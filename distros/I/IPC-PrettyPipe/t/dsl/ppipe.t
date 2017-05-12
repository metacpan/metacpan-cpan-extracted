#! perl

use strict;
use warnings;

use IPC::PrettyPipe::DSL ':all';

use Test::Deep;
use Test::More;
use Test::Exception;

# ensure that initial attributes set object, later ones don't
subtest 'attribute isolation' => sub {

    my $p;

    lives_and { $p = ppipe argpfx '--', [ 'mycmd', 'foo' ], argpfx '-', [ 'mycmd', 'l' ] } 'ppipe';

    cmp_deeply(
        $p,
        methods(
            argpfx => '--',
        ),

    );

    cmp_deeply(
        $p->cmds->elements->[0]->args->elements->[0],
        methods(
            pfx => '--',
            name   => 'foo'
        ) );

    cmp_deeply(
        $p->cmds->elements->[1]->args->elements->[0],
        methods(
            pfx => '-',
            name   => 'l'
        ) );


};

subtest 'attribute isolation 2' => sub {

    my $p;
    lives_and { $p = ppipe
		  argpfx( '-' ), [ 'cmd1', 'arg1' ],
		  argpfx( '--' ), [ 'cmd2', 'arg2' ],
		    [ 'cmd3', argpfx( '-' ), 'arg1', argpfx( '--' ), 'arg2' ]
		} 'ppipe';

    is( $p->argpfx, '-' );

    is( $p->cmds->elements->[0]->argpfx, '-' );

    is( $p->cmds->elements->[1]->argpfx, '--' );
    is( $p->cmds->elements->[2]->argpfx, '--' );

    is( $p->cmds->elements->[2]->args->elements->[0]->pfx, '-' );
    is( $p->cmds->elements->[2]->args->elements->[1]->pfx, '--' );
};


done_testing;
