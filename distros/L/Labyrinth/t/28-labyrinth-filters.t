#!/usr/bin/perl -w
use strict;

use Data::FormValidator;
use Test::More tests => 40;
use Labyrinth::Filters;
use Labyrinth::Variables;

Labyrinth::Variables::init();   # initial standard variable values

my @example_floats = (
    [ undef,        undef,      undef,      undef,      undef   ],
    [ '',           undef,      undef,      undef,      undef   ],
    [ 'blah',       undef,      undef,      undef,      undef   ],
    [ '12.122013',  '12.12',    '12.122',   '12.12201', '12.1'  ],
    [ '0',          '0.00',     '0.000',    '0.00000',  '0.0'   ],
);

for my $ex (@example_floats) {
    is(Labyrinth::Filters::float2($ex->[0]), $ex->[1],  ".. matches '" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' float2"     );
    is(Labyrinth::Filters::float3($ex->[0]), $ex->[2],  ".. matches '" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' float3"     );
    is(Labyrinth::Filters::float5($ex->[0]), $ex->[3],  ".. matches '" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' float5"     );
    is(Labyrinth::Filters::float1($ex->[0]), $ex->[4],  ".. matches '" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' float1"     );

    is(Labyrinth::Filters::filter_float2($ex->[0]), $ex->[1],  ".. matches '" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' filter_float2"     );
    is(Labyrinth::Filters::filter_float3($ex->[0]), $ex->[2],  ".. matches '" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' filter_float3"     );
    is(Labyrinth::Filters::filter_float5($ex->[0]), $ex->[3],  ".. matches '" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' filter_float5"     );
    is(Labyrinth::Filters::filter_float1($ex->[0]), $ex->[4],  ".. matches '" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' filter_float1"     );
}
