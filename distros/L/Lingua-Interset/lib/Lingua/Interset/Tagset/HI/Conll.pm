# ABSTRACT: Driver for the Hindi tagset of the shared tasks at ICON 2009, ICON 2010 and COLING 2012, as used in the CoNLL data format.
# Documentation:
# http://ltrc.iiit.ac.in/nlptools2010/documentation.php
# http://ltrc.iiit.ac.in/MachineTrans/publications/technicalReports/tr031/posguidelines.pdf
# Copyright © 2011 Loganathan Ramasamy <ramasamy@ufal.mff.cuni.cz>
# Copyright © 2011, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::HI::Conll;
use strict;
use warnings;
our $VERSION = '3.015';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
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
    return 'hi::conll';
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
            # These tags come in the CPOS column of the CoNLL data format.
            # Many tags come in two flavors, with and without final 'C'. The 'C' means "compound". Nevertheless, the compounds do not occur in the current data.
            # Documentation contains many tags that do not occur in actual data. The following tags have been observed in the data:
            # PSP (53176), NN (52984), VM (28372), NNP (21380), SYM (18178), VAUX (16761), JJ (14703), NNPC (11391), PRP (11039), CC (10672),
            # NNC (5830), QC (4692), NST (4007), RP (3936), DEM (3500), QF (1973), NEG (1904), RB (1178), QCC (625), QO (451), JJC (311),
            # WQ (267), INTF (265), RDP (199), UNK (131), VMC (44), PRPC (39), RBC (24), NSTC (19), QFC (16), NULL (8), CCC (8), INJ (7)
            # UNKC (1), <fs (1), VGF (1)
            # common nouns
            # Examples:
            # NN n m sg 3 d शुरू (śurū = beginning), आज (āja = day), फैसला (phaisalā = decision), समय (samaya = time), काम (kāma = work)
            # NN n m sg 3 o अध्यक्ष (adhyakṣa), नेता (netā), सचिव (saciva), सांसद (sāṁsada), प्रवक्ता (pravaktā)
            # NN n m pl 3 d लोग (loga = people), रुपये (rupaye = rupees), नेता (netā), सदस्य (sadasya), अधिकारी (adhikārī)
            # NN n m pl 3 o नेताओं (netāoṁ), लोगों (logoṁ), अफसरों (aphasaroṁ), किसानों (kisānoṁ), मंत्रियों (maṁtriyoṁ)
            # NN n f sg 3 d सरकार (sarakāra), बात (bāta), जानकारी (jānakārī), बार (bāra), मांग (māṁga)
            # NN n f sg 3 o पत्नी (patnī), शिक्षा (śikṣā), पुलिस (pulisa), मां (māṁ), राजधानी (rājadhānī)
            # NN n f pl 3 d तस्वीरें (tasvīreṁ), बार (bāra), कंपनियां (kaṁpaniyāṁ), महिलाएं (mahilāeṁ), बातें (bāteṁ)
            # NN n f pl 3 o महिलाओं (mahilāoṁ), विधवाओं (vidhavāoṁ), कंपनियों (kaṁpaniyoṁ), बीमारियों (bīmāriyoṁ), रैलियों (railiyoṁ)
            "NN\tn"  => ['pos' => 'noun', 'nountype' => 'com'],
            # NNC example: पुलिस (pulisa) in पुलिस स्टेशन (pulisa sṭeśana) = police station
            "NNC\tn" => ['pos' => 'noun', 'nountype' => 'com', 'other' => {'compound' => 'yes'}],
            # proper nouns
            # Examples:
            # NNP n m sg 3 d भारत (bhārata = India), मंत्री (maṁtrī = Minister), प्रधानमंत्री (pradhānamaṁtrī = Prime Minister), राष्ट्रपति (rāṣṭrapati = President), सिंह (siṁha = Singh)
            # NNP n f sg 3 d दिल्ली (dillī = Delhi), कांग्रेस (kāṁgresa = Congress), भाजपा (bhājapā = BJP), सरकार (sarakāra = Government), मुंबई (muṁbaī = Mumbai)
            "NNP\tn"  => ['pos' => 'noun', 'nountype' => 'prop'],
            # NNPC example: सोनिया (soniyā) in सोनिया गांधी (soniyā gāṁdhī) = Sonia Gandhi
            "NNPC\tn" => ['pos' => 'noun', 'nountype' => 'prop', 'other' => {'compound' => 'yes'}],
            # location nouns
            # These words are grammatically nouns but they are used to form a sort of postpositions. Often but not always they specify location.
            # For instance, "on the table" would be constructed as "the table's upper side", and the word for "upper side" would be tagged NST.
            # Examples:
            # NST nst m sg 3 d: साथ (sātha = with), बाद (bāda = then), बीच (bīca = middle), पहले (pahale = first), दौरान (daurāna = during)
            "NST\tnst"  => ['pos' => 'noun', 'adpostype' => 'post'],
            # NSTC example: आस in उसके आस - पास
            "NSTC\tnst" => ['pos' => 'noun', 'adpostype' => 'post', 'other' => {'compound' => 'yes'}],
            # pronouns
            # Examples (note that the "possessive" pronouns are genitive forms of personal pronouns):
            # मैं (I), आप (you), यह (he/she/it), वह (he/she/it), हम (we), ये (they), वे (they)
            "PRP\tpn"  => ['pos' => 'noun', 'prontype' => 'prs'],
            "PRPC\tpn" => ['pos' => 'noun', 'prontype' => 'prs', 'other' => {'compound' => 'yes'}],
            # question words
            # Examples:
            # कौन (kauna = who), क्या (kyā = what), क्यों (kyoṁ = why)
            "WQ\tpn"   => ['pos' => 'noun', 'prontype' => 'int'],
            # adjectives
            # Examples:
            # masc sing direct ... पूरा (púrá), बड़ा (bará), नया (najá), अच्छा (aččhá), कड़ा (kará)
            # masc sing oblique .. पिछले (pičhalé), अगले (agalé), नए (naé), पूरे (púré), बड़े (baré)
            # masc plur direct ... बड़े (baré), नए (naé), अच्छे (aččhé), काले (kálé), पूरे (púré)
            # masc plur oblique .. पिछले (pičhalé), अगले (agalé), नए (naé), बड़े (baré), पिछड़े (pičharé)
            # fem sing direct .... पूरी (púrí), बड़ी (barí), नई (naí), अच्छी (aččhí), कड़ी (karí)
            # fem sing oblique ... पूरी (púrí), बड़ी (barí), नई (naí), पिछली (pičhalí), लंबी (lambí)
            # fem plur direct .... नई (naí), बड़ी (barí), पक्की (pakkí), ऊंची (úňčí), ठंडी (thandí)
            # fem plur oblique ... ऊंची (úňčí), नई (naí), पिछड़ी (pičharí), नशीली (naśílí), ठंडी (thandí)
            # Indifferent to gender and number:
            # direct ........ भारी (bhárí), पूर्व (púrva), विशेष (viśéš), मुख्य (mukhja), अन्य (anja)
            # oblique ....... अन्य (anja), पूर्व (púrva), भारतीय (bháratíja), स्थित (sthita), वरिष्ठ (barištha)
            "JJ\tadj"   => ['pos' => 'adj'],
            # compound adjectives
            # Examples:
            # गैर (gaira) in गैर कानूनी (gaira kánúní = non legal = illegal)
            "JJC\tadj"  => ['pos' => 'adj', 'other' => {'compound' => 'yes'}],
            # demonstratives
            # यह (yaha = this), वह (vaha = that), जो (jo = that), यही (yahī = this only)
            "DEM\tpn"  => ['pos' => 'adj', 'prontype' => 'dem'],
            # quantifiers
            # Examples:
            # कुछ (some), कई (several), सभी (all), कम (less), ज्यादा (more, much), काफी (enough), अधिक (more)
            "QF\tavy"   => ['pos' => 'adj', 'prontype' => 'ind'],
            "QFC\tavy"  => ['pos' => 'adj', 'prontype' => 'ind', 'other' => {'compound' => 'yes'}],
            # numerals
            # Examples:
            # एक (one), दो (two), तीन (three), करोड़ (crore), लाख (lakh), १० (10)
            # दोनों (both), सैकड़ों (hundreds), हजारों (thousands), दसियों (tens), लाखों (lakhs, millions)
            "QC\tnum"   => ['pos' => 'num', 'numtype' => 'card'],
            # QCC example: एक in एक लाख; तीन in तीन हजार करोड़ (three thousand crore = thirty billion)
            "QCC\tnum"  => ['pos' => 'num', 'numtype' => 'card', 'other' => {'compound' => 'yes'}],
            # Masculine ordinal examples: दूसरा (other), पहला (first), तीसरा (third), पहले (first), दूसरे (second)
            # Feminine ordinal examples: दूसरी (other), पहली (first), पांचवीं (fifth), चौथी (fourth), 19वीं (19th)
            "QO\tnum"   => ['pos' => 'adj', 'numtype' => 'ord'],
            # main verbs (documentation says "verb-finite", are they really always finite forms?)
            # Examples:
            # कहना (kahanā = say), करना (karanā = do), मानना (mānanā = believe), देना (denā = give), होना (honā = be)
            "VM\tv"   => ['pos' => 'verb'],
            "VMC\tv"  => ['pos' => 'verb', 'other' => {'compound' => 'yes'}],
            # auxiliary verbs
            # है (hai = is), जाना (jānā = go), देना (denā = give), पाना (pānā = get), रहना (rahanā = stay)
            "VAUX\tv" => ['pos' => 'verb', 'verbtype' => 'aux'],
            # adverbs
            # Examples:
            # फिर (then), जल्द (soon), वहीं (there), फिलहाल (for the time being), लगातार (continuously)
            "RB\tadv"  => ['pos' => 'adv'],
            "RBC\tadv" => ['pos' => 'adv', 'other' => {'compound' => 'yes'}],
            # intensifiers
            # सबसे (sabase = most), बहुत (bahuta = very), बेहद (behada = vastly), सर्वाधिक (sarvādhika = most), अति (ati = very, most)
            "INTF\tavy" => ['pos' => 'adv', 'advtype' => 'deg'],
            # negation
            # Example:
            # नहीं (nahīṁ = not), न (na), बिना (binā = without)
            "NEG\tavy"  => ['pos' => 'part', 'prontype' => 'neg', 'negativeness' => 'neg'],
            # postpositions
            # Examples:
            # possessive, with gender and number: का, के, की
            # without features: में, को, के, ने, से, पर, लिए
            "PSP\tpsp"  => ['pos' => 'adp', 'adpostype' => 'post'],
            # conjunctions
            # Examples:
            # कि (ki = that), और (aura = and), व (va = and), लेकिन (lekina = but), तो (to = then)
            "CC\tavy"   => ['pos' => 'conj'],
            # particles
            # Examples:
            # भी (bhī = also), ही (hī = only), तो (to = then), करीब (karība = nearly), सिर्फ (sirpha = only)
            "RP\tavy"   => ['pos' => 'part'],
            # interjections
            # Examples:
            # हां (hāṁ = yes), वाह (vāha = wow), अरे (are = hey)
            "INJ\tavy"  => ['pos' => 'int'],
            # reduplicatives
            # The RDP tag seems to be the only one that can occur with multiple different values of the cat feature.
            # Reduplicated pronouns: only the reflexive pronoun apanā. Example: the second apane in: अपने - अपने एकाउंट पर (apane - apane ekāuṁṭa para = on your own account)
            # Reduplicated avy: only one example: the second kaī in: कई - कई (numerous)
            "RDP\tadj"  => ['pos' => 'adj', 'echo' => 'rdp'],
            "RDP\tadv"  => ['pos' => 'adv', 'echo' => 'rdp'],
            "RDP\tavy"  => ['pos' => 'adj', 'prontype' => 'ind', 'echo' => 'rdp'],
            "RDP\tn"    => ['pos' => 'noun', 'echo' => 'rdp'],
            "RDP\tnst"  => ['pos' => 'noun', 'adpostype' => 'post', 'echo' => 'rdp'],
            "RDP\tnum"  => ['pos' => 'num', 'echo' => 'rdp'],
            "RDP\tpn"   => ['pos' => 'noun', 'prontype' => 'prs', 'echo' => 'rdp'],
            "RDP\tv"    => ['pos' => 'verb', 'echo' => 'rdp'],
            # echo words
            # No occurrence in the corpus.
            'ECH'  => ['echo' => 'ech'],
            # punctuation
            # Examples (the corpus contains European punctuation):
            # । (danda = .) , - . '
            "SYM\tpunc" => ['pos' => 'punc'],
            # foreign or unknown words
            "UNK\tunk"  => ['foreign' => 'yes'],
            "UNKC\tunk" => ['foreign' => 'yes', 'other' => {'compound' => 'yes'}],
            # The 'NULL' tag is used for artificial NULL nodes.
            "NULL\t_"   => ['other' => {'pos' => 'null'}]
        },
        'encode_map' =>
        {
              'pos' => { 'noun' => { 'adpostype' => { 'post' => { 'other/compound' => { 'yes' => "NSTC\tnst",
                                                                                        '@'   => { 'echo' => { 'rdp' => "RDP\tnst",
                                                                                                               '@'   => "NST\tnst" }}}},
                                                      '@'    => { 'prontype' => { ''    => { 'nountype' => { 'prop' => { 'other/compound' => { 'yes' => "NNPC\tn",
                                                                                                                                               '@'   => "NNP\tn" }},
                                                                                                             '@'    => { 'other/compound' => { 'yes' => "NNC\tn",
                                                                                                                                               '@'   => { 'echo' => { 'rdp' => "RDP\tn",
                                                                                                                                                                      '@'   => "NN\tn" }}}}}},
                                                                                  'int' => "WQ\tpn",
                                                                                  '@'   => { 'other/compound' => { 'yes' => "PRPC\tpn",
                                                                                                                   '@'   => { 'echo' => { 'rdp' => "RDP\tpn",
                                                                                                                                          '@'   => "PRP\tpn" }}}}}}}},
                         'adj'  => { 'numtype' => { 'ord' => "QO\tnum",
                                                    '@'   => { 'prontype' => { 'dem' => "DEM\tpn",
                                                                               'ind' => { 'other/compound' => { 'yes' => "QFC\tavy",
                                                                                                                '@'   => { 'echo' => { 'rdp' => "RDP\tavy",
                                                                                                                                       '@'   => "QF\tavy" }}}},
                                                                               'tot' => { 'other/compound' => { 'yes' => "QFC\tavy",
                                                                                                                '@'   => "QF\tavy" }},
                                                                               'neg' => { 'other/compound' => { 'yes' => "QFC\tavy",
                                                                                                                '@'   => "QF\tavy" }},
                                                                               '@'   => { 'other/compound' => { 'yes' => "JJC\tadj",
                                                                                                                '@'   => { 'echo' => { 'rdp' => "RDP\tadj",
                                                                                                                                       '@'   => "JJ\tadj" }}}}}}}},
                         'num'  => { 'other/compound' => { 'yes' => "QCC\tnum",
                                                           '@'   => { 'echo' => { 'rdp' => "RDP\tnum",
                                                                                  '@'   => "QC\tnum" }}}},
                         'verb' => { 'verbtype' => { 'aux' => "VAUX\tv",
                                                     '@'   => { 'echo' => { 'rdp' => "RDP\tv",
                                                                            '@'   => { 'other/compound' => { 'yes' => "VMC\tv",
                                                                                                             '@'   => "VM\tv" }}}}}},
                         'adv'  => { 'advtype' => { 'deg' => "INTF\tavy",
                                                    '@'   => { 'other/compound' => { 'yes' => "RBC\tadv",
                                                                                     '@'   => { 'echo' => { 'rdp' => "RDP\tadv",
                                                                                                            '@'   => "RB\tadv" }}}}}},
                         'adp'  => "PSP\tpsp",
                         'conj' => "CC\tavy",
                         'part' => { 'prontype' => { 'neg' => "NEG\tavy",
                                                     '@'   => "RP\tavy" }},
                         'int'  => "INJ\tavy",
                         'punc' => "SYM\tpunc",
                         '@'    => { 'echo' => { 'rdp' => "RDP",
                                                 '@'   => { 'other/pos' => { 'null' => "NULL\t_",
                                                                             '@'    => { 'other/compound' => { 'yes' => "UNKC\tunk",
                                                                                                               '@'   => "UNK\tunk" }}}}}}}
        }
    );
    # GENDER ####################
    $atoms{gen} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'm' => 'masc',
            'f' => 'fem',
            'n' => 'neut'
        }
    );
    # NUMBER ####################
    $atoms{num} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'sg'   => 'sing',
            'pl'   => 'plur',
            'dual' => 'dual'
        }
    );
    # PERSON ####################
    $atoms{pers} = $self->create_atom
    (
        'tagset' => 'bn::conll',
        'surfeature' => 'person',
        'decode_map' =>
        {
            '1'   => ['person' => '1'],
            '1h'  => ['person' => '1', 'polite' => 'form'],
            '2'   => ['person' => '2'],
            '2h'  => ['person' => '2', 'polite' => 'form'],
            '3'   => ['person' => '3'],
            '3h'  => ['person' => '3', 'polite' => 'form']
        },
        'encode_map' =>
        {
            'person' => { '1' => { 'polite' => { 'form' => '1h',
                                                 '@'    => '1' }},
                          '2' => { 'polite' => { 'form' => '2h',
                                                 '@'    => '2' }},
                          '3' => { 'polite' => { 'form' => '3h',
                                                 '@'    => '3' }}}
        }
    );
    # CASE ####################
    # The case feature is either empty, or 'd' (direct case), or 'o' (oblique case).
    # Nouns do not have other case forms (except for vocative plural but it did not appear in the corpus).
    # Pronouns attach postpositions as suffixes, thus we have more "cases". But the case feature is also 'o',
    # and the suffixes are encoded in the tam feature. Thus we must encode any non-empty, non-direct case as 'o'.
    $atoms{case} = $self->create_atom
    (
        'surfeature' => 'case',
        'decode_map' =>
        {
            'd' => ['case' => 'nom'], # direct
            'o' => ['case' => 'acc']  # oblique
        },
        'encode_map' =>
        {
            'case' => { 'nom' => 'd',
                        ''    => '',
                        '@'   => 'o' }
        }
    );
    # TENSE, ASPECT AND MODALITY (TAM) ####################
    # The value of the tam feature often corresponds to the value of the vib feature and they differ only in the script used: "vib-गा|tam-gA".
    # When they do not match, then vib contains tam. Vib is the larger context including surrounding words (postpositions, auxiliaries)
    # while tam always reflects only the morphemes directly in the current word. For example, with verbs we can encounter "vib-ता_था|tam-wA",
    # meaning that the current word is an imperfect participle and it takes part in periphrastic past tense: वह नियुक्ति करता था = lit. "he appointment doing was".
    # Unlike vibhakti, tam does not apply to nouns because their vibhakti is always derived from postpositions and other words.
    # It does however apply to pronouns where some postpositions are transformed to suffixes.
    # (Note: With pronouns, tam has no more to do with tense, aspect or modality. It is rather an extension to the case system.)
    $atoms{tam} = $self->create_atom
    (
        'surfeature' => 'tam',
        'decode_map' =>
        {
            # ADDITIONAL CASES OF PRONOUNS
            # kā ... possessive / genitive
            # मेरा (my), आपका (your), इसका (his/her/its), उसका (his/her/its), हमारा (our), इनका (their), उनका (their)
            'kA' => ['case' => 'acc|gen', 'poss' => 'yes'],
            # ke ... also genitive suffix, but the whole phrase is in the oblique case
            # (so we could say that we have a possessive pronoun in the oblique case)
            # This is often used with compound postpositions, e.g. इसके बारे में (isake bāre meṁ = about it):
            # the final postposition में (meṁ = in) requires that its argument is in the oblique case.
            # Not sure what the direct case of this argument should be, though. इसका बार (isakā bāra = its time)?
            # मेरे (my), आपके (your), इसके (his/her/its), उसके (his/her/its), हमारे (our), इनके (their), उनके (their)
            'ke' => ['case' => 'acc|gen', 'poss' => 'yes', 'other' => {'possedcase' => 'obl'}],
            # ko ... dative
            # मुझे (me), आपको (you), इसे (him/her/it), उसे (him/her/it), हमें (us), तुम्हें (you), इन्हें (them), उन्हें (them)
            'ko' => ['case' => 'acc|dat'],
            # ne ... ergative (used with transitive verbs in past tense)
            # मैंने (I), आपने (you), इसने (he/she/it), उसने (he/she/it), हमने (we), तुमने (you), इन्होंने (they), उन्होंने (they)
            'ne' => ['case' => 'acc|erg'],
            # se ... instrumental
            # मुझसे (with me), आपसे (with you), इससे (with him/her/it), उससे (with him/her/it), हमसे (with us), इनसे (with them), उनसे (with them)
            'se' => ['case' => 'acc|ins'],
            # meṁ ... inessive
            # मुझमें (in me), इसमें (in him/her/it), उसमें (in him/her/it), हममें (in us), इनमें (in them), उनमें (in them)
            'meM' => ['case' => 'acc|ine'],
            # VERB FORM, MOOD, TENSE AND ASPECT
            # hai ... simple present form of the verb "to be"
            # हूं, हूँ (I am), है (he/she/it is), हैं (we/you/they are)
            'hE' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres'],
            # thā ... simple past form of the verb "to be"
            # था, थे, थी, थीं (was, were)
            'WA' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'past'],
            # gā ... future tense
            # करूंगा, करूँगी (I will do), करेगा (he will do), करेगी (she will do), करेंगे, करेंगी (we will do)
            'gA' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'fut'],
            # eṁ ... subjunctive
            # करे, करें (would do)
            'eM' => ['verbform' => 'fin', 'mood' => 'sub'],
            # o ... familiar/informal imperative
            # करो (do), जाओ (go)
            'ao' => ['verbform' => 'fin', 'mood' => 'imp', 'polite' => 'infm'],
            # tā ... imperfect participle
            # करता, करते, करती (doing)
            'wA' => ['verbform' => 'part', 'aspect' => 'imp'],
            # yā ... perfect participle
            # किया, किए, किये, की, कीं (done)
            'yA' => ['verbform' => 'part', 'aspect' => 'perf'],
            # yā1 ... perfect participle, special form of the verb "to go", instead of जाया etc.
            # गया, गए, गये, गई, गयी, गईं (gone)
            'yA1' => ['verbform' => 'part', 'aspect' => 'perf', 'variant' => '1'],
            # kara ... converb, adverbial participle
            # लेकर (having taken)
            'kara' => ['verbform' => 'conv'],
            # nā ... infinitive
            # करना, करने, करनी (to do)
            'nA' => ['verbform' => 'inf'],
        },
        'encode_map' =>
        {
            'verbform' => { 'inf'  => 'nA',
                            'part' => { 'aspect' => { 'imp' => 'wA',
                                                      '@'   => { 'variant' => { '1' => 'yA1',
                                                                                '@' => 'yA' }}}},
                            'conv' => 'kara',
                            '@'    => { 'mood' => { 'sub' => 'eM',
                                                    'imp' => 'ao',
                                                    '@'   => { 'tense' => { 'fut'  => 'gA',
                                                                            'pres' => 'hE',
                                                                            'past' => 'WA',
                                                                            '@'    =>
            { 'poss' => { 'yes' => { 'other/possedcase' => { 'obl' => 'ke',
                                                              '@'   => 'kA' }},
                          '@'    => { 'case' => { 'dat' => 'ko',
                                                  'erg' => 'ne',
                                                  'ins' => 'se',
                                                  'ine' => 'meM' }}}}}}}}}
        }
    );
    # VOICE ####################
    $atoms{voicetype} = $self->create_simple_atom
    (
        'intfeature' => 'voice',
        'simple_decode_map' =>
        {
            'active'  => 'act',
            'passive' => 'pass'
        }
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
    $fs->set_tagset('hi::conll');
    my $atoms = $self->atoms();
    # Three components: part-of-speech tag, part-of-speech category feature, and (the other) features
    # Hindi CoNLL files are converted from the Shakti Standard Format.
    # example: NN\tn\tgen-|num-sg|pers-|case-d|vib-|tam-
    my ($pos, $subpos, $features) = split(/\s+/, $tag);
    $features = '' if(!defined($features) || $features eq '_');
    my @features_conll = split(/\|/, $features);
    my %features_conll;
    foreach my $f (@features_conll)
    {
        if($f =~ m/^(\w+)-(.+)$/)
        {
            $features_conll{$1} = $2;
        }
        else
        {
            $features_conll{$f} = $f;
        }
    }
    $atoms->{pos}->decode_and_merge_hard("$pos\t$subpos", $fs);
    foreach my $name ('gen', 'num', 'pers', 'case', 'tam', 'voicetype')
    {
        if(defined($features_conll{$name}) && $features_conll{$name} ne '')
        {
            $atoms->{$name}->decode_and_merge_hard($features_conll{$name}, $fs);
        }
    }
    # Both vib (vibhakti) and tam (tense-aspect-modality) use Hindi morphemes
    # as values and both are used also outside the scope suggested by their
    # names (tam for vibhakti of pronouns, vib for verb forms).
    # The value of tam encodes only properties of the current word.
    # The value of vib may include other function words in the neighborhood.
    # We convert the tam values to Interset features but we cannot do that with vib.
    # We just store the vib values in the other feature of Interset.
    if(defined($features_conll{vib}) && $features_conll{vib} ne '')
    {
        $fs->set_other_subfeature('vib', $features_conll{vib});
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
    my @feature_names = ('gen', 'num', 'pers', 'case', 'vib', 'tam', 'voicetype');
    my @features;
    foreach my $name (@feature_names)
    {
        my $value = '';
        if($name eq 'vib')
        {
            $value = $fs->get_other_subfeature('hi::conll', $name);
        }
        else
        {
            if(!defined($atoms->{$name}))
            {
                confess("Cannot find atom for '$name'");
            }
            $value = $atoms->{$name}->encode($fs);
        }
        # The Hyderabad CoNLL files always name all features including those with empty values.
        push(@features, "$name-$value");
    }
    my $features = '_';
    if(scalar(@features) > 0)
    {
        $features = join('|', @features);
    }
    my $tag = "$pos\t$features";
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags. These are tag occurrences collected
# from the corpus, i.e. other tags probably exist but were not seen here. We
# have added manually tags with empty 'vib' and 'tam' to facilitate generating
# permitted tags with empty 'other' feature.
# 3830 tags from the corpus
# 3125 tags after cleaning
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
CC	avy	gen-|num-|pers-|case-|vib-|tam-|voicetype-
DEM	pn	gen-|num-pl|pers-3|case-d|vib-|tam-|voicetype-
DEM	pn	gen-|num-pl|pers-3|case-o|vib-|tam-|voicetype-
DEM	pn	gen-|num-sg|pers-3|case-d|vib-|tam-|voicetype-
DEM	pn	gen-|num-sg|pers-3|case-o|vib-|tam-|voicetype-
INJ	avy	gen-|num-|pers-|case-|vib-|tam-|voicetype-
INTF	avy	gen-|num-|pers-|case-|vib-|tam-|voicetype-
JJ	adj	gen-f|num-pl|pers-|case-d|vib-|tam-|voicetype-
JJ	adj	gen-f|num-pl|pers-|case-o|vib-|tam-|voicetype-
JJ	adj	gen-f|num-sg|pers-|case-d|vib-|tam-|voicetype-
JJ	adj	gen-f|num-sg|pers-|case-o|vib-|tam-|voicetype-
JJ	adj	gen-m|num-pl|pers-|case-d|vib-|tam-|voicetype-
JJ	adj	gen-m|num-pl|pers-|case-o|vib-|tam-|voicetype-
JJ	adj	gen-m|num-sg|pers-|case-d|vib-|tam-|voicetype-
JJ	adj	gen-m|num-sg|pers-|case-o|vib-|tam-|voicetype-
JJ	adj	gen-|num-|pers-|case-d|vib-|tam-|voicetype-
JJ	adj	gen-|num-|pers-|case-o|vib-|tam-|voicetype-
JJ	adj	gen-|num-|pers-|case-|vib-|tam-|voicetype-
JJC	adj	gen-|num-|pers-|case-d|vib-|tam-|voicetype-
JJC	adj	gen-|num-|pers-|case-o|vib-|tam-|voicetype-
JJC	adj	gen-|num-|pers-|case-|vib-|tam-|voicetype-
NEG	avy	gen-|num-|pers-|case-|vib-|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-d|vib-|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_का_ओर|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_का_तरफ|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_का_तुलना_में|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_का_वजह_से|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_का_हवाले_से|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_का|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_की_बाबत|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_अंतर्गत|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_अनुरूप|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_अनुसार|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_अलावा|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_आगे|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_आसपास|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_कारण|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_खिलाफ|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_चलते|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_जरिये|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_तहत|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_दौरान|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_पास|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_पीछे|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_प्रति|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_बजाय|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_बाद|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_बारे_में|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_बावजूद|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_बीच|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_मद्देनजर|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_मद्देनज़र|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_मुकाबला|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_मुताबिक|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_रूप_में|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_लिए|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_ले|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_संबंध_में|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_समय_पर|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_समय|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_साथ|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के_हिसाब_से|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_के|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_को|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_जैसा|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_तक|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_द्वारा|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_ने|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_पर|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_में_से|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_में|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_वाला|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_समेत|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_सहित|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_से_अलग|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_से_आगे|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_से_बाहर|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-0_से|tam-|voicetype-
NN	n	gen-f|num-pl|pers-3|case-o|vib-|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-d|vib-|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_अपेक्षा|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_ओर_से|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_ओर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_कारण|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_खातिर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_तरफ_से|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_तरफ|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_तरह|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_तर्ज_पर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_तुलना_में|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_दौरान|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_बजाय|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_बदौलत|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_बल_पर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_वक्त|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_वजह_से|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का_वजह|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_का|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_अंदर_से|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_अंदर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_अनुरूप|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_अनुसार|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_अलावा|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_आगे|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_आधार_पर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_आसपास|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_उपरान्त|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_ऊपर_का|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_ऊपर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_करीब|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_कारण|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_खिलाफ|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_चलते|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_जरिये|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_तहत|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_तौर_पर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_दौरान|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_नजदीक|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_निकट|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_नीचे_से|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_नीचे|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_परिणामस्वरूप|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_पास|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_पीछे|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_प्रति|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बगैर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बजाय|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बदले_में|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बराबर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बल_पर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बाद_से|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बाद|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बाबत|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बारे_में|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बावजूद|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बाहर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बीच_का|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बीच_में|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बीच|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_भीतर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_मद्देजनर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_मद्देनजर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_मद्देनज़र|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_मुकाबला|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_मुताबिक|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_रूप_में|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_लायक|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_लिए|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_लिहाज_से|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_ले|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_वक्त|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_विपरीत|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_विरोध_में|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_संबंध_में|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_संबंध|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_समक्ष|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_समय|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_समान|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_साथ|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_सामने|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के_हिसाब_से|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_के|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_को|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_जैसा|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_जैसी|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_तक_का|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_तक|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_दूर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_द्वारा|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_ने|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_पर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_बतौर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_में_से|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_में|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_वाला_ने|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_वाला|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_वाली|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_समेत|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_सरीखा|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_सहित|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_से_ऊपर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_से_दूर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_से_नीचे|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_से_परे|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_से_पहला|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_से_पहले|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_से_पूर्व|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_से_बाहर|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-0_से|tam-|voicetype-
NN	n	gen-f|num-sg|pers-3|case-o|vib-|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-d|vib-|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_कर|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_का_अपेक्षा|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_का_ओर_से|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_का_ओर|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_का_खातिर|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_का_तरफ_से|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_का_तरह|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_का_तुलना_में|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_का_बदौलत|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_का_भांति|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_का_वजह_से|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_का_साथ|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_का|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_की|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_अंदर|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_अनुरूप|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_अनुसार|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_अलावा|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_आसपास|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_ऊपर_से|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_ऊपर|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_कारण|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_खिलाफ|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_चलते|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_जरिये|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_तहत|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_दौरान|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_परिणामस्वरूप|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_पास_से|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_पास|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_पीछे|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_प्रति|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_बजाय|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_बाद|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_बारे_में|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_बावजूद|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_बीच_में|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_बीच_से|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_बीच|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_भीतर|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_मद्देनजर|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_मद्देनज़र|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_मुकाबला|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_मुकाबले|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_मुताबिक|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_यहाँ|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_लिए|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_वक्त|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_विरुद्ध|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_संबंध_में|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_समक्ष|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_साथ|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_सामने|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_हवाला_से|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के_हवाले_से|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_के|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_को|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_जरिये|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_जैसा|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_तक|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_द्वारा|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_ने|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_पर_से|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_पर|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_बाद|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_बीच|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_में_से|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_में|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_वाला|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_समेत|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_सहित|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_सामने|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_से_आगे|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_से_पहले|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_से_पीछे|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_से_बाहर|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_से_लेकर|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-0_से|tam-|voicetype-
NN	n	gen-m|num-pl|pers-3|case-o|vib-|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-d|vib-|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_उपग्रह|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_कंप्यूटर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_अपेक्षा|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_ओर_से|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_ओर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_जगह|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_तरफ_से|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_तरफ|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_तरह|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_तुलना_में|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_तौर_पर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_बाद|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_बाबत|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_भीतर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_ले|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_वजह_से|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_साथ|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का_हैसियत_से|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_का|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_की_तरह|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_की|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_अंतर्गत|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_अंदर_का|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_अंदर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_अंर्तगत|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_अतिरिक्त|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_अनुकूल|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_अनुरूप|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_अनुसार|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_अलावा|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_आगे|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_आधार_पर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_आसपास|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_ऊपर_से|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_ऊपर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_करीब|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_कारण|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_खिलाफ|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_चलते|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_जरिये|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_तहत|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_तौर_पर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_दरम्यान|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_दौरान|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_द्वारा|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_नजदीक|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_नाते|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_नीचे|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_परिणामस्वरूप|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_पहले|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_पास_से|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_पास|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_पीछे_से|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_पीछे|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_प्रति|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बजाए|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बजाय|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बदले_में|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बदले|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बराबर_का|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बराबर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बहाना|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बाद_में|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बाद_से|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बाद|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बाबत|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बारे_में|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बावजूद|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बाहर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बीच_का|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बीच|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_भीतर_का|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_भीतर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_मद्देनजर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_मद्देनज़र|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_मद्देनज़र|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_मध्य_में|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_माध्यम_से|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_मार्फत|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_मुकाबला|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_मुताबिक|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_रूप_में|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_लिए|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_वक्त|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_विपरीत|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_संबंध_में|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_समक्ष|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_समय_पर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_समय|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_समान|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_समीप|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_सहारा|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_साथ|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_सामने|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_सिलसिले_में|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_हवाला_से|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_हिसाब_से|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के_ज़रिए|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_के|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_को|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_जैसा|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_जैसे|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_तक_का|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_तक_के_लिए|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_तक_में|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_तक|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_तले|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_द्वारा|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_ने|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_पर_से|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_पर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_पहले_से|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_फोन|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_बतौर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_बाद|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_भी|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_में_से|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_में|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_वाला_के_लिए|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_वाला_के_साथ|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_वाला_को|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_वाला_ने|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_वाला|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_विस्फोट|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_समान|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_समेत|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_सहित|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_से_ऊपर_का|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_से_दूर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_से_नीचे|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_से_पहला|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_से_पहले_का|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_से_पहले|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_से_पीछा|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_से_पीछे|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_से_पूर्व|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_से_बाहर_का|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_से_बाहर_तक|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_से_बाहर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_से_लेकर|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-0_से|tam-|voicetype-
NN	n	gen-m|num-sg|pers-3|case-o|vib-|tam-|voicetype-
NNC	n	gen-f|num-pl|pers-3|case-d|vib-|tam-|voicetype-
NNC	n	gen-f|num-pl|pers-3|case-o|vib-|tam-|voicetype-
NNC	n	gen-f|num-sg|pers-3|case-d|vib-|tam-|voicetype-
NNC	n	gen-f|num-sg|pers-3|case-o|vib-|tam-|voicetype-
NNC	n	gen-m|num-pl|pers-3|case-d|vib-|tam-|voicetype-
NNC	n	gen-m|num-pl|pers-3|case-o|vib-0_के|tam-|voicetype-
NNC	n	gen-m|num-sg|pers-3|case-d|vib-|tam-|voicetype-
NNC	n	gen-m|num-sg|pers-3|case-o|vib-0_को|tam-|voicetype-
NNC	n	gen-m|num-sg|pers-3|case-o|vib-|tam-|voicetype-
NNP	n	gen-f|num-pl|pers-3|case-d|vib-|tam-|voicetype-
NNP	n	gen-f|num-pl|pers-3|case-o|vib-0_का|tam-|voicetype-
NNP	n	gen-f|num-pl|pers-3|case-o|vib-0_के_पास|tam-|voicetype-
NNP	n	gen-f|num-pl|pers-3|case-o|vib-0_के_समक्ष|tam-|voicetype-
NNP	n	gen-f|num-pl|pers-3|case-o|vib-0_जैसा|tam-|voicetype-
NNP	n	gen-f|num-pl|pers-3|case-o|vib-0_द्वारा|tam-|voicetype-
NNP	n	gen-f|num-pl|pers-3|case-o|vib-0_ने|tam-|voicetype-
NNP	n	gen-f|num-pl|pers-3|case-o|vib-0_में|tam-|voicetype-
NNP	n	gen-f|num-pl|pers-3|case-o|vib-0_से|tam-|voicetype-
NNP	n	gen-f|num-pl|pers-3|case-o|vib-|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-d|vib-|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_का_ओर_से|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_का_ओर|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_का_तरफ_से|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_का_तरफ|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_का_तरह|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_का_वजह_से|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_का_साथ|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_का|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_अनुसार|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_अलावा|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_आसपास_के|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_आसपास|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_ऊपर|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_कारण|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_खिलाफ|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_चलते|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_जरिये|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_तहत|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_दौरान|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_निकट_का|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_निकट|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_पास_से|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_पास|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_पीछे|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_प्रति|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बाद|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बारे_में|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बाहर|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बीच_का|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_बीच|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_भीतर|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_मुताबिक|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_रूप_में|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_लिए|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_समय_में|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_समय|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_साथ|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_सामने|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_सौजन्य_से|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के_हवाला_से|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_के|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_को|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_जैसा|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_तक_का|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_तक_के_लिए|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_तक|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_द्वारा|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_ने|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_पर|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_फिल्म|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_में|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_समेत|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_सरीखा|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_सहित|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_से_आगे|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_से_बाहर|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-0_से|tam-|voicetype-
NNP	n	gen-f|num-sg|pers-3|case-o|vib-|tam-|voicetype-
NNP	n	gen-m|num-pl|pers-3|case-d|vib-|tam-|voicetype-
NNP	n	gen-m|num-pl|pers-3|case-o|vib-0_का_तरह|tam-|voicetype-
NNP	n	gen-m|num-pl|pers-3|case-o|vib-0_का|tam-|voicetype-
NNP	n	gen-m|num-pl|pers-3|case-o|vib-0_के_बारे_में|tam-|voicetype-
NNP	n	gen-m|num-pl|pers-3|case-o|vib-0_के_बूते|tam-|voicetype-
NNP	n	gen-m|num-pl|pers-3|case-o|vib-0_के_लिए|tam-|voicetype-
NNP	n	gen-m|num-pl|pers-3|case-o|vib-0_को|tam-|voicetype-
NNP	n	gen-m|num-pl|pers-3|case-o|vib-0_द्वारा|tam-|voicetype-
NNP	n	gen-m|num-pl|pers-3|case-o|vib-0_ने|tam-|voicetype-
NNP	n	gen-m|num-pl|pers-3|case-o|vib-0_पर|tam-|voicetype-
NNP	n	gen-m|num-pl|pers-3|case-o|vib-0_में|tam-|voicetype-
NNP	n	gen-m|num-pl|pers-3|case-o|vib-0_से|tam-|voicetype-
NNP	n	gen-m|num-pl|pers-3|case-o|vib-|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-d|vib-|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_का_अनुसार|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_का_अपेक्षा|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_का_ओर_से|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_का_ओर|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_का_जगह|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_का_तरफ_का|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_का_तरफ_से|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_का_तरफ|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_का_तरह|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_का_बजाय|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_का_बीच|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_का_भांति|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_का_वजह_से|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_का_साथ|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_का|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_की_ओर_से|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_अंतर्गत|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_अतंर्गत|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_अधीन|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_अनुरूप|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_अनुसार|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_अलावा|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_आसपास|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_उलट|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_ऊपर|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_करीब|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_कारण|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_खिलाफ|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_गिर्द|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_जरिये|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_तत्वावधान_में|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_तहत|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_तौर_पर|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_दौरान|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_नजदीक|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_नाते|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_निकट|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_नीचे|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_पहले|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_पास|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_प्रति|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बजाय|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बराबर_का|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बाद_का|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बाद_से|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बाद|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बारे_में|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बाहर|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बीच_का|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बीच_में|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_बीच|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_भीतर|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_मद्देनजर|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_मुकाबला|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_मुकाबले|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_मुताबिक|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_रुप_में|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_रूप_में|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_लिए|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_वक्त|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_विरुद्ध|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_विरूद्ध|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_संबंध_में|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_समक्ष|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_समय_से|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_समय|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_समान|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_समीप|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_साथ|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_सामने|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_हवाला_से|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के_हवाले_से|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_के|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_को|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_जैसा|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_जैसी|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_जैसे|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_तक_का|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_तक_के_लिए|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_तक|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_द्वारा|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_ने|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_पर|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_बकौल|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_बाद_का|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_मनमोहन|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_मार्च|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_में_से|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_में|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_रावण|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_वाला|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_विपिन|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_समेत|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_सहित|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_से_आगे|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_से_दूर|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_से_पहला_का|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_से_पहले_का|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_से_पहले|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_से_बाहर|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_से_लेकर|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-0_से|tam-|voicetype-
NNP	n	gen-m|num-sg|pers-3|case-o|vib-|tam-|voicetype-
NNPC	n	gen-f|num-pl|pers-3|case-d|vib-|tam-|voicetype-
NNPC	n	gen-f|num-sg|pers-3|case-d|vib-|tam-|voicetype-
NNPC	n	gen-f|num-sg|pers-3|case-o|vib-0_का_तरह|tam-|voicetype-
NNPC	n	gen-f|num-sg|pers-3|case-o|vib-|tam-|voicetype-
NNPC	n	gen-m|num-pl|pers-3|case-d|vib-|tam-|voicetype-
NNPC	n	gen-m|num-pl|pers-3|case-o|vib-|tam-|voicetype-
NNPC	n	gen-m|num-sg|pers-3|case-d|vib-|tam-|voicetype-
NNPC	n	gen-m|num-sg|pers-3|case-o|vib-0_का|tam-|voicetype-
NNPC	n	gen-m|num-sg|pers-3|case-o|vib-0_के|tam-|voicetype-
NNPC	n	gen-m|num-sg|pers-3|case-o|vib-0_ने|tam-|voicetype-
NNPC	n	gen-m|num-sg|pers-3|case-o|vib-|tam-|voicetype-
NST	nst	gen-f|num-sg|pers-3|case-d|vib-|tam-|voicetype-
NST	nst	gen-m|num-sg|pers-3|case-d|vib-|tam-|voicetype-
NSTC	nst	gen-m|num-sg|pers-3|case-d|vib-|tam-|voicetype-
NULL	_	gen-|num-|pers-|case-|vib-|tam-|voicetype-
PRP	pn	gen-f|num-pl|pers-1|case-d|vib-|tam-|voicetype-
PRP	pn	gen-f|num-pl|pers-1|case-o|vib-0_ओर_से|tam-kA|voicetype-
PRP	pn	gen-f|num-pl|pers-1|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-f|num-pl|pers-1|case-o|vib-|tam-|voicetype-
PRP	pn	gen-f|num-pl|pers-1|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-f|num-pl|pers-3|case-d|vib-|tam-|voicetype-
PRP	pn	gen-f|num-pl|pers-3|case-o|vib-0_वजह_से|tam-kA|voicetype-
PRP	pn	gen-f|num-pl|pers-3|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-f|num-pl|pers-3|case-o|vib-|tam-|voicetype-
PRP	pn	gen-f|num-pl|pers-3|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-f|num-sg|pers-1|case-d|vib-|tam-|voicetype-
PRP	pn	gen-f|num-sg|pers-1|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-f|num-sg|pers-1|case-o|vib-|tam-|voicetype-
PRP	pn	gen-f|num-sg|pers-1|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-f|num-sg|pers-2h|case-d|vib-|tam-|voicetype-
PRP	pn	gen-f|num-sg|pers-2h|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-f|num-sg|pers-2h|case-o|vib-|tam-|voicetype-
PRP	pn	gen-f|num-sg|pers-2h|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-f|num-sg|pers-3h|case-d|vib-|tam-|voicetype-
PRP	pn	gen-f|num-sg|pers-3h|case-o|vib-0_ओर_से|tam-kA|voicetype-
PRP	pn	gen-f|num-sg|pers-3h|case-o|vib-0_तरफ_से|tam-kA|voicetype-
PRP	pn	gen-f|num-sg|pers-3h|case-o|vib-0_वजह_से|tam-kA|voicetype-
PRP	pn	gen-f|num-sg|pers-3h|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-f|num-sg|pers-3h|case-o|vib-|tam-ko|voicetype-
PRP	pn	gen-f|num-sg|pers-3h|case-o|vib-|tam-|voicetype-
PRP	pn	gen-f|num-sg|pers-3h|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-f|num-sg|pers-3h|case-o|vib-को|tam-ko|voicetype-
PRP	pn	gen-f|num-sg|pers-3|case-d|vib-|tam-|voicetype-
PRP	pn	gen-f|num-sg|pers-3|case-o|vib-0_ओर_से|tam-kA|voicetype-
PRP	pn	gen-f|num-sg|pers-3|case-o|vib-0_ओर|tam-kA|voicetype-
PRP	pn	gen-f|num-sg|pers-3|case-o|vib-0_वजह_से|tam-kA|voicetype-
PRP	pn	gen-f|num-sg|pers-3|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-f|num-sg|pers-3|case-o|vib-|tam-ne|voicetype-
PRP	pn	gen-f|num-sg|pers-3|case-o|vib-|tam-|voicetype-
PRP	pn	gen-f|num-sg|pers-3|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-f|num-sg|pers-3|case-o|vib-ने|tam-ne|voicetype-
PRP	pn	gen-f|num-|pers-1|case-d|vib-|tam-|voicetype-
PRP	pn	gen-f|num-|pers-1|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-f|num-|pers-1|case-o|vib-|tam-|voicetype-
PRP	pn	gen-f|num-|pers-1|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-f|num-|pers-3h|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-f|num-|pers-3h|case-o|vib-|tam-|voicetype-
PRP	pn	gen-f|num-|pers-3h|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-f|num-|pers-3|case-o|vib-0_ओर_से|tam-|voicetype-
PRP	pn	gen-f|num-|pers-3|case-o|vib-|tam-|voicetype-
PRP	pn	gen-m|num-pl|pers-1|case-d|vib-|tam-|voicetype-
PRP	pn	gen-m|num-pl|pers-1|case-o|vib-0_पास|tam-kA|voicetype-
PRP	pn	gen-m|num-pl|pers-1|case-o|vib-0_पास|tam-ke|voicetype-
PRP	pn	gen-m|num-pl|pers-1|case-o|vib-0_लिए|tam-ke|voicetype-
PRP	pn	gen-m|num-pl|pers-1|case-o|vib-0_साथ|tam-ke|voicetype-
PRP	pn	gen-m|num-pl|pers-1|case-o|vib-0_सामने|tam-ke|voicetype-
PRP	pn	gen-m|num-pl|pers-1|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-m|num-pl|pers-1|case-o|vib-|tam-|voicetype-
PRP	pn	gen-m|num-pl|pers-1|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-m|num-pl|pers-3h|case-d|vib-|tam-|voicetype-
PRP	pn	gen-m|num-pl|pers-3h|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-m|num-pl|pers-3h|case-o|vib-|tam-|voicetype-
PRP	pn	gen-m|num-pl|pers-3h|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-d|vib-|tam-|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-0_अलावा|tam-ke|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-0_कारण|tam-ke|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-0_के_लिए|tam-|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-0_खिलाफ|tam-ke|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-0_चलते|tam-ke|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-0_द्वारा|tam-ke|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-0_पास_से|tam-ke|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-0_पास|tam-ke|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-0_प्रति|tam-ke|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-0_लिए|tam-ke|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-0_संग|tam-ke|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-0_साथ|tam-ke|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-|tam-|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-m|num-pl|pers-3|case-o|vib-के|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-1|case-d|vib-|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-1|case-o|vib-0_साथ|tam-kA|voicetype-
PRP	pn	gen-m|num-sg|pers-1|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-m|num-sg|pers-1|case-o|vib-|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-1|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-m|num-sg|pers-1|case-o|vib-के|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-2h|case-d|vib-|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-2h|case-o|vib-0_पास|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-2h|case-o|vib-0_लिए|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-2h|case-o|vib-0_सामने|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-2h|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-m|num-sg|pers-2h|case-o|vib-|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-2h|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-m|num-sg|pers-2|case-d|vib-|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-2|case-o|vib-0_बारे_में|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-2|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-m|num-sg|pers-2|case-o|vib-|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-d|vib-|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-0_अलावा|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-0_ऊपर|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-0_खिलाफ|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-0_जैसा|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-0_द्वारा|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-0_पर|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-0_पास|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-0_बकौल|tam-kA|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-0_मुताबिक|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-0_लिए|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-0_साथ|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-0_हवाला_से|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-|tam-ko|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-|tam-ne|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-|tam-se|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-का|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-के|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-को|tam-ko|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-ने|tam-ne|voicetype-
PRP	pn	gen-m|num-sg|pers-3h|case-o|vib-से|tam-se|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-d|vib-|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_अनुसार|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_अलावा|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_आगे|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_आसपास_का|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_आसपास|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_उलट|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_एवज_में|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_का|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_कारण|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_के_खिलाफ|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_के_प्रति|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_के_साथ|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_के|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_को|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_खिलाफ|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_चलते|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_जरिये|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_तहत|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_द्वारा|tam-kA|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_द्वारा|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_पर|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_परिणामस्वरूप|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_पश्चात|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_पहले|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_पास_का|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_पास|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_पीछे|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_पूर्व|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_प्रति|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_फलस्वरूप|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_बगल_का|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_बगल_में|tam-kA|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_बजाय|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_बदले|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_बाद_से|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_बाद|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_बारे_में|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_बारे_में|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_बावजूद|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_मद्देनजर|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_मद्देनज़र|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_माध्यम_से|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_मुताबिक|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_में|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_लिए|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_साथ|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_सामना|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-0_से|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-|tam-meM|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-|tam-ne|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-|tam-se|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-|tam-|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-के|tam-ke|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-ने|tam-ne|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-में|tam-meM|voicetype-
PRP	pn	gen-m|num-sg|pers-3|case-o|vib-से|tam-se|voicetype-
PRP	pn	gen-m|num-sg|pers-|case-d|vib-|tam-|voicetype-
PRP	pn	gen-m|num-|pers-|case-d|vib-|tam-|voicetype-
PRP	pn	gen-m|num-|pers-|case-o|vib-|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-1|case-d|vib-|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-1|case-o|vib-0_को|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-1|case-o|vib-0_जैसे|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-1|case-o|vib-0_बीच|tam-ke|voicetype-
PRP	pn	gen-|num-pl|pers-1|case-o|vib-0_में_से|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-1|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-|num-pl|pers-1|case-o|vib-|tam-ko|voicetype-
PRP	pn	gen-|num-pl|pers-1|case-o|vib-|tam-meM|voicetype-
PRP	pn	gen-|num-pl|pers-1|case-o|vib-|tam-ne|voicetype-
PRP	pn	gen-|num-pl|pers-1|case-o|vib-|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-1|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-|num-pl|pers-1|case-o|vib-को|tam-ko|voicetype-
PRP	pn	gen-|num-pl|pers-1|case-o|vib-ने|tam-ne|voicetype-
PRP	pn	gen-|num-pl|pers-1|case-o|vib-में|tam-meM|voicetype-
PRP	pn	gen-|num-pl|pers-2|case-d|vib-|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-2|case-o|vib-|tam-ko|voicetype-
PRP	pn	gen-|num-pl|pers-2|case-o|vib-|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-2|case-o|vib-को|tam-ko|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-d|vib-|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_अलावा|tam-ke|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_का|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_के_बारे_में|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_के_माध्यम_से|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_के_लिए|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_को|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_खिलाफ|tam-ke|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_जरिये|tam-ke|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_तक|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_पर|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_पास|tam-ke|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_प्रति|tam-ke|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_बारे_में|tam-ke|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_बावजूद|tam-ke|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_में_से|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_लिए|tam-ke|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_साथ|tam-ke|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_सामने|tam-ke|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-0_से|tam-meM|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-|tam-ko|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-|tam-meM|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-|tam-ne|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-|tam-se|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-|tam-|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-को|tam-ko|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-ने|tam-ne|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-में|tam-meM|voicetype-
PRP	pn	gen-|num-pl|pers-3|case-o|vib-से|tam-se|voicetype-
PRP	pn	gen-|num-pl|pers-|case-d|vib-|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-1h|case-d|vib-|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-1h|case-o|vib-|tam-ne|voicetype-
PRP	pn	gen-|num-sg|pers-1h|case-o|vib-|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-1h|case-o|vib-ने|tam-ne|voicetype-
PRP	pn	gen-|num-sg|pers-1|case-d|vib-|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-1|case-o|vib-0_जैसा|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-1|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-|num-sg|pers-1|case-o|vib-|tam-ko|voicetype-
PRP	pn	gen-|num-sg|pers-1|case-o|vib-|tam-meM|voicetype-
PRP	pn	gen-|num-sg|pers-1|case-o|vib-|tam-ne|voicetype-
PRP	pn	gen-|num-sg|pers-1|case-o|vib-|tam-se|voicetype-
PRP	pn	gen-|num-sg|pers-1|case-o|vib-|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-1|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-|num-sg|pers-1|case-o|vib-को|tam-ko|voicetype-
PRP	pn	gen-|num-sg|pers-1|case-o|vib-ने|tam-ne|voicetype-
PRP	pn	gen-|num-sg|pers-1|case-o|vib-में|tam-meM|voicetype-
PRP	pn	gen-|num-sg|pers-1|case-o|vib-से|tam-se|voicetype-
PRP	pn	gen-|num-sg|pers-2h|case-d|vib-|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-2h|case-o|vib-0_पास|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-2h|case-o|vib-0_से|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-2h|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-|num-sg|pers-2h|case-o|vib-|tam-ko|voicetype-
PRP	pn	gen-|num-sg|pers-2h|case-o|vib-|tam-ne|voicetype-
PRP	pn	gen-|num-sg|pers-2h|case-o|vib-|tam-se|voicetype-
PRP	pn	gen-|num-sg|pers-2h|case-o|vib-|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-2h|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-|num-sg|pers-2h|case-o|vib-को|tam-ko|voicetype-
PRP	pn	gen-|num-sg|pers-2h|case-o|vib-ने|tam-ne|voicetype-
PRP	pn	gen-|num-sg|pers-2h|case-o|vib-से|tam-se|voicetype-
PRP	pn	gen-|num-sg|pers-2|case-d|vib-|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-2|case-o|vib-|tam-ne|voicetype-
PRP	pn	gen-|num-sg|pers-2|case-o|vib-|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-2|case-o|vib-ने|tam-ne|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-d|vib-|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-0_अलावा|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-0_खिलाफ|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-0_पर|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-0_पास|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-0_मुताबिक|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-0_लिए|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-0_विरोध_में|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-0_साथ|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-|tam-ko|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-|tam-meM|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-|tam-ne|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-|tam-se|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-के|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-को|tam-ko|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-ने|tam-ne|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-ने|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-में|tam-meM|voicetype-
PRP	pn	gen-|num-sg|pers-3h|case-o|vib-से|tam-se|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-d|vib-|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_अतिरिक्त|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_अलावा|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_आगे|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_आसपास_का|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_उलट|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_ऊपर|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_का|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_कारण|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_के_खिलाफ|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_के_चलते|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_के_तहत|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_के_पास|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_के_बाद|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_के_मद्देनजर|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_के_साथ|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_को|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_खिलाफ|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_चलते|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_जरिये|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_तहत|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_ने|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_पर|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_परिणामस्वरूप|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_पहला|tam-se|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_पहले|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_पहले|tam-se|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_पास_का|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_पास|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_पीछे|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_पूर्व|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_पूर्व|tam-se|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_प्रति|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_बाद_से|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_बाद|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_बाबत|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_बारे_में|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_बारे_में|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_बावजूद|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_बाहर|tam-se|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_मद्देनजर|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_मुताबिक|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_में_में|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_में|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_लिए|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_वजह_से|tam-kA|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_समक्ष|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_साथ|tam-ke|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_से|tam-meM|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-0_से|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-|tam-ko|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-|tam-meM|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-|tam-ne|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-|tam-se|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-का|tam-kA|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-को|tam-ko|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-ने|tam-ne|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-में|tam-meM|voicetype-
PRP	pn	gen-|num-sg|pers-3|case-o|vib-से|tam-se|voicetype-
PRP	pn	gen-|num-sg|pers-|case-d|vib-|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-|case-o|vib-0_से|tam-|voicetype-
PRP	pn	gen-|num-sg|pers-|case-o|vib-|tam-|voicetype-
PRP	pn	gen-|num-|pers-2h|case-d|vib-|tam-|voicetype-
PRP	pn	gen-|num-|pers-3|case-d|vib-|tam-|voicetype-
PRP	pn	gen-|num-|pers-3|case-o|vib-0_बाद|tam-ke|voicetype-
PRP	pn	gen-|num-|pers-3|case-o|vib-|tam-kA|voicetype-
PRP	pn	gen-|num-|pers-3|case-o|vib-|tam-|voicetype-
PRP	pn	gen-|num-|pers-|case-d|vib-0_तक|tam-|voicetype-
PRP	pn	gen-|num-|pers-|case-d|vib-|tam-|voicetype-
PRP	pn	gen-|num-|pers-|case-o|vib-0_का|tam-|voicetype-
PRP	pn	gen-|num-|pers-|case-o|vib-0_के_लिए|tam-|voicetype-
PRP	pn	gen-|num-|pers-|case-o|vib-0_के|tam-|voicetype-
PRP	pn	gen-|num-|pers-|case-o|vib-0_को|tam-|voicetype-
PRP	pn	gen-|num-|pers-|case-o|vib-0_तक_का|tam-|voicetype-
PRP	pn	gen-|num-|pers-|case-o|vib-0_तक|tam-|voicetype-
PRP	pn	gen-|num-|pers-|case-o|vib-0_पर|tam-|voicetype-
PRP	pn	gen-|num-|pers-|case-o|vib-0_में|tam-|voicetype-
PRP	pn	gen-|num-|pers-|case-o|vib-0_से_ले|tam-|voicetype-
PRP	pn	gen-|num-|pers-|case-o|vib-0_से|tam-|voicetype-
PRP	pn	gen-|num-|pers-|case-o|vib-|tam-ko|voicetype-
PRP	pn	gen-|num-|pers-|case-o|vib-|tam-|voicetype-
PRP	pn	gen-|num-|pers-|case-o|vib-को|tam-ko|voicetype-
PRP	pn	gen-|num-|pers-|case-|vib-0_तक|tam-|voicetype-
PRP	pn	gen-|num-|pers-|case-|vib-|tam-|voicetype-
PRPC	pn	gen-m|num-sg|pers-3|case-d|vib-|tam-|voicetype-
PRPC	pn	gen-m|num-sg|pers-|case-d|vib-|tam-|voicetype-
PRPC	pn	gen-m|num-|pers-|case-d|vib-|tam-|voicetype-
PRPC	pn	gen-m|num-|pers-|case-o|vib-|tam-|voicetype-
PRPC	pn	gen-|num-pl|pers-1|case-d|vib-|tam-|voicetype-
PRPC	pn	gen-|num-pl|pers-3|case-d|vib-|tam-|voicetype-
PRPC	pn	gen-|num-pl|pers-|case-d|vib-|tam-|voicetype-
PRPC	pn	gen-|num-sg|pers-3|case-d|vib-|tam-|voicetype-
PRPC	pn	gen-|num-|pers-3|case-d|vib-|tam-|voicetype-
PRPC	pn	gen-|num-|pers-|case-d|vib-|tam-|voicetype-
PRPC	pn	gen-|num-|pers-|case-|vib-|tam-|voicetype-
PSP	psp	gen-f|num-pl|pers-|case-d|vib-|tam-|voicetype-
PSP	psp	gen-f|num-pl|pers-|case-o|vib-|tam-|voicetype-
PSP	psp	gen-f|num-sg|pers-|case-d|vib-|tam-|voicetype-
PSP	psp	gen-f|num-sg|pers-|case-o|vib-|tam-|voicetype-
PSP	psp	gen-f|num-|pers-|case-d|vib-|tam-|voicetype-
PSP	psp	gen-f|num-|pers-|case-o|vib-|tam-|voicetype-
PSP	psp	gen-m|num-pl|pers-|case-d|vib-|tam-|voicetype-
PSP	psp	gen-m|num-pl|pers-|case-o|vib-|tam-|voicetype-
PSP	psp	gen-m|num-sg|pers-|case-d|vib-|tam-|voicetype-
PSP	psp	gen-m|num-sg|pers-|case-o|vib-|tam-|voicetype-
PSP	psp	gen-|num-|pers-|case-|vib-|tam-|voicetype-
QC	num	gen-|num-pl|pers-|case-d|vib-|tam-|voicetype-
QC	num	gen-|num-pl|pers-|case-o|vib-0_का_जगह|tam-|voicetype-
QC	num	gen-|num-pl|pers-|case-o|vib-0_का|tam-|voicetype-
QC	num	gen-|num-pl|pers-|case-o|vib-0_के|tam-|voicetype-
QC	num	gen-|num-pl|pers-|case-o|vib-0_को|tam-|voicetype-
QC	num	gen-|num-pl|pers-|case-o|vib-0_तक|tam-|voicetype-
QC	num	gen-|num-pl|pers-|case-o|vib-0_ने|tam-|voicetype-
QC	num	gen-|num-pl|pers-|case-o|vib-0_में_से|tam-|voicetype-
QC	num	gen-|num-pl|pers-|case-o|vib-0_से_का|tam-|voicetype-
QC	num	gen-|num-pl|pers-|case-o|vib-0_से|tam-|voicetype-
QC	num	gen-|num-pl|pers-|case-o|vib-|tam-|voicetype-
QC	num	gen-|num-pl|pers-|case-|vib-0_का|tam-|voicetype-
QC	num	gen-|num-pl|pers-|case-|vib-0_को|tam-|voicetype-
QC	num	gen-|num-pl|pers-|case-|vib-0_से|tam-|voicetype-
QC	num	gen-|num-pl|pers-|case-|vib-|tam-|voicetype-
QC	num	gen-|num-|pers-|case-|vib-|tam-|voicetype-
QCC	num	gen-|num-|pers-|case-|vib-|tam-|voicetype-
QF	avy	gen-|num-|pers-|case-|vib-|tam-|voicetype-
QFC	avy	gen-|num-|pers-|case-|vib-|tam-|voicetype-
QO	num	gen-f|num-sg|pers-|case-d|vib-|tam-|voicetype-
QO	num	gen-f|num-sg|pers-|case-o|vib-|tam-|voicetype-
QO	num	gen-m|num-pl|pers-|case-o|vib-|tam-|voicetype-
QO	num	gen-m|num-sg|pers-3|case-d|vib-|tam-|voicetype-
QO	num	gen-m|num-sg|pers-|case-d|vib-|tam-|voicetype-
QO	num	gen-m|num-sg|pers-|case-o|vib-|tam-|voicetype-
QO	num	gen-m|num-|pers-|case-d|vib-|tam-|voicetype-
QO	num	gen-|num-pl|pers-|case-o|vib-0_का|tam-|voicetype-
QO	num	gen-|num-pl|pers-|case-o|vib-0_से|tam-|voicetype-
QO	num	gen-|num-pl|pers-|case-o|vib-|tam-|voicetype-
QO	num	gen-|num-pl|pers-|case-|vib-|tam-|voicetype-
QO	num	gen-|num-|pers-|case-|vib-|tam-|voicetype-
RB	adv	gen-|num-|pers-|case-|vib-|tam-|voicetype-
RBC	adv	gen-|num-|pers-|case-|vib-|tam-|voicetype-
RDP	adj	gen-f|num-pl|pers-|case-d|vib-|tam-|voicetype-
RDP	adj	gen-f|num-pl|pers-|case-o|vib-|tam-|voicetype-
RDP	adj	gen-f|num-sg|pers-|case-d|vib-|tam-|voicetype-
RDP	adj	gen-m|num-pl|pers-|case-d|vib-|tam-|voicetype-
RDP	adj	gen-m|num-pl|pers-|case-o|vib-|tam-|voicetype-
RDP	adj	gen-m|num-sg|pers-|case-o|vib-|tam-|voicetype-
RDP	adj	gen-|num-|pers-|case-d|vib-|tam-|voicetype-
RDP	adj	gen-|num-|pers-|case-o|vib-|tam-|voicetype-
RDP	adv	gen-|num-|pers-|case-|vib-|tam-|voicetype-
RDP	avy	gen-|num-|pers-|case-|vib-|tam-|voicetype-
RDP	n	gen-f|num-sg|pers-3|case-d|vib-|tam-|voicetype-
RDP	n	gen-f|num-sg|pers-3|case-o|vib-|tam-|voicetype-
RDP	n	gen-m|num-pl|pers-3|case-d|vib-|tam-|voicetype-
RDP	n	gen-m|num-sg|pers-3|case-d|vib-|tam-|voicetype-
RDP	n	gen-m|num-sg|pers-3|case-o|vib-|tam-|voicetype-
RDP	nst	gen-m|num-sg|pers-3|case-d|vib-|tam-|voicetype-
RDP	nst	gen-m|num-sg|pers-3|case-o|vib-|tam-|voicetype-
RDP	num	gen-|num-|pers-|case-o|vib-|tam-|voicetype-
RDP	num	gen-|num-|pers-|case-|vib-|tam-|voicetype-
RDP	pn	gen-f|num-pl|pers-|case-d|vib-|tam-|voicetype-
RDP	pn	gen-m|num-sg|pers-|case-d|vib-|tam-|voicetype-
RDP	pn	gen-m|num-|pers-|case-d|vib-|tam-|voicetype-
RDP	pn	gen-m|num-|pers-|case-o|vib-|tam-|voicetype-
RDP	v	gen-m|num-pl|pers-3|case-|vib-|tam-wA|voicetype-
RDP	v	gen-m|num-pl|pers-3|case-|vib-ता|tam-wA|voicetype-
RDP	v	gen-m|num-sg|pers-3|case-|vib-|tam-wA|voicetype-
RDP	v	gen-m|num-sg|pers-3|case-|vib-ता|tam-wA|voicetype-
RDP	v	gen-m|num-sg|pers-|case-|vib-|tam-wA|voicetype-
RDP	v	gen-m|num-sg|pers-|case-|vib-ता|tam-wA|voicetype-
RDP	v	gen-|num-|pers-|case-|vib-|tam-|voicetype-
RP	avy	gen-|num-|pers-|case-|vib-|tam-|voicetype-
SYM	punc	gen-|num-|pers-|case-|vib-|tam-|voicetype-
UNK	unk	gen-|num-|pers-|case-|vib-|tam-|voicetype-
UNKC	unk	gen-|num-|pers-|case-|vib-|tam-|voicetype-
VAUX	v	gen-f|num-pl|pers-3|case-|vib-|tam-WA|voicetype-
VAUX	v	gen-f|num-pl|pers-3|case-|vib-|tam-gA|voicetype-
VAUX	v	gen-f|num-pl|pers-3|case-|vib-|tam-wA|voicetype-
VAUX	v	gen-f|num-pl|pers-3|case-|vib-|tam-yA|voicetype-
VAUX	v	gen-f|num-pl|pers-3|case-|vib-गा|tam-gA|voicetype-
VAUX	v	gen-f|num-pl|pers-3|case-|vib-ता|tam-wA|voicetype-
VAUX	v	gen-f|num-pl|pers-3|case-|vib-था|tam-WA|voicetype-
VAUX	v	gen-f|num-pl|pers-3|case-|vib-या|tam-yA|voicetype-
VAUX	v	gen-f|num-pl|pers-|case-|vib-|tam-WA|voicetype-
VAUX	v	gen-f|num-pl|pers-|case-|vib-|tam-wA|voicetype-
VAUX	v	gen-f|num-pl|pers-|case-|vib-|tam-yA|voicetype-
VAUX	v	gen-f|num-pl|pers-|case-|vib-ता|tam-wA|voicetype-
VAUX	v	gen-f|num-pl|pers-|case-|vib-था|tam-WA|voicetype-
VAUX	v	gen-f|num-pl|pers-|case-|vib-या|tam-yA|voicetype-
VAUX	v	gen-f|num-sg|pers-1|case-|vib-|tam-gA|voicetype-
VAUX	v	gen-f|num-sg|pers-1|case-|vib-गा|tam-gA|voicetype-
VAUX	v	gen-f|num-sg|pers-2h|case-|vib-|tam-gA|voicetype-
VAUX	v	gen-f|num-sg|pers-2h|case-|vib-गा|tam-gA|voicetype-
VAUX	v	gen-f|num-sg|pers-3h|case-|vib-|tam-WA|voicetype-
VAUX	v	gen-f|num-sg|pers-3h|case-|vib-|tam-gA|voicetype-
VAUX	v	gen-f|num-sg|pers-3h|case-|vib-|tam-wA|voicetype-
VAUX	v	gen-f|num-sg|pers-3h|case-|vib-|tam-yA|voicetype-
VAUX	v	gen-f|num-sg|pers-3h|case-|vib-गा|tam-gA|voicetype-
VAUX	v	gen-f|num-sg|pers-3h|case-|vib-ता|tam-wA|voicetype-
VAUX	v	gen-f|num-sg|pers-3h|case-|vib-था|tam-WA|voicetype-
VAUX	v	gen-f|num-sg|pers-3h|case-|vib-या|tam-yA|voicetype-
VAUX	v	gen-f|num-sg|pers-3|case-|vib-|tam-WA|voicetype-
VAUX	v	gen-f|num-sg|pers-3|case-|vib-|tam-gA|voicetype-
VAUX	v	gen-f|num-sg|pers-3|case-|vib-|tam-wA|voicetype-
VAUX	v	gen-f|num-sg|pers-3|case-|vib-|tam-yA1|voicetype-
VAUX	v	gen-f|num-sg|pers-3|case-|vib-|tam-yA|voicetype-
VAUX	v	gen-f|num-sg|pers-3|case-|vib-गा|tam-gA|voicetype-
VAUX	v	gen-f|num-sg|pers-3|case-|vib-ता|tam-wA|voicetype-
VAUX	v	gen-f|num-sg|pers-3|case-|vib-था|tam-WA|voicetype-
VAUX	v	gen-f|num-sg|pers-3|case-|vib-या|tam-yA|voicetype-
VAUX	v	gen-f|num-sg|pers-3|case-|vib-या१|tam-yA1|voicetype-
VAUX	v	gen-f|num-sg|pers-|case-|vib-|tam-WA|voicetype-
VAUX	v	gen-f|num-sg|pers-|case-|vib-|tam-gA|voicetype-
VAUX	v	gen-f|num-sg|pers-|case-|vib-|tam-nA|voicetype-
VAUX	v	gen-f|num-sg|pers-|case-|vib-|tam-wA|voicetype-
VAUX	v	gen-f|num-sg|pers-|case-|vib-|tam-yA1|voicetype-
VAUX	v	gen-f|num-sg|pers-|case-|vib-|tam-yA|voicetype-
VAUX	v	gen-f|num-sg|pers-|case-|vib-गा|tam-gA|voicetype-
VAUX	v	gen-f|num-sg|pers-|case-|vib-ता|tam-wA|voicetype-
VAUX	v	gen-f|num-sg|pers-|case-|vib-था|tam-WA|voicetype-
VAUX	v	gen-f|num-sg|pers-|case-|vib-ना|tam-nA|voicetype-
VAUX	v	gen-f|num-sg|pers-|case-|vib-या|tam-yA|voicetype-
VAUX	v	gen-f|num-sg|pers-|case-|vib-या१|tam-yA1|voicetype-
VAUX	v	gen-m|num-pl|pers-1|case-|vib-|tam-gA|voicetype-
VAUX	v	gen-m|num-pl|pers-1|case-|vib-गा|tam-gA|voicetype-
VAUX	v	gen-m|num-pl|pers-2|case-|vib-|tam-gA|voicetype-
VAUX	v	gen-m|num-pl|pers-2|case-|vib-गा|tam-gA|voicetype-
VAUX	v	gen-m|num-pl|pers-3|case-|vib-|tam-gA|voicetype-
VAUX	v	gen-m|num-pl|pers-3|case-|vib-गा|tam-gA|voicetype-
VAUX	v	gen-m|num-pl|pers-|case-|vib-|tam-WA|voicetype-
VAUX	v	gen-m|num-pl|pers-|case-|vib-|tam-nA|voicetype-
VAUX	v	gen-m|num-pl|pers-|case-|vib-|tam-wA|voicetype-
VAUX	v	gen-m|num-pl|pers-|case-|vib-|tam-yA1|voicetype-
VAUX	v	gen-m|num-pl|pers-|case-|vib-|tam-yA|voicetype-
VAUX	v	gen-m|num-pl|pers-|case-|vib-ता|tam-wA|voicetype-
VAUX	v	gen-m|num-pl|pers-|case-|vib-था|tam-WA|voicetype-
VAUX	v	gen-m|num-pl|pers-|case-|vib-ना|tam-nA|voicetype-
VAUX	v	gen-m|num-pl|pers-|case-|vib-या|tam-yA|voicetype-
VAUX	v	gen-m|num-pl|pers-|case-|vib-या१|tam-yA1|voicetype-
VAUX	v	gen-m|num-sg|pers-1|case-|vib-|tam-gA|voicetype-
VAUX	v	gen-m|num-sg|pers-1|case-|vib-गा|tam-gA|voicetype-
VAUX	v	gen-m|num-sg|pers-2h|case-|vib-|tam-gA|voicetype-
VAUX	v	gen-m|num-sg|pers-2h|case-|vib-|tam-wA|voicetype-
VAUX	v	gen-m|num-sg|pers-2h|case-|vib-गा|tam-gA|voicetype-
VAUX	v	gen-m|num-sg|pers-2h|case-|vib-ता|tam-wA|voicetype-
VAUX	v	gen-m|num-sg|pers-3h|case-|vib-|tam-WA|voicetype-
VAUX	v	gen-m|num-sg|pers-3h|case-|vib-|tam-gA|voicetype-
VAUX	v	gen-m|num-sg|pers-3h|case-|vib-|tam-hE|voicetype-
VAUX	v	gen-m|num-sg|pers-3h|case-|vib-|tam-wA|voicetype-
VAUX	v	gen-m|num-sg|pers-3h|case-|vib-|tam-yA1|voicetype-
VAUX	v	gen-m|num-sg|pers-3h|case-|vib-|tam-yA|voicetype-
VAUX	v	gen-m|num-sg|pers-3h|case-|vib-गा|tam-gA|voicetype-
VAUX	v	gen-m|num-sg|pers-3h|case-|vib-ता|tam-wA|voicetype-
VAUX	v	gen-m|num-sg|pers-3h|case-|vib-था|tam-WA|voicetype-
VAUX	v	gen-m|num-sg|pers-3h|case-|vib-या|tam-yA|voicetype-
VAUX	v	gen-m|num-sg|pers-3h|case-|vib-या१|tam-yA1|voicetype-
VAUX	v	gen-m|num-sg|pers-3h|case-|vib-है|tam-hE|voicetype-
VAUX	v	gen-m|num-sg|pers-3|case-|vib-|tam-gA|voicetype-
VAUX	v	gen-m|num-sg|pers-3|case-|vib-गा|tam-gA|voicetype-
VAUX	v	gen-m|num-sg|pers-|case-|vib-|tam-WA|voicetype-
VAUX	v	gen-m|num-sg|pers-|case-|vib-|tam-nA|voicetype-
VAUX	v	gen-m|num-sg|pers-|case-|vib-|tam-wA|voicetype-
VAUX	v	gen-m|num-sg|pers-|case-|vib-|tam-yA1|voicetype-
VAUX	v	gen-m|num-sg|pers-|case-|vib-|tam-yA|voicetype-
VAUX	v	gen-m|num-sg|pers-|case-|vib-ता|tam-wA|voicetype-
VAUX	v	gen-m|num-sg|pers-|case-|vib-था|tam-WA|voicetype-
VAUX	v	gen-m|num-sg|pers-|case-|vib-ना|tam-nA|voicetype-
VAUX	v	gen-m|num-sg|pers-|case-|vib-या|tam-yA|voicetype-
VAUX	v	gen-m|num-sg|pers-|case-|vib-या१|tam-yA1|voicetype-
VAUX	v	gen-|num-pl|pers-3|case-|vib-|tam-eM|voicetype-
VAUX	v	gen-|num-pl|pers-3|case-|vib-|tam-hE|voicetype-
VAUX	v	gen-|num-pl|pers-3|case-|vib-एं|tam-eM|voicetype-
VAUX	v	gen-|num-pl|pers-3|case-|vib-है|tam-hE|voicetype-
VAUX	v	gen-|num-sg|pers-1|case-|vib-|tam-hE|voicetype-
VAUX	v	gen-|num-sg|pers-1|case-|vib-है|tam-hE|voicetype-
VAUX	v	gen-|num-sg|pers-2h|case-|vib-|tam-hE|voicetype-
VAUX	v	gen-|num-sg|pers-2h|case-|vib-है|tam-hE|voicetype-
VAUX	v	gen-|num-sg|pers-2|case-|vib-|tam-hE|voicetype-
VAUX	v	gen-|num-sg|pers-2|case-|vib-है|tam-hE|voicetype-
VAUX	v	gen-|num-sg|pers-3h|case-|vib-|tam-hE|voicetype-
VAUX	v	gen-|num-sg|pers-3h|case-|vib-है|tam-hE|voicetype-
VAUX	v	gen-|num-sg|pers-3|case-|vib-|tam-eM|voicetype-
VAUX	v	gen-|num-sg|pers-3|case-|vib-|tam-hE|voicetype-
VAUX	v	gen-|num-sg|pers-3|case-|vib-एं|tam-eM|voicetype-
VAUX	v	gen-|num-sg|pers-3|case-|vib-है|tam-hE|voicetype-
VAUX	v	gen-|num-|pers-|case-d|vib-|tam-nA|voicetype-
VAUX	v	gen-|num-|pers-|case-d|vib-ना|tam-nA|voicetype-
VAUX	v	gen-|num-|pers-|case-o|vib-|tam-nA|voicetype-
VAUX	v	gen-|num-|pers-|case-o|vib-ना|tam-nA|voicetype-
VAUX	v	gen-|num-|pers-|case-|vib-|tam-kara|voicetype-
VAUX	v	gen-|num-|pers-|case-|vib-|tam-|voicetype-
VAUX	v	gen-|num-|pers-|case-|vib-कर|tam-kara|voicetype-
VM	v	gen-f|num-pl|pers-3|case-|vib-0_चुक+या_है|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_जा+ता_है|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_जा+या1_है|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_जा+या_है|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_जा+या१_था|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_जा+या१_है|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_दे+या_जा+गा|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_दे+या_जा+या१_है|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_दे+या_जा+या१_है|tam-|voicetype-passive
VM	v	gen-f|num-pl|pers-3|case-|vib-0_दे+या_है|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_दे+या_है|tam-|voicetype-passive
VM	v	gen-f|num-pl|pers-3|case-|vib-0_पा+या_है|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_पा_रह+या_है|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_रह+या_था|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_रह+या_है|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_रह+या_हैं+है|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_रह+या_हो|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_ले+या_है|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_सक+ता_है|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-0_सक+या_है|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-|tam-WA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-|tam-gA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-|tam-nA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-|tam-wA|voicetype-
VM	v	gen-f|num-pl|pers-3|case-|vib-|tam-wA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-|tam-yA|voicetype-
VM	v	gen-f|num-pl|pers-3|case-|vib-|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-f|num-pl|pers-3|case-|vib-|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-|tam-|voicetype-passive
VM	v	gen-f|num-pl|pers-3|case-|vib-गा|tam-gA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-ता_जा_रह+या_है|tam-wA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-ता_रह+ता_है|tam-wA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-ता_रह+या_है|tam-wA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-ता_है|tam-wA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-ता|tam-wA|voicetype-
VM	v	gen-f|num-pl|pers-3|case-|vib-था|tam-WA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-ना_पड+या|tam-nA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-ना_पड़+या|tam-nA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-ना_लग+या_है|tam-nA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-ना_हो+गा|tam-nA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या_जा+एं|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या_जा+गा|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या_जा+गा|tam-yA|voicetype-passive
VM	v	gen-f|num-pl|pers-3|case-|vib-या_जा+ता_रह+या_है|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या_जा+ता_है|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या_जा+ता_है|tam-yA|voicetype-passive
VM	v	gen-f|num-pl|pers-3|case-|vib-या_जा+या1_है|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या_जा+या_है|tam-yA|voicetype-passive
VM	v	gen-f|num-pl|pers-3|case-|vib-या_जा+या१_है|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या_जा+या१_है|tam-yA|voicetype-passive
VM	v	gen-f|num-pl|pers-3|case-|vib-या_जा+या१|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या_जा_चुक+या_है|tam-yA|voicetype-passive
VM	v	gen-f|num-pl|pers-3|case-|vib-या_जा_रह+या_है|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या_जा_रह+या_है|tam-yA|voicetype-passive
VM	v	gen-f|num-pl|pers-3|case-|vib-या_जा_सक+ता_है|tam-yA|voicetype-passive
VM	v	gen-f|num-pl|pers-3|case-|vib-या_था|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या_दे+या_है|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या_रह+ता_है|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या_सक+ता_है|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या_है|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या_है|tam-yA|voicetype-passive
VM	v	gen-f|num-pl|pers-3|case-|vib-या_हो+गा|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या_हो+या_है|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या|tam-yA|voicetype-
VM	v	gen-f|num-pl|pers-3|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-3|case-|vib-या|tam-yA|voicetype-passive
VM	v	gen-f|num-pl|pers-|case-o|vib-|tam-nA|voicetype-
VM	v	gen-f|num-pl|pers-|case-o|vib-|tam-wA|voicetype-
VM	v	gen-f|num-pl|pers-|case-o|vib-ता|tam-wA|voicetype-
VM	v	gen-f|num-pl|pers-|case-o|vib-ना|tam-nA|voicetype-
VM	v	gen-f|num-pl|pers-|case-|vib-0_कर+ता_था|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-0_दे+या_जा+या१_था|tam-|voicetype-passive
VM	v	gen-f|num-pl|pers-|case-|vib-0_दे+या_था|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-0_पा+या_था|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-0_रह+या_था|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-0_ले+या_था|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-|tam-WA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-|tam-nA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-|tam-wA|voicetype-
VM	v	gen-f|num-pl|pers-|case-|vib-|tam-wA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-|tam-yA1|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-|tam-yA|voicetype-
VM	v	gen-f|num-pl|pers-|case-|vib-|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-f|num-pl|pers-|case-|vib-|tam-|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-|tam-|voicetype-passive
VM	v	gen-f|num-pl|pers-|case-|vib-ता_था|tam-wA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-ता|tam-wA|voicetype-
VM	v	gen-f|num-pl|pers-|case-|vib-ता|tam-wA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-था|tam-WA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-ना_जा_रह+या_था|tam-nA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-ना_पड़+या|tam-nA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-या_जा+या_था|tam-yA|voicetype-passive
VM	v	gen-f|num-pl|pers-|case-|vib-या_जा+या१_था|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-या_जा+या१_है|tam-yA|voicetype-passive
VM	v	gen-f|num-pl|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-
VM	v	gen-f|num-pl|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-passive
VM	v	gen-f|num-pl|pers-|case-|vib-या_जा_रह+या_था|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-या_था|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-या_रह+या_था|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-या_है|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-या_हो+ना_की_वजह_से|tam-yA|voicetype-
VM	v	gen-f|num-pl|pers-|case-|vib-या_हो+या_था|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-या_हो+या_हो|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-या|tam-yA|voicetype-
VM	v	gen-f|num-pl|pers-|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-f|num-pl|pers-|case-|vib-या१_था|tam-yA1|voicetype-active
VM	v	gen-f|num-sg|pers-1|case-|vib-0_रह+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-1|case-|vib-0_सक+ता_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-1|case-|vib-|tam-gA|voicetype-active
VM	v	gen-f|num-sg|pers-1|case-|vib-|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-1|case-|vib-|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-1|case-|vib-|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-1|case-|vib-गा|tam-gA|voicetype-active
VM	v	gen-f|num-sg|pers-1|case-|vib-ता_है|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-1|case-|vib-या_है+ऊँ|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-1|case-|vib-या_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-2|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-2|case-|vib-या_जा+या१_है|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3h|case-|vib-0_चुक+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-0_जा+या1_है|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-3h|case-|vib-0_जा+या१_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-0_जा+या१_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-0_रह+या_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-0_रह+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-0_सक+ता_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-|tam-WA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-|tam-gA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-|tam-yA|voicetype-
VM	v	gen-f|num-sg|pers-3h|case-|vib-|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3h|case-|vib-|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-3h|case-|vib-गा|tam-gA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-ता_रह+ता_है|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-ता_रह+या_है|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-ता_रह+या|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-ता_है|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-ता|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-था|tam-WA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-ना_वाला_था|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-ना_वाला_है|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-या_जा+या१|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3h|case-|vib-या_था|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-या_दे+या|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-या_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-या_हो+या_था|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-या_हो+या_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3h|case-|vib-या|tam-yA|voicetype-
VM	v	gen-f|num-sg|pers-3h|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-d|vib-|tam-nA|voicetype-
VM	v	gen-f|num-sg|pers-3|case-d|vib-|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-d|vib-ना|tam-nA|voicetype-
VM	v	gen-f|num-sg|pers-3|case-d|vib-या|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-o|vib-|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-o|vib-ना_जा_रह+या_है|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-o|vib-ना_वाला_है|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_आ+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_उठ+ता_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_उठ+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_चुक+या_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_चुक+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_चुक+या_है|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-0_जा+ता_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_जा+या1_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_जा+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_जा+या१_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_जा+या१_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_जा+या१_है|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-0_दे+ता_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_दे+या_जा+एं|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_दे+या_जा+गा|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_दे+या_जा+गा|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-0_दे+या_जा+या1_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_दे+या_जा+या१_था|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-0_दे+या_जा+या१_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_दे+या_जा+या१_है|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-0_दे+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_पहुंच+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_पा+ता_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_पा+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_पा_रह+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_पाई_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_पड़+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_रख+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_रह+या_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_रह+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_ले+ता_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_ले+या_जा+एं|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_ले+या_जा+या1_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_ले+या_जा+या1_है|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-0_ले+या_जा+या१_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_ले+या_जा+या१_है|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-0_ले+या_जा+या१|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-0_ले+या_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_ले+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_सक+ता_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_सक+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-0_सक+या_है|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-|tam-WA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-|tam-gA|voicetype-
VM	v	gen-f|num-sg|pers-3|case-|vib-|tam-gA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-|tam-gA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-|tam-nA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-|tam-wA|voicetype-
VM	v	gen-f|num-sg|pers-3|case-|vib-|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-|tam-yA1|voicetype-
VM	v	gen-f|num-sg|pers-3|case-|vib-|tam-yA1|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-|tam-yA|voicetype-
VM	v	gen-f|num-sg|pers-3|case-|vib-|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-गा_है|tam-gA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-गा|tam-gA|voicetype-
VM	v	gen-f|num-sg|pers-3|case-|vib-गा|tam-gA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-गा|tam-gA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-ता_जा+या१_है|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ता_जा_रह+या_है|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ता_था|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ता_रह+गा|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ता_रह+ता_है|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ता_रह+या_है|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ता_है|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ता|tam-wA|voicetype-
VM	v	gen-f|num-sg|pers-3|case-|vib-ता|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-था|tam-WA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ना_जा_रह+या_है|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ना_जा_रह+या_है|tam-nA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-ना_पड+गा|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ना_पड+ता_है|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ना_पड़+गा|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ना_पड़_रह+या_है|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ना_लग+या_है|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ना_वाला_है|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ना_है|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ना_हो+गा|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-ना_हो+गा|tam-nA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-ना_हो+ता_है|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+एं|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+एं|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+गा|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+गा|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+ता_रह+या_है|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+ता_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+ता_है|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+ना_का_ओर|tam-yA|voicetype-
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+ना_का_वजह_से|tam-yA|voicetype-
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+ना_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+ना_है|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+या1_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+या1_है|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+या|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+या१_था|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+या१_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+या१_है|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+या१|tam-yA|voicetype-
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा+या१|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा_चुक+या_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा_चुक+या_है|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा_रह+या_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा_रह+या_है|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा_सक+ता_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जा_सक+ता_है|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_जाएगी+गा|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_था|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_था|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_दे+या_जा+गा|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_दे+या_जा+या१_है|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_दे_रह+या_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_रख+ना_हो+गा|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_रख+या_जा+एं|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_रह+गा|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_रह+ता_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_रह+या_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_रह+या|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_समा_रह+या_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_है|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-3|case-|vib-या_हो+गा|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या_हो+या_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या|tam-yA|voicetype-
VM	v	gen-f|num-sg|pers-3|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-या१|tam-yA1|voicetype-
VM	v	gen-f|num-sg|pers-3|case-|vib-या१|tam-yA1|voicetype-active
VM	v	gen-f|num-sg|pers-3|case-|vib-०_सक+ता_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-o|vib-|tam-nA|voicetype-
VM	v	gen-f|num-sg|pers-|case-o|vib-|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-o|vib-ना_वाला_था|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-o|vib-ना|tam-nA|voicetype-
VM	v	gen-f|num-sg|pers-|case-|vib-0_चुक+या_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-0_जा+ता_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-0_जा+या1_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-0_जा+या१_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-0_जा+या१_हो+ता|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-0_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-0_दे+या_जा+या१_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-0_दे+या_जा+या१_था|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-0_दे+या_जा+या१|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-0_दे+या_जा+या१|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-0_दे+या_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-0_पा+या_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-0_रह+या_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-0_रह+या_है|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-0_रह+या_हो+ता|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-0_ले+या_जा+या1_था|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-0_ले+या_जा+या१_था|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-0_ले+या_जा+या१|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-0_ले+या_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-0_सक+ता_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-0_सक+या_था|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-|tam-WA|voicetype-
VM	v	gen-f|num-sg|pers-|case-|vib-|tam-WA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-|tam-WA|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-|tam-nA|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-|tam-wA|voicetype-
VM	v	gen-f|num-sg|pers-|case-|vib-|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-|tam-yA1|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-|tam-yA|voicetype-
VM	v	gen-f|num-sg|pers-|case-|vib-|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-|tam-|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-|tam-|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-ता_जा+या१|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-ता_था|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-ता_बन+ता_था|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-ता_रह+या|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-ता_हो+या|tam-wA|voicetype-
VM	v	gen-f|num-sg|pers-|case-|vib-ता|tam-wA|voicetype-
VM	v	gen-f|num-sg|pers-|case-|vib-ता|tam-wA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-था|tam-WA|voicetype-
VM	v	gen-f|num-sg|pers-|case-|vib-था|tam-WA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-था|tam-WA|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-ना_था|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-ना_दे+या_जा+गा|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-ना_दे+या_था|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-ना_पड+या_था|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-ना_पड+या|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-ना_पड़+या_था|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-ना_पड़+या_था|tam-nA|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-ना_पड़+या|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-ना_लग+या_था|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-ना|tam-nA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_गया+या१|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा+एं|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा+ता_था|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा+ता|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा+ना_का_बजाय|tam-yA|voicetype-
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा+ना_का_बाबत|tam-yA|voicetype-
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा+ना_था|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा+या_था|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा+या|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा+या१_था|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा+या१_था|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा_चुक+या_था|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा_रह+या_था|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_जा_रह+या_था|tam-yA|voicetype-passive
VM	v	gen-f|num-sg|pers-|case-|vib-या_था|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_दे+या_था|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_दे+या|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_दे_रह+या_था|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_पड़+या|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_रख+या_था|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_रह+एं|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_रह+या|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_है|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_हो+ता|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_हो+या_था|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या_हो+या|tam-yA|voicetype-
VM	v	gen-f|num-sg|pers-|case-|vib-या|tam-yA|voicetype-
VM	v	gen-f|num-sg|pers-|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-f|num-sg|pers-|case-|vib-या१|tam-yA1|voicetype-active
VM	v	gen-f|num-|pers-|case-d|vib-|tam-nA|voicetype-
VM	v	gen-f|num-|pers-|case-d|vib-ना|tam-nA|voicetype-
VM	v	gen-f|num-|pers-|case-o|vib-|tam-nA|voicetype-
VM	v	gen-f|num-|pers-|case-o|vib-ना_का_खातिर|tam-nA|voicetype-
VM	v	gen-f|num-|pers-|case-o|vib-ना_का_जगह|tam-nA|voicetype-
VM	v	gen-f|num-|pers-|case-o|vib-ना_का_बजाय|tam-nA|voicetype-
VM	v	gen-f|num-|pers-|case-o|vib-ना_का_बाबत|tam-nA|voicetype-
VM	v	gen-f|num-|pers-|case-o|vib-ना_का_वजह_से|tam-nA|voicetype-
VM	v	gen-f|num-|pers-|case-o|vib-ना|tam-nA|voicetype-
VM	v	gen-f|num-|pers-|case-|vib-0_चुक+या_हो|tam-|voicetype-active
VM	v	gen-f|num-|pers-|case-|vib-0_जा+ना_का_वजह_से|tam-|voicetype-
VM	v	gen-f|num-|pers-|case-|vib-0_जा+ना_चाहिए|tam-|voicetype-active
VM	v	gen-f|num-|pers-|case-|vib-0_जा+या१_हो|tam-|voicetype-active
VM	v	gen-f|num-|pers-|case-|vib-0_दे+या_जा+ना_चाहिए|tam-|voicetype-active
VM	v	gen-f|num-|pers-|case-|vib-0_पा+ना_का_वजह_से|tam-|voicetype-
VM	v	gen-f|num-|pers-|case-|vib-0_पा+या_हो|tam-|voicetype-active
VM	v	gen-f|num-|pers-|case-|vib-0_रह+या_हो|tam-|voicetype-active
VM	v	gen-f|num-|pers-|case-|vib-0_ले+ना_चाहिए|tam-|voicetype-active
VM	v	gen-f|num-|pers-|case-|vib-|tam-nA|voicetype-
VM	v	gen-f|num-|pers-|case-|vib-|tam-nA|voicetype-active
VM	v	gen-f|num-|pers-|case-|vib-|tam-wA|voicetype-active
VM	v	gen-f|num-|pers-|case-|vib-|tam-yA|voicetype-active
VM	v	gen-f|num-|pers-|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-f|num-|pers-|case-|vib-|tam-|voicetype-
VM	v	gen-f|num-|pers-|case-|vib-|tam-|voicetype-active
VM	v	gen-f|num-|pers-|case-|vib-ता_हो|tam-wA|voicetype-active
VM	v	gen-f|num-|pers-|case-|vib-ना_का_बजाय|tam-nA|voicetype-
VM	v	gen-f|num-|pers-|case-|vib-ना_चाहिए|tam-nA|voicetype-active
VM	v	gen-f|num-|pers-|case-|vib-या_जा+एं|tam-yA|voicetype-active
VM	v	gen-f|num-|pers-|case-|vib-या_जा+ना_चाहिए|tam-yA|voicetype-active
VM	v	gen-f|num-|pers-|case-|vib-या_जा+ना_चाहिए|tam-yA|voicetype-passive
VM	v	gen-f|num-|pers-|case-|vib-या_जा+ना|tam-yA|voicetype-passive
VM	v	gen-f|num-|pers-|case-|vib-या_जा+या1_हो|tam-yA|voicetype-passive
VM	v	gen-f|num-|pers-|case-|vib-या_जाना_चाहिए|tam-yA|voicetype-passive
VM	v	gen-f|num-|pers-|case-|vib-या_हो|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-1|case-|vib-0_रह+या_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-1|case-|vib-0_सक+ता_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-1|case-|vib-|tam-gA|voicetype-active
VM	v	gen-m|num-pl|pers-1|case-|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-1|case-|vib-|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-1|case-|vib-|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-1|case-|vib-|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-1|case-|vib-गा|tam-gA|voicetype-active
VM	v	gen-m|num-pl|pers-1|case-|vib-ता_रह+गा|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-1|case-|vib-ता_है|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-1|case-|vib-ना_हो+गा|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-1|case-|vib-या_हो+या_था|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-1|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-2h|case-|vib-|tam-gA|voicetype-active
VM	v	gen-m|num-pl|pers-2h|case-|vib-गा|tam-gA|voicetype-active
VM	v	gen-m|num-pl|pers-3h|case-|vib-|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3h|case-|vib-या_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-o|vib-0_जा+या१|tam-|voicetype-
VM	v	gen-m|num-pl|pers-3|case-o|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-o|vib-|tam-|voicetype-
VM	v	gen-m|num-pl|pers-3|case-o|vib-|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-o|vib-ना|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-o|vib-०|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_उठ+ता_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_उठ+या_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_गुजर+ता_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_चुक+या_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_जा+ता_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_जा+या1_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_जा+या1_है|tam-|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-0_जा+या_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_जा+या_है|tam-|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-0_जा+या१_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_जा+या१_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_जा+या१|tam-|voicetype-
VM	v	gen-m|num-pl|pers-3|case-|vib-0_दे+ता_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_दे+या_जा+एं|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_दे+या_जा+गा|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_दे+या_जा+गा|tam-|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-0_दे+या_जा+ता_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_दे+या_जा+या1_है|tam-|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-0_दे+या_जा+या१_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_दे+या_जा+या१_है|tam-|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-0_दे+या_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_पड+या_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_पा+ता_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_पा_रह+या_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_बैठ+ता_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_रह+या_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_रह+या_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_रहा+या_हैं+है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_ले+ता_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_ले+या_जा+गा|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_ले+या_जा+या१_है|tam-|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-0_ले+या_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-0_सक+ता_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-|tam-WA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-|tam-eM|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-|tam-gA|voicetype-
VM	v	gen-m|num-pl|pers-3|case-|vib-|tam-gA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-|tam-wA|voicetype-
VM	v	gen-m|num-pl|pers-3|case-|vib-|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-|tam-wA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-|tam-yA1|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-3|case-|vib-|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-|tam-|voicetype-
VM	v	gen-m|num-pl|pers-3|case-|vib-|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-|tam-|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-एं|tam-eM|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-गा|tam-gA|voicetype-
VM	v	gen-m|num-pl|pers-3|case-|vib-गा|tam-gA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ता_आ+या_है|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ता_चल+या_जा+या१|tam-wA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-ता_जा_रह+या_है|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ता_था|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ता_रह+एं|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ता_रह+गा|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ता_रह+ता_है|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ता_रह+या_है|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ता_रह+या|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ता_है|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ता_हो|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ता|tam-wA|voicetype-
VM	v	gen-m|num-pl|pers-3|case-|vib-ता|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-था|tam-WA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ना_जा_रह+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ना_पड_सक+ता_है|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ना_पड़+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ना_रह+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ना_लग+ता_है|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ना_लग+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ना_लग+या|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ना_वाला_है|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ना_है|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-ना_हो+गा|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_आ+एं|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+एं|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+एं|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+गा|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+गा|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+ता_रह+या_है|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+ता_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+ता_है|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+ना_था|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+ना_लग+या_है|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+ना_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+या1_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+या1_है|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+या_चुक+या_है|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+या१_था|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+या१_था|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+या१_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+या१_है|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+या१|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा+या१|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा_चुक+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा_चुक+या_है|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा_रह+या_है+या|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा_रह+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा_रह+या_है|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा_रह+या_हो|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा_सक+ता_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_जा_सक+ता_है|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_था|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_दे+ता_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_दे+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_दे_रह+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_पड_रह+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_पड़+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_रख+गा|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_रख+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_रह+एं|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_रह+गा|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_रह+ता_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_रह+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_सक+ता_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_है+हैं|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_है|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या_हो+गा|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_हो+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या_हो+या_है|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-3|case-|vib-या|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-3|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-3|case-|vib-या१_है|tam-yA1|voicetype-active
VM	v	gen-m|num-pl|pers-|case-o|vib-|tam-nA|voicetype-
VM	v	gen-m|num-pl|pers-|case-o|vib-|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-|case-o|vib-ना_वाला_का|tam-nA|voicetype-
VM	v	gen-m|num-pl|pers-|case-o|vib-या|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-0_चुक+या_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_चुका+या_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_जा+ता_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_जा+या1_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_जा+या_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_जा+या१_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_दे+ता_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_दे+या_जा+या१|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_दे+या_जा+या१|tam-|voicetype-passive
VM	v	gen-m|num-pl|pers-|case-|vib-0_दे+या_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_पा+या_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_पा_रह+या_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_रख+या_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_रह+या_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_रह+या_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_ले+या_जा+या१_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_ले+या_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_सक+ता_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_सक+ता_है|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-0_सक+या_था|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-WA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-eM|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-eM|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-gA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-nA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-wA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-wA|voicetype-passive
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-yA1|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-yA1|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-|tam-|voicetype-passive
VM	v	gen-m|num-pl|pers-|case-|vib-एं|tam-eM|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-एं|tam-eM|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-गा_था|tam-gA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-गा|tam-gA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-ता_चल+या_जा+या१|tam-wA|voicetype-passive
VM	v	gen-m|num-pl|pers-|case-|vib-ता_था_जैसे|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-ता_था|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-ता_रह+या|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-ता_है|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-ता_हो+या|tam-wA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-ता_हो|tam-wA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-ता|tam-wA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-ता|tam-wA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-था|tam-WA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-ना_के_लिए|tam-nA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-ना_के_ले+या|tam-nA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-ना_था|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-ना_पड+या|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-ना_पा+ता|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-ना_पड़+या|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-ना_में|tam-nA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-ना_लग+या_था|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-ना_लग+या|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-ना_वाला_था|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-ना_हो+गा|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-ना|tam-nA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या_कर+ता_था|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या_जा+एं|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-या_जा+एं|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या_जा+ना_का|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-या_जा+ना_के_बावजूद|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-या_जा+ना_के_लिए|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-या_जा+ना_वाला_था|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या_जा+या|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-या_जा+या१_था|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या_जा+या१_था|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-|case-|vib-या_जा_रह+या_था|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या_जा_रह+या_था|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-|case-|vib-या_था|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या_था|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-|case-|vib-या_रख+ना_के_लिए|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-या_रह+ना_के_कारण|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-या_रह+या|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या_है|tam-yA|voicetype-passive
VM	v	gen-m|num-pl|pers-|case-|vib-या_हो+एं|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या_हो+ता|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या_हो+या_था|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या_हो+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या_हो+या|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-या_हो+या|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या_हो|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या|tam-yA|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या१_था|tam-yA1|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या१_हो+या_था|tam-yA1|voicetype-active
VM	v	gen-m|num-pl|pers-|case-|vib-या१|tam-yA1|voicetype-
VM	v	gen-m|num-pl|pers-|case-|vib-या१|tam-yA1|voicetype-active
VM	v	gen-m|num-sg|pers-1|case-|vib-0_चुक+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-1|case-|vib-0_रह+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-1|case-|vib-0_सक+ता_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-1|case-|vib-|tam-gA|voicetype-active
VM	v	gen-m|num-sg|pers-1|case-|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-1|case-|vib-|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-1|case-|vib-|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-1|case-|vib-|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-1|case-|vib-गा|tam-gA|voicetype-active
VM	v	gen-m|num-sg|pers-1|case-|vib-ता_है|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-1|case-|vib-ता_हो+है|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-1|case-|vib-ना_जा_रह+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-1|case-|vib-या_रहू+गा|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-1|case-|vib-या_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-2h|case-|vib-0_रह+ए_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-2h|case-|vib-0_सक+ता_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-2h|case-|vib-|tam-eM|voicetype-active
VM	v	gen-m|num-sg|pers-2h|case-|vib-|tam-gA|voicetype-active
VM	v	gen-m|num-sg|pers-2h|case-|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-2h|case-|vib-|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-2h|case-|vib-|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-2h|case-|vib-एं|tam-eM|voicetype-active
VM	v	gen-m|num-sg|pers-2h|case-|vib-गा|tam-gA|voicetype-active
VM	v	gen-m|num-sg|pers-2h|case-|vib-ता_है|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-2h|case-|vib-ना_दे+एं|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-o|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-o|vib-ना_वाला_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-0_चुक+या_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-0_चुक+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-0_जा+ता_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-0_जा+या1_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-0_जा+या१_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-0_जा+या१_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-0_दे+ता_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-0_दे+ता_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-0_दे+या_जा+या१_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-0_पा+या_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-0_पड़+ता_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-0_रह+या_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-0_रह+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-0_सक+ता_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-0_सक+ता_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-|tam-WA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-|tam-gA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-|tam-gA|voicetype-passive
VM	v	gen-m|num-sg|pers-3h|case-|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-3h|case-|vib-|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-|tam-yA1|voicetype-
VM	v	gen-m|num-sg|pers-3h|case-|vib-|tam-yA1|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3h|case-|vib-|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3h|case-|vib-|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-गा|tam-gA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-गा|tam-gA|voicetype-passive
VM	v	gen-m|num-sg|pers-3h|case-|vib-ता_था|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-ता_बन+या|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-ता_रह+गा|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-ता_रह+या_है|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-ता_रह+या|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-ता_है|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-ता_हो+एं|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-3h|case-|vib-ता_हो+या|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-3h|case-|vib-ता|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-3h|case-|vib-ता|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-था|tam-WA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-ना_जा+या१_हो+या_था|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-ना_जा_रह+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-ना_वाला_था|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-ना_वाला_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-ना_हो+गा|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_आ+या|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_कर+ता_था|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_जा+एं|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_जा+एं|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_जा+गा|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_जा+ता_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_जा+या१_था|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_जा+या१_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_जा+या१_है|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_जा+या१|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_जा+या१|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_था|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_बैठ+या|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_रख+गा|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_रह+एं|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_रह+गा|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_रह+या_था|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_रह+या|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_सक+ता_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_हो+या_था|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_हो+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या_हो+या|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3h|case-|vib-या|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3h|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या१_था|tam-yA1|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या१_है|tam-yA1|voicetype-active
VM	v	gen-m|num-sg|pers-3h|case-|vib-या१|tam-yA1|voicetype-
VM	v	gen-m|num-sg|pers-3h|case-|vib-या१|tam-yA1|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-d|vib-|tam-nA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-d|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-d|vib-|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-d|vib-ना_पड_रह+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-d|vib-ना|tam-nA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-d|vib-या_हो+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-o|vib-0_सक+ता_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-o|vib-|tam-nA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-o|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-o|vib-|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-o|vib-|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-o|vib-ना_के_साथ_साथ|tam-nA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-o|vib-ना_जा_रह+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-o|vib-ना_वाला_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-o|vib-या_जा+ना_से_पहले|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-0_आ+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_गिरा+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_चुक+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_चुक+या_है|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_चुक+या_हो+गा|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_जा+ता_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_जा+ना_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_जा+या1_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_जा+या_जा+गा|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_जा+या_जा+या१|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_जा+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_जा+या_है|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_जा+या_हो+गा|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_जा+या१_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_जा+या१_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_जा+या१_है|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_जा+या१_हो+गा|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_जा+या१|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_जा_रह+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दिखा+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दिया_जा+या१_है|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दे+ता_है|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दे+या_जा+एं|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दे+या_जा+गा|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दे+या_जा+गा|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दे+या_जा+ता_है|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दे+या_जा+या1_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दे+या_जा+या1_है|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दे+या_जा+या१_था|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दे+या_जा+या१_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दे+या_जा+या१_है|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दे+या_जा+या१|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दे+या_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दे+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दे+या_है|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_दे+या१_जा+या१_है|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_निकाल+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_पड_रह+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_पा+ता_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_पा+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_पा_रह+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_पड़+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_रख+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_रह+गा|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_रह+या_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_रह+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_ले+ता_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_ले+या_जा+एं|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_ले+या_जा+एं|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_ले+या_जा+गा|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_ले+या_जा+गा|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_ले+या_जा+ता_है|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_ले+या_जा+या१_था|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_ले+या_जा+या१_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_ले+या_जा+या१_है|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_ले+या_जा+या१|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_ले+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_सक+ता_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_सक+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_सक+या_है|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-0_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_हो+या_है|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-0_हो+या_है|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-WA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-eM|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-gA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-gA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-gA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-kara|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-kara|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-nA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-nA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-wA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-yA1|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-yA1|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-yA1|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-एं|tam-eM|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-कर|tam-kara|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-कर|tam-kara|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-गा|tam-gA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-गा|tam-gA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-गा|tam-gA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-ता_आ+या_है|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ता_जा+ता_है|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ता_जा_रह+या_है|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ता_जा_रह+या_है|tam-wA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-ता_रह+एं|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ता_रह+गा|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ता_रह+या_है|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ता_रह+या|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ता_है|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ता_है|tam-wA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-ता_हो+या|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-ता|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-ता|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-था|tam-WA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_जा+ता_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_जा_रह+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_दे+या_जा+गा|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_दे+या_जा+गा|tam-nA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_पड+गा|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_पड+ता_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_पड+या_था|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_पड+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_पड+या|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_पड_रह+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_पड़+गा|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_पड़_रह+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_पा+एं|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_पड़+एं|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_पड़+गा|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_पड़+ता_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_पड़+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_पड़_रह+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_पड़_सक+ता_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_रह+गा|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_रह+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_लग+या_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_लग+या|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_वाला_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_हो+गा|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना_हो+ता_है|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-ना|tam-nA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-ना|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_कर+गा|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_के_बाद|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+एं|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+एं|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+गा|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+गा|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ता_रह+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ता_रह+या_है|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ता_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ता_है|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ना_के_कारण|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ना_के_चलते|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ना_के_दौरान|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ना_के_पीछे|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ना_के_बाद_से|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ना_के_बाद|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ना_के_बारे_में|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ना_के_बावजूद|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ना_के_मद्देनजर|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ना_के_समय|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ना_लग+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ना_लगा+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ना_से_पहले|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ना_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+ना_है|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+या1_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+या1_है|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+या_है|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+या|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+या१_था|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+या१_था|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+या१_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+या१_है|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+या१|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+या१|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा+या१|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा_चुक+या_है|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा_चुका_है|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा_रह+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा_रह+या_है|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा_सक+ता_था|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा_सक+ता_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा_सक+ता_है|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा_सक+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जा_सक+या_है|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_जान+ना_के_बाद|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_था|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_था|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_दे+ना_लग+या_है|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_दे+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_दे+या|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_दे_रह+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_पर|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_बैठ+या|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_रख+या_जा+एं|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_रख+या_जा+गा|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_रह+एं|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_रह+गा|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_रह+ता_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_रह+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_ले+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_सक+ता_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_है|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या_हो+गा|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_हो+ता_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_हो+या_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_हो+या_हो+गा|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या_हो+या|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या_हो_सक+ता_है|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या१_है|tam-yA1|voicetype-active
VM	v	gen-m|num-sg|pers-3|case-|vib-या१_है|tam-yA1|voicetype-passive
VM	v	gen-m|num-sg|pers-3|case-|vib-या१|tam-yA1|voicetype-
VM	v	gen-m|num-sg|pers-3|case-|vib-या१|tam-yA1|voicetype-active
VM	v	gen-m|num-sg|pers-|case-d|vib-0_दे+या|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-d|vib-|tam-nA|voicetype-
VM	v	gen-m|num-sg|pers-|case-d|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-d|vib-|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-d|vib-ना|tam-nA|voicetype-
VM	v	gen-m|num-sg|pers-|case-d|vib-ना|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-o|vib-|tam-nA|voicetype-
VM	v	gen-m|num-sg|pers-|case-o|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-o|vib-|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-|case-o|vib-ता_वक्त|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-|case-o|vib-ना_पड+या_था|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-o|vib-ना_वाला_का|tam-nA|voicetype-
VM	v	gen-m|num-sg|pers-|case-o|vib-ना|tam-nA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-0_गिरा+या_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_चुक+या_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_चुक+या_हो+ता|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_जा+ना_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_जा+या1_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_जा+या_जा+या१_था|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-0_जा+या_जा+या१|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-0_जा+या_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_जा+या_था|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-0_जा+या१_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_जा+या१_था|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-0_डाल+या_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_दे+या_जा+एं|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_दे+या_जा+ता_था|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-0_दे+या_जा+ता|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-0_दे+या_जा+या१_था|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-0_दे+या_जा+या१|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_दे+या_जा+या१|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-0_दे+या_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_दे+या_हो+ता|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_निकाल+या_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_पा+ता_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_रख+या_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_रह+या_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_रह+या_हो+ता|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_ले+ना_का|tam-|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-0_ले+या_जा+एं|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-0_ले+या_जा+या|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_ले+या_जा+या१_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_ले+या_जा+या१|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_ले+या_जा+या१|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-0_ले+या_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_ले+या_हो+ता|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-0_सक+ता_था|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-WA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-WA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-eM|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-eM|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-eM|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-nA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-nA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-wA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-yA1|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-yA1|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-|tam-|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-एं|tam-eM|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-एं|tam-eM|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-एं|tam-eM|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-ता_था|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ता_था|tam-wA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-ता_बच+या|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ता_रह+एं|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ता_रह+या|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ता_वक्त|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-ता_समय|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-ता_हो+एं|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-ता_हो+या|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-ता_हो+या|tam-wA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-ता_हो|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-ता|tam-wA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-ता|tam-wA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-था|tam-WA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-था|tam-WA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ना_था|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ना_दे+या_जा+या१|tam-nA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-ना_पड+एं|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ना_पड+ता|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ना_पड+या_था|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ना_पड+या|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ना_पड+या|tam-nA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-ना_पड़+ता_था|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ना_पड़+एं|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ना_पड़+ता|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ना_पड़+या_था|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ना_पड़+या|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ना_पड़_रह+या_था|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ना_लग+या|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ना_वाला_था|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ना_हो+गा|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-ना|tam-nA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-ना|tam-nA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_कर+ता_था|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_का|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या_के_लिए|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+एं|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+एं|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+ता_था|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+ता_रह+या|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+ता|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+ना_के_कारण|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+ना_के_बाद_से|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+ना_के_बारे_में|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+ना_के_बावजूद|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+ना_के_लिए|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+ना_के_संबंध_में|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+ना_कें_बारे_में|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+ना_चाहिए|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+ना_था|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+ना_पर|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+ना|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+या_था|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+या|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+या|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+या१_था|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+या१_था|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+या१_हो+ता|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा_रह+या_था|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा_रह+या_था|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा_सक+ता_था|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-या_जा_सक+या_था|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-या_था|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_दे+या_जा+एं|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_दे+या_जा+या१|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-या_दे+या|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_पर|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या_पा+या|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_रख+ना_के_लिए|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या_रख+या_था|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_रख+या|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_रह+ता|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_रह+ना_के_लिए|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या_रह+या|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_ले+या|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_सक+ता|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-या_हो+ता|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_हो+या_था|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या_हो+या|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या|tam-yA|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या|tam-yA|voicetype-passive
VM	v	gen-m|num-sg|pers-|case-|vib-या१_तक|tam-yA1|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या१_था|tam-yA1|voicetype-active
VM	v	gen-m|num-sg|pers-|case-|vib-या१|tam-yA1|voicetype-
VM	v	gen-m|num-sg|pers-|case-|vib-या१|tam-yA1|voicetype-active
VM	v	gen-m|num-|pers-3|case-|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-|pers-3|case-|vib-ना_चाह+एं|tam-nA|voicetype-active
VM	v	gen-m|num-|pers-|case-d|vib-0_पा+ना_के_कारण|tam-|voicetype-
VM	v	gen-m|num-|pers-|case-d|vib-|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-d|vib-|tam-|voicetype-
VM	v	gen-m|num-|pers-|case-d|vib-ना|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-|pers-|case-o|vib-ना_का_कारण|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_के_एवज_में|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_के_कारण|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_के_तौर_पर|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_के_नाते|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_के_बाद_से|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_के_संबंध_में|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_के_समय|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_के_समान|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_को|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_दे+ना_चाहिए|tam-nA|voicetype-active
VM	v	gen-m|num-|pers-|case-o|vib-ना_वाला_को|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_वाला_द्वारा|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_वाला_ने|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_वाला_पर|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_वाला_में|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_वाला_समय_में|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_वाला_से|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-o|vib-ना_से_पहले_तक|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-0_चुक+या_हो|tam-|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-0_जा+ना_के_कारण|tam-|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-0_जा+ना_के_बाद_से|tam-|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-0_जा+ना_चाहिए|tam-|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-0_जा+या१_हो|tam-|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-0_दे+ना_चाहिए|tam-|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-0_दे+या_जा+ना_चाहिए|tam-|voicetype-passive
VM	v	gen-m|num-|pers-|case-|vib-0_दे+या_जान+ना_के_कारण|tam-|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-0_पा+ना_के_कारण|tam-|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-0_रह+या_हो|tam-|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-|tam-nA|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-|tam-nA|voicetype-passive
VM	v	gen-m|num-|pers-|case-|vib-|tam-wA|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-|tam-wA|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-|tam-yA|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-|tam-yA|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-m|num-|pers-|case-|vib-|tam-|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-|tam-|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-|tam-|voicetype-passive
VM	v	gen-m|num-|pers-|case-|vib-ता_बन+ना|tam-wA|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-ता_हो|tam-wA|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-ना_के_कारण|tam-nA|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-ना_चाह|tam-nA|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-ना_चाहिए|tam-nA|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-ना_दे+ना_चाहिए|tam-nA|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-ना_दे+या_जा+ना_चाहिए|tam-nA|voicetype-passive
VM	v	gen-m|num-|pers-|case-|vib-ना_हो|tam-nA|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-या_कर|tam-yA|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-या_जा+एं|tam-yA|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-या_जा+ना_चाहिए|tam-yA|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-या_जा+ना_चाहिए|tam-yA|voicetype-passive
VM	v	gen-m|num-|pers-|case-|vib-या_जा+ना|tam-yA|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-या_जा+या१_हो|tam-yA|voicetype-passive
VM	v	gen-m|num-|pers-|case-|vib-या_जान+ना|tam-yA|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-या_जान+या_चाहिए|tam-yA|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-या_रख+ना|tam-yA|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-या_रह+ना_चाहिए|tam-yA|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-या_रह+ना|tam-yA|voicetype-
VM	v	gen-m|num-|pers-|case-|vib-या_हो+ना_चाहिए|tam-yA|voicetype-passive
VM	v	gen-m|num-|pers-|case-|vib-या_हो|tam-yA|voicetype-active
VM	v	gen-m|num-|pers-|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-1|case-|vib-0_दे+एं|tam-|voicetype-active
VM	v	gen-|num-pl|pers-1|case-|vib-0_दे+गा|tam-|voicetype-active
VM	v	gen-|num-pl|pers-1|case-|vib-0_दे|tam-|voicetype-active
VM	v	gen-|num-pl|pers-1|case-|vib-0_रह+या_है|tam-|voicetype-active
VM	v	gen-|num-pl|pers-1|case-|vib-0_ले+गा|tam-|voicetype-active
VM	v	gen-|num-pl|pers-1|case-|vib-0_सक+एं|tam-|voicetype-active
VM	v	gen-|num-pl|pers-1|case-|vib-0_सक+गा|tam-|voicetype-active
VM	v	gen-|num-pl|pers-1|case-|vib-|tam-eM|voicetype-active
VM	v	gen-|num-pl|pers-1|case-|vib-|tam-gA|voicetype-active
VM	v	gen-|num-pl|pers-1|case-|vib-|tam-hE|voicetype-active
VM	v	gen-|num-pl|pers-1|case-|vib-|tam-|voicetype-active
VM	v	gen-|num-pl|pers-1|case-|vib-एं|tam-eM|voicetype-active
VM	v	gen-|num-pl|pers-1|case-|vib-गा|tam-gA|voicetype-active
VM	v	gen-|num-pl|pers-1|case-|vib-है|tam-hE|voicetype-active
VM	v	gen-|num-pl|pers-2|case-|vib-|tam-ao|voicetype-active
VM	v	gen-|num-pl|pers-2|case-|vib-|tam-wA|voicetype-active
VM	v	gen-|num-pl|pers-2|case-|vib-ओ|tam-ao|voicetype-active
VM	v	gen-|num-pl|pers-2|case-|vib-ता_रह_जा+गा|tam-wA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-o|vib-|tam-nA|voicetype-
VM	v	gen-|num-pl|pers-3|case-o|vib-ना_वाला|tam-nA|voicetype-
VM	v	gen-|num-pl|pers-3|case-|vib-0_आ+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_चुक+एं_है|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_चुक+एं|tam-|voicetype-
VM	v	gen-|num-pl|pers-3|case-|vib-0_चुक+या|tam-|voicetype-
VM	v	gen-|num-pl|pers-3|case-|vib-0_जा+एं|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_जा+गा|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_जा+या१|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_डाल+गा|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_दे+एं|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_दे+गा|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_निकल+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_पड+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_पा+गा|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_बैठ+गा|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_रह+एं|tam-|voicetype-
VM	v	gen-|num-pl|pers-3|case-|vib-0_रह+या_है|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_रह+या|tam-|voicetype-
VM	v	gen-|num-pl|pers-3|case-|vib-0_ले+एं|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_ले+गा|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_सक+एं|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_सक+गा|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-0_सक+ता|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-|tam-eM|voicetype-
VM	v	gen-|num-pl|pers-3|case-|vib-|tam-eM|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-|tam-eM|voicetype-passive
VM	v	gen-|num-pl|pers-3|case-|vib-|tam-hE|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-|tam-nA|voicetype-
VM	v	gen-|num-pl|pers-3|case-|vib-|tam-nA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-|tam-wA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-3|case-|vib-|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-|num-pl|pers-3|case-|vib-|tam-|voicetype-
VM	v	gen-|num-pl|pers-3|case-|vib-|tam-|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-एं_जा_रह+एं_है|tam-eM|voicetype-passive
VM	v	gen-|num-pl|pers-3|case-|vib-एं|tam-eM|voicetype-
VM	v	gen-|num-pl|pers-3|case-|vib-एं|tam-eM|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-ता_जा_रह+या_है|tam-wA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-ना_जा+ना_वाला|tam-nA|voicetype-
VM	v	gen-|num-pl|pers-3|case-|vib-ना_दे+एं|tam-nA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-ना_दे+गा|tam-nA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-ना_लग+एं|tam-nA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-ना_लग+या|tam-nA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-या_जा+गा|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-या_जा+ना_का|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-3|case-|vib-या_जा+ना_वाला|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-3|case-|vib-या_जा+ना_है|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-या_जा+या१|tam-yA|voicetype-passive
VM	v	gen-|num-pl|pers-3|case-|vib-या_जा_रह+या_है|tam-yA|voicetype-passive
VM	v	gen-|num-pl|pers-3|case-|vib-या_जा_सक+एं|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-या_जा_सक+गा|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-या_जा_सक+गा|tam-yA|voicetype-passive
VM	v	gen-|num-pl|pers-3|case-|vib-या_जा_सक+या|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-या_था|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-या_रह+गा|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-या_रह+या_है|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-या_है|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-या_हो+गा|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-या_हो+या_है|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-या|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-3|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-3|case-|vib-है|tam-hE|voicetype-active
VM	v	gen-|num-pl|pers-|case-d|vib-|tam-nA|voicetype-
VM	v	gen-|num-pl|pers-|case-d|vib-ना|tam-nA|voicetype-
VM	v	gen-|num-pl|pers-|case-o|vib-|tam-nA|voicetype-
VM	v	gen-|num-pl|pers-|case-o|vib-|tam-nA|voicetype-active
VM	v	gen-|num-pl|pers-|case-o|vib-|tam-ne|voicetype-
VM	v	gen-|num-pl|pers-|case-o|vib-ना_का|tam-nA|voicetype-
VM	v	gen-|num-pl|pers-|case-o|vib-ना_के|tam-nA|voicetype-
VM	v	gen-|num-pl|pers-|case-o|vib-ना_चाहिए_था|tam-nA|voicetype-active
VM	v	gen-|num-pl|pers-|case-o|vib-ना_जैसा|tam-nA|voicetype-
VM	v	gen-|num-pl|pers-|case-o|vib-ना_दे+ना_वाला|tam-nA|voicetype-
VM	v	gen-|num-pl|pers-|case-o|vib-ना_वाला|tam-nA|voicetype-
VM	v	gen-|num-pl|pers-|case-o|vib-ना_वाली|tam-nA|voicetype-
VM	v	gen-|num-pl|pers-|case-o|vib-ने_का|tam-ne|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-0_आ+या|tam-|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-0_आ+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_उठ+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_चुक+या_है|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_चुक+या|tam-|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-0_जा+ना_का|tam-|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-0_जा+ना_पड+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_जा+या|tam-|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-0_जा+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_जा+या|tam-|voicetype-passive
VM	v	gen-|num-pl|pers-|case-|vib-0_जा+या१|tam-|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-0_जा+या१|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_जा+या१|tam-|voicetype-passive
VM	v	gen-|num-pl|pers-|case-|vib-0_डाल+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_दे+एं|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_दे+गा|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_दे+या_जा+ना_का|tam-|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-0_दे+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_पड+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_पड़+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_पहुंच+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_पा+ता|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_पा+ना_वाला|tam-|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-0_पा+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_पड़+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_रह+या_था|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_रह+या|tam-|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-0_रह+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_ले+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_ले_जा+या१|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_सक+गा|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_सक+ता|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_सक+या|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-0_हो_जा+या१|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-|tam-WA|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-|tam-eM|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-|tam-hE|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-|tam-kara|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-|tam-kara|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-|tam-nA|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-|tam-nA|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-|tam-wA|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-|num-pl|pers-|case-|vib-|tam-|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-|tam-|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-|tam-|voicetype-passive
VM	v	gen-|num-pl|pers-|case-|vib-एं|tam-eM|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-कर_आ+या|tam-kara|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-कर_जा+या१|tam-kara|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-ता_रह_जा+या१|tam-wA|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-था|tam-WA|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-ना_लग+या_था|tam-nA|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-ना_लग+या|tam-nA|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-या_जा+ना_का|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-या_जा+ना_चाहिए_था|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-या_जा+ना_तक|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-या_जा+ना_पर|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-या_जा+ना_वाला|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-या_जा+ना_वाली|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-या_जा+ना_से|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-passive
VM	v	gen-|num-pl|pers-|case-|vib-या_जा_रह+या|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-या_जा_रह+या|tam-yA|voicetype-passive
VM	v	gen-|num-pl|pers-|case-|vib-या_जा_सक+ता|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-या_जा_सक+ता|tam-yA|voicetype-passive
VM	v	gen-|num-pl|pers-|case-|vib-या_जान+ना_वाला|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-या_था|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-या_दे+या|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-या_रह+या|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-या_समा_रह+या|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-या_हो+या_था|tam-yA|voicetype-active
VM	v	gen-|num-pl|pers-|case-|vib-या_हो+या|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-या|tam-yA|voicetype-
VM	v	gen-|num-pl|pers-|case-|vib-है|tam-hE|voicetype-active
VM	v	gen-|num-sg|pers-1h|case-|vib-|tam-hE|voicetype-active
VM	v	gen-|num-sg|pers-1h|case-|vib-है|tam-hE|voicetype-active
VM	v	gen-|num-sg|pers-1|case-|vib-0_दे+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-1|case-|vib-0_सक+ऊँ|tam-|voicetype-active
VM	v	gen-|num-sg|pers-1|case-|vib-0_सक+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-1|case-|vib-|tam-hE|voicetype-active
VM	v	gen-|num-sg|pers-1|case-|vib-|tam-|voicetype-active
VM	v	gen-|num-sg|pers-1|case-|vib-है|tam-hE|voicetype-active
VM	v	gen-|num-sg|pers-2h|case-|vib-0_जा+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-2h|case-|vib-0_जा+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-2h|case-|vib-0_दे+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-2h|case-|vib-0_ले+ए|tam-|voicetype-active
VM	v	gen-|num-sg|pers-2h|case-|vib-0_ले+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-2h|case-|vib-0_सक+ता|tam-|voicetype-active
VM	v	gen-|num-sg|pers-2h|case-|vib-|tam-eM|voicetype-active
VM	v	gen-|num-sg|pers-2h|case-|vib-|tam-hE|voicetype-active
VM	v	gen-|num-sg|pers-2h|case-|vib-|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-2h|case-|vib-|tam-|voicetype-active
VM	v	gen-|num-sg|pers-2h|case-|vib-एं|tam-eM|voicetype-active
VM	v	gen-|num-sg|pers-2h|case-|vib-ना_चाह+एं|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-2h|case-|vib-ना_चाह+गा|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-2h|case-|vib-है|tam-hE|voicetype-active
VM	v	gen-|num-sg|pers-2|case-|vib-|tam-ao|voicetype-active
VM	v	gen-|num-sg|pers-2|case-|vib-|tam-eM|voicetype-active
VM	v	gen-|num-sg|pers-2|case-|vib-|tam-hE|voicetype-active
VM	v	gen-|num-sg|pers-2|case-|vib-एं|tam-eM|voicetype-active
VM	v	gen-|num-sg|pers-2|case-|vib-ओ|tam-ao|voicetype-active
VM	v	gen-|num-sg|pers-2|case-|vib-है|tam-hE|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-o|vib-0_आ+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-o|vib-|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3h|case-o|vib-|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-o|vib-ना_का|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3h|case-o|vib-ना_वाला|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3h|case-|vib-0_आ+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_चुक+एं_है|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_चुक+एं|tam-|voicetype-
VM	v	gen-|num-sg|pers-3h|case-|vib-0_चुक+या_है|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_चुक+या|tam-|voicetype-
VM	v	gen-|num-sg|pers-3h|case-|vib-0_चुक+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_जा+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_जा+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_जा+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_जा+या१|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_जा_रह+या|tam-|voicetype-
VM	v	gen-|num-sg|pers-3h|case-|vib-0_दे+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_दे+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_पहुंचे+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_पा+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_पा+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_पड़+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_बैठ+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_रह+एं_था|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_रह+एं|tam-|voicetype-
VM	v	gen-|num-sg|pers-3h|case-|vib-0_रह+या_है|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_रह+या|tam-|voicetype-
VM	v	gen-|num-sg|pers-3h|case-|vib-0_रह+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_ले+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_ले+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_सक+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_सक+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_सक+ता|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-0_सक+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-|tam-eM|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-|tam-hE|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-|tam-kara|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3h|case-|vib-|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3h|case-|vib-|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-|tam-|voicetype-
VM	v	gen-|num-sg|pers-3h|case-|vib-|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-एं|tam-eM|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-कर_रो+या|tam-kara|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-ना_जा+या१|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3h|case-|vib-ना_दे+गा|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-ना_लग+या|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-या_जा+ना_वाला|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3h|case-|vib-या_दे+या|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-या_रह+या|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3h|case-|vib-या_है|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-या|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3h|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3h|case-|vib-है|tam-hE|voicetype-active
VM	v	gen-|num-sg|pers-3|case-d|vib-|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-d|vib-ना_है|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-d|vib-ना_हो+गा|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-o|vib-0_के_बाद|tam-|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-o|vib-|tam-ne|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-|tam-|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-ना_का_बाद|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-ना_का|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-ना_के_करीब|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-ना_के_दौरान|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-ना_के_निकट|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-ना_के_पहले|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-ना_के_पीछे|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-ना_के_बाद|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-ना_के_बीच|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-ना_के_साथ|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-ना_वाला+या|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-ना_वाला|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-ना_से_पहले|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-ना_से_पूर्व|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-ना_सै|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-o|vib-ने_के_बाद|tam-ne|voicetype-
VM	v	gen-|num-sg|pers-3|case-o|vib-या_जा+ना_के_बाद|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-0_आ+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_उठा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_कर|tam-|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-0_के_बाद|tam-|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-0_चुक+या_है|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_चुक+या|tam-|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-0_चुका_है|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_जा+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_जा+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_जा+गा|tam-|voicetype-passive
VM	v	gen-|num-sg|pers-3|case-|vib-0_जा+ता|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_जा+ना_के_बाद|tam-|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-0_जा+या१|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_जा+या१|tam-|voicetype-passive
VM	v	gen-|num-sg|pers-3|case-|vib-0_जा_सक+एं|tam-|voicetype-passive
VM	v	gen-|num-sg|pers-3|case-|vib-0_जा_सक+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_डाल+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_दिया+या|tam-|voicetype-passive
VM	v	gen-|num-sg|pers-3|case-|vib-0_दिया|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_दे+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_दे+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_दे+ना_के_बाद|tam-|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-0_दे+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_दे|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_पहुंच+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_पा+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_पा+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_पा+ना_के_बाद|tam-|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-0_पा+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_पाऊंगा+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_रह+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_रह+या|tam-|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-0_रह+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_ले+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_ले+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_ले+या_जा+ना_के_बाद|tam-|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-0_ले+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_सक+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_सक+गा|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_सक+ता|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_सक+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-0_है|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-|tam-ao|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-|tam-eM|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-|tam-eM|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-|tam-hE|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-|tam-hE|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-|tam-hE|voicetype-passive
VM	v	gen-|num-sg|pers-3|case-|vib-|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-|tam-wA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-|tam-wA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-|num-sg|pers-3|case-|vib-|tam-|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-|tam-|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-|tam-|voicetype-passive
VM	v	gen-|num-sg|pers-3|case-|vib-एं|tam-eM|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-एं|tam-eM|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-ओ|tam-ao|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-ता_है|tam-wA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-ता_हो+या|tam-wA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-ता|tam-wA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-ना_चाहिए_था|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-ना_दे+गा|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-ना_पा+एं|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-ना_लग+गा|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-ना_लग+या|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-ना_वाला|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-ना_है|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-ना_हो+गा|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-या_का|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा+ना_का|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा+ना_के_बाद|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा+ना_को|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा+ना_चाहिए_था|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा+ना_दे+ना_का|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा+ना_पर|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा+ना_लगा_है|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा+ना_वाला|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा+ना_से|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा+ना_है|tam-yA|voicetype-passive
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा+ने_का|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा+या१|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा_चुका_है|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा_चुका_है|tam-yA|voicetype-passive
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा_रह+या|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा_सक+एं|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा_सक+एं|tam-yA|voicetype-passive
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा_सक+गा|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा_सक+गा|tam-yA|voicetype-passive
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा_सक+ता|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-या_जा_सक+ता|tam-yA|voicetype-passive
VM	v	gen-|num-sg|pers-3|case-|vib-या_पड_जा+गा|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-या_रख+गा|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-या_रह_सक+एं|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-या_समा_रह+या|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-या_है|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-या|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-है|tam-hE|voicetype-
VM	v	gen-|num-sg|pers-3|case-|vib-है|tam-hE|voicetype-active
VM	v	gen-|num-sg|pers-3|case-|vib-है|tam-hE|voicetype-passive
VM	v	gen-|num-sg|pers-|case-d|vib-0_दे+ना_का|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-d|vib-|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-|case-d|vib-|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-d|vib-ना_पड+या|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-|case-d|vib-ना_लग_जा+गा|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-|case-o|vib-0_पा+ना_का|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-0_ले+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-o|vib-|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-|case-o|vib-|tam-ne|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-o|vib-ना_का|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-ना_के_जैसा|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-ना_के_बाद|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-ना_के_समय|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-ना_जैसा|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-ना_तक_का|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-ना_दे+ता|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-|case-o|vib-ना_दे+या|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-|case-o|vib-ना_रह+या|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-ना_वाला|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-ना_वाली|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-ने_का|tam-ne|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-या_जा+ना_का|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-या_जा+ना_तक|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-o|vib-या_जा+ना_से|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-0_आ+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_उठ+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_का|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-0_गिरा+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_चुक+या|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-0_जा+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_जा+ता|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_जा+ना_का|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-0_जा+ना_था|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_जा+या_जा_रह+या|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-0_जा+या|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-0_जा+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_जा+या|tam-|voicetype-passive
VM	v	gen-|num-sg|pers-|case-|vib-0_जा+या१|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_जा+या१|tam-|voicetype-passive
VM	v	gen-|num-sg|pers-|case-|vib-0_जा_पा+या|tam-|voicetype-passive
VM	v	gen-|num-sg|pers-|case-|vib-0_जा_सक+ता|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_डाल+ना_का|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-0_डाल+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_था|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_दिया|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_दे+ता|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_दे+ना_का|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-0_दे+ना_पड़+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_दे+ना_वाला|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-0_दे+ना|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_दे+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_दे+या|tam-|voicetype-passive
VM	v	gen-|num-sg|pers-|case-|vib-0_धमक+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_निकाल+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_पड+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_पहुँच+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_पहुंच+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_पा+ता|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_पा+ना|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-0_पा+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_पड़+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_फेंक+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_बैठ+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_रह+या|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-0_रह+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_लिया+या_जा+ना_चाहिए_था|tam-|voicetype-passive
VM	v	gen-|num-sg|pers-|case-|vib-0_ले+ता|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_ले+ना_का|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-0_ले+या_जा+ना_का|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-0_ले+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_सक+एं|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_सक+ता|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_सक+ना_का|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-0_सक+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-0_हो+या|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-|tam-eM|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-|tam-kara|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-|tam-wA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-|num-sg|pers-|case-|vib-|tam-|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-|tam-|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-|tam-|voicetype-passive
VM	v	gen-|num-sg|pers-|case-|vib-एं|tam-eM|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-कर_जा_रह+या|tam-kara|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-कर_हो+या|tam-kara|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-ता_हो+एं|tam-wA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-ता_हो+या|tam-wA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-ता|tam-wA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-ना_का|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-ना_चाहिए_था|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-ना_जा+ना_वाला|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-ना_जा_रह+या|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-ना_जान+ना_वाला|tam-nA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-ना_दे+ता|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-ना_दे+या|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-ना_पड+या|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-ना_पड़+या|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-ना_लग+या|tam-nA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-या_आ_रह+या|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_जा+ना_का|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_जा+ना_को|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_जा+ना_चाहिए_था|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-या_जा+ना_चाहिए_था|tam-yA|voicetype-passive
VM	v	gen-|num-sg|pers-|case-|vib-या_जा+ना_तक|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_जा+ना_पर|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_जा+ना_में|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_जा+ना_वाला|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_जा+ना_से|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_जा_रह+या|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_जा_रह+या|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-या_जा_सक+एं|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-या_जा_सक+एं|tam-yA|voicetype-passive
VM	v	gen-|num-sg|pers-|case-|vib-या_जा_सक+ता|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-या_जा_सक+ता|tam-yA|voicetype-passive
VM	v	gen-|num-sg|pers-|case-|vib-या_जा_सक+या|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-या_जा_सक+या|tam-yA|voicetype-passive
VM	v	gen-|num-sg|pers-|case-|vib-या_जान+ना_का|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_जान+ना_वाला|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_था|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-या_दे+या|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-या_रख+ना_का|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_रख+ना_में|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_रख+ना|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_रख+या_जा+ना_का|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_रख+या|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-या_रह+ना_का|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_रह+या|tam-yA|voicetype-
VM	v	gen-|num-sg|pers-|case-|vib-या_रह_जा+या१|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-या_समा_रह+या|tam-yA|voicetype-active
VM	v	gen-|num-sg|pers-|case-|vib-या_हो+ना_का|tam-yA|voicetype-
VM	v	gen-|num-|pers-3h|case-|vib-|tam-yA|voicetype-active
VM	v	gen-|num-|pers-3h|case-|vib-या|tam-yA|voicetype-active
VM	v	gen-|num-|pers-3|case-|vib-|tam-hE|voicetype-active
VM	v	gen-|num-|pers-3|case-|vib-|tam-kara|voicetype-
VM	v	gen-|num-|pers-3|case-|vib-|tam-wA|voicetype-
VM	v	gen-|num-|pers-3|case-|vib-कर|tam-kara|voicetype-
VM	v	gen-|num-|pers-3|case-|vib-ता|tam-wA|voicetype-
VM	v	gen-|num-|pers-3|case-|vib-है|tam-hE|voicetype-active
VM	v	gen-|num-|pers-|case-d|vib-0_दे+ना|tam-|voicetype-
VM	v	gen-|num-|pers-|case-d|vib-0_पा+ना|tam-|voicetype-
VM	v	gen-|num-|pers-|case-d|vib-|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-d|vib-|tam-nA|voicetype-active
VM	v	gen-|num-|pers-|case-d|vib-|tam-|voicetype-
VM	v	gen-|num-|pers-|case-d|vib-ना|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-d|vib-ना|tam-nA|voicetype-active
VM	v	gen-|num-|pers-|case-o|vib-0_के_कारण|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-0_जा+ना_पर|tam-|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-0_में|tam-|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-|tam-nA|voicetype-active
VM	v	gen-|num-|pers-|case-o|vib-|tam-ne|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-|tam-wA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-|tam-yA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-|tam-|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ता_में|tam-wA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ता_वक्त|tam-wA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ता_समय|tam-wA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_का_बारे_में|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_का|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_अलावा|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_खिलाफ|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_चलते|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_तहत|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_नाते|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_बजाए|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_बजाय|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_बदले|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_बाबत|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_बारे_में|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_बावजूद|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_मद्देनजर|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_लिए+या|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_लिए|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_वास्ते|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के_सिवा|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_के|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_को|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_चाहिए|tam-nA|voicetype-active
VM	v	gen-|num-|pers-|case-o|vib-ना_तक_पर|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_तक|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_दे+ना_के_बारे_में|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_पर|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_बाद|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_में|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_लायक|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_वाला_के_खिलाफ|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_वाला_के_बारे_में|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_वाला_के_लिए|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_वाला|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_संबंधी|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_संबधी|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_समेत|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_सहित|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_से_लेकर|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_से|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना_हेतु|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ना|tam-nA|voicetype-active
VM	v	gen-|num-|pers-|case-o|vib-ने_के_लिए|tam-ne|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-ने_को|tam-ne|voicetype-
VM	v	gen-|num-|pers-|case-o|vib-या|tam-yA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_आना+ना|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_कर|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_जा+एं|tam-|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-0_जा+कर|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_जा+ना_के_लिए|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_जा+ना_के|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_जा+ना_को|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_जा+ना_चाहिए|tam-|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-0_जा+ना_पर|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_जा+ना_में|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_जा+ना_से|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_जा+ना|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_जान+ना_से|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_डाल+ना|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_दे+एं|tam-|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-0_दे+ना_के_बावजूद|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_दे+ना_से|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_दे+या_जा+ना_चाहिए|tam-|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-0_दे|tam-|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-0_पा+ना_में|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_पा+ना|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_फूंक+कर|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_रह+या|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_ले+एं|tam-|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-0_ले+ना_पर|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-0_ले|tam-|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-0_सक+एं|tam-|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-0_से|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-|tam-eM|voicetype-
VM	v	gen-|num-|pers-|case-|vib-|tam-eM|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-|tam-kara|voicetype-
VM	v	gen-|num-|pers-|case-|vib-|tam-kara|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-|tam-kara|voicetype-passive
VM	v	gen-|num-|pers-|case-|vib-|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-|tam-nA|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-|tam-wA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-|tam-yA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-|tam-yA|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-|tam-yA|voicetype-passive
VM	v	gen-|num-|pers-|case-|vib-|tam-|voicetype-
VM	v	gen-|num-|pers-|case-|vib-|tam-|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-एं|tam-eM|voicetype-
VM	v	gen-|num-|pers-|case-|vib-एं|tam-eM|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-कर|tam-kara|voicetype-
VM	v	gen-|num-|pers-|case-|vib-कर|tam-kara|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-कर|tam-kara|voicetype-passive
VM	v	gen-|num-|pers-|case-|vib-ता_वक्त|tam-wA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-ता_समय|tam-wA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-ता|tam-wA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-ना_के_बावजूद|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-ना_के_लिए|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-ना_चाहिए|tam-nA|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-ना_दे_कर|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-ना_से|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-ना|tam-nA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-ना|tam-nA|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-या_कर|tam-yA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-या_जा+ना_को|tam-yA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-या_जा+ना_चाहिए|tam-yA|voicetype-active
VM	v	gen-|num-|pers-|case-|vib-या_जा+ना_चाहिए|tam-yA|voicetype-passive
VM	v	gen-|num-|pers-|case-|vib-या_जा+ना_पर|tam-yA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-या_जा+ना_संबंधी|tam-yA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-या_जा+ना|tam-yA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-या_जा+या१|tam-yA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-या_रख+ना|tam-yA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-या|tam-yA|voicetype-
VM	v	gen-|num-|pers-|case-|vib-या|tam-yA|voicetype-active
VMC	v	gen-f|num-pl|pers-|case-|vib-या_हो+ता|tam-yA|voicetype-active
VMC	v	gen-f|num-sg|pers-3|case-|vib-0_रह+या_है|tam-|voicetype-active
VMC	v	gen-f|num-sg|pers-|case-|vib-ता|tam-wA|voicetype-
VMC	v	gen-m|num-pl|pers-|case-|vib-ता|tam-wA|voicetype-
VMC	v	gen-m|num-sg|pers-3h|case-|vib-0_सक+ता_है|tam-|voicetype-active
VMC	v	gen-m|num-sg|pers-|case-|vib-या|tam-yA|voicetype-
VMC	v	gen-m|num-|pers-|case-o|vib-ना_वाला_को|tam-nA|voicetype-
VMC	v	gen-|num-pl|pers-|case-o|vib-ना_का|tam-nA|voicetype-
VMC	v	gen-|num-pl|pers-|case-o|vib-ना_वाला|tam-nA|voicetype-
VMC	v	gen-|num-pl|pers-|case-|vib-ना_वाला|tam-nA|voicetype-
VMC	v	gen-|num-sg|pers-3|case-|vib-या|tam-yA|voicetype-
VMC	v	gen-|num-sg|pers-|case-o|vib-ना_दे+ना_का|tam-nA|voicetype-
VMC	v	gen-|num-sg|pers-|case-|vib-ना_का|tam-nA|voicetype-
VMC	v	gen-|num-|pers-|case-d|vib-ना|tam-nA|voicetype-
VMC	v	gen-|num-|pers-|case-o|vib-ना_जा+ना_सहित|tam-nA|voicetype-
VMC	v	gen-|num-|pers-|case-o|vib-ना_में|tam-nA|voicetype-
VMC	v	gen-|num-|pers-|case-o|vib-ना_से|tam-nA|voicetype-
VMC	v	gen-|num-|pers-|case-|vib-0_कर|tam-|voicetype-
VMC	v	gen-|num-|pers-|case-|vib-0_के_लिए|tam-|voicetype-
VMC	v	gen-|num-|pers-|case-|vib-|tam-|voicetype-
VMC	v	gen-|num-|pers-|case-|vib-ना_में|tam-nA|voicetype-
VMC	v	gen-|num-|pers-|case-|vib-ना|tam-nA|voicetype-
WQ	pn	gen-f|num-sg|pers-3|case-d|vib-|tam-|voicetype-
WQ	pn	gen-f|num-sg|pers-3|case-o|vib-|tam-kA|voicetype-
WQ	pn	gen-f|num-sg|pers-3|case-o|vib-|tam-|voicetype-
WQ	pn	gen-f|num-sg|pers-3|case-o|vib-का|tam-kA|voicetype-
WQ	pn	gen-m|num-pl|pers-3|case-d|vib-|tam-|voicetype-
WQ	pn	gen-m|num-pl|pers-3|case-o|vib-0_को|tam-|voicetype-
WQ	pn	gen-m|num-pl|pers-3|case-o|vib-|tam-|voicetype-
WQ	pn	gen-m|num-sg|pers-3|case-d|vib-|tam-|voicetype-
WQ	pn	gen-m|num-sg|pers-3|case-o|vib-|tam-kA|voicetype-
WQ	pn	gen-m|num-sg|pers-3|case-o|vib-|tam-|voicetype-
WQ	pn	gen-m|num-sg|pers-3|case-o|vib-का|tam-kA|voicetype-
WQ	pn	gen-|num-pl|pers-3|case-o|vib-|tam-|voicetype-
WQ	pn	gen-|num-sg|pers-3|case-d|vib-|tam-|voicetype-
WQ	pn	gen-|num-sg|pers-3|case-o|vib-|tam-ko|voicetype-
WQ	pn	gen-|num-sg|pers-3|case-o|vib-|tam-ne|voicetype-
WQ	pn	gen-|num-sg|pers-3|case-o|vib-|tam-|voicetype-
WQ	pn	gen-|num-sg|pers-3|case-o|vib-को|tam-ko|voicetype-
WQ	pn	gen-|num-sg|pers-3|case-o|vib-ने|tam-ne|voicetype-
WQ	pn	gen-|num-|pers-|case-d|vib-|tam-|voicetype-
WQ	pn	gen-|num-|pers-|case-o|vib-0_तक|tam-|voicetype-
WQ	pn	gen-|num-|pers-|case-o|vib-0_से|tam-|voicetype-
WQ	pn	gen-|num-|pers-|case-o|vib-|tam-|voicetype-
WQ	pn	gen-|num-|pers-|case-|vib-0_लिए|tam-|voicetype-
WQ	pn	gen-|num-|pers-|case-|vib-|tam-|voicetype-
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

Lingua::Interset::Tagset::HI::Conll - Driver for the Hindi tagset of the shared tasks at ICON 2009, ICON 2010 and COLING 2012, as used in the CoNLL data format.

=head1 VERSION

version 3.015

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::HI::Conll;
  my $driver = Lingua::Interset::Tagset::HI::Conll->new();
  my $fs = $driver->decode("NN\tn\tgen-|num-sg|pers-|case-d|vib-|tam-|voicetype-");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('hi::conll', "NN\tn\tgen-|num-sg|pers-|case-d|vib-|tam-|voicetype-");

=head1 DESCRIPTION

Interset driver for the Hindi tagset of the shared tasks at
ICON 2009, ICON 2010 and COLING 2012, as used in the CoNLL data format.
CoNLL tagsets in Interset are traditionally three values separated by tabs,
coming from the CoNLL columns CPOS, POS and FEAT.

In the case of Hindi, the CoNLL data had to be filtered before collecting the input tags.
The data of the ICON shared tasks were converted to CoNLL from the native Shakti Standard
Fromat (SSF) and the CoNLL CPOS column contained so-called chunk tag, which we do not
want to decode. The conversion procedure was modified for the COLING 2012 shared task
and this data did not contain chunk tags in the CPOS column. We expect the 2012 format,
that is:

The CPOS column contains the part-of-speech tag that was previously (during ICON tasks)
in the POS column.

The POS column contains the value of the C<cat> feature from the morphological analyzer.
It is also a part-of-speech category but the set of tags is different, with different
granularity. As these two POS tags come from different sources, there are occasional
inconsistencies between their values. Inconsistent combinations may not be decoded
correctly by this driver. They have been removed from the driver's list of known tags
and they were not used to test the driver.

Finally the FEAT column contains features and their values.
Unlike in other CoNLL tagsets, some of the features in the Hindi treebank must not be
considered part of morphological tag. We have removed the following features
(it is not necessary to remove them when the driver is used to decode; they will be
simply ignored. However, we will not output these features when the driver is used
to encode.)

C<lex> contains lemma or stem.
C<cat> contains the same value as the POS column.
C<chunkId> identifies the chunk to which the word belongs.
C<chunkType> is either I<head> or I<child>.
C<stype> pertains to the entire sentence (declarative, imperative or interrogative).

Short description of the part of speech tags can be found in
L<http://ltrc.iiit.ac.in/nlptools2010/documentation.php>.
More information is available in the annotators' manual at
L<http://ltrc.iiit.ac.in/MachineTrans/publications/technicalReports/tr031/posguidelines.pdf>.

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
