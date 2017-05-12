use strict;
use warnings;

use Test::More;
use Image::DS9;

BEGIN { plan( tests => 4 ) ;}

require 't/common.pl';


my $ds9 = start_up();
$ds9->file( 'data/m31.fits.gz' );

test_stuff( $ds9, (
		   orient =>
		   [
		    [] => 'x',
		    [] => 'y',
		    [] => 'xy',
		    [] => 'none',
		   ],
		  ) );

