package Game::Merrills::Bot;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Merrills::Points;
use Game::Merrills::Notation;
use Game::Merrills::Rules;
use Game::Merrills::Move;

our $VERSION = '0.01';

use constant {
	WIN => 10_000,
	INFINITY => 1_000_000,
	MAX_EXTENSION => 2,
	MAX_PV => 20,
	EXACT => 0,
	LOWER => 1,
	UPPER => -1,
};

use constant {
	RM_FROM => Game::Merrills::Move::RM_FROM,
	RM_TO => Game::Merrills::Move::RM_TO,
	RM_REMOVE => Game::Merrills::Move::RM_REMOVE,
	RM_CLOSES => Game::Merrills::Move::RM_CLOSES,
	HAND_WHITE => Game::Merrills::Rules::HAND_WHITE,
	HAND_BLACK => Game::Merrills::Rules::HAND_BLACK,
};

our (%LEVEL, $MAN, $MILL, $OPEN_TWO, $REACH, $RUNNING, $BLOCKED, $MOBILITY, $JUNCTION);

BEGIN {
	%LEVEL = (
		1 => { depth => 1, nodes => 300, jitter => 1 },
		2 => { depth => 3, nodes => 3_000, jitter => 1 },
		3 => { depth => 5, nodes => 20_000, jitter => 0 },
		4 => { depth => 7, nodes => 100_000, jitter => 0 },
		5 => { depth => 9, nodes => 400_000, jitter => 0 },
	);

	$MAN = 100;
	$MILL = 12;
	$OPEN_TWO = 8;
	$REACH = 10;
	$RUNNING = 30;
	$BLOCKED = 6;
	$MOBILITY = 2;
	$JUNCTION = 3;
}

my %OTHER = (white => 'black', black => 'white');
my %VALUE = (white => 1, black => -1);

my $ADJACENT = \@Game::Merrills::Points::ADJACENT;
my $MILLS = \@Game::Merrills::Points::MILLS;
my $MILLS_OF = \@Game::Merrills::Points::MILLS_OF;

has level => (
	is => 'ro',
	isa => Int,
	default => 3
);

has seed => (
	is => 'ro',
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

sub BUILD {
	my ($self) = @_;
	die 'level must be 1 .. 5, got ' . (defined $self->level ? "'" . $self->level . "'" : 'undef')
		unless defined $self->level && $LEVEL{ $self->level };
	return $self;
}

sub levels {
	return sort { $a <=> $b } keys %LEVEL;
}

sub setting_for {
	my ($class, $level) = @_;
	my $setting = defined $level ? $LEVEL{$level} : undef;
	die 'level must be 1 .. 5, got ' . (defined $level ? "'$level'" : 'undef') unless $setting;
	return { %{$setting} };
}

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
			pv => [ $legal->[0]->notation ]
		});
		return $legal->[0];
	}

	my $spec = $LEVEL{ $self->level };
	my $position = Game::Merrills::Rules::position($game->board);
	my $turn = $game->turn;
	my $state = {
		nodes => 0,
		budget => $spec->{nodes},
		jitter => $spec->{jitter},
		table => {},
		history => {},
		killers => [],
		flying => $game->flying ? 1 : 0,
		limit => $Game::Merrills::NO_MILL_LIMIT || 0,
		aborted => 0
	};
	my $seen = { %{ $game->repetition } };

	my ($best, $score, $reached);
	for my $depth (1 .. $spec->{depth}) {
		last if $state->{nodes} >= $state->{budget};
		$state->{aborted} = 0;
		my ($iteration_score, $move) = $self->_root(
			$state, $position, $turn, $depth, $game->no_mill, $seen, $game->ply
		);
		last if $state->{aborted} || !$move;
		($best, $score, $reached) = ($move, $iteration_score, $depth);
	}

	my $chosen = $legal->[0];
	if ($best) {
		my $name = _name($best);
		for my $move (@{$legal}) {
			next unless _name($move->to_raw) eq $name;
			$chosen = $move;
			last;
		}
	}

	$self->last_search({
		depth => $reached || 0,
		nodes => $state->{nodes},
		score => $score,
		forced => 0,
		move => $chosen->notation,
		pv => $self->_pv($state, $position, $turn, $best)
	});
	return $chosen;
}

sub _name {
	my ($raw) = @_;
	return join '.', map { defined $_ ? $_ : '-' } @{$raw}[ RM_FROM, RM_TO, RM_REMOVE ];
}

sub _notation {
	my ($raw) = @_;
	return Game::Merrills::Notation::format_move({
		from => $raw->[RM_FROM],
		to => $raw->[RM_TO],
		remove => $raw->[RM_REMOVE],
	});
}

