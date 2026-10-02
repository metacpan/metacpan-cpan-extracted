#!/usr/bin/env perl
# ABSTRACT: Every self-tool call gets its result through plugin_after_tool_call (k134)
use strict;
use warnings;
use Test2::V0;
use Future;
use IO::Async::Loop;
use Langertha::Raider;

# The session journal (ADR 0015) and the machine-output stream (ADR 0013) are
# fed from the Events plugin: plugin_before_tool_call writes a tool.call,
# plugin_after_tool_call its tool.result. A tool.call without a tool.result
# reads as an interrupted call. So every call the raid dispatches has to run
# the after-hook exactly once -- also the interactive self-tool that paused
# the raid (answered on respond) and raider_wait (run to its end or cut off
# by a cancel). Offline, through a scripted engine.

my $loop = IO::Async::Loop->new;

{
  package K134::Response;
  use Moose;
  sub is_success  { 1 }
  sub status_line { '200 OK' }
  sub content     { '' }
  __PACKAGE__->meta->make_immutable;
}

{
  package K134::MCP;
  use Moose;
  use Future;
  has calls => (is => 'ro', default => sub { [] });
  sub list_tools { Future->done([ { name => 'record' } ]) }
  sub call_tool {
    my ( $self, $name, $input ) = @_;
    push @{ $self->calls }, $name;
    return Future->done({ content => [ { type => 'text', text => 'ran '.$name } ] });
  }
  __PACKAGE__->meta->make_immutable;
}

