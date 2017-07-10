# ABSTRACT: Driver for the tagset of the Basque Dependency Treebank in the CoNLL format.
# Copyright © 2011, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Copyright © 2011 Loganathan Ramasamy <ramasamy@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::EU::Conll;
use strict;
use warnings;
our $VERSION = '3.005';

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
    return 'eu::conll';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
# DZ: I could not find any documentation of the tagset. I found some Spanish
# description of Basque morphology, which I could understand, and the English
# Wikipedia. But the codes of features are derived from Basque terms, and it
# is difficult to use on-line translation to translate them if we don't know
# the full terms. A grammar book written in Basque could help, see e.g. here:
# http://www.euskaltzaindia.net/dok/iker_jagon_tegiak/24569.pdf
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
            # adberbiboa = adverb
            # arrunt = common
            # common adverb: gaurko = today, samar = relatively, lehenbiziko = first
            "ADB\tARR" => ['pos' => 'adv'],
            # galdera = question
            # interrogative adverb: nola = how, zergatik = why, noraino = to what extent, non = where, noiz = when
            "ADB\tGAL" => ['pos' => 'adv', 'prontype' => 'int'],

            # aditz = verb
            # SIN: I don't know what SIN stands for but it is not "sintetiko": unlike ADK, ADL and ADT, words tagged SIN do not have the full paradigm (e.g. including the NORK feature).
            # Synthetic verbs are also called "aditz trinkoak" (compact verbs) and they are tagged ADT.
            # most frequent ADI SIN lemmas: izan, egin, eman, jokatu, esan, lortu, irabazi, hartu, hasi, ikusi
            # most frequent ADI SIN forms: izan, egin, izango, esan, egiten, eman, irabazi, jokatu, lortu, hasi
            # My hypothesis: ADI SIN are non-finite verb forms used (together with a finite auxiliary) in periphrastic tenses.
            # Both synthetic and analytic verbs have their non-finite forms tagged ADI SIN (for example, "izan" is a synthetic verb, "hartu" is not).
            "ADI\tSIN" => ['pos' => 'verb'],
            # konposatu = compound
            # compound verbs, i.e. light verb constructions: bizi_izan = live, nahi_izan = want, atzera_egin = retract, amore_eman = give up
            "ADI\tADK" => ['pos' => 'verb', 'other' => {'verbtype' => 'compound'}],
            # ADP is very rare. The lemma always has many other forms which are ADK instead of ADP. Hypothesis: ADP marks the lexical part of a compound verb
            # if the verbal part (auxiliary) is missing.
            # (merezi = worth; lemma: merezi_izan = be worth)
            "ADI\tADP" => ['pos' => 'verb', 'other' => {'verbtype' => 'part_of_compound'}],
            # factitive verb: adierazi = say, jakinarazi = report, ikustarazi = display
            # (Some sources say that "factitive" = "causative", but based on the above Google-translated examples, I am not sure that this is the case.)
            "ADI\tFAK" => ['pos' => 'verb', 'other' => {'verbtype' => 'factitive'}],
            # ADI_IZEELI seems to be a noun phrase derived from a verb: gertatu = happen, gertatutakoa = the one that happened.
            # esandakoa (lemma esan = say), gertatutakoa (gertatu = happen), ezarritakoa (ezarri = establish), jasotakoa (jaso = receive), deitutakoa (so-called; deitu = call)
            # Wikipedia, Basque verb: Participle + -tako (dako) ... adjectival (= non-finite relative). Examples: ikusitako, egindako, hartutako, hildako.
            # Zuk ikusitako gizona itsua da.
            # 'The man you saw (= seen by you) is blind.'
            # [you.ERGATIVE see.PARTICIPLE-tako man blind is]
            "ADI\tADI_IZEELI" => ['pos' => 'verb', 'other' => {'verbtype' => 'tako'}],

            # auxiliary verb (izan, *edin, ukan, *edun, *ezan)
            # laguntzailearen = auxiliary
            "ADL\tADL" => ['pos' => 'verb', 'verbtype' => 'aux'],
            # ADL IZEELI seems to be an auxiliary verb in a nominal form, whatever that means.
            "ADL\tADL_IZEELI" => ['pos' => 'verb', 'verbtype' => 'aux', 'other' => {'verbform' => 'nominal'}],
            # aditz trinkoa = compact verb (also called synthetic verb)
            # Only a few Basque verbs can be conjugated synthetically, i.e. they have finite forms.
            # The rest have only non-finite forms, which enter into compound tenses (non-finite main verb + finite auxiliary).
            # examples: joan = go, egon = be, izan = be, jakin = know
            # most frequent ADT ADT lemmas: izan, ukan, egon, eduki, jakin, esan, etorri, joan, ibili, iruditu
            # most frequent ADT ADT forms: da, dela, dago, dira, du, zen, zegoen, daude, dute, zuen
            # most frequent ADI SIN lemmas: izan, egin, eman, jokatu, esan, lortu, irabazi, hartu, hasi, ikusi
            # most frequent ADI SIN forms: izan, egin, izango, esan, egiten, eman, irabazi, jokatu, lortu, hasi
            # Full paradigm (e.g. including the NORK feature) is found only with ADI ADK, ADL ADL, ADT ADT. But not with ADI SIN!
            "ADT\tADT" => ['pos' => 'verb', 'verbform' => 'fin', 'other' => {'verbtype' => 'synthetic'}],
            # ADT IZEELI seems to be a synthetic verb in a nominal form, whatever that means.
            "ADT\tADT_IZEELI" => ['pos' => 'verb', 'verbform' => 'fin', 'other' => {'verbtype' => 'synthetic', 'verbform' => 'nominal'}],
            # [error?] (there is only one occurrence: Bear_Zana)
            "ADT\tARR" => ['pos' => 'verb'],

            # adjektiboa = adjective (nondik_norakoa)
            # This tag is probably error. It should be ADJ ARR.
            "ADJ\tADJ" => ['pos' => 'adj'],
            # arrunt adjektiboa = common adjective (errusiar = Russian, atzerritar = foreign, gustuko = tasteful, britainiar = British, ageriko = visible)
            "ADJ\tARR" => ['pos' => 'adj'],
            # (aldi_bereko = at the same time, simultaneous)
            "ADJ\tERKIND" => ['pos' => 'adj'],
            # adjektiboa, galdera = adjective, question
            # There are also interrogative determiners (DET NOLGAL) and I do not know how the borderline is defined.
            # ADJ GAL: nolako = what, zer-nolako = what, nolakoa = what, nongoa = where of
            # DET NOLGAL: zein = which, zer = what, zenbat = how many
            "ADJ\tGAL" => ['pos' => 'adj', 'prontype' => 'int', 'other' => {'determiner' => 'no'}],
            # adjective [error?] (ongi_etorria = welcome to)
            "ADJ\tSIN" => ['pos' => 'adj'],

            # determiner, quantifier, distributive = banatu (bana = one each, 6na, 25na, bedera = at least, bina = two)
            "DET\tBAN" => ['pos' => 'num', 'numtype' => 'dist'],
            # determiner, quantifier, indefinite = determinatzaile, zenbaki, zehaztugabe
            # (asko = many, ugari = many, gehiago = more, gehien = most, hainbeste = so many, gutxi = few, gutxien = least, gutxiagorako = for less, nahikoa = enough)
            "DET\tDZG" => ['pos' => 'num', 'numtype' => 'card', 'prontype' => 'ind'],
            # determiner, quantifier, definite = determinatzaile, zenbaki, zehatz
            # (bat = one, bi = two, hiru = three, lau = four, bost = five, 19:00, %72,46, 10, 2-3)
            "DET\tDZH" => ['pos' => 'num', 'numtype' => 'card'],
            # determiner, demonstrative, common = determinatzaile, erakusleak, arrunt
            # (hori = that, hau = this, hura = he/she/it)
            "DET\tERKARR" => ['pos' => 'adj', 'prontype' => 'dem'],
            # determiner, demonstrative, emphatic/strong = determinatzaile, erakusleak, indartsu
            # (bera = the same) ###!!! ??? reflexive ???
            "DET\tERKIND" => ['pos' => 'adj', 'prontype' => 'dem', 'reflex' => 'yes'],
            # determiner, indefinite common
            # (edozein = anything, ezein = none, zernahi = whatever)
            "DET\tNOLARR" => ['pos' => 'adj', 'prontype' => 'ind|neg'],
            # determiner, indefinite question
            # There are also interrogative adjectives (ADJ GAL) and I do not know how the borderline is defined.
            # ADJ GAL: nolako = what, zer-nolako = what, nolakoa = what, nongoa = where of
            # DET NOLGAL: zein = which, zer = what, zenbat = how many
            "DET\tNOLGAL" => ['pos' => 'adj', 'prontype' => 'int'],
            # determiner, ordinal = determinatzaile, ordinal
            # (lehen = first, aurren = first, bigarren = second, hirugarren = third, azken = last)
            "DET\tORD" => ['pos' => 'adj', 'numtype' => 'ord'],
            # determiner, general/total
            # (oro = every, guzti = all, dena = everything)
            "DET\tORO" => ['pos' => 'adj', 'prontype' => 'tot'],

            # pronoun, personal common = izenordain, pertsonal arrunt
            # (ni = I, hi = thou, hura = he/she/it, gu = we, zu, zuek = you, haiek = they)
            "IOR\tPERARR" => ['pos' => 'noun', 'prontype' => 'prs'],
            # pronoun, personal emphatic/strong = izenordain, pertsonal indartsu
            # (neu, heu, geu, zeu)
            "IOR\tPERIND" => ['pos' => 'noun', 'prontype' => 'prs', 'variant' => 1],
            # pronoun, reciprocal = izenordain, ...
            # (elkar = each other)
            "IOR\tELK" => ['pos' => 'noun', 'prontype' => 'rcp'],
            # pronoun, question = izenordain, galdera
            # (nor = who)
            "IOR\tIZGGAL" => ['pos' => 'noun', 'prontype' => 'int'],
            # pronoun, indefinite = izenordain, mugagabea
            # (ezer = nothing, zerbait = something/anything, inor = anyone/none, zertxobait = somewhat, norbait = someone, edonor = anyone)
            "IOR\tIZGMGB" => ['pos' => 'noun', 'prontype' => 'ind|neg'],

            # izenak = nombres = nouns
            # noun, common = izen, arrunt
            # (gizona = man, jokalaria = player, txapelduna = champion)
            # (partidua = player, aukera = opportunity, taldea = group, garaipena = victory, beharra = need)
            "IZE\tARR" => ['pos' => 'noun', 'nountype' => 'com'],
            # proper noun = izen egokia (besides ENT:Pertsona, there are also ENT:Erakundea and ENT:Tokia)
            # IZE IZB ENT:Pertsona (Juan, Miguel, Javier, Carlos, Guzman)
            # IZE IZB PLU:-|KAS:ABS|NUM:S|MUG:M (Olano, Perez, Mendizabal, Ganix, Tauziat)
            # IZE IZB PLU:-|KAS:ABS|NUM:S|MUG:M|ENT:Pertsona (Andreas, Jontxu, Milosevic, Eli, Arafat)
            "IZE\tIZB" => ['pos' => 'noun', 'nountype' => 'prop'],
            # place name? (besides ENT:Tokia, there are also ENT:Erakundea and ENT:Pertsona)
            # IZE LIB PLU:-|KAS:ABS|NUM:S|MUG:M|ENT:Tokia (Frantzia, Bizkaia, Errusia, Zaragoza, Gipuzkoa)
            # IZE LIB PLU:+|KAS:ABS|NUM:P|MUG:M|ENT:Tokia (Bahamak, Molukak, Filipinak)
            "IZE\tLIB" => ['pos' => 'noun', 'nountype' => 'prop', 'variant' => '1'],
            # izen = noun, adverbial (adverb with nominal inflection)
            # (atzokoa = yesterday, kontrakoa = opposite, gaurkoa = present, araberakoa = depending on, biharkoa = tomorrow)
            "IZE\tADB_IZEELI" => ['pos' => 'noun', 'other' => {'derfrompos' => 'adv'}],
            # izen = noun, adjectival (adjective with nominal inflection)
            # (handikoa = high, hutsezkoa = empty, nagusietakoa = main, agortezinezkoa = inexhaustible, txikikoa = low)
            "IZE\tADJ_IZEELI" => ['pos' => 'noun', 'other' => {'derfrompos' => 'adj'}],
            # izen = noun, determinal (determiner with nominal inflection)
            # (batena = one, batekoa = one, berea = percent, guztiona = everyone, berekoa = the same)
            "IZE\tDET_IZEELI" => ['pos' => 'noun', 'other' => {'derfrompos' => 'det'}],
            # izen = noun, pronominal
            # This tag is rare because most pronouns already have nominal inflection. Only the independent forms of possessive pronouns fall here.
            # (nirea = mine, geurea = ours, zuena = yours)
            "IZE\tIOR_IZEELI" => ['pos' => 'noun', 'prontype' => 'prs', 'poss' => 'yes'],
            # izen = noun, denominal (noun with secondary nominal inflection after the -ko (locative genitive) suffix)
            # For example, "maila" = "degree, level"; "mailak" = "degrees, levels"; "mailako", "mailakoa" = "level", "mailakoak" = "levels".
            # alde = side, aldekoa = supporter, fan
            # (mailakoa = level, aldekoa = fan, pezetakoa = peseta, artekoa = art, beharrekoa = necessity)
            "IZE\tIZE_IZEELI" => ['pos' => 'noun', 'other' => {'derfrompos' => 'noun'}],
            # izen, zenbaki = noun, number (name of number, number with nominal inflection)
            # (biak = two, hiruak = three, hamabiak = twelve, 22raino = until 22, 1996tik = since 1996)
            "IZE\tZKI" => ['pos' => 'noun', 'numtype' => 'card'],

            # interjection, [error?]
            "ITJ\tARR" => ['pos' => 'int'],
            # interjekzioa = interjection (beno, ha, tira, dzast, ea)
            "ITJ\tITJ" => ['pos' => 'int'],
            # conjunction
            # LOT JNT ERL:AURK (baina = but, baino = than, baizik = rather)
            # LOT JNT ERL:EMEN (eta = and, baita = as well as, bainan = but)
            # LOT JNT ERL:HAUT (edo = or, zein = or, ala = or, edota = or, nahiz = though)
            # (baina = but, baino = than, izan_ezik = except for, ez_baina = but not, eta = and, baita = and, ezta = or, ez_ezik = in addition to, baita_ere = also, edo = or, zein = and, ala = or, edota = or, nahiz = and)
            "LOT\tJNT" => ['pos' => 'conj', 'conjtype' => 'coor'],
            # connector (DZ: are LOT LOK reserved for joining clauses, while LOT JNT was for non-clausal phrases?)
            # LOT LOK ERL:AURK (berriz = whereas, ordea = however, ostera = however, aldiz)
            # LOT LOK ERL:BALD (baldin = if, orohar = in general)
            # LOT LOK ERL:DENB (harik eta = until)
            # LOT LOK ERL:EMEN (ere = also, bestalde = on the other hand, gainera = also, halaber = as well as, behintzat = unless)
            # LOT LOK ERL:ESPL (alegia = which, hots = namely)
            # LOT LOK ERL:HAUT (bestela = otherwise, osterantzean = otherwise, gainerakoan = the rest)
            # LOT LOK ERL:KAUS (ezen = because)
            # LOT LOK ERL:KONT (nahiz = or, though, even)
            # LOT LOK ERL:MOD  (alde batetik = on the one hand, alde batera = aside, oro har = in general, besterik gabe = simply)
            # LOT LOK ERL:ONDO (beraz = therefore, orduan = when, hortaz = therefore, ba, horrenbestez = thus, hence)
            "LOT\tLOK" => ['pos' => 'conj', 'conjtype' => 'sub'],
            # subordinating conjunction = lokarri menperatzaileak? But some of the examples below do not look like subordinating conjunctions.
            # LOT MEN ERL:DENB (eta gero = and then)
            # LOT MEN ERL:KAUS (eta = and)
            # LOT MEN ERL:KONT (arren = although, despite)
            "LOT\tMEN" => ['pos' => 'conj', 'conjtype' => 'sub', 'other' => {'conjtype' => 'men'}],
            # partikula = particle (ez, ezetz = no/not, bai, baietz = yes, al = to, ote = whether, omen = it seems)
            "PRT\tPRT" => ['pos' => 'part'],

            # bereiz = separator (", (, ), -, », «, /, ', *, [, ], +, `)
            "BEREIZ\tBEREIZ"             => ['pos' => 'punc'],
            # punt marka = punctuation (, . ... ! ? : ;)
            "PUNT_MARKA\tPUNT_BI_PUNT"   => ['pos' => 'punc', 'punctype' => 'colo'], # :
            "PUNT_MARKA\tPUNT_ESKL"      => ['pos' => 'punc', 'punctype' => 'excl'], # !
            "PUNT_MARKA\tPUNT_GALD"      => ['pos' => 'punc', 'punctype' => 'qest'], # ?
            "PUNT_MARKA\tPUNT_PUNT"      => ['pos' => 'punc', 'punctype' => 'peri'], # .
            "PUNT_MARKA\tPUNT_HIRU"      => ['pos' => 'punc', 'punctype' => 'peri', 'other' => {'punctype' => 'ellipsis'}], # ... (hiru puntu = three dots)
            "PUNT_MARKA\tPUNT_KOMA"      => ['pos' => 'punc', 'punctype' => 'comm'], # ,
            "PUNT_MARKA\tPUNT_PUNT_KOMA" => ['pos' => 'punc', 'punctype' => 'semi'], # ;

            # relation = erlazio
            # Is this an error? There are only three occurrences of the word "bait" (because, since). But the word does not occur with any other tag.
            "ERL\tERL" => ['pos' => 'conj', 'conjtype' => 'sub'],
            # HAOS: 40 occurrences, 36 of which go to the word "ari".
            # It is a special verb, meaning "be engaged in", used to form progressive periphrases.
            # http://books.google.cz/books?id=Kss999lxKm0C&pg=PA287&lpg=PA287&dq=ari+basque&source=bl&ots=J3K8bKW9TT&sig=t11oLSyx76b8AhtZMufo-SVrpL4&hl=cs&sa=X&ei=vDxnVNiaCePiywOsoIKQAw&ved=0CEkQ6AEwCQ#v=onepage&q=ari%20basque&f=false
            # A Grammar of Basque (ed. José Ignacio Hualde, Jon Ortiz de Irbina), p. 285
            # Section 3.5.5.1 Progressive periphrases, 3.5.5.1.1 The ari construction
            # Example:
            # lanean/lanari     ari        da
            # work.LOC/work.DAT engaged-in is
            # he/she is working
            # I have removed HAOS from the list of known tags because it is not clear what it means and how it is used.
            # However, we can still partially decode it, based on the verb "ari".
            "HAOS\tHAOS" => ['pos' => 'verb', 'verbform' => 'part'], # (ari, komeni, berrogoita, hogeita)

            # beste = other (eta_abar = etc.)
            "BST\tARR" => [],
            # beste = other (baino = than, de = of, ohi = usually, ea = whether, ezta = or)
            "BST\tBST" => [],
            # other, indefinite (ez_beste, ez_besterik = only, no other)
            "BST\tDZG" => [],

        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { 'prs' => { 'poss' => { 'yes' => "IZE\tIOR_IZEELI",
                                                                          '@'    => { 'variant' => { '1' => "IOR\tPERIND",
                                                                                                     '@' => "IOR\tPERARR" }}}},
                                                   'rcp' => "IOR\tELK",
                                                   'int' => "IOR\tIZGGAL",
                                                   'ind' => "IOR\tIZGMGB",
                                                   'neg' => "IOR\tIZGMGB",
                                                   '@'   => { 'nountype' => { 'prop' => { 'variant' => { '1' => "IZE\tLIB",
                                                                                                         '@' => "IZE\tIZB" }},
                                                                              '@'    => { 'numtype' => { 'card' => "IZE\tZKI",
                                                                                                         '@'    => { 'other/derfrompos' => { 'adv'  => "IZE\tADB_IZEELI",
                                                                                                                                             'adj'  => "IZE\tADJ_IZEELI",
                                                                                                                                             'det'  => "IZE\tDET_IZEELI",
                                                                                                                                             'noun' => "IZE\tIZE_IZEELI",
                                                                                                                                             '@'    => "IZE\tARR" }}}}}}}},
                       'adj'  => { 'prontype' => { 'dem' => { 'reflex' => { 'yes' => "DET\tERKIND",
                                                                            '@'      => "DET\tERKARR" }},
                                                   'int' => { 'other/determiner' => { 'no' => "ADJ\tGAL",
                                                                                      '@'  => "DET\tNOLGAL" }},
                                                   'ind' => "DET\tNOLARR",
                                                   'neg' => "DET\tNOLARR",
                                                   'tot' => "DET\tORO",
                                                   '@'   => { 'numtype' => { 'ord' => "DET\tORD",
                                                                             '@'   => "ADJ\tARR" }}}},
                       'num'  => { 'numtype' => { 'dist' => "DET\tBAN",
                                                  '@'    => { 'prontype' => { 'ind' => "DET\tDZG",
                                                                              '@'   => "DET\tDZH" }}}},
                       'verb' => { 'verbtype' => { 'aux' => { 'other/verbform' => { 'nominal' => "ADL\tADL_IZEELI",
                                                                                    '@'       => "ADL\tADL" }},
                                                   '@'   => { 'other/verbtype' => { 'compound'         => "ADI\tADK",
                                                                                    'part_of_compound' => "ADI\tADP",
                                                                                    'factitive'        => "ADI\tFAK",
                                                                                    'tako'             => "ADI\tADI_IZEELI",
                                                                                    '@'                => { 'verbform' => { 'fin' => { 'other/verbform' => { 'nominal' => "ADT\tADT_IZEELI",
                                                                                                                                                             '@'       => "ADT\tADT" }},
                                                                                                                            '@'   => "ADI\tSIN" }}}}}},
                       'adv'  => { 'prontype' => { 'int' => "ADB\tGAL",
                                                   '@'   => "ADB\tARR" }},
                       'conj' => { 'conjtype' => { 'coor' => "LOT\tJNT",
                                                   'sub'  => { 'other/conjtype' => { 'men' => "LOT\tMEN",
                                                                                     '@'   => "LOT\tLOK" }}}},
                       'part' => "PRT\tPRT",
                       'int'  => "ITJ\tITJ",
                       'punc' => { 'punctype' => { 'colo' => "PUNT_MARKA\tPUNT_BI_PUNT",
                                                   'excl' => "PUNT_MARKA\tPUNT_ESKL",
                                                   'qest' => "PUNT_MARKA\tPUNT_GALD",
                                                   'peri' => { 'other/punctype' => { 'ellipsis' => "PUNT_MARKA\tPUNT_HIRU",
                                                                                     '@'        => "PUNT_MARKA\tPUNT_PUNT" }},
                                                   'comm' => "PUNT_MARKA\tPUNT_KOMA",
                                                   'semi' => "PUNT_MARKA\tPUNT_PUNT_KOMA",
                                                   '@'    => "BEREIZ\tBEREIZ" }},
                       '@'    => "BST\tBST" }
        }
    );
    # NAMED ENTITY TYPE ####################
    $atoms{ENT} = $self->create_simple_atom
    (
        'intfeature' => 'nametype',
        'simple_decode_map' =>
        {
            # person: Andreas, Jontxu, Milosevic, Eli, Arafat
            'Pertsona'  => 'prs',
            # place: Frantzia, Bizkaia, Errusia, Zaragoza, Gipuzkoa
            'Tokia'     => 'geo',
            # organization: Parlamentu_Federala, Aginte_Nazionala, Erresuma_Batua, Eliza_Ortodoxoa, Hidroelektrikoa
            'Erakundea' => 'com',
            # unknown or miscellaneous
            '???'       => 'oth'
        }
    );
    # ABBREVIATION TYPE ####################
    $atoms{MTKAT} = $self->create_atom
    (
        'surfeature' => 'nametype',
        'decode_map' =>
        {
            # laburdura = abbreviation: etab = etc., g.e., H.G.
            'LAB' => ['other' => {'abbrtype' => 'abbr'}],
            # abbreviated names of organizations: EAJ, ELA, CSU, EH, EHE
            'SIG' => ['other' => {'abbrtype' => 'org'}],
            # measure units: Kw, m, km, cm, kg
            'SNB' => ['other' => {'abbrtype' => 'measure'}]
        },
        'encode_map' =>
        {
            'other/abbrtype' => { 'abbr'    => 'LAB',
                                  'org'     => 'SIG',
                                  'measure' => 'SNB' }
        }
    );
    # IZAUR ####################
    # IZAUR is a binary feature that applies mostly to adjectives.
    # Its meaning is unknown: no documentation of the tagset is available and I have not been able to decipher this one.
    # IZAUR:+ applies predominantly but not exclusively to nationalities (errusiar = Russian).
    # Could IZAUR:- be a quality while + would be membership in a group?
    $atoms{IZAUR} = $self->create_atom
    (
        'surfeature' => 'izaur',
        'decode_map' =>
        {
            '+' => ['other' => {'izaur' => 'yes'}],
            '-' => ['other' => {'izaur' => 'no'}]
        },
        'encode_map' =>
        {
            'other/izaur' => { 'yes' => '+',
                               'no'  => '-' }
        }
    );
    # ANIMACY ####################
    # animados = bizidunak
    # inanimados = bizigabeak
    $atoms{BIZ} = $self->create_simple_atom
    (
        'intfeature' => 'animacy',
        'simple_decode_map' =>
        {
            # lagun, jokalari, pertsona, jabe, nagusi
            '+' => 'anim',
            # urte, arte, gain, ezin, behar
            '-' => 'inan'
        }
    );
    # COUNTABILITY ####################
    # zenbakarri = countable
    $atoms{ZENB} = $self->create_atom
    (
        'surfeature' => 'zenb',
        'decode_map' =>
        {
            '-' => ['other' => {'countable' => 'no'}]
        },
        'encode_map' =>
        {
            'other/countable' => { 'no' => '-' }
        }
    );
    # NEUR??? ####################
    ###!!! I don't know what this feature means but the sets of words with NEUR:- and with ZENB:- are almost identical (only three outlying occurrences).
    ###!!! There are no + values explicitly marked neither for NEUR nor for ZENB.
    $atoms{NEUR} = $self->create_atom
    (
        'surfeature' => 'neur',
        'decode_map' =>
        {
            '-' => ['other' => {'countable' => 'no'}]
        },
        'encode_map' =>
        {
            'other/countable' => { 'no' => '-' }
        }
    );
    # PLURAL-ONLY ####################
    # This feature marks pluralia tantum. The + value occurs almost exclusively with named entities, e.g. Estatu_Batuak (United States).
    $atoms{PLU} = $self->create_atom
    (
        'surfeature' => 'plu',
        'decode_map' =>
        {
            # We want to set 'number' => 'ptan' but it is not guaranteed that it will survive if we do it here.
            # There is an independent feature of NUM that may replace it with 'plur' if it is decoded later.
            # Thus we will copy the information again after all features have been decoded.
            '+' => ['other' => {'ptan' => 'yes'}, 'number' => 'ptan'],
            '-' => ['other' => {'ptan' => 'no'}]
        },
        'encode_map' =>
        {
            'number' => { 'ptan' => '+',
                          '@'    => { 'other/ptan' => { 'yes' => '+',
                                                        'no'  => '-',
                                                        '@'   => '' }}}
        }
    );
    # NUMBER ####################
    $atoms{NUM} = $self->create_atom
    (
        'surfeature' => 'number',
        'decode_map' =>
        {
            'S'  => ['number' => 'sing'],
            'P'  => ['number' => 'plur'],
            # According to http://en.wikipedia.org/wiki/Basque_grammar#Noun_phrase, there are two forms of plural in Basque: proximal ("these houses") and neutral ("the houses").
            # The proximal forms occur rarely. The tagset covers both under the NUM feature: NUM:P ... neutral plural; NUM:PH ... proximal plural.
            #    -a, -a(r)- singular article (etxea = the house)
            #    -ak, -e- plural article (etxeak = the houses)
            #    -ok, -o- plural proximal article (etxeok = these houses)
            #    -(r)ik negative-polar article (partitive suffix) (etxerik = no houses (in "there are no houses"))
            # Examples from BDT: maiteok = dear, gehienok = most, biok [bi=two], laurok [lau=four], denok, guztiok
            'PH' => ['number' => 'plur', 'other' => {'number' => 'proximal'}]
        },
        'encode_map' =>
        {
            'number' => { 'sing' => 'S',
                          'plur' => { 'other/number' => { 'proximal' => 'PH',
                                                          '@'        => 'P' }},
                          'ptan' => 'P' }
        }
    );
    # DETERMINEDNESS OF NUMBER ####################
    # mugagabea    = unlimited = indeterminado = MUG:MG
    # mugatu sing. = determ. singular          = MUG:M
    # mugatu pl.   = determ. plural            = MUG:M
    # Example from the manual: etxea = house (un nombre común terminado en vocal)
    # 	                 indeterminado   determ. singular   determ. plural
    # absolutivo (NOR)   etxe            etxea              etxeak
    # partitivo          etxerik
    # ergativo (NORK)    etxek           etxeak             etxeek
    # dativo (NORI)      etxeri          etxeari            etxeei
    # In the tagset, MUG:MG means that there is no NUM feature.
    $atoms{MUG} = $self->create_atom
    (
        'surfeature' => 'mug',
        'decode_map' =>
        {
            'M'  => ['other' => {'mug' => 'mugatu'}],
            'MG' => ['other' => {'mug' => 'mugagabea'}]
        },
        'encode_map' =>
        {
            'other/mug' => { 'mugatu'    => 'M',
                             'mugagabea' => 'MG' }
        }
    );
    # NMG ####################
    # NMG is a feature of determiners, with unknown meaning. It correlates with NUM and MUG.
    # Usually, NMG:MG means MUG:MG, NMG:S means NUM:S|MUG:M and NMG:P means NUM:P|MUG:M.
    # However, there are exceptions (e.g. NMG:S|NUM:P) and NMG can also occur without NUM and/or MUG.
    $atoms{NMG} = $self->create_atom
    (
        'surfeature' => 'nmg',
        'decode_map' =>
        {
            # determiners (hainbat = some, zenbait = some, milaka = thousands, gehiago = more, asko = many, ugari = many, oro = all)
            'MG' => ['other' => {'nmg' => 'mugagabea'}],
            # determiners (bat, bata = one, bera = the same, bereak = own)
            'S'  => ['other' => {'nmg' => 'sing'}],
            # determiners (milioika = millions of, batzu, batzuk = some, gehientsuenak = most of, bi = two, hiru = three, zortzi = eight, 20:00ak)
            'P'  => ['other' => {'nmg' => 'plur'}]
        },
        'encode_map' =>
        {
            'other/nmg' => { 'sing'      => 'S',
                             'plur'      => 'P',
                             'mugagabea' => 'MG' }
        }
    );
    # CASE ####################
    $atoms{KAS} = $self->create_atom
    (
        'surfeature' => 'case',
        'decode_map' =>
        {
            # There is some documentation written in Spanish, so the comments show also the corresponding Spanish case names.
            # The words in parentheses (e.g. "NOR") are corresponding Basque interrogative pronouns ("WHO").
            # Nuclear cases
            # absolutive / absolutivo / absolutua (NOR)
            # intransitive subject, transitive direct object
            'ABS'   => ['case' => 'abs'], # partidua, aukera, taldea, garaipena, beharra
            # partitive / partitivo / partitiboa
            'PAR'   => ['case' => 'par'], # aukerarik, arazorik, asmorik, arriskurik, garaipenik
            # ergative / ergativo / ergauboa (NORK)
            # transitive subject
            'ERG'   => ['case' => 'erg'], # taldeak, erakundeak, sindikatuak, oposizioak, haizeak
            # dative / dativo / datiboa (NORI)
            # recipient, affected, "to", "for", "from"
            'DAT'   => ['case' => 'dat'], # taldeari, partiduari, bideari, elektrizitate-lineari, kanpainari
            # Local cases
            # inessive / inesivo / inesiboa (NON)
            # where, when, "in", "at", "on"
            'INE'   => ['case' => 'ine'], # igandean, taldean, moduan, lanean, partiduan
            # allative / adlativo / adlatiboa (NORA)
            # where to, "to"
            'ALA'   => ['case' => 'all'], # behera, segundora, etxera, kalera, kilometrora
            # directional allative / adlativo direccional / adlatibo bukatuzkoa (NORANTZ)
            'ABZ'   => ['case' => 'lat'], # beherantz, ubiderantz, txokorantz, aurrerantz
            # terminal allative / adlativo terminal (NORAINO)
            'ABU'   => ['case' => 'ter'], # posturaino, zeruraino, bazterreraino, erdiraino, dorreraino
            # ablative / ablativo / ablatiboa (NONDIK)
            # where from/through, "from", "since", "through"
            'ABL'   => ['case' => 'abl'], # aurretik, hasieratik, urtetik, ondotik, kostaldetik
            # local genitive / genitivo locativo / leku genitiboa (NONGO)
            # pertaining to where/when; "of". E.g. "yesterday's program", "the exit door of upstairs".
            'GEL'   => ['case' => 'loc'], # taldeko, urteko, aurreko, munduko, goizeko
            'BNK'   => ['case' => 'loc', 'other' => {'case' => 'BNK'}], # eguneko, litroko, partiduko, antzeko
            'DESK'  => ['case' => 'loc', 'other' => {'case' => 'DESK'}], # urteko, metroko, kiloko, pezetako, mailako
            # Other cases
            # genitive / genitivo / genitiboa (NOREN)
            # possessive, genitive, "of", "-'s"
            'GEN'   => ['case' => 'gen'], # irailaren, taldearen, urriaren, apirilaren, euskararen
            # instrumental / instrumental / instrumentala (NORTAZ)
            # means, topic, "by", "of", "about"
            'INS'   => ['case' => 'ins'], # bakeaz, dinamitaz, areaz, aukeraz, giroaz
            # comitative / asociativo / soziatiboa (NOREKIN)
            # accompaniment, means, "with"
            'SOZ'   => ['case' => 'com'], # urterekin, punturekin, kolperekin, bolarekin, arazorekin
            # benefactive / destinativo (NORENTZAT)
            # beneficiary, "for"
            'DES'   => ['case' => 'ben'], # mutilarentzat, entzenatzailearentzat, jokalariarentzat, buruzagiarentzat, nafarrarentzat
            # causative / motivativo / kausazkoetan (NORENGATIK)
            # cause, reason, value, "because of", "(in exchange) for"
            'MOT'   => ['case' => 'cau'], # gorrotoarengatik, ukalondokoagatik, jokaeragatik, drogagatik, urdinagatik
            # essive / prolativo (NORTZAT)
            'PRO'   => ['case' => 'ess'], # amaieratzat, oinarritzat, aitzakiatzat, garaipentzat, eredutzat
            # the form used with postpositions
            # The postposition shares the token with the noun, they are joined using the underscore character.
            'EM'    => ['prepcase' => 'pre'], # tokiaren_arabera, eskariaren_arabera, biografiaren_arabera (here with the postposition "arabera")
        },
        'encode_map' =>
        {
            'case' => { 'abs' => 'ABS',
                        'erg' => 'ERG',
                        'dat' => 'DAT',
                        'abl' => 'ABL',
                        'ter' => 'ABU',
                        'lat' => 'ABZ',
                        'all' => 'ALA',
                        'loc' => { 'other/case' => { 'BNK'  => 'BNK',
                                                     'DESK' => 'DESK',
                                                     '@'    => 'GEL' }},
                        'ben' => 'DES',
                        'gen' => 'GEN',
                        'ine' => 'INE',
                        'ins' => 'INS',
                        'cau' => 'MOT',
                        'par' => 'PAR',
                        'ess' => 'PRO',
                        'com' => 'SOZ',
                        '@'   => { 'prepcase' => { 'pre' => 'EM' }}}
        }
    );
    # DEGREE OF COMPARISON ####################
    # maila = degree
    $atoms{MAI} = $self->create_atom
    (
        'surfeature' => 'degree',
        'decode_map' =>
        {
            # indefinite degree of some determiners (horixe, hauxe, huraxe)
            'IND'  => ['other' => {'degree' => 'ind'}],
            # comparative of adjectives, adverbs, nouns and verbs (beranduago = later, urrunago = further, arinago = lighter, ezkorrago = wetter)
            'KONP' => ['degree' => 'cmp'],
            # superlative of adjectives and adverbs (ondoen = the best, urrutien = the farthest, seguruen = the safest, azkarren = the fastest, gutxien = the least)
            'SUP'  => ['degree' => 'sup'],
            # absolute superlative of adjectives and adverbs (goizegi = too early, maizegi = too often, urrunegi = too far, azkarregi = too fast, berantegi = too late)
            # This is not exactly the same meaning as that of Romance absolute superlatives (es: guapísima).
            # In Wikipedia this is called "excessive" instead of "absolute superlative". ###!!! Shall we add this value to Interset?
            # gehiegi = too
            'GEHI' => ['degree' => 'abs']
        },
        'encode_map' =>
        {
            'degree' => { 'cmp' => 'KONP',
                          'sup' => 'SUP',
                          'abs' => 'GEHI',
                          '@'   => { 'other/degree' => { 'ind' => 'IND' }}}
        }
    );
    # PERSON AND NUMBER ####################
    $atoms{PER} = $self->create_atom
    (
        'surfeature' => 'per',
        'decode_map' =>
        {
            'NI'    => ['person' => 1, 'number' => 'sing'], # (ni, niregana, niri, niretzat, nik, nire, nigan, nitaz, niregatik, nirekin, neu, neuri, neuk, neure = I, nireak = mine)
            'HI'    => ['person' => 2, 'number' => 'sing', 'polite' => 'infm'], # (hi, hiri, hik, hire, heure = thou)
            'ZU'    => ['person' => 2, 'number' => 'sing', 'polite' => 'form'], # (zugandik, zu, zuretzat, zuk, zure, zutaz, zurekin, zeu, zeuk, zeure = you)
            'HURA'  => ['person' => 3, 'number' => 'sing'], # (berau = it)
            'GU'    => ['person' => 1, 'number' => 'plur'], # (gu, guri, guretzat, guk, gutako, gure, gurean, gutaz, gurekin, geu, geuri, geuk, geure, geuregan = we, geurea = our)
            'ZUEK'  => ['person' => 2, 'number' => 'plur'], # (zuek, zuei, zuenak, zuetako, zuen, zuetaz = you, zuena)
            'HAIEK' => ['person' => 3, 'number' => 'plur'], # (nortzuk = who, zenbaitzuk = some, beraiek, eurak = they)
        },
        'encode_map' =>
        {
            'person' => { '1' => { 'number' => { 'sing' => 'NI',
                                                 'plur' => 'GU' }},
                          '2' => { 'number' => { 'sing' => { 'polite' => { 'infm' => 'HI',
                                                                           '@'    => 'ZU' }},
                                                 'plur' => 'ZUEK' }},
                          '3' => { 'number' => { 'sing' => 'HURA',
                                                 'plur' => 'HAIEK' }}}
        }
    );
    # PERSON AND NUMBER OF IOR_IZEELI ####################
    # IOR_IZEELI are nouns derived from personal pronouns, i.e. independent forms of possessive pronouns with additional suffixes of nominal inflection.
    # Thus they have case and number, which can differ from the inherent number incorporated in the PER feature. This is the only situation where we
    # have to use the 'possnumber' feature of Interset. We had to rename the PER feature to possPER so that it gets a different processing atom.
    # Note however that we still set the 'person' feature, not 'possperson', which is parallel to the decoding of possessive pronouns in other tagsets.
    $atoms{possPER} = $self->create_atom
    (
        'surfeature' => 'possper',
        'decode_map' =>
        {
            'NI'    => ['person' => 1, 'possnumber' => 'sing'], # (nireak = mine)
            'HI'    => ['person' => 2, 'possnumber' => 'sing', 'polite' => 'infm'],
            'ZU'    => ['person' => 2, 'possnumber' => 'sing', 'polite' => 'form'],
            'HURA'  => ['person' => 3, 'possnumber' => 'sing'],
            'GU'    => ['person' => 1, 'possnumber' => 'plur'], # (geurea = ours)
            'ZUEK'  => ['person' => 2, 'possnumber' => 'plur'], # (zuena = yours)
            'HAIEK' => ['person' => 3, 'possnumber' => 'plur'],
        },
        'encode_map' =>
        {
            'person' => { '1' => { 'possnumber' => { 'sing' => 'NI',
                                                     'plur' => 'GU' }},
                          '2' => { 'possnumber' => { 'sing' => { 'polite' => { 'infm' => 'HI',
                                                                               '@'    => 'ZU' }},
                                                     'plur' => 'ZUEK' }},
                          '3' => { 'possnumber' => { 'sing' => 'HURA',
                                                     'plur' => 'HAIEK' }}}
        }
    );
    # AGREEMENT PERSON AND NUMBER OF THE ABSOLUTIVE ARGUMENT ####################
    # nor = who/whom, absolutive
    # Note: Originally I wanted to use the default features 'person', 'number' and 'polite' for this.
    # It would be parallel to languages that only mark agreement in person and number with the subject of the verb.
    # Unfortunately, some Basque finite verbs have additional morphemes of nominal inflection.
    # Thus their form reflects the person-number agreement with the absolutive argument (NOR), and nominal inflection (KAS, NUM etc.) at the same time.
    # (I have no idea what is the meaning of these forms but they are not so rare that one could consider them errors.)
    # Examples: TAG (word form)
    # ADL ADL_IZEELI KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA (dena) ................. number=sing|absnumber=sing
    # ADL ADL_IZEELI KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HAIEK|NORK:HARK (dituena) ... number=sing|absnumber=plur|ergnumber=sing
    # ADL ADL_IZEELI KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORK:GUK (dugunak) ..... number=plur|absnumber=sing|ergnumber=plur
    # ADL ADL_IZEELI KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HAIEK (direnak) ............. number=plur|absnumber=plur
    # So I decided to reserve the 'number' feature for nominal inflection, and to define 'absnumber' for agreement.
    # After all, the absolutive argument is not always the subject (for transitive verbs it is the object) so the parallelism with other languages was not so strong.
    # I also define 'absperson' and 'abspolite', although there is no direct conflict for these features ('person' and 'polite' applies now only to personal pronouns).
    # But it is better to have these features aligned with 'ergperson', 'ergpolite', 'datperson' and 'datpolite'.
    $atoms{NOR} = $self->create_atom
    (
        'surfeature' => 'nor',
        'decode_map' =>
        {
            'NI'    => ['absperson' => 1, 'absnumber' => 'sing'],                        # verb abs argument 'ni' = 'I'           (naiz,   banaiz,   naizateke) 337
            'HI'    => ['absperson' => 2, 'absnumber' => 'sing', 'abspolite' => 'infm'], # verb abs argument 'hi' = 'thou'        (haiz,   bahaiz,   haizateke) 20
            'ZU'    => ['absperson' => 2, 'absnumber' => 'sing', 'abspolite' => 'form'], # verb abs argument 'zu' = 'you'         (zara,   bazara,   zarateke) 93
            'HURA'  => ['absperson' => 3, 'absnumber' => 'sing'],                        # verb abs argument 'hura' = 'he/she/it' (da,     bada,     dateke) 14342
            'GU'    => ['absperson' => 1, 'absnumber' => 'plur'],                        # verb abs argument 'gu' = 'we'          (gara,   bagara,   garateke) 223
            'ZUEK'  => ['absperson' => 2, 'absnumber' => 'plur'],                        # verb abs argument 'zuek' = 'you'       (zarete, bazarete, zaratekete) 12
            'HAIEK' => ['absperson' => 3, 'absnumber' => 'plur'],                        # verb abs argument 'haiek' = 'they'     (dira,   badira,   dirateke) 4248
        },
        'encode_map' =>
        {
            'absperson' => { '1' => { 'absnumber' => { 'sing' => 'NI',
                                                       'plur' => 'GU' }},
                             '2' => { 'absnumber' => { 'sing' => { 'abspolite' => { 'infm' => 'HI',
                                                                                    '@'    => 'ZU' }},
                                                       'plur' => 'ZUEK' }},
                             '3' => { 'absnumber' => { 'sing' => 'HURA',
                                                       'plur' => 'HAIEK' }}}
        }
    );
    # AGREEMENT PERSON AND NUMBER OF THE ERGATIVE ARGUMENT ####################
    # nork = who, ergative
    $atoms{NORK} = $self->create_atom
    (
        'surfeature' => 'nork',
        'decode_map' =>
        {
            'NIK'     => ['ergperson' => 1, 'ergnumber' => 'sing'],                        # verb erg argument 'nik' = 'I'          (haut, dut, zaitut, zaituztet, ditut) 662
            'HIK'     => ['ergperson' => 2, 'ergnumber' => 'sing', 'ergpolite' => 'infm'], # verb erg argument 'hik' = 'thou'       (nauk, duk, gaituk, dituk) 6
            'HIK-NO'  => ['ergperson' => 2, 'ergnumber' => 'sing', 'ergpolite' => 'infm', 'erggender' => 'fem'],  #                 (dun, ezan, iezaion, nazan) 10
            'HIK-TO'  => ['ergperson' => 2, 'ergnumber' => 'sing', 'ergpolite' => 'infm', 'erggender' => 'masc'], #                 (duan, duk, ezak, baduala) 8
            'ZUK'     => ['ergperson' => 2, 'ergnumber' => 'sing', 'ergpolite' => 'form'], # verb erg argument 'zuk' = 'you-sg'     (nauzu, duzu, gaituzu, dituzu) 208
            'HARK'    => ['ergperson' => 3, 'ergnumber' => 'sing'],                        # verb erg argument 'hark' = 'he/she/it' (nau, hau, du, gaitu, zaitu, zaituzte, ditu) 5981
            'GUK'     => ['ergperson' => 1, 'ergnumber' => 'plur'],                        # verb erg argument 'guk' = 'we'         (haugu, dugu, zaitugu, zaituztegu, ditugu) 721
            'ZUEK-K'  => ['ergperson' => 2, 'ergnumber' => 'plur'],                        # verb erg argument 'zuek' = 'you-pl'    (nauzue, duzue, gaituzue, dituzue) 46
            'HAIEK-K' => ['ergperson' => 3, 'ergnumber' => 'plur'],                        # verb erg argument 'haiek' = 'they'     (naute, haute, dute, gaituzte, zaituzte, zaituztete, dituzte) 2618
        },
        'encode_map' =>
        {
            'ergperson' => { '1' => { 'ergnumber' => { 'sing' => 'NIK',
                                                       'plur' => 'GUK' }},
                             '2' => { 'ergnumber' => { 'sing' => { 'ergpolite' => { 'infm' => { 'erggender' => { 'masc' => 'HIK-TO',
                                                                                                                 'fem'  => 'HIK-NO',
                                                                                                                 '@'    => 'HIK' }},
                                                                                    '@'    => 'ZUK' }},
                                                       'plur' => 'ZUEK-K' }},
                             '3' => { 'ergnumber' => { 'sing' => 'HARK',
                                                       'plur' => 'HAIEK-K' }}}
        }
    );
    # AGREEMENT PERSON AND NUMBER OF THE DATIVE ARGUMENT ####################
    # nori = whom, dative
    $atoms{NORI} = $self->create_atom
    (
        'surfeature' => 'nori',
        'decode_map' =>
        {
            'NIRI'    => ['datperson' => 1, 'datnumber' => 'sing'],                        # verb dat argument 'niri' = 'to me'         (hatzait, zait, zatzaizkit, zatzaizkidate, zaizkit) 152
            'HIRI-NO' => ['datperson' => 2, 'datnumber' => 'sing', 'datpolite' => 'infm', 'datgender' => 'fem'],  # verb dat argument 'hiri' = 'to thee' (natzaik, zaik, gatzaizkik, zaizkik) 2
            'HIRI-TO' => ['datperson' => 2, 'datnumber' => 'sing', 'datpolite' => 'infm', 'datgender' => 'masc'], #                                      (zaik, diat, nian) 5
            'ZURI'    => ['datperson' => 2, 'datnumber' => 'sing', 'datpolite' => 'form'], # verb dat argument 'zuri' = 'to you-sg'     (natzaizu, zaizu, gatzaizkizu, zaizkizu) 39
            'HARI'    => ['datperson' => 3, 'datnumber' => 'sing'],                        # verb dat argument 'hari' = 'to him/her/it' (natzaio, hatzaio, zaio, gatzaizkio, zatzaizkio, zatzaizkiote, zaizkio) 1085
            'GURI'    => ['datperson' => 1, 'datnumber' => 'plur'],                        # verb dat argument 'guri' = 'to us'         (hatzaigu, zaigu, zatzaizkigu, zatzaizkigute, zaizkigu) 124
            'ZUEI'    => ['datperson' => 2, 'datnumber' => 'plur'],                        # verb dat argument 'zuei' = 'to you-pl'     (natzaizue, zaizue, gatzaizkizue, zaizkizue) 12
            'HAIEI'   => ['datperson' => 3, 'datnumber' => 'plur'],                        # verb dat argument 'haiei' = 'to them'      (natzaie, hatzaie, zaie, gatzaizkie, zatzaizkie, zatzaizkiete, zaizkie) 306
        },
        'encode_map' =>
        {
            'datperson' => { '1' => { 'datnumber' => { 'sing' => 'NIRI',
                                                       'plur' => 'GURI' }},
                             '2' => { 'datnumber' => { 'sing' => { 'datpolite' => { 'infm' => { 'datgender' => { 'fem' => 'HIRI-NO',
                                                                                                                 '@'   => 'HIRI-TO' }},
                                                                                    '@'    => 'ZURI' }},
                                                       'plur' => 'ZUEI' }},
                             '3' => { 'datnumber' => { 'sing' => 'HARI',
                                                       'plur' => 'HAIEI' }}}
        }
    );
    # VERB FORM ####################
    $atoms{ADM} = $self->create_simple_atom
    (
        'intfeature' => 'verbform',
        'simple_decode_map' =>
        {
            'PART'  => 'part', # partizipioa = participle
            'ADIZE' => 'ger', # aditz izena = verbal noun
            'ADOIN' => 'inf' # aditz oina = verb base (occurs with modals)
        }
    );
    # ASPECT ####################
    $atoms{ASP} = $self->create_atom
    (
        'surfeature' => 'aspect',
        'decode_map' =>
        {
            # burutua / perfect (izan, egin, esan, eman, hasi)
            'BURU' => ['aspect' => 'perf'],
            # ezburutua / imperfect (izaten, egiten, ematen, ikusten, erabiltzen)
            'EZBU' => ['aspect' => 'imp'],
            # geroa / prospective (izango, egingo, jokatuko, egongo, hartuko)
            'GERO' => ['aspect' => 'prosp'],
            # finite forms of synthetic, auxiliary and compound verbs have a special value of "aspect", meaning that aspect is irrelevant for them
            # (dugu, daukagu, dakigu, darabilgu, diogu)
            # We do not set verbform=fin here because we do not want to clash with verbform possibly set during the decoding of part of speech.
            'PNT'  => []
        },
        'encode_map' =>
        {
            # finite verbs always have a non-empty value of person (the NOR feature)
            'absperson' => { ''  => { 'aspect' => { 'perf'  => 'BURU',
                                                    'imp'   => 'EZBU',
                                                    'prosp' => 'GERO' }},
                             '@' => 'PNT' }
        }
    );
    # ERL ####################
    # ERL is a feature of verbs and conjunctions. Its meaning is unknown. Perhaps "erlazio" = "relation"?
    $atoms{ERL} = $self->create_atom
    (
        'surfeature' => 'erl',
        'decode_map' =>
        {
            # Conjunctions
            'AURK'  => ['other' => {'erl' => 'aurk'}], # conjunctions: baina = but, baino = than, baizik = but, izan_ezik = except for, ez baina = but not, ostera = while
            'EMEN'  => ['other' => {'erl' => 'emen'}], # conjunctions: eta = and, baita = and, ezta = or, ez_ezik = in addition to, baita_ere = also
            'ESPL'  => ['other' => {'erl' => 'espl'}], # conjunctions (explicative): hain_zuzen = which, esate_baterako = such as, hala_nola = such as
            'HAUT'  => ['other' => {'erl' => 'haut'}], # conjunctions: edo = or, zein = and, ala = or, edota = or, nahiz = and, bestela = or
            'ONDO'  => ['other' => {'erl' => 'ondo'}], # conjunctions (beraz = so, bada = if, orduan = when, hortaz = so, egia_esan = true that, azken_esan = now that)
            # Verbs
            # baldintzazko adizkiak = conditional forms
            'BALD'  => ['other' => {'erl' => 'bald'}], # verbs: conditional protasis (balira = if they were; bada, badira, bagara, bagatzaizkio, bagina, baginen, balira, balitz, ..., izatekoan)
            # denbora = time
            'DENB'  => ['other' => {'erl' => 'denb'}], # verbs (denean, denerako, denetik, direnean, direneako, ginenean, naizenean, naizenetik, nintzenean, zaigunean, zenean, zenetik, zirenean, zirenetik, zitzaionean, zitzaizkienean)
            'ERLT'  => ['other' => {'erl' => 'erlt'}], # verbs (den, diren, giren, naizen, zaidan, zaien, zaigun, zaion, zaizkien, zaizkion, zaizkizun, zen, ziren, zitzaidan, zitzaion, zitzaizkigun, zitzaizkion)
            'HELB'  => ['other' => {'erl' => 'helb'}], # verbs (izateko, izatera)
            'KAUS'  => ['other' => {'erl' => 'kaus'}], # verbs (baigara, bailitzateke, bainintzen, baita, baitira, baitzaio, baitzait..., danez, delako, denez, direlako, direlakotz, direnez, garelako, garenez, haizelako, litzatekeelako, naizenez, nintzelako, zaienez, zaiolako, zelako, zenez, zirelako, zirenez, zitzaizkiolako)
            'KONPL' => ['other' => {'erl' => 'konpl'}], # verbs (badela, badirela, bazela, dela, dena, denik, direla, direnik, garela, ginela, izatea, izatekoa, izaten, liratekeela, lizatekeela, naizela, naizenik, nintzatekeela, nintzela, zaiela, zaiguna, zaiola, zaizkiela, zaizkiola, zarela, zatekeela, zela, zenik, zirela, zirenik, zitzaidala, zitzaigunik, zitzaiola)
            'KONT'  => ['other' => {'erl' => 'kont'}], # verbs (izanagatik, izateagatik) because? although? as?
            'MOD'   => ['other' => {'erl' => 'mod'}], # verbs (delakoan, direlakoan, izaki, izanda, izaten, zelakoan, zirelakoan)
            'MOD/DENB'=>['other' => {'erl' => 'mod/denb'}],# verbs (dela, delarik, direla, direlarik, nintzela, nintzelarik, zaiola, zela, zelarik, zirela, zirelarik)
            'MOS'   => ['other' => {'erl' => 'mos'}], # verbs: conditional apodosis? (lirateke = they would be, ziratekeen = they would have been; baden, bazen, den, diren, garen, liratekeen, zaizkidan, zen, zinen, ziren, zitzaidan, zitzaien)
            'ZHG'   => ['other' => {'erl' => 'zhg'}], # verbs (den, diren, direnetz, garen, naizen, nintzen, zaigun, zaion, zaizkion, zaren, zen, ziren)
        },
        'encode_map' =>
        {
            'other/erl' => { 'aurk'  => 'AURK',
                             'emen'  => 'EMEN',
                             'espl'  => 'ESPL',
                             'haut'  => 'HAUT',
                             'ondo'  => 'ONDO',
                             'bald'  => 'BALD',
                             'denb'  => 'DENB',
                             'erlt'  => 'ERLT',
                             'helb'  => 'HELB',
                             'kaus'  => 'KAUS',
                             'konpl' => 'KONPL',
                             'kont'  => 'KONT',
                             'mod'   => 'MOD',
                             'mod/denb' => 'MOD/DENB',
                             'mos'   => 'MOS',
                             'zhg'   => 'ZHG' }
        }
    );
    # MDN ####################
    # MDN is a feature of verbs. Its meaning is unknown. The vast majority of verb occurrences are either class A1 or B1.
    # There are verb lemmas (e.g. "edin") whose word forms appear in multiple classes.
    $atoms{MDN} = $self->create_atom
    (
        'surfeature' => 'mdn',
        'decode_map' =>
        {
            'A1'  => ['other' => {'mdn' => 'a1' }], # verbs 11766: izan (be), edun, ukan (act), egon (stay), behar_izan (have to, need, must)
            'A3'  => ['other' => {'mdn' => 'a3' }], # verbs   107: ezan (lack), edin, egon (stay), ibili (walk)
            'A4'  => ['other' => {'mdn' => 'a4' }], # verbs     1: jakin (know)
            'A5'  => ['other' => {'mdn' => 'a5' }], # verbs   282: edin, ezan (lack)
            'B1'  => ['other' => {'mdn' => 'b1' }], # verbs  6666: edun, izan (be), egon (stay), ukan (act), ari_izan
            'B2'  => ['other' => {'mdn' => 'b2' }], # verbs   185: edun, izan (be), nahi_izan (want), behar_izan (must), ukan (act)
            'B3'  => ['other' => {'mdn' => 'b3' }], # verbs    11: edun, izan (be), jakin (know), nahiago_izan (prefer)
            'B4'  => ['other' => {'mdn' => 'b4' }], # verbs    59: izan (be), edun, ukan (act), egon (stay), ari_izan
            'B5A' => ['other' => {'mdn' => 'b5a'}], # verbs     1: ezan (lack)
            'B5B' => ['other' => {'mdn' => 'b5b'}], # verbs    27: ezan (lack), edin, egon (stay), esan (say), joan (go)
            'B6'  => ['other' => {'mdn' => 'b6' }], # verbs     1: egon (stay)
            'B7'  => ['other' => {'mdn' => 'b7' }], # verbs    79: edin, ezan (lack), ekarri (bring)
            'B8'  => ['other' => {'mdn' => 'b8' }], # verbs    38: edin, ezan (lack)
            'C'   => ['other' => {'mdn' => 'c'  }], # verbs    52: ezan (lack), egon (stay), joan (go), edin, eman (give)
        },
        'encode_map' =>
        {
            'other/mdn' => { 'a1'  => 'A1',
                             'a3'  => 'A3',
                             'a4'  => 'A4',
                             'a5'  => 'A5',
                             'b1'  => 'B1',
                             'b2'  => 'B2',
                             'b3'  => 'B3',
                             'b4'  => 'B4',
                             'b5a' => 'B5A',
                             'b5b' => 'B5B',
                             'b6'  => 'B6',
                             'b7'  => 'B7',
                             'b8'  => 'B8',
                             'c'   => 'C' }
        }
    );
    # MOD ####################
    # MOD is a feature of particles and some verbs. Its meaning is unknown.
    $atoms{MOD} = $self->create_atom
    (
        'surfeature' => 'mod',
        'decode_map' =>
        {
            # particles (ez = no, bai = yes) and verbs (ukan = act, jakin = know, izan = be, egon = stay, iruditu = seem)
           'EGI' => ['other' => {'mod' => 'egi'}],
            # particles (al, ote, omen, ei, bide, ahal)
            # "al" and "ote" are question markers.
           'ZIU' => ['other' => {'mod' => 'ziu'}]
        },
        'encode_map' =>
        {
            'other/mod' => { 'egi' => 'EGI',
                             'ziu' => 'ZIU' }
        }
    );
    # HIT ####################
    # HIT is a rare feature of some verbs. Its meaning is unknown.
    ###!!! Maybe it is related to this information from https://en.wikipedia.org/wiki/Basque_verbs:
    # In colloquial Basque, an informal relationship and social solidarity between the speaker and a single interlocutor
    # are expressed by employing a special mode of speech often referred to in Basque as either hika or hitano
    # (both derived from hi, the informal second-person pronoun; in other places the same phenomenon is named
    # noka and toka for female and male interlocutors respectively).
    $atoms{HIT} = $self->create_atom
    (
        'surfeature' => 'hit',
        'decode_map' =>
        {
            # Examples, lemma *edun (to have): din, dinat, dinagu, ditun, zinan, ninan, dun, naun, ditin, gintunan, zidaten, zien, zion
            'NO' => ['gender' => 'fem'],
            # Examples, lemma *edun (to have): dik, diat, diagu, dituk, zian, nian, duk, nauk, ditek, genian
            'TO' => ['gender' => 'masc']
        },
        'encode_map' =>
        {
            'gender' => { 'masc' => 'TO',
                          'fem'  => 'NO' }
        }
    );
    # KLM ####################
    # KLM is a rare feature of a few conjunctions. Its meaning is unknown.
    $atoms{KLM} = $self->create_atom
    (
        'surfeature' => 'klm',
        'decode_map' =>
        {
            # 80 occurrences of the conjunction "eta" ("and") (causative) are tagged LOT MEN ERL:KAUS|KLM:AM.
            'AM'  => ['other' => {'klm' => 'am'}],
            # 2 occurrences of the conjunction "zeren" ("because") (causative) are tagged LOT LOK ERL:KAUS|KLM:HAS.
            'HAS' => ['other' => {'klm' => 'has'}]
        },
        'encode_map' =>
        {
            'other/klm' => { 'am'  => 'AM',
                             'has' => 'HAS' }
        }
    );
    # MULTIWORD EXPRESSION ####################
    # In general, MW:B is set for tokens that contain multiple surface words joined by the underscore character.
    # That is, MW:B means that the word form contains '_'. Exception: noun coupled with a postposition has POS:+ instead of MW:B.
    $atoms{MW} = $self->create_atom
    (
        'surfeature' => 'mw',
        'decode_map' =>
        {
            'B' => ['other' => {'multiword' => 'yes'}]
        },
        'encode_map' =>
        {
            'other/multiword' => { 'yes' => 'B' }
        }
    );
    # POSTPOSITION ####################
    # Postpositions are attached using underscore to the preceding noun, pronoun, adjective, determiner or adverb.
    # The joined token has the POS feature set twice: once just "POS:+" to mark that there is a postposition,
    # and once indicating the concrete postposition. Note that a postposition attached using '_' does not trigger the MW:B feature!
    # For technical reasons, we do not allow two features with the same name, even if they are closely related ("POS:POSarte|POS:+").
    $atoms{hasPOS} = $self->create_atom
    (
        'surfeature' => 'haspos',
        'decode_map' =>
        {
            '+' => ['other' => {'has_postposition' => 'yes'}]
        },
        'encode_map' =>
        {
            'other/has_postposition' => { 'yes' => '+' }
        }
    );
    $atoms{POS} = $self->create_atom
    (
        'surfeature' => 'pos',
        'decode_map' => {},
        'encode_map' => { 'other/postposition' => {} }
    );
    my $dm = $atoms{POS}->decode_map();
    my $em = $atoms{POS}->encode_map();
    my @postpositions =
    (
        'aintzinean', # former 1
        'aitzina', # beyond 2
        'aitzinean', # in the 5
        'aitzineko', # before 2
        'aitzinetik', # beforehand 3
        'alboan', # next 2
        'aldamenetik', # side 1
        'alde', # the 38
        'aldean', # at 11
        'aldeaz', # at 1
        'aldeko', # for 39
        'aldera', # to 20
        'alderat', # 1
        'aldetik', # as 25
        'antzean', # similar 1
        'antzeko', # similar 9
        'antzekoa', # similar 2
        'antzera', # like 3
        'arabera', # according to 135
        'araberako', # by 1
        'arte', # to 82
        'artean', # among 158
        'arteetik', # among 1
        'arteko', # between 108
        'artekoak', # between 1
        'at', # at 6
        'atzean', # back 15
        'atzeko', # back 6
        'atzera', # back 1
        'atzetik', # after 12
        'aurka', # against 103
        'aurkaa', # against 1
        'aurkako', # against 49
        'aurrean', # to 74
        'aurreko', # previous 10
        'aurrera', # from 36
        'aurrerako', # from 2
        'aurretik', # before 26
        'azpian', # under 9
        'azpitik', # below 6
        'baitan', # within 12
        'barik', # not 2
        'barna', # through 1
        'barnean', # within 11
        'barneko', # including 2
        'barnera', # into 1
        'barrena', # through 4
        'barrenean', # inside 1
        'barru', # in 7
        'barruan', # within 37
        'barruetatik', # inside 1
        'barruko', # internal 3
        'barrura', # inside 1
        'barrutik', # inside 2
        'batera', # with 43
        'begira', # at 31
        'behera', # down 11
        'bestaldean', # other 1
        'bezala', # as 75
        'bezalako', # as 15
        'bezalakoa', # as 1
        'bezalakoen', # as 1
        'bidez', # by 45
        'bila', # for 20
        'bitarte', # to 2
        'bitartean', # while 18
        'bitarteko', # to 5
        'bitarterako', # 1
        'bitartez', # through 13
        'buruan', # after 7
        'buruz', # about 47
        'buruzko', # on 36
        'eran', # as 1
        'erdian', # middle 11
        'erdiko', # central 1
        'erdira', # half 3
        'erditan', # half 1
        'eske', # begging 2
        'esker', # thanks 30
        'esku', # the 12
        'eskuetan', # hands 5
        'eskuko', # hand 1
        'eskutik', # by 6
        'ezean', # if you do not 4
        'gabe', # no 74
        'gabeko', # not 18
        'gain', # in addition to 36
        'gaindi', # overcome 1
        'gaindiko', # border 1
        'gainean', # on 33
        'gaineko', # about
        'gainera', # also 9
        'gainerat', # 1
        'gainetik', # above 16
        'gero', # more 1
        'geroztik', # since 18
        'gertu', # near 4
        'gibeleko', # liver 1
        'gibeletik', # behind 2
        'gisa', # as 34
        'gisako', # as 1
        'gisan', # as 2
        'gisara', # as 1
        'goiko', # top 1
        'goitik', # top 1
        'gora', # up 30
        'gorago', # above 1
        'gorako', # more 7
        'gorakoen', # over 1
        'hurbil', # close 8
        'hurrean', # respectively 1
        'inguru', # about 16
        'ingurua', # environment 1
        'inguruan', # about 77
        'inguruetako', # surrounding 1
        'inguruetan', # in 2
        'inguruetara', # around
        'inguruko', # about 28
        'ingurura', # about 5
        'ingururako', # environment 1
        'irian', # 1
        'kanpo', # outside 28
        'kanpoko', # external 12
        'kanpora', # outside 4
        'kontra', # against 72
        'kontrako', # against 39
        'landa', # rural 7
        'landara', # plant 2
        'legez', # as 1
        'lekuan', # where 4
        'lepora', # 1
        'mendean', # the 1
        'menpe', # depends on 8
        'menpera', # conquest 1
        'moduan', # as 1
        'modura', # as 1
        'ondoan', # next 19
        'ondoko', # the 1
        'ondora', # close 1
        'ondoren', # after 32
        'ondorengo', # the 2
        'ondotik', # after 14
        'ordez', # instead of 9
        'ostean', # after 17
        'osteko', # after 1
        'pare', # two 1
        'parean', # at 5
        'pareko', # equivalent 2
        'partean', # part of 3
        'partez', # notebook 1
        'pean', # under 1
        'truke', # exchange 9
        'urrun', # from 3
        'urruti', # far 3
        'zai', # waiting 2
        'zain', # waiting 12
        'zehar', # during 42
    );
    foreach my $p (@postpositions)
    {
        my $value = 'POS'.$p;
        $dm->{$value} = ['other' => {'postposition' => $p}];
        $em->{'other/postposition'}{$p} = $value;
    }
    return \%atoms;
}



#------------------------------------------------------------------------------
# Creates the list of all surface CoNLL features that can appear in the FEATS
# column. This list will be used in decode().
#------------------------------------------------------------------------------
sub _create_features_all
{
    my $self = shift;
    # POS JE NEKDY PRED KAS, NEKDY ZA KAS
    # ADM ASP ERL MDN NOR NORK NORI MAI BIZ IZAUR PER NMG KAS POS NUM MUG MW ENT
    my @features = ('MTKAT', 'IZAUR', 'BIZ', 'ZENB', 'NEUR', 'PLU', 'NUM', 'MUG', 'NMG', 'KAS', 'MAI',
                    'PER', 'possPER', 'NOR', 'NORK', 'NORI', 'ADM', 'ASP', 'ERL', 'MDN', 'MOD', 'HIT', 'KLM', 'POS', 'hasPOS', 'MW', 'ENT');
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
        ###!!! Někdy i určité sloveso má pád a číslo a já pak nevím, jak mám poznat, jestli ho uvést zvlášť, nebo ne!
        'ADInfin' => ['PLU', 'MAI', 'ADM', 'ASP', 'ERL', 'KAS', 'NUM', 'MUG', 'MW', 'ENT'],
        'ADIfin'  => ['ASP', 'ERL', 'KAS', 'NUM', 'MUG', 'MOD', 'MDN', 'NOR', 'NORK', 'NORI', 'HIT', 'MW', 'ENT'],
        'ADL'     => ['ERL', 'KAS', 'NUM', 'MUG', 'MOD', 'MDN', 'NOR', 'NORK', 'NORI', 'HIT'],
        'ADT'     => ['ASP', 'ERL', 'KAS', 'NUM', 'MUG', 'MOD', 'MDN', 'NOR', 'NORK', 'NORI', 'HIT', 'ENT'],
        'IZE'     => ['BIZ', 'ZENB', 'NEUR', 'PLU', 'MTKAT', 'MAI', 'ADM', 'IZAUR', 'possPER', 'NMG', 'KAS', 'NUM', 'MUG', 'POS', 'hasPOS', 'MW', 'ENT'],
        '@'       => $self->_create_features_all()
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
    # For technical reasons, we do not allow two features with the same name, even if they are closely related ("POS:POSarte|POS:+").
    $tag =~ s/POS:\+/hasPOS:+/;
    $tag =~ s/IOR_IZEELI\tPER:/IOR_IZEELI\tpossPER:/;
    my $fs = $self->decode_conll($tag, 'both', ':');
    # Make sure that the NUM:P feature does not overwrite the value set by the PLU:+ feature.
    if($fs->get_other_subfeature('eu::conll', 'ptan') eq 'yes')
    {
        $fs->set('number', 'ptan');
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
    my $pos_subpos = $atoms->{pos}->encode($fs);
    my ($pos, $subpos) = split(/\t/, $pos_subpos);
    my $fpos = '@';
    if($pos eq 'ADI')
    {
        $fpos = $fs->absperson() ne '' ? 'ADIfin' : 'ADInfin';
    }
    elsif($pos =~ m/^(ADL|ADT|IZE)$/)
    {
        $fpos = $pos;
    }
    my $feature_names = $self->get_feature_names($fpos);
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names, 0, ':');
    # For technical reasons, we do not allow two features with the same name, even if they are closely related ("POS:POSarte|POS:+").
    $tag =~ s/hasPOS:\+/POS:+/;
    $tag =~ s/possPER:/PER:/;
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus, 3945 distinct tags found.
# Removing tags considered to be errors...
# Adding other tags to survive missing value of 'other'...
# Result: 5161 tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
ADB	ARR	ADM:PART
ADB	ARR	BIZ:-
ADB	ARR	BIZ:-|KAS:GEL
ADB	ARR	BIZ:-|MUG:M|MW:B
ADB	ARR	BIZ:-|MW:B
ADB	ARR	ENT:Erakundea
ADB	ARR	ENT:Pertsona
ADB	ARR	ENT:Tokia
ADB	ARR	IZAUR:-
ADB	ARR	IZAUR:-|KAS:ALA|POS:POSaurrera|POS:+
ADB	ARR	KAS:ABL
ADB	ARR	KAS:ABL|POS:POSaurretik|POS:+
ADB	ARR	KAS:ABL|POS:POSgoitik|POS:+
ADB	ARR	KAS:ABS
ADB	ARR	KAS:ABS|MAI:KONP
ADB	ARR	KAS:ABS|POS:POSartekoak|POS:+
ADB	ARR	KAS:ABS|POS:POSarte|POS:+
ADB	ARR	KAS:ABS|POS:POSbezalakoa|POS:+
ADB	ARR	KAS:ABS|POS:POSgisa|POS:+
ADB	ARR	KAS:ABS|POS:POSkanpo|POS:+
ADB	ARR	KAS:ABS|POS:POSlanda|POS:+
ADB	ARR	KAS:ABZ
ADB	ARR	KAS:ABZ|MAI:KONP
ADB	ARR	KAS:ALA
ADB	ARR	KAS:ALA|POS:POSaurrera|POS:+
ADB	ARR	KAS:ALA|POS:POSbehera|POS:+
ADB	ARR	KAS:EM
ADB	ARR	KAS:EM|POS:POSantzeko|POS:+
ADB	ARR	KAS:EM|POS:POSatzera|POS:+
ADB	ARR	KAS:EM|POS:POSaurrera|POS:+
ADB	ARR	KAS:EM|POS:POSbezala|POS:+
ADB	ARR	KAS:EM|POS:POSgabe|POS:+|MW:B
ADB	ARR	KAS:EM|POS:POSgora|POS:+
ADB	ARR	KAS:EM|POS:POSlegez|POS:+
ADB	ARR	KAS:EM|POS:POSzain|POS:+
ADB	ARR	KAS:EM|POS:POSzehar|POS:+
ADB	ARR	KAS:GEL
ADB	ARR	KAS:GEL|ENT:Erakundea
ADB	ARR	KAS:GEL|MAI:KONP
ADB	ARR	KAS:GEL|MW:B
ADB	ARR	KAS:GEL|POS:POSarteko|POS:+
ADB	ARR	KAS:GEL|POS:POSaurrerako|POS:+
ADB	ARR	KAS:GEL|POS:POSgibeleko|POS:+
ADB	ARR	KAS:GEL|POS:POSgoiko|POS:+
ADB	ARR	KAS:GEL|POS:POSgorako|POS:+
ADB	ARR	KAS:GEL|POS:POSinguruko|POS:+
ADB	ARR	KAS:GEL|POS:POSkanpoko|POS:+
ADB	ARR	KAS:INE
ADB	ARR	KAS:INE|POS:POSantzean|POS:+
ADB	ARR	KAS:INE|POS:POSartean|POS:+
ADB	ARR	KAS:INE|POS:POSaurrean|POS:+
ADB	ARR	KAS:INE|POS:POSaurrean|POS:+|MW:B
ADB	ARR	KAS:INE|POS:POSbarruan|POS:+
ADB	ARR	KAS:INE|POS:POSgainean|POS:+
ADB	ARR	KAS:INS
ADB	ARR	KAS:PAR|MAI:SUP
ADB	ARR	MAI:GEHI
ADB	ARR	MAI:KONP
ADB	ARR	MAI:SUP
ADB	ARR	MUG:MG|KAS:ABS
ADB	ARR	MUG:MG|KAS:ABS|MAI:KONP
ADB	ARR	MUG:MG|KAS:INE
ADB	ARR	MUG:MG|KAS:INS
ADB	ARR	MUG:MG|KAS:PAR|MAI:SUP
ADB	ARR	MUG:M|MW:B
ADB	ARR	MW:B
ADB	ARR	MW:B|ENT:Erakundea
ADB	ARR	NUM:P|KAS:ABS
ADB	ARR	NUM:P|KAS:INE
ADB	ARR	NUM:P|MUG:M|KAS:ABS
ADB	ARR	NUM:P|MUG:M|KAS:INE
ADB	ARR	NUM:P|MUG:M|KAS:INE|POS:POSartean|POS:+
ADB	ARR	NUM:S|KAS:ABL
ADB	ARR	NUM:S|KAS:ABS
ADB	ARR	NUM:S|KAS:ALA
ADB	ARR	NUM:S|KAS:EM
ADB	ARR	NUM:S|KAS:ERG
ADB	ARR	NUM:S|KAS:GEL
ADB	ARR	NUM:S|KAS:GEN
ADB	ARR	NUM:S|KAS:INE
ADB	ARR	NUM:S|MUG:M|KAS:ABL|MW:B
ADB	ARR	NUM:S|MUG:M|KAS:ABS
ADB	ARR	NUM:S|MUG:M|KAS:ABS|MW:B
ADB	ARR	NUM:S|MUG:M|KAS:ALA
ADB	ARR	NUM:S|MUG:M|KAS:EM|POS:POSondotik|POS:+
ADB	ARR	NUM:S|MUG:M|KAS:ERG
ADB	ARR	NUM:S|MUG:M|KAS:GEL|MW:B
ADB	ARR	NUM:S|MUG:M|KAS:GEN
ADB	ARR	NUM:S|MUG:M|KAS:INE
ADB	ARR	_
ADB	GAL	ENT:Pertsona
ADB	GAL	ENT:Tokia
ADB	GAL	KAS:ABS
ADB	GAL	KAS:ABS|POS:POSarte|POS:+
ADB	GAL	KAS:ABU
ADB	GAL	KAS:GEL
ADB	GAL	_
ADI	ADI_IZEELI	ADM:ADIZE|KAS:ABS|NUM:P|MUG:M
ADI	ADI_IZEELI	ADM:ADIZE|KAS:ABS|NUM:S|MUG:M
ADI	ADI_IZEELI	ADM:ADIZE|KAS:INE|NUM:S|MUG:M
ADI	ADI_IZEELI	ADM:PART|KAS:ABS|NUM:P|MUG:M
ADI	ADI_IZEELI	ADM:PART|KAS:ABS|NUM:S|MUG:M
ADI	ADI_IZEELI	ADM:PART|KAS:DAT|NUM:P|MUG:M
ADI	ADI_IZEELI	ADM:PART|KAS:ERG|NUM:P|MUG:M
ADI	ADI_IZEELI	ADM:PART|KAS:ERG|NUM:S|MUG:M
ADI	ADI_IZEELI	ADM:PART|KAS:GEN|NUM:P|MUG:M
ADI	ADI_IZEELI	ADM:PART|KAS:GEN|NUM:S|MUG:M
ADI	ADI_IZEELI	ADM:PART|KAS:INE|NUM:P|MUG:M
ADI	ADI_IZEELI	ADM:PART|KAS:INE|NUM:S|MUG:M
ADI	ADI_IZEELI	ADM:PART|KAS:INS|NUM:S|MUG:M
ADI	ADI_IZEELI	ADM:PART|KAS:SOZ|NUM:S|MUG:M
ADI	ADI_IZEELI	MAI:SUP|ADM:PART|KAS:ABS|NUM:S|MUG:M
ADI	ADK	ADM:ADIZE|ERL:DENB|KAS:INE|MW:B
ADI	ADK	ADM:ADIZE|ERL:HELB|KAS:ABS|MUG:MG|MW:B
ADI	ADK	ADM:ADIZE|ERL:HELB|KAS:ALA|MW:B
ADI	ADK	ADM:ADIZE|ERL:KONPL|KAS:ABS|MUG:MG|MW:B
ADI	ADK	ADM:ADIZE|ERL:KONPL|KAS:ABS|MW:B
ADI	ADK	ADM:ADIZE|ERL:KONPL|KAS:INE
ADI	ADK	ADM:ADIZE|ERL:KONPL|KAS:INE|MW:B
ADI	ADK	ADM:ADIZE|ERL:KONPL|KAS:PAR|ENT:Erakundea
ADI	ADK	ADM:ADIZE|ERL:KONPL|KAS:PAR|MW:B
ADI	ADK	ADM:ADIZE|ERL:KONPL|KAS:PAR|MW:B|ENT:Erakundea
ADI	ADK	ADM:ADIZE|ERL:KONT|KAS:MOT
ADI	ADK	ADM:ADIZE|ERL:KONT|KAS:MOT|NUM:S|MUG:M|MW:B
ADI	ADK	ADM:ADIZE|ERL:MOD|KAS:INE
ADI	ADK	ADM:ADIZE|ERL:MOD|KAS:INE|MW:B
ADI	ADK	ADM:ADIZE|KAS:ABS|MW:B
ADI	ADK	ADM:ADIZE|KAS:ABS|NUM:P|MUG:M|MW:B
ADI	ADK	ADM:ADIZE|KAS:DAT|NUM:S|MUG:M|MW:B
ADI	ADK	ADM:ADIZE|KAS:ERG|NUM:S|MUG:M|MW:B
ADI	ADK	ADM:ADIZE|KAS:GEL|MW:B
ADI	ADK	ADM:ADIZE|KAS:GEN|NUM:S|MUG:M|MW:B
ADI	ADK	ADM:ADIZE|KAS:INS|NUM:S|MUG:M|MW:B
ADI	ADK	ADM:ADIZE|MW:B
ADI	ADK	ADM:ADOIN
ADI	ADK	ADM:ADOIN|ASP:EZBU
ADI	ADK	ADM:ADOIN|ASP:EZBU|MW:B
ADI	ADK	ADM:ADOIN|MW:B
ADI	ADK	ADM:PART|ASP:BURU
ADI	ADK	ADM:PART|ASP:BURU|MW:B
ADI	ADK	ADM:PART|ASP:GERO|MW:B
ADI	ADK	ADM:PART|ERL:MOD|MW:B
ADI	ADK	ADM:PART|KAS:ABS|MUG:MG|MW:B
ADI	ADK	ADM:PART|KAS:ABS|NUM:P|MUG:M
ADI	ADK	ADM:PART|KAS:ABS|NUM:P|MUG:M|MW:B
ADI	ADK	ADM:PART|KAS:GEL
ADI	ADK	ADM:PART|KAS:GEL|MW:B
ADI	ADK	ADM:PART|KAS:GEN|NUM:S|MUG:M|MW:B
ADI	ADK	ADM:PART|KAS:INS|MUG:MG|MW:B
ADI	ADK	ADM:PART|KAS:PAR|MUG:MG|MW:B
ADI	ADK	ADM:PART|MW:B
ADI	ADK	ASP:GERO
ADI	ADK	ASP:PNT|ERL:BALD|MDN:A1|NOR:GU|MW:B
ADI	ADK	ASP:PNT|ERL:BALD|MDN:A1|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|ERL:BALD|MDN:A1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|ERL:BALD|MDN:A1|NOR:HURA|NORK:GUK|MW:B
ADI	ADK	ASP:PNT|ERL:BALD|MDN:A1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|ERL:BALD|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|ERL:BALD|MDN:A1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:BALD|MDN:A1|NOR:HURA|NORK:ZUK|MW:B
ADI	ADK	ASP:PNT|ERL:BALD|MDN:A1|NOR:ZU|MW:B
ADI	ADK	ASP:PNT|ERL:BALD|MDN:B1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:BALD|MDN:B4|NOR:GU|MW:B
ADI	ADK	ASP:PNT|ERL:DENB|MDN:A1|NOR:GU|MW:B
ADI	ADK	ASP:PNT|ERL:DENB|MDN:A1|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|ERL:DENB|MDN:A1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|ERL:DENB|MDN:A1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|ERL:DENB|MDN:A1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:DENB|MDN:A1|NOR:HURA|NORK:NIK|MW:B
ADI	ADK	ASP:PNT|ERL:DENB|MDN:B1|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|ERL:DENB|MDN:B1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|ERL:DENB|MDN:B1|NOR:HURA|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|ERL:DENB|MDN:B1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:A1|NOR:GU|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:A1|NOR:GU|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HAIEK|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HAIEK|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORK:GUK|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORK:NIK|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HAIEK|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HURA|NORK:GUK|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HURA|NORK:HARK|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HURA|NORK:NIK|MW:B
ADI	ADK	ASP:PNT|ERL:ERLT|MDN:B2|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:A1|NOR:GU|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HAIEK|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HAIEK|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORK:GUK|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HAIEI|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORK:HARK|NORI:HAIEI|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORK:NIK|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORK:ZUK|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:B1|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:B1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|ERL:KAUS|MDN:B1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:A1|NOR:GU|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HI|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORI:NIRI|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORK:GUK|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HAIEI|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:A1|NOR:ZU|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HAIEK|NORI:HAIEI|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HURA|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HURA|NORK:GUK|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HURA|NORK:HIK|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HURA|NORK:NIK|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HURA|NORK:ZUEK-K|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:B1|NOR:NI|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:B1|NOR:NI|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:KONPL|MDN:B2|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|ERL:MOD/DENB|MDN:A1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|ERL:MOD/DENB|MDN:A1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:MOD/DENB|MDN:B1|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|ERL:MOD/DENB|MDN:B1|NOR:HAIEK|NORI:NIRI|MW:B
ADI	ADK	ASP:PNT|ERL:MOD/DENB|MDN:B1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|ERL:MOD/DENB|MDN:B1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:MOD|MDN:A1|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|ERL:MOS|MDN:A1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|ERL:MOS|MDN:A1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:MOS|MDN:B1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|ERL:MOS|MDN:B1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:MOS|MDN:B4|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|ERL:MOS|MDN:B4|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:MOS|MDN:B4|NOR:HURA|NORK:HARK|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|ERL:ZHG|MDN:A1|NOR:GU|MW:B
ADI	ADK	ASP:PNT|ERL:ZHG|MDN:A1|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|ERL:ZHG|MDN:A1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|ERL:ZHG|MDN:A1|NOR:HURA|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|ERL:ZHG|MDN:A1|NOR:HURA|NORK:GUK|MW:B
ADI	ADK	ASP:PNT|ERL:ZHG|MDN:A1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|ERL:ZHG|MDN:A1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|ERL:ZHG|MDN:A1|NOR:HURA|NORK:NIK|MW:B
ADI	ADK	ASP:PNT|ERL:ZHG|MDN:A1|NOR:ZU|MW:B
ADI	ADK	ASP:PNT|ERL:ZHG|MDN:B1|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|KAS:ABS|NUM:P|MUG:M|MDN:B1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:NIK|MW:B
ADI	ADK	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:ZUK|MW:B
ADI	ADK	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:GUK|MW:B
ADI	ADK	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|KAS:ALA|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|KAS:DAT|NUM:S|MUG:M|MDN:A1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|KAS:DES|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|KAS:ERG|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|KAS:ERG|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|KAS:GEN|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|KAS:GEN|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|KAS:PAR|MUG:MG|MDN:A1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:GU|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HAIEK|NORI:HAIEI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HAIEK|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HAIEK|NORK:GUK|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HAIEK|NORK:GUK|MW:B|ENT:Erakundea
ADI	ADK	ASP:PNT|MDN:A1|NOR:HAIEK|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HAIEK|NORK:HAIEK-K|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HAIEK|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HAIEK|NORK:HARK|NORI:HAIEI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HAIEK|NORK:NIK|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HAIEK|NORK:NIK|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HAIEK|NORK:ZUEK-K|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|HIT:NO|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORI:GURI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORI:HAIEI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORI:HIRI-NO|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORI:NIRI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:GUK|HIT:NO|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:GUK|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:GUK|MW:B|ENT:Pertsona
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:GUK|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:GUK|NORI:HIRI-TO|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:HARK|HIT:NO|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:HARK|HIT:TO|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:HARK|NORI:GURI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:HARK|NORI:HAIEI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:HIK-TO|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:NIK|HIT:NO|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:NIK|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:NIK|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:NIK|NORI:ZUEI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:HURA|NORK:ZUK|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:NI|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:NI|NORK:ZUK|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:ZUEK|MW:B
ADI	ADK	ASP:PNT|MDN:A1|NOR:ZU|NORK:NIK|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:GU|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HAIEK|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HAIEK|NORI:NIRI|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HAIEK|NORK:GUK|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HAIEK|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HAIEK|NORK:HARK|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HAIEK|NORK:NIK|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HURA|HIT:NO|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HURA|NORI:HAIEI|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HURA|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HURA|NORK:GUK|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HURA|NORK:HAIEK-K|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HURA|NORK:HARK|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HURA|NORK:NIK|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:HURA|NORK:NIK|NORI:HARI|MW:B
ADI	ADK	ASP:PNT|MDN:B1|NOR:NI|MW:B
ADI	ADK	ASP:PNT|MDN:B2|NOR:HAIEK|NORK:HIK|MW:B
ADI	ADK	ASP:PNT|MDN:B2|NOR:HURA|MW:B
ADI	ADK	ASP:PNT|MDN:B2|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	ASP:PNT|MDN:B2|NOR:HURA|NORK:NIK|HIT:NO|MW:B
ADI	ADK	ASP:PNT|MDN:B2|NOR:HURA|NORK:NIK|MW:B
ADI	ADK	ASP:PNT|MDN:B3|NOR:HURA|NORK:NIK|MW:B
ADI	ADK	ASP:PNT|MOD:EGI|MDN:A1|NOR:HURA|NORK:NIK|MW:B
ADI	ADK	ASP:PNT|MOD:EGI|MDN:B1|NOR:HURA|NORK:HARK|MW:B
ADI	ADK	MW:B
ADI	ADP	ADM:ADOIN|ASP:BURU|ERL:MOD
ADI	ADP	ASP:BURU
ADI	ADP	ASP:GERO
ADI	FAK	ADM:ADIZE|ERL:HELB|KAS:ABS|MUG:MG
ADI	FAK	ADM:ADIZE|ERL:HELB|KAS:ALA
ADI	FAK	ADM:ADIZE|ERL:KONPL|KAS:ABS
ADI	FAK	ADM:ADIZE|ERL:KONPL|KAS:INE
ADI	FAK	ADM:ADIZE|KAS:ABU
ADI	FAK	ADM:ADIZE|KAS:DAT|NUM:S|MUG:M
ADI	FAK	ADM:ADIZE|KAS:GEL
ADI	FAK	ADM:ADIZE|KAS:INS|NUM:S|MUG:M
ADI	FAK	ADM:ADOIN
ADI	FAK	ADM:ADOIN|ASP:EZBU
ADI	FAK	ADM:PART
ADI	FAK	ADM:PART|ASP:BURU
ADI	FAK	ADM:PART|ASP:GERO
ADI	FAK	ADM:PART|ERL:MOD
ADI	FAK	ADM:PART|KAS:ABS|MUG:MG
ADI	FAK	ADM:PART|KAS:ABS|NUM:S|MUG:M
ADI	FAK	ADM:PART|KAS:GEL
ADI	FAK	ADM:PART|KAS:INS|MUG:MG
ADI	FAK	ASP:EZBU
ADI	FAK	PLU:-|ADM:PART|ASP:BURU
ADI	SIN	ADM:ADIZE
ADI	SIN	ADM:ADIZE|ERL:BALD|KAS:INE
ADI	SIN	ADM:ADIZE|ERL:DENB|KAS:ABS
ADI	SIN	ADM:ADIZE|ERL:DENB|KAS:INE
ADI	SIN	ADM:ADIZE|ERL:HELB|KAS:ABS|MUG:MG
ADI	SIN	ADM:ADIZE|ERL:HELB|KAS:ALA
ADI	SIN	ADM:ADIZE|ERL:HELB|KAS:INE
ADI	SIN	ADM:ADIZE|ERL:KONPL|KAS:ABS
ADI	SIN	ADM:ADIZE|ERL:KONPL|KAS:ABS|ENT:Erakundea
ADI	SIN	ADM:ADIZE|ERL:KONPL|KAS:ABS|MUG:MG
ADI	SIN	ADM:ADIZE|ERL:KONPL|KAS:ABS|NUM:P|MUG:M
ADI	SIN	ADM:ADIZE|ERL:KONPL|KAS:ABS|NUM:S|MUG:M
ADI	SIN	ADM:ADIZE|ERL:KONPL|KAS:INE
ADI	SIN	ADM:ADIZE|ERL:KONPL|KAS:PAR
ADI	SIN	ADM:ADIZE|ERL:KONT|KAS:MOT
ADI	SIN	ADM:ADIZE|ERL:KONT|KAS:MOT|NUM:S|MUG:M
ADI	SIN	ADM:ADIZE|ERL:MOD|KAS:INE
ADI	SIN	ADM:ADIZE|KAS:ABL
ADI	SIN	ADM:ADIZE|KAS:ABS
ADI	SIN	ADM:ADIZE|KAS:ABS|ENT:Erakundea
ADI	SIN	ADM:ADIZE|KAS:ABS|NUM:P
ADI	SIN	ADM:ADIZE|KAS:ABS|NUM:S
ADI	SIN	ADM:ADIZE|KAS:ABU
ADI	SIN	ADM:ADIZE|KAS:ALA
ADI	SIN	ADM:ADIZE|KAS:DAT|NUM:S
ADI	SIN	ADM:ADIZE|KAS:DAT|NUM:S|MUG:M
ADI	SIN	ADM:ADIZE|KAS:ERG|NUM:S
ADI	SIN	ADM:ADIZE|KAS:ERG|NUM:S|MUG:M
ADI	SIN	ADM:ADIZE|KAS:GEL
ADI	SIN	ADM:ADIZE|KAS:GEN|NUM:S
ADI	SIN	ADM:ADIZE|KAS:GEN|NUM:S|MUG:M
ADI	SIN	ADM:ADIZE|KAS:INE
ADI	SIN	ADM:ADIZE|KAS:INE|NUM:S
ADI	SIN	ADM:ADIZE|KAS:INS|NUM:S
ADI	SIN	ADM:ADIZE|KAS:INS|NUM:S|MUG:M
ADI	SIN	ADM:ADIZE|KAS:MOT
ADI	SIN	ADM:ADIZE|KAS:MOT|NUM:S
ADI	SIN	ADM:ADIZE|KAS:PAR
ADI	SIN	ADM:ADIZE|KAS:PAR|ENT:Erakundea
ADI	SIN	ADM:ADIZE|KAS:SOZ|NUM:S
ADI	SIN	ADM:ADIZE|KAS:SOZ|NUM:S|MUG:M
ADI	SIN	ADM:ADOIN
ADI	SIN	ADM:ADOIN|ASP:BURU
ADI	SIN	ADM:ADOIN|ASP:EZBU
ADI	SIN	ADM:ADOIN|ENT:Pertsona
ADI	SIN	ADM:ADOIN|ERL:MOD
ADI	SIN	ADM:PART
ADI	SIN	ADM:PART|ASP:BURU
ADI	SIN	ADM:PART|ASP:GERO
ADI	SIN	ADM:PART|ERL:KONT|KAS:MOT|NUM:S|MUG:M
ADI	SIN	ADM:PART|ERL:MOD
ADI	SIN	ADM:PART|KAS:ABL|NUM:P
ADI	SIN	ADM:PART|KAS:ABL|NUM:P|MUG:M
ADI	SIN	ADM:PART|KAS:ABL|NUM:S
ADI	SIN	ADM:PART|KAS:ABL|NUM:S|MUG:M
ADI	SIN	ADM:PART|KAS:ABS
ADI	SIN	ADM:PART|KAS:ABS|MUG:MG
ADI	SIN	ADM:PART|KAS:ABS|NUM:P
ADI	SIN	ADM:PART|KAS:ABS|NUM:P|ENT:Erakundea
ADI	SIN	ADM:PART|KAS:ABS|NUM:P|MUG:M
ADI	SIN	ADM:PART|KAS:ABS|NUM:P|MUG:M|ENT:Erakundea
ADI	SIN	ADM:PART|KAS:ABS|NUM:S
ADI	SIN	ADM:PART|KAS:ABS|NUM:S|MUG:M
ADI	SIN	ADM:PART|KAS:ALA
ADI	SIN	ADM:PART|KAS:ALA|MUG:MG
ADI	SIN	ADM:PART|KAS:ALA|NUM:P
ADI	SIN	ADM:PART|KAS:ALA|NUM:P|MUG:M
ADI	SIN	ADM:PART|KAS:ALA|NUM:S
ADI	SIN	ADM:PART|KAS:ALA|NUM:S|MUG:M
ADI	SIN	ADM:PART|KAS:DAT|NUM:P
ADI	SIN	ADM:PART|KAS:DAT|NUM:P|MUG:M
ADI	SIN	ADM:PART|KAS:DAT|NUM:S
ADI	SIN	ADM:PART|KAS:DAT|NUM:S|MUG:M
ADI	SIN	ADM:PART|KAS:ERG|NUM:P
ADI	SIN	ADM:PART|KAS:ERG|NUM:P|MUG:M
ADI	SIN	ADM:PART|KAS:ERG|NUM:S
ADI	SIN	ADM:PART|KAS:ERG|NUM:S|MUG:M
ADI	SIN	ADM:PART|KAS:GEL
ADI	SIN	ADM:PART|KAS:GEL|MUG:MG
ADI	SIN	ADM:PART|KAS:GEL|NUM:P
ADI	SIN	ADM:PART|KAS:GEL|NUM:P|MUG:M
ADI	SIN	ADM:PART|KAS:GEL|NUM:S
ADI	SIN	ADM:PART|KAS:GEL|NUM:S|ENT:Erakundea
ADI	SIN	ADM:PART|KAS:GEL|NUM:S|ENT:Tokia
ADI	SIN	ADM:PART|KAS:GEL|NUM:S|MUG:M
ADI	SIN	ADM:PART|KAS:GEL|NUM:S|MUG:M|ENT:Erakundea
ADI	SIN	ADM:PART|KAS:GEL|NUM:S|MUG:M|ENT:Tokia
ADI	SIN	ADM:PART|KAS:GEN
ADI	SIN	ADM:PART|KAS:GEN|MUG:MG
ADI	SIN	ADM:PART|KAS:GEN|NUM:P
ADI	SIN	ADM:PART|KAS:GEN|NUM:P|ENT:Tokia
ADI	SIN	ADM:PART|KAS:GEN|NUM:P|MUG:M
ADI	SIN	ADM:PART|KAS:GEN|NUM:P|MUG:M|ENT:Tokia
ADI	SIN	ADM:PART|KAS:GEN|NUM:S
ADI	SIN	ADM:PART|KAS:GEN|NUM:S|MUG:M
ADI	SIN	ADM:PART|KAS:INE|NUM:P
ADI	SIN	ADM:PART|KAS:INE|NUM:P|MUG:M
ADI	SIN	ADM:PART|KAS:INE|NUM:S
ADI	SIN	ADM:PART|KAS:INE|NUM:S|ENT:Tokia
ADI	SIN	ADM:PART|KAS:INE|NUM:S|MUG:M
ADI	SIN	ADM:PART|KAS:INE|NUM:S|MUG:M|ENT:Tokia
ADI	SIN	ADM:PART|KAS:INS
ADI	SIN	ADM:PART|KAS:INS|MUG:MG
ADI	SIN	ADM:PART|KAS:INS|NUM:P
ADI	SIN	ADM:PART|KAS:INS|NUM:P|MUG:M
ADI	SIN	ADM:PART|KAS:INS|NUM:S
ADI	SIN	ADM:PART|KAS:INS|NUM:S|MUG:M
ADI	SIN	ADM:PART|KAS:MOT|NUM:S
ADI	SIN	ADM:PART|KAS:PAR
ADI	SIN	ADM:PART|KAS:PAR|MUG:MG
ADI	SIN	ADM:PART|KAS:PRO
ADI	SIN	ADM:PART|KAS:PRO|MUG:MG
ADI	SIN	ADM:PART|KAS:SOZ|NUM:P
ADI	SIN	ADM:PART|KAS:SOZ|NUM:P|MUG:M
ADI	SIN	ADM:PART|KAS:SOZ|NUM:S
ADI	SIN	ADM:PART|KAS:SOZ|NUM:S|MUG:M
ADI	SIN	ASP:BURU
ADI	SIN	ASP:EZBU
ADI	SIN	ASP:GERO
ADI	SIN	ASP:PNT|KAS:ABS|NUM:P|NOR:HURA|NORK:HAIEK-K
ADI	SIN	ASP:PNT|KAS:ABS|NUM:S|NOR:HURA
ADI	SIN	ASP:PNT|KAS:ABS|NUM:S|NOR:HURA|NORK:GUK
ADI	SIN	ASP:PNT|KAS:ABS|NUM:S|NOR:HURA|NORK:HAIEK-K
ADI	SIN	ASP:PNT|KAS:ABS|NUM:S|NOR:HURA|NORK:HARK
ADI	SIN	ASP:PNT|KAS:ABS|NUM:S|NOR:HURA|NORK:NIK
ADI	SIN	ASP:PNT|KAS:ABS|NUM:S|NOR:HURA|NORK:ZUK
ADI	SIN	ASP:PNT|KAS:ALA|NUM:S|NOR:HURA|NORK:HAIEK-K
ADI	SIN	ASP:PNT|KAS:DAT|NUM:S|NOR:HURA
ADI	SIN	ASP:PNT|KAS:DES|NUM:S|NOR:HURA|NORK:HARK
ADI	SIN	ASP:PNT|KAS:ERG|NUM:P|NOR:HURA|NORK:HAIEK-K
ADI	SIN	ASP:PNT|KAS:ERG|NUM:S|NOR:HURA|NORK:HARK
ADI	SIN	ASP:PNT|KAS:GEN|NUM:P|NOR:HURA|NORK:HAIEK-K
ADI	SIN	ASP:PNT|KAS:GEN|NUM:S|NOR:HURA|NORK:HAIEK-K
ADI	SIN	ASP:PNT|KAS:PAR|NOR:HURA
ADI	SIN	ASP:PNT|NOR:GU
ADI	SIN	ASP:PNT|NOR:GU|NORK:HARK
ADI	SIN	ASP:PNT|NOR:HAIEK
ADI	SIN	ASP:PNT|NOR:HAIEK|NORI:HAIEI
ADI	SIN	ASP:PNT|NOR:HAIEK|NORI:HARI
ADI	SIN	ASP:PNT|NOR:HAIEK|NORI:NIRI
ADI	SIN	ASP:PNT|NOR:HAIEK|NORK:GUK
ADI	SIN	ASP:PNT|NOR:HAIEK|NORK:GUK|ENT:Erakundea
ADI	SIN	ASP:PNT|NOR:HAIEK|NORK:HAIEK-K
ADI	SIN	ASP:PNT|NOR:HAIEK|NORK:HAIEK-K|NORI:HARI
ADI	SIN	ASP:PNT|NOR:HAIEK|NORK:HARK
ADI	SIN	ASP:PNT|NOR:HAIEK|NORK:HARK|NORI:HAIEI
ADI	SIN	ASP:PNT|NOR:HAIEK|NORK:HARK|NORI:HARI
ADI	SIN	ASP:PNT|NOR:HAIEK|NORK:HIK
ADI	SIN	ASP:PNT|NOR:HAIEK|NORK:NIK
ADI	SIN	ASP:PNT|NOR:HAIEK|NORK:NIK|NORI:HARI
ADI	SIN	ASP:PNT|NOR:HAIEK|NORK:ZUEK-K
ADI	SIN	ASP:PNT|NOR:HI|NORK:HARK
ADI	SIN	ASP:PNT|NOR:HURA
ADI	SIN	ASP:PNT|NOR:HURA|HIT:NO
ADI	SIN	ASP:PNT|NOR:HURA|NORI:GURI
ADI	SIN	ASP:PNT|NOR:HURA|NORI:HAIEI
ADI	SIN	ASP:PNT|NOR:HURA|NORI:HARI
ADI	SIN	ASP:PNT|NOR:HURA|NORI:HIRI-NO
ADI	SIN	ASP:PNT|NOR:HURA|NORI:NIRI
ADI	SIN	ASP:PNT|NOR:HURA|NORK:GUK
ADI	SIN	ASP:PNT|NOR:HURA|NORK:GUK|ENT:Pertsona
ADI	SIN	ASP:PNT|NOR:HURA|NORK:GUK|HIT:NO
ADI	SIN	ASP:PNT|NOR:HURA|NORK:GUK|NORI:HARI
ADI	SIN	ASP:PNT|NOR:HURA|NORK:GUK|NORI:HIRI-TO
ADI	SIN	ASP:PNT|NOR:HURA|NORK:HAIEK-K
ADI	SIN	ASP:PNT|NOR:HURA|NORK:HAIEK-K|NORI:HAIEI
ADI	SIN	ASP:PNT|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADI	SIN	ASP:PNT|NOR:HURA|NORK:HARK
ADI	SIN	ASP:PNT|NOR:HURA|NORK:HARK|HIT:NO
ADI	SIN	ASP:PNT|NOR:HURA|NORK:HARK|HIT:TO
ADI	SIN	ASP:PNT|NOR:HURA|NORK:HARK|NORI:GURI
ADI	SIN	ASP:PNT|NOR:HURA|NORK:HARK|NORI:HAIEI
ADI	SIN	ASP:PNT|NOR:HURA|NORK:HARK|NORI:HARI
ADI	SIN	ASP:PNT|NOR:HURA|NORK:HIK-TO
ADI	SIN	ASP:PNT|NOR:HURA|NORK:HIK|NORI:HARI
ADI	SIN	ASP:PNT|NOR:HURA|NORK:NIK
ADI	SIN	ASP:PNT|NOR:HURA|NORK:NIK|HIT:NO
ADI	SIN	ASP:PNT|NOR:HURA|NORK:NIK|NORI:HARI
ADI	SIN	ASP:PNT|NOR:HURA|NORK:NIK|NORI:ZUEI
ADI	SIN	ASP:PNT|NOR:HURA|NORK:ZUEK-K
ADI	SIN	ASP:PNT|NOR:HURA|NORK:ZUK
ADI	SIN	ASP:PNT|NOR:NI
ADI	SIN	ASP:PNT|NOR:NI|NORK:HARK
ADI	SIN	ASP:PNT|NOR:NI|NORK:ZUK
ADI	SIN	ASP:PNT|NOR:ZU
ADI	SIN	ASP:PNT|NOR:ZUEK
ADI	SIN	ASP:PNT|NOR:ZU|NORK:NIK
ADI	SIN	MAI:KONP|ADM:PART|KAS:ABS
ADI	SIN	MAI:KONP|ADM:PART|KAS:ABS|MUG:MG
ADI	SIN	MAI:KONP|ADM:PART|KAS:ABS|NUM:P
ADI	SIN	MAI:KONP|ADM:PART|KAS:ABS|NUM:P|MUG:M
ADI	SIN	MAI:KONP|ADM:PART|KAS:ABS|NUM:S
ADI	SIN	MAI:KONP|ADM:PART|KAS:ABS|NUM:S|MUG:M
ADI	SIN	MAI:SUP|ADM:PART|KAS:ABS|NUM:P
ADI	SIN	MAI:SUP|ADM:PART|KAS:ABS|NUM:P|MUG:M
ADI	SIN	MAI:SUP|ADM:PART|KAS:ABS|NUM:S
ADI	SIN	MAI:SUP|ADM:PART|KAS:ABS|NUM:S|MUG:M
ADI	SIN	MAI:SUP|ADM:PART|KAS:GEN|NUM:P
ADI	SIN	MAI:SUP|ADM:PART|KAS:GEN|NUM:P|MUG:M
ADI	SIN	MAI:SUP|ADM:PART|KAS:INE|NUM:S
ADI	SIN	MAI:SUP|ADM:PART|KAS:INE|NUM:S|MUG:M
ADI	SIN	_
ADJ	ARR	BIZ:-
ADJ	ARR	BIZ:-|ENT:Erakundea
ADJ	ARR	BIZ:-|KAS:ABS
ADJ	ARR	BIZ:-|KAS:INE
ADJ	ARR	BIZ:-|MUG:MG|KAS:ABS
ADJ	ARR	BIZ:-|MUG:MG|KAS:INE
ADJ	ARR	BIZ:-|MUG:M|MW:B|ENT:Erakundea
ADJ	ARR	BIZ:-|NUM:P|KAS:ABS
ADJ	ARR	BIZ:-|NUM:P|KAS:DAT
ADJ	ARR	BIZ:-|NUM:P|MUG:M|KAS:ABS
ADJ	ARR	BIZ:-|NUM:P|MUG:M|KAS:DAT
ADJ	ARR	BIZ:-|NUM:S|KAS:ABS
ADJ	ARR	BIZ:-|NUM:S|KAS:ABS|MAI:SUP
ADJ	ARR	BIZ:-|NUM:S|KAS:ERG
ADJ	ARR	BIZ:-|NUM:S|MUG:M|KAS:ABS
ADJ	ARR	BIZ:-|NUM:S|MUG:M|KAS:ABS|MAI:SUP
ADJ	ARR	BIZ:-|NUM:S|MUG:M|KAS:ERG
ADJ	ARR	ENT:Erakundea
ADJ	ARR	ENT:Pertsona
ADJ	ARR	ENT:Tokia
ADJ	ARR	IZAUR:+
ADJ	ARR	IZAUR:+|ENT:Erakundea
ADJ	ARR	IZAUR:+|ENT:Pertsona
ADJ	ARR	IZAUR:+|ENT:Tokia
ADJ	ARR	IZAUR:+|KAS:INE|POS:POSinguruetan|POS:+
ADJ	ARR	IZAUR:+|MUG:MG|KAS:ABS
ADJ	ARR	IZAUR:+|MUG:MG|KAS:ABS|MAI:SUP
ADJ	ARR	IZAUR:+|MUG:MG|KAS:DES
ADJ	ARR	IZAUR:+|MUG:MG|KAS:ERG
ADJ	ARR	IZAUR:+|MUG:MG|KAS:INE
ADJ	ARR	IZAUR:+|MUG:MG|KAS:INS
ADJ	ARR	IZAUR:+|MUG:MG|KAS:PAR
ADJ	ARR	IZAUR:+|MUG:MG|KAS:PRO
ADJ	ARR	IZAUR:+|MW:B
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:ABL|POS:POSaurretik|POS:+
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:ABL|POS:POSeskutik|POS:+
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:ABL|POS:POSgainetik|POS:+
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:ABS
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:ABS|MAI:KONP
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:ABS|MAI:SUP
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:DAT
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:EM|POS:POSarteko|POS:+
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:ERG
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:GEL
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:GEL|POS:POSarteko|POS:+
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:GEL|POS:POSaurkako|POS:+
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:GEL|POS:POSkontrako|POS:+
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:GEN
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:GEN|ENT:Erakundea
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:INE
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:INE|POS:POSartean|POS:+
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:INS
ADJ	ARR	IZAUR:+|NUM:P|MUG:M|KAS:SOZ
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:ABL|POS:POSaurretik|POS:+
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:ABL|POS:POSgibeletik|POS:+
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:ABS
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:ABS|ENT:Erakundea
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:ABS|MAI:KONP
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:ABS|MAI:SUP
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:ABS|MW:B
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:ABS|POS:POSaurka|POS:+
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:DAT
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:DES
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:EM|POS:POSkontra|POS:+
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:ERG
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:GEL
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:GEL|ENT:Erakundea
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:GEL|ENT:Tokia
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:GEL|POS:POSkontrako|POS:+
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:GEN
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:GEN|ENT:Erakundea
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:INE
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:INE|ENT:Erakundea
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:INE|POS:POSaurrean|POS:+
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:INS
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:MOT
ADJ	ARR	IZAUR:+|NUM:S|MUG:M|KAS:SOZ
ADJ	ARR	IZAUR:-
ADJ	ARR	IZAUR:-|ENT:Erakundea
ADJ	ARR	IZAUR:-|ENT:Pertsona
ADJ	ARR	IZAUR:-|ENT:Tokia
ADJ	ARR	IZAUR:-|KAS:ABL|POS:POSaldetik|POS:+
ADJ	ARR	IZAUR:-|KAS:ABS|POS:POSgisa|POS:+
ADJ	ARR	IZAUR:-|KAS:EM|POS:POSbarik|POS:+
ADJ	ARR	IZAUR:-|KAS:EM|POS:POSbezala|POS:+
ADJ	ARR	IZAUR:-|MAI:GEHI
ADJ	ARR	IZAUR:-|MAI:KONP
ADJ	ARR	IZAUR:-|MAI:SUP
ADJ	ARR	IZAUR:-|MUG:MG|KAS:ABL
ADJ	ARR	IZAUR:-|MUG:MG|KAS:ABL|MAI:SUP
ADJ	ARR	IZAUR:-|MUG:MG|KAS:ABL|POS:POSgainetik|POS:+
ADJ	ARR	IZAUR:-|MUG:MG|KAS:ABS
ADJ	ARR	IZAUR:-|MUG:MG|KAS:ABS|ENT:???
ADJ	ARR	IZAUR:-|MUG:MG|KAS:ABS|ENT:Erakundea
ADJ	ARR	IZAUR:-|MUG:MG|KAS:ABS|MAI:GEHI
ADJ	ARR	IZAUR:-|MUG:MG|KAS:ABS|MAI:KONP
ADJ	ARR	IZAUR:-|MUG:MG|KAS:ABS|MAI:SUP
ADJ	ARR	IZAUR:-|MUG:MG|KAS:ABS|POS:POSaurka|POS:+
ADJ	ARR	IZAUR:-|MUG:MG|KAS:ABS|POS:POSgain|POS:+
ADJ	ARR	IZAUR:-|MUG:MG|KAS:ALA
ADJ	ARR	IZAUR:-|MUG:MG|KAS:BNK
ADJ	ARR	IZAUR:-|MUG:MG|KAS:DAT
ADJ	ARR	IZAUR:-|MUG:MG|KAS:DES
ADJ	ARR	IZAUR:-|MUG:MG|KAS:EM|POS:POSgabe|POS:+
ADJ	ARR	IZAUR:-|MUG:MG|KAS:ERG
ADJ	ARR	IZAUR:-|MUG:MG|KAS:ERG|ENT:Pertsona
ADJ	ARR	IZAUR:-|MUG:MG|KAS:GEL
ADJ	ARR	IZAUR:-|MUG:MG|KAS:GEL|POS:POSarteko|POS:+
ADJ	ARR	IZAUR:-|MUG:MG|KAS:GEL|POS:POSburuzko|POS:+
ADJ	ARR	IZAUR:-|MUG:MG|KAS:GEL|POS:POSgabeko|POS:+
ADJ	ARR	IZAUR:-|MUG:MG|KAS:GEN
ADJ	ARR	IZAUR:-|MUG:MG|KAS:INE
ADJ	ARR	IZAUR:-|MUG:MG|KAS:INS
ADJ	ARR	IZAUR:-|MUG:MG|KAS:INS|MAI:KONP
ADJ	ARR	IZAUR:-|MUG:MG|KAS:PAR
ADJ	ARR	IZAUR:-|MUG:MG|KAS:PAR|MAI:GEHI
ADJ	ARR	IZAUR:-|MUG:MG|KAS:PAR|MAI:SUP
ADJ	ARR	IZAUR:-|MUG:MG|KAS:PRO
ADJ	ARR	IZAUR:-|MUG:MG|KAS:PRO|MAI:SUP
ADJ	ARR	IZAUR:-|MUG:MG|KAS:SOZ
ADJ	ARR	IZAUR:-|MUG:M|MW:B
ADJ	ARR	IZAUR:-|MW:B
ADJ	ARR	IZAUR:-|NUM:PH|MUG:M|KAS:ABS
ADJ	ARR	IZAUR:-|NUM:PH|MUG:M|KAS:ERG
ADJ	ARR	IZAUR:-|NUM:PH|MUG:M|KAS:INE
ADJ	ARR	IZAUR:-|NUM:P|KAS:ABS
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ABL
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ABL|POS:POSaldetik|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ABL|POS:POSazpitik|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ABL|POS:POSondotik|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ABS
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ABS|ENT:???
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ABS|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ABS|MAI:GEHI
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ABS|MAI:KONP
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ABS|MAI:SUP
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ABS|MAI:SUP|POS:POSpare|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ABS|POS:POSalde|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ABS|POS:POSaurka|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ABS|POS:POSesker|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ABU
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ALA
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ALA|MAI:SUP
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ALA|POS:POSgainera|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:DAT
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:DAT|MAI:SUP
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:DES
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:EM|MAI:KONP|POS:POSbila|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:EM|POS:POSarabera|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:EM|POS:POSbezala|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:EM|POS:POSbila|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:EM|POS:POSburuz|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:EM|POS:POSzain|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:EM|POS:POSzehar|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ERG
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ERG|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:ERG|MAI:SUP
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:GEL
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:GEL|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:GEL|MAI:SUP
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:GEL|MAI:SUP|POS:POSarteko|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:GEL|POS:POSarteko|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:GEL|POS:POSaurkako|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:GEL|POS:POSaurreko|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:GEL|POS:POSburuzko|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:GEL|POS:POSgaineko|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:GEL|POS:POSinguruko|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:GEL|POS:POSkontrako|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:GEN
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:GEN|MAI:SUP
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:INE
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:INE|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:INE|MAI:KONP
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:INE|MAI:SUP
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:INE|MAI:SUP|POS:POSartean|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:INE|MAI:SUP|POS:POSparean|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:INE|POS:POSartean|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:INE|POS:POSaurrean|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:INE|POS:POSazpian|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:INE|POS:POSinguruan|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:INE|POS:POSondoan|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:INE|POS:POSostean|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:INS
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:INS|POS:POSbidez|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:INS|POS:POSbitartez|POS:+
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:MOT
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:SOZ
ADJ	ARR	IZAUR:-|NUM:P|MUG:M|KAS:SOZ|MAI:SUP
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABL
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABL|ENT:???
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABL|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABL|ENT:Tokia
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABS
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABS|ENT:???
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABS|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABS|ENT:Tokia
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABS|MAI:GEHI
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABS|MAI:KONP
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABS|MAI:KONP|POS:POStruke|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABS|MAI:SUP
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABS|MW:B
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABS|POS:POSalde|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABS|POS:POSarteko|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABS|POS:POSaurka|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABS|POS:POSesker|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABS|POS:POSesku|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABU|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABZ
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABZ|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABZ|ENT:Pertsona
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ABZ|ENT:Tokia
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ALA
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ALA|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ALA|ENT:Tokia
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ALA|MAI:KONP
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ALA|MAI:SUP
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ALA|POS:POSalderat|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ALA|POS:POSaurrera|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ALA|POS:POSbatera|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:DAT
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:DAT|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:DAT|MAI:SUP
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:DES
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:EM|MAI:SUP|POS:POSzain|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:EM|POS:POSarabera|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:EM|POS:POSarabera|POS:+|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:EM|POS:POSbarna|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:EM|POS:POSbatera|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:EM|POS:POSbegira|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:EM|POS:POSbezala|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:EM|POS:POSburuz|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:EM|POS:POSgora|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:EM|POS:POSondoren|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:EM|POS:POSordez|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:EM|POS:POSzehar|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ERG
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ERG|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ERG|MAI:SUP
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:ERG|MAI:SUP|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:GEL
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:GEL|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:GEL|ENT:Pertsona
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:GEL|ENT:Tokia
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:GEL|MAI:KONP
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:GEL|MAI:SUP
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:GEL|POS:POSaldeko|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:GEL|POS:POSarteko|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:GEL|POS:POSburuzko|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:GEL|POS:POSinguruko|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:GEL|POS:POSkontrako|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:GEN
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:GEN|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:GEN|MAI:KONP
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:GEN|MAI:SUP
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:INE
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:INE|ENT:???
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:INE|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:INE|ENT:Tokia
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:INE|MAI:KONP
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:INE|MAI:SUP
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:INE|POS:POSartean|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:INE|POS:POSaurrean|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:INE|POS:POSgainean|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:INE|POS:POSinguruan|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:INS
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:INS|ENT:Tokia
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:INS|POS:POSbidez|POS:+
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:MOT
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:MOT|MAI:KONP
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:SOZ
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:SOZ|ENT:Erakundea
ADJ	ARR	IZAUR:-|NUM:S|MUG:M|KAS:SOZ|MAI:KONP
ADJ	ARR	KAS:ABL
ADJ	ARR	KAS:ABL|MAI:SUP
ADJ	ARR	KAS:ABS
ADJ	ARR	KAS:ABS|ENT:???
ADJ	ARR	KAS:ABS|ENT:Erakundea
ADJ	ARR	KAS:ABS|MAI:GEHI
ADJ	ARR	KAS:ABS|MAI:KONP
ADJ	ARR	KAS:ABS|MAI:SUP
ADJ	ARR	KAS:ALA
ADJ	ARR	KAS:DAT
ADJ	ARR	KAS:DES
ADJ	ARR	KAS:EM
ADJ	ARR	KAS:ERG
ADJ	ARR	KAS:ERG|ENT:Erakundea
ADJ	ARR	KAS:ERG|ENT:Pertsona
ADJ	ARR	KAS:GEL
ADJ	ARR	KAS:GEN
ADJ	ARR	KAS:INE
ADJ	ARR	KAS:INS
ADJ	ARR	KAS:INS|MAI:KONP
ADJ	ARR	KAS:PAR
ADJ	ARR	KAS:PAR|MAI:GEHI
ADJ	ARR	KAS:PAR|MAI:SUP
ADJ	ARR	KAS:PRO
ADJ	ARR	KAS:PRO|MAI:SUP
ADJ	ARR	KAS:SOZ
ADJ	ARR	MAI:GEHI
ADJ	ARR	MAI:KONP
ADJ	ARR	MAI:SUP
ADJ	ARR	MUG:MG|KAS:ABS
ADJ	ARR	MUG:MG|KAS:ERG|ENT:Erakundea
ADJ	ARR	MUG:MG|KAS:INS
ADJ	ARR	MUG:MG|KAS:PAR
ADJ	ARR	NUM:PH|MUG:M|KAS:ERG|ENT:Erakundea
ADJ	ARR	NUM:P|KAS:ABL
ADJ	ARR	NUM:P|KAS:ABS
ADJ	ARR	NUM:P|KAS:ABS|ENT:???
ADJ	ARR	NUM:P|KAS:ABS|ENT:Erakundea
ADJ	ARR	NUM:P|KAS:ABS|MAI:GEHI
ADJ	ARR	NUM:P|KAS:ABS|MAI:KONP
ADJ	ARR	NUM:P|KAS:ABS|MAI:SUP
ADJ	ARR	NUM:P|KAS:ABU
ADJ	ARR	NUM:P|KAS:ALA
ADJ	ARR	NUM:P|KAS:ALA|MAI:SUP
ADJ	ARR	NUM:P|KAS:DAT
ADJ	ARR	NUM:P|KAS:DAT|MAI:SUP
ADJ	ARR	NUM:P|KAS:DES
ADJ	ARR	NUM:P|KAS:EM
ADJ	ARR	NUM:P|KAS:EM|MAI:KONP
ADJ	ARR	NUM:P|KAS:ERG
ADJ	ARR	NUM:P|KAS:ERG|ENT:Erakundea
ADJ	ARR	NUM:P|KAS:ERG|MAI:SUP
ADJ	ARR	NUM:P|KAS:GEL
ADJ	ARR	NUM:P|KAS:GEL|ENT:Erakundea
ADJ	ARR	NUM:P|KAS:GEL|MAI:SUP
ADJ	ARR	NUM:P|KAS:GEN
ADJ	ARR	NUM:P|KAS:GEN|ENT:Erakundea
ADJ	ARR	NUM:P|KAS:GEN|MAI:SUP
ADJ	ARR	NUM:P|KAS:INE
ADJ	ARR	NUM:P|KAS:INE|ENT:Erakundea
ADJ	ARR	NUM:P|KAS:INE|MAI:KONP
ADJ	ARR	NUM:P|KAS:INE|MAI:SUP
ADJ	ARR	NUM:P|KAS:INS
ADJ	ARR	NUM:P|KAS:MOT
ADJ	ARR	NUM:P|KAS:SOZ
ADJ	ARR	NUM:P|KAS:SOZ|MAI:SUP
ADJ	ARR	NUM:P|MUG:M|KAS:ABS
ADJ	ARR	NUM:P|MUG:M|KAS:ABS|ENT:???
ADJ	ARR	NUM:P|MUG:M|KAS:DAT
ADJ	ARR	NUM:P|MUG:M|KAS:DES
ADJ	ARR	NUM:P|MUG:M|KAS:ERG
ADJ	ARR	NUM:P|MUG:M|KAS:ERG|MAI:SUP
ADJ	ARR	NUM:P|MUG:M|KAS:GEL|POS:POSarteko|POS:+
ADJ	ARR	NUM:P|MUG:M|KAS:GEN
ADJ	ARR	NUM:P|MUG:M|KAS:INE
ADJ	ARR	NUM:P|MUG:M|KAS:INE|POS:POSinguruan|POS:+
ADJ	ARR	NUM:P|MUG:M|KAS:MOT
ADJ	ARR	NUM:P|MUG:M|KAS:SOZ
ADJ	ARR	NUM:S|KAS:ABL
ADJ	ARR	NUM:S|KAS:ABL|ENT:???
ADJ	ARR	NUM:S|KAS:ABL|ENT:Erakundea
ADJ	ARR	NUM:S|KAS:ABL|ENT:Tokia
ADJ	ARR	NUM:S|KAS:ABS
ADJ	ARR	NUM:S|KAS:ABS|ENT:???
ADJ	ARR	NUM:S|KAS:ABS|ENT:Erakundea
ADJ	ARR	NUM:S|KAS:ABS|ENT:Tokia
ADJ	ARR	NUM:S|KAS:ABS|MAI:GEHI
ADJ	ARR	NUM:S|KAS:ABS|MAI:KONP
ADJ	ARR	NUM:S|KAS:ABS|MAI:SUP
ADJ	ARR	NUM:S|KAS:ABU|ENT:Erakundea
ADJ	ARR	NUM:S|KAS:ABZ
ADJ	ARR	NUM:S|KAS:ABZ|ENT:Erakundea
ADJ	ARR	NUM:S|KAS:ABZ|ENT:Pertsona
ADJ	ARR	NUM:S|KAS:ABZ|ENT:Tokia
ADJ	ARR	NUM:S|KAS:ALA
ADJ	ARR	NUM:S|KAS:ALA|ENT:Erakundea
ADJ	ARR	NUM:S|KAS:ALA|ENT:Tokia
ADJ	ARR	NUM:S|KAS:ALA|MAI:KONP
ADJ	ARR	NUM:S|KAS:ALA|MAI:SUP
ADJ	ARR	NUM:S|KAS:DAT
ADJ	ARR	NUM:S|KAS:DAT|ENT:Erakundea
ADJ	ARR	NUM:S|KAS:DAT|MAI:SUP
ADJ	ARR	NUM:S|KAS:DES
ADJ	ARR	NUM:S|KAS:EM
ADJ	ARR	NUM:S|KAS:EM|ENT:Erakundea
ADJ	ARR	NUM:S|KAS:EM|MAI:SUP
ADJ	ARR	NUM:S|KAS:ERG
ADJ	ARR	NUM:S|KAS:ERG|ENT:Erakundea
ADJ	ARR	NUM:S|KAS:ERG|ENT:Pertsona
ADJ	ARR	NUM:S|KAS:ERG|MAI:SUP
ADJ	ARR	NUM:S|KAS:ERG|MAI:SUP|ENT:Erakundea
ADJ	ARR	NUM:S|KAS:GEL
ADJ	ARR	NUM:S|KAS:GEL|ENT:Erakundea
ADJ	ARR	NUM:S|KAS:GEL|ENT:Pertsona
ADJ	ARR	NUM:S|KAS:GEL|ENT:Tokia
ADJ	ARR	NUM:S|KAS:GEL|MAI:KONP
ADJ	ARR	NUM:S|KAS:GEL|MAI:SUP
ADJ	ARR	NUM:S|KAS:GEN
ADJ	ARR	NUM:S|KAS:GEN|ENT:Erakundea
ADJ	ARR	NUM:S|KAS:GEN|MAI:KONP
ADJ	ARR	NUM:S|KAS:GEN|MAI:SUP
ADJ	ARR	NUM:S|KAS:INE
ADJ	ARR	NUM:S|KAS:INE|ENT:???
ADJ	ARR	NUM:S|KAS:INE|ENT:Erakundea
ADJ	ARR	NUM:S|KAS:INE|ENT:Tokia
ADJ	ARR	NUM:S|KAS:INE|MAI:KONP
ADJ	ARR	NUM:S|KAS:INE|MAI:SUP
ADJ	ARR	NUM:S|KAS:INS
ADJ	ARR	NUM:S|KAS:INS|ENT:Tokia
ADJ	ARR	NUM:S|KAS:MOT
ADJ	ARR	NUM:S|KAS:MOT|MAI:KONP
ADJ	ARR	NUM:S|KAS:SOZ
ADJ	ARR	NUM:S|KAS:SOZ|ENT:Erakundea
ADJ	ARR	NUM:S|KAS:SOZ|MAI:KONP
ADJ	ARR	NUM:S|MUG:M|KAS:ABL
ADJ	ARR	NUM:S|MUG:M|KAS:ABS
ADJ	ARR	NUM:S|MUG:M|KAS:ABS|ENT:Tokia
ADJ	ARR	NUM:S|MUG:M|KAS:ABS|MAI:SUP
ADJ	ARR	NUM:S|MUG:M|KAS:ALA
ADJ	ARR	NUM:S|MUG:M|KAS:DAT
ADJ	ARR	NUM:S|MUG:M|KAS:ERG
ADJ	ARR	NUM:S|MUG:M|KAS:ERG|ENT:Erakundea
ADJ	ARR	NUM:S|MUG:M|KAS:ERG|ENT:Pertsona
ADJ	ARR	NUM:S|MUG:M|KAS:GEL
ADJ	ARR	NUM:S|MUG:M|KAS:GEL|ENT:Erakundea
ADJ	ARR	NUM:S|MUG:M|KAS:GEN
ADJ	ARR	NUM:S|MUG:M|KAS:INE
ADJ	ARR	NUM:S|MUG:M|KAS:INE|MAI:SUP
ADJ	ARR	NUM:S|MUG:M|KAS:SOZ
ADJ	ARR	_
ADJ	GAL	NUM:P|MUG:M|KAS:ABS
ADJ	GAL	NUM:S|MUG:M|KAS:ABS
ADJ	GAL	NUM:S|MUG:M|MW:B
ADJ	GAL	_
ADL	ADL	ERL:BALD|MDN:A1|NOR:GU
ADL	ADL	ERL:BALD|MDN:A1|NOR:GU|NORI:HARI
ADL	ADL	ERL:BALD|MDN:A1|NOR:HAIEK
ADL	ADL	ERL:BALD|MDN:A1|NOR:HAIEK|NORK:GUK
ADL	ADL	ERL:BALD|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	ERL:BALD|MDN:A1|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:BALD|MDN:A1|NOR:HAIEK|NORK:ZUK
ADL	ADL	ERL:BALD|MDN:A1|NOR:HURA
ADL	ADL	ERL:BALD|MDN:A1|NOR:HURA|NORI:GURI
ADL	ADL	ERL:BALD|MDN:A1|NOR:HURA|NORI:ZURI
ADL	ADL	ERL:BALD|MDN:A1|NOR:HURA|NORK:GUK
ADL	ADL	ERL:BALD|MDN:A1|NOR:HURA|NORK:GUK|NORI:HARI
ADL	ADL	ERL:BALD|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:BALD|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:GURI
ADL	ADL	ERL:BALD|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	ERL:BALD|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:BALD|MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:BALD|MDN:A1|NOR:HURA|NORK:NIK
ADL	ADL	ERL:BALD|MDN:A1|NOR:HURA|NORK:ZUK
ADL	ADL	ERL:BALD|MDN:A1|NOR:HURA|NORK:ZUK|NORI:HAIEI
ADL	ADL	ERL:BALD|MDN:A1|NOR:HURA|NORK:ZUK|NORI:HARI
ADL	ADL	ERL:BALD|MDN:A1|NOR:HURA|NORK:ZUK|NORI:NIRI
ADL	ADL	ERL:BALD|MDN:A1|NOR:NI
ADL	ADL	ERL:BALD|MDN:A1|NOR:ZU
ADL	ADL	ERL:BALD|MDN:A5|NOR:HURA|NORK:HARK
ADL	ADL	ERL:BALD|MDN:B1|NOR:GU
ADL	ADL	ERL:BALD|MDN:B1|NOR:HAIEK
ADL	ADL	ERL:BALD|MDN:B1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	ERL:BALD|MDN:B1|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:BALD|MDN:B1|NOR:HURA
ADL	ADL	ERL:BALD|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:BALD|MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:BALD|MDN:B4|NOR:HAIEK
ADL	ADL	ERL:BALD|MDN:B4|NOR:HAIEK|NORK:GUK
ADL	ADL	ERL:BALD|MDN:B4|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:BALD|MDN:B4|NOR:HAIEK|NORK:NIK
ADL	ADL	ERL:BALD|MDN:B4|NOR:HURA
ADL	ADL	ERL:BALD|MDN:B4|NOR:HURA|NORI:HARI
ADL	ADL	ERL:BALD|MDN:B4|NOR:HURA|NORI:NIRI
ADL	ADL	ERL:BALD|MDN:B4|NOR:HURA|NORK:GUK
ADL	ADL	ERL:BALD|MDN:B4|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:BALD|MDN:B4|NOR:HURA|NORK:HARK
ADL	ADL	ERL:BALD|MDN:B4|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:BALD|MDN:B4|NOR:HURA|NORK:NIK
ADL	ADL	ERL:BALD|MDN:B4|NOR:NI
ADL	ADL	ERL:DENB|MDN:A1|NOR:HAIEK
ADL	ADL	ERL:DENB|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	ERL:DENB|MDN:A1|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:DENB|MDN:A1|NOR:HAIEK|NORK:NIK
ADL	ADL	ERL:DENB|MDN:A1|NOR:HURA
ADL	ADL	ERL:DENB|MDN:A1|NOR:HURA|NORI:GURI
ADL	ADL	ERL:DENB|MDN:A1|NOR:HURA|NORK:GUK
ADL	ADL	ERL:DENB|MDN:A1|NOR:HURA|NORK:GUK|NORI:HARI
ADL	ADL	ERL:DENB|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:DENB|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:GURI
ADL	ADL	ERL:DENB|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL	ERL:DENB|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:DENB|MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:DENB|MDN:A1|NOR:HURA|NORK:NIK
ADL	ADL	ERL:DENB|MDN:A1|NOR:HURA|NORK:ZUEK-K
ADL	ADL	ERL:DENB|MDN:A1|NOR:NI
ADL	ADL	ERL:DENB|MDN:A1|NOR:NI|NORK:HARK
ADL	ADL	ERL:DENB|MDN:A5|NOR:HURA|NORK:NIK
ADL	ADL	ERL:DENB|MDN:B1|NOR:GU
ADL	ADL	ERL:DENB|MDN:B1|NOR:HAIEK
ADL	ADL	ERL:DENB|MDN:B1|NOR:HAIEK|NORI:HAIEI
ADL	ADL	ERL:DENB|MDN:B1|NOR:HAIEK|NORK:GUK
ADL	ADL	ERL:DENB|MDN:B1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	ERL:DENB|MDN:B1|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:DENB|MDN:B1|NOR:HAIEK|NORK:HARK|NORI:HAIEI
ADL	ADL	ERL:DENB|MDN:B1|NOR:HURA
ADL	ADL	ERL:DENB|MDN:B1|NOR:HURA|NORI:HARI
ADL	ADL	ERL:DENB|MDN:B1|NOR:HURA|NORK:GUK
ADL	ADL	ERL:DENB|MDN:B1|NOR:HURA|NORK:GUK|NORI:HARI
ADL	ADL	ERL:DENB|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:DENB|MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	ERL:DENB|MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:NIRI
ADL	ADL	ERL:DENB|MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:DENB|MDN:B1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:DENB|MDN:B1|NOR:HURA|NORK:NIK
ADL	ADL	ERL:DENB|MDN:B1|NOR:NI
ADL	ADL	ERL:DENB|MDN:B1|NOR:ZUEK|NORK:HARK
ADL	ADL	ERL:DENB|MDN:B5B|NOR:HURA|NORK:HARK
ADL	ADL	ERL:ERLT|MDN:A1|NOR:GU|NORK:HAIEK-K
ADL	ADL	ERL:ERLT|MDN:A1|NOR:GU|NORK:HARK
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HAIEK
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HAIEK|NORI:HAIEI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HAIEK|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HAIEK|NORI:ZURI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HAIEK|NORK:GUK
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HAIEK|NORK:HARK|NORI:HAIEI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HAIEK|NORK:HARK|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HAIEK|NORK:NIK
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HAIEK|NORK:ZUEK-K
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HAIEK|NORK:ZUK
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORI:GURI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORI:HAIEI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORI:NIRI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORK:GUK
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORK:GUK|NORI:HAIEI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORK:GUK|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:GURI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORK:HARK|NORI:GURI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORK:HARK|NORI:HAIEI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORK:HARK|NORI:NIRI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORK:NIK
ADL	ADL	ERL:ERLT|MDN:A1|NOR:HURA|NORK:ZUK
ADL	ADL	ERL:ERLT|MDN:A1|NOR:NI
ADL	ADL	ERL:ERLT|MDN:A1|NOR:NI|NORK:HARK
ADL	ADL	ERL:ERLT|MDN:A3|NOR:HURA|NORK:HARK
ADL	ADL	ERL:ERLT|MDN:A5|NOR:HAIEK
ADL	ADL	ERL:ERLT|MDN:A5|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	ERL:ERLT|MDN:A5|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:ERLT|MDN:A5|NOR:HAIEK|NORK:HARK|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:A5|NOR:HURA
ADL	ADL	ERL:ERLT|MDN:A5|NOR:HURA|NORK:GUK
ADL	ADL	ERL:ERLT|MDN:A5|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:ERLT|MDN:A5|NOR:HURA|NORK:HARK
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HAIEK
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HAIEK|NORI:GURI
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HAIEK|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HAIEK|NORK:GUK|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HAIEK|NORK:HAIEK-K|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HAIEK|NORK:HARK|NORI:GURI
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HAIEK|NORK:HARK|NORI:HAIEI
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HURA
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HURA|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HURA|NORI:NIRI
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HURA|NORK:GUK
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HURA|NORK:GUK|NORI:ZUEI
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:GURI
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HURA|NORK:HARK|NORI:GURI
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HURA|NORK:NIK
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HURA|NORK:NIK|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HURA|NORK:ZUEK-K|NORI:NIRI
ADL	ADL	ERL:ERLT|MDN:B1|NOR:HURA|NORK:ZUK
ADL	ADL	ERL:ERLT|MDN:B1|NOR:NI|NORK:HARK
ADL	ADL	ERL:ERLT|MDN:B1|NOR:ZUEK|NORK:HARK
ADL	ADL	ERL:ERLT|MDN:B2|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:ERLT|MDN:B2|NOR:HURA|NORK:GUK
ADL	ADL	ERL:ERLT|MDN:B2|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:ERLT|MDN:B2|NOR:HURA|NORK:HARK
ADL	ADL	ERL:ERLT|MDN:B2|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:B3|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:ERLT|MDN:B7|NOR:HAIEK
ADL	ADL	ERL:ERLT|MDN:B7|NOR:HURA
ADL	ADL	ERL:ERLT|MDN:B7|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:ERLT|MDN:B7|NOR:HURA|NORK:HARK
ADL	ADL	ERL:ERLT|MDN:B7|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:ERLT|MDN:B8|NOR:HURA
ADL	ADL	ERL:HELB|MDN:A3|NOR:HAIEK
ADL	ADL	ERL:HELB|MDN:A3|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	ERL:HELB|MDN:A3|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:HELB|MDN:A3|NOR:HURA
ADL	ADL	ERL:HELB|MDN:A3|NOR:HURA|NORK:GUK
ADL	ADL	ERL:HELB|MDN:A3|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:HELB|MDN:A3|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	ERL:HELB|MDN:A3|NOR:HURA|NORK:HARK
ADL	ADL	ERL:HELB|MDN:A3|NOR:HURA|NORK:NIK|NORI:HAIEI
ADL	ADL	ERL:HELB|MDN:A3|NOR:ZU
ADL	ADL	ERL:HELB|MDN:B5A|NOR:HURA|NORK:HARK
ADL	ADL	ERL:HELB|MDN:B5B|NOR:HAIEK
ADL	ADL	ERL:HELB|MDN:B5B|NOR:HURA
ADL	ADL	ERL:HELB|MDN:B5B|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:HELB|MDN:B5B|NOR:HURA|NORK:HARK
ADL	ADL	ERL:HELB|MDN:B5B|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:KAUS|MDN:A1|NOR:GU|NORK:HAIEK-K
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HAIEK
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HAIEK|NORI:GURI
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HAIEK|NORI:HARI
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HAIEK|NORK:GUK
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HAIEK|NORK:HARK|NORI:HARI
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HAIEK|NORK:NIK
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HAIEK|NORK:ZUK
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HI
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA|NORI:HAIEI
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA|NORI:HARI
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA|NORI:NIRI
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA|NORK:GUK
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA|NORK:GUK|NORI:HARI
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA|NORK:HARK|NORI:GURI
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA|NORK:HARK|NORI:HAIEI
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA|NORK:NIK
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA|NORK:ZUEK-K
ADL	ADL	ERL:KAUS|MDN:A1|NOR:HURA|NORK:ZUK
ADL	ADL	ERL:KAUS|MDN:A1|NOR:ZU
ADL	ADL	ERL:KAUS|MDN:A5|NOR:HAIEK
ADL	ADL	ERL:KAUS|MDN:A5|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	ERL:KAUS|MDN:A5|NOR:HAIEK|NORK:NIK
ADL	ADL	ERL:KAUS|MDN:A5|NOR:HURA
ADL	ADL	ERL:KAUS|MDN:A5|NOR:HURA|NORK:GUK
ADL	ADL	ERL:KAUS|MDN:A5|NOR:HURA|NORK:HARK
ADL	ADL	ERL:KAUS|MDN:A5|NOR:HURA|NORK:ZUEK-K
ADL	ADL	ERL:KAUS|MDN:A5|NOR:HURA|NORK:ZUK
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HAIEK
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HAIEK|NORI:HARI
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HAIEK|NORK:GUK
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HAIEK|NORK:NIK|NORI:HARI
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HURA
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HURA|NORI:HARI
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HURA|NORK:GUK
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:NIRI
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HURA|NORK:HARK|NORI:GURI
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HURA|NORK:HARK|NORI:HAIEI
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:KAUS|MDN:B1|NOR:HURA|NORK:ZUEK-K|NORI:GURI
ADL	ADL	ERL:KAUS|MDN:B1|NOR:NI
ADL	ADL	ERL:KAUS|MDN:B2|NOR:HURA
ADL	ADL	ERL:KAUS|MDN:B2|NOR:HURA|NORK:HARK
ADL	ADL	ERL:KAUS|MDN:B3|NOR:HAIEK|NORK:GUK
ADL	ADL	ERL:KAUS|MDN:B7|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:KAUS|MDN:B8|NOR:HURA
ADL	ADL	ERL:KAUS|MDN:B8|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:KONPL|MDN:A1|NOR:GU
ADL	ADL	ERL:KONPL|MDN:A1|NOR:GU|NORK:HARK
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HAIEK
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HAIEK|NORI:HAIEI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HAIEK|NORI:HARI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:GUK
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:HAIEK-K|NORI:HARI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:HARK|NORI:GURI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:HARK|NORI:HARI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:NIK
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:ZUEK-K
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:ZUK
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HI|NORK:NIK
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORI:GURI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORI:HAIEI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORI:HARI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORK:GUK
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:GURI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORK:HARK|NORI:HAIEI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORK:HARK|NORI:NIRI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORK:HIK-NO
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORK:NIK
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORK:ZUEK-K
ADL	ADL	ERL:KONPL|MDN:A1|NOR:HURA|NORK:ZUK
ADL	ADL	ERL:KONPL|MDN:A1|NOR:NI
ADL	ADL	ERL:KONPL|MDN:A1|NOR:NI|NORK:HAIEK-K
ADL	ADL	ERL:KONPL|MDN:A1|NOR:ZU
ADL	ADL	ERL:KONPL|MDN:A3|NOR:GU
ADL	ADL	ERL:KONPL|MDN:A3|NOR:HAIEK
ADL	ADL	ERL:KONPL|MDN:A3|NOR:HAIEK|NORK:GUK
ADL	ADL	ERL:KONPL|MDN:A3|NOR:HURA
ADL	ADL	ERL:KONPL|MDN:A3|NOR:HURA|NORK:GUK
ADL	ADL	ERL:KONPL|MDN:A3|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:KONPL|MDN:A3|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	ERL:KONPL|MDN:A3|NOR:HURA|NORK:HARK
ADL	ADL	ERL:KONPL|MDN:A3|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:KONPL|MDN:A3|NOR:HURA|NORK:NIK
ADL	ADL	ERL:KONPL|MDN:A3|NOR:NI|NORK:HAIEK-K
ADL	ADL	ERL:KONPL|MDN:A3|NOR:NI|NORK:ZUK
ADL	ADL	ERL:KONPL|MDN:A5|NOR:GU
ADL	ADL	ERL:KONPL|MDN:A5|NOR:HAIEK
ADL	ADL	ERL:KONPL|MDN:A5|NOR:HAIEK|NORK:GUK
ADL	ADL	ERL:KONPL|MDN:A5|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	ERL:KONPL|MDN:A5|NOR:HURA
ADL	ADL	ERL:KONPL|MDN:A5|NOR:HURA|NORI:HAIEI
ADL	ADL	ERL:KONPL|MDN:A5|NOR:HURA|NORK:GUK
ADL	ADL	ERL:KONPL|MDN:A5|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:KONPL|MDN:A5|NOR:HURA|NORK:HARK
ADL	ADL	ERL:KONPL|MDN:A5|NOR:HURA|NORK:NIK
ADL	ADL	ERL:KONPL|MDN:B1|NOR:GU|NORK:HAIEK-K
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HAIEK
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HAIEK|NORK:HARK|NORI:HAIEI
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HAIEK|NORK:HARK|NORI:HARI
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HAIEK|NORK:NIK
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HURA
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HURA|NORI:GURI
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HURA|NORI:HARI
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HURA|NORI:NIRI
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HURA|NORK:GUK
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HURA|NORK:HARK|NORI:HAIEI
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HURA|NORK:NIK
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HURA|NORK:ZUEK-K
ADL	ADL	ERL:KONPL|MDN:B1|NOR:HURA|NORK:ZUK
ADL	ADL	ERL:KONPL|MDN:B1|NOR:NI
ADL	ADL	ERL:KONPL|MDN:B1|NOR:ZUEK|NORK:HARK
ADL	ADL	ERL:KONPL|MDN:B2|NOR:HAIEK
ADL	ADL	ERL:KONPL|MDN:B2|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:KONPL|MDN:B2|NOR:HURA
ADL	ADL	ERL:KONPL|MDN:B2|NOR:HURA|NORK:GUK
ADL	ADL	ERL:KONPL|MDN:B2|NOR:HURA|NORK:HARK
ADL	ADL	ERL:KONPL|MDN:B2|NOR:HURA|NORK:HARK|NORI:HAIEI
ADL	ADL	ERL:KONPL|MDN:B2|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:KONPL|MDN:B2|NOR:HURA|NORK:NIK
ADL	ADL	ERL:KONPL|MDN:B2|NOR:NI
ADL	ADL	ERL:KONPL|MDN:B3|NOR:HURA
ADL	ADL	ERL:KONPL|MDN:B5B|NOR:HURA
ADL	ADL	ERL:KONPL|MDN:B5B|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:KONPL|MDN:B5B|NOR:HURA|NORK:HARK
ADL	ADL	ERL:KONPL|MDN:B7|NOR:HURA
ADL	ADL	ERL:KONPL|MDN:B7|NOR:HURA|NORK:HIK
ADL	ADL	ERL:KONPL|MDN:B8|NOR:GU
ADL	ADL	ERL:KONPL|MDN:B8|NOR:HAIEK
ADL	ADL	ERL:KONPL|MDN:B8|NOR:HURA
ADL	ADL	ERL:KONPL|MDN:B8|NOR:HURA|NORK:HARK
ADL	ADL	ERL:KONPL|MDN:B8|NOR:NI
ADL	ADL	ERL:MOD/DENB|MDN:A1|NOR:HAIEK
ADL	ADL	ERL:MOD/DENB|MDN:A1|NOR:HAIEK|NORK:GUK
ADL	ADL	ERL:MOD/DENB|MDN:A1|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:MOD/DENB|MDN:A1|NOR:HURA
ADL	ADL	ERL:MOD/DENB|MDN:A1|NOR:HURA|NORI:HARI
ADL	ADL	ERL:MOD/DENB|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:MOD/DENB|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:MOD/DENB|MDN:A1|NOR:HURA|NORK:NIK
ADL	ADL	ERL:MOD/DENB|MDN:A5|NOR:HAIEK
ADL	ADL	ERL:MOD/DENB|MDN:B1|NOR:HAIEK
ADL	ADL	ERL:MOD/DENB|MDN:B1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	ERL:MOD/DENB|MDN:B1|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:MOD/DENB|MDN:B1|NOR:HAIEK|NORK:HARK|NORI:HARI
ADL	ADL	ERL:MOD/DENB|MDN:B1|NOR:HURA
ADL	ADL	ERL:MOD/DENB|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:MOD/DENB|MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:MOD/DENB|MDN:B1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:MOD|MDN:A1|NOR:HAIEK
ADL	ADL	ERL:MOD|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:MOD|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:MOD|MDN:B1|NOR:HAIEK
ADL	ADL	ERL:MOD|MDN:B1|NOR:HURA
ADL	ADL	ERL:MOD|MDN:B8|NOR:HAIEK
ADL	ADL	ERL:MOS|MDN:A1|NOR:GU
ADL	ADL	ERL:MOS|MDN:A1|NOR:HAIEK
ADL	ADL	ERL:MOS|MDN:A1|NOR:HAIEK|NORI:NIRI
ADL	ADL	ERL:MOS|MDN:A1|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:MOS|MDN:A1|NOR:HAIEK|NORK:HARK|NORI:HARI
ADL	ADL	ERL:MOS|MDN:A1|NOR:HURA
ADL	ADL	ERL:MOS|MDN:A1|NOR:HURA|NORK:GUK
ADL	ADL	ERL:MOS|MDN:A1|NOR:HURA|NORK:GUK|NORI:HARI
ADL	ADL	ERL:MOS|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:MOS|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	ERL:MOS|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:MOS|MDN:A1|NOR:HURA|NORK:HARK|NORI:GURI
ADL	ADL	ERL:MOS|MDN:A1|NOR:HURA|NORK:NIK
ADL	ADL	ERL:MOS|MDN:A5|NOR:HAIEK
ADL	ADL	ERL:MOS|MDN:A5|NOR:HURA
ADL	ADL	ERL:MOS|MDN:A5|NOR:HURA|NORK:GUK
ADL	ADL	ERL:MOS|MDN:A5|NOR:HURA|NORK:ZUEK-K
ADL	ADL	ERL:MOS|MDN:B1|NOR:HAIEK
ADL	ADL	ERL:MOS|MDN:B1|NOR:HURA
ADL	ADL	ERL:MOS|MDN:B1|NOR:HURA|NORI:HAIEI
ADL	ADL	ERL:MOS|MDN:B1|NOR:HURA|NORI:NIRI
ADL	ADL	ERL:MOS|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:MOS|MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	ERL:MOS|MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:MOS|MDN:B1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:MOS|MDN:B1|NOR:HURA|NORK:NIK
ADL	ADL	ERL:MOS|MDN:B1|NOR:ZU
ADL	ADL	ERL:MOS|MDN:B2|NOR:HAIEK
ADL	ADL	ERL:MOS|MDN:B2|NOR:HURA|NORK:HARK
ADL	ADL	ERL:MOS|MDN:B4|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:ZHG|MDN:A1|NOR:GU
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HAIEK
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HAIEK|NORI:HARI
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HAIEK|NORK:GUK
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HURA
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HURA|NORI:GURI
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HURA|NORI:HARI
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HURA|NORK:GUK
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HURA|NORK:HIK-TO
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HURA|NORK:NIK
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HURA|NORK:ZUEK-K
ADL	ADL	ERL:ZHG|MDN:A1|NOR:HURA|NORK:ZUK
ADL	ADL	ERL:ZHG|MDN:A1|NOR:NI
ADL	ADL	ERL:ZHG|MDN:A1|NOR:NI|NORK:HARK
ADL	ADL	ERL:ZHG|MDN:A1|NOR:NI|NORK:ZUK
ADL	ADL	ERL:ZHG|MDN:A1|NOR:ZU
ADL	ADL	ERL:ZHG|MDN:A5|NOR:HAIEK
ADL	ADL	ERL:ZHG|MDN:A5|NOR:HURA
ADL	ADL	ERL:ZHG|MDN:A5|NOR:HURA|NORK:HARK
ADL	ADL	ERL:ZHG|MDN:A5|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:ZHG|MDN:A5|NOR:HURA|NORK:NIK
ADL	ADL	ERL:ZHG|MDN:B1|NOR:HAIEK
ADL	ADL	ERL:ZHG|MDN:B1|NOR:HAIEK|NORK:HARK
ADL	ADL	ERL:ZHG|MDN:B1|NOR:HAIEK|NORK:NIK
ADL	ADL	ERL:ZHG|MDN:B1|NOR:HURA
ADL	ADL	ERL:ZHG|MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:NIRI
ADL	ADL	ERL:ZHG|MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL	ERL:ZHG|MDN:B1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	ERL:ZHG|MDN:B1|NOR:HURA|NORK:NIK
ADL	ADL	ERL:ZHG|MDN:B1|NOR:NI
ADL	ADL	ERL:ZHG|MDN:B1|NOR:ZU|NORK:NIK
ADL	ADL	KAS:ABL|NUM:P|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:ABS|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HAIEK
ADL	ADL	KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HAIEK|NORK:HARK
ADL	ADL	KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:ABS|NUM:P|MUG:M|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:ABS|NUM:P|NOR:GU|NORK:HAIEK-K
ADL	ADL	KAS:ABS|NUM:P|NOR:HAIEK
ADL	ADL	KAS:ABS|NUM:P|NOR:HAIEK|NORI:HAIEI
ADL	ADL	KAS:ABS|NUM:P|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	KAS:ABS|NUM:P|NOR:HAIEK|NORK:HAIEK-K|NORI:GURI
ADL	ADL	KAS:ABS|NUM:P|NOR:HAIEK|NORK:HARK
ADL	ADL	KAS:ABS|NUM:P|NOR:HAIEK|NORK:HARK|NORI:GURI
ADL	ADL	KAS:ABS|NUM:P|NOR:HURA|NORK:GUK
ADL	ADL	KAS:ABS|NUM:P|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:ABS|NUM:P|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	KAS:ABS|NUM:P|NOR:HURA|NORK:HAIEK-K|NORI:NIRI
ADL	ADL	KAS:ABS|NUM:P|NOR:HURA|NORK:HARK|NORI:HAIEI
ADL	ADL	KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:ABS|NUM:S|MUG:M|MDN:B2|NOR:HAIEK|NORK:HARK
ADL	ADL	KAS:ABS|NUM:S|NOR:GU
ADL	ADL	KAS:ABS|NUM:S|NOR:GU|NORK:HARK
ADL	ADL	KAS:ABS|NUM:S|NOR:HAIEK|NORK:HARK
ADL	ADL	KAS:ABS|NUM:S|NOR:HAIEK|NORK:HARK|NORI:HAIEI
ADL	ADL	KAS:ABS|NUM:S|NOR:HAIEK|NORK:HARK|NORI:HARI
ADL	ADL	KAS:ABS|NUM:S|NOR:HURA
ADL	ADL	KAS:ABS|NUM:S|NOR:HURA|NORI:HARI
ADL	ADL	KAS:ABS|NUM:S|NOR:HURA|NORK:GUK
ADL	ADL	KAS:ABS|NUM:S|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:ABS|NUM:S|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	KAS:ABS|NUM:S|NOR:HURA|NORK:HAIEK-K|NORI:NIRI
ADL	ADL	KAS:ABS|NUM:S|NOR:HURA|NORK:HARK
ADL	ADL	KAS:ABS|NUM:S|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	KAS:ABS|NUM:S|NOR:HURA|NORK:HARK|NORI:NIRI
ADL	ADL	KAS:ABS|NUM:S|NOR:HURA|NORK:NIK
ADL	ADL	KAS:ABS|NUM:S|NOR:NI
ADL	ADL	KAS:ABS|NUM:S|NOR:NI|NORK:HARK
ADL	ADL	KAS:DAT|NUM:P|NOR:HAIEK|NORK:HARK
ADL	ADL	KAS:DAT|NUM:S|MUG:M|MDN:A1|NOR:HURA
ADL	ADL	KAS:DAT|NUM:S|NOR:HURA
ADL	ADL	KAS:DAT|NUM:S|NOR:HURA|NORK:GUK
ADL	ADL	KAS:DAT|NUM:S|NOR:HURA|NORK:HARK
ADL	ADL	KAS:DES|NUM:S|NOR:HURA|NORK:HARK
ADL	ADL	KAS:DES|NUM:S|NOR:NI|NORK:HARK
ADL	ADL	KAS:ERG|NUM:P|NOR:HAIEK
ADL	ADL	KAS:ERG|NUM:P|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	KAS:ERG|NUM:P|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:ERG|NUM:P|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	KAS:ERG|NUM:S|MUG:M|MDN:B1|NOR:HURA
ADL	ADL	KAS:ERG|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL	KAS:ERG|NUM:S|NOR:HURA
ADL	ADL	KAS:ERG|NUM:S|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	KAS:ERG|NUM:S|NOR:HURA|NORK:HARK
ADL	ADL	KAS:ERG|NUM:S|NOR:HURA|NORK:NIK
ADL	ADL	KAS:GEL|MDN:A1|NOR:HURA
ADL	ADL	KAS:GEL|MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL	KAS:GEL|NOR:HURA
ADL	ADL	KAS:GEL|NOR:HURA|NORK:HARK
ADL	ADL	KAS:GEL|NUM:S|MUG:M|MDN:A1|NOR:HAIEK
ADL	ADL	KAS:GEL|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:GEL|NUM:S|NOR:HAIEK
ADL	ADL	KAS:GEL|NUM:S|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:GEN|NUM:P|NOR:HAIEK
ADL	ADL	KAS:GEN|NUM:P|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	KAS:GEN|NUM:P|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:GEN|NUM:S|MUG:M|MDN:A1|NOR:HURA
ADL	ADL	KAS:GEN|NUM:S|MUG:M|MDN:A5|NOR:HURA
ADL	ADL	KAS:GEN|NUM:S|MUG:M|MDN:B7|NOR:HURA
ADL	ADL	KAS:GEN|NUM:S|NOR:HAIEK
ADL	ADL	KAS:GEN|NUM:S|NOR:HURA
ADL	ADL	KAS:GEN|NUM:S|NOR:HURA|NORI:GURI
ADL	ADL	KAS:GEN|NUM:S|NOR:HURA|NORI:NIRI
ADL	ADL	KAS:GEN|NUM:S|NOR:HURA|NORK:GUK
ADL	ADL	KAS:GEN|NUM:S|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:GEN|NUM:S|NOR:HURA|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL	KAS:GEN|NUM:S|NOR:HURA|NORK:HARK
ADL	ADL	KAS:INE|NUM:P|NOR:HAIEK
ADL	ADL	KAS:INE|NUM:P|NOR:NI
ADL	ADL	KAS:INE|NUM:S|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:INE|NUM:S|NOR:HURA|NORK:HARK
ADL	ADL	KAS:INS|NUM:S|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:MOT|NUM:S|NOR:GU|NORK:HARK
ADL	ADL	KAS:MOT|NUM:S|NOR:HURA
ADL	ADL	KAS:MOT|NUM:S|NOR:HURA|NORI:HARI
ADL	ADL	KAS:MOT|NUM:S|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:PAR|MUG:MG|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL	KAS:PAR|NOR:HURA|NORK:HARK
ADL	ADL	KAS:SOZ|NUM:P|NOR:HAIEK
ADL	ADL	KAS:SOZ|NUM:P|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	KAS:SOZ|NUM:P|NOR:HAIEK|NORK:HAIEK-K|NORI:HARI
ADL	ADL	KAS:SOZ|NUM:P|NOR:HURA|NORK:HAIEK-K
ADL	ADL	KAS:SOZ|NUM:S|NOR:HURA
ADL	ADL	KAS:SOZ|NUM:S|NOR:HURA|NORK:HARK
ADL	ADL	KAS:SOZ|NUM:S|NOR:HURA|NORK:NIK
ADL	ADL	KAS:SOZ|NUM:S|NOR:HURA|NORK:ZUK
ADL	ADL	KAS:SOZ|NUM:S|NOR:NI|NORK:HARK
ADL	ADL	MDN:A1|NOR:GU
ADL	ADL	MDN:A1|NOR:GU|NORK:HAIEK-K
ADL	ADL	MDN:A1|NOR:GU|NORK:HARK
ADL	ADL	MDN:A1|NOR:HAIEK
ADL	ADL	MDN:A1|NOR:HAIEK|HIT:NO
ADL	ADL	MDN:A1|NOR:HAIEK|NORI:GURI
ADL	ADL	MDN:A1|NOR:HAIEK|NORI:HAIEI
ADL	ADL	MDN:A1|NOR:HAIEK|NORI:HARI
ADL	ADL	MDN:A1|NOR:HAIEK|NORI:NIRI
ADL	ADL	MDN:A1|NOR:HAIEK|NORI:ZUEI
ADL	ADL	MDN:A1|NOR:HAIEK|NORI:ZURI
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:GUK
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:GUK|NORI:ZURI
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:HAIEK-K|NORI:GURI
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:HAIEK-K|NORI:NIRI
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:HARK
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:HARK|HIT:NO
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:HARK|NORI:GURI
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:HARK|NORI:HAIEI
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:HARK|NORI:HARI
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:HARK|NORI:NIRI
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:HARK|NORI:ZURI
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:NIK
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:NIK|NORI:HAIEI
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:NIK|NORI:HARI
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:NIK|NORI:ZUEI
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:ZUEK-K
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:ZUK
ADL	ADL	MDN:A1|NOR:HAIEK|NORK:ZUK|NORI:NIRI
ADL	ADL	MDN:A1|NOR:HI
ADL	ADL	MDN:A1|NOR:HURA
ADL	ADL	MDN:A1|NOR:HURA|HIT:NO
ADL	ADL	MDN:A1|NOR:HURA|HIT:TO
ADL	ADL	MDN:A1|NOR:HURA|NORI:GURI
ADL	ADL	MDN:A1|NOR:HURA|NORI:HAIEI
ADL	ADL	MDN:A1|NOR:HURA|NORI:HARI
ADL	ADL	MDN:A1|NOR:HURA|NORI:HIRI-TO
ADL	ADL	MDN:A1|NOR:HURA|NORI:NIRI
ADL	ADL	MDN:A1|NOR:HURA|NORI:NIRI|HIT:NO
ADL	ADL	MDN:A1|NOR:HURA|NORI:ZUEI
ADL	ADL	MDN:A1|NOR:HURA|NORI:ZURI
ADL	ADL	MDN:A1|NOR:HURA|NORK:GUK
ADL	ADL	MDN:A1|NOR:HURA|NORK:GUK|HIT:TO
ADL	ADL	MDN:A1|NOR:HURA|NORK:GUK|NORI:HAIEI
ADL	ADL	MDN:A1|NOR:HURA|NORK:GUK|NORI:HARI
ADL	ADL	MDN:A1|NOR:HURA|NORK:GUK|NORI:ZURI
ADL	ADL	MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	MDN:A1|NOR:HURA|NORK:HAIEK-K|HIT:TO
ADL	ADL	MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:GURI
ADL	ADL	MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL	MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:NIRI
ADL	ADL	MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:NIRI|HIT:NO
ADL	ADL	MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:ZURI
ADL	ADL	MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL	MDN:A1|NOR:HURA|NORK:HARK|HIT:NO
ADL	ADL	MDN:A1|NOR:HURA|NORK:HARK|HIT:TO
ADL	ADL	MDN:A1|NOR:HURA|NORK:HARK|NORI:GURI
ADL	ADL	MDN:A1|NOR:HURA|NORK:HARK|NORI:HAIEI
ADL	ADL	MDN:A1|NOR:HURA|NORK:HARK|NORI:HAIEI|HIT:NO
ADL	ADL	MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI|HIT:NO
ADL	ADL	MDN:A1|NOR:HURA|NORK:HARK|NORI:HIRI-NO
ADL	ADL	MDN:A1|NOR:HURA|NORK:HARK|NORI:NIRI
ADL	ADL	MDN:A1|NOR:HURA|NORK:HARK|NORI:ZURI
ADL	ADL	MDN:A1|NOR:HURA|NORK:HIK-NO
ADL	ADL	MDN:A1|NOR:HURA|NORK:HIK-TO
ADL	ADL	MDN:A1|NOR:HURA|NORK:NIK
ADL	ADL	MDN:A1|NOR:HURA|NORK:NIK|HIT:NO
ADL	ADL	MDN:A1|NOR:HURA|NORK:NIK|HIT:TO
ADL	ADL	MDN:A1|NOR:HURA|NORK:NIK|NORI:HAIEI
ADL	ADL	MDN:A1|NOR:HURA|NORK:NIK|NORI:HARI
ADL	ADL	MDN:A1|NOR:HURA|NORK:NIK|NORI:HIRI-TO
ADL	ADL	MDN:A1|NOR:HURA|NORK:NIK|NORI:ZUEI
ADL	ADL	MDN:A1|NOR:HURA|NORK:NIK|NORI:ZURI
ADL	ADL	MDN:A1|NOR:HURA|NORK:ZUEK-K
ADL	ADL	MDN:A1|NOR:HURA|NORK:ZUEK-K|NORI:NIRI
ADL	ADL	MDN:A1|NOR:HURA|NORK:ZUK
ADL	ADL	MDN:A1|NOR:HURA|NORK:ZUK|NORI:GURI
ADL	ADL	MDN:A1|NOR:HURA|NORK:ZUK|NORI:HARI
ADL	ADL	MDN:A1|NOR:NI
ADL	ADL	MDN:A1|NOR:NI|HIT:NO
ADL	ADL	MDN:A1|NOR:NI|NORK:HAIEK-K
ADL	ADL	MDN:A1|NOR:NI|NORK:HARK
ADL	ADL	MDN:A1|NOR:NI|NORK:ZUEK-K
ADL	ADL	MDN:A1|NOR:NI|NORK:ZUK
ADL	ADL	MDN:A1|NOR:ZU
ADL	ADL	MDN:A1|NOR:ZUEK
ADL	ADL	MDN:A1|NOR:ZUEK|NORK:GUK
ADL	ADL	MDN:A1|NOR:ZU|NORI:NIRI
ADL	ADL	MDN:A1|NOR:ZU|NORK:GUK
ADL	ADL	MDN:A1|NOR:ZU|NORK:HAIEK-K
ADL	ADL	MDN:A1|NOR:ZU|NORK:HARK
ADL	ADL	MDN:A1|NOR:ZU|NORK:NIK
ADL	ADL	MDN:A5|NOR:GU
ADL	ADL	MDN:A5|NOR:HAIEK
ADL	ADL	MDN:A5|NOR:HAIEK|NORK:GUK
ADL	ADL	MDN:A5|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	MDN:A5|NOR:HAIEK|NORK:HARK
ADL	ADL	MDN:A5|NOR:HAIEK|NORK:HARK|NORI:HARI
ADL	ADL	MDN:A5|NOR:HAIEK|NORK:ZUK
ADL	ADL	MDN:A5|NOR:HI
ADL	ADL	MDN:A5|NOR:HURA
ADL	ADL	MDN:A5|NOR:HURA|NORI:HARI
ADL	ADL	MDN:A5|NOR:HURA|NORI:HARI|HIT:NO
ADL	ADL	MDN:A5|NOR:HURA|NORI:ZURI
ADL	ADL	MDN:A5|NOR:HURA|NORK:GUK
ADL	ADL	MDN:A5|NOR:HURA|NORK:HAIEK-K
ADL	ADL	MDN:A5|NOR:HURA|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL	MDN:A5|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	MDN:A5|NOR:HURA|NORK:HARK
ADL	ADL	MDN:A5|NOR:HURA|NORK:HARK|HIT:NO
ADL	ADL	MDN:A5|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	MDN:A5|NOR:HURA|NORK:NIK
ADL	ADL	MDN:A5|NOR:HURA|NORK:ZUK
ADL	ADL	MDN:A5|NOR:NI
ADL	ADL	MDN:A5|NOR:NI|NORK:ZUK
ADL	ADL	MDN:A5|NOR:ZU|NORK:GUK
ADL	ADL	MDN:B1|NOR:GU
ADL	ADL	MDN:B1|NOR:GU|HIT:NO
ADL	ADL	MDN:B1|NOR:GU|NORI:HARI
ADL	ADL	MDN:B1|NOR:GU|NORK:HAIEK-K
ADL	ADL	MDN:B1|NOR:GU|NORK:HARK
ADL	ADL	MDN:B1|NOR:HAIEK
ADL	ADL	MDN:B1|NOR:HAIEK|NORI:GURI
ADL	ADL	MDN:B1|NOR:HAIEK|NORI:HAIEI
ADL	ADL	MDN:B1|NOR:HAIEK|NORI:HARI
ADL	ADL	MDN:B1|NOR:HAIEK|NORI:NIRI
ADL	ADL	MDN:B1|NOR:HAIEK|NORK:GUK
ADL	ADL	MDN:B1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	MDN:B1|NOR:HAIEK|NORK:HAIEK-K|NORI:GURI
ADL	ADL	MDN:B1|NOR:HAIEK|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL	MDN:B1|NOR:HAIEK|NORK:HAIEK-K|NORI:HARI
ADL	ADL	MDN:B1|NOR:HAIEK|NORK:HAIEK-K|NORI:NIRI
ADL	ADL	MDN:B1|NOR:HAIEK|NORK:HARK
ADL	ADL	MDN:B1|NOR:HAIEK|NORK:HARK|NORI:GURI
ADL	ADL	MDN:B1|NOR:HAIEK|NORK:HARK|NORI:HAIEI
ADL	ADL	MDN:B1|NOR:HAIEK|NORK:HARK|NORI:HARI
ADL	ADL	MDN:B1|NOR:HAIEK|NORK:HARK|NORI:NIRI
ADL	ADL	MDN:B1|NOR:HAIEK|NORK:NIK
ADL	ADL	MDN:B1|NOR:HAIEK|NORK:ZUK
ADL	ADL	MDN:B1|NOR:HI
ADL	ADL	MDN:B1|NOR:HI|NORK:HARK
ADL	ADL	MDN:B1|NOR:HURA
ADL	ADL	MDN:B1|NOR:HURA|NORI:GURI
ADL	ADL	MDN:B1|NOR:HURA|NORI:HAIEI
ADL	ADL	MDN:B1|NOR:HURA|NORI:HARI
ADL	ADL	MDN:B1|NOR:HURA|NORI:NIRI
ADL	ADL	MDN:B1|NOR:HURA|NORI:ZUEI
ADL	ADL	MDN:B1|NOR:HURA|NORI:ZURI
ADL	ADL	MDN:B1|NOR:HURA|NORK:GUK
ADL	ADL	MDN:B1|NOR:HURA|NORK:GUK|HIT:TO
ADL	ADL	MDN:B1|NOR:HURA|NORK:GUK|NORI:HAIEI
ADL	ADL	MDN:B1|NOR:HURA|NORK:GUK|NORI:HARI
ADL	ADL	MDN:B1|NOR:HURA|NORK:GUK|NORI:ZUEI
ADL	ADL	MDN:B1|NOR:HURA|NORK:GUK|NORI:ZURI
ADL	ADL	MDN:B1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:GURI
ADL	ADL	MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL	MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:NIRI
ADL	ADL	MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL	MDN:B1|NOR:HURA|NORK:HARK|HIT:NO
ADL	ADL	MDN:B1|NOR:HURA|NORK:HARK|NORI:GURI
ADL	ADL	MDN:B1|NOR:HURA|NORK:HARK|NORI:HAIEI
ADL	ADL	MDN:B1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	MDN:B1|NOR:HURA|NORK:HARK|NORI:NIRI
ADL	ADL	MDN:B1|NOR:HURA|NORK:HARK|NORI:ZUEI
ADL	ADL	MDN:B1|NOR:HURA|NORK:HARK|NORI:ZURI
ADL	ADL	MDN:B1|NOR:HURA|NORK:HIK
ADL	ADL	MDN:B1|NOR:HURA|NORK:NIK
ADL	ADL	MDN:B1|NOR:HURA|NORK:NIK|HIT:TO
ADL	ADL	MDN:B1|NOR:HURA|NORK:NIK|NORI:HAIEI
ADL	ADL	MDN:B1|NOR:HURA|NORK:NIK|NORI:HARI
ADL	ADL	MDN:B1|NOR:HURA|NORK:NIK|NORI:HIRI-TO
ADL	ADL	MDN:B1|NOR:HURA|NORK:ZUEK-K
ADL	ADL	MDN:B1|NOR:HURA|NORK:ZUEK-K|NORI:GURI
ADL	ADL	MDN:B1|NOR:HURA|NORK:ZUK
ADL	ADL	MDN:B1|NOR:NI
ADL	ADL	MDN:B1|NOR:NI|NORI:HARI
ADL	ADL	MDN:B1|NOR:NI|NORK:HAIEK-K
ADL	ADL	MDN:B1|NOR:NI|NORK:HARK
ADL	ADL	MDN:B1|NOR:ZU
ADL	ADL	MDN:B1|NOR:ZU|NORK:NIK
ADL	ADL	MDN:B2|NOR:HAIEK
ADL	ADL	MDN:B2|NOR:HAIEK|NORI:HAIEI
ADL	ADL	MDN:B2|NOR:HAIEK|NORK:GUK
ADL	ADL	MDN:B2|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	MDN:B2|NOR:HAIEK|NORK:NIK
ADL	ADL	MDN:B2|NOR:HURA
ADL	ADL	MDN:B2|NOR:HURA|NORI:GURI
ADL	ADL	MDN:B2|NOR:HURA|NORI:NIRI
ADL	ADL	MDN:B2|NOR:HURA|NORK:GUK
ADL	ADL	MDN:B2|NOR:HURA|NORK:HAIEK-K
ADL	ADL	MDN:B2|NOR:HURA|NORK:HARK
ADL	ADL	MDN:B2|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	MDN:B2|NOR:HURA|NORK:NIK
ADL	ADL	MDN:B2|NOR:HURA|NORK:NIK|NORI:ZURI
ADL	ADL	MDN:B2|NOR:HURA|NORK:ZUEK-K
ADL	ADL	MDN:B2|NOR:HURA|NORK:ZUK
ADL	ADL	MDN:B2|NOR:HURA|NORK:ZUK|NORI:HARI
ADL	ADL	MDN:B2|NOR:NI
ADL	ADL	MDN:B3|NOR:HURA
ADL	ADL	MDN:B3|NOR:HURA|NORI:NIRI
ADL	ADL	MDN:B3|NOR:HURA|NORK:HAIEK-K
ADL	ADL	MDN:B3|NOR:HURA|NORK:HARK
ADL	ADL	MDN:B7|NOR:HAIEK
ADL	ADL	MDN:B7|NOR:HURA
ADL	ADL	MDN:B7|NOR:HURA|NORK:GUK
ADL	ADL	MDN:B7|NOR:HURA|NORK:HAIEK-K
ADL	ADL	MDN:B7|NOR:HURA|NORK:HARK
ADL	ADL	MDN:B7|NOR:HURA|NORK:NIK
ADL	ADL	MDN:B7|NOR:HURA|NORK:ZUK
ADL	ADL	MDN:B8|NOR:HAIEK
ADL	ADL	MDN:B8|NOR:HAIEK|NORK:HARK
ADL	ADL	MDN:B8|NOR:HAIEK|NORK:ZUK
ADL	ADL	MDN:B8|NOR:HURA
ADL	ADL	MDN:B8|NOR:HURA|NORK:HAIEK-K
ADL	ADL	MDN:B8|NOR:HURA|NORK:HARK
ADL	ADL	MDN:B8|NOR:ZU|NORK:NIK
ADL	ADL	MDN:C|NOR:HAIEK|NORK:ZUK
ADL	ADL	MDN:C|NOR:HURA|NORK:HIK-NO
ADL	ADL	MDN:C|NOR:HURA|NORK:HIK-NO|NORI:HARI
ADL	ADL	MDN:C|NOR:HURA|NORK:HIK-TO
ADL	ADL	MDN:C|NOR:HURA|NORK:ZUEK-K
ADL	ADL	MDN:C|NOR:HURA|NORK:ZUK
ADL	ADL	MDN:C|NOR:HURA|NORK:ZUK|NORI:HAIEI
ADL	ADL	MDN:C|NOR:HURA|NORK:ZUK|NORI:HARI
ADL	ADL	MDN:C|NOR:HURA|NORK:ZUK|NORI:NIRI
ADL	ADL	MDN:C|NOR:NI|NORK:HIK-NO
ADL	ADL	MDN:C|NOR:NI|NORK:ZUK
ADL	ADL	MDN:C|NOR:ZU
ADL	ADL	MOD:EGI|MDN:A1|NOR:HAIEK|NORK:HARK
ADL	ADL	MOD:EGI|MDN:A1|NOR:HURA
ADL	ADL	MOD:EGI|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	MOD:EGI|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL	MOD:EGI|MDN:A5|NOR:HAIEK
ADL	ADL	MOD:EGI|MDN:B1|NOR:HAIEK|NORK:HARK
ADL	ADL	MOD:EGI|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADL	ADL	MOD:EGI|MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL	MOD:EGI|MDN:B2|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	MOD:EGI|MDN:B7|NOR:HURA
ADL	ADL	NOR:GU
ADL	ADL	NOR:GU|HIT:NO
ADL	ADL	NOR:GU|NORI:HARI
ADL	ADL	NOR:GU|NORK:HAIEK-K
ADL	ADL	NOR:GU|NORK:HARK
ADL	ADL	NOR:HAIEK
ADL	ADL	NOR:HAIEK|HIT:NO
ADL	ADL	NOR:HAIEK|NORI:GURI
ADL	ADL	NOR:HAIEK|NORI:HAIEI
ADL	ADL	NOR:HAIEK|NORI:HARI
ADL	ADL	NOR:HAIEK|NORI:NIRI
ADL	ADL	NOR:HAIEK|NORI:ZUEI
ADL	ADL	NOR:HAIEK|NORI:ZURI
ADL	ADL	NOR:HAIEK|NORK:GUK
ADL	ADL	NOR:HAIEK|NORK:GUK|NORI:HARI
ADL	ADL	NOR:HAIEK|NORK:GUK|NORI:ZURI
ADL	ADL	NOR:HAIEK|NORK:HAIEK-K
ADL	ADL	NOR:HAIEK|NORK:HAIEK-K|NORI:GURI
ADL	ADL	NOR:HAIEK|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL	NOR:HAIEK|NORK:HAIEK-K|NORI:HARI
ADL	ADL	NOR:HAIEK|NORK:HAIEK-K|NORI:NIRI
ADL	ADL	NOR:HAIEK|NORK:HARK
ADL	ADL	NOR:HAIEK|NORK:HARK|HIT:NO
ADL	ADL	NOR:HAIEK|NORK:HARK|NORI:GURI
ADL	ADL	NOR:HAIEK|NORK:HARK|NORI:HAIEI
ADL	ADL	NOR:HAIEK|NORK:HARK|NORI:HARI
ADL	ADL	NOR:HAIEK|NORK:HARK|NORI:NIRI
ADL	ADL	NOR:HAIEK|NORK:HARK|NORI:ZURI
ADL	ADL	NOR:HAIEK|NORK:NIK
ADL	ADL	NOR:HAIEK|NORK:NIK|NORI:HAIEI
ADL	ADL	NOR:HAIEK|NORK:NIK|NORI:HARI
ADL	ADL	NOR:HAIEK|NORK:NIK|NORI:ZUEI
ADL	ADL	NOR:HAIEK|NORK:ZUEK-K
ADL	ADL	NOR:HAIEK|NORK:ZUK
ADL	ADL	NOR:HAIEK|NORK:ZUK|NORI:NIRI
ADL	ADL	NOR:HI
ADL	ADL	NOR:HI|NORK:HARK
ADL	ADL	NOR:HI|NORK:NIK
ADL	ADL	NOR:HURA
ADL	ADL	NOR:HURA|HIT:NO
ADL	ADL	NOR:HURA|HIT:TO
ADL	ADL	NOR:HURA|NORI:GURI
ADL	ADL	NOR:HURA|NORI:HAIEI
ADL	ADL	NOR:HURA|NORI:HARI
ADL	ADL	NOR:HURA|NORI:HARI|HIT:NO
ADL	ADL	NOR:HURA|NORI:HIRI-TO
ADL	ADL	NOR:HURA|NORI:NIRI
ADL	ADL	NOR:HURA|NORI:NIRI|HIT:NO
ADL	ADL	NOR:HURA|NORI:ZUEI
ADL	ADL	NOR:HURA|NORI:ZURI
ADL	ADL	NOR:HURA|NORK:GUK
ADL	ADL	NOR:HURA|NORK:GUK|HIT:TO
ADL	ADL	NOR:HURA|NORK:GUK|NORI:HAIEI
ADL	ADL	NOR:HURA|NORK:GUK|NORI:HARI
ADL	ADL	NOR:HURA|NORK:GUK|NORI:ZUEI
ADL	ADL	NOR:HURA|NORK:GUK|NORI:ZURI
ADL	ADL	NOR:HURA|NORK:HAIEK-K
ADL	ADL	NOR:HURA|NORK:HAIEK-K|HIT:TO
ADL	ADL	NOR:HURA|NORK:HAIEK-K|NORI:GURI
ADL	ADL	NOR:HURA|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL	NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL	NOR:HURA|NORK:HAIEK-K|NORI:NIRI
ADL	ADL	NOR:HURA|NORK:HAIEK-K|NORI:NIRI|HIT:NO
ADL	ADL	NOR:HURA|NORK:HAIEK-K|NORI:ZURI
ADL	ADL	NOR:HURA|NORK:HARK
ADL	ADL	NOR:HURA|NORK:HARK|HIT:NO
ADL	ADL	NOR:HURA|NORK:HARK|HIT:TO
ADL	ADL	NOR:HURA|NORK:HARK|NORI:GURI
ADL	ADL	NOR:HURA|NORK:HARK|NORI:HAIEI
ADL	ADL	NOR:HURA|NORK:HARK|NORI:HAIEI|HIT:NO
ADL	ADL	NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL	NOR:HURA|NORK:HARK|NORI:HARI|HIT:NO
ADL	ADL	NOR:HURA|NORK:HARK|NORI:HIRI-NO
ADL	ADL	NOR:HURA|NORK:HARK|NORI:NIRI
ADL	ADL	NOR:HURA|NORK:HARK|NORI:ZUEI
ADL	ADL	NOR:HURA|NORK:HARK|NORI:ZURI
ADL	ADL	NOR:HURA|NORK:HIK
ADL	ADL	NOR:HURA|NORK:HIK-NO
ADL	ADL	NOR:HURA|NORK:HIK-NO|NORI:HARI
ADL	ADL	NOR:HURA|NORK:HIK-TO
ADL	ADL	NOR:HURA|NORK:NIK
ADL	ADL	NOR:HURA|NORK:NIK|HIT:NO
ADL	ADL	NOR:HURA|NORK:NIK|HIT:TO
ADL	ADL	NOR:HURA|NORK:NIK|NORI:HAIEI
ADL	ADL	NOR:HURA|NORK:NIK|NORI:HARI
ADL	ADL	NOR:HURA|NORK:NIK|NORI:HIRI-TO
ADL	ADL	NOR:HURA|NORK:NIK|NORI:ZUEI
ADL	ADL	NOR:HURA|NORK:NIK|NORI:ZURI
ADL	ADL	NOR:HURA|NORK:ZUEK-K
ADL	ADL	NOR:HURA|NORK:ZUEK-K|NORI:GURI
ADL	ADL	NOR:HURA|NORK:ZUEK-K|NORI:NIRI
ADL	ADL	NOR:HURA|NORK:ZUK
ADL	ADL	NOR:HURA|NORK:ZUK|NORI:GURI
ADL	ADL	NOR:HURA|NORK:ZUK|NORI:HAIEI
ADL	ADL	NOR:HURA|NORK:ZUK|NORI:HARI
ADL	ADL	NOR:HURA|NORK:ZUK|NORI:NIRI
ADL	ADL	NOR:NI
ADL	ADL	NOR:NI|HIT:NO
ADL	ADL	NOR:NI|NORI:HARI
ADL	ADL	NOR:NI|NORK:HAIEK-K
ADL	ADL	NOR:NI|NORK:HARK
ADL	ADL	NOR:NI|NORK:HIK-NO
ADL	ADL	NOR:NI|NORK:ZUEK-K
ADL	ADL	NOR:NI|NORK:ZUK
ADL	ADL	NOR:ZU
ADL	ADL	NOR:ZUEK
ADL	ADL	NOR:ZUEK|NORK:GUK
ADL	ADL	NOR:ZUEK|NORK:HARK
ADL	ADL	NOR:ZU|NORI:NIRI
ADL	ADL	NOR:ZU|NORK:GUK
ADL	ADL	NOR:ZU|NORK:HAIEK-K
ADL	ADL	NOR:ZU|NORK:HARK
ADL	ADL	NOR:ZU|NORK:NIK
ADL	ADL_IZEELI	KAS:ABL|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:ABS|MUG:MG|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:GU|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HAIEK
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HAIEK|NORI:HAIEI
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HAIEK|NORK:HARK|NORI:GURI
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORK:GUK
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORK:HARK|NORI:HAIEI
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:A5|NOR:HAIEK
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:B1|NOR:HAIEK
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:B1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:B1|NOR:HAIEK|NORK:HAIEK-K|NORI:GURI
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:NIRI
ADL	ADL_IZEELI	KAS:ABS|NUM:P|MUG:M|MDN:B8|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:GU|NORK:HARK
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HAIEK|NORK:HARK
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HAIEK|NORK:HARK|NORI:HAIEI
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORI:HARI
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:GUK
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK|NORI:NIRI
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:NI
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:NI|NORK:HARK
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A5|NOR:HURA
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A5|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A5|NOR:HURA|NORK:HARK
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:A5|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:GU
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:GU|NORK:HARK
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:HAIEK|NORK:HARK|NORI:HARI
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:HURA
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORI:HARI
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:NIRI
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:HARK|NORI:HARI
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:NIK
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:B2|NOR:HURA|NORK:HARK
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:B7|NOR:HURA
ADL	ADL_IZEELI	KAS:ABS|NUM:S|MUG:M|MDN:B8|NOR:HURA
ADL	ADL_IZEELI	KAS:DAT|NUM:P|MUG:M|MDN:B1|NOR:HAIEK|NORK:HARK
ADL	ADL_IZEELI	KAS:DAT|NUM:S|MUG:M|MDN:A1|NOR:HURA
ADL	ADL_IZEELI	KAS:DAT|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:GUK
ADL	ADL_IZEELI	KAS:DAT|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL_IZEELI	KAS:DAT|NUM:S|MUG:M|MDN:B1|NOR:HURA
ADL	ADL_IZEELI	KAS:DES|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL_IZEELI	KAS:DES|NUM:S|MUG:M|MDN:A1|NOR:NI|NORK:HARK
ADL	ADL_IZEELI	KAS:DES|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL_IZEELI	KAS:ERG|NUM:P|MUG:M|MDN:A1|NOR:HAIEK
ADL	ADL_IZEELI	KAS:ERG|NUM:P|MUG:M|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:ERG|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:ERG|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL_IZEELI	KAS:ERG|NUM:S|MUG:M|MDN:A1|NOR:HURA
ADL	ADL_IZEELI	KAS:ERG|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL_IZEELI	KAS:ERG|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:NIK
ADL	ADL_IZEELI	KAS:ERG|NUM:S|MUG:M|MDN:B1|NOR:HURA
ADL	ADL_IZEELI	KAS:ERG|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADL	ADL_IZEELI	KAS:GEL|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:GEN|NUM:P|MUG:M|MDN:A1|NOR:HAIEK
ADL	ADL_IZEELI	KAS:GEN|NUM:P|MUG:M|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:GEN|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:GEN|NUM:P|MUG:M|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:GEN|NUM:S|MUG:M|MDN:A1|NOR:HAIEK
ADL	ADL_IZEELI	KAS:GEN|NUM:S|MUG:M|MDN:A1|NOR:HURA
ADL	ADL_IZEELI	KAS:GEN|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORI:GURI
ADL	ADL_IZEELI	KAS:GEN|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORI:NIRI
ADL	ADL_IZEELI	KAS:GEN|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:GUK
ADL	ADL_IZEELI	KAS:GEN|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:GEN|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HAIEI
ADL	ADL_IZEELI	KAS:GEN|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK
ADL	ADL_IZEELI	KAS:GEN|NUM:S|MUG:M|MDN:A5|NOR:HURA
ADL	ADL_IZEELI	KAS:GEN|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL_IZEELI	KAS:INE|NUM:P|MUG:M|MDN:A1|NOR:HAIEK
ADL	ADL_IZEELI	KAS:INE|NUM:P|MUG:M|MDN:A1|NOR:NI
ADL	ADL_IZEELI	KAS:INE|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:INE|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:HARK
ADL	ADL_IZEELI	KAS:INS|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:MOT|NUM:S|MUG:M|MDN:A1|NOR:HURA
ADL	ADL_IZEELI	KAS:MOT|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:MOT|NUM:S|MUG:M|MDN:B1|NOR:GU|NORK:HARK
ADL	ADL_IZEELI	KAS:MOT|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORI:HARI
ADL	ADL_IZEELI	KAS:SOZ|NUM:P|MUG:M|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:SOZ|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADL	ADL_IZEELI	KAS:SOZ|NUM:P|MUG:M|MDN:B1|NOR:HAIEK
ADL	ADL_IZEELI	KAS:SOZ|NUM:P|MUG:M|MDN:B1|NOR:HAIEK|NORK:HAIEK-K|NORI:HARI
ADL	ADL_IZEELI	KAS:SOZ|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:NIK
ADL	ADL_IZEELI	KAS:SOZ|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:ZUK
ADL	ADL_IZEELI	KAS:SOZ|NUM:S|MUG:M|MDN:A1|NOR:NI|NORK:HARK
ADL	ADL_IZEELI	KAS:SOZ|NUM:S|MUG:M|MDN:B1|NOR:HURA
ADL	ADL_IZEELI	KAS:SOZ|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:BALD|MDN:A1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:BALD|MDN:A1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|ERL:BALD|MDN:A1|NOR:HAIEK|NORK:NIK
ADT	ADT	ASP:PNT|ERL:BALD|MDN:A1|NOR:HAIEK|NORK:ZUK
ADT	ADT	ASP:PNT|ERL:BALD|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:BALD|MDN:A1|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|ERL:BALD|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:BALD|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:BALD|MDN:A1|NOR:HURA|NORK:ZUEK-K
ADT	ADT	ASP:PNT|ERL:BALD|MDN:A1|NOR:HURA|NORK:ZUK
ADT	ADT	ASP:PNT|ERL:BALD|MDN:A1|NOR:NI
ADT	ADT	ASP:PNT|ERL:BALD|MDN:A1|NOR:ZU
ADT	ADT	ASP:PNT|ERL:BALD|MDN:A4|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|ERL:BALD|MDN:B1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:BALD|MDN:B1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|ERL:BALD|MDN:B1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:BALD|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:BALD|MDN:B1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:BALD|MDN:B1|NOR:HURA|NORK:HIK
ADT	ADT	ASP:PNT|ERL:BALD|MDN:B4|NOR:GU
ADT	ADT	ASP:PNT|ERL:BALD|MDN:B4|NOR:HAIEK|NORK:NIK
ADT	ADT	ASP:PNT|ERL:BALD|MDN:B4|NOR:HURA
ADT	ADT	ASP:PNT|ERL:BALD|MDN:B4|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:BALD|MDN:B4|NOR:ZU
ADT	ADT	ASP:PNT|ERL:BALD|MDN:B6|NOR:HURA
ADT	ADT	ASP:PNT|ERL:BALD|MDN:B7|NOR:HURA
ADT	ADT	ASP:PNT|ERL:DENB|MDN:A1|NOR:GU
ADT	ADT	ASP:PNT|ERL:DENB|MDN:A1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:DENB|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:DENB|MDN:A1|NOR:HAIEK|NORK:NIK
ADT	ADT	ASP:PNT|ERL:DENB|MDN:A1|NOR:HAIEK|NORK:ZUK
ADT	ADT	ASP:PNT|ERL:DENB|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:DENB|MDN:A1|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|ERL:DENB|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:DENB|MDN:A1|NOR:NI
ADT	ADT	ASP:PNT|ERL:DENB|MDN:B1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|ERL:DENB|MDN:B1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:DENB|MDN:B1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:GU
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:GU|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HAIEK|NORI:HAIEI
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HAIEK|NORI:HARI
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HAIEK|NORK:GUK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORI:HAIEI
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORI:NIRI
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORI:ZURI
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORK:HIK-NO
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:HURA|NORK:ZUK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:NI
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A1|NOR:ZUEK|NORK:HARK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:A3|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B1|NOR:GU
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HAIEK|NORI:HAIEI
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HAIEK|NORI:HARI
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HAIEK|NORK:GUK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B1|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B1|NOR:NI
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B5B|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B5B|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:ERLT|MDN:B5B|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:ERLT|MOD:EGI|MDN:A1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:A1|NOR:GU
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORI:GURI
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORI:HAIEI
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORI:NIRI
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:A1|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:A1|NOR:NI
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:B1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:B1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:B1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:B1|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:B1|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:B1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:B1|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:B1|NOR:NI
ADT	ADT	ASP:PNT|ERL:KAUS|MDN:B2|NOR:HURA
ADT	ADT	ASP:PNT|ERL:KAUS|MOD:EGI|MDN:A1|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|ERL:KAUS|MOD:EGI|MDN:B1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:GU
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:GUK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:NIK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HAIEK|NORK:ZUK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORI:HAIEI
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORK:HARK|NORI:HAIEI
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:NI
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A1|NOR:ZU
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A3|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:A3|NOR:HURA
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B1|NOR:GU
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HAIEK|NORK:GUK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B1|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B1|NOR:NI
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B2|NOR:HURA
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B5B|NOR:HURA
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B5B|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B7|NOR:HURA
ADT	ADT	ASP:PNT|ERL:KONPL|MDN:B8|NOR:HURA
ADT	ADT	ASP:PNT|ERL:KONPL|MOD:EGI|MDN:A1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:KONPL|MOD:EGI|MDN:A1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|ERL:KONPL|MOD:EGI|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:KONPL|MOD:EGI|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:KONPL|MOD:EGI|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:KONPL|MOD:EGI|MDN:A1|NOR:HURA|NORK:HIK-TO
ADT	ADT	ASP:PNT|ERL:KONPL|MOD:EGI|MDN:A1|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|ERL:KONPL|MOD:EGI|MDN:B1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:KONPL|MOD:EGI|MDN:B1|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:A1|NOR:GU
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:A1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:A1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:A1|NOR:HURA|NORI:NIRI
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:A1|NOR:HURA|NORK:HARK|ENT:Pertsona
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:A1|NOR:ZU
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:B1|NOR:GU
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:B1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:B1|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:B1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:B1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:B1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:B1|NOR:NI
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:B1|NOR:ZU
ADT	ADT	ASP:PNT|ERL:MOD/DENB|MDN:B5B|NOR:NI
ADT	ADT	ASP:PNT|ERL:MOD|MDN:A1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:MOD|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:MOS|MDN:A1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:MOS|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:MOS|MDN:A1|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|ERL:MOS|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:MOS|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:MOS|MDN:B1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:MOS|MDN:B1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:MOS|MDN:B1|NOR:HURA|NORI:NIRI
ADT	ADT	ASP:PNT|ERL:MOS|MDN:B1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:MOS|MDN:B4|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|ERL:MOS|MDN:B4|NOR:HURA
ADT	ADT	ASP:PNT|ERL:MOS|MOD:EGI|MDN:A1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|ERL:MOS|MOD:EGI|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:ZHG|MDN:A1|NOR:GU
ADT	ADT	ASP:PNT|ERL:ZHG|MDN:A1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:ZHG|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:ZHG|MDN:A1|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|ERL:ZHG|MDN:A1|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|ERL:ZHG|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:ZHG|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|ERL:ZHG|MDN:A1|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|ERL:ZHG|MDN:A1|NOR:HURA|NORK:ZUK
ADT	ADT	ASP:PNT|ERL:ZHG|MDN:B1|NOR:GU
ADT	ADT	ASP:PNT|ERL:ZHG|MDN:B1|NOR:HAIEK
ADT	ADT	ASP:PNT|ERL:ZHG|MDN:B1|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|ERL:ZHG|MDN:B1|NOR:HURA
ADT	ADT	ASP:PNT|ERL:ZHG|MDN:B1|NOR:NI
ADT	ADT	ASP:PNT|ERL:ZHG|MOD:EGI|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|KAS:ABL|NUM:S|NOR:GU
ADT	ADT	ASP:PNT|KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|KAS:ABS|NUM:P|NOR:GU
ADT	ADT	ASP:PNT|KAS:ABS|NUM:P|NOR:HAIEK
ADT	ADT	ASP:PNT|KAS:ABS|NUM:P|NOR:HAIEK|NORI:HAIEI
ADT	ADT	ASP:PNT|KAS:ABS|NUM:P|NOR:HAIEK|NORI:HARI
ADT	ADT	ASP:PNT|KAS:ABS|NUM:P|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|KAS:ABS|NUM:P|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|KAS:ABS|NUM:P|NOR:HURA
ADT	ADT	ASP:PNT|KAS:ABS|NUM:P|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|KAS:ABS|NUM:P|NOR:ZU|NORK:GUK
ADT	ADT	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|KAS:ABS|NUM:S|NOR:HAIEK
ADT	ADT	ASP:PNT|KAS:ABS|NUM:S|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|KAS:ABS|NUM:S|NOR:HURA
ADT	ADT	ASP:PNT|KAS:ABS|NUM:S|NOR:HURA|NORI:GURI
ADT	ADT	ASP:PNT|KAS:ABS|NUM:S|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|KAS:ABS|NUM:S|NOR:HURA|NORI:ZURI
ADT	ADT	ASP:PNT|KAS:ABS|NUM:S|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|KAS:ABS|NUM:S|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|KAS:ABS|NUM:S|NOR:HURA|NORK:HARK|NORI:HARI
ADT	ADT	ASP:PNT|KAS:ABS|NUM:S|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|KAS:ABS|NUM:S|NOR:HURA|NORK:ZUK
ADT	ADT	ASP:PNT|KAS:ABS|NUM:S|NOR:NI
ADT	ADT	ASP:PNT|KAS:DAT|NUM:P|NOR:HAIEK
ADT	ADT	ASP:PNT|KAS:DAT|NUM:P|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|KAS:DAT|NUM:P|NOR:HURA|NORI:HAIEI
ADT	ADT	ASP:PNT|KAS:DAT|NUM:S|NOR:HURA
ADT	ADT	ASP:PNT|KAS:DAT|NUM:S|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|KAS:DAT|NUM:S|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|KAS:DES|NUM:S|NOR:HURA
ADT	ADT	ASP:PNT|KAS:ERG|NUM:P|NOR:GU
ADT	ADT	ASP:PNT|KAS:ERG|NUM:P|NOR:HAIEK
ADT	ADT	ASP:PNT|KAS:ERG|NUM:P|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|KAS:ERG|NUM:S|NOR:HURA
ADT	ADT	ASP:PNT|KAS:ERG|NUM:S|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|KAS:ERG|NUM:S|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|KAS:GEL|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|KAS:GEL|NOR:HURA
ADT	ADT	ASP:PNT|KAS:GEL|NUM:P|NOR:HAIEK
ADT	ADT	ASP:PNT|KAS:GEN|NUM:P|NOR:HAIEK
ADT	ADT	ASP:PNT|KAS:GEN|NUM:S|MUG:M|MDN:B1|NOR:HURA
ADT	ADT	ASP:PNT|KAS:GEN|NUM:S|NOR:HAIEK
ADT	ADT	ASP:PNT|KAS:GEN|NUM:S|NOR:HURA
ADT	ADT	ASP:PNT|KAS:GEN|NUM:S|NOR:HURA|NORI:HAIEI
ADT	ADT	ASP:PNT|KAS:GEN|NUM:S|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|KAS:INE|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|KAS:INE|NUM:S|MUG:M|MDN:B5B|NOR:HURA
ADT	ADT	ASP:PNT|KAS:INE|NUM:S|NOR:HURA
ADT	ADT	ASP:PNT|KAS:INE|NUM:S|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|KAS:INS|MUG:MG|MDN:A1|NOR:HAIEK
ADT	ADT	ASP:PNT|KAS:INS|NOR:HAIEK
ADT	ADT	ASP:PNT|KAS:INS|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORI:HAIEI
ADT	ADT	ASP:PNT|KAS:INS|NUM:P|NOR:HURA
ADT	ADT	ASP:PNT|KAS:INS|NUM:P|NOR:HURA|NORI:HAIEI
ADT	ADT	ASP:PNT|KAS:INS|NUM:P|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|KAS:INS|NUM:S|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|KAS:INS|NUM:S|NOR:HURA|NORK:ZUK
ADT	ADT	ASP:PNT|KAS:PAR|MUG:MG|MDN:A5|NOR:HURA
ADT	ADT	ASP:PNT|KAS:PAR|NOR:HURA
ADT	ADT	ASP:PNT|KAS:SOZ|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|KAS:SOZ|NUM:S|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|MDN:A1|NOR:GU
ADT	ADT	ASP:PNT|MDN:A1|NOR:GU|HIT:TO
ADT	ADT	ASP:PNT|MDN:A1|NOR:GU|NORK:HARK
ADT	ADT	ASP:PNT|MDN:A1|NOR:HAIEK
ADT	ADT	ASP:PNT|MDN:A1|NOR:HAIEK|HIT:TO
ADT	ADT	ASP:PNT|MDN:A1|NOR:HAIEK|NORI:GURI
ADT	ADT	ASP:PNT|MDN:A1|NOR:HAIEK|NORI:HAIEI
ADT	ADT	ASP:PNT|MDN:A1|NOR:HAIEK|NORI:HARI
ADT	ADT	ASP:PNT|MDN:A1|NOR:HAIEK|NORK:GUK
ADT	ADT	ASP:PNT|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|MDN:A1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|MDN:A1|NOR:HAIEK|NORK:HARK|HIT:TO
ADT	ADT	ASP:PNT|MDN:A1|NOR:HAIEK|NORK:NIK
ADT	ADT	ASP:PNT|MDN:A1|NOR:HAIEK|NORK:ZUK
ADT	ADT	ASP:PNT|MDN:A1|NOR:HI
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|HIT:NO
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|HIT:TO
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORI:GURI
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORI:HAIEI
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:GUK|NORI:HAIEI
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:GUK|NORI:HARI
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:HAIEK-K|NORI:GURI
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:HARK|NORI:GURI
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:HARK|NORI:HAIEI
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:HARK|NORI:ZURI
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:HIK-NO
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:NIK|HIT:NO
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:NIK|HIT:TO
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:NIK|NORI:HARI
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:ZUEK-K
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:ZUK
ADT	ADT	ASP:PNT|MDN:A1|NOR:HURA|NORK:ZUK|NORI:HARI
ADT	ADT	ASP:PNT|MDN:A1|NOR:NI
ADT	ADT	ASP:PNT|MDN:A1|NOR:NI|HIT:NO
ADT	ADT	ASP:PNT|MDN:A1|NOR:NI|HIT:TO
ADT	ADT	ASP:PNT|MDN:A1|NOR:NI|NORK:ZUK
ADT	ADT	ASP:PNT|MDN:A1|NOR:ZU
ADT	ADT	ASP:PNT|MDN:A1|NOR:ZUEK
ADT	ADT	ASP:PNT|MDN:A5|NOR:HURA
ADT	ADT	ASP:PNT|MDN:B1|NOR:GU
ADT	ADT	ASP:PNT|MDN:B1|NOR:HAIEK
ADT	ADT	ASP:PNT|MDN:B1|NOR:HAIEK|NORI:HARI
ADT	ADT	ASP:PNT|MDN:B1|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|MDN:B1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|MDN:B1|NOR:HAIEK|NORK:NIK
ADT	ADT	ASP:PNT|MDN:B1|NOR:HAIEK|NORK:ZUK|HIT:TO
ADT	ADT	ASP:PNT|MDN:B1|NOR:HURA
ADT	ADT	ASP:PNT|MDN:B1|NOR:HURA|HIT:TO
ADT	ADT	ASP:PNT|MDN:B1|NOR:HURA|NORI:GURI
ADT	ADT	ASP:PNT|MDN:B1|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|MDN:B1|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|MDN:B1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|MDN:B1|NOR:HURA|NORK:HARK|HIT:TO
ADT	ADT	ASP:PNT|MDN:B1|NOR:HURA|NORK:HARK|NORI:HAIEI
ADT	ADT	ASP:PNT|MDN:B1|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|MDN:B1|NOR:HURA|NORK:NIK|HIT:NO
ADT	ADT	ASP:PNT|MDN:B1|NOR:HURA|NORK:ZUEK-K
ADT	ADT	ASP:PNT|MDN:B1|NOR:NI
ADT	ADT	ASP:PNT|MDN:B1|NOR:ZU
ADT	ADT	ASP:PNT|MDN:B2|NOR:HAIEK
ADT	ADT	ASP:PNT|MDN:B2|NOR:HURA
ADT	ADT	ASP:PNT|MDN:B2|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|MDN:B2|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|MDN:B2|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|MDN:B2|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|MDN:B2|NOR:NI
ADT	ADT	ASP:PNT|MDN:B4|NOR:HURA
ADT	ADT	ASP:PNT|MDN:B7|NOR:HURA
ADT	ADT	ASP:PNT|MDN:B7|NOR:HURA|NORK:HARK|NORI:HARI
ADT	ADT	ASP:PNT|MDN:C|NOR:HI
ADT	ADT	ASP:PNT|MDN:C|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|MDN:C|NOR:HURA|NORK:HIK-TO
ADT	ADT	ASP:PNT|MDN:C|NOR:HURA|NORK:ZUK
ADT	ADT	ASP:PNT|MDN:C|NOR:HURA|NORK:ZUK|NORI:NIRI
ADT	ADT	ASP:PNT|MDN:C|NOR:ZU
ADT	ADT	ASP:PNT|MDN:C|NOR:ZUEK
ADT	ADT	ASP:PNT|MOD:EGI|MDN:A1|NOR:HAIEK
ADT	ADT	ASP:PNT|MOD:EGI|MDN:A1|NOR:HAIEK|NORK:GUK
ADT	ADT	ASP:PNT|MOD:EGI|MDN:A1|NOR:HAIEK|NORK:GUK|HIT:NO
ADT	ADT	ASP:PNT|MOD:EGI|MDN:A1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|MOD:EGI|MDN:A1|NOR:HAIEK|NORK:NIK
ADT	ADT	ASP:PNT|MOD:EGI|MDN:A1|NOR:HAIEK|NORK:NIK|HIT:NO
ADT	ADT	ASP:PNT|MOD:EGI|MDN:A1|NOR:HURA
ADT	ADT	ASP:PNT|MOD:EGI|MDN:A1|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|MOD:EGI|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|MOD:EGI|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|MOD:EGI|MDN:A1|NOR:HURA|NORK:HARK|HIT:NO
ADT	ADT	ASP:PNT|MOD:EGI|MDN:A1|NOR:HURA|NORK:HIK-TO
ADT	ADT	ASP:PNT|MOD:EGI|MDN:A1|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|MOD:EGI|MDN:A1|NOR:HURA|NORK:ZUEK-K
ADT	ADT	ASP:PNT|MOD:EGI|MDN:A1|NOR:HURA|NORK:ZUK
ADT	ADT	ASP:PNT|MOD:EGI|MDN:B1|NOR:HAIEK
ADT	ADT	ASP:PNT|MOD:EGI|MDN:B1|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|MOD:EGI|MDN:B1|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|MOD:EGI|MDN:B1|NOR:HURA
ADT	ADT	ASP:PNT|MOD:EGI|MDN:B1|NOR:HURA|NORI:HAIEI
ADT	ADT	ASP:PNT|MOD:EGI|MDN:B1|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|MOD:EGI|MDN:B1|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|MOD:EGI|MDN:B1|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|MOD:EGI|MDN:B1|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|MOD:EGI|MDN:B3|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|MOD:EGI|MDN:B7|NOR:HURA
ADT	ADT	ASP:PNT|NOR:GU
ADT	ADT	ASP:PNT|NOR:GU|HIT:TO
ADT	ADT	ASP:PNT|NOR:GU|NORK:HAIEK-K
ADT	ADT	ASP:PNT|NOR:GU|NORK:HARK
ADT	ADT	ASP:PNT|NOR:HAIEK
ADT	ADT	ASP:PNT|NOR:HAIEK|HIT:TO
ADT	ADT	ASP:PNT|NOR:HAIEK|NORI:GURI
ADT	ADT	ASP:PNT|NOR:HAIEK|NORI:HAIEI
ADT	ADT	ASP:PNT|NOR:HAIEK|NORI:HARI
ADT	ADT	ASP:PNT|NOR:HAIEK|NORK:GUK
ADT	ADT	ASP:PNT|NOR:HAIEK|NORK:GUK|HIT:NO
ADT	ADT	ASP:PNT|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT	ASP:PNT|NOR:HAIEK|NORK:HARK
ADT	ADT	ASP:PNT|NOR:HAIEK|NORK:HARK|HIT:TO
ADT	ADT	ASP:PNT|NOR:HAIEK|NORK:NIK
ADT	ADT	ASP:PNT|NOR:HAIEK|NORK:NIK|HIT:NO
ADT	ADT	ASP:PNT|NOR:HAIEK|NORK:ZUK
ADT	ADT	ASP:PNT|NOR:HAIEK|NORK:ZUK|HIT:TO
ADT	ADT	ASP:PNT|NOR:HI
ADT	ADT	ASP:PNT|NOR:HURA
ADT	ADT	ASP:PNT|NOR:HURA|HIT:NO
ADT	ADT	ASP:PNT|NOR:HURA|HIT:TO
ADT	ADT	ASP:PNT|NOR:HURA|NORI:GURI
ADT	ADT	ASP:PNT|NOR:HURA|NORI:HAIEI
ADT	ADT	ASP:PNT|NOR:HURA|NORI:HARI
ADT	ADT	ASP:PNT|NOR:HURA|NORI:NIRI
ADT	ADT	ASP:PNT|NOR:HURA|NORI:ZURI
ADT	ADT	ASP:PNT|NOR:HURA|NORK:GUK
ADT	ADT	ASP:PNT|NOR:HURA|NORK:GUK|NORI:HAIEI
ADT	ADT	ASP:PNT|NOR:HURA|NORK:GUK|NORI:HARI
ADT	ADT	ASP:PNT|NOR:HURA|NORK:HAIEK-K
ADT	ADT	ASP:PNT|NOR:HURA|NORK:HAIEK-K|NORI:GURI
ADT	ADT	ASP:PNT|NOR:HURA|NORK:HAIEK-K|NORI:HARI
ADT	ADT	ASP:PNT|NOR:HURA|NORK:HARK
ADT	ADT	ASP:PNT|NOR:HURA|NORK:HARK|ENT:Pertsona
ADT	ADT	ASP:PNT|NOR:HURA|NORK:HARK|HIT:NO
ADT	ADT	ASP:PNT|NOR:HURA|NORK:HARK|HIT:TO
ADT	ADT	ASP:PNT|NOR:HURA|NORK:HARK|NORI:GURI
ADT	ADT	ASP:PNT|NOR:HURA|NORK:HARK|NORI:HAIEI
ADT	ADT	ASP:PNT|NOR:HURA|NORK:HARK|NORI:HARI
ADT	ADT	ASP:PNT|NOR:HURA|NORK:HARK|NORI:ZURI
ADT	ADT	ASP:PNT|NOR:HURA|NORK:HIK
ADT	ADT	ASP:PNT|NOR:HURA|NORK:HIK-NO
ADT	ADT	ASP:PNT|NOR:HURA|NORK:HIK-TO
ADT	ADT	ASP:PNT|NOR:HURA|NORK:NIK
ADT	ADT	ASP:PNT|NOR:HURA|NORK:NIK|HIT:NO
ADT	ADT	ASP:PNT|NOR:HURA|NORK:NIK|HIT:TO
ADT	ADT	ASP:PNT|NOR:HURA|NORK:NIK|NORI:HARI
ADT	ADT	ASP:PNT|NOR:HURA|NORK:ZUEK-K
ADT	ADT	ASP:PNT|NOR:HURA|NORK:ZUK
ADT	ADT	ASP:PNT|NOR:HURA|NORK:ZUK|NORI:HARI
ADT	ADT	ASP:PNT|NOR:HURA|NORK:ZUK|NORI:NIRI
ADT	ADT	ASP:PNT|NOR:NI
ADT	ADT	ASP:PNT|NOR:NI|HIT:NO
ADT	ADT	ASP:PNT|NOR:NI|HIT:TO
ADT	ADT	ASP:PNT|NOR:NI|NORK:ZUK
ADT	ADT	ASP:PNT|NOR:ZU
ADT	ADT	ASP:PNT|NOR:ZUEK
ADT	ADT	ASP:PNT|NOR:ZUEK|NORK:HARK
ADT	ADT_IZEELI	ASP:PNT|KAS:ABL|NUM:S|MUG:M|MDN:B1|NOR:GU
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:PH|MUG:M|MDN:A1|NOR:ZU|NORK:GUK
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:GU
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HAIEK
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HAIEK|NORI:HAIEI
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HAIEK|NORI:HARI
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HURA
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORK:HAIEK-K
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:P|MUG:M|MDN:B1|NOR:HAIEK
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:P|MUG:M|MDN:B1|NOR:HAIEK|NORK:HARK
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HAIEK
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HAIEK|NORK:HARK
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORI:GURI
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORI:ZURI
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:GUK
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK|NORI:HARI
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:NIK
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:ZUK
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:A1|NOR:NI
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:HAIEK|NORK:HARK
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:HURA
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORI:HARI
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:B1|NOR:HURA|NORK:HARK
ADT	ADT_IZEELI	ASP:PNT|KAS:ABS|NUM:S|MUG:M|MDN:B7|NOR:HURA
ADT	ADT_IZEELI	ASP:PNT|KAS:DAT|NUM:P|MUG:M|MDN:A1|NOR:HAIEK
ADT	ADT_IZEELI	ASP:PNT|KAS:DAT|NUM:P|MUG:M|MDN:A1|NOR:HAIEK|NORK:HAIEK-K
ADT	ADT_IZEELI	ASP:PNT|KAS:DAT|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORI:HAIEI
ADT	ADT_IZEELI	ASP:PNT|KAS:DAT|NUM:P|MUG:M|MDN:B1|NOR:HAIEK
ADT	ADT_IZEELI	ASP:PNT|KAS:DAT|NUM:S|MUG:M|MDN:A1|NOR:HURA
ADT	ADT_IZEELI	ASP:PNT|KAS:DAT|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORI:HARI
ADT	ADT_IZEELI	ASP:PNT|KAS:DAT|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT_IZEELI	ASP:PNT|KAS:DES|NUM:S|MUG:M|MDN:A1|NOR:HURA
ADT	ADT_IZEELI	ASP:PNT|KAS:ERG|NUM:PH|MUG:M|MDN:A1|NOR:GU
ADT	ADT_IZEELI	ASP:PNT|KAS:ERG|NUM:PH|MUG:M|MDN:A1|NOR:HURA|NORK:GUK
ADT	ADT_IZEELI	ASP:PNT|KAS:ERG|NUM:P|MUG:M|MDN:A1|NOR:HAIEK
ADT	ADT_IZEELI	ASP:PNT|KAS:ERG|NUM:P|MUG:M|MDN:B1|NOR:HAIEK
ADT	ADT_IZEELI	ASP:PNT|KAS:ERG|NUM:S|MUG:M|MDN:A1|NOR:HURA
ADT	ADT_IZEELI	ASP:PNT|KAS:ERG|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORI:HARI
ADT	ADT_IZEELI	ASP:PNT|KAS:ERG|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:HARK
ADT	ADT_IZEELI	ASP:PNT|KAS:GEL|NUM:P|MUG:M|MDN:B1|NOR:HAIEK
ADT	ADT_IZEELI	ASP:PNT|KAS:GEN|NUM:P|MUG:M|MDN:A1|NOR:HAIEK
ADT	ADT_IZEELI	ASP:PNT|KAS:GEN|NUM:P|MUG:M|MDN:B1|NOR:HAIEK
ADT	ADT_IZEELI	ASP:PNT|KAS:GEN|NUM:S|MUG:M|MDN:A1|NOR:HAIEK
ADT	ADT_IZEELI	ASP:PNT|KAS:GEN|NUM:S|MUG:M|MDN:A1|NOR:HURA
ADT	ADT_IZEELI	ASP:PNT|KAS:GEN|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORI:HAIEI
ADT	ADT_IZEELI	ASP:PNT|KAS:GEN|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORI:HARI
ADT	ADT_IZEELI	ASP:PNT|KAS:INE|NUM:S|MUG:M|MDN:A1|NOR:HURA
ADT	ADT_IZEELI	ASP:PNT|KAS:INE|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORI:HARI
ADT	ADT_IZEELI	ASP:PNT|KAS:INE|NUM:S|MUG:M|MDN:A3|NOR:HURA|NORI:HARI
ADT	ADT_IZEELI	ASP:PNT|KAS:INS|NUM:P|MUG:M|MDN:A1|NOR:HURA
ADT	ADT_IZEELI	ASP:PNT|KAS:INS|NUM:P|MUG:M|MDN:A1|NOR:HURA|NORI:HARI
ADT	ADT_IZEELI	ASP:PNT|KAS:INS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORI:HARI
ADT	ADT_IZEELI	ASP:PNT|KAS:INS|NUM:S|MUG:M|MDN:A1|NOR:HURA|NORK:ZUK
BEREIZ	BEREIZ	_
BST	BST	ENT:Pertsona
BST	BST	MTKAT:LAB
BST	BST	MTKAT:LAB|NUM:P|MUG:M|KAS:ERG
BST	BST	MW:B
BST	BST	NUM:P|KAS:ERG
BST	BST	_
DET	BAN	KAS:ABS
DET	BAN	KAS:GEL
DET	BAN	KAS:SOZ
DET	BAN	MUG:MG|KAS:ABS
DET	BAN	MUG:MG|KAS:SOZ
DET	BAN	PLU:-|MUG:MG|KAS:ABS
DET	BAN	_
DET	DZG	KAS:ABL
DET	DZG	KAS:ABS
DET	DZG	KAS:ALA
DET	DZG	KAS:DAT
DET	DZG	KAS:DES
DET	DZG	KAS:EM
DET	DZG	KAS:ERG
DET	DZG	KAS:GEL
DET	DZG	KAS:GEN
DET	DZG	KAS:INE
DET	DZG	KAS:INS
DET	DZG	KAS:MOT
DET	DZG	KAS:PAR
DET	DZG	KAS:SOZ
DET	DZG	MUG:MG|KAS:ABS
DET	DZG	MUG:MG|KAS:ABS|MW:B
DET	DZG	MUG:MG|KAS:DES
DET	DZG	MUG:MG|KAS:GEL
DET	DZG	MUG:MG|KAS:INE
DET	DZG	MUG:MG|KAS:INS
DET	DZG	MUG:MG|KAS:PAR
DET	DZG	MUG:MG|NMG:MG|KAS:ABL
DET	DZG	MUG:MG|NMG:MG|KAS:ABL|POS:POSarteetik|POS:+
DET	DZG	MUG:MG|NMG:MG|KAS:ABS
DET	DZG	MUG:MG|NMG:MG|KAS:ABS|MW:B
DET	DZG	MUG:MG|NMG:MG|KAS:ABS|POS:POSgain|POS:+
DET	DZG	MUG:MG|NMG:MG|KAS:ALA|POS:POSantzera|POS:+
DET	DZG	MUG:MG|NMG:MG|KAS:DAT
DET	DZG	MUG:MG|NMG:MG|KAS:DES
DET	DZG	MUG:MG|NMG:MG|KAS:EM|POS:POSbezala|POS:+
DET	DZG	MUG:MG|NMG:MG|KAS:EM|POS:POSbidez|POS:+
DET	DZG	MUG:MG|NMG:MG|KAS:EM|POS:POSkontra|POS:+
DET	DZG	MUG:MG|NMG:MG|KAS:ERG
DET	DZG	MUG:MG|NMG:MG|KAS:GEL
DET	DZG	MUG:MG|NMG:MG|KAS:GEN
DET	DZG	MUG:MG|NMG:MG|KAS:INE
DET	DZG	MUG:MG|NMG:MG|KAS:INE|POS:POSartean|POS:+
DET	DZG	MUG:MG|NMG:MG|KAS:INE|POS:POSaurrean|POS:+
DET	DZG	MUG:MG|NMG:MG|KAS:INS
DET	DZG	MUG:MG|NMG:MG|KAS:MOT
DET	DZG	MUG:MG|NMG:MG|KAS:PAR
DET	DZG	MUG:MG|NMG:MG|KAS:SOZ
DET	DZG	MUG:MG|NMG:MG|KAS:SOZ|MW:B
DET	DZG	MUG:MG|NMG:P|KAS:ABS
DET	DZG	MUG:MG|NMG:P|KAS:GEL
DET	DZG	MUG:MG|NMG:P|KAS:GEN
DET	DZG	MUG:MG|NMG:P|KAS:INE
DET	DZG	MW:B
DET	DZG	NMG:MG
DET	DZG	NMG:MG|KAS:ABS|POS:POSarte|POS:+
DET	DZG	NMG:MG|KAS:ALA
DET	DZG	NMG:MG|KAS:DESK
DET	DZG	NMG:MG|KAS:INE
DET	DZG	NMG:MG|MW:B
DET	DZG	NMG:P
DET	DZG	NMG:S|MW:B
DET	DZG	NUM:PH|MUG:M|KAS:ABS
DET	DZG	NUM:P|KAS:ABL
DET	DZG	NUM:P|KAS:ABS
DET	DZG	NUM:P|KAS:ALA
DET	DZG	NUM:P|KAS:DAT
DET	DZG	NUM:P|KAS:DES
DET	DZG	NUM:P|KAS:EM
DET	DZG	NUM:P|KAS:ERG
DET	DZG	NUM:P|KAS:GEL
DET	DZG	NUM:P|KAS:GEN
DET	DZG	NUM:P|KAS:INE
DET	DZG	NUM:P|KAS:INS
DET	DZG	NUM:P|KAS:MOT
DET	DZG	NUM:P|KAS:SOZ
DET	DZG	NUM:P|MUG:M|KAS:ABL
DET	DZG	NUM:P|MUG:M|KAS:ABL|POS:POSgainetik|POS:+
DET	DZG	NUM:P|MUG:M|KAS:ABS
DET	DZG	NUM:P|MUG:M|KAS:DAT
DET	DZG	NUM:P|MUG:M|KAS:DES
DET	DZG	NUM:P|MUG:M|KAS:EM|POS:POSbezala|POS:+
DET	DZG	NUM:P|MUG:M|KAS:ERG
DET	DZG	NUM:P|MUG:M|KAS:GEL
DET	DZG	NUM:P|MUG:M|KAS:GEN
DET	DZG	NUM:P|MUG:M|KAS:INE
DET	DZG	NUM:P|MUG:M|KAS:INE|POS:POSaintzinean|POS:+
DET	DZG	NUM:P|MUG:M|KAS:INE|POS:POSartean|POS:+
DET	DZG	NUM:P|MUG:M|KAS:SOZ
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:ABL
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:ABL|POS:POSaldetik|POS:+
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:ABL|POS:POSatzetik|POS:+
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:ABS
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:ABS|MW:B
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:ABS|POS:POSesker|POS:+
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:ALA
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:DAT
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:DES
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:ERG
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:GEL
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:GEL|POS:POSaurkako|POS:+
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:GEN
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:INE
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:INE|POS:POSartean|POS:+
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:INS
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:INS|POS:POSbitartez|POS:+
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:MOT
DET	DZG	NUM:P|MUG:M|NMG:P|KAS:SOZ
DET	DZG	NUM:S|KAS:ABL
DET	DZG	NUM:S|KAS:ABS
DET	DZG	NUM:S|KAS:ABZ
DET	DZG	NUM:S|KAS:ALA
DET	DZG	NUM:S|KAS:DAT
DET	DZG	NUM:S|KAS:EM
DET	DZG	NUM:S|KAS:ERG
DET	DZG	NUM:S|KAS:GEL
DET	DZG	NUM:S|KAS:GEN
DET	DZG	NUM:S|KAS:INE
DET	DZG	NUM:S|KAS:INS
DET	DZG	NUM:S|KAS:SOZ
DET	DZG	NUM:S|MUG:M|KAS:ABL
DET	DZG	NUM:S|MUG:M|KAS:ABL|POS:POSatzetik|POS:+
DET	DZG	NUM:S|MUG:M|KAS:ABL|POS:POSgibeletik|POS:+
DET	DZG	NUM:S|MUG:M|KAS:ABS
DET	DZG	NUM:S|MUG:M|KAS:ABZ
DET	DZG	NUM:S|MUG:M|KAS:ALA
DET	DZG	NUM:S|MUG:M|KAS:ALA|MW:B
DET	DZG	NUM:S|MUG:M|KAS:DAT
DET	DZG	NUM:S|MUG:M|KAS:EM|POS:POSondoren|POS:+
DET	DZG	NUM:S|MUG:M|KAS:ERG
DET	DZG	NUM:S|MUG:M|KAS:GEL
DET	DZG	NUM:S|MUG:M|KAS:GEN
DET	DZG	NUM:S|MUG:M|KAS:INE
DET	DZG	NUM:S|MUG:M|KAS:INS
DET	DZG	NUM:S|MUG:M|KAS:SOZ
DET	DZG	_
DET	DZH	ENT:???
DET	DZH	KAS:ABL
DET	DZH	KAS:ABS
DET	DZH	KAS:ABS|ENT:???
DET	DZH	KAS:ALA
DET	DZH	KAS:DAT
DET	DZH	KAS:DES
DET	DZH	KAS:EM
DET	DZH	KAS:ERG
DET	DZH	KAS:GEL
DET	DZH	KAS:GEN
DET	DZH	KAS:INE
DET	DZH	KAS:INS
DET	DZH	KAS:MOT
DET	DZH	KAS:PAR
DET	DZH	KAS:SOZ
DET	DZH	MUG:MG|KAS:ABS
DET	DZH	MUG:MG|NMG:P|KAS:ABS
DET	DZH	MUG:MG|NMG:P|KAS:ABS|MW:B
DET	DZH	MUG:MG|NMG:P|KAS:BNK
DET	DZH	MUG:MG|NMG:P|KAS:DAT
DET	DZH	MUG:MG|NMG:P|KAS:EM|POS:POSaurrera|POS:+
DET	DZH	MUG:MG|NMG:P|KAS:ERG
DET	DZH	MUG:MG|NMG:P|KAS:GEL
DET	DZH	MUG:MG|NMG:P|KAS:GEN
DET	DZH	MUG:MG|NMG:P|KAS:GEN|MW:B
DET	DZH	MUG:MG|NMG:P|KAS:INE
DET	DZH	MUG:MG|NMG:P|KAS:SOZ
DET	DZH	MUG:MG|NMG:S|KAS:ABS
DET	DZH	MUG:MG|NMG:S|KAS:ABS|ENT:???
DET	DZH	MUG:MG|NMG:S|KAS:ABS|MW:B
DET	DZH	MUG:MG|NMG:S|KAS:ABS|POS:POSesker|POS:+
DET	DZH	MUG:MG|NMG:S|KAS:ALA|POS:POSbatera|POS:+
DET	DZH	MUG:MG|NMG:S|KAS:DAT
DET	DZH	MUG:MG|NMG:S|KAS:DES
DET	DZH	MUG:MG|NMG:S|KAS:EM|POS:POSbegira|POS:+
DET	DZH	MUG:MG|NMG:S|KAS:EM|POS:POSburuz|POS:+
DET	DZH	MUG:MG|NMG:S|KAS:ERG
DET	DZH	MUG:MG|NMG:S|KAS:INS
DET	DZH	MUG:MG|NMG:S|KAS:PAR
DET	DZH	MUG:MG|NMG:S|KAS:SOZ
DET	DZH	MUG:MG|NMG:S|KAS:SOZ|MW:B
DET	DZH	NMG:P
DET	DZH	NMG:P|ENT:???
DET	DZH	NMG:P|KAS:DESK
DET	DZH	NMG:P|MW:B
DET	DZH	NMG:S
DET	DZH	NMG:S|KAS:ABL|POS:POSatzetik|POS:+
DET	DZH	NMG:S|KAS:ABL|POS:POSaurretik|POS:+
DET	DZH	NMG:S|KAS:ABL|POS:POSondotik|POS:+
DET	DZH	NMG:S|KAS:ABS|POS:POSalde|POS:+
DET	DZH	NMG:S|KAS:ABS|POS:POSaurka|POS:+
DET	DZH	NMG:S|KAS:ALA|POS:POSgainerat|POS:+
DET	DZH	NMG:S|KAS:DESK
DET	DZH	NMG:S|KAS:EM|POS:POSarabera|POS:+
DET	DZH	NMG:S|KAS:EM|POS:POSbila|POS:+
DET	DZH	NMG:S|KAS:EM|POS:POSgisan|POS:+
DET	DZH	NMG:S|KAS:EM|POS:POSkontra|POS:+
DET	DZH	NMG:S|KAS:EM|POS:POSondoren|POS:+
DET	DZH	NMG:S|KAS:EM|POS:POSordez|POS:+
DET	DZH	NMG:S|KAS:GEL|POS:POSkontrako|POS:+
DET	DZH	NMG:S|KAS:GEN
DET	DZH	NMG:S|KAS:INE
DET	DZH	NMG:S|KAS:INE|POS:POSatzean|POS:+
DET	DZH	NMG:S|KAS:INE|POS:POSaurrean|POS:+
DET	DZH	NMG:S|KAS:INE|POS:POSazpian|POS:+
DET	DZH	NMG:S|KAS:INE|POS:POSbarnean|POS:+
DET	DZH	NMG:S|KAS:INE|POS:POSbarruan|POS:+
DET	DZH	NMG:S|KAS:INE|POS:POSerdian|POS:+
DET	DZH	NMG:S|KAS:INE|POS:POSeskuetan|POS:+
DET	DZH	NMG:S|KAS:INE|POS:POSgainean|POS:+
DET	DZH	NMG:S|KAS:INE|POS:POSinguruan|POS:+
DET	DZH	NMG:S|KAS:INE|POS:POSondoan|POS:+
DET	DZH	NMG:S|KAS:INE|POS:POSparean|POS:+
DET	DZH	NMG:S|KAS:INE|POS:POSpean|POS:+
DET	DZH	NMG:S|KAS:INS|POS:POSbidez|POS:+
DET	DZH	NMG:S|KAS:INS|POS:POSbitartez|POS:+
DET	DZH	NMG:S|KAS:MOT
DET	DZH	NUM:PH|MUG:M|NMG:P|KAS:ABL|POS:POSaldetik|POS:+
DET	DZH	NUM:PH|MUG:M|NMG:P|KAS:ABS
DET	DZH	NUM:PH|MUG:M|NMG:P|KAS:DAT
DET	DZH	NUM:PH|MUG:M|NMG:P|KAS:ERG
DET	DZH	NUM:PH|MUG:M|NMG:P|KAS:GEN
DET	DZH	NUM:PH|MUG:M|NMG:P|KAS:INE|POS:POSartean|POS:+
DET	DZH	NUM:P|KAS:ABL
DET	DZH	NUM:P|KAS:ABS
DET	DZH	NUM:P|KAS:ALA
DET	DZH	NUM:P|KAS:DAT
DET	DZH	NUM:P|KAS:DAT|ENT:Erakundea
DET	DZH	NUM:P|KAS:DES
DET	DZH	NUM:P|KAS:EM
DET	DZH	NUM:P|KAS:ERG
DET	DZH	NUM:P|KAS:ERG|ENT:Pertsona
DET	DZH	NUM:P|KAS:GEL
DET	DZH	NUM:P|KAS:GEN
DET	DZH	NUM:P|KAS:INE
DET	DZH	NUM:P|KAS:SOZ
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:ABL
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:ABS
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:ABS|POS:POSarte|POS:+
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:ALA
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:ALA|POS:POSaldera|POS:+
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:ALA|POS:POSaurrera|POS:+
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:DAT
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:DAT|ENT:Erakundea
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:DES
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:EM|POS:POSaitzina|POS:+
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:EM|POS:POSirian|POS:+
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:ERG
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:ERG|ENT:Pertsona
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:GEL
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:GEL|POS:POSarteko|POS:+
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:GEN
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:INE
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:INE|POS:POSartean|POS:+
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:INE|POS:POSbitartean|POS:+
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:INE|POS:POSinguruan|POS:+
DET	DZH	NUM:P|MUG:M|NMG:P|KAS:SOZ
DET	DZH	NUM:S|KAS:ABL
DET	DZH	NUM:S|KAS:ABS
DET	DZH	NUM:S|KAS:ABZ
DET	DZH	NUM:S|KAS:ALA
DET	DZH	NUM:S|KAS:EM
DET	DZH	NUM:S|KAS:ERG
DET	DZH	NUM:S|KAS:GEL
DET	DZH	NUM:S|KAS:INE
DET	DZH	NUM:S|KAS:INS
DET	DZH	NUM:S|KAS:SOZ
DET	DZH	NUM:S|MUG:M|KAS:GEL
DET	DZH	NUM:S|MUG:M|NMG:P|KAS:ABS
DET	DZH	NUM:S|MUG:M|NMG:P|KAS:SOZ
DET	DZH	NUM:S|MUG:M|NMG:S|KAS:ABL
DET	DZH	NUM:S|MUG:M|NMG:S|KAS:ABS
DET	DZH	NUM:S|MUG:M|NMG:S|KAS:ABZ
DET	DZH	NUM:S|MUG:M|NMG:S|KAS:ALA
DET	DZH	NUM:S|MUG:M|NMG:S|KAS:ALA|POS:POSbehera|POS:+
DET	DZH	NUM:S|MUG:M|NMG:S|KAS:EM|POS:POSbezala|POS:+
DET	DZH	NUM:S|MUG:M|NMG:S|KAS:EM|POS:POShurbil|POS:+
DET	DZH	NUM:S|MUG:M|NMG:S|KAS:EM|POS:POSzehar|POS:+
DET	DZH	NUM:S|MUG:M|NMG:S|KAS:ERG
DET	DZH	NUM:S|MUG:M|NMG:S|KAS:GEL
DET	DZH	NUM:S|MUG:M|NMG:S|KAS:INE
DET	DZH	NUM:S|MUG:M|NMG:S|KAS:INS
DET	DZH	_
DET	ERKARR	KAS:ABS
DET	ERKARR	KAS:GEN
DET	ERKARR	MUG:MG|KAS:ABS
DET	ERKARR	MUG:MG|KAS:GEN
DET	ERKARR	NUM:P|KAS:ABL
DET	ERKARR	NUM:P|KAS:ABS
DET	ERKARR	NUM:P|KAS:ALA
DET	ERKARR	NUM:P|KAS:DAT
DET	ERKARR	NUM:P|KAS:DES
DET	ERKARR	NUM:P|KAS:EM
DET	ERKARR	NUM:P|KAS:ERG
DET	ERKARR	NUM:P|KAS:GEL
DET	ERKARR	NUM:P|KAS:GEN
DET	ERKARR	NUM:P|KAS:INE
DET	ERKARR	NUM:P|KAS:INS
DET	ERKARR	NUM:P|KAS:SOZ
DET	ERKARR	NUM:P|MUG:M|KAS:ABL
DET	ERKARR	NUM:P|MUG:M|KAS:ABL|POS:POSaurretik|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:ABL|POS:POSgainetik|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:ABS
DET	ERKARR	NUM:P|MUG:M|KAS:ABS|MAI:IND
DET	ERKARR	NUM:P|MUG:M|KAS:ABS|POS:POSalde|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:ABS|POS:POSgain|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:ALA
DET	ERKARR	NUM:P|MUG:M|KAS:ALA|POS:POSbatera|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:ALA|POS:POSgainera|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:ALA|POS:POSondora|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:DAT
DET	ERKARR	NUM:P|MUG:M|KAS:DES
DET	ERKARR	NUM:P|MUG:M|KAS:EM|POS:POSarabera|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:EM|POS:POSbarrena|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:EM|POS:POSbatera|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:EM|POS:POSbezalako|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:EM|POS:POSburuz|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:EM|POS:POSkontra|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:EM|POS:POSondoren|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:EM|POS:POSordez|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:EM|POS:POSzehar|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:ERG
DET	ERKARR	NUM:P|MUG:M|KAS:GEL
DET	ERKARR	NUM:P|MUG:M|KAS:GEL|POS:POSburuzko|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:GEL|POS:POSkontrako|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:GEN
DET	ERKARR	NUM:P|MUG:M|KAS:INE
DET	ERKARR	NUM:P|MUG:M|KAS:INE|POS:POSartean|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:INE|POS:POSatzean|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:INE|POS:POSaurrean|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:INE|POS:POSburuan|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:INE|POS:POSostean|POS:+
DET	ERKARR	NUM:P|MUG:M|KAS:INS
DET	ERKARR	NUM:P|MUG:M|KAS:SOZ
DET	ERKARR	NUM:S|KAS:ABL
DET	ERKARR	NUM:S|KAS:ABS
DET	ERKARR	NUM:S|KAS:ABU
DET	ERKARR	NUM:S|KAS:ALA
DET	ERKARR	NUM:S|KAS:DAT
DET	ERKARR	NUM:S|KAS:DES
DET	ERKARR	NUM:S|KAS:EM
DET	ERKARR	NUM:S|KAS:ERG
DET	ERKARR	NUM:S|KAS:GEL
DET	ERKARR	NUM:S|KAS:GEN
DET	ERKARR	NUM:S|KAS:INE
DET	ERKARR	NUM:S|KAS:INS
DET	ERKARR	NUM:S|KAS:MOT
DET	ERKARR	NUM:S|KAS:SOZ
DET	ERKARR	NUM:S|MUG:M|KAS:ABL
DET	ERKARR	NUM:S|MUG:M|KAS:ABL|POS:POSatzetik|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:ABL|POS:POSaurretik|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:ABL|POS:POSondotik|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:ABS
DET	ERKARR	NUM:S|MUG:M|KAS:ABS|MAI:IND
DET	ERKARR	NUM:S|MUG:M|KAS:ABS|POS:POSalde|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:ABS|POS:POSarte|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:ABS|POS:POSaurka|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:ABS|POS:POSesker|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:ABS|POS:POSgain|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:ABS|POS:POSlanda|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:ABS|POS:POSmenpe|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:ABS|POS:POSpareko|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:ABS|POS:POStruke|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:ABU
DET	ERKARR	NUM:S|MUG:M|KAS:ALA
DET	ERKARR	NUM:S|MUG:M|KAS:ALA|POS:POSbatera|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:ALA|POS:POSgainera|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:DAT
DET	ERKARR	NUM:S|MUG:M|KAS:DES
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSantzeko|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSarabera|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSat|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSaurrera|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSbarrena|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSbegira|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSbezalako|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSbila|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSburuz|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSgainera|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSkontra|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSondoren|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSordez|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSurrun|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSzain|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:EM|POS:POSzehar|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:ERG
DET	ERKARR	NUM:S|MUG:M|KAS:GEL
DET	ERKARR	NUM:S|MUG:M|KAS:GEL|POS:POSantzeko|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:GEL|POS:POSatzeko|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:GEL|POS:POSburuzko|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:GEL|POS:POSinguruko|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:GEL|POS:POSkontrako|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:GEL|POS:POSondorengo|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:GEN
DET	ERKARR	NUM:S|MUG:M|KAS:INE
DET	ERKARR	NUM:S|MUG:M|KAS:INE|MAI:IND
DET	ERKARR	NUM:S|MUG:M|KAS:INE|POS:POSaldean|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:INE|POS:POSatzean|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:INE|POS:POSaurrean|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:INE|POS:POSbaitan|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:INE|POS:POSbarnean|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:INE|POS:POSbarruan|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:INE|POS:POSburuan|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:INE|POS:POSgainean|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:INE|POS:POSinguruan|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:INE|POS:POSlekuan|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:INS
DET	ERKARR	NUM:S|MUG:M|KAS:INS|POS:POSbidez|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:INS|POS:POSbitartez|POS:+
DET	ERKARR	NUM:S|MUG:M|KAS:MOT
DET	ERKARR	NUM:S|MUG:M|KAS:MOT|MAI:IND
DET	ERKARR	NUM:S|MUG:M|KAS:SOZ
DET	ERKARR	NUM:S|MUG:M|KAS:SOZ|MAI:IND
DET	ERKIND	KAS:ABL
DET	ERKIND	KAS:ABS
DET	ERKIND	KAS:ALA
DET	ERKIND	KAS:DES
DET	ERKIND	KAS:EM
DET	ERKIND	KAS:GEL
DET	ERKIND	KAS:GEN
DET	ERKIND	KAS:INE
DET	ERKIND	MUG:MG|NMG:S|KAS:ABS
DET	ERKIND	MUG:M|NMG:S|KAS:ABS
DET	ERKIND	NMG:P|KAS:GEN
DET	ERKIND	NMG:S|KAS:ABL
DET	ERKIND	NMG:S|KAS:ABL|POS:POSaitzinetik|POS:+
DET	ERKIND	NMG:S|KAS:ABL|POS:POSaldetik|POS:+
DET	ERKIND	NMG:S|KAS:ABS|POS:POSalde|POS:+
DET	ERKIND	NMG:S|KAS:ABS|POS:POSaurka|POS:+
DET	ERKIND	NMG:S|KAS:ABS|POS:POSesku|POS:+
DET	ERKIND	NMG:S|KAS:ABS|POS:POSgain|POS:+
DET	ERKIND	NMG:S|KAS:ALA
DET	ERKIND	NMG:S|KAS:ALA|POS:POSmodura|POS:+
DET	ERKIND	NMG:S|KAS:DES
DET	ERKIND	NMG:S|KAS:EM|POS:POSantzeko|POS:+
DET	ERKIND	NMG:S|KAS:GEL|POS:POSaurreko|POS:+
DET	ERKIND	NMG:S|KAS:GEL|POS:POSkontrako|POS:+
DET	ERKIND	NMG:S|KAS:GEN
DET	ERKIND	NMG:S|KAS:INE
DET	ERKIND	NMG:S|KAS:INE|POS:POSartean|POS:+
DET	ERKIND	NMG:S|KAS:INE|POS:POSaurrean|POS:+
DET	ERKIND	NMG:S|KAS:INE|POS:POSbaitan|POS:+
DET	ERKIND	NMG:S|KAS:INE|POS:POSbarnean|POS:+
DET	ERKIND	NMG:S|KAS:INE|POS:POSburuan|POS:+
DET	ERKIND	NMG:S|KAS:INE|POS:POSgainean|POS:+
DET	ERKIND	NMG:S|KAS:INE|POS:POSlekuan|POS:+
DET	ERKIND	NMG:S|KAS:INE|POS:POSondoan|POS:+
DET	ERKIND	NUM:P|KAS:ABS
DET	ERKIND	NUM:P|KAS:ERG
DET	ERKIND	NUM:P|KAS:GEN
DET	ERKIND	NUM:P|KAS:INE
DET	ERKIND	NUM:P|KAS:INS
DET	ERKIND	NUM:P|MUG:M|KAS:ABS
DET	ERKIND	NUM:P|MUG:M|NMG:P|KAS:ABS
DET	ERKIND	NUM:P|MUG:M|NMG:P|KAS:ABS|POS:POSesku|POS:+
DET	ERKIND	NUM:P|MUG:M|NMG:P|KAS:ABS|POS:POSmenpe|POS:+
DET	ERKIND	NUM:P|MUG:M|NMG:P|KAS:ERG
DET	ERKIND	NUM:P|MUG:M|NMG:P|KAS:GEN
DET	ERKIND	NUM:P|MUG:M|NMG:P|KAS:INE
DET	ERKIND	NUM:P|MUG:M|NMG:P|KAS:INE|POS:POSartean|POS:+
DET	ERKIND	NUM:P|MUG:M|NMG:P|KAS:INE|POS:POSbaitan|POS:+
DET	ERKIND	NUM:P|MUG:M|NMG:P|KAS:INS
DET	ERKIND	NUM:P|MUG:M|NMG:S|KAS:ABS
DET	ERKIND	NUM:S|KAS:ABS
DET	ERKIND	NUM:S|KAS:ABU
DET	ERKIND	NUM:S|KAS:ALA
DET	ERKIND	NUM:S|KAS:DAT
DET	ERKIND	NUM:S|KAS:DES
DET	ERKIND	NUM:S|KAS:EM
DET	ERKIND	NUM:S|KAS:ERG
DET	ERKIND	NUM:S|KAS:ERG|ENT:Pertsona
DET	ERKIND	NUM:S|KAS:GEN
DET	ERKIND	NUM:S|KAS:INE
DET	ERKIND	NUM:S|KAS:INS
DET	ERKIND	NUM:S|KAS:MOT
DET	ERKIND	NUM:S|KAS:SOZ
DET	ERKIND	NUM:S|MUG:M|KAS:ABS
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:ABS
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:ABU
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:ALA
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:DAT
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:DES
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:EM|POS:POSbezalako|POS:+
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:EM|POS:POSbila|POS:+
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:EM|POS:POSgabe|POS:+
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:EM|POS:POSurruti|POS:+
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:ERG
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:ERG|ENT:Pertsona
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:GEN
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:INE
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:INS
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:MOT
DET	ERKIND	NUM:S|MUG:M|NMG:S|KAS:SOZ
DET	NOLARR	KAS:ABS
DET	NOLARR	KAS:DAT
DET	NOLARR	KAS:ERG
DET	NOLARR	MUG:MG|KAS:ABS
DET	NOLARR	MUG:MG|NMG:MG|KAS:ABS
DET	NOLARR	MUG:MG|NMG:MG|KAS:DAT
DET	NOLARR	MUG:MG|NMG:MG|KAS:ERG
DET	NOLARR	NMG:MG
DET	NOLARR	_
DET	NOLGAL	KAS:ABS
DET	NOLGAL	KAS:ABU
DET	NOLGAL	KAS:ALA
DET	NOLGAL	KAS:DAT
DET	NOLGAL	KAS:DES
DET	NOLGAL	KAS:ERG
DET	NOLGAL	KAS:GEL
DET	NOLGAL	KAS:INE
DET	NOLGAL	KAS:INS
DET	NOLGAL	MUG:MG|KAS:ABS
DET	NOLGAL	MUG:MG|KAS:GEL
DET	NOLGAL	MUG:MG|NMG:MG|KAS:ABS
DET	NOLGAL	MUG:MG|NMG:MG|KAS:ALA
DET	NOLGAL	MUG:MG|NMG:MG|KAS:DAT
DET	NOLGAL	MUG:MG|NMG:MG|KAS:DES
DET	NOLGAL	MUG:MG|NMG:MG|KAS:ERG
DET	NOLGAL	MUG:MG|NMG:MG|KAS:INE
DET	NOLGAL	MUG:MG|NMG:P|KAS:ABS
DET	NOLGAL	NMG:MG
DET	NOLGAL	NMG:MG|KAS:ABU
DET	NOLGAL	NMG:MG|KAS:INS
DET	NOLGAL	NUM:P|KAS:ABS
DET	NOLGAL	NUM:P|KAS:GEN
DET	NOLGAL	NUM:P|KAS:INE
DET	NOLGAL	NUM:P|MUG:M|NMG:MG|KAS:GEN
DET	NOLGAL	NUM:P|MUG:M|NMG:P|KAS:ABS
DET	NOLGAL	NUM:P|MUG:M|NMG:P|KAS:INE
DET	NOLGAL	NUM:S
DET	NOLGAL	NUM:S|KAS:ABS
DET	NOLGAL	NUM:S|MUG:M|NMG:MG|KAS:ABS
DET	NOLGAL	_
DET	ORD	ENT:Erakundea
DET	ORD	ENT:Pertsona
DET	ORD	KAS:ABS
DET	ORD	KAS:INS
DET	ORD	KAS:PAR
DET	ORD	MUG:MG|KAS:ABS
DET	ORD	MUG:MG|KAS:INS
DET	ORD	MUG:MG|KAS:PAR
DET	ORD	NUM:P|KAS:ABS
DET	ORD	NUM:P|KAS:ERG
DET	ORD	NUM:P|KAS:INE
DET	ORD	NUM:P|MUG:M|KAS:ABS
DET	ORD	NUM:P|MUG:M|KAS:ERG
DET	ORD	NUM:P|MUG:M|KAS:INE
DET	ORD	NUM:S|KAS:ABS
DET	ORD	NUM:S|KAS:ABS|ENT:Erakundea
DET	ORD	NUM:S|KAS:ABS|ENT:Pertsona
DET	ORD	NUM:S|KAS:ALA
DET	ORD	NUM:S|KAS:DAT
DET	ORD	NUM:S|KAS:ERG
DET	ORD	NUM:S|KAS:ERG|ENT:Pertsona
DET	ORD	NUM:S|KAS:GEL
DET	ORD	NUM:S|KAS:GEN|ENT:Erakundea
DET	ORD	NUM:S|KAS:GEN|ENT:Pertsona
DET	ORD	NUM:S|KAS:INE
DET	ORD	NUM:S|KAS:SOZ|ENT:Pertsona
DET	ORD	NUM:S|MUG:M|KAS:ABS
DET	ORD	NUM:S|MUG:M|KAS:ABS|ENT:Erakundea
DET	ORD	NUM:S|MUG:M|KAS:ABS|ENT:Pertsona
DET	ORD	NUM:S|MUG:M|KAS:ABS|POS:POSarte|POS:+
DET	ORD	NUM:S|MUG:M|KAS:ALA
DET	ORD	NUM:S|MUG:M|KAS:DAT
DET	ORD	NUM:S|MUG:M|KAS:ERG
DET	ORD	NUM:S|MUG:M|KAS:ERG|ENT:Pertsona
DET	ORD	NUM:S|MUG:M|KAS:GEL
DET	ORD	NUM:S|MUG:M|KAS:GEN|ENT:Erakundea
DET	ORD	NUM:S|MUG:M|KAS:GEN|ENT:Pertsona
DET	ORD	NUM:S|MUG:M|KAS:INE
DET	ORD	NUM:S|MUG:M|KAS:SOZ|ENT:Pertsona
DET	ORD	_
DET	ORO	KAS:ABS
DET	ORO	KAS:DAT
DET	ORO	KAS:ERG
DET	ORO	KAS:INS
DET	ORO	MUG:MG|KAS:ABS
DET	ORO	MUG:MG|NMG:MG|KAS:ABS
DET	ORO	MUG:MG|NMG:MG|KAS:DAT
DET	ORO	MUG:MG|NMG:MG|KAS:ERG
DET	ORO	MUG:MG|NMG:MG|KAS:INS
DET	ORO	NUM:PH|MUG:M|KAS:ABS
DET	ORO	NUM:PH|MUG:M|KAS:DAT
DET	ORO	NUM:PH|MUG:M|KAS:DES
DET	ORO	NUM:PH|MUG:M|KAS:ERG
DET	ORO	NUM:PH|MUG:M|KAS:GEN
DET	ORO	NUM:PH|MUG:M|KAS:INE|POS:POSartean|POS:+
DET	ORO	NUM:P|KAS:ABL
DET	ORO	NUM:P|KAS:ABS
DET	ORO	NUM:P|KAS:ALA
DET	ORO	NUM:P|KAS:DAT
DET	ORO	NUM:P|KAS:DES
DET	ORO	NUM:P|KAS:EM
DET	ORO	NUM:P|KAS:ERG
DET	ORO	NUM:P|KAS:GEL
DET	ORO	NUM:P|KAS:GEN
DET	ORO	NUM:P|KAS:INE
DET	ORO	NUM:P|KAS:INS
DET	ORO	NUM:P|KAS:SOZ
DET	ORO	NUM:P|MUG:M|KAS:ABL
DET	ORO	NUM:P|MUG:M|KAS:ABL|POS:POSgainetik|POS:+
DET	ORO	NUM:P|MUG:M|KAS:ABS
DET	ORO	NUM:P|MUG:M|KAS:ALA
DET	ORO	NUM:P|MUG:M|KAS:DAT
DET	ORO	NUM:P|MUG:M|KAS:DES
DET	ORO	NUM:P|MUG:M|KAS:EM|POS:POSantzera|POS:+
DET	ORO	NUM:P|MUG:M|KAS:EM|POS:POSarabera|POS:+
DET	ORO	NUM:P|MUG:M|KAS:EM|POS:POSbezala|POS:+
DET	ORO	NUM:P|MUG:M|KAS:ERG
DET	ORO	NUM:P|MUG:M|KAS:GEL
DET	ORO	NUM:P|MUG:M|KAS:GEL|POS:POSarteko|POS:+
DET	ORO	NUM:P|MUG:M|KAS:GEN
DET	ORO	NUM:P|MUG:M|KAS:INE
DET	ORO	NUM:P|MUG:M|KAS:INE|POS:POSaldean|POS:+
DET	ORO	NUM:P|MUG:M|KAS:INE|POS:POSartean|POS:+
DET	ORO	NUM:P|MUG:M|KAS:INE|POS:POSerdian|POS:+
DET	ORO	NUM:P|MUG:M|KAS:INS
DET	ORO	NUM:P|MUG:M|KAS:SOZ
DET	ORO	NUM:S|KAS:ABL
DET	ORO	NUM:S|KAS:ABS
DET	ORO	NUM:S|KAS:ALA
DET	ORO	NUM:S|KAS:DAT
DET	ORO	NUM:S|KAS:EM
DET	ORO	NUM:S|KAS:ERG
DET	ORO	NUM:S|KAS:GEN
DET	ORO	NUM:S|KAS:INE
DET	ORO	NUM:S|KAS:MOT
DET	ORO	NUM:S|KAS:SOZ
DET	ORO	NUM:S|MUG:M|KAS:ABL
DET	ORO	NUM:S|MUG:M|KAS:ABL|POS:POSgainetik|POS:+
DET	ORO	NUM:S|MUG:M|KAS:ABS
DET	ORO	NUM:S|MUG:M|KAS:ABS|POS:POSgain|POS:+
DET	ORO	NUM:S|MUG:M|KAS:ALA
DET	ORO	NUM:S|MUG:M|KAS:DAT
DET	ORO	NUM:S|MUG:M|KAS:EM|POS:POSzehar|POS:+
DET	ORO	NUM:S|MUG:M|KAS:ERG
DET	ORO	NUM:S|MUG:M|KAS:GEN
DET	ORO	NUM:S|MUG:M|KAS:INE
DET	ORO	NUM:S|MUG:M|KAS:INE|POS:POSatzean|POS:+
DET	ORO	NUM:S|MUG:M|KAS:INE|POS:POSaurrean|POS:+
DET	ORO	NUM:S|MUG:M|KAS:MOT
DET	ORO	NUM:S|MUG:M|KAS:SOZ
DET	ORO	_
IOR	ELK	KAS:ABS
IOR	ELK	KAS:DAT
IOR	ELK	KAS:EM
IOR	ELK	KAS:GEL
IOR	ELK	KAS:GEN
IOR	ELK	KAS:INE
IOR	ELK	KAS:SOZ
IOR	ELK	MUG:MG|KAS:ABS
IOR	ELK	MUG:MG|KAS:ABS|POS:POSaurka|POS:+
IOR	ELK	MUG:MG|KAS:DAT
IOR	ELK	MUG:MG|KAS:EM|POS:POSburuz|POS:+
IOR	ELK	MUG:MG|KAS:EM|POS:POSkontra|POS:+
IOR	ELK	MUG:MG|KAS:GEL
IOR	ELK	MUG:MG|KAS:GEN
IOR	ELK	MUG:MG|KAS:INE|POS:POSartean|POS:+
IOR	ELK	MUG:MG|KAS:SOZ
IOR	IZGGAL	KAS:ABS
IOR	IZGGAL	KAS:DAT
IOR	IZGGAL	KAS:EM
IOR	IZGGAL	KAS:ERG
IOR	IZGGAL	KAS:SOZ
IOR	IZGGAL	MUG:MG|KAS:ABS
IOR	IZGGAL	MUG:MG|KAS:ABS|POS:POSalde|POS:+
IOR	IZGGAL	MUG:MG|KAS:DAT
IOR	IZGGAL	MUG:MG|KAS:EM|POS:POSkontra|POS:+
IOR	IZGGAL	MUG:MG|KAS:ERG
IOR	IZGGAL	MUG:MG|KAS:SOZ
IOR	IZGGAL	NUM:P|KAS:ABS|PER:HAIEK
IOR	IZGGAL	NUM:P|MUG:M|KAS:ABS|PER:HAIEK
IOR	IZGGAL	NUM:P|MUG:M|KAS:ABS|PER:HAIEK|POS:POSesku|POS:+
IOR	IZGMGB	KAS:ABS
IOR	IZGMGB	KAS:ABS|POS:POSgisako|POS:+
IOR	IZGMGB	KAS:ALA
IOR	IZGMGB	KAS:DAT
IOR	IZGMGB	KAS:DES
IOR	IZGMGB	KAS:ERG
IOR	IZGMGB	KAS:GEL
IOR	IZGMGB	KAS:GEL|MW:B
IOR	IZGMGB	KAS:GEN
IOR	IZGMGB	KAS:INE
IOR	IZGMGB	KAS:INS
IOR	IZGMGB	KAS:MOT
IOR	IZGMGB	KAS:SOZ
IOR	IZGMGB	MUG:MG|KAS:ABS
IOR	IZGMGB	MUG:MG|KAS:ABS|MW:B
IOR	IZGMGB	MUG:MG|KAS:DAT
IOR	IZGMGB	MUG:MG|KAS:DES
IOR	IZGMGB	MUG:MG|KAS:ERG
IOR	IZGMGB	MUG:MG|KAS:GEL
IOR	IZGMGB	MUG:MG|KAS:GEN
IOR	IZGMGB	MUG:MG|KAS:INE
IOR	IZGMGB	MUG:MG|KAS:INS
IOR	IZGMGB	MUG:MG|KAS:SOZ
IOR	IZGMGB	MUG:MG|NMG:MG|KAS:ABS|MW:B
IOR	IZGMGB	MUG:MG|NMG:MG|KAS:ERG|MW:B
IOR	IZGMGB	MUG:MG|NMG:S|KAS:ABS|MW:B
IOR	IZGMGB	MUG:MG|NMG:S|KAS:ERG|MW:B
IOR	IZGMGB	NUM:P|KAS:ABS
IOR	IZGMGB	NUM:P|KAS:ABS|PER:HAIEK
IOR	IZGMGB	NUM:P|KAS:SOZ
IOR	IZGMGB	NUM:P|MUG:M|KAS:ABS|PER:HAIEK
IOR	IZGMGB	NUM:P|MUG:M|KAS:SOZ|MW:B
IOR	IZGMGB	NUM:P|MUG:M|NMG:P|KAS:ABS|MW:B
IOR	IZGMGB	NUM:S|KAS:ABS
IOR	IZGMGB	NUM:S|KAS:ERG
IOR	IZGMGB	NUM:S|KAS:GEN
IOR	IZGMGB	NUM:S|MUG:M|KAS:ABS|POS:POSesku|POS:+
IOR	IZGMGB	NUM:S|MUG:M|KAS:ERG
IOR	IZGMGB	NUM:S|MUG:M|KAS:GEN
IOR	PERARR	NUM:P|KAS:ABL|PER:GU
IOR	PERARR	NUM:P|KAS:ABS|PER:GU
IOR	PERARR	NUM:P|KAS:ABS|PER:HAIEK
IOR	PERARR	NUM:P|KAS:ABS|PER:ZUEK
IOR	PERARR	NUM:P|KAS:DAT|PER:GU
IOR	PERARR	NUM:P|KAS:DAT|PER:HAIEK
IOR	PERARR	NUM:P|KAS:DAT|PER:ZUEK
IOR	PERARR	NUM:P|KAS:DES|PER:GU
IOR	PERARR	NUM:P|KAS:DES|PER:HAIEK
IOR	PERARR	NUM:P|KAS:EM|PER:GU
IOR	PERARR	NUM:P|KAS:EM|PER:HAIEK
IOR	PERARR	NUM:P|KAS:ERG|PER:GU
IOR	PERARR	NUM:P|KAS:ERG|PER:HAIEK
IOR	PERARR	NUM:P|KAS:ERG|PER:ZUEK
IOR	PERARR	NUM:P|KAS:GEL|PER:GU
IOR	PERARR	NUM:P|KAS:GEL|PER:HAIEK
IOR	PERARR	NUM:P|KAS:GEL|PER:ZUEK
IOR	PERARR	NUM:P|KAS:GEN|PER:GU
IOR	PERARR	NUM:P|KAS:GEN|PER:HAIEK
IOR	PERARR	NUM:P|KAS:GEN|PER:ZUEK
IOR	PERARR	NUM:P|KAS:INE|PER:GU
IOR	PERARR	NUM:P|KAS:INE|PER:HAIEK
IOR	PERARR	NUM:P|KAS:INE|PER:ZUEK
IOR	PERARR	NUM:P|KAS:INS|PER:GU
IOR	PERARR	NUM:P|KAS:INS|PER:HAIEK
IOR	PERARR	NUM:P|KAS:INS|PER:ZUEK
IOR	PERARR	NUM:P|KAS:SOZ|PER:GU
IOR	PERARR	NUM:P|KAS:SOZ|PER:HAIEK
IOR	PERARR	NUM:P|MUG:M|KAS:ABL|PER:GU|POS:POSaldetik|POS:+
IOR	PERARR	NUM:P|MUG:M|KAS:ABS|PER:GU
IOR	PERARR	NUM:P|MUG:M|KAS:ABS|PER:HAIEK
IOR	PERARR	NUM:P|MUG:M|KAS:ABS|PER:ZUEK
IOR	PERARR	NUM:P|MUG:M|KAS:ABS|PER:ZUEK|POS:POSgain|POS:+
IOR	PERARR	NUM:P|MUG:M|KAS:DAT|PER:GU
IOR	PERARR	NUM:P|MUG:M|KAS:DAT|PER:HAIEK
IOR	PERARR	NUM:P|MUG:M|KAS:DAT|PER:ZUEK
IOR	PERARR	NUM:P|MUG:M|KAS:DES|PER:GU
IOR	PERARR	NUM:P|MUG:M|KAS:DES|PER:HAIEK
IOR	PERARR	NUM:P|MUG:M|KAS:EM|PER:GU|POS:POSbegira|POS:+
IOR	PERARR	NUM:P|MUG:M|KAS:EM|PER:GU|POS:POSbezala|POS:+
IOR	PERARR	NUM:P|MUG:M|KAS:EM|PER:GU|POS:POSzain|POS:+
IOR	PERARR	NUM:P|MUG:M|KAS:EM|PER:HAIEK|POS:POSkontra|POS:+
IOR	PERARR	NUM:P|MUG:M|KAS:ERG|PER:GU
IOR	PERARR	NUM:P|MUG:M|KAS:ERG|PER:HAIEK
IOR	PERARR	NUM:P|MUG:M|KAS:ERG|PER:ZUEK
IOR	PERARR	NUM:P|MUG:M|KAS:GEL|PER:GU
IOR	PERARR	NUM:P|MUG:M|KAS:GEL|PER:HAIEK|POS:POSarteko|POS:+
IOR	PERARR	NUM:P|MUG:M|KAS:GEL|PER:ZUEK
IOR	PERARR	NUM:P|MUG:M|KAS:GEN|PER:GU
IOR	PERARR	NUM:P|MUG:M|KAS:GEN|PER:HAIEK
IOR	PERARR	NUM:P|MUG:M|KAS:GEN|PER:ZUEK
IOR	PERARR	NUM:P|MUG:M|KAS:INE|PER:GU
IOR	PERARR	NUM:P|MUG:M|KAS:INE|PER:GU|POS:POSartean|POS:+
IOR	PERARR	NUM:P|MUG:M|KAS:INE|PER:GU|POS:POSinguruan|POS:+
IOR	PERARR	NUM:P|MUG:M|KAS:INE|PER:HAIEK|POS:POSaitzinean|POS:+
IOR	PERARR	NUM:P|MUG:M|KAS:INE|PER:HAIEK|POS:POSartean|POS:+
IOR	PERARR	NUM:P|MUG:M|KAS:INE|PER:ZUEK|POS:POSartean|POS:+
IOR	PERARR	NUM:P|MUG:M|KAS:INS|PER:GU
IOR	PERARR	NUM:P|MUG:M|KAS:INS|PER:HAIEK
IOR	PERARR	NUM:P|MUG:M|KAS:INS|PER:ZUEK
IOR	PERARR	NUM:P|MUG:M|KAS:SOZ|PER:GU
IOR	PERARR	NUM:P|MUG:M|KAS:SOZ|PER:HAIEK
IOR	PERARR	NUM:S|KAS:ABL|PER:ZU
IOR	PERARR	NUM:S|KAS:ABS|PER:HI
IOR	PERARR	NUM:S|KAS:ABS|PER:HURA
IOR	PERARR	NUM:S|KAS:ABS|PER:NI
IOR	PERARR	NUM:S|KAS:ABS|PER:ZU
IOR	PERARR	NUM:S|KAS:ALA|PER:NI
IOR	PERARR	NUM:S|KAS:DAT|PER:HI
IOR	PERARR	NUM:S|KAS:DAT|PER:NI
IOR	PERARR	NUM:S|KAS:DES|PER:NI
IOR	PERARR	NUM:S|KAS:DES|PER:ZU
IOR	PERARR	NUM:S|KAS:EM|PER:NI
IOR	PERARR	NUM:S|KAS:ERG|PER:HI
IOR	PERARR	NUM:S|KAS:ERG|PER:NI
IOR	PERARR	NUM:S|KAS:ERG|PER:NI|ENT:Pertsona
IOR	PERARR	NUM:S|KAS:ERG|PER:ZU
IOR	PERARR	NUM:S|KAS:GEL|PER:NI
IOR	PERARR	NUM:S|KAS:GEL|PER:ZU
IOR	PERARR	NUM:S|KAS:GEN|PER:HI
IOR	PERARR	NUM:S|KAS:GEN|PER:NI
IOR	PERARR	NUM:S|KAS:GEN|PER:ZU
IOR	PERARR	NUM:S|KAS:GEN|PER:ZU|ENT:Erakundea
IOR	PERARR	NUM:S|KAS:INE|PER:NI
IOR	PERARR	NUM:S|KAS:INS|PER:NI
IOR	PERARR	NUM:S|KAS:INS|PER:ZU
IOR	PERARR	NUM:S|KAS:MOT|PER:NI
IOR	PERARR	NUM:S|KAS:SOZ|PER:NI
IOR	PERARR	NUM:S|KAS:SOZ|PER:ZU
IOR	PERARR	NUM:S|MUG:M|KAS:ABL|PER:ZU
IOR	PERARR	NUM:S|MUG:M|KAS:ABS|PER:HI
IOR	PERARR	NUM:S|MUG:M|KAS:ABS|PER:HURA
IOR	PERARR	NUM:S|MUG:M|KAS:ABS|PER:NI
IOR	PERARR	NUM:S|MUG:M|KAS:ABS|PER:ZU
IOR	PERARR	NUM:S|MUG:M|KAS:ALA|PER:NI
IOR	PERARR	NUM:S|MUG:M|KAS:DAT|PER:HI
IOR	PERARR	NUM:S|MUG:M|KAS:DAT|PER:NI
IOR	PERARR	NUM:S|MUG:M|KAS:DES|PER:NI
IOR	PERARR	NUM:S|MUG:M|KAS:DES|PER:ZU
IOR	PERARR	NUM:S|MUG:M|KAS:EM|PER:NI|POS:POSbegira|POS:+
IOR	PERARR	NUM:S|MUG:M|KAS:EM|PER:NI|POS:POSbezala|POS:+
IOR	PERARR	NUM:S|MUG:M|KAS:EM|PER:NI|POS:POSzai|POS:+
IOR	PERARR	NUM:S|MUG:M|KAS:ERG|PER:HI
IOR	PERARR	NUM:S|MUG:M|KAS:ERG|PER:NI
IOR	PERARR	NUM:S|MUG:M|KAS:ERG|PER:NI|ENT:Pertsona
IOR	PERARR	NUM:S|MUG:M|KAS:ERG|PER:ZU
IOR	PERARR	NUM:S|MUG:M|KAS:GEL|PER:NI|POS:POSatzeko|POS:+
IOR	PERARR	NUM:S|MUG:M|KAS:GEL|PER:NI|POS:POSbarneko|POS:+
IOR	PERARR	NUM:S|MUG:M|KAS:GEL|PER:ZU|POS:POSbarneko|POS:+
IOR	PERARR	NUM:S|MUG:M|KAS:GEN|PER:HI
IOR	PERARR	NUM:S|MUG:M|KAS:GEN|PER:NI
IOR	PERARR	NUM:S|MUG:M|KAS:GEN|PER:ZU
IOR	PERARR	NUM:S|MUG:M|KAS:GEN|PER:ZU|ENT:Erakundea
IOR	PERARR	NUM:S|MUG:M|KAS:INE|PER:NI
IOR	PERARR	NUM:S|MUG:M|KAS:INE|PER:NI|POS:POSaurrean|POS:+
IOR	PERARR	NUM:S|MUG:M|KAS:INE|PER:NI|POS:POSbarnean|POS:+
IOR	PERARR	NUM:S|MUG:M|KAS:INS|PER:NI
IOR	PERARR	NUM:S|MUG:M|KAS:INS|PER:ZU
IOR	PERARR	NUM:S|MUG:M|KAS:MOT|PER:NI
IOR	PERARR	NUM:S|MUG:M|KAS:SOZ|PER:NI
IOR	PERARR	NUM:S|MUG:M|KAS:SOZ|PER:ZU
IOR	PERIND	NUM:P|KAS:ABS|PER:GU
IOR	PERIND	NUM:P|KAS:DAT|PER:GU
IOR	PERIND	NUM:P|KAS:ERG|PER:GU
IOR	PERIND	NUM:P|KAS:GEN|PER:GU
IOR	PERIND	NUM:P|KAS:INE|PER:GU
IOR	PERIND	NUM:P|MUG:M|KAS:ABS|PER:GU
IOR	PERIND	NUM:P|MUG:M|KAS:DAT|PER:GU
IOR	PERIND	NUM:P|MUG:M|KAS:ERG|PER:GU
IOR	PERIND	NUM:P|MUG:M|KAS:GEN|PER:GU
IOR	PERIND	NUM:P|MUG:M|KAS:INE|PER:GU
IOR	PERIND	NUM:S|KAS:ABL|PER:NI
IOR	PERIND	NUM:S|KAS:ABS|PER:NI
IOR	PERIND	NUM:S|KAS:ABS|PER:ZU
IOR	PERIND	NUM:S|KAS:DAT|PER:NI
IOR	PERIND	NUM:S|KAS:EM|PER:ZU
IOR	PERIND	NUM:S|KAS:ERG|PER:NI
IOR	PERIND	NUM:S|KAS:ERG|PER:ZU
IOR	PERIND	NUM:S|KAS:GEN|PER:HI
IOR	PERIND	NUM:S|KAS:GEN|PER:NI
IOR	PERIND	NUM:S|KAS:GEN|PER:ZU
IOR	PERIND	NUM:S|KAS:INE|PER:NI
IOR	PERIND	NUM:S|KAS:INE|PER:ZU
IOR	PERIND	NUM:S|MUG:M|KAS:ABL|PER:NI|POS:POSaldetik|POS:+
IOR	PERIND	NUM:S|MUG:M|KAS:ABS|PER:NI
IOR	PERIND	NUM:S|MUG:M|KAS:ABS|PER:ZU
IOR	PERIND	NUM:S|MUG:M|KAS:DAT|PER:NI
IOR	PERIND	NUM:S|MUG:M|KAS:EM|PER:ZU|POS:POSgisara|POS:+
IOR	PERIND	NUM:S|MUG:M|KAS:ERG|PER:NI
IOR	PERIND	NUM:S|MUG:M|KAS:ERG|PER:ZU
IOR	PERIND	NUM:S|MUG:M|KAS:GEN|PER:HI
IOR	PERIND	NUM:S|MUG:M|KAS:GEN|PER:NI
IOR	PERIND	NUM:S|MUG:M|KAS:GEN|PER:ZU
IOR	PERIND	NUM:S|MUG:M|KAS:INE|PER:NI|POS:POSburuan|POS:+
IOR	PERIND	NUM:S|MUG:M|KAS:INE|PER:ZU|POS:POSinguruan|POS:+
ITJ	ITJ	MW:B
ITJ	ITJ	_
IZE	ADB_IZEELI	KAS:ABS|NUM:P|MUG:M
IZE	ADB_IZEELI	KAS:ABS|NUM:S|MUG:M
IZE	ADB_IZEELI	KAS:ERG|NUM:P|MUG:M
IZE	ADB_IZEELI	KAS:ERG|NUM:S|MUG:M
IZE	ADB_IZEELI	KAS:GEN|NUM:S|MUG:M
IZE	ADB_IZEELI	KAS:INE|NUM:S|MUG:M
IZE	ADB_IZEELI	KAS:INS|NUM:S|MUG:M
IZE	ADJ_IZEELI	IZAUR:+|KAS:ABS|NUM:P|MUG:M
IZE	ADJ_IZEELI	IZAUR:+|KAS:ABS|NUM:S|MUG:M
IZE	ADJ_IZEELI	IZAUR:-|KAS:ABS|NUM:P|MUG:M
IZE	ADJ_IZEELI	IZAUR:-|KAS:ABS|NUM:S|MUG:M
IZE	ADJ_IZEELI	IZAUR:-|KAS:ABS|NUM:S|MUG:M|ENT:Pertsona
IZE	ADJ_IZEELI	IZAUR:-|KAS:GEN|NUM:P|MUG:M
IZE	ADJ_IZEELI	IZAUR:-|KAS:INE|NUM:S|MUG:M
IZE	ADJ_IZEELI	MAI:SUP|IZAUR:+|KAS:ABS|NUM:S|MUG:M
IZE	ADJ_IZEELI	MAI:SUP|IZAUR:-|KAS:ABS|NUM:S|MUG:M
IZE	ARR	ADM:ADIZE
IZE	ARR	ADM:ADIZE|KAS:ABS|NUM:S
IZE	ARR	ADM:ADIZE|KAS:ABS|NUM:S|MUG:M
IZE	ARR	BIZ:+
IZE	ARR	BIZ:+|ENT:Erakundea
IZE	ARR	BIZ:+|KAS:ABL
IZE	ARR	BIZ:+|KAS:ABL|MUG:MG
IZE	ARR	BIZ:+|KAS:ABL|NUM:P
IZE	ARR	BIZ:+|KAS:ABL|NUM:P|MUG:M
IZE	ARR	BIZ:+|KAS:ABL|NUM:P|MUG:M|POS:POSaldamenetik|POS:+
IZE	ARR	BIZ:+|KAS:ABL|NUM:P|MUG:M|POS:POSaldetik|POS:+
IZE	ARR	BIZ:+|KAS:ABL|NUM:S
IZE	ARR	BIZ:+|KAS:ABL|NUM:S|MUG:M
IZE	ARR	BIZ:+|KAS:ABL|POS:POSaitzinetik|POS:+
IZE	ARR	BIZ:+|KAS:ABS
IZE	ARR	BIZ:+|KAS:ABS|ENT:Erakundea
IZE	ARR	BIZ:+|KAS:ABS|MUG:MG
IZE	ARR	BIZ:+|KAS:ABS|MUG:MG|ENT:Erakundea
IZE	ARR	BIZ:+|KAS:ABS|MUG:MG|MW:B
IZE	ARR	BIZ:+|KAS:ABS|MUG:MG|POS:POSaurka|POS:+
IZE	ARR	BIZ:+|KAS:ABS|NUM:P
IZE	ARR	BIZ:+|KAS:ABS|NUM:PH|MUG:M
IZE	ARR	BIZ:+|KAS:ABS|NUM:P|ENT:Erakundea
IZE	ARR	BIZ:+|KAS:ABS|NUM:P|MUG:M
IZE	ARR	BIZ:+|KAS:ABS|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:+|KAS:ABS|NUM:P|MUG:M|POS:POSalde|POS:+
IZE	ARR	BIZ:+|KAS:ABS|NUM:P|MUG:M|POS:POSaurka|POS:+
IZE	ARR	BIZ:+|KAS:ABS|NUM:P|MUG:M|POS:POSesku|POS:+
IZE	ARR	BIZ:+|KAS:ABS|NUM:S
IZE	ARR	BIZ:+|KAS:ABS|NUM:S|ENT:???
IZE	ARR	BIZ:+|KAS:ABS|NUM:S|ENT:Erakundea
IZE	ARR	BIZ:+|KAS:ABS|NUM:S|MUG:M
IZE	ARR	BIZ:+|KAS:ABS|NUM:S|MUG:M|ENT:???
IZE	ARR	BIZ:+|KAS:ABS|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:+|KAS:ABS|NUM:S|MUG:M|MW:B
IZE	ARR	BIZ:+|KAS:ABS|NUM:S|MUG:M|POS:POSalde|POS:+
IZE	ARR	BIZ:+|KAS:ABS|NUM:S|MUG:M|POS:POSeskuko|POS:+
IZE	ARR	BIZ:+|KAS:ABS|NUM:S|MUG:M|POS:POSgain|POS:+
IZE	ARR	BIZ:+|KAS:ABS|NUM:S|MUG:M|POS:POSmenpe|POS:+
IZE	ARR	BIZ:+|KAS:ABS|POS:POSgisa|POS:+
IZE	ARR	BIZ:+|KAS:ABS|POS:POSinguru|POS:+
IZE	ARR	BIZ:+|KAS:ALA
IZE	ARR	BIZ:+|KAS:ALA|MUG:MG
IZE	ARR	BIZ:+|KAS:ALA|MUG:MG|POS:POSbatera|POS:+
IZE	ARR	BIZ:+|KAS:ALA|NUM:P
IZE	ARR	BIZ:+|KAS:ALA|NUM:P|MUG:M
IZE	ARR	BIZ:+|KAS:ALA|NUM:S
IZE	ARR	BIZ:+|KAS:ALA|NUM:S|MUG:M
IZE	ARR	BIZ:+|KAS:ALA|NUM:S|MUG:M|POS:POSbatera|POS:+
IZE	ARR	BIZ:+|KAS:DAT
IZE	ARR	BIZ:+|KAS:DAT|MUG:MG
IZE	ARR	BIZ:+|KAS:DAT|NUM:P
IZE	ARR	BIZ:+|KAS:DAT|NUM:P|MUG:M
IZE	ARR	BIZ:+|KAS:DAT|NUM:S
IZE	ARR	BIZ:+|KAS:DAT|NUM:S|ENT:Tokia
IZE	ARR	BIZ:+|KAS:DAT|NUM:S|MUG:M
IZE	ARR	BIZ:+|KAS:DAT|NUM:S|MUG:M|ENT:Tokia
IZE	ARR	BIZ:+|KAS:DAT|NUM:S|MUG:M|MW:B
IZE	ARR	BIZ:+|KAS:DES
IZE	ARR	BIZ:+|KAS:DESK
IZE	ARR	BIZ:+|KAS:DES|MUG:MG
IZE	ARR	BIZ:+|KAS:DES|NUM:P
IZE	ARR	BIZ:+|KAS:DES|NUM:P|MUG:M
IZE	ARR	BIZ:+|KAS:DES|NUM:S
IZE	ARR	BIZ:+|KAS:DES|NUM:S|MUG:M
IZE	ARR	BIZ:+|KAS:DES|NUM:S|MUG:M|MW:B
IZE	ARR	BIZ:+|KAS:EM
IZE	ARR	BIZ:+|KAS:EM|MUG:MG|POS:POSgabe|POS:+
IZE	ARR	BIZ:+|KAS:EM|NUM:P
IZE	ARR	BIZ:+|KAS:EM|NUM:P|MUG:M|POS:POSarabera|POS:+
IZE	ARR	BIZ:+|KAS:EM|NUM:P|MUG:M|POS:POSbatera|POS:+
IZE	ARR	BIZ:+|KAS:EM|NUM:P|MUG:M|POS:POSbezala|POS:+
IZE	ARR	BIZ:+|KAS:EM|NUM:P|MUG:M|POS:POSburuz|POS:+
IZE	ARR	BIZ:+|KAS:EM|NUM:P|MUG:M|POS:POSkontra|POS:+
IZE	ARR	BIZ:+|KAS:EM|NUM:P|MUG:M|POS:POSondoan|POS:+
IZE	ARR	BIZ:+|KAS:EM|NUM:P|MUG:M|POS:POSordez|POS:+
IZE	ARR	BIZ:+|KAS:EM|NUM:S
IZE	ARR	BIZ:+|KAS:EM|NUM:S|MUG:M|POS:POSarabera|POS:+
IZE	ARR	BIZ:+|KAS:EM|NUM:S|MUG:M|POS:POSbezala|POS:+
IZE	ARR	BIZ:+|KAS:EM|NUM:S|MUG:M|POS:POSburuz|POS:+
IZE	ARR	BIZ:+|KAS:EM|POS:POSbezala|POS:+
IZE	ARR	BIZ:+|KAS:EM|POS:POSbila|POS:+
IZE	ARR	BIZ:+|KAS:ERG
IZE	ARR	BIZ:+|KAS:ERG|MUG:MG
IZE	ARR	BIZ:+|KAS:ERG|NUM:P
IZE	ARR	BIZ:+|KAS:ERG|NUM:PH|MUG:M
IZE	ARR	BIZ:+|KAS:ERG|NUM:P|MUG:M
IZE	ARR	BIZ:+|KAS:ERG|NUM:S
IZE	ARR	BIZ:+|KAS:ERG|NUM:S|ENT:Erakundea
IZE	ARR	BIZ:+|KAS:ERG|NUM:S|MUG:M
IZE	ARR	BIZ:+|KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:+|KAS:ERG|NUM:S|MUG:M|MW:B
IZE	ARR	BIZ:+|KAS:GEL
IZE	ARR	BIZ:+|KAS:GEL|NUM:P
IZE	ARR	BIZ:+|KAS:GEL|NUM:PH|MUG:M|POS:POSarteko|POS:+
IZE	ARR	BIZ:+|KAS:GEL|NUM:P|ENT:Erakundea
IZE	ARR	BIZ:+|KAS:GEL|NUM:P|MUG:M
IZE	ARR	BIZ:+|KAS:GEL|NUM:P|MUG:M|POS:POSarteko|POS:+
IZE	ARR	BIZ:+|KAS:GEL|NUM:P|MUG:M|POS:POSatzeko|POS:+
IZE	ARR	BIZ:+|KAS:GEL|NUM:P|MUG:M|POS:POSaurkako|POS:+
IZE	ARR	BIZ:+|KAS:GEL|NUM:P|MUG:M|POS:POSgabeko|POS:+|ENT:Erakundea
IZE	ARR	BIZ:+|KAS:GEL|NUM:S
IZE	ARR	BIZ:+|KAS:GEL|NUM:S|MUG:M
IZE	ARR	BIZ:+|KAS:GEL|NUM:S|MUG:M|POS:POSarteko|POS:+
IZE	ARR	BIZ:+|KAS:GEL|POS:POSinguruko|POS:+
IZE	ARR	BIZ:+|KAS:GEN
IZE	ARR	BIZ:+|KAS:GEN|MUG:MG
IZE	ARR	BIZ:+|KAS:GEN|NUM:P
IZE	ARR	BIZ:+|KAS:GEN|NUM:PH|MUG:M
IZE	ARR	BIZ:+|KAS:GEN|NUM:P|ENT:Pertsona
IZE	ARR	BIZ:+|KAS:GEN|NUM:P|MUG:M
IZE	ARR	BIZ:+|KAS:GEN|NUM:P|MUG:M|ENT:Pertsona
IZE	ARR	BIZ:+|KAS:GEN|NUM:S
IZE	ARR	BIZ:+|KAS:GEN|NUM:S|ENT:Pertsona
IZE	ARR	BIZ:+|KAS:GEN|NUM:S|MUG:M
IZE	ARR	BIZ:+|KAS:GEN|NUM:S|MUG:M|ENT:Pertsona
IZE	ARR	BIZ:+|KAS:GEN|NUM:S|MUG:M|MW:B
IZE	ARR	BIZ:+|KAS:INE
IZE	ARR	BIZ:+|KAS:INE|MUG:MG
IZE	ARR	BIZ:+|KAS:INE|NUM:P
IZE	ARR	BIZ:+|KAS:INE|NUM:P|MUG:M
IZE	ARR	BIZ:+|KAS:INE|NUM:P|MUG:M|POS:POSartean|POS:+
IZE	ARR	BIZ:+|KAS:INE|NUM:P|MUG:M|POS:POSaurrean|POS:+
IZE	ARR	BIZ:+|KAS:INE|NUM:P|MUG:M|POS:POSeskuetan|POS:+
IZE	ARR	BIZ:+|KAS:INE|NUM:P|MUG:M|POS:POSgainean|POS:+
IZE	ARR	BIZ:+|KAS:INE|NUM:P|MUG:M|POS:POSmendean|POS:+
IZE	ARR	BIZ:+|KAS:INE|NUM:P|MUG:M|POS:POSondoan|POS:+
IZE	ARR	BIZ:+|KAS:INE|NUM:S
IZE	ARR	BIZ:+|KAS:INE|NUM:S|MUG:M
IZE	ARR	BIZ:+|KAS:INE|NUM:S|MUG:M|POS:POSaurrean|POS:+
IZE	ARR	BIZ:+|KAS:INE|NUM:S|MUG:M|POS:POSinguruan|POS:+
IZE	ARR	BIZ:+|KAS:INS
IZE	ARR	BIZ:+|KAS:INS|MUG:MG
IZE	ARR	BIZ:+|KAS:INS|NUM:P
IZE	ARR	BIZ:+|KAS:INS|NUM:P|MUG:M
IZE	ARR	BIZ:+|KAS:INS|NUM:P|MUG:M|POS:POSbidez|POS:+
IZE	ARR	BIZ:+|KAS:INS|NUM:S
IZE	ARR	BIZ:+|KAS:INS|NUM:S|MUG:M
IZE	ARR	BIZ:+|KAS:INS|NUM:S|MUG:M|POS:POSbitartez|POS:+
IZE	ARR	BIZ:+|KAS:PAR
IZE	ARR	BIZ:+|KAS:PAR|MUG:MG
IZE	ARR	BIZ:+|KAS:PRO
IZE	ARR	BIZ:+|KAS:PRO|MUG:MG
IZE	ARR	BIZ:+|KAS:SOZ
IZE	ARR	BIZ:+|KAS:SOZ|MUG:MG
IZE	ARR	BIZ:+|KAS:SOZ|NUM:P
IZE	ARR	BIZ:+|KAS:SOZ|NUM:P|MUG:M
IZE	ARR	BIZ:+|KAS:SOZ|NUM:S
IZE	ARR	BIZ:+|KAS:SOZ|NUM:S|MUG:M
IZE	ARR	BIZ:+|KAS:SOZ|NUM:S|MUG:M|MW:B
IZE	ARR	BIZ:+|MW:B
IZE	ARR	BIZ:-
IZE	ARR	BIZ:-|ADM:ADIZE|KAS:EM|NUM:S
IZE	ARR	BIZ:-|ADM:ADIZE|KAS:EM|NUM:S|MUG:M|POS:POSburuz|POS:+
IZE	ARR	BIZ:-|ENT:Erakundea
IZE	ARR	BIZ:-|ENT:Pertsona
IZE	ARR	BIZ:-|ENT:Tokia
IZE	ARR	BIZ:-|IZAUR:-|KAS:ERG|MUG:MG|MW:B
IZE	ARR	BIZ:-|IZAUR:-|KAS:ERG|NUM:S|MUG:M|MW:B
IZE	ARR	BIZ:-|IZAUR:-|KAS:ERG|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ABL
IZE	ARR	BIZ:-|KAS:ABL|MUG:MG
IZE	ARR	BIZ:-|KAS:ABL|MUG:MG|POS:POSaldetik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|NUM:P
IZE	ARR	BIZ:-|KAS:ABL|NUM:PH|MUG:M
IZE	ARR	BIZ:-|KAS:ABL|NUM:P|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ABL|NUM:P|MUG:M
IZE	ARR	BIZ:-|KAS:ABL|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ABL|NUM:P|MUG:M|POS:POSaldetik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|NUM:P|MUG:M|POS:POSaurretik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|NUM:P|MUG:M|POS:POSgainetik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|NUM:S
IZE	ARR	BIZ:-|KAS:ABL|NUM:S|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ABL|NUM:S|ENT:Tokia
IZE	ARR	BIZ:-|KAS:ABL|NUM:S|MUG:M
IZE	ARR	BIZ:-|KAS:ABL|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ABL|NUM:S|MUG:M|ENT:Tokia
IZE	ARR	BIZ:-|KAS:ABL|NUM:S|MUG:M|POS:POSaldetik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|NUM:S|MUG:M|POS:POSaldetik|POS:+|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ABL|NUM:S|MUG:M|POS:POSatzetik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|NUM:S|MUG:M|POS:POSaurretik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|NUM:S|MUG:M|POS:POSazpitik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|NUM:S|MUG:M|POS:POSbarrutik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|NUM:S|MUG:M|POS:POSeskutik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|NUM:S|MUG:M|POS:POSgainetik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|POS:POSaldetik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|POS:POSaurretik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|POS:POSazpitik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|POS:POSbarruetatik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|POS:POSbarrutik|POS:+
IZE	ARR	BIZ:-|KAS:ABL|POS:POSondotik|POS:+
IZE	ARR	BIZ:-|KAS:ABS
IZE	ARR	BIZ:-|KAS:ABS|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ABS|MUG:MG
IZE	ARR	BIZ:-|KAS:ABS|MUG:MG|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ABS|MUG:MG|MW:B
IZE	ARR	BIZ:-|KAS:ABS|MUG:MG|POS:POSaurka|POS:+|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ABS|MUG:MG|POS:POSgain|POS:+
IZE	ARR	BIZ:-|KAS:ABS|MUG:MG|POS:POSkanpo|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:P
IZE	ARR	BIZ:-|KAS:ABS|NUM:PH|MUG:M
IZE	ARR	BIZ:-|KAS:ABS|NUM:P|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ABS|NUM:P|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:ABS|NUM:P|MUG:M
IZE	ARR	BIZ:-|KAS:ABS|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ABS|NUM:P|MUG:M|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:ABS|NUM:P|MUG:M|MW:B
IZE	ARR	BIZ:-|KAS:ABS|NUM:P|MUG:M|POS:POSalde|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:P|MUG:M|POS:POSaurka|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:P|MUG:M|POS:POSesker|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:P|MUG:M|POS:POSgain|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:P|MUG:M|POS:POSkanpo|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:P|MUG:M|POS:POStruke|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:S
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|ENT:???
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|ENT:Tokia
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|ENT:???
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|ENT:Tokia
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|MW:B
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|POS:POSalde|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|POS:POSantzekoa|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|POS:POSarte|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|POS:POSaurka|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|POS:POSbitarte|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|POS:POSesker|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|POS:POSesku|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|POS:POSgain|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|POS:POSkanpo|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|POS:POSlanda|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|POS:POSmenpe|POS:+
IZE	ARR	BIZ:-|KAS:ABS|NUM:S|MUG:M|POS:POStruke|POS:+
IZE	ARR	BIZ:-|KAS:ABS|POS:POSarte|POS:+
IZE	ARR	BIZ:-|KAS:ABS|POS:POSbarru|POS:+
IZE	ARR	BIZ:-|KAS:ABS|POS:POSbitarterako|POS:+
IZE	ARR	BIZ:-|KAS:ABS|POS:POSgisa|POS:+
IZE	ARR	BIZ:-|KAS:ABS|POS:POSinguru|POS:+
IZE	ARR	BIZ:-|KAS:ABU|NUM:S
IZE	ARR	BIZ:-|KAS:ABU|NUM:S|MUG:M
IZE	ARR	BIZ:-|KAS:ABZ|NUM:S
IZE	ARR	BIZ:-|KAS:ABZ|NUM:S|MUG:M
IZE	ARR	BIZ:-|KAS:ALA
IZE	ARR	BIZ:-|KAS:ALA|MUG:MG
IZE	ARR	BIZ:-|KAS:ALA|NUM:P
IZE	ARR	BIZ:-|KAS:ALA|NUM:P|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ALA|NUM:P|ENT:Tokia
IZE	ARR	BIZ:-|KAS:ALA|NUM:P|MUG:M
IZE	ARR	BIZ:-|KAS:ALA|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ALA|NUM:P|MUG:M|ENT:Tokia
IZE	ARR	BIZ:-|KAS:ALA|NUM:P|MUG:M|POS:POSaldera|POS:+
IZE	ARR	BIZ:-|KAS:ALA|NUM:P|MUG:M|POS:POSbatera|POS:+
IZE	ARR	BIZ:-|KAS:ALA|NUM:P|MUG:M|POS:POSbehera|POS:+
IZE	ARR	BIZ:-|KAS:ALA|NUM:P|MUG:M|POS:POSkanpora|POS:+
IZE	ARR	BIZ:-|KAS:ALA|NUM:S
IZE	ARR	BIZ:-|KAS:ALA|NUM:S|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ALA|NUM:S|ENT:Tokia
IZE	ARR	BIZ:-|KAS:ALA|NUM:S|MUG:M
IZE	ARR	BIZ:-|KAS:ALA|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ALA|NUM:S|MUG:M|ENT:Tokia
IZE	ARR	BIZ:-|KAS:ALA|NUM:S|MUG:M|MW:B
IZE	ARR	BIZ:-|KAS:ALA|NUM:S|MUG:M|POS:POSantzera|POS:+
IZE	ARR	BIZ:-|KAS:ALA|NUM:S|MUG:M|POS:POSaurrera|POS:+
IZE	ARR	BIZ:-|KAS:ALA|NUM:S|MUG:M|POS:POSbatera|POS:+
IZE	ARR	BIZ:-|KAS:ALA|NUM:S|MUG:M|POS:POSbehera|POS:+
IZE	ARR	BIZ:-|KAS:ALA|NUM:S|MUG:M|POS:POSerdira|POS:+
IZE	ARR	BIZ:-|KAS:ALA|NUM:S|MUG:M|POS:POSkanpora|POS:+
IZE	ARR	BIZ:-|KAS:ALA|POS:POSaldera|POS:+
IZE	ARR	BIZ:-|KAS:ALA|POS:POSaurrera|POS:+
IZE	ARR	BIZ:-|KAS:ALA|POS:POSbarnera|POS:+
IZE	ARR	BIZ:-|KAS:ALA|POS:POSbarrura|POS:+
IZE	ARR	BIZ:-|KAS:ALA|POS:POSerdira|POS:+
IZE	ARR	BIZ:-|KAS:ALA|POS:POSgainera|POS:+
IZE	ARR	BIZ:-|KAS:ALA|POS:POSinguruetara|POS:+
IZE	ARR	BIZ:-|KAS:ALA|POS:POSingurura|POS:+
IZE	ARR	BIZ:-|KAS:BNK|MUG:MG
IZE	ARR	BIZ:-|KAS:DAT
IZE	ARR	BIZ:-|KAS:DAT|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:DAT|MUG:MG
IZE	ARR	BIZ:-|KAS:DAT|MUG:MG|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:DAT|NUM:P
IZE	ARR	BIZ:-|KAS:DAT|NUM:P|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:DAT|NUM:P|MUG:M
IZE	ARR	BIZ:-|KAS:DAT|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:DAT|NUM:S
IZE	ARR	BIZ:-|KAS:DAT|NUM:S|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:DAT|NUM:S|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:DAT|NUM:S|MUG:M
IZE	ARR	BIZ:-|KAS:DAT|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:DAT|NUM:S|MUG:M|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:DESK
IZE	ARR	BIZ:-|KAS:DESK|MW:B
IZE	ARR	BIZ:-|KAS:DES|NUM:P
IZE	ARR	BIZ:-|KAS:DES|NUM:P|MUG:M
IZE	ARR	BIZ:-|KAS:DES|NUM:S
IZE	ARR	BIZ:-|KAS:DES|NUM:S|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:DES|NUM:S|MUG:M
IZE	ARR	BIZ:-|KAS:DES|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:EM
IZE	ARR	BIZ:-|KAS:EM|MUG:MG|POS:POSantzeko|POS:+
IZE	ARR	BIZ:-|KAS:EM|MUG:MG|POS:POSezean|POS:+
IZE	ARR	BIZ:-|KAS:EM|MUG:MG|POS:POSgabe|POS:+
IZE	ARR	BIZ:-|KAS:EM|MUG:MG|POS:POSgaineko|POS:+
IZE	ARR	BIZ:-|KAS:EM|MUG:MG|POS:POSgero|POS:+
IZE	ARR	BIZ:-|KAS:EM|MUG:MG|POS:POSondoren|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:P
IZE	ARR	BIZ:-|KAS:EM|NUM:P|MUG:M|POS:POSarabera|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:P|MUG:M|POS:POSbegira|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:P|MUG:M|POS:POSbezala|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:P|MUG:M|POS:POSburuz|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:P|MUG:M|POS:POSgaindi|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:P|MUG:M|POS:POShurrean|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:P|MUG:M|POS:POSkontra|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:P|MUG:M|POS:POSondoren|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:P|MUG:M|POS:POSordez|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:P|MUG:M|POS:POSurrun|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:P|MUG:M|POS:POSurruti|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:P|MUG:M|POS:POSzain|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S
IZE	ARR	BIZ:-|KAS:EM|NUM:S|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSaitzina|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSarabera|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSarabera|POS:+|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSat|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSaurrera|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSbarrena|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSbatera|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSbegira|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSbezala|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSbidez|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSbila|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSbitartean|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSburuz|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSgeroztik|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSgeroztik|POS:+|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSgertu|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSgorago|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSgora|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POShurbil|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSkontra|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSkontra|POS:+|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSondorengo|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSondoren|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSostean|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSzain|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSzai|POS:+
IZE	ARR	BIZ:-|KAS:EM|NUM:S|MUG:M|POS:POSzehar|POS:+
IZE	ARR	BIZ:-|KAS:EM|POS:POSbarik|POS:+
IZE	ARR	BIZ:-|KAS:EM|POS:POSbezalako|POS:+
IZE	ARR	BIZ:-|KAS:EM|POS:POSbezala|POS:+
IZE	ARR	BIZ:-|KAS:EM|POS:POSbidez|POS:+
IZE	ARR	BIZ:-|KAS:EM|POS:POSbila|POS:+
IZE	ARR	BIZ:-|KAS:EM|POS:POSeske|POS:+
IZE	ARR	BIZ:-|KAS:EM|POS:POSgabe|POS:+
IZE	ARR	BIZ:-|KAS:EM|POS:POSgora|POS:+
IZE	ARR	BIZ:-|KAS:EM|POS:POSondoan|POS:+
IZE	ARR	BIZ:-|KAS:EM|POS:POSondoren|POS:+
IZE	ARR	BIZ:-|KAS:EM|POS:POSostean|POS:+
IZE	ARR	BIZ:-|KAS:ERG
IZE	ARR	BIZ:-|KAS:ERG|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ERG|MUG:MG
IZE	ARR	BIZ:-|KAS:ERG|MUG:MG|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ERG|NUM:P
IZE	ARR	BIZ:-|KAS:ERG|NUM:PH|MUG:M
IZE	ARR	BIZ:-|KAS:ERG|NUM:P|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ERG|NUM:P|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:ERG|NUM:P|MUG:M
IZE	ARR	BIZ:-|KAS:ERG|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ERG|NUM:P|MUG:M|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:ERG|NUM:P|MUG:M|MW:B
IZE	ARR	BIZ:-|KAS:ERG|NUM:S
IZE	ARR	BIZ:-|KAS:ERG|NUM:S|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ERG|NUM:S|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:ERG|NUM:S|MUG:M
IZE	ARR	BIZ:-|KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:ERG|NUM:S|MUG:M|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:ERG|NUM:S|MUG:M|MW:B
IZE	ARR	BIZ:-|KAS:ERG|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEL
IZE	ARR	BIZ:-|KAS:GEL|MUG:MG
IZE	ARR	BIZ:-|KAS:GEL|MUG:MG|POS:POSgabeko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|MUG:MG|POS:POSinguruko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:P
IZE	ARR	BIZ:-|KAS:GEL|NUM:PH|MUG:M
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|MUG:M
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|MUG:M|MW:B
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|MUG:M|POS:POSaldeko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|MUG:M|POS:POSaldeko|POS:+|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|MUG:M|POS:POSantzeko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|MUG:M|POS:POSaraberako|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|MUG:M|POS:POSarteko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|MUG:M|POS:POSaurkako|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|MUG:M|POS:POSbitarteko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|MUG:M|POS:POSburuzko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|MUG:M|POS:POSgaineko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|MUG:M|POS:POSgaineko|POS:+|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|MUG:M|POS:POSinguruko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:P|MUG:M|POS:POSkontrako|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:S
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|ENT:Tokia
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|ENT:Tokia
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|MW:B
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSaldeko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSaldeko|POS:+|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSarteko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSarteko|POS:+|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSatzeko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSaurkako|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSaurkako|POS:+|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSburuzko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSburuzko|POS:+|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSburuzko|POS:+|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSgaindiko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSgaineko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSgorako|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSinguruko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSkanpoko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|NUM:S|MUG:M|POS:POSkontrako|POS:+
IZE	ARR	BIZ:-|KAS:GEL|POS:POSaitzineko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|POS:POSaldeko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|POS:POSantzeko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|POS:POSarteko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|POS:POSaurreko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|POS:POSbarruko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|POS:POSerdiko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|POS:POSgabeko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|POS:POSgaineko|POS:+
IZE	ARR	BIZ:-|KAS:GEL|POS:POSinguruko|POS:+
IZE	ARR	BIZ:-|KAS:GEN
IZE	ARR	BIZ:-|KAS:GEN|MUG:MG
IZE	ARR	BIZ:-|KAS:GEN|NUM:P
IZE	ARR	BIZ:-|KAS:GEN|NUM:PH|MUG:M
IZE	ARR	BIZ:-|KAS:GEN|NUM:P|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEN|NUM:P|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:GEN|NUM:P|MUG:M
IZE	ARR	BIZ:-|KAS:GEN|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEN|NUM:P|MUG:M|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:GEN|NUM:P|MUG:M|MW:B
IZE	ARR	BIZ:-|KAS:GEN|NUM:P|MUG:M|MW:B|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEN|NUM:S
IZE	ARR	BIZ:-|KAS:GEN|NUM:S|ENT:???
IZE	ARR	BIZ:-|KAS:GEN|NUM:S|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEN|NUM:S|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:GEN|NUM:S|ENT:Tokia
IZE	ARR	BIZ:-|KAS:GEN|NUM:S|MUG:M
IZE	ARR	BIZ:-|KAS:GEN|NUM:S|MUG:M|ENT:???
IZE	ARR	BIZ:-|KAS:GEN|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:GEN|NUM:S|MUG:M|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:GEN|NUM:S|MUG:M|ENT:Tokia
IZE	ARR	BIZ:-|KAS:GEN|NUM:S|MUG:M|POS:POSgorakoen|POS:+
IZE	ARR	BIZ:-|KAS:INE
IZE	ARR	BIZ:-|KAS:INE|MUG:MG
IZE	ARR	BIZ:-|KAS:INE|MUG:MG|POS:POSartean|POS:+
IZE	ARR	BIZ:-|KAS:INE|MUG:MG|POS:POSaurrean|POS:+
IZE	ARR	BIZ:-|KAS:INE|MUG:MG|POS:POSazpian|POS:+
IZE	ARR	BIZ:-|KAS:INE|MUG:MG|POS:POSburuan|POS:+
IZE	ARR	BIZ:-|KAS:INE|MUG:MG|POS:POSinguruan|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:P
IZE	ARR	BIZ:-|KAS:INE|NUM:PH|MUG:M
IZE	ARR	BIZ:-|KAS:INE|NUM:P|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:INE|NUM:P|ENT:Tokia
IZE	ARR	BIZ:-|KAS:INE|NUM:P|MUG:M
IZE	ARR	BIZ:-|KAS:INE|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:INE|NUM:P|MUG:M|ENT:Tokia
IZE	ARR	BIZ:-|KAS:INE|NUM:P|MUG:M|MW:B
IZE	ARR	BIZ:-|KAS:INE|NUM:P|MUG:M|POS:POSaitzinean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:P|MUG:M|POS:POSartean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:P|MUG:M|POS:POSatzean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:P|MUG:M|POS:POSaurrean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:P|MUG:M|POS:POSazpian|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:P|MUG:M|POS:POSbarruan|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:P|MUG:M|POS:POSbitartean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:P|MUG:M|POS:POSgainean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:P|MUG:M|POS:POSinguruan|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:P|MUG:M|POS:POSondoan|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S
IZE	ARR	BIZ:-|KAS:INE|NUM:S|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:INE|NUM:S|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:INE|NUM:S|ENT:Tokia
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|ENT:Pertsona
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|ENT:Tokia
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|MW:B
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSaitzinean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSalboan|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSaldean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSatzean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSaurrean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSazpian|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSbaitan|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSbarnean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSbarrenean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSbarruan|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSbestaldean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSbitartean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSerdian|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSeskuetan|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSgainean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSinguruan|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSingurua|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSmoduan|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSondoan|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSostean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSparean|POS:+
IZE	ARR	BIZ:-|KAS:INE|NUM:S|MUG:M|POS:POSparean|POS:+|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:INE|POS:POSaldean|POS:+
IZE	ARR	BIZ:-|KAS:INE|POS:POSartean|POS:+
IZE	ARR	BIZ:-|KAS:INE|POS:POSatzean|POS:+
IZE	ARR	BIZ:-|KAS:INE|POS:POSaurrean|POS:+
IZE	ARR	BIZ:-|KAS:INE|POS:POSbarnean|POS:+
IZE	ARR	BIZ:-|KAS:INE|POS:POSbarruan|POS:+
IZE	ARR	BIZ:-|KAS:INE|POS:POSbitartean|POS:+
IZE	ARR	BIZ:-|KAS:INE|POS:POSerdian|POS:+
IZE	ARR	BIZ:-|KAS:INE|POS:POSerditan|POS:+
IZE	ARR	BIZ:-|KAS:INE|POS:POSgainean|POS:+
IZE	ARR	BIZ:-|KAS:INE|POS:POSinguruan|POS:+
IZE	ARR	BIZ:-|KAS:INE|POS:POSondoan|POS:+
IZE	ARR	BIZ:-|KAS:INE|POS:POSostean|POS:+
IZE	ARR	BIZ:-|KAS:INE|POS:POSpartean|POS:+
IZE	ARR	BIZ:-|KAS:INS
IZE	ARR	BIZ:-|KAS:INS|MUG:MG
IZE	ARR	BIZ:-|KAS:INS|MUG:MG|MW:B
IZE	ARR	BIZ:-|KAS:INS|NUM:P
IZE	ARR	BIZ:-|KAS:INS|NUM:P|MUG:M
IZE	ARR	BIZ:-|KAS:INS|NUM:P|MUG:M|POS:POSbidez|POS:+
IZE	ARR	BIZ:-|KAS:INS|NUM:P|MUG:M|POS:POSbitartez|POS:+
IZE	ARR	BIZ:-|KAS:INS|NUM:S
IZE	ARR	BIZ:-|KAS:INS|NUM:S|MUG:M
IZE	ARR	BIZ:-|KAS:INS|NUM:S|MUG:M|POS:POSbidez|POS:+
IZE	ARR	BIZ:-|KAS:INS|NUM:S|MUG:M|POS:POSbitartez|POS:+
IZE	ARR	BIZ:-|KAS:INS|POS:POSaldeaz|POS:+
IZE	ARR	BIZ:-|KAS:INS|POS:POSbidez|POS:+
IZE	ARR	BIZ:-|KAS:MOT
IZE	ARR	BIZ:-|KAS:MOT|NUM:P
IZE	ARR	BIZ:-|KAS:MOT|NUM:P|MUG:M
IZE	ARR	BIZ:-|KAS:MOT|NUM:S
IZE	ARR	BIZ:-|KAS:MOT|NUM:S|MUG:M
IZE	ARR	BIZ:-|KAS:PAR
IZE	ARR	BIZ:-|KAS:PAR|MUG:MG
IZE	ARR	BIZ:-|KAS:PRO
IZE	ARR	BIZ:-|KAS:PRO|ENT:???
IZE	ARR	BIZ:-|KAS:PRO|MUG:MG
IZE	ARR	BIZ:-|KAS:PRO|MUG:MG|ENT:???
IZE	ARR	BIZ:-|KAS:SOZ
IZE	ARR	BIZ:-|KAS:SOZ|MUG:MG
IZE	ARR	BIZ:-|KAS:SOZ|NUM:P
IZE	ARR	BIZ:-|KAS:SOZ|NUM:P|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:SOZ|NUM:P|MUG:M
IZE	ARR	BIZ:-|KAS:SOZ|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:SOZ|NUM:S
IZE	ARR	BIZ:-|KAS:SOZ|NUM:S|ENT:Erakundea
IZE	ARR	BIZ:-|KAS:SOZ|NUM:S|MUG:M
IZE	ARR	BIZ:-|KAS:SOZ|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|MAI:KONP|KAS:ABS
IZE	ARR	BIZ:-|MAI:KONP|KAS:ABS|MUG:MG
IZE	ARR	BIZ:-|MAI:KONP|KAS:ABS|NUM:S
IZE	ARR	BIZ:-|MAI:KONP|KAS:ABS|NUM:S|MUG:M
IZE	ARR	BIZ:-|MAI:KONP|KAS:ALA|NUM:S
IZE	ARR	BIZ:-|MAI:KONP|KAS:ALA|NUM:S|MUG:M
IZE	ARR	BIZ:-|MTKAT:SNB
IZE	ARR	BIZ:-|MTKAT:SNB|KAS:ABS|NUM:S|MUG:M
IZE	ARR	BIZ:-|MW:B
IZE	ARR	BIZ:-|MW:B|ENT:Erakundea
IZE	ARR	BIZ:-|PLU:-
IZE	ARR	BIZ:-|PLU:-|KAS:ABS|NUM:P|MUG:M
IZE	ARR	BIZ:-|PLU:-|KAS:ABS|NUM:S|MUG:M
IZE	ARR	BIZ:-|PLU:-|KAS:INE|NUM:S|MUG:M
IZE	ARR	BIZ:-|PLU:-|KAS:INE|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	BIZ:-|ZENB:-|NEUR:-|PLU:-
IZE	ARR	BIZ:-|ZENB:-|NEUR:-|PLU:-|KAS:ABS|NUM:P|MUG:M
IZE	ARR	BIZ:-|ZENB:-|NEUR:-|PLU:-|KAS:ABS|NUM:S|MUG:M
IZE	ARR	BIZ:-|ZENB:-|NEUR:-|PLU:-|KAS:ALA|NUM:S|MUG:M
IZE	ARR	BIZ:-|ZENB:-|NEUR:-|PLU:-|KAS:DAT|NUM:P|MUG:M
IZE	ARR	BIZ:-|ZENB:-|NEUR:-|PLU:-|KAS:ERG|NUM:P|MUG:M
IZE	ARR	BIZ:-|ZENB:-|NEUR:-|PLU:-|KAS:ERG|NUM:S|MUG:M
IZE	ARR	BIZ:-|ZENB:-|NEUR:-|PLU:-|KAS:GEL|NUM:P|MUG:M|POS:POSburuzko|POS:+
IZE	ARR	BIZ:-|ZENB:-|NEUR:-|PLU:-|KAS:GEN|NUM:P|MUG:M
IZE	ARR	BIZ:-|ZENB:-|NEUR:-|PLU:-|KAS:INE|NUM:P|MUG:M
IZE	ARR	BIZ:-|ZENB:-|NEUR:-|PLU:-|KAS:INE|NUM:S|MUG:M
IZE	ARR	BIZ:-|ZENB:-|NEUR:-|PLU:-|KAS:SOZ|NUM:P|MUG:M
IZE	ARR	ENT:Erakundea
IZE	ARR	ENT:Pertsona
IZE	ARR	ENT:Tokia
IZE	ARR	IZAUR:-
IZE	ARR	IZAUR:-|KAS:ABS|NUM:P|MUG:M|MW:B
IZE	ARR	IZAUR:-|KAS:ABS|NUM:S|MUG:M
IZE	ARR	IZAUR:-|KAS:ABS|NUM:S|MUG:M|MW:B
IZE	ARR	IZAUR:-|KAS:ERG|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	IZAUR:-|KAS:ERG|NUM:S|MUG:M|MW:B
IZE	ARR	IZAUR:-|KAS:GEL|NUM:S|MUG:M|MW:B
IZE	ARR	IZAUR:-|KAS:GEL|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	ARR	IZAUR:-|KAS:GEN|NUM:P|MUG:M|MW:B
IZE	ARR	IZAUR:-|KAS:GEN|NUM:S|MUG:M|ENT:Pertsona
IZE	ARR	IZAUR:-|KAS:GEN|NUM:S|MUG:M|MW:B
IZE	ARR	IZAUR:-|KAS:GEN|NUM:S|MUG:M|MW:B|ENT:Pertsona
IZE	ARR	IZAUR:-|KAS:INE|NUM:P|MUG:M|MW:B
IZE	ARR	IZAUR:-|KAS:INE|NUM:S|MUG:M|MW:B
IZE	ARR	IZAUR:-|KAS:PAR|MUG:MG|MW:B
IZE	ARR	IZAUR:-|KAS:PRO|MUG:MG|MW:B
IZE	ARR	IZAUR:-|MW:B
IZE	ARR	KAS:ABL
IZE	ARR	KAS:ABL|MUG:MG
IZE	ARR	KAS:ABL|MUG:MG|POS:POSgainetik|POS:+
IZE	ARR	KAS:ABL|NUM:P
IZE	ARR	KAS:ABL|NUM:P|ENT:Erakundea
IZE	ARR	KAS:ABL|NUM:P|ENT:Pertsona
IZE	ARR	KAS:ABL|NUM:P|MUG:M
IZE	ARR	KAS:ABL|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	KAS:ABL|NUM:P|MUG:M|POS:POSatzetik|POS:+
IZE	ARR	KAS:ABL|NUM:P|MUG:M|POS:POSaurretik|POS:+
IZE	ARR	KAS:ABL|NUM:P|MUG:M|POS:POSeskutik|POS:+
IZE	ARR	KAS:ABL|NUM:P|MUG:M|POS:POSgainetik|POS:+
IZE	ARR	KAS:ABL|NUM:S
IZE	ARR	KAS:ABL|NUM:S|ENT:Erakundea
IZE	ARR	KAS:ABL|NUM:S|ENT:Pertsona
IZE	ARR	KAS:ABL|NUM:S|ENT:Tokia
IZE	ARR	KAS:ABL|NUM:S|MUG:M
IZE	ARR	KAS:ABL|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	KAS:ABL|NUM:S|MUG:M|ENT:Pertsona
IZE	ARR	KAS:ABL|NUM:S|MUG:M|ENT:Tokia
IZE	ARR	KAS:ABL|NUM:S|MUG:M|POS:POSaurretik|POS:+
IZE	ARR	KAS:ABL|NUM:S|MUG:M|POS:POSazpitik|POS:+
IZE	ARR	KAS:ABL|NUM:S|MUG:M|POS:POSeskutik|POS:+
IZE	ARR	KAS:ABL|NUM:S|MUG:M|POS:POSgainetik|POS:+
IZE	ARR	KAS:ABL|NUM:S|MUG:M|POS:POSondotik|POS:+
IZE	ARR	KAS:ABL|POS:POSaldetik|POS:+
IZE	ARR	KAS:ABS
IZE	ARR	KAS:ABS|ENT:Erakundea
IZE	ARR	KAS:ABS|ENT:Pertsona
IZE	ARR	KAS:ABS|MUG:MG
IZE	ARR	KAS:ABS|MUG:MG|ENT:Erakundea
IZE	ARR	KAS:ABS|MUG:MG|ENT:Pertsona
IZE	ARR	KAS:ABS|MUG:MG|MW:B
IZE	ARR	KAS:ABS|MUG:MG|POS:POSaurka|POS:+
IZE	ARR	KAS:ABS|MUG:MG|POS:POSkanpo|POS:+
IZE	ARR	KAS:ABS|MUG:MG|POS:POStruke|POS:+
IZE	ARR	KAS:ABS|NUM:P
IZE	ARR	KAS:ABS|NUM:PH|MUG:M
IZE	ARR	KAS:ABS|NUM:P|ENT:???
IZE	ARR	KAS:ABS|NUM:P|ENT:Erakundea
IZE	ARR	KAS:ABS|NUM:P|ENT:Tokia
IZE	ARR	KAS:ABS|NUM:P|MUG:M
IZE	ARR	KAS:ABS|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	KAS:ABS|NUM:P|MUG:M|MW:B
IZE	ARR	KAS:ABS|NUM:P|MUG:M|POS:POSalde|POS:+
IZE	ARR	KAS:ABS|NUM:P|MUG:M|POS:POSaurka|POS:+
IZE	ARR	KAS:ABS|NUM:P|MUG:M|POS:POSbitarteko|POS:+
IZE	ARR	KAS:ABS|NUM:P|MUG:M|POS:POSesker|POS:+
IZE	ARR	KAS:ABS|NUM:P|MUG:M|POS:POSgain|POS:+
IZE	ARR	KAS:ABS|NUM:S
IZE	ARR	KAS:ABS|NUM:S|ENT:???
IZE	ARR	KAS:ABS|NUM:S|ENT:Erakundea
IZE	ARR	KAS:ABS|NUM:S|ENT:Pertsona
IZE	ARR	KAS:ABS|NUM:S|ENT:Tokia
IZE	ARR	KAS:ABS|NUM:S|MUG:M
IZE	ARR	KAS:ABS|NUM:S|MUG:M|ENT:???
IZE	ARR	KAS:ABS|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	KAS:ABS|NUM:S|MUG:M|ENT:Pertsona
IZE	ARR	KAS:ABS|NUM:S|MUG:M|ENT:Tokia
IZE	ARR	KAS:ABS|NUM:S|MUG:M|MW:B
IZE	ARR	KAS:ABS|NUM:S|MUG:M|POS:POSalde|POS:+
IZE	ARR	KAS:ABS|NUM:S|MUG:M|POS:POSarte|POS:+
IZE	ARR	KAS:ABS|NUM:S|MUG:M|POS:POSaurka|POS:+
IZE	ARR	KAS:ABS|NUM:S|MUG:M|POS:POSaurka|POS:+|ENT:Erakundea
IZE	ARR	KAS:ABS|NUM:S|MUG:M|POS:POSesker|POS:+
IZE	ARR	KAS:ABS|NUM:S|MUG:M|POS:POSgain|POS:+
IZE	ARR	KAS:ABS|NUM:S|MUG:M|POS:POSkanpo|POS:+
IZE	ARR	KAS:ABS|NUM:S|MUG:M|POS:POSlanda|POS:+
IZE	ARR	KAS:ABS|NUM:S|MUG:M|POS:POSmenpe|POS:+
IZE	ARR	KAS:ABS|POS:POSarte|POS:+
IZE	ARR	KAS:ABS|POS:POSbarru|POS:+
IZE	ARR	KAS:ABS|POS:POSgisa|POS:+
IZE	ARR	KAS:ABS|POS:POSgisa|POS:+|MW:B
IZE	ARR	KAS:ABS|POS:POSingururako|POS:+
IZE	ARR	KAS:ABS|POS:POSinguru|POS:+
IZE	ARR	KAS:ABU|NUM:P
IZE	ARR	KAS:ABU|NUM:P|MUG:M
IZE	ARR	KAS:ABU|NUM:S
IZE	ARR	KAS:ABU|NUM:S|MUG:M
IZE	ARR	KAS:ABZ|NUM:S
IZE	ARR	KAS:ABZ|NUM:S|MUG:M
IZE	ARR	KAS:ALA
IZE	ARR	KAS:ALA|MUG:MG
IZE	ARR	KAS:ALA|MUG:MG|POS:POSingurura|POS:+
IZE	ARR	KAS:ALA|NUM:P
IZE	ARR	KAS:ALA|NUM:P|MUG:M
IZE	ARR	KAS:ALA|NUM:P|MUG:M|MW:B
IZE	ARR	KAS:ALA|NUM:P|MUG:M|POS:POSaurrera|POS:+
IZE	ARR	KAS:ALA|NUM:P|MUG:M|POS:POSbatera|POS:+
IZE	ARR	KAS:ALA|NUM:P|MUG:M|POS:POSlandara|POS:+
IZE	ARR	KAS:ALA|NUM:S
IZE	ARR	KAS:ALA|NUM:S|ENT:Erakundea
IZE	ARR	KAS:ALA|NUM:S|ENT:Tokia
IZE	ARR	KAS:ALA|NUM:S|MUG:M
IZE	ARR	KAS:ALA|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	KAS:ALA|NUM:S|MUG:M|ENT:Tokia
IZE	ARR	KAS:ALA|NUM:S|MUG:M|POS:POSaldera|POS:+
IZE	ARR	KAS:ALA|NUM:S|MUG:M|POS:POSbatera|POS:+
IZE	ARR	KAS:ALA|NUM:S|MUG:M|POS:POSbehera|POS:+
IZE	ARR	KAS:ALA|NUM:S|MUG:M|POS:POSgainera|POS:+
IZE	ARR	KAS:ALA|NUM:S|MUG:M|POS:POSlandara|POS:+
IZE	ARR	KAS:ALA|POS:POSaldera|POS:+
IZE	ARR	KAS:ALA|POS:POSaurrera|POS:+
IZE	ARR	KAS:ALA|POS:POSerdira|POS:+
IZE	ARR	KAS:BNK|MUG:MG
IZE	ARR	KAS:DAT
IZE	ARR	KAS:DAT|ENT:Pertsona
IZE	ARR	KAS:DAT|MUG:MG
IZE	ARR	KAS:DAT|MUG:MG|ENT:Pertsona
IZE	ARR	KAS:DAT|NUM:P
IZE	ARR	KAS:DAT|NUM:PH|MUG:M
IZE	ARR	KAS:DAT|NUM:P|ENT:Erakundea
IZE	ARR	KAS:DAT|NUM:P|MUG:M
IZE	ARR	KAS:DAT|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	KAS:DAT|NUM:S
IZE	ARR	KAS:DAT|NUM:S|ENT:Erakundea
IZE	ARR	KAS:DAT|NUM:S|ENT:Pertsona
IZE	ARR	KAS:DAT|NUM:S|ENT:Tokia
IZE	ARR	KAS:DAT|NUM:S|MUG:M
IZE	ARR	KAS:DAT|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	KAS:DAT|NUM:S|MUG:M|ENT:Pertsona
IZE	ARR	KAS:DAT|NUM:S|MUG:M|ENT:Tokia
IZE	ARR	KAS:DES
IZE	ARR	KAS:DESK
IZE	ARR	KAS:DES|MUG:MG
IZE	ARR	KAS:DES|NUM:P
IZE	ARR	KAS:DES|NUM:PH|MUG:M
IZE	ARR	KAS:DES|NUM:P|MUG:M
IZE	ARR	KAS:DES|NUM:S
IZE	ARR	KAS:DES|NUM:S|MUG:M
IZE	ARR	KAS:EM
IZE	ARR	KAS:EM|MUG:MG|POS:POSbezala|POS:+
IZE	ARR	KAS:EM|MUG:MG|POS:POSezean|POS:+
IZE	ARR	KAS:EM|MUG:MG|POS:POSgabe|POS:+
IZE	ARR	KAS:EM|MUG:MG|POS:POSgeroztik|POS:+
IZE	ARR	KAS:EM|MUG:MG|POS:POSondoren|POS:+
IZE	ARR	KAS:EM|NUM:P
IZE	ARR	KAS:EM|NUM:P|MUG:M|POS:POSaldetik|POS:+
IZE	ARR	KAS:EM|NUM:P|MUG:M|POS:POSarabera|POS:+
IZE	ARR	KAS:EM|NUM:P|MUG:M|POS:POSat|POS:+
IZE	ARR	KAS:EM|NUM:P|MUG:M|POS:POSbegira|POS:+
IZE	ARR	KAS:EM|NUM:P|MUG:M|POS:POSbezalako|POS:+
IZE	ARR	KAS:EM|NUM:P|MUG:M|POS:POSbezala|POS:+
IZE	ARR	KAS:EM|NUM:P|MUG:M|POS:POSburuz|POS:+
IZE	ARR	KAS:EM|NUM:P|MUG:M|POS:POSgora|POS:+
IZE	ARR	KAS:EM|NUM:P|MUG:M|POS:POSkontra|POS:+
IZE	ARR	KAS:EM|NUM:P|MUG:M|POS:POSondoren|POS:+
IZE	ARR	KAS:EM|NUM:P|MUG:M|POS:POSzehar|POS:+
IZE	ARR	KAS:EM|NUM:S
IZE	ARR	KAS:EM|NUM:S|ENT:Erakundea
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSarabera|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSarabera|POS:+|ENT:Erakundea
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSat|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSaurrera|POS:+|ENT:Erakundea
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSbegira|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSbezalako|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSbezala|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSbidez|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSbila|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSburuz|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSgeroztik|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSgertu|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSgora|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POShurbil|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSkontra|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSondoko|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSondoren|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSzain|POS:+
IZE	ARR	KAS:EM|NUM:S|MUG:M|POS:POSzehar|POS:+
IZE	ARR	KAS:EM|POS:POSantzeko|POS:+
IZE	ARR	KAS:EM|POS:POSbezala|POS:+
IZE	ARR	KAS:EM|POS:POSbila|POS:+
IZE	ARR	KAS:EM|POS:POSgabe|POS:+
IZE	ARR	KAS:ERG
IZE	ARR	KAS:ERG|ENT:Erakundea
IZE	ARR	KAS:ERG|ENT:Pertsona
IZE	ARR	KAS:ERG|MUG:MG
IZE	ARR	KAS:ERG|MUG:MG|ENT:Erakundea
IZE	ARR	KAS:ERG|MUG:MG|ENT:Pertsona
IZE	ARR	KAS:ERG|NUM:P
IZE	ARR	KAS:ERG|NUM:PH|MUG:M
IZE	ARR	KAS:ERG|NUM:P|ENT:Erakundea
IZE	ARR	KAS:ERG|NUM:P|ENT:Pertsona
IZE	ARR	KAS:ERG|NUM:P|MUG:M
IZE	ARR	KAS:ERG|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	KAS:ERG|NUM:P|MUG:M|ENT:Pertsona
IZE	ARR	KAS:ERG|NUM:P|MUG:M|MW:B
IZE	ARR	KAS:ERG|NUM:S
IZE	ARR	KAS:ERG|NUM:S|ENT:Erakundea
IZE	ARR	KAS:ERG|NUM:S|ENT:Pertsona
IZE	ARR	KAS:ERG|NUM:S|MUG:M
IZE	ARR	KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	KAS:ERG|NUM:S|MUG:M|ENT:Pertsona
IZE	ARR	KAS:GEL
IZE	ARR	KAS:GEL|ENT:Erakundea
IZE	ARR	KAS:GEL|MUG:MG
IZE	ARR	KAS:GEL|MUG:MG|ENT:Erakundea
IZE	ARR	KAS:GEL|MUG:MG|POS:POSaurkako|POS:+
IZE	ARR	KAS:GEL|MUG:MG|POS:POSgabeko|POS:+
IZE	ARR	KAS:GEL|MUG:MG|POS:POSkanpoko|POS:+
IZE	ARR	KAS:GEL|MUG:MG|POS:POSkontrako|POS:+
IZE	ARR	KAS:GEL|NUM:P
IZE	ARR	KAS:GEL|NUM:PH|MUG:M
IZE	ARR	KAS:GEL|NUM:P|ENT:Erakundea
IZE	ARR	KAS:GEL|NUM:P|MUG:M
IZE	ARR	KAS:GEL|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	KAS:GEL|NUM:P|MUG:M|POS:POSaldeko|POS:+
IZE	ARR	KAS:GEL|NUM:P|MUG:M|POS:POSarteko|POS:+
IZE	ARR	KAS:GEL|NUM:P|MUG:M|POS:POSaurkako|POS:+
IZE	ARR	KAS:GEL|NUM:P|MUG:M|POS:POSburuzko|POS:+
IZE	ARR	KAS:GEL|NUM:P|MUG:M|POS:POSgaineko|POS:+
IZE	ARR	KAS:GEL|NUM:P|MUG:M|POS:POSinguruko|POS:+
IZE	ARR	KAS:GEL|NUM:P|MUG:M|POS:POSkanpoko|POS:+
IZE	ARR	KAS:GEL|NUM:P|MUG:M|POS:POSkontrako|POS:+
IZE	ARR	KAS:GEL|NUM:S
IZE	ARR	KAS:GEL|NUM:S|ENT:Erakundea
IZE	ARR	KAS:GEL|NUM:S|ENT:Pertsona
IZE	ARR	KAS:GEL|NUM:S|ENT:Tokia
IZE	ARR	KAS:GEL|NUM:S|MUG:M
IZE	ARR	KAS:GEL|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	KAS:GEL|NUM:S|MUG:M|ENT:Pertsona
IZE	ARR	KAS:GEL|NUM:S|MUG:M|ENT:Tokia
IZE	ARR	KAS:GEL|NUM:S|MUG:M|POS:POSaldeko|POS:+
IZE	ARR	KAS:GEL|NUM:S|MUG:M|POS:POSarteko|POS:+|ENT:Erakundea
IZE	ARR	KAS:GEL|NUM:S|MUG:M|POS:POSaurkako|POS:+
IZE	ARR	KAS:GEL|NUM:S|MUG:M|POS:POSaurkako|POS:+|ENT:Erakundea
IZE	ARR	KAS:GEL|NUM:S|MUG:M|POS:POSaurreko|POS:+
IZE	ARR	KAS:GEL|NUM:S|MUG:M|POS:POSburuzko|POS:+
IZE	ARR	KAS:GEL|NUM:S|MUG:M|POS:POSgorako|POS:+
IZE	ARR	KAS:GEL|NUM:S|MUG:M|POS:POSinguruko|POS:+
IZE	ARR	KAS:GEL|NUM:S|MUG:M|POS:POSkontrako|POS:+
IZE	ARR	KAS:GEL|NUM:S|MUG:M|POS:POSkontrako|POS:+|ENT:Erakundea
IZE	ARR	KAS:GEL|POS:POSaitzineko|POS:+
IZE	ARR	KAS:GEL|POS:POSarteko|POS:+
IZE	ARR	KAS:GEL|POS:POSaurreko|POS:+
IZE	ARR	KAS:GEL|POS:POSinguruetako|POS:+
IZE	ARR	KAS:GEL|POS:POSosteko|POS:+
IZE	ARR	KAS:GEN
IZE	ARR	KAS:GEN|MUG:MG
IZE	ARR	KAS:GEN|NUM:P
IZE	ARR	KAS:GEN|NUM:PH|MUG:M
IZE	ARR	KAS:GEN|NUM:P|ENT:Erakundea
IZE	ARR	KAS:GEN|NUM:P|MUG:M
IZE	ARR	KAS:GEN|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	KAS:GEN|NUM:P|MUG:M|MW:B
IZE	ARR	KAS:GEN|NUM:S
IZE	ARR	KAS:GEN|NUM:S|ENT:???
IZE	ARR	KAS:GEN|NUM:S|ENT:Erakundea
IZE	ARR	KAS:GEN|NUM:S|ENT:Pertsona
IZE	ARR	KAS:GEN|NUM:S|ENT:Tokia
IZE	ARR	KAS:GEN|NUM:S|MUG:M
IZE	ARR	KAS:GEN|NUM:S|MUG:M|ENT:???
IZE	ARR	KAS:GEN|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	KAS:GEN|NUM:S|MUG:M|ENT:Pertsona
IZE	ARR	KAS:GEN|NUM:S|MUG:M|ENT:Tokia
IZE	ARR	KAS:INE
IZE	ARR	KAS:INE|MUG:MG
IZE	ARR	KAS:INE|MUG:MG|POS:POSaurrean|POS:+
IZE	ARR	KAS:INE|MUG:MG|POS:POSbarnean|POS:+
IZE	ARR	KAS:INE|NUM:P
IZE	ARR	KAS:INE|NUM:PH|MUG:M
IZE	ARR	KAS:INE|NUM:P|ENT:Erakundea
IZE	ARR	KAS:INE|NUM:P|ENT:Tokia
IZE	ARR	KAS:INE|NUM:P|MUG:M
IZE	ARR	KAS:INE|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	KAS:INE|NUM:P|MUG:M|ENT:Tokia
IZE	ARR	KAS:INE|NUM:P|MUG:M|POS:POSartean|POS:+
IZE	ARR	KAS:INE|NUM:P|MUG:M|POS:POSaurrean|POS:+
IZE	ARR	KAS:INE|NUM:P|MUG:M|POS:POSbarruan|POS:+
IZE	ARR	KAS:INE|NUM:P|MUG:M|POS:POSeskuetan|POS:+
IZE	ARR	KAS:INE|NUM:P|MUG:M|POS:POSgainean|POS:+
IZE	ARR	KAS:INE|NUM:P|MUG:M|POS:POSinguruan|POS:+
IZE	ARR	KAS:INE|NUM:P|MUG:M|POS:POSondoan|POS:+
IZE	ARR	KAS:INE|NUM:P|MUG:M|POS:POSostean|POS:+
IZE	ARR	KAS:INE|NUM:S
IZE	ARR	KAS:INE|NUM:S|ENT:???
IZE	ARR	KAS:INE|NUM:S|ENT:Erakundea
IZE	ARR	KAS:INE|NUM:S|ENT:Pertsona
IZE	ARR	KAS:INE|NUM:S|ENT:Tokia
IZE	ARR	KAS:INE|NUM:S|MUG:M
IZE	ARR	KAS:INE|NUM:S|MUG:M|ENT:???
IZE	ARR	KAS:INE|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	KAS:INE|NUM:S|MUG:M|ENT:Pertsona
IZE	ARR	KAS:INE|NUM:S|MUG:M|ENT:Tokia
IZE	ARR	KAS:INE|NUM:S|MUG:M|MW:B
IZE	ARR	KAS:INE|NUM:S|MUG:M|POS:POSaitzinean|POS:+
IZE	ARR	KAS:INE|NUM:S|MUG:M|POS:POSaldean|POS:+
IZE	ARR	KAS:INE|NUM:S|MUG:M|POS:POSatzean|POS:+
IZE	ARR	KAS:INE|NUM:S|MUG:M|POS:POSaurrean|POS:+
IZE	ARR	KAS:INE|NUM:S|MUG:M|POS:POSazpian|POS:+
IZE	ARR	KAS:INE|NUM:S|MUG:M|POS:POSbaitan|POS:+
IZE	ARR	KAS:INE|NUM:S|MUG:M|POS:POSbarruan|POS:+
IZE	ARR	KAS:INE|NUM:S|MUG:M|POS:POSbitartean|POS:+
IZE	ARR	KAS:INE|NUM:S|MUG:M|POS:POSgainean|POS:+
IZE	ARR	KAS:INE|NUM:S|MUG:M|POS:POSinguruan|POS:+
IZE	ARR	KAS:INE|NUM:S|MUG:M|POS:POSlekuan|POS:+
IZE	ARR	KAS:INE|NUM:S|MUG:M|POS:POSostean|POS:+
IZE	ARR	KAS:INE|POS:POSaldean|POS:+
IZE	ARR	KAS:INE|POS:POSartean|POS:+
IZE	ARR	KAS:INE|POS:POSatzean|POS:+
IZE	ARR	KAS:INE|POS:POSaurrean|POS:+
IZE	ARR	KAS:INE|POS:POSazpian|POS:+
IZE	ARR	KAS:INE|POS:POSbarruan|POS:+
IZE	ARR	KAS:INE|POS:POSeran|POS:+
IZE	ARR	KAS:INE|POS:POSerdian|POS:+
IZE	ARR	KAS:INE|POS:POSgainean|POS:+
IZE	ARR	KAS:INE|POS:POSinguruan|POS:+
IZE	ARR	KAS:INE|POS:POSinguruetan|POS:+
IZE	ARR	KAS:INE|POS:POSostean|POS:+
IZE	ARR	KAS:INE|POS:POSpartean|POS:+
IZE	ARR	KAS:INS
IZE	ARR	KAS:INS|ENT:Erakundea
IZE	ARR	KAS:INS|MUG:MG
IZE	ARR	KAS:INS|MUG:MG|ENT:Erakundea
IZE	ARR	KAS:INS|MUG:MG|POS:POSbidez|POS:+
IZE	ARR	KAS:INS|NUM:P
IZE	ARR	KAS:INS|NUM:P|MUG:M
IZE	ARR	KAS:INS|NUM:P|MUG:M|POS:POSbidez|POS:+
IZE	ARR	KAS:INS|NUM:S
IZE	ARR	KAS:INS|NUM:S|MUG:M
IZE	ARR	KAS:INS|NUM:S|MUG:M|POS:POSbidez|POS:+
IZE	ARR	KAS:INS|NUM:S|MUG:M|POS:POSbitartez|POS:+
IZE	ARR	KAS:MOT
IZE	ARR	KAS:MOT|NUM:P
IZE	ARR	KAS:MOT|NUM:P|MUG:M
IZE	ARR	KAS:MOT|NUM:S
IZE	ARR	KAS:MOT|NUM:S|MUG:M
IZE	ARR	KAS:PAR
IZE	ARR	KAS:PAR|MUG:MG
IZE	ARR	KAS:PRO
IZE	ARR	KAS:PRO|MUG:MG
IZE	ARR	KAS:SOZ
IZE	ARR	KAS:SOZ|MUG:MG
IZE	ARR	KAS:SOZ|NUM:P
IZE	ARR	KAS:SOZ|NUM:P|MUG:M
IZE	ARR	KAS:SOZ|NUM:S
IZE	ARR	KAS:SOZ|NUM:S|ENT:Erakundea
IZE	ARR	KAS:SOZ|NUM:S|MUG:M
IZE	ARR	KAS:SOZ|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	MAI:KONP|KAS:ABS
IZE	ARR	MAI:KONP|KAS:ABS|MUG:MG
IZE	ARR	MAI:KONP|KAS:ABS|NUM:S
IZE	ARR	MAI:KONP|KAS:ABS|NUM:S|MUG:M
IZE	ARR	MAI:KONP|KAS:ALA|NUM:S
IZE	ARR	MAI:KONP|KAS:ALA|NUM:S|MUG:M
IZE	ARR	MAI:KONP|KAS:INE
IZE	ARR	MAI:KONP|KAS:INE|MUG:MG
IZE	ARR	MAI:KONP|KAS:INE|NUM:S
IZE	ARR	MAI:KONP|KAS:INE|NUM:S|MUG:M
IZE	ARR	MAI:SUP|KAS:ABS|NUM:S
IZE	ARR	MTKAT:LAB|KAS:INE|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	MTKAT:SNB
IZE	ARR	MTKAT:SNB|KAS:ABS|NUM:P|MUG:M
IZE	ARR	MTKAT:SNB|KAS:ABS|NUM:S|MUG:M
IZE	ARR	MTKAT:SNB|KAS:ALA|POS:POSingurura|POS:+
IZE	ARR	MTKAT:SNB|KAS:GEL|NUM:S|MUG:M
IZE	ARR	MW:B
IZE	ARR	NMG:S|KAS:INE|NUM:S|MUG:M|MW:B
IZE	ARR	NUM:S
IZE	ARR	NUM:S|MUG:M
IZE	ARR	PLU:+|KAS:ERG|NUM:P|ENT:Erakundea
IZE	ARR	PLU:+|KAS:GEL|NUM:P
IZE	ARR	PLU:+|KAS:GEL|NUM:P|MUG:M
IZE	ARR	PLU:-
IZE	ARR	PLU:-|KAS:ABS|MUG:MG
IZE	ARR	PLU:-|KAS:ABS|NUM:P|MUG:M|ENT:Tokia
IZE	ARR	PLU:-|KAS:ABS|NUM:S|MUG:M
IZE	ARR	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSgora|POS:+
IZE	ARR	PLU:-|KAS:ERG|NUM:P|MUG:M|ENT:Erakundea
IZE	ARR	PLU:-|KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	ARR	PLU:-|KAS:GEL|NUM:S|MUG:M|ENT:Tokia
IZE	ARR	PLU:-|KAS:INE|NUM:S|MUG:M
IZE	ARR	_
IZE	DET_IZEELI	KAS:ABS|NUM:P|MUG:M
IZE	DET_IZEELI	KAS:ABS|NUM:S|MUG:M
IZE	DET_IZEELI	KAS:DAT|NUM:S|MUG:M
IZE	DET_IZEELI	KAS:ERG|NUM:S|MUG:M
IZE	DET_IZEELI	KAS:INE|NUM:S|MUG:M
IZE	DET_IZEELI	KAS:SOZ|NUM:S|MUG:M
IZE	IOR_IZEELI	PER:GU|KAS:ABS|NUM:S
IZE	IOR_IZEELI	PER:GU|KAS:ABS|NUM:S|MUG:M
IZE	IOR_IZEELI	PER:NI|KAS:ABS|NUM:P
IZE	IOR_IZEELI	PER:NI|KAS:ABS|NUM:P|MUG:M
IZE	IOR_IZEELI	PER:ZUEK|KAS:ABS|NUM:S
IZE	IOR_IZEELI	PER:ZUEK|KAS:ABS|NUM:S|MUG:M
IZE	IZB	BIZ:+|ENT:Pertsona
IZE	IZB	BIZ:+|KAS:ABS|NUM:S|ENT:Pertsona
IZE	IZB	BIZ:+|KAS:ERG|NUM:S
IZE	IZB	BIZ:+|KAS:ERG|NUM:S|ENT:Pertsona
IZE	IZB	BIZ:+|KAS:GEN|NUM:S|ENT:Pertsona
IZE	IZB	BIZ:+|PLU:-|ENT:Pertsona
IZE	IZB	BIZ:+|PLU:-|KAS:ABS|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	BIZ:+|PLU:-|KAS:ERG|NUM:S|MUG:M
IZE	IZB	BIZ:+|PLU:-|KAS:ERG|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	BIZ:+|PLU:-|KAS:GEN|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	BIZ:-
IZE	IZB	BIZ:-|ENT:Erakundea
IZE	IZB	BIZ:-|ENT:Pertsona
IZE	IZB	BIZ:-|KAS:ABL|NUM:S|ENT:Erakundea
IZE	IZB	BIZ:-|KAS:ABS|NUM:S|ENT:Erakundea
IZE	IZB	BIZ:-|KAS:ABS|NUM:S|ENT:Pertsona
IZE	IZB	BIZ:-|KAS:ABS|NUM:S|ENT:Tokia
IZE	IZB	BIZ:-|KAS:ABS|NUM:S|MUG:M|ENT:Tokia
IZE	IZB	BIZ:-|KAS:DAT|NUM:S|ENT:Erakundea
IZE	IZB	BIZ:-|KAS:DES|NUM:S|ENT:Erakundea
IZE	IZB	BIZ:-|KAS:EM|NUM:S|ENT:Erakundea
IZE	IZB	BIZ:-|KAS:ERG|NUM:S
IZE	IZB	BIZ:-|KAS:ERG|NUM:S|ENT:Erakundea
IZE	IZB	BIZ:-|KAS:ERG|NUM:S|ENT:Pertsona
IZE	IZB	BIZ:-|KAS:ERG|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	BIZ:-|KAS:GEL|NUM:S
IZE	IZB	BIZ:-|KAS:GEL|NUM:S|ENT:Erakundea
IZE	IZB	BIZ:-|KAS:GEL|NUM:S|ENT:Pertsona
IZE	IZB	BIZ:-|KAS:GEN|NUM:S
IZE	IZB	BIZ:-|KAS:GEN|NUM:S|ENT:Erakundea
IZE	IZB	BIZ:-|KAS:GEN|NUM:S|ENT:Pertsona
IZE	IZB	BIZ:-|KAS:INE|NUM:S|ENT:Erakundea
IZE	IZB	BIZ:-|KAS:SOZ|NUM:S|ENT:Erakundea
IZE	IZB	BIZ:-|PLU:-|KAS:ERG|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|KAS:ABS|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|KAS:ERG|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|KAS:GEN|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|ENT:Erakundea
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|ENT:Pertsona
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:ABL|NUM:S|MUG:M|POS:POSaldetik|POS:+|ENT:Erakundea
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:ABS|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:DAT|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:DES|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:EM|NUM:S|MUG:M|POS:POSaldetik|POS:+|ENT:Erakundea
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:EM|NUM:S|MUG:M|POS:POSkontra|POS:+|ENT:Erakundea
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:ERG|NUM:S|MUG:M
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:ERG|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:GEL|NUM:S|MUG:M
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:GEL|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:GEL|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:GEN|NUM:S|MUG:M
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:GEN|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:INE|NUM:S|MUG:M|POS:POSinguruan|POS:+|ENT:Erakundea
IZE	IZB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:SOZ|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	ENT:???
IZE	IZB	ENT:Erakundea
IZE	IZB	ENT:Pertsona
IZE	IZB	ENT:Tokia
IZE	IZB	IZAUR:-|KAS:INE|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	IZB	KAS:ABL|NUM:S
IZE	IZB	KAS:ABL|NUM:S|ENT:Erakundea
IZE	IZB	KAS:ABL|NUM:S|ENT:Pertsona
IZE	IZB	KAS:ABL|NUM:S|ENT:Tokia
IZE	IZB	KAS:ABS|ENT:Erakundea
IZE	IZB	KAS:ABS|ENT:Pertsona
IZE	IZB	KAS:ABS|NUM:P|ENT:Pertsona
IZE	IZB	KAS:ABS|NUM:S
IZE	IZB	KAS:ABS|NUM:S|ENT:???
IZE	IZB	KAS:ABS|NUM:S|ENT:Erakundea
IZE	IZB	KAS:ABS|NUM:S|ENT:Pertsona
IZE	IZB	KAS:ABS|NUM:S|ENT:Tokia
IZE	IZB	KAS:ABS|NUM:S|MUG:M
IZE	IZB	KAS:ABS|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	KAS:ABS|NUM:S|MUG:M|ENT:Tokia
IZE	IZB	KAS:ABS|NUM:S|MUG:M|MW:B|ENT:Pertsona
IZE	IZB	KAS:ABS|NUM:S|MUG:M|POS:POSarte|POS:+
IZE	IZB	KAS:ALA|NUM:S|ENT:Erakundea
IZE	IZB	KAS:ALA|NUM:S|ENT:Pertsona
IZE	IZB	KAS:DAT|NUM:P|ENT:Pertsona
IZE	IZB	KAS:DAT|NUM:S
IZE	IZB	KAS:DAT|NUM:S|ENT:???
IZE	IZB	KAS:DAT|NUM:S|ENT:Erakundea
IZE	IZB	KAS:DAT|NUM:S|ENT:Pertsona
IZE	IZB	KAS:DAT|NUM:S|MUG:M
IZE	IZB	KAS:DAT|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	KAS:DAT|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	KAS:DES|NUM:S|ENT:???
IZE	IZB	KAS:DES|NUM:S|ENT:Erakundea
IZE	IZB	KAS:DES|NUM:S|ENT:Pertsona
IZE	IZB	KAS:EM|NUM:S
IZE	IZB	KAS:EM|NUM:S|ENT:Erakundea
IZE	IZB	KAS:EM|NUM:S|ENT:Pertsona
IZE	IZB	KAS:EM|NUM:S|ENT:Tokia
IZE	IZB	KAS:EM|NUM:S|MUG:M|POS:POSarabera|POS:+|ENT:Pertsona
IZE	IZB	KAS:ERG|NUM:S
IZE	IZB	KAS:ERG|NUM:S|ENT:Erakundea
IZE	IZB	KAS:ERG|NUM:S|ENT:Pertsona
IZE	IZB	KAS:ERG|NUM:S|ENT:Tokia
IZE	IZB	KAS:ERG|NUM:S|MUG:M
IZE	IZB	KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	KAS:ERG|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	KAS:GEL|NUM:S
IZE	IZB	KAS:GEL|NUM:S|ENT:Erakundea
IZE	IZB	KAS:GEL|NUM:S|ENT:Pertsona
IZE	IZB	KAS:GEL|NUM:S|ENT:Tokia
IZE	IZB	KAS:GEL|NUM:S|MUG:M|POS:POSaldeko|POS:+
IZE	IZB	KAS:GEN|NUM:S
IZE	IZB	KAS:GEN|NUM:S|ENT:Erakundea
IZE	IZB	KAS:GEN|NUM:S|ENT:Pertsona
IZE	IZB	KAS:GEN|NUM:S|ENT:Tokia
IZE	IZB	KAS:GEN|NUM:S|MUG:M
IZE	IZB	KAS:GEN|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	KAS:GEN|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	KAS:GEN|NUM:S|MUG:M|ENT:Tokia
IZE	IZB	KAS:GEN|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	IZB	KAS:INE|NUM:S
IZE	IZB	KAS:INE|NUM:S|ENT:Erakundea
IZE	IZB	KAS:INE|NUM:S|ENT:Pertsona
IZE	IZB	KAS:INE|NUM:S|ENT:Tokia
IZE	IZB	KAS:INS|NUM:S|ENT:Pertsona
IZE	IZB	KAS:MOT|NUM:S|ENT:Pertsona
IZE	IZB	KAS:PAR|NUM:S
IZE	IZB	KAS:PAR|NUM:S|ENT:Erakundea
IZE	IZB	KAS:SOZ|NUM:S
IZE	IZB	KAS:SOZ|NUM:S|ENT:Erakundea
IZE	IZB	KAS:SOZ|NUM:S|ENT:Pertsona
IZE	IZB	KAS:SOZ|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	MTKAT:LAB
IZE	IZB	MTKAT:SIG
IZE	IZB	MTKAT:SIG|ENT:???
IZE	IZB	MTKAT:SIG|ENT:Erakundea
IZE	IZB	MTKAT:SIG|ENT:Pertsona
IZE	IZB	MTKAT:SIG|ENT:Tokia
IZE	IZB	MTKAT:SIG|KAS:ABL|NUM:S|MUG:M
IZE	IZB	MTKAT:SIG|KAS:ABL|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:ABS|MUG:MG|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:ABS|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:ABS|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	MTKAT:SIG|KAS:ABS|NUM:S|MUG:M|ENT:Tokia
IZE	IZB	MTKAT:SIG|KAS:ABS|NUM:S|MUG:M|POS:POSalde|POS:+|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:ABS|NUM:S|MUG:M|POS:POSaurka|POS:+|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:ABS|NUM:S|MUG:M|POS:POSesku|POS:+|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:ALA|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	MTKAT:SIG|KAS:ALA|NUM:S|MUG:M|POS:POSbatera|POS:+|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:BNK|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:DAT|NUM:S|MUG:M
IZE	IZB	MTKAT:SIG|KAS:DAT|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:DAT|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	MTKAT:SIG|KAS:DES|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:EM|NUM:S|MUG:M|POS:POSarabera|POS:+|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:EM|NUM:S|MUG:M|POS:POSbezalako|POS:+|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:EM|NUM:S|MUG:M|POS:POSkontra|POS:+|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:ERG|NUM:S|MUG:M
IZE	IZB	MTKAT:SIG|KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:ERG|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	MTKAT:SIG|KAS:GEL|NUM:S|MUG:M
IZE	IZB	MTKAT:SIG|KAS:GEL|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:GEL|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	MTKAT:SIG|KAS:GEL|NUM:S|MUG:M|POS:POSaldeko|POS:+|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:GEL|NUM:S|MUG:M|POS:POSarteko|POS:+|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:GEL|NUM:S|MUG:M|POS:POSaurkako|POS:+|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:GEL|NUM:S|MUG:M|POS:POSkontrako|POS:+|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:GEN|NUM:S|MUG:M
IZE	IZB	MTKAT:SIG|KAS:GEN|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:GEN|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	MTKAT:SIG|KAS:INE|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:INE|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	MTKAT:SIG|KAS:INE|NUM:S|MUG:M|ENT:Tokia
IZE	IZB	MTKAT:SIG|KAS:INE|NUM:S|MUG:M|POS:POSatzean|POS:+|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:INE|NUM:S|MUG:M|POS:POSbaitan|POS:+|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:INE|NUM:S|MUG:M|POS:POSbarruan|POS:+|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:INE|NUM:S|MUG:M|POS:POSinguruan|POS:+|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:PAR|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	MTKAT:SIG|KAS:SOZ|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	PLU:+|KAS:ABL|NUM:P|ENT:Tokia
IZE	IZB	PLU:+|KAS:ABL|NUM:P|MUG:M|ENT:Tokia
IZE	IZB	PLU:+|KAS:ABS|NUM:P|ENT:Pertsona
IZE	IZB	PLU:+|KAS:ABS|NUM:P|ENT:Tokia
IZE	IZB	PLU:+|KAS:ABS|NUM:P|MUG:M|ENT:Tokia
IZE	IZB	PLU:+|KAS:ABS|NUM:P|MUG:M|POS:POSbitarte|POS:+|ENT:Pertsona
IZE	IZB	PLU:+|KAS:ALA|NUM:P|ENT:Tokia
IZE	IZB	PLU:+|KAS:ALA|NUM:P|MUG:M|ENT:Tokia
IZE	IZB	PLU:+|KAS:EM|NUM:P|ENT:Tokia
IZE	IZB	PLU:+|KAS:EM|NUM:P|MUG:M|POS:POSbezalako|POS:+|ENT:Tokia
IZE	IZB	PLU:+|KAS:EM|NUM:P|MUG:M|POS:POSbezala|POS:+|ENT:Tokia
IZE	IZB	PLU:+|KAS:ERG|NUM:P|ENT:Erakundea
IZE	IZB	PLU:+|KAS:ERG|NUM:P|MUG:M|ENT:Erakundea
IZE	IZB	PLU:+|KAS:GEL|NUM:P
IZE	IZB	PLU:+|KAS:GEL|NUM:P|ENT:Erakundea
IZE	IZB	PLU:+|KAS:GEL|NUM:P|ENT:Pertsona
IZE	IZB	PLU:+|KAS:GEL|NUM:P|ENT:Tokia
IZE	IZB	PLU:+|KAS:GEL|NUM:P|MUG:M
IZE	IZB	PLU:+|KAS:GEL|NUM:P|MUG:M|ENT:Erakundea
IZE	IZB	PLU:+|KAS:GEL|NUM:P|MUG:M|ENT:Pertsona
IZE	IZB	PLU:+|KAS:GEL|NUM:P|MUG:M|ENT:Tokia
IZE	IZB	PLU:+|KAS:GEL|NUM:P|MUG:M|POS:POSarteko|POS:+|ENT:Tokia
IZE	IZB	PLU:+|KAS:GEN|NUM:P|ENT:Tokia
IZE	IZB	PLU:+|KAS:GEN|NUM:P|MUG:M|ENT:Tokia
IZE	IZB	PLU:+|KAS:INE|NUM:P|ENT:Tokia
IZE	IZB	PLU:+|KAS:INE|NUM:P|MUG:M|ENT:Tokia
IZE	IZB	PLU:-
IZE	IZB	PLU:-|ENT:???
IZE	IZB	PLU:-|ENT:Erakundea
IZE	IZB	PLU:-|ENT:Pertsona
IZE	IZB	PLU:-|ENT:Tokia
IZE	IZB	PLU:-|KAS:ABL|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ABL|NUM:S|MUG:M|ENT:Tokia
IZE	IZB	PLU:-|KAS:ABL|NUM:S|MUG:M|POS:POSaitzinetik|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ABL|NUM:S|MUG:M|POS:POSatzetik|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ABL|NUM:S|MUG:M|POS:POSaurretik|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ABL|NUM:S|MUG:M|POS:POSeskutik|POS:+
IZE	IZB	PLU:-|KAS:ABL|NUM:S|MUG:M|POS:POSeskutik|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ABL|NUM:S|MUG:M|POS:POSondotik|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ABS|MUG:MG|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ABS|NUM:P|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ABS|NUM:S|MUG:M
IZE	IZB	PLU:-|KAS:ABS|NUM:S|MUG:M|ENT:???
IZE	IZB	PLU:-|KAS:ABS|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	PLU:-|KAS:ABS|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ABS|NUM:S|MUG:M|ENT:Tokia
IZE	IZB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSalde|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSaurka|POS:+
IZE	IZB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSaurka|POS:+|ENT:Erakundea
IZE	IZB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSaurka|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSesker|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSgain|POS:+
IZE	IZB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSgain|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ALA|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ALA|NUM:S|MUG:M|POS:POSaldera|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ALA|NUM:S|MUG:M|POS:POSbatera|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ALA|NUM:S|MUG:M|POS:POSlepora|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:DAT|NUM:P|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|KAS:DAT|NUM:S|MUG:M
IZE	IZB	PLU:-|KAS:DAT|NUM:S|MUG:M|ENT:???
IZE	IZB	PLU:-|KAS:DAT|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	PLU:-|KAS:DAT|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|KAS:DES|NUM:S|MUG:M|ENT:???
IZE	IZB	PLU:-|KAS:DES|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	PLU:-|KAS:DES|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSarabera|POS:+
IZE	IZB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSarabera|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSbatera|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSbegira|POS:+
IZE	IZB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSbezalako|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSbezala|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSbezala|POS:+|ENT:Tokia
IZE	IZB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSkontra|POS:+|ENT:Erakundea
IZE	IZB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSkontra|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSkontra|POS:+|ENT:Tokia
IZE	IZB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSordez|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ERG|NUM:S|MUG:M
IZE	IZB	PLU:-|KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	PLU:-|KAS:ERG|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|KAS:ERG|NUM:S|MUG:M|ENT:Tokia
IZE	IZB	PLU:-|KAS:GEL|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	PLU:-|KAS:GEL|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSaldeko|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSarteko|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSaurkako|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSaurreko|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSburuzko|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSkontrako|POS:+|ENT:Erakundea
IZE	IZB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSkontrako|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:GEN|NUM:S|MUG:M
IZE	IZB	PLU:-|KAS:GEN|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	PLU:-|KAS:GEN|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|KAS:GEN|NUM:S|MUG:M|ENT:Tokia
IZE	IZB	PLU:-|KAS:GEN|NUM:S|MUG:M|POS:POSbezalakoen|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:INE|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|KAS:INE|NUM:S|MUG:M|POS:POSartean|POS:+|ENT:Erakundea
IZE	IZB	PLU:-|KAS:INE|NUM:S|MUG:M|POS:POSartean|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:INE|NUM:S|MUG:M|POS:POSaurrean|POS:+|ENT:Erakundea
IZE	IZB	PLU:-|KAS:INE|NUM:S|MUG:M|POS:POSaurrean|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:INE|NUM:S|MUG:M|POS:POSlekuan|POS:+
IZE	IZB	PLU:-|KAS:INE|NUM:S|MUG:M|POS:POSondoan|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:INS|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|KAS:INS|NUM:S|MUG:M|POS:POSpartez|POS:+|ENT:Pertsona
IZE	IZB	PLU:-|KAS:MOT|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|KAS:PAR|NUM:S|MUG:M
IZE	IZB	PLU:-|KAS:SOZ|NUM:S|MUG:M
IZE	IZB	PLU:-|KAS:SOZ|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	PLU:-|KAS:SOZ|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|MTKAT:LAB|KAS:ABS|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|MTKAT:SIG|ENT:Erakundea
IZE	IZB	PLU:-|MTKAT:SIG|KAS:ABL|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	PLU:-|MTKAT:SIG|KAS:ABS|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|MTKAT:SIG|KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	PLU:-|MTKAT:SIG|KAS:ERG|NUM:S|MUG:M|ENT:Pertsona
IZE	IZB	PLU:-|MTKAT:SIG|KAS:GEL|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	PLU:-|MTKAT:SIG|KAS:GEL|NUM:S|MUG:M|ENT:Tokia
IZE	IZB	PLU:-|MTKAT:SIG|KAS:GEN|NUM:S|MUG:M|ENT:Erakundea
IZE	IZB	_
IZE	IZE_IZEELI	BIZ:+|KAS:ABS|NUM:P|MUG:M
IZE	IZE_IZEELI	BIZ:+|KAS:ABS|NUM:S|MUG:M
IZE	IZE_IZEELI	BIZ:+|KAS:INE|NUM:P|MUG:M
IZE	IZE_IZEELI	BIZ:-|KAS:ABS|NUM:P|MUG:M
IZE	IZE_IZEELI	BIZ:-|KAS:ABS|NUM:S|MUG:M
IZE	IZE_IZEELI	BIZ:-|KAS:ALA|NUM:S|MUG:M
IZE	IZE_IZEELI	BIZ:-|KAS:DAT|NUM:P|MUG:M
IZE	IZE_IZEELI	BIZ:-|KAS:DES|NUM:S|MUG:M
IZE	IZE_IZEELI	BIZ:-|KAS:ERG|NUM:P|MUG:M
IZE	IZE_IZEELI	BIZ:-|KAS:ERG|NUM:S|MUG:M
IZE	IZE_IZEELI	BIZ:-|KAS:GEN|NUM:P|MUG:M
IZE	IZE_IZEELI	BIZ:-|KAS:GEN|NUM:S|MUG:M
IZE	IZE_IZEELI	BIZ:-|KAS:INE|NUM:P|MUG:M
IZE	IZE_IZEELI	BIZ:-|KAS:INE|NUM:S|MUG:M
IZE	IZE_IZEELI	BIZ:-|KAS:INE|NUM:S|MUG:M|ENT:Tokia
IZE	IZE_IZEELI	BIZ:-|KAS:SOZ|NUM:P|MUG:M
IZE	IZE_IZEELI	BIZ:-|KAS:SOZ|NUM:S|MUG:M
IZE	IZE_IZEELI	KAS:ABL|NUM:S|MUG:M
IZE	IZE_IZEELI	KAS:ABS|NUM:P|MUG:M
IZE	IZE_IZEELI	KAS:ABS|NUM:P|MUG:M|ENT:Erakundea
IZE	IZE_IZEELI	KAS:ABS|NUM:S|MUG:M
IZE	IZE_IZEELI	KAS:ALA|NUM:S|MUG:M
IZE	IZE_IZEELI	KAS:DAT|NUM:S|MUG:M
IZE	IZE_IZEELI	KAS:DES|NUM:P|MUG:M
IZE	IZE_IZEELI	KAS:DES|NUM:S|MUG:M
IZE	IZE_IZEELI	KAS:ERG|NUM:P|MUG:M
IZE	IZE_IZEELI	KAS:ERG|NUM:S|MUG:M
IZE	IZE_IZEELI	KAS:GEN|NUM:P|MUG:M
IZE	IZE_IZEELI	KAS:GEN|NUM:S|MUG:M
IZE	IZE_IZEELI	KAS:INE|NUM:P|MUG:M
IZE	IZE_IZEELI	KAS:INE|NUM:S|MUG:M
IZE	IZE_IZEELI	KAS:SOZ|NUM:P|MUG:M
IZE	IZE_IZEELI	KAS:SOZ|NUM:S|MUG:M
IZE	IZE_IZEELI	MTKAT:SIG|KAS:ABS|NUM:P|MUG:M
IZE	IZE_IZEELI	MTKAT:SIG|KAS:ABS|NUM:S|MUG:M
IZE	IZE_IZEELI	MTKAT:SIG|KAS:ABS|NUM:S|MUG:M|ENT:Erakundea
IZE	IZE_IZEELI	MTKAT:SIG|KAS:ERG|NUM:P|MUG:M|ENT:Erakundea
IZE	IZE_IZEELI	MTKAT:SIG|KAS:GEN|NUM:P|MUG:M|ENT:Erakundea
IZE	IZE_IZEELI	PLU:+|KAS:ERG|NUM:P|MUG:M|ENT:Erakundea
IZE	IZE_IZEELI	PLU:-|KAS:ABL|NUM:P|MUG:M|ENT:Pertsona
IZE	IZE_IZEELI	PLU:-|KAS:ABS|MUG:MG
IZE	IZE_IZEELI	PLU:-|KAS:ABS|NUM:P|MUG:M
IZE	IZE_IZEELI	PLU:-|KAS:ABS|NUM:P|MUG:M|ENT:???
IZE	IZE_IZEELI	PLU:-|KAS:ABS|NUM:P|MUG:M|ENT:Tokia
IZE	IZE_IZEELI	PLU:-|KAS:ABS|NUM:S|MUG:M
IZE	IZE_IZEELI	PLU:-|KAS:ABS|NUM:S|MUG:M|ENT:Erakundea
IZE	IZE_IZEELI	PLU:-|KAS:ABS|NUM:S|MUG:M|ENT:Pertsona
IZE	IZE_IZEELI	PLU:-|KAS:ABS|NUM:S|MUG:M|ENT:Tokia
IZE	IZE_IZEELI	PLU:-|KAS:ALA|NUM:S|MUG:M
IZE	IZE_IZEELI	PLU:-|KAS:DAT|NUM:S|MUG:M
IZE	IZE_IZEELI	PLU:-|KAS:DAT|NUM:S|MUG:M|ENT:Tokia
IZE	IZE_IZEELI	PLU:-|KAS:ERG|NUM:P|MUG:M
IZE	IZE_IZEELI	PLU:-|KAS:ERG|NUM:P|MUG:M|ENT:Pertsona
IZE	IZE_IZEELI	PLU:-|KAS:ERG|NUM:S|MUG:M
IZE	IZE_IZEELI	PLU:-|KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	IZE_IZEELI	PLU:-|KAS:GEN|NUM:S|MUG:M
IZE	IZE_IZEELI	PLU:-|KAS:GEN|NUM:S|MUG:M|ENT:Pertsona
IZE	IZE_IZEELI	PLU:-|KAS:GEN|NUM:S|MUG:M|ENT:Tokia
IZE	IZE_IZEELI	PLU:-|KAS:INE|NUM:S|MUG:M|ENT:Tokia
IZE	IZE_IZEELI	PLU:-|KAS:INS|NUM:S|MUG:M
IZE	IZE_IZEELI	PLU:-|KAS:MOT|NUM:P|MUG:M
IZE	IZE_IZEELI	PLU:-|KAS:SOZ|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	BIZ:-|ENT:Erakundea
IZE	LIB	BIZ:-|ENT:Tokia
IZE	LIB	BIZ:-|KAS:ABS|NUM:P|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:ABS|NUM:P|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:ABS|NUM:S|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:ABS|NUM:S|ENT:Tokia
IZE	LIB	BIZ:-|KAS:ABS|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:ABS|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:DAT|NUM:S|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:ERG|NUM:P|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:ERG|NUM:P|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:ERG|NUM:S|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:ERG|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:GEL|NUM:P|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:GEL|NUM:P|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:GEL|NUM:S
IZE	LIB	BIZ:-|KAS:GEL|NUM:S|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:GEL|NUM:S|ENT:Tokia
IZE	LIB	BIZ:-|KAS:GEL|NUM:S|MUG:M|MW:B
IZE	LIB	BIZ:-|KAS:GEL|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:GEL|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	BIZ:-|KAS:GEN|NUM:P|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:GEN|NUM:P|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:GEN|NUM:S|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:GEN|NUM:S|ENT:Tokia
IZE	LIB	BIZ:-|KAS:GEN|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:INE|NUM:S|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:INE|NUM:S|ENT:Tokia
IZE	LIB	BIZ:-|KAS:INE|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:INS|NUM:S|ENT:Erakundea
IZE	LIB	BIZ:-|KAS:SOZ|NUM:S|ENT:Erakundea
IZE	LIB	BIZ:-|MTKAT:SIG|ENT:Erakundea
IZE	LIB	BIZ:-|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|MW:B|ENT:Tokia
IZE	LIB	BIZ:-|PLU:-|KAS:ABS|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|PLU:-|KAS:ABS|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	BIZ:-|PLU:-|KAS:DAT|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|PLU:-|KAS:ERG|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|PLU:-|KAS:GEL|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|PLU:-|KAS:GEL|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	BIZ:-|PLU:-|KAS:GEN|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|PLU:-|KAS:GEN|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	BIZ:-|PLU:-|KAS:INE|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	BIZ:-|PLU:-|KAS:INS|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|PLU:-|KAS:SOZ|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	BIZ:-|ZENB:-|NEUR:-|PLU:-|KAS:GEL|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	BIZ:-|ZENB:-|NEUR:-|PLU:-|MTKAT:SIG|KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	ENT:???
IZE	LIB	ENT:Erakundea
IZE	LIB	ENT:Pertsona
IZE	LIB	ENT:Tokia
IZE	LIB	IZAUR:-|KAS:ABS|NUM:P|MUG:M|MW:B|ENT:Tokia
IZE	LIB	IZAUR:-|KAS:ABS|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	IZAUR:-|KAS:ABS|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	IZAUR:-|KAS:ABS|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	IZAUR:-|KAS:DAT|NUM:P|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	IZAUR:-|KAS:ERG|NUM:P|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	IZAUR:-|KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	IZAUR:-|KAS:ERG|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	IZAUR:-|KAS:GEL|NUM:P|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	IZAUR:-|KAS:GEL|NUM:P|MUG:M|MW:B|ENT:Tokia
IZE	LIB	IZAUR:-|KAS:GEL|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	IZAUR:-|KAS:GEL|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	IZAUR:-|KAS:GEL|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	IZAUR:-|KAS:GEN|NUM:P|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	IZAUR:-|KAS:INE|NUM:P|MUG:M|MW:B|ENT:Tokia
IZE	LIB	IZAUR:-|KAS:SOZ|NUM:P|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	IZAUR:-|MW:B|ENT:Erakundea
IZE	LIB	KAS:ABL|NUM:S
IZE	LIB	KAS:ABL|NUM:S|ENT:Erakundea
IZE	LIB	KAS:ABL|NUM:S|ENT:Tokia
IZE	LIB	KAS:ABL|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	KAS:ABS|ENT:Erakundea
IZE	LIB	KAS:ABS|ENT:Tokia
IZE	LIB	KAS:ABS|NUM:P|ENT:Tokia
IZE	LIB	KAS:ABS|NUM:S
IZE	LIB	KAS:ABS|NUM:S|ENT:???
IZE	LIB	KAS:ABS|NUM:S|ENT:Erakundea
IZE	LIB	KAS:ABS|NUM:S|ENT:Pertsona
IZE	LIB	KAS:ABS|NUM:S|ENT:Tokia
IZE	LIB	KAS:ABS|NUM:S|MUG:M
IZE	LIB	KAS:ABS|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	KAS:ABS|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	KAS:ABS|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	KAS:ABU|NUM:S|ENT:Tokia
IZE	LIB	KAS:ABZ|NUM:S|ENT:Tokia
IZE	LIB	KAS:ALA|NUM:S
IZE	LIB	KAS:ALA|NUM:S|ENT:Erakundea
IZE	LIB	KAS:ALA|NUM:S|ENT:Tokia
IZE	LIB	KAS:DAT|NUM:P|ENT:Erakundea
IZE	LIB	KAS:DAT|NUM:S|ENT:Erakundea
IZE	LIB	KAS:DAT|NUM:S|ENT:Pertsona
IZE	LIB	KAS:DAT|NUM:S|ENT:Tokia
IZE	LIB	KAS:DAT|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	KAS:DES|NUM:S|ENT:Erakundea
IZE	LIB	KAS:DES|NUM:S|ENT:Tokia
IZE	LIB	KAS:EM|NUM:S|ENT:Erakundea
IZE	LIB	KAS:EM|NUM:S|ENT:Tokia
IZE	LIB	KAS:ERG|NUM:P|ENT:Erakundea
IZE	LIB	KAS:ERG|NUM:P|ENT:Pertsona
IZE	LIB	KAS:ERG|NUM:S
IZE	LIB	KAS:ERG|NUM:S|ENT:Erakundea
IZE	LIB	KAS:ERG|NUM:S|ENT:Pertsona
IZE	LIB	KAS:ERG|NUM:S|ENT:Tokia
IZE	LIB	KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	KAS:ERG|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	KAS:GEL|NUM:P|ENT:Erakundea
IZE	LIB	KAS:GEL|NUM:P|ENT:Tokia
IZE	LIB	KAS:GEL|NUM:S
IZE	LIB	KAS:GEL|NUM:S|ENT:Erakundea
IZE	LIB	KAS:GEL|NUM:S|ENT:Pertsona
IZE	LIB	KAS:GEL|NUM:S|ENT:Tokia
IZE	LIB	KAS:GEL|NUM:S|MUG:M|ENT:Pertsona
IZE	LIB	KAS:GEL|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	KAS:GEL|NUM:S|MUG:M|MW:B|ENT:Pertsona
IZE	LIB	KAS:GEL|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	KAS:GEN|NUM:P|ENT:Erakundea
IZE	LIB	KAS:GEN|NUM:S
IZE	LIB	KAS:GEN|NUM:S|ENT:???
IZE	LIB	KAS:GEN|NUM:S|ENT:Erakundea
IZE	LIB	KAS:GEN|NUM:S|ENT:Pertsona
IZE	LIB	KAS:GEN|NUM:S|ENT:Tokia
IZE	LIB	KAS:GEN|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	KAS:GEN|NUM:S|MUG:M|MW:B
IZE	LIB	KAS:GEN|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	KAS:INE|NUM:P|ENT:Tokia
IZE	LIB	KAS:INE|NUM:S
IZE	LIB	KAS:INE|NUM:S|ENT:Erakundea
IZE	LIB	KAS:INE|NUM:S|ENT:Pertsona
IZE	LIB	KAS:INE|NUM:S|ENT:Tokia
IZE	LIB	KAS:INE|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	KAS:INE|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	KAS:INS|NUM:S|ENT:Tokia
IZE	LIB	KAS:PRO|NUM:S|ENT:Tokia
IZE	LIB	KAS:SOZ|NUM:P|ENT:Erakundea
IZE	LIB	KAS:SOZ|NUM:S
IZE	LIB	KAS:SOZ|NUM:S|ENT:Erakundea
IZE	LIB	KAS:SOZ|NUM:S|ENT:Tokia
IZE	LIB	KAS:SOZ|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	KAS:SOZ|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	MTKAT:SIG|ENT:Erakundea
IZE	LIB	MTKAT:SIG|KAS:ABS|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	MTKAT:SIG|KAS:ALA|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	MTKAT:SIG|KAS:DAT|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	MTKAT:SIG|KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	MTKAT:SIG|KAS:ERG|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	MTKAT:SIG|KAS:GEL|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	MTKAT:SIG|KAS:GEL|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	MTKAT:SIG|KAS:GEN|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	MTKAT:SIG|KAS:INE|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	MW:B|ENT:???
IZE	LIB	MW:B|ENT:Erakundea
IZE	LIB	PLU:+|IZAUR:-|KAS:ABS|NUM:P|MUG:M|MW:B|ENT:Tokia
IZE	LIB	PLU:+|IZAUR:-|KAS:ALA|NUM:P|MUG:M|MW:B|ENT:Tokia
IZE	LIB	PLU:+|IZAUR:-|KAS:DAT|NUM:P|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	PLU:+|IZAUR:-|KAS:ERG|NUM:P|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	PLU:+|IZAUR:-|KAS:GEL|NUM:P|MUG:M|ENT:Erakundea
IZE	LIB	PLU:+|IZAUR:-|KAS:GEL|NUM:P|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	PLU:+|IZAUR:-|KAS:GEL|NUM:P|MUG:M|MW:B|ENT:Tokia
IZE	LIB	PLU:+|IZAUR:-|KAS:INE|NUM:P|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	PLU:+|IZAUR:-|KAS:INE|NUM:P|MUG:M|MW:B|ENT:Tokia
IZE	LIB	PLU:+|KAS:ABL|NUM:P|ENT:Tokia
IZE	LIB	PLU:+|KAS:ABL|NUM:P|MUG:M|ENT:Tokia
IZE	LIB	PLU:+|KAS:ABS|NUM:P|ENT:Erakundea
IZE	LIB	PLU:+|KAS:ABS|NUM:P|ENT:Tokia
IZE	LIB	PLU:+|KAS:ABS|NUM:P|MUG:M|ENT:Erakundea
IZE	LIB	PLU:+|KAS:ABS|NUM:P|MUG:M|ENT:Tokia
IZE	LIB	PLU:+|KAS:ALA|NUM:P|ENT:Tokia
IZE	LIB	PLU:+|KAS:ALA|NUM:P|MUG:M|ENT:Tokia
IZE	LIB	PLU:+|KAS:DAT|NUM:P|ENT:Erakundea
IZE	LIB	PLU:+|KAS:ERG|NUM:P|ENT:Erakundea
IZE	LIB	PLU:+|KAS:ERG|NUM:P|MUG:M|ENT:Erakundea
IZE	LIB	PLU:+|KAS:GEL|NUM:P|ENT:Erakundea
IZE	LIB	PLU:+|KAS:GEL|NUM:P|ENT:Pertsona
IZE	LIB	PLU:+|KAS:GEL|NUM:P|ENT:Tokia
IZE	LIB	PLU:+|KAS:GEL|NUM:P|MUG:M|ENT:Erakundea
IZE	LIB	PLU:+|KAS:GEL|NUM:P|MUG:M|ENT:Pertsona
IZE	LIB	PLU:+|KAS:GEL|NUM:P|MUG:M|ENT:Tokia
IZE	LIB	PLU:+|KAS:GEL|NUM:P|MUG:M|POS:POSarteko|POS:+|ENT:Tokia
IZE	LIB	PLU:+|KAS:INE|NUM:P|ENT:Erakundea
IZE	LIB	PLU:+|KAS:INE|NUM:P|ENT:Tokia
IZE	LIB	PLU:+|KAS:INE|NUM:P|MUG:M|ENT:Tokia
IZE	LIB	PLU:-
IZE	LIB	PLU:-|ENT:???
IZE	LIB	PLU:-|ENT:Erakundea
IZE	LIB	PLU:-|ENT:Pertsona
IZE	LIB	PLU:-|ENT:Tokia
IZE	LIB	PLU:-|KAS:ABL|NUM:S|MUG:M
IZE	LIB	PLU:-|KAS:ABL|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|KAS:ABL|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|KAS:ABL|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	PLU:-|KAS:ABL|NUM:S|MUG:M|POS:POSatzetik|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:ABL|NUM:S|MUG:M|POS:POSatzetik|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:ABL|NUM:S|MUG:M|POS:POSaurretik|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:ABS|MUG:MG|ENT:Erakundea
IZE	LIB	PLU:-|KAS:ABS|MUG:MG|ENT:Tokia
IZE	LIB	PLU:-|KAS:ABS|NUM:P|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M|ENT:???
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M|ENT:Pertsona
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSalde|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSalde|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSarte|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSaurkaa|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSaurka|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSaurka|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSesku|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSkanpo|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:ABS|NUM:S|MUG:M|POS:POSmenpe|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:ABU|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|KAS:ABZ|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|KAS:ALA|NUM:S|MUG:M
IZE	LIB	PLU:-|KAS:ALA|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|KAS:ALA|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|KAS:ALA|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	PLU:-|KAS:ALA|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	PLU:-|KAS:ALA|NUM:S|MUG:M|POS:POSbatera|POS:+
IZE	LIB	PLU:-|KAS:ALA|NUM:S|MUG:M|POS:POSbatera|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:ALA|NUM:S|MUG:M|POS:POSkanpora|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:ALA|NUM:S|MUG:M|POS:POSmenpera|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:DAT|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|KAS:DAT|NUM:S|MUG:M|ENT:Pertsona
IZE	LIB	PLU:-|KAS:DAT|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|KAS:DAT|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	PLU:-|KAS:DES|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|KAS:DES|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSarabera|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSarabera|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSbegira|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSbegira|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSbezalako|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSbezalako|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSbezala|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSburuz|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSgora|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POShurbil|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSkanpoko|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSkontra|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSkontra|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSpareko|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSurrun|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:EM|NUM:S|MUG:M|POS:POSzehar|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:ERG|NUM:P|MUG:M|ENT:Pertsona
IZE	LIB	PLU:-|KAS:ERG|NUM:S|MUG:M
IZE	LIB	PLU:-|KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|KAS:ERG|NUM:S|MUG:M|ENT:Pertsona
IZE	LIB	PLU:-|KAS:ERG|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|KAS:ERG|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|ENT:Pertsona
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSaldeko|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSaldeko|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSarteko|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSarteko|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSaurkako|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSaurkako|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSburuzko|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSinguruko|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSkanpoko|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSkontrako|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:GEL|NUM:S|MUG:M|POS:POSkontrako|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:GEN|NUM:S|MUG:M|ENT:???
IZE	LIB	PLU:-|KAS:GEN|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|KAS:GEN|NUM:S|MUG:M|ENT:Pertsona
IZE	LIB	PLU:-|KAS:GEN|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|KAS:GEN|NUM:S|MUG:M|MW:B
IZE	LIB	PLU:-|KAS:GEN|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	PLU:-|KAS:GEN|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	PLU:-|KAS:INE|NUM:S|MUG:M
IZE	LIB	PLU:-|KAS:INE|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|KAS:INE|NUM:S|MUG:M|ENT:Pertsona
IZE	LIB	PLU:-|KAS:INE|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|KAS:INE|NUM:S|MUG:M|MW:B|ENT:Erakundea
IZE	LIB	PLU:-|KAS:INE|NUM:S|MUG:M|MW:B|ENT:Tokia
IZE	LIB	PLU:-|KAS:INE|NUM:S|MUG:M|POS:POSartean|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:INE|NUM:S|MUG:M|POS:POSbarruan|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:INE|NUM:S|MUG:M|POS:POSburuan|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:INE|NUM:S|MUG:M|POS:POSeskuetan|POS:+|ENT:Tokia
IZE	LIB	PLU:-|KAS:INE|NUM:S|MUG:M|POS:POSgainean|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|KAS:INS|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|KAS:PRO|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|KAS:SOZ|NUM:S|MUG:M
IZE	LIB	PLU:-|KAS:SOZ|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|KAS:SOZ|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|MTKAT:LAB|KAS:DAT|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|MTKAT:LAB|KAS:ERG|NUM:S|MUG:M
IZE	LIB	PLU:-|MTKAT:SIG
IZE	LIB	PLU:-|MTKAT:SIG|ENT:Erakundea
IZE	LIB	PLU:-|MTKAT:SIG|ENT:Tokia
IZE	LIB	PLU:-|MTKAT:SIG|KAS:ABS|NUM:S|MUG:M
IZE	LIB	PLU:-|MTKAT:SIG|KAS:ABS|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|MTKAT:SIG|KAS:ABS|NUM:S|MUG:M|ENT:Pertsona
IZE	LIB	PLU:-|MTKAT:SIG|KAS:ABS|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|MTKAT:SIG|KAS:ABS|NUM:S|MUG:M|POS:POSesku|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|MTKAT:SIG|KAS:EM|NUM:S|MUG:M|POS:POSarabera|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|MTKAT:SIG|KAS:ERG|NUM:S|MUG:M
IZE	LIB	PLU:-|MTKAT:SIG|KAS:ERG|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|MTKAT:SIG|KAS:GEL|NUM:S|MUG:M
IZE	LIB	PLU:-|MTKAT:SIG|KAS:GEL|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|MTKAT:SIG|KAS:GEL|NUM:S|MUG:M|ENT:Pertsona
IZE	LIB	PLU:-|MTKAT:SIG|KAS:GEL|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|MTKAT:SIG|KAS:GEN|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|MTKAT:SIG|KAS:INE|NUM:S|MUG:M|ENT:Tokia
IZE	LIB	PLU:-|MTKAT:SIG|KAS:INE|NUM:S|MUG:M|POS:POSartean|POS:+|ENT:Erakundea
IZE	LIB	PLU:-|MTKAT:SIG|KAS:SOZ|NUM:S|MUG:M|ENT:Erakundea
IZE	LIB	PLU:-|MW:B|ENT:Erakundea
IZE	LIB	PLU:-|MW:B|ENT:Tokia
IZE	LIB	_
IZE	ZKI	BIZ:-
IZE	ZKI	BIZ:-|KAS:ABL|NUM:S
IZE	ZKI	BIZ:-|KAS:ABL|NUM:S|MUG:M
IZE	ZKI	BIZ:-|KAS:ABS|NUM:P
IZE	ZKI	BIZ:-|KAS:ABS|NUM:P|MUG:M
IZE	ZKI	BIZ:-|KAS:ABU|NUM:S
IZE	ZKI	BIZ:-|KAS:ABU|NUM:S|MUG:M
IZE	ZKI	BIZ:-|KAS:EM
IZE	ZKI	BIZ:-|KAS:EM|POS:POSgora|POS:+
IZE	ZKI	BIZ:-|KAS:GEL|NUM:S
IZE	ZKI	BIZ:-|KAS:GEL|NUM:S|MUG:M
IZE	ZKI	KAS:ABL|NUM:P
IZE	ZKI	KAS:ABL|NUM:P|MUG:M
IZE	ZKI	KAS:ABL|NUM:S
IZE	ZKI	KAS:ABL|NUM:S|ENT:Tokia
IZE	ZKI	KAS:ABL|NUM:S|MUG:M
IZE	ZKI	KAS:ABL|NUM:S|MUG:M|ENT:Tokia
IZE	ZKI	KAS:ABS
IZE	ZKI	KAS:ABS|MUG:MG
IZE	ZKI	KAS:ABS|NUM:P
IZE	ZKI	KAS:ABS|NUM:P|MUG:M
IZE	ZKI	KAS:ABS|NUM:P|MUG:M|POS:POSarte|POS:+
IZE	ZKI	KAS:ABS|NUM:S
IZE	ZKI	KAS:ABS|NUM:S|MUG:M
IZE	ZKI	KAS:ABS|NUM:S|MUG:M|POS:POSarte|POS:+
IZE	ZKI	KAS:ABS|POS:POSarte|POS:+
IZE	ZKI	KAS:ABU|NUM:S
IZE	ZKI	KAS:ABU|NUM:S|MUG:M
IZE	ZKI	KAS:ALA|NUM:P
IZE	ZKI	KAS:ALA|NUM:P|MUG:M
IZE	ZKI	KAS:ALA|NUM:P|MUG:M|POS:POSaldera|POS:+
IZE	ZKI	KAS:ALA|NUM:P|MUG:M|POS:POSaurrera|POS:+
IZE	ZKI	KAS:ALA|NUM:S
IZE	ZKI	KAS:ALA|NUM:S|MUG:M
IZE	ZKI	KAS:ALA|NUM:S|MUG:M|POS:POSaldera|POS:+
IZE	ZKI	KAS:ALA|NUM:S|MUG:M|POS:POSaurrera|POS:+
IZE	ZKI	KAS:DAT
IZE	ZKI	KAS:DAT|MUG:MG
IZE	ZKI	KAS:DAT|NUM:P
IZE	ZKI	KAS:DAT|NUM:PH|MUG:M
IZE	ZKI	KAS:EM
IZE	ZKI	KAS:EM|MUG:MG|POS:POSgisan|POS:+
IZE	ZKI	KAS:EM|NUM:S
IZE	ZKI	KAS:EM|NUM:S|MUG:M|POS:POSaurrera|POS:+
IZE	ZKI	KAS:EM|NUM:S|MUG:M|POS:POSgeroztik|POS:+
IZE	ZKI	KAS:EM|NUM:S|MUG:M|POS:POSgora|POS:+
IZE	ZKI	KAS:EM|POS:POSgora|POS:+
IZE	ZKI	KAS:ERG
IZE	ZKI	KAS:ERG|MUG:MG
IZE	ZKI	KAS:ERG|NUM:P
IZE	ZKI	KAS:ERG|NUM:P|MUG:M
IZE	ZKI	KAS:ERG|NUM:S
IZE	ZKI	KAS:ERG|NUM:S|MUG:M
IZE	ZKI	KAS:GEL|NUM:P
IZE	ZKI	KAS:GEL|NUM:P|MUG:M
IZE	ZKI	KAS:GEL|NUM:P|MUG:M|POS:POSbitarteko|POS:+
IZE	ZKI	KAS:GEL|NUM:S
IZE	ZKI	KAS:GEL|NUM:S|ENT:Tokia
IZE	ZKI	KAS:GEL|NUM:S|MUG:M
IZE	ZKI	KAS:GEL|NUM:S|MUG:M|ENT:Tokia
IZE	ZKI	KAS:GEL|NUM:S|MUG:M|MW:B
IZE	ZKI	KAS:GEL|NUM:S|MUG:M|POS:POSbitarteko|POS:+
IZE	ZKI	KAS:GEL|NUM:S|MUG:M|POS:POSgorako|POS:+
IZE	ZKI	KAS:GEN|NUM:P
IZE	ZKI	KAS:GEN|NUM:P|MUG:M
IZE	ZKI	KAS:GEN|NUM:S
IZE	ZKI	KAS:GEN|NUM:S|MUG:M
IZE	ZKI	KAS:INE
IZE	ZKI	KAS:INE|NUM:P
IZE	ZKI	KAS:INE|NUM:P|MUG:M
IZE	ZKI	KAS:INE|NUM:P|MUG:M|POS:POSbitartean|POS:+
IZE	ZKI	KAS:INE|NUM:S
IZE	ZKI	KAS:INE|NUM:S|ENT:Erakundea
IZE	ZKI	KAS:INE|NUM:S|ENT:Tokia
IZE	ZKI	KAS:INE|NUM:S|MUG:M
IZE	ZKI	KAS:INE|NUM:S|MUG:M|ENT:Erakundea
IZE	ZKI	KAS:INE|NUM:S|MUG:M|ENT:Tokia
IZE	ZKI	KAS:INE|NUM:S|MUG:M|POS:POSbitartean|POS:+
IZE	ZKI	KAS:INE|POS:POSaldean|POS:+
IZE	ZKI	KAS:INE|POS:POSbitartean|POS:+
IZE	ZKI	KAS:INS|NUM:S
IZE	ZKI	KAS:INS|NUM:S|MUG:M
IZE	ZKI	KAS:PAR
IZE	ZKI	KAS:PAR|MUG:MG
IZE	ZKI	KAS:SOZ
IZE	ZKI	KAS:SOZ|MUG:MG
IZE	ZKI	_
LOT	JNT	ERL:AURK
LOT	JNT	ERL:AURK|MW:B
LOT	JNT	ERL:EMEN
LOT	JNT	ERL:EMEN|MW:B
LOT	JNT	ERL:HAUT
LOT	JNT	_
LOT	LOK	ERL:AURK
LOT	LOK	ERL:AURK|MW:B
LOT	LOK	ERL:BALD
LOT	LOK	ERL:BALD|MW:B
LOT	LOK	ERL:DENB|MW:B
LOT	LOK	ERL:EMEN
LOT	LOK	ERL:EMEN|MW:B
LOT	LOK	ERL:ESPL
LOT	LOK	ERL:ESPL|MW:B
LOT	LOK	ERL:HAUT
LOT	LOK	ERL:KAUS
LOT	LOK	ERL:KAUS|KLM:HAS
LOT	LOK	ERL:KAUS|MW:B
LOT	LOK	ERL:KONT
LOT	LOK	ERL:KONT|MW:B
LOT	LOK	ERL:MOD/DENB|MW:B
LOT	LOK	ERL:MOD|MW:B
LOT	LOK	ERL:ONDO
LOT	LOK	ERL:ONDO|MW:B
LOT	LOK	_
LOT	MEN	ERL:DENB|MW:B
LOT	MEN	ERL:KAUS|KLM:AM
LOT	MEN	ERL:KONT
PRT	PRT	ERL:KONPL|MOD:EGI
PRT	PRT	MOD:EGI
PRT	PRT	MOD:ZIU
PRT	PRT	_
PUNT_MARKA	PUNT_BI_PUNT	_
PUNT_MARKA	PUNT_ESKL	_
PUNT_MARKA	PUNT_GALD	_
PUNT_MARKA	PUNT_HIRU	_
PUNT_MARKA	PUNT_KOMA	_
PUNT_MARKA	PUNT_PUNT	_
PUNT_MARKA	PUNT_PUNT_KOMA	_
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

Lingua::Interset::Tagset::EU::Conll - Driver for the tagset of the Basque Dependency Treebank in the CoNLL format.

=head1 VERSION

version 3.005

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::EU::Conll;
  my $driver = Lingua::Interset::Tagset::EU::Conll->new();
  my $fs = $driver->decode("IZE\tARR\tBIZ:+|KAS:ABS|NUM:S|MUG:M");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('eu::conll', "IZE\tARR\tBIZ:+|KAS:ABS|NUM:S|MUG:M");

=head1 DESCRIPTION

Interset driver for the tagset of the Basque Dependency Treebank version 2011
in the CoNLL format. Note that this version of the tagset is slightly different
from the Basque data of the CoNLL 2007 Shared Task. For instance, the features
now contain feature names, thus we have 'KAS:ABS' for the absolutive case,
not only 'ABS'.

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
