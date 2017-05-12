#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Locale::Maketext::Lexicon::DBI' );
}

diag( "Testing Locale::Maketext::Lexicon::DBI $Locale::Maketext::Lexicon::DBI::VERSION, Perl $], $^X" );
