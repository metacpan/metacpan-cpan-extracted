package JSONAPI::Document;
$JSONAPI::Document::VERSION = '1.3';
# ABSTRACT: Turn DBIx results into JSON API documents.

use Moo;

use Carp ();
use CHI;
use Lingua::EN::Inflexion ();
use Lingua::EN::Segment;
use List::Util;

has kebab_case_attrs => (
    is      => 'ro',
    default => sub { 0 });

has attributes_via => (
    is      => 'ro',
    default => sub { 'get_inflated_columns' },
);

has api_url => (
    is  => 'ro',
    isa => sub {
        Carp::croak('api_url should be an absolute url') unless $_[0] =~ m/^http/;
    },
    required => 1,
);

has data_dir => (
    is       => 'ro',
    required => 1,
);

has chi => (is => 'lazy',);

has segmenter => (is => 'lazy',);

sub _build_chi {
    my ($self) = @_;
    return CHI->new(driver => 'File', root_dir => $self->data_dir);
}

sub _build_segmenter {
    return Lingua::EN::Segment->new;
}

sub compound_resource_document {
    my ($self, $row, $options) = @_;

    my @relationships = $row->result_source->relationships();
    if ($options->{includes}) {
        @relationships = @{ $options->{includes} };
    }

    my $document = $self->resource_document($row, { with_relationships => 1, includes => \@relationships });

    my @included;
    foreach my $relation (sort @relationships) {
        my $result = $self->_related_resource_documents($row, $relation, { with_attributes => 1 });
        if (my $related_docs = $result->{data}) {
            if (ref($related_docs) eq 'ARRAY') {    # plural relations
                push @included, @$related_docs;
            } else {                                # singular relations
                push @included, $related_docs;
            }
        }
    }

    return {
        data     => $document,
        included => \@included,
    };
}

sub resource_documents {
    my ($self, $resultset, $options) = @_;
    $options //= {};

    my @results = $resultset->all();
    return { data => [map { $self->resource_document($_, $options) } @results], };
}

