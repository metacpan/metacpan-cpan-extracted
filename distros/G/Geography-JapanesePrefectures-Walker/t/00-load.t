#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Geography::JapanesePrefectures::Walker' );
}

diag( "Testing Geography::JapanesePrefectures::Walker $Geography::JapanesePrefectures::Walker::VERSION, Perl $], $^X" );
