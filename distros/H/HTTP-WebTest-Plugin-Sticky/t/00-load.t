#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTTP::WebTest::Plugin::Sticky' );
}

diag( "Testing HTTP::WebTest::Plugin::Sticky $HTTP::WebTest::Plugin::Sticky::VERSION, Perl $], $^X" );
