package Lingua::Stem::Patch;

use v5.8.1;
use utf8;
use Carp;

use Moo;
use namespace::clean;

our $VERSION = '0.06';

my @languages   = qw( eo io pl );
my %is_language = map { $_ => 1 } @languages;

has language => (
    is       => 'rw',
    isa      => sub { croak "Invalid language '$_[0]'"
                      unless $is_language{$_[0]} },
    coerce   => sub { defined $_[0] ? lc $_[0] : '' },
    trigger  => sub { $_[0]->_clear_stemmer },
    required => 1,
);

has aggressive => (
    is      => 'rw',
    coerce  => sub { !!$_[0] },
    trigger => sub { $_[0]->_clear_stemmer },
    default => 0,
);

has _stemmer => (
    is      => 'rw',
    builder => '_build_stemmer',
    clearer => '_clear_stemmer',
    lazy    => 1,
);

sub _build_stemmer {
    my $self = shift;
    my $language = uc $self->language;
    my $function = 'stem';

    if ($self->aggressive) {
        $function .= '_aggressive';
    }

    require "Lingua/Stem/Patch/$language.pm";
    $self->_stemmer( \&{"Lingua::Stem::Patch::${language}::${function}"} );
}

sub languages {
    return @languages;
}

sub stem {
    my $self = shift;
    my @stems = map { $self->_stemmer->($_) } @_;

    return wantarray ? @stems : pop @stems;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Lingua::Stem::Patch - Patch stemmers for Esperanto and Ido

=head1 VERSION

This document describes Lingua::Stem::Patch v0.06.

=head1 SYNOPSIS

    use Lingua::Stem::Patch;

    # create Esperanto stemmer
    $stemmer = Lingua::Stem::Patch->new(language => 'eo');

    # get stem for word
    $stem = $stemmer->stem($word);

    # get list of stems for list of words
    @stems = $stemmer->stem(@words);

=head1 DESCRIPTION

This module contains a collection of stemmers for multiple languages using the
Patch stemming algorithms. The languages currently implemented are
L<Esperanto|Lingua::Stem::Patch::EO>, L<Ido|Lingua::Stem::Patch::IO>, and
L<Polish|Lingua::Stem::Patch::PL>.

This is a new project under active development and the current stemming
algorithms are likely to change.

=head2 Attributes

=over

=item language

The following language codes are currently supported.

    ┌───────────┬────┐
    │ Esperanto │ eo │
    │ Ido       │ io │
    │ Polish    │ pl │
    └───────────┴────┘

They are in the two-letter ISO 639-1 format and are case-insensitive but are
always returned in lowercase when requested.

    # instantiate a stemmer object
    $stemmer = Lingua::Stem::Patch->new(language => $language);

    # get current language
    $language = $stemmer->language;

    # change language
    $stemmer->language($language);

=item aggressive

By default a light stemmer will be used, but when C<aggressive> is set to true,
an aggressive stemmer will be used instead.

    $stemmer->aggressive(1);

=back

=head2 Methods

=over

=item stem

Accepts a list of words, stems each word, and returns a list of stems. The list
returned will always have the same number of elements in the same order as the
list provided. When no stemming rules apply to a word, the original word is
returned.

    @stems = $stemmer->stem(@words);

    # get the stem for a single word
    $stem = $stemmer->stem($word);

The words should be provided as character strings and the stems are returned as
character strings. Byte strings in arbitrary character encodings are
intentionally not supported.

=item languages

Returns a list of supported two-letter language codes using lowercase letters.

    # object method
    @languages = $stemmer->languages;

    # class method
    @languages = Lingua::Stem::Patch->languages;

=back

=head1 SEE ALSO

L<Lingua::Stem::Any> provides a unified interface to any stemmer on CPAN,
including this module, as well as additional features like normalization,
casefolding, and in-place stemming.

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 COPYRIGHT AND LICENSE

© 2014–2015 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
