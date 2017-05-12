#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Hardware::Vhdl::Tidy' );
}

diag( "Testing Hardware::Vhdl::Tidy $Hardware::Vhdl::Tidy::VERSION, Perl $], $^X" );
