#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Finance::ChartHist' );
}

diag( "Testing Finance::ChartHist $Finance::ChartHist::VERSION, Perl $], $^X" );
