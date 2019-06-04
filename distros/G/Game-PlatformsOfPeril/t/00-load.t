#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Game::PlatformsOfPeril') || print "Bail out!\n";
}

diag(
    "Testing Game::PlatformsOfPeril $Game::PlatformsOfPeril::VERSION, Perl $], $^X"
);
