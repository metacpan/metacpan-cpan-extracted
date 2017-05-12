package Document::Transform::Backend::MongoDB;
BEGIN {
  $Document::Transform::Backend::MongoDB::VERSION = '1.110530';
}

#ABSTRACT: Talk to a MongoDB via a simple interface

use Moose;
use namespace::autoclean;

use MongoDB;
use MongoDBx::AutoDeref;
use Throwable::Error;
use MooseX::Params::Validate;
use MooseX::Types::Moose(':all');
use MooseX::Types::Structured(':all');
use Moose::Util::TypeConstraints();



has $_.'_constraint' =>
(
    is => 'ro',
    isa => 'Moose::Meta::TypeConstraint',
    builder => '_build_'.$_.'_constraint',
    lazy => 1,
) for qw/document transform/;

sub _build_document_constraint
{
    my ($self) = @_;

    return Moose::Util::TypeConstraints::subtype
    ({
        as => HashRef,
        where => sub
        {
            exists($_->{$self->document_id_key}) &&
            not exists($_->{$self->reference_id_key})
        },
    });
}

sub _build_transform_constraint
{
    my ($self) = @_;

    return Moose::Util::TypeConstraints::subtype
    ({
        as => HashRef,
        where => sub
        {
            exists($_->{$self->transform_id_key}) &&
            exists($_->{$self->reference_id_key}) &&
            exists($_->{operations}) &&
            (ArrayRef[Dict[path => Str, value => Defined]])->check($_->{operations});
        },
    });
}


has host =>
(
    is => 'ro',
    isa => Str,
    predicate => 'has_host',
);


has connection =>
(
    is => 'ro',
    isa => 'MongoDB::Connection',
    default => sub
    {
        my $self = shift;
        unless($self->has_host)
        {
            Throwable::Error->throw
            ({
                message => 'host must be provided to use the default ' .
                    'connection constructor'
            });
        }
        return MongoDB::Connection->new(host => $self->host)
    },
    lazy => 1,
);


has database_name =>
(
    is => 'ro',
    isa => Str,
    predicate => 'has_database_name',
);


has database =>
(
    is => 'ro',
    isa => 'MongoDB::Database',
    default => sub
    {
        my $self = shift;
        unless($self->has_database_name)
        {
            Throwable::Error->throw
            ({
                message => 'database must be provided to use the default ' .
                    'db constructor'
            });
        }
        return $self->connection->get_database($self->database_name);
    },
    lazy => 1,
);


has document_collection =>
(
    is => 'ro',
    isa => Str,
    predicate => 'has_document_collection',
);


has documents =>
(
    is => 'ro',
    isa => 'MongoDB::Collection',
    default => sub
    {
        my $self = shift;
        unless($self->has_document_collection)
        {
            Throwable::Error->throw
            ({
                message => 'document_collection must be provided to use the ' .
                    'default docs constructor'
            });
        }

        return $self->database->get_collection($self->document_collection);
    },
    lazy => 1,
);


has transform_collection =>
(
    is => 'ro',
    isa => Str,
    predicate => 'has_transform_collection',
);


has transforms =>
(
    is => 'ro',
    isa => 'MongoDB::Collection',
    default => sub
    {
        my $self = shift;
        unless($self->has_transform_collection)
        {
            Throwable::Error->throw
            ({
                message => 'transform_collection must be provided to use the ' .
                    'default transforms constructor'
            });
        }

        return $self->database->get_collection($self->transform_collection);
    },
    lazy => 1,
);


sub fetch_document_from_key
{
    my ($self, $key) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => Defined},
    );

    return $self->documents->find_one({$self->document_id_key => $key});
}


sub fetch_transform_from_key
{
    my ($self, $key) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => Defined},
    );

    my $val =  $self->transforms->find_one({$self->transform_id_key => $key});
    return $val;
}


sub fetch_document_from_transform
{
    my $self = shift;
    my ($transform) = pos_validated_list
    (
        \@_,
        {isa => $self->transform_constraint},
    );
    return $transform->{$self->reference_id_key}->fetch();
}



sub fetch_transform_from_document { }


