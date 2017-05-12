#!/usr/bin/perl -w

use strict;
#use Test::More 'no_plan';
use Test::More tests => 327;

my $CLASS;
BEGIN {
    $CLASS = 'FSA::Rules';
    use_ok($CLASS) or die;
}

ok my $fsa = $CLASS->new, "Construct an empty state machine";
isa_ok $fsa, $CLASS;

ok $fsa = $CLASS->new(
    foo => {},
), "Construct with a single state";

is $fsa->curr_state, undef, "... The current state should be undefined";
ok my $state =  $fsa->curr_state('foo'), "... We should be able to set the state";
isa_ok $state, 'FSA::State';
is $state->name, 'foo', "... The name of the current state should be 'foo'";
is $state->label, undef, '... The label should be undef';
is $state->machine, $fsa, '... The state object should return the machine';
is $fsa->curr_state, $state, "... The current state should be 'foo'";
is $fsa->done, undef, "... It should not be done";
is $fsa->done(1), $fsa, "... But we can set doneness";
is $fsa->done, 1, "... And then retreive that value";
is $fsa->strict, undef, "... It should not be strict";
is $fsa->strict(1), $fsa, "... But we can set strict";
is $fsa->strict, 1, "... And now strict is turned on";

# Try a bogus state.
eval { $fsa->curr_state('bogus') };
ok my $err = $@, "... Assigning a bogus state should fail";
like $err, qr/No such state "bogus"/, "... And throw the proper exception";

# Try a do code ref.
ok $fsa = $CLASS->new(
    foo => {
        label => 'This is foo',
        do => sub { shift->machine->{foo}++ }
    },
), "Construct with a single state with an action";

is $fsa->curr_state, undef, "... The current state should be undefined";
is $fsa->{foo}, undef, "... The code should not have been executed";
ok $state = $fsa->curr_state('foo'), "... We should be able to set the state";
isa_ok $state, 'FSA::State';
is $state->name, 'foo', "... The name of the current state should be 'foo'";
is $state->label, 'This is foo', 'The label should be set';
is $fsa->curr_state, $state, "... The current state should be 'foo'";
is $fsa->{foo}, 1, "... The code should now have been executed";

# Try a do code array ref.
ok $fsa = $CLASS->new(
    foo => {
        do => [ sub { shift->machine->{foo}++ },
                sub { shift->machine->{foo}++ } ],
    },
), "Construct with a single state with two actions";

is $fsa->curr_state, undef, "... The current state should be undefined";
is $fsa->{foo}, undef, "... The code should not have been executed";
ok $state = $fsa->curr_state('foo'), "... We should be able to set the state";
isa_ok $state, 'FSA::State';
is $state->name, 'foo', "... The name of the current state should be 'foo'";
is $fsa->curr_state, $state, "... The current state should be 'foo'";
is $fsa->{foo}, 2, "... Both actions should now have been executed";

# Try a single enter action.
ok $fsa = $CLASS->new(
    foo => {
        on_enter => sub { shift->machine->{foo_enter}++ },
        do => sub { shift->machine->{foo}++ }
    },
), "Construct with a single state with an enter action";

is $fsa->curr_state, undef, "... The current state should be undefined";
is $fsa->{foo}, undef, "... The code should not have been executed";
is $fsa->{foo_enter}, undef, "... The enter code should not have executed";
ok $state = $fsa->curr_state('foo'), "... We should be able to set the state";
isa_ok $state, 'FSA::State';
is $state->name, 'foo', "... The name of the current state should be 'foo'";
is $fsa->curr_state, $state, "... The current state should be 'foo'";
is $fsa->{foo}, 1, "... The code should now have been executed";
is $fsa->{foo_enter}, 1, "... The enter code should have executed";

# Try an enter action array ref.
ok $fsa = $CLASS->new(
    foo => {
        on_enter => [ sub { shift->machine->{foo_enter}++ },
                      sub { shift->machine->{foo_enter}++ }
                    ],
        do => sub { shift->machine->{foo}++ }
    },
), "Construct with a single state with multiple enter actions";

