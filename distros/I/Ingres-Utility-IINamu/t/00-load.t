#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Ingres::Utility::IINamu' );
}

diag( "Testing Ingres::Utility::IINamu $Ingres::Utility::IINamu::VERSION, Perl $], $^X" );
