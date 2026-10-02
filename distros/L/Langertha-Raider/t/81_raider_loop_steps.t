#!/usr/bin/env perl
# ABSTRACT: Characterization of the raid loop's steps: Langfuse tracing, plugin skip, injections, abort, failures
use strict;
use warnings;
use Test2::V0;

use Future;
use IO::Async::Loop;
use Storable qw( dclone );
use Langertha::Raider;

# Pins the observable behaviour of _run_raid_loop's branches that no other
# offline test drives (karr k95, written before the loop was split into named
# steps): the Langfuse observations of a raid, the tool-result shapes of the
# MCP / unknown / plugin-skipped / self-tool / wait paths, injections and
# on_iteration, abort metrics, the request-failure and iteration-limit deaths.

# --- Fake MCP server: 'echo' answers, 'fail' fails its future ---

{
  package LoopMCP;
  use Moose;
  use Future;

  has calls => (is => 'ro', default => sub { [] });

  sub list_tools { return Future->done([ { name => 'echo' }, { name => 'fail' } ]) }
  sub call_tool {
    my ( $self, $name, $input ) = @_;
    push @{$self->calls}, [ $name, $input ];
    return Future->fail('boom') if $name eq 'fail';
    return Future->done({ content => [ { type => 'text', text => "echo:$input->{v}" } ] });
  }

  __PACKAGE__->meta->make_immutable;
}

{
  package LoopEngine::Response;
  use Moose;
  has ok => (is => 'ro', default => 1);
  sub is_success  { $_[0]->ok }
  sub status_line { $_[0]->ok ? '200 OK' : '500 Internal Server Error' }
  sub content     { $_[0]->ok ? '' : 'server exploded' }
  __PACKAGE__->meta->make_immutable;
}

# --- Scripted engine: each parse_response yields the next turn; records the
#     conversation of every request, the results handed to format_tool_results
#     and (when langfuse => 1) every Langfuse call with a deterministic clock. ---

