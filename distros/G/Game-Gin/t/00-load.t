#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Game::Gin' ) || print "Bail out!\n";
}

diag( "Testing Game::Gin $Game::Gin::VERSION, Perl $], $^X" );
