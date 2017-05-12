#! perl

use strict;
use warnings;

use IPC::PrettyPipe::DSL ':all';

use Test::More;
use Test::Exception;
use Test::Deep;

use Test::Lib;
use My::Tests;

lives_ok {

    ppipe();

}
'ppipe';

subtest 'new cmd' => sub {
    my $p;
    lives_ok { $p = ppipe ['ls'] } 'new';
    is( $p->cmds->elements->[0]->cmd, 'ls' );
};


subtest 'new IPC::PrettyPipe::Cmd' => sub {

    my $p;

    lives_ok {$p = ppipe( IPC::PrettyPipe::Cmd->new( cmd => 'ls' ) ) } 'new';

    is( $p->cmds->elements->[0]->cmd, 'ls' );
};


subtest 'cmd(args) cmd' => sub {

    my $p;

    lives_ok { $p = ppipe( ['ls'], [ 'make', [ '-f', 'Makefile' ], '-k' ] ) } 'new';

    my $i = 0;

    is( $p->cmds->elements->[$i]->cmd, 'ls' );

    my $cmd = $p->cmds->elements->[ ++$i ];

    is( $cmd->cmd, 'make' );

    cmp_deeply(
        $cmd->args->elements->[0],
        methods(
            name  => '-f',
            value => 'Makefile',
        ) );

    cmp_deeply( $cmd->args->elements->[1], methods( name => '-k', ) );
};



subtest 'argsep argpfx cmd(args)' => sub {

    my $p;

    lives_ok { $p = ppipe argsep ' ', argpfx '-', [ 'make', [ 'f', 'Makefile' ], 'k' ] } 'new';

    my $cmd = $p->cmds->elements->[0];

    cmp_deeply(
        $cmd,
        methods(
            cmd    => 'make',
            argsep => ' ',
            argpfx => '-'
        ) );

    cmp_deeply(
        $cmd->args->elements->[0],
        methods(
            name  => 'f',
            value => 'Makefile',
        ) );

    cmp_deeply( $cmd->args->elements->[1], methods( name => 'k', ) );

};

subtest 'cmd( argpfx argsep cmds )' => sub {

    my $p;

    lives_ok { $p = ppipe( [ 'make', argpfx '-', argsep ' ', [ 'f', 'Makefile' ], 'k' ] ) } 'new';

    my $cmd = $p->cmds->elements->[0];

    is( $cmd->cmd, 'make' );

    cmp_deeply(
        $cmd->args->elements->[0],
        methods(
            name   => 'f',
            value  => 'Makefile',
            sep => ' ',
            pfx => '-'
        ) );

    cmp_deeply(
        $cmd->args->elements->[1],
        methods(
            name   => 'k',
            sep => ' ',
            pfx => '-'
        ) );


};

subtest 'cmd( stream )' => sub {

    my $p;
    lives_ok { $p = ppipe( [ 'make', '2>&1' ] ) } 'new';

    my $cmd = $p->cmds->elements->[0];

    is( $cmd->cmd, 'make' );

    cmp_deeply( $cmd->streams->elements->[0], methods( spec => '2>&1', ) );

};

done_testing;
