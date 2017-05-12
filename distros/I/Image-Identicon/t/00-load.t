#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Image::Identicon' );
}

diag( "Testing Image::Identicon $Image::Identicon::VERSION, Perl $], $^X" );
