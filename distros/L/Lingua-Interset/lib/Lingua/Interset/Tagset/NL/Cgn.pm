# ABSTRACT: Driver for the CGN/Lassy/Alpino Dutch tagset.
# Copyright © 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Copyright © 2014 Ondřej Dušek <odusek@ufal.mff.cuni.cz>

# tagset documentation at
# http://www.let.rug.nl/~vannoord/Lassy/POS_manual.pdf
# http://www.ccl.kuleuven.be/Papers/POSmanual_febr2004.pdf

package Lingua::Interset::Tagset::NL::Cgn;
use strict;
use warnings;
our $VERSION = '3.015';

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
    return 'nl::cgn';
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
            # adjectief / adjective
            # (groot, goed, bekend, nodig, vorig)
            'ADJ'  => ['pos' => 'adj'],
            # bijwoord / adverb
            # (zo, nu, dan, hier, altijd)
            # Note that in the 2005.07 version of the documentation the authors suggested to change the tag for adverbs
            # from BW to BIJW. But they still did not change it in the list of tags at the end of the document, and more
            # importantly, the old tag (BW) is used in the corpus. We will decode both versions and encode BW.
            'BIJW' => ['pos' => 'adv'],
            'BW'   => ['pos' => 'adv'],
            # leestekens / punctuation
            # " ' : ( ) ...
            'LET'  => ['pos' => 'punc'],
            # lidwoord / article
            # (het, der, de, des, den)
            'LID'  => ['pos' => 'adj', 'prontype' => 'art'],
            # substantief / noun
            # (jaar, heer, land, plaats, tijd)
            'N'    => ['pos' => 'noun'],
            # tussenwerpsel / interjection
            # (ja, nee)
            'TSW'  => ['pos' => 'int'],
            # telwoord / numeral
            # (twee, drie, vier, miljoen, tien)
            'TW'   => ['pos' => 'num'],
            # voegwoord / conjunction
            # (en, maar, of, dat, als, om)
            'VG'   => ['pos' => 'conj'],
            # voornaamwoord / pronoun
            # (ik, we, wij, u, je, jij, jullie, ze, zij, hij, het, ie, zijzelf)
            'VNW'  => ['pos' => 'noun', 'prontype' => 'prs'],
            # voorzetsel / preposition
            # (van, in, op, met, voor)
            'VZ'   => ['pos' => 'adp', 'adpostype' => 'prep'],
            # werkwoord / verb
            # (worden, zijn, blijven, komen, wezen)
            'WW'   => ['pos' => 'verb']
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''  => 'N',
                                                   '@' => 'VNW' }},
                       'adj'  => { 'prontype' => { ''    => { 'numtype' => { ''  => 'ADJ',
                                                                             '@' => 'TW' }},
                                                   'art' => 'LID',
                                                   '@'   => 'VNW' }},
                       'num'  => 'TW',
                       'verb' => 'WW',
                       'adv'  => { 'prontype' => { ''  => 'BW',
                                                   '@' => 'VNW' }},
                       'adp'  => 'VZ',
                       'conj' => 'VG',
                       'int'  => 'TSW',
                       'punc' => 'LET',
                       'sym'  => 'LET' }
        }
    );
    # NOUN TYPE ####################
    $atoms{nountype} = $self->create_simple_atom
    (
        'intfeature' => 'nountype',
        'simple_decode_map' =>
        {
            'soort' => 'com', # common noun (jaar, heer, land, plaats, tijd)
            'eigen' => 'prop' # proper noun (Nederland, Amsterdam, zaterdag, Groningen, Rotterdam)
        }
    );
    # VWTYPE / PRONOUN TYPE ####################
    $atoms{prontype} = $self->create_atom
    (
        'surfeature' => 'prontype',
        'decode_map' =>
        {
            'pers'  => ['prontype' => 'prs'], # persoonlijk (me, ik, ons, we, je, u, jullie, ze, hem, hij, hen)
            ###!!! There are no means in Interset to say that the word may or may not be reflexive
            ###!!! (to distinguish 'pr' from 'pers', which cannot be reflexive, and from 'refl', which is certainly reflexive).
            'pr'    => ['prontype' => 'prs', 'reflex' => 'yes'], # persoonlijk of reflexief (mij, me, mijzelf, mezelf, ons, onszelf, je, jezelf, u, uzelf)
            'refl'  => ['prontype' => 'prs', 'reflex' => 'yes'], # reflexief (zich, zichzelf)
            'bez'   => ['prontype' => 'prs', 'poss' => 'yes'], # beztittelijk (mijn, onze, je, jullie, zijner, zijn, hun)
            'recip' => ['prontype' => 'rcp'], # reciprook (elkaar, elkaars)
            'aanw'  => ['prontype' => 'dem'], # aanwijzend (deze, dit, die, dat)
            'betr'  => ['prontype' => 'rel'], # betrekkelijk (welk, die, dat, wat, wie)
            'vrag'  => ['prontype' => 'int'], # vragend (wie, wat, welke, welk)
            'vb'    => ['prontype' => 'int|rel'], # vragend of betrekkelijk / interrogative or relative
            'onbep' => ['prontype' => 'ind|neg|tot'], # onbepaald (geen, andere, alle, enkele, wat)
            'excl'  => ['prontype' => 'exc'] # exclamatief (wat een dwaasheid = what a folly; wat kan jij liegen zeg = what lie can you say)
        },
        'encode_map' =>
        {
            'prontype' => { 'prs'     => { 'poss' => { 'yes' => 'bez',
                                                       '@'    => { 'reflex' => { 'yes' => { 'person' => { '3' => 'refl',
                                                                                                             '@' => 'pr' }},
                                                                                 '@'      => 'pers' }}}},
                            'rcp'     => 'recip',
                            'dem'     => 'aanw',
                            'rel'     => 'betr',
                            'int'     => 'vrag',
                            'int|rel' => 'vb',
                            'ind'     => 'onbep',
                            'neg'     => 'onbep',
                            'tot'     => 'onbep',
                            'exc'     => 'excl' }
        }
    );
    # PDTYPE ####################
    $atoms{pdtype} = $self->create_atom
    (
        'surfeature' => 'pdtype',
        'decode_map' =>
        {
            'pron'     => ['pos' => 'noun'],
            # VNW(bez,det,...) ... possessive pronoun (determiner)
            # VNW(betr,det,stan,nom,zonder,zonder-n): hetgeen je daar ziet, het feest tijdens hetwelk
            # VNW(betr,det,stan,nom,met-e,zonder-n): op hetgene de gemeente doet = on what the municipality does
            'det'      => ['pos' => 'adj'],
            # gradable determiner
            # VNW(onbep,grad,stan,prenom,zonder,agr,basis): veel plezier = much fun, weinig geld = little money
            # VNW(onbep,grad,stan,prenom,zonder,agr,comp): meer tijd = more time, minder werk = less work
            # VNW(onbep,grad,stan,prenom,met-e,agr,sup): de meeste mensen = most people, het minste tijd = the least time
            'grad'     => ['pos' => 'adj', 'numtype' => 'card'],
            # adv-pronomen / pronominal adverb
            # VNW(vb,adv-pron,obl,vol,3o,getal): waar ga je naartoe = where are you going, de trein waar we op staan te wachten = the train we are waiting for
            # VNW(aanw,adv-pron,obl,vol,3o,getal): hier, daar
            # VNW(onbep,adv-pron,obl,vol,3o,getal): ergens, nergens, overal
            'adv-pron' => ['pos' => 'adv']
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => 'pron',
                       'adj'  => { 'numtype' => { 'card' => 'grad',
                                                  '@'    => 'det' }},
                       'adv'  => 'adv-pron' }
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
    # GRAAD / DEGREE ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            # degree of comparison (adjectives, adverbs and indefinite numerals (veel/weinig, meer/minder, meest/minst))
            # positive (goed, lang, erg, snel, zeker)
            'basis' => 'pos',
            # comparative (verder, later, eerder, vroeger, beter)
            'comp'  => 'cmp',
            # superlative (best, grootst, kleinst, moeilijkst, mooist)
            'sup'   => 'sup',
            # diminutive (stoeltje, huisje, nippertje, Kareltje)
            'dim'   => 'dim'
        }
    );
    # POSITIE / POSITION OF ADJECTIVE, DETERMINER, NUMERAL OR NON-FINITE VERB FORM ####################
    $atoms{position} = $self->create_simple_atom
    (
        'intfeature' => 'position',
        'simple_decode_map' =>
        {
            # attribute modifying a following noun
            # een vrije vogel, een mooi huis
            'prenom'  => 'prenom',
            # attribute modifying a preceding noun
            # rivieren bevaarbaar in de winter
            'postnom' => 'postnom',
            # substantively used
            # de rijken = the rich
            'nom'     => 'nom',
            # independently (predicatively or adverbially) used
            # "vrij" in "de vogels vrij laten rondvliegen"
            'vrij'    => 'free'
        }
    );
    # DEFINITENESS ####################
    # The tagset does not distinguish indefinite type of pronouns from indefinite definiteness of articles.
    # Both use the value 'onbep'. We have to distinguish them, so we change 'onbep' of articles to 'onb'.
    $atoms{definite} = $self->create_simple_atom
    (
        'intfeature' => 'definite',
        'simple_decode_map' =>
        {
            'bep' => 'def', # (het, der, de, des, den)
            'onb' => 'ind'  # (een)
        }
    );
    # GENUS / GENDER ####################
    $atoms{gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'zijd'  => 'com',  # zijdig / common, i.e. non-neuter (de)
            'masc'  => 'masc', # masculien / masculine; only third-person pronouns
            'fem'   => 'fem',  # feminien / feminine; only third-person pronouns
            'onz'   => 'neut', # onzijdig / neuter (het)
            'genus' => ''
        }
    );
    # GETAL / NUMBER ####################
    $atoms{number} = $self->create_atom
    (
        'surfeature' => 'number',
        'decode_map' =>
        {
            # enkelvoud (jaar, heer, land, plaats, tijd)
            'ev'    => ['number' => 'sing'],
            # meervoud (mensen, kinderen, jaren, problemen, landen)
            'mv'    => ['number' => 'plur'],
            # finite verbs: polite form of 2nd and 3rd person singular and plural
            'met-t' => ['polite' => 'form'],
            # underspecified number (e.g. with some pronouns)
            'getal' => []
        },
        'encode_map' =>
        {
            'number' => { 'sing' => 'ev',
                          'plur' => 'mv',
                          '@'    => { 'verbform' => { 'fin' => { 'polite' => { 'form' => 'met-t' }},
                                                      '@'   => 'getal' }}}
        }
    );
    # POSSESSOR'S NUMBER ####################
    # There are no specific feature values but number of possessive pronouns is to be interpreted as
    # the possessor's number. In order to make this work, we modify the values before decoding and after encoding.
    $atoms{possnumber} = $self->create_atom
    (
        'surfeature' => 'possnumber',
        'decode_map' =>
        {
            # enkelvoud (mijn = my, jouw = your, zijn = his, haar = her)
            'possev'    => ['possnumber' => 'sing'],
            # meervoud (ons = our, hun = their)
            'possmv'    => ['possnumber' => 'plur'],
            # underspecified number (uw = your)
            'possgetal' => []
        },
        'encode_map' =>
        {
            'possnumber' => { 'sing' => 'possev',
                              'plur' => 'possmv',
                              '@'    => 'possgetal' }
        }
    );
    # GETAL-N / NUMBER-N ####################
    $atoms{numbern} = $self->create_atom
    (
        'surfeature' => 'numbern',
        'decode_map' =>
        {
            # nominal usage without plural -n (het groen)
            'zonder-n' => [],
            # nominal usage with plural -n (de rijken)
            'mv-n'     => ['number' => 'plur']
        },
        'encode_map' =>
        {
            'number' => { 'plur' => 'mv-n',
                          '@'    => 'zonder-n' }
        }
    );
    # NAAMVAL / CASE ####################
    $atoms{case} = $self->create_atom
    (
        'surfeature' => 'case',
        'decode_map' =>
        {
            # standaard naamval / standard case (a word that does not take case markings and is used in nominative or oblique situations)
            'stan'  => ['case' => 'nom|acc'],
            # bijzonder naamval / special case (zaliger gedachtenis, van goeden huize, ten enen male)
            'bijz'  => ['case' => 'gen|dat'],
            # nominative (only pronouns: ik, we, wij, u, je, jij, jullie, ze, zij, hij, het, ie, zijzelf)
            'nomin' => ['case' => 'nom'],
            # oblique case (mij, haar, ons)
            'obl'   => ['case' => 'acc'],
            # genitive (der, des)
            'gen'   => ['case' => 'gen'],
            # dative (den)
            'dat'   => ['case' => 'dat']
        },
        'encode_map' =>
        {
            'case' => { 'acc|nom' => 'stan',
                        'dat|gen' => 'bijz',
                        'nom'     => 'nomin',
                        'gen'     => 'gen',
                        'dat'     => 'dat',
                        'acc'     => 'obl' }
        }
    );
    # BUIGING / INFLECTION ####################
    $atoms{inflection} = $self->create_atom
    (
        'surfeature' => 'inflection',
        'decode_map' =>
        {
            # base form (een mooi huis)
            'zonder' => ['other' => {'inflection' => '0'}],
            # -e (een groote pot, een niet te verstane verleiding); adjectives, verbs
            # ADJ(prenom,basis,met-e,stan): mooie huizen, een grote pot
            # ADJ(prenom,basis,met-e,bijz): zaliger gedachtenis, van goeden huize
            # ADJ(prenom,comp,met-e,stan): mooiere huizen, een grotere pot
            # ADJ(prenom,comp,met-e,bijz): van beteren huize
            'met-e'  => ['other' => {'inflection' => 'e'}],
            # -s (iets moois)
            'met-s'  => ['other' => {'inflection' => 's'}],
        },
        'encode_map' =>
        {
            'other/inflection' => { '0' => 'zonder',
                                    'e' => 'met-e',
                                    's' => 'met-s',
                                    '@' => { 'position' => { 'free' => 'zonder',
                                                             '@'    => { 'gender' => { ''  => { 'number' => { ''  => { 'case' => { ''  => 'zonder',
                                                                                                                                   '@' => 'met-e' }},
                                                                                                              '@' => 'met-e' }},
                                                                                       '@' => 'met-e' }}}}}
        }
    );
    # PERSOON / PERSON ####################
    $atoms{person} = $self->create_atom
    (
        'surfeature' => 'person',
        'decode_map' =>
        {
            # 1st person singular: ik, 'k, ikzelf, ikke
            # 1st person plural: wij, we, wijzelf
            '1'  => ['person' => '1'],
            # 2nd person vertrouwelijke vorm / informal form
            # singular: jij, je, jijzelf
            # plural: jullie
            '2v' => ['person' => '2', 'polite' => 'infm'],
            # 2nd person beleefdheidsvorm / polite form
            # singular or plural: u, uzelf
            '2b' => ['person' => '2', 'polite' => 'form'],
            # politeness-neutral form used in Vlaanderen
            # singular or plural: gij, ge, gijzelf
            '2'  => ['person' => '2'],
            # Documentation p. 43–44:
            # "Bemerk dat het hier niet om het morfo-syntactische genus van het woord gaat, maar om het natuurlijke geslacht van de referent."
            # We cannot encode the 3m vs. 3v distinction using the gender feature because it sometimes co-occurs with a separate value of gender:
            # VNW(pers,pron,nomin,nadr,3m,ev,masc) ... hijzelf
            # VNW(pers,pron,nomin,red,3p,ev,masc) ... men
            # VNW(pers,pron,nomin,red,3,ev,masc) ... ie
            # VNW(pers,pron,nomin,vol,3p,mv) ... zij
            # VNW(pers,pron,gen,vol,3m,ev) ... zijns gelijke, zijner
            # mannelijke referent
            # (wiens)
            # 3rd person singular masculine: hij, ie, hijzelf
            '3m' => ['person' => '3', 'animacy' => 'anim', 'other' => {'geslacht' => 'm'}],
            # vrouwelijke referent
            # (wier)
            # 3rd person singular feminine: zij, ze, zijzelf
            '3v' => ['person' => '3', 'animacy' => 'anim', 'other' => {'geslacht' => 'v'}],
            # 3rd person singular neuter: het, 't
            '3'  => ['person' => '3'],
            # persoonlijke referent
            # 3rd person plural animate: zij, ze, zijzelf
            # (wie, iemand, niemand, iedereen)
            '3p' => ['person' => '3', 'animacy' => 'anim', 'other' => {'geslacht' => 'p'}],
            # onpersoonlijke referent
            # (wat, iets, niets, alles)
            '3o' => ['person' => '3', 'animacy' => 'inan', 'other' => {'geslacht' => 'o'}],
            # underspecified person (e.g. with some pronouns)
            'persoon' => []
        },
        'encode_map' =>
        {
            'person' => { '1' => '1',
                          '2' => { 'polite' => { 'infm' => '2v',
                                                 'form' => '2b',
                                                 '@'    => '2' }},
                          '3' => { 'other/geslacht' => { 'o' => '3o',
                                                         'p' => '3p',
                                                         'm' => '3m',
                                                         'v' => '3v',
                                                         '@' => { 'animacy' => { 'anim' => { 'gender' => { 'masc' => '3m',
                                                                                                           'fem'  => '3v',
                                                                                                           '@'    => '3p' }},
                                                                                 'inan' => '3o',
                                                                                 '@'    => '3' }}}},
                          '@' => 'persoon' }
        }
    );
    # NP AGREEMENT ####################
    # NPAGR ... NPAGR = agr (evon, rest (evz, mv)), agr3 (evmo, rest3 (evf, mv)).
    # evon ... enkelvoudig onzijdig
    # evz .... enkelvoudig zijdig
    # evmo ... enkelvoudig masculien onzijdig
    # evf .... enkelvoudig feminien
    # mv ..... meervoudig
    # sommige determiners vereisen een enkelvoudig onzijdig substantief (dit, dat, welk, elk, ieder)
    # andere determiners vereisen een enkelvoudig zijdig substantief (elke, iedere)
    # nog andere determiners vereisen een enkelvoudig zijdig of een meervoudig substantief (deze, die, welke)
    # ons huis (our house): GETAL = meervoud; NPAGR = enkelvoud onzijdig
    ###!!! To je špatná zpráva, protože to znamená, že u slov, která mají rys NPAGR, bychom měli brát rod a číslo z něj
    ###!!! a rys GETAL by se potom vykládal jako intersetí rys possnumber.
    $atoms{npagr} = $self->create_atom
    (
        'surfeature' => 'npagr',
        'decode_map' =>
        {
            # VNW(bez,det,stan,vol,1,ev,prenom,zonder,agr) ... mijn paard(en) = my horse(s)
            'agr'   => [],
            # VNW(bez,det,stan,vol,1,mv,prenom,zonder,evon) ... ons paard = our horse
            'evon'  => ['number' => 'sing', 'gender' => 'neut'],
            # VNW(bez,det,stan,vol,1,ev,prenom,met-e,rest) ... mijne heren = (my) gentlemen
            'rest'  => ['number' => 'plur', 'gender' => 'com'],
            'evz'   => ['number' => 'sing', 'gender' => 'com'],
            'mv'    => ['number' => 'plur'],
            'agr3'  => ['gender' => 'masc|fem'],
            # VNW(bez,det,gen,vol,1,ev,prenom,zonder,evmo) ... mijns inziens = in my opinion
            'evmo'  => ['number' => 'sing', 'gender' => 'masc'],
            # VNW(bez,det,gen,vol,1,ev,prenom,met-e,rest3) ... een mijner vrienden = one of my friends
            # VNW(bez,det,dat,vol,1,ev,prenom,met-e,evmo) ... te mijnen huize = to my house
            'rest3' => ['number' => 'plur', 'gender' => 'fem'],
            # VNW(bez,det,dat,vol,1,ev,prenom,met-e,evf) ... te mijner ere = to my honor
            'evf'   => ['number' => 'sing', 'gender' => 'fem']
        },
        'encode_map' =>
        {
            'number' => { 'sing' => { 'gender' => { 'neut' => 'evon',
                                                    'com'  => 'evz',
                                                    'masc' => 'evmo',
                                                    'fem'  => 'evf',
                                                    '@'    => 'agr' }},
                          'plur' => { 'gender' => { 'com'  => 'rest',
                                                    'fem'  => 'rest3',
                                                    '@'    => 'mv' }},
                          '@'    => { 'gender' => { 'masc' => 'agr3',
                                                    'fem'  => 'agr3',
                                                    '@'    => 'agr' }}}
        }
    );
    # PRONOUN FORM ####################
    $atoms{pronform} = $self->create_simple_atom
    (
        'intfeature' => 'variant',
        'simple_decode_map' =>
        {
            'vol'  => 'long',  # vol / full: zij, haar
            'red'  => 'short', # gereduceerd / reduced: ze, d'r
            'nadr' => '1'      # nadruk / emphasis: ikke, ditte, datte, watte; -zelf, -lie(den)
        }
    );
    # VERB FORM ####################
    # wvorm
    $atoms{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            # persoonsvorm / personal form (finite verb)
            # (kom, speel, komen, spelen, komt, speelt, kwam, speelde, kwamen, speelden, kwaamt, gingt, kome, leve de koning)
            'pv'    => ['verbform' => 'fin'],
            # infinitief / infinitive
            # (zijn, gaan, slaan, staan, doen, zien)
            'inf'   => ['verbform' => 'inf'],
            # voltooid deelwoord / past participle
            # (afgelopen, gekomen, gegaan, gebeurd, begonnen)
            'vd'    => ['verbform' => 'part', 'tense' => 'past', 'aspect' => 'perf'],
            # onvoltooid deelwoord / present participle
            # (volgend, verrassend, bevredigend, vervelend, aanvallend)
            'od'    => ['verbform' => 'part', 'tense' => 'pres', 'aspect' => 'imp']
        },
        'encode_map' =>
        {
            'verbform' => { 'inf'  => 'inf',
                            'fin'  => 'pv',
                            'part' => { 'tense' => { 'pres' => 'od',
                                                     'past' => 'vd' }}}
        }
    );
    # MOOD AND TENSE ####################
    # tijd
    $atoms{tense} = $self->create_atom
    (
        'surfeature' => 'tense',
        'decode_map' =>
        {
            # tegenwoordige tijd / present tense
            # imperatief / imperative
            # (kom, speel, komen, spelen, komt, speelt)
            'tgw'   => ['mood' => 'ind|imp', 'tense' => 'pres'],
            # verleden tijd / past tense
            # (kwam, speelde, kwamen, speelden, gingt, kome)
            'verl'  => ['mood' => 'ind', 'tense' => 'past'],
            # conjunctief / subjunctive
            # (moge, leve, kome)
            # also expressing wishes (het ga je goed)
            'conj'  => ['mood' => 'sub'],
        },
        'encode_map' =>
        {
            'mood' => { 'sub' => 'conj',
                        '@'   => { 'tense' => { 'pres' => 'tgw',
                                                'past' => 'verl' }}}
        }
    );
    # ADPOSITION TYPE ####################
    $atoms{adpostype} = $self->create_atom
    (
        'surfeature' => 'adpostype',
        'decode_map' =>
        {
            # initieel / preposition
            # met een lepeltje, met Jan in het hospitaal, met zo te roepen
            'init'  => ['adpostype' => 'prep'],
            # finaal / postposition (achterzetsel)
            # (in, incluis, op)
            'fin'   => ['adpostype' => 'post'],
            # versmolten / fused preposition and article
            # ten strijde, ten hoogste, ter plaatse
            'versm' => ['adpostype' => 'comprep']
        },
        'encode_map' =>
        {
            'adpostype' => { 'prep'    => 'init',
                             'post'    => 'fin',
                             'comprep' => 'versm' }
        }
    );
    # CONJUNCTION TYPE ####################
    $atoms{conjtype} = $self->create_simple_atom
    (
        'intfeature' => 'conjtype',
        'simple_decode_map' =>
        {
            'neven' => 'coor', # coordinating (en, maar, of)
            'onder' => 'sub'   # subordinating (dat, als, dan, om, zonder, door)
        }
    );
    # SYMBOL ####################
    $atoms{symbol} = $self->create_atom
    (
        'surfeature' => 'symbol',
        'decode_map' =>
        {
            'symb' => ['pos' => 'sym'],
            'afk'  => ['abbr' => 'yes']
        },
        'encode_map' =>
        {
            'abbr' => { 'yes' => 'afk',
                        '@'    => { 'pos' => { 'sym' => 'symb' }}}
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
    my @features = ('pos', 'nountype', 'position', 'degree', 'inflection', 'definite', 'gender', 'case', 'number', 'possnumber', 'numbern', 'npagr',
                    'prontype', 'pdtype', 'person', 'pronform', 'numtype', 'verbform', 'tense', 'adpostype', 'conjtype', 'symbol');
    return \@features;
}



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    # We must distinguish indefinite articles from indefinite pronouns.
    $tag =~ s/^LID\(onbep,(.+)\)$/LID(onb,$1)/;
    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset('nl::cgn');
    my $atoms = $self->atoms();
    # Two components, part-of-speech tag and features.
    # example: N(soort,ev)
    my ($pos, $features) = split(/[\(\)]/, $tag);
    $features = '' if(!defined($features));
    # Possessive pronouns have both number and npagr. In their case number should be interpreted as the possessor's number.
    # Modify the values so that the atoms can distinguish the two numbers.
    $features =~ s/^(bez,det,.+),([em]v|getal),/$1,poss$2,/;
    my @features = split(/,/, $features);
    $atoms->{pos}->decode_and_merge_hard($pos, $fs);
    foreach my $feature (@features)
    {
        $atoms->{feature}->decode_and_merge_hard($feature, $fs);
    }
    return $fs;
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
        'N'       => ['nountype', 'number', 'degree', 'case'],
        'Ngen'    => ['nountype', 'number', 'degree', 'gender', 'case'],
        'ADJ'     => ['position', 'degree', 'inflection', 'case'],
        'ADJn'    => ['position', 'degree', 'inflection', 'numbern', 'case'],
        'WWpv'    => ['verbform', 'tense', 'number'],
        'WWopv'   => ['verbform', 'position', 'inflection'],
        'WWopvn'  => ['verbform', 'position', 'inflection', 'numbern'],
        'TW'      => ['numtype', 'position', 'case', 'degree'],
        'TWn'     => ['numtype', 'position', 'case', 'numbern', 'degree'],
        'VNW'     => ['prontype', 'pdtype', 'case', 'pronform', 'person', 'number'],
        'VNWgen'  => ['prontype', 'pdtype', 'case', 'pronform', 'person', 'number', 'gender'],
        'VNWbez'  => ['prontype', 'pdtype', 'case', 'pronform', 'person', 'possnumber', 'position', 'inflection', 'npagr'],
        'VNWbezn' => ['prontype', 'pdtype', 'case', 'pronform', 'person', 'possnumber', 'position', 'inflection', 'numbern'],
        'VNWbetr' => ['prontype', 'pdtype', 'case', 'position', 'inflection', 'numbern'],
        'VNWvb'   => ['prontype', 'pdtype', 'case', 'position', 'inflection', 'npagr', 'degree'],
        'VNWvbn'  => ['prontype', 'pdtype', 'case', 'position', 'inflection', 'numbern', 'degree'],
        'VNWvrij' => ['prontype', 'pdtype', 'case', 'position', 'inflection', 'degree'],
        'LID'     => ['definite', 'case', 'npagr'],
        'VZ'      => ['adpostype'],
        'VG'      => ['conjtype']
    );
    return \%features;
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
    my $fpos = $pos;
    # Adjectives (ADJ) and determiners (VNW) in the nominal position have the 'getal-n' feature. They do not have it in other positions.
    my $position = $fs->position();
    if($fpos eq 'N' && $fs->case() eq 'acc|nom')
    {
        $fpos = 'Ngen';
    }
    elsif($fpos =~ m/^(ADJ|TW)$/)
    {
        $fpos .= 'n' if($position eq 'nom');
    }
    elsif($fpos eq 'WW')
    {
        $fpos = $fs->is_finite_verb() ? 'WWpv' : $position eq 'nom' ? 'WWopvn' : 'WWopv';
    }
    elsif($fpos eq 'VNW')
    {
        # Gender is tagged for personal pronouns in the third person singular (or unspecified number), in the standard and oblique cases.
        if($fs->prontype() eq 'prs' && !$fs->is_reflexive() && !$fs->is_possessive() && $fs->person() eq '3' && $fs->number() ne 'plur' && $fs->case() !~ m/(gen|dat)/)
        {
            $fpos = 'VNWgen';
        }
        elsif($fs->is_adjective())
        {
            if($fs->is_possessive())
            {
                $fpos = $position eq 'nom' ? 'VNWbezn' : 'VNWbez';
            }
            elsif($fs->is_relative() && !$fs->is_interrogative()) # betrekkelijk
            {
                $fpos = 'VNWbetr';
            }
            else # vb (vragend|betrekkelijk) or aanwijzend or onbepaald
            {
                $fpos = $position eq 'nom' ? 'VNWvbn' : $position eq 'free' ? 'VNWvrij' : 'VNWvb';
            }
        }
    }
    my $feature_names = $self->get_feature_names($fpos);
    my $tag = $pos;
    my $features = '';
    if(defined($feature_names) && ref($feature_names) eq 'ARRAY')
    {
        my @features;
        foreach my $feature (@{$feature_names})
        {
            my $value = $atoms->{$feature}->encode($fs);
            push(@features, $value) unless($value eq '');
        }
        if(scalar(@features)>0)
        {
            $features = join(',', @features);
            # Possessive pronouns have both number and npagr. In their case number should be interpreted as the possessor's number.
            # Modify the values so that the atoms can distinguish the two numbers.
            $features =~ s/^(bez,det,.+),poss([em]v|getal),/$1,$2,/;
        }
    }
    $tag .= '('.$features.')';
    # We must distinguish indefinite articles from indefinite pronouns.
    $tag =~ s/^LID\(onb,(.+)\)$/LID(onbep,$1)/;
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# The list is taken from the documentation, Section 4.4. Dialectwoorden and
# speciale tokens have not been included; without them, there are 285 tags.
# A few non-existent tags have been added because we generate them if the
# 'other' feature is not available; this results in 323 tags in total.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
N(soort,ev,basis,zijd,stan)
N(soort,ev,basis,onz,stan)
N(soort,ev,basis,genus,stan)
N(soort,ev,dim,onz,stan)
N(soort,ev,basis,gen)
N(soort,ev,dim,gen)
N(soort,ev,basis,dat)
N(soort,mv,basis)
N(soort,mv,dim)
N(eigen,ev,basis,zijd,stan)
N(eigen,ev,basis,onz,stan)
N(eigen,ev,basis,genus,stan)
N(eigen,ev,dim,onz,stan)
N(eigen,ev,basis,gen)
N(eigen,ev,dim,gen)
N(eigen,ev,basis,dat)
N(eigen,mv,basis)
N(eigen,mv,dim)
ADJ(prenom,basis,zonder)
ADJ(prenom,basis,met-e,stan)
ADJ(prenom,basis,met-e,bijz)
ADJ(prenom,comp,zonder)
ADJ(prenom,comp,met-e,stan)
ADJ(prenom,comp,met-e,bijz)
ADJ(prenom,sup,zonder)
ADJ(prenom,sup,met-e,stan)
ADJ(prenom,sup,met-e,bijz)
ADJ(nom,basis,zonder,zonder-n)
ADJ(nom,basis,zonder,mv-n)
ADJ(nom,basis,met-e,zonder-n,stan)
ADJ(nom,basis,met-e,zonder-n,bijz)
ADJ(nom,basis,met-e,mv-n)
ADJ(nom,comp,zonder,zonder-n)
ADJ(nom,comp,met-e,zonder-n,stan)
ADJ(nom,comp,met-e,zonder-n,bijz)
ADJ(nom,comp,met-e,mv-n)
ADJ(nom,sup,zonder,zonder-n)
ADJ(nom,sup,met-e,zonder-n,stan)
ADJ(nom,sup,met-e,zonder-n,bijz)
ADJ(nom,sup,met-e,mv-n)
ADJ(postnom,basis,zonder)
ADJ(postnom,basis,met-s)
ADJ(postnom,comp,zonder)
ADJ(postnom,comp,met-s)
ADJ(vrij,basis,zonder)
ADJ(vrij,comp,zonder)
ADJ(vrij,sup,zonder)
ADJ(vrij,dim,zonder)
WW(pv,tgw,ev)
WW(pv,tgw,mv)
WW(pv,tgw,met-t)
WW(pv,verl,ev)
WW(pv,verl,mv)
WW(pv,verl,met-t)
WW(pv,conj,ev)
WW(inf,prenom,zonder)
WW(inf,prenom,met-e)
WW(inf,nom,zonder,zonder-n)
WW(inf,vrij,zonder)
WW(vd,prenom,zonder)
WW(vd,prenom,met-e)
WW(vd,nom,met-e,zonder-n)
WW(vd,nom,met-e,mv-n)
WW(vd,vrij,zonder)
WW(od,prenom,zonder)
WW(od,prenom,met-e)
WW(od,nom,met-e,zonder-n)
WW(od,nom,met-e,mv-n)
WW(od,vrij,zonder)
TW(hoofd,prenom,stan)
TW(hoofd,prenom,bijz)
TW(hoofd,nom,zonder-n,basis)
TW(hoofd,nom,mv-n,basis)
TW(hoofd,nom,zonder-n,dim)
TW(hoofd,nom,mv-n,dim)
TW(hoofd,vrij)
TW(rang,prenom,stan)
TW(rang,prenom,bijz)
TW(rang,nom,zonder-n)
TW(rang,nom,mv-n)
VNW(pers,pron,nomin,vol,1,ev)
VNW(pers,pron,nomin,nadr,1,ev)
VNW(pers,pron,nomin,red,1,ev)
VNW(pers,pron,nomin,vol,1,mv)
VNW(pers,pron,nomin,nadr,1,mv)
VNW(pers,pron,nomin,red,1,mv)
VNW(pers,pron,nomin,vol,2v,ev)
VNW(pers,pron,nomin,nadr,2v,ev)
VNW(pers,pron,nomin,red,2v,ev)
VNW(pers,pron,nomin,vol,2b,getal)
VNW(pers,pron,nomin,nadr,2b,getal)
VNW(pers,pron,nomin,vol,2,getal)
VNW(pers,pron,nomin,nadr,2,getal)
VNW(pers,pron,nomin,red,2,getal)
VNW(pers,pron,nomin,vol,3,ev,masc)
VNW(pers,pron,nomin,nadr,3m,ev,masc)
VNW(pers,pron,nomin,red,3,ev,masc)
VNW(pers,pron,nomin,red,3p,ev,masc)
VNW(pers,pron,nomin,vol,3v,ev,fem)
VNW(pers,pron,nomin,nadr,3v,ev,fem)
VNW(pers,pron,nomin,vol,3p,mv)
VNW(pers,pron,nomin,nadr,3p,mv)
VNW(pers,pron,obl,vol,2v,ev)
VNW(pers,pron,obl,vol,3,ev,masc)
VNW(pers,pron,obl,nadr,3m,ev,masc)
VNW(pers,pron,obl,red,3,ev,masc)
VNW(pers,pron,obl,vol,3,getal,fem)
VNW(pers,pron,obl,nadr,3v,getal,fem)
VNW(pers,pron,obl,red,3v,getal,fem)
VNW(pers,pron,obl,vol,3p,mv)
VNW(pers,pron,obl,nadr,3p,mv)
VNW(pers,pron,stan,nadr,2v,mv)
VNW(pers,pron,stan,red,3,ev,onz)
VNW(pers,pron,stan,red,3,ev,fem)
VNW(pers,pron,stan,red,3,mv)
VNW(pers,pron,gen,vol,1,ev)
VNW(pers,pron,gen,vol,1,mv)
VNW(pers,pron,gen,vol,2,getal)
VNW(pers,pron,gen,vol,3m,ev)
VNW(pers,pron,gen,vol,3v,getal)
VNW(pers,pron,gen,vol,3p,mv)
VNW(pr,pron,obl,vol,1,ev)
VNW(pr,pron,obl,nadr,1,ev)
VNW(pr,pron,obl,red,1,ev)
VNW(pr,pron,obl,vol,1,mv)
VNW(pr,pron,obl,nadr,1,mv)
VNW(pr,pron,obl,red,2v,getal)
VNW(pr,pron,obl,nadr,2v,getal)
VNW(pr,pron,obl,vol,2,getal)
VNW(pr,pron,obl,nadr,2,getal)
VNW(refl,pron,obl,red,3,getal)
VNW(refl,pron,obl,nadr,3,getal)
VNW(recip,pron,obl,vol,persoon,mv)
VNW(recip,pron,gen,vol,persoon,mv)
VNW(bez,det,stan,vol,1,ev,prenom,zonder,agr)
VNW(bez,det,stan,vol,1,ev,prenom,met-e,rest)
VNW(bez,det,stan,red,1,ev,prenom,zonder,agr)
VNW(bez,det,stan,vol,1,mv,prenom,zonder,evon)
VNW(bez,det,stan,vol,1,mv,prenom,met-e,rest)
VNW(bez,det,stan,vol,2,getal,prenom,zonder,agr)
VNW(bez,det,stan,vol,2,getal,prenom,met-e,rest)
VNW(bez,det,stan,vol,2v,ev,prenom,zonder,agr)
VNW(bez,det,stan,red,2v,ev,prenom,zonder,agr)
VNW(bez,det,stan,nadr,2v,mv,prenom,zonder,agr)
VNW(bez,det,stan,vol,3,ev,prenom,zonder,agr)
VNW(bez,det,stan,vol,3m,ev,prenom,met-e,rest)
VNW(bez,det,stan,vol,3v,ev,prenom,met-e,rest)
VNW(bez,det,stan,red,3,ev,prenom,zonder,agr)
VNW(bez,det,stan,vol,3,mv,prenom,zonder,agr)
VNW(bez,det,stan,vol,3p,mv,prenom,met-e,rest)
VNW(bez,det,stan,red,3,getal,prenom,zonder,agr)
VNW(bez,det,gen,vol,1,ev,prenom,zonder,evmo)
VNW(bez,det,gen,vol,1,ev,prenom,met-e,rest3)
VNW(bez,det,gen,vol,1,mv,prenom,met-e,evmo)
VNW(bez,det,gen,vol,1,mv,prenom,met-e,rest3)
VNW(bez,det,gen,vol,2,getal,prenom,zonder,evmo)
VNW(bez,det,gen,vol,2,getal,prenom,met-e,rest3)
VNW(bez,det,gen,vol,2v,ev,prenom,met-e,rest3)
VNW(bez,det,gen,vol,3,ev,prenom,zonder,evmo)
VNW(bez,det,gen,vol,3,ev,prenom,met-e,rest3)
VNW(bez,det,gen,vol,3v,ev,prenom,zonder,evmo)
VNW(bez,det,gen,vol,3v,ev,prenom,met-e,rest3)
VNW(bez,det,gen,vol,3p,mv,prenom,zonder,evmo)
VNW(bez,det,gen,vol,3p,mv,prenom,met-e,rest3)
VNW(bez,det,dat,vol,1,ev,prenom,met-e,evmo)
VNW(bez,det,dat,vol,1,ev,prenom,met-e,evf)
VNW(bez,det,dat,vol,1,mv,prenom,met-e,evmo)
VNW(bez,det,dat,vol,1,mv,prenom,met-e,evf)
VNW(bez,det,dat,vol,2,getal,prenom,met-e,evmo)
VNW(bez,det,dat,vol,2,getal,prenom,met-e,evf)
VNW(bez,det,dat,vol,2v,ev,prenom,met-e,evf)
VNW(bez,det,dat,vol,3,ev,prenom,met-e,evmo)
VNW(bez,det,dat,vol,3,ev,prenom,met-e,evf)
VNW(bez,det,dat,vol,3v,ev,prenom,met-e,evmo)
VNW(bez,det,dat,vol,3v,ev,prenom,met-e,evf)
VNW(bez,det,dat,vol,3p,mv,prenom,met-e,evmo)
VNW(bez,det,dat,vol,3p,mv,prenom,met-e,evf)
VNW(bez,det,stan,vol,1,ev,nom,met-e,zonder-n)
VNW(bez,det,stan,vol,1,mv,nom,met-e,zonder-n)
VNW(bez,det,stan,vol,2,getal,nom,met-e,zonder-n)
VNW(bez,det,stan,vol,2v,ev,nom,met-e,zonder-n)
VNW(bez,det,stan,vol,3m,ev,nom,met-e,zonder-n)
VNW(bez,det,stan,vol,3v,ev,nom,met-e,zonder-n)
VNW(bez,det,stan,vol,3p,mv,nom,met-e,zonder-n)
VNW(bez,det,stan,vol,1,ev,nom,met-e,mv-n)
VNW(bez,det,stan,vol,1,mv,nom,met-e,mv-n)
VNW(bez,det,stan,vol,2,getal,nom,met-e,mv-n)
VNW(bez,det,stan,vol,2v,ev,nom,met-e,mv-n)
VNW(bez,det,stan,vol,3m,ev,nom,met-e,mv-n)
VNW(bez,det,stan,vol,3v,ev,nom,met-e,mv-n)
VNW(bez,det,stan,vol,3p,mv,nom,met-e,mv-n)
VNW(bez,det,dat,vol,1,ev,nom,met-e,zonder-n)
VNW(bez,det,dat,vol,1,mv,nom,met-e,zonder-n)
VNW(bez,det,dat,vol,2,getal,nom,met-e,zonder-n)
VNW(bez,det,dat,vol,3m,ev,nom,met-e,zonder-n)
VNW(bez,det,dat,vol,3v,ev,nom,met-e,zonder-n)
VNW(bez,det,dat,vol,3p,mv,nom,met-e,zonder-n)
VNW(vrag,pron,stan,nadr,3o,ev)
VNW(betr,pron,stan,vol,persoon,getal)
VNW(betr,pron,stan,vol,3,ev)
VNW(betr,det,stan,nom,zonder,zonder-n)
VNW(betr,det,stan,nom,met-e,zonder-n)
VNW(betr,pron,gen,vol,3o,ev)
VNW(betr,pron,gen,vol,3o,getal)
VNW(vb,pron,stan,vol,3p,getal)
VNW(vb,pron,stan,vol,3o,ev)
VNW(vb,pron,gen,vol,3m,ev)
VNW(vb,pron,gen,vol,3v,ev)
VNW(vb,pron,gen,vol,3p,mv)
VNW(vb,adv-pron,obl,vol,3o,getal)
VNW(excl,pron,stan,vol,3,getal)
VNW(vb,det,stan,prenom,zonder,evon)
VNW(vb,det,stan,prenom,met-e,rest)
VNW(vb,det,stan,nom,met-e,zonder-n)
VNW(excl,det,stan,vrij,zonder)
VNW(aanw,pron,stan,vol,3o,ev)
VNW(aanw,pron,stan,nadr,3o,ev)
VNW(aanw,pron,stan,vol,3,getal)
VNW(aanw,pron,gen,vol,3m,ev)
VNW(aanw,pron,gen,vol,3o,ev)
VNW(aanw,adv-pron,obl,vol,3o,getal)
VNW(aanw,adv-pron,stan,red,3,getal)
VNW(aanw,det,stan,prenom,zonder,evon)
VNW(aanw,det,stan,prenom,zonder,rest)
VNW(aanw,det,stan,prenom,zonder,agr)
VNW(aanw,det,stan,prenom,met-e,rest)
VNW(aanw,det,gen,prenom,met-e,rest3)
VNW(aanw,det,dat,prenom,met-e,evmo)
VNW(aanw,det,dat,prenom,met-e,evf)
VNW(aanw,det,stan,nom,met-e,zonder-n)
VNW(aanw,det,stan,nom,met-e,mv-n)
VNW(aanw,det,gen,nom,met-e,zonder-n)
VNW(aanw,det,dat,nom,met-e,zonder-n)
VNW(aanw,det,stan,vrij,zonder)
VNW(onbep,pron,stan,vol,3p,ev)
VNW(onbep,pron,stan,vol,3o,ev)
VNW(onbep,pron,gen,vol,3p,ev)
VNW(onbep,adv-pron,obl,vol,3o,getal)
VNW(onbep,adv-pron,gen,red,3,getal)
VNW(onbep,det,stan,prenom,zonder,evon)
VNW(onbep,det,stan,prenom,zonder,agr)
VNW(onbep,det,stan,prenom,met-e,evz)
VNW(onbep,det,stan,prenom,met-e,mv)
VNW(onbep,det,stan,prenom,met-e,rest)
VNW(onbep,det,stan,prenom,met-e,agr)
VNW(onbep,det,gen,prenom,met-e,mv)
VNW(onbep,det,dat,prenom,met-e,evmo)
VNW(onbep,det,dat,prenom,met-e,evf)
VNW(onbep,grad,stan,prenom,zonder,agr,basis)
VNW(onbep,grad,stan,prenom,met-e,agr,basis)
VNW(onbep,grad,stan,prenom,met-e,mv,basis)
VNW(onbep,grad,stan,prenom,zonder,agr,comp)
VNW(onbep,grad,stan,prenom,met-e,agr,sup)
VNW(onbep,grad,stan,prenom,met-e,agr,comp)
VNW(onbep,det,stan,nom,met-e,mv-n)
VNW(onbep,det,stan,nom,met-e,zonder-n)
VNW(onbep,det,stan,nom,zonder,zonder-n)
VNW(onbep,det,gen,nom,met-e,mv-n)
VNW(onbep,grad,stan,nom,met-e,zonder-n,basis)
VNW(onbep,grad,stan,nom,met-e,mv-n,basis)
VNW(onbep,grad,stan,nom,met-e,zonder-n,sup)
VNW(onbep,grad,stan,nom,met-e,mv-n,sup)
VNW(onbep,grad,stan,nom,zonder,mv-n,dim)
VNW(onbep,grad,gen,nom,met-e,mv-n,basis)
VNW(onbep,det,stan,vrij,zonder)
VNW(onbep,grad,stan,vrij,zonder,basis)
VNW(onbep,grad,stan,vrij,zonder,sup)
VNW(onbep,grad,stan,vrij,zonder,comp)
LID(bep,stan,evon)
LID(bep,stan,rest)
LID(bep,gen,evmo)
LID(bep,gen,rest3)
LID(bep,dat,evmo)
LID(bep,dat,evf)
LID(bep,dat,mv)
LID(onbep,stan,agr)
LID(onbep,gen,evf)
VZ(init)
VZ(fin)
VZ(versm)
VG(neven)
VG(onder)
BW()
TSW()
LET()
end_of_list
    ;
    # Protect from editors that replace tabs by spaces.
    $list =~ s/ \s+/\t/sg;
    my @list = split(/\r?\n/, $list);
    # We have to add the following tags to the list.
    # They are not described in the documentation, which means that they are not supposed to appear in data.
    # However, we cannot avoid generating them during encoding if the 'other' feature is not available.
    my $list2 = <<end_of_list
