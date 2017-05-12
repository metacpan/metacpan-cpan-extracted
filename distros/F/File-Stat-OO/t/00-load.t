#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'File::Stat::OO' );
}

diag( "Testing File::Stat::OO $File::Stat::OO::VERSION, Perl $], $^X" );
