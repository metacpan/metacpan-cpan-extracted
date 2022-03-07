# ABSTRACT: Driver for the tagset of the (Prague) Tamil Dependency Treebank (TamilTB)
# Copyright © 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Copyright © 2011 Loganathan Ramasamy <ramasamy@ufal.mff.cuni.cz>
# Documentation at http://ufal.mff.cuni.cz/~ramasamy/tamiltb/0.1/morph_annotation.html

package Lingua::Interset::Tagset::TA::Tamiltb;
use strict;
use warnings;
our $VERSION = '3.015';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset';



has 'atoms' => ( isa => 'HashRef', is => 'ro', builder => '_create_atoms', lazy => 1 );
has 'features_pos' => ( isa => 'HashRef', is => 'ro', builder => '_create_features_pos', lazy => 1 );



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'ta::tamiltb';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # 1.+2. DETAILED PART OF SPEECH ####################
    $atoms{pos} = $self->create_atom
    (
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # AA: adverb, general (aka, inru, melum, anal, pinnar)
            'AA' => ['pos' => 'adv'],
            # CC: coordinating conjunction (marrum = and; allatu = or)
            'CC' => ['pos' => 'conj', 'conjtype' => 'coor'],
            # DD: determiner, general (inta, anta, intap, enta, antap)
            'DD' => ['pos' => 'adj', 'prontype' => 'prn'],
            # II: interjection, general (aha = aha)
            'II' => ['pos' => 'int'],
            # JJ: adjective, general (mattiya, oru, katanta, putiya, munnal)
            'JJ' => ['pos' => 'adj'],
            # Jd: participial adjective?
            'Jd' => ['pos' => 'adj', 'verbform' => 'part'],
            # NN: common noun (warkali = chair, peruwtu = bus)
            'NN' => ['pos' => 'noun', 'nountype' => 'com'],
            # NE: proper name (intiya, ilangkai, atimuka, pakistan, kirikket)
            'NE' => ['pos' => 'noun', 'nountype' => 'prop'],
            # NO: oblique noun (intiya, amerikka, tamilaka, carvateca, manila)
            # What does 'oblique' mean in this context?
            # Only one tag found in the corpus: NO--3SN--. Does it apply to location names only?
            'NO' => ['pos' => 'noun', 'nountype' => 'prop', 'other' => {'nountype' => 'oblique'}],
            # NP: participial noun (otiyaval = she who ran; utaviyavar = he/she who helped)
            'NP' => ['pos' => 'noun', 'verbform' => 'part'],
            # postposition
            'PP' => ['pos' => 'adp', 'adpostype' => 'post'],
            # QQ: quantifier, general (mika, mikap, mikac, atikam, atika)
            'QQ' => ['pos' => 'adj', 'prontype' => 'prn', 'numtype' => 'card'],
            # Rh: reflexive pronoun (tannaip, tanakku, tamakk, tanatu)
            'Rh' => ['pos' => 'noun', 'prontype' => 'prs', 'reflex' => 'yes'],
            # Ri: interrogative pronoun (yAr = who, evan = who he, etu = which, enna = what)
            'Ri' => ['pos' => 'noun', 'prontype' => 'int'],
            # Rp: personal pronoun (wAn = I, nIngkal = you, tAn = he/she, itu = it, wAm = we, avarkal = they, anaittum = they)
            'Rp' => ['pos' => 'noun', 'prontype' => 'prs'],
            # RB: general referential pronoun (yarum = anyone; etuvum = anything)
            'RB' => ['pos' => 'noun', 'prontype' => 'ind'],
            # RF: specific indefinite referential pronoun (yaro = someone; etuvo = something)
            # Not found in the corpus.
            'RF' => ['pos' => 'noun', 'prontype' => 'ind'],
            # RG: non-specific indefinite pronoun (yaravatu = someone, at least; etavatu = something, at least)
            # Not found in the corpus.
            'RG' => ['pos' => 'noun', 'prontype' => 'ind'],
            # Tb: comparative particle (kAttilum = than, vita = than)
            'Tb' => ['pos' => 'part', 'other' => {'parttype' => 'comp'}],
            # Tc: connective particle (um = also, and)
            'Tc' => ['pos' => 'part'],
            # Td: adjectival particle (??? - see also Jd, participial adjectives)
            # Td-D----A ... enra (17 occurrences)
            # Td-P----A ... enkira (3 occurrences)
            'Td' => ['pos' => 'part', 'verbform' => 'part', 'other' => {'parttype' => 'adj'}],
            # Te: interrogative particle (A)
            'Te' => ['pos' => 'part', 'other' => {'parttype' => 'int'}],
            # Tf: civility particle (um = may please: varavum = may you please come)
            'Tf' => ['pos' => 'part'],
            # Tg: particle, general (Ana, Aka, Akav, Akat, Akak)
            'Tg' => ['pos' => 'part'],
            # Tk: intensifier particle (E = very, indeed, itself)
            'Tk' => ['pos' => 'part', 'other' => {'parttype' => 'intens'}],
            # Tl: particle "Avatu" = "at least"
            'Tl' => ['pos' => 'part', 'other' => {'parttype' => 'atlst'}],
            # Tm: particle "mattum" = "only"
            'Tm' => ['pos' => 'part', 'other' => {'parttype' => 'only'}],
            # Tn: particle complementizing nouns (pati, mAtiri = manner, way; pOtu = when)
            'Tn' => ['pos' => 'part', 'other' => {'parttype' => 'noun'}],
            # To: particle of doubt or indefiniteness (O)
            'To' => ['pos' => 'part', 'other' => {'parttype' => 'doubt'}],
            # Tq: emphatic particle (tAn: rAmantAn = it was Ram)
            'Tq' => ['pos' => 'part', 'other' => {'parttype' => 'emph'}],
            # Ts: concessive particle (um: Otiyum = although ran; utavinAlum = even if helps)
            'Ts' => ['pos' => 'part', 'other' => {'parttype' => 'conc'}],
            # Tt-T----A: verbal partic(ip?)le (enru, ena, enr, enat, enak, enav)
            # See also Vt? I am adding a non-empty verbform just to make sure that tense will be output as 'T', not as '-'.
            'Tt' => ['pos' => 'part', 'other' => {'parttype' => 'verb'}, 'verbform' => 'inf'],
            # Tv: inclusive particle (um = also: rAmanum = also Raman)
            'Tv' => ['pos' => 'part', 'other' => {'parttype' => 'incl'}],
            # Tw-T----A: conditional verbal particle (enrAl)
            # See also Vw?
            'Tw' => ['pos' => 'part', 'verbform' => 'fin', 'mood' => 'cnd', 'other' => {'parttype' => 'cnd'}],
            # Tz: verbal noun particle (enpatu, etuppat, kotuppat)
            # See also Vz?
            'Tz' => ['pos' => 'part', 'verbform' => 'ger', 'other' => {'parttype' => 'ger'}],
            # TS: immediacy particle (um: vawtatum = as soon as came; otiyatum = as soon as ran)
            'TS' => ['pos' => 'part', 'other' => {'parttype' => 'imm'}],
            # U=: number expressed using digits
            'U=' => ['pos' => 'num', 'numform' => 'digit'],
            # Ux: cardinal number (iru, ayiram, munru, latcam, irantu)
            'Ux' => ['pos' => 'num', 'numtype' => 'card'],
            # Uy: ordinal number (mutal, irantavatu, 1992-m, 1-m, 21-m)
            'Uy' => ['pos' => 'adj', 'numtype' => 'ord'],
            # Vj: lexical verb, imperative (irungkal; Otu = run, utavu = help)
            'Vj' => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'imp'],
            # Vr: lexical verb, finite form (terikiratu, terivikkiratu, irukkiratu, kUrukiratu, nilavukiratu)
            'Vr' => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'ind'],
            # Vt: lexical verb, verbal participle (vawtu = having come; Oti = having run; utavi = having helped)
            'Vt' => ['pos' => 'verb', 'verbform' => 'part'],
            # Vu: lexical verb, infinitive (ceyyap, terivikkap, valangkap, ceyya, niyamikkap)
            'Vu' => ['pos' => 'verb', 'verbform' => 'inf'],
            # Vw: lexical verb, conditional (vawtal = if come; otinal = if ran; utavinal = if helped)
            'Vw' => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'cnd'],
            # Vz: lexical verb, verbal noun (uyirilappat, nampuvat, ceyalpatuvatark, povat, virippatu)
            # vawtatu = the thing that came; otiyatu = the thing that ran
            'Vz' => ['pos' => 'verb', 'verbform' => 'ger'],
            # VR: auxiliary verb, finite form (varukiratu, irukkiratu)
            'VR' => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'fin', 'mood' => 'ind'],
            # VT: auxiliary verb, verbal participle (kontu, vittu, vantu, kont, vant)
            'VT' => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'part'],
            # VU: auxiliary verb, infinitive (vitak, vitap, kolla, vita)
            'VU' => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'inf'],
            # VW: auxiliary verb, conditional (vittal, iruntal, vantal, vitil, vaittal)
            'VW' => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'fin', 'mood' => 'cnd'],
            # VZ: auxiliary verb, verbal noun (ullat, kollal, ullatu, varal)
            'VZ' => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'ger'],
            # unknown
            'XX' => [],
            # Z#: sentence-terminating punctuation.
            'Z#' => ['pos' => 'punc', 'punctype' => 'peri'],
            # Z:: commas and other punctuation
            'Z:' => ['pos' => 'punc', 'punctype' => 'comm']
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''  => { 'other/nountype' => { 'oblique' => 'NO',
                                                                                  '@'       => { 'case' => { ''  => 'NO',
                                                                                                             '@' => { 'nountype' => { 'prop' => 'NE',
                                                                                                                                      '@'    => { 'verbform' => { 'part' => 'NP',
                                                                                                                                                                  '@'    => 'NN' }}}}}}}},
                                                   '@' => { 'reflex' => { 'yes' => 'Rh',
                                                                          '@'      => { 'prontype' => { 'int' => 'Ri',
                                                                                                        'prs' => 'Rp',
                                                                                                        '@'   => 'RB' }}}}}},
                       'adj'  => { 'prontype' => { ''  => { 'numtype' => { 'card' => 'Ux',
                                                                           'ord'  => 'Uy',
                                                                           '@'    => { 'verbform' => { 'part' => 'Jd',
                                                                                                       '@'    => 'JJ' }}}},
                                                   '@' => { 'numtype' => { 'card' => 'QQ',
                                                                           '@'    => 'DD' }}}},
                       'num'  => { 'prontype' => { ''  => { 'numform' => { 'digit' => 'U=',
                                                                           '@'     => { 'numtype' => { 'ord' => 'Uy',
                                                                                                       '@'   => 'Ux' }}}},
                                                   '@' => 'QQ' }},
                       'verb' => { 'verbtype' => { 'aux' => { 'verbform' => { 'inf'   => 'VU',
                                                                              'ger'   => 'VZ',
                                                                              'part'  => 'VT',
                                                                              'trans' => 'VT',
                                                                              '@'     => { 'mood' => { 'cnd' => 'VW',
                                                                                                       '@'   => 'VR' }}}},
                                                   '@'   => { 'verbform' => { 'inf'   => 'Vu',
                                                                              'ger'   => 'Vz',
                                                                              'part'  => 'Vt',
                                                                              'trans' => 'Vt',
                                                                              '@'     => { 'mood' => { 'imp' => 'Vj',
                                                                                                       'cnd' => 'Vw',
                                                                                                       '@'   => 'Vr' }}}}}},
                       'adv'  => 'AA',
                       'adp'  => 'PP',
                       'conj' => 'CC',
                       'part' => { 'other/parttype' => { 'imm'    => 'TS',
                                                         'comp'   => 'Tb',
                                                         'adj'    => 'Td',
                                                         'int'    => 'Te',
                                                         'intens' => 'Tk',
                                                         'atlst'  => 'Tl',
                                                         'only'   => 'Tm',
                                                         'noun'   => 'Tn',
                                                         'doubt'  => 'To',
                                                         'emph'   => 'Tq',
                                                         'conc'   => 'Ts',
                                                         'verb'   => 'Tt',
                                                         'incl'   => 'Tv',
                                                         'cnd'    => 'Tw',
                                                         'ger'    => 'Tz',
                                                         '@'      => { 'verbform' => { 'inf'  => 'Tt',
                                                                                       'fin'  => 'Tw',
                                                                                       'ger'  => 'Tz',
                                                                                       'part' => 'Td',
                                                                                       '@'    => 'Tg' }}}},
                       'int'  => 'II',
                       'punc' => { 'punctype' => { 'peri' => 'Z#',
                                                   'excl' => 'Z#',
                                                   'qest' => 'Z#',
                                                   '@'    => 'Z:' }},
                       'sym'  => 'Z:',
                       '@'    => 'XX' }
        }
    );
    # 3. CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'A' => 'acc',
            'B' => 'ben',
            'C' => 'abl',
            'D' => 'dat',
            'I' => 'ins',
            'G' => 'gen',
            'L' => 'loc',
            'N' => 'nom',
            # sociative = comitative
            'S' => 'com'
        }
    );
    # 4. TENSE ####################
    $atoms{tense} = $self->create_atom
    (
        'surfeature' => 'tense',
        'decode_map' =>
        {
            'D' => ['tense' => 'past'],
            'P' => ['tense' => 'pres'],
            'F' => ['tense' => 'fut'],
            # tenseless form, e.g. the negative auxiliary "illai"
            # We cannot map it (bidirectionally) to the empty value because we do not want 'T' to appear in tags for non-verbs.
            'T' => []
        },
        'encode_map' =>
        {
            'tense' => { 'past' => 'D',
                         'pres' => 'P',
                         'fut'  => 'F',
                         '@'    => { 'verbform' => { ''  => '',
                                                     '@' => 'T' }}}
        }
    );
    # 5. PERSON ####################
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
    # 6. NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'S' => 'sing',
            'P' => 'plur'
        }
    );
    # 7. GENDER ####################
    $atoms{gender} = $self->create_atom
    (
        'surfeature' => 'gender',
        'decode_map' =>
        {
            'A' => ['gender' => 'com', 'animacy' => 'anim'],
            'I' => ['gender' => 'com', 'animacy' => 'inan'],
            'F' => ['gender' => 'fem'],
            'M' => ['gender' => 'masc'],
            'N' => ['gender' => 'neut'],
            'H' => ['gender' => 'com', 'polite' => 'form']
        },
        'encode_map' =>
        {
            'gender' => { 'masc' => 'M',
                          'fem'  => 'F',
                          'com'  => { 'polite' => { 'form' => 'H',
                                                    '@'   => { 'animacy' => { 'inan' => 'I',
                                                                              '@'    => 'A' }}}},
                          'neut' => 'N' }
        }
    );
    # 8. VOICE ####################
    $atoms{voice} = $self->create_simple_atom
    (
        'intfeature' => 'voice',
        'simple_decode_map' =>
        {
            'A' => 'act',
            # Only the passive auxiliary verb "patu" ("experience") is tagged with "P". All other verbs receive "A".
            'P' => 'pass'
        }
    );
    # 9. POLARITY ####################
    $atoms{polarity} = $self->create_simple_atom
    (
        'intfeature' => 'polarity',
        'simple_decode_map' =>
        {
            'A' => 'pos',
            'N' => 'neg'
        }
    );
    return \%atoms;
}



