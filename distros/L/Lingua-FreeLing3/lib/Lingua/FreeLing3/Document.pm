package Lingua::FreeLing3::Document;

use Lingua::FreeLing3::Bindings;
use Lingua::FreeLing3::Paragraph;
use parent -norequire, 'Lingua::FreeLing3::Bindings::document';

use Carp;
use Scalar::Util 'blessed';
use warnings;
use strict;

### XXX - missing
#
# *add_positive = *Lingua::FreeLing3::Bindingsc::document_add_positive;
# *get_coref_group = *Lingua::FreeLing3::Bindingsc::document_get_coref_group;
# *get_coref_nodes = *Lingua::FreeLing3::Bindingsc::document_get_coref_nodes;
# *is_coref = *Lingua::FreeLing3::Bindingsc::document_is_coref;

our $VERSION = "0.01";

=encoding UTF-8

=head1 NAME

Lingua::FreeLing3::Document - Interface to FreeLing3 Documento objectt

=head1 SYNOPSIS

   use Lingua::FreeLing3::Document;

=head1 DESCRIPTION

This module is a wrapper to the FreeLing3 Document object.

=head2 C<new>

The constructor returns a new Document object.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    return bless $self => $class #amen
}

=head2 C<push>

Adds a paragraph to the end of the document.

=cut

sub push {
    my $self = shift;

    my $p;
    while ($p = shift) {
        if (blessed($p) && $p->isa('Lingua::FreeLing3::Bindings::paragraph')) {
            $self->SUPER::push($p);
        } else {
            carp "Ignoring push parameter: not a paragraph."
        }
    }
    return $self;
}

=head2 C<paragraphs>

Returns a list of the document paragraphs.

=cut

sub paragraphs {
    map { Lingua::FreeLing3::Paragraph->_new_from_binding($_) } @{ $_[0]->SUPER::elements() }
}

=head2 C<paragraph>

Returns the nth paragraph (starting in 0).

=cut

sub paragraph {
    my ($self, $n) = @_;
    $n >= $self->length() and return undef;
    Lingua::FreeLing3::Paragraph->_new_from_binding($self->SUPER::get($n));
}

=head2 C<length>

Returns the number of paragraphs in the document.

=cut

sub length { $_[0]->SUPER::size }


1;

__END__

=head1 SEE ALSO

Lingua::FreeLing3(3) for the documentation table of contents. The
freeling library for extra information, or perl(1) itself.

=head1 AUTHOR

Alberto Manuel Brandão Simões, E<lt>ambs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2012 by Projecto Natura

=cut


