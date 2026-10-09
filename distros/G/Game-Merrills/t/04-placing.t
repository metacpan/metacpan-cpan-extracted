#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Merrills::Board;
use Game::Merrills::Move;
use Game::Merrills::Points;
use Game::Merrills::Rules;

sub p { return Game::Merrills::Points::point($_[0]) }

sub dies(&) {
	my ($code) = @_;
	return eval { $code->(); 1 } ? '' : ($@ || 'died');
}

sub opening {
	return Game::Merrills::Rules::position(Game::Merrills::Board->new);
}

sub written {
	my ($moves) = @_;
	return [ map { Game::Merrills::Move->from_raw($_)->notation } @{$moves} ];
}

my $seed = 20261008;
sub pick {
	my ($count) = @_;
	$seed = ($seed * 1103515245 + 12345) % 2147483648;
	return int($seed / 65536) % $count;
}

sub played {
	my ($plies) = @_;
	my $position = opening();
	my $side = 'white';
	for (1 .. $plies) {
		my $moves = Game::Merrills::Rules::generate($position, $side);
		Game::Merrills::Rules::apply($position, $side, $moves->[ pick(scalar @{$moves}) ]);
		$side = $side eq 'white' ? 'black' : 'white';
	}
	return ($position, $side);
}

subtest 'a position is the board and the two hands' => sub {
	my $board = Game::Merrills::Board->new(hand => { white => 7, black => 8 });
	$board->set(p('d2'), 'white');
	$board->set(p('f4'), 'black');
	my $position = Game::Merrills::Rules::position($board);

	is(scalar @{$position}, 26, 'twenty-six values');
	is_deeply([ @{$position}[ 0 .. 23 ] ], $board->cells, 'the cells first');
	is($position->[Game::Merrills::Rules::HAND_WHITE], 7, "then white's hand");
	is($position->[Game::Merrills::Rules::HAND_BLACK], 8, "then black's");
	isnt(Game::Merrills::Rules::HAND_WHITE, Game::Merrills::Rules::HAND_BLACK,
		'in two different places');

	$position->[0] = 1;
	ok($board->empty(0), 'a position shares nothing with its board');

	my $back = Game::Merrills::Rules::board(Game::Merrills::Rules::position($board));
	is_deeply($back->cells, $board->cells, 'and a board comes back out');
	is_deeply($back->hand, $board->hand, 'hands and all');
};

subtest 'the raw move indexes are the ones Move uses' => sub {
	for my $name (qw/RM_FROM RM_TO RM_REMOVE RM_CLOSES RM_FLEW/) {
		is(Game::Merrills::Rules->can($name)->(), Game::Merrills::Move->can($name)->(), $name);
	}
};

subtest 'twenty-four opening moves, one a point' => sub {
	my $moves = Game::Merrills::Rules::generate(opening(), 'white');
	is(scalar @{$moves}, 24, 'twenty-four');
	is_deeply(
		written($moves),
		[ map { Game::Merrills::Points::name($_) } Game::Merrills::Points::all_points() ],
		'every point, in point order'
	);
	is_deeply($moves->[0], [ undef, 0, undef, 0, 0 ],
		'a placement leaves nowhere, takes nothing, closes nothing and does not fly');
	is_deeply(written(Game::Merrills::Rules::generate(opening(), 'black')), written($moves),
		'and black, asked, would have the same');
};

subtest 'generate hands out a fresh list each time' => sub {
	my $position = opening();
	my $one = Game::Merrills::Rules::generate($position, 'white');
	my $two = Game::Merrills::Rules::generate($position, 'white');
	isnt($one, $two, 'the list');
	isnt($one->[0], $two->[0], 'and each move in it');
	is_deeply($position, opening(), 'and leaves the position alone');
};

subtest 'an occupied point is never offered' => sub {
	my ($position, $side) = played(11);
	my $moves = Game::Merrills::Rules::generate($position, $side);
	my @onto = map { $_->[Game::Merrills::Rules::RM_TO] } @{$moves};
	is(scalar(grep { $position->[$_] != 0 } @onto), 0, 'no move lands on a man');
	my %onto = map { $_ => 1 } @onto;
	is_deeply(
		[ sort { $a <=> $b } keys %onto ],
		[ grep { $position->[$_] == 0 } 0 .. 23 ],
		'and every empty point is offered'
	);
};

