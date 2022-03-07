# ABSTRACT: Driver for the Swedish tagset of the Stockholm-Umeå Corpus.
# Copyright © 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::SV::Suc;
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
    return 'sv::suc';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for the surface features.
# http://spraakbanken.gu.se/parole/tags.phtml
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # 1. PART OF SPEECH ####################
    $atoms{pos} = $self->create_atom
    (
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # adverb / adverb
            # examples: inte, också, så, bara, nu
            'AB' => ['pos' => 'adv'],
            # determiner / determinerare
            # examples: en, ett, den, det, alla, några, inga, de
            'DT' => ['pos' => 'adj', 'prontype' => 'prn'],
            # interrogative/relative adverb / frågande/relativt adverb
            # example: när, där, hur, som, då
            'HA' => ['pos' => 'adv', 'prontype' => 'int|rel'],
            # interrogative/relative determiner / frågande/relativ determinerare
            # examples: vilken, vilket, vilka
            'HD' => ['pos' => 'adj', 'prontype' => 'int|rel'],
            # interrogative/relative pronoun / frågande/relativt pronomen
            # examples: som, vilken, vem, vilket, vad, vilka
            'HP' => ['pos' => 'noun', 'prontype' => 'int|rel'],
            # interrogative/relative possessive pronoun / frågande/relativt possesivt pronomen
            # example: vars
            'HS' => ['pos' => 'adj', 'prontype' => 'int|rel', 'poss' => 'yes'],
            # infinitive marker / infinitivmärke
            # example: att
            'IE' => ['pos' => 'part', 'verbform' => 'inf'], ###!!! what is the current standard about infinitive markers?
            # interjection / interjektion
            # example: jo, ja, nej
            'IN' => ['pos' => 'int'],
            # adjective / adjektiv
            # examples: stor, annan, själv, sådan, viss
            'JJ' => ['pos' => 'adj'],
            # coordinating conjunction / konjunktion
            # examples: och, eller, som, än, men
            'KN' => ['pos' => 'conj', 'conjtype' => 'coor'],
            # meaning separating punctuation / meningsskiljande interpunktion
            # examples: . ? : ! ...
            'MAD' => ['pos' => 'punc', 'punctype' => 'peri|qest|excl|colo'],
            # punctuation inside of sentence / interpunktion
            # examples: , - : * ;
            'MID' => ['pos' => 'punc', 'punctype' => 'comm|dash|semi'], # or 'colo'; but we do not want a conflict with 'MAD'
            # noun / substantiv
            # examples: år, arbete, barn, sätt, äktenskap
            'NN' => ['pos' => 'noun', 'nountype' => 'com'],
            # paired punctuation / interpunktion
            # examples: ' ( )
            'PAD' => ['pos' => 'punc', 'punctype' => 'quot|brck'],
            # participle / particip
            # examples: särskild, ökad, beredd, gift, oförändrad
            'PC' => ['pos' => 'verb', 'verbform' => 'part'],
            # particle / partikel
            # examples: ut, upp, in, till, med
            ###!!! Joakim currently converts the particles to adpositions because these are the Germanic verb particles.
            'PL' => ['pos' => 'part'],
            # proper name / egennamn
            # example: F, N, Liechtenstein, Danmark, DK
            'PM' => ['pos' => 'noun', 'nountype' => 'prop'],
            # pronoun / pronomen
            # examples: han, den, vi, det, denne, de, dessa
            'PN' => ['pos' => 'noun', 'prontype' => 'prn'],
            # preposition / preposition
            # examples: i, av, på, för, till
            'PP' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # possessive pronoun / possesivt pronomen
            # examples: min, din, sin, vår, er, mitt, ditt, sitt, vårt, ert, mina, dina, sina, våra
            'PS' => ['pos' => 'adj', 'prontype' => 'prs', 'poss' => 'yes'],
            # cardinal numeral / grundtal
            # examples: en, ett, två, tre, 1, 20, 2
            'RG' => ['pos' => 'num', 'numtype' => 'card'],
            # ordinal numeral / ordningstal
            # examples: första, andra, tredje, fjärde, femte
            'RO' => ['pos' => 'adj', 'numtype' => 'ord'],
            # subordinating conjunction / subjunktion
            # examples: att, om, innan, eftersom, medan
            'SN' => ['pos' => 'conj', 'conjtype' => 'sub'],
            # foreign word / utländskt ord
            # examples: companionship, vice, versa, family, capita
            'UO' => ['foreign' => 'yes'],
            # verb / verb
            # examples: vara, få, ha, bli, kunna
            'VB' => ['pos' => 'verb'],
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''    => { 'nountype' => { 'prop' => 'PM',
                                                                              '@'    => 'NN' }},
                                                   'int' => { 'poss' => { 'yes' => 'HS',
                                                                          '@'    => 'HP' }},
                                                   '@'   => { 'poss' => { 'yes' => 'PS',
                                                                          '@'    => 'PN' }}}},
                       'adj'  => { 'prontype' => { ''    => { 'verbform' => { 'part' => 'PC',
                                                                              '@'    => { 'numtype' => { 'ord' => 'RO',
                                                                                                         '@'   => 'JJ' }}}},
                                                   'int' => { 'poss' => { 'yes' => 'HS',
                                                                          '@'    => 'HD' }},
                                                   '@'   => { 'poss' => { 'yes' => 'PS',
                                                                          '@'    => 'DT' }}}},
                       'num'  => { 'numtype' => { 'ord' => 'RO',
                                                  '@'   => 'RG' }},
                       'verb' => { 'verbform' => { 'part' => 'PC',
                                                   '@'    => 'VB' }},
                       'adv'  => { 'prontype' => { 'int' => 'HA',
                                                   '@'   => 'AB' }},
                       'adp'  => 'PP',
                       'conj' => { 'verbform' => { 'inf' => 'IE',
                                                   '@'   => { 'conjtype' => { 'sub' => 'SN',
                                                                              '@'   => 'KN' }}}},
                       'part' => { 'verbform' => { 'inf' => 'IE',
                                                   '@'   => 'PL' }},
                       'int'  => 'IN',
                       'punc' => { 'punctype' => { 'peri' => 'MAD',
                                                   'qest' => 'MAD',
                                                   'excl' => 'MAD',
                                                   'colo' => 'MAD', # or MID
                                                   'comm' => 'MID',
                                                   'semi' => 'MID',
                                                   'dash' => 'MID',
                                                   'quot' => 'PAD',
                                                   'brck' => 'PAD',
                                                   '@'    => 'MID' }},
                       '@'    => 'UO' }
        }
    );
    # 2. DEGREE ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'POS' => 'pos',
            'KOM' => 'cmp',
            'SUV' => 'sup'
        }
    );
    # 3. GENDER ####################
    $atoms{gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'MAS' => 'masc',
            'UTR' => 'com',
            'NEU' => 'neut',
            'UTR/NEU' => ''
        }
    );
    # 4. NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'SIN' => 'sing',
            'PLU' => 'plur',
            'SIN/PLU' => ''
        }
    );
    # 5. CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'NOM' => 'nom',
            'GEN' => 'gen'
        }
    );
    # 6. SUBJECT / OBJECT FORM ####################
    $atoms{subjobj} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'SUB' => 'nom',
            'OBJ' => 'acc',
            'SUB/OBJ' => ''
        }
    );
    # 7. DEFINITENESS ####################
    $atoms{definite} = $self->create_simple_atom
    (
        'intfeature' => 'definite',
        'simple_decode_map' =>
        {
            'DEF' => 'def',
            'IND' => 'ind',
            'IND/DEF' => ''
        }
    );
    # 8. VERB FORM, MOOD, TENSE AND ASPECT ####################
    $atoms{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            # infinitive / infinitiv
            'INF' => ['verbform' => 'inf'],
            # perfect participle / particip perfekt
            'PRF' => ['verbform' => 'part', 'aspect' => 'perf', 'tense' => 'past'],
            # present indicative or present subjunctive or present participle / presens eller particip presens
            'PRS' => ['tense' => 'pres'],
            # past indicative or subjunctive / preteritum
            'PRT' => ['verbform' => 'fin', 'tense' => 'past'],
            # imperative / imperativ
            'IMP' => ['verbform' => 'fin', 'mood' => 'imp'],
            # subjunctive / konjunktiv
            'KON' => ['verbform' => 'fin', 'mood' => 'sub'],
            # supine / supinum
            'SUP' => ['verbform' => 'sup']
        },
        'encode_map' =>
        {
            'verbform' => { 'inf'  => 'INF',
                            'fin'  => { 'mood' => { 'ind' => { 'tense' => { 'pres' => 'PRS',
                                                                            'past' => 'PRT' }},
                                                    'sub' => { 'tense' => { 'pres' => 'KON|PRS',
                                                                            'past' => 'KON|PRT' }},
                                                    'imp' => 'IMP',
                                                    '@'   => { 'tense' => { 'pres' => 'PRS',
                                                                            'past' => 'PRT' }}}},
                            'sup'  => 'SUP',
                            'part' => { 'tense' => { 'pres' => 'PRS',
                                                     'past' => 'PRF' }},
                            '@'    => { 'tense' => { 'pres' => 'PRS' }}}
        }
    );
    # 9. VOICE ####################
    $atoms{voice} = $self->create_simple_atom
    (
        'intfeature' => 'voice',
        'simple_decode_map' =>
        {
            # E.g. verb preteritum aktiv
            # Example: hänvisade = referred
            'AKT' => 'act',
            # E.g. verb preteritum s-form
            # Example: tillfrågades = asked
            ###!!! How did we come to conclude that "s-form" means passive?
            ###!!! But Joakim also decodes it as passive.
            'SFO' => 'pass'
        }
    );
    # 10. FORM ####################
    $atoms{form} = $self->create_atom
    (
        'surfeature' => 'form',
        'decode_map' =>
        {
            # hyphenated prefix / sammansättningsform
            'SMS' => ['hyph' => 'yes'],
            # abbreviation / förkortning
            'AN' => ['abbr' => 'yes']
        },
        'encode_map' =>
        {
            'hyph' => { 'yes' => 'SMS',
                        '@'    => { 'abbr' => { 'yes' => 'AN' }}}
        }
    );
    # MERGED ATOM TO DECODE ANY FEATURE VALUE ####################
    my @fatoms = map {$atoms{$_}} (qw(pos degree gender number case subjobj definite verbform voice form));
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
        'NN' => ['gender', 'number', 'definite', 'case', 'form'],
        'PM' => ['case', 'form'],
        'JJ' => ['degree', 'gender', 'number', 'definite', 'case', 'form'],
        'PC' => ['verbform', 'gender', 'number', 'definite', 'case', 'form'],
        'DT' => ['gender', 'number', 'definite', 'form'],
        'HD' => ['gender', 'number', 'definite', 'form'],
        'PN' => ['gender', 'number', 'definite', 'subjobj', 'form'],
        'PS' => ['gender', 'number', 'definite', 'form'],
        'HP' => ['gender', 'number', 'definite', 'form'],
        'HS' => ['definite'],
        'RG' => ['gender', 'number', 'definite', 'case', 'form'],
        'RO' => ['gender', 'number', 'definite', 'case', 'form'],
        'VB' => ['verbform', 'tense', 'voice', 'form'],
        'AB' => ['degree', 'form'],
        'PP' => ['form'],
        'KN' => ['form'],
        'PL' => ['form']
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
    $fs->set_tagset('sv::suc');
    my $atoms = $self->atoms();
    my @features = split(/\|/, $tag);
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
    my $features = $self->features_pos()->{$pos};
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
    my $tag = join('|', @features);
    # A few tags have other forms than expected.
    $tag =~ s:HP\|UTR/NEU\|SIN/PLU\|IND/DEF:HP|-|-|-:;
    $tag =~ s:(JJ|NN|PC|PS)\|.*\|AN:$1|AN:;
    $tag =~ s:JJ\|POS\|UTR\|SIN/PLU\|IND/DEF\|SMS:JJ|POS|UTR|-|-|SMS:;
    $tag =~ s:NN\|UTR/NEU\|SIN/PLU\|IND/DEF$:NN|-|-|-|-:;
    $tag =~ s:NN\|UTR/NEU\|SIN/PLU\|IND/DEF\|SMS:NN|SMS:;
    $tag =~ s:NN\|(NEU|UTR)\|SIN/PLU\|IND/DEF$:NN|$1|-|-|-:;
    $tag =~ s:NN\|(NEU|UTR)\|SIN/PLU\|IND/DEF\|SMS:NN|$1|-|-|SMS:;
    $tag =~ s:(RG|RO)\|UTR/NEU\|SIN/PLU\|IND/DEF:$1:;
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# The source list is the tagset of the Swedish SUC corpus; see also the
# UD Swedish treebank.
# http://spraakbanken.gu.se/parole/tags.phtml
# total tags:
# 155
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
AB
AB|AN
AB|KOM
AB|POS
AB|SMS
AB|SUV
DT|MAS|SIN|DEF
DT|MAS|SIN|IND
DT|NEU|SIN|DEF
DT|NEU|SIN|IND
DT|NEU|SIN|IND/DEF
DT|UTR/NEU|PLU|DEF
DT|UTR/NEU|PLU|IND
DT|UTR/NEU|PLU|IND/DEF
DT|UTR/NEU|SIN/PLU|IND
DT|UTR/NEU|SIN|DEF
DT|UTR/NEU|SIN|IND
DT|UTR|SIN|DEF
DT|UTR|SIN|IND
DT|UTR|SIN|IND/DEF
HA
HD|NEU|SIN|IND
HD|UTR/NEU|PLU|IND
HD|UTR|SIN|IND
HP|-|-|-
HP|NEU|SIN|IND
HP|NEU|SIN|IND|SMS
HP|UTR/NEU|PLU|IND
HP|UTR|SIN|IND
HS|DEF
IE
IN
JJ|AN
JJ|KOM|UTR/NEU|SIN/PLU|IND/DEF|GEN
JJ|KOM|UTR/NEU|SIN/PLU|IND/DEF|NOM
JJ|KOM|UTR/NEU|SIN/PLU|IND/DEF|SMS
JJ|POS|MAS|SIN|DEF|GEN
JJ|POS|MAS|SIN|DEF|NOM
JJ|POS|NEU|SIN|IND/DEF|NOM
JJ|POS|NEU|SIN|IND|GEN
JJ|POS|NEU|SIN|IND|NOM
JJ|POS|UTR/NEU|PLU|IND/DEF|GEN
JJ|POS|UTR/NEU|PLU|IND/DEF|NOM
JJ|POS|UTR/NEU|PLU|IND|NOM
JJ|POS|UTR/NEU|SIN/PLU|IND|NOM
JJ|POS|UTR/NEU|SIN/PLU|IND/DEF|NOM
JJ|POS|UTR/NEU|SIN|DEF|GEN
JJ|POS|UTR/NEU|SIN|DEF|NOM
JJ|POS|UTR|-|-|SMS
JJ|POS|UTR|SIN|IND/DEF|NOM
JJ|POS|UTR|SIN|IND|GEN
JJ|POS|UTR|SIN|IND|NOM
JJ|SUV|MAS|SIN|DEF|GEN
JJ|SUV|MAS|SIN|DEF|NOM
JJ|SUV|UTR/NEU|PLU|DEF|NOM
JJ|SUV|UTR/NEU|PLU|IND|NOM
JJ|SUV|UTR/NEU|SIN/PLU|DEF|NOM
JJ|SUV|UTR/NEU|SIN/PLU|IND|NOM
KN
KN|AN
MAD
MID
NN|-|-|-|-
NN|AN
NN|NEU|-|-|-
NN|NEU|-|-|SMS
NN|NEU|PLU|DEF|GEN
NN|NEU|PLU|DEF|NOM
NN|NEU|PLU|IND|GEN
NN|NEU|PLU|IND|NOM
NN|NEU|SIN|DEF|GEN
NN|NEU|SIN|DEF|NOM
NN|NEU|SIN|IND|GEN
NN|NEU|SIN|IND|NOM
NN|SMS
NN|UTR|-|-|-
NN|UTR|-|-|SMS
NN|UTR|PLU|DEF|GEN
NN|UTR|PLU|DEF|NOM
NN|UTR|PLU|IND|GEN
NN|UTR|PLU|IND|NOM
NN|UTR|SIN|DEF|GEN
NN|UTR|SIN|DEF|NOM
NN|UTR|SIN|IND|GEN
NN|UTR|SIN|IND|NOM
PAD
PC|AN
PC|PRF|MAS|SIN|DEF|GEN
PC|PRF|MAS|SIN|DEF|NOM
PC|PRF|NEU|SIN|IND|NOM
PC|PRF|UTR/NEU|PLU|IND/DEF|GEN
PC|PRF|UTR/NEU|PLU|IND/DEF|NOM
PC|PRF|UTR/NEU|SIN|DEF|GEN
PC|PRF|UTR/NEU|SIN|DEF|NOM
PC|PRF|UTR|SIN|IND|GEN
PC|PRF|UTR|SIN|IND|NOM
PC|PRS|UTR/NEU|SIN/PLU|IND/DEF|GEN
PC|PRS|UTR/NEU|SIN/PLU|IND/DEF|NOM
PL
PL|SMS
PM
PM|GEN
PM|NOM
PM|SMS
PN|MAS|SIN|DEF|SUB/OBJ
PN|NEU|SIN|DEF|SUB/OBJ
PN|NEU|SIN|IND|SUB/OBJ
PN|UTR/NEU|PLU|DEF|OBJ
PN|UTR/NEU|PLU|DEF|SUB
PN|UTR/NEU|PLU|DEF|SUB/OBJ
PN|UTR/NEU|PLU|IND|SUB/OBJ
PN|UTR/NEU|SIN/PLU|DEF|OBJ
PN|UTR|PLU|DEF|OBJ
PN|UTR|PLU|DEF|SUB
PN|UTR|SIN|DEF|OBJ
PN|UTR|SIN|DEF|SUB
PN|UTR|SIN|DEF|SUB/OBJ
PN|UTR|SIN|IND|SUB
PN|UTR|SIN|IND|SUB/OBJ
PP
PP|AN
PS|AN
PS|NEU|SIN|DEF
PS|UTR/NEU|PLU|DEF
PS|UTR/NEU|SIN/PLU|DEF
PS|UTR|SIN|DEF
RG
RG|GEN
RG|MAS|SIN|DEF|NOM
RG|NEU|SIN|IND|NOM
RG|NOM
RG|SMS
RG|UTR/NEU|SIN|DEF|NOM
RG|UTR|SIN|IND|NOM
RO|MAS|SIN|IND/DEF|GEN
RO|MAS|SIN|IND/DEF|NOM
RO|GEN
RO|NOM
SN
UO
VB|AN
VB|IMP|AKT
VB|IMP|SFO
VB|INF|AKT
VB|INF|SFO
VB|KON|PRS|AKT
VB|KON|PRT|AKT
VB|KON|PRT|SFO
VB|PRS|AKT
VB|PRS|SFO
VB|PRT|AKT
VB|PRT|SFO
VB|SMS
VB|SUP|AKT
VB|SUP|SFO
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

Lingua::Interset::Tagset::SV::Suc - Driver for the Swedish tagset of the Stockholm-Umeå Corpus.

=head1 VERSION

version 3.015

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::SV::Suc;
  my $driver = Lingua::Interset::Tagset::SV::Suc->new();
  my $fs = $driver->decode('NN|NEU|SIN|IND|NOM');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('sv::suc', 'NN|NEU|SIN|IND|NOM');

=head1 DESCRIPTION

Interset driver for the Swedish tagset of the Stockholm-Umeå Corpus,
L<http://spraakbanken.gu.se/parole/tags.phtml>.

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
