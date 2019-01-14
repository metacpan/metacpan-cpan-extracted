package JSONAPI::Document::Builder::Compound;
$JSONAPI::Document::Builder::Compound::VERSION = '2.4';
=head1 NAME

JSONAPI::Document::Builder::Compound - Compound Resource Document builder

=head1 VERSION

version 2.4

=head1 DESCRIPTION

Builds a compound resource document, which is essentially a resource
document with all of its relationships and attributes.

=cut

use Moo;
extends 'JSONAPI::Document::Builder';

use Carp ();
use JSONAPI::Document::Builder::Relationships;

=head2 relationships

ArrayRef of relationships to include. This
is populated by the C<include> param of
a JSON API request.

=cut

has relationships => (
    is      => 'ro',
    default => sub { [] },
);

=head2 primary_relationships, nested_relationships

Primary relationships are those belonging directly to C<row>,
while nested relationships is an ArrayRef of HashRefs as follows:

 [ { primary_related => [qw/primary relationships for primary_related/] }, { ... } ]

Where primary_related is the relationship for C<row>, and
its associated ArrayRef contains relationships for it.

=cut

has primary_relationships => (is => 'lazy');
has nested_relationships  => (is => 'lazy');

sub _build_primary_relationships {
    return [map { $_ } grep { ref($_) ne 'HASH' } @{ $_[0]->relationships }];
}

sub _build_nested_relationships {
    return [map { $_ } grep { ref($_) eq 'HASH' } @{ $_[0]->relationships }];
}

=head2 build_document : HashRef

Builds a HashRef for the primary resource document.

When C<relationships> is populated, will include
a relationships entry in the document, populated
with related links and identifiers.

=cut

sub build_document {
    my ($self) = @_;

    my $document = $self->build();

    my %relationships;
    foreach my $relationship (@{ $self->primary_relationships },
        map { $_ } map { keys(%$_) } @{ $self->nested_relationships })
    {
        my $relationship_type = $self->format_type($relationship);
        $relationships{$relationship_type} = $self->build_relationship($relationship);
    }
    if (values(%relationships)) {
        $document->{relationships} = \%relationships;
    }

    return $document;
}

=head2 build_relationships : ArrayRef

Builds an ArrayRef containing all given relationships.
These relationships are built with their attributes.

=cut

sub build_relationships {
    my ($self, $relationships, $fields) = @_;
    $fields //= {};
    return [] unless $relationships;

    if (ref($relationships) ne 'ARRAY') {
        Carp::confess('Invalid request: relationships must be an array ref.');
    }

    return [] unless @$relationships;

    my @included;

    foreach my $relation (sort @{ $self->primary_relationships }) {
        my $result = $self->build_relationship($relation, $fields->{$relation}, { with_attributes => 1 });
        if (my $related_docs = $result->{data}) {
            if (ref($related_docs) eq 'ARRAY') {    # plural relations
                push @included, @$related_docs;
            } else {                                # singular relations
                push @included, $related_docs;
            }
        }
    }

    # Note that this fetches the relationship on $self->row, so it shouldn't be done above.
    foreach my $nested (@{ $self->nested_relationships }) {
        my ($relation_source) = keys(%$nested);
        my $result_ref =
            $self->build_relationship($relation_source, $fields->{$relation_source}, { with_attributes => 1 })->{data};

        if (ref($result_ref) eq 'ARRAY') {  # The source relation is a has_many, link the nested resources for each one.
            my $source_row = $self->row->$relation_source;
            if ($source_row->can('all')) {    # Check if any overlaying dbix resultset class can do "all"
                my $includes =
                    $self->build_nested_from_resultset($source_row, $result_ref, $nested->{$relation_source}, $fields);
                push @included, $_ for @$includes;
            }
        } else {
            my $source_row = $self->row->$relation_source;
            my %relationships;
            foreach my $relationship (@{ $nested->{$relation_source} }) {
                my $relationship_type = $self->format_type($relationship);
                my ($related_data, $includes) = $self->build_nested_relationship(
                    $source_row, $relationship,
                    $fields->{$relationship},
                    { with_attributes => 1 });
                $relationships{$relationship_type} = $related_data;
                push @included, $_ for @$includes;
            }
            if (values(%relationships)) {
                $result_ref->{relationships} = \%relationships;
            }
            push @included, $result_ref;
        }
    }

    return \@included;
}

=head2 build_nested_relationship(Str $primary, Str $relationship, ArrayRef $fields, HashRef $options?) : Array

Uses build_relationship with the rows related resource as
the C<row> argument so the builder can find the relationship.

=cut

sub build_nested_relationship {
    my ($self, $primary_row, $relationship, $fields, $options) = @_;
    $options //= {};
    my $builder = JSONAPI::Document::Builder::Relationships->new({
        api_url          => $self->api_url,
        fields           => $fields,
        kebab_case_attrs => $self->kebab_case_attrs,
        row              => $primary_row,
        relationship     => $relationship,
        with_attributes  => $options->{with_attributes},
    });
    my $document = $builder->build();
    my ($data, $included);
    if (my $doc_data = $document->{data}) {
        if (ref($doc_data) eq 'ARRAY') {
            $data = [];
            foreach my $doc (@$doc_data) {
                push @$data, { id => $doc->{id}, type => $doc->{type} };
                push @$included, $doc;
            }
        } else {
            $data = { id => $doc_data->{id}, type => $doc_data->{type} };
            push @$included, $doc_data;
        }
    }
    return ({ data => $data }, $included);
}

sub build_nested_from_resultset {
    my ($self, $source_row, $primary_docs, $nested_relations, $fields) = @_;
    my @included;
    my @results = $source_row->all();
    foreach my $primary_doc (@$primary_docs) {
        my $row = List::Util::first { $_->id eq $primary_doc->{id} } @results;
        my %relationships;
        foreach my $relationship (@$nested_relations) {
            my $relationship_type = $self->format_type($relationship);
            my ($related_data, $includes) = $self->build_nested_relationship(
                $row, $relationship,
                $fields->{$relationship},
                { with_attributes => 1 },
            );
            $relationships{$relationship_type} = $related_data;
            foreach my $include (@$includes) {
                unless (    # avoid having multiple nested relationships of the same type
                    List::Util::any {
                        $_->{id} eq $include->{id}
                            && $_->{type} eq $include->{type}
                    }
                    @included
                    )
                {
                    push @included, $_ for @$includes;
                }
            }
        }
        if (values(%relationships)) {
            $primary_doc->{relationships} = \%relationships;
        }
        push @included, $primary_doc;
    }
    return \@included;
}

1;
