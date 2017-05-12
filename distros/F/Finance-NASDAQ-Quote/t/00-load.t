#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Finance::NASDAQ::Quote' );
}

diag( "Testing Finance::NASDAQ::Quote $Finance::NASDAQ::Quote::VERSION, Perl $], $^X" );