#------------------------------------------------------------------------------
# Creates the list of surface features (character positions) that can appear
# with particular parts of speech.
#------------------------------------------------------------------------------
sub _create_features_pos
{
    my $self = shift;
    my %features =
    (
        'A'  => ['morphpos', 'gender', 'number', 'case', 'degree'],
        'D'  => ['degree'],
        'E'  => ['adpostype', 'case'],
        'G'  => ['voice', 'gender', 'number', 'case', 'degree'],
        'N'  => ['morphpos', 'gender', 'number', 'case'],
        'O'  => ['conditionality'],
        'P'  => ['morphpos', 'gender', 'number', 'case', 'agglutination'],
        'S'  => ['morphpos', 'gender', 'number', 'case'],
        'T'  => ['conditionality'],
        'V'  => ['verbform', 'aspect', 'number', 'person', 'polarity'],
        'VL' => ['verbform', 'aspect', 'number', 'person', 'gender', 'polarity']
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
    $fs->set_tagset('ta::tamiltb');
    my $atoms = $self->atoms();
    my @chars = split(//, $tag);
    $atoms->{pos}->decode_and_merge_hard($chars[0].$chars[1], $fs);
    $atoms->{case}->decode_and_merge_hard($chars[2], $fs);
    $atoms->{tense}->decode_and_merge_hard($chars[3], $fs);
    $atoms->{person}->decode_and_merge_hard($chars[4], $fs);
    $atoms->{number}->decode_and_merge_hard($chars[5], $fs);
    $atoms->{gender}->decode_and_merge_hard($chars[6], $fs);
    $atoms->{voice}->decode_and_merge_hard($chars[7], $fs);
    $atoms->{polarity}->decode_and_merge_hard($chars[8], $fs);
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
    my $tag = $pos.'-------';
    my @tag = split(//, $tag);
    my @features = ('pos', 'subpos', 'case', 'tense', 'person', 'number', 'gender', 'voice', 'polarity');
    for(my $i = 2; $i<9; $i++)
    {
        my $atag = $atoms->{$features[$i]}->encode($fs);
        # If we got undef, there is something wrong with our encoding tables.
        if(!defined($atag))
        {
            print STDERR ("\n", $fs->as_string(), "\n");
            confess("Cannot encode '$features[$i]'");
        }
        if($atag ne '')
        {
            $tag[$i] = $atag;
        }
    }
    $tag = join('', @tag);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# The tags were collected from the corpus.
# 233 tags found.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
AA-------
CC-------
DD-------
JJ-------
Jd-D----A
Jd-F----A
Jd-P----A
Jd-T----A
Jd-T----N
NEA-3PA--
NEA-3PN--
NEA-3SH--
NEA-3SN--
NED-3PA--
NED-3PN--
NED-3SH--
NED-3SN--
NEG-3SH--
NEG-3SN--
NEI-3PA--
NEL-3PA--
NEL-3PN--
NEL-3SN--
NEN-3PA--
NEN-3SH--
NEN-3SN--
NNA-3PA--
NNA-3PN--
NNA-3SH--
NNA-3SN--
NND-3PA--
NND-3PN--
NND-3SH--
NND-3SN--
NNG-3PA--
NNG-3PN--
NNG-3SH--
NNG-3SN--
NNI-3PA--
NNI-3PN--
NNI-3SN--
NNL-3PA--
NNL-3PN--
NNL-3SH--
NNL-3SN--
NNN-3PA--
NNN-3PN--
NNN-3SH--
NNN-3SM--
NNN-3SN--
NNS-3SA--
NNS-3SN--
NO--3SN--
NPDF3PH-A
NPLF3PH-A
NPND3PH-A
NPND3SH-A
NPNF3PA-A
NPNF3PH-A
NPNF3SH-A
NPNP3SH-A
NPNT3SM-A
PP-------
QQ-------
RBA-3SA--
RBD-3SA--
RBN-3SA--
RBN-3SN--
RhA-1SA--
RhD-1SA--
RhD-3SA--
RhG-3PA--
RhG-3SA--
RiG-3SA--
RiN-3SA--
RiN-3SN--
RpA-1PA--
RpA-2SH--
RpA-3PA--
RpA-3PN--
RpA-3SN--
RpD-1SA--
RpD-2PA--
RpD-3PA--
RpD-3SH--
RpD-3SN--
RpG-1PA--
RpG-1SA--
RpG-2SH--
RpG-3PA--
RpG-3SH--
RpG-3SN--
RpI-1PA--
RpI-3PA--
RpL-3SN--
RpN-1PA--
RpN-1SA--
RpN-2PA--
RpN-2SH--
RpN-3PA--
RpN-3PN--
RpN-3SA--
RpN-3SH--
RpN-3SN--
TS-------
Tb-------
Td-D----A
Td-P----A
Te-------
Tg-------
Tk-------
Tl-------
Tm-------
Tn-------
To-------
Tq-------
Ts-------
Tt-T----A
Tv-------
Tw-T----A
TzAF3SN-A
TzIF3SN-A
TzNF3SN-A
U=-------
U=D-3SN-A
U=L-3SN-A
Ux-------
UxA-3SN-A
UxD-3SN-A
UxL-3SN--
UxL-3SN-A
UxN-3SH--
Uy-------
VR-D1SAAA
VR-D3PHAA
VR-D3PHPA
VR-D3PNAA
VR-D3PNPA
VR-D3SHAA
VR-D3SHPA
VR-D3SNAA
VR-D3SNPA
VR-F3PAAA
VR-F3PHPA
VR-F3SHAA
VR-F3SNAA
VR-F3SNPA
VR-P1PAAA
VR-P2PHAA
VR-P3PAAA
VR-P3PAPA
VR-P3PHAA
VR-P3PHPA
VR-P3PNAA
VR-P3PNPA
VR-P3SHAA
VR-P3SNAA
VR-P3SNPA
VR-T1PAAA
VR-T1SAAA
VR-T3PAAA
VR-T3PHAA
VR-T3PNAA
VR-T3SHAA
VR-T3SN-N
VR-T3SNAA
VT-T---AA
VT-T---PA
VU-T---AA
VU-T---PA
VW-T---AA
VW-T---PA
VZAF3SNAA
VZAT3SNAA
VZDD3SNAA
VZDD3SNPA
VZIT3SNAA
VZND3SNAA
VZND3SNPA
VZNF3SNAA
VZNT3SNAA
Vj-T2PAAA
Vr-D1P-AA
Vr-D1SAAA
Vr-D3PAAA
Vr-D3PHAA
Vr-D3PNAA
Vr-D3SHAA
Vr-D3SNAA
Vr-F1P-AA
Vr-F3PHAA
Vr-F3PNAA
Vr-F3SHAA
Vr-F3SNAA
Vr-P1P-AA
Vr-P1PAAA
Vr-P1SAAA
Vr-P2PAAA
Vr-P2PHAA
Vr-P3PHAA
Vr-P3PNAA
Vr-P3SHAA
Vr-P3SNAA
Vr-T1SAAA
Vr-T2SH-N
Vr-T3PNAA
Vr-T3SNAA
Vt-T----N
Vt-T---AA
Vu-T---AA
Vu-T---PA
Vw-T---AA
VzAD3SNAA
VzAF3SNAA
VzDD3SNAA
VzDF3SNAA
VzDF3SNPA
VzGD3SNAA
VzID3SNAA
VzIF3SNAA
VzIT3SNAA
VzLD3SNAA
VzLF3SNAA
VzLT3SNAA
VzND3PNAA
VzND3SNAA
VzND3SNPA
VzNF3SNAA
VzNP3SNAA
VzNT3SN-N
VzNT3SNAA
Z#-------
Z:-------
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

Lingua::Interset::Tagset::TA::Tamiltb - Driver for the tagset of the (Prague) Tamil Dependency Treebank (TamilTB)

=head1 VERSION

version 3.015

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::SK::Snk;
  my $driver = Lingua::Interset::Tagset::SK::Snk->new();
  my $fs = $driver->decode('SSms1');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('sk::snk', 'SSms1');

=head1 DESCRIPTION

Interset driver for the tags of the Slovak National Corpus (Slovenský národný korpus).

L<http://ufal.mff.cuni.cz/~ramasamy/tamiltb/0.1/morph_annotation.html>

=head1 AUTHORS

Dan Zeman <zeman@ufal.mff.cuni.cz>,
Loganathan Ramasamy <ramasamy@ufal.mff.cuni.cz>

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
