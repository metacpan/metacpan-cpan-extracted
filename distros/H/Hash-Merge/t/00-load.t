#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Hash::Merge' ) || BAIL_OUT("Couldn't load Hash::Merge");
}

diag( "Testing Hash::Merge $Hash::Merge::VERSION, Perl $], $^X" );
