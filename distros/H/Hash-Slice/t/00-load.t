#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Hash::Slice' );
}

diag( "Testing Hash::Slice $Hash::Slice::VERSION, Perl $], $^X" );
