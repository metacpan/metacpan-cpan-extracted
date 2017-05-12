#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Mac::PropertyList::SAX' );
}

diag( "Testing Mac::PropertyList::SAX $Mac::PropertyList::SAX::VERSION, Perl $], $^X" );
