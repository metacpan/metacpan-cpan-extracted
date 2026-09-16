package Game::Checkers::Move;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Checkers::Squares;

our $VERSION = '0.01';

use constant {
	RM_FROM => 0,
	RM_TO => 1,
	RM_PROMOTED => 2,
	RM_PATH => 3,
	RM_CAPTURES => 4,
	RM_CAPTURED => 5,
	RM_KING => 6,
};

has [qw/from to/] => (
	is => 'ro',
	isa => Int
);

has path => (
	is => 'ro',
	isa => ArrayRef,
	default => []
);

has [qw/captures captured/] => (
	is => 'ro',
	isa => ArrayRef,
	default => []
);

has [qw/promoted king/] => (
	is => 'ro',
	isa => Bool,
	default => 0
);

has side => (
	is => 'ro',
	isa => Str
);

sub from_raw {
	my ($class, $raw, $side) = @_;
	return $class->new(
		from => $raw->[RM_FROM],
		to => $raw->[RM_TO],
		promoted => $raw->[RM_PROMOTED] ? 1 : 0,
		path => [@{$raw->[RM_PATH]}],
		captures => [@{$raw->[RM_CAPTURES]}],
		captured => [@{$raw->[RM_CAPTURED]}],
		king => $raw->[RM_KING] ? 1 : 0,
		side => $side
	);
}

sub to_raw {
	my ($self) = @_;
	my @raw;
	$raw[RM_FROM] = $self->from;
	$raw[RM_TO] = $self->to;
	$raw[RM_PROMOTED] = $self->promoted;
	$raw[RM_PATH] = [@{$self->path}];
	$raw[RM_CAPTURES] = [@{$self->captures}];
	$raw[RM_CAPTURED] = [@{$self->captured}];
	$raw[RM_KING] = $self->king;
	return \@raw;
}

sub is_jump {
	return scalar @{$_[0]->captures} ? 1 : 0;
}

sub notation {
	my ($self) = @_;
	return $self->is_jump
		? join 'x', @{$self->path}
		: sprintf '%d-%d', $self->from, $self->to;
}

sub coord_notation {
	my ($self) = @_;
	my @squares = map { Game::Checkers::Squares::coord_name($_) } @{$self->path};
	return $self->is_jump
		? join 'x', @squares
		: sprintf '%s-%s', $squares[0], $squares[-1];
}

sub stringify {
	return $_[0]->notation;
}

1;

__END__

=head1 NAME

Game::Checkers::Move - one move, with everything it did

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Checkers::Move;

	my $move = Game::Checkers::Move->new(
		from     => 23,
		to       => 7,
		path     => [23, 14, 7],
		captures => [18, 10],
		captured => [1, 1],
		side     => 'white',
	);

	$move->notation;   # '23x14x7'
	$move->is_jump;    # 1

=head1 DESCRIPTION

A value object describing one applied or legal move. It carries the whole jump
path and every captured piece, so a client can animate a move and
L<Game::Checkers/undo> can restore the position exactly, without either of them
re-deriving anything from the board.

=head1 THE RAW MOVE

L<Game::Checkers::Rules> generates moves as unblessed arrayrefs, because the
search visits too many of them to bless one each time. The layout is a documented
interface and its constants live here:

	[ RM_FROM, RM_TO, RM_PROMOTED, RM_PATH, RM_CAPTURES, RM_CAPTURED, RM_KING ]

C<RM_PATH> is the squares landed on including the starting square, C<RM_CAPTURES>
the squares the captured pieces stood on in the order they were jumped,
C<RM_CAPTURED> their position values so a jumped king comes back a king, and
C<RM_KING> whether the piece was already crowned before the move.

=head1 PROPERTIES

=head2 from

Readonly integer, the square the move starts on.

	$move->from;

=head2 to

Readonly integer, the square the move ends on.

	$move->to;

=head2 path

Readonly arrayref of the squares landed on, starting with L</from> and ending
with L</to>. A simple move has two entries and a double jump three.

	$move->path;

=head2 captures

Readonly arrayref of the squares the captured pieces stood on, in the order they
were jumped. Empty for a simple move.

	$move->captures;

=head2 captured

Readonly arrayref of the position values of the captured pieces, in the same
order as L</captures>, so an undo restores a jumped king as a king.

	$move->captured;

=head2 promoted

Readonly boolean, true when the move crowned the moving piece.

	$move->promoted;

=head2 king

Readonly boolean, true when the moving piece was already crowned before the move.

	$move->king;

=head2 side

Readonly string, C<black> or C<white>.

	$move->side;

=head1 FUNCTIONS

=head2 from_raw

Class method building a move from the raw arrayref L<Game::Checkers::Rules>
generates and the side that made it.

	my $move = Game::Checkers::Move->from_raw($raw, 'black');

=head2 to_raw

The raw arrayref for this move.

	my $raw = $move->to_raw;

=head2 is_jump

True when the move captured anything.

	$move->is_jump;

=head2 notation

The move in standard numeric notation: C<11-15> for a simple move and the full
path for a jump, C<23x14x7>. The full path is always emitted, so a stored game is
unambiguous when it is replayed, even though the short form C<23x7> is accepted
on input.

	$move->notation;

=head2 coord_notation

The same move with each square named by its file and rank, C<f6-e5> and
C<e3xc5xe7>. It is what L<Game::Checkers::Terminal> prints, because the board it
draws is lettered and numbered round the edge rather than square by square. A
stored game keeps L</notation>.

	$move->coord_notation;

=head2 stringify

The same as L</notation>.

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
