#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Finance::QuoteDB' );
}

diag( "Testing Finance::QuoteDB $Finance::QuoteDB::VERSION, Perl $], $^X" );
