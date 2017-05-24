#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Devel::Jemallctl' ) || print "Bail out!\n";
}

diag( "Testing Devel::Jemallctl $Devel::Jemallctl::VERSION, Perl $], $^X" );
