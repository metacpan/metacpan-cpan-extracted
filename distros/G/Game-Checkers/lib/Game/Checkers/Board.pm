package Game::Checkers::Board;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Checkers::Piece;
use Game::Checkers::Notation;

our $VERSION = '0.01';

use constant {
	EMPTY => 0,
	BLACK_MAN => 1,
	BLACK_KING => 2,
	WHITE_MAN => -1,
	WHITE_KING => -2,
};

has position => (
	is => 'rw',
	isa => ArrayRef,
	default => sub { __PACKAGE__->opening_position }
);

sub BUILD {
	my ($self) = @_;
	my $position = $self->position;
	die 'position must be an arrayref of 33 values, index 0 unused'
		unless ref $position eq 'ARRAY' && @{$position} == 33;
	$position->[0] = EMPTY;
	for my $square (1 .. 32) {
		my $value = $position->[$square];
		die "position square $square must be -2 .. 2, got "
			. (defined $value ? "'$value'" : 'undef')
			unless defined $value && $value =~ m/^-?[0-2]$/;
		$position->[$square] = $value + 0;
	}
	return $self;
}

sub opening_position {
	my @position = (EMPTY) x 33;
	$position[$_] = BLACK_MAN for 1 .. 12;
	$position[$_] = WHITE_MAN for 21 .. 32;
	return \@position;
}

sub at {
	return $_[0]->position->[$_[1]];
}

sub set {
	my ($self, $square, $value) = @_;
	$self->position->[$square] = $value;
	return $self;
}

sub occupied {
	return $_[0]->position->[$_[1]] ? 1 : 0;
}

sub empty {
	return $_[0]->position->[$_[1]] ? 0 : 1;
}

sub colour_at {
	my $value = $_[0]->position->[$_[1]] or return undef;
	return $value > 0 ? 'black' : 'white';
}

sub king_at {
	my $value = $_[0]->position->[$_[1]] or return 0;
	return abs($value) == 2 ? 1 : 0;
}

sub piece {
	my ($self, $square) = @_;
	return Game::Checkers::Piece->from_value($self->position->[$square], $square);
}

sub pieces {
	my ($self, $side) = @_;
	my $position = $self->position;
	my @pieces;
	for my $square (1 .. 32) {
		my $value = $position->[$square] or next;
		next if $side && ($value > 0 ? 'black' : 'white') ne $side;
		push @pieces, Game::Checkers::Piece->from_value($value, $square);
	}
	return \@pieces;
}

sub count {
	my ($self, $side) = @_;
	my $position = $self->position;
	my %count = (men => 0, kings => 0, total => 0);
	for my $square (1 .. 32) {
		my $value = $position->[$square] or next;
		next if $side && ($value > 0 ? 'black' : 'white') ne $side;
		$count{abs($value) == 2 ? 'kings' : 'men'}++;
		$count{total}++;
	}
	return \%count;
}

sub clone {
	my ($self) = @_;
	return ref($self)->new(position => [@{$self->position}]);
}

sub to_fen {
	my ($self, $turn) = @_;
	return Game::Checkers::Notation::fen_from_position($self->position, $turn);
}

sub from_fen {
	my ($class, $fen, %opt) = @_;
	my ($position, $turn) = Game::Checkers::Notation::position_from_fen($fen, %opt);
	my $board = $class->new(position => $position);
	return wantarray ? ($board, $turn) : $board;
}

1;

__END__

=head1 NAME

Game::Checkers::Board - the 32 playing squares and what stands on them

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Checkers::Board;

	my $board = Game::Checkers::Board->new;          # the opening position
	$board->at(11);                                  # 1, a black man
	$board->piece(11)->colour;                       # 'black'
	$board->count('white')->{total};                 # 12

	my ($board, $turn) = Game::Checkers::Board->from_fen('B:W21,22:BK7');

=head1 DESCRIPTION

The board is a position arrayref and the queries over it. L<Game::Checkers::Piece>
objects are built on demand and are never stored.

=head1 PROPERTIES

=head2 position

Read and write arrayref of 33 values, index 0 unused so a square number indexes
itself. Each value is 0 for an empty square, 1 a black man, 2 a black king, -1 a
white man and -2 a white king.

The signed encoding is the documented state and not an implementation detail: the
search in L<Game::Checkers::Bot> copies one of these arrays for every node it
visits, so the cost of a node is the copy and nothing else, and the sign makes an
evaluation symmetric. Defaults to the opening position, and is validated at
construction.

	$board->position;

=head1 CONSTANTS

C<EMPTY>, C<BLACK_MAN>, C<BLACK_KING>, C<WHITE_MAN> and C<WHITE_KING> are the five
position values.

=head1 FUNCTIONS

=head2 opening_position

Class method returning a fresh arrayref of the opening position, black men on 1
to 12 and white men on 21 to 32.

	my $position = Game::Checkers::Board->opening_position;

=head2 at

The position value on a square.

	$board->at(15);

=head2 set

Sets the position value on a square and returns the board.

	$board->set(15, Game::Checkers::Board::BLACK_KING);

=head2 occupied

True when a square holds a piece.

	$board->occupied(15);

=head2 empty

True when a square holds nothing.

	$board->empty(15);

=head2 colour_at

C<black>, C<white>, or undef for an empty square.

	$board->colour_at(15);

=head2 king_at

True when the square holds a king.

	$board->king_at(15);

=head2 piece

A L<Game::Checkers::Piece> for the square, or undef when it is empty. Built on
demand, so two calls return two objects.

	$board->piece(15);

=head2 pieces

An arrayref of L<Game::Checkers::Piece> for one side, or for both when no side is
given, in ascending square order.

	$board->pieces('black');

=head2 count

A hashref of C<men>, C<kings> and C<total> for one side, or for both when no side
is given.

	$board->count('white');

=head2 clone

A new board with a copy of the position, so mutating one leaves the other alone.

	my $copy = $board->clone;

=head2 to_fen

The FEN for this position and the given side to move.

	$board->to_fen('black');

=head2 from_fen

Class method building a board from a FEN. Returns the board in scalar context and
the board and the side to move in list context. Dies on a malformed FEN. Pass
C<< strict => 1 >> to refuse more than twelve pieces of a colour.

	my ($board, $turn) = Game::Checkers::Board->from_fen($fen);

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
