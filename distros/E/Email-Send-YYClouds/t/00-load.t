#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Email::Send::YYClouds' ) || print "Bail out!\n";
}

diag( "Testing Email::Send::YYClouds $Email::Send::YYClouds::VERSION, Perl $], $^X" );
