# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to provide information on languages and language specific properties


package Lingua::Generic::Information;

use v5.20;
use strict;
use warnings;

use Carp;
use Data::Identifier v0.36;
use Lingua::Generic::Information::Language;

our $VERSION = v0.01;


sub lookup_language {
    my ($pkg, $idtype, $id, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return Lingua::Generic::Information::Language->_find($idtype, $id);
}


# ---- Private helpers ----

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Generic::Information - module to provide information on languages and language specific properties

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use Lingua::Generic::Information;

This module proviles an interface to query language specific values and parameters in a language independent way.

=head1 METHODS

=head2 lookup_language

    my Lingua::Generic::Information::Language $language = Lingua::Generic::Information->lookup_language($idtype => $id);
    # or:
    my Lingua::Generic::Information::Language $language = Lingua::Generic::Information->lookup_language($langtag);
    # or:
    my Lingua::Generic::Information::Language $language = Lingua::Generic::Information->lookup_language($id);
    # e.g.:
    my Lingua::Generic::Information::Language $language = Lingua::Generic::Information->lookup_language('de');

(since v0.01)

Looks up a language.
For details on languages see L<Lingua::Generic::Information::Language>.

This method can be used in one or two argument form.
In one argument form it takes any L<Data::Identifier::Interface::Simple> (such as L<Data::Identifier>)
or an IETF BCP 47 language tag (such as commonly used by HTTP and HTML and many, many more standards).

In two argument form the first parameter C<$idtype> provides the type of C<$id>.
The following types are supported:
C<uuid> (UUID of the language),
C<lti> (IETF BCP 47 language tag),
C<sid> (small-identifier),
C<wd> (Wikidata QID).

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
