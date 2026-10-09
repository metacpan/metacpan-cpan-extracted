#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Merrills;
use Game::Merrills::Test::Position qw/p position_of stream/;

sub dies(&) {
	my ($code) = @_;
	return eval { $code->(); 1 } ? '' : ($@ || 'died');
}

sub snapshot {
	my ($game) = @_;
	return join ' | ', $game->to_position, $game->turn, $game->status,
		$game->no_mill, defined $game->draw_offered_by ? $game->draw_offered_by : '-',
		join(',', map { "$_=" . $game->repetition->{$_} } sort keys %{ $game->repetition }),
		join(' ', map { $_->notation } @{ $game->legal_moves });
}

subtest 'whole games played and taken all the way back, every state on the way' => sub {
	my $next = stream(1111);
	my ($games, $plies, $captures, $boundaries, $wrong) = (0, 0, 0, 0, 0);
	my %ended;
	for my $n (1 .. 40) {
		my $game = Game::Merrills->new;
		my @states = (snapshot($game));
		my @played;
		while ($game->status eq 'active' && $game->ply < 3000) {
			my $legal = $game->legal_moves;
			my $move = $game->move($legal->[ $next->(scalar @{$legal}) ]);
			push @played, $move;
			$captures++ if $move->is_capture;
			push @states, snapshot($game);
		}
		$games++;
		$plies += $game->ply;
		$ended{ $game->result->reason }++;
		$boundaries++ if $game->ply > 18;

		pop @states;
		while (@played) {
			my $taken = $game->undo;
			$wrong++ unless $taken == pop @played;
			$wrong++ unless snapshot($game) eq pop @states;
		}
		$wrong++ unless $game->ply == 0 && !@{ $game->history };
		$wrong++ unless $game->undo->code eq 'nothing_to_undo';
	}
	is($games, 40, 'forty games');
	cmp_ok($plies, '>', 1500, "$plies moves played and taken back");
	cmp_ok($captures, '>', 200, "$captures of them captures");
	is($boundaries, 40, 'every game crossed from placing into moving and back');
	is($wrong, 0, 'and every state on the way back is the state on the way out');
	note 'ended by: ' . join ', ', map { "$_ $ended{$_}" } sort keys %ended;
};

subtest 'undoing a capture puts the man back' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 g4 c3/], black => [qw/a1 d1 b4 e5/],
	));
	my $before = snapshot($game);
	my $move = $game->move('g4-g7xb4');
	is($game->on_board('black'), 3, 'three black men after the capture');
	is($game->undo, $move, 'undo returns the move it took back');
	is($game->on_board('black'), 4, 'four again');
	is($game->board->side_at(p('b4')), 'black', 'the man is on b4 and is black');
	is($game->board->side_at(p('g4')), 'white', 'the white man is back on g4');
	ok($game->board->empty(p('g7')), 'g7 is empty');
	is($game->turn, 'white', 'white to move again');
	is(snapshot($game), $before, 'and nothing else differs');
};

subtest 'undo restores the counts a capture wiped' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 g4 c3/], black => [qw/a1 d1 b4 e5 f2/], no_mill => 7,
	));
	$game->move('c3-c4');
	$game->move('f2-f4');
	is($game->no_mill, 9, 'two quiet moves on from seven');
	is(scalar keys %{ $game->repetition }, 3, 'and three positions counted');
	my $before = snapshot($game);

	$game->move('g4-g7xb4');
	is($game->no_mill, 0, 'the capture wipes the count');
	is(scalar keys %{ $game->repetition }, 1, 'and the table, but for the new position');
	$game->undo;
	is($game->no_mill, 9, 'undo brings back nine');
	is(scalar keys %{ $game->repetition }, 3, 'and the three positions');
	is(snapshot($game), $before, 'exactly');

	$game->undo;
	$game->undo;
	is($game->no_mill, 7, 'and two more undos bring back the seven the game began with');
	is(scalar keys %{ $game->repetition }, 1, 'with one position in the table');
};

subtest 'undo across the last placement' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 b2 e3 g1 c5 d3 f6 b6 d1/], black => [qw/g7 a4 c4 e4 g4 d6 d2 f2/],
		hand => { white => 0, black => 1 }, turn => 'black', ply => 17,
	));
	is($game->phase, 'placing', 'black has one man to place');
	is_deeply($game->repetition, {}, 'nothing is counted yet');
	my $before = snapshot($game);
	$game->move('a1');
	is($game->phase, 'moving', 'placed, and white is moving');
	is(scalar keys %{ $game->repetition }, 1, 'the first moving position is counted');
	$game->undo;
	is($game->phase, 'placing', 'taken back, black is placing again');
	is($game->in_hand('black'), 1, 'with the man in hand');
	is_deeply($game->repetition, {}, 'and the table empty');
	is(snapshot($game), $before, 'as it was');
};

subtest 'undo lifts a finish' => sub {
	my $game = Game::Merrills->new(position => position_of(
		white => [qw/a7 d7 g4 c3/], black => [qw/a1 d1 b4/],
	));
	$game->move('g4-g7xa1');
	is($game->status, 'finished', 'black is down to two and the game is over');
	$game->undo;
	is($game->status, 'active', 'undo and it is on again');
	is($game->result, undef, 'with no result');
	is(scalar @{ $game->legal_moves }, scalar @{ Game::Merrills->new(position => $game->position)->legal_moves },
		'and the legal moves are back');

	my $drawn = Game::Merrills->new(position => position_of(
		white => [qw/a7 b2 e3 g1/], black => [qw/f6 c5 d2 b4/],
	));
	$drawn->move($_) for qw/a7-d7 f6-f4 d7-a7 f4-f6 a7-d7 f6-f4 d7-a7 f4-f6/;
	is($drawn->result->reason, 'repetition', 'a draw by repetition');
	$drawn->undo;
	is($drawn->status, 'active', 'is lifted too');
	is($drawn->move('f4-f6')->notation, 'f4-f6', 'and the same move');
	is($drawn->result->reason, 'repetition', 'draws it again');
};

