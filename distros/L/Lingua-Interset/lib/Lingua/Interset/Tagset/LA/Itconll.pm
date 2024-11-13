# ABSTRACT: Driver for the tagset of the Index Thomisticus Treebank in CoNLL format.
# Copyright © 2015 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::LA::Itconll;
use strict;
use warnings;
our $VERSION = '3.016';

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
    # The la::it and la::itconll drivers have mutually compatible values of the
    # other feature, thus they should use the same value of the tagset feature.
    return 'la::it';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
# On-line documentation of the tagset:
# http://itreebank.marginalia.it/tagset/IT_tagset.pdf
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # The tagset categorizes inflection patterns but it does not directly categorize
    # parts of speech. Thus we have
    # 1 nominal inflection ... includes nouns, pronouns, adjectives, determiners and numerals
    # 2 participial inflection ... something between 1 and 3: participles, gerunds and gerundives
    # 3 verbal inflection ... includes those verb forms that do not belong to 2
    # 4 no inflection ... includes adverbs, prepositions, conjunctions, particles and interjections
    # It would be correct to translate the inflection types to sets of parts of speech,
    # e.g. "1" would translate to "noun|adj|num". However, if the Interset feature structure
    # is later used to encode another physical tag, e.g. the universal POS tag, it would have to
    # randomly select one of these parts of speech. And then we want it to select a noun, not
    # adjective or even a numeral. To make things simpler, we will select just one part of speech
    # already on decoding.
    # FLEXIONAL TYPE ####################
    # This value appears in the CPOS column.
    $atoms{pos} = $self->create_atom
    (
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # nominal (only degrees and cases)
            '1'    => ['pos' => 'noun'], # noun|adj|num
            # participial
            '2'    => ['pos' => 'verb', 'verbform' => 'part'], # verb|adj
            # verbal
            '3'    => ['pos' => 'verb'],
            # invariable
            '4'    => ['pos' => 'part'], # adv|adp|conj|part|int
            # pseudo-lemma (e.g. abbreviation: corp., art., boet.)
            '5'    => ['abbr' => 'yes'],
            # punctuation
            'Punc' => ['pos' => 'punc']
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => '1',
                       'adj'  => { 'verbform' => { 'part' => '2',
                                                   'ger'  => '2',
                                                   'gdv'  => '2',
                                                   '@'    => '1' }},
                       'num'  => '1',
                       'verb' => { 'verbform' => { 'part' => '2',
                                                   'ger'  => '2',
                                                   'gdv'  => '2',
                                                   '@'    => '3' }},
                       'adv'  => '4',
                       'adp'  => '4',
                       'conj' => '4',
                       'part' => '4',
                       'int'  => '4',
                       'punc' => 'Punc',
                       '@'    => '5' }
        }
    );
    # FLEXIONAL CATEGORY ####################
    # This value appears in the POS column together with the flexional type.
    # For example, "F1" has CPOS=1 (nominal) and "F" = uninflected: example word "hoc".
    # The following POS values exist: A1, B1, C1, D1, E1, F1, G1, J2, K2, L2, M2, N2, J3, K3, L3, M3, N3, O4, S4, 5.
    $atoms{subpos} = $self->create_atom
    (
        'surfeature' => 'subpos',
        'decode_map' =>
        {
            # I declension (example: formam / forma)
            'A1' => ['pos' => 'noun', 'other' => {'flexcat' => 'idecl'}],
            # II declension (example: filio / filius)
            'B1' => ['pos' => 'noun', 'other' => {'flexcat' => 'iidecl'}],
            # III declension (example: imago / imago)
            'C1' => ['pos' => 'noun', 'other' => {'flexcat' => 'iiidecl'}],
            # IV declension (example: processu / processus)
            'D1' => ['pos' => 'noun', 'other' => {'flexcat' => 'ivdecl'}],
            # V declension (example: rerum / res)
            'E1' => ['pos' => 'noun', 'other' => {'flexcat' => 'vdecl'}],
            # regularly irregular declension (example: hoc / hic)
            'F1' => ['pos' => 'noun', 'other' => {'flexcat' => 'rirdecl'}],
            # uninflected nominal (example: quatuor)
            'G1' => ['pos' => 'noun', 'other' => {'flexcat' => 'nodecl'}],
            # I conjugation (example: formata / formo)
            'J2' => ['pos' => 'verb', 'verbform' => 'part', 'other' => {'flexcat' => 'iconj'}],
            'J3' => ['pos' => 'verb', 'other' => {'flexcat' => 'iconj'}],
            # II conjugation (example: manent / maneo)
            'K2' => ['pos' => 'verb', 'verbform' => 'part', 'other' => {'flexcat' => 'iiconj'}],
            'K3' => ['pos' => 'verb', 'other' => {'flexcat' => 'iiconj'}],
            # III conjugation (example: objicitur / objicio)
            'L2' => ['pos' => 'verb', 'verbform' => 'part', 'other' => {'flexcat' => 'iiiconj'}],
            'L3' => ['pos' => 'verb', 'other' => {'flexcat' => 'iiiconj'}],
            # IV conjugation (example: invenitur / invenio)
            'M2' => ['pos' => 'verb', 'verbform' => 'part', 'other' => {'flexcat' => 'ivconj'}],
            'M3' => ['pos' => 'verb', 'other' => {'flexcat' => 'ivconj'}],
            # regularly irregular conjugation (example: est / sum)
            'N2' => ['pos' => 'verb', 'verbform' => 'part', 'other' => {'flexcat' => 'rirconj'}],
            'N3' => ['pos' => 'verb', 'other' => {'flexcat' => 'rirconj'}],
            # invariable (example: et)
            'O4' => ['pos' => 'part', 'other' => {'flexcat' => 'invar'}],
            # prepositional (always or not) particle (examples: ad, contra, in, cum, per)
            'S4' => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'flexcat' => 'preppart'}],
            # pseudo-lemma / abbreviation
            '5'  => ['abbr' => 'yes'],
            # pseudo-lemma / number
            'G5' => ['pos' => 'num', 'numform' => 'digit'],
            # punctuation
            'Punc' => ['pos' => 'punc']
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'other/flexcat' => { 'idecl'    => 'A1',
                                                        'iidecl'   => 'B1',
                                                        'iiidecl'  => 'C1',
                                                        'ivdecl'   => 'D1',
                                                        'vdecl'    => 'E1',
                                                        'rirdecl'  => 'F1',
                                                        'nodecl'   => 'G1',
                                                        '@'        => { 'degree' => { ''  => 'G1',
                                                                                      '@' => 'A1' }}}},
                       'adj'  => { 'other/flexcat' => { 'idecl'    => 'A1',
                                                        'iidecl'   => 'B1',
                                                        'iiidecl'  => 'C1',
                                                        'ivdecl'   => 'D1',
                                                        'vdecl'    => 'E1',
                                                        'rirdecl'  => 'F1',
                                                        'nodecl'   => 'G1',
                                                        'iconj'    => 'J2',
                                                        'iiconj'   => 'K2',
                                                        'iiiconj'  => 'L2',
                                                        'ivconj'   => 'M2',
                                                        'rirconj'  => 'N2',
                                                        '@'        => { 'verbform' => { 'part' => 'J2',
                                                                                        'ger'  => 'J2',
                                                                                        'gdv'  => 'J2',
                                                                                        '@'    => { 'degree' => { ''  => 'G1',
                                                                                                                  '@' => 'A1' }}}}}},
                       'num'  => { 'other/flexcat' => { 'idecl'    => 'A1',
                                                        'iidecl'   => 'B1',
                                                        'iiidecl'  => 'C1',
                                                        'ivdecl'   => 'D1',
                                                        'vdecl'    => 'E1',
                                                        'rirdecl'  => 'F1',
                                                        'nodecl'   => 'G1',
                                                        '@'        => { 'degree' => { ''  => { 'numform' => { 'digit' => 'G5',
                                                                                                              '@'     => 'G1' }},
                                                                                      '@' => 'A1' }}}},
                       'verb' => { 'other/flexcat' => { 'iconj'    => { 'verbform' => { 'part' => 'J2',
                                                                                        'ger'  => 'J2',
                                                                                        'gdv'  => 'J2',
                                                                                        '@'    => 'J3' }},
                                                        'iiconj'   => { 'verbform' => { 'part' => 'K2',
                                                                                        'ger'  => 'K2',
                                                                                        'gdv'  => 'K2',
                                                                                        '@'    => 'K3' }},
                                                        'iiiconj'  => { 'verbform' => { 'part' => 'L2',
                                                                                        'ger'  => 'L2',
                                                                                        'gdv'  => 'L2',
                                                                                        '@'    => 'L3' }},
                                                        'ivconj'   => { 'verbform' => { 'part' => 'M2',
                                                                                        'ger'  => 'M2',
                                                                                        'gdv'  => 'M2',
                                                                                        '@'    => 'M3' }},
                                                        'rirconj'  => { 'verbform' => { 'part' => 'N2',
                                                                                        'ger'  => 'N2',
                                                                                        'gdv'  => 'N2',
                                                                                        '@'    => 'N3' }},
                                                        '@'        => { 'verbform' => { 'part' => 'J2',
                                                                                        'ger'  => 'J2',
                                                                                        'gdv'  => 'J2',
                                                                                        '@'    => 'J3' }}}},
                       'adp'  => 'S4',
                       'punc' => 'Punc',
                       '@'    => { 'other/flexcat' => { 'invar'    => 'O4',
                                                        'preppart' => 'S4',
                                                        '@'        => { 'abbr' => { 'yes' => '5',
                                                                                    '@'    => 'O4' }}}}}
        }
    );
    # NOMINAL DEGREE OF COMPARISON ####################
    $atoms{grn} = $self->create_atom
    (
        'surfeature' => 'grn',
        'decode_map' =>
        {
            'grn1' => ['degree' => 'pos'],
            'grn2' => ['degree' => 'cmp'],
            'grn3' => ['degree' => 'sup'],
            # not stable composition
            # examples: inquantum, necesse-esse, intantum, proculdubio
            'grn8' => ['other' => {'degree' => 'unstable'}]
        },
        'encode_map' =>
        {
            'degree' => { 'pos' => 'grn1',
                          'cmp' => 'grn2',
                          'sup' => 'grn3',
                          '@'   => { 'other/degree' => { 'unstable' => 'grn8' }}}
        }
    );
    # PARTICIPIAL DEGREE OF COMPARISON ####################
    $atoms{grp} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'grp1' => 'pos',
            'grp2' => 'cmp',
            'grp3' => 'sup'
        }
    );
    # MOOD ####################
    $atoms{mod} = $self->create_atom
    (
        'surfeature' => 'mod',
        'decode_map' =>
        {
            # active indicative (est, sunt, potest, oportet, habet)
            'modA' => ['verbform' => 'fin', 'mood' => 'ind', 'voice' => 'act'],
            # passive / dep indicative (dicitur, fit, videtur, sequitur, invenitur)
            'modJ' => ['verbform' => 'fin', 'mood' => 'ind', 'voice' => 'pass'],
            # active subjunctive (sit, esset, sint, possit, habeat)
            'modB' => ['verbform' => 'fin', 'mood' => 'sub', 'voice' => 'act'],
            # passive / dep subjunctive (dicatur, fiat, sequeretur, uniatur, moveatur)
            'modK' => ['verbform' => 'fin', 'mood' => 'sub', 'voice' => 'pass'],
            # active imperative (puta, accipite, docete, quaerite, accipe)
            'modC' => ['verbform' => 'fin', 'mood' => 'imp', 'voice' => 'act'],
            # passive / dep imperative (intuere)
            'modL' => ['verbform' => 'fin', 'mood' => 'imp', 'voice' => 'pass'],
            # active participle (movens, agens, intelligens, existens, habens)
            'modD' => ['verbform' => 'part', 'voice' => 'act'],
            # passive / dep participle (ostensum, dictum, probatum, consequens, separata)
            'modM' => ['verbform' => 'part', 'voice' => 'pass'],
            # active gerund (essendi, agendo, cognoscendo, intelligendo, recipiendum)
            'modE' => ['verbform' => 'ger', 'voice' => 'act'],
            # passive gerund (loquendo, operando, operandum, loquendi, ratiocinando)
            'modN' => ['verbform' => 'ger', 'voice' => 'pass'],
            # passive / dep gerundive (dicendum, sciendum, considerandum, ostendendum, intelligendum)
            'modO' => ['verbform' => 'gdv', 'voice' => 'pass'],
            # active supine
            'modG' => ['verbform' => 'sup', 'voice' => 'act'],
            # passive / dep supine
            'modP' => ['verbform' => 'sup', 'voice' => 'pass'],
            # active infinitive (esse, intelligere, habere, dicere, facere)
            'modH' => ['verbform' => 'inf', 'voice' => 'act'],
            # passive / dep infinitive (dici, fieri, moveri, uniri, intelligi)
            'modQ' => ['verbform' => 'inf', 'voice' => 'pass']
        },
        'encode_map' =>
        {
            'voice' => { 'act'  => { 'verbform' => { 'fin'  => { 'mood' => { 'ind' => 'modA',
                                                                             'sub' => 'modB',
                                                                             'imp' => 'modC' }},
                                                     'part' => 'modD',
                                                     'ger'  => 'modE',
                                                     'gdv'  => 'modE',
                                                     'sup'  => 'modG',
                                                     '@'    => 'modH' }},
                         'pass' => { 'verbform' => { 'fin'  => { 'mood' => { 'ind' => 'modJ',
                                                                             'sub' => 'modK',
                                                                             'imp' => 'modL', }},
                                                     'part' => 'modM',
                                                     'ger'  => 'modN',
                                                     'gdv'  => 'modO',
                                                     'sup'  => 'modP',
                                                     '@'    => 'modQ' }}}
        }
    );
    # TENSE ####################
    $atoms{tem} = $self->create_atom
    (
        'surfeature' => 'tem',
        'decode_map' =>
        {
            # present (est, esse, sit, sunt, potest)
            'tem1' => ['tense' => 'pres'],
            # imperfect (esset, posset, essent, sequeretur, erat)
            'tem2' => ['tense' => 'imp', 'aspect' => 'imp'],
            # future (erit, sequetur, poterit, oportebit, habebit)
            'tem3' => ['tense' => 'fut'],
            # perfect (ostensum, dictum, probatum, fuit, separata)
            'tem4' => ['tense' => 'past', 'aspect' => 'perf'],
            # plusperfect (fuisset, dixerat, fecerat, accepisset, fuerat)
            'tem5' => ['tense' => 'pqp', 'aspect' => 'perf'],
            # future perfect (fuerit, voluerit, dixerint, dederit, exarserit)
            'tem6' => ['tense' => 'fut', 'aspect' => 'perf']
        },
        'encode_map' =>
        {
            'tense' => { 'pres' => 'tem1',
                         'past' => { 'aspect' => { 'imp'  => 'tem2',
                                                   'perf' => 'tem4',
                                                   '@'    => 'tem2' }},
                         'imp'  => 'tem2',
                         'pqp'  => 'tem5',
                         'fut'  => { 'aspect' => { 'perf' => 'tem6',
                                                   '@'    => 'tem3' }}}
        }
    );
    # CASE / NUMBER ####################
    $atoms{cas} = $self->create_atom
    (
        'surfeature' => 'cas',
        'decode_map' =>
        {
            # singular nominative (forma, quod, quae, deus, intellectus)
            'casA' => ['number' => 'sing', 'case' => 'nom'],
            # singular genitive (formae, eius, corporis, materiae, dei)
            'casB' => ['number' => 'sing', 'case' => 'gen'],
            # singular dative (ei, corpori, sibi, deo, formae)
            'casC' => ['number' => 'sing', 'case' => 'dat'],
            # singular accusative (formam, se, hoc, esse, materiam)
            'casD' => ['number' => 'sing', 'case' => 'acc'],
            # singular vocative (domine, praecipue, deus, expresse, maxime)
            'casE' => ['number' => 'sing', 'case' => 'voc'],
            # singular ablative (forma, materia, actu, potentia, quo)
            'casF' => ['number' => 'sing', 'case' => 'abl'],
            # adverbial (vero, solum, amplius, similiter, primo)
            'casG' => ['number' => 'sing', 'case' => 'loc'],
            # casus “plurimus” (hoc, se)
            'casH' => ['other' => {'case' => 'plurimus'}],
            # plural nominative (quae, formae, omnia, qui, substantiae)
            'casJ' => ['number' => 'plur', 'case' => 'nom'],
            # plural genitive (rerum, eorum, omnium, formarum, quorum)
            'casK' => ['number' => 'plur', 'case' => 'gen'],
            # plural dative (eis, nobis, corporibus, aliis, omnibus)
            'casL' => ['number' => 'plur', 'case' => 'dat'],
            # plural accusative (formas, se, omnia, ea, quae)
            'casM' => ['number' => 'plur', 'case' => 'acc'],
            # plural vocative
            'casN' => ['number' => 'plur', 'case' => 'voc'],
            # plural ablative (rebus, quibus, his, aliis, omnibus)
            'casO' => ['number' => 'plur', 'case' => 'abl']
        },
        'encode_map' =>
        {
            'number' => { 'plur' => { 'case' => { 'nom' => 'casJ',
                                                  'gen' => 'casK',
                                                  'dat' => 'casL',
                                                  'acc' => 'casM',
                                                  'voc' => 'casN',
                                                  'abl' => 'casO' }},
                          '@'    => { 'case' => { 'nom' => 'casA',
                                                  'gen' => 'casB',
                                                  'dat' => 'casC',
                                                  'acc' => 'casD',
                                                  'voc' => 'casE',
                                                  'abl' => 'casF',
                                                  'loc' => 'casG',
                                                  '@'   => { 'other/case' => { 'plurimus' => 'casH' }}}}}
        }
    );
    # GENDER / NUMBER / PERSON ####################
    $atoms{gen} = $self->create_atom
    (
        'surfeature' => 'gen',
        'decode_map' =>
        {
            # masculine (intellectus, deus, actu, qui, deo)
            'gen1' => ['gender' => 'masc'],
            # feminine (forma, formam, formae, quae, materia)
            'gen2' => ['gender' => 'fem'],
            # neuter (quod, hoc, esse, quae, aliquid)
            'gen3' => ['gender' => 'neut'],
            # I singular (dico, respondeo, ostendi, attribui, baptizo)
            'gen4' => ['number' => 'sing', 'person' => '1'],
            # II singular (puta, facisti, es, odisti, dicas)
            'gen5' => ['number' => 'sing', 'person' => '2'],
            # III singular (est, sit, potest, oportet, habet)
            'gen6' => ['number' => 'sing', 'person' => '3'],
            # I plural (dicimus, videmus, possumus, intelligimus, cognoscimus)
            'gen7' => ['number' => 'plur', 'person' => '1'],
            # II plural (accipite, docete, estis, quaerite, ambuletis)
            'gen8' => ['number' => 'plur', 'person' => '2'],
            # III plural (sunt, sint, habent, possunt, dicuntur)
            'gen9' => ['number' => 'plur', 'person' => '3']
        },
        'encode_map' =>
        {
            'gender' => { 'masc' => 'gen1',
                          'fem'  => 'gen2',
                          'neut' => 'gen3',
                          '@'    => { 'person' => { '1' => { 'number' => { 'sing' => 'gen4',
                                                                           '@'    => 'gen7' }},
                                                    '2' => { 'number' => { 'sing' => 'gen5',
                                                                           '@'    => 'gen8' }},
                                                    '3' => { 'number' => { 'sing' => 'gen6',
                                                                           '@'    => 'gen9' }}}}}
        }
    );
    # COMPOSITION ####################
    $atoms{com} = $self->create_atom
    (
        'surfeature' => 'com',
        'decode_map' =>
        {
            # enclitic -ce
            'comA' => ['other' => {'com' => 'ce'}],
            # enclitic -cum (nobiscum, secum)
            'comC' => ['other' => {'com' => 'cum'}],
            # enclitic -met (ipsemet, ipsamet, ipsammet, ipsummet)
            'comM' => ['other' => {'com' => 'met'}],
            # enclitic -ne
            'comN' => ['other' => {'com' => 'ne'}],
            # enclitic -que (namque, corpori, eam, eandem, earumque)
            'comQ' => ['other' => {'com' => 'que'}],
            # enclitic -tenus (aliquatenus, quatenus)
            'comT' => ['other' => {'com' => 'tenus'}],
            # enclitic -ve (quid)
            'comV' => ['other' => {'com' => 've'}],
            # ending homographic with enclitic (ratione, absque, quandoque, utrumque, cognitione)
            'comH' => ['other' => {'com' => 'homographic'}],
            # composed with other form (inquantum, necesse-esse, intantum, proculdubio)
            'comZ' => ['other' => {'com' => 'other'}],
            # composed as lemma
            'comW' => ['other' => {'com' => 'lemma'}]
        },
        'encode_map' =>
        {
            'other/com' => { 'ce'          => 'comA',
                             'cum'         => 'comC',
                             'met'         => 'comM',
                             'ne'          => 'comN',
                             'que'         => 'comQ',
                             'tenus'       => 'comT',
                             've'          => 'comV',
                             'homographic' => 'comH',
                             'other'       => 'comZ',
                             'lemma'       => 'comW' }
        }
    );
    # FORMAL VARIATION ####################
    $atoms{var} = $self->create_atom
    (
        'surfeature' => 'var',
        'decode_map' =>
        {
            # I variation of wordform (qua, aliquod, aliquis, quoddam, quis)
            'varA' => ['variant' => '1'],
            # II variation of wordform
            'varB' => ['variant' => '2'],
            # III variation of wordform (illuc)
            'varC' => ['variant' => '3'],
            # author mistake, or bad reading? (quod)
            'varx' => ['typo' => 'yes'],
            'varX' => ['typo' => 'yes']
        },
        'encode_map' =>
        {
            'typo' => { 'yes' => 'varX',
                        '@'    => { 'variant' => { ''  => '',
                                                   '1' => 'varA',
                                                   '2' => 'varB',
                                                   '@' => 'varC' }}}
        }
    );
    # GRAPHICAL VARIATION ####################
    $atoms{vgr} = $self->create_atom
    (
        'surfeature' => 'vgr',
        'decode_map' =>
        {
            # base form (sed, quae, ut, sicut, cum)
            'vgr1' => ['other' => {'vgr' => '1'}],
            # graphical variations of “1” (ex, ab, eius, huiusmodi, cuius)
            'vgr2' => ['other' => {'vgr' => '2'}],
            # (uniuscuiusque, cuiuscumque, 2-2, ioannis, joannem)
            'vgr3' => ['other' => {'vgr' => '3'}],
            # (joannis)
            'vgr4' => ['other' => {'vgr' => '4'}]
        },
        'encode_map' =>
        {
            'other/vgr' => { '1' => 'vgr1',
                             '2' => 'vgr2',
                             '3' => 'vgr3',
                             '4' => 'vgr4' }
        }
    );
    # SEMANTIC TYPE OF LEMMA ####################
    # This feature is stored separately in Index Thomisticus. In the CoNLL files, Marco Passarotti created an extra column for it.
    # We moved it as a new feature in the FEAT column. However, we currently do not treat it as a normal feature! It does not appear
    # in our list of known tags and we do not attempt to encode it. We only decode it.
    $atoms{st} = $self->create_atom
    (
        'surfeature' => 'st',
        'decode_map' =>
        {
            'stNP' => ['nountype' => 'prop']
        },
        'encode_map' =>
        {
            'nountype' => { '@' => '' }
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
    my @features = ('grn', 'mod', 'tem', 'grp', 'cas', 'gen', 'com', 'var', 'vgr', 'st');
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
        '1' => ['grn', 'cas', 'gen', 'com', 'var', 'vgr'],
        '2' => ['mod', 'tem', 'grp', 'cas', 'gen', 'var', 'vgr'],
        # grn: only "necesse-esse": grn8
        '3' => ['grn', 'mod', 'tem', 'gen', 'com', 'var', 'vgr'],
        '4' => ['grn', 'com', 'var', 'vgr'],
        '5' => ['vgr']
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
    $fs->set_tagset($self->get_tagset_id());
    my $atoms = $self->atoms();
    # Three components: coarse-grained pos, fine-grained pos, features
    # Only features with non-empty values appear in the tag.
    # example: N\nNC\ngender=common|number=sing|case=unmarked|def=indef
    my ($pos, $subpos, $features) = split(/\s+/, $tag);
    # The underscore character is used if there are no features.
    $features = '' if($features eq '_');
    my @features = split(/\|/, $features);
    $atoms->{subpos}->decode_and_merge_hard($subpos, $fs);
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
    my $subpos = $atoms->{subpos}->encode($fs);
    my $pos = $subpos;
    $pos =~ s/[^0-9]// unless($pos eq 'Punc');
    my $fpos = $pos;
    my $feature_names = $self->get_feature_names($fpos);
    my $value_only = 1;
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names, $value_only);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus: total 419 tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
1       A1      grn1|casA|gen1
1       A1      grn1|casA|gen1|varA
1       A1      grn1|casA|gen1|vgr1
1       A1      grn1|casA|gen2
1       A1      grn1|casA|gen2|varA
1       A1      grn1|casA|gen2|vgr1
1       A1      grn1|casA|gen2|vgr2
1       A1      grn1|casA|gen3
1       A1      grn1|casA|gen3|varA
1       A1      grn1|casB|gen1
1       A1      grn1|casB|gen1|vgr1
1       A1      grn1|casB|gen2
1       A1      grn1|casB|gen2|vgr1
1       A1      grn1|casB|gen2|vgr2
1       A1      grn1|casB|gen3
1       A1      grn1|casC|gen1
1       A1      grn1|casC|gen1|vgr1
1       A1      grn1|casC|gen2
1       A1      grn1|casC|gen2|vgr1
1       A1      grn1|casC|gen3
1       A1      grn1|casD|gen1
1       A1      grn1|casD|gen1|varA
1       A1      grn1|casD|gen2
1       A1      grn1|casD|gen2|varA
1       A1      grn1|casD|gen2|vgr1
1       A1      grn1|casD|gen2|vgr2
1       A1      grn1|casD|gen3
1       A1      grn1|casD|gen3|varA
1       A1      grn1|casE|gen1
1       A1      grn1|casF|gen1
1       A1      grn1|casF|gen2
1       A1      grn1|casF|gen2|varA
1       A1      grn1|casF|gen2|vgr1
1       A1      grn1|casF|gen2|vgr2
1       A1      grn1|casF|gen3
1       A1      grn1|casG
1       A1      grn1|casG|varA
1       A1      grn1|casG|varC
1       A1      grn1|casJ|gen1
1       A1      grn1|casJ|gen1|vgr1
1       A1      grn1|casJ|gen1|vgr2
1       A1      grn1|casJ|gen2
1       A1      grn1|casJ|gen2|varA
1       A1      grn1|casJ|gen2|vgr1
1       A1      grn1|casJ|gen3
1       A1      grn1|casJ|gen3|varA
1       A1      grn1|casJ|gen3|vgr1
1       A1      grn1|casK|gen1
1       A1      grn1|casK|gen1|vgr2
1       A1      grn1|casK|gen2
1       A1      grn1|casK|gen2|vgr1
1       A1      grn1|casK|gen3
1       A1      grn1|casL|gen1
1       A1      grn1|casL|gen2
1       A1      grn1|casL|gen2|vgr1
1       A1      grn1|casL|gen3
1       A1      grn1|casM|gen1
1       A1      grn1|casM|gen2
1       A1      grn1|casM|gen2|varA
1       A1      grn1|casM|gen2|vgr1
1       A1      grn1|casM|gen3
1       A1      grn1|casM|gen3|vgr1
1       A1      grn1|casO|gen1
1       A1      grn1|casO|gen1|vgr1
1       A1      grn1|casO|gen2
1       A1      grn1|casO|gen2|vgr1
1       A1      grn1|casO|gen3
1       A1      grn1|casO|gen3|vgr1
1       A1      grn1|gen2
1       A1      grn2|casA|gen1
1       A1      grn2|casA|gen2
1       A1      grn2|casA|gen3
1       A1      grn2|casB|gen1
1       A1      grn2|casB|gen2
1       A1      grn2|casB|gen3
1       A1      grn2|casC|gen1
1       A1      grn2|casC|gen2
1       A1      grn2|casC|gen3
1       A1      grn2|casD|gen1
1       A1      grn2|casD|gen2
1       A1      grn2|casD|gen3
1       A1      grn2|casF|gen1
1       A1      grn2|casF|gen2
1       A1      grn2|casF|gen3
1       A1      grn2|casG
1       A1      grn2|casJ|gen1
1       A1      grn2|casJ|gen2
1       A1      grn2|casJ|gen3
1       A1      grn2|casK|gen1
1       A1      grn2|casK|gen2
1       A1      grn2|casK|gen3
1       A1      grn2|casL|gen1
1       A1      grn2|casL|gen2
1       A1      grn2|casL|gen3
1       A1      grn2|casM|gen1
1       A1      grn2|casM|gen2
1       A1      grn2|casM|gen3
1       A1      grn2|casO|gen1
1       A1      grn2|casO|gen2
1       A1      grn2|casO|gen3
1       A1      grn3|casA|gen1
1       A1      grn3|casA|gen2
1       A1      grn3|casA|gen2|vgr1
1       A1      grn3|casA|gen3
1       A1      grn3|casB|gen1
1       A1      grn3|casB|gen2
1       A1      grn3|casB|gen3
1       A1      grn3|casC|gen1
1       A1      grn3|casC|gen2
1       A1      grn3|casC|gen3
1       A1      grn3|casD|gen1
1       A1      grn3|casD|gen2
1       A1      grn3|casD|gen3
1       A1      grn3|casE|gen1
1       A1      grn3|casF|gen1
1       A1      grn3|casF|gen2
1       A1      grn3|casF|gen3
1       A1      grn3|casG
1       A1      grn3|casJ|gen1
1       A1      grn3|casJ|gen2
1       A1      grn3|casJ|gen3
1       A1      grn3|casJ|gen3|varA
1       A1      grn3|casK|gen1
1       A1      grn3|casK|gen2
1       A1      grn3|casK|gen3
1       A1      grn3|casL|gen3
1       A1      grn3|casM|gen1
1       A1      grn3|casM|gen2
1       A1      grn3|casM|gen3
1       A1      grn3|casO|gen2
1       A1      grn3|casO|gen3
1       B1      grn1|casA|gen1
1       B1      grn1|casA|gen1|vgr1
1       B1      grn1|casA|gen1|vgr2
1       B1      grn1|casA|gen2
1       B1      grn1|casA|gen2|vgr1
1       B1      grn1|casA|gen2|vgr2
1       B1      grn1|casA|gen3
1       B1      grn1|casA|gen3|comH
1       B1      grn1|casA|gen3|vgr1
1       B1      grn1|casA|gen3|vgr2
1       B1      grn1|casB|gen1
1       B1      grn1|casB|gen1|vgr1
1       B1      grn1|casB|gen1|vgr2
1       B1      grn1|casB|gen2
1       B1      grn1|casB|gen3
1       B1      grn1|casB|gen3|vgr1
1       B1      grn1|casB|gen3|vgr2
1       B1      grn1|casC|gen1
1       B1      grn1|casC|gen1|vgr1
1       B1      grn1|casC|gen2
1       B1      grn1|casC|gen3
1       B1      grn1|casC|gen3|vgr1
1       B1      grn1|casC|gen3|vgr2
1       B1      grn1|casD|gen1
1       B1      grn1|casD|gen1|vgr1
1       B1      grn1|casD|gen2
1       B1      grn1|casD|gen2|vgr2
1       B1      grn1|casD|gen3
1       B1      grn1|casD|gen3|vgr1
1       B1      grn1|casD|gen3|vgr2
1       B1      grn1|casE|gen1
1       B1      grn1|casE|gen1|comH
1       B1      grn1|casE|gen1|vgr1
1       B1      grn1|casF|gen1
1       B1      grn1|casF|gen1|vgr1
1       B1      grn1|casF|gen3
1       B1      grn1|casF|gen3|vgr1
1       B1      grn1|casF|gen3|vgr2
1       B1      grn1|casG
1       B1      grn1|casG|comH
1       B1      grn1|casG|comH|vgr1
1       B1      grn1|casG|vgr1
1       B1      grn1|casG|vgr2
1       B1      grn1|casJ|gen1
1       B1      grn1|casJ|gen1|vgr1
1       B1      grn1|casJ|gen1|vgr2
1       B1      grn1|casJ|gen2
1       B1      grn1|casJ|gen3
1       B1      grn1|casJ|gen3|vgr1
1       B1      grn1|casJ|gen3|vgr2
1       B1      grn1|casK|gen1
1       B1      grn1|casK|gen1|vgr1
1       B1      grn1|casK|gen1|vgr2
1       B1      grn1|casK|gen2
1       B1      grn1|casK|gen3
1       B1      grn1|casK|gen3|vgr1
1       B1      grn1|casK|gen3|vgr2
1       B1      grn1|casL|gen1
1       B1      grn1|casL|gen1|vgr1
1       B1      grn1|casL|gen3
1       B1      grn1|casL|gen3|vgr1
1       B1      grn1|casM|gen1
1       B1      grn1|casM|gen1|vgr1
1       B1      grn1|casM|gen3
1       B1      grn1|casM|gen3|vgr1
1       B1      grn1|casM|gen3|vgr2
1       B1      grn1|casO|gen1
1       B1      grn1|casO|gen1|vgr1
1       B1      grn1|casO|gen2
1       B1      grn1|casO|gen2|vgr1
1       B1      grn1|casO|gen3
1       B1      grn1|casO|gen3|vgr1
1       B1      grn1|casO|gen3|vgr2
1       B1      grn2|casA|gen3|vgr1
1       B1      grn2|casD|gen3|vgr1
1       B1      grn2|casG|vgr1
1       B1      grn3|casA|gen1
1       B1      grn3|casA|gen2
1       B1      grn3|casA|gen3
1       B1      grn3|casB|gen1
1       B1      grn3|casB|gen3
1       B1      grn3|casC|gen1
1       B1      grn3|casC|gen3
1       B1      grn3|casD|gen1
1       B1      grn3|casD|gen2
1       B1      grn3|casD|gen3
1       B1      grn3|casE|gen1
1       B1      grn3|casF|gen1
1       B1      grn3|casF|gen3
1       B1      grn3|casG
1       B1      grn3|casG|comQ
1       B1      grn3|casG|vgr1
1       B1      grn3|casJ|gen1
1       B1      grn3|casJ|gen3
1       B1      grn3|casJ|gen3|varA
1       B1      grn3|casK|gen1
1       B1      grn3|casK|gen3
1       B1      grn3|casL|gen3
1       B1      grn3|casM|gen1
1       B1      grn3|casM|gen3
1       B1      grn3|casO|gen3
1       C1      grn1|casA|gen1
1       C1      grn1|casA|gen1|vgr1
1       C1      grn1|casA|gen1|vgr2
1       C1      grn1|casA|gen2
1       C1      grn1|casA|gen2|vgr1
1       C1      grn1|casA|gen2|vgr2
1       C1      grn1|casA|gen3
1       C1      grn1|casA|gen3|vgr1
1       C1      grn1|casB|gen1
1       C1      grn1|casB|gen1|vgr1
1       C1      grn1|casB|gen1|vgr3
1       C1      grn1|casB|gen1|vgr4
1       C1      grn1|casB|gen2
1       C1      grn1|casB|gen2|vgr1
1       C1      grn1|casB|gen2|vgr2
1       C1      grn1|casB|gen3
1       C1      grn1|casB|gen3|vgr1
1       C1      grn1|casB|gen3|vgr2
1       C1      grn1|casC|gen1
1       C1      grn1|casC|gen1|vgr1
1       C1      grn1|casC|gen1|vgr2
1       C1      grn1|casC|gen2
1       C1      grn1|casC|gen2|vgr1
1       C1      grn1|casC|gen3
1       C1      grn1|casC|gen3|comQ
1       C1      grn1|casC|gen3|vgr1
1       C1      grn1|casD|gen1
1       C1      grn1|casD|gen1|vgr1
1       C1      grn1|casD|gen1|vgr3
1       C1      grn1|casD|gen2
1       C1      grn1|casD|gen2|vgr1
1       C1      grn1|casD|gen2|vgr2
1       C1      grn1|casD|gen3
1       C1      grn1|casD|gen3|comH
1       C1      grn1|casD|gen3|varA
1       C1      grn1|casD|gen3|vgr1
1       C1      grn1|casE|gen1
1       C1      grn1|casF|gen1
1       C1      grn1|casF|gen1|comH
1       C1      grn1|casF|gen1|vgr1
1       C1      grn1|casF|gen2
1       C1      grn1|casF|gen2|comH
1       C1      grn1|casF|gen2|comH|vgr1
1       C1      grn1|casF|gen2|comH|vgr2
1       C1      grn1|casF|gen2|vgr1
1       C1      grn1|casF|gen3
1       C1      grn1|casF|gen3|comH
1       C1      grn1|casF|gen3|comH|vgr1
1       C1      grn1|casF|gen3|vgr1
1       C1      grn1|casG
1       C1      grn1|casG|vgr1
1       C1      grn1|casG|vgr2
1       C1      grn1|casJ|gen1
1       C1      grn1|casJ|gen1|vgr1
1       C1      grn1|casJ|gen2
1       C1      grn1|casJ|gen2|vgr1
1       C1      grn1|casJ|gen2|vgr2
1       C1      grn1|casJ|gen3
1       C1      grn1|casJ|gen3|vgr1
1       C1      grn1|casK|gen1
1       C1      grn1|casK|gen1|vgr1
1       C1      grn1|casK|gen2
1       C1      grn1|casK|gen2|vgr1
1       C1      grn1|casK|gen3
1       C1      grn1|casK|gen3|vgr1
1       C1      grn1|casL|gen1
1       C1      grn1|casL|gen1|vgr1
1       C1      grn1|casL|gen2
1       C1      grn1|casL|gen2|vgr1
1       C1      grn1|casL|gen2|vgr2
1       C1      grn1|casL|gen3
1       C1      grn1|casL|gen3|vgr1
1       C1      grn1|casM|gen1
1       C1      grn1|casM|gen1|vgr1
1       C1      grn1|casM|gen2
1       C1      grn1|casM|gen2|vgr1
1       C1      grn1|casM|gen2|vgr2
1       C1      grn1|casM|gen3
1       C1      grn1|casM|gen3|vgr1
1       C1      grn1|casO|gen1
1       C1      grn1|casO|gen1|vgr1
1       C1      grn1|casO|gen1|vgr2
1       C1      grn1|casO|gen2
1       C1      grn1|casO|gen2|vgr1
1       C1      grn1|casO|gen2|vgr2
1       C1      grn1|casO|gen3
1       C1      grn1|casO|gen3|vgr1
1       C1      grn2|casA|gen1
1       C1      grn2|casA|gen1|vgr1
1       C1      grn2|casA|gen1|vgr2
1       C1      grn2|casA|gen2
1       C1      grn2|casA|gen2|vgr1
1       C1      grn2|casA|gen2|vgr2
1       C1      grn2|casA|gen3
1       C1      grn2|casA|gen3|vgr1
1       C1      grn2|casA|gen3|vgr2
1       C1      grn2|casB|gen1
1       C1      grn2|casB|gen1|vgr1
1       C1      grn2|casB|gen2
1       C1      grn2|casB|gen2|vgr1
1       C1      grn2|casB|gen2|vgr2
1       C1      grn2|casB|gen3
1       C1      grn2|casC|gen1
1       C1      grn2|casC|gen2
1       C1      grn2|casC|gen3
1       C1      grn2|casD|gen1
1       C1      grn2|casD|gen1|vgr2
1       C1      grn2|casD|gen2
1       C1      grn2|casD|gen2|vgr1
1       C1      grn2|casD|gen2|vgr2
1       C1      grn2|casD|gen3
1       C1      grn2|casD|gen3|vgr2
1       C1      grn2|casF|gen1
1       C1      grn2|casF|gen2
1       C1      grn2|casF|gen2|vgr2
1       C1      grn2|casF|gen3
1       C1      grn2|casF|gen3|vgr2
1       C1      grn2|casG
1       C1      grn2|casG|vgr1
1       C1      grn2|casJ|gen1
1       C1      grn2|casJ|gen1|vgr2
1       C1      grn2|casJ|gen2
1       C1      grn2|casJ|gen3
1       C1      grn2|casJ|gen3|vgr1
1       C1      grn2|casK|gen1
1       C1      grn2|casK|gen2
1       C1      grn2|casK|gen3
1       C1      grn2|casL|gen1
1       C1      grn2|casL|gen2
1       C1      grn2|casL|gen3
1       C1      grn2|casM|gen1
1       C1      grn2|casM|gen2
1       C1      grn2|casM|gen3
1       C1      grn2|casM|gen3|vgr2
1       C1      grn2|casO|gen1
1       C1      grn2|casO|gen2
1       C1      grn2|casO|gen3
1       C1      grn3|casG|vgr1
1       D1      grn1|casA|gen1
1       D1      grn1|casA|gen1|vgr1
1       D1      grn1|casA|gen2
1       D1      grn1|casA|gen3
1       D1      grn1|casB|gen1
1       D1      grn1|casB|gen1|vgr1
1       D1      grn1|casB|gen2
1       D1      grn1|casC|gen1
1       D1      grn1|casC|gen2
1       D1      grn1|casC|gen3
1       D1      grn1|casD|gen1
1       D1      grn1|casD|gen1|vgr1
1       D1      grn1|casD|gen2
1       D1      grn1|casD|gen3
1       D1      grn1|casF|gen1
1       D1      grn1|casF|gen1|vgr1
1       D1      grn1|casF|gen2
1       D1      grn1|casF|gen3
1       D1      grn1|casG
1       D1      grn1|casJ|gen1
1       D1      grn1|casJ|gen3
1       D1      grn1|casK|gen1
1       D1      grn1|casK|gen2
1       D1      grn1|casL|gen1
1       D1      grn1|casM|gen1
1       D1      grn1|casM|gen2
1       D1      grn1|casO|gen1
1       D1      grn1|casO|gen3
1       E1      grn1|casA|gen1
1       E1      grn1|casA|gen2
1       E1      grn1|casA|gen2|vgr1
1       E1      grn1|casB|gen1
1       E1      grn1|casB|gen2
1       E1      grn1|casC|gen2
1       E1      grn1|casD|gen1
1       E1      grn1|casD|gen2
1       E1      grn1|casF|gen1
1       E1      grn1|casF|gen2
1       E1      grn1|casG
1       E1      grn1|casJ|gen1
1       E1      grn1|casJ|gen2
1       E1      grn1|casK|gen1
1       E1      grn1|casK|gen2
1       E1      grn1|casK|gen3
1       E1      grn1|casL|gen2
1       E1      grn1|casM|gen1
1       E1      grn1|casM|gen2
1       E1      grn1|casO|gen1
1       E1      grn1|casO|gen2
1       F1      grn1|casA|gen1
1       F1      grn1|casA|gen1|comH
1       F1      grn1|casA|gen1|comM
1       F1      grn1|casA|gen1|varA
1       F1      grn1|casA|gen1|vgr1
1       F1      grn1|casA|gen1|vgr2
1       F1      grn1|casA|gen2
1       F1      grn1|casA|gen2|comH
1       F1      grn1|casA|gen2|comM
1       F1      grn1|casA|gen2|comT
1       F1      grn1|casA|gen2|varA
1       F1      grn1|casA|gen2|vgr1
1       F1      grn1|casA|gen2|vgr2
1       F1      grn1|casA|gen3
1       F1      grn1|casA|gen3|comH|vgr2
1       F1      grn1|casA|gen3|comM
1       F1      grn1|casA|gen3|comV
1       F1      grn1|casA|gen3|varA
1       F1      grn1|casA|gen3|vgr1
1       F1      grn1|casA|gen3|vgr2
1       F1      grn1|casB|gen1
1       F1      grn1|casB|gen1|comH
1       F1      grn1|casB|gen1|vgr1
1       F1      grn1|casB|gen1|vgr2
1       F1      grn1|casB|gen2
1       F1      grn1|casB|gen2|comH
1       F1      grn1|casB|gen2|vgr1
1       F1      grn1|casB|gen2|vgr2
1       F1      grn1|casB|gen2|vgr3
1       F1      grn1|casB|gen3
1       F1      grn1|casB|gen3|comH
1       F1      grn1|casB|gen3|vgr1
1       F1      grn1|casB|gen3|vgr2
1       F1      grn1|casB|gen3|vgr3
1       F1      grn1|casC|gen1
1       F1      grn1|casC|gen1|comH
1       F1      grn1|casC|gen1|vgr1
1       F1      grn1|casC|gen2
1       F1      grn1|casC|gen2|vgr1
1       F1      grn1|casC|gen3
1       F1      grn1|casC|gen3|comH
1       F1      grn1|casD|gen1
1       F1      grn1|casD|gen1|varA
1       F1      grn1|casD|gen1|vgr1
1       F1      grn1|casD|gen1|vgr2
1       F1      grn1|casD|gen2
1       F1      grn1|casD|gen2|comH|vgr2
1       F1      grn1|casD|gen2|comM
1       F1      grn1|casD|gen2|comQ
1       F1      grn1|casD|gen2|comQ|vgr1
1       F1      grn1|casD|gen2|varA
1       F1      grn1|casD|gen2|vgr1
1       F1      grn1|casD|gen2|vgr2
1       F1      grn1|casD|gen3
1       F1      grn1|casD|gen3|comH|vgr2
1       F1      grn1|casD|gen3|varA
1       F1      grn1|casD|gen3|vgr1
1       F1      grn1|casD|gen3|vgr2
1       F1      grn1|casE|gen1
1       F1      grn1|casF|gen1
1       F1      grn1|casF|gen1|comH
1       F1      grn1|casF|gen1|comH|vgr2
1       F1      grn1|casF|gen1|vgr1
1       F1      grn1|casF|gen2
1       F1      grn1|casF|gen2|comC
1       F1      grn1|casF|gen2|comH
1       F1      grn1|casF|gen2|comH|vgr2
1       F1      grn1|casF|gen2|comT
1       F1      grn1|casF|gen2|varA
1       F1      grn1|casF|gen2|vgr1
1       F1      grn1|casF|gen3
1       F1      grn1|casF|gen3|comC
1       F1      grn1|casF|gen3|comH
1       F1      grn1|casF|gen3|comH|vgr2
1       F1      grn1|casF|gen3|vgr1
1       F1      grn1|casG
1       F1      grn1|casG|varA
1       F1      grn1|casG|varC
1       F1      grn1|casG|vgr1
1       F1      grn1|casJ|gen1
1       F1      grn1|casJ|gen1|vgr1
1       F1      grn1|casJ|gen1|vgr2
1       F1      grn1|casJ|gen2
1       F1      grn1|casJ|gen2|varA
1       F1      grn1|casJ|gen2|vgr1
1       F1      grn1|casJ|gen2|vgr2
1       F1      grn1|casJ|gen3
1       F1      grn1|casJ|gen3|varA
1       F1      grn1|casJ|gen3|vgr1
1       F1      grn1|casJ|gen3|vgr2
1       F1      grn1|casK|gen1
1       F1      grn1|casK|gen1|vgr1
1       F1      grn1|casK|gen1|vgr2
1       F1      grn1|casK|gen2
1       F1      grn1|casK|gen2|comQ
1       F1      grn1|casK|gen2|vgr1
1       F1      grn1|casK|gen2|vgr2
1       F1      grn1|casK|gen3
1       F1      grn1|casK|gen3|vgr1
1       F1      grn1|casK|gen3|vgr2
1       F1      grn1|casL|gen1
1       F1      grn1|casL|gen1|comC
1       F1      grn1|casL|gen1|vgr1
1       F1      grn1|casL|gen2
1       F1      grn1|casL|gen2|vgr1
1       F1      grn1|casL|gen3
1       F1      grn1|casL|gen3|comH|vgr2
1       F1      grn1|casL|gen3|vgr1
1       F1      grn1|casM|gen1
1       F1      grn1|casM|gen1|comH
1       F1      grn1|casM|gen1|vgr1
1       F1      grn1|casM|gen2
1       F1      grn1|casM|gen2|comH
1       F1      grn1|casM|gen2|varA
1       F1      grn1|casM|gen2|vgr1
1       F1      grn1|casM|gen3
1       F1      grn1|casM|gen3|comH|vgr2
1       F1      grn1|casM|gen3|vgr1
1       F1      grn1|casM|gen3|vgr2
1       F1      grn1|casO|gen1
1       F1      grn1|casO|gen1|comC
1       F1      grn1|casO|gen1|comH
1       F1      grn1|casO|gen1|comH|vgr2
1       F1      grn1|casO|gen1|vgr1
1       F1      grn1|casO|gen1|vgr2
1       F1      grn1|casO|gen2
1       F1      grn1|casO|gen2|comC
1       F1      grn1|casO|gen2|comH|vgr2
1       F1      grn1|casO|gen2|vgr1
1       F1      grn1|casO|gen3
1       F1      grn1|casO|gen3|comH
1       F1      grn1|casO|gen3|comH|vgr2
1       F1      grn1|casO|gen3|vgr1
1       G1      _
1       G1      casA|gen3
1       G1      casA|gen3|vgr1
1       G1      casB|gen3
1       G1      casC|gen3
1       G1      casD|gen3
1       G1      casD|gen3|vgr1
1       G1      casF|gen3
2       J2      modD|tem1|grp1|casA|gen1
2       J2      modD|tem1|grp1|casA|gen1|vgr1
2       J2      modD|tem1|grp1|casA|gen2
2       J2      modD|tem1|grp1|casA|gen2|vgr1
2       J2      modD|tem1|grp1|casA|gen3
2       J2      modD|tem1|grp1|casB|gen1
2       J2      modD|tem1|grp1|casB|gen1|vgr2
2       J2      modD|tem1|grp1|casB|gen2
2       J2      modD|tem1|grp1|casB|gen3
2       J2      modD|tem1|grp1|casC|gen1
2       J2      modD|tem1|grp1|casC|gen2
2       J2      modD|tem1|grp1|casC|gen3
2       J2      modD|tem1|grp1|casD|gen1
2       J2      modD|tem1|grp1|casD|gen2
2       J2      modD|tem1|grp1|casD|gen3
2       J2      modD|tem1|grp1|casD|gen3|vgr2
2       J2      modD|tem1|grp1|casF|gen1
2       J2      modD|tem1|grp1|casF|gen2
2       J2      modD|tem1|grp1|casF|gen3
2       J2      modD|tem1|grp1|casG
2       J2      modD|tem1|grp1|casJ|gen1
2       J2      modD|tem1|grp1|casJ|gen1|vgr1
2       J2      modD|tem1|grp1|casJ|gen2
2       J2      modD|tem1|grp1|casJ|gen3
2       J2      modD|tem1|grp1|casK|gen1
2       J2      modD|tem1|grp1|casK|gen2
2       J2      modD|tem1|grp1|casK|gen3
2       J2      modD|tem1|grp1|casL|gen1
2       J2      modD|tem1|grp1|casL|gen2
2       J2      modD|tem1|grp1|casL|gen3
2       J2      modD|tem1|grp1|casM|gen1
2       J2      modD|tem1|grp1|casM|gen2
2       J2      modD|tem1|grp1|casM|gen3
2       J2      modD|tem1|grp1|casM|gen3|vgr1
2       J2      modD|tem1|grp1|casO|gen1
2       J2      modD|tem1|grp1|casO|gen2
2       J2      modD|tem1|grp1|casO|gen3
2       J2      modD|tem1|grp2|casA|gen1
2       J2      modD|tem1|grp2|casA|gen2
2       J2      modD|tem1|grp2|casA|gen3
2       J2      modD|tem1|grp2|casD|gen1
2       J2      modD|tem1|grp2|casD|gen2
2       J2      modD|tem1|grp2|casD|gen3
2       J2      modD|tem1|grp2|casG
2       J2      modD|tem1|grp3|casA|gen1
2       J2      modD|tem1|grp3|casA|gen2
2       J2      modD|tem1|grp3|casA|gen3
2       J2      modD|tem1|grp3|casB|gen1
2       J2      modD|tem1|grp3|casB|gen2
2       J2      modD|tem1|grp3|casB|gen3
2       J2      modD|tem1|grp3|casC|gen1
2       J2      modD|tem1|grp3|casC|gen2
2       J2      modD|tem1|grp3|casC|gen3
2       J2      modD|tem1|grp3|casD|gen1
2       J2      modD|tem1|grp3|casD|gen2
2       J2      modD|tem1|grp3|casD|gen3
2       J2      modD|tem3|grp1|casA|gen1
2       J2      modD|tem3|grp1|casA|gen1|vgr2
2       J2      modD|tem3|grp1|casA|gen2
2       J2      modD|tem3|grp1|casA|gen3
2       J2      modD|tem3|grp1|casB|gen1
2       J2      modD|tem3|grp1|casB|gen2
2       J2      modD|tem3|grp1|casB|gen3
2       J2      modD|tem3|grp1|casC|gen1
2       J2      modD|tem3|grp1|casC|gen2
2       J2      modD|tem3|grp1|casC|gen3
2       J2      modD|tem3|grp1|casD|gen1
2       J2      modD|tem3|grp1|casD|gen2
2       J2      modD|tem3|grp1|casD|gen3
2       J2      modD|tem3|grp1|casO|gen1
2       J2      modD|tem3|grp1|casO|gen2
2       J2      modD|tem3|grp1|casO|gen3
2       J2      modE|grp1|casB
2       J2      modE|grp1|casB|vgr1
2       J2      modE|grp1|casB|vgr2
2       J2      modE|grp1|casD
2       J2      modE|grp1|casD|vgr1
2       J2      modE|grp1|casD|vgr2
2       J2      modE|grp1|casF
2       J2      modE|grp1|casF|gen3
2       J2      modE|grp1|casF|vgr1
2       J2      modE|grp1|casF|vgr2
2       J2      modM|tem1|grp1|casA|gen1
2       J2      modM|tem1|grp1|casA|gen2
2       J2      modM|tem1|grp1|casA|gen3
2       J2      modM|tem1|grp1|casB|gen1
2       J2      modM|tem1|grp1|casB|gen2
2       J2      modM|tem1|grp1|casB|gen3
2       J2      modM|tem1|grp1|casC|gen1
2       J2      modM|tem1|grp1|casC|gen2
2       J2      modM|tem1|grp1|casC|gen3
2       J2      modM|tem1|grp1|casD|gen1
2       J2      modM|tem1|grp1|casD|gen2
2       J2      modM|tem1|grp1|casD|gen3
2       J2      modM|tem1|grp1|casF|gen1
2       J2      modM|tem1|grp1|casF|gen2
2       J2      modM|tem1|grp1|casF|gen3
2       J2      modM|tem1|grp1|casG
2       J2      modM|tem1|grp1|casJ|gen1
2       J2      modM|tem1|grp1|casJ|gen2
2       J2      modM|tem1|grp1|casJ|gen3
2       J2      modM|tem1|grp1|casK|gen1
2       J2      modM|tem1|grp1|casK|gen2
2       J2      modM|tem1|grp1|casK|gen3
2       J2      modM|tem1|grp1|casL|gen1
2       J2      modM|tem1|grp1|casL|gen2
2       J2      modM|tem1|grp1|casL|gen3
2       J2      modM|tem1|grp1|casM|gen1
2       J2      modM|tem1|grp1|casM|gen2
2       J2      modM|tem1|grp1|casM|gen3
2       J2      modM|tem1|grp1|casO|gen1
2       J2      modM|tem1|grp1|casO|gen2
2       J2      modM|tem1|grp1|casO|gen3
2       J2      modM|tem4|grp1|casA|gen1
2       J2      modM|tem4|grp1|casA|gen1|vgr2
2       J2      modM|tem4|grp1|casA|gen2
2       J2      modM|tem4|grp1|casA|gen2|varA
2       J2      modM|tem4|grp1|casA|gen2|vgr1
2       J2      modM|tem4|grp1|casA|gen3
2       J2      modM|tem4|grp1|casA|gen3|vgr1
2       J2      modM|tem4|grp1|casB|gen1
2       J2      modM|tem4|grp1|casB|gen2
2       J2      modM|tem4|grp1|casB|gen2|varA
2       J2      modM|tem4|grp1|casB|gen2|vgr1
2       J2      modM|tem4|grp1|casB|gen3
2       J2      modM|tem4|grp1|casB|gen3|vgr1
2       J2      modM|tem4|grp1|casC|gen1
2       J2      modM|tem4|grp1|casC|gen2
2       J2      modM|tem4|grp1|casC|gen2|vgr1
2       J2      modM|tem4|grp1|casC|gen3
2       J2      modM|tem4|grp1|casD|gen1
2       J2      modM|tem4|grp1|casD|gen2
2       J2      modM|tem4|grp1|casD|gen2|varA
2       J2      modM|tem4|grp1|casD|gen2|vgr1
2       J2      modM|tem4|grp1|casD|gen3
2       J2      modM|tem4|grp1|casD|gen3|vgr1
2       J2      modM|tem4|grp1|casE|gen1
2       J2      modM|tem4|grp1|casE|gen2
2       J2      modM|tem4|grp1|casE|gen3
2       J2      modM|tem4|grp1|casF|gen1
2       J2      modM|tem4|grp1|casF|gen2
2       J2      modM|tem4|grp1|casF|gen2|vgr1
2       J2      modM|tem4|grp1|casF|gen3
2       J2      modM|tem4|grp1|casG
2       J2      modM|tem4|grp1|casJ|gen1
2       J2      modM|tem4|grp1|casJ|gen1|vgr1
2       J2      modM|tem4|grp1|casJ|gen2
2       J2      modM|tem4|grp1|casJ|gen2|vgr1
2       J2      modM|tem4|grp1|casJ|gen3
2       J2      modM|tem4|grp1|casJ|gen3|vgr1
2       J2      modM|tem4|grp1|casK|gen1
2       J2      modM|tem4|grp1|casK|gen2
2       J2      modM|tem4|grp1|casK|gen3
2       J2      modM|tem4|grp1|casL
2       J2      modM|tem4|grp1|casL|gen1
2       J2      modM|tem4|grp1|casL|gen2
2       J2      modM|tem4|grp1|casL|gen3
2       J2      modM|tem4|grp1|casM|gen1
2       J2      modM|tem4|grp1|casM|gen2
2       J2      modM|tem4|grp1|casM|gen3
2       J2      modM|tem4|grp1|casM|gen3|vgr1
2       J2      modM|tem4|grp1|casO
2       J2      modM|tem4|grp1|casO|gen1
2       J2      modM|tem4|grp1|casO|gen2
2       J2      modM|tem4|grp1|casO|gen3
2       J2      modM|tem4|grp2|casA|gen1
2       J2      modM|tem4|grp2|casA|gen2
2       J2      modM|tem4|grp2|casA|gen3
2       J2      modM|tem4|grp2|casD|gen1
2       J2      modM|tem4|grp2|casD|gen2
2       J2      modM|tem4|grp2|casD|gen3
2       J2      modM|tem4|grp2|casG
2       J2      modM|tem4|grp2|casJ|gen1
2       J2      modM|tem4|grp2|casJ|gen2
2       J2      modM|tem4|grp2|casJ|gen3
2       J2      modM|tem4|grp2|casM|gen1
2       J2      modM|tem4|grp2|casM|gen2
2       J2      modM|tem4|grp2|casM|gen3
2       J2      modM|tem4|grp3|casA|gen1
2       J2      modM|tem4|grp3|casA|gen2
2       J2      modM|tem4|grp3|casA|gen3
2       J2      modM|tem4|grp3|casD|gen1
2       J2      modM|tem4|grp3|casD|gen2
2       J2      modM|tem4|grp3|casD|gen3
2       J2      modM|tem4|grp3|casJ|gen1
2       J2      modM|tem4|grp3|casJ|gen2
2       J2      modM|tem4|grp3|casJ|gen3
2       J2      modM|tem4|grp3|casM|gen1
2       J2      modM|tem4|grp3|casM|gen2
2       J2      modM|tem4|grp3|casM|gen3
2       J2      modN|grp1|casB
2       J2      modN|grp1|casD
2       J2      modN|grp1|casF
2       J2      modO|grp1|casA|gen1
2       J2      modO|grp1|casA|gen2
2       J2      modO|grp1|casA|gen2|vgr1
2       J2      modO|grp1|casA|gen3
2       J2      modO|grp1|casA|gen3|vgr1
2       J2      modO|grp1|casB|gen1
2       J2      modO|grp1|casB|gen2
2       J2      modO|grp1|casB|gen2|varA
2       J2      modO|grp1|casB|gen3
2       J2      modO|grp1|casC|gen1
2       J2      modO|grp1|casC|gen2
2       J2      modO|grp1|casC|gen3
2       J2      modO|grp1|casD|gen1
2       J2      modO|grp1|casD|gen2
2       J2      modO|grp1|casD|gen3
2       J2      modO|grp1|casF|gen1
2       J2      modO|grp1|casF|gen2
2       J2      modO|grp1|casF|gen3
2       J2      modO|grp1|casJ|gen1
2       J2      modO|grp1|casJ|gen2
2       J2      modO|grp1|casJ|gen3
2       J2      modO|grp1|casK|gen1
2       J2      modO|grp1|casK|gen2
2       J2      modO|grp1|casK|gen3
2       J2      modO|grp1|casM|gen1
2       J2      modO|grp1|casM|gen2
2       J2      modO|grp1|casM|gen3
2       J2      modO|grp1|casO|gen1
2       J2      modO|grp1|casO|gen2
2       J2      modO|grp1|casO|gen3
2       K2      modD|tem1|grp1|casA|gen1
2       K2      modD|tem1|grp1|casA|gen1|vgr1
2       K2      modD|tem1|grp1|casA|gen2
2       K2      modD|tem1|grp1|casA|gen2|vgr1
2       K2      modD|tem1|grp1|casA|gen2|vgr2
2       K2      modD|tem1|grp1|casA|gen3
2       K2      modD|tem1|grp1|casA|gen3|vgr1
2       K2      modD|tem1|grp1|casB|gen1
2       K2      modD|tem1|grp1|casB|gen1|vgr1
2       K2      modD|tem1|grp1|casB|gen2
2       K2      modD|tem1|grp1|casB|gen2|vgr1
2       K2      modD|tem1|grp1|casB|gen3
2       K2      modD|tem1|grp1|casC|gen1
2       K2      modD|tem1|grp1|casC|gen2
2       K2      modD|tem1|grp1|casC|gen3
2       K2      modD|tem1|grp1|casD|gen1
2       K2      modD|tem1|grp1|casD|gen2
2       K2      modD|tem1|grp1|casD|gen2|vgr2
2       K2      modD|tem1|grp1|casD|gen3
2       K2      modD|tem1|grp1|casD|gen3|vgr1
2       K2      modD|tem1|grp1|casF|gen1
2       K2      modD|tem1|grp1|casF|gen2
2       K2      modD|tem1|grp1|casF|gen2|vgr1
2       K2      modD|tem1|grp1|casF|gen2|vgr2
2       K2      modD|tem1|grp1|casF|gen3
2       K2      modD|tem1|grp1|casF|gen3|vgr2
2       K2      modD|tem1|grp1|casG
2       K2      modD|tem1|grp1|casJ|gen1
2       K2      modD|tem1|grp1|casJ|gen2
2       K2      modD|tem1|grp1|casJ|gen2|vgr1
2       K2      modD|tem1|grp1|casJ|gen3
2       K2      modD|tem1|grp1|casK|gen2
2       K2      modD|tem1|grp1|casK|gen3
2       K2      modD|tem1|grp1|casL|gen1
2       K2      modD|tem1|grp1|casL|gen3
2       K2      modD|tem1|grp1|casM|gen2
2       K2      modD|tem1|grp1|casM|gen3
2       K2      modD|tem1|grp1|casO|gen1
2       K2      modD|tem1|grp1|casO|gen2
2       K2      modD|tem1|grp1|casO|gen3
2       K2      modD|tem1|grp2|casA|gen2
2       K2      modD|tem1|grp2|casA|gen3
2       K2      modD|tem1|grp2|casD|gen1
2       K2      modD|tem1|grp2|casG
2       K2      modD|tem3|grp1|casA|gen1
2       K2      modD|tem3|grp1|casD|gen1
2       K2      modE|grp1|casB
2       K2      modE|grp1|casD
2       K2      modE|grp1|casF
2       K2      modE|grp1|casF|gen3
2       K2      modE|grp1|casF|vgr1
2       K2      modM|tem1|grp1|casJ|gen1
2       K2      modM|tem4|grp1|casA|gen1
2       K2      modM|tem4|grp1|casA|gen1|vgr1
2       K2      modM|tem4|grp1|casA|gen2
2       K2      modM|tem4|grp1|casA|gen2|vgr1
2       K2      modM|tem4|grp1|casA|gen3
2       K2      modM|tem4|grp1|casA|gen3|vgr1
2       K2      modM|tem4|grp1|casB|gen1
2       K2      modM|tem4|grp1|casB|gen2
2       K2      modM|tem4|grp1|casB|gen3
2       K2      modM|tem4|grp1|casB|gen3|vgr1
2       K2      modM|tem4|grp1|casC|gen3|vgr1
2       K2      modM|tem4|grp1|casD|gen1
2       K2      modM|tem4|grp1|casD|gen1|vgr1
2       K2      modM|tem4|grp1|casD|gen2
2       K2      modM|tem4|grp1|casD|gen2|vgr1
2       K2      modM|tem4|grp1|casD|gen3
2       K2      modM|tem4|grp1|casD|gen3|vgr1
2       K2      modM|tem4|grp1|casF|gen1
2       K2      modM|tem4|grp1|casF|gen2
2       K2      modM|tem4|grp1|casF|gen3
2       K2      modM|tem4|grp1|casF|gen3|vgr1
2       K2      modM|tem4|grp1|casG
2       K2      modM|tem4|grp1|casJ|gen1
2       K2      modM|tem4|grp1|casJ|gen2
2       K2      modM|tem4|grp1|casJ|gen3
2       K2      modM|tem4|grp1|casJ|gen3|vgr1
2       K2      modM|tem4|grp1|casK|gen3
2       K2      modM|tem4|grp1|casK|gen3|vgr1
2       K2      modM|tem4|grp1|casM|gen1
2       K2      modM|tem4|grp1|casM|gen2
2       K2      modM|tem4|grp1|casM|gen3
2       K2      modM|tem4|grp1|casM|gen3|vgr1
2       K2      modM|tem4|grp1|casO|gen1
2       K2      modM|tem4|grp1|casO|gen2
2       K2      modM|tem4|grp1|casO|gen3
2       K2      modM|tem4|grp1|casO|gen3|vgr1
2       K2      modM|tem4|grp2|casA|gen3
2       K2      modM|tem4|grp2|casD|gen3
2       K2      modM|tem4|grp2|casM|gen3
2       K2      modM|tem4|grp3|casJ|gen3
2       K2      modM|tem4|grp3|casM|gen3
2       K2      modO|grp1|casA|gen1
2       K2      modO|grp1|casA|gen2
2       K2      modO|grp1|casB|gen2
2       K2      modO|grp1|casB|gen3
2       K2      modO|grp1|casC|gen2
2       K2      modO|grp1|casD|gen2
2       K2      modO|grp1|casD|gen3
2       K2      modO|grp1|casJ|gen3
2       K2      modO|grp1|casM|gen2
2       K2      modO|grp1|casM|gen3
2       L2      modD|tem1|grp1|casA|gen1
2       L2      modD|tem1|grp1|casA|gen1|vgr1
2       L2      modD|tem1|grp1|casA|gen1|vgr2
2       L2      modD|tem1|grp1|casA|gen2
2       L2      modD|tem1|grp1|casA|gen2|vgr1
2       L2      modD|tem1|grp1|casA|gen3
2       L2      modD|tem1|grp1|casA|gen3|vgr1
2       L2      modD|tem1|grp1|casA|gen3|vgr2
2       L2      modD|tem1|grp1|casB|gen1
2       L2      modD|tem1|grp1|casB|gen1|vgr1
2       L2      modD|tem1|grp1|casB|gen2
2       L2      modD|tem1|grp1|casB|gen2|vgr1
2       L2      modD|tem1|grp1|casB|gen3
2       L2      modD|tem1|grp1|casB|gen3|vgr1
2       L2      modD|tem1|grp1|casC|gen1
2       L2      modD|tem1|grp1|casC|gen2
2       L2      modD|tem1|grp1|casC|gen3
2       L2      modD|tem1|grp1|casC|gen3|vgr1
2       L2      modD|tem1|grp1|casD|gen1
2       L2      modD|tem1|grp1|casD|gen2
2       L2      modD|tem1|grp1|casD|gen2|vgr1
2       L2      modD|tem1|grp1|casD|gen3
2       L2      modD|tem1|grp1|casD|gen3|vgr1
2       L2      modD|tem1|grp1|casF|gen1
2       L2      modD|tem1|grp1|casF|gen1|vgr1
2       L2      modD|tem1|grp1|casF|gen2
2       L2      modD|tem1|grp1|casF|gen2|vgr1
2       L2      modD|tem1|grp1|casF|gen3
2       L2      modD|tem1|grp1|casF|gen3|vgr1
2       L2      modD|tem1|grp1|casG
2       L2      modD|tem1|grp1|casJ|gen1
2       L2      modD|tem1|grp1|casJ|gen1|vgr1
2       L2      modD|tem1|grp1|casJ|gen1|vgr2
2       L2      modD|tem1|grp1|casJ|gen2
2       L2      modD|tem1|grp1|casJ|gen2|vgr1
2       L2      modD|tem1|grp1|casJ|gen3
2       L2      modD|tem1|grp1|casJ|gen3|vgr1
2       L2      modD|tem1|grp1|casK|gen1
2       L2      modD|tem1|grp1|casK|gen1|vgr1
2       L2      modD|tem1|grp1|casK|gen1|vgr2
2       L2      modD|tem1|grp1|casK|gen2
2       L2      modD|tem1|grp1|casK|gen2|vgr1
2       L2      modD|tem1|grp1|casK|gen3
2       L2      modD|tem1|grp1|casK|gen3|vgr1
2       L2      modD|tem1|grp1|casL|gen1
2       L2      modD|tem1|grp1|casL|gen2
2       L2      modD|tem1|grp1|casL|gen2|vgr1
2       L2      modD|tem1|grp1|casL|gen3
2       L2      modD|tem1|grp1|casM|gen1
2       L2      modD|tem1|grp1|casM|gen1|vgr1
2       L2      modD|tem1|grp1|casM|gen2
2       L2      modD|tem1|grp1|casM|gen2|vgr1
2       L2      modD|tem1|grp1|casM|gen3
2       L2      modD|tem1|grp1|casM|gen3|vgr1
2       L2      modD|tem1|grp1|casO|gen1
2       L2      modD|tem1|grp1|casO|gen2
2       L2      modD|tem1|grp1|casO|gen2|vgr1
2       L2      modD|tem1|grp1|casO|gen3
2       L2      modD|tem1|grp1|casO|gen3|vgr1
2       L2      modD|tem1|grp2|casA|gen3
2       L2      modD|tem1|grp3|casB|gen2
2       L2      modD|tem1|grp3|casD|gen2
2       L2      modD|tem3|grp1|casD|gen1
2       L2      modE|grp1|casB
2       L2      modE|grp1|casB|vgr2
2       L2      modE|grp1|casD
2       L2      modE|grp1|casD|vgr1
2       L2      modE|grp1|casF
2       L2      modE|grp1|casF|vgr1
2       L2      modM|tem1|grp1|casA|gen1
2       L2      modM|tem1|grp1|casA|gen1|vgr1
2       L2      modM|tem1|grp1|casA|gen2
2       L2      modM|tem1|grp1|casA|gen3
2       L2      modM|tem1|grp1|casA|gen3|vgr1
2       L2      modM|tem1|grp1|casB|gen2
2       L2      modM|tem1|grp1|casB|gen3
2       L2      modM|tem1|grp1|casB|gen3|vgr1
2       L2      modM|tem1|grp1|casD|gen1
2       L2      modM|tem1|grp1|casD|gen2
2       L2      modM|tem1|grp1|casD|gen3
2       L2      modM|tem1|grp1|casF|gen1
2       L2      modM|tem1|grp1|casF|gen2
2       L2      modM|tem1|grp1|casF|gen3
2       L2      modM|tem1|grp1|casG
2       L2      modM|tem1|grp1|casG|vgr1
2       L2      modM|tem1|grp1|casJ|gen1
2       L2      modM|tem1|grp1|casJ|gen2
2       L2      modM|tem1|grp1|casK|gen1
2       L2      modM|tem1|grp1|casK|gen1|vgr1
2       L2      modM|tem1|grp1|casK|gen2|vgr1
2       L2      modM|tem1|grp1|casK|gen3|vgr1
2       L2      modM|tem1|grp1|casL|gen1
2       L2      modM|tem1|grp1|casM|gen1
2       L2      modM|tem1|grp1|casM|gen2
2       L2      modM|tem1|grp1|casM|gen3|vgr1
2       L2      modM|tem1|grp1|casO|gen1
2       L2      modM|tem1|grp1|casO|gen2
2       L2      modM|tem1|grp1|casO|gen3
2       L2      modM|tem1|grp1|casO|gen3|vgr1
2       L2      modM|tem4|grp1|casA|gen1
2       L2      modM|tem4|grp1|casA|gen1|vgr1
2       L2      modM|tem4|grp1|casA|gen1|vgr2
2       L2      modM|tem4|grp1|casA|gen2
2       L2      modM|tem4|grp1|casA|gen2|varA
2       L2      modM|tem4|grp1|casA|gen2|vgr1
2       L2      modM|tem4|grp1|casA|gen2|vgr2
2       L2      modM|tem4|grp1|casA|gen3
2       L2      modM|tem4|grp1|casA|gen3|vgr1
2       L2      modM|tem4|grp1|casA|gen3|vgr2
2       L2      modM|tem4|grp1|casB|gen1
2       L2      modM|tem4|grp1|casB|gen2
2       L2      modM|tem4|grp1|casB|gen2|vgr1
2       L2      modM|tem4|grp1|casB|gen3
2       L2      modM|tem4|grp1|casB|gen3|vgr1
2       L2      modM|tem4|grp1|casB|gen3|vgr2
2       L2      modM|tem4|grp1|casC|gen1
2       L2      modM|tem4|grp1|casC|gen2
2       L2      modM|tem4|grp1|casC|gen3
2       L2      modM|tem4|grp1|casD|gen1
2       L2      modM|tem4|grp1|casD|gen1|vgr2
2       L2      modM|tem4|grp1|casD|gen2
2       L2      modM|tem4|grp1|casD|gen2|varA
2       L2      modM|tem4|grp1|casD|gen2|vgr1
2       L2      modM|tem4|grp1|casD|gen2|vgr2
2       L2      modM|tem4|grp1|casD|gen3
2       L2      modM|tem4|grp1|casD|gen3|vgr1
2       L2      modM|tem4|grp1|casE|gen1
2       L2      modM|tem4|grp1|casF|gen1
2       L2      modM|tem4|grp1|casF|gen1|vgr1
2       L2      modM|tem4|grp1|casF|gen2
2       L2      modM|tem4|grp1|casF|gen2|vgr1
2       L2      modM|tem4|grp1|casF|gen2|vgr2
2       L2      modM|tem4|grp1|casF|gen3
2       L2      modM|tem4|grp1|casF|gen3|vgr1
2       L2      modM|tem4|grp1|casF|gen3|vgr2
2       L2      modM|tem4|grp1|casG
2       L2      modM|tem4|grp1|casJ|gen1
2       L2      modM|tem4|grp1|casJ|gen1|vgr1
2       L2      modM|tem4|grp1|casJ|gen2
2       L2      modM|tem4|grp1|casJ|gen2|vgr1
2       L2      modM|tem4|grp1|casJ|gen2|vgr2
2       L2      modM|tem4|grp1|casJ|gen3
2       L2      modM|tem4|grp1|casJ|gen3|vgr1
2       L2      modM|tem4|grp1|casJ|gen3|vgr2
2       L2      modM|tem4|grp1|casK|gen1
2       L2      modM|tem4|grp1|casK|gen2
2       L2      modM|tem4|grp1|casK|gen3
2       L2      modM|tem4|grp1|casL|gen1
2       L2      modM|tem4|grp1|casL|gen2
2       L2      modM|tem4|grp1|casL|gen3
2       L2      modM|tem4|grp1|casM|gen1
2       L2      modM|tem4|grp1|casM|gen1|vgr1
2       L2      modM|tem4|grp1|casM|gen2
2       L2      modM|tem4|grp1|casM|gen3
2       L2      modM|tem4|grp1|casM|gen3|vgr1
2       L2      modM|tem4|grp1|casO|gen1
2       L2      modM|tem4|grp1|casO|gen2
2       L2      modM|tem4|grp1|casO|gen3
2       L2      modM|tem4|grp1|casO|gen3|vgr1
2       L2      modM|tem4|grp2|casA|gen1
2       L2      modM|tem4|grp2|casA|gen1|vgr1
2       L2      modM|tem4|grp2|casA|gen2
2       L2      modM|tem4|grp2|casA|gen2|vgr1
2       L2      modM|tem4|grp2|casA|gen3|vgr1
2       L2      modM|tem4|grp2|casD|gen2
2       L2      modM|tem4|grp2|casJ|gen1
2       L2      modM|tem4|grp2|casJ|gen2
2       L2      modM|tem4|grp3|casA|gen2
2       L2      modM|tem4|grp3|casA|gen3
2       L2      modM|tem4|grp3|casJ|gen3
2       L2      modM|tem4|grp3|casM|gen2
2       L2      modN|grp1|casB
2       L2      modN|grp1|casD
2       L2      modN|grp1|casF
2       L2      modO|grp1|casA|gen1
2       L2      modO|grp1|casA|gen2
2       L2      modO|grp1|casA|gen2|vgr1
2       L2      modO|grp1|casA|gen3
2       L2      modO|grp1|casA|gen3|vgr1
2       L2      modO|grp1|casA|gen3|vgr2
2       L2      modO|grp1|casC|gen2|vgr2
2       L2      modO|grp1|casD|gen1
2       L2      modO|grp1|casD|gen2
2       L2      modO|grp1|casD|gen3
2       L2      modO|grp1|casF|gen2|vgr1
2       L2      modO|grp1|casJ|gen2
2       L2      modO|grp1|casJ|gen3
2       L2      modO|grp1|casK|gen3
2       L2      modO|grp1|casM|gen1
2       L2      modO|grp1|casM|gen2
2       L2      modO|grp1|casM|gen3
2       L2      modO|grp1|casO|gen2
2       L2      modO|grp1|casO|gen3
2       M2      modD|tem1|grp1|casA|gen1
2       M2      modD|tem1|grp1|casA|gen1|vgr1
2       M2      modD|tem1|grp1|casA|gen2
2       M2      modD|tem1|grp1|casA|gen2|vgr1
2       M2      modD|tem1|grp1|casA|gen3
2       M2      modD|tem1|grp1|casA|gen3|vgr1
2       M2      modD|tem1|grp1|casB|gen1
2       M2      modD|tem1|grp1|casB|gen2
2       M2      modD|tem1|grp1|casB|gen3
2       M2      modD|tem1|grp1|casC|gen1
2       M2      modD|tem1|grp1|casD|gen1
2       M2      modD|tem1|grp1|casD|gen2
2       M2      modD|tem1|grp1|casD|gen2|vgr1
2       M2      modD|tem1|grp1|casD|gen3
2       M2      modD|tem1|grp1|casD|gen3|vgr1
2       M2      modD|tem1|grp1|casF|gen1
2       M2      modD|tem1|grp1|casF|gen2
2       M2      modD|tem1|grp1|casF|gen3
2       M2      modD|tem1|grp1|casG|vgr1
2       M2      modD|tem1|grp1|casJ|gen1
2       M2      modD|tem1|grp1|casJ|gen1|vgr1
2       M2      modD|tem1|grp1|casJ|gen2
2       M2      modD|tem1|grp1|casJ|gen2|vgr1
2       M2      modD|tem1|grp1|casJ|gen3
2       M2      modD|tem1|grp1|casJ|gen3|vgr1
2       M2      modD|tem1|grp1|casL|gen1
2       M2      modD|tem1|grp1|casM|gen3|vgr1
2       M2      modD|tem1|grp1|casO|gen2
2       M2      modD|tem1|grp1|casO|gen3|vgr1
2       M2      modD|tem1|grp2|casA|gen1
2       M2      modD|tem1|grp2|casA|gen2
2       M2      modD|tem1|grp2|casG|vgr1
2       M2      modD|tem1|grp3|casA|gen3
2       M2      modD|tem3|grp1|casB|gen1
2       M2      modD|tem3|grp1|casD|gen1
2       M2      modE|grp1|casB
2       M2      modE|grp1|casD
2       M2      modE|grp1|casF
2       M2      modM|tem4|grp1|casA|gen1
2       M2      modM|tem4|grp1|casA|gen2
2       M2      modM|tem4|grp1|casA|gen3
2       M2      modM|tem4|grp1|casB|gen2
2       M2      modM|tem4|grp1|casB|gen3
2       M2      modM|tem4|grp1|casC|gen2
2       M2      modM|tem4|grp1|casC|gen3
2       M2      modM|tem4|grp1|casD|gen1
2       M2      modM|tem4|grp1|casD|gen2
2       M2      modM|tem4|grp1|casD|gen3
2       M2      modM|tem4|grp1|casD|gen3|vgr1
2       M2      modM|tem4|grp1|casF|gen2
2       M2      modM|tem4|grp1|casF|gen3
2       M2      modM|tem4|grp1|casG
2       M2      modM|tem4|grp1|casJ|gen1
2       M2      modM|tem4|grp1|casJ|gen2
2       M2      modM|tem4|grp1|casJ|gen3
2       M2      modM|tem4|grp1|casK|gen1
2       M2      modM|tem4|grp1|casK|gen2
2       M2      modM|tem4|grp1|casK|gen3
2       M2      modM|tem4|grp1|casL|gen1
2       M2      modM|tem4|grp1|casM|gen1
2       M2      modM|tem4|grp1|casM|gen2
2       M2      modM|tem4|grp1|casM|gen3
2       M2      modM|tem4|grp1|casO|gen2
2       M2      modM|tem4|grp1|casO|gen3
2       M2      modM|tem4|grp2|casG
2       M2      modO|grp1|casA|gen3
2       M2      modO|grp1|casA|gen3|vgr1
2       M2      modO|grp1|casD|gen2
2       N2      modD|tem1|grp1|casA|gen1
2       N2      modD|tem1|grp1|casA|gen1|vgr1
2       N2      modD|tem1|grp1|casA|gen2
2       N2      modD|tem1|grp1|casA|gen2|vgr1
2       N2      modD|tem1|grp1|casA|gen3
2       N2      modD|tem1|grp1|casB|gen1
2       N2      modD|tem1|grp1|casB|gen2
2       N2      modD|tem1|grp1|casB|gen3
2       N2      modD|tem1|grp1|casC|gen1
2       N2      modD|tem1|grp1|casD|gen1
2       N2      modD|tem1|grp1|casD|gen2
2       N2      modD|tem1|grp1|casD|gen2|vgr1
2       N2      modD|tem1|grp1|casD|gen3
2       N2      modD|tem1|grp1|casF|gen1
2       N2      modD|tem1|grp1|casF|gen2
2       N2      modD|tem1|grp1|casF|gen3
2       N2      modD|tem1|grp1|casG
2       N2      modD|tem1|grp1|casJ|gen1
2       N2      modD|tem1|grp1|casJ|gen2
2       N2      modD|tem1|grp1|casJ|gen2|vgr1
2       N2      modD|tem1|grp1|casJ|gen3
2       N2      modD|tem1|grp1|casJ|gen3|vgr1
2       N2      modD|tem1|grp1|casK|gen1
2       N2      modD|tem1|grp1|casK|gen2
2       N2      modD|tem1|grp1|casK|gen3
2       N2      modD|tem1|grp1|casL|gen1
2       N2      modD|tem1|grp1|casM|gen2
2       N2      modD|tem1|grp1|casM|gen2|vgr1
2       N2      modD|tem1|grp1|casM|gen3
2       N2      modD|tem1|grp1|casM|gen3|vgr1
2       N2      modD|tem1|grp1|casO|gen3
2       N2      modD|tem1|grp2|casA|gen2
2       N2      modD|tem3|grp1|casD|gen1
2       N2      modD|tem3|grp1|casD|gen2
2       N2      modD|tem3|grp1|casO|gen3
2       N2      modE|grp1|casB
2       N2      modE|grp1|casD
2       N2      modE|grp1|casF
2       N2      modM|tem1|grp1|casB|gen1
2       N2      modM|tem4|grp1|casA|gen1
2       N2      modM|tem4|grp1|casA|gen2
2       N2      modM|tem4|grp1|casA|gen2|vgr1
2       N2      modM|tem4|grp1|casA|gen3
2       N2      modM|tem4|grp1|casA|gen3|vgr1
2       N2      modM|tem4|grp1|casB|gen1
2       N2      modM|tem4|grp1|casB|gen2
2       N2      modM|tem4|grp1|casB|gen3
2       N2      modM|tem4|grp1|casB|gen3|vgr1
2       N2      modM|tem4|grp1|casC|gen2
2       N2      modM|tem4|grp1|casC|gen3
2       N2      modM|tem4|grp1|casD|gen1
2       N2      modM|tem4|grp1|casD|gen1|vgr1
2       N2      modM|tem4|grp1|casD|gen2
2       N2      modM|tem4|grp1|casD|gen2|vgr1
2       N2      modM|tem4|grp1|casD|gen3
2       N2      modM|tem4|grp1|casD|gen3|vgr1
2       N2      modM|tem4|grp1|casF|gen1
2       N2      modM|tem4|grp1|casF|gen2
2       N2      modM|tem4|grp1|casF|gen2|vgr1
2       N2      modM|tem4|grp1|casF|gen3
2       N2      modM|tem4|grp1|casJ|gen1
2       N2      modM|tem4|grp1|casJ|gen1|vgr1
2       N2      modM|tem4|grp1|casJ|gen2
2       N2      modM|tem4|grp1|casJ|gen3
2       N2      modM|tem4|grp1|casJ|gen3|vgr1
2       N2      modM|tem4|grp1|casK|gen1|vgr1
2       N2      modM|tem4|grp1|casK|gen2
2       N2      modM|tem4|grp1|casK|gen2|vgr1
2       N2      modM|tem4|grp1|casK|gen3
2       N2      modM|tem4|grp1|casK|gen3|vgr1
2       N2      modM|tem4|grp1|casL|gen1|vgr1
2       N2      modM|tem4|grp1|casL|gen2|vgr1
2       N2      modM|tem4|grp1|casL|gen3|vgr1
2       N2      modM|tem4|grp1|casM|gen1|vgr1
2       N2      modM|tem4|grp1|casM|gen2
2       N2      modM|tem4|grp1|casM|gen3
2       N2      modM|tem4|grp1|casM|gen3|vgr1
2       N2      modM|tem4|grp1|casO|gen1|vgr1
2       N2      modM|tem4|grp1|casO|gen2
2       N2      modM|tem4|grp1|casO|gen2|vgr1
2       N2      modM|tem4|grp1|casO|gen3
2       N2      modM|tem4|grp1|casO|gen3|vgr1
2       N2      modN|grp1|casB
2       N2      modN|grp1|casF
2       N2      modO|grp1|casA|gen2
2       N2      modO|grp1|casA|gen3
2       N2      modO|grp1|casB|gen2
2       N2      modO|grp1|casB|gen2|varA
2       N2      modO|grp1|casC|gen2
2       N2      modO|grp1|casD|gen2
2       N2      modO|grp1|casD|gen3
2       N2      modO|grp1|casF|gen2
2       N2      modO|grp1|casJ|gen2
2       N2      modO|grp1|casJ|gen3
2       N2      modO|grp1|casK|gen2
2       N2      modO|grp1|casK|gen3
2       N2      modO|grp1|casM|gen1
2       N2      modO|grp1|casM|gen2
2       N2      modO|grp1|casO|gen1
3       J3      modA|tem1|gen4
3       J3      modA|tem1|gen5
3       J3      modA|tem1|gen6
3       J3      modA|tem1|gen6|vgr1
3       J3      modA|tem1|gen6|vgr2
3       J3      modA|tem1|gen7
3       J3      modA|tem1|gen7|vgr1
3       J3      modA|tem1|gen8
3       J3      modA|tem1|gen9
3       J3      modA|tem1|gen9|vgr1
3       J3      modA|tem2|gen6
3       J3      modA|tem2|gen6|vgr2
3       J3      modA|tem2|gen9
3       J3      modA|tem2|gen9|vgr1
3       J3      modA|tem3|gen4
3       J3      modA|tem3|gen4|vgr1
3       J3      modA|tem3|gen4|vgr2
3       J3      modA|tem3|gen5
3       J3      modA|tem3|gen6
3       J3      modA|tem3|gen6|vgr1
3       J3      modA|tem3|gen6|vgr2
3       J3      modA|tem3|gen7
3       J3      modA|tem3|gen8
3       J3      modA|tem3|gen9
3       J3      modA|tem4|gen4
3       J3      modA|tem4|gen5
3       J3      modA|tem4|gen6
3       J3      modA|tem4|gen6|vgr1
3       J3      modA|tem4|gen6|vgr2
3       J3      modA|tem4|gen7
3       J3      modA|tem4|gen8
3       J3      modA|tem4|gen9
3       J3      modA|tem4|gen9|varA
3       J3      modA|tem4|gen9|vgr1
3       J3      modA|tem5|gen6
3       J3      modA|tem5|gen6|vgr2
3       J3      modA|tem5|gen9
3       J3      modA|tem6|gen4
3       J3      modA|tem6|gen5
3       J3      modA|tem6|gen6
3       J3      modA|tem6|gen7
3       J3      modA|tem6|gen8
3       J3      modA|tem6|gen9
3       J3      modB|tem1|gen4
3       J3      modB|tem1|gen5
3       J3      modB|tem1|gen6
3       J3      modB|tem1|gen6|vgr1
3       J3      modB|tem1|gen6|vgr2
3       J3      modB|tem1|gen7
3       J3      modB|tem1|gen8
3       J3      modB|tem1|gen9
3       J3      modB|tem1|gen9|vgr1
3       J3      modB|tem2|gen4
3       J3      modB|tem2|gen5
3       J3      modB|tem2|gen6
3       J3      modB|tem2|gen6|vgr1
3       J3      modB|tem2|gen7
3       J3      modB|tem2|gen8
3       J3      modB|tem2|gen9
3       J3      modB|tem4|gen4
3       J3      modB|tem4|gen5
3       J3      modB|tem4|gen6
3       J3      modB|tem4|gen7
3       J3      modB|tem4|gen8
3       J3      modB|tem4|gen9
3       J3      modB|tem5|gen4
3       J3      modB|tem5|gen5
3       J3      modB|tem5|gen6
3       J3      modB|tem5|gen7
3       J3      modB|tem5|gen8
3       J3      modB|tem5|gen9
3       J3      modC|tem1|gen5
3       J3      modC|tem1|gen8
3       J3      modC|tem3|gen5
3       J3      modC|tem3|gen8
3       J3      modH|tem1
3       J3      modH|tem1|vgr1
3       J3      modH|tem1|vgr2
3       J3      modH|tem3
3       J3      modH|tem4
3       J3      modJ|tem1|gen4
3       J3      modJ|tem1|gen6
3       J3      modJ|tem1|gen6|vgr1
3       J3      modJ|tem1|gen6|vgr2
3       J3      modJ|tem1|gen7
3       J3      modJ|tem1|gen9
3       J3      modJ|tem1|gen9|vgr1
3       J3      modJ|tem2|gen4
3       J3      modJ|tem2|gen6
3       J3      modJ|tem2|gen9
3       J3      modJ|tem3|gen4
3       J3      modJ|tem3|gen5
3       J3      modJ|tem3|gen6
3       J3      modJ|tem3|gen6|vgr1
3       J3      modJ|tem3|gen7
3       J3      modJ|tem3|gen8
3       J3      modJ|tem3|gen9
3       J3      modK|tem1|gen4
3       J3      modK|tem1|gen6
3       J3      modK|tem1|gen6|vgr1
3       J3      modK|tem1|gen7
3       J3      modK|tem1|gen9
3       J3      modK|tem2|gen4
3       J3      modK|tem2|gen5
3       J3      modK|tem2|gen6
3       J3      modK|tem2|gen6|vgr1
3       J3      modK|tem2|gen6|vgr2
3       J3      modK|tem2|gen7
3       J3      modK|tem2|gen8
3       J3      modK|tem2|gen9
3       J3      modL|tem1|gen5
3       J3      modQ|tem1
3       J3      modQ|tem1|vgr1
3       K3      modA|tem1|gen4
3       K3      modA|tem1|gen5
3       K3      modA|tem1|gen6
3       K3      modA|tem1|gen6|vgr1
3       K3      modA|tem1|gen6|vgr2
3       K3      modA|tem1|gen7
3       K3      modA|tem1|gen7|vgr1
3       K3      modA|tem1|gen9
3       K3      modA|tem1|gen9|vgr1
3       K3      modA|tem2|gen6
3       K3      modA|tem2|gen6|vgr1
3       K3      modA|tem2|gen9
3       K3      modA|tem3|gen6
3       K3      modA|tem3|gen7
3       K3      modA|tem3|gen7|vgr1
3       K3      modA|tem3|gen9
3       K3      modA|tem4|gen4
3       K3      modA|tem4|gen6
3       K3      modA|tem4|gen6|vgr1
3       K3      modA|tem4|gen9
3       K3      modA|tem5|gen6
3       K3      modA|tem6|gen5
3       K3      modA|tem6|gen6
3       K3      modB|tem1|gen4
3       K3      modB|tem1|gen6
3       K3      modB|tem1|gen6|vgr1
3       K3      modB|tem1|gen6|vgr2
3       K3      modB|tem1|gen7|vgr1
3       K3      modB|tem1|gen9
3       K3      modB|tem1|gen9|vgr1
3       K3      modB|tem2|gen6
3       K3      modB|tem2|gen7
3       K3      modB|tem2|gen9
3       K3      modB|tem4|gen6
3       K3      modB|tem4|gen7
3       K3      modB|tem5|gen6
3       K3      modC|tem1|gen8
3       K3      modH|tem1
3       K3      modH|tem1|vgr1
3       K3      modH|tem4
3       K3      modJ|tem1|gen6
3       K3      modJ|tem1|gen6|vgr1
3       K3      modJ|tem1|gen7
3       K3      modJ|tem1|gen9
3       K3      modJ|tem1|gen9|vgr1
3       K3      modJ|tem2|gen6
3       K3      modJ|tem2|gen6|vgr1
3       K3      modJ|tem3|gen6
3       K3      modJ|tem3|gen6|vgr1
3       K3      modJ|tem3|gen9
3       K3      modK|tem1|gen6
3       K3      modK|tem1|gen6|vgr1
3       K3      modK|tem1|gen7
3       K3      modK|tem1|gen9
3       K3      modK|tem1|gen9|vgr1
3       K3      modK|tem2|gen6
3       K3      modK|tem2|gen6|vgr1
3       K3      modK|tem2|gen7
3       K3      modK|tem2|gen9
3       K3      modL|tem1|gen5
3       K3      modQ|tem1
3       K3      modQ|tem1|vgr1
3       L3      modA|tem1|gen4
3       L3      modA|tem1|gen4|vgr1
3       L3      modA|tem1|gen5
3       L3      modA|tem1|gen6
3       L3      modA|tem1|gen6|vgr1
3       L3      modA|tem1|gen6|vgr2
3       L3      modA|tem1|gen7
3       L3      modA|tem1|gen7|vgr1
3       L3      modA|tem1|gen9
3       L3      modA|tem1|gen9|vgr1
3       L3      modA|tem1|gen9|vgr2
3       L3      modA|tem2|gen6
3       L3      modA|tem2|gen9
3       L3      modA|tem2|gen9|vgr1
3       L3      modA|tem3|gen4
3       L3      modA|tem3|gen5
3       L3      modA|tem3|gen6
3       L3      modA|tem3|gen7
3       L3      modA|tem3|gen8
3       L3      modA|tem3|gen9
3       L3      modA|tem4|gen4
3       L3      modA|tem4|gen4|vgr1
3       L3      modA|tem4|gen5
3       L3      modA|tem4|gen6
3       L3      modA|tem4|gen6|vgr1
3       L3      modA|tem4|gen6|vgr2
3       L3      modA|tem4|gen7
3       L3      modA|tem4|gen9
3       L3      modA|tem4|gen9|varA
3       L3      modA|tem4|gen9|vgr2
3       L3      modA|tem5|gen6
3       L3      modA|tem6|gen6
3       L3      modB|tem1|gen5
3       L3      modB|tem1|gen6
3       L3      modB|tem1|gen6|vgr1
3       L3      modB|tem1|gen6|vgr2
3       L3      modB|tem1|gen7
3       L3      modB|tem1|gen8
3       L3      modB|tem1|gen9
3       L3      modB|tem2|gen6
3       L3      modB|tem2|gen6|vgr1
3       L3      modB|tem2|gen6|vgr2
3       L3      modB|tem2|gen7
3       L3      modB|tem2|gen9
3       L3      modB|tem4|gen6
3       L3      modB|tem4|gen6|vgr2
3       L3      modB|tem5|gen6
3       L3      modB|tem5|gen6|vgr2
3       L3      modB|tem5|gen7
3       L3      modB|tem5|gen9
3       L3      modC|tem1|gen5
3       L3      modC|tem1|gen8
3       L3      modC|tem1|gen8|vgr1
3       L3      modH|tem1
3       L3      modH|tem1|vgr1
3       L3      modH|tem1|vgr2
3       L3      modH|tem4
3       L3      modH|tem4|vgr1
3       L3      modH|tem4|vgr2
3       L3      modJ|tem1|gen6
3       L3      modJ|tem1|gen6|vgr1
3       L3      modJ|tem1|gen6|vgr2
3       L3      modJ|tem1|gen7
3       L3      modJ|tem1|gen9
3       L3      modJ|tem1|gen9|vgr1
3       L3      modJ|tem1|gen9|vgr2
3       L3      modJ|tem2|gen6
3       L3      modJ|tem2|gen6|vgr1
3       L3      modJ|tem2|gen6|vgr2
3       L3      modJ|tem2|gen9
3       L3      modJ|tem3|gen4
3       L3      modJ|tem3|gen5
3       L3      modJ|tem3|gen6
3       L3      modJ|tem3|gen6|vgr1
3       L3      modJ|tem3|gen7
3       L3      modJ|tem3|gen9
3       L3      modK|tem1|gen6
3       L3      modK|tem1|gen6|vgr1
3       L3      modK|tem1|gen6|vgr2
3       L3      modK|tem1|gen7
3       L3      modK|tem1|gen9
3       L3      modK|tem1|gen9|vgr1
3       L3      modK|tem1|gen9|vgr2
3       L3      modK|tem2|gen6
3       L3      modK|tem2|gen6|vgr1
3       L3      modK|tem2|gen6|vgr2
3       L3      modK|tem2|gen9
3       L3      modK|tem2|gen9|vgr2
3       L3      modQ|tem1
3       L3      modQ|tem1|vgr1
3       L3      modQ|tem1|vgr2
3       M3      modA|tem1|gen4
3       M3      modA|tem1|gen5
3       M3      modA|tem1|gen6
3       M3      modA|tem1|gen6|vgr1
3       M3      modA|tem1|gen7
3       M3      modA|tem1|gen9
3       M3      modA|tem1|gen9|vgr1
3       M3      modA|tem2|gen6
3       M3      modA|tem2|gen9
3       M3      modA|tem3|gen4
3       M3      modA|tem3|gen5
3       M3      modA|tem3|gen6
3       M3      modA|tem3|gen7
3       M3      modA|tem4|gen4|vgr2
3       M3      modA|tem4|gen5
3       M3      modA|tem4|gen6
3       M3      modA|tem4|gen6|vgr1
3       M3      modA|tem4|gen7
3       M3      modA|tem4|gen9
3       M3      modA|tem5|gen9
3       M3      modB|tem1|gen6
3       M3      modB|tem1|gen6|vgr1
3       M3      modB|tem1|gen7
3       M3      modB|tem1|gen9
3       M3      modB|tem2|gen6
3       M3      modB|tem2|gen9
3       M3      modB|tem4|gen6
3       M3      modB|tem5|gen6|vgr1
3       M3      modB|tem5|gen7
3       M3      modC|tem1|gen5
3       M3      modC|tem1|gen8
3       M3      modH|tem1
3       M3      modH|tem1|vgr1
3       M3      modH|tem4
3       M3      modH|tem4|vgr1
3       M3      modJ|tem1|gen6
3       M3      modJ|tem1|gen6|vgr1
3       M3      modJ|tem1|gen7
3       M3      modJ|tem1|gen9
3       M3      modJ|tem1|gen9|vgr1
3       M3      modJ|tem2|gen6
3       M3      modJ|tem3|gen6
3       M3      modJ|tem3|gen9
3       M3      modK|tem1|gen6
3       M3      modK|tem1|gen6|vgr1
3       M3      modK|tem1|gen9
3       M3      modK|tem2|gen6
3       M3      modK|tem2|gen7
3       M3      modK|tem2|gen9
3       M3      modQ|tem1
3       M3      modQ|tem1|vgr1
3       N3      grn8|modH|tem1|comZ
3       N3      modA|tem1|gen4
3       N3      modA|tem1|gen5
3       N3      modA|tem1|gen5|vgr1
3       N3      modA|tem1|gen6
3       N3      modA|tem1|gen6|comQ
3       N3      modA|tem1|gen6|vgr1
3       N3      modA|tem1|gen7
3       N3      modA|tem1|gen7|vgr1
3       N3      modA|tem1|gen8
3       N3      modA|tem1|gen9
3       N3      modA|tem1|gen9|vgr1
3       N3      modA|tem2|gen6
3       N3      modA|tem2|gen6|vgr1
3       N3      modA|tem2|gen9
3       N3      modA|tem3|gen4
3       N3      modA|tem3|gen5
3       N3      modA|tem3|gen6
3       N3      modA|tem3|gen7
3       N3      modA|tem3|gen9
3       N3      modA|tem4|gen4
3       N3      modA|tem4|gen5
3       N3      modA|tem4|gen6
3       N3      modA|tem4|gen6|vgr1
3       N3      modA|tem4|gen6|vgr2
3       N3      modA|tem4|gen7
3       N3      modA|tem4|gen8
3       N3      modA|tem4|gen9
3       N3      modA|tem5|gen6
3       N3      modA|tem5|gen9
3       N3      modA|tem6|gen6
3       N3      modA|tem6|gen8
3       N3      modA|tem6|gen9
3       N3      modB|tem1|gen4
3       N3      modB|tem1|gen5
3       N3      modB|tem1|gen6
3       N3      modB|tem1|gen6|vgr1
3       N3      modB|tem1|gen6|vgr2
3       N3      modB|tem1|gen7
3       N3      modB|tem1|gen9
3       N3      modB|tem2|gen5
3       N3      modB|tem2|gen6
3       N3      modB|tem2|gen6|comQ
3       N3      modB|tem2|gen7
3       N3      modB|tem2|gen9
3       N3      modB|tem4|gen6
3       N3      modB|tem4|gen7
3       N3      modB|tem4|gen9
3       N3      modB|tem5|gen6
3       N3      modB|tem5|gen9
3       N3      modC|tem1|gen8
3       N3      modC|tem3|gen5
3       N3      modC|tem3|gen8
3       N3      modH|tem1
3       N3      modH|tem1|vgr1
3       N3      modH|tem3
3       N3      modH|tem4
3       N3      modJ|tem1|gen6
3       N3      modJ|tem1|gen7
3       N3      modJ|tem1|gen9
3       N3      modJ|tem2|gen6
3       N3      modJ|tem2|gen9
3       N3      modJ|tem3|gen6
3       N3      modJ|tem3|gen9
3       N3      modK|tem1|gen6
3       N3      modK|tem1|gen7
3       N3      modK|tem1|gen9
3       N3      modK|tem2|gen6
3       N3      modK|tem2|gen9
3       N3      modQ|tem1
4       O4      _
4       O4      comH
4       O4      comQ
4       O4      grn8|comZ
4       O4      varA
4       O4      vgr1
4       O4      vgr2
4       S4      _
4       S4      comH
4       S4      vgr1
4       S4      vgr2
5       5       _
5       G5      _
5       G5      vgr1
Punc    Punc    _
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

Lingua::Interset::Tagset::LA::Itconll - Driver for the tagset of the Index Thomisticus Treebank in CoNLL format.

=head1 VERSION

version 3.016

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::LA::Itconll;
  my $driver = Lingua::Interset::Tagset::LA::Itconll->new();
  my $fs = $driver->decode("1\tA1\tgrn1|casA|gen1");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('la::itconll', "1\tA1\tgrn1|casA|gen1");

=head1 DESCRIPTION

Interset driver for the tagset of the Index Thomisticus Treebank in CoNLL format.
The original tags are positional, there are eleven positions.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::Conll>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
