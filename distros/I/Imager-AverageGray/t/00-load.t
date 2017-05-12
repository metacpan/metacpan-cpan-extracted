#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Imager::AverageGray' );
}

diag( "Testing Imager::AverageGray $Image::AverageGray::VERSION, Perl $], $^X" );
