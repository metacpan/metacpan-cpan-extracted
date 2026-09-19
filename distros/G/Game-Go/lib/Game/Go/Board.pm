package Game::Go::Board;

use 5.010;
use strict;
use warnings;

use Game::Go::Rules;

our $VERSION = '0.01';

sub new {
	my ($class, $engine) = @_;
	die 'Game::Go::Board: wants a Game::Go::Engine' unless ref $engine;
	return bless { engine => $engine }, $class;
}

sub size { $_[0]{engine}->size }

sub at {
	my ($self, $col, $row) = @_;
	my $pt = $self->{engine}->point_of($col, $row);
	return Game::Go::Rules::BORDER if $pt < 0;
	return $self->{engine}->at($pt);
}

sub libs {
	my ($self, $col, $row) = @_;
	my $pt = $self->{engine}->point_of($col, $row);
	return -1 if $pt < 0;
	return $self->{engine}->libs($pt);
}

sub chain_size {
	my ($self, $col, $row) = @_;
	my $pt = $self->{engine}->point_of($col, $row);
	return 0 if $pt < 0;
	return $self->{engine}->chain_size($pt);
}

sub chain_at {
	my ($self, $col, $row) = @_;
	my $engine = $self->{engine};
	my $pt = $engine->point_of($col, $row);
	return [] if $pt < 0;
	return [ map { [ $engine->col_of($_), $engine->row_of($_) ] } @{ $engine->chain_at($pt) } ];
}

sub rows {
	my ($self) = @_;
	my $size = $self->size;
	my @rows;
	for my $row (0 .. $size - 1) {
		push @rows, [ map { $self->at($_, $row) } 0 .. $size - 1 ];
	}
	return \@rows;
}

sub stones { $_[0]{engine}->stones($_[1]) }

sub hash_hex { $_[0]{engine}->hash_hex }

sub zobrist_hex {
	my ($self, $colour, $col, $row) = @_;
	my $pt = $self->{engine}->point_of($col, $row);
	return undef if $pt < 0;
	return $self->{engine}->zobrist_hex($colour, $pt);
}

sub empties {
	my ($self) = @_;
	my $size = $self->size;
	return $size * $size
		- $self->stones(Game::Go::Rules::BLACK)
		- $self->stones(Game::Go::Rules::WHITE);
}

sub to_text {
	my ($self) = @_;
	my %glyph = (
		Game::Go::Rules::EMPTY, '.',
		Game::Go::Rules::BLACK, 'X',
		Game::Go::Rules::WHITE, 'O',
	);
	return join "\n", map { join '', map { $glyph{$_} // '?' } @$_ } @{ $self->rows };
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Go::Board - a readable view of a position, in columns and rows

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $board = $game->board;

    $board->at(3, 3);          # EMPTY, BLACK or WHITE
    $board->libs(3, 3);        # the liberties of the chain there
    print $board->to_text;

=head1 DESCRIPTION

Read-only, and it speaks in columns and rows.

L<Game::Go::Engine> speaks in the C engine's padded indices, which are opaque on
purpose: an index is B<not> C<row * size + col>, and the sentinel ring around the
board is the only thing that makes the engine's neighbour arithmetic safe, so an
index a caller worked out for itself would walk off the board. Nothing in this
class's public interface takes or returns one.

Columns and rows are both 0-based and B<row 0 is the top>, matching the engine's
ordering and SGF's. Human coordinates number rows from the bottom and skip the
letter C<I>; converting between the two belongs to the notation layer and to
nothing else.

=head1 METHODS

=head2 size

=head2 at

    $board->at($col, $row)

The colour at a point: C<EMPTY>, C<BLACK>, C<WHITE>, or C<BORDER> for anything
off the board.

=head2 libs

The exact liberties of the chain at a point, or -1 where there is no stone.

=head2 chain_size

=head2 chain_at

The chain at a point, as an arrayref of C<[$col, $row]> pairs. Empty where there
is no stone.

=head2 rows

The whole position, as an arrayref of arrayrefs of colours, row by row from the
top.

=head2 stones

    $board->stones(Game::Go::Rules::BLACK)

=head2 empties

How many points hold no stone.

=head2 hash_hex

The position's key, as sixteen hex characters. B<Hex and not a number>, because
a 64-bit value on a perl with 32-bit integers goes through an NV and loses bits.
Two positions are the same position when their keys and their stones agree; the
key alone is a filter and never the verdict.

=head2 zobrist_hex

    $board->zobrist_hex($colour, $col, $row)

One point's contribution to that key, or C<undef> off the board. It is public so
the whole key can be recomputed from scratch and compared against the one the
engine maintains a move at a time.

=head2 to_text

The position as text: C<X> for black, C<O> for white, a dot for empty, one line
per row from the top. The same spelling the tests draw their positions in, so a
failure reads against the diagram that caused it.

=head1 SEE ALSO

L<Game::Go>, L<Game::Go::Engine>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
