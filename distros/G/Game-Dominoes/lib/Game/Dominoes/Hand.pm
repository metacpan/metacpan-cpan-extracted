package Game::Dominoes::Hand;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

has tiles => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

sub count {
	return scalar @{ $_[0]->tiles };
}

sub is_empty {
	return $_[0]->count ? 0 : 1;
}

sub pips {
	my ($self) = @_;
	my $total = 0;
	$total += $_->pips for @{ $self->tiles };
	return $total;
}

sub add {
	my ($self, @tiles) = @_;
	push @{ $self->tiles }, grep { defined } @tiles;
	return $self;
}

sub holds {
	my ($self, $tile) = @_;
	return 0 unless ref $tile;
	return (grep { $_->id == $tile->id } @{ $self->tiles }) ? 1 : 0;
}

sub remove {
	my ($self, $tile) = @_;
	return undef unless ref $tile;
	my $tiles = $self->tiles;
	for my $i (0 .. $#$tiles) {
		next unless $tiles->[$i]->id == $tile->id;
		return splice @$tiles, $i, 1;
	}
	return undef;
}

sub matching {
	my ($self, @faces) = @_;
	my %want = map { $_ => 1 } grep { defined } @faces;
	return [ grep { $want{ $_->high } || $want{ $_->low } } @{ $self->tiles } ];
}

sub sorted {
	my ($self) = @_;
	return [ sort { $a->id <=> $b->id } @{ $self->tiles } ];
}

sub clone {
	my ($self) = @_;
	return ref($self)->new(tiles => [ @{ $self->tiles } ]);
}

sub stringify {
	my ($self) = @_;
	return join ' ', map { $_->stringify } @{ $self->sorted };
}

1;

__END__

=head1 NAME

Game::Dominoes::Hand - one seat's tiles

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use Game::Dominoes::Hand;

	my $hand = Game::Dominoes::Hand->new(tiles => \@dealt);

	$hand->count;             # public: everybody sees how many
	$hand->tiles;             # private: only the seat sees which
	$hand->holds($tile);
	$hand->remove($tile);
	$hand->matching(6, 4);    # the tiles that could go on those ends
	$hand->pips;              # what it is worth to an opponent at the end

=head1 DESCRIPTION

A seat's tiles, and the smallest class in the distribution that carries a
secret.

C<count> exists beside C<tiles> on purpose. How many tiles a seat holds is
public and which tiles they are is not, so a view carries the first and never
the second, and having two methods makes the difference visible at every call
site rather than hiding it inside a C<scalar @{...}>.

=head1 PROPERTIES

=head2 tiles

	$hand->tiles;

The tiles, as an arrayref. B<Private.> A view carries C<count>, not this.

=head1 FUNCTIONS

=head2 count, is_empty

	$hand->count;      # 9
	$hand->is_empty;   # the seat has gone out

How many tiles are held. Public.

=head2 pips

	$hand->pips;

The pips held, which is what the hand is worth to whoever goes out, and part
of the running total that must always come to 168 across the hands, the
boneyard and the layout.

=head2 add

	$hand->add($tile, $another);

Puts tiles in, from the deal or from a draw.

=head2 holds

	$hand->holds($tile);

Whether the seat holds that tile.

=head2 remove

	my $gone = $hand->remove($tile);

Takes one tile out and returns it, or undef if the seat did not hold it. The
undef is the caller's cue to refuse the play.

=head2 matching

	$hand->matching(6, 4);

The tiles carrying any of those faces, as an arrayref: the seat's candidate
plays against a set of open ends, before anything is said about which arm.

=head2 sorted

	$hand->sorted;

The tiles in canonical order, for printing and for a stable test.

=head2 clone

	$hand->clone;

A copy with its own arrayref. The tiles inside are immutable and shared.

=head2 stringify

	$hand->stringify;   # '6-6 6-4 5-0'

The hand in canonical order, as the notation writes each tile.

=head1 SEE ALSO

L<Game::Dominoes::Tile>, L<Game::Dominoes::Boneyard>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-dominoes at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Dominoes>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Game::Dominoes::Hand

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
