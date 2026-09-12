# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to interact with the elements (words or strings of words) of any language


package Lingua::Generic::Interface::Element;

use v5.20;
use strict;
use warnings;

use Carp;
use Data::Identifier v0.34;

our $VERSION = v0.03;

use parent 'Lingua::Generic::Interface::Base';


sub natural_language {
    my ($self) = @_;
    ...
}


# ---- Private helpers ----

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Generic::Interface::Element - module to interact with the elements (words or strings of words) of any language

=head1 VERSION

version v0.03

=head1 SYNOPSIS

    use parent 'Lingua::Generic::Interface::Element';

    say $element->as_string;

(since v0.03)

This module implements a generic interface to generic elements of texts.
An element is any complete part of a text, that can be for example a sentence (a group of words with a meaning, e.g. I<I like Sundays>),
a term (zero or more words that define a single concept, e.g. I<one hundred one>), or a single word (e.g. I<home>).
An element must not contain any incomplete words. It may have other elements as parts (such as a sentence consisting of words).

An element generally is in one natural language (which might be known or unknown).
But if the element has childen each of them might be in a different language
(e.g. I<He said: Dank je!>, where the first part is in English and the second in Dutch. In this case the English part is the outer most (main clause) and gives the fragment's language as English).

This module provides a base implementation for some of it's required methods.
Methods which this module cannot provide a useful default implementation for will have an implementation that dies on call.

This module inherits from
L<Lingua::Generic::Interface::Base>.

Packages may also want to implement L<Data::Identifier::Interface::Known>.

=head1 METHODS

=head2 natural_language

    my Data::Identifier $natural_language = $element->natural_language;

(since v0.03)

Returns the natural language of this element.
When no parameters are passed an instance of L<Data::Identifier> must be returned.

The implementation must die if any parameters are passed.
The implementation must die if the language is unknown.

=head3 Default implementation

The default implementation dies.

=head1 RESERVED METHODS

See L<Lingua::Generic::Interface::Base> for a list of reserved methods.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
