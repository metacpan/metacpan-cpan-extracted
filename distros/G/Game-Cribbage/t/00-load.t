#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Game::Cribbage' ) || print "Bail out!\n";
}

diag( "Testing Game::Cribbage $Game::Cribbage::VERSION, Perl $], $^X" );
