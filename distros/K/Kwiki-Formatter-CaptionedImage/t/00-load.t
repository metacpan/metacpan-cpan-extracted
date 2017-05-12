#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::Formatter::CaptionedImage' );
}

diag( "Testing Kwiki::Formatter::CaptionedImage $Kwiki::Formatter::CaptionedImage::VERSION, Perl $], $^X" );
