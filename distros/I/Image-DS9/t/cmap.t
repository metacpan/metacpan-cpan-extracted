use strict;
use warnings;

use Test::More;
use Image::DS9;
use Cwd;

BEGIN { plan( tests => 3 ) ;}

require 't/common.pl';


my $ds9 = start_up();
load_events($ds9);

test_stuff( $ds9, (
		   cmap =>
		   [
		    [] => 'heat',
		    invert => 1,
		    value => [0.2, 0.3],
		   ],

		  ) );
$ds9->cmap( 'grey' );
$ds9->cmap( value => ( 0.5, 0.5 ) );
