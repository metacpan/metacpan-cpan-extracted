# ABSTRACT: Driver for the German tagset of the CoNLL 2009 Shared Task.
# Unlike CoNLL 2006, this year's tagset contains also morphological features.
# Copyright © 2009, 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::DE::Conll2009;
use strict;
use warnings;
our $VERSION = '3.015';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset::DE::Stts';



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
    return 'de::conll2009';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # GENUS / GENDER ####################
    $atoms{gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'Masc' => 'masc',
            'Fem'  => 'fem',
            'Neut' => 'neut'
        },
        'encode_default' => '*'
    );
    # NUMERUS / NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'Sg' => 'sing',
            'Pl' => 'plur'
        },
        'encode_default' => '*'
    );
    # KASUS / CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'Nom' => 'nom',
            'Gen' => 'gen',
            'Dat' => 'dat',
            'Acc' => 'acc'
        },
        'encode_default' => '*'
    );
    # GRAD / DEGREE ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'Pos'  => 'pos',
            'Comp' => 'cmp',
            'Sup'  => 'sup'
        },
        'encode_default' => '*'
    );
    # PERSON ####################
    $atoms{person} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            '1' => '1',
            '2' => '2',
            '3' => '3'
        },
        'encode_default' => '*'
    );
    # TENSE ####################
    $atoms{tense} = $self->create_simple_atom
    (
        'intfeature' => 'tense',
        'simple_decode_map' =>
        {
            'Past' => 'past',
            'Pres' => 'pres'
        },
        'encode_default' => '*'
    );
    # TENSE OF PARTICIPLE ####################
    $atoms{partense} = $self->create_atom
    (
        'surfeature' => 'tense',
        'decode_map' =>
        {
            # past participle ("aufgeschreckt", "überzeugt", "getan", ...)
            'Psp' => ['verbform' => 'part', 'tense' => 'past', 'aspect' => 'perf'],
            # present participle ("eingehend", "sprühend")
            'Prp' => ['verbform' => 'part', 'tense' => 'pres', 'aspect' => 'imp']
        },
        'encode_map' =>
        {
            'tense' => { 'past' => 'Psp',
                         'pres' => 'Prp',
                         '@'    => '*' }
        }
    );
    # VERB FORM ####################
    $atoms{verbform} = $self->create_atom
    (
        'tagset' => 'de::conll2009',
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            # Inf (infinitive) always comes with VVINF, so it already is set.
            # Infzu always comes with VVIZU, so it already is set.
            # infinitive: "abkommen"
            'Inf'   => ['verbform' => 'inf'],
            # infinitive with the incorporated "zu" marker: "abzukommen"
            'Infzu' => ['verbform' => 'inf', 'other' => {'verbform' => 'infzu'}]
        },
        'encode_map' =>

            { 'verbform' => { 'inf' => { 'other/verbform' => { 'infzu' => 'Infzu',
                                                               '@'     => 'Inf' }}}}
    );
    # MODUS / MOOD ####################
    $atoms{mood} = $self->create_atom
    (
        'surfeature' => 'mood',
        'decode_map' =>
        {
            # Ind (indicative) may also come with VVIMP (as in "schauen Sie mal") but it should not replace the imperative set from POS!
            # Imp (imperative) always comes with VVIMP.
            #'Ind'  => ['verbform' => 'fin', 'mood' => 'ind'],
            'Subj' => ['verbform' => 'fin', 'mood' => 'sub']
        },
        'encode_map' =>
        {
            'mood' => { 'ind' => 'Ind',
                        'sub' => 'Subj' }
        }
    );
    # MERGED ATOM TO DECODE ANY FEATURE VALUE ####################
    my @fatoms = map {$atoms{$_}} (qw(gender number case degree person tense partense verbform mood));
    $atoms{feature} = $self->create_merged_atom
    (
        'surfeature' => 'feature',
        'tagset'     => 'de::conll2009',
        'atoms'      => \@fatoms
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
    # two components: part-of-speech tag, features
    # example: NN\tNom|Sg|Masc
    my ($pos, $features) = split(/\s+/, $tag);
    # The CoNLL tagset is derived from the STTS tagset.
    # Part of speech is the STTS tag.
    if($pos eq 'PROAV')
    {
        $pos = 'PAV';
    }
    my $fs = $self->SUPER::decode($pos);
    # Unlike in DE::Conll, we do set our own tagset identifier because we have the features and thus the difference between us and the base DE::Stts is substantial.
    $fs->set_tagset('de::conll2009');
    my @features = split(/\|/, $features);
    my $atoms = $self->atoms();
    foreach my $feature (@features)
    {
        $atoms->{feature}->decode_and_merge_hard($feature, $fs);
    }
    # Estimate part of speech of TRUNCated words.
    # de::stts cannot do that without the morphological features.
    ###!!! It breaks encode(decode(x))!
    if(0 && $pos eq 'TRUNC' && $fs->pos() eq '')
    {
        if($fs->degree())
        {
            $fs->set_pos('adj');
        }
        elsif($fs->verbform() eq 'part')
        {
            $fs->set_pos('verb');
        }
        elsif($fs->verbform() eq 'inf')
        {
            $fs->set_pos('verb');
        }
        elsif($fs->person() =~ m/^[123]$/)
        {
            $fs->set_pos('verb');
        }
        else
        {
            $fs->set_pos('noun');
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
    # The CoNLL tagset is derived from the STTS tagset.
    # Part of speech is the STTS tag.
    my $old_tagset = $fs->tagset();
    $fs->set_tagset('de::stts') if($old_tagset eq 'de::conll2009');
    my $tag = $self->SUPER::encode($fs);
    $fs->set_tagset($old_tagset);
    if($tag eq 'PAV')
    {
        $tag = 'PROAV';
    }
    # Encode the features.
    my @feature_names = ();
    my $keytag = $tag;
    if($tag =~ m/^((APPR)?ART|FM|N[NE]|P(D|I|POS|REL|W)(AT|S)|XY)$/)
    {
        @feature_names = ('case', 'number', 'gender');
    }
    else
    {
        my %feature_names =
        (
            'NN'   => ['case', 'number', 'gender'],
            'ADJA' => ['degree', 'case', 'number', 'gender'],
            'ADJD' => ['degree'],
            'ADV'  => ['degree'],
            'APPO' => ['case'],
            'PPER' => ['person', 'case', 'number', 'gender'],
            'PRF'  => ['person', 'case', 'number'],
            'VINF' => ['verbform'],
            'VIZU' => ['verbform'],
            'VFIN' => ['person', 'number', 'tense', 'mood'],
            # The imperative of the 1st and 3rd persons (plural) are expressed using the word order (verb precedes pronoun).
            # The finite verb is tagged VVIMP, however its morphological features speak about indicative.
            'VIMP' => ['person', 'number'], ###!!! person [13] => Pres|Ind; otherwise, just Imp
            'VPP'  => ['partense'],
        );
        if($tag =~ m/^V([VMA])(FIN|IMP|IZU|INF|PP)$/)
        {
            my $verbtype = $1;
            my $verbform = $2;
            $keytag = 'V'.$verbform;
        }
        elsif($tag eq 'TRUNC')
        {
            if($fs->is_infinitive())
            {
                $keytag = 'VINF';
            }
            elsif($fs->is_participle())
            {
                $keytag = 'VPP';
            }
            elsif($fs->is_verb())
            {
                $keytag = 'VIND';
            }
            elsif($fs->degree())
            {
                $keytag = 'ADJA';
            }
            else
            {
                $keytag = 'NN';
            }
        }
        if(defined($feature_names{$keytag}))
        {
            @feature_names = @{$feature_names{$keytag}};
        }
    }
    my @features;
    my $atoms = $self->atoms();
    foreach my $name (@feature_names)
    {
        push(@features, $atoms->{$name}->encode($fs));
    }
    if($keytag eq 'VIMP')
    {
        # The imperative of the 1st and 3rd persons (plural) are expressed using the word order (verb precedes pronoun).
        # The finite verb is tagged VVIMP, however its morphological features speak about indicative.
        if($fs->person() ne '2')
        {
            push(@features, 'Pres', 'Ind');
        }
        else
        {
            push(@features, 'Imp');
        }
    }
    my $features = @features ? join('|', @features) : '_';
    if($tag eq 'TRUNC' && $features =~ m/^\*\|(Sg|Pl)\|\*$/)
    {
        $features = "3|$1|Pres|Ind";
    }
    # *|*|* should be changed to _
    $features = '_' if($features =~ m/^\*(\|\*)*$/);
    return "$tag\t$features";
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# The tag occurrences in the CoNLL 2009 corpus have been collected.
# 835 tags have been observed.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
\$(	_
\$,	_
\$.	_
ADJA	_
ADJA	*|Acc|Sg|Masc
ADJA	Comp|*|*|*
ADJA	Comp|Acc|Pl|*
ADJA	Comp|Acc|Pl|Fem
ADJA	Comp|Acc|Pl|Masc
ADJA	Comp|Acc|Pl|Neut
ADJA    Comp|Acc|Sg|*
ADJA	Comp|Acc|Sg|Fem
ADJA	Comp|Acc|Sg|Masc
ADJA	Comp|Acc|Sg|Neut
ADJA	Comp|Dat|Pl|*
ADJA	Comp|Dat|Pl|Fem
ADJA	Comp|Dat|Pl|Masc
ADJA	Comp|Dat|Pl|Neut
ADJA	Comp|Dat|Sg|*
ADJA	Comp|Dat|Sg|Fem
ADJA	Comp|Dat|Sg|Masc
ADJA	Comp|Dat|Sg|Neut
ADJA	Comp|Gen|Pl|*
ADJA	Comp|Gen|Pl|Fem
ADJA	Comp|Gen|Pl|Masc
ADJA	Comp|Gen|Pl|Neut
ADJA    Comp|Gen|Sg|*
ADJA	Comp|Gen|Sg|Fem
ADJA	Comp|Gen|Sg|Masc
ADJA	Comp|Gen|Sg|Neut
ADJA	Comp|Nom|Pl|*
ADJA	Comp|Nom|Pl|Fem
ADJA	Comp|Nom|Pl|Masc
ADJA	Comp|Nom|Pl|Neut
ADJA    Comp|Nom|Sg|*
ADJA	Comp|Nom|Sg|Fem
ADJA	Comp|Nom|Sg|Masc
ADJA	Comp|Nom|Sg|Neut
ADJA	Comp|*|Sg|Fem
ADJA	*|Gen|Sg|Fem
ADJA	Pos|*|*|*
ADJA	Pos|Acc|*|*
ADJA	Pos|Acc|Pl|*
ADJA	Pos|Acc|Pl|Fem
ADJA	Pos|Acc|Pl|Masc
ADJA	Pos|Acc|Pl|Neut
ADJA	Pos|Acc|Sg|*
ADJA	Pos|Acc|Sg|Fem
ADJA	Pos|Acc|Sg|Masc
ADJA	Pos|Acc|Sg|Neut
ADJA	Pos|Dat|Pl|*
ADJA	Pos|Dat|Pl|Fem
ADJA	Pos|Dat|Pl|Masc
ADJA	Pos|Dat|Pl|Neut
ADJA	Pos|Dat|Sg|*
ADJA	Pos|Dat|Sg|Fem
ADJA	Pos|Dat|Sg|Masc
ADJA	Pos|Dat|Sg|Neut
ADJA	Pos|Gen|*|*
ADJA	Pos|Gen|Pl|*
ADJA	Pos|Gen|Pl|Fem
ADJA	Pos|Gen|Pl|Masc
ADJA	Pos|Gen|Pl|Neut
ADJA	Pos|Gen|Sg|*
ADJA	Pos|Gen|Sg|Fem
ADJA	Pos|Gen|Sg|Masc
ADJA	Pos|Gen|Sg|Neut
ADJA	Pos|Nom|Pl|*
ADJA	Pos|Nom|Pl|Fem
ADJA	Pos|Nom|Pl|Masc
ADJA	Pos|Nom|Pl|Neut
ADJA	Pos|Nom|Sg|*
ADJA	Pos|Nom|Sg|Fem
ADJA	Pos|Nom|Sg|Masc
ADJA	Pos|Nom|Sg|Neut
ADJA	Pos|*|Pl|*
ADJA	Pos|*|Pl|Fem
ADJA	Pos|*|Sg|Fem
ADJA	Pos|*|Sg|Masc
ADJA	Pos|*|Sg|Neut
ADJA	Sup|Acc|Pl|*
ADJA	Sup|Acc|Pl|Fem
ADJA	Sup|Acc|Pl|Masc
ADJA	Sup|Acc|Pl|Neut
ADJA    Sup|Acc|Sg|*
ADJA	Sup|Acc|Sg|Fem
ADJA	Sup|Acc|Sg|Masc
ADJA	Sup|Acc|Sg|Neut
ADJA	Sup|Dat|Pl|*
ADJA	Sup|Dat|Pl|Fem
ADJA	Sup|Dat|Pl|Masc
ADJA	Sup|Dat|Pl|Neut
ADJA    Sup|Dat|Sg|*
ADJA	Sup|Dat|Sg|Fem
ADJA	Sup|Dat|Sg|Masc
ADJA	Sup|Dat|Sg|Neut
ADJA	Sup|Gen|Pl|*
ADJA	Sup|Gen|Pl|Fem
ADJA	Sup|Gen|Pl|Masc
ADJA	Sup|Gen|Pl|Neut
ADJA    Sup|Gen|Sg|*
ADJA	Sup|Gen|Sg|Fem
ADJA	Sup|Gen|Sg|Masc
ADJA	Sup|Gen|Sg|Neut
ADJA	Sup|Nom|Pl|*
ADJA	Sup|Nom|Pl|Fem
ADJA	Sup|Nom|Pl|Masc
ADJA	Sup|Nom|Pl|Neut
ADJA    Sup|Nom|Sg|*
ADJA	Sup|Nom|Sg|Fem
ADJA	Sup|Nom|Sg|Masc
ADJA	Sup|Nom|Sg|Neut
ADJA	Sup|*|Sg|Fem
ADJD	_
ADJD	Comp
ADJD	Pos
ADJD	Sup
ADV	    _
ADV	    Comp
ADV	    Pos
APPO	_
APPO	Acc
APPO	Dat
APPO	Gen
APPR	_
APPRART	_
APPRART	Acc|Sg|Neut
APPRART	Dat|Sg|*
APPRART	Dat|Sg|Fem
APPRART	Dat|Sg|Masc
APPRART	Dat|Sg|Neut
APZR	_
ART	_
ART	Acc|*|*
ART	Acc|Pl|*
ART	Acc|Pl|Fem
ART	Acc|Pl|Masc
ART	Acc|Pl|Neut
ART	Acc|Sg|*
ART	Acc|Sg|Fem
ART	Acc|Sg|Masc
ART	Acc|Sg|Neut
ART	Dat|Pl|*
ART	Dat|Pl|Fem
ART	Dat|Pl|Masc
ART	Dat|Pl|Neut
ART	Dat|Sg|*
ART	Dat|Sg|Fem
ART	Dat|Sg|Masc
ART	Dat|Sg|Neut
ART	Gen|*|*
ART	Gen|*|Fem
ART	Gen|Pl|*
ART	Gen|Pl|Fem
ART	Gen|Pl|Masc
ART	Gen|Pl|Neut
ART	Gen|Sg|*
ART	Gen|Sg|Fem
ART	Gen|Sg|Masc
ART	Gen|Sg|Neut
ART	*|*|Neut
ART	Nom|*|*
ART	Nom|Pl|*
ART	Nom|Pl|Fem
ART	Nom|Pl|Masc
ART	Nom|Pl|Neut
ART	Nom|Sg|*
ART	Nom|Sg|Fem
ART	Nom|Sg|Masc
ART	Nom|Sg|Neut
ART	*|Pl|*
ART	*|Pl|Fem
ART	*|Sg|Fem
ART	*|Sg|Masc
ART	*|Sg|Neut
CARD	_
FM	_
FM	Acc|Pl|Neut
FM	Acc|Sg|*
FM	Acc|Sg|Fem
FM	Acc|Sg|Masc
FM	Acc|Sg|Neut
FM	Dat|Pl|*
FM	Dat|Sg|*
FM	Dat|Sg|Fem
FM	Dat|Sg|Masc
FM	Dat|Sg|Neut
FM	Gen|Pl|*
FM	Gen|Sg|*
FM	Gen|Sg|Fem
FM	Gen|Sg|Neut
FM	Nom|*|*
FM	Nom|Pl|*
FM	Nom|Pl|Masc
FM	Nom|Sg|*
FM	Nom|Sg|Fem
FM	Nom|Sg|Masc
FM	Nom|Sg|Neut
ITJ	    _
KOKOM	_
KON	    _
KOUI	_
KOUS	_
NE	_
NE	Acc|*|*
NE	Acc|Pl|*
NE	Acc|Pl|Fem
NE	Acc|Pl|Masc
NE	Acc|Pl|Neut
NE	Acc|Sg|*
NE	Acc|Sg|Fem
NE	Acc|Sg|Masc
NE	Acc|Sg|Neut
NE	Dat|*|*
NE	Dat|*|Masc
NE	Dat|Pl|*
NE	Dat|Pl|Fem
NE	Dat|Pl|Masc
NE	Dat|Pl|Neut
NE	Dat|Sg|*
NE	Dat|Sg|Fem
NE	Dat|Sg|Masc
NE	Dat|Sg|Neut
NE	*|*|Fem
NE	Gen|*|*
NE	Gen|*|Fem
NE	Gen|Pl|*
NE	Gen|Pl|Fem
NE	Gen|Pl|Masc
NE	Gen|Pl|Neut
NE	Gen|Sg|*
NE	Gen|Sg|Fem
NE	Gen|Sg|Masc
NE	Gen|Sg|Neut
NE	*|*|Masc
NE	*|*|Neut
NE	Nom|*|*
NE	Nom|*|Fem
NE	Nom|*|Masc
NE	Nom|Pl|*
NE	Nom|Pl|Fem
NE	Nom|Pl|Masc
NE	Nom|Pl|Neut
NE	Nom|Sg|*
NE	Nom|Sg|Fem
NE	Nom|Sg|Masc
NE	Nom|Sg|Neut
NE	*|Pl|Neut
NE	*|Sg|Fem
NE	*|Sg|Masc
NE	*|Sg|Neut
NN	_
NN	Acc|*|*
NN	Acc|*|Masc
NN	Acc|*|Neut
NN	Acc|Pl|*
NN	Acc|Pl|Fem
NN	Acc|Pl|Masc
NN	Acc|Pl|Neut
NN	Acc|Sg|*
NN	Acc|Sg|Fem
NN	Acc|Sg|Masc
NN	Acc|Sg|Neut
NN	Dat|*|*
NN	Dat|*|Masc
NN	Dat|*|Neut
NN	Dat|Pl|*
NN	Dat|Pl|Fem
NN	Dat|Pl|Masc
NN	Dat|Pl|Neut
NN	Dat|Sg|*
NN	Dat|Sg|Fem
NN	Dat|Sg|Masc
NN	Dat|Sg|Neut
NN	*|*|Fem
NN	Gen|*|*
NN	Gen|*|Fem
NN	Gen|Pl|*
NN	Gen|Pl|Fem
NN	Gen|Pl|Masc
NN	Gen|Pl|Neut
NN	Gen|Sg|*
NN	Gen|Sg|Fem
NN	Gen|Sg|Masc
NN	Gen|Sg|Neut
NN	*|*|Masc
NN	*|*|Neut
NN	Nom|*|*
NN	Nom|*|Fem
NN	Nom|*|Masc
NN	Nom|*|Neut
NN	Nom|Pl|*
NN	Nom|Pl|Fem
NN	Nom|Pl|Masc
NN	Nom|Pl|Neut
NN	Nom|Sg|*
NN	Nom|Sg|Fem
NN	Nom|Sg|Masc
NN	Nom|Sg|Neut
NN	*|Pl|*
NN	*|Pl|Fem
NN	*|Pl|Masc
NN	*|Pl|Neut
NN	*|Sg|Fem
NN	*|Sg|Masc
NN	*|Sg|Neut
PDAT	_
PDAT	Acc|Pl|*
PDAT	Acc|Pl|Fem
PDAT	Acc|Pl|Masc
PDAT	Acc|Pl|Neut
PDAT	Acc|Sg|Fem
PDAT	Acc|Sg|Masc
PDAT	Acc|Sg|Neut
PDAT	Dat|Pl|*
PDAT	Dat|Pl|Fem
PDAT	Dat|Pl|Masc
PDAT	Dat|Pl|Neut
PDAT	Dat|Sg|Fem
PDAT	Dat|Sg|Masc
PDAT	Dat|Sg|Neut
PDAT	*|*|Fem
PDAT	Gen|*|*
PDAT	Gen|Pl|*
PDAT	Gen|Pl|Fem
PDAT	Gen|Pl|Masc
PDAT	Gen|Pl|Neut
PDAT	Gen|Sg|*
PDAT	Gen|Sg|Fem
PDAT	Gen|Sg|Masc
PDAT	Gen|Sg|Neut
PDAT	Nom|Pl|*
PDAT	Nom|Pl|Fem
PDAT	Nom|Pl|Masc
PDAT	Nom|Pl|Neut
PDAT	Nom|Sg|Fem
PDAT	Nom|Sg|Masc
PDAT	Nom|Sg|Neut
PDAT	*|Sg|Fem
PDS	_
PDS	Acc|*|*
PDS	Acc|Pl|*
PDS	Acc|Pl|Fem
PDS	Acc|Pl|Masc
PDS	Acc|Pl|Neut
PDS	Acc|Sg|*
PDS	Acc|Sg|Fem
PDS	Acc|Sg|Masc
PDS	Acc|Sg|Neut
PDS	Dat|Pl|*
PDS	Dat|Pl|Fem
PDS	Dat|Pl|Masc
PDS	Dat|Pl|Neut
PDS	Dat|Sg|*
PDS	Dat|Sg|Fem
PDS	Dat|Sg|Masc
PDS	Dat|Sg|Neut
PDS	Gen|Pl|*
PDS	Gen|Pl|Fem
PDS Gen|Pl|Masc
PDS	Gen|Pl|Neut
PDS	Gen|Sg|*
PDS	Gen|Sg|Fem
PDS	Gen|Sg|Masc
PDS	Gen|Sg|Neut
PDS	Nom|Pl|*
PDS	Nom|Pl|Fem
PDS	Nom|Pl|Masc
PDS	Nom|Pl|Neut
PDS	Nom|Sg|*
PDS	Nom|Sg|Fem
PDS	Nom|Sg|Masc
PDS	Nom|Sg|Neut
PIAT	_
PIAT	Acc|Pl|*
PIAT	Acc|Pl|Fem
PIAT	Acc|Pl|Masc
PIAT	Acc|Pl|Neut
PIAT	Acc|Sg|*
PIAT	Acc|Sg|Fem
PIAT	Acc|Sg|Masc
PIAT	Acc|Sg|Neut
PIAT	Dat|Pl|*
PIAT	Dat|Pl|Fem
PIAT	Dat|Pl|Masc
PIAT	Dat|Pl|Neut
PIAT	Dat|Sg|*
PIAT	Dat|Sg|Fem
PIAT	Dat|Sg|Masc
PIAT	Dat|Sg|Neut
PIAT	Gen|Pl|*
PIAT	Gen|Pl|Fem
PIAT	Gen|Pl|Masc
PIAT	Gen|Pl|Neut
PIAT    Gen|Sg|*
PIAT	Gen|Sg|Fem
PIAT	Gen|Sg|Masc
PIAT	Gen|Sg|Neut
PIAT	*|*|Neut
PIAT	Nom|Pl|*
PIAT	Nom|Pl|Fem
PIAT	Nom|Pl|Masc
PIAT	Nom|Pl|Neut
PIAT	Nom|Sg|*
PIAT	Nom|Sg|Fem
PIAT	Nom|Sg|Masc
PIAT	Nom|Sg|Neut
PIAT	*|Pl|Fem
PIAT	*|Sg|Fem
PIS	_
PIS	Acc|*|*
PIS	Acc|Pl|*
PIS	Acc|Pl|Fem
PIS	Acc|Pl|Masc
PIS	Acc|Pl|Neut
PIS	Acc|Sg|*
PIS	Acc|Sg|Fem
PIS	Acc|Sg|Masc
PIS	Acc|Sg|Neut
PIS	Dat|Pl|*
PIS	Dat|Pl|Fem
PIS	Dat|Pl|Masc
PIS	Dat|Pl|Neut
PIS	Dat|Sg|*
PIS	Dat|Sg|Fem
PIS	Dat|Sg|Masc
PIS	Dat|Sg|Neut
PIS	*|*|Fem
PIS	Gen|Pl|*
PIS	Gen|Pl|Fem
PIS	Gen|Pl|Masc
PIS	Gen|Pl|Neut
PIS	Gen|Sg|*
PIS	Gen|Sg|Fem
PIS	Gen|Sg|Masc
PIS	Gen|Sg|Neut
PIS	*|*|Masc
PIS	*|*|Neut
PIS	Nom|*|*
PIS	Nom|*|Fem
PIS	Nom|Pl|*
PIS	Nom|Pl|Fem
PIS	Nom|Pl|Masc
PIS	Nom|Pl|Neut
PIS	Nom|Sg|*
PIS	Nom|Sg|Fem
PIS	Nom|Sg|Masc
PIS	Nom|Sg|Neut
PIS	*|Sg|Masc
PPER	1|Acc|Pl|*
PPER	1|Acc|Pl|Fem
PPER	1|Acc|Pl|Masc
PPER	1|Acc|Sg|*
PPER	1|Acc|Sg|Fem
PPER	1|Acc|Sg|Masc
PPER	1|Dat|Pl|*
PPER	1|Dat|Pl|Fem
PPER	1|Dat|Pl|Masc
PPER	1|Dat|Sg|*
PPER	1|Dat|Sg|Fem
PPER	1|Dat|Sg|Masc
PPER	1|Nom|Pl|*
PPER	1|Nom|Pl|Fem
PPER	1|Nom|Pl|Masc
PPER	1|Nom|Sg|*
PPER	1|Nom|Sg|Fem
PPER	1|Nom|Sg|Masc
PPER	2|Acc|Pl|*
PPER    2|Acc|Pl|Fem
PPER	2|Acc|Pl|Masc
PPER	2|Acc|Sg|*
PPER    2|Acc|Sg|Fem
PPER	2|Acc|Sg|Masc
PPER	2|Dat|Pl|*
PPER    2|Dat|Pl|Fem
PPER	2|Dat|Pl|Masc
PPER	2|Dat|Sg|*
PPER    2|Dat|Sg|Fem
PPER	2|Dat|Sg|Masc
PPER	2|Nom|Pl|*
PPER    2|Nom|Pl|Fem
PPER	2|Nom|Pl|Masc
PPER	2|Nom|Sg|*
PPER	2|Nom|Sg|Fem
PPER	2|Nom|Sg|Masc
PPER	3|Acc|*|*
PPER	3|Acc|Pl|*
PPER	3|Acc|Pl|Fem
PPER	3|Acc|Pl|Masc
PPER	3|Acc|Pl|Neut
PPER	3|Acc|Sg|*
PPER	3|Acc|Sg|Fem
PPER	3|Acc|Sg|Masc
PPER	3|Acc|Sg|Neut
PPER	3|Dat|*|*
PPER	3|Dat|Pl|*
PPER	3|Dat|Pl|Fem
PPER	3|Dat|Pl|Masc
PPER	3|Dat|Pl|Neut
PPER	3|Dat|Sg|*
PPER	3|Dat|Sg|Fem
PPER	3|Dat|Sg|Masc
PPER	3|Dat|Sg|Neut
PPER	3|Gen|Pl|*
PPER	3|Gen|Pl|Fem
PPER	3|Gen|Pl|Masc
PPER	3|Gen|Pl|Neut
PPER	3|Gen|Sg|*
PPER	3|Gen|Sg|Fem
PPER	3|Gen|Sg|Masc
PPER	3|Gen|Sg|Neut
PPER	3|Nom|*|*
PPER	3|Nom|Pl|*
PPER	3|Nom|Pl|Fem
PPER	3|Nom|Pl|Masc
PPER	3|Nom|Pl|Neut
PPER	3|Nom|Sg|*
PPER	3|Nom|Sg|Fem
PPER	3|Nom|Sg|Masc
PPER	3|Nom|Sg|Neut
PPER	_
PPOSAT	_
PPOSAT	Acc|Pl|*
PPOSAT	Acc|Pl|Fem
PPOSAT	Acc|Pl|Masc
PPOSAT	Acc|Pl|Neut
PPOSAT	Acc|Sg|*
PPOSAT	Acc|Sg|Fem
PPOSAT	Acc|Sg|Masc
PPOSAT	Acc|Sg|Neut
PPOSAT	Dat|*|*
PPOSAT	Dat|Pl|*
PPOSAT	Dat|Pl|Fem
PPOSAT	Dat|Pl|Masc
PPOSAT	Dat|Pl|Neut
PPOSAT	Dat|Sg|*
PPOSAT	Dat|Sg|Fem
PPOSAT	Dat|Sg|Masc
PPOSAT	Dat|Sg|Neut
PPOSAT	Gen|*|*
PPOSAT	Gen|Pl|*
PPOSAT	Gen|Pl|Fem
PPOSAT	Gen|Pl|Masc
PPOSAT	Gen|Pl|Neut
PPOSAT	Gen|Sg|*
PPOSAT	Gen|Sg|Fem
PPOSAT	Gen|Sg|Masc
PPOSAT	Gen|Sg|Neut
PPOSAT	Nom|Pl|*
PPOSAT	Nom|Pl|Fem
PPOSAT	Nom|Pl|Masc
PPOSAT	Nom|Pl|Neut
PPOSAT	Nom|Sg|*
PPOSAT	Nom|Sg|Fem
PPOSAT	Nom|Sg|Masc
PPOSAT	Nom|Sg|Neut
PPOSAT	*|Pl|Fem
PPOSAT	*|Sg|Fem
PPOSS	Acc|Pl|*
PPOSS   Acc|Pl|Fem
PPOSS   Acc|Pl|Masc
PPOSS	Acc|Pl|Neut
PPOSS   Acc|Sg|*
PPOSS   Acc|Sg|Fem
PPOSS   Acc|Sg|Masc
PPOSS	Acc|Sg|Neut
PPOSS	Dat|Pl|*
PPOSS	Dat|Pl|Fem
PPOSS   Dat|Pl|Masc
PPOSS   Dat|Pl|Neut
PPOSS	Dat|Sg|*
PPOSS	Dat|Sg|Fem
PPOSS   Dat|Sg|Masc
PPOSS   Dat|Sg|Neut
PPOSS	Gen|Pl|*
PPOSS	Gen|Pl|Fem
PPOSS   Gen|Pl|Masc
PPOSS   Gen|Pl|Neut
PPOSS	Gen|Sg|*
PPOSS	Gen|Sg|Fem
PPOSS   Gen|Sg|Masc
PPOSS   Gen|Sg|Neut
PPOSS	Nom|Pl|*
PPOSS	Nom|Pl|Fem
PPOSS   Nom|Pl|Masc
PPOSS   Nom|Pl|Neut
PPOSS	Nom|Sg|*
PPOSS	Nom|Sg|Fem
PPOSS   Nom|Sg|Masc
PPOSS   Nom|Sg|Neut
PRELAT	Gen|Pl|*
PRELAT	Gen|Pl|Fem
PRELAT	Gen|Pl|Masc
PRELAT	Gen|Pl|Neut
PRELAT	Gen|Sg|*
PRELAT	Gen|Sg|Fem
PRELAT	Gen|Sg|Masc
PRELAT	Gen|Sg|Neut
PRELS	_
PRELS	Acc|Pl|*
PRELS	Acc|Pl|Fem
PRELS	Acc|Pl|Masc
PRELS	Acc|Pl|Neut
PRELS	Acc|Sg|*
PRELS	Acc|Sg|Fem
PRELS	Acc|Sg|Masc
PRELS	Acc|Sg|Neut
PRELS	Dat|Pl|*
PRELS	Dat|Pl|Fem
PRELS	Dat|Pl|Masc
PRELS	Dat|Pl|Neut
PRELS	Dat|Sg|*
PRELS	Dat|Sg|Fem
PRELS	Dat|Sg|Masc
PRELS	Dat|Sg|Neut
PRELS   Gen|Pl|*
PRELS	Gen|Pl|Fem
PRELS   Gen|Pl|Masc
PRELS	Gen|Pl|Neut
PRELS   Gen|Sg|*
PRELS	Gen|Sg|Fem
PRELS	Gen|Sg|Masc
PRELS	Gen|Sg|Neut
PRELS	Nom|Pl|*
PRELS	Nom|Pl|Fem
PRELS	Nom|Pl|Masc
PRELS	Nom|Pl|Neut
PRELS	Nom|Sg|*
PRELS	Nom|Sg|Fem
PRELS	Nom|Sg|Masc
PRELS	Nom|Sg|Neut
PRF	1|Acc|Pl
PRF	1|Acc|Sg
PRF	1|Dat|Pl
PRF	1|Dat|Sg
PRF	2|Acc|Pl
PRF	2|Acc|Sg
PRF 2|Dat|Pl
PRF 2|Dat|Sg
PRF	3|Acc|Pl
PRF	3|Acc|Sg
PRF	3|Dat|Pl
PRF	3|Dat|Sg
PROAV	_
PTKA	_
PTKANT	_
PTKNEG	_
PTKVZ	_
PTKZU	_
PWAT	_
PWAT	Acc|Pl|Fem
PWAT	Acc|Pl|Masc
PWAT	Acc|Pl|Neut
PWAT	Acc|Sg|Fem
PWAT	Acc|Sg|Masc
PWAT	Acc|Sg|Neut
PWAT	Dat|Pl|Fem
PWAT	Dat|Pl|Masc
PWAT	Dat|Pl|Neut
PWAT	Dat|Sg|Fem
PWAT	Dat|Sg|Masc
PWAT	Dat|Sg|Neut
PWAT	Gen|Sg|*
PWAT	Gen|Sg|Fem
PWAT	Nom|Pl|*
PWAT	Nom|Pl|Fem
PWAT	Nom|Pl|Masc
PWAT	Nom|Pl|Neut
PWAT	Nom|Sg|Fem
PWAT	Nom|Sg|Masc
PWAT	Nom|Sg|Neut
PWAV	_
PWS	    Acc|Pl|Fem
PWS	    Acc|Pl|Neut
PWS	    Acc|Sg|Masc
PWS	    Acc|Sg|Neut
PWS	    Dat|Sg|*
PWS	    Dat|Sg|Masc
PWS	    Gen|*|*
PWS	    Nom|Pl|*
PWS	    Nom|Pl|Masc
PWS	    Nom|Sg|*
PWS	    Nom|Sg|Masc
PWS	    Nom|Sg|Neut
TRUNC	_
TRUNC	3|Pl|Pres|Ind
TRUNC	3|Sg|Pres|Ind
TRUNC	Acc|Pl|*
TRUNC	Acc|Pl|Fem
TRUNC	Acc|Pl|Masc
TRUNC	Acc|Pl|Neut
TRUNC	Acc|Sg|Fem
TRUNC	Acc|Sg|Masc
TRUNC	Acc|Sg|Neut
TRUNC	Dat|Pl|*
TRUNC	Dat|Pl|Fem
TRUNC	Dat|Pl|Masc
TRUNC	Dat|Pl|Neut
TRUNC	Dat|Sg|*
TRUNC	Dat|Sg|Fem
TRUNC	Dat|Sg|Masc
TRUNC	Dat|Sg|Neut
TRUNC	Gen|Pl|*
TRUNC	Gen|Pl|Fem
TRUNC	Gen|Pl|Masc
TRUNC	Gen|Pl|Neut
TRUNC	Gen|Sg|Fem
TRUNC	Gen|Sg|Masc
TRUNC	Gen|Sg|Neut
TRUNC	Inf
TRUNC	Nom|Pl|*
TRUNC	Nom|Pl|Fem
TRUNC	Nom|Pl|Masc
TRUNC	Nom|Pl|Neut
TRUNC	Nom|Sg|Fem
TRUNC	Nom|Sg|Masc
TRUNC	Nom|Sg|Neut
TRUNC	Pos|*|*|*
TRUNC	Pos|Acc|Pl|Fem
TRUNC	Pos|Acc|Pl|Masc
TRUNC	Pos|Acc|Sg|Fem
TRUNC	Pos|Acc|Sg|Masc
TRUNC	Pos|Acc|Sg|Neut
TRUNC	Pos|Dat|Pl|Fem
TRUNC	Pos|Dat|Pl|Masc
TRUNC	Pos|Dat|Pl|Neut
TRUNC	Pos|Dat|Sg|Fem
TRUNC	Pos|Dat|Sg|Masc
TRUNC	Pos|Gen|Pl|Fem
TRUNC	Pos|Gen|Pl|Masc
TRUNC	Pos|Gen|Pl|Neut
TRUNC	Pos|Gen|Sg|Fem
TRUNC	Pos|Gen|Sg|Masc
TRUNC	Pos|Gen|Sg|Neut
TRUNC	Pos|Nom|Pl|*
TRUNC	Pos|Nom|Pl|Fem
TRUNC	Pos|Nom|Pl|Masc
TRUNC	Pos|Nom|Pl|Neut
TRUNC	Pos|Nom|Sg|Fem
TRUNC	Pos|Nom|Sg|Masc
TRUNC	Pos|Nom|Sg|Neut
TRUNC	Psp
TRUNC	*|Sg|Fem
VAFIN	1|Pl|Past|Ind
VAFIN	1|Pl|Past|Subj
VAFIN	1|Pl|Pres|Ind
VAFIN	1|Pl|Pres|Subj
VAFIN	1|Sg|Past|Ind
VAFIN	1|Sg|Past|Subj
VAFIN	1|Sg|Pres|Ind
VAFIN	1|Sg|Pres|Subj
VAFIN   1|Pl|Past|Ind
VAFIN   1|Pl|Past|Subj
VAFIN	2|Pl|Pres|Ind
VAFIN   2|Pl|Pres|Subj
VAFIN	2|Sg|Past|Ind
VAFIN   2|Sg|Past|Subj
VAFIN	2|Sg|Pres|Ind
VAFIN   2|Sg|Pres|Subj
VAFIN	3|Pl|Past|Ind
VAFIN	3|Pl|Past|Subj
VAFIN	3|Pl|Pres|Ind
VAFIN	3|Pl|Pres|Subj
VAFIN	3|Sg|Past|Ind
VAFIN	3|Sg|Past|Subj
VAFIN	3|Sg|Pres|Ind
VAFIN	3|Sg|Pres|Subj
VAIMP	1|Pl|Pres|Ind
VAIMP	2|Pl|Imp
VAIMP	2|Sg|Imp
VAIMP	3|Pl|Pres|Ind
VAINF	Inf
VAPP	Psp
VMFIN	1|Pl|Past|Ind
VMFIN	1|Pl|Past|Subj
VMFIN	1|Pl|Pres|Ind
VMFIN   1|Pl|Pres|Subj
VMFIN	1|Sg|Past|Ind
VMFIN	1|Sg|Past|Subj
VMFIN	1|Sg|Pres|Ind
VMFIN   1|Sg|Pres|Subj
VMFIN   2|Pl|Past|Ind
VMFIN   2|Pl|Past|Subj
VMFIN	2|Pl|Pres|Ind
VMFIN   2|Pl|Pres|Subj
VMFIN   2|Sg|Past|Ind
VMFIN   2|Sg|Past|Subj
VMFIN	2|Sg|Pres|Ind
VMFIN	2|Sg|Pres|Subj
VMFIN	3|Pl|Past|Ind
VMFIN	3|Pl|Past|Subj
VMFIN	3|Pl|Pres|Ind
VMFIN	3|Pl|Pres|Subj
VMFIN	3|Sg|Past|Ind
VMFIN	3|Sg|Past|Subj
VMFIN	3|Sg|Pres|Ind
VMFIN	3|Sg|Pres|Subj
VMINF	Inf
VMPP	Psp
VVFIN	1|Pl|Past|Ind
VVFIN	1|Pl|Past|Subj
VVFIN	1|Pl|Pres|Ind
VVFIN   1|Pl|Pres|Subj
VVFIN	1|Sg|Past|Ind
VVFIN	1|Sg|Past|Subj
VVFIN	1|Sg|Pres|Ind
VVFIN	1|Sg|Pres|Subj
VVFIN	2|Pl|Past|Ind
VVFIN   2|Pl|Past|Subj
VVFIN	2|Pl|Pres|Ind
VVFIN   2|Pl|Pres|Subj
VVFIN	2|Sg|Past|Ind
VVFIN	2|Sg|Past|Subj
VVFIN	2|Sg|Pres|Ind
VVFIN   2|Sg|Pres|Subj
VVFIN	3|Pl|Past|Ind
VVFIN	3|Pl|Past|Subj
VVFIN	3|Pl|Pres|Ind
VVFIN	3|Pl|Pres|Subj
VVFIN	3|Sg|Past|Ind
VVFIN	3|Sg|Past|Subj
VVFIN	3|Sg|Pres|Ind
VVFIN	3|Sg|Pres|Subj
VVIMP	1|Pl|Pres|Ind
VVIMP	2|Pl|Imp
VVIMP	2|Sg|Imp
VVIMP	3|Pl|Pres|Ind
VVINF	Inf
VVIZU	Infzu
VVPP	Prp
VVPP	Psp
XY	_
XY	Nom|Sg|*
XY	Nom|Sg|Fem
XY	Nom|Sg|Masc
end_of_list
    ;
    # Protect from editors that replace tabs by spaces.
    $list =~ s/[ \t]+/\t/g;
    my @list = split(/\r?\n/, $list);
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::DE::Conll2009 - Driver for the German tagset of the CoNLL 2009 Shared Task.

=head1 VERSION

version 3.015

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::DE::Conll2009;
  my $driver = Lingua::Interset::Tagset::DE::Conll2009->new();
  my $fs = $driver->decode("NN\tNom|Sg|Masc");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('de::conll2009', "NN\tNom|Sg|Masc");

=head1 DESCRIPTION

Interset driver for the German tagset of the CoNLL 2009 Shared Task.
Unlike in 2006, the CoNLL 2009 tagset also includes morphological features.
CoNLL 2009 tagsets in Interset are traditionally two values separated by tab.
The values come from the CoNLL columns POS and FEAT. For German,
these values are trivially derived from the Stuttgart-Tübingen Tagset.
Thus this driver is only a translation layer above the C<de::stts> driver.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::DE::Stts>,
L<Lingua::Interset::Tagset::DE::Conll>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
