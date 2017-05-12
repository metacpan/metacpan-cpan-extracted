#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Hash::Transform' );
}

diag( "Testing Hash::Transform $Hash::Transform::VERSION, Perl $], $^X" );
