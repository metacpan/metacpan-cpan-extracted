=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Lij - Package for language Ligurian

=cut

package Locale::CLDR::Locales::Lij;
# This file auto generated from Data\common\main\lij.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ab' => 'abcaso',
 				'ace' => 'aceh',
 				'ada' => 'adangme',
 				'ady' => 'adyghe',
 				'af' => 'afrikaans',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'ale' => 'aléuto',
 				'alt' => 'altai do meridion',
 				'am' => 'amarico',
 				'an' => 'aragoneise',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'arabo',
 				'ar_001' => 'arabo moderno standard',
 				'arn' => 'mapuche',
 				'arp' => 'arpaho',
 				'ars' => 'arabo najd',
 				'as' => 'assameise',
 				'asa' => 'asu',
 				'ast' => 'asturian',
 				'atj' => 'atikamekw',
 				'av' => 'avaro',
 				'awa' => 'awadhi',
 				'ay' => 'aymara',
 				'az' => 'azerbaigian',
 				'az@alt=short' => 'azero',
 				'ba' => 'baschiro',
 				'ban' => 'balineise',
 				'bas' => 'basaa',
 				'be' => 'bielloruscio',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'burgao',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bin' => 'bini',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bengaleise',
 				'bo' => 'tibetan',
 				'br' => 'breton',
 				'brx' => 'bòddo',
 				'bs' => 'bosniaco',
 				'bug' => 'bugineise',
 				'byn' => 'blin',
 				'ca' => 'catalan',
 				'cay' => 'cayuga',
 				'ccp' => 'chakma',
 				'ce' => 'cecen',
 				'ceb' => 'cebuano',
 				'cgg' => 'chiga',
 				'ch' => 'chamorro',
 				'chk' => 'chuukeise',
 				'chm' => 'mari',
 				'cho' => 'choctaw',
 				'chp' => 'chipewyan',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'ckb' => 'curdo sorani',
 				'ckb@alt=variant' => 'curdo do mezo',
 				'clc' => 'chilcotin',
 				'co' => 'còrso',
 				'crg' => 'métchif',
 				'crj' => 'cree do sud-levante',
 				'crk' => 'cree de ciañe',
 				'crl' => 'cree do nòrd-levante',
 				'crm' => 'cree moose',
 				'crr' => 'algonchin da Carolina',
 				'cs' => 'ceco',
 				'csw' => 'cree de smeugge',
 				'cv' => 'chuvash',
 				'cy' => 'galleise',
 				'da' => 'daneise',
 				'dak' => 'dakota',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'tedesco',
 				'de_AT' => 'tedesco de l’Austria',
 				'de_CH' => 'tedesco standard da Svissera',
 				'dgr' => 'dogrib',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'basso sorabo',
 				'dua' => 'duala',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'eka' => 'ekajuk',
 				'el' => 'grego',
 				'en' => 'ingleise',
 				'en_AU' => 'ingleise d’Australia',
 				'en_CA' => 'ingleise do Canadà',
 				'en_GB' => 'ingleise britannico',
 				'en_GB@alt=short' => 'ingleise (RU)',
 				'en_US' => 'ingleise d’America',
 				'en_US@alt=short' => 'ingleise (SUA)',
 				'eo' => 'esperanto',
 				'es' => 'spagnòllo',
 				'es_419' => 'spagnòllo d’America',
 				'es_ES' => 'spagnòllo da Spagna',
 				'es_MX' => 'spagnòllo do Mescico',
 				'et' => 'estone',
 				'eu' => 'basco',
 				'ewo' => 'ewondo',
 				'fa' => 'perscian',
 				'fa_AF' => 'dari',
 				'ff' => 'fulah',
 				'fi' => 'finlandeise',
 				'fil' => 'filipin',
 				'fj' => 'fijian',
 				'fo' => 'faroeise',
 				'fon' => 'fòn',
 				'fr' => 'franseise',
 				'fr_CA' => 'franseise do Canadà',
 				'fr_CH' => 'franseise da Svissera',
 				'frc' => 'franseise cajun',
 				'frr' => 'frison do settentrion',
 				'fur' => 'furlan',
 				'fy' => 'frisian de ponente',
 				'ga' => 'irlandeise',
 				'gaa' => 'ga',
 				'gd' => 'gaelico scoçeise',
 				'gez' => 'geez',
 				'gil' => 'gilberteise',
 				'gl' => 'galiçian',
 				'gn' => 'guarani',
 				'gor' => 'gorontalo',
 				'gsw' => 'tedesco da Svissera',
 				'gu' => 'gujarati',
 				'guz' => 'gusii',
 				'gv' => 'manneise',
 				'gwi' => 'gwichʼin',
 				'ha' => 'hausa',
 				'hai' => 'haida',
 				'haw' => 'hawaiian',
 				'hax' => 'haida do meridion',
 				'he' => 'ebreo',
 				'hi' => 'hindi',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hil' => 'hiligaynon',
 				'hmn' => 'hmong',
 				'hr' => 'croato',
 				'hsb' => 'erto sorabo',
 				'ht' => 'creolo de Haiti',
 				'hu' => 'ongareise',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem',
 				'hy' => 'ermeno',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonesian',
 				'ig' => 'igbo',
 				'ii' => 'yi do settentrion',
 				'ikt' => 'inuktitut canadeise de ponente',
 				'ilo' => 'ilocan',
 				'inh' => 'ingush',
 				'io' => 'ido',
 				'is' => 'islandeise',
 				'it' => 'italian',
 				'iu' => 'inuktitut',
 				'ja' => 'giapponeise',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jv' => 'giavaneise',
 				'ka' => 'georgian',
 				'kab' => 'cabilo',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kbd' => 'cabardin',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'cappoverdian',
 				'kfo' => 'koro',
 				'kgp' => 'kaingang',
 				'kha' => 'khasi',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'kazakh',
 				'kkj' => 'kako',
 				'kl' => 'groenlandeise',
 				'kln' => 'kalenjin',
 				'km' => 'khmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'corean',
 				'kok' => 'konkani',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karchay-balkar',
 				'krl' => 'carelian',
 				'kru' => 'kurukh',
 				'ks' => 'kashmiri',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'colonieise',
 				'ku' => 'curdo',
 				'kum' => 'kumyk',
 				'kv' => 'komi',
 				'kw' => 'còrnico',
 				'kwk' => 'kwakʼwala',
 				'ky' => 'kirghiso',
 				'la' => 'latin',
 				'lad' => 'giudeo-spagnòllo',
 				'lag' => 'langi',
 				'lb' => 'luxemburgheise',
 				'lez' => 'lesgo',
 				'lg' => 'ganda',
 				'li' => 'limburgheise',
 				'lij' => 'ligure',
 				'lil' => 'lillooet',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'lao',
 				'lou' => 'creolo da Louisiana',
 				'loz' => 'lozi',
 				'lrc' => 'luri do settentrion',
 				'lsm' => 'samia',
 				'lt' => 'lituan',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'lushai',
 				'luy' => 'luyia',
 				'lv' => 'letton',
 				'mad' => 'madureise',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makasar',
 				'mas' => 'masai',
 				'mdf' => 'moksha',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'creolo mauriçian',
 				'mg' => 'malagascio',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marshalleise',
 				'mi' => 'maori',
 				'mic' => 'mi\'kmaq',
 				'min' => 'minangkabau',
 				'mk' => 'maçedone',
 				'ml' => 'malayalam',
 				'mn' => 'mongolo',
 				'mni' => 'manipuri',
 				'moe' => 'innu-aimun',
 				'moh' => 'mohawk',
 				'mos' => 'mossi',
 				'mr' => 'marathi',
 				'ms' => 'maleise',
 				'mt' => 'malteise',
 				'mua' => 'mudang',
 				'mul' => 'moltilengua',
 				'mus' => 'muscogee',
 				'mwl' => 'mirandeise',
 				'my' => 'birman',
 				'myv' => 'erzya',
 				'mzn' => 'mazanderani',
 				'na' => 'nauru',
 				'nap' => 'napolitan',
 				'naq' => 'nama',
 				'nb' => 'norvegin bokmål',
 				'nd' => 'ndebele do settentrion',
 				'nds' => 'basso tedesco',
 				'ne' => 'nepaleise',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niue',
 				'nl' => 'olandeise',
 				'nl_BE' => 'sciammengo',
 				'nmg' => 'kwasio',
 				'nn' => 'norvegin nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'norvegin',
 				'nog' => 'nogai',
 				'nqo' => 'n’ko',
 				'nr' => 'ndebele do meridion',
 				'nso' => 'sotho do settentrion',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'ny' => 'nyanja',
 				'nyn' => 'nyankole',
 				'oc' => 'oçitan',
 				'ojb' => 'ojibwa do nòrd-ponente',
 				'ojc' => 'ojibwa do mezo',
 				'ojs' => 'oji-cree',
 				'ojw' => 'ojibwa de ponente',
 				'oka' => 'okangan',
 				'om' => 'oromo',
 				'or' => 'ödia',
 				'os' => 'oscetico',
 				'pa' => 'punjabi',
 				'pag' => 'pangasinan',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palau',
 				'pcm' => 'pidgin nigerian',
 				'pis' => 'pijin',
 				'pl' => 'polacco',
 				'pqm' => 'malecite-passamaquoddy',
 				'ps' => 'pashto',
 				'pt' => 'portogheise',
 				'pt_BR' => 'portogheise do Braxî',
 				'pt_PT' => 'portogheise d’Euröpa',
 				'qu' => 'quechua',
 				'rap' => 'rapanui',
 				'rar' => 'rarotonga',
 				'rhg' => 'rohingya',
 				'rm' => 'romancio',
 				'rn' => 'rundi',
 				'ro' => 'romen',
 				'rof' => 'rombo',
 				'ru' => 'ruscio',
 				'rup' => 'aromen',
 				'rw' => 'kinyarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanscrito',
 				'sad' => 'sandawe',
 				'sah' => 'sakha',
 				'saq' => 'samburu',
 				'sat' => 'santali',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardo',
 				'scn' => 'siçilian',
 				'sco' => 'scoçeise',
 				'sd' => 'sindhi',
 				'se' => 'sami do settentrion',
 				'seh' => 'sena',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'shi' => 'tashelhit',
 				'shn' => 'shan',
 				'si' => 'sinhala',
 				'sk' => 'slovacco',
 				'sl' => 'sloven',
 				'slh' => 'lushootseed do meridion',
 				'sm' => 'samoan',
 				'smn' => 'sami de Inari',
 				'sms' => 'sami skolt',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'sòmalo',
 				'sq' => 'arbaneise',
 				'sr' => 'serbo',
 				'srn' => 'sranan tongo',
 				'ss' => 'swati',
 				'st' => 'sotho do meridion',
 				'str' => 'salish di streiti',
 				'su' => 'sundaneise',
 				'suk' => 'sukuma',
 				'sv' => 'svedeise',
 				'sw' => 'swahili',
 				'swb' => 'comörian',
 				'syr' => 'sciriaco',
 				'ta' => 'tamil',
 				'tce' => 'tutchone do meridion',
 				'te' => 'telugu',
 				'tem' => 'timne',
 				'teo' => 'teso',
 				'tet' => 'tetum',
 				'tg' => 'tagico',
 				'tgx' => 'tagish',
 				'th' => 'thai',
 				'tht' => 'tahltan',
 				'ti' => 'tigrinya',
 				'tig' => 'tigre',
 				'tk' => 'turcomanno',
 				'tlh' => 'klingon',
 				'tli' => 'tlingit',
 				'tn' => 'tswana',
 				'to' => 'tongan',
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'turco',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tt' => 'tataro',
 				'ttm' => 'tutchone do settentrion',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitian',
 				'tyv' => 'tuvinian',
 				'tzm' => 'tamazight de l’Atlante do mezo',
 				'udm' => 'udmurt',
 				'ug' => 'uiguro',
 				'uk' => 'ucrain',
 				'umb' => 'umbundu',
 				'und' => 'lengua desconosciua',
 				'ur' => 'urdu',
 				'uz' => 'uzbeco',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vietnamita',
 				'vun' => 'vunjo',
 				'wa' => 'vallon',
 				'wae' => 'walser',
 				'wal' => 'wolaytta',
 				'war' => 'waray',
 				'wo' => 'wolof',
 				'wuu' => 'cineise wu',
 				'xal' => 'kalmyk',
 				'xh' => 'xhosa',
 				'xog' => 'soga',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'yiddish',
 				'yo' => 'yoruba',
 				'yrl' => 'nheengatu',
 				'yue' => 'cantoneise',
 				'yue@alt=menu' => 'cineise cantoneise',
 				'zgh' => 'tamazight standard do Maròcco',
 				'zh' => 'cineise',
 				'zh@alt=menu' => 'cineise mandarin',
 				'zh_Hans' => 'cineise semplificou',
 				'zh_Hans@alt=long' => 'cineise mandarin semplificou',
 				'zh_Hant' => 'cineise tradiçionale',
 				'zh_Hant@alt=long' => 'cineise mandarin tradiçionale',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'sensa contegnuo linguistico',
 				'zza' => 'zaza',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_script' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		sub {
			my %scripts = (
			'Adlm' => 'adlam',
 			'Arab' => 'arabo',
 			'Aran' => 'nastaliq',
 			'Armn' => 'ermeno',
 			'Beng' => 'bangla',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'braille',
 			'Cakm' => 'chakma',
 			'Cans' => 'scillabäi autòctoni canadeixi unificæ',
 			'Cher' => 'cherokee',
 			'Cyrl' => 'çirillico',
 			'Deva' => 'devanagari',
 			'Ethi' => 'etiope',
 			'Geor' => 'georgian',
 			'Grek' => 'grego',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurumukhi',
 			'Hanb' => 'han con bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hans' => 'semplificou',
 			'Hans@alt=stand-alone' => 'han semplificou',
 			'Hant' => 'tradiçionale',
 			'Hant@alt=stand-alone' => 'han tradiçionale',
 			'Hebr' => 'ebreo',
 			'Hira' => 'hiragana',
 			'Hrkt' => 'katakana ò hiragana',
 			'Jamo' => 'jamo',
 			'Jpan' => 'giapponeise',
 			'Kana' => 'katakana',
 			'Khmr' => 'khmer',
 			'Knda' => 'kannada',
 			'Kore' => 'corean',
 			'Laoo' => 'lao',
 			'Latn' => 'latin',
 			'Mlym' => 'malayalam',
 			'Mong' => 'mongolo',
 			'Mtei' => 'meitei mayek',
 			'Mymr' => 'birman',
 			'Nkoo' => 'n’ko',
 			'Olck' => 'ol chiki',
 			'Orya' => 'ödia',
 			'Rohg' => 'hanifi',
 			'Sinh' => 'sinhala',
 			'Sund' => 'sundaneise',
 			'Syrc' => 'sciriaco',
 			'Taml' => 'tamil',
 			'Telu' => 'telugu',
 			'Tfng' => 'tifinagh',
 			'Thaa' => 'thaana',
 			'Thai' => 'tailandeise',
 			'Tibt' => 'tibetan',
 			'Vaii' => 'vaii',
 			'Yiii' => 'yi',
 			'Zmth' => 'notaçion matematica',
 			'Zsye' => 'emoji',
 			'Zsym' => 'scimboli',
 			'Zxxx' => 'no scrito',
 			'Zyyy' => 'commun',
 			'Zzzz' => 'scrittua desconosciua',

			);
			if ( @_ ) {
				return $scripts{$_[0]};
			}
			return \%scripts;
		}
	}
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'001' => 'Mondo',
 			'002' => 'Africa',
 			'003' => 'America do settentrion',
 			'005' => 'America do meridion',
 			'009' => 'Oçeania',
 			'011' => 'Africa de ponente',
 			'013' => 'America do mezo',
 			'014' => 'Africa de levante',
 			'015' => 'Africa do settentrion',
 			'017' => 'Africa do mezo',
 			'018' => 'Africa do meridion',
 			'019' => 'Americhe',
 			'021' => 'America do nòrd',
 			'029' => 'Caraibi',
 			'030' => 'Asia de levante',
 			'034' => 'Asia do meridion',
 			'035' => 'Asia do sud-levante',
 			'039' => 'Euröpa do meridion',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'region da Micronesia',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia do mezo',
 			'145' => 'Asia de ponente',
 			'150' => 'Euröpa',
 			'151' => 'Euröpa de levante',
 			'154' => 'Euröpa do settentrion',
 			'155' => 'Euröpa de ponente',
 			'202' => 'Africa subsahariaña',
 			'419' => 'America latiña',
 			'AC' => 'Isoa de l’Ascension',
 			'AD' => 'Andòrra',
 			'AE' => 'Emirati arabi unii',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua e Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Arbania',
 			'AM' => 'Ermenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antartide',
 			'AR' => 'Argentiña',
 			'AS' => 'Samoa americaña',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Isoe Åland',
 			'AZ' => 'Azerbaigian',
 			'BA' => 'Bòsnia e Herzegòvina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgio',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Borgaia',
 			'BH' => 'Bahrein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'San Bertomê',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Caraibi olandeixi',
 			'BR' => 'Braxî',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Isoa Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Bieloruscia',
 			'BZ' => 'Belize',
 			'CA' => 'Canadà',
 			'CC' => 'Isoe Cocos (Keeling)',
 			'CD' => 'Congo-Kinshasa',
 			'CD@alt=variant' => 'Congo (RDC)',
 			'CF' => 'Repubrica çentrafricaña',
 			'CG' => 'Congo-Brazzaville',
 			'CG@alt=variant' => 'Congo (Repubrica)',
 			'CH' => 'Svissera',
 			'CI' => 'Còsta d’Avöio',
 			'CI@alt=variant' => 'Côte d’Ivoire',
 			'CK' => 'Isoe Cook',
 			'CL' => 'Cile',
 			'CM' => 'Cameron',
 			'CN' => 'Ciña',
 			'CO' => 'Colombia',
 			'CP' => 'Isoa de Clipperton',
 			'CR' => 'Còsta Rica',
 			'CU' => 'Cubba',
 			'CV' => 'Cappo Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Isoa Christmas',
 			'CY' => 'Çipri',
 			'CZ' => 'Cechia',
 			'CZ@alt=variant' => 'Repubrica ceca',
 			'DE' => 'Germania',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Danimarca',
 			'DM' => 'Dominica',
 			'DO' => 'Repubrica dominicaña',
 			'DZ' => 'Algeria',
 			'EA' => 'Çéuta e Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estònia',
 			'EG' => 'Egitto',
 			'EH' => 'Sahara de ponente',
 			'ER' => 'Eritrea',
 			'ES' => 'Spagna',
 			'ET' => 'Etiòpia',
 			'EU' => 'Union europea',
 			'EZ' => 'zöna euro',
 			'FI' => 'Finlandia',
 			'FJ' => 'Figi',
 			'FK' => 'Isoe Malviñe',
 			'FK@alt=variant' => 'Isoe Malviñe (Isoe Falkland)',
 			'FM' => 'Micronesia',
 			'FO' => 'Isoe Fær Øer',
 			'FR' => 'Fransa',
 			'GA' => 'Gabon',
 			'GB' => 'Regno Unio',
 			'GB@alt=short' => 'RU',
 			'GD' => 'Granada',
 			'GE' => 'Geòrgia',
 			'GF' => 'Guyana franseise',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibertâ',
 			'GL' => 'Groenlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadaluppa',
 			'GQ' => 'Guinea equatoiäle',
 			'GR' => 'Greçia',
 			'GS' => 'Geòrgia do Sud e Isoe Sandwich do Sud',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'RAS de Hong Kong (Ciña)',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Isoe Heard e McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croaçia',
 			'HT' => 'Haiti',
 			'HU' => 'Ongaia',
 			'IC' => 'Isoe Canäie',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israele',
 			'IM' => 'Isoa de Man',
 			'IN' => 'India',
 			'IO' => 'Tære britanniche de l’oçeano Indian',
 			'IQ' => 'Iraq',
 			'IR' => 'Iran',
 			'IS' => 'Islanda',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Giamaica',
 			'JO' => 'Giordania',
 			'JP' => 'Giappon',
 			'KE' => 'Kenya',
 			'KG' => 'Kirghizistan',
 			'KH' => 'Cambòggia',
 			'KI' => 'Kiribati',
 			'KM' => 'Comöre',
 			'KN' => 'San Cristòffa e Nevis',
 			'KP' => 'Corea do Nòrd',
 			'KR' => 'Corea do Sud',
 			'KW' => 'Kuwait',
 			'KY' => 'Isoe Cayman',
 			'KZ' => 'Kazakistan',
 			'LA' => 'Laos',
 			'LB' => 'Libano',
 			'LC' => 'Santa Luçia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituania',
 			'LU' => 'Luxemburgo',
 			'LV' => 'Lettònia',
 			'LY' => 'Libia',
 			'MA' => 'Maròcco',
 			'MC' => 'Monego',
 			'MD' => 'Moldavia',
 			'ME' => 'Monteneigro',
 			'MF' => 'San Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Isoe Marshall',
 			'MK' => 'Maçedònia do Nòrd',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birmania)',
 			'MN' => 'Mongòlia',
 			'MO' => 'RAS de Macao',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Isoe Mariañe de settentrion',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldive',
 			'MW' => 'Malawi',
 			'MX' => 'Mescico',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambico',
 			'NA' => 'Namibia',
 			'NC' => 'Neuva Caledònia',
 			'NE' => 'Niger',
 			'NF' => 'Isoa Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Paixi Basci',
 			'NO' => 'Norveggia',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Neuva Zelanda',
 			'NZ@alt=variant' => 'Aoteratoa Neuva Zelanda',
 			'OM' => 'Òman',
 			'PA' => 'Panama',
 			'PE' => 'Perù',
 			'PF' => 'Polinesia fraseise',
 			'PG' => 'Papua Neuva Guinea',
 			'PH' => 'Filipiñe',
 			'PK' => 'Pakistan',
 			'PL' => 'Polònia',
 			'PM' => 'San Pê e Miquelon',
 			'PN' => 'Isoe Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Tære palestineixi',
 			'PS@alt=short' => 'Palestiña',
 			'PT' => 'Portugâ',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'regioin lontañe de l’Oçeania',
 			'RE' => 'Réunion',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Ruscia',
 			'RW' => 'Rwanda',
 			'SA' => 'Arabia saudia',
 			'SB' => 'Isoe Salomon',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Sveçia',
 			'SG' => 'Scingapô',
 			'SH' => 'Sant’Elena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard e Jan Mayen',
 			'SK' => 'Slovacchia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marin',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Sudan do Sud',
 			'ST' => 'Sao Tomé e Prinçipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Sciria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Isoe Turks e Caicos',
 			'TD' => 'Chad',
 			'TF' => 'Tære australe franseixi',
 			'TG' => 'Tögo',
 			'TH' => 'Tailandia',
 			'TJ' => 'Tagikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor Est',
 			'TL@alt=variant' => 'Timor-Leste',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunexia',
 			'TO' => 'Tonga',
 			'TR' => 'Turchia',
 			'TT' => 'Trinidad e Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucraiña',
 			'UG' => 'Uganda',
 			'UM' => 'Isoe lontañe di SUA',
 			'UN' => 'Naçioin Unie',
 			'US' => 'Stati Unii',
 			'US@alt=short' => 'SUA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Çittæ do Vatican',
 			'VC' => 'San Viçenso e e Granadiñe',
 			'VE' => 'Venessuela',
 			'VG' => 'Isoe Vergine britanniche',
 			'VI' => 'Isoe Vergine di Stati Unii',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis e Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'pseudo-açenti',
 			'XB' => 'pseudo-bidi',
 			'XK' => 'Kòsovo',
 			'YE' => 'Yemen',
 			'YT' => 'Maiòtta',
 			'ZA' => 'Sudafrica',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'region desconosciua',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'lunäio',
 			'cf' => 'formato de monæa',
 			'collation' => 'ordine',
 			'currency' => 'monæa',
 			'hc' => 'scistema oräio (12 ò 24 oe)',
 			'lb' => 'stilo de interruçion de linia',
 			'ms' => 'scistema de mesuaçion',
 			'numbers' => 'numeri',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => {
 				'buddhist' => q{lunäio buddista},
 				'chinese' => q{lunäio cineise},
 				'coptic' => q{lunäio còpto},
 				'dangi' => q{lunäio dangi},
 				'ethiopic' => q{lunäio etiope},
 				'ethiopic-amete-alem' => q{lunäio etiope Amete Alem},
 				'gregorian' => q{lunäio gregorian},
 				'hebrew' => q{lunäio ebraico},
 				'islamic' => q{lunäio egirian},
 				'islamic-civil' => q{lunäio çivile egirian},
 				'islamic-umalqura' => q{lunäio egirian (Umm al-Qura)},
 				'iso8601' => q{lunäio ISO-8601},
 				'japanese' => q{lunäio giapponeise},
 				'persian' => q{lunäio perscian},
 				'roc' => q{lunäio repubrican cineise},
 			},
 			'cf' => {
 				'account' => q{formato de monæa contabile},
 				'standard' => q{formato de monæa standard},
 			},
 			'collation' => {
 				'ducet' => q{ordine predefinio de Unicode},
 				'search' => q{reçerca generica},
 				'standard' => q{ordine standard},
 			},
 			'hc' => {
 				'h11' => q{scistema oräio à 12 oe (0–11)},
 				'h12' => q{scistema oräio à 12 oe (1–12)},
 				'h23' => q{scistema oräio à 24 oe (0–23)},
 				'h24' => q{scistema oräio à 24 oe (1–24)},
 			},
 			'lb' => {
 				'loose' => q{stilo de interruçion de linia flescibile},
 				'normal' => q{stilo de interruçion de linia standard},
 				'strict' => q{stilo de interruçion de linia sforsou},
 			},
 			'ms' => {
 				'metric' => q{scistema metrico},
 				'uksystem' => q{scistema de mesuaçion imperiale},
 				'ussystem' => q{scistema de mesuaçion american},
 			},
 			'numbers' => {
 				'arab' => q{giffre indo-arabe},
 				'arabext' => q{giffre indo-arabe esteise},
 				'armn' => q{numeri ermeni},
 				'armnlow' => q{numeri ermeni piccin},
 				'beng' => q{giffre bengaleixi},
 				'cakm' => q{giffre chakma},
 				'deva' => q{giffre devanagari},
 				'ethi' => q{numeri etiopi},
 				'fullwide' => q{giffre à ampiessa intrega},
 				'geor' => q{numeri georgien},
 				'grek' => q{numeri greghi},
 				'greklow' => q{numeri greghi piccin},
 				'gujr' => q{giffre gujarati},
 				'guru' => q{giffre gurmuki},
 				'hanidec' => q{numeri deçimali cineixi},
 				'hans' => q{numeri cineixi semplificæ},
 				'hansfin' => q{numeri finansiäi in cineise semplificou},
 				'hant' => q{numeri cineixi tradiçionali},
 				'hantfin' => q{numeri finansiäi in cineise tradiçionale},
 				'hebr' => q{numeri ebraichi},
 				'java' => q{giffre giavaneixi},
 				'jpan' => q{numeri giapponeixi},
 				'jpanfin' => q{numeri finansiäi giapponeixi},
 				'khmr' => q{giffre khmer},
 				'knda' => q{giffre kannada},
 				'laoo' => q{giffre lao},
 				'latn' => q{giffre occidentale},
 				'mlym' => q{giffre malayalam},
 				'mtei' => q{giffre meetei mayek},
 				'mymr' => q{giffre birmañe},
 				'olck' => q{giffre ol chiki},
 				'orya' => q{giffre ödia},
 				'roman' => q{numeri romoen},
 				'romanlow' => q{numeri romoen piccin},
 				'taml' => q{giffre tamil tradiçionale},
 				'tamldec' => q{giffre tamil},
 				'telu' => q{giffre telugu},
 				'thai' => q{giffre tailandeixi},
 				'tibt' => q{giffre tibetañe},
 				'vaii' => q{giffre vaii},
 			},

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'metric' => q{metrico},
 			'UK' => q{imperiale},
 			'US' => q{american},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Lengua: {0}',
 			'script' => 'Scrittua: {0}',
 			'region' => 'Region: {0}',

		}
	},
);

