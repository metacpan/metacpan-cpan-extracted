#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Email::Postman' ) || print "Bail out!\n";
}

diag( "Testing Email::Postman $Email::Postman::VERSION, Perl $], $^X" );
