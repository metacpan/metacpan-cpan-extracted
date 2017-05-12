#!/usr/bin/perl -w

# Compile-testing for Lingua::EN::VarCon

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib'),
			);
	}
}

use Test::More tests => 2;

ok( $] > 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'Lingua::EN::VarCon' );
