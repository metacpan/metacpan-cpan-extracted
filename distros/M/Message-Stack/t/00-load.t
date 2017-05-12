#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Message::Stack' );
}

diag( "Testing Message::Stack $Message::Stack::VERSION, Perl $], $^X" );
