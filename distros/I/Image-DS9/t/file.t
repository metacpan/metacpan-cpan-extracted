use strict;
use warnings;

use Test::More;
use Image::DS9;

BEGIN { plan( tests => 1 ) ;}

require 't/common.pl';

my $ds9 = start_up();
load_events( $ds9 );
ok( 'data/snooker.fits.gz[RAYTRACE]' eq $ds9->file(), 
    "file name retrieval" );
