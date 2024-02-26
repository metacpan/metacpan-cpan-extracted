#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'File::LoadLines' );
}

note( "Testing File::LoadLines $File::LoadLines::VERSION, Perl $], $^X" );
