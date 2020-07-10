#! perl

use Test2::V0;

use IPC::PrettyPipe::DSL ':all';


# ensure that initial attributes set object, later ones don't
subtest 'attribute isolation' => sub {

    my $p;

    try_ok {
        $p = ppipe argpfx '--', [ 'mycmd', 'foo' ], argpfx '-',
          [ 'mycmd', 'l' ]
    }
    'ppipe';

    is(
        $p,
        object {
            call argpfx => '--';
        },
    );

    is(
        $p->cmds->elements->[0]->args->elements->[0],
        object {
            call pfx  => '--';
            call name => 'foo';
        },
    );

    is(
        $p->cmds->elements->[1]->args->elements->[0],
        object {
            call pfx  => '-';
            call name => 'l';
        },
    );

};

subtest 'attribute isolation 2' => sub {

    my $p;
    try_ok {
        $p = ppipe argpfx( '-' ), [ 'cmd1', 'arg1' ],
          argpfx( '--' ), [ 'cmd2', 'arg2' ],
          [ 'cmd3', argpfx( '-' ), 'arg1', argpfx( '--' ), 'arg2' ]
    }
    'ppipe';

    is( $p->argpfx, '-' );

    is( $p->cmds->elements->[0]->argpfx, '-' );

    is( $p->cmds->elements->[1]->argpfx, '--' );
    is( $p->cmds->elements->[2]->argpfx, '--' );

    is( $p->cmds->elements->[2]->args->elements->[0]->pfx, '-' );
    is( $p->cmds->elements->[2]->args->elements->[1]->pfx, '--' );
};


subtest 'nested pipes' => sub {

    subtest 'bare ppipe' => sub {
        my $p;
        try_ok {
            $p = ppipe argpfx( '-' ), [ 'cmd1', 'arg1' ],
              argpfx( '--' ), [ ppipe [ 'cmd2', 'arg2' ] ], '>', 'stdout';
        }
        'ppipe';


        is( $p->argpfx, '-' );

        {
            my $stream = $p->streams->elements->[0];
            is( $stream->spec, '>' );
            is( $stream->file, 'stdout' );
        }

        {
            my $cmd = $p->cmds->elements->[0];
            isa_ok( $cmd, 'IPC::PrettyPipe::Cmd' );
            is( $cmd->argpfx, '-' );
        }


        {
            my $cmd = $p->cmds->elements->[1];
            isa_ok( $cmd, 'IPC::PrettyPipe::Cmd' );
            is( $cmd->argpfx, undef );
        }

    };

    subtest '[ ppipe ]' => sub {
        my $p;
        try_ok {
            $p = ppipe argpfx( '-' ), [ 'cmd1', 'arg1' ],
              argpfx( '--' ), [ ppipe [ 'cmd2', 'arg2' ], '>', 'stdout' ];
        }
        'ppipe';

        is( $p->argpfx, '-' );

        {
            my $cmd = $p->cmds->elements->[0];
            isa_ok( $cmd, 'IPC::PrettyPipe::Cmd' );
            is( $cmd->argpfx, '-' );
        }

        {
            my $pipe = $p->cmds->elements->[1];
            isa_ok( $pipe, 'IPC::PrettyPipe' );
            is( $pipe->argpfx,                      undef );
            is( $pipe->cmds->elements->[0]->argpfx, undef );

            my $stream = $pipe->streams->elements->[0];
            is( $stream->spec, '>' );
            is( $stream->file, 'stdout' );
        }
    };

};



done_testing;
