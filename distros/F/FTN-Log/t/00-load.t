#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'FTN::Log' );
}

diag( "Testing FTN::Log $FTN::Log::VERSION, Perl $], $^X" );
