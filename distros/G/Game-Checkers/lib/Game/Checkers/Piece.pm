package Game::Checkers::Piece;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

my %UI = (
	'b' => "\x{26C2}",
	'B' => "\x{26C3}",
	'w' => "\x{26C0}",
	'W' => "\x{26C1}",
);

has colour => (
	is => 'ro',
	isa => Str
);

has king => (
	is => 'ro',
	isa => Bool,
	default => 0
);

has square => (
	is => 'ro',
	isa => Int
);

sub from_value {
	my ($class, $value, $square) = @_;
	return undef unless $value;
	return $class->new(
		colour => $value > 0 ? 'black' : 'white',
		king => abs($value) == 2 ? 1 : 0,
		square => $square
	);
}

sub value {
	my ($self) = @_;
	my $value = $self->king ? 2 : 1;
	return $self->colour eq 'black' ? $value : -$value;
}

sub is_black {
	return $_[0]->colour eq 'black' ? 1 : 0;
}

sub is_white {
	return $_[0]->colour eq 'white' ? 1 : 0;
}

sub stringify {
	my ($self) = @_;
	my $letter = $self->is_black ? 'b' : 'w';
	return $self->king ? uc $letter : $letter;
}

sub ui_stringify {
	return $UI{$_[0]->stringify};
}

1;

__END__

=head1 NAME

Game::Checkers::Piece - one man or king on the board

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Checkers::Piece;

	my $piece = Game::Checkers::Piece->new(
		colour => 'black',
		king   => 0,
		square => 11,
	);

	$piece->stringify;      # 'b'
	$piece->value;          # 1

=head1 DESCRIPTION

A piece object is built on demand by L<Game::Checkers::Board/piece>. It is never
what the engine stores: a position is an array of signed integers, because the
search copies one for every node it visits. See
L<Game::Checkers::Board/PROPERTIES> for that encoding.

=head1 PROPERTIES

=head2 colour

Readonly string, C<black> or C<white>.

	$piece->colour;

=head2 king

Readonly boolean, true for a crowned piece.

	$piece->king;

=head2 square

Readonly integer, the square 1 to 32 the piece stands on.

	$piece->square;

=head1 FUNCTIONS

=head2 from_value

Class method building a piece from a position value and a square, returning undef
for an empty square.

	Game::Checkers::Piece->from_value(-2, 21);   # a white king on 21

=head2 value

The position encoding of the piece: 1 a black man, 2 a black king, -1 a white man
and -2 a white king.

	$piece->value;

=head2 is_black

True for a black piece.

=head2 is_white

True for a white piece.

=head2 stringify

One letter: C<b> a black man, C<B> a black king, C<w> a white man, C<W> a white
king. This is the spelling FEN uses.

	$piece->stringify;

=head2 ui_stringify

The Unicode draughts symbol for the piece, for a terminal that can print one.

	$piece->ui_stringify;

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
