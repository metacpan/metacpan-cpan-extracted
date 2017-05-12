#!perl -T

use Test::More tests => 5;

BEGIN {
	use_ok( 'Getopt::Long' );
	use_ok( 'Pod::Usage' );
	use_ok( 'Class::Accessor::Fast' );
	use_ok( 'Text::Soundex' );
	use_ok( 'File::FindSimilars' );
}

diag( "Testing File::FindSimilars $File::FindSimilars::VERSION, Perl $], $^X" );