has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			auxiliary => qr{[õō œ ř]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aàâä æ b cç d eéèêë f g h iìîï j k l m nñ oóòôö p q r s t uùûü v w x y z]},
			numbers => qr{[\- ‑ , . ' % ‰ + − 0 1 2 3 4 5 6 7 8 9 ª º]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … ’ "“” « » ( ) \[ \] § @ * / \& # † ‡]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(ponto cardinâ),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ponto cardinâ),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(yobi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobi{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(dexi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(dexi{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(pico{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(pico{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(femto{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(femto{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(atto{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atto{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(çenti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(çenti{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(zepto{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(zepto{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(yocto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yocto{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(milli{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(milli{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(micro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micro{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nano{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nano{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(deca{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deca{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(etto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(etto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(chillo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(chillo{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0} fòrsa g),
						'other' => q({0} fòrse g),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} fòrsa g),
						'other' => q({0} fòrse g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metri a-o segondo quaddro),
						'one' => q({0} metro a-o segondo quaddro),
						'other' => q({0} metri a-o segondo quaddro),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metri a-o segondo quaddro),
						'one' => q({0} metro a-o segondo quaddro),
						'other' => q({0} metri a-o segondo quaddro),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(primmi d’erco),
						'one' => q({0} primmo d’erco),
						'other' => q({0} primmi d’erco),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(primmi d’erco),
						'one' => q({0} primmo d’erco),
						'other' => q({0} primmi d’erco),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(segondi d’erco),
						'one' => q({0} segondo d’erco),
						'other' => q({0} segondi d’erco),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(segondi d’erco),
						'one' => q({0} segondo d’erco),
						'other' => q({0} segondi d’erco),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(graddi),
						'one' => q({0} graddo),
						'other' => q({0} graddi),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(graddi),
						'one' => q({0} graddo),
						'other' => q({0} graddi),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radianti),
						'one' => q({0} radiante),
						'other' => q({0} radianti),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radianti),
						'one' => q({0} radiante),
						'other' => q({0} radianti),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(revoluçioin),
						'one' => q({0} revoluçion),
						'other' => q({0} revoluçioin),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(revoluçioin),
						'one' => q({0} revoluçion),
						'other' => q({0} revoluçioin),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acri),
						'one' => q({0} acro),
						'other' => q({0} acri),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acri),
						'one' => q({0} acro),
						'other' => q({0} acri),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ettari),
						'one' => q({0} ettaro),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ettari),
						'one' => q({0} ettaro),
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(çentimetri quaddri),
						'one' => q({0} çentimetro quaddro),
						'other' => q({0} çentimetri quaddri),
						'per' => q({0} pe çentimetro quaddro),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(çentimetri quaddri),
						'one' => q({0} çentimetro quaddro),
						'other' => q({0} çentimetri quaddri),
						'per' => q({0} pe çentimetro quaddro),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(pê quaddri),
						'one' => q({0} pê quaddro),
						'other' => q({0} pê quaddri),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(pê quaddri),
						'one' => q({0} pê quaddro),
						'other' => q({0} pê quaddri),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(pòlliçi quaddri),
						'one' => q({0} pòlliçe quaddro),
						'other' => q({0} pòlliçi quaddri),
						'per' => q({0} pe pòlliçe quaddro),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(pòlliçi quaddri),
						'one' => q({0} pòlliçe quaddro),
						'other' => q({0} pòlliçi quaddri),
						'per' => q({0} pe pòlliçe quaddro),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(chillòmetri quaddri),
						'one' => q({0} chillòmetro quaddro),
						'other' => q({0} chillòmetri quaddri),
						'per' => q({0} pe chillòmetro quaddro),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(chillòmetri quaddri),
						'one' => q({0} chillòmetro quaddro),
						'other' => q({0} chillòmetri quaddri),
						'per' => q({0} pe chillòmetro quaddro),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metri quaddri),
						'one' => q({0} metro quaddro),
						'other' => q({0} metri quaddri),
						'per' => q({0} pe metro quaddro),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metri quaddri),
						'one' => q({0} metro quaddro),
						'other' => q({0} metri quaddri),
						'per' => q({0} pe metro quaddro),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(miggia quaddre),
						'one' => q({0} miggio quaddro),
						'other' => q({0} miggia quaddre),
						'per' => q({0} pe miggio quaddro),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(miggia quaddre),
						'one' => q({0} miggio quaddro),
						'other' => q({0} miggia quaddre),
						'per' => q({0} pe miggio quaddro),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(iarde quaddre),
						'one' => q({0} iarda quaddra),
						'other' => q({0} yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(iarde quaddre),
						'one' => q({0} iarda quaddra),
						'other' => q({0} yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(elemento),
						'one' => q({0} elemento),
						'other' => q({0} elementi),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(elemento),
						'one' => q({0} elemento),
						'other' => q({0} elementi),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(caratti),
						'one' => q({0} caratto),
						'other' => q({0} caratti),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(caratti),
						'one' => q({0} caratto),
						'other' => q({0} caratti),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrammi pe deçilitro),
						'one' => q({0} milligrammo pe deçilitro),
						'other' => q({0} milligrammi pe deçilitro),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrammi pe deçilitro),
						'one' => q({0} milligrammo pe deçilitro),
						'other' => q({0} milligrammi pe deçilitro),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimöle pe litro),
						'one' => q({0} millimöle pe litro),
						'other' => q({0} millimöle pe litro),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimöle pe litro),
						'one' => q({0} millimöle pe litro),
						'other' => q({0} millimöle pe litro),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(möle),
						'one' => q({0} möle),
						'other' => q({0} möle),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(möle),
						'one' => q({0} möle),
						'other' => q({0} möle),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(pe çento),
						'one' => q({0} pe çento),
						'other' => q({0} pe çento),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(pe çento),
						'one' => q({0} pe çento),
						'other' => q({0} pe çento),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(pe mille),
						'one' => q({0} pe mille),
						'other' => q({0} pe mille),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(pe mille),
						'one' => q({0} pe mille),
						'other' => q({0} pe mille),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(parte pe mion),
						'one' => q({0} parte pe mion),
						'other' => q({0} parte pe mion),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(parte pe mion),
						'one' => q({0} parte pe mion),
						'other' => q({0} parte pe mion),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(pe dexemia),
						'one' => q({0} pe dexemia),
						'other' => q({0} pe dexemia),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(pe dexemia),
						'one' => q({0} pe dexemia),
						'other' => q({0} pe dexemia),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litri pe 100 chillòmetri),
						'one' => q({0} litro pe 100 chillòmetri),
						'other' => q({0} litri pe 100 chillòmetri),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litri pe 100 chillòmetri),
						'one' => q({0} litro pe 100 chillòmetri),
						'other' => q({0} litri pe 100 chillòmetri),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litri pe chillòmetri),
						'one' => q({0} litro pe chillòmetri),
						'other' => q({0} litri pe chillòmetri),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litri pe chillòmetri),
						'one' => q({0} litro pe chillòmetri),
						'other' => q({0} litri pe chillòmetri),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(miggia pe gallon),
						'one' => q({0} miggio pe gallon),
						'other' => q({0} miggia pe gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(miggia pe gallon),
						'one' => q({0} miggio pe gallon),
						'other' => q({0} miggia pe gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(miggia pe gallon imperiale),
						'one' => q({0} miggio pe gallon imperiale),
						'other' => q({0} miggia pe gallon imperiale),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(miggia pe gallon imperiale),
						'one' => q({0} miggio pe gallon imperiale),
						'other' => q({0} miggia pe gallon imperiale),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} est),
						'north' => q({0} nòrd),
						'south' => q({0} sud),
						'west' => q({0} òvest),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} est),
						'north' => q({0} nòrd),
						'south' => q({0} sud),
						'west' => q({0} òvest),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(chillobit),
						'one' => q({0} chillobit),
						'other' => q({0} chillobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(chillobit),
						'one' => q({0} chillobit),
						'other' => q({0} chillobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(chillobyte),
						'one' => q({0} chillobyte),
						'other' => q({0} chillobyte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(chillobyte),
						'one' => q({0} chillobyte),
						'other' => q({0} chillobyte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabyte),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabyte),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(secoli),
						'one' => q({0} secolo),
						'other' => q({0} secoli),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(secoli),
						'one' => q({0} secolo),
						'other' => q({0} secoli),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(giorni),
						'one' => q({0} giorno),
						'other' => q({0} giorni),
						'per' => q({0} a-o giorno),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(giorni),
						'one' => q({0} giorno),
						'other' => q({0} giorni),
						'per' => q({0} a-o giorno),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dëxennio),
						'one' => q({0} dëxennio),
						'other' => q({0} dëxenni),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dëxennio),
						'one' => q({0} dëxennio),
						'other' => q({0} dëxenni),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'per' => q({0} à l’oa),
					},
					# Core Unit Identifier
					'hour' => {
						'per' => q({0} à l’oa),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(microsegondi),
						'one' => q({0} microsegondo),
						'other' => q({0} microsegondi),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(microsegondi),
						'one' => q({0} microsegondo),
						'other' => q({0} microsegondi),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisegondi),
						'one' => q({0} millisegondo),
						'other' => q({0} millisegondi),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisegondi),
						'one' => q({0} millisegondo),
						'other' => q({0} millisegondi),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(menuti),
						'one' => q({0} menuto),
						'other' => q({0} menuti),
						'per' => q({0} a-o menuto),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(menuti),
						'one' => q({0} menuto),
						'other' => q({0} menuti),
						'per' => q({0} a-o menuto),
					},
					# Long Unit Identifier
					'duration-month' => {
						'per' => q({0} a-o meise),
					},
					# Core Unit Identifier
					'month' => {
						'per' => q({0} a-o meise),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosegondi),
						'one' => q({0} nanosegondo),
						'other' => q({0} nanosegondi),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosegondi),
						'one' => q({0} nanosegondo),
						'other' => q({0} nanosegondi),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(trimestri),
						'one' => q({0} trimestre),
						'other' => q({0} trimestri),
						'per' => q({0} pe trimestre),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(trimestri),
						'one' => q({0} trimestre),
						'other' => q({0} trimestri),
						'per' => q({0} pe trimestre),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(segondi),
						'one' => q({0} segondo),
						'other' => q({0} segondi),
						'per' => q({0} a-o segondo),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(segondi),
						'one' => q({0} segondo),
						'other' => q({0} segondi),
						'per' => q({0} a-o segondo),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(settemañe),
						'one' => q({0} settemaña),
						'other' => q({0} settemañe),
						'per' => q({0} a-a settemaña),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(settemañe),
						'one' => q({0} settemaña),
						'other' => q({0} settemañe),
						'per' => q({0} a-a settemaña),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0} à l’anno),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0} à l’anno),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ampère),
						'one' => q({0} ampère),
						'other' => q({0} ampère),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ampère),
						'one' => q({0} ampère),
						'other' => q({0} ampère),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliampère),
						'one' => q({0} milliampère),
						'other' => q({0} milliampère),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliampère),
						'one' => q({0} milliampère),
						'other' => q({0} milliampère),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(vòlt),
						'one' => q({0} vòlt),
						'other' => q({0} vòlt),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(vòlt),
						'one' => q({0} vòlt),
						'other' => q({0} vòlt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(unitæ termiche britanniche),
						'one' => q({0} unitæ termica britannica),
						'other' => q({0} unitæ termiche britanniche),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(unitæ termiche britanniche),
						'one' => q({0} unitæ termica britannica),
						'other' => q({0} unitæ termiche britanniche),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(calorie),
						'one' => q({0} caloria),
						'other' => q({0} calorie),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(calorie),
						'one' => q({0} caloria),
						'other' => q({0} calorie),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elettronvòlt),
						'one' => q({0} elettronvòlt),
						'other' => q({0} elettronvòlt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elettronvòlt),
						'one' => q({0} elettronvòlt),
						'other' => q({0} elettronvòlt),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(chillocalorie),
						'one' => q({0} chillocaloria),
						'other' => q({0} chillocalorie),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(chillocalorie),
						'one' => q({0} chillocaloria),
						'other' => q({0} chillocalorie),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(chillojoule),
						'one' => q({0} chillojoule),
						'other' => q({0} chillojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(chillojoule),
						'one' => q({0} chillojoule),
						'other' => q({0} chillojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(chillowatt-oe),
						'one' => q({0} chillowatt-oa),
						'other' => q({0} chillowatt-oe),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(chillowatt-oe),
						'one' => q({0} chillowatt-oa),
						'other' => q({0} chillowatt-oe),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(therm US),
						'one' => q({0} therm US),
						'other' => q({0} therm US),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(therm US),
						'one' => q({0} therm US),
						'other' => q({0} therm US),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(chillowatt-oe pe 100 chillòmetri),
						'one' => q({0} chillowatt-oa pe 100 chillòmetri),
						'other' => q({0} chillowatt-oe pe 100 chillòmetri),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(chillowatt-oe pe 100 chillòmetri),
						'one' => q({0} chillowatt-oa pe 100 chillòmetri),
						'other' => q({0} chillowatt-oe pe 100 chillòmetri),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(lie-fòrsa),
						'one' => q({0} lia-fòrsa),
						'other' => q({0} lie-fòrsa),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(lie-fòrsa),
						'one' => q({0} lia-fòrsa),
						'other' => q({0} lie-fòrsa),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(chillohertz),
						'one' => q({0} chillohertz),
						'other' => q({0} chillohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(chillohertz),
						'one' => q({0} chillohertz),
						'other' => q({0} chillohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(emme tipografica),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(emme tipografica),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0} megapixel),
						'other' => q({0} megapixel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0} megapixel),
						'other' => q({0} megapixel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pixel per çentimetro),
						'one' => q({0} pixel per çentimetro),
						'other' => q({0} pixel per çentimetro),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pixel per çentimetro),
						'one' => q({0} pixel per çentimetro),
						'other' => q({0} pixel per çentimetro),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixel pe pòlliçe),
						'one' => q({0} pixel pe pòlliçe),
						'other' => q({0} pixel pe pòlliçe),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixel pe pòlliçe),
						'one' => q({0} pixel pe pòlliçe),
						'other' => q({0} pixel pe pòlliçe),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unitæ astronòmiche),
						'one' => q({0} unitæ astronòmica),
						'other' => q({0} unitæ astronòmiche),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unitæ astronòmiche),
						'one' => q({0} unitæ astronòmica),
						'other' => q({0} unitæ astronòmiche),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(çentimetri),
						'one' => q({0} çentimetro),
						'other' => q({0} çentimetri),
						'per' => q({0} pe çentimetro),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(çentimetri),
						'one' => q({0} çentimetro),
						'other' => q({0} çentimetri),
						'per' => q({0} pe çentimetro),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(deximetri),
						'one' => q({0} deximetro),
						'other' => q({0} deximetri),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(deximetri),
						'one' => q({0} deximetro),
						'other' => q({0} deximetri),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(raggi da Tæra),
						'one' => q({0} raggio da Tæra),
						'other' => q({0} raggi da Tæra),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(raggi da Tæra),
						'one' => q({0} raggio da Tæra),
						'other' => q({0} raggi da Tæra),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(brasse),
						'one' => q({0} brasso),
						'other' => q({0} brasse),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(brasse),
						'one' => q({0} brasso),
						'other' => q({0} brasse),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(pê),
						'one' => q({0} pê),
						'other' => q({0} pê),
						'per' => q({0} pe pê),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(pê),
						'one' => q({0} pê),
						'other' => q({0} pê),
						'per' => q({0} pe pê),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(pòlliçi),
						'one' => q({0} pòlliçe),
						'other' => q({0} pòlliçi),
						'per' => q({0} pe pòlliçe),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(pòlliçi),
						'one' => q({0} pòlliçe),
						'other' => q({0} pòlliçi),
						'per' => q({0} pe pòlliçe),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(chillòmetri),
						'one' => q({0} chillòmetro),
						'other' => q({0} chillòmetri),
						'per' => q({0} pe chillòmetro),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(chillòmetri),
						'one' => q({0} chillòmetro),
						'other' => q({0} chillòmetri),
						'per' => q({0} pe chillòmetro),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(anni luxe),
						'one' => q({0} anno luxe),
						'other' => q({0} anni luxe),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(anni luxe),
						'one' => q({0} anno luxe),
						'other' => q({0} anni luxe),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metri),
						'one' => q({0} metro),
						'other' => q({0} metri),
						'per' => q({0} pe metro),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metri),
						'one' => q({0} metro),
						'other' => q({0} metri),
						'per' => q({0} pe metro),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(micrometri),
						'one' => q({0} micrometro),
						'other' => q({0} micrometri),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(micrometri),
						'one' => q({0} micrometro),
						'other' => q({0} micrometri),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(miggia),
						'one' => q({0} miggio),
						'other' => q({0} miggia),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(miggia),
						'one' => q({0} miggio),
						'other' => q({0} miggia),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(miggia scandinave),
						'one' => q({0} miggio scandinavo),
						'other' => q({0} miggia scandinave),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(miggia scandinave),
						'one' => q({0} miggio scandinavo),
						'other' => q({0} miggia scandinave),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millimetri),
						'one' => q({0} millimetro),
						'other' => q({0} millimetri),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimetri),
						'one' => q({0} millimetro),
						'other' => q({0} millimetri),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometri),
						'one' => q({0} nanometro),
						'other' => q({0} nanometri),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometri),
						'one' => q({0} nanometro),
						'other' => q({0} nanometri),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(miggia de navegaçion),
						'one' => q({0} miggio de navegaçion),
						'other' => q({0} miggia de navegaçion),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(miggia de navegaçion),
						'one' => q({0} miggio de navegaçion),
						'other' => q({0} miggia de navegaçion),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(picometri),
						'one' => q({0} picometro),
						'other' => q({0} picometri),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(picometri),
						'one' => q({0} picometro),
						'other' => q({0} picometri),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(ponti tipografichi),
						'one' => q({0} ponto tipografico),
						'other' => q({0} ponti tipografichi),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(ponti tipografichi),
						'one' => q({0} ponto tipografico),
						'other' => q({0} ponti tipografichi),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(raggi do Sô),
						'one' => q({0} raggio do Sô),
						'other' => q({0} raggi do Sô),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(raggi do Sô),
						'one' => q({0} raggio do Sô),
						'other' => q({0} raggi do Sô),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(iarde),
						'one' => q({0} iarda),
						'other' => q({0} iarde),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(iarde),
						'one' => q({0} iarda),
						'other' => q({0} iarde),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(candeie),
						'one' => q({0} candeia),
						'other' => q({0} candeie),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(candeie),
						'one' => q({0} candeia),
						'other' => q({0} candeie),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(luminoxitæ do Sô),
						'one' => q({0} luminoxitæ do Sô),
						'other' => q({0} luminoxitæ do Sô),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(luminoxitæ do Sô),
						'one' => q({0} luminoxitæ do Sô),
						'other' => q({0} luminoxitæ do Sô),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(caratti),
						'one' => q({0} caratto),
						'other' => q({0} caratti),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(caratti),
						'one' => q({0} caratto),
						'other' => q({0} caratti),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(dalton),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(dalton),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(masse da Tæra),
						'one' => q({0} massa da Tæra),
						'other' => q({0} masse da Tæra),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(masse da Tæra),
						'one' => q({0} massa da Tæra),
						'other' => q({0} masse da Tæra),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grammi),
						'one' => q({0} grammo),
						'other' => q({0} grammi),
						'per' => q({0} pe grammo),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grammi),
						'one' => q({0} grammo),
						'other' => q({0} grammi),
						'per' => q({0} pe grammo),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(chillogrammi),
						'one' => q({0} chillogrammo),
						'other' => q({0} chillogrammi),
						'per' => q({0} pe chillogrammo),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(chillogrammi),
						'one' => q({0} chillogrammo),
						'other' => q({0} chillogrammi),
						'per' => q({0} pe chillogrammo),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(microgrammi),
						'one' => q({0} microgrammo),
						'other' => q({0} microgrammi),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(microgrammi),
						'one' => q({0} microgrammo),
						'other' => q({0} microgrammi),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(milligrammi),
						'one' => q({0} milligrammo),
						'other' => q({0} milligrammi),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(milligrammi),
						'one' => q({0} milligrammo),
						'other' => q({0} milligrammi),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(onse),
						'one' => q({0} onsa),
						'other' => q({0} onse),
						'per' => q({0} pe onsa),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(onse),
						'one' => q({0} onsa),
						'other' => q({0} onse),
						'per' => q({0} pe onsa),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(onse troy),
						'one' => q({0} onsa troy),
						'other' => q({0} onse troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(onse troy),
						'one' => q({0} onsa troy),
						'other' => q({0} onse troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(lie),
						'one' => q({0} lia),
						'other' => q({0} lie),
						'per' => q({0} pe lia),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lie),
						'one' => q({0} lia),
						'other' => q({0} lie),
						'per' => q({0} pe lia),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(masse do Sô),
						'one' => q({0} massa do Sô),
						'other' => q({0} masse do Sô),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(masse do Sô),
						'one' => q({0} massa do Sô),
						'other' => q({0} masse do Sô),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tonnëi curti),
						'one' => q({0} tonneo curto),
						'other' => q({0} tonnëi curti),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tonnëi curti),
						'one' => q({0} tonneo curto),
						'other' => q({0} tonnëi curti),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tonnëi metrichi),
						'one' => q({0} tonneo metrico),
						'other' => q({0} tonnëi metrichi),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tonnëi metrichi),
						'one' => q({0} tonneo metrico),
						'other' => q({0} tonnëi metrichi),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} pe {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} pe {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawatt),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawatt),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(cavalli vapô),
						'one' => q({0} cavallo vapô),
						'other' => q({0} cavalli vapô),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(cavalli vapô),
						'one' => q({0} cavallo vapô),
						'other' => q({0} cavalli vapô),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(chillowatt),
						'one' => q({0} chillowatt),
						'other' => q({0} chillowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(chillowatt),
						'one' => q({0} chillowatt),
						'other' => q({0} chillowatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					# Long Unit Identifier
					'power2' => {
						'one' => q({0} quaddro),
						'other' => q({0} quaddri),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q({0} quaddro),
						'other' => q({0} quaddri),
					},
					# Long Unit Identifier
					'power3' => {
						'one' => q({0} cubbo),
						'other' => q({0} cubbi),
					},
					# Core Unit Identifier
					'power3' => {
						'one' => q({0} cubbo),
						'other' => q({0} cubbi),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfere),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfere),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfere),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfere),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(ettopascal),
						'one' => q({0} ettopascal),
						'other' => q({0} ettopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(ettopascal),
						'one' => q({0} ettopascal),
						'other' => q({0} ettopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(pòlliçi de mercuio),
						'one' => q({0} pòlliçe de mercuio),
						'other' => q({0} pòlliçi de mercuio),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(pòlliçi de mercuio),
						'one' => q({0} pòlliçe de mercuio),
						'other' => q({0} pòlliçi de mercuio),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(chillopascal),
						'one' => q({0} chillopascal),
						'other' => q({0} chillopascal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(chillopascal),
						'one' => q({0} chillopascal),
						'other' => q({0} chillopascal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapascal),
						'one' => q({0} megapascal),
						'other' => q({0} megapascal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapascal),
						'one' => q({0} megapascal),
						'other' => q({0} megapascal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(millimetri de mercuio),
						'one' => q({0} millimetro de mercuio),
						'other' => q({0} millimetri de mercuio),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(millimetri de mercuio),
						'one' => q({0} millimetro de mercuio),
						'other' => q({0} millimetri de mercuio),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(pascal),
						'one' => q({0} pascal),
						'other' => q({0} pascal),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(pascal),
						'one' => q({0} pascal),
						'other' => q({0} pascal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(lie-fòrsa pe pòlliçe quaddro),
						'one' => q({0} lia-fòrsa pe pòlliçe quaddro),
						'other' => q({0} lie-fòrsa pe pòlliçe quaddro),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(lie-fòrsa pe pòlliçe quaddro),
						'one' => q({0} lia-fòrsa pe pòlliçe quaddro),
						'other' => q({0} lie-fòrsa pe pòlliçe quaddro),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(chillòmetri à l’oa),
						'one' => q({0} chillòmetro à l’oa),
						'other' => q({0} chillòmetri à l’oa),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(chillòmetri à l’oa),
						'one' => q({0} chillòmetro à l’oa),
						'other' => q({0} chillòmetri à l’oa),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nödi),
						'one' => q({0} nödo),
						'other' => q({0} nödi),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nödi),
						'one' => q({0} nödo),
						'other' => q({0} nödi),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metri a-o segondo),
						'one' => q({0} metro a-o segondo),
						'other' => q({0} metri a-o segondo),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metri a-o segondo),
						'one' => q({0} metro a-o segondo),
						'other' => q({0} metri a-o segondo),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(miggia à l’oa),
						'one' => q({0} miggio à l’oa),
						'other' => q({0} miggia à l’oa),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(miggia à l’oa),
						'one' => q({0} miggio à l’oa),
						'other' => q({0} miggia à l’oa),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(graddi Celsius),
						'one' => q({0} graddo Celsius),
						'other' => q({0} graddi Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(graddi Celsius),
						'one' => q({0} graddo Celsius),
						'other' => q({0} graddi Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(graddi Fahrenheit),
						'one' => q({0} graddo Fahrenheit),
						'other' => q({0} graddi Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(graddi Fahrenheit),
						'one' => q({0} graddo Fahrenheit),
						'other' => q({0} graddi Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(graddi),
						'one' => q({0} graddo),
						'other' => q({0} graddi),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(graddi),
						'one' => q({0} graddo),
						'other' => q({0} graddi),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newton-metri),
						'one' => q({0} newton-metro),
						'other' => q({0} newton-metri),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton-metri),
						'one' => q({0} newton-metro),
						'other' => q({0} newton-metri),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(lie-fòrsa-pê),
						'one' => q({0} lia-fòrsa-pê),
						'other' => q({0} lie-fòrsa-pê),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(lie-fòrsa-pê),
						'one' => q({0} lia-fòrsa-pê),
						'other' => q({0} lie-fòrsa-pê),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acri-pê),
						'one' => q({0} acro-pê),
						'other' => q({0} acri-pê),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acri-pê),
						'one' => q({0} acro-pê),
						'other' => q({0} acri-pê),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barî),
						'one' => q({0} barî),
						'other' => q({0} barî),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barî),
						'one' => q({0} barî),
						'other' => q({0} barî),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(stæ),
						'one' => q({0} stâ),
						'other' => q({0} stæ),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(stæ),
						'one' => q({0} stâ),
						'other' => q({0} stæ),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(çentilitri),
						'one' => q({0} çentilitro),
						'other' => q({0} çentilitri),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(çentilitri),
						'one' => q({0} çentilitro),
						'other' => q({0} çentilitri),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(çentimetri cubbi),
						'one' => q({0} çentimetro cubbo),
						'other' => q({0} çentimetri cubbi),
						'per' => q({0} pe çentimetro cubbo),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(çentimetri cubbi),
						'one' => q({0} çentimetro cubbo),
						'other' => q({0} çentimetri cubbi),
						'per' => q({0} pe çentimetro cubbo),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(pê cubbi),
						'one' => q({0} pê cubbo),
						'other' => q({0} pê cubbi),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(pê cubbi),
						'one' => q({0} pê cubbo),
						'other' => q({0} pê cubbi),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(pòlliçi cubbi),
						'one' => q({0} pòlliçe cubbo),
						'other' => q({0} pòlliçi cubbi),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(pòlliçi cubbi),
						'one' => q({0} pòlliçe cubbo),
						'other' => q({0} pòlliçi cubbi),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(chillòmetri cubbi),
						'one' => q({0} chillòmetro cubbo),
						'other' => q({0} chillòmetri cubbi),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(chillòmetri cubbi),
						'one' => q({0} chillòmetro cubbo),
						'other' => q({0} chillòmetri cubbi),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(metri cubbi),
						'one' => q({0} metro cubbo),
						'other' => q({0} metri cubbi),
						'per' => q({0} pe metro cubbo),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(metri cubbi),
						'one' => q({0} metro cubbo),
						'other' => q({0} metri cubbi),
						'per' => q({0} pe metro cubbo),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(miggia cubbe),
						'one' => q({0} miggio cubbo),
						'other' => q({0} miggia cubbe),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(miggia cubbe),
						'one' => q({0} miggio cubbo),
						'other' => q({0} miggia cubbe),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(iarde cubbe),
						'one' => q({0} iarda cubba),
						'other' => q({0} iarde cubbe),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(iarde cubbe),
						'one' => q({0} iarda cubba),
						'other' => q({0} iarde cubbe),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(tassa),
						'one' => q({0} tassa),
						'other' => q({0} tasse),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(tassa),
						'one' => q({0} tassa),
						'other' => q({0} tasse),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(tasse metriche),
						'one' => q({0} tassa metrica),
						'other' => q({0} tasse metriche),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(tasse metriche),
						'one' => q({0} tassa metrica),
						'other' => q({0} tasse metriche),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dexilitri),
						'one' => q({0} dexilitro),
						'other' => q({0} dexilitri),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dexilitri),
						'one' => q({0} dexilitro),
						'other' => q({0} dexilitri),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(cuggiæn da cafè),
						'one' => q({0} cuggiæn da cafè),
						'other' => q({0} cuggiæn da cafè),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(cuggiæn da cafè),
						'one' => q({0} cuggiæn da cafè),
						'other' => q({0} cuggiæn da cafè),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(cuggiæn da cafè imperiali),
						'one' => q({0} cuggiæn da cafè imperiale),
						'other' => q({0} cuggiæn da cafè imperiali),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(cuggiæn da cafè imperiali),
						'one' => q({0} cuggiæn da cafè imperiale),
						'other' => q({0} cuggiæn da cafè imperiali),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dramme liquide),
						'one' => q({0} dramma liquida),
						'other' => q({0} dramme liquide),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dramme liquide),
						'one' => q({0} dramma liquida),
						'other' => q({0} dramme liquide),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(onse liquide),
						'one' => q({0} onsa liquida),
						'other' => q({0} onse liquide),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(onse liquide),
						'one' => q({0} onsa liquida),
						'other' => q({0} onse liquide),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(onse liquide imperiale),
						'one' => q({0} onsa liquida imperiale),
						'other' => q({0} onse liquide imperiale),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(onse liquide imperiale),
						'one' => q({0} onsa liquida imperiale),
						'other' => q({0} onse liquide imperiale),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galloin),
						'one' => q({0} gallon),
						'other' => q({0} galloin),
						'per' => q({0} pe gallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galloin),
						'one' => q({0} gallon),
						'other' => q({0} galloin),
						'per' => q({0} pe gallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(galloin imperiali),
						'one' => q({0} gallon imperiale),
						'other' => q({0} galloin imperiali),
						'per' => q({0} pe gallon imperiale),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(galloin imperiali),
						'one' => q({0} gallon imperiale),
						'other' => q({0} galloin imperiali),
						'per' => q({0} pe gallon imperiale),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(ettòlitri),
						'one' => q({0} ettòlitro),
						'other' => q({0} ettòlitri),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(ettòlitri),
						'one' => q({0} ettòlitro),
						'other' => q({0} ettòlitri),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litri),
						'one' => q({0} litro),
						'other' => q({0} litri),
						'per' => q({0} pe litro),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litri),
						'one' => q({0} litro),
						'other' => q({0} litri),
						'per' => q({0} pe litro),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitri),
						'one' => q({0} megalitro),
						'other' => q({0} megalitri),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitri),
						'one' => q({0} megalitro),
						'other' => q({0} megalitri),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(millilitri),
						'one' => q({0} millilitro),
						'other' => q({0} millilitri),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(millilitri),
						'one' => q({0} millilitro),
						'other' => q({0} millilitri),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pinte),
						'one' => q({0} pinta),
						'other' => q({0} pinte),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pinte),
						'one' => q({0} pinta),
						'other' => q({0} pinte),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pinte metriche),
						'one' => q({0} pinta metrica),
						'other' => q({0} pinte metriche),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pinte metriche),
						'one' => q({0} pinta metrica),
						'other' => q({0} pinte metriche),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(quarti),
						'one' => q({0} quarto),
						'other' => q({0} quarti),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(quarti),
						'one' => q({0} quarto),
						'other' => q({0} quarti),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(quarto imperiale),
						'one' => q({0} quarto imperiale),
						'other' => q({0} quarti imperiali),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(quarto imperiale),
						'one' => q({0} quarto imperiale),
						'other' => q({0} quarti imperiali),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(cuggiæ),
						'one' => q({0} cuggiâ),
						'other' => q({0} cuggiæ),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(cuggiæ),
						'one' => q({0} cuggiâ),
						'other' => q({0} cuggiæ),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(cuggiæn),
						'one' => q({0} cuggiæn),
						'other' => q({0} cuggiæn),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(cuggiæn),
						'one' => q({0} cuggiæn),
						'other' => q({0} cuggiæn),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0} G),
						'other' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} G),
						'other' => q({0}G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q({0}rev),
						'other' => q({0}rev),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0}rev),
						'other' => q({0}rev),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'one' => q({0}dunam),
						'other' => q({0}dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'one' => q({0}dunam),
						'other' => q({0}dunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'one' => q({0}cm²),
						'other' => q({0}cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q({0}cm²),
						'other' => q({0}cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'one' => q({0}in²),
						'other' => q({0}in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'one' => q({0}in²),
						'other' => q({0}in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0}mi²),
						'other' => q({0}mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0}mi²),
						'other' => q({0}mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'one' => q({0}yd²),
						'other' => q({0}yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'one' => q({0}yd²),
						'other' => q({0}yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(elem),
						'one' => q({0}elem),
						'other' => q({0}elem),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(elem),
						'one' => q({0}elem),
						'other' => q({0}elem),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'one' => q({0}mol),
						'other' => q({0}mol),
					},
					# Core Unit Identifier
					'mole' => {
						'one' => q({0}mol),
						'other' => q({0}mol),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'one' => q({0}l/km),
						'other' => q({0}l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'one' => q({0}l/km),
						'other' => q({0}l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'one' => q({0}mpg),
						'other' => q({0}mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'one' => q({0}mpg),
						'other' => q({0}mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg im),
						'one' => q({0}mpg im),
						'other' => q({0}mpg im),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg im),
						'one' => q({0}mpg im),
						'other' => q({0}mpg im),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}Ò),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}Ò),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0}bit),
						'other' => q({0}bit),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0}bit),
						'other' => q({0}bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'one' => q({0}GB),
						'other' => q({0}GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'one' => q({0}GB),
						'other' => q({0}GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'one' => q({0}kB),
						'other' => q({0}kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'one' => q({0}kB),
						'other' => q({0}kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'one' => q({0}PB),
						'other' => q({0}PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'one' => q({0}PB),
						'other' => q({0}PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(sec),
						'one' => q({0}sec),
						'other' => q({0}sec),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sec),
						'one' => q({0}sec),
						'other' => q({0}sec),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dëx),
						'one' => q({0}dëx),
						'other' => q({0}dëx),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dëx),
						'one' => q({0}dëx),
						'other' => q({0}dëx),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
						'one' => q({0}h),
						'other' => q({0}h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
						'one' => q({0}h),
						'other' => q({0}h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0}men),
						'other' => q({0}men),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0}men),
						'other' => q({0}men),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0}meise),
						'other' => q({0}meixi),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0}meise),
						'other' => q({0}meixi),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(tr),
						'one' => q({0}tr),
						'other' => q({0}tr),
						'per' => q({0}/tr),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(tr),
						'one' => q({0}tr),
						'other' => q({0}tr),
						'per' => q({0}/tr),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0}s),
						'other' => q({0}s),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0}s),
						'other' => q({0}s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sett),
						'one' => q({0}sett),
						'other' => q({0}sett),
						'per' => q({0}/sett),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sett),
						'one' => q({0}sett),
						'other' => q({0}sett),
						'per' => q({0}/sett),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(a),
						'one' => q({0}a),
						'other' => q({0}a),
						'per' => q({0}/a),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(a),
						'one' => q({0}a),
						'other' => q({0}a),
						'per' => q({0}/a),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q({0}A),
						'other' => q({0}A),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q({0}A),
						'other' => q({0}A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'one' => q({0}BTU),
						'other' => q({0}BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'one' => q({0}BTU),
						'other' => q({0}BTU),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'one' => q({0}cal),
						'other' => q({0}cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'one' => q({0}cal),
						'other' => q({0}cal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'one' => q({0}eV),
						'other' => q({0}eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'one' => q({0}eV),
						'other' => q({0}eV),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0}J),
						'other' => q({0}J),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0}J),
						'other' => q({0}J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'one' => q({0}kJ),
						'other' => q({0}kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'one' => q({0}kJ),
						'other' => q({0}kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'one' => q({0}kWh),
						'other' => q({0}kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'one' => q({0}kWh),
						'other' => q({0}kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q({0}thm US),
						'other' => q({0}thm US),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q({0}thm US),
						'other' => q({0}thm US),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'one' => q({0}N),
						'other' => q({0}N),
					},
					# Core Unit Identifier
					'newton' => {
						'one' => q({0}N),
						'other' => q({0}N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'one' => q({0}lbf),
						'other' => q({0}lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'one' => q({0}lbf),
						'other' => q({0}lbf),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'one' => q({0}GHz),
						'other' => q({0}GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'one' => q({0}GHz),
						'other' => q({0}GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'one' => q({0}Hz),
						'other' => q({0}Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'one' => q({0}Hz),
						'other' => q({0}Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'one' => q({0}kHz),
						'other' => q({0}kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'one' => q({0}kHz),
						'other' => q({0}kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'one' => q({0}em),
						'other' => q({0}em),
					},
					# Core Unit Identifier
					'em' => {
						'one' => q({0}em),
						'other' => q({0}em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(MP),
						'one' => q({0}Mpx),
						'other' => q({0}Mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(MP),
						'one' => q({0}Mpx),
						'other' => q({0}Mpx),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(px),
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(px),
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'one' => q({0}px/cm),
						'other' => q({0}px/cm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'one' => q({0}px/cm),
						'other' => q({0}px/cm),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q({0}au),
						'other' => q({0}au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q({0}au),
						'other' => q({0}au),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0}fth),
						'other' => q({0}fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0}fth),
						'other' => q({0}fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0}ft),
						'other' => q({0}ft),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0}ft),
						'other' => q({0}ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0}in),
						'other' => q({0}in),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0}in),
						'other' => q({0}in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0}ly),
						'other' => q({0}ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0}ly),
						'other' => q({0}ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q({0}nmi),
						'other' => q({0}nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0}nmi),
						'other' => q({0}nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					# Long Unit Identifier
					'light-candela' => {
						'one' => q({0}cd),
						'other' => q({0}cd),
					},
					# Core Unit Identifier
					'candela' => {
						'one' => q({0}cd),
						'other' => q({0}cd),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'one' => q({0}lm),
						'other' => q({0}lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'one' => q({0}lm),
						'other' => q({0}lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0}L☉),
						'other' => q({0}L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0}L☉),
						'other' => q({0}L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q({0}Da),
						'other' => q({0}Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q({0}Da),
						'other' => q({0}Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'one' => q({0}graña),
						'other' => q({0}grañe),
					},
					# Core Unit Identifier
					'grain' => {
						'one' => q({0}graña),
						'other' => q({0}grañe),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'one' => q({0}μg),
						'other' => q({0}μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'one' => q({0}μg),
						'other' => q({0}μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'one' => q({0}mg),
						'other' => q({0}mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'one' => q({0}mg),
						'other' => q({0}mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0}oz),
						'other' => q({0}oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0}oz),
						'other' => q({0}oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'one' => q({0}oz t),
						'other' => q({0}oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q({0}oz t),
						'other' => q({0}oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0}lb),
						'other' => q({0}lb),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0}lb),
						'other' => q({0}lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0}M☉),
						'other' => q({0}M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0}M☉),
						'other' => q({0}M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'tonne' => {
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'one' => q({0}GW),
						'other' => q({0}GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'one' => q({0}GW),
						'other' => q({0}GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0}hp),
						'other' => q({0}hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0}hp),
						'other' => q({0}hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'one' => q({0}mW),
						'other' => q({0}mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'one' => q({0}mW),
						'other' => q({0}mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'one' => q({0}atm),
						'other' => q({0}atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'one' => q({0}atm),
						'other' => q({0}atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q({0}bar),
						'other' => q({0}bar),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q({0}bar),
						'other' => q({0}bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0}inHg),
						'other' => q({0}inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0}inHg),
						'other' => q({0}inHg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'one' => q({0}kPa),
						'other' => q({0}kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'one' => q({0}kPa),
						'other' => q({0}kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'one' => q({0}MPa),
						'other' => q({0}MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'one' => q({0}MPa),
						'other' => q({0}MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'one' => q({0}Pa),
						'other' => q({0}Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'one' => q({0}Pa),
						'other' => q({0}Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'one' => q({0}psi),
						'other' => q({0}psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'one' => q({0}psi),
						'other' => q({0}psi),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0}mi/h),
						'other' => q({0}mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0}mi/h),
						'other' => q({0}mi/h),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'one' => q({0}N⋅m),
						'other' => q({0}N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'one' => q({0}N⋅m),
						'other' => q({0}N⋅m),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acft),
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acft),
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0}bu),
						'other' => q({0}bu),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0}bu),
						'other' => q({0}bu),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'one' => q({0}cl),
						'other' => q({0}cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'one' => q({0}cl),
						'other' => q({0}cl),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'one' => q({0}cm³),
						'other' => q({0}cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q({0}cm³),
						'other' => q({0}cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'one' => q({0}ft³),
						'other' => q({0}ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'one' => q({0}ft³),
						'other' => q({0}ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'one' => q({0}in³),
						'other' => q({0}in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'one' => q({0}in³),
						'other' => q({0}in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'one' => q({0}m³),
						'other' => q({0}m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'one' => q({0}m³),
						'other' => q({0}m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'one' => q({0}yd³),
						'other' => q({0}yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'one' => q({0}yd³),
						'other' => q({0}yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0}c),
						'other' => q({0}c),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0}c),
						'other' => q({0}c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q({0}mc),
						'other' => q({0}mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q({0}mc),
						'other' => q({0}mc),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'one' => q({0}dl),
						'other' => q({0}dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'one' => q({0}dl),
						'other' => q({0}dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dsp),
						'one' => q({0}dsp),
						'other' => q({0}dsp),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dsp),
						'one' => q({0}dsp),
						'other' => q({0}dsp),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dsp im),
						'one' => q({0}dsp im),
						'other' => q({0}dsp im),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dsp im),
						'one' => q({0}dsp im),
						'other' => q({0}dsp im),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dr liq),
						'one' => q({0}dr liq),
						'other' => q({0}dr liq),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dr liq),
						'one' => q({0}dr liq),
						'other' => q({0}dr liq),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(st),
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(st),
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(fl oz im),
						'one' => q({0}fl oz im),
						'other' => q({0}fl oz im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fl oz im),
						'one' => q({0}fl oz im),
						'other' => q({0}fl oz im),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'one' => q({0}gal),
						'other' => q({0}gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'one' => q({0}gal),
						'other' => q({0}gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(galim),
						'one' => q({0}galim),
						'other' => q({0}galim),
						'per' => q({0}/galim),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(galim),
						'one' => q({0}galim),
						'other' => q({0}galim),
						'per' => q({0}/galim),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'one' => q({0}hl),
						'other' => q({0}hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'one' => q({0}hl),
						'other' => q({0}hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'one' => q({0}jigger),
						'other' => q({0}jigger),
					},
					# Core Unit Identifier
					'jigger' => {
						'one' => q({0}jigger),
						'other' => q({0}jigger),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'one' => q({0}Ml),
						'other' => q({0}Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'one' => q({0}Ml),
						'other' => q({0}Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'one' => q({0}ml),
						'other' => q({0}ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'one' => q({0}ml),
						'other' => q({0}ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(sp),
						'one' => q({0}sp),
						'other' => q({0}sp),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(sp),
						'one' => q({0}sp),
						'other' => q({0}sp),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'pint' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'one' => q({0}mpt),
						'other' => q({0}mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'one' => q({0}mpt),
						'other' => q({0}mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					# Core Unit Identifier
					'quart' => {
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt im),
						'one' => q({0}qt im),
						'other' => q({0}qt im),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt im),
						'one' => q({0}qt im),
						'other' => q({0}qt im),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'one' => q({0}tbsp),
						'other' => q({0}tbsp),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'one' => q({0}tbsp),
						'other' => q({0}tbsp),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'one' => q({0}tsp),
						'other' => q({0}tsp),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'one' => q({0}tsp),
						'other' => q({0}tsp),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(ponto),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ponto),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(fòrsa g),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(fòrsa g),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(°),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ac),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(elem.),
						'one' => q({0} elem.),
						'other' => q({0} elem.),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(elem.),
						'one' => q({0} elem.),
						'other' => q({0} elem.),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg imp.),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg imp.),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} Ò),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} Ò),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(sec.),
						'one' => q({0} sec.),
						'other' => q({0} sec.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sec.),
						'one' => q({0} sec.),
						'other' => q({0} sec.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dëx.),
						'one' => q({0} dëx.),
						'other' => q({0} dëx.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dëx.),
						'one' => q({0} dëx.),
						'other' => q({0} dëx.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(oe),
						'one' => q({0} oa),
						'other' => q({0} oe),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(oe),
						'one' => q({0} oa),
						'other' => q({0} oe),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(men),
						'one' => q({0} men.),
						'other' => q({0} men.),
						'per' => q({0}/men),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(men),
						'one' => q({0} men.),
						'other' => q({0} men.),
						'per' => q({0}/men),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(meixi),
						'one' => q({0} meise),
						'other' => q({0} meixi),
						'per' => q({0}/meise),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(meixi),
						'one' => q({0} meise),
						'other' => q({0} meixi),
						'per' => q({0}/meise),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(trim.),
						'one' => q({0} trim.),
						'other' => q({0} trim.),
						'per' => q({0}/trim.),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(trim.),
						'one' => q({0} trim.),
						'other' => q({0} trim.),
						'per' => q({0}/trim.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sett.),
						'one' => q({0} sett.),
						'other' => q({0} sett.),
						'per' => q({0}/sett.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sett.),
						'one' => q({0} sett.),
						'other' => q({0} sett.),
						'per' => q({0}/sett.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(anni),
						'one' => q({0} anno),
						'other' => q({0} anni),
						'per' => q({0}/anno),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(anni),
						'one' => q({0} anno),
						'other' => q({0} anni),
						'per' => q({0}/anno),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(A),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(J),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(thm US),
						'one' => q({0} thm US),
						'other' => q({0} thm US),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(thm US),
						'one' => q({0} thm US),
						'other' => q({0} thm US),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixel),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixel),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixel),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(px/cm),
						'one' => q({0} px/cm),
						'other' => q({0} px/cm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(px/cm),
						'one' => q({0} px/cm),
						'other' => q({0} px/cm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(px/in),
						'one' => q({0} px/in),
						'other' => q({0} px/in),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(px/in),
						'one' => q({0} px/in),
						'other' => q({0} px/in),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(grañe),
						'one' => q({0} graña),
						'other' => q({0} grañe),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(grañe),
						'one' => q({0} graña),
						'other' => q({0} grañe),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(c),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mc),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dstspn imp.),
						'one' => q({0} dstspn imp.),
						'other' => q({0} dstspn imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dstspn imp.),
						'one' => q({0} dstspn imp.),
						'other' => q({0} dstspn imp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dramme liq.),
						'one' => q({0} dramma liq.),
						'other' => q({0} dramme liq.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dramme liq.),
						'one' => q({0} dramma liq.),
						'other' => q({0} dramme liq.),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(stisse),
						'one' => q({0} stissa),
						'other' => q({0} stisse),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(stisse),
						'one' => q({0} stissa),
						'other' => q({0} stisse),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(fl oz imp.),
						'one' => q({0} fl oz imp.),
						'other' => q({0} fl oz imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fl oz imp.),
						'one' => q({0} fl oz imp.),
						'other' => q({0} fl oz imp.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0}/gal imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0}/gal imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hl),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(spellinsegæ),
						'one' => q({0} spellinsegâ),
						'other' => q({0} spellinsegæ),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(spellinsegæ),
						'one' => q({0} spellinsegâ),
						'other' => q({0} spellinsegæ),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt imp.),
						'one' => q({0} qt imp.),
						'other' => q({0} qt imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt imp.),
						'one' => q({0} qt imp.),
						'other' => q({0} qt imp.),
					},
				},
			} }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} e {1}),
				2 => q({0} e {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000' => {
					'one' => 'mille',
					'other' => '0 mia',
				},
				'10000' => {
					'one' => '00 mia',
					'other' => '00 mia',
				},
				'100000' => {
					'one' => '000 mia',
					'other' => '000 mia',
				},
				'1000000' => {
					'one' => '0 mion',
					'other' => '0 mioin',
				},
				'10000000' => {
					'one' => '00 mioin',
					'other' => '00 mioin',
				},
				'100000000' => {
					'one' => '000 mioin',
					'other' => '000 mioin',
				},
				'1000000000' => {
					'one' => '0 miliardo',
					'other' => '0 miliardi',
				},
				'10000000000' => {
					'one' => '00 miliardi',
					'other' => '00 miliardi',
				},
				'100000000000' => {
					'one' => '000 miliardi',
					'other' => '000 miliardi',
				},
				'1000000000000' => {
					'one' => 'mille miliardi',
					'other' => '0 mia miliardi',
				},
				'10000000000000' => {
					'one' => '00 mia miliardi',
					'other' => '00 mia miliardi',
				},
				'100000000000000' => {
					'one' => '000 mia miliardi',
					'other' => '000 mia miliardi',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 k',
					'other' => '0 k',
				},
				'10000' => {
					'one' => '00 k',
					'other' => '00 k',
				},
				'100000' => {
					'one' => '000 k',
					'other' => '000 k',
				},
				'1000000' => {
					'one' => '0 Mio',
					'other' => '0 Mio',
				},
				'10000000' => {
					'one' => '00 Mio',
					'other' => '00 Mio',
				},
				'100000000' => {
					'one' => '000 Mio',
					'other' => '000 Mio',
				},
				'1000000000' => {
					'one' => '0 Mld',
					'other' => '0 Mld',
				},
				'10000000000' => {
					'one' => '00 Mld',
					'other' => '00 Mld',
				},
				'100000000000' => {
					'one' => '000 Mld',
					'other' => '000 Mld',
				},
				'1000000000000' => {
					'one' => '0 Bio',
					'other' => '0 Bio',
				},
				'10000000000000' => {
					'one' => '00 Bio',
					'other' => '00 Bio',
				},
				'100000000000000' => {
					'one' => '000 Bio',
					'other' => '000 Bio',
				},
			},
		},
} },
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(#,##0.00 ¤)',
						'positive' => '#,##0.00 ¤',
					},
					'standard' => {
						'positive' => '#,##0.00 ¤',
					},
				},
			},
		},
} },
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AED' => {
			display_name => {
				'currency' => q(dirham di Emirati Arabi Unii),
				'one' => q(dirham di EAU),
				'other' => q(dirham di EAU),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghani),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(lek arbaneise),
				'one' => q(lek arbaneise),
				'other' => q(lekë arbaneixi),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(dram ermeno),
				'one' => q(dram ermeno),
				'other' => q(dram ermeni),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(fiorin de Antille olandeixi),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza angolan),
				'one' => q(kwanza angolan),
				'other' => q(kwanza angolen),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(peso argentin),
				'one' => q(peso argentin),
				'other' => q(pesos argentin),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(dòllao australian),
				'one' => q(dòllao australian),
				'other' => q(dòllai australien),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(fiorin d’Aruba),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(manat azero),
				'one' => q(manat azero),
				'other' => q(manat azeri),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(marco convertibile da Bòsnia-Herzegòvina),
				'one' => q(marco convertibile da Bòsnia-Herzegòvina),
				'other' => q(marchi convertibili da Bòsnia-Herzegòvina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(dòllao de Barbados),
				'one' => q(dòllao de Barbados),
				'other' => q(dòllai de Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(taka bengaleise),
				'one' => q(taka bengaleise),
				'other' => q(taka bengaleixi),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(lev burgao),
				'one' => q(lev burgao),
				'other' => q(leva burgai),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dinar do Bahrein),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(franco do Burundi),
				'one' => q(franco do Burundi),
				'other' => q(franchi do Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(dòllao de Bermuda),
				'one' => q(dòllao de Bermuda),
				'other' => q(dòllai de Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(dòllao do Brunei),
				'one' => q(dòllao do Brunei),
				'other' => q(dòllai do Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(bolivian),
				'one' => q(bolivian),
				'other' => q(bolivien),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(real brasilian),
				'one' => q(real brasilian),
				'other' => q(reais brasilien),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(dòllao de Bahamas),
				'one' => q(dòllao de Bahamas),
				'other' => q(dòllai de Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(ngultrum bhutaneise),
				'one' => q(ngultrum bhutaneise),
				'other' => q(ngultrum bhutaneixi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula do Botswana),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(rubo belaruscio),
				'one' => q(rubo belaruscio),
				'other' => q(rubi belarusci),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(dòllao do Belize),
				'one' => q(dòllao do Belize),
				'other' => q(dòllai do Belize),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(dòllao canadeise),
				'one' => q(dòllao canadeise),
				'other' => q(dòllai canadeixi),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(franco congoleise),
				'one' => q(franco congoleise),
				'other' => q(franchi congoleixi),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(franco svissero),
				'one' => q(franco svissero),
				'other' => q(franchi svisseri),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(peso cileno),
				'one' => q(peso cileno),
				'other' => q(pesos cileni),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(renmimbi cineise \(offshore\)),
				'one' => q(renmimbi cineise \(offshore\)),
				'other' => q(renmimbi cineixi \(offshore\)),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(renmimbi cineise),
				'one' => q(renmimbi cineise),
				'other' => q(renmimbi cineixi),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(peso colombian),
				'one' => q(peso colombian),
				'other' => q(pesos colombien),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(colón costarican),
				'one' => q(colón costarican),
				'other' => q(colones costarichen),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(peso cuban convertibile),
				'one' => q(peso cuban convertibile),
				'other' => q(pesos cuben convertibili),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(peso cuban),
				'one' => q(peso cuban),
				'other' => q(pesos cuben),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(escudo capoverdian),
				'one' => q(escudo capoverdian),
				'other' => q(escudos capoverdien),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(coroña ceca),
				'one' => q(coroña ceca),
				'other' => q(coroñe ceche),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(franco do Djibouti),
				'one' => q(franco do Djibouti),
				'other' => q(franchi do Djibouti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(coroña daneise),
				'one' => q(coroña daneise),
				'other' => q(coroñe daneixi),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(peso dominican),
				'one' => q(peso dominican),
				'other' => q(pesos dominichen),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinar algerian),
				'one' => q(dinar algerian),
				'other' => q(dinar algerien),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(sterliña egiçiaña),
				'one' => q(sterliña egiçiaña),
				'other' => q(sterliñe egiçiañe),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nafka eritreo),
				'one' => q(nafka eritreo),
				'other' => q(nafka eritrëi),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(birr etiope),
				'one' => q(birr etiope),
				'other' => q(birr etiopi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(dòllao de Figi),
				'one' => q(dòllao de Figi),
				'other' => q(dòllai de Figi),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(sterliña de Malviñe),
				'one' => q(sterliña de Malviñe),
				'other' => q(sterliñe de Malviñe),
			},
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'currency' => q(sterliña britannica),
				'one' => q(sterliña britannica),
				'other' => q(sterliñe britanniche),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(lari georgian),
				'one' => q(lari georgian),
				'other' => q(lari georgien),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(cedi ghaneise),
				'one' => q(cedi ghaneise),
				'other' => q(cedi ghaneixi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(sterliña de Gibertâ),
				'one' => q(sterliña de Gibertâ),
				'other' => q(sterliñe de Gibertâ),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi gambian),
				'one' => q(dalasi gambian),
				'other' => q(dalasi gambien),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(franco da Guinea),
				'one' => q(franco da Guinea),
				'other' => q(franchi da Guinea),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(quetzal guatemalteco),
				'one' => q(quetzal guatemalteco),
				'other' => q(quetzal guatemaltechi),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(dòllao da Guyana),
				'one' => q(dòllao da Guyana),
				'other' => q(dòllai da Guyana),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(dòllao de Hong Kong),
				'one' => q(dòllao de Hong Kong),
				'other' => q(dòllai de Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(lempira honduregna),
				'one' => q(lempira honduregna),
				'other' => q(lempire honduregne),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kuna croata),
				'one' => q(kuna croata),
				'other' => q(kune croate),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(gourde haitian),
				'one' => q(gourde haitian),
				'other' => q(gourde haitien),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(fiorin ongareise),
				'one' => q(fiorin ongareise),
				'other' => q(fiorin ongareixi),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(rupia indonesiaña),
				'one' => q(rupia indonesiaña),
				'other' => q(rupie indonesiañe),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(neuvo sciclo israelian),
				'one' => q(neuvo sciclo israelian),
				'other' => q(neuvi scicli israelian),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(rupia indiaña),
				'one' => q(rupia indiaña),
				'other' => q(rupie indiañe),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(dinar irachen),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(rial iranian),
				'one' => q(rial iranian),
				'other' => q(rial iranien),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(coroña islandeise),
				'one' => q(coroña islandeise),
				'other' => q(coroñe islandeixi),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(dòllao giamaican),
				'one' => q(dòllao giamaican),
				'other' => q(dòllai giamaichen),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(dinar giordan),
				'one' => q(dinar giordan),
				'other' => q(dinar giorden),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(yie giapponeise),
				'one' => q(yien giapponeise),
				'other' => q(yien giapponeixi),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(scellin Kenyan),
				'one' => q(scellin Kenyan),
				'other' => q(scellin Kenyen),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(som kirghiso),
				'one' => q(som kirghiso),
				'other' => q(som kirghixi),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(riel cambogian),
				'one' => q(riel cambogian),
				'other' => q(riel cambogien),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(franco comorian),
				'one' => q(franco comorian),
				'other' => q(franchi comorien),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(won nordcorean),
				'one' => q(won nordcorean),
				'other' => q(won nordcoreen),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(won sudcorean),
				'one' => q(won sudcorean),
				'other' => q(won sudcoreen),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(dinar do Kuwait),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(dòllao de isoe Cayman),
				'one' => q(dòllao de isoe Cayman),
				'other' => q(dòllai de isoe Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(tenge kazako),
				'one' => q(tenge kazako),
				'other' => q(tenge kazaki),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(kip laotian),
				'one' => q(kip laotian),
				'other' => q(kip laotien),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(sterliña libaneise),
				'one' => q(sterliña libaneise),
				'other' => q(sterliña libaneixi),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(rupia do Sri Lanka),
				'one' => q(rupia do Sri Lanka),
				'other' => q(rupie do Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dòllao liberian),
				'one' => q(dòllao liberian),
				'other' => q(dòllai liberian),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti do Lesotho),
				'one' => q(loti do Lesotho),
				'other' => q(maloti do Lesotho),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinar libico),
				'one' => q(dinar libico),
				'other' => q(dinar libichi),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dirham marocchin),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(leu moldavo),
				'one' => q(leu moldavo),
				'other' => q(lei moldavi),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ariary malgascio),
				'one' => q(ariary malgascio),
				'other' => q(ariary malgasci),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(dinao maçedone),
				'one' => q(dinao maçedone),
				'other' => q(dinai maçedoni),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(kyat do Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(tugrik mongolo),
				'one' => q(tugrik mongolo),
				'other' => q(tugrik mongoli),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(pataca de Macao),
				'one' => q(pataca de Macao),
				'other' => q(patacas de Macao),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ouguiya da Mauritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(rupia mauriçiaña),
				'one' => q(rupia mauriçiaña),
				'other' => q(rupie mauriçiañe),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(rufiyaa de Maldive),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha malawian),
				'one' => q(kwacha malawian),
				'other' => q(kwacha malawien),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(peso mescican),
				'one' => q(peso mescican),
				'other' => q(pesos mescichen),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ringgit maleise),
				'one' => q(ringgit maleise),
				'other' => q(ringgit maleixi),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(metical mozambican),
				'one' => q(metical mozambican),
				'other' => q(meticales mozambichen),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dòllao namibian),
				'one' => q(dòllao namibian),
				'other' => q(dòllai namibien),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira nigeriaña),
				'one' => q(naira nigeriaña),
				'other' => q(naire nigeriañe),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(córdoba do Nicaragua),
				'one' => q(córdoba do Nicaragua),
				'other' => q(córdobas do Nicaragua),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(coroña norvegiña),
				'one' => q(coroña norvegiña),
				'other' => q(coroñe norvegiñe),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(rupia nepaleise),
				'one' => q(rupia nepaleise),
				'other' => q(rupie nepaleixi),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(dòllao neozelandeise),
				'one' => q(dòllao neozelandeise),
				'other' => q(dòllai neozelandeixi),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(rial de l’Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balboa de Panama),
				'one' => q(balboa de Panama),
				'other' => q(balboas de Panama),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(sol peruvian),
				'one' => q(sol peruvian),
				'other' => q(soles peruvien),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kina papuaña),
				'one' => q(kina papuaña),
				'other' => q(kina papuañe),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(peso filippin),
				'one' => q(peso filippin),
				'other' => q(pesos filippin),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(rupia pakistaña),
				'one' => q(rupia pakistaña),
				'other' => q(rupie pakistañe),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(złoty polacco),
				'one' => q(złoty polacco),
				'other' => q(złoty polacchi),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(guaraní paraguayan),
				'one' => q(guaraní paraguayan),
				'other' => q(guaraníes paraguayen),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(rial do Qatar),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(leu romen),
				'one' => q(leu romen),
				'other' => q(lei romen),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(dinao serbo),
				'one' => q(dinao serbo),
				'other' => q(dinai serbi),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rublo ruscio),
				'one' => q(rublo ruscio),
				'other' => q(rubli rusci),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(franco do Rwanda),
				'one' => q(franco do Rwanda),
				'other' => q(franchi do Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(rial saudita),
				'one' => q(rial saudita),
				'other' => q(rial sauditi),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(dòllao de Isoe Salomon),
				'one' => q(dòllao de Isoe Salomon),
				'other' => q(dòllai de Isoe Salomon),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(rupia de Seychelles),
				'one' => q(rupia de Seychelles),
				'other' => q(rupie de Seychelles),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sterliña sudaneise),
				'one' => q(sterliña sudaneise),
				'other' => q(sterliñe sudaneixi),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(coroña svedeise),
				'one' => q(coroña svedeise),
				'other' => q(coroñe svedeixi),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(dòllao de Scingapô),
				'one' => q(dòllao de Scingapô),
				'other' => q(dòllai de Scingapô),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(sterliña de Sant’Elena),
				'one' => q(sterliña de Sant’Elena),
				'other' => q(sterliñe de Sant’Elena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(lion da Sierra Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(lion da Sierra Leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(scellin da Somalia),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(dòllao do Suriname),
				'one' => q(dòllao do Suriname),
				'other' => q(dòllai do Suriname),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(sterliña sud-sudaneise),
				'one' => q(sterliña sud-sudaneise),
				'other' => q(sterliñe sud-sudaneixi),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra de Sao Tomé e Prinçipe),
				'one' => q(dobra de Sao Tomé e Prinçipe),
				'other' => q(dobras de Sao Tomé e Prinçipe),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(sterliña sciriaña),
				'one' => q(sterliña sciriaña),
				'other' => q(sterliñe sciriañe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni do Swaziland),
				'one' => q(lilangeni do Swaziland),
				'other' => q(emalangeni do Swaziland),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(baht tailandeise),
				'one' => q(baht tailandeise),
				'other' => q(baht tailandeixi),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(somoni tagiko),
				'one' => q(somoni tagiko),
				'other' => q(somoni tagiki),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(manat turkmeno),
				'one' => q(manat turkmeno),
				'other' => q(manat turkmeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinar tunexian),
				'one' => q(dinar tunexian),
				'other' => q(dinar tunexien),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(paʻanga tongan),
				'one' => q(paʻanga tongan),
				'other' => q(paʻanga tonghen),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(lia turca),
				'one' => q(lia turca),
				'other' => q(lie turche),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(dòllao de Trinidad e Tobago),
				'one' => q(dòllao de Trinidad e Tobago),
				'other' => q(dòllai de Trinidad e Tobago),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(neuvo dòllao taiwaneise),
				'one' => q(neuvo dòllao taiwaneise),
				'other' => q(neuvi dòllai taiwaneixi),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(scellin da Tanzania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(grivnia ucraiña),
				'one' => q(grivnia ucraiña),
				'other' => q(grivnie ucraiñe),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(scellin de l’Uganda),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(dòllao di Stati Unii),
				'one' => q(dòllao di Stati Unii),
				'other' => q(dòllai di Stati Unii),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(peso uruguayan),
				'one' => q(peso uruguayan),
				'other' => q(pesos uruguayen),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(som uzbeco),
				'one' => q(som uzbeco),
				'other' => q(som uzbechi),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolívar venessuelan),
				'one' => q(bolívar venessuelan),
				'other' => q(bolívares venessuelen),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(dong vietnamita),
				'one' => q(dong vietnamita),
				'other' => q(dong vietnamiti),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vatu de Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(tala samoan),
				'one' => q(tala samoan),
				'other' => q(tala samoen),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(franco CFA BEAC),
				'one' => q(franco CFA BEAC),
				'other' => q(franchi CFA BEAC),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(dòllao di Caraibi de levante),
				'one' => q(dòllao di Caraibi de levante),
				'other' => q(dòllai di Caraibi de levante),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(franco CFA BCEAO),
				'one' => q(franco CFA BCEAO),
				'other' => q(franchi CFA BCEAO),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(franco CFP),
				'one' => q(franco CFP),
				'other' => q(franchi CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(monæa desconosciua),
				'one' => q(\(monæa desconosciua\)),
				'other' => q(\(monæe desconosciue\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(rial do Yemen),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(rand sudafrican),
				'one' => q(rand sudafrican),
				'other' => q(rand sudafrichen),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwacha zambian),
				'one' => q(kwacha zambian),
				'other' => q(kwacha zambien),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'de zen.',
							'de fre.',
							'de mar.',
							'd’arv.',
							'de maz.',
							'de zug.',
							'de lug.',
							'd’ago.',
							'de set.',
							'd’ott.',
							'de nov.',
							'de dex.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'de zenâ',
							'de frevâ',
							'de marso',
							'd’arvî',
							'de mazzo',
							'de zugno',
							'de luggio',
							'd’agosto',
							'de settembre',
							'd’ottobre',
							'de novembre',
							'de dexembre'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'zen.',
							'fre.',
							'mar.',
							'arv.',
							'maz.',
							'zug.',
							'lug.',
							'ago.',
							'set.',
							'ott.',
							'nov.',
							'dex.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'ZN',
							'FR',
							'MR',
							'AR',
							'MZ',
							'ZG',
							'LG',
							'AG',
							'ST',
							'OT',
							'NV',
							'DX'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'zenâ',
							'frevâ',
							'marso',
							'arvî',
							'mazzo',
							'zugno',
							'luggio',
							'agosto',
							'settembre',
							'ottobre',
							'novembre',
							'dexembre'
						],
						leap => [
							
						],
					},
				},
			},
	} },
);

