use v5.10;
use strict;
use warnings;

package Meerkat::Role::Document;
# ABSTRACT: Enhances a Moose object with Meerkat methods and metadata

our $VERSION = '0.016';

use Moose::Role 2;
use MooseX::AttributeShortcuts;
use MooseX::Storage;
use MooseX::Storage::Engine;

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use Syntax::Keyword::Junction qw/any none/;
use BSON::OID;
use Type::Params qw/compile/;
use Types::Standard qw/slurpy :types/;
use Scalar::Util qw/looks_like_number/; # XXX crude but fast

use namespace::autoclean;

with Storage;

# pass through OID's without modification as MongoDB will
# consume/provide them; pass through Meerkat::Collection
# as Meerkat will strip/add as necessary
for my $type (qw/BSON::OID Meerkat::Collection DateTime DateTime::Tiny/) {
    MooseX::Storage::Engine->add_custom_type_handler(
        $type => (
            expand   => sub { shift },
            collapse => sub { shift },
        )
    );
}

#pod =method new
#pod
#pod B<Don't call this directly!>  Create objects through the
#pod L<Meerkat::Collection> or they won't be added to the database.
#pod
#pod     my $obj = $person->create( name => "Joe" );
#pod
#pod =cut

has _collection => (
    is       => 'ro',
    isa      => 'Meerkat::Collection',
    required => 1,
);

has _id => (
    is      => 'ro',
    isa     => 'BSON::OID',
    default => sub { BSON::OID->new },
);

has _removed => (
    is      => 'rw',
    isa     => 'Bool',
    reader  => 'is_removed',
    writer  => '_set_removed',
    default => 0,
);

#pod =method update
#pod
#pod     $obj->update( { '$set' => { 'name' => "Moe" } } );
#pod
#pod Executes a MongoDB update command on the associated document and updates the
#pod object's attributes.  You must only use MongoDB L<update
#pod operators|http://docs.mongodb.org/manual/reference/operator/nav-update/> to
#pod modify the document's fields.
#pod
#pod Returns true if the updates are applied and synchronized.  If the document has
#pod been removed, the method returns false and the object is marked as removed;
#pod subsequent C<update>, C<sync> or C<remove> calls will do nothing and return
#pod false.
#pod
#pod This command is intended for custom updates with unusual logic or operators.
#pod Many typical updates can be accomplished with the C<update_*> methods described
#pod below.
#pod
#pod For all update methods, you can use a MongoDB nested field label to modify
#pod values deep into a data structure. For example C<parents.father> refers to
#pod C<< $obj->parents->{father} >>.
#pod
#pod =cut

sub update {
    state $check = compile( Object, HashRef );
    my ( $self, $update ) = $check->(@_);
    croak "The update method only accepts MongoDB update operators"
      if grep { /^[^\$]/ } keys %$update;
    return if $self->is_removed; # NOP
    return $self->_collection->update( $self, $update );
}

#pod =method update_set
#pod
#pod     $obj->update_set( name => "Luke Skywalker" );
#pod
#pod Sets a field to a value.  This is the MongoDB C<$set> operator.
#pod
#pod The field must be undefined or else the existing value and the new value must
#pod be of similar types (e.g. scalar or array or hash).  For the purpose of this
#pod check, an object (e.g. a DateTime) is treated (opaquely) as a scalar value.  If
#pod the types do not match, an error will be thrown.
#pod
#pod Note this means that you can't set a defined value to undefined.  To remove a
#pod field entirely, see L</update_clear>.  If you need to make other structural
#pod changes, do it manually with the L</update> method.
#pod
#pod Returns true if the update is applied and synchronized.  If the document has
#pod been removed, the method returns false and the object is marked as removed.
#pod
#pod =cut

sub update_set {
    state $check = compile( Object, Defined, Defined );
    my ( $self, $field, $value ) = $check->(@_);
    $self->__check_op( $field, any(qw/undef scalar object ARRAY HASH/) );
    my $type        = $self->__field_type( $self->_deep_field($field) );
    my $target_type = $self->__field_type($value);
    croak "Can't use update_set to change $type field '$field' to $target_type"
      if $type eq none(qw/undef object/) && $type ne $target_type;

    return $self->update( { '$set' => { "$field" => $value } } );
}

#pod =method update_inc
#pod
#pod     $obj->update_inc( likes => 1 );
#pod     $obj->update_inc( likes => -1 );
#pod
#pod Increments a field by a positive or negative value.  This is the MongoDB
#pod C<$inc> operator.  The field must be undefined or a numeric scalar value
#pod or an error will be thrown.
#pod
#pod Returns true if the update is applied and synchronized.  If the document has
#pod been removed, the method returns false and the object is marked as removed.
#pod
#pod =cut

