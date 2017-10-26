# ABSTRACT: Driver for the Bulgarian tagset of the CoNLL 2006 Shared Task.
# (Documentation at http://www.bultreebank.org/TechRep/BTB-TR03.pdf)
# Copyright © 2007, 2009, 2011, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# 4.4.2009: numtype and numvalue separated from subpos, new generic numerals
# 5.4.2009: advtype separated from subpos

package Lingua::Interset::Tagset::BG::Conll;
use strict;
use warnings;
our $VERSION = '3.007';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset::Conll';



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
    return 'bg::conll';
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
        'tagset' => 'bg::conll',
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # indeclinable foreign noun
            'N' => ['pos' => 'noun', 'foreign' => 'yes'],
            # common noun
            'Nc' => ['pos' => 'noun', 'nountype' => 'com'],
            # proper noun
            'Np' => ['pos' => 'noun', 'nountype' => 'prop'],
            # Nm = typo? (The only example is "lv." ("leva"). There are other abbreviations tagged as Nc. Even "lv." occurs many other times tagged as Nc!)
            'Nm' => ['pos' => 'noun', 'other' => {'subpos' => 'Nm'}],
            # H = hybrid between noun and adjective (surnames, names of villages - Ivanov, Ivanovo)
            # Historically these words are possessive adjectives.
            # Most word forms in this class can have two meanings:
            # Ivanov = Ivanov (family name, noun)
            # Ivanov = Ivan's (possessive adjective)
            # subpos: H Hf Hm Hn
            # The second character encodes gender.
            # If there is no second character, it is plural, which is genderless.
            # We do not decode the gender/number here, we are waiting for the features.
            # We have to preserve tags like "H Hm _" where the gender is not in the features.
            'H' => ['pos' => 'noun|adj', 'nountype' => 'prop', 'poss' => 'yes', 'other' => {'subpos' => 'H'}],
            'Hm' => ['pos' => 'noun|adj', 'nountype' => 'prop', 'poss' => 'yes', 'other' => {'subpos' => 'Hm'}],
            'Hf' => ['pos' => 'noun|adj', 'nountype' => 'prop', 'poss' => 'yes', 'other' => {'subpos' => 'Hf'}],
            'Hn' => ['pos' => 'noun|adj', 'nountype' => 'prop', 'poss' => 'yes', 'other' => {'subpos' => 'Hn'}],
            # adjective
            # subpos: A Af Am An
            # The second character encodes gender.
            # If there is no second character, it is plural, which is genderless.
            # We do not decode the gender/number here, we are waiting for the features.
            # We have to preserve tags like "A Am _" where the gender is not in the features.
            'A' => ['pos' => 'adj', 'other' => {'subpos' => 'A'}],
            'Am' => ['pos' => 'adj', 'other' => {'subpos' => 'Am'}],
            'Af' => ['pos' => 'adj', 'other' => {'subpos' => 'Af'}],
            'An' => ['pos' => 'adj', 'other' => {'subpos' => 'An'}],
            # pronoun
            # subpos: P Pc Pd Pf Pi Pn Pp Pr Ps
            # P = probably error; the only example is "za_razlika_ot" ("in contrast to")
            'P' => ['pos' => 'noun|adj|adv', 'prontype' => 'prn'],
            'Pp' => ['pos' => 'noun', 'prontype' => 'prs'],
            'Ps' => ['pos' => 'adj', 'prontype' => 'prs', 'poss' => 'yes'],
            'Pd' => ['pos' => 'noun|adj|adv', 'prontype' => 'dem'],
            'Pi' => ['pos' => 'noun|adj|adv', 'prontype' => 'int'],
            'Pr' => ['pos' => 'noun|adj|adv', 'prontype' => 'rel'],
            'Pc' => ['pos' => 'noun|adj|adv', 'prontype' => 'tot'], # "collective pronoun"
            'Pf' => ['pos' => 'noun|adj|adv', 'prontype' => 'ind'],
            'Pn' => ['pos' => 'noun|adj|adv', 'prontype' => 'neg', 'polarity' => 'neg'],
            # numeral
            # subpos: Mc Mo Md My
            # Mc = cardinals
            'Mc' => ['pos' => 'num', 'numtype' => 'card'],
            # Mo = ordinals
            'Mo' => ['pos' => 'adj', 'numtype' => 'ord'],
            # Md = adverbial numerals
            # This does not mean that there are no "P Pf ref=q". There are. Examples: "nekolcina", "njakolko".
            # poveče, malko, mnogo, măničko
            'Md' => ['pos' => 'num', 'numtype' => 'card', 'prontype' => 'ind', 'other' => {'subpos' => 'Md'}],
            # My = fuzzy numerals about people
            # Only two varieties:
            # M\tMy\t_
            # M\tMy\tdef=i
            # This is unlike N\tNc which either has "_" features, or always at least number, mostly also gender, in addition to definiteness.
            # malcina = few people, mnozina = many people
            # seems more like a noun (noun phrase) than a numeral
            'My' => ['pos' => 'noun', 'other' => {'subpos' => 'My'}],
            # verb
            # V Vii Vni Vnp Vpi Vpp Vxi Vyp
            # Vni = non-personal (has 3rd person only) imperfective verb
            'Vni' => ['pos' => 'verb', 'aspect' => 'imp', 'other' => {'subpos' => 'nonpers'}],
            # Vnp = non-personal perfective
            'Vnp' => ['pos' => 'verb', 'aspect' => 'perf', 'other' => {'subpos' => 'nonpers'}],
            # Vpi = personal imperfective
            'Vpi' => ['pos' => 'verb', 'aspect' => 'imp', 'other' => {'subpos' => 'pers'}],
            # Vpp = personal perfective
            'Vpp' => ['pos' => 'verb', 'aspect' => 'perf', 'other' => {'subpos' => 'pers'}],
            # Vxi = "săm" imperfective
            'Vxi' => ['pos' => 'verb', 'verbtype' => 'aux', 'aspect' => 'imp', 'other' => {'subpos' => 'săm'}],
            # Vyp = "băda" perfective
            'Vyp' => ['pos' => 'verb', 'verbtype' => 'aux', 'aspect' => 'perf', 'other' => {'subpos' => 'băda'}],
            # Vii = "bivam" imperfective
            'Vii' => ['pos' => 'verb', 'verbtype' => 'aux', 'aspect' => 'imp', 'other' => {'subpos' => 'bivam'}],
            # V ... probably a tagging error
            'V'   => ['pos' => 'verb'],
            # adverb
            'D'  => ['pos' => 'adv'],
            # Dm = adverb of manner
            'Dm' => ['pos' => 'adv', 'advtype' => 'man'],
            # Dl = adverb of location
            'Dl' => ['pos' => 'adv', 'advtype' => 'loc'],
            # Dt = adverb of time
            'Dt' => ['pos' => 'adv', 'advtype' => 'tim'],
            # Dq = adverb of quantity or degree
            'Dq' => ['pos' => 'adv', 'advtype' => 'deg'],
            # Dd = adverb of modal nature
            'Dd' => ['pos' => 'adv', 'advtype' => 'mod'],
            # preposition
            'R' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # conjunction
            # Cc = coordinative conjunction
            'Cc' => ['pos' => 'conj', 'conjtype' => 'coor'],
            # Cs = subordinative conjunction
            'Cs' => ['pos' => 'conj', 'conjtype' => 'sub'],
            # Cr = repetitive coordinative conjunction
            # hem ... hem = either ... or
            'Cr' => ['pos' => 'conj', 'conjtype' => 'coor', 'other' => {'subpos' => 'rep'}],
            # Cp = single and repetitive coordinative conjunction
            # i = and
            'Cp' => ['pos' => 'conj', 'conjtype' => 'coor', 'other' => {'subpos' => 'srep'}],
            # particle
            # Ta Te Tg Ti Tm Tn Tv Tx
            # Ta = affirmative particle
            # da = yes
            'Ta' => ['pos' => 'part', 'parttype' => 'res', 'polarity' => 'pos'],
            # Tn = negative particle
            # ne = no
            'Tn' => ['pos' => 'part', 'parttype' => 'res', 'polarity' => 'neg'],
            # Ti = interrogative particle
            # li = question particle
            'Ti' => ['pos' => 'part', 'prontype' => 'int'],
            # Tx = auxiliary particle
            # da = to
            # šte = will
            'Tx' => ['pos' => 'part', 'verbtype' => 'aux'],
            # Tm = modal particle
            # maj = possibly
            'Tm' => ['pos' => 'part', 'parttype' => 'mod'],
            # Tv = verbal particle
            # neka = let
            'Tv' => ['pos' => 'part', 'parttype' => 'mod', 'other' => {'subpos' => 'verb'}],
            # Te = emphasis particle
            # daže = even
            'Te' => ['pos' => 'part', 'parttype' => 'emp'],
            # Tg = gradable particle
            # naj = most
            'Tg' => ['pos' => 'part', 'degree' => 'sup'],
            # interjection
            # mjau = miao
            # lele = gosh
            'I' => ['pos' => 'int'],
            # punctuation
            'Punct' => ['pos' => 'punc']
        },
        'encode_map' =>

            { 'prontype' => { 'prs' => { 'poss' => { 'yes' => 'Ps',
                                                     '@'   => 'Pp' }},
                              'dem' => 'Pd',
                              'int' => { 'pos' => { 'part' => 'Ti',
                                                    '@'    => 'Pi' }},
                              'rel' => 'Pr',
                              'tot' => 'Pc',
                              'ind' => { 'numtype' => { 'card' => 'Md',
                                                        '@'    => 'Pf' }},
                              'neg' => 'Pn',
                              'prn' => 'P',
                              '@'   => { 'pos' => { 'noun' => { 'other/subpos' => { 'My' => 'My',
                                                                                    'Nm' => 'Nm',
                                                                                    '@'  => { 'foreign' => { 'yes' => 'N',
                                                                                                             '@'       => { 'poss' => { 'yes' => { 'number' => { 'sing' => { 'gender' => { 'masc' => 'Hm',
                                                                                                                                                                                            'fem'  => 'Hf',
                                                                                                                                                                                            'neut' => 'Hn',
                                                                                                                                                                                            '@'    => 'H' }},
                                                                                                                                                                  '@'    => 'H' }},
                                                                                                                                        '@'    => { 'nountype' => { 'prop' => 'Np',
                                                                                                                                                                    '@'    => 'Nc' }}}}}}}},
                                                    'adj'  => { 'numtype' => { 'ord' => 'Mo',
                                                                               '@'   => { 'other/subpos' => { 'Am' => 'Am',
                                                                                                              'Af' => 'Af',
                                                                                                              'An' => 'An',
                                                                                                              'A'  => 'A',
                                                                                                              '@'  => { 'poss' => { 'yes' => { 'number' => { 'sing' => { 'gender' => { 'masc' => 'Hm',
                                                                                                                                                                                        'fem'  => 'Hf',
                                                                                                                                                                                        'neut' => 'Hn',
                                                                                                                                                                                        '@'    => 'H' }},
                                                                                                                                                              '@'    => 'H' }},
                                                                                                                                    '@'    => { 'number' => { 'sing' => { 'gender' => { 'masc' => 'Am',
                                                                                                                                                                                        'fem'  => 'Af',
                                                                                                                                                                                        'neut' => 'An',
                                                                                                                                                                                        '@'    => 'A' }},
                                                                                                                                                              '@'    => 'A' }}}}}}}},
                                                    'num'  => { 'other/subpos' => { 'Md' => 'Md',
                                                                                    'My' => 'My',
                                                                                    '@'  => { 'numtype' => { 'ord' => 'Mo',
                                                                                                             '@'   => 'Mc' }}}},
                                                    'verb' => { 'aspect' => { 'imp'  => { 'other/subpos' => { 'săm'     => 'Vxi',
                                                                                                              'bivam'   => 'Vii',
                                                                                                              'nonpers' => 'Vni',
                                                                                                              '@'       => { 'verbtype' => { 'aux' => 'Vxi',
                                                                                                                                             '@'   => 'Vpi' }}}},
                                                                              'perf' => { 'other/subpos' => { 'băda'    => 'Vyp',
                                                                                                              'nonpers' => 'Vnp',
                                                                                                              '@'       => { 'verbtype' => { 'aux' => 'Vyp',
                                                                                                                                             '@'   => 'Vpp' }}}},
                                                                              '@'    => 'V' }},
                                                    'adv'  => { 'advtype' => { 'mod' => 'Dd',
                                                                               'deg' => 'Dq',
                                                                               'loc' => 'Dl',
                                                                               'tim' => 'Dt',
                                                                               'man' => 'Dm',
                                                                               '@'   => 'D' }},
                                                    'adp'  => 'R',
                                                    'conj' => { 'conjtype' => { 'sub' => 'Cs',
                                                                                '@'   => { 'other/subpos' => { 'rep'  => 'Cr',
                                                                                                               'srep' => 'Cp',
                                                                                                               '@'    => 'Cc' }}}},
                                                    'part' => { 'parttype' => { 'mod' => { 'other/subpos' => { 'verb' => 'Tv',
                                                                                                               '@'    => 'Tm' }},
                                                                                'emp' => 'Te',
                                                                                '@'   => { 'polarity' => { 'pos' => 'Ta',
                                                                                                           'neg' => 'Tn',
                                                                                                           '@'   => { 'prontype' => { 'int' => 'Ti',
                                                                                                                                      '@'   => { 'degree' => { 'sup' => 'Tg',
                                                                                                                                                               '@'   => 'Tx' }}}}}}}},
                                                    'int'  => 'I',
                                                    'punc' => 'Punct' }}}}
    );
    # ASPECT ####################
    $atoms{aspect} = $self->create_simple_atom
    (
        'intfeature' => 'aspect',
        'simple_decode_map' =>
        {
            'p' => 'perf'
        }
    );
    # CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'n' => 'nom',
            # dp = dative possessive case of pronouns
            # We encode it as genitive.
            'dp' => 'gen',
            'd'  => 'dat',
            'a'  => 'acc',
            'v'  => 'voc'
        }
    );
    # CAUSE ####################
    # Interrogative adverbs of cause: "zašto" = "why".
    $atoms{cause} = $self->create_atom
    (
        'surfeature' => 'cause',
        'decode_map' =>
        {
            'cause' => ['pos' => 'adv', 'prontype' => 'int', 'advtype' => 'cau']
        },
        'encode_map' =>

            { 'advtype' => { 'cau' => 'cause' }}
    );
    # DEFINITENESS ####################
    $atoms{def} = $self->create_atom
    (
        'tagset' => 'bg::conll',
        'surfeature' => 'def',
        'decode_map' =>
        {
            'd' => ['definite' => 'def'],
            # full definite article of masculines
            # We cannot use variant = long because it would collide with the form feature of pronouns.
            'f' => ['definite' => 'def', 'other' => {'definiteness' => 'f'}],
            # short definite article of masculines
            # We cannot use variant = short because it would collide with the form feature of pronouns.
            'h' => ['definite' => 'def', 'other' => {'definiteness' => 'h'}],
            'i' => ['definite' => 'ind']
        },
        'encode_map' =>

            { 'definite' => { 'def' => { 'other/definiteness' => { 'f' => 'f',
                                                                   'h' => 'h',
                                                                   '@' => 'd' }},
                              'ind' => 'i' }}
    );
    # FORM ####################
    $atoms{form} = $self->create_atom
    (
        'surfeature' => 'form',
        'decode_map' =>
        {
            # archaic long form of adjective
            'ext' => ['style' => 'arch', 'variant' => 'long'],
            # full form of personal or possessive pronoun
            'f'   => ['variant' => 'long'],
            # short form (clitic) of personal or possessive pronoun
            's'   => ['variant' => 'short']
        },
        'encode_map' =>

            { 'variant' => { 'long' => { 'style' => { 'arch' => 'ext',
                                                      '@'    => 'f' }},
                             'short' => 's' }}
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
    # TRANSITIVITY ####################
    $atoms{imtrans} = $self->create_simple_atom
    (
        'intfeature' => 'subcat',
        'simple_decode_map' =>
        {
            'i' => 'intr',
            't' => 'tran'
        }
    );
    # MOOD ####################
    $atoms{mood} = $self->create_atom
    (
        'surfeature' => 'mood',
        'decode_map' =>
        {
            'i' => ['verbform' => 'fin', 'mood' => 'ind'],
            'z' => ['verbform' => 'fin', 'mood' => 'imp'],
            'u' => ['verbform' => 'fin', 'mood' => 'sub']
        },
        'encode_map' =>

            { 'mood' => { 'ind' => 'i',
                          'imp' => 'z',
                          'sub' => 'u' }}
    );
    # NUMBER ####################
    $atoms{num} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            's' => 'sing',
            'p' => 'plur',
            # t = count form
            # special ending for plural of inanimate nouns in counted noun phrases
            # corresponds to the singular genitive ussage in Russian ("tri časa")
            # we encode it as dual
            't' => 'dual',
            # pluralia tantum (nouns that only appear in plural: "The Alps")
            'pia_tantum' => 'ptan'
        }
    );
    # PAST ####################
    $atoms{past} = $self->create_simple_atom
    (
        'intfeature' => 'tense',
        'simple_decode_map' =>
        {
            'past' => 'past'
        }
    );
    # PERSON ####################
    $atoms{pers} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            '1' => '1',
            '2' => '2',
            '3' => '3'
        }
    );
    # POSSGENDER ####################
    # This was originally called "gen". We do not like two "gen"s in one tag, so we renamed it at the beginning of decoding.
    $atoms{possgen} = $self->create_simple_atom
    (
        'intfeature' => 'possgender',
        'simple_decode_map' =>
        {
            'm' => 'masc',
            'f' => 'fem',
            'n' => 'neut'
        }
    );
    # REFERENT TYPE ####################
    # Some pronouns are in fact pronominal numerals or adverbs. This feature distinguishes them semantically.
    $atoms{'ref'} = $self->create_atom
    (
        'surfeature' => 'ref',
        'decode_map' =>
        {
            # e = entity
            'e' => ['pos' => 'noun'],
            # r = reflexive
            'r' => ['reflex' => 'yes'],
            # a = attribute
            'a' => ['pos' => 'adj'],
            # p = possessor
            # not normal possessive pronouns (my, his, our) but relative/indefinite/negative (whose, someone's, nobody's)
            'p' => ['poss' => 'yes'],
            # op = one possessor
            'op' => ['poss' => 'yes', 'possnumber' => 'sing'],
            # mp = many possessors
            'mp' => ['poss' => 'yes', 'possnumber' => 'plur'],
            # q = quantity or degree
            'q' => ['pos' => 'num'],
            # l = location
            'l' => ['pos' => 'adv', 'advtype' => 'loc'],
            # t = time
            't' => ['pos' => 'adv', 'advtype' => 'tim'],
            # m = manner
            'm' => ['pos' => 'adv', 'advtype' => 'man']
        },
        'encode_map' =>

            { 'reflex' => { 'yes' => 'r',
                            '@'      => { 'poss' => { 'yes' => { 'possnumber' => { 'sing' => 'op',
                                                                                    'plur'  => 'mp',
                                                                                    '@'    => 'p' }},
                                                      '@'    => { 'pos' => { 'adj|adv|noun' => '',
                                                                             'noun' => 'e',
                                                                             'adj'  => 'a',
                                                                             'num'  => 'q',
                                                                             'adv'  => { 'advtype' => { 'loc' => 'l',
                                                                                                        'tim' => 't',
                                                                                                        'man' => 'm' }}}}}}}}
    );
    # TENSE ####################
    $atoms{tense} = $self->create_simple_atom
    (
        'intfeature' => 'tense',
        'simple_decode_map' =>
        {
            # present
            'r' => 'pres',
            # aorist (past tense that is neither perfect, nor imperfect)
            'o' => 'aor',
            # m = imperfect; PROBLEM: verbs classified as perfective occur (although rarely) in the imperfect past tense
            # Bulgarian has lexical aspect and grammatical aspect.
            # Lexical aspect is inherent in verb lemma.
            # Grammatical: imperfect tenses, perfect tenses, and aorist (aspect-neutral).
            # Main clause: perfective verb with perfect tense or aorist; imperfective with imperfect or aorist.
            # Relative clause: perfective verb can occur in imperfect tense, and vice versa.
            # triple specification of aspect:
            # detailed part of speech = Vpp (verb personal perfective)
            # aspect = p (perfective)
            # tense = m (imperfect)
            'm' => 'imp'
        }
    );
    # TRANSITIVITY ####################
    $atoms{trans} = $self->create_simple_atom
    (
        'intfeature' => 'subcat',
        'simple_decode_map' =>
        {
            'i' => 'intr',
            't' => 'tran'
        }
    );
    # TYPE OF VERB ####################
    $atoms{type} = $self->create_simple_atom
    (
        'intfeature' => 'verbtype',
        'simple_decode_map' =>
        {
            'aux' => 'aux'
        }
    );
    # VERB FORM ####################
    $atoms{vform} = $self->create_simple_atom
    (
        'intfeature' => 'verbform',
        'simple_decode_map' =>
        {
            # c = participle: izbiran, navăršil, izkazanite, priet, dejstvašt
            'c' => 'part',
            # g = gerund: prevărtajki, demonstrirajki, stradajki, pišejki, otčitajki, izključaja
            # what bultreebank calls gerund is in fact adverbial participle (called present transgressive in Czech)
            'g' => 'conv'
        }
    );
    # VOICE ####################
    $atoms{voice} = $self->create_simple_atom
    (
        'intfeature' => 'voice',
        'simple_decode_map' =>
        {
            'a' => 'act',
            'v' => 'pass'
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
    my @features = ('aspect', 'case', 'cause', 'def', 'form', 'gen', 'imtrans', 'mood', 'num', 'past', 'pers', 'possgen', 'ref', 'tense', 'trans', 'type', 'vform', 'voice');
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
        '@' => ['type', 'aspect', 'trans', 'vform', 'voice', 'mood', 'tense', 'past', 'ref', 'cause', 'gen', 'pers', 'num', 'case', 'def', 'form', 'possgen'],
        'P' => ['ref', 'cause', 'form', 'case', 'num', 'pers', 'gen', 'def', 'possgen'],
        'V' => ['type', 'aspect', 'trans', 'vform', 'voice', 'mood', 'tense', 'past', 'pers', 'num', 'gen', 'def'],
        'T' => []
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
    my $atoms = $self->atoms();
    # Three components: coarse-grained pos, fine-grained pos, features
    # Only features with non-empty values appear in the tag.
    # example: N\tNC\tgender=neuter|number=sing|case=unmarked|def=indef
    # This tag set is really a damn masterpiece. The "gen" feature can occur twice
    # in a tag for possessive pronouns! If that happens, the first occurrence
    # denotes the gender of the owned, the second one denotes the gender of the
    # owner. We start with renaming the second to avoid later confusion.
    $tag =~ s/\|gen=(.\|.*)\|gen=/\|gen=$1\|possgen=/;
    # Also, if number is plural, there is only one gender but it is the possessor's.
    $tag =~ s/\|num=p\|(.*)\|gen=/\|num=p\|$1\|possgen=/;
    # Also, all indefinite pronouns start with def=i and there can (but need not) be another def at the end.
    $tag =~ s/Pf\tdef=i\|/Pf\t/;
    my $fs = $self->decode_conll($tag);
    # Default feature values. Used to improve collaboration with other drivers.
    if($fs->is_verb())
    {
        if($fs->verbform() eq '')
        {
            if($fs->person() ne '')
            {
                $fs->set_verbform('fin');
                if($fs->mood() eq '')
                {
                    $fs->set_mood('ind');
                }
            }
            else
            {
                $fs->set_verbform('inf');
            }
        }
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
    my $pos = $subpos eq 'Punct' ? 'Punct' : substr($subpos, 0, 1);
    my $fpos = $pos;
    $fpos = '@' unless($fpos =~ m/^[PVT]$/);
    my $feature_names = $self->get_feature_names($fpos);
    my @feature_names = @{$feature_names};
    my @features;
    # def1
    # The features of indefinite pronouns (Pf) always begin with "def=i".
    # Another definiteness can occur at the end, this time not necessarily indefinite!
    # Examples: edin i i, edinja i h, edinjat i f, ednata i d, nekolcina i i, nešta i i, neštata i d, njakolko i i.
    # Note that we have to distinguish the indefinite pronouns from the Md numerals.
    if($pos eq 'P' && $fs->contains('prontype', 'ind'))
    {
        push(@features, 'def=i');
    }
    foreach my $name (@feature_names)
    {
        # aspect
        # Verbs explicitly specify only perfect aspect as feature (and it is superfluous because part of speech reflects aspect).
        # The superfluous feature is present only for some subclasses of verbs.
        if($name eq 'aspect')
        {
            if($fs->aspect() ne 'perf' ||
               $fs->verbtype() ne 'aux' && ($fs->get_other_subfeature('bg::conll', 'subpos') eq 'nonpers' || $fs->subcat() eq ''))
            {
                next;
            }
        }
        # transitivity of verbs
        # The 'imtrans' feature occurs at nonpersonal imperfective verbs.
        # Otherwise, the feature is called 'trans'.
        if($name eq 'trans' && $fs->get_other_subfeature('bg::conll', 'subpos') eq 'nonpers' && $fs->aspect() eq 'imp')
        {
            $name = 'imtrans';
        }
        if(!defined($atoms->{$name}))
        {
            confess("Cannot find atom for '$name'");
        }
        # Only encode referent type for pronouns.
        next if($name eq 'ref' && $pos ne 'P');
        my $value = $atoms->{$name}->encode($fs);
        if($value ne '')
        {
            if($name =~ m/^(cause|past)$/)
            {
                push(@features, $name);
            }
            elsif($name eq 'ref' && $value ne 'r' && $fs->prontype() eq 'prs' && $fs->person() eq '')
            {
                next;
            }
            elsif($name eq 'def' && $value eq 'd')
            {
                # Masculine definite morpheme can be either full ('f') or short ('s').
                # Other genders have just one definite value ('d').
                if($fs->gender() eq 'masc' && $fs->number() eq 'sing')
                {
                    # We will make the full form default.
                    # Only the 'other' feature can toggle the short form (but then we would not be here because $value would be already 'h').
                    push(@features, 'def=f');
                }
                else
                {
                    push(@features, 'def=d');
                }
            }
            elsif($name eq 'possgen')
            {
                # Due to the endless wisdom of the creators of this tag set, the possessor's gender is encoded as a second "gen" at the end of the tag.
                push(@features, "gen=$value");
            }
            else
            {
                push(@features, "$name=$value");
            }
        }
    }
    my $features = '_';
    if(scalar(@features) > 0)
    {
        $features = join('|', @features);
    }
    my $tag = "$pos\t$subpos\t$features";
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# cat bgtrain.conll bgtest.conll |\
#   perl -pe '@x = split(/\s+/, $_); $_ = "$x[3]\t$x[4]\t$x[5]\n"' |\
#   sort -u | wc -l
# 528 tags; extended manually to 533 tags
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
A\tA\t_
A\tAf\t_
A\tAf\tgen=f|num=s|def=d
A\tAf\tgen=f|num=s|def=i
A\tAm\t_
A\tAm\tgen=m|num=s|def=f
A\tAm\tgen=m|num=s|def=h
A\tAm\tgen=m|num=s|def=i
A\tAm\tgen=m|num=s|form=ext
A\tAn\tgen=n|num=s|def=d
A\tAn\tgen=n|num=s|def=i
A\tA\tnum=p|def=d
A\tA\tnum=p|def=i
C\tCc\t_
C\tCp\t_
C\tCr\t_
C\tCs\t_
D\tD\t_
D\tDd\t_
D\tDl\t_
D\tDm\t_
D\tDq\t_
D\tDt\t_
H\tHf\tgen=f|num=s|def=i
H\tHm\tgen=m|num=s|def=f
H\tHm\tgen=m|num=s|def=i
H\tHn\tgen=n|num=s|def=i
H\tH\tnum=p|def=i
I\tI\t_
M\tMc\t_
M\tMc\tdef=d
M\tMc\tdef=i
M\tMc\tgen=f|def=d
M\tMc\tgen=f|def=i
M\tMc\tgen=f|num=s|def=d
M\tMc\tgen=f|num=s|def=i
M\tMc\tgen=m|def=d
M\tMc\tgen=m|def=i
M\tMc\tgen=m|num=s|def=f
M\tMc\tgen=m|num=s|def=i
M\tMc\tgen=n|def=d
M\tMc\tgen=n|def=i
M\tMc\tgen=n|num=s|def=d
M\tMc\tgen=n|num=s|def=i
M\tMd\t_
M\tMd\tdef=d
M\tMd\tdef=i
M\tMo\tgen=f|num=s|def=d
M\tMo\tgen=f|num=s|def=i
M\tMo\tgen=m|num=s|def=f
M\tMo\tgen=m|num=s|def=h
M\tMo\tgen=m|num=s|def=i
M\tMo\tgen=n|num=s|def=d
M\tMo\tgen=n|num=s|def=i
M\tMo\tnum=p|def=d
M\tMo\tnum=p|def=i
M\tMy\t_
M\tMy\tdef=i
N\tN\t_
N\tNc\t_
N\tNc\tdef=i
N\tNc\tgen=f|num=p|def=d
N\tNc\tgen=f|num=p|def=i
N\tNc\tgen=f|num=s|case=v
N\tNc\tgen=f|num=s|def=d
N\tNc\tgen=m|num=p|def=d
N\tNc\tgen=m|num=p|def=i
N\tNc\tgen=m|num=s|case=v
N\tNc\tgen=m|num=s|def=f
N\tNc\tgen=m|num=s|def=h
N\tNc\tgen=m|num=s|def=i
N\tNc\tgen=m|num=t
N\tNc\tgen=n|num=p|def=d
N\tNc\tgen=n|num=p|def=i
N\tNc\tgen=n|num=s|def=d
N\tNc\tgen=n|num=s|def=i
N\tNc\tnum=pia_tantum|def=d
N\tNc\tnum=pia_tantum|def=i
N\tNm\t_
N\tNp\t_
N\tNp\tgen=f|num=p|def=d
N\tNp\tgen=f|num=p|def=i
N\tNp\tgen=f|num=s|case=v
N\tNp\tgen=f|num=s|def=i
N\tNp\tgen=m|num=p|def=d
N\tNp\tgen=m|num=p|def=i
N\tNp\tgen=m|num=s|case=a
N\tNp\tgen=m|num=s|case=v
N\tNp\tgen=m|num=s|def=f
N\tNp\tgen=m|num=s|def=h
N\tNp\tgen=m|num=s|def=i
N\tNp\tgen=n|num=p|def=d
N\tNp\tgen=n|num=p|def=i
N\tNp\tgen=n|num=s|def=d
N\tNp\tgen=n|num=s|def=i
N\tNp\tnum=pia_tantum|def=i
P\tP\t_
P\tPc\tref=a|num=p
P\tPc\tref=a|num=s|gen=f
P\tPc\tref=a|num=s|gen=m
P\tPc\tref=a|num=s|gen=n
P\tPc\tref=e|case=a|num=s|gen=m
P\tPc\tref=e|case=n|num=p
P\tPc\tref=e|case=n|num=s|gen=f
P\tPc\tref=e|case=n|num=s|gen=m
P\tPc\tref=e|case=n|num=s|gen=n
P\tPc\tref=l
P\tPc\tref=q|num=p|def=d
P\tPc\tref=q|num=s|gen=n|def=d
P\tPc\tref=t
P\tPd\t_
P\tPd\tref=a|num=p
P\tPd\tref=a|num=s|gen=f
P\tPd\tref=a|num=s|gen=n
P\tPd\tref=e|case=n|num=p
P\tPd\tref=e|case=n|num=s|gen=f
P\tPd\tref=e|case=n|num=s|gen=m
P\tPd\tref=e|case=n|num=s|gen=n
P\tPd\tref=l
P\tPd\tref=m
P\tPd\tref=q
P\tPd\tref=t
P\tPf\tdef=i|ref=a|num=p
P\tPf\tdef=i|ref=a|num=s|gen=f
P\tPf\tdef=i|ref=a|num=s|gen=m
P\tPf\tdef=i|ref=a|num=s|gen=n
P\tPf\tdef=i|ref=e|case=a|num=s|gen=m
P\tPf\tdef=i|ref=e|case=d|num=s|gen=m
P\tPf\tdef=i|ref=e|case=n|num=p
P\tPf\tdef=i|ref=e|case=n|num=p|def=d
P\tPf\tdef=i|ref=e|case=n|num=p|def=i
P\tPf\tdef=i|ref=e|case=n|num=s|gen=f
P\tPf\tdef=i|ref=e|case=n|num=s|gen=f|def=d
P\tPf\tdef=i|ref=e|case=n|num=s|gen=f|def=i
P\tPf\tdef=i|ref=e|case=n|num=s|gen=m
P\tPf\tdef=i|ref=e|case=n|num=s|gen=m|def=f
P\tPf\tdef=i|ref=e|case=n|num=s|gen=m|def=h
P\tPf\tdef=i|ref=e|case=n|num=s|gen=m|def=i
P\tPf\tdef=i|ref=e|case=n|num=s|gen=n
P\tPf\tdef=i|ref=e|case=n|num=s|gen=n|def=d
P\tPf\tdef=i|ref=e|case=n|num=s|gen=n|def=i
P\tPf\tdef=i|ref=l
P\tPf\tdef=i|ref=m
P\tPf\tdef=i|ref=p|num=p
P\tPf\tdef=i|ref=q|def=i
P\tPf\tdef=i|ref=t
P\tPi\tcause
P\tPi\tref=a|num=p
P\tPi\tref=a|num=s|gen=f
P\tPi\tref=a|num=s|gen=m
P\tPi\tref=a|num=s|gen=n
P\tPi\tref=e|case=a|num=s|gen=m
P\tPi\tref=e|case=n|num=p
P\tPi\tref=e|case=n|num=s|gen=f
P\tPi\tref=e|case=n|num=s|gen=m
P\tPi\tref=e|case=n|num=s|gen=n
P\tPi\tref=l
P\tPi\tref=m
P\tPi\tref=p|num=s|gen=f
P\tPi\tref=p|num=s|gen=m
P\tPi\tref=q
P\tPi\tref=t
P\tPn\t_
P\tPn\tref=a|num=p
P\tPn\tref=a|num=s|gen=f
P\tPn\tref=a|num=s|gen=m
P\tPn\tref=a|num=s|gen=n
P\tPn\tref=e|case=a|num=s|gen=m
P\tPn\tref=e|case=d|num=s|gen=m
P\tPn\tref=e|case=n|num=s|gen=f
P\tPn\tref=e|case=n|num=s|gen=m
P\tPn\tref=e|case=n|num=s|gen=n
P\tPn\tref=e|case=n|num=s|gen=n|def=d
P\tPn\tref=l
P\tPn\tref=m
P\tPn\tref=p|num=s|gen=f
P\tPn\tref=t
P\tPp\t_
P\tPp\tref=e|case=n|num=p|pers=1
P\tPp\tref=e|case=n|num=p|pers=2
P\tPp\tref=e|case=n|num=p|pers=3
P\tPp\tref=e|case=n|num=s|pers=1
P\tPp\tref=e|case=n|num=s|pers=2
P\tPp\tref=e|case=n|num=s|pers=3|gen=f
P\tPp\tref=e|case=n|num=s|pers=3|gen=m
P\tPp\tref=e|case=n|num=s|pers=3|gen=n
P\tPp\tref=e|form=f|case=a|num=p|pers=1
P\tPp\tref=e|form=f|case=a|num=p|pers=2
P\tPp\tref=e|form=f|case=a|num=p|pers=3
P\tPp\tref=e|form=f|case=a|num=s|pers=1
P\tPp\tref=e|form=f|case=a|num=s|pers=2
P\tPp\tref=e|form=f|case=a|num=s|pers=3|gen=f
P\tPp\tref=e|form=f|case=a|num=s|pers=3|gen=m
P\tPp\tref=e|form=f|case=a|num=s|pers=3|gen=n
P\tPp\tref=e|form=f|case=d|num=p|pers=1
P\tPp\tref=e|form=f|case=d|num=s|pers=1
P\tPp\tref=e|form=f|case=d|num=s|pers=2
P\tPp\tref=e|form=f|case=d|num=s|pers=3|gen=m
P\tPp\tref=e|form=s|case=a|num=p|pers=1
P\tPp\tref=e|form=s|case=a|num=p|pers=2
P\tPp\tref=e|form=s|case=a|num=p|pers=3
P\tPp\tref=e|form=s|case=a|num=s|pers=1
P\tPp\tref=e|form=s|case=a|num=s|pers=2
P\tPp\tref=e|form=s|case=a|num=s|pers=3|gen=f
P\tPp\tref=e|form=s|case=a|num=s|pers=3|gen=m
P\tPp\tref=e|form=s|case=a|num=s|pers=3|gen=n
P\tPp\tref=e|form=s|case=d|num=p|pers=1
P\tPp\tref=e|form=s|case=d|num=p|pers=2
P\tPp\tref=e|form=s|case=d|num=p|pers=3
P\tPp\tref=e|form=s|case=d|num=s|pers=1
P\tPp\tref=e|form=s|case=d|num=s|pers=2
P\tPp\tref=e|form=s|case=d|num=s|pers=3|gen=f
P\tPp\tref=e|form=s|case=d|num=s|pers=3|gen=m
P\tPp\tref=e|form=s|case=d|num=s|pers=3|gen=n
P\tPp\tref=e|form=s|case=dp|num=p|pers=1
P\tPp\tref=e|form=s|case=dp|num=p|pers=2
P\tPp\tref=e|form=s|case=dp|num=p|pers=3
P\tPp\tref=e|form=s|case=dp|num=s|pers=1
P\tPp\tref=e|form=s|case=dp|num=s|pers=2
P\tPp\tref=e|form=s|case=dp|num=s|pers=3|gen=f
P\tPp\tref=e|form=s|case=dp|num=s|pers=3|gen=m
P\tPp\tref=r|form=f|case=a
P\tPp\tref=r|form=s|case=a
P\tPp\tref=r|form=s|case=d
P\tPp\tref=r|form=s|case=dp
P\tPr\t_
P\tPr\tref=a|num=p
P\tPr\tref=a|num=s|gen=f
P\tPr\tref=a|num=s|gen=m
P\tPr\tref=a|num=s|gen=n
P\tPr\tref=e|case=a|num=s|gen=m
P\tPr\tref=e|case=d|num=s|gen=m
P\tPr\tref=e|case=n|num=p
P\tPr\tref=e|case=n|num=s|gen=f
P\tPr\tref=e|case=n|num=s|gen=m
P\tPr\tref=e|case=n|num=s|gen=n
P\tPr\tref=e|num=s
P\tPr\tref=l
P\tPr\tref=m
P\tPr\tref=p|num=p
P\tPr\tref=p|num=s|gen=f
P\tPr\tref=p|num=s|gen=m
P\tPr\tref=p|num=s|gen=n
P\tPr\tref=q
P\tPr\tref=t
P\tPs\t_
P\tPs\tref=mp|form=f|num=p|pers=1|def=d
P\tPs\tref=mp|form=f|num=p|pers=1|def=i
P\tPs\tref=mp|form=f|num=p|pers=2|def=d
P\tPs\tref=mp|form=f|num=p|pers=3|def=d
P\tPs\tref=mp|form=f|num=p|pers=3|def=i
P\tPs\tref=mp|form=f|num=s|pers=1|gen=f|def=d
P\tPs\tref=mp|form=f|num=s|pers=1|gen=f|def=i
P\tPs\tref=mp|form=f|num=s|pers=1|gen=m|def=f
P\tPs\tref=mp|form=f|num=s|pers=1|gen=m|def=h
P\tPs\tref=mp|form=f|num=s|pers=1|gen=m|def=i
P\tPs\tref=mp|form=f|num=s|pers=1|gen=n|def=d
P\tPs\tref=mp|form=f|num=s|pers=1|gen=n|def=i
P\tPs\tref=mp|form=f|num=s|pers=2|gen=f|def=d
P\tPs\tref=mp|form=f|num=s|pers=2|gen=f|def=i
P\tPs\tref=mp|form=f|num=s|pers=2|gen=m|def=f
P\tPs\tref=mp|form=f|num=s|pers=2|gen=m|def=h
P\tPs\tref=mp|form=f|num=s|pers=2|gen=m|def=i
P\tPs\tref=mp|form=f|num=s|pers=2|gen=n|def=d
P\tPs\tref=mp|form=f|num=s|pers=2|gen=n|def=i
P\tPs\tref=mp|form=f|num=s|pers=3|gen=f|def=d
P\tPs\tref=mp|form=f|num=s|pers=3|gen=f|def=i
P\tPs\tref=mp|form=f|num=s|pers=3|gen=m|def=f
P\tPs\tref=mp|form=f|num=s|pers=3|gen=m|def=h
P\tPs\tref=mp|form=f|num=s|pers=3|gen=m|def=i
P\tPs\tref=mp|form=f|num=s|pers=3|gen=n|def=d
P\tPs\tref=mp|form=f|num=s|pers=3|gen=n|def=i
P\tPs\tref=mp|form=s|pers=1
P\tPs\tref=mp|form=s|pers=2
P\tPs\tref=mp|form=s|pers=3
P\tPs\tref=op|form=f|num=p|pers=1|def=d
P\tPs\tref=op|form=f|num=p|pers=1|def=i
P\tPs\tref=op|form=f|num=p|pers=2|def=d
P\tPs\tref=op|form=f|num=p|pers=3|def=d|gen=f
P\tPs\tref=op|form=f|num=p|pers=3|def=d|gen=m
P\tPs\tref=op|form=f|num=p|pers=3|def=d|gen=n
P\tPs\tref=op|form=f|num=p|pers=3|def=i|gen=f
P\tPs\tref=op|form=f|num=p|pers=3|def=i|gen=m
P\tPs\tref=op|form=f|num=s|pers=1|gen=f|def=d
P\tPs\tref=op|form=f|num=s|pers=1|gen=f|def=i
P\tPs\tref=op|form=f|num=s|pers=1|gen=m|def=f
P\tPs\tref=op|form=f|num=s|pers=1|gen=m|def=h
P\tPs\tref=op|form=f|num=s|pers=1|gen=m|def=i
P\tPs\tref=op|form=f|num=s|pers=1|gen=n|def=d
P\tPs\tref=op|form=f|num=s|pers=1|gen=n|def=i
P\tPs\tref=op|form=f|num=s|pers=2|gen=f|def=d
P\tPs\tref=op|form=f|num=s|pers=2|gen=f|def=i
P\tPs\tref=op|form=f|num=s|pers=2|gen=n|def=i
P\tPs\tref=op|form=f|num=s|pers=3|gen=f|def=d|gen=f
P\tPs\tref=op|form=f|num=s|pers=3|gen=f|def=d|gen=m
P\tPs\tref=op|form=f|num=s|pers=3|gen=f|def=d|gen=n
P\tPs\tref=op|form=f|num=s|pers=3|gen=f|def=i|gen=f
P\tPs\tref=op|form=f|num=s|pers=3|gen=f|def=i|gen=m
P\tPs\tref=op|form=f|num=s|pers=3|gen=m|def=f|gen=f
P\tPs\tref=op|form=f|num=s|pers=3|gen=m|def=f|gen=m
P\tPs\tref=op|form=f|num=s|pers=3|gen=m|def=h|gen=f
P\tPs\tref=op|form=f|num=s|pers=3|gen=m|def=h|gen=m
P\tPs\tref=op|form=f|num=s|pers=3|gen=m|def=f|gen=n
P\tPs\tref=op|form=f|num=s|pers=3|gen=m|def=h|gen=n
P\tPs\tref=op|form=f|num=s|pers=3|gen=m|def=i|gen=f
P\tPs\tref=op|form=f|num=s|pers=3|gen=m|def=i|gen=m
P\tPs\tref=op|form=f|num=s|pers=3|gen=m|def=i|gen=n
P\tPs\tref=op|form=f|num=s|pers=3|gen=n|def=d|gen=f
P\tPs\tref=op|form=f|num=s|pers=3|gen=n|def=d|gen=m
P\tPs\tref=op|form=f|num=s|pers=3|gen=n|def=d|gen=n
P\tPs\tref=op|form=f|num=s|pers=3|gen=n|def=i|gen=f
P\tPs\tref=op|form=f|num=s|pers=3|gen=n|def=i|gen=m
P\tPs\tref=op|form=f|num=s|pers=3|gen=n|def=i|gen=n
P\tPs\tref=op|form=s|pers=1
P\tPs\tref=op|form=s|pers=2
P\tPs\tref=op|form=s|pers=3|gen=f
P\tPs\tref=op|form=s|pers=3|gen=m
P\tPs\tref=op|form=s|pers=3|gen=n
P\tPs\tref=r|form=f|case=n|num=p|def=d
P\tPs\tref=r|form=f|case=n|num=p|def=i
P\tPs\tref=r|form=f|case=n|num=s|gen=f|def=d
P\tPs\tref=r|form=f|case=n|num=s|gen=m|def=f
P\tPs\tref=r|form=f|case=n|num=s|gen=m|def=h
P\tPs\tref=r|form=f|case=n|num=s|gen=m|def=i
P\tPs\tref=r|form=f|case=n|num=s|gen=n|def=d
P\tPs\tref=r|form=f|case=n|num=s|gen=n|def=i
P\tPs\tref=r|form=s|case=n
Punct\tPunct\t_
R\tR\t_
T\tTa\t_
T\tTe\t_
T\tTg\t_
T\tTi\t_
T\tTm\t_
T\tTn\t_
T\tTv\t_
T\tTx\t_
V\tV\t_
V\tVii\ttype=aux|trans=t|mood=i|tense=r|pers=3|num=p
V\tVii\ttype=aux|trans=t|mood=i|tense=r|pers=3|num=s
V\tVni\timtrans=i|mood=i|tense=m|pers=3|num=s
V\tVni\timtrans=i|mood=i|tense=o|pers=3|num=s
V\tVni\timtrans=i|mood=i|tense=r|pers=3|num=s
V\tVni\timtrans=i|vform=c|voice=a|tense=m|num=s|gen=n|def=i
V\tVni\timtrans=i|vform=c|voice=a|tense=o|num=s|gen=n|def=i
V\tVni\timtrans=t|mood=i|tense=m|pers=3|num=s
V\tVni\timtrans=t|mood=i|tense=o|pers=3|num=s
V\tVni\timtrans=t|mood=i|tense=r|pers=3|num=s
V\tVni\timtrans=t|vform=c|voice=a|tense=m|num=s|gen=n|def=i
V\tVni\timtrans=t|vform=c|voice=a|tense=o|num=s|gen=n|def=i
V\tVnp\ttrans=i|mood=i|tense=o|pers=3|num=s
V\tVnp\ttrans=i|mood=i|tense=r|pers=3|num=s
V\tVnp\ttrans=i|vform=c|voice=a|tense=o|num=s|gen=n|def=i
V\tVnp\ttrans=t|mood=i|tense=m|pers=3|num=s
V\tVnp\ttrans=t|vform=c|voice=a|tense=o|num=s|gen=n|def=i
V\tVpi\t_
V\tVpi\ttrans=i|mood=i|tense=m|pers=1|num=p
V\tVpi\ttrans=i|mood=i|tense=m|pers=1|num=s
V\tVpi\ttrans=i|mood=i|tense=m|pers=2|num=s
V\tVpi\ttrans=i|mood=i|tense=m|pers=3|num=p
V\tVpi\ttrans=i|mood=i|tense=m|pers=3|num=s
V\tVpi\ttrans=i|mood=i|tense=o|pers=1|num=p
V\tVpi\ttrans=i|mood=i|tense=o|pers=1|num=s
V\tVpi\ttrans=i|mood=i|tense=o|pers=3|num=p
V\tVpi\ttrans=i|mood=i|tense=o|pers=3|num=s
V\tVpi\ttrans=i|mood=i|tense=r|pers=1|num=p
V\tVpi\ttrans=i|mood=i|tense=r|pers=1|num=s
V\tVpi\ttrans=i|mood=i|tense=r|pers=2|num=p
V\tVpi\ttrans=i|mood=i|tense=r|pers=2|num=s
V\tVpi\ttrans=i|mood=i|tense=r|pers=3|num=p
V\tVpi\ttrans=i|mood=i|tense=r|pers=3|num=s
V\tVpi\ttrans=i|mood=z|pers=2|num=p
V\tVpi\ttrans=i|mood=z|pers=2|num=s
V\tVpi\ttrans=i|vform=c|voice=a|tense=m|num=p|def=i
V\tVpi\ttrans=i|vform=c|voice=a|tense=m|num=s|gen=f|def=i
V\tVpi\ttrans=i|vform=c|voice=a|tense=m|num=s|gen=m|def=i
V\tVpi\ttrans=i|vform=c|voice=a|tense=m|num=s|gen=n|def=i
V\tVpi\ttrans=i|vform=c|voice=a|tense=o|num=p|def=d
V\tVpi\ttrans=i|vform=c|voice=a|tense=o|num=p|def=i
V\tVpi\ttrans=i|vform=c|voice=a|tense=o|num=s|gen=f|def=i
V\tVpi\ttrans=i|vform=c|voice=a|tense=o|num=s|gen=m|def=f
V\tVpi\ttrans=i|vform=c|voice=a|tense=o|num=s|gen=m|def=i
V\tVpi\ttrans=i|vform=c|voice=a|tense=o|num=s|gen=n|def=i
V\tVpi\ttrans=i|vform=c|voice=a|tense=r|num=p|def=d
V\tVpi\ttrans=i|vform=c|voice=a|tense=r|num=p|def=i
V\tVpi\ttrans=i|vform=c|voice=a|tense=r|num=s|gen=f|def=d
V\tVpi\ttrans=i|vform=c|voice=a|tense=r|num=s|gen=f|def=i
V\tVpi\ttrans=i|vform=c|voice=a|tense=r|num=s|gen=m|def=f
V\tVpi\ttrans=i|vform=c|voice=a|tense=r|num=s|gen=m|def=h
V\tVpi\ttrans=i|vform=c|voice=a|tense=r|num=s|gen=m|def=i
V\tVpi\ttrans=i|vform=c|voice=a|tense=r|num=s|gen=n|def=d
V\tVpi\ttrans=i|vform=c|voice=a|tense=r|num=s|gen=n|def=i
V\tVpi\ttrans=i|vform=g
V\tVpi\ttrans=t|mood=i|tense=m|pers=1|num=p
V\tVpi\ttrans=t|mood=i|tense=m|pers=1|num=s
V\tVpi\ttrans=t|mood=i|tense=m|pers=2|num=p
V\tVpi\ttrans=t|mood=i|tense=m|pers=2|num=s
V\tVpi\ttrans=t|mood=i|tense=m|pers=3|num=p
V\tVpi\ttrans=t|mood=i|tense=m|pers=3|num=s
V\tVpi\ttrans=t|mood=i|tense=o|pers=1|num=p
V\tVpi\ttrans=t|mood=i|tense=o|pers=1|num=s
V\tVpi\ttrans=t|mood=i|tense=o|pers=2|num=p
V\tVpi\ttrans=t|mood=i|tense=o|pers=2|num=s
V\tVpi\ttrans=t|mood=i|tense=o|pers=3|num=p
V\tVpi\ttrans=t|mood=i|tense=o|pers=3|num=s
V\tVpi\ttrans=t|mood=i|tense=r|pers=1|num=p
V\tVpi\ttrans=t|mood=i|tense=r|pers=1|num=s
V\tVpi\ttrans=t|mood=i|tense=r|pers=2|num=p
V\tVpi\ttrans=t|mood=i|tense=r|pers=2|num=s
V\tVpi\ttrans=t|mood=i|tense=r|pers=3|num=p
V\tVpi\ttrans=t|mood=i|tense=r|pers=3|num=s
V\tVpi\ttrans=t|mood=z|pers=2|num=p
V\tVpi\ttrans=t|mood=z|pers=2|num=s
V\tVpi\ttrans=t|vform=c|voice=a|tense=m|num=p|def=i
V\tVpi\ttrans=t|vform=c|voice=a|tense=m|num=s|gen=f|def=i
V\tVpi\ttrans=t|vform=c|voice=a|tense=m|num=s|gen=m|def=i
V\tVpi\ttrans=t|vform=c|voice=a|tense=m|num=s|gen=n|def=i
V\tVpi\ttrans=t|vform=c|voice=a|tense=o|num=p|def=i
V\tVpi\ttrans=t|vform=c|voice=a|tense=o|num=s|gen=f|def=i
V\tVpi\ttrans=t|vform=c|voice=a|tense=o|num=s|gen=m|def=i
V\tVpi\ttrans=t|vform=c|voice=a|tense=o|num=s|gen=n|def=i
V\tVpi\ttrans=t|vform=c|voice=a|tense=r|num=p|def=d
V\tVpi\ttrans=t|vform=c|voice=a|tense=r|num=p|def=i
V\tVpi\ttrans=t|vform=c|voice=a|tense=r|num=s|gen=f|def=d
V\tVpi\ttrans=t|vform=c|voice=a|tense=r|num=s|gen=f|def=i
V\tVpi\ttrans=t|vform=c|voice=a|tense=r|num=s|gen=m|def=f
V\tVpi\ttrans=t|vform=c|voice=a|tense=r|num=s|gen=m|def=h
V\tVpi\ttrans=t|vform=c|voice=a|tense=r|num=s|gen=n|def=d
V\tVpi\ttrans=t|vform=c|voice=a|tense=r|num=s|gen=n|def=i
V\tVpi\ttrans=t|vform=c|voice=v|num=p|def=d
V\tVpi\ttrans=t|vform=c|voice=v|num=p|def=i
V\tVpi\ttrans=t|vform=c|voice=v|num=s|gen=f|def=d
V\tVpi\ttrans=t|vform=c|voice=v|num=s|gen=f|def=i
V\tVpi\ttrans=t|vform=c|voice=v|num=s|gen=m|def=f
V\tVpi\ttrans=t|vform=c|voice=v|num=s|gen=m|def=h
V\tVpi\ttrans=t|vform=c|voice=v|num=s|gen=m|def=i
V\tVpi\ttrans=t|vform=c|voice=v|num=s|gen=n|def=d
V\tVpi\ttrans=t|vform=c|voice=v|num=s|gen=n|def=i
V\tVpi\ttrans=t|vform=g
V\tVpp\t_
V\tVpp\taspect=p|trans=i|mood=i|tense=m|pers=3|num=p
V\tVpp\taspect=p|trans=i|mood=i|tense=m|pers=3|num=s
V\tVpp\taspect=p|trans=i|mood=i|tense=o|pers=1|num=p
V\tVpp\taspect=p|trans=i|mood=i|tense=o|pers=1|num=s
V\tVpp\taspect=p|trans=i|mood=i|tense=o|pers=2|num=p
V\tVpp\taspect=p|trans=i|mood=i|tense=o|pers=2|num=s
V\tVpp\taspect=p|trans=i|mood=i|tense=o|pers=3|num=p
V\tVpp\taspect=p|trans=i|mood=i|tense=o|pers=3|num=s
V\tVpp\taspect=p|trans=i|mood=i|tense=r|pers=1|num=p
V\tVpp\taspect=p|trans=i|mood=i|tense=r|pers=1|num=s
V\tVpp\taspect=p|trans=i|mood=i|tense=r|pers=2|num=p
V\tVpp\taspect=p|trans=i|mood=i|tense=r|pers=2|num=s
V\tVpp\taspect=p|trans=i|mood=i|tense=r|pers=3|num=p
V\tVpp\taspect=p|trans=i|mood=i|tense=r|pers=3|num=s
V\tVpp\taspect=p|trans=i|mood=z|pers=2|num=p
V\tVpp\taspect=p|trans=i|mood=z|pers=2|num=s
V\tVpp\taspect=p|trans=i|vform=c|voice=a|tense=m|num=s|gen=n|def=i
V\tVpp\taspect=p|trans=i|vform=c|voice=a|tense=o|num=p|def=d
V\tVpp\taspect=p|trans=i|vform=c|voice=a|tense=o|num=p|def=i
V\tVpp\taspect=p|trans=i|vform=c|voice=a|tense=o|num=s|gen=f|def=d
V\tVpp\taspect=p|trans=i|vform=c|voice=a|tense=o|num=s|gen=f|def=i
V\tVpp\taspect=p|trans=i|vform=c|voice=a|tense=o|num=s|gen=m|def=f
V\tVpp\taspect=p|trans=i|vform=c|voice=a|tense=o|num=s|gen=m|def=h
V\tVpp\taspect=p|trans=i|vform=c|voice=a|tense=o|num=s|gen=m|def=i
V\tVpp\taspect=p|trans=i|vform=c|voice=a|tense=o|num=s|gen=n|def=d
V\tVpp\taspect=p|trans=i|vform=c|voice=a|tense=o|num=s|gen=n|def=i
V\tVpp\taspect=p|trans=t|mood=i|tense=m|pers=1|num=p
V\tVpp\taspect=p|trans=t|mood=i|tense=m|pers=1|num=s
V\tVpp\taspect=p|trans=t|mood=i|tense=m|pers=3|num=p
V\tVpp\taspect=p|trans=t|mood=i|tense=m|pers=3|num=s
V\tVpp\taspect=p|trans=t|mood=i|tense=o|pers=1|num=p
V\tVpp\taspect=p|trans=t|mood=i|tense=o|pers=1|num=s
V\tVpp\taspect=p|trans=t|mood=i|tense=o|pers=2|num=p
V\tVpp\taspect=p|trans=t|mood=i|tense=o|pers=2|num=s
V\tVpp\taspect=p|trans=t|mood=i|tense=o|pers=3|num=p
V\tVpp\taspect=p|trans=t|mood=i|tense=o|pers=3|num=s
V\tVpp\taspect=p|trans=t|mood=i|tense=r|pers=1|num=p
V\tVpp\taspect=p|trans=t|mood=i|tense=r|pers=1|num=s
V\tVpp\taspect=p|trans=t|mood=i|tense=r|pers=2|num=p
V\tVpp\taspect=p|trans=t|mood=i|tense=r|pers=2|num=s
V\tVpp\taspect=p|trans=t|mood=i|tense=r|pers=3|num=p
V\tVpp\taspect=p|trans=t|mood=i|tense=r|pers=3|num=s
V\tVpp\taspect=p|trans=t|mood=z|pers=2|num=p
V\tVpp\taspect=p|trans=t|mood=z|pers=2|num=s
V\tVpp\taspect=p|trans=t|vform=c|voice=a|tense=m|num=s|gen=m|def=i
V\tVpp\taspect=p|trans=t|vform=c|voice=a|tense=o|num=p|def=d
V\tVpp\taspect=p|trans=t|vform=c|voice=a|tense=o|num=p|def=i
V\tVpp\taspect=p|trans=t|vform=c|voice=a|tense=o|num=s|gen=f|def=d
V\tVpp\taspect=p|trans=t|vform=c|voice=a|tense=o|num=s|gen=f|def=i
V\tVpp\taspect=p|trans=t|vform=c|voice=a|tense=o|num=s|gen=m|def=f
V\tVpp\taspect=p|trans=t|vform=c|voice=a|tense=o|num=s|gen=m|def=h
V\tVpp\taspect=p|trans=t|vform=c|voice=a|tense=o|num=s|gen=m|def=i
V\tVpp\taspect=p|trans=t|vform=c|voice=a|tense=o|num=s|gen=n|def=d
V\tVpp\taspect=p|trans=t|vform=c|voice=a|tense=o|num=s|gen=n|def=i
V\tVpp\taspect=p|trans=t|vform=c|voice=v|num=p|def=d
V\tVpp\taspect=p|trans=t|vform=c|voice=v|num=p|def=i
V\tVpp\taspect=p|trans=t|vform=c|voice=v|num=s|gen=f|def=d
V\tVpp\taspect=p|trans=t|vform=c|voice=v|num=s|gen=f|def=i
V\tVpp\taspect=p|trans=t|vform=c|voice=v|num=s|gen=m|def=f
V\tVpp\taspect=p|trans=t|vform=c|voice=v|num=s|gen=m|def=h
V\tVpp\taspect=p|trans=t|vform=c|voice=v|num=s|gen=m|def=i
V\tVpp\taspect=p|trans=t|vform=c|voice=v|num=s|gen=n|def=d
V\tVpp\taspect=p|trans=t|vform=c|voice=v|num=s|gen=n|def=i
V\tVxi\ttype=aux|trans=t|mood=i|past|pers=1|num=p
V\tVxi\ttype=aux|trans=t|mood=i|past|pers=1|num=s
V\tVxi\ttype=aux|trans=t|mood=i|past|pers=2|num=p
V\tVxi\ttype=aux|trans=t|mood=i|past|pers=2|num=s
V\tVxi\ttype=aux|trans=t|mood=i|past|pers=3|num=p
V\tVxi\ttype=aux|trans=t|mood=i|past|pers=3|num=s
V\tVxi\ttype=aux|trans=t|mood=i|tense=r|pers=1|num=p
V\tVxi\ttype=aux|trans=t|mood=i|tense=r|pers=1|num=s
V\tVxi\ttype=aux|trans=t|mood=i|tense=r|pers=2|num=p
V\tVxi\ttype=aux|trans=t|mood=i|tense=r|pers=2|num=s
V\tVxi\ttype=aux|trans=t|mood=i|tense=r|pers=3|num=p
V\tVxi\ttype=aux|trans=t|mood=i|tense=r|pers=3|num=s
V\tVxi\ttype=aux|trans=t|mood=u|tense=o|pers=1|num=p
V\tVxi\ttype=aux|trans=t|mood=u|tense=o|pers=1|num=s
V\tVxi\ttype=aux|trans=t|mood=u|tense=o|pers=2|num=p
V\tVxi\ttype=aux|trans=t|mood=u|tense=o|pers=2|num=s
V\tVxi\ttype=aux|trans=t|mood=u|tense=o|pers=3|num=p
V\tVxi\ttype=aux|trans=t|mood=u|tense=o|pers=3|num=s
V\tVxi\ttype=aux|trans=t|vform=c|voice=a|past|num=p|def=i
V\tVxi\ttype=aux|trans=t|vform=c|voice=a|past|num=s|gen=f|def=i
V\tVxi\ttype=aux|trans=t|vform=c|voice=a|past|num=s|gen=m|def=i
V\tVxi\ttype=aux|trans=t|vform=c|voice=a|past|num=s|gen=n|def=i
V\tVyp\ttype=aux|aspect=p|trans=t|mood=i|tense=o|pers=3|num=s
V\tVyp\ttype=aux|aspect=p|trans=t|mood=i|tense=r|pers=1|num=p
V\tVyp\ttype=aux|aspect=p|trans=t|mood=i|tense=r|pers=1|num=s
V\tVyp\ttype=aux|aspect=p|trans=t|mood=i|tense=r|pers=2|num=p
V\tVyp\ttype=aux|aspect=p|trans=t|mood=i|tense=r|pers=2|num=s
V\tVyp\ttype=aux|aspect=p|trans=t|mood=i|tense=r|pers=3|num=p
V\tVyp\ttype=aux|aspect=p|trans=t|mood=i|tense=r|pers=3|num=s
V\tVyp\ttype=aux|aspect=p|trans=t|mood=z|pers=2|num=s
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

Lingua::Interset::Tagset::BG::Conll - Driver for the Bulgarian tagset of the CoNLL 2006 Shared Task.

=head1 VERSION

version 3.007

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::BG::Conll;
  my $driver = Lingua::Interset::Tagset::BG::Conll->new();
  my $fs = $driver->decode("N\tNC\tgender=neuter|number=sing|case=unmarked|def=indef");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('bg::conll', "N\tNC\tgender=neuter|number=sing|case=unmarked|def=indef");

=head1 DESCRIPTION

Interset driver for the Bulgarian tagset of the CoNLL 2006 Shared Task.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT. For Bulgarian,
these values are derived from the tagset of the BulTreeBank.

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
