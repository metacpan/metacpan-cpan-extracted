#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Imager::Simple' );
}

diag( "Testing Imager::Simple $Imager::Simple::VERSION, Perl $], $^X" );
