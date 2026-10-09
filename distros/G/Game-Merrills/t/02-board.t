#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Merrills::Board;
use Game::Merrills::Points;

sub p { return Game::Merrills::Points::point($_[0]) }

sub board_with {
	my (%men) = @_;
	my $board = Game::Merrills::Board->new(hand => { white => 0, black => 0 });
	for my $side (keys %men) {
		$board->set(p($_), $side) for @{ $men{$side} };
	}
	return $board;
}

sub dies(&) {
	my ($code) = @_;
	return eval { $code->(); 1 } ? '' : ($@ || 'died');
}

subtest 'a new board is empty, with nine men a side in hand' => sub {
	my $board = Game::Merrills::Board->new;
	is(scalar @{ $board->cells }, 24, 'twenty-four cells');
	is(scalar(grep { $_ != 0 } @{ $board->cells }), 0, 'all empty');
	for my $side (qw/white black/) {
		is($board->in_hand($side), 9, "$side holds nine");
		is($board->count($side), 0, "$side has none down");
		is($board->men($side), 9, "$side has nine men");
		is_deeply([ $board->points_of($side) ], [], "$side stands nowhere");
	}
	ok($board->empty($_), Game::Merrills::Points::name($_) . ' is empty')
		for Game::Merrills::Points::all_points();
};

subtest 'two new boards share nothing' => sub {
	my $one = Game::Merrills::Board->new;
	my $two = Game::Merrills::Board->new;
	$one->set(p('a1'), 'white');
	$one->hand->{white} = 8;
	ok($two->empty(p('a1')), 'the cells');
	is($two->in_hand('white'), 9, 'the hands');
	isnt(Game::Merrills::Board->opening, Game::Merrills::Board->opening,
		'opening hands out a fresh arrayref');
};

subtest 'setting and reading a point' => sub {
	my $board = Game::Merrills::Board->new;
	is($board->set(p('d2'), 'white'), $board, 'set returns the board');
	$board->set(p('f4'), 'black');

	is($board->at(p('d2')), Game::Merrills::Board::WHITE, 'a white man is WHITE');
	is($board->at(p('f4')), Game::Merrills::Board::BLACK, 'a black man is BLACK');
	is($board->at(p('a1')), Game::Merrills::Board::EMPTY, 'no man is EMPTY');
	is($board->side_at(p('d2')), 'white', 'side_at names white');
	is($board->side_at(p('f4')), 'black', 'side_at names black');
	is($board->side_at(p('a1')), undef, 'and nobody');
	ok(!$board->empty(p('d2')), 'a held point is not empty');

	is_deeply([ $board->points_of('white') ], [ p('d2') ], 'points_of white');
	is_deeply([ $board->points_of('black') ], [ p('f4') ], 'points_of black');
	is($board->count('white'), 1, 'count white');
	is($board->in_hand('white'), 9, 'setting a point leaves the hand alone');
	is($board->men('white'), 10, 'so men counts what it is told');

	$board->set(p('d2'), undef);
	ok($board->empty(p('d2')), 'setting undef clears the point');
	is($board->count('white'), 0, 'and the count follows');
};

subtest 'points_of is in point order' => sub {
	my $board = board_with(white => [qw/g1 a7 d5 b2/]);
	is_deeply(
		[ map { Game::Merrills::Points::name($_) } $board->points_of('white') ],
		[qw/a7 d5 b2 g1/],
		'top to bottom, left to right'
	);
};

subtest 'men is the board and the hand together' => sub {
	my $board = Game::Merrills::Board->new(hand => { white => 5, black => 0 });
	$board->set(p('a1'), 'white');
	is($board->men('white'), 6, 'one down and five in hand is six');
	is($board->men('black'), 0, 'none anywhere is none');
};

subtest 'every mill is seen, and only when it is whole' => sub {
	for my $mill (Game::Merrills::Points::mills()) {
		my @names = map { Game::Merrills::Points::name($_) } @{$mill};
		my $board = board_with(black => \@names);
		is(scalar(grep { $board->in_mill($_) } @{$mill}), 3, "@names: all three");

		for my $gap (0 .. 2) {
			my $short = board_with(black => [ @names[ grep { $_ != $gap } 0 .. 2 ] ]);
			is(scalar(grep { $short->in_mill($_) } @{$mill}), 0,
				"@names without $names[$gap]: none");
			$short->set($mill->[$gap], 'white');
			is(scalar(grep { $short->in_mill($_) } @{$mill}), 0,
				"@names with a white man on $names[$gap]: none");
		}
	}
};

