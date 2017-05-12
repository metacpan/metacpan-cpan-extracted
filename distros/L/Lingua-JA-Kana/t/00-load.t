#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Lingua::JA::Kana' );
}

diag( "Testing Lingua::JA::Kana $Lingua::JA::Kana::VERSION, Perl $], $^X" );
