package JSONAPI::Document::Builder::Role::Type;
$JSONAPI::Document::Builder::Role::Type::VERSION = '2.4';
=head1 NAME

JSONAPI::Document::Builder::Role::Type - Normalizer for document types

=head1 VERSION

version 2.4

=head1 DESCRIPTION

Provides methods to correctly format a rows source name.

=cut

use Moo::Role;
use Mojo::Util            ();
use Lingua::EN::Inflexion ();

=head2 format_type(Str $type) : Str

Returns a dash cased version of the type.

Useful for deriving resource types for relationships,
which are already in the correct singular/plural form
and don't require any word manipulations.

=cut

sub format_type {
    my ($self, $type) = @_;
    unless ($type) {
        Carp::confess('Missing argument: type');
    }
    $type =~ s/[_-]+/-/g;
    return lc $type;
}

=head2 document_type(Str $type) : Str

Takes the type and creates its correct, pluralised type.

=cut

sub document_type {
    my ($self, $type) = @_;
    my $formatted_type = $self->format_type(Mojo::Util::decamelize($type));
    my @w = split('-', $formatted_type);
    push(@w, Lingua::EN::Inflexion::noun(pop @w)->plural);
    return join('-', @w);
}

1;
