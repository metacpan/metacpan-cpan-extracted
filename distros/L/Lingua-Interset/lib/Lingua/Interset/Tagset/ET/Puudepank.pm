# ABSTRACT: Driver for the Estonian tagset from the Eesti keele puudepank (Estonian Language Treebank).
# Tag is the part of speech followed by a slash and the morphosyntactic features, separated by commas.
# Copyright © 2011, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::ET::Puudepank;
use strict;
use warnings;
our $VERSION = '3.008';

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
    return 'et::puudepank';
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
        'tagset' => 'et::puudepank',
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # n = noun (tuul, mees, kraan, riik, naine)
            'n' => ['pos' => 'noun', 'nountype' => 'com'],
            # prop = proper noun (Arnold, Lennart, Palts, Savisaar, Telia)
            'prop' => ['pos' => 'noun', 'nountype' => 'prop'],
            # art = article ###!!! DOES NOT OCCUR IN THE CORPUS
            'art' => ['pos' => 'adj', 'prontype' => 'art'],
            # v = verb (kutsutud, tahtnud, teadnud, tasunud, polnud)
            'v' => ['pos' => 'verb'],
            # v-fin = finite verb (roniti, valati, sõidutati, lahkunud, prantsatasimegi)
            'v-fin' => ['pos' => 'verb', 'verbform' => 'fin'],
            # v-inf = infinitive?/non-finite verb (lugeda, nuusutada, kiirustamata, laulmast, magama)
            'v-inf' => ['pos' => 'verb', 'verbform' => 'inf'],
            # v-pcp2 = verb participle? (sõidutatud, liigutatud, sisenenud, sõudnud, prantsatatud)
            'v-pcp2' => ['pos' => 'verb', 'verbform' => 'part'],
            # adj = adjective (suur, väike, noor, aastane, hall)
            'adj' => ['pos' => 'adj'],
            # adj-nat = nationality adjective (prantsuse, tšuktši)
            'adj-nat' => ['pos' => 'adj', 'nountype' => 'prop', 'nametype' => 'nat'],
            # adv = adverb (välja, edasi, ka, siis, maha)
            'adv' => ['pos' => 'adv'],
            # prp = preposition (juurde, taga, all, vastu, kohta)
            'prp' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # pst = preposition/postposition (poole, järele, juurde, pealt, peale)
            'pst' => ['pos' => 'adp', 'adpostype' => 'post'],
            # conj-s = subordinating conjunction (et, kui, sest, nagu, kuigi)
            'conj-s' => ['pos' => 'conj', 'conjtype' => 'sub'],
            # conj-c = coordinating conjunction (ja, aga, või, vaid, a)
            'conj-c' => ['pos' => 'conj', 'conjtype' => 'coor'],
            # conj-p = prepositional conjunction ??? ###!!! DOES NOT OCCUR IN THE CORPUS
            'conj-p' => ['pos' => 'conj', 'other' => {'subpos' => 'prep'}],
            # pron = pronoun (to be specified) (pronoun type may be specified using features) (nood, sel, niisugusest, selle, sellesama)
            'pron' => ['pos' => 'noun', 'prontype' => 'prn'],
            # pron-pers = personal pronoun (ma, mina, sa, ta, tema, me, nad, nemad)
            'pron-pers' => ['pos' => 'noun', 'prontype' => 'prs'],
            # pron-rel = relative pronoun (mis, kes)
            'pron-rel' => ['pos' => 'noun', 'prontype' => 'rel'],
            # pron-int = interrogative pronoun ###!!! DOES NOT OCCUR IN THE CORPUS (is included under relative pronouns)
            'pron-int' => ['pos' => 'noun', 'prontype' => 'int'],
            # pron-dem = demonstrative pronoun (see, üks, siuke, selline, too)
            'pron-dem' => ['pos' => 'noun', 'prontype' => 'dem'],
            # pron-indef = indefinite pronoun (mõned)
            'pron-indef' => ['pos' => 'noun', 'prontype' => 'ind'],
            # pron-poss = possessive pronoun (ise)
            'pron-poss' => ['pos' => 'noun', 'prontype' => 'prs', 'poss' => 'yes'],
            # pron-def = possessive (?) pronoun (keegi, mingi)
            'pron-def' => ['pos' => 'noun', 'prontype' => 'prs', 'poss' => 'yes'],
            # pron-refl = reflexive pronoun (enda, endasse)
            'pron-refl' => ['pos' => 'noun', 'prontype' => 'prs', 'reflex' => 'yes'],
            # num = numeral (kaks, neli, viis, seitse, kümme)
            'num' => ['pos' => 'num'],
            # intj = interjection (no, kurat)
            'intj' => ['pos' => 'int'],
            # infm = infinitive marker ###!!! DOES NOT OCCUR IN THE CORPUS
            'infm' => ['pos' => 'part', 'parttype' => 'inf'],
            # punc = punctuation (., ,, ', -, :)
            'punc' => ['pos' => 'punc'],
            # sta = statement ??? ###!!! DOES NOT OCCUR IN THE CORPUS
            # abbr = abbreviation (km/h, cm)
            'abbr' => ['abbr' => 'yes'],
            # x = undefined word class (--, pid, viis-, ta-)
            'x' => [],
            # b = discourse particle (only in sul.xml (spoken language)) (noh, nigu, vä, nagu, ei)
            'b' => ['pos' => 'part']
        },
        'encode_map' =>

            { 'prontype' => { ''    => { 'pos' => { 'noun' => { 'nountype' => { 'prop' => 'prop',
                                                                                '@'    => 'n' }},
                                                    'adj'  => { 'nametype' => { 'nat' => 'adj-nat',
                                                                                '@'   => 'adj' }},
                                                    'num'  => 'num',
                                                    # Encoding of verb forms is inconsistent in the corpus.
                                                    # The form is encoded in the features but sometimes it is also part of the part-of-speech tag.
                                                    # We can decode v-(fin|inf|pcp2) but we do not encode it.
                                                    # Our list of known tags only contains the simple "v" variant.
                                                    'verb' => 'v',
                                                    'adv'  => 'adv',
                                                    'adp'  => { 'adpostype' => { 'post' => 'pst',
                                                                                 '@'    => 'prp' }},
                                                    'conj' => { 'conjtype' => { 'sub' => 'conj-s',
                                                                                '@'   => 'conj-c' }},
                                                    'part' => { 'parttype' => { 'inf' => 'infm',
                                                                                '@'   => 'b' }},
                                                    'int'  => 'intj',
                                                    'punc' => 'punc',
                                                    '@'    => { 'abbr' => { 'yes' => 'abbr',
                                                                            '@'    => 'x' }}}},
                              'art' => 'art',
                              # Encoding of pronoun types is inconsistent in the corpus.
                              # The type is always the first feature but sometimes it is also part of the part-of-speech tag (pron-dem/dem), next time it is not (pron/dem).
                              # We can decode pron-(dem|indef|int|rel) but we do not encode it. Our list of known tags only contains the pron/dem variant.
                              '@'   => 'pron' }}
    );
    # NOUNTYPE ####################
    $atoms{nountype} = $self->create_atom
    (
        'surfeature' => 'nountype',
        'decode_map' =>
        {
            # com ... common noun (tuul, mees, kraan, riik, naine)
            'com'     => ['nountype' => 'com'],
            # prop ... proper noun (Peeter, Jaan, Jüri, Mare, Erik)
            'prop'    => ['nountype' => 'prop'],
            # nominal ... nominal abbreviation (Kaabel-TV, EE, kaabelTV) ... used rarely and inconsistently, should be ignored
            'nominal' => []
        },
        'encode_map' =>
        {
            'nountype' => { 'prop' => 'prop',
                            '@'    => 'com' }
        }
    );
    # PRONTYPE ####################
    $atoms{prontype} = $self->create_atom
    (
        'surfeature' => 'prontype',
        'decode_map' =>
        {
            # demonstrative: sel (this), samal (the same), see (it, this), need (these), niisugune (such), too (that)
            'dem'   => ['prontype' => 'dem'],
            # total: iga (each, every, any), kõik (everything, all), mõlemad (both)
            'det'   => ['prontype' => 'tot'],
            # indefinite or negative: teised (other), midagi (nothing), üht (one), mõne (a few), keegi (one), mingi (some), mitu (several)
            'indef' => ['prontype' => 'ind|neg'],
            # interrogative: milline (what), mis (which), kes (who)
            'inter' => ['prontype' => 'int'],
            # personal: mina, ma (I), sina, sa (you.sing), ta, tema (he/she/it), meie, me (we), teie, te (you.plur), nemad, nad (they)
            'pers'  => ['prontype' => 'prs'],
            # possessive: oma (own, their, your, its, his, our, my)
            # Note: The real tag is 'pos' but we change it to 'poss' during preprocessing to make it distinct from the tag for the positive degree of adjectives.
            'poss'  => ['prontype' => 'prs', 'poss' => 'yes'],
            # reciprocal: üksteisele (each other)
            'rec'   => ['prontype' => 'rcp'],
            # reflexive: ise, enese, end (oneself, self)
            'refl'  => ['prontype' => 'prs', 'reflex' => 'yes'],
            # relative: kes (who), mis (what), milline (which)
            'rel'   => ['prontype' => 'rel']
        },
        'encode_map' =>
        {
            'prontype' => { 'dem' => 'dem',
                            'tot' => 'det',
                            'ind' => 'indef',
                            'neg' => 'indef',
                            'int' => 'inter',
                            'prs' => { 'poss' => { 'yes' => 'pos',
                                                   '@'    => { 'reflex' => { 'yes' => 'refl',
                                                                             '@'      => 'pers' }}}},
                            'rcp' => 'rec',
                            'rel' => 'rel' }
        }
    );
    # NUMTYPE ####################
    $atoms{numtype} = $self->create_simple_atom
    (
        'intfeature' => 'numtype',
        'simple_decode_map' =>
        {
            # card ... cardinal numerals (kaks = two, neli = four, viis = five, seitse = seven, kümme = ten)
            # ord ... adj/ord || num/ord (esimene = first, teine = second, kolmas = third)
            'card' => 'card',
            'ord'  => 'ord'
        }
    );
    # NUMFORM ####################
    $atoms{numform} = $self->create_simple_atom
    (
        'intfeature' => 'numform',
        'simple_decode_map' =>
        {
            # l ... numeral (or ordinal adjective) written in letters (üks, kaks, kolm, neli, viis)
            # digit ... numeral written in digits (21, 120, 20_000, 15.40, 1875)
            'l'     => 'word',
            'digit' => 'digit'
        }
    );
    # VERBTYPE ####################
    $atoms{verbtype} = $self->create_simple_atom
    (
        'intfeature' => 'verbtype',
        'simple_decode_map' =>
        {
            # aux ... v/aux || v-fin/aux: auxiliary verb (ole = to be, ei = not, saaks = to)
            # mod ... v/mod || v-fin/mod: modal verb (saa = can, pean = have/need?, võib = can)
            # main ... main verb:
            # main ... v/main (teha = do, saada = get, hakata = start, pakkuda = offer, müüa = sell)
            # main ... v-fin/main (olen = I am, tatsan, sõidan = I drive, ütlen = I say, ujun = I swim)
            # main ... v-inf/main (magama = sleep, hingama = breathe, uudistama = gaze, külastama = visit, korjama = pick)
            # main ... v-pcp2/main (liikunud = moved, roninud = climbed, tilkunud = dripped, tõusnud = increased, prantsatanud = crashed)
            'aux' => 'aux',
            'mod' => 'mod'
        },
        'encode_default' => 'main'
    );
    # ADPOSTYPE ####################
    $atoms{adpostype} = $self->create_simple_atom
    (
        'intfeature' => 'adpostype',
        'simple_decode_map' =>
        {
            # pre ... prp/pre: preposition (vastu = against, enne = before, pärast = after, hoolimata = in spite of, üle = over)
            # post ... prp/post: postposition (mööda = along, juurde = to/by/near, taga = behind, all = under, vastu = against)
            # post ... pst/post: postposition (vahet = between, poole = to, järele = for, pealt = from, peale = after)
            'pre'  => 'prep',
            'post' => 'post'
        }
    );
    # CONJTYPE ####################
    $atoms{conjtype} = $self->create_simple_atom
    (
        'intfeature' => 'conjtype',
        'simple_decode_map' =>
        {
            # crd ... conj-c/crd || conj-s/crd: coordination (ja = and, aga = but, või = or, vaid = but, ent = however)
            #         conj-c/crd,sub (kui = if/as/when/that)
            # sub ... conj-s/sub || conj-c/sub: subordination (et = that, kui = if/as/when/that, sest = because, nagu = as/like, kuigi = although)
            'crd'   => 'coor',
            'sub'   => 'sub'
        }
    );
    # PUNCTYPE ####################
    $atoms{punctype} = $self->create_simple_atom
    (
        'intfeature' => 'punctype',
        'simple_decode_map' =>
        {
            # Com ... comma (,)
            # Exc ... exclamation mark (!)
            # Fst ... full stop (., ...)
            # Int ... question mark (?)
            'Com' => 'comm',
            'Exc' => 'excl',
            'Fst' => 'peri',
            'Int' => 'qest'
        }
    );
    # PERSON ####################
    $atoms{person} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            # ps1 ... first person (ma, mind)
            # ps2 ... second person (sind)
            # ps3 ... third person (neil, neile, nende, nad, neid, tal, talle, tema, ta)
            'ps1' => '1',
            'ps2' => '2',
            'ps3' => '3'
        }
    );
    # PERSONAL VS. IMPERSONAL VERB ####################
    # Personativity of verbs: is the person of the verb known? (###!!! DZ: tagset documentation missing, misinterpretation possible!)
    $atoms{personal} = $self->create_atom
    (
        'tagset' => 'et::puudepank',
        'surfeature' => 'personal',
        'decode_map' =>
        {
            # ps ... (olen = I am, sõidan = I drive, ütlen = I say, ujun = I swim, liigutan = I move)
            # imps ... (räägitakse = it's said, kaalutakse = it's considered; mängiti = played, visati = thrown, eelistati = preferred, hakati = began)
            'ps'   => [], # default
            'imps' => ['other' => {'personal' => 'no'}]
        },
        'encode_map' =>
        {
            'other/personal' => { 'no' => 'imps',
                                  '@'  => { 'verbtype' => { 'aux' => 'ps',
                                                            '@'   => { 'mood' => { 'ind' => { 'person' => { ''  => { 'polarity' => { 'pos' => 'imps',
                                                                                                                                     '@'   => 'ps' }},
                                                                                                            '@' => 'ps' }},
                                                                                   'cnd' => { 'tense' => { 'past' => 'ps',
                                                                                                           '@'    => { 'person' => { ''  => { 'polarity' => { 'pos' => 'imps',
                                                                                                                                                              '@'   => 'ps' }},
                                                                                                                                     '@' => 'ps' }}}},
                                                                                   '@'   => 'ps' }}}}}
        }
    );
    # NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            # sg ... singular (abbreviations, adjectives, nouns, numerals, pronouns, proper nouns, verbs)
            # pl ... plural (ditto)
            'sg' => 'sing',
            'pl' => 'plur'
        }
    );
    # CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            # nom ... nominative (tuul, mees, kraan, riik, naine)
            # gen ... genitive (laua, mehe, ukse, metsa, tee)
            # abes ... abessive? (aietuseta)
            # abl ... ablative (maalt, laevalt, põrandalt, teelt, näolt)
            # ad ... adessive (aastal, tänaval, hommikul, õhtul, sammul)
            # adit ... additive (koju, tuppa, linna, kööki, aeda) ... tenhle pád česká, anglická ani estonská Wikipedie estonštině nepřipisuje, ale značky Multext ho obsahují
            #    additive has the same meaning as illative, exists only for some words and only in singular
            # all ... allative (põrandala, kaldale, rinnale, koerale, külalisele)
            # el ... elative (hommikust, trepist, linnast, toast, voodist)
            # es ... essive (naisena, paratamatusena, tulemusena, montöörina, tegurina)
            # ill ... illative (voodisse, ämbrisse, sahtlisse, esikusse, autosse)
            # in ... inessive (toas, elus, unes, sadulas, lumes)
            # kom ... comitative (kiviga, jalaga, rattaga, liigutusega, petrooliga)
            # part ... partitive (vett, tundi, ust, verd, rada)
            # term ... terminative (õhtuni, mereni, ääreni, kaldani, kroonini)
            # tr ... translative (presidendiks, ajaks, kasuks, müüjaks, karjapoisiks)
            'nom'  => 'nom',
            'gen'  => 'gen',
            'abes' => 'abe',
            'abl'  => 'abl',
            'ad'   => 'ade',
            'adit' => 'add',
            'all'  => 'all',
            'el'   => 'ela',
            'es'   => 'ess',
            'ill'  => 'ill',
            'in'   => 'ine',
            'kom'  => 'com',
            'part' => 'par',
            'term' => 'ter',
            'tr'   => 'tra'
        }
    );
    # VALENCY CASE OF ADPOSITIONS ####################
    $atoms{valcase} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            # .el, %el ... preposition requires ellative (hoolimata = in spite of)
            # .gen, %gen ... preposition requires genitive (juurde = to, taga = behind, all = under, vastu = against, kohta = for)
            # .nom, %nom ... preposition requires nominative (tagasi = back)
            # .kom, %kom ... preposition requires comitative (koos = with)
            # .part, %part ... preposition requires partitive (mööda = along, vastu = against, keset = in the middle of, piki = along, enne = before)
            '.nom'  => 'nom',
            '.gen'  => 'gen',
            '.abes' => 'abe',
            '.abl'  => 'abl',
            '.ad'   => 'ade',
            '.adit' => 'add',
            '.all'  => 'all',
            '.el'   => 'ela',
            '.es'   => 'ess',
            '.ill'  => 'ill',
            '.in'   => 'ine',
            '.kom'  => 'com',
            '.part' => 'par',
            '.term' => 'ter',
            '.tr'   => 'tra'
        }
    );
    # DEGREE OF COMPARISON ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            # The feature 'pos' seems to be the only feature with multiple meanings depending on the part of speech.
            # With adjectives, it means probably 'positive degree'. With pronouns, it is probably 'possessive'.
            # pos ... adj/pos (suur = big, väike = small, noor = young, aastane = annual, hall = gray)
            # pos ... adj/pos,partic (unistav = dreamy, rahulolev = contented, kägardunud = pushed, hautatud = stew, solvatud = hurt)
            # pos ... pron/pos (oma = my/your/his/her/its/our/their)
            # pos ... pron-poss/pos (oma)
            # pos ... pron-poss/pos,det,refl (ise, enda, oma)
            # comp ... comparative (tugevam = stronger, parem = better, tõenäolisem = more likely, enam = more, suurem = greater)
            'pos'  => 'pos',
            'comp' => 'cmp'
        }
    );
    # VERBFORM AND MOOD ####################
    $atoms{mood} = $self->create_atom
    (
        'surfeature' => 'mood',
        'decode_map' =>
        {
            # inf ... infinitive (teha, saada, hakata, pakkuda, müüa)
            # sup ... supine (informeerimata, tulemast, avaldamast, otsima, tegema)
            # partic ... adjectives and verbs ... participles (keedetud, tuntud, tunnustatud)
            # ger ... gerund (arvates, naeratades, vaadates, näidates, saabudes)
            # indic ... indicative (oli, pole, ole, on, ongi)
            # imper ... imperative (vala, sõiduta)
            # cond ... conditional (saaks, moodustaksid)
            # quot ... quotative mood (olevat, tilkuvat)
            'inf'   => ['verbform' => 'inf'],
            'sup'   => ['verbform' => 'sup'],
            'partic'=> ['verbform' => 'part'],
            'ger'   => ['verbform' => 'ger'],
            'indic' => ['verbform' => 'fin', 'mood' => 'ind'],
            'imper' => ['verbform' => 'fin', 'mood' => 'imp'],
            'cond'  => ['verbform' => 'fin', 'mood' => 'cnd'],
            'quot'  => ['verbform' => 'fin', 'mood' => 'qot']
        },
        'encode_map' =>
        {
            'verbform' => { 'inf'   => 'inf',
                            'sup'   => 'sup',
                            'part'  => 'partic',
                            'trans' => 'partic',
                            'ger'   => 'ger',
                            '@'     => { 'mood' => { 'imp' => 'imper',
                                                     'cnd' => 'cond',
                                                     'qot' => 'quot',
                                                     '@'   => 'indic' }}}
        }
    );
    # TENSE ####################
    $atoms{tense} = $self->create_simple_atom
    (
        'intfeature' => 'tense',
        'simple_decode_map' =>
        {
            # pres ... present (saaks, moodustaksid, oleks, asetuks, kaalutakse)
            # past ... past (tehtud, antud, surutud, kirjutatud, arvatud)
            # impf ... imperfect (oli, käskisin, helistasin, olid, algasid)
            'pres'  => 'pres',
            'past'  => 'past',
            'impf'  => 'imp'
        }
    );
    # POLARITY ####################
    $atoms{polarity} = $self->create_simple_atom
    (
        'intfeature' => 'polarity',
        'simple_decode_map' =>
        {
            # af ... affirmative verb (oli, saime, andsin, sain, ütlesin)
            # neg ... negative verb (ei, kutsutud, tahtnud, teadnud, polnud)
            'af'  => 'pos',
            'neg' => 'neg'
        }
    );
    # MERGED ATOM TO DECODE ANY FEATURE VALUE ####################
    # Note that some features of the tagset are ignored:
        # Subcategorization of verbs:
            # .Intr, %Intr ... intransitive verb
            # .Int, %Int ... verb subcategorization? another code for intransitive?
            # .InfP, %InfP ... infinitive phrase
            # .FinV, %FinV ... finite verb
            # .NGP-P, %NGP-P ... verb subcategorization? for what?
            # .Abl, %Abl ... noun phrase in ablative
            # .All, %All ... noun phrase in allative
            # .El, %El ... noun phrase in elative
            # .Part, %Part ... noun phrase in partitive
        # y ... noun abbreviations? (USA, AS, EBRD, CIA, ETV)
        # ? ... abbreviations, numerals; unknown meaning
        # .? ... abbreviations, adjectives, adverbs, nouns, proper nouns; unknown meaning
        # x? ... numerals; unknown meaning
        # .cap, %cap ... capitalized word (abbreviations: KGB; adjectives: Inglise; adverbs: Siis; conj-c: Ja; nouns: Poistelt; pronouns: Meile; prop: Jane...)
        # .gi ... adjectives and nouns with the suffix '-gi' (rare feature)
        # .ja, %ja ... words with suffix '-ja' (pakkujad, vabastaja)
        # .janna ... words with suffix '-janna' (pekimägi-käskijanna)
        # .ke ... words with suffix '-ke' (aiamajakese, sammukese, klaasikese)
        # .lik ... words with suffix '-lik' (pidulikku)
        # .line ... adjectives or nouns with suffix '-line', '-lis-' (mustavereline)
        # .m ... adjectives; unknown meaning (rare feature; just one occurrence: väiksemagi)
        # .mine, %mine ... nouns with suffix '-mis-' (rare feature; nõudmised, kurtmised)
        # .nud, %nud ... words with suffix '-nud'
        # .tav, %tav ... words with suffix '-tav' (laetav, väidetavasti)
        # .tud, %tud ... words with suffix '-tud'
        # .v, %v ... participial adjectives with suffix '-v', '-va-'
        # -- ... meaning no features
    my @fatoms = map {$atoms{$_}} (qw(nountype prontype numtype numform verbtype adpostype conjtype punctype number case valcase degree person personal mood tense polarity));
    $atoms{feature} = $self->create_merged_atom
    (
        'surfeature' => 'feature',
        'tagset'     => 'et::puudepank',
        'atoms'      => \@fatoms
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
    $fs->set_tagset('et::puudepank');
    my $atoms = $self->atoms();
    # Tag is the part of speech followed by a slash and the morphosyntactic features, separated by commas.
    # example: n/com,sg,nom
    # The 'pos' feature is ambiguous. For adjectives it is the positive degree.
    # For pronouns it is the possessive type.
    # We must disambiguate it before we decode each feature separately.
    $tag =~ s:^pron(-poss)?/pos:pron/poss:;
    my ($pos, $features) = split(/\//, $tag);
    # Two dashes are used if there are no features.
    $features = '' if($features eq '--');
    my @features = split(/,/, $features);
    $atoms->{pos}->decode_and_merge_hard($pos, $fs);
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
    my $pos = $atoms->{pos}->encode($fs);
    my $features = '--';
    my %feature_names =
    (
        'n'     => ['nountype', 'number', 'case'],
        'prop'  => ['nountype', 'number', 'case'],
        'aord'  => ['numtype', 'number', 'case', 'numform'],
        'apart' => ['degree', 'number', 'case', 'mood'],
        'adj'   => ['degree', 'number', 'case'],
        'prs'   => ['prontype', 'person', 'number', 'case'],
        'pron'  => ['prontype', 'number', 'case'],
        'num'   => ['numtype', 'number', 'case', 'numform'],
        'vinf'  => ['verbtype', 'mood'],
        'vpart' => ['verbtype', 'mood', 'tense', 'person', 'number', 'personal'],
        'vsup'  => ['verbtype', 'mood', 'person', 'number', 'personal', 'case'],
        'v'     => ['verbtype', 'mood', 'tense', 'person', 'number', 'personal', 'polarity'],
        'prp'   => ['adpostype', 'valcase'],
        'pst'   => ['adpostype', 'valcase'],
        'conj-c'=> ['conjtype'],
        'conj-s'=> ['conjtype'],
        'punc'  => ['punctype']
    );
    my $fpos = $pos;
    $fpos = 'aord'  if($fpos eq 'adj' && $fs->is_ordinal());
    $fpos = 'apart' if($fpos eq 'adj' && $fs->is_participle());
    $fpos = 'prs'   if($fpos eq 'pron' && $fs->is_personal_pronoun() && !$fs->is_possessive() && !$fs->is_reflexive());
    $fpos = 'vinf'  if($fpos eq 'v' && ($fs->is_infinitive() || $fs->is_gerund()));
    $fpos = 'vpart' if($fpos eq 'v' && ($fs->is_participle() || $fs->is_transgressive()));
    $fpos = 'vsup'  if($fpos eq 'v' && $fs->is_supine());
    my $feature_names = $feature_names{$fpos};
    $feature_names = [] unless(defined($feature_names));
    my @features = ();
    foreach my $feature (@{$feature_names})
    {
        my $value = $atoms->{$feature}->encode($fs);
        push(@features, $value) unless($value eq '');
    }
    if(@features)
    {
        $features = join(',', @features);
    }
    my $tag = "$pos/$features";
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus.
# 598 tags have been observed in the corpus.
# We removed some tags due to inconsistency between pos and features (e.g.
# conj-c/sub).
# Removed features:
# .cap, %cap ... the word starts with an uppercase letter
# .gi ... adjectives and nouns with the suffix '-gi' (rare feature)
# .ja, %ja ... words with suffix '-ja' (pakkujad, vabastaja)
# .janna ... words with suffix '-janna' (pekimägi-käskijanna)
# .ke ... words with suffix '-ke' (aiamajakese, sammukese, klaasikese)
# .lik ... words with suffix '-lik' (pidulikku)
# .line ... adjectives or nouns with suffix '-line', '-lis-' (mustavereline)
# .m ... adjectives; unknown meaning (rare feature; just one occurrence: väiksemagi)
# .mine, %mine ... nouns with suffix '-mis-' (rare feature; nõudmised, kurtmised)
# .nud, %nud ... words with suffix '-nud'
# .tav, %tav ... words with suffix '-tav' (laetav, väidetavasti)
# .tud, %tud ... words with suffix '-tud'
# .v, %v ... participial adjectives with suffix '-v', '-va-'
# .? ... undocumented feature with unknown meaning
# x? ... undocumented feature with unknown meaning (occurs with num/card,digit)
# ? ... undocumented feature with unknown meaning
# Subcategorization of verbs:
# .Intr, %Intr ... intransitive verb
# .Int, %Int ... verb subcategorization? another code for intransitive?
# .InfP, %InfP ... infinitive phrase
# .FinV, %FinV ... finite verb
# .NGP-P, %NGP-P ... verb subcategorization? for what?
# .Abl, %Abl ... noun phrase in ablative
# .All, %All ... noun phrase in allative
# .El, %El ... noun phrase in elative
# .Part, %Part ... noun phrase in partitive
# 252 tags survived.
# Then we added missing combinations of number+case (except for the additive
# case, whose usage is limited) for nominals and person+number for verbs.
# 614 total tags after the extension.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
abbr/--
adj-nat/--
adj/comp,pl,abes
adj/comp,pl,abl
adj/comp,pl,ad
adj/comp,pl,all
adj/comp,pl,el
adj/comp,pl,es
adj/comp,pl,gen
adj/comp,pl,ill
adj/comp,pl,in
adj/comp,pl,kom
adj/comp,pl,nom
adj/comp,pl,part
adj/comp,pl,term
adj/comp,pl,tr
adj/comp,sg,abes
adj/comp,sg,abl
adj/comp,sg,ad
adj/comp,sg,all
adj/comp,sg,el
adj/comp,sg,es
adj/comp,sg,gen
adj/comp,sg,ill
adj/comp,sg,in
adj/comp,sg,kom
adj/comp,sg,nom
adj/comp,sg,part
adj/comp,sg,term
adj/comp,sg,tr
adj/ord,pl,abes,l
adj/ord,pl,abl,l
adj/ord,pl,ad,l
adj/ord,pl,all,l
adj/ord,pl,el,l
adj/ord,pl,es,l
adj/ord,pl,gen,l
adj/ord,pl,ill,l
adj/ord,pl,in,l
adj/ord,pl,kom,l
adj/ord,pl,nom,l
adj/ord,pl,part,l
adj/ord,pl,term,l
adj/ord,pl,tr,l
adj/ord,sg,abes,l
adj/ord,sg,abl,l
adj/ord,sg,ad,l
adj/ord,sg,all,l
adj/ord,sg,el,l
adj/ord,sg,es,l
adj/ord,sg,gen,l
adj/ord,sg,ill,l
adj/ord,sg,in,l
adj/ord,sg,kom,l
adj/ord,sg,nom,l
adj/ord,sg,part,l
adj/ord,sg,term,l
adj/ord,sg,tr,l
adj/pos,pl,abes
adj/pos,pl,abes,partic
adj/pos,pl,abl
adj/pos,pl,abl,partic
adj/pos,pl,ad
adj/pos,pl,ad,partic
adj/pos,pl,all
adj/pos,pl,all,partic
adj/pos,pl,el
adj/pos,pl,el,partic
adj/pos,pl,es
adj/pos,pl,es,partic
adj/pos,pl,gen
adj/pos,pl,gen,partic
adj/pos,pl,ill
adj/pos,pl,ill,partic
adj/pos,pl,in
adj/pos,pl,in,partic
adj/pos,pl,kom
adj/pos,pl,kom,partic
adj/pos,pl,nom
adj/pos,pl,nom,partic
adj/pos,pl,part
adj/pos,pl,part,partic
adj/pos,pl,term
adj/pos,pl,term,partic
adj/pos,pl,tr
adj/pos,pl,tr,partic
adj/pos,sg,abes
adj/pos,sg,abes,partic
adj/pos,sg,abl
adj/pos,sg,abl,partic
adj/pos,sg,ad
adj/pos,sg,ad,partic
adj/pos,sg,adit
adj/pos,sg,all
adj/pos,sg,all,partic
adj/pos,sg,el
adj/pos,sg,el,partic
adj/pos,sg,es
adj/pos,sg,es,partic
adj/pos,sg,gen
adj/pos,sg,gen,partic
adj/pos,sg,ill
adj/pos,sg,ill,partic
adj/pos,sg,in
adj/pos,sg,in,partic
adj/pos,sg,kom
adj/pos,sg,kom,partic
adj/pos,sg,nom
adj/pos,sg,nom,partic
adj/pos,sg,part
adj/pos,sg,part,partic
adj/pos,sg,term
adj/pos,sg,term,partic
adj/pos,sg,tr
adj/pos,sg,tr,partic
adv/--
b/--
conj-c/crd
conj-s/sub
intj/--
n/com,pl,abes
n/com,pl,abl
n/com,pl,ad
n/com,pl,all
n/com,pl,el
n/com,pl,es
n/com,pl,gen
n/com,pl,ill
n/com,pl,in
n/com,pl,kom
n/com,pl,nom
n/com,pl,part
n/com,pl,term
n/com,pl,tr
n/com,sg,abes
n/com,sg,abl
n/com,sg,ad
n/com,sg,adit
n/com,sg,all
n/com,sg,el
n/com,sg,es
n/com,sg,gen
n/com,sg,ill
n/com,sg,in
n/com,sg,kom
n/com,sg,nom
n/com,sg,part
n/com,sg,term
n/com,sg,tr
num/card,digit
num/card,pl,abes,l
num/card,pl,abl,l
num/card,pl,ad,l
num/card,pl,all,l
num/card,pl,el,l
num/card,pl,es,l
num/card,pl,gen,l
num/card,pl,ill,l
num/card,pl,in,l
num/card,pl,kom,l
num/card,pl,nom,l
num/card,pl,part,l
num/card,pl,term,l
num/card,pl,tr,l
num/card,sg,abes,l
num/card,sg,abl,l
num/card,sg,ad,l
num/card,sg,adit,l
num/card,sg,all,l
num/card,sg,el,l
num/card,sg,es,l
num/card,sg,gen,l
num/card,sg,ill,l
num/card,sg,in,l
num/card,sg,kom,l
num/card,sg,nom,l
num/card,sg,part,l
num/card,sg,term,l
num/card,sg,tr,l
num/ord,digit
num/ord,pl,abes,l
num/ord,pl,abl,l
num/ord,pl,ad,l
num/ord,pl,all,l
num/ord,pl,el,l
num/ord,pl,es,l
num/ord,pl,gen,l
num/ord,pl,ill,l
num/ord,pl,in,l
num/ord,pl,kom,l
num/ord,pl,nom,l
num/ord,pl,part,l
num/ord,pl,term,l
num/ord,pl,tr,l
num/ord,sg,abes,l
num/ord,sg,abl,l
num/ord,sg,ad,l
num/ord,sg,adit,l
num/ord,sg,all,l
num/ord,sg,el,l
num/ord,sg,es,l
num/ord,sg,gen,l
num/ord,sg,ill,l
num/ord,sg,in,l
num/ord,sg,kom,l
num/ord,sg,nom,l
num/ord,sg,part,l
num/ord,sg,term,l
num/ord,sg,tr,l
pron/dem,pl,abes
pron/dem,pl,abl
pron/dem,pl,ad
pron/dem,pl,all
pron/dem,pl,el
pron/dem,pl,es
pron/dem,pl,gen
pron/dem,pl,ill
pron/dem,pl,in
pron/dem,pl,kom
pron/dem,pl,nom
pron/dem,pl,part
pron/dem,pl,term
pron/dem,pl,tr
pron/dem,sg,abes
pron/dem,sg,abl
pron/dem,sg,ad
pron/dem,sg,all
pron/dem,sg,el
pron/dem,sg,es
pron/dem,sg,gen
pron/dem,sg,ill
pron/dem,sg,in
pron/dem,sg,kom
pron/dem,sg,nom
pron/dem,sg,part
pron/dem,sg,term
pron/dem,sg,tr
pron/det,pl,abes
pron/det,pl,abl
pron/det,pl,ad
pron/det,pl,all
pron/det,pl,el
pron/det,pl,es
pron/det,pl,gen
pron/det,pl,ill
pron/det,pl,in
pron/det,pl,kom
pron/det,pl,nom
pron/det,pl,part
pron/det,pl,term
pron/det,pl,tr
pron/det,sg,abes
pron/det,sg,abl
pron/det,sg,ad
pron/det,sg,all
pron/det,sg,el
pron/det,sg,es
pron/det,sg,gen
pron/det,sg,ill
pron/det,sg,in
pron/det,sg,kom
pron/det,sg,nom
pron/det,sg,part
pron/det,sg,term
pron/det,sg,tr
pron/indef,pl,abes
pron/indef,pl,abl
pron/indef,pl,ad
pron/indef,pl,all
pron/indef,pl,el
pron/indef,pl,es
pron/indef,pl,gen
pron/indef,pl,ill
pron/indef,pl,in
pron/indef,pl,kom
pron/indef,pl,nom
pron/indef,pl,part
pron/indef,pl,term
pron/indef,pl,tr
pron/indef,sg,abes
pron/indef,sg,abl
pron/indef,sg,ad
pron/indef,sg,adit
pron/indef,sg,all
pron/indef,sg,el
pron/indef,sg,es
pron/indef,sg,gen
pron/indef,sg,ill
pron/indef,sg,in
pron/indef,sg,kom
pron/indef,sg,nom
pron/indef,sg,part
pron/indef,sg,term
pron/indef,sg,tr
pron/inter,pl,abes
pron/inter,pl,abl
pron/inter,pl,ad
pron/inter,pl,all
pron/inter,pl,el
pron/inter,pl,es
pron/inter,pl,gen
pron/inter,pl,ill
pron/inter,pl,in
pron/inter,pl,kom
pron/inter,pl,nom
pron/inter,pl,part
pron/inter,pl,term
pron/inter,pl,tr
pron/inter,sg,abes
pron/inter,sg,abl
pron/inter,sg,ad
pron/inter,sg,all
pron/inter,sg,el
pron/inter,sg,es
pron/inter,sg,gen
pron/inter,sg,ill
pron/inter,sg,in
pron/inter,sg,kom
pron/inter,sg,nom
pron/inter,sg,part
pron/inter,sg,term
pron/inter,sg,tr
pron/pers,ps1,pl,abes
pron/pers,ps1,pl,abl
pron/pers,ps1,pl,ad
pron/pers,ps1,pl,all
pron/pers,ps1,pl,el
pron/pers,ps1,pl,es
pron/pers,ps1,pl,gen
pron/pers,ps1,pl,ill
pron/pers,ps1,pl,in
pron/pers,ps1,pl,kom
pron/pers,ps1,pl,nom
pron/pers,ps1,pl,part
pron/pers,ps1,pl,term
pron/pers,ps1,pl,tr
pron/pers,ps1,sg,abes
pron/pers,ps1,sg,abl
pron/pers,ps1,sg,ad
pron/pers,ps1,sg,all
pron/pers,ps1,sg,el
pron/pers,ps1,sg,es
pron/pers,ps1,sg,gen
pron/pers,ps1,sg,ill
pron/pers,ps1,sg,in
pron/pers,ps1,sg,kom
pron/pers,ps1,sg,nom
pron/pers,ps1,sg,part
pron/pers,ps1,sg,term
pron/pers,ps1,sg,tr
pron/pers,ps2,pl,abes
pron/pers,ps2,pl,abl
pron/pers,ps2,pl,ad
pron/pers,ps2,pl,all
pron/pers,ps2,pl,el
pron/pers,ps2,pl,es
pron/pers,ps2,pl,gen
pron/pers,ps2,pl,ill
pron/pers,ps2,pl,in
pron/pers,ps2,pl,kom
pron/pers,ps2,pl,nom
pron/pers,ps2,pl,part
pron/pers,ps2,pl,term
pron/pers,ps2,pl,tr
pron/pers,ps2,sg,abes
pron/pers,ps2,sg,abl
pron/pers,ps2,sg,ad
pron/pers,ps2,sg,all
pron/pers,ps2,sg,el
pron/pers,ps2,sg,es
pron/pers,ps2,sg,gen
pron/pers,ps2,sg,ill
pron/pers,ps2,sg,in
pron/pers,ps2,sg,kom
pron/pers,ps2,sg,nom
pron/pers,ps2,sg,part
pron/pers,ps2,sg,term
pron/pers,ps2,sg,tr
pron/pers,ps3,pl,abes
pron/pers,ps3,pl,abl
pron/pers,ps3,pl,ad
pron/pers,ps3,pl,all
pron/pers,ps3,pl,el
pron/pers,ps3,pl,es
pron/pers,ps3,pl,gen
pron/pers,ps3,pl,ill
pron/pers,ps3,pl,in
pron/pers,ps3,pl,kom
pron/pers,ps3,pl,nom
pron/pers,ps3,pl,part
pron/pers,ps3,pl,term
pron/pers,ps3,pl,tr
pron/pers,ps3,sg,abes
pron/pers,ps3,sg,abl
pron/pers,ps3,sg,ad
pron/pers,ps3,sg,all
pron/pers,ps3,sg,el
pron/pers,ps3,sg,es
pron/pers,ps3,sg,gen
pron/pers,ps3,sg,ill
pron/pers,ps3,sg,in
pron/pers,ps3,sg,kom
pron/pers,ps3,sg,nom
pron/pers,ps3,sg,part
pron/pers,ps3,sg,term
pron/pers,ps3,sg,tr
pron/pos,pl,abes
pron/pos,pl,abl
pron/pos,pl,ad
pron/pos,pl,all
pron/pos,pl,el
pron/pos,pl,es
pron/pos,pl,gen
pron/pos,pl,ill
pron/pos,pl,in
pron/pos,pl,kom
pron/pos,pl,nom
pron/pos,pl,part
pron/pos,pl,term
pron/pos,pl,tr
pron/pos,sg,abes
pron/pos,sg,abl
pron/pos,sg,ad
pron/pos,sg,all
pron/pos,sg,el
pron/pos,sg,es
pron/pos,sg,gen
pron/pos,sg,ill
pron/pos,sg,in
pron/pos,sg,kom
pron/pos,sg,nom
pron/pos,sg,part
pron/pos,sg,term
pron/pos,sg,tr
pron/rec,sg,all
pron/refl,pl,abes
pron/refl,pl,abl
pron/refl,pl,ad
pron/refl,pl,all
pron/refl,pl,el
pron/refl,pl,es
pron/refl,pl,gen
pron/refl,pl,ill
pron/refl,pl,in
pron/refl,pl,kom
pron/refl,pl,nom
pron/refl,pl,part
pron/refl,pl,term
pron/refl,pl,tr
pron/refl,sg,abes
pron/refl,sg,abl
pron/refl,sg,ad
pron/refl,sg,all
pron/refl,sg,el
pron/refl,sg,es
pron/refl,sg,gen
pron/refl,sg,ill
pron/refl,sg,in
pron/refl,sg,kom
pron/refl,sg,nom
pron/refl,sg,part
pron/refl,sg,term
pron/refl,sg,tr
pron/rel,pl,abes
pron/rel,pl,abl
pron/rel,pl,ad
pron/rel,pl,all
pron/rel,pl,el
pron/rel,pl,es
pron/rel,pl,gen
pron/rel,pl,ill
pron/rel,pl,in
pron/rel,pl,kom
pron/rel,pl,nom
pron/rel,pl,part
pron/rel,pl,term
pron/rel,pl,tr
pron/rel,sg,abes
pron/rel,sg,abl
pron/rel,sg,ad
pron/rel,sg,all
pron/rel,sg,el
pron/rel,sg,es
pron/rel,sg,gen
pron/rel,sg,ill
pron/rel,sg,in
pron/rel,sg,kom
pron/rel,sg,nom
pron/rel,sg,part
pron/rel,sg,term
pron/rel,sg,tr
prop/prop,pl,abes
prop/prop,pl,abl
prop/prop,pl,ad
prop/prop,pl,all
prop/prop,pl,el
prop/prop,pl,es
prop/prop,pl,gen
prop/prop,pl,ill
prop/prop,pl,in
prop/prop,pl,kom
prop/prop,pl,nom
prop/prop,pl,part
prop/prop,pl,term
prop/prop,pl,tr
prop/prop,sg,abes
prop/prop,sg,abl
prop/prop,sg,ad
prop/prop,sg,adit
prop/prop,sg,all
prop/prop,sg,el
prop/prop,sg,es
prop/prop,sg,gen
prop/prop,sg,ill
prop/prop,sg,in
prop/prop,sg,kom
prop/prop,sg,nom
prop/prop,sg,part
prop/prop,sg,term
prop/prop,sg,tr
prp/pre
prp/pre,.el
prp/pre,.gen
prp/pre,.kom
prp/pre,.part
pst/post
pst/post,.el
pst/post,.gen
pst/post,.nom
pst/post,.part
punc/--
punc/Com
punc/Exc
punc/Fst
punc/Int
v/aux,cond,pres,ps,af
v/aux,cond,pres,ps,neg
v/aux,indic,impf,ps1,pl,ps,af
v/aux,indic,impf,ps1,sg,ps,af
v/aux,indic,impf,ps2,pl,ps,af
v/aux,indic,impf,ps2,sg,ps,af
v/aux,indic,impf,ps3,pl,ps,af
v/aux,indic,impf,ps3,sg,ps,af
v/aux,indic,pres,ps,neg
v/aux,indic,pres,ps1,pl,ps,af
v/aux,indic,pres,ps1,sg,ps,af
v/aux,indic,pres,ps2,pl,ps,af
v/aux,indic,pres,ps2,sg,ps,af
v/aux,indic,pres,ps3,pl,ps,af
v/aux,indic,pres,ps3,sg,ps,af
v/main,cond,past,imps,af
v/main,cond,past,ps,af
v/main,cond,pres,imps,af
v/main,cond,pres,ps,neg
v/main,cond,pres,ps1,pl,ps,af
v/main,cond,pres,ps1,sg,ps,af
v/main,cond,pres,ps2,pl,ps,af
v/main,cond,pres,ps2,sg,ps,af
v/main,cond,pres,ps3,pl,ps,af
v/main,cond,pres,ps3,sg,ps,af
v/main,ger
v/main,imper,pres,ps1,pl,ps,af
v/main,imper,pres,ps1,sg,ps,af
v/main,imper,pres,ps2,pl,ps,af
v/main,imper,pres,ps2,sg,ps,af
v/main,imper,pres,ps3,pl,ps,af
v/main,imper,pres,ps3,sg,ps,af
v/main,indic,impf,imps,af
v/main,indic,impf,imps,neg
v/main,indic,impf,ps,neg
v/main,indic,impf,ps1,pl,ps,af
v/main,indic,impf,ps1,sg,ps,af
v/main,indic,impf,ps2,pl,ps,af
v/main,indic,impf,ps2,sg,ps,af
v/main,indic,impf,ps3,pl,ps,af
v/main,indic,impf,ps3,sg,ps,af
v/main,indic,pres,imps,af
v/main,indic,pres,ps,neg
v/main,indic,pres,ps1,pl,ps,af
v/main,indic,pres,ps1,sg,ps,af
v/main,indic,pres,ps2,pl,ps,af
v/main,indic,pres,ps2,sg,ps,af
v/main,indic,pres,ps3,pl,ps,af
v/main,indic,pres,ps3,sg,ps,af
v/main,inf
v/main,partic,past,imps
v/main,partic,past,ps
v/main,quot,pres,ps,af
v/main,sup,ps,abes
v/main,sup,ps,el
v/main,sup,ps,ill
v/main,sup,ps,in
v/mod,cond,pres,ps,neg
v/mod,cond,pres,ps1,pl,ps,af
v/mod,cond,pres,ps1,sg,ps,af
v/mod,cond,pres,ps2,pl,ps,af
v/mod,cond,pres,ps2,sg,ps,af
v/mod,cond,pres,ps3,pl,ps,af
v/mod,cond,pres,ps3,sg,ps,af
v/mod,indic,impf,ps,neg
v/mod,indic,impf,ps1,pl,ps,af
v/mod,indic,impf,ps1,sg,ps,af
v/mod,indic,impf,ps2,pl,ps,af
v/mod,indic,impf,ps2,sg,ps,af
v/mod,indic,impf,ps3,pl,ps,af
v/mod,indic,impf,ps3,sg,ps,af
v/mod,indic,pres,ps,neg
v/mod,indic,pres,ps1,pl,ps,af
v/mod,indic,pres,ps1,sg,ps,af
v/mod,indic,pres,ps2,pl,ps,af
v/mod,indic,pres,ps2,sg,ps,af
v/mod,indic,pres,ps3,pl,ps,af
v/mod,indic,pres,ps3,sg,ps,af
x/--
end_of_list
    ;
    # Protect from editors that replace tabs by spaces.
    $list =~ s/[ \t]+/\t/sg;
    my @list = split(/\r?\n/, $list);
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::ET::Puudepank - Driver for the Estonian tagset from the Eesti keele puudepank (Estonian Language Treebank).

=head1 VERSION

version 3.008

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::ET::Puudepank;
  my $driver = Lingua::Interset::Tagset::ET::Puudepank->new();
  my $fs = $driver->decode('n/com,sg,nom');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('et::puudepank', 'n/com,sg,nom');

=head1 DESCRIPTION

Interset driver for the Estonian tagset from the Eesti keele puudepank (Estonian Language Treebank).
Tag is the part of speech followed by a slash and the morphosyntactic features, separated by commas.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
