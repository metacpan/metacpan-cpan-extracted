#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

use Game::Snake;
use Game::Snake::Result;
use Game::Snake::Test::Steer;

# A RESULT SAYS HOW IT ENDED IN ONE SENTENCE, reset replays the same game,
# and quit is an ending that is not a death.

subtest 'a result after a death' => sub {
	my $game = Game::Snake->new(cols => 10, rows => 8, seed => 'ending');
	Game::Snake::Test::Steer->play($game, 'greedy', 5000);
	is($game->status, 'finished', 'the greedy steer dies on a small board');
	my $result = $game->result;
	isa_ok($result, 'Game::Snake::Result');
	ok($result->cause eq 'wall' || $result->cause eq 'body', 'at a wall or its body (' . $result->cause . ')');
	is($result->score, $game->score, 'the score');
	is($result->length, $game->length, 'the length');
	is($result->ticks, $game->ticks, 'the ticks');
	is($result->speed, $game->speed, 'the speed');
	is($result->died, 1, 'it died');
	like($result->stringify, qr/\AGame over: (hit the wall|ran into yourself) at \d+ points, \d+ long\z/,
		'and the sentence says so');
};

subtest 'quit is an ending that is not a death' => sub {
	my $game;
	for my $i (1 .. 200) {
		$game = Game::Snake->new(cols => 10, rows => 8, seed => "quiet$i");
		my $food = $game->food;
		last unless $food->[1] == 5 && $food->[0] < 3;
		$game = undef;
	}
	ok($game, 'a seed with no food in the first two cells of the path was found');
	$game->tick for 1 .. 2;
	is($game->quit, 1, 'quit finishes the game');
	is($game->status, 'finished', 'finished');
	is($game->result->cause, 'quit', 'as quit');
	is($game->result->died, 0, 'which is not a death');
	is($game->result->stringify, 'Quit at 0 points, 3 long', 'with its own sentence');
	is($game->quit, 0, 'and a second quit does nothing');
	is_deeply($game->tick, { moved => 0 }, 'nor does a tick');
};

subtest 'reset replays the same game' => sub {
	my $game = Game::Snake->new(cols => 12, rows => 10, seed => 'again');
	my $first = Game::Snake::Test::Steer->play($game, 'greedy', 60);
	my $body = $game->segments;
	my $score = $game->score;
	ok($score > 0, 'the first run scored');
	$game->reset;
	is($game->status, 'ready', 'reset leaves the game ready');
	is($game->score, 0, 'with no score');
	is($game->ticks, 0, 'no ticks');
	is($game->length, 3, 'three long');
	is($game->heading, 'left', 'heading left');
	is($game->result, undef, 'and no result');
	my $second = Game::Snake::Test::Steer->play($game, 'greedy', 60);
	is_deeply($second, $first, 'the same steps');
	is_deeply($game->segments, $body, 'the same snake');
	is($game->score, $score, 'the same score');
};

subtest 'reset clears a queued turn, with or without a finish' => sub {
	my $game = Game::Snake->new(cols => 10, rows => 8);
	$game->turn('up');
	$game->reset;
	$game->tick;
	is($game->heading, 'left', 'a turn queued before a reset is forgotten');

	$game = Game::Snake->new(cols => 10, rows => 8);
	$game->turn('up');
	$game->quit;
	$game->reset;
	is($game->turn('up'), 1, 'up can be queued again after a quit and a reset');
	$game->tick;
	is($game->heading, 'up', 'and it is the only thing queued');
};

subtest 'the result class checks its arguments' => sub {
	my $r = eval { Game::Snake::Result->new(cause => 'tired') };
	like($@, qr/'tired' is not a cause/, 'an unknown cause dies');
	$r = eval { Game::Snake::Result->new(caus => 'wall') };
	like($@, qr/'undef' is not a cause/, 'a misspelt cause is dropped, so the cause is missing and it dies');
	$r = eval { Game::Snake::Result->new(cause => 'wall', score => 'lots') };
	like($@, qr/score must be a whole number/, 'a score that is not a number dies');
	is_deeply(Game::Snake::Result->causes, [qw/ wall body full quit /], 'the causes are listed');
	is(Game::Snake::Result->new(cause => 'full', score => 330, length => 36)->stringify,
		'Game over: filled the board at 330 points, 36 long', 'a full board has its sentence');
};

done_testing();
