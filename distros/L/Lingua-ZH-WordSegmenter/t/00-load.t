#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Lingua::ZH::WordSegmenter' );
}

diag( "Testing Lingua::ZH::WordSegmenter $Lingua::ZH::WordSegmenter::VERSION, Perl $], $^X" );
