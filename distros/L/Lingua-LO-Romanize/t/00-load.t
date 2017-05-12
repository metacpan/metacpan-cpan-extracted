#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'Lingua::LO::Romanize' );
	use_ok( 'Lingua::LO::Romanize::Types' );
	use_ok( 'Lingua::LO::Romanize::Word' );
	use_ok( 'Lingua::LO::Romanize::Syllable' );
}

diag( "Testing Lingua::LO::Romanize $Lingua::LO::Romanize::VERSION, Perl $], $^X" );