subtest 'placing takes a man from the hand and puts it on the point' => sub {
	my $position = opening();
	my $move = [ undef, p('d2'), undef, 0, 0 ];
	is(Game::Merrills::Rules::apply($position, 'white', $move), $position,
		'apply returns the position');
	is($position->[ p('d2') ], 1, 'a white man on d2');
	is($position->[Game::Merrills::Rules::HAND_WHITE], 8, 'eight left in hand');
	is($position->[Game::Merrills::Rules::HAND_BLACK], 9, "black's hand untouched");
	is(scalar(grep { $_ != 0 } @{$position}[ 0 .. 23 ]), 1, 'and nothing else moved');

	Game::Merrills::Rules::apply($position, 'black', [ undef, p('f4'), undef, 0, 0 ]);
	is($position->[ p('f4') ], -1, 'a black man on f4');
	is($position->[Game::Merrills::Rules::HAND_BLACK], 8, 'from the black hand');
	is($position->[Game::Merrills::Rules::HAND_WHITE], 8, 'and not the white one');

	is(Game::Merrills::Rules::unapply($position, 'black', [ undef, p('f4'), undef, 0, 0 ]),
		$position, 'unapply returns the position');
	Game::Merrills::Rules::unapply($position, 'white', $move);
	is_deeply($position, opening(), 'and two unapplies are the opening again');
};

subtest 'a man that leaves a point is taken off it, and put back' => sub {
	my $board = Game::Merrills::Board->new(hand => { white => 0, black => 0 });
	$board->set(p($_), 'white') for qw/d2 a7/;
	$board->set(p($_), 'black') for qw/f4 g1/;
	my $position = Game::Merrills::Rules::position($board);
	my $before = [ @{$position} ];

	my $quiet = [ p('d2'), p('d3'), undef, 0, 0 ];
	Game::Merrills::Rules::apply($position, 'white', $quiet);
	is($position->[ p('d2') ], 0, 'd2 is empty');
	is($position->[ p('d3') ], 1, 'the man is on d3');
	is($position->[Game::Merrills::Rules::HAND_WHITE], 0, 'and the hand paid nothing');
	is(scalar(grep { $position->[$_] != $before->[$_] } 0 .. 25), 2, 'two cells changed');
	Game::Merrills::Rules::unapply($position, 'white', $quiet);
	is_deeply($position, $before, 'taken back, the man is on d2 again');

	my $taking = [ p('f4'), p('g4'), p('a7'), 1, 0 ];
	Game::Merrills::Rules::apply($position, 'black', $taking);
	is($position->[ p('f4') ], 0, 'black leaves f4');
	is($position->[ p('g4') ], -1, 'lands on g4');
	is($position->[ p('a7') ], 0, 'and the white man on a7 is gone');
	is(scalar(grep { $position->[$_] != $before->[$_] } 0 .. 25), 3, 'three cells changed');
	Game::Merrills::Rules::unapply($position, 'black', $taking);
	is_deeply($position, $before, 'taken back, all three are as they were');
};

subtest 'the first three plies count 24, 552 and 12,144' => sub {
	my $position = opening();
	my ($two, $three) = (0, 0);
	my $first = Game::Merrills::Rules::generate($position, 'white');
	for my $white (@{$first}) {
		Game::Merrills::Rules::apply($position, 'white', $white);
		my $second = Game::Merrills::Rules::generate($position, 'black');
		$two += @{$second};
		for my $black (@{$second}) {
			Game::Merrills::Rules::apply($position, 'black', $black);
			$three += @{ Game::Merrills::Rules::generate($position, 'white') };
			Game::Merrills::Rules::unapply($position, 'black', $black);
		}
		Game::Merrills::Rules::unapply($position, 'white', $white);
	}
	is(scalar @{$first}, 24, 'ply 1');
	is($two, 552, 'ply 2');
	is($three, 12144, 'ply 3');
	is_deeply($position, opening(), 'and the walk left the opening as it found it');
};

subtest 'the list is in order: point landed on, then the man taken' => sub {
	my $checked = 0;
	my $closing = 0;
	for my $game (1 .. 60) {
		my ($position, $side) = played(4 + ($game % 14));
		my $moves = Game::Merrills::Rules::generate($position, $side);
		my @keys = map {
			sprintf '%02d %02d', $_->[1], defined $_->[2] ? $_->[2] : -1
		} @{$moves};
		$closing += grep { defined $_->[2] } @{$moves};
		next if join('|', @keys) eq join('|', sort @keys);
		fail('game ' . $game . ' is out of order: ' . join ' ', @{ written($moves) });
		return;
	}
	continue { $checked++ }
	is($checked, 60, 'sixty positions, all in order');
	cmp_ok($closing, '>', 20, "and $closing of the moves seen took a man, so the second key was tested");
};

