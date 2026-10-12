#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Snake;

# THE START POSITION IS 0.11'S, IN CELLS. 0.11 put the head at pixel
# (300,400) on an 800x600 window of 20 px cells under a 20 px band, which is
# column 15, row 18 of a 40x28 board, body to the right, heading left. The
# same fractions lay a smaller board.

subtest 'the default board' => sub {
	my $game = Game::Snake->new;
	is($game->cols, 40, '40 across');
	is($game->rows, 28, '28 down');
	is($game->status, 'ready', 'ready');
	is($game->heading, 'left', 'heading left');
	is($game->length, 3, 'three long');
	is($game->score, 0, 'no score');
	is($game->speed, 2, 'two cells a second');
	is($game->ticks, 0, 'no ticks');
	is($game->result, undef, 'no result');
	is($game->error, undef, 'no error');

	is_deeply($game->segments, [
		{ x => 15, y => 18, dir => 'left', bend => 0, last => 0 },
		{ x => 16, y => 18, dir => 'left', bend => 0, last => 0 },
		{ x => 17, y => 18, dir => 'left', bend => 0, last => 1 },
	], 'head at (15,18), body to the right');

	is($game->at(15, 18), 'head', 'at knows the head');
	is($game->at(16, 18), 'body', 'the body');
	is($game->at(17, 18), 'tail', 'the tail');
	is($game->at(0, 0), undef, 'and an empty cell');

	my $food = $game->food;
	ok($food, 'there is food from the start');
	is($game->at(@$food), 'food', 'and at finds it');
	ok(!(grep { $_->{x} == $food->[0] && $_->{y} == $food->[1] } @{ $game->segments }),
		'and it is not on the snake');

	is(scalar($game->free_cells), 40 * 28 - 3, 'free cells are every cell but the snake');
};

subtest 'the smallest board' => sub {
	my $game = Game::Snake->new(cols => 6, rows => 6);
	is_deeply([ map { [ $_->{x}, $_->{y} ] } @{ $game->segments } ],
		[ [ 2, 3 ], [ 3, 3 ], [ 4, 3 ] ], 'head at (2,3) on 6x6');
	ok($game->food, 'with food');
};

subtest 'the arguments are checked' => sub {
	for my $case (
		[ { cols => 5 },                     qr/at least 6 by 6/,        'a board under six' ],
		[ { rows => 'x' },                   qr/rows must be a whole/,   'a row count that is not a number' ],
		[ { cols => undef },                 qr/cols must be a whole/,   'an undefined width' ],
		[ { start_length => 1 },             qr/at least 2 long/,        'a snake of one' ],
		[ { cols => 8, start_length => 7 },  qr/does not fit/,           'a snake longer than the room to its right' ],
		[ { start_speed => 0 },              qr/speed starts at 1/,      'a speed of nothing' ],
		[ { food_score => 0 },               qr/worth 1 or more/,        'food worth nothing' ],
		[ { seed => '' },                    qr/a seed is a string/,     'an empty seed' ],
	) {
		my ($args, $why, $name) = @$case;
		my $game = eval { Game::Snake->new(%$args) };
		like($@, $why, "$name is refused");
		is($game, undef, 'and nothing is built');
	}
};

subtest 'an argument name the class does not know is dropped' => sub {
	# Sugar 1.00 reads a list of name => value pairs by name and DROPS a
	# name it does not know, and BUILD is handed no arguments, so there is
	# no door through which a misspelling can be refused. This pins what
	# happens so that a Sugar that starts behaving differently shows up here.
	my $game = Game::Snake->new(colz => 9, rows => 7);
	is($game->cols, 40, 'a misspelt cols is dropped and the default stands');
	is($game->rows, 7, 'while the spelt one beside it is taken');
};

subtest 'every argument may be given' => sub {
	my $game = Game::Snake->new(cols => 10, rows => 8, seed => 'given',
		start_length => 4, food_score => 5, start_speed => 3);
	is($game->cols, 10, 'cols');
	is($game->rows, 8, 'rows');
	is($game->seed, 'given', 'seed');
	is($game->start_length, 4, 'start_length');
	is($game->length, 4, 'which is the length');
	is($game->food_score, 5, 'food_score');
	is($game->start_speed, 3, 'start_speed');
	is($game->speed, 3, 'which is the speed');
	is_deeply([ map { [ $_->{x}, $_->{y} ] } @{ $game->segments } ],
		[ [ 3, 5 ], [ 4, 5 ], [ 5, 5 ], [ 6, 5 ] ], 'head at (3,5) on 10x8');
};

done_testing();
