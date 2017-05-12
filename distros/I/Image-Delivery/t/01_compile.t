#!/usr/bin/perl -w

# Load test the Image::Delivery module

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'lib') );
	}
}





# Does everything load?
use Test::More 'tests' => 6;
ok( $] >= 5.005, 'Your perl is new enough'    );
use_ok( 'Image::Delivery'                     );
use_ok( 'Image::Delivery::Provider'           );
use_ok( 'Image::Delivery::Provider::Scalar'   );
use_ok( 'Image::Delivery::Provider::IOHandle' );
use_ok( 'Image::Delivery::Provider::File'     );

1;
