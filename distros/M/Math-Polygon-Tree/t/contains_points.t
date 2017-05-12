#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;

use Math::Polygon::Tree;


our @TESTS = (
    [
        triangle => [[0,0],[4,0],[0,4]],
        [ [[1,1],[2,1]], 1, 'all inside' ],
        [ [[5,5],[6,6]], 0, 'all outside' ],
        [ [[2,2],[3,0]], 1, 'all on border' ],
        [ [[[5,5],[6,6]]], 0, 'all outside in arrayref' ],
        [ [[1,1],[6,6]], undef, 'inside and outside' ],
        [ [[1,0],[1,1]], 1, 'inside and border' ],
    ],
);


for my $item ( @TESTS ) {
    my ($case, $contour, @tests) = @$item;
    my $t = Math::Polygon::Tree->new($contour);

    for my $test ( @tests ) { 
        my ($in, $expected, $name) = @$test;
        my $got = $t->contains_points($in);
        is( $got, $expected, "$case: $name" );
    }
}


done_testing();

