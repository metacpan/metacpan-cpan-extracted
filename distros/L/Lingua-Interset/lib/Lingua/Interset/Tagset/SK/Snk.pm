# ABSTRACT: Driver for the tags of the Slovak National Corpus (Slovenský národný korpus)
# Copyright © 2014, 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::SK::Snk;
use strict;
use warnings;
our $VERSION = '3.005';

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
    return 'sk::snk';
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
            # noun / substantívum (slovo, ryba, ústav, muž)
            'S' => ['pos' => 'noun'],
            # adjective / adjektívum (milý, svieži, priateľkin, psí)
            'A' => ['pos' => 'adj'],
            # pronoun / pronominum (akýkoľvek, onen, jeho, kadiaľ)
            'P' => ['pos' => 'noun', 'prontype' => 'prs'], ###!!! nutno dole rozpracovat lépe!
            # numeral / numerále (jeden, dva, raz, sto, prvý, dvojmo)
            'N' => ['pos' => 'num'],
            # verb / verbum (klásť, čítať, vidieť, činiť)
            'V' => ['pos' => 'verb'],
            # participle / particípium (robiaci, sediaci, naložený, zohriaty)
            'G' => ['pos' => 'verb', 'verbform' => 'part'],
            # adverb / adverbium (prísne, milo, pravidelne, prázdno)
            'D' => ['pos' => 'adv'],
            # preposition / prepozícia (po, pre, na, do, cez, medzi)
            'E' => ['pos' => 'adp'],
            # conjunction / konjunkcia (a, ale, alebo, či, pretože, že)
            'O' => ['pos' => 'conj'],
            # particle / partikula (azda, nuž, bodaj, sotva, áno, nie)
            'T' => ['pos' => 'part'],
            # interjection / interjekcia (fíha, bác, bums, dokelu, ahoj, cveng, plesk)
            'J' => ['pos' => 'int'],
            # reflexive pronoun/particle / reflexívum (sa, si)
            'R' => ['pos' => 'noun', 'prontype' => 'prs', 'reflex' => 'yes'],
            # conditional morpheme / kondicionálová morféma (by)
            'Y' => ['pos' => 'verb', 'verbtype' => 'aux', 'mood' => 'cnd'],
            # abbreviation / abreviácie, značky (km, kg, atď., H2O, SND)
            'W' => ['abbr' => 'yes'],
            # punctuation / interpunkcia (., !, (, ), +)
            'Z' => ['pos' => 'punc'],
            # unidentifiable part of speech / neurčiteľný slovný druh (bielo(-čierny), New (York))
            ###!!! We could use 'hyph' => 'yes' but this class also contains completely different token types (New from New York).
            'Q' => ['hyph' => 'yes'],
            # non-word element / neslovný element (XXXX, -------)
            '#' => [],
            # citation in foreign language / citátový výraz (šaj pes dovakeras, take it easy!, náměstí)
            '%' => ['foreign' => 'yes'],
            # digit / číslica (8, 14000, 3 (razy))
            '0' => ['pos' => 'num', 'numform' => 'digit']
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''  => 'S',
                                                   '@' => { 'reflex' => { 'yes' => 'R',
                                                                          '@'      => 'P' }}}},
                       'adj'  => 'A',
                       'num'  => { 'numform' => { 'digit' => '0',
                                                  '@'     => 'N' }},
                       'verb' => { 'mood' => { 'cnd' => 'Y',
                                               '@'   => { 'verbform' => { 'part' => { 'tense' => { 'past' => 'V',
                                                                                                   '@'    => 'G' }},
                                                                          '@'    => 'V' }}}},
                       'adv'  => 'D',
                       'adp'  => 'E',
                       'conj' => 'O',
                       'part' => 'T',
                       'int'  => 'J',
                       'punc' => 'Z',
                       '@'    => { 'hyph' => { 'yes' => 'Q',
                                               '@'    => { 'abbr' => { 'yes' => 'W',
                                                                       '@'    => { 'foreign' => { 'yes' => '%' }}}}}}}
        }
    );
    # MORPHOLOGICAL PART OF SPEECH ####################
    # The main part of speech is defined mostly along syntactic criteria.
    # However, some words are used as a different part of speech than their morphological paradigm would suggest.
    # For instance, some nouns are inflected as adjectives. (Alternatively we could say that some adjectives are used as nouns.)
    $atoms{morphpos} = $self->create_simple_atom
    (
        'intfeature' => 'morphpos',
        # paradigm / paradigma
        'simple_decode_map' =>
        {
            # substantívna (chlap, žena, srdce; P: koľkátka, všetučko; N: nula, milión, státisíce, raz)
            'S' => 'noun',
            # adjektívna (hlavný, vedúci, Mastný, vstupné; A: pekný, cudzí; P: aký, ktorá, inakšie; N: jediný, prvý, dvojitý, mnohonásobný, obojaký)
            'A' => 'adj',
            # zámenná (ja, ty, my, vy, seba, sebe)
            'P' => 'pron',
            # číslovková (dva, dvaja, oba, obaja, obidva, tri, štyri)
            'N' => 'num',
            # príslovková (P: ako, kam, kde, kade, vtedy, začo; N: prvýkrát, sedemkrát, dvojmo, neraz, mnohorako)
            'D' => 'adv',
            # zmiešaná (kuli, gazdiná; A: otcov, matkin; P: on, ona, ono, kto, ten, môj, všetok, čo, žiaden; N: jeden, jedna, jedno)
            'F' => 'mix',
            # neúplná (kanoe, kupé; A: super, nanič, hoden, rád, rada; P: koľko, jeho, jej, ich; N: sto, tisíc, päť, šesť, dvanásť, dvoje)
            'U' => 'def'
        }
    );
    # GENDER / ROD ####################
    $atoms{gender} = $self->create_atom
    (
        'surfeature' => 'gender',
        'decode_map' =>
        {
            # mužský životný (hrdina, hlavný, Mastný)
            'm' => ['gender' => 'masc', 'animacy' => 'anim'],
            # mužský neživotný (strom, rýľ)
            'i' => ['gender' => 'masc', 'animacy' => 'inan'],
            # ženský (ulica, pani, vedúca)
            'f' => ['gender' => 'fem'],
            # stredný (mesto, vysvedčenie, dievča, mláďa)
            'n' => ['gender' => 'neut'],
            # všeobecný (ja, ty, my, vy, seba; V: vy ste prišli)
            'h' => [],
            # neurčený / neurčiteľný (V: (chlapi, ženy i deti) sa tešili)
            'o' => [],
        },
        'encode_map' =>
        {
            'gender' => { 'masc' => { 'animacy' => { 'anim' => 'm',
                                                     '@'    => 'i' }},
                          'fem'  => 'f',
                          'neut' => 'n',
                          '@'    => 'h' }
        }
    );
    # NUMBER / ČÍSLO ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            # jednotné (slovo, ryba, ústav, muž)
            's' => 'sing',
            # množné (slová, ryby, ústavy, muži, mužovia)
            'p' => 'plur'
        }
    );
    # CASE / PÁD ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            # nominatív (pán, vedúci, matka)
            '1' => 'nom',
            # genitív (pána, vedúceho, matky)
            '2' => 'gen',
            # datív (pánovi, vedúcemu, matke)
            '3' => 'dat',
            # akuzatív (pána, vedúceho, matku)
            '4' => 'acc',
            # vokatív (pane, mami, Táni, oci)
            '5' => 'voc',
            # lokál (pánovi, mame, mori)
            '6' => 'loc',
            # inštrumentál (pánom, vedúcim, matkou)
            '7' => 'ins'
        }
    );
    # DEGREE OF COMPARISON / STUPEŇ ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            # pozitív (vzácny, drahá, otcov; D: draho, vzácne)
            'x' => 'pos',
            # komparatív (vzácnejší, drahší, drevenejší; D: drahšie, vzácnejšie)
            'y' => 'cmp',
            # superlatív (najvzácnejší, najdrahší, najdrevenejší; D: najdrahšie, najvzácnejšie)
            'z' => 'sup'
        }
    );
    # AGGLUTINATION / AGLUTINOVANOSŤ ####################
    $atoms{agglutination} = $self->create_atom
    (
        'surfeature' => 'agglutination',
        'decode_map' =>
        {
            # aglutinované (preňho, naňho, oň, zaň, doň)
            'g' => ['adpostype' => 'preppron']
        },
        'encode_map' =>
        {
            'adpostype' => { 'preppron' => 'g' }
        }
    );
    # VERBAL FORM / SLOVESNÁ FORMA ####################
    $atoms{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            # infinitív (byť, hriať, volať, viesť, hovoriť)
            'I' => ['verbform' => 'inf'],
            # prézent indikatív (je, hreje, volá, vedie, hovorí)
            'K' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres'],
            # imperatív (buď, hrej, volajte, veďte, hovor)
            'M' => ['verbform' => 'fin', 'mood' => 'imp'],
            # prechodník (súc, hrejúc, volajúc, vedúc, hovoriac)
            'H' => ['verbform' => 'conv'],
            # l-ové príčastie (bol, hrialo, volali, viedla, hovorili)
            'L' => ['verbform' => 'part', 'tense' => 'past'],
            # futúrum (budem, budeš, bude, budeme, budete, budú, poletím, povedú)
            'B' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'fut']
        },
        'encode_map' =>
        {
            'verbform' => { 'inf'  => 'I',
                            'fin'  => { 'mood' => { 'imp' => 'M',
                                                    '@'   => { 'tense' => { 'fut' => 'B',
                                                                            '@'   => 'K' }}}},
                            'conv' => 'H',
                            'part' => 'L' }
        }
    );
    # ASPECT / VID ####################
    $atoms{aspect} = $self->create_atom
    (
        'surfeature' => 'aspect',
        'decode_map' =>
        {
            # dokonavý (zohrejem, zavolám, povieme)
            'd' => ['aspect' => 'perf'],
            # nedokonavý (budem hriať, volala som, bola by hovorila)
            'e' => ['aspect' => 'imp'],
            # obojvidové sloveso (aplikovať, počuť)
            'j' => ['aspect' => 'imp|perf']
        },
        'encode_map' =>
        {
            'aspect' => { 'imp'      => 'e',
                          'perf'     => 'd',
                          'imp|perf' => 'j' }
        }
    );
    # PERSON / OSOBA ####################
    $atoms{person} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            # prvá (som, sme, hrejme, volali sme, budem hovoriť)
            'a' => '1',
            # druhá (si, ste, hriali ste, volajte, budeš viesť, hovoril by si)
            'b' => '2',
            # tretia (je, sú, hrejú, volalo, povedie, hovoria)
            'c' => '3'
        }
    );
    # NEGATION / NEGÁCIA ####################
    $atoms{polarity} = $self->create_simple_atom
    (
        'intfeature' => 'polarity',
        'simple_decode_map' =>
        {
            # afirmácia (prichádzať, priateliť sa, rásť)
            '+' => 'pos',
            # negácia (nebyť, neprichádzať, nepriateliť sa, nebáť sa)
            '-' => 'neg'
        }
    );
    # PARTICIPLE TYPE (VOICE) / DRUH ####################
    $atoms{voice} = $self->create_simple_atom
    (
        'intfeature' => 'voice',
        'simple_decode_map' =>
        {
            # aktívne (pracujúci, visiaci, píšuci, platiaci)
            'k' => 'act',
            # pasívne (robený, kosený, obratý, zožatý)
            't' => 'pass'
        }
    );
    # PREPOSITION FORM / FORMA ####################
    $atoms{adpostype} = $self->create_simple_atom
    (
        'intfeature' => 'adpostype',
        'simple_decode_map' =>
        {
            # vokalizovaná (so, zo, odo, podo)
            'v' => 'voc',
            # nevokalizovaná (s, z, od, pod, prostredníctvom)
            'u' => 'prep'
        }
    );
    # CONDITIONALITY / KONDICIONÁLNOSŤ ####################
    # This feature marks conditional conjunctions and particles.
    $atoms{conditionality} = $self->create_simple_atom
    (
        'intfeature' => 'mood',
        'simple_decode_map' =>
        {
            # kondicionálnosť (O: aby, keby, čoby, žeby; T: kiežby, žeby)
            'Y' => 'cnd'
        }
    );
    # PROPER NAME / VLASTNÉ MENO ####################
    # Optional appendix to the tag.
    $atoms{proper} = $self->create_simple_atom
    (
        'intfeature' => 'nountype',
        'simple_decode_map' =>
        {
            # vlastné meno (Emil, Molnárová, Vysoké, Tatry, Slovenské (národné divadlo))
            ':r' => 'prop'
        }
    );
    # SPELLING ERROR / CHYBNÝ ZÁPIS ####################
    # Optional appendix to the tag.
    $atoms{typo} = $self->create_simple_atom
    (
        'intfeature' => 'typo',
        'simple_decode_map' =>
        {
            # chybný zápis (papeirníctvo, zhrzený)
            ':q' => 'yes'
        }
    );
    # MERGED ATOM TO DECODE ANY FEATURE VALUE ####################
    my @fatoms = map {$atoms{$_}} (qw(morphpos gender number case degree agglutination verbform aspect person polarity voice adpostype conditionality proper typo));
    $atoms{feature} = $self->create_merged_atom
    (
        'surfeature' => 'feature',
        'atoms'      => \@fatoms
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
    $fs->set_tagset('sk::snk');
    my ($pos, $features, $appendix);
    if($tag =~ m/^(.)([^:]*)(:.*)?$/)
    {
        $pos = $1;
        $features = $2;
        $appendix = $3;
        $appendix = '' if(!defined($appendix));
    }
    else
    {
        # We do not throw exceptions from Interset drivers but if we did, this would be a good occasion.
        $features = $tag;
    }
    my @features = split(//, $features);
    # Both appendices could be present.
    while($appendix =~ s/^(:.)//)
    {
        push(@features, $1);
    }
    my $atoms = $self->atoms();
    # Decode part of speech.
    $atoms->{pos}->decode_and_merge_hard($pos, $fs);
    # Decode feature values.
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
    if($fs->is_verb() && $fs->tense() eq 'past')
    {
        $fpos = 'VL';
    }
    my $features = $self->features_pos()->{$fpos};
    my @features = ($pos);
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
    my $tag = join('', @features);
    # Some tags have different forms than generated by the atoms.
    $tag =~ s/^([NP])Dh$/$1D/;
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Got this list from Johanka and cleaned it a bit There are 1457 tags.
# 1457
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
AAfp1x
AAfp1y
AAfp1z
AAfp2x
AAfp2y
AAfp2z
AAfp3x
AAfp3y
AAfp3z
AAfp4x
AAfp4y
AAfp4z
AAfp5x
AAfp5y
AAfp5z
AAfp6x
AAfp6y
AAfp6z
AAfp7x
AAfp7y
AAfp7z
AAfs1x
AAfs1y
AAfs1z
AAfs2x
AAfs2y
AAfs2z
AAfs3x
AAfs3y
AAfs3z
AAfs4x
AAfs4y
AAfs4z
AAfs5x
AAfs5y
AAfs5z
AAfs6x
AAfs6y
AAfs6z
AAfs7x
AAfs7y
AAfs7z
AAip1x
AAip1y
AAip1z
AAip2x
AAip2y
AAip2z
AAip3x
AAip3y
AAip3z
AAip4x
AAip4y
AAip4z
AAip5x
AAip5y
AAip5z
AAip6x
AAip6y
AAip6z
AAip7x
AAip7y
AAip7z
AAis1x
AAis1y
AAis1z
AAis2x
AAis2y
AAis2z
AAis3x
AAis3y
AAis3z
AAis4x
AAis4y
AAis4z
AAis5x
AAis5y
AAis5z
AAis6x
AAis6y
AAis6z
AAis7x
AAis7y
AAis7z
AAmp1x
AAmp1y
AAmp1z
AAmp2x
AAmp2y
AAmp2z
AAmp3x
AAmp3y
AAmp3z
AAmp4x
AAmp4y
AAmp4z
AAmp5x
AAmp5y
AAmp5z
AAmp6x
AAmp6y
AAmp6z
AAmp7x
AAmp7y
AAmp7z
AAms1x
AAms1y
AAms1z
AAms2x
AAms2y
AAms2z
AAms3x
AAms3y
AAms3z
AAms4x
AAms4y
AAms4z
AAms5x
AAms5y
AAms5z
AAms6x
AAms6y
AAms6z
AAms7x
AAms7y
AAms7z
AAnp1x
AAnp1y
AAnp1z
AAnp2x
AAnp2y
AAnp2z
AAnp3x
AAnp3y
AAnp3z
AAnp4x
AAnp4y
AAnp4z
AAnp5x
AAnp5y
AAnp5z
AAnp6x
AAnp6y
AAnp6z
AAnp7x
AAnp7y
AAnp7z
AAns1x
AAns1y
AAns1z
AAns2x
AAns2y
AAns2z
AAns3x
AAns3y
AAns3z
AAns4x
AAns4y
AAns4z
AAns5x
AAns5y
AAns5z
AAns6x
AAns6y
AAns6z
AAns7x
AAns7y
AAns7z
AFfp1x
AFfp2x
AFfp3x
AFfp4x
AFfp5x
AFfp6x
AFfp7x
AFfs1x
AFfs2x
AFfs3x
AFfs4x
AFfs5x
AFfs6x
AFfs7x
AFip1x
AFip2x
AFip3x
AFip4x
AFip5x
AFip6x
AFip7x
AFis1x
AFis2x
AFis3x
AFis4x
AFis5x
AFis6x
AFis7x
AFmp1x
AFmp2x
AFmp3x
AFmp4x
AFmp5x
AFmp6x
AFmp7x
AFms1x
AFms2x
AFms3x
AFms4x
AFms5x
AFms6x
AFms7x
AFnp1x
AFnp2x
AFnp3x
AFnp4x
AFnp5x
AFnp6x
AFnp7x
AFns1x
AFns2x
AFns3x
AFns4x
AFns5x
AFns6x
AFns7x
AUfp1x
AUfp1y
AUfp1z
AUfp2x
AUfp3x
AUfp4x
AUfp5x
AUfp6x
AUfp7x
AUfs1x
AUfs1y
AUfs1z
AUfs2x
AUfs3x
AUfs4x
AUfs5x
AUfs6x
AUfs7x
AUip1x
AUip1y
AUip1z
AUip2x
AUip3x
AUip4x
AUip5x
AUip6x
AUip7x
AUis1x
AUis1y
AUis1z
AUis2x
AUis3x
AUis4x
AUis5x
AUis6x
AUis7x
AUmp1x
AUmp1y
AUmp1z
AUmp2x
AUmp3x
AUmp4x
AUmp5x
AUmp6x
AUmp7x
AUms1x
AUms1y
AUms1z
AUms2x
AUms3x
AUms4x
AUms5x
AUms6x
AUms7x
AUnp1x
AUnp1y
AUnp1z
AUnp2x
AUnp3x
AUnp4x
AUnp5x
AUnp6x
AUnp7x
AUns1x
AUns1y
AUns1z
AUns2x
AUns3x
AUns4x
AUns5x
AUns6x
AUns7x
Dx
Dy
Dz
Eu1
Eu2
Eu3
Eu4
Eu6
Eu7
Ev2
Ev3
Ev4
Ev6
Ev7
Gkfp1x
Gkfp1y
Gkfp1z
Gkfp2x
Gkfp2y
Gkfp2z
Gkfp3x
Gkfp3y
Gkfp3z
Gkfp4x
Gkfp4y
Gkfp4z
Gkfp5x
Gkfp5y
Gkfp5z
Gkfp6x
Gkfp6y
Gkfp6z
Gkfp7x
Gkfp7y
Gkfp7z
Gkfs1x
Gkfs1y
Gkfs1z
Gkfs2x
Gkfs2y
Gkfs2z
Gkfs3x
Gkfs3y
Gkfs3z
Gkfs4x
Gkfs4y
Gkfs4z
Gkfs5x
Gkfs5y
Gkfs5z
Gkfs6x
Gkfs6y
Gkfs6z
Gkfs7x
Gkfs7y
Gkfs7z
Gkip1x
Gkip1y
Gkip1z
Gkip2x
Gkip2y
Gkip2z
Gkip3x
Gkip3y
Gkip3z
Gkip4x
Gkip4y
Gkip4z
Gkip5x
Gkip5y
Gkip5z
Gkip6x
Gkip6y
Gkip6z
Gkip7x
Gkip7y
Gkip7z
Gkis1x
Gkis1y
Gkis1z
Gkis2x
Gkis2y
Gkis2z
Gkis3x
Gkis3y
Gkis3z
Gkis4x
Gkis4y
Gkis4z
Gkis5x
Gkis5y
Gkis5z
Gkis6x
Gkis6y
Gkis6z
Gkis7x
Gkis7y
Gkis7z
Gkmp1x
Gkmp1y
Gkmp1z
Gkmp2x
Gkmp2y
Gkmp2z
Gkmp3x
Gkmp3y
Gkmp3z
Gkmp4x
Gkmp4y
Gkmp4z
Gkmp5x
Gkmp5y
Gkmp5z
Gkmp6x
Gkmp6y
Gkmp6z
Gkmp7x
Gkmp7y
Gkmp7z
Gkms1x
Gkms1y
Gkms1z
Gkms2x
Gkms2y
Gkms2z
Gkms3x
Gkms3y
Gkms3z
Gkms4x
Gkms4y
Gkms4z
Gkms5x
Gkms5y
Gkms5z
Gkms6x
Gkms6y
Gkms6z
Gkms7x
Gkms7y
Gkms7z
Gknp1x
Gknp1y
Gknp1z
Gknp2x
Gknp2y
Gknp2z
Gknp3x
Gknp3y
Gknp3z
Gknp4x
Gknp4y
Gknp4z
Gknp5x
Gknp5y
Gknp5z
Gknp6x
Gknp6y
Gknp6z
Gknp7x
Gknp7y
Gknp7z
Gkns1x
Gkns1y
Gkns1z
Gkns2x
Gkns2y
Gkns2z
Gkns3x
Gkns3y
Gkns3z
Gkns4x
Gkns4y
Gkns4z
Gkns5x
Gkns5y
Gkns5z
Gkns6x
Gkns6y
Gkns6z
Gkns7x
Gkns7y
Gkns7z
Gtfp1x
Gtfp1y
Gtfp1z
Gtfp2x
Gtfp2y
Gtfp2z
Gtfp3x
Gtfp3y
Gtfp3z
Gtfp4x
Gtfp4y
Gtfp4z
Gtfp5x
Gtfp5y
Gtfp5z
Gtfp6x
Gtfp6y
Gtfp6z
Gtfp7x
Gtfp7y
Gtfp7z
Gtfs1x
Gtfs1y
Gtfs1z
Gtfs2x
Gtfs2y
Gtfs2z
Gtfs3x
Gtfs3y
Gtfs3z
Gtfs4x
Gtfs4y
Gtfs4z
Gtfs5x
Gtfs5y
Gtfs5z
Gtfs6x
Gtfs6y
Gtfs6z
Gtfs7x
Gtfs7y
Gtfs7z
Gtip1x
Gtip1y
Gtip1z
Gtip2x
Gtip2y
Gtip2z
Gtip3x
Gtip3y
Gtip3z
Gtip4x
Gtip4y
Gtip4z
Gtip5x
Gtip5y
Gtip5z
Gtip6x
Gtip6y
Gtip6z
Gtip7x
Gtip7y
Gtip7z
Gtis1x
Gtis1y
Gtis1z
Gtis2x
Gtis2y
Gtis2z
Gtis3x
Gtis3y
Gtis3z
Gtis4x
Gtis4y
Gtis4z
Gtis5x
Gtis5y
Gtis5z
Gtis6x
Gtis6y
Gtis6z
Gtis7x
Gtis7y
Gtis7z
Gtmp1x
Gtmp1y
Gtmp1z
Gtmp2x
Gtmp2y
Gtmp2z
Gtmp3x
Gtmp3y
Gtmp3z
Gtmp4x
Gtmp4y
Gtmp4z
Gtmp5x
Gtmp5y
Gtmp5z
Gtmp6x
Gtmp6y
Gtmp6z
Gtmp7x
Gtmp7y
Gtmp7z
Gtms1x
Gtms1y
Gtms1z
Gtms2x
Gtms2y
Gtms2z
Gtms3x
Gtms3y
Gtms3z
Gtms4x
Gtms4y
Gtms4z
Gtms5x
Gtms5y
Gtms5z
Gtms6x
Gtms6y
Gtms6z
Gtms7x
Gtms7y
Gtms7z
Gtnp1x
Gtnp1y
Gtnp1z
Gtnp2x
Gtnp2y
Gtnp2z
Gtnp3x
Gtnp3y
Gtnp3z
Gtnp4x
Gtnp4y
Gtnp4z
Gtnp5x
Gtnp5y
Gtnp5z
Gtnp6x
Gtnp6y
Gtnp6z
Gtnp7x
Gtnp7y
Gtnp7z
Gtns1x
Gtns1y
Gtns1z
Gtns2x
Gtns2y
Gtns2z
Gtns3x
Gtns3y
Gtns3z
Gtns4x
Gtns4y
Gtns4z
Gtns5x
Gtns5y
Gtns5z
Gtns6x
Gtns6y
Gtns6z
Gtns7x
Gtns7y
Gtns7z
J
NAfp1
NAfp2
NAfp3
NAfp4
NAfp5
NAfp6
NAfp7
NAfs1
NAfs2
NAfs3
NAfs4
NAfs5
NAfs6
NAfs7
NAip1
NAip2
NAip3
NAip4
NAip5
NAip6
NAip7
NAis1
NAis2
NAis3
NAis4
NAis5
NAis6
NAis7
NAmp1
NAmp2
NAmp3
NAmp4
NAmp5
NAmp6
NAmp7
NAms1
NAms2
NAms3
NAms4
NAms5
NAms6
NAms7
NAnp1
NAnp2
NAnp3
NAnp4
NAnp5
NAnp6
NAnp7
NAns1
NAns2
NAns3
NAns4
NAns5
NAns6
NAns7
ND
NFfp1
NFfp2
NFfp3
NFfp4
NFfp5
NFfp6
NFfp7
NFfs1
NFfs2
NFfs3
NFfs4
NFfs5
NFfs6
NFfs7
NFip1
NFip2
NFip3
NFip4
NFip5
NFip6
NFip7
NFis1
NFis2
NFis3
NFis4
NFis5
NFis6
NFis7
NFmp1
NFmp2
NFmp3
NFmp4
NFmp5
NFmp6
NFmp7
NFms1
NFms2
NFms3
NFms4
NFms5
NFms6
NFms7
NFnp1
NFnp2
NFnp3
NFnp4
NFnp5
NFnp6
NFnp7
NFns1
NFns2
NFns3
NFns4
NFns5
NFns6
NFns7
NNfp1
NNfp2
NNfp3
NNfp4
NNfp5
NNfp6
NNfp7
NNip1
NNip2
NNip3
NNip4
NNip5
NNip6
NNip7
NNmp1
NNmp2
NNmp3
NNmp4
NNmp5
NNmp6
NNmp7
NNnp1
NNnp2
NNnp3
NNnp4
NNnp5
NNnp6
NNnp7
NSfp1
NSfp2
NSfp3
NSfp4
NSfp5
NSfp6
NSfp7
NSfs1
NSfs2
NSfs3
NSfs4
NSfs5
NSfs6
NSfs7
NSip1
NSip2
NSip3
NSip4
NSip5
NSip6
NSip7
NSis1
NSis2
NSis3
NSis4
NSis5
NSis6
NSis7
NUfp1
NUfp2
NUfp3
NUfp4
NUfp5
NUfp6
NUfp7
NUip1
NUip2
NUip3
NUip4
NUip5
NUip6
NUip7
NUis1
NUis2
NUis3
NUis4
NUis5
NUis6
NUis7
NUmp1
NUmp2
NUmp3
NUmp4
NUmp5
NUmp6
NUmp7
NUnp1
NUnp2
NUnp3
NUnp4
NUnp5
NUnp6
NUnp7
NUns1
NUns2
NUns3
NUns4
NUns5
NUns6
NUns7
O
OY
PAfp1
PAfp2
PAfp3
PAfp4
PAfp5
PAfp6
PAfp7
PAfs1
PAfs2
PAfs3
PAfs4
PAfs5
PAfs6
PAfs7
PAip1
PAip2
PAip3
PAip4
PAip5
PAip6
PAip7
PAis1
PAis2
PAis3
PAis4
PAis5
PAis6
PAis7
PAmp1
PAmp2
PAmp3
PAmp4
PAmp5
PAmp6
PAmp7
PAms1
PAms2
PAms3
PAms4
PAms5
PAms6
PAms7
PAnp1
PAnp2
PAnp3
PAnp4
PAnp5
PAnp6
PAnp7
PAns1
PAns2
PAns3
PAns4
PAns5
PAns6
PAns7
PD
PFfp1
PFfp2
PFfp3
PFfp4
PFfp5
PFfp6
PFfp7
PFfs1
PFfs2
PFfs3
PFfs4
PFfs5
PFfs6
PFfs7
PFip1
PFip2
PFip3
PFip4
PFip5
PFip6
PFip7
PFis1
PFis2
PFis2g
PFis3
PFis4
PFis4g
PFis5
PFis6
PFis7
PFmp1
PFmp2
PFmp3
PFmp4
PFmp5
PFmp6
PFmp7
PFms1
PFms2
PFms2g
PFms3
PFms4
PFms4g
PFms5
PFms6
PFms7
PFnp1
PFnp2
PFnp3
PFnp4
PFnp5
PFnp6
PFnp7
PFns1
PFns2
PFns2g
PFns3
PFns4
PFns4g
PFns5
PFns6
PFns7
PPhp1
PPhp2
PPhp3
PPhp4
PPhp5
PPhp6
PPhp7
PPhs1
PPhs2
PPhs3
PPhs4
PPhs5
PPhs6
PPhs7
PSfp1
PSfp2
PSfp3
PSfp4
PSfp5
PSfp6
PSfp7
PSfs1
PSfs2
PSfs3
PSfs4
PSfs5
PSfs6
PSfs7
PSns1
PSns2
PSns3
PSns4
PSns5
PSns6
PSns7
PUfp1
PUfp2
PUfp3
PUfp4
PUfp5
PUfp6
PUfp7
PUfs1
PUfs2
PUfs3
PUfs4
PUfs5
PUfs6
PUfs7
PUip1
PUip2
PUip3
PUip4
PUip5
PUip6
PUip7
PUis1
PUis2
PUis3
PUis4
PUis5
PUis6
PUis7
PUmp1
PUmp2
PUmp3
PUmp4
PUmp5
PUmp6
PUmp7
PUms1
PUms2
PUms3
PUms4
PUms5
PUms6
PUms7
PUnp1
PUnp2
PUnp3
PUnp4
PUnp5
PUnp6
PUnp7
PUns1
PUns2
PUns3
PUns4
PUns5
PUns6
PUns7
Q
R
SAfp1
SAfp2
SAfp3
SAfp4
SAfp5
SAfp6
SAfp7
SAfs1
SAfs2
SAfs3
SAfs4
SAfs5
SAfs6
SAfs7
SAip1
SAip2
SAip3
SAip4
SAip5
SAip6
SAip7
SAis1
SAis2
SAis3
SAis4
SAis5
SAis6
SAis7
SAmp1
SAmp2
SAmp3
SAmp4
SAmp5
SAmp6
SAmp7
SAms1
SAms2
SAms3
SAms4
SAms5
SAms6
SAms7
SAnp1
SAnp2
SAnp3
SAnp4
SAnp5
SAnp6
SAnp7
SAns1
SAns2
SAns3
SAns4
SAns5
SAns6
SAns7
SFfp1
SFfp2
SFfp3
SFfp4
SFfp5
SFfp6
SFfp7
SFfs1
SFfs2
SFfs3
SFfs4
SFfs5
SFfs6
SFfs7
SSfp1
SSfp2
SSfp3
SSfp4
SSfp5
SSfp6
SSfp7
SSfs1
SSfs2
SSfs3
SSfs4
SSfs5
SSfs6
SSfs7
SSip1
SSip2
SSip3
SSip4
SSip5
SSip6
SSip7
SSis1
SSis2
SSis3
SSis4
SSis5
SSis6
SSis7
SSmp1
SSmp2
SSmp3
SSmp4
SSmp5
SSmp6
SSmp7
SSms1
SSms2
SSms3
SSms4
SSms5
SSms6
SSms7
SSnp1
SSnp2
SSnp3
SSnp4
SSnp5
SSnp6
SSnp7
SSns1
SSns2
SSns3
SSns4
SSns5
SSns6
SSns7
SUfp1
SUfp2
SUfp3
SUfp4
SUfp5
SUfp6
SUfp7
SUfs1
SUfs2
SUfs3
SUfs4
SUfs5
SUfs6
SUfs7
SUip1
SUip2
SUip3
SUip4
SUip5
SUip6
SUip7
SUis1
SUis2
SUis3
SUis4
SUis5
SUis6
SUis7
SUmp1
SUmp2
SUmp3
SUmp4
SUmp5
SUmp6
SUmp7
SUms1
SUms2
SUms3
SUms4
SUms5
SUms6
SUms7
SUnp1
SUnp2
SUnp3
SUnp4
SUnp5
SUnp6
SUnp7
SUns1
SUns2
SUns3
SUns4
SUns5
SUns6
SUns7
T
TY
VBepa-
VBepa+
VBepb-
VBepb+
VBepc-
VBepc+
VBesa-
VBesa+
VBesb-
VBesb+
VBesc-
VBesc+
VBjpa-
VBjpa+
VBjpb-
VBjpb+
VBjpc-
VBjpc+
VBjsa-
VBjsa+
VBjsb-
VBjsb+
VBjsc-
VBjsc+
VHd-
VHd+
VHe-
VHe+
VHj-
VHj+
VId-
VId+
VIe-
VIe+
VIj-
VIj+
VKdpa-
VKdpa+
VKdpb-
VKdpb+
VKdpc-
VKdpc+
VKdsa-
VKdsa+
VKdsb-
VKdsb+
VKdsc-
VKdsc+
VKe-
VKepa-
VKepa+
VKepb-
VKepb+
VKepc-
VKepc+
VKesa-
VKesa+
VKesb-
VKesb+
VKesc-
VKesc+
VKjpa-
VKjpa+
VKjpb-
VKjpb+
VKjpc-
VKjpc+
VKjsa-
VKjsa+
VKjsb-
VKjsb+
VKjsc-
VKjsc+
VLdpah-
VLdpah+
VLdpbh-
VLdpbh+
VLdpcf-
VLdpcf+
VLdpci-
VLdpci+
VLdpcm-
VLdpcm+
VLdpcn-
VLdpcn+
VLdsaf-
VLdsaf+
VLdsai-
VLdsai+
VLdsam-
VLdsam+
VLdsan-
VLdsan+
VLdsbf-
VLdsbf+
VLdsbi-
VLdsbi+
VLdsbm-
VLdsbm+
VLdsbn-
VLdsbn+
VLdscf-
VLdscf+
VLdsci-
VLdsci+
VLdscm-
VLdscm+
VLdscn-
VLdscn+
VLepah-
VLepah+
VLepbh-
VLepbh+
VLepcf-
VLepcf+
VLepci-
VLepci+
VLepcm-
VLepcm+
VLepcn-
VLepcn+
VLesaf-
VLesaf+
VLesai-
VLesai+
VLesam-
VLesam+
VLesan-
VLesan+
VLesbf-
VLesbf+
VLesbi-
VLesbi+
VLesbm-
VLesbm+
VLesbn-
VLesbn+
VLescf-
VLescf+
VLesci-
VLesci+
VLescm-
VLescm+
VLescn-
VLescn+
VLjpah-
VLjpah+
VLjpbh-
VLjpbh+
VLjpcf-
VLjpcf+
VLjpci-
VLjpci+
VLjpcm-
VLjpcm+
VLjpcn-
VLjpcn+
VLjsaf-
VLjsaf+
VLjsai-
VLjsai+
VLjsam-
VLjsam+
VLjsan-
VLjsan+
VLjsbf-
VLjsbf+
VLjsbi-
VLjsbi+
VLjsbm-
VLjsbm+
VLjsbn-
VLjsbn+
VLjscf-
VLjscf+
VLjsci-
VLjsci+
VLjscm-
VLjscm+
VLjscn-
VLjscn+
VMdpa-
VMdpa+
VMdpb-
VMdpb+
VMdsb-
VMdsb+
VMepa-
VMepa+
VMepb-
VMepb+
VMesb-
VMesb+
VMjpa-
VMjpa+
VMjpb-
VMjpb+
VMjsb-
VMjsb+
W
Y
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

Lingua::Interset::Tagset::SK::Snk - Driver for the tags of the Slovak National Corpus (Slovenský národný korpus)

=head1 VERSION

version 3.005

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::SK::Snk;
  my $driver = Lingua::Interset::Tagset::SK::Snk->new();
  my $fs = $driver->decode('SSms1');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('sk::snk', 'SSms1');

=head1 DESCRIPTION

Interset driver for the tags of the Slovak National Corpus (Slovenský národný korpus).

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
