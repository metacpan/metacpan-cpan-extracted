use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 448;
use Lingua::Stem::Patch::EO qw( stem stem_aggressive );

sub is_stem {
    my ($word, $stem, $description) = @_;

    is stem($word),            $stem, "$description (light)";
    is stem_aggressive($word), $stem, "$description (aggressive)";
}

# standalone roots
for my $word (qw{
    adiaŭ ajn al almenaŭ ambaŭ amen ankaŭ ankoraŭ anstataŭ antaŭ apenaŭ apud aŭ
    baldaŭ bis boj ĉar ĉe cent ĉi ĉirkaŭ ĉu da de dek des do du dum eĉ ekster el
    en fi for ĝis ha he hieraŭ ho hodiaŭ hu hura ja jam je jen jes ju ĵus kaj ke
    kontraŭ krom kun kvankam kvar kvazaŭ kvin la laŭ malgraŭ mem mil minus
    morgaŭ na naŭ ne nek nu nul nun nur ok ol per plej pli plu plus po por post
    preskaŭ preter pri pro se sed sen sep ses sub super sur tamen tra trans tre
    tri tro tuj unu ve
}) {
    is_stem($word, $word, 'protected root');
}

# pronouns
for my $word (qw{ ci ĝi ili li mi ni oni ri si ŝi ŝli vi }) {
    is_stem($word,       $word, 'preposition');
    is_stem($word . 'n', $word, 'accusative preposition');
}

# correlatives
for my $start (qw{ ki ti i ĉi neni }) {
    for my $end (qw{ a al am e el es o om u }) {
        my $word = $start . $end;
        is_stem($word, $word, "correlative: $word");

        if ($end eq 'a' || $end eq 'o' || $end eq 'u') {
            is_stem($word . 'j',  $word, "correlative: -${end}j");
            is_stem($word . 'n',  $word, "correlative: -${end}n");
            is_stem($word . 'jn', $word, "correlative: -${end}jn");
        }
        elsif ($end eq 'e') {
            is_stem($word . 'n', $word, 'correlative: -en');
        }
    }
}
