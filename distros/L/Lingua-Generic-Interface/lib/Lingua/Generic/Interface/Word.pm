# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to interact with the words of any language


package Lingua::Generic::Interface::Word;

use v5.20;
use strict;
use warnings;

use Carp;
use Data::Identifier v0.34;

our $VERSION = v0.01;

use parent qw(Data::Identifier::Interface::Subobjects Data::Identifier::Interface::Simple);

use overload (
    '""'    => \&as_string,
    'eq'    => sub {  $_[0]->eq($_[1]) },
    'ne'    => sub { !$_[0]->eq($_[1]) },
    'cmp'   => sub {  $_[0]->cmp($_[1]) },
);



sub new {
    my ($pkg, $type, $value, @opts) = @_;

    croak 'No type given' unless defined $type;
    croak 'No value given' unless defined $value;
    croak 'Stray options passed' if scalar @opts;

    if ($type eq 'from') {
        if (ref $value) {
            if ($value->isa(__PACKAGE__)) {
                return $value;
            } else {
                ...
            }
        } else {
            $type = 'string';
        }
    } elsif ($type eq 'ise') {
        ...
    }

    if ($type eq 'string') {
        return bless {
            string => $value,
        }, $pkg;
    } else {
        croak 'Bad type: '.$type;
    }
}


sub as_string {
    my ($self, @opts) = @_;
    return $self->{string} // confess 'BUG: No valid string';
}


sub eq {
    my ($self, $other, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return 1 if !defined($self) && !defined($other);
    return undef unless defined($self) && defined($other);

    $self  = __PACKAGE__->new(from => $self) unless eval {$self->isa(__PACKAGE__)};
    $other = __PACKAGE__->new(from => $other) unless eval {$other->isa(__PACKAGE__)};

    return undef unless ref($self) eq ref($other);

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
        my $v = ref($self) cmp ref($other);
        return $v if $v != 0;
    }

    {
        my $str_self  = $self->as_string;
        my $str_other = $other->as_string;

        return $str_self cmp $str_other;
    }

    croak 'BUG!';
}


sub natural_language {
    my ($self) = @_;
    ...
}


sub displayname {
    my ($self, @opts) = @_;
    return $self->as_string if scalar(@opts) == 0;
    { # work around the case we have no working $self->as().
        my %x = @opts;
        delete $x{default};
        delete $x{no_defaults};
        return $self->as_string if scalar(keys %x) == 0;
    }
    return $self->as('Data::Identifier')->displayname(@opts);
}


sub ise {
    ...
}


# ---- Private helpers ----

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Generic::Interface::Word - module to interact with the words of any language

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use parent 'Lingua::Generic::Interface::Word';

    my Lingua::Generic::Interface::Word $word = Lingua::XXX::Word->new(string => 'mi');

    say $word->as_string;

This module implements a generic interface to language specific implementations of a word object.

This module provides a base implementation for some of it's required methods.
Methods which this module cannot provide a useful default implementation for will have an implementation that dies on call.

This module inherits from
L<Data::Identifier::Interface::Simple>,
and L<Data::Identifier::Interface::Subobjects>.

Package may also want to implement L<Data::Identifier::Interface::Known>.

=head1 METHODS

=head2 new

    my Lingua::Generic::Interface::Word $word = Lingua::XXX::Word->new($type => $value);
    # e.g.:
    my Lingua::Generic::Interface::Word $word = Lingua::XXX::Word->new(string => 'mi');

(since v0.01)

Constructs a new word.
The word is normalised as part of this.
This method deduplicate instances.

Currently the following types (C<$type>) are defined:

=over

=item C<from>

(since v0.01)

Constructs a word from an object.
C<$value> should be a reference to an object from which the word is constructed.
Which exact objects a word can be constructed from depends on the implementation.

If C<$value> is not a reference the value is parsed as per C<string> if it looks like a word string (experimental since v0.01).

=item C<ise>

(since v0.01)

Constructs a word from a ISE (such as returned by L<Data::Identifier::Interface::Simple/ise>).

=item C<string>

(since v0.01)

Constructs a word from it's string representation.

=back

=head3 Default implementation

The default implementation will return C<$value> if C<from> is used and the passed object is already an instance of this package.
For C<string> it will create a new object that will work with the rest of the default implementation.
Such object will be a blessed hash reference with the string set in a key C<string>.

It will fail in all other cases.

=head2 as_string

    my $str = $word->as_string;

(since v0.01)

Returns the string representation of the word.

=head3 Default implementation

The default implementation will return the string value from the key C<string>.

=head2 eq

    my $bool = $word->eq($other); # $word must be non-undef
    # or:
    my $bool = Lingua::Generic::Interface::Word::eq($word, $other); # $word can be undef

(since v0.01)

Compares two words to be equal.

If both words are C<undef> they are considered equal.

If C<$word> or C<$other> is not an instance of L<Lingua::Generic::Interface::Word> or C<undef>
L</new> with the type C<from> is used.

The operators L<perlop/eq> and L<perlop/ne> are overloaded to this method.

=head3 Default implementation

The default implementation will force both sides to be a L<Lingua::Generic::Interface::Word>.
After that it will compare the actual packages, and then the string values as per L</as_string>.

=head2 cmp

    my $val = $word->cmp($other); # $word must be non-undef
    # or:
    my $val = Lingua::Generic::Interface::Word::cmp($word, $other); # $word can be undef

(experimental since v0.01)

Compares the words similar to C<cmp>. This method can be used to order words.
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

=head3 Default implementation

The default implementation will force both sides to be a L<Lingua::Generic::Interface::Word>.
After that it will compare the actual packages, and then the string values as per L</as_string>.

=head2 natural_language

    my Data::Identifier $natural_language = $word->natural_language;

(since v0.01)

Returns the natural language this word is in.
When no parameters are passed an instance of L<Data::Identifier> must be returned.

The implementation must die if any parameters are passed.

=head3 Default implementation

The default implementation dies.

=head2 displayname

    my $displayname = $word->displayname;

(since v0.01)

This method returns a string suitable to display to the user.

This is the same as L<Data::Identifier::Interface::Simple/displayname>.

=head3 Default implementation

The default implementation is compatible with L<Data::Identifier::Interface::Simple/displayname>.
It will make use of L</as_string> as good as possible, then fall back to calling L</as> asking for a L<Data::Identifier> to handle the request.

=head2 ise

    my $ise = $word->ise(...)

(since v0.01)

This is the same as L<Data::Identifier::Interface::Simple/ise>.

If an implementations implement this method or L<Data::Identifier::Interface::Simple/as> as their primary method to create L<Data::Identifier> objects
this method might be overridden by the default implementation from L<Data::Identifier::Interface::Simple> such as by:

    sub ise { goto &Data::Identifier::Interface::Simple::ise } # overridden using tail-call

=head3 Default implementation

The default implementation will die.

=head2 register

    $word->register;

(experimental since v0.01)

This should be implemented by packages that support registering words.
A registered word object is kept alive indefinitely and may be used for deduplication.
This is specifically useful when splitting texts into word objects, so common words do not get created over and over again.

This method returns the passed word (so it can be used in chain calls).
This method must also be suitable to be used with C<use constant>, see L<constant> for details.

It is undefined if this method will also register related objects (such as the word's stem, modifiers, or related L<Data::Identifier> objects).

=head3 Default implementation

Unimplemented. Future versions may provide a default implementation.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
