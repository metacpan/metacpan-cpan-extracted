package Invariants;

use 5.010;
use strict;
use warnings;

use Test::More ();
use Game::Go::Rules;

our $VERSION = '0.01';

# EVERY STRUCTURE THE C MAINTAINS INCREMENTALLY, RE-DERIVED IN PERL FROM THE ONE
# THING THAT IS NOT INCREMENTAL: the colour at each point.
#
# This is as close as decision four lets us get to a differential oracle. There
# is no second board implementation to disagree with the first, but the chain
# membership, the liberty counts and the zobrist key are all DERIVED quantities,
# and a derived quantity can be recomputed from scratch, in another language, by
# code that shares nothing with the original. The C keeps them up to date a move
# at a time; this file works them out from the whole position; and a
# disagreement is a bug in the maintenance, which is exactly the class of bug
# decision four exposes us to.
#
# The failure mode being hunted has no other symptom. An incremental counter
# that drifts leaves the board looking plausible, lets every legality test pass,
# and shows up only as a bot that plays slightly badly for reasons nothing
# reports.
#
# IT TAKES A Game::Go::Board AND WORKS IN COLUMNS AND ROWS, which is not a
# convenience. The engine's neighbour arithmetic is safe because of the sentinel
# ring around its padded array, and a checker that walked the same padded array
# would be trusting the very thing it is meant to be checking. Doing its own
# bounds test in column and row space means the edge is tested twice by two
# different mechanisms rather than once by one.

my $B = Game::Go::Rules::BLACK;
my $W = Game::Go::Rules::WHITE;

sub _neighbours {
	my ($board, $col, $row) = @_;
	my $size = $board->size;
	my @out;
	for my $d ([-1, 0], [1, 0], [0, -1], [0, 1]) {
		my ($c, $r) = ($col + $d->[0], $row + $d->[1]);
		next if $c < 0 || $r < 0 || $c >= $size || $r >= $size;
		push @out, [$c, $r];
	}
	return @out;
}

sub _stones {
	my ($board) = @_;
	my $size = $board->size;
	my @pts;
	for my $row (0 .. $size - 1) {
		for my $col (0 .. $size - 1) {
			my $at = $board->at($col, $row);
			push @pts, [$col, $row] if $at == $B || $at == $W;
		}
	}
	return @pts;
}

# The chains, worked out by flood fill over same-coloured neighbours, with no
# reference to the C's chain_root, chain_next or chain_size at all. Returns a
# list of { colour, points => [[col,row],...], libs => n }, each point list
# sorted so it can be compared as a string.
sub chains {
	my ($board) = @_;

	my %colour;
	$colour{"$_->[0],$_->[1]"} = $board->at(@$_) for _stones($board);

	my %seen;
	my @chains;

	for my $start (sort keys %colour) {
		next if $seen{$start};
		my $c = $colour{$start};

		my @stack = ([ split /,/, $start ]);
		my (@points, %in, %libs);
		$seen{$start} = $in{$start} = 1;

		while (@stack) {
			my $pt = pop @stack;
			push @points, $pt;
			for my $n (_neighbours($board, @$pt)) {
				my $key = "$n->[0],$n->[1]";
				my $at = $board->at(@$n);
				if ($at == Game::Go::Rules::EMPTY) { $libs{$key} = 1; next }
				next unless $at == $c;
				next if $in{$key};
				$in{$key} = $seen{$key} = 1;
				push @stack, $n;
			}
		}

		push @chains, {
			colour => $c,
			points => [ sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @points ],
			libs   => scalar keys %libs,
		};
	}

	return @chains;
}

# A chain's point list as one comparable string.
sub _spell { return join ' ', map { "$_->[0],$_->[1]" } @{ $_[0] } }

# The zobrist key, XORed from scratch over every stone.
#
# IT IS DONE IN TWO 32-BIT HALVES ON PURPOSE. A 64-bit value on a perl with
# 32-bit integers goes through an NV and loses bits, and the whole point of this
# function is to agree with the C exactly. Halves keep it in xor alone, which is
# the same reason the engine's generator is xorshift32.
sub zobrist_hex {
	my ($board) = @_;

	my ($hi, $lo) = (0, 0);
	for my $pt (_stones($board)) {
		my $hex = $board->zobrist_hex($board->at(@$pt), @$pt);
		$hi ^= hex substr($hex, 0, 8);
		$lo ^= hex substr($hex, 8, 8);
	}

	return sprintf '%08x%08x', $hi & 0xFFFFFFFF, $lo & 0xFFFFFFFF;
}

