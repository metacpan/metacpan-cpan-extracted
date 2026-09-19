#!perl

# THE INVARIANTS: every structure the C maintains a move at a time, re-derived
# in Perl from the whole position.
#
# This is the closest thing decision four leaves us to a differential oracle.
# The chains, the liberty counts and the zobrist key are DERIVED quantities, so
# they can be recomputed from scratch by different code in a different language
# even though there is only one board implementation. t/lib/Invariants.pm says
# what each check is and why it works in columns and rows rather than in the
# engine's padded indices.
#
# The heavy version of this file is xt/invariants-paranoid.t, which checks after
# EVERY move of a thousand playouts. This one keeps the positions a person can
# read, and the game it plays is short enough to install.

use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Digest::SHA ();

use Game::Go;
use Game::Go::Rules;
use Invariants;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

# A position drawn as text. X is black, O is white, a dot is empty, and every
# stone is PLAYED rather than placed, so the position is one the rules can
# actually reach and the structures under test were built the way they are in a
# game. Turn order is forced because a diagram is not a game record.
#
# THE BOARD IS ALWAYS 9x9, because 9, 13 and 19 are the only sizes this
# distribution has, and a diagram is padded out to it with empty points rather
# than sizing the board to the drawing.
sub drawn {
	my (@rows) = @_;
	my $game = Game::Go->new(size => 9, seed => 'invariants');

	for my $row (0 .. $#rows) {
		my @cells = split //, $rows[$row];
		for my $col (0 .. $#cells) {
			next if $cells[$col] eq '.';
			my $colour = $cells[$col] eq 'X' ? $B : $W;
			$game->turn($colour);
			my $out = $game->play($colour, $game->point($col, $row));
			die "drawn: $cells[$col] at $col,$row was refused: " . $out->flag
				if ref $out eq 'Game::Go::Error';
		}
	}
	return $game;
}

subtest 'an empty board' => sub {
	my $game = Game::Go->new(size => 9, seed => 'invariants');
	Invariants::check($game->board, 'empty 9x9');
	is($game->board->hash_hex, '0' x 16, 'and the empty board hashes to zero');
	done_testing();
};

subtest 'a single stone, and the edge' => sub {
	# The corner has two liberties, the edge three, the middle four. If the
	# sentinel ring were wrong in either direction this is where it shows, and
	# the checker finds it independently because it bounds-tests in column and
	# row space rather than trusting the ring.
	my $game = drawn(
		'X.......X',
		'.........',
		'.........',
		'.........',
		'....X....',
		'.........',
		'.........',
		'.........',
		'X.......X',
	);
	Invariants::check($game->board, 'corners and centre');

	is($game->board->libs(0, 0), 2, 'a corner stone has two liberties');
	is($game->board->libs(8, 8), 2, 'and so does the opposite corner');
	is($game->board->libs(4, 4), 4, 'one in the middle has four');
	is(scalar(Invariants::chains($game->board)), 5, 'five separate stones');
	done_testing();
};

subtest 'a chain along a whole row does not wrap into the next' => sub {
	# THE EDGE WRAP. On a padded 1-D array the point to the right of the last
	# column is the border sentinel, not the first column of the next row. Two
	# full rows are two chains; a missing sentinel would make them one.
	my $game = drawn(
		'XXXXXXXXX',
		'.........',
		'XXXXXXXXX',
	);
	Invariants::check($game->board, 'two full rows');

	is(scalar(Invariants::chains($game->board)), 2, 'two rows are two chains');
	is($game->board->chain_size(0, 0), 9, 'each nine stones long');
	is($game->board->libs(0, 0), 9, 'with nine liberties below it');
	done_testing();
};

subtest 'shared liberties are counted once' => sub {
	# A LIBERTY IS A POINT, NOT AN ADJACENCY. Two stones of one chain touching
	# the same empty point give the chain one liberty between them, and a
	# pseudo-liberty count would say one more. This is the exact difference
	# between the exact recount the engine does and the faster approximation it
	# deliberately does not.
	my $game = drawn('XX');
	Invariants::check($game->board, 'a two-stone chain');

	my ($chain) = Invariants::chains($game->board);
	# The two stones touch 0,1 and 1,1 below and 2,0 to the right. Three
	# points; four adjacencies.
	is($chain->{libs}, 3, 'two stones in a row have three liberties, not four');
	is($game->board->libs(0, 0), 3, 'and the engine agrees');
	done_testing();
};

subtest 'every tenth position of a played game' => sub {
	# The structures after real moves, captures included, which is where the
	# maintenance has something to get wrong.
	my $game = Game::Go->new(size => 9, seed => 'invariants');

	my ($n, $moves, $checked) = (0, 0, 0);
	while ($game->status eq 'active' && $game->phase eq 'play' && $moves < 80) {
		my $colour = $game->turn;
		my $legal = $game->legal($colour);
		my @plays = grep { $_->kind eq 'play' } @$legal;
		last unless @plays;

		# A seeded walk, so a failure replays exactly.
		my $word = unpack 'N', Digest::SHA::sha256('invariants:' . $n++);
		my $move = $plays[ $word % scalar @plays ];

		$game->play($colour, $move->point);
		$moves++;

		next unless $moves % 10 == 0;
		Invariants::check($game->board, "after move $moves");
		$checked++;
	}

	cmp_ok($moves, '>=', 60, "$moves moves played");
	cmp_ok($checked, '>=', 6, "and $checked positions checked along the way");
	Invariants::check($game->board, 'the final position');
	done_testing();
};

subtest 'a capture gives the liberties back' => sub {
	# THE ONE THE MAINTENANCE CAN GET WRONG QUIETLY. Lifting a chain has to
	# return the liberties to every neighbouring chain, and a chain whose count
	# is not restored looks alive while being one move away from a wrong
	# legality verdict. Nothing about the position shows it; only the recount
	# does.
	#
	#   . . .      white at 1,1 has one liberty left, 1,0
	#   X O X      black at 0,1 has two: 0,0 and 0,2
	#   . X .      black at 2,1 has three: 2,0, 3,1 and 2,2
	my $game = drawn(
		'...',
		'XOX',
		'.X',
	);
	Invariants::check($game->board, 'before the capture');

	my $before_left  = $game->board->libs(0, 1);
	my $before_right = $game->board->libs(2, 1);
	is($game->board->libs(1, 1), 1, 'the white stone is down to one liberty');
	is($before_left, 2, 'the chain to its left has two');
	is($before_right, 3, 'and the one to its right has three');

	$game->turn($B);
	my $out = $game->play($B, $game->point(1, 0));
	isa_ok($out, 'Game::Go::Move', 'the capturing move');
	is($out->captured, 1, 'and it took the stone');

	Invariants::check($game->board, 'after the capture');
	is($game->board->libs(2, 1), $before_right + 1,
		'the chain on the far side got its liberty back');
	cmp_ok($game->board->libs(0, 1), '>', $before_left,
		'and so did the one on the near side');
	done_testing();
};

done_testing();
