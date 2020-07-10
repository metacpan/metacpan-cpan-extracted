#!perl

use strict;
use warnings;

use Test2::V0;

use Test::Lib;
use My::Test::Render;

my %expected = (
    T1 => {
            elements => [ {
                    cmd => 'cmd1'
                },
            ]
        },
    T2 => {
            elements => [ {
                    cmd  => 'cmd1',
                    args => ['a']
                },
            ],
        },
    T3 => {
            elements => [ {
                    cmd  => 'cmd1',
                    args => [ 'a', '3' ]
                },
            ],
        },

    T4 => {
            elements => [ {
                    cmd  => 'cmd1',
                    args => [ 'a', '' ]
                },
            ],
        },
    T5 => {
            elements => [ {
                    cmd  => 'cmd1',
                    args => ['a=3']
                },
            ],
        },
    T6 => {
            elements => [ {
                    cmd  => 'cmd1',
                    args => [ '-a', '3' ]
                },
            ],
        },
    T7 => {
            elements => [ {
                    cmd  => 'cmd1',
                    args => [ '--a=3', '--b=is after a' ]
                },
            ],
        },
    T8 => {
            elements => [ {
                    cmd  => 'cmd1',
                    args => [ 'a', 'b' ]
                },
            ],
        },
    T9 => {
            elements => [ {
                    cmd     => 'cmd1',
                    streams => [ [ '>', 'file' ] ],
                },
            ],
        },
    T10 => {
            elements => [ {
                    cmd     => 'cmd1',
                    args    => ['-a'],
                    streams => [ [ '>', 'file' ] ],
                },
            ],
        },
    T11 => {
            elements => [ {
                    cmd     => 'cmd1',
                    streams => [ [ '>', 'stdout' ], [ '2>', 'stderr' ], ],
                },
            ],
        },
    T12 => {
            elements => [ {
                    cmd     => 'cmd1',
                    args    => ['-a'],
                    streams => [ [ '>', 'stdout' ], [ '2>', 'stderr' ], ],
                },
            ],
        },
    T13 => {
            elements => [ { cmd => 'cmd1', }, { cmd => 'cmd2' }, ],
        },
    T14 => {
            elements => [ {
                    cmd  => 'cmd1',
                    args => ['-a'],
                },
                {
                    cmd  => 'cmd2',
                    args => ['-b'],
                },
            ],
        },
    T15 => {
            elements => [ {
                    cmd     => 'cmd1',
                    args    => ['-a'],
                    streams => [ [ '2>', 'stderr' ] ],
                },
                {
                    cmd     => 'cmd2',
                    args    => ['-b'],
                    streams => [ [ '>', 'stdout' ] ],
                },
            ],
        },
    T16 => {
            elements => [ {
                    cmd     => 'cmd1',
                    args    => ['-a'],
                    streams => [ [ '2>', 'stderr' ], [ '3>', 'out put' ], ],
                },
                {
                    cmd     => 'cmd2',
                    args    => ['-b'],
                    streams => [ [ '>', '0' ], [ '2>', 'std err' ], ],
                },
            ],
        },
    T17 => {
            elements    => [ { cmd => 'cmd1', }, { cmd => 'cmd2', }, ],
            streams => [ [ '>', 'stdout' ] ],
        },
    T18 => {
            elements => [ {
                    cmd     => 'cmd 1',
                    args    => ['-a'],
                    streams => [ [ '2>', 'std err' ], ],
                },
                {
                    cmd     => 'cmd 2',
                    args    => ['-b'],
                    streams => [ [ '>', 'std out' ], ],
                },
            ],
            streams => [ [ '>', '0' ], ],
        },
    T19 => {
            elements => [ {
                    cmd     => 'cmd 1',
                    args    => ['-a'],
                    streams => [ [ '2>', 'std err' ], ],
                },
                {
                    elements => [ {
                            cmd     => 'cmd 2',
                            args    => ['-b'],
                            streams => [ [ '>', 'std out' ], ],
                        },
                    ],
                },
            ],
            streams => [ [ '>', '0' ] ],
        },
    T20 => {
            elements => [ {
                    cmd     => 'cmd 1',
                    args    => ['-a'],
                    streams => [ [ '2>', 'std err' ], ],
                },
                {
                    cmd     => 'cmd 2',
                    args    => ['-b'],
                    streams => [ [ '>', 'std out' ], ],
                },
            ],
            streams => [ [ '>', '0' ] ],
        },
    T21 => {
            elements => [ {
                    cmd     => 'cmd 1',
                    args    => ['-a'],
                    streams => [ [ '2>', 'std err' ], ],
                },
                {
                    elements => [ {
                            cmd     => 'cmd 2',
                            args    => ['-b'],
                            streams => [ [ '>', 'std out' ], ],
                        },
                    ],
                    streams => [ [ '>', '0' ] ],
                }
            ],
        },
);

test_renderer( 'Struct', \%expected );

done_testing;
