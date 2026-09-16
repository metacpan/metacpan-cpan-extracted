#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers::Squares;

my $S = 'Game::Checkers::Squares';

# The coordinate table, written out by hand. This is the one table in the
# distribution that must not be produced by the code it checks: everything else
# is derived from it.
#
# Rows run 0 to 7 from Black's back rank, columns 0 to 7 from the left. Squares
# 1 to 4 are the top row. Even rows hold the playing squares on columns 1, 3, 5
# and 7, odd rows on columns 0, 2, 4 and 6.
my %COORD = (
	1  => [0, 1], 2  => [0, 3], 3  => [0, 5], 4  => [0, 7],
	5  => [1, 0], 6  => [1, 2], 7  => [1, 4], 8  => [1, 6],
	9  => [2, 1], 10 => [2, 3], 11 => [2, 5], 12 => [2, 7],
	13 => [3, 0], 14 => [3, 2], 15 => [3, 4], 16 => [3, 6],
	17 => [4, 1], 18 => [4, 3], 19 => [4, 5], 20 => [4, 7],
	21 => [5, 0], 22 => [5, 2], 23 => [5, 4], 24 => [5, 6],
	25 => [6, 1], 26 => [6, 3], 27 => [6, 5], 28 => [6, 7],
	29 => [7, 0], 30 => [7, 2], 31 => [7, 4], 32 => [7, 6],
);

subtest 'the coordinate table' => sub {
	plan tests => 32 * 3;
	for my $n (1 .. 32) {
		my ($row, $col) = $S->can('coords')->($n);
		is $row, $COORD{$n}[0], "square $n is on row $COORD{$n}[0]";
		is $col, $COORD{$n}[1], "square $n is on column $COORD{$n}[1]";
		is $S->can('square')->(@{$COORD{$n}}), $n,
			"row $COORD{$n}[0] column $COORD{$n}[1] is square $n";
	}
};

subtest 'the numbering agrees with the known opening moves' => sub {
	plan tests => 2;

	# The seven first moves of each side are a fact about the game, not about
	# this code, which is what makes them worth testing the numbering against.
	my @black;
	for my $n (9 .. 12) {
		my $steps = Game::Checkers::Squares::steps($n);
		push @black, map { "$n-$steps->{$_}" }
			grep { $steps->{$_} } qw/SW SE/;
	}
	is_deeply [sort @black],
		[sort qw/9-13 9-14 10-14 10-15 11-15 11-16 12-16/],
		q|Black's seven opening moves|;

	my @white;
	for my $n (21 .. 24) {
		my $steps = Game::Checkers::Squares::steps($n);
		push @white, map { "$n-$steps->{$_}" }
			grep { $steps->{$_} } qw/NW NE/;
	}
	is_deeply [sort @white],
		[sort qw/21-17 22-17 22-18 23-18 23-19 24-19 24-20/],
		q|White's seven opening moves|;
};

subtest 'steps, spelled out for every kind of edge' => sub {
	my %expect = (
		1  => { NE => undef, NW => undef, SE => 6,     SW => 5 },
		4  => { NE => undef, NW => undef, SE => undef, SW => 8 },
		5  => { NE => 1,     NW => undef, SE => 9,     SW => undef },
		12 => { NE => undef, NW => 8,     SE => undef, SW => 16 },
		13 => { NE => 9,     NW => undef, SE => 17,    SW => undef },
		15 => { NE => 11,    NW => 10,    SE => 19,    SW => 18 },
		20 => { NE => undef, NW => 16,    SE => undef, SW => 24 },
		28 => { NE => undef, NW => 24,    SE => undef, SW => 32 },
		29 => { NE => 25,    NW => undef, SE => undef, SW => undef },
		32 => { NE => 28,    NW => 27,    SE => undef, SW => undef },
	);
	plan tests => scalar keys %expect;
	is_deeply Game::Checkers::Squares::steps($_), $expect{$_}, "steps from $_"
		for sort { $a <=> $b } keys %expect;
};

