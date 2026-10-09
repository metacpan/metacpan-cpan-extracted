#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Merrills;
use Game::Merrills::Result;
use Game::Merrills::Test::Position qw/p position_of stream/;

sub dies(&) {
	my ($code) = @_;
	return eval { $code->(); 1 } ? '' : ($@ || 'died');
}

sub finished {
	my ($game, $winner, $reason, $name) = @_;
	subtest $name => sub {
		is($game->status, 'finished', 'the game is over');
		isa_ok($game->result, 'Game::Merrills::Result') or return;
		is($game->result->winner, $winner, 'winner: ' . (defined $winner ? $winner : 'nobody'));
		is($game->result->reason, $reason, "reason: $reason");
		is_deeply($game->legal_moves, [], 'and there is nothing left to play');
	};
}

my $SHUFFLE = position_of(white => [qw/a7 b2 e3 g1/], black => [qw/f6 c5 d2 b4/]);
my @ROUND = qw/a7-d7 f6-f4 d7-a7 f4-f6/;

subtest 'few: a side brought down to two men has lost' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 g4 c3/], black => [qw/a1 d1 b4/],
	));
	is($game->status, 'active', 'three men is enough to play on');
	is($game->result, undef, 'and an active game has no result');
	$game->move('g4-g7xa1');
	finished($game, 'white', 'few', 'white takes the third man');
	is($game->men('black'), 2, 'black has two');
	is($game->result->loser, 'black', 'and is the loser');
	is($game->result->stringify, 'White wins: Black has fewer than three men', 'in words');
	is($game->move('d1-a1')->code, 'game_over', 'a move after the end is refused');
};

subtest 'few counts the men in hand: one down and five to come is six' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7/], black => [qw/a1/], hand => { white => 7, black => 5 },
	));
	is($game->status, 'active', 'alive at the start');
	$game->move('g7xa1');
	is($game->on_board('black'), 0, 'black has nobody on the board');
	is($game->men('black'), 5, 'and five men all the same');
	is($game->status, 'active', 'so the game goes on');
	is($game->phase, 'placing', 'with black to place');
};

subtest 'blocked: a side to move with no move has lost' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/d6 a4 g4 d1/], black => [qw/a7 g7 a1 g1/],
	));
	is($game->status, 'active', 'd7 is open, so black could still move');
	$game->move('d6-d7');
	finished($game, 'white', 'blocked', 'white shuts the last door');
	is($game->on_board('black'), 4, 'black still has four men');
	is($game->result->stringify, 'White wins: Black has no move', 'in words');
};

subtest 'a game can begin already lost' => sub {
	finished(
		Game::Merrills->new(position => position_of(
			white => [qw/d7 a4 g4 d1/], black => [qw/a7 g7 a1 g1/], turn => 'black',
		)),
		'white', 'blocked', 'black to move and walled in'
	);
	finished(
		Game::Merrills->new(position => position_of(
			white => [qw/d7 a4 g4/], black => [qw/a7 g7/], turn => 'black',
		)),
		'white', 'few', 'black to move with two men'
	);
	finished(
		Game::Merrills->new(position => position_of(
			white => [qw/d7 a4 g4/], black => [qw/a7 g7/], turn => 'white',
		)),
		'white', 'few', 'white to move and black with two men'
	);
};

subtest 'two men and no move is few, not blocked' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a4 d1 g4 c5 d5 e4/], black => [qw/a1 g1 b6/],
	));
	$game->move('e4-e5xb6');
	finished($game, 'white', 'few', 'the two left are hemmed in as well');
};

subtest 'repetition: the same position a third time is a draw' => sub {
	my $game = Game::Merrills->new(position => $SHUFFLE);
	is_deeply([ values %{ $game->repetition } ], [1], 'the first position counts once');
	$game->move($_) for @ROUND;
	is($game->status, 'active', 'once round, and it has stood twice');
	is(scalar(grep { $_ == 2 } values %{ $game->repetition }), 1, 'the table says so');
	$game->move($_) for @ROUND[ 0 .. 2 ];
	is($game->status, 'active', 'one move short of the third time');
	$game->move($ROUND[3]);
	finished($game, undef, 'repetition', 'the fourth move of the second round');
	ok($game->result->is_draw, 'a draw');
	is($game->result->loser, undef, 'with no loser');
	is($game->result->stringify, 'Draw: the same position three times', 'in words');
	is($game->ply, 8, 'after eight plies');
};

