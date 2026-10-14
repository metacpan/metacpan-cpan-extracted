#!perl
use 5.014;
use strict;
use warnings;
use utf8;
use Test::More;

use Game::Terminal::Kit::Canvas;
use Game::Terminal::Kit::Frame;
use Game::Terminal::Kit::Screen;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw/output failure_output todo_output/;

sub canvas { return Game::Terminal::Kit::Canvas->new(width => $_[0], height => $_[1]) }

open my $sink, '>', \my $unused or die $!;
my $plain = Game::Terminal::Kit::Screen->new(out => $sink, colour => 0);
my $coloured = Game::Terminal::Kit::Screen->new(out => $sink, colour => 1);

subtest 'an empty canvas' => sub {
	plan tests => 4;
	is_deeply [canvas(4, 3)->text], ['', '', ''], 'three rows of nothing';
	is_deeply [canvas(4, 3)->lines($coloured)], ['', '', ''], 'with colour too';
	is_deeply [canvas(0, 0)->text], [], 'no size is no rows';
	is_deeply [Game::Terminal::Kit::Canvas->new->text], [], 'nor is no size given';
};

subtest 'putting text' => sub {
	plan tests => 7;
	my $canvas = canvas(6, 3);
	is $canvas->put(1, 1, 'abc'), $canvas, 'put returns the canvas';
	is_deeply [$canvas->text], ['', ' abc', ''], 'where it was put, nothing after it';
	$canvas->put(3, 1, 'XY');
	is_deeply [$canvas->text], ['', ' abXY', ''], 'later text goes over earlier';
	$canvas->put(0, 0, undef)->put(0, 0, '');
	is_deeply [$canvas->text], ['', ' abXY', ''], 'no text puts nothing';
	$canvas->put(5, 2, '!');
	is_deeply [$canvas->text], ['', ' abXY', '     !'], 'the last cell of the last row';
	$canvas->put(0, 0, '#');
	is_deeply [$canvas->text], ['#', ' abXY', '     !'], 'and the first of the first';
	is_deeply [$canvas->wipe->text], ['', '', ''], 'wipe empties it';
};

subtest 'the edges' => sub {
	plan tests => 6;
	is_deeply [canvas(4, 2)->put(2, 0, 'abcd')->text], ['  ab', ''], 'off the right, the rest is dropped';
	is_deeply [canvas(4, 2)->put(-2, 0, 'abcd')->text], ['cd', ''], 'off the left, the start is dropped';
	is_deeply [canvas(4, 2)->put(0, -1, 'ab')->text], ['', ''], 'above';
	is_deeply [canvas(4, 2)->put(0, 2, 'ab')->text], ['', ''], 'below';
	is_deeply [canvas(4, 2)->put(4, 1, 'ab')->text], ['', ''], 'wholly off the right';
	is_deeply [canvas(4, 2)->put(-9, 1, 'ab')->text], ['', ''], 'wholly off the left';
};

subtest 'colour is written where it changes' => sub {
	plan tests => 9;
	my $canvas = canvas(8, 1)->put(0, 0, 'aaa', ink => '31')->put(3, 0, 'b')->put(4, 0, 'cc', ink => '1', ground => '44');
	is_deeply [$canvas->lines($coloured)], ["\e[31maaa\e[0mb\e[1;44mcc\e[0m"],
		'one sequence for a run, a reset before plain text and at the end';
	is_deeply [$canvas->lines($plain)], ['aaabcc'], 'none for a screen without colour';
	is_deeply [$canvas->lines], ['aaabcc'], 'none for no screen';
	is_deeply [$canvas->text], ['aaabcc'], 'and none in text';

	is_deeply [canvas(4, 1)->put(0, 0, 'ab', ink => '31')->put(2, 0, 'cd', ink => '32')->lines($coloured)],
		["\e[31mab\e[0;32mcd\e[0m"], 'one style straight to another resets on the way';
	is_deeply [canvas(4, 1)->put(0, 0, 'ab')->lines($coloured)], ['ab'], 'plain text has no sequence at all';
	is_deeply [canvas(4, 1)->put(0, 0, 'ab', ink => '', ground => undef)->lines($coloured)], ['ab'],
		'an empty style is no style';

	is_deeply [canvas(4, 1)->fill(0, 0, 4, 1, ' ', ground => '42')->put(0, 0, 'a', ground => '42')->lines($coloured)],
		["\e[42ma   \e[0m"], 'spaces with a ground are kept to the end of the row';
	is_deeply [canvas(4, 1)->fill(0, 0, 4, 1, ' ', ground => '42')->put(0, 0, 'a', ground => '42')->lines($plain)],
		['a'], 'and left off when there is no colour to show them';
};