{
  # A duck-typed engine answering from a script: each entry is
  # { tool_calls => [ [ name, input ], ... ] } or { text => ... }. Every tool
  # result handed to format_tool_results is kept in `captured`.
  package K134::Engine;
  use Moose;
  has script      => (is => 'rw', default => sub { [] });
  has mcp_servers => (is => 'ro', default => sub { [] });
  has captured    => (is => 'ro', default => sub { [] });
  has _next       => (is => 'rw');

  sub async_loop { $loop }
  sub async_request_f {
    my ( $self ) = @_;
    my $step = shift @{ $self->script } // { text => 'done' };
    $self->_next($step);
    return Future->done(K134::Response->new);
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
  sub chat_model              { 'k134-model' }
  __PACKAGE__->meta->make_immutable;
}

{
  # Records every plugin_after_tool_call it sees.
  package K134::After;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';
  has seen => (is => 'ro', default => sub { [] });
  async sub plugin_after_tool_call {
    my ( $self, $name, $input, $result ) = @_;
    push @{ $self->seen }, [ $name, $input, $result ];
    return $result;
  }
  __PACKAGE__->meta->make_immutable;
}

sub raider {
  my ( @script ) = @_;
  my $mcp    = K134::MCP->new;
  my $engine = K134::Engine->new(script => [ @script ], mcp_servers => [ $mcp ]);
  my @events;
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    raider_mcp            => 1,
    no_session_embeddings => 1,
    plugins               => [
      '+K134::After',
      '+Langertha::Raider::Plugin::Events' => { on_event => sub {
        my ( $type, %payload ) = @_;
        push @events, { type => $type, %payload };
      } },
    ],
  );
  my ( $after ) = grep { $_->isa('K134::After') } @{ $raider->plugin_instances };
  return ( $raider, $engine, $mcp, $after, \@events );
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

# The events of the call named $name, as [ type, call, status ].
sub events_of {
  my ( $events, $name ) = @_;
  return [ map { [ $_->{type}, $_->{call}, $_->{status} ] } grep { $_->{name} eq $name } @$events ];
}

# Checks that every tool.call has exactly one tool.result, and no result is
# without its call.
sub every_call_has_one_result {
  my ( $events, $label ) = @_;
  my %n;
  $n{ $_->{call} }{ $_->{type} }++ for @$events;
  is \%n, { map { $_ => { 'tool.call' => 1, 'tool.result' => 1 } } keys %n }, $label;
}

for my $case (
  [ raider_ask_user => { question => 'Proceed?' }, 'is_question' ],
  [ raider_pause    => { reason   => 'Hold on' },  'is_pause' ],
) {
  my ( $first, $input, $pred ) = @$case;

  subtest 'the answer to '.$first.' runs plugin_after_tool_call on respond' => sub {
    my ( $raider, $engine, $mcp, $after, $events ) = raider(
      { tool_calls => [ [ $first => $input ], [ record => { note => 'x' } ] ] },
      { text => 'all done' },
    );

    my $r1 = run_f($raider->raid_f('stop, then record'));
    ok $r1->$pred, 'the batch stops on '.$first;
    is events_of($events, $first), [ [ 'tool.call', 'c1', 'dispatched' ] ],
      'only its tool.call so far: the answer is still pending';

    my $r2 = run_f($raider->respond_f('yes'));
    ok $r2->is_final, 'respond resumes to a final answer';

    is events_of($events, $first),
      [ [ 'tool.call', 'c1', 'dispatched' ], [ 'tool.result', 'c1', 'succeeded' ] ],
      $first.' gets its tool.result, under its own call id';
    my ( $res ) = grep { $_->{type} eq 'tool.result' && $_->{name} eq $first } @$events;
    is $res->{content}, 'yes', 'the tool.result carries the answer';

    is [ map { $_->[0] } @{ $after->seen } ], [ $first, 'record' ],
      'plugin_after_tool_call ran once for each call, the paused one first';
    is $after->seen->[0][1], $input, 'with the arguments of the paused call';
    every_call_has_one_result($events, 'every tool.call has exactly one tool.result');

    my %count;
    $count{ $_->{tool_call}{id} }++ for @{ $engine->captured };
    is \%count, { tc1 => 1, tc2 => 1 }, 'every tool_use has exactly one tool_result';
    my ( $answer ) = grep { $_->{tool_call}{id} eq 'tc1' } @{ $engine->captured };
    is $answer->{result}{content}, [ { type => 'text', text => 'yes' } ], 'the model gets the answer';
  };
}

subtest 'a plugin_after_tool_call rewrite of the answer reaches the model' => sub {
  my ( $raider, $engine ) = raider(
    { tool_calls => [ [ raider_ask_user => { question => 'Name?' } ] ] },
    { text => 'all done' },
  );
  my ( $after ) = grep { $_->isa('K134::After') } @{ $raider->plugin_instances };
  ok run_f($raider->raid_f('ask'))->is_question, 'asks';
  # Replace what the hook hands on.
  no warnings 'redefine';
  local *K134::After::plugin_after_tool_call = sub {
    my ( $self, $name, $input, $result ) = @_;
    return Future->done({ content => [ { type => 'text', text => 'redacted' } ] });
  };
  ok run_f($raider->respond_f('secret'))->is_final, 'resumes';
  my ( $answer ) = grep { $_->{tool_call}{id} eq 'tc1' } @{ $engine->captured };
  is $answer->{result}{content}[0]{text}, 'redacted', 'the model gets the hook\'s result';
};

subtest 'raider_wait runs plugin_after_tool_call' => sub {
  my ( $raider, $engine, $mcp, $after, $events ) = raider(
    { tool_calls => [ [ raider_wait => { seconds => 0 } ], [ record => {} ] ] },
    { text => 'all done' },
  );
  ok run_f($raider->raid_f('wait, then record'))->is_final, 'final';

  is events_of($events, 'raider_wait'),
    [ [ 'tool.call', 'c1', 'dispatched' ], [ 'tool.result', 'c1', 'succeeded' ] ],
    'raider_wait gets its tool.result';
  is [ map { $_->[0] } @{ $after->seen } ], [ 'raider_wait', 'record' ], 'the after-hook ran for both';
  every_call_has_one_result($events, 'every tool.call has exactly one tool.result');
  my ( $wait ) = grep { $_->{tool_call}{id} eq 'tc1' } @{ $engine->captured };
  is $wait->{result}{content}, [ { type => 'text', text => 'Waited 0 seconds.' } ], 'the model gets the wait result';
};

subtest 'raider_wait after a resume runs plugin_after_tool_call' => sub {
  my ( $raider, $engine, $mcp, $after, $events ) = raider(
    { tool_calls => [ [ raider_ask_user => { question => 'Wait?' } ], [ raider_wait => { seconds => 0 } ] ] },
    { text => 'all done' },
  );
  ok run_f($raider->raid_f('ask, then wait'))->is_question, 'asks';
  ok run_f($raider->respond_f('ok'))->is_final, 'resumes to a final answer';
  is [ map { $_->[0] } @{ $after->seen } ], [ 'raider_ask_user', 'raider_wait' ], 'the after-hook ran for both';
  every_call_has_one_result($events, 'every tool.call has exactly one tool.result');
};

subtest 'a raider_wait cut off by a cancel gets a cancelled tool.result' => sub {
  my ( $raider, $engine, $mcp, $after, $events ) = raider(
    { tool_calls => [ [ raider_wait => { seconds => 30 } ], [ record => {} ] ] },
  );
  $loop->watch_time(after => 0.2, code => sub { $raider->cancel });
  my $r = run_f($raider->raid_f('wait long'));
  ok $r->is_cancelled, 'the raid ends cancelled';
  is $mcp->calls, [], 'the call after the wait never ran';

  is events_of($events, 'raider_wait'),
    [ [ 'tool.call', 'c1', 'dispatched' ], [ 'tool.result', 'c1', 'cancelled' ] ],
    'raider_wait gets a cancelled tool.result';
  is scalar @{ $after->seen }, 1, 'the after-hook ran once';
  is $after->seen->[0][2], {
    content   => [ { type => 'text', text => "Tool call 'raider_wait' was cancelled." } ],
    isError   => T(),
    cancelled => 1,
  }, 'with the cancelled tool result';
  is $raider->metrics->{tool_calls}, 1, 'the cut-off wait counts as a tool call';
};

done_testing;