subtest 'the same men with the other side to move is another position' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d5 g1/], black => [qw/b6 f4 d2 c3/],
	));
	my $men = substr $game->to_position, 0, 24;
	$game->move($_) for qw/a7-g7 b6-d6 g7-b2 d6-b6 b2-a7/;
	is(substr($game->to_position, 0, 24), $men, 'white flies a man round three points and the men are as they began');
	is($game->turn, 'black', 'but now it is black to move, where it was white');
	is_deeply([ sort values %{ $game->repetition } ], [ 1, 1, 1, 1, 1, 1 ],
		'so it is a new position, and each of the six has stood once');

	$game->move($_) for qw/b6-d6 a7-g7 d6-b6 g7-a7/;
	is(substr($game->to_position, 0, 24), $men, 'round again, the same men a third time');
	is($game->status, 'active', 'once with white to move and twice with black is not three times');
	is(scalar(grep { $_ > 2 } values %{ $game->repetition }), 0, 'and the table agrees');
};

subtest 'nothing is counted while men are still being placed' => sub {
	my $next = stream(9);
	my $game = Game::Merrills->new;
	my $counted_early = 0;
	while ($game->ply < 18 && $game->status eq 'active') {
		$counted_early++ if %{ $game->repetition } || $game->no_mill;
		my $legal = $game->legal_moves;
		$game->move($legal->[ $next->(scalar @{$legal}) ]);
	}
	is($counted_early, 0, 'no position counted and no_mill nought, for eighteen plies');
	is($game->ply, 18, 'every man is down');
	is_deeply([ values %{ $game->repetition } ], [1], 'and the first moving position counts once');
};

subtest 'no_mill: the limit is the constant, and the move that reaches it draws' => sub {
	my $limit = Game::Merrills::NO_MILL_PLIES;
	cmp_ok($limit, '>', 0, "the limit is $limit");
	is($Game::Merrills::NO_MILL_LIMIT, $limit, 'and the limit in force is the constant');

	my %men = (white => [qw/a7 b2 e3 g1/], black => [qw/f6 c5 d2 b4/]);
	my $short = Game::Merrills->new(position => position_of(%men, no_mill => $limit - 2));
	$short->move('a7-d7');
	is($short->status, 'active', 'one short of the limit, the game goes on');
	is($short->no_mill, $limit - 1, 'the count having gone up by one');

	my $game = Game::Merrills->new(position => position_of(%men, no_mill => $limit - 1));
	$game->move('a7-d7');
	finished($game, undef, 'no_mill', 'the move that makes it the limit');
	is($game->result->stringify, 'Draw: too long without a mill', 'in words');
};

subtest 'closing a mill starts the count again' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 g4 c3/], black => [qw/a1 d1 b4 e5 f2/],
		no_mill => Game::Merrills::NO_MILL_PLIES - 1,
	));
	$game->move('g4-g7xf2');
	is($game->status, 'active', 'the capture came in time');
	is($game->no_mill, 0, 'and the count is nought again');
	is_deeply([ values %{ $game->repetition } ], [1], 'as is the table of positions, but for this one');
};

subtest 'the limit in force can be moved, and switched off' => sub {
	{
		local $Game::Merrills::NO_MILL_LIMIT = 4;
		my $game = Game::Merrills->new(position => $SHUFFLE);
		$game->move($_) for @ROUND[ 0 .. 2 ];
		is($game->status, 'active', 'at four, three quiet moves are fine');
		$game->move($ROUND[3]);
		finished($game, undef, 'no_mill', 'and the fourth draws');
	}
	{
		local $Game::Merrills::NO_MILL_LIMIT = 0;
		my $game = Game::Merrills->new(position => position_of(
			white => [qw/a7 b2 e3 g1/], black => [qw/f6 c5 d2 b4/],
			no_mill => 5 * Game::Merrills::NO_MILL_PLIES,
		));
		$game->move('a7-d7');
		is($game->status, 'active', 'at nought there is no limit');
		$game->move($_) for @ROUND[ 1 .. 3 ], @ROUND;
		finished($game, undef, 'repetition', 'and repetition still ends the shuffle');
	}
	{
		local $Game::Merrills::NO_MILL_LIMIT = 8;
		my $game = Game::Merrills->new(position => $SHUFFLE);
		$game->move($_) for @ROUND, @ROUND;
		is($game->no_mill, 8, 'eight quiet moves, with the limit at eight');
		finished($game, undef, 'repetition', 'when one move reaches both, it is repetition that is named');
	}
	is($Game::Merrills::NO_MILL_LIMIT, Game::Merrills::NO_MILL_PLIES, 'afterwards it is the constant again');
};

