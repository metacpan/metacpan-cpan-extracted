use v5.10;
use strict;
use warnings;

package Meerkat::Collection;
# ABSTRACT: Associate a class, database and MongoDB collection

our $VERSION = '0.016';

use Moose 2;
use MooseX::AttributeShortcuts;

use Carp qw/croak/;
use Meerkat::Cursor;
use Module::Runtime qw/require_module/;
use Tie::IxHash;
use Try::Tiny::Retry 0.002 qw/:all/;
use Type::Params qw/compile/;
use Types::Standard qw/slurpy :types/;

use namespace::autoclean;

our @CARP_NOT = qw/Meerkat::Role::Document Try::Tiny/;

#--------------------------------------------------------------------------#
# Public attributes
#--------------------------------------------------------------------------#

#pod =attr meerkat (required)
#pod
#pod The Meerkat object that constructed the object.  It holds the MongoDB
#pod collections used to access the database.
#pod
#pod =cut

has meerkat => (
    is       => 'ro',
    isa      => 'Meerkat',
    required => 1,
);

#pod =attr class (required)
#pod
#pod The class name to associate with documents.  The class is loaded
#pod for you if needed.
#pod
#pod =cut

has class => (
    is       => 'ro',
    isa      => 'Str', # XXX should check that the class does the role
    required => 1,
);

#pod =attr collection_name
#pod
#pod The collection name to associate with the class.  Defaults to the
#pod name of the class with "::" replaced with "_".
#pod
#pod =cut

has collection_name => (
    is  => 'lazy',
    isa => 'Str',
);

sub _build_collection_name {
    my ($self) = @_;
    ( my $name = $self->class ) =~ s{::}{_}g;
    return $name;
}

has _class_loaded => (
    is  => 'rw',
    isa => 'Bool',
);

#--------------------------------------------------------------------------#
# Constructor
#--------------------------------------------------------------------------#

sub BUILD {
    my ($self) = @_;
    return if $self->_class_loaded;
    require_module( $self->class ) and $self->_class_loaded(1);
}

#--------------------------------------------------------------------------#
# Public methods on collection as a whole
#--------------------------------------------------------------------------#

#pod =method create
#pod
#pod     my $obj = $person->create( name => 'John' );
#pod
#pod Creates an object of the class associated with the Meerkat::Collection and
#pod inserts it into the associated collection in the database.  Returns the object on
#pod success or throws an error on failure.
#pod
#pod Any arguments given are passed directly to the associated class constructor.
#pod Arguments may be given either as a list or as a hash reference.
#pod
#pod =cut

sub create {
    state $check = compile( Object, slurpy ArrayRef );
    my ( $self, $args ) = $check->(@_);
    my @args = ( ref $args->[0] eq 'HASH' ? %{ $args->[0] } : @$args );
    my $obj = $self->class->new( @args, _collection => $self );
    $self->_save($obj);
    return $obj;
}

#pod =method count
#pod
#pod     my $count = $person->count;
#pod     my $count = $person->count( $query );
#pod
#pod Returns the number of documents in the associated collection or throws an error on
#pod failure.  If a hash reference is provided, it is passed as a query parameter to
#pod the MongoDB L<count_documents|MongoDB::Collection/count_documents> method.
#pod Otherwise, the MongoDB
#pod L<estimated_document_count|MongoDB::Collection/estimated_document_count> method
#pod is used instead.
#pod
#pod =cut

sub count {
    state $check = compile( Object, Optional [HashRef] );
    my ( $self, $query ) = $check->(@_);
    if ( defined $query ) {
        return $self->_try_mongo_op(
            count => sub { $self->_mongo_collection->count_documents($query) } );
    }
    return $self->_try_mongo_op(
        count => sub { $self->_mongo_collection->estimated_document_count() } );
}

#pod =method find_id
#pod
#pod     my $obj = $person->find_id( $id );
#pod
#pod Finds a document with the given C<_id> and returns it as an object of the
#pod associated class.  Returns undef if the C<_id> is not found or throws an error
#pod if one occurs.  This is a shorthand for the same query via C<find_one>:
#pod
#pod     $person->find_one( { _id => $id } );
#pod
#pod However, C<find_id> can take either a scalar C<_id> or a L<BSON::OID> object
#pod as an argument.
#pod
#pod =cut

sub find_id {
    state $check = compile( Object, Defined );
    my ( $self, $id ) = $check->(@_);
    my $data =
      $self->_try_mongo_op(
        find_id => sub { $self->_mongo_collection->find_one( { _id => $id } ) } );
    return unless $data;
    return $self->thaw_object($data);
}

#pod =method find_one
#pod
#pod     my $obj = $person->find_one( { name => "Larry Wall" } );
#pod
#pod Finds the first document matching a query parameter hash reference and returns
#pod it as an object of the associated class.  Returns undef if the C<_id> is not
#pod found or throws an error if one occurs.
#pod
#pod =cut

