#! perl

use v5.10;

use strict;
use warnings;

use Test2::V0;

use Image::DS9;
use Image::DS9::Constants::V1 -angular_formats, -sky_coord_systems;

use Test::Lib;
use My::Util;

my $ds9 = start_up( image => 1 );

my @coords = qw( 00:42:41.377 +41:15:24.28 );
$ds9->pan( to => @coords, wcs => SKY_COORDSYS_FK5 );

my @exp = ( qr/0?0:42:41.377/, qr/[+]41:15:24.280?/ );

my $got = $ds9->pan( wcs => SKY_COORDSYS_FK5, ANGULAR_FORMAT_SEXAGESIMAL );

like( $got, \@exp, 'pan' );

done_testing;
