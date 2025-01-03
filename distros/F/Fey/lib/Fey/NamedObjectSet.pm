package Fey::NamedObjectSet;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use List::AllUtils qw( all pairwise );
use Tie::IxHash;

use Fey::Types qw( HashRef Named );

use Moose 2.1200;

has '_set' => (
    is      => 'bare',
    isa     => 'Tie::IxHash',
    handles => {
        _get    => 'FETCH',
        _add    => 'STORE',
        _delete => 'Delete',
        _all    => 'Values',
        _keys   => 'Keys',
    },
    required => 1,
);

sub BUILDARGS {
    my $class = shift;

    return { _set => Tie::IxHash->new( map { $_->name() => $_ } @_ ) };
}

sub add {
    my $self = shift;

    $self->_add( map { $_->name() => $_ } @_ );

    return;
}

sub delete {
    my $self = shift;

    $self->_delete( map { $_->name() } @_ );

    return;
}

sub object {
    my $self = shift;

    return $self->_get(shift);
}

sub objects {
    my $self = shift;

    return $self->_all() unless @_;

    return grep {defined} map { $self->_get($_) } @_;
}

sub is_same_as {
    my $self  = shift;
    my $other = shift;

    my @self_names  = sort $self->_keys();
    my @other_names = sort $other->_keys();

    return 0 unless @self_names == @other_names;

    return all {$_} pairwise { $a eq $b } @self_names, @other_names;
}

__PACKAGE__->meta()->make_immutable();

1;

=head1 SYNOPSIS

  my $set = Fey::NamedObjectSet->new( $name_col, $size_col );

=head1 DESCRIPTION

This class represents a set of named objects, such as tables or
columns. You can look up objects in the set by name, or simply
retrieve all of the objects at once.

It exists to simplify Fey's internals, since named sets of objects are
quite common in SQL.

=head1 METHODS

This class provides the following methods:

=head2 Fey::NamedObjectSet->new(@objects)

This method returns a new C<Fey::NamedObjectSet> object. Any objects
passed to this method are added to the set as it is created. Each
object passed must implement a C<name()> method, which is expected to
return a unique name for that object.

=head2 $set->add(@objects)

Adds one or more named objects to the set.

=head2 $set->delete(@objects)

This method accepts one or more objects and removes them from the set,
if they are part of it.

=head2 $set->object($name)

Given a name, this method returns the corresponding object.

=head2 $set->objects(@names)

When given a list of names as an argument, this method returns the
named objects in the order specified, if they exist in the set. If not
given any arguments it returns all of the objects in the set.

=head2 $set->is_same_as($other_set)

Given a C<Fey::NamedObjectSet>, this method indicates whether or not
the two sets are the same.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=cut
