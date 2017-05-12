#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'HTML::GMap' );
	use_ok( 'HTML::GMap::Files' );
	use_ok( 'HTML::GMap::Tutorial' );
}

diag( "Testing HTML::GMap $HTML::GMap::VERSION, Perl $], $^X" );
