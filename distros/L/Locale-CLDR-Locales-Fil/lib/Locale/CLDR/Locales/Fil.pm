=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Fil - Package for language Filipino

=cut

package Locale::CLDR::Locales::Fil;
# This file auto generated from Data\common\main\fil.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-ordinal','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'digits-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ika=#,##0=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ika=#,##0=),
				},
			},
		},
		'number-times' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(isáng),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dalawáng),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tatlóng),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(ápat na),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(limáng),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(anim na),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(pitóng),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(walóng),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(siyám na),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(sampûng),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(labíng-→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%number-times← pû[’t →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%%number-times← daán[ at →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%%number-times← libó[’t →→]),
				},
				'max' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%%number-times← libó[’t →→]),
				},
			},
		},
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(walâ),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← tuldok →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(isá),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dalawá),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tatló),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(ápat),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(limá),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(anim),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(pitó),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(waló),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(siyám),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(sampû),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(labíng-→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%%number-times← pû[’t →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%%number-times← daán[ at →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%%number-times← libó[’t →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%%number-times← milyón[ at →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%%number-times← bilyón[ at →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%%number-times← trilyón[ at →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%number-times← katrilyón[ at →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
			},
		},
		'spellout-ordinal' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ika =%spellout-cardinal=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
			},
		},
    } },
);

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'Afar',
 				'ab' => 'Abkhazian',
 				'ace' => 'Achinese',
 				'ach' => 'Acoli',
 				'ada' => 'Adangme',
 				'ady' => 'Adyghe',
 				'af' => 'Afrikaans',
 				'agq' => 'Aghem',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'ale' => 'Aleut',
 				'alt' => 'Southern Altai',
 				'am' => 'Amharic',
 				'an' => 'Aragonese',
 				'ann' => 'Obolo',
 				'anp' => 'Angika',
 				'ar' => 'Arabic',
 				'ar_001' => 'Modernong Karaniwang Arabic',
 				'arn' => 'Mapuche',
 				'arp' => 'Arapaho',
 				'ars' => 'Najdi Arabic',
 				'as' => 'Assamese',
 				'asa' => 'Asu',
 				'ast' => 'Asturian',
 				'atj' => 'Atikamekw',
 				'av' => 'Avaric',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Azerbaijani',
 				'az@alt=short' => 'Azeri',
 				'ba' => 'Bashkir',
 				'ban' => 'Balinese',
 				'bas' => 'Basaa',
 				'be' => 'Belarusian',
 				'bem' => 'Bemba',
 				'bez' => 'Bena',
 				'bg' => 'Bulgarian',
 				'bgc' => 'Haryanvi',
 				'bgn' => 'Kanlurang Balochi',
 				'bho' => 'Bhojpuri',
 				'bi' => 'Bislama',
 				'bin' => 'Bini',
 				'bla' => 'Siksika',
 				'bm' => 'Bambara',
 				'bn' => 'Bangla',
 				'bo' => 'Tibetan',
 				'br' => 'Breton',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnian',
 				'bug' => 'Buginese',
 				'byn' => 'Blin',
 				'ca' => 'Catalan',
 				'cay' => 'Cayuga',
 				'ccp' => 'Chakma',
 				'ce' => 'Chechen',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Chiga',
 				'ch' => 'Chamorro',
 				'chk' => 'Chuukese',
 				'chm' => 'Mari',
 				'cho' => 'Choctaw',
 				'chp' => 'Chipewyan',
 				'chr' => 'Cherokee',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Central Kurdish',
 				'ckb@alt=menu' => 'Kurdish, Central',
 				'ckb@alt=variant' => 'Kurdish, Sorani',
 				'clc' => 'Chilcotin',
 				'co' => 'Corsican',
 				'crg' => 'Michif',
 				'crj' => 'Southern East Cree',
 				'crk' => 'Plains Cree',
 				'crl' => 'Northern East Cree',
 				'crm' => 'Moose Cree',
 				'crr' => 'Carolina Algonquian',
 				'crs' => 'Seselwa Creole French',
 				'cs' => 'Czech',
 				'csw' => 'Latian na Cree',
 				'cu' => 'Church Slavic',
 				'cv' => 'Chuvash',
 				'cy' => 'Welsh',
 				'da' => 'Danish',
 				'dak' => 'Dakota',
 				'dar' => 'Dargwa',
 				'dav' => 'Taita',
 				'de' => 'German',
 				'de_CH' => 'Swiss High German',
 				'dgr' => 'Dogrib',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Lower Sorbian',
 				'dua' => 'Duala',
 				'dv' => 'Divehi',
 				'dyo' => 'Jola-Fonyi',
 				'dz' => 'Dzongkha',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'eka' => 'Ekajuk',
 				'el' => 'Greek',
 				'en' => 'Ingles',
 				'en_GB@alt=short' => 'Ingles sa UK',
 				'en_US' => 'Ingles (American)',
 				'en_US@alt=short' => 'Ingles sa US',
 				'eo' => 'Esperanto',
 				'es' => 'Spanish',
 				'es_419' => 'Latin American na Espanyol',
 				'es_ES' => 'European Spanish',
 				'es_MX' => 'Mexican na Espanyol',
 				'et' => 'Estonian',
 				'eu' => 'Basque',
 				'ewo' => 'Ewondo',
 				'fa' => 'Persian',
 				'fa_AF' => 'Dari',
 				'ff' => 'Fulah',
 				'fi' => 'Finnish',
 				'fil' => 'Filipino',
 				'fj' => 'Fijian',
 				'fo' => 'Faroese',
 				'fon' => 'Fon',
 				'fr' => 'French',
 				'fr_CH' => 'Swiss na French',
 				'frc' => 'Cajun French',
 				'frr' => 'Hilagang Frisian',
 				'fur' => 'Friulian',
 				'fy' => 'Kanlurang Frisian',
 				'ga' => 'Irish',
 				'gaa' => 'Ga',
 				'gag' => 'Gagauz',
 				'gd' => 'Scottish Gaelic',
 				'gez' => 'Geez',
 				'gil' => 'Gilbertese',
 				'gl' => 'Galician',
 				'gn' => 'Guarani',
 				'gor' => 'Gorontalo',
 				'gsw' => 'Swiss German',
 				'gu' => 'Gujarati',
 				'guz' => 'Gusii',
 				'gv' => 'Manx',
 				'gwi' => 'Gwichʼin',
 				'ha' => 'Hausa',
 				'hai' => 'Haida',
 				'haw' => 'Hawaiian',
 				'hax' => 'Katimugang Haida',
 				'he' => 'Hebrew',
 				'hi' => 'Hindi',
 				'hi_Latn@alt=variant' => 'Hinglish',
 				'hil' => 'Hiligaynon',
 				'hmn' => 'Hmong',
 				'hr' => 'Croatian',
 				'hsb' => 'Upper Sorbian',
 				'ht' => 'Haitian',
 				'hu' => 'Hungarian',
 				'hup' => 'Hupa',
 				'hur' => 'Halkomelem',
 				'hy' => 'Armenian',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Indonesian',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Sichuan Yi',
 				'ikt' => 'Kanlurang Canadian Inuktitut',
 				'ilo' => 'Iloko',
 				'inh' => 'Ingush',
 				'io' => 'Ido',
 				'is' => 'Icelandic',
 				'it' => 'Italian',
 				'iu' => 'Inuktitut',
 				'ja' => 'Japanese',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jv' => 'Javanese',
 				'ka' => 'Georgian',
 				'kab' => 'Kabyle',
 				'kac' => 'Kachin',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kbd' => 'Kabardian',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Kabuverdianu',
 				'kfo' => 'Koro',
 				'kg' => 'Kongo',
 				'kgp' => 'Kaingang',
 				'kha' => 'Khasi',
 				'khq' => 'Koyra Chiini',
 				'ki' => 'Kikuyu',
 				'kj' => 'Kuanyama',
 				'kk' => 'Kazakh',
 				'kkj' => 'Kako',
 				'kl' => 'Kalaallisut',
 				'kln' => 'Kalenjin',
 				'km' => 'Khmer',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada',
 				'ko' => 'Korean',
 				'koi' => 'Komi-Permyak',
 				'kok' => 'Konkani',
 				'kpe' => 'Kpelle',
 				'kr' => 'Kanuri',
 				'krc' => 'Karachay-Balkar',
 				'krl' => 'Karelian',
 				'kru' => 'Kurukh',
 				'ks' => 'Kashmiri',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Colognian',
 				'ku' => 'Kurdish',
 				'kum' => 'Kumyk',
 				'kv' => 'Komi',
 				'kw' => 'Cornish',
 				'kwk' => 'Kwakʼwala',
 				'ky' => 'Kirghiz',
 				'la' => 'Latin',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lb' => 'Luxembourgish',
 				'lez' => 'Lezghian',
 				'lg' => 'Ganda',
 				'li' => 'Limburgish',
 				'lil' => 'Lillooet',
 				'lkt' => 'Lakota',
 				'lmo' => 'Lombard',
 				'ln' => 'Lingala',
 				'lo' => 'Lao',
 				'lou' => 'Louisiana Creole',
 				'loz' => 'Lozi',
 				'lrc' => 'Hilagang Luri',
 				'lsm' => 'Saamia',
 				'lt' => 'Lithuanian',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Mizo',
 				'luy' => 'Luyia',
 				'lv' => 'Latvian',
 				'mad' => 'Madurese',
 				'mag' => 'Magahi',
 				'mai' => 'Maithili',
 				'mak' => 'Makasar',
 				'mas' => 'Masai',
 				'mdf' => 'Moksha',
 				'men' => 'Mende',
 				'mer' => 'Meru',
 				'mfe' => 'Morisyen',
 				'mg' => 'Malagasy',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Meta’',
 				'mh' => 'Marshallese',
 				'mi' => 'Māori',
 				'mic' => 'Micmac',
 				'min' => 'Minangkabau',
 				'mk' => 'Macedonian',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongolian',
 				'mni' => 'Manipuri',
 				'moe' => 'Innu-aimun',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Marathi',
 				'ms' => 'Malay',
 				'mt' => 'Maltese',
 				'mua' => 'Mundang',
 				'mul' => 'Maramihang Wika',
 				'mus' => 'Creek',
 				'mwl' => 'Mirandese',
 				'my' => 'Burmese',
 				'myv' => 'Erzya',
 				'mzn' => 'Mazanderani',
 				'na' => 'Nauru',
 				'nap' => 'Neapolitan',
 				'naq' => 'Nama',
 				'nb' => 'Norwegian Bokmål',
 				'nd' => 'Hilagang Ndebele',
 				'nds' => 'Low German',
 				'nds_NL' => 'Low Saxon',
 				'ne' => 'Nepali',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Niuean',
 				'nl' => 'Dutch',
 				'nl_BE' => 'Flemish',
 				'nmg' => 'Kwasio',
 				'nn' => 'Norwegian Nynorsk',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Norwegian',
 				'nog' => 'Nogai',
 				'nqo' => 'N’Ko',
 				'nr' => 'South Ndebele',
 				'nso' => 'Hilagang Sotho',
 				'nus' => 'Nuer',
 				'nv' => 'Navajo',
 				'ny' => 'Nyanja',
 				'nyn' => 'Nyankole',
 				'oc' => 'Occitan',
 				'ojb' => 'Hilagang-Kanluran ng Ojibwa',
 				'ojc' => 'Central Ojibwa',
 				'ojs' => 'Oji-Cree',
 				'ojw' => 'Kanlurang Ojibwa',
 				'oka' => 'Okanagan',
 				'om' => 'Oromo',
 				'or' => 'Odia',
 				'os' => 'Ossetic',
 				'pa' => 'Punjabi',
 				'pag' => 'Pangasinan',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiamento',
 				'pau' => 'Palauan',
 				'pcm' => 'Nigerian Pidgin',
 				'pis' => 'Pijin',
 				'pl' => 'Polish',
 				'pqm' => 'Maliseet-Passamaquoddy',
 				'prg' => 'Prussian',
 				'ps' => 'Pashto',
 				'ps@alt=variant' => 'Pushto',
 				'pt' => 'Portuguese',
 				'pt_BR' => 'Portuges ng Brasil',
 				'pt_PT' => 'European Portuguese',
 				'qu' => 'Quechua',
 				'quc' => 'Kʼicheʼ',
 				'raj' => 'Rajasthani',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotongan',
 				'rhg' => 'Rohingya',
 				'rm' => 'Romansh',
 				'rn' => 'Rundi',
 				'ro' => 'Romanian',
 				'ro_MD' => 'Moldavian',
 				'rof' => 'Rombo',
 				'ru' => 'Russian',
 				'rup' => 'Aromanian',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskrit',
 				'sad' => 'Sandawe',
 				'sah' => 'Sakha',
 				'saq' => 'Samburu',
 				'sat' => 'Santali',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardinian',
 				'scn' => 'Sicilian',
 				'sco' => 'Scots',
 				'sd' => 'Sindhi',
 				'sdh' => 'Katimugang Kurdish',
 				'se' => 'Hilagang Sami',
 				'seh' => 'Sena',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'sh' => 'Serbo-Croatian',
 				'shi' => 'Tachelhit',
 				'shn' => 'Shan',
 				'si' => 'Sinhala',
 				'sk' => 'Slovak',
 				'sl' => 'Slovenian',
 				'slh' => 'Katimugang Lushootseed',
 				'sm' => 'Samoan',
 				'sma' => 'Katimugang Sami',
 				'smj' => 'Lule Sami',
 				'smn' => 'Inari Sami',
 				'sms' => 'Skolt Sami',
 				'sn' => 'Shona',
 				'snk' => 'Soninke',
 				'so' => 'Somali',
 				'sq' => 'Albanian',
 				'sr' => 'Serbian',
 				'srn' => 'Sranan Tongo',
 				'ss' => 'Swati',
 				'ssy' => 'Saho',
 				'st' => 'Katimugang Sotho',
 				'str' => 'Straits Salish',
 				'su' => 'Sundanese',
 				'suk' => 'Sukuma',
 				'sv' => 'Swedish',
 				'sw' => 'Swahili',
 				'sw_CD' => 'Congo Swahili',
 				'swb' => 'Comorian',
 				'syr' => 'Syriac',
 				'ta' => 'Tamil',
 				'tce' => 'Katimugang Tutchone',
 				'te' => 'Telugu',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'tet' => 'Tetum',
 				'tg' => 'Tajik',
 				'tgx' => 'Tagish',
 				'th' => 'Thai',
 				'tht' => 'Tahltan',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tk' => 'Turkmen',
 				'tl' => 'Tagalog',
 				'tlh' => 'Klingon',
 				'tli' => 'Tlingit',
 				'tn' => 'Tswana',
 				'to' => 'Tongan',
 				'tok' => 'Toki Pona',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Turkish',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tt' => 'Tatar',
 				'ttm' => 'Northern Tutchone',
 				'tum' => 'Tumbuka',
 				'tvl' => 'Tuvalu',
 				'tw' => 'Twi',
 				'twq' => 'Tasawaq',
 				'ty' => 'Tahitian',
 				'tyv' => 'Tuvinian',
 				'tzm' => 'Central Atlas Tamazight',
 				'udm' => 'Udmurt',
 				'ug' => 'Uyghur',
 				'ug@alt=variant' => 'Uighur',
 				'uk' => 'Ukranian',
 				'umb' => 'Umbundu',
 				'und' => 'Hindi Kilalang Wika',
 				'ur' => 'Urdu',
 				'uz' => 'Uzbek',
 				'vai' => 'Vai',
 				've' => 'Venda',
 				'vi' => 'Vietnamese',
 				'vo' => 'Volapük',
 				'vun' => 'Vunjo',
 				'wa' => 'Walloon',
 				'wae' => 'Walser',
 				'wal' => 'Wolaytta',
 				'war' => 'Waray',
 				'wbp' => 'Warlpiri',
 				'wo' => 'Wolof',
 				'wuu' => 'Wu Chinese',
 				'xal' => 'Kalmyk',
 				'xh' => 'Xhosa',
 				'xog' => 'Soga',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Yiddish',
 				'yo' => 'Yoruba',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Cantonese',
 				'yue@alt=menu' => 'Chinese, Cantonese',
 				'zgh' => 'Standard Moroccan Tamazight',
 				'zh' => 'Chinese',
 				'zh@alt=menu' => 'Chinese, Mandarin',
 				'zh_Hans' => 'Pinasimpleng Chinese',
 				'zh_Hans@alt=long' => 'Pinasimpleng Mandarin Chinese',
 				'zh_Hant' => 'Tradisyonal na Chinese',
 				'zh_Hant@alt=long' => 'Tradisyonal na Mandarin Chinese',
 				'zu' => 'Zulu',
 				'zun' => 'Zuni',
 				'zxx' => 'Walang nilalaman na ukol sa wika',
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
 			'Arab' => 'Arabic',
 			'Arab@alt=variant' => 'Perso-Arabic',
 			'Aran' => 'Nastaliq',
 			'Armn' => 'Armenian',
 			'Beng' => 'Bangla',
 			'Bopo' => 'Bopomofo',
 			'Brai' => 'Braille',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Unified Canadian Aboriginal Syllabics',
 			'Cher' => 'Cherokee',
 			'Cyrl' => 'Cyrillic',
 			'Deva' => 'Devanagari',
 			'Ethi' => 'Ethiopic',
 			'Geor' => 'Georgian',
 			'Grek' => 'Greek',
 			'Gujr' => 'Gujarati',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Han na may Bopomofo',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hans' => 'Pinasimple',
 			'Hans@alt=stand-alone' => 'Pinasimpleng Han',
 			'Hant' => 'Tradisyonal',
 			'Hant@alt=stand-alone' => 'Tradisyonal na Han',
 			'Hebr' => 'Hebrew',
 			'Hira' => 'Hiragana',
 			'Hrkt' => 'Japanese syllabaries',
 			'Jamo' => 'Jamo',
 			'Jpan' => 'Japanese',
 			'Kana' => 'Katakana',
 			'Khmr' => 'Khmer',
 			'Knda' => 'Kannada',
 			'Kore' => 'Korean',
 			'Laoo' => 'Lao',
 			'Latn' => 'Latin',
 			'Mlym' => 'Malayalam',
 			'Mong' => 'Mongolian',
 			'Mtei' => 'Meitei Mayek',
 			'Mymr' => 'Myanmar',
 			'Nkoo' => 'N’Ko',
 			'Olck' => 'Ol Chiki',
 			'Orya' => 'Odia',
 			'Rohg' => 'Hanifi',
 			'Sinh' => 'Sinhala',
 			'Sund' => 'Sundanese',
 			'Syrc' => 'Syriac',
 			'Taml' => 'Tamil',
 			'Telu' => 'Telugu',
 			'Tfng' => 'Tifinagh',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thai',
 			'Tibt' => 'Tibetan',
 			'Vaii' => 'Vai',
 			'Yiii' => 'Yi',
 			'Zmth' => 'Mathematical Notation',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Mga Simbolo',
 			'Zxxx' => 'Hindi Nakasulat',
 			'Zyyy' => 'Karaniwan',
 			'Zzzz' => 'Hindi Kilalang Script',

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
			'001' => 'Mundo',
 			'002' => 'Africa',
 			'003' => 'Hilagang Amerika',
 			'005' => 'Timog Amerika',
 			'009' => 'Oceania',
 			'011' => 'Kanlurang Africa',
 			'013' => 'Gitnang Amerika',
 			'014' => 'Silangang Africa',
 			'015' => 'Hilagang Africa',
 			'017' => 'Gitnang Africa',
 			'018' => 'Katimugang Africa',
 			'019' => 'Americas',
 			'021' => 'Northern America',
 			'029' => 'Carribbean',
 			'030' => 'Silangang Asya',
 			'034' => 'Katimugang Asya',
 			'035' => 'Timog-Silangang Asya',
 			'039' => 'Katimugang Europe',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Rehiyon ng Micronesia',
 			'061' => 'Polynesia',
 			'142' => 'Asya',
 			'143' => 'Gitnang Asya',
 			'145' => 'Kanlurang Asya',
 			'150' => 'Europe',
 			'151' => 'Silangang Europe',
 			'154' => 'Hilagang Europe',
 			'155' => 'Kanlurang Europe',
 			'202' => 'Sub-Saharan Africa',
 			'419' => 'Latin America',
 			'AC' => 'Acsencion island',
 			'AD' => 'Andorra',
 			'AE' => 'United Arab Emirates',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua & Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarctica',
 			'AR' => 'Argentina',
 			'AS' => 'American Samoa',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Åland Islands',
 			'AZ' => 'Azerbaijan',
 			'BA' => 'Bosnia and Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgium',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Caribbean Netherlands',
 			'BR' => 'Brazil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvet Island',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Cocos (Keeling) Islands',
 			'CD' => 'Congo - Kinshasa',
 			'CD@alt=variant' => 'Congo (DRC)',
 			'CF' => 'Central African Republic',
 			'CG' => 'Congo - Brazzaville',
 			'CG@alt=variant' => 'Congo (Republika)',
 			'CH' => 'Switzerland',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Ivory Coast',
 			'CK' => 'Cook Islands',
 			'CL' => 'Chile',
 			'CM' => 'Cameroon',
 			'CN' => 'China',
 			'CO' => 'Colombia',
 			'CP' => 'Clipperton Island',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cape Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Christmas Island',
 			'CY' => 'Cyprus',
 			'CZ' => 'Czechia',
 			'CZ@alt=variant' => 'Czech Republic',
 			'DE' => 'Germany',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Denmark',
 			'DM' => 'Dominica',
 			'DO' => 'Dominican Republic',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta & Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egypt',
 			'EH' => 'Kanlurang Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spain',
 			'ET' => 'Ethiopia',
 			'EU' => 'European Union',
 			'EZ' => 'Eurozone',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Falkland Islands',
 			'FK@alt=variant' => 'Falkland Islands (Islas Malvinas)',
 			'FM' => 'Micronesia',
 			'FO' => 'Faroe Islands',
 			'FR' => 'France',
 			'GA' => 'Gabon',
 			'GB' => 'United Kingdom',
 			'GB@alt=short' => 'U.K.',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'French Guiana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Equatorial Guinea',
 			'GR' => 'Greece',
 			'GS' => 'South Georgia & South Sandwich Islands',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong SAR China',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Heard & McDonald Islands',
 			'HN' => 'Honduras',
 			'HR' => 'Croatia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungary',
 			'IC' => 'Canary Islands',
 			'ID' => 'Indonesia',
 			'IE' => 'Ireland',
 			'IL' => 'Israel',
 			'IM' => 'Isle of Man',
 			'IN' => 'India',
 			'IO' => 'Teritoryo sa Karagatan ng British Indian',
 			'IO@alt=chagos' => 'Chagos Archipelago',
 			'IQ' => 'Iraq',
 			'IR' => 'Iran',
 			'IS' => 'Iceland',
 			'IT' => 'Italy',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordan',
 			'JP' => 'Japan',
 			'KE' => 'Kenya',
 			'KG' => 'Kyrgyzstan',
 			'KH' => 'Cambodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoros',
 			'KN' => 'St. Kitts & Nevis',
 			'KP' => 'Hilagang Korea',
 			'KR' => 'Timog Korea',
 			'KW' => 'Kuwait',
 			'KY' => 'Cayman Islands',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Lebanon',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lithuania',
 			'LU' => 'Luxembourg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Morocco',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Marshall Islands',
 			'MK' => 'North Macedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macau SAR China',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Northern Mariana Islands',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldives',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibia',
 			'NC' => 'New Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk Island',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Netherlands',
 			'NO' => 'Norway',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'New Zealand',
 			'NZ@alt=variant' => 'Aotearoa New Zealand',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'French Polynesia',
 			'PG' => 'Papua New Guinea',
 			'PH' => 'Pilipinas',
 			'PK' => 'Pakistan',
 			'PL' => 'Poland',
 			'PM' => 'St. Pierre & Miquelon',
 			'PN' => 'Pitcairn Islands',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestinian Territories',
 			'PS@alt=short' => 'Palestine',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Outlying Oceania',
 			'RE' => 'Réunion',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Russia',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi Arabia',
 			'SB' => 'Solomon Islands',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Sweden',
 			'SG' => 'Singapore',
 			'SH' => 'St. Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard & Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Timog Sudan',
 			'ST' => 'São Tomé & Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syria',
 			'SZ' => 'Swaziland',
 			'TA' => 'Tristan de Cunha',
 			'TC' => 'Turks & Caicos Islands',
 			'TD' => 'Chad',
 			'TF' => 'French Southern Territories',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'East Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Türkiye',
 			'TT' => 'Trinidad & Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraine',
 			'UG' => 'Uganda',
 			'UM' => 'U.S. Outlying Islands',
 			'UN' => 'United Nations',
 			'UN@alt=short' => 'UN',
 			'US' => 'Estados Unidos',
 			'US@alt=short' => 'U.S.',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatican City',
 			'VC' => 'St. Vincent & Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'British Virgin Islands',
 			'VI' => 'U.S. Virgin Islands',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis & Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Mga Pseudo-Accent',
 			'XB' => 'Pseudo-Bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'South Africa',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Hindi Kilalang Rehiyon',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'PINYIN' => 'Pinyin Romanization',
 			'WADEGILE' => 'Wade-Giles Romanization',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kalendaryo',
 			'cf' => 'Format ng Pera',
 			'colalternate' => 'Pag-uuri-uri ng Mga Ignore Symbol',
 			'colbackwards' => 'Pag-uuri-uri ng Baliktad na Accent',
 			'colcasefirst' => 'Uppercase/Lowercase na Pagsusunud-sunod',
 			'colcaselevel' => 'Case Sensitive na Pag-uuri-uri',
 			'collation' => 'Pagkakasunud-sunod ng Ayos',
 			'colnormalization' => 'Normalized na Pag-uuri-uri',
 			'colnumeric' => 'Numeric na Pag-uuri-uri',
 			'colstrength' => 'Lakas ng Pag-uuri-uri',
 			'currency' => 'Pera',
 			'hc' => 'Siklo ng Oras (12 laban sa 24)',
 			'lb' => 'Istilo ng Putol ng Linya',
 			'ms' => 'Sistema ng Pagsukat',
 			'numbers' => 'Mga Numero',
 			'timezone' => 'Time Zone',
 			'va' => 'Lokal na Variant',
 			'x' => 'Pribadong Paggamit',

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
 				'buddhist' => q{Kalendaryo ng Buddhist},
 				'chinese' => q{Kalendaryong Chinese},
 				'coptic' => q{Kalendaryong Coptic},
 				'dangi' => q{Dangi na Kalendaryo},
 				'ethiopic' => q{Kalendaryo ng Ethiopia},
 				'ethiopic-amete-alem' => q{Kalendaryong Ethiopic Amete Alem},
 				'gregorian' => q{Gregorian na Kalendaryo},
 				'hebrew' => q{Hebrew na Kalendaryo},
 				'indian' => q{Pambansang Kalendaryong Indian},
 				'islamic' => q{Kalendaryong Islam},
 				'islamic-civil' => q{Kalendaryong Hijri (tabular, Civil epoch)},
 				'islamic-rgsa' => q{Kalendaryong Islamiko (Saudi Arabia, sighting)},
 				'islamic-tbla' => q{Kalendaryong Islamiko (tabular, astronomikal na epoch)},
 				'islamic-umalqura' => q{Kalendaryong Hijri (Umm al-Qura)},
 				'iso8601' => q{ISO-8601 na Kalendaryo},
 				'japanese' => q{Kalendaryong Japanese},
 				'persian' => q{Kalendaryong Persian},
 				'roc' => q{Kalendaryong Minguo},
 			},
 			'cf' => {
 				'account' => q{Format ng Pera sa Accounting},
 				'standard' => q{Karaniwang Format ng Pera},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Pag-uri-uriin ang Mga Simbolo},
 				'shifted' => q{Pag-uri-uriin ang Mga Ignoring Symbol},
 			},
 			'colbackwards' => {
 				'no' => q{Pag-uri-uriin ang Mga Accent nang Normal},
 				'yes' => q{Pag-uri-uriin ang Mga Accent nang Baliktad},
 			},
 			'colcasefirst' => {
 				'lower' => q{Lowercase Muna ang Pag-uri-uriin},
 				'no' => q{Pag-uri-uriin ang Ayos ng Normal na Case},
 				'upper' => q{Uppercase Muna ang Pag-uri-uriin},
 			},
 			'colcaselevel' => {
 				'no' => q{Pag-uri-uriin ang Hindi Case Sensitive},
 				'yes' => q{Pag-uri-uriin ang Case Sensitive},
 			},
 			'collation' => {
 				'big5han' => q{Pagkakasunod-sunod ng Pag-uuri ng Tradisyunal na Chinese - Big5},
 				'compat' => q{Nakaraang Pagkakasunud-sunod ng Pag-uuri, para sa compatibility},
 				'dictionary' => q{Pagkakasunud-sunod ng Pag-uuri ng Diksyunaryo},
 				'ducet' => q{Default na Pagkakasunud-sunod ng Ayos ng Unicode},
 				'emoji' => q{Pagkakasunud-sunod ng Pag-uuri ng Emoji},
 				'eor' => q{Mga Tuntunin ng European na Pagkakasunud-sunod},
 				'gb2312han' => q{Pagkakasunud-sunod ng Pag-uuri ng Pinasimpleng Chinese - GB2312},
 				'phonebook' => q{Pagkakasunud-sunod ng Pag-uuri ng Phonebook},
 				'phonetic' => q{Phonetic na Ayos ng Pag-uuri-uri},
 				'pinyin' => q{Pagkakasunud-sunod ng Pag-uuri ng Pinyin},
 				'reformed' => q{Pagkakasunud-sunod ng Pag-uuri ng Na-reform},
 				'search' => q{Pangkalahatang Paghahanap},
 				'searchjl' => q{Maghanap Ayon sa Unang Katinig ng Hangul},
 				'standard' => q{Karaniwang Pagkakasunud-sunod ng Ayos},
 				'stroke' => q{Pagkakasunud-sunod ng Pag-uuri ng Stroke},
 				'traditional' => q{Tradisyunal na Pagkakasunud-sunod ng Pag-uuri},
 				'unihan' => q{Pagkakasunud-sunod ng Pag-uuri ng Radical-Stroke},
 				'zhuyin' => q{Zhuyin na Pagkakasunud-sunod ng Pag-uuri},
 			},
 			'colnormalization' => {
 				'no' => q{Pag-uri-uriin nang Walang Pag-normalize},
 				'yes' => q{Pag-uri-uriin ang Unicode nang Normalized},
 			},
 			'colnumeric' => {
 				'no' => q{Pag-uri-uriin ang Mga Digit nang Indibidwal},
 				'yes' => q{Pag-uri-uriin ang Mga Digit nang Numerical},
 			},
 			'colstrength' => {
 				'identical' => q{Pag-uri-uriin Lahat},
 				'primary' => q{Mga Base na Titik Lang ang Pag-uri-uriin},
 				'quaternary' => q{Pag-uri-uriin ang Mga Accent/Case/Lapad/Kana},
 				'secondary' => q{Pag-uri-uriin ang Mga Accent},
 				'tertiary' => q{Pag-uri-uriin ang Mga Accent/Case/Lapad},
 			},
 			'd0' => {
 				'fwidth' => q{Hanggang sa Fullwidth},
 				'hwidth' => q{Hanggang sa Halfwidth},
 				'npinyin' => q{Numeric},
 			},
 			'hc' => {
 				'h11' => q{12 Oras na Sistema (0–11)},
 				'h12' => q{12 Oras na Sistema (1–12)},
 				'h23' => q{24 na Oras na Sistema (0–23)},
 				'h24' => q{24 na Oras na Sistema (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Loose na Istilo ng Line Break},
 				'normal' => q{Normal na Istilo ng Line Break},
 				'strict' => q{Mahigpit na Istilo ng Line Break},
 			},
 			'm0' => {
 				'bgn' => q{US BGN na Transliteration},
 				'ungegn' => q{UN GEGN na Transliteration},
 			},
 			'ms' => {
 				'metric' => q{Metrikong Sistema},
 				'uksystem' => q{Sistemang Imperial na Pagsukat},
 				'ussystem' => q{Sistema ng Pagsukat sa US},
 			},
 			'numbers' => {
 				'ahom' => q{Ahom na mga Digit},
 				'arab' => q{Arabic-Indic na Mga Digit},
 				'arabext' => q{Extendend Arabic-Indic na Mga Digit},
 				'armn' => q{Mga Armenian Numeral},
 				'armnlow' => q{Armenian Lowercase Numerals},
 				'bali' => q{Balinese na Mga Digit},
 				'beng' => q{Mga Bengali Digit},
 				'brah' => q{Brahmi na Mga Digit},
 				'cakm' => q{Mga Digit na Chakma},
 				'cham' => q{Cham na Mga Digit},
 				'cyrl' => q{Cyrillic na Mga Numero},
 				'deva' => q{Mga Devanagari Digit},
 				'ethi' => q{Mga Ethiopic Numeral},
 				'finance' => q{Mga Pampinansyang Numeral},
 				'fullwide' => q{Mga Full-Width Digit},
 				'geor' => q{Georgian na Mga Numeral},
 				'gonm' => q{Masaram Gondi na mga digit},
 				'grek' => q{Greek na Mga Numeral},
 				'greklow' => q{Greek Lowercase na Mga Numeral},
 				'gujr' => q{Mga Gujarati Digit},
 				'guru' => q{Mga Gurmukhi Digit},
 				'hanidec' => q{Mga Chinese Decimal na Numeral},
 				'hans' => q{Simplified Chinese na Mga Numeral},
 				'hansfin' => q{Simplified Chinese na Mga Numeral para sa Pananalapi},
 				'hant' => q{Traditional Chinese na Mga Numeral},
 				'hantfin' => q{Traditional Chinese na Mga Numeral para sa Pananalapi},
 				'hebr' => q{Mga Hebrew Numeral},
 				'hmng' => q{Pahawh Hmong na Mga Digit},
 				'java' => q{Javanese na Mga Digit},
 				'jpan' => q{Mga Japanese Numeral},
 				'jpanfin' => q{Mga Japanese Numeral sa Pananalapi},
 				'kali' => q{Kayah Li na Mga Digit},
 				'khmr' => q{Mga Khmer na Digit},
 				'knda' => q{Mga Kannada na Digit},
 				'lana' => q{Tai Tham Hora na Mga Digit},
 				'lanatham' => q{Tai Tham Tham na Mga Digit},
 				'laoo' => q{Mga Lao na Digit},
 				'latn' => q{Mga Kanluraning Digit},
 				'lepc' => q{Lepcha Mga Digit},
 				'limb' => q{Limbu na Mga Digit},
 				'mathbold' => q{Matematikal na Bold na Mga Digit},
 				'mathdbl' => q{Matematikal na Dobleng-Struck na Mga Digit},
 				'mathmono' => q{Matematikal na Mga Digit na May Isang Puwang},
 				'mathsanb' => q{Matematikal na Sans-Serif Bold na Mga Digit},
 				'mathsans' => q{Matematikal na Sans-Serif na Mga Digit},
 				'mlym' => q{Mga Malayalam na Digit},
 				'modi' => q{Modi na Mga Digit},
 				'mong' => q{Mongolian Digits},
 				'mroo' => q{Mro na Mga Digit},
 				'mtei' => q{Meetei Mayek na Mga Digit},
 				'mymr' => q{Mga Myanmar na Digit},
 				'mymrshan' => q{Maynmar Shan na Mga Digit},
 				'mymrtlng' => q{Myanmar Tai Laing na Mga Digit},
 				'native' => q{Mga Native na Digit},
 				'nkoo' => q{N’Ko na Mga Digit},
 				'olck' => q{Mga Digit ng Ol Chiki},
 				'orya' => q{Mga Oriya na Digit},
 				'roman' => q{Mga Roman Numeral},
 				'romanlow' => q{Roman Lowercase na Mga Numeral},
 				'taml' => q{Tamil na Mga Numeral},
 				'tamldec' => q{Mga Tamil na Digit},
 				'telu' => q{Mga Telugu na Digit},
 				'thai' => q{Mga Thai na Digit},
 				'tibt' => q{Mga Tibetan na Digit},
 				'traditional' => q{Mga Tradisyunal na Numeral},
 				'vaii' => q{Mga Vai na Digit},
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
			'metric' => q{Metriko},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Wika: {0}',
 			'script' => 'Script: {0}',
 			'region' => 'Rehiyon: {0}',

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
			auxiliary => qr{[áàâ éèê íìî óòô úùû]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ñ', '{Ng}', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n ñ {ng} o p q r s t u v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § * / \& # ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ñ', '{Ng}', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
						'name' => q(cardinal direction),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(cardinal direction),
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
						'1' => q(deci{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(deci{0}),
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
						'1' => q(centi{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(centi{0}),
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
					'10p-27' => {
						'1' => q(ronto{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ronto{0}),
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
					'10p-30' => {
						'1' => q(quecto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(quecto{0}),
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
						'1' => q(deka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
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
						'1' => q(hecto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hecto{0}),
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
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(quetta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(quetta{0}),
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
						'one' => q({0} g-force),
						'other' => q({0} g-force),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} g-force),
						'other' => q({0} g-force),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metro kada segundo kwadrado),
						'one' => q({0} metro kada segundo kwadrado),
						'other' => q({0} na metro kada segundo kwadrado),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metro kada segundo kwadrado),
						'one' => q({0} metro kada segundo kwadrado),
						'other' => q({0} na metro kada segundo kwadrado),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arcminutes),
						'one' => q({0} arcminute),
						'other' => q({0} na arcminute),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcminutes),
						'one' => q({0} arcminute),
						'other' => q({0} na arcminute),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcseconds),
						'one' => q({0} arcsecond),
						'other' => q({0} na arcsecond),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcseconds),
						'one' => q({0} arcsecond),
						'other' => q({0} na arcsecond),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} degree),
						'other' => q({0} na degree),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} degree),
						'other' => q({0} na degree),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0} radian),
						'other' => q({0} na radian),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0} radian),
						'other' => q({0} na radian),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(pag-ikot),
						'one' => q({0} pag-ikot),
						'other' => q({0} na pag-ikot),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(pag-ikot),
						'one' => q({0} pag-ikot),
						'other' => q({0} na pag-ikot),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ektarya),
						'one' => q({0} hektarya),
						'other' => q({0} na hektarya),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ektarya),
						'one' => q({0} hektarya),
						'other' => q({0} na hektarya),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(sentimetro kwadrado),
						'one' => q({0} sentimetro kwadrado),
						'other' => q({0} na sentimetro kwadrado),
						'per' => q({0} kada sentimetro kwadrado),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sentimetro kwadrado),
						'one' => q({0} sentimetro kwadrado),
						'other' => q({0} na sentimetro kwadrado),
						'per' => q({0} kada sentimetro kwadrado),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(talampakan parisukat),
						'one' => q({0} talampakan parisukat),
						'other' => q({0} na talampakan parisukat),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(talampakan parisukat),
						'one' => q({0} talampakan parisukat),
						'other' => q({0} na talampakan parisukat),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(pulgada kwadrado),
						'one' => q({0} pulgada kwadrado),
						'other' => q({0} na pulgada kwadrado),
						'per' => q({0} kada pulgada kwadrado),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(pulgada kwadrado),
						'one' => q({0} pulgada kwadrado),
						'other' => q({0} na pulgada kwadrado),
						'per' => q({0} kada pulgada kwadrado),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilometro kwadrado),
						'one' => q({0} kilometro kwadrado),
						'other' => q({0} na kilometro kwadrado),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilometro kwadrado),
						'one' => q({0} kilometro kwadrado),
						'other' => q({0} na kilometro kwadrado),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metro kwadrado),
						'one' => q({0} metro kwadrado),
						'other' => q({0} na metro kwadrado),
						'per' => q({0} kada metro kwadrado),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metro kwadrado),
						'one' => q({0} metro kwadrado),
						'other' => q({0} na metro kwadrado),
						'per' => q({0} kada metro kwadrado),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milya kwadrado),
						'one' => q({0} milya kwadrado),
						'other' => q({0} na milya kwadrado),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milya kwadrado),
						'one' => q({0} milya kwadrado),
						'other' => q({0} na milya kwadrado),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yardang parisukat),
						'one' => q({0} yardang parisukat),
						'other' => q({0} na yardang parisukat),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yardang parisukat),
						'one' => q({0} yardang parisukat),
						'other' => q({0} na yardang parisukat),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(mga item),
						'one' => q({0} item),
						'other' => q({0} na item),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(mga item),
						'one' => q({0} item),
						'other' => q({0} na item),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0} karat),
						'other' => q({0} na karat),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0} karat),
						'other' => q({0} na karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'one' => q({0} milligram per deciliter),
						'other' => q({0} milligrams per deciliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'one' => q({0} milligram per deciliter),
						'other' => q({0} milligrams per deciliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'one' => q({0} millimole per liter),
						'other' => q({0} millimoles per liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'one' => q({0} millimole per liter),
						'other' => q({0} millimoles per liter),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'one' => q({0} mole),
						'other' => q({0} mole),
					},
					# Core Unit Identifier
					'mole' => {
						'one' => q({0} mole),
						'other' => q({0} mole),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(porsyento),
						'one' => q({0} porsyento),
						'other' => q({0} na porsyento),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(porsyento),
						'one' => q({0} porsyento),
						'other' => q({0} na porsyento),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(permille),
						'one' => q({0} permille),
						'other' => q({0} na permille),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(permille),
						'one' => q({0} permille),
						'other' => q({0} na permille),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(parts per million),
						'one' => q({0} part per million),
						'other' => q({0} parts per million),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(parts per million),
						'one' => q({0} part per million),
						'other' => q({0} parts per million),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} permyriad),
						'other' => q({0} permyriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} permyriad),
						'other' => q({0} permyriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litro kada 100 kilometro),
						'one' => q({0} litro kada 100 kilometro),
						'other' => q({0} na litro kada 100 kilometer),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litro kada 100 kilometro),
						'one' => q({0} litro kada 100 kilometro),
						'other' => q({0} na litro kada 100 kilometer),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litro kada kilometro),
						'one' => q({0} litro kada kilometro),
						'other' => q({0} litro kada kilometro),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litro kada kilometro),
						'one' => q({0} litro kada kilometro),
						'other' => q({0} litro kada kilometro),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(milya kada galon),
						'one' => q({0} milya kada galon),
						'other' => q({0} na milya kada galon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(milya kada galon),
						'one' => q({0} milya kada galon),
						'other' => q({0} na milya kada galon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milya kada Imp.gallon),
						'one' => q({0} milya kada Imp.galon),
						'other' => q({0} milya kada Imp. galon),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milya kada Imp.gallon),
						'one' => q({0} milya kada Imp.galon),
						'other' => q({0} milya kada Imp. galon),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} na bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} na bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bytes),
						'one' => q({0} byte),
						'other' => q({0} na byte),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bytes),
						'one' => q({0} byte),
						'other' => q({0} na byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabits),
						'one' => q({0} gigabit),
						'other' => q({0} na gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabits),
						'one' => q({0} gigabit),
						'other' => q({0} na gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabytes),
						'one' => q({0} gigabyte),
						'other' => q({0} na gigabyte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabytes),
						'one' => q({0} gigabyte),
						'other' => q({0} na gigabyte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobits),
						'one' => q({0} kilobit),
						'other' => q({0} na kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobits),
						'one' => q({0} kilobit),
						'other' => q({0} na kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobytes),
						'one' => q({0} kilobyte),
						'other' => q({0} na kilobyte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobytes),
						'one' => q({0} kilobyte),
						'other' => q({0} na kilobyte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabits),
						'one' => q({0} megabit),
						'other' => q({0} na megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabits),
						'one' => q({0} megabit),
						'other' => q({0} na megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabytes),
						'one' => q({0} megabyte),
						'other' => q({0} na megabyte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabytes),
						'one' => q({0} megabyte),
						'other' => q({0} na megabyte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabytes),
						'one' => q({0} petabyte),
						'other' => q({0} petabytes),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabytes),
						'one' => q({0} petabyte),
						'other' => q({0} petabytes),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabits),
						'one' => q({0} terabit),
						'other' => q({0} na terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabits),
						'one' => q({0} terabit),
						'other' => q({0} na terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabytes),
						'one' => q({0} terabyte),
						'other' => q({0} na terabyte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabytes),
						'one' => q({0} terabyte),
						'other' => q({0} na terabyte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(mga siglo),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(mga siglo),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0} araw),
						'other' => q({0} na araw),
						'per' => q({0} kada araw),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} araw),
						'other' => q({0} na araw),
						'per' => q({0} kada araw),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dekada),
						'one' => q({0} dekada),
						'other' => q({0} dekada),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dekada),
						'one' => q({0} dekada),
						'other' => q({0} dekada),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(mga oras),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(mga oras),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosegundo),
						'one' => q({0} mikrosegundo),
						'other' => q({0} mikrosegundo),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosegundo),
						'one' => q({0} mikrosegundo),
						'other' => q({0} mikrosegundo),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisegundo),
						'one' => q({0} milisegundo),
						'other' => q({0} milisegundo),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisegundo),
						'one' => q({0} milisegundo),
						'other' => q({0} milisegundo),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(mga minuto),
						'one' => q({0} minuto),
						'other' => q({0} na minuto),
						'per' => q({0} kada minuto),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(mga minuto),
						'one' => q({0} minuto),
						'other' => q({0} na minuto),
						'per' => q({0} kada minuto),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mga buwan),
						'per' => q({0} kada buwan),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mga buwan),
						'per' => q({0} kada buwan),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosegundo),
						'one' => q({0} nanosegundo),
						'other' => q({0} nanosegundo),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosegundo),
						'one' => q({0} nanosegundo),
						'other' => q({0} nanosegundo),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(mga quarter),
						'one' => q({0} qtr),
						'other' => q({0} qaurter),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(mga quarter),
						'one' => q({0} qtr),
						'other' => q({0} qaurter),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(mga segundo),
						'one' => q({0} segundo),
						'other' => q({0} na segundo),
						'per' => q({0} kada segundo),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(mga segundo),
						'one' => q({0} segundo),
						'other' => q({0} na segundo),
						'per' => q({0} kada segundo),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(mga linggo),
						'per' => q({0} kada linggo),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(mga linggo),
						'per' => q({0} kada linggo),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(mga taon),
						'one' => q({0} taon),
						'other' => q({0} na taon),
						'per' => q({0} kada taon),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(mga taon),
						'one' => q({0} taon),
						'other' => q({0} na taon),
						'per' => q({0} kada taon),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amperes),
						'one' => q({0} ampere),
						'other' => q({0} na ampere),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amperes),
						'one' => q({0} ampere),
						'other' => q({0} na ampere),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliamperes),
						'one' => q({0} milliampere),
						'other' => q({0} na milliampere),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliamperes),
						'one' => q({0} milliampere),
						'other' => q({0} na milliampere),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0} ohm),
						'other' => q({0} na ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0} ohm),
						'other' => q({0} na ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0} volt),
						'other' => q({0} na volt),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0} volt),
						'other' => q({0} na volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(British thermal unit),
						'one' => q({0} British thermal unit),
						'other' => q({0} British thermal unit),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(British thermal unit),
						'one' => q({0} British thermal unit),
						'other' => q({0} British thermal unit),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(calories),
						'one' => q({0} calorie),
						'other' => q({0} na calories),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(calories),
						'one' => q({0} calorie),
						'other' => q({0} na calories),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'one' => q({0} electronvolt),
						'other' => q({0} electronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'one' => q({0} electronvolt),
						'other' => q({0} electronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Mga calorie),
						'one' => q({0} Calorie),
						'other' => q({0} Calorie),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Mga calorie),
						'one' => q({0} Calorie),
						'other' => q({0} Calorie),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0} joule),
						'other' => q({0} na joules),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0} joule),
						'other' => q({0} na joules),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilocalories),
						'one' => q({0} kilocalorie),
						'other' => q({0} na kilocalorie),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilocalories),
						'one' => q({0} kilocalorie),
						'other' => q({0} na kilocalorie),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoules),
						'one' => q({0} kilojoule),
						'other' => q({0} na kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoules),
						'one' => q({0} kilojoule),
						'other' => q({0} na kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowatt-hours),
						'one' => q({0} kilowatt hour),
						'other' => q({0} na kilowatt-hour),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowatt-hours),
						'one' => q({0} kilowatt hour),
						'other' => q({0} na kilowatt-hour),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-hour bawat 100 kilometro),
						'one' => q({0} kilowatt-hour bawat 100 kilometro),
						'other' => q({0} kilowatt-hours bawat 100 kilometro),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-hour bawat 100 kilometro),
						'one' => q({0} kilowatt-hour bawat 100 kilometro),
						'other' => q({0} kilowatt-hours bawat 100 kilometro),
					},
					# Long Unit Identifier
					'force-newton' => {
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pound of force),
						'one' => q({0} pound of force),
						'other' => q({0} pound of force),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pound of force),
						'one' => q({0} pound of force),
						'other' => q({0} pound of force),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} na gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} na gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} na hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} na hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} na kilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} na kilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} na megahertz),
						'other' => q({0} megahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} na megahertz),
						'other' => q({0} megahertz),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(tuldok bawat sentimetro),
						'one' => q({0} tuldok bawat sentimetro),
						'other' => q({0} tuldok bawat sentimetro),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(tuldok bawat sentimetro),
						'one' => q({0} tuldok bawat sentimetro),
						'other' => q({0} tuldok bawat sentimetro),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(tuldok bawat pulgada),
						'one' => q({0} tuldok bawat pulgada),
						'other' => q({0} tuldok bawat pulgada),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(tuldok bawat pulgada),
						'one' => q({0} tuldok bawat pulgada),
						'other' => q({0} tuldok bawat pulgada),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(tipograpikang em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(tipograpikang em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixels),
						'one' => q({0} megapixel),
						'other' => q({0} megapixels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixels),
						'one' => q({0} megapixel),
						'other' => q({0} megapixels),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0} pixel),
						'other' => q({0} pixel),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0} pixel),
						'other' => q({0} pixel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(mga pixel bawat sentimetro),
						'one' => q({0} pixel bawat sentimetro),
						'other' => q({0} pixel bawat sentimetro),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(mga pixel bawat sentimetro),
						'one' => q({0} pixel bawat sentimetro),
						'other' => q({0} pixel bawat sentimetro),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(mga pixel bawat pulgada),
						'one' => q({0} pixel bawat pulgada),
						'other' => q({0} pixel bawat pulgada),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(mga pixel bawat pulgada),
						'one' => q({0} pixel bawat pulgada),
						'other' => q({0} pixel bawat pulgada),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronomical units),
						'one' => q({0} astronomical unit),
						'other' => q({0} na astronomical units),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronomical units),
						'one' => q({0} astronomical unit),
						'other' => q({0} na astronomical units),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sentimetro),
						'one' => q({0} sentimetro),
						'other' => q({0} sentimetro),
						'per' => q({0} kada sentimetro),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sentimetro),
						'one' => q({0} sentimetro),
						'other' => q({0} sentimetro),
						'per' => q({0} kada sentimetro),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(decimetro),
						'one' => q({0} decimetro),
						'other' => q({0} na decimetro),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(decimetro),
						'one' => q({0} decimetro),
						'other' => q({0} na decimetro),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(earth radius),
						'one' => q({0} earth radius),
						'other' => q({0} na earth radius),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(earth radius),
						'one' => q({0} earth radius),
						'other' => q({0} na earth radius),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0} fathom),
						'other' => q({0} na fathom),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} fathom),
						'other' => q({0} na fathom),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} talampakan),
						'other' => q({0} na talampakan),
						'per' => q({0} kada talampakan),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} talampakan),
						'other' => q({0} na talampakan),
						'per' => q({0} kada talampakan),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} na furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} na furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} pulgada),
						'other' => q({0} na pulgada),
						'per' => q({0} kada pulgada),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} pulgada),
						'other' => q({0} na pulgada),
						'per' => q({0} kada pulgada),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometro),
						'one' => q({0} kilometro),
						'other' => q({0} na kilometro),
						'per' => q({0} kada kilometro),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometro),
						'one' => q({0} kilometro),
						'other' => q({0} na kilometro),
						'per' => q({0} kada kilometro),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(light year),
						'one' => q({0} light year),
						'other' => q({0} na light year),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(light year),
						'one' => q({0} light year),
						'other' => q({0} na light year),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0} metro),
						'other' => q({0} na metro),
						'per' => q({0} kada metro),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0} metro),
						'other' => q({0} na metro),
						'per' => q({0} kada metro),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(micrometro),
						'one' => q({0} micrometro),
						'other' => q({0} micrometro),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(micrometro),
						'one' => q({0} micrometro),
						'other' => q({0} micrometro),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} milya),
						'other' => q({0} na milya),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} milya),
						'other' => q({0} na milya),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(milya-scandinavian),
						'one' => q({0} milya-scandinavian),
						'other' => q({0} na milya-scandinavian),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(milya-scandinavian),
						'one' => q({0} milya-scandinavian),
						'other' => q({0} na milya-scandinavian),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimetro),
						'one' => q({0} milimetro),
						'other' => q({0} na milimetro),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimetro),
						'one' => q({0} milimetro),
						'other' => q({0} na milimetro),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometro),
						'one' => q({0} nanometro),
						'other' => q({0} nanometro),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometro),
						'one' => q({0} nanometro),
						'other' => q({0} nanometro),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(nautical miles),
						'one' => q({0} nautical mile),
						'other' => q({0} nautical miles),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(nautical miles),
						'one' => q({0} nautical mile),
						'other' => q({0} nautical miles),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(picometer),
						'one' => q({0} picometer),
						'other' => q({0} picometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(picometer),
						'one' => q({0} picometer),
						'other' => q({0} picometer),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q({0} puntos),
						'other' => q({0} puntos),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q({0} puntos),
						'other' => q({0} puntos),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} solar radius),
						'other' => q({0} solar radii),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} solar radius),
						'other' => q({0} solar radii),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} yarda),
						'other' => q({0} na yarda),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} yarda),
						'other' => q({0} na yarda),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candela),
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
						'one' => q({0} lux),
						'other' => q({0} na lux),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0} lux),
						'other' => q({0} na lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0} solar luminosity),
						'other' => q({0} solar luminosity),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} solar luminosity),
						'other' => q({0} solar luminosity),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q({0} Earth mass),
						'other' => q({0} Earth mass),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} Earth mass),
						'other' => q({0} Earth mass),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} gramo),
						'other' => q({0} na gramo),
						'per' => q({0} kada gramo),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} gramo),
						'other' => q({0} na gramo),
						'per' => q({0} kada gramo),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilo),
						'one' => q({0} kilo),
						'other' => q({0} kilo),
						'per' => q({0} kada kilo),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilo),
						'one' => q({0} kilo),
						'other' => q({0} kilo),
						'per' => q({0} kada kilo),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(micrograms),
						'one' => q({0} microgram),
						'other' => q({0} micrograms),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(micrograms),
						'one' => q({0} microgram),
						'other' => q({0} micrograms),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(milligrams),
						'one' => q({0} milligram),
						'other' => q({0} milligrams),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(milligrams),
						'one' => q({0} milligram),
						'other' => q({0} milligrams),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(onsa),
						'one' => q({0} onsa),
						'other' => q({0} na onsa),
						'per' => q({0} kada onsa),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(onsa),
						'one' => q({0} onsa),
						'other' => q({0} na onsa),
						'per' => q({0} kada onsa),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy na onsa),
						'one' => q({0} troy na onsa),
						'other' => q({0} na troy na onsa),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy na onsa),
						'one' => q({0} troy na onsa),
						'other' => q({0} na troy na onsa),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} libra),
						'other' => q({0} na libra),
						'per' => q({0} kada libra),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} libra),
						'other' => q({0} na libra),
						'per' => q({0} kada libra),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} solar mass),
						'other' => q({0} solar mass),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} solar mass),
						'other' => q({0} solar mass),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} tonelada),
						'other' => q({0} tonelada),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} tonelada),
						'other' => q({0} tonelada),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(mga metriko tonelada),
						'one' => q({0} metriko tonelada),
						'other' => q({0} metriko tonelada),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(mga metriko tonelada),
						'one' => q({0} metriko tonelada),
						'other' => q({0} metriko tonelada),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} kada {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} kada {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawatts),
						'one' => q({0} gigawatt),
						'other' => q({0} na gigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawatts),
						'one' => q({0} gigawatt),
						'other' => q({0} na gigawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(horsepower),
						'one' => q({0} horsepower),
						'other' => q({0} horsepower),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(horsepower),
						'one' => q({0} horsepower),
						'other' => q({0} horsepower),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowatts),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatts),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowatts),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatts),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawatts),
						'one' => q({0} megawatt),
						'other' => q({0} na megawatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawatts),
						'one' => q({0} megawatt),
						'other' => q({0} na megawatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(milliwatts),
						'one' => q({0} milliwatt),
						'other' => q({0} na milliwatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(milliwatts),
						'one' => q({0} milliwatt),
						'other' => q({0} na milliwatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0} watt),
						'other' => q({0} na watt),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} watt),
						'other' => q({0} na watt),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(square {0}),
						'one' => q({0} kuwadrado),
						'other' => q({0} kuwadrado),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(square {0}),
						'one' => q({0} kuwadrado),
						'other' => q({0} kuwadrado),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(cubic {0}),
						'one' => q(cubic na {0}),
						'other' => q(cubic {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(cubic {0}),
						'one' => q(cubic na {0}),
						'other' => q(cubic {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmospheres),
						'one' => q({0} atmosphere),
						'other' => q({0} atmospheres),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmospheres),
						'one' => q({0} atmosphere),
						'other' => q({0} atmospheres),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hectopascals),
						'one' => q({0} hectopascal),
						'other' => q({0} na hectopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hectopascals),
						'one' => q({0} hectopascal),
						'other' => q({0} na hectopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(pulgada ng asoge),
						'one' => q({0} pulgada ng asoge),
						'other' => q({0} na pulgada ng asoge),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(pulgada ng asoge),
						'one' => q({0} pulgada ng asoge),
						'other' => q({0} na pulgada ng asoge),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopascal),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopascal),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascal),
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
						'other' => q({0} na millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} na millibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milimetro ng asoge),
						'one' => q({0} milimetro ng asoge),
						'other' => q({0} na milimetro ng asoge),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milimetro ng asoge),
						'one' => q({0} milimetro ng asoge),
						'other' => q({0} na milimetro ng asoge),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(pascal),
						'one' => q({0} pascal),
						'other' => q({0} pascals),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(pascal),
						'one' => q({0} pascal),
						'other' => q({0} pascals),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(libra kada pulgadang parisukat),
						'one' => q({0} libra kada pulgadang parisukat),
						'other' => q({0} na libra kada pulgadang parisukat),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(libra kada pulgadang parisukat),
						'one' => q({0} libra kada pulgadang parisukat),
						'other' => q({0} na libra kada pulgadang parisukat),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometro kada oras),
						'one' => q({0} kilometro kada oras),
						'other' => q({0} na kilometro kada oras),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometro kada oras),
						'one' => q({0} kilometro kada oras),
						'other' => q({0} na kilometro kada oras),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(knot),
						'one' => q({0} knot),
						'other' => q({0} na knot),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(knot),
						'one' => q({0} knot),
						'other' => q({0} na knot),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metro kada segundo),
						'one' => q({0} metro kada segundo),
						'other' => q({0} metro kada segundo),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metro kada segundo),
						'one' => q({0} metro kada segundo),
						'other' => q({0} metro kada segundo),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milya kada oras),
						'one' => q({0} milya kada oras),
						'other' => q({0} milya kada oras),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milya kada oras),
						'one' => q({0} milya kada oras),
						'other' => q({0} milya kada oras),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(degrees Celsius),
						'one' => q({0} degree Celsius),
						'other' => q({0} degrees Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(degrees Celsius),
						'one' => q({0} degree Celsius),
						'other' => q({0} degrees Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(degrees Fahrenheit),
						'one' => q({0} degree Fahrenheit),
						'other' => q({0} degrees Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(degrees Fahrenheit),
						'one' => q({0} degree Fahrenheit),
						'other' => q({0} degrees Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(degrees kelvin),
						'one' => q({0} degree kelvin),
						'other' => q({0} degrees kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(degrees kelvin),
						'one' => q({0} degree kelvin),
						'other' => q({0} degrees kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newton-meter),
						'one' => q({0} newton-meter),
						'other' => q({0} newton-meter),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton-meter),
						'one' => q({0} newton-meter),
						'other' => q({0} newton-meter),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pound-feet),
						'one' => q({0} pound-force-foot),
						'other' => q({0} pound-feet),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pound-feet),
						'one' => q({0} pound-force-foot),
						'other' => q({0} pound-feet),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre-feet),
						'one' => q({0} acre-foot),
						'other' => q({0} acre-feet),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre-feet),
						'one' => q({0} acre-foot),
						'other' => q({0} acre-feet),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q({0} bariles),
						'other' => q({0} bariles),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q({0} bariles),
						'other' => q({0} bariles),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} bushel),
						'other' => q({0} mga bushel),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0} bushel),
						'other' => q({0} mga bushel),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sentilitro),
						'one' => q({0} sentilitro),
						'other' => q({0} sentilitro),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sentilitro),
						'one' => q({0} sentilitro),
						'other' => q({0} sentilitro),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(kubiko sentimetro),
						'one' => q({0} kubiko sentimetro),
						'other' => q({0} na sentimetro kubiko),
						'per' => q({0} kada sentimetro kubiko),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(kubiko sentimetro),
						'one' => q({0} kubiko sentimetro),
						'other' => q({0} na sentimetro kubiko),
						'per' => q({0} kada sentimetro kubiko),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kubiko talampakan),
						'one' => q({0} kubiko talampakan),
						'other' => q({0} kubiko talampakan),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kubiko talampakan),
						'one' => q({0} kubiko talampakan),
						'other' => q({0} kubiko talampakan),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(kubiko pulgada),
						'one' => q({0} kubiko pulgada),
						'other' => q({0} kubiko pulgada),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(kubiko pulgada),
						'one' => q({0} kubiko pulgada),
						'other' => q({0} kubiko pulgada),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kubiko kilometro),
						'one' => q({0} kubiko kilometro),
						'other' => q({0} kubiko kilometro),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kubiko kilometro),
						'one' => q({0} kubiko kilometro),
						'other' => q({0} kubiko kilometro),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(kubiko metro),
						'one' => q({0} kubiko metro),
						'other' => q({0} na metro kubiko),
						'per' => q({0} kada metro kubiko),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(kubiko metro),
						'one' => q({0} kubiko metro),
						'other' => q({0} na metro kubiko),
						'per' => q({0} kada metro kubiko),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(kubiko milya),
						'one' => q({0} kubiko milya),
						'other' => q({0} kubiko milya),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(kubiko milya),
						'one' => q({0} kubiko milya),
						'other' => q({0} kubiko milya),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(kubiko yarda),
						'one' => q({0} kubiko yarda),
						'other' => q({0} kubiko yarda),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(kubiko yarda),
						'one' => q({0} kubiko yarda),
						'other' => q({0} kubiko yarda),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0} tasa),
						'other' => q({0} na tasa),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0} tasa),
						'other' => q({0} na tasa),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(metric cups),
						'one' => q({0} metric cup),
						'other' => q({0} na metric cup),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(metric cups),
						'one' => q({0} metric cup),
						'other' => q({0} na metric cup),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(decilitro),
						'one' => q({0} decilitro),
						'other' => q({0} na decilitro),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(decilitro),
						'one' => q({0} decilitro),
						'other' => q({0} na decilitro),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(kutsarang panghimagas),
						'one' => q({0} kutsarang panghimagas),
						'other' => q({0} kutsarang panghimagas),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(kutsarang panghimagas),
						'one' => q({0} kutsarang panghimagas),
						'other' => q({0} kutsarang panghimagas),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Imp. na kutsarang panghimagas),
						'one' => q({0} Imp. na kutsarang panghimagas),
						'other' => q({0} Imp. na kutsarang panghimagas),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Imp. na kutsarang panghimagas),
						'one' => q({0} Imp. na kutsarang panghimagas),
						'other' => q({0} Imp. na kutsarang panghimagas),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram),
						'one' => q({0} dram),
						'other' => q({0} dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram),
						'one' => q({0} dram),
						'other' => q({0} dram),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fluid ounces),
						'one' => q({0} fluid ounce),
						'other' => q({0} na fluid ounce),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fluid ounces),
						'one' => q({0} fluid ounce),
						'other' => q({0} na fluid ounce),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. fluid ounce),
						'one' => q({0} Imp. fluid ounce),
						'other' => q({0} Imp. fluid ounce),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. fluid ounce),
						'one' => q({0} Imp. fluid ounce),
						'other' => q({0} Imp. fluid ounce),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galon),
						'one' => q({0} galon),
						'other' => q({0} na galon),
						'per' => q({0} kada galon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galon),
						'one' => q({0} galon),
						'other' => q({0} na galon),
						'per' => q({0} kada galon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'per' => q({0} kada Imp. galon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'per' => q({0} kada Imp. galon),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektolitro),
						'one' => q({0} hektolitro),
						'other' => q({0} hektolitro),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektolitro),
						'one' => q({0} hektolitro),
						'other' => q({0} hektolitro),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} litro),
						'other' => q({0} na litro),
						'per' => q({0} kada litro),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} litro),
						'other' => q({0} na litro),
						'per' => q({0} kada litro),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitro),
						'one' => q({0} megalitro),
						'other' => q({0} megalitro),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitro),
						'one' => q({0} megalitro),
						'other' => q({0} megalitro),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililitro),
						'one' => q({0} mililitro),
						'other' => q({0} mililitro),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililitro),
						'one' => q({0} mililitro),
						'other' => q({0} mililitro),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'one' => q({0} pint),
						'other' => q({0} pints),
					},
					# Core Unit Identifier
					'pint' => {
						'one' => q({0} pint),
						'other' => q({0} pints),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(metric pints),
						'one' => q({0} metric pint),
						'other' => q({0} na metric pint),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(metric pints),
						'one' => q({0} metric pint),
						'other' => q({0} na metric pint),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(quarts),
						'one' => q({0} quart),
						'other' => q({0} na quarts),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(quarts),
						'one' => q({0} quart),
						'other' => q({0} na quarts),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp. na kuwart),
						'one' => q({0} Imp. na kuwart),
						'other' => q({0} Imp. na kuwart),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp. na kuwart),
						'one' => q({0} Imp. na kuwart),
						'other' => q({0} Imp. na kuwart),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(kutsara),
						'one' => q({0} kutsara),
						'other' => q({0} kutsara),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(kutsara),
						'one' => q({0} kutsara),
						'other' => q({0} kutsara),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(kutsarita),
						'one' => q({0} kutsarita),
						'other' => q({0} kutsarita),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(kutsarita),
						'one' => q({0} kutsarita),
						'other' => q({0} kutsarita),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(deg),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(deg),
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
					'area-acre' => {
						'name' => q(ektarya),
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ektarya),
						'one' => q({0}ac),
						'other' => q({0}ac),
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
						'per' => q({0}/cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'per' => q({0}/cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(in²),
						'per' => q({0}/in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(in²),
						'per' => q({0}/in²),
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
					'area-square-mile' => {
						'name' => q(mi²),
						'one' => q({0}mi²),
						'other' => q({0}mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0}mi²),
						'other' => q({0}mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'one' => q({0} item),
						'other' => q({0}item),
					},
					# Core Unit Identifier
					'item' => {
						'one' => q({0} item),
						'other' => q({0}item),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mol),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mol),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(L/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0}mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0}mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
						'one' => q({0}mpg),
						'other' => q({0}mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
						'one' => q({0}mpg),
						'other' => q({0}mpg),
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
					'digital-gigabit' => {
						'name' => q(Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0} araw),
						'other' => q({0} na araw),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} araw),
						'other' => q({0} na araw),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} oras),
						'other' => q({0} oras),
						'per' => q({0}/oras),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} oras),
						'other' => q({0} oras),
						'per' => q({0}/oras),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(mseg),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(mseg),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0}buwan),
						'other' => q({0} buwan),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0}buwan),
						'other' => q({0} buwan),
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
						'one' => q({0}linggo),
						'other' => q({0}linggo),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0}linggo),
						'other' => q({0}linggo),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0}taon),
						'other' => q({0}taon),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0}taon),
						'other' => q({0}taon),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mA),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(eV),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kWh),
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
						'name' => q(N),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(lbf),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(tuldok),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(tuldok),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(px),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(px),
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
					'length-fathom' => {
						'name' => q(fathom),
						'one' => q({0}fth),
						'other' => q({0}fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathom),
						'one' => q({0}fth),
						'other' => q({0}fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(in),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(in),
						'one' => q({0}″),
						'other' => q({0}″),
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
						'name' => q(ly),
						'one' => q({0}ly),
						'other' => q({0}ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ly),
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
					'length-mile' => {
						'name' => q(mi),
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mi),
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
						'name' => q(pts),
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pts),
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yd),
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0}CD),
						'other' => q({0}CD),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0}CD),
						'other' => q({0}CD),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(M⊕),
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
						'one' => q({0}#),
						'other' => q({0}#),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0}#),
						'other' => q({0}#),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone),
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(ton),
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ton),
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
					'power-watt' => {
						'name' => q(watt),
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watt),
						'one' => q({0}W),
						'other' => q({0}W),
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
						'name' => q(″ Hg),
						'one' => q({0}" Hg),
						'other' => q({0}" Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q({0}" Hg),
						'other' => q({0}" Hg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0}mb),
						'other' => q({0}mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0}mb),
						'other' => q({0}mb),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
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
						'one' => q({0}kph),
						'other' => q({0}kph),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0}kph),
						'other' => q({0}kph),
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
						'name' => q(mi/hr),
						'one' => q({0}mph),
						'other' => q({0}mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mi/hr),
						'one' => q({0}mph),
						'other' => q({0}mph),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(⁰C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(⁰C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(K),
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(K),
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bbl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushel),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(in³),
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
						'name' => q(yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yd³),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(kutsaritang panghimagas),
						'one' => q({0} dsp),
						'other' => q({0} dsp),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(kutsaritang panghimagas),
						'one' => q({0} dsp),
						'other' => q({0} dsp),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dsp lmp),
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dsp lmp),
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl.dr.),
						'one' => q({0}fl.dr.),
						'other' => q({0}fl.dr.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl.dr.),
						'one' => q({0}fl.dr.),
						'other' => q({0}fl.dr.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'one' => q({0} jigger),
						'other' => q({0}jigger),
					},
					# Core Unit Identifier
					'jigger' => {
						'one' => q({0} jigger),
						'other' => q({0}jigger),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(kurot),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(kurot),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt Imp),
						'one' => q({0} qt Imp.),
						'other' => q({0}qt-Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt Imp),
						'one' => q({0} qt Imp.),
						'other' => q({0}qt-Imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(kutsara),
						'one' => q({0} kutsara),
						'other' => q({0} kutsara),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(kutsara),
						'one' => q({0} kutsara),
						'other' => q({0} kutsara),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(kutsarita),
						'one' => q({0} kutsarita),
						'other' => q({0} kutsarita),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(kutsarita),
						'one' => q({0} kutsarita),
						'other' => q({0} kutsarita),
					},
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metro/segundo²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metro/segundo²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arcmins),
						'one' => q({0} arcmin),
						'other' => q({0} na arcmin),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcmins),
						'one' => q({0} arcmin),
						'other' => q({0} na arcmin),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcsecs),
						'one' => q({0} arcsec),
						'other' => q({0} na arcsec),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcsecs),
						'one' => q({0} arcsec),
						'other' => q({0} na arcsec),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(degrees),
						'one' => q({0} deg),
						'other' => q({0} na deg),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(degrees),
						'one' => q({0} deg),
						'other' => q({0} na deg),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radians),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radians),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q({0} rev),
						'other' => q({0} na rev),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0} rev),
						'other' => q({0} na rev),
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
						'name' => q(hektarya),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektarya),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'per' => q({0} kada cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'per' => q({0} kada cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(sq feet),
						'one' => q({0} sq ft),
						'other' => q({0} sq ft),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(sq feet),
						'one' => q({0} sq ft),
						'other' => q({0} sq ft),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(pulgada²),
						'per' => q({0} kada in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(pulgada²),
						'per' => q({0} kada in²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metro²),
						'per' => q({0} kada m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metro²),
						'per' => q({0} kada m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(sq mile),
						'one' => q({0} sq mi),
						'other' => q({0} sq mi),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(sq mile),
						'one' => q({0} sq mi),
						'other' => q({0} sq mi),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yarda²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yarda²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mole),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mole),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(parts/million),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(parts/million),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(permyriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(permyriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'one' => q({0} na L/100km),
						'other' => q({0} na L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'one' => q({0} na L/100km),
						'other' => q({0} na L/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litro/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litro/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(milya/gal),
						'one' => q({0} mpg),
						'other' => q({0} na mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(milya/gal),
						'one' => q({0} mpg),
						'other' => q({0} na mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milya/gal Imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milya/gal Imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}S),
						'north' => q({0}H),
						'south' => q({0}T),
						'west' => q({0}K),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}S),
						'north' => q({0}H),
						'south' => q({0}T),
						'west' => q({0}K),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GByte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GByte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kByte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kByte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MByte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MByte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PByte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PByte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TByte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TByte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(siglo),
						'one' => q({0} siglo),
						'other' => q({0} siglo),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(siglo),
						'one' => q({0} siglo),
						'other' => q({0} siglo),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(araw),
						'one' => q({0} araw),
						'other' => q({0} araw),
						'per' => q({0}/araw),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(araw),
						'one' => q({0} araw),
						'other' => q({0} araw),
						'per' => q({0}/araw),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(oras),
						'one' => q({0} oras),
						'other' => q({0} na oras),
						'per' => q({0} kada oras),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(oras),
						'one' => q({0} oras),
						'other' => q({0} na oras),
						'per' => q({0} kada oras),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μseg),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μseg),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(miliseg),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(miliseg),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(buwan),
						'one' => q({0} buwan),
						'other' => q({0} buwan),
						'per' => q({0}/buwan),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(buwan),
						'one' => q({0} buwan),
						'other' => q({0} buwan),
						'per' => q({0}/buwan),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanoseg),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanoseg),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'one' => q({0} qtr),
						'other' => q({0} qtrs),
					},
					# Core Unit Identifier
					'quarter' => {
						'one' => q({0} qtr),
						'other' => q({0} qtrs),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(seg.),
						'one' => q({0} seg.),
						'other' => q({0} seg.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(seg.),
						'one' => q({0} seg.),
						'other' => q({0} seg.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(linggo),
						'one' => q({0} linggo),
						'other' => q({0} na linggo),
						'per' => q({0}/linggo),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(linggo),
						'one' => q({0} linggo),
						'other' => q({0} na linggo),
						'per' => q({0}/linggo),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(taon),
						'one' => q({0} taon),
						'other' => q({0} taon),
						'per' => q({0}/taon),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(taon),
						'one' => q({0} taon),
						'other' => q({0} taon),
						'per' => q({0}/taon),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliamps),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliamps),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohms),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohms),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volts),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volts),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(electronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(electronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joules),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joules),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kW-hour),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kW-hour),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pound-force),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pound-force),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(mga tuldok),
						'one' => q({0} tuldok),
						'other' => q({0} tuldok),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(mga tuldok),
						'one' => q({0} tuldok),
						'other' => q({0} tuldok),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
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
						'name' => q(mga pixel),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(mga pixel),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'one' => q({0} na R⊕),
						'other' => q({0} na R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q({0} na R⊕),
						'other' => q({0} na R⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathoms),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathoms),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(talampakan),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(talampakan),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongs),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongs),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(pulgada),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(pulgada),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(light yrs),
						'one' => q({0} ly),
						'other' => q({0} na ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(light yrs),
						'one' => q({0} ly),
						'other' => q({0} na ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metro),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metro),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μmetro),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μmetro),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milya),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milya),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q({0} nmi),
						'other' => q({0} na nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0} nmi),
						'other' => q({0} na nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsecs),
						'one' => q({0} pc),
						'other' => q({0} na pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsecs),
						'one' => q({0} pc),
						'other' => q({0} na pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0} pm),
						'other' => q({0} na pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0} pm),
						'other' => q({0} na pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(puntos),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(puntos),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(solar radii),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(solar radii),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yarda),
						'one' => q({0} yd),
						'other' => q({0} na yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yarda),
						'one' => q({0} yd),
						'other' => q({0} na yd),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(solar luminosity),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(solar luminosity),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karat),
						'one' => q({0} KD),
						'other' => q({0} KD),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
						'one' => q({0} KD),
						'other' => q({0} KD),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(Earth mass),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Earth mass),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(butil),
						'one' => q({0} butil),
						'other' => q({0} butil),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(butil),
						'one' => q({0} butil),
						'other' => q({0} butil),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramo),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramo),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(libra),
						'one' => q({0} lb),
						'other' => q({0} lbs),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(libra),
						'one' => q({0} lb),
						'other' => q({0} lbs),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(solar mass),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(solar mass),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stones),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tonelada),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tonelada),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watts),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watts),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(in Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(in Hg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/hr),
						'one' => q({0} kph),
						'other' => q({0} kph),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/hr),
						'one' => q({0} kph),
						'other' => q({0} kph),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metro/seg),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metro/seg),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milya/oras),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milya/oras),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(deg. C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(deg. C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(deg. F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(deg. F),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(deg. K),
						'one' => q({0}°K),
						'other' => q({0}°K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(deg. K),
						'one' => q({0}°K),
						'other' => q({0}°K),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(bariles),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bariles),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(mga bushel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(mga bushel),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(talampakan³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(talampakan³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(pulgada³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(pulgada³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yarda³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yarda³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(tasa),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(tasa),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q({0} mc),
						'other' => q({0} na mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q({0} mc),
						'other' => q({0} na mc),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(patak),
						'one' => q({0} patak),
						'other' => q({0} patak),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(patak),
						'one' => q({0} patak),
						'other' => q({0} patak),
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
					'volume-gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} na gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} na gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litro),
						'one' => q({0} L),
						'other' => q({0} L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litro),
						'one' => q({0} L),
						'other' => q({0} L),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(karampot),
						'one' => q({0} kurot),
						'other' => q({0} kurot),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(karampot),
						'one' => q({0} kurot),
						'other' => q({0} kurot),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pints),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pints),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'one' => q({0} na mpt),
						'other' => q({0} na mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'one' => q({0} na mpt),
						'other' => q({0} na mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qts),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qts),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp na kuwart),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp na kuwart),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:oo|o|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:hindi|h|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, at {1}),
				2 => q({0} at {1}),
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
					'one' => '0 libo',
					'other' => '0 na libo',
				},
				'10000' => {
					'one' => '00 libo',
					'other' => '00 na libo',
				},
				'100000' => {
					'one' => '000 libo',
					'other' => '000 na libo',
				},
				'1000000' => {
					'one' => '0 milyon',
					'other' => '0 na milyon',
				},
				'10000000' => {
					'one' => '00 milyon',
					'other' => '00 na milyon',
				},
				'100000000' => {
					'one' => '000 milyon',
					'other' => '000 na milyon',
				},
				'1000000000' => {
					'one' => '0 bilyon',
					'other' => '0 na bilyon',
				},
				'10000000000' => {
					'one' => '00 bilyon',
					'other' => '00 na bilyon',
				},
				'100000000000' => {
					'one' => '000 bilyon',
					'other' => '000 na bilyon',
				},
				'1000000000000' => {
					'one' => '0 trilyon',
					'other' => '0 na trilyon',
				},
				'10000000000000' => {
					'one' => '00 trilyon',
					'other' => '00 na trilyon',
				},
				'100000000000000' => {
					'one' => '000 trilyon',
					'other' => '000 na trilyon',
				},
			},
			'short' => {
				'1000000000' => {
					'one' => '0B',
					'other' => '0B',
				},
				'10000000000' => {
					'one' => '00B',
					'other' => '00B',
				},
				'100000000000' => {
					'one' => '000B',
					'other' => '000B',
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
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
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
				'currency' => q(United Arab Emirates Dirham),
				'one' => q(dirham ng UAE),
				'other' => q(UAE dirhams),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghan Afghani),
				'one' => q(Afghan Afghani),
				'other' => q(Afghan Afghanis),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek ng Albania),
				'one' => q(lek ng Albania),
				'other' => q(leke ng Albania),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armenian Dram),
				'one' => q(Armenian dram),
				'other' => q(Armenian drams),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Antillean Guilder ng Netherlands),
				'one' => q(Antillean guilder ng Netherlands),
				'other' => q(Antillean guilders ng Netherlands),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angolan Kwanza),
				'one' => q(Angolan kwanza),
				'other' => q(Angolan kwanzas),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Piso ng Argentina),
				'one' => q(piso ng Argentina),
				'other' => q(piso ng Argentina),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dolyar ng Australya),
				'one' => q(dolyar ng Australya),
				'other' => q(dolyares ng Australya),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Florin ng Aruba),
				'one' => q(florin ng Aruba),
				'other' => q(florin ng Aruba),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Azerbaijani Manat),
				'one' => q(Azerbaijani manat),
				'other' => q(Azerbaijani manats),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosnia-Herzegovina Convertible Mark),
				'one' => q(Bosnia-Herzegovina convertible mark),
				'other' => q(Bosnia-Herzegovina convertible marks),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dolyar ng Barbados),
				'one' => q(dolyar ng Barbados),
				'other' => q(dolyares ng Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bangladeshi Taka),
				'one' => q(Bangladeshi taka),
				'other' => q(Bangladeshi takas),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgarian Lev),
				'one' => q(Bulgarian lev),
				'other' => q(Bulgarian leva),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahraini Dinar),
				'one' => q(Bahraini dinar),
				'other' => q(Bahraini dinars),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundian Franc),
				'one' => q(Burundian franc),
				'other' => q(Burundian francs),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dolyar ng Bermuda),
				'one' => q(dolyar ng Bermuda),
				'other' => q(dolyares ng Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dolyar ng Brunei),
				'one' => q(dolyar ng Brunei),
				'other' => q(dolyar ng Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano ng Bolivia),
				'one' => q(boliviano ng Bolivia),
				'other' => q(bolivianos ng Bolivia),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real ng Barzil),
				'one' => q(real ng Brazil),
				'other' => q(reals ng Brazil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dolyar ng Bahamas),
				'one' => q(dolyar ng Bahamas),
				'other' => q(dolyares ng Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Bhutanese Ngultrum),
				'one' => q(Bhutanese ngultrum),
				'other' => q(Bhutanese ngultrums),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botswanan Pula),
				'one' => q(Botswanan pula),
				'other' => q(Botswanan pulas),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Ruble ng Belarus),
				'one' => q(ruble ng Belarus),
				'other' => q(rubles ng Belarus),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Belarusian Ruble \(2000–2016\)),
				'one' => q(Belarusian ruble \(2000–2016\)),
				'other' => q(Belarusian rubles \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dolyar ng Belize),
				'one' => q(dolyar ng Belize),
				'other' => q(dolyares ng Belize),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dolyar ng Canada),
				'one' => q(dolyar ng Canada),
				'other' => q(Dolyares ng Canada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Congolese Franc),
				'one' => q(Congolese franc),
				'other' => q(Congolese francs),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Swiss Franc),
				'one' => q(Swiss franc),
				'other' => q(Swiss francs),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Piso ng Chile),
				'one' => q(piso ng Chile),
				'other' => q(piso ng Chile),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Chinese Yuan \(offshore\)),
				'one' => q(Chinese yuan \(offshore\)),
				'other' => q(Chinese yuan \(offshore\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Chinese Yuan),
				'one' => q(Chinese yuan),
				'other' => q(Chinese yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Piso ng Colombia),
				'one' => q(piso ng Colombia),
				'other' => q(Piso ng Colombia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colón ng Costa Rica),
				'one' => q(colón ng Costa Rica),
				'other' => q(colóns ng Costa Rica),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Convertible na Piso ng Cuba),
				'one' => q(Convertible na piso ng Cuba),
				'other' => q(Convertible na piso ng Cuba),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Piso ng Cuba),
				'one' => q(piso ng Cuba),
				'other' => q(piso ng Cuba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Cape Verdean Escudo),
				'one' => q(Cape Verdean escudo),
				'other' => q(Cape Verdean escudos),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Koruna ng Czech Republic),
				'one' => q(koruna ng Czech Republic),
				'other' => q(korunas ng Czech Republic),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Deutsche Marks),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Djiboutian Franc),
				'one' => q(Djiboutian franc),
				'other' => q(Djiboutian francs),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Danish Krone),
				'one' => q(Danish krone),
				'other' => q(Danish kroner),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Piso ng Dominican),
				'one' => q(Piso ng Dominican),
				'other' => q(piso ng Dominican),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algerian Dinar),
				'one' => q(dinar ng Algeria),
				'other' => q(Algerian dinars),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Estonian Kroon),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Pound ng Egypt),
				'one' => q(pound ng Egypt),
				'other' => q(Egyptian pounds),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritrean Nakfa),
				'one' => q(Eritrean nakfa),
				'other' => q(Eritrean nakfas),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Ethiopian Birr),
				'one' => q(Ethiopian birr),
				'other' => q(Ethiopian birrs),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'one' => q(euro),
				'other' => q(euros),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dolyar ng Fiji),
				'one' => q(dolyar ng Fiji),
				'other' => q(dolyares ng Fiji),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Pound ng Falkland Islands),
				'one' => q(pound ng Falkland Islands),
				'other' => q(pounds ng Falkland Islands),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(French Franc),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(British Pound),
				'one' => q(British pound),
				'other' => q(British pounds),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Georgian Lari),
				'one' => q(Georgian lari),
				'other' => q(Georgian laris),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Ghanaian Cedi),
				'one' => q(Ghanaian cedi),
				'other' => q(Ghanian cedis),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Pound ng Gibraltar),
				'one' => q(pound ng Gibraltar),
				'other' => q(pounds ng Gilbraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambian Dalasi),
				'one' => q(Gambian dalasi),
				'other' => q(Gambian dalasis),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Guinean Franc),
				'one' => q(Guinean franc),
				'other' => q(Guinean francs),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal ng Guatemala),
				'one' => q(quetzal ng Guatemala),
				'other' => q(quetzals ng Guatemala),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dolyar ng Guyanese),
				'one' => q(dolyar ng Guyanese),
				'other' => q(dolyares ng Guyanese),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dolyar ng Hong Kong),
				'one' => q(dolyar ng Hong Kong),
				'other' => q(dolyares ng Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira ng Honduras),
				'one' => q(lempira ng Honduras),
				'other' => q(lempiras ng Honduras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna ng Croatia),
				'one' => q(kuna ng Croatia),
				'other' => q(kunas ng Croatia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde ng Haiti),
				'one' => q(gourde ng Haiti),
				'other' => q(gourdes ng Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Forint ng Hungary),
				'one' => q(forint ng Hungary),
				'other' => q(forints ng Hungary),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indonesian Rupiah),
				'one' => q(Indonesian rupiah),
				'other' => q(Indonesian rupiahs),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(New Shekel ng Israel),
				'one' => q(new shekel ng Israel),
				'other' => q(new shekels ng Israel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indian Rupee),
				'one' => q(Indian rupee),
				'other' => q(Indian rupees),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Iraqi Dinar),
				'one' => q(Iraqi dinar),
				'other' => q(Iraqi dinars),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Iranian Rial),
				'one' => q(Iranian rial),
				'other' => q(Iranian rials),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Icelandic Króna),
				'one' => q(Icelandic króna),
				'other' => q(Icelandic krónur),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dolyar ng Jamaica),
				'one' => q(dolyar ng Jamaica),
				'other' => q(dolyares ng Jamaica),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jordanian Dinar),
				'one' => q(Jordanian dinar),
				'other' => q(Jordanian dinars),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Japanese Yen),
				'one' => q(Japanese yen),
				'other' => q(Japanese yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Kenyan Shilling),
				'one' => q(Kenyan shilling),
				'other' => q(Kenyan shillings),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kyrgystani Som),
				'one' => q(Kyrgystani som),
				'other' => q(Kyrgystani soms),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Cambodian Riel),
				'one' => q(Cambodian riel),
				'other' => q(Cambodian riels),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Comorian Franc),
				'one' => q(Comorian franc),
				'other' => q(Comorian francs),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won ng Hilagang Korea),
				'one' => q(won ng Hilagang Korea),
				'other' => q(won ng Hilagang Korea),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won ng Timog Korea),
				'one' => q(won ng Timog Korea),
				'other' => q(won ng Timog Korea),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuwaiti Dinar),
				'one' => q(Kuwaiti dinar),
				'other' => q(Kuwaiti dinars),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dolyar ng Cayman Islands),
				'one' => q(dolyar ng Cayman Islands),
				'other' => q(dolyares ng Cayman Islands),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kazakhstani Tenge),
				'one' => q(Kazakhstani tenge),
				'other' => q(Kazakhstani tenges),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laotian Kip),
				'one' => q(Laotian kip),
				'other' => q(Laotian kips),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Pound ng Lebanon),
				'one' => q(pound ng Lebanon),
				'other' => q(pounds ng Lebanon),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Sri Lankan Rupee),
				'one' => q(Sri Lankan rupee),
				'other' => q(Sri Lankan rupees),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dolyar ng Liberia),
				'one' => q(dolyar ng Liberia),
				'other' => q(dolyares ng Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesotho Loti),
				'one' => q(Lesotho loti),
				'other' => q(Lesotho lotis),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Lithuanian Litas),
				'one' => q(Lithuanian litas),
				'other' => q(Lithuanian litai),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Latvian Lats),
				'one' => q(Latvian lats),
				'other' => q(Latvian lati),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinar ng Libya),
				'one' => q(dinar ng Libya),
				'other' => q(mga dinar ng Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Moroccan Dirham),
				'one' => q(Moroccan dirham),
				'other' => q(Moroccan dirhams),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leu ng Moldova),
				'one' => q(leu ng Moldova),
				'other' => q(lei ng Moldova),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Malagasy Ariary),
				'one' => q(Malagasy Ariary),
				'other' => q(Malagasy Ariaries),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Denar ng Macedonia),
				'one' => q(denar ng North Macedonia),
				'other' => q(denari ng North Macedonia),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Myanmar Kyat),
				'one' => q(Myanmar kyat),
				'other' => q(Myanmar kyats),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongolian Tugrik),
				'one' => q(Mongolian tugrik),
				'other' => q(Mongolian tugriks),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Macanese Pataca),
				'one' => q(Macanese pataca),
				'other' => q(Macanese patacas),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mauritanian Ouguiya \(1973–2017\)),
				'one' => q(Mauritanian ouguiya \(1973–2017\)),
				'other' => q(Mauritanian ouguiyas \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya ng Mauritania),
				'one' => q(Mauritanian ouguiya),
				'other' => q(Mauritanian ouguiyas),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mauritian Rupee),
				'one' => q(Mauritian rupee),
				'other' => q(Mauritian rupees),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Maldivian Rufiyaa),
				'one' => q(Maldivian rufiyaa),
				'other' => q(Maldivian rufiyaas),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawian Kwacha),
				'one' => q(Malawian Kwacha),
				'other' => q(Malawian Kwachas),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Piso ng Mexico),
				'one' => q(piso ng Mexico),
				'other' => q(piso ng Mexico),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Malaysian Ringgit),
				'one' => q(Malaysian ringgit),
				'other' => q(Malaysian ringgits),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mozambican Metical),
				'one' => q(Mozambican metical),
				'other' => q(Mozambican meticals),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dolyar ng Namibia),
				'one' => q(dolyar ng Namibia),
				'other' => q(dolyares ng Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigerian Naira),
				'one' => q(Nigerian naira),
				'other' => q(Nigerian nairas),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Córdoba ng Nicaragua),
				'one' => q(córdoba ng Nicaragua),
				'other' => q(Córdoba ng Nicaragua),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norwegian Krone),
				'one' => q(Norwegian krone),
				'other' => q(Norwegian kroner),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepalese Rupee),
				'one' => q(Nepalese rupee),
				'other' => q(Nepalese rupees),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dolyar ng New Zealand),
				'one' => q(dolyares ng New Zealand),
				'other' => q(dolyares ng New Zealand),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Omani Rial),
				'one' => q(Omani rial),
				'other' => q(Omani rials),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa ng Panama),
				'one' => q(balboa ng Panama),
				'other' => q(Balboas ng Panama),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peruvian Sol),
				'one' => q(Peruvian sol),
				'other' => q(Peruvian soles),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papua New Guinean Kina),
				'one' => q(Papua New Guinean kina),
				'other' => q(Papua New Guinean kina),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Piso ng Pilipinas),
				'one' => q(piso ng Pilipinas),
				'other' => q(piso ng Pilipinas),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakistani Rupee),
				'one' => q(Pakistani rupee),
				'other' => q(Pakistani rupees),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty ng Poland),
				'one' => q(zloty ng Poland),
				'other' => q(zlotys ng Poland),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraguayan Guarani),
				'one' => q(Paraguayan guarani),
				'other' => q(Paraguayan guaranis),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Qatari Rial),
				'one' => q(Qatari rial),
				'other' => q(Qatari rials),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Leu ng Romania),
				'one' => q(leu ng Romania),
				'other' => q(lei ng Romania),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinar ng Serbia),
				'one' => q(dinar ng Serbia),
				'other' => q(Serbian dinars),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Ruble ng Russia),
				'one' => q(ruble ng Russia),
				'other' => q(Russian rubles),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Rwandan Franc),
				'one' => q(Rwandan franc),
				'other' => q(Rwandan francs),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudi Riyal),
				'one' => q(Saudi riyal),
				'other' => q(Saudi riyals),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dolyar ng Solomon Islands),
				'one' => q(dolyar ng Solomon Islands),
				'other' => q(dolyar ng Solomon Islands),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seychellois Rupee),
				'one' => q(Seychellois rupee),
				'other' => q(Seychellois rupees),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Pound ng Sudan),
				'one' => q(pound ng Sudan),
				'other' => q(pounds ng Sudan),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Swedish Krona),
				'one' => q(Swedish krona),
				'other' => q(Swedish kronor),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dolyar ng Singapore),
				'one' => q(dolyar ng Singapore),
				'other' => q(dolyares ng Singapore),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Saint Helena Pound),
				'one' => q(Saint Helena pound),
				'other' => q(Saint Helena pounds),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Slovenian Tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slovak Koruna),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sierra Leonean Leone),
				'one' => q(Sierra Leonean leone),
				'other' => q(Sierra Leonean leones),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra Leonean Leone \(1964—2022\)),
				'one' => q(Sierra Leonean leone \(1964—2022\)),
				'other' => q(Sierra Leonean leones \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somali Shilling),
				'one' => q(Somali shilling),
				'other' => q(Somali shillings),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dolyar ng Suriname),
				'one' => q(dolyar ng Suriname),
				'other' => q(dolyares ng Suriname),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Pound ng Timog Sudan),
				'one' => q(Pound ng Timog Sudan),
				'other' => q(pounds ng Timog Sudan),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(São Tomé & Príncipe Dobra \(1977–2017\)),
				'one' => q(São Tomé & Príncipe dobra \(1977–2017\)),
				'other' => q(São Tomé & Príncipe dobras \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(São Tomé & Príncipe Dobra),
				'one' => q(São Tomé & Príncipe dobra),
				'other' => q(São Tomé & Príncipe dobras),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Syrian Pound),
				'one' => q(Syrian pound),
				'other' => q(Syrian pounds),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Swazi Lilangeni),
				'one' => q(Swazi lilangeni),
				'other' => q(Swazi emalangeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Thai Baht),
				'one' => q(Thai baht),
				'other' => q(Thai baht),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tajikistani Somoni),
				'one' => q(Tajikistani somoni),
				'other' => q(Tajikistani somonis),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Turkmenistani Manat),
				'one' => q(Turkmenistani manat),
				'other' => q(Turkmenistani manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunisian Dinar),
				'one' => q(Tunisian dinar),
				'other' => q(Tunisian dinars),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tongan Paʻanga),
				'one' => q(Tongan paʻanga),
				'other' => q(Tongan paʻanga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Turkish Lira),
				'one' => q(Turkish lira),
				'other' => q(Turkish Lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dolyar ng Trinidad and Tobago),
				'one' => q(dolyar ng Trinidad and Tobago),
				'other' => q(dolyares ng Trinidad and Tobago),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Dolyar ng New Taiwan),
				'one' => q(dolyar ng New Taiwan),
				'other' => q(dolyares ng New Taiwan),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzanian Shilling),
				'one' => q(Tanzanian shilling),
				'other' => q(Tanzanian shillings),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia ng Ukraine),
				'one' => q(hryvnia ng Ukraine),
				'other' => q(hryvnias ng Ukraine),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Ugandan Shilling),
				'one' => q(Ugandan shilling),
				'other' => q(Ugandan shillings),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Dolyar ng US),
				'one' => q(dolyar ng US),
				'other' => q(dolyares ng US),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Piso ng Uruguay),
				'one' => q(piso ng Uruguay),
				'other' => q(piso ng Uruguay),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Uzbekistan Som),
				'one' => q(Uzbekistan som),
				'other' => q(Uzbekistan som),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venezuelan Bolívar \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Bolívar ng Venezuela \(2008–2018\)),
				'one' => q(bolívar ng Venezuela \(2008–2018\)),
				'other' => q(bolívars ng Venezuela \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bolívar ng Venezuela),
				'one' => q(bolívar ng Venezuela),
				'other' => q(bolívars ng Venezuela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Vietnamese Dong),
				'one' => q(Vietnamese dong),
				'other' => q(Vietnamese dong),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatu Vatu),
				'one' => q(Vanuatu vatu),
				'other' => q(Vanuatu vatus),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoan Tala),
				'one' => q(Samoan tala),
				'other' => q(Samoan tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA Franc BEAC),
				'one' => q(CFA franc BEAC),
				'other' => q(CFA francs BEAC),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dolyar ng Silangang Caribbean),
				'one' => q(dolyar ng Silangang Caribbean),
				'other' => q(dolyares ng Silangang Caribbean),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(CFA Franc ng Kanlurang Africa),
				'one' => q(CFA franc ng Kanlurang Africa),
				'other' => q(CFA francs ng Kanlurang Africa),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP Franc),
				'one' => q(CFP franc),
				'other' => q(CFP francs),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Hindi Kilalang Pera),
				'one' => q(\(hindi kilalang unit ng currency\)),
				'other' => q(\(hindi kilalang pera\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Yemeni Rial),
				'one' => q(Yemeni rial),
				'other' => q(Yemeni rials),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand ng Timog Africa),
				'one' => q(rand ng Timog Africa),
				'other' => q(rand ng Timog Africa),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambian Kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Zambian Kwacha),
				'one' => q(Zambian kwacha),
				'other' => q(Zambian kwachas),
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
							'Ene',
							'Peb',
							'Mar',
							'Abr',
							'May',
							'Hun',
							'Hul',
							'Ago',
							'Set',
							'Okt',
							'Nob',
							'Dis'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Ene',
							'Peb',
							'Mar',
							'Abr',
							'May',
							'Hun',
							'Hul',
							'Ago',
							'Set',
							'Okt',
							'Nob',
							'Dis'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Enero',
							'Pebrero',
							'Marso',
							'Abril',
							'Mayo',
							'Hunyo',
							'Hulyo',
							'Agosto',
							'Setyembre',
							'Oktubre',
							'Nobyembre',
							'Disyembre'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'E',
							'P',
							'M',
							'A',
							'M',
							'Hun',
							'Hul',
							'Ago',
							'Set',
							'Okt',
							'Nob',
							'Dis'
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
						mon => 'Lun',
						tue => 'Mar',
						wed => 'Miy',
						thu => 'Huw',
						fri => 'Biy',
						sat => 'Sab',
						sun => 'Lin'
					},
					short => {
						mon => 'Lu',
						tue => 'Ma',
						wed => 'Mi',
						thu => 'Hu',
						fri => 'Bi',
						sat => 'Sa',
						sun => 'Li'
					},
					wide => {
						mon => 'Lunes',
						tue => 'Martes',
						wed => 'Miyerkules',
						thu => 'Huwebes',
						fri => 'Biyernes',
						sat => 'Sabado',
						sun => 'Linggo'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'Lun',
						tue => 'Mar',
						wed => 'Miy',
						thu => 'Huw',
						fri => 'Biy',
						sat => 'Sab',
						sun => 'Lin'
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
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					wide => {0 => 'ika-1 quarter',
						1 => 'ika-2 quarter',
						2 => 'ika-3 quarter',
						3 => 'ika-4 na quarter'
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
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1600;
					return 'evening1' if $time >= 1600
						&& $time < 1800;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 1800
						&& $time < 2400;
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
					'afternoon1' => q{tanghali},
					'evening1' => q{ng gabi},
					'midnight' => q{hatinggabi},
					'morning1' => q{nang umaga},
					'morning2' => q{madaling-araw},
					'night1' => q{ng gabi},
					'noon' => q{tanghaling-tapat},
				},
				'narrow' => {
					'afternoon1' => q{sa hapon},
					'am' => q{am},
					'evening1' => q{sa gabi},
					'midnight' => q{hatinggabi},
					'morning1' => q{umaga},
					'morning2' => q{madaling-araw},
					'night1' => q{ng gabi},
					'noon' => q{tanghaling-tapat},
					'pm' => q{pm},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{hapon},
					'evening1' => q{gabi},
					'morning1' => q{umaga},
					'morning2' => q{madaling-araw},
					'night1' => q{gabi},
				},
				'wide' => {
					'afternoon1' => q{hapon},
					'evening1' => q{gabi},
					'morning1' => q{umaga},
					'morning2' => q{madaling-araw},
					'night1' => q{gabi},
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
				'0' => 'BC',
				'1' => 'AD'
			},
			wide => {
				'0' => 'Before Christ',
				'1' => 'Anno Domini'
			},
		},
		'hebrew' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'Bago ang R.O.C.',
				'1' => 'Minguo'
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
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d, y},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{M/d/yy},
		},
		'hebrew' => {
			'full' => q{EEEE, MMMM d y},
			'long' => q{MMMM d y},
			'medium' => q{MMM d y},
			'short' => q{MMM d y},
		},
		'roc' => {
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
		'hebrew' => {
		},
		'roc' => {
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
		'hebrew' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			GyMd => q{M/d/y GGGGG},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			Md => q{M/d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, M/d/y GGGGG},
			yyyyMM => q{MM-y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, MMM d, y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{MMM d, y G},
			yyyyMd => q{M/d/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			GyMd => q{M/d/y G},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			MMMMW => q{'linggo' W 'ng' MMMM},
			Md => q{M/d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{MMM d, y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'linggo' w 'ng' Y},
		},
		'hebrew' => {
			MEd => q{E, MMM d},
			Md => q{MMM d},
			y => q{y},
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
			Bh => {
				h => q{h – h B},
			},
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, M/d/y GGGGG – E, M/d/y GGGGG},
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
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
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y G},
				d => q{MMM d–d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			yMd => {
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
		},
		'gregorian' => {
			Bh => {
				h => q{h – h B},
			},
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y G – M/y G},
				M => q{M/y–M/y G},
				y => q{M/y – M/y G},
			},
			GyMEd => {
				G => q{E, M/d/y G–E, M/d/y G},
				M => q{E, M/d/y – E, M/d/y G},
				d => q{E, M/d/y – E, M/d/y G},
				y => q{E, M/d/y–E, M/d/y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y G–M/d/y G},
				M => q{M/d/y – M/d/y G},
				d => q{M/d/y–M/d/y G},
				y => q{M/d/y–M/d/y G},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
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
				M => q{E, M/d/y – E, M/d/y},
				d => q{E, M/d/y – E, M/d/y},
				y => q{E, M/d/y – E, M/d/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y},
				d => q{E, MMM d – E, MMM d, y},
				y => q{E, MMM d, y – E, MMM d, y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y},
				d => q{MMM d–d, y},
				y => q{MMM d, y – MMM d, y},
			},
			yMd => {
				M => q{M/d/y – M/d/y},
				d => q{M/d/y – M/d/y},
				y => q{M/d/y – M/d/y},
			},
		},
		'hebrew' => {
			MEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			Md => {
				M => q{MMM d – MMM d},
			},
			yM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMEd => {
				M => q{E, MMM d – E, MMM d y},
				d => q{E, MMM d – E, MMM d y},
				y => q{E, MMM d y – E, MMM d y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d y},
				d => q{E, MMM d – E, MMM d y},
				y => q{E, MMM d y – E, MMM d y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d – MMM d y},
				d => q{d – MMM d y},
				y => q{MMM d y – MMM d y},
			},
			yMd => {
				M => q{MMM d – MMM d y},
				d => q{d – MMM d y},
				y => q{MMM d y – MMM d y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Oras sa {0}),
		regionFormat => q(Daylight Time ng {0}),
		regionFormat => q(Standard na Oras sa {0}),
		'Afghanistan' => {
			long => {
				'standard' => q#Oras sa Afghanistan#,
			},
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Oras sa Gitnang Africa#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Oras sa Silangang Africa#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Oras sa Timog Africa#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Kanlurang Africa#,
				'generic' => q#Oras sa Kanlurang Africa#,
				'standard' => q#Standard na Oras sa Kanlurang Africa#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Daylight Time sa Alaska#,
				'generic' => q#Oras sa Alaska#,
				'standard' => q#Standard na Oras sa Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Amazon#,
				'generic' => q#Oras sa Amazon#,
				'standard' => q#Standard na Oras sa Amazon#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Lungsod ng Juárez#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Lungsod ng Mexico#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Puwerto ng Espanya#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Makipot na Look ng Rankin#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthélemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Sentral na Daylight na Oras sa North America#,
				'generic' => q#Sentral na Oras sa North America#,
				'standard' => q#Sentral na Standard na Oras sa North America#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Daylight na Oras sa Silangan ng Hilagang Amerika#,
				'generic' => q#Oras sa Silangan ng Hilagang Amerika#,
				'standard' => q#Standard na Oras sa Silangan ng Hilangang Amerika#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Daylight na Oras sa Bundok sa Hilagang Amerika#,
				'generic' => q#Oras sa Bundok sa Hilagang Amerika#,
				'standard' => q#Standard na Oras sa Bundok sa Hilagang Amerika#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Daylight na Oras sa Pasipiko sa Hilagang Amerika#,
				'generic' => q#Oras sa Pasipiko sa HIlagang Amerika#,
				'standard' => q#Standard na Oras sa Pasipiko sa Hilagang Amerika#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Summer Time sa Anadyr#,
				'generic' => q#Oras sa Anadyr#,
				'standard' => q#Standard Time sa Anadyr#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Daylight Time sa Apia#,
				'generic' => q#Oras sa Apia#,
				'standard' => q#Standard na Oras sa Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Daylight Time sa Arabia#,
				'generic' => q#Oras sa Arabia#,
				'standard' => q#Standard na Oras sa Arabia#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Argentina#,
				'generic' => q#Oras sa Argentina#,
				'standard' => q#Standard na Oras sa Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Kanlurang Argentina#,
				'generic' => q#Oras sa Kanlurang Argentina#,
				'standard' => q#Standard na Oras sa Kanlurang Argentina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Armenia#,
				'generic' => q#Oras sa Armenia#,
				'standard' => q#Standard na Oras sa Armenia#,
			},
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Lungsod ng Ho Chi Minh#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Daylight na Oras sa Atlantiko#,
				'generic' => q#Oras sa Atlantiko#,
				'standard' => q#Standard na Oras sa Atlantiko#,
			},
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Daylight Time sa Gitnang Australya#,
				'generic' => q#Oras sa Gitnang Australya#,
				'standard' => q#Standard na Oras sa Gitnang Australya#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Daylight Time sa Gitnang Kanlurang Australya#,
				'generic' => q#Oras ng Gitnang Kanluran ng Australya#,
				'standard' => q#Standard Time ng Gitnang Kanluran ng Australya#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Daylight Time sa Silangang Australya#,
				'generic' => q#Oras sa Silangang Australya#,
				'standard' => q#Standard na Oras sa Silangang Australya#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Daylight Time sa Kanlurang Australya#,
				'generic' => q#Oras sa Kanlurang Australya#,
				'standard' => q#Standard na Oras sa Kanlurang Australya#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Azerbaijan#,
				'generic' => q#Oras sa Azerbaijan#,
				'standard' => q#Standard na Oras sa Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Azores#,
				'generic' => q#Oras sa Azores#,
				'standard' => q#Standard na Oras sa Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Bangladesh#,
				'generic' => q#Oras sa Bangladesh#,
				'standard' => q#Standard na Oras sa Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Oras sa Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Oras sa Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Brasilia#,
				'generic' => q#Oras sa Brasilia#,
				'standard' => q#Standard na Oras sa Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Oras sa Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Cape Verde#,
				'generic' => q#Oras sa Cape Verde#,
				'standard' => q#Standard na Oras sa Cape Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Standard na Oras sa Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Daylight Time sa Chatham#,
				'generic' => q#Oras sa Chatham#,
				'standard' => q#Standard na Oras sa Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Chile#,
				'generic' => q#Oras sa Chile#,
				'standard' => q#Standard na Oras sa Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Daylight Time sa China#,
				'generic' => q#Oras sa China#,
				'standard' => q#Standard na Oras sa China#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Choibalsan#,
				'generic' => q#Oras sa Choibalsan#,
				'standard' => q#Standard na Oras sa Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Oras sa Christmas Island#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Oras sa Cocos Islands#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Colombia#,
				'generic' => q#Oras sa Colombia#,
				'standard' => q#Standard na Oras sa Colombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Oras sa Kalahati ng Tag-init ng Cook Islands#,
				'generic' => q#Oras sa Cook Islands#,
				'standard' => q#Standard na Oras sa Cook Islands#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Daylight na Oras sa Cuba#,
				'generic' => q#Oras sa Cuba#,
				'standard' => q#Standard na Oras sa Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Oras sa Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Oras sa Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Oras sa East Timor#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Easter Island#,
				'generic' => q#Oras sa Easter Island#,
				'standard' => q#Standard na Oras sa Easter Island#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Oras sa Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Coordinated Universal Time#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Di-kilalang Lungsod#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Standard na Oras sa Ireland#,
			},
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Britain#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Gitnang Europe#,
				'generic' => q#Oras sa Gitnang Europe#,
				'standard' => q#Standard na Oras sa Gitnang Europe#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Silangang Europe#,
				'generic' => q#Oras sa Silangang Europe#,
				'standard' => q#Standard na Oras sa Silangang Europe#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Oras sa Pinaka-silangang Europe#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Kanlurang Europe#,
				'generic' => q#Oras sa Kanlurang Europe#,
				'standard' => q#Standard na Oras sa Kanlurang Europe#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Falkland Islands#,
				'generic' => q#Oras sa Falkland Islands#,
				'standard' => q#Standard na Oras sa Falkland Islands#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Fiji#,
				'generic' => q#Oras sa Fiji#,
				'standard' => q#Standard na Oras sa Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Oras sa French Guiana#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Oras sa Katimugang France at Antartiko#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich Mean Time#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Oras sa Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Oras sa Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Georgia#,
				'generic' => q#Oras sa Georgia#,
				'standard' => q#Standard na Oras sa Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Oras sa Gilbert Islands#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Silangang Greenland#,
				'generic' => q#Oras sa Silangang Greenland#,
				'standard' => q#Standard na Oras sa Silangang Greenland#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Kanlurang Greenland#,
				'generic' => q#Oras sa Kanlurang Greenland#,
				'standard' => q#Standard na Oras sa Kanlurang Greenland#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Oras sa Gulf#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Oras sa Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Hawaii-Aleutian#,
				'generic' => q#Oras sa Hawaii-Aleutian#,
				'standard' => q#Standard na Oras sa Hawaii-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Hong Kong#,
				'generic' => q#Oras sa Hong Kong#,
				'standard' => q#Standard na Oras sa Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Hovd#,
				'generic' => q#Oras sa Hovd#,
				'standard' => q#Standard na Oras sa Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Standard na Oras sa India#,
			},
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Oras sa Indian Ocean#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Oras sa Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Oras sa Gitnang Indonesia#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Oras sa Silangang Indonesia#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Oras sa Kanlurang Indonesia#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Daylight Time sa Iran#,
				'generic' => q#Oras sa Iran#,
				'standard' => q#Standard na Oras sa Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Irkutsk#,
				'generic' => q#Oras sa Irkutsk#,
				'standard' => q#Standard na Oras sa Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Daylight Time sa Israel#,
				'generic' => q#Oras sa Israel#,
				'standard' => q#Standard na Oras sa Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Daylight Time sa Japan#,
				'generic' => q#Oras sa Japan#,
				'standard' => q#Standard na Oras sa Japan#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Summer Time sa Petropavlovsk-Kamchatski#,
				'generic' => q#Oras sa Petropavlovsk-Kamchatski#,
				'standard' => q#Standard Time sa Petropavlovsk-Kamchatski#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Oras sa Silangang Kazakhstan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Oras sa Kanlurang Kazakhstan#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Daylight Time sa Korea#,
				'generic' => q#Oras sa Korea#,
				'standard' => q#Standard na Oras sa Korea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Oras sa Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Krasnoyarsk#,
				'generic' => q#Oras sa Krasnoyarsk#,
				'standard' => q#Standard na Oras sa Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Oras sa Kyrgystan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Oras sa Line Islands#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Daylight Time sa Lorde Howe#,
				'generic' => q#Oras sa Lord Howe#,
				'standard' => q#Standard na Oras sa Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Oras sa Macquarie Island#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Magadan#,
				'generic' => q#Oras sa Magadan#,
				'standard' => q#Standard na Oras sa Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Oras sa Malaysia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Oras sa Maldives#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Oras sa Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Oras sa Marshall Islands#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Mauritius#,
				'generic' => q#Oras sa Mauritius#,
				'standard' => q#Standard na Oras sa Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Oras sa Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Daylight na Oras sa Hilagang-kanlurang Mexico#,
				'generic' => q#Oras sa Hilagang-kanlurang Mexico#,
				'standard' => q#Standard na Oras sa Hilagang-kanlurang Mexico#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Daylight na Oras sa Pasipiko ng Mexico#,
				'generic' => q#Oras sa Pasipiko ng Mexico#,
				'standard' => q#Standard na Oras sa Pasipiko ng Mexico#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Ulan Bator#,
				'generic' => q#Oras sa Ulan Bator#,
				'standard' => q#Standard na Oras sa Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Moscow#,
				'generic' => q#Oras sa Moscow#,
				'standard' => q#Standard na Oras sa Moscow#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Oras sa Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Oras sa Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Oras sa Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng New Caledonia#,
				'generic' => q#Oras sa New Caledonia#,
				'standard' => q#Standard na Oras sa New Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Daylight Time sa New Zealand#,
				'generic' => q#Oras sa New Zealand#,
				'standard' => q#Standard na Oras sa New Zealand#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Daylight na Oras sa Newfoundland#,
				'generic' => q#Oras sa Newfoundland#,
				'standard' => q#Standard na Oras sa Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Oras sa Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Daylight Time sa Norfolk Island#,
				'generic' => q#Oras sa Norfolk Island#,
				'standard' => q#Standard na Oras sa Norfolk Island#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Fernando de Noronha#,
				'generic' => q#Oras sa Fernando de Noronha#,
				'standard' => q#Standard na Oras sa Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Novosibirsk#,
				'generic' => q#Oras sa Novosibirsk#,
				'standard' => q#Standard na Oras sa Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Omsk#,
				'generic' => q#Oras sa Omsk#,
				'standard' => q#Standard na Oras sa Omsk#,
			},
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Pakistan#,
				'generic' => q#Oras sa Pakistan#,
				'standard' => q#Standard na Oras sa Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Oras sa Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Oras sa Papua New Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Paraguay#,
				'generic' => q#Oras sa Paraguay#,
				'standard' => q#Standard na Oras sa Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Peru#,
				'generic' => q#Oras sa Peru#,
				'standard' => q#Standard na Oras sa Peru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Pilipinas#,
				'generic' => q#Oras sa Pilipinas#,
				'standard' => q#Standard na Oras sa Pilipinas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Oras sa Phoenix Islands#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Daylight na Oras sa Saint Pierre & Miquelon#,
				'generic' => q#Oras sa Saint Pierre & Miquelon#,
				'standard' => q#Standard na Oras sa Saint Pierre & Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Oras sa Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Oras sa Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Oras sa Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Oras sa Reunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Oras sa Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Sakhalin#,
				'generic' => q#Oras sa Sakhalin#,
				'standard' => q#Standard na Oras sa Sakhalin#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samara Daylight#,
				'generic' => q#Oras sa Samara#,
				'standard' => q#Standard Time sa Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Daylight Time sa Samoa#,
				'generic' => q#Oras sa Samoa#,
				'standard' => q#Standard na Oras sa Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Oras sa Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Standard na Oras sa Singapore#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Oras sa Solomon Islands#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Oras sa Timog Georgia#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Oras sa Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Oras sa Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Oras sa Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Daylight Time sa Taipei#,
				'generic' => q#Oras sa Taipei#,
				'standard' => q#Standard na Oras sa Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Oras sa Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Oras sa Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Tonga#,
				'generic' => q#Oras sa Tonga#,
				'standard' => q#Standard na Oras sa Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Oras sa Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Turkmenistan#,
				'generic' => q#Oras sa Turkmenistan#,
				'standard' => q#Standard na Oras sa Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Oras sa Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Uruguay#,
				'generic' => q#Oras sa Uruguay#,
				'standard' => q#Standard na Oras sa Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Uzbekistan#,
				'generic' => q#Oras sa Uzbekistan#,
				'standard' => q#Standard na Oras sa Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Vanuatu#,
				'generic' => q#Oras sa Vanuatu#,
				'standard' => q#Standard na Oras sa Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Oras sa Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Vladivostok#,
				'generic' => q#Oras sa Vladivostok#,
				'standard' => q#Standard na Oras sa Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Volgograd#,
				'generic' => q#Oras sa Volgograd#,
				'standard' => q#Standard na Oras sa Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Oras sa Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Oras sa Wake Island#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Oras sa Wallis & Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Yakutsk#,
				'generic' => q#Oras sa Yakutsk#,
				'standard' => q#Standard na Oras sa Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Oras sa Tag-init ng Yekaterinburg#,
				'generic' => q#Oras sa Yekaterinburg#,
				'standard' => q#Standard na Oras sa Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Oras sa Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
