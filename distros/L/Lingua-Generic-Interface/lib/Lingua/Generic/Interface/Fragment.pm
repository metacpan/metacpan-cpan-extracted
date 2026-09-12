# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to interact with strings of words of any language


package Lingua::Generic::Interface::Fragment;

use v5.20;
use strict;
use warnings;

use Carp;
use Data::Identifier v0.34;

our $VERSION = v0.03;

use parent 'Lingua::Generic::Interface::Element';


sub words {
    my ($self) = @_;
    ...
}


sub natural_language {
    my ($self, @opts) = @_;
    my $language;

    croak 'Stray options passed' if scalar @opts;

    foreach my Lingua::Generic::Interface::Word $word ($self->words) {
        my $wl = $word->natural_language;

        $language //= $wl;

        croak 'Mixed languages' unless $language->eq($wl);
    }

    return $language // croak 'Unknown language';
}


# ---- Private helpers ----

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Generic::Interface::Fragment - module to interact with strings of words of any language

=head1 VERSION

version v0.03

=head1 SYNOPSIS

    use parent 'Lingua::Generic::Interface::Fragment';

    say $fragment->as_string;

    foreach my Lingua::Generic::Interface::Word $word ($fragment->words) {
        say $word->as_string;
    }

(since v0.03)

This module is a generic interface to strings of words.
Fragments can be large sections of texts, sentences, or parts of sentences.

This module inherits from
L<Lingua::Generic::Interface::Element> (since v0.03).

Packages may also want to implement L<Data::Identifier::Interface::Known>.

=head1 METHODS

=head2 words

    my @words = $fragment->words;

(since v0.03)

Returns the list of all the words in the fragment.
The words are to be returned in-order.
This also means that if any word is repreated within the fragment it is returned more than once.

B<Note:>
Non word parts of the fragment such as punctuation are not returned.
This means that the returned list is not considered a truthful representation of the fragment.

When no parameters are passed an instances of L<Lingua::Generic::Interface::Word> must be returned.

The implementation must die if any parameters are passed.
The implementation must die if the value can not evaluated.
The implementation can return an empty list if the fragment does not contain any words.

=head3 Default implementation

The default implementation dies.

=head2 natural_language

    my Data::Identifier $natural_language = $fragment->natural_language;

(since v0.03)

Returns the natural language of this fragment.
Note that a fragment can contrain parts that are of other languages.

See also L<Lingua::Generic::Interface::Element/natural_language> for the interface.

=head3 Default implementation

The default implementation will return the language of the words in the fragment if all words are of the same language.
The default implementation may, but will likely not cache the result.

=head1 RESERVED METHODS

See L<Lingua::Generic::Interface::Base> for a list of reserved methods.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
