#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'FTN::SRIF' );
}

diag( "Testing FTN::SRIF $FTN::SRIF::VERSION, Perl $], $^X" );
