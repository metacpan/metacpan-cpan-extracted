# ABSTRACT: Driver for the Hebrew tagset.
# Copyright © 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Copyright © 2013 Rudolf Rosa <rosa@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::HE::Conll;
use strict;
use warnings;
our $VERSION = '3.011';

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
    return 'he::conll';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # PART OF SPEECH ####################
    # Yoav Goldberg:
    # The tagging conversion was done in a semi-automated process (a heuristic
    # mapping between the tagsets, which accounts for the tree context, was
    # defined and applied. Some hard cases were left unresolved in the automatic
    # process and marked for manual annotation). Words that lack an analysis in
    # the Morphological Analyzer are assigned the tag !!UNK!!, and words that do
    # not have a correct analysis in the morphological analyzer are assigned the
    # tag !!MISS!!
    $atoms{pos} = $self->create_atom
    (
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # Adverb appearing as prefix
            # כ
            'ADVERB' => ['pos' => 'adv', 'other' => {'advtype' => 'prefix'}],
            # AT (direct object) marker
            # תא
            'AT' => ['pos' => 'part'],
            # There are two ways of tagging participles:
            # BN (or BN_S_PP or BNT) part of speech ... we decode it as 'adj|verb'.
            # VB part of speech, BEINONI feature ... we decode it as 'verb'.
            # Beinoni (participle) form
            # רושק, ףסונ, עגונ, רבודמ
            'BN' => ['pos' => 'adj|verb', 'verbform' => 'part'],
            # Beinoni Form with a possessive suffix
            # היבשוי
            'BN_S_PP' => ['pos' => 'adj|verb', 'verbform' => 'part', 'poss' => 'yes'],
            # Construct-state Beinoni Form
            # עבטמ, הברמ, תלזוא, יליחנמ, יכומ
            'BNT' => ['pos' => 'adj|verb', 'verbform' => 'part', 'definite' => 'cons'],
            # Conjunction
            # ש, דוגינב, לככ, יפכ
            'CC' => ['pos' => 'conj'],
            # Coordinating Conjunction other than ו
            # םג, םא, וא, לבא, קר
            'CC-COORD' => ['pos' => 'conj', 'conjtype' => 'coor'],
            # Relativizing Conjunction
            # אשר ašər אֲשֶׁר = which, that, who
            'CC-REL' => ['pos' => 'conj', 'prontype' => 'rel'],
            # Subordinating Conjunction
            # יכ, ידכ, רחאל, רשאכ, ומכ
            'CC-SUB' => ['pos' => 'conj', 'conjtype' => 'sub'],
            # Number
            # תחא, 1, 0
            'CD' => ['pos' => 'num'],
            # Construct Numeral
            # ינש, יתש, יפלא, תואמ, תורשע
            'CDT' => ['pos' => 'num', 'definite' => 'cons'],
            # The ו coordinating word
            # ו (wa) = and ... 3707 occurrences; but why is it not CC-COORD? (35 occs. is CC but not CC-COORD.)
            # We will decode it but we will not list it as a known tag and we will encode CC-COORD back.
            'CONJ' => ['pos' => 'conj', 'conjtype' => 'coor'],
            # Copula (present) and Auxiliaries (past and future)
            # היה, ויה, התיה, וניא, היהי
            'COP' => ['pos' => 'verb', 'verbtype' => 'cop'],
            #89 COP-TOINFINITIVE
            'COP-TOINFINITIVE' => ['pos' => 'verb', 'verbtype' => 'cop', 'verbform' => 'inf'],
            # H marker (the definite article prefix: 15847 occurrences)
            # ה
            'DEF' => ['pos' => 'adj', 'prontype' => 'art', 'definite' => 'def'],
            #53 DEF@DT הכל (hkl) = "everything", 46 occurrences
            'DEF@DT' => ['pos' => 'adj', 'definite' => 'def', 'prontype' => 'tot'],
            # Determiner
            # יהשוזיא, רחבמ, לכ
            'DT' => ['pos' => 'adj', 'prontype' => 'prn'],
            # Construct-state Determiner
            # המכ, ותוא, םוש, הברה
            'DTT' => ['pos' => 'adj', 'prontype' => 'prn', 'definite' => 'cons'],
            # Existential
            # שי, ןיא, םנשי, היה
            'EX' => ['pos' => 'adv', 'advtype' => 'ex'],
            # Preposition
            # לע, ל, םע, ןיב
            'IN' => ['pos' => 'adp|conj', 'adpostype' => 'prep', 'conjtype' => 'sub'],
            # Interjection
            # סופ, ףוא, הלילח, אנ, יוא
            'INTJ' => ['pos' => 'int'],
            # Adjective
            # םירחא, םיבר, שדח, לודג, ימואל
            'JJ' => ['pos' => 'adj'],
            # Construct-state Adjective
            # רבודמ, יעדומ, ילוער, תרסח, יבורמ
            'JJT' => ['pos' => 'adj', 'definite' => 'cons'],
            # Modal
            # רשפא, לוכי, ךירצ, הלוכי, לולע
            'MD' => ['pos' => 'verb', 'verbtype' => 'mod'],
            # Numerical Expression: dates, times and other codes composed of numbers and dots.
            # 03.02, 00.02, 11.61, 28.6.6, 11.31
            'NCD' => ['pos' => 'num', 'numform' => 'digit'],
            # Noun
            # הרטשמ, הלשממ, םוי, ץרא
            'NN' => ['pos' => 'noun', 'nountype' => 'com'],
            # Proper Nouns
            # לארשי, םילשורי, אנהכ, ביבא
            'NNP' => ['pos' => 'noun', 'nountype' => 'prop'],
            # Noun with a possessive suffix
            # ותומ, וירבד, וייח, ופוס, ומש
            'NN_S_PP' => ['pos' => 'noun', 'poss' => 'yes'],
            # Construct-state nouns
            # ידי, תעדוו
            'NNT' => ['pos' => 'noun', 'definite' => 'cons'],
            # “Prefix” wordlets
            # בלתי, אי, בין, אנטי, תת
            # 22 different word forms in the corpus.
            # 47 occurrences of the most frequent one, בלתי (vlty).
            'P' => ['pos' => 'part', 'other' => {'parttype' => 'prefix'}],
            # Possessive
            # לש
            'POS' => ['pos' => 'part', 'poss' => 'yes'],
            # Prefix-Prepositions
            # ב, ל, מ, כ, שכ
            'PREPOSITION' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # Pronouns TODO prontype?
            # אוה, הז, איה, םה, וז
            'PRP' => ['pos' => 'noun', 'prontype' => 'prs'],
            #222 PRP-DEM
            'PRP-DEM' => ['pos' => 'adj', 'prontype' => 'dem'],
            #2 PRP-IMP
            # כְּלוּם kəlum = anything PRP PRP-IMP _
            # Used with a negative word, so the combination means "nothing".
            'PRP-IMP' => ['pos' => 'noun', 'prontype' => 'neg'],
            # Punctuation
            # ,, ., ־
            'PUNC' => ['pos' => 'punc'],
            # QuestionWord
            # המ, ימ, םאה, מ, ןכיה
            'QW' => ['pos' => 'adj', 'prontype' => 'int'],
            # Adverbs
            # אל, רתוי, דוע, רבכ, לומתא
            'RB' => ['pos' => 'adv'],
            # Relativizer
            # ש
            'REL-SUBCONJ' => ['pos' => 'adj', 'prontype' => 'rel'],
            # Nominative suffix
            # F|P|3: הן~ (-hen)
            # F|S|3: היא~ (-hya)
            # M|P|3: הם~ (-hem)
            # M|S|2: אתה~ (-ath)
            # M|S|3: הוא~ (-hwa)
            'S_ANP' => ['pos' => 'part', 'case' => 'nom'],
            # Pronomial suffix TODO prontype?
            # suffאוה, suffמה, suffאיה
            # F|M|P|1: אנחנו~ (-anaxnú)
            # F|M|S|1: אני~ (-aní)
            # F|P|3: הן~ (-hen)
            # F|S|2: את~ (-at)
            # F|S|3: היא~ (-hya)
            # M|P|2: אתם~ (-atm)
            # M|P|3: הם~ (-hem)
            # M|S|2: אתה~ (-ath)
            # M|S|3: הוא~ (-hwa)
            'S_PRN' => ['pos' => 'part', 'prontype' => 'prs'],
            # Temporal Suboordinating Conjunction
            # כש (kš) = when ... 111 occurrences
            # מש (mš) = duration ... 2 occurrences
            'TEMP-SUBCONJ' => ['pos' => 'conj', 'conjtype' => 'sub', 'advtype' => 'tim'],
            # Titles
            # ד"ר (d"r) = Dr. ... TTL S, 24 occurrences
            # עו"ד (ew"d) = Attorney ... TTL S, 11 occurrences
            # זצ"ל (zc"l, zexer cadik livraxa) = holy/righteous person in judaism ... TTL S, 1 occurrence
            # ניצב (nycv) = commander ... TTL M|S, 9 occurrences
            # פרופסור (profsor) = proffessor ... TTL M|S, 4 occurrences
            # מר (mr) = Mr. ... TTL M|S, 4 occurrences
            # ז"ל (z"l) = late ... TTL M|F|S|P, 3 occurrences
            # A shorthand way of writing זכרונו\ה\ם\ן לברכה (zikhronó/á/ám/án livrakhá), which means “may his/her/their memory be a blessing”.
            # The abbreviation ז״ל is nearly always read out as the two words it stands for.
            # This means that its pronunciation depends on whether the referent is a woman, a man, multiple women, or multiple men and women.
            # It is, however, also pronounced /zal/.
            'TTL' => ['pos' => 'noun', 'other' => {'nountype' => 'title'}],
            # Verbs
            # רמא, רמוא, הארנ, עדוי
            'VB' => ['pos' => 'verb'],
            #1 VB-BAREINFINITIVE
            'VB-BAREINFINITIVE' => ['pos' => 'verb', 'verbform' => 'inf'],
            # Infinitive Verbs
            # תושעל, םלשל, עונמל, תתל, עצבל
            'VB-TOINFINITIVE' => ['pos' => 'verb', 'verbform' => 'inf', 'other' => {'infinitive' => 'to'}],
            #550 !!MISS!!
            # words that do not have a correct analysis in the morphological analyzer
            '!!MISS!!' => ['other' => {'unknown' => 'miss'}],
            #6 !!SOME_!!
            '!!SOME_!!' => ['other' => {'unknown' => 'some'}],
            #520 !!UNK!!
            # Words that lack an analysis in the Morphological Analyzer
            '!!UNK!!' => ['other' => {'unknown' => 'unk'}],
            #134 !!ZVL!!
            '!!ZVL!!' => ['other' => {'unknown' => 'zvl'}]
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''    => { 'poss' => { 'yes' => 'NN_S_PP',
                                                              '@' => { 'nountype' => { 'prop' => 'NNP',
                                                                       '@' => { 'definite' => { 'cons' => 'NNT',
                                                                                '@' => { 'other/nountype' => { 'title' => 'TTL',
                                                                                         '@' => 'NN' }}}}}}}},
                                                   'neg' => 'PRP-IMP',
                                                   '@'   => 'PRP' }},
                       'adj'  => { 'prontype' => { 'art' => 'DEF',
                                                   'tot' => 'DEF@DT',
                                                   'dem' => 'PRP-DEM',
                                                   'int' => 'QW',
                                                   'rel' => 'REL-SUBCONJ',
                                                   ''    => { 'definite' => { 'cons' => 'JJT',
                                                                              '@'    => 'JJ' }},
                                                   '@'   => { 'definite' => { 'cons' => 'DTT',
                                                                              '@'    => 'DT' }}}},
                       'num'  => { 'definite' => { 'cons' => 'CDT',
                                                   '@'    => { 'numform' => { 'digit' => 'NCD',
                                                                              '@'     => 'CD' }}}},
                       # There are two ways of tagging participles:
                       # BN (or BN_S_PP or BNT) part of speech ... we decode it as 'adj|verb'.
                       # VB part of speech, BEINONI feature ... we decode it as 'verb'.
                       'adj|verb' => { 'poss' => { 'yes' => 'BN_S_PP',
                                                   '@'    => { 'definite' => { 'cons' => 'BNT',
                                                                               '@'    => 'BN' }}}},
                       'verb' => { 'verbtype' => { 'cop' => { 'verbform' => { 'inf' => 'COP-TOINFINITIVE',
                                                                              '@'   => 'COP' }},
                                                   'mod' => 'MD',
                                                   '@'   => { 'verbform' => { 'inf'  => { 'other/infinitive' => { 'to' => 'VB-TOINFINITIVE',
                                                                                                                  '@'  => 'VB-BAREINFINITIVE' }},
                                                                              '@'    => 'VB' }}}},
                       'adv'  => { 'advtype' => { 'ex' => 'EX',
                                                  '@'  => { 'other/advtype' => { 'prefix' => 'ADVERB',
                                                                                 '@'      => 'RB' }}}},
                       'conj' => { 'conjtype' => { 'coor' => 'CC-COORD',
                                                   'sub'  => { 'advtype' => { 'tim' => 'TEMP-SUBCONJ',
                                                                              '@'   => 'CC-SUB' }},
                                                   '@'    => { 'prontype' => { 'rel' => 'CC-REL',
                                                                               '@'   => 'CC' }}}},
                       'adp|conj'  => 'IN',
                       'adp'  => 'PREPOSITION',
                       'part' => { 'poss' => { 'yes' => 'POS',
                                               '@'    => { 'case' => { 'nom' => 'S_ANP',
                                                                       '@'   => { 'prontype' => { 'prs' => 'S_PRN',
                                                                                                  '@'   => { 'other/parttype' => { 'prefix' => 'P',
                                                                                                                                   '@'      => 'AT' }}}}}}}},
                       'int'  => 'INTJ',
                       'punc' => 'PUNC',
                       '@'    => { 'other/unknown' => { 'miss' => '!!MISS!!',
                                                        'some' => '!!SOME_!!',
                                                        'zvl'  => '!!ZVL!!',
                                                        '@'    => '!!UNK!!' }}}
        }
    );
    # PRONOUN TYPE ####################
    # Personal pronouns (PRP PRP PERS):
    # אֲנִי aní = já
    # אֲנַחְנוּ anáxnu = my (hovorově)
    # אָנוּ ánu = my (spisovně)
    # אַתָּה atá = ty (mužský rod)
    # אַתְּ át = ty (ženský rod)
    # אֲתֶּם atém = vy (mužský rod)
    # אַתֶּן atén = vy (ženský rod)
    # הוּא hu = on
    # הִיא hi = ona
    # הֵם hem = oni
    # הֵן hen = ony
    # Demonstrative pronouns (PRP PRP DEM):
    # זֶה ze = tento
    # זוֹ zó = tato
    # Interrogative pronouns:
    # מָה má = co, který, která
    # מִי mí = kdo
    # The undocumented "IMP" feature seems to mean "indefinite, negative or total pronoun".
    # כולם \ כֻּלָּם kulám = all PRP PRP M|P|3|IMP
    # כלשהו klšhú (כָּלְשֶׁהוּ) káləšhú = some PRP PRP M|S|3|IMP
    # כלשהי klšhí (כָּלְשֶׁהִי) káləšhí = some PRP PRP F|S|IMP
    # כלשהם klšhm (כָּלְשֶׁהֵם) káləšhem = any PRP PRP M|P|IMP
    # כלשהן klšhn (כָּלְשֶׁהֵן) káləšhen = any PRP PRP F|P|IMP
    # כְּלוּם kəlum = anything PRP PRP-IMP _
    # Used with a negative word, so the combination means "nothing".
    $atoms{prontype} = $self->create_atom
    (
        'surfeature' => 'prontype',
        'decode_map' =>
        {
            'PERS' => ['prontype' => 'prs'],
            'DEM'  => ['prontype' => 'dem'],
            # We would want to set prontype => 'ind|neg|tot' here but we cannot because we have to preserve the weird distinction of
            # PRP PRP-IMP _
            # PRP PRP    F|P|IMP
            'IMP'  => ['prontype' => 'ind|tot']
        },
        'encode_map' =>
        {
            'prontype' => { 'prs' => 'PERS',
                            'dem' => 'DEM',
                            'ind' => 'IMP',
                            'neg' => 'IMP',
                            'tot' => 'IMP' }
        }
    );
    # UNKNOWN WORDS ####################
    $atoms{unknown} = $self->create_atom
    (
        'surfeature' => 'unknown',
        'decode_map' =>
        {
            '!!MISS!!' => ['other' => {'unknown' => 'miss'}],
            '!!UNK!!'  => ['other' => {'unknown' => 'unk'}]
        },
        'encode_map' =>
        {
            'other/unknown' => { 'miss' => '!!MISS!!',
                                 '@'    => '!!UNK!!' }
        }
    );
    # GENDER ####################
    $atoms{gender} = $self->create_atom
    (
        'surfeature' => 'gender',
        'decode_map' =>
        {
            # used usually with nouns. pronouns, numerals, verbs and adjectives
            'M' => ['gender' => 'masc'],
            'F' => ['gender' => 'fem'],
        },
        'encode_map' =>
        {
            'gender' => { 'masc' => 'M',
                          'fem'  => 'F' }
        }
    );
    # POSSESSOR'S GENDER ####################
    $atoms{possgender} = $self->create_atom
    (
        'surfeature' => 'possgender',
        'decode_map' =>
        {
            # used with NN and BN
            'suf_M'  => ['possgender' => 'masc'],
            'suf_F'  => ['possgender' => 'fem'],
            'suf_MF' => ['possgender' => 'masc|fem']
        },
        'encode_map' =>
        {
            'possgender' => { 'masc|fem' => 'suf_MF',
                              'masc'     => 'suf_M',
                              'fem'      => 'suf_F' }
        }
    );
    # NUMBER ####################
    $atoms{number} = $self->create_atom
    (
        'surfeature' => 'number',
        'decode_map' =>
        {
            # used usually with nouns. pronouns, numerals, verbs and adjectives
            'S' => ['number' => 'sing'],
            'D' => ['number' => 'dual'],
            'DP'=> ['number' => 'dual|plur'], # pseudo-dual, that is dual used as plural
            'P' => ['number' => 'plur'],
        },
        'encode_map' =>
        {
            'number' => { 'sing' => 'S',
                          'dual|plur' => 'DP',
                          'dual' => 'D',
                          'plur' => 'P' }
        }
    );
    # POSSESSOR'S NUMBER ####################
    $atoms{possnumber} = $self->create_atom
    (
        'surfeature' => 'possnumber',
        'decode_map' =>
        {
            # used with NN and BN
            'suf_S' => ['possnumber' => 'sing'],
            'suf_P' => ['possnumber' => 'plur']
        },
        'encode_map' =>
        {
            'possnumber' => { 'sing' => 'suf_S',
                              'plur' => 'suf_P' }
        }
    );
    # PERSON ####################
    # The "A" feature:
    # Used with BN, BNT, MD, VB (i.e. verb forms).
    # For MD and VB, it always coincides with BEINONI.
    # MD and VB BEINONI without A exist but they are very rare.
    # COP BEINONI is always without A.
    # It seems to replace the person feature, meaning person=all. (COP always has person.)
    $atoms{person} = $self->create_atom
    (
        'surfeature' => 'person',
        'decode_map' =>
        {
            # used with VB, COP, MD, BN; NN, PRP, S_PRP, S_ANP
            '1' => ['person' => '1'],
            '2' => ['person' => '2'],
            '3' => ['person' => '3'],
            'A' => [],
        },
        'encode_map' =>
        {
            'person' => { '1' => '1',
                          '2' => '2',
                          '3' => '3',
                          ''  => 'A' }
        }
    );
    # POSSESSOR'S PERSON ####################
    $atoms{possperson} = $self->create_atom
    (
        'surfeature' => 'possperson',
        'decode_map' =>
        {
            # used with NN and BN
            'suf_1' => ['possperson' => '1'],
            'suf_2' => ['possperson' => '2'],
            'suf_3' => ['possperson' => '3']
        },
        'encode_map' =>
        {
            'possperson' => { '1' => 'suf_1',
                              '2' => 'suf_2',
                              '3' => 'suf_3' }
        }
    );
    # VERB FORM ####################
    $atoms{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            # used with COP and VB
            'PAST'       => ['tense' => 'past'],
            'FUTURE'     => ['tense' => 'fut'],
            'IMPERATIVE' => ['mood' => 'imp'],
            'BEINONI'    => ['verbform' => 'part']
        },
        'encode_map' =>
        {
            'verbform' => { 'part' => 'BEINONI',
                            '@'    => { 'mood' => { 'imp' => 'IMPERATIVE',
                                                    '@'   => { 'tense' => { 'past' => 'PAST',
                                                                            'fut'  => 'FUTURE' }}}}}
        }
    );
    # POLARITY ####################
    $atoms{polarity} = $self->create_simple_atom
    (
        'intfeature' => 'polarity',
        'simple_decode_map' =>
        {
            # used with COP
            'POSITIVE' => 'pos',
            'NEGATIVE' => 'neg'
        }
    );
    # BINYANIM ####################
    # used with VB, BN and BNT
    # binyan = building, structure
    # This seems to be a traditional part of Hebrew morphology. See e.g. page 1347 of:
    # http://books.google.cz/books?id=l7UWMZq7FGIC&pg=PA1350&lpg=PA1350&dq=HIFIL+HITPAEL+HUFAL+NIFAL+PAAL+PIEL+PUAL+HIFIL&source=bl&ots=bnVti7b3wi&sig=8O9q5x0DA1DqYiH3g8yVY8r9qgM&hl=cs&sa=X&ei=pf1wVLeADcLOygON7YHoAw&ved=0CCkQ6AEwAQ#v=onepage&q=HIFIL%20HITPAEL%20HUFAL%20NIFAL%20PAAL%20PIEL%20PUAL%20HIFIL&f=false
    # or
    # http://tzion.org/devarim/The%20Seven%20Binyanim.pdf
    $atoms{binyan} = $self->create_atom
    (
        'surfeature' => 'binyan',
        'decode_map' =>
        {
            # PAAL      CaCaC      katav = wrote (basic/simple)
            'PAAL'    => ['voice' => 'act'],
            # NIFAL     niCCaC     niktav = was written (basic/simple-passive)
            'NIFAL'   => ['voice' => 'pass'],
            # PIEL      CiCeC      kitev = inscribed/engraved (intensive)
            'PIEL'    => ['voice' => 'int'],
            # PUAL      CuCaC      kutav = was inscribed/engraved (intensive-passive) (theoretical, to illustrate the binyanim; not used with this root)
            'PUAL'    => ['voice' => 'int|pass'],
            # HIFIL     hiCCiC     hiktiv = dictated (causative)
            'HIFIL'   => ['voice' => 'cau'],
            # HUFAL     huCCaC     huktav = was dictated (causative-passive)
            'HUFAL'   => ['voice' => 'cau|pass'],
            # HITPAEL   hitCaCeC   hitkatev = corresponded (reflexive/cooperative aspect ... both active and passive)
            'HITPAEL' => ['voice' => 'mid']
        },
        'encode_map' =>
        {
            'voice' => { 'int|pass' => 'PUAL',
                         'cau|pass' => 'HUFAL',
                         'pass'     => 'NIFAL',
                         'mid'      => 'HITPAEL',
                         'act'      => 'PAAL',
                         'cau'      => 'HIFIL',
                         'int'      => 'PIEL' }
        }
    );
    # MERGED ATOM TO DECODE ANY FEATURE VALUE ####################
    my @fatoms = map {$atoms{$_}} @{$self->features_all()};
    $atoms{feature} = $self->create_merged_atom
    (
        'surfeature' => 'feature',
        'atoms'      => \@fatoms
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
    my @features = ('gender', 'number', 'person', 'verbform', 'polarity', 'binyan', 'possgender', 'possnumber', 'possperson', 'prontype', 'unknown');
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
        '!!MISS!!' => ['unknown'],
        '!!UNK!!'  => ['unknown'],
        'BN'       => ['gender', 'number', 'person', 'binyan', 'possgender', 'possnumber', 'possperson'],
        'BNT'      => ['gender', 'number', 'person', 'binyan'],
        'CD'       => ['gender', 'number'],
        'CDT'      => ['gender', 'number'],
        'COP'      => ['gender', 'number', 'person', 'verbform', 'polarity'],
        'COP-TOINFINITIVE' => ['polarity'],
        'JJ'       => ['gender', 'number'],
        'JJT'      => ['gender', 'number'],
        'MD'       => ['gender', 'number', 'person', 'verbform'],
        'NN'       => ['gender', 'number', 'possgender', 'possnumber', 'possperson'],
        'NNP'      => ['gender', 'number'],
        'NNT'      => ['gender', 'number'],
        'PRP'      => ['gender', 'number', 'person', 'prontype'],
        'PRPIMP'   => ['gender', 'number', 'prontype'],
        'S_ANP'    => ['gender', 'number', 'person'],
        'S_PRN'    => ['gender', 'number', 'person'],
        'TTL'      => ['gender', 'number'],
        'VB'       => ['gender', 'number', 'person', 'verbform', 'binyan'],
        'VB-TOINFINITIVE' => ['binyan']
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
    $fs->set_tagset('he::conll');
    my $atoms = $self->atoms();
    # three components: part-of-speech tag, subpart of speech, features
    # example: NN\tNN\tM|S
    my ($pos, $subpos, $features) = split(/\s+/, $tag);
    # The underscore character is used if there are no features.
    $features = '' if($features eq '_');
    my @features = split(/\|/, $features);
    $atoms->{pos}->decode_and_merge_hard($subpos, $fs);
    foreach my $feature (@features)
    {
        $atoms->{feature}->decode_and_merge_hard($feature, $fs);
    }
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
    my $pos = $atoms->{pos}->encode($fs);
    my $subpos = $pos;
    $pos =~ s/(_S_PP|-BAREINFINITIVE|-COORD|-DEM|-IMP|-REL|-SUB|-SUBCONJ|-TOINFINITIVE)$//;
    my $fpos = $pos;
    if($subpos =~ m/(PRP-DEM|PRP-IMP|INFINITIVE)/)
    {
        $fpos = $subpos;
    }
    elsif($fs->is_noun() && $fs->prontype() =~ m/ind|neg|tot/)
    {
        $fpos = 'PRPIMP';
    }
    my $feature_names = $self->get_feature_names($fpos);
    my $value_only = 1;
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names, $value_only);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus and cleaned (canonical ordering of
# features).
# 370 tags after cleaning.
###!!! TODO: Some of the original tags contained two values of gender (M|F) if
###!!! the word did not distinguish gender. We currently cannot detect it
###!!! because we process every feature independently but we should. For
###!!! example, the first-person pronouns (and S_PRN) in Hebrew are genderless.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
!!MISS!!	!!MISS!!	!!MISS!!
!!SOME_!!	!!SOME_!!	_
!!UNK!!	!!UNK!!	!!UNK!!
!!ZVL!!	!!ZVL!!	_
ADVERB	ADVERB	_
AT	AT	_
BN	BN	F|P|A
BN	BN	F|P|A|HIFIL
BN	BN	F|P|A|HITPAEL
BN	BN	F|P|A|HUFAL
BN	BN	F|P|A|NIFAL
BN	BN	F|P|A|PAAL
BN	BN	F|P|A|PIEL
BN	BN	F|P|A|PUAL
BN	BN	F|S|3
BN	BN	F|S|A
BN	BN	F|S|A|HIFIL
BN	BN	F|S|A|HITPAEL
BN	BN	F|S|A|HUFAL
BN	BN	F|S|A|NIFAL
BN	BN	F|S|A|PAAL
BN	BN	F|S|A|PIEL
BN	BN	F|S|A|PUAL
BN	BN	M|P|1
BN	BN	M|P|3|HIFIL
BN	BN	M|P|A
BN	BN	M|P|A|HIFIL
BN	BN	M|P|A|HITPAEL
BN	BN	M|P|A|HUFAL
BN	BN	M|P|A|NIFAL
BN	BN	M|P|A|PAAL
BN	BN	M|P|A|PIEL
BN	BN	M|P|A|PUAL
BN	BN	M|S|A
BN	BN	M|S|A|HIFIL
BN	BN	M|S|A|HITPAEL
BN	BN	M|S|A|HUFAL
BN	BN	M|S|A|NIFAL
BN	BN	M|S|A|PAAL
BN	BN	M|S|A|PIEL
BN	BN	M|S|A|PUAL
BN	BN_S_PP	M|P|A|PAAL|suf_F|suf_P|suf_3
BN	BN_S_PP	M|P|A|PAAL|suf_F|suf_S|suf_3
BN	BN_S_PP	M|P|A|PAAL|suf_M|suf_S|suf_3
BN	BN_S_PP	M|S|A|HIFIL|suf_M|suf_S|suf_3
BN	BN_S_PP	M|S|A|PAAL|suf_F|suf_P|suf_3
BN	BN_S_PP	M|S|A|PAAL|suf_M|suf_P|suf_3
BN	BN_S_PP	M|S|A|PIEL|suf_M|suf_S|suf_3
BNT	BNT	F|P|A|HIFIL
BNT	BNT	F|P|A|HITPAEL
BNT	BNT	F|S|A|HIFIL
BNT	BNT	F|S|A|PAAL
BNT	BNT	M|P|A
BNT	BNT	M|P|A|HIFIL
BNT	BNT	M|P|A|HUFAL
BNT	BNT	M|P|A|NIFAL
BNT	BNT	M|P|A|PAAL
BNT	BNT	M|P|A|PIEL
BNT	BNT	M|S|A
BNT	BNT	M|S|A|HIFIL
BNT	BNT	M|S|A|PAAL
BNT	BNT	M|S|A|PIEL
BNT	BNT	M|S|A|PUAL
CC	CC	_
CC	CC-COORD	_
CC	CC-REL	_
CC	CC-SUB	_
CD	CD	F|D
CD	CD	F|P
CD	CD	F|S
CD	CD	M|D
CD	CD	M|P
CD	CD	M|S
CD	CD	_
CDT	CDT	F|D
CDT	CDT	F|P
CDT	CDT	F|S
CDT	CDT	M|D
CDT	CDT	M|P
CDT	CDT	M|S
COP	COP	F|P|3|BEINONI|NEGATIVE
COP	COP	F|P|3|FUTURE|POSITIVE
COP	COP	F|S|2|PAST|POSITIVE
COP	COP	F|S|3|BEINONI|NEGATIVE
COP	COP	F|S|3|BEINONI|POSITIVE
COP	COP	F|S|3|FUTURE|POSITIVE
COP	COP	F|S|3|PAST|POSITIVE
COP	COP	M|P|1|BEINONI|NEGATIVE
COP	COP	M|P|1|BEINONI|POSITIVE
COP	COP	M|P|1|FUTURE|POSITIVE
COP	COP	M|P|2|BEINONI|NEGATIVE
COP	COP	M|P|2|IMPERATIVE|POSITIVE
COP	COP	M|P|3|BEINONI|NEGATIVE
COP	COP	M|P|3|BEINONI|POSITIVE
COP	COP	M|P|3|FUTURE|POSITIVE
COP	COP	M|S|1|BEINONI|NEGATIVE
COP	COP	M|S|1|PAST|POSITIVE
COP	COP	M|S|2|BEINONI|NEGATIVE
COP	COP	M|S|2|IMPERATIVE|POSITIVE
COP	COP	M|S|3|BEINONI|NEGATIVE
COP	COP	M|S|3|BEINONI|POSITIVE
COP	COP	M|S|3|FUTURE|POSITIVE
COP	COP	M|S|3|PAST|POSITIVE
COP	COP-TOINFINITIVE	POSITIVE
DEF	DEF	_
DEF\@DT	DEF\@DT	_
DT	DT	_
DTT	DTT	_
EX	EX	_
IN	IN	_
INTJ	INTJ	_
JJ	JJ	F|P
JJ	JJ	F|S
JJ	JJ	M|P
JJ	JJ	M|S
JJ	JJ	_
JJT	JJT	F|P
JJT	JJT	F|S
JJT	JJT	M|P
JJT	JJT	M|S
MD	MD	A
MD	MD	F|P|A
MD	MD	F|P|A|BEINONI
MD	MD	F|S|3|FUTURE
MD	MD	F|S|A
MD	MD	F|S|A|BEINONI
MD	MD	M|P|1|FUTURE
MD	MD	M|P|1|PAST
MD	MD	M|P|3|FUTURE
MD	MD	M|P|A
MD	MD	M|P|A|BEINONI
MD	MD	M|S|2|FUTURE
MD	MD	M|S|A
MD	MD	M|S|A|BEINONI
MD	MD	M|S|A|PAST
NCD	NCD	_
NN	NN	F|D
NN	NN	F|DP
NN	NN	F|P
NN	NN	F|S
NN	NN	M
NN	NN	M|D
NN	NN	M|DP
NN	NN	M|P
NN	NN	M|S
NN	NN	S
NN	NN	_
NN	NN_S_PP	F|P|suf_F|suf_P|suf_3
NN	NN_S_PP	F|P|suf_F|suf_S|suf_2
NN	NN_S_PP	F|P|suf_F|suf_S|suf_3
NN	NN_S_PP	F|P|suf_MF|suf_P|suf_1
NN	NN_S_PP	F|P|suf_MF|suf_S|suf_1
NN	NN_S_PP	F|P|suf_M|suf_P|suf_2
NN	NN_S_PP	F|P|suf_M|suf_P|suf_3
NN	NN_S_PP	F|P|suf_M|suf_S|suf_3
NN	NN_S_PP	F|S|suf_F|suf_P|suf_3
NN	NN_S_PP	F|S|suf_F|suf_S|suf_2
NN	NN_S_PP	F|S|suf_F|suf_S|suf_3
NN	NN_S_PP	F|S|suf_MF|suf_P|suf_1
NN	NN_S_PP	F|S|suf_MF|suf_S|suf_1
NN	NN_S_PP	F|S|suf_M|suf_P|suf_2
NN	NN_S_PP	F|S|suf_M|suf_P|suf_3
NN	NN_S_PP	F|S|suf_M|suf_S|suf_3
NN	NN_S_PP	M|P|suf_F|suf_P|suf_3
NN	NN_S_PP	M|P|suf_F|suf_S|suf_2
NN	NN_S_PP	M|P|suf_F|suf_S|suf_3
NN	NN_S_PP	M|P|suf_MF|suf_P|suf_1
NN	NN_S_PP	M|P|suf_MF|suf_S|suf_1
NN	NN_S_PP	M|P|suf_M|suf_P|suf_2
NN	NN_S_PP	M|P|suf_M|suf_P|suf_3
NN	NN_S_PP	M|P|suf_M|suf_S|suf_3
NN	NN_S_PP	M|S|suf_F|suf_P|suf_3
NN	NN_S_PP	M|S|suf_F|suf_S|suf_2
NN	NN_S_PP	M|S|suf_F|suf_S|suf_3
NN	NN_S_PP	M|S|suf_MF|suf_P|suf_1
NN	NN_S_PP	M|S|suf_MF|suf_S|suf_1
NN	NN_S_PP	M|S|suf_M|suf_P|suf_2
NN	NN_S_PP	M|S|suf_M|suf_P|suf_3
NN	NN_S_PP	M|S|suf_M|suf_S|suf_3
NNP	NNP	F|S
NNP	NNP	M|S
NNP	NNP	_
NNT	NNT	F|P
NNT	NNT	F|S
NNT	NNT	M|P
NNT	NNT	M|S
P	P	_
POS	POS	_
PREPOSITION	PREPOSITION	_
PRP	PRP	F|P|1|PERS
PRP	PRP	F|P|3|DEM
PRP	PRP	F|P|3|PERS
PRP	PRP	F|P|IMP
PRP	PRP	F|S|1|PERS
PRP	PRP	F|S|3|DEM
PRP	PRP	F|S|3|PERS
PRP	PRP	F|S|IMP
PRP	PRP	M|P|1|PERS
PRP	PRP	M|P|2|PERS
PRP	PRP	M|P|3|DEM
PRP	PRP	M|P|3|PERS
PRP	PRP	M|P|IMP
PRP	PRP	M|S|1|PERS
PRP	PRP	M|S|2|PERS
PRP	PRP	M|S|3|DEM
PRP	PRP	M|S|3|PERS
PRP	PRP	M|S|IMP
PRP	PRP-DEM	_
PRP	PRP-IMP	_
PUNC	PUNC	_
QW	QW	_
RB	RB	_
REL	REL-SUBCONJ	_
S_ANP	S_ANP	F|P|3
S_ANP	S_ANP	F|S|3
S_ANP	S_ANP	M|P|3
S_ANP	S_ANP	M|S|2
S_ANP	S_ANP	M|S|3
S_PRN	S_PRN	F|P|1
S_PRN	S_PRN	F|P|3
S_PRN	S_PRN	F|S|1
S_PRN	S_PRN	F|S|2
S_PRN	S_PRN	F|S|3
S_PRN	S_PRN	M|P|1
S_PRN	S_PRN	M|P|2
S_PRN	S_PRN	M|P|3
S_PRN	S_PRN	M|S|1
S_PRN	S_PRN	M|S|2
S_PRN	S_PRN	M|S|3
TEMP	TEMP-SUBCONJ	_
TTL	TTL	M|S
TTL	TTL	S
VB	VB	F|P|2|IMPERATIVE
VB	VB	F|P|2|IMPERATIVE|PAAL
VB	VB	F|P|3|FUTURE|PAAL
VB	VB	F|P|3|FUTURE|PIEL
VB	VB	F|P|3|PAST
VB	VB	F|P|A|BEINONI|HIFIL
VB	VB	F|P|A|BEINONI|HITPAEL
VB	VB	F|P|A|BEINONI|HUFAL
VB	VB	F|P|A|BEINONI|NIFAL
VB	VB	F|P|A|BEINONI|PAAL
VB	VB	F|P|A|BEINONI|PIEL
VB	VB	F|P|A|BEINONI|PUAL
VB	VB	F|S|2|FUTURE|HUFAL
VB	VB	F|S|2|FUTURE|PAAL
VB	VB	F|S|2|IMPERATIVE|PAAL
VB	VB	F|S|2|IMPERATIVE|PIEL
VB	VB	F|S|2|PAST
VB	VB	F|S|2|PAST|HIFIL
VB	VB	F|S|2|PAST|HITPAEL
VB	VB	F|S|2|PAST|PAAL
VB	VB	F|S|2|PAST|PIEL
VB	VB	F|S|3|FUTURE|HIFIL
VB	VB	F|S|3|FUTURE|HITPAEL
VB	VB	F|S|3|FUTURE|HUFAL
VB	VB	F|S|3|FUTURE|NIFAL
VB	VB	F|S|3|FUTURE|PAAL
VB	VB	F|S|3|FUTURE|PIEL
VB	VB	F|S|3|FUTURE|PUAL
VB	VB	F|S|3|PAST
VB	VB	F|S|3|PAST|HIFIL
VB	VB	F|S|3|PAST|HITPAEL
VB	VB	F|S|3|PAST|HUFAL
VB	VB	F|S|3|PAST|NIFAL
VB	VB	F|S|3|PAST|PAAL
VB	VB	F|S|3|PAST|PIEL
VB	VB	F|S|3|PAST|PUAL
VB	VB	F|S|A|BEINONI
VB	VB	F|S|A|BEINONI|HIFIL
VB	VB	F|S|A|BEINONI|HITPAEL
VB	VB	F|S|A|BEINONI|HUFAL
VB	VB	F|S|A|BEINONI|NIFAL
VB	VB	F|S|A|BEINONI|PAAL
VB	VB	F|S|A|BEINONI|PIEL
VB	VB	F|S|A|BEINONI|PUAL
VB	VB	M|P|2|PAST|PAAL
VB	VB	M|P|2|PAST|PIEL
VB	VB	M|P|3|BEINONI|HIFIL
VB	VB	M|P|3|FUTURE|PIEL
VB	VB	M|P|3|PAST
VB	VB	M|P|A|BEINONI|HIFIL
VB	VB	M|P|A|BEINONI|HITPAEL
VB	VB	M|P|A|BEINONI|HUFAL
VB	VB	M|P|A|BEINONI|NIFAL
VB	VB	M|P|A|BEINONI|PAAL
VB	VB	M|P|A|BEINONI|PIEL
VB	VB	M|P|A|BEINONI|PUAL
VB	VB	M|S|1|PAST
VB	VB	M|S|2|IMPERATIVE
VB	VB	M|S|2|IMPERATIVE|HIFIL
VB	VB	M|S|2|IMPERATIVE|HITPAEL
VB	VB	M|S|2|IMPERATIVE|PAAL
VB	VB	M|S|2|IMPERATIVE|PIEL
VB	VB	M|S|3|FUTURE|HIFIL
VB	VB	M|S|3|FUTURE|HITPAEL
VB	VB	M|S|3|FUTURE|HUFAL
VB	VB	M|S|3|FUTURE|NIFAL
VB	VB	M|S|3|FUTURE|PAAL
VB	VB	M|S|3|FUTURE|PIEL
VB	VB	M|S|3|FUTURE|PUAL
VB	VB	M|S|3|PAST
VB	VB	M|S|3|PAST|HIFIL
VB	VB	M|S|3|PAST|HITPAEL
VB	VB	M|S|3|PAST|HUFAL
VB	VB	M|S|3|PAST|NIFAL
VB	VB	M|S|3|PAST|PAAL
VB	VB	M|S|3|PAST|PIEL
VB	VB	M|S|3|PAST|PUAL
VB	VB	M|S|A|BEINONI|HIFIL
VB	VB	M|S|A|BEINONI|HITPAEL
VB	VB	M|S|A|BEINONI|HUFAL
VB	VB	M|S|A|BEINONI|NIFAL
VB	VB	M|S|A|BEINONI|PAAL
VB	VB	M|S|A|BEINONI|PIEL
VB	VB	M|S|A|BEINONI|PUAL
VB	VB	P|1|FUTURE|HIFIL
VB	VB	P|1|FUTURE|HITPAEL
VB	VB	P|1|FUTURE|HUFAL
VB	VB	P|1|FUTURE|NIFAL
VB	VB	P|1|FUTURE|PAAL
VB	VB	P|1|FUTURE|PIEL
VB	VB	P|1|PAST
VB	VB	P|1|PAST|HIFIL
VB	VB	P|1|PAST|HITPAEL
VB	VB	P|1|PAST|NIFAL
VB	VB	P|1|PAST|PAAL
VB	VB	P|1|PAST|PIEL
VB	VB	P|1|PAST|PUAL
VB	VB	P|2|FUTURE|HIFIL
VB	VB	P|2|FUTURE|PAAL
VB	VB	P|2|IMPERATIVE
VB	VB	P|2|IMPERATIVE|NIFAL
VB	VB	P|2|IMPERATIVE|PAAL
VB	VB	P|3|FUTURE
VB	VB	P|3|FUTURE|HIFIL
VB	VB	P|3|FUTURE|HITPAEL
VB	VB	P|3|FUTURE|HUFAL
VB	VB	P|3|FUTURE|NIFAL
VB	VB	P|3|FUTURE|PAAL
VB	VB	P|3|FUTURE|PIEL
VB	VB	P|3|FUTURE|PUAL
VB	VB	P|3|PAST
VB	VB	P|3|PAST|HIFIL
VB	VB	P|3|PAST|HITPAEL
VB	VB	P|3|PAST|HUFAL
VB	VB	P|3|PAST|NIFAL
VB	VB	P|3|PAST|PAAL
VB	VB	P|3|PAST|PIEL
VB	VB	P|3|PAST|PUAL
VB	VB	S|1|FUTURE|HIFIL
VB	VB	S|1|FUTURE|HITPAEL
VB	VB	S|1|FUTURE|NIFAL
VB	VB	S|1|FUTURE|PAAL
VB	VB	S|1|FUTURE|PIEL
VB	VB	S|1|FUTURE|PUAL
VB	VB	S|1|PAST|HIFIL
VB	VB	S|1|PAST|HITPAEL
VB	VB	S|1|PAST|HUFAL
VB	VB	S|1|PAST|NIFAL
VB	VB	S|1|PAST|PAAL
VB	VB	S|1|PAST|PIEL
VB	VB	S|1|PAST|PUAL
VB	VB-BAREINFINITIVE	_
VB	VB-TOINFINITIVE	HIFIL
VB	VB-TOINFINITIVE	HITPAEL
VB	VB-TOINFINITIVE	NIFAL
VB	VB-TOINFINITIVE	PAAL
VB	VB-TOINFINITIVE	PIEL
VB	VB-TOINFINITIVE	_
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

Lingua::Interset::Tagset::HE::Conll - Driver for the Hebrew tagset.

=head1 VERSION

version 3.011

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::HE::Conll;
  my $driver = Lingua::Interset::Tagset::HE::Conll->new();
  my $fs = $driver->decode("NN\tNN\tM|S");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('he::conll', "NN\tNN\tM|S");

=head1 DESCRIPTION

Interset driver for the Hebrew tagset in CoNLL format.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT.

Tagset described in Yoav Goldberg: Automatic Syntactic Processing of Modern
Hebrew Automatic Syntactic Processing of Modern Hebrew (2011), p. 32,
L<http://www.cs.bgu.ac.il/~nlpproj/yoav-phd.pdf>

TODO: try to use the official (but not as easy to process) resource:
BGU Computational Linguistics Group. Hebrew morphological tagging guidelines.
Technical report, Ben Gurion University of the Negev, 2008.
L<http://www.cs.bgu.ac.il/~adlerm/tagging-guideline.pdf>

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::Conll>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Rudolf Rosa <rosa@ufal.mff.cuni.cz>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