is $fsa->curr_state, undef, "... The current state should be undefined";
is $fsa->{foo}, undef, "... The code should not have been executed";
is $fsa->{foo_enter}, undef, "... The enter code should not have executed";
ok $state = $fsa->curr_state('foo'), "... We should be able to set the state";
isa_ok $state, 'FSA::State';
is $state->name, 'foo', "... The name of the current state should be 'foo'";
is $fsa->curr_state, $state, "... The current state should be 'foo'";
is $fsa->{foo}, 1, "... The code should now have been executed";
is $fsa->{foo_enter}, 2, "... Both enter actions should have executed";

# Try a second state with exit actions in the first state.
ok $fsa = $CLASS->new(
    foo => {
        on_enter => sub { shift->machine->{foo_enter}++ },
        do => sub { shift->machine->{foo}++ },
        on_exit => sub { shift->machine->{foo_exit}++ },
    },
    bar => {
        on_enter => sub { shift->machine->{bar_enter}++ },
        do => sub { $_[0]->machine->{bar} = $_[0]->machine->{bar_enter} }
    },
), "Construct with a two states and a exit action";

is $fsa->curr_state, undef, "... The current state should be undefined";
is $fsa->{foo}, undef, "... The foo code should not have been executed";
is $fsa->{foo_enter}, undef, "... The 'foo' enter code should not have executed";
is $fsa->{bar}, undef, "... The bar code should not have been executed";
is $fsa->{bar_enter}, undef, "... The enter code should not have executed";
ok $state = $fsa->curr_state('foo'), "... We should be able to set the state";
isa_ok $state, 'FSA::State';
is $state->name, 'foo', "... The name of the current state should be 'foo'";
is $fsa->curr_state, $state, "... The current state should be 'foo'";
is $fsa->{foo}, 1, "... The 'foo' code should now have been executed";
is $fsa->{foo_enter}, 1, "... The  'foo' enter action should have executed";
is $fsa->{foo_exit}, undef, "... The  'foo' exit action should not have executed";
ok $state = $fsa->curr_state('bar'), "... We should be able to change the state to 'bar'";
isa_ok $state, 'FSA::State';
is $state->name, 'bar', "... The name of the current state should be 'bar'";
is $fsa->curr_state, $state, "... The current state should be 'bar'";
is $fsa->{foo_exit}, 1, "... The 'foo' exit action should have executed";
is $fsa->{bar}, 1, "... The 'bar' code should now have been executed";
is $fsa->{bar_enter}, 1, "... The 'bar' enter action should have executed";

# Try a second state with multiple exit actions in the first state.
ok $fsa = $CLASS->new(
    foo => {
        on_enter => sub { shift->machine->{foo_enter}++ },
        do => sub { shift->machine->{foo}++ },
        on_exit => [sub { shift->machine->{foo_exit}++ }, sub { shift->machine->{foo_exit}++ } ],
    },
    bar => {
        on_enter => sub { shift->machine->{bar_enter}++ },
        do => sub { $_[0]->machine->{bar} = $_[0]->machine->{bar_enter} }
    },
), "Construct with a two states and multiple exit actions";

is $fsa->curr_state, undef, "... The current state should be undefined";
is $fsa->{foo}, undef, "... The foo code should not have been executed";
is $fsa->{foo_enter}, undef, "... The 'foo' enter code should not have executed";
is $fsa->{bar}, undef, "... The bar code should not have been executed";
is $fsa->{bar_enter}, undef, "... The enter code should not have executed";
ok $state = $fsa->curr_state('foo'), "... We should be able to set the state";
isa_ok $state, 'FSA::State';
is $state->name, 'foo', "... The name of the current state should be 'foo'";
is $fsa->curr_state, $state, "... The current state should be 'foo'";
is $fsa->{foo}, 1, "... The 'foo' code should now have been executed";
is $fsa->{foo_enter}, 1, "... The  'foo' enter action should have executed";
is $fsa->{foo_exit}, undef, "... The  'foo' exit action should not have executed";
ok $state = $fsa->curr_state('bar'), "... We should be able to change the state to 'bar'";
isa_ok $state, 'FSA::State';
is $state->name, 'bar', "... The name of the current state should be 'bar'";
is $fsa->curr_state, $state, "... The current state should be 'bar'";
is $fsa->{foo_exit}, 2, "... Both 'foo' exit actions should have executed";
is $fsa->{bar}, 1, "... The 'bar' code should now have been executed";
is $fsa->{bar_enter}, 1, "... The  'bar' enter action should have executed";

