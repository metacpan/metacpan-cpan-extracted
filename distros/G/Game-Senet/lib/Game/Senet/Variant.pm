package Game::Senet::Variant;

use 5.010;
use strict;
use warnings;

use Carp ();
use Scalar::Util ();
use Object::Proto::Sugar;

use Game::Senet::Engine ();

our $VERSION = '0.02';

my (@FIELDS, @IDENTITY, %NAMED, %ALLOWED);
BEGIN {
    @FIELDS   = qw(exits pieces blockade protect backward reach26 throw_on_26);
    @IDENTITY = grep { $_ ne 'pieces' } @FIELDS;
    %NAMED = (
        kendall => { exits => 'kendall', pieces => 5, blockade => 3, protect => 'run',
                     backward => 1, reach26 => 'exact', throw_on_26 => 0 },
        skyruk  => { exits => 'skyruk', pieces => 5, blockade => 2, protect => 'ends',
                     backward => 1, reach26 => 'any', throw_on_26 => 1 },
    );
    %ALLOWED = (
        exits       => qr/\A(?:kendall|skyruk)\z/,
        pieces      => qr/\A[57]\z/,
        blockade    => qr/\A[023]\z/,
        protect     => qr/\A(?:run|ends|none)\z/,
        backward    => qr/\A[01]\z/,
        reach26     => qr/\A(?:exact|any)\z/,
        throw_on_26 => qr/\A[01]\z/,
    );
}

has exits => (is => 'ro', default => 'kendall');

has pieces => (is => 'ro', default => 5);

has blockade => (is => 'ro', default => 3);

has protect => (is => 'ro', default => 'run');

has backward => (is => 'ro', default => 1);

has reach26 => (is => 'ro', default => 'exact');

has throw_on_26 => (is => 'ro', default => 0);

sub BUILD {
    my ($self) = @_;
    for my $field (@FIELDS) {
        my $value = $self->$field;
        Carp::croak("Game::Senet::Variant: $field may not be '" . ($value // 'undef') . "'")
            unless defined $value && !ref $value && $value =~ $ALLOWED{$field};
    }
    return;
}

sub fields { @FIELDS }

sub names { sort keys %NAMED }

sub named {
    my ($class, $name, %override) = @_;
    Carp::croak("Game::Senet::Variant: no rule set is called '" . ($name // 'undef')
        . "'; the names are " . join(', ', $class->names))
        unless defined $name && !ref $name && exists $NAMED{$name};
    for my $key (sort keys %override) {
        Carp::croak("Game::Senet::Variant: a named set takes pieces and nothing else, not '$key'")
            unless $key eq 'pieces';
    }
    return $class->new(%{ $NAMED{$name} }, %override);
}

sub custom {
    my ($class, %given) = @_;
    for my $key (sort keys %given) {
        Carp::croak("Game::Senet::Variant: no rule is called '$key'") unless exists $ALLOWED{$key};
    }
    return $class->new(%{ $NAMED{kendall} }, %given);
}

sub of {
    my ($class, $rules) = @_;
    return $class->named('kendall') unless defined $rules;
    return $rules if Scalar::Util::blessed($rules) && $rules->isa($class);
    return $class->custom(%$rules) if ref $rules eq 'HASH';
    Carp::croak('Game::Senet::Variant: a rule set is a name, a hash reference or a variant') if ref $rules;
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
        return $name unless grep { $self->$_ ne $NAMED{$name}{$_} } @IDENTITY;
    }
    return undef;
}

sub describe {
    my ($self) = @_;
    my $name = $self->name;
    return join ' ', map { $_ . '=' . $self->$_ } @FIELDS unless defined $name;
    return $self->pieces == 5 ? $name : "$name pieces=" . $self->pieces;
}

sub exit_for {
    my ($self, $house, $roll) = @_;
    Carp::croak('Game::Senet::Variant: an exit is asked of a house from 26 to 30 and a roll from 1 to 5')
        unless defined $house && $house =~ /\A(?:2[6-9]|30)\z/ && defined $roll && $roll =~ /\A[1-5]\z/;
    return [ @{ Game::Senet::Engine->rules($self->as_hash)->{exits}{$house}{$roll} } ];
}

1;

__END__

=head1 NAME

Game::Senet::Variant - a rule set of Senet, as a value

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Game::Senet::Variant;

    my $kendall = Game::Senet::Variant->named('kendall');
    my $seven   = Game::Senet::Variant->named('kendall', pieces => 7);
    my $mine    = Game::Senet::Variant->custom(exits => 'skyruk', protect => 'run');

    print $seven->name, "\n";            # kendall
    print $seven->describe, "\n";        # kendall pieces=7
    print "@{ $kendall->exit_for(26, 1) }\n";    # walk

=head1 DESCRIPTION

The rules a game of Senet is played by, as an immutable value. Two are named:
C<kendall>, after Timothy Kendall's reconstruction as modern sets print it, and
C<skyruk>, the reconstruction published with an open-source implementation of
the game. Any other combination of the fields is a custom set.

=head1 FIELDS

=over 4

=item exits

C<kendall> or C<skyruk>: which named set's table says what a piece on houses 26
to 30 may do with each roll. It names a table and is not a table.

=item pieces

5 or 7 a side.

=item blockade

3, 2, or 0 for none: how many of a side's pieces in a row the other side may not
pass.

=item protect

C<run>, C<ends> or C<none>: which pieces of a run of two or more may not be
swapped.

=item backward

1 when a piece moves back, by the roll, if no piece can move forward.

=item reach26

C<exact>, or C<any> when a piece on house 25 reaches 26 on any roll.

=item throw_on_26

1 when a piece arriving on house 26 is thrown for again, alone.

=back

=head1 CONSTRUCTORS

=head2 new

    my $variant = Game::Senet::Variant->new(%fields);

Sugar's constructor: a field not given takes C<kendall>'s value, and a value no
field may hold croaks. B<A key that is not a field is ignored in silence>, which
is why L</custom> exists.

=head2 named

    my $variant = Game::Senet::Variant->named($name);
    my $variant = Game::Senet::Variant->named($name, pieces => 7);

A named set. C<pieces> may be given, and nothing else. A name that is not one
croaks, listing the names.

=head2 custom

    my $variant = Game::Senet::Variant->custom(%fields);

C<kendall> with the fields given changed. A key that is not a field croaks.

=head2 of

    my $variant = Game::Senet::Variant->of($name_or_hash_or_variant);

A variant from whatever names one: C<undef> for C<kendall>, a name, a hash of
fields, or a variant, which is returned as it is.

=head1 METHODS

=head2 fields

The field names, in order.

=head2 names

The named sets, in order.

=head2 name

The named set this is, C<pieces> aside, or C<undef> for a custom set.

=head2 describe

C<kendall>, C<kendall pieces=7>, or every field for a custom set.

=head2 as_hash

The fields as a hash, in the shape L<Game::Senet::Engine/rules> takes.

=head2 equals

    $a->equals($b)

True when every field, C<pieces> included, is the same.

=head2 exit_for

    my $chain = $variant->exit_for($house, $roll);

What a piece on house 26 to 30 tries with a roll, in order: house numbers and
the words C<off>, C<walk> (house 15, or the first empty house below it) and
C<stay>. An empty list is no move.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
