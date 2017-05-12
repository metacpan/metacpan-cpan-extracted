#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'File::CreationTime' );
}

diag( "Testing File::CreationTime $File::CreationTime::VERSION, Perl $], $^X" );
