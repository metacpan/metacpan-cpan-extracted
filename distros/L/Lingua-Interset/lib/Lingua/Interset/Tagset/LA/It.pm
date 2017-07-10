# ABSTRACT: Driver for the positional tagset of the Index Thomisticus Treebank.
# Copyright © 2015 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::LA::It;
use strict;
use warnings;
our $VERSION = '3.005';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset';



has 'features' => ( isa => 'ArrayRef', is => 'ro', builder => '_create_features', lazy => 1 );
has 'atoms'    => ( isa => 'HashRef', is => 'ro', builder => '_create_atoms', lazy => 1 );



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
# Creates the list of all surface CoNLL features that can appear in the FEATS
# column. This list will be used in decode().
#------------------------------------------------------------------------------
sub _create_features
{
    my $self = shift;
    my @features = ('grn', 'mod', 'tem', 'grp', 'cas', 'gen', 'com', 'var', 'vgr');
    return \@features;
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
    # FLEXIONAL CATEGORY ####################
    # The first and the third character of the tag encode flectional type and category.
    # We process them together. In the table below there is always a two-character string,
    # whereas the first character is the third character of the tag, and the second character is the first character from the tag.
    # (This is the ordering used when the tags are exported in the CoNLL format; see the la::itconll driver.)
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
            '-5'  => ['abbr' => 'yes'],
            # pseudo-lemma / number
            'G5' => ['pos' => 'num', 'numform' => 'digit'],
            # punctuation
            '--' => ['pos' => 'punc']
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
                       'punc' => '--',
                       '@'    => { 'other/flexcat' => { 'invar'    => 'O4',
                                                        'preppart' => 'S4',
                                                        '@'        => { 'abbr' => { 'yes' => '-5',
                                                                                    '@'    => 'O4' }}}}}
        }
    );
    # 2. NOMINAL DEGREE OF COMPARISON ####################
    $atoms{grn} = $self->create_atom
    (
        'surfeature' => 'grn',
        'decode_map' =>
        {
            '1' => ['degree' => 'pos'],
            '2' => ['degree' => 'cmp'],
            '3' => ['degree' => 'sup'],
            # not stable composition
            # examples: inquantum, necesse-esse, intantum, proculdubio
            '8' => ['other' => {'degree' => 'unstable'}]
        },
        'encode_map' =>
        {
            'degree' => { 'pos' => '1',
                          'cmp' => '2',
                          'sup' => '3',
                          '@'   => { 'other/degree' => { 'unstable' => '8',
                                                         '@'        => '-' }}}
        }
    );
    # 4. MOOD ####################
    $atoms{mod} = $self->create_atom
    (
        'surfeature' => 'mod',
        'decode_map' =>
        {
            # active indicative (est, sunt, potest, oportet, habet)
            'A' => ['verbform' => 'fin', 'mood' => 'ind', 'voice' => 'act'],
            # passive / dep indicative (dicitur, fit, videtur, sequitur, invenitur)
            'J' => ['verbform' => 'fin', 'mood' => 'ind', 'voice' => 'pass'],
            # active subjunctive (sit, esset, sint, possit, habeat)
            'B' => ['verbform' => 'fin', 'mood' => 'sub', 'voice' => 'act'],
            # passive / dep subjunctive (dicatur, fiat, sequeretur, uniatur, moveatur)
            'K' => ['verbform' => 'fin', 'mood' => 'sub', 'voice' => 'pass'],
            # active imperative (puta, accipite, docete, quaerite, accipe)
            'C' => ['verbform' => 'fin', 'mood' => 'imp', 'voice' => 'act'],
            # passive / dep imperative (intuere)
            'L' => ['verbform' => 'fin', 'mood' => 'imp', 'voice' => 'pass'],
            # active participle (movens, agens, intelligens, existens, habens)
            'D' => ['verbform' => 'part', 'voice' => 'act'],
            # passive / dep participle (ostensum, dictum, probatum, consequens, separata)
            'M' => ['verbform' => 'part', 'voice' => 'pass'],
            # active gerund (essendi, agendo, cognoscendo, intelligendo, recipiendum)
            'E' => ['verbform' => 'ger', 'voice' => 'act'],
            # passive gerund (loquendo, operando, operandum, loquendi, ratiocinando)
            'N' => ['verbform' => 'ger', 'voice' => 'pass'],
            # passive / dep gerundive (dicendum, sciendum, considerandum, ostendendum, intelligendum)
            'O' => ['verbform' => 'gdv', 'voice' => 'pass'],
            # active supine
            'G' => ['verbform' => 'sup', 'voice' => 'act'],
            # passive / dep supine
            'P' => ['verbform' => 'sup', 'voice' => 'pass'],
            # active infinitive (esse, intelligere, habere, dicere, facere)
            'H' => ['verbform' => 'inf', 'voice' => 'act'],
            # passive / dep infinitive (dici, fieri, moveri, uniri, intelligi)
            'Q' => ['verbform' => 'inf', 'voice' => 'pass']
        },
        'encode_map' =>
        {
            'voice' => { 'act'  => { 'verbform' => { 'fin'  => { 'mood' => { 'ind' => 'A',
                                                                             'sub' => 'B',
                                                                             'imp' => 'C' }},
                                                     'part' => 'D',
                                                     'ger'  => 'E',
                                                     'gdv'  => 'E',
                                                     'sup'  => 'G',
                                                     '@'    => 'H' }},
                         'pass' => { 'verbform' => { 'fin'  => { 'mood' => { 'ind' => 'J',
                                                                             'sub' => 'K',
                                                                             'imp' => 'L', }},
                                                     'part' => 'M',
                                                     'ger'  => 'N',
                                                     'gdv'  => 'O',
                                                     'sup'  => 'P',
                                                     '@'    => 'Q' }},
                         '@'    => '-' }
        }
    );
    # 5. TENSE ####################
    $atoms{tem} = $self->create_atom
    (
        'surfeature' => 'tem',
        'decode_map' =>
        {
            # present (est, esse, sit, sunt, potest)
            '1' => ['tense' => 'pres'],
            # imperfect (esset, posset, essent, sequeretur, erat)
            '2' => ['tense' => 'imp', 'aspect' => 'imp'],
            # future (erit, sequetur, poterit, oportebit, habebit)
            '3' => ['tense' => 'fut'],
            # perfect (ostensum, dictum, probatum, fuit, separata)
            '4' => ['tense' => 'past', 'aspect' => 'perf'],
            # plusperfect (fuisset, dixerat, fecerat, accepisset, fuerat)
            '5' => ['tense' => 'pqp', 'aspect' => 'perf'],
            # future perfect (fuerit, voluerit, dixerint, dederit, exarserit)
            '6' => ['tense' => 'fut', 'aspect' => 'perf']
        },
        'encode_map' =>
        {
            'tense' => { 'pres' => '1',
                         'past' => { 'aspect' => { 'imp'  => '2',
                                                   'perf' => '4',
                                                   '@'    => '2' }},
                         'imp'  => '2',
                         'pqp'  => '5',
                         'fut'  => { 'aspect' => { 'perf' => '6',
                                                   '@'    => '3' }},
                         '@'    => '-' }
        }
    );
    # 6. PARTICIPIAL DEGREE OF COMPARISON ####################
    $atoms{grp} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            '1' => 'pos',
            '2' => 'cmp',
            '3' => 'sup'
        },
        'encode_default' => '-'
    );
    # 7. CASE / NUMBER ####################
    $atoms{cas} = $self->create_atom
    (
        'surfeature' => 'cas',
        'decode_map' =>
        {
            # singular nominative (forma, quod, quae, deus, intellectus)
            'A' => ['number' => 'sing', 'case' => 'nom'],
            # singular genitive (formae, eius, corporis, materiae, dei)
            'B' => ['number' => 'sing', 'case' => 'gen'],
            # singular dative (ei, corpori, sibi, deo, formae)
            'C' => ['number' => 'sing', 'case' => 'dat'],
            # singular accusative (formam, se, hoc, esse, materiam)
            'D' => ['number' => 'sing', 'case' => 'acc'],
            # singular vocative (domine, praecipue, deus, expresse, maxime)
            'E' => ['number' => 'sing', 'case' => 'voc'],
            # singular ablative (forma, materia, actu, potentia, quo)
            'F' => ['number' => 'sing', 'case' => 'abl'],
            # adverbial (vero, solum, amplius, similiter, primo)
            'G' => ['number' => 'sing', 'case' => 'loc'],
            # casus “plurimus” (hoc, se)
            'H' => ['other' => {'case' => 'plurimus'}],
            # plural nominative (quae, formae, omnia, qui, substantiae)
            'J' => ['number' => 'plur', 'case' => 'nom'],
            # plural genitive (rerum, eorum, omnium, formarum, quorum)
            'K' => ['number' => 'plur', 'case' => 'gen'],
            # plural dative (eis, nobis, corporibus, aliis, omnibus)
            'L' => ['number' => 'plur', 'case' => 'dat'],
            # plural accusative (formas, se, omnia, ea, quae)
            'M' => ['number' => 'plur', 'case' => 'acc'],
            # plural vocative
            'N' => ['number' => 'plur', 'case' => 'voc'],
            # plural ablative (rebus, quibus, his, aliis, omnibus)
            'O' => ['number' => 'plur', 'case' => 'abl']
        },
        'encode_map' =>
        {
            'number' => { 'plur' => { 'case' => { 'nom' => 'J',
                                                  'gen' => 'K',
                                                  'dat' => 'L',
                                                  'acc' => 'M',
                                                  'voc' => 'N',
                                                  'abl' => 'O',
                                                  '@'   => '-' }},
                          '@'    => { 'case' => { 'nom' => 'A',
                                                  'gen' => 'B',
                                                  'dat' => 'C',
                                                  'acc' => 'D',
                                                  'voc' => 'E',
                                                  'abl' => 'F',
                                                  'loc' => 'G',
                                                  '@'   => { 'other/case' => { 'plurimus' => 'H',
                                                                               '@'        => '-' }}}}}
        }
    );
    # 8. GENDER / NUMBER / PERSON ####################
    $atoms{gen} = $self->create_atom
    (
        'surfeature' => 'gen',
        'decode_map' =>
        {
            # masculine (intellectus, deus, actu, qui, deo)
            '1' => ['gender' => 'masc'],
            # feminine (forma, formam, formae, quae, materia)
            '2' => ['gender' => 'fem'],
            # neuter (quod, hoc, esse, quae, aliquid)
            '3' => ['gender' => 'neut'],
            # I singular (dico, respondeo, ostendi, attribui, baptizo)
            '4' => ['number' => 'sing', 'person' => '1'],
            # II singular (puta, facisti, es, odisti, dicas)
            '5' => ['number' => 'sing', 'person' => '2'],
            # III singular (est, sit, potest, oportet, habet)
            '6' => ['number' => 'sing', 'person' => '3'],
            # I plural (dicimus, videmus, possumus, intelligimus, cognoscimus)
            '7' => ['number' => 'plur', 'person' => '1'],
            # II plural (accipite, docete, estis, quaerite, ambuletis)
            '8' => ['number' => 'plur', 'person' => '2'],
            # III plural (sunt, sint, habent, possunt, dicuntur)
            '9' => ['number' => 'plur', 'person' => '3']
        },
        'encode_map' =>
        {
            'gender' => { 'masc' => '1',
                          'fem'  => '2',
                          'neut' => '3',
                          '@'    => { 'person' => { '1' => { 'number' => { 'sing' => '4',
                                                                           '@'    => '7' }},
                                                    '2' => { 'number' => { 'sing' => '5',
                                                                           '@'    => '8' }},
                                                    '3' => { 'number' => { 'sing' => '6',
                                                                           '@'    => '9' }},
                                                    '@' => '-' }}}
        }
    );
    # 9. COMPOSITION ####################
    $atoms{com} = $self->create_atom
    (
        'surfeature' => 'com',
        'decode_map' =>
        {
            # enclitic -ce
            'A' => ['other' => {'com' => 'ce'}],
            # enclitic -cum (nobiscum, secum)
            'C' => ['other' => {'com' => 'cum'}],
            # enclitic -met (ipsemet, ipsamet, ipsammet, ipsummet)
            'M' => ['other' => {'com' => 'met'}],
            # enclitic -ne
            'N' => ['other' => {'com' => 'ne'}],
            # enclitic -que (namque, corpori, eam, eandem, earumque)
            'Q' => ['other' => {'com' => 'que'}],
            # enclitic -tenus (aliquatenus, quatenus)
            'T' => ['other' => {'com' => 'tenus'}],
            # enclitic -ve (quid)
            'V' => ['other' => {'com' => 've'}],
            # ending homographic with enclitic (ratione, absque, quandoque, utrumque, cognitione)
            'H' => ['other' => {'com' => 'homographic'}],
            # composed with other form (inquantum, necesse-esse, intantum, proculdubio)
            'Z' => ['other' => {'com' => 'other'}],
            # composed as lemma
            'W' => ['other' => {'com' => 'lemma'}]
        },
        'encode_map' =>
        {
            'other/com' => { 'ce'          => 'A',
                             'cum'         => 'C',
                             'met'         => 'M',
                             'ne'          => 'N',
                             'que'         => 'Q',
                             'tenus'       => 'T',
                             've'          => 'V',
                             'homographic' => 'H',
                             'other'       => 'Z',
                             'lemma'       => 'W',
                             '@'           => '-' }
        }
    );
    # 10. FORMAL VARIATION ####################
    $atoms{var} = $self->create_atom
    (
        'surfeature' => 'var',
        'decode_map' =>
        {
            # I variation of wordform (qua, aliquod, aliquis, quoddam, quis)
            'A' => ['variant' => '1'],
            # II variation of wordform
            'B' => ['variant' => '2'],
            # III variation of wordform (illuc)
            'C' => ['variant' => '3'],
            # author mistake, or bad reading? (quod)
            'x' => ['typo' => 'yes'],
            'X' => ['typo' => 'yes']
        },
        'encode_map' =>
        {
            'typo' => { 'yes' => 'X',
                        '@'    => { 'variant' => { ''  => '-',
                                                   '1' => 'A',
                                                   '2' => 'B',
                                                   '@' => 'C' }}}
        }
    );
    # 11. GRAPHICAL VARIATION ####################
    $atoms{vgr} = $self->create_atom
    (
        'surfeature' => 'vgr',
        'decode_map' =>
        {
            # base form (sed, quae, ut, sicut, cum)
            '1' => ['other' => {'vgr' => '1'}],
            # graphical variations of “1” (ex, ab, eius, huiusmodi, cuius)
            '2' => ['other' => {'vgr' => '2'}],
            # (uniuscuiusque, cuiuscumque, 2-2, ioannis, joannem)
            '3' => ['other' => {'vgr' => '3'}],
            # (joannis)
            '4' => ['other' => {'vgr' => '4'}]
        },
        'encode_map' =>
        {
            'other/vgr' => { '1' => '1',
                             '2' => '2',
                             '3' => '3',
                             '4' => '4',
                             '@' => '-' }
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
    $fs->set_tagset($self->get_tagset_id());
    my $atoms = $self->atoms();
    # The tag is an eleven-position string.
    my @chars = split(//, $tag);
    my $subpos = $chars[2].$chars[0];
    shift(@chars);
    splice(@chars, 1, 1);
    $atoms->{subpos}->decode_and_merge_hard($subpos, $fs);
    my $features = $self->features();
    for (my $i = 0; $i <= $#chars; $i++)
    {
        $atoms->{$features->[$i]}->decode_and_merge_hard($chars[$i], $fs);
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
    my $subpos = $atoms->{subpos}->encode($fs);
    my $features = $self->features();
    my $tag = $subpos.join('', map {$atoms->{$_}->encode($fs)} (@{$features}));
    if($tag =~ m/^Punc/)
    {
        $tag = '-----------';
    }
    else
    {
        $tag =~ s/^(.)(.)(.)/$2$3$1/;
    }
    # There are two positions for degree of comparison. Only one should be used.
    $tag =~ s/^(1....)[123]/$1-/;
    $tag =~ s/^(2)[123]/$1-/;
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus: total 1492 tags.
# Removed wrong tags, kept 1476 tags.
# Added unknown tags for empty other feature: total 1635 tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
-----------
1-G--------
1-G-------1
1-G----1---
1-G----1--1
1-G----2---
1-G----2--1
1-G----3---
1-G----3--1
1-G---A3---
1-G---A3--1
1-G---B3---
1-G---C3---
1-G---D1---
1-G---D1--1
1-G---D3---
1-G---D3--1
1-G---F3---
1-G---G----
1-G---G---1
11A----1---
11A----2---
11A---A----
11A---A1---
11A---A1--1
11A---A1-A-
11A---A2---
11A---A2--1
11A---A2--2
11A---A2-A-
11A---A3---
11A---A3-A-
11A---B----
11A---B1---
11A---B1--1
11A---B2---
11A---B2--1
11A---B2--2
11A---B3---
11A---C1---
11A---C1--1
11A---C2---
11A---C2--1
11A---C3---
11A---D----
11A---D1---
11A---D1-A-
11A---D2---
11A---D2--1
11A---D2--2
11A---D2-A-
11A---D3---
11A---D3-A-
11A---E1---
11A---F----
11A---F1---
11A---F2---
11A---F2--1
11A---F2--2
11A---F2-A-
11A---F3---
11A---G----
11A---G--A-
11A---G--C-
11A---J1---
11A---J1--1
11A---J1--2
11A---J2---
11A---J2--1
11A---J2-A-
11A---J3---
11A---J3--1
11A---J3-A-
11A---K----
11A---K1---
11A---K1--2
11A---K2---
11A---K2--1
11A---K3---
11A---L1---
11A---L2---
11A---L2--1
11A---L3---
11A---M----
11A---M1---
11A---M2---
11A---M2--1
11A---M2-A-
11A---M3---
11A---M3--1
11A---O----
11A---O1---
11A---O1--1
11A---O2---
11A---O2--1
11A---O3---
11A---O3--1
11A-1-M3---
11B---A1---
11B---A1--1
11B---A1--2
11B---A2---
11B---A2--1
11B---A2--2
11B---A3---
11B---A3--1
11B---A3--2
11B---A3H--
11B---B1---
11B---B1--1
11B---B1--2
11B---B2---
11B---B3---
11B---B3--1
11B---B3--2
11B---C1---
11B---C1--1
11B---C2---
11B---C3---
11B---C3--1
11B---C3--2
11B---D1---
11B---D1--1
11B---D2---
11B---D2--2
11B---D3---
11B---D3--1
11B---D3--2
11B---E1---
11B---E1--1
11B---E1H--
11B---F1---
11B---F1--1
11B---F3---
11B---F3--1
11B---F3--2
11B---G----
11B---G---1
11B---G---2
11B---G-H--
11B---G-H-1
11B---J1---
11B---J1--1
11B---J1--2
11B---J2---
11B---J3---
11B---J3--1
11B---J3--2
11B---K1---
11B---K1--1
11B---K1--2
11B---K2---
11B---K3---
11B---K3--1
11B---K3--2
11B---L1---
11B---L1--1
11B---L3---
11B---L3--1
11B---M1---
11B---M1--1
11B---M3---
11B---M3--1
11B---M3--2
11B---O1---
11B---O1--1
11B---O2---
11B---O2--1
11B---O3---
11B---O3--1
11B---O3--2
11C---A----
11C---A1---
11C---A1--1
11C---A1--2
11C---A2---
11C---A2--1
11C---A2--2
11C---A3---
11C---A3--1
11C---B1---
11C---B1--1
11C---B1--3
11C---B1--4
11C---B2---
11C---B2--1
11C---B2--2
11C---B3---
11C---B3--1
11C---B3--2
11C---C1---
11C---C1--1
11C---C1--2
11C---C2---
11C---C2--1
11C---C3---
11C---C3--1
11C---C3Q--
11C---D----
11C---D1---
11C---D1--1
11C---D1--3
11C---D2---
11C---D2--1
11C---D2--2
11C---D3---
11C---D3--1
11C---D3-A-
11C---D3H--
11C---E1---
11C---F----
11C---F1---
11C---F1--1
11C---F1H--
11C---F2---
11C---F2--1
11C---F2H--
11C---F2H-1
11C---F2H-2
11C---F3---
11C---F3--1
11C---F3H--
11C---F3H-1
11C---G----
11C---G---1
11C---G---2
11C---J1---
11C---J1--1
11C---J2---
11C---J2--1
11C---J2--2
11C---J3---
11C---J3--1
11C---K----
11C---K1---
11C---K1--1
11C---K2---
11C---K2--1
11C---K3---
11C---K3--1
11C---L1---
11C---L1--1
11C---L2---
11C---L2--1
11C---L2--2
11C---L3---
11C---L3--1
11C---M1---
11C---M1--1
11C---M2---
11C---M2--1
11C---M2--2
11C---M3---
11C---M3--1
11C---O----
11C---O1---
11C---O1--1
11C---O1--2
11C---O2---
11C---O2--1
11C---O2--2
11C---O3---
11C---O3--1
11D---A1---
11D---A1--1
11D---A2---
11D---A3---
11D---B1---
11D---B1--1
11D---B2---
11D---C1---
11D---C2---
11D---C3---
11D---D1---
11D---D1--1
11D---D2---
11D---D3---
11D---F1---
11D---F1--1
11D---F2---
11D---F3---
11D---G----
11D---J1---
11D---J3---
11D---K1---
11D---K2---
11D---L1---
11D---M1---
11D---M2---
11D---O1---
11D---O3---
11E---A1---
11E---A2---
11E---A2--1
11E---B1---
11E---B2---
11E---C2---
11E---D1---
11E---D2---
11E---F1---
11E---F2---
11E---G----
11E---J1---
11E---J2---
11E---K1---
11E---K2---
11E---K3---
11E---L2---
11E---M1---
11E---M2---
11E---O1---
11E---O2---
11F---A1---
11F---A1--1
11F---A1--2
11F---A1-A-
11F---A1H--
11F---A1M--
11F---A2---
11F---A2--1
11F---A2--2
11F---A2-A-
11F---A2H--
11F---A2M--
11F---A2T--
11F---A3---
11F---A3--1
11F---A3--2
11F---A3-A-
11F---A3H-2
11F---A3M--
11F---A3V--
11F---B---2
11F---B-H--
11F---B1---
11F---B1--1
11F---B1--2
11F---B1H--
11F---B2---
11F---B2--1
11F---B2--2
11F---B2--3
11F---B2H--
11F---B3---
11F---B3--1
11F---B3--2
11F---B3--3
11F---B3H--
11F---C1---
11F---C1--1
11F---C1H--
11F---C2---
11F---C2--1
11F---C3---
11F---C3H--
11F---D1---
11F---D1--1
11F---D1--2
11F---D1-A-
11F---D2---
11F---D2--1
11F---D2--2
11F---D2-A-
11F---D2H-2
11F---D2M--
11F---D2Q--
11F---D2Q-1
11F---D3---
11F---D3--1
11F---D3--2
11F---D3-A-
11F---D3H-2
11F---E1---
11F---F-T--
11F---F1---
11F---F1--1
11F---F1H--
11F---F1H-2
11F---F2---
11F---F2--1
11F---F2-A-
11F---F2C--
11F---F2H--
11F---F2H-2
11F---F2T--
11F---F3---
11F---F3--1
11F---F3C--
11F---F3H--
11F---F3H-2
11F---G----
11F---G---1
11F---G--A-
11F---G--C-
11F---H1---
11F---J1---
11F---J1--1
11F---J1--2
11F---J2---
11F---J2--1
11F---J2--2
11F---J2-A-
11F---J3---
11F---J3--1
11F---J3--2
11F---J3-A-
11F---K----
11F---K1---
11F---K1--1
11F---K1--2
11F---K2---
11F---K2--1
11F---K2--2
11F---K2Q--
11F---K3---
11F---K3--1
11F---K3--2
11F---L1---
11F---L1--1
11F---L1C--
11F---L2---
11F---L2--1
11F---L3---
11F---L3--1
11F---L3H-2
11F---M----
11F---M1---
11F---M1--1
11F---M1H--
11F---M2---
11F---M2--1
11F---M2-A-
11F---M2H--
11F---M3---
11F---M3--1
11F---M3--2
11F---M3H-2
11F---O----
11F---O1---
11F---O1--1
11F---O1--2
11F---O1C--
11F---O1H--
11F---O1H-2
11F---O2---
11F---O2--1
11F---O2C--
11F---O2H-2
11F---O3---
11F---O3--1
11F---O3H--
11F---O3H-2
11F-1-M3---
12A---A1---
12A---A2---
12A---A3---
12A---B1---
12A---B2---
12A---B3---
12A---C1---
12A---C2---
12A---C3---
12A---D1---
12A---D2---
12A---D3---
12A---F1---
12A---F2---
12A---F3---
12A---G----
12A---J1---
12A---J2---
12A---J3---
12A---K1---
12A---K2---
12A---K3---
12A---L1---
12A---L2---
12A---L3---
12A---M1---
12A---M2---
12A---M3---
12A---O1---
12A---O2---
12A---O3---
12B---A3--1
12B---D3--1
12B---G---1
12C---A1---
12C---A1--1
12C---A1--2
12C---A2---
12C---A2--1
12C---A2--2
12C---A3---
12C---A3--1
12C---A3--2
12C---B1---
12C---B1--1
12C---B2---
12C---B2--1
12C---B2--2
12C---B3---
12C---C1---
12C---C2---
12C---C3---
12C---D1---
12C---D1--2
12C---D2---
12C---D2--1
12C---D2--2
12C---D3---
12C---D3--2
12C---F1---
12C---F2---
12C---F2--2
12C---F3---
12C---F3--2
12C---G----
12C---G---1
12C---J1---
12C---J1--2
12C---J2---
12C---J3---
12C---J3--1
12C---K1---
12C---K2---
12C---K3---
12C---L1---
12C---L2---
12C---L3---
12C---M1---
12C---M2---
12C---M3---
12C---M3--2
12C---O1---
12C---O2---
12C---O3---
13A---A1---
13A---A2---
13A---A2--1
13A---A3---
13A---B1---
13A---B2---
13A---B3---
13A---C1---
13A---C2---
13A---C3---
13A---D1---
13A---D2---
13A---D3---
13A---E1---
13A---F1---
13A---F2---
13A---F3---
13A---G----
13A---J1---
13A---J2---
13A---J3---
13A---J3-A-
13A---K1---
13A---K2---
13A---K3---
13A---L3---
13A---M1---
13A---M2---
13A---M3---
13A---O2---
13A---O3---
13B---A1---
13B---A2---
13B---A3---
13B---B1---
13B---B3---
13B---C1---
13B---C3---
13B---D1---
13B---D2---
13B---D3---
13B---E1---
13B---F1---
13B---F3---
13B---G----
13B---G---1
13B---G-Q--
13B---J1---
13B---J3---
13B---J3-A-
13B---K1---
13B---K3---
13B---L3---
13B---M1---
13B---M3---
13B---O3---
13C---G---1
2-JD11A----
2-JD11A1---
2-JD11A1--1
2-JD11A2---
2-JD11A2--1
2-JD11A3---
2-JD11B1---
2-JD11B1--2
2-JD11B2---
2-JD11B3---
2-JD11C1---
2-JD11C2---
2-JD11C3---
2-JD11D1---
2-JD11D2---
2-JD11D3---
2-JD11D3--2
2-JD11F1---
2-JD11F2---
2-JD11F3---
2-JD11G----
2-JD11J1---
2-JD11J1--1
2-JD11J2---
2-JD11J3---
2-JD11K1---
2-JD11K2---
2-JD11K3---
2-JD11L1---
2-JD11L2---
2-JD11L3---
2-JD11M1---
2-JD11M2---
2-JD11M3---
2-JD11M3--1
2-JD11O1---
2-JD11O2---
2-JD11O3---
2-JD12A1---
2-JD12A2---
2-JD12A3---
2-JD12D1---
2-JD12G----
2-JD13A3---
2-JD13B2---
2-JD13D2---
2-JD31A1---
2-JD31A1--2
2-JD31B1---
2-JD31D1---
2-JD31D2---
2-JD31O3---
2-JE-1A3---
2-JE-1B----
2-JE-1B---1
2-JE-1B---2
2-JE-1D----
2-JE-1D---1
2-JE-1D---2
2-JE-1F----
2-JE-1F---1
2-JE-1F---2
2-JE-1F3---
2-JM-1F3---
2-JM11A1---
2-JM11A2---
2-JM11A3---
2-JM11B1---
2-JM11B2---
2-JM11B3---
2-JM11C2---
2-JM11D1---
2-JM11D2---
2-JM11D3---
2-JM11F1---
2-JM11F2---
2-JM11F3---
2-JM11G----
2-JM11J1---
2-JM11J2---
2-JM11J3---
2-JM11K1---
2-JM11K2---
2-JM11K3---
2-JM11L1---
2-JM11M1---
2-JM11M2---
2-JM11M3---
2-JM11O1---
2-JM11O2---
2-JM11O3---
2-JM41A1---
2-JM41A1--2
2-JM41A2---
2-JM41A2--1
2-JM41A2-A-
2-JM41A3---
2-JM41A3--1
2-JM41B1---
2-JM41B2---
2-JM41B2--1
2-JM41B2-A-
2-JM41B3---
2-JM41B3--1
2-JM41C1---
2-JM41C2---
2-JM41C2--1
2-JM41C3---
2-JM41D1---
2-JM41D2---
2-JM41D2--1
2-JM41D2-A-
2-JM41D3---
2-JM41D3--1
2-JM41E1---
2-JM41F1---
2-JM41F2---
2-JM41F2--1
2-JM41F3---
2-JM41G----
2-JM41J1---
2-JM41J1--1
2-JM41J2---
2-JM41J2--1
2-JM41J3---
2-JM41J3--1
2-JM41K1---
2-JM41K2---
2-JM41K3---
2-JM41L----
2-JM41L1---
2-JM41L2---
2-JM41L3---
2-JM41M1---
2-JM41M2---
2-JM41M3---
2-JM41M3--1
2-JM41O----
2-JM41O1---
2-JM41O2---
2-JM41O3---
2-JM42A1---
2-JM42A2---
2-JM42A3---
2-JM42D2---
2-JM42D3---
2-JM42G----
2-JM42J1---
2-JM42J2---
2-JM42M3---
2-JM43A2---
2-JM43A3---
2-JM43D3---
2-JM43J3---
2-JM43M2---
2-JM43M3---
2-JN-1B----
2-JN-1D----
2-JN-1F----
2-JO-1A1---
2-JO-1A2---
2-JO-1A2--1
2-JO-1A3---
2-JO-1A3--1
2-JO-1B2---
2-JO-1B2-A-
2-JO-1B3---
2-JO-1C2---
2-JO-1D1---
2-JO-1D2---
2-JO-1D3---
2-JO-1F2---
2-JO-1J2---
2-JO-1J3---
2-JO-1K2---
2-JO-1K3---
2-JO-1M1---
2-JO-1M2---
2-JO-1M3---
2-JO-1O1---
2-JO-1O2---
2-JO-1O3---
2-KD11A----
2-KD11A1---
2-KD11A1--1
2-KD11A2---
2-KD11A2--1
2-KD11A2--2
2-KD11A3---
2-KD11A3--1
2-KD11B1---
2-KD11B1--1
2-KD11B2---
2-KD11B2--1
2-KD11B3---
2-KD11C1---
2-KD11C2---
2-KD11C3---
2-KD11D1---
2-KD11D2---
2-KD11D2--2
2-KD11D3---
2-KD11D3--1
2-KD11F1---
2-KD11F2---
2-KD11F2--1
2-KD11F2--2
2-KD11F3---
2-KD11F3--2
2-KD11G----
2-KD11J1---
2-KD11J2---
2-KD11J2--1
2-KD11J3---
2-KD11K2---
2-KD11K3---
2-KD11L1---
2-KD11L3---
2-KD11M2---
2-KD11M3---
2-KD11O1---
2-KD11O2---
2-KD11O3---
2-KD12A2---
2-KD12A3---
2-KD12D1---
2-KD12G----
2-KD31A1---
2-KD31D1---
2-KE-1B----
2-KE-1D----
2-KE-1F----
2-KE-1F---1
2-KE-1F3---
2-KM11J1---
2-KM41A1---
2-KM41A1--1
2-KM41A2---
2-KM41A2--1
2-KM41A3---
2-KM41A3--1
2-KM41B1---
2-KM41B2---
2-KM41B3---
2-KM41B3--1
2-KM41C3--1
2-KM41D1---
2-KM41D1--1
2-KM41D2---
2-KM41D2--1
2-KM41D3---
2-KM41D3--1
2-KM41F1---
2-KM41F2---
2-KM41F3---
2-KM41F3--1
2-KM41G----
2-KM41J1---
2-KM41J2---
2-KM41J3---
2-KM41J3--1
2-KM41K3---
2-KM41K3--1
2-KM41M1---
2-KM41M2---
2-KM41M3---
2-KM41M3--1
2-KM41O1---
2-KM41O2---
2-KM41O3---
2-KM41O3--1
2-KM42A3---
2-KM42D3---
2-KM42M3---
2-KM43J3---
2-KM43M3---
2-KO-1A1---
2-KO-1A2---
2-KO-1B2---
2-KO-1B3---
2-KO-1C2---
2-KO-1D2---
2-KO-1D3---
2-KO-1J3---
2-KO-1M2---
2-KO-1M3---
2-LD11A1---
2-LD11A1--1
2-LD11A1--2
2-LD11A2---
2-LD11A2--1
2-LD11A3---
2-LD11A3--1
2-LD11A3--2
2-LD11B1---
2-LD11B1--1
2-LD11B2---
2-LD11B2--1
2-LD11B3---
2-LD11B3--1
2-LD11C1---
2-LD11C2---
2-LD11C3---
2-LD11C3--1
2-LD11D1---
2-LD11D2---
2-LD11D2--1
2-LD11D3---
2-LD11D3--1
2-LD11F1---
2-LD11F1--1
2-LD11F2---
2-LD11F2--1
2-LD11F3---
2-LD11F3--1
2-LD11G----
2-LD11J1---
2-LD11J1--1
2-LD11J1--2
2-LD11J2---
2-LD11J2--1
2-LD11J3---
2-LD11J3--1
2-LD11K1---
2-LD11K1--1
2-LD11K1--2
2-LD11K2---
2-LD11K2--1
2-LD11K3---
2-LD11K3--1
2-LD11L1---
2-LD11L2---
2-LD11L2--1
2-LD11L3---
2-LD11M1---
2-LD11M1--1
2-LD11M2---
2-LD11M2--1
2-LD11M3---
2-LD11M3--1
2-LD11O1---
2-LD11O2---
2-LD11O2--1
2-LD11O3---
2-LD11O3--1
2-LD12A3---
2-LD13B2---
2-LD13D2---
2-LD31D1---
2-LE-1B----
2-LE-1B---2
2-LE-1D----
2-LE-1D---1
2-LE-1F----
2-LE-1F---1
2-LM-1F3---
2-LM11A1---
2-LM11A1--1
2-LM11A2---
2-LM11A3---
2-LM11A3--1
2-LM11B2---
2-LM11B3---
2-LM11B3--1
2-LM11D1---
2-LM11D2---
2-LM11D3---
2-LM11F1---
2-LM11F2---
2-LM11F3---
2-LM11G----
2-LM11G---1
2-LM11J1---
2-LM11J2---
2-LM11K1---
2-LM11K1--1
2-LM11K2--1
2-LM11K3--1
2-LM11L1---
2-LM11M1---
2-LM11M2---
2-LM11M3--1
2-LM11O1---
2-LM11O2---
2-LM11O3---
2-LM11O3--1
2-LM41A1---
2-LM41A1--1
2-LM41A1--2
2-LM41A2---
2-LM41A2--1
2-LM41A2--2
2-LM41A2-A-
2-LM41A3---
2-LM41A3--1
2-LM41A3--2
2-LM41B1---
2-LM41B2---
2-LM41B2--1
2-LM41B3---
2-LM41B3--1
2-LM41B3--2
2-LM41C1---
2-LM41C2---
2-LM41C3---
2-LM41D1---
2-LM41D1--2
2-LM41D2---
2-LM41D2--1
2-LM41D2--2
2-LM41D2-A-
2-LM41D3---
2-LM41D3--1
2-LM41E1---
2-LM41F1---
2-LM41F1--1
2-LM41F2---
2-LM41F2--1
2-LM41F2--2
2-LM41F3---
2-LM41F3--1
2-LM41F3--2
2-LM41G----
2-LM41J1---
2-LM41J1--1
2-LM41J2---
2-LM41J2--1
2-LM41J2--2
2-LM41J3---
2-LM41J3--1
2-LM41J3--2
2-LM41K1---
2-LM41K2---
2-LM41K3---
2-LM41L1---
2-LM41L2---
2-LM41L3---
2-LM41M1---
2-LM41M1--1
2-LM41M2---
2-LM41M3---
2-LM41M3--1
2-LM41O1---
2-LM41O2---
2-LM41O3---
2-LM41O3--1
2-LM42A1---
2-LM42A1--1
2-LM42A2---
2-LM42A2--1
2-LM42A3--1
2-LM42D2---
2-LM42J1---
2-LM42J2---
2-LM43A2---
2-LM43A3---
2-LM43J3---
2-LM43M2---
2-LN-1B----
2-LN-1D----
2-LN-1F----
2-LO-1A1---
2-LO-1A2---
2-LO-1A2--1
2-LO-1A3---
2-LO-1A3--1
2-LO-1A3--2
2-LO-1C2--2
2-LO-1D1---
2-LO-1D2---
2-LO-1D3---
2-LO-1F2--1
2-LO-1J2---
2-LO-1J3---
2-LO-1K3---
2-LO-1M1---
2-LO-1M2---
2-LO-1M3---
2-LO-1O2---
2-LO-1O3---
2-MD11A1---
2-MD11A1--1
2-MD11A2---
2-MD11A2--1
2-MD11A3---
2-MD11A3--1
2-MD11B1---
2-MD11B2---
2-MD11B3---
2-MD11C1---
2-MD11D1---
2-MD11D2---
2-MD11D2--1
2-MD11D3---
2-MD11D3--1
2-MD11F1---
2-MD11F2---
2-MD11F3---
2-MD11G---1
2-MD11J1---
2-MD11J1--1
2-MD11J2---
2-MD11J2--1
2-MD11J3---
2-MD11J3--1
2-MD11L1---
2-MD11M3--1
2-MD11O2---
2-MD11O3--1
2-MD12A1---
2-MD12A2---
2-MD12G---1
2-MD13A3---
2-MD31B1---
2-MD31D1---
2-ME-1B----
2-ME-1D----
2-ME-1F----
2-MM41A1---
2-MM41A2---
2-MM41A3---
2-MM41B2---
2-MM41B3---
2-MM41C2---
2-MM41C3---
2-MM41D1---
2-MM41D2---
2-MM41D3---
2-MM41D3--1
2-MM41F2---
2-MM41F3---
2-MM41G----
2-MM41J1---
2-MM41J2---
2-MM41J3---
2-MM41K1---
2-MM41K2---
2-MM41K3---
2-MM41L1---
2-MM41M1---
2-MM41M2---
2-MM41M3---
2-MM41O2---
2-MM41O3---
2-MM42G----
2-MO-1A3---
2-MO-1A3--1
2-MO-1D2---
2-ND11A1---
2-ND11A1--1
2-ND11A2---
2-ND11A2--1
2-ND11A3---
2-ND11B1---
2-ND11B2---
2-ND11B3---
2-ND11C1---
2-ND11D1---
2-ND11D2---
2-ND11D2--1
2-ND11D3---
2-ND11F1---
2-ND11F2---
2-ND11F3---
2-ND11G----
2-ND11J1---
2-ND11J2---
2-ND11J2--1
2-ND11J3---
2-ND11J3--1
2-ND11K1---
2-ND11K2---
2-ND11K3---
2-ND11L1---
2-ND11M2---
2-ND11M2--1
2-ND11M3---
2-ND11M3--1
2-ND11O3---
2-ND12A2---
2-ND31D1---
2-ND31D2---
2-ND31O3---
2-NE-1A3---
2-NE-1B----
2-NE-1D----
2-NE-1F----
2-NM11B1---
2-NM41A1---
2-NM41A2---
2-NM41A2--1
2-NM41A3---
2-NM41A3--1
2-NM41B1---
2-NM41B2---
2-NM41B3---
2-NM41B3--1
2-NM41C2---
2-NM41C3---
2-NM41D1---
2-NM41D1--1
2-NM41D2---
2-NM41D2--1
2-NM41D3---
2-NM41D3--1
2-NM41F1---
2-NM41F2---
2-NM41F2--1
2-NM41F3---
2-NM41J1---
2-NM41J1--1
2-NM41J2---
2-NM41J3---
2-NM41J3--1
2-NM41K1--1
2-NM41K2---
2-NM41K2--1
2-NM41K3---
2-NM41K3--1
2-NM41L1--1
2-NM41L2--1
2-NM41L3--1
2-NM41M1--1
2-NM41M2---
2-NM41M3---
2-NM41M3--1
2-NM41O1--1
2-NM41O2---
2-NM41O2--1
2-NM41O3---
2-NM41O3--1
2-NN-1B----
2-NN-1F----
2-NO-1A2---
2-NO-1A3---
2-NO-1B2---
2-NO-1B2-A-
2-NO-1C2---
2-NO-1D2---
2-NO-1D3---
2-NO-1F2---
2-NO-1J2---
2-NO-1J3---
2-NO-1K2---
2-NO-1K3---
2-NO-1M1---
2-NO-1M2---
2-NO-1O1---
3-JA1--4---
3-JA1--5---
3-JA1--6---
3-JA1--6--1
3-JA1--6--2
3-JA1--7---
3-JA1--7--1
3-JA1--8---
3-JA1--9---
3-JA1--9--1
3-JA2--6---
3-JA2--6--2
3-JA2--9---
3-JA2--9--1
3-JA3--4---
3-JA3--4--1
3-JA3--4--2
3-JA3--5---
3-JA3--6---
3-JA3--6--1
3-JA3--6--2
3-JA3--7---
3-JA3--8---
3-JA3--9---
3-JA4--4---
3-JA4--5---
3-JA4--6---
3-JA4--6--1
3-JA4--6--2
3-JA4--7---
3-JA4--8---
3-JA4--9---
3-JA4--9--1
3-JA4--9-A-
3-JA5--6---
3-JA5--6--2
3-JA5--9---
3-JA6--5---
3-JA6--6---
3-JA6--8---
3-JA6--9---
3-JB1--4---
3-JB1--5---
3-JB1--6---
3-JB1--6--1
3-JB1--6--2
3-JB1--7---
3-JB1--8---
3-JB1--9---
3-JB1--9--1
3-JB2--4---
3-JB2--5---
3-JB2--6---
3-JB2--6--1
3-JB2--7---
3-JB2--9---
3-JB4--6---
3-JB4--7---
3-JB4--9---
3-JB5--6---
3-JB5--7---
3-JB5--9---
3-JC1--5---
3-JC1--8---
3-JC3--5---
3-JC3--8---
3-JH1------
3-JH1-----1
3-JH1-----2
3-JH3------
3-JH4------
3-JJ1--4---
3-JJ1--6---
3-JJ1--6--1
3-JJ1--6--2
3-JJ1--7---
3-JJ1--9---
3-JJ1--9--1
3-JJ2--4---
3-JJ2--6---
3-JJ2--9---
3-JJ3--4---
3-JJ3--5---
3-JJ3--6---
3-JJ3--6--1
3-JJ3--7---
3-JJ3--9---
3-JK1--4---
3-JK1--6---
3-JK1--6--1
3-JK1--7---
3-JK1--9---
3-JK2--6---
3-JK2--6--1
3-JK2--6--2
3-JK2--7---
3-JK2--9---
3-JL1--5---
3-JQ1------
3-JQ1-----1
3-KA1--4---
3-KA1--5---
3-KA1--6---
3-KA1--6--1
3-KA1--6--2
3-KA1--7---
3-KA1--7--1
3-KA1--9---
3-KA1--9--1
3-KA2--6---
3-KA2--6--1
3-KA2--9---
3-KA3--6---
3-KA3--7---
3-KA3--7--1
3-KA3--9---
3-KA4--4---
3-KA4--6---
3-KA4--6--1
3-KA4--9---
3-KA5--6---
3-KA6--5---
3-KA6--6---
3-KB1--4---
3-KB1--6---
3-KB1--6--1
3-KB1--6--2
3-KB1--7--1
3-KB1--9---
3-KB1--9--1
3-KB2--6---
3-KB2--7---
3-KB2--9---
3-KB4--6---
3-KB4--7---
3-KB5--6---
3-KC1--8---
3-KH1------
3-KH1-----1
3-KH4------
3-KJ1--6---
3-KJ1--6--1
3-KJ1--7---
3-KJ1--9---
3-KJ1--9--1
3-KJ2--6---
3-KJ2--6--1
3-KJ3--6---
3-KJ3--6--1
3-KJ3--9---
3-KK1--6---
3-KK1--6--1
3-KK1--7---
3-KK1--9---
3-KK1--9--1
3-KK2--6---
3-KK2--6--1
3-KK2--7---
3-KK2--9---
3-KL1--5---
3-KQ1------
3-KQ1-----1
3-LA1--4---
3-LA1--4--1
3-LA1--5---
3-LA1--6---
3-LA1--6--1
3-LA1--6--2
3-LA1--7---
3-LA1--7--1
3-LA1--9---
3-LA1--9--1
3-LA1--9--2
3-LA2--6---
3-LA2--9---
3-LA2--9--1
3-LA3--4---
3-LA3--5---
3-LA3--6---
3-LA3--7---
3-LA3--8---
3-LA3--9---
3-LA4--4---
3-LA4--4--1
3-LA4--5---
3-LA4--6---
3-LA4--6--1
3-LA4--6--2
3-LA4--7---
3-LA4--9---
3-LA4--9--2
3-LA4--9-A-
3-LA5--6---
3-LA6--6---
3-LB1--5---
3-LB1--6---
3-LB1--6--1
3-LB1--6--2
3-LB1--7---
3-LB1--8---
3-LB1--9---
3-LB2--6---
3-LB2--6--1
3-LB2--6--2
3-LB2--7---
3-LB2--9---
3-LB4--6---
3-LB4--6--2
3-LB5--6---
3-LB5--6--2
3-LB5--7---
3-LB5--9---
3-LC1--5---
3-LC1--8---
3-LC1--8--1
3-LH1------
3-LH1-----1
3-LH1-----2
3-LH4------
3-LH4-----1
3-LH4-----2
3-LJ1--6---
3-LJ1--6--1
3-LJ1--6--2
3-LJ1--7---
3-LJ1--9---
3-LJ1--9--1
3-LJ1--9--2
3-LJ2--6---
3-LJ2--6--1
3-LJ2--6--2
3-LJ2--9---
3-LJ3--4---
3-LJ3--5---
3-LJ3--6---
3-LJ3--6--1
3-LJ3--7---
3-LJ3--9---
3-LK1--6---
3-LK1--6--1
3-LK1--6--2
3-LK1--7---
3-LK1--9---
3-LK1--9--1
3-LK1--9--2
3-LK2--6---
3-LK2--6--1
3-LK2--6--2
3-LK2--9---
3-LK2--9--2
3-LQ1------
3-LQ1-----1
3-LQ1-----2
3-MA1--4---
3-MA1--5---
3-MA1--6---
3-MA1--6--1
3-MA1--7---
3-MA1--9---
3-MA1--9--1
3-MA2--6---
3-MA2--9---
3-MA3--4---
3-MA3--5---
3-MA3--6---
3-MA3--7---
3-MA4--4--2
3-MA4--5---
3-MA4--6---
3-MA4--6--1
3-MA4--7---
3-MA4--9---
3-MA5--9---
3-MB1--6---
3-MB1--6--1
3-MB1--7---
3-MB1--9---
3-MB2--6---
3-MB2--9---
3-MB4--6---
3-MB5--6--1
3-MB5--7---
3-MC1--5---
3-MC1--8---
3-MH1------
3-MH1-----1
3-MH4------
3-MH4-----1
3-MJ1--6---
3-MJ1--6--1
3-MJ1--7---
3-MJ1--9---
3-MJ1--9--1
3-MJ2--6---
3-MJ3--6---
3-MJ3--9---
3-MK1--6---
3-MK1--6--1
3-MK1--9---
3-MK2--6---
3-MK2--7---
3-MK2--9---
3-MQ1------
3-MQ1-----1
3-NA1--4---
3-NA1--5---
3-NA1--5--1
3-NA1--6---
3-NA1--6--1
3-NA1--6Q--
3-NA1--7---
3-NA1--7--1
3-NA1--8---
3-NA1--9---
3-NA1--9--1
3-NA2--6---
3-NA2--6--1
3-NA2--9---
3-NA3--4---
3-NA3--5---
3-NA3--6---
3-NA3--7---
3-NA3--9---
3-NA4--4---
3-NA4--5---
3-NA4--6---
3-NA4--6--1
3-NA4--6--2
3-NA4--7---
3-NA4--8---
3-NA4--9---
3-NA5--6---
3-NA5--9---
3-NA6--6---
3-NA6--8---
3-NA6--9---
3-NB1--4---
3-NB1--5---
3-NB1--6---
3-NB1--6--1
3-NB1--6--2
3-NB1--7---
3-NB1--9---
3-NB2--5---
3-NB2--6---
3-NB2--6Q--
3-NB2--7---
3-NB2--9---
3-NB4--6---
3-NB4--7---
3-NB4--9---
3-NB5--6---
3-NB5--9---
3-NC1--8---
3-NC3--5---
3-NC3--8---
3-NH1------
3-NH1-----1
3-NH3------
3-NH4------
3-NJ1--6---
3-NJ1--7---
3-NJ1--9---
3-NJ2--6---
3-NJ2--9---
3-NJ3--6---
3-NJ3--9---
3-NK1--6---
3-NK1--7---
3-NK1--9---
3-NK2--6---
3-NK2--9---
3-NQ1------
38NH1---Z--
4-O--------
4-O-------1
4-O-------2
4-O------A-
4-O-----H--
4-O-----Q--
4-S--------
4-S-------1
4-S-------2
4-S-----H--
48O-----Z--
5----------
5---------1
5------1---
5------2---
5-G--------
5-G-------1
5-G-------3
5-G----7---
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

Lingua::Interset::Tagset::LA::It - Driver for the positional tagset of the Index Thomisticus Treebank.

=head1 VERSION

version 3.005

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

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
