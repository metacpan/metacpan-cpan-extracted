#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'File::Ignore' );
}

diag( "Testing File::Ignore $File::Ignore::VERSION, Perl $], $^X" );
