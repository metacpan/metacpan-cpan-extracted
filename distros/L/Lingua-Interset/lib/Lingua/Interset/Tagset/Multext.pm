# ABSTRACT: Common code for drivers of tagsets of the Multext-EAST project.
# Copyright © 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::Multext;
use strict;
use warnings;
our $VERSION = '3.016';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset';



has 'atoms'       => ( isa => 'HashRef', is => 'ro', builder => '_create_atoms',       lazy => 1 );
has 'feature_map' => ( isa => 'HashRef', is => 'ro', builder => '_create_feature_map', lazy => 1 );
has 'determiners' => ( isa => 'Bool',    is => 'ro', default => undef );



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
            # noun
            # examples [cs]: pán, hrad, žena, růže, město, moře
            # examples [ro]: număr, oraș, loc, punct, protocol
            'N' => ['pos' => 'noun'],
            # adjective
            # examples [cs]: mladý, jarní
            # examples [ro]: național, român, nou, internațional, bun
            'A' => ['pos' => 'adj'],
            # Multext tagsets of Slavic languages do not distinguish pronouns from determiners. Romanian does.
            # We do not want to bias here towards Slavic languages, hence we distinguish the two (sub-)classes.
            # pronoun
            # examples [cs]: já, ty, on, ona, ono, my, vy, oni, ony
            # examples [ro]: eu, tu, el, ea, noi, voi, ei, ele
            'P' => ['pos' => 'noun', 'prontype' => 'prn'],
            # determiner (but not article)
            # examples [ro]: meu, lui, acest, acel, mult
            'D' => ['pos' => 'adj', 'prontype' => 'prn'],
            # article
            # examples [ro]: un, o (indefinite); -ul, -a (definite affix); cel, cea, cei, cele (demonstrative); al, a, ai, ale (possessive)
            ###!!! Since there are demonstrative articles and we have to distinguish them from demonstrative determiners, we must set 'other/prontype'.
            'T' => ['pos' => 'adj', 'prontype' => 'art', 'other' => {'prontype' => 'art'}],
            # numeral
            # examples [cs]: jeden, dva, tři, čtyři, pět, šest, sedm, osm, devět, deset
            # examples [ro]: doi, trei, patru, cinci, șase, șapte, opt, nouă, zece
            'M' => ['pos' => 'num'],
            # entity; used in [ro]; not documented at the Multext-East website
            # used mostly for numbers expressed in digits, not denoting quantity (apartament 3)
            # examples: 1916, miliarde_de_lei, 58_%, 3, 99-06, mg
            # Ed = a few abbreviations of names, usually just 1 occurrence: mg, A., nr., U.E., N.
            # Eii = interval, only two occurrences: 99-06, 1908-1909
            # Eni = number (usually) written using digits: 3, 20, 50, 2, 24
            #       These numbers do not denote quantity. They are used as references: "figura 3", "apartament 3".
            # Enr = number, only two occurrences: 58_%, 1,4
            # Eqy = only two occurrences: miliarde_de_lei, 2_000_lei
            # Etd = time or date: 1916, 1923, 2005, 1928, 1_martie
            'E' => ['pos' => 'num', 'nountype' => 'prop'],
            # verb
            # examples [cs]: nese, bere, maže, peče, umře, tiskne, mine, začne, kryje, kupuje, prosí, trpí, sází, dělá
            # examples [ro]: poate, este, face, e, devine
            'V' => ['pos' => 'verb'],
            # adverb
            # examples [cs]: kde, kam, kdy, jak, dnes, vesele
            # examples [ro]: astfel, încă, doar, atât, bine
            'R' => ['pos' => 'adv'],
            # adposition
            # examples [cs]: v, pod, k
            # examples [ro]: de, pe, la, cu, în
            'S' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # conjunction
            # examples [cs]: a, i, ani, nebo, ale, avšak
            # examples [ro]: și, sau, dar, însă, că
            'C' => ['pos' => 'conj'],
            # particle
            # examples [cs]: ať, kéž, nechť
            # examples [ro]: a, să, nu
            'Q' => ['pos' => 'part'],
            # interjection
            # examples [cs]: haf, bum, bác
            # examples [ro]: vai, bravo, na
            'I' => ['pos' => 'int'],
            # abbreviation
            # examples [cs]: atd., apod.
            # examples [ro]: mp, km, etc.
            'Y' => ['abbr' => 'yes'],
            # punctuation
            # examples: , .
            'Z' => ['pos' => 'punc'],
            # residual
            'X' => []
        },
        # Some Multext-East tagsets (e.g. most Slavic languages) lack articles and determiners (the latter exist but are included in pronouns).
        'encode_map' => $self->determiners() ?
        {
            'abbr' => { 'yes' => 'Y',
                        '@'    => { 'numtype' => { ''  => { 'pos' => { 'noun' => { 'prontype' => { ''  => 'N',
                                                                                                   '@' => 'P' }},
                                                                       'adj'  => { 'prontype' => { ''    => 'A',
                                                                                                   'art' => 'T',
                                                                                                   '@'   => { 'other/prontype' => { 'art' => 'T',
                                                                                                                                    '@'   => { 'person' => { ''  => 'T',
                                                                                                                                                             '@' => 'D' }}}}}},
                                                                       'num'  => { 'nountype' => { 'prop' => 'E',
                                                                                                   '@'    => 'M' }},
                                                                       'verb' => 'V',
                                                                       'adv'  => 'R',
                                                                       'adp'  => 'S',
                                                                       'conj' => 'C',
                                                                       'part' => 'Q',
                                                                       'int'  => 'I',
                                                                       'punc' => 'Z',
                                                                       '@'    => 'X' }},
                                                   '@' => 'M' }}}
        }
        :
        {
            'abbr' => { 'yes' => 'Y',
                        '@'    => { 'numtype' => { ''  => { 'pos' => { 'noun' => { 'prontype' => { ''  => 'N',
                                                                                                   '@' => 'P' }},
                                                                       'adj'  => { 'prontype' => { ''  => 'A',
                                                                                                   '@' => 'P' }},
                                                                       'num'  => 'M',
                                                                       'verb' => 'V',
                                                                       'adv'  => 'R',
                                                                       'adp'  => 'S',
                                                                       'conj' => 'C',
                                                                       'part' => 'Q',
                                                                       'int'  => 'I',
                                                                       'punc' => 'Z',
                                                                       '@'    => 'X' }},
                                                   '@' => 'M' }}}
        }
    );
    # NOUNTYPE ####################
    $atoms{nountype} = $self->create_simple_atom
    (
        'intfeature' => 'nountype',
        'simple_decode_map' =>
        {
            'c' => 'com',
            'p' => 'prop'
        }
    );
    # ADJTYPE ####################
    $atoms{adjtype} = $self->create_atom
    (
        'surfeature' => 'adjtype',
        'decode_map' =>
        {
            # qualificative adjective
            # examples: mladý, jarní
            'f' => [],
            # possessive adjective
            # examples: otcův, matčin
            's' => ['poss' => 'yes']
        },
        'encode_map' =>

            { 'poss' => { 'yes' => 's',
                           '@'   => 'f' }}
    );
    # PRONTYPE ####################
    $atoms{prontype} = $self->create_atom
    (
        'surfeature' => 'prontype',
        'decode_map' =>
        {
            # personal pronoun
            # examples: já, ty, on, ona, ono, my, vy, oni, ony
            'p' => ['prontype' => 'prs'],
            # demonstrative pronoun
            # examples: ten, tento, tenhle, onen, takový, týž, tentýž, sám
            'd' => ['prontype' => 'dem'],
            # emphatic pronoun (~ reflexive demonstrative)
            # examples: sám
            'h' => ['prontype' => 'emp'],
            # indefinite pronoun
            # examples: někdo, něco, nějaký, některý, něčí, leckdo, málokdo, kdokoli
            'i' => ['prontype' => 'ind'],
            # possessive pronoun
            # relative possessive pronouns ("jehož") are classified as relatives
            # examples: můj, tvůj, jeho, její, náš, váš, jejich
            's' => ['prontype' => 'prs', 'poss' => 'yes'],
            # interrogative pronoun
            # examples: kdo, co, jaký, který, čí
            'q' => ['prontype' => 'int'],
            # relative pronoun
            # examples: kdo, co, jaký, který, čí, jenž
            'r' => ['prontype' => 'rel'],
            # interrogative/relative pronoun
            # examples: kdo, co, jaký, který, čí
            'w' => ['prontype' => 'int|rel'],
            # reflexive pronoun (both personal and possessive reflexive pronouns fall here)
            # examples of personal reflexive pronouns: se, si, sebe, sobě, sebou
            # examples of possessive reflexive pronouns: svůj
            'x' => ['prontype' => 'prs', 'reflex' => 'yes'],
            # negative pronoun
            # examples: nikdo, nic, nijaký, ničí, žádný
            'z' => ['prontype' => 'neg'],
            # general pronoun
            # examples: sám, samý, veškerý, všecko, všechno, všelicos, všelijaký, všeliký, všema
            # some of them also appear classified as indefinite pronouns
            # most of the above examples are clearly syntactic adjectives (determiners)
            # many (except of "sám" and "samý" are classified as totality pronouns in other tagsets)
            'g' => ['prontype' => 'tot'],
            # definite article [ro]
            'f' => ['definite' => 'def']
        },
        'encode_map' =>
        {
            'reflex' => { 'yes' => 'x',
                          '@'      => { 'poss' => { 'yes' => 's',
                                                    '@'    => { 'prontype' => { 'dem' => 'd',
                                                                                'emp' => 'h',
                                                                                'ind' => 'i',
                                                                                'int|rel' => 'w',
                                                                                'int' => 'q',
                                                                                'rel' => 'r',
                                                                                'neg' => 'z',
                                                                                'tot' => 'g',
                                                                                '@'   => { 'definite' => { 'def' => 'f',
                                                                                                               '@'   => 'p' }}}}}}}
        }
    );
    # NUMTYPE ####################
    $atoms{numtype} = $self->create_atom
    (
        'surfeature' => 'numtype',
        'decode_map' =>
        {
            # cardinal number
            # examples [cs]: jeden, dva, tři, čtyři, pět, šest, sedm, osm, devět, deset
            'c' => ['pos' => 'num', 'numtype' => 'card'],
            # collective number
            # It expresses quantity and totality at the same time.
            # examples [ro]: amândoi, ambele (both)
            'l' => ['pos' => 'num', 'numtype' => 'card', 'prontype' => 'tot'],
            # ordinal number
            # examples [cs]: první, druhý, třetí, čtvrtý, pátý
            'o' => ['pos' => 'adj', 'numtype' => 'ord'],
            # pronominal numeral
            # examples [sl]: eden, en, drugi, drug
            # "en" ("one") could also be classified as a cardinal numeral but it is never tagged so.
            # "drugi" ("second" / "other") could also be classified as an ordinal numeral but is never tagged so.
            # These two have a catagory of their own because they also work as indefinite pronouns ("one man or the other").
            # Other pronominal numerals (in the sense of Interset, e.g. "how many") are not classified as pronominal in the Slovene Multext tagset!
            # Note that prontype=ind itself is not enough to distinguish this category because in other languages (e.g. Czech)
            # prontype is orthogonal to numtype (indefinite cardinal: "několik"; indefinite ordinal: "několikátý" etc.)
            # The only thing that makes these Slovene numerals different is the multivalue of numtype: card|ord.
            'p' => ['pos' => 'adj', 'numtype' => 'card|ord', 'prontype' => 'ind'],
            # multiplier number
            # examples [cs]: jednou, dvakrát, třikrát, čtyřikrát, pětkrát
            'm' => ['pos' => 'adv', 'numtype' => 'mult'],
            # special (generic) number (only Slavic languages?)
            # Czech term: číslovka druhová
            # Slovene term: števnik drugi
            # examples [cs]: desaterý, dvojí, jeden, několikerý, několikery, obojí
            # examples [sl]: dvojen, trojen
            # Some generic numerals are used for plurale tantum and for sets of objects. They are also called collective numerals.
            # examples [cs]: jedny, dvoje, troje, čtvery, patery, kolikery, několikery
            's' => ['pos' => 'adj', 'numtype' => 'sets']
        },
        'encode_map' =>
        {
            'numtype' => { 'card|ord' => { 'prontype' => { 'ind' => 'p',
                                                           'tot' => 'l',
                                                           '@'   => 'c' }},
                           'card'     => { 'prontype' => { 'tot' => 'l',
                                                           '@'   => 'c' }},
                           'ord'      => 'o',
                           'mult'     => 'm',
                           'sets'     => 's',
                           '@'        => 'c' }
        }
    );
    # VERBTYPE ####################
    $atoms{verbtype} = $self->create_atom
    (
        'surfeature' => 'verbtype',
        'decode_map' =>
        {
            # main verb
            # examples: absentovat, absolvovat, adaptovat, ...
            'm' => [],
            # auxiliary verb
            # examples: dostat, mít
            'a' => ['verbtype' => 'aux'],
            # modal verb
            # examples: chtít, dát, dávat, hodlat, moci, muset, lze, umět, zachtít
            'o' => ['verbtype' => 'mod'],
            # copula verb
            # examples: být, bývat, by
            'c' => ['verbtype' => 'cop']
        },
        'encode_map' =>

            { 'verbtype' => { 'aux' => 'a',
                              'mod' => 'o',
                              'cop' => 'c',
                              '@'   => 'm' }}
    );
    # CONJTYPE ####################
    $atoms{conjtype} = $self->create_atom
    (
        'surfeature' => 'conjtype',
        'decode_map' =>
        {
            # coordinating conjunction
            # examples: a, i, ani, nebo, ale
            # [ro] examples: sau (or), dar (but), însă (however), că (that), fie (or)
            'c' => ['conjtype' => 'coor'],
            # subordinating conjunction
            # examples: že, zda, aby, protože
            # [ro] examples: că (that), dacă (if), încât (that), deși (although), de
            's' => ['conjtype' => 'sub'],
            # portmanteau (multi-purpose?) conjunction: it can be either coordinating conjunction or an adverb, and the distinction is tricky for an average speaker of Romanian
            # [ro] examples: și (and), iar (and)
            'r' => ['conjtype' => 'coor', 'other' => {'conjtype' => 'portmanteau'}]
        },
        'encode_map' =>
        {
            'conjtype' => { 'coor' => { 'other/conjtype' => { 'portmanteau' => 'r',
                                                              '@'           => 'c' }},
                            'sub'  => 's',
                            '@'    => 'c' }
        }
    );
    # GENDER ####################
    $atoms{gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'm' => 'masc',
            'f' => 'fem',
            'n' => 'neut'
        },
        'encode_default' => '-'
    );
    # NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            's' => 'sing',
            'd' => 'dual',
            'p' => 'plur'
        },
        'encode_default' => '-'
    );
    # CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'n' => 'nom',
            'g' => 'gen',
            'd' => 'dat',
            'a' => 'acc',
            'v' => 'voc',
            'l' => 'loc',
            'i' => 'ins'
        },
        'encode_default' => '-'
    );
    # ANIMACY ####################
    $atoms{animacy} = $self->create_simple_atom
    (
        'intfeature' => 'animacy',
        'simple_decode_map' =>
        {
            'y' => 'anim',
            'n' => 'inan'
        },
        'encode_default' => '-'
    );
    # DEGREE ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'p' => 'pos',
            'c' => 'cmp',
            's' => 'sup'
        },
        'encode_default' => '-'
    );
    # ADJECTIVE FORMATION ####################
    $atoms{adjform} = $self->create_atom
    (
        'surfeature' => 'adjform',
        'decode_map' =>
        {
            # Short form of adjective ("nominal form" = "jmenný tvar" in Czech)
            # Only a handful of adjectives have nominal forms that are still in use.
            # One adjective has only nominal form: "rád".
            # examples: mlád, stár, zdráv, nemocen
            'n' => ['variant' => 'short'],
            # Long (normal) form of adjective ("pronominal form" = "zájmenný tvar" in Czech)
            # examples: mladý, starý, zdravý, nemocný
            'c' => [],
            '-' => []  # possessive adjectives do not have two forms
        },
        'encode_map' =>

            { 'poss' => { 'yes' => '-',
                          '@'    => { 'variant' => { 'short' => 'n',
                                                     '@'     => 'c' }}}}
    );
    # DEFINITENESS ####################
    # Definiteness is defined only for adjectives in Croatian.
    # It distinguishes long and short forms of Slavic adjectives. In Czech, the "indefinite" form would be "jmenný tvar" (nominal form, as opposed to the long, pronominal form).
    $atoms{definite} = $self->create_simple_atom
    (
        'intfeature' => 'definite',
        'simple_decode_map' =>
        {
            'y' => 'def', # glavni, bivši, novi, prvi, turski
            'n' => 'ind'  # važan, velik, poznat, dobar, ključan
        }
    );
    # PERSON ####################
    $atoms{person} = $self->create_atom
    (
        'surfeature' => 'person',
        'decode_map' =>
        {
            '1' => ['person' => '1'],
            '2' => ['person' => '2'],
            '3' => ['person' => '3']
        },
        'encode_map' =>
        # Person of participles is undefined even if the attached clitic "-s" suggests the 2nd person.
        # Person of demonstrative and reflexive pronouns is undefined despite the attached clitic "-s".
        # We have to be careful here. The "-s" clitic is specific for Czech. We cannot just erase person in any language.
        # Romanian, for example, sets the 3rd person even for demonstrative pronouns.
        { 'verbform' => { 'part' => '-',
                          '@'    => { 'other/clitic_s' => { 'y' => { 'prontype' => { 'prs' => { 'reflex' => { 'yes' => '-',
                                                                                                              '@'      => { 'person' => { '1' => '1',
                                                                                                                                          '2' => '2',
                                                                                                                                          '3' => '3',
                                                                                                                                          '@' => '-' }}}},
                                                                                     '@'   => '-' }},
                                                            '@' => { 'person' => { '1' => '1',
                                                                                   '2' => '2',
                                                                                   '3' => '3',
                                                                                   '@' => '-' }}}}}
        }
    );
    # OWNER NUMBER ####################
    $atoms{possnumber} = $self->create_simple_atom
    (
        'intfeature' => 'possnumber',
        'simple_decode_map' =>
        {
            's' => 'sing',
            'd' => 'dual',
            'p' => 'plur'
        },
        'encode_default' => '-'
    );
    # OWNER GENDER ####################
    $atoms{possgender} = $self->create_simple_atom
    (
        'intfeature' => 'possgender',
        'simple_decode_map' =>
        {
            'm' => 'masc',
            'f' => 'fem',
            'n' => 'neut'
        },
        'encode_default' => '-'
    );
    # IS PRONOUN CLITIC? ####################
    # clitic = yes for short forms of pronouns that behave like clitics (there exists a long form with identical meaning).
    # PerGenNumCase:       1-sd 1-sa 2-sd 2-sa 3msd 3msa 3d   3a   3d+s     3a+s
    # Examples [cs] (yes): mi   mě   ti   tě   mu   ho   si   se   sis      ses
    # Examples [cs] (no):  mně  mne  tobě tebe jemu jeho sobě sebe sobě jsi sebe jsi
    # Counterexamples (these are "short" but they have no longer equivalent, thus clitic = -): je, ně, tys
    $atoms{clitic} = $self->create_atom
    (
        'surfeature' => 'clitic',
        'decode_map' =>
        {
            'y' => ['variant' => 'short'],
            'n' => []
        },
        'encode_map' =>
        {
            'variant' => { 'short' => 'y',
                           '@'     => 'n' }
        }
    );
    # IS REFLEXIVE PRONOUN POSSESSIVE? ####################
    # referent type distinguishes between reflexive personal and reflexive possessive pronouns
    # personal: sebe, sebou, se, ses, si, sis, sobě
    # possessive: svůj
    $atoms{referent_type} = $self->create_atom
    (
        'surfeature' => 'referent_type',
        'decode_map' =>
        {
            's' => ['reflex' => 'yes', 'poss' => 'yes'],
            'p' => ['reflex' => 'yes']
        },
        'encode_map' =>

            { 'reflex' => { 'yes' => { 'poss' => { 'yes' => 's',
                                                      '@'    => 'p' }},
                            '@'      => '-' }}
    );
    # SYNTACTIC TYPE OF PRONOUN ####################
    # syntactic type: nominal or adjectival pronouns
    # in [ro] this is used to distinguish the part of speech of abbreviations
    # nominal: který, co, cokoliv, cosi, což, copak, cože, on, jaký, jenž, kdekdo, kdo, já, něco, někdo, nic, nikdo, se, ty, žádný
    # adjectival: který, čí, čísi, jaký, jakýkoli, jakýkoliv, jakýsi, jeho, jenž, kdekterý, kterýkoli, kterýkoliv, kterýžto, málokterý, můj, nějaký, něčí, některý, ničí, onen, sám, samý, svůj, týž, tenhle, takýs, takovýto, ten, tento, tentýž, tenhleten, tvůj, veškerý, všecko, všechno, všelicos, všelijaký, všeliký, všema, žádný
    $atoms{syntactic_type} = $self->create_atom
    (
        'surfeature' => 'syntactic_type',
        'decode_map' =>
        {
            'n' => ['pos' => 'noun'],
            'a' => ['pos' => 'adj'],
            'r' => ['pos' => 'adv']
        },
        'encode_map' =>

            { 'pos' => { 'noun' => 'n',
                         'adj'  => 'a',
                         'adv'  => 'r',
                         '@'    => '-' }}
    );
    # IS THERE AN ATTACHED CLITIC "-S" ("JSI")? ####################
    # clitic_s: Does it contain encliticized form of 2nd person of the auxiliary verb "být"?
    # There is no directly corresponding feature in the Interset.
    # Pronoun examples: ses, sis, tos, tys
    # "ses", "sis" and "tos" can be distinguished from "se", "si", "to" by setting person = '2'.
    # However, such a trick will not work for "tys" (as opposed to "ty": both are 2nd person).
    # Verb examples: slíbils, zapomněls, scvrnkls
    # In Czech this applies only to participles that normally do not set person.
    # Thus, setting person = '2' will distinguish these forms from the normal ones.
    $atoms{clitic_s} = $self->create_atom
    (
        'tagset'     => 'cs::multext',
        'surfeature' => 'clitic_s',
        'decode_map' =>
        {
            'y' => ['person' => '2', 'other' => {'clitic_s' => 'y'}],
            'n' => ['other' => {'clitic_s' => 'n'}]
        },
        # We cannot use encode_map for decisions based on the 'other' feature.
        # Custom code must be used instead of calling Atom::encode().
        'encode_map' =>

            { 'other/clitic_s' => { 'y' => 'y',
            # Clitic_s is obligatory for pronouns.
            # It is also obligatory for participles and infinitives (!) but not other verb forms.
                                    '@' => { 'prontype' => { ''  => { 'verbform' => { 'inf'  => 'n',
                                                                                      'part' => 'n',
                                                                                      '@'    => '-' }},
                                                             '@' => 'n' }}}}
    );
    # NUMERAL FORM ####################
    $atoms{numform} = $self->create_simple_atom
    (
        'intfeature' => 'numform',
        'simple_decode_map' =>
        {
            'd' => 'digit',
            'r' => 'roman',
            'l' => 'word',
            'm' => 'combi' # combined digits + suffix, e.g. 7-oji, 2009-ųjų
        },
        # We cannot say that 'l' is default. It would work for Czech, Slovenian and Croatian.
        # However, it would not work for Romanian where we distinguish collective numerals ("both").
        # These must be expressed as words, thus the numform feature is not explicitly used for them.
        'encode_default' => '-'
    );
    # NUMERAL CLASS ####################
    $atoms{numclass} = $self->create_atom
    (
        'surfeature' => 'numclass',
        'decode_map' =>
        {
            # Definite other than 1, 2, 3, 4
            # Examples: 1929, čtrnáctý, čtyřiapadesát, dvoustý, tucet
            # This is the default class of numerals, so we do not have to set anything.
            'f' => [],
            # Definite1 examples: jeden, první
            '1' => ['numvalue' => '1'],
            # Definite2 examples: druhý, dvojí, dvojnásob, dva, nadvakrát, oba, obojí
            '2' => ['numvalue' => '2'],
            # Definite34 examples: čtvrtý, čtyři, potřetí, tři, třetí, třikrát
            '3' => ['numvalue' => '3'],
            # Demonstrative examples: tolik, tolikrát
            'd' => ['prontype' => 'dem'],
            # Indefinite examples: bezpočet, bezpočtukrát, bůhvíkolik, hodně, málo, mnohý, mockrát, několik, několikerý, několikrát, nejeden, pár, vícekrát
            'i' => ['prontype' => 'ind'],
            # Interrogative examples: kolik, kolikrát
            'q' => ['prontype' => 'int'],
            # Relative examples: kolik, kolikrát
            'r' => ['prontype' => 'rel']
        },
        'encode_map' =>

            { 'prontype' => { 'dem' => 'd',
                              'ind' => 'i',
                              'int' => 'q',
                              'rel' => 'r',
                              '@'   => { 'numvalue' => { '1' => '1',
                                                         '2' => '2',
                                                         '3' => '3',
                                                         '@' => 'f' }}}}
    );
    # VERB FORM ####################
    $atoms{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            'i' => ['verbform' => 'fin', 'mood' => 'ind'],
            'm' => ['verbform' => 'fin', 'mood' => 'imp'],
            'c' => ['verbform' => 'fin', 'mood' => 'cnd'],
            's' => ['verbform' => 'fin', 'mood' => 'sub'],
            'n' => ['verbform' => 'inf'],
            'p' => ['verbform' => 'part'],
            't' => ['verbform' => 'conv'],
            'g' => ['verbform' => 'ger']
        },
        'encode_map' =>

            { 'mood' => { 'imp' => 'm',
                          'cnd' => 'c',
                          'sub' => 's',
                          'ind' => 'i',
                          '@'   => { 'verbform' => { 'part' => 'p',
                                                     'conv' => 't',
                                                     'ger'  => 'g',
                                                     '@'    => 'n' }}}}
    );
    # ASPECT ####################
    $atoms{aspect} = $self->create_simple_atom
    (
        'intfeature' => 'aspect',
        'simple_decode_map' =>
        {
            'e' => 'perf',    # perfective
            'p' => 'imp',     # imperfective (this is called "progressive" in the Slovene tagset)
            'b' => 'imp|perf' # biaspectual (we do not use the empty value here because we need it for tags where aspect is '-')
        },
        'encode_default' => '-'
    );
    # TENSE ####################
    $atoms{tense} = $self->create_simple_atom
    (
        'intfeature' => 'tense',
        'simple_decode_map' =>
        {
            'p' => 'pres',
            'f' => 'fut',
            's' => 'past',
            'i' => 'imp',
            'l' => 'pqp'
        },
        'encode_default' => '-'
    );
    # VOICE ####################
    $atoms{voice} = $self->create_simple_atom
    (
        'intfeature' => 'voice',
        'simple_decode_map' =>
        {
            'a' => 'act',
            'p' => 'pass'
        },
        'encode_default' => '-'
    );
    # POLARITY ####################
    $atoms{polarity} = $self->create_simple_atom
    (
        'intfeature' => 'polarity',
        'simple_decode_map' =>
        {
            'y' => 'neg',
            'n' => 'pos'
        },
        'encode_default' => '-'
    );
    # ADVERB TYPE ####################
    # Croatian distinguishes participial adverbs (or adverbial participles).
    # In Czech, the same category is classified as verbs (verbform = converb/transgressive).
    # Note that the current solution does not convert Czech converbs to Croatian participial adverbs or vice versa.
    $atoms{adverb_type} = $self->create_atom
    (
        'surfeature' => 'adverb_type',
        'decode_map' =>
        {
            # general adverb
            # examples: također, međutim, još, samo, kada
            'g' => [],
            # participial adverb (= adverbial participle = converb in Czech!)
            # examples: uključujući, ističući, govoreći, dodajući, budući
            'r' => ['verbform' => 'conv'],
            # interrogative or relative adverb
            # [ro] examples: când (when), cum (how), cât (how much), unde (where)
            'w' => ['prontype' => 'int|rel'],
            # negative adverb
            # [ro] examples: nici (not)
            'z' => ['prontype' => 'neg'],
            # particle adverb [ro]
            # It can dislocate verbal compound forms: Ea a _tot_ cântat. = She has _ever_ sung.
            # Or it marks degree: circa (about), foarte (very), prea (too).
            # [ro] examples: mai (more), și (also), foarte (very)
            'p' => ['other' => {'advtype' => 'particle'}],
            # portmanteau adverb [ro]
            # The word can be either adverb or conjunction, the adverbial reading is more frequent.
            # [ro] examples: ca (as), iar (again)
            'c' => ['other' => {'advtype' => 'portmanteau'}]
        },
        'encode_map' =>

            { 'verbform' => { 'conv' => 'r',
                              'part' => 'r',
                              '@'    => { 'prontype' => { 'int' => 'w',
                                                          'rel' => 'w',
                                                          'neg' => 'z',
                                                          '@'   => { 'other/advtype' => { 'portmanteau' => 'c',
                                                                                          'particle'    => 'p',
                                                                                          '@'           => 'g' }}}}}}
    );
    # ADPOSITION TYPE ####################
    # Czech has only prepositions, no postpositions or circumpositions.
    # Nevertheless, this field must still be filled in because of compatibility with the other languages.
    $atoms{adpostype} = $self->create_atom
    (
        'surfeature' => 'adpostype',
        'decode_map' =>
        {
            'p' => ['adpostype' => 'prep']
        },
        'encode_map' =>

            { 'adpostype' => { '@' => 'p' }}
    );
    # ADPOSITION FORMATION ####################
    # formation = compound ("nač", "naň", "oč", "vzhledem", "zač", "zaň")
    # These should be classified as pronouns rather than prepositions.
    $atoms{adposition_formation} = $self->create_atom
    (
        'surfeature' => 'adposition_formation',
        'decode_map' =>
        {
            # Merged word form of a preposition and a pronoun.
            # Examples: oč, zač, nač, oň, zaň, naň
            'c' => ['adpostype' => 'preppron'],
            's' => []
        },
        'encode_map' =>

            { 'adpostype' => { 'preppron' => 'c',
                               '@'        => 's' }}
    );
    # PARTICLE TYPE ####################
    $atoms{parttype} = $self->create_atom
    (
        'surfeature' => 'parttype',
        'decode_map' =>
        {
            # affirmative particle
            # examples: da
            'r' => ['polarity' => 'pos'],
            # negative particle
            # examples: ne
            'z' => ['polarity' => 'neg'],
            # interrogative particle
            # examples: li, zar
            'q' => ['prontype' => 'int'],
            # modal particle
            # examples: sve, što, i, više, god, bilo
            'o' => ['parttype' => 'mod'],
            # infinitive particle
            # [ro] examples: a: Cerea bani de la cine putea, spre a trăi pe un picior mai convenabil. = Who could ask for money, to live more conveniently.
            'n' => ['parttype' => 'inf'],
            # subjunctive particle
            # [ro] examples: să: Statul în cauză este în măsură să garanteze că... = State concerned is able to guarantee that...
            's' => ['mood' => 'sub'],
            # future particle
            # [ro] documentation has this, although it does not appear in the corpus
            'f' => ['tense' => 'fut']
        },
        'encode_map' =>

            { 'polarity' => { 'pos' => 'r',
                              'neg' => 'z',
                              '@'   => { 'prontype' => { 'int' => 'q',
                                                         '@'   => { 'parttype' => { 'mod' => 'o',
                                                                                    'inf' => 'n',
                                                                                    '@'   => { 'mood' => { 'sub' => 's',
                                                                                                           '@'   => { 'tense' => { 'fut' => 'f',
                                                                                                                                   '@'   => '-' }}}}}}}}}}
    );
    # RESIDUAL TYPE ####################
    $atoms{restype} = $self->create_atom
    (
        'surfeature' => 'restype',
        'decode_map' =>
        {
            # foreign word
            # examples: a1, SETimes, European, bin, international
            'f' => ['foreign' => 'yes'],
            # typo
            't' => ['typo' => 'yes'],
            # symbol (occurs in Lithuanian as Xh)
            'h' => ['pos' => 'sym'],
            # program
            # DZ: I am not sure what this value is supposed to mean. It is mentioned but not explained in the documentation.
            # It does not occur in the SETimes.HR corpus.
            'p' => []
        },
        'encode_map' =>
        {
            'pos' => { 'sym' => 'h',
                       '@'   => { 'foreign' => { 'yes' => 'f',
                                                 '@'       => { 'typo' => { 'yes' => 't',
                                                                            '@'    => '-' }}}}}
        }
    );
    return \%atoms;
}