# Set up switch rules (rules).
ok $fsa = $CLASS->new(
    foo => {
        on_enter => sub { shift->machine->{foo_enter}++ },
        do => sub { shift->machine->{foo}++ },
        on_exit => sub { shift->machine->{foo_exit}++ },
        rules => [
            bar => sub { shift->machine->{foo} },
        ],
    },
    bar => {
        on_enter => sub { shift->machine->{bar_enter}++ },
        do => sub { $_[0]->machine->{bar} = $_[0]->machine->{bar_enter} },
    },
), "Construct with a two states and a switch rule";

is $fsa->curr_state, undef, "... The current state should be undefined";
is $fsa->{foo}, undef, "... The foo code should not have been executed";
is $fsa->{foo_enter}, undef, "... The 'foo' enter code should not have executed";
is $fsa->{bar}, undef, "... The bar code should not have been executed";
is $fsa->{bar_enter}, undef, "... The enter code should not have executed";
ok $state = $fsa->curr_state('foo'), "... We should be able to set the state";
isa_ok $state, 'FSA::State';
is $state->name, 'foo', "... The name of the current state should be 'foo'";
is $fsa->curr_state, $state, "... The current state should be 'foo'";
is $fsa->{foo}, 1, "... The 'foo' code should now have been executed";
is $fsa->{foo_enter}, 1, "... The  'foo' enter action should have executed";
is $fsa->{foo_exit}, undef, "... The 'foo' exit action should not have executed";
ok $state =  $fsa->try_switch, "... The try_switch method should return the 'bar' state";
isa_ok $state, 'FSA::State';
is $state->name, 'bar', "... The name of the current state should be 'bar'";
is $fsa->curr_state, $state, "... The current state should be 'bar'";
is $fsa->{foo_exit}, 1, "... Now the 'foo' exit action should have executed";
is $fsa->{bar}, 1, "... And the 'bar' code should now have been executed";
is $fsa->{bar_enter}, 1, "... And the 'bar' enter action should have executed";

# There are no switchs from bar.
eval { $fsa->switch };
ok $err = $@, "... Another attempt to switch should fail";
like $err, qr/Cannot determine transition from state "bar"/,
  "... And throw the proper exception";

# Test that rule labels are no-ops for normal operation
ok $fsa = $CLASS->new(
    foo => {
        on_enter => sub { shift->machine->{foo_enter}++ },
        do       => sub { shift->machine->{foo}++ },
        on_exit  => sub { shift->machine->{foo_exit}++ },
        rules => [
            bar => {
                rule    => sub { shift->machine->{foo} },
                message => 'some rule label',
            },
        ],
    },
    bar => {
        on_enter => sub { shift->machine->{bar_enter}++ },
        do => sub { $_[0]->machine->{bar} = $_[0]->machine->{bar_enter} },
    },
), "Construct with a two states and a switch rule";

is $fsa->curr_state, undef, "Adding labels to rules should not affect behavior";
is $fsa->{foo}, undef, "... The foo code should not have been executed";
is $fsa->{foo_enter}, undef, "... The 'foo' enter code should not have executed";
is $fsa->{bar}, undef, "... The bar code should not have been executed";
is $fsa->{bar_enter}, undef, "... The enter code should not have executed";
ok $state = $fsa->curr_state('foo'), "... We should be able to set the state";
isa_ok $state, 'FSA::State';
is $state->name, 'foo', "... The name of the current state should be 'foo'";
is $fsa->curr_state, $state, "... The current state should be 'foo'";
is $fsa->{foo}, 1, "... The 'foo' code should now have been executed";
is $fsa->{foo_enter}, 1, "... The  'foo' enter action should have executed";
is $fsa->{foo_exit}, undef, "... The 'foo' exit action should not have executed";
ok $state =  $fsa->try_switch, "... The try_switch method should return the 'bar' state";
isa_ok $state, 'FSA::State';
is $state->name, 'bar', "... The name of the current state should be 'bar'";
is $fsa->curr_state, $state, "... The current state should be 'bar'";
is $fsa->{foo_exit}, 1, "... Now the 'foo' exit action should have executed";
is $fsa->{bar}, 1, "... And the 'bar' code should now have been executed";
is $fsa->{bar_enter}, 1, "... And the 'bar' enter action should have executed";

