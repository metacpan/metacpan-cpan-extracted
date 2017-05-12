#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ICS::Simple' );
}

diag( "Testing ICS::Simple $ICS::Simple::VERSION, Perl $], $^X" );
