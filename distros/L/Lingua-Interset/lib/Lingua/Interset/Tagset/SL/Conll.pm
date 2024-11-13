# ABSTRACT: Driver for the Slovene tagset of the CoNLL 2006 Shared Task (derived from the Slovene Dependency Treebank).
# Copyright © 2011, 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::SL::Conll;
use strict;
use warnings;
our $VERSION = '3.016';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset::Conll';



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'sl::conll';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # PART OF SPEECH ####################
    $atoms{pos} = $self->create_atom
    (
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # example: V-B
            'Abbreviation'              => ['abbr' => 'yes'],
            # Ordinal adjectives, unlike qualificative, cannot be graded. Interset currently does not provide for this distinction.
            # example qualificative: boljše, kasnejšimi, revnejših, pomembnejše, močnejšo
            'Adjective-qualificative'   => ['pos' => 'adj'],
            # example ordinal: mali, partijske, zunanjim, srednjih, azijskimi
            'Adjective-ordinal'         => ['pos' => 'adj', 'other' => {'adjtype' => 'ordinal'}],
            # example possessive: O'Brienovih, Časnikovih, nageljnovimi, dečkovih, starčeve
            'Adjective-possessive'      => ['pos' => 'adj', 'poss' => 'yes'],
            # example: nanj, v, proti
            'Adposition-preposition'    => ['pos' => 'adp', 'adpostype' => 'prep'],
            # example: več, hitro, najbolj
            'Adverb-general'            => ['pos' => 'adv'],
            # example: in, pa, ali, a
            'Conjunction-coordinating'  => ['pos' => 'conj', 'conjtype' => 'coor'],
            # example: da, ki, kot, ko, če
            'Conjunction-subordinating' => ['pos' => 'conj', 'conjtype' => 'sub'],
            # example: oh, pozor
            'Interjection'              => ['pos' => 'int'],
            # example: ploščici, sil, neznankama, stvari, prsi
            'Noun-common'               => ['pos' => 'noun', 'nountype' => 'com'],
            # example: Winston, Parsons, Syme, O'Brien, Goldstein
            'Noun-proper'               => ['pos' => 'noun', 'nountype' => 'prop'],
            # example cardinal: eno, dve, tri
            'Numeral-cardinal'          => ['pos' => 'num', 'numtype' => 'card'],
            # example multiple: dvojno
            'Numeral-multiple'          => ['pos' => 'adv', 'numtype' => 'mult'],
            # example ordinal: prvi, drugi, tretje, devetnajstega
            'Numeral-ordinal'           => ['pos' => 'adj', 'numtype' => 'ord'],
            # example special: dvoje, enkratnem
            'Numeral-special'           => ['pos' => 'num', 'numtype' => 'sets'],
            # example: , . " - ?
            'PUNC'                      => ['pos' => 'punc'],
            # example: ne, pa, še, že, le
            'Particle'                  => ['pos' => 'part'],
            # example demonstrative: take, tem, tistih, teh, takimi
            'Pronoun-demonstrative'     => ['pos' => 'noun|adj', 'prontype' => 'dem'],
            # example general: vsakdo, obe, vse, vsemi, vsakih
            'Pronoun-general'           => ['pos' => 'noun|adj', 'prontype' => 'tot'],
            # example indefinite: koga, nekoga, nekatere, druge, isti
            'Pronoun-indefinite'        => ['pos' => 'noun|adj', 'prontype' => 'ind'],
            # example interrogative: koga, česa, čem, kaj, koliko
            'Pronoun-interrogative'     => ['pos' => 'noun|adj', 'prontype' => 'int'],
            # example negative: nič, nikakršne, nobeni, nobenega, nobenem
            'Pronoun-negative'          => ['pos' => 'noun|adj', 'prontype' => 'neg'],
            # example personal: jaz, ti, on, ona, mi, vi, oni
            'Pronoun-personal'          => ['pos' => 'noun', 'prontype' => 'prs'],
            # example possessive: moj, tvoj, njegove, naše, vašo, njihove
            'Pronoun-possessive'        => ['pos' => 'adj', 'prontype' => 'prs', 'poss' => 'yes'],
            # example reflexive: sebe, se, sebi, si, seboj, svoj, svoja
            # Both reflexive and possessive reflexive pronouns are included in Pronoun-reflexive.
            # The possessive reflexives are recognized by Referent-Type=possessive.
            'Pronoun-reflexive'         => ['pos' => 'noun|adj', 'prontype' => 'prs', 'reflex' => 'yes'],
            # example relative: kar, česar, čimer, kdorkoli, katerih, kakršna, kolikor
            'Pronoun-relative'          => ['pos' => 'noun|adj', 'prontype' => 'rel'],
            # example copula: bi, bova, bomo, bom, boste, boš, bosta, bodo, bo, sva, smo, nismo, sem, nisem, ste, si, nisi, sta, nista, so, niso, je, ni, bili, bila, bile, bil, bilo
            'Verb-copula'               => ['pos' => 'verb', 'verbtype' => 'cop'],
            # example main: vzemiva, dajmo, krčite, bodi, greva
            'Verb-main'                 => ['pos' => 'verb'],
            # example modal: moremo, hočem, želiš, dovoljene, mogla
            'Verb-modal'                => ['pos' => 'verb', 'verbtype' => 'mod']
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'nountype' => { 'prop' => 'Noun-proper',
                                                   '@'    => { 'prontype' => { 'dem' => 'Pronoun-demonstrative',
                                                                               'tot' => 'Pronoun-general',
                                                                               'ind' => 'Pronoun-indefinite',
                                                                               'int' => 'Pronoun-interrogative',
                                                                               'neg' => 'Pronoun-negative',
                                                                               'prs' => { 'reflex' => { 'yes' => 'Pronoun-reflexive',
                                                                                                        '@'      => 'Pronoun-personal' }},
                                                                               'rel' => 'Pronoun-relative',
                                                                               '@'   => 'Noun-common' }}}},
                       'adj'  => { 'numtype' => { 'ord' => 'Numeral-ordinal',
                                                  '@'   => { 'prontype' => { 'dem' => 'Pronoun-demonstrative',
                                                                             'tot' => 'Pronoun-general',
                                                                             'ind' => 'Pronoun-indefinite',
                                                                             'int' => 'Pronoun-interrogative',
                                                                             'neg' => 'Pronoun-negative',
                                                                             'prs' => { 'reflex' => { 'yes' => 'Pronoun-reflexive',
                                                                                                      '@'      => 'Pronoun-possessive' }},
                                                                             'rel' => 'Pronoun-relative',
                                                                             '@'   => { 'poss' => { 'yes' => 'Adjective-possessive',
                                                                                                    '@'    => { 'other/adjtype' => { 'ordinal' => 'Adjective-ordinal',
                                                                                                                                     '@'       => 'Adjective-qualificative' }}}}}}}},
                       'num'  => { 'numtype' => { 'ord'  => 'Numeral-ordinal',
                                                  'mult' => 'Numeral-multiple',
                                                  'sets' => 'Numeral-special',
                                                  '@'    => 'Numeral-cardinal' }},
                       'verb' => { 'verbtype' => { 'cop' => 'Verb-copula',
                                                   'mod' => 'Verb-modal',
                                                   '@'   => 'Verb-main' }},
                       'adv'  => { 'numtype' => { 'mult' => 'Numeral-multiple',
                                                  '@'    => 'Adverb-general' }},
                       'adp'  => 'Adposition-preposition',
                       'conj' => { 'conjtype' => { 'sub' => 'Conjunction-subordinating',
                                                   '@'   => 'Conjunction-coordinating' }},
                       'part' => 'Particle',
                       'int'  => 'Interjection',
                       'punc' => 'PUNC',
                       'sym'  => 'PUNC',
                       '@'    => { 'abbr' => { 'yes' => 'Abbreviation' }}}
        }
    );
    # DEGREE OF COMPARISON ####################
    $atoms{Degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'positive'    => 'pos',
            'comparative' => 'cmp',
            'superlative' => 'sup'
        }
    );
    # GENDER ####################
    $atoms{Gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'masculine' => 'masc',
            'feminine'  => 'fem',
            'neuter'    => 'neut'
        }
    );
    # ANIMACY ####################
    $atoms{Animate} = $self->create_simple_atom
    (
        'intfeature' => 'animacy',
        'simple_decode_map' =>
        {
            'yes' => 'anim',
            'no'  => 'inan'
        }
    );
    # NUMBER ####################
    $atoms{Number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'singular' => 'sing',
            'dual'     => 'dual',
            'plural'   => 'plur'
        }
    );
    # CASE ####################
    $atoms{Case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'nominative'   => 'nom',
            'genitive'     => 'gen',
            'dative'       => 'dat',
            'accusative'   => 'acc',
            'locative'     => 'loc',
            'instrumental' => 'ins'
        }
    );
    # DEFINITENESS ####################
    # This feature is not the same as definiteness in Germanic and Romance languages.
    # It distinguishes two forms of some adjectives: the short form (nominal) from the long form (pronominal).
    # To maintain analogy with other Slavic languages, we decode it as the variant feature, not as definiteness.
    $atoms{Definiteness} = $self->create_simple_atom
    (
        'intfeature' => 'variant',
        'simple_decode_map' =>
        {
            # Definite = long form, also called pronominal.
            # stari, veliki, edini, miselni, poglavitni
            'yes' => 'long',
            # Indefinite = short form, also called nominal.
            # sam, star, preden, poln, živ
            'no'  => 'short'
        }
    );
    # FORMATION OF PREPOSITIONS ####################
    $atoms{Formation} = $self->create_simple_atom
    (
        'intfeature' => 'adpostype',
        'simple_decode_map' =>
        {
            'simple'   => 'prep',
            'compound' => 'comprep'
        }
    );
    # FORMAT OF NUMERALS ####################
    $atoms{Form} = $self->create_simple_atom
    (
        'intfeature' => 'numform',
        'simple_decode_map' =>
        {
            'digit'  => 'digit',
            'letter' => 'word'
        }
    );
    # SYNTACTIC TYPE ####################
    # Applies solely to pronouns.
    # nominal|adjectival
    $atoms{'Syntactic-Type'} = $self->create_simple_atom
    (
        'intfeature' => 'pos',
        'simple_decode_map' =>
        {
            'nominal'    => 'noun',
            'adjectival' => 'adj'
        }
    );
    # CLITIC ####################
    # no examples:  mene meni tebe njiju njih njo njej nje njega njemu sebe sebi
    # yes examples: me   mi   te   ju    jih  jo  ji   je  ga    mu    se   si
    # I am taking the same approach as in cs::pdt.
    # In future we may prefer to introduce a new 'clitic' feature in Interset.
    $atoms{Clitic} = $self->create_simple_atom
    (
        'intfeature' => 'variant',
        'simple_decode_map' =>
        {
            'yes' => 'short',
            'no'  => ''
        }
    );
    # POSSESSOR'S NUMBER ####################
    $atoms{'Owner-Number'} = $self->create_simple_atom
    (
        'intfeature' => 'possnumber',
        'simple_decode_map' =>
        {
            'singular' => 'sing',
            'dual'     => 'dual',
            'plural'   => 'plur'
        }
    );
    # POSSESSOR'S GENDER ####################
    $atoms{'Owner-Gender'} = $self->create_simple_atom
    (
        'intfeature' => 'possgender',
        'simple_decode_map' =>
        {
            'masculine' => 'masc',
            'feminine'  => 'fem',
            'neuter'    => 'neut'
        }
    );
    # REFERENT TYPE ####################
    # This feature is used to subclassify pronouns:
    # personal|possessive
    $atoms{'Referent-Type'} = $self->create_simple_atom
    (
        'intfeature' => 'poss',
        'simple_decode_map' =>
        {
            'personal'   => '',
            'possessive' => 'yes'
        }
    );
    # VERB FORM ####################
    $atoms{VForm} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            # biti, videti, vedeti, spomniti, reči
            'infinitive'  => ['verbform' => 'inf'],
            # ima, pomeni, govori, opazuje, obstaja
            'indicative'  => ['verbform' => 'fin', 'mood' => 'ind'],
            # pokaži, bodi, drži, prosi, zavračaj
            'imperative'  => ['verbform' => 'fin', 'mood' => 'imp'],
            # bi
            'conditional' => ['verbform' => 'fin', 'mood' => 'cnd'],
            # imel, vedel, rekel, videl, pomislil
            # prepričan, poročen, pomešan, opremljen, določen
            'participle'  => ['verbform' => 'part'],
            # gledat
            # (Si šel včeraj gledat obešanje ujetnikov?)
            'supine'      => ['verbform' => 'sup']
        },
        'encode_map' =>
        {
            'verbform' => { 'inf'  => 'infinitive',
                            'fin'  => { 'mood' => { 'ind' => 'indicative',
                                                    'imp' => 'imperative',
                                                    'cnd' => 'conditional' }},
                            'part' => 'participle',
                            'sup'  => 'supine' }
        }
    );
    # TENSE ####################
    $atoms{Tense} = $self->create_simple_atom
    (
        'intfeature' => 'tense',
        'simple_decode_map' =>
        {
            'past'    => 'past',
            'present' => 'pres',
            'future'  => 'fut'
        }
    );
    # PERSON ####################
    $atoms{Person} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            'first'  => '1',
            'second' => '2',
            'third'  => '3'
        }
    );
    # POLARITY ####################
    $atoms{Negative} = $self->create_simple_atom
    (
        'intfeature' => 'polarity',
        'simple_decode_map' =>
        {
            'yes' => 'neg',
            'no'  => 'pos'
        }
    );
    # VOICE ####################
    $atoms{Voice} = $self->create_simple_atom
    (
        'intfeature' => 'voice',
        'simple_decode_map' =>
        {
            'active'  => 'act',
            'passive' => 'pass'
        }
    );
    return \%atoms;
}



