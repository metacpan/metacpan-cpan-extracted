#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'Math::StochasticProcess' );
	use_ok( 'Math::StochasticProcess::Event' );
	use_ok( 'Math::StochasticProcess::RandomVariable' );
	use_ok( 'Math::StochasticProcess::Event::Tuple' );
}

diag( "Testing Math::StochasticProcess $Math::StochasticProcess::VERSION, Perl $], $^X" );
