#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Hardware::Vhdl::Lexer' );
}

diag( "Testing Hardware::Vhdl::Lexer $Hardware::Vhdl::Lexer::VERSION, Perl $], $^X" );
