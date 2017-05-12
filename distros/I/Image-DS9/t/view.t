use strict;
use warnings;

use Test::More tests => 72;
use Image::DS9;


require 't/common.pl';


my $ds9 = start_up();

test_stuff( $ds9, (
		   view =>
		   [
		    ( map { $_ => 0, $_ => 1 } 
		      qw( info panner magnifier buttons 
			  image physical ),
		    ),
		    colorbar => 'no',		# FIXME; should be 1/0? why not?
		    colorbar => 'yes',
		    wcs => 0,
		    wcs => 1,
		    ( map { $_ => 1, $_ => 0 } 
		      ( map { 'wcs' . $_ } ('a'..'z') )
		    ),
		    ( map { $_ => 0, $_ => 1 } 
                      ( [ 'graph', 'horizontal' ],
                        [ 'graph', 'vertical' ] )
		    ),
		   ]
		  ) );
