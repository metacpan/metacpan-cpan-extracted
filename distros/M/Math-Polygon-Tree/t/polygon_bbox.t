#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;

use Math::Polygon::Tree qw/ polygon_bbox /;

our @TESTS = (
    [ [[0,0]], [0,0,0,0], 'single point' ],
    [ [[0,0],[1,1],[2,1],[2,2],[0,0]], [0,0,2,2], 'simple contour' ],
);


for my $test ( @TESTS ) {
    my ($in, $expected, $name) = @$test;
    my $got = polygon_bbox($in);
    is_deeply( $got, $expected, $name );
}


done_testing();