subtest 'undo after a resignation takes back the last move as well' => sub {
	my $game = Game::Merrills->new;
	$game->move('d2');
	$game->resign;
	is($game->status, 'finished', 'black resigned');
	is($game->undo->notation, 'd2', 'undo takes back d2');
	is($game->status, 'active', 'and the game is on');
	is($game->ply, 0, 'from the start');
};

subtest 'an offer standing before a move stands again after the undo' => sub {
	my $game = Game::Merrills->new;
	$game->move('d2');
	$game->offer_draw('white');
	$game->move('f4');
	is($game->draw_offered_by, undef, "black's move let it lapse");
	$game->undo;
	is($game->draw_offered_by, 'white', 'and taking that move back restores it');
};

subtest 'a clone shares nothing, forwards or backwards' => sub {
	my $next = stream(42);
	my $game = Game::Merrills->new(flying => 0);
	while ($game->ply < 30 && $game->status eq 'active') {
		my $legal = $game->legal_moves;
		$game->move($legal->[ $next->(scalar @{$legal}) ]);
	}
	$game->offer_draw;
	my $before = snapshot($game);
	my $clone = $game->clone;
	is(snapshot($clone), $before, 'a clone is in the same state');
	is($clone->ply, $game->ply, 'at the same ply');
	is($clone->flying, 0, 'with the same rules');
	is($clone->position, $game->position, 'from the same beginning');

	$clone->undo for 1 .. 30;
	is($clone->ply, 0, 'the clone taken all the way back');
	is($clone->to_position, '........................ w 9 9 0 0', 'to the empty board');
	is(snapshot($game), $before, 'leaves the original where it was');

	my $forward = $game->clone;
	$forward->move($forward->legal_moves->[0]) for 1 .. 3;
	is(snapshot($game), $before, 'and one played forward leaves it there too');

	my @back;
	push @back, snapshot($game) while ref $game->undo ne 'Game::Merrills::Error';
	is(scalar @back, 30, 'the original still takes back all thirty of its own');

	my $done = Game::Merrills->new;
	$done->resign;
	is($done->clone->status, 'finished', 'a finished game clones finished');
	is($done->clone->result->reason, 'resign', 'with its result');
};

subtest 'a game written down and read back' => sub {
	my $next = stream(77);
	my $game = Game::Merrills->new;
	while ($game->status eq 'active' && $game->ply < 3000) {
		my $legal = $game->legal_moves;
		$game->move($legal->[ $next->(scalar @{$legal}) ]);
	}
	my $text = $game->to_text;
	like($text, qr/\A1\. \S+ \S+\n2\. /, 'numbered pairs from move one');
	unlike($text, qr/position/, 'and no position line for a game from the empty board');

	my $read = Game::Merrills->from_text($text);
	is($read->to_position, $game->to_position, 'the same final position');
	is($read->ply, $game->ply, 'the same number of moves');
	is($read->result->reason, $game->result->reason, 'the same ending');
	is($read->result->winner, $game->result->winner, 'the same winner');
	is($read->to_text, $text, 'and it writes itself the same, byte for byte');
};

subtest 'a game from a position says so, and reads back from there' => sub {
	my $start = position_of(white => [qw/a7 d7 g4 c3/], black => [qw/a1 d1 b4 e5/], ply => 30);
	my $game = Game::Merrills->from_position($start);
	is($game->position, $start, 'position is where it began');
	is($game->ply, 30, 'ply counts on from the position');
	$game->move('g4-g7xb4');
	$game->move('e5-e4');
	is($game->ply, 32, 'two moves later');
	is(
		$game->to_position,
		position_of(white => [qw/a7 d7 g7 c3/], black => [qw/a1 d1 e4/], no_mill => 1, ply => 32),
		'to_position is where it is now'
	);
	is($game->position, $start, 'and position has not moved');

	my $text = $game->to_text;
	is($text, "position $start\n1. g4-g7xb4 e5-e4\n", 'the text names the start');
	my $read = Game::Merrills->from_text($text);
	is($read->to_position, $game->to_position, 'and reading it arrives at the same place');
	is($read->position, $start, 'from the same start');

	is(Game::Merrills->from_position($start, flying => 0)->flying, 0, 'from_position passes options on');
	is(Game::Merrills->from_text($text, flying => 0)->flying, 0, 'and so does from_text');
};

subtest 'a written game that does not play dies, naming the move' => sub {
	is(dies { Game::Merrills->from_text('1. d2 d2') },
		"illegal record: move 2, 'd2': that point is not empty\n", 'a move the rules refuse');
	like(dies { Game::Merrills->from_text('1. d2 f4 2. d2-d3') },
		qr/^illegal record: move 3, 'd2-d3': you still have men to place/, 'by its place in the game');
	like(dies { Game::Merrills->from_text('1. d2 zz') },
		qr/^record: move 2, 'zz' is not a move/, 'and one that is not a move at all');
	like(dies { Game::Merrills->new(position => 'nonsense') },
		qr/^position: six fields are needed/, 'a position that is not one dies too');
};

done_testing;
