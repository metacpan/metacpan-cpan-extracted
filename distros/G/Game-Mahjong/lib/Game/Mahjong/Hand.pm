package Game::Mahjong::Hand;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Mahjong::Tiles;
use Game::Mahjong::Notation;
use Game::Mahjong::Meld;

our $VERSION = '0.01';

use constant FULL => 13;

has counts => (is => 'ro', isa => ArrayRef, default => sub { [ (0) x (Game::Mahjong::Tiles::KINDS + 1) ] });

has melds => (is => 'ro', isa => ArrayRef, default => []);

has flowers => (is => 'ro', isa => ArrayRef, default => []);

has waits => (is => 'rw');

sub from_tiles {
	my ($class, $tiles) = @_;
	my $self = $class->new;
	$self->add($_) for @$tiles;
	return $self;
}

sub from_notation {
	my ($class, $string) = @_;
	my $parsed = Game::Mahjong::Notation::parse_hand($string);
	my $self = $class->new;
	$self->add($_) for @{ $parsed->{concealed} };
	$self->add_flower($_) for @{ $parsed->{flowers} };
	push @{ $self->melds }, Game::Mahjong::Meld->new(%$_) for @{ $parsed->{melds} };
	return $self;
}

sub _kind {
	my ($kind) = @_;
	Game::Mahjong::Tiles::code_of($kind);
	die 'Game::Mahjong::Hand: a bonus tile is never in the hand; add_flower takes it'
		if Game::Mahjong::Tiles::is_bonus($kind);
	return $kind;
}

sub add {
	my ($self, $kind) = @_;
	_kind($kind);
	die 'Game::Mahjong::Hand: a fifth ' . Game::Mahjong::Tiles::code_of($kind)
		if $self->counts->[$kind] >= Game::Mahjong::Tiles::PER_KIND;
	$self->counts->[$kind]++;
	$self->waits(undef);
	return $self;
}

sub remove {
	my ($self, $kind) = @_;
	_kind($kind);
	die 'Game::Mahjong::Hand: no ' . Game::Mahjong::Tiles::code_of($kind) . ' to remove'
		unless $self->counts->[$kind] > 0;
	$self->counts->[$kind]--;
	$self->waits(undef);
	return $self;
}

sub add_flower {
	my ($self, $kind) = @_;
	Game::Mahjong::Tiles::code_of($kind);
	die 'Game::Mahjong::Hand: ' . Game::Mahjong::Tiles::code_of($kind) . ' is not a bonus tile'
		unless Game::Mahjong::Tiles::is_bonus($kind);
	die 'Game::Mahjong::Hand: ' . Game::Mahjong::Tiles::code_of($kind) . ' is exposed already'
		if grep { $_ == $kind } @{ $self->flowers };
	push @{ $self->flowers }, $kind;
	@{ $self->flowers } = sort { $a <=> $b } @{ $self->flowers };
	return $self;
}

sub count {
	my ($self, $kind) = @_;
	_kind($kind);
	return $self->counts->[$kind];
}

sub size {
	my ($self) = @_;
	my $n = 0;
	$n += $_ for @{ $self->counts };
	return $n;
}

sub tiles {
	my ($self) = @_;
	my $counts = $self->counts;
	return map { ($_) x $counts->[$_] } grep { $counts->[$_] } 1 .. Game::Mahjong::Tiles::KINDS;
}

sub kinds {
	my ($self) = @_;
	my $counts = $self->counts;
	return grep { $counts->[$_] } 1 .. Game::Mahjong::Tiles::KINDS;
}

sub meld_count { return scalar @{ $_[0]->melds } }

sub total { return $_[0]->size + 3 * $_[0]->meld_count }

sub expects { return FULL - 3 * $_[0]->meld_count }

sub is_concealed {
	my ($self) = @_;
	return (grep { !$_->concealed } @{ $self->melds }) ? 0 : 1;
}

sub concealed_kongs { return [ grep { $_->concealed } @{ $_[0]->melds } ] }

sub holds_pair { return $_[0]->count($_[1]) >= 2 ? 1 : 0 }

