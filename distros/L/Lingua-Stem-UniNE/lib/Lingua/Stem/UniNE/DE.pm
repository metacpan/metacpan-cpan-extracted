package Lingua::Stem::UniNE::DE;

use v5.8.1;
use utf8;
use strict;
use warnings;
use parent 'Exporter';
use Unicode::CaseFold qw( fc );
use Unicode::Normalize qw( NFC );

our $VERSION   = '0.08';
our @EXPORT_OK = qw( stem stem_de stem_aggressive stem_de_aggressive );

*stem_de            = \&stem;
*stem_de_aggressive = \&stem_aggressive;

sub stem {
    my ($word) = @_;

    $word = NFC fc $word;
    $word = remove_plural($word);

    return $word;
}

sub stem_aggressive {
    my ($word) = @_;

    $word = NFC fc $word;
    $word = aggressive_diacritic($word);
    $word = aggressive_step1($word);
    $word = aggressive_step2($word);

    return $word;
}

sub remove_plural {
    my ($word) = @_;
    my $length = length $word;

    return $word
        if $length < 5;

    $word = remove_diacritic($word);

    if ($length > 6) {
        return $word
            if $word =~ s{ nen $}{}x;  # -nen
    }

    if ($length > 5) {
        return $word
            if $word =~ s{ (?: e[nrs] | se ) $}{}x;  # -en -er -es -se
    }

    return $word
        if $word =~ s{ [enrs] $}{}x;  # -e -n -r -s

    return $word;
}

sub remove_diacritic {
    my ($word) = @_;

    $word =~ tr{äöü}{aou};

    return $word;
}

sub aggressive_diacritic {
    my ($word) = @_;

    for ($word) {
        #tr{áàâä}{a};
        tr{áàâä}{a};
        tr{íìîï}{i};
        tr{óòôö}{o};
        tr{úùûü}{u};
    }

    return $word;
}

sub aggressive_step1 {
    my ($word) = @_;
    my $length = length $word;

    if ($length > 5) {
        return $word
            if $word =~ s{ ern $}{}x;  # -ern
    }

    if ($length > 4) {
        return $word
            if $word =~ s{ e[mnrs] $}{}x;  # -em -en -er -es
    }

    if ($length > 3) {
        return $word
            if $word =~ s{ e $}{}x;  # -e

        return $word
            if $word =~ s{ (?<= [bdfghklmnt] ) s $}{}x;  # -s
    }

    return $word;
}

sub aggressive_step2 {
    my ($word) = @_;
    my $length = length $word;

    if ($length > 5) {
        return $word
            if $word =~ s{ est $}{}x;  # -est
    }

    if ($length > 4) {
        return $word
            if $word =~ s{ e[nr] $}{}x;  # -en -er

        return $word
            if $word =~ s{ (?<= [bdfghklmnt] ) st $}{}x;  # -st
    }

    return $word;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Lingua::Stem::UniNE::DE - German stemmer

=head1 VERSION

This document describes Lingua::Stem::UniNE::DE v0.08.

=head1 SYNOPSIS

    use Lingua::Stem::UniNE::DE qw( stem_de );

    my $stem = stem_de($word);

    # alternate syntax
    $stem = Lingua::Stem::UniNE::DE::stem($word);

=head1 DESCRIPTION

Light and aggressive stemmers for the German language. The light stemmer removes
plural endings and umlauts. The aggressive stemmer also removes inflectional
suffixes and additional diacritics.

This module provides the C<stem> and C<stem_de> functions for the light stemmer,
which are synonymous and can optionally be exported, plus C<stem_aggressive> and
C<stem_de_aggressive> functions for the light stemmer. They accept a single word
and return a single stem.

=head1 NOTES

“In proposing stemmers for other languages than English, we think that a ‘light’
stemmer (removing inflections only for noun and adjectives) presents some
advantages. […] In German, a few rules may be applied to obtain the plural form
of words (e.g., ‘Frau’ into ‘Frauen’ (woman), ‘Bild’ into ‘Bilder’ (picture),
‘Sohn’ into ‘Söhne’ (son), ‘Apfel’ into ‘Äpfel’ (apple)), but the suggested
algorithms do not account for person and tense variations, or for the
morphological variations used by verbs (we think that indexing verbs for
Italian, French or German is not of primary importance compared to nouns and
adjectives).” —Jacques Savoy, L<IR Multilingual Resources at UniNE
|http://members.unine.ch/jacques.savoy/clef/>

“For the German corpus, Porter’s stemmer provided better retrieval performance
than did the UniNE scheme (average difference of 3.7% over nine IR models). The
difference between these two stemming schemes however was never statistically
significant.” —Jacques Savoy, L<Light Stemming Approaches for the French, Portuguese,
German and Hungarian Languages
|https://doc.rero.ch/record/13225/files/Savoy_Jacques_-_Light_Stemming_Approaches_fo_the_French_20091216.pdf>

=head1 SEE ALSO

L<Lingua::Stem::UniNE> provides a stemming object with access to all of the
implemented University of Neuchâtel stemmers including this one. It has
additional features like stemming lists of words.

L<Lingua::Stem::Any> provides a unified interface to any stemmer on CPAN,
including this one, as well as additional features like normalization,
casefolding, and in-place stemming.

This modules is based on stemming algorithms by Jacques Savoy of the University
of Neuchâtel and implemented in C
(L<light|http://members.unine.ch/jacques.savoy/clef/germanStemmer.txt>,
L<aggressive|http://members.unine.ch/jacques.savoy/clef/germanStemmerPlus.txt>).

=head1 AUTHOR

Nick Patch <patch@cpan.org>

This module is brought to you by L<Shutterstock|http://www.shutterstock.com/>.
Additional open source projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 COPYRIGHT AND LICENSE

© 2014 Shutterstock, Inc.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
