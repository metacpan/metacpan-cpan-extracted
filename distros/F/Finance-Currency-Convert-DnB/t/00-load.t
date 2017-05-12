#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Finance::Currency::Convert::DnB' );
}

diag( "Testing Finance::Currency::Convert::DnB $Finance::Currency::Convert::DnB::VERSION, Perl $], $^X" );
