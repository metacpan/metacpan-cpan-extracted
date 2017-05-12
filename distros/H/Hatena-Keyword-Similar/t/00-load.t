#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Hatena::Keyword::Similar' );
}

diag( "Testing Hatena::Keyword::Similar $Hatena::Keyword::Similar::VERSION, Perl $], $^X" );
