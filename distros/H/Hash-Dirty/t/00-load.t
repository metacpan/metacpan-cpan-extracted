#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Hash::Dirty' );
}

diag( "Testing Hash::Dirty $Hash::Dirty::VERSION, Perl $], $^X" );
