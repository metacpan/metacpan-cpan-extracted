#!/usr/bin/env perl

use strict;

use FindBin '$Bin';
use lib $Bin;

use Test::More;
use Test::Deep;
use TypeComparator;

use JSON;
use JSON::Schema::Fit;


*_n = \&TypeComparator::real_number;
*_f = \&TypeComparator::real_float_number;
*_s = \&TypeComparator::real_string;

my @tests = (
    [ { type => 'boolean' }, 0, JSON::false ],
    [ { type => 'boolean' }, {}, JSON::true ],

    [ { type => 'integer' }, 22.3, _n(22) ],
    [ { type => 'integer', multipleOf => 5 }, 22.3, _n(20) ],
    [ { type => 'integer', multipleOf => 5 }, 23.3, _n(25) ],

    [ { type => 'number', multipleOf => 0.01 }, 2/3, _f(0.67) ],

    [ { type => 'string' }, 22.3, _s(22.3) ],

    [
        { type => 'array', items => {type => 'integer'} },
        [0.2, "1", 3.3],
        [_n(0), _n(1), _n(3)]
    ],

    [
        { type => 'object', properties => {aa=>{type=>'integer'}} },
        {aa => 0.1, bb => 0.1},
        {aa => _n(0), bb=> _n(0.1)}
    ],
    [
        { type => 'object', additionalProperties=>0, properties => {aa=>{type=>'integer'}} },
        {aa => 0.1, bb => 0.1},
        {aa => _n(0)}
    ],

    [ { type => 'number', minimum => 3, maximum => 6 }, 1 => _n(3) ],
    [ { type => 'number', minimum => 3, maximum => 6 }, 5 => _n(5) ],
    [ { type => 'number', minimum => 3, maximum => 6 }, 8.22 => _n(6) ],
);

my $jsa = JSON::Schema::Fit->new(clamp_numbers => 1);
for my $test ( @tests ) {
    my ($schema, $param, $expected, $name) = @$test;
    cmp_deeply( $jsa->get_adjusted($param, $schema), $expected, $name || to_json($schema) );
}


done_testing();


