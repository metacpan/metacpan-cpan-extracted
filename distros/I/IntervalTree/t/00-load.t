#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'IntervalTree' ) || print "Bail out!\n";
}

diag( "Testing IntervalTree $IntervalTree::VERSION, Perl $], $^X" );
