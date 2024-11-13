# ABSTRACT: Driver for the Croatian tagset of the Multext-EAST v4 project.
# http://nlp.ffzg.hr/data/tagging/msd-hr.html
# Copyright © 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::HR::Multext;
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
    return 'hr::multext';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    # Most atoms can be inherited but some have to be redefined.
    my $atoms = $self->SUPER::_create_atoms();
    # Croatian verbform feature is a merger of verbform, mood, tense and voice.
    # VERB FORM ####################
    $atoms->{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            'n' => ['verbform' => 'inf'],                                     # biti, bit
            'p' => ['verbform' => 'part'],                                    # bio, bila, bilo, bili, bile, bila
            'r' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres'], # sam, si, je, smo, ste, su
            'f' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'fut'],  # no occurrence? these forms are also tagged as present: budem, budeš, bude, budemo, budete, budu
            'm' => ['verbform' => 'fin', 'mood' => 'imp'],                    # budi, budimo, budite
            'a' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'aor'],  # bih, bi, bi, bismo, biste, bi
            'e' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'imp']   # bijah, bijaše, bijaše, bijasmo, bijaste, bijahu
        },
        'encode_map' =>

            { 'mood' => { 'imp' => 'm',
                          '@'   => { 'verbform' => { 'part'  => 'p',
                                                     'trans' => 't',
                                                     'inf'   => 'n',
                                                     '@'     => { 'tense' => { 'pres' => 'r',
                                                                               'fut'  => 'f',
                                                                               'aor'  => 'a',
                                                                               'imp'  => 'e',
                                                                               'past' => 'a',
                                                                               'narr' => 'a',
                                                                               'pqp'  => 'a',
                                                                               '@'    => 'n' }}}}}}
    );
    # ADJTYPE ####################
    $atoms->{adjtype} = $self->create_atom
    (
        'surfeature' => 'adjtype',
        'decode_map' =>
        {
            # general adjective
            # examples: važan, velik, dobar
            'g' => [],
            # possessive adjective
            # examples: Žuvanićev, Ashdownov, vladin
            's' => ['poss' => 'yes'],
            # participial adjective
            # examples: žrtvovan, zvan, znan, zloupotrebljavan
            'p' => ['verbform' => 'part']
        },
        'encode_map' =>

            { 'poss' => { 'yes' => 's',
                           '@'   => { 'verbform' => { 'part' => 'p',
                                                      '@'    => 'g' }}}}
    );
    # IS PRONOUN CLITIC? ####################
    # clitic = yes for short forms of pronouns that behave like clitics (there exists a long form with identical meaning).
    # Examples: me, mi, nam (vs. "nama"), te, ti, vam, ih, im, njeg, ga, mu, nj, njem, njim, je, joj, ju, njom
    $atoms->{clitic} = $self->create_atom
    (
        'surfeature' => 'clitic',
        'decode_map' =>
        {
            'y' => ['variant' => 'short'],
            'n' => ['variant' => 'long']
        },
        'encode_map' =>
        {
            'variant' => { 'short' => 'y',
                           'long'  => 'n',
                           '@'     => '-' }
        }
    );
    # NUMERAL TYPE ####################
    # Czech default is 'c', Croatian default should be '-'.
    $atoms->{numtype}{encode_map}{numtype}{'card'} = 'c';
    $atoms->{numtype}{encode_map}{numtype}{'@'} = '-';
    return $atoms;
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
        'N' => ['pos', 'nountype', 'gender', 'number', 'case', 'animacy'],
        'V' => ['pos', 'verbtype', 'verbform', 'person', 'number', 'gender', 'polarity'],
        'A' => ['pos', 'adjtype', 'degree', 'gender', 'number', 'case', 'definite', 'animacy'],
        'P' => ['pos', 'prontype', 'person', 'gender', 'number', 'case', 'possnumber', 'possgender', 'clitic', 'referent_type', 'syntactic_type', 'animacy'],
        'R' => ['pos', 'adverb_type', 'degree'],
        'S' => ['pos', 'case'],
        # The documentation also mentions a third feature, "conjunction formation", with the values 's' (simple) and 'c' (compound).
        # It does not occur in the SETimes.HR corpus, there are only 'Cc' (coordinating conjunctions) and 'Cs' (subordinating).
        'C' => ['pos', 'conjtype'],
        'M' => ['pos', 'numform', 'numtype', 'gender', 'number', 'case', 'animacy'],
        'Q' => ['pos', 'parttype'],
        'X' => ['pos', 'restype']
    );
    return \%features;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# This is the official list from http://nlp.ffzg.hr/data/tagging/msd-hr.html
