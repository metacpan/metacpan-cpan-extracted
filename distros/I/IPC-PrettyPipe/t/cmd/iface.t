#! perl

use strict;
use warnings;

use IPC::PrettyPipe::Cmd;

use Test::Lib;
use Test::Deep;
use Test::More;
use Test::Exception;

sub new { IPC::PrettyPipe::Cmd->new( @_ ); }

use My::Tests;

test_attr(
    \&new,
    {
        desc => 'new: hash, no args',
        new      => [     { cmd => 'true' } ],
        expected => { cmd => 'true' }
    },

    {
        desc => 'new: hash, args',
        new  => [ {
                cmd  => 'true',
                args => ['false'],
                   debug => 1,
                  }
        ],
        expected => { cmd => 'true' },
        compare => [ [ 'args->elements->[0]', { name => 'false' } ], ],
    },


    {
        desc => 'new: hash, args, pfx',
        new  => [ {
                cmd    => 'true',
                args   => [ [ arg1 => 'false' ] ],
                argpfx => '--',
            }
        ],
        expected => {
            cmd    => 'true',
            argpfx => '--',
        },
        compare => [ [
                'args->elements->[0]',
                {
                    name => 'arg1',
                    pfx  => '--',
                    sep  => undef,
                }
            ],
        ],
    },


    {
        desc => 'new: hash, args, pfx, sep',

        new => [ {
                cmd    => 'true',
                args   => [ [ arg1 => 'false' ] ],
                argpfx => '--',
                argsep => '='
            }
        ],

        expected => {
            cmd    => 'true',
            argpfx => '--',
            argsep => '='
        },

        compare => [ [
                'args->elements->[0]',
                {
                    name => 'arg1',
                    pfx  => '--',
                    sep  => '=',
                }
            ],
        ],

    },



### existing IPC::PrettyPipe::Arg

    {
        desc => 'new, existing Arg object',
        new  => [
            cmd  => 'foo',
            args => IPC::PrettyPipe::Arg->new(
                name  => '-f',
                value => 'Makefile'
            )
        ],

        expected => { cmd => 'foo' },

        compare => [ [
                'args->elements->[0]',
                {
                    name  => '-f',
                    value => 'Makefile',
                } ]
        ],

    },

    {
        desc => 'new, existing Arg object in array',

        new => [ cmd => 'foo' ],

        methods => [
            ffadd => sub {
                [ -f => 'Makefile' ], IPC::PrettyPipe::Arg->new( name => '-l' );
            },
        ],

        compare => [
            [ 'args->elements->[0]', { name => '-f', } ],
            [ 'args->elements->[1]', { name => '-l', } ]
        ],
    },



    {
        desc => 'add, alternate pfx & sep',

        new => [
            cmd    => 'true',
            args   => [ [ arg1 => 'false' ] ],
            argpfx => '--',
            argsep => '='
        ],

        methods => [
            add => [ arg => [ f => 3, b => 9 ], argpfx => '-', argsep => ' ' ],
        ],

        compare => [ [
                'args->elements->[0]',
                {
                    name  => 'arg1',
                    value => 'false',
                    pfx   => '--',
                    sep   => '=',
                }
            ],

            [
                'args->elements->[1]',
                {
                    name  => 'f',
                    value => '3',
                    pfx   => '-',
                    sep   => ' ',
                }
            ],

            [
                'args->elements->[2]',
                {
                    name  => 'b',
                    value => '9',
                    pfx   => '-',
                    sep   => ' ',
                }
            ],
        ],

    },


    {
        desc => 'ffadd, stream op',

        new => [ cmd => 'true' ],

        methods => [ ffadd => [ [ f => 3, b => 9 ], '>', 'stdout' ], ],

        compare => [ [
                'args->elements->[0]',
                {
                    name  => 'f',
                    value => '3',
                }
            ],

            [
                'args->elements->[1]',
                {
                    name  => 'b',
                    value => '9',
                }
            ],

            [
                'streams->elements->[0]',
                {
                    spec   => '>',
                    file => 'stdout'
                }
            ],
        ],

    },



);


### flush out corner cases

throws_ok {
    my $cmd = new( cmd => 'ls' );

    $cmd->add( arg => sub { } );
}
qr/did not pass type constraint/, 'add: bad argument';

throws_ok {
    my $cmd = new( cmd => 'ls' );

    $cmd->add( arg => ['l'] );
}
qr/missing value/, 'add array: not enough elements';



done_testing;
