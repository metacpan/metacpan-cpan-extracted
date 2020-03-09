#!perl
#
# test that the module at least loads, or appears to load

use 5.24.0;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Game::Xomb') || print "Bail out!\n";
}

diag("Testing Game::Xomb $Game::Xomb::VERSION, Perl $], $^X");
