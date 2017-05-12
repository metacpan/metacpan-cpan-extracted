#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Geometry::Primitive' );
}

diag( "Testing Geometry::Primitive $Geometry::Primitive::VERSION, Perl $], $^X" );
