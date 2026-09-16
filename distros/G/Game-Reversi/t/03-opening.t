#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi::Board;
use Game::Reversi::Move;
use Game::Reversi::Opening;

# The historic opening: four placements on the centre four, capturing nothing.
#
# There is no reference implementation of this anywhere, on CPAN or off it:
# every Reversi engine in existence plays the Othello start. So every position
# in this file was derived by hand before any of it was written, and the
# derivation is in the comments so that it can be checked rather than trusted.
#
# Parentheses on every Test::More call whose first argument is a Class->method
# call: without them it parses as indirect object syntax and becomes
# Class->is(...), which fails in a way that reads like a fault in the module.

my $B = 'Game::Reversi::Board';
my $O = 'Game::Reversi::Opening';

sub sq   { return $B->square_of(split //, $_[0]) }
sub name { return $B->name_of($_[0]) }
sub names { return join ',', sort map { name($_) } @_ }

# Who holds what, as a canonical string, so two boards can be compared as
# positions rather than as histories.
sub picture {
	my ($board) = @_;
	return join ' ',
		'b:' . names(grep { ($board->[$_] // '') eq 'b' } 0 .. 63),
		'w:' . names(grep { ($board->[$_] // '') eq 'w' } 0 .. 63);
}

subtest 'the centre four' => sub {
	is_deeply([ sort { $a <=> $b } $O->centre ],
		[ sort { $a <=> $b } map { sq($_) } qw(d5 e5 d4 e4) ],
		'd5, e5, d4 and e4');
	is(scalar(() = $O->centre), 4, 'four of them');
	is($O->PLIES, 4, 'and four plies to fill them');

	ok($O->is_centre(sq('d4')), 'd4 is a centre square');
	ok(!$O->is_centre(sq('c4')), 'c4 is not');
	ok(!$O->is_centre(sq('a1')), 'nor is a corner');
	ok(!$O->is_centre(undef), 'nor is nothing');
	done_testing();
};

subtest 'Black moves first, which is the one thing every source agrees on' => sub {
	# WOF rule 1: "Black always moves first."
	is($O->first, 'b', 'Black');
	done_testing();
};

subtest 'the opening is over exactly when the centre is full' => sub {
	my $board = $O->board_for('historic');
	is(scalar(grep { defined } @$board), 0, 'the historic game starts empty');
	ok($O->in_opening($board), 'so it is in the opening');
	is($O->plies_left($board), 4, 'with four placements to come');

	my $colour = $O->first;
	for my $n (reverse 1 .. 4) {
		is($O->plies_left($board), $n, "$n placements left");
		my ($place) = $O->legal($board, $colour);
		$board = $O->apply($board, $place->square, $colour);
		$colour = $B->other($colour);
	}

	ok(!$O->in_opening($board), 'after four placements the opening is over');
	is($O->plies_left($board), 0, 'with none left');
	is(scalar(grep { defined } @$board), 4, 'and four discs down');
	done_testing();
};

subtest 'a placement offers the empty centre squares and nothing else' => sub {
	my $board = $O->board_for('historic');
	my @places = $O->legal($board, 'b');
	is(scalar @places, 4, 'four placements to start');
	is(names(map { $_->square } @places), 'd4,d5,e4,e5', 'the centre four');

	for my $place (@places) {
		is($place->phase, 'place', 'each is a placement');
		is($place->turned, 0, 'and turns nothing, because the opening captures nothing');
		is($place->colour, 'b', 'in the colour asked for');
	}

	$board = $O->apply($board, sq('d5'), 'b');
	is(names(map { $_->square } $O->legal($board, 'w')), 'd4,e4,e5',
		'the square just taken is no longer offered');
	done_testing();
};

# ---- the finding this file exists for ---------------------------------------

subtest 'the no-captures rule does real work, it is not decoration' => sub {
	# NOT IN THE PLAN, AND THE REASON THIS SUBTEST IS HERE.
	#
	# After only two placements the board can already contain a legal capture by
	# the ordinary rules of the game. Black on d5, White on e5: a disc at f5
	# runs west over e5, white, and ends on d5, black. Game::Reversi::Board
	# calls that a legal move, and it is, once the game has started.
	#
	# During the opening it must be refused, because "no captures are made". So
	# an implementation that simply asked the board for its legal moves during
	# the opening would offer f5 on ply three and be wrong in a way that still
	# looks like a working game.
	my $board = $O->board_for('historic');
	$board = $O->apply($board, sq('d5'), 'b');
	$board = $O->apply($board, sq('e5'), 'w');

	# First establish that the trap is real, rather than assuming it.
	my @by_the_rules = $B->legal_moves($board, 'b');
	ok(scalar @by_the_rules,
		'the ordinary rules already offer Black a capture two plies in');
	ok((grep { $_ == sq('f5') } @by_the_rules),
		'f5 among them, outflanking e5 back to d5');
	is_deeply([ $B->flips_for($board, sq('f5'), 'b') ], [ sq('e5') ],
		'and it really would turn a disc');

	# Now the rule.
	is(names(map { $_->square } $O->legal($board, 'b')), 'd4,e4',
		'but the opening offers only the two empty centre squares');
	ok(!(grep { $_->square == sq('f5') } $O->legal($board, 'b')),
		'f5 is not among them');

	my $error = $O->check($board, sq('f5'));
	ok($error, 'and placing there is refused');
	is($error->code, 'not_centre', 'as not_centre');
	done_testing();
};

# ---- all twenty four sequences ----------------------------------------------

subtest 'twenty four sequences collapse to exactly six positions' => sub {
	# Every order of the four squares is legal, so 4! = 24 sequences. A position
	# is fixed by which PAIR Black ends with, and each pair is reachable by two
	# orders of Black's discs times two of White's, so 24 / 4 = 6 positions.
	my @centre = sort { $a <=> $b } $O->centre;
	my @orders;
	my $permute;
	$permute = sub {
		my ($taken, $left) = @_;
		if (!@$left) { push @orders, [ @$taken ]; return }
		for my $i (0 .. $#$left) {
			my @rest = @$left;
			my ($one) = splice @rest, $i, 1;
			$permute->([ @$taken, $one ], \@rest);
		}
	};
	$permute->([], \@centre);
	is(scalar @orders, 24, 'twenty four placement sequences');

	my %position;
	for my $order (@orders) {
		my $board = $O->board_for('historic');
		my $colour = $O->first;
		for my $square (@$order) {
			$board = $O->apply($board, $square, $colour);
			$colour = $B->other($colour);
		}
		push @{ $position{ picture($board) } }, $order;
	}

	is(scalar keys %position, 6, 'which reach six distinct positions');
	is_deeply([ sort map { scalar @$_ } values %position ], [ (4) x 6 ],
		'each reachable exactly four ways, which accounts for all 24');

	# The six, named by the pair Black holds. Derived by hand: Black takes two
	# of the four squares, and the six ways to choose two from four are the two
	# diagonal pairs and the four adjacent ones.
	my @black = sort map { (split / /)[0] } keys %position;
	# Quoted rather than qw(), because these contain commas and qw() warns
	# "Possible attempt to separate words with commas" on them.
	is_deeply(\@black, [ sort
		'b:d4,d5', 'b:d4,e4', 'b:d4,e5', 'b:d5,e4', 'b:d5,e5', 'b:e4,e5'
	], 'and Black holds each of the six possible pairs, once');
	done_testing();
};

subtest 'none of the six leaves Black stranded on ply five' => sub {
	# THE ASSERTION THIS PHASE EXISTS TO MAKE. No source states it: the rule
	# books all describe the Othello start, so nobody has ever had to ask
	# whether the other five openings are playable.
	#
	# If one of them were dead the rule would need an escape hatch and the whole
	# phase would change shape, so it was derived on paper first. Each line
	# below is the move and the ray that makes it work.
	my %expect = (
		# Black holds        a move, and why it flips
		'd5,e4' => [ 'f5', 'west: e5 white, then d5 black' ],   # the Othello position
		'd4,e5' => [ 'e3', 'north: e4 white, then e5 black' ],
		'd4,e4' => [ 'd6', 'south: d5 white, then d4 black' ],
		'd5,e5' => [ 'd3', 'north: d4 white, then d5 black' ],
		'd4,d5' => [ 'f4', 'west: e4 white, then d4 black' ],
		'e4,e5' => [ 'c4', 'east: d4 white, then e4 black' ],
	);

	for my $pair (sort keys %expect) {
		my ($first, $second) = map { sq($_) } split /,/, $pair;
		my @white = grep { $_ != $first && $_ != $second } $O->centre;

		# Black places first and third, White second and fourth.
		my $board = $O->board_for('historic');
		$board = $O->apply($board, $first,     'b');
		$board = $O->apply($board, $white[0],  'w');
		$board = $O->apply($board, $second,    'b');
		$board = $O->apply($board, $white[1],  'w');

		ok(!$O->in_opening($board), "$pair: the opening is over");

		my ($move, $why) = @{ $expect{$pair} };
		my @legal = $B->legal_moves($board, 'b');
		ok(scalar @legal, "$pair: Black has a move at all, which is the point");
		ok((grep { $_ == sq($move) } @legal),
			"$pair: $move is one of them, $why");
		ok(scalar($B->flips_for($board, sq($move), 'b')),
			"$pair: and it turns something");
	}
	done_testing();
};

subtest 'the two shapes, and what makes them different games' => sub {
	# Up to rotation and reflection the six are two: two diagonal openings and
	# four parallel ones. Worth asserting because the count is the argument for
	# the historic rule being interesting rather than merely different.
	my %shape;
	for my $pair ('d5,e4', 'd4,e5', 'd4,e4', 'd5,e5', 'd4,d5', 'e4,e5') {
		my ($one, $two) = map { sq($_) } split /,/, $pair;
		my ($r1, $c1) = (int($one / 8), $one % 8);
		my ($r2, $c2) = (int($two / 8), $two % 8);
		$shape{ ($r1 != $r2 && $c1 != $c2) ? 'diagonal' : 'parallel' }++;
	}
	is($shape{diagonal}, 2, 'two diagonal openings, one of which is Othello');
	is($shape{parallel}, 4, 'and four parallel ones nobody has written about');
	done_testing();
};

# ---- refusals ---------------------------------------------------------------

subtest 'a placement off the centre four is refused' => sub {
	my $board = $O->board_for('historic');
	for my $bad (qw(a1 h8 c4 e6 d6)) {
		my $error = $O->check($board, sq($bad));
		ok($error, "$bad is refused");
		is($error->code, 'not_centre', "as not_centre");
	}
	my $error = $O->check($board, undef);
	ok($error, 'and so is nothing at all');
	is($error->code, 'not_centre', 'as not_centre');
	done_testing();
};

subtest 'a placement on an occupied centre square is refused' => sub {
	my $board = $O->board_for('historic');
	$board = $O->apply($board, sq('d4'), 'b');

	my $error = $O->check($board, sq('d4'));
	ok($error, 'the square just used is refused');
	is($error->code, 'square_taken', 'as square_taken');
	is_deeply([ sort { $a <=> $b } @{ $error->legal } ],
		[ sort { $a <=> $b } map { sq($_) } qw(d5 e5 e4) ],
		'and the error says what was open instead');

	ok(!$O->check($board, sq('e4')), 'while an empty one is not refused');
	done_testing();
};

subtest 'an error is returned, not thrown, but apply dies on one' => sub {
	my $board = $O->board_for('historic');

	# A refusal is a return value, so a caller never wraps a placement in eval.
	my $error = $O->check($board, sq('a1'));
	isa_ok($error, 'Game::Reversi::Error');
	ok($error->error, 'and it is true, so it can be tested directly');
	like($error->stringify, qr/not_centre/, 'it stringifies with its code');

	# By the time anything reaches apply the square came out of legal, so a bad
	# one is programmer error and dies.
	ok(!eval { $O->apply($board, sq('a1'), 'b'); 1 },
		'apply dies on a square check would refuse');
	like($@, qr/not_centre/, 'saying which rule it broke');
	done_testing();
};

subtest 'the opening captures nothing, ever' => sub {
	# The rule stated as an invariant over all 24 sequences rather than as one
	# example: at no point during any opening does a placement change the colour
	# of a disc already on the board.
	my @centre = $O->centre;
	my ($checked, @turned) = (0);
	for my $a (@centre) {
		for my $b (grep { $_ != $a } @centre) {
			for my $c (grep { $_ != $a && $_ != $b } @centre) {
				my ($d) = grep { $_ != $a && $_ != $b && $_ != $c } @centre;
				my $board = $O->board_for('historic');
				my $colour = $O->first;
				my %placed;
				for my $square ($a, $b, $c, $d) {
					$board = $O->apply($board, $square, $colour);
					$placed{$square} = $colour;
					# Every disc placed so far still holds the colour it was
					# placed in. A capture would have turned one of them.
					#
					# Collected rather than returned early: a bare return here
					# would leave the subtest without its plan, which reports as
					# a confusing failure instead of as this assertion failing.
					for my $was (sort keys %placed) {
						push @turned, name($was) . ' in ' . names($a, $b, $c, $d)
							if $board->[$was] ne $placed{$was};
					}
					$colour = $B->other($colour);
				}
				$checked++;
			}
		}
	}
	is($checked, 24, 'all 24 sequences played');
	is_deeply(\@turned, [], 'and no disc ever changed colour during any of them');
	done_testing();
};

done_testing();
