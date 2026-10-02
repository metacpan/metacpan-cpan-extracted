#!/usr/bin/env perl
# ABSTRACT: Calls left in a batch after a pause run through the same dispatch (k120)

use strict;
use warnings;

use Test2::V0;

use Langertha::Raider;

# When raider_ask_user (or raider_pause) stops a batch of tool calls, the calls
# queued after it run on respond_f. They must go through the same per-call
# dispatch as the calls of the first turn: the plugin_before_tool_call hook
# runs for each of them, so a gate on that hook applies and the Events plugin
# reports a tool.call before its tool.result -- the session journal (ADR 0015)
# is fed from those events. Offline, through a scripted engine.

{
  package K120::Response;
  use Moose;
  sub is_success  { 1 }
  sub status_line { '200 OK' }
  sub content     { '' }
  __PACKAGE__->meta->make_immutable;
}

{
  package K120::HTTP;
  use Moose;
  use IO::Async::Loop;
  has loop => ( is => 'ro', default => sub { IO::Async::Loop->new } );
  sub do_request { return $_[0]->loop->new_future->done(K120::Response->new) }
  __PACKAGE__->meta->make_immutable;
}

{
  package K120::MCP;
  use Moose;
  use Future;
  has tools    => ( is => 'ro', default => sub { [] } );
  has call_log => ( is => 'ro', default => sub { [] } );
  sub list_tools { return Future->done($_[0]->tools) }
  sub call_tool {
    my ( $self, $name, $input ) = @_;
    push @{$self->call_log}, { name => $name, input => $input };
    return Future->done({ content => [{ type => 'text', text => 'ran '.$name }] });
  }
  __PACKAGE__->meta->make_immutable;
}

# Each model turn is popped from `turns`; every tool result handed to
# format_tool_results is kept in `captured`.
{
  package K120::Engine;
  use Moose;
  with 'Langertha::Role::Tools';

  has chat_model     => ( is => 'ro', default => 'k120-model' );
  has '+mcp_servers' => ( default => sub { [] } );
  has turns          => ( is => 'ro', default => sub { [] } );
  has _turn_idx      => ( is => 'rw', default => 0 );
  has captured       => ( is => 'ro', default => sub { [] } );
  has _http          => ( is => 'ro', lazy => 1, default => sub { K120::HTTP->new } );

  sub async_request_f { return $_[0]->_http->do_request }
  sub async_loop      { return $_[0]->_http->loop }

  sub format_tools            { return $_[1] }
  sub build_tool_chat_request { return { request => 1 } }
  sub response_tool_calls     { return $_[1]->{tool_calls} // [] }
  sub response_text_content   { return $_[1]->{text} // 'final answer' }
  sub extract_tool_call       { return ( $_[1]->{name}, $_[1]->{input} ) }
  sub think_tag_filter        { 0 }

  sub parse_response {
    my ( $self ) = @_;
    my $i = $self->_turn_idx;
    $self->_turn_idx($i + 1);
    return $self->turns->[$i] // { tool_calls => [] };
  }

  sub format_tool_results {
    my ( $self, $data, $results ) = @_;
    push @{$self->captured}, @$results;
    return map {
      { role => 'tool', tool_call_id => ( $_->{tool_call}{id} // '' ), content => $_->{result} }
    } @$results;
  }

  __PACKAGE__->meta->make_immutable;
}

# A gate on plugin_before_tool_call: records every call it sees, skips the
# names in `deny`.
{
  package K120::Gate;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';

  has seen => ( is => 'ro', default => sub { [] } );
  has deny => ( is => 'ro', default => sub { {} } );

  async sub plugin_before_tool_call {
    my ( $self, $name, $input ) = @_;
    push @{$self->seen}, $name;
    return if $self->deny->{$name};
    return ( $name, $input );
  }

  __PACKAGE__->meta->make_immutable;
}

# A batch of [ $first, record ] where $first is the interactive self-tool that
# stops it, then a final turn.
sub build_raider {
  my ( %arg ) = @_;
  my $first  = $arg{first} // { name => 'raider_ask_user', input => { question => 'Proceed?' } };
  my $mcp    = K120::MCP->new( tools => [{ name => 'record' }] );
  my $engine = K120::Engine->new(
    mcp_servers => [$mcp],
    turns       => [
      { tool_calls => [
        { %$first, id => 'tc_first' },
        { name => 'record', input => { note => 'x' }, id => 'tc_rec' },
      ] },
      { tool_calls => [], text => 'all done' },
    ],
  );
  my @events;
  my $raider = Langertha::Raider->new(
    engine     => $engine,
    raider_mcp => 1,
    plugins    => [
      '+K120::Gate' => { deny => $arg{deny} // {} },
      '+Langertha::Raider::Plugin::Events' => { on_event => sub {
        my ( $type, %payload ) = @_;
        push @events, { type => $type, %payload };
      } },
    ],
  );
  my ( $gate ) = grep { $_->isa('K120::Gate') } @{$raider->plugin_instances};
  return ( $raider, $engine, $mcp, $gate, \@events );
}

for my $case (
  [ raider_ask_user => { question => 'Proceed?' }, 'is_question' ],
  [ raider_pause    => { reason   => 'Hold on' },  'is_pause' ],
) {
  my ( $first, $input, $pred ) = @$case;

  subtest 'a call queued after '.$first.' gets its tool.call on resume' => sub {
    my ( $raider, $engine, $mcp, $gate, $events ) =
      build_raider( first => { name => $first, input => $input } );

    my $r1 = $raider->raid('stop, then record');
    ok $r1->$pred, 'the batch stops on '.$first;
    is $gate->seen, [$first], 'only '.$first.' reached the hook before the stop';
    is $mcp->call_log, [], 'record did not run before the answer';

    my $r2 = $raider->respond('yes');
    ok $r2->is_final, 'respond resumes to a final answer';
    is "$r2", 'all done', 'final text is the second turn';

    is $gate->seen, [$first, 'record'],
      'plugin_before_tool_call ran for the call queued after the stop';
    is $mcp->call_log, [{ name => 'record', input => { note => 'x' } }], 'record ran once';

    my @record = grep { ( $_->{name} // '' ) eq 'record' } @$events;
    is [ map { $_->{type} } @record ], ['tool.call', 'tool.result'],
      'record has a tool.call before its tool.result';
    is $record[1]{call}, $record[0]{call}, 'the tool.result belongs to the tool.call of record';
    my ( $first_call ) = grep { $_->{type} eq 'tool.call' && $_->{name} eq $first } @$events;
    isnt $record[0]{call}, $first_call->{call}, 'record got its own call id';

    my %count;
    $count{ $_->{tool_call}{id} }++ for @{$engine->captured};
    is \%count, { tc_first => 1, tc_rec => 1 }, 'every tool_use has exactly one tool_result';
  };
}

subtest 'a gate on plugin_before_tool_call applies after resume' => sub {
  my ( $raider, $engine, $mcp, $gate, $events ) = build_raider( deny => { record => 1 } );

  ok $raider->raid('ask me, then record')->is_question, 'pauses on raider_ask_user';
  ok $raider->respond('yes')->is_final, 'resumes to a final answer';

  is $mcp->call_log, [], 'the gate kept record from running after the pause';
  my ( $rec ) = grep { $_->{tool_call}{id} eq 'tc_rec' } @{$engine->captured};
  like $rec->{result}{content}[0]{text}, qr/skipped by plugin/,
    'the skipped call still gets a tool_result';
};

done_testing;
