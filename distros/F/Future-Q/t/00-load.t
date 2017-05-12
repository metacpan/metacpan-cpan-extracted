#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Future::Q' ) || print "Bail out!\n";
}

diag( "Testing Future::Q $Future::Q::VERSION, Perl $], $^X" );
