#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;

subtest 'a game played and fully taken back' => sub {
	plan tests => 6;
	my $game = Game::Checkers->new;
	my $opening = $game->to_fen;
	my @fen = ($opening);

	# the moves themselves do not matter here, only that the position after
	# each one comes back exactly, so the first legal move will do
	while ($game->ply < 30 && $game->status eq 'active') {
		my $move = $game->move($game->legal_moves->[0]);
		last if ref $move eq 'Game::Checkers::Error';
		push @fen, $game->to_fen;
	}
	is $game->ply, 30, 'thirty moves played';
	isnt $game->to_fen, $opening, 'and the position has moved on';

	pop @fen;
	my $matched = 0;
	while ($game->ply) {
		$game->undo;
		$matched++ if $game->to_fen eq pop @fen;
	}
	is $matched, 30, 'every position on the way back is the one on the way out';
	is $game->to_fen, $opening, 'and the last of them is the opening';
	is $game->no_progress, 0, 'the no progress counter is back where it started';
	is_deeply $game->repetition, { $opening => 1 },
		'and the repetition table holds the opening and nothing else';
};

subtest 'undoing a jump restores what it took' => sub {
	plan tests => 5;
	my $game = Game::Checkers->new(fen => 'B:WK19:B15');
	my $before = $game->to_fen;

	my $move = $game->move('15x24');
	is_deeply $move->captured, [Game::Checkers::Board::WHITE_KING],
		'the move recorded what it captured, crown and all';

	$game->undo;
	is $game->to_fen, $before, 'the position is back';
	is $game->board->at(19), Game::Checkers::Board::WHITE_KING,
		'and a king that was jumped comes back a king';
	ok $game->board->king_at(19), 'not demoted to a man on the way';
	is $game->turn, 'black', 'with the same side to move';
};

subtest 'undo lifts a finish' => sub {
	plan tests => 3;
	my $game = Game::Checkers->new(fen => 'B:W15:B11');
	$game->move('11x18');
	is $game->status, 'finished', 'White has nothing left, so the game ended';

	$game->undo;
	is $game->status, 'active', 'and taking the move back starts it again';
	is $game->board->at(15), Game::Checkers::Board::WHITE_MAN, 'the man is back';
};

subtest 'undo through a draw' => sub {
	plan tests => 2;
	my $game = Game::Checkers->new(fen => 'B:WK32:BK1');
	$game->no_progress(Game::Checkers::NO_PROGRESS_PLIES - 1);
	$game->move('1-5');
	is $game->result->reason, 'no_progress', 'the counter ran out';

	$game->undo;
	is $game->no_progress, Game::Checkers::NO_PROGRESS_PLIES - 1,
		'and the counter comes back with the move';
};

done_testing;
