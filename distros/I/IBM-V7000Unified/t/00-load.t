#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'IBM::V7000Unified' ) || print "Bail out!\n";
}

diag( "Testing IBM::V7000Unified $IBM::V7000Unified::VERSION, Perl $], $^X" );
