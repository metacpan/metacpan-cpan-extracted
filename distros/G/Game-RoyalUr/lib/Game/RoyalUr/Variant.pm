package Game::RoyalUr::Variant;

use 5.010;
use strict;
use warnings;

use Carp ();
use Scalar::Util ();
use Object::Proto::Sugar;

our $VERSION = '0.01';

my (@FIELDS, %NAMED, %ALLOWED);
BEGIN {
    @FIELDS = qw(route dice zero_rolls safe_rosettes pieces);
    %NAMED = (
        finkel  => { route => 'short', dice => 4, zero_rolls => 0, safe_rosettes => 1, pieces => 7 },
        masters => { route => 'long',  dice => 3, zero_rolls => 4, safe_rosettes => 0, pieces => 7 },
    );
    %ALLOWED = (
        route         => qr/\A(?:short|long)\z/,
        dice          => qr/\A[34]\z/,
        zero_rolls    => qr/\A[04]\z/,
        safe_rosettes => qr/\A[01]\z/,
        pieces        => qr/\A[1-7]\z/,
    );
}

has route => (is => 'ro', default => 'short');

has dice => (is => 'ro', default => 4);

has zero_rolls => (is => 'ro', default => 0);

has safe_rosettes => (is => 'ro', default => 1);

has pieces => (is => 'ro', default => 7);

sub BUILD {
    my ($self) = @_;
    for my $field (@FIELDS) {
        my $value = $self->$field;
        Carp::croak("Game::RoyalUr::Variant: $field may not be '" . ($value // 'undef') . "'")
            unless defined $value && !ref $value && $value =~ $ALLOWED{$field};
    }
    return;
}

sub fields { @FIELDS }

sub names { sort keys %NAMED }

sub named {
    my ($class, $name) = @_;
    Carp::croak("Game::RoyalUr::Variant: no rule set is called '" . ($name // 'undef')
        . "'; the names are " . join(', ', $class->names))
        unless defined $name && !ref $name && exists $NAMED{$name};
    return $class->new(%{ $NAMED{$name} });
}

sub custom {
    my ($class, %given) = @_;
    for my $key (sort keys %given) {
        Carp::croak("Game::RoyalUr::Variant: no rule is called '$key'") unless exists $ALLOWED{$key};
    }
    return $class->new(%given);
}

sub of {
    my ($class, $rules) = @_;
    return $class->named('finkel') unless defined $rules;
    return $rules if Scalar::Util::blessed($rules) && $rules->isa($class);
    return $class->custom(%$rules) if ref $rules eq 'HASH';
    Carp::croak('Game::RoyalUr::Variant: a rule set is a name, a hash reference or a variant') if ref $rules;
    return $class->named($rules);
}

sub as_hash {
    my ($self) = @_;
    return { map { $_ => $self->$_ } @FIELDS };
}

sub equals {
    my ($self, $other) = @_;
    return 0 unless Scalar::Util::blessed($other) && $other->isa(__PACKAGE__);
    for my $field (@FIELDS) {
        return 0 unless $self->$field eq $other->$field;
    }
    return 1;
}

sub name {
    my ($self) = @_;
    for my $name ($self->names) {
        return $name unless grep { $self->$_ ne $NAMED{$name}{$_} } @FIELDS;
    }
    return undef;
}

sub describe {
    my ($self) = @_;
    return join ' ', map { $_ . '=' . $self->$_ } @FIELDS;
}

1;

__END__

=head1 NAME

Game::RoyalUr::Variant - a rule set of the Royal Game of Ur, as a value

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::RoyalUr::Variant;

    my $finkel  = Game::RoyalUr::Variant->named('finkel');
    my $masters = Game::RoyalUr::Variant->named('masters');

    my $own = Game::RoyalUr::Variant->custom(route => 'long', safe_rosettes => 1);
    print $own->name // $own->describe, "\n";

    my $game = Game::RoyalUr->new(seed => $seed, rules => $masters);

=head1 DESCRIPTION

Nobody knows how the Royal Game of Ur was played. The board survives and the
rules do not, so every set of rules is somebody's reconstruction, and they
differ. A variant is one such set, as five values. It is read and never
changed.

=head2 The two named sets

=over 4

=item C<finkel>

The rules Irving Finkel of the British Museum proposed, and the ones most
people have met. Seven pieces a side and four dice; a throw with nothing
marked moves nothing. A piece follows the short route: four squares of its
own, the eight of the middle row, and two more of its own. A piece standing
on a rosette cannot be captured.

=item C<masters>

The rules James Masters proposed. Seven pieces a side and three dice; a throw
with nothing marked is worth four. A piece follows the long route, which
leaves the middle row a square early, runs round the far end of the board
through the other side's row, and comes home from the other direction, so
that every fourth step is a rosette and nothing past the first four squares
is safe. No rosette protects the piece on it.

=back

Landing on a rosette earns another roll under both, and a piece leaves the
board only on the exact roll under both.

=head2 The five fields

=over 4

=item C<route>

C<'short'>, fourteen steps, or C<'long'>, sixteen.

=item C<dice>

3 or 4.

=item C<zero_rolls>

What a throw with no die marked is worth: 0 or 4.

=item C<safe_rosettes>

1 when a piece standing on a rosette cannot be captured, 0 when it can.

=item C<pieces>

How many a side has, 1 to 7.

=back

Any combination is a rule set that can be played. Only the two above have
names.

=head1 METHODS

=head2 new

    my $variant = Game::RoyalUr::Variant->new(route => 'long', dice => 3);

A variant with the fields given, and C<finkel>'s for the rest. B<Croaks> on a
value a field may not hold.

A key that is not one of the five is not noticed here. Use C<custom>, which
refuses one.

=head2 named

    my $variant = Game::RoyalUr::Variant->named('masters');

One of the named sets. B<Croaks>, listing the names, on anything else.

=head2 custom

    my $variant = Game::RoyalUr::Variant->custom(pieces => 5);

As C<new>, and B<croaks> on a key that is not one of the five, so that a
misspelt rule cannot quietly play the standard game.

=head2 of

    my $variant = Game::RoyalUr::Variant->of($rules);

A variant from whatever a caller has: C<undef> is C<finkel>, a name is the
set of that name, a hash reference is handed to C<custom>, and a variant is
returned as it is.

=head2 names

The names of the named sets, sorted.

=head2 fields

The names of the five fields, in the order they are always written.

=head2 route

=head2 dice

=head2 zero_rolls

=head2 safe_rosettes

=head2 pieces

The five fields. See L</The five fields>.

=head2 name

C<'finkel'> or C<'masters'> when the five values are those of a named set,
however the variant was made, and C<undef> when they are not.

=head2 describe

    route=long dice=4 zero_rolls=0 safe_rosettes=1 pieces=7

The five fields spelled out, in order, on one line.

=head2 as_hash

The five fields as a new hash reference.

=head2 equals

    $one->equals($other)

True when the other is a variant with the same five values.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
