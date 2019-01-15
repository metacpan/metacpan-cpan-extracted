# ABSTRACT: Driver for the Czech tagset of the Prague Spoken Corpus (Pražský mluvený korpus).
# Copyright © 2009, 2010, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::CS::Pmk;
use strict;
use warnings;
our $VERSION = '3.013';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset';



has 'atoms'       => ( isa => 'HashRef', is => 'ro', builder => '_create_atoms',       lazy => 1 );
has 'feature_map' => ( isa => 'HashRef', is => 'ro', builder => '_create_feature_map', lazy => 1 );



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'cs::pmk';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for 11 surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # PART OF SPEECH ####################
    $atoms{pos} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'pos',
        'decode_map' =>
        {
            '1' => ['pos' => 'noun'],
            '2' => ['pos' => 'adj'],
            '3' => ['pos' => 'noun|adj', 'prontype' => 'prn'],
            '4' => ['pos' => 'num'],
            '5' => ['pos' => 'verb'],
            '6' => ['pos' => 'adv'],
            '7' => ['pos' => 'adp', 'adpostype' => 'prep'],
            '8' => ['pos' => 'conj'],
            '9' => ['pos' => 'int'],
            '0' => ['pos' => 'part'],
            'F' => ['other' => {'pos' => 'F'}], # idiom (it may behave syntactically as various parts of speech)
            'J' => ['other' => {'pos' => 'J'}] # other
        },
        'encode_map' =>

            { 'other/pos' => { 'F' => 'F',
                               'J' => 'J',
                               '@' => { 'pos' => { 'noun' => { 'prontype' => { ''  => { 'nountype' => { 'prop' => 'J',
                                                                                                        '@'    => '1' }},
                                                                               '@' => '3' }},
                                                   'adj'  => { 'numtype' => { ''  => { 'prontype' => { ''  => '2',
                                                                                                       '@' => '3' }},
                                                                              '@' => '4' }},
                                                   'num'  => '4',
                                                   'verb' => '5',
                                                   'adv'  => { 'numtype' => { ''  => '6',
                                                                              '@' => '4' }},
                                                   'adp'  => '7',
                                                   'conj' => '8',
                                                   'int'  => '9',
                                                   'part' => '0' }}}}
    );
    # GENDER ####################
    # Encoding of gender varies depending on context (part of speech).
    # Functions _surface_to_internal_gender() or _internal_to_surface_gender() must be used.
    $atoms{gender} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'gender',
        'decode_map' =>
        {
            'M' => ['gender' => 'masc', 'animacy' => 'anim'],
            'I' => ['gender' => 'masc', 'animacy' => 'inan'],
            'F' => ['gender' => 'fem'],
            'N' => ['gender' => 'neut'],
            # Some pronouns ('já', 'ty') do not distinguish grammatical gender and have this value.
            # Note that this value ('B') is not identical to the general "unknown gender" ('X').
            'B' => ['other' => {'gender' => 'bezrodé'}],
            'X' => []
        },
        'encode_map' =>

            { 'gender' => { 'masc' => { 'animacy' => { 'inan' => 'I',
                                                       '@'    => 'M' }},
                            'fem'  => 'F',
                            'neut' => 'N',
                            '@'    => { 'other/gender' => { 'bezrodé' => 'B',
                                                            '@'       => 'X' }}}}
    );
    # NUMBER ####################
    # Encoding of number varies depending on context (part of speech).
    # Functions _surface_to_internal_number() or _internal_to_surface_number() must be used.
    $atoms{number} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'number',
        'decode_map' =>
        {
            'S' => ['number' => 'sing'],
            'P' => ['number' => 'plur'],
            'T' => ['number' => 'ptan'],
            'D' => ['number' => 'dual'],
            'C' => ['number' => 'coll'],
            # "Vykání": using plural to address a single person in a polite manner.
            'V' => ['number' => 'plur', 'polite' => 'form'],
            'X' => []
        },
        'encode_map' =>

            { 'number' => { 'sing' => 'S',
                            'dual' => 'D',
                            'plur'  => { 'polite' => { 'form' => 'V',
                                                       '@'    => 'P' }},
                            'ptan' => 'T',
                            'coll' => 'C',
                            '@'    => 'X' }}
    );
    # GENDER AND NUMBER OF PARTICIPLES ####################
    $atoms{participle_gender_number} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'participle_gender_number',
        'decode_map' =>
        {
            '1' => ['gender' => 'masc', 'animacy' => 'anim', 'number' => 'sing'],
            '2' => ['gender' => 'masc', 'animacy' => 'inan', 'number' => 'sing'],
            '3' => ['gender' => 'fem', 'number' => 'sing'],
            '4' => ['gender' => 'neut', 'number' => 'sing'],
            '5' => ['gender' => 'masc', 'animacy' => 'anim', 'number' => 'plur'],
            '6' => ['gender' => 'masc', 'animacy' => 'inan', 'number' => 'plur'],
            '7' => ['gender' => 'fem', 'number' => 'plur'],
            '8' => ['gender' => 'neut', 'number' => 'plur'],
            # - -> neurčuje se / not specified => empty value
            # 9 => nelze určit / cannot specify => empty value
            # If this is not a participle number may still be specified but will be encoded elsewhere; gender will be '-'.
            # It can also happen that person+number is 3rd+singular (5=3) and gender+number is unknown (9=9). Example: "nařízíno"
            '9' => ['other' => {'gender' => '9'}],
            '-' => ['other' => {'gender' => '-'}]
        },
        'encode_map' =>

            { 'other/gender' => { '9' => '9',
                                  '-' => '-',
                                  '@' => { 'number' => { 'sing' => { 'gender' => { 'masc' => { 'animacy' => { 'inan' => '2',
                                                                                                              '@'    => '1' }},
                                                                                   'fem'  => '3',
                                                                                   '@'    => '4' }},
                                                         'plur' => { 'gender' => { 'masc' => { 'animacy' => { 'inan' => '6',
                                                                                                              '@'    => '5' }},
                                                                                   'fem'  => '7',
                                                                                   '@'    => '8' }},
                                                         '@'    => '9' }}}}
    );
    # PERSON AND NUMBER OF VERBS ####################
    $atoms{person_number} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'person_number',
        'decode_map' =>
        {
            '1' => ['person' => '1', 'number' => 'sing'],
            '2' => ['person' => '2', 'number' => 'sing'],
            '3' => ['person' => '3', 'number' => 'sing'],
            '4' => ['person' => '1', 'number' => 'plur'],
            '5' => ['person' => '2', 'number' => 'plur'],
            '6' => ['person' => '3', 'number' => 'plur'],
            '7' => ['verbform' => 'inf', 'voice' => 'act'],
            '8' => ['verbform' => 'inf', 'voice' => 'pass'],
            # "non-personal" (neosobní) usage of the third person
            # "říkalo se", "říká se": subject "ono" (it) is a filler that does not denote any semantic object
            '9' => ['person' => '3', 'number' => 'sing', 'other' => {'person' => 'nonpers'}],
            # non-personal plural
            # only two occurrences in the whole corpus: "řikali", "hlásaj"
            '0' => ['person' => '3', 'number' => 'plur', 'other' => {'person' => 'nonpers'}],
            # - -> neurčuje se / not specified => empty value
            # can conflict with participle gender+number
            '-' => ['other' => {'person' => '-'}]
        },
        'encode_map' =>

            { 'other/person' => { '-'       => '-',
                                  'nonpers' => { 'number' => { 'sing' => '9',
                                                               'plur' => '0',
                                                               '@'    => '-' }},
                                  '@'       => { 'verbform' => { 'inf' => { 'voice' => { 'pass' => '8',
                                                                                         '@'    => '7' }},
                                                                 '@'   => { 'number' => { 'plur' => { 'person' => { '1' => '4',
                                                                                                                    '2' => '5',
                                                                                                                    '@' => '6' }},
                                                                                          'sing' => { 'person' => { '1' => '1',
                                                                                                                    '2' => '2',
                                                                                                                    '@' => '3' }},
                                                                                          '@'    => '-' }}}}}}
    );
    # CASE ####################
    $atoms{case} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'case',
        'decode_map' =>
        {
            '1' => ['case' => 'nom'],
            '2' => ['case' => 'gen'],
            '3' => ['case' => 'dat'],
            '4' => ['case' => 'acc'],
            '5' => ['case' => 'voc'],
            '6' => ['case' => 'loc'],
            '7' => ['case' => 'ins'],
            # valency-based case of prepositions = "other" ... 8
            '8' => ['other' => {'valency_case' => 'other'}],
            # case of nouns, adjective etc. "cannot specify or indeclinable" ... 9
            '9' => ['other' => {'case' => 'indeclinable'}]
        },
        'encode_map' =>

            { 'case' => { 'nom' => '1',
                          'gen' => '2',
                          'dat' => '3',
                          'acc' => '4',
                          'voc' => '5',
                          'loc' => '6',
                          'ins' => '7',
                          '@'   => { 'other/valency_case' => { 'other' => '8',
                                                               '@'     => { 'pos' => { 'adp' => '8',
                                                                                       '@'   => '9' }}}}}}
    );
    # COUNTED CASE ####################
    # (pád počítané jmenné fráze)
    $atoms{counted_case} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'counted_case',
        'decode_map' =>
        {
            '1' => ['other' => {'ccase' => 'nom'}],
            '2' => ['other' => {'ccase' => 'gen'}],
            '3' => ['other' => {'ccase' => 'dat'}],
            '4' => ['other' => {'ccase' => 'acc'}],
            '5' => ['other' => {'ccase' => 'voc'}],
            '6' => ['other' => {'ccase' => 'loc'}],
            '7' => ['other' => {'ccase' => 'ins'}],
            '9' => []
        },
        'encode_map' =>

            { 'other/ccase' => { 'nom' => '1',
                                 'gen' => '2',
                                 'dat' => '3',
                                 'acc' => '4',
                                 'voc' => '5',
                                 'loc' => '6',
                                 'ins' => '7',
                                 '@'   => '9' }}
    );
    # DEGREE OF COMPARISON ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'tagset' => 'cs::pmk',
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            '-' => 'pos',
            '2' => 'cmp',
            '3' => 'sup'
        }
    );
    # MOOD, TENSE AND VOICE ####################
    $atoms{mood_tense_voice} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'mood_tense_voice',
        'decode_map' =>
        {
            '1' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres', 'voice' => 'act'],  # dělá
            '2' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres', 'voice' => 'pass'], # je dělán
            '3' => ['verbform' => 'fin', 'mood' => 'cnd', 'tense' => 'pres', 'voice' => 'act'],  # dělal by
            '4' => ['verbform' => 'fin', 'mood' => 'cnd', 'tense' => 'pres', 'voice' => 'pass'], # byl by dělán
            '5' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'past', 'voice' => 'act'],  # dělal
            '6' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'past', 'voice' => 'pass'], # byl dělán
            '7' => ['verbform' => 'fin', 'mood' => 'cnd', 'tense' => 'past', 'voice' => 'act'],  # byl by dělal
            '8' => ['verbform' => 'fin', 'mood' => 'cnd', 'tense' => 'past', 'voice' => 'pass'], # byl by byl dělán
            '9' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'fut',  'voice' => 'act'],  # bude dělat
            '0' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'fut',  'voice' => 'pass']  # bude dělán
        },
        'encode_map' =>

            { 'verbform' => { 'conv' => '-',
                              '@'     => { 'mood' => { 'cnd' => { 'tense' => { 'past' => { 'voice' => { 'pass' => '8',
                                                                                                        '@'    => '7' }},
                                                                               '@'    => { 'voice' => { 'pass' => '4',
                                                                                                        '@'    => '3' }}}},
                                                       '@'   => { 'tense' => { 'fut'  => { 'voice' => { 'pass' => '0',
                                                                                                        '@'    => '9' }},
                                                                               'past' => { 'voice' => { 'pass' => '6',
                                                                                                        '@'    => '5' }},
                                                                               'pres' => { 'voice' => { 'pass' => '2',
                                                                                                        '@'    => '1' }},
                                                                               '@'    => '-' }}}}}}
    );
    # IMPERATIVE OR NON-FINITE VERB FORM ####################
    $atoms{nonfinite_verb_form} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'nonfinite_verb_form',
        'decode_map' =>
        {
            '1' => ['verbform' => 'fin', 'mood' => 'imp', 'voice' => 'act'],     # dělej
            '2' => ['verbform' => 'fin', 'mood' => 'imp', 'voice' => 'pass'],    # buď dělán
            '3' => ['verbform' => 'part', 'voice' => 'pass'],                    # dělán
            '4' => ['verbform' => 'conv', 'tense' => 'pres', 'voice' => 'act'],  # dělaje
            '5' => ['verbform' => 'conv', 'tense' => 'pres', 'voice' => 'pass'], # jsa dělán
            '6' => ['verbform' => 'conv', 'tense' => 'past', 'voice' => 'act'],  # udělav
            '7' => ['verbform' => 'conv', 'tense' => 'past', 'voice' => 'pass']  # byv udělán
        },
        'encode_map' =>

            { 'mood' => { 'imp' => { 'voice' => { 'pass' => '2',
                                                  '@'    => '1' }},
                          '@'   => { 'verbform' => { 'conv' => { 'tense' => { 'past' => { 'voice' => { 'pass' => '7',
                                                                                                       '@'    => '6' }},
                                                                              '@'    => { 'voice' => { 'pass' => '5',
                                                                                                       '@'    => '4' }}}},
                                                     'part'  => { 'voice' => { 'pass' => '3',
                                                                               '@'    => '-' }},
                                                     '@'     => '-' }}}}
    );
    # POLARITY ####################
    $atoms{polarity} = $self->create_simple_atom
    (
        'tagset' => 'cs::pmk',
        'intfeature' => 'polarity',
        'simple_decode_map' =>
        {
            '1' => 'pos',
            '2' => 'neg'
        }
    );
    # STYLE ####################
    $atoms{style} = $self->create_simple_atom
    (
        'tagset' => 'cs::pmk',
        'intfeature' => 'style',
        'simple_decode_map' =>
        {
            # základní, mluvený, neformální
            '1' => 'coll',
            # neutrální, mluvený, psaný
            '2' => 'norm',
            # knižní
            '3' => 'form',
            # vulgární
            '4' => 'vulg'
        },
        'encode_default' => '2'
    );
    # NOUN TYPE ####################
    # Noun types in PMK mostly reflect how (from what part of speech) the noun was derived.
    $atoms{noun_type} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'noun_type',
        'decode_map' =>
        {
            # běžné: konstruktér, rodina, auto
            '1' => [],
            # adjektivní: ženská, vedoucí, nadřízenej
            '2' => ['other' => {'nountype' => 'adj'}],
            # zájmenné: naši, vaši
            '3' => ['other' => {'nountype' => 'pron'}],
            # číslovkové: dvojka, devítka, šestsettřináctka
            '4' => ['other' => {'nountype' => 'num'}],
            # slovesné: postavení, bití, chování
            '5' => ['other' => {'nountype' => 'verb'}],
            # slovesné zvratné: věnování se; note: the tag is assigned to "věnování" while "se" has an empty tag
            '6' => ['other' => {'nountype' => 'verb'}, 'reflex' => 'yes'],
            # zkratkové slovo: ó dé eska; note: the tag is assigned to "ó" while "dé" and "eska" have empty tags
            # This is not the same as an abbreviated noun.
            '7' => ['other' => {'nountype' => 'abbr'}],
            # nesklonné: apartmá, interview, gró
            '9' => ['other' => {'nountype' => 'indecl'}]
        },
        'encode_map' =>

            { 'reflex' => { 'yes' => '6',
                            '@'      => { 'other/nountype' => { 'adj'    => '2',
                                                                'pron'   => '3',
                                                                'num'    => '4',
                                                                'verb'   => '5',
                                                                'abbr'   => '7',
                                                                'indecl' => '9',
                                                                '@'      => '1' }}}}
    );
    # ADJECTIVE TYPE ####################
    $atoms{adjective_type} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'adjective_type',
        'decode_map' =>
        {
            # nespecifické: jiný, prázdnej, řádová
            '1' => [],
            # slovesné: ovlivněný, skličující, vyspělý
            '2' => ['other' => {'adjtype' => 'verb'}],
            # přivlastňovací: Martinův, tátový, Klárčiny
            '3' => ['poss' => 'yes']
        },
        'encode_map' =>

            { 'poss' => { 'yes' => '3',
                          '@'    => { 'other/adjtype' => { 'verb' => '2',
                                                           '@'    => '1' }}}}
    );
    # ADJECTIVE SUBTYPE ####################
    $atoms{adjective_subtype} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'adjective_subtype',
        'decode_map' =>
        {
            # departicipiální prosté: přeloženej, shořelej, naloženej
            '1' => ['verbform' => 'part'],
            # zvratné: blížícím se, se živícim, drolící se
            '2' => ['reflex' => 'yes'],
            # jmenná forma sg neutra: (chybná anotace???) prioritní, vytížený, obligátní
            '3' => ['variant' => 'short', 'gender' => 'neut', 'number' => 'sing'],
            # jmenná forma jiná: schopni, ochotni, unaven
            '4' => ['variant' => 'short'],
            # zvratná jmenná forma: si vědom
            '5' => ['variant' => 'short', 'reflex' => 'yes'],
            # ostatní: chybnejch, normální, hovorový
            '0' => []
        },
        'encode_map' =>

            { 'variant' => { 'short' => { 'reflex' => { 'yes' => '5',
                                                        '@' => { 'gender' => { 'neut' => { 'number' => { 'sing' => '3',
                                                                                                         '@'    => '4' }},
                                                                               '@'    => '4' }}}},
                             '@'     => { 'reflex' => { 'yes' => '2',
                                                        '@'      => { 'verbform' => { 'part' => '1',
                                                                                      '@'    => '0' }}}}}}
    );
    # PRONOUN TYPE ####################
    $atoms{pronoun_type} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'pronoun_type',
        'decode_map' =>
        {
            # osobní: já, ty, on, ona, ono, my, vy, oni, ony
            '1' => ['prontype' => 'prs'],
            # neurčité: všem, všechno, nějakou, ňáká, něco, některé, každý
            '2' => ['prontype' => 'ind'],
            # osobní zvratné: sebe, sobě, se, si, sebou
            '3' => ['prontype' => 'prs', 'reflex' => 'yes'],
            # ukazovací: to, takový, tu, ten, tamto, té, tech
            '4' => ['prontype' => 'dem'],
            # tázací: co, jaký, kdo, čim, komu, která
            '5' => ['prontype' => 'int'],
            # vztažné: což, který, která, čeho, čehož, jakým
            '6' => ['prontype' => 'rel'],
            # záporné: žádná, nic, žádný, žádnej, nikdo, nikomu
            '7' => ['prontype' => 'neg'],
            # přivlastňovací: můj, tvůj, jeho, její, náš, váš, jejich
            '8' => ['prontype' => 'prs', 'poss' => 'yes'],
            # přivlastňovací zvratné: své, svýmu, svými, svoje
            '9' => ['prontype' => 'prs', 'poss' => 'yes', 'reflex' => 'yes'],
            # víceslovné: nějaký takový, takový ňáký, nějaký ty, takovym tim
            '0' => ['prontype' => 'ind', 'other' => {'prontype' => 'víceslovné'}],
            # víceslovné vztažné: to co, "to, co", něco co, "ten, kdo"
            '-' => ['prontype' => 'rel', 'other' => {'prontype' => 'víceslovné'}]
        },
        'encode_map' =>

            { 'prontype' => { 'prs' => { 'poss' => { 'yes' => { 'reflex' => { 'yes' => '9',
                                                                               '@'      => '8' }},
                                                     '@'    => { 'reflex' => { 'yes' => '3',
                                                                               '@'      => '1' }}}},
                              'ind' => { 'other/prontype' => { 'víceslovné' => '0',
                                                               '@'          => '2' }},
                              'dem' => '4',
                              'int' => '5',
                              'rel' => { 'other/prontype' => { 'víceslovné' => '-',
                                                               '@'          => '6' }},
                              'neg' => '7' }}
    );
    # NUMERAL TYPE ####################
    $atoms{numeral_type} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'numeral_type',
        'decode_map' =>
        {
            # základní: jeden, pět, jedný, deset, vosum
            '1' => ['pos' => 'num', 'numtype' => 'card'],
            # řadová: druhej, prvnímu, poprvé, sedumdesátým
            '2' => ['pos' => 'adj|adv', 'numtype' => 'ord'],
            # druhová: oboje, troje, vosmery, jedny, dvojího
            '3' => ['pos' => 'adj', 'numtype' => 'sets'],
            # násobná: dvakrát, mockrát, jednou, mnohokrát, čtyřikrát
            '4' => ['pos' => 'adv', 'numtype' => 'mult'],
            # neurčitá: několik, kolik, pár, tolik, několikrát
            '5' => ['prontype' => 'ind'],
            # víceslovná základní: dvě stě, tři tisíce, deset tisíc, sedum set, čtyři sta
            '6' => ['pos' => 'num', 'numtype' => 'card', 'other' => {'numtype' => 'víceslovná'}],
            # víceslovná řadová: sedumdesátym druhym, šedesátej vosmej, osmdesátém devátém
            '7' => ['pos' => 'adj', 'numtype' => 'ord', 'other' => {'numtype' => 'víceslovná'}],
            # víceslovná druhová
            '8' => ['pos' => 'adj', 'numtype' => 'sets', 'other' => {'numtype' => 'víceslovná'}],
            # víceslovná násobná
            '9' => ['pos' => 'adv', 'numtype' => 'mult', 'other' => {'numtype' => 'víceslovná'}],
            # víceslovná neurčitá: "tolik, kolik", "tolik (ženskejch), kolik"
            '0' => ['prontype' => 'ind', 'other' => {'numtype' => 'víceslovná'}]
        },
        'encode_map' =>

            { 'other/numtype' => { 'víceslovná' => { 'prontype' => { 'ind' => '0',
                                                                     '@'   => { 'numtype' => { 'mult' => '9',
                                                                                               'sets' => '8',
                                                                                               'ord'  => '7',
                                                                                               '@'    => '6' }}}},
                                   '@'          => { 'prontype' => { 'ind' => '5',
                                                                     '@'   => { 'numtype' => { 'mult' => '4',
                                                                                               'sets' => '3',
                                                                                               'ord'  => '2',
                                                                                               '@'    => '1' }}}}}}
    );
    # ASPECT ####################
    $atoms{aspect} = $self->create_simple_atom
    (
        'tagset' => 'cs::pmk',
        'intfeature' => 'aspect',
        'simple_decode_map' =>
        {
            # imperfektivum: neměl, myslim, je, má, existují
            '1' => 'imp',
            # perfektivum: uživí, udělat, zlepšit, rozvíst, vynechat
            '2' => 'perf',
            # obouvidové: stačilo, absolvovali, algoritmizovat, analyzujou, nedokáží
            '9' => 'imp|perf'
        }
    );
    # ADVERB TYPE ####################
    $atoms{adverb_type} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'adverb_type',
        'decode_map' =>
        {
            # běžné nespecifické: materiálně, pak, finančně, moc, hrozně
            '1' => [],
            # predikativum: nelze, smutno, blízko, zima, horko
            '2' => ['advtype' => 'mod|sta'],
            # zájmenné nespojovací: tady, jak, tak, tehdy, teď, vždycky, kde, vodkaď, tam, tu, vodtaď, potom, přitom, někde
            # In fact, this category contains several types of pronominal adverbs: indefinite, demonstrative, interrogative etc.
            # The main point is to set prontype to anything non-empty here to distinguish them from adjectival adverbs.
            '3' => ['prontype' => 'ind'],
            # spojovací výraz jednoslovný: proč, kdy, kde, kam
            '4' => ['prontype' => 'rel'],
            # spojovací výraz víceslovný: "tak, jak", "tak, že", "tak, aby", "tak jako", "tak (velký), aby"
            # Typically, this is a pair of a demonstrative adverb ("tak") and a relative adverb ("jak") or conjunction ("že").
            # The tag appears at the demonstrative adverb while the rest has empty tag.
            '5' => ['prontype' => 'dem']
        },
        'encode_map' =>

            { 'advtype' => { 'mod|sta' => '2',
                             '@'       => { 'prontype' => { 'ind' => '3',
                                                            'rel' => '4',
                                                            'dem' => '5',
                                                            '@'   => '1' }}}}
    );
    # PREPOSITION TYPE ####################
    $atoms{preposition_type} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'preposition_type',
        'decode_map' =>
        {
            # běžná vlastní: v, vod, na, z, se
            '1' => [],
            # nevlastní homonymní: vokolo, vedle, včetně, pomocí, během
            '2' => ['other' => {'preptype' => 'nevlastní'}],
            # víceslovná: z pohledů, na základě, na začátku, za účelem, v rámci
            '3' => ['other' => {'preptype' => 'víceslovná'}]
        },
        'encode_map' =>

            { 'other/preptype' => { 'nevlastní'  => '2',
                                    'víceslovná' => '3',
                                    '@'          => '1' }}
    );
    # CONJUNCTION TYPE ####################
    $atoms{conjunction_type} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'conjunction_type',
        'decode_map' =>
        {
            # souřadící jednoslovná: a, ale, nebo, jenomže, či
            '1' => ['conjtype' => 'coor'],
            # podřadící jednoslovná: jesli, protože, že, jako, než
            '2' => ['conjtype' => 'sub'],
            # souřadící víceslovná: buďto-anebo, i-i, ať už-anebo, buď-nebo, ať-nebo
            '3' => ['conjtype' => 'coor', 'other' => {'conjtype' => 'multitoken'}],
            # podřadící víceslovná: jesli-tak, "na to, že", i když, i dyž, proto-že
            '4' => ['conjtype' => 'sub', 'other' => {'conjtype' => 'multitoken'}],
            # jiná jednoslovná: v korpusu se nevyskytuje
            '5' => ['other' => {'conjtype' => 'other'}],
            # jiná víceslovná: v korpusu se nevyskytuje
            '6' => ['other' => {'conjtype' => 'other-multitoken'}],
            # nelze určit: buď, jak, sice, jednak, buďto
            '9' => []
        },
        'encode_map' =>

            { 'other/conjtype' => { 'other'            => '5',
                                    'other-multitoken' => '6',
                                    'multitoken'       => { 'conjtype' => { 'sub'  => '4',
                                                                            '@'    => '3' }},
                                    '@'                => { 'conjtype' => { 'sub'  => '2',
                                                                            'coor' => '1',
                                                                            '@'    => '9' }}}}
    );
    # INTERJECTION TYPE ####################
    $atoms{interjection_type} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'interjection_type',
        'decode_map' =>
        {
            # běžné původní: hm, nó, no jo, jé, aha
            '1' => [],
            # substantivní: škoda, čoveče, mami, bóže, hovno
            '2' => ['other' => {'intertype' => 'noun'}],
            # adjektivní: hotovo, bezva
            '3' => ['other' => {'intertype' => 'adj'}],
            # zájmenné: jo, ne, jó, né
            '4' => ['other' => {'intertype' => 'pron'}],
            # slovesné: neboj, sím, podivejte, hele, počkej
            '5' => ['other' => {'intertype' => 'verb'}],
            # adverbiální: vážně, jistě, takle, depak, rozhodně
            '6' => ['other' => {'intertype' => 'adv'}],
            # jiné: jaktože, pardón, zaplať pámbu, ahój, vůbec
            '7' => ['other' => {'intertype' => 'other'}],
            # víceslovné = frazém: v korpusu se nevyskytlo, resp. možná se vyskytlo a bylo označkováno jako frazém
            '0' => ['other' => {'intertype' => 'multitoken'}]
        },
        'encode_map' =>

            { 'other/intertype' => { 'noun'       => '2',
                                     'adj'        => '3',
                                     'pron'       => '4',
                                     'verb'       => '5',
                                     'adv'        => '6',
                                     'other'      => '7',
                                     'multitoken' => '0',
                                     '@'          => '1' }}
    );
    # PARTICLE TYPE ####################
    $atoms{particle_type} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'particle_type',
        'decode_map' =>
        {
            # vlastní nehomonymní: asi, právě, také, spíš, přece
            '1' => [],
            # adverbiální: prostě, hnedle, naopak, třeba, tak
            '2' => ['other' => {'parttype' => 'adv'}],
            # spojkové: teda, ani, jako, až, ale
            '3' => ['other' => {'parttype' => 'conj'}],
            # jiné: nó, zrovna, jo, vlastně, to
            '4' => ['other' => {'parttype' => 'other'}],
            # víceslovné nevětné: no tak, tak ňák, že jo, nebo co, jen tak
            '5' => ['other' => {'parttype' => 'multitoken'}]
        },
        'encode_map' =>

            { 'other/parttype' => { 'adv'        => '2',
                                    'conj'       => '3',
                                    'other'      => '4',
                                    'multitoken' => '5',
                                    '@'          => '1' }}
    );
    # IDIOM TYPE ####################
    ###!!! Perhaps we could reverse the priorities. Idiom type would be (mostly) decoded
    ###!!! as $fs->{pos}, and $fs->{other} would record that this is an idiom.
    $atoms{idiom_type} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'idiom_type',
        'decode_map' =>
        {
            # verbální: vyprdnout se na to, mít dojem, mít smysl, měli rádi, jít vzorem
            '1' => ['other' => {'idiomtype' => 'verb'}],
            # substantivní: hlava rodiny, žebříček hodnot, říjnový revoluci, diamantovou svatbou, českej člověk
            '2' => ['other' => {'idiomtype' => 'noun'}],
            # adjektivní: ten a ten, každym druhym, toho a toho, jako takovou, výše postavených
            '3' => ['other' => {'idiomtype' => 'adj'}],
            # adverbiální: u nás, v naší době, tak ňák, za chvíli, podle mýho názoru
            '4' => ['other' => {'idiomtype' => 'adv'}],
            # propoziční včetně interjekčních: to stálo vodříkání, to snad není možný, je to tím že, největší štěstí je
            '5' => ['other' => {'idiomtype' => 'prop'}],
            # jiné: samy za sebe, všechno možný, jak který, všech možnejch, jednoho vůči druhýmu
            '6' => ['other' => {'idiomtype' => 'other'}]
        },
        'encode_map' =>

            { 'other/idiomtype' => { 'verb' => '1',
                                     'noun' => '2',
                                     'adj'  => '3',
                                     'adv'  => '4',
                                     'prop' => '5',
                                     '@'    => '6' }}
    );
    # OTHER REAL TYPE ####################
    # (skutečný druh)
    $atoms{other_real_type} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'other_real_type',
        'decode_map' =>
        {
            # citátové výrazy cizojazyčné, zvláště víceslovné: go, skinheads, non plus ultra, madame, cleaner polish
            'C' => ['foreign' => 'yes'],
            # zkratky neslovní: ý, í, x, ČKD, EEG
            'Z' => ['abbr' => 'yes'],
            # propria: Kunratickou, Hrádek, Mirek, Roháčích, Vinnetou
            'P' => ['pos' => 'noun', 'nountype' => 'prop']
        },
        'encode_map' =>

            { 'foreign' => { 'yes' => 'C',
                             '@'       => { 'abbr' => { 'yes' => 'Z',
                                                        '@'    => { 'nountype' => { 'prop' => 'P' }}}}}}
    );
    # PROPER NOUN TYPE ####################
    $atoms{proper_noun_type} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'proper_noun_type',
        'decode_map' =>
        {
            # jednoslovné: Vinnetou, Rybanu, Tujunga, Brně, Praze
            '1' => [],
            # víceslovné: Zahradním Městě, u Andělů, Staroměstského náměstí, Český Štenberk, Lucinka Tomíčková
            '2' => ['other' => {'multitoken' => 1}]
        },
        'encode_map' =>

            { 'other/multitoken' => { 1   => '2',
                                      '@' => '1' }}
    );
    # NOUN CLASS ####################
    $atoms{noun_class} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'noun_class',
        'decode_map' =>
        {
            # osoba: holčička, maminku, blondýnka, bytost, rošťanda
            '1' => ['other' => {'nounclass' => 'person'}],
            # živočich: zvířata, vůl, had, krávám, psy
            '2' => ['other' => {'nounclass' => 'animal'}],
            # konkrétum: hlavou, vodu, nohy, auto, metru
            '3' => ['other' => {'nounclass' => 'concrete'}],
            # abstraktum: pocit, vzdělání, mezera, mládí, války
            '4' => ['other' => {'nounclass' => 'abstract'}],
            # jiné nejasné: sídlišti, chatu, továrnách, pracovně, ateliér
            '9' => ['other' => {'nounclass' => 'unclear'}]
        },
        'encode_map' =>

            { 'other/nounclass' => { 'person'   => '1',
                                     'animal'   => '2',
                                     'concrete' => '3',
                                     'abstract' => '4',
                                     '@'        => '9' }}
    );
    # ADJECTIVE CLASS ####################
    $atoms{adjective_class} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'adjective_class',
        'decode_map' =>
        {
            # deskriptivní: těsné, prožitej, vykonaný, starší, mladších
            '1' => ['other' => {'adjclass' => 'descr'}],
            # deskriptivní propriální: Zděnkový, Patriková, Romanovou, náchodskýho, silvánského
            '2' => ['other' => {'adjclass' => 'prop'}],
            # evaluativní: blbej, nepříjemnej, hroznej, neuvěřitelný, šílený
            '3' => ['other' => {'adjclass' => 'eval'}],
            # intenzifikační: kratší, krátkou, delší, rychlý, malej, velká, nejhlubšího
            '4' => ['other' => {'adjclass' => 'intens'}],
            # restriktivní: celý, další, stejnej, specifický, určitý, jinýho
            '5' => ['other' => {'adjclass' => 'restr'}],
            # nelze určit: zato, myšlená, danej
            '9' => []
        },
        'encode_map' =>

            { 'other/adjclass' => { 'descr'  => '1',
                                    'prop'   => '2',
                                    'eval'   => '3',
                                    'intens' => '4',
                                    'restr'  => '5',
                                    '@'      => '9' }}
    );
    # ADVERB CLASS ####################
    $atoms{adverb_class} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'adverb_class',
        'decode_map' =>
        {
            # neurčuje se: takle, jak, tak, takhle, nějak
            '-' => [],
            # deskriptivní: spolu, prakticky, individuálně, citově, přesně
            '1' => ['other' => {'advclass' => 'descr'}],
            # evaluativní: strašně, různě, nespravedlivě, pořádně, prakticky
            '2' => ['other' => {'advclass' => 'eval'}],
            # intenzifikační: malinko, uplně, totálně, hodně, daleko
            '3' => ['other' => {'advclass' => 'intens'}],
            # restriktivní: většinou, jenom, podobně, stejně, výhradně
            '4' => ['other' => {'advclass' => 'restr'}],
            # deskriptivní časoprostorové: pořád, domů, dneska, tady, někam
            '5' => ['other' => {'advclass' => 'timespace'}],
            # nelze určit: no occurrence in corpus
            '6' => ['other' => {'advclass' => 'unknown'}]
        },
        'encode_map' =>

            { 'other/advclass' => { 'descr'     => '1',
                                    'eval'      => '2',
                                    'intens'    => '3',
                                    'restr'     => '4',
                                    'timespace' => '5',
                                    'unknown'   => '6',
                                    '@'         => '-' }}
    );
    # PREPOSITION CLASS ####################
    $atoms{preposition_class} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'preposition_class',
        'decode_map' =>
        {
            # lokální: u, do, na, v, po
            '1' => ['advtype' => 'loc'],
            # temporální: před, po, v, vod, do
            '2' => ['advtype' => 'tim'],
            # jiná: vo, kvůli, ke, kromě, s
            '3' => []
        },
        'encode_map' =>

            { 'advtype' => { 'loc' => '1',
                             'tim' => '2',
                             '@'   => '3' }}
    );
    # CONJUNCTION CLASS ####################
    $atoms{conjunction_class} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'conjunction_class',
        'decode_map' =>
        {
            # kombinační (sluč./stup./vyluč./odpor.): a, ale, nebo, jenomže, ať
            '1' => ['other' => {'conjclass' => 'comb'}],
            # specifikační (obsah./kval./účin./účel.): aby, že, jesli
            '2' => ['other' => {'conjclass' => 'spec'}],
            # závislostní (kauz./důsl./podmín./příp./výjim.): pokuď, když, protože, takže, prže
            '3' => ['other' => {'conjclass' => 'dep'}],
            # časoprostorová: jakmile, než, co, jak, dyž
            '4' => ['other' => {'conjclass' => 'timespace'}],
            # jiná (podob./srov./způs./zřet.): než, jako
            '5' => ['other' => {'conjclass' => 'comp'}]
        },
        'encode_map' =>

            { 'other/conjclass' => { 'spec'      => '2',
                                     'dep'       => '3',
                                     'timespace' => '4',
                                     'comp'      => '5',
                                     '@'         => '1' }}
    );
    # INTERJECTION CLASS ####################
    $atoms{interjection_class} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'interjection_class',
        'decode_map' =>
        {
            # faktuální: ee, ne, hm, á, eh
            '1' => ['other' => {'interclass' => 'fac'}],
            # voluntativní: no, jo, jasně, pozor, nene
            '2' => ['other' => {'interclass' => 'vol'}],
            # emocionální: sakra, jé, bóže, bezva, hrůza
            '3' => ['other' => {'interclass' => 'emo'}],
            # kontaktové: neboj, podivejte, na, hele, počkej
            '4' => ['other' => {'interclass' => 'con'}],
            # onomatopoické: hhh, checheche, cha, chachacha
            '5' => ['other' => {'interclass' => 'ono'}],
            # voluntativní kontaktové: vole
            '6' => ['other' => {'interclass' => 'volcon'}],
            # voluntativní emocionální: jaktože, ty, ále, chá, šlus
            '7' => ['other' => {'interclass' => 'volemo'}],
            # voluntativní onomatopoické: šup
            '8' => ['other' => {'interclass' => 'volono'}],
            # emocionální kontaktové: ano
            '9' => ['other' => {'interclass' => 'emocon'}],
            # jiné: no occurrence in corpus
            '0' => []
        },
        'encode_map' =>

            { 'other/interclass' => { 'fac'    => '1',
                                      'vol'    => '2',
                                      'emo'    => '3',
                                      'con'    => '4',
                                      'ono'    => '5',
                                      'volcon' => '6',
                                      'volemo' => '7',
                                      'volono' => '8',
                                      'emocon' => '9',
                                      '@'      => '0' }}
    );
    # PARTICLE CLASS ####################
    $atoms{particle_class} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'particle_class',
        'decode_map' =>
        {
            # faktuální: tak, teda, asi, jako, řikám
            '1' => ['other' => {'partclass' => 'fact'}],
            # faktuální evaluativní: přitom, stejně, ovšem, potom, prakticky
            '2' => ['other' => {'partclass' => 'eval'}],
            # faktuální intenzifikační: i, specielně, hlavně, aspoň, už
            '3' => ['other' => {'partclass' => 'intens'}],
            # voluntativní: řekněme
            '4' => ['other' => {'partclass' => 'vol'}],
            # voluntativní evaluativní: třeba
            '5' => ['other' => {'partclass' => 'voleval'}],
            # expresivní (+eval./intenz.): no, taky, tak
            '6' => ['other' => {'partclass' => 'expr'}],
            # emocionální (eval./intenz.): bohužel, normálně, eště, akorát, vyloženě
            '7' => ['other' => {'partclass' => 'emo'}],
            # faktuální expresivní (+eval.): prostě, nakonec, vono, ne, jenom
            '8' => ['other' => {'partclass' => 'factexpr'}],
            # jiné (kombinace): teprv, nó, no, jo, dejme tomu
            '9' => []
        },
        'encode_map' =>

            { 'other/partclass' => { 'fact'     => '1',
                                     'eval'     => '2',
                                     'intens'   => '3',
                                     'vol'      => '4',
                                     'voleval'  => '5',
                                     'expr'     => '6',
                                     'emo'      => '7',
                                     'factexpr' => '8',
                                     '@'        => '9' }}
    );
    # VALENCY ####################
    # Note that valency, as it seems to be defined by the corpus annotation, does
    # not distinguish obligatory arguments from optional adjuncts. It simply
    # denotes the type of the dependent node in the particular sentence. It is thus
    # a property of the word in context, rather than of the lexical unit.
    # Valency codes differ for different parts of speech, thus we have different
    # atoms here, indexed by the characters that encode part of speech (e.g. 1
    # is noun).
    # NOUN VALENCY ####################
    $atoms{valency1} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'noun_valency',
        'decode_map' =>
        {
            # bez valence: zařazení, ohodnocení, vzdělání, věc, lidi
            '0' => [],
            # s bezpředložkovým pádem: fůra, května, rok, revizi, zdroje
            '1' => ['other' => {'valency' => 'npr'}],
            # s předložkou: díru, kamna, smlouva, subdodavatele, modernizace
            '2' => ['other' => {'valency' => 'pre'}],
            # se spojovacím výrazem (včetně relativ): práci, lazar, člověk, dlaždičky, mapy
            '3' => ['other' => {'valency' => 'con'}],
            # s infinitivem: možnost, příležitost, čas, rozdíl, snaha
            '4' => ['other' => {'valency' => 'inf'}],
            # s adverbiem: hodin (denně), životem (předtim), starost (navíc), moc (shora), prací (doma)
            '5' => ['other' => {'valency' => 'adv'}],
            # se dvěma bezpředložkovými pády: stanice (metra Dejvická), přetížení (dětí učivem), věnování se (rodičů dětem)
            '6' => ['other' => {'valency' => 'npr+npr'}],
            # s bezpředložkovým a předložkovým pádem: kontakt (dětí s vostatníma), výchovu (dětí v rodině), vztah (dítěte k rodině)
            '7' => ['other' => {'valency' => 'npr+pre'}],
            # s bezpředložkovým pádem a spojkou: spolčení (jeden proti druhému, aby), podmínky (k tomu, aby), mládí (dítěte, kdy)
            '8' => ['other' => {'valency' => 'npr+con'}],
            # jiné a vícečetné: příklad (, kdy), pracovník (, jako je ..., kterej ...), záruka (, že)
            '9' => ['other' => {'valency' => 'oth'}]
        },
        'encode_map' =>

            { 'other/valency' => { 'npr' => '1',
                                   'pre' => '2',
                                   'con' => '3',
                                   'inf' => '4',
                                   'adv' => '5',
                                   'npr+npr' => '6',
                                   'npr+pre' => '7',
                                   'npr+con' => '8',
                                   'oth' => '9',
                                   '@'   => '0' }}
    );
    # ADJECTIVE VALENCY ####################
    $atoms{valency2} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'adjective_valency',
        'decode_map' =>
        {
            # bez valence v atributu: vysoká, šeredný, mladí, naprostou, nezkušený
            '0' => ['other' => {'valency' => 'attr'}],
            # bez valence v predikátu: dobrý, solidní, zlí, vobtížný, schopný
            '1' => ['other' => {'valency' => 'pred'}],
            # s pádem bez předložky v predikátu: vytvořený (závodem), vychovávaná (třicátníky), plný (jich), adekvátní (tomu)
            '2' => ['other' => {'valency' => 'npr'}],
            # s předložkovým pádem v predikátu: spokojený (v práci), nevšímaví (ke všemu), spokojená (s prostředim)
            '3' => ['other' => {'valency' => 'pre'}],
            # se spojkou: rádi (že), přesvědčená (že), hodnější (než), posuzovanej (jako), vyšší (než)
            '4' => ['other' => {'valency' => 'con'}],
            # s infinitivem: nutný (vykonávat), možný (měnit), povolený (řikat), schopnej (říct), zvyklý (bejt)
            '5' => ['other' => {'valency' => 'inf'}],
            # jiné nebo neurčitelné: otevřený, nemyslitelné, nového, nastudovaného, připravený
            '8' => ['other' => {'valency' => 'oth'}]
        },
        'encode_map' =>

            { 'other/valency' => { 'pred' => '1',
                                   'npr'  => '2',
                                   'pre'  => '3',
                                   'con'  => '4',
                                   'inf'  => '5',
                                   'oth'  => '8',
                                   '@'    => '0' }}
    );
    # PRONOUN VALENCY ####################
    $atoms{valency3} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'pronoun_valency',
        'decode_map' =>
        {
            # bez valence: sám, tom, my, všechno, jim
            '0' => [],
            # s bezpředložkovým pádem: tudle (otázku) (???), naše (společnost) (???), některý (ženský) (???)
            '1' => ['other' => {'valency' => 'npr'}],
            # s předložkovým pádem: sám (vod sebe), každej (z nás), málokterý (z rodičů), málokdo (z nich), někoho (nad hrobem)
            '2' => ['other' => {'valency' => 'pre'}],
            # s podřadící spojkou: tom (jesi), tom (kolik), takový (jak), toho (na jaký)
            '3' => ['other' => {'valency' => 'con'}],
            # jiné: co, který, ten (že), čem, to (vo čem)
            '4' => ['other' => {'valency' => 'oth'}]
        },
        'encode_map' =>

            { 'other/valency' => { 'npr' => '1',
                                   'pre' => '2',
                                   'con' => '3',
                                   'oth' => '4',
                                   '@'   => '0' }}
    );
    # NUMERAL VALENCY ####################
    $atoms{valency4} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'numeral_valency',
        'decode_map' =>
        {
            # bez valence samostatná: tolik, druhejm, jednou, vobojí, jedno
            '0' => [],
            # s bezpředložkovým pádem: vosum (hodin), dva (buřty), tři (krajíce), jedenáct (let), čtyřiceti (letech)
            '1' => ['other' => {'valency' => 'npr'}],
            # s předložkou: jedním (z důvodů), jednou (za čtyři roky), dvě (z možností), jeden (z kořenů), čtvrt (na devět)
            '2' => ['other' => {'valency' => 'pre'}],
            # jiná: jedenáct (večer), jednou (tak velkej), (těch) devět (co jsme), pět (který), tří (v Praze)
            '3' => ['other' => {'valency' => 'oth'}]
        },
        'encode_map' =>

            { 'other/valency' => { 'npr' => '1',
                                   'pre' => '2',
                                   'oth' => '3',
                                   '@'   => '0' }}
    );
    # VALENCY OF VERBS AND VERBAL IDIOMS ####################
    $atoms{valency5} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'verb_valency',
        'decode_map' =>
        {
            # nerealizovaná subjektová valence, zřejmě hlavně u infinitivů: vzdělávat se, dejchat, nehýřit, rozšířit, stihnout
            '1'  => [],
            # nesubjektová valence s akuzativem
            # jen akuzativ: dělat (tohleto), stihnout (to), mít (čas), vystudovat (školu), přijímat (procento)
            '2-' => ['other' => {'valency' => 'acc'}],
            # a genitiv: vodpovědět (bez přípravy na votázku), vymazat (to z třídní knihy), ušetřit (na auto z platu)
            '21' => ['other' => {'valency' => 'acc+gen'}],
            # a instrumentál: dělat (něco s tim), dosáhnout (něco s nima), vyto (to před náma), získat (prostředky jinými formami)
            '22' => ['other' => {'valency' => 'acc+ins'}],
            # a lokativ: vychovaj (lidi v tom), říct (todleto vo mně), postavit (manželství na základech), mluvit (vo tom hodinu)
            '23' => ['other' => {'valency' => 'acc+loc'}],
            # a akuzativ: vést (dialog přes třetí osobu), máš (to samozřejmý), svádět (to na bolševiky), nabalovat (ty na kterej)
            '24' => ['other' => {'valency' => 'acc+acc'}],
            # a dativ: věnovat (tomu čas), vysvětlit (to jim), přidat (někomu stovku), ubrat (herci stovku), hnát (lidi k tomu)
            '25' => ['other' => {'valency' => 'acc+dat'}],
            # a adverbiále: udělat (cokoli kůli penězům), vyruš (policajta v sobotu), polapit (ho za vobojek), představit si (ženu tam)
            '26' => ['other' => {'valency' => 'acc+adv'}],
            # a infinitiv: nenapadne (mě kouřit), nechat (děti vystudovat), baví (mladý poslouchat), nechat (se popíchat)
            '27' => ['other' => {'valency' => 'acc+inf'}],
            # a spojka: rozvíjet (je jako), věřit (v to, že), postarat se (vo to, aby), nekouká se (na to, aby)
            '28' => ['other' => {'valency' => 'acc+con'}],
            # a další 2 pády: dělat (něco vopravdu) (???); no other occurrences
            '29' => ['other' => {'valency' => 'acc+2'}],
            # jiné smíšené/trojmístné: dodělat (to částečně, než), sladit (si všechno barevně, jak chceš)
            '20' => ['other' => {'valency' => 'acc+oth'}],
            # nesubjektová valence s neakuzativem
            # genitiv: ubývá (lásky), jít (do svazku), vodtrhnout se (vod většiny), nezbláznit se (do shonu), nadít se (pomoci)
            '31' => ['other' => {'valency' => 'gen'}],
            # instrumentál: vrtět (ocasem), udělat se (vedoucím), rozptylovat (činností), zabývat se (situací)
            '32' => ['other' => {'valency' => 'ins'}],
            # lokativ: záleží (na lidech), podílet se (na výchově), rozhodnout se (o tom), vydělávat (na tom)
            '33' => ['other' => {'valency' => 'loc'}],
            # dativ: vadilo by (mně), přirovnat (k tomu), došlo (k rovnoprávnosti), pomoct (jí)
            '34' => ['other' => {'valency' => 'dat'}],
            # genitiv a neakuzativ: usuzovat (z toho, že), oprostit (se vod všeho), bylo (vod předmětů až po stáje)
            '35' => ['other' => {'valency' => 'gen+nac'}],
            # instrumentál a neakuzativ: učit se (s dětma do školy), mluvit (s nima vo věcech), plýtvat (nehospodárně čimkoliv)
            '36' => ['other' => {'valency' => 'ins+nac'}],
            # lokativ a neakuzativ: píše se (vo tom v novinách), mluvit (vo tom víc), omezit (se v něčem)
            '37' => ['other' => {'valency' => 'loc+nac'}],
            # dativ a neakuzativ: věnovat se (těmto cele), mluví se (mně blbě), nelíbilo se (tobě na Slapech)
            '38' => ['other' => {'valency' => 'dat+nac'}],
            # nominativ včetně adjektiv: řídit (sama), bejt (podmínka), bejt (vohodnocená), bejt (hrdá)
            '39' => ['other' => {'valency' => 'nom-nsb'}],
            # jiné smíšené/trojmístné: bejt (mně šedesát), vyrovnat se (způsobem sami ze sebou s tim)
            '30' => ['other' => {'valency' => 'oth+nac'}],
            # jiná nesubjektová valence
            # adverbiále: zařadit (tim způsobem), zařadit se (někam), použít (v životě), žít (v úctě), žilo se (jak)
            '41' => ['other' => {'valency' => 'adv'}],
            # infinitiv: mělo se (vyučovat), nechat si (brát), umět (pomoct), chodit (si zatrénovat)
            '42' => ['other' => {'valency' => 'inf'}],
            # spojka: hodilo by se (abys), zdá se (že), představ si (že), uvažovat (že), myslelo se (že)
            '43' => ['other' => {'valency' => 'con'}],
            # dvě adverbiále: chodí se (denně do práce), sednout si (zvlášť do místnosti), nepršelo (tady na Silvestra)
            '44' => ['other' => {'valency' => 'adv+adv'}],
            # adverbiále a neakuzativ: vyprávělo se (o tom léta), pracovalo se (mi líp), hrát (nám tam)
            '45' => ['other' => {'valency' => 'adv+nac'}],
            # adverbiále a infinitiv: jezdit (tam nakupovat), snažit se (tam vydat), nejde (už potom přitáhnout)
            '46' => ['other' => {'valency' => 'adv+inf'}],
            # adverbiále a spojka: přečíst si (na pytliku, z čeho to je), uvádí se (nakonec, že), porovnávat (tolik, že)
            '47' => ['other' => {'valency' => 'adv+con'}],
            # infinitiv a neakuzativ: nepodařilo se (mu naplnit), bát se (strašně mluvit), podařilo se (mi přivýst)
            '48' => ['other' => {'valency' => 'inf+nac'}],
            # spojka a neakuzativ: myslej (tim, že), dokázat (si, že), říct (o okolí, že), vočekávat (vod ženy, že)
            '49' => ['other' => {'valency' => 'con+nac'}],
            # jiné: říct (spousta), říct (já dělám ...) [unquoted direct speech]
            '40' => ['other' => {'valency' => 'oth'}],
            # subjektová valence bez nesubjektové
            '5-' => ['other' => {'valency' => 'nom'}],
            # subjektová a nesubjektová s akuzativem
            # jen akuzativ
            '6-' => ['other' => {'valency' => 'nom+acc'}],
            # a genitiv
            '61' => ['other' => {'valency' => 'nom+acc+gen'}],
            # a instrumentál
            '62' => ['other' => {'valency' => 'nom+acc+ins'}],
            # a lokativ
            '63' => ['other' => {'valency' => 'nom+acc+loc'}],
            # a akuzativ
            '64' => ['other' => {'valency' => 'nom+acc+acc'}],
            # a dativ
            '65' => ['other' => {'valency' => 'nom+acc+dat'}],
            # a adverbiále (včetně předložek)
            '66' => ['other' => {'valency' => 'nom+acc+adv'}],
            # a infinitiv
            '67' => ['other' => {'valency' => 'nom+acc+inf'}],
            # a spojka
            '68' => ['other' => {'valency' => 'nom+acc+con'}],
            # a další 2 pády
            '69' => ['other' => {'valency' => 'nom+acc+2'}],
            # jiná (smíšená/trojmístná)
            '60' => ['other' => {'valency' => 'nom+acc+oth'}],
            # subjektová a nesubjektová s neakuzativem
            # genitiv
            '71' => ['other' => {'valency' => 'nom+gen'}],
            # instrumentál (včetně adjektiv)
            '72' => ['other' => {'valency' => 'nom+ins'}],
            # lokativ
            '73' => ['other' => {'valency' => 'nom+loc'}],
            # dativ
            '74' => ['other' => {'valency' => 'nom+dat'}],
            # genitiv a neakuzativ
            '75' => ['other' => {'valency' => 'nom+gen+nac'}],
            # instrumentál a neakuzativ
            '76' => ['other' => {'valency' => 'nom+ins+nac'}],
            # lokativ a neakuzativ
            '77' => ['other' => {'valency' => 'nom+loc+nac'}],
            # dativ a neakuzativ
            '78' => ['other' => {'valency' => 'nom+dat+nac'}],
            # nominativ (včetně adj. ap.)
            '79' => ['other' => {'valency' => 'nom+nom'}],
            # jiné pády (smíšená, trojmístná)
            '70' => ['other' => {'valency' => 'nom+othercase'}],
            # subjektová a nesubjektová jiná
            # adverbiále včetně předložkových frází
            '81' => ['other' => {'valency' => 'nom+adv'}],
            # infinitiv
            '82' => ['other' => {'valency' => 'nom+inf'}],
            # spojka
            '83' => ['other' => {'valency' => 'nom+con'}],
            # 2 adverbiále
            '84' => ['other' => {'valency' => 'nom+adv+adv'}],
            # adverbiále a neakuzativ
            '85' => ['other' => {'valency' => 'nom+adv+nac'}],
            # adverbiále a infinitiv
            '86' => ['other' => {'valency' => 'nom+adv+inf'}],
            # adverbiále a spojka
            '87' => ['other' => {'valency' => 'nom+adv+con'}],
            # infinitiv a neakuzativ
            '88' => ['other' => {'valency' => 'nom+inf+nac'}],
            # spojka a neakuzativ
            '89' => ['other' => {'valency' => 'nom+con+nac'}],
            # jiné i přímá řeč
            '80' => ['other' => {'valency' => 'nom+oth'}]
        },
        'encode_map' =>

            { 'other/valency' => { 'acc'     => '2-',
                                   'acc+gen' => '21',
                                   'acc+ins' => '22',
                                   'acc+loc' => '23',
                                   'acc+acc' => '24',
                                   'acc+dat' => '25',
                                   'acc+adv' => '26',
                                   'acc+inf' => '27',
                                   'acc+con' => '28',
                                   'acc+2'   => '29',
                                   'acc+oth' => '20',
                                   'gen'     => '31',
                                   'ins'     => '32',
                                   'loc'     => '33',
                                   'dat'     => '34',
                                   'gen+nac' => '35',
                                   'ins+nac' => '36',
                                   'loc+nac' => '37',
                                   'dat+nac' => '38',
                                   'nom-nsb' => '39',
                                   'oth+nac' => '30',
                                   'adv'     => '41',
                                   'inf'     => '42',
                                   'con'     => '43',
                                   'adv+adv' => '44',
                                   'adv+nac' => '45',
                                   'adv+inf' => '46',
                                   'adv+con' => '47',
                                   'inf+nac' => '48',
                                   'con+nac' => '49',
                                   'oth'     => '40',
                                   'nom'     => '5-',
                                   'nom+acc' => '6-',
                                   'nom+acc+gen' => '61',
                                   'nom+acc+ins' => '62',
                                   'nom+acc+loc' => '63',
                                   'nom+acc+acc' => '64',
                                   'nom+acc+dat' => '65',
                                   'nom+acc+adv' => '66',
                                   'nom+acc+inf' => '67',
                                   'nom+acc+con' => '68',
                                   'nom+acc+2'   => '69',
                                   'nom+acc+oth' => '60',
                                   'nom+gen'     => '71',
                                   'nom+ins'     => '72',
                                   'nom+loc'     => '73',
                                   'nom+dat'     => '74',
                                   'nom+gen+nac' => '75',
                                   'nom+ins+nac' => '76',
                                   'nom+loc+nac' => '77',
                                   'nom+dat+nac' => '78',
                                   'nom+nom'     => '79',
                                   'nom+othercase' => '70',
                                   'nom+adv'     => '81',
                                   'nom+inf'     => '82',
                                   'nom+con'     => '83',
                                   'nom+adv+adv' => '84',
                                   'nom+adv+nac' => '85',
                                   'nom+adv+inf' => '86',
                                   'nom+adv+con' => '87',
                                   'nom+inf+nac' => '88',
                                   'nom+con+nac' => '89',
                                   'nom+oth'     => '80',
                                   '@'           => '1-' }}
    );
    $atoms{valencyF1} = $atoms{valency5};
    # ADVERB VALENCY ####################
    $atoms{valency6} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'adverb_valency',
        'decode_map' =>
        {
            # nespecifikovaná u slovesa: eště (a eště vydělali), napoprvý (nestřílím napoprvý), spolu (kdyby spolu mladí lidé déle žili)
            '-' => [],
            # kvantifikační nebo intenzifikační u slovesa: eště (Láďovi eště neni štyricet), absolutně (neplatí to absolutně)
            '1' => ['other' => {'valency' => 'vrb-qnt'}],
            # nekvantifikační s bezpředložkovým pádem jména: akorát (měli akorát dvě ženský), přesně (mám přesně tydlety zkušenosti)
            '2' => ['other' => {'valency' => 'npr-nqn'}],
            # kvantifikační s bezpředložkovým pádem jména: eště (eště vo víc dní), akorát (čuchala sem akorát olovo)
            '3' => ['other' => {'valency' => 'npr-qnt'}],
            # nekvantifikační u substantiv bez předložky: akorát (akorát párek sme dostali), přesně (neseženeš přesně ty lidi)
            # How the hell does this differ from 2?
            '4' => ['other' => {'valency' => 'npr-nq4'}],
            # s adjektivem nebo adverbiem: eště (dyť sou malinký eště), fyzicky (fyzicky těžké práce)
            '5' => ['other' => {'valency' => 'adj-adv'}],
            # s předložkou: zády (zády k ňákejm klukům), spolu (spolu s výchovou dětí)
            '6' => ['other' => {'valency' => 'pre'}],
            # se spojkou nebo synsém.: přesně (přesně cejtěj to, co ty), dozelena (takovej ten dozelena)
            '7' => ['other' => {'valency' => 'con'}],
            # s infinitivem: spolu (schopni spolu diskutovat), přesně (nemůžu přesně posoudit)
            '8' => ['other' => {'valency' => 'inf'}],
            # s větou: možná (možná, že tím, dyby se zvýšily...)
            '9' => ['other' => {'valency' => 'snt'}],
            # jiné (věta apod.): až (deset až patnáct tisíc ročně), možná (možná že bych se přikláněl)
            '0' => ['other' => {'valency' => 'oth'}]
        },
        'encode_map' =>

            { 'other/valency' => { 'vrb-qnt' => '1',
                                   'npr-nqn' => '2',
                                   'npr-qnt' => '3',
                                   'npr-nq4' => '4',
                                   'adj-adv' => '5',
                                   'pre'     => '6',
                                   'con'     => '7',
                                   'inf'     => '8',
                                   'snt'     => '9',
                                   'oth'     => '0',
                                   '@'       => '-' }}
    );
    # CONJUNCTION VALENCY ####################
    $atoms{valency8} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'conjunction_valency',
        'decode_map' =>
        {
            # vůči slovu: na zadek a dolu; rodičům nebo mýmu okolí; v nepříliš zralém věku, ale z objektivních příčin
            '1' => ['other' => {'valency' => 'wrd'}],
            # vůči větě: sme se sešli a řikali sme mu; povinnosti sou tvoje, ale já je dělám; budu s vámi běhat nebo pudu do soutěže
            '2' => ['other' => {'valency' => 'snt'}],
            # nelze určit: a pak vždycky ne; něco jim teda sdělit nebo ...; autorita, ale ... asi mmm
            '9' => ['other' => {'valency' => 'unk'}]
        },
        'encode_map' =>

            { 'other/valency' => { 'wrd' => '1',
                                   'snt' => '2',
                                   '@'   => '9' }}
    );
    # PARTICLE VALENCY ####################
    $atoms{valency0} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'particle_valency',
        'decode_map' =>
        {
            # adpropoziční zač.: ... asi si ...; že taky nekoupí nic; spíš si myslim
            '1' => ['other' => {'valency' => 'pro-beg'}],
            # adpropoziční konc.: tak tam taky pudem, asi; to určitě přispělo k tomu taky; kolem sto čtyřiceti korun snad
            '2' => ['other' => {'valency' => 'pro-end'}],
            # adpropoziční jiná: to bych asi neměla; menčí taky kapacita plic; bojuje a snad částečně úspěšně
            '3' => ['other' => {'valency' => 'pro-oth'}],
            # adlexémová zač.: asi tisíc dvě stě let; taky nekoupí; spíš pes a Tonda
            '4' => ['other' => {'valency' => 'lex-beg'}],
            # adlexémová konc.: matika taky; několik asi; ňáká francouzská značka snad
            '5' => ['other' => {'valency' => 'lex-end'}],
            # adlexémová jiná: dneska je asi důvod jiný; která je taky tabuizovaná; nebo spíš, spíš hudby
            '6' => ['other' => {'valency' => 'lex-oth'}],
            # jiná nebo neurčeno: asi jak chválit za něco; co se týče jazyků, taky asi, pokud teda
            '7' => ['other' => {'valency' => 'oth'}]
        },
        'encode_map' =>

            { 'other/valency' => { 'pro-beg' => '1',
                                   'pro-end' => '2',
                                   'pro-oth' => '3',
                                   'lex-beg' => '4',
                                   'lex-end' => '5',
                                   'lex-oth' => '6',
                                   '@'       => '7' }}
    );
    # VALENCY OF SUBSTANTIVE IDIOMS ####################
    $atoms{valencyF2} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'substantive_idiom_valency',
        'decode_map' =>
        {
            # bez valence: změny k lepšímu; zlatou svatbu; motor (hnací motor a stimul)
            '0' => [],
            # pád bez předložky (???): mít vliv; mít k sobě blíž; být doma (=nepracovat); mít děti; obejít se bez něčeho
            '1' => ['other' => {'valency' => 'npr'}],
            # s předložkou: vzít sebou; pochopení pro mě; pudou nahoru; udělat něco pro ty děti
            '2' => ['other' => {'valency' => 'pre'}],
            # se spojkou (???): vývojem vědy a techniky; samozřejmostí správců učeben a správců laboratoří
            '3' => ['other' => {'valency' => 'con'}],
            # s infinitivem: dát pozor (???); mít právo, aby (???)
            '4' => ['other' => {'valency' => 'inf'}],
            # s adverbiem: maj daleko; hodně dalších výskytů, ale jsou divné
            '5' => ['other' => {'valency' => 'adv'}],
            # bez předložky dva pády: má ráda Komárka; mám na mysli ten film; dám to trochu do pořádku
            '6' => ['other' => {'valency' => 'npr+npr'}],
            # pád a předložka: jí mám dát na zadek; ze kterejch by měl radost; to je na úkor té emancipace
            '7' => ['other' => {'valency' => 'npr+pre'}],
            # pád a spojka: nemáš, kdo by ti je držel; si říkaj za zády:; mohu říct, tak tohleto ten člověk vytvořil
            '8' => ['other' => {'valency' => 'npr+con'}],
            # jiné, 2 předložky nebo 3 pády: pro sebe a pro jiné tím pádem; tady u nich; a tak dále
            '9' => ['other' => {'valency' => 'oth'}]
        },
        'encode_map' =>

            { 'other/valency' => { 'npr' => '1',
                                   'pre' => '2',
                                   'con' => '3',
                                   'inf' => '4',
                                   'adv' => '5',
                                   'npr+npr' => '6',
                                   'npr+pre' => '7',
                                   'npr+con' => '8',
                                   'oth'     => '9',
                                   '@'       => '0' }}
    );
    # VALENCY OF ADJECTIVE IDIOMS ####################
    $atoms{valencyF3} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'adjective_idiom_valency',
        'decode_map' =>
        {
            # bez valence v atributu: jako (vo ženu jako takovou); úrovni (na ňáký slušný úrovni); ten (pán ten a ten)
            '0' => ['other' => {'valency' => 'atr'}],
            # bez valence v predikátu: života (je vodtržená vod života); zpitá (byla zpitá na mol); nahňácaný (sedíme na sebe nahňácaný)
            '1' => ['other' => {'valency' => 'prd'}],
            # pád bez předložky v predikátu: žádný výskyt
            '2' => ['other' => {'valency' => 'prd-npr'}],
            # s předložkou v predikátu: žádný výskyt
            '3' => ['other' => {'valency' => 'prd-pre'}],
            # se spojkou: žádný výskyt
            '4' => ['other' => {'valency' => 'con'}],
            # s infinitivem: žádný výskyt
            '5' => ['other' => {'valency' => 'inf'}],
            # jiné: jako (vo systému jako takovym); pohled (taková roztomilá bytost na první pohled); takovej (strach jako takovej)
            '8' => ['other' => {'valency' => 'oth'}]
        },
        'encode_map' =>

            { 'other/valency' => { 'atr' => '0',
                                   'prd' => '1',
                                   'prd-npr' => '2',
                                   'prd-pre' => '3',
                                   'con' => '4',
                                   'inf' => '5',
                                   'oth' => '8' }}
    );
    # VALENCY OF ADVERBIAL IDIOMS ####################
    $atoms{valencyF4} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'adverb_idiom_valency',
        'decode_map' =>
        {
            # nespecifikovaná u slovesa: způsobem (kerý se ňákym způsobem rozlišujou); u (zrovna tak je to u mě)
            '-' => [],
            # kvantifikační nebo intenzifikační u slovesa: životě (asi jednou v životě); případě (v každém případě dokážou)
            '1' => ['other' => {'valency' => 'vrb-qnt'}],
            # nepředložkový pád, nekvantifikační: pohodě (my v krásný pohodě)
            '2' => ['other' => {'valency' => 'npr-nqn'}],
            # kvantifikační u jmen: cenu (shonu po penězích za každou cenu); většině (ve většině rodinách)
            '3' => ['other' => {'valency' => 'nou-qnt'}],
            # nekvantifikační u substantiv: u (to neni jenom u nás na podniku); podstatě (to je v podstatě prostředí školy)
            '4' => ['other' => {'valency' => 'nou-nqn'}],
            # s adjektivem nebo adverbiem: způsobem (ňákym způsobem úspěšná); tak (tak ňák hezký)
            '5' => ['other' => {'valency' => 'adj-adv'}],
            # s předložkou: u (mysliš u mě na pracovišti); podstatě (děti se vychovávaj v podstatě vod půl roku)
            '6' => ['other' => {'valency' => 'pre'}],
            # se spojkou / synsém.: podstatě (v podstatě nic, nó to by); tak (dycky jich tak ňák je tak ňák to,)
            '7' => ['other' => {'valency' => 'con'}],
            # s infinitivem: způsobem (nemaj ňákym způsobem možnost vybít); tak (tak a tak ta věc má vypadat)
            '8' => ['other' => {'valency' => 'inf'}],
            # s větou: u (u mě teda byl v tom, že); podstatě (ale v podstatě na to nejsem zvyklá)
            '9' => ['other' => {'valency' => 'snt'}],
            # jiné, věta aj.: tak (tý vteřiny, jo, nebo tak ňák, já vim); míře (nemyslim, že v takový míře, protože ty lidi)
            '0' => ['other' => {'valency' => 'oth'}]
        },
        'encode_map' =>

            { 'other/valency' => { 'vrb-qnt' => '1',
                                   'npr-nqn' => '2',
                                   'nou-qnt' => '3',
                                   'nou-nqn' => '4',
                                   'adj-adv' => '5',
                                   'pre'     => '6',
                                   'con'     => '7',
                                   'inf'     => '8',
                                   'snt'     => '9',
                                   'oth'     => '0',
                                   '@'       => '-' }}
    );
    # VALENCY OF PROPOSITIONAL IDIOMS ####################
    $atoms{valencyF5} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'propositional_idiom_valency',
        'decode_map' =>
        {
            # bez valence k propozici: nevim (já nevim ten plán); no (no a jedno ke druhému)
            '1' => [],
            # spojení s propozicí: je (jak u nás je známo, tak je to tak, že prostě)
            '2' => ['other' => {'valency' => 'pro'}]
        },
        'encode_map' =>

            { 'other/valency' => { 'pro' => '2',
                                   '@'   => '1' }}
    );
    # MULTIWORDNESS AND RESULTATIVITY ####################
    # Applies to verbs.
    $atoms{multiwordness_and_resultativity} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'multiwordness_and_resultativity',
        'decode_map' =>
        {
            # jednoslovné: kradou, maj, sou
            '1' => [],
            # nezvratné složené: honorována (by honorována být neměla); nepršelo (by nepršelo); bylo (by bylo třeba usměrnit)
            '2' => ['other' => {'compverb' => 'comp'}],
            # zvratné nesložené: myslim (si myslim); ptej (se ptej); neboj (se neboj)
            # The feature of reflexiveness could accommodate this particular value.
            '3' => ['other' => {'compverb' => 'rflx'}, 'reflex' => 'yes'],
            # zvratné složené: atestovat (se bude atestovat); stávalo (by se stávalo); měla (by se měla)
            '4' => ['other' => {'compverb' => 'rflx-comp'}, 'reflex' => 'yes'],
            # rezultativ prézens: placeno (máme placeno); maji (maji tam napsáno); votevřeno (maji votevřeno)
            '5' => ['other' => {'compverb' => 'res-pres'}],
            # rezultativ minulý: feminizováno (sem měl pracoviště silně feminizováno); napsáno (měli napsáno); nařízíno (měl nařízíno)
            '6' => ['other' => {'compverb' => 'res-past'}],
            # rezultativ budoucí: žádný výskyt
            '7' => ['other' => {'compverb' => 'res-fut'}],
            # rezultativ v infinitivu: vyluxováno (snažím se tam mít vyluxováno); uklizíno (musim mít prostě uklizíno)
            '8' => ['other' => {'compverb' => 'res-inf'}],
            # rezultativ v kondicionálu: zakázáno (že bych měla zakázáno)
            '9' => ['other' => {'compverb' => 'res-cnd'}]
        },
        'encode_map' =>

            { 'other/compverb' => { 'comp' => '2',
                                    'rflx' => '3',
                                    'rflx-comp' => '4',
                                    'res-pres' => '5',
                                    'res-past' => '6',
                                    'res-fut' => '7',
                                    'res-inf' => '8',
                                    'res-cnd' => '9',
                                    '@' => '1' }}
    );
    # SENTENTIAL MODUS ####################
    # Applies to particles.
    $atoms{sentmod} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'sentmod',
        'decode_map' =>
        {
            # konstatovací nebo oznamovací: asi; taky (že taky nekoupí nic); spíš (spíš si myslim)
            '1' => ['other' => {'sentmod' => 'ind'}],
            # tázací: asi (který by to mohly bejt, asi?); snad (chceš snad tvrdit, že); taky (Zuzana taky chtěla?)
            '2' => ['other' => {'sentmod' => 'int'}],
            # imperativní nebo zvolací: taky (no ty taky!); asi (voni asi určitě začnou!?); dyť (dyť si chtěla sama řídit, né?)
            '3' => ['other' => {'sentmod' => 'imp'}],
            # jiný nebo smíšený: snad (snad neni počůraná); tak (já nevim no, tak ...); sotva (a sotva ta rovnoprávnost kdy bude)
            '4' => []
        },
        'encode_map' =>

            { 'other/sentmod' => { 'ind' => '1',
                                   'int' => '2',
                                   'imp' => '3',
                                   '@'   => '4' }}
    );
    # NOUN FUNCTION ####################
    $atoms{function1} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'noun_function',
        'decode_map' =>
        {
            # subjekt: člověk (se člověk může dočíst)
            '1' => ['other' => {'function' => 'subj'}],
            # predikát (v širším pojetí adv. aj.): člověk (ty seš akční člověk)
            '2' => ['other' => {'function' => 'pred'}],
            # atribut neshodný: člověka (záleží na individualitě člověka)
            '3' => ['other' => {'function' => 'atr'}],
            # nevazebné příslovečné určení: kantor (jako vysokoškolskej kantor by si měla mít); partnera (u toho druhýho partnera najdou)
            '4' => ['other' => {'function' => 'adv'}],
            # věta vokativní: táto (povídej něco, táto taky)
            '5' => ['other' => {'function' => 'vsent'}],
            # věta nominativní: děda (a děda chudák, toho budou bolet nohy)
            '6' => ['other' => {'function' => 'nsent'}],
            # věta jiná: dědečka (ne z dědečka!)
            '7' => ['other' => {'function' => 'osent'}],
            # jiné: muž (má povinností mnohem víc než muž)
            '8' => ['other' => {'function' => 'oth'}],
            # samostatné: člověk (a člověk, dyž by vod nich něco potřeboval, tak pomalu by se jim bál něco říc)
            '9' => ['other' => {'function' => 'sep'}],
            # nelze určit: člověk (je prostě málo nad čim člověk tak: nebo málo co je upoutává)
            '-' => []
        },
        'encode_map' =>

            { 'other/function' => { 'subj'  => '1',
                                    'pred'  => '2',
                                    'atr'   => '3',
                                    'adv'   => '4',
                                    'vsent' => '5',
                                    'nsent' => '6',
                                    'osent' => '7',
                                    'oth'   => '8',
                                    'sep'   => '9',
                                    '@'     => '-' }}
    );
    # ADJECTIVE FUNCTION ####################
    $atoms{function2} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'adjective_function',
        'decode_map' =>
        {
            # atribut: mladej (to žádnej mladej člověk nesnáší)
            '1' => ['other' => {'function' => 'atr'}],
            # predikát: akční (ty seš akční člověk) (!!!)
            '2' => ['other' => {'function' => 'pred'}],
            # nelexikalizované v platnosti substantiva: mladší (ty mladší si řikaj)
            '3' => ['other' => {'function' => 'noun'}],
            # věta: vizuálnější (vizuálnější ...)
            '4' => ['other' => {'function' => 'sent'}],
            # jiné: svobodnej (no tak jako svobodnej, to by si se nesměl voženit a vzít si mě)
            '5' => ['other' => {'function' => 'oth'}]
        },
        'encode_map' =>

            { 'other/function' => { 'atr'  => '1',
                                    'pred' => '2',
                                    'noun' => '3',
                                    'sent' => '4',
                                    'oth'  => '5' }}
    );
    # PRONOUN FUNCTION ####################
    $atoms{function3} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'pronoun_function',
        'decode_map' =>
        {
            # samostatné: ten (a že teda ten, kterej to koupí)
            '1' => ['other' => {'function' => 'sep'}],
            # adjektivní: tom (záleží na tom pracovnim prostředí)
            '2' => ['other' => {'function' => 'adj'}],
            # v platnosti věty: to (to, co mu doposavad chybělo)
            '3' => ['other' => {'function' => 'sent'}],
            # jiné: tu (na tu, co má jenom jedny boty)
            '4' => ['other' => {'function' => 'oth'}]
        },
        'encode_map' =>

            { 'other/function' => { 'sep'  => '1',
                                    'adj'  => '2',
                                    'sent' => '3',
                                    'oth'  => '4' }}
    );
    # NUMERAL FUNCTION ####################
    $atoms{function4} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'numeral_function',
        'decode_map' =>
        {
            # samostatná: jeden (má stálý místo jeden, dva, tři lidi; že jeden žije pro sebe)
            '1' => ['other' => {'function' => 'sep'}],
            # adjektivní: tři (bylo asi tři dny po pohřbu)
            '2' => ['other' => {'function' => 'adj'}],
            # adverbiální: tolik (muslimové maj tolik ženskejch, kolik jich uživí); čtvrt (reaguješ čtvrt vteřiny); jednou (byla jenom jednou); několikanásobně
            '3' => ['other' => {'function' => 'adv'}],
            # vztažná: žádný výskyt
            '4' => ['other' => {'function' => 'rel'}],
            # věta: žádný výskyt
            '5' => ['other' => {'function' => 'sent'}],
            # jiná: jedný (v půl jedný); šedesáti (úspěšnej život jinak než v šedesáti)
            '6' => ['other' => {'function' => 'oth'}]
        },
        'encode_map' =>

            { 'other/function' => { 'sep'  => '1',
                                    'adj'  => '2',
                                    'adv'  => '3',
                                    'rel'  => '4',
                                    'sent' => '5',
                                    'oth'  => '6' }}
    );
    # FUNCTION OF PREPOSITION ####################
    # (left functional dependency)
    $atoms{function7} = $self->create_atom
    (
        'tagset' => 'cs::pmk',
        'surfeature' => 'preposition_function',
        'decode_map' =>
        {
            # bez řídícího výrazu: u (můžeš u toho žehlit)
            '0' => ['other' => {'dependency' => 'sep'}],
            # postverbální: do (pudu do soutěže); z (by se tam moh dostat z půllitru Jany); u (že by dělala u pece)
            '1' => ['other' => {'dependency' => 'verb'}],
            # postsubstantivní nebo postpronominální: z (skleničku, z který ráda piju); do (při cestě do malý země)
            '2' => ['other' => {'dependency' => 'noun'}],
            # postadjektivní: do (zašitej do peřiny); u (nepopulární u starších lidí); ze (pojišťovna nejbližší ze Žižkova)
            '3' => ['other' => {'dependency' => 'adj'}],
            # postadverbiální: do (potom do obchodní školy); vod (daleko vod toho autobusu); z (pryč z pracovního prostředí)
            '4' => ['other' => {'dependency' => 'adv'}],
            # jiná: u (jako u ženskejch); z (že z Horních); do (radši na Slapy než do Káranýho)
            '5' => ['other' => {'dependency' => 'oth'}]
        },
        'encode_map' =>

            { 'other/dependency' => { 'sep'  => '0',
                                      'verb' => '1',
                                      'noun' => '2',
                                      'adj'  => '3',
                                      'adv'  => '4',
                                      'oth'  => '5' }}
    );
    return \%atoms;
}



