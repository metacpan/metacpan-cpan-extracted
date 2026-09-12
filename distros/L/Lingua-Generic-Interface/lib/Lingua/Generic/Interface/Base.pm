# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: base module used by language independent linguistic interfaces


package Lingua::Generic::Interface::Base;

use v5.20;
use strict;
use warnings;

use Carp;
use Scalar::Util;
use Data::Identifier v0.34;

our $VERSION = v0.03;

use parent qw(Data::Identifier::Interface::Subobjects Data::Identifier::Interface::Simple);

use overload (
    '""'    => sub {  $_[0]->as_string },
    'eq'    => sub {  $_[0]->eq($_[1]) },
    'ne'    => sub { !$_[0]->eq($_[1]) },
    'cmp'   => sub {  $_[0]->cmp($_[1]) },
);



sub as_string {
    my ($self, @opts) = @_;
    croak 'Stray options passed' if scalar @opts;
    return $self->{string} // confess 'BUG: No valid string';
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


sub eq {
    my ($self, $other, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return 1 if !defined($self) && !defined($other);
    return undef unless defined($self) && defined($other);

    croak 'Invalid input' unless defined Scalar::Util::blessed($self);
    croak 'Invalid input' unless defined Scalar::Util::blessed($other);

    return Scalar::Util::refaddr($self) == Scalar::Util::refaddr($other);
}

# ---- Private helpers ----

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Generic::Interface::Base - base module used by language independent linguistic interfaces

=head1 VERSION

version v0.03

=head1 SYNOPSIS

    use parent 'Lingua::Generic::Interface::Base';

(since v0.03)

This module implements te base package for language independent linguistic interfaces
such as L<Lingua::Generic::Interface::Word>.

This module provides a base implementation for some of it's methods.
Methods which this module cannot provide a useful default implementation for will have an implementation that dies on call.

This module inherits from
L<Data::Identifier::Interface::Simple>,
and L<Data::Identifier::Interface::Subobjects>.

Packages that inherit from this package may also want to implement L<Data::Identifier::Interface::Known>.

=head1 METHODS

=head2 as_string

    my $str = $word->as_string;

(since v0.03)

Returns the string representation of the word.

=head3 Default implementation

The default implementation will return the string value from the key C<string>.

=head2 displayname

    my $displayname = $base->displayname;

(since v0.03)

This method returns a string suitable to display to the user.

This is the same as L<Data::Identifier::Interface::Simple/displayname>.

=head3 Default implementation

The default implementation is compatible with L<Data::Identifier::Interface::Simple/displayname>.
It will make use of L</as_string> as good as possible, then fall back to calling L</as> asking for a L<Data::Identifier> to handle the request.

=head2 ise

    my $ise = $base->ise(...)

(since v0.03)

This is the same as L<Data::Identifier::Interface::Simple/ise>.

If an implementations implement this method or L<Data::Identifier::Interface::Simple/as> as their primary method to create L<Data::Identifier> objects
this method might be overridden by the default implementation from L<Data::Identifier::Interface::Simple> such as by:

    sub ise { goto &Data::Identifier::Interface::Simple::ise } # overridden using tail-call

=head3 Default implementation

The default implementation will die.

=head2 eq

    my $bool = $base->eq($other); # $base must be non-undef

(since v0.03)

Compares two objects to be equal.

If both objects are C<undef> they are considered equal.

The operators L<perlop/eq> and L<perlop/ne> are overloaded to this method.

=head3 Default implementation

The default implementation checks if both objects are identical.
It may also check other attributes.
All packages that inherit from this B<should> override this method to something matching their domain's definition of equal.

=head1 RESERVED METHODS

The following methods are reserved for future use and or use by any interface under L<Lingua::Generic::Interface>:

=over

=item attribute

=item as_number

=item as_string

=item classes_of

=item cmp

=item combine

=item concept

=item concepts

=item eq

=item flags

=item get

=item has_roles

=item has_type

=item language

=item markers

=item modifiers

=item natural_language

=item new

=item parts

=item prefix

=item property

=item register

=item role

=item roles

=item stem

=item suffix

=item tagname

=item type

=item words

=item _*_provider

=back

Also the methods from the following interfaces are reserved for their designated usages:
L<Data::Identifier::Interface::Known>.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
