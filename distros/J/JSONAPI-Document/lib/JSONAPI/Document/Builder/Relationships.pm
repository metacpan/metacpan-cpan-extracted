package JSONAPI::Document::Builder::Relationships;
$JSONAPI::Document::Builder::Relationships::VERSION = '2.4';
=head1 NAME

JSONAPI::Document::Builder::Relationships - Related Resource Document builder

=head1 VERSION

version 2.4

=head1 DESCRIPTION

Builds the related resource document for a given row.

=cut

use Moo;
with 'JSONAPI::Document::Builder::Role::Parameters',
    'JSONAPI::Document::Builder::Role::Attributes',
    'JSONAPI::Document::Builder::Role::Type';

use Carp ();

=head2 row

The C<DBIx::Class::Row> for C<relationship>.

Note this is not the relationship row, rather
it is its parent.

=cut

has row => (
    is       => 'ro',
    required => 1,
);

=head2 relationship

String name of the relationship.

=cut

has relationship => (
    is       => 'ro',
    required => 1,
);

=head2 with_attributes

Boolean; Default: false

If specified, will build the relationship with attributes
instead of links.

Default behaviour is to build with links.

=cut

has with_attributes => (
    is      => 'ro',
    default => sub { 0 },
);

=head2 build : HashRef

Main caller method; Builds the related resource document.

=cut

sub build {
    my ($self) = @_;
    my $row    = $self->row;
    my $rel    = $self->relationship;

    unless ($row->has_relationship($rel)) {
        return undef;
    }

    if ($self->with_attributes) {
        return $self->build_document($row, $rel);
    }

    return $self->build_links_document($row, $rel);
}

=head2 build_links_document(DBIx::Class::Row $row, Str $relationship) : HashRef

Builds a HashRef containing strings that represent URLs for fetching
the given relationship, as well as the relationship ID(s).

For referential purposes, B<self> and B<related> mean the following:

=over

=item self

A link pointing to the relationship itself regardless of whether it is
a one-to-one or has-many type of relationship. It contains the word
"relationship" in the URL.

The specification defines this link as the B<link to the relationship itself>
in the context of the primary resource. This means that the resource(s)
returned from this URL should be directly related to the primary resource,
i.e. C<$dbic_row-E<gt>$relationship>.

=item related

Behaves the same as "self" except that its URL structure is
different. I fail to see the difference.

=back

=cut

sub build_links_document {
    my ($self, $row, $relationship) = @_;

    unless ($self->api_url) {
        Carp::confess('Missing required argument: api_url');
    }

    my $relationship_type = $self->document_type($relationship);

    my $data;
    my $rel_info = $row->result_source->relationship_info($relationship);
    if ($rel_info->{attrs}->{accessor} eq 'multi') {
        $data = [];
        my @rs = $row->$relationship->all();
        foreach my $related_row (@rs) {
            push @$data, { id => $related_row->id, type => $relationship_type };
        }
    } else {
        if (my $related_row = $row->$relationship) {
            $data = {
                id   => $related_row->id,
                type => $relationship_type
            };
        }
    }

    my $row_type = $self->document_type($row->result_source->source_name());

    return {
        links => {
            self => $self->api_url . '/'
                . $row_type . '/'
                . $row->id
                . '/relationships/'
                . $self->format_type($relationship),
            related => $self->api_url . '/' . $row_type . '/' . $row->id . '/' . $self->format_type($relationship),
        },
        data => $data,
    };
}

=head2 build_document(DBIx::Class::Row $row, Str $relationship) : HashRef

Builds a HashRef of the relationship(s) with attributes.

=cut

sub build_document {
    my ($self, $row, $relationship) = @_;
    my $rel_info = $row->result_source->relationship_info($relationship);
    if ($rel_info->{attrs}->{accessor} eq 'multi') {
        my @results;
        my @rs = $row->$relationship->all();
        foreach my $related_row (@rs) {
            push @results, $self->build_single_document($related_row, $relationship);
        }
        return { data => \@results };
    } else {
        if (my $related_row = $row->$relationship) {
            return { data => $self->build_single_document($related_row, $relationship), };
        } else {
            return { data => undef };
        }
    }
}

=head2 build_single_document(DBIx::Class::Row $related_row, Str $relationship) : HashRef

Builds a HashRef representing a single relationship row.

=cut

sub build_single_document {
    my ($self, $related_row, $relationship) = @_;
    return {
        id         => $related_row->id,
        type       => $self->document_type($relationship),
        attributes => $self->get_attributes($related_row),
    };
}

1;