can_ok $fsa, 'states';
my @messages = map { $_->message } $fsa->states('foo');
is $messages[0], 'some rule label',
  '... and states should have messages automatically added';
eval {$fsa->states('no_such_state')};
ok $@, '... but asking for a state that was never defined should die';
like $@, qr/No such state\(s\) 'no_such_state'/, '... with an appropriate error message';

# Try switch actions.
ok $fsa = $CLASS->new(
    foo => {
        on_enter => sub { shift->machine->{foo_enter}++ },
        do => sub { shift->machine->{foo}++ },
        on_exit => sub { shift->machine->{foo_exit}++ },
        rules => [
            bar => [sub { shift->machine->{foo} },
                    sub {
                        my ($foo, $bar) = @_;
                        isa_ok $_, 'FSA::State' for ($foo, $bar);
                        is $foo->name, 'foo', 'The first parameter is "foo"';
                        is $bar->name, 'bar', 'The second parameter is "bar"';
                        $foo->machine->{foo_bar}++ }
                   ],
        ],
    },
    bar => {
        on_enter => sub { $_[0]->machine->{bar_enter} = $_[0]->machine->{foo_bar} },
        do => sub { $_[0]->machine->{bar} = $_[0]->machine->{bar_enter} }
    },
), "Construct with a two states and a switch rule with its own action";

is $fsa->curr_state, undef, "... The current state should be undefined";
is $fsa->{foo}, undef, "... The foo code should not have been executed";
is $fsa->{foo_enter}, undef, "... The 'foo' enter code should not have executed";
is $fsa->{bar}, undef, "... The bar code should not have been executed";
is $fsa->{bar_enter}, undef, "... The enter code should not have executed";
ok $state = $fsa->curr_state('foo'), "... We should be able to set the state";
isa_ok $state, 'FSA::State';
is $state->name, 'foo', "... The name of the current state should be 'foo'";
is $fsa->curr_state, $state, "... The current state should be 'foo'";
is $fsa->{foo}, 1, "... The 'foo' code should now have been executed";
is $fsa->{foo_enter}, 1, "... The  'foo' enter action should have executed";
is $fsa->{foo_exit}, undef, "... The 'foo' exit action should not have executed";
ok $state =  $fsa->switch, "... The switch method should return the 'bar' state";
isa_ok $state, 'FSA::State';
is $state->name, 'bar', "... The name of the current state should be 'bar'";
is $fsa->curr_state, $state, "... The current state should be 'bar'";
is $fsa->{foo_exit}, 1, "... Now the 'foo' exit action should have executed";
is $fsa->{bar}, 1, "... And the 'bar' code should now have been executed";
is $fsa->{foo_bar}, 1, "... And the 'foo' to 'bar' switch action should have executed";
is $fsa->{bar_enter}, 1, "... And the 'bar' enter action should have executed";

# Try a simple true value switch rule.
ok $fsa = $CLASS->new(
    foo => {
        on_enter => sub { shift->machine->{foo_enter}++ },
        do => sub { shift->machine->{foo}++ },
        on_exit => sub { shift->machine->{foo_exit}++ },
        rules => [
            foo => 0,
            bar => 1
        ],
    },
    bar => {
        on_enter => sub { shift->machine->{bar_enter}++ },
        do => sub { $_[0]->machine->{bar} = $_[0]->machine->{bar_enter} }
    },
), "Construct with a two states and a switch rule of '1'";

