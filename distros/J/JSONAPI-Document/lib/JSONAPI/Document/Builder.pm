package JSONAPI::Document::Builder;
$JSONAPI::Document::Builder::VERSION = '2.4';
=head1 NAME

JSONAPI::Document::Builder - Resource Document builder

=head1 VERSION

version 2.4

=head1 DESCRIPTION

Builds a resource document.

=cut

use Moo;
with 'JSONAPI::Document::Builder::Role::Parameters',
    'JSONAPI::Document::Builder::Role::Attributes',
    'JSONAPI::Document::Builder::Role::Type';

use JSONAPI::Document::Builder::Relationships;

has row => (
    is       => 'ro',
    required => 1,
);

=head2 build : HashRef

Main caller method; Builds the resource document for C<row>.

=cut

sub build {
    my ($self) = @_;
    my $row    = $self->row;
    my $type   = $row->result_source->source_name();

    my %document = (
        id         => $row->id(),
        type       => $self->document_type($type),
        attributes => $self->get_attributes());

    return \%document;
}

=head2 build_relationship(Str $relationship, ArrayRef $fields, HashRef $options?) : HashRef

Builds the related resource document for the given relationship.

=cut

sub build_relationship {
    my ($self, $relationship, $fields, $options) = @_;
    $options //= {};
    my $builder = JSONAPI::Document::Builder::Relationships->new(
        api_url          => $self->api_url,
        fields           => $fields,
        kebab_case_attrs => $self->kebab_case_attrs,
        row              => $self->row,
        relationship     => $relationship,
        with_attributes  => $options->{with_attributes},
    );
    return $builder->build();
}

1;
