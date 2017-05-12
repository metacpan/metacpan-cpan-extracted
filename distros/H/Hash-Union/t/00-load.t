#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Hash::Union' );
}

diag( "Testing Hash::Union $Hash::Union::VERSION, Perl $], $^X" );
