package JSONAPI::Document;
$JSONAPI::Document::VERSION = '0.4';
# ABSTRACT: Turn DBIx results into JSON API documents.

use Moo;

use Lingua::EN::Inflexion ();
use Carp                  ();

has kebab_case_attrs => (
    is      => 'ro',
    default => sub { 0 }
);

has attributes_via => (
    is      => 'ro',
    default => sub { 'get_inflated_columns' },
);

sub compound_resource_document {
    my ( $self, $row, $options ) = @_;

    my $document = $self->resource_document( $row, { with_relationships => 1 } );

    my @includes;
    my @relationships =
      @{ $options->{includes} // [] } || $row->result_source->relationships();
    foreach my $relation ( sort @relationships ) {
        my $result = $self->_related_resource_documents( $row, $relation, { with_attributes => 1 } );
        if ($result) {
            push @includes, @$result;
        }
    }

    return {
        data     => [$document],
        included => \@includes,
    };
}

sub resource_documents {
    my ( $self, $resultset, $options ) = @_;
    $options //= {};

    my @results = $resultset->all();
    return { data => [ map { $self->resource_document( $_, $options ) } @results ], };
}

sub resource_document {
    my ( $self, $row, $options ) = @_;
    Carp::confess('No row provided') unless $row;

    $options //= {};
    my $attrs_method       = $options->{attributes_via} // $self->attributes_via;
    my $with_kebab_case    = $options->{kebab_case_attrs} // $self->kebab_case_attrs;
    my $with_relationships = $options->{with_relationships};
    my $includes           = $options->{includes};

    my $type = lc( $row->result_source->source_name() );
    my $noun = Lingua::EN::Inflexion::noun($type);

    my %columns = $row->$attrs_method();
    my $id      = delete $columns{id} // $row->id;

    unless ( $type && $id ) {

        # Document is not valid without a type and id.
        return undef;
    }

    my %relationships;
    if ($with_relationships) {
        my @relations = $includes ? @$includes : $row->result_source->relationships();
        foreach my $rel (@relations) {
            if ( $row->has_relationship($rel) ) {
                my $docs = $self->_related_resource_documents( $row, $rel, $options );
                $docs = $docs->[0] if ( scalar(@$docs) == 1 );
                $relationships{$rel} = { data => $docs };
            }
        }
    }

    if ($with_kebab_case) {
        %columns = _kebab_case(%columns);
    }

    my %document;

    $document{id}         = $id;
    $document{type}       = $noun->plural;
    $document{attributes} = \%columns;

    if ( values(%relationships) ) {
        $document{relationships} = \%relationships;
    }

    return \%document;
}

sub _related_resource_documents {
    my ( $self, $row, $relation, $options ) = @_;
    $options //= {};
    my $with_attributes = $options->{with_attributes};
    my $with_kebab_case = $options->{kebab_case_attrs} // $self->kebab_case_attrs;
    my $attrs_method    = $options->{attributes_via} // $self->attributes_via;

    my @results;

    my $rel_info = $row->result_source->relationship_info($relation);
    if ( $rel_info->{attrs}->{accessor} eq 'multi' ) {
        my @rs = $row->$relation->all();
        foreach my $rel_row (@rs) {
            my %attributes;
            if ($with_attributes) {
                %attributes = $rel_row->$attrs_method();
            }
            if ($with_kebab_case) {
                %attributes = _kebab_case(%attributes);
            }

            push @results,
              {
                id   => delete $attributes{id} // $rel_row->id,
                type => Lingua::EN::Inflexion::noun( lc( $rel_row->result_source->source_name() ) )->plural,
                values(%attributes) ? ( attributes => \%attributes ) : (),
              };
        }
    }
    else {
        my %attributes = $row->$relation->$attrs_method();
        if ($with_kebab_case) {
            %attributes = _kebab_case(%attributes);
        }
        push @results,
          {
            id   => delete $attributes{id} // $row->$relation->id,
            type => Lingua::EN::Inflexion::noun( lc( $row->$relation->result_source->source_name() ) )->plural,
            $with_attributes ? ( attributes => \%attributes ) : (),
          };
    }

    return \@results;
}

sub _kebab_case {
    my (%row) = @_;
    my %new_row;
    foreach my $column ( keys(%row) ) {
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

version 0.4

=head1 SYNOPSIS

    use JSONAPI::Document;
    use DBIx::Class::Schema;

    my $jsonapi = JSONAPI::Document->new();
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

=head1 DESCRIPTION

This is a plug-and-play Moo class that builds data structures according
to the L<JSON API|http://jsonapi.org/format/> specification.

=head1 NOTES

JSON API documents require that you define the type of a document, which this
library does using the L<source_name|https://metacpan.org/pod/DBIx::Class::ResultSource#source_name>
of the result row. The type is also pluralised using L<Linua::EN::Inflexion|https://metacpan.org/pod/Lingua::EN::Inflexion>
while keeping relationship names intact (i.e. an 'author' relationship will still be called 'author', with the type 'authors').

=head1 ATTRIBUTES

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
        data => [
            {
                id => 1,
                type => 'authors',
                attributes => {},
                relationships => {},
            }
        ],
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

The following options can be given:

=over

=item C<with_relationships> I<Bool>

If true, will introspect the rows relationships and include each
of them in the relationships key of the document.

=item C<includes> I<ArrayRef>

If C<with_relationships> is true, this optional array ref can be
provided to include a subset of relations instead of all of them.

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

=cut
