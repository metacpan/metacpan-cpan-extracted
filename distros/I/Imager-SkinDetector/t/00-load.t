#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Imager::SkinDetector' );
}

diag( "Testing Imager::SkinDetector $Imager::SkinDetector::VERSION, Perl $], $^X" );
