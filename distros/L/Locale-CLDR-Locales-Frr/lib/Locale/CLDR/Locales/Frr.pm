=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Frr - Package for language Northern Frisian

=cut

package Locale::CLDR::Locales::Frr;
# This file auto generated from Data\common\main\frr.xml
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
				'ab' => 'Abchaasisk',
 				'ace' => 'Achineesk',
 				'ada' => 'Adangme',
 				'ady' => 'Adygeesk',
 				'af' => 'Afrikaans',
 				'agq' => 'Aghem',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'ale' => 'Aleutisk',
 				'alt' => 'Süüd Altai',
 				'am' => 'Amhaarisk',
 				'an' => 'Aragoneesk',
 				'ann' => 'Obolo',
 				'anp' => 'Angika',
 				'ar' => 'Araabisk',
 				'ar_001' => 'Modern Standard Araabisk',
 				'arn' => 'Mapuche',
 				'arp' => 'Arapaho',
 				'ars' => 'Najdi Araabisk',
 				'as' => 'Asameesk',
 				'asa' => 'Asu',
 				'ast' => 'Astuurisk',
 				'atj' => 'Atikamekw',
 				'av' => 'Awaarisk',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Aserbaidschaansk',
 				'az@alt=short' => 'Aseeri',
 				'ba' => 'Baschkiirisk',
 				'ban' => 'Balineesk',
 				'bas' => 'Basaa',
 				'be' => 'Witjrüsk',
 				'bem' => 'Bemba',
 				'bez' => 'Bena',
 				'bg' => 'Bulgaarsk',
 				'bgc' => 'Haryanvi',
 				'bho' => 'Bhoipuurisk',
 				'bi' => 'Bislama',
 				'bin' => 'Bini',
 				'bla' => 'Siksiká',
 				'bm' => 'Bambara',
 				'bn' => 'Bengaals',
 				'bo' => 'Tibetaans',
 				'br' => 'Bretoonsk',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnisk',
 				'bug' => 'Bugineesk',
 				'byn' => 'Blin',
 				'ca' => 'Katalaans',
 				'cay' => 'Cayuga',
 				'ccp' => 'Chakma',
 				'ce' => 'Tschetscheensk',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Chiga',
 				'ch' => 'Chamorro',
 				'chk' => 'Chuukese',
 				'chm' => 'Mari',
 				'cho' => 'Choctaw',
 				'chp' => 'Chipewyan',
 				'chr' => 'Cherokee',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Madel Kurdisk',
 				'ckb@alt=menu' => 'Kurdisk, Madel',
 				'ckb@alt=variant' => 'Kurdisk, Sorani',
 				'clc' => 'Chilcotin',
 				'co' => 'Korsisk',
 				'crg' => 'Michif',
 				'crj' => 'Süüdelk Uast Cree',
 				'crk' => 'Plains Cree',
 				'crl' => 'Nuurdelk Uast Cree',
 				'crm' => 'Moose Cree',
 				'crr' => 'Carolina Algonkin',
 				'cs' => 'Tschechisk',
 				'csw' => 'Swampy Cree',
 				'cv' => 'Tschuwaschisk',
 				'cy' => 'Waliisk',
 				'da' => 'Deensk',
 				'dak' => 'Dakota',
 				'dar' => 'Dargwa',
 				'dav' => 'Taita',
 				'de' => 'Tjiisk',
 				'de_AT' => 'Uastenriks Tjiisk',
 				'de_CH' => 'Sweitser Huuchtjiisk',
 				'dgr' => 'Dogrib',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Liachsorbisk',
 				'dua' => 'Duala',
 				'dv' => 'Divehi',
 				'dyo' => 'Jola-Fonyi',
 				'dz' => 'Dzongkha',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'eka' => 'Ekajuk',
 				'el' => 'Greks',
 				'en' => 'Ingelsk',
 				'en_AU' => 'Austraalisk Ingelsk',
 				'en_CA' => 'Kanaadsk Ingelsk',
 				'en_GB' => 'Britisk Ingelsk',
 				'en_US' => 'Amerikoonsk Ingelsk',
 				'eo' => 'Esperanto',
 				'es' => 'Spaans',
 				'es_419' => 'Amerikoonsk Spaans',
 				'es_ES' => 'Europeesk Spaans',
 				'es_MX' => 'Meksikoons Spaans',
 				'et' => 'Eestnisk',
 				'eu' => 'Baskisk',
 				'ewo' => 'Ewondo',
 				'fa' => 'Persisk',
 				'fa_AF' => 'Dari',
 				'ff' => 'Fula',
 				'fi' => 'Finsk',
 				'fil' => 'Filipiinsk',
 				'fj' => 'Fidschiaans',
 				'fo' => 'Färöisk',
 				'fon' => 'Fon',
 				'fr' => 'Fransöösk',
 				'fr_CA' => 'Kanaadsk Fransöösk',
 				'fr_CH' => 'Sweitser Fransöösk',
 				'frc' => 'Cajun Fransöösk',
 				'frr' => 'Nordfriisk',
 				'fur' => 'Friaulisk',
 				'fy' => 'Waastfresk',
 				'ga' => 'Iirsk',
 				'gaa' => 'Ga',
 				'gd' => 'Skots Geelisk',
 				'gez' => 'Geez',
 				'gil' => 'Gilberteesk',
 				'gl' => 'Galitsisk',
 				'gn' => 'Guarani',
 				'gor' => 'Gorontalo',
 				'gsw' => 'Sweitsertjiisk',
 				'gu' => 'Gujarati',
 				'guz' => 'Gusii',
 				'gv' => 'Manx',
 				'gwi' => 'Gwichʼin',
 				'ha' => 'Hausa',
 				'hai' => 'Haida',
 				'haw' => 'Hawaiiaans',
 				'hax' => 'Süüd Haida',
 				'he' => 'Hebreews',
 				'hi' => 'Hindi',
 				'hil' => 'Hiligaynon',
 				'hmn' => 'Hmong',
 				'hr' => 'Kroatisk',
 				'hsb' => 'Huuchsorbisk',
 				'ht' => 'Haitiaans Kreool',
 				'hu' => 'Ungaars',
 				'hup' => 'Hupa',
 				'hur' => 'Halkomelem',
 				'hy' => 'Armeensk',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Indoneesk',
 				'ig' => 'Igbo',
 				'ii' => 'Sichuan Yi',
 				'ikt' => 'Waast Kanaadsk Inuktitut',
 				'ilo' => 'Iloko',
 				'inh' => 'Inguschisk',
 				'io' => 'Ido',
 				'is' => 'Isluns',
 				'it' => 'Itajeensk',
 				'iu' => 'Inuktitut',
 				'ja' => 'Japaans',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jv' => 'Jawaneesk',
 				'ka' => 'Georgisk',
 				'kab' => 'Kabyle',
 				'kac' => 'Jingpo',
 				'kaj' => 'Kaje',
 				'kam' => 'Kamba',
 				'kbd' => 'Kabardisk',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Kabuverdianu',
 				'kfo' => 'Koro',
 				'kgp' => 'Kaingang',
 				'kha' => 'Khasi',
 				'khq' => 'Koyra Chiini',
 				'ki' => 'Kikuyu',
 				'kj' => 'Kuanyama',
 				'kk' => 'Kasachisk',
 				'kkj' => 'Kako',
 				'kl' => 'Kalaallisut',
 				'kln' => 'Kalenjin',
 				'km' => 'Khmer',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada',
 				'ko' => 'Koreaans',
 				'kok' => 'Konkani',
 				'kpe' => 'Kpelle',
 				'kr' => 'Kanuri',
 				'krc' => 'Karachay-Balkar',
 				'krl' => 'Kareelisk',
 				'kru' => 'Kurukh',
 				'ks' => 'Kaschmiirisk',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Kölsch',
 				'ku' => 'Kurdisk',
 				'kum' => 'Kumyk',
 				'kv' => 'Komi',
 				'kw' => 'Kornisk',
 				'kwk' => 'Kwakʼwala',
 				'ky' => 'Kirgiisk',
 				'la' => 'Latiinsk',
 				'lad' => 'Ladiinsk',
 				'lag' => 'Langi',
 				'lb' => 'Luksemborigs',
 				'lez' => 'Lesgisk',
 				'lg' => 'Ganda',
 				'li' => 'Limburgs',
 				'lil' => 'Lillooet',
 				'lkt' => 'Lakota',
 				'ln' => 'Lingala',
 				'lo' => 'Laotisk',
 				'lou' => 'Louisiana Kreool',
 				'loz' => 'Lozi',
 				'lrc' => 'Nuurd Luri',
 				'lsm' => 'Saamia',
 				'lt' => 'Litauisk',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Mizo',
 				'luy' => 'Luyia',
 				'lv' => 'Letisk',
 				'mad' => 'Madureesk',
 				'mag' => 'Magahi',
 				'mai' => 'Maithili',
 				'mak' => 'Makasar',
 				'mas' => 'Masai',
 				'mdf' => 'Moksha',
 				'men' => 'Mende',
 				'mer' => 'Meru',
 				'mfe' => 'Mauritiaans',
 				'mg' => 'Malagasy',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Metaʼ',
 				'mh' => 'Marshaleesk',
 				'mi' => 'Maori',
 				'mic' => 'Mi\'kmaw',
 				'min' => 'Minangkabau',
 				'mk' => 'Matsedoonsk',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongoolsk',
 				'mni' => 'Manipuri',
 				'moe' => 'Innu-aimun',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Marathi',
 				'ms' => 'Malaiisk',
 				'mt' => 'Malteesk',
 				'mua' => 'Mundang',
 				'mul' => 'Flook spriaken',
 				'mus' => 'Muscogee',
 				'mwl' => 'Mirandees',
 				'my' => 'Burmeesk',
 				'myv' => 'Erzya',
 				'mzn' => 'Mazanderani',
 				'na' => 'Nauru',
 				'nap' => 'Neapolitaans',
 				'naq' => 'Nama',
 				'nb' => 'Noorsk Bokmål',
 				'nd' => 'Nuurd Ndebele',
 				'nds' => 'Plaattjiisk',
 				'ne' => 'Nepaleesk',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Niueaans',
 				'nl' => 'Holuns',
 				'nl_BE' => 'Flaams',
 				'nmg' => 'Kwasio',
 				'nn' => 'Noorsk Nynorsk',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Noorsk',
 				'nog' => 'Nogai',
 				'nqo' => 'N’Ko',
 				'nr' => 'Süüd Ndebele',
 				'nso' => 'Nuurd Sotho',
 				'nus' => 'Nuer',
 				'nv' => 'Navajo',
 				'ny' => 'Nyanja',
 				'nyn' => 'Nyankole',
 				'oc' => 'Oksitaans',
 				'ojb' => 'Nuurdwaast Ojibwa',
 				'ojc' => 'Madel Ojibwa',
 				'ojs' => 'Oji-Cree',
 				'ojw' => 'Waast Ojibwa',
 				'oka' => 'Okanagan',
 				'om' => 'Oromo',
 				'or' => 'Odia',
 				'os' => 'Oseetisk',
 				'pa' => 'Panjabi',
 				'pag' => 'Pangasineesk',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiamento',
 				'pau' => 'Palauisk',
 				'pcm' => 'Nigeriaans Pidgin',
 				'pis' => 'Salomoonen Pidgin',
 				'pl' => 'Poolsk',
 				'pqm' => 'Maliseet-Passamaquoddy',
 				'ps' => 'Paschtu',
 				'pt' => 'Portugiisk',
 				'pt_BR' => 'Brasiliaans Portugiisk',
 				'pt_PT' => 'Europeesk Portugiisk',
 				'qu' => 'Ketschua',
 				'raj' => 'Rajastaans',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotongaans',
 				'rhg' => 'Rohingya',
 				'rm' => 'Rätoromaans',
 				'rn' => 'Rundi',
 				'ro' => 'Rumeensk',
 				'rof' => 'Rombo',
 				'ru' => 'Rüsk',
 				'rup' => 'Arumeensk',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskrit',
 				'sad' => 'Sandawe',
 				'sah' => 'Jakutisk',
 				'saq' => 'Samburu',
 				'sat' => 'Santali',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardiinsk',
 				'scn' => 'Sitsiliaans',
 				'sco' => 'Skots',
 				'sd' => 'Sindhi',
 				'se' => 'Nuurd Saamisk',
 				'seh' => 'Sena',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'shi' => 'Tachelhit',
 				'shn' => 'Shan',
 				'si' => 'Sinhala',
 				'sk' => 'Slowaakisk',
 				'sl' => 'Sloweensk',
 				'slh' => 'Süüd Lushootseed',
 				'sm' => 'Samoaans',
 				'smn' => 'Inari Sami',
 				'sms' => 'Skoltsaamisk',
 				'sn' => 'Shona',
 				'snk' => 'Soninke',
 				'so' => 'Somaalisk',
 				'sq' => 'Albaansk',
 				'sr' => 'Serbisk',
 				'srn' => 'Sranan Tongo',
 				'ss' => 'Swati',
 				'st' => 'Süüd Sotho',
 				'str' => 'Straits Salish',
 				'su' => 'Sundaneesk',
 				'suk' => 'Sukuma',
 				'sv' => 'Sweedsk',
 				'sw' => 'Suaheli',
 				'swb' => 'Komoorisk',
 				'syr' => 'Syrisk',
 				'ta' => 'Tamiilisk',
 				'tce' => 'Süüd Tutchone',
 				'te' => 'Telugu',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'tet' => 'Tetum',
 				'tg' => 'Tadjikisk',
 				'tgx' => 'Tagish',
 				'th' => 'Thai',
 				'tht' => 'Tahltan',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tk' => 'Turkmeensk',
 				'tlh' => 'Klingoonisk',
 				'tli' => 'Tlingit',
 				'tn' => 'Tsuana',
 				'to' => 'Tongaans',
 				'tok' => 'Toki Pona',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Türkisk',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tt' => 'Tataarisk',
 				'ttm' => 'Nuurd Tutchone',
 				'tum' => 'Tumbuka',
 				'tvl' => 'Tuwaaluu',
 				'twq' => 'Tasawaq',
 				'ty' => 'Tahitiaans',
 				'tyv' => 'Tuwiinisk',
 				'tzm' => 'Madel Atlas Tamazight',
 				'udm' => 'Udmurtisk',
 				'ug' => 'Uiguurisk',
 				'uk' => 'Ukrainisk',
 				'umb' => 'Umbundu',
 				'und' => 'Ünbekäänd spriik',
 				'ur' => 'Urdu',
 				'uz' => 'Usbeekisk',
 				'vai' => 'Vai',
 				've' => 'Venda',
 				'vi' => 'Wjetnameesk',
 				'vun' => 'Vunjo',
 				'wa' => 'Waloons',
 				'wae' => 'Walsertjiisk',
 				'wal' => 'Wolaytta',
 				'war' => 'Waray',
 				'wo' => 'Wolof',
 				'wuu' => 'Wu Schineesk',
 				'xal' => 'Kalmükisk',
 				'xh' => 'Xhosa',
 				'xog' => 'Soga',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Jidisk',
 				'yo' => 'Yoruba',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Kantoneesk',
 				'yue@alt=menu' => 'Schineesk, Kantoneesk',
 				'zgh' => 'Maroko Standard Tamazight',
 				'zh' => 'Schineesk',
 				'zh@alt=menu' => 'Mandariin Schineesk',
 				'zh_Hans' => 'Kurt Schineesk',
 				'zh_Hans@alt=long' => 'Kurt Mandariin Schineesk',
 				'zh_Hant' => 'Lung Schineesk',
 				'zh_Hant@alt=long' => 'Lung Mandariin Schineesk',
 				'zu' => 'Zulu',
 				'zun' => 'Zuni',
 				'zxx' => 'Nian spriak',
 				'zza' => 'Zaza',

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
			'Adlm' => 'Adlam',
 			'Arab' => 'Araabisk',
 			'Aran' => 'Nastaliq',
 			'Armn' => 'Armeensk',
 			'Beng' => 'Bangla',
 			'Bopo' => 'Bopomofo',
 			'Brai' => 'Braille',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Kanaadsk Silwenskraft',
 			'Cher' => 'Cherokee',
 			'Cyrl' => 'Kyrilisk',
 			'Deva' => 'Devanagari',
 			'Ethi' => 'Etioopisk',
 			'Geor' => 'Georgisk',
 			'Grek' => 'Greks',
 			'Gujr' => 'Gujarati',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Han Bopomofo',
 			'Hang' => 'Hangeul',
 			'Hani' => 'Han',
 			'Hans' => 'Kurt',
 			'Hans@alt=stand-alone' => 'Kurt Han',
 			'Hant' => 'Lung',
 			'Hant@alt=stand-alone' => 'Lung Han',
 			'Hebr' => 'Hebreews',
 			'Hira' => 'Hiragana',
 			'Hrkt' => 'Japaans Silwenskraft',
 			'Jamo' => 'Jamo',
 			'Jpan' => 'Japaans',
 			'Kana' => 'Katakana',
 			'Khmr' => 'Khmer',
 			'Knda' => 'Kannada',
 			'Kore' => 'Koreaans',
 			'Laoo' => 'Laotisk',
 			'Latn' => 'Latiinsk',
 			'Mlym' => 'Malayalam',
 			'Mong' => 'Mongools',
 			'Mtei' => 'Meitei Mayek',
 			'Mymr' => 'Burmeesk',
 			'Nkoo' => 'N’Ko',
 			'Olck' => 'Ol Chiki',
 			'Orya' => 'Oriya',
 			'Rohg' => 'Hanifi',
 			'Sinh' => 'Singhaleesk',
 			'Sund' => 'Sundaneesk',
 			'Syrc' => 'Syrisk',
 			'Taml' => 'Tamil',
 			'Telu' => 'Telugu',
 			'Tfng' => 'Tifinagh',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thai',
 			'Tibt' => 'Tibeetisk',
 			'Vaii' => 'Vai',
 			'Yiii' => 'Yi',
 			'Zmth' => 'Matemaatisk Notiaring',
 			'Zsye' => 'Emojis',
 			'Zsym' => 'Sümboolen',
 			'Zxxx' => 'Nian skraft',
 			'Zyyy' => 'Algemian',
 			'Zzzz' => 'Ünbekäänd skraft',

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
			'001' => 'wäält',
 			'002' => 'Afrikoo',
 			'003' => 'Nuurdameerikoo',
 			'005' => 'Süüdameerikoo',
 			'009' => 'Oseaanien',
 			'011' => 'Waastafrikoo',
 			'013' => 'Madelameerikoo',
 			'014' => 'Uastafrikoo',
 			'015' => 'Nuurdafrikoo',
 			'017' => 'Madelafrikoo',
 			'018' => 'Süüdelk Afrikoo',
 			'019' => 'Ameerikoo',
 			'021' => 'Nuurdelk Ameerikoo',
 			'029' => 'Kariibik',
 			'030' => 'Uastaasien',
 			'034' => 'Süüdaasien',
 			'035' => 'Süüduastaasien',
 			'039' => 'Süüdeuroopa',
 			'053' => 'Austraalaasien',
 			'054' => 'Melaneesien',
 			'057' => 'Mikroneesien',
 			'061' => 'Polyneesien',
 			'142' => 'Aasien',
 			'143' => 'Madelaasien',
 			'145' => 'Waastaasien',
 			'150' => 'Euroopa',
 			'151' => 'Uasteuroopa',
 			'154' => 'Nuurdeuroopa',
 			'155' => 'Waasteuroopa',
 			'202' => 'Süüdelk Sahara Afrikoo',
 			'419' => 'Latiinsk Ameerikoo',
 			'AC' => 'Ascension Eilun',
 			'AD' => 'Andora',
 			'AE' => 'Ferianigt Araabisk Emiraaten',
 			'AF' => 'Afghaanistaan',
 			'AG' => 'Antiigua an Barbuuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albaanien',
 			'AM' => 'Armeenien',
 			'AO' => 'Angoola',
 			'AQ' => 'Antarktikaa',
 			'AR' => 'Argentiinien',
 			'AS' => 'Amerikoonsk Samoa',
 			'AT' => 'Uastenrik',
 			'AU' => 'Austraalien',
 			'AW' => 'Aruuba',
 			'AX' => 'Åland Eilunen',
 			'AZ' => 'Aserbaidschaan',
 			'BA' => 'Bosnien an Hertsegowina',
 			'BB' => 'Barbaados',
 			'BD' => 'Bangladesch',
 			'BE' => 'Belgien',
 			'BF' => 'Burkiina Faaso',
 			'BG' => 'Bulgaarien',
 			'BH' => 'Bachrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Beniin',
 			'BL' => 'St. Barthélemy',
 			'BM' => 'Bermuuda',
 			'BN' => 'Brunei',
 			'BO' => 'Boliiwien',
 			'BQ' => 'Kariibisk Neederlunen',
 			'BR' => 'Brasiilien',
 			'BS' => 'Bahaamas',
 			'BT' => 'Bhuutaan',
 			'BV' => 'Bouvet Eilun',
 			'BW' => 'Botsuana',
 			'BY' => 'Witjruslun',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Cocos Eilunen',
 			'CD' => 'Kongo - Kinshasa',
 			'CD@alt=variant' => 'Demokraatisk Republiik Kongo',
 			'CF' => 'Madelafrikoonsk Republiik',
 			'CG' => 'Kongo - Brazzaville',
 			'CG@alt=variant' => 'Republiik Kongo',
 			'CH' => 'Sweits',
 			'CI' => 'Elfenbianküst',
 			'CK' => 'Cook Eilunen',
 			'CL' => 'Chiile',
 			'CM' => 'Kameruun',
 			'CN' => 'Schiina',
 			'CO' => 'Kolumbien',
 			'CP' => 'Clipperton Eilun',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuuba',
 			'CV' => 'Kapwerden',
 			'CW' => 'Curaçao',
 			'CX' => 'Jul Eilun',
 			'CY' => 'Tsypern',
 			'CZ' => 'Tschechien',
 			'CZ@alt=variant' => 'Tschechisk Republiik',
 			'DE' => 'Tjiisklun',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibuti',
 			'DK' => 'Denemark',
 			'DM' => 'Domiinika',
 			'DO' => 'Dominikaans Republiik',
 			'DZ' => 'Algeerien',
 			'EA' => 'Ceuta an Melilla',
 			'EC' => 'Ekwadoor',
 			'EE' => 'Eestlun',
 			'EG' => 'Egypten',
 			'EH' => 'Waastsahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spoonien',
 			'ET' => 'Etioopien',
 			'EU' => 'Europeesk Unioon',
 			'EZ' => 'Eurorüm',
 			'FI' => 'Finlun',
 			'FJ' => 'Fidschi',
 			'FK' => 'Falkland Eilunen',
 			'FK@alt=variant' => 'Falkland Eilunen (Malwiinen)',
 			'FM' => 'Tuupslööden Stooten faan Mikroneesien',
 			'FO' => 'Färöer Eilunen',
 			'FR' => 'Frankrik',
 			'GA' => 'Gabuun',
 			'GB' => 'Ferianigt Köningrik',
 			'GD' => 'Grenaada',
 			'GE' => 'Georgien',
 			'GF' => 'Fransöösk Guayaana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghaana',
 			'GI' => 'Gibraltaar',
 			'GL' => 'Greenlun',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Ekwatoriaalguinea',
 			'GR' => 'Griichenlun',
 			'GS' => 'Süüdgeorgien an Süüdelk Sandwich Eilunen',
 			'GT' => 'Guatemaala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyaana',
 			'HK' => 'Prowins Hongkong',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heard an McDonald Eilunen',
 			'HN' => 'Honduuras',
 			'HR' => 'Kroaatien',
 			'HT' => 'Haiti',
 			'HU' => 'Ungarn',
 			'IC' => 'Kanaarisk Eilunen',
 			'ID' => 'Indoneesien',
 			'IE' => 'Irlun',
 			'IL' => 'Israel',
 			'IM' => 'Eilun Man',
 			'IN' => 'Indien',
 			'IO' => 'Britisk Teritoorium uun a Indisk Oosean',
 			'IO@alt=chagos' => 'Chagos Eilunen',
 			'IQ' => 'Iraak',
 			'IR' => 'Iraan',
 			'IS' => 'Islun',
 			'IT' => 'Itaalien',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordaanien',
 			'JP' => 'Jaapan',
 			'KE' => 'Keenia',
 			'KG' => 'Kirgistaan',
 			'KH' => 'Kambodscha',
 			'KI' => 'Kiribaati',
 			'KM' => 'Komooren',
 			'KN' => 'St. Kitts an Nevis',
 			'KP' => 'Nuurdkorea',
 			'KR' => 'Süüdkorea',
 			'KW' => 'Kuwait',
 			'KY' => 'Kaiman Eilunen',
 			'KZ' => 'Kasachstaan',
 			'LA' => 'Laos',
 			'LB' => 'Liibanon',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Libeeria',
 			'LS' => 'Lesotho',
 			'LT' => 'Litauen',
 			'LU' => 'Luksemborig',
 			'LV' => 'Letlun',
 			'LY' => 'Liibyen',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldaawien',
 			'ME' => 'Monteneegro',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshall Eilunen',
 			'MK' => 'Nuurdmatsedoonien',
 			'ML' => 'Maali',
 			'MM' => 'Mjanmaar',
 			'MN' => 'Mongolei',
 			'MO' => 'Prowins Macao',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Nuurdelk Mariaanen',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauretaanien',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Malediiwen',
 			'MW' => 'Malaawi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namiibia',
 			'NC' => 'Nei Kaledoonien',
 			'NE' => 'Niiger',
 			'NF' => 'Norfolk Eilun',
 			'NG' => 'Nigeeria',
 			'NI' => 'Nikaraagua',
 			'NL' => 'Neederlunen',
 			'NO' => 'Norweegen',
 			'NP' => 'Neepaal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Neisialun',
 			'NZ@alt=variant' => 'Aotearoa',
 			'OM' => 'Omaan',
 			'PA' => 'Panama',
 			'PE' => 'Peruu',
 			'PF' => 'Fransöösk Polyneesien',
 			'PG' => 'Papua Nei Guinea',
 			'PH' => 'Filipiinen',
 			'PK' => 'Pakistaan',
 			'PL' => 'Poolen',
 			'PM' => 'St. Pierre an Miquelon',
 			'PN' => 'Pitcairn Eilunen',
 			'PR' => 'Puerto Riko',
 			'PS' => 'Stoot Palestiina',
 			'PS@alt=short' => 'Palestiina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Kataar',
 			'QO' => 'Faarder Oseaanien',
 			'RE' => 'Réunion',
 			'RO' => 'Rumeenien',
 			'RS' => 'Serbien',
 			'RU' => 'Ruslun',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudi Araabien',
 			'SB' => 'Salomon Eilunen',
 			'SC' => 'Seschelen',
 			'SD' => 'Sudaan',
 			'SE' => 'Sweeden',
 			'SG' => 'Singapuur',
 			'SH' => 'St. Helena',
 			'SI' => 'Sloweenien',
 			'SJ' => 'Svalbard an Jan Mayen',
 			'SK' => 'Slowakei',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Seenegal',
 			'SO' => 'Somaalia',
 			'SR' => 'Suurinam',
 			'SS' => 'Süüdsudaan',
 			'ST' => 'São Tomé an Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syrien',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaasilun',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks an Caicos Eilunen',
 			'TD' => 'Tschad',
 			'TF' => 'Fransöösk Süüd- an Antarktisregiuunen',
 			'TG' => 'Toogo',
 			'TH' => 'Thailun',
 			'TJ' => 'Tadjikistaan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Uast Timor',
 			'TM' => 'Turkmeenistaan',
 			'TN' => 'Tuneesien',
 			'TO' => 'Tonga',
 			'TR' => 'Türkiye',
 			'TR@alt=variant' => 'Türkei',
 			'TT' => 'Trinidad an Tobago',
 			'TV' => 'Tuwaalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansania',
 			'UA' => 'Ukraine',
 			'UG' => 'Uganda',
 			'UM' => 'United States Minor Outlying Islands',
 			'UN' => 'Feriand Natsioonen',
 			'US' => 'Ferianagt Stooten',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbekistaan',
 			'VA' => 'Watikaanstääd',
 			'VC' => 'St. Vincent an Grenadiinen',
 			'VE' => 'Weenesuela',
 			'VG' => 'Britisk Jongfoomen Eilunen',
 			'VI' => 'Amerikoonsk Jongfoomen Eilunen',
 			'VN' => 'Wjetnam',
 			'VU' => 'Wanuaatuu',
 			'WF' => 'Wallis an Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Pseudo-Accents',
 			'XB' => 'Pseudo-Bidi',
 			'XK' => 'Kosowo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Süüdafrikoo',
 			'ZM' => 'Sambia',
 			'ZW' => 'Simbabwe',
 			'ZZ' => 'Ünbekäänd Regiuun',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kalender',
 			'cf' => 'Münt Formaat',
 			'collation' => 'Sortiaring',
 			'currency' => 'Münt',
 			'hc' => 'Stünjen Formaat (12 of 24)',
 			'lb' => 'Rä Ambreeg Stiil',
 			'ms' => 'Miat Süsteem',
 			'numbers' => 'Taalen',

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
 				'buddhist' => q{Buddhistisk Kalender},
 				'chinese' => q{Schineesk Kalender},
 				'coptic' => q{Koptisk Kalender},
 				'dangi' => q{Dangi Kalender},
 				'ethiopic' => q{Etioopisk Kalender},
 				'ethiopic-amete-alem' => q{Etioopisk Amete Alem Kalender},
 				'gregorian' => q{Gregoriaans Kalender},
 				'hebrew' => q{Hebreewsk Kalender},
 				'islamic' => q{Islaamisk Kalender},
 				'islamic-civil' => q{Islaamisk Bürgerlik Kalender},
 				'islamic-umalqura' => q{Islaamisk Umalkura Kalender},
 				'iso8601' => q{ISO-8601 Kalender},
 				'japanese' => q{Japoonsk Kalender},
 				'persian' => q{Persisk Kalender},
 				'roc' => q{Minguo Kalender},
 			},
 			'cf' => {
 				'account' => q{Konto Münt Formaat},
 				'standard' => q{Standard Münt Formaat},
 			},
 			'collation' => {
 				'ducet' => q{Unicode Sortiaring},
 				'search' => q{Normool Schüken},
 				'standard' => q{Standard Sortiaring},
 			},
 			'hc' => {
 				'h11' => q{12 Stünj Süsteem (0–11)},
 				'h12' => q{12 Stünj Süsteem (1–12)},
 				'h23' => q{24 Stünj Süsteem (0–23)},
 				'h24' => q{24 Stünj Süsteem (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Luas Rä Ambreeg Stiil},
 				'normal' => q{Normool Rä Ambreeg Stiil},
 				'strict' => q{String Rä Ambreeg Stiil},
 			},
 			'ms' => {
 				'metric' => q{Meetrisk Süsteem},
 				'uksystem' => q{UK Süsteem},
 				'ussystem' => q{US Süsteem},
 			},
 			'numbers' => {
 				'arab' => q{Araabisk Taalen},
 				'arabext' => q{Ütjwidjet Araabisk taalen},
 				'armn' => q{Armeensk Taalen},
 				'armnlow' => q{Armeensk Letj Taalen},
 				'beng' => q{Bangla Taalen},
 				'cakm' => q{Chakma Taalen},
 				'deva' => q{Devanagari Taalen},
 				'ethi' => q{Etioopisk Taalen},
 				'fullwide' => q{Ütjwidjet Taalen},
 				'geor' => q{Georgisk Taalen},
 				'grek' => q{Greks Taalen},
 				'greklow' => q{Greks Letj Taalen},
 				'gujr' => q{Gujarati Taalen},
 				'guru' => q{Gurmukhi Taalen},
 				'hanidec' => q{Schineesk Deesimaal Taalen},
 				'hans' => q{Ianfach Schineesk Taalen},
 				'hansfin' => q{Ianfach Schineesk Finans Taalen},
 				'hant' => q{Ual Schineesk Taalen},
 				'hantfin' => q{Ual Schineesk Finans Taalen},
 				'hebr' => q{Hebreewsk Taalen},
 				'java' => q{Jawaans Taalen},
 				'jpan' => q{Japoonsk Taalen},
 				'jpanfin' => q{Japoonsk Finans Taalen},
 				'khmr' => q{Khmer Taalen},
 				'knda' => q{Kannada Taalen},
 				'laoo' => q{Laotisk Taalen},
 				'latn' => q{Europeesk Taalen},
 				'mlym' => q{Malayalam Taalen},
 				'mtei' => q{Meetei Mayek Taalen},
 				'mymr' => q{Mjanmaar Taalen},
 				'olck' => q{Ol Chiki Taalen},
 				'orya' => q{Oriya Taalen},
 				'roman' => q{Röömsk Taalen},
 				'romanlow' => q{Röömsk Letj Taalen},
 				'taml' => q{Ual Tamil Taalen},
 				'tamldec' => q{Tamil Taalen},
 				'telu' => q{Telugu Taalen},
 				'thai' => q{Thai Taalen},
 				'tibt' => q{Tibetaans Taalen},
 				'vaii' => q{Vai Taalen},
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
			'metric' => q{Meetrisk},
 			'UK' => q{Britisk},
 			'US' => q{US-Amerikoonsk},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Spriik: {0}',
 			'script' => 'Skraft: {0}',
 			'region' => 'Regiuun: {0}',

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
			auxiliary => qr{[áàăâã æ ç éèĕêë ğ íìĭîïİī ı ñ óòŏôøō œ q ş ß úùŭûū v x yÿ z]},
			main => qr{[aåäā b c dđ eē f g h i j k l m n oö p r s t uü w]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘‚ "“„ « » ( ) \[ \] \{ \} § @ * / \& #]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(hemelswai),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(hemelswai),
					},
					# Long Unit Identifier
					'area-acre' => {
						'other' => q({0} acres),
					},
					# Core Unit Identifier
					'acre' => {
						'other' => q({0} acres),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'other' => q({0} hektaar),
					},
					# Core Unit Identifier
					'hectare' => {
						'other' => q({0} hektaar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(kwadrootsentimeetern),
						'other' => q({0} kwadrootsentimeetern),
						'per' => q({0} per kwadrootsentimeeter),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(kwadrootsentimeetern),
						'other' => q({0} kwadrootsentimeetern),
						'per' => q({0} per kwadrootsentimeeter),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(kwadrootfut),
						'other' => q({0} kwadrootfut),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kwadrootfut),
						'other' => q({0} kwadrootfut),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(kwadroottol),
						'other' => q({0} kwadroottol),
						'per' => q({0} per kwadroottol),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(kwadroottol),
						'other' => q({0} kwadroottol),
						'per' => q({0} per kwadroottol),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kwadrootkilomeetern),
						'other' => q({0} kwadrootkilomeetern),
						'per' => q({0} per kwadrootkilomeeter),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kwadrootkilomeetern),
						'other' => q({0} kwadrootkilomeetern),
						'per' => q({0} per kwadrootkilomeeter),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(kwadrootmeetern),
						'per' => q({0} per kwadrootmeeter),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(kwadrootmeetern),
						'per' => q({0} per kwadrootmeeter),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(kwadrootmiilen),
						'other' => q({0} kwadrootmiilen),
						'per' => q({0} per kwadrootmiil),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(kwadrootmiilen),
						'other' => q({0} kwadrootmiilen),
						'per' => q({0} per kwadrootmiil),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(kwadrootyards),
						'other' => q({0} kwadrootyards),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(kwadrootyards),
						'other' => q({0} kwadrootyards),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} uast),
						'north' => q({0} nuurd),
						'south' => q({0} süüd),
						'west' => q({0} waast),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} uast),
						'north' => q({0} nuurd),
						'south' => q({0} süüd),
						'west' => q({0} waast),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(juarhunerten),
						'other' => q({0} juarhunerten),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(juarhunerten),
						'other' => q({0} juarhunerten),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} per dai),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} per dai),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(juartjiinten),
						'other' => q({0} juartjiinten),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(juartjiinten),
						'other' => q({0} juartjiinten),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0} stünjen),
						'per' => q({0} per stünj),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0} stünjen),
						'per' => q({0} per stünj),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekunden),
						'other' => q({0} mikrosekunden),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekunden),
						'other' => q({0} mikrosekunden),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisekunden),
						'other' => q({0} millisekunden),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisekunden),
						'other' => q({0} millisekunden),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minüten),
						'other' => q({0} minüten),
						'per' => q({0} per minüt),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minüten),
						'other' => q({0} minüten),
						'per' => q({0} per minüt),
					},
					# Long Unit Identifier
					'duration-month' => {
						'other' => q({0} muuner),
						'per' => q({0} per muun),
					},
					# Core Unit Identifier
					'month' => {
						'other' => q({0} muuner),
						'per' => q({0} per muun),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekunden),
						'other' => q({0} nanosekunden),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekunden),
						'other' => q({0} nanosekunden),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kwartaalen),
						'other' => q({0} kwartaalen),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kwartaalen),
						'other' => q({0} kwartaalen),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekunden),
						'other' => q({0} sekunden),
						'per' => q({0} per sekund),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekunden),
						'other' => q({0} sekunden),
						'per' => q({0} per sekund),
					},
					# Long Unit Identifier
					'duration-week' => {
						'other' => q({0} wegen),
						'per' => q({0} per weg),
					},
					# Core Unit Identifier
					'week' => {
						'other' => q({0} wegen),
						'per' => q({0} per weg),
					},
					# Long Unit Identifier
					'duration-year' => {
						'other' => q({0} juaren),
						'per' => q({0} per juar),
					},
					# Core Unit Identifier
					'year' => {
						'other' => q({0} juaren),
						'per' => q({0} per juar),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(typograafisk ems),
						'other' => q({0} ems),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(typograafisk ems),
						'other' => q({0} ems),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'other' => q({0} megapixel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'other' => q({0} megapixel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'other' => q({0} pixel),
					},
					# Core Unit Identifier
					'pixel' => {
						'other' => q({0} pixel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pixel per sentimeeter),
						'other' => q({0} pixel per sentimeeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pixel per sentimeeter),
						'other' => q({0} pixel per sentimeeter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixel per tol),
						'other' => q({0} pixel per tol),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixel per tol),
						'other' => q({0} pixel per tol),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronoomisk ianhaiden),
						'other' => q({0} astronoomisk ianhaiden),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronoomisk ianhaiden),
						'other' => q({0} astronoomisk ianhaiden),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sentimeetern),
						'other' => q({0} sentimeetern),
						'per' => q({0} per sentimeeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sentimeetern),
						'other' => q({0} sentimeetern),
						'per' => q({0} per sentimeeter),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(deesimeetern),
						'other' => q({0} deesimeetern),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(deesimeetern),
						'other' => q({0} deesimeetern),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'other' => q({0} eerd raadius),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'other' => q({0} eerd raadius),
					},
					# Long Unit Identifier
					'length-foot' => {
						'per' => q({0} per fut),
					},
					# Core Unit Identifier
					'foot' => {
						'per' => q({0} per fut),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'other' => q({0} foraglengden),
					},
					# Core Unit Identifier
					'furlong' => {
						'other' => q({0} foraglengden),
					},
					# Long Unit Identifier
					'length-inch' => {
						'per' => q({0} per tol),
					},
					# Core Unit Identifier
					'inch' => {
						'per' => q({0} per tol),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilomeetern),
						'other' => q({0} kilomeetern),
						'per' => q({0} per kilomeeter),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilomeetern),
						'other' => q({0} kilomeetern),
						'per' => q({0} per kilomeeter),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(laachtjuaren),
						'other' => q({0} laachtjuaren),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(laachtjuaren),
						'other' => q({0} laachtjuaren),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(meetern),
						'other' => q({0} meetern),
						'per' => q({0} per meeter),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(meetern),
						'other' => q({0} meetern),
						'per' => q({0} per meeter),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikromeetern),
						'other' => q({0} mikromeetern),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikromeetern),
						'other' => q({0} mikromeetern),
					},
					# Long Unit Identifier
					'length-mile' => {
						'other' => q({0} miilen),
					},
					# Core Unit Identifier
					'mile' => {
						'other' => q({0} miilen),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(skandinaawisk miilen),
						'other' => q({0} skandinaawisk miilen),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(skandinaawisk miilen),
						'other' => q({0} skandinaawisk miilen),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millimeetern),
						'other' => q({0} millimeetern),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimeetern),
						'other' => q({0} millimeetern),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanomeetern),
						'other' => q({0} nanomeetern),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanomeetern),
						'other' => q({0} nanomeetern),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(siamiilen),
						'other' => q({0} siamiilen),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(siamiilen),
						'other' => q({0} siamiilen),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'other' => q({0} parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'other' => q({0} parsecs),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(picomeetern),
						'other' => q({0} picomeetern),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(picomeetern),
						'other' => q({0} picomeetern),
					},
					# Long Unit Identifier
					'length-point' => {
						'other' => q({0} points),
					},
					# Core Unit Identifier
					'point' => {
						'other' => q({0} points),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'other' => q({0} san raadien),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'other' => q({0} san raadien),
					},
					# Long Unit Identifier
					'length-yard' => {
						'other' => q({0} yards),
					},
					# Core Unit Identifier
					'yard' => {
						'other' => q({0} yards),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}U),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}U),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(wai),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(wai),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acres),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acres),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektaar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektaar),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(tol²),
						'other' => q({0} tol²),
						'per' => q({0}/tol²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(tol²),
						'other' => q({0} tol²),
						'per' => q({0}/tol²),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} U),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} U),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(juarh),
						'other' => q({0} juarh),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(juarh),
						'other' => q({0} juarh),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(daar),
						'other' => q({0} daar),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(daar),
						'other' => q({0} daar),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(juartj),
						'other' => q({0} juartj),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(juartj),
						'other' => q({0} juartj),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(stünjen),
						'other' => q({0} st),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(stünjen),
						'other' => q({0} st),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsekn),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsekn),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisekn),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisekn),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(muuner),
						'other' => q({0} mnr),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(muuner),
						'other' => q({0} mnr),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekn),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekn),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kwrt),
						'other' => q({0} kwrtn),
						'per' => q({0}/kw),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kwrt),
						'other' => q({0} kwrtn),
						'per' => q({0}/kw),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekn),
						'other' => q({0} sek),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekn),
						'other' => q({0} sek),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(wegen),
						'other' => q({0} wgn),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(wegen),
						'other' => q({0} wgn),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(juaren),
						'other' => q({0} jrn),
						'per' => q({0}/j),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(juaren),
						'other' => q({0} jrn),
						'per' => q({0}/j),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixel),
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
					'length-astronomical-unit' => {
						'name' => q(AI),
						'other' => q({0} AI),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(AI),
						'other' => q({0} AI),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(eerd raadius),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(eerd raadius),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(faaden),
						'other' => q({0} faaden),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(faaden),
						'other' => q({0} faaden),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(fut),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(fut),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(foraglengden),
						'other' => q({0} for),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(foraglengden),
						'other' => q({0} for),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(tol),
						'other' => q({0} tol),
						'per' => q({0}/tol),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(tol),
						'other' => q({0} tol),
						'per' => q({0}/tol),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(laachtjrn),
						'other' => q({0} lj),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(laachtjrn),
						'other' => q({0} lj),
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
					'length-micrometer' => {
						'name' => q(μmeetern),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μmeetern),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(miilen),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(miilen),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(sm),
						'other' => q({0} sm),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(sm),
						'other' => q({0} sm),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsecs),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(points),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(points),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(san raadien),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(san raadien),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yards),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yards),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}{1}),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ja|j|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:naan|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} an {1}),
				2 => q({0} an {1}),
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
			'nan' => q(nian taal),
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
				'1000000' => {
					'other' => '0M',
				},
				'10000000' => {
					'other' => '00 miljoon',
				},
				'100000000' => {
					'other' => '000 miljoon',
				},
				'1000000000' => {
					'other' => '0G',
				},
				'10000000000' => {
					'other' => '00G',
				},
				'100000000000' => {
					'other' => '000 miljaard',
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
				'currency' => q(Ferianagt Araabisk Emiraaten Dirham),
				'other' => q(Ferianagt Araabisk Emiraaten Dirhams),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghaans Afghani),
				'other' => q(Afghaans Afghanis),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Albaansk Lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armeensk Dram),
				'other' => q(Armeensk Drams),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Neederluns Antilen Gulden),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angolaans Kwanza),
				'other' => q(Angolaans Kwanzas),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentiinsk Peeso),
				'other' => q(Argentiinsk Peesos),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Austraalisk Dooler),
				'other' => q(Austraalisk Doolers),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruuba Florin),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Aserbaidschaans Manat),
				'other' => q(Aserbaidschaans Manats),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosnisk-Hertsegowiinsk Waksel Mark),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbaados Dooler),
				'other' => q(Barbaados Doolers),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bangladesch Taka),
				'other' => q(Bangladesch Takas),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgaarsk Lew),
				'other' => q(Bulgaarsk Lewa),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bachrains Dinaar),
				'other' => q(Bachrains Dinaaren),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi Franc),
				'other' => q(Burundi Francs),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuuda Dooler),
				'other' => q(Bermuuda Doolers),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Brunei Dooler),
				'other' => q(Brunei Doolers),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliwiaans Boliwiano),
				'other' => q(Boliwiaans Boliwianos),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brasiliaans Real),
				'other' => q(Brasiliaans Reals),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahaamas Dooler),
				'other' => q(Bahaamas Doolers),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Bhuutaans Ngultrum),
				'other' => q(Bhuutaans Ngultrums),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botsuana Pula),
				'other' => q(Botsuana Pulas),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Witjrüsk Ruubel),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belize Dooler),
				'other' => q(Belize Doolers),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanaadsk Dooler),
				'other' => q(Kanaadsk Doolers),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Kongoleesk Franc),
				'other' => q(Kongoleesk Francs),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Sweitser Franken),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Chileens Peeso),
				'other' => q(Chileens Peesos),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Schineesk Bütjluns Yuan),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Schineesk Yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Kolumbiaans Peeso),
				'other' => q(Kolumbiaans Peesos),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Cost Rica Colon),
				'other' => q(Costa Rica Colons),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Kubaans Waksel Peeso),
				'other' => q(Kubaans Waksel Peesos),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Kubaans Peeso),
				'other' => q(Kubaans Peesos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kapwerden Eskuudo),
				'other' => q(Kapwerden Eskuudos),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Tschechisk Krüün),
				'other' => q(Tschechisk Krüünen),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Djibouti Franc),
				'other' => q(Djibouti Francs),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Däänsk Krüün),
				'other' => q(Däänsk Krüünen),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominikaans Peeso),
				'other' => q(Dominikaans Peesos),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algeerisk Dinaar),
				'other' => q(Algeerisk Dinaaren),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Egyptisk Pünj),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritreesk Nakfa),
				'other' => q(Eritreesk Nakfas),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Etioopisk Birr),
				'other' => q(Etioopisk Birrs),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'other' => q(Euros),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fidschi Dooler),
				'other' => q(Fidschi Doolers),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Falklun Eilunen Pünj),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Britisk Pünj),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Georgisk Lari),
				'other' => q(Georgisk Laris),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Ghanaask Cedi),
				'other' => q(Ghanaask Cedis),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltaar Pünj),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambisk Delasi),
				'other' => q(Gambisk Delasis),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Guineesk Franc),
				'other' => q(Guineesk Francs),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Guatemalteesk Quetzal),
				'other' => q(Guatemalteesk Quetzals),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Guayaneesk Dooler),
				'other' => q(Guayaneesk Doolers),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hongkong Dooler),
				'other' => q(Hongkong Doolers),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Honduraans Lempira),
				'other' => q(Honduraans Lempiras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kroaatisk Kuna),
				'other' => q(Kroaatisk Kunas),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haitiaans Gourde),
				'other' => q(Haitiaans Gourdes),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Ungaars Forint),
				'other' => q(Ungaars Forints),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indoneesk Rupie),
				'other' => q(Indoneesk Rupien),
			},
		},
		'ILS' => {
			symbol => 'ILS',
			display_name => {
				'currency' => q(Israeels Nei Scheekel),
				'other' => q(Israeels Nei Scheekels),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(Indisk Rupie),
				'other' => q(Indisk Rupien),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Iraaks Dinaar),
				'other' => q(Iraaks Dinaaren),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Iraans Rial),
				'other' => q(Iraans Rials),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Isluns Krüün),
				'other' => q(Isluns Krüünen),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaikaans Dooler),
				'other' => q(Jamaikaans Doolers),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jordaansk Dinaar),
				'other' => q(Jordaansk Dinaaren),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Japoonsk Yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Keniaans Skalang),
				'other' => q(Keniaans Skalanger),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kirgisk Som),
				'other' => q(Kirgisk Soms),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Kambodschaansk Riel),
				'other' => q(Kambodschaansk Riels),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komooren Franc),
				'other' => q(Komooren Francs),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Nuurdkoreaans Won),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(Süüdkoreaans Won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuwaits Dinaar),
				'other' => q(Kuwaits Dinaaren),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Cayman Eilunen Dooler),
				'other' => q(Cayman Eilunen Doolers),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kasachstaans Tenge),
				'other' => q(Kasachstaans Tenges),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laootisk Kip),
				'other' => q(Laootisk Kips),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Libaneesk Pünj),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Sri Lankas Rupie),
				'other' => q(Sri Lankas Rupien),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Libeerisk Dooler),
				'other' => q(Libeerisk Doolers),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesotho Loti),
				'other' => q(Lesotho Lotis),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Liibysk Dinaar),
				'other' => q(Liibysk Dinaaren),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Marokaans Dirham),
				'other' => q(Marokaans Dirhams),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldaawisk Leu),
				'other' => q(Moldaawisk Lei),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Madagaskar Ariary),
				'other' => q(Madagaskar Ariarys),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Matsedoonsk Dinaar),
				'other' => q(Matsedoonsk Dinaaren),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Mjanmaar Kyat),
				'other' => q(Mjanmaar Kyats),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongoolisk Tugrik),
				'other' => q(Mongoolisk Tugriks),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Macau Pataca),
				'other' => q(Macau Patacas),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mauritiaans Ouguiya),
				'other' => q(Mauritiaans Ouguiyas),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mauritiaans Rupie),
				'other' => q(Mauritiaans Rupien),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Malediiwisk Rufiyaa),
				'other' => q(Malediiwisk Rufiyaas),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malaawwisk Kwacha),
				'other' => q(Malaawisk Kwachas),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Meksikoons Peeso),
				'other' => q(Meksikoons Peesos),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Malaysisk Ringgit),
				'other' => q(Malaysisk Ringgits),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mosambikaans Metical),
				'other' => q(Mosambikaans Meticals),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namiibisk Dooler),
				'other' => q(Namiibisk Doolers),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigeriaans Naira),
				'other' => q(Nigeriaans Nairas),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nikaraaguaans Cordoba),
				'other' => q(Nikaraaguaans Cordobas),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Noorsk Krüün),
				'other' => q(Noorsk Krüünen),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepaleesk Rupie),
				'other' => q(Nepaleesk Rupien),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Neisialun Dooler),
				'other' => q(Neisialun Doolers),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Omaans Rial),
				'other' => q(Omaans Rials),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panameesk Balboa),
				'other' => q(Panameesk Balboas),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peruaans Sol),
				'other' => q(Peruaans Sols),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papua Neiguineesk Kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filipiinsk Peeso),
				'other' => q(Filipiinsk Peesos),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakistaans Rupie),
				'other' => q(Pakistaans Rupien),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Poolsk Sloty),
				'other' => q(Poolsk Slotys),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraguayaans Guarani),
				'other' => q(Paraguayaans Guaranis),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Kataars Riyal),
				'other' => q(Kataars Riyals),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Rumeensk Leu),
				'other' => q(Rumeensk Lei),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serbisk Dinaar),
				'other' => q(Serbisk Dinaaren),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rüsk Ruubel),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Ruanda Franc),
				'other' => q(Ruanda Francs),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudi Araabisk Riyal),
				'other' => q(Saudi Araabisk Riyals),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Salomoonen Dooler),
				'other' => q(Salomoonen Doolers),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seschelen Rupie),
				'other' => q(Seschelen Rupien),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudaneesk Pünj),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Sweedsk Krüün),
				'other' => q(Sweedsk Krüünen),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singapuur Dooler),
				'other' => q(Singapuur Doolers),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St. Helena Pünj),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sierra Leones Leone),
				'other' => q(Sierra Leones Leones),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra Leones Leone \(1964—2022\)),
				'other' => q(Sierra Leones Leones \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somaali Skalang),
				'other' => q(Somaali Skalanger),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinameesk Dooler),
				'other' => q(Surinameesk Doolers),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Süüdsudaneesk Pünj),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(São Tomé an Príncipe Dobra),
				'other' => q(São Tomé an Príncipe Dobras),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Syrisk Pünj),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Eswatini Lilangeni),
				'other' => q(Eswatini Emalengeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Thai Baht),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tadjikisk Somoni),
				'other' => q(Tadjikisk Somonis),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Turkmeensk Manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tuneesisk Dinaar),
				'other' => q(Tuneesisk Dinaaren),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tongaans Pa’anga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Türkisk Lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad an Tobago Dooler),
				'other' => q(Trinidad an Tobago Doolers),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Nei Taiwan Dooler),
				'other' => q(Nei Taiwan Doolers),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tansaanisk Skalang),
				'other' => q(Tansaanisk Skalanger),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ukrainisk Griwna),
				'other' => q(Ukrainisk Griwni),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Ugandisk Skalang),
				'other' => q(Ugandisk Skalanger),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(US Dooler),
				'other' => q(US Doolers),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruguayaans Peeso),
				'other' => q(Uruguayaans Peesos),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Usbeekisk Som),
				'other' => q(Usbeekisk Soms),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Weenesulaans Bolivar),
				'other' => q(Weenesulaans Bolivars),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(Wjetnameesk Dong),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Wanuaatuu Vatu),
				'other' => q(Wanuaatuu Vatus),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoaans Tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Sentraal Afrikoonsk Franc),
				'other' => q(Sentraal Afrikoonsk Francs),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Uast Kariibik Dooler),
				'other' => q(Uast Kariibik Doolers),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Waastafrikoonsk CFA Franc),
				'other' => q(Waastafrikoonsk CFA Francs),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP Franc),
				'other' => q(CFP Francs),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Ünbekäänd Münt),
				'other' => q(ünbekäänd münt),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Jeemens Rial),
				'other' => q(Jeemens Rials),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Süüdafrikoons Rand),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Sambisk Kwacha),
				'other' => q(Sambisk Kwachas),
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
							'Jan',
							'Feb',
							'Mar',
							'Apr',
							'Mei',
							'Jün',
							'Jül',
							'Aug',
							'Sep',
							'Okt',
							'Nof',
							'Det'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Janewoore',
							'Febrewoore',
							'Maarts',
							'April',
							'Mei',
							'Jüüne',
							'Jüüle',
							'August',
							'September',
							'Oktuuber',
							'Nofember',
							'Detsember'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'A',
							'M',
							'J',
							'J',
							'A',
							'S',
							'O',
							'N',
							'D'
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
						mon => 'Mun',
						tue => 'Tei',
						wed => 'Wed',
						thu => 'Tür',
						fri => 'Fre',
						sat => 'San',
						sun => 'Sön'
					},
					short => {
						mon => 'Mu',
						tue => 'Te',
						wed => 'We',
						thu => 'Tü',
						fri => 'Fr',
						sat => 'Sa',
						sun => 'Sö'
					},
					wide => {
						mon => 'Mundai',
						tue => 'Teisdai',
						wed => 'Weedensdai',
						thu => 'Tüürsdai',
						fri => 'Freidai',
						sat => 'Saninj',
						sun => 'Söndai'
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
					wide => {0 => 'iarst kwartaal',
						1 => 'naist kwartaal',
						2 => 'traad kwartaal',
						3 => 'fjuard kwartaal'
					},
				},
				'stand-alone' => {
					narrow => {0 => 'I',
						1 => 'II',
						2 => 'III',
						3 => 'IV'
					},
				},
			},
	} },
);

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'am' => q{i/m},
					'pm' => q{e/m},
				},
				'narrow' => {
					'am' => q{i},
					'pm' => q{e},
				},
				'wide' => {
					'am' => q{iarmade},
					'pm' => q{eftermade},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'am' => q{i},
					'pm' => q{e},
				},
				'wide' => {
					'am' => q{iarmade},
					'pm' => q{eftermade},
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
				'0' => 'f.Kr.',
				'1' => 'AD'
			},
			wide => {
				'0' => 'Föör Krast'
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
			'full' => q{G y MMMM d, EEEE},
			'long' => q{G y MMMM d},
			'medium' => q{G y MMM d},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE, d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d. MMM y},
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
			'short' => q{{1}, {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Ed => q{E, d},
			MMMd => q{MMM, d},
			yyyyMMMd => q{G y MMM, d},
		},
		'gregorian' => {
			EBhm => q{E, h:mm B},
			EBhms => q{E, h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			GyMMM => q{G MMM y},
			GyMMMEd => q{G E, d. MMM y},
			GyMMMd => q{G d. MMM y},
			GyMd => q{G dd/MM/y},
			M => q{LL},
			MEd => q{E dd/MM},
			MMMEd => q{E, d. MMM},
			MMMMW => q{'weg' W 'faan' MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{dd/MM},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{MM/y},
			yMEd => q{E, dd/MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d. MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d. MMM y},
			yMd => q{dd/MM/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQ y},
			yw => q{'weg' w 'faan' Y},
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
		'gregorian' => {
			Gy => {
				G => q{G y – G y},
				y => q{G y – y},
			},
			GyM => {
				G => q{G M/y – G M/y},
				M => q{G M/y – M/y},
				y => q{G M/y – M/y},
			},
			GyMEd => {
				G => q{G E, dd/MM/y – G E, dd/MM/y},
				M => q{G E, dd/MM/y – E, dd/MM/y},
				d => q{G E, dd/MM/y – E, dd/MM/y},
				y => q{G E, dd/MM/y – E. dd/MM/y},
			},
			GyMMM => {
				G => q{G MMM y – G MMM y},
				M => q{G MMM – MMM y},
				y => q{G MMM y – MMM y},
			},
			GyMMMEd => {
				G => q{G E, d. MMM y – G E, d. MMM yE},
				M => q{G E, d. MMM y – E, d. MMM y},
				d => q{G E, d. MMM – E, d. MMM y},
				y => q{G E, d. MMM y – E, d. MMM y},
			},
			GyMMMd => {
				G => q{G d. MMM y – G d. MMM y},
				M => q{G d. MMM – d. MMM y},
				d => q{G d. – d. MMM y},
				y => q{G d. MMM y – d. MMM y},
			},
			GyMd => {
				G => q{G d/M/y – G d/M/y},
				M => q{G d/M/y – d/M/y},
				d => q{G d/M/y – d/M/y},
				y => q{G d/M/y – d/M/y},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{MM – MM},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. MMM – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d. – d. MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d. – d.},
			},
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM y – E, d. MMM y},
				d => q{E, d. MMM – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d. – d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} Tidj),
		regionFormat => q({0} Somertidj),
		regionFormat => q({0} Standard Tidj),
		'Afghanistan' => {
			long => {
				'standard' => q#Afghaanistaan Tidj#,
			},
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algier#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripolis#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Sentraal Afrikoo Tidj#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Uast Afrikoo Tidj#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Süüdelk Afrikoo Standard Tidj#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Waast Afrikoo Somertidj#,
				'generic' => q#Waast Afrikoo Tidj#,
				'standard' => q#Waast Afrikoo Standard Tidj#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska Somertidj#,
				'generic' => q#Alaska Tidj#,
				'standard' => q#Alaska Standard Tidj#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazonas Somertidj#,
				'generic' => q#Amazonas Tidj#,
				'standard' => q#Amazonas Standard Tidj#,
			},
		},
		'America/Antigua' => {
			exemplarCity => q#Antiigua#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruuba#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia de Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Brabaados#,
		},
		'America/Dominica' => {
			exemplarCity => q#Domiinika#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenaada#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemaala#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyaana#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Meksiko Steed#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Nuurd Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Nuurd Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Nuurd Dakota#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Riko#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Sentraal Ameerikoo Somertidj#,
				'generic' => q#Sentraal Ameerikoo Tidj#,
				'standard' => q#Sentraal Ameerikoo Standard Tidj#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Uast Ameerikoo Somertidj#,
				'generic' => q#Uast Ameerikoo Tidj#,
				'standard' => q#Uast Ameerikoo Standard Tidj#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Waast Ameerikoo Somertidj#,
				'generic' => q#Waast Ameerikoo Tidj#,
				'standard' => q#Waast Ameerikoo Standard Tidj#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Ameerikoo Pasiifik Somertidj#,
				'generic' => q#Ameeriko Pasiifik Tidj#,
				'standard' => q#Ameerikoo Pasiifik Standard Tidj#,
			},
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Wostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia Somertidj#,
				'generic' => q#Apia Tidj#,
				'standard' => q#Apia Standard Tidj#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Araabisk Somertidj#,
				'generic' => q#Araabisk Tidj#,
				'standard' => q#Araabisk Standard Tidj#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentiinien Somertidj#,
				'generic' => q#Argentiinien Tidj#,
				'standard' => q#Argentiinien Standard Tidj#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Waast Argentiinien Somertidj#,
				'generic' => q#Waast Argentiinien Tidj#,
				'standard' => q#Waast Argentiinien Standard Tidj#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armeenien Somertidj#,
				'generic' => q#Armeenien Tidj#,
				'standard' => q#Armeenien Standard Tidj#,
			},
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Aschgabat#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bachrain#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bischkek#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkuta#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Tschoibalsan#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duschanbe#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Chowd#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtschatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karatschi#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kutsching#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Maskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Nowokusnetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Nowosibirsk#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pjöngjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Kataar#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Ranguun#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh Steed#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Schanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapuur#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipee#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taschkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiflis#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumtschi#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Wjentiane#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Wladiwostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Jerewan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Ameerikoo Atlantik Somertidj#,
				'generic' => q#Ameerikoo Atlantik Tidj#,
				'standard' => q#Ameerikoo Atlantik Standard Tidj#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Atsooren#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanaaren#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kapwerden#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Färöern#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Süüdgeorgien#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Sentraal Austraalisk Somertidj#,
				'generic' => q#Sentraal Austraalisk Tidj#,
				'standard' => q#Sentraal Austraalisk Standard Tidj#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Sentraal Waastaustraalisk Somertidj#,
				'generic' => q#Sentraal Waastaustraalisk Tidj#,
				'standard' => q#Sentraal Waastaustraalisk Standard Tidj#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Uast Austraalisk Somertidj#,
				'generic' => q#Uast Austraalisk Tidj#,
				'standard' => q#Uast Austraalisk Standard Tidj#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Waast Austraalisk Somertidj#,
				'generic' => q#Waast Austraalisk Tidj#,
				'standard' => q#Waast Austraalisk Standard Tidj#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Aserbaidschaan Somertidj#,
				'generic' => q#Aserbaidschaan Tidj#,
				'standard' => q#Aserbaidschaan Standard Tidj#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Atsooren Somertidj#,
				'generic' => q#Atsooren Tidj#,
				'standard' => q#Atsooren Standard Tidj#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladesch Somertidj#,
				'generic' => q#Bangladesch Tidj#,
				'standard' => q#Bangladesch Standard Tidj#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhuutaan Tidj#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Boliiwien Tidj#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasiilien Somertidj#,
				'generic' => q#Brasiilien Tidj#,
				'standard' => q#Brasiilien Standard Tidj#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei Darussalam Tidj#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kapwerden Sommertidj#,
				'generic' => q#Kapwerden Tidj#,
				'standard' => q#Kapwerden Standard Tidj#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorro Tidj#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatham Somertidj#,
				'generic' => q#Chatham Tidj#,
				'standard' => q#Chatham Standard Tidj#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chiile Somertidj#,
				'generic' => q#Chiile Tidj#,
				'standard' => q#Chiile Standard Tidj#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Schiina Somertidj#,
				'generic' => q#Schiina Tidj#,
				'standard' => q#Schiina Standard Tidj#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Tschoibalsan Somertidj#,
				'generic' => q#Tschoibalsan Tidj#,
				'standard' => q#Tschoibalsan Standard Tidj#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Jul Eilun Tidj#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Cocos Eilunen Tidj#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbien Somertidj#,
				'generic' => q#Kolumbien Tidj#,
				'standard' => q#Kolumbien Standard Tidj#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cook Eilunen Hualew Somertidj#,
				'generic' => q#Cook Eilunen Tidj#,
				'standard' => q#Cook Eilunen Standard Tidj#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kuuba Somertidj#,
				'generic' => q#Kuuba Tidj#,
				'standard' => q#Kuuba Standard Tidj#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis Tidj#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville Tidj#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Uast Tiimor Tidj#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Puask Eilun Somertidj#,
				'generic' => q#Puask Eilun Tidj#,
				'standard' => q#Puask Eilun Standard Tidj#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekwadoor Tidj#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Ufstemet Wäälttidj#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Ünbekäänd steed#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andora#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrachan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atheen#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhuuwen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Iirsk Standard Tidj#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltaar#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Eilun Man#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiew#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisabon#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Britisk Somertidj#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksemborig#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskau#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Pariis#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praag#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riiga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Room#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratow#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanowsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uschhorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Watikaanstääd#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wiin#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warschau#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Saporischja#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Madeleuropeesk Somertidj#,
				'generic' => q#Madeleuropeesk Tidj#,
				'standard' => q#Madeleuropeesk Standard Tidj#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Uasteuropeesk Somertidj#,
				'generic' => q#Uasteuropeesk Tidj#,
				'standard' => q#Uasteuropeesk Standard Tidj#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Faarder Uasteuropeesk Tidj#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Waasteuropeesk Somertidj#,
				'generic' => q#Waasteuropeesk Tidj#,
				'standard' => q#Waasteuropeesk Standard Tidj#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklun Eilunen Somertidj#,
				'generic' => q#Falklun Eilunen Tidj#,
				'standard' => q#Falklun Eilunen Standard Tidj#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fidschi Somertidj#,
				'generic' => q#Fidschi Tidj#,
				'standard' => q#Fidschi Standard Tidj#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Fransöösk Guayaana Tidj#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Fransöösk Süüd an Antarktis Tidj#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Madel Greenwich Tidj#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos Tidj#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambier Tidj#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgien Somertidj#,
				'generic' => q#Georgien Tidj#,
				'standard' => q#Georgien Standard Tidj#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbert Eilunen Tidj#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Uast Greenlun Somertidj#,
				'generic' => q#Uast Greenlun Tidj#,
				'standard' => q#Uast Greenlun Standard Tidj#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Waast Greenlun Somertidj#,
				'generic' => q#Waast Greenlun Tidj#,
				'standard' => q#Waast Greenlun Standard Tidj#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Golf Tidj#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyaana Tidj#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleuten Somertidj#,
				'generic' => q#Hawaii-Aleuten Tidj#,
				'standard' => q#Hawaii-Aleuten Standard Tidj#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hongkong Somertidj#,
				'generic' => q#Hongkong Tidj#,
				'standard' => q#Hongkong Standard Tidj#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Chowd Somertidj#,
				'generic' => q#Chowd Tidj#,
				'standard' => q#Chowd Standard Tidj#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indisk Tidj#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Jul Eilun#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocos Eilunen#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Malediiwen#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indisk Ooseaan Tidj#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indoschiina Tidj#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Sentraal Indoneesien Tidj#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Uast Indoneesien Tidj#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Waast Indoneesien Tidj#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iraan Somertidj#,
				'generic' => q#Iraan Tidj#,
				'standard' => q#Iraan Standard Tidj#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutsk Somertidj#,
				'generic' => q#Irkutsk Tidj#,
				'standard' => q#Irkutsk Standard Tidj#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israel Somertidj#,
				'generic' => q#Israel Tidj#,
				'standard' => q#Israel Standard Tidj#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Jaapan Somertidj#,
				'generic' => q#Jaapan Tidj#,
				'standard' => q#Jaapan Standard Tidj#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Uast Kasachstaan Tidj#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Waast Kasachstaan Tidj#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korea Somertidj#,
				'generic' => q#Korea Tidj#,
				'standard' => q#Korea Standard Tidj#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae Tidj#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarsk Somertidj#,
				'generic' => q#Krasnojarsk Tidj#,
				'standard' => q#Krasnojarsk Standard Tidj#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgistaan Tidj#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Line Eilunen Tidj#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe Somertidj#,
				'generic' => q#Lord Howe Tidj#,
				'standard' => q#Lord Howe Standard Tidj#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquarie Eilun Tidj#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan Somertidj#,
				'generic' => q#Magadan Tidj#,
				'standard' => q#Magadan Standard Tidj#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malaysia Tidj#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Malediiwen Tidj#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marquesas Tidj#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshall Eilunen Tidj#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritius Somertidj#,
				'generic' => q#Mauritius Tidj#,
				'standard' => q#Mauritius Standard Tidj#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson Tidj#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Nuurdwaast Meksiko Somertidj#,
				'generic' => q#Nuurdwaast Meksiko Tidj#,
				'standard' => q#Nuurdwaast Meksiko Standard Tidj#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Meksiko Pasiifik Somertidj#,
				'generic' => q#Meksiko Pasiifik Tidj#,
				'standard' => q#Meksiko Pasiifik Standard Tidj#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulaanbaatar Somertidj#,
				'generic' => q#Ulaanbaatar Tidj#,
				'standard' => q#Ulaanbaatar Standard Tidj#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskau Somertidj#,
				'generic' => q#Moskau Tidj#,
				'standard' => q#Moskau Standard Tidj#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Mjanmaar Tidj#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru Tidj#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Neepaal Tidj#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Neikaledoonien Somertidj#,
				'generic' => q#Neikaledoonien Tidj#,
				'standard' => q#Neikaledoonien Standard Tidj#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Neisialun Somertidj#,
				'generic' => q#Neisialun Tidj#,
				'standard' => q#Neisialun Standard Tidj#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Neifundlun Somertidj#,
				'generic' => q#Neifundlun Tidj#,
				'standard' => q#Neifundlun Standard Tidj#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue Tidj#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolk Eilun Somertidj#,
				'generic' => q#Norfolk Eilun Tidj#,
				'standard' => q#Norfolk Eilun Standard Tidj#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha Somertidj#,
				'generic' => q#Fernando de Noronha Tidj#,
				'standard' => q#Fernando de Noronha Standard Tidj#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Nowosibirsk Somertidj#,
				'generic' => q#Nowosibirsk Tidj#,
				'standard' => q#Nowosibirsk Standard Tidj#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk Somertidj#,
				'generic' => q#Omsk Tidj#,
				'standard' => q#Omsk Standard Tidj#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Puask Eilunen#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidschi#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Norfolk Eilun#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistaan Somertidj#,
				'generic' => q#Pakistaan Tidj#,
				'standard' => q#Pakistaan Standard Tidj#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau Tidj#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua Neiguinea Tidj#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguay Somertidj#,
				'generic' => q#Paraguay Tidj#,
				'standard' => q#Paraguay Standard Tidj#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peruu Somertidj#,
				'generic' => q#Peruu Tidj#,
				'standard' => q#Peruu Standard Tidj#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipiinen Somertidj#,
				'generic' => q#Filipiinen Tidj#,
				'standard' => q#Filipiinen Standard Tidj#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoenix Eilunen Tidj#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#St. Pierre an Miquelon Somertidj#,
				'generic' => q#St. Pierre an Miquelon Tidj#,
				'standard' => q#St. Pierre an Miquelon Standard Tidj#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairn Eilunen Tidj#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape Tidj#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pjöngjang Tidj#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Réunion Tidj#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera Tidj#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sachalin Somertidj#,
				'generic' => q#Sachalin Tidj#,
				'standard' => q#Sachalin Standard Tidj#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa Somertidj#,
				'generic' => q#Samoa Tidj#,
				'standard' => q#Samoa Standard Tidj#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seschelen Tidj#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapuur Tidj#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomoonen Tidj#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Süüdgeorgien Tidj#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Suurinam Tidj#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa Tidj#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti Tidj#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipee Somertidj#,
				'generic' => q#Taipee Tidj#,
				'standard' => q#Taipee Standard Tidj#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadjikistaan Tidj#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau Tidj#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga Somertidj#,
				'generic' => q#Tonga Tidj#,
				'standard' => q#Tonga Standard Tidj#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk Tidj#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmeenistaan Somertidj#,
				'generic' => q#Turkmeenistaan Tidj#,
				'standard' => q#Turkmeenistaan Standard Tidj#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuwaalu Tidj#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguay Somertidj#,
				'generic' => q#Uruguay Tidj#,
				'standard' => q#Uruguay Standard Tidj#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Usbekistaan Somertidj#,
				'generic' => q#Usbekistaan Tidj#,
				'standard' => q#Usbekistaan Standard Tidj#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu Somertidj#,
				'generic' => q#Vanuatu Tidj#,
				'standard' => q#Vanuatu Standard Tidj#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Weenesueela Tidj#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Wladiwostok Somertidj#,
				'generic' => q#Wladiwostok Tidj#,
				'standard' => q#Wladiwostok Standard Tidj#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wolgograd Somertidj#,
				'generic' => q#Wolgograd Tidj#,
				'standard' => q#Wolgograd Standard Tidj#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Wostok Tidj#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wake Eilun Tidj#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis an Futuna Tidj#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutsk Somertidj#,
				'generic' => q#Jakutsk Tidj#,
				'standard' => q#Jakutsk Standard Tidj#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburg Somertidj#,
				'generic' => q#Jekaterinburg Tidj#,
				'standard' => q#Jekaterinburg Standard Tidj#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukon Tidj#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