#------------------------------------------------------------------------------
# Creates a map that tells for each surface part of speech which features are
# relevant and in what order they appear.
#------------------------------------------------------------------------------
sub _create_feature_map
{
    my $self = shift;
    my %features =
    (
        # substantivum = noun
        # According to documentation the last attribute should be style but it does not occur in the data.
        # 2! druh 3. třída 4. valence 5! rod 6. číslo 7. pád 8. funkce 9! styl
        '1' => ['pos', 'noun_type', 'noun_class', 'valency1', 'gender', 'number', 'case', 'function1'],
        # adjektivum = adjective
        # 2! druh 3! poddruh 4. třída 5. valence 6. rod 7. číslo 8. pád 9. stupeň 10. funkce 11! styl
        '2' => ['pos', 'adjective_type', 'adjective_subtype', 'adjective_class', 'valency2', 'gender', 'number', 'case', 'degree', 'function2'],
        # zájmeno = pronoun
        # 2! druh 3. valence 4. rod 5. číslo 6. pád 7. funkce 8. styl
        '3' => ['pos', 'pronoun_type', 'valency3', 'gender', 'number', 'case', 'function3'],
        # číslovka = numeral
        # 2! druh 3. valence 4. rod 5. číslo 6. pád 7. pád subst./pron. 8. funkce 9. styl
        '4' => ['pos', 'numeral_type', 'valency4', 'gender', 'number', 'case', 'counted_case', 'function4'],
        # sloveso = verb
        # 2. vid 3. valence subjektová 4. valence 5. osoba/číslo 6. způsob/čas/slovesný rod 7. imper./neurč. tvary 8! víceslovnost a rezultativnost 9. jmenný rod 10! zápor 11! styl
        '5' => ['pos', 'aspect', 'valency5', 'valency5', 'person_number', 'mood_tense_voice', 'nonfinite_verb_form', 'multiwordness_and_resultativity', 'participle_gender_number', 'polarity'],
        # adverbium = adverb
        # 2! druh 3. třída 4. valence/funkce 5. stupeň 6! styl
        '6' => ['pos', 'adverb_type', 'adverb_class', 'valency6', 'degree'],
        # předložka = preposition
        # 2! druh 3. třída 4. valenční pád 5. funkční závislost levá 6! styl
        '7' => ['pos', 'preposition_type', 'preposition_class', 'case', 'function7'],
        # spojka = conjunction
        # 2! druh 3. třída 4. valence 5! styl
        '8' => ['pos', 'conjunction_type', 'conjunction_class', 'valency8'],
        # citoslovce = interjection
        # 2! druh 3. třída 4! styl
        '9' => ['pos', 'interjection_type', 'interjection_class'],
        # částice = particle
        # 2! druh 3. třída 4. valence 5. modus věty 6! styl
        '0' => ['pos', 'particle_type', 'particle_class', 'valency0', 'sentmod'],
        # idiom a frazém = idiom and set phrase
        # 2! druh; other positions are not defined for F6: 3. valence substantivní 4. valence
        'F1' => ['pos', 'idiom_type', 'valency5', 'valency5'],
        'F2' => ['pos', 'idiom_type', 'valencyF2'],
        'F3' => ['pos', 'idiom_type', 'valencyF3'],
        'F4' => ['pos', 'idiom_type', 'valencyF4'],
        'F5' => ['pos', 'idiom_type', 'valencyF5'],
        'F6' => ['pos', 'idiom_type'],
        # jiné = other (real type encoded at second position: CZP)
        # 2! skutečný druh: CZP 7! styl
        # pouze pro P: P3. druh P4. rod P5. číslo P6. pád
        'JC' => ['pos', 'other_real_type'],
        'JZ' => ['pos', 'other_real_type'],
        'JP' => ['pos', 'other_real_type', 'proper_noun_type', 'gender', 'number', 'case']
    );
    return \%features;
}



