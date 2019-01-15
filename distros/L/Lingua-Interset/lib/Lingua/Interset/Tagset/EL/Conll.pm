# ABSTRACT: Driver for the Greek tagset of the CoNLL 2007 Shared Task.
# Copyright © 2011, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Copyright © 2011 Loganathan Ramasamy <ramasamy@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::EL::Conll;
use strict;
use warnings;
our $VERSION = '3.013';

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
    return 'el::conll';
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
        'tagset' => 'el::conll',
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # No = noun
            # common noun: πρόεδρος, αριθμός, επισκέπτης, στόχος
            'NoCm'   => ['pos' => 'noun', 'nountype' => 'com'],
            # proper noun: Αμερικανός, ΣΩΚΡΑΤΗΣ, Άγιος, Γερμανός, Γάλλος
            'NoPr'   => ['pos' => 'noun', 'nountype' => 'prop'],
            # initial: Ο., Ζ., M., Χ., Ν.
            'INIT'   => ['pos' => 'noun', 'nountype' => 'prop', 'abbr' => 'yes'],
            # Aj = adjective: επικεφαλής, επόμενος, ίδιος, τελικός, Αρτέμιδος
            'Aj'     => ['pos' => 'adj'],
            # Pn = pronoun
            # personal pronoun: εγώ, εμείς, εσείς
            'PnPe'   => ['pos' => 'noun', 'prontype' => 'prs'],
            # possessive pronoun: μου, του, της, μας, σας, τους
            'PnPo'   => ['pos' => 'adj', 'prontype' => 'prs', 'poss' => 'yes'],
            # relative pronoun: που, οποίος, οποία, οποίο
            'PnRe'   => ['pos' => 'noun|adj', 'prontype' => 'rel'],
            # relative or interrogative pronoun: όποιος, οποιαδήποτε
            'PnRi'   => ['pos' => 'noun|adj', 'prontype' => 'rel|int'],
            # demonstrative pronoun: αυτός, εκείνος, τέτοιος
            'PnDm'   => ['pos' => 'noun|adj', 'prontype' => 'dem'],
            # interrogative pronoun: ποιος
            'PnIr'   => ['pos' => 'noun|adj', 'prontype' => 'int'],
            # indefinite, negative or total pronoun: κανείς, κάποιος, άλλος, καθένας
            'PnId'   => ['pos' => 'noun|adj', 'prontype' => 'ind|neg|tot'],
            # At = article
            # definite article: ο, η, το, οι, τα
            'AtDf'   => ['pos' => 'adj', 'prontype' => 'art', 'definite' => 'def'],
            # indefinite article: ένας, μια, μία, ένα
            'AtId'   => ['pos' => 'adj', 'prontype' => 'art', 'definite' => 'ind'],
            # Nm = numeral
            # cardinal numeral: ένας, δύο, εννέα, δίκτυό, πέντε
            'NmCd'   => ['pos' => 'num', 'numtype' => 'card'],
            # plural cardinal (generic?) numeral: χιλιάδες, δεκάδες, εκατοντάδες
            # numerals used like plural nouns: thousands, tens, hundreds
            # unfortunately, number=plur is not enough to distinguish them
            'NmCt'   => ['pos' => 'num', 'numtype' => 'card', 'other' => {'numtype' => 'generic'}],
            # multiplicative numeral: διπλό
            'NmMl'   => ['pos' => 'adv', 'numtype' => 'mult'],
            # ordinal numeral: δεύτερος, πρώτος, ντ', τρίτος
            'NmOd'   => ['pos' => 'adj', 'numtype' => 'ord'],
            # DIG = number expressed using digits: 1, 15, 1999, 10, 2005
            'DIG'    => ['pos' => 'num', 'numform' => 'digit'],
            # DATE = date: Παρασκευή (Friday), Τρίτη (Tuesday), Δευτέρα (Monday), 11ης_Μαρτίου (March 11), Τετάρτη (Wednesday)
            'DATE'   => ['pos' => 'noun', 'advtype' => 'tim'],
            # ENUM = enumeration: -, 22.000, 7ο, 2.234, 1948.
            # This tag is rare and I suspect that it is assigned by mistake.
            'ENUM'   => ['pos' => 'num', 'numform' => 'digit'],
            # Vb = verb
            # modal verb: πρέπει (must), αφορά (concern), μπορεί (may)
            'VbIs'   => ['pos' => 'verb', 'verbtype' => 'mod'],
            # main verb: έχει (is), μπορεί (may), αποτελεί (forms), υπάρχει (there is), αφορά (concerns)
            'VbMn'   => ['pos' => 'verb'],
            # Ad = adverb: ως, όπως, σχετικά, καθώς, μεταξύ
            'Ad'     => ['pos' => 'adv'],
            # AsPp = preposition
            # normal preposition: για, από, με, σε, κατά
            'AsPpSp' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # preposition fused with article: στον, στο, στην, στη, στους, στις, στα
            'AsPpPa' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # LSPLIT = left split: γι', σ', απ', κατ', εφ'
            # example: γι' αυτή (for this) (γι' is an abbreviation of για)
            'LSPLIT' => ['pos' => 'adp', 'adpostype' => 'prep', 'abbr' => 'yes'],
            # Cj = conjunction
            # coordinating conjunction: και, αλλά, ή, ενώ, όμως
            'CjCo'   => ['pos' => 'conj', 'conjtype' => 'coor'],
            # subordinating conjunction: ότι, αν, ώστε, εάν, όταν
            'CjSb'   => ['pos' => 'conj', 'conjtype' => 'sub'],
            # Pt = particle
            # future particle: θα
            'PtFu'   => ['pos' => 'part', 'tense' => 'fut'],
            # negative particle: δεν, όχι, μην, μη
            'PtNg'   => ['pos' => 'part', 'polarity' => 'neg'],
            # discourse particle: ας (let), άραγε (I wonder)
            'PtOt'   => ['pos' => 'part'],
            # infinitive? particle: να (to), ν
            'PtSj'   => ['pos' => 'part', 'parttype' => 'inf'],
            # Rg = foreign word or abbreviation
            # abbreviation: κ., ΕΕ, π.Χ., ΗΠΑ, χλμ.
            'RgAbXx' => ['abbr' => 'yes'],
            # abbreviatory noun, acronym: ΟΗΕ, ΝΑΤΟ, ΕΤΑ, ΣΕΒ, ΔΠΔΓ
            'RgAnXx' => ['pos' => 'noun', 'abbr' => 'yes'],
            # foreign word in foreign script: Sudan, van, OLAF, of, Journal
            'RgFwOr' => ['foreign' => 'yes', 'other' => {'script' => 'foreign'}],
            # foreign word transcribed to the Greek script: Ιράν, Ιράκ, Δρ, Μπους, Γιουστσένκο
            'RgFwTr' => ['foreign' => 'yes', 'other' => {'script' => 'translit'}],
            # COMP = multi-word expression: εν_λόγω (this, said), εν_όψει (with a view), απ'_όλα (all), εν__λόγω, _εν_λόγω
            'COMP'   => ['other' => {'pos' => 'comp'}],
            # PUNCT = punctuation: ,, ., ", -, :
            'PUNCT'  => ['pos' => 'punc'],
        },
        'encode_map' =>

            { 'pos' => { 'noun' => { 'prontype' => { ''    => { 'nountype' => { 'prop' => { 'abbr' => { 'yes' => 'INIT',
                                                                                                        '@'    => 'NoPr' }},
                                                                                '@'    => { 'abbr' => { 'yes' => 'RgAnXx',
                                                                                                        '@'    => { 'advtype' => { 'tim' => 'DATE',
                                                                                                                                   '@'   => 'NoCm' }}}}}},
                                                     'prs' => { 'poss' => { 'yes' => 'PnPo',
                                                                            '@'    => 'PnPe' }},
                                                     'dem' => 'PnDm',
                                                     'int|rel' => 'PnRi',
                                                     'int' => 'PnIr',
                                                     'rel' => 'PnRe',
                                                     '@'   => 'PnId' }},
                         'adj'  => { 'prontype' => { ''    => { 'numtype' => { 'ord'  => 'NmOd',
                                                                               '@'    => 'Aj' }},
                                                     'prs' => { 'poss' => { 'yes' => 'PnPo',
                                                                            '@'    => 'PnPe' }},
                                                     'art' => { 'definite' => { 'def' => 'AtDf',
                                                                                '@'   => 'AtId' }},
                                                     'dem' => 'PnDm',
                                                     'int|rel' => 'PnRi',
                                                     'int' => 'PnIr',
                                                     'rel' => 'PnRe',
                                                     '@'   => 'PnId' }},
                         'num'  => { 'numform' => { 'digit' => 'DIG',
                                                    '@'     => { 'numtype' => { 'card' => { 'other/numtype' => { 'generic' => 'NmCt',
                                                                                                                 '@'       => 'NmCd' }},
                                                                                'ord'  => 'NmOd',
                                                                                'mult' => 'NmMl' }}}},
                         'verb' => { 'verbtype' => { 'mod' => 'VbIs',
                                                     '@'   => 'VbMn' }},
                         'adv'  => { 'numtype' => { 'mult' => 'NmMl',
                                                    '@'    => 'Ad' }},
                         'adp'  => { 'abbr' => { 'yes' => 'LSPLIT',
                                                 '@'    => { 'number' => { ''  => 'AsPpSp',
                                                                           '@' => 'AsPpPa' }}}},
                         'conj' => { 'conjtype' => { 'sub' => 'CjSb',
                                                     '@'   => 'CjCo' }},
                         'part' => { 'parttype' => { 'inf' => 'PtSj',
                                                     '@'   => { 'tense' => { 'fut' => 'PtFu',
                                                                             '@'   => { 'polarity' => { 'neg' => 'PtNg',
                                                                                                        '@'   => 'PtOt' }}}}}},
                         'punc' => 'PUNCT',
                         '@'    => { 'abbr' => { 'yes' => 'RgAbXx',
                                                 '@'    => { 'foreign' => { 'yes' => { 'other/script' => { 'foreign'  => 'RgFwOr',
                                                                                                               'translit' => 'RgFwTr',
                                                                                                               '@'        => 'RgFwTr' }},
                                                                            '@'       => { 'other/pos' => { 'comp' => 'COMP',
                                                                                                            '@'    => 'RgFwTr' }}}}}}}}
    );
    # GENDER ####################
    $atoms{gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'Ma' => 'masc',
            'Fe' => 'fem',
            'Ne' => 'neut'
        },
        'encode_default' => 'Xx'
    );
    # NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'Sg' => 'sing',
            'Pl' => 'plur'
        },
        'encode_default' => 'Xx'
    );
    # CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'Nm' => 'nom',
            'Ge' => 'gen',
            'Ac' => 'acc',
            'Vo' => 'voc',
            'Da' => 'dat'
        },
        'encode_default' => 'Xx'
    );
    # DEGREE ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'Ba' => 'pos',
            'Cp' => 'cmp',
            'Su' => 'sup'
        },
        'encode_default' => 'Xx'
    );
    # PERSON ####################
    $atoms{person} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            '01' => '1',
            '02' => '2',
            '03' => '3'
        },
        'encode_default' => 'Xx'
    );
    # FORM OF PERSONAL PRONOUN ####################
    $atoms{perspronform} = $self->create_simple_atom
    (
        'intfeature' => 'variant',
        'simple_decode_map' =>
        {
            'St' => 'long',
            'We' => 'short'
        },
        'encode_default' => 'Xx'
    );
    # SYNTACTIC TYPE OF NUMERAL ####################
    $atoms{synpos} = $self->create_atom
    (
        'surfeature' => 'synpos',
        'decode_map' =>
        {
            # Adjectival form. Used with all types of numerals except for "Ct".
            'Aj' => [],
            # Noun form. Used only with the "Ct" numerals.
            'No' => []
        },
        'encode_map' =>
        {
            'other/numtype' => { 'generic' => 'No',
                                 '@'       => 'Aj' }
        }
    );
    # VERB FORM AND MOOD ####################
    $atoms{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            'Nf' => ['verbform' => 'inf'],
            'Pp' => ['verbform' => 'part'],
            'Id' => ['verbform' => 'fin', 'mood' => 'ind'],
            'Mp' => ['verbform' => 'fin', 'mood' => 'imp']
        },
        'encode_map' =>
        {
            'verbform' => { 'inf'   => 'Nf',
                            'sup'   => 'Nf',
                            'part'  => 'Pp',
                            'trans' => 'Pp',
                            '@'     => { 'mood' => { 'imp' => 'Mp',
                                                     '@'   => 'Id' }}}
        }
    );
    # TENSE ####################
    $atoms{tense} = $self->create_simple_atom
    (
        'intfeature' => 'tense',
        'simple_decode_map' =>
        {
            'Pa' => 'past',
            'Pr' => 'pres'
        },
        'encode_default' => 'Xx'
    );
    # ASPECT ####################
    $atoms{aspect} = $self->create_simple_atom
    (
        'intfeature' => 'aspect',
        'simple_decode_map' =>
        {
            'Ip' => 'imp',
            'Pe' => 'perf'
        },
        'encode_default' => 'Xx'
    );
    # VOICE ####################
    $atoms{voice} = $self->create_simple_atom
    (
        'intfeature' => 'voice',
        'simple_decode_map' =>
        {
            'Av' => 'act',
            'Pv' => 'pass'
        },
        'encode_default' => 'Xx'
    );
    # MERGED ATOM TO DECODE ANY FEATURE VALUE ####################
    my @fatoms = map {$atoms{$_}} (qw(gender number case degree person perspronform synpos verbform tense aspect voice));
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
    my @features = ('verbform', 'tense', 'degree', 'gender', 'person', 'number', 'aspect', 'voice', 'case', 'perspronform', 'synpos');
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
        'No' => ['gender', 'number', 'case'],
        'Aj' => ['degree', 'gender', 'number', 'case'],
        'Pn' => ['gender', 'person', 'number', 'case', 'perspronform'],
        'At' => ['gender', 'number', 'case'],
        'Nm' => ['gender', 'number', 'case', 'synpos'],
        'Ad' => ['degree'],
        'AsPpPa' => ['gender', 'number', 'case'],
        'Vb' => ['verbform', 'tense', 'person', 'number', 'gender', 'aspect', 'voice', 'case']
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
    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset('el::conll');
    my $atoms = $self->atoms();
    # Three components, and the first two are identical: pos, pos, features.
    # example: No\tNoCm\tMa|Sg|Nm
    my ($pos, $subpos, $features) = split(/\s+/, $tag);
    # The underscore character is used if there are no features.
    $features = '' if($features eq '_');
    my @features = split(/\|/, $features);
    $atoms->{pos}->decode_and_merge_hard($subpos, $fs);
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
    my $subpos = $atoms->{pos}->encode($fs);
    my $pos = $subpos =~ m/^(COMP|DATE|DIG|ENUM|INIT|LSPLIT|PUNCT)$/ ? $subpos : $subpos =~ m/^AsPp/ ? 'AsPp' : substr($subpos, 0, 2);
    my $fpos = $subpos eq 'AsPpPa' ? 'At' : $pos;
    my $feature_names = $self->get_feature_names($fpos);
    my $value_only = 1;
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names, $value_only);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus: 350 tags found.
# 445 total tags after adding missing cases etc.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
Ad	Ad	Ba
Ad	Ad	Cp
Ad	Ad	Su
Aj	Aj	Ba|Fe|Pl|Ac
Aj	Aj	Ba|Fe|Pl|Da
Aj	Aj	Ba|Fe|Pl|Ge
Aj	Aj	Ba|Fe|Pl|Nm
Aj	Aj	Ba|Fe|Sg|Ac
Aj	Aj	Ba|Fe|Sg|Da
Aj	Aj	Ba|Fe|Sg|Ge
Aj	Aj	Ba|Fe|Sg|Nm
Aj	Aj	Ba|Ma|Pl|Ac
Aj	Aj	Ba|Ma|Pl|Da
Aj	Aj	Ba|Ma|Pl|Ge
Aj	Aj	Ba|Ma|Pl|Nm
Aj	Aj	Ba|Ma|Pl|Vo
Aj	Aj	Ba|Ma|Sg|Ac
Aj	Aj	Ba|Ma|Sg|Da
Aj	Aj	Ba|Ma|Sg|Ge
Aj	Aj	Ba|Ma|Sg|Nm
Aj	Aj	Ba|Ma|Sg|Vo
Aj	Aj	Ba|Ne|Pl|Ac
Aj	Aj	Ba|Ne|Pl|Da
Aj	Aj	Ba|Ne|Pl|Ge
Aj	Aj	Ba|Ne|Pl|Nm
Aj	Aj	Ba|Ne|Sg|Ac
Aj	Aj	Ba|Ne|Sg|Da
Aj	Aj	Ba|Ne|Sg|Ge
Aj	Aj	Ba|Ne|Sg|Nm
Aj	Aj	Cp|Fe|Pl|Ac
Aj	Aj	Cp|Fe|Pl|Da
Aj	Aj	Cp|Fe|Pl|Ge
Aj	Aj	Cp|Fe|Pl|Nm
Aj	Aj	Cp|Fe|Sg|Ac
Aj	Aj	Cp|Fe|Sg|Da
Aj	Aj	Cp|Fe|Sg|Ge
Aj	Aj	Cp|Fe|Sg|Nm
Aj	Aj	Cp|Ma|Pl|Ac
Aj	Aj	Cp|Ma|Pl|Da
Aj	Aj	Cp|Ma|Pl|Ge
Aj	Aj	Cp|Ma|Pl|Nm
Aj	Aj	Cp|Ma|Sg|Ac
Aj	Aj	Cp|Ma|Sg|Da
Aj	Aj	Cp|Ma|Sg|Ge
Aj	Aj	Cp|Ma|Sg|Nm
Aj	Aj	Cp|Ne|Pl|Ac
Aj	Aj	Cp|Ne|Pl|Da
Aj	Aj	Cp|Ne|Pl|Ge
Aj	Aj	Cp|Ne|Pl|Nm
Aj	Aj	Cp|Ne|Sg|Ac
Aj	Aj	Cp|Ne|Sg|Da
Aj	Aj	Cp|Ne|Sg|Ge
Aj	Aj	Cp|Ne|Sg|Nm
Aj	Aj	Su|Fe|Pl|Ac
Aj	Aj	Su|Fe|Pl|Da
Aj	Aj	Su|Fe|Pl|Ge
Aj	Aj	Su|Fe|Pl|Nm
Aj	Aj	Su|Fe|Sg|Ac
Aj	Aj	Su|Fe|Sg|Da
Aj	Aj	Su|Fe|Sg|Ge
Aj	Aj	Su|Fe|Sg|Nm
Aj	Aj	Su|Ma|Pl|Ac
Aj	Aj	Su|Ma|Pl|Da
Aj	Aj	Su|Ma|Pl|Ge
Aj	Aj	Su|Ma|Pl|Nm
Aj	Aj	Su|Ma|Sg|Ac
Aj	Aj	Su|Ma|Sg|Da
Aj	Aj	Su|Ma|Sg|Ge
Aj	Aj	Su|Ma|Sg|Nm
Aj	Aj	Su|Ne|Pl|Ac
Aj	Aj	Su|Ne|Pl|Da
Aj	Aj	Su|Ne|Pl|Ge
Aj	Aj	Su|Ne|Pl|Nm
Aj	Aj	Su|Ne|Sg|Ac
Aj	Aj	Su|Ne|Sg|Da
Aj	Aj	Su|Ne|Sg|Ge
Aj	Aj	Su|Ne|Sg|Nm
AsPp	AsPpPa	Fe|Pl|Ac
AsPp	AsPpPa	Fe|Sg|Ac
AsPp	AsPpPa	Ma|Pl|Ac
AsPp	AsPpPa	Ma|Sg|Ac
AsPp	AsPpPa	Ne|Pl|Ac
AsPp	AsPpPa	Ne|Sg|Ac
AsPp	AsPpSp	_
At	AtDf	Fe|Pl|Ac
At	AtDf	Fe|Pl|Da
At	AtDf	Fe|Pl|Ge
At	AtDf	Fe|Pl|Nm
At	AtDf	Fe|Sg|Ac
At	AtDf	Fe|Sg|Da
At	AtDf	Fe|Sg|Ge
At	AtDf	Fe|Sg|Nm
At	AtDf	Ma|Pl|Ac
At	AtDf	Ma|Pl|Da
At	AtDf	Ma|Pl|Ge
At	AtDf	Ma|Pl|Nm
At	AtDf	Ma|Sg|Ac
At	AtDf	Ma|Sg|Da
At	AtDf	Ma|Sg|Ge
At	AtDf	Ma|Sg|Nm
At	AtDf	Ne|Pl|Ac
At	AtDf	Ne|Pl|Da
At	AtDf	Ne|Pl|Ge
At	AtDf	Ne|Pl|Nm
At	AtDf	Ne|Sg|Ac
At	AtDf	Ne|Sg|Da
At	AtDf	Ne|Sg|Ge
At	AtDf	Ne|Sg|Nm
At	AtId	Fe|Sg|Ac
At	AtId	Fe|Sg|Da
At	AtId	Fe|Sg|Ge
At	AtId	Fe|Sg|Nm
At	AtId	Ma|Sg|Ac
At	AtId	Ma|Sg|Da
At	AtId	Ma|Sg|Ge
At	AtId	Ma|Sg|Nm
At	AtId	Ne|Sg|Ac
At	AtId	Ne|Sg|Da
At	AtId	Ne|Sg|Ge
At	AtId	Ne|Sg|Nm
COMP	COMP	_
Cj	CjCo	_
Cj	CjSb	_
DATE	DATE	_
DIG	DIG	_
INIT	INIT	_
LSPLIT	LSPLIT	_
Nm	NmCd	Fe|Pl|Ac|Aj
Nm	NmCd	Fe|Pl|Da|Aj
Nm	NmCd	Fe|Pl|Ge|Aj
Nm	NmCd	Fe|Pl|Nm|Aj
Nm	NmCd	Fe|Sg|Ac|Aj
Nm	NmCd	Fe|Sg|Da|Aj
Nm	NmCd	Fe|Sg|Ge|Aj
Nm	NmCd	Fe|Sg|Nm|Aj
Nm	NmCd	Ma|Pl|Ac|Aj
Nm	NmCd	Ma|Pl|Da|Aj
Nm	NmCd	Ma|Pl|Ge|Aj
Nm	NmCd	Ma|Pl|Nm|Aj
Nm	NmCd	Ma|Sg|Ac|Aj
Nm	NmCd	Ma|Sg|Da|Aj
Nm	NmCd	Ma|Sg|Ge|Aj
Nm	NmCd	Ma|Sg|Nm|Aj
Nm	NmCd	Ne|Pl|Ac|Aj
Nm	NmCd	Ne|Pl|Da|Aj
Nm	NmCd	Ne|Pl|Ge|Aj
Nm	NmCd	Ne|Pl|Nm|Aj
Nm	NmCd	Ne|Sg|Ac|Aj
Nm	NmCd	Ne|Sg|Da|Aj
Nm	NmCd	Ne|Sg|Ge|Aj
Nm	NmCd	Ne|Sg|Nm|Aj
Nm	NmCt	Fe|Pl|Ac|No
Nm	NmCt	Fe|Pl|Da|No
Nm	NmCt	Fe|Pl|Ge|No
Nm	NmCt	Fe|Pl|Nm|No
Nm	NmMl	Ne|Sg|Ac|Aj
Nm	NmOd	Fe|Pl|Ac|Aj
Nm	NmOd	Fe|Pl|Da|Aj
Nm	NmOd	Fe|Pl|Ge|Aj
Nm	NmOd	Fe|Pl|Nm|Aj
Nm	NmOd	Fe|Sg|Ac|Aj
Nm	NmOd	Fe|Sg|Da|Aj
Nm	NmOd	Fe|Sg|Ge|Aj
Nm	NmOd	Fe|Sg|Nm|Aj
Nm	NmOd	Ma|Pl|Ac|Aj
Nm	NmOd	Ma|Pl|Da|Aj
Nm	NmOd	Ma|Pl|Ge|Aj
Nm	NmOd	Ma|Pl|Nm|Aj
Nm	NmOd	Ma|Sg|Ac|Aj
Nm	NmOd	Ma|Sg|Da|Aj
Nm	NmOd	Ma|Sg|Ge|Aj
Nm	NmOd	Ma|Sg|Nm|Aj
Nm	NmOd	Ne|Pl|Ac|Aj
Nm	NmOd	Ne|Pl|Da|Aj
Nm	NmOd	Ne|Pl|Ge|Aj
Nm	NmOd	Ne|Pl|Nm|Aj
Nm	NmOd	Ne|Sg|Ac|Aj
Nm	NmOd	Ne|Sg|Da|Aj
Nm	NmOd	Ne|Sg|Ge|Aj
Nm	NmOd	Ne|Sg|Nm|Aj
No	NoCm	Fe|Pl|Ac
No	NoCm	Fe|Pl|Da
No	NoCm	Fe|Pl|Ge
No	NoCm	Fe|Pl|Nm
No	NoCm	Fe|Pl|Vo
No	NoCm	Fe|Sg|Ac
No	NoCm	Fe|Sg|Da
No	NoCm	Fe|Sg|Ge
No	NoCm	Fe|Sg|Nm
No	NoCm	Fe|Sg|Vo
No	NoCm	Ma|Pl|Ac
No	NoCm	Ma|Pl|Da
No	NoCm	Ma|Pl|Ge
No	NoCm	Ma|Pl|Nm
No	NoCm	Ma|Pl|Vo
No	NoCm	Ma|Sg|Ac
No	NoCm	Ma|Sg|Da
No	NoCm	Ma|Sg|Ge
No	NoCm	Ma|Sg|Nm
No	NoCm	Ma|Sg|Vo
No	NoCm	Ne|Pl|Ac
No	NoCm	Ne|Pl|Da
No	NoCm	Ne|Pl|Ge
No	NoCm	Ne|Pl|Nm
No	NoCm	Ne|Sg|Ac
No	NoCm	Ne|Sg|Da
No	NoCm	Ne|Sg|Ge
No	NoCm	Ne|Sg|Nm
No	NoPr	Fe|Pl|Ac
No	NoPr	Fe|Pl|Da
No	NoPr	Fe|Pl|Ge
No	NoPr	Fe|Pl|Nm
No	NoPr	Fe|Sg|Ac
No	NoPr	Fe|Sg|Da
No	NoPr	Fe|Sg|Ge
No	NoPr	Fe|Sg|Nm
No	NoPr	Ma|Pl|Ac
No	NoPr	Ma|Pl|Da
No	NoPr	Ma|Pl|Ge
No	NoPr	Ma|Pl|Nm
No	NoPr	Ma|Sg|Ac
No	NoPr	Ma|Sg|Da
No	NoPr	Ma|Sg|Ge
No	NoPr	Ma|Sg|Nm
No	NoPr	Ma|Sg|Vo
No	NoPr	Ne|Pl|Ac
No	NoPr	Ne|Pl|Da
No	NoPr	Ne|Pl|Ge
No	NoPr	Ne|Pl|Nm
No	NoPr	Ne|Sg|Ac
No	NoPr	Ne|Sg|Da
No	NoPr	Ne|Sg|Ge
No	NoPr	Ne|Sg|Nm
PUNCT	PUNCT	_
Pn	PnDm	Fe|03|Pl|Ac|Xx
Pn	PnDm	Fe|03|Pl|Ge|Xx
Pn	PnDm	Fe|03|Pl|Nm|Xx
Pn	PnDm	Fe|03|Sg|Ac|Xx
Pn	PnDm	Fe|03|Sg|Ge|Xx
Pn	PnDm	Fe|03|Sg|Nm|Xx
Pn	PnDm	Ma|03|Pl|Ac|Xx
Pn	PnDm	Ma|03|Pl|Ge|Xx
Pn	PnDm	Ma|03|Pl|Nm|Xx
Pn	PnDm	Ma|03|Sg|Ac|Xx
Pn	PnDm	Ma|03|Sg|Ge|Xx
Pn	PnDm	Ma|03|Sg|Nm|Xx
Pn	PnDm	Ne|03|Pl|Ac|Xx
Pn	PnDm	Ne|03|Pl|Ge|Xx
Pn	PnDm	Ne|03|Pl|Nm|Xx
Pn	PnDm	Ne|03|Sg|Ac|Xx
Pn	PnDm	Ne|03|Sg|Ge|Xx
Pn	PnDm	Ne|03|Sg|Nm|Xx
Pn	PnId	Fe|03|Pl|Ac|Xx
Pn	PnId	Fe|03|Pl|Ge|Xx
Pn	PnId	Fe|03|Pl|Nm|Xx
Pn	PnId	Fe|03|Sg|Ac|Xx
Pn	PnId	Fe|03|Sg|Ge|Xx
Pn	PnId	Fe|03|Sg|Nm|Xx
Pn	PnId	Ma|03|Pl|Ac|Xx
Pn	PnId	Ma|03|Pl|Ge|Xx
Pn	PnId	Ma|03|Pl|Nm|Xx
Pn	PnId	Ma|03|Sg|Ac|Xx
Pn	PnId	Ma|03|Sg|Ge|Xx
Pn	PnId	Ma|03|Sg|Nm|Xx
Pn	PnId	Ne|03|Pl|Ac|Xx
Pn	PnId	Ne|03|Pl|Ge|Xx
Pn	PnId	Ne|03|Pl|Nm|Xx
Pn	PnId	Ne|03|Sg|Ac|Xx
Pn	PnId	Ne|03|Sg|Ge|Xx
Pn	PnId	Ne|03|Sg|Nm|Xx
Pn	PnIr	Fe|03|Pl|Ac|Xx
Pn	PnIr	Fe|03|Pl|Ge|Xx
Pn	PnIr	Fe|03|Pl|Nm|Xx
Pn	PnIr	Fe|03|Sg|Ac|Xx
Pn	PnIr	Fe|03|Sg|Ge|Xx
Pn	PnIr	Fe|03|Sg|Nm|Xx
Pn	PnIr	Ma|03|Pl|Ac|Xx
Pn	PnIr	Ma|03|Pl|Ge|Xx
Pn	PnIr	Ma|03|Pl|Nm|Xx
Pn	PnIr	Ma|03|Sg|Ac|Xx
Pn	PnIr	Ma|03|Sg|Ge|Xx
Pn	PnIr	Ma|03|Sg|Nm|Xx
Pn	PnIr	Ne|03|Pl|Ac|Xx
Pn	PnIr	Ne|03|Pl|Ge|Xx
Pn	PnIr	Ne|03|Pl|Nm|Xx
Pn	PnIr	Ne|03|Sg|Ac|Xx
Pn	PnIr	Ne|03|Sg|Ge|Xx
Pn	PnIr	Ne|03|Sg|Nm|Xx
Pn	PnPe	Fe|03|Pl|Ac|We
Pn	PnPe	Fe|03|Pl|Ge|We
Pn	PnPe	Fe|03|Pl|Nm|St
Pn	PnPe	Fe|03|Sg|Ac|We
Pn	PnPe	Fe|03|Sg|Ge|We
Pn	PnPe	Fe|03|Sg|Nm|St
Pn	PnPe	Ma|01|Pl|Ac|St
Pn	PnPe	Ma|01|Pl|Ac|We
Pn	PnPe	Ma|01|Pl|Ge|We
Pn	PnPe	Ma|01|Pl|Nm|St
Pn	PnPe	Ma|01|Sg|Ac|St
Pn	PnPe	Ma|01|Sg|Ac|We
Pn	PnPe	Ma|01|Sg|Ge|We
Pn	PnPe	Ma|01|Sg|Nm|St
Pn	PnPe	Ma|02|Pl|Ac|St
Pn	PnPe	Ma|02|Pl|Ac|We
Pn	PnPe	Ma|02|Pl|Ge|We
Pn	PnPe	Ma|02|Pl|Nm|St
Pn	PnPe	Ma|02|Sg|Ac|We
Pn	PnPe	Ma|02|Sg|Ge|We
Pn	PnPe	Ma|02|Sg|Nm|St
Pn	PnPe	Ma|03|Pl|Ac|We
Pn	PnPe	Ma|03|Pl|Ge|We
Pn	PnPe	Ma|03|Pl|Nm|St
Pn	PnPe	Ma|03|Sg|Ac|We
Pn	PnPe	Ma|03|Sg|Ge|We
Pn	PnPe	Ma|03|Sg|Nm|St
Pn	PnPe	Ne|03|Pl|Ac|We
Pn	PnPe	Ne|03|Pl|Ge|We
Pn	PnPe	Ne|03|Pl|Nm|St
Pn	PnPe	Ne|03|Sg|Ac|We
Pn	PnPe	Ne|03|Sg|Ge|We
Pn	PnPe	Ne|03|Sg|Nm|St
Pn	PnPo	Fe|03|Sg|Ge|Xx
Pn	PnPo	Ma|01|Pl|Ge|Xx
Pn	PnPo	Ma|01|Sg|Ge|Xx
Pn	PnPo	Ma|02|Pl|Ge|Xx
Pn	PnPo	Ma|02|Sg|Ge|Xx
Pn	PnPo	Ma|03|Pl|Ge|Xx
Pn	PnPo	Ma|03|Sg|Ge|Xx
Pn	PnRe	Fe|03|Pl|Ac|Xx
Pn	PnRe	Fe|03|Pl|Ge|Xx
Pn	PnRe	Fe|03|Pl|Nm|Xx
Pn	PnRe	Fe|03|Sg|Ac|Xx
Pn	PnRe	Fe|03|Sg|Ge|Xx
Pn	PnRe	Fe|03|Sg|Nm|Xx
Pn	PnRe	Ma|03|Pl|Ac|Xx
Pn	PnRe	Ma|03|Pl|Ge|Xx
Pn	PnRe	Ma|03|Pl|Nm|Xx
Pn	PnRe	Ma|03|Sg|Ac|Xx
Pn	PnRe	Ma|03|Sg|Ge|Xx
Pn	PnRe	Ma|03|Sg|Nm|Xx
Pn	PnRe	Ne|03|Pl|Ac|Xx
Pn	PnRe	Ne|03|Pl|Ge|Xx
Pn	PnRe	Ne|03|Pl|Nm|Xx
Pn	PnRe	Ne|03|Sg|Ac|Xx
Pn	PnRe	Ne|03|Sg|Ge|Xx
Pn	PnRe	Ne|03|Sg|Nm|Xx
Pn	PnRi	Fe|03|Pl|Ac|Xx
Pn	PnRi	Fe|03|Pl|Ge|Xx
Pn	PnRi	Fe|03|Pl|Nm|Xx
Pn	PnRi	Fe|03|Sg|Ac|Xx
Pn	PnRi	Fe|03|Sg|Ge|Xx
Pn	PnRi	Fe|03|Sg|Nm|Xx
Pn	PnRi	Ma|03|Pl|Ac|Xx
Pn	PnRi	Ma|03|Pl|Ge|Xx
Pn	PnRi	Ma|03|Pl|Nm|Xx
Pn	PnRi	Ma|03|Sg|Ac|Xx
Pn	PnRi	Ma|03|Sg|Ge|Xx
Pn	PnRi	Ma|03|Sg|Nm|Xx
Pn	PnRi	Ne|03|Pl|Ac|Xx
Pn	PnRi	Ne|03|Pl|Ge|Xx
Pn	PnRi	Ne|03|Pl|Nm|Xx
Pn	PnRi	Ne|03|Sg|Ac|Xx
Pn	PnRi	Ne|03|Sg|Ge|Xx
Pn	PnRi	Ne|03|Sg|Nm|Xx
Pt	PtFu	_
Pt	PtNg	_
Pt	PtOt	_
Pt	PtSj	_
Rg	RgAbXx	_
Rg	RgAnXx	_
Rg	RgFwOr	_
Rg	RgFwTr	_
Vb	VbIs	Id|Pa|03|Sg|Xx|Ip|Av|Xx
Vb	VbIs	Id|Pa|03|Sg|Xx|Ip|Pv|Xx
Vb	VbIs	Id|Pa|03|Sg|Xx|Pe|Av|Xx
Vb	VbIs	Id|Pa|03|Sg|Xx|Pe|Pv|Xx
Vb	VbIs	Id|Pr|03|Sg|Xx|Ip|Av|Xx
Vb	VbIs	Id|Pr|03|Sg|Xx|Ip|Pv|Xx
Vb	VbMn	Id|Pa|01|Pl|Xx|Ip|Av|Xx
Vb	VbMn	Id|Pa|01|Pl|Xx|Ip|Pv|Xx
Vb	VbMn	Id|Pa|01|Pl|Xx|Pe|Av|Xx
Vb	VbMn	Id|Pa|01|Pl|Xx|Pe|Pv|Xx
Vb	VbMn	Id|Pa|01|Sg|Xx|Ip|Av|Xx
Vb	VbMn	Id|Pa|01|Sg|Xx|Ip|Pv|Xx
Vb	VbMn	Id|Pa|01|Sg|Xx|Pe|Av|Xx
Vb	VbMn	Id|Pa|01|Sg|Xx|Pe|Pv|Xx
Vb	VbMn	Id|Pa|02|Pl|Xx|Ip|Av|Xx
Vb	VbMn	Id|Pa|02|Pl|Xx|Ip|Pv|Xx
Vb	VbMn	Id|Pa|02|Pl|Xx|Pe|Av|Xx
Vb	VbMn	Id|Pa|02|Pl|Xx|Pe|Pv|Xx
Vb	VbMn	Id|Pa|02|Sg|Xx|Ip|Av|Xx
Vb	VbMn	Id|Pa|02|Sg|Xx|Ip|Pv|Xx
Vb	VbMn	Id|Pa|02|Sg|Xx|Pe|Av|Xx
Vb	VbMn	Id|Pa|02|Sg|Xx|Pe|Pv|Xx
Vb	VbMn	Id|Pa|03|Pl|Xx|Ip|Av|Xx
Vb	VbMn	Id|Pa|03|Pl|Xx|Ip|Pv|Xx
Vb	VbMn	Id|Pa|03|Pl|Xx|Pe|Av|Xx
Vb	VbMn	Id|Pa|03|Pl|Xx|Pe|Pv|Xx
Vb	VbMn	Id|Pa|03|Sg|Xx|Ip|Av|Xx
Vb	VbMn	Id|Pa|03|Sg|Xx|Ip|Pv|Xx
Vb	VbMn	Id|Pa|03|Sg|Xx|Pe|Av|Xx
Vb	VbMn	Id|Pa|03|Sg|Xx|Pe|Pv|Xx
Vb	VbMn	Id|Pr|01|Pl|Xx|Ip|Av|Xx
Vb	VbMn	Id|Pr|01|Pl|Xx|Ip|Pv|Xx
Vb	VbMn	Id|Pr|01|Sg|Xx|Ip|Av|Xx
Vb	VbMn	Id|Pr|01|Sg|Xx|Ip|Pv|Xx
Vb	VbMn	Id|Pr|02|Pl|Xx|Ip|Av|Xx
Vb	VbMn	Id|Pr|02|Pl|Xx|Ip|Pv|Xx
Vb	VbMn	Id|Pr|02|Sg|Xx|Ip|Av|Xx
Vb	VbMn	Id|Pr|02|Sg|Xx|Ip|Pv|Xx
Vb	VbMn	Id|Pr|03|Pl|Xx|Ip|Av|Xx
Vb	VbMn	Id|Pr|03|Pl|Xx|Ip|Pv|Xx
Vb	VbMn	Id|Pr|03|Sg|Xx|Ip|Av|Xx
Vb	VbMn	Id|Pr|03|Sg|Xx|Ip|Pv|Xx
Vb	VbMn	Id|Xx|01|Pl|Xx|Pe|Av|Xx
Vb	VbMn	Id|Xx|01|Pl|Xx|Pe|Pv|Xx
Vb	VbMn	Id|Xx|01|Sg|Xx|Pe|Av|Xx
Vb	VbMn	Id|Xx|01|Sg|Xx|Pe|Pv|Xx
Vb	VbMn	Id|Xx|02|Pl|Xx|Pe|Av|Xx
Vb	VbMn	Id|Xx|02|Pl|Xx|Pe|Pv|Xx
Vb	VbMn	Id|Xx|02|Sg|Xx|Pe|Av|Xx
Vb	VbMn	Id|Xx|02|Sg|Xx|Pe|Pv|Xx
Vb	VbMn	Id|Xx|03|Pl|Xx|Pe|Av|Xx
Vb	VbMn	Id|Xx|03|Pl|Xx|Pe|Pv|Xx
Vb	VbMn	Id|Xx|03|Sg|Xx|Pe|Av|Xx
Vb	VbMn	Id|Xx|03|Sg|Xx|Pe|Pv|Xx
Vb	VbMn	Mp|Xx|02|Pl|Xx|Pe|Av|Xx
Vb	VbMn	Mp|Xx|02|Pl|Xx|Pe|Pv|Xx
Vb	VbMn	Nf|Xx|Xx|Xx|Xx|Pe|Av|Xx
Vb	VbMn	Nf|Xx|Xx|Xx|Xx|Pe|Pv|Xx
Vb	VbMn	Pp|Xx|Xx|Pl|Fe|Pe|Pv|Ac
Vb	VbMn	Pp|Xx|Xx|Pl|Fe|Pe|Pv|Ge
Vb	VbMn	Pp|Xx|Xx|Pl|Fe|Pe|Pv|Nm
Vb	VbMn	Pp|Xx|Xx|Pl|Ma|Pe|Pv|Nm
Vb	VbMn	Pp|Xx|Xx|Pl|Ne|Pe|Pv|Ac
Vb	VbMn	Pp|Xx|Xx|Pl|Ne|Pe|Pv|Ge
Vb	VbMn	Pp|Xx|Xx|Pl|Ne|Pe|Pv|Nm
Vb	VbMn	Pp|Xx|Xx|Sg|Fe|Pe|Pv|Ac
Vb	VbMn	Pp|Xx|Xx|Sg|Fe|Pe|Pv|Ge
Vb	VbMn	Pp|Xx|Xx|Sg|Fe|Pe|Pv|Nm
Vb	VbMn	Pp|Xx|Xx|Sg|Ma|Pe|Pv|Nm
Vb	VbMn	Pp|Xx|Xx|Sg|Ne|Pe|Pv|Ac
Vb	VbMn	Pp|Xx|Xx|Sg|Ne|Pe|Pv|Ge
Vb	VbMn	Pp|Xx|Xx|Sg|Ne|Pe|Pv|Nm
Vb	VbMn	Pp|Xx|Xx|Xx|Xx|Ip|Av|Xx
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

Lingua::Interset::Tagset::EL::Conll - Driver for the Greek tagset of the CoNLL 2007 Shared Task.

=head1 VERSION

version 3.013

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::EL::Conll;
  my $driver = Lingua::Interset::Tagset::EL::Conll->new();
  my $fs = $driver->decode("No\tNoCm\tMa|Sg|Nm");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('el::conll', "No\tNoCm\tMa|Sg|Nm");

=head1 DESCRIPTION

Interset driver for the Greek tagset of the CoNLL 2007 Shared Task.
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

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
