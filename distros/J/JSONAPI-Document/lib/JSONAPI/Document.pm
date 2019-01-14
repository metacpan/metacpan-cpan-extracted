package JSONAPI::Document;
$JSONAPI::Document::VERSION = '2.4';
# ABSTRACT: Turn DBIx results into JSON API documents.

use Moo;

use Carp ();
use JSONAPI::Document::Builder;
use JSONAPI::Document::Builder::Compound;

has kebab_case_attrs => (
    is      => 'ro',
    default => sub { 0 });

has api_url => (
    is  => 'ro',
    isa => sub {
        Carp::croak('api_url should be an absolute url') unless $_[0] =~ m/^http/i;
    },
    required => 1,
);

sub compound_resource_document {
    my ($self, $row, $options) = @_;
    $options //= {};
    my $fields = [grep { $_ } @{ $options->{fields} // [] }];
    my $related_fields = $options->{related_fields} //= {};

    my @relationships = $row->result_source->relationships();
    if ($options->{includes}) {
        @relationships = @{ $options->{includes} };
    }

    my $builder = JSONAPI::Document::Builder::Compound->new(
        api_url          => $self->api_url,
        fields           => $fields,
        kebab_case_attrs => $self->kebab_case_attrs,
        row              => $row,
        relationships    => \@relationships,
    );

    return {
        data     => $builder->build_document(),
        included => $builder->build_relationships(\@relationships, $related_fields),
    };
}

sub resource_documents {
    my ($self, $resultset, $options) = @_;
    $options //= {};

    my @results;
    if ((ref($resultset) // '') eq 'ARRAY') {
        @results = @$resultset;
    } else {
        @results = $resultset->all();
    }
    return { data => [map { $self->resource_document($_, $options) } @results], };
}

sub resource_document {
    my ($self, $row, $options) = @_;
    Carp::confess('No row provided') unless $row;

    $options //= {};
    my $with_attributes = $options->{with_attributes};
    my $includes        = $options->{includes} // [];
    my $fields          = [grep { $_ } @{ $options->{fields} // [] }];
    my $related_fields  = $options->{related_fields} //= {};

    if (ref(\$includes) eq 'SCALAR' && $includes eq 'all_related') {
        $includes = [$row->result_source->relationships()];
    }

    my $builder = JSONAPI::Document::Builder->new(
        api_url          => $self->api_url,
        fields           => $fields,
        kebab_case_attrs => $self->kebab_case_attrs,
        row              => $row,
    );

    my $document = $builder->build();

    if (@$includes) {
        my %relationships;
        foreach my $relationship (@$includes) {
            my $relationship_type = $builder->format_type($relationship);
            $relationships{$relationship_type} = $builder->build_relationship(
                $relationship,
                $related_fields->{$relationship},
                { with_attributes => $with_attributes });
        }
        if (values(%relationships)) {
            $document->{relationships} = \%relationships;
        }
    }

    return $document;
}

1;

__END__

=encoding UTF-8

=head1 NAME

JSONAPI::Document - Turn DBIx results into JSON API documents.

=head1 VERSION

version 2.4

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Moo class that builds data structures according to the L<JSON API|http://jsonapi.org/format/> specification.

=head1 NOTES

JSON API documents require that you define the type of a document, which this
library does using the L<source_name|https://metacpan.org/pod/DBIx::Class::ResultSource#source_name>
of the result row. The type is also pluralised using L<Linua::EN::Inflexion|https://metacpan.org/pod/Lingua::EN::Inflexion>
while keeping relationship names intact (i.e. an 'author' relationship will still be called 'author', with the type 'authors').

This module supplies an opt-in Moo role that can be consumed by objects that layer over a DBIx::Class::Row,
C<JSONAPI::Document::Role::Attributes>. Consuming objects should implement a method called C<attributes>
which will be used throughout the creation of resource documents for that result type to build the attributes
of the document. This is useful when you have a more complicated set of attributes that cannot be fulfilled
by simply calling C<get_inflated_columns> (the default behaviour).

=head1 ATTRIBUTES

=head2 api_url

Required; An absolute URL pointing to your servers JSON API namespace.

=head2 kebab_case_attrs

Boolean attribute; setting this will make the column keys for each document into
kebab-cased-strings instead of snake_cased. Default is false.

=head1 METHODS

=head2 compound_resource_document(I<DBIx::Class::Row|Object> $row, I<HashRef> $options)

A compound document is one that includes the resource object
along with the data of all its relationships.

Returns a I<HashRef> with the following structure:

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

=over

=item C<includes>

An array reference specifying inclusion of a subset of relationships.
By default all the relationships will be included. Use this if you
only want a subset of relationships (e.g. when accepting the C<includes>
query parameter in your API requests, where you have to return only what
relationships were requested).

This argument should contain strings representing direct relationships to the row,
and can also contain hash refs which specify nested inclusion. Example:

    $self->compound_resource_document($post, ['author', { comments => ['author'] }]);

This will include the post as the primary document, its direct relationships 'author'
and 'comments', and the 'author' of each related comment.

B<NOTE>: Nested relationships are experimental and come with the following limitations:

=over 2

=item

many_to_many relationships are not supported

=item

Only one level of depth is supported (so requesting 'include=comments.likes.author' will throw errors)

=item

Are only available through C<compound_resource_document> (not C<resource_document>).

=back

=back

=head2 resource_document(I<DBIx::Class::Row|Object> $row, I<HashRef> $options)

Builds a single resource document for the given result row. Will optionally
include relationships that contain resource identifiers.

Returns a I<HashRef> with the following structure:

    {
        id => 1,
        type => 'authors',
        attributes => {},
        relationships => {},
    },

View the resource document specification L<here|http://jsonapi.org/format/#document-resource-objects>.

Uses C<decamelize> from L<Mojo::Util|metacpan.org/pod/Mojo::Util> to parse the
L<source_name|https://metacpan.org/pod/DBIx::Class::ResultSource#source_name> of the DBIx::Class::Row and
set the appropriate type of the document. This is used to ensure that your rows source name gets
hyphenated appropriately when converted into its plural form.

The following options can be given:

=over

=item C<includes> I<Str|ArrayRef>

Optional; Used to specify any relationships of the row to include.

This argument can contain either the value 'all_related', which will return all the direct
relationships of the row, or an array ref including a subset of direct relationships.

=item C<with_attributes> I<Bool>

If C<includes> is used, for each resulting relationship row, the attributes (columns) of that
relationship will be included.

By default, each relationship will contain a L<links object|http://jsonapi.org/format/#document-links>.

If this option is true, links object will be replaced with attributes.

=item C<fields> I<ArrayRef>

An optional list of attributes to include for the given resource. Implements
L<sparse fieldsets|http://jsonapi.org/format/#fetching-sparse-fieldsets> in the specification.

Will pass the array reference to the C<attributes> method (if you're using the attributes role), which
should make use of the reference and return B<only> those attributes that were requested.

=item C<related_fields> I<HashRef>

Behaves the same as the C<fields> option but for relationships, returning only those fields
for the related resource that were requested.

Not specifying sparse fieldsets for a resource implies requesting all attributes for
that relationship.

=back

=head2 resource_documents(I<DBIx::Class::ResultSet|Object|ArrayRef> $resultset, I<HashRef> $options)

Builds the structure for multiple resource documents with a given resultset.

C<$resultset> can be either a C<DBIx::Class::ResultSet> object in which case this method will call
C<all> on the resultset, an object that extends C<DBIx::Class::ResultSet>, or you can pass in an
ArrayRef from your own C<all> call.

Returns a I<HashRef> with the following structure:

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

See C<resource_document> for a list of options.

=head1 LICENSE

This code is released under the Perl 5 License.

=cut
