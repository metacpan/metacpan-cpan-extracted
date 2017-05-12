#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DocLife' ) || print "Bail out!\n";
}

diag( "Testing DocLife $DocLife::VERSION, Perl $], $^X" );
