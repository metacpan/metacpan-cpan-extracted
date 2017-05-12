#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Image::Mate' );
}

diag( "Testing Image::Mate $Image::Mate::VERSION, Perl $], $^X" );
