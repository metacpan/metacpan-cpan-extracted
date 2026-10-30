#!/usr/bin/env perl
# ABSTRACT: A tool no source offers is "unknown tool" before hooks, gate and approval (ADR 0005)
use strict;
use warnings;
use Test2::V0;
use Future;
use IO::Async::Loop;
use JSON::MaybeXS qw( JSON );
use Langertha::Raider;

# ADR 0005: validate, resolve, check policy, ask, execute. A name that
# resolves to no tool ends at resolve: the model gets "unknown tool" and
# neither the PreToolUse hook, the gate nor an approval ever see the call.

my $loop = IO::Async::Loop->new;

{
  package K175::Response;
  use Moose;
  sub is_success  { 1 }
  sub status_line { '200 OK' }
  sub content     { '' }
  __PACKAGE__->meta->make_immutable;
}

{
  package K175::MCP;
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
      { name => 'bash' },
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
  # A duck-typed engine answering from a script: each entry is
  # { tool_calls => [ [ name, input ], ... ] } or { text => ... }. Every tool
  # result handed to format_tool_results is kept in `captured`.
  package K175::Engine;
  use Moose;
  has script      => (is => 'rw', default => sub { [] });
  has mcp_servers => (is => 'ro', default => sub { [] });
  has captured    => (is => 'ro', default => sub { [] });
  has _next       => (is => 'rw');

  sub async_loop { $loop }
  sub async_request_f {
    my ( $self ) = @_;
    $self->_next(shift @{ $self->script } // { text => 'done' });
    return Future->done(K175::Response->new);
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
  sub chat_model              { 'k175-model' }
  __PACKAGE__->meta->make_immutable;
}

# A raider over K175::MCP with the Events plugin; %args go to new. Returns the
# raider, engine, MCP source and the events list.
sub raider {
  my ( $args, @script ) = @_;
  my $plugins = delete $args->{plugins} // [];
  my $mcp     = K175::MCP->new;
  my $engine  = K175::Engine->new(script => [ @script ], mcp_servers => [ $mcp ]);
  my @events;
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    raider_mcp            => 1,
    no_session_embeddings => 1,
    plugins               => [
      @$plugins,
      '+Langertha::Raider::Plugin::Events' => { on_event => sub {
        my ( $type, %payload ) = @_;
        push @events, { type => $type, %payload };
      } },
    ],
    %$args,
  );
  return ( $raider, $engine, $mcp, \@events );
}

# A gate that records every canonical call it sees and answers from %verdict
# (tool name => verdict hash); everything else is allowed.
sub gate {
  my ( $seen, %verdict ) = @_;
  return sub {
    my ( $raider, $call ) = @_;
    push @$seen, $call;
    return $verdict{ $call->{name} } // { verdict => 'allow' };
  };
}

# Runs $f on the loop; a hang fails the test instead of CI.
sub run_f {
  my ( $f ) = @_;
  my $ok = eval {
    local $SIG{ALRM} = sub { die "TIMEOUT: raid hung\n" };
    alarm 10;
    $loop->await($f);
    alarm 0;
    1;
  };
  alarm 0;
  die $@ unless $ok;
  return $f->get;
}

# The result the model got for the call with wire id $id.
sub result_for {
  my ( $engine, $id ) = @_;
  my ( $r ) = grep { $_->{tool_call}{id} eq $id } @{ $engine->captured };
  return $r && $r->{result};
}

sub text_of { join '', map { $_->{text} // '' } @{ $_[0]{content} // [] } }

# Every tool.call has exactly one tool.result, and no result is without its call.
sub every_call_has_one_result {
  my ( $events, $label ) = @_;
  my %n;
  $n{ $_->{call} }{ $_->{type} }++ for @$events;
  is \%n, { map { $_ => { 'tool.call' => 1, 'tool.result' => 1 } } keys %n }, $label;
}


subtest 'unknown tool: error result, no hook, no gate' => sub {
  my ( @gated, @hooked );
  my ( $raider, $engine, $mcp, $events ) = raider({
      _tool_gate => sub { push @gated, $_[1]; { verdict => 'ask', reason => 'sure?' } },
      _tool_hook => sub { push @hooked, $_[1]; Future->done({}) },
    },
    { tool_calls => [ [ nonesuch => { x => 1 } ], [ record => { note => 'x' } ] ] },
    { text => 'all done' },
  );
  ok run_f($raider->raid_f('go'))->is_final, 'final';
  my $r = result_for($engine, 'tc1');
  ok $r->{isError}, 'error result';
  like text_of($r), qr/No such tool available: /, 'says no such tool';
  unlike text_of($r), qr/approval/, 'not an approval refusal';
  is [ map { $_->{name} } @gated ], [ 'record' ], 'the gate saw only the known tool';
  is [ map { $_->{name} } @hooked ], [ 'record' ], 'the hook saw only the known tool';
  is $mcp->calls, [], 'known tool refused by ask, nothing ran';
};

subtest 'unknown tool: Claude Code\'s text, with the case hint' => sub {
  my ( $raider, $engine ) = raider({},
    { tool_calls => [ [ nonesuch => {} ], [ Record => { note => 'x' } ] ] },
    { text => 'done' },
  );
  ok run_f($raider->raid_f('go'))->is_final, 'final';
  is text_of(result_for($engine, 'tc1')), '<tool_use_error>Error: No such tool available: nonesuch</tool_use_error>', 'as Claude words it';
  is text_of(result_for($engine, 'tc2')),
    '<tool_use_error>Error: No such tool available: Record. Tool names are case-sensitive: call record instead.</tool_use_error>',
    'a name that differs in case names the tool';
};

done_testing;
