package Lingua::Stem::UniNE::CS;

use v5.8.1;
use utf8;
use strict;
use warnings;
use parent 'Exporter';
use Unicode::CaseFold qw( fc );
use Unicode::Normalize qw( NFC );

our $VERSION   = '0.08';
our @EXPORT_OK = qw( stem stem_cs stem_aggressive stem_cs_aggressive );

*stem_cs            = \&stem;
*stem_cs_aggressive = \&stem_aggressive;

sub stem {
    my ($word) = @_;

    $word = NFC fc $word;
    $word = remove_case($word);
    $word = remove_possessive($word);

    return $word;
}

sub stem_aggressive {
    my ($word) = @_;

    $word = NFC fc $word;
    $word = remove_case($word);
    $word = remove_possessive($word);
    $word = remove_comparative($word);
    $word = remove_diminutive($word);
    $word = remove_augmentative($word);
    $word = remove_derivational($word);

    return $word;
}

# remove grammatical case endings from nouns and adjectives
sub remove_case {
    my ($word) = @_;
    my $length = length $word;

    if ($length > 7) {
        return $word
            if $word =~ s{ atech $}{}x;
    }

    if ($length > 6) {
        return $word
            if $word =~ s{ atům $}{}x;

        return palatalize($word)
            if $word =~ s{ (?<= ě ) tem $}{}x;  # -ětem → -ě
    }

    if ($length > 5) {
        return $word
            if $word =~ s{ (?:
                  ými     # -ými
                | am[ai]  # -ama -ami
                | at[ay]  # -ata -aty
                | ov[éi]  # -ové -ovi
                | [áý]ch  # -ách -ých
            ) $}{}x;

        return palatalize($word)
            if $word =~ s{ (?:
                  (?<= [eě]  ) t[ei]  # -ete -eti -ěte -ěti → -e -ě
                | (?<= [éi]  ) mu     # -ému -imu           → -é -i
                | (?<= [eií] ) ch     # -ech -ich -ích      → -e -i -í
                | (?<= [eěí] ) mi     # -emi -ěmi -ími      → -e -ě -í
                | (?<= [éií] ) ho     # -ého -iho -ího      → -é -i -í
            ) $}{}x;
    }

    if ($length > 4) {
        return $word
            if $word =~ s{ (?:
                  at      # -at
                | mi      # -mi
                | us      # -us
                | o[su]   # -os -ou
                | [áůý]m  # -ám -ům -ým
            ) $}{}x;

        return palatalize($word)
            if $word =~ s{ (?:
                  es          # -es
                | [éí]m       # -ém -ím
                | (?<= e ) m  # -em → -e
            ) $}{}x;
    }

    if ($length > 3) {
        return $word
            if $word =~ s{ [aáéouůyý] $}{}x;

        return palatalize($word)
            if $word =~ m{ [eěií] $}x;
    }

    return $word;
}

# remove possesive endings from names
sub remove_possessive {
    my ($word) = @_;

    return $word
        if length $word < 6;

    return $word
        if $word =~ s{ [oů]v $}{}x;  # -ov -ův

    return palatalize($word)
        if $word =~ s{ (?<= i ) n $}{}x;  # -in → -i

    return $word;
}

sub remove_comparative {
    my ($word) = @_;

    return $word
        if length $word < 6;

    return palatalize($word)
        if $word =~ s{ (?<= [eě] ) jš $}{}x;  # -ejš -ějš → -e -ě

    return $word;
}

sub remove_diminutive {
    my ($word) = @_;
    my $length = length $word;

    if ($length > 7) {
        return $word
            if $word =~ s{ oušek $}{}x;
    }

    if ($length > 6) {
        # -aček -áček -anek -ánek -oček -onek -uček -unek
        return $word
            if $word =~ s{ [aáou][čn]ek $}{}x;

        # -eček -éček -enek -ének -iček -íček -inek -ínek → -e -é -i -í
        return palatalize($word)
            if $word =~ s{ (?<= [eéií] ) [čn]ek $}{}x;
    }

    if ($length > 5) {
        # -ačk -áčk -ank -ánk -átk -očk -onk -učk -unk -ušk
        return $word
            if $word =~ s{ (?: [aáou][čn] | át | uš ) k $}{}x;

        # -ečk -éčk -enk -énk -ičk -íčk -ink -ínk
        return palatalize($word)
            if $word =~ s{ [eéií][čn]k $}{}x;
    }

    if ($length > 4) {
        # -ak -ák -ok -uk → -a -á -o -u
        return $word
            if $word =~ s{ (?<= [aáou] ) k $}{}x;

        # -ek -ék -ik -ík → -e -é -i -í
        return palatalize($word)
            if $word =~ s{ (?<= [eéií] ) k $}{}x;
    }

    if ($length > 3) {
        return $word
            if $word =~ s{ k $}{}x;
    }

    return $word;
}

sub remove_augmentative {
    my ($word) = @_;
    my $length = length $word;

    if ($length > 6) {
        return $word
            if $word =~ s{ ajzn $}{}x;
    }

    if ($length > 5) {
        return palatalize($word)
            if $word =~ s{ (?<= i ) (?: sk | zn ) $}{}x;  # -isk -izn → -i
    }

    if ($length > 4) {
        return $word
            if $word =~ s{ ák $}{}x;
    }

    return $word;
}

