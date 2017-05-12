#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTTP::Session::Store::DBI' );
}

diag( "Testing HTTP::Session::Store::DBI $HTTP::Session::Store::DBI::VERSION, Perl $], $^X" );
