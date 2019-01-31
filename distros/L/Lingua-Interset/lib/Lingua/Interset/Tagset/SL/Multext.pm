# ABSTRACT: Driver for the Slovene tagset of the Multext-EAST v4 project.
# http://nlp.ffzg.hr/data/tagging/msd-hr.html
# Copyright © 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::SL::Multext;
use strict;
use warnings;
our $VERSION = '3.014';

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
    return 'sl::multext';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    # Most atoms can be inherited but some have to be redefined.
    my $atoms = $self->SUPER::_create_atoms();
    # Slovenian verbform feature is a merger of verbform, mood, tense and voice.
    # VERB FORM ####################
    $atoms->{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            'n' => ['verbform' => 'inf'],                                     # biti, bit
            'u' => ['verbform' => 'sup'],                                     # bit
            'p' => ['verbform' => 'part'],                                    # bil, bila, bilo, bili, bile, bila
            'r' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres'], # sem, si, je, sva, sta, sta, smo, ste, su
            'f' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'fut'],  # bom, boš, bo, bova, bosta, bosta, bomo, boste, bodo
            'c' => ['verbform' => 'fin', 'mood' => 'cnd'],                    # bi
            'm' => ['verbform' => 'fin', 'mood' => 'imp']                     # bodi, bodita, bodimo, bodite
        },
        'encode_map' =>
        {
            'mood' => { 'imp' => 'm',
                        'cnd' => 'c',
                        '@'   => { 'verbform' => { 'part' => 'p',
                                                   'sup'  => 'u',
                                                   'inf'  => 'n',
                                                   '@'    => { 'tense' => { 'pres' => 'r',
                                                                            'fut'  => 'f',
                                                                            '@'    => 'n' }}}}}
        }
    );
    # ADJTYPE ####################
    ###!!! Hodnoty [gsp] jsou v dokumentaci, kterou mám.
    ###!!! Jenže mezi značkami (které mám, pokud vím, ze stejné verze Multextu jako dokumentaci), jsou hodnoty [fos]!
    ###!!! např. Af: adoptiven, adoptivna
    ###!!! např. Ao: adrenalinski, adrenalinska
    ###!!! např. As: agentov, agentova
    # To spíš vypadá na jmenný tvar, zájmenný tvar a přivlastňovací přídavné jméno.
    # Zastaralá je asi ta tabulka značek, protože v korpusu SSJ se Af nevyskytuje, ale Ag ano.
    $atoms->{adjtype} = $self->create_atom
    (
        'surfeature' => 'adjtype',
        'decode_map' =>
        {
            # general adjective
            # examples: sam, dober, velik
            'g' => [],
            # possessive adjective
            # examples: kalcijev, ogljikov, papežev
            's' => ['poss' => 'yes'],
            # participial adjective
            # examples: prepričan, pripravljen, namenjen
            'p' => ['verbform' => 'part']
        },
        'encode_map' =>

            { 'poss' => { 'yes' => 's',
                           '@'   => { 'verbform' => { 'part' => 'p',
                                                      '@'    => 'g' }}}}
    );
    # IS PRONOUN CLITIC? ####################
    # clitic = yes for short forms of pronouns that behave like clitics (there exists a long form with identical meaning).
    # clitic = bound for short forms with prepositions
    # PerGenNumCase:  1-sa  2-sa  3msg   3msd   3mdg   3mdd   3mpg  3mpd  3fsg 3fsd  3fsa a
    # Examples (yes): me,   te,   ga,    mu,    ju,    jima,  jih,  jim,  je,  ji,   jo,  se
    # Examples (-):   mene, tebe, njega, njemu, njiju, njima, njih, njim, nje, njej, njo, sebe
    # Examples (bound): zame, name, vame, čezme, skozme, predme, pome, zate, nate, vate,
    #     zanjo, vanjo, nanjo, nadnjo, skoznjo, čeznjo, prednjo, ponjo, podnjo, obnjo,
    #     vanj, nanj, zanj, skozenj, nanje, zanje, skoznje, mednje, zase, nase, vase, predse, medse
    $atoms->{clitic} = $self->create_atom
    (
        'surfeature' => 'clitic',
        'decode_map' =>
        {
            'y' => ['variant' => 'short'],
            'n' => ['variant' => 'long'],
            'b' => ['variant' => 'short', 'adpostype' => 'preppron']
        },
        'encode_map' =>
        {
            'variant' => { 'short' => { 'adpostype' => { 'preppron' => 'b',
                                                         '@'        => 'y' }},
                           'long'  => 'n',
                           '@'     => '-' }
        }
    );
    # NUMERAL TYPE ####################
    ###!!!
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
        'V' => ['pos', 'verbtype', 'aspect', 'verbform', 'person', 'number', 'gender', 'polarity'],
        'A' => ['pos', 'adjtype', 'degree', 'gender', 'number', 'case', 'definite', 'animacy'],
        'P' => ['pos', 'prontype', 'person', 'gender', 'number', 'case', 'possnumber', 'possgender', 'clitic'],
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
Agcfdn
Agcfpa
Agcfpd
Agcfpg
Agcfpi
Agcfpl
Agcfpn
Agcfsa
Agcfsd
Agcfsg
Agcfsi
Agcfsl
Agcfsn
Agcmdn
Agcmpa
Agcmpd
Agcmpg
Agcmpi
Agcmpl
Agcmpn
Agcmsay
Agcmsd
Agcmsg
Agcmsi
Agcmsl
Agcmsny
Agcnpa
Agcnpd
Agcnpg
Agcnpi
Agcnpl
Agcnpn
Agcnsa
Agcnsd
Agcnsg
Agcnsi
Agcnsl
Agcnsn
Agpfda
Agpfdg
Agpfdi
Agpfdl
Agpfdn
Agpfpa
Agpfpd
Agpfpg
Agpfpi
Agpfpl
Agpfpn
Agpfsa
Agpfsd
Agpfsg
Agpfsi
Agpfsl
Agpfsn
Agpmda
Agpmdg
Agpmdi
Agpmdl
Agpmdn
Agpmpa
Agpmpd
Agpmpg
Agpmpi
Agpmpl
Agpmpn
Agpmsa
Agpmsan
Agpmsay
Agpmsd
Agpmsg
Agpmsi
Agpmsl
Agpmsnn
Agpmsny
Agpnda
Agpndg
Agpndi
Agpndn
Agpnpa
Agpnpd
Agpnpg
Agpnpi
Agpnpl
Agpnpn
Agpnsa
Agpnsd
Agpnsg
Agpnsi
Agpnsl
Agpnsn
Agsfda
Agsfdi
Agsfpa
Agsfpg
Agsfpi
Agsfpl
Agsfpn
Agsfsa
Agsfsd
Agsfsg
Agsfsi
Agsfsl
Agsfsn
Agsmdn
Agsmpa
Agsmpd
Agsmpg
Agsmpi
Agsmpl
Agsmpn
Agsmsa
Agsmsay
Agsmsg
Agsmsi
Agsmsl
Agsmsny
Agsnpa
Agsnpg
Agsnpn
Agsnsa
Agsnsi
Agsnsl
Agsnsn
Appfda
Appfdg
Appfdi
Appfdn
Appfpa
Appfpd
Appfpg
Appfpi
Appfpl
Appfpn
Appfsa
Appfsd
Appfsg
Appfsi
Appfsl
Appfsn
Appmda
Appmdd
Appmdg
Appmdl
Appmdn
Appmpa
Appmpd
Appmpg
Appmpi
Appmpl
Appmpn
Appmsa
Appmsan
Appmsay
Appmsd
Appmsg
Appmsi
Appmsl
Appmsnn
Appmsny
Appndg
Appndn
Appnpa
Appnpg
Appnpi
Appnpl
Appnpn
Appnsa
Appnsd
Appnsg
Appnsi
Appnsl
Appnsn
Aspfdn
Aspfpa
Aspfpd
Aspfpg
Aspfpi
Aspfpl
Aspfpn
Aspfsa
Aspfsd
Aspfsg
Aspfsi
Aspfsl
Aspfsn
Aspmdl
Aspmdn
Aspmpa
Aspmpd
Aspmpg
Aspmpl
Aspmpn
Aspmsa
Aspmsan
Aspmsd
Aspmsg
Aspmsi
Aspmsl
Aspmsnn
Aspnpa
Aspnpg
Aspnpi
Aspnpl
Aspnpn
Aspnsa
Aspnsg
Aspnsi
Aspnsl
Aspnsn
Cc
Cs
I
Mdc
Mdo
Mlc-pa
Mlc-pd
Mlc-pg
Mlc-pi
Mlc-pl
Mlc-pn
Mlcfda
Mlcfdg
Mlcfdi
Mlcfdl
Mlcfdn
Mlcfpa
Mlcfpd
Mlcfpg
Mlcfpi
Mlcfpl
Mlcfpn
Mlcmda
Mlcmdg
Mlcmdi
Mlcmdl
Mlcmdn
Mlcmpa
Mlcmpd
Mlcmpg
Mlcmpi
Mlcmpl
Mlcmpn
Mlcnda
Mlcndg
Mlcndi
Mlcndl
Mlcndn
Mlcnpa
Mlcnpg
Mlcnpi
Mlcnpl
Mlcnpn
Mlofpa
Mlofpd
Mlofpg
Mlofpi
Mlofpl
Mlofpn
Mlofsa
Mlofsd
Mlofsg
Mlofsi
Mlofsl
Mlofsn
Mlompa
Mlompg
Mlompi
Mlompl
Mlompn
Mlomsa
Mlomsd
Mlomsg
Mlomsi
Mlomsl
Mlomsn
Mlonda
Mlonpg
Mlonpl
Mlonpn
Mlonsa
Mlonsg
Mlonsi
Mlonsl
Mlonsn
Mlpfdl
Mlpfpa
Mlpfpg
Mlpfpi
Mlpfpl
Mlpfpn
Mlpfsa
Mlpfsd
Mlpfsg
Mlpfsi
Mlpfsl
Mlpfsn
Mlpmdl
Mlpmpa
Mlpmpd
Mlpmpg
Mlpmpi
Mlpmpl
Mlpmpn
Mlpmsa
Mlpmsan
Mlpmsay
Mlpmsd
Mlpmsg
Mlpmsi
Mlpmsl
Mlpmsn
Mlpmsnn
Mlpmsny
Mlpnpa
Mlpnpg
Mlpnpi
Mlpnpl
Mlpnpn
Mlpnsa
Mlpnsg
Mlpnsi
Mlpnsl
Mlpnsn
Mlsfpa
Mlsfpg
Mlsfsg
Mlsfsi
Mlsfsn
Mlsmpi
Mlsmsg
Mlsmsi
Mlsnsa
Mlsnsi
Mlsnsn
Mrc
Mro
Ncfda
Ncfdd
Ncfdg
Ncfdi
Ncfdl
Ncfdn
Ncfpa
Ncfpd
Ncfpg
Ncfpi
Ncfpl
Ncfpn
Ncfsa
Ncfsd
Ncfsg
Ncfsi
Ncfsl
Ncfsn
Ncmda
Ncmdd
Ncmdg
Ncmdi
Ncmdl
Ncmdn
Ncmpa
Ncmpd
Ncmpg
Ncmpi
Ncmpl
Ncmpn
Ncmsan
Ncmsay
Ncmsd
Ncmsg
Ncmsi
Ncmsl
Ncmsn
Ncnda
Ncndd
Ncndg
Ncndi
Ncndl
Ncndn
Ncnpa
Ncnpd
Ncnpg
Ncnpi
Ncnpl
Ncnpn
Ncnsa
Ncnsd
Ncnsg
Ncnsi
Ncnsl
Ncnsn
Npfpa
Npfpd
Npfpg
Npfpi
Npfpl
Npfpn
Npfsa
Npfsd
Npfsg
Npfsi
Npfsl
Npfsn
Npmda
Npmdg
Npmdn
Npmpa
Npmpd
Npmpg
Npmpi
Npmpl
Npmpn
Npmsan
Npmsay
Npmsd
Npmsg
Npmsi
Npmsl
Npmsn
Npnpn
Npnsa
Npnsg
Npnsi
Npnsl
Npnsn
Pd-fda
Pd-fdn
Pd-fpa
Pd-fpd
Pd-fpg
Pd-fpi
Pd-fpl
Pd-fpn
Pd-fsa
Pd-fsd
Pd-fsg
Pd-fsi
Pd-fsl
Pd-fsn
Pd-mda
Pd-mdg
Pd-mdl
Pd-mdn
Pd-mpa
Pd-mpd
Pd-mpg
Pd-mpi
Pd-mpl
Pd-mpn
Pd-msa
Pd-msd
Pd-msg
Pd-msi
Pd-msl
Pd-msn
Pd-npa
Pd-npd
Pd-npg
Pd-npl
Pd-npn
Pd-nsa
Pd-nsd
Pd-nsg
Pd-nsi
Pd-nsl
Pd-nsn
Pg-fda
Pg-fdg
Pg-fdi
Pg-fdl
Pg-fdn
Pg-fpa
Pg-fpd
Pg-fpg
Pg-fpi
Pg-fpl
Pg-fpn
Pg-fsa
Pg-fsd
Pg-fsg
Pg-fsi
Pg-fsl
Pg-fsn
Pg-mda
Pg-mdd
Pg-mdg
Pg-mdi
Pg-mdl
Pg-mdn
Pg-mpa
Pg-mpd
Pg-mpg
Pg-mpi
Pg-mpl
Pg-mpn
Pg-msa
Pg-msd
Pg-msg
Pg-msi
Pg-msl
Pg-msn
Pg-nda
Pg-ndd
Pg-ndn
Pg-npa
Pg-npd
Pg-npg
Pg-npi
Pg-npl
Pg-npn
Pg-nsa
Pg-nsd
Pg-nsg
Pg-nsi
Pg-nsl
Pg-nsn
Pi-fdn
Pi-fpa
Pi-fpd
Pi-fpg
Pi-fpi
Pi-fpl
Pi-fpn
Pi-fsa
Pi-fsd
Pi-fsg
Pi-fsi
Pi-fsl
Pi-fsn
Pi-mpa
Pi-mpd
Pi-mpg
Pi-mpi
Pi-mpl
Pi-mpn
Pi-msa
Pi-msd
Pi-msg
Pi-msi
Pi-msl
Pi-msn
Pi-npa
Pi-npg
Pi-npi
Pi-npl
Pi-npn
Pi-nsa
Pi-nsg
Pi-nsi
Pi-nsl
Pi-nsn
Pp1-da
Pp1-dd
Pp1-dg
Pp1-di
Pp1-pa
Pp1-pd
Pp1-pg
Pp1-pi
Pp1-pl
Pp1-sa
Pp1-sa--b
Pp1-sa--y
Pp1-sd
Pp1-sd--y
Pp1-sg
Pp1-sg--y
Pp1-si
Pp1-sl
Pp1-sn
Pp1fpn
Pp1mdn
Pp1mpn
Pp2-da
Pp2-dd
Pp2-di
Pp2-pa
Pp2-pd
Pp2-pg
Pp2-pi
Pp2-pl
Pp2-sa
Pp2-sa--b
Pp2-sa--y
Pp2-sd
Pp2-sd--y
Pp2-sg
Pp2-sg--y
Pp2-si
Pp2-sn
Pp2fdn
Pp2mpn
Pp3fda
Pp3fda--b
Pp3fda--y
Pp3fdd--y
Pp3fdg--y
Pp3fdi
Pp3fdl
Pp3fpa--b
Pp3fpa--y
Pp3fpd
Pp3fpd--y
Pp3fpg
Pp3fpg--y
Pp3fpi
Pp3fpl
Pp3fsa
Pp3fsa--b
Pp3fsa--y
Pp3fsd
Pp3fsd--y
Pp3fsg
Pp3fsg--y
Pp3fsi
Pp3fsl
Pp3fsn
Pp3mda
Pp3mda--b
Pp3mda--y
Pp3mdd
Pp3mdd--y
Pp3mdg
Pp3mdi
Pp3mdl
Pp3mdn
Pp3mpa
Pp3mpa--b
Pp3mpa--y
Pp3mpd
Pp3mpd--y
Pp3mpg
Pp3mpg--y
Pp3mpi
Pp3mpl
Pp3mpn
Pp3msa
Pp3msa--b
Pp3msa--y
Pp3msd
Pp3msd--y
Pp3msg
Pp3msg--y
Pp3msi
Pp3msl
Pp3msn
Pp3nda--y
Pp3npa--b
Pp3npa--y
Pp3npd--y
Pp3npg
Pp3npg--y
Pp3npi
Pp3npl
Pp3nsa--b
Pp3nsa--y
Pp3nsd--y
Pp3nsg
Pp3nsg--y
Pp3nsi
Pp3nsl
Pq-fda
Pq-fdi
Pq-fpa
Pq-fpd
Pq-fpg
Pq-fpi
Pq-fpl
Pq-fpn
Pq-fsa
Pq-fsd
Pq-fsg
Pq-fsi
Pq-fsl
Pq-fsn
Pq-mdg
Pq-mdi
Pq-mpa
Pq-mpd
Pq-mpg
Pq-mpi
Pq-mpl
Pq-mpn
Pq-msa
Pq-msd
Pq-msg
Pq-msi
Pq-msl
Pq-msn
Pq-npa
Pq-npg
Pq-npi
Pq-npl
Pq-npn
Pq-nsa
Pq-nsd
Pq-nsg
Pq-nsi
Pq-nsl
Pq-nsn
Pr----sm
Pr-fpa
Pr-fpg
Pr-fpl
Pr-fsa
Pr-fsg
Pr-fsi
Pr-fsl
Pr-fsn
Pr-mdn
Pr-mpg
Pr-mpl
Pr-mpn
Pr-msa
Pr-msd
Pr-msg
Pr-msi
Pr-msn
Pr-nsa
Pr-nsg
Pr-nsi
Pr-nsl
Pr-nsn
Ps1fdns
Ps1fpap
Ps1fpas
Ps1fpdp
Ps1fpgp
Ps1fpgs
Ps1fpip
Ps1fplp
Ps1fpnd
Ps1fpnp
Ps1fpns
Ps1fsap
Ps1fsas
Ps1fsdp
Ps1fsds
Ps1fsgp
Ps1fsgs
Ps1fsid
Ps1fsip
Ps1fsis
Ps1fslp
Ps1fsls
Ps1fsnd
Ps1fsnp
Ps1fsns
Ps1mdgd
Ps1mdid
Ps1mdns
Ps1mpap
Ps1mpdp
Ps1mpgd
Ps1mpgp
Ps1mpgs
Ps1mpip
Ps1mplp
Ps1mpnd
Ps1mpnp
Ps1mpns
Ps1msap
Ps1msas
Ps1msds
Ps1msgp
Ps1msgs
Ps1msip
Ps1msis
Ps1mslp
Ps1msls
Ps1msnd
Ps1msnp
Ps1msns
Ps1npap
Ps1npas
Ps1npgp
Ps1npgs
Ps1nplp
Ps1npnp
Ps1nsap
Ps1nsas
Ps1nsdp
Ps1nsgd
Ps1nsgp
Ps1nsgs
Ps1nslp
Ps1nsls
Ps1nsnd
Ps1nsnp
Ps1nsns
Ps2fdnp
Ps2fpap
Ps2fpgp
Ps2fpnp
Ps2fpns
Ps2fsad
Ps2fsap
Ps2fsds
Ps2fsgd
Ps2fsgp
Ps2fsgs
Ps2fsid
Ps2fsip
Ps2fslp
Ps2fsnp
Ps2fsns
Ps2mdgd
Ps2mpdp
Ps2mpgp
Ps2mpid
Ps2mpnp
Ps2mpns
Ps2msap
Ps2msas
Ps2msgp
Ps2msgs
Ps2msip
Ps2mslp
Ps2msnd
Ps2msnp
Ps2msns
Ps2ndgd
Ps2npap
Ps2npnp
Ps2npns
Ps2nsap
Ps2nsas
Ps2nsgp
Ps2nslp
Ps2nsnp
Ps2nsns
Ps3fdnd
Ps3fpap
Ps3fpasf
Ps3fpasm
Ps3fpdp
Ps3fpdsm
Ps3fpgp
Ps3fpgsf
Ps3fpgsm
Ps3fpip
Ps3fpisf
Ps3fpism
Ps3fplp
Ps3fplsf
Ps3fplsm
Ps3fpnp
Ps3fpnsf
Ps3fpnsm
Ps3fsad
Ps3fsap
Ps3fsasf
Ps3fsasm
Ps3fsdp
Ps3fsdsf
Ps3fsdsm
Ps3fsgd
Ps3fsgp
Ps3fsgsf
Ps3fsgsm
Ps3fsid
Ps3fsip
Ps3fsisf
Ps3fsism
Ps3fsld
Ps3fslp
Ps3fslsf
Ps3fslsm
Ps3fsnd
Ps3fsnp
Ps3fsnsf
Ps3fsnsm
Ps3fsnsn
Ps3mdnd
Ps3mdnsm
Ps3mpap
Ps3mpasf
Ps3mpasm
Ps3mpdp
Ps3mpdsf
Ps3mpdsm
Ps3mpgp
Ps3mpgsf
Ps3mpgsm
Ps3mpip
Ps3mpism
Ps3mplp
Ps3mplsf
Ps3mplsm
Ps3mpnd
Ps3mpnp
Ps3mpnsf
Ps3mpnsm
Ps3msad
Ps3msap
Ps3msasf
Ps3msasm
Ps3msdp
Ps3msdsf
Ps3msdsm
Ps3msgd
Ps3msgp
Ps3msgsf
Ps3msgsm
Ps3msip
Ps3msisf
Ps3msism
Ps3mslp
Ps3mslsf
Ps3mslsm
Ps3msnd
Ps3msnp
Ps3msnsf
Ps3msnsm
Ps3msnsn
Ps3ndad
Ps3ndnsf
Ps3npap
Ps3npasf
Ps3npasm
Ps3npgd
Ps3npgp
Ps3npgsf
Ps3npgsm
Ps3npism
Ps3npnp
Ps3npnsm
Ps3nsad
Ps3nsap
Ps3nsasf
Ps3nsasm
Ps3nsdp
Ps3nsdsf
Ps3nsgp
Ps3nsgsf
Ps3nsgsm
Ps3nsisf
Ps3nsism
Ps3nsld
Ps3nslp
Ps3nslsf
Ps3nslsm
Ps3nsnd
Ps3nsnp
Ps3nsnsf
Ps3nsnsm
Px------y
Px---a
Px---a--b
Px---d
Px---d--y
Px---g
Px---i
Px---l
Px-fda
Px-fpa
Px-fpd
Px-fpg
Px-fpi
Px-fpl
Px-fsa
Px-fsd
Px-fsg
Px-fsi
Px-fsl
Px-mda
Px-mpa
Px-mpd
Px-mpg
Px-mpi
Px-mpl
Px-msa
Px-msd
Px-msg
Px-msi
Px-msl
Px-msn
Px-npa
Px-npd
Px-npg
Px-npi
Px-npl
Px-nsa
Px-nsd
Px-nsg
Px-nsi
Px-nsl
Px-nsn
Pz-fpa
Pz-fpg
Pz-fpi
Pz-fpn
Pz-fsa
Pz-fsd
Pz-fsg
Pz-fsn
Pz-mpg
Pz-msa
Pz-msd
Pz-msg
Pz-msi
Pz-msl
Pz-msn
Pz-nsa
Pz-nsd
Pz-nsg
Pz-nsl
Pz-nsn
Q
Rgc
Rgp
Rgs
Rr
Sa
Sd
Sg
Si
Sl
Va-c
Va-f1d-n
Va-f1p-n
Va-f1s-n
Va-f2d-n
Va-f2p-n
Va-f2s-n
Va-f3d-n
Va-f3p-n
Va-f3s-n
Va-m2p
Va-m2s
Va-n
Va-p-df
Va-p-dm
Va-p-dn
Va-p-pf
Va-p-pm
Va-p-pn
Va-p-sf
Va-p-sm
Va-p-sn
Va-r1d-n
Va-r1d-y
Va-r1p-n
Va-r1p-y
Va-r1s-n
Va-r1s-y
Va-r2d-n
Va-r2p-n
Va-r2p-y
Va-r2s-n
Va-r2s-y
Va-r3d-n
Va-r3d-y
Va-r3p-n
Va-r3p-y
Va-r3s-n
Va-r3s-y
Vmbm1p
Vmbm2d
Vmbm2p
Vmbm2s
Vmbn
Vmbp-df
Vmbp-dm
Vmbp-dn
Vmbp-pf
Vmbp-pm
Vmbp-pn
Vmbp-sf
Vmbp-sm
Vmbp-sn
Vmbr1d
Vmbr1p
Vmbr1s
Vmbr2d
Vmbr2p
Vmbr2s
Vmbr3d
Vmbr3p
Vmbr3s
Vmbu
Vmem1d
Vmem1p
Vmem2d
Vmem2p
Vmem2s
Vmen
Vmep-df
Vmep-dm
Vmep-dn
Vmep-pf
Vmep-pm
Vmep-pn
Vmep-sf
Vmep-sm
Vmep-sn
Vmer1d
Vmer1p
Vmer1s
Vmer2d
Vmer2p
Vmer2s
Vmer3d
Vmer3p
Vmer3s
Vmeu
Vmpm1p
Vmpm2d
Vmpm2p
Vmpm2s
Vmpn
Vmpp-df
Vmpp-dm
Vmpp-dn
Vmpp-pf
Vmpp-pm
Vmpp-pn
Vmpp-sf
Vmpp-sm
Vmpp-sn
Vmpr1d
Vmpr1d-n
Vmpr1p
Vmpr1p-n
Vmpr1p-y
Vmpr1s
Vmpr1s-n
Vmpr1s-y
Vmpr2d
Vmpr2d-n
Vmpr2p
Vmpr2p-n
Vmpr2p-y
Vmpr2s
Vmpr2s-n
Vmpr2s-y
Vmpr3d
Vmpr3d-n
Vmpr3p
Vmpr3p-n
Vmpr3p-y
Vmpr3s
Vmpr3s-n
Vmpr3s-y
Vmpu
X
Xf
Y
Z
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

Lingua::Interset::Tagset::SL::Multext - Driver for the Slovene tagset of the Multext-EAST v4 project.

=head1 VERSION

version 3.014

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::SL::Multext;
  my $driver = Lingua::Interset::Tagset::SL::Multext->new();
  my $fs = $driver->decode('Ncmsn');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('sl::multext', 'Ncmsn');

=head1 DESCRIPTION

Interset driver for the Slovene tagset of the Multext-EAST v4 project.
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
