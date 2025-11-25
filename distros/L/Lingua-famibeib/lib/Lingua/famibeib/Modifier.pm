# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to interact with the famibeib word modifiers


package Lingua::famibeib::Modifier;

use v5.16;
use strict;
use warnings;

use Carp;

our $VERSION = v0.01;

use parent qw(Data::Identifier::Interface::Simple Data::Identifier::Interface::Subobjects);

use constant {
    _GENERATOR => Data::Identifier->new(uuid => '306baa6e-e672-4327-a6b4-ba1d3de89a1e')->register,
};

use overload (
    '""'    => sub { $_[0]->as_string },
    'eq'    => sub {  $_[0]->eq($_[1]) },
    'ne'    => sub { !$_[0]->eq($_[1]) },
    'cmp'   => sub {  $_[0]->cmp($_[1]) },
);

my %_modifiers = (
    (map {$_ => {max_repeat => 0, allow_word => undef}} qw(ab eb ib ub if of ak ek ik ok uk)),
);

$_modifiers{$_}{max_repeat} = 1 foreach qw(eb ib);
$_modifiers{ab}{allow_word} = 1;

my %_registered_by_string;
my %_registered_by_uuid;

foreach my $key (keys %_modifiers) {
    my $d = $_modifiers{$key};
    __PACKAGE__->new(string => $key)->register;
}


sub new {
    my ($pkg, $type, $value, @opts) = @_;
    my $self = bless {}, $pkg;

    croak 'Stray options passed' if scalar @opts;
    croak 'No type given' unless defined $type;
    croak 'No value given' unless defined $value;

    if ($type eq 'from') {
        if (ref $value) {
            if ($value->isa(__PACKAGE__)) {
                # TODO: handle this when @opts are non-empty
                return $value;
            } elsif ($value->isa('Data::Identifier') || $value->isa('Data::Identifier::Interface::Simple') || $value->isa('Data::URIID::Base')) {
                my $id = $value->as('Data::Identifier');
                if (eval {$id->generator->eq(_GENERATOR)} && defined(my $request = $id->request(default => undef, no_defaults => 1))) {
                    $type = 'string';
                    $value = $request;
                } else {
                    if (defined(my $o = $_registered_by_uuid{$id->uuid})) {
                        if (scalar @opts) {
                            $type = 'string';
                            $value = $o->as_string;
                            $self = $o;
                        } else {
                            return $o;
                        }
                    } else {
                        croak 'Unknown word (did you register it or a dictionary?): '.$value;
                    }
                }
            }
        } else {
            $type = 'string';
        }
    }

    if ($type eq 'string') {
        my ($first, $rest);
        my $d;

        $value =~ s/^-//;
        $value = lc($value);

        if (defined(my $o = $_registered_by_string{$value})) {
            return $o;
        }

        ($first, $rest) = $value =~ /^(..)(.*)$/;
        $d = $_modifiers{$first};

        croak 'Invalid modifier: Unknown mora: '.$first unless defined $d;

        if (defined($rest) && length($rest)) {
            if ($rest =~ /^[aeiou][bfklmst]/) {
                my $l = length($rest);

                croak 'Bad string: '.$value if $l & 1;

                $l /= 2;

                croak 'Bad repeat count'   if $l > $d->{max_repeat};
                croak 'Bad repeat pattern' if $rest ne ($first x $l);
            } elsif ($rest =~ /^(?:[bfklmst][aeiou])+\z/ && $d->{allow_word}) {
                # no-op
            } else {
                croak 'Bad string: '.$value;
            }
        }

        $self->{string} = $value;
    } else {
        croak 'Bad type: '.$type;
    }

    return $self;
}


sub as_string {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{string};
}


sub master_mora {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return substr($self->{string}, 0, 2);
}


