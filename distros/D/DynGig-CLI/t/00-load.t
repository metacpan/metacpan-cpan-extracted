#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DynGig::CLI' ) || print "Bail out!\n";
}

diag( "Testing DynGig::CLI $DynGig::CLI::VERSION, Perl $], $^X" );
