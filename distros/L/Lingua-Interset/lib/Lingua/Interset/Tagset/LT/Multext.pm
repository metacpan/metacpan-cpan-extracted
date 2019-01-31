# ABSTRACT: Driver for the Lithuanian Multext-EAST-like tagset.
# Copyright © 2019 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::LT::Multext;
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
    return 'lt::multext';
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
            # examples: didelis, svarbus, tikras
            'g' => []
        },
        'encode_map' =>
        {
            'poss' => { '@' => 'g' }
        }
    );
    # DEFINITENESS ####################
    # In Lithuanian, this feature is presented as "pronominal suffix yes or no?"
    # Hence the short form (more frequent, indefinite) has 'n', the long form (pronominal, definite) 'y'.
    $atoms->{definite} = $self->create_atom
    (
        'surfeature' => 'definite',
        'decode_map' =>
        {
            # Nominal, short form of adjective. (NOTE: we are now reclassifying this as the indefinite form, see the feature of definiteness.)
            # examples: lietuviškas
            'n' => ['definite' => 'ind'],
            # Pronominal, long form of adjective. (NOTE: we are now reclassifying this as the definite form, see the feature of definiteness.)
            # examples: lietuviškasis
            'y' => ['definite' => 'def']
        },
        'encode_map' =>
        {
            'numform' => { 'digit' => '-',
                           'roman' => '-',
                           '@'     => { 'numtype' => { 'card' => '-',
                                                       'mult' => '-',
                                                       '@'    => { 'verbform' => { 'conv' => '-',
                                                                                   'ger'  => '-',
                                                                                   'gdv'  => '-',
                                                                                   'inf'  => '-',
                                                                                   'fin'  => '-',
                                                                                   '@'    => { 'definite' => { 'ind' => 'n',
                                                                                                               'def' => 'y',
                                                                                                               '@'   => 'n' }}}}}}}
        }
    );
    # CONJTYPE ####################
    $atoms->{conjtype} = $self->create_atom
    (
        'surfeature' => 'conjtype',
        'decode_map' =>
        {
            # general conjunction
            # examples: ir, kad, ar, kaip, o
            'g' => []
        },
        'encode_map' =>
        {
            'conjtype' => { '@' => 'g' }
        }
    );
    # INTTYPE ####################
    $atoms->{inttype} = $self->create_atom
    (
        'surfeature' => 'conjtype',
        'decode_map' =>
        {
            # general conjunction
            # examples: Na, Deja, O
            'g' => []
        },
        'encode_map' =>
        {
            'conjtype' => { '@' => 'g' }
        }
    );
    # NAME TYPE ####################
    $atoms->{nametype} = $self->create_simple_atom
    (
        'intfeature' => 'nametype',
        'simple_decode_map' =>
        {
            'f' => 'giv',
            's' => 'sur',
            'g' => 'geo'
        },
        'encode_default' => '-'
    );
    # PRONTYPE ####################
    $atoms->{prontype} = $self->create_atom
    (
        'surfeature' => 'prontype',
        'decode_map' =>
        {
            # general pronoun (unclassified)
            'g' => []
        },
        'encode_map' =>
        {
            'prontype' => { '@' => 'g' }
        }
    );
    # PARTTYPE ####################
    $atoms->{parttype} = $self->create_atom
    (
        'surfeature' => 'parttype',
        'decode_map' =>
        {
            # general particle (unclassified)
            'g' => []
        },
        'encode_map' =>
        {
            'parttype' => { '@' => 'g' }
        }
    );
    # ADPOSTYPE ####################
    $atoms->{adpostype} = $self->create_atom
    (
        'surfeature' => 'adpostype',
        'decode_map' =>
        {
            # general adposition (unclassified)
            'g' => []
        },
        'encode_map' =>
        {
            'adpostype' => { '@' => 'g' }
        }
    );
    # VERBTYPE ####################
    $atoms->{verbtype} = $self->create_atom
    (
        'surfeature' => 'verbtype',
        'decode_map' =>
        {
            # general verb (unclassified)
            'g' => []
        },
        'encode_map' =>
        {
            'verbtype' => { '@' => 'g' }
        }
    );
    # VERB FORM ####################
    $atoms->{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            'm' => ['verbform' => 'fin'],
            'i' => ['verbform' => 'inf'],
            # Vgp ... adjectival participle
            'p' => ['verbform' => 'part'],
            # Vga ... padalyvis ... adverbial participle describing an action performed by one that causes or otherwise relates to the action of another.
            #                       The subject of a padalyvis participle is required to be in the dative case.
            'a' => ['verbform' => 'gdv'],
            # Vgh ... pusdalyvis ... a special adverbial participle that is declined for number and gender
            #                       and describes secondary actions performed alongside primary actions.
            'h' => ['verbform' => 'conv'],
            # Vgb ... būdinys ... adverbial participle describing manner of action
            # Examples: prašyte, kniedyte
            'b' => ['verbform' => 'ger']
            # http://www.lituanus.org/1987/87_1_04.htm
            # dirbant - 'while working' ... padalyvis ... Vgap
            # dirbus - 'after having worked' ... padalyvis ... Vgaa
            # dirbdavus - 'after having worked frequently' ... padalyvis ... Vgaq
            # dirbsiant - 'having to work (yet)' ... padalyvis ... Vgaf
            # dirbdamas - 'while working' ... pusdalyvis ... Vgh
            # dirbtinas - 'one which still has to be worked' ... reikiamybės dalyvis
              # ... nurodo ypatybę, kylančią iš reikiamo atlikti veiksmo. Daromi iš bendraties kamieno, pridedant -tinas, -tina (skaitytinas, rašytina).
              #   = indicates a feature that arises from the required action. It is done from the common strain, adding tin, tina (readable, writable).
        },
        'encode_map' =>
        {
            'verbform' => { 'fin'  => 'm',
                            'inf'  => 'i',
                            'part' => 'p',
                            'conv' => 'h',
                            'gdv'  => 'a',
                            'ger'  => 'b' }
        }
    );
    # TENSE ####################
    $atoms->{tense} = $self->create_atom
    (
        'surfeature' => 'tense',
        'decode_map' =>
        {
            # esamasis laikas "does/is doing something"
            'p' => ['tense' => 'pres'],
            # būsimas laikas "will do something"
            'f' => ['tense' => 'fut'],
            # būtasis kartinis laikas "did something"
            'a' => ['tense' => 'past'],
            # būtasis dažninis laikas "used to do something"
            'q' => ['tense' => 'past', 'aspect' => 'hab'],
            # 's' is used with past passive participles but not for finite verbs.
            's' => ['tense' => 'past', 'aspect' => 'perf']
        },
        'encode_map' =>
        {
            'tense' => { 'pres' => 'p',
                         'fut'  => 'f',
                         'past' => { 'aspect' => { 'hab'  => 'q',
                                                   'iter' => 'q',
                                                   'perf' => 's',
                                                   '@'    => 'a' }},
                         '@'    => '-' }
        }
    );
    # REFLEXIVITY OF VERBS ####################
    $atoms->{reflex} = $self->create_atom
    (
        'surfeature' => 'reflex',
        'decode_map' =>
        {
            'y' => ['reflex' => 'yes']
        },
        'encode_map' =>
        {
            'reflex' => { 'yes' => 'y',
                          '@'   => 'n' }
        }
    );
    # MOOD ####################
    $atoms->{mood} = $self->create_simple_atom
    (
        'intfeature' => 'mood',
        'simple_decode_map' =>
        {
            'i' => 'ind',
            's' => 'sub',
            'm' => 'imp'
        },
        'encode_default' => '-'
    );
    # ABBRTYPE ####################
    $atoms->{abbrtype} = $self->create_atom
    (
        'surfeature' => 'abbrtype',
        'decode_map' =>
        {
            'a' => ['nountype' => 'prop'],
            's' => ['nountype' => 'com']
        },
        'encode_map' =>
        {
            'nountype' => { 'prop' => 'a',
                            '@'    => 's' }
        }
    );
    # NUMERAL TYPE ####################
    # Czech default is 'c', Lithuanian default should be '-'.
    $atoms->{numtype}{encode_map}{numtype}{'card'} = 'c';
    $atoms->{numtype}{encode_map}{numtype}{'@'} = '-';
    return $atoms;
}