sub eq {
    my ($self, $other, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return 1 if !defined($self) && !defined($other);
    return undef unless defined($self) && defined($other);

    $self  = __PACKAGE__->new(from => $self) unless eval {$self->isa(__PACKAGE__)};
    $other = __PACKAGE__->new(from => $other) unless eval {$other->isa(__PACKAGE__)};

    return $self->as_string eq $other->as_string;
}


sub cmp {
    my ($self, $other, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return 1 if !defined($self) && !defined($other);
    return undef unless defined($self) && defined($other);

    $self  = __PACKAGE__->new(from => $self) unless eval {$self->isa(__PACKAGE__)};
    $other = __PACKAGE__->new(from => $other) unless eval {$other->isa(__PACKAGE__)};

    return $self->as_string cmp $other->as_string;
}


sub register {
    my ($self) = @_;

    $_registered_by_string{$self->as_string} //= $self;
    $_registered_by_uuid{$self->as('uuid')} //= $self;

    return $self;
}

# ---- Private helpers ----

sub as {
    my ($self, $as, @opts) = @_;
    my $id = $self->{id} //= do {
        require Data::Identifier::Generate;
        my $str = $self->as_string;

        Data::Identifier::Generate->generic(
            request => $str,
            displayname => $str,
            style => 'id-based',
            namespace => '5c2b24f0-e0d9-4746-bd72-0d07061d0dd7',
            generator => _GENERATOR,
        )
    };

    return $id if $as eq 'Data::Identifier' && scalar(@opts) == 0;

    return $id->as($as, @opts);
}

sub displayname {
    my ($self, @opts) = @_;
    return $self->as_string if scalar(@opts) == 0;
    return $self->as('Data::Identifier')->displayname(@opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::famibeib::Modifier - module to interact with the famibeib word modifiers

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use Lingua::famibeib::Modifier;

This package represents a modifier that is applied to a word.
See also L<Lingua::famibeib::Word>.

This module inherits from L<Data::Identifier::Interface::Simple>, and L<Data::Identifier::Interface::Subobjects>.
Instances are overloaded so they will stringify to their string representation as per L</as_string>.

=head2 new

    my Lingua::famibeib::Modifier $modifier = Lingua::famibeib::Modifier->new($type => $value);
    # e.g.:
    my Lingua::famibeib::Modifier $modifier = Lingua::famibeib::Modifier->new(string => 'ik');

(since v0.01)

Creates a new modifier instance.
A modifier is the part of a word that is not it's stem.

Currently the following types (C<$type>) are supported:

=over

=item C<from>

Constructs a word from an object.
If the C<$value> should be a reference.

Currently references to the following types are supported:
L<Data::Identifier>,
L<Data::Identifier::Interface::Simple>,
L<Data::URIID::Base>,
and L<Lingua::famibeib::Modifier>.
More types might be supported.
If C<$value> is not a reference the value is parsed as per C<string>.

=item C<string>

Constructs a modifier from a string.

=back

=head2 as_string

    my $str = $modifier->as_string;

(since v0.01)

Returns the current modifier as a string.

=head2 master_mora

    my $str = $modifier->master_mora;

(experimental since v0.01)

Returns the master mora from the modifier.
This is the first mora of the modifier.
It provides the type of the modifier.

=head2 eq

    my $bool = $modifier->eq($other); # $modifier must be non-undef
    # or:
    my $bool = Lingua::famibeib::Modifier::eq($modifier, $other); # $modifier can be undef

(since v0.01)

Compares two modifier to be equal.

If both modifier are C<undef> they are considered equal.

If C<$modifier> or C<$other> is not an instance of L<Lingua::famibeib::Modifier> or C<undef>
L</new> with the type C<from> is used.

The operators L<perlop/eq> and L<perlop/ne> are overloaded to this method.

=head2 cmp

    my $val = $modifier->cmp($other); # $modifier must be non-undef
    # or:
    my $val = Lingua::famibeib::Modifier::cmp($modifier, $other); # $modifier can be undef

(experimental since v0.01)

Compares the modifier similar to C<cmp>. This method can be used to order modifier.
To check for them to be equal see L</eq>.

The parameters are parsed the same way as L</eq>.

The operator L<perlop/cmp> is overloaded to this method.

If this method is used for sorting the exact resulting order is not defined. However:

=over

=item *

The order is stable

=item *

The order is the same for C<$a-E<gt>cmp($b)> as for C<- $b-E<gt>cmp($a)>.

=back

=head2 register

    $modifier->register;

(since v0.01)

Registers the modifier with this module.
A registered modifier will be kept in memory indefinitely.
It is used for deduplication and some types of lookups.

This method will return C<$modifier>.
This can be used to build constants.

B<Note:>
Calling this multiple times on the same modifier is fine.
However, doing so might waste some time.

B<Note:>
Base and common modifiers are already registered by this module.
Hence it is hardly needed to call this method at all.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
