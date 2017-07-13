# ABSTRACT: Driver for the tagset of the Persian Dependency Treebank (in the CoNLL-X format).
# Copyright © 2012, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::FA::Conll;
use strict;
use warnings;
our $VERSION = '3.006';

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
    return 'fa::conll';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
# Tagset documentation is at
# https://wiki.ufal.ms.mff.cuni.cz/_media/user:zeman:treebanks:persian-dependency-treebank-version-0.1-annotation-manual-and-user-guide.pdf
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # PART OF SPEECH ####################
    $atoms{pos} = $self->create_atom
    (
        'tagset' => 'fa::conll',
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # This table uses pos and subpos (the CPOS and POS columns of the CoNLL format) as input.
            # coarse ADJ: adjective
            "ADJ\tAJP"    => ['pos' => 'adj', 'degree' => 'pos'], # dígr, islámí, bzrg, jdíd, mxtlf
            "ADJ\tAJCM"   => ['pos' => 'adj', 'degree' => 'cmp'], # bíštr, bíš, bhtr, bíštrí, kmtr
            "ADJ\tAJSUP"  => ['pos' => 'adj', 'degree' => 'sup'], # bhtrín, mhmtrín, bzrgtrín, bíštrín, qwítrín
            "ADJ\t_"      => ['pos' => 'adj'], # wláyí, xúdsáxte, wárd, xúbí (undocumented)
            # coarse ADR: address term
            # pre-noun morpheme to "make the noun the address of the speaker" (i.e. an interjection introducing a vocative phrase?)
            # í = hey!, hallo!; yá = or (???); áháí = hey!
            "ADR\tPRADR"  => ['pos' => 'int', 'case' => 'voc', 'other' => {'side' => 'pre'}],
            # post-noun morpheme to "make the noun the address of the speaker"
            # only "á", sometimes (15 times) as a bound morpheme, sometimes (3 times) as an isolated word
            "ADR\tPOSADR" => ['pos' => 'int', 'case' => 'voc', 'other' => {'side' => 'post'}],
            # coarse ADV
            "ADV\tSADV"   => ['pos' => 'adv'], # hm, níz, htí, ne, xílí (genuine adverbs)
            "ADV\tAVP"    => ['pos' => 'adv', 'degree' => 'pos'], # hm, tnhá, dígr, xúb, ps (positive adjectives modifying verbs)
            "ADV\tAVCM"   => ['pos' => 'adv', 'degree' => 'cmp'], # bíštr, bíš, kmtr, bhtr, zúdtr (comparative adjectives modifying verbs)
            "ADV\tAVSUP"  => ['pos' => 'adv', 'degree' => 'sup'], # dúbáre
            # coarse CL (undocumented)
            "CL\tMEAS"    => ['pos' => 'noun'], # kílú (only one occurrence of this one word form) + one N MEAS: qášq
            # coarse CONJ: coordinating conjunction
            "CONJ\tCONJ"  => ['pos' => 'conj', 'conjtype' => 'coor'], # w, yá, amá, wlí, ke
            # coarse IDEN
            "IDEN\tIDEN"  => ['pos' => 'noun', 'other' => {'nountype' => 'title'}], # imám, dktr, šhíd, síd, áytalláh (titles used with personal names)
            # coarse N: noun
            "N\tANM"      => ['pos' => 'noun', 'animacy' => 'anim'], # xdá, ksí, ansán, xadáwand, nfr
            "N\tIANM"     => ['pos' => 'noun', 'animacy' => 'inan'], # sál, kár, írán, rúz, dst
            # coarse PART: particle
            "PART\tPART"  => ['pos' => 'part'], # áyá, ke, mgr, rá, dígr
            # coarse POSNUM: number following a noun
            "POSNUM\tPOSNUM" => ['pos' => 'num', 'other' => {'numtype' => 'post'}], # awl, dúm, súm, čhárm, nxst (post-noun numeral)
            # coarse POSTP: postposition
            "POSTP\tPOSTP" => ['pos' => 'adp', 'adpostype' => 'post'], # rá, čún, az, rfte, mrá
            # coarse PR: pronoun
            "PR\tSEPER"   => ['pos' => 'noun', 'prontype' => 'prs'], # mn, tú, aw, má, šmá, ánhá (separate personal pronoun)
            "PR\tJOPER"   => ['pos' => 'noun', 'prontype' => 'prs', 'variant' => 'short'], # m, t, š, mán, tán, šán (enclitic personal pronoun)
            "PR\tDEMON"   => ['pos' => 'noun', 'prontype' => 'dem'], # án, ín, hmín, čnán, ánjá (demonstrative pronoun)
            "PR\tINTG"    => ['pos' => 'noun', 'prontype' => 'int'], # če, kjá, čgúne, čí, črá (interrogative pronoun)
            "PR\tCREFX"   => ['pos' => 'noun', 'prontype' => 'prs', 'reflex' => 'yes'], # xod, xwíš, hm, ykdígr, hmdígr (common reflexive pronoun)
            "PR\tUCREFX"  => ['pos' => 'noun', 'prontype' => 'prs', 'reflex' => 'yes'], # (noncommon reflexive pronoun: not present in data)
            "PR\tRECPR"   => ['pos' => 'noun', 'prontype' => 'rcp'], # (reciprocal pronoun: not present in data)
            "PR\t_"       => ['pos' => 'noun', 'prontype' => 'prs'], # hm, ykdígr, hmdígr, xúdš, xúdšán ###!!! The '_' fine POS also occurs with adjectives!
            # coarse PREM (pre-modifier of nouns, i.e. determiner?)
            # exclamatory determiner: expresses speaker's surprise towards the modified noun ("WHAT a surprise!")
            # če = what, čqdr = how much, how many, án = it, čnd = several, ajb = wonder, surprise
            "PREM\tEXAJ"  => ['pos' => 'adj', 'prontype' => 'exc'],
            # interrogative determiner
            # če = what, kdám = which, čnd = several, kdámín = what
            "PREM\tQUAJ"  => ['pos' => 'adj', 'prontype' => 'int'],
            # demonstrative determiner
            # ín = this, án = it, hmán = same, hmín = same, čnín = such
            "PREM\tDEMAJ" => ['pos' => 'adj', 'prontype' => 'dem'],
            # "ambiguous" (per the documentation) => total, indefinite or negative determiner
            # hr = each/any/every, čnd = several/a few, híč = any/no/none, brxí = some, hme = all/every
            "PREM\tAMBAJ" => ['pos' => 'adj', 'prontype' => 'tot|ind|neg'],
            # coarse PRENUM (pre-noun numeral)
            "PRENUM\tPRENUM" => ['pos' => 'num', 'other' => {'numtype' => 'pre'}], # ek, do, se, úlín, čhár
            # coarse PREP: preposition
            "PREP\tPREP"  => ['pos' => 'adp', 'adpostype' => 'prep'], # be, dr, az, bá, bráí
            "PREP\tPOST"  => ['pos' => 'adp', 'adpostype' => 'post'], # zmn
            "PREP\tPOSTP" => ['pos' => 'adp', 'adpostype' => 'post'], # ps
            # coarse PSUS (pseudo-sentence; instead of verb)
            # káš = if; ne = not; angár = if; yacní = namely; bale = yes
            "PSUS\tPSUS"  => ['pos' => 'part', 'parttype' => 'mod'], # káš, ne, angár, ya'aní, ble
            # coarse PUNC: punctuation
            "PUNC\tPUNC"  => ['pos' => 'punc'], # ., ,, ?, !, "
            # coarse V: verb
            "V\tACT"      => ['pos' => 'verb', 'voice' => 'act'], # míknnd, hstnd, dárnd, mídhnd, mítwánnd
            "V\tPASS"     => ['pos' => 'verb', 'voice' => 'pass'], # míšúnd, šde, dádemíšúnd, zádemíšúnd, gdárdemíšúnd
            "V\tMODL"     => ['pos' => 'verb', 'verbtype' => 'mod'], # báyd, nbáyd, mítwán, nmítwánd, míšúd
            # coarse SUBR (subordinating conjunction)
            "SUBR\tSUBR"  => ['pos' => 'conj', 'conjtype' => 'sub'], # ke, agr, tá, zírá, čún
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { 'prs' => { 'reflex' => { 'yes' => "PR\tCREFX",
                                                                            '@'      => { 'variant' => { 'short' => "PR\tJOPER",
                                                                                                         '@'     => "PR\tSEPER" }}}},
                                                   'rcp' => "PR\tRECPR",
                                                   'dem' => "PR\tDEMON",
                                                   'int' => "PR\tINTG",
                                                   '@'   => { 'other/nountype' => { 'title' => "IDEN\tIDEN",
                                                                                    '@'     => { 'animacy' => { 'anim' => "N\tANM",
                                                                                                                '@'    => "N\tIANM" }}}}}},
                       'adj'  => { 'prontype' => { 'dem' => "PREM\tDEMAJ",
                                                   'int' => "PREM\tQUAJ",
                                                   'exc' => "PREM\tEXAJ",
                                                   'tot' => "PREM\tAMBAJ",
                                                   'ind' => "PREM\tAMBAJ",
                                                   'neg' => "PREM\tAMBAJ",
                                                   '@'   => { 'degree' => { 'sup' => "ADJ\tAJSUP",
                                                                            'cmp' => "ADJ\tAJCM",
                                                                            '@'   => "ADJ\tAJP" }}}},
                       'num'  => { 'other/numtype' => { 'post' => "POSNUM\tPOSNUM",
                                                        '@'    => "PRENUM\tPRENUM" }},
                       'verb' => { 'verbtype' => { 'mod' => "V\tMODL",
                                                   '@'   => { 'voice' => { 'pass' => "V\tPASS",
                                                                           '@'    => "V\tACT" }}}},
                       'adv'  => { 'degree' => { 'pos' => "ADV\tAVP",
                                                 'cmp' => "ADV\tAVCM",
                                                 'sup' => "ADV\tAVSUP",
                                                 '@'   => "ADV\tSADV" }},
                       'adp'  => { 'adpostype' => { 'post' => "POSTP\tPOSTP",
                                                    '@'    => "PREP\tPREP" }},
                       'conj' => { 'conjtype' => { 'sub' => "SUBR\tSUBR",
                                                   '@'   => "CONJ\tCONJ" }},
                       'part' => { 'parttype' => { 'mod' => "PSUS\tPSUS",
                                                   '@'   => "PART\tPART" }},
                       'punc' => "PUNC\tPUNC",
                       'int'  => { 'other/side' => { 'post' => "ADR\tPOSADR",
                                                     '@'    => "ADR\tPRADR" }}}
        }
    );
    # ATTACHMENT TYPE ####################
    # Orthographic words may have been broken into parts during tokenization in order to show syntactic relations between morphemes. Examples:
    # didämäš => didäm|äš (äš is object of the verb didäm)
    # mära => mä (contracted form of the personal pronoun män) | ra (postposition, could play object or complement adposition of the verb)
    # The attachment feature makes restoration of orthographic words possible.
    $atoms{attachment} = $self->create_atom
    (
        'tagset' => 'fa::conll',
        'surfeature' => 'attachment',
        'decode_map' =>
        {
            'ISO' => ['other' => {'attachment' => 'isolated'}], # isolated word
            'PRV' => ['other' => {'attachment' => 'previous'}], # attached to the previous word
            'NXT' => ['other' => {'attachment' => 'next'}]  # attached to the next word
        },
        'encode_map' =>
        {
            'other/attachment' => { 'isolated' => 'ISO',
                                    'previous' => 'PRV',
                                    'next'     => 'NXT',
                                    '@'        => 'ISO' }
        }
    );
    # PERSON ####################
    $atoms{person} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            '1' => '1', # mn, xúdm, án, má, xúdmán
            '2' => '2', # tú, xúdt, šmá, xúdtán, šmáhá
            '3' => '3'  # ú, án, ín, ánhá, ánán
        }
    );
    # NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'SING' => 'sing', # xdá, ksí, ansán, xdáwnd, nfr
            'PLUR' => 'plur'  # mrdm, ksání, dígrán, afrád, znán
        }
    );
    # VERB FORM, MOOD, TENSE AND ASPECT ####################
    # Here is a website that helps understand Persian verb forms: http://www.jahanshiri.ir/pvc/en/
    # Some of the examples below are from the website, some from the PDF documentation of the treebank and some directly from the data.
    # The transliterations of the three sources differ.
    $atoms{tma} = $self->create_atom
    (
        'surfeature' => 'tma',
        'decode_map' =>
        {
            # There are 12 past tenses in Persian. Even some (not all) periphrastic tenses have their dedicated tags because
            # the participating verb forms are put together in one token in the treebank. Progressive tenses with the auxiliary
            # verb dáštan (to have) are not tagged, the auxiliary verb is tokenized separately (but note that some other tenses,
            # that are not called progressive in Persian, partially cover the meaning of the English continuous/progressive tenses).
            # The remaining past tenses can be classified along three dimensions:
            # aspect (normal vs. imperfect); narativeness; precedent vs. non-precedent
            # The tenses that are called narrative in Persian grammar roughly correspond to the English present perfect.
            # The tenses that are called precedent in Persian grammar roughly correspond to the English past perfect.
            # Example verb is xordän = to eat.
            # Simple past (indicative preterite)
            # xordäm = I ate
            # past stem + past ending
            # raftam = I went; rafti = you went; raft = he went; raftim = we went; raftid = you went; raftand = they went
            # Treebank examples: krd = did; búd = was; dášt = had
            'GS'    => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'past', 'aspect' => 'perf'],
            # Narrative past (indicative perfect)
            # xordeäm = I have eaten
            # past participle + past ending
            # rafteam = I have gone; raftei = you have gone; rafte = he has gone; rafteim = we have gone; rafteid = you have gone; rafteand = they have gone
            # Án ketáb rá čand bár xwándeam. = I have read that book several times.
            # Treebank examples: krde ast = he has been; krde = he has been; ámde ast = he has come
            'GN'    => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'past', 'evident' => 'nfh', 'aspect' => 'perf'],
            # Precedent past (indicative pluperfect)
            # xorde budäm = I had eaten
            # past participle of main verb + past simple of auxiliary budan (to be)
            # rafte budam = I had gone; rafte budi = you had gone; rafte bud = he had gone; rafte budim = we had gone; rafte budid = you had gone; rafte budand = they have gone
            # Vaght-i ke residim, ánhá rafte budand. = By the time we arrived, they had gone.
            # Treebank examples: krde búd = he had been; dáde búd = he had been; zde búd = he had struck
            'GB'    => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pqp',  'aspect' => 'perf'],
            # Past imperfect (indicative imperfective preterite)
            # mixordäm = I was eating
            # mi + past stem + past ending
            # miraftam; mirafti; miraft; miraftim; miraftid; miraftand
            # Hamiše mixwást engelisi yád begirad. = He always wanted to learn English.
            # Treebank examples: míkrd = would, was; mízd = drew, played; mídád = would, was
            'GES'   => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'past', 'aspect' => 'imp'],
            # Narrative imperfect (indicative imperfective perfect?)
            # mixordeäm = I have been eating
            # mi + past participle + past ending
            # mirafteam; miraftei; mirafte; mirafteim; mirafteid; mirafteand
            # Engelisi mixwánde? = Has she been studying English?
            # Treebank examples: míkrde ast = he has been, he have had; mídánste = he knew; míkrde = he did
            'GNES'  => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'past', 'evident' => 'nfh', 'aspect' => 'imp'],
            # Precedent imperfect (indicative imperfective pluperfect)
            # mixorde budäm = I had been eating
            # mi + past participle of main verb + past simple of auxiliary budan (to be)
            # mirafte budam; mirafte budi; mirafte bud; mirafte budim; mirafte budid; mirafte budand
            # No treebank examples found.
            'GBES'  => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pqp',  'aspect' => 'imp'],
            # Indicative present
            # mixoräm = I am eating, I eat
            # am = I am; i = you are; ast = he is; im = we are; id = you are; and = they are
            # dáram = I have; dári = you have; dárad = he has; dárim = we have; dárid = you have; dárand = they have
            # mibandam = I close; mibandi = you close; mibandad = he closes; mibandim = we close; mibandid = you close; mibandand = they close
            # Treebank examples: ast = he is; míknd = he does; dárd = it has, there is
            'H'     => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres', 'aspect' => 'imp'],
            # Indicative future (simple)
            # xahäm xord = I will eat
            # auxiliary verb xwástan (to want) in present simple + main verb in apocopated infinitive
            # xwáham raft = I will go; xwáhi raft = you will go; xwáhad raft = he will go; xwáhim raft = we will go; xwáhid raft = you will go; xwáhand raft = they will go
            # Treebank examples: xwáhd krd = he will do; xwáhd šd = he will be; xwáhd búd = he will/would be; xwáhd dád = he will give
            'AY'    => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'fut'],
            # Imperative
            # boxor = eat
            # It is made from subjunctive present simple.
            # benevis = write!; benevisim = let's write!; benevisid = write!
            # Treebank examples: kn = do; báš = remember; bgw = tell
            'HA'    => ['verbform' => 'fin', 'mood' => 'imp'],
            # Subjunctive past simple/narrative (subjunctive preterite)
            # xorde bašäm ~ I would have eaten
            # past participle of main verb + auxiliary verb budan (to be) in subjunctive present simple
            # rafte bášam ~ I would have gone; rafte báši; rafte bášad; rafte bášim; rafte bášid; rafte bášand
            # Treebank examples: krde bášd; dášte bášd; dáde bášd
            'GEL'   => ['verbform' => 'fin', 'mood' => 'sub', 'tense' => 'past', 'aspect' => 'perf'],
            # Subjunctive precedent narrative (subjunctive pluperfect)
            # xorde bude bašäm ~ I would have had eaten
            # past participle of main verb + auxiliary verb budan (to be) in subjunctive past narrative
            # rafte bude bášam ~ I would have had gone; rafte bude báši; rafte bude bášad; rafte bude bášim; rafte bude bášid; rafte bude bášand
            # No treebank examples found.
            'GBEL'  => ['verbform' => 'fin', 'mood' => 'sub', 'tense' => 'pqp',  'aspect' => 'perf'],
            # Subjunctive past narrative imperfect (subjunctive imperfective preterite)
            # mixorde bašäm ~ I would have been eating
            # mi + past participle of main verb + auxiliary verb budan (to be) in subjunctive present simple
            # mirafte bášam ~ I would have been going; mirafte báši; mirafte bášad; mirafte bášim; mirafte bášid; mirafte bášand
            # Treebank example: brmígrdánídm
            'GESEL' => ['verbform' => 'fin', 'mood' => 'sub', 'tense' => 'past', 'aspect' => 'imp'],
            # Subjunctive past precedent narrative imperfect (subjunctive imperfective pluperfect)
            # mixorde bude bašäm ~ I would have had been eating
            # mi + past participle of main verb + auxiliary verb budan (to be) in subjunctive past narrative
            # mirafte bude bášam ~ I would have had been going; mirafte bude báši; mirafte bude bášad; mirafte bude bášim; mirafte bude bášid; mirafte bude bášand
            # Treebank example: bde (???)
            'GBESE' => ['verbform' => 'fin', 'mood' => 'sub', 'tense' => 'pqp',  'aspect' => 'imp'],
            # Subjunctive present
            # boxoräm = I would eat
            # be + present stem + present ending (but the "be-" prefix is often omitted in light-verb constructions)
            # benevisam = I would write; benevisi = you would write; benevisad = he would write; benevisim = we would write; benevisid = you would write; benevisand = they would write
            # Treebank examples: knd = he would do; bášd = he would be; bknd = he would do; dárd = there would be; dhd = he would give
            'HEL'   => ['verbform' => 'fin', 'mood' => 'sub', 'tense' => 'pres'],
        },
        'encode_map' =>
        {
            'mood' => { 'imp' => 'HA',
                        'sub' => { 'tense' => { 'pres' => 'HEL',
                                                'past' => { 'aspect' => { 'imp' => 'GESEL',
                                                                          '@'   => 'GEL' }},
                                                'pqp'  => { 'aspect' => { 'imp' => 'GBESE',
                                                                          '@'   => 'GBEL' }}}},
                        '@'   => { 'tense' => { 'fut'  => 'AY',
                                                'pres' => 'H',
                                                'past' => { 'evident' => { 'nfh' => { 'aspect' => { 'imp' => 'GNES',
                                                                                                    '@'   => 'GN' }},
                                                                           '@'   => { 'aspect' => { 'imp' => 'GES',
                                                                                                    '@'   => 'GS' }}}},
                                                'pqp'  => { 'aspect' => { 'imp'  => 'GBES',
                                                                          '@'    => 'GB' }}}}}
        }
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
    my @features = ('person', 'attachment', 'number', 'tma');
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
        'NC' => ['gender', 'number', 'case', 'def'],
        'V.gerund' => ['mood', 'number', 'gender', 'definiteness', 'case']
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
    my $fs = $self->decode_conll($tag, 'both');
    # Default feature values. Used to improve collaboration with other drivers.
    # ... nothing yet ...
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
    my ($pos, $subpos) = split(/\t/, $atoms->{pos}->encode($fs));
    my $fpos = $subpos;
    my $feature_names = $self->features_all(); ###!!!$self->get_feature_names($fpos);
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus, 880 distinct tags found:
# Returns reference to list of known tags.
# cat train.conll test.conll |\
#   perl -pe '@x = split(/\s+/, $_); $_ = "$x[3]\t$x[4]\t$x[5]\n"' |\
#   sort -u | wc -l
# 880
# 271 after cleaning and adding 'other'-resistant tags
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
ADJ	AJCM	attachment=ISO
ADJ	AJCM	attachment=NXT
ADJ	AJP	attachment=ISO
ADJ	AJP	attachment=ISO|number=SING
ADJ	AJP	attachment=NXT
ADJ	AJP	attachment=PRV
ADJ	AJSUP	attachment=ISO
ADR	POSADR	attachment=ISO
ADR	POSADR	attachment=PRV
ADR	PRADR	attachment=ISO
ADV	AVCM	attachment=ISO
ADV	AVP	attachment=ISO
ADV	AVP	attachment=NXT
ADV	AVSUP	attachment=ISO
ADV	SADV	attachment=ISO
ADV	SADV	attachment=NXT
ADV	SADV	attachment=PRV
CONJ	CONJ	attachment=ISO
IDEN	IDEN	attachment=ISO
IDEN	IDEN	attachment=ISO|number=SING
N	ANM	attachment=ISO
N	ANM	attachment=ISO|number=PLUR
N	ANM	attachment=ISO|number=SING
N	ANM	attachment=NXT|number=PLUR
N	ANM	attachment=NXT|number=SING
N	IANM	attachment=ISO
N	IANM	attachment=ISO|number=PLUR
N	IANM	attachment=ISO|number=SING
N	IANM	attachment=NXT|number=PLUR
N	IANM	attachment=NXT|number=SING
N	IANM	attachment=PRV|number=SING
PART	PART	attachment=ISO
PART	PART	attachment=PRV
POSNUM	POSNUM	attachment=ISO
POSTP	POSTP	attachment=ISO
POSTP	POSTP	attachment=NXT
POSTP	POSTP	attachment=PRV
PR	CREFX	attachment=ISO
PR	CREFX	attachment=ISO|number=SING
PR	CREFX	person=1|attachment=ISO|number=PLUR
PR	CREFX	person=1|attachment=ISO|number=SING
PR	CREFX	person=1|attachment=PRV|number=PLUR
PR	CREFX	person=1|attachment=PRV|number=SING
PR	CREFX	person=2|attachment=ISO|number=PLUR
PR	CREFX	person=2|attachment=ISO|number=SING
PR	CREFX	person=3|attachment=ISO|number=PLUR
PR	CREFX	person=3|attachment=ISO|number=SING
PR	DEMON	attachment=ISO
PR	DEMON	attachment=ISO|number=PLUR
PR	DEMON	attachment=ISO|number=SING
PR	DEMON	attachment=NXT|number=SING
PR	DEMON	attachment=PRV|number=SING
PR	DEMON	person=1|attachment=ISO|number=PLUR
PR	DEMON	person=1|attachment=ISO|number=SING
PR	DEMON	person=1|attachment=NXT|number=PLUR
PR	DEMON	person=3|attachment=ISO
PR	DEMON	person=3|attachment=ISO|number=PLUR
PR	DEMON	person=3|attachment=ISO|number=SING
PR	DEMON	person=3|attachment=NXT|number=SING
PR	INTG	attachment=ISO
PR	INTG	attachment=ISO|number=SING
PR	INTG	attachment=NXT
PR	INTG	attachment=NXT|number=SING
PR	INTG	person=1|attachment=ISO|number=SING
PR	INTG	person=3|attachment=ISO|number=SING
PR	JOPER	person=1|attachment=ISO|number=PLUR
PR	JOPER	person=1|attachment=ISO|number=SING
PR	JOPER	person=1|attachment=NXT|number=SING
PR	JOPER	person=1|attachment=PRV|number=PLUR
PR	JOPER	person=1|attachment=PRV|number=SING
PR	JOPER	person=2|attachment=ISO|number=PLUR
PR	JOPER	person=2|attachment=ISO|number=SING
PR	JOPER	person=2|attachment=PRV|number=PLUR
PR	JOPER	person=2|attachment=PRV|number=SING
PR	JOPER	person=3|attachment=ISO|number=PLUR
PR	JOPER	person=3|attachment=ISO|number=SING
PR	JOPER	person=3|attachment=NXT|number=SING
PR	JOPER	person=3|attachment=PRV|number=PLUR
PR	JOPER	person=3|attachment=PRV|number=SING
PR	SEPER	attachment=ISO
PR	SEPER	attachment=ISO|number=PLUR
PR	SEPER	attachment=ISO|number=SING
PR	SEPER	person=1|attachment=ISO|number=PLUR
PR	SEPER	person=1|attachment=ISO|number=SING
PR	SEPER	person=1|attachment=NXT|number=PLUR
PR	SEPER	person=1|attachment=NXT|number=SING
PR	SEPER	person=1|attachment=PRV|number=PLUR
PR	SEPER	person=1|attachment=PRV|number=SING
PR	SEPER	person=2|attachment=ISO|number=PLUR
PR	SEPER	person=2|attachment=ISO|number=SING
PR	SEPER	person=2|attachment=NXT|number=PLUR
PR	SEPER	person=2|attachment=NXT|number=SING
PR	SEPER	person=3|attachment=ISO|number=PLUR
PR	SEPER	person=3|attachment=ISO|number=SING
PR	SEPER	person=3|attachment=NXT|number=PLUR
PR	SEPER	person=3|attachment=NXT|number=SING
PR	SEPER	person=3|attachment=PRV|number=SING
PREM	AMBAJ	attachment=ISO
PREM	DEMAJ	attachment=ISO
PREM	DEMAJ	attachment=PRV
PREM	EXAJ	attachment=ISO
PREM	QUAJ	attachment=ISO
PRENUM	PRENUM	attachment=ISO
PREP	PREP	attachment=ISO
PREP	PREP	attachment=NXT
PREP	PREP	attachment=PRV
PSUS	PSUS	attachment=ISO
PSUS	PSUS	attachment=NXT
PUNC	PUNC	attachment=ISO
PUNC	PUNC	attachment=PRV
SUBR	SUBR	attachment=ISO
SUBR	SUBR	attachment=PRV
V	ACT	attachment=ISO|number=PLUR|tma=AY
V	ACT	attachment=ISO|number=PLUR|tma=GN
V	ACT	attachment=ISO|number=PLUR|tma=GS
V	ACT	attachment=ISO|number=PLUR|tma=H
V	ACT	attachment=ISO|number=PLUR|tma=HEL
V	ACT	attachment=ISO|number=SING|tma=GB
V	ACT	attachment=ISO|number=SING|tma=GEL
V	ACT	attachment=ISO|number=SING|tma=H
V	ACT	attachment=ISO|number=SING|tma=HEL
V	ACT	attachment=ISO|tma=H
V	ACT	attachment=ISO|tma=HEL
V	ACT	person=1|attachment=ISO|number=PLUR|tma=AY
V	ACT	person=1|attachment=ISO|number=PLUR|tma=GB
V	ACT	person=1|attachment=ISO|number=PLUR|tma=GEL
V	ACT	person=1|attachment=ISO|number=PLUR|tma=GES
V	ACT	person=1|attachment=ISO|number=PLUR|tma=GN
V	ACT	person=1|attachment=ISO|number=PLUR|tma=GS
V	ACT	person=1|attachment=ISO|number=PLUR|tma=H
V	ACT	person=1|attachment=ISO|number=PLUR|tma=HEL
V	ACT	person=1|attachment=ISO|number=SING|tma=AY
V	ACT	person=1|attachment=ISO|number=SING|tma=GB
V	ACT	person=1|attachment=ISO|number=SING|tma=GBESE
V	ACT	person=1|attachment=ISO|number=SING|tma=GEL
V	ACT	person=1|attachment=ISO|number=SING|tma=GES
V	ACT	person=1|attachment=ISO|number=SING|tma=GESEL
V	ACT	person=1|attachment=ISO|number=SING|tma=GN
V	ACT	person=1|attachment=ISO|number=SING|tma=GNES
V	ACT	person=1|attachment=ISO|number=SING|tma=GS
V	ACT	person=1|attachment=ISO|number=SING|tma=H
V	ACT	person=1|attachment=ISO|number=SING|tma=HA
V	ACT	person=1|attachment=ISO|number=SING|tma=HEL
V	ACT	person=1|attachment=NXT|number=PLUR|tma=H
V	ACT	person=1|attachment=NXT|number=SING|tma=GS
V	ACT	person=1|attachment=NXT|number=SING|tma=H
V	ACT	person=1|attachment=PRV|number=PLUR|tma=AY
V	ACT	person=1|attachment=PRV|number=PLUR|tma=H
V	ACT	person=1|attachment=PRV|number=SING|tma=AY
V	ACT	person=1|attachment=PRV|number=SING|tma=H
V	ACT	person=1|attachment=PRV|number=SING|tma=HEL
V	ACT	person=2|attachment=ISO|number=PLUR
V	ACT	person=2|attachment=ISO|number=PLUR|tma=AY
V	ACT	person=2|attachment=ISO|number=PLUR|tma=GB
V	ACT	person=2|attachment=ISO|number=PLUR|tma=GEL
V	ACT	person=2|attachment=ISO|number=PLUR|tma=GES
V	ACT	person=2|attachment=ISO|number=PLUR|tma=GN
V	ACT	person=2|attachment=ISO|number=PLUR|tma=GNES
V	ACT	person=2|attachment=ISO|number=PLUR|tma=GS
V	ACT	person=2|attachment=ISO|number=PLUR|tma=H
V	ACT	person=2|attachment=ISO|number=PLUR|tma=HA
V	ACT	person=2|attachment=ISO|number=PLUR|tma=HEL
V	ACT	person=2|attachment=ISO|number=SING|tma=AY
V	ACT	person=2|attachment=ISO|number=SING|tma=GB
V	ACT	person=2|attachment=ISO|number=SING|tma=GEL
V	ACT	person=2|attachment=ISO|number=SING|tma=GES
V	ACT	person=2|attachment=ISO|number=SING|tma=GN
V	ACT	person=2|attachment=ISO|number=SING|tma=GS
V	ACT	person=2|attachment=ISO|number=SING|tma=H
V	ACT	person=2|attachment=ISO|number=SING|tma=HA
V	ACT	person=2|attachment=ISO|number=SING|tma=HEL
V	ACT	person=2|attachment=NXT|number=PLUR|tma=H
V	ACT	person=2|attachment=PRV|number=PLUR|tma=H
V	ACT	person=2|attachment=PRV|number=SING|tma=H
V	ACT	person=2|attachment=PRV|number=SING|tma=HA
V	ACT	person=3|attachment=ISO|number=PLUR|tma=AY
V	ACT	person=3|attachment=ISO|number=PLUR|tma=GB
V	ACT	person=3|attachment=ISO|number=PLUR|tma=GEL
V	ACT	person=3|attachment=ISO|number=PLUR|tma=GES
V	ACT	person=3|attachment=ISO|number=PLUR|tma=GN
V	ACT	person=3|attachment=ISO|number=PLUR|tma=GNES
V	ACT	person=3|attachment=ISO|number=PLUR|tma=GS
V	ACT	person=3|attachment=ISO|number=PLUR|tma=H
V	ACT	person=3|attachment=ISO|number=PLUR|tma=HA
V	ACT	person=3|attachment=ISO|number=PLUR|tma=HEL
V	ACT	person=3|attachment=ISO|number=SING
V	ACT	person=3|attachment=ISO|number=SING|tma=AY
V	ACT	person=3|attachment=ISO|number=SING|tma=GB
V	ACT	person=3|attachment=ISO|number=SING|tma=GEL
V	ACT	person=3|attachment=ISO|number=SING|tma=GES
V	ACT	person=3|attachment=ISO|number=SING|tma=GN
V	ACT	person=3|attachment=ISO|number=SING|tma=GNES
V	ACT	person=3|attachment=ISO|number=SING|tma=GS
V	ACT	person=3|attachment=ISO|number=SING|tma=H
V	ACT	person=3|attachment=ISO|number=SING|tma=HA
V	ACT	person=3|attachment=ISO|number=SING|tma=HEL
V	ACT	person=3|attachment=NXT|number=PLUR|tma=GES
V	ACT	person=3|attachment=NXT|number=PLUR|tma=GS
V	ACT	person=3|attachment=NXT|number=PLUR|tma=H
V	ACT	person=3|attachment=NXT|number=SING|tma=GES
V	ACT	person=3|attachment=NXT|number=SING|tma=GS
V	ACT	person=3|attachment=NXT|number=SING|tma=H
V	ACT	person=3|attachment=PRV|number=PLUR|tma=H
V	ACT	person=3|attachment=PRV|number=SING|tma=AY
V	ACT	person=3|attachment=PRV|number=SING|tma=GS
V	ACT	person=3|attachment=PRV|number=SING|tma=H
V	MODL	attachment=ISO|number=SING|tma=H
V	MODL	attachment=ISO|number=SING|tma=HEL
V	MODL	attachment=ISO|tma=GEL
V	MODL	attachment=ISO|tma=GES
V	MODL	attachment=ISO|tma=GS
V	MODL	attachment=ISO|tma=H
V	MODL	attachment=ISO|tma=HEL
V	MODL	attachment=NXT|tma=HEL
V	MODL	person=1|attachment=ISO|number=PLUR|tma=H
V	MODL	person=1|attachment=ISO|number=SING|tma=H
V	MODL	person=2|attachment=ISO|number=SING|tma=H
V	MODL	person=3|attachment=ISO|number=PLUR|tma=H
V	MODL	person=3|attachment=ISO|number=SING|tma=GES
V	MODL	person=3|attachment=ISO|number=SING|tma=GNES
V	MODL	person=3|attachment=ISO|number=SING|tma=GS
V	MODL	person=3|attachment=ISO|number=SING|tma=H
V	MODL	person=3|attachment=ISO|number=SING|tma=HEL
V	PASS	attachment=ISO|number=SING|tma=GEL
V	PASS	person=1|attachment=ISO|number=PLUR|tma=AY
V	PASS	person=1|attachment=ISO|number=PLUR|tma=GB
V	PASS	person=1|attachment=ISO|number=PLUR|tma=GES
V	PASS	person=1|attachment=ISO|number=PLUR|tma=GN
V	PASS	person=1|attachment=ISO|number=PLUR|tma=GS
V	PASS	person=1|attachment=ISO|number=PLUR|tma=H
V	PASS	person=1|attachment=ISO|number=PLUR|tma=HEL
V	PASS	person=1|attachment=ISO|number=SING|tma=AY
V	PASS	person=1|attachment=ISO|number=SING|tma=GB
V	PASS	person=1|attachment=ISO|number=SING|tma=GES
V	PASS	person=1|attachment=ISO|number=SING|tma=GN
V	PASS	person=1|attachment=ISO|number=SING|tma=GS
V	PASS	person=1|attachment=ISO|number=SING|tma=H
V	PASS	person=1|attachment=ISO|number=SING|tma=HEL
V	PASS	person=2|attachment=ISO|number=PLUR|tma=AY
V	PASS	person=2|attachment=ISO|number=PLUR|tma=GB
V	PASS	person=2|attachment=ISO|number=PLUR|tma=GEL
V	PASS	person=2|attachment=ISO|number=PLUR|tma=GN
V	PASS	person=2|attachment=ISO|number=PLUR|tma=GS
V	PASS	person=2|attachment=ISO|number=PLUR|tma=H
V	PASS	person=2|attachment=ISO|number=PLUR|tma=HA
V	PASS	person=2|attachment=ISO|number=PLUR|tma=HEL
V	PASS	person=2|attachment=ISO|number=SING|tma=GB
V	PASS	person=2|attachment=ISO|number=SING|tma=GES
V	PASS	person=2|attachment=ISO|number=SING|tma=GN
V	PASS	person=2|attachment=ISO|number=SING|tma=GS
V	PASS	person=2|attachment=ISO|number=SING|tma=H
V	PASS	person=2|attachment=ISO|number=SING|tma=HA
V	PASS	person=2|attachment=ISO|number=SING|tma=HEL
V	PASS	person=3|attachment=ISO|number=PLUR|tma=AY
V	PASS	person=3|attachment=ISO|number=PLUR|tma=GB
V	PASS	person=3|attachment=ISO|number=PLUR|tma=GEL
V	PASS	person=3|attachment=ISO|number=PLUR|tma=GES
V	PASS	person=3|attachment=ISO|number=PLUR|tma=GN
V	PASS	person=3|attachment=ISO|number=PLUR|tma=GS
V	PASS	person=3|attachment=ISO|number=PLUR|tma=H
V	PASS	person=3|attachment=ISO|number=PLUR|tma=HA
V	PASS	person=3|attachment=ISO|number=PLUR|tma=HEL
V	PASS	person=3|attachment=ISO|number=SING|tma=AY
V	PASS	person=3|attachment=ISO|number=SING|tma=GB
V	PASS	person=3|attachment=ISO|number=SING|tma=GEL
V	PASS	person=3|attachment=ISO|number=SING|tma=GES
V	PASS	person=3|attachment=ISO|number=SING|tma=GN
V	PASS	person=3|attachment=ISO|number=SING|tma=GNES
V	PASS	person=3|attachment=ISO|number=SING|tma=GS
V	PASS	person=3|attachment=ISO|number=SING|tma=H
V	PASS	person=3|attachment=ISO|number=SING|tma=HEL
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

Lingua::Interset::Tagset::FA::Conll - Driver for the tagset of the Persian Dependency Treebank (in the CoNLL-X format).

=head1 VERSION

version 3.006

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::FA::Conll;
  my $driver = Lingua::Interset::Tagset::FA::Conll->new();
  my $fs = $driver->decode("N\tANM\tattachment=ISO|number=SING");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('fa::conll', "N\tANM\tattachment=ISO|number=SING");

=head1 DESCRIPTION

Interset driver for the tagset of the Persian Dependency Treebank (in the
CoNLL-X format).
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT.

Tagset documentation is at
L<https://wiki.ufal.ms.mff.cuni.cz/_media/user:zeman:treebanks:persian-dependency-treebank-version-0.1-annotation-manual-and-user-guide.pdf>

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::Conll>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
