#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::Element::Convert' );
}

diag( "Testing HTML::Element::Convert $HTML::Element::Convert::VERSION, Perl $], $^X" );