VNW(pers,pron,nomin,red,3m,ev,masc)
VNW(pers,pron,gen,vol,3p,ev)
VNW(pers,pron,gen,vol,3p,getal)
VNW(bez,det,stan,vol,3p,ev,prenom,met-e,rest)
VNW(bez,det,gen,vol,3v,mv,prenom,met-e,rest3)
VNW(bez,det,dat,vol,3m,ev,prenom,met-e,evmo)
VNW(bez,det,dat,vol,3m,mv,prenom,met-e,evmo)
VNW(bez,det,dat,vol,3v,mv,prenom,met-e,evf)
VNW(bez,det,stan,vol,3p,ev,nom,met-e,zonder-n)
VNW(bez,det,stan,vol,3p,ev,nom,met-e,zonder-n)
VNW(bez,det,stan,vol,3p,ev,nom,met-e,mv-n)
VNW(bez,det,stan,vol,3p,ev,nom,met-e,mv-n)
VNW(bez,det,dat,vol,3p,ev,nom,met-e,zonder-n)
VNW(vb,pron,gen,vol,3p,ev)
VNW(aanw,pron,gen,vol,3p,ev)
WW(vd,nom,zonder,zonder-n)
WW(od,nom,zonder,zonder-n)
VNW(bez,det,stan,vol,1,ev,prenom,met-e,agr)
VNW(bez,det,stan,red,1,ev,prenom,met-e,agr)
VNW(bez,det,stan,vol,1,mv,prenom,met-e,evon)
VNW(bez,det,stan,vol,2,getal,prenom,met-e,agr)
VNW(bez,det,stan,vol,2v,ev,prenom,met-e,agr)
VNW(bez,det,stan,red,2v,ev,prenom,met-e,agr)
VNW(bez,det,stan,nadr,2v,mv,prenom,met-e,agr)
VNW(bez,det,stan,vol,3,ev,prenom,met-e,agr)
VNW(bez,det,stan,red,3,ev,prenom,met-e,agr)
VNW(bez,det,stan,vol,3,mv,prenom,met-e,agr)
VNW(bez,det,stan,red,3,getal,prenom,met-e,agr)
VNW(bez,det,gen,vol,1,ev,prenom,met-e,evmo)
VNW(bez,det,gen,vol,2,getal,prenom,met-e,evmo)
VNW(bez,det,gen,vol,3,ev,prenom,met-e,evmo)
VNW(bez,det,gen,vol,3m,ev,prenom,met-e,evmo)
VNW(bez,det,gen,vol,3m,mv,prenom,met-e,evmo)
VNW(vb,det,stan,prenom,met-e,evon)
VNW(aanw,det,stan,prenom,met-e,evon)
VNW(aanw,det,stan,prenom,met-e,agr)
VNW(onbep,det,stan,prenom,met-e,evon)
VNW(onbep,grad,stan,nom,met-e,mv-n,dim)
end_of_list
    ;
    push(@list, split(/\r?\n/, $list2));
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::NL::Cgn - Driver for the CGN/Lassy/Alpino Dutch tagset.

=head1 VERSION

version 3.015

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::NL::Cgn;
  my $driver = Lingua::Interset::Tagset::NL::Cgn->new();
  my $fs = $driver->decode('N(soort,ev,basis,zijd,stan)');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('nl::cgn', 'N(soort,ev,basis,zijd,stan)');

=head1 DESCRIPTION

Interset driver for the CGN/Lassy/Alpino Dutch tagset.
Tagset documentation at L<http://www.let.rug.nl/~vannoord/Lassy/POS_manual.pdf>.

=head1 AUTHOR

Ondřej Dušek, Dan Zeman

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
