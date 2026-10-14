#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal::Kit::Choose;
use Game::Terminal::Kit::Log;
use Game::Terminal::Kit::Test::Screen qw/kit/;

my @pieces = ([ q => 'a queen', 'nearly always' ], [ n => 'a knight', 'for the fork' ], [ r => 'a rook' ]);

sub ask { return Game::Terminal::Kit::Choose->new(question => 'Promote to', choices => \@pieces, @_) }

subtest 'the screen' => sub {
	plan tests => 4;
	is_deeply [ask()->lines], [
		'Promote to', '',
		' >  1. a queen   nearly always',
		'    2. a knight  for the fork',
		'    3. a rook',
		'', 'up and down to choose, enter to take it, q to leave',
	], 'the question, the answers with what is said of them, the keys';
	is_deeply [ask(legend => [])->lines], ['Promote to', '', ' >  1. a queen   nearly always',
		'    2. a knight  for the fork', '    3. a rook'], 'a legend of the game\'s own, here none';
	is_deeply [(ask(at => 2, legend => [])->lines)[-1]], [' >  3. a rook'], 'the cursor where it was asked to start';

	my $log = Game::Terminal::Kit::Log->new->note('The pawn reached the last rank.');
	is_deeply [(ask(log => $log)->lines)[0 .. 3]],
		['Promote to', '', 'The pawn reached the last rank.', ''], 'a log is drawn under the question';
};

subtest 'the answers' => sub {
	plan tests => 9;
	my $ask = ask();
	is $ask->at, 0, 'the first to begin with';
	is_deeply [$ask->step('enter')], ['chosen', 'q'], 'enter takes it';
	is_deeply [$ask->step('down')], ['moved'], 'down';
	is $ask->at, 1, 'moves the cursor, and at says so';
	is_deeply [$ask->step(' ')], ['chosen', 'n'], 'space takes the second';
	is_deeply [$ask->step('3'), $ask->step('enter')], ['moved', 'chosen', 'r'], 'a digit and enter';
	is_deeply [$ask->step('down'), $ask->at], ['moved', 0], 'down from the last goes round';
	is_deeply [$ask->step('escape')], ['back'], 'escape goes back';
	is_deeply [$ask->step('q')], ['quit'], 'q quits';
};

subtest 'run' => sub {
	plan tests => 4;
	my ($keys, $screen, $text) = kit(keys => "\e[B\r");
	is_deeply [ask()->run($keys, $screen)], ['chosen', 'n'], 'down and enter is the knight';
	is scalar(() = ${$text} =~ m/^Promote to$/mg), 2, 'two frames, one a key';
	($keys, $screen) = kit(keys => 'q');
	is_deeply [ask()->run($keys, $screen)], ['quit'], 'q leaves';
	($keys, $screen) = kit(keys => '');
	is_deeply [ask()->run($keys, $screen)], ['quit'], 'and so does no keyboard';
};

done_testing;
