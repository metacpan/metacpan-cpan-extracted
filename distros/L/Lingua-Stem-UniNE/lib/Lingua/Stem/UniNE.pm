package Lingua::Stem::UniNE;

use v5.8.1;
use utf8;
use Carp;

use Moo;
use namespace::clean;

our $VERSION = '0.08';

my @languages  = qw( bg cs de fa );
my @aggressive = qw( cs de );

my %is_language    = map { $_ => 1 } @languages;
my %has_aggressive = map { $_ => 1 } @aggressive;

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

    if ($self->aggressive && $has_aggressive{$self->language}) {
        $function .= '_aggressive';
    }

    require "Lingua/Stem/UniNE/$language.pm";
    $self->_stemmer( \&{"Lingua::Stem::UniNE::${language}::${function}"} );
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

Lingua::Stem::UniNE - University of Neuchâtel stemmers

=head1 VERSION

This document describes Lingua::Stem::UniNE v0.08.

=head1 SYNOPSIS

    use Lingua::Stem::UniNE;

    # create Bulgarian stemmer
    $stemmer = Lingua::Stem::UniNE->new(language => 'bg');

    # get stem for word
    $stem = $stemmer->stem($word);

    # get list of stems for list of words
    @stems = $stemmer->stem(@words);

=head1 DESCRIPTION

This module contains a collection of stemmers for multiple languages based on
stemming algorithms provided by Jacques Savoy of the University of Neuchâtel
(UniNE). The languages currently implemented are
L<Bulgarian|Lingua::Stem::UniNE::BG>, L<Czech|Lingua::Stem::UniNE::CS>,
L<German|Lingua::Stem::UniNE::DE>, and L<Persian|Lingua::Stem::UniNE::FA>. Work
is ongoing for Arabic, Bengali, Finnish, French, Hindi, Hungarian, Italian,
Portuguese, Marathi, Russian, Spanish, and Swedish. The top priority is
languages for which there are no stemmers available on CPAN.

=head2 Attributes

=over

=item language

The following language codes are currently supported.

    ┌───────────┬────┐
    │ Bulgarian │ bg │
    │ Czech     │ cs │
    │ German    │ de │
    │ Persian   │ fa │
    └───────────┴────┘

They are in the two-letter ISO 639-1 format and are case-insensitive but are
always returned in lowercase when requested.

    # instantiate a stemmer object
    $stemmer = Lingua::Stem::UniNE->new(language => $language);

    # get current language
    $language = $stemmer->language;

    # change language
    $stemmer->language($language);

Country codes such as C<cz> for the Czech Republic are not supported, nor are
IETF language tags such as C<fa-AF> or C<fa-IR>.

=item aggressive

By default, if there are multiple strengths of stemmers, a light stemmer will be
used. When C<aggressive> is set to true, an aggressive stemmer will be used if
available.

    $stemmer->aggressive(1);

Czech and German have aggressive options.

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
    @languages = Lingua::Stem::UniNE->languages;

=back

=head1 SEE ALSO

L<Lingua::Stem::Any> provides a unified interface to any stemmer on CPAN,
including this module, as well as additional features like normalization,
casefolding, and in-place stemming.

L<Lingua::Stem::Snowball> provides alternate stemming algorithms for Finnish,
French, German, Hungarian, Italian, Portuguese, Russian, Spanish, and Swedish,
as well as other languages.

These stemming algorithms are based on definition and implementations by Jacques
Savoy and Ljiljana Dolamic of the University of Neuchâtel and provided at
L<IR Multilingual Resources at UniNE|http://members.unine.ch/jacques.savoy/clef/>.

=head1 AUTHOR

Nick Patch <patch@cpan.org>

This project is brought to you by L<Shutterstock|http://www.shutterstock.com/>.
Additional open source projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 COPYRIGHT AND LICENSE

© 2012–2014 Shutterstock, Inc.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
