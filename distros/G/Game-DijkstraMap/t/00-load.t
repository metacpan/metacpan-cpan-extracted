#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Game::DijkstraMap') || print "Bail out!\n";
}

diag("Testing Game::DijkstraMap $Game::DijkstraMap::VERSION, Perl $], $^X");
