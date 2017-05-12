use strict;
use warnings;

use Test::More tests => 15;
use Image::DS9;

require 't/common.pl';

my $ds9 = start_up();
$ds9->file( 'data/m31.fits.gz' );

test_stuff( $ds9, (
		   scale =>
		   [
		    [] => 'linear',
		    [] => 'log',
		    [] => 'squared',
		    [] => 'sqrt',
		    [] => 'histequ',
		    [] => 'linear',
		    
		    datasec => 1,
		    datasec => 0,
		    
		    limits => [1, 100],
		    mode => 'minmax',
		    mode => 33,
		    mode => 'zscale',
		    mode => 'zmax',
		    
		    scope => 'local',
		    scope => 'global',
		   ],
		  ) );

