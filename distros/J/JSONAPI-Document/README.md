# NAME

JSONAPI::Document - Turn DBIx results into JSON API documents.

# VERSION

version 1.0

# SYNOPSIS

    use JSONAPI::Document;
    use DBIx::Class::Schema;

    my $jsonapi = JSONAPI::Document->new({ api_url => 'http://example.com/api' });
    my $schema = DBIx::Class::Schema->connect(['dbi:SQLite:dbname=:memory:', '', '']);
    my $user = $schema->resultset('User')->find(1);

    # Builds a simple JSON API document, without any relationships
    my $doc = $jsonapi->resource_document($user);

    # Same but with all relationships
    my $doc = $jsonapi->resource_document($user, { with_relationships => 1 });

    # With only the author relationship
    my $doc = $jsonapi->resource_document($user, { with_relationships => 1, relationships => ['author'] });

    # Fully blown resource document with all relationships and their attributes
    my $doc = $jsonapi->compound_resource_document($user);

    # Multiple resource documents
    my $docs = $jsonapi->resource_documents($schema->resultset('User'));

# DESCRIPTION

This is a plug-and-play Moo class that builds data structures according
to the [JSON API](http://jsonapi.org/format/) specification.

# NOTES

JSON API documents require that you define the type of a document, which this
library does using the [source\_name](https://metacpan.org/pod/DBIx::Class::ResultSource#source_name)
of the result row. The type is also pluralised using [Linua::EN::Inflexion](https://metacpan.org/pod/Lingua::EN::Inflexion)
while keeping relationship names intact (i.e. an 'author' relationship will still be called 'author', with the type 'authors').

# ATTRIBUTES

## api\_url

Required; An absolute URL pointing to your servers JSON API namespace.

## kebab\_case\_attrs

Boolean attribute; setting this will make the column keys for each document into
kebab-cased-strings instead of snake\_cased. Default is false.

## attributes\_via

The method name to use throughout the creation of the resource document(s) to
get the attributes of the resources/relationships. This is useful if you
have a object that layers your DBIx results, you can instruct this
module to call that method instead of the default, which is
[get\_inflated\_columns](https://metacpan.org/pod/DBIx::Class::Row#get_inflated_columns).

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
    By default all the relationships will be included, use this if you
    only want a subset of relationships (e.g. when accepting the `includes`
    query parameter in your application routes).

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
appropriately when converted into its plural form. The resulting type is cached eternally into memory
(sorry) to minimize the need to re-compute the document type.

The following options can be given:

- `with_relationships` _Bool_

    If true, will introspect the rows relationships and include each
    of them in the relationships key of the document.

- `with_attributes` _Bool_

    If `with_relationships` is true, for each resulting row of a relationship,
    the attributes of that relation will be included.

    By default, each relationship will contain a [links object](http://jsonapi.org/format/#document-links).
    If this option is true, links object will be replaced with attributes.

- `includes` _ArrayRef_

    If `with_relationships` is true, this optional array ref can be
    provided to include a subset of relations instead of all of them.

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