# THE WORK, WITH NO TAP IN IT. Returns what Perl derived beside what the engine
# says, so a caller can assert on it (check, below) or count disagreements over
# a hundred thousand positions without emitting a hundred thousand ok lines.
sub audit {
	my ($board) = @_;

	my @chains = chains($board);

	my ($nb, $nw) = (0, 0);
	my %by_point;
	for my $chain (@chains) {
		$chain->{colour} == $B
			? ($nb += @{ $chain->{points} })
			: ($nw += @{ $chain->{points} });
		$by_point{"$_->[0],$_->[1]"} = $chain for @{ $chain->{points} };
	}

	# Every stone belongs to exactly one chain, and the C agrees which.
	my ($wrong_chain, $wrong_size) = (0, 0);
	for my $key (sort keys %by_point) {
		my ($col, $row) = split /,/, $key;
		my $mine = $by_point{$key};
		$wrong_size++ unless $board->chain_size($col, $row) == scalar @{ $mine->{points} };

		my @theirs = sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] }
			@{ $board->chain_at($col, $row) };
		$wrong_chain++ unless _spell(\@theirs) eq _spell($mine->{points});
	}

	# The liberty counts, recomputed from scratch.
	my ($wrong_libs, $dead_on_board) = (0, 0);
	for my $chain (@chains) {
		my ($col, $row) = @{ $chain->{points}[0] };
		$wrong_libs++ unless $board->libs($col, $row) == $chain->{libs};
		# A CHAIN WITH NO LIBERTIES CANNOT BE ON THE BOARD. Capture is not
		# optional and suicide is refused, so a zero here means a stone that
		# should have been lifted was not.
		$dead_on_board++ if $chain->{libs} == 0;
	}

	return {
		stones_b      => $board->stones($B),  derived_b => $nb,
		stones_w      => $board->stones($W),  derived_w => $nw,
		wrong_chain   => $wrong_chain,
		wrong_size    => $wrong_size,
		wrong_libs    => $wrong_libs,
		dead_on_board => $dead_on_board,
		hash          => $board->hash_hex,
		derived_hash  => zobrist_hex($board),
		chains        => scalar @chains,
	};
}

# Whether an audit found anything, as a list of one-line complaints. Empty means
# the engine and Perl agree about everything.
sub complaints {
	my ($a) = @_;
	my @out;
	push @out, "black stone count: engine $a->{stones_b}, derived $a->{derived_b}"
		if $a->{stones_b} != $a->{derived_b};
	push @out, "white stone count: engine $a->{stones_w}, derived $a->{derived_w}"
		if $a->{stones_w} != $a->{derived_w};
	push @out, "$a->{wrong_chain} chains are not the ones Perl derives" if $a->{wrong_chain};
	push @out, "$a->{wrong_size} chain sizes disagree" if $a->{wrong_size};
	push @out, "$a->{wrong_libs} liberty counts disagree" if $a->{wrong_libs};
	push @out, "$a->{dead_on_board} chains on the board have no liberties" if $a->{dead_on_board};
	push @out, "hash: engine $a->{hash}, derived $a->{derived_hash}"
		if $a->{hash} ne $a->{derived_hash};
	return @out;
}

# The whole check, as ASSERTIONS_PER_CHECK assertions. $label names the position
# so a failure inside a long loop says which move it was.
sub check {
	my ($board, $label) = @_;
	$label = defined $label ? $label : 'position';

	my $a = audit($board);

	Test::More::is($a->{stones_b}, $a->{derived_b}, "$label: black stone count");
	Test::More::is($a->{stones_w}, $a->{derived_w}, "$label: white stone count");
	Test::More::is($a->{wrong_chain}, 0, "$label: every chain is the one Perl derives");
	Test::More::is($a->{wrong_size}, 0, "$label: and the size the C keeps matches it");
	Test::More::is($a->{wrong_libs}, 0, "$label: every liberty count is the recounted one");
	Test::More::is($a->{dead_on_board}, 0, "$label: no chain on the board has zero liberties");
	Test::More::is($a->{hash}, $a->{derived_hash},
		"$label: the hash is the one the stones add up to");

	return;
}

# So a caller can plan, or size a loop against a budget.
use constant ASSERTIONS_PER_CHECK => 7;

1;
