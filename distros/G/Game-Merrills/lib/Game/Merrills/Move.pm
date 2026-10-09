package Game::Merrills::Move;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Merrills::Points;
use Game::Merrills::Notation;

our $VERSION = '0.01';

use constant {
	RM_FROM => 0,
	RM_TO => 1,
	RM_REMOVE => 2,
	RM_CLOSES => 3,
	RM_FLEW => 4,
};

has [qw/from to remove/] => (
	is => 'ro',
	isa => Int
);

has closes => (
	is => 'ro',
	isa => Int,
	default => 0
);

has flew => (
	is => 'ro',
	isa => Bool,
	default => 0
);

has side => (
	is => 'ro',
	isa => Str
);

sub BUILD {
	my ($self) = @_;
	die 'a move needs a point to go to' unless defined $self->to;
	Game::Merrills::Points::_check($self->to);
	Game::Merrills::Points::_check($self->from) if defined $self->from;
	Game::Merrills::Points::_check($self->remove) if defined $self->remove;
	return $self;
}

sub from_raw {
	my ($class, $raw, $side) = @_;
	my %part = (
		to => $raw->[RM_TO],
		closes => $raw->[RM_CLOSES] || 0,
		flew => $raw->[RM_FLEW] ? 1 : 0,
	);
	$part{from} = $raw->[RM_FROM] if defined $raw->[RM_FROM];
	$part{remove} = $raw->[RM_REMOVE] if defined $raw->[RM_REMOVE];
	$part{side} = $side if defined $side;
	return $class->new(%part);
}

sub to_raw {
	my ($self) = @_;
	my @raw;
	$raw[RM_FROM] = $self->from;
	$raw[RM_TO] = $self->to;
	$raw[RM_REMOVE] = $self->remove;
	$raw[RM_CLOSES] = $self->closes;
	$raw[RM_FLEW] = $self->flew;
	return \@raw;
}

sub is_placement {
	return defined $_[0]->from ? 0 : 1;
}

sub is_capture {
	return defined $_[0]->remove ? 1 : 0;
}

sub notation {
	my ($self) = @_;
	return Game::Merrills::Notation::format_move({
		from => $self->from,
		to => $self->to,
		remove => $self->remove,
	});
}

sub stringify {
	return $_[0]->notation;
}

1;

__END__

=head1 NAME

Game::Merrills::Move - one whole move: where from, where to, and the man it took

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Merrills::Move;
	use Game::Merrills::Points;

	my $move = Game::Merrills::Move->new(
		from => Game::Merrills::Points::point('d2'),
		to => Game::Merrills::Points::point('d3'),
		remove => Game::Merrills::Points::point('a1'),
		closes => 1,
		side => 'white',
	);

	$move->notation;          # 'd2-d3xa1'
	$move->is_capture;        # 1
	$move->is_placement;      # 0

=head1 DESCRIPTION

A turn in Nine Men's Morris can have up to three parts: the point a man
leaves, the point it lands on, and, when landing completes a mill, the enemy
man taken off the board. A move here is always the whole turn. There is no
such thing as a move that has closed a mill and not yet taken its man, so
nothing that holds a move ever has to ask whether the turn is finished.

While men are still being placed there is no point to leave, and C<from> is
undef. When no mill is closed there is nothing to take, and C<remove> is
undef.

A move records what was done. It does not know whether it is legal.

=head1 THE RAW MOVE

Where many moves are made and thrown away, a move travels as a plain arrayref
indexed by the C<RM_> constants below. L</from_raw> and L</to_raw> convert
between the two.

=head1 PROPERTIES

All are read only. Points are the numbers of L<Game::Merrills::Points>.

=head2 from

The point the man left, or undef when the man came from the hand.

	$move->from;

=head2 to

The point the man landed on. Every move has one.

	$move->to;

=head2 remove

The point of the enemy man taken, or undef when no mill was closed.

	$move->remove;

=head2 closes

How many mills the man completed by landing: 0, 1 or 2. Two mills still take
one man. Defaults to 0.

	$move->closes;

=head2 flew

True when the man moved to a point that is not a neighbour of the one it
left, which a side down to three men may do. Defaults to false.

	$move->flew;

=head2 side

The side that moved, C<white> or C<black>.

	$move->side;

=head1 METHODS

=head2 from_raw

Builds a move from a raw move and the side that made it.

	my $move = Game::Merrills::Move->from_raw($raw, 'white');

=head2 to_raw

The move as a fresh raw move.

	my $raw = $move->to_raw;

=head2 is_placement

True when the man came from the hand.

	$move->is_placement;

=head2 is_capture

True when the move took a man.

	$move->is_capture;

=head2 notation

The move as it is written down: C<d2> for a placement, C<d2-d3> for a move,
with C<xa1> on the end when it took the man on a1. See
L<Game::Merrills::Notation>.

	$move->notation;

=head2 stringify

The same as L</notation>.

	$move->stringify;

=head1 CONSTANTS

The indexes of a raw move.

=over 4

=item RM_FROM

The point left, or undef.

=item RM_TO

The point landed on.

=item RM_REMOVE

The point of the man taken, or undef.

=item RM_CLOSES

The number of mills completed.

=item RM_FLEW

True when the man flew.

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
