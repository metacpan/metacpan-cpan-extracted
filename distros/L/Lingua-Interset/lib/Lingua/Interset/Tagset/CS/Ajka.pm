# ABSTRACT: Driver for the tagset of the Czech morphological analyzers Ajka and Majka (Masaryk University in Brno).
# This driver is for version 1.0 of the tagset (still produced by Majka downloaded in July 2014).
# For more on Ajka, see http://nlp.fi.muni.cz/projekty/ajka/ajkacz.htm
# For more on the tagset, see http://nlp.fi.muni.cz/projekty/ajka/tags.pdf
# For more on versions 1.0 and 2.0, see http://raslan2011.nlp-consulting.net/program/paper05.pdf?attredirects=0
# Copyright © 2009, 2014, 2017 Petr Pořízka, Markus Schäfer, Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::CS::Ajka;
use strict;
use warnings;
our $VERSION = '3.004';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset';



has 'atoms'       => ( isa => 'HashRef', is => 'ro', builder => '_create_atoms',       lazy => 1 );



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'cs::ajka';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # PART OF SPEECH ####################
    $atoms{k} = $self->create_atom
    (
        'tagset' => 'cs::ajka',
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # noun
            # examples: pán, hrad, žena, růže, město, moře
            'k1' => ['pos' => 'noun'],
            # adjective
            # examples: mladý, jarní
            'k2' => ['pos' => 'adj'],
            # pronoun
            # examples: já, ty, on, ona, ono, my, vy, oni, ony
            'k3' => ['pos' => 'noun|adj', 'prontype' => 'prn'],
            # numeral
            # examples: jeden, dva, tři, čtyři, pět, šest, sedm, osm, devět, deset
            'k4' => ['pos' => 'num'],
            # verb
            # examples: nese, bere, maže, peče, umře, tiskne, mine, začne, kryje, kupuje, prosí, trpí, sází, dělá
            'k5' => ['pos' => 'verb'],
            # adverb
            # examples: kde, kam, kdy, jak, dnes, vesele
            'k6' => ['pos' => 'adv'],
            # adposition
            # examples: v, pod, k
            'k7' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # conjunction
            # examples: a, i, ani, nebo, ale, avšak
            'k8' => ['pos' => 'conj'],
            # particle
            # examples: ať, kéž, nechť
            'k9' => ['pos' => 'part'],
            # interjection
            # examples: haf, bum, bác
            'k0' => ['pos' => 'int'],
            # abbreviation
            # examples: atd., apod.
            'kA' => ['abbr' => 'abbr'],
            # separate class for "by", "aby", "kdyby" and their inflected forms
            # "by" is a form of the auxiliary verb "být" (to be), used together with participle of a main verb, to create conditional (e.g. "dělal by")
            # "aby" is a subordinating conjunction derived from "by" and meaning "so that". It inflects for person and number of the subject of the subordinate clause.
            # "kdyby" is a subordinating conjunction derived from "by" and meaning "if". It inflects for person and number of the subject of the subordinate clause.
            'kY' => ['pos' => 'conj', 'conjtype' => 'sub', 'verbtype' => 'aux', 'mood' => 'cnd']
        },
        'encode_map' =>

             { 'abbr' => { 'abbr' => 'kA',
                           '@'    => { 'numtype' => { '' => { 'prontype' => { ''  => { 'pos' => { 'noun' => 'k1',
                                                                                                  'adj'  => 'k2',
                                                                                                  'num'  => 'k4',
                                                                                                  'verb' => 'k5',
                                                                                                  'adv'  => 'k6',
                                                                                                  'adp'  => 'k7',
                                                                                                  'conj' => { 'mood' => { 'cnd' => 'kY',
                                                                                                                          '@'   => 'k8' }},
                                                                                                  'part' => 'k9',
                                                                                                  'int'  => 'k0' }},
                                                                              '@' => { 'pos' => { 'num' => 'k4',
                                                                                                  'adv' => 'k6',
                                                                                                  '@'   => 'k3' }}}},
                                                      '@' => 'k4' }}}}
    );
    # SUBCLASS X ####################
    # The same value has different meaning depending on part of speech (the 'k' attribute).
    # For example, k3xO means "possessive pronoun" but k4xO means "ordinal number".
    # Thus we have to define separate atom for every part of speech.
    $atoms{xk1} = $self->create_atom
    (
        'surfeature' => 'xtype_noun',
        'decode_map' =>
        {
            # Special paradigm: "půl"
            # This feature applies to nouns even though one may argue that "půl" is numeral.
            # There is no corresponding feature in Interset.
            # We could use the 'other' feature but we do not need it because we can recognize this tag by empty values of gender, number and case.
            'xP' => []
        },
        'encode_map' =>

            { 'gender' => { '' => { 'number' => { '' => { 'case' => { '' => 'xP' }}}}}}
    );
    $atoms{xk3} = $self->create_atom
    (
        'surfeature' => 'xtype_pronoun',
        'decode_map' =>
        {
            # Personal pronoun. Note that xP also occurs with nouns where it means something else.
            # Examples: já, ty, on, ona, ono, my, vy, oni, ony, se
            'xP' => ['prontype' => 'prs'],
            # Possessive pronoun.
            # Unlike in the PDT tagset, possessiveness is taken broader and there are also interrogative possessive pronouns ("čí").
            # We assign prontype=prs here but we hope that it will be later overwritten by the y-type if necessary.
            ###!!! THIS IS DANGEROUS! Despite the canonical ordering, Majka (Brno) tags are defined as non-positional and we are not guaranteed that 'y' will not precede 'x'!
            ###!!! However, the 'y' type will not tell us that this is a "personal possessive". We will not have another chance to set prontype=prs.
            ###!!! We would have to give up decode_map and use Perl code instead (prontype = prs if prontype eq '' || prontype eq 'prn').
            # Personal possessive pronouns: můj, tvůj, jeho, její, náš, váš, jejich
            # Reflexive possessive pronouns: svůj
            # Interrogative and relative possessive pronouns: čí
            # Relative possessive pronouns: jehož, jejíž, jejichž
            # Indefinite possessive pronouns: něčí, číkoli, čísi
            # Negative possessive pronouns: ničí
            'xO' => ['prontype' => 'prs', 'poss' => 'poss'],
            # Demonstrative pronoun.
            # Examples: ten, tento, tenhle, tenž, tenže, onen, takový, takovýhle, takovýto
            'xD' => ['prontype' => 'dem'],
            # Delimiting pronoun (vymezovací zájmeno) is a class similar to totality pronouns in other tagsets.
            # Examples: každý, samý, sám, tentýž, týž, veškerý, všecek, všechen
            'xT' => ['prontype' => 'tot']
        },
        'encode_map' =>

            { 'poss' => { 'poss' => 'xO',
                          '@'    => { 'prontype' => { 'prs' => 'xP',
                                                      'dem' => 'xD',
                                                      'tot' => 'xT' }}}}
    );
    $atoms{xk4} = $self->create_atom
    (
        'surfeature' => 'xtype_numeral',
        'decode_map' =>
        {
            # Note that a few indefinite (cardinal) numerals have neither x- nor y-type.
            # Examples: mnoho, málo, pramálo
            # Cardinal number.
            # Examples: nula, jeden, nejeden, dva, oba, pár, tři, čtyři, pět, šest, sedm, osm, šestnáct, devatenáct, miliarda
            'xC' => ['numtype' => 'card'],
            # Ordinal number.
            # (Note that xO also exists with pronouns where it means "possessive pronoun".)
            # It also includes adverbial ordinal numbers that can be recognized by lack of gender, number and case.
            # Examples: prvý, šestnáctý, osmdesátý, stý, tisící, několikátý
            # Adverbial examples: zaprvé, zadruhé, popáté, poosmé, pojedenácté
            'xO' => ['numtype' => 'ord', 'pos' => 'adj|adv'],
            # Generic numeral.
            # Examples: dvoje, dvojí, oboje, obojí, troje, trojí, několikerý
            'xR' => ['numtype' => 'sets|mult', 'pos' => 'adj'],
            # Demonstrative numeral.
            # Examples: tolik
            # ("tolik" could be described as demonstrative cardinal numeral.
            # Note that there could be also demonstrative ordinal numerals ("tolikátý", "potolikáté") or generic ("tolikerý")
            # but the current version of Majka does not know them.)
            'xD' => ['numtype' => 'card', 'prontype' => 'dem'],
            # Numeral types xG and xH appear in documentation with the brief note "gramatika".
            # They do not appear in the lexical database and in the output of Majka.
            'xG' => [],
            'xH' => []
        },
        'encode_map' =>

            { 'prontype' => { 'dem' => 'xD',
                              '@'   => { 'numtype' => { 'card' => 'xC',
                                                        'ord'  => 'xO',
                                                        'sets' => 'xR',
                                                        'mult' => 'xR' }}}}
    );
    $atoms{xk6} = $self->create_atom
    (
        'surfeature' => 'xtype_pronominal_adverb',
        'decode_map' =>
        {
            # Demonstrative adverb.
            # Examples: odtud, potud, odsud, tam, tu, tuhle, odtamtud, onde, tady, tak, takhle, takto, takž, natolik, doposavad, doposud, dosud, tehdy, sem, teď, zde
            'xD' => ['prontype' => 'dem'],
            # Delimiting adverb (vymezovací příslovce) is a class similar to totality pronouns/adverbs in other tagsets.
            # Examples: pokaždé, tamtéž, všude, všudy, vždy, vždycky
            'xT' => ['prontype' => 'tot'],
            # Adverb x-types xM and xS appear in documentation but not in the lexical database and in the output of Majka.
            # These two subclasses actually exist but they are distinguished using the "t" attribute.
            'xM' => [], # manner adverb (příslovce způsobu)
            'xS' => []  # state adverb (stavové příslovce)
        },
        'encode_map' =>

            { 'prontype' => { 'dem' => 'xD',
                              'tot' => 'xT' }}
    );
    $atoms{xk8} = $self->create_simple_atom
    (
        'intfeature' => 'conjtype',
        'simple_decode_map' =>
        {
            'xC' => 'coor',
            'xS' => 'sub'
        }
    );
    # SUBCLASS Y ####################
    # The remaining (pronominal) subclasses of pronouns, numerals and adverbs, sometimes orthogonal to x-types (that's why they are a separate feature).
    # Unlike x-types, the values of y-types have the same meaning regardless of the main part of speech.
    $atoms{y} = $self->create_atom
    (
        'surfeature' => 'ytype',
        'decode_map' =>
        {
            # Reflexive pronoun.
            # Examples of reflexive personal pronouns: sebe, sobě, si, se, sebou
            # Examples of reflexive possessive pronouns: svůj, svá, své, sví
            'yF' => ['prontype' => 'prs', 'reflex' => 'reflex'],
            # Interrogative pronoun, numeral or adverb.
            # Pronoun examples: kdo, kdopak, co, copak, což, cožpak, cože, jaký, jakýpak, který, čí
            # Numeral examples: kolik
            # Adverb examples:  kde, kdy, jak, cože, pokud, proč, co, kterak
            'yQ' => ['prontype' => 'int'],
            # Relative pronoun, numeral or adverb.
            # Pronoun examples: kdo, kdož, co, což, jaký, který, čí, jenž, jenžto, jehož, jejíž, jejichž
            # Numeral examples: kolik
            # Adverb examples:  kde, kam, kdy, jak, proč, co
            'yR' => ['prontype' => 'rel'],
            # Indefinite pronoun, numeral or adverb.
            # Pronoun examples: někdo, něco, nějaký, některý, něčí,
            #                   bůhvíjaký, jakýkoli, jakýkoliv, jakýsi, jakýs, takýs, kdejaký, kdovíjaký, lecjaký, ledajaký, všelijaký, málokterý
            # Numeral examples: několik, kolik, tolik, nejeden, několikátý, několikerý, pár
            # Adverb examples:  někde, někam, někdy, nějak, kdykoli, zřídkakdy
            'yI' => ['prontype' => 'ind'],
            # Negative pronoun or adverb.
            # Pronoun examples: nikdo, nic, pranic, nijaký, ničí, žádný
            # Adverb examples:  nikde, nikam, nikdy, nijak, nikterak, odnikud, nic, pranic
            'yN' => ['prontype' => 'neg']
        },
        'encode_map' =>

            { 'reflex' => { 'reflex' => 'yF',
                            '@'      => { 'prontype' => { 'int' => 'yQ',
                                                          'rel' => 'yR',
                                                          'neg' => 'yN',
                                                          'ind' => 'yI' }}}}
    );
    # ADVERB TYPE ####################
    # Semantic classification of adverbs (both normal and pronominal adverbs are classified this way).
    # Note that one tag for one word may contain several 't' features!
    # For instance, "potud" can be both adverb of extent and of time, thus its tag contains 'tQtT'.
    $atoms{t} = $self->create_atom
    (
        'tagset' => 'cs::ajka',
        'surfeature' => 'advtype',
        'decode_map' =>
        {
            # Adverb of regard (příslovce zřetele).
            ###!!! I have been able to find only one example: "místně". And it is tagged 'tAtM', i.e. it is also adverb of manner.
            ###!!! I do not understand how the class 'tA' is defined and I have not dedicated an Interset value to it.
            ###!!! Thus for the time being I decided to remove the tag that contains 'tA' from the list of known tags.
            ###!!! The decoder will not die on it but it will silently ignore the 'tA' feature.
            'tA' => [], # we could set other=>'tA' but then it would overwrite the co-occurring 'tM' feature.
            # Adverb of location (příslovce místa).
            # Examples: odtud, nazpátek, odjinud, vpravo, zdaleka, ven, pryč, daleko, skrz, blíž
            'tL' => ['advtype' => 'loc'],
            # Adverb of time (příslovce času).
            # Examples: odtud, potud, pak, potom, dlouho, nadlouho, pozdě, nato, chvílemi, večer
            'tT' => ['advtype' => 'tim'],
            # Adverb of cause (příslovce příčiny).
            # Examples: odtud, cože
            'tC' => ['advtype' => 'cau'],
            # Adverb of manner (příslovce způsobu).
            # Examples: místně, bokem, ostře, matematicky, západně, skoro, tak, takhle, takto, nijak
            'tM' => ['advtype' => 'man'],
            # Adverb of degree, extent, quantity (příslovce míry).
            # Examples: daleko, skrz, potud, hodně, tak, takhle, takto, spoustu, poněkud, bezmála
            'tQ' => ['advtype' => 'deg'],
            # Modal adverb (modální příslovce).
            # Examples: lze, možno, možná, načase, nutno, potřeba, radno, třeba, zapotřebí, dlužno
            'tD' => ['advtype' => 'mod'],
            # State adverb (příslovce stavu).
            # Examples: dlužno, plno, zima, chyba, škoda, volno, nanic
            'tS' => ['advtype' => 'sta']
        },
        'encode_map' =>

            { 'advtype' => { 'loc' => 'tL',
                             'tim' => 'tT',
                             'man' => 'tM',
                             'sta' => 'tS',
                             'deg' => 'tQ',
                             'cau' => 'tC',
                             'mod' => 'tD' }}
    );
    # GENDER ####################
    $atoms{g} = $self->create_atom
    (
        'surfeature' => 'gender',
        'decode_map' =>
        {
            'gM' => ['gender' => 'masc', 'animacy' => 'anim'],
            'gI' => ['gender' => 'masc', 'animacy' => 'inan'],
            'gF' => ['gender' => 'fem'],
            'gN' => ['gender' => 'neut'],
            # Special value for common forms of surnames that denote all members of a family, e.g. "Novákovi" = "the Nováks", "the Novák family".
            # We abuse the Interset value 'com' that is normally used in Scandinavian languages that have only two genders, neutrum and utrum (common gender).
            'gR' => ['gender' => 'com']
        },
        'encode_map' =>

            { 'gender' => { 'masc' => { 'animacy' => { 'inan' => 'gI',
                                                       '@'    => 'gM' }},
                            'fem'  => 'gF',
                            'neut' => 'gN',
                            'com'  => 'gR' }}
    );
    # POSSGENDER ####################
    # This feature is not documented but it appears in the output of Majka.
    $atoms{h} = $self->create_atom
    (
        'surfeature' => 'possgender',
        'decode_map' =>
        {
            # Examples: Janáčkův
            'hM' => ['possgender' => 'masc'],
            # Examples: babiččin, Konečné
            'hF' => ['possgender' => 'fem'],
            # Special value for common forms of surnames that denote all members of a family, e.g. "Novákovi" = "the Nováks", "the Novák family".
            # We abuse the Interset value 'com' that is normally used in Scandinavian languages that have only two genders, neutrum and utrum (common gender).
            # Examples: Novákových
            'hR' => ['possgender' => 'com'],
            # For pronouns "kdo", "co", and their derivatives, there are two other values of the 'h' feature that have nothing to do with possessivity!
            # We will only set animacy and not gender although we know that "kdo" is grammatically masculine animate and
            # "co" is grammatically neuter. However, it is very difficult to figure out under which circumstances the encoded tag should contain hP or hT,
            # and empty value of gender turns out to be the key clue. Without it, we would either not be able to preserve encode(decode(x))=x, or we would
            # have to use the 'other' feature but then without it (e.g. for structures coming from other tagsets) we would produce unknown tags even in strict encoding.
            # Person; examples: kdo, někdo, kdokoli, nikdo
            'hP' => ['animacy' => 'anim'],
            # Thing; examples: co, něco, cokoli, nic
            'hT' => ['animacy' => 'inan']
        },
        'encode_map' =>

            { 'possgender' => { 'masc' => 'hM',
                                'fem'  => 'hF',
                                'com'  => 'hR',
                                '@'    => { 'pos' => { 'noun' => { 'prontype' => { 'int|rel|ind|neg' => { 'number' => { 'sing' => { 'gender' => { '' => { 'animacy' => { 'anim' => 'hP',
                                                                                                                                                                         'inan' => 'hT' }}}}}}}}}}}}
    );
    # NUMBER ####################
    $atoms{n} = $self->create_atom
    (
        'surfeature' => 'number',
        'decode_map' =>
        {
            'nS' => ['number' => 'sing'],
            'nD' => ['number' => 'dual'],
            'nP' => ['number' => 'plur'],
            # Special value for common forms of surnames that denote all members of a family, e.g. "Novákovi" = "the Nováks", "the Novák family".
            # Unlike gender, for number it is not necessary to have a special value: this surname form is always in plural.
            # In fact, the 'nR' value is mentioned in documentation but it does not occur in output of Majka.
            'nR' => ['number' => 'plur']
        },
        'encode_map' =>

            { 'number' => { 'sing' => 'nS',
                            'dual' => 'nD',
                            'plur'  => 'nP' }}
    );
    # CASE ####################
    $atoms{c} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'c1' => 'nom',
            'c2' => 'gen',
            'c3' => 'dat',
            'c4' => 'acc',
            'c5' => 'voc',
            'c6' => 'loc',
            'c7' => 'ins'
        }
    );
    # POLARITY ####################
    $atoms{e} = $self->create_simple_atom
    (
        'intfeature' => 'polarity',
        'simple_decode_map' =>
        {
            'eA' => 'pos',
            'eN' => 'neg'
        }
    );
    # DEGREE ####################
    $atoms{d} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'd1' => 'pos',
            'd2' => 'cmp',
            'd3' => 'sup'
        }
    );
    # PERSON ####################
    $atoms{p} = $self->create_atom
    (
        'surfeature' => 'person',
        'decode_map' =>
        {
            'p1' => ['person' => '1'],
            'p2' => ['person' => '2'],
            'p3' => ['person' => '3'],
            'pX' => ['person' => '1|2|3']
        },
        'encode_map' =>

            { 'person' => { '1|2|3' => 'pX',
                            '1'     => 'p1',
                            '2'     => 'p2',
                            '3'     => 'p3' }}
    );
    # ASPECT ####################
    $atoms{a} = $self->create_simple_atom
    (
        'intfeature' => 'aspect',
        'simple_decode_map' =>
        {
            'aP' => 'perf',
            'aI' => 'imp',
            'aB' => 'imp|perf'
        }
    );
    # VERB FORM ####################
    $atoms{m} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            'mF' => ['verbform' => 'inf'],
            'mI' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres'],
            'mB' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'fut'],
            'mR' => ['verbform' => 'fin', 'mood' => 'imp'],
            'mC' => ['verbform' => 'fin', 'mood' => 'cnd'],
            'mA' => ['verbform' => 'part', 'voice' => 'act', 'tense' => 'past'],
            'mN' => ['verbform' => 'part', 'voice' => 'pass'],
            'mS' => ['verbform' => 'conv', 'tense' => 'pres'],
            'mD' => ['verbform' => 'conv', 'tense' => 'past']
        },
        'encode_map' =>

            { 'mood' => { 'imp' => 'mR',
                          'cnd' => 'mC',
                          'ind' => { 'tense' => { 'fut' => 'mB',
                                                  '@'   => 'mI' }},
                          '@'   => { 'verbform' => { 'part' => { 'voice' => { 'pass' => 'mN',
                                                                              '@'    => 'mA' }},
                                                     'conv' => { 'tense' => { 'past' => 'mD',
                                                                              '@'    => 'mS' }},
                                                     'inf'  => 'mF' }}}}
    );
    # CLITIC ####################
    # This feature is documented but it does not occur in the output of the current version of Majka.
    # Majka does not know the word forms ses, sis, tys, šels, viděls etc.
    $atoms{z} = $self->create_atom
    (
        'tagset' => 'cs::ajka',
        'surfeature' => 'clitic',
        'decode_map' =>
        {
            'zS' => ['other' => 'zS', 'verbtype' => 'aux', 'person' => '2', 'number' => 'sing'] # word form with added encliticized "-s" ("jsi", i.e. auxiliary "you are")
        },
        'encode_map' =>

            { 'other' => { 'zS' => 'zS' }}
    );
    # STYLE ####################
    # This feature is documented but it does not occur in the output of the current version of Majka.
    $atoms{w} = $self->create_atom
    (
        'tagset' => 'cs::ajka',
        'surfeature' => 'style',
        'decode_map' =>
        {
            'wA' => ['style' => 'arch'], # archaismus
            'wB' => ['style' => 'poet'], # básnicky
            'wC' => ['other' => 'wC'], # pouze v korpusech (???)
            'wE' => ['style' => 'expr'], # expresivně
            'wH' => ['style' => 'coll'], # hovorově
            'wK' => ['style' => 'form'], # knižně
            'wO' => ['style' => 'vrnc'], # oblastně
            'wR' => ['style' => 'rare'], # řidčeji
            'wZ' => ['style' => 'arch', 'other' => 'wZ'] # zastarale (??? - obsolete? - what's the difference from wA?)
        },
        'encode_map' =>

            { 'other' => { 'wC' => 'wC',
                           'wZ' => 'wZ',
                           '@'  => { 'style' => { 'arch' => 'wA',
                                                  'poet' => 'wB',
                                                  'expr' => 'wE',
                                                  'coll' => 'wH',
                                                  'form' => 'wK',
                                                  'vrnc' => 'wO',
                                                  'rare' => 'wR' }}}}
    );
    return \%atoms;
}



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset('cs::ajka');
    my $atoms = $self->atoms();
    # A tag is a sequence of feature-value pairs. Feature is a lowercase letter, value is an uppercase letter or a digit.
    # Example: k1gMnSc1
    # Decompose the tag to individual feature-value pairs.
    # Ordering of features is not guaranteed, thus it is safer to first read all features, then query them.
    # Also, it is possible that a feature occurs repeatedly with different values (observed with the 't' feature).
    my @chars = split(//, $tag);
    my @features; # ordering of surface features
    my %features; # lists of values of surface features
    for(my $i = 0; $i<=$#chars; $i += 2)
    {
        my $feature = $chars[$i]; # e.g. 'k'
        my $value = $feature.$chars[$i+1]; # e.g. 'k1'
        push(@features, $feature) unless(exists($features{$feature}));
        push(@{$features{$feature}{valarray}}, $value) unless(exists($features{$feature}{valhash}{$value}));
        $features{$feature}{valhash}{$value}++;
    }
    # Decode the features in the order in which they appeared in the input.
    foreach my $feature (@features)
    {
        # Interpretation of the 'x' feature depends on the value of the 'k' feature.
        my $kfeature = $feature;
        if($kfeature eq 'x')
        {
            $kfeature .= join('', @{$features{'k'}{valarray}});
        }
        if(exists($atoms->{$kfeature}))
        {
            foreach my $value (@{$features{$feature}{valarray}})
            {
                if($kfeature eq 't')
                {
                    $atoms->{$kfeature}->decode_and_merge_soft($value, $fs);
                }
                else
                {
                    # Normally we need "hard merging". For instance, 'k3' will set prontype=prn,
                    # later we see 'yQ' and we want to REWRITE prontype to 'int', not just merge prontype=prn|int!
                    $atoms->{$kfeature}->decode_and_merge_hard($value, $fs);
                }
            }
        }
    }
    return $fs;
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $tag = '';
    my $atoms = $self->atoms();
    # The tagset is defined as non-positional, yet there is a canonical ordering of features that we should follow.
    # Note that the canonical ordering of tagset version 1.0 (as output by Majka) differs from the ordering described for version 2.0.
    # k0 ... k
    # k1 ... kgncx
    # k2 ... kegncdh
    # k3 ... kpgncxy
    # k4 ... kgncxy
    # k5 ... keampgn
    # k6 ... kedtxy
    # k7 ... kc
    # k8 ... kx
    # k9 ... k
    # kA ... k
    # kY ... kmpn
    my @canonical = ('k', 'e', 'a', 'm', 'p', 'g', 'n', 'c', 'd', 'h', 't', 'x', 'y', 'z', 'w');
    my %surfeatures;
    foreach my $feature (@canonical)
    {
        # Interpretation of the 'x' feature depends on the value of the 'k' feature.
        my $kfeature = $feature;
        if($feature eq 'x')
        {
            $kfeature .= $surfeatures{'k'};
        }
        if(exists($atoms->{$kfeature}))
        {
            my $value;
            if($kfeature eq 't')
            {
                $value = $self->encode_t($fs, $atoms->{'t'});
            }
            else
            {
                $value = $atoms->{$kfeature}->encode($fs);
            }
            if(defined($value) && $value ne '')
            {
                $tag .= $value;
                $surfeatures{$feature} = $value;
            }
        }
    }
    return $tag;
}



#------------------------------------------------------------------------------
# Encodes semantic type of adverb (the surface feature 't'). This feature
# requires special treatment because it can have multiple values.
#------------------------------------------------------------------------------
sub encode_t
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $atom_t = shift; # Lingua::Interset::Atom
    my @values = $fs->get_list('advtype');
    my $n = scalar(@values);
    if($n==0)
    {
        return '';
    }
    elsif($n==1)
    {
        return $atom_t->encode($fs);
    }
    else # $n>1
    {
        my @tags = ();
        foreach my $value (@values)
        {
            my $fs1 = $fs->duplicate();
            $fs1->set('advtype', $value);
            push(@tags, $atom_t->encode($fs1));
        }
        return join('', sort(@tags));
    }
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# I have no official list of tags that can be generated by Ajka or Majka.
# I took the Czech text from PDT (CoNLL 2006), asked Majka to analyze all the
# words, then took all lemmas and asked Majka to generate all possible word
# forms for every lemma. The list contains all tags that appeared in output of
# one or both the runs of Majka.
# Count: 2176 Majka tags
# (it was 2177 before I removed the 'k6eAd1tAtM' tag)
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
k0
k1gFnPc1
k1gFnPc2
k1gFnPc3
k1gFnPc4
k1gFnPc5
k1gFnPc6
k1gFnPc7
k1gFnSc1
k1gFnSc2
k1gFnSc3
k1gFnSc4
k1gFnSc5
k1gFnSc6
k1gFnSc7
k1gInPc1
k1gInPc2
k1gInPc3
k1gInPc4
k1gInPc5
k1gInPc6
k1gInPc7
k1gInSc1
k1gInSc2
k1gInSc3
k1gInSc4
k1gInSc5
k1gInSc6
k1gInSc7
k1gMnPc1
k1gMnPc2
k1gMnPc3
k1gMnPc4
k1gMnPc5
k1gMnPc6
k1gMnPc7
k1gMnSc1
k1gMnSc2
k1gMnSc3
k1gMnSc4
k1gMnSc5
k1gMnSc6
k1gMnSc7
k1gNnPc1
k1gNnPc2
k1gNnPc3
k1gNnPc4
k1gNnPc5
k1gNnPc6
k1gNnPc7
k1gNnSc1
k1gNnSc2
k1gNnSc3
k1gNnSc4
k1gNnSc5
k1gNnSc6
k1gNnSc7
k1gRnPc1
k1gRnPc2
k1gRnPc3
k1gRnPc4
k1gRnPc5
k1gRnPc6
k1gRnPc7
k1xP
k2eAgFnPc1d1
k2eAgFnPc1d1hF
k2eAgFnPc1d1hM
k2eAgFnPc1d1hR
k2eAgFnPc1d2
k2eAgFnPc1d3
k2eAgFnPc2d1
k2eAgFnPc2d1hF
k2eAgFnPc2d1hM
k2eAgFnPc2d1hR
k2eAgFnPc2d2
k2eAgFnPc2d3
k2eAgFnPc3d1
k2eAgFnPc3d1hF
k2eAgFnPc3d1hM
k2eAgFnPc3d1hR
k2eAgFnPc3d2
k2eAgFnPc3d3
k2eAgFnPc4d1
k2eAgFnPc4d1hF
k2eAgFnPc4d1hM
k2eAgFnPc4d1hR
k2eAgFnPc4d2
k2eAgFnPc4d3
k2eAgFnPc5d1
k2eAgFnPc5d1hF
k2eAgFnPc5d1hM
k2eAgFnPc5d1hR
k2eAgFnPc5d2
k2eAgFnPc5d3
k2eAgFnPc6d1
k2eAgFnPc6d1hF
k2eAgFnPc6d1hM
k2eAgFnPc6d1hR
k2eAgFnPc6d2
k2eAgFnPc6d3
k2eAgFnPc7d1
k2eAgFnPc7d1hF
k2eAgFnPc7d1hM
k2eAgFnPc7d1hR
k2eAgFnPc7d2
k2eAgFnPc7d3
k2eAgFnSc1d1
k2eAgFnSc1d1hF
k2eAgFnSc1d1hM
k2eAgFnSc1d1hR
k2eAgFnSc1d2
k2eAgFnSc1d3
k2eAgFnSc2d1
k2eAgFnSc2d1hF
k2eAgFnSc2d1hM
k2eAgFnSc2d1hR
k2eAgFnSc2d2
k2eAgFnSc2d3
k2eAgFnSc3d1
k2eAgFnSc3d1hF
k2eAgFnSc3d1hM
k2eAgFnSc3d1hR
k2eAgFnSc3d2
k2eAgFnSc3d3
k2eAgFnSc4d1
k2eAgFnSc4d1hF
k2eAgFnSc4d1hM
k2eAgFnSc4d1hR
k2eAgFnSc4d2
k2eAgFnSc4d3
k2eAgFnSc5d1
k2eAgFnSc5d1hF
k2eAgFnSc5d1hM
k2eAgFnSc5d1hR
k2eAgFnSc5d2
k2eAgFnSc5d3
k2eAgFnSc6d1
k2eAgFnSc6d1hF
k2eAgFnSc6d1hM
k2eAgFnSc6d1hR
k2eAgFnSc6d2
k2eAgFnSc6d3
k2eAgFnSc7d1
k2eAgFnSc7d1hF
k2eAgFnSc7d1hM
k2eAgFnSc7d1hR
k2eAgFnSc7d2
k2eAgFnSc7d3
k2eAgInPc1d1
k2eAgInPc1d1hF
k2eAgInPc1d1hM
k2eAgInPc1d1hR
k2eAgInPc1d2
k2eAgInPc1d3
k2eAgInPc2d1
k2eAgInPc2d1hF
k2eAgInPc2d1hM
k2eAgInPc2d1hR
k2eAgInPc2d2
k2eAgInPc2d3
k2eAgInPc3d1
k2eAgInPc3d1hF
k2eAgInPc3d1hM
k2eAgInPc3d1hR
k2eAgInPc3d2
k2eAgInPc3d3
k2eAgInPc4d1
k2eAgInPc4d1hF
k2eAgInPc4d1hM
k2eAgInPc4d1hR
k2eAgInPc4d2
k2eAgInPc4d3
k2eAgInPc5d1
k2eAgInPc5d1hF
k2eAgInPc5d1hM
k2eAgInPc5d1hR
k2eAgInPc5d2
k2eAgInPc5d3
k2eAgInPc6d1
k2eAgInPc6d1hF
k2eAgInPc6d1hM
k2eAgInPc6d1hR
k2eAgInPc6d2
k2eAgInPc6d3
k2eAgInPc7d1
k2eAgInPc7d1hF
k2eAgInPc7d1hM
k2eAgInPc7d1hR
k2eAgInPc7d2
k2eAgInPc7d3
k2eAgInSc1d1
k2eAgInSc1d1hF
k2eAgInSc1d1hM
k2eAgInSc1d1hR
k2eAgInSc1d2
k2eAgInSc1d3
k2eAgInSc2d1
k2eAgInSc2d1hF
k2eAgInSc2d1hM
k2eAgInSc2d1hR
k2eAgInSc2d2
k2eAgInSc2d3
k2eAgInSc3d1
k2eAgInSc3d1hF
k2eAgInSc3d1hM
k2eAgInSc3d1hR
k2eAgInSc3d2
k2eAgInSc3d3
k2eAgInSc4d1
k2eAgInSc4d1hF
k2eAgInSc4d1hM
k2eAgInSc4d1hR
k2eAgInSc4d2
k2eAgInSc4d3
k2eAgInSc5d1
k2eAgInSc5d1hF
k2eAgInSc5d1hM
k2eAgInSc5d1hR
k2eAgInSc5d2
k2eAgInSc5d3
k2eAgInSc6d1
k2eAgInSc6d1hF
k2eAgInSc6d1hM
k2eAgInSc6d1hR
k2eAgInSc6d2
k2eAgInSc6d3
k2eAgInSc7d1
k2eAgInSc7d1hF
k2eAgInSc7d1hM
k2eAgInSc7d1hR
k2eAgInSc7d2
k2eAgInSc7d3
k2eAgMnPc1d1
k2eAgMnPc1d1hF
k2eAgMnPc1d1hM
k2eAgMnPc1d1hR
k2eAgMnPc1d2
k2eAgMnPc1d3
k2eAgMnPc2d1
k2eAgMnPc2d1hF
k2eAgMnPc2d1hM
k2eAgMnPc2d1hR
k2eAgMnPc2d2
k2eAgMnPc2d3
k2eAgMnPc3d1
k2eAgMnPc3d1hF
k2eAgMnPc3d1hM
k2eAgMnPc3d1hR
k2eAgMnPc3d2
k2eAgMnPc3d3
k2eAgMnPc4d1
k2eAgMnPc4d1hF
k2eAgMnPc4d1hM
k2eAgMnPc4d1hR
k2eAgMnPc4d2
k2eAgMnPc4d3
k2eAgMnPc5d1
k2eAgMnPc5d1hF
k2eAgMnPc5d1hM
k2eAgMnPc5d1hR
k2eAgMnPc5d2
k2eAgMnPc5d3
k2eAgMnPc6d1
k2eAgMnPc6d1hF
k2eAgMnPc6d1hM
k2eAgMnPc6d1hR
k2eAgMnPc6d2
k2eAgMnPc6d3
k2eAgMnPc7d1
k2eAgMnPc7d1hF
k2eAgMnPc7d1hM
k2eAgMnPc7d1hR
k2eAgMnPc7d2
k2eAgMnPc7d3
k2eAgMnSc1d1
k2eAgMnSc1d1hF
k2eAgMnSc1d1hM
k2eAgMnSc1d1hR
k2eAgMnSc1d2
k2eAgMnSc1d3
k2eAgMnSc2d1
k2eAgMnSc2d1hF
k2eAgMnSc2d1hM
k2eAgMnSc2d1hR
k2eAgMnSc2d2
k2eAgMnSc2d3
k2eAgMnSc3d1
k2eAgMnSc3d1hF
k2eAgMnSc3d1hM
k2eAgMnSc3d1hR
k2eAgMnSc3d2
k2eAgMnSc3d3
k2eAgMnSc4d1
k2eAgMnSc4d1hF
k2eAgMnSc4d1hM
k2eAgMnSc4d1hR
k2eAgMnSc4d2
k2eAgMnSc4d3
k2eAgMnSc5d1
k2eAgMnSc5d1hF
k2eAgMnSc5d1hM
k2eAgMnSc5d1hR
k2eAgMnSc5d2
k2eAgMnSc5d3
k2eAgMnSc6d1
k2eAgMnSc6d1hF
k2eAgMnSc6d1hM
k2eAgMnSc6d1hR
k2eAgMnSc6d2
k2eAgMnSc6d3
k2eAgMnSc7d1
k2eAgMnSc7d1hF
k2eAgMnSc7d1hM
k2eAgMnSc7d1hR
k2eAgMnSc7d2
k2eAgMnSc7d3
k2eAgNnPc1d1
k2eAgNnPc1d1hF
k2eAgNnPc1d1hM
k2eAgNnPc1d1hR
k2eAgNnPc1d2
k2eAgNnPc1d3
k2eAgNnPc2d1
k2eAgNnPc2d1hF
k2eAgNnPc2d1hM
k2eAgNnPc2d1hR
k2eAgNnPc2d2
k2eAgNnPc2d3
k2eAgNnPc3d1
k2eAgNnPc3d1hF
k2eAgNnPc3d1hM
k2eAgNnPc3d1hR
k2eAgNnPc3d2
k2eAgNnPc3d3
k2eAgNnPc4d1
k2eAgNnPc4d1hF
k2eAgNnPc4d1hM
k2eAgNnPc4d1hR
k2eAgNnPc4d2
k2eAgNnPc4d3
k2eAgNnPc5d1
k2eAgNnPc5d1hF
k2eAgNnPc5d1hM
k2eAgNnPc5d1hR
k2eAgNnPc5d2
k2eAgNnPc5d3
k2eAgNnPc6d1
k2eAgNnPc6d1hF
k2eAgNnPc6d1hM
k2eAgNnPc6d1hR
k2eAgNnPc6d2
k2eAgNnPc6d3
k2eAgNnPc7d1
k2eAgNnPc7d1hF
k2eAgNnPc7d1hM
k2eAgNnPc7d1hR
k2eAgNnPc7d2
k2eAgNnPc7d3
k2eAgNnSc1d1
k2eAgNnSc1d1hF
k2eAgNnSc1d1hM
k2eAgNnSc1d1hR
k2eAgNnSc1d2
k2eAgNnSc1d3
k2eAgNnSc2d1
k2eAgNnSc2d1hF
k2eAgNnSc2d1hM
k2eAgNnSc2d1hR
k2eAgNnSc2d2
k2eAgNnSc2d3
k2eAgNnSc3d1
k2eAgNnSc3d1hF
k2eAgNnSc3d1hM
k2eAgNnSc3d1hR
k2eAgNnSc3d2
k2eAgNnSc3d3
k2eAgNnSc4d1
k2eAgNnSc4d1hF
k2eAgNnSc4d1hM
k2eAgNnSc4d1hR
k2eAgNnSc4d2
k2eAgNnSc4d3
k2eAgNnSc5d1
k2eAgNnSc5d1hF
k2eAgNnSc5d1hM
k2eAgNnSc5d1hR
k2eAgNnSc5d2
k2eAgNnSc5d3
k2eAgNnSc6d1
k2eAgNnSc6d1hF
k2eAgNnSc6d1hM
k2eAgNnSc6d1hR
k2eAgNnSc6d2
k2eAgNnSc6d3
k2eAgNnSc7d1
k2eAgNnSc7d1hF
k2eAgNnSc7d1hM
k2eAgNnSc7d1hR
k2eAgNnSc7d2
k2eAgNnSc7d3
k2eNgFnPc1d1
k2eNgFnPc1d2
k2eNgFnPc1d3
k2eNgFnPc2d1
k2eNgFnPc2d2
k2eNgFnPc2d3
k2eNgFnPc3d1
k2eNgFnPc3d2
k2eNgFnPc3d3
k2eNgFnPc4d1
k2eNgFnPc4d2
k2eNgFnPc4d3
k2eNgFnPc5d1
k2eNgFnPc5d2
k2eNgFnPc5d3
k2eNgFnPc6d1
k2eNgFnPc6d2
k2eNgFnPc6d3
k2eNgFnPc7d1
k2eNgFnPc7d2
k2eNgFnPc7d3
k2eNgFnSc1d1
k2eNgFnSc1d2
k2eNgFnSc1d3
k2eNgFnSc2d1
k2eNgFnSc2d2
k2eNgFnSc2d3
k2eNgFnSc3d1
k2eNgFnSc3d2
k2eNgFnSc3d3
k2eNgFnSc4d1
k2eNgFnSc4d2
k2eNgFnSc4d3
k2eNgFnSc5d1
k2eNgFnSc5d2
k2eNgFnSc5d3
k2eNgFnSc6d1
k2eNgFnSc6d2
k2eNgFnSc6d3
k2eNgFnSc7d1
k2eNgFnSc7d2
k2eNgFnSc7d3
k2eNgInPc1d1
k2eNgInPc1d2
k2eNgInPc1d3
k2eNgInPc2d1
k2eNgInPc2d2
k2eNgInPc2d3
k2eNgInPc3d1
k2eNgInPc3d2
k2eNgInPc3d3
k2eNgInPc4d1
k2eNgInPc4d2
k2eNgInPc4d3
k2eNgInPc5d1
k2eNgInPc5d2
k2eNgInPc5d3
k2eNgInPc6d1
k2eNgInPc6d2
k2eNgInPc6d3
k2eNgInPc7d1
k2eNgInPc7d2
k2eNgInPc7d3
k2eNgInSc1d1
k2eNgInSc1d2
k2eNgInSc1d3
k2eNgInSc2d1
k2eNgInSc2d2
k2eNgInSc2d3
k2eNgInSc3d1
k2eNgInSc3d2
k2eNgInSc3d3
k2eNgInSc4d1
k2eNgInSc4d2
k2eNgInSc4d3
k2eNgInSc5d1
k2eNgInSc5d2
k2eNgInSc5d3
k2eNgInSc6d1
k2eNgInSc6d2
k2eNgInSc6d3
k2eNgInSc7d1
k2eNgInSc7d2
k2eNgInSc7d3
k2eNgMnPc1d1
k2eNgMnPc1d2
k2eNgMnPc1d3
k2eNgMnPc2d1
k2eNgMnPc2d2
k2eNgMnPc2d3
k2eNgMnPc3d1
k2eNgMnPc3d2
k2eNgMnPc3d3
k2eNgMnPc4d1
k2eNgMnPc4d2
k2eNgMnPc4d3
k2eNgMnPc5d1
k2eNgMnPc5d2
k2eNgMnPc5d3
k2eNgMnPc6d1
k2eNgMnPc6d2
k2eNgMnPc6d3
k2eNgMnPc7d1
k2eNgMnPc7d2
k2eNgMnPc7d3
k2eNgMnSc1d1
k2eNgMnSc1d2
k2eNgMnSc1d3
k2eNgMnSc2d1
k2eNgMnSc2d2
k2eNgMnSc2d3
k2eNgMnSc3d1
k2eNgMnSc3d2
k2eNgMnSc3d3
k2eNgMnSc4d1
k2eNgMnSc4d2
k2eNgMnSc4d3
k2eNgMnSc5d1
k2eNgMnSc5d2
k2eNgMnSc5d3
k2eNgMnSc6d1
k2eNgMnSc6d2
k2eNgMnSc6d3
k2eNgMnSc7d1
k2eNgMnSc7d2
k2eNgMnSc7d3
k2eNgNnPc1d1
k2eNgNnPc1d2
k2eNgNnPc1d3
k2eNgNnPc2d1
k2eNgNnPc2d2
k2eNgNnPc2d3
k2eNgNnPc3d1
k2eNgNnPc3d2
k2eNgNnPc3d3
k2eNgNnPc4d1
k2eNgNnPc4d2
k2eNgNnPc4d3
k2eNgNnPc5d1
k2eNgNnPc5d2
k2eNgNnPc5d3
k2eNgNnPc6d1
k2eNgNnPc6d2
k2eNgNnPc6d3
k2eNgNnPc7d1
k2eNgNnPc7d2
k2eNgNnPc7d3
k2eNgNnSc1d1
k2eNgNnSc1d2
k2eNgNnSc1d3
k2eNgNnSc2d1
k2eNgNnSc2d2
k2eNgNnSc2d3
k2eNgNnSc3d1
k2eNgNnSc3d2
k2eNgNnSc3d3
k2eNgNnSc4d1
k2eNgNnSc4d2
k2eNgNnSc4d3
k2eNgNnSc5d1
k2eNgNnSc5d2
k2eNgNnSc5d3
k2eNgNnSc6d1
k2eNgNnSc6d2
k2eNgNnSc6d3
k2eNgNnSc7d1
k2eNgNnSc7d2
k2eNgNnSc7d3
k3c2xPyF
k3c3xPyF
k3c4xPyF
k3c6xPyF
k3c7xPyF
k3gFnPc1xD
k3gFnPc1xOyF
k3gFnPc1xOyI
k3gFnPc1xOyN
k3gFnPc1xOyQ
k3gFnPc1xOyR
k3gFnPc1xT
k3gFnPc1yI
k3gFnPc1yN
k3gFnPc1yQ
k3gFnPc1yR
k3gFnPc2xD
k3gFnPc2xOyF
k3gFnPc2xOyI
k3gFnPc2xOyN
k3gFnPc2xOyQ
k3gFnPc2xOyR
k3gFnPc2xT
k3gFnPc2yI
k3gFnPc2yN
k3gFnPc2yQ
k3gFnPc2yR
k3gFnPc3xD
k3gFnPc3xOyF
k3gFnPc3xOyI
k3gFnPc3xOyN
k3gFnPc3xOyQ
k3gFnPc3xOyR
k3gFnPc3xT
k3gFnPc3yI
k3gFnPc3yN
k3gFnPc3yQ
k3gFnPc3yR
k3gFnPc4xD
k3gFnPc4xOyF
k3gFnPc4xOyI
k3gFnPc4xOyN
k3gFnPc4xOyQ
k3gFnPc4xOyR
k3gFnPc4xT
k3gFnPc4yI
k3gFnPc4yN
k3gFnPc4yQ
k3gFnPc4yR
k3gFnPc5yR
k3gFnPc6xD
k3gFnPc6xOyF
k3gFnPc6xOyI
k3gFnPc6xOyN
k3gFnPc6xOyQ
k3gFnPc6xOyR
k3gFnPc6xT
k3gFnPc6yI
k3gFnPc6yN
k3gFnPc6yQ
k3gFnPc6yR
k3gFnPc7xD
k3gFnPc7xOyF
k3gFnPc7xOyI
k3gFnPc7xOyN
k3gFnPc7xOyQ
k3gFnPc7xOyR
k3gFnPc7xT
k3gFnPc7yI
k3gFnPc7yN
k3gFnPc7yQ
k3gFnPc7yR
k3gFnSc1xD
k3gFnSc1xOyF
k3gFnSc1xOyI
k3gFnSc1xOyN
k3gFnSc1xOyQ
k3gFnSc1xOyR
k3gFnSc1xT
k3gFnSc1yI
k3gFnSc1yN
k3gFnSc1yQ
k3gFnSc1yR
k3gFnSc2xD
k3gFnSc2xOyF
k3gFnSc2xOyI
k3gFnSc2xOyN
k3gFnSc2xOyQ
k3gFnSc2xOyR
k3gFnSc2xT
k3gFnSc2yI
k3gFnSc2yN
k3gFnSc2yQ
k3gFnSc2yR
k3gFnSc3xD
k3gFnSc3xOyF
k3gFnSc3xOyI
k3gFnSc3xOyN
k3gFnSc3xOyQ
k3gFnSc3xOyR
k3gFnSc3xT
k3gFnSc3yI
k3gFnSc3yN
k3gFnSc3yQ
k3gFnSc3yR
k3gFnSc4xD
k3gFnSc4xOyF
k3gFnSc4xOyI
k3gFnSc4xOyN
k3gFnSc4xOyQ
k3gFnSc4xOyR
k3gFnSc4xT
k3gFnSc4yI
k3gFnSc4yN
k3gFnSc4yQ
k3gFnSc4yR
k3gFnSc5yR
k3gFnSc6xD
k3gFnSc6xOyF
k3gFnSc6xOyI
k3gFnSc6xOyN
k3gFnSc6xOyQ
k3gFnSc6xOyR
k3gFnSc6xT
k3gFnSc6yI
k3gFnSc6yN
k3gFnSc6yQ
k3gFnSc6yR
k3gFnSc7xD
k3gFnSc7xOyF
k3gFnSc7xOyI
k3gFnSc7xOyN
k3gFnSc7xOyQ
k3gFnSc7xOyR
k3gFnSc7xT
k3gFnSc7yI
k3gFnSc7yN
k3gFnSc7yQ
k3gFnSc7yR
k3gInPc1xD
k3gInPc1xOyF
k3gInPc1xOyI
k3gInPc1xOyN
k3gInPc1xOyQ
k3gInPc1xOyR
k3gInPc1xT
k3gInPc1yI
k3gInPc1yN
k3gInPc1yQ
k3gInPc1yR
k3gInPc2xD
k3gInPc2xOyF
k3gInPc2xOyI
k3gInPc2xOyN
k3gInPc2xOyQ
k3gInPc2xOyR
k3gInPc2xT
k3gInPc2yI
k3gInPc2yN
k3gInPc2yQ
k3gInPc2yR
k3gInPc3xD
k3gInPc3xOyF
k3gInPc3xOyI
k3gInPc3xOyN
k3gInPc3xOyQ
k3gInPc3xOyR
k3gInPc3xT
k3gInPc3yI
k3gInPc3yN
k3gInPc3yQ
k3gInPc3yR
k3gInPc4xD
k3gInPc4xOyF
k3gInPc4xOyI
k3gInPc4xOyN
k3gInPc4xOyQ
k3gInPc4xOyR
k3gInPc4xT
k3gInPc4yI
k3gInPc4yN
k3gInPc4yQ
k3gInPc4yR
k3gInPc5yR
k3gInPc6xD
k3gInPc6xOyF
k3gInPc6xOyI
k3gInPc6xOyN
k3gInPc6xOyQ
k3gInPc6xOyR
k3gInPc6xT
k3gInPc6yI
k3gInPc6yN
k3gInPc6yQ
k3gInPc6yR
k3gInPc7xD
k3gInPc7xOyF
k3gInPc7xOyI
k3gInPc7xOyN
k3gInPc7xOyQ
k3gInPc7xOyR
k3gInPc7xT
k3gInPc7yI
k3gInPc7yN
k3gInPc7yQ
k3gInPc7yR
k3gInSc1xD
k3gInSc1xOyF
k3gInSc1xOyI
k3gInSc1xOyN
k3gInSc1xOyQ
k3gInSc1xOyR
k3gInSc1xT
k3gInSc1yI
k3gInSc1yN
k3gInSc1yQ
k3gInSc1yR
k3gInSc2xD
k3gInSc2xOyF
k3gInSc2xOyI
k3gInSc2xOyN
k3gInSc2xOyQ
k3gInSc2xOyR
k3gInSc2xT
k3gInSc2yI
k3gInSc2yN
k3gInSc2yQ
k3gInSc2yR
k3gInSc3xD
k3gInSc3xOyF
k3gInSc3xOyI
k3gInSc3xOyN
k3gInSc3xOyQ
k3gInSc3xOyR
k3gInSc3xT
k3gInSc3yI
k3gInSc3yN
k3gInSc3yQ
k3gInSc3yR
k3gInSc4xD
k3gInSc4xOyF
k3gInSc4xOyI
k3gInSc4xOyN
k3gInSc4xOyQ
k3gInSc4xOyR
k3gInSc4xT
k3gInSc4yI
k3gInSc4yN
k3gInSc4yQ
k3gInSc4yR
k3gInSc5yR
k3gInSc6xD
k3gInSc6xOyF
k3gInSc6xOyI
k3gInSc6xOyN
k3gInSc6xOyQ
k3gInSc6xOyR
k3gInSc6xT
k3gInSc6yI
k3gInSc6yN
k3gInSc6yQ
k3gInSc6yR
k3gInSc7xD
k3gInSc7xOyF
k3gInSc7xOyI
k3gInSc7xOyN
k3gInSc7xOyQ
k3gInSc7xOyR
k3gInSc7xT
k3gInSc7yI
k3gInSc7yN
k3gInSc7yQ
k3gInSc7yR
k3gMnPc1xD
k3gMnPc1xOyF
k3gMnPc1xOyI
k3gMnPc1xOyN
k3gMnPc1xOyQ
k3gMnPc1xOyR
k3gMnPc1xT
k3gMnPc1yI
k3gMnPc1yN
k3gMnPc1yQ
k3gMnPc1yR
k3gMnPc2xD
k3gMnPc2xOyF
k3gMnPc2xOyI
k3gMnPc2xOyN
k3gMnPc2xOyQ
k3gMnPc2xOyR
k3gMnPc2xT
k3gMnPc2yI
k3gMnPc2yN
k3gMnPc2yQ
k3gMnPc2yR
k3gMnPc3xD
k3gMnPc3xOyF
k3gMnPc3xOyI
k3gMnPc3xOyN
k3gMnPc3xOyQ
k3gMnPc3xOyR
k3gMnPc3xT
k3gMnPc3yI
k3gMnPc3yN
k3gMnPc3yQ
k3gMnPc3yR
k3gMnPc4xD
k3gMnPc4xOyF
k3gMnPc4xOyI
k3gMnPc4xOyN
k3gMnPc4xOyQ
k3gMnPc4xOyR
k3gMnPc4xT
k3gMnPc4yI
k3gMnPc4yN
k3gMnPc4yQ
k3gMnPc4yR
k3gMnPc5yR
k3gMnPc6xD
k3gMnPc6xOyF
k3gMnPc6xOyI
k3gMnPc6xOyN
k3gMnPc6xOyQ
k3gMnPc6xOyR
k3gMnPc6xT
k3gMnPc6yI
k3gMnPc6yN
k3gMnPc6yQ
k3gMnPc6yR
k3gMnPc7xD
k3gMnPc7xOyF
k3gMnPc7xOyI
k3gMnPc7xOyN
k3gMnPc7xOyQ
k3gMnPc7xOyR
k3gMnPc7xT
k3gMnPc7yI
k3gMnPc7yN
k3gMnPc7yQ
k3gMnPc7yR
k3gMnSc1xD
k3gMnSc1xOyF
k3gMnSc1xOyI
k3gMnSc1xOyN
k3gMnSc1xOyQ
k3gMnSc1xOyR
k3gMnSc1xT
k3gMnSc1yI
k3gMnSc1yN
k3gMnSc1yQ
k3gMnSc1yR
k3gMnSc2xD
k3gMnSc2xOyF
k3gMnSc2xOyI
k3gMnSc2xOyN
k3gMnSc2xOyQ
k3gMnSc2xOyR
k3gMnSc2xT
k3gMnSc2yI
k3gMnSc2yN
k3gMnSc2yQ
k3gMnSc2yR
k3gMnSc3xD
k3gMnSc3xOyF
k3gMnSc3xOyI
k3gMnSc3xOyN
k3gMnSc3xOyQ
k3gMnSc3xOyR
k3gMnSc3xT
k3gMnSc3yI
k3gMnSc3yN
k3gMnSc3yQ
k3gMnSc3yR
k3gMnSc4xD
k3gMnSc4xOyF
k3gMnSc4xOyI
k3gMnSc4xOyN
k3gMnSc4xOyQ
k3gMnSc4xOyR
k3gMnSc4xT
k3gMnSc4yI
k3gMnSc4yN
k3gMnSc4yQ
k3gMnSc4yR
k3gMnSc5yR
k3gMnSc6xD
k3gMnSc6xOyF
k3gMnSc6xOyI
k3gMnSc6xOyN
k3gMnSc6xOyQ
k3gMnSc6xOyR
k3gMnSc6xT
k3gMnSc6yI
k3gMnSc6yN
k3gMnSc6yQ
k3gMnSc6yR
k3gMnSc7xD
k3gMnSc7xOyF
k3gMnSc7xOyI
k3gMnSc7xOyN
k3gMnSc7xOyQ
k3gMnSc7xOyR
k3gMnSc7xT
k3gMnSc7yI
k3gMnSc7yN
k3gMnSc7yQ
k3gMnSc7yR
k3gNnPc1xD
k3gNnPc1xOyF
k3gNnPc1xOyI
k3gNnPc1xOyN
k3gNnPc1xOyQ
k3gNnPc1xOyR
k3gNnPc1xT
k3gNnPc1yI
k3gNnPc1yN
k3gNnPc1yQ
k3gNnPc1yR
k3gNnPc2xD
k3gNnPc2xOyF
k3gNnPc2xOyI
k3gNnPc2xOyN
k3gNnPc2xOyQ
k3gNnPc2xOyR
k3gNnPc2xT
k3gNnPc2yI
k3gNnPc2yN
k3gNnPc2yQ
k3gNnPc2yR
k3gNnPc3xD
k3gNnPc3xOyF
k3gNnPc3xOyI
k3gNnPc3xOyN
k3gNnPc3xOyQ
k3gNnPc3xOyR
k3gNnPc3xT
k3gNnPc3yI
k3gNnPc3yN
k3gNnPc3yQ
k3gNnPc3yR
k3gNnPc4xD
k3gNnPc4xOyF
k3gNnPc4xOyI
k3gNnPc4xOyN
k3gNnPc4xOyQ
k3gNnPc4xOyR
k3gNnPc4xT
k3gNnPc4yI
k3gNnPc4yN
k3gNnPc4yQ
k3gNnPc4yR
k3gNnPc5yR
k3gNnPc6xD
k3gNnPc6xOyF
k3gNnPc6xOyI
k3gNnPc6xOyN
k3gNnPc6xOyQ
k3gNnPc6xOyR
k3gNnPc6xT
k3gNnPc6yI
k3gNnPc6yN
k3gNnPc6yQ
k3gNnPc6yR
k3gNnPc7xD
k3gNnPc7xOyF
k3gNnPc7xOyI
k3gNnPc7xOyN
k3gNnPc7xOyQ
k3gNnPc7xOyR
k3gNnPc7xT
k3gNnPc7yI
k3gNnPc7yN
k3gNnPc7yQ
k3gNnPc7yR
k3gNnSc1xD
k3gNnSc1xOyF
k3gNnSc1xOyI
k3gNnSc1xOyN
k3gNnSc1xOyQ
k3gNnSc1xOyR
k3gNnSc1xT
k3gNnSc1yI
k3gNnSc1yN
k3gNnSc1yQ
k3gNnSc1yR
k3gNnSc2xD
k3gNnSc2xOyF
k3gNnSc2xOyI
k3gNnSc2xOyN
k3gNnSc2xOyQ
k3gNnSc2xOyR
k3gNnSc2xT
k3gNnSc2yI
k3gNnSc2yN
k3gNnSc2yQ
k3gNnSc2yR
k3gNnSc3xD
k3gNnSc3xOyF
k3gNnSc3xOyI
k3gNnSc3xOyN
k3gNnSc3xOyQ
k3gNnSc3xOyR
k3gNnSc3xT
k3gNnSc3yI
k3gNnSc3yN
k3gNnSc3yQ
k3gNnSc3yR
k3gNnSc4xD
k3gNnSc4xOyF
k3gNnSc4xOyI
k3gNnSc4xOyN
k3gNnSc4xOyQ
k3gNnSc4xOyR
k3gNnSc4xT
k3gNnSc4yI
k3gNnSc4yN
k3gNnSc4yQ
k3gNnSc4yR
k3gNnSc5yR
k3gNnSc6xD
k3gNnSc6xOyF
k3gNnSc6xOyI
k3gNnSc6xOyN
k3gNnSc6xOyQ
k3gNnSc6xOyR
k3gNnSc6xT
k3gNnSc6yI
k3gNnSc6yN
k3gNnSc6yQ
k3gNnSc6yR
k3gNnSc7xD
k3gNnSc7xOyF
k3gNnSc7xOyI
k3gNnSc7xOyN
k3gNnSc7xOyQ
k3gNnSc7xOyR
k3gNnSc7xT
k3gNnSc7yI
k3gNnSc7yN
k3gNnSc7yQ
k3gNnSc7yR
k3nSc1hPyI
k3nSc1hPyN
k3nSc1hPyQ
k3nSc1hPyR
k3nSc1hTyI
k3nSc1hTyN
k3nSc1hTyQ
k3nSc1hTyR
k3nSc1yQ
k3nSc2hPyI
k3nSc2hPyN
k3nSc2hPyQ
k3nSc2hPyR
k3nSc2hTyI
k3nSc2hTyN
k3nSc2hTyQ
k3nSc2hTyR
k3nSc2yQ
k3nSc3hPyI
k3nSc3hPyN
k3nSc3hPyQ
k3nSc3hPyR
k3nSc3hTyI
k3nSc3hTyN
k3nSc3hTyQ
k3nSc3hTyR
k3nSc3yQ
k3nSc4hPyI
k3nSc4hPyN
k3nSc4hPyQ
k3nSc4hPyR
k3nSc4hTyI
k3nSc4hTyN
k3nSc4hTyQ
k3nSc4hTyR
k3nSc4yQ
k3nSc6hPyI
k3nSc6hPyN
k3nSc6hPyQ
k3nSc6hPyR
k3nSc6hTyI
k3nSc6hTyN
k3nSc6hTyQ
k3nSc6hTyR
k3nSc6yQ
k3nSc7hPyI
k3nSc7hPyN
k3nSc7hPyQ
k3nSc7hPyR
k3nSc7hTyI
k3nSc7hTyN
k3nSc7hTyQ
k3nSc7hTyR
k3nSc7yQ
k3p1gFnPc1xO
k3p1gFnPc2xO
k3p1gFnPc3xO
k3p1gFnPc4xO
k3p1gFnPc5xO
k3p1gFnPc6xO
k3p1gFnPc7xO
k3p1gFnSc1xO
k3p1gFnSc2xO
k3p1gFnSc3xO
k3p1gFnSc4xO
k3p1gFnSc5xO
k3p1gFnSc6xO
k3p1gFnSc7xO
k3p1gInPc1xO
k3p1gInPc2xO
k3p1gInPc3xO
k3p1gInPc4xO
k3p1gInPc5xO
k3p1gInPc6xO
k3p1gInPc7xO
k3p1gInSc1xO
k3p1gInSc2xO
k3p1gInSc3xO
k3p1gInSc4xO
k3p1gInSc5xO
k3p1gInSc6xO
k3p1gInSc7xO
k3p1gMnPc1xO
k3p1gMnPc2xO
k3p1gMnPc3xO
k3p1gMnPc4xO
k3p1gMnPc5xO
k3p1gMnPc6xO
k3p1gMnPc7xO
k3p1gMnSc1xO
k3p1gMnSc2xO
k3p1gMnSc3xO
k3p1gMnSc4xO
k3p1gMnSc5xO
k3p1gMnSc6xO
k3p1gMnSc7xO
k3p1gNnPc1xO
k3p1gNnPc2xO
k3p1gNnPc3xO
k3p1gNnPc4xO
k3p1gNnPc5xO
k3p1gNnPc6xO
k3p1gNnPc7xO
k3p1gNnSc1xO
k3p1gNnSc2xO
k3p1gNnSc3xO
k3p1gNnSc4xO
k3p1gNnSc5xO
k3p1gNnSc6xO
k3p1gNnSc7xO
k3p1nPc1xP
k3p1nPc2xP
k3p1nPc3xP
k3p1nPc4xP
k3p1nPc6xP
k3p1nPc7xP
k3p1nSc1xP
k3p1nSc2xP
k3p1nSc3xP
k3p1nSc4xP
k3p1nSc6xP
k3p1nSc7xP
k3p2gFnPc1xO
k3p2gFnPc2xO
k3p2gFnPc3xO
k3p2gFnPc4xO
k3p2gFnPc6xO
k3p2gFnPc7xO
k3p2gFnSc1xO
k3p2gFnSc2xO
k3p2gFnSc3xO
k3p2gFnSc4xO
k3p2gFnSc6xO
k3p2gFnSc7xO
k3p2gInPc1xO
k3p2gInPc2xO
k3p2gInPc3xO
k3p2gInPc4xO
k3p2gInPc6xO
k3p2gInPc7xO
k3p2gInSc1xO
k3p2gInSc2xO
k3p2gInSc3xO
k3p2gInSc4xO
k3p2gInSc6xO
k3p2gInSc7xO
k3p2gMnPc1xO
k3p2gMnPc2xO
k3p2gMnPc3xO
k3p2gMnPc4xO
k3p2gMnPc6xO
k3p2gMnPc7xO
k3p2gMnSc1xO
k3p2gMnSc2xO
k3p2gMnSc3xO
k3p2gMnSc4xO
k3p2gMnSc6xO
k3p2gMnSc7xO
k3p2gNnPc1xO
k3p2gNnPc2xO
k3p2gNnPc3xO
k3p2gNnPc4xO
k3p2gNnPc6xO
k3p2gNnPc7xO
k3p2gNnSc1xO
k3p2gNnSc2xO
k3p2gNnSc3xO
k3p2gNnSc4xO
k3p2gNnSc6xO
k3p2gNnSc7xO
k3p2nPc1xP
k3p2nPc2xP
k3p2nPc3xP
k3p2nPc4xP
k3p2nPc5xP
k3p2nPc6xP
k3p2nPc7xP
k3p2nSc1xP
k3p2nSc2xP
k3p2nSc3xP
k3p2nSc4xP
k3p2nSc5xP
k3p2nSc6xP
k3p2nSc7xP
k3p3gFnPc1xO
k3p3gFnPc1xOyR
k3p3gFnPc1xP
k3p3gFnPc2xO
k3p3gFnPc2xOyR
k3p3gFnPc2xP
k3p3gFnPc3xO
k3p3gFnPc3xOyR
k3p3gFnPc3xP
k3p3gFnPc4xO
k3p3gFnPc4xOyR
k3p3gFnPc4xP
k3p3gFnPc6xO
k3p3gFnPc6xOyR
k3p3gFnPc6xP
k3p3gFnPc7xO
k3p3gFnPc7xOyR
k3p3gFnPc7xP
k3p3gFnSc1xO
k3p3gFnSc1xOyR
k3p3gFnSc1xP
k3p3gFnSc2xO
k3p3gFnSc2xOyR
k3p3gFnSc2xP
k3p3gFnSc3xO
k3p3gFnSc3xOyR
k3p3gFnSc3xP
k3p3gFnSc4xO
k3p3gFnSc4xOyR
k3p3gFnSc4xP
k3p3gFnSc6xO
k3p3gFnSc6xOyR
k3p3gFnSc6xP
k3p3gFnSc7xO
k3p3gFnSc7xOyR
k3p3gFnSc7xP
k3p3gInPc1xO
k3p3gInPc1xOyR
k3p3gInPc1xP
k3p3gInPc2xO
k3p3gInPc2xOyR
k3p3gInPc2xP
k3p3gInPc3xO
k3p3gInPc3xOyR
k3p3gInPc3xP
k3p3gInPc4xO
k3p3gInPc4xOyR
k3p3gInPc4xP
k3p3gInPc6xO
k3p3gInPc6xOyR
k3p3gInPc6xP
k3p3gInPc7xO
k3p3gInPc7xOyR
k3p3gInPc7xP
k3p3gInSc1xO
k3p3gInSc1xOyR
k3p3gInSc1xP
k3p3gInSc2xO
k3p3gInSc2xOyR
k3p3gInSc2xP
k3p3gInSc3xO
k3p3gInSc3xOyR
k3p3gInSc3xP
k3p3gInSc4xO
k3p3gInSc4xOyR
k3p3gInSc4xP
k3p3gInSc6xO
k3p3gInSc6xOyR
k3p3gInSc6xP
k3p3gInSc7xO
k3p3gInSc7xOyR
k3p3gInSc7xP
k3p3gMnPc1xO
k3p3gMnPc1xOyR
k3p3gMnPc1xP
k3p3gMnPc2xO
k3p3gMnPc2xOyR
k3p3gMnPc2xP
k3p3gMnPc3xO
k3p3gMnPc3xOyR
k3p3gMnPc3xP
k3p3gMnPc4xO
k3p3gMnPc4xOyR
k3p3gMnPc4xP
k3p3gMnPc6xO
k3p3gMnPc6xOyR
k3p3gMnPc6xP
k3p3gMnPc7xO
k3p3gMnPc7xOyR
k3p3gMnPc7xP
k3p3gMnSc1xO
k3p3gMnSc1xOyR
k3p3gMnSc1xP
k3p3gMnSc2xO
k3p3gMnSc2xOyR
k3p3gMnSc2xP
k3p3gMnSc3xO
k3p3gMnSc3xOyR
k3p3gMnSc3xP
k3p3gMnSc4xO
k3p3gMnSc4xOyR
k3p3gMnSc4xP
k3p3gMnSc6xO
k3p3gMnSc6xOyR
k3p3gMnSc6xP
k3p3gMnSc7xO
k3p3gMnSc7xOyR
k3p3gMnSc7xP
k3p3gNnPc1xO
k3p3gNnPc1xOyR
k3p3gNnPc1xP
k3p3gNnPc2xO
k3p3gNnPc2xOyR
k3p3gNnPc2xP
k3p3gNnPc3xO
k3p3gNnPc3xOyR
k3p3gNnPc3xP
k3p3gNnPc4xO
k3p3gNnPc4xOyR
k3p3gNnPc4xP
k3p3gNnPc6xO
k3p3gNnPc6xOyR
k3p3gNnPc6xP
k3p3gNnPc7xO
k3p3gNnPc7xOyR
k3p3gNnPc7xP
k3p3gNnSc1xO
k3p3gNnSc1xOyR
k3p3gNnSc1xP
k3p3gNnSc2xO
k3p3gNnSc2xOyR
k3p3gNnSc2xP
k3p3gNnSc3xO
k3p3gNnSc3xOyR
k3p3gNnSc3xP
k3p3gNnSc4xO
k3p3gNnSc4xOyR
k3p3gNnSc4xP
k3p3gNnSc6xO
k3p3gNnSc6xOyR
k3p3gNnSc6xP
k3p3gNnSc7xO
k3p3gNnSc7xOyR
k3p3gNnSc7xP
k4c1
k4c1xC
k4c1xD
k4c1yI
k4c1yQ
k4c1yR
k4c2
k4c2xC
k4c2xD
k4c2yI
k4c2yQ
k4c2yR
k4c3
k4c3xC
k4c3xD
k4c3yI
k4c3yQ
k4c3yR
k4c4
k4c4xC
k4c4xD
k4c4yI
k4c4yQ
k4c4yR
k4c6
k4c6xC
k4c6xD
k4c6yI
k4c6yQ
k4c6yR
k4c7
k4c7xC
k4c7xD
k4c7yI
k4c7yQ
k4c7yR
k4gFnDc7xC
k4gFnDc7xCyI
k4gFnDc7xO
k4gFnDc7xOyI
k4gFnDc7xR
k4gFnDc7xRyI
k4gFnPc1xC
k4gFnPc1xCyI
k4gFnPc1xO
k4gFnPc1xOyI
k4gFnPc1xR
k4gFnPc1xRyI
k4gFnPc2xC
k4gFnPc2xCyI
k4gFnPc2xO
k4gFnPc2xOyI
k4gFnPc2xR
k4gFnPc2xRyI
k4gFnPc3xC
k4gFnPc3xCyI
k4gFnPc3xO
k4gFnPc3xOyI
k4gFnPc3xR
k4gFnPc3xRyI
k4gFnPc4xC
k4gFnPc4xCyI
k4gFnPc4xO
k4gFnPc4xOyI
k4gFnPc4xR
k4gFnPc4xRyI
k4gFnPc5xC
k4gFnPc5xO
k4gFnPc5xOyI
k4gFnPc5xR
k4gFnPc5xRyI
k4gFnPc6xC
k4gFnPc6xCyI
k4gFnPc6xO
k4gFnPc6xOyI
k4gFnPc6xR
k4gFnPc6xRyI
k4gFnPc7xC
k4gFnPc7xCyI
k4gFnPc7xO
k4gFnPc7xOyI
k4gFnPc7xR
k4gFnPc7xRyI
k4gFnSc1xC
k4gFnSc1xCyI
k4gFnSc1xO
k4gFnSc1xOyI
k4gFnSc1xR
k4gFnSc1xRyI
k4gFnSc2xC
k4gFnSc2xCyI
k4gFnSc2xO
k4gFnSc2xOyI
k4gFnSc2xR
k4gFnSc2xRyI
k4gFnSc3xC
k4gFnSc3xCyI
k4gFnSc3xO
k4gFnSc3xOyI
k4gFnSc3xR
k4gFnSc3xRyI
k4gFnSc4xC
k4gFnSc4xCyI
k4gFnSc4xO
k4gFnSc4xOyI
k4gFnSc4xR
k4gFnSc4xRyI
k4gFnSc5xC
k4gFnSc5xO
k4gFnSc5xOyI
k4gFnSc5xR
k4gFnSc5xRyI
k4gFnSc6xC
k4gFnSc6xCyI
k4gFnSc6xO
k4gFnSc6xOyI
k4gFnSc6xR
k4gFnSc6xRyI
k4gFnSc7xC
k4gFnSc7xCyI
k4gFnSc7xO
k4gFnSc7xOyI
k4gFnSc7xR
k4gFnSc7xRyI
k4gInDc7xC
k4gInPc1xC
k4gInPc1xCyI
k4gInPc1xO
k4gInPc1xOyI
k4gInPc1xR
k4gInPc1xRyI
k4gInPc2xC
k4gInPc2xCyI
k4gInPc2xO
k4gInPc2xOyI
k4gInPc2xR
k4gInPc2xRyI
k4gInPc3xC
k4gInPc3xCyI
k4gInPc3xO
k4gInPc3xOyI
k4gInPc3xR
k4gInPc3xRyI
k4gInPc4xC
k4gInPc4xCyI
k4gInPc4xO
k4gInPc4xOyI
k4gInPc4xR
k4gInPc4xRyI
k4gInPc5xC
k4gInPc5xO
k4gInPc5xOyI
k4gInPc5xR
k4gInPc5xRyI
k4gInPc6xC
k4gInPc6xCyI
k4gInPc6xO
k4gInPc6xOyI
k4gInPc6xR
k4gInPc6xRyI
k4gInPc7xC
k4gInPc7xCyI
k4gInPc7xO
k4gInPc7xOyI
k4gInPc7xR
k4gInPc7xRyI
k4gInSc1xC
k4gInSc1xCyI
k4gInSc1xO
k4gInSc1xOyI
k4gInSc1xR
k4gInSc1xRyI
k4gInSc2xC
k4gInSc2xCyI
k4gInSc2xO
k4gInSc2xOyI
k4gInSc2xR
k4gInSc2xRyI
k4gInSc3xC
k4gInSc3xCyI
k4gInSc3xO
k4gInSc3xOyI
k4gInSc3xR
k4gInSc3xRyI
k4gInSc4xC
k4gInSc4xCyI
k4gInSc4xO
k4gInSc4xOyI
k4gInSc4xR
k4gInSc4xRyI
k4gInSc5xC
k4gInSc5xO
k4gInSc5xOyI
k4gInSc5xR
k4gInSc5xRyI
k4gInSc6xC
k4gInSc6xCyI
k4gInSc6xO
k4gInSc6xOyI
k4gInSc6xR
k4gInSc6xRyI
k4gInSc7xC
k4gInSc7xCyI
k4gInSc7xO
k4gInSc7xOyI
k4gInSc7xR
k4gInSc7xRyI
k4gMnDc7xC
k4gMnPc1xC
k4gMnPc1xCyI
k4gMnPc1xO
k4gMnPc1xOyI
k4gMnPc1xR
k4gMnPc1xRyI
k4gMnPc2xC
k4gMnPc2xCyI
k4gMnPc2xO
k4gMnPc2xOyI
k4gMnPc2xR
k4gMnPc2xRyI
k4gMnPc3xC
k4gMnPc3xCyI
k4gMnPc3xO
k4gMnPc3xOyI
k4gMnPc3xR
k4gMnPc3xRyI
k4gMnPc4xC
k4gMnPc4xCyI
k4gMnPc4xO
k4gMnPc4xOyI
k4gMnPc4xR
k4gMnPc4xRyI
k4gMnPc5xC
k4gMnPc5xO
k4gMnPc5xOyI
k4gMnPc5xR
k4gMnPc5xRyI
k4gMnPc6xC
k4gMnPc6xCyI
k4gMnPc6xO
k4gMnPc6xOyI
k4gMnPc6xR
k4gMnPc6xRyI
k4gMnPc7xC
k4gMnPc7xCyI
k4gMnPc7xO
k4gMnPc7xOyI
k4gMnPc7xR
k4gMnPc7xRyI
k4gMnSc1xC
k4gMnSc1xCyI
k4gMnSc1xO
k4gMnSc1xOyI
k4gMnSc1xR
k4gMnSc1xRyI
k4gMnSc2xC
k4gMnSc2xCyI
k4gMnSc2xO
k4gMnSc2xOyI
k4gMnSc2xR
k4gMnSc2xRyI
k4gMnSc3xC
k4gMnSc3xCyI
k4gMnSc3xO
k4gMnSc3xOyI
k4gMnSc3xR
k4gMnSc3xRyI
k4gMnSc4xC
k4gMnSc4xCyI
k4gMnSc4xO
k4gMnSc4xOyI
k4gMnSc4xR
k4gMnSc4xRyI
k4gMnSc5xC
k4gMnSc5xO
k4gMnSc5xOyI
k4gMnSc5xR
k4gMnSc5xRyI
k4gMnSc6xC
k4gMnSc6xCyI
k4gMnSc6xO
k4gMnSc6xOyI
k4gMnSc6xR
k4gMnSc6xRyI
k4gMnSc7xC
k4gMnSc7xCyI
k4gMnSc7xO
k4gMnSc7xOyI
k4gMnSc7xR
k4gMnSc7xRyI
k4gNnDc7xC
k4gNnDc7xCyI
k4gNnDc7xO
k4gNnDc7xOyI
k4gNnDc7xR
k4gNnDc7xRyI
k4gNnPc1xC
k4gNnPc1xCyI
k4gNnPc1xO
k4gNnPc1xOyI
k4gNnPc1xR
k4gNnPc1xRyI
k4gNnPc2xC
k4gNnPc2xCyI
k4gNnPc2xO
k4gNnPc2xOyI
k4gNnPc2xR
k4gNnPc2xRyI
k4gNnPc3xC
k4gNnPc3xCyI
k4gNnPc3xO
k4gNnPc3xOyI
k4gNnPc3xR
k4gNnPc3xRyI
k4gNnPc4xC
k4gNnPc4xCyI
k4gNnPc4xO
k4gNnPc4xOyI
k4gNnPc4xR
k4gNnPc4xRyI
k4gNnPc5xC
k4gNnPc5xO
k4gNnPc5xOyI
k4gNnPc5xR
k4gNnPc5xRyI
k4gNnPc6xC
k4gNnPc6xCyI
k4gNnPc6xO
k4gNnPc6xOyI
k4gNnPc6xR
k4gNnPc6xRyI
k4gNnPc7xC
k4gNnPc7xCyI
k4gNnPc7xO
k4gNnPc7xOyI
k4gNnPc7xR
k4gNnPc7xRyI
k4gNnSc1xC
k4gNnSc1xCyI
k4gNnSc1xO
k4gNnSc1xOyI
k4gNnSc1xR
k4gNnSc1xRyI
k4gNnSc2xC
k4gNnSc2xCyI
k4gNnSc2xO
k4gNnSc2xOyI
k4gNnSc2xR
k4gNnSc2xRyI
k4gNnSc3xC
k4gNnSc3xCyI
k4gNnSc3xO
k4gNnSc3xOyI
k4gNnSc3xR
k4gNnSc3xRyI
k4gNnSc4xC
k4gNnSc4xCyI
k4gNnSc4xO
k4gNnSc4xOyI
k4gNnSc4xR
k4gNnSc4xRyI
k4gNnSc5xC
k4gNnSc5xO
k4gNnSc5xOyI
k4gNnSc5xR
k4gNnSc5xRyI
k4gNnSc6xC
k4gNnSc6xCyI
k4gNnSc6xO
k4gNnSc6xOyI
k4gNnSc6xR
k4gNnSc6xRyI
k4gNnSc7xC
k4gNnSc7xCyI
k4gNnSc7xO
k4gNnSc7xOyI
k4gNnSc7xR
k4gNnSc7xRyI
k4xCyI
k4xO
k5eAaBmAgFnP
k5eAaBmAgFnS
k5eAaBmAgInP
k5eAaBmAgInS
k5eAaBmAgMnP
k5eAaBmAgMnS
k5eAaBmAgNnP
k5eAaBmAgNnS
k5eAaBmDgFnP
k5eAaBmDgFnS
k5eAaBmDgInP
k5eAaBmDgInS
k5eAaBmDgMnP
k5eAaBmDgMnS
k5eAaBmDgNnP
k5eAaBmDgNnS
k5eAaBmF
k5eAaBmIp1nP
k5eAaBmIp1nS
k5eAaBmIp2nP
k5eAaBmIp2nS
k5eAaBmIp3nP
k5eAaBmIp3nS
k5eAaBmNgFnP
k5eAaBmNgFnS
k5eAaBmNgInP
k5eAaBmNgInS
k5eAaBmNgMnP
k5eAaBmNgMnS
k5eAaBmNgNnP
k5eAaBmNgNnS
k5eAaBmRp1nP
k5eAaBmRp2nP
k5eAaBmRp2nS
k5eAaBmSgFnP
k5eAaBmSgFnS
k5eAaBmSgInP
k5eAaBmSgInS
k5eAaBmSgMnP
k5eAaBmSgMnS
k5eAaBmSgNnP
k5eAaBmSgNnS
k5eAaImAgFnP
k5eAaImAgFnS
k5eAaImAgInP
k5eAaImAgInS
k5eAaImAgMnP
k5eAaImAgMnS
k5eAaImAgNnP
k5eAaImAgNnS
k5eAaImBp1nP
k5eAaImBp1nS
k5eAaImBp2nP
k5eAaImBp2nS
k5eAaImBp3nP
k5eAaImBp3nS
k5eAaImDgFnP
k5eAaImDgFnS
k5eAaImDgInP
k5eAaImDgInS
k5eAaImDgMnP
k5eAaImDgMnS
k5eAaImDgNnP
k5eAaImDgNnS
k5eAaImF
k5eAaImIp1nP
k5eAaImIp1nS
k5eAaImIp2nP
k5eAaImIp2nS
k5eAaImIp3nP
k5eAaImIp3nS
k5eAaImNgFnP
k5eAaImNgFnS
k5eAaImNgInP
k5eAaImNgInS
k5eAaImNgMnP
k5eAaImNgMnS
k5eAaImNgNnP
k5eAaImNgNnS
k5eAaImRp1nP
k5eAaImRp2nP
k5eAaImRp2nS
k5eAaImSgFnP
k5eAaImSgFnS
k5eAaImSgInP
k5eAaImSgInS
k5eAaImSgMnP
k5eAaImSgMnS
k5eAaImSgNnP
k5eAaImSgNnS
k5eAaPmAgFnP
k5eAaPmAgFnS
k5eAaPmAgInP
k5eAaPmAgInS
k5eAaPmAgMnP
k5eAaPmAgMnS
k5eAaPmAgNnP
k5eAaPmAgNnS
k5eAaPmDgFnP
k5eAaPmDgFnS
k5eAaPmDgInP
k5eAaPmDgInS
k5eAaPmDgMnP
k5eAaPmDgMnS
k5eAaPmDgNnP
k5eAaPmDgNnS
k5eAaPmF
k5eAaPmIp1nP
k5eAaPmIp1nS
k5eAaPmIp2nP
k5eAaPmIp2nS
k5eAaPmIp3nP
k5eAaPmIp3nS
k5eAaPmNgFnP
k5eAaPmNgFnS
k5eAaPmNgInP
k5eAaPmNgInS
k5eAaPmNgMnP
k5eAaPmNgMnS
k5eAaPmNgNnP
k5eAaPmNgNnS
k5eAaPmRp1nP
k5eAaPmRp2nP
k5eAaPmRp2nS
k5eAaPmSgFnP
k5eAaPmSgFnS
k5eAaPmSgInP
k5eAaPmSgInS
k5eAaPmSgMnP
k5eAaPmSgMnS
k5eAaPmSgNnP
k5eAaPmSgNnS
k5eNaBmAgFnP
k5eNaBmAgFnS
k5eNaBmAgInP
k5eNaBmAgInS
k5eNaBmAgMnP
k5eNaBmAgMnS
k5eNaBmAgNnP
k5eNaBmAgNnS
k5eNaBmDgFnP
k5eNaBmDgFnS
k5eNaBmDgInP
k5eNaBmDgInS
k5eNaBmDgMnP
k5eNaBmDgMnS
k5eNaBmDgNnP
k5eNaBmDgNnS
k5eNaBmF
k5eNaBmIp1nP
k5eNaBmIp1nS
k5eNaBmIp2nP
k5eNaBmIp2nS
k5eNaBmIp3nP
k5eNaBmIp3nS
k5eNaBmNgFnP
k5eNaBmNgFnS
k5eNaBmNgInP
k5eNaBmNgInS
k5eNaBmNgMnP
k5eNaBmNgMnS
k5eNaBmNgNnP
k5eNaBmNgNnS
k5eNaBmRp1nP
k5eNaBmRp2nP
k5eNaBmRp2nS
k5eNaBmSgFnP
k5eNaBmSgFnS
k5eNaBmSgInP
k5eNaBmSgInS
k5eNaBmSgMnP
k5eNaBmSgMnS
k5eNaBmSgNnP
k5eNaBmSgNnS
k5eNaImAgFnP
k5eNaImAgFnS
k5eNaImAgInP
k5eNaImAgInS
k5eNaImAgMnP
k5eNaImAgMnS
k5eNaImAgNnP
k5eNaImAgNnS
k5eNaImBp1nP
k5eNaImBp1nS
k5eNaImBp2nP
k5eNaImBp2nS
k5eNaImBp3nP
k5eNaImBp3nS
k5eNaImDgFnP
k5eNaImDgFnS
k5eNaImDgInP
k5eNaImDgInS
k5eNaImDgMnP
k5eNaImDgMnS
k5eNaImDgNnP
k5eNaImDgNnS
k5eNaImF
k5eNaImIp1nP
k5eNaImIp1nS
k5eNaImIp2nP
k5eNaImIp2nS
k5eNaImIp3nP
k5eNaImIp3nS
k5eNaImNgFnP
k5eNaImNgFnS
k5eNaImNgInP
k5eNaImNgInS
k5eNaImNgMnP
k5eNaImNgMnS
k5eNaImNgNnP
k5eNaImNgNnS
k5eNaImRp1nP
k5eNaImRp2nP
k5eNaImRp2nS
k5eNaImSgFnP
k5eNaImSgFnS
k5eNaImSgInP
k5eNaImSgInS
k5eNaImSgMnP
k5eNaImSgMnS
k5eNaImSgNnP
k5eNaImSgNnS
k5eNaPmAgFnP
k5eNaPmAgFnS
k5eNaPmAgInP
k5eNaPmAgInS
k5eNaPmAgMnP
k5eNaPmAgMnS
k5eNaPmAgNnP
k5eNaPmAgNnS
k5eNaPmDgFnP
k5eNaPmDgFnS
k5eNaPmDgInP
k5eNaPmDgInS
k5eNaPmDgMnP
k5eNaPmDgMnS
k5eNaPmDgNnP
k5eNaPmDgNnS
k5eNaPmF
k5eNaPmIp1nP
k5eNaPmIp1nS
k5eNaPmIp2nP
k5eNaPmIp2nS
k5eNaPmIp3nP
k5eNaPmIp3nS
k5eNaPmNgFnP
k5eNaPmNgFnS
k5eNaPmNgInP
k5eNaPmNgInS
k5eNaPmNgMnP
k5eNaPmNgMnS
k5eNaPmNgNnP
k5eNaPmNgNnS
k5eNaPmRp1nP
k5eNaPmRp2nP
k5eNaPmRp2nS
k5eNaPmSgFnP
k5eNaPmSgFnS
k5eNaPmSgInP
k5eNaPmSgInS
k5eNaPmSgMnP
k5eNaPmSgMnS
k5eNaPmSgNnP
k5eNaPmSgNnS
k6eAd1
k6eAd1tCtLtTxD
k6eAd1tCyQ
k6eAd1tD
k6eAd1tDtS
k6eAd1tL
k6eAd1tLtM
k6eAd1tLtMtT
k6eAd1tLtQ
k6eAd1tLtQtTxD
k6eAd1tLtT
k6eAd1tLtTxD
k6eAd1tLxD
k6eAd1tLyN
k6eAd1tLyQ
k6eAd1tM
k6eAd1tMtQ
k6eAd1tMtQxD
k6eAd1tMtT
k6eAd1tMxD
k6eAd1tMyN
k6eAd1tQ
k6eAd1tQtS
k6eAd1tQxD
k6eAd1tS
k6eAd1tT
k6eAd1tTxD
k6eAd1tTxT
k6eAd1xD
k6eAd1xT
k6eAd1yI
k6eAd1yN
k6eAd1yQ
k6eAd1yR
k6eAd2
k6eAd2tL
k6eAd2tLtM
k6eAd2tLtQ
k6eAd2tM
k6eAd2tMtQ
k6eAd2tMtT
k6eAd2tQ
k6eAd2tT
k6eAd3
k6eAd3tL
k6eAd3tLtM
k6eAd3tLtQ
k6eAd3tM
k6eAd3tMtQ
k6eAd3tMtT
k6eAd3tQ
k6eAd3tT
k6eNd1
k6eNd1tD
k6eNd1tDtS
k6eNd1tL
k6eNd1tLtM
k6eNd1tLtQ
k6eNd1tM
k6eNd1tMtT
k6eNd1tQ
k6eNd1tQtS
k6eNd1tS
k6eNd1tT
k6eNd2
k6eNd2tL
k6eNd2tLtQ
k6eNd2tM
k6eNd2tMtT
k6eNd2tQ
k6eNd2tT
k6eNd3
k6eNd3tL
k6eNd3tLtQ
k6eNd3tM
k6eNd3tMtT
k6eNd3tQ
k6eNd3tT
k7c1
k7c2
k7c3
k7c4
k7c6
k7c7
k8xC
k8xS
k9
kA
kYmCp1nP
kYmCp1nS
kYmCp2nP
kYmCp2nS
kYmCp3nP
kYmCp3nS
end_of_list
    ;
    my @list = split(/\r?\n/, $list);
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::CS::Ajka - Driver for the tagset of the Czech morphological analyzers Ajka and Majka (Masaryk University in Brno).

=head1 VERSION

version 3.004

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::CS::Ajka;
  my $driver = Lingua::Interset::Tagset::CS::Ajka->new();
  my $fs = $driver->decode('k1gMnSc1');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('cs::ajka', 'k1gMnSc1');

=head1 DESCRIPTION

Interset driver for the tagsets of the Czech morphological analyzers Ajka and
Majka (from the Masaryk University in Brno).

Multiple different flavors of the tagset have been used in different tools.
The Ajka analyzer was written by Radek Sedláček as part of his master thesis
(1999). In 2009, a the tool was completely rewritten by Pavel Šmerk and it got
a new name, Majka. It still used more or less the same tagset. In 2011,
a significant revision of the tagset was announced; the new versiou should be
called 2.0, the old tagset (all flavors) would be retroactively called 1.0.
According to this numbering, the Czech lexical database that is available for
download with Majka in July 2014 is still 1.0. That is also the version that
this driver assumes.

For more on Ajka, see L<http://nlp.fi.muni.cz/projekty/ajka/ajkacz.htm>.
For more on the original tagset of Ajka, see L<http://nlp.fi.muni.cz/projekty/ajka/tags.pdf>.
For more on the proposed version 2.0 of the tagset (not covered by this driver),
see L<http://raslan2011.nlp-consulting.net/program/paper05.pdf?attredirects=0>.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Petr Pořízka,
Markus Schäfer,
Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
