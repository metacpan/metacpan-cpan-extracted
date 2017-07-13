# ABSTRACT: Driver for the Portuguese tagset of the CoNLL 2006 Shared Task (derived from the Bosque / Floresta sintá(c)tica treebank).
# Copyright © 2007-2009, 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::PT::Conll;
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
    return 'pt::conll';
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
            # n = common noun
            # example: ano, dia, país, grupo, governo; parte, semana, empresa, cidade, forma
            'n'         => ['pos' => 'noun', 'nountype' => 'com'],
            # prop = proper noun
            # example: Portugal, Brasil, São_Paulo; Coimbra, Alvalade; EUA, Estados_Unidos
            'prop'      => ['pos' => 'noun', 'nountype' => 'prop'],
            # adj = adjective
            # example: novo, grande, próximo, bom, nacional
            'adj'       => ['pos' => 'adj'],
            # art = article
            # example: a, as, o, os, uma, um
            'art'       => ['pos' => 'adj', 'prontype' => 'art'],
            # pron-pers = personal # example: ela, elas, ele, eles, eu, nós, se, tu, você, vós
            'pron-pers' => ['pos' => 'noun', 'prontype' => 'prs'],
            # pron-det = determiner # example: algo, ambos, bastante, demais, este, menos, nosso, o, que, todo_o
            'pron-det'  => ['pos' => 'adj', 'prontype' => 'prn'],
            # pron-indp = independent # example: algo, aquilo, cada_qual, o, o_que, que, todo_o_mundo, um_pouco
            'pron-indp' => ['pos' => 'noun', 'prontype' => 'ind'],
            # num = number
            # example: 0,05, cento_e_quatro, cinco, setenta_e_dois, um, zero
            'num'       => ['pos' => 'num'],
            # v-inf = infinitive
            # example: ser, ter, fazer, ver, dar
            'v-inf'     => ['pos' => 'verb', 'verbform' => 'inf'],
            # v-fin = finite
            # example: abafaram, abalou, abandonará...
            'v-fin'     => ['pos' => 'verb', 'verbform' => 'fin'],
            # v-pcp = participle
            # example: passado, feito, eleito, aberto, considerado
            'v-pcp'     => ['pos' => 'verb', 'verbform' => 'part'],
            # v-ger = gerund
            # example: abraçando, abrindo, acabando...
            'v-ger'     => ['pos' => 'verb', 'verbform' => 'ger'],
            # vp = verb phrase
            # 1 occurrence in CoNLL 2006 data ("existente"), looks like an error
            'vp'        => ['pos' => 'adj', 'other' => {'pos' => 'vp'}],
            # adv = adverb
            # example: não, também, ontem, ainda, já
            'adv'       => ['pos' => 'adv'],
            # pp = prepositional phrase
            # example: de_facto, ao_mesmo_tempo, em_causa, por_vezes, de_acordo
            'pp'        => ['pos' => 'adv', 'other' => {'pos' => 'pp'}],
            # prp = preposition
            # example: de, em, para, a, com, por, sobre, entre
            'prp'       => ['pos' => 'adp', 'adpostype' => 'prep'],
            # coordinating conjunction
            # example: e, mais, mas, nem, ou, quer, tampouco, tanto
            'conj-c'    => ['pos' => 'conj', 'conjtype' => 'coor'],
            # subordinating conjunction
            # example: que, se, porque, do_que, embora
            'conj-s'    => ['pos' => 'conj', 'conjtype' => 'sub'],
            # in = interjection # example: adeus, ai, alô
            'in'        => ['pos' => 'int'],
            # ec = partial word # example: anti-, ex-, pós, pré-
            'ec'        => ['pos' => 'part', 'hyph' => 'yes'],
            # punc = punctuation # example: --, -, ,, ;, :, !, ?:?...
            'punc'      => ['pos' => 'punc'],
            # ? = unknown # 2 occurrences in CoNLL 2006 data
            '?'         => [],
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''    => { 'nountype' => { 'prop' => 'prop',
                                                                              '@'    => 'n' }},
                                                   'prs' => 'pron-pers',
                                                   'rcp' => 'pron-pers',
                                                   '@'   => 'pron-indp' }},
                       'adj'  => { 'prontype' => { ''    => { 'other/pos' => { 'vp' => 'vp',
                                                                               '@'  => 'adj' }},
                                                   'art' => 'art',
                                                   '@'   => 'pron-det' }},
                       'num'  => 'num',
                       'verb' => { 'verbform' => { 'inf'  => 'v-inf',
                                                   'fin'  => 'v-fin',
                                                   'part' => 'v-pcp',
                                                   'ger'  => 'v-ger' }},
                       'adv'  => { 'other/pos' => { 'pp' => 'pp',
                                                    '@'  => 'adv' }},
                       'adp'  => 'prp',
                       'conj' => { 'conjtype' => { 'sub' => 'conj-s',
                                                   '@'   => 'conj-c' }},
                       'part' => 'ec',
                       'int'  => 'in',
                       'punc' => 'punc',
                       'sym'  => 'punc',
                       '@'    => '?' }
        }
    );
    # GENDER ####################
    $atoms{gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            # gender = F|M/F|M|M/F
            'F'   => 'fem',
            'M'   => 'masc',
            'M/F' => ''
        }
    );
    # NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            # number = P|S|S/P
            'S'   => 'sing',
            'P'   => 'plur',
            'S/P' => ''
        }
    );
    # CASE ####################
    $atoms{case} = $self->create_atom
    (
        'surfeature' => 'case',
        'decode_map' =>
        {
            # case = ACC|ACC/DAT|DAT|NOM|NOM/PIV|PIV
            'NOM'     => ['case' => 'nom'],
            'NOM/PIV' => ['case' => 'nom|acc', 'prepcase' => 'pre'],
            'DAT'     => ['case' => 'dat'],
            'ACC/DAT' => ['case' => 'acc|dat'],
            'ACC'     => ['case' => 'acc'],
            # Note: PIV also occurs as the syntactic tag of prepositions heading prepositional objects.
            'PIV'     => ['case' => 'acc', 'prepcase' => 'pre']
        },
        'encode_map' =>
        {
            'case' => { 'acc|nom' => 'NOM/PIV',
                        'acc|dat' => 'ACC/DAT',
                        'nom'     => 'NOM',
                        'dat'     => 'DAT',
                        'acc'     => { 'prepcase' => { 'pre' => 'PIV',
                                                       '@'   => 'ACC' }}}
        }
    );
    # PERSON AND NUMBER ####################
    $atoms{person} = $self->create_atom
    (
        'surfeature' => 'person',
        'decode_map' =>
        {
            # person+number = 1/3S|1S|1P|2S|2P|3S|3S/P|3P
            '1/3S'  => ['person' => '1|3', 'number' => 'sing'],
            '1S'    => ['person' => '1', 'number' => 'sing'],
            '1P'    => ['person' => '1', 'number' => 'plur'],
            '2S'    => ['person' => '2', 'number' => 'sing'],
            '2P'    => ['person' => '2', 'number' => 'plur'],
            '3S'    => ['person' => '3', 'number' => 'sing'],
            '3S/P'  => ['person' => '3'],
            '3P'    => ['person' => '3', 'number' => 'plur'],
        },
        'encode_map' =>
        {
            'number' => { 'sing' => { 'person' => { '1|3' => '1/3S',
                                                    '1'   => '1S',
                                                    '2'   => '2S',
                                                    '3'   => '3S',
                                                    '@'   => '3S' }},
                          'plur' => { 'person' => { '1'   => '1P',
                                                    '2'   => '2P',
                                                    '@'   => '3P' }},
                          '@'    => { 'person' => { '3'   => '3S/P' }}}
        }
    );
    # POSSESSOR'S PERSON AND NUMBER ####################
    # Possessive pronouns (determiners) have double feautres like "<poss|1S>".
    # We remove the vertical bar during preprocessing so that we can process it as one feature.
    $atoms{possessor} = $self->create_atom
    (
        'surfeature' => 'possessor',
        'decode_map' =>
        {
            # meu, meus, minha, minhas
            '<poss1S>'   => ['prontype' => 'prs', 'poss' => 'yes', 'person' => '1', 'possnumber' => 'sing'],
            # teu, teus, tua, tuas
            '<poss2S>'   => ['prontype' => 'prs', 'poss' => 'yes', 'person' => '2', 'possnumber' => 'sing'],
            # seu, seus, sua, suas
            '<poss3S>'   => ['prontype' => 'prs', 'poss' => 'yes', 'person' => '3', 'possnumber' => 'sing'],
            '<poss3S/P>' => ['prontype' => 'prs', 'poss' => 'yes', 'person' => '3'],
            # nosso, nossos, nossa, nossas
            '<poss1P>'   => ['prontype' => 'prs', 'poss' => 'yes', 'person' => '1', 'possnumber' => 'plur'],
            # vosso, vossos, vossa, vossas
            '<poss2P>'   => ['prontype' => 'prs', 'poss' => 'yes', 'person' => '2', 'possnumber' => 'plur'],
            # seu, seus, sua, suas
            '<poss3P>'   => ['prontype' => 'prs', 'poss' => 'yes', 'person' => '3', 'possnumber' => 'plur'],
        },
        'encode_map' =>
        {
            'possnumber' => { 'sing' => { 'person' => { '1'   => '<poss1S>',
                                                        '2'   => '<poss2S>',
                                                        '@'   => '<poss3S>' }},
                              'plur' => { 'person' => { '1'   => '<poss1P>',
                                                        '2'   => '<poss2P>',
                                                        '@'   => '<poss3P>' }},
                              '@'    => { 'poss' => { 'yes' => '<poss3S/P>' }}}
        }
    );
    # MOOD ####################
    $atoms{mood} = $self->create_atom
    (
        'surfeature' => 'mood',
        'decode_map' =>
        {
            # mood = IND|SUBJ
            'IND'    => ['mood' => 'ind'],
            'SUBJ'   => ['mood' => 'sub']
        },
        'encode_map' =>
        {
            'mood' => { 'ind' => 'IND',
                        'sub' => 'SUBJ' }
        }
    );
    # TENSE ####################
    $atoms{tense} = $self->create_atom
    (
        'surfeature' => 'tense',
        'decode_map' =>
        {
            # sê, move, olha, chega
            'IMP'    => ['mood' => 'imp'],
            # é, está, tem, há, vai
            'PR'     => ['tense' => 'pres'],
            # decidimos, conhecemos, conseguimos
            'PR/PS'  => ['tense' => 'pres|past'],
            # foi, disse, fez, afirmou, teve
            'PS'     => ['tense' => 'past'],
            # era, tinha, estava, havia, ia
            'IMPF'   => ['tense' => 'imp'],
            # foram, chegaram, fizeram, tiveram, ficaram
            'PS/MQP' => ['tense' => 'imp|pqp'],
            # fora, fizera, desaparecera, acabara, levara
            'MQP'    => ['tense' => 'pqp'],
            # será, terá, deverá, poderá, irá
            'FUT'    => ['tense' => 'fut'],
            # seria, poderia, teria, deveria, iria
            'COND'   => ['mood' => 'cnd']
        },
        'encode_map' =>
        {
            'tense' => { 'pres'      => 'PR',
                         'past|pres' => 'PR/PS',
                         'past'      => 'PS',
                         'imp'       => 'IMPF',
                         'imp|pqp'   => 'PS/MQP',
                         'pqp'       => 'MQP',
                         'fut'       => 'FUT',
                         '@'         => { 'mood' => { 'imp' => 'IMP',
                                                      'cnd' => 'COND' }}}
        }
    );
    # Features in angle brackets are secondary tags, word subclasses etc.
    # DEGREE OF COMPARISON ####################
    # Occurs at adjectives and determiners (quantifiers).
    # Both <KOMP> and <SUP> may occur at one token!
    # <KOMP>|<SUP> ... melhor, superior, pior, inferior
    # <KOMP> ... maior, melhor, menor, superior, pior
    # <SUP> ... principal, ótimo, máximo, mínimo, péssimo
    $atoms{degree} = $self->create_atom
    (
        'surfeature' => 'degree',
        'decode_map' =>
        {
            # Comparative degree.
            '<KOMP>' => ['degree' => 'cmp'],
            # Superlative degree.
            '<SUP>'  => ['degree' => 'sup']
        },
        'encode_map' =>
        {
            'degree' => { 'cmp' => '<KOMP>',
                          'sup' => '<SUP>' }
        }
    );
    # PRONOUN TYPE ####################
    $atoms{prontype} = $self->create_atom
    (
        'surfeature' => 'prontype',
        'decode_map' =>
        {
            # Collective reflexive pronoun ("se" in "reunir-se", "associar-se").
            # This feature is relatively rare. It should always co-occur with the <reflex> feature
            # but sometimes it does not so we make sure to set reflex here as well.
            '<coll>'   => ['reflex' => 'yes', 'other' => {'coll' => '1'}],
            # Demonstrative pronoun or adverb.
            # adv <dem>|<quant>: tão
            # For adverbs, <dem> almost always comes together with <quant>. There was one occurrence of <dem> without <quant> (an error?)
            # and it also came with the word "tão".
            '<dem>'    => ['prontype' => 'dem'],
            # Interrogative pronoun or adverb.
            # adv <interr>: como, onde, porque, quando, para_onde
            '<interr>'   => ['prontype' => 'int'],
            '<intquant>' => ['prontype' => 'int', 'numtype' => 'card'],
            # Relative pronoun or adverb.
            # adv <rel>: como, onde, quando, enquanto, tal_como
            # adv <rel>|<quant>: quanto, quanto_mais
            # pron-det <rel>: cujo, qual, quanto, o_que
            # pron-indp <rel>: que, o_que, quem, o_qual
            # pron-indp <rel>|<quant>: tudo_o_que
            # We preprocess <rel>|<quant> into <relquant>.
            '<rel>'      => ['prontype' => 'rel'],
            '<relquant>' => ['prontype' => 'rel', 'numtype' => 'card'],
            # (Indefinite) quantifier pronoun or adverb.
            # independent pronouns: algo, tudo, nada
            # independent relative pronouns: todo_o_que
            # determiners (pronouns): algum, alguma, alguns, algumas, uns, umas, vários, várias,
            #    qualquer, pouco, poucos, muitos, mais,
            #    todo, todo_o, todos, todas, ambos, ambas
            # adverbs: pouco, menos, muito, mais, mais_de, quase, tanto, mesmo, demais, bastante, suficiente, bem
            # demonstrative adverbs: t~ao
            # This is not the class of indefinite pronouns. This class contains pronouns and adverbs of quantity.
            # The pronouns and adverbs in this class can be indefinite (algo), total (todo), negative (nada), demonstrative (tanto, tao),
            # interrogative (quanto), relative (todo_o_que). Many are indefinite, but not all.
            # adv <quant> (no other features): muito, bem, mais, quase, mais_de
            # adv <quant>|<KOMP>: mais, menos, tão, tanto, nada_mais_nada_menos
            # adv <dem>|<quant>: tão
            '<quant>' => ['prontype' => 'ind|neg|tot', 'numtype' => 'card'],
            # Reciprocal reflexive (amar-se).
            '<reci>'  => ['prontype' => 'rcp'],
            # Reflexive pronoun.
            '<refl>'  => ['prontype' => 'prs', 'reflex' => 'yes'],
            # Reflexive usage of 3rd person possessive (seu, seus, sua, suas).
            '<si>'    => ['prontype' => 'prs', 'poss' => 'yes', 'person' => '3', 'reflex' => 'yes'],
            # Differentiator (mesmo, outro, semelhante, tal).
            '<diff>'  => ['other' => {'prontype' => 'diff'}],
            # Identifier pronoun (mesmo, próprio).
            '<ident>' => ['other' => {'prontype' => 'ident'}]
        },
        'encode_map' =>
        {
            'other/coll' => { '1' => '<refl>|<coll>',
                              '@' => { 'other/prontype' => { 'diff'  => '<diff>',
                                                             'ident' => '<ident>',
                                                             '@'     => { 'prontype' => { 'dem' => '<dem>',
                                                                                          'int' => { 'numtype' => { 'card' => '<intquant>',
                                                                                                                    '@'    => '<interr>' }},
                                                                                          'rel' => { 'numtype' => { 'card' => '<relquant>',
                                                                                                                    '@'    => '<rel>' }},
                                                                                          'rcp' => '<reci>',
                                                                                          'ind' => { 'numtype' => { 'card' => '<quant>' }},
                                                                                          'neg' => { 'numtype' => { 'card' => '<quant>' }},
                                                                                          'tot' => { 'numtype' => { 'card' => '<quant>' }},
                                                                                          'prs' => { 'reflex' => { 'yes' => { 'poss' => { 'yes' => '<si>',
                                                                                                                                             '@'    => '<refl>' }}}}}}}}}
        }
    );
    # DEFINITENESS ####################
    $atoms{definite} = $self->create_simple_atom
    (
        'intfeature' => 'definite',
        'simple_decode_map' =>
        {
            # Definite article: o, os, a, as
            # Occurs with pron-det as well, so do not set prontype = art, or we cannot distinguish the original pos = art.
            '<artd>' => 'def',
            # Indefinite article: um, uma
            # Occurs with pron-det as well, so do not set prontype = art, or we cannot distinguish the original pos = art.
            '<arti>' => 'ind'
        }
    );
    # NUMERAL TYPE ####################
    $atoms{numtype} = $self->create_atom
    (
        'surfeature' => 'numtype',
        'decode_map' =>
        {
            # Ordinal number (subclass of adjectives).
            '<NUM-ord>' => ['numtype' => 'ord'],
            # Cardinal number.
            # This can co-occur with subpos=prop (proper noun).
            # If it is the case, we may want to keep "prop" and discard "card".
            '<card>' => ['numtype' => 'card'],
        },
        'encode_map' =>
        {
            'numtype' => { 'card' => '<card>',
                           'ord'  => '<NUM-ord>' }
        }
    );
    # TYPO, ALTERNATIVE SPELLING ####################
    $atoms{alt} = $self->create_simple_atom
    (
        'intfeature' => 'typo',
        'simple_decode_map' =>
        {
            '<ALT>' => 'yes'
        }
    );
    # CONTRACTIONS ####################
    # There are many contracted words in Portuguese. Most of them involve a preposition
    # and an article: "em" + "o" = "no"
    # http://en.wikibooks.org/wiki/Portuguese/Contents/Common_Prepositions_and_Contractions
    # Contracted words have been split during tokenization and the original tokens act as tree nodes.
    # The <sam-> and <-sam> features indicate that there was a contraction.
    # The contracted form is not indicated (but it is probably deterministic to derive it from the parts).
    $atoms{sam} = $self->create_atom
    (
        'surfeature' => 'sam',
        'decode_map' =>
        {
            # First part in contracted word.
            '<sam->'  => ['other' => {'sam' => 'first'}],
            # Second part in contracted word.
            '<-sam>'  => ['other' => {'sam' => 'second'}]
        },
        'encode_map' =>
        {
            'other/sam' => { 'first'  => '<sam->',
                             'second' => '<-sam>' }
        }
    );
    # KIND OF NODES COORDINATED BY CONJUNCTION ####################
    $atoms{co} = $self->create_atom
    (
        'surfeature' => 'co',
        'decode_map' =>
        {
            # Kind of nodes coordinated by this conjunction.
            '<co-acc>'     => ['other' => {'co' => 'acc'}],
            '<co-advl>'    => ['other' => {'co' => 'advl'}],
            '<co-advo>'    => ['other' => {'co' => 'advo'}],
            '<co-advs>'    => ['other' => {'co' => 'advs'}],
            '<co-app>'     => ['other' => {'co' => 'app'}],
            '<co-fmc>'     => ['other' => {'co' => 'fmc'}],
            '<co-ger>'     => ['other' => {'co' => 'ger'}],
            '<co-inf>'     => ['other' => {'co' => 'inf'}],
            '<co-oc>'      => ['other' => {'co' => 'oc'}],
            '<co-pass>'    => ['other' => {'co' => 'pass'}],
            '<co-pcv>'     => ['other' => {'co' => 'pcv'}],
            '<co-piv>'     => ['other' => {'co' => 'piv'}],
            '<co-postad>'  => ['other' => {'co' => 'postad'}],
            '<co-postnom>' => ['other' => {'co' => 'postnom'}],
            '<co-pred>'    => ['other' => {'co' => 'pred'}],
            '<co-prenom>'  => ['other' => {'co' => 'prenom'}],
            '<co-prparg>'  => ['other' => {'co' => 'prparg'}],
            '<co-sc>'      => ['other' => {'co' => 'sc'}],
            '<co-subj>'    => ['other' => {'co' => 'subj'}],
            '<co-vfin>'    => ['other' => {'co' => 'vfin'}]
        },
        'encode_map' =>
        {
            'other/co' => { 'acc'     => '<co-acc>',
                            'advl'    => '<co-advl>',
                            'advo'    => '<co-advo>',
                            'advs'    => '<co-advs>',
                            'app'     => '<co-app>',
                            'fmc'     => '<co-fmc>',
                            'ger'     => '<co-ger>',
                            'inf'     => '<co-inf>',
                            'oc'      => '<co-oc>',
                            'pass'    => '<co-pass>',
                            'pcv'     => '<co-pcv>',
                            'piv'     => '<co-piv>',
                            'postad'  => '<co-postad>',
                            'postnom' => '<co-postnom>',
                            'pred'    => '<co-pred>',
                            'prenom'  => '<co-prenom>',
                            'prparg'  => '<co-prparg>',
                            'sc'      => '<co-sc>',
                            'subj'    => '<co-subj>',
                            'vfin'    => '<co-vfin>' }
        }
    );
    # WORDS USED AS WORD CLASSES OTHER THAN THOSE THEY BELONG TO ####################
    $atoms{transcat} = $self->create_atom
    (
        'surfeature' => 'transcat',
        'decode_map' =>
        {
            '<det>'   => ['other' => {'transcat' => 'det'}],
            '<kc>'    => ['other' => {'transcat' => 'kc'}],
            '<ks>'    => ['other' => {'transcat' => 'ks'}],
            '<n>'     => ['other' => {'transcat' => 'n'}],
            # n <prop>: Estado, Presidente, Congresso, Janeiro, Maio
            '<prop>'  => ['other' => {'transcat' => 'prop'}],
            '<prp>'   => ['other' => {'transcat' => 'prp'}]
        },
        'encode_map' =>
        {
            'other/transcat' => { 'det'  => '<det>',
                                  'kc'   => '<kc>',
                                  'ks'   => '<ks>',
                                  'n'    => '<n>',
                                  'prop' => '<prop>',
                                  'prp'  => '<prp>' }
        }
    );
    # OTHER FEATURES IN ANGLE BRACKETS ####################
    $atoms{anglefeature} = $self->create_atom
    (
        'surfeature' => 'anglefeature',
        'decode_map' =>
        {
            # Derivation by prefixation.
            '<DERP>' => ['other' => {'derp' => '1'}],
            # Derivation by suffixation.
            '<DERS>' => ['other' => {'ders' => '1'}],
            # Annotation or processing error.
            '<error>' => ['other' => {'error' => '1'}],
            # Verb heading finite main clause.
            '<fmc>'   => ['other' => {'fmc' => '1'}],
            # Focus marker, adverb or pronoun.
            # adv <foc>: que, é_que, foi, é, era
            '<foc>'   => ['other' => {'foc' => '1'}],
            # Hyphenated prefix, usually of reflexive verbs.
            '<hyfen>' => ['hyph' => 'yes'],
        },
        'encode_map' =>
        {
            'hyph' => { 'yes' => '<hyfen>',
                        '@'    => { 'other/derp' => { '1' => '<DERP>',
                                                      '@' => { 'other/ders' => { '1' => '<DERS>',
                                                                                 '@' => { 'other/foc' => { '1' => '<foc>' }}}}}}}
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
    my @features = ('pos', 'gender', 'number', 'case', 'person', 'tense', 'mood',
                    'degree', 'alt', 'possessor', 'prontype', 'definite', 'numtype', 'anglefeature', 'sam', 'co', 'transcat');
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
        'adj'       => ['anglefeature', 'transcat', 'numtype', 'alt', 'degree', 'gender', 'number'],
        'adv'       => ['prontype', 'transcat', 'anglefeature', 'sam', 'co', 'alt', 'degree'],
        'art'       => ['sam', 'alt', 'definite', 'gender', 'number'],
        'conj-c'    => ['co'],
        'conj-s'    => ['transcat'],
        'n'         => ['anglefeature', 'transcat', 'alt', 'gender', 'number'],
        'num'       => ['transcat', 'sam', 'alt', 'numtype', 'gender', 'number'],
        'pp'        => ['sam'],
        'pron-det'  => ['transcat', 'sam', 'possessor', 'prontype', 'definite', 'degree', 'gender', 'number'],
        'pron-indp' => ['sam', 'alt', 'prontype', 'gender', 'number'],
        'pron-pers' => ['anglefeature', 'sam', 'prontype', 'gender', 'person', 'case'],
        'prop'      => ['anglefeature', 'alt', 'gender', 'number'],
        'prp'       => ['sam', 'transcat', 'co', 'alt'],
        'v-fin'     => ['anglefeature', 'transcat', 'alt', 'tense', 'person', 'mood'],
        'v-ger'     => ['anglefeature', 'alt'],
        'v-inf'     => ['anglefeature', 'transcat', 'alt', 'person'],
        'v-pcp'     => ['anglefeature', 'transcat', 'alt', 'gender', 'number']
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
    # Preprocess the tag. Processing of some features depends on processing of some other features.
    # For adverbs, <dem> almost always comes together with <quant>.
    # There was one occurrence of <dem> without <quant> (an error?) and it also came with the word "tão".
    $tag =~ s/(adv\s+<dem>)\|<quant>/$1/;
    $tag =~ s/<rel>\|<quant>/<relquant>/;
    $tag =~ s/<interr>\|<quant>/<intquant>/;
    $tag =~ s/<poss\|([123](S|P|S\/P))>/<poss$1>/;
    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset('pt::conll');
    my $atoms = $self->atoms();
    # Three components, and the first two are identical: pos, pos, features.
    # example: N\tN\tsoort|ev|neut
    my ($pos, $subpos, $features) = split(/\s+/, $tag);
    # The underscore character is used if there are no features.
    $features = '' if($features eq '_');
    my @features = split(/\|/, $features);
    $atoms->{pos}->decode_and_merge_hard($subpos, $fs);
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
    my $subpos = $atoms->{pos}->encode($fs);
    my $pos = $subpos;
    $pos =~ s/-.*//;
    my $fpos = $subpos;
    my $feature_names = $self->get_feature_names($fpos);
    my $value_only = 1;
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names, $value_only);
    # Postprocess the tag. Processing of some features depends on processing of some other features.
    # For adverbs, <dem> almost always comes together with <quant>.
    # There was one occurrence of <dem> without <quant> (an error?) and it also came with the word "tão".
    $tag =~ s/<poss([123](S|P|S\/P))>/<poss|$1>/;
    $tag =~ s/<intquant>/<interr>|<quant>/;
    $tag =~ s/<relquant>/<rel>|<quant>/;
    $tag =~ s/(adv\s+<dem>)/$1|<quant>/;
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus, 671 distinct tags found.
# Cleaned up suspicious combinations of features that were hard to replicate.
# 564 tags survived.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
?	?	_
adj	adj	<ALT>|<SUP>|M|S
adj	adj	<ALT>|F|P
adj	adj	<ALT>|F|S
adj	adj	<ALT>|M|S
adj	adj	<DERP>|<n>|M|P
adj	adj	<DERP>|F|P
adj	adj	<DERP>|F|S
adj	adj	<DERP>|M|P
adj	adj	<DERP>|M|S
adj	adj	<DERS>|<n>|M|P
adj	adj	<DERS>|F|P
adj	adj	<DERS>|F|S
adj	adj	<DERS>|M|P
adj	adj	<DERS>|M|S
adj	adj	<KOMP>|F|P
adj	adj	<KOMP>|F|S
adj	adj	<KOMP>|M/F|S
adj	adj	<KOMP>|M|P
adj	adj	<KOMP>|M|S
adj	adj	<NUM-ord>|F|P
adj	adj	<NUM-ord>|F|S
adj	adj	<NUM-ord>|M/F|S
adj	adj	<NUM-ord>|M|P
adj	adj	<NUM-ord>|M|S
adj	adj	<SUP>|F|P
adj	adj	<SUP>|F|S
adj	adj	<SUP>|M|P
adj	adj	<SUP>|M|S
adj	adj	<hyfen>|F|P
adj	adj	<n>|<KOMP>|F|P
adj	adj	<n>|<KOMP>|F|S
adj	adj	<n>|<KOMP>|M|P
adj	adj	<n>|<KOMP>|M|S
adj	adj	<n>|<NUM-ord>|F|P
adj	adj	<n>|<NUM-ord>|F|S
adj	adj	<n>|<NUM-ord>|M|P
adj	adj	<n>|<NUM-ord>|M|S
adj	adj	<n>|<SUP>|F|P
adj	adj	<n>|<SUP>|F|S
adj	adj	<n>|<SUP>|M|P
adj	adj	<n>|<SUP>|M|S
adj	adj	<n>|F|P
adj	adj	<n>|F|S
adj	adj	<n>|M/F|P
adj	adj	<n>|M/F|S
adj	adj	<n>|M|P
adj	adj	<n>|M|S
adj	adj	<prop>|<NUM-ord>|M|S
adj	adj	<prop>|F|P
adj	adj	<prop>|F|S
adj	adj	<prop>|M/F|S
adj	adj	<prop>|M|P
adj	adj	<prop>|M|S
adj	adj	F|P
adj	adj	F|S
adj	adj	M/F|P
adj	adj	M/F|S
adj	adj	M/F|S/P
adj	adj	M|P
adj	adj	M|S
adv	adv	<-sam>
adv	adv	<ALT>
adv	adv	<DERS>
adv	adv	<KOMP>
adv	adv	<SUP>
adv	adv	<co-acc>
adv	adv	<co-advl>
adv	adv	<co-prparg>
adv	adv	<co-sc>
adv	adv	<dem>|<quant>
adv	adv	<dem>|<quant>|<KOMP>
adv	adv	<foc>
adv	adv	<interr>
adv	adv	<interr>|<ks>
adv	adv	<kc>
adv	adv	<kc>|<-sam>
adv	adv	<kc>|<KOMP>
adv	adv	<kc>|<co-acc>
adv	adv	<kc>|<co-advl>
adv	adv	<kc>|<co-pass>
adv	adv	<kc>|<co-piv>
adv	adv	<kc>|<foc>
adv	adv	<ks>
adv	adv	<n>|<KOMP>
adv	adv	<prp>
adv	adv	<quant>
adv	adv	<quant>|<KOMP>
adv	adv	<quant>|<det>
adv	adv	<rel>
adv	adv	<rel>|<ks>
adv	adv	<rel>|<prp>
adv	adv	<rel>|<prp>|<co-advl>
adv	adv	<rel>|<quant>
adv	adv	<sam->
adv	adv	_
art	art	<-sam>|<artd>|F|P
art	art	<-sam>|<artd>|F|S
art	art	<-sam>|<artd>|M|P
art	art	<-sam>|<artd>|M|S
art	art	<-sam>|<arti>|F|S
art	art	<-sam>|<arti>|M|S
art	art	<-sam>|F|P
art	art	<-sam>|F|S
art	art	<-sam>|M|S
art	art	<ALT>|<artd>|F|S
art	art	<ALT>|F|S
art	art	<artd>|F|P
art	art	<artd>|F|S
art	art	<artd>|M|P
art	art	<artd>|M|S
art	art	<arti>|F|S
art	art	<arti>|M|S
art	art	F|P
art	art	F|S
art	art	M|P
art	art	M|S
conj	conj-c	<co-acc>
conj	conj-c	<co-advl>
conj	conj-c	<co-advo>
conj	conj-c	<co-advs>
conj	conj-c	<co-app>
conj	conj-c	<co-fmc>
conj	conj-c	<co-ger>
conj	conj-c	<co-inf>
conj	conj-c	<co-oc>
conj	conj-c	<co-pass>
conj	conj-c	<co-pcv>
conj	conj-c	<co-piv>
conj	conj-c	<co-postad>
conj	conj-c	<co-postnom>
conj	conj-c	<co-pred>
conj	conj-c	<co-prenom>
conj	conj-c	<co-prparg>
conj	conj-c	<co-sc>
conj	conj-c	<co-subj>
conj	conj-c	<co-vfin>
conj	conj-c	_
conj	conj-s	<prp>
conj	conj-s	_
ec	ec	_
in	in	_
n	n	<ALT>|F|S
n	n	<ALT>|M|P
n	n	<ALT>|M|S
n	n	<DERP>|F|P
n	n	<DERP>|F|S
n	n	<DERP>|M|P
n	n	<DERP>|M|S
n	n	<DERS>|F|P
n	n	<DERS>|F|S
n	n	<DERS>|M|P
n	n	<DERS>|M|S
n	n	<hyfen>|F|S
n	n	<hyfen>|M|P
n	n	<hyfen>|M|S
n	n	<prop>|F|P
n	n	<prop>|F|S
n	n	<prop>|M/F|S
n	n	<prop>|M|P
n	n	<prop>|M|S
n	n	F|P
n	n	F|S
n	n	F|S/P
n	n	M/F|P
n	n	M/F|S
n	n	M|P
n	n	M|S
n	n	M|S/P
num	num	<-sam>|<card>|M|S
num	num	<-sam>|M|S
num	num	<ALT>|<card>|M|P
num	num	<card>|F|P
num	num	<card>|F|S
num	num	<card>|M/F|P
num	num	<card>|M/F|S
num	num	<card>|M|P
num	num	<card>|M|S
num	num	<card>|M|S/P
num	num	<n>|<card>|M|P
num	num	<n>|<card>|M|S
num	num	<n>|M|P
num	num	<prop>|<card>|F|P
num	num	<prop>|<card>|M|P
num	num	F|P
num	num	M/F|P
num	num	M|P
num	num	M|S
pp	pp	<sam->
pp	pp	_
pron	pron-det	<-sam>|<dem>|F|P
pron	pron-det	<-sam>|<dem>|F|S
pron	pron-det	<-sam>|<dem>|M|P
pron	pron-det	<-sam>|<dem>|M|S
pron	pron-det	<-sam>|<diff>|F|P
pron	pron-det	<-sam>|<diff>|F|S
pron	pron-det	<-sam>|<diff>|M|P
pron	pron-det	<-sam>|<diff>|M|S
pron	pron-det	<-sam>|<quant>|F|P
pron	pron-det	<-sam>|<quant>|M|P
pron	pron-det	<dem>|<KOMP>|F|P
pron	pron-det	<dem>|<KOMP>|M|P
pron	pron-det	<dem>|F|P
pron	pron-det	<dem>|F|S
pron	pron-det	<dem>|M|P
pron	pron-det	<dem>|M|S
pron	pron-det	<diff>|F|P
pron	pron-det	<diff>|F|S
pron	pron-det	<diff>|M/F|S
pron	pron-det	<diff>|M|P
pron	pron-det	<diff>|M|S
pron	pron-det	<ident>|F|P
pron	pron-det	<ident>|F|S
pron	pron-det	<ident>|M|P
pron	pron-det	<ident>|M|S
pron	pron-det	<interr>|<quant>|F|P
pron	pron-det	<interr>|<quant>|M|P
pron	pron-det	<interr>|<quant>|M|S
pron	pron-det	<interr>|F|P
pron	pron-det	<interr>|F|S
pron	pron-det	<interr>|M/F|S
pron	pron-det	<interr>|M/F|S/P
pron	pron-det	<interr>|M|P
pron	pron-det	<interr>|M|S
pron	pron-det	<n>|<dem>|M|S
pron	pron-det	<poss|1P>|F|P
pron	pron-det	<poss|1P>|F|S
pron	pron-det	<poss|1P>|M|P
pron	pron-det	<poss|1P>|M|S
pron	pron-det	<poss|1S>|F|P
pron	pron-det	<poss|1S>|F|S
pron	pron-det	<poss|1S>|M|P
pron	pron-det	<poss|1S>|M|S
pron	pron-det	<poss|2P>|F|S
pron	pron-det	<poss|2P>|M|S
pron	pron-det	<poss|2S>|M|S
pron	pron-det	<poss|3P>|<si>|F|P
pron	pron-det	<poss|3P>|<si>|F|S
pron	pron-det	<poss|3P>|<si>|M|P
pron	pron-det	<poss|3P>|<si>|M|S
pron	pron-det	<poss|3P>|F|S
pron	pron-det	<poss|3P>|M|P
pron	pron-det	<poss|3P>|M|S
pron	pron-det	<poss|3S/P>|<si>|F|S
pron	pron-det	<poss|3S/P>|<si>|M|S
pron	pron-det	<poss|3S/P>|F|S
pron	pron-det	<poss|3S/P>|M|P
pron	pron-det	<poss|3S>|<si>|F|P
pron	pron-det	<poss|3S>|<si>|F|S
pron	pron-det	<poss|3S>|<si>|M|P
pron	pron-det	<poss|3S>|<si>|M|S
pron	pron-det	<poss|3S>|F|P
pron	pron-det	<poss|3S>|F|S
pron	pron-det	<poss|3S>|M|P
pron	pron-det	<poss|3S>|M|S
pron	pron-det	<quant>|<KOMP>|F|P
pron	pron-det	<quant>|<KOMP>|F|S
pron	pron-det	<quant>|<KOMP>|M/F|S/P
pron	pron-det	<quant>|<KOMP>|M|P
pron	pron-det	<quant>|<KOMP>|M|S
pron	pron-det	<quant>|<SUP>|M|S
pron	pron-det	<quant>|F|P
pron	pron-det	<quant>|F|S
pron	pron-det	<quant>|M/F|P
pron	pron-det	<quant>|M/F|S
pron	pron-det	<quant>|M/F|S/P
pron	pron-det	<quant>|M|P
pron	pron-det	<quant>|M|S
pron	pron-det	<rel>|F|P
pron	pron-det	<rel>|F|S
pron	pron-det	<rel>|M|P
pron	pron-det	<rel>|M|S
pron	pron-det	F|P
pron	pron-det	F|S
pron	pron-det	M/F|S
pron	pron-det	M|P
pron	pron-det	M|S
pron	pron-det	M|S/P
pron	pron-indp	<-sam>|<dem>|M|S
pron	pron-indp	<-sam>|<rel>|F|P
pron	pron-indp	<-sam>|<rel>|F|S
pron	pron-indp	<-sam>|<rel>|M|P
pron	pron-indp	<-sam>|<rel>|M|S
pron	pron-indp	<ALT>|<rel>|F|S
pron	pron-indp	<dem>|M/F|S/P
pron	pron-indp	<dem>|M|S
pron	pron-indp	<diff>|M|S
pron	pron-indp	<interr>|F|P
pron	pron-indp	<interr>|F|S
pron	pron-indp	<interr>|M/F|P
pron	pron-indp	<interr>|M/F|S
pron	pron-indp	<interr>|M/F|S/P
pron	pron-indp	<interr>|M|P
pron	pron-indp	<interr>|M|S
pron	pron-indp	<quant>|M/F|S
pron	pron-indp	<quant>|M|S
pron	pron-indp	<rel>|F|P
pron	pron-indp	<rel>|F|S
pron	pron-indp	<rel>|M/F|P
pron	pron-indp	<rel>|M/F|S
pron	pron-indp	<rel>|M/F|S/P
pron	pron-indp	<rel>|M|P
pron	pron-indp	<rel>|M|S
pron	pron-indp	F|S
pron	pron-indp	M/F|S
pron	pron-indp	M/F|S/P
pron	pron-indp	M|P
pron	pron-indp	M|S
pron	pron-indp	M|S/P
pron	pron-pers	<-sam>|<refl>|F|3S|PIV
pron	pron-pers	<-sam>|<refl>|M|3S|PIV
pron	pron-pers	<-sam>|F|1P|PIV
pron	pron-pers	<-sam>|F|1S|PIV
pron	pron-pers	<-sam>|F|3P|NOM
pron	pron-pers	<-sam>|F|3P|NOM/PIV
pron	pron-pers	<-sam>|F|3P|PIV
pron	pron-pers	<-sam>|F|3S|ACC
pron	pron-pers	<-sam>|F|3S|NOM/PIV
pron	pron-pers	<-sam>|F|3S|PIV
pron	pron-pers	<-sam>|M/F|2P|PIV
pron	pron-pers	<-sam>|M|3P|NOM
pron	pron-pers	<-sam>|M|3P|NOM/PIV
pron	pron-pers	<-sam>|M|3P|PIV
pron	pron-pers	<-sam>|M|3S|ACC
pron	pron-pers	<-sam>|M|3S|NOM
pron	pron-pers	<-sam>|M|3S|NOM/PIV
pron	pron-pers	<-sam>|M|3S|PIV
pron	pron-pers	<hyfen>|<refl>|F|3S|ACC
pron	pron-pers	<hyfen>|<refl>|M/F|1S|DAT
pron	pron-pers	<hyfen>|F|3S|ACC
pron	pron-pers	<hyfen>|M/F|3S/P|ACC
pron	pron-pers	<hyfen>|M|3S|ACC
pron	pron-pers	<hyfen>|M|3S|DAT
pron	pron-pers	<reci>|F|3P|ACC
pron	pron-pers	<reci>|M|3P|ACC
pron	pron-pers	<refl>|<coll>|F|3P|ACC
pron	pron-pers	<refl>|<coll>|M/F|3P|ACC
pron	pron-pers	<refl>|<coll>|M|3P|ACC
pron	pron-pers	<refl>|<coll>|M|3S|ACC
pron	pron-pers	<refl>|F|1S|ACC
pron	pron-pers	<refl>|F|1S|DAT
pron	pron-pers	<refl>|F|3P|ACC
pron	pron-pers	<refl>|F|3S|ACC
pron	pron-pers	<refl>|F|3S|DAT
pron	pron-pers	<refl>|F|3S|PIV
pron	pron-pers	<refl>|M/F|1P|ACC
pron	pron-pers	<refl>|M/F|1P|ACC/DAT
pron	pron-pers	<refl>|M/F|1P|DAT
pron	pron-pers	<refl>|M/F|1S|ACC
pron	pron-pers	<refl>|M/F|1S|DAT
pron	pron-pers	<refl>|M/F|2P|DAT
pron	pron-pers	<refl>|M/F|3P|ACC
pron	pron-pers	<refl>|M/F|3S/P|ACC
pron	pron-pers	<refl>|M/F|3S/P|ACC/DAT
pron	pron-pers	<refl>|M/F|3S/P|DAT
pron	pron-pers	<refl>|M/F|3S/P|PIV
pron	pron-pers	<refl>|M/F|3S|ACC
pron	pron-pers	<refl>|M/F|3S|PIV
pron	pron-pers	<refl>|M|1P|ACC
pron	pron-pers	<refl>|M|1P|DAT
pron	pron-pers	<refl>|M|1S|ACC
pron	pron-pers	<refl>|M|1S|DAT
pron	pron-pers	<refl>|M|2S|ACC
pron	pron-pers	<refl>|M|3P|ACC
pron	pron-pers	<refl>|M|3P|DAT
pron	pron-pers	<refl>|M|3P|PIV
pron	pron-pers	<refl>|M|3S/P|ACC
pron	pron-pers	<refl>|M|3S|ACC
pron	pron-pers	<refl>|M|3S|DAT
pron	pron-pers	<refl>|M|3S|PIV
pron	pron-pers	<sam->|M/F|3S|DAT
pron	pron-pers	F|1P|NOM/PIV
pron	pron-pers	F|1P|PIV
pron	pron-pers	F|1S|ACC
pron	pron-pers	F|1S|NOM
pron	pron-pers	F|1S|PIV
pron	pron-pers	F|3P|ACC
pron	pron-pers	F|3P|DAT
pron	pron-pers	F|3P|NOM
pron	pron-pers	F|3P|NOM/PIV
pron	pron-pers	F|3P|PIV
pron	pron-pers	F|3S/P|ACC
pron	pron-pers	F|3S|ACC
pron	pron-pers	F|3S|DAT
pron	pron-pers	F|3S|NOM
pron	pron-pers	F|3S|NOM/PIV
pron	pron-pers	F|3S|PIV
pron	pron-pers	M/F|1P|ACC
pron	pron-pers	M/F|1P|DAT
pron	pron-pers	M/F|1P|NOM
pron	pron-pers	M/F|1P|NOM/PIV
pron	pron-pers	M/F|1P|PIV
pron	pron-pers	M/F|1S|ACC
pron	pron-pers	M/F|1S|DAT
pron	pron-pers	M/F|1S|NOM
pron	pron-pers	M/F|1S|PIV
pron	pron-pers	M/F|2P|ACC
pron	pron-pers	M/F|2P|NOM
pron	pron-pers	M/F|2P|PIV
pron	pron-pers	M/F|3P|ACC
pron	pron-pers	M/F|3P|DAT
pron	pron-pers	M/F|3P|NOM
pron	pron-pers	M/F|3S/P|ACC
pron	pron-pers	M/F|3S|ACC
pron	pron-pers	M/F|3S|DAT
pron	pron-pers	M/F|3S|NOM
pron	pron-pers	M/F|3S|NOM/PIV
pron	pron-pers	M|1P|ACC
pron	pron-pers	M|1P|DAT
pron	pron-pers	M|1P|NOM
pron	pron-pers	M|1P|NOM/PIV
pron	pron-pers	M|1S|ACC
pron	pron-pers	M|1S|DAT
pron	pron-pers	M|1S|NOM
pron	pron-pers	M|1S|PIV
pron	pron-pers	M|2S|ACC
pron	pron-pers	M|2S|PIV
pron	pron-pers	M|3P|ACC
pron	pron-pers	M|3P|DAT
pron	pron-pers	M|3P|NOM
pron	pron-pers	M|3P|NOM/PIV
pron	pron-pers	M|3P|PIV
pron	pron-pers	M|3S
pron	pron-pers	M|3S/P|ACC
pron	pron-pers	M|3S|ACC
pron	pron-pers	M|3S|DAT
pron	pron-pers	M|3S|NOM
pron	pron-pers	M|3S|NOM/PIV
pron	pron-pers	M|3S|PIV
prop	prop	<ALT>|F|S
prop	prop	<ALT>|M|S
prop	prop	<DERS>|M|S
prop	prop	<hyfen>|F|P
prop	prop	<hyfen>|F|S
prop	prop	<hyfen>|M|S
prop	prop	F|P
prop	prop	F|S
prop	prop	M/F|P
prop	prop	M/F|S
prop	prop	M/F|S/P
prop	prop	M|P
prop	prop	M|S
prp	prp	<ALT>
prp	prp	<kc>
prp	prp	<kc>|<co-acc>
prp	prp	<kc>|<co-prparg>
prp	prp	<ks>
prp	prp	<sam->
prp	prp	<sam->|<co-acc>
prp	prp	<sam->|<kc>
prp	prp	_
punc	punc	_
v	v-fin	<ALT>|IMPF|3S|IND
v	v-fin	<ALT>|IMPF|3S|SUBJ
v	v-fin	<ALT>|PR|3S|IND
v	v-fin	<ALT>|PS|3S|IND
v	v-fin	<ALT>|PS|3S|SUBJ
v	v-fin	<DERP>|PR|1S|IND
v	v-fin	<DERP>|PR|3P|IND
v	v-fin	<DERP>|PR|3S|IND
v	v-fin	<DERP>|PS|3S|IND
v	v-fin	<hyfen>|COND|1S
v	v-fin	<hyfen>|COND|3S
v	v-fin	<hyfen>|FUT|3S|IND
v	v-fin	<hyfen>|IMPF|1S|IND
v	v-fin	<hyfen>|IMPF|3P|IND
v	v-fin	<hyfen>|IMPF|3S|IND
v	v-fin	<hyfen>|MQP|1/3S|IND
v	v-fin	<hyfen>|MQP|3S|IND
v	v-fin	<hyfen>|PR|1/3S|SUBJ
v	v-fin	<hyfen>|PR|1P|IND
v	v-fin	<hyfen>|PR|1S|IND
v	v-fin	<hyfen>|PR|3P|IND
v	v-fin	<hyfen>|PR|3P|SUBJ
v	v-fin	<hyfen>|PR|3S|IND
v	v-fin	<hyfen>|PR|3S|SUBJ
v	v-fin	<hyfen>|PS/MQP|3P|IND
v	v-fin	<hyfen>|PS|1S|IND
v	v-fin	<hyfen>|PS|2S|IND
v	v-fin	<hyfen>|PS|3P|IND
v	v-fin	<hyfen>|PS|3S|IND
v	v-fin	<n>|PR|3S|IND
v	v-fin	COND|1/3S
v	v-fin	COND|1P
v	v-fin	COND|1S
v	v-fin	COND|3P
v	v-fin	COND|3S
v	v-fin	FUT|1/3S|SUBJ
v	v-fin	FUT|1P|IND
v	v-fin	FUT|1P|SUBJ
v	v-fin	FUT|1S|IND
v	v-fin	FUT|1S|SUBJ
v	v-fin	FUT|2S|IND
v	v-fin	FUT|3P|IND
v	v-fin	FUT|3P|SUBJ
v	v-fin	FUT|3S|IND
v	v-fin	FUT|3S|SUBJ
v	v-fin	IMPF|1/3S|IND
v	v-fin	IMPF|1/3S|SUBJ
v	v-fin	IMPF|1P|IND
v	v-fin	IMPF|1P|SUBJ
v	v-fin	IMPF|1S|IND
v	v-fin	IMPF|1S|SUBJ
v	v-fin	IMPF|3P|IND
v	v-fin	IMPF|3P|SUBJ
v	v-fin	IMPF|3S|IND
v	v-fin	IMPF|3S|SUBJ
v	v-fin	IMP|2S
v	v-fin	MQP|1/3S|IND
v	v-fin	MQP|1S|IND
v	v-fin	MQP|3P|IND
v	v-fin	MQP|3S|IND
v	v-fin	PR/PS|1P|IND
v	v-fin	PR|1/3S|SUBJ
v	v-fin	PR|1P|IND
v	v-fin	PR|1P|SUBJ
v	v-fin	PR|1S|IND
v	v-fin	PR|1S|SUBJ
v	v-fin	PR|2P|IND
v	v-fin	PR|2S|IND
v	v-fin	PR|2S|SUBJ
v	v-fin	PR|3P|IND
v	v-fin	PR|3P|SUBJ
v	v-fin	PR|3S
v	v-fin	PR|3S|IND
v	v-fin	PR|3S|SUBJ
v	v-fin	PS/MQP|3P|IND
v	v-fin	PS|1/3S|IND
v	v-fin	PS|1P|IND
v	v-fin	PS|1S|IND
v	v-fin	PS|2S|IND
v	v-fin	PS|3P|IND
v	v-fin	PS|3S|IND
v	v-ger	<ALT>
v	v-ger	<hyfen>
v	v-ger	_
v	v-inf	1/3S
v	v-inf	1P
v	v-inf	1S
v	v-inf	3P
v	v-inf	3S
v	v-inf	<DERP>
v	v-inf	<DERS>
v	v-inf	<hyfen>
v	v-inf	<hyfen>|1S
v	v-inf	<hyfen>|3P
v	v-inf	<hyfen>|3S
v	v-inf	<n>
v	v-inf	<n>|3S
v	v-inf	_
v	v-pcp	<ALT>|F|S
v	v-pcp	<DERP>|M|P
v	v-pcp	<DERS>|F|P
v	v-pcp	<DERS>|M|S
v	v-pcp	<n>|F|P
v	v-pcp	<n>|F|S
v	v-pcp	<n>|M|P
v	v-pcp	<n>|M|S
v	v-pcp	<prop>|F|S
v	v-pcp	<prop>|M|P
v	v-pcp	F|P
v	v-pcp	F|S
v	v-pcp	M|P
v	v-pcp	M|S
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

Lingua::Interset::Tagset::PT::Conll - Driver for the Portuguese tagset of the CoNLL 2006 Shared Task (derived from the Bosque / Floresta sintá(c)tica treebank).

=head1 VERSION

version 3.006

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::PT::Conll;
  my $driver = Lingua::Interset::Tagset::PT::Conll->new();
  my $fs = $driver->decode("n\tn\tM|S");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('pt::conll', "n\tn\tM|S");

=head1 DESCRIPTION

Interset driver for the Portuguese tagset of the CoNLL 2006 Shared Task.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT. For Portuguese,
these values are derived from the tagset of the Bosque treebank (part of Floresta sintá(c)tica).

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
