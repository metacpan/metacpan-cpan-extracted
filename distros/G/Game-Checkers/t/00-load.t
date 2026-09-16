#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

my @modules = qw/
	Game::Checkers
	Game::Checkers::Squares
	Game::Checkers::Piece
	Game::Checkers::Move
	Game::Checkers::Notation
	Game::Checkers::Board
	Game::Checkers::Rules
	Game::Checkers::Error
	Game::Checkers::Result
	Game::Checkers::Bot
	Game::Checkers::Terminal
/;

plan tests => scalar(@modules) + 1;

use_ok($_) for @modules;

# Game::Cribbage shipped a POD version one ahead of its distribution and nothing
# caught it, so every module carries $VERSION and they are asserted to agree.
my %version;
no strict 'refs';
$version{${"${_}::VERSION"}}++ for @modules;
use strict 'refs';

is scalar(keys %version), 1,
	'every module carries the same $VERSION (' . join(', ', keys %version) . ')';

diag("Testing Game::Checkers $Game::Checkers::VERSION, Perl $], $^X");
