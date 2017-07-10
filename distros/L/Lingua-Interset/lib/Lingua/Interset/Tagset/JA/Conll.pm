# ABSTRACT: Driver for the Japanese tagset of the CoNLL 2006 Shared Task (derived from the TüBa J/S Verbmobil treebank).
# Copyright © 2011, 2012, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Copyright © 2011 Loganathan Ramasamy <ramasamy@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::JA::Conll;
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
    return 'ja::conll';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # PART OF SPEECH ####################
    # /net/data/conll/2006/ja/doc/fine2coarse.table
    $atoms{pos} = $self->create_atom
    (
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # to, su, shi, o, i; e.g. "to" could be also ITJ, P, PQ, Pcnj, PSSa
            '--'         => [],
            '.'          => ['pos' => 'punc', 'punctype' => 'peri'], # sentence-final punctuation (.)
            ','          => ['pos' => 'punc', 'punctype' => 'comm'], # comma (,)
            '?'          => ['pos' => 'punc', 'punctype' => 'qest'], # question mark (?)
            # adjective other (onaji, iroNna, taishita, iroirona, korekorekouiu)
            'ADJ'        => ['pos' => 'adj'],
            # adjective demonstrative (sono, kono, koNna, soNna, ano)
            'ADJdem'     => ['pos' => 'adj', 'prontype' => 'dem'],
            # adjective conditional (-reba, -tara) (yoroshikereba, nakereba, yokereba, chikakereba, takakunakereba) [yoroshikereba = if you please]
            'ADJicnd'    => ['pos' => 'adj', 'mood' => 'cnd', 'other' => {'adjtype' => 'i'}],
            # i-adjective, -i ending (yoroshii, ii, nai, chikai, osoi) [yoroshii = good]
            'ADJifin'    => ['pos' => 'adj', 'verbform' => 'fin', 'other' => {'adjtype' => 'i'}],
            # Finite adjective can also occur with the feature "ta" (yokatta, yoroshikatta, tookatta, nakatta) [yokatta = was good].
            # i-adjective, -ku ending (yoroshiku, arigatou, ohayou, hayaku, yoku)
            # These are actually adverbs derived from adjectives.
            # [adverb; yoroshiku = well, properly; best regards ("please treat me favourably")]
            'ADJiku'     => ['pos' => 'adv', 'other' => {'adjtype' => 'i', 'advtype' => 'ku'}],
            # i-adjective, -kute ending (nakute, chikakute, yasukute, takakute, yokute)
            # [converb/transgressive/participle form of adjective; str. 74]
            'ADJite'     => ['pos' => 'adv', 'verbform' => 'conv', 'other' => {'adjtype' => 'i', 'advtype' => 'kute'}],
            # n-adjective, concatenating "-na; PV" (daijoubu, kekkou, beNri, hajimete, muri) [daijoubu = safe; all right; kekkou = nice, fine]
            'ADJ_n'      => ['pos' => 'adj', 'other' => {'adjtype' => 'n'}],
            # adjectival suffix "na" (na) [dame na = bad]
            'ADJsf'      => ['pos' => 'adj', 'other' => {'adjtype' => 'sf'}],
            # adjective, -teki ending (jikaNteki, gutaiteki, kojiNteki, nedaNteki, nitteiteki) [-teki = -like; jikaNteki = time-like, temporal]
            'ADJteki'    => ['pos' => 'adj', 'other' => {'adjtype' => 'teki'}],
            # adjective interrogative (dono, doNna, douitta, douiu) [dono = which, what, how]
            'ADJwh'      => ['pos' => 'adj', 'prontype' => 'int'],
            # adverb (chotto, mou, mata, dekireba, daitai) [chotto = just a minute; mou = more, already; mata = moreover]
            'ADV'        => ['pos' => 'adv'],
            # adverb demonstrative (sou, kou, so) [sou = so]
            'ADVdem'     => ['pos' => 'adv', 'prontype' => 'dem'],
            # adverb of degree (ichibaN, sukoshi, chotto, amari, soNnani) [ichibaN = best, first]
            'ADVdgr'     => ['pos' => 'adv', 'advtype' => 'deg'],
            # adverb of time, not numeric (mazu, sassoku, sakihodo, sakki, toriaezu) [mazu = first; sassoku = immediately; sakihodo = not long ago, just now]
            'ADVtmp'     => ['pos' => 'adv', 'advtype' => 'tim'],
            # adverb interrogative (dou, ikaga, doushite) [dou, ikaga = how, in what way]
            'ADVwh'      => ['pos' => 'adv', 'prontype' => 'int'],
            # cardinal numeral (ichi, ni, saN, hyaku) [ichi = one, ni = two, saN = three]
            'CD'         => ['pos' => 'num', 'numtype' => 'card'],
            # cardinal numeral with unit [CD-shitsu, biN, kiro] (mittsu, hitotsu, ichinichi, futatsu, ichido)
            'CDU'        => ['pos' => 'num', 'numtype' => 'card', 'other' => {'numtype' => 'unit'}],
            # cardinal numeral with date unit (juugatsu, juuninichi, nigatsu, tooka, mikka) [juugatsu = ten-month, October; juuninichi = twelve-day, twelfth day of the month]
            'CDdate'     => ['pos' => 'adv', 'advtype' => 'tim', 'other' => {'advtype' => 'date'}],
            # cardinal numeral with time unit (gojuppuN, juuichiji, juuji, saNjuugofuN, juugofuN) [gojuppuN = fifty minutes; juuichiji = eleven o'clock]
            'CDtime'     => ['pos' => 'adv', 'advtype' => 'tim', 'other' => {'advtype' => 'time'}],
            # conjunction, sentence-initial or between nominals (dewa, de, soredewa, ato, soshitara) [soredewa = now, so; ato = after]
            'CNJ'        => ['pos' => 'conj'],
            # greeting [koNnichiwa = hello; otsukaresama = thank you very much; sayounara = good bye]
            'GR'         => ['pos' => 'int', 'other' => {'inttype' => 'greeting'}],
            # interjection (hai, ee, to, e, a) [hai = yes]
            'ITJ'        => ['pos' => 'int'],
            # formal noun (hou, no, koto, nano, naN) [watakushi no hou = on my part, my way (watakushi = I)]
            'NF'         => ['pos' => 'noun', 'other' => {'nountype' => 'formal'}],
            # common noun (hoteru = hotel, biN = jar, hikouki = airplane, shiNguru = single, kaeri = return)
            'NN'         => ['pos' => 'noun', 'nountype' => 'com'],
            # demonstrative pronoun (sore = that, kochira = here, sochira = there, kore = this, soko = there)
            'Ndem'       => ['pos' => 'noun', 'prontype' => 'dem'],
            # suffix to nominal phrase (hatsu, chaku, gurai, keiyu, hodo) [hatsu = departure, chaku = arrival, keiyu = via] [NP(furaNkufuruto/NAMEloc/COMP keiyu/Nsf/HD) = via Frankfurt]
            'Nsf'        => ['pos' => 'noun', 'other' => {'nountype' => 'sf'}],
            # temporal noun (ima = now, hi = day, asa = morning, yuugata = evening, koNdo = this time)
            'Ntmp'       => ['pos' => 'noun', 'advtype' => 'tim'],
            # another tag for temporal noun? (kayoubi = Tuesday, getsuyoubi = Monday, suiyoubi = Wednesday, gogo = afternoon, kiNyoubi = Friday)
            'NT'         => ['pos' => 'noun', 'advtype' => 'tim', 'other' => {'nountype' => 'weekday'}],
            # interrogative pronoun (dochira = where, itsu = when, naNji = what time, dore = which, docchi = which way, which one)
            'Nwh'        => ['pos' => 'noun', 'prontype' => 'int'],
            # personal pronoun (watashi = I, watakushi = I, boku = I, atashi = I, atakushi = I)
            'PRON'       => ['pos' => 'noun', 'prontype' => 'prs'],
            # verbal (predicative) noun, VN-suru = make-VN (onegai, shuppatsu, yoyaku, kaNkou, shuchhou) [onegai = please; shuppatsu = departure; yoyaku = reservation]
            'VN'         => ['pos' => 'noun', 'other' => {'nountype' => 'lightverb'}],
            # proper noun (doNjobaNni = Don Giovanni, kurisumasu, zeNnikkuubiN, omamori, nihoNkoukuubiN)
            'NAME'       => ['pos' => 'noun', 'nountype' => 'prop'],
            # name of location (hanoofaa = Hannover, doitsu = Germany, kaNkuu = Kansai International Airport, furaNkufuruto = Frankfurt, roNdoN = London)
            'NAMEloc'    => ['pos' => 'noun', 'nountype' => 'prop', 'nametype' => 'geo'],
            # name of organization (rufutohaNza = Lufthansa; jaru = JAL, Japan Airlines; rufutohaNzakoukuu, nihoNkoukuu, zeNnikkuu)
            'NAMEorg'    => ['pos' => 'noun', 'nountype' => 'prop', 'nametype' => 'com'],
            # name of person (matsumoto, miyake, kitahara, yoshikawa, tsutsui)
            'NAMEper'    => ['pos' => 'noun', 'nountype' => 'prop', 'nametype' => 'prs'],
            # postposition / particle [np];[pp] (ni, de, kara, made, to)
            'P'          => ['pos' => 'adp', 'adpostype' => 'post'],
            # adjectival particle [vp];[ap] (youna, you, mitai, rashii, sou)
            # PADJ also occurs with the feature 'kute' (the only form is rashikute)
            'PADJ'       => ['pos' => 'adp', 'adpostype' => 'post', 'other' => {'parttype' => 'adj'}],
            # adverbial particle [vp];[ap] (youni, fuuni, shidai, nagara, hodo)
            'PADV'       => ['pos' => 'adp', 'adpostype' => 'post', 'other' => {'parttype' => 'adv'}],
            # title suffix to personal name: okamoto saN = Mr./Ms. Okamoto
            # (saN, sama)
            'PNsf'       => ['pos' => 'noun', 'other' => {'nountype' => 'title'}],
            # particle of quotation (to, te, naNte, toka, ka, tte)
            'PQ'         => ['pos' => 'adp', 'adpostype' => 'post', 'other' => {'parttype' => 'quot'}],
            # accusative particle [np] (o)
            'Pacc'       => ['pos' => 'adp', 'adpostype' => 'post', 'case' => 'acc'],
            # coordinating conjunction / particle (to = and; ka, ya = or; toka, nari)
            'Pcnj'       => ['pos' => 'conj', 'conjtype' => 'coor'],
            # focus particle (wa, mo, demo, koso, nara, sae)
            'Pfoc'       => ['pos' => 'adp', 'adpostype' => 'post', 'other' => {'parttype' => 'focus'}],
            # genitive particle [np] (no)
            'Pgen'       => ['pos' => 'adp', 'adpostype' => 'post', 'case' => 'gen'],
            # nominative particle [np] (ga)
            'Pnom'       => ['pos' => 'adp', 'adpostype' => 'post', 'case' => 'nom'],
            # S-end (clause-final) particle (ka, ne, yo, na, kana)
            'PSE'        => ['pos' => 'part', 'other' => {'parttype' => 'send'}],
            # S-conjunctive particle "and" (node, to, shi, kara, nanode)
            'PSSa'       => ['pos' => 'part', 'other' => {'parttype' => 'sand'}],
            # S-conjunctive particle "but" (ga, keredomo, kedo, kedomo, keredo)
            'PSSb'       => ['pos' => 'part', 'other' => {'parttype' => 'sbut'}],
            # S-conjunctive particle question (ka)
            'PSSq'       => ['pos' => 'part', 'other' => {'parttype' => 'qest'}],
            # What they call "particle verb" is regarded by other authors a copula ("to be").
            # particle verb+cond (deshitara, dattara, deshitaraba)
            'PVcnd'      => ['pos' => 'verb', 'verbtype' => 'cop', 'verbform' => 'fin', 'mood' => 'cnd'],
            # particle verb+tens (feature ta: da, deshita, datta; feature u: desu, deshou, darou)
            'PVfin'      => ['pos' => 'verb', 'verbtype' => 'cop', 'verbform' => 'fin', 'mood' => 'ind'],
            # particle verb-tens (de, deshite)
            'PVte'       => ['pos' => 'verb', 'verbtype' => 'cop', 'verbform' => 'conv'],
            # noun prefix (yaku, dai, yoku, maru, Frau)
            'PreN'       => ['pos' => 'noun', 'other' => {'nountype' => 'pref'}],
            # unit (maruku, biN, meetoru, kiro, shitsu) [maruku = mark, meetoru = meter, kiro = kilo]
            'UNIT'       => ['pos' => 'noun', 'other' => {'nountype' => 'unit'}],
            # verb-tense (ittari, nitari, tomarezu, shirabetari, tanoshimetari) [ittari = and go; nitari = barge]
            'V'          => ['pos' => 'verb'],
            # verb-tense, stem and 1st/2nd/5th base (mi, tore, nomi, kimari, kiki, tabe) [mi = look at, tabe = eat]
            'Vbas'       => ['pos' => 'verb', 'other' => {'verbform' => 'base'}],
            # verb conditional (shimashitara, shitara, areba, arimashitara, dekimashitara) [str. 160]
            'Vcnd'       => ['pos' => 'verb', 'mood' => 'cnd'],
            # finite verb + tense (-ru, -ta, -masu, -maseN)
            # Finite verbs occur with three different features:
            # eN (sumimaseN, arimaseN, kamaimaseN, suimaseN, shiremaseN) [honorific negative future] [str. 61]
            # ta (wakarimashita, gozaimashita, itta, kashikomarimashita, hanareta) [past] [str. 61]
            # u (iu, aru, arimasu, narimasu, omoimasu) [present or afirmative future?] [str. 61]
            'Vfin'       => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'ind'],
            # verb imperative (gomeNnasai, kudasai, ie, nome, shiro, kimero) [gomeNnasai = pardon me; kudasai = please do]
            'Vimp'       => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'imp'],
            # verb tense, -te/-de ending [transgressive?] (aite, shite, tsuite, natte, arimashite) [str. 73]
            'Vte'        => ['pos' => 'verb', 'verbform' => 'conv'],
            # Verbal adjectives
            # -sou verbal adjective [str. 153]
            # (ikesou, arisou, toresou, owarisou, awanasasou)
            # [dono atari ikesou desu ka = how do I go around]
            'VADJ_n'     => ['pos' => 'adj', 'other' => {'adjtype' => 'vn'}],
            # -nai/-tai verbal adjective [str. 67]
            # (shitai, mitai, ikitai, kimetai, itadakitai)
            'VADJi'      => ['pos' => 'adj', 'other' => {'adjtype' => 'vi'}],
            # VADJi can also occur with the feature 'kute' (kimenakute, ikanakute, noranakute, wakaranakute, okanakute)
            # VADJi can also occur with the feature 'ta' (inakatta, ikitakatta, kiitenakatta, dekinakatta)
            # verbal adjective conditional -nakereba (shinakereba, konakereba, ikanakereba, sashitsukaenakereba, iwanakereba) [shinakereba = unless one does something]
            'VADJicnd'   => ['pos' => 'adj', 'mood' => 'cnd', 'other' => {'adjtype' => 'vicnd'}],
            # auxiliary verb - tense (mitari, shimattari) [str. 181]
            'VAUX'       => ['pos' => 'verb', 'verbtype' => 'aux'],
            # auxiliary verb - tense (itadaki) [itadaku = to take]
            'VAUXbas'    => ['pos' => 'verb', 'verbtype' => 'aux', 'other' => {'verbform' => 'base'}],
            # auxiliary verb conditional (itadakereba, okanakereba, itadaitara, itadakimashitara, mitara)
            'VAUXcnd'    => ['pos' => 'verb', 'verbtype' => 'aux', 'mood' => 'cnd'],
            # finite auxiliary verb +tense following V (iru, ita, kuru, shimau)
            # Finite auxiliary verbs occur with three different features:
            # eN (imaseN, orimaseN, mimaseN, itadakemaseN, shimaimaseN)
            # ta (ita, mita, imashita, kita, oita, itadaita)
            # u (iru, okimasu, imasu, orimasu, itadakimasu)
            'VAUXfin'    => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'fin', 'mood' => 'ind'],
            # finite auxiliary verb imperative (kudasai, kure)
            'VAUXimp'    => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'fin', 'mood' => 'imp'],
            # auxiliary verb -tense -te/-de ending transgressive (imashite, orimashite, itadaite, oite, shimatte)
            'VAUXte'     => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'conv'],
            # Support verb (light verb) "suru"
            # support verb -tense VN (shitari, shinagara)
            'VS'         => ['pos' => 'verb', 'verbtype' => 'light'],
            # support verb -tense VN (shi)
            'VSbas'      => ['pos' => 'verb', 'verbtype' => 'light', 'other' => {'verbform' => 'base'}],
            # support verb conditional (dekireba, sureba, dekitara, dekimashitara, shitara)
            'VScnd'      => ['pos' => 'verb', 'verbtype' => 'light', 'mood' => 'cnd'],
            # finite support verb +tense VN (suru, shita)
            # Finite support verbs occur with three different features:
            # eN (shimaseN)
            # ta (shita, shimashita, itashimashita, sareta, dekita)
            # u (shimasu, itashimasu, suru, dekimasu, shimashou, dekiru)
            'VSfin'      => ['pos' => 'verb', 'verbtype' => 'light', 'verbform' => 'fin', 'mood' => 'ind'],
            # finite support verb imperative (shiro)
            'VSimp'      => ['pos' => 'verb', 'verbtype' => 'light', 'verbform' => 'fin', 'mood' => 'imp'],
            # support verb -tense, -te ending transgressive (shite, sasete, shimashite, sashite, sarete, itashimashite)
            'VSte'       => ['pos' => 'verb', 'verbtype' => 'light', 'verbform' => 'conv'],
            'xxx'        => [], # segmentation problem
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''    => { 'nountype' => { 'prop' => { 'nametype' => { 'geo' => 'NAMEloc',
                                                                                                          'com' => 'NAMEorg',
                                                                                                          'prs' => 'NAMEper',
                                                                                                          '@'   => 'NAME' }},
                                                                              '@'    => { 'other/nountype' => { 'formal'    => 'NF',
                                                                                                                'sf'        => 'Nsf',
                                                                                                                'lightverb' => 'VN',
                                                                                                                'weekday'   => 'NT',
                                                                                                                'title'     => 'PNsf',
                                                                                                                'unit'      => 'UNIT',
                                                                                                                'pref'      => 'PreN',
                                                                                                                '@'         => { 'advtype' => { 'tim' => 'Ntmp',
                                                                                                                                                '@'   => 'NN' }}}}}},
                                                   'prs' => 'PRON',
                                                   'dem' => 'Ndem',
                                                   'int' => 'Nwh' }},
                       'adj'  => { 'prontype' => { ''    => { 'other/adjtype' => { 'i'    => { 'mood' => { 'cnd' => 'ADJicnd',
                                                                                                           '@'   => { 'verbform' => { 'conv' => 'ADJite',
                                                                                                                                      'part' => 'ADJite',
                                                                                                                                      '@'    => 'ADJifin' }}}},
                                                                                   'n'    => 'ADJ_n',
                                                                                   'sf'   => 'ADJsf',
                                                                                   'teki' => 'ADJteki',
                                                                                   'vi'   => 'VADJi',
                                                                                   'vicnd'=> 'VADJicnd',
                                                                                   'vn'   => 'VADJ_n',
                                                                                   '@'    => { 'tense' => { 'past' => 'ADJifin',
                                                                                                            '@'    => 'ADJ' }}}},
                                                   'dem' => 'ADJdem',
                                                   'int' => 'ADJwh' }},
                       'num'  => { 'other/numtype' => { 'unit' => 'CDU',
                                                        '@'    => 'CD' }},
                       'verb' => { 'verbtype' => { 'cop'   => { 'mood' => { 'cnd' => 'PVcnd',
                                                                            '@'   => { 'verbform' => { 'conv' => 'PVte',
                                                                                                       'part' => 'PVte',
                                                                                                       '@'    => 'PVfin' }}}},
                                                   'aux'   => { 'mood' => { 'cnd' => 'VAUXcnd',
                                                                            'imp' => 'VAUXimp',
                                                                            '@'   => { 'verbform' => { 'conv' => 'VAUXte',
                                                                                                       'part' => 'VAUXte',
                                                                                                       'fin'  => 'VAUXfin',
                                                                                                       '@'    => { 'other/verbform' => { 'base' => 'VAUXbas',
                                                                                                                                         '@'    => 'VAUX' }}}}}},
                                                   'light' => { 'mood' => { 'cnd' => 'VScnd',
                                                                            'imp' => 'VSimp',
                                                                            '@'   => { 'verbform' => { 'conv' => 'VSte',
                                                                                                       'part' => 'VSte',
                                                                                                       'fin'  => 'VSfin',
                                                                                                       '@'    => { 'other/verbform' => { 'base' => 'VSbas',
                                                                                                                                         '@'    => 'VS' }}}}}},
                                                   '@'     => { 'mood' => { 'cnd' => 'Vcnd',
                                                                            'imp' => 'Vimp',
                                                                            '@'   => { 'verbform' => { 'conv' => 'Vte',
                                                                                                       'part' => 'Vte',
                                                                                                       'fin'  => 'Vfin',
                                                                                                       '@'    => { 'other/verbform' => { 'base' => 'Vbas',
                                                                                                                                         '@'    => 'V' }}}}}}}},
                       'adv'  => { 'prontype' => { ''    => { 'advtype' => { 'deg' => 'ADVdgr',
                                                                             'tim' => { 'other/advtype' => { 'date' => 'CDdate',
                                                                                                             'time' => 'CDtime',
                                                                                                             '@'    => 'ADVtmp' }},
                                                                             '@'   => { 'other/advtype' => { 'ku'   => 'ADJiku',
                                                                                                             'kute' => 'ADJite',
                                                                                                             '@'    => 'ADV' }}}},
                                                   'dem' => 'ADVdem',
                                                   'int' => 'ADVwh' }},
                       'adp'  => { 'other/parttype' => { 'adj'   => 'PADJ',
                                                         'adv'   => 'PADV',
                                                         'quot'  => 'PQ',
                                                         'focus' => 'Pfoc',
                                                         '@'     => { 'verbform' => { 'conv' => 'PADJ',
                                                                                      '@'    => { 'case' => { 'acc' => 'Pacc',
                                                                                                              'gen' => 'Pgen',
                                                                                                              'nom' => 'Pnom',
                                                                                                              '@'   => 'P' }}}}}},
                       'conj' => { 'conjtype' => { 'coor' => 'Pcnj',
                                                   '@'    => 'CNJ' }},
                       'part' => { 'other/parttype' => { 'send' => 'PSE',
                                                         'sand' => 'PSSa',
                                                         'sbut' => 'PSSb',
                                                         'qest' => 'PSSq',
                                                         '@'    => 'PSE' }},
                       'int'  => { 'other/inttype' => { 'greeting' => 'GR',
                                                        '@'        => 'ITJ' }},
                       'punc' => { 'punctype' => { 'peri' => '.',
                                                   'qest' => '?',
                                                   '@'    => ',' }},
                       '@'    => 'xxx' }
        }
    );
    # FEATURE ####################
    # Most tags do not have features.
    # Those who have, have only one of four possible feature values: eN, kute, ta, u
    $atoms{feature} = $self->create_atom
    (
        'surfeature' => 'feature',
        'decode_map' =>
        {
            # eN is the suffix of the honorific negative future [str. 61]
            # It occurs with the tags Vfin, VAUXfin, VSfin.
            # examples:
            # sumimaseN, arimaseN, kamaimaseN, suimaseN, shiremaseN
            # yomimaseN = will not read
            'eN' => ['tense' => 'fut', 'polarity' => 'neg', 'polite' => 'form'],
            # ta is the suffix of the past tense (this includes the honorific "shita") [str. 61]
            # It occurs with the tags ADJifin, PVfin, Vfin, VADJi, VAUXfin, VSfin.
            # examples:
            # wakarimashita, gozaimashita, itta, kashikomarimashita, hanareta
            # yomimashita = did read, yomimaseNdeshita = did not read
            'ta' => ['tense' => 'past'],
            # u is the infinitive (citation form) suffix; masu (affirmative future and present) is also included here [str. 61]
            # It occurs with the tags PVfin, Vfin, VAUXfin, VSfin.
            # examples:
            # iu, aru, arimasu, narimasu, omoimasu
            # yomu = to read, yomimasu = will read
            'u'  => ['tense' => 'pres|fut'],
            # kute is the transgressive suffix for adjectives [str. 74]
            # In fact it is the suffix 'ku' that converts adjectives to adverbs, then 'te' that makes participles (cs:přechodník) from verbs, and here, from adjectives/adverbs.
            # It occurs with the tags PADJ, VADJi.
            # It does not occur with ADJ*! The ADJite subpos tag is used instead.
            # It does not occur with PV*! The PVte subpos tag is used instead.
            # examples:
            # nakute, chikakute, yasukute, takakute, yokute
            'kute' => ['other' => {'kute' => 'yes'}]
        },
        'encode_map' =>
        {
            'other/kute' => { 'yes' => 'kute',
                              '@'     => { 'polarity' => { 'neg' => 'eN',
                                                           '@'   => { 'tense' => { 'past' => 'ta',
                                                                                   'pres' => 'u',
                                                                                   'fut'  => 'u' }}}}}
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
    my @features = ('feature');
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
        '@'  => []
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
    $fs->set_tagset('ja::conll');
    my $atoms = $self->atoms();
    # Three components: pos, subpos, features.
    # example: N\tNN\t_
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
    # POS tags available: -- . ADJ ADV CD CNJ GR ITJ N NAME NT P PS PUNC PV PreN UNIT V VADJ VAUX VS xxx
    # We do not encode '--', we merge it with 'xxx'.
    my @postags = ('ADJ', 'ADV', 'CD', 'CNJ', 'GR', 'ITJ', 'NAME', 'NT', 'N', 'PreN', 'PUNC', 'PS', 'PV', 'P', 'UNIT', 'VADJ', 'VAUX', 'VS', 'V', 'xxx');
    my $pos = $subpos eq '.' ? '.' : 'xxx';
    if($subpos =~ m/^(PRON|VN)$/)
    {
        $pos = 'N';
    }
    elsif($subpos =~ m/^[,?]$/)
    {
        $pos = 'PUNC';
    }
    else
    {
        foreach my $p (@postags)
        {
            if($subpos =~ m/^$p/)
            {
                $pos = $p;
                last;
            }
        }
    }
    my $feature = $atoms->{feature}->encode($fs);
    $feature = '_' if($feature eq '');
    my $tag = "$pos\t$subpos\t$feature";
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus, 91 tags found.
# After cleaning: 90
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
.	.	_
ADJ	ADJ	_
ADJ	ADJ_n	_
ADJ	ADJdem	_
ADJ	ADJicnd	_
ADJ	ADJifin	_
ADJ	ADJifin	ta
ADJ	ADJiku	_
ADJ	ADJite	_
ADJ	ADJsf	_
ADJ	ADJteki	_
ADJ	ADJwh	_
ADV	ADV	_
ADV	ADVdem	_
ADV	ADVdgr	_
ADV	ADVtmp	_
ADV	ADVwh	_
CD	CD	_
CD	CDU	_
CD	CDdate	_
CD	CDtime	_
CNJ	CNJ	_
GR	GR	_
ITJ	ITJ	_
N	NF	_
N	NN	_
N	Ndem	_
N	Nsf	_
N	Ntmp	_
N	Nwh	_
N	PRON	_
N	VN	_
NAME	NAME	_
NAME	NAMEloc	_
NAME	NAMEorg	_
NAME	NAMEper	_
NT	NT	_
P	P	_
P	PADJ	_
P	PADJ	kute
P	PADV	_
P	PNsf	_
P	PQ	_
P	Pacc	_
P	Pcnj	_
P	Pfoc	_
P	Pgen	_
P	Pnom	_
PS	PSE	_
PS	PSSa	_
PS	PSSb	_
PS	PSSq	_
PUNC	,	_
PUNC	?	_
PV	PVcnd	_
PV	PVfin	ta
PV	PVfin	u
PV	PVte	_
PreN	PreN	_
UNIT	UNIT	_
V	V	_
V	Vbas	_
V	Vcnd	_
V	Vfin	eN
V	Vfin	ta
V	Vfin	u
V	Vimp	_
V	Vte	_
VADJ	VADJ_n	_
VADJ	VADJi	_
VADJ	VADJi	kute
VADJ	VADJi	ta
VADJ	VADJicnd	_
VAUX	VAUX	_
VAUX	VAUXbas	_
VAUX	VAUXcnd	_
VAUX	VAUXfin	eN
VAUX	VAUXfin	ta
VAUX	VAUXfin	u
VAUX	VAUXimp	_
VAUX	VAUXte	_
VS	VS	_
VS	VSbas	_
VS	VScnd	_
VS	VSfin	eN
VS	VSfin	ta
VS	VSfin	u
VS	VSimp	_
VS	VSte	_
xxx	xxx	_
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

Lingua::Interset::Tagset::JA::Conll - Driver for the Japanese tagset of the CoNLL 2006 Shared Task (derived from the TüBa J/S Verbmobil treebank).

=head1 VERSION

version 3.005

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::JA::Conll;
  my $driver = Lingua::Interset::Tagset::JA::Conll->new();
  my $fs = $driver->decode("N\tNN\t_");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('ja::conll', "N\tNN\t_");

=head1 DESCRIPTION

Interset driver for the Japanese tagset of the CoNLL 2006 Shared Task.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT. For Japanese,
these values are derived from the tagset of the TüBa J/S Verbmobil
treebank (Universität Tübingen).

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
