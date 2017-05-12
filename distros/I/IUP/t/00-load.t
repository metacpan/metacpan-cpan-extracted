#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'IUP' ) || print "Bail out!";
}

diag( "Testing IUP $IUP::VERSION, Perl $], $^X" );