#------------------------------------------------------------------------------
# Five parts of speech have gender but its values vary. This function converts
# surface values to internal values, depending on part of speech.
#------------------------------------------------------------------------------
sub _surface_to_internal_gender
{
    my $surface_pos = shift;
    my $surface_gender = shift;
    my %map =
    (
        '1'  => {'1'=>'M', '2'=>'I', '3'=>'F', '4'=>'N', '9'=>'X'},
        '2'  => {'1'=>'M', '2'=>'I', '3'=>'F', '4'=>'N', '9'=>'X'},
        '3'  => {'1'=>'M', '2'=>'I', '3'=>'F', '4'=>'N', '5'=>'B', '9'=>'X'},
        '4'  => {'1'=>'M', '2'=>'I', '3'=>'F', '4'=>'N', '5'=>'B', '9'=>'X'},
        'JP' => {'1'=>'M', '2'=>'I', '3'=>'F', '4'=>'N', '5'=>'X'}
    );
    return $map{$surface_pos}{$surface_gender};
}



#------------------------------------------------------------------------------
# Five parts of speech have gender but its values vary. This function converts
# internal values to surface values, depending on part of speech.
#------------------------------------------------------------------------------
sub _internal_to_surface_gender
{
    my $surface_pos = shift;
    my $internal_gender = shift;
    my %map =
    (
        '1'  => {'M'=>'1', 'I'=>'2', 'F'=>'3', 'N'=>'4', 'X'=>'9'},
        '2'  => {'M'=>'1', 'I'=>'2', 'F'=>'3', 'N'=>'4', 'X'=>'9'},
        '3'  => {'M'=>'1', 'I'=>'2', 'F'=>'3', 'N'=>'4', 'B'=>'5', 'X'=>'9'},
        '4'  => {'M'=>'1', 'I'=>'2', 'F'=>'3', 'N'=>'4', 'B'=>'5', 'X'=>'9'},
        'JP' => {'M'=>'1', 'I'=>'2', 'F'=>'3', 'N'=>'4', 'X'=>'5'}
    );
    return $map{$surface_pos}{$internal_gender};
}



#------------------------------------------------------------------------------
# Five parts of speech have number but its values vary. This function converts
# surface values to internal values, depending on part of speech.
#------------------------------------------------------------------------------
sub _surface_to_internal_number
{
    my $surface_pos = shift;
    my $surface_number = shift;
    my %map =
    (
        '1'  => {'1'=>'S', '2'=>'P', '3'=>'T', '4'=>'D', '5'=>'C', '9'=>'X'},
        '2'  => {'1'=>'S', '2'=>'P', '3'=>'D', '4'=>'C', '9'=>'X'},
        '3'  => {'1'=>'S', '2'=>'P', '3'=>'D', '4'=>'V', '9'=>'X'},
        '4'  => {'1'=>'S', '2'=>'P', '3'=>'D', '4'=>'C', '9'=>'X'},
        'JP' => {'1'=>'S', '2'=>'P', '3'=>'T', '4'=>'X'}
    );
    return $map{$surface_pos}{$surface_number};
}