sub update_inc {
    state $check = compile( Object, Defined, Defined );
    my ( $self, $field, $value ) = $check->(@_);
    $self->__check_op( $field, any(qw/undef scalar/) );
    my $current = $self->$field;
    croak "Can't use update_inc on non-numeric field '$field'"
      if defined $current && !looks_like_number($current);
    return $self->update( { '$inc' => { "$field" => $value } } );
}

#pod =method update_push
#pod
#pod     $obj->update_push( tags => qw/cool hot trendy/ );
#pod
#pod Pushes values onto an array reference field. This is the MongoDB C<$push>
#pod operator.  The field must be undefined or an array reference or an error
#pod is thrown.
#pod
#pod Returns true if the update is applied and synchronized.  If the document has
#pod been removed, the method returns false and the object is marked as removed.
#pod
#pod
#pod =cut

sub update_push {
    state $check = compile( Object, Defined, slurpy ArrayRef );
    my ( $self, $field, $list ) = $check->(@_);
    $self->__check_op( $field, any(qw/undef ARRAY/) );
    return $self->update( { '$push' => { "$field" => { '$each' => $list } } } );
}

#pod =method update_add
#pod
#pod     $obj->update_add( tags => qw/cool hot trendy/ );
#pod
#pod Pushes values onto an array reference field, but only if they do not already
#pod exist in the array.  This is the MongoDB C<$addToSet> operator.  The field
#pod must be undefined or an array reference or an error is thrown.
#pod
#pod Returns true if the update is applied and synchronized.  If the document has
#pod been removed, the method returns false and the object is marked as removed.
#pod
#pod =cut

sub update_add {
    state $check = compile( Object, Defined, slurpy ArrayRef );
    my ( $self, $field, $list ) = $check->(@_);
    $self->__check_op( $field, any(qw/undef ARRAY/) );
    return $self->update( { '$addToSet' => { "$field" => { '$each' => $list } } } );
}

#pod =method update_pop
#pod
#pod     $obj->update_pop( 'tags' );
#pod
#pod Removes a value from the end of the array.  This is the MongoDB C<$pop>
#pod operator with a direction of "1".    The field must be undefined or an array
#pod reference or an error is thrown.
#pod
#pod Returns true if the update is applied and synchronized.  If the document has
#pod been removed, the method returns false and the object is marked as removed.
#pod
#pod =cut

sub update_pop {
    state $check = compile( Object, Defined );
    my ( $self, $field ) = $check->(@_);
    $self->__check_op( $field, any(qw/undef ARRAY/) );
    return $self->update( { '$pop' => { "$field" => 1 } } );
}

#pod =method update_shift
#pod
#pod     $obj->update_shift( 'tags' );
#pod
#pod Removes a value from the front of the array.  This is the MongoDB C<$pop>
#pod operator with a direction of "-1".   The field must be undefined or an array
#pod reference or an error is thrown.
#pod
#pod Returns true if the update is applied and synchronized.  If the document has
#pod been removed, the method returns false and the object is marked as removed.
#pod
#pod
#pod =cut

sub update_shift {
    state $check = compile( Object, Defined );
    my ( $self, $field ) = $check->(@_);
    $self->__check_op( $field, any(qw/undef ARRAY/) );
    return $self->update( { '$pop' => { "$field" => -1 } } );
}

#pod =method update_remove
#pod
#pod     $obj->update_remove( tags => qw/cool hot/ );
#pod
#pod Removes a list of values from the array.  This is the MongoDB C<$pullAll>
#pod operator.   The field must be undefined or an array reference or an error is
#pod thrown.
#pod
#pod Returns true if the update is applied and synchronized.  If the document has
#pod been removed, the method returns false and the object is marked as removed.
#pod
#pod
#pod =cut

sub update_remove {
    state $check = compile( Object, Defined, slurpy ArrayRef );
    my ( $self, $field, $list ) = $check->(@_);
    $self->__check_op( $field, any(qw/undef ARRAY/) );
    return $self->update( { '$pullAll' => { "$field" => $list } } );
}

#pod =method update_clear
#pod
#pod     $obj->update_clear( 'tags' );
#pod
#pod Removes a field from a document.  This is the MongoDB C<$unset> operator.
#pod Returns true if the update is applied and synchronized.  If the document has
#pod been removed, the method returns false and the object is marked as removed.
#pod
#pod Be sure not to clear any required fields.
#pod
#pod =cut

