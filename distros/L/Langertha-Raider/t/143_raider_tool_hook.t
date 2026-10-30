#!/usr/bin/env perl
# ABSTRACT: The raider's tool hook (PreToolUse) runs before the schema check and the gate (ADR 0022, k155)
use strict;
use warnings;
use Test2::V0;
use Future;
use IO::Async::Loop;
use JSON::MaybeXS qw( JSON );
use Langertha::Raider;

# The _tool_hook of Langertha::Raider: after plugin_before_tool_call, before
# the inputSchema check and the gate. deny: the tool does not run, one
# tool.call and one failed tool.result; new arguments replace the model's
# and are checked against the schema and gated like them; allow/ask reach
# the gate as the call's 'hook'. Offline, through a scripted engine (the
# scaffolding of t/103_raider_tool_gate.t).

my $loop = IO::Async::Loop->new;

{
  package K155::Response;
  use Moose;
  sub is_success  { 1 }
  sub status_line { '200 OK' }
  sub content     { '' }
  __PACKAGE__->meta->make_immutable;
}

{
  package K155::MCP;
  use Moose;
  use Future;
  has calls => (is => 'ro', default => sub { [] });
  sub list_tools {
    Future->done([
      { name => 'record', inputSchema => {
        type => 'object',
        properties => { note => { type => 'string' } },
        required => [ 'note' ],
      } },
    ]);
  }
  sub call_tool {
    my ( $self, $name, $input ) = @_;
    push @{ $self->calls }, [ $name, $input ];
    return Future->done({ content => [ { type => 'text', text => 'ran '.$name } ] });
  }
  __PACKAGE__->meta->make_immutable;
}

{
  package K155::Engine;
  use Moose;
  has script      => (is => 'rw', default => sub { [] });
  has mcp_servers => (is => 'ro', default => sub { [] });
  has captured    => (is => 'ro', default => sub { [] });
  has _next       => (is => 'rw');
  sub async_loop { $loop }
  sub async_request_f {
    my ( $self ) = @_;
    $self->_next(shift @{ $self->script } // { text => 'done' });
    return Future->done(K155::Response->new);
  }
  sub build_tool_chat_request { return { request => 1 } }
  sub parse_response          { return $_[0]->_next }
  sub response_tool_calls     {
    my $i = 0;
    return [ map { { id => 'tc'.++$i, call => $_ } } @{ $_[1]->{tool_calls} // [] } ];
  }
  sub response_text_content   { return $_[1]->{text} }
  sub extract_tool_call       { return @{ $_[1]->{call} } }
  sub format_tools            { return $_[1] }
  sub format_tool_results {
    my ( $self, $data, $results ) = @_;
    push @{ $self->captured }, @$results;
    return map { { role => 'tool', content => 'r' } } @$results;
  }
  sub think_tag_filter        { 0 }
  sub chat_model              { 'k155-model' }
  __PACKAGE__->meta->make_immutable;
}

sub raider {
  my ( $args, @script ) = @_;
  my $mcp    = K155::MCP->new;
  my $engine = K155::Engine->new(script => [ @script ], mcp_servers => [ $mcp ]);
  my @events;
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    no_session_embeddings => 1,
    plugins               => [ '+Langertha::Raider::Plugin::Events' => { on_event => sub {
      my ( $type, %payload ) = @_;
      push @events, { type => $type, %payload };
    } } ],
    %$args,
  );
  return ( $raider, $engine, $mcp, \@events );
}

sub text_of { join "\n", map { $_->{text} // '' } @{ $_[0]{result}{content} // [] } }

subtest 'deny: the tool does not run, one tool.call and one failed tool.result' => sub {
  my @seen;
  my ( $raider, $engine, $mcp, $events ) = raider(
    { _tool_hook => sub { push @seen, $_[1]; Future->done({ decision => 'deny', reason => 'PreToolUse hook: no' }) },
      _tool_gate => sub { die 'the gate must not be asked' } },
    { tool_calls => [ [ record => { note => 'x' } ] ] },
  );
  $raider->raid('go');
  is( $mcp->calls, [], 'not run' );
  is( $seen[0], { name => 'record', source => 'engine:1', arguments => { note => 'x' }, call => 'c1' }, 'the hook gets the canonical call, with its id' );
  is( $engine->captured->[0]{result}{isError}, JSON->true, 'an error result' );
  like( text_of( $engine->captured->[0] ), qr/\ATool call 'record' was denied: PreToolUse hook: no\z/, 'with the reason' );
  is( [ map { $_->{type} } @$events ], [qw( tool.call tool.result )], 'one tool.call, one tool.result' );
  is( $events->[1]{status}, 'failed', 'failed' );
};

subtest 'deny with a message: the model gets that text as it stands' => sub {
  my ( $raider, $engine, $mcp ) = raider(
    { _tool_hook => sub { Future->done({ decision => 'deny', reason => 'PreToolUse hook: no', message => 'PreToolUse:record hook error: no' }) } },
    { tool_calls => [ [ record => { note => 'x' } ] ] },
  );
  $raider->raid('go');
  is( $mcp->calls, [], 'not run' );
  is( text_of( $engine->captured->[0] ), 'PreToolUse:record hook error: no', 'the message, nothing added' );
  is( $engine->captured->[0]{result}{isError}, JSON->true, 'still an error result' );
};

subtest 'new arguments are schema-checked and gated, and run' => sub {
  my @gated;
  my ( $raider, $engine, $mcp ) = raider(
    { _tool_hook => sub { Future->done({ decision => 'allow', reason => 'ok', arguments => { note => 'from the hook' } }) },
      _tool_gate => sub { push @gated, $_[1]; { verdict => 'allow' } } },
    { tool_calls => [ [ record => { note => 'from the model' } ] ] },
  );
  $raider->raid('go');
  is( $mcp->calls, [ [ record => { note => 'from the hook' } ] ], 'the hook\'s arguments run' );
  is( $gated[0], { name => 'record', source => 'engine:1', arguments => { note => 'from the hook' }, call => 'c1',
    hook => { decision => 'allow', reason => 'ok' } }, 'the gate sees them and the hook\'s allow' );

  ( $raider, $engine, $mcp ) = raider(
    { _tool_hook => sub { Future->done({ arguments => { wrong => 1 } }) } },
    { tool_calls => [ [ record => { note => 'x' } ] ] },
  );
  $raider->raid('go');
  is( $mcp->calls, [], 'arguments that break the schema do not run' );
  like( text_of( $engine->captured->[0] ), qr/do not match the input schema of tool 'record'/, 'the schema error' );
};

subtest 'no decision: nothing reaches the gate; no hook: unchanged' => sub {
  my @gated;
  my ( $raider, $engine, $mcp ) = raider(
    { _tool_hook => sub { Future->done({}) }, _tool_gate => sub { push @gated, $_[1]; { verdict => 'allow' } } },
    { tool_calls => [ [ record => { note => 'x' } ] ] },
  );
  $raider->raid('go');
  ok( !exists $gated[0]{hook}, 'no hook key without a decision' );
  is( $mcp->calls, [ [ record => { note => 'x' } ] ], 'runs as the model sent it' );
  ok( !Langertha::Raider->can('tool_hook'), 'no public accessor: constructor-only' );
};

done_testing;
