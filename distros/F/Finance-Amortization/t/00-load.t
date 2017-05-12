#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Finance::Amortization' );
}

diag( "Testing Finance::Amortization $Finance::Amortization::VERSION, Perl $], $^X" );
