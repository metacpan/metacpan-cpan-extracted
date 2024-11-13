# ABSTRACT: Driver for the tagset of the Prague Dependency Treebank Consolidated.
# Copyright © 2006-2009, 2014, 2016, 2021, 2022 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::CS::Ridics;
use strict;
use warnings;
our $VERSION = '3.016';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset';



has 'atoms' => ( isa => 'HashRef', is => 'ro', builder => '_create_atoms', lazy => 1 );



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'cs::ridics';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for 11 surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # 1. PART OF SPEECH ####################
    $atoms{pos} = $self->create_atom
    (
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # noun
            # examples: pán hrad žena růže město moře
            'NN' => ['pos' => 'noun'],
            'N-' => ['pos' => 'noun'],
            # nominal postfixal segment of a hyphenated compound
            # examples: upista (in "start-upista"), tunga, timu (final parts of Chinese personal names, inflected according to Czech grammar)
            'SN' => ['pos' => 'noun', 'other' => 'postfix'],
            # noun phrase abbreviation ("USA")
            'BN' => ['pos' => 'noun', 'abbr' => 'yes'],
            # isolated letter (used as abbreviation?)
            'Q3' => ['pos' => 'noun', 'abbr' => 'yes', 'other' => 'letter'],
            # adjective
            # examples: mladý jarní
            'AA' => ['pos' => 'adj'],
            # short form of adjective ("jmenný tvar")
            # examples: mlád stár zdráv
            'AC' => ['pos' => 'adj', 'variant' => 'short'],
            # special adjectives: svůj, nesvůj, tentam
            # svůj: other usage than possessive reflexive pronoun
            'AO' => ['pos' => 'adj', 'other' => 'O'],
            # possessive adjective
            # examples: otcův matčin
            'AU' => ['pos' => 'adj', 'poss' => 'yes'],
            # adjective derived from present transgressive of verb
            # examples: dělající
            'AG' => ['pos' => 'adj', 'verbform' => 'part', 'tense' => 'pres', 'voice' => 'act', 'aspect' => 'imp'],
            # adjective derived from past transgressive of verb
            # examples: udělavší
            'AM' => ['pos' => 'adj', 'verbform' => 'part', 'tense' => 'past', 'voice' => 'act', 'aspect' => 'perf'],
            # prefixal segment of a hyphenated compound
            # examples: česko (in "česko-slovenský"), sci (in "sci-fi")
            'S2' => ['pos' => 'adj', 'hyph' => 'yes'],
            # adjectival postfixal segment of a hyphenated compound
            # examples: upový (in "start-upový"), tého, line (in "on-line")
            'SA' => ['pos' => 'adj', 'other' => 'postfix'],
            # adjectival phrase abbreviation ("aj")
            'BA' => ['pos' => 'adj', 'abbr' => 'yes'],
            # personal pronoun
            # examples: já ty my vy
            'PP' => ['pos' => 'noun', 'prontype' => 'prs'],
            # personal pronoun, short inflected variant
            # examples: mě mi ti
            'PH' => ['pos' => 'noun', 'prontype' => 'prs', 'variant' => 'short'],
            # personal pronoun, 3rd person
            # example: on něj
            'PE' => ['pos' => 'noun', 'prontype' => 'prs'],
            # personal pronoun, 3rd person, short inflected variant
            # examples: mu
            'P5' => ['pos' => 'noun', 'prontype' => 'prs', 'variant' => 'short'],
            # compound preposition + personal pronoun
            # examples: naň ("na něj")
            'P0' => ['pos' => 'noun', 'prontype' => 'prs', 'adpostype' => 'preppron'],
            # reflexive personal pronoun, long form
            # examples: sebe sobě sebou
            'P6' => ['pos' => 'noun', 'prontype' => 'prs', 'reflex' => 'yes'],
            # reflexive personal pronoun, short form
            # examples: se si ses sis
            'P7' => ['pos' => 'noun', 'prontype' => 'prs', 'reflex' => 'yes', 'variant' => 'short'],
            # possessive pronoun, 1st or 2nd person
            # examples: můj tvůj náš váš
            'PS' => ['pos' => 'adj', 'prontype' => 'prs', 'poss' => 'yes'],
            # possessive pronoun, 3rd person
            # examples: jeho, její, jejich
            'P9' => ['pos' => 'adj', 'prontype' => 'prs', 'poss' => 'yes'],
            # reflexive possessive pronoun
            # examples: svůj
            'P8' => ['pos' => 'adj', 'prontype' => 'prs', 'poss' => 'yes', 'reflex' => 'yes'],
            # demonstrative pronoun
            # examples: ten tento tenhle onen takový týž tentýž sám
            ###!!! Syntactically they are often adjectives but not always ("to auto je moje" vs. "to je moje").
            'PD' => ['pos' => 'adj', 'prontype' => 'dem'],
            # interrogative or relative pronoun, no gender inflection
            # examples: kdo co kdož copak
            'PQ' => ['pos' => 'noun', 'prontype' => 'int|rel'],
            # interrogative or relative pronoun, with gender (i.e., not only attributive, unlike in cs::pdt, which did not include "jenž" here!)
            # examples: jaký který čí jenž
            'P4' => ['pos' => 'adj|noun', 'prontype' => 'int|rel'],
            # possessive relative pronoun
            # examples: jehož jejíž
            'P1' => ['pos' => 'adj', 'prontype' => 'rel', 'poss' => 'yes'],
            # indefinite pronoun, no gender inflection
            # examples: někdo něco kdokoli kdosi cosi nevímco
            'PK' => ['pos' => 'noun', 'prontype' => 'ind'],
            # indefinite pronoun, attributive
            # examples: nějaký některý něčí čísi sotvakterý
            'PZ' => ['pos' => 'adj', 'prontype' => 'ind'],
            # total pronoun
            # examples: všechen sám
            'PL' => ['pos' => 'noun', 'prontype' => 'tot'],
            # negative pronoun, no gender inflection
            # examples: nikdo nic
            'PY' => ['pos' => 'noun', 'prontype' => 'neg'],
            # negative pronoun, attributive
            # examples: nijaký ničí žádný
            'PW' => ['pos' => 'adj', 'prontype' => 'neg'],
            # cardinal number expressed by digits
            # examples: 1 3,14 2014
            'C=' => ['pos' => 'num', 'numtype' => 'card', 'numform' => 'digit'],
            # cardinal number expressed by Roman numerals
            # examples: MCMLXXI
            # { ... syntax highlighting
            'C}' => ['pos' => 'num', 'numtype' => 'card', 'numform' => 'roman'],
            # interrogative or relative cardinal numeral
            # example: kolik
            'C?' => ['pos' => 'num', 'numtype' => 'card', 'prontype' => 'int|rel'],
            # indefinite or demonstrative cardinal numeral
            # examples: několik mnoho málo kdovíkolik tolik
            'Ca' => ['pos' => 'num', 'numtype' => 'card', 'prontype' => 'ind|dem'],
            # adjectival multiplicative numeral "twofold" (note: these words are included in generic numerals in the Czech grammar)
            # examples: obojí dvojí trojí
            # generic adjectival numeral (number of sets of things)
            # examples: jedny oboje dvoje troje (čtvery patery desatery?)
            # "oboje", "dvoje" and "troje" appear in the corpus as "Cd" and the feature variant=1 distinguishes them from "obojí", "dvojí" and "trojí".
            # Larger numerals of this type ("čtvery", "patery" etc.) do not appear in the corpus.
            'Cd' => ['pos' => 'adj', 'numtype' => 'mult|sets'],
            # generic adjectival numeral (number of sets of things), indefinite
            # examples: několikerý
            'Ch' => ['pos' => 'adj', 'numtype' => 'sets', 'prontype' => 'ind'],
            # generic cardinal numeral
            # examples: čtvero patero desatero
            # This tag is documented in the tagset but it does not occur in the PDT.
            'Cj' => ['pos' => 'num', 'numtype' => 'card', 'other' => {'numtype' => 'generic'}],
            # ordinal suffix as a separate token
            # only one occurrence in the corpus: tých ("posledně v letech 60 tých" = "posledně v letech šedesátých")
            # Syntactic analysis of the above example is Atr(letech, tých); Atr(tých, 60).
            # Hence we can say that the suffix works as an adjective.
            'Ck' => ['pos' => 'adj', 'numtype' => 'ord', 'other' => {'numtype' => 'suffix'}],
            # cardinal numeral, low value (agrees with counted noun)
            # examples: jeden dva tři čtyři
            'Cl' => ['pos' => 'num', 'numtype' => 'card', 'numform' => 'word', 'numvalue' => '1|2|3'],
            # cardinal numeral, high value (in nominative, accusative and vocative behaves like a noun and the counted noun must be in genitive)
            # examples: pět šest sedm sto
            'Cn' => ['pos' => 'num', 'numtype' => 'card', 'numform' => 'word'],
            # indefinite multiplicative numeral
            # examples: několikrát mnohokrát tolikrát kolikrát nesčíslněkrát
            'Co' => ['pos' => 'adv', 'numtype' => 'mult', 'prontype' => 'ind|dem'],
            # ordinal numeral (adjectival)
            # examples: první druhý třetí stý tisící
            # (Note: "poprvé" is another type of ordinal numeral, it behaves syntactically as adverb.
            # It is tagged 'Cv', together with multiplicative numerals ("jedenkrát"), which are also syntactic adverbs.)
            'Cr' => ['pos' => 'adj', 'numtype' => 'ord'],
            # interrogative or relative multiplicative numeral
            # examples: kolikrát
            'Cu' => ['pos' => 'adv', 'numtype' => 'mult', 'prontype' => 'int|rel'],
            # multiplicative numeral or adverbial ordinal numeral
            # examples: jedenkrát dvakrát třikrát stokrát tisíckrát
            # examples: poprvé podruhé potřetí posté potisící
            'Cv' => ['pos' => 'adv', 'numtype' => 'mult'],
            # Two different types of agreeing adjectival indefinite numerals are tagged 'Cw':
            # indefinite numeral "nejeden" = lit. "not one" = "more than one"
            # examples: nejeden
            # indefinite or demonstrative adjectival ordinal numeral
            # examples: několikátý, mnohý, tolikátý
            'Cw' => ['pos' => 'adj', 'numtype' => 'ord', 'prontype' => 'ind|dem'],
            # cardinal numeral, fraction denominator
            # examples: polovina třetina čtvrtina setina tisícina
            # These words behave morphologically and syntactically as feminine nouns of the paradigm "žena".
            # (Note that the fraction words "půl" and "čtvrt" are not tagged "Cy".)
            'Cy' => ['pos' => 'num', 'numtype' => 'frac'],
            # interrogative or relative ordinal numeral
            # examples: kolikátý
            'Cz' => ['pos' => 'adj', 'numtype' => 'ord', 'prontype' => 'int|rel'],
            # adjectival postfixal segment of a hyphenated compound
            # examples: ti (in "755-ti")
            'Sl' => ['pos' => 'adj', 'other' => 'postfix', 'numtype' => 'card', 'numform' => 'word'],
            # verb infinitive
            # examples: nést dělat říci
            'Vf' => ['pos' => 'verb', 'verbform' => 'inf'],
            # verb supine
            # example: modlit (infinitive: modliti), hledat (infinitive: hledati)
            'V$' => ['pos' => 'verb', 'verbform' => 'sup'],
            # finite verb, present or future indicative
            # examples: nesu beru mažu půjdu
            'VB' => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres'], # tense may be later overwritten by 'fut'
            # finite verb, present or future indicative with encliticized 'neboť'
            # examples: dělámť děláť
            'Vt' => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres', 'voice' => 'act', 'verbtype' => 'verbconj'],
            # finite verb, simple past (aorist or imperfect) indicative
            # examples: bieše, vecě, prosiechu
            'V-' => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'ind', 'tense' => 'past'], # tense may be later overwritten by 'imp'
            # verb imperative
            # examples: nes dělej řekni
            'Vi' => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'imp'],
            # conditional auxiliary verb form (evolved from aorist of 'to be')
            # examples: bych bys by bychom byste
            'Vc' => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'cnd'],
            # verb active participle
            # examples: dělal dělala dělalo dělali dělaly dělals dělalas ...
            'Vp' => ['pos' => 'verb', 'verbform' => 'part', 'tense' => 'past', 'voice' => 'act'],
            # verb active participle with encliticized 'neboť'
            # examples: dělalť dělalať dělaloť ...
            'Vq' => ['pos' => 'verb', 'verbform' => 'part', 'tense' => 'past', 'voice' => 'act', 'verbtype' => 'verbconj'],
            # verb passive participle
            # examples: dělán dělána děláno děláni dělány udělán udělána
            'Vs' => ['pos' => 'verb', 'verbform' => 'part', 'voice' => 'pass'],
            # verb present transgressive (converb, gerund, přechodník)
            # examples: nesa nesouc nesouce dělaje dělajíc dělajíce
            'Ve' => ['pos' => 'verb', 'verbform' => 'conv', 'tense' => 'pres', 'aspect' => 'imp', 'voice' => 'act'],
            # verb past transgressive (converb, gerund, přechodník)
            # examples: udělav udělavši udělavše přišed přišedši přišedše
            'Vm' => ['pos' => 'verb', 'verbform' => 'conv', 'tense' => 'past', 'aspect' => 'perf', 'voice' => 'act'],
            # adverb
            'D-' => ['pos' => 'adv'],
            # adverb with degree of comparison and polarity
            # examples: málo chytře
            'Dg' => ['pos' => 'adv'],
            # adverb without degree of comparison and polarity
            # examples: kde kam kdy jak tady dnes
            'Db' => ['pos' => 'adv'],
            # adverbial postfixal segment of a hyphenated compound
            # examples: line (in "on-line")
            'Sb' => ['pos' => 'adv', 'other' => 'postfix'],
            # adverbial phrase abbreviation ("atd")
            'Bb' => ['pos' => 'adv', 'abbr' => 'yes'],
            # preposition
            # examples: v pod k
            'RR' => ['pos' => 'adp', 'adpostype' => 'prep'],
            'R-' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # vocalized preposition
            # examples: ve pode ke ku
            'RV' => ['pos' => 'adp', 'adpostype' => 'voc'],
            # first part of compound preposition
            # examples: nehledě na, vzhledem k
            'RF' => ['pos' => 'adp', 'adpostype' => 'comprep'],
            # conjunction
            'J-' => ['pos' => 'conj'],
            # coordinating conjunction
            # examples: a i ani nebo ale avšak
            'J^' => ['pos' => 'conj', 'conjtype' => 'coor'],
            # subordinating conjunction
            # examples: že, aby, zda, protože, přestože
            'J,' => ['pos' => 'conj', 'conjtype' => 'sub'],
            # mathematical conjunction (the word 'times' in 'five times')
            # examples: krát
            'J*' => ['pos' => 'conj', 'conjtype' => 'oper'],
            # conjunction phrase abbreviation ("tzn")
            'B^' => ['pos' => 'conj', 'conjtype' => 'coor', 'abbr' => 'yes'],
            # particle
            # examples: ať kéž nechť
            'TT' => ['pos' => 'part'],
            'T-' => ['pos' => 'part'],
            # interjection
            # examples: haf bum bác
            'II' => ['pos' => 'int'],
            'I-' => ['pos' => 'int'],
            # punctuation
            # examples: . ? ! , ; : -
            'Z:' => ['pos' => 'punc'],
            # artificial root node of the sentence
            # examples: #
            "Z\#" => ['pos' => 'punc', 'punctype' => 'root'],
            # foreign word
            'F%' => ['foreign' => 'yes'],
            # X: unknown part of speech
            # unrecognized word form
            'X@' => ['other' => '@'],
            # word form recognized but tag is missing in dictionary
            'XX' => ['other' => 'X'],
            # - should never appear as subpos but it does, even in the list in b2800a.o2f
            'X-' => ['other' => '-']
        },
        'encode_map' => {} # Encoding of part of speech must be solved directly in Perl code, it would be too complicated to do it here.
    );
    # 2. GENDER ####################
    $atoms{gender} = $self->create_atom
    (
        'surfeature' => 'gender',
        'decode_map' =>
        {
            'M' => ['gender' => 'masc', 'animacy' => 'anim'],
            'I' => ['gender' => 'masc', 'animacy' => 'inan'],
            'F' => ['gender' => 'fem'],
            'N' => ['gender' => 'neut'],
            'Y' => ['gender' => 'masc'],
            'T' => ['gender' => 'masc|fem', 'animacy' => 'inan|'],
            'W' => ['gender' => 'masc|neut', 'animacy' => 'inan|'],
            'H' => ['gender' => 'fem|neut'],
            'Q' => ['gender' => 'fem|neut'],
            'Z' => ['gender' => 'masc|neut'],
            'X' => []
        },
        'encode_map' =>

            { 'gender' => { 'fem|masc'  => 'T',
                            'fem|neut'  => { 'number' => { 'plur|sing' => 'Q',
                                                           'sing'     => 'H',
                                                           'plur'      => 'H',
                                                           '@'        => 'H' }},
                            'masc|neut' => { 'animacy' => { 'inan' => 'W',
                                                                '@'    => 'Z' }},
                            'masc'      => { 'animacy' => { ''     => 'Y',
                                                                'inan' => 'I',
                                                                '@'    => 'M' }},
                            'fem'  => 'F',
                            'neut' => 'N' }}
    );
    # 3. NUMBER ####################
    $atoms{number} = $self->create_atom
    (
        'surfeature' => 'number',
        'decode_map' =>
        {
            'S' => ['number' => 'sing'],
            'D' => ['number' => 'dual'],
            'P' => ['number' => 'plur'],
            'W' => ['number' => 'sing|plur'],
            'X' => []
        },
        'encode_map' =>

            # Do not generate number for conditional auxiliaries. It is encoded as aggregate there.
            { 'mood' => { 'cnd' => '',
                          '@'   => { 'number' => { 'plur|sing' => 'W',
                                                   'dual' => 'D',
                                                   'plur' => 'P',
                                                   'sing' => 'S' }}}}
    );
    # 4. CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            '1' => 'nom',
            '2' => 'gen',
            '3' => 'dat',
            '4' => 'acc',
            '5' => 'voc',
            '6' => 'loc',
            '7' => 'ins'
        }
    );
    # 5. POSSGENDER ####################
    $atoms{possgender} = $self->create_atom
    (
        'surfeature' => 'possgender',
        'decode_map' =>
        {
            'M' => ['possgender' => 'masc'],
            'F' => ['possgender' => 'fem'],
            'N' => ['possgender' => 'neut'],
            'Y' => ['possgender' => 'masc'],
            'Z' => ['possgender' => 'masc|neut'],
        },
        'encode_map' =>

            { 'possgender' => { 'masc|neut' => 'Z',
                                'masc' => { 'prontype' => { ''  => 'M',
                                                            '@' => 'Y' }},
                                'fem'  => 'F',
                                'neut' => 'N' }}
    );
    # 6. POSSNUMBER ####################
    $atoms{possnumber} = $self->create_simple_atom
    (
        'intfeature' => 'possnumber',
        'simple_decode_map' =>
        {
            'S' => 'sing',
            'P' => 'plur'
        }
    );
    # 7. PERSON ####################
    $atoms{person} = $self->create_atom
    (
        'surfeature' => 'person',
        'decode_map' =>
        {
            '1' => ['person' => '1'],
            '2' => ['person' => '2'],
            '3' => ['person' => '3']
        },
        'encode_map' =>

            # Do not generate person for conditional auxiliaries. It is encoded as aggregate there.
            { 'mood' => { 'cnd' => '',
                          '@'   => { 'person' => { '1' => '1',
                                                   '2' => '2',
                                                   '3' => '3' }}}}
    );
    # 8. TENSE ####################
    $atoms{tense} = $self->create_atom
    (
        'surfeature' => 'tense',
        'decode_map' =>
        {
            'A' => ['tense' => 'past'], # aorist
            'I' => ['tense' => 'imp'],  # imperfekt
            'R' => ['tense' => 'past'],
            'H' => ['tense' => 'past|pres'],
            'P' => ['tense' => 'pres'],
            'F' => ['tense' => 'fut'],
        },
        'encode_map' =>

            # Do not encode tense of verbal adjectives and transgressives. Otherwise encode(decode(x)) will not equal to x.
            { 'pos' => { 'adj' => '',
                         '@'   => { 'verbform' => { 'conv' => '',
                                                    'fin'  => { 'tense' => { 'past' => 'A',
                                                                             'imp'  => 'I',
                                                                             'fut'  => 'F',
                                                                             'pres' => 'P' }},
                                                    '@'    => { 'tense' => { 'past|pres' => 'H',
                                                                             'past' => 'R',
                                                                             'fut'  => 'F',
                                                                             'pres' => 'P' }}}}}}
    );
    # 9. DEGREE ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            '1' => 'pos',
            '2' => 'cmp',
            '3' => 'sup'
        }
    );
    # 10. POLARITY ####################
    $atoms{polarity} = $self->create_atom
    (
        'surfeature' => 'polarity',
        'decode_map' =>
        {
            'A' => ['polarity' => 'pos'],
            'N' => ['polarity' => 'neg']
        },
        'encode_map' =>

            # Do not encode polarity of negative pronouns. Otherwise encode(decode(x)) will not equal to x.
            { 'prontype' => { 'neg' => '',
                              '@'   => { 'polarity' => { 'pos' => 'A',
                                                         'neg' => 'N' }}}}
    );
    # 11. VOICE ####################
    $atoms{voice} = $self->create_atom
    (
        'surfeature' => 'voice',
        'decode_map' =>
        {
            'A' => ['voice' => 'act'],
            'P' => ['voice' => 'pass']
        },
        'encode_map' =>

            # Do not encode voice of verbal adjectives and transgressives. Otherwise encode(decode(x)) will not equal to x.
            { 'pos' => { 'adj' => '',
                         '@'   => { 'verbform' => { 'conv' => '',
                                                    '@'     => { 'voice' => { 'act'  => 'A',
                                                                              'pass' => 'P' }}}}}}
    );
    # 12. ASPECT ####################
    $atoms{aspect} = $self->create_atom
    (
        'surfeature' => 'aspect',
        'decode_map' =>
        {
            'P' => ['aspect' => 'perf'],    # napsat
            'I' => ['aspect' => 'imp'],     # psát
            'B' => ['aspect' => 'imp|perf'] # absolvovat
        },
        'encode_map' =>

            # Do not encode aspect of verbal adjectives. Otherwise encode(decode(x)) will not equal to x.
            { 'pos' => { 'adj' => '',
                         '@'   => { 'aspect' => { 'imp|perf' => 'B',
                                                  'imp'      => 'I',
                                                  'perf'     => 'P' }}}}
    );
    # 13. AGGREGATE ####################
    $atoms{aggregate} = $self->create_atom
    (
        'surfeature' => 'aggregate',
        'decode_map' =>
        {
            # In PDT-C, unlike in previous versions of PDT, the conditional forms of the auxiliary 'být'
            # are analyzed as aggregates (contractions) of 'by' ('aby', 'kdyby') and the present form ('jsem', 'jsi', 'jsme', 'jste').
            # Nevertheless, the aggregate 's' also includes other aggregates with -s = jsi.
            'c' => ['person' => '1', 'number' => 'sing'], # bych, bysem
            's' => ['person' => '2', 'number' => 'sing'], # bys, přišels, kdyžs
            'm' => ['person' => '1', 'number' => 'plur'], # bychom, bysme
            'e' => ['person' => '2', 'number' => 'plur']  # byste
        },
        'encode_map' =>

            # Since this currently occurs mostly with conditional verbs, we do not want to do it for personal pronouns
            # (which always have person and number). However, in the future we may need to be able to use it with
            # pronouns 'tys', 'ses', and 'sis'. We also do not want to generate this with present indicative verbs.
            { 'pos' => { 'verb' => { 'mood' => { 'cnd' => { 'number' => { 'sing' => { 'person' => { '1' => 'c',
                                                                                                    '2' => 's' }},
                                                                          'plur' => { 'person' => { '1' => 'm',
                                                                                                    '2' => 'e' }}}}}}}}
    );
    # 14. VARIANT ####################
    $atoms{variant} = $self->create_atom
    (
        'surfeature' => 'variant',
        'decode_map' =>
        {
            '0' => ['variant' => '0'], # 0 does not occur in the data. Dash ('-') is the neutral value for standard contemporary style
            '1' => ['variant' => '1'], # standard variant: orli, myslet, jejž
            # Unlike in cs::pdt, variants 2-4 are not necessarily archaic. For example, the personal pronoun forms used before preposition (něj, něhož etc.) get one of these variants.
            '2' => ['variant' => '2'], # standard variant: mysliti, nějž
            '3' => ['variant' => '3'], # standard variant: mysleti, něhož
            '4' => ['variant' => '4'], # standard variant: pomažemť
            '5' => ['variant' => '5', 'style' => 'coll'], # non-standard variant: přídeme
            '6' => ['variant' => '6', 'style' => 'coll'], # non-standard variant: přijdem
            '7' => ['variant' => '7', 'style' => 'coll'], # non-standard variant: přídem
            '8' => ['variant' => '8', 'style' => 'coll'], # non-standard variant: příjdeme
            '9' => ['variant' => '9', 'typo' => 'yes'],   # non-standard variant, misspelling: příjdem
            'b' => ['variant' => 'b', 'abbr' => 'yes'], # abbreviated form: s (= sekunda)
            'a' => ['variant' => 'a', 'abbr' => 'yes'], # other abbreviated form: sec (= sekunda)
            'c' => ['variant' => 'c', 'abbr' => 'yes']  # other abbreviated form: sek (= sekunda)
        },
        'encode_map' =>

            { 'variant' => { '0' => '0',
                             '1' => '1',
                             '2' => '2',
                             '3' => '3',
                             '4' => '4',
                             '5' => '5',
                             '6' => '6',
                             '7' => '7',
                             '8' => '8',
                             '9' => '9',
                             'a' => 'a',
                             'b' => 'b',
                             'c' => 'c',
                             # We cannot take abbreviation into account here because it would conflict with the old encoding of abbreviations in SUBPOS.
                             '@' => { 'style' => { 'arch' => '2',
                                                   'coll' => '5' }}}}
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
    $fs->set_tagset('cs::ridics');
    my $atoms = $self->atoms();
    my @chars = split(//, $tag);
    $atoms->{pos}->decode_and_merge_hard($chars[0].$chars[1], $fs);
    $atoms->{gender}->decode_and_merge_hard($chars[2], $fs);
    $atoms->{number}->decode_and_merge_hard($chars[3], $fs);
    $atoms->{case}->decode_and_merge_hard($chars[4], $fs);
    $atoms->{possgender}->decode_and_merge_hard($chars[5], $fs);
    $atoms->{possnumber}->decode_and_merge_hard($chars[6], $fs);
    $atoms->{person}->decode_and_merge_hard($chars[7], $fs);
    $atoms->{tense}->decode_and_merge_hard($chars[8], $fs);
    $atoms->{degree}->decode_and_merge_hard($chars[9], $fs);
    $atoms->{polarity}->decode_and_merge_hard($chars[10], $fs);
    $atoms->{voice}->decode_and_merge_hard($chars[11], $fs);
    $atoms->{aggregate}->decode_and_merge_hard($chars[13], $fs);
    $atoms->{variant}->decode_and_merge_hard($chars[14], $fs);
    $atoms->{aspect}->decode_and_merge_hard($chars[15], $fs);
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
    # pos and subpos
    # Foreign words must come first because then we do not care about the foreign part of speech, if present.
    if($fs->is_foreign())
    {
        $tag = 'F%---------------';
    }
    # Numerals and pronouns must come first because they can be at the same time also nouns or adjectives.
    elsif($fs->is_numeral())
    {
        if($fs->numform() eq 'digit')
        {
            $tag = 'C=---------------';
        }
        elsif($fs->numform() eq 'roman')
        { #{
            $tag = 'C}---------------';
        }
        elsif($fs->numtype() eq 'card')
        {
            if($fs->is_wh())
            {
                # kolik
                $tag = 'C?---------------';
            }
            elsif($fs->contains('prontype', 'ind') || $fs->contains('prontype', 'dem'))
            {
                # několik, mnoho, málo, tolik
                $tag = 'Ca--X------------';
            }
            # certain "generic" numerals (druhové číslovky) are classified as cardinals
            elsif($fs->get_other_subfeature('cs::ridics', 'numtype') eq 'generic')
            {
                # čtvero, patero, desatero
                $tag = 'Cj---------------';
            }
            elsif(scalar(grep {m/^[123]$/} ($fs->get_list('numvalue')))>=1)
            {
                # jeden, jedna, jedno, dva, dvě, tři, čtyři
                $tag = 'Cl-XX------------';
            }
            else
            {
                # pět, deset, patnáct, devadesát, sto
                $tag = 'CnXXX------------';
            }
        }
        elsif($fs->numtype() eq 'ord')
        {
            if($fs->is_wh())
            {
                # kolikátý
                $tag = 'CzXXX------------';
            }
            elsif($fs->contains('prontype', 'ind') || $fs->contains('prontype', 'dem'))
            {
                # několikátý, mnohý, tolikátý
                # but also: nejeden
                $tag = 'CwXXX------------';
            }
            elsif($fs->get_other_subfeature('cs::ridics', 'numtype') eq 'suffix' ||
               $fs->gender() eq '' && $fs->number() ne '')
            {
                # tých
                $tag = 'Ck-XX------------';
            }
            else
            {
                $tag = 'CrXXX------------';
            }
        }
        elsif($fs->numtype() eq 'mult')
        {
            if($fs->is_wh())
            {
                # kolikrát
                $tag = 'Cu---------------';
            }
            elsif($fs->contains('prontype', 'ind') || $fs->contains('prontype', 'dem'))
            {
                # několikrát, mnohokrát, tolikrát
                $tag = 'Co---------------';
            }
            else
            {
                $tag = 'Cv---------------'; ###!!! pozor tohle jsou i řadové číslovky příslovečné (poprvé, podruhé...)
            }
        }
        elsif($fs->numtype() eq 'frac')
        {
            $tag = 'Cy---------------';
        }
        elsif($fs->numtype() eq 'sets' && $fs->contains('prontype', 'ind'))
        {
            # několikerý
            $tag = 'Ch---------------';
            # "nejedny" is indefinite numeral and has its own tag 'Cw'.
            # "oboje", "dvoje", "troje" (and "čtvery", "patery", "desatery"?) are included in "Cd", together with "obojí", "dvojí", "trojí".
        }
        else
        {
            # obojí, dvojí, trojí (both-fold, twofold, three-fold)
            # oboje, dvoje, troje (both sets of, two sets of, three sets of)
            # The latter are distinguished by variant=1.
            $tag = 'CdX--------------';
        }
    }
    elsif($fs->is_pronominal())
    {
        # possessive pronoun
        if($fs->is_possessive())
        {
            if($fs->is_wh())
            {
                # jehož, jejíž, jejichž
                # it has possgender if it is 3rd person
                if($fs->person() eq '3')
                {
                    $tag = 'P1XXXX-----------';
                }
                else
                {
                    $tag = 'P1XXX------------';
                }
            }
            elsif($fs->is_reflexive())
            {
                # svůj
                $tag = 'P8XXX------------';
            }
            else
            {
                # můj, tvůj, jeho, její, náš, váš, jejich
                # it has possgender if it is 3rd person
                if($fs->person() eq '3')
                {
                    $tag = 'P9XXXXX----------';
                }
                else
                {
                    $tag = 'PSXXX-X----------';
                }
            }
        }
        # personal pronoun
        elsif($fs->adpostype() eq 'preppron')
        {
            $tag = 'P0---------------'; # oň, naň
        }
        elsif($fs->prontype() eq 'prs')
        {
            if(!$fs->is_reflexive())
            {
                if($fs->variant() eq 'short')
                {
                    # mi, mě, ti, tě, mu
                    # it has gender if it is 3rd person
                    if($fs->person() eq '3')
                    {
                        $tag = 'P5XXX------------';
                    }
                    else
                    {
                        $tag = 'PH--X------------';
                    }
                }
                else
                {
                    # já, ty, on, ona, ono, my, vy, oni, ony
                    # it has gender if it is 3rd person
                    if($fs->person() eq '3')
                    {
                        $tag = 'PEXXX------------';
                    }
                    else
                    {
                        $tag = 'PP-XX------------';
                    }
                }
            }
            else # reflexive
            {
                if($fs->variant() eq 'short')
                {
                    # si, sis, se, ses
                    $tag = 'P7--X------------';
                }
                else
                {
                    # sebe, sobě, sebou
                    $tag = 'P6--X------------';
                }
            }
        }
        # negative pronoun
        elsif($fs->polarity() eq 'neg' || $fs->prontype() eq 'neg')
        {
            # nikdo, nic, nijaký, ničí, žádný
            if($fs->is_noun())
            {
                # nikdo, nic
                $tag = 'PY--X------------';
            }
            else
            {
                # nijaký, ničí, žádný
                $tag = 'PWXXX------------';
            }
        }
        # demonstrative pronoun
        elsif($fs->prontype() eq 'dem')
        {
            # ten, tento, tenhle, onen, takový, týž, tentýž
            $tag = 'PDXXX------------';
        }
        # interrogative or relative pronoun
        elsif($fs->is_wh())
        {
            # P4 inflects for gender and PQ does not. Unfortunately, this does not
            # help us to distinguish them because an empty gender is either '-' (PQ-) or 'X' (P4X).
            # We decode PQ as pos=noun, while P4 has pos=adj|noun, so let's use this.
            if($fs->is_noun() && !$fs->is_adjective())
            {
                # kdo, co
                $tag = 'PQ--X------------';
            }
            else
            {
                # jaký, který, čí, jenž
                $tag = 'P4XXX------------';
            }
        }
        # totality (collective) pronoun
        elsif($fs->prontype() eq 'tot')
        {
            # it has gender and number if it is plural or if it does not have case
            if($fs->is_plural() || $fs->case() eq '')
            {
                $tag = 'PLXXX------------';
            }
            else
            {
                $tag = 'PL--X------------';
            }
        }
        # indefinite pronoun
        elsif($fs->is_noun())
        {
            $tag = 'PK--X------------';
        }
        else
        {
            $tag = 'PZXXX------------';
        }
    }
    elsif($fs->is_noun())
    {
        if($fs->tagset() eq 'cs::ridics' && $fs->other() eq 'letter')
        {
            $tag = 'Q3---------------';
        }
        elsif($fs->is_abbreviation() && $fs->variant() !~ m/^[abc]$/)
        {
            # We have to set the default 'A' here for the case that 'Q3' is stored without other=letter.
            $tag = 'BNXXX-----A------';
        }
        elsif($fs->tagset() eq 'cs::ridics' && $fs->other() eq 'postfix')
        {
            $tag = 'SNXXX------------';
        }
        else
        {
            $tag = 'N----------------';
        }
    }
    elsif($fs->is_adjective())
    {
        if($fs->is_abbreviation() && $fs->variant() !~ m/^[abc]$/)
        {
            $tag = 'BAXXX------------';
        }
        elsif($fs->tagset() eq 'cs::ridics' && $fs->other() eq 'postfix')
        {
            $tag = 'SAXXX------------';
        }
        elsif($fs->variant() eq 'short')
        {
            $tag = 'ACXX-------------';
        }
        elsif($fs->is_possessive())
        {
            $tag = 'AUXXX------------';
        }
        elsif($fs->is_participle() && $fs->is_past())
        {
            $tag = 'AMXXX------------';
        }
        elsif($fs->is_participle())
        {
            $tag = 'AGXXX------------';
        }
        elsif($fs->is_hyph())
        {
            $tag = 'S2---------------';
        }
        elsif($fs->get_other_for_tagset('cs::ridics') eq 'O' ||
              $fs->case() eq '' && $fs->polarity() eq '')
        {
            $tag = 'AOXX-------------';
        }
        else
        {
            $tag = 'AAXXX------------';
        }
    }
    elsif($fs->is_verb())
    {
        if($fs->is_infinitive())
        {
            $tag = 'Vf---------------';
        }
        elsif($fs->is_supine())
        {
            $tag = 'V$---------------';
        }
        elsif($fs->is_participle())
        {
            if($fs->voice() eq 'pass')
            {
                $tag = 'VsXX-------------';
            }
            elsif($fs->verbtype() eq 'verbconj')
            {
                $tag = 'VqXX---XX--------';
            }
            else # default is active past/conditional participle
            {
                $tag = 'VpXX----X--------';
            }
        }
        elsif($fs->is_transgressive())
        {
            if($fs->tense() eq 'past')
            {
                $tag = 'VmX--------------';
            }
            else # default is present transgressive
            {
                $tag = 'VeX--------------';
            }
        }
        else # default is finite verb
        {
            if($fs->mood() eq 'imp')
            {
                $tag = 'Vi-X---X---------';
            }
            elsif($fs->mood() =~ m/^(cnd|sub)$/)
            {
                $tag = 'Vc---------------';
            }
            else # indicative
            {
                if($fs->verbtype() eq 'verbconj')
                {
                    $tag = 'Vt-X---XX--------';
                }
                elsif($fs->tense() =~ m/^(past|imp)$/) # aorist or imperfect
                {
                    $tag = 'V--X---XX--------';
                }
                else
                {
                    $tag = 'VB-X---XX--------';
                }
            }
        }
    }
    elsif($fs->is_adverb())
    {
        if($fs->is_abbreviation() && $fs->variant() !~ m/^[abc]$/)
        {
            $tag = 'Bb---------------';
        }
        elsif($fs->tagset() eq 'cs::ridics' && $fs->other() eq 'postfix')
        {
            $tag = 'Sb---------------';
        }
        else
        {
            $tag = 'D----------------';
        }
    }
    elsif($fs->is_adposition())
    {
        if($fs->adpostype() eq 'comprep')
        {
            $tag = 'RF---------------';
        }
        elsif($fs->adpostype() eq 'voc')
        {
            $tag = 'RV--X------------';
        }
        else
        {
            $tag = 'R---X------------';
        }
    }
    elsif($fs->is_conjunction())
    {
        if($fs->is_subordinator())
        {
            # it has number if it has (3rd) person
            if($fs->person() eq '3')
            {
                $tag = 'J,-X-------------';
            }
            else
            {
                $tag = 'J,---------------';
            }
        }
        elsif($fs->is_coordinator())
        {
            $tag = 'J^---------------';
        }
        elsif($fs->conjtype() eq 'oper')
        {
            $tag = 'J*---------------';
        }
        elsif($fs->is_abbreviation() && $fs->variant() !~ m/^[abc]$/)
        {
            $tag = 'B^---------------';
        }
        else # by default the diachronic data do not distinguish conjunction subtypes
        {
            $tag = 'J----------------';
        }
    }
    elsif($fs->is_particle())
    {
        $tag = 'T----------------';
    }
    elsif($fs->is_interjection())
    {
        $tag = 'I----------------';
    }
    elsif($fs->is_punctuation())
    {
        if($fs->punctype() eq 'root')
        {
            $tag = 'Z#---------------';
        }
        else
        {
            $tag = 'Z:---------------';
        }
    }
    else # default is unknown tag
    {
        my $other = $fs->get_other_for_tagset('cs::ridics');
        # Unknown abbreviation can be encoded either as 'XX------------8' or as 'Xx-------------' but not as 'Xx------------8'.
        if($fs->variant() eq '8')
        {
            $tag = 'XX---------------';
        }
        elsif($other =~ m/^[-X\@]$/)
        {
            $tag = 'X'.$other.'---------------';
        }
        elsif($fs->is_abbreviation())
        {
            $tag = 'Xx---------------';
        }
        else
        {
            $tag = 'X@---------------';
        }
    }
    # Now encode the features.
    # The PDT tagset distinguishes unknown values ("X") and irrelevant features ("-").
    # Interset does not do this distinction but we have prepared the defaults for empty values above.
    my @tag = split(//, $tag);
    my @features = ('pos', 'subpos', 'gender', 'number', 'case', 'possgender', 'possnumber', 'person', 'tense', 'degree', 'polarity', 'voice', undef, 'aggregate', 'variant', 'aspect');
    my $atoms = $self->atoms();
    for(my $i = 2; $i<16; $i++)
    {
        next if(!defined($features[$i]));
        my $atag = $atoms->{$features[$i]}->encode($fs);
        # If we got undef, there is something wrong with our encoding tables.
        if(!defined($atag))
        {
            print STDERR ("\n", $fs->as_string(), "\n");
            confess("Cannot encode '$features[$i]'");
        }
        if($atag ne '')
        {
            $tag[$i] = $atag;
        }
    }
    $tag = join('', @tag);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags. The list was collected from the
# (partial and ambiguous) morphological analysis of the Dresden and Olomouc
# Bibles.
# 337
# Z nich jsem kvůli konzistenci vyhodil: 0
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
D----------------
D--------1-------
D--------2-------
I----------------
J----------------
N-FD1------------
N-FD2------------
N-FD3------------
N-FD4------------
N-FD5------------
N-FD6------------
N-FD7------------
N-FP1------------
N-FP2------------
N-FP3------------
N-FP4------------
N-FP5------------
N-FP6------------
N-FP7------------
N-FS1------------
N-FS2------------
N-FS3------------
N-FS4------------
N-FS5------------
N-FS6------------
N-FS7------------
N-M--------------
N-MD1------------
N-MD2------------
N-MD3------------
N-MD4------------
N-MD5------------
N-MD6------------
N-MD7------------
N-MP1------------
N-MP2------------
N-MP3------------
N-MP4------------
N-MP5------------
N-MP6------------
N-MP7------------
N-MS1------------
N-MS2------------
N-MS3------------
N-MS4------------
N-MS5------------
N-MS6------------
N-MS7------------
N-ND1------------
N-ND2------------
N-ND3------------
N-ND4------------
N-ND5------------
N-ND6------------
N-ND7------------
N-NP1------------
N-NP2------------
N-NP3------------
N-NP4------------
N-NP5------------
N-NP6------------
N-NP7------------
N-NS1------------
N-NS2------------
N-NS3------------
N-NS4------------
N-NS5------------
N-NS6------------
N-NS7------------
R---2------------
R---3------------
R---4------------
R---6------------
R---7------------
T----------------
V\$--------A----I-
V--D---1A-AA---I-
V--D---1A-AA---P-
V--D---2A-AA---I-
V--D---2A-AA---P-
V--D---2I-AA---I-
V--D---2I-AA---P-
V--D---3A-AA---I-
V--D---3A-AA---P-
V--D---3I-AA---I-
V--D---3I-AA---P-
V--P---1A-AA---I-
V--P---1A-AA---P-
V--P---2A-AA---I-
V--P---2A-AA---P-
V--P---3A-AA---I-
V--P---3A-AA---P-
V--P---3A-NA---I-
V--P---3A-NA---P-
V--P---3I-AA---I-
V--P---3I-AA---P-
V--P---3I-NA---I-
V--S---1A-AA---I-
V--S---1A-AA---P-
V--S---1I-AA---I-
V--S---1I-AA---P-
V--S---2A-AA---I-
V--S---2A-AA---P-
V--S---2A-NA---I-
V--S---2A-NA---P-
V--S---2I-AA---I-
V--S---2I-AA---P-
V--S---2I-NA---I-
V--S---2I-NA---P-
V--S---3A-AA---I-
V--S---3A-AA---P-
V--S---3A-NA---I-
V--S---3A-NA---P-
V--S---3I-AA---I-
V--S---3I-AA---P-
V--S---3I-NA---I-
V--S---3I-NA---P-
VB-D---2F-AA---I-
VB-D---2F-AA---P-
VB-D---2P-AA---I-
VB-D---2P-AA---P-
VB-D---2P-NA---I-
VB-D---2P-NA---P-
VB-D---3F-AA---I-
VB-D---3F-AA---P-
VB-D---3P-AA---I-
VB-D---3P-AA---P-
VB-D---3P-NA---I-
VB-D---3P-NA---P-
VB-P---1F-AA---I-
VB-P---1F-AA---P-
VB-P---1P-AA---I-
VB-P---1P-AA---P-
VB-P---1P-NA---I-
VB-P---1P-NA---P-
VB-P---2F-AA---I-
VB-P---2F-AA---P-
VB-P---2F-NA---I-
VB-P---2F-NA---P-
VB-P---2P-AA---I-
VB-P---2P-AA---P-
VB-P---2P-NA---I-
VB-P---2P-NA---P-
VB-P---3F-AA---I-
VB-P---3F-AA---P-
VB-P---3F-NA---I-
VB-P---3F-NA---P-
VB-P---3P-AA---I-
VB-P---3P-AA---P-
VB-P---3P-NA---I-
VB-P---3P-NA---P-
VB-S---1F-AA---I-
VB-S---1F-AA---P-
VB-S---1F-NA---I-
VB-S---1F-NA---P-
VB-S---1P-AA---I-
VB-S---1P-AA---P-
VB-S---1P-NA---I-
VB-S---1P-NA---P-
VB-S---2F-AA---I-
VB-S---2F-AA---P-
VB-S---2F-NA---I-
VB-S---2F-NA---P-
VB-S---2P-AA---I-
VB-S---2P-AA---P-
VB-S---2P-NA---I-
VB-S---2P-NA---P-
VB-S---3F-AA---I-
VB-S---3F-AA---P-
VB-S---3F-NA---I-
VB-S---3F-NA---P-
VB-S---3P-AA---I-
VB-S---3P-AA---P-
VB-S---3P-NA---I-
VB-S---3P-NA---P-
VeFD1-----A----I-
VeFD1-----A----P-
VeFD1-----N----I-
VeFD1-----N----P-
VeFP1-----A----I-
VeFP1-----A----P-
VeFP1-----N----I-
VeFP1-----N----P-
VeFS1-----A----I-
VeFS1-----A----P-
VeFS1-----N----I-
VeFS1-----N----P-
VeMD1-----A----I-
VeMD1-----A----P-
VeMD1-----N----I-
VeMD1-----N----P-
VeMP1-----A----I-
VeMP1-----A----P-
VeMP1-----N----I-
VeMP1-----N----P-
VeMS1-----A----I-
VeMS1-----A----P-
VeMS1-----N----I-
VeMS4-----A----I-
VeMS4-----A----P-
VeMS4-----N----I-
VeMS4-----N----P-
VeND1-----A----I-
VeND1-----A----P-
VeND1-----N----I-
VeND1-----N----P-
VeNP1-----A----I-
VeNP1-----A----P-
VeNP1-----N----I-
VeNP1-----N----P-
VeNS1-----A----I-
VeNS1-----A----P-
VeNS1-----N----I-
VeNS1-----N----P-
Vf--------A----I-
Vf--------A----P-
Vf--------N----I-
Vi-D---1--A----I-
Vi-D---2--A----I-
Vi-D---3--A----I-
Vi-P---1--A----I-
Vi-P---1--A----P-
Vi-P---1--N----I-
Vi-P---2--A----I-
Vi-P---2--A----P-
Vi-P---2--N----I-
Vi-P---2--N----P-
Vi-P---3--A----I-
Vi-P---3--A----P-
Vi-P---3--N----I-
Vi-P---3--N----P-
Vi-S---2--A----I-
Vi-S---2--A----P-
Vi-S---2--N----I-
Vi-S---2--N----P-
Vi-S---3--A----I-
Vi-S---3--A----P-
Vi-S---3--N----I-
Vi-S---3--N----P-
VmFD------A----I-
VmFD------A----P-
VmFP------A----I-
VmFP------A----P-
VmFS------A----P-
VmMD------A----I-
VmMD------A----P-
VmMP------A----I-
VmMP------A----P-
VmMS------A----I-
VmMS------A----P-
VmND------A----I-
VmND------A----P-
VmNP------A----I-
VmNP------A----P-
VmNS------A----I-
VmNS------A----P-
VpFD----R-AA---P-
VpFP----R-AA---I-
VpFP----R-AA---P-
VpFP----R-NA---P-
VpFS----R-AA---I-
VpFS----R-AA---P-
VpFS----R-NA---I-
VpFS----R-NA---P-
VpMD----R-AA---I-
VpMD----R-AA---P-
VpMD----R-NA---I-
VpMD----R-NA---P-
VpMP----R-AA---I-
VpMP----R-AA---P-
VpMP----R-NA---I-
VpMP----R-NA---P-
VpMS----R-AA---I-
VpMS----R-AA---P-
VpMS----R-NA---I-
VpMS----R-NA---P-
VpND----R-AA---P-
VpNP----R-AA---I-
VpNP----R-AA---P-
VpNP----R-NA---I-
VpNP----R-NA---P-
VpNS----R-AA---I-
VpNS----R-AA---P-
VpNS----R-NA---I-
VpNS----R-NA---P-
VsFD1-----AP---I-
VsFD1-----AP---P-
VsFD4-----AP---I-
VsFD4-----AP---P-
VsFP1-----AP---I-
VsFP1-----AP---P-
VsFP4-----AP---I-
VsFP4-----AP---P-
VsFS1-----AP---I-
VsFS1-----AP---P-
VsFS2-----AP---I-
VsFS2-----AP---P-
VsFS4-----AP---I-
VsFS4-----AP---P-
VsMD1-----AP---I-
VsMD1-----AP---P-
VsMD4-----AP---I-
VsMD4-----AP---P-
VsMP1-----AP---I-
VsMP1-----AP---P-
VsMP1-----NP---I-
VsMP1-----NP---P-
VsMP4-----AP---I-
VsMP4-----AP---P-
VsMS1-----AP---I-
VsMS1-----AP---P-
VsMS1-----NP---P-
VsMS2-----AP---I-
VsMS2-----AP---P-
VsMS3-----AP---I-
VsMS3-----AP---P-
VsMS4-----AP---I-
VsMS4-----AP---P-
VsMS4-----NP---P-
VsND1-----AP---I-
VsND1-----AP---P-
VsND4-----AP---I-
VsND4-----AP---P-
VsNP1-----AP---I-
VsNP1-----AP---P-
VsNP4-----AP---I-
VsNP4-----AP---P-
VsNS1-----AP---I-
VsNS1-----AP---P-
VsNS2-----AP---I-
VsNS2-----AP---P-
VsNS3-----AP---I-
VsNS3-----AP---P-
VsNS4-----AP---I-
VsNS4-----AP---P-
Z:---------------
end_of_list
    ;
    # Protect from editors that replace tabs by spaces.
    $list =~ s/ \s+/\t/sg;
    my @list = split(/\r?\n/, $list);
    pop(@list) if($list[$#list] eq "");
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::CS::Ridics - Driver for the tagset of the Prague Dependency Treebank Consolidated.

=head1 VERSION

version 3.016

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::cs::ridics;
  my $driver = Lingua::Interset::Tagset::cs::ridics->new();
  my $fs = $driver->decode('NNMS1-----A----');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('cs::ridics', 'NNMS1-----A----');

=head1 DESCRIPTION

Interset driver for the Prague-derived part-of-speech tagset used by the
Research Infrastructure for Diachronic Czech Studies (RIDICS, Výzkumná
infrastruktura pro diachronní bohemistiku, https://vokabular.ujc.cas.cz/).
It is a positional tagset similar to PDT and PDT-C, but it has some extra
positions and values that are needed in old Czech texts.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
