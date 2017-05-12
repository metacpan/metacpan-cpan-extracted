#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Imager::Montage' );
}

diag( "Testing Imager::Montage $Imager::Montage::VERSION, Perl $], $^X" );