subtest 'jumps' => sub {
	plan tests => 9;
	is_deeply [Game::Checkers::Squares::jump(15, 'SE')], [19, 24], '15 jumps 19 to 24';
	is_deeply [Game::Checkers::Squares::jump(15, 'NW')], [10, 6],  '15 jumps 10 to 6';
	is_deeply [Game::Checkers::Squares::jump(9, 'SE')],  [14, 18], '9 jumps 14 to 18';
	is_deeply [Game::Checkers::Squares::jump(13, 'NE')], [9, 6],   '13 jumps 9 to 6';
	is_deeply [Game::Checkers::Squares::jump(13, 'SE')], [17, 22], '13 jumps 17 to 22';
	is_deeply [Game::Checkers::Squares::jump(4, 'SW')],  [8, 11],  '4 jumps 8 to 11';

	is_deeply [Game::Checkers::Squares::jump(5, 'NE')], [],
		'5 has a neighbour to the north east but no square to land on';
	is Game::Checkers::Squares::steps(5)->{NE}, 1,
		'and the step itself is still there, so a jump is not a step';
	is_deeply [Game::Checkers::Squares::jump(1, 'NE')], [],
		'a jump off the top of the board is nothing';
};

subtest 'directions and crowning' => sub {
	plan tests => 10;
	is_deeply [Game::Checkers::Squares::forward_dirs('black')],
		[Game::Checkers::Squares::SE, Game::Checkers::Squares::SW],
		'black men move south';
	is_deeply [Game::Checkers::Squares::forward_dirs('white')],
		[Game::Checkers::Squares::NE, Game::Checkers::Squares::NW],
		'white men move north';
	is Game::Checkers::Squares::dir_index('se'), Game::Checkers::Squares::SE,
		'a direction name is case insensitive';
	is Game::Checkers::Squares::dir_name(0), 'NE', 'and comes back as a name';

	ok Game::Checkers::Squares::crowning($_, 'black'), "black crowns on $_"
		for 29, 32;
	ok !Game::Checkers::Squares::crowning(28, 'black'), 'black does not crown on 28';
	ok Game::Checkers::Squares::crowning($_, 'white'), "white crowns on $_"
		for 1, 4;
	ok !Game::Checkers::Squares::crowning(5, 'white'), 'white does not crown on 5';
};

subtest 'what is not a square' => sub {
	plan tests => 7;
	is Game::Checkers::Squares::square(0, 0), undef, 'a light square is not a square';
	is Game::Checkers::Squares::square(-1, 1), undef, 'off the top';
	is Game::Checkers::Squares::square(8, 1), undef, 'off the bottom';
	is Game::Checkers::Squares::square(0, 8), undef, 'off the side';
	ok !eval { Game::Checkers::Squares::coords(33); 1 }, 'square 33 dies';
	ok !eval { Game::Checkers::Squares::coords(0); 1 }, 'square 0 dies';
	ok !eval { Game::Checkers::Squares::crowning(1, 'red'); 1 }, 'a third colour dies';
};

subtest 'coord_name' => sub {
	plan tests => 3;
	is Game::Checkers::Squares::coord_name(1), 'b8', 'square 1 is b8';
	is Game::Checkers::Squares::coord_name(32), 'g1', 'square 32 is g1';
	is Game::Checkers::Squares::coord_name(15), 'e5', 'square 15 is e5';
};

subtest 'coord_square is coord_name backwards' => sub {
	plan tests => 32 + 5;
	for my $n (1 .. 32) {
		my $name = Game::Checkers::Squares::coord_name($n);
		is Game::Checkers::Squares::coord_square($name), $n, "$name is square $n";
	}
	is Game::Checkers::Squares::coord_square('B8'), 1, 'the file may be upper case';
	is Game::Checkers::Squares::coord_square('a8'), undef, 'a light square is not one';
	is Game::Checkers::Squares::coord_square('i5'), undef, 'nor is a file off the board';
	is Game::Checkers::Squares::coord_square('e9'), undef, 'nor a rank off it';
	is Game::Checkers::Squares::coord_square('wibble'), undef, 'nor a word';
};

done_testing;
