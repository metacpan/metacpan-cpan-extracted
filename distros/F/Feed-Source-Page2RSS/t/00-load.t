#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Feed::Source::Page2RSS' );
}

diag( "Testing Feed::Source::Page2RSS $Feed::Source::Page2RSS::VERSION, Perl $], $^X" );
