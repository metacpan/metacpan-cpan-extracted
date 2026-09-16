#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

my @modules = qw/
	Game::Dominoes
	Game::Dominoes::Tile
	Game::Dominoes::Set
	Game::Dominoes::Hand
	Game::Dominoes::Boneyard
	Game::Dominoes::Play
	Game::Dominoes::Layout
	Game::Dominoes::Rules
	Game::Dominoes::Scoring
	Game::Dominoes::Notation
	Game::Dominoes::Error
	Game::Dominoes::Result
	Game::Dominoes::Bot
	Game::Dominoes::Terminal
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

diag("Testing Game::Dominoes $Game::Dominoes::VERSION, Perl $], $^X");
