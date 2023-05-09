#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Hash::Util::Exists::Tiny' ) || print "Bail out!\n";
}

diag( "Testing Hash::Util::Exists::Tiny $Hash::Util::Exists::Tiny::VERSION, Perl $], $^X" );
