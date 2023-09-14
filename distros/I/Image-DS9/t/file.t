#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;

use Test::Lib;
use My::Util;

plan( 'skip_all' => "file is mapped to fits for backwards compatibility" );

my $ds9 = start_up();
load_events( $ds9 );
is( SNOOKER_FITS . '[RAYTRACE]', $ds9->file(), 'file name retrieval' );

done_testing
