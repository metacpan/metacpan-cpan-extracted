#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Merrills;
use Game::Merrills::Rules;
use Game::Merrills::Points;
use Game::Merrills::Test::Position qw/p names position_of stream/;

sub written { return [ map { $_->notation } @{ $_[0] } ] }

subtest 'once every man is placed, a turn moves one along a line' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d6 c3 g1/], black => [qw/d7 b4 e4 a1/],
	));
	is($game->phase, 'moving', 'white is moving');
	is($game->phase_of('black'), 'moving', 'and so is black');
	is_deeply(
		written($game->legal_moves),
		[qw/d6-b6 d6-f6 d6-d5 a7-a4 c3-c4 g1-g4 c3-d3 g1-d1/],
		'each man to each empty neighbour, in order of the point landed on'
	);
	is(scalar(grep { $_->flew } @{ $game->legal_moves }), 0, 'and nobody flew');
	is(scalar(grep { $_->is_placement } @{ $game->legal_moves }), 0, 'nor placed a man');
	is_deeply(written($game->legal_moves_for(p('d6'))), [qw/d6-b6 d6-f6 d6-d5/],
		'legal_moves_for picks out one man');
	is_deeply(written($game->legal_moves_for(p('b6'))), [], 'and an empty point has none');

	my $move = $game->move('d6-d5');
	isa_ok($move, 'Game::Merrills::Move');
	is($move->side, 'white', 'the move knows who made it');
	is($game->turn, 'black', 'and the turn passes');
	is($game->board->side_at(p('d5')), 'white', 'the man is on d5');
	ok($game->board->empty(p('d6')), 'and d6 is empty');
	is($game->on_board('white'), 4, 'still four white men');
};

subtest 'a man may not pass over another, nor cross the centre' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 c4 b2 f6/], black => [qw/d7 e4 g1 d3/],
	));
	my %legal = map { $_ => 1 } @{ written($game->legal_moves) };
	ok(!$legal{'a7-g7'}, 'a7 cannot hop d7 to g7');
	ok(!$legal{'a7-d7'}, 'nor land on it');
	ok(!$legal{'c4-e4'}, 'c4 and e4 face each other across the centre and are not neighbours');
	ok($legal{'a7-a4'}, 'a7 can step down to a4');
	is($game->move('a7-g7')->code, 'not_adjacent', 'and the game says why not');
};

subtest 'the list is what an independent walk of the lines gives, over 300 positions' => sub {
	my $next = stream(307);
	my ($positions, $moves_seen, $wrong, $unsorted, $disagree) = (0, 0, 0, 0, 0);
	my $tries = 0;
	while ($positions < 300 && $tries++ < 3000) {
		my $game = Game::Merrills->new(flying => 0);
		my $stop = 18 + $next->(30);
		while ($game->status eq 'active' && $game->ply < $stop) {
			my $legal = $game->legal_moves;
			$game->move($legal->[ $next->(scalar @{$legal}) ]);
		}
		next unless $game->status eq 'active';
		$positions++;

		my $board = $game->board;
		my %want;
		for my $from ($board->points_of($game->turn)) {
			for my $to (Game::Merrills::Points::adjacent($from)) {
				$want{"$from,$to"} = 1 if $board->empty($to);
			}
		}
		my %have;
		my @keys;
		for my $move (@{ $game->legal_moves }) {
			$moves_seen++;
			$have{ $move->from . ',' . $move->to } = 1;
			push @keys, sprintf '%02d %02d %02d', $move->to, $move->from,
				defined $move->remove ? $move->remove : -1;
		}
		$wrong++ unless join('|', sort keys %have) eq join('|', sort keys %want);
		$unsorted++ unless join('|', @keys) eq join('|', sort @keys);
		my $position = Game::Merrills::Rules::position($board);
		$disagree++ unless !!Game::Merrills::Rules::has_move($position, $game->turn, 0)
			eq !!@{ $game->legal_moves };
	}
	is($positions, 300, 'three hundred positions found');
	cmp_ok($moves_seen, '>', 2000, "$moves_seen moves looked at");
	is($wrong, 0, 'every position offers exactly the steps along its lines');
	is($unsorted, 0, 'in order: point landed on, point left, man taken');
	is($disagree, 0, 'and has_move is true exactly when the list is not empty');
};

subtest 'a move that closes a mill takes a man, and is not offered without one' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 g4 c3/], black => [qw/a1 d1 b4 e5/],
	));
	my @closing = grep { $_->to == p('g7') && $_->from == p('g4') }
		@{ $game->legal_moves };
	is_deeply(written(\@closing), [qw/g4-g7xe5 g4-g7xb4 g4-g7xa1 g4-g7xd1/],
		'g4-g7 closes the top row, once for each black man');
	is(scalar(grep { $_->closes == 1 } @closing), 4, 'each says it closed one mill');
	is($game->move('g4-g7')->code, 'must_remove', 'played without a capture, it is refused');
	is($game->on_board('black'), 4, 'and nothing was taken');

	my $move = $game->move('g4-g7xb4');
	is($move->notation, 'g4-g7xb4', 'played with one, it stands');
	is($game->on_board('black'), 3, 'black is a man down');
	ok($game->board->empty(p('b4')), 'the man on b4 is gone');
	ok($game->board->in_mill(p('g7')), 'and white has its mill');
};

subtest 'stepping out of a mill and back in closes it again' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 g7 c3/], black => [qw/a1 d1 b4 e5 f2/],
	));
	is($game->move('g7-g4')->notation, 'g7-g4', 'white opens the mill and takes nothing');
	is($game->move('f2-f4')->notation, 'f2-f4', 'black makes a move');
	my $back = $game->move('g4-g7xa1');
	is($back->notation, 'g4-g7xa1', 'white closes it again and takes a man');
	is($back->closes, 1, 'one mill');
	is($game->on_board('black'), 4, 'five black men are four');
};

subtest 'both sides finish placing on the same ply, in every one of 500 games' => sub {
	my $next = stream(500);
	my ($checked, $broken, $finished_placing) = (0, 0, 0);
	for my $n (1 .. 500) {
		my $game = Game::Merrills->new;
		while ($game->status eq 'active' && $game->ply < 24) {
			my $turn = $game->turn;
			my $other = $turn eq 'white' ? 'black' : 'white';
			$checked++;
			$broken++ if $game->phase ne 'placing' && $game->in_hand($other);
			$broken++ if $game->ply < 18 && $game->phase ne 'placing';
			$broken++ if $game->ply >= 18 && $game->phase eq 'placing';
			my $legal = $game->legal_moves;
			$game->move($legal->[ $next->(scalar @{$legal}) ]);
		}
		$finished_placing++ if $game->ply >= 18;
	}
	cmp_ok($checked, '>', 9000, "$checked positions");
	cmp_ok($finished_placing, '>', 400, "$finished_placing games reached the moving phase");
	is($broken, 0, 'placing is plies 0 to 17 for both, and nobody moves while the other places');
};

done_testing;