sub remove_derivational {
    my ($word) = @_;
    my $length = length $word;

    if ($length > 8) {
        return $word
            if $word =~ s{ obinec $}{}x;
    }

    if ($length > 7) {
        # -ovisk -ovišt -ovník -ovstv
        return $word
            if $word =~ s{ ov (?: isk | išt | ník | stv ) $}{}x;

        # -ionář → -i
        return palatalize($word)
            if $word =~ s{ (?<= i ) onář $}{}x;
    }

    if ($length > 6) {
        return $word
            if $word =~ s{ (?:
                ásek | loun | nost | štin | teln |
                ov (?: ec | ík | in | tv )  # -ovec -ovík -ovin -ovtv
            ) $}{}x;

        # -enic -inec -itel → -e -i
        return palatalize($word)
            if $word =~ s{ (?: (?<= e ) nic | (?<= i ) (?: nec | tel ) ) $}{}x;
    }

    if ($length > 5) {
        return $word
            if $word =~ s{ árn $}{}x;

        return palatalize($word)
            if $word =~ s{ (?<= ě ) nk $}{}x;  # -ěnk → -ě

        # -ián -isk -ist -išt -itb → -i -í
        return palatalize($word)
            if $word =~ s{ (?<= i ) (?: án | sk | st | št | tb ) $}{}x;

        # -írn → -í
        return palatalize($word)
            if $word =~ s{ (?<= í ) rn $}{}x;

        # -och -ost -oun -ouš -out -ovn
        return $word
            if $word =~ s{ o (?: ch | st | un | uš | ut | vn ) $}{}x;

        return $word
            if $word =~ s{ (?:
                čan | ctv | kář | kyn | néř | ník | stv | ušk
            ) $}{}x;
    }

    if ($length > 4) {
        # -ač -áč -an -án -ář -as
        return $word
            if $word =~ s{ (?: a[čns] | á[čnř] ) $}{}x;

        # -ec -en -ěn -éř -ic -in -it -iv -ín -íř → -e -ě -é -i -í
        return palatalize($word)
            if $word =~ s{ (?:
                  (?<= e ) [cn]
                | (?<= ě ) n
                | (?<= é ) ř
                | (?<= i ) [cntv]
                | (?<= í ) [nř]
            ) $}{}x;

        # -čk -čn -dl -nk -ob -oň -ot -ov -tk -tv -ul -vk -yn
        return $word
            if $word =~ s{ (?:
                č[kn] | o[bňtv] | t[kv] | [du]l | [nv]k | yn
            ) $}{}x;
    }

    if ($length > 3) {
        return $word
            if $word =~ s{ [cčklnt] $}{}x;
    }

    return $word;
}

sub palatalize {
    my ($word) = @_;

    return $word
        if $word =~ s{ čt[ěií]  $}{ck}x  # -čtě -čti -čtí  → -ck
        || $word =~ s{ št[ěií]  $}{sk}x  # -ště -šti -ští  → -sk
        || $word =~ s{ [cč][ei] $}{k}x   # -ce -ci -če -či → -k
        || $word =~ s{ [zž][ei] $}{h}x;  # -ze -zi -že -ži → -h

    chop $word;

    return $word;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Lingua::Stem::UniNE::CS - Czech stemmer

=head1 VERSION

This document describes Lingua::Stem::UniNE::CS v0.08.

=head1 SYNOPSIS

    use Lingua::Stem::UniNE::CS qw( stem_cs stem_cs_aggressive );

    $stem = stem_cs($word);
    $stem = stem_cs_aggressive($word);

    # alternate syntax
    $stem = Lingua::Stem::UniNE::CS::stem($word);
    $stem = Lingua::Stem::UniNE::CS::stem_aggressive($word);

=head1 DESCRIPTION

Light and aggressive stemmers for the Czech language. The light stemmer removes
grammatical case endings from nouns and adjectives, possessive adjective endings
from names, and takes care of palatalization. The aggressive stemmer also
removes diminutive, augmentative, and comparative suffixes and derivational
suffixes from nouns.

This module provides the C<stem> and C<stem_cs> functions for the light stemmer,
which are synonymous and can optionally be exported, plus C<stem_aggressive> and
C<stem_cs_aggressive> functions for the light stemmer. They accept a single word
and return a single stem.

=head1 SEE ALSO

L<Lingua::Stem::UniNE> provides a stemming object with access to all of the
implemented University of Neuchâtel stemmers including this one. It has
additional features like stemming lists of words.

L<Lingua::Stem::Any> provides a unified interface to any stemmer on CPAN,
including this one, as well as additional features like normalization,
casefolding, and in-place stemming.

A L<Czech stemmer for Snowball|http://snowball.tartarus.org/otherapps/oregan/intro.html>
by Jimmy O’Regan is available on the Snowball site but not included in the
official distribution and therefore not included in L<Lingua::Stem::Snowball>.

This module is based on a stemming algorithm defined in
L<Indexing and stemming approaches for the Czech language|http://dl.acm.org/citation.cfm?id=1598600>
(PDF) by Ljiljana Dolamic and Jacques Savoy of the University of Neuchâtel and
implemented by Ljiljana Dolamic in
L<Java|http://members.unine.ch/jacques.savoy/clef/CzechStemmerLight.txt>.

=head1 AUTHOR

Nick Patch <patch@cpan.org>

This module is brought to you by L<Shutterstock|http://www.shutterstock.com/>.
Additional open source projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 COPYRIGHT AND LICENSE

© 2012–2014 Shutterstock, Inc.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
