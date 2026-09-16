#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes;
use Game::Dominoes::Layout;
use Game::Dominoes::Scoring qw(count score_for);
use Game::Dominoes::Set qw(tile_of PIPS SIZE);
use Game::Dominoes::Tile;

plan tests => 4;

# The vectors in this file are the ones somebody else derived. Everything
# asserted here was published before this distribution existed, which is the
# whole point: a number our own code produced and we then pinned would prove
# only that the code agrees with itself.

subtest 'the five opening tiles that score at once' => sub {
	plan tests => 8;

	# Wikipedia, Muggins: "If it is a 6-4, double-five, 5-0, 4-1, or 3-2, the
	# initial count is evenly divisible by five and so the player scores."
	#
	# Muggins is a different game from All Fives (it has no spinner), but an
	# opening lead is one tile on an empty table in both, so the arithmetic
	# transfers and is hand-checkable: 10, 10, 5, 5, 5.
	my @cited = ([ 6, 4 ], [ 5, 5 ], [ 5, 0 ], [ 4, 1 ], [ 3, 2 ]);

	for my $pair (@cited) {
		my $layout = Game::Dominoes::Layout->new;
		$layout->place(Game::Dominoes::Tile->of(@$pair), 'L');
		ok score_for(count($layout)) > 0,
			"$pair->[0]-$pair->[1] scores as an opening lead";
	}

	# Found by the engine rather than asserted from the list, so that a sixth
	# scoring tile would fail here rather than pass quietly.
	my @found;
	for my $id (1 .. SIZE) {
		my $layout = Game::Dominoes::Layout->new;
		$layout->place(tile_of($id), 'L');
		push @found, tile_of($id)->stringify if score_for(count($layout)) > 0;
	}

	is scalar(@found), 5, 'exactly five tiles score as an opening lead';
	is_deeply [ sort @found ],
		[ sort map { Game::Dominoes::Tile->of(@$_)->stringify } @cited ],
		'and they are the five the source names';

	# The double blank is absent from the published list, which is the
	# evidence for nought not being a score even though it divides by five.
	my $blank = Game::Dominoes::Layout->new;
	$blank->place(Game::Dominoes::Tile->of(0, 0), 'L');
	is score_for(count($blank)), 0, 'and the double blank is not among them';
};

subtest 'the set holds 168 pips, at every ply of every hand' => sub {
	plan tests => 4;

	# Pagat, The Mathematics of Dominoes: "the double six set has 168 pips in
	# it". Hand-derivable as 8 x (0+1+2+3+4+5+6) = 168, because each face
	# appears eight times across the set.
	my $total = 0;
	$total += tile_of($_)->pips for 1 .. SIZE;
	is $total, PIPS, 'the set adds up to 168';

	# As a running invariant it catches a lost tile, a duplicated draw and a
	# mis-set hand size in one assertion.
	for my $players (2, 3, 4) {
		my $g = Game::Dominoes->new(seed => 'e' x 32, players => $players);
		my ($bad, $n) = (0, 0);
		while ($g->status eq 'active' && $n++ < 20000) {
			my $sum = $g->layout->pips + $g->boneyard->pips;
			$sum += $g->hand($_)->pips for $g->seats;
			$bad++ if $sum != PIPS;
			my $moves = $g->legal($g->turn);
			last unless @$moves;
			$g->play($g->turn, $moves->[0]);
		}
		is $bad, 0, "$players players: 168 pips at every ply of a whole game";
	}
};

subtest "Clark's Law: a blocked hand leaves an even number of pips" => sub {
	plan tests => 3;

	# Pagat, The Mathematics of Dominoes: "in a blocked game of single spinner
	# dominoes, the sum of the four arms of the tableau must always total to
	# an even number", and "The first corollary of Clark's Law is that the sum
	# of the four hands in a blocked game is always an even number. This is
	# because the double six set has 168 pips in it, which is an even number
	# and an even number minus an even number is an even number."
	#
	# A published parity invariant needs no expected value pinned, so it is a
	# wide net over the layout and the hands at once, and it is checked
	# against every blocked hand the suite happens to produce.
	my ($blocked, $odd, $with_spinner) = (0, 0, 0);

	for my $seed (1 .. 300) {
		for my $players (2, 3, 4) {
			my $g = Game::Dominoes->new(
				seed => sprintf('%032d', $seed), players => $players
			);
			my $start = $g->hand_number;
			my ($n, $spinner) = (0, undef);
			while ($g->status eq 'active' && $g->hand_number == $start && $n++ < 300) {
				my $moves = $g->legal($g->turn);
				last unless @$moves;
				$g->play($g->turn, $moves->[0]);
				$spinner = $g->layout->spinner if $g->hand_number == $start;
			}

			my ($end) = grep { $_->{kind} eq 'hand_end' } @{ $g->history };
			next unless $end && ($end->{reason} // '') =~ /\Ablocked/;

			$blocked++;
			$with_spinner++ if defined $spinner;
			my $pips = 0;
			$pips += $_ for values %{ $end->{pips} };
			$odd++ if $pips % 2;
		}
	}

	cmp_ok $blocked, '>', 40, 'the sweep produced enough blocked hands to mean something';
	cmp_ok $with_spinner, '>', 0, 'including hands with a spinner, which is what the law covers';
	is $odd, 0, "and not one of the $blocked blocked hands left an odd pip total";
};

subtest 'a double at an end is what makes the parity work' => sub {
	plan tests => 2;

	# Clark's derivation: "doubles are always even, so the spinner will have
	# four identical halves against it. Then in each arm, the ends of the
	# tiles must be paired, so they are even until you get to the end of an
	# arm. If the arm ends in a double, then the exposed tile is even."
	#
	# So a double contributing both halves is not a scoring quirk bolted on:
	# it is the same fact the parity law rests on.
	my $layout = Game::Dominoes::Layout->new;
	$layout->place(Game::Dominoes::Tile->of(5, 5), 'L');
	is count($layout) % 2, 0, 'a double alone contributes an even count';

	$layout->place(Game::Dominoes::Tile->of(5, 2), 'L');
	$layout->place(Game::Dominoes::Tile->of(5, 3), 'R');
	is count($layout), 5, 'and once it is interior the ends speak for themselves';
};