subtest 'resigning and running out of time' => sub {
	my $resigned = Game::Merrills->new;
	my $result = $resigned->resign;
	isa_ok($result, 'Game::Merrills::Result');
	finished($resigned, 'black', 'resign', 'white, to move, resigns');
	is($result->stringify, 'Black wins: White resigned', 'in words');
	is($resigned->resign->code, 'game_over', 'and cannot resign twice');

	my $other = Game::Merrills->new;
	$other->resign('black');
	finished($other, 'white', 'resign', 'black resigns out of turn');

	my $late = Game::Merrills->new;
	$late->move('d2');
	$late->timeout;
	finished($late, 'white', 'timeout', 'black, to move, runs out of time');
	is($late->result->stringify, 'White wins: Black ran out of time', 'in words');
	is($late->timeout('white')->code, 'game_over', 'and time cannot run out twice');

	my $named = Game::Merrills->new;
	$named->timeout('white');
	finished($named, 'black', 'timeout', 'white named as out of time');

	like(dies { Game::Merrills->new->resign('red') }, qr/^side must be white or black, got 'red'/,
		'a side that is not one dies');
};

subtest 'a draw by agreement' => sub {
	my $game = Game::Merrills->new;
	is($game->accept_draw->code, 'no_offer', 'nothing to accept at first');
	is($game->decline_draw->code, 'no_offer', 'nor to decline');
	is($game->offer_draw, 'white', 'white offers');
	is($game->draw_offered_by, 'white', 'the offer stands');
	is($game->accept_draw('white')->code, 'no_offer', 'white cannot accept its own');
	is($game->decline_draw('white')->code, 'no_offer', 'nor decline it');
	is($game->decline_draw('black'), 'black', 'black declines');
	is($game->draw_offered_by, undef, 'and the offer is gone');
	is($game->status, 'active', 'with the game still on');

	$game->offer_draw('white');
	my $result = $game->accept_draw('black');
	finished($game, undef, 'agreement', 'offered again and accepted');
	is($result->stringify, 'Draw: agreed', 'in words');
	is($game->offer_draw->code, 'game_over', 'no offers after the end');
	is($game->accept_draw->code, 'game_over', 'nor acceptances');
	is($game->decline_draw->code, 'game_over', 'nor refusals');
};

subtest 'an offer stands through the offerer\'s own move and lapses on the reply' => sub {
	my $game = Game::Merrills->new;
	$game->offer_draw('white');
	$game->move('d2');
	is($game->draw_offered_by, 'white', 'white moved, the offer stands');
	$game->move('f4');
	is($game->draw_offered_by, undef, 'black answered with a move, and it lapsed');
	is($game->accept_draw('black')->code, 'no_offer', 'so there is nothing to accept');
};

subtest 'a result that contradicts itself cannot be made' => sub {
	is_deeply([ Game::Merrills::Result->reasons ],
		[qw/few blocked repetition no_mill agreement resign timeout/], 'the seven reasons');
	like(dies { Game::Merrills::Result->new(winner => 'white', reason => 'luck') },
		qr/^reason must be one of few, blocked, .* got 'luck'/, 'a reason that is not one');
	like(dies { Game::Merrills::Result->new(winner => 'white') },
		qr/^reason must be one of .* got undef/, 'no reason');
	like(dies { Game::Merrills::Result->new(winner => 'red', reason => 'few') },
		qr/^winner must be white, black or undef for a draw, got 'red'/, 'a red winner');
	for my $reason (qw/repetition no_mill agreement/) {
		like(dies { Game::Merrills::Result->new(winner => 'white', reason => $reason) },
			qr/^a game that ends by $reason is a draw and has no winner/, "$reason with a winner");
		ok(Game::Merrills::Result->new(reason => $reason)->is_draw, "$reason without one is a draw");
	}
	for my $reason (qw/few blocked resign timeout/) {
		like(dies { Game::Merrills::Result->new(reason => $reason) },
			qr/^a game that ends by $reason has a winner/, "$reason with no winner");
		my $result = Game::Merrills::Result->new(winner => 'black', reason => $reason);
		is($result->loser, 'white', "$reason: black wins and white loses");
		like($result->stringify, qr/^Black wins: White /, 'and says so');
	}
};

done_testing;
