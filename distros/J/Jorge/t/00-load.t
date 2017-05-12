#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'Jorge' );
	use_ok( 'Jorge::ObjectCollection' );
	use_ok( 'Jorge::Plugin::Md5' );
}

diag( "Testing Jorge $Jorge::VERSION, Perl $], $^X" );
