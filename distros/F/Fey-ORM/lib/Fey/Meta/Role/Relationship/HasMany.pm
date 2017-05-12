package Fey::Meta::Role::Relationship::HasMany;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Fey::Exceptions qw( param_error );
use Fey::Object::Iterator::FromSelect;
use Fey::Object::Iterator::FromSelect::Caching;
use Fey::ORM::Types qw( ClassDoesIterator );

use Moose::Role;

with 'Fey::Meta::Role::Relationship';

has associated_method => (
    is       => 'rw',
    isa      => 'Moose::Meta::Method',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_associated_method',
);

has 'iterator_class' => (
    is      => 'ro',
    isa     => ClassDoesIterator,
    lazy    => 1,
    builder => '_build_iterator_class',
);

sub _build_iterator_class {
    my $self = shift;

    return $self->is_cached()
        ? 'Fey::Object::Iterator::FromSelect::Caching'
        : 'Fey::Object::Iterator::FromSelect';
}

sub _build_is_cached {0}

sub _build_associated_method {
    my $self = shift;

    my $method;
    if ( $self->is_cached() ) {
        my $iter_attr_name = q{___} . $self->name() . q{_iterator};

        $self->associated_class()->add_attribute(
            $iter_attr_name,
            is       => 'ro',
            isa      => $self->iterator_class(),
            lazy     => 1,
            default  => $self->_make_iterator_maker(),
            init_arg => undef,
        );

        $method = sub { return $_[0]->$iter_attr_name()->clone() };
    }
    else {
        $method = $self->_make_iterator_maker();
    }

    return $self->associated_class()->method_metaclass()->wrap(
        name         => $self->name(),
        package_name => $self->associated_class()->name(),
        body         => $method,
    );
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _make_subref_for_sql {
    my $self     = shift;
    my $select   = shift;
    my $bind_sub = shift;

    my $target_table = $self->foreign_table();

    my $iterator_class = $self->iterator_class();

    return sub {
        my $self = shift;

        my $class = $self->meta()->ClassForTable($target_table);

        my $dbh = $self->_dbh($select);

        return $iterator_class->new(
            classes     => $class,
            dbh         => $dbh,
            select      => $select,
            bind_params => [ $self->$bind_sub() ],
        );
    };

}
## use critic

sub attach_to_class {
    my $self  = shift;
    my $class = shift;

    $self->_set_associated_class($class);

    $class->add_method( $self->name() => $self->associated_method() );
}

sub detach_from_class {
    my $self = shift;

    return unless $self->associated_class();

    $self->associated_class->remove_method( $self->name() );

    $self->_clear_associated_class();
}

1;

# ABSTRACT: A role for has-many metaclasses

__END__

=pod

=head1 NAME

Fey::Meta::Role::Relationship::HasMany - A role for has-many metaclasses

=head1 VERSION

version 0.47

=head1 DESCRIPTION

This role provides shared functionality for the two has-many metaclasses,
L<Fey::Meta::HasMany::ViaFK> and L<Fey::Meta::HasMany::ViaSelect>.

=head1 CONSTRUCTOR OPTIONS

This role adds the following constructor options:

=over 4

=item * is_cached

Defaults to false for this class.

=item * iterator_class

This is the class used for iterators over the objects in this
relationship. By default, if this relationship is cached, it uses
L<Fey::Object::Iterator::FromSelect::Caching>, otherwise it uses
L<Fey::Object::Iterator::FromSelect>

=back

=head1 METHODS

This role provides the following methods:

=head2 $hm->name()

Corresponds to the value passed to the constructor.

=head2 $hm->table()

Corresponds to the value passed to the constructor.

=head2 $hm->foreign_table()

Corresponds to the value passed to the constructor.

=head2 $ho->is_cached()

Corresponds to the value passed to the constructor, or the calculated
default.

=head2 $hm->iterator_class()

Corresponds to the value passed to the constructor, or the calculated
default.

=head2 $hm->attach_to_class($class)

This method takes a F<Fey::Meta::Class::Table> object and attaches the
relationship to the associated class. Doing so will create a new
method in the associated class.

=head2 $hm->associated_class()

The class associated with this object. This is undefined until C<<
$hm->attach_to_class() >> is called.

=head2 $hm->associated_method()

Returns the method associated with this object, if any.

=head2 $hm->detach_from_class()

If this object was attached to a class, it removes the method it made,
and unsets the C<associated_class>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
