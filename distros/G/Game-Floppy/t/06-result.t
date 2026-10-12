#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

use Game::Floppy;
use Game::Floppy::Result;
use Game::Floppy::Test::Fly;

# A RESULT SAYS HOW IT ENDED IN ONE SENTENCE, quit is an ending that is not a
# death, and reset replays the same game from the start.

subtest 'the three deaths have their sentences' => sub {
	my $game = Game::Floppy->new;
	Game::Floppy::Test::Fly->play($game, Game::Floppy::Test::Fly->never, 200);
	is($game->result->stringify, 'Game over: fell to the ground at 0 points after 75 ticks', 'ground');
	is($game->result->died, 1, 'which is a death');
	is($game->result->tubes, 0, 'no tubes passed');

	$game = Game::Floppy->new;
	Game::Floppy::Test::Fly->play($game, Game::Floppy::Test::Fly->always, 200);
	is($game->result->stringify, 'Game over: flew off the top at 0 points after 7 ticks', 'sky');

	$game = Game::Floppy->new(seed => 'tube');
	Game::Floppy::Test::Fly->play($game, Game::Floppy::Test::Fly->hold(200), 5000);
	is($game->status, 'finished', 'a bird holding y 200 meets a tube in the end');
	is($game->result->cause, 'tube', 'tube');
	like($game->result->stringify, qr/\AGame over: hit a tube at (?:\d+00|0) points after \d+ ticks\z/, 'with the sentence');
	is($game->result->tubes * 100, $game->result->score, 'tubes times a hundred is the score');
};

subtest 'quit is an ending that is not a death' => sub {
	my $game = Game::Floppy->new;
	$game->tick for 1 .. 10;
	is($game->result, undef, 'no result while active');
	is($game->quit, 1, 'quit finishes the game');
	is($game->status, 'finished', 'finished');
	is($game->result->cause, 'quit', 'as quit');
	is($game->result->died, 0, 'not a death');
	is($game->result->stringify, 'Quit at 0 points after 10 ticks', 'with its own sentence');
	is($game->quit, 0, 'a second quit does nothing');
	is_deeply($game->tick, { moved => 0 }, 'nor does a tick');
};

subtest 'reset replays the same game' => sub {
	my $game = Game::Floppy->new(seed => 'again');
	my $fly = Game::Floppy::Test::Fly->every(10);
	for (1 .. 150) { $game->flap if $fly->($game); $game->tick }
	ok(@{ $game->tubes }, 'a tube is on the field');
	$game->flap;
	ok($game->flap == 0, 'and a flap is pending');
	$game->reset;
	is($game->status, 'ready', 'reset leaves the game ready');
	is_deeply($game->bird, { x => 80, y => 176, radius => 24, tilt => 0 }, 'the bird at the start');
	is_deeply($game->tubes, [], 'no tubes');
	is($game->ticks, 0, 'no ticks');
	is($game->result, undef, 'no result');
	my $steps = Game::Floppy::Test::Fly->play($game, Game::Floppy::Test::Fly->never, 200);
	is(scalar @$steps, 75, 'the flap pending before the reset is gone: the ground death is at 75 again');
	$game->reset;
	Game::Floppy::Test::Fly->advance($game, 100);
	my $first = $game->tubes->[0]{gap_top};
	$game->reset;
	Game::Floppy::Test::Fly->advance($game, 100);
	is($game->tubes->[0]{gap_top}, $first, 'and the first tube is the same tube');
};

subtest 'the result class checks its arguments' => sub {
	my $r = eval { Game::Floppy::Result->new(cause => 'tired') };
	like($@, qr/'tired' is not a cause/, 'an unknown cause dies');
	$r = eval { Game::Floppy::Result->new(caus => 'tube') };
	like($@, qr/'undef' is not a cause/, 'a misspelt cause is dropped, so the cause is missing and it dies');
	$r = eval { Game::Floppy::Result->new(cause => 'tube', score => 'lots') };
	like($@, qr/score must be a whole number/, 'a score that is not a number dies');
	is_deeply(Game::Floppy::Result->causes, [qw/ ground sky tube quit /], 'the causes are listed');
};

done_testing();
