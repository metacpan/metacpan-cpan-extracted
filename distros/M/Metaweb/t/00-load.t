#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Metaweb' );
}

diag( "Testing Metaweb $Metaweb::VERSION, Perl $], $^X" );
