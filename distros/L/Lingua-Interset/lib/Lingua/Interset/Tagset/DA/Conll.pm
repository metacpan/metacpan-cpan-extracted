# ABSTRACT: Driver for the Danish tagset of the CoNLL 2006 Shared Task (derived from the Danish Parole tagset).
# Copyright © 2006-2009, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::DA::Conll;
use strict;
use warnings;
our $VERSION = '3.010';

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
    return 'da::conll';
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
            # N = noun
            # common noun
            'NC' => ['pos' => 'noun', 'nountype' => 'com'],
            # proper noun
            'NP' => ['pos' => 'noun', 'nountype' => 'prop'],
            # A = adjective or numeral
            'AN' => ['pos' => 'adj'],
            'AC' => ['pos' => 'num', 'numtype' => 'card'],
            'AO' => ['pos' => 'adj', 'numtype' => 'ord'],
            # P = pronoun
            'PP' => ['pos' => 'noun', 'prontype' => 'prs'],
            'PO' => ['pos' => 'adj', 'prontype' => 'prs', 'poss' => 'yes'],
            'PC' => ['pos' => 'noun', 'prontype' => 'rcp'],
            'PD' => ['pos' => 'noun|adj', 'prontype' => 'dem'],
            'PI' => ['pos' => 'noun|adj', 'prontype' => 'ind'],
            'PT' => ['pos' => 'noun|adj', 'prontype' => 'int|rel'],
            # V = verb
            # VA = main verb
            # VE = medial verb
            #     - deponent verb
            #     - reciprocal verb
            #     (medial verbs are passive in form and active in meaning)
            'VA' => ['pos' => 'verb'],
            'VE' => ['pos' => 'verb', 'other' => {'verbtype' => 'medial'}],
            # RG = adverb
            'RG' => ['pos' => 'adv'],
            # SP = preposition
            'SP' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # C = conjunction
            'CC' => ['pos' => 'conj', 'conjtype' => 'coor'],
            'CS' => ['pos' => 'conj', 'conjtype' => 'sub'],
            # U = unique (including particles?)
            # ... infinitivmark&osla;ren "at"
            # ... "som"
            # ... "der"
            # We cannot distinguish those three without seeing the actual word.
            # Since infinitive is the most important and most frequent of them, we
            # will choose infinitive.
            'U'  => ['pos' => 'part', 'parttype' => 'inf'],
            # I = interjection
            'I'  => ['pos' => 'int'],
            # X = residual class
            'XA' => ['abbr' => 'yes'],
            'XF' => ['foreign' => 'yes'],
            'XP' => ['pos' => 'punc'],
            # symbol, e.g. "+"
            'XS' => ['pos' => 'sym'],
            # formulae, e.g. "U-21"
            # nothing to do - same as "other"
            'XR' => ['other' => {'pos' => 'formula'}],
            # other than the above
            'XX' => []
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''    => { 'nountype' => { 'prop' => 'NP',
                                                                              '@'    => 'NC' }},
                                                   'prs' => { 'poss' => { 'yes' => 'PO',
                                                                          '@'    => 'PP' }},
                                                   'rcp' => 'PC',
                                                   'dem' => 'PD',
                                                   'int' => 'PT',
                                                   'rel' => 'PT',
                                                   '@'   => 'PI' }},
                       'adj'  => { 'prontype' => { ''    => { 'numtype' => { 'card' => 'AC',
                                                                             'ord'  => 'AO',
                                                                             '@'    => 'AN' }},
                                                   'prs' => { 'poss' => { 'yes' => 'PO',
                                                                          '@'    => 'PP' }},
                                                   'rcp' => 'PC',
                                                   'dem' => 'PD',
                                                   'int' => 'PT',
                                                   'rel' => 'PT',
                                                   '@'   => 'PI' }},
                       'num'  => { 'numtype' => { 'ord' => 'AO',
                                                  '@'   => 'AC' }},
                       'verb' => { 'other/verbtype' => { 'medial' => 'VE',
                                                         '@'      => 'VA' }},
                       'adv'  => 'RG',
                       'adp'  => 'SP',
                       'conj' => { 'conjtype' => { 'sub' => 'CS',
                                                   '@'   => 'CC' }},
                       'part' => 'U',
                       'int'  => 'I',
                       'punc' => 'XP',
                       'sym'  => 'XS',
                       '@'    => { 'abbr' => { 'yes' => 'XA',
                                               '@'    => { 'foreign' => { 'yes' => 'XF',
                                                                          '@'       => { 'other/pos' => { 'formula' => 'XR',
                                                                                                          '@'       => 'XX' }}}}}}}
        }
    );
    # GENDER ####################
    $atoms{gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'common'        => 'com',
            'neuter'        => 'neut',
            'common/neuter' => ''
        }
    );
    # NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'sing'      => 'sing',
            'plur'      => 'plur',
            'sing/plur' => ''
        }
    );
    # CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'nom'      => 'nom',
            'gen'      => 'gen',
            'unmarked' => ''
        },
        'encode_default' => 'unmarked'
    );
    # DEFINITENESS ####################
    # For some reason there are two features encoding definiteness: "def" and "definiteness". Their value ranges are identical.
    $atoms{definiteness} = $self->create_simple_atom
    (
        'intfeature' => 'definite',
        'simple_decode_map' =>
        {
            'def'       => 'def',
            'indef'     => 'ind',
            'def/indef' => ''
        }
    );
    $atoms{def} = $atoms{definiteness};
    # DEGREE ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'pos'      => 'pos',
            'comp'     => 'cmp',
            'sup'      => 'sup',
            'abs'      => 'abs',
            'unmarked' => ''
        }
    );
    # REFLEXIVE ####################
    # This feature applies to all personal and possessive pronouns.
    $atoms{reflexive} = $self->create_atom
    (
        'surfeature' => 'reflexive',
        'decode_map' =>
        {
            # Irreflexive personal pronouns: jeg, du, De, han, hun, den, ham, hende, det, dét, vi, I, de, dem
            # Irreflexive possessive pronouns: min, mine, mit, din, dine, dit, Deres, hans, hendes, dets, vor, vores, vore, vort, jeres, deres
            # Personal pronouns that can but need not be reflexive: mig, dig, Dem, os, jer
            # Reflexive personal pronoun: sig
            # Reflexive possessive pronouns: sin, sine, sit
            'no'     => ['other' => {'reflex' => 'no'}],
            'yes'    => ['reflex' => 'yes'],
            'yes/no' => ['other' => {'reflex' => 'maybe'}]
        },
        'encode_map' =>
        {
            'reflex' => { 'yes' => 'yes',
                          '@'      => { 'other/reflex' => { 'no' => 'no',
                                                            '@'  => { 'poss' => { 'yes' => 'no',
                                                                                  '@'    => { 'case' => { 'nom' => 'no',
                                                                                                          '@'   => 'yes/no' }}}}}}}
        }
    );
    # REGISTER ####################
    $atoms{register} = $self->create_atom
    (
        'surfeature' => 'register',
        'decode_map' =>
        {
            'polite'   => ['polite' => 'form'],
            'formal'   => ['style'  => 'form'],
            'obsolete' => ['style'  => 'arch']
        },
        'encode_map' =>
        {
            'polite' => { 'form' => 'polite',
                          '@'    => { 'style' => { 'form' => 'formal',
                                                   'arch' => 'obsolete',
                                                   '@'    => 'unmarked' }}}
        }
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
        }
    );
    # POSSESSOR ####################
    $atoms{possessor} = $self->create_simple_atom
    (
        'intfeature' => 'possnumber',
        'simple_decode_map' =>
        {
            'sing'      => 'sing',
            'plur'      => 'plur',
            'sing/plur' => ''
        }
    );
    # MOOD ####################
    $atoms{mood} = $self->create_atom
    (
        'surfeature' => 'mood',
        'decode_map' =>
        {
            # er, har, kan, skal, vil
            'indic'  => ['verbform' => 'fin', 'mood' => 'ind'],
            # lad, r&osla;r, sk&ae;r, se
            'imper'  => ['verbform' => 'fin', 'mood' => 'imp'],
            # v&ae;re, f&arin;, have, blive, g&arin;
            'infin'  => ['verbform' => 'inf'],
            # v&ae;ret, blevet, f&arin;et, gjort, haft
            'partic' => ['verbform' => 'part'],
            # medvirken, skelen, undren, banken, skaben
            'gerund' => ['verbform' => 'ger']
        },
        'encode_map' =>
        {
            'verbform' => { 'ger'  => 'gerund',
                            'part' => 'partic',
                            'conv' => 'partic',
                            'inf'  => 'infin',
                            '@'    => { 'mood' => { 'imp' => 'imper',
                                                    'ind' => 'indic' }}}
        }
    );
    # TENSE ####################
    $atoms{tense} = $self->create_simple_atom
    (
        'intfeature' => 'tense',
        'simple_decode_map' =>
        {
            # er, har, kan, skal, vil
            'present' => 'pres',
            # var, havde, blev, kunne, sagde
            'past'    => 'past'
        }
    );
    # VOICE ####################
    $atoms{voice} = $self->create_simple_atom
    (
        'intfeature' => 'voice',
        'simple_decode_map' =>
        {
            # er, har, kan, skal, vil
            'active'  => 'act',
            # ventes, udsendes, kaldes, s&ae;lges, menes
            'passive' => 'pass'
        }
    );
    # TRANSCAT ####################
    # Adjectives (only AN) have transcat either "adverbial" or "unmarked".
    # Verb participles have transcat either "adject", or "adject/adverb/unmarked", or "adverb".
    $atoms{transcat} = $self->create_atom
    (
        'surfeature' => 'transcat',
        'decode_map' =>
        {
            # Adverbial adjective. It has degree but not other features (gender, number, case, definiteness).
            # Examples: meget, helt, godt; mere, senere, tidligere; mest, mindst, senest; allermindst, alleryderst
            'adverbial' => ['variant' => 'short'],
            # Normal adjective. It has all features, even if some of them have disjunction of all values (degree, gender, number, case, definiteness).
            # Examples: stor, ny, lang; stort, godt, nyt; st&osla;rre, bedre, tidligere; bedste, st&osla;rste, seneste; allerinderst, allerst&osla;rste
            'unmarked'  => ['variant' => 'long'],
            # Adjectival participle.
            # Examples: samlede, n&ae;vnte, fortsatte, lukkede, udsendte
            'adject'    => ['verbform' => 'part'],
            # Adverbial participle.
            # Examples: lysende, alarmerende
            'adverb'    => ['verbform' => 'conv'],
            # Participle that cannot be clearly distinguished as adjectival or adverbial.
            # Examples: v&ae;ret, blevet, f&arin;et, gjort, haft; kommende, manglende, f&osla;lgende, administrerende, overlevende
            'adject/adverb/unmarked' => ['verbform' => 'part|conv']
        },
        'encode_map' =>
        {
            'pos' => { 'adj'  => { 'variant' => { 'short' => 'adverbial',
                                                  'long'  => 'unmarked' }},
                       'verb' => { 'verbform' => { 'part|conv' => 'adject/adverb/unmarked',
                                                   'conv'      => 'adverb',
                                                   'part'      => 'adject' }}}
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
    my @features = ('mood', 'tense', 'voice', 'number', 'person', 'degree', 'gender', 'definiteness', 'transcat', 'case', 'def', 'possessor', 'reflexive', 'register');
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
        'NC' => ['gender', 'number', 'case', 'def'],
        'NP' => ['case'],
        'AN' => ['degree', 'gender', 'number', 'case', 'def', 'transcat'],
        'AD' => ['degree', 'transcat'],
        'AC' => ['case'],
        'AO' => ['case'],
        'PC' => ['number', 'case'],
        'PD' => ['gender', 'number', 'case', 'register'],
        'PI' => ['gender', 'number', 'case', 'register'],
        'PO' => ['person', 'gender', 'number', 'case', 'possessor', 'reflexive', 'register'],
        'PP' => ['person', 'gender', 'number', 'case', 'reflexive', 'register'],
        'PT' => ['gender', 'number', 'case', 'register'],
        'RG' => ['degree'],
        'V.infin'  => ['mood', 'voice'],
        'V.indic'  => ['mood', 'tense', 'voice'],
        'V.imper'  => ['mood'],
        'V.partic' => ['mood', 'tense', 'number', 'gender', 'definiteness', 'transcat', 'case'],
        'V.conv'   => ['mood', 'tense', 'transcat'],
        'V.gerund' => ['mood', 'number', 'gender', 'definiteness', 'case']
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
    # Some pronoun forms can be declared accusative/oblique case.
    if($fs->prontype() eq 'prs' && !$fs->is_possessive() && $fs->case() eq '')
    {
        # Most nominative personal pronouns have case=nom. Examples: jeg (I), du (you), han (he), hun (she), vi (we), I (you), de (they).
        # Most accusative personal pronouns have case=unmarked. Examples: mig (me), dig (you), ham (him), hende (her), os (us), jer (you), dem (them), sig (oneself).
        # It is unclear what to do with 3rd person singular pronouns "den" and "det", which have case=unmarked but I suspect they can be used also as nominative.
        $fs->set_case('acc');
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
    my $subpos = $atoms->{pos}->encode($fs);
    my $fpos = $subpos;
    if($fpos =~ m/^V[AE]$/)
    {
        my $verbform = $fs->verbform();
        my $surface_mood = $verbform eq 'conv' ? 'conv' : $atoms->{mood}->encode($fs);
        $fpos = "V.$surface_mood";
    }
    elsif($fpos eq 'AN')
    {
        my $transcat = $atoms->{transcat}->encode($fs);
        if($transcat eq 'adverbial')
        {
            $fpos = 'AD';
        }
    }
    my $feature_names = $self->get_feature_names($fpos);
    my $pos = $subpos =~ m/^(RG|SP)$/ ? $subpos : substr($subpos, 0, 1);
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus, 144 distinct tags found:
# cat danish_ddt_train.conll ../test/danish_ddt_test.conll |\
#   perl -pe '@x = split(/\s+/, $_); $_ = "$x[3]\t$x[4]\t$x[5]\n"' |\
#   sort -u | wc -l
# 147 total tags after adding a few to survive missing value of 'other'.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
A       AC      case=unmarked
A       AN      degree=abs|gender=common/neuter|number=sing/plur|case=unmarked|def=def|transcat=unmarked
A       AN      degree=abs|transcat=adverbial
A       AN      degree=comp|gender=common/neuter|number=plur|case=unmarked|def=def/indef|transcat=unmarked
A       AN      degree=comp|gender=common/neuter|number=sing|case=unmarked|def=indef|transcat=unmarked
A       AN      degree=comp|gender=common/neuter|number=sing/plur|case=gen|def=def/indef|transcat=unmarked
A       AN      degree=comp|gender=common/neuter|number=sing/plur|case=unmarked|def=def/indef|transcat=unmarked
A       AN      degree=comp|transcat=adverbial
A       AN      degree=pos|gender=common/neuter|number=plur|case=gen|def=def/indef|transcat=unmarked
A       AN      degree=pos|gender=common/neuter|number=plur|case=unmarked|def=def/indef|transcat=unmarked
A       AN      degree=pos|gender=common/neuter|number=sing|case=gen|def=def|transcat=unmarked
A       AN      degree=pos|gender=common/neuter|number=sing|case=unmarked|def=def/indef|transcat=unmarked
A       AN      degree=pos|gender=common/neuter|number=sing|case=unmarked|def=def|transcat=unmarked
A       AN      degree=pos|gender=common/neuter|number=sing|case=unmarked|def=indef|transcat=unmarked
A       AN      degree=pos|gender=common/neuter|number=sing/plur|case=unmarked|def=def/indef|transcat=unmarked
A       AN      degree=pos|gender=common|number=sing|case=unmarked|def=def/indef|transcat=unmarked
A       AN      degree=pos|gender=common|number=sing|case=unmarked|def=indef|transcat=unmarked
A       AN      degree=pos|gender=neuter|number=sing|case=unmarked|def=def/indef|transcat=unmarked
A       AN      degree=pos|gender=neuter|number=sing|case=unmarked|def=indef|transcat=unmarked
A       AN      degree=pos|transcat=adverbial
A       AN      degree=sup|gender=common/neuter|number=plur|case=unmarked|def=def/indef|transcat=unmarked
A       AN      degree=sup|gender=common/neuter|number=plur|case=unmarked|def=def|transcat=unmarked
A       AN      degree=sup|gender=common/neuter|number=sing|case=unmarked|def=def|transcat=unmarked
A       AN      degree=sup|gender=common/neuter|number=sing|case=unmarked|def=indef|transcat=unmarked
A       AN      degree=sup|gender=common/neuter|number=sing/plur|case=unmarked|def=def/indef|transcat=unmarked
A       AN      degree=sup|gender=common/neuter|number=sing/plur|case=unmarked|def=def|transcat=unmarked
A       AN      degree=sup|transcat=adverbial
A       AO      case=unmarked
C       CC      _
C       CS      _
I       I       _
N       NC      gender=common/neuter|number=plur|case=unmarked|def=def
N       NC      gender=common/neuter|number=plur|case=unmarked|def=indef
N       NC      gender=common/neuter|number=sing|case=unmarked|def=indef
N       NC      gender=common/neuter|number=sing/plur|case=gen|def=def/indef
N       NC      gender=common/neuter|number=sing/plur|case=unmarked|def=def/indef
N       NC      gender=common/neuter|number=sing/plur|case=unmarked|def=indef
N       NC      gender=common|number=plur|case=gen|def=def
N       NC      gender=common|number=plur|case=gen|def=indef
N       NC      gender=common|number=plur|case=unmarked|def=def
N       NC      gender=common|number=plur|case=unmarked|def=def/indef
N       NC      gender=common|number=plur|case=unmarked|def=indef
N       NC      gender=common|number=sing|case=gen|def=def
N       NC      gender=common|number=sing|case=gen|def=indef
N       NC      gender=common|number=sing|case=unmarked|def=def
N       NC      gender=common|number=sing|case=unmarked|def=indef
N       NC      gender=neuter|number=plur|case=gen|def=def
N       NC      gender=neuter|number=plur|case=gen|def=indef
N       NC      gender=neuter|number=plur|case=unmarked|def=def
N       NC      gender=neuter|number=plur|case=unmarked|def=indef
N       NC      gender=neuter|number=sing|case=gen|def=def
N       NC      gender=neuter|number=sing|case=gen|def=indef
N       NC      gender=neuter|number=sing|case=unmarked|def=def
N       NC      gender=neuter|number=sing|case=unmarked|def=indef
N       NP      case=gen
N       NP      case=unmarked
P       PC      number=plur|case=gen
P       PC      number=plur|case=unmarked
P       PD      gender=common/neuter|number=plur|case=unmarked|register=unmarked
P       PD      gender=common/neuter|number=sing/plur|case=unmarked|register=unmarked
P       PD      gender=common|number=sing|case=gen|register=unmarked
P       PD      gender=common|number=sing|case=unmarked|register=unmarked
P       PD      gender=neuter|number=sing|case=unmarked|register=unmarked
P       PI      gender=common/neuter|number=plur|case=gen|register=unmarked
P       PI      gender=common/neuter|number=plur|case=unmarked|register=obsolete
P       PI      gender=common/neuter|number=plur|case=unmarked|register=unmarked
P       PI      gender=common|number=sing|case=gen|register=unmarked
P       PI      gender=common|number=sing|case=unmarked|register=unmarked
P       PI      gender=common|number=sing/plur|case=nom|register=unmarked
P       PI      gender=neuter|number=sing|case=unmarked|register=unmarked
P       PO      person=1|gender=common/neuter|number=plur|case=unmarked|possessor=plur|reflexive=no|register=formal
P       PO      person=1|gender=common/neuter|number=plur|case=unmarked|possessor=sing|reflexive=no|register=unmarked
P       PO      person=1|gender=common/neuter|number=sing/plur|case=unmarked|possessor=plur|reflexive=no|register=unmarked
P       PO      person=1|gender=common|number=sing|case=unmarked|possessor=plur|reflexive=no|register=formal
P       PO      person=1|gender=common|number=sing|case=unmarked|possessor=sing|reflexive=no|register=unmarked
P       PO      person=1|gender=neuter|number=sing|case=unmarked|possessor=plur|reflexive=no|register=formal
P       PO      person=1|gender=neuter|number=sing|case=unmarked|possessor=sing|reflexive=no|register=unmarked
P       PO      person=2|gender=common/neuter|number=plur|case=unmarked|possessor=sing|reflexive=no|register=unmarked
P       PO      person=2|gender=common/neuter|number=sing/plur|case=unmarked|possessor=plur|reflexive=no|register=unmarked
P       PO      person=2|gender=common/neuter|number=sing/plur|case=unmarked|possessor=sing/plur|reflexive=no|register=polite
P       PO      person=2|gender=common|number=sing|case=unmarked|possessor=sing|reflexive=no|register=unmarked
P       PO      person=2|gender=neuter|number=sing|case=unmarked|possessor=sing|reflexive=no|register=unmarked
P       PO      person=3|gender=common/neuter|number=plur|case=unmarked|possessor=sing|reflexive=yes|register=unmarked
P       PO      person=3|gender=common/neuter|number=sing/plur|case=unmarked|possessor=plur|reflexive=no|register=unmarked
P       PO      person=3|gender=common/neuter|number=sing/plur|case=unmarked|possessor=sing|reflexive=no|register=unmarked
P       PO      person=3|gender=common|number=sing|case=unmarked|possessor=sing|reflexive=yes|register=unmarked
P       PO      person=3|gender=neuter|number=sing|case=unmarked|possessor=sing|reflexive=yes|register=unmarked
P       PP      person=1|gender=common|number=plur|case=nom|reflexive=no|register=unmarked
P       PP      person=1|gender=common|number=plur|case=unmarked|reflexive=yes/no|register=unmarked
P       PP      person=1|gender=common|number=sing|case=nom|reflexive=no|register=unmarked
P       PP      person=1|gender=common|number=sing|case=unmarked|reflexive=yes/no|register=unmarked
P       PP      person=2|gender=common|number=plur|case=nom|reflexive=no|register=unmarked
P       PP      person=2|gender=common|number=plur|case=unmarked|reflexive=yes/no|register=unmarked
P       PP      person=2|gender=common|number=sing|case=nom|reflexive=no|register=unmarked
P       PP      person=2|gender=common|number=sing|case=unmarked|reflexive=yes/no|register=unmarked
P       PP      person=2|gender=common|number=sing/plur|case=nom|reflexive=no|register=polite
P       PP      person=2|gender=common|number=sing/plur|case=unmarked|reflexive=yes/no|register=polite
P       PP      person=3|gender=common/neuter|number=plur|case=nom|reflexive=no|register=unmarked
P       PP      person=3|gender=common/neuter|number=plur|case=unmarked|reflexive=no|register=unmarked
P       PP      person=3|gender=common/neuter|number=plur|case=unmarked|reflexive=yes/no|register=unmarked
P       PP      person=3|gender=common/neuter|number=sing/plur|case=unmarked|reflexive=yes|register=unmarked
P       PP      person=3|gender=common|number=sing|case=nom|reflexive=no|register=unmarked
P       PP      person=3|gender=common|number=sing|case=unmarked|reflexive=no|register=unmarked
P       PP      person=3|gender=common|number=sing|case=unmarked|reflexive=yes/no|register=unmarked
P       PP      person=3|gender=neuter|number=sing|case=unmarked|reflexive=no|register=unmarked
P       PP      person=3|gender=neuter|number=sing|case=unmarked|reflexive=yes/no|register=unmarked
P       PT      gender=common/neuter|number=plur|case=unmarked|register=unmarked
P       PT      gender=common/neuter|number=sing|case=unmarked|register=unmarked
P       PT      gender=common/neuter|number=sing/plur|case=gen|register=unmarked
P       PT      gender=common|number=sing|case=unmarked|register=unmarked
P       PT      gender=common|number=sing/plur|case=unmarked|register=unmarked
P       PT      gender=neuter|number=sing|case=unmarked|register=unmarked
RG      RG      degree=abs
RG      RG      degree=comp
RG      RG      degree=pos
RG      RG      degree=sup
RG      RG      degree=unmarked
SP      SP      _
U       U       _
V       VA      mood=gerund|number=sing|gender=common|definiteness=indef|case=unmarked
V       VA      mood=imper
V       VA      mood=indic|tense=past|voice=active
V       VA      mood=indic|tense=past|voice=passive
V       VA      mood=indic|tense=present|voice=active
V       VA      mood=indic|tense=present|voice=passive
V       VA      mood=infin|voice=active
V       VA      mood=infin|voice=passive
V       VA      mood=partic|tense=past|number=plur|gender=common/neuter|definiteness=def/indef|transcat=adject|case=gen
V       VA      mood=partic|tense=past|number=plur|gender=common/neuter|definiteness=def/indef|transcat=adject|case=unmarked
V       VA      mood=partic|tense=past|number=sing|gender=common|definiteness=def|transcat=adject|case=unmarked
V       VA      mood=partic|tense=past|number=sing|gender=common/neuter|definiteness=def|transcat=adject|case=unmarked
V       VA      mood=partic|tense=past|number=sing|gender=common/neuter|definiteness=indef|transcat=adject/adverb/unmarked|case=unmarked
V       VA      mood=partic|tense=past|number=sing|gender=common/neuter|definiteness=indef|transcat=adject|case=unmarked
V       VA      mood=partic|tense=past|number=sing/plur|gender=common/neuter|definiteness=def/indef|transcat=adject/adverb/unmarked|case=unmarked
V       VA      mood=partic|tense=present|number=sing/plur|gender=common/neuter|definiteness=def/indef|transcat=adject/adverb/unmarked|case=unmarked
V       VA      mood=partic|tense=present|number=sing/plur|gender=common/neuter|definiteness=def/indef|transcat=adject|case=unmarked
V       VA      mood=partic|tense=present|transcat=adverb
V       VE      mood=indic|tense=past|voice=active
V       VE      mood=indic|tense=present|voice=active
V       VE      mood=infin|voice=active
V       VE      mood=partic|tense=past|number=sing/plur|gender=common/neuter|definiteness=def/indef|transcat=adject/adverb/unmarked|case=unmarked
X       XA      _
X       XF      _
X       XP      _
X       XR      _
X       XS      _
X       XX      _
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

Lingua::Interset::Tagset::DA::Conll - Driver for the Danish tagset of the CoNLL 2006 Shared Task (derived from the Danish Parole tagset).

=head1 VERSION

version 3.010

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::DA::Conll;
  my $driver = Lingua::Interset::Tagset::DA::Conll->new();
  my $fs = $driver->decode("N\tNC\tgender=common|number=sing|case=unmarked|def=indef");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('da::conll', "N\tNC\tgender=common|number=sing|case=unmarked|def=indef");

=head1 DESCRIPTION

Interset driver for the Danish tagset of the CoNLL 2006 Shared Task.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT. For Danish,
these values are derived from the Danish PAROLE tagset, as used in the
Danish Dependency Treebank.

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
