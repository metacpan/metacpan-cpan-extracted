package Game::Checkers::Bot;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Checkers::Squares;
use Game::Checkers::Notation;
use Game::Checkers::Rules;
use Game::Checkers::Move;

our $VERSION = '0.01';

use constant {
	MATE => 10_000,
	INFINITY => 1_000_000,
	MAX_EXTENSION => 8,
	MAX_PV => 20,
	NO_PROGRESS_PLIES => 80,
	EXACT => 0,
	LOWER => 1,
	UPPER => -1,
};

use constant {
	RM_FROM => Game::Checkers::Move::RM_FROM,
	RM_TO => Game::Checkers::Move::RM_TO,
	RM_PROMOTED => Game::Checkers::Move::RM_PROMOTED,
	RM_PATH => Game::Checkers::Move::RM_PATH,
	RM_CAPTURES => Game::Checkers::Move::RM_CAPTURES,
	RM_KING => Game::Checkers::Move::RM_KING,
};

our (%WEIGHT, %LEVEL);

# has runs at compile time, and so does anything a level table is read by, so
# these are built here rather than in the file body
BEGIN {
	%WEIGHT = (
		man => 100,
		king => 160,
		advance => 4,
		back_rank => 8,
		centre => 4,
		edge => -6,
		mobility => 2,
		trapped_king => -20,
		chase => -2,
	);

	%LEVEL = (
		1 => { depth => 2, nodes => 300, jitter => 1 },
		2 => { depth => 4, nodes => 2_000, jitter => 1 },
		3 => { depth => 7, nodes => 20_000, jitter => 0 },
		4 => { depth => 10, nodes => 120_000, jitter => 0 },
		5 => { depth => 13, nodes => 600_000, jitter => 0 },
	);
}

my $ROW = \@Game::Checkers::Squares::ROW;
my $COL = \@Game::Checkers::Squares::COL;
my $STEP = \@Game::Checkers::Squares::STEP;
my $JUMP_OVER = \@Game::Checkers::Squares::JUMP_OVER;
my $JUMP_TO = \@Game::Checkers::Squares::JUMP_TO;

my @DIRS = @Game::Checkers::Squares::DIRS;

my %FORWARD = (
	1 => [Game::Checkers::Squares::SE(), Game::Checkers::Squares::SW()],
	-1 => [Game::Checkers::Squares::NE(), Game::Checkers::Squares::NW()],
);

has level => (
	is => 'rw',
	isa => Int,
	default => 3
);

has seed => (
	is => 'rw',
	isa => Int,
	default => 0
);

has transposition => (
	is => 'rw',
	isa => Bool,
	default => 1
);

has last_search => (
	is => 'rw'
);

sub choose {
	my ($self, $game) = @_;
	return undef if $game->result;

	my $legal = $game->legal_moves;
	return undef unless @{$legal};

	if (@{$legal} == 1) {
		$self->last_search({
			depth => 0,
			nodes => 0,
			score => undef,
			forced => 1,
			move => $legal->[0]->notation,
			pv => [$legal->[0]->notation]
		});
		return $legal->[0];
	}

	my $spec = $LEVEL{$self->level}
		or die 'level must be 1 .. 5, got ' . $self->level;

	my $position = [@{$game->board->position}];
	my $turn = $game->turn;
	my $state = {
		nodes => 0,
		budget => $spec->{nodes},
		jitter => $spec->{jitter},
		table => {},
		history => {},
		killers => [],
		seen => $self->_seen($game),
		aborted => 0
	};

	my ($best, $score, $reached);
	for my $depth (1 .. $spec->{depth}) {
		last if $state->{nodes} > $state->{budget};
		$state->{aborted} = 0;
		my ($iteration_score, $move) = $self->_root(
			$state, $position, $turn, $depth, $game->no_progress, $game->ply
		);
		last if $state->{aborted} || !$move;
		($best, $score, $reached) = ($move, $iteration_score, $depth);
	}

	my $notation = $best
		? Game::Checkers::Notation::format_move({
			squares => $best->[RM_PATH],
			jump => scalar @{$best->[RM_CAPTURES]}
		})
		: $legal->[0]->notation;

	$self->last_search({
		depth => $reached || 0,
		nodes => $state->{nodes},
		score => $score,
		forced => 0,
		move => $notation,
		pv => $self->_pv($state, $position, $turn, $best)
	});

	# the move handed back is the one out of the game's own legal list, so a
	# caller may compare it by reference as well as by notation
	for my $move (@{$legal}) {
		return $move if $move->notation eq $notation;
	}
	return $legal->[0];
}

