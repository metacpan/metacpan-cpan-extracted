#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

use Game::Snake;
use Game::Snake::Bot;

# THE LADDER IS THE METHOD, NOT AN ERROR RATE. Three levels share one look at
# the board; the tests assert the ORDER of their results over seeded games,
# never the numbers (the numbers are measured in plan_update_snake/02), that
# no level ever walks into a death it could see, and that the same seed is
# steered the same way twice. A reference flood fill lives in this file so
# `room` is checked against a second implementation.

sub drive {
	my ($level, $seed, %opt) = @_;
	my $game = Game::Snake->new(cols => $opt{cols} || 16, rows => $opt{rows} || 12, seed => $seed);
	my @chosen;
	while ($game->status ne 'finished' && $game->ticks < ($opt{cap} || 4000)) {
		my $direction = Game::Snake::Bot->choose($game, level => $level);
		push @chosen, $direction;
		$game->turn($direction) if $direction ne $game->heading;
		$game->tick;
	}
	return ($game, \@chosen);
}

sub reference_room {
	my ($game, $direction) = @_;
	my %delta = (up => [0, -1], down => [0, 1], left => [-1, 0], right => [1, 0]);
	my ($head) = @{ $game->segments };
	my ($x, $y) = ($head->{x} + $delta{$direction}[0], $head->{y} + $delta{$direction}[1]);
	my %blocked;
	my $segments = $game->segments;
	for my $i (0 .. $#$segments) {
		next if $i == $#$segments && !$game->growing;
		$blocked{"$segments->[$i]{x},$segments->[$i]{y}"} = 1;
	}
	return 0 if $x < 0 || $y < 0 || $x >= $game->cols || $y >= $game->rows || $blocked{"$x,$y"};
	my %seen = ("$x,$y" => 1);
	my @queue = ([ $x, $y ]);
	while (my $cell = shift @queue) {
		for my $d (values %delta) {
			my ($nx, $ny) = ($cell->[0] + $d->[0], $cell->[1] + $d->[1]);
			next if $nx < 0 || $ny < 0 || $nx >= $game->cols || $ny >= $game->rows;
			next if $seen{"$nx,$ny"} || $blocked{"$nx,$ny"};
			$seen{"$nx,$ny"} = 1;
			push @queue, [ $nx, $ny ];
		}
	}
	return scalar keys %seen;
}

subtest 'the ladder' => sub {
	is_deeply([ Game::Snake::Bot->levels ], [ 1, 2 ], 'two levels');
	like(Game::Snake::Bot->describe(1), qr/greedy/, 'level 1 is greedy');
	like(Game::Snake::Bot->describe(2), qr/flood/, 'level 2 is flood-fill');
	like(Game::Snake::Bot->describe, qr/flood/, 'and the default is the top');
	my $bad = eval { Game::Snake::Bot->describe(3) };
	like($@, qr/a level is one of 1 2, not '3'/, 'a level off the ladder dies');
	$bad = eval { Game::Snake::Bot->choose(Game::Snake->new, level => 'x') };
	like($@, qr/not 'x'/, 'and so does a level that is not a number');
};

subtest 'each level does better than the one below' => sub {
	my %mean;
	for my $level (1 .. 2) {
		my $total = 0;
		for my $n (1 .. 20) {
			my ($game) = drive($level, "order$n");
			$total += $game->score;
		}
		$mean{$level} = $total / 20;
	}
	cmp_ok($mean{2}, '>', 1.5 * $mean{1}, "flood-fill ($mean{2}) beats greedy ($mean{1}) by half again");
};

subtest 'no level walks into a death it could see' => sub {
	my $checked = 0;
	for my $level (1 .. 2) {
		for my $n (1 .. 3) {
			my $game = Game::Snake->new(cols => 16, rows => 12, seed => "safe$level$n");
			while ($game->status ne 'finished' && $game->ticks < 2000) {
				my @safe = Game::Snake::Bot->safe($game);
				my $direction = Game::Snake::Bot->choose($game, level => $level);
				if (@safe) {
					fail("level $level chose $direction with only @safe safe")
						unless grep { $_ eq $direction } @safe;
					$checked++;
				}
				$game->turn($direction) if $direction ne $game->heading;
				my $step = $game->tick;
				fail("level $level died by $step->{died} with @safe safe")
					if $step->{died} && @safe && $step->{died} ne 'full';
			}
		}
	}
	cmp_ok($checked, '>', 500, "$checked choices were checked against the safe set");
};

subtest 'the same seed is steered the same way twice' => sub {
	for my $level (1 .. 2) {
		my (undef, $first) = drive($level, 'twice', cap => 1500);
		my (undef, $second) = drive($level, 'twice', cap => 1500);
		is_deeply($second, $first, "level $level, " . scalar(@$first) . ' choices');
	}
};

subtest 'choose on a finished game is undef' => sub {
	my $game = Game::Snake->new(cols => 10, rows => 8);
	$game->quit;
	is(Game::Snake::Bot->choose($game), undef, 'undef');
	is_deeply([ Game::Snake::Bot->safe($game) ], [], 'and nothing is safe');
};

