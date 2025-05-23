# ABSTRACT: Driver for the Czech tagset of the Multext-EAST project.
# Copyright © 2009, 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::CS::Multext;
use strict;
use warnings;
our $VERSION = '3.016';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset::Multext';



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by
# '::multext'. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'cs::multext';
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
        'N' => ['pos', 'nountype', 'gender', 'number', 'case', undef, undef, 'animacy'], # definiteness and clitic not used in Czech
        'A' => ['pos', 'adjtype', 'degree', 'gender', 'number', 'case', undef, undef, 'animacy', 'adjform'], # definiteness and clitic not used in Czech
        'P' => ['pos', 'prontype', 'person', 'gender', 'number', 'case', 'possnumber', 'possgender', 'clitic', 'referent_type', 'syntactic_type', undef, 'animacy', 'clitic_s'],
        'M' => ['pos', 'numtype', 'gender', 'number', 'case', 'numform', undef, undef, 'numclass', 'animacy'],
        # The documentation lists only 11 features (including the initial 'V') for Czech verbs.
        # However, the data contains verb tags of up to 14 characters.
        # Most likely, the designers forgot to skip the empty values of definiteness, clitic and case.
        'V' => ['pos', 'verbtype', 'verbform', 'tense', 'person', 'number', 'gender', 'voice', 'polarity', undef, undef, undef, 'animacy', 'clitic_s'],
        'R' => ['pos', 'adverb_type', 'degree'],
        'S' => ['pos', 'adpostype', 'adposition_formation', 'case'],
        'C' => ['pos', 'conjtype', undef, undef, undef, undef, 'number', 'person'] # undefined formation, coord type, sub type and clitic
    );
    return \%features;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# cut -f3 < wfl-cs.tbl | sort -u | wc -l
