# ABSTRACT: Driver for the Hungarian tagset of the CoNLL 2007 Shared Task (derived from the Szeged Treebank).
# Copyright © 2011, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::HU::Conll;
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
    return 'hu::conll';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
# /net/data/conll/2007/hu/doc/README
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
            'Af' => ['pos' => 'adj'],
            'Cc' => ['pos' => 'conj', 'conjtype' => 'coor'], # és, is, s, de, vagy
            'Cs' => ['pos' => 'conj', 'conjtype' => 'sub'], # hogy, mint, ha, mert
            'I'  => ['pos' => 'int'],
            'Io' => ['pos' => 'int', 'other' => {'single_word_sentence' => 'yes'}], # single word sentence
            'Mc' => ['pos' => 'num', 'numtype' => 'card'], # cardinal numeral
            'Md' => ['pos' => 'num', 'numtype' => 'dist'], # distributive numeral
            'Mf' => ['pos' => 'num', 'numtype' => 'frac'], # fractal numeral
            'Mo' => ['pos' => 'adj', 'numtype' => 'ord'], # ordinal numeral
            'Nc' => ['pos' => 'noun', 'nountype' => 'com'], # common noun
            'Np' => ['pos' => 'noun', 'nountype' => 'prop'], # proper noun
            'O'  => [], # other tokens (e-mail or web address)
            'Oh' => ['hyph' => 'yes'], # words ending in hyphens
            'Oi' => ['pos' => 'noun', 'other' => {'nountype' => 'identifier'}], # identifier: R99, V-3
            'On' => ['pos' => 'num', 'numform' => 'digit'], # numbers written in digits: 6:2, 4:2-re
            'Pd' => ['pos' => 'adj',  'prontype' => 'dem'], # az = the, ez = this, olyan = such
            'Pg' => ['pos' => 'noun', 'prontype' => 'tot|neg'], # general pronoun: minden = all, mindenki = everyone, semmi = nothing, senki = no one
            'Pi' => ['pos' => 'adj',  'prontype' => 'ind'], # egyik = one, más = other, néhány = some, másik = other, valaki = one
            'Pp' => ['pos' => 'noun', 'prontype' => 'prs'], # én = I, mi = we, te = thou, ti = you, ő = he/she/it, ők = they
            'Pq' => ['pos' => 'noun', 'prontype' => 'int'], # mi, milyen = what, ki = who
            'Pr' => ['pos' => 'noun', 'prontype' => 'rel'], # amely, aki, ami, amelyik = which
            'Ps' => ['pos' => 'adj',  'prontype' => 'prs', 'poss' => 'yes'], # enyém = mine, miénk = ours, övék = theirs, saját, sajátja, önnön = own
            'Px' => ['pos' => 'noun', 'prontype' => 'prs', 'reflex' => 'yes'], # magam = myself, magunk = ourselves, magad = yourself, önmaga = himself/herself, maga = itself, maguk = themselves
            'Py' => ['pos' => 'noun', 'prontype' => 'rcp'], # egymás = each other
            'Rd' => ['pos' => 'adv', 'prontype' => 'dem'], # akkor = then, úgy = so, így = so, itt = here, ott = there
            'Rg' => ['pos' => 'adv', 'prontype' => 'tot|neg'], # general adverbs: mindig = always, soha = never, mindenképpen = in any case, mind = every, bármikor = whenever
            'Ri' => ['pos' => 'adv', 'prontype' => 'ind'], # sokáig = long, olykor = sometimes, valahol = somewhere, egyrészt = on the one hand, másrészt = on the other hand
            'Rl' => ['pos' => 'adv', 'prontype' => 'prs'], # personal adverb: rá = it, neki = him/her, vele = with him, benne = in him/it, inside, róla = it
            'Rm' => ['pos' => 'adv', 'polarity' => 'neg'], # modifier: nem, ne = not, sem = neither, se = nor
            'Rp' => ['pos' => 'part'], # particle, preverb: meg = and, el = away/off, ki = out, be = in, fel = up
            'Rq' => ['pos' => 'adv', 'prontype' => 'int'], # -e [interrogative suffix, tokenized separately], miért = why, hogyan = how, hol = where, vajon = whether, mikor = when
            'Rr' => ['pos' => 'adv', 'prontype' => 'rel'], # amikor = when, ahol = where, míg = while, miközben = while, mint = as
            'Rv' => ['pos' => 'verb', 'verbform' => 'conv'], # verbal adverb: hivatkozva = referring to, kezdve = from, hozzátéve = adding, mondván = saying
            'Rx' => ['pos' => 'adv'], # other adverb: már = already, még = even, csak = only, is = also, például = for example
            'St' => ['pos' => 'adp', 'adpostype' => 'post'], # adposition/postposition: szerint = according to, után = after, között = between, által = by, alatt = under
            'Tf' => ['pos' => 'adj', 'prontype' => 'art', 'definite' => 'def'], # definite article: a, az
            'Ti' => ['pos' => 'adj', 'prontype' => 'art', 'definite' => 'ind'], # indefinite article: egy
            'Va' => ['pos' => 'verb', 'verbtype' => 'aux'], # fogok, fog, fogja, fogunk, fognak, fogják, volna
            'Vm' => ['pos' => 'verb'], # main verb: van = there is, kell = must, lehet = may, lesz = become, nincs = is not, áll = stop, kerül = get to, tud = know
            'X'  => ['foreign' => 'yes'], # foreign or unknown: homo, ecce, public_relations, szlovák)-Coetzer
            'Y'  => ['abbr' => 'yes'], # abbreviation: stb., dr., Mr., T., Dr.
            'Z'  => ['typo' => 'yes'], # mistyped word
            'WPUNCT' => ['pos' => 'punc'], # word punctuation
            'SPUNCT' => ['pos' => 'punc', 'punctype' => 'peri|excl|qest'], # sentence delimiting punctuation (., !, ?)
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''    => { 'nountype' => { 'prop' => 'Np',
                                                                              'com'  => 'Nc',
                                                                              '@'    => 'Oi' }},
                                                   'prs' => { 'reflex' => { 'yes' => 'Px',
                                                                            '@'      => 'Pp' }},
                                                   'rcp' => 'Py',
                                                   'int' => 'Pq',
                                                   'rel' => 'Pr',
                                                   'tot' => 'Pg',
                                                   'neg' => 'Pg' }},
                       'adj'  => { 'prontype' => { ''    => { 'numtype' => { 'ord' => 'Mo',
                                                                             '@'   => 'Af' }},
                                                   'art' => { 'definite' => { 'def' => 'Tf',
                                                                              '@'   => 'Ti' }},
                                                   'dem' => 'Pd',
                                                   'ind' => 'Pi',
                                                   'prs' => 'Ps' }},
                       'num'  => { 'numform' => { 'digit' => 'On',
                                                  '@'     => { 'numtype' => { 'card' => 'Mc',
                                                                              'dist' => 'Md',
                                                                              'frac' => 'Mf',
                                                                              'ord'  => 'Mo' }}}},
                       'verb' => { 'verbform' => { 'conv' => 'Rv',
                                                   '@'    => { 'verbtype' => { 'aux' => 'Va',
                                                                               '@'   => 'Vm' }}}},
                       'adv'  => { 'prontype' => { 'dem' => 'Rd',
                                                   'ind' => 'Ri',
                                                   'tot' => 'Rg',
                                                   'neg' => 'Rg',
                                                   'prs' => 'Rl',
                                                   'int' => 'Rq',
                                                   'rel' => 'Rr',
                                                   '@'   => { 'polarity' => { 'neg' => 'Rm',
                                                                              '@'   => 'Rx' }}}},
                       'adp'  => 'St',
                       'conj' => { 'conjtype' => { 'coor' => 'Cc',
                                                   '@'    => 'Cs' }},
                       'part' => 'Rp',
                       'int'  => { 'other/single_word_sentence' => { 'yes' => 'Io',
                                                                     '@'   => 'I' }},
                       'punc' => { 'punctype' => { 'peri' => 'SPUNCT',
                                                   'excl' => 'SPUNCT',
                                                   'qest' => 'SPUNCT',
                                                   '@'    => 'WPUNCT' }},
                       '@'    => { 'hyph' => { 'yes' => 'Oh',
                                               '@'    => { 'foreign' => { 'yes' => 'X',
                                                                          '@'       => { 'abbr' => { 'yes' => 'Y',
                                                                                                     '@'    => { 'typo' => { 'yes' => 'Z',
                                                                                                                             '@'    => 'O' }}}}}}}}}
        }
    );
    # DEGREE OF COMPARISON ####################
    $atoms{deg} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            # új, magyar, nagy, amerikai, német
            'positive'     => 'pos',
            # nagyobb, újabb, korábbi, kisebb, utóbbi
            'comparative'  => 'cmp',
            # legnagyobb, legfontosabb, legfőbb, legjobb, legkisebb
            'superlative'  => 'sup',
            # does not occur in the treebank
            'exaggeration' => 'abs'
        }
    );
    # CONJUNCTION TYPE ####################
    $atoms{ctype} = $self->create_simple_atom
    (
        'intfeature' => 'conjtype',
        'simple_decode_map' =>
        {
            # és, is, s, de, vagy
            'coordinating'  => 'coor',
            # hogy, mint, ha, mert, mivel
            'subordinating' => 'sub'
        }
    );
    # VERB FORM AND MOOD ####################
    $atoms{mood} = $self->create_atom
    (
        'surfeature' => 'mood',
        'decode_map' =>
        {
            # van, kell, lehet, lesz, nincs
            'indicative'  => ['verbform' => 'fin', 'mood' => 'ind'],
            # háborúzz, szeretkezz, figyelj, legyél, szedj
            'imperative'  => ['verbform' => 'fin', 'mood' => 'imp'],
            # lenne, kellene, lehetne, szeretne, volna
            'conditional' => ['verbform' => 'fin', 'mood' => 'cnd'],
            # tenni, tudni, tartani, venni, elérni
            'infinitive'  => ['verbform' => 'inf']
        },
        'encode_map' =>
        {
            'verbform' => { 'inf' => 'infinitive',
                            '@'   => { 'mood' => { 'ind' => 'indicative',
                                                   'imp' => 'imperative',
                                                   'cnd' => 'conditional' }}}
        }
    );
    # TENSE ####################
    $atoms{t} = $self->create_simple_atom
    (
        'intfeature' => 'tense',
        'simple_decode_map' =>
        {
            # van, kell, lehet, lesz, nincs
            'present' => 'pres',
            # volt, lett, kellett, került, lehetett
            'past'    => 'past'
        }
    );
    # PERSON ####################
    $atoms{p} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            # vagyok, akarok, gondolok, beszélek, írok
            '1st' => '1',
            # vagy, szerezhetsz, akarsz, bedughatsz, lemész
            '2nd' => '2',
            # van, kell, lehet, lesz, nincs
            '3rd' => '3'
        }
    );
    # NUMBER ####################
    $atoms{n} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            # kormány, év, század, forint, cég
            'singular' => 'sing',
            # évek, szerbek, emberek, albánok, nők
            'plural'   => 'plur'
        }
    );
    # DEFINITENESS ####################
    $atoms{def} = $self->create_simple_atom
    (
        'intfeature' => 'definite',
        'simple_decode_map' =>
        {
            # mondja, tudja, teszi, állítja, jelenti
            'yes' => 'def',
            # van, kell, lehet, lesz, nincs
            'no'  => 'ind'
        }
    );
    # CASE ####################
    # Multext: Genitive is rarely marked in Hungarian. If marked then with the same suffix as that of dative case.
    # Nouns with zero suffix can be nominative or genitive, so they are ambigious.
    $atoms{case} = $self->create_atom
    (
        'surfeature' => 'case',
        'decode_map' =>
        {
            # kormány, év, század, forint, cég
            'nominative'   => ['case' => 'nom'],
            # forintot, részt, pénzt, dollárt, szerepet
            'accusative'   => ['case' => 'acc'],
            # rendőrségnek, kormánynak, embernek, államnak, tárcának
            'genitive'     => ['case' => 'gen'],
            # kormánynak, embernek, parlamentnek, fegyvernek, sikernek
            'dative'       => ['case' => 'dat'],
            # évvel, százalékkal, nappal, sikerrel, alkalommal
            'instrumental' => ['case' => 'ins'],
            # figyelembe, forgalomba, helyzetbe, igénybe, őrizetbe
            'illative'     => ['case' => 'ill'],
            # évben, kapcsolatban, esetben, mértékben, időben
            'inessive'     => ['case' => 'ine'],
            # százalékról, háborúról, dollárról, ügyről, dologról
            'elative'      => ['case' => 'ela'],
            # tárgyalóasztalhoz, földhöz, bravúrhoz, feltételhez, békéhez
            'allative'     => ['case' => 'all'],
            # évnél, korábbinál, százaléknál, vadásztársaságnál, óránál
            'adessive'     => ['case' => 'ade'],
            # évtől, kormánytól, tárcától, politikától, lőfegyvertől
            'ablative'     => ['case' => 'abl'],
            # évre, forintra, nyilvánosságra, kilométerre, kérdésre
            'sublative'    => ['case' => 'sub'],
            # héten, módon, helyen, területen, pénteken
            'superessive'  => ['case' => 'sup'],
            # százalékról, háborúról, dollárról, ügyről, dologról
            'delative'     => ['case' => 'del'],
            # ideig, évig, máig, napig, hónapig
            'terminative'  => ['case' => 'ter'],
            # ráadásul, hírül, célul, segítségül, tudomásul
            'essive'       => ['case' => 'ess'],
            # szükségképpen, miniszterként, tulajdonosként, személyként, példaként
            'essiveformal' => ['case' => 'ess', 'style' => 'form'],
            # órakor, induláskor, perckor, átültetéskor, záráskor
            'temporalis'   => ['case' => 'tem'],
            # forintért, dollárért, pénzért, euróért, májátültetésért
            'causalis'     => ['case' => 'cau'],
            # kamatostul, családostul
            'sociative'    => ['case' => 'com'],
            # várossá, bérmunkássá, sztárrá, társasággá, panzióvá
            'factive'      => ['case' => 'tra'],
            # másodpercenként, négyzetméterenként, tonnánként, óránként, esténként
            'distributive' => ['case' => 'dis'],
            # helyütt
            'locative'     => ['case' => 'loc']
        },
        'encode_map' =>
        {
            'case' => { 'nom' => 'nominative',
                        'acc' => 'accusative',
                        'gen' => 'genitive',
                        'dat' => 'dative',
                        'ins' => 'instrumental',
                        'ill' => 'illative',
                        'ine' => 'inessive',
                        'ela' => 'elative',
                        'all' => 'allative',
                        'ade' => 'adessive',
                        'abl' => 'ablative',
                        'sub' => 'sublative',
                        'sup' => 'superessive',
                        'del' => 'delative',
                        'ter' => 'terminative',
                        'ess' => { 'style' => { 'form' => 'essiveformal',
                                                '@'    => 'essive' }},
                        'tem' => 'temporalis',
                        'cau' => 'causalis',
                        'com' => 'sociative',
                        'tra' => 'factive',
                        'dis' => 'distributive',
                        'loc' => 'locative' }
        }
    );
    # NOUN TYPE ####################
    $atoms{proper} = $self->create_simple_atom
    (
        'intfeature' => 'nountype',
        'simple_decode_map' =>
        {
            # kormány, év, század, forint, cég
            'yes' => 'prop',
            # HVG, Magyarország, NATO, Torgyán_József, Koszovó
            'no'  => 'com'
        }
    );
    # POSSESSOR'S PERSON ####################
    # owner's (possessor's) person of nouns, adjectives, numerals, pronouns
    $atoms{pperson} = $self->create_simple_atom
    (
        'intfeature' => 'possperson',
        'simple_decode_map' =>
        {
            # meggyőződésem = my opinion, időm = my time, barátom = my friend, ismerősöm, édesanyám
            '1st' => '1',
            # ellenfeled = your opponent, kapcsolatod = your relationship, aranytartalékod
            '2nd' => '2',
            # százaléka, éve, vezetője, száma, elnöke
            '3rd' => '3'
        }
    );
    # POSSESSOR'S NUMBER ####################
    # owner's (possessor's) number of nouns, adjectives, numerals, pronouns
    $atoms{pnumber} = $self->create_simple_atom
    (
        'intfeature' => 'possnumber',
        'simple_decode_map' =>
        {
            # meggyőződésem = my opinion, időm = my time, barátom = my friend, ismerősöm, édesanyám
            'singular' => 'sing',
            # kultúránk = our culture, tudósítónk = our correspondent, hazánk, lapunk, szükségünk
            'plural'   => 'plur'
        }
    );
    # POSSESSED'S NUMBER ####################
    # owned (possession's) number of nouns, adjectives, numerals, pronouns
    # Possession relation can be marked on the owner or on the owned, and one noun can be owner and owned at the same time.
    # Combination n=plural|.*|pednumber=singular means that a plural noun owns something singular. (That something is elided.)
    # szerbeké, mellsebészeké, ortodoxoké, festőké, albánoké
    # Multext: Hungarian has three types of number in the nominal inflection:
    # 1. The number of the noun.
    # 2. The number of owners that own the noun.
    # 3. The number of the context given referent, which is some possession of the noun, i.e. belongs to the noun (anaphoric possessive).
    $atoms{pednumber} = $self->create_simple_atom
    (
        'intfeature' => 'possednumber',
        'simple_decode_map' =>
        {
            # pártarányosításé, kerületé, szövetségé, férfié, cukoré
            'singular' => 'sing',
            # in SzTB, applies only to the possessive pronoun mieinket = ours; and in general is very rare
            'plural'   => 'plur'
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
    my @features = ('deg', 'ctype', 'mood', 't', 'p', 'n', 'def', 'case', 'proper', 'pperson', 'pnumber', 'pednumber');
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
        '@' => []
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
    my $fs = $self->decode_conll($tag);
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
    my $subpos = $atoms->{pos}->encode($fs);
    my $pos = $subpos =~ m/^([SW]PUNCT)$/ ? $subpos : substr($subpos, 0, 1);
    my $feature_names = $self->features_all();
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus, 576 tags found.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
A	Af	deg=comparative|n=plural|case=accusative
A	Af	deg=comparative|n=plural|case=adessive
A	Af	deg=comparative|n=plural|case=nominative
A	Af	deg=comparative|n=singular|case=accusative
A	Af	deg=comparative|n=singular|case=dative
A	Af	deg=comparative|n=singular|case=delative
A	Af	deg=comparative|n=singular|case=essive
A	Af	deg=comparative|n=singular|case=factive
A	Af	deg=comparative|n=singular|case=inessive
A	Af	deg=comparative|n=singular|case=nominative
A	Af	deg=comparative|n=singular|case=sublative
A	Af	deg=positive|n=plural|case=ablative
A	Af	deg=positive|n=plural|case=ablative|pednumber=singular
A	Af	deg=positive|n=plural|case=accusative
A	Af	deg=positive|n=plural|case=adessive
A	Af	deg=positive|n=plural|case=allative
A	Af	deg=positive|n=plural|case=dative
A	Af	deg=positive|n=plural|case=delative
A	Af	deg=positive|n=plural|case=factive
A	Af	deg=positive|n=plural|case=genitive
A	Af	deg=positive|n=plural|case=illative
A	Af	deg=positive|n=plural|case=inessive
A	Af	deg=positive|n=plural|case=instrumental
A	Af	deg=positive|n=plural|case=nominative
A	Af	deg=positive|n=plural|case=nominative|pednumber=singular
A	Af	deg=positive|n=plural|case=nominative|pperson=3rd|pnumber=singular
A	Af	deg=positive|n=plural|case=sublative
A	Af	deg=positive|n=singular|case=ablative
A	Af	deg=positive|n=singular|case=accusative
A	Af	deg=positive|n=singular|case=adessive
A	Af	deg=positive|n=singular|case=allative
A	Af	deg=positive|n=singular|case=causalis
A	Af	deg=positive|n=singular|case=dative
A	Af	deg=positive|n=singular|case=dative|pperson=3rd|pnumber=singular
A	Af	deg=positive|n=singular|case=elative
A	Af	deg=positive|n=singular|case=essive
A	Af	deg=positive|n=singular|case=essiveformal
A	Af	deg=positive|n=singular|case=factive
A	Af	deg=positive|n=singular|case=factive|pperson=3rd|pnumber=singular
A	Af	deg=positive|n=singular|case=genitive
A	Af	deg=positive|n=singular|case=illative
A	Af	deg=positive|n=singular|case=inessive
A	Af	deg=positive|n=singular|case=instrumental
A	Af	deg=positive|n=singular|case=nominative
A	Af	deg=positive|n=singular|case=nominative|pednumber=singular
A	Af	deg=positive|n=singular|case=nominative|pperson=3rd|pnumber=singular
A	Af	deg=positive|n=singular|case=sublative
A	Af	deg=positive|n=singular|case=sublative|pperson=3rd|pnumber=singular
A	Af	deg=superlative|n=plural|case=accusative
A	Af	deg=superlative|n=plural|case=accusative|pperson=3rd|pnumber=singular
A	Af	deg=superlative|n=plural|case=nominative
A	Af	deg=superlative|n=singular|case=dative
A	Af	deg=superlative|n=singular|case=essive
A	Af	deg=superlative|n=singular|case=nominative
A	Af	deg=superlative|n=singular|case=sublative
C	Cc	ctype=coordinating
C	Cs	ctype=subordinating
I	I	_
I	Io	_
M	Mc	n=plural|case=accusative
M	Mc	n=plural|case=dative
M	Mc	n=plural|case=genitive|pperson=3rd|pnumber=singular
M	Mc	n=plural|case=inessive
M	Mc	n=plural|case=instrumental
M	Mc	n=plural|case=nominative
M	Mc	n=plural|case=nominative|pperson=3rd|pnumber=singular
M	Mc	n=singular
M	Mc	n=singular|case=ablative
M	Mc	n=singular|case=accusative
M	Mc	n=singular|case=adessive
M	Mc	n=singular|case=causalis
M	Mc	n=singular|case=dative
M	Mc	n=singular|case=delative
M	Mc	n=singular|case=elative
M	Mc	n=singular|case=essive
M	Mc	n=singular|case=genitive
M	Mc	n=singular|case=illative
M	Mc	n=singular|case=inessive
M	Mc	n=singular|case=instrumental
M	Mc	n=singular|case=instrumental|pperson=3rd|pnumber=singular
M	Mc	n=singular|case=nominative
M	Mc	n=singular|case=nominative|pperson=3rd|pnumber=plural
M	Mc	n=singular|case=nominative|pperson=3rd|pnumber=singular
M	Mc	n=singular|case=sublative
M	Mc	n=singular|case=temporalis
M	Mc	n=singular|case=terminative
M	Md	n=singular|case=nominative
M	Mf	n=singular|case=accusative|pperson=3rd|pnumber=singular
M	Mf	n=singular|case=adessive|pperson=3rd|pnumber=singular
M	Mf	n=singular|case=causalis|pednumber=singular
M	Mf	n=singular|case=inessive|pperson=3rd|pnumber=singular
M	Mf	n=singular|case=instrumental
M	Mf	n=singular|case=instrumental|pperson=3rd|pnumber=singular
M	Mf	n=singular|case=nominative
M	Mf	n=singular|case=nominative|pperson=3rd|pnumber=singular
M	Mf	n=singular|case=sublative
M	Mf	n=singular|case=sublative|pperson=3rd|pnumber=singular
M	Mo	n=singular
M	Mo	n=singular|case=dative
M	Mo	n=singular|case=essiveformal
M	Mo	n=singular|case=inessive
M	Mo	n=singular|case=nominative
M	Mo	n=singular|case=sublative
N	Nc	n=plural|case=ablative|proper=no
N	Nc	n=plural|case=ablative|proper=no|pednumber=singular
N	Nc	n=plural|case=ablative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=plural|case=ablative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=accusative|proper=no
N	Nc	n=plural|case=accusative|proper=no|pednumber=singular
N	Nc	n=plural|case=accusative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=plural|case=accusative|proper=no|pperson=1st|pnumber=singular
N	Nc	n=plural|case=accusative|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=plural|case=accusative|proper=no|pperson=3rd|pnumber=plural|pednumber=singular
N	Nc	n=plural|case=accusative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=adessive|proper=no
N	Nc	n=plural|case=adessive|proper=no|pperson=1st|pnumber=singular
N	Nc	n=plural|case=adessive|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=plural|case=adessive|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=adessive|proper=no|pperson=3rd|pnumber=singular|pednumber=singular
N	Nc	n=plural|case=allative|proper=no
N	Nc	n=plural|case=allative|proper=no|pednumber=singular
N	Nc	n=plural|case=allative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=plural|case=allative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=causalis|proper=no
N	Nc	n=plural|case=causalis|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=dative|proper=no
N	Nc	n=plural|case=dative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=plural|case=dative|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=plural|case=dative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=delative|proper=no
N	Nc	n=plural|case=delative|proper=no|pednumber=singular
N	Nc	n=plural|case=delative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=plural|case=delative|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=plural|case=delative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=elative|proper=no
N	Nc	n=plural|case=elative|proper=no|pednumber=singular
N	Nc	n=plural|case=elative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=plural|case=elative|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=plural|case=elative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=essiveformal|proper=no
N	Nc	n=plural|case=essiveformal|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=factive|proper=no
N	Nc	n=plural|case=factive|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=genitive|proper=no
N	Nc	n=plural|case=genitive|proper=no|pperson=1st|pnumber=plural
N	Nc	n=plural|case=genitive|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=plural|case=genitive|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=illative|proper=no
N	Nc	n=plural|case=illative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=plural|case=illative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=inessive|proper=no
N	Nc	n=plural|case=inessive|proper=no|pperson=1st|pnumber=plural
N	Nc	n=plural|case=inessive|proper=no|pperson=1st|pnumber=singular
N	Nc	n=plural|case=inessive|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=plural|case=inessive|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=instrumental|proper=no
N	Nc	n=plural|case=instrumental|proper=no|pednumber=singular
N	Nc	n=plural|case=instrumental|proper=no|pperson=1st|pnumber=plural
N	Nc	n=plural|case=instrumental|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=plural|case=instrumental|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=nominative|proper=no
N	Nc	n=plural|case=nominative|proper=no|pednumber=singular
N	Nc	n=plural|case=nominative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=plural|case=nominative|proper=no|pperson=1st|pnumber=singular
N	Nc	n=plural|case=nominative|proper=no|pperson=2nd|pnumber=plural
N	Nc	n=plural|case=nominative|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=plural|case=nominative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=sublative|proper=no
N	Nc	n=plural|case=sublative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=plural|case=sublative|proper=no|pperson=1st|pnumber=singular
N	Nc	n=plural|case=sublative|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=plural|case=sublative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=superessive|proper=no
N	Nc	n=plural|case=superessive|proper=no|pperson=1st|pnumber=plural
N	Nc	n=plural|case=superessive|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=plural|case=superessive|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=plural|case=temporalis|proper=no
N	Nc	n=plural|case=terminative|proper=no
N	Nc	n=plural|case=terminative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=singular|case=ablative|proper=no
N	Nc	n=singular|case=ablative|proper=no|pperson=1st|pnumber=singular
N	Nc	n=singular|case=ablative|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=singular|case=ablative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=accusative|proper=no
N	Nc	n=singular|case=accusative|proper=no|pednumber=singular
N	Nc	n=singular|case=accusative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=singular|case=accusative|proper=no|pperson=1st|pnumber=singular
N	Nc	n=singular|case=accusative|proper=no|pperson=2nd|pnumber=singular
N	Nc	n=singular|case=accusative|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=singular|case=accusative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=accusative|proper=no|pperson=3rd|pnumber=singular|pednumber=singular
N	Nc	n=singular|case=adessive|proper=no
N	Nc	n=singular|case=adessive|proper=no|pednumber=singular
N	Nc	n=singular|case=adessive|proper=no|pperson=1st|pnumber=singular
N	Nc	n=singular|case=adessive|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=singular|case=adessive|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=allative|proper=no
N	Nc	n=singular|case=allative|proper=no|pednumber=singular
N	Nc	n=singular|case=allative|proper=no|pperson=1st|pnumber=singular
N	Nc	n=singular|case=allative|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=singular|case=allative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=causalis|proper=no
N	Nc	n=singular|case=causalis|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=singular|case=causalis|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=dative|proper=no
N	Nc	n=singular|case=dative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=singular|case=dative|proper=no|pperson=1st|pnumber=singular
N	Nc	n=singular|case=dative|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=singular|case=dative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=delative|proper=no
N	Nc	n=singular|case=delative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=singular|case=delative|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=singular|case=delative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=distributive|proper=no
N	Nc	n=singular|case=elative|proper=no
N	Nc	n=singular|case=elative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=singular|case=elative|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=singular|case=elative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=essiveformal|proper=no
N	Nc	n=singular|case=essiveformal|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=essive|proper=no
N	Nc	n=singular|case=essive|proper=no|pperson=1st|pnumber=plural
N	Nc	n=singular|case=essive|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=factive|proper=no
N	Nc	n=singular|case=factive|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=genitive|proper=no
N	Nc	n=singular|case=genitive|proper=no|pednumber=singular
N	Nc	n=singular|case=genitive|proper=no|pperson=2nd|pnumber=singular
N	Nc	n=singular|case=genitive|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=singular|case=genitive|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=illative|proper=no
N	Nc	n=singular|case=illative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=singular|case=illative|proper=no|pperson=1st|pnumber=singular
N	Nc	n=singular|case=illative|proper=no|pperson=2nd|pnumber=singular
N	Nc	n=singular|case=illative|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=singular|case=illative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=inessive|proper=no
N	Nc	n=singular|case=inessive|proper=no|pednumber=singular
N	Nc	n=singular|case=inessive|proper=no|pperson=1st|pnumber=plural
N	Nc	n=singular|case=inessive|proper=no|pperson=1st|pnumber=singular
N	Nc	n=singular|case=inessive|proper=no|pperson=2nd|pnumber=singular
N	Nc	n=singular|case=inessive|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=singular|case=inessive|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=instrumental|proper=no
N	Nc	n=singular|case=instrumental|proper=no|pednumber=singular
N	Nc	n=singular|case=instrumental|proper=no|pperson=1st|pnumber=plural
N	Nc	n=singular|case=instrumental|proper=no|pperson=1st|pnumber=singular
N	Nc	n=singular|case=instrumental|proper=no|pperson=2nd|pnumber=singular
N	Nc	n=singular|case=instrumental|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=singular|case=instrumental|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=locative|proper=no
N	Nc	n=singular|case=nominative|proper=no
N	Nc	n=singular|case=nominative|proper=no|pednumber=singular
N	Nc	n=singular|case=nominative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=singular|case=nominative|proper=no|pperson=1st|pnumber=singular
N	Nc	n=singular|case=nominative|proper=no|pperson=2nd|pnumber=plural
N	Nc	n=singular|case=nominative|proper=no|pperson=2nd|pnumber=singular
N	Nc	n=singular|case=nominative|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=singular|case=nominative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=nominative|proper=no|pperson=3rd|pnumber=singular|pednumber=singular
N	Nc	n=singular|case=sociative|proper=no
N	Nc	n=singular|case=sublative|proper=no
N	Nc	n=singular|case=sublative|proper=no|pednumber=singular
N	Nc	n=singular|case=sublative|proper=no|pperson=1st|pnumber=plural
N	Nc	n=singular|case=sublative|proper=no|pperson=1st|pnumber=singular
N	Nc	n=singular|case=sublative|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=singular|case=sublative|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=superessive|proper=no
N	Nc	n=singular|case=superessive|proper=no|pperson=1st|pnumber=plural
N	Nc	n=singular|case=superessive|proper=no|pperson=1st|pnumber=singular
N	Nc	n=singular|case=superessive|proper=no|pperson=2nd|pnumber=singular
N	Nc	n=singular|case=superessive|proper=no|pperson=3rd|pnumber=plural
N	Nc	n=singular|case=superessive|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=temporalis|proper=no
N	Nc	n=singular|case=temporalis|proper=no|pperson=1st|pnumber=plural
N	Nc	n=singular|case=temporalis|proper=no|pperson=3rd|pnumber=singular
N	Nc	n=singular|case=terminative|proper=no
N	Nc	n=singular|case=terminative|proper=no|pperson=3rd|pnumber=singular
N	Np	n=plural|case=accusative|proper=yes
N	Np	n=plural|case=allative|proper=yes
N	Np	n=plural|case=dative|proper=yes
N	Np	n=plural|case=instrumental|proper=yes
N	Np	n=plural|case=nominative|proper=yes
N	Np	n=plural|case=sublative|proper=yes
N	Np	n=singular|case=ablative|proper=yes
N	Np	n=singular|case=accusative|proper=yes
N	Np	n=singular|case=accusative|proper=yes|pednumber=singular
N	Np	n=singular|case=accusative|proper=yes|pperson=3rd|pnumber=singular
N	Np	n=singular|case=adessive|proper=yes
N	Np	n=singular|case=allative|proper=yes
N	Np	n=singular|case=allative|proper=yes|pednumber=singular
N	Np	n=singular|case=allative|proper=yes|pperson=3rd|pnumber=singular
N	Np	n=singular|case=causalis|proper=yes
N	Np	n=singular|case=dative|proper=yes
N	Np	n=singular|case=dative|proper=yes|pperson=2nd|pnumber=singular
N	Np	n=singular|case=dative|proper=yes|pperson=3rd|pnumber=singular
N	Np	n=singular|case=delative|proper=yes
N	Np	n=singular|case=delative|proper=yes|pperson=3rd|pnumber=singular
N	Np	n=singular|case=elative|proper=yes
N	Np	n=singular|case=elative|proper=yes|pperson=3rd|pnumber=singular
N	Np	n=singular|case=essiveformal|proper=yes
N	Np	n=singular|case=factive|proper=yes
N	Np	n=singular|case=genitive|proper=yes
N	Np	n=singular|case=genitive|proper=yes|pednumber=singular
N	Np	n=singular|case=genitive|proper=yes|pperson=3rd|pnumber=singular
N	Np	n=singular|case=illative|proper=yes
N	Np	n=singular|case=inessive|proper=yes
N	Np	n=singular|case=inessive|proper=yes|pperson=1st|pnumber=plural
N	Np	n=singular|case=inessive|proper=yes|pperson=3rd|pnumber=singular
N	Np	n=singular|case=instrumental|proper=yes
N	Np	n=singular|case=nominative|proper=yes
N	Np	n=singular|case=nominative|proper=yes|pednumber=singular
N	Np	n=singular|case=nominative|proper=yes|pperson=1st|pnumber=singular
N	Np	n=singular|case=nominative|proper=yes|pperson=3rd|pnumber=singular
N	Np	n=singular|case=sublative|proper=yes
N	Np	n=singular|case=superessive|proper=yes
N	Np	n=singular|case=terminative|proper=yes
O	Oh	_
O	Oi	n=singular|case=nominative
O	Oi	n=singular|case=sublative
O	On	n=singular|case=nominative
O	On	n=singular|case=sublative
P	Pd	p=3rd|n=plural|case=accusative
P	Pd	p=3rd|n=plural|case=adessive
P	Pd	p=3rd|n=plural|case=allative
P	Pd	p=3rd|n=plural|case=dative
P	Pd	p=3rd|n=plural|case=delative
P	Pd	p=3rd|n=plural|case=elative
P	Pd	p=3rd|n=plural|case=genitive
P	Pd	p=3rd|n=plural|case=inessive
P	Pd	p=3rd|n=plural|case=instrumental
P	Pd	p=3rd|n=plural|case=nominative
P	Pd	p=3rd|n=plural|case=sublative
P	Pd	p=3rd|n=plural|case=superessive
P	Pd	p=3rd|n=singular|case=ablative
P	Pd	p=3rd|n=singular|case=accusative
P	Pd	p=3rd|n=singular|case=adessive
P	Pd	p=3rd|n=singular|case=allative
P	Pd	p=3rd|n=singular|case=causalis
P	Pd	p=3rd|n=singular|case=dative
P	Pd	p=3rd|n=singular|case=dative|pperson=3rd|pnumber=plural
P	Pd	p=3rd|n=singular|case=delative
P	Pd	p=3rd|n=singular|case=elative
P	Pd	p=3rd|n=singular|case=essive
P	Pd	p=3rd|n=singular|case=factive
P	Pd	p=3rd|n=singular|case=genitive
P	Pd	p=3rd|n=singular|case=illative
P	Pd	p=3rd|n=singular|case=inessive
P	Pd	p=3rd|n=singular|case=instrumental
P	Pd	p=3rd|n=singular|case=nominative
P	Pd	p=3rd|n=singular|case=nominative|pednumber=singular
P	Pd	p=3rd|n=singular|case=sublative
P	Pd	p=3rd|n=singular|case=superessive
P	Pd	p=3rd|n=singular|case=terminative
P	Pg	p=3rd|n=plural|case=nominative
P	Pg	p=3rd|n=singular|case=ablative
P	Pg	p=3rd|n=singular|case=accusative
P	Pg	p=3rd|n=singular|case=accusative|pperson=3rd|pnumber=singular
P	Pg	p=3rd|n=singular|case=allative
P	Pg	p=3rd|n=singular|case=dative
P	Pg	p=3rd|n=singular|case=essive
P	Pg	p=3rd|n=singular|case=genitive
P	Pg	p=3rd|n=singular|case=illative
P	Pg	p=3rd|n=singular|case=inessive
P	Pg	p=3rd|n=singular|case=inessive|pperson=3rd|pnumber=singular
P	Pg	p=3rd|n=singular|case=instrumental
P	Pg	p=3rd|n=singular|case=nominative
P	Pg	p=3rd|n=singular|case=nominative|pednumber=singular
P	Pg	p=3rd|n=singular|case=nominative|pperson=3rd|pnumber=plural
P	Pg	p=3rd|n=singular|case=sublative
P	Pg	p=3rd|n=singular|case=superessive
P	Pi	p=3rd|n=plural|case=accusative
P	Pi	p=3rd|n=plural|case=nominative
P	Pi	p=3rd|n=singular
P	Pi	p=3rd|n=singular|case=ablative
P	Pi	p=3rd|n=singular|case=accusative
P	Pi	p=3rd|n=singular|case=accusative|pperson=3rd|pnumber=plural
P	Pi	p=3rd|n=singular|case=accusative|pperson=3rd|pnumber=singular
P	Pi	p=3rd|n=singular|case=allative
P	Pi	p=3rd|n=singular|case=causalis
P	Pi	p=3rd|n=singular|case=dative
P	Pi	p=3rd|n=singular|case=delative
P	Pi	p=3rd|n=singular|case=essive
P	Pi	p=3rd|n=singular|case=essiveformal
P	Pi	p=3rd|n=singular|case=factive
P	Pi	p=3rd|n=singular|case=genitive
P	Pi	p=3rd|n=singular|case=illative
P	Pi	p=3rd|n=singular|case=inessive
P	Pi	p=3rd|n=singular|case=instrumental
P	Pi	p=3rd|n=singular|case=instrumental|pperson=3rd|pnumber=plural
P	Pi	p=3rd|n=singular|case=nominative
P	Pi	p=3rd|n=singular|case=nominative|pperson=1st|pnumber=plural
P	Pi	p=3rd|n=singular|case=nominative|pperson=3rd|pnumber=plural
P	Pi	p=3rd|n=singular|case=nominative|pperson=3rd|pnumber=singular
P	Pi	p=3rd|n=singular|case=sublative
P	Pi	p=3rd|n=singular|case=superessive
P	Pi	p=3rd|n=singular|case=superessive|pperson=3rd|pnumber=singular
P	Pp	p=1st|n=plural|case=accusative
P	Pp	p=1st|n=plural|case=nominative
P	Pp	p=1st|n=singular|case=accusative
P	Pp	p=1st|n=singular|case=nominative
P	Pp	p=2nd|n=plural|case=nominative
P	Pp	p=2nd|n=singular|case=accusative
P	Pp	p=2nd|n=singular|case=nominative
P	Pp	p=3rd|n=plural|case=accusative
P	Pp	p=3rd|n=plural|case=adessive
P	Pp	p=3rd|n=plural|case=dative
P	Pp	p=3rd|n=plural|case=nominative
P	Pp	p=3rd|n=singular|case=ablative
P	Pp	p=3rd|n=singular|case=accusative
P	Pp	p=3rd|n=singular|case=allative
P	Pp	p=3rd|n=singular|case=causalis
P	Pp	p=3rd|n=singular|case=dative
P	Pp	p=3rd|n=singular|case=elative
P	Pp	p=3rd|n=singular|case=genitive
P	Pp	p=3rd|n=singular|case=inessive
P	Pp	p=3rd|n=singular|case=instrumental
P	Pp	p=3rd|n=singular|case=nominative
P	Pp	p=3rd|n=singular|case=nominative|pednumber=singular
P	Pp	p=3rd|n=singular|case=sublative
P	Pq	p=3rd|n=plural|case=nominative
P	Pq	p=3rd|n=singular|case=ablative
P	Pq	p=3rd|n=singular|case=accusative
P	Pq	p=3rd|n=singular|case=dative
P	Pq	p=3rd|n=singular|case=delative
P	Pq	p=3rd|n=singular|case=elative
P	Pq	p=3rd|n=singular|case=essive
P	Pq	p=3rd|n=singular|case=genitive
P	Pq	p=3rd|n=singular|case=illative
P	Pq	p=3rd|n=singular|case=inessive
P	Pq	p=3rd|n=singular|case=instrumental
P	Pq	p=3rd|n=singular|case=nominative
P	Pq	p=3rd|n=singular|case=sublative
P	Pr	p=3rd|n=plural|case=ablative
P	Pr	p=3rd|n=plural|case=accusative
P	Pr	p=3rd|n=plural|case=allative
P	Pr	p=3rd|n=plural|case=dative
P	Pr	p=3rd|n=plural|case=delative
P	Pr	p=3rd|n=plural|case=elative
P	Pr	p=3rd|n=plural|case=genitive
P	Pr	p=3rd|n=plural|case=inessive
P	Pr	p=3rd|n=plural|case=instrumental
P	Pr	p=3rd|n=plural|case=nominative
P	Pr	p=3rd|n=plural|case=sublative
P	Pr	p=3rd|n=plural|case=superessive
P	Pr	p=3rd|n=singular|case=ablative
P	Pr	p=3rd|n=singular|case=accusative
P	Pr	p=3rd|n=singular|case=adessive
P	Pr	p=3rd|n=singular|case=allative
P	Pr	p=3rd|n=singular|case=causalis
P	Pr	p=3rd|n=singular|case=dative
P	Pr	p=3rd|n=singular|case=delative
P	Pr	p=3rd|n=singular|case=elative
P	Pr	p=3rd|n=singular|case=essive
P	Pr	p=3rd|n=singular|case=genitive
P	Pr	p=3rd|n=singular|case=illative
P	Pr	p=3rd|n=singular|case=inessive
P	Pr	p=3rd|n=singular|case=instrumental
P	Pr	p=3rd|n=singular|case=nominative
P	Pr	p=3rd|n=singular|case=sublative
P	Pr	p=3rd|n=singular|case=superessive
P	Ps	p=1st|n=plural|case=accusative|pednumber=plural
P	Ps	p=3rd|n=singular|case=accusative|pperson=3rd|pnumber=singular
P	Ps	p=3rd|n=singular|case=nominative
P	Ps	p=3rd|n=singular|case=nominative|pperson=1st|pnumber=plural
P	Ps	p=3rd|n=singular|case=nominative|pperson=1st|pnumber=singular
P	Ps	p=3rd|n=singular|case=nominative|pperson=3rd|pnumber=plural
P	Ps	p=3rd|n=singular|case=nominative|pperson=3rd|pnumber=singular
P	Px	p=1st|n=plural|case=accusative
P	Px	p=1st|n=plural|case=instrumental
P	Px	p=1st|n=plural|case=nominative
P	Px	p=1st|n=singular|case=inessive
P	Px	p=1st|n=singular|case=nominative
P	Px	p=2nd|n=singular|case=nominative
P	Px	p=3rd|n=plural|case=ablative
P	Px	p=3rd|n=plural|case=accusative
P	Px	p=3rd|n=plural|case=dative
P	Px	p=3rd|n=plural|case=dative|pednumber=singular
P	Px	p=3rd|n=plural|case=elative
P	Px	p=3rd|n=plural|case=factive|pednumber=singular
P	Px	p=3rd|n=plural|case=illative
P	Px	p=3rd|n=plural|case=inessive
P	Px	p=3rd|n=plural|case=instrumental
P	Px	p=3rd|n=plural|case=nominative
P	Px	p=3rd|n=plural|case=sublative
P	Px	p=3rd|n=singular|case=ablative
P	Px	p=3rd|n=singular|case=accusative
P	Px	p=3rd|n=singular|case=allative
P	Px	p=3rd|n=singular|case=dative
P	Px	p=3rd|n=singular|case=dative|pednumber=singular
P	Px	p=3rd|n=singular|case=elative
P	Px	p=3rd|n=singular|case=illative
P	Px	p=3rd|n=singular|case=inessive
P	Px	p=3rd|n=singular|case=instrumental
P	Px	p=3rd|n=singular|case=nominative
P	Px	p=3rd|n=singular|case=sublative
P	Px	p=3rd|n=singular|case=superessive
P	Py	p=3rd|n=singular|case=ablative
P	Py	p=3rd|n=singular|case=accusative
P	Py	p=3rd|n=singular|case=allative
P	Py	p=3rd|n=singular|case=dative
P	Py	p=3rd|n=singular|case=illative
P	Py	p=3rd|n=singular|case=instrumental
P	Py	p=3rd|n=singular|case=nominative
P	Py	p=3rd|n=singular|case=sublative
R	Rd	_
R	Rg	_
R	Ri	_
R	Rl	_
R	Rm	_
R	Rp	_
R	Rq	_
R	Rr	_
R	Rv	_
R	Rx	_
S	St	_
SPUNCT	SPUNCT	_
T	Tf	def=yes
T	Ti	def=no
V	Va	mood=conditional|t=present|p=3rd|n=singular|def=no
V	Va	mood=indicative|t=present|p=1st|n=plural|def=no
V	Va	mood=indicative|t=present|p=1st|n=singular|def=no
V	Va	mood=indicative|t=present|p=3rd|n=plural|def=no
V	Va	mood=indicative|t=present|p=3rd|n=plural|def=yes
V	Va	mood=indicative|t=present|p=3rd|n=singular|def=no
V	Va	mood=indicative|t=present|p=3rd|n=singular|def=yes
V	Vm	mood=conditional|t=present|p=1st|n=plural|def=no
V	Vm	mood=conditional|t=present|p=1st|n=plural|def=yes
V	Vm	mood=conditional|t=present|p=1st|n=singular|def=no
V	Vm	mood=conditional|t=present|p=1st|n=singular|def=yes
V	Vm	mood=conditional|t=present|p=3rd|n=plural|def=no
V	Vm	mood=conditional|t=present|p=3rd|n=plural|def=yes
V	Vm	mood=conditional|t=present|p=3rd|n=singular|def=no
V	Vm	mood=conditional|t=present|p=3rd|n=singular|def=yes
V	Vm	mood=imperative|t=present|p=1st|n=plural|def=no
V	Vm	mood=imperative|t=present|p=1st|n=plural|def=yes
V	Vm	mood=imperative|t=present|p=1st|n=singular|def=no
V	Vm	mood=imperative|t=present|p=1st|n=singular|def=yes
V	Vm	mood=imperative|t=present|p=2nd|n=plural|def=yes
V	Vm	mood=imperative|t=present|p=2nd|n=singular|def=no
V	Vm	mood=imperative|t=present|p=2nd|n=singular|def=yes
V	Vm	mood=imperative|t=present|p=3rd|n=plural|def=no
V	Vm	mood=imperative|t=present|p=3rd|n=plural|def=yes
V	Vm	mood=imperative|t=present|p=3rd|n=singular|def=no
V	Vm	mood=imperative|t=present|p=3rd|n=singular|def=yes
V	Vm	mood=indicative|t=past|p=1st|n=plural|def=no
V	Vm	mood=indicative|t=past|p=1st|n=plural|def=yes
V	Vm	mood=indicative|t=past|p=1st|n=singular|def=no
V	Vm	mood=indicative|t=past|p=1st|n=singular|def=yes
V	Vm	mood=indicative|t=past|p=2nd|n=plural|def=yes
V	Vm	mood=indicative|t=past|p=2nd|n=singular|def=no
V	Vm	mood=indicative|t=past|p=2nd|n=singular|def=yes
V	Vm	mood=indicative|t=past|p=3rd|n=plural|def=no
V	Vm	mood=indicative|t=past|p=3rd|n=plural|def=yes
V	Vm	mood=indicative|t=past|p=3rd|n=singular|def=no
V	Vm	mood=indicative|t=past|p=3rd|n=singular|def=yes
V	Vm	mood=indicative|t=present|p=1st|n=plural|def=no
V	Vm	mood=indicative|t=present|p=1st|n=plural|def=yes
V	Vm	mood=indicative|t=present|p=1st|n=singular|def=no
V	Vm	mood=indicative|t=present|p=1st|n=singular|def=yes
V	Vm	mood=indicative|t=present|p=2nd|n=singular|def=no
V	Vm	mood=indicative|t=present|p=2nd|n=singular|def=yes
V	Vm	mood=indicative|t=present|p=3rd|n=plural|def=no
V	Vm	mood=indicative|t=present|p=3rd|n=plural|def=yes
V	Vm	mood=indicative|t=present|p=3rd|n=singular|def=no
V	Vm	mood=indicative|t=present|p=3rd|n=singular|def=yes
V	Vm	mood=infinitive
V	Vm	mood=infinitive|t=present|p=1st|n=plural
V	Vm	mood=infinitive|t=present|p=1st|n=singular
V	Vm	mood=infinitive|t=present|p=2nd|n=singular
V	Vm	mood=infinitive|t=present|p=3rd|n=plural
V	Vm	mood=infinitive|t=present|p=3rd|n=singular
WPUNCT	WPUNCT	_
X	X	_
Y	Y	_
Z	Z	_
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

Lingua::Interset::Tagset::HU::Conll - Driver for the Hungarian tagset of the CoNLL 2007 Shared Task (derived from the Szeged Treebank).

=head1 VERSION

version 3.006

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::HU::Conll;
  my $driver = Lingua::Interset::Tagset::HU::Conll->new();
  my $fs = $driver->decode("N\tNc\tn=singular|case=nominative|proper=no");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('hu::conll', "N\tNc\tn=singular|case=nominative|proper=no");

=head1 DESCRIPTION

Interset driver for the Hungarian tagset of the CoNLL 2007 Shared Task.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT. For Hungarian,
these values are derived from the Hungarian MULTEXT-EAST tagset, as used in the
Szeged Treebank.

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