subtest 'wide glyphs take two columns' => sub {
	plan tests => 8;
	my $canvas = canvas(8, 1)->put(0, 0, '車馬', wide => 1)->put(4, 0, '|');
	is_deeply [$canvas->text], ['車馬|'], 'what follows two wide glyphs lands in the fifth column';
	is $canvas->cells->[0][1][0], '', 'the second cell of a wide glyph holds nothing';
	is $canvas->cells->[0][4][0], '|', 'and the fifth cell holds what was put there';

	is_deeply [canvas(4, 1)->put(0, 0, '車', wide => 1)->put(1, 0, 'x')->text], [' x'],
		'writing on the second half clears the first';
	is_deeply [canvas(4, 1)->put(0, 0, '車', wide => 1)->put(0, 0, 'x')->text], ['x'],
		'writing on the first half clears the second';
	is_deeply [canvas(4, 1)->put(0, 0, '車馬', wide => 1)->put(1, 0, '象', wide => 1)->put(3, 0, '!')->text], [' 象!'],
		'a wide glyph across two others clears both';
	is_deeply [canvas(3, 1)->put(0, 0, '車馬', wide => 1)->text], ['車'],
		'a wide glyph with one column left is dropped';
	is_deeply [canvas(4, 1)->put(-1, 0, '車馬', wide => 1)->text], [' 馬'],
		'and so is one half off the left';
};

subtest 'filling and boxing' => sub {
	plan tests => 8;
	is_deeply [canvas(5, 3)->fill(1, 1, 3, 1, '.')->text], ['', ' ...', ''], 'a row of dots';
	is_deeply [canvas(5, 3)->fill(3, 1, 9, 9, '.')->text], ['', '   ..', '   ..'], 'a fill is clipped';
	is_deeply [canvas(5, 2)->put(0, 0, 'abcde')->fill(1, 0, 3, 1)->text], ['a   e', ''], 'a fill with no glyph is spaces';

	my $light = Game::Terminal::Kit::Frame::box('plain', 1);
	is_deeply [canvas(7, 4)->box(1, 0, 5, 4, $light)->text], [' +---+', ' |   |', ' |   |', ' +---+'], 'a box';
	is_deeply [canvas(7, 4)->put(2, 1, 'abc')->box(1, 0, 5, 3, $light)->text], [' +---+', ' |abc|', ' +---+', ''],
		'a box leaves its inside alone';
	is_deeply [canvas(7, 2)->box(0, 0, 2, 2, $light)->text], ['++', '++'], 'the smallest box';
	is_deeply [canvas(7, 2)->box(0, 0, 1, 2, $light)->box(0, 0, 3, 1, $light)->text], ['', ''], 'less than two either way is nothing';

	my @shapes = map { join '|', canvas(5, 3)->box(0, 0, 5, 3, Game::Terminal::Kit::Frame::box($_, 0))->put(2, 1, '6')->text } qw/plain recent cursor/;
	is_deeply \@shapes, ['┌───┐|│ 6 │|└───┘', '╔═══╗|║ 6 ║|╚═══╝', '┏━━━┓|┃ 6 ┃|┗━━━┛'],
		'the three weights round the same piece';
};

done_testing;
