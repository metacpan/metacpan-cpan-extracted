# ABSTRACT: Driver for the Dutch tagset of the CoNLL 2006 Shared Task (derived from the Alpino tagset).
# Copyright © 2011, 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Copyright © 2011 Zdeněk Žabokrtský <zabokrtsky@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::NL::Conll;
use strict;
use warnings;
our $VERSION = '3.014';

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
    return 'nl::conll';
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
            'Adj'  => ['pos' => 'adj'], # groot, goed, bekend, nodig, vorig
            'Adv'  => ['pos' => 'adv'], # zo, nu, dan, hier, altijd
            'Art'  => ['pos' => 'adj', 'prontype' => 'art'], # het, der, de, des, den
            'Conj' => ['pos' => 'conj'], # en, maar, of, dat, als, om
            'Int'  => ['pos' => 'int'], # ja, nee
            'Misc' => [], # sarx, the, jazz, plaats, Bevrijding ... words unknown by the tagger? In the corpus, it occurs only with the feature 'vreemd' (foreign).
            'MWU'  => [], # multi-word unit. Needs special treatment. Subpos contains the POSes. E.g. "MWU V_V" is combination of two verbs ("laat_staan").
            'N'    => ['pos' => 'noun'], # jaar, heer, land, plaats, tijd
            'Num'  => ['pos' => 'num'], # twee, drie, vier, miljoen, tien
            'Prep' => ['pos' => 'adp', 'adpostype' => 'prep'], # van, in, op, met, voor
            'Pron' => ['pos' => 'noun', 'prontype' => 'prs'], # ik, we, wij, u, je, jij, jullie, ze, zij, hij, het, ie, zijzelf
            'Punc' => ['pos' => 'punc'], # " ' : ( ) ...
            'V'    => ['pos' => 'verb'] # worden, zijn, blijven, komen, wezen
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''    => 'N',
                                                   '@' => 'Pron' }},
                       'adj'  => { 'prontype' => { ''    => { 'numtype' => { ''  => 'Adj',
                                                                             '@' => 'Num' }},
                                                   'art' => 'Art' }},
                       'num'  => 'Num',
                       'verb' => 'V',
                       'adv'  => 'Adv',
                       'adp'  => 'Prep',
                       'conj' => 'Conj',
                       'int'  => 'Int',
                       'punc' => 'Punc',
                       'sym'  => 'Punc',
                       '@'    => 'Misc' }
        }
    );
    # ADJECTIVE TYPE ####################
    $atoms{adjtype} = $self->create_atom
    (
        'surfeature' => 'adjtype',
        'decode_map' =>
        {
            # adjective type (attr and zelfst applies to numerals and pronouns too)
            # adverbially used adjective
            # Example: "goed" in "Ben je al goed opgeschoten?" = "Have you done good progress?"
            # (goed, lang, erg, snel, zeker)
            'adv'    => ['variant' => 'short', 'other' => {'synpos' => 'adv'}],
            # attributively or predicatively used adjective
            # Example: "Dat huis is groot genoeg om in te verdwalen" = "The house is big enough to get lost in"
            # (groot, goed, bekend, nodig, vorig)
            'attr'   => ['other' => {'synpos' => 'attr'}],
            # independently used adjective
            # Example: "Antwoord in vloeiend Nederlands:" = "Response in fluent Dutch:"
            # (Nederlands, Frans, rood, groen, Engels)
            'zelfst' => ['other' => {'synpos' => 'self'}]
        },
        'encode_map' =>
        {
            'other/synpos' => { 'adv'  => 'adv',
                                'attr' => 'attr',
                                'self' => 'zelfst',
                                '@'    => { 'variant' => { 'short' => 'adv',
                                                           '@'     => { 'prontype' => { 'prs' => { 'poss' => { ''  => '',
                                                                                                               '@' => { 'number' => { 'plur' => 'zelfst',
                                                                                                                                      '@'    => 'attr' }}}},
                                                                                        'rcp' => '',
                                                                                        '@'   => { 'number' => { 'plur' => 'zelfst',
                                                                                                                 '@'    => 'attr' }}}}}}}
        }
    );
    # DEGREE ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            # degree of comparison (adjectives, adverbs and indefinite numerals (veel/weinig, meer/minder, meest/minst))
            # positive (goed, lang, erg, snel, zeker)
            'stell'  => 'pos',
            # comparative (verder, later, eerder, vroeger, beter)
            'vergr'  => 'cmp',
            # superlative (best, grootst, kleinst, moeilijkst, mooist)
            'overtr' => 'sup'
        }
    );
    # ADJECTIVE FORM ####################
    # Applies also to indefinite numerals and verbal participles.
    $atoms{adjform} = $self->create_atom
    (
        'surfeature' => 'adjform',
        'decode_map' =>
        {
            'onverv'    => [], # uninflected (best, grootst, kleinst, moeilijkst, mooist)
            'vervneut'  => ['case' => 'nom'], # normal inflected form (mogelijke, ongelukkige, krachtige, denkbare, laatste)
            'vervgen'   => ['case' => 'gen'], # genitive form (bijzonders, goeds, nieuws, vreselijks, lekkerders)
            'vervmv'    => ['number' => 'plur'], # plural form (aanwezigen, religieuzen, Fransen, deskundigen, doden)
            'vervdat'   => ['case' => 'dat'], # dative form, verbs only, not found in corpus
            # comparative form of participles (occurs with "V", not with "Adj")
            # tegemoetkomender = more accommodating; overrompelender
            # vermoeider = more tired; verfijnder = more sophisticated
            'vervvergr' => ['degree' => 'cmp']
        },
        'encode_map' =>
        {
            'pos' => { 'verb' => { 'degree' => { 'cmp' => 'vervvergr',
                                                 '@'   => { 'verbform' => { 'part' => { 'number' => { 'plur' => 'vervmv',
                                                                                                      '@'    => { 'case' => { 'nom' => 'vervneut',
                                                                                                                              '@'   => 'onverv' }}}},
                                                                            '@'    => '' }}}},
                       '@'    => { 'number' => { 'plur' => 'vervmv',
                                                 '@'    => { 'case' => { 'nom' => 'vervneut',
                                                                         'gen' => 'vervgen',
                                                                         'dat' => 'vervdat',
                                                                         # The value 'onverv' occurs also with adverbs but only with those that have degree of comparison.
                                                                         # With adjectives the degree is also always present, hence we can check on it.
                                                                         # With numerals it occurs even without the degree.
                                                                         '@'   => { 'numtype' => { ''  => { 'degree' => { ''  => '',
                                                                                                                          '@' => 'onverv' }},
                                                                                                   '@' => 'onverv' }}}}}}}
        }
    );
    # ADVERB TYPE ####################
    $atoms{advtype} = $self->create_atom
    (
        'surfeature' => 'advtype',
        'decode_map' =>
        {
            # normal (zo, nu, dan, hier, altijd)
            # gew|aanw: zo = so; nu = now; dan = then; hier = here; altijd = always
            # gew|betr: hoe = how; waar = where; wanneer = when; waarom = why; hoeverre = to what extent
            # gew|er: er = there (existential: er is = there is)
            # gew|onbep: nooit = never; ooit = ever; ergens = somewhere; overal = everywhere; elders = elsewhere
            # gew|vrag: waar = where; vanwaar = where from; alwaar = where to
            # gew|geenfunc|stell|onverv: niet = not; nog = still; ook = also; wel = well; al = already
            # gew|geenfunc|vergr|onverv: meer = more; vaker = more often; dichter = more densely; dichterbij = closer
            # gew|geenfunc|overtr|onverv: meest = most
            'gew'     => ['other' => {'advtype' => 'gew'}],
            # pronominal (daar, daarna, waarin, waarbij)
            # pron|aanw: daar = there; daarna = then; daardoor = thereby; daarmee = therewith; daarop = thereon
            # pron|betr: waar = where; waaruit = whence; waaraan = whereat
            # pron|er: er = there (existential: er is = there is)
            # pron|onbep: ervan = whose; erop = on; erin; erover; ervoor = therefore
            # pron|vrag: waarin = wherein; waarbij = whereby; waarmee; waarop = whereupon; waardoor = whereby
            'pron'    => ['other' => {'advtype' => 'pron'}],
            # adverbial or prepositional part of separable (phrasal) verb (uit, op, aan, af, in)
            'deelv'   => ['parttype' => 'vbp', 'other' => {'advtype' => 'deelv'}],
            # prepositional part of separed pronominal adverb (van, voor, aan, op, mee)
            'deeladv' => ['parttype' => 'vbp', 'other' => {'advtype' => 'deeladv'}]
        },
        'encode_map' =>
        {
            'other/advtype' => { 'gew'     => 'gew',
                                 'pron'    => 'pron',
                                 'deelv'   => 'deelv',
                                 'deeladv' => 'deeladv',
                                 '@'       => { 'parttype' => { 'vbp' => 'deelv',
                                                                '@'   => { 'prontype' => { ''  => 'gew',
                                                                                           '@' => 'pron' }}}}}
        }
    );
    # FUNCTION OF NORMAL AND PRONOMINAL ADVERBS ####################
    $atoms{function} = $self->create_atom
    (
        'surfeature' => 'function',
        'decode_map' =>
        {
            'geenfunc' => [], # no function information (meest, niet, nog, ook, wel)
            'betr'     => ['prontype' => 'rel'], # relative pronoun or adverb (welke, die, dat, wat, wie, hoe, waar)
            'vrag'     => ['prontype' => 'int'], # interrogative pronoun or adverb (wat, wie, welke, welk, waar, dat, vanwaar)
            'aanw'     => ['prontype' => 'dem'], # demonstrative pronoun or adverb (deze, dit, die, dat, zo, nu, dan, daar, daardoor)
            'onbep'    => ['prontype' => 'ind'], # indefinite pronoun, numeral or adverb (geen, andere, alle, enkele, wat, minst, meest, nooit, ooit)
            'er'       => ['advtype'  => 'ex'] # the adverb 'er' (existential 'there'?)
        },
        'encode_map' =>
        {
            'prontype' => { 'rel' => 'betr',
                            'int' => 'vrag',
                            'dem' => 'aanw',
                            'ind' => 'onbep',
                            '@'   => { 'advtype' => { 'ex' => 'er',
                                                      '@'  => { 'parttype' => { 'vbp' => '',
                                                                                '@'   => 'geenfunc' }}}}}
        }
    );
    # DEFINITENESS ####################
    $atoms{definite} = $self->create_simple_atom
    (
        'intfeature' => 'definite',
        'simple_decode_map' =>
        {
            'bep'   => 'def', # (het, der, de, des, den)
            'onbep' => 'ind'  # (een)
        }
    );
    # GENDER OF ARTICLES ####################
    $atoms{gender} = $self->create_atom
    (
        'surfeature' => 'gender',
        'decode_map' =>
        {
            'zijd'         => ['gender' => 'com'], # non-neuter (den)
            'zijdofmv'     => [], # non-neuter gender or plural (de, der)
            'onzijd'       => ['gender' => 'neut'], # neuter (het)
            'zijdofonzijd' => ['number' => 'sing'], # both genders possible (des, een)
        },
        'encode_map' =>
        {
            'gender' => { 'com'  => 'zijd',
                          'neut' => 'onzijd',
                          '@'    => { 'number' => { 'sing' => 'zijdofonzijd',
                                                    '@'    => 'zijdofmv' }}}
        }
    );
    # CASE OF ARTICLES, PRONOUNS AND NOUNS ####################
    $atoms{case} = $self->create_atom
    (
        'surfeature' => 'case',
        'decode_map' =>
        {
            'neut'     => [], # no case (i.e. nominative or a word that does not take case markings) (het, de, een)
            'nom'      => ['case' => 'nom'], # nominative (only pronouns: ik, we, wij, u, je, jij, jullie, ze, zij, hij, het, ie, zijzelf)
            'gen'      => ['case' => 'gen'], # genitive (der, des)
            'dat'      => ['case' => 'dat'], # dative (den)
            'datofacc' => ['case' => 'dat|acc'], # dative or accusative (only pronouns: me, mij, ons, je, jou, jullie, ze, hem, haar, het, haarzelf, hen, hun)
            'acc'      => ['case' => 'acc'], # accusative (not found in the corpus, there is only 'datofacc')
        },
        'encode_map' =>
        {
            'case' => { 'nom'     => 'nom',
                        'gen'     => 'gen',
                        'acc|dat' => 'datofacc',
                        'dat'     => 'dat',
                        'acc'     => 'acc',
                        '@'       => { 'reflex' => { 'yes' => '',
                                                     '@'      => 'neut' }}}
        }
    );
    # CONJUNCTION TYPE ####################
    $atoms{conjtype} = $self->create_atom
    (
        'surfeature' => 'conjtype',
        'decode_map' =>
        {
            'neven' => ['conjtype' => 'coor'], # coordinating (en, maar, of)
            'onder' => ['conjtype' => 'sub'] # subordinating (dat, als, dan, om, zonder, door)
        },
        'encode_map' =>
        {
            'conjtype' => { 'coor' => 'neven',
                            'sub'  => 'onder' }
        }
    );
    # SUBORDINATING CONJUNCTION TYPE ####################
    $atoms{sconjtype} = $self->create_atom
    (
        'surfeature' => 'sconjtype',
        'decode_map' =>
        {
            # followed by a finite clause (dat, als, dan, omdat)
            # Example: "ik hoop dat we tot een compromis kunnen komen" = "I hope that we can come to a compromise"
            'metfin' => ['other' => {'sconjtype' => 'fin'}],
            # followed by an infinite clause (om, zonder, door, teneinde)
            # Example: "Het was voor ons de kans om een ander Colombia te laten zien." = "It was for us a chance to show a different Colombia."
            'metinf' => ['other' => {'sconjtype' => 'inf'}]
        },
        'encode_map' =>
        {
            'other/sconjtype' => { 'inf' => 'metinf',
                                   'fin' => 'metfin',
                                   # This feature is required for all subordinating conjunctions.
                                   '@'   => { 'conjtype' => { 'sub' => 'metfin' }}}
        }
    );
    # NOUN TYPE ####################
    $atoms{nountype} = $self->create_simple_atom
    (
        'intfeature' => 'nountype',
        'simple_decode_map' =>
        {
            'soort' => 'com', # common noun is the default type of noun (jaar, heer, land, plaats, tijd)
            'eigen' => 'prop' # proper noun (Nederland, Amsterdam, zaterdag, Groningen, Rotterdam)
        }
    );
    # NUMBER ####################
    $atoms{number} = $self->create_atom
    (
        'surfeature' => 'number',
        'decode_map' =>
        {
            # enkelvoud (jaar, heer, land, plaats, tijd)
            'ev'     => ['number' => 'sing'],
            # meervoud (mensen, kinderen, jaren, problemen, landen)
            'mv'     => ['number' => 'plur'],
            # singular undistinguishable from plural (only pronouns: ze, zij, zich, zichzelf)
            'evofmv' => ['number' => 'sing|plur']
        },
        'encode_map' =>
        {
            'number' => { 'plur|sing' => 'evofmv',
                          'sing'      => 'ev',
                          'plur'      => 'mv' }
        }
    );
    # NUMERAL TYPE ####################
    $atoms{numtype} = $self->create_atom
    (
        'surfeature' => 'numtype',
        'decode_map' =>
        {
            'hoofd' => ['pos' => 'num', 'numtype' => 'card'], # hoofdtelwoord (twee, 1969, beider, minst, veel)
            'rang'  => ['pos' => 'adj', 'numtype' => 'ord'], # rangtelwoord (eerste, tweede, derde, vierde, vijfde)
        },
        'encode_map' =>
        {
            'numtype' => { 'card' => 'hoofd',
                           'ord'  => 'rang' }
        }
    );
    # MISCELLANEOUS TYPE ####################
    $atoms{misctype} = $self->create_atom
    (
        'surfeature' => 'misctype',
        'decode_map' =>
        {
            'afkort'  => ['abbr' => 'yes'], # abbreviation
            'vreemd'  => ['foreign' => 'yes'], # foreign expression
            'symbool' => ['pos' => 'sym'], # symbol not included in Punc
        },
        'encode_map' =>
        {
            'pos' => { 'sym' => 'symbool',
                       '@'   => { 'foreign' => { 'yes' => 'vreemd',
                                                 '@'       => { 'abbr' => { 'yes' => 'afkort' }}}}}
        }
    );
    # ADPOSITION TYPE ####################
    $atoms{adpostype} = $self->create_atom
    (
        'surfeature' => 'adpostype',
        'decode_map' =>
        {
            'voor'    => ['adpostype' => 'prep'], # preposition (voorzetsel) (van, in, op, met, voor)
            'achter'  => ['adpostype' => 'post'], # postposition (achterzetsel) (in, incluis, op)
            'comb'    => ['adpostype' => 'circ'], # second part of combined (split) preposition (toe, heen, af, in, uit) [van het begin af / from the beginning on: van/voor, af/comb]
            'voorinf' => ['parttype' => 'inf'] # infinitive marker (te)
        },
        'encode_map' =>
        {
            'parttype' => { 'inf' => 'voorinf',
                            '@'   => { 'adpostype' => { 'prep' => 'voor',
                                                        'post' => 'achter',
                                                        'circ' => 'comb' }}}
        }
    );
    # PRONOUN TYPE ####################
    $atoms{prontype} = $self->create_atom
    (
        'surfeature' => 'prontype',
        'decode_map' =>
        {
            'per'   => ['prontype' => 'prs'], # persoonlijk (me, ik, ons, we, je, u, jullie, ze, hem, hij, hen)
            'bez'   => ['prontype' => 'prs', 'poss' => 'yes'], # beztittelijk (mijn, onze, je, jullie, zijner, zijn, hun)
            'ref'   => ['prontype' => 'prs', 'reflex' => 'yes'], # reflexief (me, mezelf, mij, ons, onszelf, je, jezelf, zich, zichzelf)
            'rec'   => ['prontype' => 'rcp'], # reciprook (elkaar, elkaars)
            'aanw'  => ['prontype' => 'dem'], # aanwijzend (deze, dit, die, dat)
            'betr'  => ['prontype' => 'rel'], # betrekkelijk (welk, die, dat, wat, wie)
            'vrag'  => ['prontype' => 'int'], # vragend (wie, wat, welke, welk)
            'onbep' => ['prontype' => 'ind|neg|tot'] # onbepaald (geen, andere, alle, enkele, wat)
        },
        'encode_map' =>
        {
            'prontype' => { 'prs' => { 'poss' => { 'yes' => 'bez',
                                                   '@'    => { 'reflex' => { 'yes' => 'ref',
                                                                             '@'      => 'per' }}}},
                            'rcp' => 'rec',
                            'dem' => 'aanw',
                            'rel' => 'betr',
                            'int' => 'vrag',
                            'ind' => 'onbep',
                            'neg' => 'onbep',
                            'tot' => 'onbep' }
        }
    );
    # SPECIFIC PRONOUN ####################
    $atoms{pronoun} = $self->create_atom
    (
        'surfeature' => 'pronoun',
        'decode_map' =>
        {
            # eigen = own
            'weigen' => ['other' => {'pronoun' => 'eigen'}],
            # zelf = self
            'wzelf'  => ['other' => {'pronoun' => 'zelf'}]
        },
        'encode_map' =>
        {
            'other/pronoun' => { 'eigen' => 'weigen',
                                 'zelf'  => 'wzelf' }
        }
    );
    # PERSON ####################
    $atoms{person} = $self->create_atom
    (
        'surfeature' => 'person',
        'decode_map' =>
        {
            '1' => ['person' => '1'], # (mijn, onze, ons, me, mij, ik, we, mezelf, onszelf)
            '2' => ['person' => '2'], # (je, uw, jouw, jullie, jou, u, je, jij, jezelf)
            '3' => ['person' => '3'], # (zijner, zijn, haar, zijnen, zijne, hun, ze, zij, hem, het, hij, ie, zijzelf, zich, zichzelf)
            '1of2of3' => [], # person not marked; applies only to verbs in imperfect past (was, werd, heette; waren, werden, bleven) and plural imperfect present (zijn, worden, blijven)
        },
        'encode_map' =>
        {
            'person' => { '1' => '1',
                          '2' => '2',
                          '3' => '3',
                          '@' => { 'pos' => { 'verb' => { 'mood' => { 'ind' => '1of2of3' }}}}}
        }
    );
    # PUNCTUATION TYPE ####################
    $atoms{punctype} = $self->create_atom
    (
        'surfeature' => 'punctype',
        'decode_map' =>
        {
            'aanhaaldubb' => ['punctype' => 'quot'], # "
            'aanhaalenk'  => ['punctype' => 'quot', 'other' => {'punctype' => 'singlequot'}], # '
            'dubbpunt'    => ['punctype' => 'colo'], # :
            'en'          => ['pos' => 'sym', 'other' => {'symbol' => 'and'}], # &
            'gedstreep'   => ['punctype' => 'dash'], # -
            'haakopen'    => ['punctype' => 'brck', 'puncside' => 'ini'], # (
            'haaksluit'   => ['punctype' => 'brck', 'puncside' => 'fin'], # )
            'hellip'      => ['punctype' => 'peri', 'other' => {'punctype' => 'ellipsis'}], # ...
            'isgelijk'    => ['pos' => 'sym', 'other' => {'symbol' => 'equals'}], # =
            'komma'       => ['punctype' => 'comm'], # ,
            'liggstreep'  => ['pos' => 'sym', 'other' => {'symbol' => 'underscore'}], # -, _
            'maal'        => ['pos' => 'sym', 'other' => {'symbol' => 'times'}], # x
            'plus'        => ['pos' => 'sym', 'other' => {'symbol' => 'plus'}], # +
            'punt'        => ['punctype' => 'peri'], # .
            'puntkomma'   => ['punctype' => 'semi'], # ;
            'schuinstreep'=> ['pos' => 'sym', 'other' => {'symbol' => 'slash'}], # /
            'uitroep'     => ['punctype' => 'excl'], # !
            'vraag'       => ['punctype' => 'qest'], # ?
        },
        'encode_map' =>
        {
            'punctype' => { 'quot' => { 'other/punctype' => { 'singlequot' => 'aanhaalenk',
                                                              '@'          => 'aanhaaldubb' }},
                            'colo' => 'dubbpunt',
                            'dash' => 'gedstreep',
                            'brck' => { 'puncside' => { 'ini' => 'haakopen',
                                                        '@'   => 'haaksluit' }},
                            'comm' => 'komma',
                            'peri' => { 'other/punctype' => { 'ellipsis' => 'hellip',
                                                              '@'        => 'punt' }},
                            'semi' => 'puntkomma',
                            'excl' => 'uitroep',
                            'qest' => 'vraag',
                            '@'    => { 'other/symbol' => { 'and'        => 'en',
                                                            'equals'     => 'isgelijk',
                                                            'underscore' => 'liggstreep',
                                                            'times'      => 'maal',
                                                            'plus'       => 'plus',
                                                            'slash'      => 'schuinstreep',
                                                            '@'          => 'isgelijk' }}}
        }
    );
    # VERB TYPE ####################
    $atoms{verbtype} = $self->create_atom
    (
        'surfeature' => 'verbtype',
        'decode_map' =>
        {
            'trans'      => ['subcat' => 'tran'], # transitive (maken, zien, doen, nemen, geven)
            'refl'       => ['reflex' => 'yes'], # reflexive (verzetten, ontwikkelen, voelen, optrekken, concentreren)
            'intrans'    => ['subcat' => 'intr'], # intransitive (komen, gaan, staan, vertrekken, spelen)
            'hulp'       => ['verbtype' => 'mod'], # auxiliary / modal (kunnen, moeten, hebben, gaan, laten)
            'hulpofkopp' => ['verbtype' => 'aux|cop'] # auxiliary or copula (worden, zijn, blijven, komen, wezen)
        },
        'encode_map' =>
        {
            'verbtype' => { 'aux' => 'hulpofkopp',
                            'cop' => 'hulpofkopp',
                            'mod' => 'hulp',
                            '@'   => { 'reflex' => { 'yes' => 'refl',
                                                     '@'      => { 'subcat' => { 'tran' => 'trans',
                                                                                 'intr' => 'intrans' }}}}}
        }
    );
    # VERB FORM, MOOD, TENSE AND ASPECT ####################
    $atoms{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            'ott'    => ['verbform' => 'fin', 'mood' => 'ind', 'aspect' => 'imp', 'tense' => 'pres'], # (komt, heet, gaat, ligt, staat)
            'ovt'    => ['verbform' => 'fin', 'mood' => 'ind', 'aspect' => 'imp', 'tense' => 'past'], # (kwam, ging, stond, viel, won)
            'tegdw'  => ['verbform' => 'part', 'tense' => 'pres'], # (volgend, verrassend, bevredigend, vervelend, aanvallend)
            'verldw' => ['verbform' => 'part', 'tense' => 'past'], # (afgelopen, gekomen, gegaan, gebeurd, begonnen)
            'inf'    => ['verbform' => 'inf'], # (komen, gaan, staan, vertrekken, spelen)
            'conj'   => ['verbform' => 'fin', 'mood' => 'sub'], # (leve, ware, inslape, oordele, zegge)
            'imp'    => ['verbform' => 'fin', 'mood' => 'imp'], # (kijk, kom, ga, denk, wacht)
        },
        'encode_map' =>
        {
            'verbform' => { 'inf'  => 'inf',
                            'fin'  => { 'mood' => { 'ind' => { 'tense' => { 'pres' => 'ott',
                                                                            'past' => 'ovt' }},
                                                    'sub' => 'conj',
                                                    'imp' => 'imp' }},
                            'part' => { 'tense' => { 'pres' => 'tegdw',
                                                     'past' => 'verldw' }}}
        }
    );
    # SUBSTANTIVAL USAGE OF INFINITIVE ####################
    $atoms{subst} = $self->create_atom
    (
        'surfeature' => 'subst',
        'decode_map' =>
        {
            # (worden, zijn, optreden, streven, dringen, maken, bereiken)
            'subst' => ['other' => {'infinitive' => 'subst'}]
        },
        'encode_map' =>
        {
            'other/infinitive' => { 'subst' => 'subst' }
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
    my @features = ('pos', 'adjtype', 'degree', 'adjform', 'advtype', 'function', 'definite', 'gender', 'case', 'conjtype', 'sconjtype', 'nountype', 'number',
                    'numtype', 'misctype', 'adpostype', 'prontype', 'pronoun', 'person', 'punctype', 'verbtype', 'verbform', 'subst');
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
        'Adj'   => ['adjtype', 'degree', 'adjform'],
        'Adv'   => ['advtype', 'function', 'degree', 'adjform'],
        'Art'   => ['definite', 'gender', 'case'],
        'Conj'  => ['conjtype', 'sconjtype'],
        'Misc'  => ['misctype'],
        'N'     => ['nountype', 'number', 'case'],
        'Num'   => ['numtype', 'definite', 'prontype', 'adjtype', 'degree', 'adjform'],
        'Prep'  => ['adpostype'],
        'Pron'  => ['prontype', 'person', 'number', 'case', 'adjtype', 'pronoun'],
        'Punc'  => ['punctype'],
        'V'     => ['verbtype', 'verbform', 'subst', 'person', 'number'],
        'Vpart' => ['verbtype', 'verbform', 'adjform']
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
    $fs->set_tagset('nl::conll');
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
    # The feature 'onbep' can mean indefinite pronoun or indefinite article.
    # If it is article, we want prontype=art, not prontype=ind.
    if($tag =~ m/^Art.*onbep/)
    {
        $fs->set('prontype', 'art');
        $fs->set('definite', 'ind');
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
    my $fpos = $subpos;
    $fpos = 'Vpart' if($fpos eq 'V' && $fs->is_participle());
    my $feature_names = $self->get_feature_names($fpos);
    my $pos = $subpos;
    my $value_only = 1;
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names, $value_only);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus, 745 distinct tags found.
# MWU (multi-word-unit) tags were removed because they are sequences of normal
# tags and we cannot support them.
# Total 198 tags survived.
# Total 208 tags after adding missing tags (without the 'other' feature etc.)
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
Adj	Adj	adv|stell|onverv
Adj	Adj	adv|stell|vervneut
Adj	Adj	adv|vergr|onverv
Adj	Adj	adv|vergr|vervneut
Adj	Adj	attr|overtr|onverv
Adj	Adj	attr|overtr|vervneut
Adj	Adj	attr|stell|onverv
Adj	Adj	attr|stell|vervgen
Adj	Adj	attr|stell|vervneut
Adj	Adj	attr|vergr|onverv
Adj	Adj	attr|vergr|vervgen
Adj	Adj	attr|vergr|vervneut
Adj	Adj	zelfst|overtr|vervneut
Adj	Adj	zelfst|stell|onverv
Adj	Adj	zelfst|stell|vervmv
Adj	Adj	zelfst|stell|vervneut
Adj	Adj	zelfst|vergr|vervneut
Adv	Adv	deeladv
Adv	Adv	deelv
Adv	Adv	gew|aanw
Adv	Adv	gew|betr
Adv	Adv	gew|er
Adv	Adv	gew|geenfunc|overtr|onverv
Adv	Adv	gew|geenfunc|stell|onverv
Adv	Adv	gew|geenfunc|vergr|onverv
Adv	Adv	gew|onbep
Adv	Adv	gew|vrag
Adv	Adv	pron|aanw
Adv	Adv	pron|betr
Adv	Adv	pron|er
Adv	Adv	pron|onbep
Adv	Adv	pron|vrag
Art	Art	bep|onzijd|neut
Art	Art	bep|zijdofmv|gen
Art	Art	bep|zijdofmv|neut
Art	Art	bep|zijdofonzijd|gen
Art	Art	bep|zijd|dat
Art	Art	onbep|zijdofonzijd|neut
Conj	Conj	neven
Conj	Conj	onder|metfin
Conj	Conj	onder|metinf
Int	Int	_
Misc	Misc	vreemd
N	N	eigen|ev|gen
N	N	eigen|ev|neut
N	N	eigen|mv|neut
N	N	soort|ev|dat
N	N	soort|ev|gen
N	N	soort|ev|neut
N	N	soort|mv|neut
Num	Num	hoofd|bep|attr|onverv
Num	Num	hoofd|bep|attr|vervgen
Num	Num	hoofd|bep|zelfst|onverv
Num	Num	hoofd|bep|zelfst|vervgen
Num	Num	hoofd|bep|zelfst|vervmv
Num	Num	hoofd|onbep|attr|overtr|onverv
Num	Num	hoofd|onbep|attr|overtr|vervneut
Num	Num	hoofd|onbep|attr|stell|onverv
Num	Num	hoofd|onbep|attr|stell|vervneut
Num	Num	hoofd|onbep|attr|vergr|onverv
Num	Num	hoofd|onbep|attr|vergr|vervneut
Num	Num	hoofd|onbep|zelfst|overtr|onverv
Num	Num	hoofd|onbep|zelfst|overtr|vervmv
Num	Num	hoofd|onbep|zelfst|overtr|vervneut
Num	Num	hoofd|onbep|zelfst|stell|onverv
Num	Num	hoofd|onbep|zelfst|stell|vervmv
Num	Num	hoofd|onbep|zelfst|stell|vervneut
Num	Num	hoofd|onbep|zelfst|vergr|onverv
Num	Num	hoofd|onbep|zelfst|vergr|vervmv
Num	Num	hoofd|onbep|zelfst|vergr|vervneut
Num	Num	rang|bep|attr|onverv
Num	Num	rang|bep|zelfst|onverv
Prep	Prep	achter
Prep	Prep	comb
Prep	Prep	voor
Prep	Prep	voorinf
Pron	Pron	aanw|dat|attr
Pron	Pron	aanw|gen|attr
Pron	Pron	aanw|neut|attr
Pron	Pron	aanw|neut|attr|weigen
Pron	Pron	aanw|neut|attr|wzelf
Pron	Pron	aanw|neut|zelfst
Pron	Pron	betr|gen|attr
Pron	Pron	betr|gen|zelfst
Pron	Pron	betr|neut|attr
Pron	Pron	betr|neut|zelfst
Pron	Pron	bez|1|ev|neut|attr
Pron	Pron	bez|1|ev|neut|zelfst
Pron	Pron	bez|1|mv|neut|attr
Pron	Pron	bez|1|mv|neut|zelfst
Pron	Pron	bez|2|ev|neut|attr
Pron	Pron	bez|2|ev|neut|zelfst
Pron	Pron	bez|2|mv|neut|attr
Pron	Pron	bez|2|mv|neut|zelfst
Pron	Pron	bez|3|ev|gen|attr
Pron	Pron	bez|3|ev|gen|zelfst
Pron	Pron	bez|3|ev|neut|attr
Pron	Pron	bez|3|ev|neut|zelfst
Pron	Pron	bez|3|mv|neut|attr
Pron	Pron	bez|3|mv|neut|zelfst
Pron	Pron	onbep|gen|attr
Pron	Pron	onbep|gen|zelfst
Pron	Pron	onbep|neut|attr
Pron	Pron	onbep|neut|zelfst
Pron	Pron	per|1|ev|datofacc
Pron	Pron	per|1|ev|nom
Pron	Pron	per|1|mv|datofacc
Pron	Pron	per|1|mv|nom
Pron	Pron	per|2|ev|datofacc
Pron	Pron	per|2|ev|nom
Pron	Pron	per|2|mv|datofacc
Pron	Pron	per|2|mv|nom
Pron	Pron	per|3|evofmv|datofacc
Pron	Pron	per|3|evofmv|nom
Pron	Pron	per|3|ev|datofacc
Pron	Pron	per|3|ev|nom
Pron	Pron	per|3|mv|datofacc
Pron	Pron	per|3|mv|nom
Pron	Pron	rec|gen
Pron	Pron	rec|neut
Pron	Pron	ref|1|ev
Pron	Pron	ref|1|mv
Pron	Pron	ref|2|ev
Pron	Pron	ref|3|evofmv
Pron	Pron	vrag|neut|attr
Pron	Pron	vrag|neut|zelfst
Punc	Punc	aanhaaldubb
Punc	Punc	aanhaalenk
Punc	Punc	dubbpunt
Punc    Punc    en
Punc	Punc	haakopen
Punc	Punc	haaksluit
Punc	Punc	hellip
Punc	Punc	isgelijk
Punc	Punc	komma
Punc	Punc	liggstreep
Punc	Punc	maal
Punc    Punc    plus
Punc	Punc	punt
Punc	Punc	puntkomma
Punc	Punc	schuinstreep
Punc	Punc	uitroep
Punc	Punc	vraag
V	V	hulpofkopp|conj
V	V	hulpofkopp|imp
V	V	hulpofkopp|inf
V	V	hulpofkopp|inf|subst
V	V	hulpofkopp|ott|1of2of3|mv
V	V	hulpofkopp|ott|1|ev
V	V	hulpofkopp|ott|2|ev
V	V	hulpofkopp|ott|3|ev
V	V	hulpofkopp|ovt|1of2of3|ev
V	V	hulpofkopp|ovt|1of2of3|mv
V	V	hulpofkopp|tegdw|vervneut
V	V	hulpofkopp|verldw|onverv
V	V	hulp|conj
V	V	hulp|inf
V	V	hulp|ott|1of2of3|mv
V	V	hulp|ott|1|ev
V	V	hulp|ott|2|ev
V	V	hulp|ott|3|ev
V	V	hulp|ovt|1of2of3|ev
V	V	hulp|ovt|1of2of3|mv
V	V	hulp|verldw|onverv
V	V	intrans|conj
V	V	intrans|imp
V	V	intrans|inf
V	V	intrans|inf|subst
V	V	intrans|ott|1of2of3|mv
V	V	intrans|ott|1|ev
V	V	intrans|ott|2|ev
V	V	intrans|ott|3|ev
V	V	intrans|ovt|1of2of3|ev
V	V	intrans|ovt|1of2of3|mv
V	V	intrans|tegdw|onverv
V	V	intrans|tegdw|vervmv
V	V	intrans|tegdw|vervneut
V	V	intrans|tegdw|vervvergr
V	V	intrans|verldw|onverv
V	V	intrans|verldw|vervmv
V	V	intrans|verldw|vervneut
V	V	refl|imp
V	V	refl|inf
V	V	refl|inf|subst
V	V	refl|ott|1of2of3|mv
V	V	refl|ott|1|ev
V	V	refl|ott|2|ev
V	V	refl|ott|3|ev
V	V	refl|ovt|1of2of3|ev
V	V	refl|ovt|1of2of3|mv
V	V	refl|tegdw|vervneut
V	V	refl|verldw|onverv
V	V	trans|conj
V	V	trans|imp
V	V	trans|inf
V	V	trans|inf|subst
V	V	trans|ott|1of2of3|mv
V	V	trans|ott|1|ev
V	V	trans|ott|2|ev
V	V	trans|ott|3|ev
V	V	trans|ovt|1of2of3|ev
V	V	trans|ovt|1of2of3|mv
V	V	trans|tegdw|onverv
V	V	trans|tegdw|vervneut
V	V	trans|verldw|onverv
V	V	trans|verldw|vervmv
V	V	trans|verldw|vervneut
V	V	trans|verldw|vervvergr
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

Lingua::Interset::Tagset::NL::Conll - Driver for the Dutch tagset of the CoNLL 2006 Shared Task (derived from the Alpino tagset).

=head1 VERSION

version 3.014

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::NL::Conll;
  my $driver = Lingua::Interset::Tagset::NL::Conll->new();
  my $fs = $driver->decode("N\tN\tsoort|ev|neut");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('nl::conll', "N\tN\tsoort|ev|neut");

=head1 DESCRIPTION

Interset driver for the Dutch tagset of the CoNLL 2006 Shared Task.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT. For Dutch,
these values are derived from the tagset of the Alpino treebank.

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
