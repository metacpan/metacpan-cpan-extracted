#!perl
use strict;
use Test::More tests => 2;
# make sure all the necesary modules exist
BEGIN {
    use_ok( 'Hash::AutoHash' );
    use_ok( 'Hash::AutoHash::AVPairsMulti' );
}
diag( "Testing Hash::AutoHash::AVPairsMulti $Hash::AutoHash::AVPairsMulti::VERSION, Perl $], $^X" );
done_testing();