sub _seen {
	my ($self, $game) = @_;
	my ($position, $turn) =
		Game::Checkers::Notation::position_from_fen($game->fen);
	my %seen = (_key($position, $turn) => 1);
	for my $move (@{$game->history}) {
		Game::Checkers::Rules::apply($position, $move->to_raw);
		$turn = $turn eq 'black' ? 'white' : 'black';
		$seen{_key($position, $turn)}++;
	}
	return \%seen;
}

sub _key {
	my ($position, $turn) = @_;
	return pack('c32', @{$position}[1 .. 32]) . $turn;
}

sub _root {
	my ($self, $state, $position, $turn, $depth, $no_progress, $ply) = @_;
	my $moves = Game::Checkers::Rules::generate($position, $turn);
	return (undef, undef) unless @{$moves};

	my $forced = @{$moves->[0][RM_CAPTURES]} ? 1 : 0;
	my ($child_depth, $child_extension) = $forced
		? ($depth, 1)
		: ($depth - 1, 0);

	my $alpha = -INFINITY;
	my ($best, $best_score);
	for my $raw (@{$self->_ordered($state, $moves, 0, undef)}) {
		# a move that fails low comes back as a bound rather than a score, and
		# a bound plus a jitter is how a losing move gets chosen. So when the
		# jitter is on every root move is searched with the full window and the
		# scores it is added to are all exact.
		my $bound = $state->{jitter} ? -INFINITY : $alpha;
		my $score = $self->_child(
			$state, $position, $turn, $raw,
			$child_depth, -INFINITY, -$bound, 1, $child_extension, $no_progress
		);
		return (undef, undef) if $state->{aborted};

		$score += _jitter($self->seed, $ply, $raw) if $state->{jitter};

		if (!defined $best_score || $score > $best_score) {
			($best, $best_score) = ($raw, $score);
			$alpha = $score if $score > $alpha && !$state->{jitter};
		}
	}
	return ($best_score, $best);
}

sub _child {
	my ($self, $state, $position, $turn, $raw, $depth, $alpha, $beta, $ply,
		$extension, $no_progress) = @_;

	my $next = $turn eq 'black' ? 'white' : 'black';
	my $progress = Game::Checkers::Rules::progress($raw) ? 0 : $no_progress + 1;

	Game::Checkers::Rules::apply($position, $raw);
	my $key = _key($position, $next);
	$state->{seen}{$key}++;

	my $score = -$self->_search(
		$state, $position, $next, $depth, $alpha, $beta, $ply, $extension, $progress
	);

	delete $state->{seen}{$key} unless --$state->{seen}{$key};
	Game::Checkers::Rules::unapply($position, $raw);
	return $score;
}

