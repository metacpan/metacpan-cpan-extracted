# ABSTRACT: Driver for the tagset of the Latin Dependency Treebank in CoNLL format.
# Copyright © 2011, 2015 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Copyright © 2011 Loganathan Ramasamy <ramasamy@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::LA::Conll;
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
    return 'la::conll';
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
            'n' => ['pos' => 'noun'],
            'v' => ['pos' => 'verb'],
            't' => ['pos' => 'verb', 'verbform' => 'part'],
            'a' => ['pos' => 'adj'],
            'd' => ['pos' => 'adv'],
            'l' => ['pos' => 'adj', 'prontype' => 'art'],
            'g' => ['pos' => 'part'],
            'c' => ['pos' => 'conj'],
            'r' => ['pos' => 'adp', 'adpostype' => 'prep'],
            'p' => ['pos' => 'noun', 'prontype' => 'prn'],
            'm' => ['pos' => 'num'],
            # Documentation mentions "i" (interjection) and "e" (exclamation).
            # I found only "e" in the data. So I will decode both but encode "e" only.
            'i' => ['pos' => 'int'], # interjection
            'e' => ['pos' => 'int'], # exclamation
            'u' => ['pos' => 'punc'],
            'x' => [] # unknown; sometimes also '-' is used
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''  => 'n',
                                                   '@' => 'p' }},
                       'verb' => { 'verbform' => { 'part' => 't',
                                                   'ger'  => 't',
                                                   'gdv'  => 't',
                                                   '@'    => 'v' }},
                       'adj'  => { 'prontype' => { 'art' => 'l',
                                                   '@'   => 'a' }},
                       'adv'  => 'd',
                       'part' => 'g',
                       'conj' => 'c',
                       'adp'  => 'r',
                       'num'  => 'm',
                       'int'  => 'e',
                       'punc' => 'u',
                       '@'    => 'x' }
        }
    );
    # PERSON ####################
    $atoms{per} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            '1' => '1',
            '2' => '2',
            '3' => '3'
        },
        'encode_default' => '-'
    );
    # NUMBER ####################
    $atoms{num} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            's' => 'sing',
            'd' => 'dual',
            'p' => 'plur'
        },
        'encode_default' => '-'
    );
    # TENSE ####################
    $atoms{ten} = $self->create_atom
    (
        'surfeature' => 'ten',
        'decode_map' =>
        {
            'p' => ['tense' => 'pres'],                     # present: ἔχει, ἐστὶ, ἐστιν, χρὴ, ἔστι
            'a' => ['tense' => 'aor'],                      # aorist: βῆ, προσέειπε, ἦλθε, βάλε, στῆ
            'i' => ['tense' => 'imp', 'aspect' => 'imp'],   # imperfect: προσέφη, προσηύδα, ἦν, ἦεν, ηὔδα
            'r' => ['tense' => 'past', 'aspect' => 'perf'], # perfect: ἔοικε, ἔοικεν, οἶδεν, οἶδε, οἶδ’
            'l' => ['tense' => 'pqp', 'aspect' => 'perf'],  # pluperfect: ὀρώρει, βεβήκει, ᾔδη, ἑστήκει, ἐῴκει
            't' => ['tense' => 'fut', 'aspect' => 'perf'],  # future perfect: κεχολώσεται, τετεύξεται, κεκλήσεται, τεθάψεται, ἐφάψεται
            'f' => ['tense' => 'fut'],                      # future: δώσει, ἕξει, μελήσει, ἐρέει, ἐρεῖ
        },
        'encode_map' =>
        {
            'tense' => { 'pres' => 'p',
                         'past' => { 'aspect' => { 'imp'  => 'i',
                                                   'perf' => 'r',
                                                   '@'    => 'a' }},
                         'aor'  => 'a',
                         'imp'  => 'i',
                         'pqp'  => 'l',
                         'fut'  => { 'aspect' => { 'perf' => 't',
                                                   '@'    => 'f' }},
                         '@'    => '-' }
        }
    );
    # MOOD ####################
    $atoms{mod} = $self->create_atom
    (
        'surfeature' => 'mod',
        'decode_map' =>
        {
            'i' => ['verbform' => 'fin', 'mood' => 'ind'],
            's' => ['verbform' => 'fin', 'mood' => 'sub'],
            'o' => ['verbform' => 'fin', 'mood' => 'opt'],
            'm' => ['verbform' => 'fin', 'mood' => 'imp'],
            'n' => ['verbform' => 'inf'],
            'p' => ['verbform' => 'part'],
            'd' => ['verbform' => 'ger'], # gerund (active, rare):         cenandum, vindicandum, faciendum, suspicandum, vivendum
            'g' => ['verbform' => 'gdv'], # gerundive (passive, frequent): recidendum, admirandum, providendum, intolerandum, verendum
        },
        'encode_map' =>
        {
            'verbform' => { 'inf'  => 'n',
                            'fin'  => { 'mood' => { 'ind' => 'i',
                                                    'sub' => 's',
                                                    'opt' => 'o',
                                                    'imp' => 'm',
                                                    '@'   => '-' }},
                            'part' => 'p',
                            'ger'  => 'd',
                            'gdv'  => 'g',
                            '@'    => '-' }
        }
    );
    # VOICE ####################
    # http://en.wikipedia.org/wiki/Mediopassive_voice
    # Ancient Greek had a mediopassive in the present, imperfect, perfect, and pluperfect tenses,
    # but in the aorist and future tenses the mediopassive voice was replaced by two voices, one middle and one passive.
    $atoms{voi} = $self->create_atom
    (
        'surfeature' => 'voi',
        'decode_map' =>
        {
            'a' => ['voice' => 'act'],
            # Middle voice is neither active nor passive but somewhere inbetween.
            # http://en.wikipedia.org/wiki/Voice_%28grammar%29#Middle
            'm' => ['voice' => 'mid'],
            'p' => ['voice' => 'pass'],
            # Medio-passive is a merger of the middle and the passive voices.
            # http://en.wikipedia.org/wiki/Mediopassive_voice
            'e' => ['voice' => 'mid|pass']
        },
        'encode_map' =>
        {
            'voice' => { 'act'      => 'a',
                         'mid|pass' => 'e',
                         'mid'      => 'm',
                         'pass'     => 'p',
                         '@'        => '-' }
        }
    );
    # GENDER ####################
    $atoms{gen} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'm' => 'masc',
            'f' => 'fem',
            'n' => 'neut'
        },
        'encode_default' => '-'
    );
    # CASE ####################
    $atoms{cas} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'n' => 'nom',
            'g' => 'gen',
            'd' => 'dat',
            'a' => 'acc',
            'v' => 'voc',
            'l' => 'loc',
            'b' => 'abl'
        },
        'encode_default' => '-'
    );
    # DEGREE OF COMPARISON ####################
    $atoms{deg} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'c' => 'cmp',
            's' => 'sup'
        },
        'encode_default' => '-'
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
    my @features = ('pos', 'per', 'num', 'ten', 'mod', 'voi', 'gen', 'cas', 'deg');
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
    # Default feature values. Used to improve collaboration with other drivers.
    # ... nothing yet ...
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
    my $subpos = $pos;
    my $feature_names = $self->features_all();
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus: total 419 tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
a	a	pos=a|per=-|num=-|ten=-|mod=-|voi=-|gen=-|cas=-|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=-|cas=b|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=-|cas=b|deg=c
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=-|cas=d|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=a|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=a|deg=c
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=a|deg=s
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=b|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=b|deg=s
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=d|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=d|deg=s
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=g|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=n|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=n|deg=c
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=n|deg=s
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=v|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=a|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=a|deg=c
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=a|deg=s
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=b|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=b|deg=c
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=b|deg=s
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=d|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=d|deg=s
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=g|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=g|deg=c
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=n|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=n|deg=c
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=n|deg=s
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=v|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=v|deg=s
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=a|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=a|deg=c
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=a|deg=s
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=b|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=b|deg=c
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=d|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=g|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=n|deg=-
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=n|deg=c
a	a	pos=a|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=n|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=-|cas=-|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=-|cas=a|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=-|cas=b|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=-|cas=b|deg=c
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=-|cas=g|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=-|cas=g|deg=c
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=-|cas=n|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=-|cas=n|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=a|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=a|deg=c
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=a|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=b|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=b|deg=c
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=b|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=d|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=g|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=g|deg=c
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=g|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=l|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=n|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=n|deg=c
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=n|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=v|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=v|deg=c
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=v|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=a|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=a|deg=c
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=a|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=b|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=b|deg=c
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=b|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=d|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=d|deg=c
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=d|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=g|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=g|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=n|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=n|deg=c
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=n|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=v|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=v|deg=c
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=v|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=a|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=a|deg=c
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=a|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=b|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=b|deg=c
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=b|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=d|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=g|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=g|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=n|deg=-
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=n|deg=c
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=n|deg=s
a	a	pos=a|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=v|deg=-
c	c	pos=c|per=-|num=-|ten=-|mod=-|voi=-|gen=-|cas=-|deg=-
d	d	pos=d|per=-|num=-|ten=-|mod=-|voi=-|gen=-|cas=-|deg=-
d	d	pos=d|per=-|num=-|ten=-|mod=-|voi=-|gen=-|cas=-|deg=c
d	d	pos=d|per=-|num=-|ten=-|mod=-|voi=-|gen=-|cas=-|deg=s
e	e	pos=e|per=-|num=-|ten=-|mod=-|voi=-|gen=-|cas=-|deg=-
m	m	pos=m|per=-|num=-|ten=-|mod=-|voi=-|gen=-|cas=-|deg=-
n	n	pos=n|per=-|num=-|ten=-|mod=-|voi=-|gen=-|cas=-|deg=-
n	n	pos=n|per=-|num=-|ten=-|mod=-|voi=-|gen=m|cas=-|deg=-
n	n	pos=n|per=-|num=-|ten=-|mod=-|voi=-|gen=n|cas=-|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=-|cas=b|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=-|cas=d|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=-|cas=n|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=-|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=a|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=b|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=d|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=g|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=n|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=v|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=a|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=b|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=d|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=g|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=n|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=v|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=a|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=b|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=d|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=g|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=n|deg=-
n	n	pos=n|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=v|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=-|cas=a|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=-|cas=b|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=-|cas=n|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=-|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=a|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=b|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=d|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=g|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=l|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=n|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=v|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=-|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=a|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=b|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=d|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=g|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=l|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=n|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=v|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=-|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=a|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=b|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=d|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=g|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=n|deg=-
n	n	pos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=v|deg=-
n	n	pos=n|per=-|num=s|ten=p|mod=-|voi=-|gen=-|cas=v|deg=-
p	p	pos=p|per=-|num=-|ten=-|mod=-|voi=-|gen=-|cas=-|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=a|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=b|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=d|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=g|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=n|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=f|cas=v|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=a|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=b|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=d|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=g|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=m|cas=n|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=a|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=b|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=d|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=g|deg=-
p	p	pos=p|per=-|num=p|ten=-|mod=-|voi=-|gen=n|cas=n|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=-|cas=b|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=a|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=b|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=d|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=g|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=n|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=f|cas=v|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=a|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=b|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=d|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=g|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=n|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=v|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=a|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=b|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=d|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=g|deg=-
p	p	pos=p|per=-|num=s|ten=-|mod=-|voi=-|gen=n|cas=n|deg=-
r	r	pos=r|per=-|num=-|ten=-|mod=-|voi=-|gen=-|cas=-|deg=-
t	t	pos=t|per=-|num=-|ten=p|mod=p|voi=a|gen=m|cas=n|deg=-
t	t	pos=t|per=-|num=-|ten=r|mod=p|voi=p|gen=m|cas=g|deg=-
t	t	pos=t|per=-|num=p|ten=-|mod=p|voi=a|gen=m|cas=a|deg=-
t	t	pos=t|per=-|num=p|ten=f|mod=p|voi=a|gen=m|cas=a|deg=-
t	t	pos=t|per=-|num=p|ten=f|mod=p|voi=a|gen=m|cas=n|deg=-
t	t	pos=t|per=-|num=p|ten=f|mod=p|voi=a|gen=n|cas=a|deg=-
t	t	pos=t|per=-|num=p|ten=f|mod=p|voi=a|gen=n|cas=b|deg=-
t	t	pos=t|per=-|num=p|ten=f|mod=p|voi=a|gen=n|cas=n|deg=-
t	t	pos=t|per=-|num=p|ten=f|mod=p|voi=p|gen=m|cas=a|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=g|voi=p|gen=f|cas=a|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=g|voi=p|gen=f|cas=b|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=g|voi=p|gen=f|cas=g|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=g|voi=p|gen=f|cas=n|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=g|voi=p|gen=m|cas=a|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=g|voi=p|gen=m|cas=b|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=g|voi=p|gen=m|cas=g|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=g|voi=p|gen=m|cas=n|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=g|voi=p|gen=n|cas=a|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=g|voi=p|gen=n|cas=b|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=g|voi=p|gen=n|cas=g|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=g|voi=p|gen=n|cas=n|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=a|gen=f|cas=a|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=a|gen=f|cas=b|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=a|gen=f|cas=d|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=a|gen=f|cas=g|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=a|gen=f|cas=n|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=a|gen=f|cas=v|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=a|gen=m|cas=a|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=a|gen=m|cas=b|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=a|gen=m|cas=d|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=a|gen=m|cas=g|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=a|gen=m|cas=n|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=a|gen=n|cas=a|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=a|gen=n|cas=b|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=a|gen=n|cas=n|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=a|gen=n|cas=v|deg=-
t	t	pos=t|per=-|num=p|ten=p|mod=p|voi=p|gen=f|cas=b|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=-|gen=n|cas=n|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=a|gen=f|cas=a|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=a|gen=f|cas=b|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=a|gen=m|cas=a|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=a|gen=m|cas=n|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=f|cas=-|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=f|cas=a|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=f|cas=b|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=f|cas=d|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=f|cas=g|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=f|cas=n|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=m|cas=a|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=m|cas=b|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=m|cas=d|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=m|cas=g|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=m|cas=n|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=m|cas=v|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=n|cas=a|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=n|cas=b|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=n|cas=d|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=n|cas=g|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=n|cas=n|deg=-
t	t	pos=t|per=-|num=p|ten=r|mod=p|voi=p|gen=n|cas=v|deg=-
t	t	pos=t|per=-|num=s|ten=-|mod=p|voi=p|gen=f|cas=n|deg=-
t	t	pos=t|per=-|num=s|ten=f|mod=p|voi=a|gen=f|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=f|mod=p|voi=a|gen=f|cas=n|deg=-
t	t	pos=t|per=-|num=s|ten=f|mod=p|voi=a|gen=f|cas=v|deg=-
t	t	pos=t|per=-|num=s|ten=f|mod=p|voi=a|gen=m|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=f|mod=p|voi=a|gen=m|cas=n|deg=-
t	t	pos=t|per=-|num=s|ten=f|mod=p|voi=a|gen=n|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=f|mod=p|voi=a|gen=n|cas=g|deg=-
t	t	pos=t|per=-|num=s|ten=f|mod=p|voi=a|gen=n|cas=n|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=d|voi=a|gen=n|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=d|voi=a|gen=n|cas=b|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=d|voi=a|gen=n|cas=g|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=g|voi=a|gen=m|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=g|voi=p|gen=f|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=g|voi=p|gen=f|cas=d|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=g|voi=p|gen=f|cas=g|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=g|voi=p|gen=f|cas=n|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=g|voi=p|gen=m|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=g|voi=p|gen=m|cas=b|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=g|voi=p|gen=m|cas=g|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=g|voi=p|gen=m|cas=n|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=g|voi=p|gen=n|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=g|voi=p|gen=n|cas=b|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=g|voi=p|gen=n|cas=g|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=g|voi=p|gen=n|cas=n|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=g|voi=p|gen=n|cas=v|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=f|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=f|cas=b|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=f|cas=d|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=f|cas=g|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=f|cas=n|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=f|cas=n|deg=c
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=m|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=m|cas=b|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=m|cas=d|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=m|cas=g|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=m|cas=n|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=m|cas=n|deg=c
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=n|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=n|cas=b|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=n|cas=d|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=n|cas=g|deg=-
t	t	pos=t|per=-|num=s|ten=p|mod=p|voi=a|gen=n|cas=n|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=a|gen=f|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=a|gen=m|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=a|gen=m|cas=n|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=a|gen=n|cas=b|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=f|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=f|cas=b|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=f|cas=d|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=f|cas=g|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=f|cas=n|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=m|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=m|cas=b|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=m|cas=d|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=m|cas=g|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=m|cas=n|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=m|cas=v|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=n|cas=a|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=n|cas=b|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=n|cas=d|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=n|cas=g|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=n|cas=n|deg=-
t	t	pos=t|per=-|num=s|ten=r|mod=p|voi=p|gen=n|cas=v|deg=-
u	u	pos=u|per=-|num=-|ten=-|mod=-|voi=-|gen=-|cas=-|deg=-
v	v	pos=v|per=-|num=-|ten=-|mod=n|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=-|num=-|ten=f|mod=n|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=-|num=-|ten=p|mod=n|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=-|num=-|ten=p|mod=n|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=-|num=-|ten=r|mod=n|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=-|ten=r|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=p|ten=f|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=p|ten=f|mod=i|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=p|ten=i|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=p|ten=i|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=p|ten=i|mod=s|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=p|ten=l|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=p|ten=l|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=p|ten=p|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=p|ten=p|mod=i|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=p|ten=p|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=p|ten=p|mod=s|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=p|ten=r|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=p|ten=r|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=f|mod=-|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=f|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=f|mod=i|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=i|mod=-|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=i|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=i|mod=i|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=i|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=i|mod=s|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=l|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=l|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=p|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=p|mod=i|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=p|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=p|mod=s|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=r|mod=-|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=r|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=r|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=1|num=s|ten=t|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=p|ten=f|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=p|ten=f|mod=m|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=p|ten=i|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=p|ten=i|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=p|ten=l|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=p|ten=p|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=p|ten=p|mod=i|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=p|ten=p|mod=m|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=p|ten=p|mod=m|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=p|ten=p|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=p|ten=p|mod=s|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=p|ten=r|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=p|ten=r|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=-|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=f|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=f|mod=i|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=f|mod=m|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=i|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=i|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=l|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=l|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=p|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=p|mod=i|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=p|mod=m|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=p|mod=m|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=p|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=p|mod=s|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=r|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=r|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=2|num=s|ten=t|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=f|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=f|mod=i|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=f|mod=m|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=i|mod=-|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=i|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=i|mod=i|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=i|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=i|mod=s|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=l|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=l|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=p|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=p|mod=i|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=p|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=p|mod=s|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=r|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=r|mod=i|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=r|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=p|ten=t|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=-|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=-|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=f|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=f|mod=i|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=i|mod=-|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=i|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=i|mod=i|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=i|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=i|mod=s|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=l|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=l|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=p|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=p|mod=i|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=p|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=p|mod=s|voi=p|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=r|mod=-|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=r|mod=i|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=r|mod=s|voi=a|gen=-|cas=-|deg=-
v	v	pos=v|per=3|num=s|ten=t|mod=i|voi=a|gen=-|cas=-|deg=-
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

Lingua::Interset::Tagset::LA::Conll - Driver for the tagset of the Latin Dependency Treebank in CoNLL format.

=head1 VERSION

version 3.012

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::LA::Conll;
  my $driver = Lingua::Interset::Tagset::LA::Conll->new();
  my $fs = $driver->decode("n\tn\tpos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=n|deg=-");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('la::conll', "n\tn\tpos=n|per=-|num=s|ten=-|mod=-|voi=-|gen=m|cas=n|deg=-");

=head1 DESCRIPTION

Interset driver for the tagset of the Latin Dependency Treebank in CoNLL format.
The original tags are positional, there are nine positions.
This driver covers a format that we used in HamleDT processing where the input was first converted to CoNLL.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::Conll>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
