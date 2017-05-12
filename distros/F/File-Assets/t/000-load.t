#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'File::Assets' );
}

diag( "Testing File::Assets $File::Assets::VERSION, Perl $], $^X" );
