#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Log::Rolling' );
}

diag( "Testing Log::Rolling $Log::Rolling::VERSION, Perl $], $^X" );
