package JSONAPI::Document::Builder::Role::Type;
$JSONAPI::Document::Builder::Role::Type::VERSION = '1.5';
=head1 NAME

JSONAPI::Document::Builder::Role::Type - Normalizer for document types

=head1 VERSION

version 1.5

=head1 DESCRIPTION

Provides methods to correctly format a rows source name.

=cut

use Moo::Role;

use Lingua::EN::Inflexion ();

has chi => (
    is       => 'ro',
    required => 1,
);

has segmenter => (
    is       => 'ro',
    required => 1,
);

=head2 format_type(Str $type) : Str

Returns a dash cased version of the type.

=cut

sub format_type {
    my ($self, $type) = @_;
    unless ($type) {
        Carp::confess('Missing argument: type');
    }
    $type =~ s/_/-/g;
    return lc $type;
}

=head2 document_type(Str $type) : Str

Takes the type and creates its correct, pluralised type.

=cut

sub document_type {
    my ($self, $type) = @_;
    my $noun   = Lingua::EN::Inflexion::noun($type);
    my $result = $self->chi->compute(
        'JSONAPI::Document:' . $noun->plural,
        undef,
        sub {
            my @words = $self->segmenter->segment($noun->plural);
            unless (scalar(@words) > 0) {
                push @words, $noun->plural;
            }
            @words = map { $_ } grep { $_ =~ m/\A(?:[A-Za-z]+)\z/ } @words;
            return $self->format_type(join('-', @words));
        });
    return $result;
}

1;
