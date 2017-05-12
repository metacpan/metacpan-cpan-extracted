#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'File::Maintenance' );
}

diag( "Testing File::Maintenance $File::Maintenance::VERSION, Perl $], $^X" );
