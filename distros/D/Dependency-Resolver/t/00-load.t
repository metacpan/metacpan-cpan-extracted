#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dependency::Resolver' ) || print "Bail out!\n";
}

diag( "Testing Dependency::Resolver $Dependency::Resolver::VERSION, Perl $], $^X" );