subtest 'apply and unapply are each other backwards, over 200 positions' => sub {
	my ($positions, $moves_seen, $captures, $wrong) = (0, 0, 0, 0);
	my %conserved;
	for my $game (0 .. 199) {
		my ($position, $side) = played($game % 18);
		my $value = $side eq 'white' ? 1 : -1;
		my $hand = $side eq 'white'
			? Game::Merrills::Rules::HAND_WHITE : Game::Merrills::Rules::HAND_BLACK;
		my $before = [ @{$position} ];
		$positions++;

		for my $move (@{ Game::Merrills::Rules::generate($position, $side) }) {
			my ($from, $to, $remove) = @{$move};
			$moves_seen++;
			$captures++ if defined $remove;
			Game::Merrills::Rules::apply($position, $side, $move);

			my $changed = grep { $position->[$_] != $before->[$_] } 0 .. 25;
			$wrong++ unless $position->[$to] == $value
				&& $position->[$hand] == $before->[$hand] - 1
				&& $changed == (defined $remove ? 3 : 2)
				&& (!defined $remove
					|| ($before->[$remove] == -$value && $position->[$remove] == 0));

			Game::Merrills::Rules::unapply($position, $side, $move);
			$wrong++ unless join(',', @{$position}) eq join(',', @{$before});
		}
	}
	is($positions, 200, 'two hundred positions');
	cmp_ok($moves_seen, '>', 2000, "$moves_seen moves applied and taken back");
	cmp_ok($captures, '>', 50, "$captures of them took a man");
	is($wrong, 0, 'and not one left a mark');
};

subtest 'a side with every man placed moves a man instead' => sub {
	my $board = Game::Merrills::Board->new(hand => { white => 0, black => 1 });
	$board->set(p($_), 'white') for qw/a1 d5 e3 g7/;
	my $position = Game::Merrills::Rules::position($board);
	my $moves = Game::Merrills::Rules::generate($position, 'white');
	is(scalar(grep { !defined $_->[Game::Merrills::Rules::RM_FROM] } @{$moves}), 0,
		'white, with none in hand, places nothing');
	cmp_ok(scalar @{$moves}, '>', 0, 'and has moves all the same');
	is(scalar @{ Game::Merrills::Rules::generate($position, 'black') }, 20,
		'black, with one, still places');
};

subtest 'a side or a position that is not one dies' => sub {
	my $position = opening();
	for my $function (qw/generate removable/) {
		like(dies { Game::Merrills::Rules->can($function)->($position, 'red') },
			qr/^side must be white or black, got 'red'/, "$function, a red side");
		like(dies { Game::Merrills::Rules->can($function)->($position, undef) },
			qr/^side must be white or black, got undef/, "$function, no side");
		like(dies { Game::Merrills::Rules->can($function)->([ (0) x 24 ], 'white') },
			qr/^a position is an arrayref of 26 values/, "$function, a bare board");
		like(dies { Game::Merrills::Rules->can($function)->(undef, 'white') },
			qr/^a position is an arrayref of 26 values/, "$function, no position");
	}
	like(dies { Game::Merrills::Rules::closes($position, 'red', undef, 0) },
		qr/^side must be white or black/, 'closes, a red side');
	like(dies { Game::Merrills::Rules::closes([], 'white', undef, 0) },
		qr/^a position is an arrayref of 26 values/, 'closes, no position');
	like(dies { Game::Merrills::Rules::closes($position, 'white', undef, 24) },
		qr/^point must be 0 \.\. 23/, 'closes, a point off the board');
	like(dies { Game::Merrills::Rules::closes($position, 'white', 24, 0) },
		qr/^point must be 0 \.\. 23/, 'closes, from a point off the board');
	like(dies { Game::Merrills::Rules::apply($position, 'red', [ undef, 0 ]) },
		qr/^side must be white or black/, 'apply, a red side');
	like(dies { Game::Merrills::Rules::unapply($position, 'red', [ undef, 0 ]) },
		qr/^side must be white or black/, 'unapply, a red side');
	like(dies { Game::Merrills::Rules::board([ (0) x 24 ]) },
		qr/^a position is an arrayref of 26 values/, 'board, a bare board');
	is_deeply($position, opening(), 'and nothing was touched');
};

done_testing;
