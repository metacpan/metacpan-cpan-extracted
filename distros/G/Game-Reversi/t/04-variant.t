#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi::Board;
use Game::Reversi::Opening;

# The variants: 'historic', which is the game this distribution is named after,
# and 'othello', which is the 1971 fixed start.
#
# The othello variant is not here because anybody asked for it. It is one of the
# six positions the historic opening reaches anyway, and it is the position
# every published transcript and every published move count begins from, so it
# is the only external oracle this distribution has. If it is wrong, every check
# against the outside world is checking the wrong thing.

my $B = 'Game::Reversi::Board';
my $O = 'Game::Reversi::Opening';

sub sq    { return $B->square_of(split //, $_[0]) }
sub names { return join ',', sort map { $B->name_of($_) } @_ }

subtest 'there are two variants and historic is the default' => sub {
	is_deeply([ $O->variants ], [ qw(historic othello) ], 'two of them');
	ok($O->describes('historic'), 'each has a sentence');
	ok($O->describes('othello'), 'about what it is');

	is_deeply($O->board_for(), $O->board_for('historic'),
		'no variant named means historic, which is the game on the tin');

	ok(!eval { $O->board_for('draughts'); 1 }, 'an unknown variant dies');
	like($@, qr/no variant/, 'saying so');
	done_testing();
};

subtest 'the historic game starts with nothing on the board' => sub {
	my $board = $O->board_for('historic');
	is(scalar(grep { defined } @$board), 0, 'an empty board');
	ok($O->in_opening($board), 'and four discs still to place');
	is($O->plies_left($board), 4, 'four');

	# Nobody can move by the ordinary rules yet, which is why the opening needs
	# its own rule rather than falling out of the others.
	ok(!$B->has_move($board, 'b'), 'Black has no ordinary move on an empty board');
	ok(!$B->has_move($board, 'w'), 'nor has White');
	done_testing();
};

subtest 'the othello start is the position every book opens with' => sub {
	# Wikipedia: "the game begins with four disks placed in a square in the
	# middle of the grid, two facing light-side-up, two dark-side-up, so that
	# the same-colored disks are on a diagonal", and "Convention has this such
	# that the dark-side-up disks are to the north-east and south-west (from
	# both players' perspectives)". Its board diagram shows rank 4 as light on
	# d4 and dark on e4, rank 5 as dark on d5 and light on e5.
	my $board = $O->board_for('othello');

	is(scalar(grep { defined } @$board), 4, 'four discs');
	is($board->[ sq('e4') ], 'b', 'dark on e4');
	is($board->[ sq('d5') ], 'b', 'and dark on d5, the other end of that diagonal');
	is($board->[ sq('d4') ], 'w', 'light on d4');
	is($board->[ sq('e5') ], 'w', 'and light on e5');

	is(names(grep { ($board->[$_] // '') eq 'b' } 0 .. 63), 'd5,e4',
		'dark holds exactly d5 and e4');
	is(names(grep { ($board->[$_] // '') eq 'w' } 0 .. 63), 'd4,e5',
		'and light exactly d4 and e5');
	done_testing();
};

subtest 'the othello variant has no opening to play' => sub {
	# The centre arrives full, so in_opening answers correctly without needing
	# to know which variant it is looking at. That is the whole reason it is
	# written as "is a centre square empty" rather than as a ply counter.
	my $board = $O->board_for('othello');
	ok(!$O->in_opening($board), 'not in the opening');
	is($O->plies_left($board), 0, 'no placements to come');
	is_deeply([ $O->legal($board, 'b') ], [],
		'and no placements are offered, because there is nowhere to place');
	done_testing();
};

subtest 'Black has exactly four moves, which is the outside world checking us' => sub {
	# THE ONE POSITION IN THE GAME WHOSE MOVE LIST CAN BE CHECKED AGAINST A
	# PUBLISHED SOURCE. Every opening book starts here and gives Black c4, d3,
	# e6 and f5. Anything else means move generation is wrong, and it is the
	# cheapest external check this distribution has until a perft ladder is
	# found and cited.
	my $board = $O->board_for('othello');
	is(names($B->legal_moves($board, 'b')), 'c4,d3,e6,f5',
		'c4, d3, e6 and f5, and nothing else');

	# Each of them turns exactly one disc, which is the other thing every book
	# says about this position: the four openings are the same game rotated.
	for my $move (qw(c4 d3 e6 f5)) {
		is(scalar($B->flips_for($board, sq($move), 'b')), 1,
			"$move turns exactly one disc");
	}

	# And White, who is not to move, would have the mirror image of the same
	# four. A position this symmetric is worth asserting both ways: an engine
	# that had the colours crossed somewhere would pass the Black check alone.
	is(names($B->legal_moves($board, 'w')), 'c5,d6,e3,f4',
		'White would have the mirror four');
	done_testing();
};

subtest 'the othello position is one of the six the historic opening reaches' => sub {
	# Not a coincidence worth leaving implicit: it is why the variant costs an
	# array constant rather than a code path.
	my $reached = $O->board_for('historic');
	$reached = $O->apply($reached, sq('e4'), 'b');
	$reached = $O->apply($reached, sq('d4'), 'w');
	$reached = $O->apply($reached, sq('d5'), 'b');
	$reached = $O->apply($reached, sq('e5'), 'w');

	is_deeply($reached, $O->board_for('othello'),
		'placing e4, d4, d5, e5 in that order reaches the othello start exactly');
	done_testing();
};

done_testing();
