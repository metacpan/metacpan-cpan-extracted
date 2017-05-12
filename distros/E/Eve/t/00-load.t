#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Eve' ) || print "Bail out!\n";
}

diag( "Testing Eve $Eve::VERSION, Perl $], $^X" );
