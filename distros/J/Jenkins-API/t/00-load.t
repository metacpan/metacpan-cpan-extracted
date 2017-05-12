#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Jenkins::API' ) || print "Bail out!\n";
}

diag( "Testing Jenkins::API $Jenkins::API::VERSION, Perl $], $^X" );