sub find_one {
    state $check = compile( Object, HashRef );
    my ( $self, $query ) = $check->(@_);
    return
      unless my $data =
      $self->_try_mongo_op(
        find_one => sub { $self->_mongo_collection->find_one($query) } );
    return $self->thaw_object($data);
}

#pod =method find
#pod
#pod     my $cursor = $person->find( { tag => "trendy" } );
#pod     my @objs   = $cursor->all;
#pod
#pod Executes a query against C<collection_name>.  It returns a L<Meerkat::Cursor>
#pod or throws an error on failure.  If a hash reference is provided, it is passed
#pod as a query parameter to the MongoDB L<find|MongoDB::Collection/find> method,
#pod otherwise all documents are returned.  You may include and optional options
#pod hash reference after the query hash reference.  Iterating the cursor will return
#pod objects of the associated class.
#pod
#pod =cut

sub find {
    state $check = compile( Object, Optional [HashRef], Optional [HashRef] );
    my ( $self, $query, $options ) = $check->(@_);
    my $cursor =
      $self->_try_mongo_op(
        find => sub { $self->_mongo_collection->find( $query, $options ) } );
    return Meerkat::Cursor->new( cursor => $cursor, collection => $self );
}

#pod =method ensure_indexes
#pod
#pod     $person->ensure_indexes;
#pod
#pod Ensures an index is constructed for index returned by the C<_index> method
#pod of the associated class.  Returns true on success or throws an error if one
#pod occurs. See L<Meerkat::Role::Document> for more.
#pod
#pod =cut

sub ensure_indexes {
    state $check = compile(Object);
    my ($self) = $check->(@_);
    state $aoa_check = compile( slurpy ArrayRef [ArrayRef] );
    my ($aoa) = $aoa_check->( $self->class->_indexes );
    my $index_view = $self->_mongo_collection->indexes;
    my @indexes;
    for my $index (@$aoa) {
        my @copy = @$index;
        my $options = ref $copy[0] eq 'HASH' ? shift @copy : undef;
        if ( @copy % 2 != 0 ) {
            $self->_croak(
                "_indexes must provide a list of key/value pairs, with an optional leading hashref");
        }
        my $spec = Tie::IxHash->new(@copy);
        push @indexes, { keys => $spec, ( $options ? ( options => $options ) : () ) };
    }
    $self->_try_mongo_op( ensure_indexes => sub { $index_view->create_many(@indexes) } );
    return 1;
}

#--------------------------------------------------------------------------#
# Semi-private methods on individual objects; typically called by object to
# modify itself and synchronize with the database
#--------------------------------------------------------------------------#

sub remove {
    state $check = compile( Object, Object );
    my ( $self, $obj ) = $check->(@_);
    $self->_try_mongo_op(
        remove => sub { $self->_mongo_collection->delete_one( { _id => $obj->_id } ) } );
    $obj->_set_removed(1);
    return 1;
}

sub reinsert {
    state $check = compile( Object, Object );
    my ( $self, $obj ) = $check->(@_);
    $self->_save($obj);
    $obj->_set_removed(0);
    return 1;
}

sub sync {
    state $check = compile( Object, Object );
    my ( $self, $obj ) = $check->(@_);
    my $data = $self->_try_mongo_op(
        sync => sub { $self->_mongo_collection->find_one( { _id => $obj->_id } ) } );
    if ($data) {
        $self->_sync( $data => $obj );
        $obj->_set_removed(0);
        return 1;
    }
    else {
        $obj->_set_removed(1);
        return; # false means removed
    }
}

sub update {
    state $check = compile( Object, Object, HashRef );
    my ( $self, $obj, $update ) = $check->(@_);
    my $data = $self->_try_mongo_op(
        update => sub {
            $self->_mongo_collection->find_one_and_update( { _id => $obj->_id },
                $update, { returnDocument => "after" } );
        },
    );

    if ( ref $data ) {
        $self->_sync( $data => $obj );
        return 1;
    }
    else {
        $obj->_set_removed(1);
        return; # false means removed
    }
}

sub thaw_object {
    state $check = compile( Object, HashRef );
    my ( $self, $data ) = $check->(@_);
    $data->{__CLASS__}   = $self->class;
    $data->{_collection} = $self;
    return $self->class->unpack($data);
}

#--------------------------------------------------------------------------#
# Private methods
#--------------------------------------------------------------------------#

sub _mongo_collection {
    state $check = compile(Object);
    my ($self) = $check->(@_);
    return $self->meerkat->mongo_collection( $self->collection_name );
}

sub _try_mongo_op {
    state $check = compile( Object, Str, CodeRef );
    my ( $self, $action, $code, $rest ) = $check->(@_);
    # call &retry to bypass prototype
    return &retry(
        $code, @$rest,
        retry_if { /not connected/ },
        delay_exp { 5, 1e6 },
        on_retry { $self->mongo_clear_caches },
        catch { croak "$action error: $_" }
    );
}