{
  package LoopEngine;
  use Moose;
  with 'Langertha::Role::Tools';
  use JSON::MaybeXS;
  use Storable qw( dclone );

  has chat_model     => (is => 'ro', default => 'loop-model');
  has '+mcp_servers' => (default => sub { [] });
  has turns          => (is => 'ro', required => 1);
  has fail_request   => (is => 'ro', default => 0);
  has langfuse       => (is => 'ro', default => 0);
  has requests       => (is => 'ro', default => sub { [] });
  has tool_results   => (is => 'ro', default => sub { [] });
  has lf             => (is => 'ro', default => sub { [] });
  has _clock         => (is => 'rw', default => 0);
  has _ids           => (is => 'rw', default => 0);
  has _turn_idx      => (is => 'rw', default => 0);
  has _loop          => (is => 'ro', lazy => 1, default => sub { IO::Async::Loop->new });

  sub async_loop      { return $_[0]->_loop }
  sub async_request_f {
    return $_[0]->_loop->new_future->done(LoopEngine::Response->new(ok => !$_[0]->fail_request));
  }

  sub format_tools          { return $_[1] }
  sub response_tool_calls   { return $_[1]->{tool_calls} // [] }
  sub response_text_content { return $_[1]->{text} // 'final' }
  sub extract_tool_call     { return ($_[1]->{name}, $_[1]->{input}) }
  sub think_tag_filter      { 0 }
  sub build_tool_chat_request {
    my ( $self, $conversation, $tools ) = @_;
    push @{$self->requests}, dclone($conversation);
    return { request => 1 };
  }
  sub format_tool_results {
    my ( $self, $data, $results ) = @_;
    push @{$self->tool_results}, [ map {
      [ $self->extract_tool_call($_->{tool_call}) ]->[0] => $_->{result}
    } @$results ];
    return map { { role => 'tool', content => 'r' } } @$results;
  }
  sub parse_response {
    my ( $self ) = @_;
    my $i = $self->_turn_idx;
    $self->_turn_idx($i + 1);
    return $self->turns->[$i] // $self->turns->[-1];
  }

  # Langfuse surface, as Raider calls it
  sub json               { JSON::MaybeXS->new(canonical => 1) }
  sub has_temperature    { 1 }
  sub temperature        { 0.5 }
  sub langfuse_enabled   { $_[0]->langfuse }
  sub langfuse_timestamp { my $t = $_[0]->_clock + 1; $_[0]->_clock($t); 't'.$t }
  sub _record {
    my ( $self, $method, %args ) = @_;
    my $id = $self->_ids + 1;
    $self->_ids($id);
    push @{$self->lf}, [ $method, dclone(\%args) ];
    return $method.'-'.$id;
  }
  sub langfuse_trace        { shift->_record('trace', @_) }
  sub langfuse_span         { shift->_record('span', @_) }
  sub langfuse_generation   { shift->_record('generation', @_) }
  sub langfuse_update_span  { shift->_record('update_span', @_) }
  sub langfuse_update_trace { shift->_record('update_trace', @_) }

  __PACKAGE__->meta->make_immutable;
}

{
  package LoopPlugin::SkipEcho;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';
  async sub plugin_before_tool_call {
    my ( $self, $name, $input ) = @_;
    return if $name eq 'echo';
    return ( $name, $input );
  }
  __PACKAGE__->meta->make_immutable;
}

sub guarded {
  my ( $code ) = @_;
  my ( $result, $err );
  {
    local $@;
    $result = eval {
      local $SIG{ALRM} = sub { die "TIMEOUT: raid hung\n" };
      alarm 5;
      my $r = $code->();
      alarm 0;
      $r;
    };
    $err = $@;
    alarm 0;
  }
  return ( $result, $err );
}

my $usage = { prompt_tokens => 10, completion_tokens => 5, total_tokens => 15 };

subtest 'langfuse observations and tool-result shapes of a two-turn raid' => sub {
  my $mcp = LoopMCP->new;
  my $engine = LoopEngine->new(
    langfuse    => 1,
    mcp_servers => [ $mcp ],
    turns       => [
      { usage => $usage, tool_calls => [
        { name => 'echo',            input => { v => 1 } },
        { name => 'fail',            input => { v => 2 } },
        { name => 'nope',            input => {} },
        { name => 'raider_ask_user', input => { question => 'q?' } },
        { name => 'raider_wait',     input => { seconds => 0 } },
      ] },
      { usage => $usage, text => 'all done' },
    ],
  );
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    mission               => 'M',
    no_session_embeddings => 1,
    raider_mcp            => { ask_user => 1, wait => 1 },
    on_ask_user           => sub { 'yes' },
  );

  my ( $result, $err ) = guarded(sub { $raider->raid('go') });
  is($err, '', 'the raid does not die');
  ok($result->is_final, 'final result');
  is("$result", 'all done', 'final text');

  is($engine->tool_results, [ [
    echo => { content => [ { type => 'text', text => 'echo:1' } ] },
    fail => { content => [ { type => 'text', text => "Error calling tool 'fail': boom" } ], isError => T() },
    nope => { content => [ { type => 'text', text => 'unknown tool nope' } ], isError => T() },
    raider_ask_user => { type => 'result', content => [ { type => 'text', text => 'yes' } ] },
    raider_wait => { content => [ { type => 'text', text => 'Waited 0 seconds.' } ] },
  ] ], 'every call of the batch left its result, in order');

  my $conv1 = [ { role => 'system', content => 'M' }, { role => 'user', content => 'go' } ];
  my $mp = { temperature => 0.5 };
  my $lu = { input => 10, output => 5, total => 15 };
  is($engine->lf, [
    [ trace => { name => E(), input => [ 'go' ],
      metadata => { mission => 'M', history_length => 0 } } ],
    [ span => { trace_id => 'trace-1', name => 'iteration-1', start_time => 't1' } ],
    [ generation => { trace_id => 'trace-1', parent_observation_id => 'span-2',
      name => 'llm-call', model => 'loop-model', input => $conv1,
      output => '["echo","fail","nope","raider_ask_user","raider_wait"]',
      start_time => 't1', end_time => 't2', usage => $lu, model_parameters => $mp } ],
    [ span => { trace_id => 'trace-1', parent_observation_id => 'span-2', name => 'tool: echo',
      input => { v => 1 }, output => 'echo:1', start_time => 't3', end_time => 't4' } ],
    [ span => { trace_id => 'trace-1', parent_observation_id => 'span-2', name => 'tool: fail',
      input => { v => 2 }, output => "Error calling tool 'fail': boom",
      start_time => 't5', end_time => 't6', level => 'ERROR' } ],
    # the unknown tool 'nope' takes its start time (t7) but is never traced
    [ span => { trace_id => 'trace-1', parent_observation_id => 'span-2', name => 'tool: raider_ask_user',
      input => { question => 'q?' }, output => 'yes', start_time => 't8', end_time => 't9' } ],
    [ span => { trace_id => 'trace-1', parent_observation_id => 'span-2', name => 'tool: raider_wait',
      input => { seconds => 0 }, output => 'Waited 0 seconds.', start_time => 't10', end_time => 't11' } ],
    [ update_span => { id => 'span-2', end_time => 't12', metadata => { tool_calls => 5,
      tools_used => [ qw( echo fail nope raider_ask_user raider_wait ) ] } } ],
    [ span => { trace_id => 'trace-1', name => 'iteration-2', start_time => 't13' } ],
    [ generation => { trace_id => 'trace-1', parent_observation_id => 'span-9',
      name => 'llm-call', model => 'loop-model', input => [ @$conv1, ( { role => 'tool', content => 'r' } ) x 5 ],
      output => 'all done', start_time => 't13', end_time => 't14',
      usage => $lu, model_parameters => $mp } ],
    [ update_span => { id => 'span-9', end_time => 't14', output => 'all done' } ],
    [ update_trace => { id => 'trace-1', output => 'all done' } ],
  ], 'the Langfuse observations of the raid');

  is($raider->metrics, { raids => 1, iterations => 2, tool_calls => 5, time_ms => E() },
    'metrics count the raid, both iterations and all five calls');
  is($raider->history, [ { role => 'user', content => 'go' },
    { role => 'assistant', content => 'all done' } ], 'history keeps the user turn and the answer');
};

subtest 'plugin skip, injections and on_iteration' => sub {
  my $mcp = LoopMCP->new;
  my $engine = LoopEngine->new(
    mcp_servers => [ $mcp ],
    turns       => [
      { tool_calls => [ { name => 'echo', input => { v => 1 } } ] },
      { text => 'fin' },
    ],
  );
  my @seen;
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    no_session_embeddings => 1,
    plugins               => [ 'LoopPlugin::SkipEcho' ],
    on_iteration          => sub { push @seen, $_[1]; return [ "cb $_[1]" ] },
  );
  $raider->inject('queued');

  my ( $result, $err ) = guarded(sub { $raider->raid('go') });
  is($err, '', 'the raid does not die');
  is("$result", 'fin', 'final text');
  is(scalar @{$mcp->calls}, 0, 'the skipped call never reached the MCP source');
  is($engine->tool_results, [ [ echo => { content => [ { type => 'text',
    text => "Tool call 'echo' was skipped by plugin." } ] } ] ], 'the skip result');
  is(\@seen, [ 2 ], 'on_iteration runs from the second iteration on');
  is($engine->requests->[0], [ { role => 'user', content => 'go' } ],
    'no injection before the first request');
  is($engine->requests->[1], [ { role => 'user', content => 'go' }, { role => 'tool', content => 'r' },
    { role => 'user', content => 'queued' }, { role => 'user', content => 'cb 2' } ],
    'queued injection and on_iteration messages follow the tool turn');
  is($raider->history, [ { role => 'user', content => 'go' }, { role => 'user', content => 'queued' },
    { role => 'user', content => 'cb 2' }, { role => 'assistant', content => 'fin' } ],
    'history keeps the injected messages between user turn and answer');
  is($raider->metrics->{tool_calls}, 1, 'the skipped call counts as a tool call');
};

