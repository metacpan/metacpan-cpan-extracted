#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'List::Conditional' );
}

diag( "Testing List::Conditional $List::Conditional::VERSION, Perl $], $^X" );
