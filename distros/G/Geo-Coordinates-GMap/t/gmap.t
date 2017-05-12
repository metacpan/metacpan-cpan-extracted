#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Geo::Coordinates::GMap');
}

{
    my ($x, $y) = coord_to_gmap_tile( 86, 177, 1 );
    is( int($x), 1, 'tile x is 0' );
    is( int($y), 0, 'tile y is 1' );
}

{
    my ($x, $y) = zoom_gmap_tile( 0.4, 0.6, 0, 1 );
    is( int($x), 0, 'tile x is 0' );
    is( int($y), 1, 'tile y is 1' );
}

{
    my ($x, $y) = zoom_gmap_tile( 7.5, 12.3, 4, 1 );
    is( int($x), 0, 'tile x is 0' );
    is( int($y), 1, 'tile y is 1' );
}

{
    my ($x, $y) = gmap_tile_xy( 1.50, 5.75 );
    is( $x, 128, 'x is 128' );
    is( $y, 192, 'y is 192' );
}

{
    my ($x, $y) = gmap_tile_xy( 1.50, 5.75, 2 );
    is( $x, 256, 'x is 256' );
    is( $y, 384, 'y is 384' );
}

done_testing;