#------------------------------------------------------------------------------
# Creates a map that tells for each surface part of speech which features are
# relevant and in what order they appear.
#------------------------------------------------------------------------------
sub _create_feature_map
{
    my $self = shift;
    my %features =
    (
        # This method must be overridden in every Multext-EAST-based tagset because the lists of features vary across languages.
        # Declaring a feature as undef means that there will be always a dash at that position of the tag.
        # 'N' => ['pos', 'nountype', 'gender', 'number', 'case'],
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
    my $features = $self->feature_map();
    my @chars = split(//, $tag);
    $atoms->{pos}->decode_and_merge_hard($chars[0], $fs);
    my @features;
    @features = @{$features->{$chars[0]}} if(defined($features->{$chars[0]}));
    for(my $i = 1; $i<=$#features; $i++)
    {
        if(defined($features[$i]) && defined($chars[$i]))
        {
            # Tagset drivers normally do not throw exceptions because they should be able to digest any input.
            # However, if we know we expect a feature and we have not defined an atom to handle that feature,
            # then it is an error of our code, not of the input data.
            if(!defined($atoms->{$features[$i]}))
            {
                confess("There is no atom to handle the feature '$features[$i]'");
            }
            $atoms->{$features[$i]}->decode_and_merge_hard($chars[$i], $fs);
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
    my $features = $self->feature_map();
    my $tag = $atoms->{pos}->encode($fs);
    my @features;
    @features = @{$features->{$tag}} if(defined($features->{$tag}));
    for(my $i = 1; $i<=$#features; $i++)
    {
        if(defined($features[$i]))
        {
            # Tagset drivers normally do not throw exceptions because they should be able to digest any input.
            # However, if we know we expect a feature and we have not defined an atom to handle that feature,
            # then it is an error of our code, not of the input data.
            if(!defined($atoms->{$features[$i]}))
            {
                confess("There is no atom to handle the feature '$features[$i]'");
            }
            $tag .= $atoms->{$features[$i]}->encode($fs);
        }
        else
        {
            $tag .= '-';
        }
    }
    # Remove trailing dashes.
    $tag =~ s/-+$//;
    return $tag;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::Multext - Common code for drivers of tagsets of the Multext-EAST project.

=head1 VERSION

version 3.016

=head1 SYNOPSIS

  package Lingua::Interset::Tagset::HR::Multext;
  extends 'Lingua::Interset::Tagset::Multext';

  # We must redefine the method that returns tagset identification, used by the
  # decode() method for the 'tagset' feature.
  sub get_tagset_id
  {
      # It should correspond to the last two parts in package name, lowercased.
      # Specifically, it should be the ISO 639-2 language code, followed by '::multext'.
      return 'hr::multext';
  }

  # We may add or redefine atoms for individual surface features.
  sub _create_atoms
  {
      my $self = shift;
      # Most atoms can be inherited but some have to be redefined.
      my $atoms = $self->SUPER::_create_atoms();
      $atoms->{verbform} = $self->create_atom (...);
      return $atoms;
  }

  # We must define the lists of surface features for all surface parts of speech!
  sub _create_feature_map
  {
      my $self = shift;
      my %features =
      (
          'N' => ['pos', 'nountype', 'gender', 'number', 'case', 'animacy'],
          ...
      );
      return \%features;
  }

  # We must define the list() method.
  sub list
  {
      my $self = shift;
      my $list = <<end_of_list
  Ncmsn
  Ncmsg
  Ncmsd
  ...
  end_of_list
      ;
      my @list = split(/\r?\n/, $list);
      return \@list;
  }

=head1 DESCRIPTION

Common code for drivers of tagsets of the Multext-EAST project.
All the Multext-EAST tagsets use the same inventory of parts of speech and the
same inventory of features (but not all features are used in all languages).
Feature values are individual alphanumeric characters and they are also
unified, thus if a feature value appears in several languages, it is always
encoded by the same character. The tagsets are positional, i.e. the position
of the value character in the tag determines the feature whose value this is.
The interpretation of the positions is defined separately for every language
and for every part of speech. Empty value (for unknown or irrelevant features)
is either encoded by a dash ("-"; if at least one of the following features has
a non-empty value) or is just omitted (at the end of the tag).

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::CS::Multext>,
L<Lingua::Interset::Tagset::HR::Multext>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
