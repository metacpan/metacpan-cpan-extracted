#!/usr/bin/env perl
# ABSTRACT: Tool arguments are checked against the tool's inputSchema before it runs (k122)
use strict;
use warnings;
use Test2::V0;
use Future;
use IO::Async::Loop;
use JSON::MaybeXS qw( JSON );
use Langertha::Raider;
use Langertha::Raider::ToolArgs qw( tool_args_problems );

# ADR 0005, step "validate" of the one execution path: a call whose arguments
# clearly break the inputSchema the model was shown -- a required key missing,
# a top-level property of the wrong type -- does not run the tool. The model
# gets an isError result saying what is wrong, the raid goes on, and the call
# still has exactly one tool.call and one tool.result (k134). Offline, through
# a scripted engine.

#### The checker

my $schema = {
  type       => 'object',
  properties => {
    path    => { type => 'string' },
    count   => { type => 'integer' },
    ratio   => { type => 'number' },
    force   => { type => 'boolean' },
    opts    => { type => 'object' },
    tags    => { type => 'array' },
    maybe   => { type => [ 'string', 'null' ] },
    any     => { description => 'no type' },
    weird   => { type => 'uuid' },
    nested  => { type => 'object', properties => { deep => { type => 'integer' } } },
  },
  required => [ 'path' ],
};

subtest 'clear violations are reported' => sub {
  is [ tool_args_problems($schema, {}) ], [ "missing required property 'path'" ],
    'missing required key';
  is [ tool_args_problems($schema, undef) ], [ "missing required property 'path'" ],
    'undef arguments count as {}';
  is [ tool_args_problems($schema, { path => undef }) ],
    [ "property 'path' must be string, got null" ], 'null for a required string';
  is [ tool_args_problems($schema, { path => 'x', count => 'many' }) ],
    [ "property 'count' must be integer, got string" ], 'non-numeric string for integer';
  is [ tool_args_problems($schema, { path => 'x', count => 1.5 }) ],
    [ "property 'count' must be integer, got number" ], 'fraction for integer';
  is [ tool_args_problems($schema, { path => 'x', ratio => 'half' }) ],
    [ "property 'ratio' must be number, got string" ], 'string for number';
  is [ tool_args_problems($schema, { path => 'x', force => 'false' }) ],
    [ "property 'force' must be boolean, got string" ],
    '"false" for boolean -- true in Perl, so rejected';
  is [ tool_args_problems($schema, { path => [ 'x' ] }) ],
    [ "property 'path' must be string, got array" ], 'array for string';
  is [ tool_args_problems($schema, { path => JSON->true }) ],
    [ "property 'path' must be string, got boolean" ], 'boolean for string';
  is [ tool_args_problems($schema, { path => 'x', count => JSON->false }) ],
    [ "property 'count' must be integer, got boolean" ], 'boolean for integer';
  is [ tool_args_problems($schema, { path => 'x', opts => [] }) ],
    [ "property 'opts' must be object, got array" ], 'array for object';
  is [ tool_args_problems($schema, { path => 'x', tags => 'a,b' }) ],
    [ "property 'tags' must be array, got string" ], 'string for array';
  is [ tool_args_problems($schema, { path => 'x', maybe => 3 }) ], [],
    'a number passes as string or null';
  is [ tool_args_problems($schema, { path => 'x', maybe => {} }) ],
    [ "property 'maybe' must be string or null, got object" ], 'type lists are named in full';
  is [ tool_args_problems($schema, { count => 'x', tags => {} }) ], [
    "missing required property 'path'",
    "property 'count' must be integer, got string",
    "property 'tags' must be array, got object",
  ], 'all problems at once: required first, then properties by name';
  is [ tool_args_problems({ type => 'object' }, [ 1 ]) ],
    [ 'arguments must be an object, got array' ], 'non-object arguments for an object schema';
};

subtest 'lenient where the schema or Perl is ambiguous' => sub {
  is [ tool_args_problems($schema, {
    path => 'x', count => 5, ratio => 0.5, force => JSON->true, opts => {}, tags => [],
    maybe => undef,
  }) ], [], 'well-typed arguments pass';
  is [ tool_args_problems($schema, { path => 'x', count => '5', ratio => '2.5' }) ], [],
    'numeric strings pass as integer / number';
  is [ tool_args_problems($schema, { path => 'x', count => '5.0' }) ], [],
    '5.0 is an integer';
  is [ tool_args_problems($schema, { path => 42 }) ], [], 'a number passes as string';
  is [ tool_args_problems($schema, { path => 'x', force => 1 }) ], [], '1 passes as boolean';
  is [ tool_args_problems($schema, { path => 'x', force => '0' }) ], [], '"0" passes as boolean';
  is [ tool_args_problems($schema, { path => 'x', count => undef, opts => undef }) ], [],
    'null for an optional property counts as absent';
  is [ tool_args_problems($schema, { path => 'x', any => [ 1 ], weird => {} }) ], [],
    'no type, or a type name it does not know: not checked';
  is [ tool_args_problems($schema, { path => 'x', nested => { deep => 'no' } }) ], [],
    'nested schemas are not checked';
  is [ tool_args_problems($schema, { path => 'x', extra => [ 1 ] }) ], [],
    'undeclared properties pass (additionalProperties is not checked)';
  is [ tool_args_problems(undef, {}) ], [], 'no schema: nothing checked';
  is [ tool_args_problems({}, { a => 1 }) ], [], 'empty schema: nothing checked';
  is [ tool_args_problems({ type => 'string' }, 'x') ], [], 'a non-object schema: nothing checked';
  is [ tool_args_problems({ properties => {} }, [ 1 ]) ], [],
    'non-object arguments without an explicit object type: not judged';
  is [ tool_args_problems({ type => 'object', required => 'path' }, {}) ], [],
    'a malformed required list is ignored';
};

