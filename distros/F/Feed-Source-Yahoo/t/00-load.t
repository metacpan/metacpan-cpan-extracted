#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Feed::Source::Yahoo' );
}

diag( "Testing Feed::Source::Yahoo $Feed::Source::Yahoo::VERSION, Perl $], $^X" );
