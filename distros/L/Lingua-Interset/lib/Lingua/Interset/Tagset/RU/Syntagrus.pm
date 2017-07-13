# ABSTRACT: Driver for Syntagrus (Russian Dependency Treebank) tags.
# Copyright © 2006, 2011, 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::RU::Syntagrus;
use strict;
use warnings;
our $VERSION = '3.006';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset';



has 'atoms' => ( isa => 'HashRef', is => 'ro', builder => '_create_atoms', lazy => 1 );
has 'features_all' => ( isa => 'ArrayRef', is => 'ro', builder => '_create_features_all', lazy => 1 );



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'ru::syntagrus';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for the surface features.
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
            'A'    => ['pos' => 'adj'],
            'ADV'  => ['pos' => 'adv'],
            'COM'  => ['hyph' => 'yes'],
            'CONJ' => ['pos' => 'conj'],
            'INTJ' => ['pos' => 'int'],
            'NID'  => [], # unknown word
            'NUM'  => ['pos' => 'num'],
            'P'    => ['pos' => 'part'],
            'PART' => ['pos' => 'part'],
            'PR'   => ['pos' => 'adp', 'adpostype' => 'prep'],
            'S'    => ['pos' => 'noun'],
            'V'    => ['pos' => 'verb']
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => 'S',
                       'adj'  => 'A',
                       'num'  => 'NUM',
                       'verb' => 'V',
                       'adv'  => 'ADV',
                       'adp'  => 'PR',
                       'conj' => 'CONJ',
                       'part' => 'PART',
                       'int'  => 'INTJ',
                       '@'    => { 'hyph' => { 'yes' => 'COM',
                                               '@'    => 'NID' }}}
        }
    );
    # SHORT (NOMINAL) FORM OF ADJECTIVES ####################
    $atoms{shortadj} = $self->create_simple_atom
    (
        'intfeature' => 'variant',
        'simple_decode_map' =>
        {
            'КР' => 'short'
        }
    );
    # PART OF COMPOUND ####################
    $atoms{compart} = $self->create_simple_atom
    (
        'intfeature' => 'hyph',
        'simple_decode_map' =>
        {
            'СЛ' => 'yes'
        }
    );
    # PO- (SMJAG) ####################
    # For adjectives and adverbs: distinguishes forms with prefix по-
    # (поближе, поскорее, подальше) from normal forms (больше, меньше, быстрей, дальше, позже).
    $atoms{smjag} = $self->create_atom
    (
        'surfeature' => 'smjag',
        'decode_map' =>
        {
            'СМЯГ' => ['other' => {'smjag' => '1'}]
        },
        'encode_map' =>
        {
            'other/smjag' => { '1' => 'СМЯГ' }
        }
    );
    # NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'ЕД' => 'sing',
            'МН' => 'plur'
        }
    );
    # GENDER ####################
    $atoms{gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'ЖЕН'  => 'fem',
            'МУЖ'  => 'masc',
            'СРЕД' => 'neut'
        }
    );
    # ANIMACY ####################
    $atoms{animacy} = $self->create_simple_atom
    (
        'intfeature' => 'animacy',
        'simple_decode_map' =>
        {
            'НЕОД' => 'inan',
            'ОД'   => 'anim'
        }
    );
    # CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            # Именительный / Номинатив (Nominative)
            'ИМ'    => 'nom',
            # Родительный / Генитив (Genitive)
            'РОД'   => 'gen',
            # Количественно-отделительный (партитив, или второй родительный) (Partitive) [not in Russian schools]
            # Subcase of РОД. Occasionally the word form differs if the genitive.
            # It is used for the noun describing a whole in relation to parts;
            # these forms may also be preferred with mass nouns.
            # «нет сахара» vs. «положить сахару»
            'ПАРТ'  => 'par',
            # Дательный / Датив (Dative)
            'ДАТ'   => 'dat',
            # Винительный / Аккузатив (Accusative)
            'ВИН'   => 'acc',
            # Звательный (вокатив) (Vocative) [not in Russian schools]
            # only one word type: "Господи"
            'ЗВ'    => 'voc',
            # Предложный / Препозитив (Prepositional) [in Russian schools taught as the last one after instrumental?]
            # See also "МЕСТН" below. Since "ПР" is the more widely used value and since it is parallel to locative
            # cases in other Slavic languages, I use "loc" for "ПР" and seek another Interset value for "МЕСТН".
            'ПР'    => 'loc',
            # [not in Russian schools]
            # Subcase of ПР. ПР is used for two meanings: 'about what?' (о чём?) and 'where?' (где?).
            # The word forms of the two meanings mostly overlap but there are about 100 words whose forms differ:
            # «о шкафе» — «в шкафу»
            'МЕСТН' => 'ine',
            # Творительный / Аблатив (объединяет инструментатив [Instrumental], локатив и аблатив)
            'ТВОР'  => 'ins'
        }
    );
    # DEGREE OF COMPARISON ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'СРАВ' => 'cmp',
            'ПРЕВ' => 'sup'
        }
    );
    # ASPECT ####################
    $atoms{aspect} = $self->create_simple_atom
    (
        'intfeature' => 'aspect',
        'simple_decode_map' =>
        {
            'НЕСОВ' => 'imp',
            'СОВ'   => 'perf'
        }
    );
    # VERB FORM ####################
    $atoms{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            'ДЕЕПР' => ['verbform' => 'conv'],
            'ИЗЪЯВ' => ['verbform' => 'fin', 'mood' => 'ind'],
            'ИНФ'   => ['verbform' => 'inf'],
            'ПОВ'   => ['verbform' => 'fin', 'mood' => 'imp'],
            'ПРИЧ'  => ['verbform' => 'part']
        },
        'encode_map' =>
        {
            'verbform' => { 'inf'  => 'ИНФ',
                            'fin'  => { 'mood' => { 'imp' => 'ПОВ',
                                                    '@'   => 'ИЗЪЯВ' }},
                            'part' => 'ПРИЧ',
                            'conv' => 'ДЕЕПР' }
        }
    );
    # TENSE ####################
    $atoms{tense} = $self->create_simple_atom
    (
        'intfeature' => 'tense',
        'simple_decode_map' =>
        {
            'НЕПРОШ' => 'pres|fut',
            'ПРОШ'   => 'past',
            'НАСТ'   => 'pres'
        }
    );
    # PERSON ####################
    $atoms{person} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            '1-Л' => '1',
            '2-Л' => '2',
            '3-Л' => '3'
        }
    );
    # VOICE ####################
    $atoms{voice} = $self->create_simple_atom
    (
        'intfeature' => 'voice',
        'simple_decode_map' =>
        {
            # Voice: страдательный залог = passive voice
            'СТРАД' => 'pass'
        }
    );
    # NON-STANDARD SPELLING ####################
    $atoms{typo} = $self->create_simple_atom
    (
        'intfeature' => 'typo',
        'simple_decode_map' =>
        {
            'НЕСТАНД' => 'yes'
        }
    );
    # OBSOLETE TAGS ####################
    $atoms{obsolete} = $self->create_atom
    (
        'surfeature' => 'obsolete',
        'decode_map' =>
        {
            # This tag has been encountered at one token only, without any obvious purpose.
            'МЕТА'   => ['other' => {'obsolete' => 'meta'}],
            # This tag has been encountered at two tokens only, without any obvious purpose.
            'НЕПРАВ' => ['other' => {'obsolete' => 'neprav'}]
        },
        'encode_map' =>
        {
            'other/obsolete' => { 'meta'   => 'МЕТА',
                                  'neprav' => 'НЕПРАВ' }
        }
    );
    # MERGED ATOM TO DECODE ANY FEATURE VALUE ####################
    my @fatoms = map {$atoms{$_}} (@{$self->features_all()});
    $atoms{feature} = $self->create_merged_atom
    (
        'surfeature' => 'feature',
        'atoms'      => \@fatoms
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
    my @features = ('pos', 'degree', 'smjag',
                    'aspect', 'voice', 'verbform', 'tense', 'shortadj',
                    'number', 'gender', 'case', 'animacy', 'person',
                    'compart', 'typo', 'obsolete');
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
    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset('ru::syntagrus');
    my $atoms = $self->atoms();
    my @features = split(/\s+/, $tag);
    foreach my $feature (@features)
    {
        $atoms->{feature}->decode_and_merge_hard($feature, $fs);
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
    my $features = $self->features_all();
    my @features = ();
    if(defined($features))
    {
        foreach my $feature (@{$features})
        {
            if(defined($feature) && defined($atoms->{$feature}))
            {
                my $value = $atoms->{$feature}->encode($fs);
                if(defined($value) && $value ne '')
                {
                    push(@features, $value);
                }
            }
        }
    }
    my $tag = join(' ', @features);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# The corpus contains 376 different tags.
# After cleaning up (PART vs. P; COM) we have 374 tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
A
A ЕД ЖЕН ВИН
A ЕД ЖЕН ДАТ
A ЕД ЖЕН ИМ
A ЕД ЖЕН ИМ МЕТА
A ЕД ЖЕН ПР
A ЕД ЖЕН РОД
A ЕД ЖЕН ТВОР
A ЕД МУЖ ВИН НЕОД
A ЕД МУЖ ВИН ОД
A ЕД МУЖ ДАТ
A ЕД МУЖ ИМ
A ЕД МУЖ ПР
A ЕД МУЖ РОД
A ЕД МУЖ ТВОР
A ЕД СРЕД ВИН
A ЕД СРЕД ДАТ
A ЕД СРЕД ИМ
A ЕД СРЕД ПР
A ЕД СРЕД РОД
A ЕД СРЕД ТВОР
A КР ЕД ЖЕН
A КР ЕД МУЖ
A КР ЕД СРЕД
A КР МН
A МН ВИН НЕОД
A МН ВИН ОД
A МН ДАТ
A МН ИМ
A МН ПР
A МН РОД
A МН ТВОР
A ПРЕВ ЕД ЖЕН ИМ
A ПРЕВ ЕД ЖЕН РОД
A ПРЕВ ЕД ЖЕН ТВОР
A ПРЕВ ЕД МУЖ ИМ
A ПРЕВ ЕД МУЖ ПР
A ПРЕВ ЕД МУЖ РОД
A ПРЕВ ЕД СРЕД ИМ
A ПРЕВ МН ВИН НЕОД
A ПРЕВ МН ВИН ОД
A ПРЕВ МН ДАТ
A ПРЕВ МН ИМ
A ПРЕВ МН ПР
A ПРЕВ МН РОД
A СЛ
A СРАВ
A СРАВ СМЯГ
ADV
ADV НЕСТАНД
ADV СРАВ
ADV СРАВ СМЯГ
COM СЛ
CONJ
INTJ
NID
NUM
NUM ВИН
NUM ВИН НЕОД
NUM ВИН ОД
NUM ДАТ
NUM ЕД ЖЕН ВИН
NUM ЕД ЖЕН ДАТ
NUM ЕД ЖЕН ИМ
NUM ЕД ЖЕН ПР
NUM ЕД ЖЕН РОД
NUM ЕД ЖЕН ТВОР
NUM ЕД МУЖ ВИН НЕОД
NUM ЕД МУЖ ВИН ОД
NUM ЕД МУЖ ДАТ
NUM ЕД МУЖ ИМ
NUM ЕД МУЖ ПР
NUM ЕД МУЖ РОД
NUM ЕД МУЖ ТВОР
NUM ЕД СРЕД ВИН
NUM ЕД СРЕД ИМ
NUM ЕД СРЕД ПР
NUM ЕД СРЕД РОД
NUM ЕД СРЕД ТВОР
NUM ЖЕН ВИН НЕОД
NUM ЖЕН ДАТ
NUM ЖЕН ИМ
NUM ЖЕН РОД
NUM ИМ
NUM МУЖ ВИН НЕОД
NUM МУЖ ВИН ОД
NUM МУЖ ДАТ
NUM МУЖ ИМ
NUM ПР
NUM РОД
NUM СЛ
NUM СРЕД ВИН
NUM СРЕД ИМ
NUM ТВОР
PART
PART НЕПРАВ
PR
S ЕД ЖЕН ВИН
S ЕД ЖЕН ВИН НЕОД
S ЕД ЖЕН ВИН ОД
S ЕД ЖЕН ДАТ
S ЕД ЖЕН ДАТ НЕОД
S ЕД ЖЕН ДАТ ОД
S ЕД ЖЕН ИМ
S ЕД ЖЕН ИМ НЕОД
S ЕД ЖЕН ИМ ОД
S ЕД ЖЕН МЕСТН НЕОД
S ЕД ЖЕН ПР
S ЕД ЖЕН ПР НЕОД
S ЕД ЖЕН ПР ОД
S ЕД ЖЕН РОД
S ЕД ЖЕН РОД НЕОД
S ЕД ЖЕН РОД НЕОД НЕСТАНД
S ЕД ЖЕН РОД ОД
S ЕД ЖЕН РОД ОД НЕСТАНД
S ЕД ЖЕН ТВОР НЕОД
S ЕД ЖЕН ТВОР ОД
S ЕД МУЖ ВИН НЕОД
S ЕД МУЖ ВИН ОД
S ЕД МУЖ ДАТ
S ЕД МУЖ ДАТ НЕОД
S ЕД МУЖ ДАТ ОД
S ЕД МУЖ ДАТ ОД НЕСТАНД
S ЕД МУЖ ЗВ ОД
S ЕД МУЖ ИМ
S ЕД МУЖ ИМ НЕОД
S ЕД МУЖ ИМ ОД
S ЕД МУЖ ИМ ОД НЕСТАНД
S ЕД МУЖ МЕСТН НЕОД
S ЕД МУЖ НЕОД
S ЕД МУЖ ПАРТ НЕОД
S ЕД МУЖ ПР
S ЕД МУЖ ПР НЕОД
S ЕД МУЖ ПР ОД
S ЕД МУЖ РОД
S ЕД МУЖ РОД НЕОД
S ЕД МУЖ РОД ОД
S ЕД МУЖ ТВОР
S ЕД МУЖ ТВОР НЕОД
S ЕД МУЖ ТВОР ОД
S ЕД МУЖ ТВОР ОД НЕСТАНД
S ЕД СРЕД ВИН
S ЕД СРЕД ВИН НЕОД
S ЕД СРЕД ВИН ОД
S ЕД СРЕД ДАТ
S ЕД СРЕД ДАТ НЕОД
S ЕД СРЕД ИМ
S ЕД СРЕД ИМ НЕОД
S ЕД СРЕД ИМ ОД
S ЕД СРЕД НЕОД
S ЕД СРЕД ПР
S ЕД СРЕД ПР НЕОД
S ЕД СРЕД РОД
S ЕД СРЕД РОД НЕОД
S ЕД СРЕД РОД ОД
S ЕД СРЕД ТВОР НЕОД
S ЕД СРЕД ТВОР ОД
S ЖЕН НЕОД СЛ
S МН ВИН НЕОД
S МН ВИН ОД
S МН ДАТ
S МН ДАТ НЕОД
S МН ДАТ ОД
S МН ЖЕН ВИН НЕОД
S МН ЖЕН ВИН ОД
S МН ЖЕН ДАТ НЕОД
S МН ЖЕН ДАТ ОД
S МН ЖЕН ИМ НЕОД
S МН ЖЕН ИМ ОД
S МН ЖЕН НЕОД
S МН ЖЕН ПР НЕОД
S МН ЖЕН РОД НЕОД
S МН ЖЕН РОД ОД
S МН ЖЕН ТВОР НЕОД
S МН ЖЕН ТВОР ОД
S МН ИМ
S МН ИМ НЕОД
S МН ИМ ОД
S МН МУЖ ВИН НЕОД
S МН МУЖ ВИН ОД
S МН МУЖ ДАТ НЕОД
S МН МУЖ ДАТ ОД
S МН МУЖ ИМ НЕОД
S МН МУЖ ИМ ОД
S МН МУЖ ИМ ОД НЕСТАНД
S МН МУЖ ПР НЕОД
S МН МУЖ ПР ОД
S МН МУЖ РОД НЕОД
S МН МУЖ РОД НЕОД НЕСТАНД
S МН МУЖ РОД ОД
S МН МУЖ РОД ОД НЕСТАНД
S МН МУЖ ТВОР НЕОД
S МН МУЖ ТВОР ОД
S МН ПР
S МН ПР НЕОД
S МН ПР ОД
S МН РОД
S МН РОД НЕОД
S МН РОД ОД
S МН СРЕД ВИН НЕОД
S МН СРЕД ВИН ОД
S МН СРЕД ДАТ НЕОД
S МН СРЕД ДАТ ОД
S МН СРЕД ИМ НЕОД
S МН СРЕД ИМ ОД
S МН СРЕД НЕОД
S МН СРЕД ПР НЕОД
S МН СРЕД ПР ОД
S МН СРЕД РОД НЕОД
S МН СРЕД РОД ОД
S МН СРЕД ТВОР НЕОД
S МН СРЕД ТВОР ОД
S МН ТВОР
S МН ТВОР НЕОД
S МН ТВОР ОД
S МУЖ НЕОД СЛ
S МУЖ ОД СЛ
S СРЕД НЕОД СЛ
V НЕСОВ ДЕЕПР НЕПРОШ
V НЕСОВ ДЕЕПР ПРОШ
V НЕСОВ ИЗЪЯВ НАСТ ЕД 2-Л
V НЕСОВ ИЗЪЯВ НАСТ ЕД 3-Л
V НЕСОВ ИЗЪЯВ НАСТ МН 3-Л
V НЕСОВ ИЗЪЯВ НЕПРОШ ЕД 1-Л
V НЕСОВ ИЗЪЯВ НЕПРОШ ЕД 2-Л
V НЕСОВ ИЗЪЯВ НЕПРОШ ЕД 3-Л
V НЕСОВ ИЗЪЯВ НЕПРОШ ЕД 3-Л НЕСТАНД
V НЕСОВ ИЗЪЯВ НЕПРОШ МН 1-Л
V НЕСОВ ИЗЪЯВ НЕПРОШ МН 2-Л
V НЕСОВ ИЗЪЯВ НЕПРОШ МН 3-Л
V НЕСОВ ИЗЪЯВ НЕПРОШ МН 3-Л НЕСТАНД
V НЕСОВ ИЗЪЯВ ПРОШ ЕД ЖЕН
V НЕСОВ ИЗЪЯВ ПРОШ ЕД МУЖ
V НЕСОВ ИЗЪЯВ ПРОШ ЕД СРЕД
V НЕСОВ ИЗЪЯВ ПРОШ МН
V НЕСОВ ИНФ
V НЕСОВ ПОВ ЕД 2-Л
V НЕСОВ ПОВ МН 2-Л
V НЕСОВ ПРИЧ НЕПРОШ ЕД ЖЕН ВИН
V НЕСОВ ПРИЧ НЕПРОШ ЕД ЖЕН ИМ
V НЕСОВ ПРИЧ НЕПРОШ ЕД ЖЕН ПР
V НЕСОВ ПРИЧ НЕПРОШ ЕД ЖЕН РОД
V НЕСОВ ПРИЧ НЕПРОШ ЕД ЖЕН ТВОР
V НЕСОВ ПРИЧ НЕПРОШ ЕД МУЖ ВИН НЕОД
V НЕСОВ ПРИЧ НЕПРОШ ЕД МУЖ ВИН ОД
V НЕСОВ ПРИЧ НЕПРОШ ЕД МУЖ ДАТ
V НЕСОВ ПРИЧ НЕПРОШ ЕД МУЖ ИМ
V НЕСОВ ПРИЧ НЕПРОШ ЕД МУЖ ПР
V НЕСОВ ПРИЧ НЕПРОШ ЕД МУЖ РОД
V НЕСОВ ПРИЧ НЕПРОШ ЕД МУЖ ТВОР
V НЕСОВ ПРИЧ НЕПРОШ ЕД СРЕД ВИН
V НЕСОВ ПРИЧ НЕПРОШ ЕД СРЕД ИМ
V НЕСОВ ПРИЧ НЕПРОШ ЕД СРЕД ПР
V НЕСОВ ПРИЧ НЕПРОШ ЕД СРЕД РОД
V НЕСОВ ПРИЧ НЕПРОШ ЕД СРЕД ТВОР
V НЕСОВ ПРИЧ НЕПРОШ МН ВИН НЕОД
V НЕСОВ ПРИЧ НЕПРОШ МН ВИН ОД
V НЕСОВ ПРИЧ НЕПРОШ МН ДАТ
V НЕСОВ ПРИЧ НЕПРОШ МН ИМ
V НЕСОВ ПРИЧ НЕПРОШ МН ПР
V НЕСОВ ПРИЧ НЕПРОШ МН РОД
V НЕСОВ ПРИЧ НЕПРОШ МН ТВОР
V НЕСОВ ПРИЧ ПРОШ ЕД ЖЕН ДАТ
V НЕСОВ ПРИЧ ПРОШ ЕД ЖЕН ИМ
V НЕСОВ ПРИЧ ПРОШ ЕД ЖЕН ПР
V НЕСОВ ПРИЧ ПРОШ ЕД ЖЕН ТВОР
V НЕСОВ ПРИЧ ПРОШ ЕД МУЖ ВИН НЕОД
V НЕСОВ ПРИЧ ПРОШ ЕД МУЖ ИМ
V НЕСОВ ПРИЧ ПРОШ ЕД МУЖ РОД
V НЕСОВ ПРИЧ ПРОШ ЕД МУЖ ТВОР
V НЕСОВ ПРИЧ ПРОШ ЕД СРЕД ВИН
V НЕСОВ ПРИЧ ПРОШ МН ВИН НЕОД
V НЕСОВ ПРИЧ ПРОШ МН ВИН ОД
V НЕСОВ ПРИЧ ПРОШ МН ДАТ
V НЕСОВ ПРИЧ ПРОШ МН ИМ
V НЕСОВ ПРИЧ ПРОШ МН РОД
V НЕСОВ ПРИЧ ПРОШ МН ТВОР
V НЕСОВ СТРАД ИЗЪЯВ НЕПРОШ ЕД 3-Л
V НЕСОВ СТРАД ИЗЪЯВ НЕПРОШ МН 3-Л
V НЕСОВ СТРАД ИЗЪЯВ ПРОШ ЕД ЖЕН
V НЕСОВ СТРАД ИЗЪЯВ ПРОШ ЕД МУЖ
V НЕСОВ СТРАД ИЗЪЯВ ПРОШ ЕД СРЕД
V НЕСОВ СТРАД ИЗЪЯВ ПРОШ МН
V НЕСОВ СТРАД ИНФ
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД ЖЕН ИМ
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД ЖЕН РОД
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД ЖЕН ТВОР
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД МУЖ ИМ
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД МУЖ РОД
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД МУЖ ТВОР
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД СРЕД ВИН
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД СРЕД ИМ
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД СРЕД РОД
V НЕСОВ СТРАД ПРИЧ НЕПРОШ МН ВИН НЕОД
V НЕСОВ СТРАД ПРИЧ НЕПРОШ МН ИМ
V НЕСОВ СТРАД ПРИЧ НЕПРОШ МН РОД
V НЕСОВ СТРАД ПРИЧ ПРОШ ЕД ЖЕН ВИН
V НЕСОВ СТРАД ПРИЧ ПРОШ ЕД МУЖ ВИН ОД
V НЕСОВ СТРАД ПРИЧ ПРОШ ЕД СРЕД ВИН
V НЕСОВ СТРАД ПРИЧ ПРОШ ЕД СРЕД ИМ
V НЕСОВ СТРАД ПРИЧ ПРОШ КР ЕД ЖЕН
V НЕСОВ СТРАД ПРИЧ ПРОШ КР ЕД СРЕД
V НЕСОВ СТРАД ПРИЧ ПРОШ КР МН
V НЕСОВ СТРАД ПРИЧ ПРОШ МН ИМ
V СОВ ДЕЕПР НЕПРОШ
V СОВ ДЕЕПР ПРОШ
V СОВ ДЕЕПР ПРОШ НЕПРАВ
V СОВ ИЗЪЯВ НЕПРОШ ЕД 1-Л
V СОВ ИЗЪЯВ НЕПРОШ ЕД 1-Л НЕСТАНД
V СОВ ИЗЪЯВ НЕПРОШ ЕД 2-Л
V СОВ ИЗЪЯВ НЕПРОШ ЕД 3-Л
V СОВ ИЗЪЯВ НЕПРОШ МН 1-Л
V СОВ ИЗЪЯВ НЕПРОШ МН 2-Л
V СОВ ИЗЪЯВ НЕПРОШ МН 3-Л
V СОВ ИЗЪЯВ ПРОШ ЕД ЖЕН
V СОВ ИЗЪЯВ ПРОШ ЕД МУЖ
V СОВ ИЗЪЯВ ПРОШ ЕД СРЕД
V СОВ ИЗЪЯВ ПРОШ МН
V СОВ ИНФ
V СОВ ПОВ ЕД 2-Л
V СОВ ПОВ ЕД 2-Л НЕСТАНД
V СОВ ПОВ МН 1-Л
V СОВ ПОВ МН 2-Л
V СОВ ПРИЧ ПРОШ ЕД ЖЕН ВИН
V СОВ ПРИЧ ПРОШ ЕД ЖЕН ДАТ
V СОВ ПРИЧ ПРОШ ЕД ЖЕН ИМ
V СОВ ПРИЧ ПРОШ ЕД ЖЕН ПР
V СОВ ПРИЧ ПРОШ ЕД ЖЕН ТВОР
V СОВ ПРИЧ ПРОШ ЕД МУЖ ВИН НЕОД
V СОВ ПРИЧ ПРОШ ЕД МУЖ ВИН ОД
V СОВ ПРИЧ ПРОШ ЕД МУЖ ДАТ
V СОВ ПРИЧ ПРОШ ЕД МУЖ ИМ
V СОВ ПРИЧ ПРОШ ЕД МУЖ ПР
V СОВ ПРИЧ ПРОШ ЕД МУЖ РОД
V СОВ ПРИЧ ПРОШ ЕД МУЖ ТВОР
V СОВ ПРИЧ ПРОШ ЕД СРЕД ВИН
V СОВ ПРИЧ ПРОШ ЕД СРЕД ИМ
V СОВ ПРИЧ ПРОШ ЕД СРЕД ПР
V СОВ ПРИЧ ПРОШ ЕД СРЕД РОД
V СОВ ПРИЧ ПРОШ ЕД СРЕД ТВОР
V СОВ ПРИЧ ПРОШ МН ВИН НЕОД
V СОВ ПРИЧ ПРОШ МН ВИН ОД
V СОВ ПРИЧ ПРОШ МН ИМ
V СОВ ПРИЧ ПРОШ МН ПР
V СОВ ПРИЧ ПРОШ МН РОД
V СОВ ПРИЧ ПРОШ МН ТВОР
V СОВ СТРАД ПРИЧ ПРОШ ЕД ЖЕН ВИН
V СОВ СТРАД ПРИЧ ПРОШ ЕД ЖЕН ДАТ
V СОВ СТРАД ПРИЧ ПРОШ ЕД ЖЕН ИМ
V СОВ СТРАД ПРИЧ ПРОШ ЕД ЖЕН ПР
V СОВ СТРАД ПРИЧ ПРОШ ЕД ЖЕН РОД
V СОВ СТРАД ПРИЧ ПРОШ ЕД ЖЕН ТВОР
V СОВ СТРАД ПРИЧ ПРОШ ЕД МУЖ ВИН НЕОД
V СОВ СТРАД ПРИЧ ПРОШ ЕД МУЖ ДАТ
V СОВ СТРАД ПРИЧ ПРОШ ЕД МУЖ ИМ
V СОВ СТРАД ПРИЧ ПРОШ ЕД МУЖ ПР
V СОВ СТРАД ПРИЧ ПРОШ ЕД МУЖ РОД
V СОВ СТРАД ПРИЧ ПРОШ ЕД МУЖ ТВОР
V СОВ СТРАД ПРИЧ ПРОШ ЕД СРЕД ВИН
V СОВ СТРАД ПРИЧ ПРОШ ЕД СРЕД ИМ
V СОВ СТРАД ПРИЧ ПРОШ ЕД СРЕД ПР
V СОВ СТРАД ПРИЧ ПРОШ ЕД СРЕД РОД
V СОВ СТРАД ПРИЧ ПРОШ ЕД СРЕД ТВОР
V СОВ СТРАД ПРИЧ ПРОШ КР ЕД ЖЕН
V СОВ СТРАД ПРИЧ ПРОШ КР ЕД МУЖ
V СОВ СТРАД ПРИЧ ПРОШ КР ЕД СРЕД
V СОВ СТРАД ПРИЧ ПРОШ КР МН
V СОВ СТРАД ПРИЧ ПРОШ МН ВИН НЕОД
V СОВ СТРАД ПРИЧ ПРОШ МН ВИН ОД
V СОВ СТРАД ПРИЧ ПРОШ МН ДАТ
V СОВ СТРАД ПРИЧ ПРОШ МН ИМ
V СОВ СТРАД ПРИЧ ПРОШ МН ПР
V СОВ СТРАД ПРИЧ ПРОШ МН РОД
V СОВ СТРАД ПРИЧ ПРОШ МН ТВОР
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

Lingua::Interset::Tagset::RU::Syntagrus - Driver for Syntagrus (Russian Dependency Treebank) tags.

=head1 VERSION

version 3.006

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::RU::Syntagrus;
  my $driver = Lingua::Interset::Tagset::RU::Syntagrus->new();
  my $fs = $driver->decode('S ЕД МУЖ ИМ');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('ru::syntagrus', 'S ЕД МУЖ ИМ');

=head1 DESCRIPTION

Interset driver for Syntagrus (Russian Dependency Treebank) tags.

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
