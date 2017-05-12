package Lingua::Stem::UniNE::BG;

use v5.8.1;
use utf8;
use strict;
use warnings;
use parent 'Exporter';
use Unicode::CaseFold qw( fc );
use Unicode::Normalize qw( NFC );

our $VERSION   = '0.08';
our @EXPORT_OK = qw( stem stem_bg );

*stem_bg = \&stem;

sub stem {
    my ($word) = @_;

    $word = NFC fc $word;

    my $length = length $word;

    return $word
        if $length < 4;

    if ($length > 5) {
        return $word
            if $word =~ s{ ища $}{}x;
    }

    $word = remove_article($word);
    $word = remove_plural($word);
    $length = length $word;

    if ($length > 3) {
        $word =~ s{ я $}{}x;  # masculine

        # normalization (e.g., -а could be a definite article or plural form)
        $word =~ s{ [аео] $}{}x;

        $length = length $word;
    }

    if ($length > 4) {
        $word =~ s{ е (?= н $) }{}x;  # -ен → -н

        $length = length $word;
    }

    if ($length > 5) {
        $word =~ s{ ъ (?= \p{Cyrl} $) }{}x;  # -ъ� → -�
    }

    return $word;
}

sub remove_article {
    my ($word) = @_;
    my $length = length $word;

    if ($length > 6) {
        # definite article with adjectives and masculine
        return $word
            if $word =~ s{ ият $}{}x;
    }

    if ($length > 5) {
        return $word
            if $word =~ s{ (?:
                  ия  # definite articles for nouns:
                | ът  # ∙ masculine
                | та  # ∙ feminine
                | то  # ∙ neutral
                | те  # ∙ plural
            ) $}{}x;
    }

    if ($length > 4) {
        return $word
            if $word =~ s{ ят $}{}x;  # article for masculine
    }

    return $word;
}

sub remove_plural {
    my ($word) = @_;
    my $length = length $word;

    # specific plural rules for some words (masculine)
    if ($length > 6) {
        return $word
            if $word =~ s{ ове  $}{}x
            || $word =~ s{ еве  $}{й}x
            || $word =~ s{ овци $}{о}x;
    }

    if ($length > 5) {
        return $word
            if $word =~ s{ зи               $}{г}x
            || $word =~ s{ е ( \p{Cyrl} ) и $}{я$1}x  # -е�и → -я�
            || $word =~ s{ ци               $}{к}x
            || $word =~ s{ (?: та | ища )   $}{}x;
    }

    if ($length > 4) {
        return $word
            if $word =~ s{ си $}{х}x
            || $word =~ s{ и  $}{}x;  # plural for various nouns and adjectives
    }

    return $word;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Lingua::Stem::UniNE::BG - Bulgarian stemmer

=head1 VERSION

This document describes Lingua::Stem::UniNE::BG v0.08.

=head1 SYNOPSIS

    use Lingua::Stem::UniNE::BG qw( stem_bg );

    my $stem = stem_bg($word);

    # alternate syntax
    $stem = Lingua::Stem::UniNE::BG::stem($word);

=head1 DESCRIPTION

A stemmer for the Bulgarian language.

This module provides the C<stem> and C<stem_bg> functions, which are synonymous
and can optionally be exported. They accept a single word and return a single
stem.

=head1 SEE ALSO

L<Lingua::Stem::UniNE> provides a stemming object with access to all of the
implemented University of Neuchâtel stemmers including this one. It has
additional features like stemming lists of words.

L<Lingua::Stem::Any> provides a unified interface to any stemmer on CPAN,
including this one, as well as additional features like normalization,
casefolding, and in-place stemming.

This module is based on a stemming algorithm defined in
L<Searching Strategies for the Bulgarian Language|http://dl.acm.org/citation.cfm?id=1298736>
(PDF) by Jacques Savoy of the University of Neuchâtel and implemented in a
L<Perl script|http://members.unine.ch/jacques.savoy/clef/bulgarianStemmer.txt>.

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 COPYRIGHT AND LICENSE

© 2012–2014 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
