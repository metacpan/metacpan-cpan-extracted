# ABSTRACT: Driver for the Faroese tagset provided by Bjartensen.
# See also https://github.com/UniversalDependencies/docs/issues/336
# The corpus where this tagset is used can be downloaded from http://stava.fo/ ("Markað tekstasavn").
# The corpus originates at Føroyamálsdeildin (Department of the Faroese Language and Literature), Fróðskaparsetur Føroya (University of Faroe Islands),
# although I was not able to find it directly at their website (http://setur.fo/en/language-and-literature/department/).
# Copyright © 2016, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::FO::Setur;
use strict;
use warnings;
our $VERSION = '3.013';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset';



has 'atoms'       => ( isa => 'HashRef', is => 'ro', builder => '_create_atoms',       lazy => 1 );
has 'feature_map' => ( isa => 'HashRef', is => 'ro', builder => '_create_feature_map', lazy => 1 );



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'fo::setur';
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
            # substantiv / noun
            'S' => ['pos' => 'noun'],
            # adjective
            'A' => ['pos' => 'adj'],
            # pronomen / pronoun
            'P' => ['pos' => 'noun', 'prontype' => 'prn'],
            # numeral
            'N' => ['pos' => 'num'],
            # verb
            'V' => ['pos' => 'verb'],
            # adverb
            'D' => ['pos' => 'adv'],
            # conjunction
            'C' => ['pos' => 'conj'],
            # preposition
            'E' => ['pos' => 'adp'],
            # interjection
            'I' => ['pos' => 'int'],
            # foreign word
            'F' => ['foreign' => 'yes'],
            # unanalyzed word
            'X' => [],
            # abbreviation
            'T' => ['abbr' => 'yes']
        },
        'encode_map' =>
        {
            'abbr' => { 'yes' => 'T',
                        '@'    => { 'foreign' => { 'yes' => 'F',
                                                   '@'       => { 'pos' => { 'noun' => { 'prontype' => { ''  => 'S',
                                                                                                         '@' => 'P' }},
                                                                             'adj'  => 'A',
                                                                             'num'  => 'N',
                                                                             'verb' => 'V',
                                                                             'adv'  => 'D',
                                                                             'conj' => 'C',
                                                                             'adp'  => 'E',
                                                                             'int'  => 'I',
                                                                             '@'    => 'X' }}}}}
        }
    );
    # GENDER ####################
    $atoms{gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'M' => 'masc',
            'F' => 'fem',
            'N' => 'neut',
            'X' => ''
        },
        'encode_default' => 'X'
    );
    # NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'S' => 'sing',
            'P' => 'plur'
        },
        'encode_default' => 'X'
    );
    # CASE ####################
    # also used as valency feature of adverbs and prepositions; then N means "does not govern case"
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'N' => 'nom',
            'A' => 'acc',
            'D' => 'dat',
            'G' => 'gen'
        },
        'encode_default' => 'X'
    );
    # DEFINITENESS ####################
    $atoms{definiteness} = $self->create_simple_atom
    (
        'intfeature' => 'definite',
        'simple_decode_map' =>
        {
            # definite (i.e. with suffixed definite article)
            'A' => 'def'
        },
        'encode_default' => 'X'
    );
    # NAME TYPE ####################
    $atoms{nametype} = $self->create_atom
    (
        'surfeature' => 'nametype',
        'decode_map' =>
        {
            'P' => ['nountype' => 'prop', 'nametype' => 'prs'],
            'L' => ['nountype' => 'prop', 'nametype' => 'geo']
        },
        'encode_map' =>
        {
            'nametype' => { 'prs' => 'P',
                            'geo' => 'L',
                            '@'   => 'X' }
        }
    );
    # DEGREE OF COMPARISON ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'P' => 'pos',
            'C' => 'cmp',
            'S' => 'sup'
        },
        'encode_default' => 'X'
    );
    # DECLENSION OF ADJECTIVES ####################
    $atoms{declension} = $self->create_atom
    (
        'surfeature' => 'declension',
        'decode_map' =>
        {
            'S' => ['other' => {'declension' => 'strong'}],
            'W' => ['other' => {'declension' => 'weak'}],
            'I' => ['other' => {'declension' => 'indeclinable'}]
        },
        'encode_map' =>
        {
            'other/declension' => { 'indeclinable' => 'I',
                                    'strong'       => 'S',
                                    'weak'         => 'W',
                                    '@'            => 'S' }
        }
    );
    # PRONOUN TYPE ####################
    # 1st and 2nd person pronouns lack the pronoun type and have person instead of gender: P1SN ("eg" = "I") vs. PDMSN ("hesin", "tann")
    # 3rd person, possessive and interrogative pronouns have no prontype and the second character is gender. We insert '3' before decoding.
    # PMSN hann, hvør
    # PMSG hansara, sín, sínar, síni
    # PMSD honum, sínum, sær, hvørjum
    # PMSA hann, sín, sína, seg, hvønn
    # PMPN teir
    # PMPG teirra, síni
    # PMPD teimum, sínum, sær
    # PMPA teir, sínar, seg
    # PFSN hon, hvør
    # PFSG hennara, sína
    # PFSD henni, sær, hvør
    # PFSA hana, sína, seg, hvørja
    # PFPN tær, hvørjar
    # PFPG teirra
    # PFPD teimum, sínum, sær
    # PFPA tær, sínar, seg, hvørjar
    # PNSN tað, hvat
    # PNSG tess, síni, sítt
    # PNSD tí, sínum, sær
    # PNSA tað, sína, sítt, seg, hvat
    # PNPN tey, øll
    # PNPG teirra, síni
    # PNPD teimum, sínum, sær
    # PNPA tey, sínar, síni, seg
    $atoms{prontype} = $self->create_atom
    (
        'surfeature' => 'prontype',
        'decode_map' =>
        {
            'D' => ['prontype' => 'dem'],
            'I' => ['prontype' => 'ind'],
            '1' => ['prontype' => 'prs', 'person' => '1'],
            '2' => ['prontype' => 'prs', 'person' => '2'],
            '3' => ['prontype' => 'prs', 'person' => '3']
        },
        'encode_map' =>
        {
            'prontype' => { 'dem' => 'D',
                            'prs' => { 'person' => { '1' => '1',
                                                     '2' => '2',
                                                     '@' => '3' }},
                            '@'   => 'I' }
        }
    );
    # NUMERAL TYPE ####################
    $atoms{numtype} = $self->create_atom
    (
        'surfeature' => 'numtype',
        'decode_map' =>
        {
            'C' => ['numtype' => 'card'],
            'O' => ['numtype' => 'ord'],
            # there is a typo in the corpus with "triðju"
            '0' => ['numtype' => 'ord']
        },
        'encode_map' =>
        {
            'numtype' => { 'ord' => 'O',
                           '@'   => 'C' }
        }
    );
    # VERB FORM AND MOOD ####################
    $atoms{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            'I' => ['verbform' => 'inf'],
            'M' => ['verbform' => 'fin', 'mood' => 'imp'],
            'N' => ['verbform' => 'fin', 'mood' => 'ind'],
            'S' => ['verbform' => 'fin', 'mood' => 'sub'],
            'P' => ['verbform' => 'part', 'tense' => 'pres'],
            'A' => ['verbform' => 'part', 'tense' => 'past'],
            # this seems to be middle voice because the forms are infinitive + the suffix "-st"
            'E' => ['verbform' => 'fin', 'voice' => 'mid'],
            'e' => ['verbform' => 'inf', 'voice' => 'mid'] # our modification to distinguish middle/passive infinitive from finite forms
        },
        'encode_map' =>
        {
            'verbform' => { 'fin'  => { 'mood' => { 'imp' => 'M',
                                                    'sub' => 'S',
                                                    '@'   => { 'voice' => { 'mid'  => 'E',
                                                                            'pass' => 'E',
                                                                            '@'    => 'N' }}}},
                            'part' => { 'tense' => { 'pres' => 'P',
                                                     '@'    => 'A' }},
                            '@'    => { 'voice' => { 'mid'  => 'E',
                                                     'pass' => 'E',
                                                     '@'    => 'I' }}}
        }
    );
    # TENSE ####################
    $atoms{tense} = $self->create_simple_atom
    (
        'intfeature' => 'tense',
        'simple_decode_map' =>
        {
            'P' => 'pres',
            'A' => 'past'
        },
        'encode_default' => 'X'
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
        },
        'encode_default' => 'X'
    );
    # CONJUNCTION TYPE ####################
    $atoms{conjtype} = $self->create_atom
    (
        'surfeature' => 'conjtype',
        'decode_map' =>
        {
            'I' => ['conjtype' => 'sub', 'verbform' => 'inf'], # infinitive marker
            'R' => ['conjtype' => 'sub'] # relative conjunction
        },
        'encode_map' =>
        {
            'conjtype' => { 'sub' => { 'verbform' => { 'inf' => 'I',
                                                       '@'   => 'R' }},
                            '@'   => 'X' }
        }
    );
    return \%atoms;
}