is $fsa->curr_state, undef, "... The current state should be undefined";
is $fsa->{foo}, undef, "... The foo code should not have been executed";
is $fsa->{foo_enter}, undef, "... The 'foo' enter code should not have executed";
is $fsa->{bar}, undef, "... The bar code should not have been executed";
is $fsa->{bar_enter}, undef, "... The enter code should not have executed";
ok $state = $fsa->curr_state('foo'), "... We should be able to set the state";
isa_ok $state, 'FSA::State';
is $state->name, 'foo', "... The name of the current state should be 'foo'";
is $fsa->curr_state, $state, "... The current state should be 'foo'";
is $fsa->{foo}, 1, "... The 'foo' code should now have been executed";
is $fsa->{foo_enter}, 1, "... The  'foo' enter action should have executed";
is $fsa->{foo_exit}, undef, "... The 'foo' exit action should not have executed";
ok $state =  $fsa->switch, "... The switch method should return the 'bar' state";
isa_ok $state, 'FSA::State';
is $state->name, 'bar', "... The name of the current state should be 'bar'";
is $fsa->curr_state, $state, "... The current state should be 'bar'";
is $fsa->{foo_exit}, 1, "... Now the 'foo' exit action should have executed";
is $fsa->{bar}, 1, "... And the 'bar' code should now have been executed";
is $fsa->{bar_enter}, 1, "... And the 'bar' enter action should have executed";

# Try a simple true value switch rule with switch actions.
ok $fsa = $CLASS->new(
    foo => {
        on_enter => sub { shift->machine->{foo_enter}++ },
        do => sub { shift->machine->{foo}++ },
        on_exit => sub { shift->machine->{foo_exit}++ },
        rules => [
            bar => [1, sub { shift->machine->{foo_bar}++ } ],
        ],
    },
    bar => {
        on_enter => sub { $_[0]->machine->{bar_enter} = $_[0]->machine->{foo_bar} },
        do => sub { $_[0]->machine->{bar} = $_[0]->machine->{bar_enter} }
    },
), "Construct with a two states, a switch rule of '1', and a switch action";

is $fsa->curr_state, undef, "... The current state should be undefined";
is $fsa->{foo}, undef, "... The foo code should not have been executed";
is $fsa->{foo_enter}, undef, "... The 'foo' enter code should not have executed";
is $fsa->{bar}, undef, "... The bar code should not have been executed";
is $fsa->{bar_enter}, undef, "... The enter code should not have executed";
ok $state = $fsa->curr_state('foo'), "... We should be able to set the state";
isa_ok $state, 'FSA::State';
is $state->name, 'foo', "... The name of the current state should be 'foo'";
is $fsa->curr_state, $state, "... The current state should be 'foo'";
is $fsa->{foo}, 1, "... The 'foo' code should now have been executed";
is $fsa->{foo_enter}, 1, "... The  'foo' enter action should have executed";
is $fsa->{foo_exit}, undef, "... The 'foo' exit action should not have executed";
ok $state =  $fsa->switch, "... The switch method should return the 'bar' state";
isa_ok $state, 'FSA::State';
is $state->name, 'bar', "... The name of the current state should be 'bar'";
is $fsa->curr_state, $state, "... The current state should be 'bar'";
is $fsa->{foo_exit}, 1, "... Now the 'foo' exit action should have executed";
is $fsa->{foo_bar}, 1, "... And the 'foo' to 'bar' switch action should have executed";
is $fsa->{bar}, 1, "... And the 'bar' code should now have been executed";
is $fsa->{bar_enter}, 1, "... And the 'bar' enter action should have executed";

# Try start().
ok $fsa = $CLASS->new(
    foo => {
        do => sub { shift->machine->{foo}++ }
    },
), "Construct with a single state with an enter action";

is $fsa->curr_state, undef, "... The current state should be undefined";
is $fsa->{foo}, undef, "... The code should not have been executed";
ok $state = $fsa->start, "... The start method should return the start state";
isa_ok $state, 'FSA::State';
is $state->name, 'foo', "... The name of the current state should be 'foo'";
is $fsa->curr_state, $state, "... The current state should be 'foo'";
is $fsa->{foo}, 1, "... The code should now have been executed";
eval { $fsa->start };
ok $err = $@, '... Calling start on a running machine should die';
like $err, qr/Cannot start machine because it is already running/,
  '... And it should throw the proper exception';

