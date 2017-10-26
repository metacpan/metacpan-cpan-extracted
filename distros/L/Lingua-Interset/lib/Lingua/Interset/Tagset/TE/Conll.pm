# ABSTRACT: Driver for the Telugu tagset of the ICON 2009 and 2010 Shared Tasks, as used in the CoNLL data format.
# Documentation:
# http://ltrc.iiit.ac.in/nlptools2010/documentation.php
# http://ltrc.iiit.ac.in/MachineTrans/publications/technicalReports/tr031/posguidelines.pdf
# Copyright © 2011 Loganathan Ramasamy <ramasamy@ufal.mff.cuni.cz>
# Copyright © 2015 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::TE::Conll;
use strict;
use warnings;
our $VERSION = '3.007';

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
    return 'te::conll';
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
            # These tags come in the POS column of the CoNLL data format (while CPOS contains so-called chunk tag).
            # Many tags come in two flavors, with and without final 'C'. The 'C' means "compound". Nevertheless, the compounds do not occur in the current data.
            # Documentation contains many tags that do not occur in actual data. The following tags have been observed in the data:
            # NN (4924), VM (2854), NNP (1540), PRP (1096), JJ (536), CC (448), NULL (388), NST (332), SYM (252), RB (230), WQ (110),
            # RP (96), QF (20), QC (16), INJ (14), NEG (6), VAUX (6), DEM (4), XC (4), PSP (2), RDP (2)
            # common nouns
            'NN'   => ['pos' => 'noun', 'nountype' => 'com'],
            'NNC'  => ['pos' => 'noun', 'nountype' => 'com'],
            # proper nouns
            'NNP'  => ['pos' => 'noun', 'nountype' => 'prop'],
            'NNPC' => ['pos' => 'noun', 'nountype' => 'prop'],
            # location nouns
            # These words are grammatically nouns but they are used to form a sort of postpositions. Often but not always they specify location.
            # For instance, "on the table" would be constructed as "the table's upper side", and the word for "upper side" would be tagged NST.
            'NST'  => ['pos' => 'noun', 'adpostype' => 'post'],
            'NSTC' => ['pos' => 'noun', 'adpostype' => 'post'],
            # pronouns
            'PRP'  => ['pos' => 'noun', 'prontype' => 'prs'],
            'PRPC' => ['pos' => 'noun', 'prontype' => 'prs'],
            # question words
            'WQ'   => ['pos' => 'noun', 'prontype' => 'int'],
            # adjectives
            'JJ'   => ['pos' => 'adj'],
            'JJC'  => ['pos' => 'adj'],
            # demonstratives
            'DEM'  => ['pos' => 'adj', 'prontype' => 'dem'],
            # quantifiers
            'QF'   => ['pos' => 'adj', 'prontype' => 'ind'],
            'QFC'  => ['pos' => 'adj', 'prontype' => 'ind'],
            # numerals
            'QC'   => ['pos' => 'num', 'numtype' => 'card'],
            'QCC'  => ['pos' => 'num', 'numtype' => 'card'],
            'QO'   => ['pos' => 'adj', 'numtype' => 'ord'],
            # classifiers
            # A classifier is a word or morpheme used to classify a noun according to its meaning.
            # (http://en.wikipedia.org/wiki/Classifier_%28linguistics%29)
            # Example: padi mandi pillalu = lit. ten persons children ("mandi" is classifier).
            'CL'   => ['pos' => 'noun', 'nountype' => 'class'],
            # main verbs (documentation says "verb-finite", are they really always finite forms?)
            'VM'   => ['pos' => 'verb'],
            'VMC'  => ['pos' => 'verb'],
            # auxiliary verbs
            'VAUX' => ['pos' => 'verb', 'verbtype' => 'aux'],
            # adverbs
            'RB'   => ['pos' => 'adv'],
            'RBC'  => ['pos' => 'adv'],
            # intensifiers
            'INTF' => ['pos' => 'adv', 'advtype' => 'deg'],
            # negation
            'NEG'  => ['pos' => 'part', 'prontype' => 'neg', 'negativeness' => 'neg'],
            # postpositions
            'PSP'  => ['pos' => 'adp', 'adpostype' => 'post'],
            # conjunctions
            'CC'   => ['pos' => 'conj'],
            # quotatives
            # A quotative introduces a quote. Typically, it is a verb.
            # Bengali: she Ashbe     bole      bolechilo
            # lit.:    he  will-come QUOTATIVE said
            # English: He said that he would come.
            'UT'   => ['pos' => 'conj', 'conjtype' => 'sub'],
            # particles
            'RP'   => ['pos' => 'part'],
            # interjections
            'INJ'  => ['pos' => 'int'],
            # reduplicatives
            'RDP'  => ['echo' => 'rdp'],
            # echo words
            'ECH'  => ['echo' => 'ech'],
            # undocumented (compounds???)
            'XC'   => [],
            # punctuation
            # Examples (the corpus contains European punctuation):
            # , . - " ? ; : !
            'SYM'  => ['pos' => 'punc'],
            # foreign or unknown words
            'UNK'  => ['foreign' => 'yes'],
            # The 'NULL' tag is used for artificial NULL nodes.
            'NULL' => ['other' => {'pos' => 'null'}]
        },
        'encode_map' =>

            { 'pos' => { 'noun' => { 'adpostype' => { 'post' => 'NST',
                                                      '@'    => { 'prontype' => { ''    => { 'nountype' => { 'prop'  => 'NNP',
                                                                                                             'class' => 'CL',
                                                                                                             '@'     => 'NN' }},
                                                                                  'int' => 'WQ',
                                                                                  '@'   => 'PRP' }}}},
                         'adj'  => { 'numtype' => { 'ord' => 'QO',
                                                    '@'   => { 'prontype' => { 'dem' => 'DEM',
                                                                               'ind' => 'QF',
                                                                               'tot' => 'QF',
                                                                               'neg' => 'QF',
                                                                               '@'   => 'JJ' }}}},
                         'num'  => 'QC',
                         'verb' => { 'verbtype' => { 'aux' => 'VAUX',
                                                     '@'   => 'VM' }},
                         'adv'  => { 'advtype' => { 'deg' => 'INTF',
                                                    '@'   => 'RB' }},
                         'adp'  => 'PSP',
                         'conj' => { 'conjtype' => { 'sub' => 'UT',
                                                     '@'   => 'CC' }},
                         'part' => { 'prontype' => { 'neg' => 'NEG',
                                                     '@'   => 'RP' }},
                         'int'  => 'INJ',
                         'punc' => 'SYM',
                         '@'    => { 'echo' => { 'rdp' => 'RDP',
                                                 'ech' => 'ECH',
                                                 '@'   => { 'other/pos' => { 'null' => 'NULL',
                                                                             '@'    => 'XC' }}}}}}
    );
    # GENDER ####################
    $atoms{gend} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'm'  => 'masc',
            'f'  => 'fem',
            'fm' => 'fem|masc',
            'fn' => 'fem|neut',
            'n'  => 'neut'
        }
    );
    # NUMBER ####################
    $atoms{num} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'sg'   => 'sing',
            'pl'   => 'plur',
            'dual' => 'dual'
        }
    );
    # PERSON ####################
    $atoms{pers} = $self->create_atom
    (
        'surfeature' => 'person',
        'decode_map' =>
        {
            '1'   => ['person' => '1'],
            '2'   => ['person' => '2'],
            '3'   => ['person' => '3'],
            ###!!! There are also pers-4, pers-5, pers-6 and pers-7. So far I have not been able to figure out what these values mean.
            '4'   => ['other' => {'person' => '4'}],
            '5'   => ['other' => {'person' => '5'}],
            '6'   => ['other' => {'person' => '6'}],
            '7'   => ['other' => {'person' => '7'}],
            'any' => ['person' => '1|2|3']
        },
        'encode_map' =>

            { 'other/person' => { '4' => '4',
                                  '5' => '5',
                                  '6' => '6',
                                  '7' => '7',
                                  '@' => { 'person' => { '1|2|3' => 'any',
                                                         '1'     => '1',
                                                         '2'     => '2',
                                                         '3'     => '3' }}}}
    );
    # CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'd' => 'nom', # direct
            'o' => 'acc'  # oblique
        }
    );
    # VOICE ####################
    $atoms{voicetype} = $self->create_simple_atom
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
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset('te::conll');
    my $atoms = $self->atoms();
    # Two components: part of speech and features
    # Bengali CoNLL files are converted from the Shakti Standard Format.
    # The CPOS column contains the chunk tag and is not considered part of the tag for this driver.
    # The POS column contains part of speech of the chunk headword.
    # example: NN\tcat-n|gend-|num-sg|pers-|case-d|vib-0|tam-0
    my ($pos, $features) = split(/\s+/, $tag);
    $features = '' if($features eq '_');
    my @features_conll = split(/\|/, $features);
    my %features_conll;
    foreach my $f (@features_conll)
    {
        if($f =~ m/^(\w+)-(.+)$/)
        {
            $features_conll{$1} = $2;
        }
        else
        {
            $features_conll{$f} = $f;
        }
    }
    $atoms->{pos}->decode_and_merge_hard($pos, $fs);
    foreach my $name ('gend', 'num', 'pers', 'case')
    {
        if(defined($features_conll{$name}) && $features_conll{$name} ne '')
        {
            $atoms->{$name}->decode_and_merge_hard($features_conll{$name}, $fs);
        }
    }
    ###!!! Proper decoding of vibhakti and tense-aspect-modality is not implemented yet.
    if(defined($features_conll{vib}) && $features_conll{vib} ne '')
    {
        $fs->set_other_subfeature('vib', $features_conll{vib});
    }
    if(defined($features_conll{tam}) && $features_conll{tam} ne '')
    {
        $fs->set_other_subfeature('tam', $features_conll{tam});
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
    my $pos = $atoms->{pos}->encode($fs);
    my @feature_names = ('gend', 'num', 'pers', 'case', 'vib', 'tam');
    my @features;
    foreach my $name (@feature_names)
    {
        my $value = '';
        if($name =~ m/^(vib|tam)$/)
        {
            $value = $fs->get_other_subfeature('te::conll', $name);
        }
        else
        {
            if(!defined($atoms->{$name}))
            {
                confess("Cannot find atom for '$name'");
            }
            $value = $atoms->{$name}->encode($fs);
        }
        # The Hyderabad CoNLL files always name all features including those with empty values.
        push(@features, "$name-$value");
    }
    my $features = '_';
    if(scalar(@features) > 0)
    {
        $features = join('|', @features);
    }
    my $tag = "$pos\t$features";
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags. These are tag occurrences collected
# from the corpus, i.e. other tags probably exist but were not seen here. We
# have added manually tags with empty 'vib' and 'tam' to facilitate generating
# permitted tags with empty 'other' feature.
# Only the POS and FEATS columns of the CoNLL file are used (no CPOS, which
# actually contains the chunk tag).
# The cat, poslcat, pbank, stype and voicetype features were removed.
# Zero values of the vib and tam features were replaced by empty values.
# 597 tags
# Added feature combinations that result from erasing the 'other' feature.
# 664 tags
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
CC	gend-|num-|pers-|case-|vib-|tam-
CL	gend-|num-pl|pers-|case-d|vib-|tam-
CL	gend-|num-pl|pers-|case-|vib-ni|tam-ni
CL	gend-|num-pl|pers-|case-|vib-nu|tam-nu
CL	gend-|num-pl|pers-|case-|vib-|tam-
DEM	gend-fn|num-sg|pers-3|case-|vib-|tam-
DEM	gend-fn|num-sg|pers-3|case-|vib-|tam-0_o
ECH	gend-|num-sg|pers-|case-|vib-gA|tam-gA
ECH	gend-|num-sg|pers-|case-|vib-|tam-
INTF	gend-|num-|pers-|case-|vib-|tam-
JJ	gend-|num-pl|pers-|case-|vib-lAMti_xi|tam-lAMti_xi_0
JJ	gend-|num-pl|pers-|case-|vib-|tam-
JJ	gend-|num-sg|pers-2|case-|vib-AjFArWa|tam-AjFArWa
JJ	gend-|num-sg|pers-2|case-|vib-|tam-
JJ	gend-|num-sg|pers-|case-d|vib-|tam-
JJ	gend-|num-sg|pers-|case-o|vib-|tam-
JJ	gend-|num-sg|pers-|case-o|vib-|tam-0_adj
JJ	gend-|num-sg|pers-|case-|vib-Ena|tam-Ena
JJ	gend-|num-sg|pers-|case-|vib-gA|tam-gA
JJ	gend-|num-sg|pers-|case-|vib-lAti|tam-lAti
JJ	gend-|num-sg|pers-|case-|vib-vi|tam-vi
JJ	gend-|num-sg|pers-|case-|vib-xi_0|tam-xi_0_o
JJ	gend-|num-sg|pers-|case-|vib-xi|tam-xi_adj
JJ	gend-|num-sg|pers-|case-|vib-|tam-
JJ	gend-|num-sg|pers-|case-|vib-|tam-0_e
JJ	gend-|num-|pers-|case-|vib-e|tam-e_avy
JJ	gend-|num-|pers-|case-|vib-gA|tam-gA_adj
JJ	gend-|num-|pers-|case-|vib-|tam-
JJ	gend-|num-|pers-|case-|vib-|tam-0_adj
NEG	gend-|num-|pers-|case-|vib-|tam-
NN	gend-fm|num-pl|pers-3|case-|vib-xi|tam-xi
NN	gend-fm|num-pl|pers-3|case-|vib-|tam-
NN	gend-fn|num-sg|pers-3|case-|vib-A|tam-A
NN	gend-fn|num-sg|pers-3|case-|vib-ki|tam-ki
NN	gend-fn|num-sg|pers-3|case-|vib-xi|tam-xi
NN	gend-fn|num-sg|pers-3|case-|vib-|tam-
NN	gend-f|num-sg|pers-3|case-|vib-xi|tam-xi
NN	gend-f|num-sg|pers-3|case-|vib-|tam-
NN	gend-|num-pl|pers-|case-d|vib-0_kUdA|tam-
NN	gend-|num-pl|pers-|case-d|vib-0_mAwraM|tam-
NN	gend-|num-pl|pers-|case-d|vib-0_sEwaM|tam-
NN	gend-|num-pl|pers-|case-d|vib-ru|tam-ru
NN	gend-|num-pl|pers-|case-d|vib-|tam-
NN	gend-|num-pl|pers-|case-o|vib-0_kosaM|tam-ti
NN	gend-|num-pl|pers-|case-o|vib-0_mIxa|tam-ti
NN	gend-|num-pl|pers-|case-o|vib-0_nuMci|tam-ti
NN	gend-|num-pl|pers-|case-o|vib-0_nuMdi_kUdA|tam-ti
NN	gend-|num-pl|pers-|case-o|vib-0_nuMdi|tam-ti
NN	gend-|num-pl|pers-|case-o|vib-0_varaku|tam-ti
NN	gend-|num-pl|pers-|case-o|vib-ti|tam-ti
NN	gend-|num-pl|pers-|case-o|vib-|tam-
NN	gend-|num-pl|pers-|case-|vib-0_batti|tam-ni
NN	gend-|num-pl|pers-|case-|vib-0_kUdA|tam-ki
NN	gend-|num-pl|pers-|case-|vib-0_nuMci|tam-0_o
NN	gend-|num-pl|pers-|case-|vib-I|tam-I
NN	gend-|num-pl|pers-|case-|vib-e_vAlYlu|tam-e_vAlYlu_0
NN	gend-|num-pl|pers-|case-|vib-gAru_ki|tam-gAru_ki
NN	gend-|num-pl|pers-|case-|vib-gAru_obl|tam-gAru_obl
NN	gend-|num-pl|pers-|case-|vib-kUdA|tam-kUdA
NN	gend-|num-pl|pers-|case-|vib-ki|tam-ki
NN	gend-|num-pl|pers-|case-|vib-ki|tam-ki_V
NN	gend-|num-pl|pers-|case-|vib-lAMti_xi|tam-lAMti_xi_0
NN	gend-|num-pl|pers-|case-|vib-lA|tam-lA
NN	gend-|num-pl|pers-|case-|vib-lo|tam-lo
NN	gend-|num-pl|pers-|case-|vib-lo|tam-lo_V
NN	gend-|num-pl|pers-|case-|vib-lo|tam-lo_e
NN	gend-|num-pl|pers-|case-|vib-mIxa|tam-mIxa
NN	gend-|num-pl|pers-|case-|vib-ni|tam-ni
NN	gend-|num-pl|pers-|case-|vib-vAlYlu_kaMteV|tam-vAlYlu_kaMteV
NN	gend-|num-pl|pers-|case-|vib-vAlYlu_ki|tam-vAlYlu_ki
NN	gend-|num-pl|pers-|case-|vib-vAlYlu_lo|tam-vAlYlu_lo
NN	gend-|num-pl|pers-|case-|vib-vAlYlu_obl|tam-vAlYlu_obl
NN	gend-|num-pl|pers-|case-|vib-vAlYlu_wo|tam-vAlYlu_wo
NN	gend-|num-pl|pers-|case-|vib-vAru_obl|tam-vAru_obl
NN	gend-|num-pl|pers-|case-|vib-wopAtu|tam-wopAtu
NN	gend-|num-pl|pers-|case-|vib-wo|tam-wo
NN	gend-|num-pl|pers-|case-|vib-xi_0|tam-xi_0_e
NN	gend-|num-pl|pers-|case-|vib-xi|tam-xi_0
NN	gend-|num-pl|pers-|case-|vib-|tam-
NN	gend-|num-pl|pers-|case-|vib-|tam-0_A
NN	gend-|num-pl|pers-|case-|vib-|tam-0_e
NN	gend-|num-pl|pers-|case-|vib-|tam-0_o
NN	gend-|num-sg|pers-2|case-|vib-AjFArWa|tam-AjFArWa
NN	gend-|num-sg|pers-2|case-|vib-|tam-
NN	gend-|num-sg|pers-|case-d|vib-0_aMxulo|tam-
NN	gend-|num-sg|pers-|case-d|vib-0_guriMci|tam-
NN	gend-|num-sg|pers-|case-d|vib-0_kUdA|tam-
NN	gend-|num-sg|pers-|case-d|vib-0_koVraku|tam-
NN	gend-|num-sg|pers-|case-d|vib-0_kosaM|tam-
NN	gend-|num-sg|pers-|case-d|vib-0_lopala|tam-
NN	gend-|num-sg|pers-|case-d|vib-0_lo|tam-
NN	gend-|num-sg|pers-|case-d|vib-0_mAwraM|tam-
NN	gend-|num-sg|pers-|case-d|vib-0_nuMci|tam-
NN	gend-|num-sg|pers-|case-d|vib-0_nuMdi|tam-
NN	gend-|num-sg|pers-|case-d|vib-0_varaku|tam-
NN	gend-|num-sg|pers-|case-d|vib-0_warvAwa|tam-
NN	gend-|num-sg|pers-|case-d|vib-0_xAkA|tam-
NN	gend-|num-sg|pers-|case-d|vib-0_xvArA|tam-
NN	gend-|num-sg|pers-|case-d|vib-|tam-
NN	gend-|num-sg|pers-|case-o|vib-0_xAkA|tam-ti
NN	gend-|num-sg|pers-|case-o|vib-ti|tam-ti
NN	gend-|num-sg|pers-|case-o|vib-|tam-
NN	gend-|num-sg|pers-|case-|vib-0_batti|tam-nu
NN	gend-|num-sg|pers-|case-|vib-0_ceVMwa_nuMdi|tam-gAdu_obl
NN	gend-|num-sg|pers-|case-|vib-0_guriMci|tam-nu
NN	gend-|num-sg|pers-|case-|vib-0_kUdA|tam-gAru
NN	gend-|num-sg|pers-|case-|vib-0_kUdA|tam-ki
NN	gend-|num-sg|pers-|case-|vib-0_kUdA|tam-ni
NN	gend-|num-sg|pers-|case-|vib-0_kUdA|tam-niMci
NN	gend-|num-sg|pers-|case-|vib-0_le|tam-0_le
NN	gend-|num-sg|pers-|case-|vib-0_nuMci|tam-lo
NN	gend-|num-sg|pers-|case-|vib-0_pAtu|tam-wo
NN	gend-|num-sg|pers-|case-|vib-Ena_xi|tam-Ena_xi_0
NN	gend-|num-sg|pers-|case-|vib-aMte|tam-aMte
NN	gend-|num-sg|pers-|case-|vib-cotlo|tam-cotlo
NN	gend-|num-sg|pers-|case-|vib-gAdu|tam-gAdu
NN	gend-|num-sg|pers-|case-|vib-gAru|tam-gAru
NN	gend-|num-sg|pers-|case-|vib-gA|tam-gA
NN	gend-|num-sg|pers-|case-|vib-kAda|tam-kAda
NN	gend-|num-sg|pers-|case-|vib-kUdA|tam-kUdA
NN	gend-|num-sg|pers-|case-|vib-ki|tam-ki
NN	gend-|num-sg|pers-|case-|vib-ki|tam-ki_V
NN	gend-|num-sg|pers-|case-|vib-ki|tam-ki_e
NN	gend-|num-sg|pers-|case-|vib-kosaM|tam-kosaM
NN	gend-|num-sg|pers-|case-|vib-lAMti_xi_0|tam-lAMti_xi_0_A
NN	gend-|num-sg|pers-|case-|vib-loni|tam-loni
NN	gend-|num-sg|pers-|case-|vib-lopalaki|tam-lopalaki
NN	gend-|num-sg|pers-|case-|vib-lo|tam-lo
NN	gend-|num-sg|pers-|case-|vib-lo|tam-lo_V
NN	gend-|num-sg|pers-|case-|vib-lo|tam-lo_e
NN	gend-|num-sg|pers-|case-|vib-mIxa|tam-mIxa
NN	gend-|num-sg|pers-|case-|vib-na|tam-na
NN	gend-|num-sg|pers-|case-|vib-niMci|tam-niMci
NN	gend-|num-sg|pers-|case-|vib-ni|tam-ni
NN	gend-|num-sg|pers-|case-|vib-ni|tam-ni_A
NN	gend-|num-sg|pers-|case-|vib-nu|tam-nu
NN	gend-|num-sg|pers-|case-|vib-vAdu|tam-vAdu
NN	gend-|num-sg|pers-|case-|vib-vi|tam-vi
NN	gend-|num-sg|pers-|case-|vib-wo|tam-wo
NN	gend-|num-sg|pers-|case-|vib-wo|tam-wo_e
NN	gend-|num-sg|pers-|case-|vib-xi_0|tam-xi_0_o
NN	gend-|num-sg|pers-|case-|vib-xi_nu|tam-xi_nu
NN	gend-|num-sg|pers-|case-|vib-xi|tam-xi
NN	gend-|num-sg|pers-|case-|vib-xi|tam-xi_0
NN	gend-|num-sg|pers-|case-|vib-|tam-
NN	gend-|num-sg|pers-|case-|vib-|tam-0_A
NN	gend-|num-sg|pers-|case-|vib-|tam-0_V
NN	gend-|num-sg|pers-|case-|vib-|tam-0_e
NN	gend-|num-sg|pers-|case-|vib-|tam-0_o
NN	gend-|num-|pers-|case-|vib-0_ku|tam-
NN	gend-|num-|pers-|case-|vib-0_mAwrame|tam-
NN	gend-|num-|pers-|case-|vib-0_nuMdi|tam-an
NN	gend-|num-|pers-|case-|vib-0_wo|tam-
NN	gend-|num-|pers-|case-|vib-aMwa_0_A|tam-aMwa_0_A_adv
NN	gend-|num-|pers-|case-|vib-an|tam-an
NN	gend-|num-|pers-|case-|vib-kiMxa_yoVkka|tam-kiMxa_yoVkka_adv
NN	gend-|num-|pers-|case-|vib-ru|tam-ru
NN	gend-|num-|pers-|case-|vib-xi|tam-xi_adj
NN	gend-|num-|pers-|case-|vib-|tam-
NN	gend-|num-|pers-|case-|vib-|tam-0_adj
NNP	gend-|num-pl|pers-|case-d|vib-|tam-
NNP	gend-|num-pl|pers-|case-|vib-ki|tam-ki
NNP	gend-|num-pl|pers-|case-|vib-|tam-
NNP	gend-|num-pl|pers-|case-|vib-|tam-0_o
NNP	gend-|num-sg|pers-|case-d|vib-0_cewa|tam-
NNP	gend-|num-sg|pers-|case-d|vib-0_kUdA|tam-
NNP	gend-|num-sg|pers-|case-d|vib-0_kosaM|tam-
NNP	gend-|num-sg|pers-|case-d|vib-0_lo|tam-
NNP	gend-|num-sg|pers-|case-d|vib-0_nuMci|tam-
NNP	gend-|num-sg|pers-|case-d|vib-|tam-
NNP	gend-|num-sg|pers-|case-o|vib-ti|tam-ti
NNP	gend-|num-sg|pers-|case-o|vib-|tam-
NNP	gend-|num-sg|pers-|case-|vib-0_kUdA|tam-ki
NNP	gend-|num-sg|pers-|case-|vib-ki|tam-ki
NNP	gend-|num-sg|pers-|case-|vib-ki|tam-ki_V
NNP	gend-|num-sg|pers-|case-|vib-ki|tam-ki_e
NNP	gend-|num-sg|pers-|case-|vib-lo|tam-lo
NNP	gend-|num-sg|pers-|case-|vib-ni|tam-ni
NNP	gend-|num-sg|pers-|case-|vib-ni|tam-ni_e
NNP	gend-|num-sg|pers-|case-|vib-nu|tam-nu
NNP	gend-|num-sg|pers-|case-|vib-wo|tam-wo
NNP	gend-|num-sg|pers-|case-|vib-xi_0|tam-xi_0_A
NNP	gend-|num-sg|pers-|case-|vib-xi|tam-xi
NNP	gend-|num-sg|pers-|case-|vib-xi|tam-xi_0
NNP	gend-|num-sg|pers-|case-|vib-|tam-
NNP	gend-|num-sg|pers-|case-|vib-|tam-0_V
NNP	gend-|num-sg|pers-|case-|vib-|tam-0_e
NNP	gend-|num-|pers-|case-|vib-0_nuMdi|tam-
NNP	gend-|num-|pers-|case-|vib-0_wo|tam-
NNP	gend-|num-|pers-|case-|vib-|tam-
NST	gend-|num-sg|pers-|case-d|vib-0_kUdA|tam-
NST	gend-|num-sg|pers-|case-d|vib-0_nuMdi|tam-
NST	gend-|num-sg|pers-|case-d|vib-|tam-
NST	gend-|num-sg|pers-|case-|vib-ki|tam-ki
NST	gend-|num-sg|pers-|case-|vib-na|tam-na
NST	gend-|num-sg|pers-|case-|vib-niMci|tam-niMci
NST	gend-|num-sg|pers-|case-|vib-ni|tam-ni_e
NST	gend-|num-sg|pers-|case-|vib-varaku|tam-varaku
NST	gend-|num-sg|pers-|case-|vib-|tam-
NST	gend-|num-sg|pers-|case-|vib-|tam-0_V
NST	gend-|num-|pers-|case-|vib-0_e|tam-0_e_adv
NST	gend-|num-|pers-|case-|vib-0_kUdA|tam-0_adv
NST	gend-|num-|pers-|case-|vib-0_nuMci|tam-i
NST	gend-|num-|pers-|case-|vib-0_nuMci|tam-yoVkka_adv
NST	gend-|num-|pers-|case-|vib-0_o|tam-0_o_adv
NST	gend-|num-|pers-|case-|vib-0_varaku|tam-yoVkka_adv
NST	gend-|num-|pers-|case-|vib-V|tam-V_avy
NST	gend-|num-|pers-|case-|vib-ina|tam-ina
NST	gend-|num-|pers-|case-|vib-ku|tam-ku_adv
NST	gend-|num-|pers-|case-|vib-lo|tam-lo_adv
NST	gend-|num-|pers-|case-|vib-yoVkka|tam-yoVkka_adv
NST	gend-|num-|pers-|case-|vib-|tam-
NST	gend-|num-|pers-|case-|vib-|tam-0_adv
PRP	gend-fm|num-pl|pers-3|case-d|vib-nu|tam-nu
PRP	gend-fm|num-pl|pers-3|case-d|vib-|tam-
PRP	gend-fm|num-pl|pers-3|case-o|vib-ki|tam-ki
PRP	gend-fm|num-pl|pers-3|case-o|vib-ti|tam-ti
PRP	gend-fm|num-pl|pers-3|case-o|vib-|tam-
PRP	gend-fm|num-pl|pers-3|case-|vib-ki|tam-ki
PRP	gend-fm|num-pl|pers-3|case-|vib-lo|tam-lo
PRP	gend-fm|num-pl|pers-3|case-|vib-mIxa|tam-mIxa
PRP	gend-fm|num-pl|pers-3|case-|vib-|tam-
PRP	gend-fn|num-pl|pers-3|case-d|vib-|tam-
PRP	gend-fn|num-pl|pers-3|case-|vib-lo|tam-lo
PRP	gend-fn|num-pl|pers-3|case-|vib-ni|tam-ni
PRP	gend-fn|num-pl|pers-3|case-|vib-|tam-
PRP	gend-fn|num-pl|pers-3|case-|vib-|tam-0_V
PRP	gend-fn|num-sg|pers-3|case-d|vib-|tam-
PRP	gend-fn|num-sg|pers-3|case-o|vib-0_guriMcayinA|tam-ti
PRP	gend-fn|num-sg|pers-3|case-o|vib-0_valana_kUdA|tam-ti
PRP	gend-fn|num-sg|pers-3|case-o|vib-0_valana|tam-ti
PRP	gend-fn|num-sg|pers-3|case-o|vib-0_xvArA|tam-ti
PRP	gend-fn|num-sg|pers-3|case-o|vib-ti|tam-ti
PRP	gend-fn|num-sg|pers-3|case-o|vib-|tam-
PRP	gend-fn|num-sg|pers-3|case-|vib-ki|tam-ki
PRP	gend-fn|num-sg|pers-3|case-|vib-lo|tam-lo
PRP	gend-fn|num-sg|pers-3|case-|vib-nu|tam-nu
PRP	gend-fn|num-sg|pers-3|case-|vib-valana|tam-valana
PRP	gend-fn|num-sg|pers-3|case-|vib-wo|tam-wo
PRP	gend-fn|num-sg|pers-3|case-|vib-|tam-
PRP	gend-fn|num-sg|pers-3|case-|vib-|tam-0_V
PRP	gend-fn|num-sg|pers-3|case-|vib-|tam-0_e
PRP	gend-fn|num-sg|pers-3|case-|vib-|tam-0_o
PRP	gend-f|num-sg|pers-3|case-d|vib-0_vaxxa|tam-
PRP	gend-f|num-sg|pers-3|case-d|vib-|tam-
PRP	gend-f|num-sg|pers-3|case-|vib-ki|tam-ki
PRP	gend-f|num-sg|pers-3|case-|vib-ki|tam-ki_o
PRP	gend-f|num-sg|pers-3|case-|vib-ni|tam-ni
PRP	gend-f|num-sg|pers-3|case-|vib-wo|tam-wo
PRP	gend-f|num-sg|pers-3|case-|vib-|tam-
PRP	gend-f|num-sg|pers-3|case-|vib-|tam-0_e
PRP	gend-m|num-sg|pers-3|case-d|vib-0_kUdA|tam-
PRP	gend-m|num-sg|pers-3|case-d|vib-|tam-
PRP	gend-m|num-sg|pers-3|case-o|vib-0_koVraku|tam-ti
PRP	gend-m|num-sg|pers-3|case-o|vib-0_kosaM|tam-ti
PRP	gend-m|num-sg|pers-3|case-o|vib-ti|tam-ti
PRP	gend-m|num-sg|pers-3|case-o|vib-|tam-
PRP	gend-m|num-sg|pers-3|case-|vib-ki|tam-ki
PRP	gend-m|num-sg|pers-3|case-|vib-ni|tam-ni
PRP	gend-m|num-sg|pers-3|case-|vib-nu|tam-nu
PRP	gend-m|num-sg|pers-3|case-|vib-|tam-
PRP	gend-m|num-sg|pers-3|case-|vib-|tam-0_e
PRP	gend-|num-pl|pers-1|case-o|vib-ti|tam-ti
PRP	gend-|num-pl|pers-1|case-o|vib-|tam-
PRP	gend-|num-pl|pers-1|case-|vib-|tam-
PRP	gend-|num-pl|pers-1|case-|vib-|tam-0_e
PRP	gend-|num-pl|pers-2|case-o|vib-ti|tam-ti
PRP	gend-|num-pl|pers-2|case-o|vib-|tam-
PRP	gend-|num-pl|pers-2|case-|vib-ki|tam-ki
PRP	gend-|num-pl|pers-2|case-|vib-|tam-
PRP	gend-|num-pl|pers-2|case-|vib-|tam-0_e
PRP	gend-|num-pl|pers-|case-d|vib-0_kUdA|tam-
PRP	gend-|num-pl|pers-|case-d|vib-|tam-
PRP	gend-|num-pl|pers-|case-o|vib-ti|tam-ti
PRP	gend-|num-pl|pers-|case-o|vib-|tam-
PRP	gend-|num-pl|pers-|case-|vib-e_axi|tam-e_axi_0
PRP	gend-|num-pl|pers-|case-|vib-ki|tam-ki
PRP	gend-|num-pl|pers-|case-|vib-ki|tam-ki_V
PRP	gend-|num-pl|pers-|case-|vib-lo|tam-lo
PRP	gend-|num-pl|pers-|case-|vib-ni|tam-ni_V
PRP	gend-|num-pl|pers-|case-|vib-nu|tam-nu
PRP	gend-|num-pl|pers-|case-|vib-wo|tam-wo
PRP	gend-|num-pl|pers-|case-|vib-wo|tam-wo_V
PRP	gend-|num-pl|pers-|case-|vib-|tam-
PRP	gend-|num-pl|pers-|case-|vib-|tam-0_V
PRP	gend-|num-sg|pers-1|case-d|vib-0_kUdA|tam-
PRP	gend-|num-sg|pers-1|case-d|vib-|tam-
PRP	gend-|num-sg|pers-1|case-o|vib-0_woti|tam-ti
PRP	gend-|num-sg|pers-1|case-o|vib-ti|tam-ti
PRP	gend-|num-sg|pers-1|case-o|vib-|tam-
PRP	gend-|num-sg|pers-1|case-|vib-0_kUdA|tam-ki
PRP	gend-|num-sg|pers-1|case-|vib-aMte|tam-aMte
PRP	gend-|num-sg|pers-1|case-|vib-kaMteV|tam-kaMteV
PRP	gend-|num-sg|pers-1|case-|vib-ki|tam-ki
PRP	gend-|num-sg|pers-1|case-|vib-mIxa|tam-mIxa
PRP	gend-|num-sg|pers-1|case-|vib-ni|tam-ni
PRP	gend-|num-sg|pers-1|case-|vib-wo|tam-wo
PRP	gend-|num-sg|pers-1|case-|vib-|tam-
PRP	gend-|num-sg|pers-1|case-|vib-|tam-0_e
PRP	gend-|num-sg|pers-2|case-d|vib-|tam-
PRP	gend-|num-sg|pers-2|case-o|vib-ti|tam-ti
PRP	gend-|num-sg|pers-2|case-o|vib-|tam-
PRP	gend-|num-sg|pers-2|case-|vib-0_kUdA|tam-ki
PRP	gend-|num-sg|pers-2|case-|vib-AjFArWa|tam-AjFArWa
PRP	gend-|num-sg|pers-2|case-|vib-ki|tam-ki
PRP	gend-|num-sg|pers-2|case-|vib-ki|tam-ki_e
PRP	gend-|num-sg|pers-2|case-|vib-ni|tam-ni
PRP	gend-|num-sg|pers-2|case-|vib-wo|tam-wo
PRP	gend-|num-sg|pers-2|case-|vib-|tam-
PRP	gend-|num-sg|pers-|case-d|vib-0_valana|tam-
PRP	gend-|num-sg|pers-|case-d|vib-|tam-
PRP	gend-|num-sg|pers-|case-o|vib-ti|tam-ti
PRP	gend-|num-sg|pers-|case-o|vib-|tam-
PRP	gend-|num-sg|pers-|case-|vib-e_axi_0|tam-e_axi_0_o
PRP	gend-|num-sg|pers-|case-|vib-kaMteV|tam-kaMteV
PRP	gend-|num-sg|pers-|case-|vib-ki|tam-ki
PRP	gend-|num-sg|pers-|case-|vib-ni|tam-ni
PRP	gend-|num-sg|pers-|case-|vib-wo|tam-wo
PRP	gend-|num-sg|pers-|case-|vib-xAkA|tam-xAkA
PRP	gend-|num-sg|pers-|case-|vib-|tam-
PRP	gend-|num-|pers-|case-|vib-0_kUdA|tam-
PRP	gend-|num-|pers-|case-|vib-e|tam-e_avy
PRP	gend-|num-|pers-|case-|vib-|tam-
PSP	gend-|num-sg|pers-|case-d|vib-|tam-
QC	gend-|num-sg|pers-|case-d|vib-0_nuMdi|tam-
QC	gend-|num-sg|pers-|case-d|vib-0_xAkA|tam-
QC	gend-|num-sg|pers-|case-d|vib-|tam-
QC	gend-|num-sg|pers-|case-o|vib-0_nuMci|tam-ti
QC	gend-|num-sg|pers-|case-o|vib-|tam-
QC	gend-|num-sg|pers-|case-|vib-xAkA|tam-xAkA
QC	gend-|num-sg|pers-|case-|vib-|tam-
QC	gend-|num-|pers-|case-|vib-0_nuMdi|tam-
QC	gend-|num-|pers-|case-|vib-unnara|tam-unnara
QC	gend-|num-|pers-|case-|vib-|tam-
QC	gend-|num-|pers-|case-|vib-|tam-0_adj
QF	gend-|num-pl|pers-|case-d|vib-|tam-
QF	gend-|num-pl|pers-|case-o|vib-ti|tam-ti
QF	gend-|num-pl|pers-|case-o|vib-|tam-
QF	gend-|num-sg|pers-2|case-|vib-AjFArWa|tam-AjFArWa
QF	gend-|num-sg|pers-2|case-|vib-|tam-
QF	gend-|num-sg|pers-|case-d|vib-|tam-
QF	gend-|num-sg|pers-|case-|vib-na|tam-na
QF	gend-|num-sg|pers-|case-|vib-|tam-
QF	gend-|num-|pers-|case-|vib-iMwa|tam-iMwa
QF	gend-|num-|pers-|case-|vib-|tam-
QF	gend-|num-|pers-|case-|vib-|tam-0_adj
QO	gend-|num-sg|pers-|case-d|vib-|tam-
RB	gend-|num-pl|pers-|case-|vib-gA|tam-gA
RB	gend-|num-pl|pers-|case-|vib-|tam-
RB	gend-|num-sg|pers-|case-d|vib-|tam-
RB	gend-|num-sg|pers-|case-o|vib-|tam-
RB	gend-|num-sg|pers-|case-o|vib-|tam-0_adv
RB	gend-|num-sg|pers-|case-|vib-gA|tam-gA
RB	gend-|num-sg|pers-|case-|vib-|tam-
RB	gend-|num-sg|pers-|case-|vib-|tam-0_e
RB	gend-|num-|pers-|case-|vib-A|tam-A_avy
RB	gend-|num-|pers-|case-|vib-V|tam-V_avy
RB	gend-|num-|pers-|case-|vib-akuMdA|tam-akuMdA
RB	gend-|num-|pers-|case-|vib-e|tam-e_avy
RB	gend-|num-|pers-|case-|vib-gA|tam-gA_adj
RB	gend-|num-|pers-|case-|vib-iMwa|tam-iMwa
RB	gend-|num-|pers-|case-|vib-i|tam-i
RB	gend-|num-|pers-|case-|vib-|tam-
RB	gend-|num-|pers-|case-|vib-|tam-0_adj
RDP	gend-|num-|pers-|case-|vib-|tam-
RP	gend-|num-sg|pers-|case-d|vib-|tam-
RP	gend-|num-|pers-|case-|vib-V|tam-V_avy
RP	gend-|num-|pers-|case-|vib-we|tam-we
RP	gend-|num-|pers-|case-|vib-|tam-
SYM	gend-|num-|pers-|case-|vib-|tam-
UT	gend-|num-|pers-|case-|vib-|tam-
VAUX	gend-fn|num-sg|pers-3|case-|vib-A|tam-A
VAUX	gend-fn|num-sg|pers-3|case-|vib-wA|tam-wA
VAUX	gend-fn|num-sg|pers-3|case-|vib-|tam-
VAUX	gend-|num-|pers-|case-|vib-ina|tam-ina
VAUX	gend-|num-|pers-|case-|vib-|tam-
VM	gend-fm|num-sg|pers-3|case-|vib-e_axi|tam-e_axi_0
VM	gend-fm|num-sg|pers-3|case-|vib-e_vAdu_avvu+a|tam-e_vAdu_0
VM	gend-fm|num-sg|pers-3|case-|vib-|tam-
VM	gend-fn|num-sg|pers-3|case-|vib-A_ani|tam-A_ani
VM	gend-fn|num-sg|pers-3|case-|vib-A|tam-A
VM	gend-fn|num-sg|pers-3|case-|vib-A|tam-A_A
VM	gend-fn|num-sg|pers-3|case-|vib-A|tam-A_o
VM	gend-fn|num-sg|pers-3|case-|vib-a_ani|tam-a_ani
VM	gend-fn|num-sg|pers-3|case-|vib-a_gala_aka_po|tam-a_gala_aka_po_A
VM	gend-fn|num-sg|pers-3|case-|vib-a_ivvu_a_gala_a|tam-a_ivvu_a_gala_a
VM	gend-fn|num-sg|pers-3|case-|vib-a_ivvu_a|tam-a_ivvu_a
VM	gend-fn|num-sg|pers-3|case-|vib-a_sAgu|tam-a_sAgu_A
VM	gend-fn|num-sg|pers-3|case-|vib-a_valayu_avvu+a|tam-a_valayu_A
VM	gend-fn|num-sg|pers-3|case-|vib-a_valayu|tam-a_valayu_A
VM	gend-fn|num-sg|pers-3|case-|vib-a|tam-a
VM	gend-fn|num-sg|pers-3|case-|vib-a|tam-a_o
VM	gend-fn|num-sg|pers-3|case-|vib-i_po_wU_uMdu|tam-i_po_wU_uMdu_A
VM	gend-fn|num-sg|pers-3|case-|vib-i_po_wunn|tam-i_po_wunn
VM	gend-fn|num-sg|pers-3|case-|vib-i_po|tam-i_po_A
VM	gend-fn|num-sg|pers-3|case-|vib-i_vaccu|tam-i_vaccu_A
VM	gend-fn|num-sg|pers-3|case-|vib-i_veVyyi_wU_uMdu_A|tam-i_veVyyi_wU_uMdu_A_A
VM	gend-fn|num-sg|pers-3|case-|vib-i_veVyyi|tam-i_veVyyi_A
VM	gend-fn|num-sg|pers-3|case-|vib-koVn_a_le_a|tam-koVn_a_le_a
VM	gend-fn|num-sg|pers-3|case-|vib-koVn_wU_uMdu|tam-koVn_wU_uMdu_A
VM	gend-fn|num-sg|pers-3|case-|vib-koVn_wunn|tam-koVn_wunn
VM	gend-fn|num-sg|pers-3|case-|vib-koVn|tam-koVn_A
VM	gend-fn|num-sg|pers-3|case-|vib-wA|tam-wA
VM	gend-fn|num-sg|pers-3|case-|vib-wA|tam-wA_A
VM	gend-fn|num-sg|pers-3|case-|vib-wA|tam-wA_o
VM	gend-fn|num-sg|pers-3|case-|vib-wunn|tam-wunn
VM	gend-fn|num-sg|pers-3|case-|vib-wunn|tam-wunn_A
VM	gend-fn|num-sg|pers-3|case-|vib-|tam-
VM	gend-m|num-sg|pers-3|case-|vib-A_ani|tam-A_ani
VM	gend-m|num-sg|pers-3|case-|vib-A|tam-A
VM	gend-m|num-sg|pers-3|case-|vib-A|tam-A_o
VM	gend-m|num-sg|pers-3|case-|vib-a_gala_aka_po|tam-a_gala_aka_po_A
VM	gend-m|num-sg|pers-3|case-|vib-a_manu|tam-a_manu_A
VM	gend-m|num-sg|pers-3|case-|vib-a|tam-a
VM	gend-m|num-sg|pers-3|case-|vib-i_cUdu|tam-i_cUdu_A
VM	gend-m|num-sg|pers-3|case-|vib-i_po|tam-i_po_A
VM	gend-m|num-sg|pers-3|case-|vib-i_veVyyi|tam-i_veVyyi_A
VM	gend-m|num-sg|pers-3|case-|vib-koVn_A_ani|tam-koVn_A_ani
VM	gend-m|num-sg|pers-3|case-|vib-koVn_a_galugu|tam-koVn_a_galugu_A
VM	gend-m|num-sg|pers-3|case-|vib-koVn_wA_ata|tam-koVn_wA_ata
VM	gend-m|num-sg|pers-3|case-|vib-koVn_wA|tam-koVn_wA
VM	gend-m|num-sg|pers-3|case-|vib-koVn|tam-koVn_A
VM	gend-m|num-sg|pers-3|case-|vib-wA|tam-wA
VM	gend-m|num-sg|pers-3|case-|vib-wunn|tam-wunn
VM	gend-m|num-sg|pers-3|case-|vib-|tam-
VM	gend-n|num-pl|pers-3|case-|vib-A_ata|tam-A_ata
VM	gend-n|num-pl|pers-3|case-|vib-A|tam-A
VM	gend-n|num-pl|pers-3|case-|vib-a_ani|tam-a_ani
VM	gend-n|num-pl|pers-3|case-|vib-a_manu_iwi|tam-a_manu_iwi
VM	gend-n|num-pl|pers-3|case-|vib-a_sAgu_iwi|tam-a_sAgu_iwi
VM	gend-n|num-pl|pers-3|case-|vib-a_uta|tam-a_uta
VM	gend-n|num-pl|pers-3|case-|vib-aka_uMdu_iwi|tam-aka_uMdu_iwi
VM	gend-n|num-pl|pers-3|case-|vib-a|tam-a
VM	gend-n|num-pl|pers-3|case-|vib-a|tam-a_A
VM	gend-n|num-pl|pers-3|case-|vib-i_po_iwi|tam-i_po_iwi
VM	gend-n|num-pl|pers-3|case-|vib-i_po|tam-i_po_A
VM	gend-n|num-pl|pers-3|case-|vib-iwi|tam-iwi
VM	gend-n|num-pl|pers-3|case-|vib-uxu|tam-uxu
VM	gend-n|num-pl|pers-3|case-|vib-wA|tam-wA
VM	gend-n|num-pl|pers-3|case-|vib-wU_uMdu_wA|tam-wU_uMdu_wA
VM	gend-n|num-pl|pers-3|case-|vib-wunn|tam-wunn
VM	gend-n|num-pl|pers-3|case-|vib-|tam-
VM	gend-|num-pl|pers-1|case-|vib-A|tam-A
VM	gend-|num-pl|pers-1|case-|vib-a_gala_a|tam-a_gala_a
VM	gend-|num-pl|pers-1|case-|vib-a|tam-a
VM	gend-|num-pl|pers-1|case-|vib-koVn_a_le_a|tam-koVn_a_le_a_A
VM	gend-|num-pl|pers-1|case-|vib-wA_ani|tam-wA_ani
VM	gend-|num-pl|pers-1|case-|vib-wA|tam-wA
VM	gend-|num-pl|pers-1|case-|vib-|tam-
VM	gend-|num-pl|pers-2|case-|vib-AjFArWa|tam-AjFArWa
VM	gend-|num-pl|pers-2|case-|vib-e_lA_cUdu+AjFArWa|tam-e_lA
VM	gend-|num-pl|pers-2|case-|vib-i_uMdu+xA|tam-i
VM	gend-|num-pl|pers-2|case-|vib-xA_ani|tam-xA_ani
VM	gend-|num-pl|pers-2|case-|vib-xA_le|tam-xA_le
VM	gend-|num-pl|pers-2|case-|vib-xA|tam-xA
VM	gend-|num-pl|pers-2|case-|vib-|tam-
VM	gend-|num-pl|pers-3|case-|vib-A|tam-A
VM	gend-|num-pl|pers-3|case-|vib-A|tam-A_A
VM	gend-|num-pl|pers-3|case-|vib-a_gala_aka_po+A|tam-a_gala_aka
VM	gend-|num-pl|pers-3|case-|vib-a_gala_wA|tam-a_gala_wA
VM	gend-|num-pl|pers-3|case-|vib-a_le_a|tam-a_le_a
VM	gend-|num-pl|pers-3|case-|vib-akuMdA_ceVyyi+A|tam-akuMdA
VM	gend-|num-pl|pers-3|case-|vib-a|tam-a
VM	gend-|num-pl|pers-3|case-|vib-e_atlu_cUdu+A|tam-e_atlu
VM	gend-|num-pl|pers-3|case-|vib-i_ceVyyi+A|tam-i_A
VM	gend-|num-pl|pers-3|case-|vib-i_po+A|tam-i
VM	gend-|num-pl|pers-3|case-|vib-i_po+wA|tam-i
VM	gend-|num-pl|pers-3|case-|vib-i_po|tam-i_po_A
VM	gend-|num-pl|pers-3|case-|vib-i_uMdu+iwi|tam-i
VM	gend-|num-pl|pers-3|case-|vib-i_veVyyi_koVn_wU_uMdi_veVyyi_koVn_wU_uMdu_A|tam-i_veVyyi_koVn_wU_uMdu_A
VM	gend-|num-pl|pers-3|case-|vib-wA|tam-wA
VM	gend-|num-pl|pers-3|case-|vib-wA|tam-wA_o
VM	gend-|num-pl|pers-3|case-|vib-wU_uMdu_wA|tam-wU_uMdu_wA
VM	gend-|num-pl|pers-3|case-|vib-wunn|tam-wunn
VM	gend-|num-pl|pers-3|case-|vib-|tam-
VM	gend-|num-pl|pers-|case-d|vib-|tam-
VM	gend-|num-pl|pers-|case-|vib-e_vAlYlu_nu|tam-e_vAlYlu_nu
VM	gend-|num-pl|pers-|case-|vib-e_vAru_0|tam-e_vAru_0_e
VM	gend-|num-pl|pers-|case-|vib-e_vAru|tam-e_vAru_0
VM	gend-|num-pl|pers-|case-|vib-gala_xi|tam-gala_xi_0
VM	gend-|num-pl|pers-|case-|vib-ina_axi_0|tam-ina_axi_0_e
VM	gend-|num-pl|pers-|case-|vib-ina_axi|tam-ina_axi_0
VM	gend-|num-pl|pers-|case-|vib-ina_vAru_0|tam-ina_vAru_0_e
VM	gend-|num-pl|pers-|case-|vib-ina_vAru_ki|tam-ina_vAru_ki
VM	gend-|num-pl|pers-|case-|vib-xi|tam-xi_0
VM	gend-|num-pl|pers-|case-|vib-|tam-
VM	gend-|num-sg|pers-1|case-|vib-A_ani|tam-A_ani
VM	gend-|num-sg|pers-1|case-|vib-A|tam-A
VM	gend-|num-sg|pers-1|case-|vib-a_badu|tam-a_badu_A
VM	gend-|num-sg|pers-1|case-|vib-a_sAgu|tam-a_sAgu_A
VM	gend-|num-sg|pers-1|case-|vib-a|tam-a
VM	gend-|num-sg|pers-1|case-|vib-a|tam-a_e
VM	gend-|num-sg|pers-1|case-|vib-i_po|tam-i_po_A
VM	gend-|num-sg|pers-1|case-|vib-i_uMcu+A|tam-i
VM	gend-|num-sg|pers-1|case-|vib-i_vaccu+wA|tam-i
VM	gend-|num-sg|pers-1|case-|vib-i_veVyyi_wA_rA|tam-i_veVyyi_wA_rA
VM	gend-|num-sg|pers-1|case-|vib-i_veVyyi|tam-i_veVyyi_A
VM	gend-|num-sg|pers-1|case-|vib-koVn_a_galugu|tam-koVn_a_galugu_A
VM	gend-|num-sg|pers-1|case-|vib-koVn_wA|tam-koVn_wA_A
VM	gend-|num-sg|pers-1|case-|vib-wA|tam-wA
VM	gend-|num-sg|pers-1|case-|vib-wU_uMdu+A|tam-wU_e
VM	gend-|num-sg|pers-1|case-|vib-wunn|tam-wunn
VM	gend-|num-sg|pers-1|case-|vib-|tam-
VM	gend-|num-sg|pers-2|case-|vib-A_ani|tam-A_ani
VM	gend-|num-sg|pers-2|case-|vib-AjFArWa_cAlu+AjFArWa|tam-AjFArWa
VM	gend-|num-sg|pers-2|case-|vib-AjFArWa_manu|tam-AjFArWa_manu
VM	gend-|num-sg|pers-2|case-|vib-AjFArWa|tam-AjFArWa
VM	gend-|num-sg|pers-2|case-|vib-A|tam-A
VM	gend-|num-sg|pers-2|case-|vib-aku|tam-aku
VM	gend-|num-sg|pers-2|case-|vib-i_po+wA|tam-i
VM	gend-|num-sg|pers-2|case-|vib-i_uMcu+AjFArWa_manu|tam-i
VM	gend-|num-sg|pers-2|case-|vib-i_veVyyi_A|tam-i_veVyyi_A_A
VM	gend-|num-sg|pers-2|case-|vib-i_veVyyi|tam-i_veVyyi_A
VM	gend-|num-sg|pers-2|case-|vib-koVn_wA|tam-koVn_wA
VM	gend-|num-sg|pers-2|case-|vib-koVn_wU_uMdu_A|tam-koVn_wU_uMdu_A_A
VM	gend-|num-sg|pers-2|case-|vib-koVn_we_cAlu+AjFArWa|tam-koVn_we
VM	gend-|num-sg|pers-2|case-|vib-wA|tam-wA
VM	gend-|num-sg|pers-2|case-|vib-we_cAlu+AjFArWa|tam-we
VM	gend-|num-sg|pers-2|case-|vib-|tam-
VM	gend-|num-sg|pers-3|case-|vib-0_po+A|tam-
VM	gend-|num-sg|pers-3|case-|vib-Ali_ani_gala+a|tam-Ali_ani
VM	gend-|num-sg|pers-3|case-|vib-Ali_ani_uMdu+A|tam-Ali_ani
VM	gend-|num-sg|pers-3|case-|vib-a_ivvu_adaM_gala+a|tam-a_ivvu_adaM
VM	gend-|num-sg|pers-3|case-|vib-a_vaccu+a|tam-a_e
VM	gend-|num-sg|pers-3|case-|vib-a_valayu_i_uMdu+A|tam-a_valayu_i
VM	gend-|num-sg|pers-3|case-|vib-a_valayu_i_uMdu+wA|tam-a_valayu_i
VM	gend-|num-sg|pers-3|case-|vib-adaM_gala+a|tam-adaM
VM	gend-|num-sg|pers-3|case-|vib-an_kUdu+a|tam-an
VM	gend-|num-sg|pers-3|case-|vib-e_axi_avvu+a|tam-e_axi_0
VM	gend-|num-sg|pers-3|case-|vib-e_lA_ceVyyi+A|tam-e_lA
VM	gend-|num-sg|pers-3|case-|vib-e_vAdu_avvu+a|tam-e_vAdu_0
VM	gend-|num-sg|pers-3|case-|vib-i_ivvu+A|tam-i
VM	gend-|num-sg|pers-3|case-|vib-i_po+A|tam-i
VM	gend-|num-sg|pers-3|case-|vib-i_po+wA|tam-i
VM	gend-|num-sg|pers-3|case-|vib-i_po_Ali_ani_uMdu+A|tam-i_po_Ali_ani
VM	gend-|num-sg|pers-3|case-|vib-i_uMdu+A|tam-i
VM	gend-|num-sg|pers-3|case-|vib-i_vaccu+A|tam-i
VM	gend-|num-sg|pers-3|case-|vib-i_veVyyi_an_gUdu+a|tam-i_veVyyi_an
VM	gend-|num-sg|pers-3|case-|vib-ina_atlu_avvu+wA|tam-ina_atlu
VM	gend-|num-sg|pers-3|case-|vib-koVn_Ali_ani_uMdu+A|tam-koVn_Ali_ani
VM	gend-|num-sg|pers-3|case-|vib-wU_uMdu+A|tam-wU_e
VM	gend-|num-sg|pers-3|case-|vib-wU_uMdu+wA|tam-wU
VM	gend-|num-sg|pers-3|case-|vib-|tam-
VM	gend-|num-sg|pers-|case-d|vib-|tam-
VM	gend-|num-sg|pers-|case-|vib-adaM_0|tam-adaM_0_e
VM	gend-|num-sg|pers-|case-|vib-adaM_ki|tam-adaM_ki
VM	gend-|num-sg|pers-|case-|vib-adaM_wo|tam-adaM_wo
VM	gend-|num-sg|pers-|case-|vib-e_axi_0|tam-e_axi_0_e
VM	gend-|num-sg|pers-|case-|vib-e_axi|tam-e_axi_0
VM	gend-|num-sg|pers-|case-|vib-e_vAdu|tam-e_vAdu_0
VM	gend-|num-sg|pers-|case-|vib-ina_axi|tam-ina_axi_0
VM	gend-|num-sg|pers-|case-|vib-lo|tam-lo
VM	gend-|num-sg|pers-|case-|vib-na|tam-na
VM	gend-|num-sg|pers-|case-|vib-wunna_axi|tam-wunna_axi_0
VM	gend-|num-sg|pers-|case-|vib-xi|tam-xi
VM	gend-|num-sg|pers-|case-|vib-|tam-
VM	gend-|num-sg|pers-|case-|vib-|tam-0_A
VM	gend-|num-|pers-|case-|vib-0_V|tam-0_V_adv
VM	gend-|num-|pers-|case-|vib-0_mAwrame|tam-
VM	gend-|num-|pers-|case-|vib-Ali_aMte|tam-Ali_aMte
VM	gend-|num-|pers-|case-|vib-Ali_ani|tam-Ali_ani
VM	gend-|num-|pers-|case-|vib-Ali|tam-Ali
VM	gend-|num-|pers-|case-|vib-Ali|tam-Ali_o
VM	gend-|num-|pers-|case-|vib-_e_appudu_0_V|tam-_e_appudu_0_V_adv
VM	gend-|num-|pers-|case-|vib-a_gAne|tam-a_gAne
VM	gend-|num-|pers-|case-|vib-a_gala_aka|tam-a_gala_aka
VM	gend-|num-|pers-|case-|vib-a_galugu_inA|tam-a_galugu_inA
VM	gend-|num-|pers-|case-|vib-a_kUdaxu|tam-a_kUdaxu
VM	gend-|num-|pers-|case-|vib-a_le_aka_po+adaM|tam-a_le_aka
VM	gend-|num-|pers-|case-|vib-a_lexu|tam-a_lexu
VM	gend-|num-|pers-|case-|vib-a_manu_i|tam-a_manu_i
VM	gend-|num-|pers-|case-|vib-a_neru|tam-a_neru
VM	gend-|num-|pers-|case-|vib-a_po_i|tam-a_po_i
VM	gend-|num-|pers-|case-|vib-a_po|tam-a_po_e
VM	gend-|num-|pers-|case-|vib-a_vaccu|tam-a_vaccu
VM	gend-|num-|pers-|case-|vib-a_valayu_ina_aMwa_uMdu+Ali|tam-a_valayu_ina_aMwa
VM	gend-|num-|pers-|case-|vib-a_valayu_ina|tam-a_valayu_ina
VM	gend-|num-|pers-|case-|vib-a_vaxxu|tam-a_vaxxu
VM	gend-|num-|pers-|case-|vib-adaM_lexemo|tam-adaM
VM	gend-|num-|pers-|case-|vib-adaM_valla|tam-adaM
VM	gend-|num-|pers-|case-|vib-adaM|tam-adaM
VM	gend-|num-|pers-|case-|vib-aka_po_adaM|tam-aka_po_adaM
VM	gend-|num-|pers-|case-|vib-aka_po_ina_app_ki|tam-aka_po_ina_app_ki
VM	gend-|num-|pers-|case-|vib-aka_uMdu_e_eMxuku|tam-aka_uMdu_e_eMxuku
VM	gend-|num-|pers-|case-|vib-akapowe|tam-akapowe
VM	gend-|num-|pers-|case-|vib-aka|tam-aka
VM	gend-|num-|pers-|case-|vib-akuMdA_ayiMdu|tam-akuMdA
VM	gend-|num-|pers-|case-|vib-akuMdA|tam-akuMdA
VM	gend-|num-|pers-|case-|vib-ani|tam-ani
VM	gend-|num-|pers-|case-|vib-an|tam-an
VM	gend-|num-|pers-|case-|vib-a|tam-a_gA
VM	gend-|num-|pers-|case-|vib-e_appudu|tam-e_appudu
VM	gend-|num-|pers-|case-|vib-e_atlu|tam-e_atlu
VM	gend-|num-|pers-|case-|vib-e_axi_gala+aka|tam-e_axi_0
VM	gend-|num-|pers-|case-|vib-e_eMxuku|tam-e_eMxuku
VM	gend-|num-|pers-|case-|vib-e_muMxu|tam-e_muMxu
VM	gend-|num-|pers-|case-|vib-e_sariki|tam-e_sariki
VM	gend-|num-|pers-|case-|vib-e|tam-e
VM	gend-|num-|pers-|case-|vib-i_po+a_lexu|tam-i
VM	gend-|num-|pers-|case-|vib-i_po_adaM|tam-i_po_adaM
VM	gend-|num-|pers-|case-|vib-i_po_i|tam-i_po_i
VM	gend-|num-|pers-|case-|vib-i_po_we|tam-i_po_we
VM	gend-|num-|pers-|case-|vib-i_uMdu+Ali|tam-i
VM	gend-|num-|pers-|case-|vib-i_uMdu+a_vaccu|tam-i
VM	gend-|num-|pers-|case-|vib-i_uMdu+e|tam-i
VM	gend-|num-|pers-|case-|vib-i_uMdu_Ali|tam-i_uMdu_Ali
VM	gend-|num-|pers-|case-|vib-i_uMdu_a_gAne|tam-i_uMdu_a_gAne
VM	gend-|num-|pers-|case-|vib-i_uMdu_we|tam-i_uMdu_we
VM	gend-|num-|pers-|case-|vib-i_vaccu+Ali|tam-i
VM	gend-|num-|pers-|case-|vib-i_vaccu|tam-i_vaccu
VM	gend-|num-|pers-|case-|vib-i_veVyyi+Ali|tam-i
VM	gend-|num-|pers-|case-|vib-i_veVyyi_a_kUdaxu|tam-i_veVyyi_a_kUdaxu
VM	gend-|num-|pers-|case-|vib-i_veVyyi_i|tam-i_veVyyi_i
VM	gend-|num-|pers-|case-|vib-inA|tam-inA
VM	gend-|num-|pers-|case-|vib-ina_Aka|tam-ina_Aka
VM	gend-|num-|pers-|case-|vib-ina_aMwa|tam-ina_aMwa
VM	gend-|num-|pers-|case-|vib-ina_aMxuku|tam-ina_aMxuku
VM	gend-|num-|pers-|case-|vib-ina_appudu|tam-ina_appudu
VM	gend-|num-|pers-|case-|vib-ina_atlu|tam-ina_atlu
VM	gend-|num-|pers-|case-|vib-ina_xAkA|tam-ina_xAkA
VM	gend-|num-|pers-|case-|vib-ina|tam-ina
VM	gend-|num-|pers-|case-|vib-i|tam-i
VM	gend-|num-|pers-|case-|vib-i|tam-i_A
VM	gend-|num-|pers-|case-|vib-i|tam-i_o
VM	gend-|num-|pers-|case-|vib-koVn_Ali_ani|tam-koVn_Ali_ani
VM	gend-|num-|pers-|case-|vib-koVn_Ali|tam-koVn_Ali
VM	gend-|num-|pers-|case-|vib-koVn_a_vaccu|tam-koVn_a_vaccu
VM	gend-|num-|pers-|case-|vib-koVn_akuMdA|tam-koVn_akuMdA_e
VM	gend-|num-|pers-|case-|vib-koVn_inA|tam-koVn_inA
VM	gend-|num-|pers-|case-|vib-koVn_wU|tam-koVn_wU
VM	gend-|num-|pers-|case-|vib-koVn_we|tam-koVn_we
VM	gend-|num-|pers-|case-|vib-koVn_wunnA|tam-koVn_wunnA
VM	gend-|num-|pers-|case-|vib-koVn|tam-koVn
VM	gend-|num-|pers-|case-|vib-koVn|tam-koVn_e
VM	gend-|num-|pers-|case-|vib-o|tam-o_avy
VM	gend-|num-|pers-|case-|vib-wU_po_wU|tam-wU_po_wU
VM	gend-|num-|pers-|case-|vib-wU_uMdu_Ali|tam-wU_uMdu_Ali
VM	gend-|num-|pers-|case-|vib-wU_uMdu|tam-wU_uMdu
VM	gend-|num-|pers-|case-|vib-wU_unnAM|tam-wU_e
VM	gend-|num-|pers-|case-|vib-wU|tam-wU
VM	gend-|num-|pers-|case-|vib-we|tam-we
VM	gend-|num-|pers-|case-|vib-wuMte|tam-wuMte
VM	gend-|num-|pers-|case-|vib-xi|tam-xi_adj
VM	gend-|num-|pers-|case-|vib-|tam-
VM	gend-|num-|pers-|case-|vib-|tam-0_adj
VM	gend-|num-|pers-|case-|vib-|tam-0_adv
WQ	gend-fm|num-pl|pers-3|case-o|vib-ti|tam-ti
WQ	gend-fm|num-pl|pers-3|case-o|vib-|tam-
WQ	gend-fm|num-pl|pers-3|case-|vib-ki|tam-ki_V
WQ	gend-fm|num-pl|pers-3|case-|vib-ni|tam-ni
WQ	gend-fm|num-pl|pers-3|case-|vib-|tam-
WQ	gend-fn|num-pl|pers-3|case-|vib-|tam-
WQ	gend-fn|num-pl|pers-3|case-|vib-|tam-0_V
WQ	gend-fn|num-sg|pers-3|case-|vib-|tam-
WQ	gend-fn|num-sg|pers-3|case-|vib-|tam-0_o
WQ	gend-|num-pl|pers-|case-|vib-ni|tam-ni
WQ	gend-|num-pl|pers-|case-|vib-|tam-
WQ	gend-|num-sg|pers-|case-d|vib-|tam-
WQ	gend-|num-sg|pers-|case-|vib-e_axi_0|tam-e_axi_0_o
WQ	gend-|num-sg|pers-|case-|vib-ni|tam-ni_o
WQ	gend-|num-sg|pers-|case-|vib-|tam-
WQ	gend-|num-|pers-|case-|vib-o|tam-o_avy
WQ	gend-|num-|pers-|case-|vib-|tam-
WQ	gend-|num-|pers-|case-|vib-|tam-0_adv
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

Lingua::Interset::Tagset::TE::Conll - Driver for the Telugu tagset of the ICON 2009 and 2010 Shared Tasks, as used in the CoNLL data format.

=head1 VERSION

version 3.007

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::TE::Conll;
  my $driver = Lingua::Interset::Tagset::TE::Conll->new();
  my $fs = $driver->decode("NN\tcat-n|gend-|num-sg|pers-|case-d|vib-0|tam-0");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('te::conll', "NN\tcat-n|gend-|num-sg|pers-|case-d|vib-0|tam-0");

=head1 DESCRIPTION

Interset driver for the Telugu tagset of the ICON 2009 and 2010 Shared Tasks,
as used in the CoNLL data format.
CoNLL tagsets in Interset are traditionally three values separated by tabs,
coming from the CoNLL columns CPOS, POS and FEAT.
ICON shared task data were converted to CoNLL from the native Shakti Standard Format (SSF).
The CoNLL CPOS column contains so-called chunk tag, which we do not want to decode,
thus we expect only two tab-separated values in this tagset:
the POS column (which contains the part of speech of the headword of the chunk)
and partial contents of the FEAT column (we exclude features that should not be
considered part of the tag,
e.g. the C<lex> feature, which contains lemma or word stem).

Short description of the part of speech tags can be found in
L<http://ltrc.iiit.ac.in/nlptools2010/documentation.php>.
More information is available in the annotators' manual at
L<http://ltrc.iiit.ac.in/MachineTrans/publications/technicalReports/tr031/posguidelines.pdf>.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
