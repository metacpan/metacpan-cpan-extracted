# ABSTRACT: Driver for the tagset of the Prague Dependency Treebank Consolidated.
# Copyright © 2006-2009, 2014, 2016, 2021 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::CS::Pdtc;
use strict;
use warnings;
our $VERSION = '3.015';

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
    return 'cs::pdtc';
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
            # finite verb, present or future indicative
            # examples: nesu beru mažu půjdu
            'VB' => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres'], # tense may be later overwritten by 'fut'
            # finite verb, present or future indicative with encliticized 'neboť'
            # examples: dělámť děláť
            'Vt' => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres', 'voice' => 'act', 'verbtype' => 'verbconj'],
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
            # vocalized preposition
            # examples: ve pode ke ku
            'RV' => ['pos' => 'adp', 'adpostype' => 'voc'],
            # first part of compound preposition
            # examples: nehledě na, vzhledem k
            'RF' => ['pos' => 'adp', 'adpostype' => 'comprep'],
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
            # interjection
            # examples: haf bum bác
            'II' => ['pos' => 'int'],
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
            'R' => ['tense' => 'past'],
            'H' => ['tense' => 'past|pres'],
            'P' => ['tense' => 'pres'],
            'F' => ['tense' => 'fut'],
        },
        'encode_map' =>

            # Do not encode tense of verbal adjectives and transgressives. Otherwise encode(decode(x)) will not equal to x.
            { 'pos' => { 'adj' => '',
                         '@'   => { 'verbform' => { 'conv' => '',
                                    '@'     => { 'tense' => { 'past|pres' => 'H',
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
    $fs->set_tagset('cs::pdtc');
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
    $atoms->{aspect}->decode_and_merge_hard($chars[12], $fs);
    $atoms->{aggregate}->decode_and_merge_hard($chars[13], $fs);
    $atoms->{variant}->decode_and_merge_hard($chars[14], $fs);
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
        $tag = 'F%-------------';
    }
    # Numerals and pronouns must come first because they can be at the same time also nouns or adjectives.
    elsif($fs->is_numeral())
    {
        if($fs->numform() eq 'digit')
        {
            $tag = 'C=-------------';
        }
        elsif($fs->numform() eq 'roman')
        { #{
            $tag = 'C}-------------';
        }
        elsif($fs->numtype() eq 'card')
        {
            if($fs->is_wh())
            {
                # kolik
                $tag = 'C?-------------';
            }
            elsif($fs->contains('prontype', 'ind') || $fs->contains('prontype', 'dem'))
            {
                # několik, mnoho, málo, tolik
                $tag = 'Ca--X----------';
            }
            # certain "generic" numerals (druhové číslovky) are classified as cardinals
            elsif($fs->get_other_subfeature('cs::pdtc', 'numtype') eq 'generic')
            {
                # čtvero, patero, desatero
                $tag = 'Cj-------------';
            }
            elsif(scalar(grep {m/^[123]$/} ($fs->get_list('numvalue')))>=1)
            {
                # jeden, jedna, jedno, dva, dvě, tři, čtyři
                $tag = 'Cl-XX----------';
            }
            else
            {
                # pět, deset, patnáct, devadesát, sto
                $tag = 'CnXXX----------';
            }
        }
        elsif($fs->numtype() eq 'ord')
        {
            if($fs->is_wh())
            {
                # kolikátý
                $tag = 'CzXXX----------';
            }
            elsif($fs->contains('prontype', 'ind') || $fs->contains('prontype', 'dem'))
            {
                # několikátý, mnohý, tolikátý
                # but also: nejeden
                $tag = 'CwXXX----------';
            }
            elsif($fs->get_other_subfeature('cs::pdtc', 'numtype') eq 'suffix' ||
               $fs->gender() eq '' && $fs->number() ne '')
            {
                # tých
                $tag = 'Ck-XX----------';
            }
            else
            {
                $tag = 'CrXXX----------';
            }
        }
        elsif($fs->numtype() eq 'mult')
        {
            if($fs->is_wh())
            {
                # kolikrát
                $tag = 'Cu-------------';
            }
            elsif($fs->contains('prontype', 'ind') || $fs->contains('prontype', 'dem'))
            {
                # několikrát, mnohokrát, tolikrát
                $tag = 'Co-------------';
            }
            else
            {
                $tag = 'Cv-------------'; ###!!! pozor tohle jsou i řadové číslovky příslovečné (poprvé, podruhé...)
            }
        }
        elsif($fs->numtype() eq 'frac')
        {
            $tag = 'Cy-------------';
        }
        elsif($fs->numtype() eq 'sets' && $fs->contains('prontype', 'ind'))
        {
            # několikerý
            $tag = 'Ch-------------';
            # "nejedny" is indefinite numeral and has its own tag 'Cw'.
            # "oboje", "dvoje", "troje" (and "čtvery", "patery", "desatery"?) are included in "Cd", together with "obojí", "dvojí", "trojí".
        }
        else
        {
            # obojí, dvojí, trojí (both-fold, twofold, three-fold)
            # oboje, dvoje, troje (both sets of, two sets of, three sets of)
            # The latter are distinguished by variant=1.
            $tag = 'CdX------------';
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
                    $tag = 'P1XXXX---------';
                }
                else
                {
                    $tag = 'P1XXX----------';
                }
            }
            elsif($fs->is_reflexive())
            {
                # svůj
                $tag = 'P8XXX----------';
            }
            else
            {
                # můj, tvůj, jeho, její, náš, váš, jejich
                # it has possgender if it is 3rd person
                if($fs->person() eq '3')
                {
                    $tag = 'P9XXXXX--------';
                }
                else
                {
                    $tag = 'PSXXX-X--------';
                }
            }
        }
        # personal pronoun
        elsif($fs->adpostype() eq 'preppron')
        {
            $tag = 'P0-------------'; # oň, naň
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
                        $tag = 'P5XXX----------';
                    }
                    else
                    {
                        $tag = 'PH--X----------';
                    }
                }
                else
                {
                    # já, ty, on, ona, ono, my, vy, oni, ony
                    # it has gender if it is 3rd person
                    if($fs->person() eq '3')
                    {
                        $tag = 'PEXXX----------';
                    }
                    else
                    {
                        $tag = 'PP-XX----------';
                    }
                }
            }
            else # reflexive
            {
                if($fs->variant() eq 'short')
                {
                    # si, sis, se, ses
                    $tag = 'P7--X----------';
                }
                else
                {
                    # sebe, sobě, sebou
                    $tag = 'P6--X----------';
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
                $tag = 'PY--X----------';
            }
            else
            {
                # nijaký, ničí, žádný
                $tag = 'PWXXX----------';
            }
        }
        # demonstrative pronoun
        elsif($fs->prontype() eq 'dem')
        {
            # ten, tento, tenhle, onen, takový, týž, tentýž
            $tag = 'PDXXX----------';
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
                $tag = 'PQ--X----------';
            }
            else
            {
                # jaký, který, čí, jenž
                $tag = 'P4XXX----------';
            }
        }
        # totality (collective) pronoun
        elsif($fs->prontype() eq 'tot')
        {
            # it has gender and number if it is plural or if it does not have case
            if($fs->is_plural() || $fs->case() eq '')
            {
                $tag = 'PLXXX----------';
            }
            else
            {
                $tag = 'PL--X----------';
            }
        }
        # indefinite pronoun
        elsif($fs->is_noun())
        {
            $tag = 'PK--X----------';
        }
        else
        {
            $tag = 'PZXXX----------';
        }
    }
    elsif($fs->is_noun())
    {
        if($fs->tagset() eq 'cs::pdtc' && $fs->other() eq 'letter')
        {
            $tag = 'Q3-------------';
        }
        elsif($fs->is_abbreviation() && $fs->variant() !~ m/^[abc]$/)
        {
            # We have to set the default 'A' here for the case that 'Q3' is stored without other=letter.
            $tag = 'BNXXX-----A----';
        }
        elsif($fs->tagset() eq 'cs::pdtc' && $fs->other() eq 'postfix')
        {
            $tag = 'SNXXX----------';
        }
        else
        {
            $tag = 'NNXXX----------';
        }
    }
    elsif($fs->is_adjective())
    {
        if($fs->is_abbreviation() && $fs->variant() !~ m/^[abc]$/)
        {
            $tag = 'BAXXX----------';
        }
        elsif($fs->tagset() eq 'cs::pdtc' && $fs->other() eq 'postfix')
        {
            $tag = 'SAXXX----------';
        }
        elsif($fs->variant() eq 'short')
        {
            $tag = 'ACXX-----------';
        }
        elsif($fs->is_possessive())
        {
            $tag = 'AUXXX----------';
        }
        elsif($fs->is_participle() && $fs->is_past())
        {
            $tag = 'AMXXX----------';
        }
        elsif($fs->is_participle())
        {
            $tag = 'AGXXX----------';
        }
        elsif($fs->is_hyph())
        {
            $tag = 'S2-------------';
        }
        elsif($fs->get_other_for_tagset('cs::pdtc') eq 'O' ||
              $fs->case() eq '' && $fs->polarity() eq '')
        {
            $tag = 'AOXX-----------';
        }
        else
        {
            $tag = 'AAXXX----------';
        }
    }
    elsif($fs->is_verb())
    {
        if($fs->is_infinitive())
        {
            $tag = 'Vf-------------';
        }
        elsif($fs->is_participle())
        {
            if($fs->voice() eq 'pass')
            {
                $tag = 'VsXX----X------';
            }
            elsif($fs->verbtype() eq 'verbconj')
            {
                $tag = 'VqXX---XX------';
            }
            else # default is active past/conditional participle
            {
                $tag = 'VpXX----X------';
            }
        }
        elsif($fs->is_transgressive())
        {
            if($fs->tense() eq 'past')
            {
                $tag = 'VmX------------';
            }
            else # default is present transgressive
            {
                $tag = 'VeX------------';
            }
        }
        else # default is finite verb
        {
            if($fs->mood() eq 'imp')
            {
                $tag = 'Vi-X---X-------';
            }
            elsif($fs->mood() =~ m/^(cnd|sub)$/)
            {
                $tag = 'Vc-------------';
            }
            else # indicative
            {
                if($fs->verbtype() eq 'verbconj')
                {
                    $tag = 'Vt-X---XX------';
                }
                else
                {
                    $tag = 'VB-X---XX------';
                }
            }
        }
    }
    elsif($fs->is_adverb())
    {
        if($fs->is_abbreviation() && $fs->variant() !~ m/^[abc]$/)
        {
            $tag = 'Bb-------------';
        }
        elsif($fs->tagset() eq 'cs::pdtc' && $fs->other() eq 'postfix')
        {
            $tag = 'Sb-------------';
        }
        elsif($fs->degree() ne '')
        {
            $tag = 'Dg-------------';
        }
        else
        {
            $tag = 'Db-------------';
        }
    }
    elsif($fs->is_adposition())
    {
        if($fs->adpostype() eq 'comprep')
        {
            $tag = 'RF-------------';
        }
        elsif($fs->adpostype() eq 'voc')
        {
            $tag = 'RV--X----------';
        }
        else
        {
            $tag = 'RR--X----------';
        }
    }
    elsif($fs->is_conjunction())
    {
        if($fs->is_subordinator())
        {
            # it has number if it has (3rd) person
            if($fs->person() eq '3')
            {
                $tag = 'J,-X-----------';
            }
            else
            {
                $tag = 'J,-------------';
            }
        }
        elsif($fs->conjtype() eq 'oper')
        {
            $tag = 'J*-------------';
        }
        elsif($fs->is_abbreviation() && $fs->variant() !~ m/^[abc]$/)
        {
            $tag = 'B^-------------';
        }
        else # default is coordinating conjunction
        {
            $tag = 'J^-------------';
        }
    }
    elsif($fs->is_particle())
    {
        $tag = 'TT-------------';
    }
    elsif($fs->is_interjection())
    {
        $tag = 'II-------------';
    }
    elsif($fs->is_punctuation())
    {
        if($fs->punctype() eq 'root')
        {
            $tag = 'Z#-------------';
        }
        else
        {
            $tag = 'Z:-------------';
        }
    }
    else # default is unknown tag
    {
        my $other = $fs->get_other_for_tagset('cs::pdtc');
        # Unknown abbreviation can be encoded either as 'XX------------8' or as 'Xx-------------' but not as 'Xx------------8'.
        if($fs->variant() eq '8')
        {
            $tag = 'XX-------------';
        }
        elsif($other =~ m/^[-X\@]$/)
        {
            $tag = 'X'.$other.'-------------';
        }
        elsif($fs->is_abbreviation())
        {
            $tag = 'Xx-------------';
        }
        else
        {
            $tag = 'X@-------------';
        }
    }
    # Now encode the features.
    # The PDT tagset distinguishes unknown values ("X") and irrelevant features ("-").
    # Interset does not do this distinction but we have prepared the defaults for empty values above.
    my @tag = split(//, $tag);
    my @features = ('pos', 'subpos', 'gender', 'number', 'case', 'possgender', 'possnumber', 'person', 'tense', 'degree', 'polarity', 'voice', 'aspect', 'aggregate', 'variant');
    my $atoms = $self->atoms();
    for(my $i = 2; $i<15; $i++)
    {
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
# Returns reference to list of known tags. The list was collected from the part
# of PDT-C that has tectogrammatical annotation.
# 1398
# Z nich jsem kvůli konzistenci vyhodil: 6
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
AAFD7----1A----
AAFP1----1A----
AAFP1----1A---6
AAFP1----1N----
AAFP1----2A----
AAFP1----2A---1
AAFP1----3A----
AAFP2----1A----
AAFP2----1N----
AAFP2----2A----
AAFP2----3A----
AAFP2----3A---1
AAFP2----3N----
AAFP3----1A----
AAFP3----1N----
AAFP3----2A----
AAFP3----3A----
AAFP4----1A----
AAFP4----1A---6
AAFP4----1N----
AAFP4----2A----
AAFP4----2A---1
AAFP4----3A----
AAFP4----3N----
AAFP6----1A----
AAFP6----1N----
AAFP6----2A----
AAFP6----2A---1
AAFP6----3A----
AAFP7----1A----
AAFP7----1N----
AAFP7----2A----
AAFP7----2A---1
AAFP7----3A----
AAFS1----1A----
AAFS1----1N----
AAFS1----2A----
AAFS1----3A----
AAFS2----1A----
AAFS2----1N----
AAFS2----2A----
AAFS2----2A---1
AAFS2----3A----
AAFS3----1A----
AAFS3----1N----
AAFS3----2A----
AAFS3----3A----
AAFS4----1A----
AAFS4----1N----
AAFS4----2A----
AAFS4----2A---1
AAFS4----3A----
AAFS4----3N----
AAFS5----1A----
AAFS5----1N----
AAFS6----1A----
AAFS6----1N----
AAFS6----2A----
AAFS6----3A----
AAFS6----3A---1
AAFS7----1A----
AAFS7----1N----
AAFS7----2A----
AAFS7----2N----
AAFS7----3A----
AAFS7----3N----
AAIP1----1A----
AAIP1----1N----
AAIP1----2A----
AAIP1----2A---1
AAIP1----2N----
AAIP1----3A----
AAIP2----1A----
AAIP2----1A---6
AAIP2----1N----
AAIP2----2A----
AAIP2----3A----
AAIP2----3N----
AAIP3----1A----
AAIP3----1N----
AAIP3----2A----
AAIP3----3A----
AAIP4----1A----
AAIP4----1A---6
AAIP4----1N----
AAIP4----2A----
AAIP4----2A---1
AAIP4----2N----
AAIP4----3A----
AAIP6----1A----
AAIP6----1N----
AAIP6----2A----
AAIP6----3A----
AAIP7----1A----
AAIP7----1N----
AAIP7----2A----
AAIP7----3A----
AAIS1----1A----
AAIS1----1A---6
AAIS1----1N----
AAIS1----2A----
AAIS1----2A---1
AAIS1----2N----
AAIS1----3A----
AAIS2----1A----
AAIS2----1N----
AAIS2----2A----
AAIS2----3A----
AAIS3----1A----
AAIS3----1N----
AAIS3----2A----
AAIS3----3A----
AAIS4----1A----
AAIS4----1N----
AAIS4----2A----
AAIS4----2A---1
AAIS4----3A----
AAIS4----3A---1
AAIS4----3N----
AAIS5----1A----
AAIS6----1A----
AAIS6----1N----
AAIS6----2A----
AAIS6----2A---1
AAIS6----3A----
AAIS7----1A----
AAIS7----1N----
AAIS7----2A----
AAIS7----3A----
AAIS7----3A---1
AAMP1----1A----
AAMP1----1A---9
AAMP1----1N----
AAMP1----2A----
AAMP1----2N----
AAMP1----3A----
AAMP1----3A---1
AAMP1----3N----
AAMP2----1A----
AAMP2----1N----
AAMP2----2A----
AAMP2----3A----
AAMP2----3A---1
AAMP3----1A----
AAMP3----1N----
AAMP3----2A----
AAMP3----3A----
AAMP4----1A----
AAMP4----1N----
AAMP4----2A----
AAMP4----3A----
AAMP5----1A----
AAMP6----1A----
AAMP6----1N----
AAMP7----1A----
AAMP7----1N----
AAMP7----2A----
AAMP7----3A----
AAMS1----1A----
AAMS1----1A---6
AAMS1----1N----
AAMS1----2A----
AAMS1----2A---1
AAMS1----3A----
AAMS2----1A----
AAMS2----1N----
AAMS2----2A----
AAMS2----3A----
AAMS3----1A----
AAMS3----1N----
AAMS3----2A----
AAMS3----3A----
AAMS4----1A----
AAMS4----1N----
AAMS4----2A----
AAMS4----3A----
AAMS5----1A----
AAMS5----1A---6
AAMS6----1A----
AAMS6----1N----
AAMS6----2A----
AAMS7----1A----
AAMS7----1N----
AAMS7----2A----
AAMS7----3A----
AANP1----1A----
AANP1----1A---6
AANP1----1N----
AANP1----2A----
AANP1----3A----
AANP2----1A----
AANP2----1N----
AANP2----2A----
AANP2----3A----
AANP2----3N----
AANP3----1A----
AANP3----1N----
AANP3----2A----
AANP3----3A----
AANP3----3A---1
AANP4----1A----
AANP4----1N----
AANP4----2A----
AANP4----3A----
AANP4----3N----
AANP6----1A----
AANP6----1N----
AANP6----2A----
AANP6----3A----
AANP7----1A----
AANP7----1N----
AANP7----2A----
AANP7----3A----
AANS1----1A----
AANS1----1A---6
AANS1----1N----
AANS1----1N---6
AANS1----2A----
AANS1----2A---1
AANS1----2N----
AANS1----3A----
AANS2----1A----
AANS2----1A---6
AANS2----1N----
AANS2----2A----
AANS2----3A----
AANS3----1A----
AANS3----1N----
AANS3----2A----
AANS3----3A----
AANS4----1A----
AANS4----1A---6
AANS4----1A---b
AANS4----1N----
AANS4----1N---6
AANS4----2A----
AANS4----3A----
AANS6----1A----
AANS6----1N----
AANS6----2A----
AANS6----3A----
AANS7----1A----
AANS7----1A---b
AANS7----1N----
AANS7----2A----
AANS7----3A----
AAXXX----1A----
AAXXX----1A---a
AAXXX----1A---b
AAXXX----2A---b
ACMP------A----
ACMP------N----
ACNS------A----
ACNS------N----
ACQW------A----
ACQW------N----
ACTP------A----
ACYS------A----
ACYS------N----
AGFD7-----A----
AGFP1-----A----
AGFP1-----N----
AGFP2-----A----
AGFP2-----N----
AGFP3-----A----
AGFP4-----A----
AGFP6-----A----
AGFP6-----N----
AGFP7-----A----
AGFP7-----N----
AGFS1-----A----
AGFS1-----N----
AGFS2-----A----
AGFS2-----N----
AGFS3-----A----
AGFS3-----N----
AGFS4-----A----
AGFS4-----N----
AGFS6-----A----
AGFS6-----N----
AGFS7-----A----
AGFS7-----N----
AGIP1-----A----
AGIP1-----N----
AGIP2-----A----
AGIP2-----N----
AGIP3-----A----
AGIP4-----A----
AGIP4-----N----
AGIP6-----A----
AGIP7-----A----
AGIS1-----A----
AGIS1-----N----
AGIS2-----A----
AGIS3-----A----
AGIS4-----A----
AGIS4-----N----
AGIS6-----A----
AGIS7-----A----
AGIS7-----N----
AGMP1-----A----
AGMP1-----N----
AGMP2-----A----
AGMP2-----N----
AGMP3-----A----
AGMP3-----N----
AGMP4-----A----
AGMP4-----N----
AGMP6-----A----
AGMP7-----A----
AGMS1-----A----
AGMS2-----A----
AGMS3-----A----
AGMS3-----N----
AGMS4-----A----
AGMS4-----N----
AGMS6-----A----
AGMS7-----A----
AGNP1-----A----
AGNP1-----N----
AGNP2-----A----
AGNP3-----A----
AGNP4-----A----
AGNP6-----A----
AGNP7-----A----
AGNS1-----A----
AGNS1-----N----
AGNS2-----A----
AGNS2-----N----
AGNS3-----A----
AGNS4-----A----
AGNS6-----A----
AGNS6-----N----
AGNS7-----A----
AMFS6-----A----
AMIS2-----A----
AMMP4-----A----
AMMP6-----A----
AMMS1-----A----
AMMS2-----A----
AMMS4-----A----
AMNS2-----A----
AOFP-----------
AOYS-----------
AUFP1F---------
AUFP1M---------
AUFP2F---------
AUFP2M---------
AUFP3M---------
AUFP4F---------
AUFP4M---------
AUFP6M---------
AUFP7M---------
AUFS1F---------
AUFS1M---------
AUFS2F---------
AUFS2M---------
AUFS3M---------
AUFS4F---------
AUFS4M---------
AUFS6M---------
AUFS7F---------
AUFS7M---------
AUIP1F---------
AUIP1M---------
AUIP2M---------
AUIP3M---------
AUIP4M---------
AUIP6M---------
AUIP7F---------
AUIP7M---------
AUIS1F---------
AUIS1M---------
AUIS2F---------
AUIS2M---------
AUIS3M---------
AUIS3M--------6
AUIS4F---------
AUIS4M---------
AUIS6M---------
AUIS7M---------
AUMP1M---------
AUMP2M---------
AUMP3M---------
AUMP4M---------
AUMP4M--------9
AUMP6M---------
AUMP7M---------
AUMS1M---------
AUMS2M---------
AUMS3M---------
AUMS3M--------6
AUMS4F---------
AUMS4M---------
AUMS6M---------
AUMS7M---------
AUNP1M---------
AUNP2M---------
AUNP3M---------
AUNP4M---------
AUNP6M---------
AUNP7M---------
AUNS1M---------
AUNS2F---------
AUNS2M---------
AUNS3M---------
AUNS3M--------6
AUNS4M---------
AUNS6M---------
AUNS7M---------
AUXXXM---------
AUXXXM--------5
BAXXX----1A----
BNFXX-----A----
BNNXX-----A----
BNXXX-----A----
B^-------------
Bb-------------
C=-------------
Ca--1----------
Ca--2----------
Ca--2---------1
Ca--3----------
Ca--4----------
Ca--6----------
Ca--7----------
Ca--X----------
CdFP1----------
CdFP4----------
CdFS2----------
CdFS4----------
CdMP1----------
CdNS1---------1
CdNS2----------
CdNS4----------
CdNS6----------
CdNS7----------
CdXP1----------
CdXP2----------
CdXP3----------
CdXP4----------
CdXP4---------1
CdXP6----------
CdXS1----------
CdYP4----------
CdYS7----------
ChIS2----------
CjNS1----------
Cl-D7----------
Cl-P1----------
Cl-P2----------
Cl-P2---------1
Cl-P3----------
Cl-P4----------
Cl-P6----------
Cl-P7----------
Cl-S1----------
Cl-S4----------
Cl-XX----------
CnFD7----------
CnFS1----------
CnFS2----------
CnFS3----------
CnFS4----------
CnFS6----------
CnFS7----------
CnHP1----------
CnHP4----------
CnIS4----------
CnMS4----------
CnNS1----------
CnNS4----------
CnXP2----------
CnXP3----------
CnXP6----------
CnXP7----------
CnXXX----------
CnYP1----------
CnYP4----------
CnYS1----------
CnZS2----------
CnZS3----------
CnZS6----------
CnZS7----------
Co-------------
Co------------1
CrFP1----------
CrFP2----------
CrFP3----------
CrFP4----------
CrFP6----------
CrFP7----------
CrFS1----------
CrFS2----------
CrFS3----------
CrFS4----------
CrFS6----------
CrFS7----------
CrIP1----------
CrIP2----------
CrIP3----------
CrIP4----------
CrIP6----------
CrIP7----------
CrIS1----------
CrIS2----------
CrIS3----------
CrIS4----------
CrIS6----------
CrIS7----------
CrMP1----------
CrMP2----------
CrMP3----------
CrMP4----------
CrMP7----------
CrMS1----------
CrMS2----------
CrMS3----------
CrMS4----------
CrMS6----------
CrMS7----------
CrNP1----------
CrNP2----------
CrNP3----------
CrNP4----------
CrNP6----------
CrNP7----------
CrNS1----------
CrNS2----------
CrNS3----------
CrNS4----------
CrNS6----------
CrNS7----------
Cv-------------
CwZS6----------
CyFS6----------
CyNS4----------
CyYS1----------
CyZS2----------
CyZS3----------
CzFP1----------
CzFP2----------
CzFP3----------
CzFP4----------
CzFP6----------
CzFP7----------
CzFS1----------
CzFS2----------
CzFS3----------
CzFS4----------
CzFS6----------
CzFS7----------
CzFXX----------
CzFXX---------b
CzIP1----------
CzIP2----------
CzIP3----------
CzIP4----------
CzIP6----------
CzIP7----------
CzIS1----------
CzIS2----------
CzIS3----------
CzIS4----------
CzIS6----------
CzIS7----------
CzIXX----------
CzIXX---------b
CzNP1----------
CzNP2----------
CzNP3----------
CzNP4----------
CzNP6----------
CzNP7----------
CzNS1----------
CzNS2----------
CzNS4----------
CzNS6----------
CzNXX----------
CzNXX---------2
C}-------------
Db-------------
Db------------2
Db------------b
Dg-------1A----
Dg-------1A---1
Dg-------1A---b
Dg-------1N----
Dg-------1N---1
Dg-------2A----
Dg-------2A---1
Dg-------2A---2
Dg-------2N----
Dg-------3A----
Dg-------3A---1
F%-------------
II-------------
J*-------------
J,-------------
J^-------------
NNFD7-----A----
NNFP1-----A----
NNFP1-----A---1
NNFP1-----A---3
NNFP1-----N----
NNFP2-----A----
NNFP2-----A---1
NNFP2-----N----
NNFP3-----A----
NNFP3-----A---1
NNFP4-----A----
NNFP4-----N----
NNFP6-----A----
NNFP6-----A---1
NNFP6-----A---6
NNFP7-----A----
NNFP7-----A---1
NNFP7-----A---6
NNFS1-----A----
NNFS1-----A---1
NNFS1-----N----
NNFS2-----A----
NNFS2-----A---1
NNFS2-----A---b
NNFS2-----N----
NNFS3-----A----
NNFS3-----A---1
NNFS3-----N----
NNFS4---------1
NNFS4-----A----
NNFS4-----A---1
NNFS4-----N----
NNFS5-----A----
NNFS6-----A----
NNFS6-----A---1
NNFS6-----N----
NNFS7-----A----
NNFS7-----A---1
NNFS7-----N----
NNFXX-----A----
NNFXX-----A---a
NNFXX-----A---b
NNIP1-----A----
NNIP1-----A---1
NNIP1-----A---2
NNIP1-----N----
NNIP2-----A----
NNIP2-----A---1
NNIP2-----A---8
NNIP3-----A----
NNIP4-----A----
NNIP4-----A---1
NNIP6-----A----
NNIP6-----A---1
NNIP6-----A---6
NNIP7-----A----
NNIS1-----A----
NNIS1-----A---1
NNIS2-----A----
NNIS2-----A---1
NNIS2-----A---2
NNIS3-----A----
NNIS3-----A---1
NNIS4-----A----
NNIS4-----A---1
NNIS5-----A----
NNIS5-----A---1
NNIS6-----A----
NNIS6-----A---1
NNIS6-----A---9
NNIS6-----N---1
NNIS7-----A----
NNIS7-----A---1
NNIS7-----A---3
NNIS7-----N----
NNIXX-----A----
NNIXX-----A---b
NNMP1-----A----
NNMP1-----A---1
NNMP1-----A---2
NNMP1-----A---6
NNMP2-----A----
NNMP2-----A---1
NNMP2-----A---3
NNMP3-----A----
NNMP3-----N----
NNMP4-----A----
NNMP4-----A---1
NNMP5-----A----
NNMP6-----A----
NNMP6-----A---1
NNMP6-----A---6
NNMP7-----A----
NNMP7-----A---6
NNMP7-----A---7
NNMP7-----N----
NNMS1-----A----
NNMS1-----A---1
NNMS1-----A---2
NNMS1-----A---5
NNMS1-----N----
NNMS2-----A----
NNMS2-----A---1
NNMS2-----A---2
NNMS2-----A---6
NNMS2-----A---9
NNMS2-----N----
NNMS3-----A----
NNMS3-----A---1
NNMS3-----A---2
NNMS3-----A---9
NNMS4-----A----
NNMS4-----A---1
NNMS4-----A---2
NNMS4-----A---6
NNMS4-----N----
NNMS5-----A----
NNMS6-----A----
NNMS6-----A---1
NNMS6-----A---2
NNMS6-----A---3
NNMS7-----A----
NNMS7-----A---1
NNMS7-----A---2
NNMXX-----A----
NNMXX-----A---8
NNMXX-----A---a
NNMXX-----A---b
NNNP1-----A----
NNNP1-----A---2
NNNP2-----A----
NNNP2-----A---1
NNNP2-----N----
NNNP3-----A----
NNNP3-----A---2
NNNP4-----A----
NNNP4-----A---1
NNNP4-----A---2
NNNP6-----A----
NNNP6-----A---1
NNNP6-----A---2
NNNP7-----A----
NNNP7-----A---1
NNNP7-----A---2
NNNS1-----A----
NNNS1-----N----
NNNS2-----A----
NNNS2-----A---1
NNNS2-----N----
NNNS3-----A----
NNNS3-----A---1
NNNS3-----N----
NNNS4-----A----
NNNS4-----N----
NNNS5-----A----
NNNS6-----A----
NNNS6-----A---1
NNNS6-----N----
NNNS7-----A----
NNNS7-----A---b
NNNS7-----N----
NNNXX-----A----
NNNXX-----A---1
NNNXX-----A---b
NNXXX-----A----
NNXXX-----A---b
P1FXXFS3-------
P1IS4FS3-------
P1NS4FS3-------
P1XP1FS3-------
P1XP3FS3-------
P1XP4FS3-------
P1XXXXP3-------
P1XXXZS3-------
P1ZS1FS3-------
P1ZS2FS3-------
P1ZS6FS3-------
P1ZS7FS3-------
P4FP1----------
P4FP4----------
P4FS1----------
P4FS2----------
P4FS2---------1
P4FS3----------
P4FS3---------1
P4FS4----------
P4FS4---------1
P4FS6----------
P4FS7----------
P4FS7---------1
P4IP1----------
P4IS4----------
P4MP1----------
P4MS4----------
P4NP1----------
P4NP1---------6
P4NP4----------
P4NS1----------
P4NS1---------6
P4NS4----------
P4NS4---------1
P4XP2----------
P4XP2---------1
P4XP3----------
P4XP3---------1
P4XP4----------
P4XP4---------1
P4XP6----------
P4XP7----------
P4XP7---------1
P4XXX----------
P4YP4----------
P4YS1----------
P4ZS2----------
P4ZS2---------2
P4ZS2---------3
P4ZS3----------
P4ZS3---------1
P4ZS4---------1
P4ZS4---------2
P4ZS4---------3
P4ZS6----------
P4ZS7----------
P4ZS7---------1
P5ZS2--3-------
P5ZS3--3-------
P5ZS4--3-------
P6--2----------
P6--3----------
P6--4----------
P6--6----------
P6--7----------
P7--3----------
P7--4----------
P8FP4---------1
P8FS2---------1
P8FS3---------1
P8FS4----------
P8FS4---------1
P8FS4---------6
P8FS6---------1
P8FS7----------
P8FS7---------1
P8IS4----------
P8MP1----------
P8MS4----------
P8NP4---------1
P8NS4----------
P8NS4---------1
P8XP2----------
P8XP3----------
P8XP4----------
P8XP6----------
P8XP7----------
P8YP4---------1
P8ZS2----------
P8ZS3----------
P8ZS3---------6
P8ZS6----------
P8ZS7----------
P9FD7FS3-------
P9FXXFS3-------
P9IS4FS3-------
P9MS4FS3-------
P9NS4FS3-------
P9XP1FS3-------
P9XP2FS3-------
P9XP3FS3-------
P9XP4FS3-------
P9XP6FS3-------
P9XP7FS3-------
P9XXXXP3-------
P9XXXZS3-------
P9ZS1FS3-------
P9ZS2FS3-------
P9ZS3FS3-------
P9ZS6FS3-------
P9ZS7FS3-------
PDFP1----------
PDFP4----------
PDFS1----------
PDFS2----------
PDFS3----------
PDFS4----------
PDFS6----------
PDFS7----------
PDIP1----------
PDIP4----------
PDIS4----------
PDMP1----------
PDMP1---------1
PDMP4----------
PDMS4----------
PDNP1----------
PDNP1---------6
PDNP4----------
PDNS1----------
PDNS4----------
PDXP2----------
PDXP2---------1
PDXP3----------
PDXP6----------
PDXP6---------1
PDXP7----------
PDXXX---------b
PDYS1----------
PDZS2----------
PDZS2---------6
PDZS3----------
PDZS6----------
PDZS7----------
PEFP1--3-------
PEFS1--3-------
PEFS2--3-------
PEFS2--3------1
PEFS3--3-------
PEFS3--3------1
PEFS4--3-------
PEFS4--3------1
PEFS4--3------6
PEFS4--3------7
PEFS6--3-------
PEFS7--3-------
PEFS7--3------1
PEIP1--3-------
PEMP1--3-------
PENS1--3-------
PENS4--3-------
PENS4--3------1
PEXP2--3-------
PEXP2--3------1
PEXP3--3-------
PEXP3--3------1
PEXP4--3-------
PEXP4--3------1
PEXP6--3-------
PEXP7--3-------
PEXP7--3------1
PEYS1--3-------
PEYS2--3-------
PEYS4--3-------
PEZS2--3-------
PEZS2--3------1
PEZS2--3------2
PEZS3--3-------
PEZS3--3------1
PEZS4--3-------
PEZS4--3------1
PEZS4--3------2
PEZS6--3-------
PEZS7--3-------
PEZS7--3------1
PH-S2--1-------
PH-S3--1-------
PH-S3--2-------
PH-S4--1-------
PH-S4--2-------
PK--1----------
PK--2----------
PK--3----------
PK--4----------
PK--6----------
PK--7----------
PKM-1----------
PLFP1----------
PLFP4----------
PLFS1----------
PLFS2----------
PLFS3----------
PLFS4----------
PLFS6----------
PLFS7----------
PLIP1----------
PLIS4----------
PLMP1----------
PLMS4----------
PLNP1----------
PLNP4----------
PLNS1----------
PLNS1---------1
PLNS4----------
PLNS4---------1
PLXP2----------
PLXP3----------
PLXP6----------
PLXP7----------
PLYP4----------
PLYS1----------
PLYS4----------
PLZS2----------
PLZS3----------
PLZS6----------
PLZS7----------
PP-P1--1-------
PP-P1--2-------
PP-P2--1-------
PP-P2--2-------
PP-P3--1-------
PP-P3--2-------
PP-P4--1-------
PP-P4--2-------
PP-P6--1-------
PP-P6--2-------
PP-P7--1-------
PP-P7--2-------
PP-S1--1-------
PP-S1--2-------
PP-S2--1-------
PP-S2--2-------
PP-S3--1-------
PP-S3--2-------
PP-S4--1-------
PP-S5--2-------
PP-S6--1-------
PP-S7--1-------
PQ--1----------
PQ--2----------
PQ--3----------
PQ--4----------
PQ--6----------
PQ--7----------
PSFP1-S1------1
PSFS1-S1------1
PSFS2-P1-------
PSFS2-P2-------
PSFS2-S1-------
PSFS2-S1------1
PSFS3-P1-------
PSFS3-P2-------
PSFS3-S1------1
PSFS4-P1-------
PSFS4-P1------6
PSFS4-P2-------
PSFS4-S1-------
PSFS4-S1------1
PSFS5-S1------1
PSFS6-P1-------
PSFS6-P2-------
PSFS6-S1------1
PSFS7-P1-------
PSFS7-P2-------
PSFS7-S1-------
PSFS7-S1------1
PSHP1-P1-------
PSHP1-P2-------
PSHP1-S1-------
PSHS1-P1-------
PSHS1-P2-------
PSHS1-S1-------
PSHS5-S1-------
PSIP1-P1-------
PSIP1-P2-------
PSIP1-S1-------
PSIP1-S1------1
PSIS4-P1-------
PSIS4-P2-------
PSIS4-S1-------
PSMP1-P1-------
PSMP1-P2-------
PSMP1-S1-------
PSMP1-S1------1
PSMS4-P1-------
PSMS4-P2-------
PSNS1-S1------1
PSNS4-P1-------
PSNS4-P2-------
PSNS4-S1------1
PSXP2-P1-------
PSXP2-P2-------
PSXP2-S1-------
PSXP3-P1-------
PSXP3-S1-------
PSXP4-P1-------
PSXP4-P2-------
PSXP6-P1-------
PSXP6-P2-------
PSXP6-S1-------
PSXP7-P1-------
PSXP7-P2-------
PSXP7-S1-------
PSYP4-S1------1
PSYS1-P1-------
PSYS1-P2-------
PSYS1-S1-------
PSYS5-S1-------
PSZS2-P1-------
PSZS2-P2-------
PSZS2-S1-------
PSZS3-P1-------
PSZS3-S1-------
PSZS6-P1-------
PSZS6-P2-------
PSZS6-S1-------
PSZS7-P1-------
PSZS7-P1------6
PSZS7-P2-------
PSZS7-S1-------
PWFP1----------
PWFP4----------
PWFS1----------
PWFS2----------
PWFS3----------
PWFS4----------
PWFS6----------
PWFS7----------
PWIP1----------
PWIS4----------
PWMP1----------
PWMS4----------
PWNP1----------
PWNP4----------
PWNS1----------
PWNS4----------
PWXP2----------
PWXP3----------
PWXP6----------
PWXP7----------
PWYP4----------
PWYS1----------
PWYS1---------6
PWZS2----------
PWZS3----------
PWZS6----------
PWZS7----------
PY--1----------
PY--2----------
PY--3----------
PY--4----------
PY--6----------
PY--7----------
PZFP1----------
PZFP4----------
PZFS1----------
PZFS2----------
PZFS3----------
PZFS4----------
PZFS6----------
PZFS7----------
PZIP1----------
PZIS4----------
PZMP1----------
PZMS4----------
PZNP1----------
PZNP4----------
PZNS1----------
PZNS4----------
PZXP2----------
PZXP3----------
PZXP6----------
PZXP7----------
PZYP4----------
PZYS1----------
PZYS1---------6
PZZS2----------
PZZS3----------
PZZS6----------
PZZS7----------
Q3-------------
RF-------------
RR--1----------
RR--1---------c
RR--2----------
RR--3----------
RR--4----------
RR--6----------
RR--7----------
RR--7---------b
RV--2----------
RV--3----------
RV--3---------1
RV--4----------
RV--4---------1
RV--6----------
RV--7----------
S2--------A----
S2--------N----
SAIS2----1A----
SAXXX----1A----
SNFS1-----A----
SNIS1-----A----
SNIS2-----A----
SNIS3-----A----
SNMS1-----A----
SNMS2-----A----
SNMS3-----A----
SNMS7-----A----
SNMXX-----A----
SNNS1-----A----
SNNXX-----A----
SNXXX-----A----
TT-------------
TT------------1
TT------------a
TT------------b
VB-P---1F-AAI--
VB-P---1F-AAI-6
VB-P---1F-NAI--
VB-P---1P-AAB--
VB-P---1P-AAI--
VB-P---1P-AAI-6
VB-P---1P-AAP--
VB-P---1P-AAP-1
VB-P---1P-NAB--
VB-P---1P-NAI--
VB-P---1P-NAI-6
VB-P---1P-NAP--
VB-P---2F-AAI--
VB-P---2F-NAI--
VB-P---2P-AAB--
VB-P---2P-AAI--
VB-P---2P-AAI-1
VB-P---2P-AAP--
VB-P---2P-NAI--
VB-P---2P-NAP--
VB-P---3F-AAI--
VB-P---3F-NAI--
VB-P---3P-AAB--
VB-P---3P-AAI--
VB-P---3P-AAI-1
VB-P---3P-AAI-2
VB-P---3P-AAI-3
VB-P---3P-AAI-6
VB-P---3P-AAP--
VB-P---3P-AAP-1
VB-P---3P-AAP-6
VB-P---3P-NAB--
VB-P---3P-NAI--
VB-P---3P-NAI-1
VB-P---3P-NAI-7
VB-P---3P-NAP--
VB-P---3P-NAP-1
VB-S---1F-AAI--
VB-S---1F-NAI--
VB-S---1P-AAB--
VB-S---1P-AAB-1
VB-S---1P-AAI--
VB-S---1P-AAI-1
VB-S---1P-AAP--
VB-S---1P-AAP-1
VB-S---1P-NAB-1
VB-S---1P-NAI--
VB-S---1P-NAI-1
VB-S---1P-NAP--
VB-S---1P-NAP-1
VB-S---2F-AAI--
VB-S---2F-NAI--
VB-S---2P-AAI--
VB-S---2P-AAI-8
VB-S---2P-AAP--
VB-S---2P-NAI--
VB-S---2P-NAP--
VB-S---3F-AAI--
VB-S---3F-NAI--
VB-S---3P-AAB--
VB-S---3P-AAI--
VB-S---3P-AAI-1
VB-S---3P-AAI-2
VB-S---3P-AAP--
VB-S---3P-AAP-1
VB-S---3P-AAP-6
VB-S---3P-NAB--
VB-S---3P-NAI--
VB-S---3P-NAI-5
VB-S---3P-NAP--
VB-S---3P-NAP-1
Vc----------I--
Vc----------Ic-
Vc----------Ic6
Vc----------Ie-
Vc----------Im-
Vc----------Im6
Vc----------Is-
VeHS------A-I--
VeHS------N-I--
VeXP------A-I--
VeXP------A-P-6
VeYS------A-I--
VeYS------N-I--
Vf--------A-B--
Vf--------A-I--
Vf--------A-I-1
Vf--------A-I-2
Vf--------A-P--
Vf--------A-P-1
Vf--------A-P-2
Vf--------A-P-6
Vf--------N-B--
Vf--------N-I--
Vf--------N-P--
Vf--------N-P-2
Vi-P---1--A-B--
Vi-P---1--A-I--
Vi-P---1--A-P--
Vi-P---1--A-P-1
Vi-P---1--N-I--
Vi-P---1--N-P--
Vi-P---1--N-P-1
Vi-P---2--A-I--
Vi-P---2--A-P--
Vi-P---2--A-P-1
Vi-P---2--A-P-6
Vi-P---2--N-I--
Vi-P---2--N-P--
Vi-P---2--N-P-1
Vi-S---2--A-I--
Vi-S---2--A-P--
Vi-S---2--A-P-1
Vi-S---2--A-P-b
Vi-S---2--N-I--
Vi-S---2--N-P--
Vi-S---3--A-I-2
Vi-S---3--A-I-4
VmYS------A-P--
VpMP----R-AAB--
VpMP----R-AAI--
VpMP----R-AAI-1
VpMP----R-AAP--
VpMP----R-AAP-1
VpMP----R-NAB--
VpMP----R-NAI--
VpMP----R-NAP--
VpMP----R-NAP-1
VpNS----R-AAB--
VpNS----R-AAI--
VpNS----R-AAI-1
VpNS----R-AAP--
VpNS----R-AAP-1
VpNS----R-NAI--
VpNS----R-NAP--
VpNS----R-NAP-1
VpQW----R-AAB--
VpQW----R-AAI--
VpQW----R-AAI-1
VpQW----R-AAP--
VpQW----R-AAP-1
VpQW----R-NAB--
VpQW----R-NAI--
VpQW----R-NAP--
VpQW----R-NAP-1
VpTP----R-AAB--
VpTP----R-AAI--
VpTP----R-AAI-1
VpTP----R-AAP--
VpTP----R-AAP-1
VpTP----R-NAB--
VpTP----R-NAI--
VpTP----R-NAP--
VpTP----R-NAP-1
VpYS----R-AAB--
VpYS----R-AAI--
VpYS----R-AAI-1
VpYS----R-AAP--
VpYS----R-AAP-1
VpYS----R-NAB--
VpYS----R-NAI--
VpYS----R-NAI-1
VpYS----R-NAP--
VpYS----R-NAP-1
VsFS4---X-APP--
VsMP----X-APB--
VsMP----X-API--
VsMP----X-APP--
VsMP----X-APP-1
VsMP----X-NPP--
VsNS----X-APB--
VsNS----X-API--
VsNS----X-API-1
VsNS----X-APP--
VsNS----X-APP-1
VsNS----X-APP-5
VsNS----X-NPP--
VsQW----X-APB--
VsQW----X-API--
VsQW----X-APP--
VsQW----X-APP-1
VsQW----X-NPP--
VsQW----X-NPP-1
VsTP----X-APB--
VsTP----X-API--
VsTP----X-APP--
VsTP----X-APP-1
VsTP----X-NPI--
VsTP----X-NPP--
VsTP----X-NPP-1
VsYS----X-APB--
VsYS----X-API--
VsYS----X-APP--
VsYS----X-APP-1
VsYS----X-NPI--
VsYS----X-NPP--
Vt-S---3P-NA--2
Z:-------------
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

Lingua::Interset::Tagset::CS::Pdtc - Driver for the tagset of the Prague Dependency Treebank Consolidated.

=head1 VERSION

version 3.015

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::CS::Pdtc;
  my $driver = Lingua::Interset::Tagset::CS::Pdtc->new();
  my $fs = $driver->decode('NNMS1-----A----');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('cs::pdtc', 'NNMS1-----A----');

=head1 DESCRIPTION

Interset driver for the part-of-speech tagset of the Prague Dependency Treebank Consolidated (PDT-C).

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
