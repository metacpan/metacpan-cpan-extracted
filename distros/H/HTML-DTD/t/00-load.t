#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::DTD' );
}

diag( "Testing HTML::DTD $HTML::DTD::VERSION, Perl $], $^X" );
