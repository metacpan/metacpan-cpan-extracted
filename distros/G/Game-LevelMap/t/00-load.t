#!perl
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Game::LevelMap') || print "Bail out!\n";
}

diag("Testing Game::LevelMap $Game::LevelMap::VERSION, Perl $], $^X");
