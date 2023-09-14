#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;

use Test::Lib;
use My::Util;

my $ds9 = start_up( image => 1, clear => 1 );



$ds9->zoom( to => 'fit' );
my $zval = $ds9->zoom;

$ds9->zoom( to => 1 );
is( $ds9->zoom, 1, 'zoom to' );

$ds9->zoom( abs => 2 );
is( $ds9->zoom, 2, 'zoom abs' );

$ds9->zoom( rel => 2 );
is( $ds9->zoom, 4, 'zoom rel' );

$ds9->zoom( 0.5 );
is( $ds9->zoom, 2, 'zoom' );

$ds9->zoom( 0 );
is( $ds9->zoom, $zval, '0' );

$ds9->zoom( 'out' );
isnt( $ds9->zoom, $zval, 'in' );

$ds9->zoom( 'in' );
is( $ds9->zoom, $zval, 'out' );



done_testing;
