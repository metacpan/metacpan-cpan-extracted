#! perl

use Test2::V0;

use IPC::PrettyPipe::DSL ':all';

ok( dies { ppcmd }, qr/missing required argument/i, 'no cmd' );

subtest 'argsep, srgpfx, cmd, arg' => sub {
    my $cmd;

    ok( lives { $cmd = ppcmd argsep( '=' ), argpfx( '--' ), 'mycmd', 'foo' },
        'ppcmd' );

    is(
        $cmd,
        object {
            call argsep => '=';
            call argpfx => '--';
            call cmd    => 'mycmd';
        },
    );

    is(
        $cmd->args->elements->[0],
        object {
            call sep  => '=';
            call pfx  => '--';
            call name => 'foo';
        },
    );
};

# ensure that initial attributes set object, later ones don't
subtest 'attribute isolation' => sub {

    my $cmd;
    ok(
        lives {
            $cmd = ppcmd argsep( '=' ), argpfx( '--' ),
              'mycmd',
              'foo',
              argpfx '-',
              'l';
        },
        'ppcmd'
    );

    is(
        $cmd,
        object {
            call argsep => '=';
            call argpfx => '--';
            call cmd    => 'mycmd';
        },
    );

    is(
        $cmd->args->elements->[0],
        object {
            call sep  => '=';
            call pfx  => '--';
            call name => 'foo';
        },
    );

    is(
        $cmd->args->elements->[1],
        object {
            call sep  => '=';
            call pfx  => '-';
            call name => 'l';
        },
    );

};

done_testing;
