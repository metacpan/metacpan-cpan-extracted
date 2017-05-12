#!perl -w
use strict;
use Test::More;

use FSM::Tiny;

#++$FSM::Tiny::DEBUG;

my $fsm = FSM::Tiny->new({
    on_enter      => sub {
        $_->{count} = 0;
        $_->{str}   = "foo";
    },
    on_transition => sub { $_->{str} .= "bar" },
    on_exit       => sub { $_->{str} .= "baz" }
});

$fsm->register(init => sub {}, [
    add => sub { $_->{count} < 20 },
    end => sub { $_->{count} >= 20 }
]);

$fsm->register(add => sub { ++$_->{count} }, [
    init => 1
]);

$fsm->register(end => sub { $_->{count} *= 5 });

$fsm->run;

is $fsm->context->{count}, 100, "state machine ran";

# (init -> add (-> init)) x 20 + end
is $fsm->context->{str}, "foo".("bar" x 41)."baz", "on_* event correctly fired";

done_testing;
