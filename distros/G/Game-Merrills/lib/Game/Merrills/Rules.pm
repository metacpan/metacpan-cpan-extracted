package Game::Merrills::Rules;

use strict;
use warnings;

use Game::Merrills::Points;
use Game::Merrills::Board;
use Game::Merrills::Move;

our $VERSION = '0.01';

use constant {
	HAND_WHITE => 24,
	HAND_BLACK => 25,
};

use constant {
	RM_FROM => Game::Merrills::Move::RM_FROM,
	RM_TO => Game::Merrills::Move::RM_TO,
	RM_REMOVE => Game::Merrills::Move::RM_REMOVE,
	RM_CLOSES => Game::Merrills::Move::RM_CLOSES,
	RM_FLEW => Game::Merrills::Move::RM_FLEW,
};

sub _value {
	my ($side) = @_;
	die 'side must be white or black, got ' . (defined $side ? "'$side'" : 'undef')
		unless defined $side && exists $Game::Merrills::Board::VALUE{$side};
	return $Game::Merrills::Board::VALUE{$side};
}

sub _check {
	my ($position) = @_;
	die 'a position is an arrayref of 26 values'
		unless ref $position eq 'ARRAY' && @{$position} == 26;
	return $position;
}

sub _in_mill {
	my ($position, $point) = @_;
	my $value = $position->[$point] or return 0;
	for my $mill (@{ $Game::Merrills::Points::MILLS_OF[$point] }) {
		return 1 if $position->[ $mill->[0] ] == $value
			&& $position->[ $mill->[1] ] == $value
			&& $position->[ $mill->[2] ] == $value;
	}
	return 0;
}

sub _closes {
	my ($position, $value, $from, $to) = @_;
	my $closed = 0;
	for my $mill (@{ $Game::Merrills::Points::MILLS_OF[$to] }) {
		my $whole = 1;
		for my $point (@{$mill}) {
			next if $point == $to;
			next if $position->[$point] == $value && !(defined $from && $point == $from);
			$whole = 0;
			last;
		}
		$closed += $whole;
	}
	return $closed;
}

sub _removable {
	my ($position, $value) = @_;
	my (@loose, @all);
	for my $point (0 .. 23) {
		next unless $position->[$point] == -$value;
		push @all, $point;
		push @loose, $point unless _in_mill($position, $point);
	}
	return @loose ? @loose : @all;
}

sub position {
	my ($board) = @_;
	return [ @{ $board->cells }, $board->in_hand('white'), $board->in_hand('black') ];
}

sub board {
	my ($position) = @_;
	_check($position);
	return Game::Merrills::Board->new(
		cells => [ @{$position}[ 0 .. 23 ] ],
		hand => { white => $position->[HAND_WHITE], black => $position->[HAND_BLACK] }
	);
}

sub closes {
	my ($position, $side, $from, $to) = @_;
	_check($position);
	Game::Merrills::Points::_check($to);
	Game::Merrills::Points::_check($from) if defined $from;
	return _closes($position, _value($side), $from, $to);
}

sub removable {
	my ($position, $side) = @_;
	_check($position);
	return _removable($position, _value($side));
}

sub _phase {
	my ($position, $value, $flying) = @_;
	return 'placing' if $position->[ $value > 0 ? HAND_WHITE : HAND_BLACK ];
	return 'moving' unless $flying;
	my $men = grep { $_ == $value } @{$position}[ 0 .. 23 ];
	return $men == 3 ? 'flying' : 'moving';
}

sub phase {
	my ($position, $side, $flying) = @_;
	_check($position);
	return _phase($position, _value($side), defined $flying ? $flying : 1);
}

sub generate {
	my ($position, $side, $flying) = @_;
	_check($position);
	my $value = _value($side);
	my $phase = _phase($position, $value, defined $flying ? $flying : 1);

	my (@moves, @takes, $asked, @own);
	@own = grep { $position->[$_] == $value } 0 .. 23 if $phase eq 'flying';
	for my $to (0 .. 23) {
		next if $position->[$to];
		my @from = $phase eq 'placing' ? (undef)
			: $phase eq 'flying' ? @own
			: grep { $position->[$_] == $value } @{ $Game::Merrills::Points::ADJACENT[$to] };
		for my $from (@from) {
			my $flew = $phase eq 'flying'
				&& !grep { $_ == $from } @{ $Game::Merrills::Points::ADJACENT[$to] };
			my $closed = _closes($position, $value, $from, $to);
			unless ($closed) {
				push @moves, [ $from, $to, undef, 0, $flew ? 1 : 0 ];
				next;
			}
			@takes = _removable($position, $value) unless $asked++;
			die 'a mill closed and there is no man to take' unless @takes;
			push @moves, map { [ $from, $to, $_, $closed, $flew ? 1 : 0 ] } @takes;
		}
	}
	return \@moves;
}

sub has_move {
	my ($position, $side, $flying) = @_;
	_check($position);
	my $value = _value($side);
	my $phase = _phase($position, $value, defined $flying ? $flying : 1);
	if ($phase eq 'moving') {
		for my $from (0 .. 23) {
			next unless $position->[$from] == $value;
			for my $to (@{ $Game::Merrills::Points::ADJACENT[$from] }) {
				return 1 unless $position->[$to];
			}
		}
		return 0;
	}
	return scalar(grep { !$_ } @{$position}[ 0 .. 23 ]) ? 1 : 0;
}

sub apply {
	my ($position, $side, $raw) = @_;
	my $value = _value($side);
	if (defined $raw->[RM_FROM]) {
		$position->[ $raw->[RM_FROM] ] = 0;
	}
	else {
		$position->[ $value > 0 ? HAND_WHITE : HAND_BLACK ]--;
	}
	$position->[ $raw->[RM_TO] ] = $value;
	$position->[ $raw->[RM_REMOVE] ] = 0 if defined $raw->[RM_REMOVE];
	return $position;
}

