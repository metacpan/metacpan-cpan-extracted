package Fey::Meta::Role::Relationship::HasOne;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Fey::Exceptions qw( param_error );
use Fey::ORM::Types qw( Bool Item Maybe );

use Moose::Role;

with 'Fey::Meta::Role::Relationship';

has associated_attribute => (
    is       => 'rw',
    isa      => Maybe ['Moose::Meta::Attribute'],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_associated_attribute',
);

has associated_method => (
    is       => 'rw',
    isa      => Maybe ['Moose::Meta::Method'],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_associated_method',
);

has allows_undef => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_allows_undef',
);

has handles => (
    is => 'ro',

    # just gets passed on for attribute creation
    isa => Item,
);

sub _build_associated_attribute {
    my $self = shift;

    return unless $self->is_cached();

    # It'd be nice to set isa to the actual foreign class, but we may
    # not be able to map a table to a class yet, since that depends on
    # the related class being loaded. It doesn't really matter, since
    # this accessor is read-only, so there's really no typing issue to
    # deal with.
    my $type = 'Fey::Object::Table';
    $type = "Maybe[$type]" if $self->allows_undef();

    my %attr_p = (
        is        => 'rw',
        isa       => $type,
        lazy      => 1,
        default   => $self->_make_subref(),
        writer    => q{_set_} . $self->name(),
        predicate => q{_has_} . $self->name(),
        clearer   => q{_clear_} . $self->name(),
    );

    $attr_p{handles} = $self->handles()
        if $self->handles();

    return $self->associated_class()->attribute_metaclass()->new(
        $self->name(),
        %attr_p,
    );
}

sub _build_is_cached {1}

sub _build_associated_method {
    my $self = shift;

    return if $self->is_cached();

    return $self->associated_class()->method_metaclass()->wrap(
        name         => $self->name(),
        package_name => $self->associated_class()->name(),
        body         => $self->_make_subref(),
    );
}

sub attach_to_class {
    my $self  = shift;
    my $class = shift;

    $self->_set_associated_class($class);

    if ( $self->is_cached() ) {
        $class->add_attribute( $self->associated_attribute() );
    }
    else {
        $class->add_method( $self->name() => $self->associated_method() );
    }
}

sub detach_from_class {
    my $self = shift;

    return unless $self->associated_class();

    if ( $self->is_cached() ) {
        $self->associated_class->remove_attribute( $self->name() );
    }
    else {
        $self->associated_class->remove_method( $self->name() );
    }

    $self->_clear_associated_class();
}

1;

# ABSTRACT: A role for has-one metaclasses

__END__

=pod

=head1 NAME

Fey::Meta::Role::Relationship::HasOne - A role for has-one metaclasses

=head1 VERSION

version 0.47

=head1 DESCRIPTION

This role provides functionality for the two has-one metaclasses,
L<Fey::Meta::HasOne::ViaFK> and L<Fey::Meta::HasOne::ViaSelect>.

=head1 CONSTRUCTOR OPTIONS

This role adds the following constructor options:

=over 4

=item * handles

This will simply be passed on when an attribute for this has-one relationship
is created. Note that this is ignored if C<is_cached> is false.

=item * allows_undef

A boolean indicating whether or not the relationship's value can be
C<undef>.

=item * is_cached

Defaults to true for this class.

=back

=head1 METHODS

This role provides the following methods:

=head2 $ho->name()

Corresponds to the value passed to the constructor.

=head2 $ho->table()

Corresponds to the value passed to the constructor.

=head2 $ho->foreign_table()

Corresponds to the value passed to the constructor.

=head2 $ho->is_cached()

Corresponds to the value passed to the constructor, or the calculated
default.

=head2 $ho->allows_undef()

Corresponds to the value passed to the constructor.

=head2 $ho->handles()

Corresponds to the value passed to the constructor.

=head2 $ho->attach_to_class($class)

This method takes a F<Fey::Meta::Class::Table> object and attaches the
relationship to the associated class. If this relationship is cached,
it creates a new attribute, otherwise it creates a new method.

The method/attribute returns an object belonging to the class
associated with the foreign table. It can return C<undef> if
C<allows_undef> is true.

=head2 $ho->associated_class()

The class associated with this object. This is undefined until C<<
$ho->attach_to_class() >> is called.

=head2 $ho->associated_attribute()

Returns the attribute associated with this object, if any.

=head2 $ho->associated_method()

Returns the method associated with this object, if any.

=head2 $ho->detach_from_class()

If this object was attached to a class, it removes any attribute or
method it made, and unsets the C<associated_class>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
