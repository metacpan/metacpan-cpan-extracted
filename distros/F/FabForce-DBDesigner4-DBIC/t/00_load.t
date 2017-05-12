#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'FabForce::DBDesigner4::DBIC' );
}

diag( "Testing FabForce::DBDesigner4::DBIC $FabForce::DBDesigner4::DBIC::VERSION, Perl $], $^X" );
