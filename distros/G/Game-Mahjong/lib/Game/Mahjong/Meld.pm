package Game::Mahjong::Meld;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Mahjong::Tiles;
use Game::Mahjong::Notation;

our $VERSION = '0.01';

our %KIND;
BEGIN { %KIND = (chow => 3, pung => 3, kong => 4) }

has kind => (is => 'ro', isa => Str, required => 1);

has tiles => (is => 'ro', isa => ArrayRef, required => 1);

has concealed => (is => 'ro', default => 0);

has claimed_from => (is => 'ro');

has claimed_tile => (is => 'ro');

has promoted => (is => 'ro', default => 0);

sub BUILD {
	my ($self) = @_;
	my $kind = $self->kind;
	die "Game::Mahjong::Meld: no such kind '$kind'" unless $KIND{$kind};

	my @tiles = sort { $a <=> $b } @{ $self->tiles };
	die "Game::Mahjong::Meld: a $kind is $KIND{$kind} tiles, not " . scalar @tiles
		unless @tiles == $KIND{$kind};
	Game::Mahjong::Tiles::code_of($_) for @tiles;
	die 'Game::Mahjong::Meld: a bonus tile is never in a meld'
		if grep { Game::Mahjong::Tiles::is_bonus($_) } @tiles;

	if ($kind eq 'chow') {
		my $suit = Game::Mahjong::Tiles::suit_of($tiles[0]);
		die 'Game::Mahjong::Meld: a chow is three consecutive tiles of one suit'
			unless defined $suit
			&& $tiles[1] == $tiles[0] + 1 && $tiles[2] == $tiles[1] + 1
			&& Game::Mahjong::Tiles::rank_of($tiles[0]) <= 7;
	}
	else {
		die "Game::Mahjong::Meld: a $kind is identical tiles"
			if grep { $_ != $tiles[0] } @tiles;
	}

	die 'Game::Mahjong::Meld: a claimed meld names the tile it took'
		if defined $self->claimed_from && !defined $self->claimed_tile;
	die 'Game::Mahjong::Meld: the claimed tile is not in the meld'
		if defined $self->claimed_tile && !grep { $_ == $self->claimed_tile } @tiles;
	die 'Game::Mahjong::Meld: a concealed meld was claimed from nobody'
		if $self->concealed && defined $self->claimed_from;
	die 'Game::Mahjong::Meld: only a kong is promoted'
		if $self->promoted && $kind ne 'kong';

	@{ $self->tiles } = @tiles;
	return;
}

sub is_chow { return $_[0]->kind eq 'chow' ? 1 : 0 }

sub is_pung { return $_[0]->kind eq 'chow' ? 0 : 1 }

sub is_kong { return $_[0]->kind eq 'kong' ? 1 : 0 }

sub size { return scalar @{ $_[0]->tiles } }

sub counts_as { return 3 }

sub tile { return $_[0]->tiles->[0] }

sub suit { return Game::Mahjong::Tiles::suit_of($_[0]->tiles->[0]) }

sub rank { return Game::Mahjong::Tiles::rank_of($_[0]->tiles->[0]) }

sub is_honour { return Game::Mahjong::Tiles::is_honour($_[0]->tiles->[0]) }

sub has_terminal {
	my ($self) = @_;
	return (grep { Game::Mahjong::Tiles::is_terminal($_) } @{ $self->tiles }) ? 1 : 0;
}

sub is_outside {
	my ($self) = @_;
	return $self->is_honour || $self->has_terminal ? 1 : 0;
}

sub is_exposed {
	my ($self) = @_;
	return $self->concealed ? 0 : 1;
}

sub promote {
	my ($self) = @_;
	die 'Game::Mahjong::Meld: only an exposed pung is promoted to a kong'
		unless $self->kind eq 'pung' && !$self->concealed;
	return ref($self)->new(
		kind         => 'kong',
		tiles        => [ @{ $self->tiles }, $self->tile ],
		claimed_from => $self->claimed_from,
		claimed_tile => $self->claimed_tile,
		promoted     => 1,
	);
}

sub equals {
	my ($self, $other) = @_;
	return 0 unless ref $other && $other->can('kind');
	return $self->kind eq $other->kind
		&& $self->concealed == $other->concealed
		&& join(',', @{ $self->tiles }) eq join(',', @{ $other->tiles }) ? 1 : 0;
}

sub to_hash {
	my ($self) = @_;
	return {
		kind      => $self->kind,
		tiles     => [ @{ $self->tiles } ],
		concealed => $self->concealed ? 1 : 0,
	};
}

sub to_notation {
	my ($self) = @_;
	return Game::Mahjong::Notation::print_meld($self->to_hash);
}

1;

__END__

=head1 NAME

Game::Mahjong::Meld - a chow, a pung or a kong

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $chow = Game::Mahjong::Meld->new(kind => 'chow', tiles => [ 2, 3, 4 ],
        claimed_from => 3, claimed_tile => 3);
    my $kong = Game::Mahjong::Meld->new(kind => 'kong', tiles => [ 28, 28, 28, 28 ],
        concealed => 1);
    $chow->is_chow;        # 1
    $kong->is_pung;        # 1, a kong counts wherever a pung does
    $kong->counts_as;      # 3, for the fourteen-tile count

=head1 DESCRIPTION

A value object. Immutable after construction; C<promote> returns a new one.

=head2 A kong is a pung

Every fan that says "pung or kong" (Big Four Winds, All Pungs, Dragon
Pung, and the rest) counts a kong, so C<is_pung> is true of a kong and
C<is_kong> tells the two apart. A kong is four tiles on the table and three
in the fourteen-tile count (3.11.6.6: "not counting ... the 4th tile in a
Kong"), which is what C<size> and C<counts_as> say.

=head2 Concealed

A concealed kong is declared from four tiles in hand and shown at the end;
the hand stays concealed (3.6.8). A chow or pung with C<concealed> set is
a set the decomposer found inside a concealed hand and never a meld on the
table; the rules never build one.

=head2 What it refuses

A chow with a gap, across suits, or of honours; a pung or kong of different
tiles; a bonus tile in any meld; a claimed meld that does not name the tile
it took; a concealed meld claimed from somebody; a promoted chow or pung.
All die: these are programmer errors, and a player's mistake is refused by
the rules before a meld is built.

=head1 ATTRIBUTES

=head2 kind

C<chow>, C<pung> or C<kong>.

=head2 tiles

The kinds, sorted ascending.

=head2 concealed

1 for a concealed kong.

=head2 claimed_from

The seat, 0 to 3, whose discard made the meld; undef for a concealed kong.

=head2 claimed_tile

The kind that was claimed.

=head2 promoted

1 for a kong made by adding the fourth tile to an exposed pung.

=head1 METHODS

=head2 is_chow, is_pung, is_kong

As above.

=head2 size

3 or 4.

=head2 counts_as

3.

=head2 tile

The kind of a pung or kong; the lowest kind of a chow.

=head2 suit, rank

Of C<tile>; undef for an honour.

=head2 is_honour

Whether the meld is of a wind or a dragon.

=head2 has_terminal

Whether any tile is a one or a nine (a 1-2-3 chow has one).

=head2 is_outside

Honour or terminal in it: what fan 55 asks of every set.

=head2 is_exposed

The opposite of C<concealed>.

=head2 promote

A new kong from an exposed pung, keeping where the pung came from.

=head2 equals

Same kind, tiles and concealment.

=head2 to_hash, to_notation

The plain hash L<Game::Mahjong::Notation> speaks, and its token.

=head1 SEE ALSO

L<Game::Mahjong::Hand>, L<Game::Mahjong::Notation>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
