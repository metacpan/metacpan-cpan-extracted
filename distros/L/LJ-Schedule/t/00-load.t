#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'LJ::Schedule' );
	use_ok( 'LJ::Schedule::Vcal' );
	use_ok( 'LJ::Schedule::Post' );
	use_ok( 'LJ::Schedule::Post::Simple' );
}

diag( "Testing LJ::Schedule $LJ::Schedule::VERSION, Perl $], $^X" );