sub _search {
	my ($self, $state, $position, $turn, $depth, $alpha, $beta, $ply,
		$extension, $no_progress) = @_;

	$state->{nodes}++;
	if ($state->{nodes} >= $state->{budget}) {
		$state->{aborted} = 1;
		return 0;
	}

	my $key = _key($position, $turn);
	return 0 if ($state->{seen}{$key} || 0) >= 3;
	return 0 if $no_progress >= NO_PROGRESS_PLIES;

	my $entry = $self->transposition ? $state->{table}{$key} : undef;
	my $table_move;
	if ($entry) {
		$table_move = $entry->[3];
		if ($entry->[0] >= $depth && abs($entry->[1]) < MATE - 100) {
			return $entry->[1] if $entry->[2] == EXACT;
			return $entry->[1] if $entry->[2] == LOWER && $entry->[1] >= $beta;
			return $entry->[1] if $entry->[2] == UPPER && $entry->[1] <= $alpha;
		}
	}

	my $moves = Game::Checkers::Rules::generate($position, $turn);
	return -MATE + $ply unless @{$moves};

	my $forced = @{$moves->[0][RM_CAPTURES]} ? 1 : 0;
	my $extend = $forced && $extension < MAX_EXTENSION ? 1 : 0;
	return _evaluate($position, $turn) if $depth <= 0 && !$extend;

	my ($child_depth, $child_extension) = $extend
		? ($depth, $extension + 1)
		: ($depth - 1, $extension);

	my $original = $alpha;
	my ($best_score, $best_move) = (-INFINITY, undef);
	for my $raw (@{$self->_ordered($state, $moves, $ply, $table_move)}) {
		my $score = $self->_child(
			$state, $position, $turn, $raw,
			$child_depth, -$beta, -$alpha, $ply + 1, $child_extension, $no_progress
		);
		return 0 if $state->{aborted};

		if ($score > $best_score) {
			($best_score, $best_move) = ($score, $raw);
			$alpha = $score if $score > $alpha;
		}
		next if $alpha < $beta;

		my $name = $raw->[RM_FROM] . '-' . $raw->[RM_TO];
		$state->{history}{$name} += $depth * $depth;
		my $killers = $state->{killers}[$ply] ||= [];
		unshift @{$killers}, $name
			unless @{$killers} && $killers->[0] eq $name;
		pop @{$killers} while @{$killers} > 2;
		last;
	}

	if ($self->transposition) {
		my $flag = $best_score <= $original ? UPPER
			: $best_score >= $beta ? LOWER
			: EXACT;
		$state->{table}{$key} = [
			$depth, $best_score, $flag,
			$best_move && [@{$best_move}]
		];
	}
	return $best_score;
}

sub _ordered {
	my ($self, $state, $moves, $ply, $table_move) = @_;
	my $wanted = $table_move
		? join('.', @{$table_move->[RM_PATH]})
		: '';
	my $killers = $state->{killers}[$ply] || [];
	my $history = $state->{history};

	my @scored;
	for my $raw (@{$moves}) {
		my $name = $raw->[RM_FROM] . '-' . $raw->[RM_TO];
		my $score = 0;
		$score += 1_000_000 if $wanted && join('.', @{$raw->[RM_PATH]}) eq $wanted;
		$score += 1_000 + (10 * scalar @{$raw->[RM_CAPTURES]}) if @{$raw->[RM_CAPTURES]};
		$score += 500 if $raw->[RM_PROMOTED];
		$score += 400 if @{$killers} && $killers->[0] eq $name;
		$score += 300 if @{$killers} > 1 && $killers->[1] eq $name;
		$score += $history->{$name} || 0;
		push @scored, [$score, $raw];
	}
	return [map { $_->[1] } sort { $b->[0] <=> $a->[0] } @scored];
}

sub _pv {
	my ($self, $state, $position, $turn, $first) = @_;
	my @pv;
	my @undo;

	# the root is searched outside the table, so the line starts with the move
	# choose settled on and the table carries it from there
	my $raw = $first;
	while (@pv < MAX_PV) {
		unless ($raw) {
			my $entry = $state->{table}{_key($position, $turn)} or last;
			$raw = $entry->[3] or last;
		}
		my $legal = Game::Checkers::Rules::generate($position, $turn);
		my $path = join '.', @{$raw->[RM_PATH]};
		last unless grep { join('.', @{$_->[RM_PATH]}) eq $path } @{$legal};
		push @pv, Game::Checkers::Notation::format_move({
			squares => $raw->[RM_PATH],
			jump => scalar @{$raw->[RM_CAPTURES]}
		});
		Game::Checkers::Rules::apply($position, $raw);
		push @undo, $raw;
		$turn = $turn eq 'black' ? 'white' : 'black';
		undef $raw;
	}
	Game::Checkers::Rules::unapply($position, pop @undo) while @undo;
	return \@pv;
}

sub _jitter {
	my ($seed, $ply, $raw) = @_;
	my $string = $seed . ':' . $ply . ':' . join '.', @{$raw->[RM_PATH]};
	my $hash = 0;
	$hash = (($hash * 33) + ord) % 65_521 for split //, $string;
	return $hash % 25;
}

