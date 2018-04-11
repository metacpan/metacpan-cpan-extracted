#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Game::TextPatterns') || print "Bail out!\n";
}

diag("Testing Game::TextPatterns $Game::TextPatterns::VERSION, Perl $], $^X");
