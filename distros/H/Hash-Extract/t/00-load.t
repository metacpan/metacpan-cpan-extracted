#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Hash::Extract' );
}

diag( "Testing Hash::Extract $Hash::Extract::VERSION, Perl $], $^X" );
