#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

use Game::Snake;
use Game::Snake::Test::Steer;

# THE RULES OF 0.11, COUNTED. A run to the wall takes exactly the head's
# distance plus the fatal tick. The tail leaves its cell before the head
# arrives, so a snake may follow its own tail but not cross its body. Growth
# lands the tick after the meal. The speed rises at 20, 40, 80, each time
# the score doubles what it was at the last rise. A board with no free cell
# ends the game as full.

subtest 'a straight run into the wall' => sub {
	my $game = Game::Snake->new;
	my $head_x = $game->segments->[0]{x};
	my @steps;
	while ($game->status ne 'finished' && @steps < 100) {
		push @steps, $game->tick;
	}
	is(scalar @steps, $head_x + 1, 'the head crossed every cell to the edge, then one more');
	is($steps[-1]{died}, 'wall', 'and died at the wall');
	is($steps[-1]{moved}, 0, 'without moving');
	is($game->segments->[0]{x}, 0, 'the head is on the edge');
	is($game->status, 'finished', 'the game is finished');
	is($game->ticks, $head_x + 1, 'ticks count the fatal tick too');
	is($game->result->cause, 'wall', 'and the result says wall');
	is_deeply($game->tick, { moved => 0 }, 'a tick on a finished game moves nothing');
	ok(!grep({ $_->{died} } @steps[0 .. $#steps - 1]), 'no step before the last died');
};

subtest 'a snake that crosses its own body dies' => sub {
	my $game = Game::Snake->new(cols => 10, rows => 8, start_length => 5);
	$game->turn('up');
	my $one = $game->tick;
	$game->turn('right');
	my $two = $game->tick;
	$game->turn('down');
	my $three = $game->tick;
	is($one->{died}, undef, 'up was fine');
	is($two->{died}, undef, 'right was fine');
	is($three->{died}, 'body', 'down ran into the body');
	is($game->result->cause, 'body', 'and the result says body');
};

subtest 'a snake may follow its own tail' => sub {
	my ($game, $seed);
	for my $i (1 .. 200) {
		$seed = "chase$i";
		$game = Game::Snake->new(cols => 10, rows => 8, start_length => 4, seed => $seed);
		my $food = $game->food;
		last unless grep { $food->[0] == $_->[0] && $food->[1] == $_->[1] }
			[ 3, 4 ], [ 4, 4 ], [ 4, 5 ];
		$game = undef;
	}
	ok($game, "a seed ($seed) with no food on the loop was found");
	$game->turn('up');
	$game->tick;
	$game->turn('right');
	$game->tick;
	$game->turn('down');
	my $step = $game->tick;
	is($step->{died}, undef, 'the head took the cell the tail was leaving');
	is($step->{moved}, 1, 'and moved');
	is_deeply([ $game->segments->[0]{x}, $game->segments->[0]{y} ], [ 4, 5 ], 'onto (4,5)');
};

subtest 'growth lands the tick after the meal' => sub {
	my ($game, $seed);
	for my $i (1 .. 5000) {
		$seed = "meal$i";
		$game = Game::Snake->new(cols => 10, rows => 8, seed => $seed);
		my $food = $game->food;
		last if $food->[0] == 2 && $food->[1] == 5;
		$game = undef;
	}
	ok($game, "a seed ($seed) with the food just left of the head was found");
	my $one = $game->tick;
	is($one->{ate}, 1, 'the first tick eats');
	is($one->{grew}, 0, 'but does not grow');
	is($game->length, 3, 'still three long');
	is($game->score, 10, 'and ten points');
	ok($game->food, 'new food is on the board');
	isnt($game->at(2, 5), 'food', 'and not where the old was');
	my $two = $game->tick;
	is($two->{ate}, 0, 'the second tick eats nothing');
	is($two->{grew}, 1, 'and grows');
	is($game->length, 4, 'four long');
};

subtest 'the speed rises as the score doubles' => sub {
	my $game = Game::Snake->new(cols => 14, rows => 12, seed => 'rise');
	my @at;
	my $meals = 0;
	while ($game->status ne 'finished' && $meals < 9) {
		my $direction = Game::Snake::Test::Steer->greedy($game);
		$game->turn($direction) if $direction ne $game->heading;
		my $step = $game->tick;
		if ($step->{ate}) {
			$meals++;
			push @at, [ $game->score, $game->speed ];
		}
	}
	is($meals, 9, 'nine meals were eaten (the greedy steer stayed alive)') or diag explain $game->result;
	is_deeply(\@at, [
		[ 10, 2 ], [ 20, 3 ], [ 30, 3 ], [ 40, 4 ], [ 50, 4 ],
		[ 60, 4 ], [ 70, 4 ], [ 80, 5 ], [ 90, 5 ],
	], 'speed 3 at 20, 4 at 40, 5 at 80');
};

subtest 'a full board ends the game' => sub {
	my $game = Game::Snake->new(cols => 6, rows => 6, seed => 'full');
	my $steps = Game::Snake::Test::Steer->play($game, 'cycle6', 2000);
	is($game->status, 'finished', 'the game finished');
	is($game->result->cause, 'full', 'as full');
	is($game->length, 36, 'with the snake on every cell');
	is($game->score, 34 * 10, 'after thirty-four meals: the last is eaten with growth already pending');
	is($game->food, undef, 'and no food anywhere');
	is($steps->[-1]{died}, 'full', 'the last step says full');
	is($steps->[-1]{ate}, 1, 'and it was the meal that filled the board');
	is(scalar($game->free_cells), 0, 'no free cell');
};

subtest 'every wall, counted' => sub {
	for my $case (
		[ 'left',  [],                 3, [ 0, 5 ] ],
		[ 'up',    [ 'up' ],          5, [ 3, 0 ] ],
		[ 'down',  [ 'down' ],        2, [ 3, 7 ] ],
		[ 'right', [ 'up', 'right' ], 7, [ 9, 4 ] ],
	) {
		my ($wall, $turns, $moves, $edge) = @$case;
		my $game = Game::Snake->new(cols => 10, rows => 8, seed => "wall-$wall");
		my $ticks = 0;
		for my $turn (@$turns) {
			$game->turn($turn);
			if ($turn ne $turns->[-1]) { $game->tick; $ticks++ }
		}
		while ($game->status ne 'finished' && $ticks < 50) { $game->tick; $ticks++ }
		is($game->result->cause, 'wall', "the $wall wall kills");
		is($ticks, $moves + 1, "after $moves moves and the fatal tick");
		is_deeply([ $game->segments->[0]{x}, $game->segments->[0]{y} ], $edge, 'with the head on the edge');
	}
};

subtest 'a tail that is staying put cannot be followed' => sub {
	my ($game, $seed);
	for my $i (1 .. 5000) {
		$seed = "stay$i";
		$game = Game::Snake->new(cols => 10, rows => 8, start_length => 4, seed => $seed);
		my $food = $game->food;
		last if $food->[0] == 4 && $food->[1] == 4;
		$game = undef;
	}
	ok($game, "a seed ($seed) with the food at (4,4) was found");
	$game->turn('up');
	$game->tick;
	$game->turn('right');
	my $meal = $game->tick;
	is($meal->{ate}, 1, 'the second tick eats, so growth is pending');
	$game->turn('down');
	my $step = $game->tick;
	is($step->{died}, 'body', 'and the tail, which is not leaving, kills');
};

subtest 'the bends of a snake turned twice' => sub {
	my $game = Game::Snake->new(cols => 10, rows => 8, start_length => 5, seed => 'bends');
	$game->turn('up');
	$game->tick;
	is_deeply([ map { $_->{bend} } @{ $game->segments } ], [ 0, 'up', 0, 0, 0 ],
		'after one turn the segment behind the head bends up');
	$game->turn('right');
	$game->tick;
	is_deeply($game->segments, [
		{ x => 4, y => 4, dir => 'right', bend => 0,       last => 0 },
		{ x => 3, y => 4, dir => 'up',    bend => 'right', last => 0 },
		{ x => 3, y => 5, dir => 'left',  bend => 'up',    last => 0 },
		{ x => 4, y => 5, dir => 'left',  bend => 0,       last => 0 },
		{ x => 5, y => 5, dir => 'left',  bend => 0,       last => 1 },
	], 'after two, each bend is the heading of the segment in front');
};

done_testing();
