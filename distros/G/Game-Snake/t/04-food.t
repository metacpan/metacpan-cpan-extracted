#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Digest::SHA ();

use Game::Snake;
use Game::Snake::Test::Steer;

# FOOD FALLS FROM THE SEED. The k-th placement takes the free cell at index
# unpack('N', sha256($seed . "snake:food:$k")) % @free over the free cells in
# row-major order at the moment of placement: the site's rule, verbatim. So
# the same seed and the same turns are the same game twice, and a test can
# compute the first placement by hand.

subtest 'the first placement, by hand' => sub {
	for my $seed (qw/ one two three /) {
		my $game = Game::Snake->new(cols => 10, rows => 8, seed => $seed);
		my @free;
		my %snake = map { ("$_->{x},$_->{y}", 1) } @{ $game->segments };
		for my $y (0 .. 7) {
			for my $x (0 .. 9) {
				push @free, [ $x, $y ] unless $snake{"$x,$y"};
			}
		}
		my $index = unpack('N', substr(Digest::SHA::sha256($seed . 'snake:food:0'), 0, 4)) % @free;
		is_deeply($game->food, $free[$index], "seed '$seed' puts the first food where the hash says");
	}
};

subtest 'the same seed is the same game twice' => sub {
	my @runs;
	for (1 .. 2) {
		my $game = Game::Snake->new(cols => 12, rows => 10, seed => 'twice');
		my @foods = ($game->food);
		my $steps = Game::Snake::Test::Steer->play($game, 'greedy', 400);
		push @foods, $game->food for grep { $_->{ate} } @$steps;
		push @runs, { foods => \@foods, score => $game->score, body => $game->segments, cause => $game->result ? $game->result->cause : 'running' };
	}
	is_deeply($runs[0], $runs[1], 'every placement and the whole snake agree');
	cmp_ok(scalar @{ $runs[0]{foods} }, '>', 3, 'and more than a few foods fell');
};

subtest 'food is never on the snake' => sub {
	my $game = Game::Snake->new(cols => 10, rows => 8, seed => 'clean');
	my $checked = 0;
	while ($game->status ne 'finished' && $checked < 300) {
		my $food = $game->food;
		for my $segment (@{ $game->segments }) {
			fail("food on the snake at $food->[0],$food->[1]")
				if $segment->{x} == $food->[0] && $segment->{y} == $food->[1];
		}
		is(scalar($game->free_cells) + $game->length, 10 * 8, 'free cells and the snake make the board')
			if $checked % 50 == 0;
		my $direction = Game::Snake::Test::Steer->greedy($game);
		$game->turn($direction) if $direction ne $game->heading;
		$game->tick;
		$checked++;
	}
	cmp_ok($checked, '>', 20, "$checked positions were checked");
};

subtest 'different seeds are different games' => sub {
	my %first;
	$first{ join ',', @{ Game::Snake->new(seed => "s$_")->food } }++ for 1 .. 20;
	cmp_ok(scalar keys %first, '>', 10, 'twenty seeds put the first food in more than ten places');
};

subtest 'the second placement, by hand' => sub {
	my ($game, $seed);
	for my $i (1 .. 5000) {
		$seed = "second$i";
		$game = Game::Snake->new(cols => 10, rows => 8, seed => $seed);
		my $food = $game->food;
		last if $food->[0] == 2 && $food->[1] == 5;
		$game = undef;
	}
	ok($game, "a seed ($seed) with the food just left of the head was found");
	my $step = $game->tick;
	is($step->{ate}, 1, 'and it is eaten on the first tick');
	my @free;
	my %snake = map { ("$_->{x},$_->{y}", 1) } @{ $game->segments };
	for my $y (0 .. 7) {
		for my $x (0 .. 9) {
			push @free, [ $x, $y ] unless $snake{"$x,$y"};
		}
	}
	my $index = unpack('N', substr(Digest::SHA::sha256($seed . 'snake:food:1'), 0, 4)) % @free;
	is_deeply($game->food, $free[$index], 'the second food is where the k=1 hash says');
	my $same = unpack('N', substr(Digest::SHA::sha256($seed . 'snake:food:0'), 0, 4)) % @free;
	isnt($index, $same, 'and that is not where the k=0 hash would have put it');
};

done_testing();
