#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Finance::Bank::mBank' );
}

diag( "Testing Finance::Bank::mBank $Finance::Bank::mBank::VERSION, Perl $], $^X" );
