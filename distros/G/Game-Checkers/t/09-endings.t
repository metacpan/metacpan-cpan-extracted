#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;

subtest 'a side with nothing left has lost' => sub {
	plan tests => 4;
	my $game = Game::Checkers->new(fen => 'B:W15:B');
	is $game->status, 'finished', 'the game is over before it starts';
	is $game->result->winner, 'white', 'White wins';
	is $game->result->reason, 'no_moves', 'because Black has no move';
	is_deeply $game->legal_moves, [], 'and a finished game offers nothing';
};

subtest 'a side that cannot move has lost, pieces or not' => sub {
	plan tests => 3;
	# the man on 1 is walled in: both steps are blocked and both landing
	# squares behind them are occupied
	my $game = Game::Checkers->new(fen => 'B:W5,6,9,10:B1');
	is $game->status, 'finished', 'blocked is the same as beaten';
	is $game->result->winner, 'white', 'White wins';
	is $game->result->stringify, 'White wins: Black has no move', 'and says so';
};

subtest 'threefold repetition' => sub {
	plan tests => 7;
	my $game = Game::Checkers->new(fen => 'B:WK32:BK1');
	my $start = $game->to_fen;

	for my $cycle (1 .. 2) {
		$game->move('1-5');
		$game->move('32-28');
		$game->move('5-1');
		$game->move('28-32');
		is $game->to_fen, $start, "back where it started, cycle $cycle";
		if ($cycle == 1) {
			is $game->status, 'active', 'twice is not three times';
			is $game->repetition->{$start}, 2, 'the position has been here twice';
		}
	}

	is $game->status, 'finished', 'the third occurrence ends it';
	ok $game->result->is_draw, 'as a draw';
	is $game->result->reason, 'repetition', 'by repetition';
};

subtest 'forty moves with nothing to show for them' => sub {
	plan tests => 5;
	my $game = Game::Checkers->new(fen => 'B:WK32:BK1');
	is $game->no_progress, 0, 'the counter starts at nothing';

	$game->move('1-5');
	is $game->no_progress, 1, 'a king move is not progress';

	# the counter is a plain property, so the long walk to 80 does not have to
	# be played out move by move to test what happens at the end of it
	$game->no_progress(Game::Checkers::NO_PROGRESS_PLIES - 2);
	$game->move('32-28');
	is $game->status, 'active', 'seventy nine is not eighty';

	$game->move('5-1');
	is $game->status, 'finished', 'eighty plies is forty moves each';
	is $game->result->reason, 'no_progress', 'and draws';
};

subtest 'a man moving resets the counter' => sub {
	plan tests => 2;
	my $game = Game::Checkers->new(fen => 'B:WK32:B11');
	$game->no_progress(40);
	$game->move('11-15');
	is $game->no_progress, 0, 'a man moved, so the game is going somewhere';

	$game->move('32-28');
	is $game->no_progress, 1, 'and the count starts again';
};

subtest 'resigning' => sub {
	plan tests => 4;
	my $game = Game::Checkers->new;
	my $result = $game->resign('black');
	is $game->status, 'finished', 'the game is over';
	is $result->winner, 'white', 'the other side wins';
	is $result->reason, 'resign', 'by resignation';
	ok $game->move('11-15')->game_over, 'and no move follows it';
};

subtest 'a draw by agreement' => sub {
	plan tests => 6;
	my $game = Game::Checkers->new;
	ok $game->accept_draw('white')->no_offer, 'nothing to accept yet';

	$game->offer_draw('black');
	is $game->draw_offered_by, 'black', 'black has offered';
	ok $game->accept_draw('black')->no_offer, 'and cannot accept its own offer';

	my $result = $game->accept_draw('white');
	ok $result->is_draw, 'white accepts';
	is $result->reason, 'agreement', 'by agreement';
	is $result->pdn, '1/2-1/2', 'which is how PDN spells it';
};

subtest 'an offer does not outlive the answer' => sub {
	plan tests => 3;
	my $game = Game::Checkers->new;
	$game->offer_draw('black');
	$game->move('11-15');
	is $game->draw_offered_by, 'black', 'still open while black is the one moving';

	$game->move('22-18');
	is $game->draw_offered_by, undef, 'white answered it with a move instead';
	ok $game->accept_draw('white')->no_offer, 'so there is nothing left to accept';
};

done_testing;
