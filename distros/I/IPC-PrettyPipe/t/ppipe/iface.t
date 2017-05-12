#! perl

use strict;
use warnings;

use IPC::PrettyPipe;
use IPC::PrettyPipe::Cmd;

use Test::More;
use Test::Exception;

use Test::Lib;
use My::Tests;

sub new { IPC::PrettyPipe->new( @_ ); }

lives_ok {

    IPC::PrettyPipe->new();
}
'new';

test_attr(
    \&new,

    {
        desc => 'new cmd',
        new => [ cmds => 'ls' ],
        compare => [ [ 'cmds->elements->[0]', { cmd => 'ls' } ], ],
    },


    {
        desc => 'new IPC::PrettyPipe::Cmd',
        new => sub { IPC::PrettyPipe::Cmd->new( 'ls' ) },
        compare => [ [ 'cmds->elements->[0]', { cmd => 'ls' } ], ],
    },

    {
        desc => 'add 2 cmds +args',

        new => [],
        methods =>
          [ ffadd => [ ['ls'], [ 'make', [ '-f', 'Makefile' ], '-k' ] ], ],

        compare => [

            [ 'cmds->elements->[0]', { cmd => 'ls' } ],

            [ 'cmds->elements->[1]', { cmd => 'make' } ],

            [
                'cmds->elements->[1]->args->elements->[0]',
                {
                    name  => '-f',
                    value => 'Makefile',
                },
            ],

            [ 'cmds->elements->[1]->args->elements->[1]', { name => '-k', }, ],
        ],
    },


    {
        desc => 'add cmd+args',

        new => [],

        methods => [
            ffadd => [ [ 'make', [ '-f', 'Makefile' ], '-k' ] ],
            ffadd => [ [ 'ls', '-l' ] ],
        ],

        compare => [
            [ 'cmds->elements->[0]', { cmd => 'make' } ],

            [
                'cmds->elements->[0]->args->elements->[0]',
                {
                    name  => '-f',
                    value => 'Makefile',
                },
            ],

            [ 'cmds->elements->[0]->args->elements->[1]', { name => '-k', }, ],

            [ 'cmds->elements->[1]', { cmd => 'ls' } ],

            [ 'cmds->elements->[1]->args->elements->[0]', { name => '-l', }, ],

        ],

    },

    {
        desc => 'add Cmd object',

        new => [],

        methods => [
            add => sub {
                cmd => IPC::PrettyPipe::Cmd->new(
                    cmd  => 'make',
                    args => [ [ '-f', 'Makefile' ], '-k' ] );
            },
            add => [ cmd => 'ls', args => ['-l'] ],
        ],

        compare => [
            [ 'cmds->elements->[0]', { cmd => 'make' } ],

            [
                'cmds->elements->[0]->args->elements->[0]',
                {
                    name  => '-f',
                    value => 'Makefile',
                },
            ],

            [ 'cmds->elements->[0]->args->elements->[1]', { name => '-k', }, ],

            [ 'cmds->elements->[1]', { cmd => 'ls' } ],

            [ 'cmds->elements->[1]->args->elements->[0]', { name => '-l', }, ],

        ],

    },

    {
        desc    => 'ffadd stream',
        new     => [],
        methods => [ ffadd => [ ['ls'], '>', 'stdout' ] ],
        compare => [
            [ 'cmds->elements->[0]', { cmd => 'ls' } ],
            [
                'streams->elements->[0]',
                {
                    Op   => '>',
                    file => 'stdout',
                }
            ],
        ],
    },

    {
        desc    => 'stream',
        new     => [ cmds => 'ls' ],
        methods => [ stream => [ '>', 'stdout' ] ],
        compare => [
            [ 'cmds->elements->[0]', { cmd => 'ls' } ],
            [
                'streams->elements->[0]',
                {
                    Op   => '>',
                    file => 'stdout',
                }
            ],
        ],
    },

);

done_testing;
