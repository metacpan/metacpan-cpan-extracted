#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'IRC::Bot::Log::Extended' );
}

diag( "Testing IRC::Bot::Log::Extended $IRC::Bot::Log::Extended::VERSION, Perl $], $^X" );
