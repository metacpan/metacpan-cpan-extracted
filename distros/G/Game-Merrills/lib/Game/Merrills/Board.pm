package Game::Merrills::Board;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Merrills::Points;

our $VERSION = '0.01';

use constant {
	EMPTY => 0,
	WHITE => 1,
	BLACK => -1,
	MEN => 9,
};

our (%VALUE, %SIDE);

BEGIN {
	%VALUE = (white => WHITE, black => BLACK);
	%SIDE = (WHITE, 'white', BLACK, 'black');
}

has cells => (
	is => 'rw',
	isa => ArrayRef,
	default => sub { opening() }
);

has hand => (
	is => 'rw',
	isa => HashRef,
	default => sub { { white => MEN, black => MEN } }
);

sub BUILD {
	my ($self) = @_;
	my $cells = $self->cells;
	die 'cells must be an arrayref of 24 values'
		unless ref $cells eq 'ARRAY' && @{$cells} == Game::Merrills::Points::POINTS;
	for my $point (Game::Merrills::Points::all_points()) {
		my $value = $cells->[$point];
		die 'cell ' . Game::Merrills::Points::name($point) . ' must be -1, 0 or 1, got '
			. (defined $value ? "'$value'" : 'undef')
			unless defined $value && $value =~ m/^(?:-1|0|1)$/;
		$cells->[$point] = $value + 0;
	}
	my $hand = $self->hand;
	for my $side (qw/white black/) {
		my $held = $hand->{$side};
		die "hand of $side must be 0 .. 9, got " . (defined $held ? "'$held'" : 'undef')
			unless defined $held && $held =~ m/^[0-9]$/;
		$hand->{$side} = $held + 0;
		die "$side has more than nine men"
			if $self->count($side) + $held > MEN;
	}
	die 'hand must hold white and black and nothing else'
		unless keys %{$hand} == 2;
	return $self;
}

sub _value {
	my ($side) = @_;
	die 'side must be white or black, got ' . (defined $side ? "'$side'" : 'undef')
		unless defined $side && exists $VALUE{$side};
	return $VALUE{$side};
}

sub opening {
	return [ (EMPTY) x Game::Merrills::Points::POINTS ];
}

sub at {
	return $_[0]->cells->[ Game::Merrills::Points::_check($_[1]) ];
}

sub side_at {
	my $value = $_[0]->at($_[1]) or return undef;
	return $SIDE{$value};
}

sub set {
	my ($self, $point, $side) = @_;
	Game::Merrills::Points::_check($point);
	$self->cells->[$point] = defined $side ? _value($side) : EMPTY;
	return $self;
}

sub empty {
	return $_[0]->at($_[1]) ? 0 : 1;
}

sub points_of {
	my ($self, $side) = @_;
	my $value = _value($side);
	my $cells = $self->cells;
	return grep { $cells->[$_] == $value } Game::Merrills::Points::all_points();
}

sub count {
	my ($self, $side) = @_;
	return scalar(() = $self->points_of($side));
}

sub in_hand {
	my ($self, $side) = @_;
	_value($side);
	return $self->hand->{$side};
}

sub men {
	my ($self, $side) = @_;
	return $self->count($side) + $self->in_hand($side);
}

sub in_mill {
	my ($self, $point) = @_;
	my $value = $self->at($point) or return 0;
	my $cells = $self->cells;
	for my $mill (@{ $Game::Merrills::Points::MILLS_OF[$point] }) {
		return 1 if $cells->[ $mill->[0] ] == $value
			&& $cells->[ $mill->[1] ] == $value
			&& $cells->[ $mill->[2] ] == $value;
	}
	return 0;
}

sub clone {
	my ($self) = @_;
	return ref($self)->new(
		cells => [ @{ $self->cells } ],
		hand => { %{ $self->hand } }
	);
}

1;

__END__

=head1 NAME

Game::Merrills::Board - the 24 points, the men on them and the men still in hand

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Merrills::Board;
	use Game::Merrills::Points;

	my $board = Game::Merrills::Board->new;

	my $d2 = Game::Merrills::Points::point('d2');
	$board->set($d2, 'white');
	$board->side_at($d2);          # 'white'
	$board->count('white');        # 1
	$board->in_hand('white');      # 9, the board does not move men for you
	$board->in_mill($d2);          # 0

=head1 DESCRIPTION

A board is what a photograph of the table would show: which points hold a
white man, which a black one, and how many men each side has yet to place.

It knows nothing of turns or of what is legal. Setting a point does not take a
man from a hand, and nothing stops a man being set where the rules would never
allow it. The board refuses only what could not be a position at all: a cell
that is not a man or empty, a hand that is not a count, and a side with more
than nine men between its hand and the board.

Sides are the strings C<white> and C<black>. Points are the numbers of
L<Game::Merrills::Points>. A side that is neither, or a point that is not one,
is a programming mistake and dies.

=head1 PROPERTIES

=head2 cells

Read and write arrayref of 24 values, one a point in point order, each
C<EMPTY>, C<WHITE> or C<BLACK>. Defaults to an empty board.

	my $board = Game::Merrills::Board->new(cells => \@cells);

=head2 hand

Read and write hashref of the men each side has not yet placed, keyed
C<white> and C<black>. Defaults to nine each.

	my $board = Game::Merrills::Board->new(hand => { white => 0, black => 0 });

=head1 METHODS

=head2 opening

The cells of an empty board, a fresh arrayref each time. Callable as a
function.

	my $cells = Game::Merrills::Board->opening;

=head2 at

The value on a point: C<EMPTY>, C<WHITE> or C<BLACK>.

	$board->at($point);

=head2 side_at

The side whose man is on a point, or undef when it is empty.

	$board->side_at($point);       # 'black'

=head2 set

Puts a man of a side on a point, or clears the point when the side is undef.
Returns the board.

	$board->set($point, 'black');
	$board->set($point, undef);

=head2 empty

True when no man is on the point.

	$board->empty($point);

=head2 points_of

The points a side has men on, in point order.

	my @points = $board->points_of('white');

=head2 count

How many men a side has on the board.

	$board->count('white');

=head2 in_hand

How many men a side has yet to place.

	$board->in_hand('black');

=head2 men

The men a side has left, on the board and in hand together. A side with fewer
than three has lost.

	$board->men('black');

=head2 in_mill

True when the man on a point is one of three of its side in a row. False for
an empty point.

	$board->in_mill($point);

=head2 clone

A board with the same men and the same hands, sharing nothing with this one.

	my $copy = $board->clone;

=head1 CONSTANTS

=over 4

=item EMPTY

0, a point with no man on it.

=item WHITE

1, a white man.

=item BLACK

-1, a black man.

=item MEN

9, the men each side starts with.

=back

=head1 PACKAGE VARIABLES

=over 4

=item C<%VALUE>

The cell value of each side name.

=item C<%SIDE>

The side name of each cell value.

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
