#!perl
use strict;
use Test::More tests => 2;
# make sure all the necesary modules exist
BEGIN {
    use_ok( 'Hash::AutoHash' );
    use_ok( 'Hash::AutoHash::Record' );
}
diag( "Testing Hash::AutoHash::Record $Hash::AutoHash::Record::VERSION, Perl $], $^X" );
done_testing();