sub holds_pung_of { return $_[0]->count($_[1]) >= 3 ? 1 : 0 }

sub holds_kong_of { return $_[0]->count($_[1]) == 4 ? 1 : 0 }

sub exposed_pung_of {
	my ($self, $kind) = @_;
	_kind($kind);
	for my $meld (@{ $self->melds }) {
		return $meld if $meld->kind eq 'pung' && !$meld->concealed && $meld->tile == $kind;
	}
	return undef;
}

sub chow_shapes {
	my ($self, $kind) = @_;
	_kind($kind);
	my $suit = Game::Mahjong::Tiles::suit_of($kind);
	return () unless defined $suit;
	my $rank = Game::Mahjong::Tiles::rank_of($kind);
	my $counts = $self->counts;
	my @shapes;
	for my $low ($rank - 2 .. $rank) {
		next if $low < 1 || $low + 2 > 9;
		my @others = grep { $_ != $kind } map { $kind + ($_ - $rank) } $low .. $low + 2;
		next unless $counts->[ $others[0] ] && $counts->[ $others[1] ];
		push @shapes, [ @others ];
	}
	return @shapes;
}

sub _meld {
	my ($self, $meld) = @_;
	push @{ $self->melds }, $meld;
	$self->waits(undef);
	return $meld;
}

sub claim_chow {
	my ($self, $kind, $p, $q, $from) = @_;
	_kind($_) for $kind, $p, $q;
	my ($x, $y) = sort { $a <=> $b } $p, $q;
	die 'Game::Mahjong::Hand: those two tiles are not both held'
		unless $self->count($x) && $self->count($y) && ($x != $y || $self->count($x) >= 2);
	my $meld = Game::Mahjong::Meld->new(
		kind => 'chow', tiles => [ $kind, $x, $y ],
		claimed_from => $from, claimed_tile => $kind,
	);
	$self->remove($x)->remove($y);
	return $self->_meld($meld);
}

sub claim_pung {
	my ($self, $kind, $from) = @_;
	die 'Game::Mahjong::Hand: a pung needs a pair in hand' unless $self->holds_pair($kind);
	my $meld = Game::Mahjong::Meld->new(
		kind => 'pung', tiles => [ ($kind) x 3 ],
		claimed_from => $from, claimed_tile => $kind,
	);
	$self->remove($kind)->remove($kind);
	return $self->_meld($meld);
}

sub claim_kong {
	my ($self, $kind, $from) = @_;
	die 'Game::Mahjong::Hand: a claimed kong needs three in hand' unless $self->holds_pung_of($kind);
	my $meld = Game::Mahjong::Meld->new(
		kind => 'kong', tiles => [ ($kind) x 4 ],
		claimed_from => $from, claimed_tile => $kind,
	);
	$self->remove($kind) for 1 .. 3;
	return $self->_meld($meld);
}

sub concealed_kong {
	my ($self, $kind) = @_;
	die 'Game::Mahjong::Hand: a concealed kong needs four in hand' unless $self->holds_kong_of($kind);
	my $meld = Game::Mahjong::Meld->new(kind => 'kong', tiles => [ ($kind) x 4 ], concealed => 1);
	$self->remove($kind) for 1 .. 4;
	return $self->_meld($meld);
}

sub promote_kong {
	my ($self, $kind) = @_;
	my $pung = $self->exposed_pung_of($kind)
		or die 'Game::Mahjong::Hand: no exposed pung of ' . Game::Mahjong::Tiles::code_of($kind) . ' to promote';
	die 'Game::Mahjong::Hand: the fourth ' . Game::Mahjong::Tiles::code_of($kind) . ' is not in hand'
		unless $self->count($kind);
	my $kong = $pung->promote;
	@{ $self->melds } = map { $_ == $pung ? $kong : $_ } @{ $self->melds };
	$self->remove($kind);
	$self->waits(undef);
	return $kong;
}

sub clone {
	my ($self) = @_;
	return ref($self)->new(
		counts  => [ @{ $self->counts } ],
		melds   => [ @{ $self->melds } ],
		flowers => [ @{ $self->flowers } ],
		waits   => $self->waits ? [ @{ $self->waits } ] : undef,
	);
}

