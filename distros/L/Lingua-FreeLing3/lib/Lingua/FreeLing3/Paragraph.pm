package Lingua::FreeLing3::Paragraph;

use Lingua::FreeLing3::Bindings;
use parent -norequire, 'Lingua::FreeLing3::Bindings::paragraph';

use Scalar::Util 'blessed';
use Carp;
use warnings;
use strict;

# XXX
# *empty = *Lingua::FreeLing3::Bindingsc::ListSentence_empty;
# *clear = *Lingua::FreeLing3::Bindingsc::ListSentence_clear;

our $VERSION = "0.03";

=encoding UTF-8

=head1 NAME

Lingua::FreeLing3::Paragraph - Interface to FreeLing3 Paragraph object

=head1 SYNOPSIS

   use Lingua::FreeLing3::Paragraph;

=head1 DESCRIPTION

This module is a wrapper to the FreeLing3 Paragraph object.

=head2 C<new>

The constructor returns a new Paragraph object: a list of sentences

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    return bless $self => $class #amen
}

sub _new_from_binding {
    my ($class, $paragraph) = @_;
    bless $paragraph => $class #amen
}

=head2 C<push>

Adds one or more sentences to the paragraph.

=cut

sub push {
    my $self = shift;

    my $p;
    while ($p = shift) {
        if (blessed($p) && $p->isa('Lingua::FreeLing3::Bindings::sentence')) {
            $self->SUPER::push($p);
        } else {
            carp "Ignoring push parameter: not a sentence."
        }
    }
    return $self;
}

=head2 C<sentence>

Gets a sentence from a paragraph. Note that this method is extremely
slow, given that FreeLing paragraph is implemented as a
list. Therefore, retrieving the nth element of the list does n
iterations on a linked list.

=cut

sub sentence {
    my ($self, $n) = @_;
    $n >= $self->length() and return undef;
    Lingua::FreeLing3::Sentence->_new_from_binding($self->SUPER::get($n));
}

=head2 C<sentences>

Returns an array of sentences from a paragraph.

=cut

sub sentences {
    map { Lingua::FreeLing3::Sentence->_new_from_binding($_) } @{ $_[0]->SUPER::elements() }
}

=head2 C<length>

Returns the number of sentences in the paragraph.

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


