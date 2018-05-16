# ABSTRACT: Driver for the Arabic tagset of the CoNLL 2007 Shared Task.
# Copyright © 2011, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::AR::Conll2007;
use strict;
use warnings;
our $VERSION = '3.012';

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
    return 'ar::conll2007';
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
            # common noun
            'N-' => ['pos' => 'noun', 'nountype' => 'com'],
            # proper noun
            'Z-' => ['pos' => 'noun', 'nountype' => 'prop'],
            # adjective
            'A-' => ['pos' => 'adj'],
            # pronoun
            # personal or possessive pronoun
            'S-' => ['pos' => 'noun|adj', 'prontype' => 'prs'],
            # demonstrative pronoun
            'SD' => ['pos' => 'noun|adj', 'prontype' => 'dem'],
            # relative pronoun
            'SR' => ['pos' => 'noun|adj', 'prontype' => 'rel'],
            # numeral
            'Q-' => ['pos' => 'num'],
            # verb
            'VI' => ['pos' => 'verb', 'aspect' => 'imp'],
            'VP' => ['pos' => 'verb', 'aspect' => 'perf'],
            'VC' => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'imp'],
            # adverb
            'D-' => ['pos' => 'adv'],
            # preposition
            'P-' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # conjunction
            'C-' => ['pos' => 'conj'],
            # function word, particle
            'F-' => ['pos' => 'part'],
            # interrogative particle
            'FI' => ['pos' => 'part', 'prontype' => 'int'],
            # negative particle
            'FN' => ['pos' => 'part', 'polarity' => 'neg'],
            # interjection
            'I-' => ['pos' => 'int'],
            # abbreviation
            'Y-' => ['abbr' => 'yes'],
            # typo
            'T-' => ['typo' => 'yes'],
            # punctuation (not used in UMH subcorpus)
            'G-' => ['pos' => 'punc'],
            # unknown tokens etc. (former X?)
            '_' => [],
            # Although not documented, the data contain the tag "-\t-\tdef=D".
            # It is always assigned to the definite article 'al' if separated from its noun or adjective.
            # Normally the article is not tokenized off and makes the definiteness feature of the noun.
            '--' => ['pos' => 'adj', 'prontype' => 'art']
        },
        'encode_map' =>

            { 'abbr' => { 'yes' => 'Y-',
                          '@'    => { 'typo' => { 'yes' => 'T-',
                                                  '@'    => { 'numtype' => { ''  => { 'pos' => { 'noun' => { 'prontype' => { ''    => { 'nountype' => { 'prop' => 'Z-',
                                                                                                                                                        '@'    => 'N-' }},
                                                                                                                             'dem' => 'SD',
                                                                                                                             'rel' => 'SR',
                                                                                                                             '@'   => 'S-' }},
                                                                                                 'adj'  => { 'prontype' => { ''    => 'A-',
                                                                                                                             'art' => '--',
                                                                                                                             'dem' => 'SD',
                                                                                                                             'rel' => 'SR',
                                                                                                                             '@'   => 'S-' }},
                                                                                                 'num'  => 'Q-',
                                                                                                 'verb' => { 'mood' => { 'imp' => 'VC',
                                                                                                                         '@'   => { 'aspect' => { 'perf' => 'VP',
                                                                                                                                                  '@'    => 'VI' }}}},
                                                                                                 'adv'  => 'D-',
                                                                                                 'adp'  => 'P-',
                                                                                                 'conj' => 'C-',
                                                                                                 'part' => { 'prontype' => { 'int' => 'FI',
                                                                                                                             '@'   => { 'polarity' => { 'neg' => 'FN',
                                                                                                                                                        '@'   => 'F-' }}}},
                                                                                                 'int'  => 'I-',
                                                                                                 'punc' => 'G-',
                                                                                                 '@'    => '_' }},
                                                                             '@' => 'Q-' }}}}}}
    );
    # GENDER ####################
    $atoms{Gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'M' => 'masc',
            'F' => 'fem'
        }
    );
    # NUMBER ####################
    $atoms{Number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'S' => 'sing',
            'D' => 'dual',
            'P' => 'plur'
        }
    );
    # CASE ####################
    $atoms{Case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            '1' => 'nom',
            '2' => 'gen',
            '4' => 'acc'
        }
    );
    # DEFINITENESS ####################
    $atoms{Defin} = $self->create_simple_atom
    (
        'intfeature' => 'definite',
        'simple_decode_map' =>
        {
            # definite
            'D' => 'def',
            # indefinite
            'I' => 'ind',
            # reduced (construct state)
            'R' => 'cons',
            # complex
            'C' => 'com'
        }
    );
    # PERSON ####################
    $atoms{Person} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            '1' => '1',
            '2' => '2',
            '3' => '3'
        }
    );
    # MOOD ####################
    $atoms{Mood} = $self->create_atom
    (
        'surfeature' => 'mood',
        'decode_map' =>
        {
            'I' => ['verbform' => 'fin', 'mood' => 'ind'],
            'S' => ['verbform' => 'fin', 'mood' => 'sub'],
            'J' => ['verbform' => 'fin', 'mood' => 'jus'],
            # undecided between subjunctive and jussive
            'D' => ['verbform' => 'fin', 'mood' => 'sub|jus']
        },
        'encode_map' =>

            { 'mood' => { 'jus|sub' => 'D',
                          'sub'     => 'S',
                          'jus'     => 'J',
                          'ind'     => 'I' }}
    );
    # VOICE ####################
    $atoms{Voice} = $self->create_simple_atom
    (
        'intfeature' => 'voice',
        'simple_decode_map' =>
        {
            'A' => 'act',
            'P' => 'pass'
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
    my @features = ('Mood', 'Voice', 'Person', 'Gender', 'Number', 'Case', 'Defin');
    return \@features;
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
    my $pos = substr($subpos, 0, 1);
    my $feature_names = $self->features_all();
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# 296 tags
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
-	--	Defin=D
A	A-	Case=1|Defin=D
A	A-	Case=1|Defin=I
A	A-	Case=1|Defin=R
A	A-	Case=2|Defin=C
A	A-	Case=2|Defin=D
A	A-	Case=2|Defin=I
A	A-	Case=2|Defin=R
A	A-	Case=4|Defin=C
A	A-	Case=4|Defin=D
A	A-	Case=4|Defin=I
A	A-	Case=4|Defin=R
A	A-	Defin=C
A	A-	Defin=D
A	A-	Gender=F|Number=D|Case=1|Defin=D
A	A-	Gender=F|Number=D|Case=1|Defin=I
A	A-	Gender=F|Number=D|Case=2|Defin=D
A	A-	Gender=F|Number=D|Case=2|Defin=I
A	A-	Gender=F|Number=D|Case=4|Defin=D
A	A-	Gender=F|Number=D|Case=4|Defin=I
A	A-	Gender=F|Number=P
A	A-	Gender=F|Number=P|Case=1|Defin=D
A	A-	Gender=F|Number=P|Case=1|Defin=I
A	A-	Gender=F|Number=P|Case=2|Defin=D
A	A-	Gender=F|Number=P|Case=2|Defin=I
A	A-	Gender=F|Number=P|Case=2|Defin=R
A	A-	Gender=F|Number=P|Case=4|Defin=D
A	A-	Gender=F|Number=P|Case=4|Defin=I
A	A-	Gender=F|Number=P|Defin=D
A	A-	Gender=F|Number=S
A	A-	Gender=F|Number=S|Case=1|Defin=D
A	A-	Gender=F|Number=S|Case=1|Defin=I
A	A-	Gender=F|Number=S|Case=1|Defin=R
A	A-	Gender=F|Number=S|Case=2|Defin=C
A	A-	Gender=F|Number=S|Case=2|Defin=D
A	A-	Gender=F|Number=S|Case=2|Defin=I
A	A-	Gender=F|Number=S|Case=2|Defin=R
A	A-	Gender=F|Number=S|Case=4|Defin=C
A	A-	Gender=F|Number=S|Case=4|Defin=D
A	A-	Gender=F|Number=S|Case=4|Defin=I
A	A-	Gender=F|Number=S|Case=4|Defin=R
A	A-	Gender=F|Number=S|Defin=C
A	A-	Gender=F|Number=S|Defin=D
A	A-	Gender=M|Number=D|Case=1|Defin=D
A	A-	Gender=M|Number=D|Case=1|Defin=I
A	A-	Gender=M|Number=D|Case=2|Defin=D
A	A-	Gender=M|Number=D|Case=2|Defin=I
A	A-	Gender=M|Number=D|Case=2|Defin=R
A	A-	Gender=M|Number=D|Case=4|Defin=D
A	A-	Gender=M|Number=D|Case=4|Defin=I
A	A-	Gender=M|Number=P|Case=1|Defin=D
A	A-	Gender=M|Number=P|Case=1|Defin=I
A	A-	Gender=M|Number=P|Case=1|Defin=R
A	A-	Gender=M|Number=P|Case=2|Defin=D
A	A-	Gender=M|Number=P|Case=2|Defin=I
A	A-	Gender=M|Number=P|Case=2|Defin=R
A	A-	Gender=M|Number=P|Case=4|Defin=D
A	A-	Gender=M|Number=P|Case=4|Defin=I
A	A-	Gender=M|Number=P|Case=4|Defin=R
A	A-	Gender=M|Number=S|Case=4|Defin=I
A	A-	_
C	C-	_
D	D-	Case=4|Defin=I
D	D-	Case=4|Defin=R
D	D-	Gender=M|Number=S|Case=4|Defin=I
D	D-	_
F	F-	_
F	FI	Case=2|Defin=R
F	FI	_
F	FN	Case=1|Defin=R
F	FN	Case=2|Defin=R
F	FN	Case=4|Defin=R
F	FN	_
G	G-	_
I	I-	Case=4|Defin=I
I	I-	Case=4|Defin=R
I	I-	Gender=M|Number=S|Case=4|Defin=I
I	I-	_
N	N-	Case=1|Defin=C
N	N-	Case=1|Defin=D
N	N-	Case=1|Defin=I
N	N-	Case=1|Defin=R
N	N-	Case=2|Defin=C
N	N-	Case=2|Defin=D
N	N-	Case=2|Defin=I
N	N-	Case=2|Defin=R
N	N-	Case=4|Defin=C
N	N-	Case=4|Defin=D
N	N-	Case=4|Defin=I
N	N-	Case=4|Defin=R
N	N-	Defin=D
N	N-	Defin=R
N	N-	Gender=F|Number=D|Case=1|Defin=D
N	N-	Gender=F|Number=D|Case=1|Defin=I
N	N-	Gender=F|Number=D|Case=1|Defin=R
N	N-	Gender=F|Number=D|Case=2|Defin=D
N	N-	Gender=F|Number=D|Case=2|Defin=I
N	N-	Gender=F|Number=D|Case=2|Defin=R
N	N-	Gender=F|Number=D|Case=4|Defin=D
N	N-	Gender=F|Number=D|Case=4|Defin=I
N	N-	Gender=F|Number=D|Case=4|Defin=R
N	N-	Gender=F|Number=P
N	N-	Gender=F|Number=P|Case=1|Defin=D
N	N-	Gender=F|Number=P|Case=1|Defin=I
N	N-	Gender=F|Number=P|Case=1|Defin=R
N	N-	Gender=F|Number=P|Case=2|Defin=D
N	N-	Gender=F|Number=P|Case=2|Defin=I
N	N-	Gender=F|Number=P|Case=2|Defin=R
N	N-	Gender=F|Number=P|Case=4|Defin=D
N	N-	Gender=F|Number=P|Case=4|Defin=I
N	N-	Gender=F|Number=P|Case=4|Defin=R
N	N-	Gender=F|Number=P|Defin=D
N	N-	Gender=F|Number=S
N	N-	Gender=F|Number=S|Case=1|Defin=D
N	N-	Gender=F|Number=S|Case=1|Defin=I
N	N-	Gender=F|Number=S|Case=1|Defin=R
N	N-	Gender=F|Number=S|Case=2|Defin=C
N	N-	Gender=F|Number=S|Case=2|Defin=D
N	N-	Gender=F|Number=S|Case=2|Defin=I
N	N-	Gender=F|Number=S|Case=2|Defin=R
N	N-	Gender=F|Number=S|Case=4|Defin=C
N	N-	Gender=F|Number=S|Case=4|Defin=D
N	N-	Gender=F|Number=S|Case=4|Defin=I
N	N-	Gender=F|Number=S|Case=4|Defin=R
N	N-	Gender=F|Number=S|Defin=D
N	N-	Gender=M|Number=D|Case=1|Defin=D
N	N-	Gender=M|Number=D|Case=1|Defin=I
N	N-	Gender=M|Number=D|Case=1|Defin=R
N	N-	Gender=M|Number=D|Case=2|Defin=D
N	N-	Gender=M|Number=D|Case=2|Defin=I
N	N-	Gender=M|Number=D|Case=2|Defin=R
N	N-	Gender=M|Number=D|Case=4|Defin=D
N	N-	Gender=M|Number=D|Case=4|Defin=I
N	N-	Gender=M|Number=D|Case=4|Defin=R
N	N-	Gender=M|Number=P|Case=1|Defin=D
N	N-	Gender=M|Number=P|Case=1|Defin=I
N	N-	Gender=M|Number=P|Case=1|Defin=R
N	N-	Gender=M|Number=P|Case=2|Defin=D
N	N-	Gender=M|Number=P|Case=2|Defin=I
N	N-	Gender=M|Number=P|Case=2|Defin=R
N	N-	Gender=M|Number=P|Case=4|Defin=D
N	N-	Gender=M|Number=P|Case=4|Defin=I
N	N-	Gender=M|Number=P|Case=4|Defin=R
N	N-	Gender=M|Number=S|Case=4|Defin=I
N	N-	_
P	P-	Gender=F|Number=S
P	P-	_
Q	Q-	_
S	S-	Person=1|Number=P|Case=1
S	S-	Person=1|Number=P|Case=2
S	S-	Person=1|Number=P|Case=4
S	S-	Person=1|Number=S|Case=1
S	S-	Person=1|Number=S|Case=2
S	S-	Person=1|Number=S|Case=4
S	S-	Person=2|Gender=F|Number=S|Case=2
S	S-	Person=2|Gender=M|Number=P|Case=2
S	S-	Person=2|Gender=M|Number=P|Case=4
S	S-	Person=2|Gender=M|Number=S|Case=2
S	S-	Person=2|Gender=M|Number=S|Case=4
S	S-	Person=3|Gender=F|Number=P|Case=2
S	S-	Person=3|Gender=F|Number=P|Case=4
S	S-	Person=3|Gender=F|Number=S|Case=1
S	S-	Person=3|Gender=F|Number=S|Case=2
S	S-	Person=3|Gender=F|Number=S|Case=4
S	S-	Person=3|Gender=M|Number=P|Case=1
S	S-	Person=3|Gender=M|Number=P|Case=2
S	S-	Person=3|Gender=M|Number=P|Case=4
S	S-	Person=3|Gender=M|Number=S|Case=1
S	S-	Person=3|Gender=M|Number=S|Case=2
S	S-	Person=3|Gender=M|Number=S|Case=4
S	S-	Person=3|Number=D|Case=1
S	S-	Person=3|Number=D|Case=2
S	S-	Person=3|Number=D|Case=4
S	SD	Gender=F
S	SD	Gender=F|Number=D
S	SD	Gender=F|Number=S
S	SD	Gender=M|Number=D
S	SD	Gender=M|Number=P
S	SD	Gender=M|Number=S
S	SR	_
V	VC	Person=2|Gender=M|Number=P
V	VC	Person=2|Gender=M|Number=S
V	VI	Mood=D|Person=3|Gender=F|Number=D
V	VI	Mood=D|Person=3|Gender=M|Number=D
V	VI	Mood=D|Person=3|Gender=M|Number=P
V	VI	Mood=D|Voice=A|Person=3|Gender=F|Number=D
V	VI	Mood=D|Voice=A|Person=3|Gender=M|Number=D
V	VI	Mood=D|Voice=A|Person=3|Gender=M|Number=P
V	VI	Mood=D|Voice=P|Person=3|Gender=M|Number=D
V	VI	Mood=D|Voice=P|Person=3|Gender=M|Number=P
V	VI	Mood=I|Person=1|Number=P
V	VI	Mood=I|Person=1|Number=S
V	VI	Mood=I|Person=2|Gender=M|Number=S
V	VI	Mood=I|Person=3|Gender=F|Number=D
V	VI	Mood=I|Person=3|Gender=F|Number=S
V	VI	Mood=I|Person=3|Gender=M|Number=D
V	VI	Mood=I|Person=3|Gender=M|Number=P
V	VI	Mood=I|Person=3|Gender=M|Number=S
V	VI	Mood=I|Voice=A|Person=1|Number=P
V	VI	Mood=I|Voice=A|Person=1|Number=S
V	VI	Mood=I|Voice=A|Person=2|Gender=M|Number=P
V	VI	Mood=I|Voice=A|Person=2|Number=D
V	VI	Mood=I|Voice=A|Person=3|Gender=F|Number=D
V	VI	Mood=I|Voice=A|Person=3|Gender=F|Number=S
V	VI	Mood=I|Voice=A|Person=3|Gender=M|Number=D
V	VI	Mood=I|Voice=A|Person=3|Gender=M|Number=P
V	VI	Mood=I|Voice=A|Person=3|Gender=M|Number=S
V	VI	Mood=I|Voice=P|Person=3|Gender=F|Number=S
V	VI	Mood=I|Voice=P|Person=3|Gender=M|Number=P
V	VI	Mood=I|Voice=P|Person=3|Gender=M|Number=S
V	VI	Mood=J|Voice=A|Person=1|Number=P
V	VI	Mood=J|Voice=A|Person=1|Number=S
V	VI	Mood=J|Voice=A|Person=3|Gender=F|Number=S
V	VI	Mood=J|Voice=A|Person=3|Gender=M|Number=P
V	VI	Mood=J|Voice=A|Person=3|Gender=M|Number=S
V	VI	Mood=J|Voice=P|Person=3|Gender=F|Number=S
V	VI	Mood=J|Voice=P|Person=3|Gender=M|Number=S
V	VI	Mood=S|Person=1|Number=P
V	VI	Mood=S|Person=1|Number=S
V	VI	Mood=S|Person=3|Gender=F|Number=S
V	VI	Mood=S|Person=3|Gender=M|Number=S
V	VI	Mood=S|Voice=A|Person=1|Number=P
V	VI	Mood=S|Voice=A|Person=1|Number=S
V	VI	Mood=S|Voice=A|Person=2|Gender=M|Number=S
V	VI	Mood=S|Voice=A|Person=3|Gender=F|Number=S
V	VI	Mood=S|Voice=A|Person=3|Gender=M|Number=S
V	VI	Mood=S|Voice=P|Person=3|Gender=F|Number=S
V	VI	Mood=S|Voice=P|Person=3|Gender=M|Number=S
V	VI	Person=1|Number=P
V	VI	Person=1|Number=S
V	VI	Person=2|Gender=M|Number=S
V	VI	Person=3|Gender=F|Number=P
V	VI	Person=3|Gender=F|Number=S
V	VI	Person=3|Gender=M|Number=S
V	VI	Voice=A|Person=3|Gender=F|Number=P
V	VI	Voice=A|Person=3|Gender=M|Number=S
V	VI	Voice=P|Person=3|Gender=F|Number=S
V	VI	Voice=P|Person=3|Gender=M|Number=S
V	VP	Person=1|Number=P
V	VP	Person=1|Number=S
V	VP	Person=2|Gender=M|Number=S
V	VP	Person=3|Gender=F|Number=D
V	VP	Person=3|Gender=F|Number=P
V	VP	Person=3|Gender=F|Number=S
V	VP	Person=3|Gender=M|Number=D
V	VP	Person=3|Gender=M|Number=P
V	VP	Person=3|Gender=M|Number=S
V	VP	Voice=A|Person=1|Number=P
V	VP	Voice=A|Person=1|Number=S
V	VP	Voice=A|Person=2|Gender=M|Number=S
V	VP	Voice=A|Person=3|Gender=F|Number=D
V	VP	Voice=A|Person=3|Gender=F|Number=P
V	VP	Voice=A|Person=3|Gender=F|Number=S
V	VP	Voice=A|Person=3|Gender=M|Number=D
V	VP	Voice=A|Person=3|Gender=M|Number=P
V	VP	Voice=A|Person=3|Gender=M|Number=S
V	VP	Voice=P|Person=1|Number=P
V	VP	Voice=P|Person=3|Gender=F|Number=S
V	VP	Voice=P|Person=3|Gender=M|Number=D
V	VP	Voice=P|Person=3|Gender=M|Number=P
V	VP	Voice=P|Person=3|Gender=M|Number=S
Y	Y-	Defin=D
Y	Y-	_
Z	Z-	Case=1|Defin=D
Z	Z-	Case=1|Defin=I
Z	Z-	Case=1|Defin=R
Z	Z-	Case=2|Defin=D
Z	Z-	Case=2|Defin=I
Z	Z-	Case=2|Defin=R
Z	Z-	Case=4|Defin=D
Z	Z-	Case=4|Defin=I
Z	Z-	Case=4|Defin=R
Z	Z-	Defin=D
Z	Z-	Gender=F|Number=D|Case=2|Defin=D
Z	Z-	Gender=F|Number=P
Z	Z-	Gender=F|Number=P|Case=1|Defin=D
Z	Z-	Gender=F|Number=P|Case=1|Defin=I
Z	Z-	Gender=F|Number=P|Case=2|Defin=D
Z	Z-	Gender=F|Number=P|Case=4|Defin=D
Z	Z-	Gender=F|Number=P|Case=4|Defin=I
Z	Z-	Gender=F|Number=P|Defin=D
Z	Z-	Gender=F|Number=S
Z	Z-	Gender=F|Number=S|Case=1|Defin=D
Z	Z-	Gender=F|Number=S|Case=1|Defin=I
Z	Z-	Gender=F|Number=S|Case=1|Defin=R
Z	Z-	Gender=F|Number=S|Case=2|Defin=D
Z	Z-	Gender=F|Number=S|Case=2|Defin=I
Z	Z-	Gender=F|Number=S|Case=2|Defin=R
Z	Z-	Gender=F|Number=S|Case=4|Defin=D
Z	Z-	Gender=F|Number=S|Case=4|Defin=I
Z	Z-	Gender=F|Number=S|Case=4|Defin=R
Z	Z-	Gender=F|Number=S|Defin=D
Z	Z-	Gender=M|Number=D|Case=2|Defin=D
Z	Z-	Gender=M|Number=P|Case=2|Defin=R
Z	Z-	_
_	_	_
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

Lingua::Interset::Tagset::AR::Conll2007 - Driver for the Arabic tagset of the CoNLL 2007 Shared Task.

=head1 VERSION

version 3.012

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::AR::Conll2007;
  my $driver = Lingua::Interset::Tagset::AR::Conll2007->new();
  my $fs = $driver->decode("N\tN-\tCase=1|Defin=I");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('ar::conll2007', "N\tN-\tCase=1|Defin=I");

=head1 DESCRIPTION

Interset driver for the Arabic tagset of the CoNLL 2007 (not 2006!) Shared Task.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT. For Arabic,
these values are derived from the tagset of the Prague Arabic Dependency Treebank.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::Conll>,
L<Lingua::Interset::Tagset::AR::Padt>,
L<Lingua::Interset::Tagset::AR::Conll>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