# Try start() with a second state.
ok $fsa = $CLASS->new(
    foo => {
        do => sub { shift->machine->{foo}++ }
    },
    bar => {
        do => sub { shift->machine->{bar}++ }
    },
), "Construct with a single state with an enter action";

is $fsa->curr_state, undef, "... The current state should be undefined";
is $fsa->{foo}, undef, "... The 'foo' code should not have been executed";
is $fsa->{bar}, undef, "... The 'bar' code should not have been executed";
ok $state = $fsa->start, "... The start method should return the start state";
isa_ok $state, 'FSA::State';
is $state->name, 'foo', "... The name of the current state should be 'foo'";
is $fsa->curr_state, $state, "... The current state should be 'foo'";
is $fsa->{foo}, 1, "... The code should now have been executed";
is $fsa->{bar}, undef, "... The 'bar' code still should not have been executed";

# Try a bad switch state name.
eval {
    $CLASS->new(
        foo => { rules => [bad => 1] }
    )
};

ok $err = $@, "A bad state name in rules should fail";
like $err, qr/Unknown state "bad" referenced by state "foo"/,
  "... And give the appropriate error message";

# Try numbered states.
ok $fsa = $CLASS->new(
    0 => { rules => [ 1 => 1 ] },
    1 => {},
), "Construct with numbered states";
ok $state = $fsa->start, "... Call to start() should return state '0'";
isa_ok $state, 'FSA::State';
is $state->name, 0, "... The name of the current state should be '0'";
is $fsa->curr_state, $state, "... The current state should be '0'";

ok $state = $fsa->switch, "... Call to switch should return '1' state";
isa_ok $state, 'FSA::State';
is $state->name, 1, "... The name of the current state should be '1'";
is $fsa->curr_state, $state, "... The current state should be '1'";

# Try run().
ok $fsa = $CLASS->new(
    0 => { rules => [ 1 => [ 1, sub { shift->machine->{count}++ } ] ] },
    1 => { rules => [ 0 => [ 1, sub { $_[0]->done($_[0]->machine->{count} == 3 ) } ] ] },
), "Construct with simple states to run";

is $fsa->run, $fsa, "... Run should return the FSA object";
is $fsa->{count}, 3,
  "... And it should have run through the proper number of iterations.";
# Reset and try again.
$fsa->{count} = 0;
is $fsa->done(0), $fsa, "... We should be able to reset done";
ok $state = $fsa->curr_state,  "... We should be left in state '0'";
isa_ok $state, 'FSA::State';
is $state->name, 0, "... The name of the current state should be '0'";
is $fsa->run, $fsa, "... Run should still work.";
is $fsa->{count}, 3,
  "... And it should have run through the proper number of again.";

# Try done with a code refernce.
ok $fsa = $CLASS->new(
    0 => { rules => [ 1 => [ 1, sub { shift->machine->{count}++ } ] ] },
    1 => { rules => [ 0 => [ 1 ] ] },
), "Construct with simple states to test a done code ref";


is $fsa->done( sub { shift->{count} == 3 }), $fsa,
  "Set done to a code reference";
$fsa->{count} = 0;
is $fsa->run, $fsa, "... Run should still work.";
is $fsa->{count}, 3,
  "... And it should have run through the proper number of again.";

# Check for duplicate states.
eval { $CLASS->new( foo => {}, foo => {}) };
ok $err = $@, 'Attempt to specify the same state twice should throw an error';
like $err, qr/The state "foo" already exists/,
  '... And that exception should have the proper message';

# Try try_switch with parameters.
my %prevs = ( 1 => 'foo', 2 => 'bar');
ok $fsa = $CLASS->new(
    foo => {
        do => sub { shift->notes(test => 'foo') },
        rules => [
            bar => [ sub { $_[1]  eq 'bar' } ],
            foo => [ sub { $_[1]  eq 'foo' } ],
        ]
    },
    bar => {
        do => sub {
            my $state = shift;
            isa_ok $state->prev_state, 'FSA::State',
              "...state->prev_state should return a state object";
            is $state->prev_state->name, $prevs{++$state->{count}},
              "... state->prev_state should return the previous state";
        },
        rules => [
            foo => [ sub { $_[1]  eq 'foo' } ],
            bar => [ sub { $_[1]  eq 'bar' } ],
        ]
    }
), 'Construct with switch rules that expect parameters.';