subtest 'a mill is not three in a row across the centre' => sub {
	my $board = board_with(white => [qw/b4 c4 e4/]);
	is(scalar(grep { $board->in_mill(p($_)) } qw/b4 c4 e4/), 0, 'b4 c4 e4');
	my $down = board_with(white => [qw/d6 d5 d3/]);
	is(scalar(grep { $down->in_mill(p($_)) } qw/d6 d5 d3/), 0, 'd6 d5 d3');
};

subtest 'in_mill is about the man asked after' => sub {
	my $board = board_with(white => [qw/a7 d7 g7 g4/], black => [qw/a1/]);
	ok($board->in_mill(p('g7')), 'g7 is in the top row');
	ok(!$board->in_mill(p('g4')), 'g4 is beside it and in nothing');
	ok(!$board->in_mill(p('a1')), 'a lone black man is in nothing');
	ok(!$board->in_mill(p('d1')), 'an empty point is in nothing');

	$board->set(p('g1'), 'white');
	ok($board->in_mill(p('g4')), 'g4 is, once g1 fills the file');
	ok($board->in_mill(p('g7')), 'and g7 is in two at once');
};

subtest 'a clone shares nothing' => sub {
	my $board = board_with(white => [qw/a1 d1/], black => [qw/g7/]);
	$board->hand->{white} = 3;
	my $copy = $board->clone;
	is_deeply($copy->cells, $board->cells, 'the same men');
	is_deeply($copy->hand, $board->hand, 'the same hands');
	$copy->set(p('g1'), 'white');
	$copy->hand->{white} = 2;
	ok($board->empty(p('g1')), 'a man set on the copy is not on the original');
	is($board->in_hand('white'), 3, 'nor is the hand');
	isa_ok($copy, 'Game::Merrills::Board');
};

subtest 'what could not be a position is refused' => sub {
	like(dies { Game::Merrills::Board->new(cells => [ (0) x 23 ]) },
		qr/^cells must be an arrayref of 24 values/, 'twenty-three cells');
	like(dies { Game::Merrills::Board->new(cells => [ (0) x 23, 2 ]) },
		qr/^cell g1 must be -1, 0 or 1, got '2'/, 'a cell that is no man');
	like(dies { Game::Merrills::Board->new(cells => [ (0) x 23, undef ]) },
		qr/^cell g1 must be -1, 0 or 1, got undef/, 'an undefined cell');
	like(dies { Game::Merrills::Board->new(hand => { white => 10, black => 9 }) },
		qr/^hand of white must be 0 \.\. 9, got '10'/, 'ten in hand');
	like(dies { Game::Merrills::Board->new(hand => { white => 9 }) },
		qr/^hand of black must be 0 \.\. 9, got undef/, 'a hand with one side');
	like(dies { Game::Merrills::Board->new(hand => { white => 9, black => 9, red => 1 }) },
		qr/^hand must hold white and black and nothing else/, 'a third side');
	like(
		dies {
			Game::Merrills::Board->new(
				cells => [ 1, (0) x 23 ],
				hand => { white => 9, black => 9 }
			)
		},
		qr/^white has more than nine men/, 'ten white men in all'
	);
	is(
		dies {
			Game::Merrills::Board->new(
				cells => [ 1, -1, (0) x 22 ],
				hand => { white => 8, black => 8 }
			)
		},
		'', 'nine in all is fine'
	);
};

subtest 'a side or a point that is not one dies' => sub {
	my $board = Game::Merrills::Board->new;
	for my $method (qw/points_of count in_hand men/) {
		like(dies { $board->$method('red') },
			qr/^side must be white or black, got 'red'/, "$method('red')");
		like(dies { $board->$method(undef) },
			qr/^side must be white or black, got undef/, "$method(undef)");
	}
	like(dies { $board->set(0, 'red') }, qr/^side must be white or black/, 'set a red man');
	for my $method (qw/at side_at empty in_mill/) {
		like(dies { $board->$method(24) }, qr/^point must be 0 \.\. 23/, "$method(24)");
	}
	like(dies { $board->set(24, 'white') }, qr/^point must be 0 \.\. 23/, 'set(24)');
	is_deeply($board->cells, Game::Merrills::Board->opening, 'and nothing was set');
};

done_testing;
