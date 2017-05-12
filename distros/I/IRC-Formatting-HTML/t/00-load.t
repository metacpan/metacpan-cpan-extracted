#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'IRC::Formatting::HTML' );
}

diag( "Testing IRC::Formatting::HTML $IRC::Formatting::HTML::VERSION, Perl $], $^X" );