#------------------------------------------------------------------------------
# Five parts of speech have number but its values vary. This function converts
# internal values to surface values, depending on part of speech.
#------------------------------------------------------------------------------
sub _internal_to_surface_number
{
    my $surface_pos = shift;
    my $internal_number = shift;
    my %map =
    (
        '1'  => {'S'=>'1', 'P'=>'2', 'T'=>'3', 'D'=>'4', 'C'=>'5', 'X'=>'9'},
        '2'  => {'S'=>'1', 'P'=>'2', 'D'=>'3', 'C'=>'4', 'X'=>'9'},
        '3'  => {'S'=>'1', 'P'=>'2', 'D'=>'3', 'V'=>'4', 'X'=>'9'},
        '4'  => {'S'=>'1', 'P'=>'2', 'D'=>'3', 'C'=>'4', 'X'=>'9'},
        'JP' => {'S'=>'1', 'P'=>'2', 'T'=>'3', 'X'=>'4'}
    );
    return $map{$surface_pos}{$internal_number};
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
    $fs->set_tagset('cs::pmk');
    # Convert the tag to an array of values.
    my $tag1 = $tag;
    my @values;
    while($tag1 =~ s/^<i(\d+)>(.*?)<\/i\1>//)
    {
        my $position = $1;
        my $value = $2;
        $values[$position-1] = $value;
    }
    my $atoms = $self->atoms();
    my $features = $self->feature_map();
    my $pos = $values[0];
    if($pos =~ m/^[FJ]$/)
    {
        $pos .= $values[1];
    }
    if(exists($features->{$pos}))
    {
        my @features = @{$features->{$pos}};
        for(my $i = 0; $i<=$#features; $i++)
        {
            next if(!defined($features[$i]));
            confess("Unknown atom '$features[$i]'") if(!exists($atoms->{$features[$i]}));
            if($features[$i] eq 'gender')
            {
                $values[$i] = _surface_to_internal_gender($pos, $values[$i]);
            }
            elsif($features[$i] eq 'number')
            {
                $values[$i] = _surface_to_internal_number($pos, $values[$i]);
            }
            elsif($features[$i] eq 'valency5')
            {
                # Valency of verbs is encoded in two consecutive values.
                $i++;
                $values[$i] = $values[$i-1].$values[$i];
            }
            $atoms->{$features[$i]}->decode_and_merge_hard($values[$i], $fs);
        }
    }
    # untagged tokens in multi-word expressions have empty tags like this:
    # <i1></i1><i2></i2><i3></i3><i4></i4><i5></i5><i6></i6><i7></i7><i8></i8><i9></i9><i10></i10><i11></i11>
    else
    {
        $fs->set('other', {'pos' => 'untagged'});
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
    my $atoms = $self->atoms();
    my $features = $self->feature_map();
    my $pos = $atoms->{pos}->encode($fs);
    if($pos eq 'J')
    {
        $pos .= $atoms->{other_real_type}->encode($fs);
    }
    elsif($pos eq 'F')
    {
        $pos .= $atoms->{idiom_type}->encode($fs);
    }
    my @values;
    if(exists($features->{$pos}))
    {
        my @features = @{$features->{$pos}};
        for(my $i = 0; $i<=$#features; $i++)
        {
            confess("Unknown atom '$features[$i]'") if(!exists($atoms->{$features[$i]}));
            $values[$i] = $atoms->{$features[$i]}->encode($fs);
            if($features[$i] eq 'gender')
            {
                $values[$i] = _internal_to_surface_gender($pos, $values[$i]);
            }
            elsif($features[$i] eq 'number')
            {
                $values[$i] = _internal_to_surface_number($pos, $values[$i]);
            }
            elsif($features[$i] eq 'valency5')
            {
                # Valency of verbs is encoded in two consecutive values.
                $values[$i+1] = substr($values[$i], 1, 1);
                $values[$i]   = substr($values[$i], 0, 1);
                $i++;
            }
        }
    }
    my $tag;
    # Convert the array of values to a tag in the XML format.
    # If $values[0] is empty, then all are empty.
    # untagged tokens in multi-word expressions have empty tags like this:
    # <i1></i1><i2></i2><i3></i3><i4></i4><i5></i5><i6></i6><i7></i7><i8></i8><i9></i9><i10></i10><i11></i11>
    if(!defined($values[0]) || $values[0] eq '')
    {
        $tag = '<i1></i1><i2></i2><i3></i3><i4></i4><i5></i5><i6></i6><i7></i7><i8></i8><i9></i9><i10></i10><i11></i11>';
    }
    else
    {
        for(my $i = 0; $i<11; $i++)
        {
            my $iplus = $i+1;
            my $value = $values[$i];
            $value = '' if(!defined($value));
            # In the corpus, undefined feature values are encoded either as empty strings (<i10></i10>) or using underscores (<i10>_</i10>).
            # The choice is arbitrary and there is no meaningful difference between the two ways.
            # We do not attempt to reconstruct the tags in the corpus. Instead, our list of permitted tags always prefers the empty strings.
            $tag .= "<i$iplus>$value</i$iplus>";
        }
    }
    return $tag;
}



sub compressed_list
{
    my $self = shift;
    my $list = $self->list();
    my @clist;
    foreach my $tag (@{$list})
    {
        my $tag1 = $tag;
        my $compressed = '';
        while($tag1 =~ s/^<i(\d+)>(.?)<\/i\1>//)
        {
            my $character = $2;
            if(!defined($character) || $character eq '')
            {
                $character = '_';
            }
            $compressed .= $character;
        }
        # Erase trailing underscore characters.
        $compressed =~ s/_+$//;
        push(@clist, $compressed);
        print("$compressed\n");
    }
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# 236 (pmk_kr.xml), after cleaning: 212
# 10900 (pmk_dl.xml), after cleaning: 10813
# after addition of missing other-resistant tags: 12385
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    # In order to make this file smaller, the list is given in a compressed
    # (but also more readable) form.
    my $list = <<end_of_list

01111
01114
01121
01122
01123
01131
01132
01141
01143
01151
01161
01171
01211
01213
01221
01231
01241
01251
01261
01271
01311
01321
01322
01331
01341
01343
01351
01361
01371
01611
01612
01621
01622
01631
01641
01651
01661
01671
01911
01921
01931
01941
01951
01961
01971
01974
02111
02112
02113
02114
02121
02131
02132
02133
02141
02142
02143
02151
02161
02171
02172
02211
02214
02221
02231
02233
02241
02251
02261
02271
02311
02312
02321
02324
02331
02333
02341
02342
02351
02352
02361
02371
02373
02411
02412
02511
02513
02521
02522
02531
02533
02541
02551
02561
02571
02611
02621
02631
02641
02651
02661
02711
02712
02721
02731
02741
02751
02761
02771
02811
02812
02813
02821
02822
02831
02841
02851
02861
02871
02911
02914
02921
02922
02931
02932
02933
02934
02941
02943
02951
02953
02961
02962
02971
02974
03111
03112
03113
03114
03121
03122
03131
03132
03133
03141
03142
03143
03151
03152
03153
03161
03171
03172
03173
03174
03211
03212
03221
03222
03231
03232
03241
03251
03252
03311
03321
03331
03341
03351
03361
03371
03511
03513
03531
03534
03541
03711
03712
03713
03714
03721
03722
03731
03732
03741
03751
03752
03811
03812
03813
03821
03831
03841
03842
03861
03871
03911
03912
03913
03914
03921
03931
03941
03942
03943
03951
03971
03973
03974
04111
04112
04113
04121
04122
04123
04124
04131
04132
04134
04141
04142
04143
04151
04152
04161
04162
04171
04211
04212
04221
04231
04241
04251
04271
04311
04321
04331
04341
04342
04343
04351
04361
04371
04411
04413
04414
04431
04433
04441
04451
04461
04511
04514
04521
04524
04531
04534
04541
04571
04611
04631
04641
04711
04721
04731
04741
04751
04761
04771
04811
04812
04813
04821
04822
04823
04831
04832
04833
04841
04842
04851
04861
04871
04911
04912
04913
04914
04921
04922
04923
04924
04931
04932
04933
04941
04942
04943
04951
04952
04953
04954
04961
04971
04974
05111
05113
05121
05122
05123
05131
05132
05134
05141
05151
05152
05161
05162
05163
05171
05211
05221
05222
05231
05232
05241
05251
05271
05321
05341
05361
05511
05512
05521
05531
05541
05551
05561
05571
05611
05612
05613
05621
05623
05631
05641
05651
05671
05711
05743
05811
05814
05831
05841
05851
05861
05871
05911
05912
05913
05921
05931
05932
05933
05941
05971
05974
1110111-
11101111
11101112
11101113
11101114
11101116
11101117
11101118
11101119
11101122
11101123
11101124
11101127
11101128
1110113-
11101132
11101133
11101134
11101137
11101138
1110114-
11101142
11101143
11101144
11101147
11101148
11101149
11101155
1110116-
11101162
11101163
11101164
11101168
11101172
11101173
11101174
11101178
1110119-
1110121-
11101211
11101212
11101213
11101214
11101216
11101218
11101219
1110122-
11101221
11101222
11101223
11101224
11101227
11101228
11101229
1110123-
11101232
11101233
11101234
11101237
11101238
11101239
1110124-
11101241
11101242
11101243
11101244
11101247
11101248
11101249
11101255
11101262
11101263
11101264
11101268
11101269
1110127-
11101272
11101273
11101274
11101277
11101278
1110129-
11101299
11101311
11101312
11101316
11101318
11101319
11101342
11101942
11101998
1110311-
11103111
11103112
11103113
11103115
11103116
11103118
11103119
11103122
11103123
11103124
11103128
11103132
11103133
11103134
11103138
1110314-
11103142
11103143
11103144
11103147
11103148
11103149
11103155
11103162
11103163
11103164
11103172
11103173
11103174
11103177
11103178
1110319-
1110321-
11103211
11103212
11103213
11103214
11103216
11103218
11103219
11103221
11103222
11103223
11103224
11103227
11103228
11103229
1110323-
11103232
11103233
11103234
11103237
11103238
1110324-
11103241
11103242
11103243
11103244
11103247
11103248
11103249
11103255
11103262
11103263
11103264
11103267
11103268
11103272
11103273
11103274
11103277
11103278
1110329-
11103299
11103311
11103312
11103319
11103342
11103998
11104111
11104112
11104114
11104116
11104118
11104119
1110412-
11104122
11104123
11104124
11104132
11104133
11104137
11104138
11104141
11104142
11104143
11104144
11104147
11104148
11104155
11104162
11104163
11104172
11104173
11104174
1110419-
11104211
11104222
11104223
11104228
11104242
11104243
11104248
11104262
11111111
11111112
11111113
11111116
11111118
11111119
11111122
11111123
11111128
11111132
11111139
1111114-
11111142
11111144
11111148
11111151
11111155
11111172
11111211
11111212
11111216
11111219
11111223
11111228
11111232
11111242
11111248
11111268
11111942
1111212-
11113111
11113112
11113116
11113118
11113119
11113121
11113122
11113123
11113124
11113128
11113132
11113142
11113148
11113155
11113162
11113168
11113172
11113178
11113211
11113212
11113218
11113223
11113242
11113272
11113273
11114111
11114142
11121111
11121112
11121116
11121118
11121123
11121127
11121132
11121142
11121148
11121211
11121212
11121216
11121218
11121219
11121223
11121228
11121232
11121233
11121242
11121243
11121248
11121272
11121273
11121278
1112129-
11122212
11123111
11123112
11123116
11123118
11123119
11123123
11123134
11123142
11123162
11123163
11123168
11123174
11123211
11123212
11123216
11123218
11123219
11123223
11123224
11123228
11123233
11123242
11123262
11123273
11123299
11123311
11124112
11124211
11131111
11131112
11131113
11131116
11131118
11131119
11131121
11131122
11131123
11131124
11131128
11131132
11131133
11131134
11131138
11131142
11131143
11131144
11131148
11131162
11131168
11131172
11131173
11131178
1113121-
11131211
11131212
11131216
11131218
11131219
11131222
11131223
11131224
11131227
11131228
11131232
11131233
11131242
11131243
11131244
11131247
11131248
11131249
11131262
11131268
11131272
11131273
11131278
11131311
11133111
11133112
11133116
11133118
11133119
11133122
11133123
11133142
11133148
11133168
11133172
11133211
11133212
11133218
11133219
11133222
11133223
11133228
11133229
11133232
11133242
11133248
11133249
11133263
11133272
11133273
11133274
11133323
11133342
11134111
11134112
11134119
11134123
11134132
11134142
11134174
11134219
11141223
11151112
11151123
11151211
11151228
11151242
11151273
11153122
11153123
11153211
11154242
11161122
11171218
11181111
11181116
11181242
11183111
11183118
11183132
11183148
11183216
11183222
11191111
11191112
11191142
11191211
11191219
11191222
11191242
11191272
11193111
11193142
11193216
11193242
11201111
11201112
11201116
11201118
11201122
11201132
11201142
11201147
11201148
11201155
11201172
11201173
11201174
11201178
11201211
11201212
11201216
11201227
11201228
11201242
11201243
11201247
11201262
11201272
11201273
11201277
1120129-
11202211
11202234
11203111
11203112
11203116
11203118
11203142
11203168
11203211
11203216
11203222
11203228
11203232
11203242
11203262
11203267
11204128
11204132
11204142
11204148
11204219
11204223
11204238
11204242
11204272
11204273
11223118
11231111
11231116
11231211
11231223
11233118
11234112
11234248
11251111
11251278
11301112
11302111
11302112
11302116
11302117
11302118
11302119
11302121
11302122
11302123
11302124
11302127
11302128
11302129
11302132
11302133
11302138
11302139
1130214-
11302141
11302142
11302143
11302144
11302147
11302148
11302149
11302162
11302163
11302164
11302167
11302168
11302172
11302173
11302174
11302177
11302178
11302179
1130219-
11302199
11302211
11302212
11302216
11302218
11302219
11302222
11302223
11302224
11302228
11302232
11302238
11302242
11302243
11302244
11302247
11302248
11302249
1130226-
11302262
11302263
11302264
11302268
11302272
11302273
11302274
11302277
11302278
11302279
1130229-
11302299
11302311
11302316
11302318
11302319
11302322
11302328
11302332
11302342
11302362
11302373
11302377
1130239-
11302511
11302512
11302516
1130252-
11302522
11302523
11302528
11302542
11302543
11302562
11302573
1130259-
1130311-
11303111
11303112
11303116
11303118
11303119
1130312-
11303122
11303123
11303124
11303128
11303132
11303137
11303138
1130314-
11303142
11303143
11303144
11303147
11303148
11303149
11303162
11303163
11303164
11303167
11303168
11303172
11303173
11303174
11303177
11303178
11303179
1130319-
11303211
11303212
11303215
11303216
11303218
11303219
1130322-
11303221
11303222
11303223
11303224
11303227
11303228
11303232
11303242
11303243
11303244
11303247
11303248
11303249
11303255
1130326-
11303262
11303263
11303264
11303268
11303272
11303273
11303274
11303277
11303278
11303279
1130329-
11303311
11303316
11303319
11303322
11303323
11303324
11303328
11303342
11303343
11303347
11303348
11303362
11303363
11303368
11303372
11303373
11303377
11303378
1130339-
11303399
11303532
11303572
11304111
11304112
11304113
11304116
11304117
11304118
11304119
11304122
11304123
11304124
11304127
11304128
11304132
11304139
11304142
11304143
11304148
11304149
11304162
11304163
11304164
11304172
11304173
11304174
11304178
11304179
1130419-
11304211
11304212
11304216
11304218
11304219
11304222
11304223
11304224
11304228
11304242
11304243
11304244
11304247
11304248
11304262
11304263
11304264
11304268
11304272
11304273
11304274
11304278
1130429-
11304311
11304316
11304322
11304342
11304362
11304364
11304368
11304372
11304511
11304516
11304519
11304522
11304523
11304528
11304532
11304542
11304547
11304548
11304562
11304564
11304572
11312112
11312118
11312122
11312123
11312142
11312148
11312162
11312172
11312211
11312228
11312242
11312263
11313111
11313122
11313142
11313147
11313148
11313162
11313172
11313211
11313212
11313216
11313242
11313316
11313322
11314138
11314148
11314173
11314242
11314333
11322116
11322118
11322119
11322142
11322146
11322148
11322172
11322211
11322212
11322216
11322218
11322242
11322247
11322248
11322262
11322272
11322278
11322299
11322319
11322342
11322362
11322372
11323111
11323112
11323116
11323122
11323123
11323142
11323147
11323167
11323172
11323211
11323212
11323216
11323218
11323242
11323263
11323272
11323311
11323316
11323342
11323372
11324112
11324116
11324119
11324142
11324148
1132419-
11324242
11324248
11324342
11332111
11332116
11332118
11332119
11332122
11332142
11332147
11332148
11332162
11332172
1133219-
11332211
11332216
11332228
11332242
11332262
11332278
11332342
11333111
11333112
11333118
11333132
11333142
11333162
11333178
11333211
11333212
11333218
11333219
11333228
11333242
11333248
11333249
11333278
11333342
11333372
11334111
11334149
11334242
11352111
11352118
11352119
11352142
11352223
11353111
11353242
11382122
11382142
11382224
1138329-
11392211
11393142
11393342
11401116
11401128
11401218
11401224
11401242
11401511
1140211-
11402111
11402112
11402113
11402114
11402116
11402118
11402119
1140212-
11402121
11402122
11402123
11402124
11402127
11402128
11402129
1140213-
11402132
11402133
11402134
11402137
11402138
11402139
1140214-
11402141
11402142
11402143
11402144
11402146
11402147
11402148
11402149
1140216-
11402162
11402163
11402164
11402167
11402168
11402169
1140217-
11402172
11402173
11402174
11402177
11402178
11402179
1140219-
11402199
1140221-
11402211
11402212
11402216
11402218
11402219
1140222-
11402221
11402222
11402223
11402224
11402227
11402228
11402229
1140223-
11402232
11402233
11402238
11402242
11402243
11402244
11402246
11402247
11402248
11402249
1140226-
11402262
11402263
11402264
11402267
11402268
11402269
11402272
11402273
11402274
11402277
11402278
1140229-
11402298
11402299
11402311
11402312
11402316
11402319
11402322
11402323
11402324
11402328
11402332
11402334
11402338
11402342
11402344
11402347
11402348
11402349
11402362
11402363
11402368
11402372
11402374
11402378
11402512
11402523
11402528
11402572
1140311-
11403111
11403112
11403113
11403116
11403118
11403119
1140312-
11403121
11403122
11403123
11403124
11403127
11403128
11403129
1140313-
11403132
11403133
11403134
11403137
11403138
11403139
1140314-
11403141
11403142
11403143
11403144
11403146
11403147
11403148
11403149
1140316-
11403162
11403163
11403164
11403167
11403168
11403169
1140317-
11403172
11403173
11403174
11403177
11403178
11403179
1140319-
11403211
11403212
11403216
11403218
11403219
1140322-
11403221
11403222
11403223
11403224
11403227
11403228
11403229
11403232
11403233
11403234
11403238
11403242
11403243
11403244
11403247
11403248
11403249
1140326-
11403262
11403263
11403264
11403267
11403268
11403269
1140327-
11403272
11403273
11403274
11403278
11403279
1140329-
11403298
11403299
11403311
11403316
11403319
1140332-
11403322
11403323
11403328
11403332
11403333
11403342
11403343
11403344
11403348
11403349
11403362
11403363
11403364
11403368
11403372
11403374
1140339-
11403511
11403512
11403516
11403518
11403519
11403522
11403523
11403524
11403527
11403528
11403532
11403538
11403541
11403542
11403543
11403544
11403548
11403562
11403568
11403569
11403573
11403574
11403919
1140399-
11403999
11404111
11404112
11404113
11404114
11404116
11404118
11404119
11404122
11404123
11404124
11404127
11404128
1140413-
11404132
11404133
11404134
11404137
11404138
1140414-
11404141
11404142
11404143
11404144
11404147
11404148
11404149
11404154
11404161
11404162
11404163
11404164
11404167
11404168
11404169
11404172
11404173
11404174
11404177
11404178
1140419-
11404199
11404211
11404212
11404216
11404218
11404219
1140422-
11404222
11404223
11404224
11404227
11404228
11404232
11404233
11404242
11404243
11404244
11404248
11404249
11404262
11404263
11404264
11404267
11404268
11404269
11404272
11404273
11404277
11404278
1140429-
11404298
11404311
11404323
11404342
11404348
11404373
11404374
11404511
11404512
11404518
11404523
11404524
11404528
11404534
11404542
11404562
11404942
1140499-
11409322
11409328
11412111
11412112
11412116
11412118
11412119
11412122
11412123
11412124
11412127
11412128
11412132
11412134
11412141
11412142
11412143
11412144
11412147
11412148
1141216-
11412162
11412163
11412164
11412168
11412169
11412172
11412173
11412174
11412178
1141219-
11412211
11412212
11412216
11412218
11412222
11412223
11412224
11412228
11412238
11412242
11412248
11412249
11412262
11412263
11412272
11412274
11412278
1141229-
11412311
11412338
1141311-
11413111
11413112
11413113
11413116
11413118
11413119
11413121
11413122
11413123
11413124
11413127
11413128
11413132
11413133
11413138
11413142
11413143
11413144
11413147
11413148
11413149
11413162
11413163
11413164
11413167
11413168
1141317-
11413172
11413173
11413174
11413177
11413178
11413179
11413211
11413212
11413218
11413219
11413222
11413223
11413224
11413227
11413228
11413232
11413233
11413238
11413242
11413243
11413247
11413248
11413249
11413262
11413268
11413272
11413273
11413278
1141329-
11413319
11413348
11413511
11413522
11413543
11413562
11414111
11414112
11414113
11414116
11414118
11414119
11414122
11414123
11414124
11414128
11414132
11414138
11414142
11414144
11414148
11414149
11414162
11414164
11414168
11414172
11414173
11414174
11414178
11414211
11414224
11414228
11414242
11414248
11414262
11414264
11414268
11414362
11414511
11414516
11422111
11422112
11422116
11422118
11422119
11422121
11422122
11422123
11422128
11422132
11422138
11422141
11422142
11422143
11422144
11422148
11422149
11422162
11422163
11422164
11422168
1142217-
11422172
11422177
11422178
1142219-
11422193
11422211
11422212
11422216
11422218
11422219
11422222
11422223
11422228
11422238
11422241
11422242
11422243
11422244
11422248
11422262
11422263
1142229-
11422311
11422316
11422319
11422323
11422328
11422342
11422349
11423111
11423112
11423116
11423118
11423119
11423121
11423122
11423123
11423124
11423128
11423129
11423132
11423134
11423138
11423142
11423143
11423144
11423147
11423148
11423149
11423162
11423163
11423164
11423168
11423169
1142317-
11423172
11423173
11423174
11423177
11423178
11423179
1142319-
11423211
11423212
11423216
11423218
11423219
11423222
11423223
11423224
11423228
11423238
11423241
11423242
11423247
11423248
11423262
11423263
11423268
11423272
11423273
11423274
11423278
11423324
11423342
11423522
11423523
11423562
11424111
11424112
11424114
11424116
11424123
11424142
11424148
11424162
11424172
11424174
11424211
11424222
11424223
11424228
11424264
11424268
11424512
11431242
11432111
11432112
11432116
11432118
11432119
11432121
11432122
11432123
11432124
11432128
11432132
11432133
11432138
1143214-
11432142
11432143
11432144
11432148
1143216-
11432162
11432163
11432164
11432167
11432168
11432172
11432174
11432178
1143219-
11432211
11432212
11432216
11432218
11432219
11432222
11432223
11432224
11432228
11432232
11432238
11432242
11432243
11432244
11432248
11432249
11432262
11432264
11432268
11432272
11432278
1143229-
11432311
11432323
11432328
11432342
11433111
11433112
11433116
11433118
11433119
11433122
11433123
11433124
11433128
11433132
11433138
1143314-
11433142
11433143
11433144
11433147
11433148
11433149
11433162
11433163
11433164
11433167
11433168
11433169
11433172
11433173
11433178
11433199
11433211
11433212
11433216
11433218
11433219
11433222
11433223
11433224
11433228
11433232
1143324-
11433241
11433242
11433243
11433248
11433249
11433262
11433263
11433264
11433268
11433272
11433273
11433278
1143329-
11433319
11433362
11433373
11433519
11433523
11433562
11433568
11434111
11434112
11434116
11434119
11434122
11434123
11434124
11434128
11434132
11434133
11434134
11434137
11434142
11434143
11434148
11434162
11434163
11434164
11434167
11434168
11434172
11434174
11434178
11434211
11434222
11434223
11434228
11434242
11434248
11434262
11434263
11434268
11434272
1143429-
11434511
11434512
11434516
11434523
11434998
11442111
11442112
11442122
11442128
11442142
11442211
11442216
11442219
11443111
11443112
11443116
11443119
11443122
11443123
11443142
11443147
11443148
11443161
11443162
11443173
11443178
11443223
11443228
11443242
1144399-
11444111
11444142
11444148
11444168
11452111
11452112
11452122
11452142
11452148
11452172
11452178
11452216
11452219
11452228
11452242
11452248
11453111
11453112
11453113
11453118
11453119
11453123
11453128
11453142
11453144
11453147
11453148
11453178
11453211
11453219
11453224
11453228
11453242
11453264
11453511
11453562
11453919
11454228
11463123
11464523
11472111
11472112
11472116
11472119
11472123
11472128
11472142
11472143
11472148
11472162
11472172
11472173
11472199
11473111
11473116
11473118
11473123
11473132
11473142
11473172
11473178
11473179
11473213
11473242
11474111
11482111
11482112
11482116
11482119
11482122
11482142
11482144
11482168
11482174
11482211
11482212
11483111
11483112
11483118
11483119
11483122
11483128
11483138
11483142
11483148
11483162
11483211
11483212
11483242
11484112
11484142
11492111
11492112
11492119
11492123
11492124
11492128
11492142
11492148
11492162
11492168
11492172
11492211
11492223
11492228
11492242
11492272
11492311
11493111
11493116
11493119
11493123
11493124
11493142
11493143
11493147
11493148
11493164
11493167
11493172
11493178
11493223
11493228
11493242
11493268
11494142
1149419-
11494242
11494248
1190111-
11901112
11901116
1190112-
1190113-
1190114-
1190115-
1190116-
1190117-
1190119-
1190121-
1190122-
1190123-
1190124-
1190125-
1190126-
1190127-
1190129-
1190131-
1190132-
1190133-
1190134-
1190136-
1190137-
1190151-
1190194-
1190199-
1190211-
11902111
11902112
11902116
11902118
11902119
1190212-
11902122
11902123
11902124
11902127
11902128
1190213-
11902132
1190214-
11902142
11902143
11902144
11902147
11902148
1190216-
11902162
11902163
11902164
11902167
11902168
11902169
1190217-
11902172
11902173
11902174
11902178
1190219-
11902199
1190221-
11902211
11902212
11902216
11902218
11902219
1190222-
11902222
11902223
11902227
11902228
1190223-
11902232
1190224-
11902242
11902247
11902248
1190226-
11902262
11902263
11902264
11902268
1190227-
1190229-
1190231-
1190232-
1190233-
1190234-
1190236-
1190237-
1190239-
1190251-
1190252-
1190254-
1190256-
1190257-
1190259-
1190299-
1190311-
11903111
11903112
11903116
11903118
11903119
1190312-
11903122
11903123
11903124
11903127
11903128
1190313-
11903132
11903133
1190314-
11903142
11903143
11903144
11903147
11903148
1190315-
1190316-
11903162
11903163
11903164
11903167
11903168
11903169
1190317-
11903172
11903173
11903174
11903178
1190319-
1190321-
11903211
11903212
11903216
11903218
11903219
1190322-
11903222
11903223
11903224
11903227
11903228
1190323-
1190324-
11903242
11903243
11903248
1190325-
1190326-
11903262
11903263
11903264
11903268
1190327-
11903272
11903273
1190329-
1190331-
1190332-
11903322
1190333-
1190334-
11903342
1190336-
11903362
11903363
1190337-
1190339-
1190351-
1190352-
1190353-
1190354-
1190356-
1190357-
1190391-
1190399-
1190411-
11904111
11904112
11904113
11904116
11904118
11904119
1190412-
11904122
11904123
11904124
11904127
11904128
1190413-
11904134
1190414-
11904142
11904147
11904148
1190415-
1190416-
11904162
11904163
11904164
11904167
11904168
1190417-
11904172
11904178
1190419-
1190421-
11904211
11904212
11904218
11904219
1190422-
11904222
11904223
11904224
11904228
1190423-
1190424-
11904242
1190426-
11904262
11904263
11904264
11904267
11904268
11904269
1190427-
11904273
11904274
1190429-
11904299
1190431-
1190432-
1190433-
1190434-
1190436-
1190437-
1190451-
1190452-
1190453-
1190454-
1190456-
1190457-
1190491-
1190492-
1190494-
1190499-
1190911-
1190932-
1190999-
11912111
11912116
11912122
11912123
11912134
11912142
11912162
11912211
11912248
1191229-
11913111
11913112
11913119
11913122
11913132
11913162
11913163
11913172
11913218
11913242
11913248
1191329-
11913318
11914123
11914143
11914162
11914168
11921211
11922111
11922112
11922116
11922122
11922123
11922142
11922148
11922162
11922168
11922169
11922199
11922211
11923111
11923112
11923116
11923119
11923122
11923123
11923128
11923132
11923142
11923162
11923163
11923167
11923168
11923169
11923211
11923219
11923222
11923228
11923242
11923248
11924142
11924148
11924162
11924164
11931119
11932111
11932112
11932119
11932122
11932123
11932148
11932162
11932168
11932211
11932216
11932222
11932228
11932242
11932262
11933111
11933112
11933116
11933122
11933124
11933127
11933142
11933144
11933162
11933164
11933168
11933211
11933216
11933218
11933219
11933242
11933262
11933268
11933322
11934111
11934112
11934122
11934123
11934132
11934162
11934163
11934164
11934168
11934223
1193426-
11934264
11952142
11952242
11952248
11953147
11953162
11953211
11953249
11954112
11954122
11963122
11973148
11973263
11982142
11992112
11992142
11992164
11992211
11993112
11993223
12101111
12101112
12101116
12101118
12101123
12101124
12101132
12101138
12101142
12101143
12101148
12101168
12101172
12101173
12101178
12101211
12101218
12101219
12101222
12101223
12101224
12101228
12101232
12101242
12101243
12101248
12101262
12101263
12101272
12101273
1210129-
12101333
12103111
12103112
12103116
12103118
12103119
12103122
12103123
12103124
12103129
12103132
12103138
12103142
12103143
12103144
12103148
12103162
12103163
12103172
12103173
1210321-
12103211
12103212
12103216
12103218
12103219
12103222
12103223
12103224
12103228
12103229
12103232
12103238
12103242
12103244
12103255
12103263
12103272
12103273
1210329-
12109111
12111111
12111116
12111132
12111172
12113111
12113112
12113118
12113142
12113211
12121211
12121228
12123111
12123112
12123116
12123118
12123211
12131111
12131118
12131133
12131142
12131178
12131211
12131223
12131228
12131238
12131242
12131272
12131273
12133111
12133118
12133128
12133162
12133211
12133212
12133219
12133224
12133272
12182169
12303142
12303147
12304142
12323142
12402128
12402216
12402242
12402342
12403111
12403116
12403118
12403122
12403123
1240314-
12403142
12403143
12403144
12403147
12403148
12403162
12403163
12403164
12403172
12403211
12403228
12403242
12403268
12403312
12403316
12403322
12403362
12403363
12403364
1240414-
12404142
12404228
12404242
12414111
12423112
12433142
1290199-
1290299-
1290399-
12904142
12904164
1290499-
1290999-
13101211
13101272
13101311
13101319
13101322
13101372
13131362
13303111
1390199-
1390399-
14101211
14101278
14103112
14402128
14402142
14402172
14402212
14402222
14402232
14402242
14402248
14403111
14403116
14403118
14403122
14403123
14403127
14403128
14403138
14403142
14403144
14403147
14403148
14403149
14403162
14403164
14403168
14403172
14403173
14403177
14403211
14403218
14403228
14403242
14403243
14403248
14403272
14412118
14412148
14412218
14412228
14413111
14413116
14413118
14413128
14413142
14413147
14413148
14413149
14413162
14413168
14413212
14413228
14413247
14413268
14422142
14423211
14423248
14433119
14433142
14433248
1490199-
1490299-
14903162
1490399-
1490499-
15304111
15304112
15304123
15304148
15324111
15403119
15403122
15404111
15404112
15404113
15404116
15404118
15404119
15404122
15404123
15404124
15404127
15404128
15404132
15404133
15404134
15404138
15404141
15404142
15404143
15404144
15404147
15404148
15404149
1540416-
15404162
15404163
15404164
15404167
15404168
1540417-
15404172
15404173
15404174
15404177
15404178
15404179
1540419-
15404199
15404211
15404212
15404216
15404218
15404219
15404222
15404223
15404224
15404228
15404234
15404238
15404242
15404243
15404244
15404248
15404262
15404264
15404268
15404278
15404919
15404942
15404948
1540499-
15413113
15414111
15414112
15414116
15414118
15414119
15414122
15414123
15414124
15414128
15414132
15414133
15414138
15414142
15414143
15414148
15414162
15414163
15414164
15414168
15414172
15414173
15414174
15414177
15414178
1541419-
15414199
15414211
15414228
15414248
15414923
15424111
15424112
15424116
15424119
15424122
15424123
15424128
15424142
15424143
15424147
15424148
15424149
15424162
15424164
15424172
15424174
15424178
15424211
15424242
15434111
15434112
15434116
15434119
15434122
15434123
15434124
15434134
15434142
15434148
15434162
15434163
15434164
15434168
15434173
15434178
15434211
15434212
15434216
15434218
15434219
15434222
15434223
15434228
15434242
15434262
15434268
15434911
1543499-
15444112
15444119
15444134
15444142
15444148
15454123
15454199
15464111
15464123
15464142
15464163
15474111
15474112
15474116
15474132
15474142
15474147
15474148
15474164
15474173
15474223
15484111
15484112
15484172
15494111
15494142
15494178
1590299-
1590399-
1590499-
16404111
16404112
16404123
16404142
16404163
16414118
16414123
1641419-
16424111
16424118
16424119
16424123
16424133
16424148
16424199
16434112
16464199
16474123
1690411-
1690412-
1690413-
1690414-
1690416-
1690419-
1690499-
17101211
17101222
17101223
17101232
17304112
17304148
1730419-
17304248
17402142
17403111
17403142
17403162
17403164
17403173
17404116
17404142
17404147
17404148
17404228
17404248
17404311
17414142
17414148
17414228
17414242
17414248
17433116
1790199-
1790299-
17903122
1790399-
1790499-
19103112
19304112
19304119
19304142
19404111
19404112
19404116
19404142
19404148
19424142
19424148
1990299-
1990399-
19904111
1990499-
21010111-1
21010111-2
2101011121
21010112-1
21010113-1
21010114-1
2101011421
21010117-1
21010121-1
2101012121
2101012123
21010122-1
2101012221
21010123-1
2101012321
21010124-1
21010126-1
21010127-1
2101012731
21010129-1
21010211-1
21010211-2
2101021121
21010212-1
2101021221
21010213-1
21010214-1
21010214-2
2101021421
21010216-1
2101021621
21010217-1
21010219-1
21010221-1
21010221-2
21010222-1
2101022221
21010223-1
21010224-1
2101022421
2101022431
21010226-1
2101022621
21010227-1
21010229-1
21010311-1
2101031121
2101031131
21010312-1
2101031221
21010313-1
2101031321
2101031331
21010314-1
2101031421
21010315-1
21010316-1
2101031621
21010317-1
2101031721
21010319-1
21010321-1
2101032121
2101032131
21010322-1
2101032221
2101032231
21010323-1
2101032321
21010324-1
21010324-2
21010326-1
2101032621
21010327-1
21010329-1
21010411-1
2101041121
21010412-1
2101041231
21010413-1
21010414-1
21010416-1
2101041621
2101041631
21010417-1
21010419-1
21010421-1
21010422-1
2101042221
21010424-1
21010426-1
2101042621
21010427-1
21010429-1
21010491-1
21010499-1
21010916-1
21010921-1
21010922-1
21011111-2
2101111122
21011114-2
21011121-2
2101112122
21011124-2
21011211-2
2101121122
21011221-2
2101122122
21011224-2
21011311-2
2101131122
2101131132
21011314-1
21011314-2
21011321-2
2101132122
21011324-2
21011411-2
2101141122
21011414-1
21011414-2
21011421-1
21011421-2
2101191122
21011921-2
21012111-2
21012121-2
21012211-2
21012311-2
21012321-2
21012324-2
21012411-2
21013111-2
2101311422
21013121-2
21013211-2
21013311-2
21013314-3
21013317-2
21013321-2
2101332122
21013411-2
21013991-2
21014111-2
2101411122
21014121-2
21014121-3
21014211-3
21014224-3
21014311-2
2101431122
2101431123
21014314-1
21014411-2
2101441122
21014414-3
21014417-3
21018111-2
21018111-3
21018111-5
2101811122
2101811123
21018112-3
21018113-3
21018114-3
21018114-5
2101811423
21018121-3
2101812123
2101812133
21018122-3
2101812223
2101812233
21018123-3
2101812323
21018124-3
2101812423
21018127-3
21018211-3
21018211-5
2101821123
21018212-3
21018212-5
21018214-3
21018214-5
2101821423
21018216-3
21018221-3
21018221-5
21018222-2
21018222-3
21018224-3
21018224-5
21018311-2
21018311-3
21018311-5
2101831123
2101831131
21018312-3
21018312-5
21018313-3
21018314-3
21018314-5
2101831423
21018316-3
21018316-5
21018317-3
21018317-5
21018321-3
21018321-5
2101832123
21018322-3
2101832223
21018324-3
21018324-5
21018326-3
21018399-5
21018411-3
21018411-5
21018412-3
21018412-5
21018414-2
21018414-3
21018416-3
21018417-1
21018417-3
21018421-3
21018422-3
21018424-3
2101842423
21018426-3
21018429-3
21018911-3
21018912-3
21018912-5
21018913-3
21018914-3
21018916-3
21018916-5
21018917-3
21018917-5
21018919-5
21018921-3
21018922-3
21018924-3
21018926-5
21018991-3
21018994-3
21018994-5
21018999-3
21018999-5
2101899924
21020212-1
21020216-1
21020412-1
21030111-1
2103011121
21030112-1
2103011221
21030114-1
2103011421
21030117-1
21030121-1
21030121-2
2103012121
2103012122
2103012131
21030122-1
2103012221
21030123-1
2103012321
21030124-1
2103012431
21030127-1
21030211-1
2103021121
2103021131
2103021132
21030212-1
2103021221
2103021231
21030213-1
21030214-1
2103021421
2103021431
21030216-1
2103021621
21030217-1
21030219-1
21030221-1
2103022121
2103022131
21030222-1
2103022221
2103022231
21030223-1
2103022321
21030224-1
21030224-2
2103022421
2103022431
21030226-1
2103022631
21030227-1
21030229-1
21030311-1
21030311-2
2103031121
2103031131
21030312-1
2103031221
2103031231
21030313-1
2103031321
2103031331
21030314-1
21030314-2
2103031421
2103031431
21030316-1
21030316-5
2103031621
2103031631
21030317-1
2103031721
2103031731
21030319-1
2103031931
21030321-1
21030321-2
2103032121
2103032131
21030322-1
2103032231
21030323-1
21030324-1
2103032421
2103032431
21030326-1
2103032631
21030327-1
21030329-1
21030394-1
21030399-1
21030411-1
21030411-2
2103041121
2103041131
2103041132
21030412-1
2103041221
2103041231
21030413-1
2103041321
21030414-1
2103041421
21030415-1
21030416-1
2103041621
2103041631
21030417-1
2103041721
21030419-1
2103041921
21030421-1
21030421-2
21030422-1
21030424-1
2103042421
21030426-1
2103042631
21030427-1
21030499-1
2103049921
2103091121
21030912-1
21030922-1
21030929-1
21031111-1
21031111-2
2103111122
2103111132
2103111222
21031114-2
2103111432
21031117-2
21031121-2
2103112122
2103112132
21031211-1
21031211-2
21031211-3
2103121122
2103121132
21031214-2
2103121421
2103121422
21031221-2
2103122122
2103122132
21031224-1
21031311-2
2103131122
2103131132
21031312-1
21031312-2
21031314-2
21031321-1
21031321-2
2103132122
2103132132
21031322-2
21031324-2
21031411-1
21031411-2
2103141122
2103141132
21031412-2
2103141322
21031414-2
2103141422
2103141432
2103141732
21031421-2
21031422-2
2103142422
21031911-2
2103191122
2103191422
2103191922
21031921-2
2103192122
21031991-2
2103199922
21032111-2
21032121-2
2103212122
21032311-2
21032321-2
21032411-2
2103241122
21033111-2
2103311122
21033121-2
2103312122
21033211-2
21033221-2
21033311-1
21033311-2
21033311-5
2103331122
2103331132
2103331135
21033314-2
21033316-2
21033321-2
2103332122
21033324-1
21033411-1
21033411-2
2103341122
21033414-2
21033421-2
2103342122
21034111-2
2103411122
2103411221
21034114-3
21034121-2
2103412122
2103412222
2103421122
21034214-3
2103421421
2103421422
2103422122
2103422422
21034311-1
21034311-2
21034311-3
2103431122
2103431123
21034314-3
2103431421
21034321-2
2103432121
2103432122
2103432132
2103432421
2103432422
21034411-2
21034411-3
21034411-4
21034411-5
2103441122
2103441123
2103441125
2103441132
2103441133
2103441134
2103441135
2103442122
2103499922
21035111-2
21035121-1
21035121-2
2103512122
21035211-2
21035221-2
21035311-2
2103531122
21035321-2
21035411-2
21035411-5
2103541122
2103541125
21038111-2
21038111-3
21038111-4
21038111-5
2103811123
2103811132
2103811133
21038114-3
2103811433
2103811723
21038121-1
21038121-2
21038121-3
21038121-5
2103812123
21038122-3
2103812223
21038124-3
21038127-3
21038129-3
21038211-1
21038211-3
21038211-5
2103821122
2103821123
2103821233
21038214-3
21038214-5
2103821421
2103821423
21038217-3
21038219-2
21038219-5
21038221-3
2103822123
21038224-3
2103822425
21038229-5
21038311-2
21038311-3
21038311-5
2103831122
2103831131
2103831133
21038312-3
21038312-5
21038314-3
21038314-5
2103831421
2103831423
21038316-5
2103831621
2103831635
21038317-3
21038317-5
2103831721
2103831723
21038319-5
21038321-3
21038321-5
2103832122
2103832235
21038324-1
21038324-3
2103832421
2103832423
2103832433
21038411-1
21038411-2
21038411-3
21038411-4
21038411-5
2103841123
2103841124
2103841125
2103841131
2103841133
2103841135
21038412-1
2103841223
2103841233
21038413-3
2103841323
21038414-1
21038414-3
2103841421
2103841422
2103841433
21038416-3
21038419-1
21038419-3
21038419-4
2103841923
2103841933
2103842133
2103842433
21038911-3
21038912-5
21038913-3
21038916-5
21038917-3
21038919-3
21038919-5
2103891935
21038921-1
21038921-3
21038924-3
21038991-5
21038994-5
2103899423
21038999-3
21038999-5
2103899925
2103899935
21040111-1
2104011121
2104011231
21040117-1
21040121-1
2104012131
21040122-1
21040211-1
2104021121
2104021131
21040212-1
2104021221
21040213-1
2104021321
21040214-1
2104021421
2104021431
21040216-1
2104021621
2104021631
21040217-1
2104021721
2104021931
21040221-1
21040221-2
2104022121
21040222-1
2104022221
21040223-1
2104022321
21040224-1
2104022421
2104022431
21040226-1
2104022621
21040227-1
2104022731
21040311-1
2104031121
2104031131
21040312-1
2104031221
2104031231
21040313-1
2104031321
21040314-1
2104031421
2104031431
21040316-1
2104031621
21040317-1
2104031721
2104031731
2104031931
21040321-1
21040321-2
2104032121
2104032131
21040322-1
2104032221
2104032231
21040323-1
21040324-1
2104032421
2104032431
21040326-1
2104032621
21040327-1
21040329-1
21040411-1
2104041121
2104041131
2104041132
21040412-1
2104041221
21040413-1
2104041321
21040414-1
2104041421
2104041431
21040416-1
2104041621
21040417-1
2104041721
2104041731
21040421-1
21040422-1
2104042221
2104042231
21040423-1
21040424-1
2104042421
21040426-1
2104042621
21041111-1
21041111-2
2104111122
21041121-2
2104112122
21041211-2
2104121122
21041214-1
2104121732
21041221-2
2104122122
21041311-2
2104131121
2104131122
21041314-2
2104131422
21041321-2
2104132122
21041324-2
21041411-2
2104141122
2104141132
21041414-2
2104141422
21041416-1
21041421-2
21041424-2
2104192122
21042221-2
21043111-2
21043211-2
2104321122
2104322422
21043311-2
21043321-2
2104341122
2104411123
2104421121
2104421221
2104421421
2104422121
2104422421
2104431121
2104431122
2104431123
2104431325
2104431421
2104431423
2104432122
2104432421
2104441122
2104441125
2104441421
21048111-3
21048111-5
2104811123
21048114-3
2104811433
21048116-3
21048117-3
21048119-5
21048121-3
21048121-5
21048123-3
21048123-5
2104821121
2104821122
2104821123
2104821131
21048214-3
21048214-5
2104821421
2104821423
21048221-3
2104822123
2104822421
2104822633
21048311-3
21048311-5
2104831135
21048312-3
2104831323
2104831325
21048314-1
21048314-3
21048314-5
2104831421
2104831423
2104831425
2104831433
21048316-3
21048317-3
21048321-3
2104832233
21048324-3
2104832423
2104832425
21048327-3
21048411-3
21048411-4
2104841125
2104841133
21048414-3
2104841425
21048416-3
21048416-5
2104891233
2104891235
21048924-3
2104899935
21050111-1
21050112-1
21050113-1
21050114-1
21050116-1
21050121-1
21050122-1
21050123-1
21050124-1
21050126-1
21050127-1
21050211-1
21050211-2
21050212-1
21050213-1
21050214-1
21050216-1
21050217-1
21050219-1
21050219-2
21050221-1
21050222-1
2105022231
21050223-1
21050224-1
21050226-1
21050227-1
21050229-1
21050311-1
21050311-2
2105031131
21050312-1
21050313-1
21050314-1
21050316-1
21050317-1
21050319-1
21050321-1
21050322-1
21050323-1
21050324-1
21050326-1
21050327-1
21050329-1
21050411-1
21050412-1
21050412-3
2105041221
21050413-1
21050414-1
2105041421
21050416-1
21050417-1
21050419-1
21050421-1
21050422-1
21050423-1
21050424-1
21050426-1
21050427-1
21050911-1
21050911-5
21050912-1
21050921-1
21050922-1
21050929-1
21050999-1
21051111-2
21051121-2
21051211-2
21051214-2
21051221-2
21051224-2
21051311-2
21051312-1
21051321-2
21051322-2
21051324-2
21051411-2
21051412-2
21051414-2
21051424-2
21051911-2
21051924-2
21051994-2
21052111-2
21052211-2
21052411-2
21053111-2
21053211-2
21053221-2
21053411-2
21053411-5
21053421-2
21054111-2
21054121-2
21054129-3
21054211-2
21054214-1
21054214-2
21054214-5
21054216-1
21054221-1
21054224-1
21054311-2
21054314-1
21054317-1
21054321-2
21054322-1
21054324-1
21054324-2
21054411-2
21054411-3
21054411-5
21054412-1
21054413-1
21054414-1
21054417-1
21055311-2
21055411-2
21055411-3
21055411-5
21058111-3
21058112-3
21058113-3
21058114-3
21058117-3
21058121-1
21058121-3
21058121-5
21058122-3
21058123-3
21058124-3
21058126-3
21058211-3
21058212-2
21058212-3
21058212-5
21058214-1
21058214-3
21058216-3
21058217-1
21058222-3
21058224-3
21058226-3
21058294-3
21058311-1
21058311-3
21058311-5
21058312-3
21058314-1
21058314-3
21058314-5
21058316-1
21058316-5
21058321-1
21058321-3
21058322-1
21058322-3
21058324-1
21058324-3
21058394-3
21058411-2
21058411-3
21058411-5
2105841133
21058412-1
21058413-3
21058414-2
21058414-3
21058414-5
21058417-3
21058419-3
21058421-3
21058911-3
21058914-3
21058916-5
21058917-3
21058922-3
21058922-5
21058924-3
21058926-3
21058929-3
21058991-5
21058994-3
21058994-5
21058999-3
21058999-5
21090111-
210901112
210901113
21090112-
210901122
210901123
21090113-
21090114-
210901142
210901143
21090116-
21090117-
210901172
21090119-
21090121-
210901212
210901213
21090122-
210901222
210901223
21090123-
210901232
21090124-
210901242
210901243
21090126-
21090127-
210901273
21090129-
21090211-
210902112
210902113
21090212-
210902122
210902123
21090213-
210902132
21090214-
210902142
210902143
21090216-
210902162
210902163
21090217-
210902172
210902173
210902173
21090219-
210902193
21090221-
210902212
210902213
21090222-
210902222
210902223
21090223-
210902232
21090224-
210902242
210902243
21090226-
210902262
210902263
21090227-
210902273
21090229-
21090294-
21090311-
210903112
210903113
21090312-
210903122
210903123
21090313-
210903132
210903133
21090314-
210903142
210903143
21090315-
21090316-
210903162
210903163
21090317-
210903172
210903173
21090319-
210903193
21090321-
210903212
210903213
21090322-
210903222
210903223
21090323-
210903232
21090324-
210903242
210903243
21090326-
210903262
210903263
21090327-
21090329-
21090394-
21090399-
21090411-
210904112
210904113
21090412-
210904122
210904123
21090413-
210904132
21090414-
210904142
210904143
21090415-
21090416-
210904162
210904163
21090417-
210904172
210904173
21090419-
210904192
210904193
21090421-
210904212
210904213
21090422-
210904222
210904223
21090423-
21090424-
210904242
210904243
21090426-
210904262
210904263
21090427-
21090429-
21090491-
21090499-
210904992
21090911-
210909112
21090912-
210909123
21090913-
21090914-
210909142
210909142
21090916-
21090917-
21090919-
210909192
210909192
210909193
21090921-
210909212
210909212
210909212
21090922-
21090924-
21090926-
21090929-
21090991-
21090994-
210909942
21090999-
21090999
210909992
210909993
21091111-
210911112
210911113
210911122
21091114-
210911142
210911143
21091117-
21091121-
210911212
210911213
21091124-
21091211-
210912112
210912113
21091214-
210912142
210912173
21091221-
210912212
210912213
21091224-
210912242
21091311-
210913112
210913113
21091312-
21091314-
210913142
21091316-
21091317-
21091321-
210913212
210913213
21091322-
21091324-
21091411-
210914112
210914113
21091412-
210914132
21091414-
210914142
210914143
21091416-
210914173
21091421-
210914212
21091422-
21091424-
210914242
21091911-
210919112
210919142
210919192
21091921-
210919212
21091924-
21091991-
21091991-2
21091994-
210919992
21111311-2
21131321-2
21133121-2
21190111-
211901112
211901112
21190112-
21190114-
21190116-
21190117-
21190121-
211901212
211901213
21190122-
21190123-
21190124-
21190125-
21190127-
21190211-
21190212-
21190213-
21190214-
21190216-
211902162
21190217-
211902172
21190219-
21190221-
211902212
21190222-
21190223-
21190224-
21190226-
21190311-
211903112
21190312-
21190313-
21190314-
21190316-
21190317-
21190321-
211903212
211903212
211903212
21190322-
211903222
21190323-
21190324-
21190326-
211903262
21190327-
21190329-
21190391-
21190411-
211904112
211904112
211904112
21190412-
21190414-
21190416-
21190417-
21190419-
21190421-
21190422-
21190424-
21190426-
21190427-
21190429-
21190911-
21190913-
21190914-
21190921-
21190924-
21190924-
21190929-
21190929-
21190929-
21190994-
21190999
21191111-
211911112
21191114-
21191121-
211911212
21191122-
21191211-
21191214-
21191221-
211912212
21191224-
21191311-
211913112
21191314-
21191321-
211913212
21191324-
21191411-
211914112
21191414-
21191416-
21191421-
21191422-
21191424-
21191911-
21191921-
21191924-
21191929-
21290123-
21290221-
21290311-
21290316-
21290417-
21290916-
21290999
21310411-1
21311411-2
21313411-2
21314411-2
21335411-2
21340412-1
21390411-
21390412-
21390419
21391411-
21411111-2
21411121-2
21411211-2
21411311-2
21411321-2
21412111-2
21414111-2
21415111-2
21415121-2
21415311-2
21415321-2
21418211-3
21431121-2
21431311-2
2143131122
21431999-2
21433311-2
21434111-2
21434121-2
21434311-2
21435111-2
21435121-2
21435311-2
21490111-
21490121-
21490211-
21490311-
214903112
214903112
21490321-
21490999-
21490999-
21490999
21491111-
21491121-
21491211-
21491311-
214913112
21491321-
21491999-
21590111-
21590999
22110111-1
22110111-2
22110112-1
22110114-1
22110116-1
22110117-1
22110121-1
22110122-1
22110123-1
22110124-1
22110127-1
22110211-1
22110212-1
22110213-1
22110214-1
22110216-1
22110217-1
22110221-1
22110221-2
22110222-1
22110224-1
22110226-1
22110311-1
2211031121
22110312-1
22110313-1
22110314-1
22110316-1
22110317-1
22110321-1
22110322-1
2211032221
22110323-1
22110324-1
22110326-1
22110327-1
22110329-1
22110391-1
22110411-1
22110412-1
22110414-1
22110414-2
22110416-1
22110417-1
22110421-1
22110422-1
22110424-1
22110426-1
22110427-1
22110429-1
22111111-2
2211111122
22111114-2
22111121-2
2211112122
22111122-2
22111211-2
22111214-2
22111221-2
22111224-2
22111311-2
2211131122
22111314-2
22111321-2
2211132122
22111324-2
22111411-2
22111414-2
22111421-2
22111422-2
22111424-2
22111921-2
22111924-2
22112111-2
22112121-2
22112211-1
22112211-2
22112214-2
22112221-2
2211222122
22112224-2
22112311-2
22112321-2
22112324-2
22112411-1
22112411-2
22112414-2
22112421-2
22112911-2
22112921-2
22112929-1
22113111-2
22113111-5
22113121-2
22113211-2
22113214-2
22113221-2
22113224-2
22113311-1
22113311-2
2211331122
22113314-1
22113314-2
22113321-2
22113411-2
22113414-2
22113421-2
22113424-2
22114111-2
22114114-2
22114121-2
22114211-2
22114311-2
22114411-2
22114411-5
22114414-2
22115111-2
22115121-2
22115311-2
22115414-2
22118111-2
22118111-3
22118111-5
22118114-3
22118121-1
22118121-2
22118121-3
22118121-5
22118122-3
22118124-3
22118127-3
22118211-1
22118211-2
22118211-3
22118211-5
22118212-1
22118214-1
22118214-3
22118219-1
22118221-1
22118221-2
22118221-3
22118222-1
22118224-3
22118311-1
22118311-2
22118311-3
22118311-5
22118312-3
22118314-1
22118314-3
22118314-5
22118321-1
22118321-2
22118321-3
22118321-5
22118322-3
22118322-5
22118324-1
22118324-3
22118326-3
22118329-5
22118411-2
22118411-3
22118411-5
22118412-1
22118412-3
22118414-1
22118414-2
22118414-5
22118417-3
22118419-3
22118419-5
22118421-1
22118422-1
22118913-3
22118914-3
22118921-5
22118994-5
22120216-1
22121211-2
22124411-5
22128211-3
22130111-1
22130114-1
22130121-1
2213012131
22130124-1
22130211-1
22130212-1
22130213-1
22130214-1
22130216-1
2213021621
22130217-1
2213021721
22130221-1
2213022121
22130223-1
22130224-1
22130226-1
22130311-1
2213031121
22130312-1
22130314-1
22130316-1
22130317-1
22130321-1
22130324-1
22130326-1
22130327-1
22130329-1
22130411-1
22130412-1
22130414-1
22130416-1
22130421-1
22130422-1
22130424-1
22131111-2
22131121-2
2213112122
22131211-2
22131221-2
2213122122
22131311-2
2213131122
22131314-2
22131321-1
22131321-2
2213132122
22131411-2
2213141122
22131414-2
22131416-1
22131421-2
22132121-2
22132311-2
22132321-2
22132411-2
2213241122
22132414-2
22133111-2
22133121-2
2213312122
22133311-2
22133411-2
22133414-2
22134111-2
22134121-2
2213412122
22134221-2
22134311-2
2213431122
22134321-2
2213432621
22134411-2
22134411-5
22138111-3
22138111-5
22138121-2
22138121-3
22138121-5
22138122-3
22138124-3
22138125-3
22138211-3
22138311-1
22138311-2
22138311-3
22138311-5
22138312-3
22138321-3
22138321-5
22138324-3
22138411-5
22138414-5
22138421-3
22138424-3
22138911-3
22140224-1
22148211-3
22150211-1
22150212-1
22150214-1
22150216-1
22150311-1
22150313-1
22150314-1
22150316-1
22150317-1
22150322-1
22150324-1
22150326-1
22150327-1
22150411-1
22150414-1
22150416-1
22150422-1
22150426-1
22158214-5
22158317-3
22158411-5
22190999
22191211-2
22193311-2
22210123-1
22210311-1
22210316-1
22210417-1
22218916-5
22230221-1
22290999
22390419
22411111-2
22413111-2
22431111-2
22431321-2
22433111-2
22434111-2
22438111-2
22438311-2
22490999
22514111-2
22518111-2
22590999
23010414-1
23020123-1
23020316-1
23020317-1
23090123-
23090316-
23090317-
23090414-
23090999
23390419
23410121-1
23410211-1
23410212-1
23410214-1
23410216-1
23410314-1
23410316-1
23410321-1
23418224-3
23420113-1
23420121-1
23420313-1
23420314-1
23420324-1
23428111-3
23428311-3
23428314-3
23490111-
23490113-
23490121-
23490211-
23490212-
23490214-
23490216-
23490224-
23490311-
23490313-
23490314-
23490316-
23490321-
23490324-
23490999
3-01111
3-01211
3-01291
3-02113
3-02213
3-03111
3-03211
3-03291
3-04161
3-04211
3-05911
3-05991
3-09911
3-09941
3-09971
3-0999
3-09991
3-09994
3-14162
3-41193
3-41291
3-41991
3-43141
3-44134
3-44141
3-44144
3-44193
3-44991
3-45141
3-45193
3-45941
3-45944
3-45991
3-45994
3-49921
3-49941
3-49961
3-49971
3-49991
3-49994
3001111
3001141
3001191
3001211
3002111
3002171
3002191
3002241
3003111
3003112
3003121
3003141
3003142
3003171
3003191
3003211
3004111
3004112
3004131
3004141
3004191
3004244
3005911
3005941
3009121
3009161
3009211
3009231
3009291
3009911
3009921
3009931
3009941
300999
3009991
3009994
3011112
3011122
3011132
3011142
3011172
3011212
3011222
3011242
3011292
3012112
3012122
3012142
3012162
3012172
3012192
3012212
3012222
3012232
3012242
3012262
3012272
3012292
3013112
3013122
3013132
3013142
3013162
3013172
3013212
3013222
3013232
3013242
3013262
3013272
3013292
3014111
3014112
3014122
3014132
3014142
3014162
3014172
3014192
3014212
3014222
3014242
3014262
3015941
3015991
3019112
3019122
3019942
3021114
3022112
3022174
3022262
3023114
3023211
3023244
3024111
3029214
3032141
3033124
3033172
3034111
3034114
3034141
3034144
3042114
310111
3101111
310112
3101121
310113
3101131
3101134
310114
3101141
3101144
310116
3101161
310117
3101171
310121
3101211
310122
3101221
3101224
310123
3101231
3101234
310124
3101241
310126
3101261
310127
3101271
310211
3102111
310212
3102121
3102124
310213
3102131
310214
3102141
3102144
310216
3102161
310217
3102171
310221
3102211
310222
3102221
3102224
310223
3102231
310224
3102241
310226
3102261
310227
3102271
310311
3103111
3103114
310312
3103121
3103124
310313
3103131
310314
3103141
3103144
310316
3103161
3103164
310317
3103171
3103174
310319
3103191
310321
3103211
310322
3103221
3103224
310323
3103231
310324
3103241
3103244
310326
3103261
310327
3103271
310411
3104111
310412
3104121
310413
3104131
3104134
310414
3104141
3104144
310416
3104161
3104164
310417
3104171
310421
3104211
310422
3104221
3104224
310423
3104231
310424
3104241
310426
3104261
3105111
3105113
3105114
3105121
3105124
3105131
3105134
3105141
3105144
3105151
3105161
3105171
3105191
3105211
3105214
3105221
3105224
3105231
3105234
3105241
3105244
3105261
3105271
3105291
3105411
3105421
3105431
3105441
310911
310912
310913
310914
310915
310916
310917
310919
310921
3109211
310922
310923
3109231
310924
3109241
310926
310927
310929
310941
310942
310943
310944
310999
3111112
3111212
3113112
3115112
3115114
3115152
3115212
3115214
3115222
3115232
3115244
3115412
3121214
3123141
3125111
3125114
3125124
3125211
3125214
3125244
3131114
3132224
3133114
3134111
3135111
3135114
3135131
3135211
3135214
3141212
3143111
3145111
3145114
3145134
3145214
3145221
3145241
320111
3201111
320112
3201121
320113
3201131
320114
3201141
3201142
320116
3201161
320117
3201171
320119
320121
3201211
320122
3201221
320123
3201231
320124
3201241
3201244
320126
3201261
320127
3201271
320129
320211
3202111
3202112
320212
3202122
320213
320214
3202141
320216
320217
3202172
320219
320221
3202211
3202212
320222
3202221
320223
320224
3202241
3202242
320226
3202261
320227
320229
3202291
320297
320311
3203111
320312
3203122
320313
3203131
320314
3203141
3203142
3203144
320316
3203162
320317
3203171
320319
320321
3203211
320322
3203222
320323
3203231
3203232
320324
3203241
3203242
320326
3203261
320327
320329
3203292
320411
3204111
3204112
320412
3204121
3204122
3204124
320413
3204131
320414
3204141
3204144
320416
3204161
3204164
320417
3204171
3204174
320419
3204191
320421
320422
320424
3204241
3204242
320426
3204261
320427
320429
3204292
320494
3204941
3204942
3205161
3205911
3205921
3205931
3205934
3205941
3205944
3205961
3205964
3205971
3205974
3205991
320911
3209111
320912
3209121
320914
3209141
320916
320917
3209171
320919
3209191
320921
3209211
320922
3209221
320923
320924
3209241
320926
3209261
320927
3209271
320929
3209291
320991
3209911
320992
320993
320994
3209941
3209942
320996
320997
320999
3209991
3209992
3211111
3211112
3211122
3211131
3211132
3211142
3211162
3211172
3211211
3211212
3211222
3211232
3211242
3211244
3211272
3211292
3212112
3212122
3212132
3212142
3212161
3212162
3212171
3212172
3212192
3212212
3212222
3212232
3212242
3212262
3212272
3212972
3213111
3213112
3213122
3213132
3213142
3213162
3213172
3213212
3213222
3213232
3213242
3213262
3213272
3213292
3214111
3214112
3214122
3214132
3214142
3214162
3214172
3214192
3214212
3214222
3214242
3214262
3214272
3214942
3215911
3215912
3215914
3215922
3215924
3215941
3215942
3215944
3215962
3215972
3219112
3219122
3219212
3219214
3219222
3219242
3219942
3219991
3221111
3221114
3221124
3221211
3221214
3221241
3223114
3223211
3223214
3224141
3224144
3225911
3225914
3225921
3225924
3225941
3225944
3231111
3231211
3231214
3231224
3232114
3233111
3233211
3234111
3234114
3234121
3234124
3234134
3234141
3234144
3234164
3234171
3235911
3235914
3235941
3235944
3239261
3241142
3241231
3241271
3243271
3244161
3244214
3244261
3245914
3245941
3245944
3249124
3305921
3305924
3305931
3305934
3305941
3305944
3305961
3305964
3305971
3305991
330992
330993
330994
330996
330997
330999
3325921
340111
3401111
3401112
3401114
340112
3401121
3401122
340113
3401131
340114
3401141
3401142
340115
340116
3401161
340117
3401171
340119
3401191
340121
3401211
3401212
340122
3401221
3401224
340123
3401231
340124
3401241
3401244
340126
3401261
340127
3401271
340129
340211
3402111
3402112
340212
3402121
3402122
3402124
340213
3402131
3402132
3402134
340214
3402141
3402142
340216
3402161
3402162
340217
3402171
340219
340221
3402211
3402212
340222
3402221
3402222
3402224
340223
340224
3402241
3402242
340226
3402261
340227
3402271
340229
340311
3403111
3403112
340312
3403121
340313
3403131
3403132
340314
3403141
3403142
340316
3403161
340317
3403171
340321
3403211
3403212
340322
3403221
3403222
3403224
340323
3403231
340324
3403241
340326
3403261
340327
3403271
340329
3403291
3403292
340411
3404111
3404112
3404114
340412
3404121
3404122
3404124
340413
3404131
3404132
3404134
340414
3404141
3404142
3404144
340416
3404161
3404162
3404164
340417
3404171
3404174
340419
3404191
340421
3404211
340422
3404221
340423
340424
3404241
340426
340427
340429
340491
3404911
340499
3404991
340911
3409111
340912
3409121
340913
3409131
3409132
340914
3409141
340916
3409161
340917
3409171
340919
3409191
3409194
340921
3409211
340922
3409221
3409222
3409224
340923
3409231
340924
3409241
340926
3409261
340927
3409271
340929
3409291
340991
3409911
340992
3409921
340994
3409941
340999
3409991
3411111
3411112
3411122
3411132
3411141
3411142
3411152
3411162
3411172
3411192
3411211
3411212
3411222
3411232
3411242
3411243
3411261
3411262
3411272
3411292
3412111
3412112
3412121
3412122
3412132
3412142
3412161
3412162
3412171
3412172
3412192
3412211
3412212
3412222
3412232
3412242
3412262
3412272
3412292
3413111
3413112
3413121
3413122
3413131
3413132
3413141
3413142
3413161
3413162
3413172
3413211
3413212
3413221
3413222
3413231
3413232
3413242
3413262
3413271
3413272
3413292
3414111
3414112
3414121
3414122
3414124
3414131
3414132
3414141
3414142
3414161
3414162
3414172
3414191
3414192
3414212
3414222
3414232
3414242
3414262
3414272
3414292
3414992
3415911
3419112
3419122
3419132
3419162
3419172
3419192
3419211
3419212
3419221
3419222
3419242
3419244
3419262
3419292
3419294
3419911
3419942
3421111
3421114
3421211
3421212
3422111
3422114
3422294
3423111
3423144
3424114
3424131
3424144
3424174
3424194
3424244
3429214
3429241
3431111
3431114
3431141
3431211
3431214
3431224
3431241
3431264
3431274
3432111
3432114
3432131
3432134
3432142
3432144
3432211
3433111
3433114
3433144
3433171
3433211
3433214
3433234
3433241
3434111
3434114
3434121
3434124
3434131
3434134
3434141
3434144
3434161
3434162
3434164
3434171
3434174
3434194
3434211
3434914
3439211
3439244
3439291
3439911
3439994
3441111
3441112
3441114
3441214
3442114
3442172
3442262
3443112
3443142
3443222
3444111
3444114
3444121
3444134
3444141
3444142
3444161
3444164
3444172
3444174
350114
350211
3502111
350212
350214
3502141
350216
3502161
350217
350221
3502211
350224
350226
3502262
350311
3503111
350312
350314
3503141
350321
3503211
350324
350411
3504111
350414
350419
3504191
350421
3504211
3505911
3505913
3505921
3505931
3505941
3505961
3505971
3505991
350911
3509111
350991
350992
350993
350994
3509941
350996
350997
350999
3511142
3512122
3512142
3512162
3512172
3512212
3512242
3513112
3513122
3513142
3513212
3513242
3514112
3514142
3515912
3515932
3515941
3515942
3515944
3525994
3545941
3545944
360111
3601111
360112
360113
3601131
360114
3601141
3601143
360116
3601161
360117
360119
360121
3601211
3601213
360122
360123
360124
3601241
3601243
360126
360127
360129
360199
360211
3602111
360212
3602121
360214
3602141
3602142
360216
3602163
360217
3602171
360219
3602191
360221
3602211
3602213
360223
3602231
360224
3602241
360226
360227
360311
3603111
3603112
360312
360313
3603131
360314
3603141
3603143
360316
3603163
360317
360319
360321
3603211
3603214
360322
3603221
360323
3603231
360324
3603241
360326
3603261
360327
360329
3603291
360411
3604111
3604113
360412
360413
3604131
360414
3604141
360416
360417
3604171
360419
360421
3604211
360424
3604241
360426
360499
3604991
3605141
3605911
3605913
3605921
3605931
3605941
3605943
3605961
3605971
3605973
3605991
360911
360914
360916
360917
360919
3609191
360921
3609211
360929
3609291
360991
360992
360993
360994
360996
360997
360999
3609991
3611112
3611142
3611212
3611222
3611242
3611272
3612112
3612113
3612142
3612162
3612172
3612192
3612212
3612242
3613112
3613122
3613142
3613162
3613212
3613242
3614112
3614142
3614162
3615911
3615912
3615941
3615942
3615992
3621124
3625944
3625994
3641121
3641131
3641141
3641161
3641171
3641211
3641221
3641224
3641231
3641241
3641261
3641271
3642111
3642121
3642141
3642142
3642161
3642162
3642171
3642191
3642241
3642242
3642261
3642271
3643111
3643121
3643131
3643141
3643142
3643161
3643164
3643171
3643191
3643221
3643224
3643231
3643241
3643242
3643261
3643271
3644121
3644131
3644141
3644142
3644161
3644162
3644171
3644191
3644211
3644241
3644242
3644261
3644262
3644264
3645114
3645921
3645931
3645941
3645942
3645944
3645961
3645971
3645991
3645992
3645994
3649161
3649171
370111
3701111
370114
370124
370211
3702111
370212
370214
370216
370217
370219
370221
370224
370311
3703111
370312
370313
3703131
370314
3703141
3703142
370316
370317
370321
370322
370324
3703241
3703242
370411
3704111
370414
3705911
3705913
3705921
3705931
3705941
3705943
3705961
3705971
3705974
3705991
370911
3709111
370991
370992
370993
370994
370996
370997
370999
3711112
3711142
3711242
3712112
3712122
3712142
3712162
3712172
3712192
3712212
3712242
3713111
3713112
3713122
3713142
3713162
3713172
3713212
3713222
3713242
3714112
3714142
3715914
3715944
3719942
3721111
3725911
3725914
3725941
3725944
3734111
3735911
3735914
3735931
3735941
3735944
3735971
3745914
380111
3801111
3801114
380112
380113
380114
380117
380121
380122
380123
380124
380127
380211
3802111
380212
380213
3802131
380214
3802141
380216
380217
380219
380221
380222
380223
380224
380226
3802261
380227
380229
380311
3803111
3803112
380312
3803121
380313
3803132
380314
3803141
380316
380317
380321
3803211
3803214
380322
3803222
380323
380324
380326
380327
380329
380341
380411
3804111
3804112
380412
3804121
3804122
380413
380414
380416
3804162
380417
380419
380421
380422
380426
3805294
380911
3809111
380912
380914
3809141
380921
3809211
380922
3809221
380924
3809241
380929
380991
3809911
380994
3809941
380999
3811112
3811122
3811132
3811142
3811172
3811212
3811222
3811232
3811242
3811272
3812111
3812112
3812122
3812132
3812142
3812162
3812172
3812192
3812211
3812212
3812222
3812232
3812242
3812262
3812272
3812292
3813112
3813122
3813132
3813142
3813162
3813172
3813212
3813222
3813232
3813242
3813262
3813272
3813292
3813412
3814112
3814122
3814132
3814142
3814162
3814172
3814192
3814212
3814222
3814262
3815122
390112
390114
390116
390117
390122
390123
390124
3901241
390127
390211
390212
390213
390214
390216
390217
390222
390223
390224
3902241
3902242
390226
390227
390312
390313
390314
3903141
3903142
390316
390317
3903172
390322
390323
390324
3903242
390326
390327
390412
3904121
3904122
390413
390414
3904141
390416
390417
3904171
390422
390423
3904232
390424
390426
390427
390494
390912
3909121
390913
3909131
390914
3909141
390917
3909171
390924
3909241
390926
3909261
390999
3909991
3911122
3911142
3911162
3911172
3911222
3911232
3911242
3911272
3912112
3912122
3912132
3912142
3912162
3912172
3912222
3912232
3912242
3912262
3912272
3913122
3913132
3913142
3913162
3913172
3913222
3913232
3913242
3913262
3913272
3914122
3914132
3914142
3914162
3914172
3914222
3914232
3914242
3914262
3914272
3914942
3919122
3919242
3921272
40059193
4009999
40359423
40359493
41011111
4101119
41011191
41011192
4101129
4101139
41011391
4101149
41011491
4101159
41011591
4101179
41011791
41019111
4101919
41019191
4101929
41019291
4101939
41019391
4101949
41019491
4101969
41019691
4101979
4102119
41021191
4102129
41021291
41021411
41021442
4102149
41021491
4102169
4102179
4102199
4102219
4102249
41022491
4102919
41029191
41029192
4102929
4102939
41029442
4102949
41029491
4102969
41029691
4102979
4103119
41031191
4103129
41031291
41031296
4103139
41031391
41031411
41031441
4103149
41031491
4103169
41031691
4103179
41031791
4103199
41031991
4103219
41032191
4103229
4103249
4103919
41039191
4103929
4103949
41039491
4103969
4103979
4103999
4104119
41041191
4104129
41041291
4104149
41041491
4104169
41041691
4104179
41041791
4104269
4104919
41049191
4104929
41049291
4104949
41049491
4104969
41049772
4104979
4104999
41059112
41059121
41059122
41059191
41059193
41059221
41059222
41059291
41059293
41059411
41059421
41059422
41059442
41059491
41059662
41059691
41059696
41059772
41059921
41059991
4109119
41091191
4109179
4109919
4109929
4109939
41099422
4109949
41099491
4109969
4109979
4109999
41099991
41111112
41111191
41111222
41111331
41111442
41111772
41119111
41119112
41119192
41119222
41119442
41119772
41121112
41121222
41121422
41121442
41121612
41121662
41121772
41121992
41122122
41129112
41129222
41129332
41129422
41129442
41129772
41131112
41131121
41131123
41131212
41131222
41131312
41131332
41131412
41131422
41131423
41131442
41131492
41131612
41131662
41131772
41131791
41132112
41132422
41132441
41132442
41139112
41139191
41139192
41139222
41139442
41139446
41139662
41139772
41139992
41141112
41141222
41141442
41141662
41141772
41142662
41149112
41149122
41149222
41149292
41149422
41149442
41149662
41149772
41149972
41149992
41159112
41159121
41159122
41159123
41159126
41159142
41159192
41159221
41159222
41159262
41159292
41159332
41159421
41159422
41159423
41159426
41159442
41159491
41159492
41159622
41159662
41159663
41159666
41159692
41159772
41159922
41159992
41159993
41191712
41199191
41199222
41199422
41211116
41211126
41211191
41211711
41221116
41221121
41221126
41221191
41221196
41221426
41221496
41221791
41221796
41229496
41231116
41231191
41231196
41231392
41231491
41231496
41231791
41231796
41232191
41232222
41232291
41232491
41239196
41239496
41241491
41241696
41259196
41259291
41259422
41259491
41259496
41311111
41311196
41319196
41329496
41331196
41331496
41332196
41341496
41359121
41359122
41359126
41359191
41359291
41359491
41359496
42011141
4201119
42011191
42011196
4201129
42011291
4201139
42011391
4201149
42011491
4201169
42011691
4201179
42011791
4201219
42012191
42012196
4201229
42012291
4201239
42012391
4201249
42012491
4202119
42021191
42021222
4202129
42021291
42021442
4202149
42021491
4202169
42021691
4202179
4202199
4202219
42022191
4202229
4202269
42029111
4202919
42031112
4203119
42031191
42031196
42031222
4203129
42031291
42031296
4203139
42031391
4203149
42031491
42031662
4203169
42031691
4203179
42031796
4203199
42031991
4203219
4203229
42032291
4203249
4203269
4203929
42039296
42041111
4204119
42041191
42041222
4204129
42041291
4204149
42041491
42041492
42041496
4204169
42041691
4204179
42041791
4204199
42041991
4204229
4204269
42059991
42059993
4209119
42091191
4209129
42091291
4209169
42091691
4209199
4209999
42099993
42111112
42111222
42111332
42111442
42111491
42111772
42112222
42112332
42112442
42121112
42121142
42121222
42121442
42121612
42121662
42121692
42121772
42121992
42122112
42122222
42122662
42131112
42131222
42131332
42131442
42131622
42131662
42131772
42132112
42132222
42132442
42132662
42141112
42141222
42141442
42141662
42142222
42142292
42142662
42231191
42241191
42311196
42311291
42312291
42331196
42331296
42331496
42332291
42341196
42359993
42391996
4301229
4302919
4302949
43029491
4303249
43032491
4303279
4303919
43039191
4303949
4304119
43041191
4304129
4304149
43041491
4304249
43042491
43059191
43059491
4309919
43099191
4309949
4309999
43112222
43129112
43132442
43132772
43139442
43141222
43141492
44059991
44059993
4409999
44159943
44159992
44159993
44259993
44259996
44359993
4503149
4504169
45041691
45059111
45059113
45059191
45059193
45059293
45059421
45059491
45059493
45059773
45059791
45059991
45059993
45059996
4509919
4509929
4509939
4509949
4509969
4509979
4509999
45099991
45131442
45159121
45159122
45159123
45159192
45159221
45159222
45159223
45159332
45159422
45159423
45159426
45159662
45159663
45159772
45159773
45159922
45159923
45159926
45159993
45259122
45259196
45259491
45259493
45259993
45359122
45359126
45359222
45359422
45359423
45359426
45359491
45359492
45359493
45359496
45359993
45359996
45399993
46029191
46029491
46059191
46059291
46059491
46059691
46059791
46059991
46099191
46099291
46099491
4609999
46099991
46159122
46159422
46159423
46159662
46159722
46159772
46159922
46159992
46199122
46199222
46199421
46199422
46199492
46199772
46199922
46199972
46199992
46259491
46299496
46359296
46399296
47021111
47021291
47021691
4709999
47121112
47121442
511---3171
511---4192
511--1-191
511-01-1-1
511-05-151
511-05-152
511-1--111
511-1--141
511-1-4141
511-11-1-2
511-11-131
511-11-141
511-11-142
511-11-3-1
511-13-111
511-13-112
511-13-131
511-13-132
511-13-141
511-15-111
511-15-112
511-15-121
511-15-131
511-15-132
511-15-142
511-16-131
511-16-132
511-17-111
511-17-131
511-19-141
511-19-142
511-2-11-1
511-2-11-2
511-2-1141
511-2-1142
511-2-13-1
511-2-13-2
511-21-141
511-21-142
511-211142
511-23-111
511-23-112
511-23-131
511-23-132
511-23-141
511-25-111
511-25-112
511-25-131
511-25-132
511-29-141
511-29-142
511-3--141
511-3-3141
511-30-141
511-30-142
511-31-1-1
511-31-1-2
511-31-111
511-31-141
511-31-142
511-32-111
511-32-121
511-32-131
511-32-132
511-32-141
511-32-142
511-33-111
511-33-112
511-33-121
511-33-122
511-33-131
511-33-132
511-33-141
511-33-142
511-34-112
511-34-121
511-34-131
511-34-141
511-34-142
511-35-111
511-35-112
511-35-121
511-35-122
511-35-131
511-35-132
511-35-141
511-35-142
511-36-111
511-36-112
511-36-121
511-36-122
511-36-131
511-36-141
511-36-142
511-37-111
511-37-121
511-37-131
511-37-132
511-37-141
511-39-141
511-39-142
511-4--181
511-4-1181
511-41-1-1
511-41-181
511-41-182
511-43-151
511-43-152
511-43-171
511-43-181
511-45-151
511-45-152
511-45-171
511-45-172
511-45-181
511-45-182
511-46-151
511-49-151
511-49-181
511-49-182
511-5--181
511-5-11-1
511-5-11-2
511-5-1181
511-5-1182
511-5-13-1
511-5-13-2
511-51-181
511-51-182
511-53-151
511-53-152
511-53-171
511-55-151
511-55-152
511-55-171
511-57-151
511-59-181
511-59-182
511-6--181
511-6-3171
511-60-181
511-60-182
511-61-171
511-61-181
511-61-182
511-62-151
511-62-152
511-62-161
511-62-171
511-62-181
511-62-182
511-63-151
511-63-152
511-63-161
511-63-162
511-63-171
511-63-172
511-63-181
511-63-182
511-64-151
511-64-152
511-64-161
511-64-162
511-64-171
511-64-172
511-64-182
511-65-151
511-65-152
511-65-161
511-65-162
511-65-171
511-65-172
511-65-181
511-65-182
511-66-151
511-66-152
511-66-161
511-66-162
511-66-171
511-66-172
511-66-181
511-66-182
511-67-151
511-67-171
511-69-181
511-69-182
511-7--1-1
511-7--1-2
511-7--191
511-7--192
511-7--3-1
511-7--3-2
511-8--111
511-8--131
511-8--141
511-8--151
511-8--161
511-8--191
511-8--231
511-90-4-1
511-91-1-1
511-91-1-2
511-91-3-1
511-91-3-2
511-92-3-1
511-92-3-2
511-93-242
511-93-441
511-94-341
511-94-431
511-94-442
511-95-132
511-95-141
511-95-142
511-96-342
512-01-1-1
512-01-1-2
512-01-3-1
512-03-251
512-05-151
512-05-152
512-09-2-1
512-09-2-2
512-2-11-1
512-2-11-2
512-31-1-1
512-33-142
512-4--1-1
512-5-11-1
512-5-11-2
512-5-13-1
512-51-1-1
512-61-3-1
512-7--1-1
512-7--1-2
512-7--3-1
512-8--2-1
512-8--251
512-91-1-1
512-91-3-1
512-91-3-2
512-92-3-1
512-92-3-2
512-93-241
512-95-141
512-95-341
512-96-341
512-96-342
512001-1-1
512005-151
51202-11-2
51205-11-1
51207--1-1
51207--3-1
512091-1-1
512092-241
512096-341
51212-11-2
51217--1-1
51217--3-1
512193-242
51227--1-1
51227--3-1
51235-11-1
51237--1-1
51237--1-2
51237--3-1
512401-1-1
512401-1-2
51247--1-1
512501-1-1
512505-151
51252-11-1
51252-11-2
51257--1-1
512601-1-1
512601-1-2
512605-151
512609-2-1
51262-11-1
51262-11-2
51262-13-2
512631-1-2
512635-112
512639-1-1
512639-2-1
512639-2-2
512649-2-1
512661-1-1
51267--1-1
51267--1-2
51267--2-1
51267--3-1
512691-1-1
512692-3-1
512692-3-2
512696-341
512791-1-1
512801-1-1
512805-151
51287--1-1
51287--1-2
51287--3-1
512891-1-1
512892-3-2
512893-241
512895-142
51297--1-1
51307--1-1
51307--3-1
513091-1-1
513091-1-2
513091-3-1
513091-3-2
513092-3-1
513094-441
513095-141
513096-241
5131--3141
51312-13-2
51314-11-1
513141-3-1
51317--1-1
51317--3-1
51317--3-2
513191-1-1
513191-1-2
513191-3-1
513192-3-1
513192-3-2
513199-1-1
51322-11-1
513231-1-1
513232-3-1
513239-4-1
51325-11-1
51327--1-1
51327--3-1
513291-1-1
513291-1-2
513291-3-1
513292-3-1
513296-341
513301-1-1
513361-1-1
51337--1-1
51337--1-2
51337--3-1
513391-1-1
513391-1-2
513392-3-1
513392-3-2
513392-321
513394-441
513395-341
513396-341
513396-342
51342-11-2
51345-11-1
51347--1-1
51347--3-1
51348--3-1
513490-242
513490-4-1
513491-1-1
513491-1-2
513491-3-1
513492-3-1
513492-3-2
513493-141
513493-241
513493-242
513493-332
513495-141
513495-142
513495-342
513499-1-1
513499-2-1
513501-3-1
51352-11-1
51357--1-1
51357--3-1
513591-1-1
513596-1-1
51367--1-1
51367--3-1
51367--3-2
513692-2-1
513692-3-1
513696-341
513705-151
51377--1-1
51377--3-1
513791-1-1
513792-3-1
513792-3-2
513794-341
513796-341
513796-342
513799-2-1
513801-1-1
51382-11-2
513836-341
51385-11-1
51387--1-1
51387--3-1
51387--4-1
513891-1-1
513891-1-2
513891-3-1
513891-3-2
513892-3-1
513893-241
513893-341
513894-441
513895-141
513895-341
513895-342
513896-341
513899-4-1
513901-1-1
51392-11-1
513935-1-1
51394-11-1
51397--1-1
51397--1-2
51397--3-1
513991-1-1
513991-1-2
513992-3-1
513993-241
513993-242
513995-141
513995-142
513999-1-1
513999-1-2
514001-1-1
514005-151
51407--1-1
51407--1-2
514091-1-1
514092-3-1
514095-141
514095-342
514096-341
514101-1-1
514101-1-2
514105-151
514105-152
514115-231
51412-11-1
51412-13-1
51412-13-2
514131-1-1
514135-142
514136-342
514139-2-1
51415-11-1
51415-13-1
51417--1-1
51417--1-2
51417--3-1
51418--2-1
51418--231
51418--241
51418--251
51418--261
514190-4-1
514190-4-2
514191-1-1
514191-1-2
514191-3-1
514192-3-1
514192-3-2
514193-141
514193-241
514193-342
514194-341
514194-342
514194-441
514195-141
514195-341
514196-3-1
514196-341
514196-342
514199-1-1
514201-1-1
514201-1-2
514201-3-1
514203-251
514204-471
514205-151
514205-152
514215-212
51422-11-1
514231-1-1
514237-291
514239-2-1
514241-1-2
51425-11-1
51427--1-1
51427--1-2
51427--3-1
514290-4-1
514291-1-1
514291-1-2
514291-3-2
514292-3-1
514292-3-2
514293-142
514293-241
514293-242
514293-441
514294-341
514294-441
514294-442
514295-141
514295-142
514296-341
514296-342
5143--41-2
5143-1-1-1
514301-1-1
514305-151
514311-1-2
514311-3-1
51432-11-1
51432-11-2
51432-13-2
514331-1-1
51434-11-1
51435-11-1
51435-13-1
514361-3-1
514369-2-1
51437--1-1
51437--3-1
51438--251
514391-1-1
514391-3-1
514392-3-1
514392-3-2
514393-141
514393-241
514393-441
514394-441
514395-141
514395-341
514396-341
514399-1-1
514399-1-2
51442-11-1
514431-1-1
514435-211
51447--1-1
51447--3-1
514491-1-1
514492-3-1
514495-141
514495-142
514496-341
514496-342
514499-1-1
514501-1-1
51457--1-1
51457--3-1
514591-1-1
514591-3-1
514592-3-1
514592-3-2
514594-341
514595-3-1
514595-341
514599-1-1
51467--1-1
51467--3-1
514691-1-2
514705-1-1
514705-151
514706-151
51477--1-1
51477--3-1
514791-1-1
514791-3-1
514792-3-1
514795-141
514799-4-1
51487--3-1
514894-442
514901-1-1
514932-3-2
51497--1-1
514991-1-1
514991-3-1
514991-3-2
514992-3-1
514994-341
514995-341
515-1-43-1
515-11-1-1
515-11-1-2
515-11-3-1
515-11-3-2
515-13-111
515-13-211
515-13-212
515-13-231
515-13-232
515-13-312
515-13-411
515-13-431
515-13-432
515-15-131
515-15-211
515-15-212
515-15-231
515-15-232
515-15-411
515-15-412
515-15-431
515-15-432
515-19-1-1
515-19-1-2
515-19-2-1
515-19-2-2
515-19-3-1
515-21-1-1
515-21-1-2
515-21-3-1
515-21-3-2
515-23-131
515-23-212
515-23-231
515-23-232
515-23-431
515-25-211
515-25-212
515-25-231
515-25-232
515-25-411
515-25-431
515-29-1-1
515-29-1-2
515-29-2-1
515-29-2-2
515-30-4-1
515-30-4-2
515-31-1-1
515-31-1-2
515-31-3-1
515-31-3-2
515-32-2-1
515-32-231
515-32-241
515-32-242
515-32-3-1
515-32-3-2
515-33-111
515-33-112
515-33-121
515-33-122
515-33-131
515-33-132
515-33-141
515-33-142
515-33-211
515-33-212
515-33-221
515-33-231
515-33-232
515-33-241
515-33-242
515-33-291
515-33-311
515-33-331
515-33-341
515-33-411
515-33-431
515-33-441
515-34-231
515-34-331
515-34-341
515-34-342
515-34-441
515-35-1-1
515-35-1-2
515-35-111
515-35-112
515-35-121
515-35-122
515-35-131
515-35-132
515-35-141
515-35-142
515-35-191
515-35-211
515-35-231
515-35-311
515-35-312
515-35-331
515-35-341
515-35-342
515-36-211
515-36-3-1
515-36-321
515-36-322
515-36-331
515-36-341
515-36-342
515-37-221
515-37-231
515-37-411
515-39-1-1
515-39-1-2
515-39-2-1
515-39-2-2
515-39-4-1
515-39-4-2
515-41-1-1
515-41-1-2
515-41-3-1
515-41-3-2
515-43-251
515-43-451
515-45-151
515-45-152
515-45-171
515-45-251
515-45-252
515-45-271
515-45-451
515-45-452
515-49-1-1
515-49-2-1
515-49-2-2
515-49-4-2
515-49-451
515-51-1-1
515-51-1-2
515-51-3-1
515-55-251
515-55-252
515-59-1-2
515-59-2-1
515-60-4-1
515-61-1-1
515-61-1-2
515-61-3-1
515-61-3-2
515-62-1-1
515-62-261
515-62-271
515-62-3-1
515-62-3-2
515-63-151
515-63-152
515-63-171
515-63-172
515-63-181
515-63-251
515-63-252
515-63-261
515-63-271
515-63-272
515-63-352
515-63-372
515-63-451
515-64-372
515-64-451
515-64-471
515-65-1-1
515-65-151
515-65-152
515-65-161
515-65-162
515-65-171
515-65-172
515-65-181
515-65-191
515-65-192
515-65-251
515-65-351
515-65-352
515-65-371
515-65-372
515-65-381
515-65-451
515-66-371
515-69-1-1
515-69-1-2
515-69-2-1
515-69-2-2
515-69-4-1
515-69-4-2
515-8--3-1
515-92-3-1
515-95-321
516--1-3-1
516-11-1-1
516-11-1-2
516-11-3-1
516-11-3-2
516-13-131
516-13-211
516-13-212
516-13-231
516-13-232
516-13-332
516-13-411
516-13-412
516-15-111
516-15-112
516-15-131
516-15-211
516-15-212
516-15-231
516-15-232
516-15-411
516-15-412
516-15-431
516-17-431
516-19-1-1
516-19-2-1
516-19-2-2
516-19-4-1
516-19-4-2
516-21-1-1
516-21-1-2
516-21-3-1
516-21-3-2
516-23-112
516-23-211
516-23-212
516-23-231
516-23-232
516-23-431
516-23-432
516-25-211
516-25-212
516-25-231
516-25-232
516-25-411
516-25-431
516-29-1-2
516-29-2-1
516-29-2-2
516-29-3-2
516-29-4-1
516-31-1-1
516-31-1-2
516-31-3-1
516-31-3-2
516-32-111
516-32-241
516-32-3-1
516-32-3-2
516-33-111
516-33-112
516-33-121
516-33-122
516-33-131
516-33-141
516-33-142
516-33-211
516-33-212
516-33-221
516-33-231
516-33-232
516-33-241
516-33-242
516-33-311
516-33-312
516-33-391
516-33-411
516-33-432
516-35-1-1
516-35-111
516-35-112
516-35-121
516-35-122
516-35-131
516-35-132
516-35-141
516-35-142
516-35-192
516-35-211
516-35-212
516-35-311
516-35-312
516-35-321
516-35-331
516-35-332
516-35-341
516-36-231
516-36-241
516-39-1-1
516-39-2-1
516-39-2-2
516-39-4-1
516-41-1-1
516-41-1-2
516-41-3-1
516-41-3-2
516-43-151
516-43-251
516-43-252
516-43-271
516-43-451
516-43-452
516-45-251
516-45-252
516-45-271
516-45-451
516-45-452
516-49-2-1
516-49-2-2
516-51-1-1
516-51-1-2
516-51-3-1
516-51-3-2
516-53-251
516-53-252
516-53-271
516-55-251
516-55-252
516-55-271
516-57-251
516-59-2-1
516-61-1-1
516-61-1-2
516-61-3-1
516-61-3-2
516-62-261
516-62-3-1
516-62-3-2
516-63-151
516-63-152
516-63-171
516-63-172
516-63-181
516-63-251
516-63-252
516-63-271
516-63-281
516-63-351
516-63-371
516-63-451
516-63-471
516-65-1-1
516-65-151
516-65-152
516-65-161
516-65-171
516-65-172
516-65-181
516-65-251
516-65-351
516-65-352
516-65-372
516-65-452
516-66-251
516-69-1-1
516-69-2-1
516-69-2-2
516-69-4-1
516-69-4-2
516-7--1-1
516011-1-1
516011-1-2
516011-3-1
516011-3-2
516013-231
516013-232
516015-131
516015-211
516015-231
516015-232
516021-1-1
516025-211
516031-1-1
516031-1-2
516031-3-1
516033-111
516033-212
516033-231
516035-111
516035-131
516035-141
516035-311
516041-1-1
516045-251
516045-252
516045-271
516045-451
516051-1-1
516061-1-1
516061-1-2
516063-251
516065-151
516065-152
516065-171
516065-351
516069-2-1
516111-1-1
516111-1-2
516111-3-1
516111-3-2
516113-231
516113-431
516115-231
516119-2-1
516121-1-1
516129-4-1
516131-1-1
516131-1-2
516131-3-1
516133-211
516135-111
516135-141
516139-2-1
516141-1-1
516143-252
516151-1-1
516161-1-1
516161-1-2
516161-3-1
516165-151
516165-351
516211-1-1
516211-1-2
516211-3-1
516211-3-2
516213-231
516215-211
516215-231
516219-2-1
516221-1-1
516221-1-2
516223-432
516231-1-1
516231-3-1
516232-211
516233-231
516235-111
516235-112
516235-131
516239-2-1
516239-4-2
516241-1-1
516243-251
516245-251
516249-2-1
516251-1-1
516255-251
516261-1-1
516261-1-2
516261-3-1
516263-361
516265-351
516269-2-2
516311-1-1
516311-1-2
516311-3-1
516311-3-2
516313-231
516313-232
516315-211
516315-212
516315-231
516319-2-1
516319-2-2
516321-1-1
516321-3-1
516325-211
516331-1-1
516331-1-2
516331-3-1
516333-112
516335-111
516335-112
516335-131
516335-141
516341-1-1
516341-1-2
516345-251
516361-1-1
516361-1-2
516361-3-1
516363-152
516363-171
516363-251
516365-151
516365-161
516411-1-1
516411-1-2
516413-211
516413-231
516415-131
516415-211
516415-212
516415-231
516415-232
516415-411
516419-2-1
516421-1-1
516421-1-2
516425-211
516429-2-1
516431-1-1
516433-111
516433-211
516433-212
516433-231
516435-111
516435-112
516435-131
516435-132
516435-141
516435-142
516439-2-1
516441-1-1
516441-1-2
516443-251
516445-251
516445-271
516449-2-1
516451-1-1
516455-251
516461-1-1
516461-1-2
516461-3-1
516463-151
516463-251
516463-252
516465-151
516465-171
516469-2-1
516511-1-1
516513-211
516513-231
516513-232
516515-131
516515-211
516515-212
516515-231
516515-232
516519-2-1
516519-2-2
516521-1-1
516521-1-2
516523-231
516525-211
516525-231
516525-232
516525-412
516531-1-1
516531-1-2
516533-111
516533-112
516533-131
516533-141
516533-211
516533-231
516535-111
516535-112
516535-121
516535-131
516535-132
516535-141
516535-142
516535-311
516539-2-1
516541-1-1
516545-251
516561-1-1
516561-1-2
516563-251
516563-271
516565-151
516565-171
5166-1-3-1
51661--611
516611-1-1
516611-1-2
516611-3-1
516611-3-2
516613-112
516613-131
516613-211
516613-212
516613-231
516613-232
516613-411
516615-111
516615-131
516615-132
516615-211
516615-212
516615-231
516615-232
516615-411
516615-431
516619-2-1
516619-2-2
516619-4-1
516621-1-1
516621-1-2
516621-3-1
516623-211
516625-211
516625-212
516625-231
516625-232
516629-1-1
516629-2-1
516629-4-2
516631-1-1
516631-1-2
516631-3-1
516633-111
516633-112
516633-131
516633-141
516633-142
516633-211
516633-212
516633-231
516633-241
516633-411
516635-1-1
516635-111
516635-112
516635-121
516635-131
516635-132
516635-141
516635-311
516635-341
516636-231
516639-2-1
516639-2-2
516639-4-1
516641-1-1
516641-1-2
516641-3-1
516643-251
516643-252
516643-271
516645-151
516645-2-1
516645-251
516645-252
516645-271
516645-451
516649-1-1
516649-2-1
516649-2-2
516651-1-1
516651-1-2
516651-3-1
516653-251
516655-251
516659-2-1
516661-1-1
516661-1-2
516661-3-1
516661-3-2
516662-3-1
516663-151
516663-171
516663-251
516663-261
516663-271
516663-272
516663-371
516663-451
516665-151
516665-152
516665-171
516665-351
516665-352
516665-371
516666-252
516669-2-1
516669-2-2
516669-4-1
51667--1-1
516711-1-1
516711-1-2
516711-3-1
516715-211
516715-231
516731-1-1
516731-1-2
516733-241
516745-251
516761-1-1
516761-3-2
516765-171
516811-1-1
516811-1-2
516811-3-1
516811-3-2
516813-211
516813-231
516813-232
516815-111
516815-132
516815-211
516815-231
516815-232
516815-431
516817-411
516819-2-1
516819-2-2
516819-4-2
516821-1-1
516821-1-2
516821-3-1
516825-231
516829-2-1
516831-1-1
516831-1-2
516831-3-1
516833-232
516833-331
516833-431
516835-111
516835-131
516835-141
516835-311
516835-331
516839-2-1
516841-1-1
516841-3-2
516843-452
516845-251
516845-271
516851-1-1
516861-1-1
516861-1-2
516861-3-1
516862-3-1
516863-171
516865-151
516869-2-1
516869-4-1
516911-1-1
516915-231
516935-111
517011-1-1
517011-3-2
517013-231
517015-211
517015-231
517015-232
517021-1-1
517021-3-1
517031-1-1
517031-3-1
517032-3-1
517033-131
517035-111
517035-131
517035-141
517035-142
517035-331
517035-341
517039-1-2
517039-2-1
517041-1-1
517041-3-1
517043-251
517045-251
517045-451
51705--1-1
517061-1-1
517061-1-2
517061-3-1
517063-351
517065-151
517065-171
517065-271
517065-351
517111-1-1
517111-1-2
517111-3-1
517111-3-2
517113-231
517115-131
517115-211
517115-231
517115-232
517115-332
517115-411
517115-431
517121-1-1
517123-232
517123-431
517125-211
517125-212
517131-1-1
517131-1-2
517131-3-1
517131-3-2
517132-3-1
517133-112
517133-211
517133-231
517133-241
517135-1-1
517135-111
517135-131
517135-132
517135-141
517135-142
517135-311
517135-312
517135-331
517139-1-1
517139-1-2
517141-1-1
517141-3-1
517143-451
517145-251
517145-451
517161-1-1
517161-1-2
517161-3-1
517161-3-2
517162-3-1
517163-151
517163-171
517163-251
517163-351
517163-451
517163-471
517165-151
517165-171
517165-181
517165-351
517165-371
517166-382
517169-1-1
517169-2-1
51717--3-1
517211-1-1
517211-1-2
517211-3-1
517211-3-2
517213-211
517213-212
517213-312
517213-411
517213-412
517215-211
517215-212
517215-231
517215-232
517215-311
517215-411
517219-1-1
517219-2-1
517219-2-2
517219-4-1
517221-1-1
517221-3-1
517225-211
517225-212
517225-231
517229-1-1
517231-1-1
517231-1-2
517231-3-1
517231-3-2
517232-3-1
517233-111
517233-131
517233-141
517233-142
517233-211
517233-231
517233-232
517233-241
517233-311
517233-331
517234-412
517234-441
517235-111
517235-112
517235-121
517235-131
517235-132
517235-141
517235-142
517235-312
517235-331
517239-1-1
517239-2-1
517241-1-1
517241-1-2
517241-3-1
517245-251
517245-271
517245-451
517261-1-1
517261-1-2
517261-3-1
517261-3-2
517262-251
517262-271
517262-281
517263-152
517263-252
517264-171
517265-151
517265-171
517265-172
517265-271
517265-351
517269-1-1
517269-2-2
517269-4-1
51727--1-1
51727--3-1
517311-1-1
517311-1-2
517311-3-1
517311-3-2
517313-211
517313-212
517313-231
517313-232
517313-411
517313-431
517315-111
517315-211
517315-231
517319-1-1
517319-2-1
517319-2-2
517321-1-1
517325-211
517325-231
517331-1-1
517331-1-2
517331-111
517331-3-1
517332-3-1
517333-211
517333-232
517333-241
517335-111
517335-112
517335-131
517335-141
517335-142
517335-331
517339-1-1
517339-2-1
517341-1-1
517341-1-2
517341-3-1
517341-3-2
517343-451
517345-251
517345-252
517345-451
517345-452
517349-2-1
517349-4-1
517349-4-2
517351-1-1
517355-251
517361-1-1
517361-1-2
517361-3-1
517363-151
517363-161
517363-171
517363-172
517365-151
517365-152
517365-161
517365-181
517365-351
517365-372
517369-1-1
517369-2-1
517369-2-2
51737--3-1
517411-1-1
517411-1-2
517411-3-1
517411-3-2
517413-411
517413-412
517415-211
517415-231
517415-232
517419-4-1
517421-1-1
517421-3-1
517423-231
517425-211
51743--1-1
517431-1-1
517431-1-2
517431-3-1
517431-3-2
517432-3-1
517432-3-2
517433-141
517433-142
517433-211
517433-221
517433-231
517433-241
517433-242
517433-331
517433-431
517433-441
517435-1-2
517435-111
517435-112
517435-121
517435-131
517435-132
517435-141
517435-142
517435-311
517435-321
517435-322
517435-331
517435-341
517435-342
517436-141
517436-3-1
517436-331
517436-341
517439-1-1
517439-2-1
517439-2-2
517439-4-1
517439-4-2
517441-1-1
517441-3-1
517445-151
517445-272
517445-352
517449-2-1
517451-1-2
517461-1-1
517461-1-2
517461-3-1
517461-3-2
517462-3-1
517462-3-2
517463-151
517463-171
517463-261
517463-271
517463-351
517463-352
517463-371
517463-471
517464-271
517464-362
517464-371
517465-151
517465-161
517465-162
517465-171
517465-172
517465-351
517465-361
517465-362
517465-371
517465-372
517466-361
517469-2-1
517511-1-1
517511-3-1
517511-3-2
517513-411
517515-211
517515-231
517515-431
517523-411
517531-1-1
517531-3-1
517533-131
517535-121
517535-312
517545-251
517545-452
517561-1-1
517561-1-2
517561-3-1
517561-3-2
517563-252
517565-152
517611-1-1
517611-1-2
517611-3-1
517611-3-2
517613-211
517613-212
517615-211
517615-231
517621-1-1
517621-3-1
517629-2-1
517631-1-1
517631-1-2
517631-3-1
517631-3-2
517632-231
517633-211
517633-411
517635-111
517635-131
517635-141
517635-311
517639-1-1
517639-2-1
517639-2-2
517641-1-1
517641-3-1
517645-251
517645-451
517649-1-1
517661-1-1
517661-3-1
517661-3-2
517662-271
517663-151
517665-151
517665-351
517665-352
517669-2-1
51767--1-1
517711-1-1
517711-1-2
517715-211
517715-231
517715-232
517715-411
517719-1-1
517719-2-1
517721-1-1
517725-231
517731-1-1
517731-1-2
517731-3-1
517731-3-2
517732-3-1
517733-111
517735-111
517735-112
517735-131
517735-141
517735-331
517737-211
517739-2-1
517741-1-1
517741-3-1
517743-251
517745-2-1
517745-251
517745-252
517745-451
517761-1-1
517761-1-2
517761-3-1
517763-151
517765-151
517811-1-1
517811-1-2
517811-3-1
517811-3-2
517815-211
517815-231
517815-431
517821-1-1
517823-231
517825-231
517829-2-2
517831-1-1
517831-1-2
517831-3-1
517831-3-2
517832-3-1
517833-131
517833-142
517833-231
517833-241
517833-311
517833-341
517833-431
517835-1-2
517835-112
517835-131
517835-141
517835-142
517835-231
517835-311
517835-312
517835-321
517835-322
517835-331
517835-341
517836-341
517839-1-1
517839-2-1
517839-2-2
517839-4-2
517841-1-1
517845-251
517845-252
517845-451
517861-1-1
517861-1-2
517861-3-1
517861-3-2
517862-271
517863-151
517863-171
517863-351
517863-371
517863-471
517865-151
517865-161
517865-162
517865-171
517865-172
517865-351
517865-371
517865-372
517869-2-1
517869-2-2
517911-1-1
517911-1-2
517911-3-1
517911-3-2
517913-211
517913-212
517913-231
517913-232
517915-131
517915-211
517915-231
517915-232
517919-1-1
517919-1-2
517921-1-1
517921-1-2
517923-212
517923-232
517925-211
517925-231
517925-232
517929-1-1
517931-1-1
517931-1-2
517931-3-1
517932-3-1
517933-111
517933-112
517933-121
517933-131
517933-132
517933-141
517933-142
517933-211
517933-212
517933-221
517933-222
517933-231
517933-232
517933-241
517933-242
517933-411
517935-111
517935-112
517935-121
517935-122
517935-131
517935-132
517935-141
517935-142
517935-191
517935-311
517935-312
517935-321
517935-341
517937-231
517939-1-1
517939-1-2
517939-4-1
517941-1-1
517941-1-2
517941-3-1
517943-251
517943-271
517945-251
517945-252
517945-271
517945-451
517949-1-1
517951-1-1
517955-251
517955-271
517959-1-1
517961-1-1
517961-1-2
517961-3-1
517962-3-1
517963-151
517963-152
517963-161
517963-171
517963-191
517963-251
517963-252
517963-261
517963-262
517963-271
517963-272
517963-282
517965-151
517965-152
517965-161
517965-162
517965-171
517965-172
517965-181
517965-191
517965-251
517965-271
517965-371
517966-361
517969-1-1
517969-1-2
518011-1-1
518011-1-2
518011-3-1
518013-211
518015-211
518015-231
518015-411
518015-431
518019-2-1
518019-4-1
518021-1-1
518023-231
518025-211
518025-231
518029-2-1
518031-1-1
518031-1-2
518031-3-1
518031-3-2
518032-3-1
518035-111
518035-131
518035-141
518035-3-1
518035-311
518039-2-1
518041-1-1
518041-3-1
518043-251
518045-251
518045-271
518045-471
518051-1-1
518061-1-1
518061-3-1
518065-151
518065-171
518065-351
518069-2-1
51807--1-1
518111-1-1
518111-1-2
518111-3-1
518111-3-2
518111-431
518113-2-1
518113-211
518113-212
518113-231
518113-232
518113-411
518115-111
518115-121
518115-131
518115-2-2
518115-211
518115-212
518115-231
518115-232
518115-411
518115-431
518115-432
518116-231
518119-1-1
518119-1-2
518119-2-1
518119-2-2
518119-4-1
518121-1-1
518121-1-2
518121-3-1
518123-211
518123-231
518123-411
518123-431
518125-211
518125-231
518125-232
518125-411
518125-412
518125-431
518129-1-1
518129-1-2
518129-2-1
518130-4-1
518131-1-1
518131-1-2
518131-111
518131-3-1
518131-3-2
518132-2-1
518132-211
518132-231
518132-232
518132-241
518132-3-1
518132-3-2
518133-111
518133-112
518133-121
518133-131
518133-141
518133-142
518133-211
518133-212
518133-221
518133-222
518133-231
518133-232
518133-241
518133-242
518133-311
518133-312
518133-411
518133-431
518133-441
518134-331
518134-441
518135-1-1
518135-111
518135-112
518135-121
518135-122
518135-131
518135-132
518135-141
518135-142
518135-191
518135-311
518135-312
518135-321
518135-331
518135-341
518136-212
518136-231
518136-241
518136-311
518136-321
518136-341
518137-232
518139-1-1
518139-1-2
518139-2-1
518139-2-2
518139-3-1
518139-4-1
51814--591
518141-1-1
518141-1-2
518141-3-1
518143-152
518143-251
518143-252
518143-451
518145-1-2
518145-2-1
518145-251
518145-252
518145-271
518145-272
518145-451
518145-452
518149-1-1
518149-1-2
518149-2-1
518149-2-2
518149-4-1
518151-1-1
518151-1-2
518151-3-1
518153-251
518153-252
518155-251
518155-252
518155-451
518159-1-1
518159-2-1
51816--1-1
518160-4-2
518161-1-1
518161-1-2
518161-3-1
518161-3-2
518161-371
518162-1-1
518162-251
518162-271
518162-3-1
518162-3-2
518163-1-1
518163-151
518163-152
518163-161
518163-162
518163-171
518163-251
518163-252
518163-261
518163-271
518163-281
518163-351
518163-352
518163-361
518163-372
518163-381
518163-451
518164-361
518164-472
518165-151
518165-152
518165-161
518165-171
518165-172
518165-181
518165-182
518165-271
518165-351
518165-352
518165-361
518165-371
518166-251
518166-261
518166-272
518166-361
518166-362
518166-371
518169-1-1
518169-1-2
518169-2-1
518169-2-2
518169-3-1
518169-4-1
51817--1-1
51817--3-1
51818--211
518192-3-1
518211-1-1
518211-1-2
518211-3-1
518211-3-2
518213-1-1
518213-132
518213-211
518213-212
518213-231
518213-232
518213-432
518215-111
518215-131
518215-211
518215-212
518215-231
518215-232
518215-411
518215-431
518219-1-1
518219-2-1
518219-2-2
518221-1-1
518221-1-2
518221-3-1
51822111-2
518223-2-1
518223-211
518223-212
518223-231
518223-232
518223-431
518225-211
518225-212
518225-231
518225-232
518229-2-1
518229-2-2
518230-2-1
518230-4-1
518231-1-1
518231-1-2
518231-3-1
518231-3-2
518232-3-1
518232-3-2
518233-111
518233-112
518233-121
518233-131
518233-132
518233-141
518233-211
518233-212
518233-221
518233-222
518233-231
518233-232
518233-241
518233-242
518233-311
518233-411
518233-431
518233-441
518234-321
518234-341
518234-412
518234-421
518234-431
518234-441
518234-442
518235-111
518235-112
518235-121
518235-131
518235-132
518235-141
518235-142
518235-311
518235-331
518236-341
518237-241
518239-1-1
518239-1-2
518239-2-1
518239-2-2
518239-4-1
518241-1-1
518241-1-2
518241-3-1
518243-251
518243-252
518243-271
518243-3-1
518245-151
518245-251
518245-252
518245-271
518245-451
518249-1-1
518249-2-1
518251-1-1
518251-1-2
518253-151
518253-251
518253-351
518255-252
51826--1-1
518261-1-1
518261-1-2
518261-3-1
518261-3-2
518262-3-1
518262-3-2
518263-151
518263-152
518263-171
518263-172
518263-182
518263-251
518263-252
518263-261
518263-262
518263-271
518263-272
518263-281
518263-351
518263-371
518264-271
518264-451
518264-452
518264-461
518264-471
518264-472
518264-492
518265-151
518265-152
518265-162
518265-171
518265-172
518265-272
518265-371
518266-361
518267-251
518267-271
518269-2-1
518269-2-2
51827--1-1
518291-3-1
518292-3-1
51831--3-1
518311-1-1
518311-1-2
518311-3-1
518311-3-2
518313-211
518313-231
518313-232
518313-411
518313-431
518315-111
518315-131
518315-132
518315-211
518315-212
518315-231
518315-232
518315-411
518315-431
518319-2-1
518319-4-1
518319-4-2
518321-1-1
518321-1-2
518321-3-1
518321-3-2
518325-211
518325-212
518325-231
518329-2-1
518331-1-1
518331-1-2
518331-3-1
518331-3-2
518332-241
518332-3-1
518332-3-2
518333-111
518333-131
518333-141
518333-211
518333-212
518333-231
518333-232
518333-242
518333-311
518333-412
518335-111
518335-112
518335-121
518335-131
518335-132
518335-141
518335-142
518335-211
518335-311
518335-331
518336-341
518339-1-1
518339-1-2
518339-2-1
518339-4-1
518341-1-1
518341-1-2
518341-3-1
518343-251
518343-252
518345-251
518345-252
518345-451
518345-452
518345-471
518349-2-1
518351-1-1
518351-1-2
518351-3-1
518355-251
518361-1-1
518361-1-2
518361-3-1
518361-3-2
518362-252
518362-3-1
518363-151
518363-152
518363-171
518363-251
518363-351
518365-1-1
518365-151
518365-152
518365-171
518365-172
518365-251
518365-351
518365-371
518366-281
518369-2-1
51837--1-1
518411-1-1
518411-1-2
518411-3-1
518413-211
518413-231
518413-232
518415-131
518415-211
518415-231
518415-232
518416-232
518419-1-1
518419-1-2
518419-4-1
518421-1-1
518421-1-2
518421-3-1
518423-211
518423-231
518425-211
518425-232
518429-1-1
51843--1-1
518431-1-1
518431-1-2
518431-3-1
518431-3-2
518432-241
518432-3-1
518433-111
518433-112
518433-131
518433-141
518433-211
518433-231
518433-311
518433-342
518433-411
518435-111
518435-112
518435-121
518435-122
518435-131
518435-132
518435-141
518435-331
518436-231
518436-341
518439-1-1
518439-2-1
518439-2-2
518439-3-2
518439-4-1
518441-1-1
518441-1-2
518441-3-1
518443-251
518445-251
518445-252
518445-271
518445-451
518449-1-1
518449-1-2
518451-1-1
518461-1-1
518461-1-2
518461-3-1
518461-3-2
518462-252
518462-271
518462-3-1
518463-151
518463-251
518463-271
518463-272
518463-351
518463-451
518464-251
518465-151
518465-152
518465-171
518465-271
518465-351
518465-361
518466-151
518469-1-1
518469-1-2
518469-2-2
518469-4-1
518511-1-1
518511-1-2
518511-3-1
518513-231
518515-131
518515-211
518515-231
518519-1-1
518521-1-1
518525-232
518531-1-1
518531-3-1
518532-3-1
518533-131
518533-211
518533-241
518533-331
518535-111
518535-121
518535-131
518535-132
518535-141
518535-142
518535-311
518535-331
518539-1-1
518539-2-1
518539-4-1
518541-1-1
518543-251
518545-251
518559-2-1
518561-1-1
518561-3-1
518562-271
518563-351
518563-371
518565-151
518565-152
518565-251
518565-351
518565-371
518566-271
518566-371
518611-1-1
518613-211
518613-231
518619-4-1
518631-1-1
518635-111
518635-112
518635-131
518639-2-2
518643-271
518645-251
518661-1-1
518663-271
518663-371
518665-251
518665-351
518711-1-1
518711-1-2
518711-3-1
518711-3-2
518715-211
518715-231
518719-2-1
518721-1-1
518731-1-1
518731-1-2
518731-3-1
518732-3-1
518733-211
518735-111
518735-131
518735-141
518736-311
518736-341
518741-1-1
518745-251
518745-451
518749-4-1
518761-1-1
518761-1-2
518761-3-1
518763-251
518765-151
518765-351
518811-1-2
518813-231
518815-231
518815-232
518819-4-1
518831-1-1
518831-3-1
518833-211
518833-242
518835-111
518835-131
518835-132
518861-1-1
518861-1-2
518869-2-1
518911-1-1
518911-1-2
518911-3-1
518915-131
518915-211
518915-231
518915-411
518921-1-1
518929-2-1
518931-1-1
518931-3-1
518933-242
518934-341
518935-111
518935-121
518935-131
518935-311
518935-331
518941-1-1
518945-251
518946-251
518949-2-1
518961-1-1
518961-1-2
518961-3-1
518963-251
518965-151
518965-171
518965-351
518969-2-1
521----191
521----891
521---3141
521-03-251
521-09-1-2
521-09-3-2
521-1--141
521-1--142
521-11-111
521-12-111
521-13-111
521-13-112
521-13-131
521-13-132
521-13-142
521-15-111
521-15-112
521-15-131
521-15-132
521-15-141
521-16-131
521-17-131
521-19-141
521-19-142
521-2--141
521-2-11-1
521-2-1141
521-2-1142
521-2-13-1
521-23-111
521-23-131
521-23-132
521-25-111
521-25-112
521-25-131
521-25-132
521-27-111
521-29-141
521-29-142
521-3--111
521-3--141
521-3-3111
521-3-3141
521-30-141
521-30-142
521-31-141
521-32-111
521-32-121
521-32-131
521-32-141
521-32-142
521-33-111
521-33-112
521-33-121
521-33-131
521-33-132
521-33-141
521-33-142
521-34-111
521-34-121
521-34-131
521-34-141
521-35-111
521-35-112
521-35-121
521-35-122
521-35-131
521-35-132
521-35-141
521-35-142
521-36-111
521-36-121
521-36-131
521-36-132
521-36-141
521-36-142
521-37-111
521-37-112
521-37-141
521-37-142
521-39-111
521-39-141
521-39-142
521-4--181
521-4-1181
521-41-181
521-41-182
521-42-171
521-43-151
521-43-152
521-43-171
521-45-151
521-45-152
521-45-171
521-45-181
521-46-151
521-47-151
521-49-181
521-49-182
521-5--181
521-5-11-1
521-5-1181
521-5-13-1
521-51-182
521-53-151
521-53-171
521-55-151
521-55-152
521-59-181
521-59-182
521-6--151
521-6--181
521-6-3152
521-60-171
521-60-181
521-60-182
521-61-152
521-61-181
521-62-151
521-62-152
521-62-161
521-62-171
521-62-172
521-63-151
521-63-152
521-63-161
521-63-171
521-63-172
521-63-181
521-64-151
521-64-161
521-64-171
521-64-181
521-65-151
521-65-152
521-65-161
521-65-171
521-65-172
521-65-181
521-65-182
521-66-151
521-66-152
521-66-161
521-66-171
521-66-172
521-66-181
521-67-151
521-69-1-1
521-69-151
521-69-181
521-69-182
521-7--1-1
521-7--1-2
521-7--191
521-7--192
521-7--3-1
521-7--3-2
521-8--121
521-8--131
521-8--141
521-8--171
521-8--191
521-8--2-1
521-8--231
521-8--241
521-9-3141
521-90-3-1
521-92-241
521-93-341
521-95-141
521-95-142
521-95-341
521-95-342
521-96-241
521-96-341
521-99-3-1
522-0--691
522-05-151
522-05-152
522-09-1-1
522-15-211
522-2-11-1
522-2-11-2
522-2-13-1
522-4-11-1
522-5--3-1
522-5-11-1
522-5-13-1
522-7--1-1
522-7--1-2
522-7--3-1
522-90-3-1
522-90-3-2
522-92-3-1
522-93-211
522-95-141
522-95-142
522003-151
522003-252
522005-151
522009-1-1
522009-1-2
52205-11-1
522063-251
52207--1-1
52207--3-1
522105-151
52215-11-1
52217--1-1
52217--3-1
52222-11-1
52224-11-1
52227--1-1
52227--3-1
522309-1-1
52237--1-1
52242-11-1
52247--1-1
52247--3-1
522505-151
522505-152
522509-1-1
52252-11-1
52255-11-1
52257--1-1
52257--1-2
52257--3-1
522590-3-1
522603-251
522605-151
522615-211
52262-11-1
52265-11-1
52265-13-1
52267--1-1
52267--3-1
522690-3-1
522694-341
522695-141
522695-142
52275-11-1
52277--1-1
52277--3-1
522799-1-2
522809-1-1
52282-13-1
52287--1-1
52287--3-1
522890-3-1
522893-242
522895-141
522899-1-2
523005-151
523009-1-1
52307--1-1
52307--3-1
523090-3-1
523092-241
5231--3141
52312-13-1
52317--1-1
52317--3-1
52317--3-2
523190-3-1
523194-341
523196-341
523199-1-1
523199-3-1
523205-151
52322-13-1
52327--1-1
52327--3-1
52328--231
523290-1-1
523290-3-1
523294-341
523363-352
52337--1-1
52337--3-1
523390-3-2
523393-241
523395-341
523403-151
52342-11-1
52342-13-1
52345-11-1
52347--1-1
52347--3-1
52348--231
523490-3-1
523494-341
523495-141
523495-341
523496-241
523499-1-1
52352-13-1
52357--1-1
52357--3-1
523590-3-2
523595-141
52367--1-1
52367--3-1
52377--1-1
52377--3-1
523803-151
52382-11-1
52387--1-1
52387--3-1
523890-3-1
523892-241
523895-142
523895-341
523896-241
523896-341
523899-1-1
523899-3-1
52390--591
52397--1-1
52397--3-1
523990-3-1
52407--1-1
52407--3-1
52407--3-2
524090-3-1
524096-241
524096-341
524099-3-1
5241--3141
52410--591
524105-151
524109-1-1
52412-11-1
52412-13-1
524135-141
524135-341
524139-1-1
524139-3-2
52415-11-1
524162-251
52417--1-1
52417--2-1
52417--3-1
52418--231
52418--241
52418--271
52418--3-1
524190-3-1
524192-241
524194-441
524195-142
524196-341
524199-1-1
524199-1-2
524199-3-1
52422-11-1
524235-141
524236-341
524245-451
52425-11-1
52427--1-1
52427--3-1
524290-3-1
524294-441
524295-141
524295-142
524295-341
524296-341
524299-3-1
524305-151
52432-11-1
52432-11-2
52432-13-1
52435-11-1
52437--1-1
52437--3-1
524390-3-1
524392-241
524393-341
524394-241
524394-341
524395-142
524395-341
524395-342
524396-341
524399-1-1
524399-3-1
52447--1-1
52447--3-1
52448--221
524490-3-1
524495-341
524496-341
524499-3-2
52457--1-1
52457--3-1
52472-11-1
52472-13-1
52477--1-1
52477--3-1
524796-341
524799-3-1
52487--1-1
52487--3-1
524893-341
524895-341
524895-342
524899-3-1
52492-11-1
524936-241
52497--1-1
52497--3-1
524990-3-1
524995-141
524996-241
525-13-211
525-13-231
525-13-232
525-13-411
525-13-431
525-15-112
525-15-132
525-15-211
525-15-231
525-15-232
525-15-411
525-15-412
525-15-431
525-16-231
525-19-1-1
525-19-3-1
525-19-3-2
525-2--591
525-2-11-1
525-2-13-1
525-23-431
525-23-432
525-25-231
525-25-331
525-25-411
525-25-412
525-25-431
525-29-1-1
525-29-1-2
525-29-3-1
525-3--111
525-3--591
525-30-1-2
525-30-3-1
525-30-3-2
525-32-1-2
525-32-211
525-32-231
525-32-541
525-33-111
525-33-112
525-33-121
525-33-131
525-33-132
525-33-141
525-33-142
525-33-211
525-33-231
525-33-241
525-33-311
525-33-331
525-33-332
525-33-341
525-33-411
525-33-412
525-33-421
525-33-431
525-33-441
525-34-331
525-34-341
525-34-411
525-34-431
525-34-441
525-35-1-1
525-35-111
525-35-112
525-35-121
525-35-131
525-35-132
525-35-141
525-35-142
525-35-191
525-35-231
525-35-3-1
525-35-311
525-35-312
525-35-321
525-35-322
525-35-331
525-35-332
525-35-341
525-35-342
525-36-131
525-36-231
525-36-232
525-36-311
525-36-321
525-36-331
525-36-341
525-37-442
525-39-1-1
525-39-1-2
525-39-3-1
525-39-3-2
525-4--5-1
525-4--591
525-43-451
525-43-471
525-45-151
525-45-251
525-45-451
525-45-452
525-45-471
525-46-251
525-49-1-1
525-49-1-2
525-49-3-1
525-49-3-2
525-55-251
525-55-451
525-59-1-1
525-59-3-1
525-6--151
525-60-1-1
525-60-3-1
525-60-3-2
525-61-3-1
525-62-251
525-62-252
525-62-261
525-62-271
525-62-272
525-63-151
525-63-271
525-63-351
525-63-352
525-63-371
525-63-451
525-63-471
525-64-371
525-64-381
525-65-151
525-65-152
525-65-161
525-65-171
525-65-172
525-65-181
525-65-3-1
525-65-351
525-65-352
525-65-361
525-65-371
525-65-372
525-65-381
525-66-251
525-66-252
525-66-371
525-66-381
525-66-391
525-69-1-1
525-69-1-2
525-69-3-1
525-69-3-2
525-8--231
525-94-341
526---3141
526-1--991
526-13-111
526-13-211
526-13-231
526-13-232
526-13-311
526-13-411
526-13-431
526-15-111
526-15-131
526-15-132
526-15-2-1
526-15-211
526-15-212
526-15-231
526-15-232
526-15-311
526-15-331
526-15-411
526-15-412
526-15-431
526-15-432
526-19-1-1
526-19-1-2
526-19-3-1
526-19-3-2
526-23-111
526-23-231
526-23-232
526-23-411
526-23-431
526-25-211
526-25-212
526-25-231
526-25-232
526-25-311
526-25-411
526-25-431
526-29-1-1
526-29-1-2
526-29-2-1
526-29-3-1
526-29-3-2
526-3-3111
526-31-1-1
526-32-241
526-33-111
526-33-112
526-33-131
526-33-132
526-33-141
526-33-142
526-33-211
526-33-212
526-33-231
526-33-232
526-33-241
526-33-242
526-33-311
526-33-321
526-33-341
526-33-391
526-33-411
526-33-431
526-33-441
526-34-431
526-35-1-1
526-35-111
526-35-112
526-35-121
526-35-131
526-35-132
526-35-141
526-35-142
526-35-311
526-35-312
526-35-321
526-35-331
526-36-331
526-36-341
526-39-1-1
526-39-1-2
526-39-111
526-39-2-1
526-39-3-1
526-39-3-2
526-4--591
526-41-1-1
526-43-251
526-43-252
526-43-451
526-43-452
526-45-251
526-45-252
526-45-271
526-45-351
526-45-451
526-45-471
526-49-1-1
526-49-1-2
526-49-3-1
526-51-192
526-55-251
526-59-1-1
526-59-1-2
526-59-3-1
526-61-1-1
526-61-152
526-61-3-1
526-62-252
526-63-151
526-63-152
526-63-171
526-63-172
526-63-251
526-63-271
526-63-272
526-63-351
526-63-352
526-63-471
526-63-472
526-63-481
526-65-1-1
526-65-1-2
526-65-151
526-65-152
526-65-161
526-65-171
526-65-172
526-65-251
526-65-3-1
526-65-351
526-65-352
526-65-371
526-65-372
526-65-451
526-66-272
526-69-1-1
526-69-1-2
526-69-151
526-69-3-1
526-69-3-2
526-7--1-1
526-7--3-1
526013-211
526013-212
526013-231
526013-411
526015-131
526015-211
526015-212
526015-231
526015-411
526019-1-1
526029-1-1
526029-3-1
526031-1-1
526033-112
526033-211
526033-231
526035-111
526035-112
526035-131
526035-141
526035-311
526039-1-1
526039-1-2
526039-3-1
526041-3-1
526045-251
526049-1-1
526055-251
526059-1-1
526059-1-2
526063-151
526063-171
526065-151
526065-152
526069-1-1
526069-1-2
526069-3-1
52607--1-1
526113-111
526113-231
526113-431
526115-211
526115-231
526115-411
526115-432
526117-231
526119-1-1
526123-231
526125-211
526125-431
526129-1-1
526133-111
526133-121
526133-211
526135-111
526135-131
526135-132
526135-311
526135-331
526139-1-1
526139-1-2
526139-3-1
526139-3-2
526143-251
526145-251
526149-1-1
526159-1-1
526165-151
526165-171
526169-1-1
526169-1-2
526169-3-1
52617--1-1
526213-211
526213-231
526215-211
526215-231
526215-411
526219-1-1
526229-1-1
526229-1-2
526233-131
526233-311
526235-111
526235-112
526235-131
526239-1-1
526239-3-1
526245-251
526245-451
526249-1-1
526249-1-2
526263-251
526265-151
526269-1-1
526269-3-2
526313-231
526315-211
526315-231
526319-1-1
526319-1-2
526319-3-1
526323-232
526331-1-1
526335-1-1
526335-131
526339-1-1
526345-251
526363-271
526365-371
526369-1-1
526369-1-2
526413-211
526413-231
526415-131
526415-211
526415-212
526415-231
526419-1-1
526423-231
526425-231
526429-1-1
526429-3-1
526435-111
526435-112
526435-131
526435-132
526435-311
526435-331
526439-1-1
526439-1-2
526439-3-1
526443-251
526443-451
526445-251
526449-3-1
526465-151
526465-152
526465-171
526465-351
526465-371
526469-1-1
526469-1-2
526469-3-1
52647--1-1
526513-111
526513-211
526513-231
526513-311
526515-211
526515-231
526515-232
526519-1-1
526519-1-2
52652-11-1
526523-231
526523-331
526525-211
526525-212
526525-231
526529-1-1
526529-1-2
526533-111
526533-131
526533-132
526533-141
526533-142
526533-211
526533-241
526535-111
526535-112
526535-121
526535-131
526535-132
526535-142
526535-341
526539-1-1
526539-1-2
526539-3-1
526543-271
526545-152
526545-251
526545-252
526549-1-1
526549-1-2
526549-3-1
526559-1-1
526562-252
526563-151
526563-251
526563-252
526565-151
526565-152
526565-171
526569-1-1
526569-1-2
52657--1-1
526613-211
526613-212
526613-231
526613-232
526613-411
526613-431
526613-432
526615-111
526615-131
526615-132
526615-211
526615-212
526615-231
526615-232
526615-411
526615-431
526619-1-1
526619-1-2
526619-3-1
526619-3-2
526623-211
526623-231
526623-431
526625-211
526625-231
526625-331
526629-1-1
526629-1-2
526631-1-1
526633-111
526633-131
526633-211
526633-212
526633-231
526633-241
526633-242
526633-431
526635-111
526635-112
526635-121
526635-131
526635-141
526635-211
526635-311
526635-331
526637-211
526639-1-1
526639-1-2
526639-3-1
526639-3-2
526643-251
526643-252
526645-1-1
526645-251
526645-271
526645-451
526647-251
526649-1-1
526649-1-2
526649-3-1
526659-1-1
526659-3-1
526661-2-1
526663-151
526663-251
526663-252
526663-271
526663-371
526663-451
526663-472
526665-1-1
526665-151
526665-152
526665-171
526665-351
526665-371
526669-1-1
526669-1-2
526669-3-1
52667--1-1
52667--3-1
526713-232
526719-1-1
526733-111
526735-142
526739-1-1
526739-1-2
526765-152
526769-1-1
526769-1-2
526813-211
526815-211
526815-231
526815-411
526819-1-1
526819-1-2
526825-231
526829-1-1
526833-241
526833-341
526834-211
526835-111
526835-131
526835-141
526835-331
526839-1-1
526839-1-2
526839-3-1
526845-251
526849-1-1
526859-1-1
526863-151
526863-171
526865-151
526865-351
526869-1-1
526869-3-2
526919-1-1
526925-411
526929-1-1
526939-3-1
526965-151
526969-1-1
527013-211
527015-231
527015-431
527033-211
527035-111
527035-131
527035-311
527035-331
527039-1-1
527039-1-2
527039-3-1
527045-251
527065-151
527069-1-1
5271-3-121
527113-211
527113-432
527115-211
527115-212
527115-232
527115-332
527115-411
527115-431
527115-432
527119-1-1
527119-2-1
527119-3-1
527125-411
527125-412
527125-432
527127-411
527129-1-1
527129-3-1
527130-3-1
527132-211
527133-111
527133-112
527133-121
527133-241
527133-331
527133-411
527133-412
527135-111
527135-131
527135-141
527135-311
527135-312
527135-321
527135-331
527135-342
527139-1-1
527139-1-2
527139-3-1
527139-3-2
527149-1-2
527149-3-1
527163-151
527163-251
527165-151
527165-171
527165-361
527165-371
527169-1-1
527169-1-2
527169-3-1
527169-3-2
52717--3-1
527213-411
527213-431
527215-211
527215-231
527215-411
527215-431
527219-1-1
527219-3-1
527229-1-1
527230-3-1
527232-241
527233-241
527233-311
527233-411
527234-441
527235-111
527235-131
527235-132
527235-311
527235-312
527235-331
527239-1-1
527239-3-1
527239-3-2
527242-271
527243-451
527245-271
527245-451
527259-1-1
527259-3-1
527262-251
527262-261
527262-271
527263-351
527263-451
527265-151
527265-171
527265-371
527265-372
527269-3-1
527269-3-2
527315-211
527315-411
527319-1-1
527319-3-1
527330-3-1
527330-3-2
527333-141
527333-411
527333-421
527335-111
527335-141
527335-331
527335-341
527335-342
527336-241
527339-1-1
527339-1-2
527339-3-1
527339-3-2
527345-251
527345-451
527363-351
527365-351
527369-1-1
527369-3-1
527413-411
527413-432
527415-132
527415-211
527415-212
527415-231
527415-431
527419-1-1
527419-3-1
527425-231
527425-411
527425-432
527429-1-1
527429-3-1
527430-3-1
527431-3-1
527432-221
527432-231
527432-241
527433-111
527433-121
527433-131
527433-142
527433-212
527433-221
527433-231
527433-241
527433-242
527433-341
527433-342
527434-341
527435-1-1
527435-111
527435-112
527435-121
527435-131
527435-132
527435-141
527435-142
527435-311
527435-312
527435-331
527435-341
527435-342
527436-321
527436-341
527439-1-1
527439-1-2
527439-3-1
527439-3-2
527445-471
527449-1-1
527449-3-2
527453-271
527459-1-1
527459-1-2
527460-271
527460-281
527462-251
527463-151
527465-151
527465-152
527465-161
527465-171
527465-181
527465-351
527465-371
527466-2-1
527469-1-1
527469-1-2
527469-3-1
527515-131
527515-211
527515-411
527515-412
527515-431
527519-1-1
527519-3-1
527529-3-1
527533-111
527533-211
527533-411
527535-132
527535-311
527539-1-1
527539-3-1
527543-452
527545-451
527549-3-2
527562-251
527562-272
527563-151
527569-1-1
527569-3-1
527613-231
527613-411
527615-211
527615-331
527615-411
527615-412
527615-431
527615-432
527619-1-1
527619-3-1
527629-3-2
527632-241
527635-111
527635-342
527639-1-1
527639-3-1
527645-251
527645-451
527649-3-1
527655-251
527664-451
527669-1-1
52768--2-1
527712-211
527715-411
527729-3-2
527733-111
527739-1-1
527739-3-1
527745-451
527749-3-1
527765-171
52777--1-1
52778--241
527813-211
527813-411
527813-431
527815-211
527815-231
527815-232
527819-1-1
527819-3-1
527829-1-1
527829-3-2
527830-3-1
527832-231
527832-241
527833-111
527833-131
527833-211
527833-221
527833-231
527833-241
527833-312
527834-231
527835-111
527835-112
527835-121
527835-122
527835-131
527835-132
527835-141
527835-142
527835-321
527835-332
527835-341
527835-342
527835-442
527836-211
527836-341
527839-1-1
527839-1-2
527839-3-1
527841-1-1
527849-1-1
527849-3-2
527859-1-1
527859-1-2
527863-152
527863-271
527863-351
527865-151
527865-161
527865-171
527865-351
527865-371
527866-261
527869-1-1
527869-3-1
527915-132
527930-3-1
527933-441
527935-111
527935-311
527936-341
527939-1-1
527939-3-1
527963-271
527965-151
527965-171
527969-3-1
528013-211
528013-431
528015-131
528015-211
528015-231
528015-411
528019-1-1
528019-3-1
528023-231
528029-1-1
528029-3-1
528033-111
528033-211
528033-311
528033-411
528035-111
528035-131
528035-132
528035-141
528035-311
528035-341
528039-1-1
528039-1-2
528039-3-1
528045-251
528045-451
528049-1-1
528049-3-1
528063-351
528065-151
528065-152
528065-171
528069-1-1
528069-1-2
528069-3-1
528069-3-2
52807--1-1
52811--591
52811--592
528111-211
528113-211
528113-212
528113-231
528113-232
528113-4-2
528113-411
528113-431
528115-131
528115-211
528115-231
528115-232
528115-411
528115-412
528115-431
528115-432
528119-1-1
528119-1-2
528119-3-1
528123-231
528123-411
528123-431
528125-211
528125-231
528125-232
528125-431
528129-1-1
528129-1-2
528129-3-1
528129-3-2
52813--591
528130-241
528130-3-1
528130-3-2
528131-3-1
528132-2-1
528132-211
528132-221
528132-231
528132-241
528133-111
528133-112
528133-131
528133-141
528133-142
528133-211
528133-231
528133-232
528133-241
528133-311
528133-321
528133-331
528133-341
528133-411
528133-421
528133-441
528133-491
528134-331
528134-341
528134-431
528135-111
528135-112
528135-121
528135-131
528135-132
528135-141
528135-142
528135-211
528135-231
528135-311
528135-312
528135-321
528135-331
528135-332
528135-341
528135-342
528135-491
528136-141
528136-231
528136-232
528136-321
528136-341
528136-342
528137-241
528139-1-1
528139-1-2
528139-2-2
528139-3-1
528139-3-2
528139-4-1
528141-1-2
528142-271
528143-251
528143-451
528143-452
528145-151
528145-251
528145-252
528145-271
528145-451
528145-452
528145-471
528146-251
528149-1-1
528149-1-2
528149-3-1
528149-3-2
528153-251
528155-251
528155-252
528155-451
528159-1-1
528159-3-1
52816--591
528160-3-1
528162-251
528162-252
528162-271
528162-272
528163-151
528163-251
528163-271
528163-351
528163-371
528163-471
528164-251
528164-361
528164-471
528165-1-1
528165-151
528165-161
528165-171
528165-181
528165-3-2
528165-351
528165-352
528165-361
528165-371
528166-251
528166-271
528167-451
528169-1-1
528169-3-1
528169-3-2
52817--1-1
52817--3-1
528192-241
528192-3-1
528213-211
528213-212
528213-231
528213-4-2
528213-432
528215-111
528215-211
528215-231
528215-431
528219-1-1
528219-1-2
528219-3-1
528223-231
528225-211
528225-231
528225-331
528225-431
528229-1-1
528231-1-1
528233-111
528233-131
528233-141
528233-211
528233-231
528233-311
528233-411
528233-412
528235-111
528235-131
528235-141
528235-311
528235-341
528237-312
528239-1-1
528239-3-1
528239-3-2
528239-4-1
528243-251
528243-252
528245-251
528245-271
528245-451
528249-1-1
52826-3152
528261-3-1
528263-251
528263-351
528263-452
528265-151
528265-171
528265-181
528265-351
528269-1-1
528269-1-2
528269-3-1
52827--3-1
528313-211
528313-231
528313-411
528313-432
528315-111
528315-112
528315-211
528315-231
528315-232
528315-331
528315-411
528315-431
528317-231
528319-1-1
528319-1-2
528319-3-1
528323-231
528323-232
528325-231
528325-431
528329-1-1
528329-3-1
528329-3-2
52833--691
528330-3-1
528332-111
528332-241
528332-242
528333-111
528333-132
528333-142
528333-211
528333-311
528333-312
528333-332
528333-341
528333-431
528334-421
528335-111
528335-112
528335-131
528335-132
528335-141
528335-311
528335-331
528335-342
528336-211
528336-321
528339-1-1
528339-1-2
528339-3-1
528339-3-2
528341-1-1
528341-3-1
528343-251
528343-252
528345-251
528345-451
528349-1-1
528349-3-1
528363-171
528363-251
528363-351
528363-451
528365-151
528365-152
528365-351
528365-352
528369-1-1
528369-3-1
528369-3-2
52837--3-1
528413-231
528415-211
528415-212
528415-231
528415-411
528415-412
528415-431
528419-1-1
528419-1-2
528423-231
528425-211
528429-1-1
528429-3-1
528430-3-1
528432-241
528432-242
528433-131
528433-431
528435-111
528435-121
528435-131
528435-141
528435-231
528435-311
528435-312
528435-321
528435-331
528435-341
528436-321
528436-341
528439-1-1
528439-3-1
528439-3-2
528443-251
528445-251
528445-271
528445-451
528449-1-1
528449-3-1
528459-1-1
528459-3-1
528462-261
528462-272
528463-171
528463-271
528465-151
528465-351
528465-371
528469-1-1
528469-3-1
528513-211
528513-231
528515-431
528519-1-1
528519-3-1
528525-211
528529-1-1
528532-241
528533-141
528533-211
528533-311
528533-341
528534-211
528535-111
528535-121
528535-131
528535-141
528535-311
528535-331
528539-1-1
528539-1-2
528539-3-1
528545-251
528545-451
528549-3-1
528563-161
528563-361
528565-151
528565-152
528565-371
528569-1-1
528569-3-1
528619-3-1
528635-111
528639-1-1
528645-251
528713-231
528713-432
528715-211
528715-231
528715-411
528715-431
528719-1-1
528725-432
528729-1-1
528733-241
528735-111
528735-131
528735-141
528735-311
528735-331
528735-341
528736-341
528739-1-1
528739-3-1
528742-271
528745-451
528769-1-1
528769-3-1
52877--1-1
528815-231
528815-431
528835-111
528839-1-1
528839-3-1
528865-151
528869-1-1
528915-211
528915-231
528919-1-1
528925-211
528933-232
528935-111
528935-131
528935-141
528939-1-1
528939-3-1
528945-251
528959-1-1
528965-151
528969-1-1
591----191
591----192
591----291
591----292
591----391
591----392
591----491
591----492
591----591
591----592
591----691
591----791
591----891
591----991
591-11-141
591-11-142
591-12-111
591-12-112
591-13-111
591-13-112
591-13-132
591-13-141
591-15-111
591-15-112
591-15-131
591-15-132
591-19-141
591-19-142
591-21-112
591-21-141
591-21-142
591-23-131
591-25-111
591-29-141
591-3--1-2
591-3--141
591-3--142
591-30-141
591-30-142
591-31-141
591-31-142
591-32-131
591-33-111
591-33-112
591-33-121
591-33-131
591-33-132
591-33-141
591-33-142
591-35-111
591-35-112
591-35-131
591-35-132
591-35-141
591-36-141
591-39-141
591-39-142
591-41-181
591-41-182
591-43-151
591-45-151
591-45-152
591-49-181
591-49-182
591-5-1181
591-6--182
591-61-181
591-61-182
591-63-151
591-63-161
591-63-171
591-65-151
591-65-152
591-65-171
591-65-172
591-69-181
591-69-182
591-7--1-1
591-7--191
591-7--3-1
591-91-1-1
592----1-1
592-5-11-1
592-7--1-1
59207--1-1
59217--1-1
59223--1-1
59227--1-1
59237--1-1
59247--1-1
59257--1-1
59267--1-1
59287--1-1
59307--3-1
59327--1-1
59327--3-1
59347--1-1
59347--3-1
593491-1-1
593491-1-2
59367--1-1
593891-1-1
59417--1-1
59417--3-1
594191-1-1
594196-3-1
594199-3-1
594201-1-1
59427--1-1
594291-1-1
59437--1-1
594391-1-1
594393-141
594395-141
59447--1-1
59447--3-1
59457--1-1
59497--1-1
594991-1-1
595-11-1-1
595-11-1-2
595-13-212
595-15-131
595-15-211
595-15-231
595-31-1-1
595-31-1-2
595-31-3-1
595-33-211
595-33-231
595-33-241
595-35-312
595-39-1-2
595-43-251
595-6--1-2
595-61-1-1
595-61-1-2
595-61-3-1
595-65-151
595-65-172
595-69-1-2
596-13-232
596-15-211
596-15-231
596-15-232
596-19-1-2
596-19-2-2
596-21-1-1
596-29-1-1
596-3--1-2
596-31-1-1
596-31-1-2
596-33-221
596-33-232
596-35-131
596-35-132
596-39-3-2
596-41-3-1
596-61-1-1
596-61-1-2
596-61-3-1
596-63-151
596-65-151
596-65-171
596-69-3-1
596-7--1-1
596011-1-1
596033-211
596263-271
596411-1-1
596419-2-2
596425-211
59653--1-2
596539-2-1
596561-1-1
596613-212
596631-1-1
596631-1-2
596633-111
596635-111
596639-2-1
596661-1-1
596663-271
596831-1-1
596861-1-1
597169-3-2
597245-251
597263-351
597431-1-1
597431-1-2
597433-242
597435-141
597439-2-1
597461-3-1
597615-231
597631-3-1
597823-431
597831-1-1
597833-331
597839-2-1
597845-252
597861-3-1
598112-211
598112-212
598115-231
598130-2-1
598130-242
598131-1-2
598131-3-1
598131-3-2
598132-231
598133-341
598133-412
598133-441
598139-3-1
598149-3-1
598161-1-1
598161-3-1
598163-361
598165-171
598169-1-1
59817--1-1
59817--3-1
598211-1-1
598211-1-2
598213-211
598215-212
598219-1-2
598221-1-1
598221-1-2
598221-112
598229-1-1
598230-3-1
598231-1-1
598231-1-2
598233-132
598233-141
598233-211
598233-231
598235-111
598235-131
598235-132
598239-1-1
598239-1-2
598241-1-1
598241-1-2
598245-251
598245-252
598249-1-2
598261-1-1
598261-1-2
598263-151
598263-251
598265-151
598265-152
598265-172
598269-1-1
598313-2-1
598313-211
598331-1-1
598333-131
598339-1-1
598431-3-1
598441-3-1
598463-451
598465-372
598533-232
598535-332
598565-171
598615-231
598619-1-1
598715-211
598839-1-1
598861-1-1
61---
61--
61--2
61--3
61-0-
61-1-
61-3-
61-4-
61-5-
61-7-
61-9-
611--
611-2
611-3
6110-
61102
6111-
6112-
6113-
6114-
6115-
6116-
6117-
6118-
6119-
612--
612-2
612-3
6120-
61202
6121-
6124-
6125-
61252
61253
6126-
61262
6127-
61272
6128-
61282
6129-
61292
61293
613--
613-2
613-3
6130-
61302
61303
6131-
61312
61313
6132-
6133-
61332
61333
6134-
6135-
61352
61353
6136-
61362
6137-
61372
6138-
61382
61383
6139-
61392
61393
614--
6140-
6141-
6142-
6143-
6144-
6145-
6146-
6147-
6148-
6149-
615--
615-2
615-3
6150-
61502
61503
6151-
61512
6152-
61522
6154-
61542
6155-
61552
61553
6156-
61562
61563
6157-
61572
6158-
61582
61583
6159-
61592
61593
62---
62--
62--2
62-0-
62-7-
62-8-
62-9-
621--
621-2
6210-
6215-
6218-
6219-
622--
6228-
6229-
6230-
6235-
624--
6248-
625--
6256-
63---
63--
63-0-
63-2-
63-3-
63-4-
63-5-
63-6-
63-7-
63-8-
63-9-
632--
6328-
6329-
633--
6330-
6331-
6334-
6335-
6336-
6337-
6338-
6339-
635--
6350-
6351-
6352-
6353-
6354-
6355-
6356-
6357-
6358-
6359-
64---
64--
64-8-
64-9-
6436-
6439-
645--
6450-
6454-
6457-
6458-
6459-
65---
65--
65-0-
65-4-
65-9-
6539-
6559-
7111
71111
7112
71120
71121
71122
71123
71124
71125
7113
71130
71131
71132
71133
71134
71135
7114
71140
71141
71142
71143
71144
71145
7116
71160
71161
71162
71163
71164
71165
7117
71170
71171
71172
71173
71174
71175
7118
71180
7122
71220
71221
71222
71223
71224
71225
7123
71230
71231
7124
71240
71241
71242
71243
71244
71245
7126
71260
71261
71262
71263
71264
71265
7127
71270
71271
71272
71274
7131
71315
7132
71320
71321
71322
71323
71324
71325
7133
71330
71331
71332
71333
71334
71335
7134
71340
71341
71342
71343
71344
71345
7136
71360
71361
71362
71363
71364
71365
7137
71370
71371
71372
71373
71374
71375
7138
71380
71381
71385
72120
72121
72122
72130
72132
72140
72141
72173
72181
72220
72221
72222
72225
72320
72321
72322
72330
72331
72332
72333
72335
72340
72341
72365
72370
72371
7238
72380
73121
73131
73141
73220
73221
73222
73261
73310
73320
73321
73322
73323
73324
73325
73330
73332
73333
73335
73340
73341
73342
73360
73370
73371
73372
7338
73380
8111
8112
8119
8131
8132
8139
8211
8212
8219
8221
8222
8229
8231
8232
8239
8241
8242
8249
8251
8252
8259
8311
8312
8319
8331
8332
8339
8342
8352
8412
8419
8421
8422
8429
8431
8432
8439
8441
8442
8449
8451
8452
8459
8911
8912
8919
8951
8952
910
911
912
913
914
915
917
918
919
920
921
922
923
924
926
929
930
932
933
940
941
942
950
951
952
954
959
960
961
962
963
970
972
973
974
977
F11-
F12-
F125
F131
F132
F134
F140
F141
F143
F144
F145
F15-
F16-
F162
F164
F165
F166
F168
F170
F171
F172
F173
F174
F176
F177
F178
F179
F180
F181
F182
F183
F188
F20
F21
F22
F3
F30
F31
F38
F4-
F40
F41
F42
F43
F44
F45
F46
F47
F48
F49
F51
F52
F6
JC
JP1111
JP1112
JP1113
JP1114
JP1115
JP1116
JP1117
JP1121
JP1122
JP1123
JP1124
JP1126
JP1127
JP1131
JP1132
JP1133
JP1137
JP1211
JP1212
JP1213
JP1214
JP1216
JP1217
JP1221
JP1222
JP1224
JP1226
JP1231
JP1232
JP1234
JP1236
JP1237
JP1311
JP1312
JP1313
JP1314
JP1315
JP1316
JP1317
JP1319
JP1321
JP1322
JP1323
JP1324
JP1326
JP1331
JP1332
JP1333
JP1334
JP1336
JP1337
JP1349
JP1411
JP1412
JP1413
JP1414
JP1416
JP1417
JP1421
JP1511
JP1512
JP1514
JP1516
JP1529
JP1541
JP1544
JP1549
JP2111
JP2112
JP2113
JP2114
JP2116
JP2117
JP2121
JP2122
JP2124
JP2211
JP2212
JP2213
JP2214
JP2216
JP2217
JP2221
JP2222
JP2226
JP2232
JP2236
JP2311
JP2312
JP2313
JP2314
JP2316
JP2317
JP2321
JP2324
JP2331
JP2334
JP2336
JP2349
JP2411
JP2412
JP2413
JP2414
JP2416
JP2421
JP2511
JP2512
JP2514
JP2516
JP2529
JP2541
JP2549
JZ
end_of_list
    ;
    my @clist = split(/\r?\n/, $list);
    my @list;
    foreach my $ctag (@clist)
    {
        my $tag = '';
        my @chars = split(//, $ctag);
        for(my $i = 0; $i<11; $i++)
        {
            my $iplus = $i+1;
            my $character = $chars[$i];
            if(!defined($character) || $character eq '_')
            {
                $character = '';
            }
            $tag .= "<i$iplus>$character</i$iplus>";
        }
        push(@list, $tag);
    }
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::CS::Pmk - Driver for the Czech tagset of the Prague Spoken Corpus (Pražský mluvený korpus).

=head1 VERSION

version 3.013

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::CS::Pmk;
  my $driver = Lingua::Interset::Tagset::CS::Pmk->new();
  my $fs = $driver->decode('<i1>1</i1><i2>1</i2><i3>1</i3><i4>0</i4><i5>1</i5><i6>1</i6><i7>1</i7><i8>1</i8><i9>_</i9><i10>_</i10><i11></i11>');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('cs::pmk', '<i1>1</i1><i2>1</i2><i3>1</i3><i4>0</i4><i5>1</i5><i6>1</i6><i7>1</i7><i8>1</i8><i9>_</i9><i10>_</i10><i11></i11>');

=head1 DESCRIPTION

Interset driver for the long tags of the Prague Spoken Corpus (Pražský mluvený korpus, PMK).

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::CS::Pmkkr>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