has 'calendar_days' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						mon => 'lun.',
						tue => 'mät.',
						wed => 'mäc.',
						thu => 'zeu.',
						fri => 'ven.',
						sat => 'sab.',
						sun => 'dom.'
					},
					wide => {
						mon => 'lunesdì',
						tue => 'mätesdì',
						wed => 'mäcordì',
						thu => 'zeuggia',
						fri => 'venardì',
						sat => 'sabbo',
						sun => 'domenega'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'Z',
						fri => 'V',
						sat => 'S',
						sun => 'D'
					},
				},
			},
	} },
);

has 'calendar_quarters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {0 => 'T1',
						1 => 'T2',
						2 => 'T3',
						3 => 'T4'
					},
					wide => {0 => '1º trimestre',
						1 => '2º trimestre',
						2 => '3º trimestre',
						3 => '4º trimestre'
					},
				},
			},
	} },
);

has 'day_period_data' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { sub {
		# Time in hhmm format
		my ($self, $type, $time, $day_period_type) = @_;
		$day_period_type //= 'default';
		SWITCH:
		for ($type) {
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
		}
	} },
);

around day_period_data => sub {
    my ($orig, $self) = @_;
    return $self->$orig;
};

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'afternoon1' => q{do poidisnâ},
					'evening1' => q{da seia},
					'midnight' => q{mëzaneutte},
					'morning1' => q{da mattin},
					'night1' => q{da neutte},
					'noon' => q{mëzogiorno},
				},
				'narrow' => {
					'am' => q{m.},
					'pm' => q{p.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{poidisnâ},
					'evening1' => q{seia},
					'morning1' => q{mattin},
					'night1' => q{neutte},
				},
				'narrow' => {
					'am' => q{m.},
					'pm' => q{p.},
				},
			},
		},
	} },
);

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'aC',
				'1' => 'dC'
			},
			wide => {
				'0' => 'avanti de Cristo',
				'1' => 'dòppo de Cristo'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{EEEE d 'de' MMMM 'do' y G},
			'long' => q{d 'de' MMMM 'do' y G},
			'medium' => q{d/M/y G},
			'short' => q{d/M/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM 'do' y},
			'long' => q{d MMMM 'do' y},
			'medium' => q{d MMM 'do' y},
			'short' => q{dd/MM/yy},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1} {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y G},
			yyyyMEd => q{E d/M/y GGGGG},
			yyyyMMM => q{LLL y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{LLLL 'do' y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM 'do' y G},
			GyMMMd => q{d MMM 'do' y G},
			GyMd => q{d/M/y G},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMMW => q{W'ª' 'settemaña' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{LLL 'do' y},
			yMMMEd => q{E d MMM 'do' y},
			yMMMM => q{LLLL 'do' y},
			yMMMd => q{d MMM 'do' y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'do' y},
			yw => q{w'ª' 'settemaña' 'do' Y},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E d/M/y GGGGG – E d/M/y GGGGG},
				M => q{E d/M/y – E d/M/y GGGGG},
				d => q{E d/M/y – E d/M/y GGGGG},
				y => q{E d/M/y – E d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM y – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM y G – d MMM y G},
				d => q{d–d MMM, y G},
				y => q{d MMM y G – d MMM y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d/M – E d/M},
				d => q{E d/M – E d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E d/M/y – E d/M/y GGGGG},
				d => q{E d/M/y – E d/M/y GGGGG},
				y => q{E d/M/y – E d/M/y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM 'do' y – MMM 'do' y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM 'do' y G},
				d => q{E d MMM – E d MMM 'do' y G},
				y => q{E d MMM 'do' y – E d MMM 'do' y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM 'do' y G},
				y => q{MMMM 'do' y – MMMM 'do' y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM 'do' y G},
				d => q{d–d MMM 'do' y G},
				y => q{d MMM 'do' y – d MMM 'do' y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y G – M/y G},
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			GyMEd => {
				G => q{E d/M/y – E d/M/y G},
				M => q{E d/M/y – E d/M/y G},
				d => q{E d/M/y – E d/M/y G},
				y => q{E d/M/y – E d/M/y G},
			},
			GyMMM => {
				G => q{LLL 'do' y G – LLL 'do' y G},
				M => q{LLL – LLL 'do' y G},
				y => q{LLL 'do' y – LLL 'do' y G},
			},
			GyMMMEd => {
				G => q{E, d MMM 'do' y G – E d MMM 'do' y G},
				M => q{E d MMM – E d MMM 'do' y G},
				d => q{E d MMM – E d MMM 'do' y G},
				y => q{E d MMM 'do' y – E d MMM 'do' y G},
			},
			GyMMMd => {
				G => q{d MMM 'do' y G – d MMM 'do' y G},
				M => q{d MMM – d MMM 'do' y G},
				d => q{d–d MMM 'do' y G},
				y => q{d MMM 'do' y – d MMM 'do' y G},
			},
			GyMd => {
				G => q{d/M/y G – d/M/y G},
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E d/M – E d/M},
				d => q{E d/M – E d/M},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E d/M/y – E d/M/y},
				d => q{E d/M/y – E d/M/y},
				y => q{E d/M/y – E d/M/y},
			},
			yMMM => {
				M => q{LLL–LLL 'do' y},
				y => q{LLL 'do' y – LLL 'do' y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM 'do' y},
				d => q{E d – E d MMM 'do' y},
				y => q{E d MMM 'do' y – E d MMM 'do' y},
			},
			yMMMM => {
				M => q{LLLL–LLLL 'do' y},
				y => q{LLLL 'do' y – LLLL 'do' y},
			},
			yMMMd => {
				M => q{d MMM – d MMM 'do' y},
				d => q{d–d MMM 'do' y},
				y => q{d MMM 'do' y – d MMM 'do' y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;−HH:mm),
		gmtFormat => q(UTC{0}),
		gmtZeroFormat => q(UTC),
		regionFormat => q(oa: {0}),
		regionFormat => q(oa de stæ: {0}),
		regionFormat => q(oa standard: {0}),
		'Afghanistan' => {
			long => {
				'standard' => q#oa de l’Afghanistan#,
			},
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Argê#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Çéuta#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadiscio#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairöbi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao Tomé#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunexi#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#oa de l’Africa do mezo#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#oa de l’Africa de levante#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#oa de l’Africa do meridion#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#oa de stæ de l’Africa de ponente#,
				'generic' => q#oa de l’Africa de ponente#,
				'standard' => q#oa standard de l’Africa de ponente#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#oa de stæ de l’Alaska#,
				'generic' => q#oa de l’Alaska#,
				'standard' => q#oa standard de l’Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#oa de stæ de l’Amassònia#,
				'generic' => q#oa de l’Amassònia#,
				'standard' => q#oa standard de l’Amassònia#,
			},
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotà#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Caieña#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Còrdova#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Còsta Rica#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Grenada' => {
			exemplarCity => q#Granada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadaluppa#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinica#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Çittæ do Mescico#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#San Poulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#San Bertomê#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#San Cristoffa#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Luçia#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#San Viçenso#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#oa de stæ do mezo nordamericaña#,
				'generic' => q#oa do mezo nordamericaña#,
				'standard' => q#oa standard do mezo nordamericaña#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#oa de stæ do levante nordamericaña#,
				'generic' => q#oa do levante nordamericaña#,
				'standard' => q#oa standard do levante nordamericaña#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#oa de stæ de Montagne Alliggiæ#,
				'generic' => q#oa de Montagne Alliggiæ#,
				'standard' => q#oa standard de Montagne Alliggiæ#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#oa de stæ do Paçifico nordamericaña#,
				'generic' => q#oa do Paçifico nordamericaña#,
				'standard' => q#oa standard do Paçifico nordamericaña#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#oa de stæ de Apia#,
				'generic' => q#oa de Apia#,
				'standard' => q#oa standard de Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#oa de stæ de l’Arabia#,
				'generic' => q#oa de l’Arabia#,
				'standard' => q#oa standard de l’Arabia#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#oa de stæ de l’Argentiña#,
				'generic' => q#oa de l’Argentiña#,
				'standard' => q#oa standard de l’Argentiña#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#oa de stæ de l’Argentiña de ponente#,
				'generic' => q#oa de l’Argentiña de ponente#,
				'standard' => q#oa standard de l’Argentiña de ponente#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#oa de stæ de l’Ermenia#,
				'generic' => q#oa de l’Ermenia#,
				'standard' => q#oa standard de l’Ermenia#,
			},
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrein#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcutta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Cita#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasco#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Giacarta#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Gerusalemme#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcanda#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Scingapô#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ekaterinburg#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#oa de stæ de l’Atlantico nordamericaña#,
				'generic' => q#oa de l’Atlantico nordamericaña#,
				'standard' => q#oa standard de l’Atlantico nordamericaña#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azore#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canäie#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cappo Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Fær Øer#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Geòrgia do sud#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sant’Elena#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#oa de stæ de l’Australia de mezo#,
				'generic' => q#oa de l’Australia de mezo#,
				'standard' => q#oa standard de l’Australia de mezo#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#oa de stæ de l’Australia do mezo-ponente#,
				'generic' => q#oa de l’Australia do mezo-ponente#,
				'standard' => q#oa standard de l’Australia do mezo-ponente#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#oa de stæ de l’Australia de levante#,
				'generic' => q#oa de l’Australia de levante#,
				'standard' => q#oa standard de l’Australia de levante#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#oa de stæ de l’Australia de ponente#,
				'generic' => q#oa de l’Australia de ponente#,
				'standard' => q#oa standard de l’Australia de ponente#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#oa de stæ de l’Azerbaigian#,
				'generic' => q#oa de l’Azerbaigian#,
				'standard' => q#oa standard de l’Azerbaigian#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#oa de stæ de Azore#,
				'generic' => q#oa de Azore#,
				'standard' => q#oa standard de Azore#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#oa de stæ do Bangladesh#,
				'generic' => q#oa do Bangladesh#,
				'standard' => q#oa standard do Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#oa do Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#oa da Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#oa de stæ de Brasilia#,
				'generic' => q#oa de Brasilia#,
				'standard' => q#oa standard de Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#oa do Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#oa de stæ de Cappo Verde#,
				'generic' => q#oa de Cappo Verde#,
				'standard' => q#oa standard de Cappo Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#oa de Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#oa de stæ de Chatham#,
				'generic' => q#oa de Chatham#,
				'standard' => q#oa standard de Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#oa de stæ do Cile#,
				'generic' => q#oa do Cile#,
				'standard' => q#oa standard do Cile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#oa de stæ da Ciña#,
				'generic' => q#oa da Ciña#,
				'standard' => q#oa standard da Ciña#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#oa de stæ de Choibalsan#,
				'generic' => q#oa de Choibalsan#,
				'standard' => q#oa standard de Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#oa de l’isoa Christmas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#oa de isoe Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#oa de stæ da Colombia#,
				'generic' => q#oa da Colombia#,
				'standard' => q#oa standard da Colombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#oa de stæ de isoe Cook#,
				'generic' => q#oa de isoe Cook#,
				'standard' => q#oa standard de isoe Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#oa de stæ de Cubba#,
				'generic' => q#oa de Cubba#,
				'standard' => q#oa standard de Cubba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#oa de Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#oa de Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#oa de Timor Est#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#oa de stæ de l’isoa de Pasqua#,
				'generic' => q#oa de l’isoa de Pasqua#,
				'standard' => q#oa standard de l’isoa de Pasqua#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#oa de l’Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#tempo universale coordinou#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#çittæ desconosciua#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andòrra#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atene#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgraddo#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelles#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Doblin#,
			long => {
				'daylight' => q#oa de stæ d’Irlanda#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibertâ#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Isoa de Man#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboña#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lubiaña#,
		},
		'Europe/London' => {
			exemplarCity => q#Londra#,
			long => {
				'daylight' => q#oa de stæ britannica#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburgo#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monego#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mosca#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Òslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Pariggi#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Romma#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marin#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stoccolma#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tiraña#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsavia#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagabria#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurigo#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#oa de stæ de l’Euröpa do mezo#,
				'generic' => q#oa de l’Euröpa do mezo#,
				'standard' => q#oa standard de l’Euröpa do mezo#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#oa de stæ de l’Euröpa de levante#,
				'generic' => q#oa de l’Euröpa de levante#,
				'standard' => q#oa standard de l’Euröpa de levante#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#oa de Kaliningrad#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#oa de stæ de l’Euröpa de ponente#,
				'generic' => q#oa de l’Euröpa de ponente#,
				'standard' => q#oa standard de l’Euröpa de ponente#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#oa de stæ de isoe Malviñe#,
				'generic' => q#oa de isoe Malviñe#,
				'standard' => q#oa standard de isoe Malviñe#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#oa de stæ de Figi#,
				'generic' => q#oa de Figi#,
				'standard' => q#oa standard de Figi#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#oa da Guyana franseise#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#oa de Tære australe e antartiche franseixi#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#oa do meridian de Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#oa de Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#oa de Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#oa de stæ da Geòrgia#,
				'generic' => q#oa da Geòrgia#,
				'standard' => q#oa standard da Geòrgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#oa de isoe Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#oa de stæ da Groenlandia de levante#,
				'generic' => q#oa da Groenlandia de levante#,
				'standard' => q#oa standard da Groenlandia de levante#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#oa de stæ da Groenlandia de ponente#,
				'generic' => q#oa da Groenlandia de ponente#,
				'standard' => q#oa standard da Groenlandia de ponente#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#oa standard do Gorfo#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#oa da Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#oa de stæ de Hawaii-Aleutiñe#,
				'generic' => q#oa de Hawaii-Aleutiñe#,
				'standard' => q#oa standard de Hawaii-Aleutiñe#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#oa de stæ de Hong Kong#,
				'generic' => q#oa de Hong Kong#,
				'standard' => q#oa standard de Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#oa de stæ de Hovd#,
				'generic' => q#oa de Hovd#,
				'standard' => q#oa standard de Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#oa de l’India#,
			},
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comöre#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldive#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Maiòtta#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#oa de l’Oçeano Indian#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#oa de l’Indociña#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#oa de l’Indonesia de mezo#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#oa de l’Indonesia de levante#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#oa de l’Indonesia de ponente#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#oa de stæ de l’Iran#,
				'generic' => q#oa de l’Iran#,
				'standard' => q#oa standard de l’Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#oa de stæ de Irkutsk#,
				'generic' => q#oa de Irkutsk#,
				'standard' => q#oa standard de Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#oa de stæ d’Israele#,
				'generic' => q#oa d’Israele#,
				'standard' => q#oa standard d’Israele#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#oa de stæ do Giappon#,
				'generic' => q#oa do Giappon#,
				'standard' => q#oa standard do Giappon#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#oa do Kazakistan de levante#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#oa do Kazakistan de ponente#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#oa de stæ da Corea#,
				'generic' => q#oa da Corea#,
				'standard' => q#oa standard da Corea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#oa do Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#oa de stæ de Krasnoyarsk#,
				'generic' => q#oa de Krasnoyarsk#,
				'standard' => q#oa standard de Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#oa do Kirghizistan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#oa de isoe da Linia#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#oa de stæ de Lord Howe#,
				'generic' => q#oa de Lord Howe#,
				'standard' => q#oa standard de Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#oa de l’isoa Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#oa de stæ de Magadan#,
				'generic' => q#oa de Magadan#,
				'standard' => q#oa standard de Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#oa da Malesia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#oa de Maldive#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#oa de Marcheixi#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#oa de isoe Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#oa de stæ de Mauritius#,
				'generic' => q#oa de Mauritius#,
				'standard' => q#oa standard de Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#oa de Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#oa de stæ do Mescico do nòrd-ponente#,
				'generic' => q#oa do Mescico do nòrd-ponente#,
				'standard' => q#oa standard do Mescico do nòrd-ponente#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#oa de stæ do Paçifico mescicaña#,
				'generic' => q#oa do Paçifico mescicaña#,
				'standard' => q#oa standard do Paçifico mescicaña#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#oa de stæ d’Ulan Bator#,
				'generic' => q#oa d’Ulan Bator#,
				'standard' => q#oa standard d’Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#oa de stæ de Mosca#,
				'generic' => q#oa de Mosca#,
				'standard' => q#oa standard de Mosca#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#oa da Birmania#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#oa de Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#oa do Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#oa de stæ da Neuva Caledònia#,
				'generic' => q#oa da Neuva Caledònia#,
				'standard' => q#oa standard da Neuva Caledònia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#oa de stæ da Neuva Zelanda#,
				'generic' => q#oa da Neuva Zelanda#,
				'standard' => q#oa standard da Neuva Zelanda#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#oa de stæ de Tæraneuva#,
				'generic' => q#oa de Tæraneuva#,
				'standard' => q#oa standard de Tæraneuva#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#oa de Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#oa de stæ de l’isoa Norfolk#,
				'generic' => q#oa de l’isoa Norfolk#,
				'standard' => q#oa standard de l’isoa Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#oa de stæ de Fernando de Noronha#,
				'generic' => q#oa de Fernando de Noronha#,
				'standard' => q#oa standard de Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#oa de stæ de Novosibirsk#,
				'generic' => q#oa de Novosibirsk#,
				'standard' => q#oa standard de Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#oa de stæ de Òmsk#,
				'generic' => q#oa de Òmsk#,
				'standard' => q#oa standard de Òmsk#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Pasqua#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Figi#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marcheixi#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#oa de stæ do Pakistan#,
				'generic' => q#oa do Pakistan#,
				'standard' => q#oa standard do Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#oa de Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#oa da Papua Neuva Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#oa de stæ do Paraguay#,
				'generic' => q#oa do Paraguay#,
				'standard' => q#oa standard do Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#oa de stæ do Perù#,
				'generic' => q#oa do Perù#,
				'standard' => q#oa standard do Perù#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#oa de stæ de Filipiñe#,
				'generic' => q#oa de Filipiñe#,
				'standard' => q#oa standard de Filipiñe#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#oa de isoe Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#oa de stæ de San Pê e Miquelon#,
				'generic' => q#oa de San Pê e Miquelon#,
				'standard' => q#oa standard de San Pê e Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#oa de Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#oa de Pohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#oa de Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#oa da Réunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#oa de Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#oa de stæ de Sakhalin#,
				'generic' => q#oa de Sakhalin#,
				'standard' => q#oa standard de Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#oa de stæ de Samoa#,
				'generic' => q#oa de Samoa#,
				'standard' => q#oa standard de Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#oa de Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#oa de Scingapô#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#oa de isoe Solomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#oa da Geòrgia do sud#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#oa do Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#oa de Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#oa de Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#oa de stæ de Taipei#,
				'generic' => q#oa de Taipei#,
				'standard' => q#oa standard de Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#oa do Tagikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#oa de Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#oa de stæ de Tonga#,
				'generic' => q#oa de Tonga#,
				'standard' => q#oa standard de Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#oa do Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#oa de stæ do Turkmenistan#,
				'generic' => q#oa do Turkmenistan#,
				'standard' => q#oa standard do Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#oa de Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#oa de stæ de l’Uruguay#,
				'generic' => q#oa de l’Uruguay#,
				'standard' => q#oa standard de l’Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#oa de stæ de l’Uzbekistan#,
				'generic' => q#oa de l’Uzbekistan#,
				'standard' => q#oa standard de l’Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#oa de stæ de Vanuatu#,
				'generic' => q#oa de Vanuatu#,
				'standard' => q#oa standard de Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#oa do Venessuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#oa de stæ de Vladivostok#,
				'generic' => q#oa de Vladivostok#,
				'standard' => q#oa standard de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#oa de stæ de Volgograd#,
				'generic' => q#oa de Volgograd#,
				'standard' => q#oa standard de Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#oa de Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#oa de l’isoa de Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#oa de Wallis e Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#oa de stæ de Yakutsk#,
				'generic' => q#oa de Yakutsk#,
				'standard' => q#oa standard de Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#oa de stæ d’Ekaterinburg#,
				'generic' => q#oa d’Ekaterinburg#,
				'standard' => q#oa standard d’Ekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#oa do Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