#------------------------------------------------------------------------------
# Creates a map that tells for each surface part of speech which features are
# relevant and in what order they appear. The MULTEXT-EAST website does not
# document Lithuanian but the annotation manual supplied with v2.2 of the
# ALKSNIS treebank (http://hdl.handle.net/20.500.11821/20) has some documenta-
# tion (in Lithuanian only).
#------------------------------------------------------------------------------
sub _create_feature_map
{
    my $self = shift;
    my %features =
    (
        'N' => ['pos', 'nountype', 'gender', 'number', 'case', 'reflex', 'nametype'], # The last feature is often '-', sometimes 'g', 's' or 'f', and it occurs almost exclusively with proper nouns. My guess: 'f' is a personal first name; 's' is a surname; 'g' is a geographical name.
        'A' => ['pos', 'adjtype', 'degree', 'gender', 'number', 'case', 'definite'], # The last feature distinguishes the nominal, indefinite form 'n' from the pronominal, definite form 'y'.
        'P' => ['pos', 'prontype', 'gender', 'number', 'case', 'definite'], # They do not distinguish pronoun types. Everything is Pg*. They also do not distinguish person. The last feature is 'n', 'y' or '-'.
        'M' => ['pos', 'numtype', 'gender', 'number', 'case', 'numform', 'definite'], # The last feature is 'n', 'y' or '-'.
        'V' => ['pos', 'verbtype', 'verbform', 'tense', 'person', 'number', 'gender', 'voice', 'polarity', 'definite', 'case', 'reflex', 'mood', 'degree'], # Verb type is always 'g'. Last feature is 'p' for participles, '-' otherwise. But participles are already identified by 'p' in the third position. According to the documentation of the ALKSNIS treebank, the feature may mark the positive degree.
        'R' => ['pos', 'adverb_type', 'degree'],
        'S' => ['pos', 'adpostype', 'case'],
        'C' => ['pos', 'conjtype'], # just Cg
        'Q' => ['pos', 'parttype'], # just Qg
        'I' => ['pos', 'inttype'], # just Ig
        'X' => ['pos', 'restype'],
        'Y' => ['pos', 'abbrtype']
    );
    return \%features;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
Agcfpan
Agcfpgn
Agcfpin
Agcfpln
Agcfpnn
Agcfsan
Agcfsgn
Agcfsin
Agcfsnn
Agcfsny
Agcmpan
Agcmpgn
Agcmpin
Agcmpnn
Agcmsan
Agcmsay
Agcmsdn
Agcmsgn
Agcmsin
Agcmsln
Agcmsnn
Agp---n
Agpfpan
Agpfpay
Agpfpdn
Agpfpdy
Agpfpgn
Agpfpgy
Agpfpin
Agpfpiy
Agpfpln
Agpfpnn
Agpfpny
Agpfsan
Agpfsay
Agpfsdn
Agpfsdy
Agpfsgn
Agpfsgy
Agpfsin
Agpfsiy
Agpfsln
Agpfsly
Agpfsnn
Agpfsny
Agpmpan
Agpmpay
Agpmpdn
Agpmpdy
Agpmpgn
Agpmpgy
Agpmpin
Agpmpiy
Agpmpln
Agpmply
Agpmpnn
Agpmpny
Agpmsan
Agpmsay
Agpmsdn
Agpmsdy
Agpmsgn
Agpmsgy
Agpmsin
Agpmsiy
Agpmsln
Agpmsly
Agpmsnn
Agpmsny
Agpmsvn
Agpn--n
Agsfpan
Agsfpdn
Agsfpgn
Agsfpin
Agsfpln
Agsfpnn
Agsfsgn
Agsfsgy
Agsfsin
Agsfsln
Agsfsnn
Agsfsny
Agsmpan
Agsmpgn
Agsmpin
Agsmpnn
Agsmsan
Agsmsgn
Agsmsin
Agsmsnn
Agsn--n
Cg
Ig
M----d
M----r
Mc---l
Mc---l
Mc--gl
Mc--nl
Mcf-al
Mcf-dl
Mcf-gl
Mcf-il
Mcf-nl
Mcfpal
Mcfpgl
Mcfpnl
Mcfsal
Mcfsdl
Mcfsgl
Mcfsil
Mcfsnl
Mcm-al
Mcm-dl
Mcm-gl
Mcm-il
Mcm-nl
Mcmpal
Mcmpgl
Mcmpnl
Mcmsal
Mcmsgl
Mcmsnl
Mcnsnl
Mmf-nl
Mmm-al
Mmm-dl
Mmm-gl
Mmm-nl
Mofpily
Mofpnly
Mofsaly
Mofsamn
Mofsamy
Mofsgln
Mofsily
Mofslly
Mofsnln
Mofsnly
Mofsnmy
Mompgln
Mompgmy
Mompily
Momplly
Mompnln
Mompnly
Momsaln
Momsaly
Momsdln
Momsgln
Momsgly
Momslly
Momsnln
Momsnly
Mon--ln
Ncf--n
Ncfpan
Ncfpdn
Ncfpgn
Ncfpin
Ncfpln
Ncfpnn
Ncfpvn
Ncfsan
Ncfsdn
Ncfsgn
Ncfsin
Ncfsln
Ncfsnn
Ncfsvn
Ncm--n
Ncmpan
Ncmpdn
Ncmpgn
Ncmpgy
Ncmpin
Ncmpln
Ncmpnn
Ncmpny
Ncmpvn
Ncmsan
Ncmsay
Ncmsdn
Ncmsdy
Ncmsgn
Ncmsgy
Ncmsin
Ncmsiy
Ncmsln
Ncmsnn
Ncmsny
Ncmsvn
Np---n
Npfpan
Npfpgn
Npfpgng
Npfpln
Npfpnn
Npfsan
Npfsanf
Npfsang
Npfsdn
Npfsdnf
Npfsdng
Npfsdns
Npfsgn
Npfsgnf
Npfsgng
Npfsgns
Npfsin
Npfsinf
Npfsing
Npfsins
Npfsln
Npfslng
Npfsnn
Npfsnnf
Npfsnng
Npfsnns
Npm--nf
Npm--ns
Npmpgng
Npmplng
Npmpnns
Npms-nf
Npms-ns
Npmsan
Npmsanf
Npmsang
Npmsans
Npmsdnf
Npmsdng
Npmsdns
Npmsgn
Npmsgnf
Npmsgng
Npmsgns
Npmsinf
Npmsing
Npmsins
Npmsln
Npmslng
Npmsnn
Npmsnnf
Npmsnng
Npmsnns
Pg--an
Pg--dn
Pg--gn
Pg--in
Pg--nn
Pg-dnn
Pg-pan
Pg-pdn
Pg-pgn
Pg-pin
Pg-pln
Pg-pnn
Pg-san
Pg-sdn
Pg-sgn
Pg-sin
Pg-sln
Pg-snn
Pgf-an
Pgf-dn
Pgf-nn
Pgfdnn
Pgfpan
Pgfpdn
Pgfpgn
Pgfpin
Pgfpln
Pgfpnn
Pgfsan
Pgfsdn
Pgfsgn
Pgfsin
Pgfsln
Pgfsnn
Pgfsny
Pgm-an
Pgm-dn
Pgm-gn
Pgm-nn
Pgmdan
Pgmdgn
Pgmdnn
Pgmpan
Pgmpdn
Pgmpgn
Pgmpin
Pgmpln
Pgmpnn
Pgmsan
Pgmsdn
Pgmsgn
Pgmsin
Pgmsln
Pgmsnn
Pgmsny
Pgn--n
Qg
Rgc
Rgp
Rgs
Sga
Sgg
Sgi
Vgaa----n--n
Vgaa----n--y
Vgaa----y--n
Vgaa----y--y
Vgap----n--n
Vgap----n--y
Vgap----y--n
Vgap----y--y
Vgb-----n--n
Vgh--pf-n--n
Vgh--pf-y--n
Vgh--pm-n--n
Vgh--pm-n--y
Vgh--pm-y--n
Vgh--sf-n--n
Vgh--sf-n--y
Vgh--sf-y--n
Vgh--sm-n--n
Vgh--sm-n--y
Vgh--sm-y--n
Vgh--sm-y--y
Vgi-----n--n
Vgi-----n--y
Vgi-----y--n
Vgi-----y--y
Vgm-1p--n--nm
Vgm-1p--n--ns
Vgm-1p--y--nm
Vgm-1p--y--ys
Vgm-1s--n--ns
Vgm-1s--n--ys
Vgm-1s--y--ns
Vgm-2p--n--nm
Vgm-2p--n--ns
Vgm-2p--n--ym
Vgm-2p--n--ys
Vgm-2p--y--nm
Vgm-2p--y--ns
Vgm-2p--y--ym
Vgm-2s--n--nm
Vgm-2s--n--ns
Vgm-2s--n--ym
Vgm-2s--y--nm
Vgm-2s--y--ns
Vgm-3---n--ns
Vgm-3---n--ys
Vgm-3---y--ns
Vgm-3---y--ys
Vgm-3p--n--ns
Vgm-3p--n--ys
Vgm-3p--y--ns
Vgm-3p--y--ys
Vgm-3s--n--ns
Vgm-3s--n--ys
Vgm-3s--y--ns
Vgm-3s--y--ys
Vgma1p--n--ni
Vgma1p--n--yi
Vgma1p--y--ni
Vgma1p--y--yi
Vgma1s--n--ni
Vgma1s--n--yi
Vgma1s--y--ni
Vgma1s--y--yi
Vgma2p--n--ni
Vgma2p--n--yi
Vgma2p--y--ni
Vgma2s--n--ni
Vgma2s--n--yi
Vgma2s--y--ni
Vgma3---n--ni
Vgma3---n--yi
Vgma3---y--ni
Vgma3---y--yi
Vgma3p--n--ni
Vgma3p--n--yi
Vgma3p--y--ni
Vgma3p--y--yi
Vgma3s--n--ni
Vgma3s--n--yi
Vgma3s--y--ni
Vgma3s--y--yi
Vgmf1p--n--ni
Vgmf1p--n--yi
Vgmf1p--y--ni
Vgmf1s--n--ni
Vgmf1s--n--yi
Vgmf1s--y--ni
Vgmf2p--n--ni
Vgmf2p--n--yi
Vgmf2p--y--ni
Vgmf2s--n--ni
Vgmf2s--n--yi
Vgmf2s--y--ni
Vgmf2s--y--yi
Vgmf3---n--ni
Vgmf3---n--yi
Vgmf3---y--ni
Vgmf3p--n--ni
Vgmf3p--n--yi
Vgmf3p--y--ni
Vgmf3s--n--ni
Vgmf3s--n--yi
Vgmf3s--y--ni
Vgmf3s--y--yi
Vgmp1p--n--ni
Vgmp1p--n--yi
Vgmp1p--y--ni
Vgmp1p--y--yi
Vgmp1s--n--ni
Vgmp1s--n--yi
Vgmp1s--y--ni
Vgmp1s--y--yi
Vgmp2p--n--ni
Vgmp2p--n--yi
Vgmp2p--y--ni
Vgmp2p--y--yi
Vgmp2s--n--ni
Vgmp2s--n--yi
Vgmp2s--y--ni
Vgmp3---n--ni
Vgmp3---n--yi
Vgmp3---y--ni
Vgmp3---y--yi
Vgmp3p--n--ni
Vgmp3p--n--yi
Vgmp3p--y--ni
Vgmp3p--y--yi
Vgmp3s--n--ni
Vgmp3s--n--yi
Vgmp3s--y--ni
Vgmp3s--y--yi
Vgmq1p--n--ni
Vgmq1s--n--ni
Vgmq1s--n--yi
Vgmq1s--y--ni
Vgmq2p--y--ni
Vgmq2s--n--ni
Vgmq3---n--ni
Vgmq3p--n--ni
Vgmq3p--n--yi
Vgmq3s--n--ni
Vgmq3s--n--yi
Vgmq3s--y--ni
Vgpa--nann-n
Vgpa--nann-y
Vgpa--nayn-n
Vgpa-pfannan
Vgpa-pfannay
Vgpa-pfanngn
Vgpa-pfanngy
Vgpa-pfannin
Vgpa-pfannnn
Vgpa-pfannny
Vgpa-pfaynnn
Vgpa-pmannan
Vgpa-pmannay
Vgpa-pmanndn
Vgpa-pmanngn
Vgpa-pmanngy
Vgpa-pmannin
Vgpa-pmannnn
Vgpa-pmannny
Vgpa-pmanygn
Vgpa-pmanygy
Vgpa-pmanynn
Vgpa-pmaynnn
Vgpa-pmaynny
Vgpa-pmpnnnn
Vgpa-sfannan
Vgpa-sfannay
Vgpa-sfanndn
Vgpa-sfanngn
Vgpa-sfanngy
Vgpa-sfannin
Vgpa-sfannnn
Vgpa-sfannny
Vgpa-sfanynn
Vgpa-sfaynan
Vgpa-sfaynnn
Vgpa-sfpynln
Vgpa-smannan
Vgpa-smannay
Vgpa-smanndn
Vgpa-smanngn
Vgpa-smanngy
Vgpa-smannin
Vgpa-smanniy
Vgpa-smannln
Vgpa-smannnn
Vgpa-smannny
Vgpa-smanygn
Vgpa-smanyin
Vgpa-smanynn
Vgpa-smaynnn
Vgpf--nann-n
Vgpf-sfanngy
Vgpf-sfaynvy
Vgpf-smannln
Vgpf-smannnn
Vgpf-smpnnan
Vgpf-smpnndn
Vgpp--fpnn-n
Vgpp--npnn-n
Vgpp--npnn-y
Vgpp--npyn-n
Vgpp--npyn-y
Vgpp-pfannan
Vgpp-pfanndn
Vgpp-pfanngn
Vgpp-pfanngy
Vgpp-pfannin
Vgpp-pfannnn
Vgpp-pfannny
Vgpp-pfpnnan
Vgpp-pfpnndn
Vgpp-pfpnngn
Vgpp-pfpnnin
Vgpp-pfpnnln
Vgpp-pfpnnnn
Vgpp-pfpnnny
Vgpp-pfpnygn
Vgpp-pfpnyin
Vgpp-pfpynan
Vgpp-pfpyngn
Vgpp-pfpynin
Vgpp-pfpynnn
Vgpp-pmannan
Vgpp-pmannay
Vgpp-pmanndn
Vgpp-pmanngn
Vgpp-pmanngy
Vgpp-pmannin
Vgpp-pmannln
Vgpp-pmannnn
Vgpp-pmannny
Vgpp-pmanyan
Vgpp-pmaynan
Vgpp-pmayndn
Vgpp-pmayngn
Vgpp-pmaynin
Vgpp-pmaynnn
Vgpp-pmpnnan
Vgpp-pmpnndn
Vgpp-pmpnngn
Vgpp-pmpnnin
Vgpp-pmpnniy
Vgpp-pmpnnnn
Vgpp-pmpnyan
Vgpp-pmpnygn
Vgpp-pmpnyin
Vgpp-pmpynan
Vgpp-pmpyngn
Vgpp-pmpynnn
Vgpp-pmpyygn
Vgpp-sfannan
Vgpp-sfannay
Vgpp-sfanndn
Vgpp-sfanngn
Vgpp-sfanngy
Vgpp-sfannin
Vgpp-sfannln
Vgpp-sfannnn
Vgpp-sfannny
Vgpp-sfanyny
Vgpp-sfaynay
Vgpp-sfaynin
Vgpp-sfaynnn
Vgpp-sfpnnan
Vgpp-sfpnndn
Vgpp-sfpnngn
Vgpp-sfpnnin
Vgpp-sfpnnln
Vgpp-sfpnnnn
Vgpp-sfpnyan
Vgpp-sfpnygn
Vgpp-sfpnyin
Vgpp-sfpnynn
Vgpp-sfpyngn
Vgpp-sfpynnn
Vgpp-smannan
Vgpp-smanndy
Vgpp-smanngn
Vgpp-smannin
Vgpp-smannln
Vgpp-smannly
Vgpp-smannnn
Vgpp-smannny
Vgpp-smayngn
Vgpp-smaynin
Vgpp-smaynnn
Vgpp-smaynny
Vgpp-smpnnan
Vgpp-smpnndn
Vgpp-smpnngn
Vgpp-smpnnin
Vgpp-smpnnln
Vgpp-smpnnnn
Vgpp-smpnygn
Vgpp-smpnynn
Vgpp-smpynnn
Vgps--mpnngn
Vgps--npnn-n
Vgps--npnn-y
Vgps--npyn-n
Vgps-pfpnnan
Vgps-pfpnnay
Vgps-pfpnndn
Vgps-pfpnngn
Vgps-pfpnngy
Vgps-pfpnnin
Vgps-pfpnnln
Vgps-pfpnnnn
Vgps-pfpyngn
Vgps-pmpnnan
Vgps-pmpnnay
Vgps-pmpnndn
Vgps-pmpnngn
Vgps-pmpnnin
Vgps-pmpnnln
Vgps-pmpnnnn
Vgps-pmpnygn
Vgps-pmpnynn
Vgps-pmpynin
Vgps-pmpynnn
Vgps-sfpnn-n
Vgps-sfpnnan
Vgps-sfpnnay
Vgps-sfpnndn
Vgps-sfpnngn
Vgps-sfpnnin
Vgps-sfpnnln
Vgps-sfpnnly
Vgps-sfpnnnn
Vgps-sfpnynn
Vgps-sfpynan
Vgps-sfpyngn
Vgps-sfpynnn
Vgps-smpnnan
Vgps-smpnnay
Vgps-smpnndn
Vgps-smpnngn
Vgps-smpnnin
Vgps-smpnniy
Vgps-smpnnln
Vgps-smpnnnn
Vgps-smpnnny
Vgps-smpnynn
Vgps-smpynan
Vgps-smpyngn
Vgps-smpynnn
Vgps-snpnn-n
X
Xf
Xh
Ya
Ys
Z
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

Lingua::Interset::Tagset::LT::Multext - Driver for the Lithuanian Multext-EAST-like tagset.

=head1 VERSION

version 3.014

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
