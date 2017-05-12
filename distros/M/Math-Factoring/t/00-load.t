#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Math::Factoring' );
}

diag( "Testing Math::Factoring $Math::Factoring::VERSION, Perl $], $^X" );
