package Lingua::Stem::Patch::PL;

use v5.8.1;
use utf8;
use strict;
use warnings;
use parent 'Exporter';

our $VERSION   = '0.06';
our @EXPORT_OK = qw( stem stem_pl );

*stem_pl = \&stem;

sub stem {
    my $word = lc shift;

    $word = remove_noun($word);
    $word = remove_diminutive($word);
    $word = remove_adjective($word);
    $word = remove_verb($word);
    $word = remove_adverb($word);
    $word = remove_plural($word);
    $word = remove_other($word);

    return $word;
}

sub remove_noun {
    my ($word) = @_;
    my $length = length $word;

    if ($length > 6) {
        return $word if $word =~ s{ (?:
            tach
            | acj[aąi]      # -acja -acją -acji
            | [ae]ni[eu]    # -anie -aniu -enie -eniu
            | (?<= ty ) ka  # -tyka → -ty
        ) $}{}x;
    }

    if ($length > 5) {
        return $word if $word =~ s{ (?:
            ach | ami | ce | ta
            | [cn]i[au]        # -cia -ciu -nia -niu
            | (?<= c ) j[aąi]  # -cja -cją -cji → -c
        ) $}{}x;
    }

    return $word;
}

sub remove_diminutive {
    my ($word) = @_;
    my $length = length $word;

    if ($length > 6) {
        return $word if $word =~ s{ (?:
            (?: [aiu]s | [ei]c ) zek  # -aszek -eczek -iczek -iszek -uszek
            | (?<= e[jnr] ) ek        # -ejek -enek -erek → -ej -en -er
        ) $}{}x;
    }

    if ($length > 4) {
        return $word if $word =~ s{
            [ae]k  # -ak -ek
        $}{}x;
    }

    return $word;
}

sub remove_adjective {
    my ($word) = @_;
    my $length = length $word;

    if ($length > 7) {
        return $1 if $word =~ m{^
            naj                  # naj-
            ( .+ )               # $1
            sz (?: [ey] | ych )  # -sze -szy -szych
        $}x;
    }

    if ($length > 6) {
        return $word
            if $word =~ s{ czny $}{}x;
    }

    if ($length > 5) {
        return $word if $word =~ s{ (?:
            ego | ej | ych
            | ow[aey]  # -owa -owe -owy
        ) $}{}x;
    }

    return $word;
}

sub remove_verb {
    my ($word) = @_;
    my $length = length $word;

    if ($length > 5) {
        return $word if $word =~ s{ (?:
            bym | cie | łem
            | [ae] (?: my | sz | ść )  # -amy -emy -asz -esz -aść -eść
        ) $}{}x;
    }

    if ($length > 3) {
        return $word if $word =~ s{ (?:
            ąc
            | a[ćmł]                     # -ać -am -ał
            | e[ćm]                      # -eć -em
            | i[ćł]                      # -ić -ił
            | (?<= a    ) j              # -aj                 → -a
            | (?<= [ae] ) (?: sz | ść )  # -asz -aść -esz -eść → -a -e
        ) $}{}x;
    }

    return $word;
}

sub remove_adverb {
    my ($word) = @_;
    my $length = length $word;

    if ($length > 4) {
        return $word if $word =~ s{ (?:
              (?<= r    ) ze  # -rze      → -r
            | (?<= [nw] ) ie  # -nie -wie → -n -w
        ) $}{}x;
    }

    return $word;
}

sub remove_plural {
    my ($word) = @_;
    my $length = length $word;

    if ($length > 4) {
        return $word if $word =~ s{ (?:
            ami | om | ów
        ) $}{}x;
    }

    return $word;
}

sub remove_other {
    my ($word) = @_;
    my $length = length $word;

    if ($length > 4) {
        return $word if $word =~ s{
            i[ae]  # -ia -ie
        $}{}x;
    }

    if ($length > 3) {
        return $word
            if $word =~ s{ [aąęiłuy] $}{}x;
    }

    return $word;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Lingua::Stem::Patch::PL - Polish stemmer

=head1 VERSION

This document describes Lingua::Stem::Patch::PL v0.06.

=head1 SYNOPSIS

    use Lingua::Stem::Patch::PL qw( stem_pl );

    $stem = stem_pl($word);

    # alternate syntax
    $stem = Lingua::Stem::Patch::PL::stem($word);

=head1 DESCRIPTION

A stemmer for the Polish language.

This module provides the C<stem> and C<stem_pl> functions for the light stemmer,
which are synonymous and can optionally be exported. They accept a character
string for a word and return a character string for its stem.

=head1 SEE ALSO

L<Lingua::Stem::Patch> provides a stemming object with access to all of the
Patch stemmers including this one. It has additional features like stemming
lists of words.

L<Lingua::Stem::Any> provides a unified interface to any stemmer on CPAN,
including this one, as well as additional features like normalization,
casefolding, and in-place stemming.

This module is based on a stemming algorithm by Błażej Kubiński and implemented
in a L<Python script|https://github.com/Tutanchamon/pl_stemmer>.

=head1 AUTHOR

Nick Patch <patch@cpan.org>

This module is brought to you by L<Shutterstock|http://www.shutterstock.com/>.
Additional open source projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 COPYRIGHT AND LICENSE

© 2014–2015 Shutterstock, Inc.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
