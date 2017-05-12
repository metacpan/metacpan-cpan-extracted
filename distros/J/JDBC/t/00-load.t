#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'JDBC' );
}

diag( "Testing JDBC $JDBC::VERSION, Perl $], $^X" );

require "t/test_init.pl";
