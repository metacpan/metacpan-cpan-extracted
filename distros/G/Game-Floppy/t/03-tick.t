#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

use Game::Floppy;
use Game::Floppy::Test::Fly;

# THE RULES OF 0.08, COUNTED. A bird never flapped dies on the ground at tick
# 75 (176 + 3 x 75 = 401 > 400); one flapped every tick dies off the top at
# tick 7. The first tube appears at tick 100 at x 516 and moves 3 a tick; it
# first overlaps the bird's disc at tick 238 (x 102, dx 48) and is passed at
# tick 263 (x 27). With the defaults y is always 2 mod 3 and x 0 mod 3, so the
# strict comparisons are tested on heights 401 and 402 and on the geometry
# function itself.

subtest 'never flapped, the bird falls to the ground' => sub {
	my $game = Game::Floppy->new;
	my $steps = Game::Floppy::Test::Fly->play($game, Game::Floppy::Test::Fly->never, 200);
	is(scalar @$steps, 75, 'seventy-five ticks');
	is($steps->[-1]{died}, 'ground', 'died on the ground');
	is($game->bird->{y}, 401, 'at y 401');
	is($game->ticks, 75, 'ticks count the fatal tick');
	is($game->result->cause, 'ground', 'the result says ground');
	is_deeply($game->tick, { moved => 0 }, 'a tick on a finished game moves nothing');
	ok(!grep({ $_->{died} } @$steps[0 .. 73]), 'and no step before the last died');
};

subtest 'flapped every tick, the bird flies off the top' => sub {
	my $game = Game::Floppy->new;
	my $steps = Game::Floppy::Test::Fly->play($game, Game::Floppy::Test::Fly->always, 200);
	is(scalar @$steps, 7, 'seven ticks');
	is($steps->[-1]{died}, 'sky', 'died in the sky');
	is($game->bird->{y}, -13, 'at y -13');
	is($game->result->cause, 'sky', 'the result says sky');
};

subtest 'the ground is strict: y equal to the height is alive' => sub {
	my $game = Game::Floppy->new(height => 401);
	$game->tick for 1 .. 75;
	is($game->bird->{y}, 401, 'y is 401 at tick 75');
	is($game->status, 'active', 'and the bird lives on a field 401 high');
	my $step = $game->tick;
	is($step->{died}, 'ground', 'the next tick, at 404, kills');
};

subtest 'the sky is strict: y zero is alive' => sub {
	my $game = Game::Floppy->new(height => 402);
	$game->tick for 1 .. 4;
	is($game->bird->{y}, 189, 'four falls from 177');
	for (1 .. 7) { $game->flap; $game->tick }
	is($game->bird->{y}, 0, 'seven flaps reach y 0');
	is($game->status, 'active', 'alive at zero');
	$game->flap;
	is($game->tick->{died}, 'sky', 'and the next flap is the sky');
};

subtest 'tubes appear every hundred ticks and move three a tick' => sub {
	my $game = Game::Floppy->new;
	my $fly = Game::Floppy::Test::Fly->every(10);
	for (1 .. 99) { $game->flap if $fly->($game); $game->tick }
	is_deeply($game->tubes, [], 'none at tick 99');
	$game->flap if $fly->($game);
	$game->tick;
	my $tubes = $game->tubes;
	is(scalar @$tubes, 1, 'one at tick 100');
	is($tubes->[0]{x}, 516, 'at the right edge');
	is($tubes->[0]{gap_bottom} - $tubes->[0]{gap_top}, 140, 'with a gap 140 high');
	is($tubes->[0]{k}, 0, 'the first');
	$game->flap if $fly->($game);
	$game->tick;
	is($game->tubes->[0]{x}, 513, 'x 513 at tick 101');
	for (102 .. 200) { $game->flap if $fly->($game); $game->tick }
	is(scalar @{ $game->tubes }, 2, 'two at tick 200');
	is($game->tubes->[1]{k}, 1, 'the second is the second');
};

subtest 'the hover driver keeps the bird between 176 and 203' => sub {
	my $game = Game::Floppy->new(seed => 'hover');
	my $fly = Game::Floppy::Test::Fly->every(10);
	my ($low, $high) = (999, -999);
	for (1 .. 90) {
		$game->flap if $fly->($game);
		$game->tick;
		my $y = $game->bird->{y};
		$low = $y if $y < $low;
		$high = $y if $y > $high;
	}
	is($low, 176, 'never above 176');
	is($high, 203, 'never below 203');
};

