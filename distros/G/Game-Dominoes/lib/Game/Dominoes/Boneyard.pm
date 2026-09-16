package Game::Dominoes::Boneyard;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

has tiles => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

has reserve => (
	is => 'rw',
	isa => Int,
	default => 0
);

sub BUILD {
	my ($self) = @_;
	die 'Game::Dominoes::Boneyard: reserve must not be negative'
		if $self->reserve < 0;
	return $self;
}

sub count {
	return scalar @{ $_[0]->tiles };
}

sub drawable {
	my ($self) = @_;
	my $n = $self->count - $self->reserve;
	return $n > 0 ? $n : 0;
}

sub is_empty {
	return $_[0]->count ? 0 : 1;
}

sub can_draw {
	return $_[0]->drawable ? 1 : 0;
}

sub draw {
	my ($self) = @_;
	return undef unless $self->can_draw;
	return shift @{ $self->tiles };
}

sub peek {
	return [ @{ $_[0]->tiles } ];
}

sub pips {
	my ($self) = @_;
	my $total = 0;
	$total += $_->pips for @{ $self->tiles };
	return $total;
}

1;

__END__

=head1 NAME

Game::Dominoes::Boneyard - the undealt tiles, and the two nobody may draw

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use Game::Dominoes::Boneyard;

	my $yard = Game::Dominoes::Boneyard->new(tiles => \@tiles);

	$yard->count;      # 10, and this is public
	$yard->drawable;   # 8, because the last two are reserved
	$yard->can_draw;   # 1
	my $tile = $yard->draw;

=head1 DESCRIPTION

The tiles nobody was dealt, in the order the seeded shuffle put them. Drawing
takes from the front, so a whole hand is a pure function of the shuffle and
this class never sees a seed.

The count is public and the tiles are not. That split is what makes dominoes
worth adding to a site whose only hidden state has ever been a player's hand,
and it is why C<peek> carries a warning and C<count> does not.

=head1 PROPERTIES

=head2 tiles

	$yard->tiles;   # an arrayref of Game::Dominoes::Tile

What is left, in draw order. Not for a view.

=head2 reserve

	$yard->reserve;   # 0

How many tiles at the back may never be drawn. B<Nought in All Fives>, which
is drawn to empty: a player who cannot play "must draw tiles from the boneyard
until he has a tile to play or the boneyard is empty".

A reserve of one or two is a listed variation on the same page and the rule of
the separate game Draw Dominoes, so it is an attribute rather than a constant.
Set it and a player facing a boneyard of that size passes instead of drawing.

=head1 FUNCTIONS

=head2 count

	$yard->count;   # 10

How many tiles are in the boneyard, the reserve included. This is public: a
player at the table can see those tiles even though nobody may take them.

=head2 drawable

	$yard->drawable;   # 8

How many may actually be taken, which is C<count> less C<reserve>, never
below zero.

=head2 can_draw

	$yard->can_draw;

Whether a draw would produce a tile.

=head2 is_empty

	$yard->is_empty;

Whether there is nothing left at all, reserve included.

=head2 draw

	my $tile = $yard->draw;

The next tile, or undef when only the reserve is left. Removes it.

=head2 peek

	$yard->peek;   # an arrayref copy

What is left, without taking it, for the tests and for the terminal's replay
mode. B<This must never reach a view.>

=head2 pips

	$yard->pips;

The pips still in the boneyard. Part of the running total that must always
come to 168 across the hands, the boneyard and the layout.

=head1 SEE ALSO

L<Game::Dominoes::Set>, where the order comes from.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-dominoes at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Dominoes>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Game::Dominoes::Boneyard

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
