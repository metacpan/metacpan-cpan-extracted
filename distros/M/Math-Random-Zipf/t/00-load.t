#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Math::Random::Zipf' );
}

diag( "Testing Math::Random::Zipf $Math::Random::Zipf::VERSION, Perl $], $^X" );
