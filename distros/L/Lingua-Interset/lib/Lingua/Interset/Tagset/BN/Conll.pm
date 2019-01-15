# ABSTRACT: Driver for the Bengali tagset of the ICON 2009 and 2010 Shared Tasks, as used in the CoNLL data format.
# Documentation:
# http://ltrc.iiit.ac.in/nlptools2010/documentation.php
# http://ltrc.iiit.ac.in/MachineTrans/publications/technicalReports/tr031/posguidelines.pdf
# Copyright © 2011 Loganathan Ramasamy <ramasamy@ufal.mff.cuni.cz>
# Copyright © 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::BN::Conll;
use strict;
use warnings;
our $VERSION = '3.013';

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
    return 'bn::conll';
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
            # Examples:
            # কথা (kathā = word), বাতাসে (bātāsē = air), সময় (samaẏa = time), স্যার (syāra = sir), হাত (hāta = hand)
            'NN'   => ['pos' => 'noun', 'nountype' => 'com'],
            'NNC'  => ['pos' => 'noun', 'nountype' => 'com'],
            # proper nouns
            # Examples:
            # সালে (Sālē), খ্রী (Khrī = America), মদনা (Madanā), গণপতিবাবু (Gaṇapatibābu), কলকাতা (Kalakātā = Kolkata)
            'NNP'  => ['pos' => 'noun', 'nountype' => 'prop'],
            'NNPC' => ['pos' => 'noun', 'nountype' => 'prop'],
            # location nouns
            # These words are grammatically nouns but they are used to form a sort of postpositions. Often but not always they specify location.
            # For instance, "on the table" would be constructed as "the table's upper side", and the word for "upper side" would be tagged NST.
            # Examples:
            # সঙ্গে (saṅgē = with), উপর (upara = up, on), কাছে (kāchē = of), মধ্যে (madhyē = in, between), পর (para = after)
            'NST'  => ['pos' => 'noun', 'adpostype' => 'post'],
            'NSTC' => ['pos' => 'noun', 'adpostype' => 'post'],
            # pronouns
            # Examples (note that the "possessive" pronouns are genitive forms of personal pronouns):
            # তার (tāra = his), আমি (āmi = I), আমার (āmāra = my), এখন (ēkhana = now), সে (sē = he)
            'PRP'  => ['pos' => 'noun', 'prontype' => 'prs'],
            'PRPC' => ['pos' => 'noun', 'prontype' => 'prs'],
            # question words
            # Examples:
            # কি (ki = what), কী (kī = what), কেন (kēna = why), কোথায় (kōthāẏa = where), কে (kē = who)
            'WQ'   => ['pos' => 'noun', 'prontype' => 'int'],
            # adjectives
            # Examples:
            # পরিণত (pariṇata = become, turned [participle]), বাধ্য (bādhya = forced), ভালো (bhālō = good), দুর্বল (durbala = weak)
            'JJ'   => ['pos' => 'adj'],
            'JJC'  => ['pos' => 'adj'],
            # demonstratives
            # Only 4 occurrences in the corpus, only 2 word types:
            # এই (ē'i = this), এইসব (ē'isaba = these)
            'DEM'  => ['pos' => 'adj', 'prontype' => 'dem'],
            # quantifiers
            # Examples:
            # একটু (ēkaṭu = a little), কিছুটা (kichuṭā = somewhat), কোনও (kōna'ō = no), খুব (khuba = very), বহু (bahu = many), সব (saba = all)
            'QF'   => ['pos' => 'adj', 'prontype' => 'ind'],
            'QFC'  => ['pos' => 'adj', 'prontype' => 'ind'],
            # numerals
            # Examples:
            # ১৬৯৮ (1698), ১৮৯ (189), এক (ēka = one), সতের (satēra = seventeen), হাজার (hājāra = thousand)
            'QC'   => ['pos' => 'num', 'numtype' => 'card'],
            'QCC'  => ['pos' => 'num', 'numtype' => 'card'],
            'QO'   => ['pos' => 'adj', 'numtype' => 'ord'],
            # main verbs (documentation says "verb-finite", are they really always finite forms?)
            # Examples:
            # করে (karē = do), হয় (haẏa = be), হয়ে (haẏē = be), ছিল (chila = was), করতে (karatē = do)
            'VM'   => ['pos' => 'verb'],
            'VMC'  => ['pos' => 'verb'],
            # auxiliary verbs
            # Only three occurrences in the corpus:
            # চায় (cāẏa = want), নেবেন (nēbēna = will), যায় (yāẏa = can)
            'VAUX' => ['pos' => 'verb', 'verbtype' => 'aux'],
            # adverbs
            # Examples:
            # শুধু (śudhu = only), তারপর (tārapara = then), আর (āra), আবার (ābāra = again), ক্রমে (kramē = gradually)
            'RB'   => ['pos' => 'adv'],
            'RBC'  => ['pos' => 'adv'],
            # intensifiers
            'INTF' => ['pos' => 'adv'],
            # negation
            # Example:
            # না (nā = not)
            'NEG'  => ['pos' => 'part', 'prontype' => 'neg', 'polarity' => 'neg'],
            # postpositions
            # Examples:
            # সহ (saha = with)
            'PSP'  => ['pos' => 'adp', 'adpostype' => 'post'],
            # conjunctions
            # Examples:
            # ও (ō = and), এবং (ēbaṁ = and), কিন্তু (kintu = but), আর (āra = and), বা (bā = or)
            'CC'   => ['pos' => 'conj'],
            'UT'   => ['pos' => 'conj', 'conjtype' => 'sub'],
            # particles
            # Examples:
            # তো (tō), করে (karē), যেন (yēna), আর (āra), যে (yē)
            'RP'   => ['pos' => 'part'],
            # interjections
            # Examples:
            # আচ্ছা (ācchā = well), কি (ki = what), খিলখিল (khilakhila = haha), ছি (chi = bo), ত (ta)
            'INJ'  => ['pos' => 'int'],
            # reduplicatives
            # Only one occurrence in the corpus:
            # যার (yāra)
            'RDP'  => ['echo' => 'rdp'],
            # echo words
            'ECH'  => ['echo' => 'ech'],
            # undocumented (compounds???), two word forms, four occurrences:
            # টুকরো (Ṭukarō = Trivia), যে (yē = that)
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
                                                      '@'    => { 'prontype' => { ''    => { 'nountype' => { 'prop' => 'NNP',
                                                                                                             '@'    => 'NN' }},
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
                         'adv'  => 'RB',
                         'adp'  => 'PSP',
                         'conj' => 'CC',
                         'part' => { 'prontype' => { 'neg' => 'NEG',
                                                     '@'   => 'RP' }},
                         'int'  => 'INJ',
                         'punc' => 'SYM',
                         '@'    => { 'echo' => { 'rdp' => 'RDP',
                                                 '@'   => { 'other/pos' => { 'null' => 'NULL',
                                                                             '@'    => 'XC' }}}}}}
    );
    # GENDER ####################
    $atoms{gend} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'm' => 'masc',
            'f' => 'fem',
            'n' => 'neut'
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
    $fs->set_tagset('bn::conll');
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
            $value = $fs->get_other_subfeature('bn::conll', $name);
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
# 531 tags
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
CC	gend-|num-|pers-|case-|vib-|tam-
DEM	gend-|num-sg|pers-|case-d|vib-0|tam-0
DEM	gend-|num-sg|pers-|case-d|vib-|tam-
DEM	gend-|num-|pers-|case-|vib-|tam-
INJ	gend-|num-|pers-|case-|vib-|tam-
JJ	gend-|num-sg|pers-|case-d|vib-me|tam-me
JJ	gend-|num-sg|pers-|case-d|vib-|tam-
JJ	gend-|num-|pers-1|case-|vib-ne|tam-ne
JJ	gend-|num-|pers-1|case-|vib-|tam-
JJ	gend-|num-|pers-|case-|vib-|tam-
NEG	gend-|num-|pers-|case-|vib-|tam-
NN	gend-|num-pl|pers-|case-d|vib-0|tam-0
NN	gend-|num-pl|pers-|case-d|vib-me|tam-me
NN	gend-|num-pl|pers-|case-d|vib-|tam-
NN	gend-|num-pl|pers-|case-o|vib-era|tam-era
NN	gend-|num-pl|pers-|case-o|vib-ke|tam-ke
NN	gend-|num-pl|pers-|case-o|vib-|tam-
NN	gend-|num-sg|pers-|case-d|vib-0_CAdZA|tam-0
NN	gend-|num-sg|pers-|case-d|vib-0_Weke|tam-0
NN	gend-|num-sg|pers-|case-d|vib-0_Xare|tam-0
NN	gend-|num-sg|pers-|case-d|vib-0_anuyAyZI|tam-0
NN	gend-|num-sg|pers-|case-d|vib-0_hisAbe|tam-0
NN	gend-|num-sg|pers-|case-d|vib-0_hisebe|tam-0
NN	gend-|num-sg|pers-|case-d|vib-0_niyZe|tam-0
NN	gend-|num-sg|pers-|case-d|vib-0_paryanwa|tam-0
NN	gend-|num-sg|pers-|case-d|vib-0_paryyanwa|tam-0
NN	gend-|num-sg|pers-|case-d|vib-0_saha|tam-0
NN	gend-|num-sg|pers-|case-d|vib-0_samparke|tam-0
NN	gend-|num-sg|pers-|case-d|vib-0_wo|tam-0
NN	gend-|num-sg|pers-|case-d|vib-0_xiyZez|tam-0
NN	gend-|num-sg|pers-|case-d|vib-0_xiyZe|tam-0
NN	gend-|num-sg|pers-|case-d|vib-0_xiye|tam-0
NN	gend-|num-sg|pers-|case-d|vib-0|tam-0
NN	gend-|num-sg|pers-|case-d|vib-era|tam-era
NN	gend-|num-sg|pers-|case-d|vib-ke|tam-ke
NN	gend-|num-sg|pers-|case-d|vib-me|tam-me
NN	gend-|num-sg|pers-|case-d|vib-|tam-
NN	gend-|num-sg|pers-|case-o|vib-0_Pale|tam-era
NN	gend-|num-sg|pers-|case-o|vib-0_ceyZe|tam-era
NN	gend-|num-sg|pers-|case-o|vib-0_janya|tam-era
NN	gend-|num-sg|pers-|case-o|vib-0_mawa|tam-era
NN	gend-|num-sg|pers-|case-o|vib-0_mawo|tam-era
NN	gend-|num-sg|pers-|case-o|vib-0_pakRe|tam-era
NN	gend-|num-sg|pers-|case-o|vib-0_uxxeSya|tam-era
NN	gend-|num-sg|pers-|case-o|vib-0_xike|tam-era
NN	gend-|num-sg|pers-|case-o|vib-era|tam-era
NN	gend-|num-sg|pers-|case-o|vib-ke|tam-ke
NN	gend-|num-sg|pers-|case-o|vib-|tam-
NN	gend-|num-|pers-1|case-|vib-ne|tam-ne
NN	gend-|num-|pers-1|case-|vib-|tam-
NN	gend-|num-|pers-3|case-|vib-ne|tam-ne
NN	gend-|num-|pers-3|case-|vib-|tam-
NN	gend-|num-|pers-4|case-|vib-ka|tam-ka
NN	gend-|num-|pers-5|case-|vib-ne|tam-ne
NN	gend-|num-|pers-6|case-|vib-ka|tam-ka
NN	gend-|num-|pers-any|case-|vib-Be|tam-Be
NN	gend-|num-|pers-any|case-|vib-iwe|tam-iwe
NN	gend-|num-|pers-any|case-|vib-we|tam-we
NN	gend-|num-|pers-any|case-|vib-|tam-
NN	gend-|num-|pers-|case-|vib-0_Weke|tam-
NN	gend-|num-|pers-|case-|vib-0_hisAbe|tam-
NN	gend-|num-|pers-|case-|vib-0_hisebe|tam-
NN	gend-|num-|pers-|case-|vib-0_janya|tam-
NN	gend-|num-|pers-|case-|vib-0_ke|tam-
NN	gend-|num-|pers-|case-|vib-0_mawana|tam-
NN	gend-|num-|pers-|case-|vib-0_mawa|tam-
NN	gend-|num-|pers-|case-|vib-0_mawo|tam-
NN	gend-|num-|pers-|case-|vib-0_niyZe|tam-
NN	gend-|num-|pers-|case-|vib-0_niye|tam-
NN	gend-|num-|pers-|case-|vib-0_of|tam-
NN	gend-|num-|pers-|case-|vib-0_pakRe|tam-
NN	gend-|num-|pers-|case-|vib-0_paryanwa|tam-
NN	gend-|num-|pers-|case-|vib-0_safge|tam-
NN	gend-|num-|pers-|case-|vib-0_sambanXe|tam-
NN	gend-|num-|pers-|case-|vib-0_samparke|tam-
NN	gend-|num-|pers-|case-|vib-0_sbarUpa|tam-
NN	gend-|num-|pers-|case-|vib-0_xaruna|tam-
NN	gend-|num-|pers-|case-|vib-0_xbArA|tam-
NN	gend-|num-|pers-|case-|vib-0_xiyZe|tam-
NN	gend-|num-|pers-|case-|vib-|tam-
NNP	gend-|num-pl|pers-|case-d|vib-0|tam-0
NNP	gend-|num-pl|pers-|case-d|vib-ke|tam-ke
NNP	gend-|num-pl|pers-|case-d|vib-|tam-
NNP	gend-|num-pl|pers-|case-o|vib-era|tam-era
NNP	gend-|num-pl|pers-|case-o|vib-ke|tam-ke
NNP	gend-|num-pl|pers-|case-o|vib-|tam-
NNP	gend-|num-sg|pers-|case-d|vib-0_Weke|tam-0
NNP	gend-|num-sg|pers-|case-d|vib-0_aBimuKe|tam-0
NNP	gend-|num-sg|pers-|case-d|vib-0_paryanwa|tam-0
NNP	gend-|num-sg|pers-|case-d|vib-0_saMkrAnwa|tam-0
NNP	gend-|num-sg|pers-|case-d|vib-0_sambanXe|tam-0
NNP	gend-|num-sg|pers-|case-d|vib-0_samparke|tam-0
NNP	gend-|num-sg|pers-|case-d|vib-0_xiyZe|tam-0
NNP	gend-|num-sg|pers-|case-d|vib-0|tam-0
NNP	gend-|num-sg|pers-|case-d|vib-ke|tam-ke
NNP	gend-|num-sg|pers-|case-d|vib-me|tam-me
NNP	gend-|num-sg|pers-|case-d|vib-|tam-
NNP	gend-|num-sg|pers-|case-o|vib-0_mawana|tam-era
NNP	gend-|num-sg|pers-|case-o|vib-0_mawa|tam-era
NNP	gend-|num-sg|pers-|case-o|vib-0_mawo|tam-era
NNP	gend-|num-sg|pers-|case-o|vib-0_pakRe|tam-era
NNP	gend-|num-sg|pers-|case-o|vib-era|tam-era
NNP	gend-|num-sg|pers-|case-o|vib-|tam-
NNP	gend-|num-|pers-6|case-|vib-ka|tam-ka
NNP	gend-|num-|pers-|case-|vib-0_-|tam-
NNP	gend-|num-|pers-|case-|vib-0_Weke|tam-
NNP	gend-|num-|pers-|case-|vib-0_anwargawa|tam-
NNP	gend-|num-|pers-|case-|vib-0_ceyZe|tam-
NNP	gend-|num-|pers-|case-|vib-0_hayZe|tam-
NNP	gend-|num-|pers-|case-|vib-0_in|tam-
NNP	gend-|num-|pers-|case-|vib-0_janya|tam-
NNP	gend-|num-|pers-|case-|vib-0_mawa|tam-
NNP	gend-|num-|pers-|case-|vib-0_mawo|tam-
NNP	gend-|num-|pers-|case-|vib-0_prawi|tam-
NNP	gend-|num-|pers-|case-|vib-0_saha|tam-
NNP	gend-|num-|pers-|case-|vib-0_xiyZe|tam-
NNP	gend-|num-|pers-|case-|vib-|tam-
NST	gend-|num-sg|pers-|case-d|vib-0_Weke|tam-0
NST	gend-|num-sg|pers-|case-d|vib-0_xiyZe|tam-0
NST	gend-|num-sg|pers-|case-d|vib-0_xiye|tam-0
NST	gend-|num-sg|pers-|case-d|vib-0|tam-0
NST	gend-|num-sg|pers-|case-d|vib-me|tam-me
NST	gend-|num-sg|pers-|case-d|vib-|tam-
NST	gend-|num-|pers-4|case-|vib-0_xiye|tam-ka
NST	gend-|num-|pers-|case-|vib-0_Weke|tam-
NST	gend-|num-|pers-|case-|vib-0_xiyZe|tam-
NST	gend-|num-|pers-|case-|vib-0_xiye|tam-
NST	gend-|num-|pers-|case-|vib-|tam-
NULL	gend-|num-|pers-|case-|vib-|tam-
PRP	gend-|num-pl|pers-|case-d|vib-|tam-
PRP	gend-|num-pl|pers-|case-d|vib-0_ceyZe|tam-0
PRP	gend-|num-pl|pers-|case-d|vib-0|tam-0
PRP	gend-|num-pl|pers-|case-d|vib-ke|tam-ke
PRP	gend-|num-pl|pers-|case-d|vib-me|tam-me
PRP	gend-|num-pl|pers-|case-o|vib-|tam-
PRP	gend-|num-pl|pers-|case-o|vib-0_mawo|tam-era
PRP	gend-|num-pl|pers-|case-o|vib-0_niyZe|tam-era
PRP	gend-|num-pl|pers-|case-o|vib-0_prawi|tam-era
PRP	gend-|num-pl|pers-|case-o|vib-0_sambanXe|tam-era
PRP	gend-|num-pl|pers-|case-o|vib-0|tam-0
PRP	gend-|num-pl|pers-|case-o|vib-era|tam-era
PRP	gend-|num-sg|pers-|case-d|vib-|tam-
PRP	gend-|num-sg|pers-|case-d|vib-0_CAdZA|tam-0
PRP	gend-|num-sg|pers-|case-d|vib-0_CA|tam-0
PRP	gend-|num-sg|pers-|case-d|vib-0_janya|tam-0
PRP	gend-|num-sg|pers-|case-d|vib-0_niyZe|tam-0
PRP	gend-|num-sg|pers-|case-d|vib-0|tam-0
PRP	gend-|num-sg|pers-|case-d|vib-ke|tam-ke
PRP	gend-|num-sg|pers-|case-d|vib-me|tam-me
PRP	gend-|num-sg|pers-|case-o|vib-|tam-
PRP	gend-|num-sg|pers-|case-o|vib-0_Pale|tam-era
PRP	gend-|num-sg|pers-|case-o|vib-0_Weke|tam-era
PRP	gend-|num-sg|pers-|case-o|vib-0_baxale|tam-era
PRP	gend-|num-sg|pers-|case-o|vib-0_janya|tam-era
PRP	gend-|num-sg|pers-|case-o|vib-0_mawa|tam-era
PRP	gend-|num-sg|pers-|case-o|vib-0|tam-0
PRP	gend-|num-sg|pers-|case-o|vib-era|tam-era
PRP	gend-|num-sg|pers-|case-o|vib-me|tam-me
PRP	gend-|num-|pers-5|case-|vib-|tam-
PRP	gend-|num-|pers-5|case-|vib-i|tam-i
PRP	gend-|num-|pers-5|case-|vib-sao|tam-sao
PRP	gend-|num-|pers-any|case-|vib-|tam-
PRP	gend-|num-|pers-any|case-|vib-Be|tam-Be
PRP	gend-|num-|pers-|case-d|vib-|tam-
PRP	gend-|num-|pers-|case-d|vib-0_Weke|tam-me
PRP	gend-|num-|pers-|case-d|vib-0|tam-0
PRP	gend-|num-|pers-|case-d|vib-me|tam-me
PRP	gend-|num-|pers-|case-|vib-|tam-
QC	gend-|num-|pers-|case-|vib-0_Weke|tam-
QC	gend-|num-|pers-|case-|vib-|tam-
QF	gend-|num-|pers-|case-|vib-|tam-
RB	gend-|num-sg|pers-|case-d|vib-0|tam-0
RB	gend-|num-sg|pers-|case-d|vib-|tam-
RB	gend-|num-|pers-|case-|vib-|tam-
RDP	gend-|num-|pers-|case-|vib-|tam-
RP	gend-|num-|pers-|case-|vib-0_janya|tam-
RP	gend-|num-|pers-|case-|vib-|tam-
SYM	gend-|num-|pers-|case-|vib-|tam-
VAUX	gend-|num-|pers-2|case-|vib-be|tam-be
VAUX	gend-|num-|pers-2|case-|vib-|tam-
VAUX	gend-|num-|pers-5|case-|vib-ne|tam-ne
VAUX	gend-|num-|pers-|case-|vib-|tam-
VM	gend-|num-sg|pers-5|case-d|vib-|tam-
VM	gend-|num-sg|pers-5|case-d|vib-me_yA+la|tam-me
VM	gend-|num-sg|pers-5|case-d|vib-me_yA+ne|tam-me
VM	gend-|num-sg|pers-7|case-d|vib-|tam-
VM	gend-|num-sg|pers-7|case-d|vib-me_xe+le|tam-me
VM	gend-|num-sg|pers-any|case-|vib-|tam-
VM	gend-|num-sg|pers-any|case-|vib-Be_AsA+era|tam-Be
VM	gend-|num-sg|pers-|case-d|vib-|tam-
VM	gend-|num-sg|pers-|case-d|vib-ke|tam-ke
VM	gend-|num-sg|pers-|case-d|vib-me|tam-me
VM	gend-|num-sg|pers-|case-o|vib-|tam-
VM	gend-|num-sg|pers-|case-o|vib-era|tam-era
VM	gend-|num-sg|pers-|case-|vib-|tam-
VM	gend-|num-sg|pers-|case-|vib-0_Ala+me|tam-
VM	gend-|num-|pers-1|case-|vib-|tam-
VM	gend-|num-|pers-1|case-|vib-0_xe+be|tam-
VM	gend-|num-|pers-1|case-|vib-A_cA+ne|tam-A
VM	gend-|num-|pers-1|case-|vib-A_pAr+ne|tam-A
VM	gend-|num-|pers-1|case-|vib-A_per+Ce|tam-A
VM	gend-|num-|pers-1|case-|vib-Be_xe+A_cA+la|tam-Be
VM	gend-|num-|pers-1|case-|vib-Be_xe+be|tam-Be
VM	gend-|num-|pers-1|case-|vib-Be_yA+Ce|tam-Be
VM	gend-|num-|pers-1|case-|vib-Be_yA+Cila|tam-Be
VM	gend-|num-|pers-1|case-|vib-Be_yA+iwe_cA+ne|tam-Be
VM	gend-|num-|pers-1|case-|vib-Ce|tam-Ce
VM	gend-|num-|pers-1|case-|vib-Cila|tam-Cila
VM	gend-|num-|pers-1|case-|vib-be|tam-be
VM	gend-|num-|pers-1|case-|vib-eni|tam-eni
VM	gend-|num-|pers-1|case-|vib-la|tam-la
VM	gend-|num-|pers-1|case-|vib-nA_be|tam-be
VM	gend-|num-|pers-1|case-|vib-nA_ne|tam-ne
VM	gend-|num-|pers-1|case-|vib-nAi_ne|tam-ne
VM	gend-|num-|pers-1|case-|vib-ne_ACa+ne|tam-ne
VM	gend-|num-|pers-1|case-|vib-ne_As+Ce|tam-ne
VM	gend-|num-|pers-1|case-|vib-ne_xe+Cila|tam-ne
VM	gend-|num-|pers-1|case-|vib-ne_xe+be|tam-ne
VM	gend-|num-|pers-1|case-|vib-ne_xe+la|tam-ne
VM	gend-|num-|pers-1|case-|vib-ne_yA+be|tam-ne
VM	gend-|num-|pers-1|case-|vib-ne_yAkanA|tam-ne
VM	gend-|num-|pers-1|case-|vib-ne|tam-ne
VM	gend-|num-|pers-1|case-|vib-wa|tam-wa
VM	gend-|num-|pers-1|case-|vib-yZa|tam-yZa
VM	gend-|num-|pers-2|case-|vib-|tam-
VM	gend-|num-|pers-2|case-|vib-0_per+Ce|tam-
VM	gend-|num-|pers-2|case-|vib-0_xe+ne|tam-
VM	gend-|num-|pers-2|case-|vib-0_yA+la|tam-
VM	gend-|num-|pers-2|case-|vib-A_Pel+la|tam-A
VM	gend-|num-|pers-2|case-|vib-A_pAr+be|tam-A
VM	gend-|num-|pers-2|case-|vib-A_pAr+ne|tam-A
VM	gend-|num-|pers-2|case-|vib-A_uT+la|tam-A
VM	gend-|num-|pers-2|case-|vib-A_xe+be|tam-A
VM	gend-|num-|pers-2|case-|vib-Be_ACa+ne|tam-Be
VM	gend-|num-|pers-2|case-|vib-Be_As+ne|tam-Be
VM	gend-|num-|pers-2|case-|vib-Be_ne+la|tam-Be
VM	gend-|num-|pers-2|case-|vib-Be_uT+Ce|tam-Be
VM	gend-|num-|pers-2|case-|vib-Be_uT+be|tam-Be
VM	gend-|num-|pers-2|case-|vib-Be_xe+lei_pAr+wa|tam-Be
VM	gend-|num-|pers-2|case-|vib-Be_yA+be|tam-Be
VM	gend-|num-|pers-2|case-|vib-Ce|tam-Ce
VM	gend-|num-|pers-2|case-|vib-Cila|tam-Cila
VM	gend-|num-|pers-2|case-|vib-be|tam-be
VM	gend-|num-|pers-2|case-|vib-iwe_pAr+ne|tam-iwe
VM	gend-|num-|pers-2|case-|vib-iyZe_ne+la|tam-iyZe
VM	gend-|num-|pers-2|case-|vib-iyZe_xe+la|tam-iyZe
VM	gend-|num-|pers-2|case-|vib-la|tam-la
VM	gend-|num-|pers-2|case-|vib-li|tam-li
VM	gend-|num-|pers-2|case-|vib-nA_be|tam-be
VM	gend-|num-|pers-2|case-|vib-nA_la|tam-la
VM	gend-|num-|pers-2|case-|vib-nA_ne|tam-ne
VM	gend-|num-|pers-2|case-|vib-ne_As+be|tam-ne
VM	gend-|num-|pers-2|case-|vib-ne_As+ne|tam-ne
VM	gend-|num-|pers-2|case-|vib-ne_Pel+la|tam-ne
VM	gend-|num-|pers-2|case-|vib-ne_padZ+la|tam-ne
VM	gend-|num-|pers-2|case-|vib-ne_xe+la|tam-ne
VM	gend-|num-|pers-2|case-|vib-ne_xe+ne|tam-ne
VM	gend-|num-|pers-2|case-|vib-ne|tam-ne
VM	gend-|num-|pers-2|case-|vib-wai|tam-wai
VM	gend-|num-|pers-2|case-|vib-wa|tam-wa
VM	gend-|num-|pers-2|case-|vib-yZa|tam-yZa
VM	gend-|num-|pers-3|case-|vib-|tam-
VM	gend-|num-|pers-3|case-|vib-0_pAr+be|tam-
VM	gend-|num-|pers-3|case-|vib-0_yA+ka|tam-
VM	gend-|num-|pers-3|case-|vib-A_WAk+be|tam-A
VM	gend-|num-|pers-3|case-|vib-A_ha+be|tam-A
VM	gend-|num-|pers-3|case-|vib-A_pAr+be|tam-A
VM	gend-|num-|pers-3|case-|vib-A_pAr+ini|tam-A
VM	gend-|num-|pers-3|case-|vib-A_yA+be|tam-A
VM	gend-|num-|pers-3|case-|vib-Be_yA+be|tam-Be
VM	gend-|num-|pers-3|case-|vib-Ce|tam-Ce
VM	gend-|num-|pers-3|case-|vib-Cila|tam-Cila
VM	gend-|num-|pers-3|case-|vib-be|tam-be
VM	gend-|num-|pers-3|case-|vib-eni|tam-eni
VM	gend-|num-|pers-3|case-|vib-ini|tam-ini
VM	gend-|num-|pers-3|case-|vib-ka_ha+be|tam-ka
VM	gend-|num-|pers-3|case-|vib-ka_yA+be|tam-ka
VM	gend-|num-|pers-3|case-|vib-ka|tam-ka
VM	gend-|num-|pers-3|case-|vib-nA_Ce|tam-Ce
VM	gend-|num-|pers-3|case-|vib-nA_be|tam-be
VM	gend-|num-|pers-3|case-|vib-nA_ka|tam-ka
VM	gend-|num-|pers-3|case-|vib-ne_ne+A_ha+be|tam-ne
VM	gend-|num-|pers-3|case-|vib-ne_yA+ka|tam-ne
VM	gend-|num-|pers-3|case-|vib-ne|tam-ne
VM	gend-|num-|pers-4|case-|vib-|tam-
VM	gend-|num-|pers-4|case-|vib-A_WAkA+ka|tam-A
VM	gend-|num-|pers-4|case-|vib-A_pAr+ka|tam-A
VM	gend-|num-|pers-4|case-|vib-Be_WAkA+ka|tam-Be
VM	gend-|num-|pers-4|case-|vib-iyZe_AnA+ka|tam-iyZe
VM	gend-|num-|pers-4|case-|vib-ka_halya|tam-ka
VM	gend-|num-|pers-4|case-|vib-ka_hayeCe|tam-ka
VM	gend-|num-|pers-4|case-|vib-ka_hayeCila|tam-ka
VM	gend-|num-|pers-4|case-|vib-ka_yAcCila|tam-ka
VM	gend-|num-|pers-4|case-|vib-ka_yAy|tam-ka
VM	gend-|num-|pers-4|case-|vib-ka|tam-ka
VM	gend-|num-|pers-4|case-|vib-la|tam-la
VM	gend-|num-|pers-4|case-|vib-nA_ka|tam-ka
VM	gend-|num-|pers-4|case-|vib-nA_paryyanwa_ka|tam-ka
VM	gend-|num-|pers-4|case-|vib-nAi_ka|tam-ka
VM	gend-|num-|pers-5|case-|vib-|tam-
VM	gend-|num-|pers-5|case-|vib-0_As+Ce|tam-
VM	gend-|num-|pers-5|case-|vib-0_As+la|tam-
VM	gend-|num-|pers-5|case-|vib-0_Cila+wai|tam-
VM	gend-|num-|pers-5|case-|vib-0_WAk+ne|tam-
VM	gend-|num-|pers-5|case-|vib-0_cal+Ce|tam-
VM	gend-|num-|pers-5|case-|vib-0_mar+ne|tam-
VM	gend-|num-|pers-5|case-|vib-0_ne|tam-
VM	gend-|num-|pers-5|case-|vib-0_padZ+ne|tam-
VM	gend-|num-|pers-5|case-|vib-0_rAKA+ka_ha+la|tam-
VM	gend-|num-|pers-5|case-|vib-0_uT+ne|tam-
VM	gend-|num-|pers-5|case-|vib-0_xe+la|tam-
VM	gend-|num-|pers-5|case-|vib-0_yA+Ce|tam-
VM	gend-|num-|pers-5|case-|vib-0_yA+la|tam-
VM	gend-|num-|pers-5|case-|vib-0_yA+ne|tam-
VM	gend-|num-|pers-5|case-|vib-0_yAc+Ce|tam-
VM	gend-|num-|pers-5|case-|vib-A_WAk+ne|tam-A
VM	gend-|num-|pers-5|case-|vib-A_cA+ne|tam-A
VM	gend-|num-|pers-5|case-|vib-A_ha+Ce|tam-A
VM	gend-|num-|pers-5|case-|vib-A_ha+eni|tam-A
VM	gend-|num-|pers-5|case-|vib-A_ha+la|tam-A
VM	gend-|num-|pers-5|case-|vib-A_ha+ne|tam-A
VM	gend-|num-|pers-5|case-|vib-A_ha+wa|tam-A
VM	gend-|num-|pers-5|case-|vib-A_lAg+la|tam-A
VM	gend-|num-|pers-5|case-|vib-A_pA+Ce|tam-A
VM	gend-|num-|pers-5|case-|vib-A_pA+la|tam-A
VM	gend-|num-|pers-5|case-|vib-A_pA+ne|tam-A
VM	gend-|num-|pers-5|case-|vib-A_pAr+ne|tam-A
VM	gend-|num-|pers-5|case-|vib-A_padZ+Cila|tam-A
VM	gend-|num-|pers-5|case-|vib-A_per+Ce|tam-A
VM	gend-|num-|pers-5|case-|vib-A_per+ne|tam-A
VM	gend-|num-|pers-5|case-|vib-A_yA+Ce|tam-A
VM	gend-|num-|pers-5|case-|vib-A_yA+Cila|tam-A
VM	gend-|num-|pers-5|case-|vib-Be_An+Ce|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_As+Ce|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_As+la|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_Pel+ne|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_WAk+A_pArA+ka_yA+eni|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_WAk+ne|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_cal+Ce|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_cal+la|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_cal+ne|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_ne+Ce|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_padZ+Ce|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_padZ+eni|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_padZ+ne|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_uT+la|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_xe+Ce|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_xe+ne|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_xeoyZA+ka_ha+ne|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_yA+Ce|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_yA+iwe_WAk+ne|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_yA+iwe_pAr+ne|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_yA+la|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_yA+ne|tam-Be
VM	gend-|num-|pers-5|case-|vib-Be_yAc+Ce|tam-Be
VM	gend-|num-|pers-5|case-|vib-Ce|tam-Ce
VM	gend-|num-|pers-5|case-|vib-Cila|tam-Cila
VM	gend-|num-|pers-5|case-|vib-eni|tam-eni
VM	gend-|num-|pers-5|case-|vib-iwe_bas+Ce|tam-iwe
VM	gend-|num-|pers-5|case-|vib-iyZe_ACa+ne|tam-iyZe
VM	gend-|num-|pers-5|case-|vib-iyZe_ne+Be_yAc+Ce|tam-iyZe
VM	gend-|num-|pers-5|case-|vib-iyZe_ne|tam-iyZe
VM	gend-|num-|pers-5|case-|vib-iyZe_padZ+ne|tam-iyZe
VM	gend-|num-|pers-5|case-|vib-iyZe_rAK+ne|tam-iyZe
VM	gend-|num-|pers-5|case-|vib-iyZe_xe+Ce|tam-iyZe
VM	gend-|num-|pers-5|case-|vib-iyZe_xe+ne|tam-iyZe
VM	gend-|num-|pers-5|case-|vib-iyZe_xe+wa|tam-iyZe
VM	gend-|num-|pers-5|case-|vib-iyZe_yA+ne|tam-iyZe
VM	gend-|num-|pers-5|case-|vib-i|tam-i
VM	gend-|num-|pers-5|case-|vib-ka_ha+A_WAk+ne|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka_ha+Ce|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka_ha+Cila|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka_ha+la|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka_ha+ne|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka_padZ+ne|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka_xe+A_pAr+ne|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka_xe+ne|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka_yA+Ce|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka_yA+eni|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka_yA+iwe_pAr+ne|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka_yA+ka|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka_yA+la|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka_yA+ne|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka_yAc+Ce|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka_yewei_pAr+ne|tam-ka
VM	gend-|num-|pers-5|case-|vib-ka|tam-ka
VM	gend-|num-|pers-5|case-|vib-la|tam-la
VM	gend-|num-|pers-5|case-|vib-nA_Ce|tam-Ce
VM	gend-|num-|pers-5|case-|vib-nA_Cila|tam-Cila
VM	gend-|num-|pers-5|case-|vib-nA_ka|tam-ka
VM	gend-|num-|pers-5|case-|vib-nA_la|tam-la
VM	gend-|num-|pers-5|case-|vib-nA_ne|tam-ne
VM	gend-|num-|pers-5|case-|vib-nA_wai|tam-wai
VM	gend-|num-|pers-5|case-|vib-nA_wa|tam-wa
VM	gend-|num-|pers-5|case-|vib-nAi_pAr+ne_0|tam-
VM	gend-|num-|pers-5|case-|vib-ne_As+la|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_Cila+wai|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_Pel+Ce|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_Pel+ne|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_WAk+eni|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_WAk+ne|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_bas+Ce|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_bas+wa|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_cal+Ce|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_cal+ne|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_cal_janya|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_ne+A_ha+ne|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_ne|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_oTA|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_oTe|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_padZ+ne|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_pa|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_rAK+Cila|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_uT+Ce|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_wul+Cila|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_xe+A_ha+ne|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_xe+Ce|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_xeoyZA+ka_ha+ne|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_yA+Ce|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_yA+iwe_pAr+ne|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_yA+la|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_yA+ne|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne_yAc+Ce|tam-ne
VM	gend-|num-|pers-5|case-|vib-ne|tam-ne
VM	gend-|num-|pers-5|case-|vib-ni_ne|tam-ne
VM	gend-|num-|pers-5|case-|vib-wai|tam-wai
VM	gend-|num-|pers-5|case-|vib-wa|tam-wa
VM	gend-|num-|pers-6|case-|vib-|tam-
VM	gend-|num-|pers-6|case-|vib-Be_As+ka|tam-Be
VM	gend-|num-|pers-6|case-|vib-Be_yA+ka|tam-Be
VM	gend-|num-|pers-6|case-|vib-eni|tam-eni
VM	gend-|num-|pers-6|case-|vib-iyZe_yA+ka|tam-iyZe
VM	gend-|num-|pers-6|case-|vib-ka_yA+ka|tam-ka
VM	gend-|num-|pers-6|case-|vib-ka|tam-ka
VM	gend-|num-|pers-6|case-|vib-nA_be|tam-be
VM	gend-|num-|pers-6|case-|vib-ne_Pel+ka|tam-ne
VM	gend-|num-|pers-6|case-|vib-ne_xe+ka|tam-ne
VM	gend-|num-|pers-6|case-|vib-ne_yA+ka|tam-ne
VM	gend-|num-|pers-6|case-|vib-oni|tam-oni
VM	gend-|num-|pers-7|case-|vib-|tam-
VM	gend-|num-|pers-7|case-|vib-0_As+A|tam-
VM	gend-|num-|pers-7|case-|vib-0_pAr+leo|tam-
VM	gend-|num-|pers-7|case-|vib-0_xe+A|tam-
VM	gend-|num-|pers-7|case-|vib-A_ACa+A|tam-A
VM	gend-|num-|pers-7|case-|vib-A_As+A|tam-A
VM	gend-|num-|pers-7|case-|vib-A_CAdZA|tam-A
VM	gend-|num-|pers-7|case-|vib-A_cAy|tam-A
VM	gend-|num-|pers-7|case-|vib-A_giye|tam-A
VM	gend-|num-|pers-7|case-|vib-A_oTe|tam-A
VM	gend-|num-|pers-7|case-|vib-A_pAr+le|tam-A
VM	gend-|num-|pers-7|case-|vib-A_yA+Ao|tam-A
VM	gend-|num-|pers-7|case-|vib-A_yA+A|tam-A
VM	gend-|num-|pers-7|case-|vib-Ao|tam-Ao
VM	gend-|num-|pers-7|case-|vib-A|tam-A
VM	gend-|num-|pers-7|case-|vib-Be_ACa+A|tam-Be
VM	gend-|num-|pers-7|case-|vib-Be_uT+A|tam-Be
VM	gend-|num-|pers-7|case-|vib-Be_yA+A|tam-Be
VM	gend-|num-|pers-7|case-|vib-iyZe_WAk+A|tam-iyZe
VM	gend-|num-|pers-7|case-|vib-iyZe_padZ+le|tam-iyZe
VM	gend-|num-|pers-7|case-|vib-i|tam-i
VM	gend-|num-|pers-7|case-|vib-ka_ACa+A|tam-ka
VM	gend-|num-|pers-7|case-|vib-ka_ha+leo|tam-ka
VM	gend-|num-|pers-7|case-|vib-lei|tam-lei
VM	gend-|num-|pers-7|case-|vib-leo|tam-leo
VM	gend-|num-|pers-7|case-|vib-le|tam-le
VM	gend-|num-|pers-7|case-|vib-nA_Ao|tam-Ao
VM	gend-|num-|pers-7|case-|vib-nA_A|tam-A
VM	gend-|num-|pers-7|case-|vib-nA_lei|tam-lei
VM	gend-|num-|pers-7|case-|vib-nA_leo|tam-leo
VM	gend-|num-|pers-7|case-|vib-nA_le|tam-le
VM	gend-|num-|pers-7|case-|vib-ne_As+A|tam-ne
VM	gend-|num-|pers-7|case-|vib-ne_Pel+le|tam-ne
VM	gend-|num-|pers-7|case-|vib-ne_bas+ne_ACa+A|tam-ne
VM	gend-|num-|pers-7|case-|vib-ne_yA+A|tam-ne
VM	gend-|num-|pers-7|case-|vib-ni_A|tam-A
VM	gend-|num-|pers-7|case-|vib-ni|tam-ni
VM	gend-|num-|pers-any|case-|vib-|tam-
VM	gend-|num-|pers-any|case-|vib-0_Pel|tam-
VM	gend-|num-|pers-any|case-|vib-0_gel+Be|tam-
VM	gend-|num-|pers-any|case-|vib-0_janya|tam-
VM	gend-|num-|pers-any|case-|vib-0_mawa|tam-
VM	gend-|num-|pers-any|case-|vib-0_xe|tam-
VM	gend-|num-|pers-any|case-|vib-A_xe|tam-A
VM	gend-|num-|pers-any|case-|vib-Be_WAk|tam-Be
VM	gend-|num-|pers-any|case-|vib-Be_ne+A_hay|tam-Be
VM	gend-|num-|pers-any|case-|vib-Be_oTAyZa|tam-Be
VM	gend-|num-|pers-any|case-|vib-Be_oTe|tam-Be
VM	gend-|num-|pers-any|case-|vib-Be_pATAyZa|tam-Be
VM	gend-|num-|pers-any|case-|vib-Be_xAzdZAyZa|tam-Be
VM	gend-|num-|pers-any|case-|vib-Be_xe|tam-Be
VM	gend-|num-|pers-any|case-|vib-Be_yA+we|tam-Be
VM	gend-|num-|pers-any|case-|vib-Be_yewei|tam-Be
VM	gend-|num-|pers-any|case-|vib-Be|tam-Be
VM	gend-|num-|pers-any|case-|vib-iwe|tam-iwe
VM	gend-|num-|pers-any|case-|vib-iyZe_WAk+Be|tam-iyZe
VM	gend-|num-|pers-any|case-|vib-iyZe_gel+Be|tam-iyZe
VM	gend-|num-|pers-any|case-|vib-iyZe_xe|tam-iyZe
VM	gend-|num-|pers-any|case-|vib-iyZe|tam-iyZe
VM	gend-|num-|pers-any|case-|vib-ka_gel+Be|tam-ka
VM	gend-|num-|pers-any|case-|vib-ka_kar+A_gel+Be|tam-ka
VM	gend-|num-|pers-any|case-|vib-ka_xe+Be|tam-ka
VM	gend-|num-|pers-any|case-|vib-nA_0|tam-
VM	gend-|num-|pers-any|case-|vib-nA_Be|tam-Be
VM	gend-|num-|pers-any|case-|vib-nA_iyZe|tam-iyZe
VM	gend-|num-|pers-any|case-|vib-nA_we|tam-we
VM	gend-|num-|pers-any|case-|vib-ne_ne+Be|tam-ne
VM	gend-|num-|pers-any|case-|vib-ne_xe+Be|tam-ne
VM	gend-|num-|pers-any|case-|vib-we|tam-we
VM	gend-|num-|pers-any|case-|vib-|tam-
VM	gend-|num-|pers-|case-|vib-0_WAkibyi|tam-
VM	gend-|num-|pers-|case-|vib-0_geCye|tam-
VM	gend-|num-|pers-|case-|vib-0_geleo|tam-
VM	gend-|num-|pers-|case-|vib-0_giye|tam-
VM	gend-|num-|pers-|case-|vib-0_habeka|tam-
VM	gend-|num-|pers-|case-|vib-0_janya|tam-
VM	gend-|num-|pers-|case-|vib-0_liyZez_AsyeCi|tam-
VM	gend-|num-|pers-|case-|vib-0_ney|tam-
VM	gend-|num-|pers-|case-|vib-0_oTe|tam-
VM	gend-|num-|pers-|case-|vib-0_xao|tam-
VM	gend-|num-|pers-|case-|vib-0_xiCi|tam-
VM	gend-|num-|pers-|case-|vib-nA_0|tam-
VM	gend-|num-|pers-|case-|vib-|tam-
WQ	gend-|num-sg|pers-|case-d|vib-0|tam-0
WQ	gend-|num-sg|pers-|case-d|vib-|tam-
WQ	gend-|num-sg|pers-|case-o|vib-era|tam-era
WQ	gend-|num-sg|pers-|case-o|vib-|tam-
WQ	gend-|num-|pers-|case-|vib-0_Weke|tam-
WQ	gend-|num-|pers-|case-|vib-|tam-
XC	gend-|num-sg|pers-|case-o|vib-era|tam-era
XC	gend-|num-sg|pers-|case-o|vib-|tam-
XC	gend-|num-|pers-|case-|vib-|tam-
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

Lingua::Interset::Tagset::BN::Conll - Driver for the Bengali tagset of the ICON 2009 and 2010 Shared Tasks, as used in the CoNLL data format.

=head1 VERSION

version 3.013

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::BN::Conll;
  my $driver = Lingua::Interset::Tagset::BN::Conll->new();
  my $fs = $driver->decode("NN\tcat-n|gend-|num-sg|pers-|case-d|vib-0|tam-0");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('bn::conll', "NN\tcat-n|gend-|num-sg|pers-|case-d|vib-0|tam-0");

=head1 DESCRIPTION

Interset driver for the Bengali tagset of the ICON 2009 and 2010 Shared Tasks,
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

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
