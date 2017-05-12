#!/usr/bin/perl -w

# Load test the Email::Stuff module

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), 'lib') );
	}
}





# Does everything load?
use Test::More 'tests' => 2;
ok( $] >= 5.005, 'Your perl is new enough' );
use_ok( 'Email::Stuff' );

1;
