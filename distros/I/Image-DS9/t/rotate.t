#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;

use Test::Lib;
use My::Util;

my $ds9 = start_up( image => 1, clear => 1 );

$ds9->rotate( abs => 45 );
is( $ds9->rotate, 45, 'rotate abs' );

$ds9->rotate( to => 45 );
is( $ds9->rotate, 45, 'rotate to' );

$ds9->rotate( rel => 45 );
is( $ds9->rotate, 90, 'rotate rel' );

$ds9->rotate( 45 );
is( $ds9->rotate, 135, 'rotate' );

done_testing;