sub update_clear {
    state $check = compile( Object, Defined );
    my ( $self, $field ) = $check->(@_);
    $self->__check_op( $field, any(qw/undef scalar object ARRAY HASH/) );
    return $self->update( { '$unset' => { "$field" => undef } } );
}

#pod =method sync
#pod
#pod     $obj->sync;
#pod
#pod Updates object attributes from the database.  Returns true if synced.  If the
#pod document has been removed, the method returns false and the object is marked as
#pod removed; subsequent C<update>, C<sync> or C<remove> calls will do nothing and
#pod return false.
#pod
#pod =cut

sub sync {
    state $check = compile(Object);
    my ($self) = $check->(@_);
    return $self->_collection->sync($self);
}

#pod =method remove
#pod
#pod     $obj->remove;
#pod
#pod Removes the associated document from the database.  The object is marked as
#pod removed; subsequent C<update>, C<sync> or C<remove> calls will do nothing and
#pod return false.
#pod
#pod =method is_removed
#pod
#pod     if ( $obj->is_removed ) { ... }
#pod
#pod Returns true or false indicating whether the associated document was removed
#pod from the database.
#pod
#pod =cut

sub remove {
    state $check = compile(Object);
    my ($self) = $check->(@_);
    return 1 if $self->is_removed; # NOP
    return $self->_collection->remove($self);
}

#pod =method reinsert
#pod
#pod     $obj->reinsert;
#pod     $obj->reinsert( force => 1 );
#pod
#pod Reinserts a removed document.  If the C<force> option is true, then it will be
#pod reinserted even if the document has not been removed, overwriting any existing
#pod document in the database.  Returns false if the document is not removed (unless
#pod the force option is true).  Returns true if the document has been reinserted.
#pod
#pod =cut

sub reinsert {
    state $check = compile( Object, slurpy Dict [ force => Optional [Bool] ] );
    my ( $self, $options ) = $check->(@_);
    return if !$self->is_removed and !$options->{force}; # NOP
    return $self->_collection->reinsert($self);
}

#--------------------------------------------------------------------------#
# semi private methods
#--------------------------------------------------------------------------#

#pod =method _indexes
#pod
#pod     $class->_indexes;
#pod
#pod Returns an empty list.  If you want to define indexes for use with the
#pod L<ensure_indexes|Meerkat::Collection/ensure_indexes> method of
#pod L<Meerkat::Collection>, create your own C<_indexes> method that returns a list
#pod of array references.  The array references can have an optional initial hash
#pod reference of indexing options, followed by ordered key & value pairs in the
#pod usual MongoDB way.
#pod
#pod You must provide index fields in an array reference because Perl hashes are not
#pod ordered and a compound index requires an order.
#pod
#pod For example:
#pod
#pod     sub _indexes {
#pod         return (
#pod             [ { unique => 1 }, name => 1 ],
#pod             [ name => 1, zip_code => 1 ]
#pod             [ likes => -1 ],
#pod             [ location => '2dsphere' ],
#pod         );
#pod     }
#pod
#pod See the L<Meerkat::Cookbook> for more information.
#pod
#pod =cut

sub _indexes { return }

#pod =method _deep_field
#pod
#pod     my $value = $obj->_deep_field( "parents.father" ); # hash key
#pod     my $value = $obj->_deep_field( "tags.0" );         # array index
#pod
#pod Retrieves a field deep in the object's data structure using MongoDB's dot
#pod notation.  Returns undef if the field does not exist.  Throws an error if the
#pod dot notation would do an illegal dereference.
#pod
#pod This is far less efficient than accessing an attribute and dereferencing
#pod directly.  It is used internally for validation of update_* field arguments.
#pod
#pod =cut

sub _deep_field {
    my ( $self, $field ) = @_;
    my ( $head, @tail ) = split /\./, $field;
    my $target = eval { $self->$head };
    croak "Invalid attribute '$head'" if $@;
    return unless defined $target;
    while ( defined( my $p = shift @tail ) ) {
        my $ref = ref $target;
        if ( $ref eq 'ARRAY' ) {
            croak
              "Invalid subdocument '$head.$p': '$head' is an array but $p is not positive integer"
              unless $p =~ /^\d+$/;
            return if $p > $#{$target}; # doesn't exist yet
            $target = $target->[$p];
        }
        elsif ( $ref eq 'HASH' ) {
            return unless exists $target->{$p};
            $target = $target->{$p};
        }
        else {
            croak "Invalid subdocument '$head.$p': '$head' is not a reference";
        }
        $head .= ".$p";
    }
    return $target;
}

