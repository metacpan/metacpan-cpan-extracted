#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;

use Test::Lib;
use My::Util;

diag( "tests are incomplete" );

my $ds9 = start_up( image => 1, clear => 1 );

$ds9->frame( 3 );
is( $ds9->frame(), 3, 'frame create' );

$ds9->frame( 4 );
is( $ds9->frame(), 4, 'frame create' );

is( [ 1, 3, 4 ], scalar $ds9->frame( 'all' ), 'frame all' );

$ds9->frame( 'first' );
is( $ds9->frame(), 1, 'frame first' );

$ds9->frame( 'last' );
is( $ds9->frame(), 4, 'frame last' );

$ds9->frame( 'prev' );
is( $ds9->frame(), 3, 'frame prev' );

$ds9->frame( 'next' );
is( $ds9->frame(), 4, 'frame next' );

# avoid strange timing crash on some X servers
sleep( 1 );

$ds9->frame( 'delete' );
is( $ds9->frame(), 3, 'frame delete' );

$ds9->frame( 'new' );
is( $ds9->frame(), 5, 'frame new' );


$ds9->frame( 1 );
ok( $ds9->frame( has => 'wcs' ), 'has wcs' );

done_testing;