subtest 'safe and room against a second implementation' => sub {
	my $compared = 0;
	my $game = Game::Snake->new(cols => 12, rows => 10, seed => 'room');
	while ($game->status ne 'finished' && $game->ticks < 400) {
		for my $direction (qw/ up down left right /) {
			is(Game::Snake::Bot->room($game, $direction), reference_room($game, $direction),
				"room $direction at tick " . $game->ticks)
				if $game->ticks % 40 == 0;
			$compared++;
		}
		my $direction = Game::Snake::Bot->choose($game, level => 2);
		$game->turn($direction) if $direction ne $game->heading;
		$game->tick;
	}
	cmp_ok($compared, '>', 100, "$compared rooms compared");
	my $bad = eval { Game::Snake::Bot->room($game, 'sideways') };
	like($@, qr/'sideways' is not a direction/, 'room refuses a word that is not a direction');
};

subtest 'the tail that is leaving is safe, the tail that stays is not' => sub {
	my ($game, $seed);
	for my $i (1 .. 5000) {
		$seed = "tail$i";
		$game = Game::Snake->new(cols => 10, rows => 8, start_length => 4, seed => $seed);
		my $food = $game->food;
		last unless grep { $food->[0] == $_->[0] && $food->[1] == $_->[1] } [ 3, 4 ], [ 4, 4 ], [ 4, 5 ];
		$game = undef;
	}
	ok($game, "a seed ($seed) with no food on the loop was found");
	$game->turn('up');
	$game->tick;
	$game->turn('right');
	$game->tick;
	ok((grep { $_ eq 'down' } Game::Snake::Bot->safe($game)), 'down onto a tail that is leaving is safe');
	cmp_ok(Game::Snake::Bot->room($game, 'down'), '>', 0, 'and has room behind it');

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
	$game->tick;
	is($game->growing, 1, 'growth is owed');
	ok(!(grep { $_ eq 'down' } Game::Snake::Bot->safe($game)), 'so down onto the staying tail is not safe');
	is(Game::Snake::Bot->room($game, 'down'), 0, 'and has no room');
};

subtest 'greedy closes on the food' => sub {
	my $closer = 0;
	my $game = Game::Snake->new(cols => 16, rows => 12, seed => 'close');
	for (1 .. 60) {
		last if $game->status eq 'finished';
		my ($head) = @{ $game->segments };
		my $food = $game->food;
		my $before = abs($food->[0] - $head->{x}) + abs($food->[1] - $head->{y});
		my $direction = Game::Snake::Bot->choose($game, level => 1);
		$game->turn($direction) if $direction ne $game->heading;
		my $step = $game->tick;
		last if $step->{ate};
		($head) = @{ $game->segments };
		my $after = abs($food->[0] - $head->{x}) + abs($food->[1] - $head->{y});
		$closer++ if $after < $before;
	}
	cmp_ok($closer, '>=', 3, "greedy got closer on $closer of its first ticks");
};

sub reference_safe {
	my ($game) = @_;
	my %delta = (up => [0, -1], down => [0, 1], left => [-1, 0], right => [1, 0]);
	my %sides = (up => [qw/left right/], down => [qw/left right/], left => [qw/up down/], right => [qw/up down/]);
	my ($head) = @{ $game->segments };
	my $heading = $game->heading;
	my @safe;
	for my $direction ($heading, @{ $sides{$heading} }) {
		my ($x, $y) = ($head->{x} + $delta{$direction}[0], $head->{y} + $delta{$direction}[1]);
		next if $x < 0 || $y < 0 || $x >= $game->cols || $y >= $game->rows;
		my $what = $game->at($x, $y);
		next if defined $what && $what ne 'food' && !($what eq 'tail' && !$game->growing);
		push @safe, $direction;
	}
	return \@safe;
}

subtest 'safe against a second implementation, every tick of a game' => sub {
	my $compared = 0;
	for my $seed (qw/ edge1 edge2 /) {
		my $game = Game::Snake->new(cols => 12, rows => 8, seed => $seed);
		while ($game->status ne 'finished' && $game->ticks < 1500) {
			my $ours = [ Game::Snake::Bot->safe($game) ];
			my $theirs = reference_safe($game);
			is_deeply($ours, $theirs, "safe set at tick " . $game->ticks . " of $seed") or last
				unless "@$ours" eq "@$theirs";
			$compared++;
			my $direction = Game::Snake::Bot->choose($game, level => 2);
			$game->turn($direction) if $direction ne $game->heading;
			$game->tick;
		}
	}
	cmp_ok($compared, '>', 300, "$compared safe sets agreed");
};

subtest 'greedy takes the straight road to the food' => sub {
	for my $n (1 .. 6) {
		my $game = Game::Snake->new(cols => 16, rows => 12, seed => "road$n");
		my ($head) = @{ $game->segments };
		my $food = $game->food;
		my $distance = abs($food->[0] - $head->{x}) + abs($food->[1] - $head->{y});
		my $ticks = 0;
		my $ate = 0;
		while ($ticks < $distance + 2) {
			my $direction = Game::Snake::Bot->choose($game, level => 1);
			$game->turn($direction) if $direction ne $game->heading;
			$ticks++;
			if ($game->tick->{ate}) { $ate = 1; last }
		}
		ok($ate, "road$n: the food $distance away was eaten within $ticks ticks");
	}
};

subtest 'straight on wins a tie' => sub {
	my $found = 0;
	for my $i (1 .. 20000) {
		my $game = Game::Snake->new(cols => 10, rows => 8, seed => "tie$i");
		my $food = $game->food;
		next unless $food->[0] == 2 && ($food->[1] == 4 || $food->[1] == 6);
		$found++;
		is(Game::Snake::Bot->choose($game, level => 1), 'left',
			"tie$i: left and a side are both one step from the food, so straight on");
		last if $found == 6;
	}
	is($found, 6, 'six such seeds were found');
};

done_testing();
