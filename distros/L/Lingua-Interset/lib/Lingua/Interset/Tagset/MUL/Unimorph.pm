# ABSTRACT: Driver for the UniMorph features.
# https://unimorph.github.io/
# Copyright © 2023 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::MUL::Unimorph;
use strict;
use warnings;
our $VERSION = '3.016';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
use Lingua::Interset::FeatureStructure;
extends 'Lingua::Interset::Tagset';



has 'atoms' => ( isa => 'HashRef', is => 'ro', builder => '_create_atoms', lazy => 1 );



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'mul::unimorph';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for 11 surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # 0. DECODE ####################
    # In UniMorph, the decoding map is common for all features because the feature value knows to which feature/dimension it belongs.
    $atoms{unimorph} = $self->create_atom
    (
        'surfeature' => 'unimorph',
        'decode_map' =>
        {
            # 1. PART OF SPEECH ####################
            # noun
            'N'      => ['pos' => 'noun'],
            # proper noun
            'PROPN'  => ['pos' => 'noun', 'nountype' => 'prop'],
            # classifier
            'CLF'    => ['pos' => 'noun', 'nountype' => 'class'],
            # adjective
            'ADJ'    => ['pos' => 'adj'],
            # pronoun
            'PRO'    => ['pos' => 'noun', 'prontype' => 'prn'],
            # determiner
            'DET'    => ['pos' => 'adj', 'prontype' => 'prn'],
            # article
            'ART'    => ['pos' => 'adj', 'prontype' => 'art'],
            # (cardinal?) number
            'NUM'    => ['pos' => 'num', 'numtype' => 'card'],
            # verb
            'V'      => ['pos' => 'verb'],
            # masdar / verbal noun
            'V.MSDR' => ['pos' => 'verb', 'verbform' => 'vnoun'],
            # participle / verbal adjective
            'V.PTCP' => ['pos' => 'verb', 'verbform' => 'part'],
            # converb / verbal adverb
            'V.CVB'  => ['pos' => 'verb', 'verbform' => 'conv'],
            # auxiliary verb
            'AUX'    => ['pos' => 'verb', 'verbtype' => 'aux'],
            # auxiliary masdar / verbal noun
            'AUX.MSDR' => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'vnoun'],
            # auxiliary participle / verbal adjective
            'AUX.PTCP' => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'part'],
            # auxiliary converb / verbal adverb
            'AUX.CVB'  => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'conv'],
            # adverb
            'ADV'    => ['pos' => 'adv'],
            # preposition
            'ADP'    => ['pos' => 'adp'],
            # complementizer
            'COMP'   => ['pos' => 'conj', 'conjtype' => 'sub'],
            # conjunction
            'CONJ'   => ['pos' => 'conj'],
            # particle
            'PART'   => ['pos' => 'part'],
            # interjection
            'INTJ'   => ['pos' => 'int'],
            # 2. AKTIONSART ####################
            # stative
            'STAT'   => [],
            # dynamic
            'DYN'    => [],
            # telic
            'TEL'    => [],
            # atelic
            'ATEL'   => [],
            # punctual
            'PCT'    => [],
            # durative
            'DUR'    => [],
            # achievement
            'ACH'    => [],
            # accomplishment
            'ACCMP'  => [],
            # semelfactive
            'SEMEL'  => [],
            # activity
            'ACTY'   => [],
            # 3. ANIMACY ####################
            # animate
            'ANIM'   => ['animacy' => 'anim'],
            # inanimate
            'INAN'   => ['animacy' => 'inan'],
            # human
            'HUM'    => ['animacy' => 'hum'],
            # non-human
            'NHUM'   => ['animacy' => 'nhum'],
            # 5. ASPECT ####################
            # imperfective
            'IPFV'   => ['aspect' => 'imp'],
            # perfective
            'PFV'    => ['aspect' => 'perf'],
            # perfect
            'PRF'    => ['aspect' => 'perf'],
            # progressive
            'PROG'   => ['aspect' => 'prog'],
            # prospective
            'PROSP'  => ['aspect' => 'prosp'],
            # iterative
            'ITER'   => ['aspect' => 'iter'],
            # habitual
            'HAB'    => ['aspect' => 'hab'],
            # 6. CASE ####################
            # nominative (S, A)
            'NOM'    => ['case' => 'nom'],
            # nominative, S-only (S)
            'NOMS'   => ['case' => 'nom'],
            # accusative (P)
            'ACC'    => ['case' => 'acc'],
            # ergative (A)
            'ERG'    => ['case' => 'erg'],
            # absolutive (S, P)
            'ABS'    => ['case' => 'abs'],
            # dative (to, indirect object)
            'DAT'    => ['case' => 'dat'],
            # benefactive (beneficiary, a gift for someone)
            'BEN'    => ['case' => 'ben'],
            # purposive (for (profit e.g.))
            'PRP'    => ['case' => 'prp'],
            # genitive (of)
            'GEN'    => ['case' => 'gen'],
            # relative (marks possessor and A role; of)
            'REL'    => ['case' => 'rel'],
            # partitive (marks a patient as partially affected; some of)
            'PRT'    => ['case' => 'par'],
            # instrumental (means by which an action occurred; by, with, using)
            'INS'    => ['case' => 'ins'],
            # comitative (accompaniment; together with)
            'COM'    => ['case' => 'com'],
            # vocative (direct form of address)
            'VOC'    => ['case' => 'voc'],
            # comparative (standard of comparison; than)
            'COMPV'  => ['case' => 'cmp'],
            # equative (equality or similarity; as much as, like)
            'EQTV'   => ['case' => 'equ'],
            # privative, abessive (lack of something; without)
            'PRIV'   => ['case' => 'abe'],
            # proprietive (indicates quality of possessing something; having)
            'PROPR'  => ['case' => 'com'],
            # aversive (indicates what is to be feared, avoided; afraid of, dying from)
            'AVR'    => [],
            # formal (indicates something is function as something else; as something, in the capacity of something)
            'FRML'   => ['case' => 'ess'],
            # translative (indicates that an entity is the result of a transformation);
            'TRANS'  => ['case' => 'tra'],
            # essive-modal (indicates that a motion event occurs 'by way of' a location)
            'BYWAY'  => ['case' => 'ess'],
            # interessive (among)
            'INTER'  => [],
            # adessive (at)
            'AT'     => ['case' => 'ade'],
            # postessive (behind)
            'POST'   => [],
            # inessive (in)
            'IN'     => ['case' => 'ine'],
            # circumessive (near)
            'CIRC'   => [],
            # antessive (near, in front of)
            'ANTE'   => [],
            # apudessive (next to)
            'APUD'   => [],
            # superessive (on)
            'ON'     => ['case' => 'sup'],
            # (on, horizontal)
            'ONHR'   => [],
            # (on, vertical)
            'ONVR'   => [],
            # subessive (under)
            'SUB'    => ['case' => 'sub'],
            # distal
            'REM'    => [], ###!!! Deixis jsem přidal do UD, ale ne do Intersetu.
            # proximate
            'PROX'   => [], ###!!! Deixis jsem přidal do UD, ale ne do Intersetu.
            # "essive" (their definition corresponds to our locative, while our essive is their formal)
            'ESS'    => ['case' => 'loc'],
            # allative (their definition goes without specification whether the target is on/under/in something)
            'ALL'    => ['case' => 'all'],
            # ablative (their definition goes without specification whether the target is on/under/in something)
            'ABL'    => ['case' => 'abl'],
            # approximative (orthogonal to the other locational case meanings)
            'APPRX'  => [],
            # terminative
            'TERM'   => ['case' => 'ter'],
            # versative
            'VERS'   => [],
            # 7. COMPARISON ####################
            # comparative
            'CMPR'   => ['degree' => 'cmp'],
            # superlative
            'SPRL'   => ['degree' => 'sup'],
            # absolute (to be combined with superlative)
            'AB'     => ['degree' => 'abs'],
            # relative (to be combined with superlative)
            'RL'     => [],
            # equative
            'EQT'    => ['degree' => 'equ'],
            # 8. DEFINITENESS ####################
            # definite
            'DEF'    => ['definite' => 'def'],
            # indefinite
            'INDF'   => ['definite' => 'ind'],
            # specific
            'SPEC'   => ['definite' => 'spec'],
            # non-specific
            'NSPEC'  => ['definite' => 'spec'],
            # 9. DEIXIS ####################
            # proximate
            'PROX'   => [],
            # medial
            'MED'    => [],
            # remote
            'REMT'   => [],
            # first person reference point
            'REF1'   => [],
            # second person reference point
            'REF2'   => [],
            # no reference point, distal
            'NOREF'  => [],
            # phoric, situated in discourse
            'PHOR'   => [],
            # visible
            'VIS'    => [],
            # invisible
            'NVIS'   => [],
            # above
            'ABV'    => [],
            # even
            'EVEN'   => [],
            # below
            'BEL'    => [],
            # 10. EVIDENTIALITY ####################
            # firsthand
            'FH'     => ['evident' => 'fh'],
            # direct
            'DRCT'   => [],
            # sensory
            'SEN'    => [],
            # visual
            'VISU'   => [],
            # non-visual sensory
            'NVSEN'  => [],
            # auditory
            'AUD'   => [],
            # non-firsthand
            'NFH'   => ['evident' => 'nfh'],
            # quotative
            'QUOT'  => [],
            # reported
            'RPRT'  => [],
            # hearsay
            'HRSY'  => [],
            # inferred
            'INFER' => [],
            # assumed
            'ASSUM' => [],
            # 11. FINITENESS ##################################################
            # finite
            'FIN'   => ['verbform' => 'fin'],
            # nonfinite
            'NFIN'  => ['verbform' => 'inf'],
            # 12. GENDER AND NOUN CLASS #######################################
            # masculine
            'MASC'  => ['gender' => 'masc'],
            # feminine
            'FEM'   => ['gender' => 'fem'],
            # neuter
            'NEUT'  => ['gender' => 'neut'],
            # 13. INFORMATION STRUCTURE #######################################
            # topic
            'TOP'   => [],
            # focus
            'FOC'   => [],
            # 14. INTERROGATIVITY #############################################
            # declarative
            'DECL'  => [],
            # interrogative
            'INT'   => [],
            # 15. MOOD ########################################################
            # indicative
            'IND'   => ['mood' => 'ind'],
            # subjunctive
            'SBJV'  => ['mood' => 'sub'],
            # realis
            'REAL'  => ['mood' => 'ind'],
            # irrealis
            'IRR'   => ['mood' => 'irr'],
            # Australian purposive
            'AUPRP' => ['mood' => 'prp'],
            # Australian non-purposive
            'AUNPRP' => [],
            # imperative-jussive
            'IMP'   => ['mood' => 'imp'],
            # conditional
            'COND'  => ['mood' => 'cnd'],
            # general purposive ('in order to')
            'PURP'  => ['mood' => 'prp'],
            # intentive
            'INTEN' => ['mood' => 'des'],
            # potential
            'POT'   => ['mood' => 'pot'],
            # likely
            'LKLY'  => [],
            # admirative
            'ADM'   => ['mood' => 'adm'],
            # obligative
            'OBLIG' => ['mood' => 'nec'],
            # debitive
            'DEB'   => ['mood' => 'nec'],
            # permissive
            'PERM'  => ['mood' => 'pot'],
            # deductive
            'DED'   => [],
            # simulative
            'SIM'   => [],
            # optative-desiderative
            'OPT'   => ['mood' => 'opt'],
            # 16. NUMBER ######################################################
            # singular
            'SG'    => ['number' => 'sing'],
            # plural
            'PL'    => ['number' => 'plur'],
            # greater plural
            'GRPL'  => ['number' => 'grpl'],
            # dual
            'DU'    => ['number' => 'dual'],
            # trial
            'TRI'   => ['number' => 'tri'],
            # paucal
            'PAUC'  => ['number' => 'pauc'],
            # greater paucal
            'GPAUC' => ['number' => 'grpa'],
            # inverse
            'INVN'  => ['number' => 'inv'],
            # 17. PERSON ######################################################
            # impersonal
            '0'     => ['person' => '0'],
            # first
            '1'     => ['person' => '1'],
            # second
            '2'     => ['person' => '2'],
            # third
            '3'     => ['person' => '3'],
            # another third
            '4'     => ['person' => '4'],
            # inclusive
            'INCL'  => ['clusivity' => 'in'],
            # exclusive
            'EXCL'  => ['clusivity' => 'ex'],
            # proximate
            'PRX'  => [],
            # obviative
            'OBV'  => [],
            # 18. POLARITY ####################################################
            # positive
            'POS'  => ['polarity' => 'pos'],
            # negative
            'NEG'  => ['polarity' => 'neg'],
            # 19. POLITENESS ##################################################
            # informal
            'INFM' => ['polite' => 'infm'],
            # formal
            'FORM' => ['polite' => 'form'],
            # referent elevating
            'ELEV' => ['polite' => 'elev'],
            # speaker humbling
            'HUMB' => ['polite' => 'humb'],
            # polite (speaker-addressee axis)
            'POL'  => ['polite' => 'form'],
            # medium polite (speaker-addressee axis)
            'MPOL' => [],
            # avoidance style (speaker-bystander axis)
            'AVOID' => [],
            # low status (speaker-bystander axis)
            'LOW'  => [],
            # high status (speaker-bystander axis)
            'HIGH' => [],
            # elevated status (speaker-bystander axis)
            'STELV' => [],
            # supreme status (speaker-bystander axis)
            'STSUPR' => [],
            # literary register (speaker-setting axis)
            'LIT'    => ['style' => 'form'],
            # formal register (speaker-setting axis)
            'FOREG'  => ['style' => 'form'],
            # colloquial register (speaker-setting axis)
            'COL'    => ['style' => 'coll'],
            # 20. POSSESSION ##################################################
            'PSSD'   => ['poss' => 'yes'],
            # alienable possession
            'ALN'    => ['poss' => 'yes'],
            # inalienable possession
            'NALN'   => ['poss' => 'yes'],
            # cross-reference of the features of the possessor
            'PSS(MASC)'    => ['possgender' => 'masc'],
            'PSS(FEM)'     => ['possgender' => 'fem'],
            'PSS(NEUT)'    => ['possgender' => 'neut'],
            'PSS(SG;MASC)' => ['possgender' => 'masc', 'possnumber' => 'sing'],
            'PSS(SG;FEM)'  => ['possgender' => 'fem', 'possnumber' => 'sing'],
            'PSS(SG;NEUT)' => ['possgender' => 'neut', 'possnumber' => 'sing'],
            'PSS(SG)'      => ['possnumber' => 'sing'],
            'PSS(PL)'      => ['possnumber' => 'plur'],
            'PSS(PL;MASC)' => ['possgender' => 'masc', 'possnumber' => 'plur'],
            'PSS(PL;FEM)'  => ['possgender' => 'fem', 'possnumber' => 'plur'],
            'PSS(PL;NEUT)' => ['possgender' => 'neut', 'possnumber' => 'plur'],
            # 21. SWITCH-REFERENCE ############################################
            # SS
            'SS'     => [],
            # SS adverbial
            'SSADV'  => [],
            # DS
            'DS'     => [],
            # DS adverbial
            'DSADV'  => [],
            # 22. TENSE #######################################################
            # present
            'PRS'    => ['tense' => 'pres'],
            # past
            'PST'    => ['tense' => 'past'],
            # future
            'FUT'    => ['tense' => 'fut'],
            # immediate
            'IMMED'  => [],
            # hodiernal (today)
            'HOD'    => [],
            # within one day
            '1DAY'    => [],
            # recent
            'RCT'    => [],
            # remote
            'RMT'    => [],
            # 23. VALENCY #####################################################
            # impersonal
            'IMPRS'  => ['person' => '0'],
            # intransitive
            'INTR'   => ['subcat' => 'intr'],
            # transitive
            'TR'     => ['subcat' => 'tran'],
            # ditransitive
            'DITR'   => ['subcat' => 'tran'],
            # reflexive
            'REFL'   => ['reflex' => 'yes'],
            # reciprocal
            'RECP'   => ['voice' => 'rcp'],
            # causative
            'CAUS'   => ['voice' => 'cau'],
            # applicative
            'APPL'   => [],
            # 24. VOICE #######################################################
            # active
            'ACT'    => ['voice' => 'act'],
            # middle
            'MID'    => ['voice' => 'mid'],
            # passive
            'PASS'   => ['voice' => 'pass'],
            # antipassive
            'ANTIP'  => ['voice' => 'antip'],
            # direct
            'DIR'    => ['voice' => 'dir'],
            # inverse
            'INV'    => ['voice' => 'inv'],
            # agent focus
            'AGFOC'  => ['voice' => 'act'],
            # patient focus
            'PFOC'   => ['voice' => 'pass'],
            # location focus
            'LFOC'   => [],
            # beneficiary focus
            'BFOC'   => [],
            # accompanier focus
            'ACFOC'  => [],
            # instrument focus
            'IFOC'   => [],
            # conveyed focus
            'CFOC'   => [],
        },
        'encode_map' => {} # Unlike decoding, encoding can be solved per each feature/dimension.
    );
    # 2. PART OF SPEECH #######################################################
    $atoms{pos} = $self->create_atom
    (
        'surfeature' => 'pos',
        'decode_map' => {},
        'encode_map' =>

            { 'pos' => { 'noun' => { 'prontype' => { ''     => { 'nountype' => { 'prop' => 'PROPN',
                                                                                 '@'    => 'N' }},
                                                     '@'    => 'PRO' }},
                         'adj'  => { 'prontype' => { ''     => { 'verbform' => { 'part' => 'V.PTCP',
                                                                                 '@'    => 'ADJ' }},
                                                     '@'    => 'DET' }},
                         'num'  => 'NUM',
                         'verb' => { 'verbtype' => { 'aux'  => { 'verbform' => { 'part' => 'AUX.PTCP',
                                                                                 'conv' => 'AUX.CVB',
                                                                                 '@'    => 'AUX' }},
                                                     '@'    => { 'verbform' => { 'part' => 'V.PTCP',
                                                                                 'conv' => 'V.CVB',
                                                                                 '@'    => 'V' }}}},
                         'adv'  => 'ADV',
                         'adp'  => 'ADP',
                         'conj' => { 'conjtype' => { 'sub' => 'COMP',
                                                     '@'   => 'CONJ' }},
                         'part' => 'PART',
                         'int'  => 'INTJ' }}
    );
    # 3. GENDER ###############################################################
    $atoms{gender} = $self->create_atom
    (
        'surfeature' => 'gender',
        'decode_map' => {},
        'encode_map' =>

            { 'gender' => { 'masc' => 'MASC',
                            'fem'  => 'FEM',
                            'neut' => 'NEUT' }}
    );
    # 4. ANIMACY ##############################################################
    $atoms{animacy} = $self->create_simple_atom
    (
        'intfeature' => 'animacy',
        'simple_decode_map' =>
        {
            'ANIM' => 'anim',
            'INAN' => 'inan',
            'HUM'  => 'hum',
            'NHUM' => 'nhum'
        }
    );
    # 5. NUMBER ###############################################################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'SG'   => 'sing',
            'DU'   => 'dual',
            'TRI'  => 'tri',
            'PAUC' => 'pauc',
            'PL'   => 'plur'
        }
    );
    # 6. CASE #################################################################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'NOM' => 'nom',
            'GEN' => 'gen',
            'DAT' => 'dat',
            'ACC' => 'acc',
            'VOC' => 'voc',
            'ESS' => 'loc',
            'INS' => 'ins'
        }
    );
    # 7. PERSON ###############################################################
    $atoms{person} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            '0' => '0',
            '1' => '1',
            '2' => '2',
            '3' => '3'
        }
    );
    # 8. POLITENESS ###########################################################
    $atoms{polite} = $self->create_simple_atom
    (
        'intfeature' => 'polite',
        'simple_decode_map' =>
        {
            'INFM' => 'infm',
            'FORM' => 'form'
        }
    );
    # 9. FINITENESS ###########################################################
    $atoms{finiteness} = $self->create_atom
    (
        'surfeature' => 'finiteness',
        'decode_map' => {},
        'encode_map' =>

            { 'verbform' => { 'fin' => 'FIN',
                              'inf' => 'NFIN' }}
    );
    # 10. MOOD #################################################################
    $atoms{mood} = $self->create_simple_atom
    (
        'intfeature' => 'mood',
        'simple_decode_map' =>
        {
            'IND'  => 'ind',
            'IMP'  => 'imp',
            'SBJV' => 'sub',
            'COND' => 'cnd'
        }
    );
    # 11. ASPECT ###############################################################
    $atoms{aspect} = $self->create_atom
    (
        'surfeature' => 'aspect',
        'decode_map' => {},
        'encode_map' =>

            { 'aspect' => { 'imp'      => 'IPFV',
                            'perf'     => 'PFV' }}
    );
    # 12. TENSE ###############################################################
    $atoms{tense} = $self->create_atom
    (
        'surfeature' => 'tense',
        'decode_map' => {},
        'encode_map' =>

            { 'tense' => { 'past' => 'PST',
                           'fut'  => 'FUT',
                           'pres' => 'PRS' }}
    );
    # 13. DEGREE ##############################################################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'CMPR' => 'cmp',
            'SPRL' => 'sup'
        }
    );
    # 14. POLARITY ############################################################
    $atoms{polarity} = $self->create_atom
    (
        'surfeature' => 'polarity',
        'decode_map' => {},
        'encode_map' =>

            { 'polarity' => { 'pos' => 'POS',
                              'neg' => 'NEG' }}
    );
    # 15. VOICE ###############################################################
    $atoms{voice} = $self->create_atom
    (
        'surfeature' => 'voice',
        'decode_map' => {},
        'encode_map' =>

            { 'voice' => { 'act'  => 'ACT',
                           'pass' => 'PASS' }}
    );
    # 16. POSSESSOR'S GENDER AND NUMBER #######################################
    $atoms{possessor} = $self->create_atom
    (
        'surfeature' => 'possessor',
        'decode_map' => {},
        'encode_map' =>

            { 'possnumber' => { 'sing' => { 'possgender' => { 'masc' => 'PSS(SG;MASC)',
                                                              'fem'  => 'PSS(SG;FEM)',
                                                              'neut' => 'PSS(SG;NEUT)',
                                                              '@'    => 'PSS(SG)' }},
                                'plur' => { 'possgender' => { 'masc' => 'PSS(PL;MASC)',
                                                              'fem'  => 'PSS(PL;FEM)',
                                                              'neut' => 'PSS(PL;NEUT)',
                                                              '@'    => 'PSS(PL)' }},
                                '@'    => { 'possgender' => { 'masc' => 'PSS(MASC)',
                                                              'fem'  => 'PSS(FEM)',
                                                              'neut' => 'PSS(NEUT)' }}}}
    );
    return \%atoms;
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
    $fs->set_tagset('mul::unimorph');
    # There is a string of feature values, separated by semicolons. The order of
    # the features is not significant, except that the main part of speech always
    # comes first. Since UniMorph 4.0, the string can be organized hierarchically.
    # For example, the possessor's features may be grouped under PSS:
    # N;SG;PSSD;PSS(3;SG;FEM)
    my @features;
    while($tag =~ s/(PSS\([A-Z0-9]+(;[A-Z0-9]+)*\))//)
    {
        push(@features, $1);
        $tag =~ s/^;//;
        $tag =~ s/;$//;
        $tag =~ s/;+/;/g;
    }
    push(@features, split(/;/, $tag));
    my $atoms = $self->atoms();
    foreach my $feature (@features)
    {
        $atoms->{unimorph}->decode_and_merge_hard($feature, $fs);
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
    my @features;
    foreach my $f (qw(pos voice finiteness mood aspect tense person polite gender animacy number case polarity degree possessor))
    {
        die("Missing atom for '$f'") if(!exists($atoms->{$f}));
        my $umfeature = $atoms->{$f}->encode($fs);
        if(defined($umfeature) && $umfeature ne '' && !grep {$_ eq $umfeature} (@features))
        {
            push(@features, $umfeature);
        }
    }
    my $tag = join(';', @features);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags. In the specific case of UniMorph, we
# generate a long list of plausible feature combinations but it is not an
# exhaustive list. In theory, no combination of features can be excluded.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my %values =
    (
        'pos'      => ['N', 'PROPN', 'CLF', 'PRO', 'ADJ', 'ART', 'DET', 'NUM', 'V', 'AUX', 'ADV', 'ADP', 'CONJ', 'PART', 'INTJ'],
        'mood'     => ['IND', 'IMP', 'COND'],
        'aspect'   => ['IPFV', 'PFV'],
        'tense'    => ['PST', 'PRS', 'FUT'],
        'person'   => ['0', '1', '2', '3'],
        'gender'   => ['MASC', 'FEM', 'NEUT'],
        'animacy'  => ['ANIM', 'INAN', 'HUM', 'NHUM'],
        'number'   => ['SG', 'PL', 'DU', 'TRI', 'PAUC'],
        'case'     => ['NOM', 'ACC', 'GEN', 'DAT', 'VOC', 'ESS', 'INS'],
        'polarity' => ['POS', 'NEG'],
        'degree'   => ['CMPR', 'SPRL']
    );
    my %dimensions =
    (
        'N'     => ['gender', 'animacy', 'number', 'case', 'polarity'],
        'PROPN' => ['gender', 'animacy', 'number', 'case', 'polarity'],
        'ADJ'   => ['gender', 'animacy', 'number', 'case', 'polarity', 'degree'],
        'V'     => ['mood', 'aspect', 'tense', 'person', 'number', 'polarity'],
        'AUX'   => ['mood', 'aspect', 'tense', 'person', 'number', 'polarity'],
        'ADV'   => ['polarity', 'degree']
    );
    my @list = ();
    foreach my $pos (qw(N PROPN ADJ V AUX ADV))
    {
        my @dimensions = @{$dimensions{$pos}};
        $self->generate_list_recursive(\@list, \%values, [$pos], @dimensions);
    }
    return \@list;
}



#------------------------------------------------------------------------------
# The recursive part of generating plausible combinations of UniMorph features.
#------------------------------------------------------------------------------
sub generate_list_recursive
{
    my $self = shift;
    my $list = shift;
    my $values = shift;
    my $fixed_values = shift;
    my @dimensions = @_;
    my $current_dimension = shift(@dimensions);
    # Specifically in Slavic languages, animacy makes sense only with masculine
    # gender. I am manipulating the algorithm to reflect this, although it will
    # not work in other languages (some of them will distinguish only animacy
    # but not gender). But it does not matter much because the list() is only
    # for test purposes and it is not exhaustive anyway.
    if($current_dimension eq 'animacy' && !grep {$_ eq 'MASC'} (@{$fixed_values}))
    {
        $current_dimension = shift(@dimensions);
    }
    foreach my $value (@{$values->{$current_dimension}})
    {
        my @fixed_values = @{$fixed_values};
        push(@fixed_values, $value);
        if(scalar(@dimensions) > 0)
        {
            $self->generate_list_recursive($list, $values, \@fixed_values, @dimensions);
        }
        else
        {
            push(@{$list}, join(';', @fixed_values));
        }
    }
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::MUL::Unimorph - Driver for the UniMorph features.

=head1 VERSION

version 3.016

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::MUL::Unimorph;
  my $driver = Lingua::Interset::Tagset::MUL::Unimorph->new();
  my $fs = $driver->decode("N;MASC;ANIM;SG;NOM;POS");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('mul::unimorph', "N;MASC;SG;NOM");

=head1 DESCRIPTION

Interset driver for UniMorph 4.0 feature strings,
see L<https://unimorph.github.io/>.

=head1 SEE ALSO

L<Lingua::Interset>
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::MUL::Uposf>,
L<Lingua::Interset::Atom>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