sub _save {
    state $check = compile( Object, Object );
    my ( $self, $obj ) = $check->(@_);
    my $pack = $obj->pack;
    delete $pack->{$_} for qw/__CLASS__ _collection _removed/;
    return $self->_try_mongo_op(
        sync => sub {
            !!$self->_mongo_collection->replace_one( { _id => $pack->{_id} },
                $pack, { upsert => 1 } );
        }
    );
}

sub _sync {
    state $check = compile( Object, HashRef, Object );
    my ( $self, $data, $tgt ) = $check->(@_);
    my $src = try {
        $self->thaw_object($data);
    }
    catch {
        $self->_croak(
            "Could not inflate updated document with _id=$data->{_id} because: $_");
    };
    for my $tgt_attr ( $tgt->meta->get_all_attributes ) {
        my $src_attr = $src->meta->find_attribute_by_name( $tgt_attr->name );
        $tgt_attr->set_value( $tgt, $src_attr->get_value($src) );
    }
    return 1;
}

sub _croak {
    my ( $self, $msg ) = @_;
    $msg =~ s/ at \S+ line \d+.*//ms;
    croak $msg;
}

__PACKAGE__->meta->make_immutable;

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Meerkat::Collection - Associate a class, database and MongoDB collection

=head1 VERSION

version 0.016

=head1 SYNOPSIS

    use Meerkat;

    my $meerkat = Meerkat->new(
        model_namespace => "My::Model",
        database_name   => "test"
    );

    my $person = $meerkat->collection("Person"); # My::Model::Person

    # create an object and insert it into the MongoDB collection
    my $obj = $person->create( name => 'John' );

    # find a single object
    my $copy = $person->find_one( { name => 'John' } );

    # get a Meerkat::Cursor for multiple objects
    my $cursor = $person->find( { tag => 'hot' } );

=head1 DESCRIPTION

A Meerkat::Collection holds an association between your model class and a
collection in the database.  This class does all the real work of creating,
searching, updating, or deleting from the underlying MongoDB collection.

If you use the Meerkat::Collection object to run a query that could have
multiple results, it returns a Meerkat::Cursor object that wraps the
MongoDB::Cursor and inflates results into objects from your model.

=head1 ATTRIBUTES

=head2 meerkat (required)

The Meerkat object that constructed the object.  It holds the MongoDB
collections used to access the database.

=head2 class (required)

The class name to associate with documents.  The class is loaded
for you if needed.

=head2 collection_name

The collection name to associate with the class.  Defaults to the
name of the class with "::" replaced with "_".

=head1 METHODS

=head2 create

    my $obj = $person->create( name => 'John' );

Creates an object of the class associated with the Meerkat::Collection and
inserts it into the associated collection in the database.  Returns the object on
success or throws an error on failure.

Any arguments given are passed directly to the associated class constructor.
Arguments may be given either as a list or as a hash reference.

=head2 count

    my $count = $person->count;
    my $count = $person->count( $query );

Returns the number of documents in the associated collection or throws an error on
failure.  If a hash reference is provided, it is passed as a query parameter to
the MongoDB L<count_documents|MongoDB::Collection/count_documents> method.
Otherwise, the MongoDB
L<estimated_document_count|MongoDB::Collection/estimated_document_count> method
is used instead.

=head2 find_id

    my $obj = $person->find_id( $id );

Finds a document with the given C<_id> and returns it as an object of the
associated class.  Returns undef if the C<_id> is not found or throws an error
if one occurs.  This is a shorthand for the same query via C<find_one>:

    $person->find_one( { _id => $id } );

However, C<find_id> can take either a scalar C<_id> or a L<BSON::OID> object
as an argument.

=head2 find_one

    my $obj = $person->find_one( { name => "Larry Wall" } );

Finds the first document matching a query parameter hash reference and returns
it as an object of the associated class.  Returns undef if the C<_id> is not
found or throws an error if one occurs.

=head2 find

    my $cursor = $person->find( { tag => "trendy" } );
    my @objs   = $cursor->all;

Executes a query against C<collection_name>.  It returns a L<Meerkat::Cursor>
or throws an error on failure.  If a hash reference is provided, it is passed
as a query parameter to the MongoDB L<find|MongoDB::Collection/find> method,
otherwise all documents are returned.  You may include and optional options
hash reference after the query hash reference.  Iterating the cursor will return
objects of the associated class.

=head2 ensure_indexes

    $person->ensure_indexes;

Ensures an index is constructed for index returned by the C<_index> method
of the associated class.  Returns true on success or throws an error if one
occurs. See L<Meerkat::Role::Document> for more.

=for Pod::Coverage BUILD remove reinsert sync update thaw_object

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
