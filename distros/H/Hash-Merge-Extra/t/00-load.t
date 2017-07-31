#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Hash::Merge::Extra' ) || print "Bail out!\n";
}

diag( "Testing Hash::Merge::Extra $Hash::Merge::Extra::VERSION, Perl $], $^X" );
