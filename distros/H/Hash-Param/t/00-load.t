#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Hash::Param' );
}

diag( "Testing Hash::Param $Hash::Param::VERSION, Perl $], $^X" );
