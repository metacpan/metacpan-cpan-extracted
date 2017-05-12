#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Hook::Output::Tiny' ) || print "Bail out!\n";
}

diag( "Testing Hook::Output::Tiny $Hook::Output::Tiny::VERSION, Perl $], $^X" );