sub seed_with_gap_top {
	my ($test) = @_;
	for my $i (1 .. 5000) {
		my $game = Game::Floppy->new(seed => "gap$i");
		Game::Floppy::Test::Fly->advance($game, 100);
		return "gap$i" if $test->($game->tubes->[0]{gap_top});
	}
	return undef;
}

subtest 'a tube whose top pipe reaches the bird kills at tick 238' => sub {
	my $seed = seed_with_gap_top(sub { $_[0] >= 200 });
	ok($seed, "a seed ($seed) with gap_top at or below the bird was found");
	my $game = Game::Floppy->new(seed => $seed);
	my $fly = Game::Floppy::Test::Fly->every(10);
	for (1 .. 237) { $game->flap if $fly->($game); $game->tick }
	is($game->status, 'active', 'alive at tick 237');
	is($game->tubes->[0]{x}, 105, 'with the tube at x 105, dx 51');
	is($game->bird->{y}, 197, 'and the bird at y 197, reaching 200 on the next tick');
	$game->flap if $fly->($game);
	my $step = $game->tick;
	is($step->{died}, 'tube', 'tick 238, x 102, dx 48: dead');
	is($game->score, 0, 'for nothing');
	is($game->result->stringify, 'Game over: hit a tube at 0 points after 238 ticks', 'the sentence');
};

subtest 'a tube whose gap holds the hover is passed at tick 263' => sub {
	my $seed = seed_with_gap_top(sub { $_[0] >= 88 && $_[0] <= 151 });
	ok($seed, "a seed ($seed) with the gap round the hover was found");
	my $game = Game::Floppy->new(seed => $seed);
	my $fly = Game::Floppy::Test::Fly->every(10);
	my $passed_at;
	for (1 .. 300) {
		$game->flap if $fly->($game);
		my $step = $game->tick;
		if ($step->{passed}) { $passed_at = $game->ticks; last }
		last if $step->{died};
	}
	is($passed_at, 263, 'passed on tick 263');
	is($game->score, 100, 'a hundred points');
	is($game->passed, 1, 'one tube passed');
	is(scalar @{ $game->tubes }, 1, 'one tube left');
	is($game->tubes->[0]{x}, 327, 'the second, at x 327');
	is($game->tubes->[0]{k}, 1, 'and it is the second');
};

subtest 'a tube whose bottom pipe reaches the hover kills before it is passed' => sub {
	my $seed = seed_with_gap_top(sub { $_[0] >= 68 && $_[0] <= 87 });
	ok($seed, "a seed ($seed) with gap_bottom between 208 and 227 was found");
	my $game = Game::Floppy->new(seed => $seed);
	my $fly = Game::Floppy::Test::Fly->every(10);
	my $died_at;
	for (1 .. 300) {
		$game->flap if $fly->($game);
		my $step = $game->tick;
		if ($step->{died}) { $died_at = $game->ticks; last }
		last if $step->{passed};
	}
	ok($died_at, 'the bird died');
	is($game->result->cause, 'tube', 'on the tube');
	cmp_ok($died_at, '>=', 238, 'not before the tube reached it');
	cmp_ok($died_at, '<', 263, 'and before it could have passed');
	cmp_ok($game->bird->{y} + 24, '>=', $game->tubes->[0]{gap_bottom} - 24,
		'with the disc down at the bottom pipe');
};

subtest 'the geometry, directly' => sub {
	my $f = 'Game::Floppy';
	is($f->circle_hits_rectangle(80, 200, 24, 105, 0, 52, 200), 0, 'dx 51 misses');
	is($f->circle_hits_rectangle(80, 200, 24, 102, 0, 52, 200), 1, 'dx 48 hits');
	is($f->circle_hits_rectangle(80, 200, 24, 102, 0, 52, 199), 1, 'and a pipe ending one above the centre still hits');
	is($f->circle_hits_rectangle(0, 0, 24, 22, 9, 10, 10), 1, 'the corner at (22, 9) is inside the radius');
	is($f->circle_hits_rectangle(0, 0, 24, 22, 10, 10, 10), 0, 'the corner at (22, 10) is outside');
	is($f->circle_hits_rectangle(80, 176, 24, 60, 200, 52, 400), 1, 'a disc touching the bottom pipe from above hits');
	is($f->circle_hits_rectangle(80, 175, 24, 60, 200, 52, 400), 0, 'one pixel higher misses');
	is($f->circle_hits_rectangle(80, 200, 24, 60, 300, 52, 400), 0, 'and well clear misses');
};

done_testing();
