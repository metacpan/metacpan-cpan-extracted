# ABSTRACT: Driver for the Turkish tagset of the CoNLL 2007 Shared Task (derived from the METU Sabanci Treebank).
# Copyright © 2011, 2013, 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Copyright © 2011 Loganathan Ramasamy <ramasamy@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::TR::Conll;
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
    return 'tr::conll';
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
            # Noun Noun A3sg|Pnon|Nom examples: şey (thing), gün (day), zaman (time), kadın (woman), yıl (year)
            'Noun Noun'      => ['pos' => 'noun', 'nountype' => 'com'],
            'Noun Prop'      => ['pos' => 'noun', 'nountype' => 'prop'],
            # Documentation: "A +Zero appears after a zero morpheme derivation."
            # So it does not seem as something one would necessarily want to preserve.
            'Noun Zero'      => ['pos' => 'noun', 'other' => {'zero' => 1}],
            'Noun NInf'      => ['pos' => 'noun', 'verbform' => 'inf'],
            'Noun NFutPart'  => ['pos' => 'noun', 'verbform' => 'part', 'tense' => 'fut'],
            'Noun NPresPart' => ['pos' => 'noun', 'verbform' => 'part', 'tense' => 'pres'],
            'Noun NPastPart' => ['pos' => 'noun', 'verbform' => 'part', 'tense' => 'past'],
            'Pron PersP'     => ['pos' => 'noun', 'prontype' => 'prs'],
            'Pron ReflexP'   => ['pos' => 'noun', 'prontype' => 'prs', 'reflex' => 'yes'],
            # "Pron Pron" contains a heterogenous group of pronouns. Reciprocal pronouns seem to constitute a large part of it.
            # Example: birbirimizi (each other)
            'Pron Pron'      => ['pos' => 'noun', 'prontype' => 'rcp'],
            'Pron DemonsP'   => ['pos' => 'noun', 'prontype' => 'dem'],
            'Pron QuesP'     => ['pos' => 'noun', 'prontype' => 'int'],
            'Adj Adj'        => ['pos' => 'adj'],
            'Adj Zero'       => ['pos' => 'adj', 'other' => {'zero' => 1}],
            'Adj AFutPart'   => ['pos' => 'adj', 'verbform' => 'part', 'tense' => 'fut'],
            'Adj APresPart'  => ['pos' => 'adj', 'verbform' => 'part', 'tense' => 'pres'],
            'Adj APastPart'  => ['pos' => 'adj', 'verbform' => 'part', 'tense' => 'past'],
            'Det Det'        => ['pos' => 'adj', 'prontype' => 'prn'],
            'Num Card'       => ['pos' => 'num', 'numtype' => 'card'],
            'Num Ord'        => ['pos' => 'adj', 'numtype' => 'ord'],
            'Num Distrib'    => ['pos' => 'num', 'numtype' => 'dist'],
            'Num Range'      => ['pos' => 'num', 'numtype' => 'range'],
            'Num Real'       => ['pos' => 'num', 'numform' => 'digit'],
            'Verb Verb'      => ['pos' => 'verb'],
            'Verb Zero'      => ['pos' => 'verb', 'other' => {'zero' => 1}],
            'Adv Adv'        => ['pos' => 'adv'],
            'Postp Postp'    => ['pos' => 'adp', 'adpostype' => 'post'],
            'Conj Conj'      => ['pos' => 'conj'],
            # Question particle "mi". It inflects for person, number and tense.
            'Ques Ques'      => ['pos' => 'part', 'prontype' => 'int'],
            # Documentation (https://wiki.ufal.ms.mff.cuni.cz/_media/user:zeman:treebanks:ttbankkl.pdf page 25):
            # +Dup category contains onomatopoeia words (zvukomalebná slova) which only appear as duplications in a sentence.
            # Some of them could be considered interjections, some others (or in some contexts) not.
            # Syntactically they may probably act as various parts of speech. Adjectives? Adverbs? Verbs? Nouns?
            # There are only about ten examples in the corpus.
            'Dup Dup'        => ['pos' => '', 'echo' => 'rdp'],
            'Interj Interj'  => ['pos' => 'int'],
            'Punc Punc'      => ['pos' => 'punc']
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'nountype' => { 'com'  => 'Noun Noun',
                                                   'prop' => 'Noun Prop',
                                                   '@'    => { 'prontype' => { 'dem' => 'Pron DemonsP',
                                                                               'int' => 'Pron QuesP',
                                                                               'prs' => { 'reflex' => { 'yes' => 'Pron ReflexP',
                                                                                                        '@'      => 'Pron PersP' }},
                                                                               ''    => { 'verbform' => { 'part' => { 'tense' => { 'fut'  => 'Noun NFutPart',
                                                                                                                                   'pres' => 'Noun NPresPart',
                                                                                                                                   '@'    => 'Noun NPastPart' }},
                                                                                                          'inf'  => 'Noun NInf',
                                                                                                          '@'    => { 'other/zero' => { '1' => 'Noun Zero',
                                                                                                                                        '@' => 'Noun Noun' }}}},
                                                                               '@'   => 'Pron Pron' }}}},
                       'adj'  => { 'numtype' => { 'ord' => 'Num Ord',
                                                  '@'   => { 'prontype' => { ''  => { 'verbform' => { 'part' => { 'tense' => { 'fut'  => 'Adj AFutPart',
                                                                                                                               'pres' => 'Adj APresPart',
                                                                                                                               '@'    => 'Adj APastPart' }},
                                                                                                      '@'    => { 'other/zero' => { '1' => 'Adj Zero',
                                                                                                                                    '@' => 'Adj Adj' }}}},
                                                                             '@' => 'Det Det' }}}},
                       'num'  => { 'numtype' => { 'ord'   => 'Num Ord',
                                                  'dist'  => 'Num Distrib',
                                                  'range' => 'Num Range',
                                                  '@'     => { 'numform' => { 'digit' => 'Num Real',
                                                                              '@'     => 'Num Card' }}}},
                       'verb' => { 'other/zero' => { '1' => 'Verb Zero',
                                                     '@' => 'Verb Verb' }},
                       'adv'  => 'Adv Adv',
                       'adp'  => 'Postp Postp',
                       'conj' => 'Conj Conj',
                       'part' => 'Ques Ques',
                       'int'  => 'Interj Interj',
                       'punc' => 'Punc Punc',
                       'sym'  => 'Punc Punc',
                       '@'    => 'Dup Dup' }
        }
    );
    # GENDER ####################
    $atoms{gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'Ma' => 'masc',
            'Fe' => 'fem',
            'Ne' => 'neut'
        }
    );
    # AGREEMENT ####################
    $atoms{agreement} = $self->create_atom
    (
        'surfeature' => 'agreement',
        'decode_map' =>
        {
            'A1sg' => ['person' => '1', 'number' => 'sing'],
            'A1pl' => ['person' => '1', 'number' => 'plur'],
            'A2sg' => ['person' => '2', 'number' => 'sing'],
            'A2pl' => ['person' => '2', 'number' => 'plur'],
            'A3sg' => ['person' => '3', 'number' => 'sing'],
            'A3pl' => ['person' => '3', 'number' => 'plur']
        },
        'encode_map' =>
        {
            'number' => { 'sing' => { 'person' => { '1' => 'A1sg',
                                                    '2' => 'A2sg',
                                                    '3' => 'A3sg' }},
                          'plur' => { 'person' => { '1' => 'A1pl',
                                                    '2' => 'A2pl',
                                                    '3' => 'A3pl' }}}
        }
    );
    # POSSESSIVE AGREEMENT ####################
    $atoms{possagreement} = $self->create_atom
    (
        'surfeature' => 'possagreement',
        'decode_map' =>
        {
            'P1sg' => ['possperson' => '1', 'possnumber' => 'sing'],
            'P1pl' => ['possperson' => '1', 'possnumber' => 'plur'],
            'P2sg' => ['possperson' => '2', 'possnumber' => 'sing'],
            'P2pl' => ['possperson' => '2', 'possnumber' => 'plur'],
            'P3sg' => ['possperson' => '3', 'possnumber' => 'sing'],
            'P3pl' => ['possperson' => '3', 'possnumber' => 'plur'],
            'Pnon' => [] # no overt agreement
        },
        'encode_map' =>
        {
            'possnumber' => { 'sing' => { 'possperson' => { '1' => 'P1sg',
                                                            '2' => 'P2sg',
                                                            '3' => 'P3sg' }},
                              'plur' => { 'possperson' => { '1' => 'P1pl',
                                                            '2' => 'P2pl',
                                                            '3' => 'P3pl' }},
                              '@'    => 'Pnon' }
        }
    );
    # CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'Nom' => 'nom',
            'Gen' => 'gen',
            'Acc' => 'acc',
            'Abl' => 'abl',
            'Dat' => 'dat',
            'Loc' => 'loc',
            'Ins' => 'ins',
            # There is also the 'Equ' feature. It seems to appear in place of case but it is not documented.
            # And descriptions of Turkish grammar that I have seen do not list other cases than the above.
            # Nevertheless, until further notice, I am going to use another case value to store the feature.
            'Equ' => 'com'
        }
    );
    # PC (???) CASE ####################
    # This feature is used with postpositions. Is it their valency case?
    $atoms{pccase} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'PCNom' => 'nom',
            'PCGen' => 'gen',
            'PCAcc' => 'acc',
            'PCAbl' => 'abl',
            'PCDat' => 'dat',
            'PCLoc' => 'loc',
            'PCIns' => 'ins'
        }
    );
    # DEGREE OF COMPARISON ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'Cp' => 'cmp',
            'Su' => 'sup'
        }
    );
    # ADJECTIVE OR ADVERB TYPE ####################
    # We have to join these two features (adjtype and advtype) because they overlap in the AsIf value.
    # They never occur together, thus there is no harm in joining them.
    # The non-"_" non-Ly non-Since adverbs seem to be derived from verbs, i.e. they could be called adverbial participles (transgressives).
    $atoms{adjvtype} = $self->create_atom
    (
        'surfeature' => 'adjvtype',
        'decode_map' =>
        {
            # Adj Adj _ examples: büyük (big), yeni (new), iyi (good), aynı (same), çok (many)
            # Adj Adj Agt examples: üretici (manufacturing), ürkütücü (scary), rahatlatıcı (relaxing), yakıcı (burning), barışçı (pacific)
            'Agt'       => ['other' => {'adjvtype' => 'agt'}],
            # Adj Adj AsIf examples: böylece (so that), onca (all that), delice (insane), aptalca (stupid), çılgınca (wild)
            # Adv Adv AsIf examples: güneşiymişçesine, okumuşçasına (as if reads), etmişçesine, taparcasına (as if worships), okşarcasına (as if strokes)
            'AsIf'      => ['other' => {'adjvtype' => 'asif'}], # 'verbform' => 'trans' for the Adv cases? ###!!!
            # Adj Adj FitFor examples: dolarlık (in dollars), yıllık (annual), saatlik (hourly), trilyonluk (trillions worth), liralık (in pounds)
            'FitFor'    => ['other' => {'adjvtype' => 'fitfor'}],
            # Adj Adj InBetween example: uluslararası (international)
            'InBetween' => ['other' => {'adjvtype' => 'inbetween'}],
            # Adj Adj JustLike example: konyakımsı (just like brandy), redingotumsu (just like redingot)
            'JustLike'  => ['other' => {'adjvtype' => 'justlike'}],
            # Adj Adj Rel examples: önceki (previous), arasındaki (in-between), içindeki (intra-), üzerindeki (upper), öteki (other)
            'Rel'       => ['other' => {'adjvtype' => 'rel'}],
            # Adj Adj Related examples: ideolojik (ideological), teknolojik (technological), meteorolojik (meteorological), bilimsel (scientific), psikolojik (psychological)
            'Related'   => ['other' => {'adjvtype' => 'related'}],
            # Adj Adj With examples: önemli (important), ilgili (related), vadeli (forward), yaşlı (elderly), yararlı (helpful)
            'With'      => ['other' => {'adjvtype' => 'with'}],
            # Adj Adj Without examples: sessiz (quiet), savunmasız (vulnerable), anlamsız (meaningless), gereksiz (unnecessary), rahatsız (uncomfortable)
            'Without'   => ['other' => {'adjvtype' => 'without'}],
            # Adv Adv _ examples: daha (more), çok (very), en (most), bile (even), hiç (never)
            # Adv Adv Ly examples: hafifçe (slightly), rahatça (easily), iyice (thoroughly), öylece (just), aptalca (stupidly)
            'Ly'                  => ['other' => {'adjvtype' => 'ly'}],
            # Adv Adv Since examples: yıldır (for years), yıllardır (for years), saattir (for hours)
            'Since'               => ['other' => {'adjvtype' => 'since'}],
            # Adv Adv AfterDoingSo examples: gidip (having gone), gelip (having come), deyip (having said), kesip (having cut out), çıkıp (having gotten out)
            'AfterDoingSo'        => ['other' => {'adjvtype' => 'afterdoingso'}, 'verbform' => 'trans'],
            # Adv Adv As examples: istemedikçe (unless you want to), arttıkça (as increases), konuştukça (as you talk), oldukça (rather), gördükçe (as you see)
            'As'                  => ['other' => {'adjvtype' => 'as'}, 'verbform' => 'trans'],
            # Adv Adv ByDoingSo examples: olarak (by being), diyerek (by saying), belirterek (by specifying), koşarak (by running), çekerek (by pulling)
            'ByDoingSo'           => ['other' => {'adjvtype' => 'bydoingso'}, 'verbform' => 'trans'],
            # Adv Adv SinceDoingSo examples: olalı (since being), geleli (since coming), dönüşeli (since returning), başlayalı (since starting), kapılalı
            'SinceDoingSo'        => ['other' => {'adjvtype' => 'sincedoingso'}, 'verbform' => 'trans'],
            # Adv Adv When examples: görünce (when/on seeing), deyince (when we say), olunca (when), açılınca (when opening), gelince (when coming)
            'When'                => ['other' => {'adjvtype' => 'when'}, 'verbform' => 'trans'],
            # Adv Adv While examples: giderken (en route), konuşurken (while talking), derken (while saying), çıkarken (on the way out), varken (when there is)
            'While'               => ['other' => {'adjvtype' => 'while'}, 'verbform' => 'trans'],
            # Adv Adv WithoutHavingDoneSo examples: olmadan (without being), düşünmeden (without thinking), geçirmeden (without passing), çıkarmadan (without removing), almadan (without taking)
            'WithoutHavingDoneSo' => ['other' => {'adjvtype' => 'withouthavingdoneso'}, 'verbform' => 'trans'],
            # Additional categories apply to nouns:
            'Dim'  => ['other' => {'adjvtype' => 'dim'}],
            'Inf2' => ['other' => {'adjvtype' => 'inf2'}],
            'Inf3' => ['other' => {'adjvtype' => 'inf3'}],
            'Ness' => ['other' => {'adjvtype' => 'ness'}]
        },
        'encode_map' =>
        {
            'other/adjvtype' => { 'agt'       => 'Agt',
                                  'asif'      => 'AsIf',
                                  'fitfor'    => 'FitFor',
                                  'inbetween' => 'InBetween',
                                  'justlike'  => 'JustLike',
                                  'rel'       => 'Rel',
                                  'related'   => 'Related',
                                  'with'      => 'With',
                                  'without'   => 'Without',
                                  'ly'                  => 'Ly',
                                  'since'               => 'Since',
                                  'afterdoingso'        => 'AfterDoingSo',
                                  'as'                  => 'As',
                                  #'asif'                => 'AsIf',
                                  'bydoingso'           => 'ByDoingSo',
                                  'sincedoingso'        => 'SinceDoingSo',
                                  'when'                => 'When',
                                  'while'               => 'While',
                                  'withouthavingdoneso' => 'WithoutHavingDoneSo',
                                  'dim'  => 'Dim',
                                  'inf2' => 'Inf2',
                                  'inf3' => 'Inf3',
                                  'ness' => 'Ness' }
        }
    );
    # COMPOUNDING AND MODALITY ####################
    # These features apply to verbs. Only 3 features actually occur in the corpus: Able, Hastily and Stay.
    # (The features are explained below on the English verb "to do"; Turkish examples are not translations of "to do"!)
    # +Able ... able to do ... examples: olabilirim, olabilirsin, olabilir ... bunu demis olabilirim = I may have said (demis = said)
    # +Repeat ... do repeatedly ... no occurrence
    # +Hastily ... do hastily ... examples: aliverdi, doluverdi, gidiverdi
    # +EverSince ... have been doing ever since ... no occurrence
    # +Almost ... almost did but did not ... no occurrence
    # +Stay ... stayed frozen whlie doing ... just two examples: şaşakalmıştık, uyuyakalmıştı (Google translates the latter as "fallen asleep")
    # +Start ... start doing immediately ... no occurrence
    $atoms{comod} = $self->create_atom
    (
        'surfeature' => 'comod',
        'decode_map' =>
        {
            'Able'      => ['other' => {'comod' => 'able'}],
            'Repeat'    => ['other' => {'comod' => 'repeat'}],
            'Hastily'   => ['other' => {'comod' => 'hastily'}],
            'EverSince' => ['other' => {'comod' => 'eversince'}],
            'Almost'    => ['other' => {'comod' => 'almost'}],
            'Stay'      => ['other' => {'comod' => 'stay'}],
            'Start'     => ['other' => {'comod' => 'start'}],
            # Verbs derived from nouns or adjectives:
            # to acquire the noun
            'Acquire'   => ['other' => {'comod' => 'acquire'}],
            # to become the noun
            'Become'    => ['other' => {'comod' => 'become'}]
        },
        'encode_map' =>
        {
            'other/comod' => { 'able'      => 'Able',
                               'repeat'    => 'Repeat',
                               'hastily'   => 'Hastily',
                               'eversince' => 'EverSince',
                               'almost'    => 'Almost',
                               'stay'      => 'Stay',
                               'start'     => 'Start',
                               'acquire'   => 'Acquire',
                               'become'    => 'Become' }
        }
    );
    # TENSE ####################
    # Two (but not more) tenses may be combined together.
    # We have to preprocess the tags so that two tense features appear as one, e.g. "Fut|Past" becomse "FutPast".
    $atoms{tense} = $self->create_atom
    (
        'surfeature' => 'tense',
        'decode_map' =>
        {
            # The "Pres" tag is not frequent.
            # It occurs with "Verb Zero" more often than with "Verb Verb". It often occurs with copulae ("Cop").
            # According to documentation, it is intended for predicative nominals or adjectives.
            # Pres|Cop|A3sg examples: vardır (there are), yoktur (there is no), demektir (means), sebzedir, nedir (what is the)
            'Pres'     => ['tense' => 'pres'],
            # The "Fut" tag can be combined with "Past" and occasionally with "Narr".
            # Pos|Fut|A3sg examples: olacak (will), verecek (will give), gelecek, sağlayacak, yapacak
            # Pos|Fut|Past|A3sg examples: olacaktı (would), öğrenecekti (would learn), yapacaktı (would make), ölecekti, sokacaktı
            'Fut'      => ['tense' => 'fut'],
            'FutPast'  => ['tense' => 'fut|past'],
            'FutNarr'  => ['tense' => 'fut', 'evident' => 'nfh'],
            # Pos|Past|A3sg examples: dedi (said), oldu (was), söyledi (said), geldi (came), sordu (asked)
            # Pos|Prog1|Past|A3sg examples: geliyordu (was coming), oturuyordu (was sitting), bakıyordu, oluyordu, titriyordu
            'Past'     => ['tense' => 'past'],
            # Pos|Narr|A3sg examples: olmuş (was), demiş (said), bayılmış (fainted), gelmiş (came), çıkmış (emerged)
            # Pos|Narr|Past|A3sg examples: başlamıştı (started), demişti (said), gelmişti (was), geçmişti (passed), kalkmıştı (sailed)
            # Pos|Prog1|Narr|A3sg examples: oluyormuş (was happening), bakıyormuş (was staring), çırpınıyormuş, yaşıyormuş, istiyormuş
            # enwiki:
            # The definite past or di-past is used to assert that something did happen in the past.
            # The inferential past or miş-past can be understood as asserting that a past participle is applicable now;
            # hence it is used when the fact of a past event, as such, is not important;
            # in particular, the inferential past is used when one did not actually witness the past event.
            # A newspaper will generally use the di-past, because it is authoritative.
            'Narr'     => ['tense' => 'past', 'evident' => 'nfh'],
            'NarrPast' => ['tense' => 'past', 'evident' => 'fh|nfh'],
            # Pos|Aor|A3sg examples: olur (will), gerekir (must), yeter (is enough), alır (takes), gelir (income)
            # Pos|Aor|Narr|A3sg examples: olurmuş (bustled), inanırmış, severmiş (loved), yaşarmış (lived), bitermiş
            # Pos|Aor|Past|A3sg examples: olurdu (would), otururdu (sat), yapardı (would), bilirdi (knew), derdi (used to say)
            # enwiki:
            # In Turkish the aorist is a habitual aspect. (Geoffrey Lewis, Turkish Grammar (2nd ed, 2000, Oxford))
            # So it is not a tense (unlike e.g. Bulgarian aorist) and it can be combined with tenses.
            # Habitual aspect means repetitive actions (they take place "usually"). It is a type of imperfective aspect.
            # English has habitual past: "I used to visit him frequently."
            'Aor'      => ['tense' => 'aor'],
            'AorPast'  => ['tense' => 'aor|past'],
            'AorNarr'  => ['tense' => 'aor', 'evident' => 'nfh']
        },
        'encode_map' =>
        {
            'tense' => { 'aor'       => { 'evident' => { 'nfh' => 'AorNarr',
                                                         '@'   => 'Aor' }},
                         'aor|past'  => 'AorPast',
                         'fut'       => { 'evident' => { 'nfh' => 'FutNarr',
                                                         '@'   => 'Fut' }},
                         'fut|past'  => 'FutPast',
                         'past'      => { 'evident' => { 'fh|nfh' => 'NarrPast',
                                                         'nfh'    => 'Narr',
                                                         '@'      => 'Past' }},
                         'pres'      => 'Pres' }
        }
    );
    # ASPECT ####################
    $atoms{aspect} = $self->create_atom
    (
        'surfeature' => 'aspect',
        'decode_map' =>
        {
            # Documentation calls the following two tenses "present continuous".
            # Prog1 = "present continuous, process"
            # Prog2 = "present continuous, state"
            # However, there are also combinations with past tags, e.g. "Prog1|Past".
            # Pos|Prog1|A3sg examples: diyor (is saying), geliyor (is coming), oluyor (is being), yapıyor (is doing), biliyor (is knowing)
            # Pos|Prog1|Past|A3sg examples: geliyordu (was coming), oturuyordu (was sitting), bakıyordu, oluyordu, titriyordu
            # Pos|Prog1|Narr|A3sg examples: oluyormuş (was happening), bakıyormuş (was staring), çırpınıyormuş, yaşıyormuş, istiyormuş
            # Pos|Prog2|A3sg examples: oturmakta (is sitting), kapamakta (is closing), soymakta (is peeling), kullanmakta, taşımakta
            'Prog1' => ['aspect' => 'prog'],
            'Prog2' => ['aspect' => 'prog', 'variant' => '2']
        },
        'encode_map' =>
        {
            'aspect' => { 'prog' => { 'variant' => { '2' => 'Prog2',
                                                     '@' => 'Prog1' }}}
        }
    );
    # MOOD ####################
    # mood: wish-must case (dilek-şart kipi)
    $atoms{mood} = $self->create_simple_atom
    (
        'intfeature' => 'mood',
        'simple_decode_map' =>
        {
            # Pos|Imp|A2sg examples: var (be), gerek (need), bak (look), kapa (expand), anlat (tell)
            'Imp'   => 'imp',
            # Pos|Neces|A3sg examples: olmalı (should be), almalı (should buy), sağlamalı (should provide), kapsamalı (should cover)
            'Neces' => 'nec',
            # Optative mood (indicates a wish or hope). "May you have a long life! If only I were rich!"
            # Oflazer: "Let me/him/her do..." / "Kéž by ..."
            # Pos|Opt|A3sg examples: diye (if only said), sevine (if only exulted), güle (if only laughed), ola (if only were), otura (if only sat)
            'Opt'   => 'opt',
            ###!!! What's the difference between Desr and Cond?
            # Pos|Desr|A3sg examples: olsa (wants to be), ise, varsa, istese (if wanted), bıraksa (wants to leave)
            'Desr'  => 'des',
            # Pos|Aor|Cond|A3sg examples: verirse (if), isterse, kalırsa (if remains), başlarsa (if begins), derse
            # Pos|Fut|Cond|A3sg example: olacaksa (if will)
            # Pos|Narr|Cond|A3sg example: oturmuşsa
            # Pos|Past|Cond|A3sg example: olduysa (if (would have been)), uyuduysa
            # Pos|Prog1|Cond|A3sg examples: geliyorsa (would be coming), öpüyorsa, uyuşuyorsa, seviyorsa (would be loving)
            'Cond'  => 'cnd'
        }
    );
    # POLARITY ####################
    $atoms{polarity} = $self->create_simple_atom
    (
        'intfeature' => 'polarity',
        'simple_decode_map' =>
        {
            # Pos|Prog1|A3sg examples: diyor (is saying), geliyor (is coming), oluyor (is being), yapıyor (is doing), biliyor (is knowing)
            'Pos' => 'pos',
            # Neg|Prog1|A3sg examples: olmuyor (is not), tutmuyor (does not match), bilmiyor (does not know), gerekmiyor, benzemiyor
            'Neg' => 'neg'
        }
    );
    # VOICE ####################
    $atoms{voice} = $self->create_atom
    (
        'surfeature' => 'voice',
        'decode_map' =>
        {
            # Pass|Pos|Past|A3sg examples: belirtildi (was said), söylendi (was told), istendi (was asked), öğrenildi (was learned), kaldırıldı
            'Pass'   => ['voice' => 'pass'],
            # Reflex|Pos|Prog1|A3sg example: hazırlanıyor (is preparing itself)
            'Reflex' => ['reflex' => 'yes'],
            # Recip|Pos|Past|A3sg example: karıştı (confused each other?)
            'Recip'  => ['voice' => 'rcp'],
            # Caus ... causative
            # Oflazer's documentation classifies this as a value of the voice feature.
            # Caus|Pos|Narr|A3sg examples: bastırmış (suppressed), bitirmiş (completed), oluşturmuş (created), çoğaltmış (multiplied), çıkartmış (issued)
            # Caus|Pos|Past|A3sg examples: belirtti (said), bildirdi (reported), uzattı (extended), indirdi (reduced), sürdürdü (continued)
            # Caus|Pos|Prog1|A3sg examples: karıştırıyor (is confusing), korkutuyor (is scaring), geçiriyor (is taking), koparıyor (is breaking), döktürüyor
            # Caus|Pos|Prog1|Past|A3sg examples: karıştırıyordu (was scooping), geçiriyordu (was giving), dolduruyordu (was filling), sürdürüyordu (was continuing), azaltıyordu (was diminishing)
            'Caus'   => ['voice' => 'cau']
        },
        'encode_map' =>
        {
            'voice' => { 'pass' => 'Pass',
                         'rcp'  => 'Recip',
                         'cau'  => 'Caus',
                         '@'    => { 'reflex' => { 'yes' => 'Reflex' }}}
        }
    );
    # COPULA ####################
    # Copula in Turkish is not an independent word. It is a bound morpheme (tur/tır/tir/dur etc.)
    # It is not clear to me though, what meaning it adds when attached to a verb.
    $atoms{copula} = $self->create_simple_atom
    (
        'intfeature' => 'verbtype',
        'simple_decode_map' =>
        {
            # Pos|Narr|Cop|A3sg examples: olmuştur (has been), açmıştır (has led), ulaşmıştır (has reached), başlamıştır, gelmiştir
            # Pos|Prog1|Cop|A3sg examples: oturuyordur (is sitting), öpüyordur (is kissing), tanıyordur (knows)
            # Pos|Fut|Cop|A3sg examples: olacaktır (will), akacaktır (will flow), alacaktır (will take), çarpacaktır, görecektir
            'Cop' => 'cop'
        }
    );
    # MERGED ATOM TO DECODE ANY FEATURE VALUE ####################
    my @fatoms = map {$atoms{$_}} (@{$self->features_all()});
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
    my @features = ('pos', 'gender', 'agreement', 'possagreement', 'case', 'pccase', 'degree', 'adjvtype', 'tense', 'aspect', 'comod', 'mood', 'polarity', 'voice', 'copula');
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
        'Adj Adj'        => ['adjvtype'],
        'Adj AFutPart'   => ['possagreement'],
        'Adj APastPart'  => ['possagreement'],
        'Adv Adv'        => ['adjvtype'],
        'Noun NFutPart'  => ['agreement', 'possagreement', 'case'],
        'Noun NInf'      => ['agreement', 'possagreement', 'case'],
        'Noun Noun'      => ['adjvtype', 'agreement', 'possagreement', 'case'],
        'Noun NPastPart' => ['agreement', 'possagreement', 'case'],
        'Noun NPresPart' => ['agreement', 'possagreement', 'case'],
        'Noun Prop'      => ['agreement', 'possagreement', 'case'],
        'Noun Zero'      => ['agreement', 'possagreement', 'case'],
        'Postp Postp'    => ['pccase'],
        'Pron DemonsP'   => ['agreement', 'possagreement', 'case'],
        'Pron PersP'     => ['agreement', 'possagreement', 'case'],
        'Pron Pron'      => ['agreement', 'possagreement', 'case'],
        'Pron QuesP'     => ['agreement', 'possagreement', 'case'],
        'Pron ReflexP'   => ['agreement', 'possagreement', 'case'],
        'Ques Ques'      => ['tense', 'copula', 'agreement'],
        'Verb Verb'      => ['comod', 'voice', 'polarity', 'mood', 'aspect', 'tense', 'copula', 'agreement'],
        'Verb Zero'      => ['polarity', 'mood', 'tense', 'copula', 'agreement']
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
    # Preprocess the tag. There may be up to two different tense features.
    # If there are two tense features, we want to merge them so that they are later processed together.
    $tag =~ s/(Aor|Fut|Narr)\|(Past|Narr)/$1$2/;
    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset('tr::conll');
    my $atoms = $self->atoms();
    # Three components: pos, subpos, features.
    # example: Noun\tNoun\tA3sg|Pnon|Nom
    my ($pos, $subpos, $features) = split(/\s+/, $tag);
    # The underscore character is used if there are no features.
    $features = '' if($features eq '_');
    my @features = split(/\|/, $features);
    $atoms->{pos}->decode_and_merge_hard("$pos $subpos", $fs);
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
    my $possubpos = $atoms->{pos}->encode($fs);
    my ($pos, $subpos) = split(/\s+/, $possubpos);
    my $fpos = $possubpos;
    my $feature_names = $self->get_feature_names($fpos);
    my $value_only = 1;
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names, $value_only);
    # Postprocess the tag. There may be up to two different tense features.
    # If there are two tense features, we have merged them and processed together, but now we have to split them again.
    $tag =~ s/(Aor|Fut|Narr)(Past|Narr)/$1|$2/;
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus, 1061 distinct tags found.
# One erroneous tag removed, permutations normalized, 1058 tags survived.
# Added tags generated when 'other' is not available: 1112 tags total.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
Adj	AFutPart	P1pl
Adj	AFutPart	P1sg
Adj	AFutPart	P3pl
Adj	AFutPart	P3sg
Adj	AFutPart	Pnon
Adj	APastPart	P1pl
Adj	APastPart	P1sg
Adj	APastPart	P2pl
Adj	APastPart	P2sg
Adj	APastPart	P3pl
Adj	APastPart	P3sg
Adj	APastPart	Pnon
Adj	APresPart	_
Adj	Adj	Agt
Adj	Adj	AsIf
Adj	Adj	FitFor
Adj	Adj	InBetween
Adj	Adj	JustLike
Adj	Adj	Rel
Adj	Adj	Related
Adj	Adj	With
Adj	Adj	Without
Adj	Adj	_
Adj	Zero	_
Adv	Adv	AfterDoingSo
Adv	Adv	As
Adv	Adv	AsIf
Adv	Adv	ByDoingSo
Adv	Adv	Ly
Adv	Adv	Since
Adv	Adv	SinceDoingSo
Adv	Adv	When
Adv	Adv	While
Adv	Adv	WithoutHavingDoneSo
Adv	Adv	_
Conj	Conj	_
Det	Det	_
Dup	Dup	_
Interj	Interj	_
Noun	NFutPart	A3pl|P1sg|Nom
Noun	NFutPart	A3pl|P3pl|Acc
Noun	NFutPart	A3pl|P3pl|Dat
Noun	NFutPart	A3pl|P3pl|Nom
Noun	NFutPart	A3pl|P3sg|Acc
Noun	NFutPart	A3pl|P3sg|Nom
Noun	NFutPart	A3pl|Pnon|Acc
Noun	NFutPart	A3pl|Pnon|Gen
Noun	NFutPart	A3pl|Pnon|Nom
Noun	NFutPart	A3sg|P1pl|Abl
Noun	NFutPart	A3sg|P1pl|Acc
Noun	NFutPart	A3sg|P1pl|Dat
Noun	NFutPart	A3sg|P1pl|Nom
Noun	NFutPart	A3sg|P1sg|Acc
Noun	NFutPart	A3sg|P1sg|Dat
Noun	NFutPart	A3sg|P1sg|Nom
Noun	NFutPart	A3sg|P2pl|Dat
Noun	NFutPart	A3sg|P2sg|Abl
Noun	NFutPart	A3sg|P2sg|Acc
Noun	NFutPart	A3sg|P2sg|Nom
Noun	NFutPart	A3sg|P3pl|Abl
Noun	NFutPart	A3sg|P3pl|Acc
Noun	NFutPart	A3sg|P3pl|Nom
Noun	NFutPart	A3sg|P3sg|Abl
Noun	NFutPart	A3sg|P3sg|Acc
Noun	NFutPart	A3sg|P3sg|Dat
Noun	NFutPart	A3sg|P3sg|Gen
Noun	NFutPart	A3sg|P3sg|Nom
Noun	NInf	A3pl|P1sg|Dat
Noun	NInf	A3pl|P1sg|Loc
Noun	NInf	A3pl|P1sg|Nom
Noun	NInf	A3pl|P3pl|Acc
Noun	NInf	A3pl|P3pl|Dat
Noun	NInf	A3pl|P3pl|Ins
Noun	NInf	A3pl|P3pl|Nom
Noun	NInf	A3pl|P3sg|Abl
Noun	NInf	A3pl|P3sg|Acc
Noun	NInf	A3pl|P3sg|Dat
Noun	NInf	A3pl|P3sg|Gen
Noun	NInf	A3pl|P3sg|Ins
Noun	NInf	A3pl|P3sg|Loc
Noun	NInf	A3pl|P3sg|Nom
Noun	NInf	A3pl|Pnon|Abl
Noun	NInf	A3pl|Pnon|Acc
Noun	NInf	A3pl|Pnon|Dat
Noun	NInf	A3pl|Pnon|Gen
Noun	NInf	A3pl|Pnon|Ins
Noun	NInf	A3pl|Pnon|Loc
Noun	NInf	A3pl|Pnon|Nom
Noun	NInf	A3sg|P1pl|Abl
Noun	NInf	A3sg|P1pl|Acc
Noun	NInf	A3sg|P1pl|Loc
Noun	NInf	A3sg|P1pl|Nom
Noun	NInf	A3sg|P1sg|Abl
Noun	NInf	A3sg|P1sg|Acc
Noun	NInf	A3sg|P1sg|Dat
Noun	NInf	A3sg|P1sg|Gen
Noun	NInf	A3sg|P1sg|Nom
Noun	NInf	A3sg|P2pl|Acc
Noun	NInf	A3sg|P2pl|Dat
Noun	NInf	A3sg|P2pl|Nom
Noun	NInf	A3sg|P2sg|Acc
Noun	NInf	A3sg|P2sg|Nom
Noun	NInf	A3sg|P3pl|Dat
Noun	NInf	A3sg|P3pl|Gen
Noun	NInf	A3sg|P3pl|Ins
Noun	NInf	A3sg|P3pl|Nom
Noun	NInf	A3sg|P3sg|Abl
Noun	NInf	A3sg|P3sg|Acc
Noun	NInf	A3sg|P3sg|Dat
Noun	NInf	A3sg|P3sg|Gen
Noun	NInf	A3sg|P3sg|Ins
Noun	NInf	A3sg|P3sg|Loc
Noun	NInf	A3sg|P3sg|Nom
Noun	NInf	A3sg|Pnon|Abl
Noun	NInf	A3sg|Pnon|Acc
Noun	NInf	A3sg|Pnon|Dat
Noun	NInf	A3sg|Pnon|Gen
Noun	NInf	A3sg|Pnon|Ins
Noun	NInf	A3sg|Pnon|Loc
Noun	NInf	A3sg|Pnon|Nom
Noun	NPastPart	A3pl|P1sg|Abl
Noun	NPastPart	A3pl|P1sg|Acc
Noun	NPastPart	A3pl|P1sg|Dat
Noun	NPastPart	A3pl|P1sg|Gen
Noun	NPastPart	A3pl|P1sg|Ins
Noun	NPastPart	A3pl|P1sg|Loc
Noun	NPastPart	A3pl|P1sg|Nom
Noun	NPastPart	A3pl|P2pl|Acc
Noun	NPastPart	A3pl|P2pl|Ins
Noun	NPastPart	A3pl|P2pl|Nom
Noun	NPastPart	A3pl|P2sg|Acc
Noun	NPastPart	A3pl|P3pl|Abl
Noun	NPastPart	A3pl|P3pl|Acc
Noun	NPastPart	A3pl|P3pl|Dat
Noun	NPastPart	A3pl|P3pl|Loc
Noun	NPastPart	A3pl|P3pl|Nom
Noun	NPastPart	A3pl|P3sg|Abl
Noun	NPastPart	A3pl|P3sg|Acc
Noun	NPastPart	A3pl|P3sg|Dat
Noun	NPastPart	A3pl|P3sg|Loc
Noun	NPastPart	A3pl|P3sg|Nom
Noun	NPastPart	A3pl|Pnon|Acc
Noun	NPastPart	A3sg|P1pl|Acc
Noun	NPastPart	A3sg|P1pl|Loc
Noun	NPastPart	A3sg|P1pl|Nom
Noun	NPastPart	A3sg|P1sg|Abl
Noun	NPastPart	A3sg|P1sg|Acc
Noun	NPastPart	A3sg|P1sg|Dat
Noun	NPastPart	A3sg|P1sg|Gen
Noun	NPastPart	A3sg|P1sg|Loc
Noun	NPastPart	A3sg|P1sg|Nom
Noun	NPastPart	A3sg|P2pl|Abl
Noun	NPastPart	A3sg|P2pl|Acc
Noun	NPastPart	A3sg|P2pl|Loc
Noun	NPastPart	A3sg|P2pl|Nom
Noun	NPastPart	A3sg|P2sg|Abl
Noun	NPastPart	A3sg|P2sg|Loc
Noun	NPastPart	A3sg|P2sg|Nom
Noun	NPastPart	A3sg|P3pl|Acc
Noun	NPastPart	A3sg|P3pl|Dat
Noun	NPastPart	A3sg|P3pl|Loc
Noun	NPastPart	A3sg|P3pl|Nom
Noun	NPastPart	A3sg|P3sg|Abl
Noun	NPastPart	A3sg|P3sg|Acc
Noun	NPastPart	A3sg|P3sg|Dat
Noun	NPastPart	A3sg|P3sg|Equ
Noun	NPastPart	A3sg|P3sg|Gen
Noun	NPastPart	A3sg|P3sg|Loc
Noun	NPastPart	A3sg|P3sg|Nom
Noun	NPastPart	A3sg|Pnon|Abl
Noun	NPresPart	A3sg|P3sg|Nom
Noun	Noun	A1pl|P3sg|Nom
Noun	Noun	A3pl|P1pl|Abl
Noun	Noun	A3pl|P1pl|Acc
Noun	Noun	A3pl|P1pl|Dat
Noun	Noun	A3pl|P1pl|Gen
Noun	Noun	A3pl|P1pl|Ins
Noun	Noun	A3pl|P1pl|Loc
Noun	Noun	A3pl|P1pl|Nom
Noun	Noun	A3pl|P1sg|Abl
Noun	Noun	A3pl|P1sg|Acc
Noun	Noun	A3pl|P1sg|Dat
Noun	Noun	A3pl|P1sg|Gen
Noun	Noun	A3pl|P1sg|Ins
Noun	Noun	A3pl|P1sg|Loc
Noun	Noun	A3pl|P1sg|Nom
Noun	Noun	A3pl|P2pl|Abl
Noun	Noun	A3pl|P2pl|Acc
Noun	Noun	A3pl|P2pl|Dat
Noun	Noun	A3pl|P2pl|Gen
Noun	Noun	A3pl|P2pl|Loc
Noun	Noun	A3pl|P2pl|Nom
Noun	Noun	A3pl|P2sg|Abl
Noun	Noun	A3pl|P2sg|Acc
Noun	Noun	A3pl|P2sg|Dat
Noun	Noun	A3pl|P2sg|Equ
Noun	Noun	A3pl|P2sg|Gen
Noun	Noun	A3pl|P2sg|Ins
Noun	Noun	A3pl|P2sg|Nom
Noun	Noun	A3pl|P3pl|Abl
Noun	Noun	A3pl|P3pl|Acc
Noun	Noun	A3pl|P3pl|Dat
Noun	Noun	A3pl|P3pl|Gen
Noun	Noun	A3pl|P3pl|Ins
Noun	Noun	A3pl|P3pl|Loc
Noun	Noun	A3pl|P3pl|Nom
Noun	Noun	A3pl|P3sg|Abl
Noun	Noun	A3pl|P3sg|Acc
Noun	Noun	A3pl|P3sg|Dat
Noun	Noun	A3pl|P3sg|Equ
Noun	Noun	A3pl|P3sg|Gen
Noun	Noun	A3pl|P3sg|Ins
Noun	Noun	A3pl|P3sg|Loc
Noun	Noun	A3pl|P3sg|Nom
Noun	Noun	A3pl|Pnon|Abl
Noun	Noun	A3pl|Pnon|Acc
Noun	Noun	A3pl|Pnon|Dat
Noun	Noun	A3pl|Pnon|Equ
Noun	Noun	A3pl|Pnon|Gen
Noun	Noun	A3pl|Pnon|Ins
Noun	Noun	A3pl|Pnon|Loc
Noun	Noun	A3pl|Pnon|Nom
Noun	Noun	A3sg|P1pl|Abl
Noun	Noun	A3sg|P1pl|Acc
Noun	Noun	A3sg|P1pl|Dat
Noun	Noun	A3sg|P1pl|Gen
Noun	Noun	A3sg|P1pl|Ins
Noun	Noun	A3sg|P1pl|Loc
Noun	Noun	A3sg|P1pl|Nom
Noun	Noun	A3sg|P1sg|Abl
Noun	Noun	A3sg|P1sg|Acc
Noun	Noun	A3sg|P1sg|Dat
Noun	Noun	A3sg|P1sg|Gen
Noun	Noun	A3sg|P1sg|Ins
Noun	Noun	A3sg|P1sg|Loc
Noun	Noun	A3sg|P1sg|Nom
Noun	Noun	A3sg|P2pl|Abl
Noun	Noun	A3sg|P2pl|Acc
Noun	Noun	A3sg|P2pl|Dat
Noun	Noun	A3sg|P2pl|Gen
Noun	Noun	A3sg|P2pl|Ins
Noun	Noun	A3sg|P2pl|Loc
Noun	Noun	A3sg|P2pl|Nom
Noun	Noun	A3sg|P2sg|Abl
Noun	Noun	A3sg|P2sg|Acc
Noun	Noun	A3sg|P2sg|Dat
Noun	Noun	A3sg|P2sg|Equ
Noun	Noun	A3sg|P2sg|Gen
Noun	Noun	A3sg|P2sg|Ins
Noun	Noun	A3sg|P2sg|Loc
Noun	Noun	A3sg|P2sg|Nom
Noun	Noun	A3sg|P3pl|Abl
Noun	Noun	A3sg|P3pl|Acc
Noun	Noun	A3sg|P3pl|Dat
Noun	Noun	A3sg|P3pl|Gen
Noun	Noun	A3sg|P3pl|Ins
Noun	Noun	A3sg|P3pl|Loc
Noun	Noun	A3sg|P3pl|Nom
Noun	Noun	A3sg|P3sg|Abl
Noun	Noun	A3sg|P3sg|Acc
Noun	Noun	A3sg|P3sg|Dat
Noun	Noun	A3sg|P3sg|Equ
Noun	Noun	A3sg|P3sg|Gen
Noun	Noun	A3sg|P3sg|Ins
Noun	Noun	A3sg|P3sg|Loc
Noun	Noun	A3sg|P3sg|Nom
Noun	Noun	A3sg|Pnon|Abl
Noun	Noun	A3sg|Pnon|Acc
Noun	Noun	A3sg|Pnon|Dat
Noun	Noun	A3sg|Pnon|Equ
Noun	Noun	A3sg|Pnon|Gen
Noun	Noun	A3sg|Pnon|Ins
Noun	Noun	A3sg|Pnon|Loc
Noun	Noun	A3sg|Pnon|Nom
Noun	Noun	Agt|A3pl|P3pl|Dat
Noun	Noun	Agt|A3pl|P3sg|Abl
Noun	Noun	Agt|A3pl|P3sg|Gen
Noun	Noun	Agt|A3pl|P3sg|Loc
Noun	Noun	Agt|A3pl|P3sg|Nom
Noun	Noun	Agt|A3pl|Pnon|Abl
Noun	Noun	Agt|A3pl|Pnon|Acc
Noun	Noun	Agt|A3pl|Pnon|Dat
Noun	Noun	Agt|A3pl|Pnon|Gen
Noun	Noun	Agt|A3pl|Pnon|Ins
Noun	Noun	Agt|A3pl|Pnon|Nom
Noun	Noun	Agt|A3sg|P1pl|Nom
Noun	Noun	Agt|A3sg|P1sg|Nom
Noun	Noun	Agt|A3sg|P3pl|Abl
Noun	Noun	Agt|A3sg|P3sg|Nom
Noun	Noun	Agt|A3sg|Pnon|Abl
Noun	Noun	Agt|A3sg|Pnon|Acc
Noun	Noun	Agt|A3sg|Pnon|Dat
Noun	Noun	Agt|A3sg|Pnon|Gen
Noun	Noun	Agt|A3sg|Pnon|Ins
Noun	Noun	Agt|A3sg|Pnon|Nom
Noun	Noun	Dim|A3sg|Pnon|Dat
Noun	Noun	Dim|A3sg|Pnon|Nom
Noun	Noun	Inf2|A3sg|Pnon|Dat
Noun	Noun	Inf3|A3sg|Pnon|Dat
Noun	Noun	Ness|A3pl|P2pl|Loc
Noun	Noun	Ness|A3pl|P2sg|Dat
Noun	Noun	Ness|A3pl|P3pl|Acc
Noun	Noun	Ness|A3pl|P3pl|Dat
Noun	Noun	Ness|A3pl|P3pl|Gen
Noun	Noun	Ness|A3pl|P3sg|Abl
Noun	Noun	Ness|A3pl|P3sg|Acc
Noun	Noun	Ness|A3pl|P3sg|Gen
Noun	Noun	Ness|A3pl|P3sg|Ins
Noun	Noun	Ness|A3pl|P3sg|Nom
Noun	Noun	Ness|A3pl|Pnon|Abl
Noun	Noun	Ness|A3pl|Pnon|Acc
Noun	Noun	Ness|A3pl|Pnon|Dat
Noun	Noun	Ness|A3pl|Pnon|Gen
Noun	Noun	Ness|A3pl|Pnon|Ins
Noun	Noun	Ness|A3pl|Pnon|Nom
Noun	Noun	Ness|A3sg|P1pl|Dat
Noun	Noun	Ness|A3sg|P1pl|Nom
Noun	Noun	Ness|A3sg|P1sg|Acc
Noun	Noun	Ness|A3sg|P1sg|Dat
Noun	Noun	Ness|A3sg|P1sg|Gen
Noun	Noun	Ness|A3sg|P1sg|Ins
Noun	Noun	Ness|A3sg|P1sg|Loc
Noun	Noun	Ness|A3sg|P1sg|Nom
Noun	Noun	Ness|A3sg|P2pl|Nom
Noun	Noun	Ness|A3sg|P2sg|Nom
Noun	Noun	Ness|A3sg|P3pl|Dat
Noun	Noun	Ness|A3sg|P3pl|Gen
Noun	Noun	Ness|A3sg|P3pl|Ins
Noun	Noun	Ness|A3sg|P3sg|Abl
Noun	Noun	Ness|A3sg|P3sg|Acc
Noun	Noun	Ness|A3sg|P3sg|Dat
Noun	Noun	Ness|A3sg|P3sg|Gen
Noun	Noun	Ness|A3sg|P3sg|Ins
Noun	Noun	Ness|A3sg|P3sg|Loc
Noun	Noun	Ness|A3sg|P3sg|Nom
Noun	Noun	Ness|A3sg|Pnon|Abl
Noun	Noun	Ness|A3sg|Pnon|Acc
Noun	Noun	Ness|A3sg|Pnon|Dat
Noun	Noun	Ness|A3sg|Pnon|Gen
Noun	Noun	Ness|A3sg|Pnon|Ins
Noun	Noun	Ness|A3sg|Pnon|Loc
Noun	Noun	Ness|A3sg|Pnon|Nom
Noun	Prop	A3pl|P3sg|Dat
Noun	Prop	A3pl|P3sg|Gen
Noun	Prop	A3pl|P3sg|Loc
Noun	Prop	A3pl|Pnon|Abl
Noun	Prop	A3pl|Pnon|Acc
Noun	Prop	A3pl|Pnon|Dat
Noun	Prop	A3pl|Pnon|Gen
Noun	Prop	A3pl|Pnon|Loc
Noun	Prop	A3pl|Pnon|Nom
Noun	Prop	A3sg|P1sg|Nom
Noun	Prop	A3sg|P2sg|Nom
Noun	Prop	A3sg|P3sg|Abl
Noun	Prop	A3sg|P3sg|Acc
Noun	Prop	A3sg|P3sg|Dat
Noun	Prop	A3sg|P3sg|Equ
Noun	Prop	A3sg|P3sg|Gen
Noun	Prop	A3sg|P3sg|Ins
Noun	Prop	A3sg|P3sg|Loc
Noun	Prop	A3sg|P3sg|Nom
Noun	Prop	A3sg|Pnon|Abl
Noun	Prop	A3sg|Pnon|Acc
Noun	Prop	A3sg|Pnon|Dat
Noun	Prop	A3sg|Pnon|Gen
Noun	Prop	A3sg|Pnon|Ins
Noun	Prop	A3sg|Pnon|Loc
Noun	Prop	A3sg|Pnon|Nom
Noun	Zero	A3pl|P2sg|Equ
Noun	Zero	A3pl|P2sg|Gen
Noun	Zero	A3pl|P2sg|Nom
Noun	Zero	A3pl|P3pl|Acc
Noun	Zero	A3pl|P3pl|Gen
Noun	Zero	A3pl|P3pl|Loc
Noun	Zero	A3pl|P3pl|Nom
Noun	Zero	A3pl|P3sg|Abl
Noun	Zero	A3pl|P3sg|Acc
Noun	Zero	A3pl|P3sg|Dat
Noun	Zero	A3pl|P3sg|Gen
Noun	Zero	A3pl|P3sg|Ins
Noun	Zero	A3pl|P3sg|Loc
Noun	Zero	A3pl|P3sg|Nom
Noun	Zero	A3pl|Pnon|Abl
Noun	Zero	A3pl|Pnon|Acc
Noun	Zero	A3pl|Pnon|Dat
Noun	Zero	A3pl|Pnon|Equ
Noun	Zero	A3pl|Pnon|Gen
Noun	Zero	A3pl|Pnon|Ins
Noun	Zero	A3pl|Pnon|Loc
Noun	Zero	A3pl|Pnon|Nom
Noun	Zero	A3sg|P1pl|Abl
Noun	Zero	A3sg|P1pl|Acc
Noun	Zero	A3sg|P1pl|Gen
Noun	Zero	A3sg|P1pl|Nom
Noun	Zero	A3sg|P1sg|Nom
Noun	Zero	A3sg|P2pl|Loc
Noun	Zero	A3sg|P2sg|Abl
Noun	Zero	A3sg|P2sg|Acc
Noun	Zero	A3sg|P2sg|Dat
Noun	Zero	A3sg|P2sg|Loc
Noun	Zero	A3sg|P3pl|Acc
Noun	Zero	A3sg|P3pl|Nom
Noun	Zero	A3sg|P3sg|Abl
Noun	Zero	A3sg|P3sg|Acc
Noun	Zero	A3sg|P3sg|Dat
Noun	Zero	A3sg|P3sg|Gen
Noun	Zero	A3sg|P3sg|Ins
Noun	Zero	A3sg|P3sg|Loc
Noun	Zero	A3sg|P3sg|Nom
Noun	Zero	A3sg|Pnon|Abl
Noun	Zero	A3sg|Pnon|Acc
Noun	Zero	A3sg|Pnon|Dat
Noun	Zero	A3sg|Pnon|Gen
Noun	Zero	A3sg|Pnon|Ins
Noun	Zero	A3sg|Pnon|Loc
Noun	Zero	A3sg|Pnon|Nom
Num	Card	_
Num	Distrib	_
Num	Ord	_
Num	Range	_
Num	Real	_
Postp	Postp	PCAbl
Postp	Postp	PCAcc
Postp	Postp	PCDat
Postp	Postp	PCGen
Postp	Postp	PCIns
Postp	Postp	PCNom
Pron	DemonsP	A3pl|Pnon|Abl
Pron	DemonsP	A3pl|Pnon|Acc
Pron	DemonsP	A3pl|Pnon|Dat
Pron	DemonsP	A3pl|Pnon|Gen
Pron	DemonsP	A3pl|Pnon|Nom
Pron	DemonsP	A3sg|Pnon|Abl
Pron	DemonsP	A3sg|Pnon|Acc
Pron	DemonsP	A3sg|Pnon|Dat
Pron	DemonsP	A3sg|Pnon|Equ
Pron	DemonsP	A3sg|Pnon|Gen
Pron	DemonsP	A3sg|Pnon|Ins
Pron	DemonsP	A3sg|Pnon|Loc
Pron	DemonsP	A3sg|Pnon|Nom
Pron	PersP	A1pl|Pnon|Abl
Pron	PersP	A1pl|Pnon|Acc
Pron	PersP	A1pl|Pnon|Dat
Pron	PersP	A1pl|Pnon|Gen
Pron	PersP	A1pl|Pnon|Ins
Pron	PersP	A1pl|Pnon|Loc
Pron	PersP	A1pl|Pnon|Nom
Pron	PersP	A1sg|Pnon|Abl
Pron	PersP	A1sg|Pnon|Acc
Pron	PersP	A1sg|Pnon|Dat
Pron	PersP	A1sg|Pnon|Equ
Pron	PersP	A1sg|Pnon|Gen
Pron	PersP	A1sg|Pnon|Ins
Pron	PersP	A1sg|Pnon|Loc
Pron	PersP	A1sg|Pnon|Nom
Pron	PersP	A2pl|Pnon|Abl
Pron	PersP	A2pl|Pnon|Acc
Pron	PersP	A2pl|Pnon|Dat
Pron	PersP	A2pl|Pnon|Gen
Pron	PersP	A2pl|Pnon|Ins
Pron	PersP	A2pl|Pnon|Nom
Pron	PersP	A2sg|Pnon|Abl
Pron	PersP	A2sg|Pnon|Acc
Pron	PersP	A2sg|Pnon|Dat
Pron	PersP	A2sg|Pnon|Gen
Pron	PersP	A2sg|Pnon|Ins
Pron	PersP	A2sg|Pnon|Nom
Pron	PersP	A3pl|Pnon|Abl
Pron	PersP	A3pl|Pnon|Acc
Pron	PersP	A3pl|Pnon|Dat
Pron	PersP	A3pl|Pnon|Gen
Pron	PersP	A3pl|Pnon|Ins
Pron	PersP	A3pl|Pnon|Loc
Pron	PersP	A3pl|Pnon|Nom
Pron	PersP	A3sg|Pnon|Abl
Pron	PersP	A3sg|Pnon|Acc
Pron	PersP	A3sg|Pnon|Dat
Pron	PersP	A3sg|Pnon|Equ
Pron	PersP	A3sg|Pnon|Gen
Pron	PersP	A3sg|Pnon|Ins
Pron	PersP	A3sg|Pnon|Loc
Pron	PersP	A3sg|Pnon|Nom
Pron	Pron	A1pl|P1pl|Acc
Pron	Pron	A1pl|P1pl|Dat
Pron	Pron	A1pl|P1pl|Equ
Pron	Pron	A1pl|P1pl|Gen
Pron	Pron	A1pl|P1pl|Nom
Pron	Pron	A2pl|P2pl|Acc
Pron	Pron	A2pl|P2pl|Ins
Pron	Pron	A2pl|P2pl|Nom
Pron	Pron	A3pl|P3pl|Abl
Pron	Pron	A3pl|P3pl|Acc
Pron	Pron	A3pl|P3pl|Dat
Pron	Pron	A3pl|P3pl|Gen
Pron	Pron	A3pl|P3pl|Ins
Pron	Pron	A3pl|P3pl|Loc
Pron	Pron	A3pl|P3pl|Nom
Pron	Pron	A3pl|Pnon|Gen
Pron	Pron	A3pl|Pnon|Nom
Pron	Pron	A3sg|P3sg|Abl
Pron	Pron	A3sg|P3sg|Acc
Pron	Pron	A3sg|P3sg|Dat
Pron	Pron	A3sg|P3sg|Gen
Pron	Pron	A3sg|P3sg|Ins
Pron	Pron	A3sg|P3sg|Loc
Pron	Pron	A3sg|P3sg|Nom
Pron	Pron	A3sg|Pnon|Abl
Pron	Pron	A3sg|Pnon|Acc
Pron	Pron	A3sg|Pnon|Dat
Pron	Pron	A3sg|Pnon|Loc
Pron	Pron	A3sg|Pnon|Nom
Pron	QuesP	A3pl|Pnon|Abl
Pron	QuesP	A3pl|Pnon|Acc
Pron	QuesP	A3pl|Pnon|Dat
Pron	QuesP	A3pl|Pnon|Loc
Pron	QuesP	A3pl|Pnon|Nom
Pron	QuesP	A3sg|P1sg|Nom
Pron	QuesP	A3sg|P2sg|Nom
Pron	QuesP	A3sg|P3sg|Acc
Pron	QuesP	A3sg|P3sg|Gen
Pron	QuesP	A3sg|P3sg|Nom
Pron	QuesP	A3sg|Pnon|Abl
Pron	QuesP	A3sg|Pnon|Acc
Pron	QuesP	A3sg|Pnon|Dat
Pron	QuesP	A3sg|Pnon|Gen
Pron	QuesP	A3sg|Pnon|Loc
Pron	QuesP	A3sg|Pnon|Nom
Pron	ReflexP	A1pl|P1pl|Acc
Pron	ReflexP	A1pl|P1pl|Dat
Pron	ReflexP	A1sg|P1sg|Acc
Pron	ReflexP	A1sg|P1sg|Dat
Pron	ReflexP	A1sg|P1sg|Nom
Pron	ReflexP	A2pl|P2pl|Acc
Pron	ReflexP	A2pl|P2pl|Dat
Pron	ReflexP	A2pl|P2pl|Nom
Pron	ReflexP	A2sg|P2sg|Acc
Pron	ReflexP	A2sg|P2sg|Dat
Pron	ReflexP	A3pl|P3pl|Abl
Pron	ReflexP	A3pl|P3pl|Acc
Pron	ReflexP	A3pl|P3pl|Dat
Pron	ReflexP	A3pl|P3pl|Gen
Pron	ReflexP	A3pl|P3pl|Ins
Pron	ReflexP	A3pl|P3pl|Loc
Pron	ReflexP	A3pl|P3pl|Nom
Pron	ReflexP	A3sg|P3sg|Abl
Pron	ReflexP	A3sg|P3sg|Acc
Pron	ReflexP	A3sg|P3sg|Dat
Pron	ReflexP	A3sg|P3sg|Equ
Pron	ReflexP	A3sg|P3sg|Gen
Pron	ReflexP	A3sg|P3sg|Ins
Pron	ReflexP	A3sg|P3sg|Nom
Punc	Punc	_
Ques	Ques	Narr|A3sg
Ques	Ques	Past|A1sg
Ques	Ques	Past|A2sg
Ques	Ques	Past|A3sg
Ques	Ques	Pres|A1pl
Ques	Ques	Pres|A1sg
Ques	Ques	Pres|A2pl
Ques	Ques	Pres|A2sg
Ques	Ques	Pres|A3sg
Ques	Ques	Pres|Cop|A3sg
Verb	Verb	A1pl
Verb	Verb	A3sg
Verb	Verb	Able
Verb	Verb	Able|Aor
Verb	Verb	Able|Aor|A1pl
Verb	Verb	Able|Aor|A1sg
Verb	Verb	Able|Aor|A2pl
Verb	Verb	Able|Aor|A2sg
Verb	Verb	Able|Aor|A3pl
Verb	Verb	Able|Aor|A3sg
Verb	Verb	Able|Aor|Narr|A3sg
Verb	Verb	Able|Aor|Past|A1pl
Verb	Verb	Able|Aor|Past|A1sg
Verb	Verb	Able|Aor|Past|A3pl
Verb	Verb	Able|Aor|Past|A3sg
Verb	Verb	Able|Cond|Aor|A3sg
Verb	Verb	Able|Cond|Prog1|A2pl
Verb	Verb	Able|Desr|A1pl
Verb	Verb	Able|Desr|A1sg
Verb	Verb	Able|Desr|Past|A3pl
Verb	Verb	Able|Desr|Past|A3sg
Verb	Verb	Able|Fut|A1sg
Verb	Verb	Able|Fut|A3pl
Verb	Verb	Able|Fut|A3sg
Verb	Verb	Able|Fut|Cop|A3sg
Verb	Verb	Able|Fut|Past|A1pl
Verb	Verb	Able|Fut|Past|A3pl
Verb	Verb	Able|Imp|A3sg
Verb	Verb	Able|Narr
Verb	Verb	Able|Narr|A3sg
Verb	Verb	Able|Narr|Cop|A3sg
Verb	Verb	Able|Neces|A3sg
Verb	Verb	Able|Neces|Cop|A3sg
Verb	Verb	Able|Neg
Verb	Verb	Able|Neg|Aor
Verb	Verb	Able|Neg|Aor|A1pl
Verb	Verb	Able|Neg|Aor|A1sg
Verb	Verb	Able|Neg|Aor|A2pl
Verb	Verb	Able|Neg|Aor|A2sg
Verb	Verb	Able|Neg|Aor|A3pl
Verb	Verb	Able|Neg|Aor|A3sg
Verb	Verb	Able|Neg|Aor|Narr|A3sg
Verb	Verb	Able|Neg|Aor|Past|A1sg
Verb	Verb	Able|Neg|Aor|Past|A3pl
Verb	Verb	Able|Neg|Aor|Past|A3sg
Verb	Verb	Able|Neg|Cond|Aor|A1sg
Verb	Verb	Able|Neg|Cond|Aor|A2pl
Verb	Verb	Able|Neg|Cond|Fut|A3sg
Verb	Verb	Able|Neg|Desr|A3sg
Verb	Verb	Able|Neg|Fut|A1sg
Verb	Verb	Able|Neg|Fut|A3sg
Verb	Verb	Able|Neg|Narr
Verb	Verb	Able|Neg|Narr|A1pl
Verb	Verb	Able|Neg|Narr|A1sg
Verb	Verb	Able|Neg|Narr|A2sg
Verb	Verb	Able|Neg|Narr|A3sg
Verb	Verb	Able|Neg|Narr|Past|A1pl
Verb	Verb	Able|Neg|Narr|Past|A1sg
Verb	Verb	Able|Neg|Narr|Past|A3sg
Verb	Verb	Able|Neg|Past|A1pl
Verb	Verb	Able|Neg|Past|A1sg
Verb	Verb	Able|Neg|Past|A2pl
Verb	Verb	Able|Neg|Past|A3pl
Verb	Verb	Able|Neg|Past|A3sg
Verb	Verb	Able|Neg|Prog1|A1pl
Verb	Verb	Able|Neg|Prog1|A1sg
Verb	Verb	Able|Neg|Prog1|A2pl
Verb	Verb	Able|Neg|Prog1|A2sg
Verb	Verb	Able|Neg|Prog1|A3pl
Verb	Verb	Able|Neg|Prog1|A3sg
Verb	Verb	Able|Neg|Prog1|Past|A1sg
Verb	Verb	Able|Neg|Prog1|Past|A3pl
Verb	Verb	Able|Neg|Prog1|Past|A3sg
Verb	Verb	Able|Past|A1pl
Verb	Verb	Able|Past|A1sg
Verb	Verb	Able|Past|A2pl
Verb	Verb	Able|Past|A3sg
Verb	Verb	Able|Prog1|A1sg
Verb	Verb	Able|Prog1|A2sg
Verb	Verb	Able|Prog1|A3pl
Verb	Verb	Able|Prog1|A3sg
Verb	Verb	Able|Prog1|Past|A1sg
Verb	Verb	Able|Prog1|Past|A3sg
Verb	Verb	Acquire
Verb	Verb	Acquire|Neg|Aor|A3sg
Verb	Verb	Acquire|Neg|Fut|A1pl
Verb	Verb	Acquire|Neg|Imp|A2sg
Verb	Verb	Acquire|Neg|Narr
Verb	Verb	Acquire|Pos
Verb	Verb	Acquire|Pos|Aor
Verb	Verb	Acquire|Pos|Aor|A3pl
Verb	Verb	Acquire|Pos|Aor|A3sg
Verb	Verb	Acquire|Pos|Cond|Fut|A3sg
Verb	Verb	Acquire|Pos|Imp|A2sg
Verb	Verb	Acquire|Pos|Imp|A3sg
Verb	Verb	Acquire|Pos|Narr
Verb	Verb	Acquire|Pos|Narr|A3sg
Verb	Verb	Acquire|Pos|Narr|Cop|A3sg
Verb	Verb	Acquire|Pos|Narr|Past|A1sg
Verb	Verb	Acquire|Pos|Narr|Past|A3sg
Verb	Verb	Acquire|Pos|Opt|A3sg
Verb	Verb	Acquire|Pos|Past|A1sg
Verb	Verb	Acquire|Pos|Past|A3sg
Verb	Verb	Acquire|Pos|Prog1|A1pl
Verb	Verb	Acquire|Pos|Prog1|A1sg
Verb	Verb	Acquire|Pos|Prog1|A2sg
Verb	Verb	Acquire|Pos|Prog1|A3pl
Verb	Verb	Acquire|Pos|Prog1|A3sg
Verb	Verb	Acquire|Pos|Prog1|Past|A3sg
Verb	Verb	Acquire|Pos|Prog2|A3sg
Verb	Verb	Aor
Verb	Verb	Aor|A1pl
Verb	Verb	Aor|A1sg
Verb	Verb	Aor|A2pl
Verb	Verb	Aor|A2sg
Verb	Verb	Aor|A3pl
Verb	Verb	Aor|A3sg
Verb	Verb	Aor|Narr|A3sg
Verb	Verb	Aor|Past|A1pl
Verb	Verb	Aor|Past|A1sg
Verb	Verb	Aor|Past|A3pl
Verb	Verb	Aor|Past|A3sg
Verb	Verb	Become
Verb	Verb	Become|Neg|Aor
Verb	Verb	Become|Neg|Aor|A3sg
Verb	Verb	Become|Neg|Imp|A2sg
Verb	Verb	Become|Pos
Verb	Verb	Become|Pos|Aor|A3sg
Verb	Verb	Become|Pos|Aor|Past|A3pl
Verb	Verb	Become|Pos|Desr|A3sg
Verb	Verb	Become|Pos|Narr|A3sg
Verb	Verb	Become|Pos|Narr|Cop|A3sg
Verb	Verb	Become|Pos|Narr|Past|A3sg
Verb	Verb	Become|Pos|Past|A2pl
Verb	Verb	Become|Pos|Past|A2sg
Verb	Verb	Become|Pos|Past|A3sg
Verb	Verb	Become|Pos|Prog1|A1pl
Verb	Verb	Become|Pos|Prog1|A2sg
Verb	Verb	Become|Pos|Prog1|A3sg
Verb	Verb	Become|Pos|Prog1|Past|A3pl
Verb	Verb	Become|Pos|Prog1|Past|A3sg
Verb	Verb	Caus
Verb	Verb	Caus|Neg
Verb	Verb	Caus|Neg|Aor|A1sg
Verb	Verb	Caus|Neg|Aor|A3sg
Verb	Verb	Caus|Neg|Aor|Past|A1sg
Verb	Verb	Caus|Neg|Desr|A3pl
Verb	Verb	Caus|Neg|Imp|A2sg
Verb	Verb	Caus|Neg|Past|A1pl
Verb	Verb	Caus|Neg|Past|A3sg
Verb	Verb	Caus|Pos
Verb	Verb	Caus|Pos|Aor
Verb	Verb	Caus|Pos|Aor|A1pl
Verb	Verb	Caus|Pos|Aor|A1sg
Verb	Verb	Caus|Pos|Aor|A2pl
Verb	Verb	Caus|Pos|Aor|A3pl
Verb	Verb	Caus|Pos|Aor|A3sg
Verb	Verb	Caus|Pos|Aor|Past|A3sg
Verb	Verb	Caus|Pos|Cond|Aor|A3pl
Verb	Verb	Caus|Pos|Desr|A1sg
Verb	Verb	Caus|Pos|Desr|A3sg
Verb	Verb	Caus|Pos|Fut|A1pl
Verb	Verb	Caus|Pos|Fut|A1sg
Verb	Verb	Caus|Pos|Fut|A2sg
Verb	Verb	Caus|Pos|Fut|A3pl
Verb	Verb	Caus|Pos|Fut|A3sg
Verb	Verb	Caus|Pos|Fut|Cop|A3sg
Verb	Verb	Caus|Pos|Fut|Past|A1sg
Verb	Verb	Caus|Pos|Imp|A2sg
Verb	Verb	Caus|Pos|Imp|A3sg
Verb	Verb	Caus|Pos|Narr
Verb	Verb	Caus|Pos|Narr|A1pl
Verb	Verb	Caus|Pos|Narr|A2sg
Verb	Verb	Caus|Pos|Narr|A3pl
Verb	Verb	Caus|Pos|Narr|A3sg
Verb	Verb	Caus|Pos|Narr|Cop|A3pl
Verb	Verb	Caus|Pos|Narr|Cop|A3sg
Verb	Verb	Caus|Pos|Narr|Past|A1pl
Verb	Verb	Caus|Pos|Narr|Past|A1sg
Verb	Verb	Caus|Pos|Narr|Past|A2sg
Verb	Verb	Caus|Pos|Narr|Past|A3pl
Verb	Verb	Caus|Pos|Narr|Past|A3sg
Verb	Verb	Caus|Pos|Neces|A3sg
Verb	Verb	Caus|Pos|Opt|A1pl
Verb	Verb	Caus|Pos|Opt|A3pl
Verb	Verb	Caus|Pos|Opt|A3sg
Verb	Verb	Caus|Pos|Past|A1pl
Verb	Verb	Caus|Pos|Past|A1sg
Verb	Verb	Caus|Pos|Past|A2pl
Verb	Verb	Caus|Pos|Past|A3pl
Verb	Verb	Caus|Pos|Past|A3sg
Verb	Verb	Caus|Pos|Prog1|A1sg
Verb	Verb	Caus|Pos|Prog1|A2sg
Verb	Verb	Caus|Pos|Prog1|A3pl
Verb	Verb	Caus|Pos|Prog1|A3sg
Verb	Verb	Caus|Pos|Prog1|Narr|A3sg
Verb	Verb	Caus|Pos|Prog1|Past|A1sg
Verb	Verb	Caus|Pos|Prog1|Past|A2sg
Verb	Verb	Caus|Pos|Prog1|Past|A3pl
Verb	Verb	Caus|Pos|Prog1|Past|A3sg
Verb	Verb	Caus|Pos|Prog2|A3sg
Verb	Verb	Caus|Pos|Prog2|Cop|A3sg
Verb	Verb	Cond|A1sg
Verb	Verb	Cond|A3sg
Verb	Verb	Cond|Aor|A3sg
Verb	Verb	Cond|Prog1|A2pl
Verb	Verb	Desr|A1pl
Verb	Verb	Desr|A1sg
Verb	Verb	Desr|Past|A3pl
Verb	Verb	Desr|Past|A3sg
Verb	Verb	Fut|A1sg
Verb	Verb	Fut|A3pl
Verb	Verb	Fut|A3sg
Verb	Verb	Fut|Cop|A3sg
Verb	Verb	Fut|Past|A1pl
Verb	Verb	Fut|Past|A3pl
Verb	Verb	Hastily
Verb	Verb	Hastily|Aor|A3sg
Verb	Verb	Hastily|Imp|A2sg
Verb	Verb	Hastily|Narr|Past|A2sg
Verb	Verb	Hastily|Narr|Past|A3sg
Verb	Verb	Hastily|Past|A3sg
Verb	Verb	Hastily|Prog1|A3sg
Verb	Verb	Imp|A2sg
Verb	Verb	Imp|A3sg
Verb	Verb	Narr
Verb	Verb	Narr|A1pl
Verb	Verb	Narr|A1sg
Verb	Verb	Narr|A2sg
Verb	Verb	Narr|A3pl
Verb	Verb	Narr|A3sg
Verb	Verb	Narr|Cop|A3sg
Verb	Verb	Narr|Past|A1pl
Verb	Verb	Narr|Past|A2sg
Verb	Verb	Narr|Past|A3sg
Verb	Verb	Neces|A3sg
Verb	Verb	Neces|Cop|A3sg
Verb	Verb	Neg
Verb	Verb	Neg|Aor
Verb	Verb	Neg|Aor|A1pl
Verb	Verb	Neg|Aor|A1sg
Verb	Verb	Neg|Aor|A2pl
Verb	Verb	Neg|Aor|A2sg
Verb	Verb	Neg|Aor|A3pl
Verb	Verb	Neg|Aor|A3sg
Verb	Verb	Neg|Aor|Narr|A3sg
Verb	Verb	Neg|Aor|Past|A1sg
Verb	Verb	Neg|Aor|Past|A3pl
Verb	Verb	Neg|Aor|Past|A3sg
Verb	Verb	Neg|Cond|Aor|A1pl
Verb	Verb	Neg|Cond|Aor|A1sg
Verb	Verb	Neg|Cond|Aor|A2pl
Verb	Verb	Neg|Cond|Aor|A3sg
Verb	Verb	Neg|Cond|Fut|A3sg
Verb	Verb	Neg|Cond|Past|A2pl
Verb	Verb	Neg|Cond|Prog1|A1sg
Verb	Verb	Neg|Cond|Prog1|A2pl
Verb	Verb	Neg|Cond|Prog1|A3pl
Verb	Verb	Neg|Cond|Prog1|A3sg
Verb	Verb	Neg|Desr|A1pl
Verb	Verb	Neg|Desr|A1sg
Verb	Verb	Neg|Desr|A2pl
Verb	Verb	Neg|Desr|A2sg
Verb	Verb	Neg|Desr|A3pl
Verb	Verb	Neg|Desr|A3sg
Verb	Verb	Neg|Desr|Past|A1sg
Verb	Verb	Neg|Desr|Past|A3sg
Verb	Verb	Neg|Fut|A1pl
Verb	Verb	Neg|Fut|A1sg
Verb	Verb	Neg|Fut|A2sg
Verb	Verb	Neg|Fut|A3sg
Verb	Verb	Neg|Fut|Cop|A3sg
Verb	Verb	Neg|Fut|Narr|A3sg
Verb	Verb	Neg|Fut|Past|A1sg
Verb	Verb	Neg|Fut|Past|A3sg
Verb	Verb	Neg|Imp|A2pl
Verb	Verb	Neg|Imp|A2sg
Verb	Verb	Neg|Imp|A3sg
Verb	Verb	Neg|Narr
Verb	Verb	Neg|Narr|A1pl
Verb	Verb	Neg|Narr|A1sg
Verb	Verb	Neg|Narr|A2sg
Verb	Verb	Neg|Narr|A3pl
Verb	Verb	Neg|Narr|A3sg
Verb	Verb	Neg|Narr|Cop|A3sg
Verb	Verb	Neg|Narr|Past|A1pl
Verb	Verb	Neg|Narr|Past|A1sg
Verb	Verb	Neg|Narr|Past|A3pl
Verb	Verb	Neg|Narr|Past|A3sg
Verb	Verb	Neg|Neces|Past|A2pl
Verb	Verb	Neg|Opt|A1pl
Verb	Verb	Neg|Opt|A1sg
Verb	Verb	Neg|Opt|A3sg
Verb	Verb	Neg|Past|A1pl
Verb	Verb	Neg|Past|A1sg
Verb	Verb	Neg|Past|A2pl
Verb	Verb	Neg|Past|A2sg
Verb	Verb	Neg|Past|A3pl
Verb	Verb	Neg|Past|A3sg
Verb	Verb	Neg|Prog1|A1pl
Verb	Verb	Neg|Prog1|A1sg
Verb	Verb	Neg|Prog1|A2pl
Verb	Verb	Neg|Prog1|A2sg
Verb	Verb	Neg|Prog1|A3pl
Verb	Verb	Neg|Prog1|A3sg
Verb	Verb	Neg|Prog1|Cop|A3sg
Verb	Verb	Neg|Prog1|Narr|A3pl
Verb	Verb	Neg|Prog1|Past|A1sg
Verb	Verb	Neg|Prog1|Past|A2sg
Verb	Verb	Neg|Prog1|Past|A3pl
Verb	Verb	Neg|Prog1|Past|A3sg
Verb	Verb	Neg|Prog2|Cop|A3sg
Verb	Verb	Pass
Verb	Verb	Pass|Neg
Verb	Verb	Pass|Neg|Aor
Verb	Verb	Pass|Neg|Aor|A3pl
Verb	Verb	Pass|Neg|Aor|A3sg
Verb	Verb	Pass|Neg|Aor|Past|A3sg
Verb	Verb	Pass|Neg|Fut|A3sg
Verb	Verb	Pass|Neg|Narr
Verb	Verb	Pass|Neg|Narr|A3sg
Verb	Verb	Pass|Neg|Narr|Cop|A3sg
Verb	Verb	Pass|Neg|Narr|Past|A3sg
Verb	Verb	Pass|Neg|Neces|A3sg
Verb	Verb	Pass|Neg|Past|A1sg
Verb	Verb	Pass|Neg|Past|A3sg
Verb	Verb	Pass|Neg|Prog1|A1sg
Verb	Verb	Pass|Neg|Prog1|A3sg
Verb	Verb	Pass|Neg|Prog1|Narr|A3sg
Verb	Verb	Pass|Neg|Prog1|Past|A3sg
Verb	Verb	Pass|Pos
Verb	Verb	Pass|Pos|A3sg
Verb	Verb	Pass|Pos|Aor
Verb	Verb	Pass|Pos|Aor|A1pl
Verb	Verb	Pass|Pos|Aor|A1sg
Verb	Verb	Pass|Pos|Aor|A2sg
Verb	Verb	Pass|Pos|Aor|A3pl
Verb	Verb	Pass|Pos|Aor|A3sg
Verb	Verb	Pass|Pos|Aor|Narr|A3sg
Verb	Verb	Pass|Pos|Aor|Past|A3sg
Verb	Verb	Pass|Pos|Cond|Aor|A1sg
Verb	Verb	Pass|Pos|Cond|Aor|A3sg
Verb	Verb	Pass|Pos|Cond|Narr|A3sg
Verb	Verb	Pass|Pos|Desr|A3sg
Verb	Verb	Pass|Pos|Fut|A3pl
Verb	Verb	Pass|Pos|Fut|A3sg
Verb	Verb	Pass|Pos|Fut|Cop|A3sg
Verb	Verb	Pass|Pos|Fut|Past|A3sg
Verb	Verb	Pass|Pos|Imp|A3sg
Verb	Verb	Pass|Pos|Narr
Verb	Verb	Pass|Pos|Narr|A2sg
Verb	Verb	Pass|Pos|Narr|A3sg
Verb	Verb	Pass|Pos|Narr|Cop|A3sg
Verb	Verb	Pass|Pos|Narr|Past|A3pl
Verb	Verb	Pass|Pos|Narr|Past|A3sg
Verb	Verb	Pass|Pos|Neces|A3sg
Verb	Verb	Pass|Pos|Neces|Cop|A3pl
Verb	Verb	Pass|Pos|Neces|Cop|A3sg
Verb	Verb	Pass|Pos|Neces|Past|A3sg
Verb	Verb	Pass|Pos|Opt|A3sg
Verb	Verb	Pass|Pos|Past|A1pl
Verb	Verb	Pass|Pos|Past|A1sg
Verb	Verb	Pass|Pos|Past|A3pl
Verb	Verb	Pass|Pos|Past|A3sg
Verb	Verb	Pass|Pos|Prog1|A1sg
Verb	Verb	Pass|Pos|Prog1|A2sg
Verb	Verb	Pass|Pos|Prog1|A3pl
Verb	Verb	Pass|Pos|Prog1|A3sg
Verb	Verb	Pass|Pos|Prog1|Narr|A3sg
Verb	Verb	Pass|Pos|Prog1|Past|A1sg
Verb	Verb	Pass|Pos|Prog1|Past|A3sg
Verb	Verb	Pass|Pos|Prog2|A3sg
Verb	Verb	Pass|Pos|Prog2|Cop|A3sg
Verb	Verb	Past|A1pl
Verb	Verb	Past|A1sg
Verb	Verb	Past|A2pl
Verb	Verb	Past|A2sg
Verb	Verb	Past|A3pl
Verb	Verb	Past|A3sg
Verb	Verb	Pos
Verb	Verb	Pos|Aor
Verb	Verb	Pos|Aor|A1pl
Verb	Verb	Pos|Aor|A1sg
Verb	Verb	Pos|Aor|A2pl
Verb	Verb	Pos|Aor|A2sg
Verb	Verb	Pos|Aor|A3pl
Verb	Verb	Pos|Aor|A3sg
Verb	Verb	Pos|Aor|Narr|A1sg
Verb	Verb	Pos|Aor|Narr|A3pl
Verb	Verb	Pos|Aor|Narr|A3sg
Verb	Verb	Pos|Aor|Past|A1pl
Verb	Verb	Pos|Aor|Past|A1sg
Verb	Verb	Pos|Aor|Past|A2sg
Verb	Verb	Pos|Aor|Past|A3pl
Verb	Verb	Pos|Aor|Past|A3sg
Verb	Verb	Pos|Cond|Aor|A1pl
Verb	Verb	Pos|Cond|Aor|A1sg
Verb	Verb	Pos|Cond|Aor|A2pl
Verb	Verb	Pos|Cond|Aor|A2sg
Verb	Verb	Pos|Cond|Aor|A3pl
Verb	Verb	Pos|Cond|Aor|A3sg
Verb	Verb	Pos|Cond|Fut|A2sg
Verb	Verb	Pos|Cond|Fut|A3sg
Verb	Verb	Pos|Cond|Narr|A3pl
Verb	Verb	Pos|Cond|Narr|A3sg
Verb	Verb	Pos|Cond|Past|A2sg
Verb	Verb	Pos|Cond|Past|A3sg
Verb	Verb	Pos|Cond|Prog1|A1pl
Verb	Verb	Pos|Cond|Prog1|A1sg
Verb	Verb	Pos|Cond|Prog1|A2sg
Verb	Verb	Pos|Cond|Prog1|A3sg
Verb	Verb	Pos|Desr|A1pl
Verb	Verb	Pos|Desr|A1sg
Verb	Verb	Pos|Desr|A2pl
Verb	Verb	Pos|Desr|A2sg
Verb	Verb	Pos|Desr|A3pl
Verb	Verb	Pos|Desr|A3sg
Verb	Verb	Pos|Desr|Past|A1sg
Verb	Verb	Pos|Desr|Past|A2pl
Verb	Verb	Pos|Desr|Past|A2sg
Verb	Verb	Pos|Desr|Past|A3pl
Verb	Verb	Pos|Desr|Past|A3sg
Verb	Verb	Pos|Fut|A1pl
Verb	Verb	Pos|Fut|A1sg
Verb	Verb	Pos|Fut|A2pl
Verb	Verb	Pos|Fut|A2sg
Verb	Verb	Pos|Fut|A3pl
Verb	Verb	Pos|Fut|A3sg
Verb	Verb	Pos|Fut|Cop|A3sg
Verb	Verb	Pos|Fut|Narr|A3pl
Verb	Verb	Pos|Fut|Narr|A3sg
Verb	Verb	Pos|Fut|Past|A1pl
Verb	Verb	Pos|Fut|Past|A1sg
Verb	Verb	Pos|Fut|Past|A2sg
Verb	Verb	Pos|Fut|Past|A3pl
Verb	Verb	Pos|Fut|Past|A3sg
Verb	Verb	Pos|Imp|A2pl
Verb	Verb	Pos|Imp|A2sg
Verb	Verb	Pos|Imp|A3pl
Verb	Verb	Pos|Imp|A3sg
Verb	Verb	Pos|Narr
Verb	Verb	Pos|Narr|A1pl
Verb	Verb	Pos|Narr|A1sg
Verb	Verb	Pos|Narr|A2pl
Verb	Verb	Pos|Narr|A2sg
Verb	Verb	Pos|Narr|A3pl
Verb	Verb	Pos|Narr|A3sg
Verb	Verb	Pos|Narr|Cop|A1sg
Verb	Verb	Pos|Narr|Cop|A3pl
Verb	Verb	Pos|Narr|Cop|A3sg
Verb	Verb	Pos|Narr|Past|A1pl
Verb	Verb	Pos|Narr|Past|A1sg
Verb	Verb	Pos|Narr|Past|A2pl
Verb	Verb	Pos|Narr|Past|A2sg
Verb	Verb	Pos|Narr|Past|A3pl
Verb	Verb	Pos|Narr|Past|A3sg
Verb	Verb	Pos|Neces|A1pl
Verb	Verb	Pos|Neces|A1sg
Verb	Verb	Pos|Neces|A2pl
Verb	Verb	Pos|Neces|A2sg
Verb	Verb	Pos|Neces|A3sg
Verb	Verb	Pos|Neces|Cop|A3sg
Verb	Verb	Pos|Neces|Past|A1sg
Verb	Verb	Pos|Neces|Past|A2pl
Verb	Verb	Pos|Neces|Past|A3sg
Verb	Verb	Pos|Opt|A1pl
Verb	Verb	Pos|Opt|A1sg
Verb	Verb	Pos|Opt|A3sg
Verb	Verb	Pos|Past|A1pl
Verb	Verb	Pos|Past|A1sg
Verb	Verb	Pos|Past|A2pl
Verb	Verb	Pos|Past|A2sg
Verb	Verb	Pos|Past|A3pl
Verb	Verb	Pos|Past|A3sg
Verb	Verb	Pos|Prog1|A1pl
Verb	Verb	Pos|Prog1|A1sg
Verb	Verb	Pos|Prog1|A2pl
Verb	Verb	Pos|Prog1|A2sg
Verb	Verb	Pos|Prog1|A3pl
Verb	Verb	Pos|Prog1|A3sg
Verb	Verb	Pos|Prog1|Cop|A3sg
Verb	Verb	Pos|Prog1|Narr|A1sg
Verb	Verb	Pos|Prog1|Narr|A3pl
Verb	Verb	Pos|Prog1|Narr|A3sg
Verb	Verb	Pos|Prog1|Past|A1pl
Verb	Verb	Pos|Prog1|Past|A1sg
Verb	Verb	Pos|Prog1|Past|A2pl
Verb	Verb	Pos|Prog1|Past|A2sg
Verb	Verb	Pos|Prog1|Past|A3pl
Verb	Verb	Pos|Prog1|Past|A3sg
Verb	Verb	Pos|Prog2|A3sg
Verb	Verb	Pos|Prog2|Cop|A3pl
Verb	Verb	Pos|Prog2|Cop|A3sg
Verb	Verb	Pres|A1pl
Verb	Verb	Pres|A1sg
Verb	Verb	Pres|A2pl
Verb	Verb	Pres|A2sg
Verb	Verb	Pres|A3pl
Verb	Verb	Pres|A3sg
Verb	Verb	Pres|Cop|A2pl
Verb	Verb	Pres|Cop|A3pl
Verb	Verb	Pres|Cop|A3sg
Verb	Verb	Prog1|A1sg
Verb	Verb	Prog1|A2sg
Verb	Verb	Prog1|A3pl
Verb	Verb	Prog1|A3sg
Verb	Verb	Prog1|Past|A1sg
Verb	Verb	Prog1|Past|A3sg
Verb	Verb	Recip
Verb	Verb	Recip|Neg
Verb	Verb	Recip|Pos
Verb	Verb	Recip|Pos|Aor|A1pl
Verb	Verb	Recip|Pos|Imp|A2pl
Verb	Verb	Recip|Pos|Past|A1pl
Verb	Verb	Recip|Pos|Past|A3pl
Verb	Verb	Recip|Pos|Past|A3sg
Verb	Verb	Reflex
Verb	Verb	Reflex|Pos
Verb	Verb	Reflex|Pos|Narr|A3sg
Verb	Verb	Reflex|Pos|Past|A2pl
Verb	Verb	Reflex|Pos|Prog1|A3sg
Verb	Verb	Stay
Verb	Verb	Stay|Narr|A3sg
Verb	Verb	Stay|Narr|Past|A1pl
Verb	Verb	Stay|Narr|Past|A3sg
Verb	Verb	_
Verb	Zero	A3sg
Verb	Zero	Cond|A1sg
Verb	Zero	Cond|A3sg
Verb	Zero	Narr|A1pl
Verb	Zero	Narr|A1sg
Verb	Zero	Narr|A2sg
Verb	Zero	Narr|A3pl
Verb	Zero	Narr|A3sg
Verb	Zero	Past|A1pl
Verb	Zero	Past|A1sg
Verb	Zero	Past|A2pl
Verb	Zero	Past|A2sg
Verb	Zero	Past|A3pl
Verb	Zero	Past|A3sg
Verb	Zero	Pos|Imp|A2sg
Verb	Zero	Pres|A1pl
Verb	Zero	Pres|A1sg
Verb	Zero	Pres|A2pl
Verb	Zero	Pres|A2sg
Verb	Zero	Pres|A3pl
Verb	Zero	Pres|Cop|A2pl
Verb	Zero	Pres|Cop|A3pl
Verb	Zero	Pres|Cop|A3sg
Verb	Zero	_
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

Lingua::Interset::Tagset::TR::Conll - Driver for the Turkish tagset of the CoNLL 2007 Shared Task (derived from the METU Sabanci Treebank).

=head1 VERSION

version 3.011

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::TR::Conll;
  my $driver = Lingua::Interset::Tagset::TR::Conll->new();
  my $fs = $driver->decode("Noun\tNoun\tA3sg|Pnon|Nom");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('tr::conll', "Noun\tNoun\tA3sg|Pnon|Nom");

=head1 DESCRIPTION

Interset driver for the Turkish tagset of the CoNLL 2007 Shared Task.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT. For Turkish,
these values are derived from the tagset of the METU Sabanci Treebank.

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