sub _root {
	my ($self, $state, $position, $turn, $depth, $no_mill, $seen, $ply) = @_;
	my $moves = Game::Merrills::Rules::generate($position, $turn, $state->{flying});
	return (undef, undef) unless @{$moves};

	my $alpha = -INFINITY();
	my ($best, $best_score);
	for my $raw (@{ $self->_ordered($state, $moves, 0, undef) }) {
		my $bound = $state->{jitter} ? -INFINITY() : $alpha;
		my $score = $self->_child(
			$state, $position, $turn, $raw,
			$depth - 1, -INFINITY(), -$bound, 1, 0, $no_mill, $seen
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
		$extension, $no_mill, $seen) = @_;

	my $next = $OTHER{$turn};
	my ($child_seen, $child_quiet) = !defined $raw->[RM_FROM] || defined $raw->[RM_REMOVE]
		? ({}, 0)
		: ($seen, $no_mill + 1);

	Game::Merrills::Rules::apply($position, $turn, $raw);
	my $key;
	if (!$position->[HAND_WHITE] && !$position->[HAND_BLACK]) {
		$key = join '', @{$position}[ 0 .. 23 ], $next;
		$child_seen->{$key}++;
	}

	my $score = -$self->_search(
		$state, $position, $next, $depth, $alpha, $beta, $ply, $extension,
		$child_quiet, $child_seen, $key
	);

	if (defined $key) {
		delete $child_seen->{$key} unless --$child_seen->{$key};
	}
	Game::Merrills::Rules::unapply($position, $turn, $raw);
	return $score;
}

sub _search {
	my ($self, $state, $position, $turn, $depth, $alpha, $beta, $ply,
		$extension, $no_mill, $seen, $key) = @_;

	$state->{nodes}++;
	if ($state->{nodes} >= $state->{budget}) {
		$state->{aborted} = 1;
		return 0;
	}

	my $value = $VALUE{$turn};
	my $men = $position->[ $value > 0 ? HAND_WHITE : HAND_BLACK ];
	$men += grep { $_ == $value } @{$position}[ 0 .. 23 ];
	return -WIN() + $ply if $men < 3;

	return 0 if defined $key && ($seen->{$key} || 0) >= 3;
	return 0 if $state->{limit} && $no_mill >= $state->{limit};

	return $self->_quiesce(
		$state, $position, $turn, $alpha, $beta, $ply, $extension, $no_mill, $seen
	) if $depth <= 0;

	my $slot = pack('c26', @{$position}) . $turn;
	my $entry = $self->transposition ? $state->{table}{$slot} : undef;
	my $table_move;
	if ($entry) {
		$table_move = $entry->[3];
		if ($entry->[0] >= $depth && abs($entry->[1]) < WIN - 100) {
			return $entry->[1] if $entry->[2] == EXACT;
			return $entry->[1] if $entry->[2] == LOWER && $entry->[1] >= $beta;
			return $entry->[1] if $entry->[2] == UPPER && $entry->[1] <= $alpha;
		}
	}

	my $moves = Game::Merrills::Rules::generate($position, $turn, $state->{flying});
	return -WIN() + $ply unless @{$moves};

	my $original = $alpha;
	my ($best_score, $best_move) = (-INFINITY(), undef);
	for my $raw (@{ $self->_ordered($state, $moves, $ply, $table_move) }) {
		my $score = $self->_child(
			$state, $position, $turn, $raw,
			$depth - 1, -$beta, -$alpha, $ply + 1, $extension, $no_mill, $seen
		);
		return 0 if $state->{aborted};

		if ($score > $best_score) {
			($best_score, $best_move) = ($score, $raw);
			$alpha = $score if $score > $alpha;
		}
		next if $alpha < $beta;

		my $name = _name($raw);
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
		$state->{table}{$slot} = [
			$depth, $best_score, $flag,
			$best_move && [ @{$best_move} ]
		];
	}
	return $best_score;
}

sub _quiesce {
	my ($self, $state, $position, $turn, $alpha, $beta, $ply, $extension,
		$no_mill, $seen) = @_;

	return -WIN() + $ply
		unless Game::Merrills::Rules::has_move($position, $turn, $state->{flying});

	my $stand = _evaluate($position, $turn, $state->{flying});
	return $stand if $extension >= MAX_EXTENSION || $stand >= $beta;

	my @captures = grep { defined $_->[RM_REMOVE] }
		@{ Game::Merrills::Rules::generate($position, $turn, $state->{flying}) };
	return $stand unless @captures;

	my $best = $stand;
	$alpha = $stand if $stand > $alpha;
	for my $raw (@captures) {
		my $score = $self->_child(
			$state, $position, $turn, $raw,
			0, -$beta, -$alpha, $ply + 1, $extension + 1, $no_mill, $seen
		);
		return 0 if $state->{aborted};
		$best = $score if $score > $best;
		$alpha = $score if $score > $alpha;
		last if $alpha >= $beta;
	}
	return $best;
}

sub _ordered {
	my ($self, $state, $moves, $ply, $table_move) = @_;
	my $wanted = $table_move ? _name($table_move) : '';
	my $killers = $state->{killers}[$ply] || [];
	my $history = $state->{history};

	my @scored;
	for my $i (0 .. $#{$moves}) {
		my $raw = $moves->[$i];
		my $name = _name($raw);
		my $score = 0;
		$score += 1_000_000 if $name eq $wanted;
		$score += 1_000 + (10 * $raw->[RM_CLOSES]) if defined $raw->[RM_REMOVE];
		$score += 400 if @{$killers} && $killers->[0] eq $name;
		$score += 300 if @{$killers} > 1 && $killers->[1] eq $name;
		$score += $history->{$name} || 0;
		push @scored, [ $score, $i, $raw ];
	}
	return [
		map { $_->[2] } sort { $b->[0] <=> $a->[0] || $a->[1] <=> $b->[1] } @scored
	];
}

sub _pv {
	my ($self, $state, $position, $turn, $first) = @_;
	my @pv;
	my @undo;

	my $raw = $first;
	while (@pv < MAX_PV) {
		unless ($raw) {
			my $entry = $state->{table}{ pack('c26', @{$position}) . $turn } or last;
			$raw = $entry->[3] or last;
		}
		my $name = _name($raw);
		last unless grep { _name($_) eq $name }
			@{ Game::Merrills::Rules::generate($position, $turn, $state->{flying}) };
		push @pv, _notation($raw);
		Game::Merrills::Rules::apply($position, $turn, $raw);
		push @undo, [ $turn, $raw ];
		$turn = $OTHER{$turn};
		undef $raw;
	}
	Game::Merrills::Rules::unapply($position, @{ pop @undo }) while @undo;
	return \@pv;
}

sub _jitter {
	my ($seed, $ply, $raw) = @_;
	my $string = $seed . ':' . $ply . ':' . _name($raw);
	my $hash = 0;
	$hash = (($hash * 33) + ord) % 65_521 for split //, $string;
	return $hash % 25;
}

sub _evaluate {
	my ($position, $turn, $flying) = @_;
	my %hand = (1 => $position->[HAND_WHITE], -1 => $position->[HAND_BLACK]);
	my %score = (1 => 0, -1 => 0);
	my %count = (1 => 0, -1 => 0);
	for my $point (0 .. 23) {
		$count{ $position->[$point] }++ if $position->[$point];
	}
	my $placing = $hand{1} || $hand{-1};

	my (@closed, @open);
	for my $mill (@{$MILLS}) {
		my ($one, $two, $three) = @{$position}[ @{$mill} ];
		my $sum = $one + $two + $three;
		if ($sum == 3 || $sum == -3) {
			my $side = $sum > 0 ? 1 : -1;
			$score{$side} += $MILL;
			$closed[$_] = $side for @{$mill};
			next;
		}
		next unless ($sum == 2 || $sum == -2) && !($one && $two && $three);
		my ($empty) = grep { !$position->[$_] } @{$mill};
		push @open, [ $sum > 0 ? 1 : -1, $empty, $mill ];
	}

	for my $two (@open) {
		my ($side, $empty, $mill) = @{$two};
		$score{$side} += $OPEN_TWO;
		if ($hand{$side}) {
			$score{$side} += $REACH;
			next;
		}
		if ($flying && $count{$side} == 3) {
			$score{$side} += $REACH;
			next;
		}
		my ($reach, $running) = (0, 0);
		for my $near (@{ $ADJACENT->[$empty] }) {
			next unless $position->[$near] == $side;
			next if grep { $_ == $near } @{$mill};
			$reach = 1;
			$running = 1 if ($closed[$near] || 0) == $side;
		}
		$score{$side} += $REACH if $reach;
		$score{$side} += $RUNNING if $running;
	}

	for my $point (0 .. 23) {
		my $side = $position->[$point] or next;
		if ($placing) {
			$score{$side} += $JUNCTION * (@{ $ADJACENT->[$point] } - 2);
			next;
		}
		my $free = grep { !$position->[$_] } @{ $ADJACENT->[$point] };
		$score{$side} += $MOBILITY * $free;
		$score{$side} -= $BLOCKED unless $free || ($flying && $count{$side} == 3);
	}

	$score{$_} += $MAN * ($count{$_} + $hand{$_}) for 1, -1;

	my $value = $VALUE{$turn};
	return $score{$value} - $score{ -$value };
}

1;

__END__

=head1 NAME

Game::Merrills::Bot - a player that chooses its own moves, at five strengths

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Merrills;
	use Game::Merrills::Bot;

	my $game = Game::Merrills->new;
	my $bot = Game::Merrills::Bot->new(level => 3, seed => 7);

	while ($game->status eq 'active') {
		$game->move($bot->choose($game));
	}

	$bot->last_search;        # { depth, nodes, score, forced, move, pv }

=head1 DESCRIPTION

A bot looks at a game and picks a move for the side whose turn it is. It does
not play the move; hand what it chose to the game.

=head2 It only ever picks a move the game offered

What L</choose> returns is one of the objects in the game's own list of legal
moves. The bot never makes a move up, so however poor its judgement, it
cannot play an illegal one.

=head2 It looks ahead

The bot tries each move, then each reply, and so on to a depth set by its
level, and picks the move that leaves it best off if both sides play as well
as it can see. When the look-ahead ends on a position where a mill is about
to be closed, it looks a little further before judging, so that it does not
stop one move short of losing a man.

=head2 How it judges a position

At the end of each line it adds up what it likes and takes away what its
opponent would like:

=over 4

=item *

Men, on the board and in hand. Far the largest part.

=item *

Mills that stand closed.

=item *

Two men in a row with the third point empty, and more when a man is placed to
step in and close it.

=item *

The running mill: a man that can step out of one mill straight into another,
so that every move closes one of the two.

=item *

Room to move, and enemy men that have none, once every man is placed.

=item *

While men are still being placed, the points where most lines meet.

=back

A side reduced to two men, or left with no move, has lost, and a loss sooner
counts for more than a loss later. A position that would be a draw by
repetition or for want of a mill counts as level.

=head2 Its effort is measured in positions, never in time

Each level has a depth and a number of positions it may look at. When the
number runs out the bot answers with the best move from the deepest look it
finished. No clock is consulted, so the same bot on the same game chooses the
same move on any machine, however fast or slow.

=head2 It never guesses

Nothing here is random. Levels 1 and 2 are made to vary their play, and to
play less well, by adding a small amount to each move's worth that is worked
out from the seed, the move and how far the game has gone. A different seed
gives a different game. From level 3 up the seed changes nothing.

=head1 PROPERTIES

=head2 level

Read only number, 1 to 5, weakest first. Defaults to 3. Anything else dies.

	my $bot = Game::Merrills::Bot->new(level => 1);

=head2 seed

Read only number that varies the play of levels 1 and 2. Defaults to 0.

	my $bot = Game::Merrills::Bot->new(level => 1, seed => 42);

=head2 transposition

Read and write flag. The bot remembers positions it has already judged, so as
not to judge them again when a different order of moves reaches them. Turning
this off makes it slower. Given positions to spare, it does not change what
the chosen move is judged to be worth, though between two moves of equal
worth it may settle on the other. Defaults to true.

	$bot->transposition(0);

=head2 last_search

A hashref describing the most recent choice, or undef before the first:

=over 4

=item depth

How many moves ahead the finished look went.

=item nodes

How many positions were looked at.

=item score

What the chosen move was judged to be worth, from the chooser's side: 100 is
about a man. Undef when the move was forced.

=item forced

True when there was only one legal move and nothing to think about.

=item move

The chosen move, as written.

=item pv

An arrayref of the moves the bot expects, its own and the replies, as written.

=back

	$bot->last_search->{score};

=head1 METHODS

=head2 choose

The move the bot would play in a game, one of the game's own legal moves, or
undef when the game is over. The game is not changed.

	my $move = $bot->choose($game);

=head2 levels

The levels there are, as a list, weakest first.

	my @levels = Game::Merrills::Bot->levels;

=head2 setting_for

A hashref of what a level is allowed: C<depth>, C<nodes> and C<jitter>, true
for the levels the seed varies. Dies when the level is not one.

	my $setting = Game::Merrills::Bot->setting_for(3);

=head1 PACKAGE VARIABLES

=over 4

=item C<%LEVEL>

What each level is allowed.

=item C<$MAN>, C<$MILL>, C<$OPEN_TWO>, C<$REACH>, C<$RUNNING>, C<$BLOCKED>, C<$MOBILITY>, C<$JUNCTION>

What each thing the bot likes is worth. They are variables so that they can
be tried at other values.

=back

=head1 CONSTANTS

=over 4

=item WIN

The worth of a won game.

=item INFINITY

A number larger than any worth.

=item MAX_EXTENSION

How many moves past its depth the bot will follow mills being closed.

=item MAX_PV

The longest line of expected moves kept.

=item EXACT

=item LOWER

=item UPPER

How sure a remembered judgement is.

=item RM_FROM

=item RM_TO

=item RM_REMOVE

=item RM_CLOSES

The indexes of a raw move, as in L<Game::Merrills::Move>.

=item HAND_WHITE

=item HAND_BLACK

Where a position holds each hand, as in L<Game::Merrills::Rules>.

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