# 1428
# The above is the count of tags that really appeared in Multext East corpus.
# I have extended the list with some tags that are good as well and I needed them.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
Afcfpa---c
Afcfpd---c
Afcfpg---c
Afcfpi---c
Afcfpl---c
Afcfpn---c
Afcfpv---c
Afcfsa---c
Afcfsd---c
Afcfsg---c
Afcfsi---c
Afcfsl---c
Afcfsn---c
Afcfsv---c
Afcmpa---c
Afcmpd---c
Afcmpg---c
Afcmpi---c
Afcmpl---c
Afcmpn--nc
Afcmpn--yc
Afcmpv--nc
Afcmpv--yc
Afcmsa--nc
Afcmsa--yc
Afcmsd---c
Afcmsg---c
Afcmsi---c
Afcmsl---c
Afcmsn---c
Afcmsv---c
Afcnpa---c
Afcnpd---c
Afcnpg---c
Afcnpi---c
Afcnpl---c
Afcnpn---c
Afcnpv---c
Afcnsa---c
Afcnsd---c
Afcnsg---c
Afcnsi---c
Afcnsl---c
Afcnsn---c
Afcnsv---c
Afp------c
Afpfdi---c
Afpfpa---c
Afpfpa---n
Afpfpd---c
Afpfpg---c
Afpfpi---c
Afpfpl---c
Afpfpn---c
Afpfpn---n
Afpfpv---c
Afpfsa---c
Afpfsa---n
Afpfsd---c
Afpfsg---c
Afpfsi---c
Afpfsl---c
Afpfsn---c
Afpfsn---n
Afpfsv---c
Afpmpa---c
Afpmpa---n
Afpmpd---c
Afpmpg---c
Afpmpi---c
Afpmpl---c
Afpmpn--nc
Afpmpn--nn
Afpmpn--yc
Afpmpn--yn
Afpmpv--nc
Afpmpv--yc
Afpmsa--nc
Afpmsa--nn
Afpmsa--yc
Afpmsa--yn
Afpmsd---c
Afpmsg---c
Afpmsi---c
Afpmsl---c
Afpmsn---c
Afpmsn---n
Afpmsv---c
Afpnpa---c
Afpnpa---n
Afpnpd---c
Afpnpg---c
Afpnpi---c
Afpnpl---c
Afpnpn---c
Afpnpn---n
Afpnpv---c
Afpnsa---c
Afpnsa---n
Afpnsd---c
Afpnsg---c
Afpnsi---c
Afpnsl---c
Afpnsn---c
Afpnsn---n
Afpnsv---c
Afsfpa---c
Afsfpd---c
Afsfpg---c
Afsfpi---c
Afsfpl---c
Afsfpn---c
Afsfpv---c
Afsfsa---c
Afsfsd---c
Afsfsg---c
Afsfsi---c
Afsfsl---c
Afsfsn---c
Afsfsv---c
Afsmpa---c
Afsmpd---c
Afsmpg---c
Afsmpi---c
Afsmpl---c
Afsmpn--nc
Afsmpn--yc
Afsmpv--nc
Afsmpv--yc
Afsmsa--nc
Afsmsa--yc
Afsmsd---c
Afsmsg---c
Afsmsi---c
Afsmsl---c
Afsmsn---c
Afsmsv---c
Afsnpa---c
Afsnpd---c
Afsnpg---c
Afsnpi---c
Afsnpl---c
Afsnpn---c
Afsnpv---c
Afsnsa---c
Afsnsd---c
Afsnsg---c
Afsnsi---c
Afsnsl---c
Afsnsn---c
Afsnsv---c
As-fpa
As-fpd
As-fpg
As-fpi
As-fpl
As-fpn
As-fpv
As-fsa
As-fsd
As-fsg
As-fsi
As-fsl
As-fsn
As-fsv
As-mpa
As-mpd
As-mpg
As-mpi
As-mpl
As-mpn--n
As-mpn--y
As-mpv--n
As-mpv--y
As-msa--n
As-msa--y
As-msd
As-msg
As-msi
As-msl
As-msn
As-msv
As-npa
As-npd
As-npg
As-npi
As-npl
As-npn
As-npv
As-nsa
As-nsd
As-nsg
As-nsi
As-nsl
As-nsn
As-nsv
Cc
Cs
Cs-----3
Cs----p1
Cs----p2
Cs----s1
Cs----s2
I
Mc---d--f
Mcfpal--2
Mcfpal--f
Mcfpnl--2
Mcfpnl--f
Mcfsal--1
Mcfsdl--1
Mcfsgl--1
Mcfsil--1
Mcfsil--i
Mcfsll--1
Mcfsnl--1
Mcmpal--2
Mcmpal--f
Mcmpnl--2
Mcmpnl--f
Mcmsal--1n
Mcmsal--1y
Mcmsal--in
Mcmsdl--1
Mcmsgl--1
Mcmsil--1
Mcmsll--1
Mcmsnl--1
Mcmsnl--i
Mcnpal--2
Mcnpal--f
Mcnpnl--2
Mcnpnl--f
Mcnsal--1
Mcnsal--d
Mcnsal--f
Mcnsal--i
Mcnsal--q
Mcnsal--r
Mcnsdl--1
Mcnsgl--1
Mcnsil--1
Mcns-l--1
Mcns-l--f
Mcns-l--i
Mcnsll--1
Mcnsnl--1
Mcnsnl--d
Mcnsnl--f
Mcnsnl--i
Mcnsnl--q
Mcnsnl--r
Mc-pal--3
Mc-pal--f
Mc-p-d--2
Mc-p-d--3
Mc-pdl--2
Mc-pdl--3
Mc-pdl--d
Mc-pdl--f
Mc-pdl--i
Mc-pgl--2
Mc-pgl--3
Mc-pgl--d
Mc-pgl--f
Mc-pgl--i
Mc-pil--2
Mc-pil--3
Mc-pil--d
Mc-pil--f
Mc-pil--i
Mc-p-l--f
Mc-pll--2
Mc-pll--3
Mc-pll--d
Mc-pll--f
Mc-pll--i
Mc-pnl--3
Mc-pnl--f
Mc-p-r--2
Mc-p-r--3
Mc---r--f
Mc-s-d--1
Mc-sil--f
Mc-sil--i
Mc-s-r--1
Mm---l--1
Mm---l--2
Mm---l--3
Mm---l--d
Mm---l--f
Mm---l--i
Mm---l--q
Mm---l--r
Mofpal--1
Mofpal--2
Mofpal--3
Mofpal--f
Mofpal--i
Mofpdl--1
Mofpdl--2
Mofpdl--3
Mofpdl--f
Mofpdl--i
Mofpgl--1
Mofpgl--2
Mofpgl--f
Mofpgl--i
Mofpil--2
Mofpil--f
Mofpll--1
Mofpll--2
Mofpll--f
Mofpll--i
Mofpnl--1
Mofpnl--2
Mofpnl--3
Mofpnl--f
Mofpnl--i
Mofsal--1
Mofsal--2
Mofsal--3
Mofsal--f
Mofsal--i
Mofsdl--1
Mofsdl--2
Mofsdl--3
Mofsdl--f
Mofsdl--i
Mofsgl--1
Mofsgl--2
Mofsgl--3
Mofsgl--f
Mofsgl--i
Mofsil--1
Mofsil--2
Mofsil--3
Mofsil--f
Mofsll--1
Mofsll--2
Mofsll--3
Mofsll--f
Mofsll--i
Mofsnl--1
Mofsnl--2
Mofsnl--3
Mofsnl--f
Mofsnl--i
Mompal--1
Mompal--2
Mompal--3
Mompal--f
Mompal--i
Mompdl--1
Mompdl--2
Mompdl--3
Mompdl--f
Mompdl--i
Mompgl--1
Mompgl--2
Mompgl--f
Mompgl--i
Mompil--2
Mompil--f
Mompll--1
Mompll--2
Mompll--f
Mompll--i
Mompnl--1n
Mompnl--1y
Mompnl--2n
Mompnl--2y
Mompnl--3n
Mompnl--3y
Mompnl--fn
Mompnl--fy
Mompnl--in
Mompnl--iy
Momsal--1n
Momsal--1y
Momsal--2n
Momsal--2y
Momsal--3n
Momsal--3y
Momsal--fn
Momsal--fy
Momsal--iy
Momsdl--2
Momsdl--3
Momsdl--f
Momsgl--1
Momsgl--2
Momsgl--3
Momsgl--f
Momsgl--i
Momsil--1
Momsil--2
Momsil--3
Momsil--f
Momsil--i
Momsll--1
Momsll--2
Momsll--3
Momsll--f
Momsll--i
Momsnl--1
Momsnl--2
Momsnl--3
Momsnl--f
Momsnl--i
Monpal--1
Monpal--2
Monpal--3
Monpal--f
Monpal--i
Monpdl--1
Monpdl--2
Monpdl--3
Monpdl--f
Monpdl--i
Monpgl--1
Monpgl--2
Monpgl--f
Monpgl--i
Monpil--2
Monpil--f
Monpll--1
Monpll--2
Monpll--f
Monpll--i
Monpnl--1
Monpnl--2
Monpnl--3
Monpnl--f
Monpnl--i
Monsal--1
Monsal--2
Monsal--3
Monsal--f
Monsal--i
Monsdl--2
Monsdl--3
Monsdl--f
Monsgl--1
Monsgl--2
Monsgl--3
Monsgl--f
Monsgl--i
Monsil--1
Monsil--2
Monsil--3
Monsil--f
Monsil--i
Monsll--1
Monsll--2
Monsll--3
Monsll--f
Monsll--i
Monsnl--1
Monsnl--2
Monsnl--3
Monsnl--f
Monsnl--i
Mo-p-r--2
Mo-p-r--3
Mo---r--f
Msfpal--2
Msfpal--f
Msfpal--i
Msfpdl--f
Msfpgl--1
Msfpgl--f
Msfpll--1
Msfpll--f
Msfpnl--2
Msfpnl--f
Msfpnl--i
Msfsal--2
Msfsal--f
Msfsdl--2
Msfsdl--f
Msfsgl--2
Msfsgl--f
Msfsil--2
Msfsil--f
Msfsll--2
Msfsll--f
Msfsnl--2
Msfsnl--f
Msmpal--2
Msmpal--i
Msmpal--f
Msmpdl--f
Msmpgl--1
Msmpll--1
Msmpnl--1y
Msmpnl--2n
Msmpnl--2y
Msmpnl--fn
Msmpnl--fy
Msmpnl--in
Msmsal--2n
Msmsal--fn
Msmsal--fy
Msmsal--in
Msmsal--iy
Msmsdl--i
Msmsgl--i
Msmsil--f
Msmsnl--1
Msmsnl--2
Msmsnl--f
Msmsnl--i
Msnpal--1
Msnpal--2
Msnpal--f
Msnpdl--f
Msnpgl--1
Msnpgl--f
Msnpll--1
Msnpll--f
Msnpnl--1
Msnpnl--f
Msnpnl--2
Msnsal--2
Msnsal--f
Msnsdl--i
Msnsil--f
Msnsnl--2
Msnsnl--f
Msnsnl--i
Ncf
Ncfdi
Ncfpa
Ncfpd
Ncfpg
Ncfpi
Ncfpl
Ncfpn
Ncfpv
Ncfs
Ncfsa
Ncfsd
Ncfsg
Ncfsi
Ncfsl
Ncfsn
Ncfsv
Ncm
Ncmp
Ncmpa
Ncmpd
Ncmpg
Ncmpi
Ncmpl
Ncmpn--n
Ncmpn--y
Ncmpv
Ncms
Ncmsa--n
Ncmsa--y
Ncmsd
Ncmsg
Ncmsi
Ncmsl
Ncmsn
Ncmsv
Ncn
Ncnpa
Ncnpd
Ncnpg
Ncnpi
Ncnpl
Ncnpn
Ncnpv
Ncns
Ncnsa
Ncnsd
Ncnsg
Ncnsi
Ncnsl
Ncnsn
Ncnsv
Nc-p
Nc-s
Npf
Npfpa
Npfpd
Npfpg
Npfpi
Npfpl
Npfpn
Npfpv
Npfs
Npfsa
Npfsd
Npfsg
Npfsi
Npfsl
Npfsn
Npfsv
Npmp
Npmpa
Npmpd
Npmpg
Npmpi
Npmpl
Npmpn--n
Npmpn--y
Npmpv
Npms
Npmsa--n
Npmsa--y
Npmsd
Npmsg
Npmsi
Npmsl
Npmsn
Npmsv
Npn
Npnpa
Npnpd
Npnpg
Npnpi
Npnpn
Npnpv
Npns
Npnsa
Npnsd
Npnsg
Npnsi
Npnsl
Npnsn
Npnsv
Np-s
Pd-fdi--n-a--n
Pd-fpa--n-a--n
Pd-fpd--n-a--n
Pd-fpg--n-a--n
Pd-fpi--n-a--n
Pd-fpl--n-a--n
Pd-fpn--n-a--n
Pd-fsa--n-a--n
Pd-fsd--n-a--n
Pd-fsg--n-a--n
Pd-fsi--n-a--n
Pd-fsl--n-a--n
Pd-fsn--n-a--n
Pd-mpa--n-a--n
Pd-mpd--n-a--n
Pd-mpg--n-a--n
Pd-mpi--n-a--n
Pd-mpl--n-a--n
Pd-mpn--n-a-nn
Pd-mpn--n-a-yn
Pd-msa--n-a-nn
Pd-msa--n-a-yn
Pd-msd--n-a--n
Pd-msg--n-a--n
Pd-msi--n-a--n
Pd-msl--n-a--n
Pd-msn--n-a--n
Pd-npa--n-a--n
Pd-npd--n-a--n
Pd-npg--n-a--n
Pd-npi--n-a--n
Pd-npl--n-a--n
Pd-npn--n-a--n
Pd-nsa--n-a--n
Pd-nsa--n-a--y
Pd-nsd--n-a--n
Pd-nsg--n-a--n
Pd-nsi--n-a--n
Pd-nsl--n-a--n
Pd-nsn--n-a--n
Pd-nsn--n-a--y
Pd2nsa--n-a--n
Pd2nsn--n-a--n
Pg-fdi--n-a--n
Pg-fpa--n-a--n
Pg-fpd--n-a--n
Pg-fpg--n-a--n
Pg-fpi--n-a--n
Pg-fpl--n-a--n
Pg-fpn--n-a--n
Pg-fsa--n-a--n
Pg-fsd--n-a--n
Pg-fsg--n-a--n
Pg-fsi--n-a--n
Pg-fsl--n-a--n
Pg-fsn--n-a--n
Pg-mpa--n-a--n
Pg-mpd--n-a--n
Pg-mpg--n-a--n
Pg-mpi--n-a--n
Pg-mpl--n-a--n
Pg-mpn--n-a-nn
Pg-mpn--n-a-yn
Pg-msa--n-a-nn
Pg-msa--n-a-yn
Pg-msd--n-a--n
Pg-msg--n-a--n
Pg-msi--n-a--n
Pg-msl--n-a--n
Pg-msn--n-a--n
Pg-ndi--n-a--n
Pg-npa--n-a--n
Pg-npd--n-a--n
Pg-npg--n-a--n
Pg-npi--n-a--n
Pg-npl--n-a--n
Pg-npn--n-a--n
Pg-nsa--n-a--n
Pg-nsd--n-a--n
Pg-nsg--n-a--n
Pg-nsi--n-a--n
Pg-nsl--n-a--n
Pg-nsn--n-a--n
Pi-fpa--n-a--n
Pi-fpd--n-a--n
Pi-fpg--n-a--n
Pi-fpi--n-a--n
Pi-fpl--n-a--n
Pi-fpn--n-a--n
Pi-fsa--n-a--n
Pi-fsd--n-a--n
Pi-fsg--n-a--n
Pi-fsi--n-a--n
Pi-fsl--n-a--n
Pi-fsn--n-a--n
Pi-mpa--n-a--n
Pi-mpd--n-a--n
Pi-mpg--n-a--n
Pi-mpi--n-a--n
Pi-mpl--n-a--n
Pi-mpn--n-a-nn
Pi-mpn--n-a-yn
Pi-msa--n-a-nn
Pi-msa--n-a-yn
Pi-msa--n-n--n
Pi-msd--n-a--n
Pi-msd--n-n--n
Pi-msg--n-a--n
Pi-msg--n-n--n
Pi-msi--n-a--n
Pi-msi--n-n--n
Pi-msl--n-a--n
Pi-msl--n-n--n
Pi-msn--n-a--n
Pi-msn--n-n--n
Pi-npa--n-a--n
Pi-npd--n-a--n
Pi-npg--n-a--n
Pi-npi--n-a--n
Pi-npl--n-a--n
Pi-npn--n-a--n
Pi-nsa--n-a--n
Pi-nsa--n-n--n
Pi-nsd--n-a--n
Pi-nsd--n-n--n
Pi-nsg--n-a--n
Pi-nsg--n-n--n
Pi-nsi--n-a--n
Pi-nsi--n-n--n
Pi-nsl--n-a--n
Pi-nsl--n-n--n
Pi-nsn--n-a--n
Pi-nsn--n-n--n
Pp1-pa--n-n--n
Pp1-pd--n-n--n
Pp1-pg--n-n--n
Pp1-pi--n-n--n
Pp1-pl--n-n--n
Pp1-pn--n-n--n
Pp1-sa--n-n--n
Pp1-sa--y-n--n
Pp1-sd--n-n--n
Pp1-sd--y-n--n
Pp1-sg--n-n--n
Pp1-sg--y-n--n
Pp1-si--n-n--n
Pp1-sl--n-n--n
Pp1-sn--n-n--n
Pp2-pa--n-n--n
Pp2-pd--n-n--n
Pp2-pg--n-n--n
Pp2-pi--n-n--n
Pp2-pl--n-n--n
Pp2-pn--n-n--n
Pp2-sa--n-n--n
Pp2-sa--y-n--n
Pp2-sd--n-n--n
Pp2-sd--y-n--n
Pp2-sg--n-n--n
Pp2-sg--y-n--n
Pp2-si--n-n--n
Pp2-sl--n-n--n
Pp2-sn--n-n--n
Pp2-sn--n-n--y
Pp3fpn--n-n--n
Pp3fsa--n-n--n
Pp3fsd--n-n--n
Pp3fsg--n-n--n
Pp3fsi--n-n--n
Pp3fsl--n-n--n
Pp3fsn--n-n--n
Pp3mpn--n-n-nn
Pp3mpn--n-n-yn
Pp3msa--n-n--n
Pp3msa--n-n-yn
Pp3msa--y-n--n
Pp3msd--n-n--n
Pp3msd--y-n--n
Pp3msg--n-n--n
Pp3msg--y-n--n
Pp3msi--n-n--n
Pp3msl--n-n--n
Pp3msn--n-n--n
Pp3npn--n-n--n
Pp3nsa--n-n--n
Pp3nsa--y-n--n
Pp3nsd--n-n--n
Pp3nsd--y-n--n
Pp3nsg--n-n--n
Pp3nsg--y-n--n
Pp3nsi--n-n--n
Pp3nsl--n-n--n
Pp3nsn--n-n--n
Pp3-pa--n-n--n
Pp3-pd--n-n--n
Pp3-pg--n-n--n
Pp3-pi--n-n--n
Pp3-pl--n-n--n
Pq-fpa--n-a--n
Pq-fpa--n-n--n
Pq-fpd--n-a--n
Pq-fpd--n-n--n
Pq-fpg--n-a--n
Pq-fpg--n-n--n
Pq-fpi--n-a--n
Pq-fpi--n-n--n
Pq-fpl--n-a--n
Pq-fpl--n-n--n
Pq-fpn--n-a--n
Pq-fpn--n-n--n
Pq-fsa--n-a--n
Pq-fsa--n-n--n
Pq-fsd--n-a--n
Pq-fsd--n-n--n
Pq-fsg--n-a--n
Pq-fsg--n-n--n
Pq-fsi--n-a--n
Pq-fsi--n-n--n
Pq-fsl--n-a--n
Pq-fsl--n-n--n
Pq-fsn--n-a--n
Pq-fsn--n-n--n
Pq-mpa--n-a--n
Pq-mpa--n-n--n
Pq-mpd--n-a--n
Pq-mpd--n-n--n
Pq-mpg--n-a--n
Pq-mpg--n-n--n
Pq-mpi--n-a--n
Pq-mpi--n-n--n
Pq-mpl--n-a--n
Pq-mpl--n-n--n
Pq-mpn--n-a-nn
Pq-mpn--n-a-yn
Pq-mpn--n-n-nn
Pq-mpn--n-n-yn
Pq-msa--n-a-nn
Pq-msa--n-a-yn
Pq-msa--n-n--n
Pq-msa--n-n-nn
Pq-msa--n-n-yn
Pq-msd--n-a--n
Pq-msd--n-n--n
Pq-msg--n-a--n
Pq-msg--n-n--n
Pq-msi--n-a--n
Pq-msi--n-n--n
Pq-msl--n-a--n
Pq-msl--n-n--n
Pq-msn--n-a--n
Pq-msn--n-n--n
Pq-npa--n-a--n
Pq-npa--n-n--n
Pq-npd--n-a--n
Pq-npd--n-n--n
Pq-npg--n-a--n
Pq-npg--n-n--n
Pq-npi--n-a--n
Pq-npi--n-n--n
Pq-npl--n-a--n
Pq-npl--n-n--n
Pq-npn--n-a--n
Pq-npn--n-n--n
Pq-nsa--n-a--n
Pq-nsa--n-n--n
Pq-nsd--n-a--n
Pq-nsd--n-n--n
Pq-nsg--n-a--n
Pq-nsg--n-n--n
Pq-nsi--n-a--n
Pq-nsi--n-n--n
Pq-nsl--n-a--n
Pq-nsl--n-n--n
Pq-nsn--n-a--n
Pq-nsn--n-n--n
Pr-fpa--n-a--n
Pr-fpa--n-n--n
Pr-fpd--n-a--n
Pr-fpd--n-n--n
Pr-fpg--n-a--n
Pr-fpg--n-n--n
Pr-fpi--n-a--n
Pr-fpi--n-n--n
Pr-fpl--n-a--n
Pr-fpl--n-n--n
Pr-fpn--n-a--n
Pr-fpn--n-n--n
Pr-fsa--n-a--n
Pr-fsa--n-n--n
Pr-fsasfn-a--n
Pr-fsd--n-a--n
Pr-fsd--n-n--n
Pr-fsg--n-a--n
Pr-fsg--n-n--n
Pr-fsi--n-a--n
Pr-fsi--n-n--n
Pr-fsl--n-a--n
Pr-fsl--n-n--n
Pr-fsn--n-a--n
Pr-fsn--n-n--n
Pr-fs-sfn-a--n
Pr-mpa--n-a--n
Pr-mpa--n-n--n
Pr-mpd--n-a--n
Pr-mpd--n-n--n
Pr-mpg--n-a--n
Pr-mpg--n-n--n
Pr-mpi--n-a--n
Pr-mpi--n-n--n
Pr-mpl--n-a--n
Pr-mpl--n-n--n
Pr-mpn--n-a-nn
Pr-mpn--n-a-yn
Pr-mpn--n-n-nn
Pr-mpn--n-n-yn
Pr-msa--n-a-nn
Pr-msa--n-a-yn
Pr-msa--n-n--n
Pr-msa--n-n-nn
Pr-msa--n-n-yn
Pr-msasfn-a-nn
Pr-msasfn-a-yn
Pr-msd--n-a--n
Pr-msd--n-n--n
Pr-msg--n-a--n
Pr-msg--n-n--n
Pr-msgsfn-a--n
Pr-msi--n-a--n
Pr-msi--n-n--n
Pr-msisfn-a--n
Pr-msl--n-a--n
Pr-msl--n-n--n
Pr-mslsfn-a--n
Pr-msn--n-a--n
Pr-msn--n-n--n
Pr------n-n--n
Pr-npa--n-a--n
Pr-npa--n-n--n
Pr-npd--n-a--n
Pr-npd--n-n--n
Pr-npg--n-a--n
Pr-npg--n-n--n
Pr-npi--n-a--n
Pr-npi--n-n--n
Pr-npl--n-a--n
Pr-npl--n-n--n
Pr-npn--n-a--n
Pr-npn--n-n--n
Pr-nsa--n-a--n
Pr-nsa--n-n--n
Pr-nsasfn-a--n
Pr-nsd--n-a--n
Pr-nsd--n-n--n
Pr-nsg--n-a--n
Pr-nsg--n-n--n
Pr-nsgsfn-a--n
Pr-nsi--n-a--n
Pr-nsi--n-n--n
Pr-nsisfn-a--n
Pr-nsl--n-a--n
Pr-nsl--n-n--n
Pr-nslsfn-a--n
Pr-nsn--n-a--n
Pr-nsn--n-n--n
Pr--pa--n-n--n
Pr--pasfn-a--n
Pr--pd--n-n--n
Pr--pdsfn-a--n
Pr--pg--n-n--n
Pr--pgsfn-a--n
Pr--pi--n-n--n
Pr--pl--n-n--n
Pr--plsfn-a--n
Pr----p-n-a--n
Pr--pnsfn-a--n
Pr----smn-a--n
Pr----snn-a--n
Ps1fdis-n-a--n
Ps1fpap-n-a--n
Ps1fpas-n-a--n
Ps1fpdp-n-a--n
Ps1fpds-n-a--n
Ps1fpgp-n-a--n
Ps1fpgs-n-a--n
Ps1fpip-n-a--n
Ps1fpis-n-a--n
Ps1fplp-n-a--n
Ps1fpls-n-a--n
Ps1fpnp-n-a--n
Ps1fpns-n-a--n
Ps1fsap-n-a--n
Ps1fsas-n-a--n
Ps1fsdp-n-a--n
Ps1fsds-n-a--n
Ps1fsgp-n-a--n
Ps1fsgs-n-a--n
Ps1fsip-n-a--n
Ps1fsis-n-a--n
Ps1fslp-n-a--n
Ps1fsls-n-a--n
Ps1fsnp-n-a--n
Ps1fsns-n-a--n
Ps1mpap-n-a--n
Ps1mpas-n-a--n
Ps1mpdp-n-a--n
Ps1mpds-n-a--n
Ps1mpgp-n-a--n
Ps1mpgs-n-a--n
Ps1mpip-n-a--n
Ps1mpis-n-a--n
Ps1mplp-n-a--n
Ps1mpls-n-a--n
Ps1mpnp-n-a-nn
Ps1mpnp-n-a-yn
Ps1mpns-n-a-nn
Ps1mpns-n-a-yn
Ps1msap-n-a-nn
Ps1msap-n-a-yn
Ps1msas-n-a-nn
Ps1msas-n-a-yn
Ps1msdp-n-a--n
Ps1msgp-n-a--n
Ps1msgs-n-a--n
Ps1msip-n-a--n
Ps1msis-n-a--n
Ps1mslp-n-a--n
Ps1msls-n-a--n
Ps1msnp-n-a--n
Ps1msns-n-a--n
Ps1npap-n-a--n
Ps1npas-n-a--n
Ps1npdp-n-a--n
Ps1npds-n-a--n
Ps1npgp-n-a--n
Ps1npgs-n-a--n
Ps1npip-n-a--n
Ps1npis-n-a--n
Ps1nplp-n-a--n
Ps1npls-n-a--n
Ps1npnp-n-a--n
Ps1npns-n-a--n
Ps1nsap-n-a--n
Ps1nsas-n-a--n
Ps1nsdp-n-a--n
Ps1nsgp-n-a--n
Ps1nsgs-n-a--n
Ps1nsip-n-a--n
Ps1nsis-n-a--n
Ps1nslp-n-a--n
Ps1nsls-n-a--n
Ps1nsnp-n-a--n
Ps1nsns-n-a--n
Ps2fpap-n-a--n
Ps2fpas-n-a--n
Ps2fpds-n-a--n
Ps2fpgp-n-a--n
Ps2fpip-n-a--n
Ps2fplp-n-a--n
Ps2fpnp-n-a--n
Ps2fpns-n-a--n
Ps2fsap-n-a--n
Ps2fsas-n-a--n
Ps2fsdp-n-a--n
Ps2fsds-n-a--n
Ps2fsgp-n-a--n
Ps2fsgs-n-a--n
Ps2fsip-n-a--n
Ps2fsis-n-a--n
Ps2fslp-n-a--n
Ps2fsls-n-a--n
Ps2fsnp-n-a--n
Ps2fsns-n-a--n
Ps2mpap-n-a--n
Ps2mpas-n-a--n
Ps2mpds-n-a--n
Ps2mpgp-n-a--n
Ps2mpip-n-a--n
Ps2mplp-n-a--n
Ps2mpnp-n-a-nn
Ps2mpnp-n-a-yn
Ps2mpns-n-a-nn
Ps2mpns-n-a-yn
Ps2msap-n-a-nn
Ps2msap-n-a-yn
Ps2msas-n-a-nn
Ps2msas-n-a-yn
Ps2msgp-n-a--n
Ps2msgs-n-a--n
Ps2msip-n-a--n
Ps2msis-n-a--n
Ps2mslp-n-a--n
Ps2msls-n-a--n
Ps2msnp-n-a--n
Ps2msns-n-a--n
Ps2npap-n-a--n
Ps2npas-n-a--n
Ps2npds-n-a--n
Ps2npgp-n-a--n
Ps2npip-n-a--n
Ps2nplp-n-a--n
Ps2npnp-n-a--n
Ps2npns-n-a--n
Ps2nsap-n-a--n
Ps2nsas-n-a--n
Ps2nsgp-n-a--n
Ps2nsgs-n-a--n
Ps2nsip-n-a--n
Ps2nsis-n-a--n
Ps2nslp-n-a--n
Ps2nsls-n-a--n
Ps2nsnp-n-a--n
Ps2nsns-n-a--n
Ps3fsasfn-a--n
Ps3fs-sfn-a--n
Ps3msasfn-a-nn
Ps3msasfn-a-yn
Ps3msdsfn-a--n
Ps3msgsfn-a--n
Ps3msisfn-a--n
Ps3mslsfn-a--n
Ps3msnsfn-a--n
Ps3nsasfn-a--n
Ps3nsdsfn-a--n
Ps3nsgsfn-a--n
Ps3nsisfn-a--n
Ps3nslsfn-a--n
Ps3nsnsfn-a--n
Ps3-pasfn-a--n
Ps3-pdsfn-a--n
Ps3-pgsfn-a--n
Ps3-pisfn-a--n
Ps3-plsfn-a--n
Ps3---p-n-a--n
Ps3-pnsfn-a--n
Ps3---smn-a--n
Ps3---snn-a--n
Px---a--npn--n
Px---a--ypn--n
Px---a--ypn--y
Px---d--npn--n
Px---d--ypn--n
Px---d--ypn--y
Px-fdi--nsa--n
Px-fpa--nsa--n
Px-fpd--nsa--n
Px-fpg--nsa--n
Px-fpi--nsa--n
Px-fpl--nsa--n
Px-fpn--nsa--n
Px-fsa--nsa--n
Px-fsd--nsa--n
Px-fsg--nsa--n
Px-fsi--nsa--n
Px-fsl--nsa--n
Px-fsn--nsa--n
Px---g--npn--n
Px---i--npn--n
Px---l--npn--n
Px-mpa--nsa--n
Px-mpd--nsa--n
Px-mpg--nsa--n
Px-mpi--nsa--n
Px-mpl--nsa--n
Px-mpn--nsa-nn
Px-mpn--nsa-yn
Px-msa--nsa-nn
Px-msa--nsa-yn
Px-msd--nsa--n
Px-msg--nsa--n
Px-msi--nsa--n
Px-msl--nsa--n
Px-msn--nsa--n
Px-npa--nsa--n
Px-npd--nsa--n
Px-npg--nsa--n
Px-npi--nsa--n
Px-npl--nsa--n
Px-npn--nsa--n
Px-nsa--nsa--n
Px-nsd--nsa--n
Px-nsg--nsa--n
Px-nsi--nsa--n
Px-nsl--nsa--n
Px-nsn--nsa--n
Px2--a--ypn--n
Px2--d--ypn--n
Pz-fpa--n-a--n
Pz-fpd--n-a--n
Pz-fpd--n-n--n
Pz-fpg--n-n--n
Pz-fpi--n-n--n
Pz-fpl--n-n--n
Pz-fpn--n-a--n
Pz-fsa--n-a--n
Pz-fsd--n-a--n
Pz-fsg--n-a--n
Pz-fsi--n-a--n
Pz-fsl--n-a--n
Pz-fsn--n-a--n
Pz-mpa--n-a--n
Pz-mpd--n-a--n
Pz-mpd--n-n--n
Pz-mpg--n-n--n
Pz-mpi--n-n--n
Pz-mpl--n-n--n
Pz-mpn--n-a-nn
Pz-mpn--n-a-yn
Pz-msa--n-a-nn
Pz-msa--n-a-yn
Pz-msa--n-n--n
Pz-msd--n-a--n
Pz-msd--n-n--n
Pz-msg--n-a--n
Pz-msg--n-n--n
Pz-msi--n-a--n
Pz-msi--n-n--n
Pz-msl--n-a--n
Pz-msl--n-n--n
Pz-msn--n-a--n
Pz-msn--n-n--n
Pz-npa--n-a--n
Pz-npd--n-a--n
Pz-npd--n-n--n
Pz-npg--n-n--n
Pz-npi--n-n--n
Pz-npl--n-n--n
Pz-npn--n-a--n
Pz-nsa--n-a--n
Pz-nsa--n-n--n
Pz-nsd--n-a--n
Pz-nsd--n-n--n
Pz-nsg--n-a--n
Pz-nsg--n-n--n
Pz-nsi--n-a--n
Pz-nsi--n-n--n
Pz-nsl--n-a--n
Pz-nsl--n-n--n
Pz-nsn--n-a--n
Pz-nsn--n-n--n
Q
Rgc
Rgp
Rgs
Spc
Sps
Spsa
Spsd
Spsg
Spsi
Spsl
Vaip1p-an
Vaip1p-ay
Vaip1s-an
Vaip1s-ay
Vaip2p-an
Vaip2p-ay
Vaip2s-an
Vaip2s-ay
Vaip3p-an
Vaip3p-ay
Vaip3s-an
Vaip3s-ay
Van----an----n
Van----ay----n
Vaps-pfan----n
Vaps-pfay----n
Vaps-pman---nn
Vaps-pman---yn
Vaps-pmay---nn
Vaps-pmay---yn
Vaps-pnan----n
Vaps-pnay----n
Vaps-sfan----n
Vaps-sfay----n
Vaps-sman----n
Vaps-smay----n
Vaps-snan----n
Vaps-snay----n
Vcc-1p
Vcc-1s
Vcc-2p
Vcc-2s
Vcc-3
Vcif1p-an
Vcif1p-ay
Vcif1s-an
Vcif1s-ay
Vcif2p-an
Vcif2p-ay
Vcif2s-an
Vcif2s-ay
Vcif3p-an
Vcif3p-ay
Vcif3s-an
Vcif3s-ay
Vcip1p-an
Vcip1p-ay
Vcip1s-an
Vcip1s-ay
Vcip2p-an
Vcip2p-ay
Vcip2s-an
Vcip2s-ay
Vcip3p-an
Vcip3p-ay
Vcip3s-an
Vcip3s-ay
Vcmp1p-ay
Vcmp2s-an
Vcmp2s-ay
Vcn----an----n
Vcn----ay----n
Vcps-pfan----n
Vcps-pfay----n
Vcps-pman---nn
Vcps-pman---yn
Vcps-pmay---nn
Vcps-pmay---yn
Vcps-pnan----n
Vcps-pnay----n
Vcps-sfan----n
Vcps-sfay----n
Vcps-sman----n
Vcps-smay----n
Vcps-snan----n
Vcps-snay----n
Vmif1p-an
Vmif2p-an
Vmif2s-an
Vmif3p-an
Vmif3s-an
Vmif3s-ay
Vmip1p-an
Vmip1p-ay
Vmip1s-an
Vmip1s-ay
Vmip2p-an
Vmip2p-ay
Vmip2s-an
Vmip2s-ay
Vmip3p-an
Vmip3p-ay
Vmip3s-an
Vmip3s-ay
Vmmp1p-an
Vmmp1p-ay
Vmmp2p-an
Vmmp2p-ay
Vmmp2s-an
Vmmp2s-ay
Vmn----an----n
Vmn----ay----n
Vmp--pfpn----n
Vmp--pmpn---nn
Vmp--pmpn---yn
Vmp--pmpy---yn
Vmp--pnpn----n
Vmp--pnpy----n
Vmp--sfpn----n
Vmp--sfpy----n
Vmp--smpn----n
Vmp--smpy----n
Vmp--snpn----n
Vmp--snpy----n
Vmps-pfan----n
Vmps-pfay----n
Vmps-pman---nn
Vmps-pman---yn
Vmps-pmay---nn
Vmps-pmay---yn
Vmps-pnan----n
Vmps-pnay----n
Vmps-sfan----n
Vmps-sfan----y
Vmps-sfay----n
Vmps-sman----n
Vmps-sman----y
Vmps-smay----n
Vmps-snan----n
Vmps-snay----n
Vmtp-p-an
Vmtp-p-ay
Vmtp-sfan
Vmtp-sfay
Vmtp-sman
Vmtp-smay
Vmtp-snan
Vmtp-snay
Vmts-p-an
Vmts-sfan
Vmts-sman
Vmts-snan
Voip1p-an
Voip1p-ay
Voip1s-an
Voip1s-ay
Voip2p-an
Voip2p-ay
Voip2s-an
Voip2s-ay
Voip3p-an
Voip3p-ay
Voip3s-an
Voip3s-ay
Vomp1p-an
Vomp2p-an
Vomp2s-an
Von----an----n
Von----ay----n
Vop--snpn----n
Vops-pfan----n
Vops-pfay----n
Vops-pman---nn
Vops-pman---yn
Vops-pmay---nn
Vops-pmay---yn
Vops-pnan----n
Vops-pnay----n
Vops-sfan----n
Vops-sfay----n
Vops-sman----n
Vops-smay----n
Vops-snan----n
Vops-snay----n
Vots-sman
X
Y
end_of_list
    ;
    my @list = split(/\r?\n/, $list);
    pop(@list) if($list[$#list] eq '');
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::CS::Multext - Driver for the Czech tagset of the Multext-EAST project.

=head1 VERSION

version 3.016

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::CS::Multext;
  my $driver = Lingua::Interset::Tagset::CS::Multext->new();
  my $fs = $driver->decode('Ncmsn');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('cs::multext', 'Ncmsn');

=head1 DESCRIPTION

Interset driver for the Czech tagset of the Multext-EAST project.

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