#### Through a raid

my $loop = IO::Async::Loop->new;

{
  package K122::Response;
  use Moose;
  sub is_success  { 1 }
  sub status_line { '200 OK' }
  sub content     { '' }
  __PACKAGE__->meta->make_immutable;
}

{
  # One MCP source: `record` has a schema, `loose` has none.
  package K122::MCP;
  use Moose;
  use Future;
  has calls => (is => 'ro', default => sub { [] });
  sub list_tools {
    Future->done([
      { name => 'record', inputSchema => {
        type => 'object',
        properties => { note => { type => 'string' }, times => { type => 'integer' } },
        required => [ 'note' ],
      } },
      { name => 'loose' },
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
  package K122::Engine;
  use Moose;
  has script      => (is => 'rw', default => sub { [] });
  has mcp_servers => (is => 'ro', default => sub { [] });
  has captured    => (is => 'ro', default => sub { [] });
  has requests    => (is => 'rw', default => 0);
  has _next       => (is => 'rw');

  sub async_loop { $loop }
  sub async_request_f {
    my ( $self ) = @_;
    $self->requests($self->requests + 1);
    my $step = shift @{ $self->script } // { text => 'done' };
    $self->_next($step);
    return Future->done(K122::Response->new);
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
  sub chat_model              { 'k122-model' }
  __PACKAGE__->meta->make_immutable;
}

sub raider {
  my ( $args, @script ) = @_;
  my $mcp    = K122::MCP->new;
  my $engine = K122::Engine->new(script => [ @script ], mcp_servers => [ $mcp ]);
  my @events;
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    raider_mcp            => 1,
    no_session_embeddings => 1,
    plugins               => [
      '+Langertha::Raider::Plugin::Events' => { on_event => sub {
        my ( $type, %payload ) = @_;
        push @events, { type => $type, %payload };
      } },
    ],
    %$args,
  );
  return ( $raider, $engine, $mcp, \@events );
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

# Checks that every tool.call has exactly one tool.result, and no result is
# without its call.
sub every_call_has_one_result {
  my ( $events, $label ) = @_;
  my %n;
  $n{ $_->{call} }{ $_->{type} }++ for @$events;
  is \%n, { map { $_ => { 'tool.call' => 1, 'tool.result' => 1 } } keys %n }, $label;
}

subtest 'MCP tool: a missing required key does not run the tool' => sub {
  my ( $raider, $engine, $mcp, $events ) = raider({},
    { tool_calls => [ [ record => { times => 2 } ], [ record => { note => 'ok' } ] ] },
    { text => 'all done' },
  );
  my $r = run_f($raider->raid_f('record'));
  ok $r->is_final, 'the raid goes on to a final answer';
  is $engine->requests, 2, 'the model got a turn with the error result';

  is $mcp->calls, [ [ record => { note => 'ok' } ] ],
    'only the valid call reached the tool';   # red without the check: both ran

  my $bad = result_for($engine, 'tc1');
  ok $bad->{isError}, 'the model gets an error result';
  is text_of($bad),
    "arguments do not match the input schema of tool 'record': missing required property 'note'",
    'saying what is wrong';
  is text_of(result_for($engine, 'tc2')), 'ran record', 'the valid call ran normally';

  is [ map { [ $_->{type}, $_->{call}, $_->{status} ] } @$events ], [
    [ 'tool.call',   'c1', 'dispatched' ],
    [ 'tool.result', 'c1', 'failed' ],
    [ 'tool.call',   'c2', 'dispatched' ],
    [ 'tool.result', 'c2', 'succeeded' ],
  ], 'the rejected call has its tool.call and a failed tool.result';
  every_call_has_one_result($events, 'every tool.call has exactly one tool.result');
  is $raider->metrics->{tool_calls}, 2, 'the rejected call counts as a tool call';
};

subtest 'MCP tool: a wrong top-level type does not run the tool' => sub {
  my ( $raider, $engine, $mcp, $events ) = raider({},
    { tool_calls => [ [ record => { note => 'x', times => 'twice' } ] ] },
    { text => 'all done' },
  );
  ok run_f($raider->raid_f('record'))->is_final, 'final';
  is $mcp->calls, [], 'the tool did not run';
  is text_of(result_for($engine, 'tc1')),
    "arguments do not match the input schema of tool 'record': property 'times' must be integer, got string",
    'the model is told which property has which wrong type';
  every_call_has_one_result($events, 'tool.call and tool.result once each');
};

subtest 'MCP tool: lenient cases still run' => sub {
  my ( $raider, $engine, $mcp ) = raider({},
    { tool_calls => [
      [ record => { note => 'x', times => '3' } ],
      [ record => { note => 'y', times => undef, extra => [ 1 ] } ],
      [ loose  => { anything => [ 1 ] } ],
      [ loose  => undef ],
    ] },
    { text => 'all done' },
  );
  ok run_f($raider->raid_f('go'))->is_final, 'final';
  is [ map { $_->[0] } @{ $mcp->calls } ], [ qw( record record loose loose ) ],
    'numeric string, null optional, extra keys and a schema-less tool all run';
  ok !( grep { $_->{result}{isError} } @{ $engine->captured } ), 'no error result';
};

subtest 'self-tools are checked against their own schema' => sub {
  my ( $raider, $engine, $mcp, $events ) = raider({},
    { tool_calls => [
      [ raider_ask_user => { options => [ 'a' ] } ],
      [ raider_wait     => { seconds => 'soon' } ],
    ] },
    { text => 'all done' },
  );
  my $r = run_f($raider->raid_f('ask'));
  ok $r->is_final, 'no pause: raider_ask_user without a question did not run';
  is text_of(result_for($engine, 'tc1')),
    "arguments do not match the input schema of tool 'raider_ask_user': missing required property 'question'",
    'raider_ask_user gets the error';
  is text_of(result_for($engine, 'tc2')),
    "arguments do not match the input schema of tool 'raider_wait': property 'seconds' must be number, got string",
    'raider_wait gets the error and does not wait';
  every_call_has_one_result($events, 'tool.call and tool.result once each');
};

subtest 'a valid self-tool call still runs' => sub {
  my ( $raider, $engine ) = raider({},
    { tool_calls => [ [ raider_wait => { seconds => '0' } ] ] },
    { text => 'all done' },
  );
  ok run_f($raider->raid_f('wait'))->is_final, 'final';
  is text_of(result_for($engine, 'tc1')), 'Waited 0 seconds.', 'the wait ran';
};

subtest 'the calls resumed after a pause are checked too' => sub {
  my ( $raider, $engine, $mcp, $events ) = raider({},
    { tool_calls => [
      [ raider_ask_user => { question => 'Go?' } ],
      [ record          => { times => 1 } ],
    ] },
    { text => 'all done' },
  );
  ok run_f($raider->raid_f('ask'))->is_question, 'pauses on ask_user';
  ok run_f($raider->respond_f('yes'))->is_final, 'respond resumes to a final answer';
  is $mcp->calls, [], 'the invalid resumed call did not run';
  like text_of(result_for($engine, 'tc2')), qr/missing required property 'note'/,
    'it gets the error result';
  every_call_has_one_result($events, 'tool.call and tool.result once each');
};

subtest 'inline tools: the schema given as input_schema is checked' => sub {
  my @runs;
  my ( $raider, $engine ) = raider({ tools => [ {
      name => 'greet', description => 'greet',
      input_schema => { type => 'object', properties => { name => { type => 'string' } },
        required => [ 'name' ] },
      code => sub { push @runs, $_[1]; $_[0]->text_result('hi') },
    } ] },
    { tool_calls => [ [ greet => {} ], [ greet => { name => 'x' } ] ] },
    { text => 'all done' },
  );
  ok run_f($raider->raid_f('greet'))->is_final, 'final';
  is \@runs, [ { name => 'x' } ], 'only the valid call ran';
  like text_of(result_for($engine, 'tc1')), qr/missing required property 'name'/,
    'the invalid call got the error';
};

subtest 'the call as plugin_before_tool_call hands it on is what is checked' => sub {
  {
    package K122::Fixer;
    use Moose;
    use Future::AsyncAwait;
    extends 'Langertha::Plugin';
    async sub plugin_before_tool_call {
      my ( $self, $name, $input ) = @_;
      return ( $name, { %{ $input // {} }, note => 'filled in' } );
    }
    __PACKAGE__->meta->make_immutable;
  }
  my $mcp    = K122::MCP->new;
  my $engine = K122::Engine->new(mcp_servers => [ $mcp ], script => [
    { tool_calls => [ [ record => {} ] ] }, { text => 'all done' },
  ]);
  my $raider = Langertha::Raider->new(
    engine => $engine, no_session_embeddings => 1, plugins => [ '+K122::Fixer' ],
  );
  ok run_f($raider->raid_f('go'))->is_final, 'final';
  is $mcp->calls, [ [ record => { note => 'filled in' } ] ],
    'the rewritten arguments pass and run';
};

done_testing;
