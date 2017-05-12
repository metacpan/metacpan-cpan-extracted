#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Hash::ConsistentHash' ) || print "Bail out!\n";
}

diag( "Testing Hash::ConsistentHash $Hash::ConsistentHash::VERSION, Perl $], $^X" );
