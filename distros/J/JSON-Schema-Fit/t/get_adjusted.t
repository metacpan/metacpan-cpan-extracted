#!/usr/bin/env perl

use strict;

use Test::More;
use Test::Deep;

use JSON;
use JSON::Schema::Fit;


my @tests = (
    [ { type => 'boolean' }, 0, JSON::false ],
    [ { type => 'boolean' }, {}, JSON::true ],
    [ { type => 'integer', multipleOf => 5 }, 22.3, 20 ],
    [ { type => 'number', multipleOf => 0.01 }, 2/3, 0.67 ],
    [
        { type => 'array', items => {type => 'integer'} },
        [0.2, "1", 3.3],
        [0,1,3]
    ],
    [
        { type => 'object', properties => {aa=>{type=>'integer'}} },
        {aa=>0.1, bb=>0.1},
        {aa=>0, bb=>0.1}
    ],
    [
        { type => 'object', additionalProperties=>0, properties => {aa=>{type=>'integer'}} },
        {aa=>0.1, bb=>0.1},
        {aa=>0}
    ],
);

my $jsa = JSON::Schema::Fit->new();
for my $test ( @tests ) {
    my ($schema, $param, $expected, $name) = @$test;
    cmp_deeply( $jsa->get_adjusted($param, $schema), $expected, $name || to_json($schema) );
}


done_testing();


