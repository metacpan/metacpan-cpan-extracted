#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'JavaScript::Framework::jQuery' );
}

diag( "Testing JavaScript::Framework::jQuery $JavaScript::Framework::jQuery::VERSION, Perl $], $^X" );
