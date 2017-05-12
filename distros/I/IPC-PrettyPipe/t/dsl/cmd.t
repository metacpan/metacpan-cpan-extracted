#! perl

use strict;
use warnings;

use IPC::PrettyPipe::DSL ':all';

use Test::Deep;
use Test::More;
use Test::Exception;

throws_ok {

    ppcmd;

}
qr/missing required argument/i, 'no cmd';

subtest 'argsep, srgpfx, cmd, arg' => sub {

    my $cmd;

    lives_ok { $cmd = ppcmd argsep( '=' ), argpfx( '--' ), 'mycmd', 'foo' }
    'ppcmd';

    cmp_deeply(
        $cmd,
        methods(
            argsep => '=',
            argpfx => '--',
            cmd    => 'mycmd'
        ),

    );

    cmp_deeply(
        $cmd->args->elements->[0],
        methods(
            sep => '=',
            pfx => '--',
            name   => 'foo'
        ) );

};

# ensure that initial attributes set object, later ones don't
subtest 'attribute isolation' => sub {

    my $cmd;
    lives_ok {
        $cmd = ppcmd argsep( '=' ), argpfx( '--' ),
          'mycmd',
          'foo',
          argpfx '-',
          'l';
    }
    'ppcmd';

    cmp_deeply(
        $cmd,
        methods(
            argsep => '=',
            argpfx => '--',
            cmd    => 'mycmd'
        ),

    );

    cmp_deeply(
        $cmd->args->elements->[0],
        methods(
            sep => '=',
            pfx => '--',
            name   => 'foo'
        ) );

    cmp_deeply(
        $cmd->args->elements->[1],
        methods(
            sep => '=',
            pfx => '-',
            name   => 'l'
        ) );

};


done_testing;
