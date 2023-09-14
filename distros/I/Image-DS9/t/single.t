#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;

use Test::Lib;
use My::Util;

my $ds9 = start_up( clear => 1, events => 1, image => 1 );

$ds9->single();
is( $ds9->single( 'state' ), !!1, "single" );
is( $ds9->blink( 'state' ),  !!0, "single; blink off" );
is( $ds9->tile( 'state' ),   !!0, "single; tile off" );

done_testing