ok my $foo = $fsa->start, "... It should start with 'foo'";
isa_ok $foo, 'FSA::State';
is $foo->name, 'foo', "... The name of the current state should be 'foo'";
is $fsa->curr_state, $foo, "... The current state should be 'foo'";
ok my $bar = $fsa->switch('bar'),
  "... It should switch to 'bar' when passed 'bar'";
isa_ok $bar, 'FSA::State';
is $bar->name, 'bar', "... The name of the current state should be 'bar'";
is $fsa->curr_state, $bar, "... The current state should be 'bar'";
is $fsa->switch('bar'), $bar,
  "... It should stay as 'bar' when passed 'bar' again";
is $fsa->curr_state, $bar, "... So the state should still be 'bar'";
is $fsa->try_switch('foo'), $foo,
  "... It should switch back to 'foo' when passed 'foo'";
is $fsa->curr_state, $foo, "... So the state should now be back to 'foo'";

# Try some notes.
is_deeply $fsa->notes, {test => 'foo'}, "Notes should start out empty";
is $fsa->notes( key => 'val' ), $fsa,
  "... And should get the machine back when setting a note";
is $fsa->notes('key'), 'val',
  "... And passing in the key should return the corresponding value";
is $fsa->notes( my => 'machine' ), $fsa,
  "We should get the machine back when setting another note";
is $fsa->notes('my'), 'machine',
  "... And passing in the key should return the new value";
is_deeply $fsa->notes, { test => 'foo', key => 'val', my => 'machine' },
  "... And passing in no arguments should return the complete notes hashref";
$fsa->{should_not_exist_after_reset} = 1;
$fsa->states('foo')->{should_not_exist_after_reset} = 1;

# Try resetting.
ok $fsa->done(1), "Set done to a true value";
is_deeply $fsa->reset, $fsa, "... Calling reset() should return the machine";
is_deeply $fsa, {}, "... it should be an empty hashref";
is $fsa->done, undef, "... and 'done' should be reset to undef";
is_deeply $fsa->states('foo'), {}, "... and the states should be empty, too";
is $fsa->notes('key'), undef, '... And now passing in a key should return undef';
is_deeply $fsa->notes, {}, "... and with no arguments, we should get an empty hash";

# Try parameters to new().
ok $fsa = $CLASS->new(
    {
        done   => 'done',
        start  => 1,
        strict => 1,
    },
    foo => {},
    bar => {},
), "Construct with a optional parameters";

is $fsa->curr_state->name, 'foo',
  "... And the engine should be started with the 'bar' state";
is $fsa->done, 'done', '... And done should be set to "done"';
is $fsa->strict, 1, "... And strict should be turned on";

# Try strict.
ok $fsa = $CLASS->new(
    { strict => 1, start => 1 },
    foo => { rules => [ bar => 1 ] },
    bar => { rules => [ foo => 1, bar => 1 ] },
), 'Constuct with strict enabled and multiple possible paths';

is $fsa->curr_state->name, 'foo', "... The engine should be started";
is $fsa->strict, 1, "... Strict should be enabled";
is $fsa->switch->name, 'bar', "... The switch to 'bar' should succeed";
eval { $fsa->try_switch };
ok $err = $@, "... Try to switch from bar should throw an exception";
like $err,
  qr/Attempt to switch from state "bar" improperly found multiple destination states: "foo", "bar"/,
  "... And the error message should be appropriate (and verbose)";

can_ok $fsa, 'at';
$fsa = $CLASS->new(
   ping => {
       do => sub { shift->machine->{count}++ },
       rules => [
           game_over => sub { shift->machine->{count} >= 20 },
           pong      => 1,
       ],
   },
   pong => {
       rules => [ ping => 1, ], # always goes back to pong
   },
   game_over => { 
       do => sub { shift->machine->{save_this} = 1 },
   },
);