sub _evaluate {
	my ($position, $turn) = @_;
	my $score = 0;
	my (%men, %kings, %back, %mobility, @kings, @pieces);

	for my $square (1 .. 32) {
		my $value = $position->[$square] or next;
		my $sign = $value > 0 ? 1 : -1;
		my $king = abs($value) == 2 ? 1 : 0;
		my $row = $ROW->[$square];
		my $col = $COL->[$square];

		push @{$pieces[$sign > 0 ? 0 : 1]}, $square;
		if ($king) {
			$kings{$sign}++;
			$score += $sign * $WEIGHT{king};
			push @{$kings[$sign > 0 ? 0 : 1]}, $square;
		} else {
			$men{$sign}++;
			$score += $sign * $WEIGHT{man};
			$score += $sign * $WEIGHT{advance} * ($sign > 0 ? $row : 7 - $row);
			$score += $sign * $WEIGHT{edge} if $col == 0 || $col == 7;
			$back{$sign}++ if ($sign > 0 ? $row : 7 - $row) == 0;
		}
		$score += $sign * $WEIGHT{centre} if $col == 3 || $col == 4;

		# moves available to this piece, counted without expanding a jump
		# sequence: a cheap stand in for mobility that costs four lookups
		my $moves = 0;
		my $base = $square * 4;
		for my $dir ($king ? @DIRS : @{$FORWARD{$sign}}) {
			my $step = $STEP->[$base + $dir];
			$moves++ if $step && !$position->[$step];
			my $landing = $JUMP_TO->[$base + $dir] or next;
			next if $position->[$landing];
			my $victim = $position->[$JUMP_OVER->[$base + $dir]] or next;
			$moves++ if ($victim > 0 ? 1 : -1) != $sign;
		}
		$mobility{$sign} += $moves;
		$score += $sign * $WEIGHT{trapped_king} if $king && !$moves;
	}

	# a home row is worth holding only while there is a man that could crown
	$score += $WEIGHT{back_rank} * ($back{1} || 0) if $men{-1};
	$score -= $WEIGHT{back_rank} * ($back{-1} || 0) if $men{1};
	$score += $WEIGHT{mobility} * (($mobility{1} || 0) - ($mobility{-1} || 0));

	my $total = ($men{1} || 0) + ($kings{1} || 0) + ($men{-1} || 0) + ($kings{-1} || 0);
	if ($total <= 6 && $total) {
		my $black = ($men{1} || 0) * $WEIGHT{man} + ($kings{1} || 0) * $WEIGHT{king};
		my $white = ($men{-1} || 0) * $WEIGHT{man} + ($kings{-1} || 0) * $WEIGHT{king};
		my $stronger = $black > $white ? 0 : $white > $black ? 1 : undef;
		if (defined $stronger && $kings[$stronger]) {
			my $distance = 0;
			for my $king (@{$kings[$stronger]}) {
				for my $enemy (@{$pieces[$stronger ? 0 : 1] || []}) {
					my $rows = abs($ROW->[$king] - $ROW->[$enemy]);
					my $cols = abs($COL->[$king] - $COL->[$enemy]);
					$distance += $rows > $cols ? $rows : $cols;
				}
			}
			$score += ($stronger ? -1 : 1) * $WEIGHT{chase} * $distance;
		}
	}

	return $turn eq 'black' ? $score : -$score;
}

1;

__END__

=head1 NAME

Game::Checkers::Bot - an opponent, at five strengths

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Checkers;
	use Game::Checkers::Bot;

	my $game = Game::Checkers->new;
	my $bot = Game::Checkers::Bot->new(level => 3, seed => 12345);

	while ($game->status eq 'active') {
		my $move = $bot->choose($game);
		$game->move($move);
	}

	$bot->last_search->{nodes};   # what the last move cost

=head1 DESCRIPTION

Negamax with alpha beta, iterative deepening to a node budget, and an evaluation
of material, position and mobility.