#--------------------------------------------------------------------------#
# really private methods
#--------------------------------------------------------------------------#

sub __check_op {
    my ( $self, $field, $allowed ) = @_; # $allowed could be a junction
    my $type = $self->__field_type( $self->_deep_field($field) );
    unless ( $type eq $allowed ) {
        my ( undef, undef, undef, $sub ) = caller(1);
        $sub =~ s/.*::(\w+)$/$1/;
        croak "Can't use $sub on $type field '$field'";
    }
}

sub __field_type {
    my ( $self, $value ) = @_;
    return 'undef' unless defined $value;
    return 'object' if blessed($value);
    return ref($value) || 'scalar';
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Meerkat::Role::Document - Enhances a Moose object with Meerkat methods and metadata

=head1 VERSION

version 0.016

=head1 SYNOPSIS

Your model class:

    package My::Model::Person;

    use Moose;

    with 'Meerkat::Role::Document';

    has name => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    has likes => (
        is      => 'ro',
        isa     => 'Num',
        default => 0,
    );

    has tags => (
        is      => 'ro',
        isa     => 'ArrayRef',
        default => sub { [] },
    );

    1;

In your code:

    use Meerkat;

    my $meerkat = Meerkat->new(
        model_namespace => "My::Model",
        database_name => "test"
    );

    my $person = $meerkat->collection("Person"); # My::Model::Person

    # create a document
    my $obj = $person->create( name => "Larry" );

    # change document in the database and update object
    $obj->update_set( name => "Moe" );
    $obj->update_inc( likes => 1 );
    $obj->update_push( tags => qw/cool hot trendy/ );

    # get any other updates from the database
    $obj->sync;

    # delete it
    $obj->remove;

=head1 DESCRIPTION

This role enhances a Moose class with attributes and methods needed to operate
in tandem with a L<Meerkat::Collection>.

The resulting object is a projection of the document state in the database.
Update methods change the state atomically in the database and synchronize the
object with the new state in the database (potentially including other changes
from other sources).

=head2 Consuming the role

When you apply this role to your Moose class, it provides and manages the
C<_id> attribute for you.  This attribute is meant to be public, but keeps
the leading underscore for consistency with L<MongoDB> classes.

The attributes you define should be read-only.  Modifying attributes directly
in the object will not be reflected in the database and will be lost the next
time you synchronize.

Objects are serialized with L<MooseX::Storage>.  Any attributes that should
not be serialized must have the C<DoNotSerialize> trait:

    has 'expensive' => (
        traits => [ 'DoNotSerialize' ],
        is     => 'lazy',
        isa    => 'HeavyObject',
    );

Attributes with embedded objects are not well supported.  See the
L<Meerkat::Cookbook> for more.

=head2 Working with objects

Create objects from an associated Meerkat::Collection, not with C<new>.

    my $obj = $person->create( %attributes );

That will construct the object, instantiate all lazy attributes (except those
marked C<DoNoSerialize>) and store the new document into the database.

Then, use the various update methods to modify state if you need to.  Use
C<sync> to refresh the object with any remote changes from the database.

=head1 METHODS

=head2 new

B<Don't call this directly!>  Create objects through the
L<Meerkat::Collection> or they won't be added to the database.

    my $obj = $person->create( name => "Joe" );

=head2 update

    $obj->update( { '$set' => { 'name' => "Moe" } } );

Executes a MongoDB update command on the associated document and updates the
object's attributes.  You must only use MongoDB L<update
operators|http://docs.mongodb.org/manual/reference/operator/nav-update/> to
modify the document's fields.

Returns true if the updates are applied and synchronized.  If the document has
been removed, the method returns false and the object is marked as removed;
subsequent C<update>, C<sync> or C<remove> calls will do nothing and return
false.

This command is intended for custom updates with unusual logic or operators.
Many typical updates can be accomplished with the C<update_*> methods described
below.

For all update methods, you can use a MongoDB nested field label to modify
values deep into a data structure. For example C<parents.father> refers to
C<< $obj->parents->{father} >>.

=head2 update_set

    $obj->update_set( name => "Luke Skywalker" );

Sets a field to a value.  This is the MongoDB C<$set> operator.

The field must be undefined or else the existing value and the new value must
be of similar types (e.g. scalar or array or hash).  For the purpose of this
check, an object (e.g. a DateTime) is treated (opaquely) as a scalar value.  If
the types do not match, an error will be thrown.

Note this means that you can't set a defined value to undefined.  To remove a
field entirely, see L</update_clear>.  If you need to make other structural
changes, do it manually with the L</update> method.

Returns true if the update is applied and synchronized.  If the document has
been removed, the method returns false and the object is marked as removed.

=head2 update_inc

    $obj->update_inc( likes => 1 );
    $obj->update_inc( likes => -1 );

Increments a field by a positive or negative value.  This is the MongoDB
C<$inc> operator.  The field must be undefined or a numeric scalar value
or an error will be thrown.

Returns true if the update is applied and synchronized.  If the document has
been removed, the method returns false and the object is marked as removed.

=head2 update_push

    $obj->update_push( tags => qw/cool hot trendy/ );

Pushes values onto an array reference field. This is the MongoDB C<$push>
operator.  The field must be undefined or an array reference or an error
is thrown.

Returns true if the update is applied and synchronized.  If the document has
been removed, the method returns false and the object is marked as removed.

=head2 update_add

    $obj->update_add( tags => qw/cool hot trendy/ );

Pushes values onto an array reference field, but only if they do not already
exist in the array.  This is the MongoDB C<$addToSet> operator.  The field
must be undefined or an array reference or an error is thrown.

Returns true if the update is applied and synchronized.  If the document has
been removed, the method returns false and the object is marked as removed.

=head2 update_pop

    $obj->update_pop( 'tags' );

Removes a value from the end of the array.  This is the MongoDB C<$pop>
operator with a direction of "1".    The field must be undefined or an array
reference or an error is thrown.

Returns true if the update is applied and synchronized.  If the document has
been removed, the method returns false and the object is marked as removed.

=head2 update_shift

    $obj->update_shift( 'tags' );

Removes a value from the front of the array.  This is the MongoDB C<$pop>
operator with a direction of "-1".   The field must be undefined or an array
reference or an error is thrown.

Returns true if the update is applied and synchronized.  If the document has
been removed, the method returns false and the object is marked as removed.

=head2 update_remove

    $obj->update_remove( tags => qw/cool hot/ );

Removes a list of values from the array.  This is the MongoDB C<$pullAll>
operator.   The field must be undefined or an array reference or an error is
thrown.

Returns true if the update is applied and synchronized.  If the document has
been removed, the method returns false and the object is marked as removed.

=head2 update_clear

    $obj->update_clear( 'tags' );

Removes a field from a document.  This is the MongoDB C<$unset> operator.
Returns true if the update is applied and synchronized.  If the document has
been removed, the method returns false and the object is marked as removed.

Be sure not to clear any required fields.

=head2 sync

    $obj->sync;

Updates object attributes from the database.  Returns true if synced.  If the
document has been removed, the method returns false and the object is marked as
removed; subsequent C<update>, C<sync> or C<remove> calls will do nothing and
return false.

=head2 remove

    $obj->remove;

Removes the associated document from the database.  The object is marked as
removed; subsequent C<update>, C<sync> or C<remove> calls will do nothing and
return false.

=head2 is_removed

    if ( $obj->is_removed ) { ... }

Returns true or false indicating whether the associated document was removed
from the database.

=head2 reinsert

    $obj->reinsert;
    $obj->reinsert( force => 1 );

Reinserts a removed document.  If the C<force> option is true, then it will be
reinserted even if the document has not been removed, overwriting any existing
document in the database.  Returns false if the document is not removed (unless
the force option is true).  Returns true if the document has been reinserted.

=head2 _indexes

    $class->_indexes;

Returns an empty list.  If you want to define indexes for use with the
L<ensure_indexes|Meerkat::Collection/ensure_indexes> method of
L<Meerkat::Collection>, create your own C<_indexes> method that returns a list
of array references.  The array references can have an optional initial hash
reference of indexing options, followed by ordered key & value pairs in the
usual MongoDB way.

You must provide index fields in an array reference because Perl hashes are not
ordered and a compound index requires an order.

For example:

    sub _indexes {
        return (
            [ { unique => 1 }, name => 1 ],
            [ name => 1, zip_code => 1 ]
            [ likes => -1 ],
            [ location => '2dsphere' ],
        );
    }

See the L<Meerkat::Cookbook> for more information.

=head2 _deep_field

    my $value = $obj->_deep_field( "parents.father" ); # hash key
    my $value = $obj->_deep_field( "tags.0" );         # array index

Retrieves a field deep in the object's data structure using MongoDB's dot
notation.  Returns undef if the field does not exist.  Throws an error if the
dot notation would do an illegal dereference.

This is far less efficient than accessing an attribute and dereferencing
directly.  It is used internally for validation of update_* field arguments.

=for Pod::Coverage BUILD

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