sub resource_document {
    my ($self, $row, $options) = @_;
    Carp::confess('No row provided') unless $row;

    $options //= {};
    my $attrs_method       = $options->{attributes_via} // $self->attributes_via;
    my $with_kebab_case    = $options->{kebab_case_attrs} // $self->kebab_case_attrs;
    my $with_attributes    = $options->{with_attributes};
    my $with_relationships = $options->{with_relationships};
    my $includes           = $options->{includes};
    my $fields             = [grep { $_ } @{ $options->{fields} // [] }];

    $options->{related_fields} //= {};

    my $type = lc($row->result_source->source_name());
    my $noun = Lingua::EN::Inflexion::noun($type);

    my %columns = $row->$attrs_method($fields);
    my $id      = delete $columns{id} // $row->id;

    unless ($type && $id) {
        return undef;    # Document is not valid without a type and id.
    }

    my %relationships;
    if ($with_relationships) {
        my @relations = $includes ? @$includes : $row->result_source->relationships();
        foreach my $rel (@relations) {
            if ($row->has_relationship($rel)) {
                if ($with_attributes) {
                    $relationships{$rel} = $self->_related_resource_documents($row, $rel, $options);
                } else {
                    $relationships{$rel} = $self->_related_resource_links($row, $noun, $rel, $options);
                }
            }
        }
    }

    if ($with_kebab_case) {
        %columns = _kebab_case(%columns);
        if (values(%relationships)) {
            %relationships = _kebab_case(%relationships);
        }
    }

    my $resource_type = $self->chi->compute(
        __PACKAGE__ . ':' . $noun->plural,
        undef,
        sub {
            my @words = $self->segmenter->segment($noun->plural);
            unless (@words > 0) {
                @words = ($noun->plural);
            }
            return join('-', @words);
        });

    if (scalar(@$fields)) {
        %columns = %{ $self->_sparse_attributes({%columns}, $fields) };
    }

    my %document;

    $document{id}         = $id;
    $document{type}       = $resource_type;
    $document{attributes} = \%columns;

    if (values(%relationships)) {
        $document{relationships} = \%relationships;
    }

    return \%document;
}

sub _related_resource_links {
    my ($self, $row, $row_noun, $relation, $options) = @_;
    my $with_kebab_case = $options->{kebab_case_attrs} // $self->kebab_case_attrs;
    my $relation_row    = $row->$relation;
    my $relation_type   = $relation;

    if ($with_kebab_case) {
        $relation_type =~ s/_/-/g;
    }

    my $data;
    my $rel_info = $row->result_source->relationship_info($relation);
    if ($rel_info->{attrs}->{accessor} eq 'multi') {
        $data = [];
        my @rs = $relation_row->all();
        foreach my $rel_row (@rs) {
            push @$data, { id => $rel_row->id, type => $relation_type };
        }
    } else {
        $data = {
            id   => $relation_row->id,
            type => Lingua::EN::Inflexion::noun(lc($relation))->plural,
        };
    }

    return {
        links => {
            self    => $self->api_url . '/' . $row_noun->plural . '/' . $row->id . "/relationships/$relation_type",
            related => $self->api_url . '/' . $row_noun->plural . '/' . $row->id . "/$relation_type",
        },
        data => $data,
    };
}

sub _related_resource_documents {
    my ($self, $row, $relation, $options) = @_;
    $options //= {};

    my @results;

    my $rel_info = $row->result_source->relationship_info($relation);
    if ($rel_info->{attrs}->{accessor} eq 'multi') {
        my @rs = $row->$relation->all();
        foreach my $rel_row (@rs) {
            push @results,
                $self->_relation_with_attributes($rel_row, { %$options, relation => $relation, is_multi => 1, });
        }
        return { data => \@results, };
    } else {
        return { data => $self->_relation_with_attributes($row->$relation, { %$options, relation => $relation, }) };
    }
}

sub _relation_with_attributes {
    my ($self, $row, $options) = @_;
    my $with_kebab_case = $options->{kebab_case_attrs} // $self->kebab_case_attrs;
    my $attrs_method    = $options->{attributes_via} // $self->attributes_via;
    my $type            = $options->{relation};
    my $fields          = $options->{related_fields}->{$type} // [];

    if (!$options->{is_multi}) {
        $type = Lingua::EN::Inflexion::noun(lc($type))->plural;
    }

    my %attributes = $row->$attrs_method();
    if ($with_kebab_case) {
        %attributes = _kebab_case(%attributes);
        $type =~ s/_/-/g;
    }

    if (scalar(@$fields)) {
        %attributes = %{ $self->_sparse_attributes({%attributes}, $fields) };
    }

    return {
        id         => delete $attributes{id} // $row->id,
        type       => $type,
        attributes => \%attributes,
    };
}

sub _sparse_attributes {
    my ($self, $attributes, $fields) = @_;
    my @delete;
    for my $field (keys(%$attributes)) {
        unless (List::Util::first { $_ eq $field } @$fields) {
            push @delete, $field;
        }
    }
    delete $attributes->{$_} for @delete;
    return $attributes;
}

sub _kebab_case {
    my (%row) = @_;
    my %new_row;
    foreach my $column (keys(%row)) {
        my $value = $row{$column};
        $column =~ s/_/-/g;
        $new_row{$column} = $value;
    }
    return %new_row;
}

1;

__END__

=encoding UTF-8

=head1 NAME

JSONAPI::Document - Turn DBIx results into JSON API documents.

=head1 VERSION

version 1.3

=head1 SYNOPSIS

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

=head1 ATTRIBUTES

=head2 data_dir

Required; Directory string where this module can store computed document type strings. This should be
a directory that's ignored by your VCS.

=head2 api_url

Required; An absolute URL pointing to your servers JSON API namespace.

=head2 kebab_case_attrs

Boolean attribute; setting this will make the column keys for each document into
kebab-cased-strings instead of snake_cased. Default is false.

=head2 attributes_via

The method name to use throughout the creation of the resource document(s) to
get the attributes of the resources/relationships. This is useful if you
have a object that layers your DBIx results, you can instruct this
module to call that method instead of the default, which is
L<get_inflated_columns|https://metacpan.org/pod/DBIx::Class::Row#get_inflated_columns>.

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
By default all the relationships will be included, use this if you
only want a subset of relationships (e.g. when accepting the C<includes>
query parameter in your application routes).

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

Uses L<Lingua::EN::Segment|metacpan.org/pod/Lingua::EN::Segment> to set the appropriate type of the
document. This is a bit expensive, but it ensures that your schema results source name gets hyphenated
appropriately when converted into its plural form. The resulting type is cached into the C<data_dir>
to minimize the need to re-compute the document type.

The following options can be given:

=over

=item C<with_relationships> I<Bool>

If true, will introspect the rows relationships and include each
of them in the relationships key of the document.

=item C<with_attributes> I<Bool>

If C<with_relationships> is true, for each resulting row of a relationship,
the attributes of that relation will be included.

By default, each relationship will contain a L<links object|http://jsonapi.org/format/#document-links>.
If this option is true, links object will be replaced with attributes.

=item C<includes> I<ArrayRef>

If C<with_relationships> is true, this optional array ref can be
provided to include a subset of relations instead of all of them.

=item C<fields> I<ArrayRef>

An optional list of attributes to include for the given resource. Implements
L<sparse fieldsets|http://jsonapi.org/format/#fetching-sparse-fieldsets> in the specification.

Will pass the array reference to the C<attributes_via> method, which should make use
of the reference and return B<only> those attributes that were requested.

=item C<related_fields> I<HashRef>

Behaves the same as the C<fields> option but for relationships, returning only those fields
for the related resource that were requested.

Not specifying sparse fieldsets for a resource implies requesting all attributes for
that relationship.

=back

=head2 resource_documents(I<DBIx::Class::Row|Object> $row, I<HashRef> $options)

Builds the structure for multiple resource documents with a given resultset.

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