sub unapply {
	my ($position, $side, $raw) = @_;
	my $value = _value($side);
	$position->[ $raw->[RM_REMOVE] ] = -$value if defined $raw->[RM_REMOVE];
	$position->[ $raw->[RM_TO] ] = 0;
	if (defined $raw->[RM_FROM]) {
		$position->[ $raw->[RM_FROM] ] = $value;
	}
	else {
		$position->[ $value > 0 ? HAND_WHITE : HAND_BLACK ]++;
	}
	return $position;
}

1;

__END__

=head1 NAME

Game::Merrills::Rules - which moves are legal, and what a move does to a position

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Merrills::Board;
	use Game::Merrills::Rules;

	my $position = Game::Merrills::Rules::position(Game::Merrills::Board->new);

	my $moves = Game::Merrills::Rules::generate($position, 'white');     # 24 of them

	Game::Merrills::Rules::apply($position, 'white', $moves->[0]);
	Game::Merrills::Rules::unapply($position, 'white', $moves->[0]);

=head1 DESCRIPTION

The rules of Nine Men's Morris as plain functions over a position. Nothing
here keeps a game: there is no turn, no history and no result. Give the
functions a position and a side and they say what that side may do; give them
a move and they do it or undo it.

=head2 A position

An arrayref of 26 values. The first 24 are the points in point order, 1 for a
white man, -1 for a black one and 0 for an empty point, exactly as
L<Game::Merrills::Board> holds them. The last two are the men white and then
black have yet to place. L</position> makes one from a board and L</board>
makes a board from one.

=head2 A move

A raw move, the arrayref L<Game::Merrills::Move> describes. A move is always
the whole turn. One that closes a mill names the man it takes, so a position
is never left waiting for a capture.

=head2 The placing rules

While a side has men in hand, its turn is to put one on any empty point.

A man that lands as the third of its side in a row closes a mill, and the move
takes one enemy man off the board.

A man in a mill is safe while any enemy man stands outside one. When every
enemy man on the board is in a mill, any of them may be taken.

A man that completes two mills at once, one across and one down, still takes
one man.

Only men on the board can be taken. Men in hand are out of reach.

=head2 The moving rules

Once a side has placed every man, its turn is to move one of them along a
line to a neighbouring empty point. A man may not pass over another. Mills
are closed and men taken exactly as while placing, and a man may step out of
a mill and back in to close it again.

=head2 Flying

A side with exactly three men on the board and none in hand may move a man to
any empty point, neighbour or not. The two sides are judged apart, so one may
be flying while the other still moves along the lines.

Flying is the usual rule and is on unless a function is told otherwise. Each
function that depends on it takes a last argument for it: leave it out or
pass a true value for flying, pass 0 for a game without it.

=head2 A side that cannot move

A side whose every man is hemmed in has no move, and L</generate> returns an
empty list for it. A side still placing always has a move, since eighteen men
cannot fill 24 points, and so does a side that is flying.

=head1 FUNCTIONS

None is exported. A side is C<white> or C<black>; anything else dies, as does
a position that is not 26 values.

=head2 position

The position of a L<Game::Merrills::Board>, as a fresh arrayref.

	my $position = Game::Merrills::Rules::position($board);

=head2 board

A new L<Game::Merrills::Board> holding a position.

	my $board = Game::Merrills::Rules::board($position);

=head2 phase

What a side does on its turn: C<placing> while it has men in hand, C<flying>
when it has none in hand and exactly three on the board, and C<moving>
otherwise. Takes the flying argument.

	Game::Merrills::Rules::phase($position, 'white');
	Game::Merrills::Rules::phase($position, 'white', 0);     # never 'flying'

=head2 has_move

True when a side has at least one legal move. Takes the flying argument.

	Game::Merrills::Rules::has_move($position, 'black');

=head2 generate

Every legal move for a side, as an arrayref of raw moves. A move that closes a
mill appears once for each man it could take, and never without one. Takes
the flying argument.

The order is fixed: by the point landed on, then the point left, then the man
taken, each ascending. The same position always gives the same list.

	my $moves = Game::Merrills::Rules::generate($position, 'white');
	my $moves = Game::Merrills::Rules::generate($position, 'white', 0);

=head2 closes

How many mills a man of a side would complete by landing on a point: 0, 1 or
2. Give the point it leaves, or undef when it comes from the hand. The point
left counts as empty, so a man stepping along a row it already stood in closes
nothing.

	Game::Merrills::Rules::closes($position, 'white', undef, $to);
	Game::Merrills::Rules::closes($position, 'white', $from, $to);

=head2 removable

The enemy men a side may take on closing a mill, as a list of points in
order: the enemy men outside any mill, or every enemy man when there are none
outside.

	my @points = Game::Merrills::Rules::removable($position, 'white');

=head2 apply

Plays a raw move for a side, changing the position, and returns it. The move
is taken on trust: hand this only moves that L</generate> returned.

	Game::Merrills::Rules::apply($position, 'white', $raw);

=head2 unapply

Takes back a raw move a side played, changing the position, and returns it.
The move must be the last one applied.

	Game::Merrills::Rules::unapply($position, 'white', $raw);

=head1 CONSTANTS

=over 4

=item HAND_WHITE

24, where a position holds the men white has yet to place.

=item HAND_BLACK

25, where a position holds the men black has yet to place.

=item RM_FROM

=item RM_TO

=item RM_REMOVE

=item RM_CLOSES

=item RM_FLEW

The indexes of a raw move, the same as in L<Game::Merrills::Move>.

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