sub to_notation {
	my ($self) = @_;
	return Game::Mahjong::Notation::print_hand({
		concealed => [ $self->tiles ],
		melds     => [ map { $_->to_hash } @{ $self->melds } ],
		flowers   => [ @{ $self->flowers } ],
	});
}

1;

__END__

=head1 NAME

Game::Mahjong::Hand - one seat's tiles: the counts, the melds, the flowers

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $hand = Game::Mahjong::Hand->from_notation('123m 55p EEE 78s');
    $hand->add(27);                     # a drawn nine of bamboo
    $hand->size;                        # 14
    $hand->chow_shapes(24);             # the pairs in hand that run with a six of bamboo
    my $meld = $hand->claim_pung(28, 2);  # the pair of east winds and seat 2's discard
    $hand->expects;                     # 10: thirteen less three a meld

=head1 DESCRIPTION

The concealed tiles are a count vector over the thirty-four kinds, because
tiles of a kind are identical and every question the rules and the
decomposer ask is about counts. The melds are L<Game::Mahjong::Meld>
objects in the order they were made; the flowers are the exposed bonus
tiles.

=head2 Thirteen between turns

A seat holds thirteen tiles between turns counting three for every meld
(3.4.29); C<expects> is that number for the melds so far, and C<total> is
the concealed count plus three a meld, fourteen for a complete hand
whatever its kongs.

=head2 The claims are mechanics, not rules

C<claim_chow>, C<claim_pung>, C<claim_kong>, C<concealed_kong> and
C<promote_kong> move the tiles and build the meld, and die if the tiles are
not there: that is a programmer error. Whether the seat MAY claim (its
turn, the window, the seat to the left, the kong after a chow) is
L<Game::Mahjong::Rules>' question, answered with a code before any of these
is called.

=head2 The waits are a cache

C<waits> is the list of kinds that complete the hand, filled by
L<Game::Mahjong::Shanten> only when the hand is one from ready, and cleared
by every change to the tiles or the melds. It is what makes "can this seat
win on the tile" a lookup when a window opens.

=head1 ATTRIBUTES

=head2 counts

An arrayref of thirty-five: index 1 to 34 the count of that kind, index 0
unused.

=head2 melds

The melds made, in order.

=head2 flowers

The exposed bonus tiles, sorted.

=head2 waits

The cached waits, or undef when not computed.

=head1 METHODS

=head2 from_tiles

A hand from a list of kinds.

=head2 from_notation

A hand from a notation string with melds and flowers.

=head2 add, remove

One tile in or out. Both die on a bonus tile and C<remove> dies below zero.

=head2 add_flower

One bonus tile exposed. Dies on a second of the same.

=head2 count

How many of a kind are concealed.

=head2 size

How many tiles are concealed.

=head2 tiles

The concealed tiles as a sorted list with repeats.

=head2 kinds

The distinct kinds held, sorted.

=head2 meld_count, total, expects

As above.

=head2 is_concealed

No exposed meld; a concealed kong does not count against it.

=head2 concealed_kongs

The concealed kongs, to be shown at the end of the hand.

=head2 holds_pair, holds_pung_of, holds_kong_of

Two or more, three or more, exactly four of a kind concealed.

=head2 exposed_pung_of

The exposed pung of a kind, for promotion, or undef.

=head2 chow_shapes

    my @pairs = $hand->chow_shapes($kind);

Every pair of concealed tiles that makes a chow with the kind, each a
sorted two-element arrayref, lowest chow first; empty for an honour.

=head2 claim_chow, claim_pung, claim_kong, concealed_kong, promote_kong

The mechanics above. Each returns the meld.

=head2 clone

A copy the caller may change.

=head2 to_notation

The hand as a notation string.

=head2 FULL

Thirteen.

=head1 SEE ALSO

L<Game::Mahjong::Meld>, L<Game::Mahjong::Wall>, L<Game::Mahjong::Notation>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
