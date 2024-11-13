# ABSTRACT: Driver for the Jablonskis tagset of Lithuanian.
# Copyright © 2019 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::LT::Jablonskis;
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
    return 'lt::jablonskis';
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
            # noun / daiktavardis
            'dkt'  => ['pos' => 'noun'],
            # adjective / būdvardis
            # All adjectives have definite=ind by default. For definite forms it will be overridden later.
            'bdv'  => ['pos' => 'adj', 'definite' => 'ind'],
            # pronoun / įvardis
            # All pronouns have definite=ind by default. For definite forms it will be overridden later.
            'įv'   => ['pos' => 'noun', 'prontype' => 'prn', 'definite' => 'ind'],
            # numeral / skaitvardis
            # All numerals have definite=ind by default. For definite forms it will be overridden later.
            'sktv' => ['pos' => 'num', 'definite' => 'ind'],
            # verb / veiksmažodis
            # All verbs have polarity=pos by default. For negative forms it will be overridden later.
            'vksm' => ['pos' => 'verb', 'polarity' => 'pos'],
            # adverb / prieveiksmis
            'prv'  => ['pos' => 'adv'],
            # adposition / prielinsknis
            'prl'  => ['pos' => 'adp', 'adpostype' => 'prep'],
            # conjunction / jungtukas
            'jng'  => ['pos' => 'conj'],
            # particle / dalelytė
            'dll'  => ['pos' => 'part'],
            # interjection / jaustukas
            'jst'  => ['pos' => 'int'],
            # onomatopoeia / ištiktukas
            'išt'  => ['pos' => 'int'],
            # acronym / akronimas
            'akr'  => ['abbr' => 'yes', 'other' => {'acronym' => 'yes'}],
            # abbreviation / sutrumpinimas
            'sutr' => ['abbr' => 'yes'],
            # foreign word / užsienio
            'užs'  => ['foreign' => 'yes'],
            # punctuation / skyryba
            'skyr' => ['pos' => 'punc'],
            # period (maybe this is an error. There are 5 occurrences in the corpus. And other 2339 occurrences of the period are tagged "skyr.")
            '.'    => ['pos' => 'punc', 'punctype' => 'peri'],
            # other / kitas: in practice, it is used for symbols and alphanumeric identifiers
            # examples: %, ĮV-459
            'kita' => ['pos' => 'sym']
        },
        'encode_map' =>
        {
            'foreign' => { 'yes' => 'užs',
                           '@'   => {
            'abbr' => { 'yes' => { 'other/acronym' => { 'yes' => 'akr',
                                                        '@'   => 'sutr' }},
                        '@'   => { 'numtype' => { ''  => { 'verbform' => { ''  => { 'pos' => { 'noun' => { 'prontype' => { ''  => 'dkt',
                                                                                                                           '@' => 'įv' }},
                                                                                               'adj'  => 'bdv',
                                                                                               'num'  => 'sktv',
                                                                                               'verb' => 'vksm',
                                                                                               'adv'  => 'prv',
                                                                                               'adp'  => 'prl',
                                                                                               'conj' => 'jng',
                                                                                               'part' => 'dll',
                                                                                               'int'  => 'jst',
                                                                                               'punc' => { 'punctype' => { 'peri' => '.',
                                                                                                                           '@'    => 'skyr' }},
                                                                                               'sym'  => 'kita' }},
                                                                           '@' => 'vksm' }},
                                                  '@' => 'sktv' }}}}}
        }
    );
    # NOUNTYPE ####################
    # Daiktavardžių rūšys
    $atoms{nountype} = $self->create_simple_atom
    (
        'intfeature' => 'nountype',
        'simple_decode_map' =>
        {
            # common noun / bendrinis: no tag
            # proper noun / tikrinis
            'tikr' => 'prop'
        }
    );
    # GENDER ####################
    # Giminė
    $atoms{gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            # vyriškoji giminė
            'vyr'   => 'masc',
            # moteriškoji giminė
            'mot'   => 'fem',
            # bevardė giminė
            'bev'   => 'neut',
            # bendroji giminė
            'bendr' => 'com'
        },
        'encode_default' => ''
    );
    # NUMBER ####################
    # Skaičius
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            # vienaskaita
            'vns'   => 'sing',
            # dviskaita
            'dvisk' => 'dual',
            # daugiskaita
            'dgs'   => 'plur'
        },
        'encode_default' => ''
    );
    # CASE ####################
    # Linksnis
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            # vardininkas
            'V'  => 'nom',
            # kilmininkas
            'K'  => 'gen',
            # naudininkas
            'N'  => 'dat',
            # galininkas
            'G'  => 'acc',
            # įnagininkas
            'Įn' => 'ins',
            # vietininkas
            'Vt' => 'loc',
            # šauksmininkas
            'Š'  => 'voc',
            # iliatyvas
            'Il' => 'ill'
        },
        'encode_default' => ''
    );
    # DEGREE ####################
    # Laipsnis
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            # nelyginamasis laipsnis
            'nelygin' => 'pos',
            # aukštesnysis laipsnis
            'aukšt'   => 'cmp',
            # aukščiausiasis laipsnis
            'aukšč'   => 'sup'
        },
        'encode_default' => ''
    );
    # ADJECTIVE FORMATION / DEFINITENESS ####################
    # Apibrėžtumas
    $atoms{definite} = $self->create_simple_atom
    (
        'intfeature' => 'definite',
        'simple_decode_map' =>
        {
            # įvardžiuotinis = pronominal = definite
            'įvardž' => 'def'#,
            # neįvardžiuotinis = nominal = indefinite
            ###!!! The tags in our list below actually do not use the 'neįvardž' value.
            ###!!! Instead, they omit the definiteness feature.
            #'neįvardž' => 'ind'
        },
        'encode_default' => ''
    );
    # PERSON ####################
    # Asmuo
    $atoms{person} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            # pirmasis asmuo
            '1' => '1',
            # antrasis asmuo
            '2' => '2',
            # trečiasis asmuo
            '3' => '3'
        },
        'encode_default' => ''
    );
    # NUMERAL TYPE ####################
    # Skaitvardžiai
    $atoms{numtype} = $self->create_simple_atom
    (
        'intfeature' => 'numtype',
        'simple_decode_map' =>
        {
            # kiekinis
            'kiek'   => 'card',
            # kelintinis
            'kelint' => 'ord',
            # dauginis
            'daugin' => 'mult',
            # kuopinis = collective
            'kuopin' => 'sets'
        },
        'encode_default' => ''
    );
    # NUMERAL FORM ####################
    # Romėniški skaičiai
    $atoms{numform} = $self->create_simple_atom
    (
        'intfeature' => 'numform',
        'simple_decode_map' =>
        {
            # arabiškas skaičius
            'arab' => 'digit',
            # romėniškas skaičius
            'rom'  => 'roman',
            # mišrus skaitvardis (pvz., 2-oji, 50-ies)
            'mišr' => 'combi',
            # žodžiu užrašytas skaitvardis
            'raid' => 'word'
        },
        'encode_default' => ''
    );
    # VERB FORM ####################
    # Veiksmažodis ir jo formos
    $atoms{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            # asmenuojama forma = personal form
            'asm'  => ['pos' => 'verb', 'verbform' => 'fin'],
            # bendratis
            'bndr' => ['pos' => 'verb', 'verbform' => 'inf'],
            # dalyvis = participle
            # All participles have definite=ind by default. For definite forms it will be overridden later.
            'dlv'  => ['pos' => 'verb', 'verbform' => 'part', 'definite' => 'ind'],
            # padalyvis = half participle = same subject converb
            # The tentative conversion by the authors of ALKSNIS maps padalyvis to gerund and pusdalyvis to converb.
            'pad'  => ['pos' => 'verb', 'verbform' => 'ger'],
            # pusdalyvis = adverbial participle = different subject converb
            'pusd' => ['pos' => 'verb', 'verbform' => 'conv'],
            # būdinys = adverbial participle of manner
            'būdn' => ['pos' => 'adv', 'verbform' => 'conv']
        },
        'encode_map' =>
        {
            'verbform' => { 'fin'  => 'asm',
                            'inf'  => 'bndr',
                            'part' => 'dlv',
                            'ger'  => 'pad',
                            'conv' => { 'pos' => { 'verb' => 'pusd',
                                                   'adv'  => 'būdn' }}}
        }
    );
    # MOOD ####################
    # Nuosaka
    $atoms{mood} = $self->create_simple_atom
    (
        'intfeature' => 'mood',
        'simple_decode_map' =>
        {
            # tiesioginė nuosaka
            'tiesiog' => 'ind',
            # liepiamoji nuosaka
            'liep'    => 'imp',
            # tariamoji nuosaka = subjunctive or conditional
            'tar'     => 'cnd'
        },
        'encode_default' => ''
    );
    # TENSE ####################
    # Laikas
    $atoms{tense} = $self->create_atom
    (
        'surfeature' => 'tense',
        'decode_map' =>
        {
            # esamasis laikas
            'es'    => ['tense' => 'pres'],
            # būtasis laikas
            'būt'   => ['tense' => 'past'],
            # būtasis kartinis laikas = simple past
            'būt-k' => ['tense' => 'past', 'aspect' => 'perf'],
            # būtasis dažninis laikas = iterative / frequentative / habitual past
            # The tentative conversion by the ALKSNIS authors uses Aspect=Iter, not Aspect=Hab.
            'būt-d' => ['tense' => 'past', 'aspect' => 'hab'],
            # būsimasis laikas
            'būs'   => ['tense' => 'fut']
        },
        'encode_map' =>
        {
            'tense' => { 'pres' => 'es',
                         'past' => { 'aspect' => { 'hab'  => 'būt-d',
                                                   'iter' => 'būt-d',
                                                   'imp'  => 'būt-k',
                                                   'perf' => 'būt-k',
                                                   '@'    => 'būt' }},
                         'fut'  => 'būs' }
        }
    );
    # VOICE ####################
    # Rūšis
    $atoms{voice} = $self->create_atom
    (
        'surfeature' => 'voice',
        'decode_map' =>
        {
            # veikiamoji rūšis
            'veik'   => ['voice' => 'act'],
            # neveikiamoji rūšis
            'neveik' => ['voice' => 'pass'],
            # reikiamybės = debitive / necessitative (voice?)
            # The tagset classifies "reik" as a voice but it is not a voice.
            # It occurs exclusively with the "dlv" verb form (dalyvis, participle).
            # It distinguishes the necessitative participle from the other participles.
            'reik'   => ['mood' => 'nec']
        },
        'encode_map' =>
        {
            'mood' => { 'nec' => 'reik',
                        '@'   => { 'voice' => { 'act'  => 'veik',
                                                'pass' => 'neveik' }}}
        }
    );
    # REFLEXIVITY ####################
    # Sangrąžumas
    $atoms{reflex} = $self->create_simple_atom
    (
        'intfeature' => 'reflex',
        'simple_decode_map' =>
        {
            'sngr' => 'yes'
        },
        'encode_default' => ''
    );
    # POLARITY ####################
    # Teigiamumas
    $atoms{polarity} = $self->create_simple_atom
    (
        'intfeature' => 'polarity',
        'simple_decode_map' =>
        {
            ###!!! The tags in our list below actually do not use the 'teig' value.
            ###!!! Instead, they omit the polarity feature.
            # teigiamas
            #'teig' => 'pos',
            # neigiamas
            'neig' => 'neg'
        },
        'encode_default' => ''
    );
    # PART OF COMPOUND ####################
    # Samplaikiškumas
    $atoms{hyph} = $self->create_atom
    (
        'surfeature' => 'hyph',
        'decode_map' =>
        {
            # samplaikos pradžia = first part of a compound
            'sampl' => ['hyph' => 'yes', 'other' => {'compound' => 'ini'}],
            # nesamplaikinis = non-compound ... unmarked
            # samplaikos tęsinys = continuation of a compound
            'tęs'   => ['hyph' => 'yes', 'other' => {'compound' => 'fin'}]
        },
        'encode_map' =>
        {
            'hyph' => { 'yes' => { 'other/compound' => { 'ini' => 'sampl',
                                                         'fin' => 'tęs',
                                                         '@'   => '' }},
                        '@'   => '' }
        }
    );
    # IDIOM TYPE ####################
    $atoms{idiomtype} = $self->create_atom
    (
        'surfeature' => 'idiomtype',
        'decode_map' =>
        {
            # multi-word preposition
            'idprl'  => ['pos' => 'adp'],
            # multi-word conjunction
            'idjngt' => ['pos' => 'conj'],
            # PS???
            'idPS'   => []
        },
        'encode_map' =>
        {
            'pos' => { 'adp'  => 'idprl',
                       'conj' => 'idjngt',
                       ''     => 'idPS',
                       '@'    => '' }
        }
    );
    # MERGED ATOM TO DECODE ANY FEATURE VALUE ####################
    my @fatoms = map
    {
        confess("Undefined atom for feature $_") if(!defined($atoms{$_}));
        $atoms{$_}
    }
    (@{$self->features_all()});
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
    my @features = ('pos', 'nountype', 'reflex', 'numtype', 'numform', 'degree', 'definite', 'gender', 'number', 'case', 'verbform', 'tense', 'person', 'polarity', 'voice', 'mood', 'hyph');
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
        'dkt'  => ['nountype', 'reflex', 'gender', 'number', 'case'],
        'bdv'  => ['degree', 'definite', 'gender', 'number', 'case'],
        'įv'   => ['definite', 'gender', 'number', 'case'],
        'sktv' => ['numform', 'numtype', 'definite', 'gender', 'number', 'case'],
        'vksm' => ['verbform', 'polarity', 'reflex', 'mood', 'voice', 'tense', 'degree', 'definite', 'gender', 'number', 'person', 'case'],
        'prv'  => ['degree'],
        'prl'  => ['case']
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
    $fs->set_tagset('lt::jablonskis');
    my $atoms = $self->atoms();
    # The part of speech and all other features form one string. Each part is terminated by a period.
    # example: dkt.vyr.vns.V.
    # exception: the tag '.' is possibly an error but it occurs in the corpus
    my @features;
    if($tag eq '.')
    {
        @features = ('.');
    }
    else
    {
        # Any tag can start with "sampl." (even before the actual part of speech).
        # Samplaikiškumas (= "agility", says Google Translate)
        # samplaikos pradžia (sampl) = "beginning of the clash"
        # nesamplaikinis (without the "sampl" tag) = "timeless"
        # Google Translate provides quite weird clues but it seems to tag the initial
        # part of a multi-token compound.
        # samplaikos tęsinys = continuation of a compound
        my $sampl;
        if($tag =~ s/^(sampl|tęs)\.//)
        {
            $sampl = $1;
        }
        $tag =~ s/\.$//;
        @features = split(/\./, $tag);
        push(@features, $sampl) if($sampl);
    }
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
    my $pos = $atoms->{pos}->encode($fs);
    my $fpos = $pos;
    my $feature_names = $self->get_feature_names($fpos);
    my @features = ($pos);
    my $hyph = $atoms->{hyph}->encode($fs);
    unshift(@features, $hyph) if($hyph);
    if(defined($feature_names) && ref($feature_names) eq 'ARRAY')
    {
        foreach my $feature (@{$feature_names})
        {
            my $value = $atoms->{$feature}->encode($fs);
            push(@features, $value) unless($value eq '');
        }
    }
    my $tag = join('.', @features);
    $tag .= '.' unless($tag =~ m/\.$/);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# 696
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
.
akr.
bdv.aukšt.mot.dgs.G.
bdv.aukšt.mot.dgs.K.
bdv.aukšt.mot.dgs.V.
bdv.aukšt.mot.dgs.Vt.
bdv.aukšt.mot.dgs.Įn.
bdv.aukšt.mot.vns.G.
bdv.aukšt.mot.vns.K.
bdv.aukšt.mot.vns.V.
bdv.aukšt.mot.vns.Įn.
bdv.aukšt.vyr.dgs.G.
bdv.aukšt.vyr.dgs.K.
bdv.aukšt.vyr.dgs.V.
bdv.aukšt.vyr.dgs.Įn.
bdv.aukšt.vyr.vns.G.
bdv.aukšt.vyr.vns.K.
bdv.aukšt.vyr.vns.N.
bdv.aukšt.vyr.vns.V.
bdv.aukšt.vyr.vns.Vt.
bdv.aukšt.vyr.vns.Įn.
bdv.aukšt.įvardž.mot.vns.V.
bdv.aukšt.įvardž.vyr.vns.G.
bdv.aukšč.bev.
bdv.aukšč.mot.dgs.G.
bdv.aukšč.mot.dgs.K.
bdv.aukšč.mot.dgs.N.
bdv.aukšč.mot.dgs.V.
bdv.aukšč.mot.dgs.Vt.
bdv.aukšč.mot.dgs.Įn.
bdv.aukšč.mot.vns.K.
bdv.aukšč.mot.vns.V.
bdv.aukšč.mot.vns.Vt.
bdv.aukšč.mot.vns.Įn.
bdv.aukšč.vyr.dgs.G.
bdv.aukšč.vyr.dgs.K.
bdv.aukšč.vyr.dgs.V.
bdv.aukšč.vyr.dgs.Įn.
bdv.aukšč.vyr.vns.G.
bdv.aukšč.vyr.vns.K.
bdv.aukšč.vyr.vns.V.
bdv.aukšč.vyr.vns.Įn.
bdv.aukšč.įvardž.mot.vns.K.
bdv.aukšč.įvardž.mot.vns.V.
bdv.nelygin.
bdv.nelygin.bev.
bdv.nelygin.mot.dgs.G.
bdv.nelygin.mot.dgs.K.
bdv.nelygin.mot.dgs.N.
bdv.nelygin.mot.dgs.V.
bdv.nelygin.mot.dgs.Vt.
bdv.nelygin.mot.dgs.Įn.
bdv.nelygin.mot.vns.G.
bdv.nelygin.mot.vns.K.
bdv.nelygin.mot.vns.N.
bdv.nelygin.mot.vns.V.
bdv.nelygin.mot.vns.Vt.
bdv.nelygin.mot.vns.Įn.
bdv.nelygin.vyr.dgs.G.
bdv.nelygin.vyr.dgs.K.
bdv.nelygin.vyr.dgs.N.
bdv.nelygin.vyr.dgs.V.
bdv.nelygin.vyr.dgs.Vt.
bdv.nelygin.vyr.dgs.Įn.
bdv.nelygin.vyr.vns.G.
bdv.nelygin.vyr.vns.K.
bdv.nelygin.vyr.vns.N.
bdv.nelygin.vyr.vns.V.
bdv.nelygin.vyr.vns.Vt.
bdv.nelygin.vyr.vns.Įn.
bdv.nelygin.vyr.vns.Š.
bdv.nelygin.įvardž.mot.dgs.G.
bdv.nelygin.įvardž.mot.dgs.K.
bdv.nelygin.įvardž.mot.dgs.N.
bdv.nelygin.įvardž.mot.dgs.V.
bdv.nelygin.įvardž.mot.dgs.Įn.
bdv.nelygin.įvardž.mot.vns.G.
bdv.nelygin.įvardž.mot.vns.K.
bdv.nelygin.įvardž.mot.vns.N.
bdv.nelygin.įvardž.mot.vns.V.
bdv.nelygin.įvardž.mot.vns.Vt.
bdv.nelygin.įvardž.mot.vns.Įn.
bdv.nelygin.įvardž.vyr.dgs.G.
bdv.nelygin.įvardž.vyr.dgs.K.
bdv.nelygin.įvardž.vyr.dgs.N.
bdv.nelygin.įvardž.vyr.dgs.V.
bdv.nelygin.įvardž.vyr.dgs.Vt.
bdv.nelygin.įvardž.vyr.dgs.Įn.
bdv.nelygin.įvardž.vyr.vns.G.
bdv.nelygin.įvardž.vyr.vns.K.
bdv.nelygin.įvardž.vyr.vns.N.
bdv.nelygin.įvardž.vyr.vns.V.
bdv.nelygin.įvardž.vyr.vns.Vt.
bdv.nelygin.įvardž.vyr.vns.Įn.
dkt.bendr.dgs.V.
dkt.bendr.vns.K.
dkt.bendr.vns.N.
dkt.bendr.vns.V.
dkt.mot.
dkt.mot.dgs.G.
dkt.mot.dgs.K.
dkt.mot.dgs.N.
dkt.mot.dgs.V.
dkt.mot.dgs.Vt.
dkt.mot.dgs.Įn.
dkt.mot.dgs.Š.
dkt.mot.vns.G.
dkt.mot.vns.Il.
dkt.mot.vns.K.
dkt.mot.vns.N.
dkt.mot.vns.V.
dkt.mot.vns.Vt.
dkt.mot.vns.Įn.
dkt.mot.vns.Š.
dkt.sngr.vyr.dgs.K.
dkt.sngr.vyr.dgs.V.
dkt.sngr.vyr.vns.G.
dkt.sngr.vyr.vns.K.
dkt.sngr.vyr.vns.N.
dkt.sngr.vyr.vns.V.
dkt.sngr.vyr.vns.Įn.
dkt.tikr.
dkt.tikr.mot.dgs.G.
dkt.tikr.mot.dgs.K.
dkt.tikr.mot.dgs.V.
dkt.tikr.mot.dgs.Vt.
dkt.tikr.mot.vns.G.
dkt.tikr.mot.vns.K.
dkt.tikr.mot.vns.N.
dkt.tikr.mot.vns.V.
dkt.tikr.mot.vns.Vt.
dkt.tikr.mot.vns.Įn.
dkt.tikr.vyr.dgs.K.
dkt.tikr.vyr.dgs.V.
dkt.tikr.vyr.dgs.Vt.
dkt.tikr.vyr.vns.
dkt.tikr.vyr.vns.G.
dkt.tikr.vyr.vns.K.
dkt.tikr.vyr.vns.N.
dkt.tikr.vyr.vns.V.
dkt.tikr.vyr.vns.Vt.
dkt.tikr.vyr.vns.Įn.
dkt.vyr.
dkt.vyr.dgs.G.
dkt.vyr.dgs.K.
dkt.vyr.dgs.N.
dkt.vyr.dgs.V.
dkt.vyr.dgs.Vt.
dkt.vyr.dgs.Įn.
dkt.vyr.dgs.Š.
dkt.vyr.vns.G.
dkt.vyr.vns.Il.
dkt.vyr.vns.K.
dkt.vyr.vns.N.
dkt.vyr.vns.V.
dkt.vyr.vns.Vt.
dkt.vyr.vns.Įn.
dkt.vyr.vns.Š.
dll.
jng.
jst.
kita.
prl.G.
prl.K.
prl.Įn.
prv.aukšt.
prv.aukšč.
prv.nelygin.
sampl.dll.
sampl.jng.
sampl.jst.
sampl.prl.G.
sampl.prl.K.
sampl.prv.nelygin.
sampl.sktv.
sampl.sutr.
sampl.užs.
sampl.vksm.pad.es.
sampl.įv.G.
sampl.įv.K.
sampl.įv.V.
sampl.įv.bev.
sampl.įv.mot.dgs.G.
sampl.įv.mot.dgs.K.
sampl.įv.mot.dgs.V.
sampl.įv.mot.dgs.Vt.
sampl.įv.mot.dgs.Įn.
sampl.įv.mot.vns.G.
sampl.įv.mot.vns.K.
sampl.įv.mot.vns.V.
sampl.įv.mot.vns.Vt.
sampl.įv.mot.vns.Įn.
sampl.įv.vyr.dgs.G.
sampl.įv.vyr.dgs.K.
sampl.įv.vyr.dgs.N.
sampl.įv.vyr.dgs.V.
sampl.įv.vyr.dgs.Vt.
sampl.įv.vyr.dgs.Įn.
sampl.įv.vyr.vns.G.
sampl.įv.vyr.vns.K.
sampl.įv.vyr.vns.V.
sampl.įv.vyr.vns.Vt.
sampl.įv.vyr.vns.Įn.
sampl.įv.Įn.
sktv.
sktv.arab.
sktv.kiek.mot.vns.G.
sktv.kiek.vyr.vns.G.
sktv.mišr.
sktv.mišr.kelint.įvardž.mot.vns.G.
sktv.mišr.kelint.įvardž.mot.vns.V.
sktv.mišr.kelint.įvardž.vyr.dgs.K.
sktv.raid.daugin.mot.V.
sktv.raid.daugin.vyr.G.
sktv.raid.daugin.vyr.K.
sktv.raid.daugin.vyr.N.
sktv.raid.daugin.vyr.V.
sktv.raid.kelint.bev.
sktv.raid.kelint.mot.vns.K.
sktv.raid.kelint.mot.vns.V.
sktv.raid.kelint.vyr.dgs.K.
sktv.raid.kelint.vyr.dgs.V.
sktv.raid.kelint.vyr.dgs.Įn.
sktv.raid.kelint.vyr.vns.G.
sktv.raid.kelint.vyr.vns.K.
sktv.raid.kelint.vyr.vns.N.
sktv.raid.kelint.vyr.vns.V.
sktv.raid.kelint.įvardž.mot.dgs.V.
sktv.raid.kelint.įvardž.mot.dgs.Įn.
sktv.raid.kelint.įvardž.mot.vns.G.
sktv.raid.kelint.įvardž.mot.vns.V.
sktv.raid.kelint.įvardž.mot.vns.Vt.
sktv.raid.kelint.įvardž.mot.vns.Įn.
sktv.raid.kelint.įvardž.vyr.dgs.V.
sktv.raid.kelint.įvardž.vyr.dgs.Vt.
sktv.raid.kelint.įvardž.vyr.vns.G.
sktv.raid.kelint.įvardž.vyr.vns.K.
sktv.raid.kelint.įvardž.vyr.vns.V.
sktv.raid.kelint.įvardž.vyr.vns.Vt.
sktv.raid.kiek.
sktv.raid.kiek.K.
sktv.raid.kiek.V.
sktv.raid.kiek.mot.G.
sktv.raid.kiek.mot.K.
sktv.raid.kiek.mot.N.
sktv.raid.kiek.mot.V.
sktv.raid.kiek.mot.dgs.G.
sktv.raid.kiek.mot.dgs.K.
sktv.raid.kiek.mot.dgs.V.
sktv.raid.kiek.mot.vns.G.
sktv.raid.kiek.mot.vns.K.
sktv.raid.kiek.mot.vns.N.
sktv.raid.kiek.mot.vns.V.
sktv.raid.kiek.mot.vns.Įn.
sktv.raid.kiek.mot.Įn.
sktv.raid.kiek.vyr.G.
sktv.raid.kiek.vyr.K.
sktv.raid.kiek.vyr.N.
sktv.raid.kiek.vyr.V.
sktv.raid.kiek.vyr.dgs.G.
sktv.raid.kiek.vyr.dgs.K.
sktv.raid.kiek.vyr.dgs.V.
sktv.raid.kiek.vyr.vns.G.
sktv.raid.kiek.vyr.vns.K.
sktv.raid.kiek.vyr.vns.V.
sktv.raid.kiek.vyr.Įn.
sktv.raid.kuopin.G.
sktv.rom.
skyr.
sutr.
tęs.
tęs.įv.vyr.dgs.G.
tęs.įv.vyr.dgs.N.
tęs.įv.vyr.vns.G.
tęs.įv.vyr.vns.N.
tęs.įv.vyr.vns.V.
tęs.įv.vyr.vns.Įn.
užs.
vksm.asm.būs.3.
vksm.asm.būt-k.3.
vksm.asm.liep.dgs.1.
vksm.asm.liep.dgs.2.
vksm.asm.liep.vns.2.
vksm.asm.liep.vns.3.
vksm.asm.neig.liep.dgs.1.
vksm.asm.neig.liep.dgs.2.
vksm.asm.neig.liep.vns.2.
vksm.asm.neig.sngr.liep.dgs.2.
vksm.asm.neig.sngr.tar.3.
vksm.asm.neig.sngr.tar.dgs.1.
vksm.asm.neig.sngr.tar.dgs.3.
vksm.asm.neig.sngr.tar.vns.1.
vksm.asm.neig.sngr.tar.vns.3.
vksm.asm.neig.sngr.tiesiog.būs.vns.2.
vksm.asm.neig.sngr.tiesiog.būs.vns.3.
vksm.asm.neig.sngr.tiesiog.būt-k.3.
vksm.asm.neig.sngr.tiesiog.būt-k.dgs.1.
vksm.asm.neig.sngr.tiesiog.būt-k.dgs.3.
vksm.asm.neig.sngr.tiesiog.būt-k.vns.1.
vksm.asm.neig.sngr.tiesiog.būt-k.vns.3.
vksm.asm.neig.sngr.tiesiog.es.3.
vksm.asm.neig.sngr.tiesiog.es.dgs.1.
vksm.asm.neig.sngr.tiesiog.es.dgs.2.
vksm.asm.neig.sngr.tiesiog.es.dgs.3.
vksm.asm.neig.sngr.tiesiog.es.vns.1.
vksm.asm.neig.sngr.tiesiog.es.vns.3.
vksm.asm.neig.tar.3.
vksm.asm.neig.tar.dgs.2.
vksm.asm.neig.tar.dgs.3.
vksm.asm.neig.tar.vns.1.
vksm.asm.neig.tar.vns.2.
vksm.asm.neig.tar.vns.3.
vksm.asm.neig.tiesiog.būs.3.
vksm.asm.neig.tiesiog.būs.dgs.1.
vksm.asm.neig.tiesiog.būs.dgs.2.
vksm.asm.neig.tiesiog.būs.dgs.3.
vksm.asm.neig.tiesiog.būs.vns.1.
vksm.asm.neig.tiesiog.būs.vns.2.
vksm.asm.neig.tiesiog.būs.vns.3.
vksm.asm.neig.tiesiog.būt-d.dgs.2.
vksm.asm.neig.tiesiog.būt-d.vns.1.
vksm.asm.neig.tiesiog.būt-d.vns.3.
vksm.asm.neig.tiesiog.būt-k.3.
vksm.asm.neig.tiesiog.būt-k.dgs.1.
vksm.asm.neig.tiesiog.būt-k.dgs.2.
vksm.asm.neig.tiesiog.būt-k.dgs.3.
vksm.asm.neig.tiesiog.būt-k.vns.1.
vksm.asm.neig.tiesiog.būt-k.vns.2.
vksm.asm.neig.tiesiog.būt-k.vns.3.
vksm.asm.neig.tiesiog.es.3.
vksm.asm.neig.tiesiog.es.dgs.1.
vksm.asm.neig.tiesiog.es.dgs.2.
vksm.asm.neig.tiesiog.es.dgs.3.
vksm.asm.neig.tiesiog.es.vns.1.
vksm.asm.neig.tiesiog.es.vns.2.
vksm.asm.neig.tiesiog.es.vns.3.
vksm.asm.sngr.liep.dgs.1.
vksm.asm.sngr.liep.dgs.2.
vksm.asm.sngr.liep.vns.2.
vksm.asm.sngr.tar.3.
vksm.asm.sngr.tar.dgs.2.
vksm.asm.sngr.tar.dgs.3.
vksm.asm.sngr.tar.vns.1.
vksm.asm.sngr.tar.vns.3.
vksm.asm.sngr.tiesiog.būs.3.
vksm.asm.sngr.tiesiog.būs.dgs.1.
vksm.asm.sngr.tiesiog.būs.dgs.2.
vksm.asm.sngr.tiesiog.būs.dgs.3.
vksm.asm.sngr.tiesiog.būs.vns.1.
vksm.asm.sngr.tiesiog.būs.vns.2.
vksm.asm.sngr.tiesiog.būs.vns.3.
vksm.asm.sngr.tiesiog.būt-d.dgs.3.
vksm.asm.sngr.tiesiog.būt-d.vns.1.
vksm.asm.sngr.tiesiog.būt-d.vns.3.
vksm.asm.sngr.tiesiog.būt-k.3.
vksm.asm.sngr.tiesiog.būt-k.dgs.1.
vksm.asm.sngr.tiesiog.būt-k.dgs.2.
vksm.asm.sngr.tiesiog.būt-k.dgs.3.
vksm.asm.sngr.tiesiog.būt-k.vns.1.
vksm.asm.sngr.tiesiog.būt-k.vns.2.
vksm.asm.sngr.tiesiog.būt-k.vns.3.
vksm.asm.sngr.tiesiog.es.3.
vksm.asm.sngr.tiesiog.es.dgs.1.
vksm.asm.sngr.tiesiog.es.dgs.2.
vksm.asm.sngr.tiesiog.es.dgs.3.
vksm.asm.sngr.tiesiog.es.vns.1.
vksm.asm.sngr.tiesiog.es.vns.2.
vksm.asm.sngr.tiesiog.es.vns.3.
vksm.asm.tar.3.
vksm.asm.tar.dgs.1.
vksm.asm.tar.dgs.2.
vksm.asm.tar.dgs.3.
vksm.asm.tar.vns.1.
vksm.asm.tar.vns.2.
vksm.asm.tar.vns.3.
vksm.asm.tiesiog.būs.3.
vksm.asm.tiesiog.būs.dgs.1.
vksm.asm.tiesiog.būs.dgs.2.
vksm.asm.tiesiog.būs.dgs.3.
vksm.asm.tiesiog.būs.vns.1.
vksm.asm.tiesiog.būs.vns.2.
vksm.asm.tiesiog.būs.vns.3.
vksm.asm.tiesiog.būt-d.3.
vksm.asm.tiesiog.būt-d.dgs.1.
vksm.asm.tiesiog.būt-d.dgs.3.
vksm.asm.tiesiog.būt-d.vns.1.
vksm.asm.tiesiog.būt-d.vns.2.
vksm.asm.tiesiog.būt-d.vns.3.
vksm.asm.tiesiog.būt-k.3.
vksm.asm.tiesiog.būt-k.dgs.1.
vksm.asm.tiesiog.būt-k.dgs.2.
vksm.asm.tiesiog.būt-k.dgs.3.
vksm.asm.tiesiog.būt-k.vns.1.
vksm.asm.tiesiog.būt-k.vns.2.
vksm.asm.tiesiog.būt-k.vns.3.
vksm.asm.tiesiog.es.3.
vksm.asm.tiesiog.es.dgs.1.
vksm.asm.tiesiog.es.dgs.2.
vksm.asm.tiesiog.es.dgs.3.
vksm.asm.tiesiog.es.vns.1.
vksm.asm.tiesiog.es.vns.2.
vksm.asm.tiesiog.es.vns.3.
vksm.bndr.
vksm.bndr.neig.
vksm.bndr.neig.sngr.
vksm.bndr.sngr.
vksm.būdn.
vksm.dlv.neig.neveik.būt-k.mot.vns.Vt.
vksm.dlv.neig.neveik.būt.bev.
vksm.dlv.neig.neveik.būt.mot.dgs.K.
vksm.dlv.neig.neveik.būt.mot.vns.G.
vksm.dlv.neig.neveik.būt.mot.vns.K.
vksm.dlv.neig.neveik.būt.mot.vns.V.
vksm.dlv.neig.neveik.būt.vyr.dgs.V.
vksm.dlv.neig.neveik.būt.vyr.dgs.Įn.
vksm.dlv.neig.neveik.būt.vyr.vns.G.
vksm.dlv.neig.neveik.būt.vyr.vns.K.
vksm.dlv.neig.neveik.būt.vyr.vns.V.
vksm.dlv.neig.neveik.es.bev.
vksm.dlv.neig.neveik.es.mot.dgs.G.
vksm.dlv.neig.neveik.es.mot.dgs.K.
vksm.dlv.neig.neveik.es.mot.dgs.V.
vksm.dlv.neig.neveik.es.mot.dgs.Įn.
vksm.dlv.neig.neveik.es.mot.vns.G.
vksm.dlv.neig.neveik.es.mot.vns.K.
vksm.dlv.neig.neveik.es.mot.vns.V.
vksm.dlv.neig.neveik.es.vyr.dgs.G.
vksm.dlv.neig.neveik.es.vyr.dgs.K.
vksm.dlv.neig.neveik.es.vyr.dgs.V.
vksm.dlv.neig.neveik.es.vyr.vns.V.
vksm.dlv.neig.neveik.es.įvardž.vyr.dgs.K.
vksm.dlv.neig.reik.bev.
vksm.dlv.neig.reik.vyr.vns.V.
vksm.dlv.neig.sngr.neveik.es.bev.
vksm.dlv.neig.sngr.veik.būs.mot.vns.V.
vksm.dlv.neig.sngr.veik.būt-k.vyr.dgs.V.
vksm.dlv.neig.sngr.veik.es.mot.vns.G.
vksm.dlv.neig.sngr.veik.es.vyr.vns.V.
vksm.dlv.neig.veik.būt-k.bev.
vksm.dlv.neig.veik.būt-k.mot.dgs.V.
vksm.dlv.neig.veik.būt-k.mot.vns.G.
vksm.dlv.neig.veik.būt-k.mot.vns.V.
vksm.dlv.neig.veik.būt-k.vyr.dgs.V.
vksm.dlv.neig.veik.būt-k.vyr.vns.V.
vksm.dlv.neig.veik.es.mot.vns.N.
vksm.dlv.neig.veik.es.mot.vns.V.
vksm.dlv.neig.veik.es.mot.vns.Įn.
vksm.dlv.neig.veik.es.vyr.dgs.G.
vksm.dlv.neig.veik.es.vyr.dgs.K.
vksm.dlv.neig.veik.es.vyr.dgs.N.
vksm.dlv.neig.veik.es.vyr.dgs.V.
vksm.dlv.neig.veik.es.vyr.dgs.Įn.
vksm.dlv.neig.veik.es.vyr.vns.K.
vksm.dlv.neig.veik.es.vyr.vns.V.
vksm.dlv.neig.veik.es.vyr.vns.Įn.
vksm.dlv.neveik.būs.vyr.vns.G.
vksm.dlv.neveik.būs.vyr.vns.N.
vksm.dlv.neveik.būt-k.vyr.dgs.V.
vksm.dlv.neveik.būt.bev.
vksm.dlv.neveik.būt.mot.dgs.G.
vksm.dlv.neveik.būt.mot.dgs.K.
vksm.dlv.neveik.būt.mot.dgs.N.
vksm.dlv.neveik.būt.mot.dgs.V.
vksm.dlv.neveik.būt.mot.dgs.Vt.
vksm.dlv.neveik.būt.mot.dgs.Įn.
vksm.dlv.neveik.būt.mot.vns.G.
vksm.dlv.neveik.būt.mot.vns.K.
vksm.dlv.neveik.būt.mot.vns.N.
vksm.dlv.neveik.būt.mot.vns.V.
vksm.dlv.neveik.būt.mot.vns.Vt.
vksm.dlv.neveik.būt.mot.vns.Įn.
vksm.dlv.neveik.būt.vyr.dgs.G.
vksm.dlv.neveik.būt.vyr.dgs.K.
vksm.dlv.neveik.būt.vyr.dgs.N.
vksm.dlv.neveik.būt.vyr.dgs.V.
vksm.dlv.neveik.būt.vyr.dgs.Vt.
vksm.dlv.neveik.būt.vyr.dgs.Įn.
vksm.dlv.neveik.būt.vyr.vns.G.
vksm.dlv.neveik.būt.vyr.vns.K.
vksm.dlv.neveik.būt.vyr.vns.N.
vksm.dlv.neveik.būt.vyr.vns.V.
vksm.dlv.neveik.būt.vyr.vns.Vt.
vksm.dlv.neveik.būt.vyr.vns.Įn.
vksm.dlv.neveik.būt.įvardž.mot.vns.V.
vksm.dlv.neveik.būt.įvardž.vyr.dgs.K.
vksm.dlv.neveik.būt.įvardž.vyr.dgs.V.
vksm.dlv.neveik.būt.įvardž.vyr.vns.V.
vksm.dlv.neveik.es.aukšč.vyr.vns.Įn.
vksm.dlv.neveik.es.bev.
vksm.dlv.neveik.es.mot.dgs.G.
vksm.dlv.neveik.es.mot.dgs.K.
vksm.dlv.neveik.es.mot.dgs.N.
vksm.dlv.neveik.es.mot.dgs.V.
vksm.dlv.neveik.es.mot.dgs.Vt.
vksm.dlv.neveik.es.mot.dgs.Įn.
vksm.dlv.neveik.es.mot.vns.G.
vksm.dlv.neveik.es.mot.vns.K.
vksm.dlv.neveik.es.mot.vns.N.
vksm.dlv.neveik.es.mot.vns.V.
vksm.dlv.neveik.es.mot.vns.Vt.
vksm.dlv.neveik.es.mot.vns.Įn.
vksm.dlv.neveik.es.vyr.dgs.G.
vksm.dlv.neveik.es.vyr.dgs.K.
vksm.dlv.neveik.es.vyr.dgs.N.
vksm.dlv.neveik.es.vyr.dgs.V.
vksm.dlv.neveik.es.vyr.dgs.Įn.
vksm.dlv.neveik.es.vyr.vns.G.
vksm.dlv.neveik.es.vyr.vns.K.
vksm.dlv.neveik.es.vyr.vns.N.
vksm.dlv.neveik.es.vyr.vns.V.
vksm.dlv.neveik.es.vyr.vns.Vt.
vksm.dlv.neveik.es.vyr.vns.Įn.
vksm.dlv.neveik.es.įvardž.mot.dgs.K.
vksm.dlv.neveik.es.įvardž.mot.dgs.Įn.
vksm.dlv.neveik.es.įvardž.mot.vns.G.
vksm.dlv.neveik.es.įvardž.mot.vns.K.
vksm.dlv.neveik.es.įvardž.mot.vns.V.
vksm.dlv.neveik.es.įvardž.mot.vns.Įn.
vksm.dlv.neveik.es.įvardž.vyr.dgs.K.
vksm.dlv.neveik.es.įvardž.vyr.dgs.Įn.
vksm.dlv.neveik.es.įvardž.vyr.vns.K.
vksm.dlv.neveik.es.įvardž.vyr.vns.V.
vksm.dlv.reik.bev.
vksm.dlv.reik.mot.dgs.K.
vksm.dlv.reik.mot.dgs.V.
vksm.dlv.reik.vyr.dgs.K.
vksm.dlv.reik.vyr.vns.Š.
vksm.dlv.sngr.neveik.būt.bev.
vksm.dlv.sngr.neveik.būt.mot.dgs.G.
vksm.dlv.sngr.neveik.būt.mot.dgs.K.
vksm.dlv.sngr.neveik.būt.mot.vns.G.
vksm.dlv.sngr.neveik.būt.mot.vns.Vt.
vksm.dlv.sngr.neveik.būt.vyr.dgs.G.
vksm.dlv.sngr.neveik.būt.vyr.vns.G.
vksm.dlv.sngr.neveik.būt.vyr.vns.V.
vksm.dlv.sngr.neveik.būt.vyr.vns.Įn.
vksm.dlv.sngr.neveik.es.bev.
vksm.dlv.sngr.neveik.es.mot.dgs.V.
vksm.dlv.sngr.neveik.es.vyr.dgs.Įn.
vksm.dlv.sngr.veik.būs.mot.dgs.V.
vksm.dlv.sngr.veik.būt-k.bev.
vksm.dlv.sngr.veik.būt-k.mot.dgs.G.
vksm.dlv.sngr.veik.būt-k.mot.dgs.K.
vksm.dlv.sngr.veik.būt-k.mot.dgs.V.
vksm.dlv.sngr.veik.būt-k.mot.vns.G.
vksm.dlv.sngr.veik.būt-k.mot.vns.K.
vksm.dlv.sngr.veik.būt-k.mot.vns.V.
vksm.dlv.sngr.veik.būt-k.vyr.dgs.G.
vksm.dlv.sngr.veik.būt-k.vyr.dgs.K.
vksm.dlv.sngr.veik.būt-k.vyr.dgs.V.
vksm.dlv.sngr.veik.būt-k.vyr.vns.G.
vksm.dlv.sngr.veik.būt-k.vyr.vns.K.
vksm.dlv.sngr.veik.būt-k.vyr.vns.V.
vksm.dlv.sngr.veik.būt-k.vyr.vns.Įn.
vksm.dlv.sngr.veik.būt-k.įvardž.vyr.dgs.K.
vksm.dlv.sngr.veik.es.mot.dgs.K.
vksm.dlv.sngr.veik.es.mot.dgs.V.
vksm.dlv.sngr.veik.es.mot.vns.G.
vksm.dlv.sngr.veik.es.mot.vns.K.
vksm.dlv.sngr.veik.es.mot.vns.V.
vksm.dlv.sngr.veik.es.vyr.dgs.G.
vksm.dlv.sngr.veik.es.vyr.dgs.K.
vksm.dlv.sngr.veik.es.vyr.dgs.V.
vksm.dlv.sngr.veik.es.vyr.vns.N.
vksm.dlv.sngr.veik.es.vyr.vns.V.
vksm.dlv.sngr.veik.es.vyr.vns.Vt.
vksm.dlv.sngr.veik.es.įvardž.mot.vns.V.
vksm.dlv.veik.būs.bev.
vksm.dlv.veik.būs.vyr.vns.V.
vksm.dlv.veik.būs.vyr.vns.Vt.
vksm.dlv.veik.būt-k.bev.
vksm.dlv.veik.būt-k.mot.dgs.G.
vksm.dlv.veik.būt-k.mot.dgs.K.
vksm.dlv.veik.būt-k.mot.dgs.V.
vksm.dlv.veik.būt-k.mot.dgs.Įn.
vksm.dlv.veik.būt-k.mot.vns.G.
vksm.dlv.veik.būt-k.mot.vns.K.
vksm.dlv.veik.būt-k.mot.vns.N.
vksm.dlv.veik.būt-k.mot.vns.V.
vksm.dlv.veik.būt-k.mot.vns.Įn.
vksm.dlv.veik.būt-k.vyr.dgs.G.
vksm.dlv.veik.būt-k.vyr.dgs.K.
vksm.dlv.veik.būt-k.vyr.dgs.N.
vksm.dlv.veik.būt-k.vyr.dgs.V.
vksm.dlv.veik.būt-k.vyr.dgs.Įn.
vksm.dlv.veik.būt-k.vyr.vns.G.
vksm.dlv.veik.būt-k.vyr.vns.K.
vksm.dlv.veik.būt-k.vyr.vns.N.
vksm.dlv.veik.būt-k.vyr.vns.V.
vksm.dlv.veik.būt-k.vyr.vns.Vt.
vksm.dlv.veik.būt-k.vyr.vns.Įn.
vksm.dlv.veik.būt-k.įvardž.vyr.dgs.K.
vksm.dlv.veik.būt-k.įvardž.vyr.dgs.V.
vksm.dlv.veik.būt-k.įvardž.vyr.vns.V.
vksm.dlv.veik.būt-k.įvardž.vyr.vns.Įn.
vksm.dlv.veik.es.mot.dgs.G.
vksm.dlv.veik.es.mot.dgs.K.
vksm.dlv.veik.es.mot.dgs.N.
vksm.dlv.veik.es.mot.dgs.V.
vksm.dlv.veik.es.mot.dgs.Įn.
vksm.dlv.veik.es.mot.vns.G.
vksm.dlv.veik.es.mot.vns.K.
vksm.dlv.veik.es.mot.vns.N.
vksm.dlv.veik.es.mot.vns.V.
vksm.dlv.veik.es.mot.vns.Vt.
vksm.dlv.veik.es.mot.vns.Įn.
vksm.dlv.veik.es.vyr.dgs.G.
vksm.dlv.veik.es.vyr.dgs.K.
vksm.dlv.veik.es.vyr.dgs.N.
vksm.dlv.veik.es.vyr.dgs.V.
vksm.dlv.veik.es.vyr.dgs.Vt.
vksm.dlv.veik.es.vyr.dgs.Įn.
vksm.dlv.veik.es.vyr.vns.G.
vksm.dlv.veik.es.vyr.vns.K.
vksm.dlv.veik.es.vyr.vns.V.
vksm.dlv.veik.es.vyr.vns.Vt.
vksm.dlv.veik.es.vyr.vns.Įn.
vksm.dlv.veik.es.įvardž.vyr.dgs.G.
vksm.pad.būt-k.
vksm.pad.es.
vksm.pad.neig.būt-k.
vksm.pad.neig.es.
vksm.pad.neig.sngr.būt-k.
vksm.pad.neig.sngr.es.
vksm.pad.sngr.būt-k.
vksm.pad.sngr.būt.
vksm.pad.sngr.es.
vksm.pusd.mot.dgs.
vksm.pusd.mot.vns.
vksm.pusd.neig.mot.dgs.
vksm.pusd.neig.mot.vns.
vksm.pusd.neig.sngr.vyr.vns.
vksm.pusd.neig.vyr.dgs.
vksm.pusd.neig.vyr.vns.
vksm.pusd.sngr.mot.vns.
vksm.pusd.sngr.vyr.dgs.
vksm.pusd.sngr.vyr.vns.
vksm.pusd.vyr.dgs.
vksm.pusd.vyr.vns.
įv.G.
įv.K.
įv.N.
įv.V.
įv.bev.
įv.dgs.G.
įv.dgs.K.
įv.dgs.N.
įv.dgs.V.
įv.dgs.Vt.
įv.dgs.Įn.
įv.dvisk.V.
įv.mot.G.
įv.mot.N.
įv.mot.V.
įv.mot.dgs.G.
įv.mot.dgs.K.
įv.mot.dgs.N.
įv.mot.dgs.V.
įv.mot.dgs.Vt.
įv.mot.dgs.Įn.
įv.mot.dvisk.V.
įv.mot.vns.G.
įv.mot.vns.K.
įv.mot.vns.N.
įv.mot.vns.V.
įv.mot.vns.Vt.
įv.mot.vns.Įn.
įv.vns.G.
įv.vns.K.
įv.vns.N.
įv.vns.V.
įv.vns.Vt.
įv.vns.Įn.
įv.vns.Š.
įv.vyr.G.
įv.vyr.K.
įv.vyr.N.
įv.vyr.V.
įv.vyr.dgs.G.
įv.vyr.dgs.K.
įv.vyr.dgs.N.
įv.vyr.dgs.V.
įv.vyr.dgs.Vt.
įv.vyr.dgs.Įn.
įv.vyr.dvisk.G.
įv.vyr.dvisk.K.
įv.vyr.dvisk.V.
įv.vyr.vns.G.
įv.vyr.vns.K.
įv.vyr.vns.N.
įv.vyr.vns.V.
įv.vyr.vns.Vt.
įv.vyr.vns.Įn.
įv.Įn.
įv.įvardž.mot.vns.V.
įv.įvardž.vyr.vns.V.
end_of_list
    ;
    my @list = split(/\r?\n/, $list);
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::LT::Jablonskis - Driver for the Jablonskis tagset of Lithuanian.

=head1 VERSION

version 3.016

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::LT::Jablonskis;
  my $driver = Lingua::Interset::Tagset::LT::Jablonskis->new();
  my $fs = $driver->decode('dkt.vyr.vns.V.');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('lt::jablonskis', 'dkt.vyr.vns.V.');

=head1 DESCRIPTION

Interset driver for the Jablonskis tagset for Lithuanian.

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