#------------------------------------------------------------------------------
# Creates the list of all surface CoNLL features that can appear in the FEATS
# column. This list will be used in decode().
#------------------------------------------------------------------------------
sub _create_features_all
{
    my $self = shift;
    my @features = ('Degree', 'Gender', 'Animate', 'Number', 'Case',
                    'Definiteness', 'Formation', 'Form', 'Syntactic-Type', 'Clitic', 'Owner-Number', 'Owner-Gender', 'Referent-Type',
                    'VForm', 'Tense', 'Person', 'Negative', 'Voice');
    return \@features;
}



#------------------------------------------------------------------------------
# Creates the list of surface CoNLL features that can appear in the FEATS
# column with particular parts of speech. This list will be used in encode().
#------------------------------------------------------------------------------
sub _create_features_pos
{
    my $self = shift;
    my %features =
    (
        'Adjective-ordinal' => ['Degree', 'Gender', 'Number', 'Case', 'Animate'],
        'Adjective-possessive' => ['Degree', 'Gender', 'Number', 'Case', 'Animate'],
        'Adjective-qualificative' => ['Degree', 'Gender', 'Number', 'Case', 'Definiteness', 'Animate'],
        'Adposition-preposition' => ['Formation', 'Case'],
        'Adverb-general' => ['Degree'],
        'Conjunction-coordinating' => ['Formation'],
        'Conjunction-subordinating' => ['Formation'],
        'Noun-common' => ['Gender', 'Number', 'Case', 'Animate'],
        'Noun-proper' => ['Gender', 'Number', 'Case', 'Animate'],
        'Numeral-cardinal' => ['Gender', 'Number', 'Case', 'Form', 'Animate'],
        'Numeral-multiple' => ['Gender', 'Number', 'Case', 'Form'],
        'Numeral-ordinal' => ['Gender', 'Number', 'Case', 'Form', 'Animate'],
        'Numeral-special' => ['Gender', 'Number', 'Case', 'Form'],
        'Pronoun-demonstrative' => ['Gender', 'Number', 'Case', 'Syntactic-Type', 'Animate'],
        'Pronoun-general' => ['Gender', 'Number', 'Case', 'Syntactic-Type', 'Animate'],
        'Pronoun-indefinite' => ['Gender', 'Number', 'Case', 'Syntactic-Type', 'Animate'],
        'Pronoun-interrogative' => ['Gender', 'Number', 'Case', 'Syntactic-Type', 'Animate'],
        'Pronoun-negative' => ['Gender', 'Number', 'Case', 'Syntactic-Type', 'Animate'],
        'Pronoun-personal' => ['Person', 'Gender', 'Number', 'Case', 'Clitic', 'Syntactic-Type'],
        'Pronoun-possessive' => ['Person', 'Gender', 'Number', 'Case', 'Owner-Number', 'Owner-Gender', 'Syntactic-Type', 'Animate'],
        'Pronoun-reflexive' => ['Gender', 'Number', 'Case', 'Clitic', 'Referent-Type', 'Syntactic-Type'],
        'Pronoun-reflexive0' => ['Clitic'],
        'Pronoun-possessive-reflexive' => ['Gender', 'Number', 'Case', 'Referent-Type', 'Syntactic-Type', 'Animate'],
        'Pronoun-relative' => ['Gender', 'Number', 'Case', 'Syntactic-Type', 'Animate'],
        'Verb-copula' => ['VForm', 'Tense', 'Person', 'Number', 'Gender', 'Voice', 'Negative'],
        'Verb-main' => ['VForm', 'Tense', 'Person', 'Number', 'Gender', 'Voice', 'Negative'],
        'Verb-modal' => ['VForm', 'Tense', 'Person', 'Number', 'Gender', 'Voice', 'Negative']
    );
    return \%features;
}



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    my $fs = $self->decode_conll($tag);
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
    my $subpos = $atoms->{pos}->encode($fs);
    my $pos = $subpos;
    $pos =~ s/-.*//;
    my $fpos = $subpos;
    if($fpos eq 'Pronoun-reflexive')
    {
        if($fs->is_possessive())
        {
            $fpos = 'Pronoun-possessive-reflexive';
        }
        elsif($fs->case() eq '')
        {
            $fpos = 'Pronoun-reflexive0';
        }
    }
    my $feature_names = $self->get_feature_names($fpos);
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names);
    # We cannot distinguish Adjective-ordinal and Adjective-qualificative without the 'other' feature.
    # If the feature is not available, we should make sure that we only generate valid tags.
    # We change all ordinal adjectives to qualificatives. But these should have the definiteness feature in certain contexts.
    $tag =~ s/(Adjective-qualificative\tDegree=positive\|Gender=masculine\|Number=singular\|Case=(nominative|accusative))(\|Animate=no$|$)/$1|Definiteness=yes$3/;
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus, 766 distinct tags found.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
Abbreviation	Abbreviation	_
Adjective	Adjective-ordinal	Degree=positive|Gender=feminine|Number=dual|Case=nominative
Adjective	Adjective-ordinal	Degree=positive|Gender=feminine|Number=plural|Case=accusative
Adjective	Adjective-ordinal	Degree=positive|Gender=feminine|Number=plural|Case=dative
Adjective	Adjective-ordinal	Degree=positive|Gender=feminine|Number=plural|Case=genitive
Adjective	Adjective-ordinal	Degree=positive|Gender=feminine|Number=plural|Case=instrumental
Adjective	Adjective-ordinal	Degree=positive|Gender=feminine|Number=plural|Case=locative
Adjective	Adjective-ordinal	Degree=positive|Gender=feminine|Number=plural|Case=nominative
Adjective	Adjective-ordinal	Degree=positive|Gender=feminine|Number=singular|Case=accusative
Adjective	Adjective-ordinal	Degree=positive|Gender=feminine|Number=singular|Case=dative
Adjective	Adjective-ordinal	Degree=positive|Gender=feminine|Number=singular|Case=genitive
Adjective	Adjective-ordinal	Degree=positive|Gender=feminine|Number=singular|Case=instrumental
Adjective	Adjective-ordinal	Degree=positive|Gender=feminine|Number=singular|Case=locative
Adjective	Adjective-ordinal	Degree=positive|Gender=feminine|Number=singular|Case=nominative
Adjective	Adjective-ordinal	Degree=positive|Gender=masculine|Number=dual|Case=nominative
Adjective	Adjective-ordinal	Degree=positive|Gender=masculine|Number=plural|Case=accusative
Adjective	Adjective-ordinal	Degree=positive|Gender=masculine|Number=plural|Case=genitive
Adjective	Adjective-ordinal	Degree=positive|Gender=masculine|Number=plural|Case=instrumental
Adjective	Adjective-ordinal	Degree=positive|Gender=masculine|Number=plural|Case=locative
Adjective	Adjective-ordinal	Degree=positive|Gender=masculine|Number=plural|Case=nominative
Adjective	Adjective-ordinal	Degree=positive|Gender=masculine|Number=singular|Case=accusative|Animate=no
Adjective	Adjective-ordinal	Degree=positive|Gender=masculine|Number=singular|Case=accusative|Animate=yes
Adjective	Adjective-ordinal	Degree=positive|Gender=masculine|Number=singular|Case=genitive
Adjective	Adjective-ordinal	Degree=positive|Gender=masculine|Number=singular|Case=instrumental
Adjective	Adjective-ordinal	Degree=positive|Gender=masculine|Number=singular|Case=locative
Adjective	Adjective-ordinal	Degree=positive|Gender=masculine|Number=singular|Case=nominative
Adjective	Adjective-ordinal	Degree=positive|Gender=neuter|Number=plural|Case=accusative
Adjective	Adjective-ordinal	Degree=positive|Gender=neuter|Number=plural|Case=genitive
Adjective	Adjective-ordinal	Degree=positive|Gender=neuter|Number=plural|Case=instrumental
Adjective	Adjective-ordinal	Degree=positive|Gender=neuter|Number=plural|Case=nominative
Adjective	Adjective-ordinal	Degree=positive|Gender=neuter|Number=singular|Case=accusative
Adjective	Adjective-ordinal	Degree=positive|Gender=neuter|Number=singular|Case=dative
Adjective	Adjective-ordinal	Degree=positive|Gender=neuter|Number=singular|Case=genitive
Adjective	Adjective-ordinal	Degree=positive|Gender=neuter|Number=singular|Case=instrumental
Adjective	Adjective-ordinal	Degree=positive|Gender=neuter|Number=singular|Case=locative
Adjective	Adjective-ordinal	Degree=positive|Gender=neuter|Number=singular|Case=nominative
Adjective	Adjective-possessive	Degree=positive|Gender=feminine|Number=dual|Case=genitive
Adjective	Adjective-possessive	Degree=positive|Gender=feminine|Number=plural|Case=genitive
Adjective	Adjective-possessive	Degree=positive|Gender=feminine|Number=plural|Case=instrumental
Adjective	Adjective-possessive	Degree=positive|Gender=feminine|Number=plural|Case=locative
Adjective	Adjective-possessive	Degree=positive|Gender=feminine|Number=plural|Case=nominative
Adjective	Adjective-possessive	Degree=positive|Gender=feminine|Number=singular|Case=accusative
Adjective	Adjective-possessive	Degree=positive|Gender=feminine|Number=singular|Case=genitive
Adjective	Adjective-possessive	Degree=positive|Gender=feminine|Number=singular|Case=locative
Adjective	Adjective-possessive	Degree=positive|Gender=feminine|Number=singular|Case=nominative
Adjective	Adjective-possessive	Degree=positive|Gender=masculine|Number=plural|Case=accusative
Adjective	Adjective-possessive	Degree=positive|Gender=masculine|Number=plural|Case=genitive
Adjective	Adjective-possessive	Degree=positive|Gender=masculine|Number=plural|Case=locative
Adjective	Adjective-possessive	Degree=positive|Gender=masculine|Number=singular|Case=accusative|Animate=no
Adjective	Adjective-possessive	Degree=positive|Gender=masculine|Number=singular|Case=accusative|Animate=yes
Adjective	Adjective-possessive	Degree=positive|Gender=masculine|Number=singular|Case=dative
Adjective	Adjective-possessive	Degree=positive|Gender=masculine|Number=singular|Case=genitive
Adjective	Adjective-possessive	Degree=positive|Gender=masculine|Number=singular|Case=instrumental
Adjective	Adjective-possessive	Degree=positive|Gender=masculine|Number=singular|Case=locative
Adjective	Adjective-possessive	Degree=positive|Gender=masculine|Number=singular|Case=nominative
Adjective	Adjective-possessive	Degree=positive|Gender=neuter|Number=plural|Case=accusative
Adjective	Adjective-possessive	Degree=positive|Gender=neuter|Number=singular|Case=accusative
Adjective	Adjective-possessive	Degree=positive|Gender=neuter|Number=singular|Case=instrumental
Adjective	Adjective-possessive	Degree=positive|Gender=neuter|Number=singular|Case=nominative
Adjective	Adjective-qualificative	Degree=comparative|Gender=feminine|Number=plural|Case=accusative
Adjective	Adjective-qualificative	Degree=comparative|Gender=feminine|Number=plural|Case=instrumental
Adjective	Adjective-qualificative	Degree=comparative|Gender=feminine|Number=plural|Case=locative
Adjective	Adjective-qualificative	Degree=comparative|Gender=feminine|Number=plural|Case=nominative
Adjective	Adjective-qualificative	Degree=comparative|Gender=feminine|Number=singular|Case=accusative
Adjective	Adjective-qualificative	Degree=comparative|Gender=feminine|Number=singular|Case=dative
Adjective	Adjective-qualificative	Degree=comparative|Gender=feminine|Number=singular|Case=genitive
Adjective	Adjective-qualificative	Degree=comparative|Gender=feminine|Number=singular|Case=instrumental
Adjective	Adjective-qualificative	Degree=comparative|Gender=feminine|Number=singular|Case=locative
Adjective	Adjective-qualificative	Degree=comparative|Gender=feminine|Number=singular|Case=nominative
Adjective	Adjective-qualificative	Degree=comparative|Gender=masculine|Number=plural|Case=accusative
Adjective	Adjective-qualificative	Degree=comparative|Gender=masculine|Number=plural|Case=genitive
Adjective	Adjective-qualificative	Degree=comparative|Gender=masculine|Number=plural|Case=nominative
Adjective	Adjective-qualificative	Degree=comparative|Gender=masculine|Number=singular|Case=accusative|Animate=no
Adjective	Adjective-qualificative	Degree=comparative|Gender=masculine|Number=singular|Case=accusative|Animate=yes
Adjective	Adjective-qualificative	Degree=comparative|Gender=masculine|Number=singular|Case=genitive
Adjective	Adjective-qualificative	Degree=comparative|Gender=masculine|Number=singular|Case=locative
Adjective	Adjective-qualificative	Degree=comparative|Gender=masculine|Number=singular|Case=nominative
Adjective	Adjective-qualificative	Degree=comparative|Gender=neuter|Number=plural|Case=accusative
Adjective	Adjective-qualificative	Degree=comparative|Gender=neuter|Number=singular|Case=accusative
Adjective	Adjective-qualificative	Degree=comparative|Gender=neuter|Number=singular|Case=locative
Adjective	Adjective-qualificative	Degree=comparative|Gender=neuter|Number=singular|Case=nominative
Adjective	Adjective-qualificative	Degree=positive|Gender=feminine|Number=dual|Case=accusative
Adjective	Adjective-qualificative	Degree=positive|Gender=feminine|Number=dual|Case=nominative
Adjective	Adjective-qualificative	Degree=positive|Gender=feminine|Number=plural|Case=accusative
Adjective	Adjective-qualificative	Degree=positive|Gender=feminine|Number=plural|Case=dative
Adjective	Adjective-qualificative	Degree=positive|Gender=feminine|Number=plural|Case=genitive
Adjective	Adjective-qualificative	Degree=positive|Gender=feminine|Number=plural|Case=instrumental
Adjective	Adjective-qualificative	Degree=positive|Gender=feminine|Number=plural|Case=locative
Adjective	Adjective-qualificative	Degree=positive|Gender=feminine|Number=plural|Case=nominative
Adjective	Adjective-qualificative	Degree=positive|Gender=feminine|Number=singular|Case=accusative
Adjective	Adjective-qualificative	Degree=positive|Gender=feminine|Number=singular|Case=dative
Adjective	Adjective-qualificative	Degree=positive|Gender=feminine|Number=singular|Case=genitive
Adjective	Adjective-qualificative	Degree=positive|Gender=feminine|Number=singular|Case=instrumental
Adjective	Adjective-qualificative	Degree=positive|Gender=feminine|Number=singular|Case=locative
Adjective	Adjective-qualificative	Degree=positive|Gender=feminine|Number=singular|Case=nominative
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=dual|Case=accusative
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=dual|Case=genitive
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=dual|Case=instrumental
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=dual|Case=nominative
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=plural|Case=accusative
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=plural|Case=dative
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=plural|Case=genitive
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=plural|Case=instrumental
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=plural|Case=locative
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=plural|Case=nominative
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=singular|Case=accusative|Animate=yes
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=singular|Case=accusative|Definiteness=no|Animate=no
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=singular|Case=accusative|Definiteness=yes|Animate=no
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=singular|Case=dative
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=singular|Case=genitive
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=singular|Case=instrumental
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=singular|Case=locative
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=singular|Case=nominative|Definiteness=no
Adjective	Adjective-qualificative	Degree=positive|Gender=masculine|Number=singular|Case=nominative|Definiteness=yes
Adjective	Adjective-qualificative	Degree=positive|Gender=neuter|Number=plural|Case=accusative
Adjective	Adjective-qualificative	Degree=positive|Gender=neuter|Number=plural|Case=genitive
Adjective	Adjective-qualificative	Degree=positive|Gender=neuter|Number=plural|Case=instrumental
Adjective	Adjective-qualificative	Degree=positive|Gender=neuter|Number=plural|Case=locative
Adjective	Adjective-qualificative	Degree=positive|Gender=neuter|Number=plural|Case=nominative
Adjective	Adjective-qualificative	Degree=positive|Gender=neuter|Number=singular|Case=accusative
Adjective	Adjective-qualificative	Degree=positive|Gender=neuter|Number=singular|Case=dative
Adjective	Adjective-qualificative	Degree=positive|Gender=neuter|Number=singular|Case=genitive
Adjective	Adjective-qualificative	Degree=positive|Gender=neuter|Number=singular|Case=instrumental
Adjective	Adjective-qualificative	Degree=positive|Gender=neuter|Number=singular|Case=locative
Adjective	Adjective-qualificative	Degree=positive|Gender=neuter|Number=singular|Case=nominative
Adjective	Adjective-qualificative	Degree=superlative|Gender=feminine|Number=singular|Case=accusative
Adjective	Adjective-qualificative	Degree=superlative|Gender=feminine|Number=singular|Case=genitive
Adjective	Adjective-qualificative	Degree=superlative|Gender=feminine|Number=singular|Case=nominative
Adjective	Adjective-qualificative	Degree=superlative|Gender=masculine|Number=plural|Case=genitive
Adjective	Adjective-qualificative	Degree=superlative|Gender=masculine|Number=plural|Case=locative
Adjective	Adjective-qualificative	Degree=superlative|Gender=masculine|Number=singular|Case=accusative|Animate=no
Adjective	Adjective-qualificative	Degree=superlative|Gender=masculine|Number=singular|Case=genitive
Adjective	Adjective-qualificative	Degree=superlative|Gender=masculine|Number=singular|Case=locative
Adjective	Adjective-qualificative	Degree=superlative|Gender=masculine|Number=singular|Case=nominative
Adjective	Adjective-qualificative	Degree=superlative|Gender=neuter|Number=singular|Case=genitive
Adjective	Adjective-qualificative	Degree=superlative|Gender=neuter|Number=singular|Case=nominative
Adposition	Adposition-preposition	Formation=compound
Adposition	Adposition-preposition	Formation=simple|Case=accusative
Adposition	Adposition-preposition	Formation=simple|Case=dative
Adposition	Adposition-preposition	Formation=simple|Case=genitive
Adposition	Adposition-preposition	Formation=simple|Case=instrumental
Adposition	Adposition-preposition	Formation=simple|Case=locative
Adverb	Adverb-general	Degree=comparative
Adverb	Adverb-general	Degree=positive
Adverb	Adverb-general	Degree=superlative
Conjunction	Conjunction-coordinating	Formation=simple
Conjunction	Conjunction-subordinating	Formation=simple
Interjection	Interjection	_
Noun	Noun-common	Gender=feminine|Number=dual|Case=accusative
Noun	Noun-common	Gender=feminine|Number=dual|Case=genitive
Noun	Noun-common	Gender=feminine|Number=dual|Case=instrumental
Noun	Noun-common	Gender=feminine|Number=dual|Case=nominative
Noun	Noun-common	Gender=feminine|Number=plural|Case=accusative
Noun	Noun-common	Gender=feminine|Number=plural|Case=dative
Noun	Noun-common	Gender=feminine|Number=plural|Case=genitive
Noun	Noun-common	Gender=feminine|Number=plural|Case=instrumental
Noun	Noun-common	Gender=feminine|Number=plural|Case=locative
Noun	Noun-common	Gender=feminine|Number=plural|Case=nominative
Noun	Noun-common	Gender=feminine|Number=singular|Case=accusative
Noun	Noun-common	Gender=feminine|Number=singular|Case=dative
Noun	Noun-common	Gender=feminine|Number=singular|Case=genitive
Noun	Noun-common	Gender=feminine|Number=singular|Case=instrumental
Noun	Noun-common	Gender=feminine|Number=singular|Case=locative
Noun	Noun-common	Gender=feminine|Number=singular|Case=nominative
Noun	Noun-common	Gender=masculine|Number=dual|Case=accusative
Noun	Noun-common	Gender=masculine|Number=dual|Case=dative
Noun	Noun-common	Gender=masculine|Number=dual|Case=instrumental
Noun	Noun-common	Gender=masculine|Number=dual|Case=locative
Noun	Noun-common	Gender=masculine|Number=dual|Case=nominative
Noun	Noun-common	Gender=masculine|Number=plural|Case=accusative
Noun	Noun-common	Gender=masculine|Number=plural|Case=dative
Noun	Noun-common	Gender=masculine|Number=plural|Case=genitive
Noun	Noun-common	Gender=masculine|Number=plural|Case=instrumental
Noun	Noun-common	Gender=masculine|Number=plural|Case=locative
Noun	Noun-common	Gender=masculine|Number=plural|Case=nominative
Noun	Noun-common	Gender=masculine|Number=singular
Noun	Noun-common	Gender=masculine|Number=singular|Case=accusative|Animate=no
Noun	Noun-common	Gender=masculine|Number=singular|Case=accusative|Animate=yes
Noun	Noun-common	Gender=masculine|Number=singular|Case=dative
Noun	Noun-common	Gender=masculine|Number=singular|Case=genitive
Noun	Noun-common	Gender=masculine|Number=singular|Case=instrumental
Noun	Noun-common	Gender=masculine|Number=singular|Case=locative
Noun	Noun-common	Gender=masculine|Number=singular|Case=nominative
Noun	Noun-common	Gender=neuter|Number=dual|Case=accusative
Noun	Noun-common	Gender=neuter|Number=dual|Case=genitive
Noun	Noun-common	Gender=neuter|Number=dual|Case=locative
Noun	Noun-common	Gender=neuter|Number=dual|Case=nominative
Noun	Noun-common	Gender=neuter|Number=plural|Case=accusative
Noun	Noun-common	Gender=neuter|Number=plural|Case=dative
Noun	Noun-common	Gender=neuter|Number=plural|Case=genitive
Noun	Noun-common	Gender=neuter|Number=plural|Case=instrumental
Noun	Noun-common	Gender=neuter|Number=plural|Case=locative
Noun	Noun-common	Gender=neuter|Number=plural|Case=nominative
Noun	Noun-common	Gender=neuter|Number=singular|Case=accusative
Noun	Noun-common	Gender=neuter|Number=singular|Case=dative
Noun	Noun-common	Gender=neuter|Number=singular|Case=genitive
Noun	Noun-common	Gender=neuter|Number=singular|Case=instrumental
Noun	Noun-common	Gender=neuter|Number=singular|Case=locative
Noun	Noun-common	Gender=neuter|Number=singular|Case=nominative
Noun	Noun-proper	Gender=feminine|Number=singular|Case=accusative
Noun	Noun-proper	Gender=feminine|Number=singular|Case=genitive
Noun	Noun-proper	Gender=feminine|Number=singular|Case=instrumental
Noun	Noun-proper	Gender=feminine|Number=singular|Case=locative
Noun	Noun-proper	Gender=feminine|Number=singular|Case=nominative
Noun	Noun-proper	Gender=masculine|Number=plural|Case=genitive
Noun	Noun-proper	Gender=masculine|Number=singular|Case=accusative|Animate=no
Noun	Noun-proper	Gender=masculine|Number=singular|Case=accusative|Animate=yes
Noun	Noun-proper	Gender=masculine|Number=singular|Case=dative
Noun	Noun-proper	Gender=masculine|Number=singular|Case=genitive
Noun	Noun-proper	Gender=masculine|Number=singular|Case=instrumental
Noun	Noun-proper	Gender=masculine|Number=singular|Case=locative
Noun	Noun-proper	Gender=masculine|Number=singular|Case=nominative
Noun	Noun-proper	Gender=neuter|Number=singular|Case=genitive
Noun	Noun-proper	Gender=neuter|Number=singular|Case=locative
Numeral	Numeral-cardinal	Form=digit
Numeral	Numeral-cardinal	Gender=feminine|Number=dual|Case=accusative|Form=letter
Numeral	Numeral-cardinal	Gender=feminine|Number=dual|Case=genitive|Form=letter
Numeral	Numeral-cardinal	Gender=feminine|Number=dual|Case=instrumental|Form=letter
Numeral	Numeral-cardinal	Gender=feminine|Number=dual|Case=nominative|Form=letter
Numeral	Numeral-cardinal	Gender=feminine|Number=plural|Case=accusative|Form=letter
Numeral	Numeral-cardinal	Gender=feminine|Number=plural|Case=genitive|Form=letter
Numeral	Numeral-cardinal	Gender=feminine|Number=plural|Case=instrumental|Form=letter
Numeral	Numeral-cardinal	Gender=feminine|Number=plural|Case=locative|Form=letter
Numeral	Numeral-cardinal	Gender=feminine|Number=plural|Case=nominative|Form=letter
Numeral	Numeral-cardinal	Gender=feminine|Number=singular|Case=accusative|Form=letter
Numeral	Numeral-cardinal	Gender=feminine|Number=singular|Case=dative|Form=letter
Numeral	Numeral-cardinal	Gender=feminine|Number=singular|Case=genitive|Form=letter
Numeral	Numeral-cardinal	Gender=feminine|Number=singular|Case=instrumental|Form=letter
Numeral	Numeral-cardinal	Gender=feminine|Number=singular|Case=locative|Form=letter
Numeral	Numeral-cardinal	Gender=feminine|Number=singular|Case=nominative|Form=letter
Numeral	Numeral-cardinal	Gender=masculine|Number=dual|Case=accusative|Form=letter
Numeral	Numeral-cardinal	Gender=masculine|Number=dual|Case=instrumental|Form=letter
Numeral	Numeral-cardinal	Gender=masculine|Number=dual|Case=nominative|Form=letter
Numeral	Numeral-cardinal	Gender=masculine|Number=plural|Case=accusative|Form=letter
Numeral	Numeral-cardinal	Gender=masculine|Number=plural|Case=instrumental|Form=letter
Numeral	Numeral-cardinal	Gender=masculine|Number=plural|Case=locative|Form=letter
Numeral	Numeral-cardinal	Gender=masculine|Number=plural|Case=nominative|Form=letter
Numeral	Numeral-cardinal	Gender=masculine|Number=singular|Case=accusative|Form=letter|Animate=no
Numeral	Numeral-cardinal	Gender=masculine|Number=singular|Case=accusative|Form=letter|Animate=yes
Numeral	Numeral-cardinal	Gender=masculine|Number=singular|Case=genitive|Form=letter
Numeral	Numeral-cardinal	Gender=masculine|Number=singular|Case=instrumental|Form=letter
Numeral	Numeral-cardinal	Gender=masculine|Number=singular|Case=locative|Form=letter
Numeral	Numeral-cardinal	Gender=masculine|Number=singular|Case=nominative|Form=letter
Numeral	Numeral-cardinal	Gender=neuter|Number=dual|Case=accusative|Form=letter
Numeral	Numeral-cardinal	Gender=neuter|Number=dual|Case=genitive|Form=letter
Numeral	Numeral-cardinal	Gender=neuter|Number=dual|Case=locative|Form=letter
Numeral	Numeral-cardinal	Gender=neuter|Number=plural|Case=accusative|Form=letter
Numeral	Numeral-cardinal	Gender=neuter|Number=plural|Case=genitive|Form=letter
Numeral	Numeral-cardinal	Gender=neuter|Number=plural|Case=instrumental|Form=letter
Numeral	Numeral-cardinal	Gender=neuter|Number=plural|Case=locative|Form=letter
Numeral	Numeral-cardinal	Gender=neuter|Number=plural|Case=nominative|Form=letter
Numeral	Numeral-cardinal	Gender=neuter|Number=singular|Case=accusative|Form=letter
Numeral	Numeral-cardinal	Gender=neuter|Number=singular|Case=genitive|Form=letter
Numeral	Numeral-cardinal	Gender=neuter|Number=singular|Case=instrumental|Form=letter
Numeral	Numeral-cardinal	Gender=neuter|Number=singular|Case=locative|Form=letter
Numeral	Numeral-cardinal	Gender=neuter|Number=singular|Case=nominative|Form=letter
Numeral	Numeral-multiple	Gender=feminine|Number=singular|Case=instrumental|Form=letter
Numeral	Numeral-ordinal	Form=digit
Numeral	Numeral-ordinal	Gender=feminine|Number=plural|Case=accusative|Form=letter
Numeral	Numeral-ordinal	Gender=feminine|Number=plural|Case=genitive|Form=letter
Numeral	Numeral-ordinal	Gender=feminine|Number=singular|Case=accusative|Form=letter
Numeral	Numeral-ordinal	Gender=feminine|Number=singular|Case=genitive|Form=letter
Numeral	Numeral-ordinal	Gender=feminine|Number=singular|Case=locative|Form=letter
Numeral	Numeral-ordinal	Gender=feminine|Number=singular|Case=nominative|Form=letter
Numeral	Numeral-ordinal	Gender=masculine|Number=singular|Case=accusative|Form=letter|Animate=no
Numeral	Numeral-ordinal	Gender=masculine|Number=singular|Case=genitive|Form=letter
Numeral	Numeral-ordinal	Gender=masculine|Number=singular|Case=instrumental|Form=letter
Numeral	Numeral-ordinal	Gender=masculine|Number=singular|Case=locative|Form=letter
Numeral	Numeral-ordinal	Gender=masculine|Number=singular|Case=nominative|Form=letter
Numeral	Numeral-ordinal	Gender=neuter|Number=plural|Case=accusative|Form=letter
Numeral	Numeral-ordinal	Gender=neuter|Number=plural|Case=genitive|Form=letter
Numeral	Numeral-ordinal	Gender=neuter|Number=plural|Case=locative|Form=letter
Numeral	Numeral-ordinal	Gender=neuter|Number=singular|Case=accusative|Form=letter
Numeral	Numeral-ordinal	Gender=neuter|Number=singular|Case=genitive|Form=letter
Numeral	Numeral-ordinal	Gender=neuter|Number=singular|Case=instrumental|Form=letter
Numeral	Numeral-ordinal	Gender=neuter|Number=singular|Case=locative|Form=letter
Numeral	Numeral-ordinal	Gender=neuter|Number=singular|Case=nominative|Form=letter
Numeral	Numeral-special	Gender=feminine|Number=plural|Case=accusative|Form=letter
Numeral	Numeral-special	Gender=masculine|Number=singular|Case=locative|Form=letter
PUNC	PUNC	_
Particle	Particle	_
Pronoun	Pronoun-demonstrative	Gender=feminine|Number=plural|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=feminine|Number=plural|Case=dative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=feminine|Number=plural|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=feminine|Number=plural|Case=genitive|Syntactic-Type=nominal
Pronoun	Pronoun-demonstrative	Gender=feminine|Number=plural|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=feminine|Number=plural|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=feminine|Number=plural|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=feminine|Number=singular|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=feminine|Number=singular|Case=accusative|Syntactic-Type=nominal
Pronoun	Pronoun-demonstrative	Gender=feminine|Number=singular|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=feminine|Number=singular|Case=genitive|Syntactic-Type=nominal
Pronoun	Pronoun-demonstrative	Gender=feminine|Number=singular|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=feminine|Number=singular|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=feminine|Number=singular|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=feminine|Number=singular|Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-demonstrative	Gender=masculine|Number=plural|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=masculine|Number=plural|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=masculine|Number=plural|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=masculine|Number=plural|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=masculine|Number=singular|Case=accusative|Syntactic-Type=adjectival|Animate=no
Pronoun	Pronoun-demonstrative	Gender=masculine|Number=singular|Case=accusative|Syntactic-Type=adjectival|Animate=yes
Pronoun	Pronoun-demonstrative	Gender=masculine|Number=singular|Case=accusative|Syntactic-Type=nominal|Animate=no
Pronoun	Pronoun-demonstrative	Gender=masculine|Number=singular|Case=dative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=masculine|Number=singular|Case=dative|Syntactic-Type=nominal
Pronoun	Pronoun-demonstrative	Gender=masculine|Number=singular|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=masculine|Number=singular|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=masculine|Number=singular|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=masculine|Number=singular|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=masculine|Number=singular|Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-demonstrative	Gender=neuter|Number=plural|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=neuter|Number=plural|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=neuter|Number=plural|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=neuter|Number=singular|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=neuter|Number=singular|Case=accusative|Syntactic-Type=nominal
Pronoun	Pronoun-demonstrative	Gender=neuter|Number=singular|Case=dative|Syntactic-Type=nominal
Pronoun	Pronoun-demonstrative	Gender=neuter|Number=singular|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=neuter|Number=singular|Case=genitive|Syntactic-Type=nominal
Pronoun	Pronoun-demonstrative	Gender=neuter|Number=singular|Case=instrumental|Syntactic-Type=nominal
Pronoun	Pronoun-demonstrative	Gender=neuter|Number=singular|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=neuter|Number=singular|Case=locative|Syntactic-Type=nominal
Pronoun	Pronoun-demonstrative	Gender=neuter|Number=singular|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-demonstrative	Gender=neuter|Number=singular|Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Case=accusative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Case=dative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=feminine|Number=dual|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=feminine|Number=dual|Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=feminine|Number=plural|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=feminine|Number=plural|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=feminine|Number=plural|Case=genitive|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=feminine|Number=plural|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=feminine|Number=plural|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=feminine|Number=plural|Case=locative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=feminine|Number=plural|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=feminine|Number=plural|Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=feminine|Number=singular|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=feminine|Number=singular|Case=accusative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=feminine|Number=singular|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=feminine|Number=singular|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=feminine|Number=singular|Case=instrumental|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=feminine|Number=singular|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=feminine|Number=singular|Case=locative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=feminine|Number=singular|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=feminine|Number=singular|Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=masculine|Number=dual|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=masculine|Number=dual|Case=accusative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=masculine|Number=dual|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=masculine|Number=dual|Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=masculine|Number=plural|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=masculine|Number=plural|Case=accusative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=masculine|Number=plural|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=masculine|Number=plural|Case=genitive|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=masculine|Number=plural|Case=instrumental|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=masculine|Number=plural|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=masculine|Number=plural|Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=masculine|Number=singular|Case=accusative|Syntactic-Type=adjectival|Animate=no
Pronoun	Pronoun-general	Gender=masculine|Number=singular|Case=accusative|Syntactic-Type=adjectival|Animate=yes
Pronoun	Pronoun-general	Gender=masculine|Number=singular|Case=accusative|Syntactic-Type=nominal|Animate=no
Pronoun	Pronoun-general	Gender=masculine|Number=singular|Case=dative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=masculine|Number=singular|Case=genitive|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=masculine|Number=singular|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=masculine|Number=singular|Case=instrumental|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=masculine|Number=singular|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=masculine|Number=singular|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=neuter|Number=dual|Case=accusative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=neuter|Number=plural|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=neuter|Number=plural|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=neuter|Number=plural|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=neuter|Number=plural|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=neuter|Number=singular|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=neuter|Number=singular|Case=accusative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=neuter|Number=singular|Case=dative|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=neuter|Number=singular|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=neuter|Number=singular|Case=genitive|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=neuter|Number=singular|Case=instrumental|Syntactic-Type=nominal
Pronoun	Pronoun-general	Gender=neuter|Number=singular|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=neuter|Number=singular|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-general	Gender=neuter|Number=singular|Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Case=accusative|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Case=dative|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Case=genitive|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Case=instrumental|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=feminine|Number=dual|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=feminine|Number=plural|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=feminine|Number=plural|Case=accusative|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=feminine|Number=plural|Case=dative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=feminine|Number=plural|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=feminine|Number=plural|Case=genitive|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=feminine|Number=plural|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=feminine|Number=plural|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=feminine|Number=plural|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=feminine|Number=plural|Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=feminine|Number=singular|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=feminine|Number=singular|Case=dative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=feminine|Number=singular|Case=dative|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=feminine|Number=singular|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=feminine|Number=singular|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=feminine|Number=singular|Case=instrumental|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=feminine|Number=singular|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=feminine|Number=singular|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=feminine|Number=singular|Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=masculine|Number=dual|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=masculine|Number=plural|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=masculine|Number=plural|Case=accusative|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=masculine|Number=plural|Case=dative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=masculine|Number=plural|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=masculine|Number=plural|Case=genitive|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=masculine|Number=plural|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=masculine|Number=plural|Case=instrumental|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=masculine|Number=plural|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=masculine|Number=plural|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=masculine|Number=plural|Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=masculine|Number=singular|Case=accusative|Syntactic-Type=adjectival|Animate=no
Pronoun	Pronoun-indefinite	Gender=masculine|Number=singular|Case=accusative|Syntactic-Type=adjectival|Animate=yes
Pronoun	Pronoun-indefinite	Gender=masculine|Number=singular|Case=accusative|Syntactic-Type=nominal|Animate=yes
Pronoun	Pronoun-indefinite	Gender=masculine|Number=singular|Case=dative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=masculine|Number=singular|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=masculine|Number=singular|Case=genitive|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=masculine|Number=singular|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=masculine|Number=singular|Case=instrumental|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=masculine|Number=singular|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=masculine|Number=singular|Case=locative|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=masculine|Number=singular|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=masculine|Number=singular|Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=neuter|Number=dual|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=neuter|Number=plural|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=neuter|Number=singular|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=neuter|Number=singular|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=neuter|Number=singular|Case=genitive|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Gender=neuter|Number=singular|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=neuter|Number=singular|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=neuter|Number=singular|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-indefinite	Gender=neuter|Number=singular|Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-indefinite	Syntactic-Type=adjectival
Pronoun	Pronoun-interrogative	Case=accusative|Syntactic-Type=nominal
Pronoun	Pronoun-interrogative	Case=genitive|Syntactic-Type=nominal
Pronoun	Pronoun-interrogative	Case=instrumental|Syntactic-Type=nominal
Pronoun	Pronoun-interrogative	Case=locative|Syntactic-Type=nominal
Pronoun	Pronoun-interrogative	Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-interrogative	Gender=feminine|Number=plural|Case=dative|Syntactic-Type=adjectival
Pronoun	Pronoun-interrogative	Gender=feminine|Number=singular|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-interrogative	Gender=masculine|Number=singular|Case=accusative|Syntactic-Type=adjectival|Animate=no
Pronoun	Pronoun-interrogative	Gender=masculine|Number=singular|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-interrogative	Gender=masculine|Number=singular|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-interrogative	Gender=neuter|Number=plural|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-interrogative	Gender=neuter|Number=singular|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-interrogative	Gender=neuter|Number=singular|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-interrogative	Syntactic-Type=adjectival
Pronoun	Pronoun-negative	Case=accusative|Syntactic-Type=nominal
Pronoun	Pronoun-negative	Case=genitive|Syntactic-Type=nominal
Pronoun	Pronoun-negative	Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-negative	Gender=feminine|Number=singular|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-negative	Gender=feminine|Number=singular|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-negative	Gender=feminine|Number=singular|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-negative	Gender=masculine|Number=plural|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-negative	Gender=masculine|Number=singular|Case=dative|Syntactic-Type=adjectival
Pronoun	Pronoun-negative	Gender=masculine|Number=singular|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-negative	Gender=masculine|Number=singular|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-negative	Gender=masculine|Number=singular|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-negative	Gender=neuter|Number=plural|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-negative	Gender=neuter|Number=singular|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-negative	Gender=neuter|Number=singular|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-negative	Syntactic-Type=adjectival
Pronoun	Pronoun-personal	Person=first|Number=dual|Case=instrumental|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=first|Number=plural|Case=dative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=first|Number=plural|Case=genitive|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=first|Number=plural|Case=nominative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=first|Number=singular|Case=accusative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=first|Number=singular|Case=accusative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=first|Number=singular|Case=dative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=first|Number=singular|Case=dative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=first|Number=singular|Case=genitive|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=first|Number=singular|Case=instrumental|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=first|Number=singular|Case=nominative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=second|Number=plural|Case=accusative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=second|Number=plural|Case=accusative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=second|Number=plural|Case=dative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=second|Number=plural|Case=instrumental|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=second|Number=plural|Case=nominative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=second|Number=singular|Case=accusative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=second|Number=singular|Case=dative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=second|Number=singular|Case=genitive|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=second|Number=singular|Case=genitive|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=second|Number=singular|Case=instrumental|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=second|Number=singular|Case=locative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=second|Number=singular|Case=nominative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=dual|Case=accusative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=dual|Case=accusative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=dual|Case=genitive|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=dual|Case=nominative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=plural|Case=accusative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=plural|Case=dative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=plural|Case=genitive|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=plural|Case=genitive|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=singular|Case=accusative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=singular|Case=accusative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=singular|Case=dative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=singular|Case=dative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=singular|Case=genitive|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=singular|Case=genitive|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=singular|Case=instrumental|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=singular|Case=locative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=feminine|Number=singular|Case=nominative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=dual|Case=accusative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=dual|Case=accusative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=dual|Case=dative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=dual|Case=genitive|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=dual|Case=instrumental|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=plural|Case=accusative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=plural|Case=dative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=plural|Case=genitive|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=plural|Case=genitive|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=plural|Case=instrumental|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=plural|Case=locative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=singular|Case=accusative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=singular|Case=accusative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=singular|Case=dative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=singular|Case=dative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=singular|Case=genitive|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=singular|Case=genitive|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=singular|Case=instrumental|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=singular|Case=locative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=masculine|Number=singular|Case=nominative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=neuter|Number=plural|Case=accusative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=neuter|Number=singular|Case=accusative|Clitic=yes|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=neuter|Number=singular|Case=instrumental|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-personal	Person=third|Gender=neuter|Number=singular|Case=locative|Clitic=no|Syntactic-Type=nominal
Pronoun	Pronoun-possessive	Person=first|Gender=feminine|Number=plural|Case=nominative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=first|Gender=feminine|Number=singular|Case=genitive|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=first|Gender=feminine|Number=singular|Case=genitive|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=first|Gender=feminine|Number=singular|Case=locative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=first|Gender=feminine|Number=singular|Case=nominative|Owner-Number=dual|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=first|Gender=feminine|Number=singular|Case=nominative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=first|Gender=feminine|Number=singular|Case=nominative|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=first|Gender=masculine|Number=dual|Case=nominative|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=first|Gender=masculine|Number=plural|Case=genitive|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=first|Gender=masculine|Number=plural|Case=locative|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=first|Gender=masculine|Number=singular|Case=accusative|Owner-Number=dual|Syntactic-Type=adjectival|Animate=no
Pronoun	Pronoun-possessive	Person=first|Gender=masculine|Number=singular|Case=locative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=first|Gender=masculine|Number=singular|Case=nominative|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=first|Gender=neuter|Number=plural|Case=accusative|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=first|Gender=neuter|Number=plural|Case=nominative|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=first|Gender=neuter|Number=singular|Case=locative|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=first|Gender=neuter|Number=singular|Case=nominative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=second|Gender=feminine|Number=plural|Case=instrumental|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=second|Gender=feminine|Number=plural|Case=locative|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=second|Gender=feminine|Number=singular|Case=accusative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=second|Gender=feminine|Number=singular|Case=locative|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=second|Gender=feminine|Number=singular|Case=nominative|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=second|Gender=masculine|Number=plural|Case=accusative|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=second|Gender=masculine|Number=singular|Case=accusative|Owner-Number=singular|Syntactic-Type=adjectival|Animate=no
Pronoun	Pronoun-possessive	Person=second|Gender=masculine|Number=singular|Case=genitive|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=second|Gender=masculine|Number=singular|Case=locative|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=second|Gender=masculine|Number=singular|Case=nominative|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=second|Gender=neuter|Number=singular|Case=genitive|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=second|Gender=neuter|Number=singular|Case=locative|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=second|Gender=neuter|Number=singular|Case=nominative|Owner-Number=singular|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=plural|Case=accusative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=plural|Case=accusative|Owner-Number=singular|Owner-Gender=feminine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=plural|Case=accusative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=plural|Case=dative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=plural|Case=genitive|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=plural|Case=genitive|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=plural|Case=instrumental|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=plural|Case=locative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=plural|Case=nominative|Owner-Number=dual|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=plural|Case=nominative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=plural|Case=nominative|Owner-Number=singular|Owner-Gender=feminine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=plural|Case=nominative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=singular|Case=accusative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=singular|Case=accusative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=singular|Case=dative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=singular|Case=genitive|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=singular|Case=genitive|Owner-Number=singular|Owner-Gender=feminine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=singular|Case=genitive|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=singular|Case=instrumental|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=singular|Case=locative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=singular|Case=nominative|Owner-Number=dual|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=singular|Case=nominative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=singular|Case=nominative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=feminine|Number=singular|Case=nominative|Owner-Number=singular|Owner-Gender=neuter|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=dual|Case=locative|Owner-Number=dual|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=plural|Case=accusative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=plural|Case=genitive|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=plural|Case=genitive|Owner-Number=singular|Owner-Gender=feminine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=plural|Case=genitive|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=plural|Case=instrumental|Owner-Number=singular|Owner-Gender=feminine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=plural|Case=instrumental|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=plural|Case=locative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=plural|Case=locative|Owner-Number=singular|Owner-Gender=feminine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=plural|Case=nominative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=plural|Case=nominative|Owner-Number=singular|Owner-Gender=feminine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=plural|Case=nominative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=singular|Case=accusative|Owner-Number=dual|Syntactic-Type=adjectival|Animate=no
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=singular|Case=accusative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival|Animate=no
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=singular|Case=genitive|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=singular|Case=genitive|Owner-Number=singular|Owner-Gender=feminine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=singular|Case=genitive|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=singular|Case=instrumental|Owner-Number=dual|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=singular|Case=instrumental|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=singular|Case=locative|Owner-Number=dual|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=singular|Case=locative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=singular|Case=nominative|Owner-Number=singular|Owner-Gender=feminine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=masculine|Number=singular|Case=nominative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=plural|Case=accusative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=plural|Case=accusative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=plural|Case=genitive|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=plural|Case=genitive|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=plural|Case=locative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=plural|Case=nominative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=plural|Case=nominative|Owner-Number=singular|Owner-Gender=feminine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=plural|Case=nominative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=singular|Case=accusative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=singular|Case=accusative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=singular|Case=dative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=singular|Case=genitive|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=singular|Case=instrumental|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=singular|Case=locative|Owner-Number=singular|Owner-Gender=feminine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=singular|Case=locative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=singular|Case=nominative|Owner-Number=plural|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=singular|Case=nominative|Owner-Number=singular|Owner-Gender=feminine|Syntactic-Type=adjectival
Pronoun	Pronoun-possessive	Person=third|Gender=neuter|Number=singular|Case=nominative|Owner-Number=singular|Owner-Gender=masculine|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Case=accusative|Clitic=no|Referent-Type=personal|Syntactic-Type=nominal
Pronoun	Pronoun-reflexive	Case=accusative|Clitic=yes|Referent-Type=personal|Syntactic-Type=nominal
Pronoun	Pronoun-reflexive	Case=dative|Clitic=no|Referent-Type=personal|Syntactic-Type=nominal
Pronoun	Pronoun-reflexive	Case=dative|Clitic=yes|Referent-Type=personal|Syntactic-Type=nominal
Pronoun	Pronoun-reflexive	Case=genitive|Clitic=no|Referent-Type=personal|Syntactic-Type=nominal
Pronoun	Pronoun-reflexive	Case=instrumental|Clitic=no|Referent-Type=personal|Syntactic-Type=nominal
Pronoun	Pronoun-reflexive	Case=locative|Clitic=no|Referent-Type=personal|Syntactic-Type=nominal
Pronoun	Pronoun-reflexive	Clitic=yes
Pronoun	Pronoun-reflexive	Gender=feminine|Number=plural|Case=accusative|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=feminine|Number=plural|Case=dative|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=feminine|Number=plural|Case=genitive|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=feminine|Number=plural|Case=instrumental|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=feminine|Number=plural|Case=locative|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=feminine|Number=singular|Case=accusative|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=feminine|Number=singular|Case=dative|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=feminine|Number=singular|Case=genitive|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=feminine|Number=singular|Case=instrumental|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=feminine|Number=singular|Case=locative|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=masculine|Number=plural|Case=accusative|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=masculine|Number=plural|Case=genitive|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=masculine|Number=plural|Case=instrumental|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=masculine|Number=plural|Case=locative|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=masculine|Number=singular|Case=accusative|Referent-Type=possessive|Syntactic-Type=adjectival|Animate=no
Pronoun	Pronoun-reflexive	Gender=masculine|Number=singular|Case=accusative|Referent-Type=possessive|Syntactic-Type=adjectival|Animate=yes
Pronoun	Pronoun-reflexive	Gender=masculine|Number=singular|Case=genitive|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=masculine|Number=singular|Case=instrumental|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=masculine|Number=singular|Case=locative|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=neuter|Number=plural|Case=accusative|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=neuter|Number=plural|Case=locative|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=neuter|Number=singular|Case=accusative|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=neuter|Number=singular|Case=genitive|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-reflexive	Gender=neuter|Number=singular|Case=locative|Referent-Type=possessive|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Case=accusative|Syntactic-Type=nominal
Pronoun	Pronoun-relative	Case=genitive|Syntactic-Type=nominal
Pronoun	Pronoun-relative	Case=instrumental|Syntactic-Type=nominal
Pronoun	Pronoun-relative	Case=locative|Syntactic-Type=nominal
Pronoun	Pronoun-relative	Case=nominative|Syntactic-Type=nominal
Pronoun	Pronoun-relative	Gender=feminine|Number=plural|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=feminine|Number=plural|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=feminine|Number=plural|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=feminine|Number=singular|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=feminine|Number=singular|Case=dative|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=feminine|Number=singular|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=feminine|Number=singular|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=feminine|Number=singular|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=feminine|Number=singular|Case=nominative|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=masculine|Number=plural|Case=accusative|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=masculine|Number=plural|Case=dative|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=masculine|Number=plural|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=masculine|Number=plural|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=masculine|Number=singular|Case=accusative|Syntactic-Type=adjectival|Animate=yes
Pronoun	Pronoun-relative	Gender=masculine|Number=singular|Case=dative|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=masculine|Number=singular|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=masculine|Number=singular|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=masculine|Number=singular|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=neuter|Number=plural|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=neuter|Number=plural|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=neuter|Number=singular|Case=dative|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=neuter|Number=singular|Case=genitive|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=neuter|Number=singular|Case=instrumental|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Gender=neuter|Number=singular|Case=locative|Syntactic-Type=adjectival
Pronoun	Pronoun-relative	Syntactic-Type=adjectival
Verb	Verb-copula	VForm=conditional
Verb	Verb-copula	VForm=indicative|Tense=future|Person=first|Number=dual
Verb	Verb-copula	VForm=indicative|Tense=future|Person=first|Number=plural
Verb	Verb-copula	VForm=indicative|Tense=future|Person=first|Number=singular
Verb	Verb-copula	VForm=indicative|Tense=future|Person=second|Number=plural
Verb	Verb-copula	VForm=indicative|Tense=future|Person=second|Number=singular
Verb	Verb-copula	VForm=indicative|Tense=future|Person=third|Number=dual
Verb	Verb-copula	VForm=indicative|Tense=future|Person=third|Number=plural
Verb	Verb-copula	VForm=indicative|Tense=future|Person=third|Number=singular
Verb	Verb-copula	VForm=indicative|Tense=present|Person=first|Number=dual|Negative=no
Verb	Verb-copula	VForm=indicative|Tense=present|Person=first|Number=plural|Negative=no
Verb	Verb-copula	VForm=indicative|Tense=present|Person=first|Number=plural|Negative=yes
Verb	Verb-copula	VForm=indicative|Tense=present|Person=first|Number=singular|Negative=no
Verb	Verb-copula	VForm=indicative|Tense=present|Person=first|Number=singular|Negative=yes
Verb	Verb-copula	VForm=indicative|Tense=present|Person=second|Number=plural|Negative=no
Verb	Verb-copula	VForm=indicative|Tense=present|Person=second|Number=singular|Negative=no
Verb	Verb-copula	VForm=indicative|Tense=present|Person=second|Number=singular|Negative=yes
Verb	Verb-copula	VForm=indicative|Tense=present|Person=third|Number=dual|Negative=no
Verb	Verb-copula	VForm=indicative|Tense=present|Person=third|Number=dual|Negative=yes
Verb	Verb-copula	VForm=indicative|Tense=present|Person=third|Number=plural|Negative=no
Verb	Verb-copula	VForm=indicative|Tense=present|Person=third|Number=plural|Negative=yes
Verb	Verb-copula	VForm=indicative|Tense=present|Person=third|Number=singular|Negative=no
Verb	Verb-copula	VForm=indicative|Tense=present|Person=third|Number=singular|Negative=yes
Verb	Verb-copula	VForm=participle|Tense=past|Number=dual|Gender=feminine|Voice=active
Verb	Verb-copula	VForm=participle|Tense=past|Number=dual|Gender=masculine|Voice=active
Verb	Verb-copula	VForm=participle|Tense=past|Number=dual|Gender=neuter|Voice=active
Verb	Verb-copula	VForm=participle|Tense=past|Number=plural|Gender=feminine|Voice=active
Verb	Verb-copula	VForm=participle|Tense=past|Number=plural|Gender=masculine|Voice=active
Verb	Verb-copula	VForm=participle|Tense=past|Number=plural|Gender=neuter|Voice=active
Verb	Verb-copula	VForm=participle|Tense=past|Number=singular|Gender=feminine|Voice=active
Verb	Verb-copula	VForm=participle|Tense=past|Number=singular|Gender=masculine|Voice=active
Verb	Verb-copula	VForm=participle|Tense=past|Number=singular|Gender=neuter|Voice=active
Verb	Verb-main	VForm=imperative|Tense=present|Person=first|Number=dual
Verb	Verb-main	VForm=imperative|Tense=present|Person=first|Number=plural
Verb	Verb-main	VForm=imperative|Tense=present|Person=second|Number=plural
Verb	Verb-main	VForm=imperative|Tense=present|Person=second|Number=singular
Verb	Verb-main	VForm=indicative|Tense=present|Person=first|Number=dual|Negative=no
Verb	Verb-main	VForm=indicative|Tense=present|Person=first|Number=plural|Negative=no
Verb	Verb-main	VForm=indicative|Tense=present|Person=first|Number=plural|Negative=yes
Verb	Verb-main	VForm=indicative|Tense=present|Person=first|Number=singular|Negative=no
Verb	Verb-main	VForm=indicative|Tense=present|Person=first|Number=singular|Negative=yes
Verb	Verb-main	VForm=indicative|Tense=present|Person=second|Number=plural|Negative=no
Verb	Verb-main	VForm=indicative|Tense=present|Person=second|Number=plural|Negative=yes
Verb	Verb-main	VForm=indicative|Tense=present|Person=second|Number=singular|Negative=no
Verb	Verb-main	VForm=indicative|Tense=present|Person=second|Number=singular|Negative=yes
Verb	Verb-main	VForm=indicative|Tense=present|Person=third|Number=dual|Negative=no
Verb	Verb-main	VForm=indicative|Tense=present|Person=third|Number=plural|Negative=no
Verb	Verb-main	VForm=indicative|Tense=present|Person=third|Number=singular|Negative=no
Verb	Verb-main	VForm=infinitive
Verb	Verb-main	VForm=participle|Number=dual|Gender=masculine|Voice=passive
Verb	Verb-main	VForm=participle|Number=dual|Gender=neuter|Voice=passive
Verb	Verb-main	VForm=participle|Number=plural|Gender=feminine|Voice=passive
Verb	Verb-main	VForm=participle|Number=plural|Gender=masculine|Voice=passive
Verb	Verb-main	VForm=participle|Number=plural|Gender=neuter|Voice=passive
Verb	Verb-main	VForm=participle|Number=singular|Gender=feminine|Voice=passive
Verb	Verb-main	VForm=participle|Number=singular|Gender=masculine|Voice=passive
Verb	Verb-main	VForm=participle|Number=singular|Gender=neuter|Voice=passive
Verb	Verb-main	VForm=participle|Tense=past|Number=dual|Gender=feminine|Voice=active
Verb	Verb-main	VForm=participle|Tense=past|Number=dual|Gender=masculine|Voice=active
Verb	Verb-main	VForm=participle|Tense=past|Number=plural|Gender=feminine|Voice=active
Verb	Verb-main	VForm=participle|Tense=past|Number=plural|Gender=masculine|Voice=active
Verb	Verb-main	VForm=participle|Tense=past|Number=plural|Gender=neuter|Voice=active
Verb	Verb-main	VForm=participle|Tense=past|Number=singular|Gender=feminine|Voice=active
Verb	Verb-main	VForm=participle|Tense=past|Number=singular|Gender=masculine|Voice=active
Verb	Verb-main	VForm=participle|Tense=past|Number=singular|Gender=neuter|Voice=active
Verb	Verb-main	VForm=supine
Verb	Verb-modal	VForm=indicative|Tense=present|Person=first|Number=plural|Negative=no
Verb	Verb-modal	VForm=indicative|Tense=present|Person=first|Number=singular|Negative=no
Verb	Verb-modal	VForm=indicative|Tense=present|Person=second|Number=plural|Negative=no
Verb	Verb-modal	VForm=indicative|Tense=present|Person=second|Number=singular|Negative=no
Verb	Verb-modal	VForm=indicative|Tense=present|Person=third|Number=dual|Negative=no
Verb	Verb-modal	VForm=indicative|Tense=present|Person=third|Number=plural|Negative=no
Verb	Verb-modal	VForm=indicative|Tense=present|Person=third|Number=singular|Negative=no
Verb	Verb-modal	VForm=participle|Number=plural|Gender=feminine|Voice=passive
Verb	Verb-modal	VForm=participle|Number=singular|Gender=neuter|Voice=passive
Verb	Verb-modal	VForm=participle|Tense=past|Number=plural|Gender=feminine|Voice=active
Verb	Verb-modal	VForm=participle|Tense=past|Number=plural|Gender=masculine|Voice=active
Verb	Verb-modal	VForm=participle|Tense=past|Number=singular|Gender=feminine|Voice=active
Verb	Verb-modal	VForm=participle|Tense=past|Number=singular|Gender=masculine|Voice=active
Verb	Verb-modal	VForm=participle|Tense=past|Number=singular|Gender=neuter|Voice=active
end_of_list
    ;
    # Protect from editors that replace tabs by spaces.
    $list =~ s/ \s+/\t/sg;
    my @list = split(/\r?\n/, $list);
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::SL::Conll - Driver for the Slovene tagset of the CoNLL 2006 Shared Task (derived from the Slovene Dependency Treebank).

=head1 VERSION

version 3.016

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::SL::Conll;
  my $driver = Lingua::Interset::Tagset::SL::Conll->new();
  my $fs = $driver->decode("Noun\tNoun-common\tGender=masculine|Number=singular|Case=nominative");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('sl::conll', "Noun\tNoun-common\tGender=masculine|Number=singular|Case=nominative");

=head1 DESCRIPTION

Interset driver for the Slovene tagset of the CoNLL 2006 Shared Task.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT. For Slovene,
these values are derived from the tagset of the Slovene Dependency Treebank.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::Conll>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
