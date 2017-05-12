#! perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use IPC::PrettyPipe;

{
    package ExtendExecutor;
    use Moo;
    extends 'IPC::PrettyPipe::Execute::IPC::Run';
}

is(
    exception {
        my $p = IPC::PrettyPipe->new( executor => 'ExtendExecutor' );
        $p->executor;
    },
    undef,
    "extend existing executor"
);

{
    package NewExecutor;
    use Moo;

    sub run { }
    with 'IPC::PrettyPipe::Executor';
}

is(
    exception {
        my $p = IPC::PrettyPipe->new( executor => 'NewExecutor' );
        $p->executor;
    },
    undef,
    "extend existing executor"
);

is(
    exception {
        my $p = IPC::PrettyPipe->new( executor => NewExecutor->new );
        $p->executor;
    },
    undef,
    "object"
);



done_testing;