sub store_document
{
    my $self = shift;
    my ($item, $safe) = pos_validated_list
    (
        \@_,
        {isa => $self->document_constraint},
        {isa => Bool, optional => 1}
    );

    unless(exists($item->{_id}))
    {
        $self->documents->insert($item, ($safe ? {safe => 1} : ()) );
    }

    $self->documents->update(
        {$self->document_id_key => $item->{$self->document_id_key}},
        $item, ($safe ? {safe => 1} : ())
    );
}


sub store_transform
{
    my $self = shift;
    my ($item, $safe) = pos_validated_list
    (
        \@_,
        {isa => $self->transform_constraint},
        {isa => Bool, optional => 1}
    );

    unless(exists($item->{_id}))
    {
        $self->transforms->insert($item, ($safe ? {safe => 1} : ()) );
    }

    $self->transforms->update(
        {$self->transform_id_key => $item->{$self->transform_id_key}},
        $item, ($safe ? {safe => 1} : ())
    );
}


sub has_document
{
    my ($self, $key) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => Defined},
    );

    return defined($self->documents->find_one({$self->document_id_key => $key}));
}


sub has_transform
{
    my ($self, $key) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => Defined},
    );

    return defined($self->transforms->find_one({$self->transform_id_key => $key}));
}


sub is_same_document
{
    my $self = shift;
    my ($doc1, $doc2) = validated_list
    (
        \@_,
        {isa => $self->document_constraint},
        {isa => $self->document_constraint},
    );

    return $doc1->{$self->document_id_key} eq $doc2->{$self->document_id_key};
}


sub is_same_transform
{
    my $self = shift;
    my ($tra1, $tra2) = pos_validated_list
    (
        \@_,
        {isa => $self->transform_constraint},
        {isa => $self->transform_constraint},
    );

    return $tra1->{$self->transform_id_key} eq $tra2->{$self->transform_id_key};
}

with 'Document::Transform::Role::Backend';




has '+'.$_.'_id_key' =>
(
    default => '_id'
) for qw/document transform/;

has '+reference_id_key' => ( default => 'source' );

__PACKAGE__->meta->make_immutable();
1;


=pod

=head1 NAME

Document::Transform::Backend::MongoDB - Talk to a MongoDB via a simple interface

=head1 VERSION

version 1.110530

=head1 SYNOPSIS

    use Document::Transform::Backend::MongoDB;

    my $backend = Document::Transform::Backend::MongoDB->new(
        host => $ENV{MONGOD}
        database_name => 'foo',
        transform_collection => 'transforms',
        document_collection => 'documents');

    my $doc = $backend->fetch_document_from_key(
        MongoDB::OID->new(value => 'deadbeef'));

=head1 DESCRIPTION

So you need Document::Transform to talk MongoDB. You're in luck, bucko, because this module is your godsend. And it comes by default! Now, there are a couple of different ways to instantiate this and different levels of attributes that can be filled. You can plug in the collections, you can plug in collection names and a database instance, you can plug in collection names, a database name, and connection instance. And if you don't have any instances then some connection info, database name, and collection names are all you need! So it is like you pick your level of support when calling into a PBS telethon.

=head1 PUBLIC_ATTRIBUTES

=head2 document_constraint

    is: ro, isa: Moose::Meta::TypeConstraint
    builder: _build_document_constraint, lazy: 1

This attribute implements
L<Document::Transform::Role::Backend/document_constraint> and provides a
meaningful type constraint built using L</document_id_key> in the where clause
to check for the appropriate keys in the data structure that represents a
document.

=head2 transform_constraint

    is: ro, isa: Moose::Meta::TypeConstraint
    builder: _build_transform_constraint, lazy: 1

This attribute implements
L<Document::Transform::Role::Backend/transform_constraint> and provides a
meaningful type constraint built using L</transform_id_key> in the where clause
to check for the appropriate keys in the data structure that represents a
transform.

=head2 host

    is: ro, isa: Str

host contains the host string provided to the MongoDB::Connection constructor.

=head2 connection

    is: ro, isa: MongoDB::Connection, lazy: 1

This attribute holds the MongoDB connection object. If this isn't provided and
it is accessed, a connection will be constructed using the L</host> attribute.