#------------------------------------------------------------------------------
# Creates a map that tells for each surface part of speech which features are
# relevant and in what order they appear.
#------------------------------------------------------------------------------
sub _create_feature_map
{
    my $self = shift;
    my %features =
    (
        # Nouns with gender (i.e. they don't start SX) always have the first four features.
        # Then the definiteness is optional and the combinations may be empty or A, L, P, AL, AP.
        'S'  => ['pos', 'gender', 'number', 'case', 'definiteness', 'nametype'],
        # AI ... indeclinable noun, degree is skipped, rest after declension too
        'A'  => ['pos', 'degree', 'declension', 'gender', 'number', 'case'],
        'P'  => ['pos', 'prontype', 'gender', 'number', 'case'],
        'N'  => ['pos', 'numtype', 'gender', 'number', 'case'],
        # Imperatives do not have tense so we must insert it.
        'V'  => ['pos', 'verbform', 'tense', 'number', 'person'],
        'VA' => ['pos', 'verbform', 'gender', 'number', 'case'],
        'D'  => ['pos', 'degree', 'case'],
        'C'  => ['pos', 'conjtype'],
        'E'  => ['pos', 'case']
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
    $tag = 'AXI' if($tag eq 'AI');
    $tag =~ s/^D([ADGN])$/DX$1/;
    $tag =~ s/^P([12])/P${1}X/;
    $tag =~ s/^P([MFN])/P3$1/;
    $tag =~ s/^(S[MFN][SP][NGDA])([LP])$/${1}X${2}/;
    $tag =~ s/^SX([LP])$/SXXXX$1/;
    $tag =~ s/^VM/VMX/;
    # VE is middle voice infinitive while VEAP3 is middle voice indicative
    $tag =~ s/^VE$/Ve/;
    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset('fo::setur');
    my $atoms = $self->atoms();
    my $features = $self->feature_map();
    my @chars = split(//, $tag);
    $atoms->{pos}->decode_and_merge_hard($chars[0], $fs);
    my $fpos = $chars[0];
    $fpos = 'VA' if($chars[0] eq 'V' && $chars[1] eq 'A');
    my @features;
    @features = @{$features->{$fpos}} if(defined($features->{$fpos}));
    for(my $i = 1; $i<=$#features; $i++)
    {
        if(defined($features[$i]) && defined($chars[$i]))
        {
            # Tagset drivers normally do not throw exceptions because they should be able to digest any input.
            # However, if we know we expect a feature and we have not defined an atom to handle that feature,
            # then it is an error of our code, not of the input data.
            if(!defined($atoms->{$features[$i]}))
            {
                confess("There is no atom to handle the feature '$features[$i]'");
            }
            $atoms->{$features[$i]}->decode_and_merge_hard($chars[$i], $fs);
        }
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
    my $features = $self->feature_map();
    my $tag = $atoms->{pos}->encode($fs);
    my $fpos = $tag;
    $fpos = 'VA' if($fs->is_participle() && $fs->is_past());
    my @features;
    @features = @{$features->{$fpos}} if(defined($features->{$fpos}));
    for(my $i = 1; $i<=$#features; $i++)
    {
        if(defined($features[$i]))
        {
            # Tagset drivers normally do not throw exceptions because they should be able to digest any input.
            # However, if we know we expect a feature and we have not defined an atom to handle that feature,
            # then it is an error of our code, not of the input data.
            if(!defined($atoms->{$features[$i]}))
            {
                confess("There is no atom to handle the feature '$features[$i]'");
            }
            $tag .= $atoms->{$features[$i]}->encode($fs);
        }
        else
        {
            $tag .= 'X';
        }
    }
    $tag = 'AI' if($tag =~ m/^AX/);
    $tag = 'C' if($tag eq 'CX');
    $tag =~ s/^DX([ADGN])$/D$1/;
    $tag = 'NC' if($tag eq 'NCXXX'); ###!!! NC are numbers expressed by digits - should we reflect it somehow?
    $tag =~ s/^P([12])X/P$1/;
    $tag =~ s/^P3/P/;
    $tag =~ s/^(S[MFN][SP][NGDA])X([LP])$/${1}${2}/;
    $tag =~ s/^SX+([LP])$/SX$1/;
    $tag =~ s/^VMX([SP])/VM$1/;
    $tag =~ s/^VPP/VP/;
    $tag =~ s/^SX+$/SX/ or $tag =~ s/^X+$/X/ or $tag =~ s/X+$//;
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    # There is no tag for punctuation; instead, the punctuation symbol is
    # copied in the tag column. It thus does not make sense to include in the
    # tagset the symbols we have observed, because other symbols may appear
    # in new text.
    # ! " % & ' ( ) , - . / : ; ? « ­ ´ » ' "
    my $list = <<end_of_list
ACSFPA
ACSFPD
ACSFPN
ACSFSA
ACSFSD
ACSFSN
ACSMPA
ACSMPD
ACSMPN
ACSMSA
ACSMSD
ACSMSN
ACSNPA
ACSNPD
ACSNPN
ACSNSA
ACSNSD
ACSNSN
ACWFPA
ACWFPD
ACWFPN
ACWFSA
ACWFSD
ACWFSN
ACWMPD
ACWMPN
ACWMSA
ACWMSN
ACWNPA
ACWNPD
ACWNPN
ACWNSA
ACWNSN
AI
APSFPA
APSFPD
APSFPG
APSFPN
APSFSA
APSFSD
APSFSG
APSFSN
APSMPA
APSMPD
APSMPG
APSMPN
APSMSA
APSMSD
APSMSG
APSMSN
APSNPA
APSNPD
APSNPG
APSNPN
APSNSA
APSNSD
APSNSG
APSNSN
APWFPA
APWFPD
APWFPG
APWFPN
APWFSA
APWFSD
APWFSG
APWFSN
APWMPA
APWMPD
APWMPG
APWMPN
APWMSA
APWMSD
APWMSG
APWMSN
APWNPA
APWNPD
APWNPG
APWNPN
APWNSA
APWNSD
APWNSG
APWNSN
ASSFPA
ASSFPD
ASSFPN
ASSFSA
ASSFSD
ASSFSN
ASSMPA
ASSMPN
ASSMSA
ASSMSD
ASSMSN
ASSNPA
ASSNPD
ASSNPN
ASSNSA
ASSNSD
ASSNSN
ASWFPA
ASWFPD
ASWFPN
ASWFSA
ASWFSD
ASWFSN
ASWMPA
ASWMPN
ASWMSA
ASWMSD
ASWMSN
ASWNPA
ASWNPD
ASWNPN
ASWNSA
ASWNSD
ASWNSN
C
CI
CR
DA
DCA
DCD
DCN
DD
DG
DN
DSA
DSN
EA
ED
EG
EN
F
I
NC
NCFPA
NCFPD
NCFPN
NCFSA
NCFSN
NCMPA
NCMPD
NCMPG
NCMPN
NCMSA
NCMSN
NCNPA
NCNPD
NCNPN
NCNSA
NCNSD
NCNSN
NOFSA
NOFSD
NOFSG
NOFSN
NOMPD
NOMSA
NOMSD
NOMSG
NOMSN
NONPA
NONPD
NONSA
NONSD
NONSN
P1PA
P1PD
P1PG
P1PN
P1SA
P1SD
P1SG
P1SN
P2PA
P2PD
P2PG
P2PN
P2SA
P2SD
P2SG
P2SN
PDFPA
PDFPD
PDFPN
PDFSA
PDFSD
PDFSN
PDMPA
PDMPD
PDMPN
PDMSA
PDMSD
PDMSN
PDNPA
PDNPD
PDNPN
PDNSA
PDNSD
PDNSN
PFPA
PFPD
PFPG
PFPN
PFSA
PFSD
PFSG
PFSN
PIFPA
PIFPD
PIFPN
PIFSA
PIFSD
PIFSN
PIMPA
PIMPD
PIMPN
PIMSA
PIMSD
PIMSN
PINPA
PINPD
PINPN
PINSA
PINSD
PINSN
PMPA
PMPD
PMPG
PMPN
PMSA
PMSD
PMSG
PMSN
PNPA
PNPD
PNPG
PNPN
PNSA
PNSD
PNSG
PNSN
SFPA
SFPAA
SFPAL
SFPD
SFPDA
SFPDAL
SFPDL
SFPG
SFPGL
SFPN
SFPNA
SFPNL
SFSA
SFSAA
SFSAAL
SFSAL
SFSAP
SFSD
SFSDA
SFSDAL
SFSDL
SFSDP
SFSG
SFSGA
SFSGL
SFSGP
SFSN
SFSNA
SFSNAL
SFSNL
SFSNP
SMPA
SMPAA
SMPD
SMPDA
SMPDL
SMPG
SMPGA
SMPN
SMPNA
SMSA
SMSAA
SMSAL
SMSAP
SMSD
SMSDA
SMSDAL
SMSDAP
SMSDL
SMSDP
SMSG
SMSGA
SMSGL
SMSGP
SMSN
SMSNA
SMSNAP
SMSNL
SMSNP
SNPA
SNPAA
SNPD
SNPDA
SNPDL
SNPG
SNPGA
SNPN
SNPNA
SNPNL
SNSA
SNSAA
SNSAAL
SNSAL
SNSD
SNSDA
SNSDAL
SNSDL
SNSDP
SNSG
SNSGA
SNSGL
SNSN
SNSNA
SNSNAL
SNSNAP
SNSNL
SNSNP
SX
SXL
SXP
T
VA
VAFPA
VAFPD
VAFPN
VAFSA
VAFSD
VAFSN
VAMPA
VAMPD
VAMPN
VAMSA
VAMSD
VAMSN
VANPA
VANPD
VANPN
VANSA
VANSD
VANSN
VE
VEAP1
VEAP2
VEAP3
VEAS1
VEAS2
VEAS3
VEPP1
VEPP2
VEPP3
VEPS1
VEPS2
VEPS3
VI
VMP
VMS
VNAP1
VNAP2
VNAP3
VNAS1
VNAS2
VNAS3
VNPP1
VNPP2
VNPP3
VNPS1
VNPS2
VNPS3
VP
X
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

Lingua::Interset::Tagset::FO::Setur - Driver for the Faroese tagset provided by Bjartensen.

=head1 VERSION

version 3.013

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::FO::Setur;
  my $driver = Lingua::Interset::Tagset::FO::Setur->new();
  my $fs = $driver->decode('SMSN');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('fo::setur', 'SMSN');

=head1 DESCRIPTION

Interset driver for the Faroese tagset briefly described by Bjartensen in
L<https://github.com/UniversalDependencies/docs/issues/336>.
The corpus where this tagset is used can be downloaded from L<http://stava.fo/> (“Markað tekstasavn”).
The corpus originates at Føroyamálsdeildin (Department of the Faroese Language and Literature), Fróðskaparsetur Føroya (University of Faroe Islands),
although I was not able to find it directly at their website (L<http://setur.fo/en/language-and-literature/department/>).

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
