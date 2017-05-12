#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'File::VirusScan' );
}

diag( "Testing File::VirusScan $File::VirusScan::VERSION, Perl $], $^X" );