=head2 database_name

    is: ro, isa: Str

If the collections are not provided, this attribute must be provided as a means
to access the collections named in the L</transform_collection> and
L</document_collection>

=head2 database

    is: ro, isa: MongoDB::Database, lazy: 1

This attribute holds the MongoDB data in which the transform and document
collections are held. If this isn't provided in the constructor, one will be
constructed using the value from L</database_name>. If there is no value, an
exception will be thrown.

=head2 document_collection

    is: ro, isa: Str

If a collection is not passed to L</documents>, this attribute will be used to
access a collection from the L</database>.

=head2 documents

    is: ro, isa: MongoDB::Collection, lazy: 1

This attribute holds the collection from MongoDB that should be the documents
that should be fetched for transformation. If a collection is not passed to the
constructor, one will be pulled from the database using the value from
L</document_collection>

=head2 transform_collection

    is: ro, isa: Str

If a collection is not passed to L</transforms>, this attribute will be used to
access a collection from the L</database>.

=head2 transforms

    is: ro, isa: MongoDB::Collection, lazy: 1

This attribute holds the collection from MongoDB that should be the transforms
that should be fetched for transformation. If a collection is not passed to the
constructor, one will be pulled from the database using the value from
L</transform_collection>

=head2 document_id_key

    is: ro, isa: Str,
    default: '_id',

=head2 transform_id_key

    is: ro, isa: Str,
    +default: '_id',

=head2 reference_id_key

    is: ro, isa: Str,
    +default: 'source',

This attribute holds the key used in the transform to reference the document to
which this transform should occur.

=head1 PUBLIC_METHODS

=head2 fetch_document_from_key

    (Defined)

This method implements the
L<Docoument::Transform::Role::Backend/fetch_document_from_key> method. It takes
a single key that should match a document within the documents collection with
the right L</document_id_key> attribute.

=head2 fetch_transform_from_key

    (Defined)

This method implements the
L<Docoument::Transform::Role::Backend/fetch_transform_from_key> method. It
takes a single key that should match a transform within the transforms
collection with the right L</transform_id_key> attribute.

=head2 fetch_document_from_transform

    (Transform)

This method implements the
L<Docoument::Transform::Role::Backend/fetch_document_from_transform> method. It
takes a Transform defined by L</transform_constraint> that has DBRef to a document
stored with in the L</reference_id_key> attribute of the transform.

=head2 fetch_transform_from_document

This method is a no-op implementation of
L<Docoument::Transform::Role::Backend/fetch_transform_from_document>. 

=head2 store_document

This method implements the L</Document::Transform::Role::Backend/store_document>
method with one key notable option. In addition to the document to store, a
second boolean value can be passed to denote whether a "safe" insert/update
should take place.

This method makes use of L</document_id_key> to perform an update of the
document.

=head2 store_transform

This method implements the L</Document::Transform::Role::Backend/store_transform>
method with one key notable option. In addition to the transform to store, a
second boolean value can be passed to denote whether a "safe" insert/update
should take place.

This method makes use of L</transform_id_key> to perform an update of the
transform.

=head2 has_document

    (Defined)

This method implements L<Document::Transform::Role::Backend/has_document>.
Simply provide a key and it will check Mongo if such a document exists using
L</document_id_key>

=head2 has_transform

    (Defined)

This method implements L<Document::Transform::Role::Backend/has_transform>.
Simply provide a key and it will check Mongo if such a transform exists using
L</transform_id_key>

=head2 is_same_document

    (Document, Document)

This method implements L<Document::Transform::Role::Backend/is_same_document>.
It does a string comparison between the two documents values stored in
L</document_id_key>. If using the default '_id' value for L</document_id_key>,
this will stringify the MongoDB::OID objects down to their hex key and compare
them. 

=head2 is_same_transform

    (Transform, Transform)

This method implements L<Transform::Transform::Role::Backend/is_same_transform>.
It does a string comparison between the two transforms values stored in
L</transform_id_key>. If using the default '_id' value for L</transform_id_key>,
this will stringify the MongoDB::OID objects down to their hex key and compare
them. 

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

