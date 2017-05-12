#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Math::Goedel' );
}

diag( "Testing Math::Goedel $Math::Goedel::VERSION, Perl $], $^X" );
