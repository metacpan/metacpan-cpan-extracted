#! perl

use Test2::V0;
use Test::Lib;

use IPC::PrettyPipe::DSL ':all';

use My::Tests;

ok(
    lives {
        ppipe();
    },
    'ppipe'
);

subtest 'new cmd' => sub {
    my $p;
    ok( lives { $p = ppipe ['ls'] }, 'new' );
    is( $p->cmds->elements->[0]->cmd, 'ls' );
};


subtest 'new IPC::PrettyPipe::Cmd' => sub {

    my $p;

    ok( lives { $p = ppipe( IPC::PrettyPipe::Cmd->new( cmd => 'ls' ) ) },
        'new' );

    is( $p->cmds->elements->[0]->cmd, 'ls' );
};


subtest 'cmd(args) cmd' => sub {

    my $p;

    ok( lives { $p = ppipe( ['ls'], [ 'make', [ '-f', 'Makefile' ], '-k' ] ) },
        'new' );

    my $i = 0;

    is( $p->cmds->elements->[$i]->cmd, 'ls' );

    my $cmd = $p->cmds->elements->[ ++$i ];

    is( $cmd->cmd, 'make' );

    is(
        $cmd->args->elements->[0],
        object {
            call name  => '-f';
            call value => 'Makefile';
        },
    );

    is( $cmd->args->elements->[1], object { call name => '-k'; } );
};

subtest 'argsep argpfx cmd(args)' => sub {

    my $p;
    ok(
        lives {
            $p = ppipe argsep ' ', argpfx '-',
              [ 'make', [ 'f', 'Makefile' ], 'k' ]
        },
        'new'
    );

    my $cmd = $p->cmds->elements->[0];

    is(
        $cmd,
        object {
            call cmd    => 'make';
            call argsep => ' ';
            call argpfx => '-';
        } );

    is(
        $cmd->args->elements->[0],
        object {
            call name  => 'f';
            call value => 'Makefile';
        } );

    is( $cmd->args->elements->[1], object { call name => 'k' } );

};

subtest 'cmd( argpfx argsep cmds )' => sub {

    my $p;
    ok(
        lives {
            $p = ppipe(
                [ 'make', argpfx '-', argsep ' ', [ 'f', 'Makefile' ], 'k' ] )
        },
        'new'
    );

    my $cmd = $p->cmds->elements->[0];

    is( $cmd->cmd, 'make' );

    is(
        $cmd->args->elements->[0],
        object {
            call name  => 'f';
            call value => 'Makefile';
            call sep   => ' ';
            call pfx   => '-';
        } );

    is(
        $cmd->args->elements->[1],
        object {
            call name => 'k';
            call sep  => ' ';
            call pfx  => '-';
        },
    );
};

subtest 'cmd( stream )' => sub {

    my $p;
    ok( lives { $p = ppipe( [ 'make', '2>&1' ] ) }, 'new' );

    my $cmd = $p->cmds->elements->[0];

    is( $cmd->cmd, 'make' );

    is( $cmd->streams->elements->[0], object { call spec => '2>&1'; } );

};

done_testing;
