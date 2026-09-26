#!perl
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Game::Durak::Card') || print "Bail out!\n";
    use_ok('Game::Durak::Deck') || print "Bail out!\n";
}

diag("Testing Game::Durak::Card $Game::Durak::Card::VERSION, Perl $], $^X");

done_testing();
