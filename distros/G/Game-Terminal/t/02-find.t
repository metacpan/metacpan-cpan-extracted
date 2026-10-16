#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal;

subtest 'normalise' => sub {
	plan tests => 5;
	is Game::Terminal::normalise('Checkers'), 'checkers', 'lowercased';
	is Game::Terminal::normalise('Game::Checkers'), 'checkers', 'a module name';
	is Game::Terminal::normalise('game-checkers'), 'checkers', 'a dist name';
	is Game::Terminal::normalise('Nine Men\'s Morris'), 'ninemensmorris', 'punctuation and spaces dropped';
	is Game::Terminal::normalise(undef), '', 'undef is empty';
};

subtest 'find by key' => sub {
	my @keys = Game::Terminal::names();
	plan tests => scalar @keys;
	for my $key (@keys) {
		is Game::Terminal::find(uc $key)->{key}, $key, "$key, whatever the case";
	}
};

subtest 'find by alias' => sub {
	my %alias = (
		draughts => 'checkers', othello => 'reversi', ur => 'royalur',
		morris => 'merrills', mills => 'merrills', tafl => 'brandubh',
		weiqi => 'go', baduk => 'go', chinesechess => 'xiangqi',
		'chinese-chess' => 'xiangqi', awale => 'oware', awari => 'oware',
		rummy => 'gin', crib => 'cribbage', flappy => 'floppy', 66 => 'sixtysix',
		japanesechess => 'shogi', 'japanese-chess' => 'shogi',
		chinesecheckers => 'sternhalma', 'Chinese-Checkers' => 'sternhalma',
	);
	plan tests => scalar keys %alias;
	for my $alias (sort keys %alias) {
		is Game::Terminal::find($alias)->{key}, $alias{$alias}, "$alias is $alias{$alias}";
	}
};

subtest 'sixtysix carries its variant' => sub {
	plan tests => 2;
	is_deeply Game::Terminal::find('66')->{args}, ['--variant', 'sixtysix'], 'the alias 66';
	is_deeply Game::Terminal::find('Sixty-Six')->{args}, ['--variant', 'sixtysix'], 'Sixty-Six';
};

subtest 'nothing' => sub {
	plan tests => 3;
	is Game::Terminal::find('zzz'), undef, 'an unknown name is undef';
	is Game::Terminal::find(''), undef, 'so is the empty string';
	is Game::Terminal::find(undef), undef, 'and undef';
};

subtest 'nearest' => sub {
	plan tests => 6;
	is +(Game::Terminal::nearest('chekers'))[0], 'checkers', 'a dropped letter';
	is +(Game::Terminal::nearest('rev'))[0], 'reversi', 'a prefix';
	is +(Game::Terminal::nearest('xianqi'))[0], 'xiangqi', 'a dropped letter in a long name';
	is_deeply [ Game::Terminal::nearest('zzzzzzzz') ], [], 'nothing within three edits is nothing';
	is_deeply [ Game::Terminal::nearest('') ], [], 'and the empty string offers nothing';
	is Game::Terminal::distance('kitten', 'sitting'), 3, 'the distance is Levenshtein';
};

done_testing;
