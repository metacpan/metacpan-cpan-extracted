#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Mac::PropertyList::XS' );
}

diag( "Testing Mac::PropertyList::XS $Mac::PropertyList::XS::VERSION, Perl $], $^X" );
