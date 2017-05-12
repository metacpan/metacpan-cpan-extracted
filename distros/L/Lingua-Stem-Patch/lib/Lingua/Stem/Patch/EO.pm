package Lingua::Stem::Patch::EO;

use v5.8.1;
use utf8;
use strict;
use warnings;
use parent 'Exporter';

our $VERSION   = '0.06';
our @EXPORT_OK = qw( stem stem_eo stem_aggressive stem_eo_aggressive );

*stem_eo            = \&stem;
*stem_eo_aggressive = \&stem_aggressive;

my %protect = (
    correlative => { map { $_ => 1 } map {
        my $start = $_;
        map { $start . $_ } qw( a al am e el es o om u )
    } qw( ki ti i ĉi neni ) },
    root => { map { $_ => 1 } qw(
        ĉar ĉi ĉu kaj ke la minus plus se
        ĉe da de el ekster en ĝis je kun na po pri pro sen tra
        ajn do ja jen ju ne pli tamen tre tro
        ci ĝi ili li mi ni oni ri si ŝi ŝli vi
        unu du tri kvin
        ĵus nun plu tuj
        amen bis boj fi ha he ho hu hura nu ve
    ) },
    simple => { map { my $root = $_; map { $root . $_ => 1 } qw( a e i o ) } qw(
        abrikot absint arogant artrit azot balustrad bant bat biskvit blat boat
        bot briliant cit ĉokolad dat degrad delikat diamant diskont dorlot dot
        ekscit elefant ermit etat evit flat font frat front frot gad gant genot
        glad glat glit grad granat granit grat grenad grot hepat hipokrit hont
        horizont imit incit iniciat intermit invit kalikot kamlot kant kapot
        karot kat klimat komitat kompat konfit konsonant konstant konstat
        kontant kot krad kravat kvant kvit lad lekant leŭtenant limonad lit lot
        markot marmot mat medit merit milit miozot monat mont muskat not oblat
        palat parad parazit pat perlamot pilot pint pirit plad plant plat plot
        pont pot predikat privat profit rabat rabot rad rakont rat renkont rilat
        rot sabat salat sat ŝat skarlat soldat spat spirit spit sprit stat ŝtat
        strat subit sublimat svat ŝvit terebint tint trikot trot universitat
        vant vat vizit volont zenit
        almilit bofrat ciferplat esperant malŝat manplat
    ) },
);

sub stem {
    my $word = lc shift;

    for ($word) {
        # standalone roots
        last if $protect{root}{$word};

        # l’ l' → la
        last if s{ (?<= ^ l ) [’'] $}{a}x;

        # un’ un' unuj → unu
        last if s{ (?<= ^ un  ) [’'] $}{u}x;
        last if s{ (?<= ^ unu ) j    $}{}x;

        # -’ -' → -o
        s{ [’'] $}{o}x;

        # ’st- 'st- → est-
        s{^ [’'] (?= st (?: [aiou] s | [iu] ) $ ) }{e}x;

        # nouns, adjectives, -u correlatives:
        # -oj -on -ojn → o
        # -aj -an -ajn → a
        # -uj -un -ujn → u
        s{ (?<= [aou] ) (?: [jn] | jn ) $}{}x;

        # correlatives: -en → -e
        s{^ ( (?: [ĉkt] | nen )? ie ) n $}{$1}x;

        # correlative roots
        last if $protect{correlative}{$word};

        # accusative pronouns: -in → -i
        last if s{ (?<= i ) n $}{}x;

        # accusative adverbs: -en → -o
        s{ en $}{o}x;

        # verbs: -is -as -os -us -u → -i
        s{ (?: [aiou] s | u ) $}{i}x;

        # lexical aspect: ek- el-
        s{^ ek (?! scit  ) }{}x;
        s{^ el (?! efant ) }{}x;

        # simple words: root plus single suffix
        last if $protect{simple}{$word};

        # imperfective verbs & action nouns: -adi -ado → -i
        last if s{ ad [io] $}{i}x;

        # compound verbs:
        # -inti -anti -onti -iti -ati -oti → -i
        # -inte -ante -onte -ite -ate -ote → -i
        # -inta -anta -onta -ita -ata -ota → -i
        last if s{ (?: [aio] n? t ) [aei] $}{i}x;

        # participle nouns:
        # -into -anto -onto → -anto
        # -ito  -ato  -oto  → -ato
        last if s{ [aio] ( n? ) to $}{a$1to}x;
    }

    return $word;
}

sub stem_aggressive {
    my $word = stem(shift);
    my $copy = $word;

    for ($word) {
        # protected words
        last if $protect{root}{$word}
             || $protect{correlative}{$word};

        # remove final suffix
        s{ [aeio] $}{}x;

        last if $protect{simple}{$copy};

        # remove suffix for participle nouns:
        # -int- -ant- -ont- -it- -at- -ot-
        s{ [aio] n? t $}{}x;
    }

    return $word;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Lingua::Stem::Patch::EO - Esperanto stemmer

=head1 VERSION

This document describes Lingua::Stem::Patch::EO v0.06.

=head1 SYNOPSIS

    use Lingua::Stem::Patch::EO qw( stem_eo );

    $stem = stem_eo($word);

    # alternate syntax
    $stem = Lingua::Stem::Patch::EO::stem($word);

=head1 DESCRIPTION

Light and aggressive stemmers for the universal language Esperanto. This is a
new project under active development and the current stemming algorithm is
likely to change.

This module provides the C<stem> and C<stem_eo> functions for the light stemmer,
which are synonymous and can optionally be exported, plus C<stem_aggressive> and
C<stem_eo_aggressive> functions for the aggressive stemmer. They accept a
character string for a word and return a character string for its stem.

=head1 SEE ALSO

L<Lingua::Stem::Patch> provides a stemming object with access to all of the
Patch stemmers including this one. It has additional features like stemming
lists of words.

L<Lingua::Stem::Any> provides a unified interface to any stemmer on CPAN,
including this one, as well as additional features like normalization,
casefolding, and in-place stemming.

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 COPYRIGHT AND LICENSE

© 2014–2015 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
