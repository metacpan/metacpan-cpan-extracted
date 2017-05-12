#!perl
use strict;
use Test::More tests => 2;
# make sure all the necesary modules exist
BEGIN {
    use_ok( 'Hash::AutoHash' );
    use_ok( 'Hash::AutoHash::AVPairsSingle' );
}
diag( "Testing Hash::AutoHash::AVPairsSingle $Hash::AutoHash::AVPairsSingle::VERSION, Perl $], $^X" );
done_testing();
