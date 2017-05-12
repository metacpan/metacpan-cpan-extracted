#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Math::Spline' );
}

diag( "Testing Math::Spline $Math::Spline::VERSION, Perl $], $^X" );
