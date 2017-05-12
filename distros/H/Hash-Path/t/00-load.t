#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Hash::Path' );
}

diag( "Testing Hash::Path $Hash::Path::VERSION, Perl $], $^X" );
