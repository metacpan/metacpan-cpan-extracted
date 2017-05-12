#!perl -T
use strict;
use warnings;
use Test::More 'no_plan';
BEGIN { use_ok( 'Game::Battleship' ) }
diag("Testing Game::Battleship $Game::Battleship::VERSION, Perl $], $^X");
