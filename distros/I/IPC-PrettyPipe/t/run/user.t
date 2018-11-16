#! perl

use Test2::V0;

use IPC::PrettyPipe;

{
    package ExtendExecutor;
    use Moo;
    extends 'IPC::PrettyPipe::Execute::IPC::Run';
}

ok(
    lives {
        my $p = IPC::PrettyPipe->new( executor => 'ExtendExecutor' );
        $p->executor;
    },
    "extend existing executor"
);

{
    package NewExecutor;
    use Moo;

    sub run { }
    with 'IPC::PrettyPipe::Executor';
}

ok(
    lives {
        my $p = IPC::PrettyPipe->new( executor => 'NewExecutor' );
        $p->executor;
    },
    "extend existing executor"
);

ok(
    lives {
        my $p = IPC::PrettyPipe->new( executor => NewExecutor->new );
        $p->executor;
    },
    "object"
);

done_testing;
