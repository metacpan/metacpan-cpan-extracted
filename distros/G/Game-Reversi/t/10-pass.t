#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi;
use Game::Reversi::Board;
use Game::Reversi::Rules;

# The forced pass. WOF rule 2:
#
#     If on your turn you cannot outflank and flip at least one opposing disc,
#     your turn is forfeited and your opponent moves again. However, if a move
#     is available to you, you may not forfeit your turn.
#
# Two rules pulling opposite ways, and the consequence worth checking is the one
# that falls out of having both: because the engine forfeits for anybody who
# cannot move, a seat on turn ALWAYS has a move, so a deliberate pass can only
# ever be answered with has_move.
#
# Parentheses on every Test::More call whose first argument is a Class->method
# call: without them it parses as indirect object syntax.

my $B = 'Game::Reversi::Board';
my $R = 'Game::Reversi::Rules';

sub sq    { return $B->square_of(split //, $_[0]) }
sub names { return join ',', sort map { $B->name_of($_) } @_ }

# A position with the centre full, so that the opening is over, and with White
# unable to move.
#
# Black holds the four centre squares and h4. White holds g4 and nothing else.
#
# WHITE CANNOT MOVE, derived: a legal White move needs an empty square from
# which a ray runs over black discs and ends on a white one. White's only disc
# is g4, so every candidate ray has to finish there. The rays that reach g4 are
# the eight from its neighbours, and the only black disc adjacent to g4 is h4,
# which is east of it; so the ray would have to start east of h4 and run west,
# and there is nothing east of h4. The centre blacks are on rank 4 and file d/e,
# and a rank 4 ray from either side stops on an empty square before reaching g4.
#
# BLACK CAN MOVE: f4 runs east over g4, white, and ends on h4, black.
#
# It is a fixture rather than a position from a game: it isolates the rule,
# which is what a unit test of a pure function is for. The rule is exercised
# again further down inside a game that really reaches a pass.
sub stuck_white {
	my $board = $B->empty;
	$board->[ sq($_) ] = 'b' for qw(d5 e5 d4 e4 h4);
	$board->[ sq('g4') ] = 'w';
	return $board;
}

subtest 'the fixture is what it claims to be' => sub {
	my $board = stuck_white();
	ok(!$R->in_opening($board), 'the centre is full, so the opening is over');
	ok(!$B->has_move($board, 'w'), 'White has no legal move');
	ok($B->has_move($board, 'b'), 'Black has one');
	is(names($B->legal_moves($board, 'b')), 'f4', 'and it is f4');
	is_deeply([ $B->flips_for($board, sq('f4'), 'b') ], [ sq('g4') ],
		'turning g4');
	done_testing();
};

subtest 'a seat that cannot move has its turn taken away' => sub {
	my $board = stuck_white();
	my ($turn, $forfeited) = $R->next_turn($board, 'b');

	is($turn, 'b', 'Black moves again');
	is($forfeited, 'w', 'because White forfeited');
	ok(!$R->over($board), 'and the game is not over, since Black can still play');
	done_testing();
};

subtest 'when neither can move the game is over, not passed round for ever' => sub {
	# A position where only one colour is on the board. Neither side can move,
	# and for the same reason both ways round: every legal move has to outflank
	# an opposing disc, and there are none of one colour at all.
	#
	# The first attempt at this fixture was wrong, which is worth recording.
	# It took the stuck_white board and added a black disc on f4 to remove
	# Black's only reply. That did remove it, and it also created a black run
	# d4 e4 f4 closed by White's g4, handing White the move c4 and making the
	# position lively again. Hand deriving Reversi positions is error prone in
	# exactly this way: blocking one line opens another.
	my $board = $B->empty;
	$board->[ sq($_) ] = 'b' for qw(d5 e5 d4 e4 c4 f4);

	ok(!$R->in_opening($board), 'the centre is full, so the opening is over');
	ok(!$B->has_move($board, 'b'), 'Black has nothing to outflank');
	ok(!$B->has_move($board, 'w'), 'and White has no disc to outflank anything with');
	ok($R->over($board), 'so the game is over');
	is($B->empties($board), 58, 'with 58 squares still empty, which is allowed');

	my ($turn) = $R->next_turn($board, 'b');
	is($turn, undef, 'next_turn says there is no turn');
	done_testing();
};

subtest 'a full board is over too, as a special case of the same rule' => sub {
	# WOF rule 8 gives one condition, neither player able to move, and notes
	# that "It is possible for a game to end before all 64 squares are filled."
	# A full board is a strict special case of it rather than a second rule, and
	# this asserts that the general condition really does cover it.
	my $board = $B->empty;
	$_ = 'b' for @$board;
	$board->[ sq('a1') ] = 'w';

	ok($R->over($board), 'a full board is over');
	is($B->empties($board), 0, 'with nothing empty');
	done_testing();
};

# ---- inside a real game ------------------------------------------------------

subtest 'legal never offers a pass, at any point in a whole game' => sub {
	# The rule stated over a game rather than at one position: at no point is a
	# player shown a move they have no choice about.
	my $game = Game::Reversi->new(variant => 'historic');
	my ($moves, %phases) = (0);

	while ($game->status eq 'active' && $moves < 200) {
		my $legal = $game->legal($game->turn);
		last unless @$legal;
		$phases{ $_->phase }++ for @$legal;
		$moves++;
		$game->play($game->turn, $legal->[0]->square);
	}

	is($game->status, 'finished', 'the game finished');
	is_deeply([ sort keys %phases ], [ qw(place play) ],
		'every move offered was a placement or a play, and never anything else');
	done_testing();
};

subtest 'a deliberate pass is refused, and it is always has_move' => sub {
	my $game = Game::Reversi->new(variant => 'historic');
	my $error = $game->pass($game->turn);

	ok($error, 'passing is refused');
	is($error->code, 'has_move', 'as has_move');
	like($error->message, qr/cannot be forfeited/, 'saying why');
	ok(scalar @{ $error->legal }, 'and listing what could be played instead');

	# There is no way to reach this method legitimately, so the claim that
	# has_move is the only possible answer is worth checking over a whole game
	# rather than once: whenever it is somebody's turn, they have a move.
	my ($codes, $moves) = ({}, 0);
	while ($game->status eq 'active' && $moves++ < 200) {
		my $refusal = $game->pass($game->turn);
		$codes->{ $refusal->code }++;
		my $legal = $game->legal($game->turn);
		last unless @$legal;
		$game->play($game->turn, $legal->[0]->square);
	}
	is_deeply([ keys %$codes ], [ 'has_move' ],
		'has_move every single time, because a seat on turn always has a move');
	done_testing();
};

subtest 'passing out of turn, and after the end, say so instead' => sub {
	my $game = Game::Reversi->new(variant => 'historic');
	my $off_turn = $game->pass($B->other($game->turn));
	is($off_turn->code, 'not_your_turn',
		'the seat not on turn is told that first, not has_move');

	1 while $game->status eq 'active'
		&& do { my $l = $game->legal($game->turn); @$l and $game->play($game->turn, $l->[0]->square) };
	is($game->status, 'finished', 'played to the end');
	is($game->pass('b')->code, 'game_over', 'and then a pass is game_over');
	is($game->play('b', sq('a1'))->code, 'game_over', 'as is a move');
	done_testing();
};

subtest 'a game that really forfeits a turn says so in its log' => sub {
	# The historic opening, always taking the lowest numbered legal square,
	# reaches a position where a turn is forfeited. That is a fact about this
	# engine rather than a cited one, so what is asserted is the SHAPE of the
	# log around a pass and not which game produces it: a sys pass event names
	# the seat that lost its turn, and the seat that moved before it moves again
	# straight after.
	my $game = Game::Reversi->new(variant => 'historic');
	while ($game->status eq 'active') {
		my $legal = $game->legal($game->turn);
		last unless @$legal;
		$game->play($game->turn, $legal->[0]->square);
	}

	my @log = @{ $game->events };
	my @passes = grep { $log[$_]{kind} eq 'pass' } 0 .. $#log;
	ok(scalar @passes, 'this game forfeits at least one turn') or do {
		done_testing();
		return;
	};

	for my $i (@passes) {
		is($log[$i]{actor}, 'sys',
			'a pass is the engine talking, not a move a player made');
		my $lost = $log[$i]{payload}{colour};
		like($lost, qr/\A[bw]\z/, 'and it names the seat that lost its turn');

		my ($before) = grep { $log[$_]{actor} ne 'sys' } reverse 0 .. $i - 1;
		my ($after)  = grep { $log[$_]{actor} ne 'sys' } $i + 1 .. $#log;
		is($log[$before]{actor}, $B->other($lost),
			'the seat before the pass is the other one');
		is($log[$after]{actor}, $B->other($lost),
			'and it moves again straight after, which is what a forfeit means')
			if defined $after;
	}
	done_testing();
};

done_testing();
