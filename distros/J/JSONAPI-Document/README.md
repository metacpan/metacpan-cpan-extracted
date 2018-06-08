# NAME

JSONAPI::Document - Turn DBIx results into JSON API documents.

# VERSION

version 1.6

# SYNOPSIS

    use JSONAPI::Document;
    use DBIx::Class::Schema;

    my $jsonapi = JSONAPI::Document->new({ api_url => 'http://example.com/api' });
    my $schema = DBIx::Class::Schema->connect(['dbi:SQLite:dbname=:memory:', '', '']);
    my $user = $schema->resultset('User')->find(1);

    # Builds a simple JSON API document, without any relationships
    my $doc = $jsonapi->resource_document($user);

    # Same but with all relationships
    my $doc = $jsonapi->resource_document($user, { includes => 'all_related' });

    # With only the author relationship
    my $doc = $jsonapi->resource_document($user, { includes => ['author'] });

    # Fully blown resource document with all relationships and their attributes
    my $doc = $jsonapi->compound_resource_document($user);

    # Multiple resource documents
    my $docs = $jsonapi->resource_documents($schema->resultset('User'));

    # With sparse fieldsets
    my $doc = $jsonapi->resource_document($user, { fields => [qw/name email/] });

    # Relationships with sparse fieldsets
    my $doc = $jsonapi->resource_document($user, { related_fields => { author => [qw/name expertise/] } });

# DESCRIPTION

Moo class that builds data structures according to the [JSON API](http://jsonapi.org/format/) specification.

# NOTES

JSON API documents require that you define the type of a document, which this
library does using the [source\_name](https://metacpan.org/pod/DBIx::Class::ResultSource#source_name)
of the result row. The type is also pluralised using [Linua::EN::Inflexion](https://metacpan.org/pod/Lingua::EN::Inflexion)
while keeping relationship names intact (i.e. an 'author' relationship will still be called 'author', with the type 'authors').

This module supplies an opt-in Moo role that can be consumed by objects that layer over a DBIx::Class::Row,
`JSONAPI::Document::Role::Attributes`. Consuming objects should implement a method called `attributes`
which will be used throughout the creation of resource documents for that result type to build the attributes
of the document. This is useful when you have a more complicated set of attribute that cannot be fulfilled
by simply calling `get_inflated_columns` (the default behaviour).

# ATTRIBUTES

## data\_dir

Required; Directory string where this module can store computed document type strings. This should be
a directory that's ignored by your VCS.

## api\_url

Required; An absolute URL pointing to your servers JSON API namespace.

## kebab\_case\_attrs

Boolean attribute; setting this will make the column keys for each document into
kebab-cased-strings instead of snake\_cased. Default is false.

# METHODS

## compound\_resource\_document(_DBIx::Class::Row|Object_ $row, _HashRef_ $options)

A compound document is one that includes the resource object
along with the data of all its relationships.

Returns a _HashRef_ with the following structure:

    {
        data => {
            id => 1,
            type => 'authors',
            attributes => {},
            relationships => {},
        },
        included => [
            {
                id => 1,
                type => 'posts',
                attributes => { ... },
            },
            ...
        ]
    }

The following options can be given:

- `includes`

    An array reference specifying inclusion of a subset of relationships.
    By default all the relationships will be included. Use this if you
    only want a subset of relationships (e.g. when accepting the `includes`
    query parameter in your API requests, where you have to return only what
    relationships were requested).

    This argument should contain strings representing direct relationships to the row,
    and can also contain hash refs which specify nested inclusion. Example:

        $self->compound_resource_document($post, ['author', { comments => ['author'] }]);

    This will include the post as the primary document, its direct relationships 'author'
    and 'comments', and the 'author' of each related comment.

    **NOTE**: Nested relationships are experimental and come with the following limitations:

    - many\_to\_many relationships are not supported
    - only one level of depth is supported (so requesting 'include=comments.likes.author' will throw errors)

## resource\_document(_DBIx::Class::Row|Object_ $row, _HashRef_ $options)

Builds a single resource document for the given result row. Will optionally
include relationships that contain resource identifiers.

Returns a _HashRef_ with the following structure:

    {
        id => 1,
        type => 'authors',
        attributes => {},
        relationships => {},
    },

View the resource document specification [here](http://jsonapi.org/format/#document-resource-objects).

Uses [Lingua::EN::Segment](https://metacpan.org/pod/metacpan.org#pod-Lingua::EN::Segment) to set the appropriate type of the
document. This is a bit expensive, but it ensures that your schema results source name gets hyphenated
appropriately when converted into its plural form. The resulting type is cached into the `data_dir`
to minimize the need to re-compute the document type.

The following options can be given:

- `includes` _Str|ArrayRef_

    Optional; Used to specify any relationships of the row to include.

    This argument can contain either the value 'all\_related', which will return all the direct
    relationships of the row, or an array ref including a subset of direct relationships.

- `with_attributes` _Bool_

    If `includes` is used, for each resulting relationship row, the attributes (columns) of that
    relationship will be included.

    By default, each relationship will contain a [links object](http://jsonapi.org/format/#document-links).

    If this option is true, links object will be replaced with attributes.

- `fields` _ArrayRef_

    An optional list of attributes to include for the given resource. Implements
    [sparse fieldsets](http://jsonapi.org/format/#fetching-sparse-fieldsets) in the specification.

    Will pass the array reference to the `attributes_via` method, which should make use
    of the reference and return **only** those attributes that were requested.

- `related_fields` _HashRef_

    Behaves the same as the `fields` option but for relationships, returning only those fields
    for the related resource that were requested.

    Not specifying sparse fieldsets for a resource implies requesting all attributes for
    that relationship.

## resource\_documents(_DBIx::Class::Row|Object_ $row, _HashRef_ $options)

Builds the structure for multiple resource documents with a given resultset.

Returns a _HashRef_ with the following structure:

    {
        data => [
            {
                id => 1,
                type => 'authors',
                attributes => {},
                relationships => {},
            },
            ...
        ]
    }

See `resource_document` for a list of options.

# LICENSE

This code is released under the Perl 5 License.
