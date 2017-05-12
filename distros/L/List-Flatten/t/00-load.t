#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'List::Flatten' );
}

diag( "Testing List::Flatten $List::Flatten::VERSION, Perl $], $^X" );
