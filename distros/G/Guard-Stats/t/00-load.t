#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Guard::Stats' ) || print "Bail out!\n";
}

diag( "Testing Guard::Stats $Guard::Stats::VERSION, Perl $], $^X" );