subtest 'abort finalizes metrics without counting a raid' => sub {
  my $mcp = LoopMCP->new;
  my $engine = LoopEngine->new(
    mcp_servers => [ $mcp ],
    turns       => [ { tool_calls => [
      { name => 'echo',         input => { v => 1 } },
      { name => 'raider_abort', input => { reason => 'stop' } },
      { name => 'echo',         input => { v => 3 } },
    ] } ],
  );
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    no_session_embeddings => 1,
    raider_mcp            => { abort => 1 },
  );
  my ( $result, $err ) = guarded(sub { $raider->raid('go') });
  is($err, '', 'the raid does not die');
  ok($result->is_abort, 'abort result');
  is($result->content, 'stop', 'abort reason');
  is($mcp->calls, [ [ echo => { v => 1 } ] ], 'calls after the abort do not run');
  is($raider->metrics, { raids => 0, iterations => 1, tool_calls => 1, time_ms => E() },
    'metrics hold the iteration and the call before the abort');
  is($raider->history, [], 'an aborted raid adds nothing to history');
};

subtest 'a failed request dies with the status line' => sub {
  my $engine = LoopEngine->new(
    mcp_servers  => [ LoopMCP->new ],
    fail_request => 1,
    turns        => [ { text => 'never' } ],
  );
  my $raider = Langertha::Raider->new(engine => $engine, no_session_embeddings => 1);
  my ( undef, $err ) = guarded(sub { $raider->raid('go') });
  like($err, qr/^LoopEngine raid request failed: 500 Internal Server Error\nserver exploded/,
    'the error names the engine, status and body');
};

subtest 'exceeding max_iterations dies' => sub {
  my $engine = LoopEngine->new(
    mcp_servers => [ LoopMCP->new ],
    turns       => [ { tool_calls => [ { name => 'echo', input => { v => 1 } } ] } ],
  );
  my $raider = Langertha::Raider->new(
    engine => $engine, no_session_embeddings => 1, max_iterations => 2 );
  my ( undef, $err ) = guarded(sub { $raider->raid('go') });
  like($err, qr/^Raider tool loop exceeded 2 iterations/, 'the iteration limit is reported');
  is(scalar @{$engine->requests}, 2, 'exactly max_iterations requests were sent');
};

done_testing;
