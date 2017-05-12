#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MW::ssNA' ) || print "Bail out!\n";
}

diag( "Testing MW::ssNA $MW::ssNA::VERSION, Perl $], $^X" );