C<choose> is a pure function of the position, the side to move, the level and the
seed. The same four give the same move on every machine and every perl, because a
game log that cannot be replayed is not a game log. Nothing here reads a clock,
calls C<rand>, or allocates a L<Game::Checkers::Move> except the one it returns:
the search runs on the raw position array through L<Game::Checkers::Rules>.

=head2 The search

=over

=item *

B<The budget is in nodes, never in seconds.> A loaded machine must produce the
same move as an idle one, so no part of this module knows what time it is. An
iteration that runs out of budget is discarded whole, and the move comes from the
last iteration that finished.

=item *

B<A forced capture does not cost depth.> When every legal move is a jump the
position is not a choice, so the search goes on without decrementing, up to eight
extension plies from any node. Without that, a search stops in the middle of an
exchange and reads a position as a piece up when it is about to be a piece down.

=item *

B<Move ordering> at every node: the transposition table's move, then jumps by how
much they take, then promotions, then two killer moves for the ply, then the
history heuristic, then generation order.

=item *

B<The transposition table> is a plain hash keyed by the packed position and the
side to move, emptied at the start of every C<choose>, so one search cannot
influence the next. A cutoff is taken only from an entry at least as deep as the
node wants, and never from a score near mate, whose value depends on how far away
it is.

=item *

B<Terminal nodes.> A side with no move has lost, scored so that a quicker win
beats a slower one. A repetition or the no progress rule scores nothing, counted
against the game's own history as well as the search path, so the bot neither
walks into a draw while winning nor misses one while losing.

=back

=head2 The evaluation

In hundredths of a man, from the side to move's point of view:

=over

=item *

Material: a man 100, a king 160.

=item *

A man is worth 4 more for every row it has advanced, 6 less on the outside file,
and every piece is worth 4 more on the two centre files.

=item *

A piece still on its home row is worth 8, but only while the other side has a man
that could crown there.

=item *

Mobility is 2 a move, counted as the steps and jumps each piece has rather than
by generating the sequences, which costs four lookups a piece instead of a move
list at every leaf. A king with nothing at all is worth 20 less.

=item *

With six pieces or fewer on the board, the side that is ahead loses 2 for every
square between its kings and the enemy. That term is what makes a won ending get
won instead of shuffled into the forty move draw.

=back

The weights are in C<%WEIGHT> and the search does not know what is in it.

=head2 The levels

	level   depth   nodes     jitter
	  1       2        300    yes
	  2       4      2_000    yes
	  3       7     20_000    no
	  4      10    120_000    no
	  5      13    600_000    no

Levels 1 and 2 add a deterministic offset of up to a quarter of a man to each
move at the root, derived from the seed and the move, so an easy opponent does
not play the same game every time while staying reproducible. Level 3 and above
have none: there the point is strength, and a move that is a pure function of the
position is what a replay wants.

=head1 PROPERTIES

=head2 level

Read and write integer 1 to 5, 3 by default.

	$bot->level(5);

=head2 seed

Read and write integer feeding the jitter at levels 1 and 2. It changes nothing
at level 3 and above.

	$bot->seed(12345);

=head2 transposition

Read and write boolean, true by default. Turning it off makes the search slower
and must not change the move it chooses, which is what the test asserts.

	$bot->transposition(0);

=head2 last_search

Read and write hashref describing the last C<choose>: C<depth> reached, C<nodes>
visited, C<score> in hundredths of a man, C<move>, C<pv> as a list of notations,
and C<forced> when there was only one legal move and no search happened.

	$bot->last_search->{pv};

=head1 FUNCTIONS

=head2 choose

The move the bot would play, as one of the L<Game::Checkers::Move> objects in the
game's own legal list, or undef when the game is over. A position with one legal
move returns it without searching.

	my $move = $bot->choose($game);

=head1 CONSTANTS

C<MATE>, C<INFINITY>, C<MAX_EXTENSION>, C<MAX_PV>, C<NO_PROGRESS_PLIES> and the
transposition flags C<EXACT>, C<LOWER> and C<UPPER>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-checkers at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Checkers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Checkers

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Checkers>

=item * Search CPAN

L<https://metacpan.org/release/Game-Checkers>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
