#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::Tidy::libXML' );
}

diag( "Testing HTML::Tidy::libXML $HTML::Tidy::libXML::VERSION, Perl $], $^X" );
