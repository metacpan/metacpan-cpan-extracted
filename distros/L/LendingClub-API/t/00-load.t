#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'LendingClub::API' ) || print "Bail out!\n";
}

diag( "Testing LendingClub::API $LendingClub::API::VERSION, Perl $], $^X" );
