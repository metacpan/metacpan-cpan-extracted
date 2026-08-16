# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to interact with famibeib word prefixes


package Lingua::famibeib::Prefix;

use v5.16;
use strict;
use warnings;

use Carp;
use Data::Identifier;

our $VERSION = v0.07;

use parent qw(Data::Identifier::Interface::Simple Data::Identifier::Interface::Subobjects);

use constant {
    _GENERATOR          => Data::Identifier->new(uuid => '6574c0af-1389-4db7-96ac-3087b6202bd2')->register,
};

use overload (
    '""'    => \&as_string,
    'eq'    => sub {  $_[0]->eq($_[1]) },
    'ne'    => sub { !$_[0]->eq($_[1]) },
    'cmp'   => sub {  $_[0]->cmp($_[1]) },
);

my %_registered_by_string;
my %_registered_by_uuid;

# Preregister most common prefixes:
__PACKAGE__->new(string => $_)->register foreach qw(ba be  fa fe fi fo fu  ta to tu);


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
                my $generator = eval {$id->generator};
                my $request;

                if (defined($generator) && $generator->eq(_GENERATOR) && defined($request = $id->request(default => undef, no_defaults => 1))) {
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
                        croak 'Unknown prefix (did you register it or a dictionary?): '.$value;
                    }
                }
            }
        } else {
            $type = 'string';
        }
    }

    if ($type eq 'string') {
        if ($value =~ /[\s\.,\!\?]/) {
            croak 'Multi prefix string passed. Consider using Lingua::famibeib::Text if this is what you wanted';
        }

        $value = lc($value);

        if ($value =~ /^[bfklmst][aeiou](?:[bfklmst][aeiou])*\z/m) {
            $self = $_registered_by_string{$value} // $self;
            $self->{string} = $value;
        } else {
            croak 'Bad string: '.$value;
        }
    } else {
        croak 'Bad type: '.$type;
    }


    return $self;
}


sub as_string {
    my ($self) = @_;
    return $self->{string};
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

    {
        my $str_self  = $self->as_string;
        my $str_other = $other->as_string;

        return $str_self cmp $str_other;
    }

    croak 'BUG!';
}


#@returns __PACKAGE__
sub register {
    my ($self) = @_;
    my Data::Identifier $id = $self->as('Data::Identifier');
    my $string = $self->as_string;

    $_registered_by_string{$string} //= $self;
    $_registered_by_uuid{$id->uuid} //= $self;

    if (length($string) == 2) {
        # If it's the root prefix, also register the Identifier.
        $id->register;
    }

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
            tagname => $str,
            style => 'id-based',
            namespace => 'e75ce34a-a8a6-4f6c-aef1-6dad279118e0',
            generator => _GENERATOR,
        )
    };

    return $id if $as eq 'Data::Identifier' && scalar(@opts) == 0;

    return $id->as($as, @opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::famibeib::Prefix - module to interact with famibeib word prefixes

=head1 VERSION

version v0.07

=head1 SYNOPSIS

    use Lingua::famibeib::Prefix;

(since v0.06)

This package is used to store famibeib word prefixes and query them about their properties.

This module inherits from L<Data::Identifier::Interface::Simple>, and L<Data::Identifier::Interface::Subobjects>.
Instances are overloaded so they will stringify to their string representation as per L</as_string>.

=head1 METHODS

=head2 new

    my Lingua::famibeib::Prefix $prefix = Lingua::famibeib::Prefix->new($type => $value);
    # e.g:
    my Lingua::famibeib::Prefix $prefix = Lingua::famibeib::Prefix->new(string => $str);

(since v0.06)

Constructs a new prefix.
The prefix is normalised as part of this.
This method might deduplicate instances.
So not all instances might be new objects.

Currently the following types (C<$type>) are supported:

=over

=item C<from>

(since v0.06)

Constructs a prefix from an object.
C<$value> should be a reference.

Currently references to the following types are supported:
L<Data::Identifier>,
L<Data::Identifier::Interface::Simple>,
L<Data::URIID::Base>,
and L<Lingua::famibeib::Prefix>.
More types might be supported.

If C<$value> is not a reference the value is parsed as per C<string> if it looks like a prefix string (experimental since v0.06).

=item C<string>

(since v0.06)

Constructs a prefix from it's string representation.

=back

=head2 as_string

    my $str = $prefix->as_string;

(since v0.06)

Returns the string representation of the prefix.

=head2 eq

    my $bool = $prefix->eq($other); # $prefix must be non-undef
    # or:
    my $bool = Lingua::famibeib::Prefix::eq($prefix, $other); # $prefix can be undef

(since v0.06)

Compares two prefixes to be equal.

If both prefixes are C<undef> they are considered equal.

If C<$prefix> or C<$other> is not an instance of L<Lingua::famibeib::Prefix> or C<undef>
L</new> with the type C<from> is used.

The operators L<perlop/eq> and L<perlop/ne> are overloaded to this method.

=head2 cmp

    my $val = $prefix->cmp($other); # $prefix must be non-undef
    # or:
    my $val = Lingua::famibeib::Prefix::cmp($prefix, $other); # $prefix can be undef

(experimental since v0.06)

Compares the prefixes similar to C<cmp>. This method can be used to order prefixes.
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

    $prefix->register;

(since v0.06)

Registers the prefix with this module.
A registered prefix will be kept in memory indefinitely.
It is used for deduplication and some types of lookups.

This method will return C<$prefix>.
This can be used to build constants.

B<Note:>
Calling this multiple times on the same prefix is fine.
However, doing so might waste some time.

B<Note:>
It is undefined (since v0.06) whether or not this will also register
the corresponding L<Data::Identifier>.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
