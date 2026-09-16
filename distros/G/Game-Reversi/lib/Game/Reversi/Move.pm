package Game::Reversi::Move;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Reversi::Board;

our $VERSION = '0.01';

has phase => (
	is  => 'ro',
	isa => Str
);

has square => (
	is  => 'ro',
	isa => Int
);

has colour => (
	is  => 'ro',
	isa => Str
);

has flips => (
	is  => 'ro',
	isa => ArrayRef
);

sub BUILD {
	my ($self) = @_;
	my $phase = $self->phase // '';
	die "Game::Reversi::Move: phase must be place or play, not '$phase'"
		unless $phase eq 'place' || $phase eq 'play';

	my $colour = $self->colour // '';
	die "Game::Reversi::Move: colour must be b or w, not '$colour'"
		unless $colour eq 'b' || $colour eq 'w';

	my $square = $self->square;
	die 'Game::Reversi::Move: square must be 0 to 63'
		unless defined $square && $square =~ /\A\d+\z/ && $square < 64;

	my $flips = $self->flips || [];
	die 'Game::Reversi::Move: a placement flips nothing'
		if $phase eq 'place' && @$flips;
	die 'Game::Reversi::Move: a play flips at least one disc'
		if $phase eq 'play' && !@$flips;

	return $self;
}

sub place {
	my ($class, $square, $colour) = @_;
	return $class->new(
		phase => 'place', square => $square, colour => $colour, flips => []);
}

sub play {
	my ($class, $square, $colour, @flips) = @_;
	return $class->new(
		phase => 'play', square => $square, colour => $colour, flips => [ @flips ]);
}

sub name { my ($self) = @_; return Game::Reversi::Board->name_of($self->square) }

sub turned { my ($self) = @_; return scalar @{ $self->flips || [] } }

sub stringify {
	my ($self) = @_;
	return $self->name;
}

1;

__END__

=head1 NAME

Game::Reversi::Move - one placement or one play, and what it turned

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $move = Game::Reversi::Move->place($square, 'b');
    my $move = Game::Reversi::Move->play($square, 'b', @flips);

    $move->phase;    # 'place' or 'play'
    $move->square;   # 0 .. 63
    $move->colour;   # 'b' or 'w'
    $move->flips;    # the squares that turned, in ray order
    $move->name;     # 'd4'

=head1 DESCRIPTION

Reversi has two kinds of move and they are not interchangeable. The first four
plies are B<placements>: a disc goes on one of the four centre squares and
nothing turns. Everything after that is a B<play>: a disc goes on any square
that outflanks something, and at least one disc turns.

Keeping them apart as C<phase> is deliberate. Collapsing them into one kind
would make an opening placement indistinguishable from a play that happened to
turn nothing, which is illegal after the opening, and the game log would lose
the ability to explain itself.

=head2 The turned discs are called flips

Never C<line>. The site that consumes this engine refuses any view carrying a
key named C<line>, among others, because that gate exists to stop a game leaking
the bot's reading of the position. The name is a constraint from outside this
distribution and it is not free to change.

=head1 METHODS

=head2 place

A placement: C<square> and C<colour>, turning nothing.

=head2 play

A play: C<square>, C<colour> and the squares it turns, which must not be empty.

=head2 phase, square, colour, flips

The attributes.

=head2 name

The algebraic name of the square, C<d4> and so on.

=head2 turned

How many discs the move turned.

=head2 stringify

The same as L</name>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