#
# Only the tag 'Ps1fsnp--sa' has been removed because it is wrong. It sets the
# referent type (pos[9]='s') for the non-reflexive possessive pronoun "naša",
# while the referent type is normally used to distinguish between reflexive
# personal and reflexive possessive pronouns, i.e. it is non-empty iff the
# pronoun is reflexive. The tag occurs once in the SETimes.HR corpus but the
# same pronoun "naša" occurs more often with the empty referent type
# (Ps1fsnp-n-a).
#
# 1290 tags after removing that one.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
Ncmsn
Ncmsg
Ncmsd
Ncmsan
Ncmsay
Ncmsv
Ncmsl
Ncmsi
Ncmpn
Ncmpg
Ncmpd
Ncmpa
Ncmpv
Ncmpl
Ncmpi
Ncfsn
Ncfsg
Ncfsd
Ncfsa
Ncfsv
Ncfsl
Ncfsi
Ncfpn
Ncfpg
Ncfpd
Ncfpa
Ncfpv
Ncfpl
Ncfpi
Ncnsn
Ncnsg
Ncnsd
Ncnsa
Ncnsv
Ncnsl
Ncnsi
Ncnpn
Ncnpg
Ncnpd
Ncnpa
Ncnpv
Ncnpl
Ncnpi
Np-pn
Np-pg
Npmsn
Npmsg
Npmsd
Npmsan
Npmsay
Npmsv
Npmsl
Npmsi
Npmpn
Npmpg
Npmpd
Npmpa
Npmpv
Npmpl
Npmpi
Npfsn
Npfsg
Npfsd
Npfsa
Npfsv
Npfsl
Npfsi
Npfpn
Npfpg
Npfpd
Npfpa
Npfpv
Npfpl
Npfpi
Npnsn
Npnsg
Npnsd
Npnsa
Npnsv
Npnsl
Npnsi
Npnpn
Npnpg
Npnpd
Npnpa
Npnpv
Npnpl
Npnpi
Vmn
Vmp-sm
Vmp-sf
Vmp-sn
Vmp-pm
Vmp-pf
Vmp-pn
Vmr1s
Vmr1p
Vmr2s
Vmr2p
Vmr3s
Vmr3s-y
Vmr3p
Vmr3p-y
Vmm1p
Vmm2s
Vmm2p
Vma1s
Vma1p
Vma2s
Vma2p
Vma3s
Vma3p
Vme1s
Vme1p
Vme2s
Vme2p
Vme3s
Vme3p
Van
Vap-sm
Vap-sf
Vap-sn
Vap-pm
Vap-pf
Vap-pn
Var1s
Var1s-y
Var1p
Var1p-y
Var2s
Var2p
Var3s
Var3s-y
Var3p
Var3p-y
Vam1p
Vam2s
Vam2p
Vaa1s
Vae1s
Vae1p
Vae2s
Vae2p
Vae3s
Vae3p
Vcn
Vcp-sm
Vcp-sf
Vcp-sn
Vcp-pm
Vcp-pf
Vcp-pn
Vcr1s
Vcr1s-y
Vcr1p
Vcr1p-y
Vcr2s
Vcr2p
Vcr2p-y
Vcr3
Vcr3s
Vcr3s-y
Vcr3p
Vcr3p-y
Vcm1p
Vcm2s
Vcm2p
Vca1s
Vca1p
Vca2s
Vca2p
Vca3s
Vca3p
Vce1s
Vce1p
Vce2s
Vce2p
Vce3s
Vce3p
Agpmsn
Agpmsnn
Agpmsny
Agpmsg
Agpmsgn
Agpmsgy
Agpmsd
Agpmsdy
Agpmsan
Agpmsann
Agpmsany
Agpmsay
Agpmsayn
Agpmsayy
Agpmsv
Agpmsl
Agpmsln
Agpmsly
Agpmsi
Agpmsin
Agpmsiy
Agpmpn
Agpmpnn
Agpmpny
Agpmpg
Agpmpgn
Agpmpgy
Agpmpd
Agpmpdn
Agpmpdy
Agpmpa
Agpmpan
Agpmpay
Agpmpv
Agpmpl
Agpmpln
Agpmply
Agpmpi
Agpmpin
Agpmpiy
Agpfsn
Agpfsnn
Agpfsny
Agpfsg
Agpfsgn
Agpfsgy
Agpfsd
Agpfsdn
Agpfsdy
Agpfsa
Agpfsan
Agpfsay
Agpfsv
Agpfsl
Agpfsln
Agpfsly
Agpfsi
Agpfsin
Agpfsiy
Agpfpn
Agpfpnn
Agpfpny
Agpfpg
Agpfpgn
Agpfpgy
Agpfpd
Agpfpdy
Agpfpa
Agpfpay
Agpfpv
Agpfpl
Agpfpln
Agpfply
Agpfpi
Agpfpin
Agpfpiy
Agpnsn
Agpnsnn
Agpnsny
Agpnsg
Agpnsgn
Agpnsgy
Agpnsd
Agpnsdy
Agpnsa
Agpnsan
Agpnsay
Agpnsv
Agpnsl
Agpnsln
Agpnsly
Agpnsi
Agpnsin
Agpnsiy
Agpnpn
Agpnpnn
Agpnpny
Agpnpg
Agpnpgn
Agpnpgy
Agpnpd
Agpnpdn
Agpnpdy
Agpnpa
Agpnpan
Agpnpay
Agpnpv
Agpnpl
Agpnpln
Agpnply
Agpnpi
Agpnpin
Agpnpiy
Agcmsn
Agcmsny
Agcmsg
Agcmsgy
Agcmsd
Agcmsdy
Agcmsan
Agcmsay
Agcmsayn
Agcmsv
Agcmsl
Agcmsly
Agcmsi
Agcmsiy
Agcmpn
Agcmpny
Agcmpg
Agcmpgy
Agcmpd
Agcmpa
Agcmpay
Agcmpv
Agcmpl
Agcmply
Agcmpi
Agcmpiy
Agcfsn
Agcfsny
Agcfsg
Agcfsgy
Agcfsd
Agcfsdy
Agcfsa
Agcfsay
Agcfsv
Agcfsl
Agcfsly
Agcfsi
Agcfsiy
Agcfpn
Agcfpny
Agcfpg
Agcfpgy
Agcfpd
Agcfpa
Agcfpay
Agcfpv
Agcfpl
Agcfply
Agcfpi
Agcfpiy
Agcnsn
Agcnsny
Agcnsg
Agcnsgy
Agcnsd
Agcnsdy
Agcnsa
Agcnsay
Agcnsv
Agcnsl
Agcnsly
Agcnsi
Agcnsiy
Agcnpn
Agcnpny
Agcnpg
Agcnpgy
Agcnpd
Agcnpa
Agcnpv
Agcnpl
Agcnpi
Agsmsn
Agsmsny
Agsmsg
Agsmsgy
Agsmsd
Agsmsdy
Agsmsan
Agsmsay
Agsmsayn
Agsmsayy
Agsmsv
Agsmsl
Agsmsly
Agsmsi
Agsmsiy
Agsmpn
Agsmpny
Agsmpg
Agsmpgy
Agsmpd
Agsmpdy
Agsmpa
Agsmpay
Agsmpv
Agsmpl
Agsmply
Agsmpi
Agsmpiy
Agsfsn
Agsfsny
Agsfsg
Agsfsgy
Agsfsd
Agsfsa
Agsfsay
Agsfsv
Agsfsl
Agsfsly
Agsfsi
Agsfsiy
Agsfpn
Agsfpny
Agsfpg
Agsfpgy
Agsfpd
Agsfpa
Agsfpay
Agsfpv
Agsfpl
Agsfpi
Agsfpiy
Agsnsn
Agsnsny
Agsnsg
Agsnsgy
Agsnsd
Agsnsa
Agsnsay
Agsnsv
Agsnsl
Agsnsly
Agsnsi
Agsnpn
Agsnpny
Agsnpg
Agsnpgy
Agsnpd
Agsnpa
Agsnpay
Agsnpv
Agsnpl
Agsnply
Agsnpi
Aspmsn
Aspmsnn
Aspmsg
Aspmsgn
Aspmsd
Aspmsdn
Aspmsan
Aspmsann
Aspmsay
Aspmsv
Aspmsl
Aspmsln
Aspmsi
Aspmsin
Aspmsiy
Aspmpn
Aspmpnn
Aspmpg
Aspmpgn
Aspmpd
Aspmpa
Aspmpan
Aspmpv
Aspmpl
Aspmpi
Aspfsn
Aspfsnn
Aspfsg
Aspfsgn
Aspfsd
Aspfsdn
Aspfsa
Aspfsan
Aspfsv
Aspfsl
Aspfsln
Aspfsi
Aspfpn
Aspfpnn
Aspfpg
Aspfpgn
Aspfpgy
Aspfpd
Aspfpa
Aspfpan
Aspfpv
Aspfpl
Aspfpln
Aspfpi
Aspnsn
Aspnsnn
Aspnsg
Aspnsgn
Aspnsd
Aspnsdn
Aspnsa
Aspnsan
Aspnsay
Aspnsv
Aspnsl
Aspnsln
Aspnsly
Aspnsi
Aspnpn
Aspnpg
Aspnpgn
Aspnpd
Aspnpa
Aspnpan
Aspnpv
Aspnpl
Aspnpi
Appmsn
Appmsnn
Appmsny
Appmsg
Appmsgy
Appmsd
Appmsdy
Appmsan
Appmsann
Appmsay
Appmsayn
Appmsayy
Appmsv
Appmsl
Appmsly
Appmsi
Appmsin
Appmsiy
Appmpn
Appmpnn
Appmpg
Appmpgn
Appmpgy
Appmpd
Appmpdn
Appmpa
Appmpan
Appmpv
Appmpl
Appmpln
Appmpi
Appmpin
Appfsn
Appfsnn
Appfsny
Appfsg
Appfsgn
Appfsd
Appfsdn
Appfsa
Appfsan
Appfsay
Appfsv
Appfsl
Appfsln
Appfsly
Appfsi
Appfsin
Appfpn
Appfpnn
Appfpg
Appfpgn
Appfpgy
Appfpd
Appfpdn
Appfpdy
Appfpa
Appfpay
Appfpv
Appfpl
Appfpln
Appfpi
Appfpin
Appnsn
Appnsnn
Appnsg
Appnsgy
Appnsd
Appnsa
Appnsan
Appnsv
Appnsvy
Appnsl
Appnsly
Appnsi
Appnsin
Appnpn
Appnpnn
Appnpg
Appnpgn
Appnpgy
Appnpd
Appnpa
Appnpan
Appnpv
Appnpl
Appnpln
Appnpi
Appnpin
Apcmsny
Apcfsny
Apcnsly
Apsmpny
Apsmpgy
Apsfsgy
Apsfsiy
Apsfpgy
Apsnpgy
Pp1-sn--n-n
Pp1-sg--n-n
Pp1-sg--y-n
Pp1-sd--n-n
Pp1-sd--y-n
Pp1-sa--n-n
Pp1-sa--y-n
Pp1-sl--n-n
Pp1-si--n-n
Pp1-si--y-n
Pp1-pn--n-n
Pp1-pg--n-n
Pp1-pd--n-n
Pp1-pd--y-n
Pp1-pa--n-n
Pp1-pv--n-n
Pp1-pl--n-n
Pp1-pi--n-n
Pp2-sn--n-n
Pp2-sg--n-n
Pp2-sg--y-n
Pp2-sd--n-n
Pp2-sd--y-n
Pp2-sa--n-n
Pp2-sa--y-n
Pp2-sv--n-n
Pp2-sl--n-n
Pp2-si--n-n
Pp2-pn--n-n
Pp2-pg--n-n
Pp2-pd--n-n
Pp2-pd--y-n
Pp2-pa--n-n
Pp2-pv--n-n
Pp2-pl--n-n
Pp2-pi--n-n
Pp3-pg--n-n
Pp3-pg--y-n
Pp3-pd--n-n
Pp3-pd--y-n
Pp3-pa--n-n
Pp3-pa--y-n
Pp3-pl--n-n
Pp3-pi--n-n
Pp3msn--n-n
Pp3msg--n-n
Pp3msg--y-n
Pp3msd--n-n
Pp3msd--y-n
Pp3msa--n-n
Pp3msa--y-n
Pp3msl--n-n
Pp3msl--y-n
Pp3msi--n-n
Pp3msi--y-n
Pp3mpn--n-n
Pp3fsn--n-n
Pp3fsg--n-n
Pp3fsg--y-n
Pp3fsd--n-n
Pp3fsd--y-n
Pp3fsa--n-n
Pp3fsa--y-n
Pp3fsl--n-n
Pp3fsi--n-n
Pp3fsi--y-n
Pp3fpn--n-n
Pp3nsn--n-n
Pp3nsg--n-n
Pp3nsg--y-n
Pp3nsd--n-n
Pp3nsd--y-n
Pp3nsa--n-n
Pp3nsa--y-n
Pp3nsl--n-n
Pp3nsl--y-n
Pp3nsi--n-n
Pp3nsi--y-n
Pp3npn--n-n
Pd-msn--n-a
Pd-msg--n-a
Pd-msd--n-a
Pd-msa--n-an
Pd-msa--n-ay
Pd-msv--n-a
Pd-msl--n-a
Pd-msi--n-a
Pd-mpn--n-a
Pd-mpg--n-a
Pd-mpd--n-a
Pd-mpa--n-a
Pd-mpv--n-a
Pd-mpl--n-a
Pd-mpi--n-a
Pd-fsn--n-a
Pd-fsg--n-a
Pd-fsd--n-a
Pd-fsa--n-a
Pd-fsv--n-a
Pd-fsl--n-a
Pd-fsi--n-a
Pd-fpn--n-a
Pd-fpg--n-a
Pd-fpd--n-a
Pd-fpa--n-a
Pd-fpv--n-a
Pd-fpl--n-a
Pd-fpi--n-a
Pd-nsn--n-a
Pd-nsg--n-a
Pd-nsd--n-a
Pd-nsa--n-a
Pd-nsv--n-a
Pd-nsl--n-a
Pd-nsi--n-a
Pd-npn--n-a
Pd-npg--n-a
Pd-npd--n-a
Pd-npa--n-a
Pd-npv--n-a
Pd-npl--n-a
Pd-npi--n-a
Pi-msn--n-a
Pi-msg--n-a
Pi-msd--n-a
Pi-msa--n-a
Pi-msa--n-an
Pi-msa--n-ay
Pi-msv--n-a
Pi-msl--n-a
Pi-msi--n-a
Pi-mpn--n-a
Pi-mpg--n-a
Pi-mpd--n-a
Pi-mpa--n-a
Pi-mpv--n-a
Pi-mpl--n-a
Pi-mpi--n-a
Pi-fsn--n-a
Pi-fsg--n-a
Pi-fsd--n-a
Pi-fsa--n-a
Pi-fsv--n-a
Pi-fsl--n-a
Pi-fsi--n-a
Pi-fpn--n-a
Pi-fpg--n-a
Pi-fpd--n-a
Pi-fpa--n-a
Pi-fpv--n-a
Pi-fpl--n-a
Pi-fpi--n-a
Pi-nsn--n-a
Pi-nsg--n-a
Pi-nsd--n-a
Pi-nsa----a
Pi-nsa--n-a
Pi-nsv--n-a
Pi-nsl--n-a
Pi-nsi--n-a
Pi-npn--n-a
Pi-npg--n-a
Pi-npd--n-a
Pi-npa--n-a
Pi-npv--n-a
Pi-npl--n-a
Pi-npi--n-a
Pi3m-n--n-ny
Pi3m-g--n-ny
Pi3m-d--n-ny
Pi3m-a--n-ny
Pi3m-l--n-ny
Pi3m-i--n-ny
Pi3n-n--n-nn
Pi3n-g--n-nn
Pi3n-d--n-nn
Pi3n-a--n-nn
Pi3n-l--n-nn
Pi3n-i--n-nn
Pi3n-i--y-nn
Pi3nsn----a
Ps1msns-n-a
Ps1msnp-n-a
Ps1msgs-n-a
Ps1msgp-n-a
Ps1msds-n-a
Ps1msdp-n-a
Ps1msas-n-an
Ps1msas-n-ay
Ps1msap-n-an
Ps1msap-n-ay
Ps1msvs-n-a
Ps1msvp-n-a
Ps1msls-n-a
Ps1mslp-n-a
Ps1msis-n-a
Ps1msip-n-a
Ps1mpns-n-a
Ps1mpnp-n-a
Ps1mpgs-n-a
Ps1mpgp-n-a
Ps1mpds-n-a
Ps1mpdp-n-a
Ps1mpas-n-a
Ps1mpap-n-a
Ps1mpvs-n-a
Ps1mpvp-n-a
Ps1mpls-n-a
Ps1mplp-n-a
Ps1mpis-n-a
Ps1mpip-n-a
Ps1fsns-n-a
Ps1fsnp-n-a
Ps1fsgs-n-a
Ps1fsgp-n-a
Ps1fsds-n-a
Ps1fsdp-n-a
Ps1fsas-n-a
Ps1fsap-n-a
Ps1fsvs-n-a
Ps1fsvp-n-a
Ps1fsls-n-a
Ps1fslp-n-a
Ps1fsis-n-a
Ps1fsip-n-a
Ps1fpns-n-a
Ps1fpnp-n-a
Ps1fpgs-n-a
Ps1fpgp-n-a
Ps1fpds-n-a
Ps1fpdp-n-a
Ps1fpas-n-a
Ps1fpap-n-a
Ps1fpvs-n-a
Ps1fpvp-n-a
Ps1fpls-n-a
Ps1fplp-n-a
Ps1fpis-n-a
Ps1fpip-n-a
Ps1nsns-n-a
Ps1nsnp-n-a
Ps1nsgs-n-a
Ps1nsgp-n-a
Ps1nsds-n-a
Ps1nsdp-n-a
Ps1nsas-n-a
Ps1nsap-n-a
Ps1nsvs-n-a
Ps1nsvp-n-a
Ps1nsls-n-a
Ps1nslp-n-a
Ps1nsis-n-a
Ps1nsip-n-a
Ps1npns-n-a
Ps1npnp-n-a
Ps1npgs-n-a
Ps1npgp-n-a
Ps1npds-n-a
Ps1npdp-n-a
Ps1npas-n-a
Ps1npap-n-a
Ps1npvs-n-a
Ps1npvp-n-a
Ps1npls-n-a
Ps1nplp-n-a
Ps1npis-n-a
Ps1npip-n-a
Ps2msns-n-a
Ps2msnp-n-a
Ps2msgs-n-a
Ps2msgp-n-a
Ps2msds-n-a
Ps2msdp-n-a
Ps2msas-n-an
Ps2msas-n-ay
Ps2msap-n-an
Ps2msap-n-ay
Ps2msvs-n-a
Ps2msvp-n-a
Ps2msls-n-a
Ps2mslp-n-a
Ps2msis-n-a
Ps2msip-n-a
Ps2mpns-n-a
Ps2mpnp-n-a
Ps2mpgs-n-a
Ps2mpgp-n-a
Ps2mpds-n-a
Ps2mpdp-n-a
Ps2mpas-n-a
Ps2mpap-n-a
Ps2mpvs-n-a
Ps2mpvp-n-a
Ps2mpls-n-a
Ps2mplp-n-a
Ps2mpis-n-a
Ps2mpip-n-a
Ps2fsns-n-a
Ps2fsnp-n-a
Ps2fsgs-n-a
Ps2fsgp-n-a
Ps2fsds-n-a
Ps2fsdp-n-a
Ps2fsas-n-a
Ps2fsap-n-a
Ps2fsvs-n-a
Ps2fsvp-n-a
Ps2fsls-n-a
Ps2fslp-n-a
Ps2fsis-n-a
Ps2fsip-n-a
Ps2fpns-n-a
Ps2fpnp-n-a
Ps2fpgs-n-a
Ps2fpgp-n-a
Ps2fpds-n-a
Ps2fpdp-n-a
Ps2fpas-n-a
Ps2fpap-n-a
Ps2fpvs-n-a
Ps2fpvp-n-a
Ps2fpls-n-a
Ps2fplp-n-a
Ps2fpis-n-a
Ps2fpip-n-a
Ps2nsns-n-a
Ps2nsnp-n-a
Ps2nsgs-n-a
Ps2nsgp-n-a
Ps2nsds-n-a
Ps2nsdp-n-a
Ps2nsas-n-a
Ps2nsap-n-a
Ps2nsvs-n-a
Ps2nsvp-n-a
Ps2nsls-n-a
Ps2nslp-n-a
Ps2nsis-n-a
Ps2nsip-n-a
Ps2npns-n-a
Ps2npnp-n-a
Ps2npgs-n-a
Ps2npgp-n-a
Ps2npds-n-a
Ps2npdp-n-a
Ps2npas-n-a
Ps2npap-n-a
Ps2npvs-n-a
Ps2npvp-n-a
Ps2npls-n-a
Ps2nplp-n-a
Ps2npis-n-a
Ps2npip-n-a
Ps3msnsmn-a
Ps3msnsfn-a
Ps3msnsnn-a
Ps3msnp-n-a
Ps3msgsmn-a
Ps3msgsfn-a
Ps3msgsnn-a
Ps3msgp-n-a
Ps3msdsmn-a
Ps3msdsfn-a
Ps3msdsnn-a
Ps3msdp-n-a
Ps3msasmn-an
Ps3msasmn-ay
Ps3msasfn-an
Ps3msasfn-ay
Ps3msasnn-an
Ps3msasnn-ay
Ps3msap-n-an
Ps3msap-n-ay
Ps3mslsmn-a
Ps3mslsfn-a
Ps3mslsnn-a
Ps3mslp-n-a
Ps3msismn-a
Ps3msisfn-a
Ps3msisnn-a
Ps3msip-n-a
Ps3mpnsmn-a
Ps3mpnsfn-a
Ps3mpnsnn-a
Ps3mpnp-n-a
Ps3mpgsmn-a
Ps3mpgsfn-a
Ps3mpgsnn-a
Ps3mpgp-n-a
Ps3mpdsmn-a
Ps3mpdsfn-a
Ps3mpdsnn-a
Ps3mpdp-n-a
Ps3mpasmn-a
Ps3mpasfn-a
Ps3mpasnn-a
Ps3mpap-n-a
Ps3mplsmn-a
Ps3mplsfn-a
Ps3mplsnn-a
Ps3mplp-n-a
Ps3mpismn-a
Ps3mpisfn-a
Ps3mpisnn-a
Ps3mpip-n-a
Ps3fsnsmn-a
Ps3fsnsfn-a
Ps3fsnsnn-a
Ps3fsnp-n-a
Ps3fsgsmn-a
Ps3fsgsfn-a
Ps3fsgsnn-a
Ps3fsgp-n-a
Ps3fsdsmn-a
Ps3fsdsfn-a
Ps3fsdsnn-a
Ps3fsdp-n-a
Ps3fsasmn-a
Ps3fsasfn-a
Ps3fsasnn-a
Ps3fsap-n-a
Ps3fslsmn-a
Ps3fslsfn-a
Ps3fslsnn-a
Ps3fslp-n-a
Ps3fsismn-a
Ps3fsisfn-a
Ps3fsisnn-a
Ps3fsip-n-a
Ps3fpnsmn-a
Ps3fpnsfn-a
Ps3fpnsnn-a
Ps3fpnp-n-a
Ps3fpgsmn-a
Ps3fpgsfn-a
Ps3fpgsnn-a
Ps3fpgp-n-a
Ps3fpdsmn-a
Ps3fpdsfn-a
Ps3fpdsnn-a
Ps3fpdp-n-a
Ps3fpasmn-a
Ps3fpasfn-a
Ps3fpasnn-a
Ps3fpap-n-a
Ps3fplsmn-a
Ps3fplsfn-a
Ps3fplsnn-a
Ps3fplp-n-a
Ps3fpismn-a
Ps3fpisfn-a
Ps3fpisnn-a
Ps3fpip-n-a
Ps3nsnsmn-a
Ps3nsnsfn-a
Ps3nsnsnn-a
Ps3nsnp-n-a
Ps3nsgsmn-a
Ps3nsgsfn-a
Ps3nsgsnn-a
Ps3nsgp-n-a
Ps3nsdsmn-a
Ps3nsdsfn-a
Ps3nsdsnn-a
Ps3nsdp-n-a
Ps3nsasmn-a
Ps3nsasfn-a
Ps3nsasnn-a
Ps3nsap-n-a
Ps3nslsmn-a
Ps3nslsfn-a
Ps3nslsnn-a
Ps3nslp-n-a
Ps3nsismn-a
Ps3nsisfn-a
Ps3nsisnn-a
Ps3nsip-n-a
Ps3npnsmn-a
Ps3npnsfn-a
Ps3npnsnn-a
Ps3npnp-n-a
Ps3npgsmn-a
Ps3npgsfn-a
Ps3npgsnn-a
Ps3npgp-n-a
Ps3npdsmn-a
Ps3npdsfn-a
Ps3npdsnn-a
Ps3npdp-n-a
Ps3npasmn-a
Ps3npasfn-a
Ps3npasnn-a
Ps3npap-n-a
Ps3nplsmn-a
Ps3nplsfn-a
Ps3nplsnn-a
Ps3nplp-n-a
Ps3npismn-a
Ps3npisfn-a
Ps3npisnn-a
Ps3npip-n-a
Pq-msn--n-a
Pq-msg--n-a
Pq-msd--n-a
Pq-msa--n-an
Pq-msa--n-ay
Pq-msv--n-a
Pq-msl--n-a
Pq-msi--n-a
Pq-mpn--n-a
Pq-mpg--n-a
Pq-mpd--n-a
Pq-mpa--n-a
Pq-mpv--n-a
Pq-mpl--n-a
Pq-mpi--n-a
Pq-fsn--n-a
Pq-fsg--n-a
Pq-fsd--n-a
Pq-fsa--n-a
Pq-fsv--n-a
Pq-fsl--n-a
Pq-fsi--n-a
Pq-fpn--n-a
Pq-fpg--n-a
Pq-fpd--n-a
Pq-fpa--n-a
Pq-fpv--n-a
Pq-fpl--n-a
Pq-fpi--n-a
Pq-nsn--n-a
Pq-nsg--n-a
Pq-nsd--n-a
Pq-nsa--n-a
Pq-nsv--n-a
Pq-nsl--n-a
Pq-nsi--n-a
Pq-npn--n-a
Pq-npg--n-a
Pq-npd--n-a
Pq-npa--n-a
Pq-npv--n-a
Pq-npl--n-a
Pq-npi--n-a
Pq3m-n--n-ny
Pq3m-g--n-ny
Pq3m-g--y-ny
Pq3m-d--n-ny
Pq3m-d--y-ny
Pq3m-a--n-ny
Pq3m-a--y-ny
Pq3m-l--n-ny
Pq3m-l--y-ny
Pq3m-i--n-ny
Pq3m-i--y-ny
Pq3n-n--n-nn
Pq3n-g--n-nn
Pq3n-g--y-nn
Pq3n-d--n-nn
Pq3n-d--y-nn
Pq3n-a--n-nn
Pq3n-l--n-nn
Pq3n-l--y-nn
Pq3n-i--n-nn
Pq3n-i--y-nn
Px--sg--npn
Px--sg--ypn
Px--sd--npn
Px--sd--ypn
Px--sa--npn
Px--sa--ypn
Px--sl--npn
Px--si--npn
Px-msn--nsa
Px-msg--nsa
Px-msd--nsa
Px-msa--nsan
Px-msa--nsay
Px-msv--nsa
Px-msl--nsa
Px-msi--nsa
Px-mpn--nsa
Px-mpg--nsa
Px-mpd--nsa
Px-mpa--nsa
Px-mpv--nsa
Px-mpl--nsa
Px-mpi--nsa
Px-fsn--nsa
Px-fsg--nsa
Px-fsd--nsa
Px-fsa--nsa
Px-fsv--nsa
Px-fsl--nsa
Px-fsi--nsa
Px-fpn--nsa
Px-fpg--nsa
Px-fpd--nsa
Px-fpa--nsa
Px-fpv--nsa
Px-fpl--nsa
Px-fpi--nsa
Px-nsn--nsa
Px-nsg--nsa
Px-nsd--nsa
Px-nsa--nsa
Px-nsv--nsa
Px-nsl--nsa
Px-nsi--nsa
Px-npn--nsa
Px-npg--nsa
Px-npd--nsa
Px-npa--nsa
Px-npv--nsa
Px-npl--nsa
Px-npi--nsa
Rgp
Rgc
Rgs
Rr
Sg
Sd
Sa
Sl
Si
Cc
Cs
Md
Mro-p
Mlc-s
Mlc-p
Mlc-pn
Mlc-pg
Mlc-pd
Mlc-pa
Mlcmsn
Mlcmsg
Mlcmsd
Mlcmsan
Mlcmsay
Mlcmsl
Mlcmsi
Mlcmpn
Mlcmpg
Mlcmpa
Mlcmpan
Mlcmpl
Mlcfs
Mlcfsn
Mlcfsg
Mlcfsd
Mlcfsa
Mlcfsl
Mlcfsi
Mlcfp
Mlcfpn
Mlcfpg
Mlcfpa
Mlcnsn
Mlcnsg
Mlcnsa
Mlcnpn
Mls-s
Mls-sa
Mls-p
Mls-pn
Mlsmpg
Mlsmpa
Mlsfp
Mlsfpn
Mlsfpg
Mlsfpd
Mlsfpa
Mlsfpl
Qz
Qq
Qo
Qr
I
Y
X
Xf
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

Lingua::Interset::Tagset::HR::Multext - Driver for the Croatian tagset of the Multext-EAST v4 project.

=head1 VERSION

version 3.016

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::HR::Multext;
  my $driver = Lingua::Interset::Tagset::HR::Multext->new();
  my $fs = $driver->decode('Ncmsn');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('hr::multext', 'Ncmsn');

=head1 DESCRIPTION

Interset driver for the Croatian tagset of the Multext-EAST v4 project.
See L<http://nlp.ffzg.hr/data/tagging/msd-hr.html> for a detailed description
of the tagset.

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
