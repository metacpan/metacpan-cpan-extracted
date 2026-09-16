package Game::Dominoes::Tile;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

sub _offset { my ($l) = @_; return 7 * $l - ($l * ($l - 1)) / 2 }

has high => (
	is => 'ro',
	isa => Int
);

has low => (
	is => 'ro',
	isa => Int
);

sub BUILD {
	my ($self) = @_;
	for my $face (qw/high low/) {
		my $v = $self->$face;
		die "Game::Dominoes::Tile: $face must be a face from 0 to 6"
			unless defined $v && $v =~ /\A[0-6]\z/;
	}
	die 'Game::Dominoes::Tile: high must not be less than low'
		if $self->high < $self->low;
	return $self;
}

sub of {
	my ($class, $a, $b) = @_;
	($a, $b) = ($b, $a) if defined $a && defined $b && $a < $b;
	return $class->new(high => $a, low => $b);
}

sub id {
	my ($self) = @_;
	return _offset($self->low) + ($self->high - $self->low) + 1;
}

sub from_id {
	my ($class, $id) = @_;
	die "Game::Dominoes::Tile: no tile has id " . (defined $id ? $id : 'undef')
		unless defined $id && $id =~ /\A\d+\z/ && $id >= 1 && $id <= 28;
	for my $low (reverse 0 .. 6) {
		my $offset = _offset($low);
		next if $offset >= $id;
		return $class->new(low => $low, high => $low + ($id - $offset - 1));
	}
	die 'unreachable';
}

sub is_double {
	return $_[0]->high == $_[0]->low ? 1 : 0;
}

sub pips {
	return $_[0]->high + $_[0]->low;
}

sub has_face {
	my ($self, $face) = @_;
	return 0 unless defined $face;
	return ($self->high == $face || $self->low == $face) ? 1 : 0;
}

sub other {
	my ($self, $face) = @_;
	die 'Game::Dominoes::Tile: that tile does not carry face '
		. (defined $face ? $face : 'undef')
		unless $self->has_face($face);
	return $self->high == $face ? $self->low : $self->high;
}

sub equals {
	my ($self, $other) = @_;
	return 0 unless ref $other;
	return $self->id == $other->id ? 1 : 0;
}

sub stringify {
	my ($self) = @_;
	return $self->high . '-' . $self->low;
}

1;

__END__

=head1 NAME

Game::Dominoes::Tile - one bone of a double six set

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use Game::Dominoes::Tile;

	my $tile = Game::Dominoes::Tile->of(4, 6);

	$tile->high;         # 6
	$tile->low;          # 4
	$tile->pips;         # 10
	$tile->is_double;    # 0
	$tile->id;           # 25
	$tile->other(6);     # 4
	$tile->stringify;    # '6-4'

=head1 DESCRIPTION

An immutable value object. C<high> is never less than C<low>, so a tile has
exactly one representation and two tiles are the same tile when their ids are
equal: there is no separate 4-6 to keep in step with 6-4.

The id is the tile's place in the canonical order of the set, 0-0 first and
6-6 last, and it is what the event log and the notation store. It is stable
across processes, machines and perls, so it is part of the wire format and is
not to be renumbered.

Faces run from 0 to 6. A face outside that, or a C<high> below C<low>, is a
programmer error and dies; nothing a player can do reaches this class.

=head1 FUNCTIONS

=head2 of

	my $tile = Game::Dominoes::Tile->of(4, 6);

The tile carrying two faces, given in either order. This is the constructor
to use: C<new> wants them sorted already.

=head2 from_id

	my $tile = Game::Dominoes::Tile->from_id(25);

The tile with that id, 1 to 28. Dies outside that range.

=head2 high, low

	$tile->high;   # 6
	$tile->low;    # 4

The larger and smaller face. Equal on a double.

=head2 id

	$tile->id;     # 25

Its place in the canonical order of the set, from 1 to 28.

=head2 is_double

	$tile->is_double;   # 1 for 5-5

Whether both faces are the same.

=head2 pips

	$tile->pips;   # 10 for 6-4

The two faces added together. The whole set holds 168 pips, which is worth
asserting as an invariant over the hands, the boneyard and the layout.

=head2 has_face

	$tile->has_face(6);   # 1

Whether the tile carries that face, and so whether it can be played against
an end showing it.

=head2 other

	$tile->other(6);   # 4

The face left showing when C<$face> is matched. A double leaves itself. Dies
if the tile does not carry the face, because that is a programmer error:
whether a tile can be played is settled before it is turned round.

=head2 equals

	$tile->equals($other);

Whether two tiles are the same tile.

=head2 stringify

	$tile->stringify;   # '6-4'

The tile as the notation writes it, higher face first.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-dominoes at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Dominoes>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Game::Dominoes::Tile

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