$fsa->start;
eval {$fsa->at};
like $@, qr/You must supply a state name/,
  '... and it should croak() if you do not supply a state name';
eval {$fsa->at('no_such_state')};
like $@, qr/No such state "no_such_state"/,
  '... or if no state with the supplied name exists';
$fsa->switch until $fsa->at('game_over');
is $fsa->{count}, 20,
  '... and it should terminate when I want it to.';
is $fsa->{save_this}, 1,
  '... and execute the "do" action.';

# Try a valid strict.
ok $fsa = $CLASS->new(
    { strict => 1, start => 1 },
    foo => { rules => [ bar => 1 ] },
    bar => { rules => [ foo => 1, bar => 0 ] },
), "Constuct with strict enabled and valid paths";

is $fsa->curr_state->name, 'foo', "... The engine should be started";
is $fsa->strict, 1, "... Strict should be enabled";
is $fsa->switch->name, 'bar', "... The switch to 'bar' should succeed";
is $fsa->switch->name, 'foo', "... The switch back to 'foo' should succeed";

# Make sure that subclasses work.
{
    package FSA::Stately;
    @FSA::Stately::ISA = qw(FSA::State);
}

ok $fsa = $CLASS->new( { state_class => 'FSA::Stately'}, foo => {} ),
  "Construct with state_class";

ok $foo = $fsa->states('foo'), 'Get "foo" state';
isa_ok $foo, 'FSA::Stately';
isa_ok $foo, 'FSA::State';

ok $fsa = $CLASS->new( { start => 1,
                         state_class => 'FSA::Stately',
                         state_params  => { myarg => 'bar'} },
                       foo => { rules => [ bar => 1 ]},
                       bar => {},
                   ),
  "Construct with state_class";

ok $foo = $fsa->states('foo'), 'Get "foo" state';
isa_ok $foo, 'FSA::Stately';
isa_ok $foo, 'FSA::State';
isa_ok $fsa->curr_state, 'FSA::Stately';
is $fsa->curr_state->name, 'foo';
is $fsa->curr_state->{myarg}, 'bar';
ok $fsa->try_switch;
isa_ok $fsa->curr_state, 'FSA::Stately';
is $fsa->curr_state->name, 'bar';
is $fsa->curr_state->{myarg}, 'bar';

# test that messages get set even if a state dies
$fsa = $CLASS->new(
    alpha => {
        rules => [
            omega => {
                rule    => 1,
                message => 'If I heard a voice from heaven ...'
            }
        ],
    },
    omega => { do => sub { die } },
);
$fsa->start;
eval {$fsa->switch} until $fsa->at('omega');
is $fsa->states('alpha')->message, 'If I heard a voice from heaven ...',
  '... messages should be set even if the final state dies';

# Test actions passed via a hash reference rule are executed.
ok $fsa = $CLASS->new(
    alpha => {
        rules => [
            beta => {
                rule => 1,
                action => sub { shift->machine->notes(goto_beta => 1) }
            },
            omega => {
                rule    => 1,
            }
        ],
    },
    beta => {
        rules => [
            omega => {
                rule    => 1,
                action => [
                    sub { shift->machine->notes(goto_omega => 1) },
                    sub { shift->machine->notes(goto_omega2 => 2) },
                ],
            }
        ],
    },
    omega => { },
), "Construct to test for hashref rule actions";
ok $fsa->start, "Start the machine";
$fsa->switch until $fsa->at('omega');
is $fsa->notes('goto_beta'), 1, '... Beta rule action should have executed';
is $fsa->notes('goto_omega'), 1, '... Omega rule action should have executed';
is $fsa->notes('goto_omega2'), 2,
  '... Second omega rule action should have executed';

##############################################################################
# Regressions!
my $i;
ok my $rules = FSA::Rules->new(
    { strict => 1 },
    login => {
        do => sub {
            shift->notes( num => ++$i );
        },
        rules => [
            login => sub {
                shift->notes('num') <= 2;
            },
            next  => sub {
                shift->notes('num') > 2;
            }
        ],
    },
    next => { do => sub { shift->done(1) } },
), 'Create new rules with strict and dependency on do block';

ok $rules->run, '... And they should run properly.';

