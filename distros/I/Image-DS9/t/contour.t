use strict;
use warnings;

use Test::More;
use Image::DS9;

BEGIN { plan( tests => 1 ) ;}

require 't/common.pl';


my $ds9 = start_up();
$ds9->file( 'data/m31.fits.gz' );

test_stuff( $ds9, (
		   contour =>
		   [
		    [] => 1,
		   ],
		  ) );

