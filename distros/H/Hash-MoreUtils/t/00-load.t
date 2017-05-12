#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Hash::MoreUtils' );
}

diag( "Testing Hash::MoreUtils $Hash::MoreUtils::VERSION, Perl $], $^X" );
