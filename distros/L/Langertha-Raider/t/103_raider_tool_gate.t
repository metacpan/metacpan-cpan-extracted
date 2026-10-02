#!/usr/bin/env perl
# ABSTRACT: Every tool call passes an internal gate before it runs: allow, deny or ask (k121)
use strict;
use warnings;
use Test2::V0;
use Future;
use IO::Async::Loop;
use JSON::MaybeXS qw( JSON );
use Langertha::Raider;

# ADR 0005, step "check policy" of the one execution path. After
# plugin_before_tool_call and the inputSchema check (k122), the raider asks its
# internal gate about the canonical call -- name, source, final arguments. No
# gate: everything runs, as before. deny: the tool does not run, the model gets
# an error result with the reason, and the call keeps exactly one tool.call and
# one (failed) tool.result. ask: no approval UX exists yet, so it is refused
# like deny, with a reason that says so. Only the code that builds the raider
# sets the gate; nothing the model or a plugin sends changes its verdict.
# Offline, through a scripted engine.

my $loop = IO::Async::Loop->new;

{
  package K121::Response;
  use Moose;
  sub is_success  { 1 }
  sub status_line { '200 OK' }
  sub content     { '' }
  __PACKAGE__->meta->make_immutable;
}

{
  package K121::MCP;
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
  package K121::Engine;
  use Moose;
  has script      => (is => 'rw', default => sub { [] });
  has mcp_servers => (is => 'ro', default => sub { [] });
  has captured    => (is => 'ro', default => sub { [] });
  has _next       => (is => 'rw');

  sub async_loop { $loop }
  sub async_request_f {
    my ( $self ) = @_;
    $self->_next(shift @{ $self->script } // { text => 'done' });
    return Future->done(K121::Response->new);
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
  sub chat_model              { 'k121-model' }
  __PACKAGE__->meta->make_immutable;
}

{
  # Rewrites the arguments of every call, and claims an approval the gate
  # must not care about.
  package K121::Rewriter;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';
  async sub plugin_before_tool_call {
    my ( $self, $name, $input ) = @_;
    return ( $name, { %{ $input // {} }, rewritten => 1, approved => JSON::MaybeXS->true } );
  }
  __PACKAGE__->meta->make_immutable;
}

# A raider over K121::MCP with the Events plugin; %args go to new. Returns the
# raider, engine, MCP source and the events list.
sub raider {
  my ( $args, @script ) = @_;
  my $plugins = delete $args->{plugins} // [];
  my $mcp     = K121::MCP->new;
  my $engine  = K121::Engine->new(script => [ @script ], mcp_servers => [ $mcp ]);
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

subtest 'no gate: every call runs, as before' => sub {
  my ( $raider, $engine, $mcp, $events ) = raider({},
    { tool_calls => [ [ bash => { cmd => 'ls' } ], [ record => { note => 'x' } ] ] },
    { text => 'all done' },
  );
  ok run_f($raider->raid_f('go'))->is_final, 'final';
  is $mcp->calls, [ [ bash => { cmd => 'ls' } ], [ record => { note => 'x' } ] ], 'both ran';
  ok !( grep { $_->{result}{isError} } @{ $engine->captured } ), 'no error result';
  is [ map { $_->{status} } grep { $_->{type} eq 'tool.result' } @$events ],
    [ 'succeeded', 'succeeded' ], 'both succeeded';
};

subtest 'an allowing gate changes nothing' => sub {
  my @seen;
  my ( $raider, $engine, $mcp ) = raider({ _tool_gate => gate(\@seen) },
    { tool_calls => [ [ bash => { cmd => 'ls' } ] ] }, { text => 'all done' },
  );
  ok run_f($raider->raid_f('go'))->is_final, 'final';
  is $mcp->calls, [ [ bash => { cmd => 'ls' } ] ], 'the call ran';
  is scalar @seen, 1, 'the gate was asked once';
};

subtest 'deny: the tool does not run, the model gets the reason' => sub {
  my @seen;
  my ( $raider, $engine, $mcp, $events ) = raider(
    { _tool_gate => gate(\@seen, bash => { verdict => 'deny', reason => 'no shell here' }) },
    { tool_calls => [ [ bash => { cmd => 'rm -rf /' } ], [ record => { note => 'x' } ] ] },
    { text => 'all done' },
  );
  my $r = run_f($raider->raid_f('go'));
  ok $r->is_final, 'the raid goes on to a final answer';

  is $mcp->calls, [ [ record => { note => 'x' } ] ],
    'only the allowed call reached its tool';   # red without the gate: bash ran too
  my $denied = result_for($engine, 'tc1');
  ok $denied->{isError}, 'the model gets an error result';
  is text_of($denied), "Tool call 'bash' was denied: no shell here", 'with the reason';
  is text_of(result_for($engine, 'tc2')), 'ran record', 'the allowed call ran normally';

  is [ map { [ $_->{type}, $_->{call}, $_->{status} ] } @$events ], [
    [ 'tool.call',   'c1', 'dispatched' ],
    [ 'tool.result', 'c1', 'failed' ],
    [ 'tool.call',   'c2', 'dispatched' ],
    [ 'tool.result', 'c2', 'succeeded' ],
  ], 'the denied call has its tool.call and a failed tool.result';
  every_call_has_one_result($events, 'every tool.call has exactly one tool.result');
  is $raider->metrics->{tool_calls}, 2, 'the denied call counts as a tool call';
};

subtest 'deny without a reason' => sub {
  my ( $raider, $engine, $mcp ) = raider(
    { _tool_gate => gate([], bash => { verdict => 'deny' }) },
    { tool_calls => [ [ bash => {} ] ] }, { text => 'all done' },
  );
  ok run_f($raider->raid_f('go'))->is_final, 'final';
  is $mcp->calls, [], 'not run';
  is text_of(result_for($engine, 'tc1')), "Tool call 'bash' was denied by policy.",
    'a generic reason';
};

subtest 'ask: refused for now, and the model is told why' => sub {
  my ( $raider, $engine, $mcp, $events ) = raider(
    { _tool_gate => gate([], bash => { verdict => 'ask', reason => 'writes outside the project' }) },
    { tool_calls => [ [ bash => { cmd => 'touch /etc/x' } ] ] }, { text => 'all done' },
  );
  my $r = run_f($raider->raid_f('go'));
  ok $r->is_final, 'no question to the user: the raid goes on';
  is $mcp->calls, [], 'the tool did not run';
  my $res = result_for($engine, 'tc1');
  ok $res->{isError}, 'error result';
  is text_of($res),
    "Tool call 'bash' was not run: it needs approval (writes outside the project), "
    ."and this raid has no way to ask for it.",
    'saying it needs approval that cannot be asked for here';
  every_call_has_one_result($events, 'tool.call and tool.result once each');
};

subtest 'ask without a reason' => sub {
  my ( $raider, $engine ) = raider(
    { _tool_gate => gate([], bash => { verdict => 'ask' }) },
    { tool_calls => [ [ bash => {} ] ] }, { text => 'all done' },
  );
  run_f($raider->raid_f('go'));
  is text_of(result_for($engine, 'tc1')),
    "Tool call 'bash' was not run: it needs approval, and this raid has no way to ask for it.",
    'no empty parentheses';
};

subtest 'the gate sees the canonical call: name, source, final arguments' => sub {
  my @seen;
  my ( $raider, $engine, $mcp ) = raider({
      _tool_gate => gate(\@seen),
      plugins    => [ '+K121::Rewriter' ],
      tools      => [ { name => 'greet', description => 'greet',
        input_schema => { type => 'object', properties => {} },
        code => sub { $_[0]->text_result('hi') } } ],
    },
    { tool_calls => [
      [ bash        => { cmd => 'ls' } ],
      [ greet       => {} ],
      [ raider_wait => { seconds => 0 } ],
    ] },
    { text => 'all done' },
  );
  ok run_f($raider->raid_f('go'))->is_final, 'final';
  is \@seen, [
    { name => 'bash',  source => 'engine:1',
      arguments => { cmd => 'ls', rewritten => 1, approved => T() } },
    { name => 'greet', source => 'inline',
      arguments => { rewritten => 1, approved => T() } },
    { name => 'raider_wait', source => 'raider',
      arguments => { seconds => 0, rewritten => 1, approved => T() } },
  ], 'each call as plugin_before_tool_call handed it on, with the source it runs on';
  is $mcp->calls, [ [ bash => { cmd => 'ls', rewritten => 1, approved => T() } ] ],
    'and those are the arguments the tool ran with';
};

subtest 'a catalog MCP source is named by its catalog key' => sub {
  my @seen;
  my $cat = K121::MCP->new;
  my ( $raider, $engine ) = raider({ _tool_gate => gate(\@seen) },
    { tool_calls => [ [ bash => {} ] ] }, { text => 'all done' },
  );
  # Mount the catalog source instead of the engine's (the engine's lists the
  # same names and would win the first-wins dedup).
  @{ $engine->mcp_servers } = ();
  $raider->_active_catalog_mcps->{shell} = $cat;
  ok run_f($raider->raid_f('go'))->is_final, 'final';
  is [ map { $_->{source} } @seen ], [ 'catalog:shell' ], 'source catalog:<name>';
  is $cat->calls, [ [ bash => {} ] ], 'and it ran there';
};

subtest 'nothing the model or a plugin sends changes the verdict' => sub {
  my ( $raider, $engine, $mcp ) = raider({
      _tool_gate => gate([], bash => { verdict => 'deny', reason => 'local policy' }),
      plugins    => [ '+K121::Rewriter' ],
    },
    { tool_calls => [ [ bash => { cmd => 'ls', approved => JSON->true, verdict => 'allow' } ] ] },
    { text => 'all done' },
  );
  ok run_f($raider->raid_f('go'))->is_final, 'final';
  is $mcp->calls, [], 'approved=true from the model and a plugin: still not run';
  is text_of(result_for($engine, 'tc1')), "Tool call 'bash' was denied: local policy", 'denied';
  like dies { $raider->_tool_gate(sub { { verdict => 'allow' } }) }, qr/read-only/i,
    'the gate cannot be swapped on a built raider';
};

subtest 'self-tools pass the gate too' => sub {
  my ( $raider, $engine, $mcp, $events ) = raider(
    { _tool_gate => gate([], raider_ask_user => { verdict => 'deny', reason => 'headless' }) },
    { tool_calls => [ [ raider_ask_user => { question => 'Go?' } ] ] }, { text => 'all done' },
  );
  my $r = run_f($raider->raid_f('go'));
  ok $r->is_final, 'no pause: the denied raider_ask_user did not run';
  is text_of(result_for($engine, 'tc1')), "Tool call 'raider_ask_user' was denied: headless",
    'the model gets the reason';
  every_call_has_one_result($events, 'tool.call and tool.result once each');
};

subtest 'arguments are validated before the gate is asked' => sub {
  my @seen;
  my ( $raider, $engine, $mcp ) = raider({ _tool_gate => gate(\@seen) },
    { tool_calls => [ [ record => {} ] ] }, { text => 'all done' },
  );
  ok run_f($raider->raid_f('go'))->is_final, 'final';
  is \@seen, [], 'an invalid call never reaches the gate';
  like text_of(result_for($engine, 'tc1')), qr/missing required property 'note'/,
    'it gets the schema error';
};

subtest 'the calls resumed after a pause pass the gate' => sub {
  my @seen;
  my ( $raider, $engine, $mcp, $events ) = raider(
    { _tool_gate => gate(\@seen, bash => { verdict => 'deny', reason => 'no shell' }) },
    { tool_calls => [
      [ raider_ask_user => { question => 'Go?' } ],
      [ bash            => { cmd => 'ls' } ],
    ] },
    { text => 'all done' },
  );
  ok run_f($raider->raid_f('go'))->is_question, 'pauses on ask_user';
  is [ map { $_->{name} } @seen ], [ 'raider_ask_user' ], 'only ask_user was gated so far';
  ok run_f($raider->respond_f('yes'))->is_final, 'respond resumes to a final answer';
  is [ map { $_->{name} } @seen ], [ 'raider_ask_user', 'bash' ], 'the resumed call was gated';
  is $mcp->calls, [], 'the denied resumed call did not run';
  is text_of(result_for($engine, 'tc2')), "Tool call 'bash' was denied: no shell",
    'it gets the denial';
  every_call_has_one_result($events, 'tool.call and tool.result once each');
};

subtest 'a gate without a valid verdict fails loud and runs nothing' => sub {
  my ( $raider, $engine, $mcp ) = raider(
    { _tool_gate => sub { { verdict => 'maybe' } } },
    { tool_calls => [ [ bash => {} ] ] }, { text => 'all done' },
  );
  like dies { run_f($raider->raid_f('go')) }, qr/_tool_gate gave no valid verdict for tool 'bash'/,
    'croaks';
  is $mcp->calls, [], 'the tool did not run';
};

done_testing;
