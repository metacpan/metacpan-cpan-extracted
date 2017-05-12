#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'File::Extractor' );
}

diag( "Testing File::Extractor $File::Extractor::VERSION, Perl $], $^X" );
