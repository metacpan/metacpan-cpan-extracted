#!/usr/bin/perl -w

use strict;
#use Test::More 'no_plan';
use Test::More tests => 57;

my $CLASS;
BEGIN { 
    $CLASS = 'FSA::Rules';
    use_ok($CLASS) or die;
}

ok my $fsa = $CLASS->new, "Construct an empty state machine";

# Try try_switch with parameters.
ok $fsa = $CLASS->new(
    foo => {
        rules => [
            bar => [ sub { $_[1]  eq 'bar' } ],
            foo => [ sub { $_[1]  eq 'foo' } ],
        ]
    },
    bar => {
        rules => [
            foo => [ sub { $_[1]  eq 'foo' } ],
            bar => [ sub { $_[1]  eq 'bar' } ],
        ]
    }
), 'Construct with switch rules that expect parameters.';

ok my $foo = $fsa->start, "... Start up the machine";
isa_ok $foo, 'FSA::State';
is $foo->name, 'foo', "... It should start with 'foo'";
ok my $bar = $fsa->switch('bar'),
  "... Switch to the next state";
isa_ok $bar, 'FSA::State';
is $bar->name, 'bar', "... It should start with 'bar'";
is $fsa->switch('bar'), $bar,  "... It should switch to 'bar' when passed 'bar'";
is $fsa->curr_state, $bar, "... So the state should now be 'bar'";
is $fsa->switch('bar'), $bar,
  "... It should stay as 'bar' when passed 'bar' again";
is $fsa->curr_state, $bar, "... So the state should still be 'bar'";
is $fsa->try_switch('foo'), $foo,
  "... It should switch back to 'foo' when passed 'foo'";
is $fsa->curr_state, $foo, "... So the state should now be back to 'foo'";

can_ok $CLASS, 'stack';
is_deeply $fsa->stack, [qw/foo bar bar bar foo/],
  "... and it should have a stack of the state transformations";

can_ok $CLASS, 'reset';
$fsa->reset;
is_deeply $fsa->stack, [],
  '... It should clear out the stack';
is $fsa->curr_state, undef, '... It set the current state to undef';

# these are not duplicate tests.  We need to ensure that the state machine
# behavior is deterministic
is $fsa->start, $foo, "... It should start with 'foo'";
is $fsa->switch('bar'), $bar,
  "... It should switch to 'bar' when passed 'bar'";
is $fsa->curr_state, $bar, "... So the state should now be 'bar'";
is $fsa->switch('bar'), $bar,
  "... It should stay as 'bar' when passed 'bar' again";
is $fsa->curr_state, $bar, "... So the state should still be 'bar'";
is $fsa->try_switch('foo'), $foo,
  "... It should switch back to 'foo' when passed 'foo'";
is $fsa->curr_state, $foo, "... So the state should now be back to 'foo'";
is_deeply $fsa->stack, [qw/foo bar bar foo/],
  "... and it should have a stack of the state transformations";

can_ok $foo, 'result';
can_ok $foo, 'message';
can_ok $fsa, 'last_message';
can_ok $fsa, 'last_result';

undef $fsa;
my $counter  = 1;
my $acounter = 'a';
ok $fsa = $CLASS->new(
    foo => {
        do    => sub {
            my $state = shift;
            $state->result($acounter++);
        },
        rules => [
            bar => [ sub { $_[1]  eq 'bar' } ],
            foo => [ sub { $_[1]  eq 'foo' } ],
        ]
    },
    bar => {
        do    => sub {
            my $state = shift;
            $state->message('bar has been called ', $counter, ' times');
            $state->result($counter++);
        },
        rules => [
            foo => [ sub { $_[1]  eq 'foo' } ],
            bar => [ sub { $_[1]  eq 'bar' } ],
        ]
    }
), 'Construct with switch rules that expect parameters.';

ok my @states = $fsa->states, "... We should get states back from states()";
is scalar @states, 2, "... There should be two states";
isa_ok $states[$_], 'FSA::State', "... State # $_ should be an FSA::State object"
  for (0..1);
is $states[0]->name, 'foo', "...The first state should be 'foo'";
is $states[1]->name, 'bar', "...The second state should be 'foo'";
is $foo = $fsa->states('foo'), $states[0],
  "... Called with a 'foo', states() should return the appropriate state";
is $bar = $fsa->states('bar'), $states[1],
  "... Called with a 'bar', states() should return the appropriate state";
is_deeply [ $fsa->states(qw(bar foo))], [@states[1, 0]],
  "... Called with two arguments, it should return both states in the order of the arguments";

$fsa->start;
$fsa->switch('bar');
$fsa->switch('bar');
$fsa->switch('foo');

is $fsa->last_result, 'b', '... and last_result() should return the last result';
is $fsa->last_result('bar'), 2,
  '... and last_result() shoul return the last result for a specified state';
is scalar $foo->result, 'b', '... and result should return its last result';

is scalar $bar->result, 2,
  '... and the last result on bar should be returned in a scalar context';
is_deeply [$bar->result], [1,2],
  '... or all results of the state if called in list context';

is $fsa->last_message, undef,
  '... and last_message should return undef if the last state had no message set';
is $fsa->last_message('bar'), 'bar has been called 2 times',
  '... and last_message should return the message for a specified state';
is scalar $bar->message, 'bar has been called 2 times',
  '... and the last result on bar should be returned in a scalar context';
is_deeply [$bar->message], [
    'bar has been called 1 times',
    'bar has been called 2 times',
],
  '... or all messages of of the state if called in list context';

can_ok $fsa, 'stacktrace';
my $stacktrace = $fsa->stacktrace;
is $stacktrace, <<"END_TRACE", '... and it should return a human readable trace';
State: foo
{
  message => undef,
  result => 'a'
}

State: bar
{
  message => 'bar has been called 1 times',
  result => 1
}

State: bar
{
  message => 'bar has been called 2 times',
  result => 2
}

State: foo
{
  message => undef,
  result => 'b'
}

END_TRACE

can_ok $fsa, 'raw_stacktrace';
my $expected = [
  [
    'foo',
    {
      'message' => undef,
      'result' => 'a'
    }
  ],
  [
    'bar',
    {
      'message' => 'bar has been called 1 times',
      'result' => 1
    }
  ],
  [
    'bar',
    {
      'message' => 'bar has been called 2 times',
      'result' => 2
    }
  ],
  [
    'foo',
    {
      'message' => undef,
      'result' => 'b'
    }
  ]
];

is_deeply $fsa->raw_stacktrace, $expected,
  '... and it should return the raw data structure of the state stack.';

can_ok $fsa, 'prev_state';
is $fsa->prev_state->name, 'bar',
  '... and it should correctly return the the previous state object';
