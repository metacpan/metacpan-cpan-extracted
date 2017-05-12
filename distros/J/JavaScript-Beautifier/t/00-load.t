#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'JavaScript::Beautifier' );
}

diag( "Testing JavaScript::Beautifier $JavaScript::Beautifier::VERSION, Perl $], $^X" );
