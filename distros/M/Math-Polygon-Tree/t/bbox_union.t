#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;

use Math::Polygon::Tree;

our @TESTS = (
    [ [[0,0]], [0,0,0,0], 'single point' ],
    [ [[0,1],[1,0]], [0,0,1,1], 'two points' ],
    [ [[0,0,1,1]], [0,0,1,1], 'single bbox' ],
    [ [[0,0,1,1],[2,3]], [0,0,2,3], 'point with bbox' ],
    [ [[0,0,2,2],[1,0,2,3]], [0,0,2,3], 'two bboxes' ],
);


for my $test ( @TESTS ) {
    my ($in, $expected, $name) = @$test;
    my $got = Math::Polygon::Tree::bbox_union(@$in);
    is_deeply( $got, $expected, $name );
}


done_testing();



