#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DynGig::Schedule' ) || print "Bail out!\n";
}

diag( "Testing DynGig::Schedule $DynGig::Schedule::VERSION, Perl $], $^X" );
