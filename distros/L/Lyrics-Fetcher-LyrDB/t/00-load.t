#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Lyrics::Fetcher::LyrDB' );
}

diag( "Testing Lyrics::Fetcher::LyrDB $Lyrics::Fetcher::LyrDB::VERSION, Perl $], $^X" );
