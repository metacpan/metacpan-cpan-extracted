#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'IBM::V7000' ) || print "Bail out!\n";
}

diag( "Testing IBM::V7000 $IBM::V7000::VERSION, Perl $], $^X" );
