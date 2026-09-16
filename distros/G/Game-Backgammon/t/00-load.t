#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Everything loads, and the engine loads WITHOUT the terminal: a consumer
# that wants the rules must not drag a user interface in behind them.

my @engine = qw(
    Game::Backgammon
    Game::Backgammon::Board
    Game::Backgammon::Bot
    Game::Backgammon::Dice
    Game::Backgammon::Error
    Game::Backgammon::Move
    Game::Backgammon::Notation
    Game::Backgammon::Result
    Game::Backgammon::Rules
    Game::Backgammon::Shots
    Game::Backgammon::Turn
);

plan tests => scalar(@engine) + 2;

use_ok($_) || print "Bail out!\n" for @engine;

ok(!$INC{'Game/Backgammon/Terminal.pm'},
   'the engine does not load the terminal: a consumer of the rules gets only the rules');

use_ok('Game::Backgammon::Terminal');

diag("Testing Game::Backgammon $Game::Backgammon::VERSION, Perl $], $^X");
