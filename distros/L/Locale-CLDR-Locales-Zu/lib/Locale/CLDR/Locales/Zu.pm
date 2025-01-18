=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Zu - Package for language Zulu

=cut

package Locale::CLDR::Locales::Zu;
# This file auto generated from Data\common\main\zu.xml
#	on Fri 17 Jan 12:03:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.46.0');

use v5.12.0;
use mro 'c3';
use utf8;
use feature 'unicode_strings';
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
				'aa' => 'isi-Afar',
 				'ab' => 'isi-Abkhazian',
 				'ace' => 'isi-Achinese',
 				'ach' => 'isi-Acoli',
 				'ada' => 'isi-Adangme',
 				'ady' => 'isi-Adyghe',
 				'af' => 'i-Afrikaans',
 				'agq' => 'isi-Aghem',
 				'ain' => 'isi-Ainu',
 				'ak' => 'isi-Akan',
 				'ale' => 'isi-Aleut',
 				'alt' => 'isi-Southern Altai',
 				'am' => 'isi-Amharic',
 				'an' => 'isi-Aragonese',
 				'ann' => 'isi-Obolo',
 				'anp' => 'isi-Angika',
 				'ar' => 'isi-Arabic',
 				'ar_001' => 'Isi-Arabic Esivamile Sesimanje',
 				'arn' => 'isi-Mapuche',
 				'arp' => 'isi-Arapaho',
 				'ars' => 'isi-Najdi Arabic',
 				'as' => 'isi-Assamese',
 				'asa' => 'isi-Asu',
 				'ast' => 'isi-Asturian',
 				'atj' => 'isi-Atikamekw',
 				'av' => 'isi-Avaric',
 				'awa' => 'isi-Awadhi',
 				'ay' => 'isi-Aymara',
 				'az' => 'isi-Azerbaijani',
 				'az@alt=short' => 'isi-Azeria',
 				'ba' => 'isi-Bashkir',
 				'ban' => 'isi-Balinese',
 				'bas' => 'isi-Basaa',
 				'be' => 'isi-Belarusian',
 				'bem' => 'isi-Bemba',
 				'bez' => 'isi-Bena',
 				'bg' => 'isi-Bulgari',
 				'bgc' => 'isi-Haryanvi',
 				'bgn' => 'isi-Western Balochi',
 				'bho' => 'isi-Bhojpuri',
 				'bi' => 'isi-Bislama',
 				'bin' => 'isi-Bini',
 				'bla' => 'isi-Siksika',
 				'blo' => 'isi-Anii',
 				'bm' => 'isi-Bambara',
 				'bn' => 'isi-Bengali',
 				'bo' => 'isi-Tibetan',
 				'br' => 'isi-Breton',
 				'brx' => 'isi-Bodo',
 				'bs' => 'isi-Bosnian',
 				'bug' => 'isi-Buginese',
 				'byn' => 'isi-Blin',
 				'ca' => 'isi-Catalan',
 				'cay' => 'isi-Cayuga',
 				'ccp' => 'i-Chakma',
 				'ce' => 'isi-Chechen',
 				'ceb' => 'isi-Cebuano',
 				'cgg' => 'isi-Chiga',
 				'ch' => 'isi-Chamorro',
 				'chk' => 'isi-Chuukese',
 				'chm' => 'isi-Mari',
 				'cho' => 'isi-Choctaw',
 				'chp' => 'isi-Chipewyan',
 				'chr' => 'isi-Cherokee',
 				'chy' => 'isi-Cheyenne',
 				'ckb' => 'isi-Central Kurdish',
 				'clc' => 'isi-Chilcotin',
 				'co' => 'isi-Corsican',
 				'crg' => 'isi-Michif',
 				'crj' => 'Southern East Cree',
 				'crk' => 'Plains Cree',
 				'crl' => 'isi-Northern East Cree',
 				'crm' => 'isi-Moose Cree',
 				'crr' => 'isi-Carolina Algonquian',
 				'crs' => 'i-Seselwa Creole French',
 				'cs' => 'isi-Czech',
 				'csw' => 'Swampy Cree',
 				'cu' => 'isi-Church Slavic',
 				'cv' => 'isi-Chuvash',
 				'cy' => 'isi-Welsh',
 				'da' => 'isi-Danish',
 				'dak' => 'isi-Dakota',
 				'dar' => 'isi-Dargwa',
 				'dav' => 'isi-Taita',
 				'de' => 'isi-German',
 				'de_AT' => 'isi-Austrian German',
 				'de_CH' => 'Isi-Swiss High German',
 				'dgr' => 'isi-Dogrib',
 				'dje' => 'isi-Zarma',
 				'doi' => 'isi-Dogri',
 				'dsb' => 'isi-Lower Sorbian',
 				'dua' => 'isi-Duala',
 				'dv' => 'isi-Divehi',
 				'dyo' => 'isi-Jola-Fonyi',
 				'dz' => 'isi-Dzongkha',
 				'dzg' => 'isi-Dazaga',
 				'ebu' => 'isi-Embu',
 				'ee' => 'isi-Ewe',
 				'efi' => 'isi-Efik',
 				'eka' => 'isi-Ekajuk',
 				'el' => 'isi-Greek',
 				'en' => 'i-English',
 				'en_AU' => 'i-Australian English',
 				'en_CA' => 'i-Canadian English',
 				'en_GB' => 'i-British English',
 				'en_GB@alt=short' => 'i-UK English',
 				'en_US' => 'i-American English',
 				'en_US@alt=short' => 'i-English (US)',
 				'eo' => 'isi-Esperanto',
 				'es' => 'isi-Spanish',
 				'es_419' => 'isi-Latin American Spanish',
 				'es_ES' => 'isi-European Spanish',
 				'es_MX' => 'isi-Mexican Spanish',
 				'et' => 'isi-Estonia',
 				'eu' => 'isi-Basque',
 				'ewo' => 'isi-Ewondo',
 				'fa' => 'isi-Persian',
 				'fa_AF' => 'isi-Dari',
 				'ff' => 'isi-Fulah',
 				'fi' => 'isi-Finnish',
 				'fil' => 'isi-Filipino',
 				'fj' => 'isi-Fijian',
 				'fo' => 'isi-Faroese',
 				'fon' => 'isi-Fon',
 				'fr' => 'isi-French',
 				'fr_CA' => 'isi-Canadian French',
 				'fr_CH' => 'isi-Swiss French',
 				'frc' => 'isi-Cajun French',
 				'frr' => 'isi-Northern Frisian',
 				'fur' => 'isi-Friulian',
 				'fy' => 'isi-Western Frisian',
 				'ga' => 'isi-Irish',
 				'gaa' => 'isi-Ga',
 				'gag' => 'isi-Gagauz',
 				'gan' => 'isi-Gan Chinese',
 				'gd' => 'isi-Scottish Gaelic',
 				'gez' => 'isi-Geez',
 				'gil' => 'isi-Gilbertese',
 				'gl' => 'isi-Galicia',
 				'gn' => 'isi-Guarani',
 				'gor' => 'isi-Gorontalo',
 				'gsw' => 'isi-Swiss German',
 				'gu' => 'isi-Gujarati',
 				'guz' => 'isi-Gusli',
 				'gv' => 'isi-Manx',
 				'gwi' => 'isi-Gwichʼin',
 				'ha' => 'isi-Hausa',
 				'hai' => 'isi-Haida',
 				'hak' => 'isi-Hakka Chinese',
 				'haw' => 'isi-Hawaiian',
 				'hax' => 'Southern Haida',
 				'he' => 'isi-Hebrew',
 				'hi' => 'isi-Hindi',
 				'hil' => 'isi-Hiligaynon',
 				'hmn' => 'isi-Hmong',
 				'hr' => 'isi-Croatian',
 				'hsb' => 'isi-Upper Sorbian',
 				'hsn' => 'isi-Xiang Chinese',
 				'ht' => 'isi-Haitian',
 				'hu' => 'isi-Hungarian',
 				'hup' => 'isi-Hupa',
 				'hur' => 'isi-Halkomelem',
 				'hy' => 'isi-Armenia',
 				'hz' => 'isi-Herero',
 				'ia' => 'izilimi ezihlangene',
 				'iba' => 'isi-Iban',
 				'ibb' => 'isi-Ibibio',
 				'id' => 'isi-Indonesian',
 				'ie' => 'izimili',
 				'ig' => 'isi-Igbo',
 				'ii' => 'isi-Sichuan Yi',
 				'ikt' => 'Western Canadian Inuktitut',
 				'ilo' => 'isi-Iloko',
 				'inh' => 'isi-Ingush',
 				'io' => 'isi-Ido',
 				'is' => 'isi-Icelandic',
 				'it' => 'isi-Italian',
 				'iu' => 'isi-Inuktitut',
 				'ja' => 'isi-Japanese',
 				'jbo' => 'isi-Lojban',
 				'jgo' => 'isi-Ngomba',
 				'jmc' => 'isi-Machame',
 				'jv' => 'isi-Javanese',
 				'ka' => 'isi-Georgian',
 				'kab' => 'isi-Kabyle',
 				'kac' => 'isi-Kachin',
 				'kaj' => 'isi-Jju',
 				'kam' => 'isi-Kamba',
 				'kbd' => 'isi-Kabardian',
 				'kcg' => 'isi-Tyap',
 				'kde' => 'isi-Makonde',
 				'kea' => 'isi-Kabuverdianu',
 				'kfo' => 'isi-Koro',
 				'kg' => 'isi-Kongo',
 				'kgp' => 'isi-Kaingang',
 				'kha' => 'isi-Khasi',
 				'khq' => 'isi-Koyra Chiini',
 				'ki' => 'isi-Kikuyu',
 				'kj' => 'isi-Kuanyama',
 				'kk' => 'isi-Kazakh',
 				'kkj' => 'isi-Kako',
 				'kl' => 'isi-Kalaallisut',
 				'kln' => 'isi-Kalenjin',
 				'km' => 'isi-Khmer',
 				'kmb' => 'isi-Kimbundu',
 				'kn' => 'isi-Kannada',
 				'ko' => 'isi-Korean',
 				'koi' => 'isi-Komi-Permyak',
 				'kok' => 'isi-Konkani',
 				'kpe' => 'isi-Kpelle',
 				'kr' => 'isi-Kanuri',
 				'krc' => 'isi-Karachay-Balkar',
 				'krl' => 'isi-Karelian',
 				'kru' => 'isi-Kurukh',
 				'ks' => 'isi-Kashmiri',
 				'ksb' => 'isiShambala',
 				'ksf' => 'isi-Bafia',
 				'ksh' => 'isi-Colognian',
 				'ku' => 'isi-Kurdish',
 				'kum' => 'isi-Kumyk',
 				'kv' => 'isi-Komi',
 				'kw' => 'isi-Cornish',
 				'kwk' => 'Kwakʼwala',
 				'kxv' => 'Kuvi',
 				'ky' => 'isi-Kyrgyz',
 				'la' => 'isi-Latin',
 				'lad' => 'isi-Ladino',
 				'lag' => 'isi-Langi',
 				'lb' => 'isi-Luxembourgish',
 				'lez' => 'isi-Lezghian',
 				'lg' => 'isi-Ganda',
 				'li' => 'isi-Limburgish',
 				'lij' => 'IsiLigurian',
 				'lil' => 'isi-Lillooet',
 				'lkt' => 'isi-Lakota',
 				'lmo' => 'IsiLombard',
 				'ln' => 'isi-Lingala',
 				'lo' => 'isi-Lao',
 				'lou' => 'isi-Louisiana Creole',
 				'loz' => 'isi-Lozi',
 				'lrc' => 'isi-Northern Luri',
 				'lsm' => 'isi-Saamia',
 				'lt' => 'isi-Lithuanian',
 				'lu' => 'isi-Luba-Katanga',
 				'lua' => 'isi-Luba-Lulua',
 				'lun' => 'isi-Lunda',
 				'luo' => 'isi-Luo',
 				'lus' => 'isi-Mizo',
 				'luy' => 'isi-Luyia',
 				'lv' => 'isi-Latvian',
 				'mad' => 'isi-Madurese',
 				'mag' => 'isi-Magahi',
 				'mai' => 'isi-Maithili',
 				'mak' => 'isi-Makasar',
 				'mas' => 'isi-Masai',
 				'mdf' => 'isi-Moksha',
 				'men' => 'isi-Mende',
 				'mer' => 'isi-Meru',
 				'mfe' => 'isi-Morisyen',
 				'mg' => 'isi-Malagasy',
 				'mgh' => 'isi-Makhuwa-Meetto',
 				'mgo' => 'isi-Meta’',
 				'mh' => 'isi-Marshallese',
 				'mi' => 'isi-Maori',
 				'mic' => 'isi-Micmac',
 				'min' => 'isi-Minangkabau',
 				'mk' => 'isi-Macedonian',
 				'ml' => 'isi-Malayalam',
 				'mn' => 'isi-Mongolian',
 				'mni' => 'isi-Manipuri',
 				'moe' => 'isi-Innu-aimun',
 				'moh' => 'isi-Mohawk',
 				'mos' => 'isi-Mossi',
 				'mr' => 'isi-Marathi',
 				'ms' => 'isi-Malay',
 				'mt' => 'isi-Maltese',
 				'mua' => 'isi-Mundang',
 				'mul' => 'izilimi ezehlukene',
 				'mus' => 'isi-Creek',
 				'mwl' => 'isi-Mirandese',
 				'my' => 'isi-Burmese',
 				'myv' => 'isi-Erzya',
 				'mzn' => 'isi-Mazanderani',
 				'na' => 'isi-Nauru',
 				'nan' => 'isi-Min Nan Chinese',
 				'nap' => 'isi-Neapolitan',
 				'naq' => 'isi-Nama',
 				'nb' => 'isi-Norwegian Bokmål',
 				'nd' => 'isi-North Ndebele',
 				'nds' => 'isi-Low German',
 				'nds_NL' => 'isi-Low Saxon',
 				'ne' => 'isi-Nepali',
 				'new' => 'isi-Newari',
 				'ng' => 'isi-Ndonga',
 				'nia' => 'isi-Nias',
 				'niu' => 'isi-Niuean',
 				'nl' => 'isi-Dutch',
 				'nl_BE' => 'isi-Flemish',
 				'nmg' => 'isi-Kwasio',
 				'nn' => 'isi-Norwegian Nynorsk',
 				'nnh' => 'isi-Ngiemboon',
 				'no' => 'isi-Norwegian',
 				'nog' => 'isi-Nogai',
 				'nqo' => 'isi-N’Ko',
 				'nr' => 'isi-South Ndebele',
 				'nso' => 'isi-Northern Sotho',
 				'nus' => 'isi-Nuer',
 				'nv' => 'isi-Navajo',
 				'ny' => 'isi-Nyanja',
 				'nyn' => 'isi-Nyankole',
 				'oc' => 'isi-Occitan',
 				'ojb' => 'Northwestern Ojibwa',
 				'ojc' => 'isi-Central Ojibwa',
 				'ojs' => 'isi-Oji-Cree',
 				'ojw' => 'Western Ojibwa',
 				'oka' => 'isi-Okanagan',
 				'om' => 'isi-Oromo',
 				'or' => 'isi-Odia',
 				'os' => 'isi-Ossetic',
 				'pa' => 'isi-Punjabi',
 				'pag' => 'isi-Pangasinan',
 				'pam' => 'isi-Pampanga',
 				'pap' => 'isi-Papiamento',
 				'pau' => 'isi-Palauan',
 				'pcm' => 'isi-Nigerian Pidgin',
 				'pis' => 'Pijin',
 				'pl' => 'isi-Polish',
 				'pqm' => 'Maliseet-Passamaquoddy',
 				'prg' => 'isi-Prussian',
 				'ps' => 'isi-Pashto',
 				'ps@alt=variant' => 'isi-Pushto',
 				'pt' => 'isi-Portuguese',
 				'pt_BR' => 'isi-Brazillian Portuguese',
 				'pt_PT' => 'isi-European Portuguese',
 				'qu' => 'isi-Quechua',
 				'quc' => 'isi-Kʼicheʼ',
 				'raj' => 'isi-Rajasthani',
 				'rap' => 'isi-Rapanui',
 				'rar' => 'isi-Rarotongan',
 				'rhg' => 'Rohingya',
 				'rm' => 'isi-Romansh',
 				'rn' => 'isi-Rundi',
 				'ro' => 'isi-Romanian',
 				'ro_MD' => 'isi-Moldavian',
 				'rof' => 'isi-Rombo',
 				'ru' => 'isi-Russian',
 				'rup' => 'isi-Aromanian',
 				'rw' => 'isi-Kinyarwanda',
 				'rwk' => 'isi-Rwa',
 				'sa' => 'isi-Sanskrit',
 				'sad' => 'isi-Sandawe',
 				'sah' => 'i-Sakha',
 				'saq' => 'isi-Samburu',
 				'sat' => 'isi-Santali',
 				'sba' => 'isi-Ngambay',
 				'sbp' => 'isi-Sangu',
 				'sc' => 'isi-Sardinian',
 				'scn' => 'isi-Sicilian',
 				'sco' => 'isi-Scots',
 				'sd' => 'isi-Sindhi',
 				'sdh' => 'i-Southern Kurdish',
 				'se' => 'isi-Northern Sami',
 				'seh' => 'isi-Sena',
 				'ses' => 'isi-Koyraboro Senni',
 				'sg' => 'isi-Sango',
 				'sh' => 'isi-Serbo-Croatian',
 				'shi' => 'isi-Tachelhit',
 				'shn' => 'isi-Shan',
 				'si' => 'isi-Sinhala',
 				'sk' => 'isi-Slovak',
 				'sl' => 'isi-Slovenian',
 				'slh' => 'Southern Lushootseed',
 				'sm' => 'isi-Samoan',
 				'sma' => 'isi-Southern Sami',
 				'smj' => 'isi-Lule Sami',
 				'smn' => 'isi-Inari Sami',
 				'sms' => 'isi-Skolt Sami',
 				'sn' => 'isiShona',
 				'snk' => 'isi-Soninke',
 				'so' => 'isi-Somali',
 				'sq' => 'isi-Albania',
 				'sr' => 'isi-Serbian',
 				'srn' => 'isi-Sranan Tongo',
 				'ss' => 'isiSwati',
 				'ssy' => 'isi-Saho',
 				'st' => 'isi-Southern Sotho',
 				'str' => 'Straits Salish',
 				'su' => 'isi-Sundanese',
 				'suk' => 'isi-Sukuma',
 				'sv' => 'isi-Swedish',
 				'sw' => 'isiSwahili',
 				'sw_CD' => 'isi-Congo Swahili',
 				'swb' => 'isi-Comorian',
 				'syr' => 'isi-Syriac',
 				'szl' => 'iSilesian',
 				'ta' => 'isi-Tamil',
 				'tce' => 'Southern Tutchone',
 				'te' => 'isi-Telugu',
 				'tem' => 'isi-Timne',
 				'teo' => 'isi-Teso',
 				'tet' => 'isi-Tetum',
 				'tg' => 'isi-Tajik',
 				'tgx' => 'isi-Tagish',
 				'th' => 'isi-Thai',
 				'tht' => 'Tahltan',
 				'ti' => 'isi-Tigrinya',
 				'tig' => 'isi-Tigre',
 				'tk' => 'isi-Turkmen',
 				'tlh' => 'isi-Klingon',
 				'tli' => 'Tlingit',
 				'tn' => 'isi-Tswana',
 				'to' => 'isi-Tongan',
 				'tok' => 'Toki Pona',
 				'tpi' => 'isi-Tok Pisin',
 				'tr' => 'isi-Turkish',
 				'trv' => 'isi-Taroko',
 				'ts' => 'isi-Tsonga',
 				'tt' => 'isi-Tatar',
 				'ttm' => 'Northern Tutchone',
 				'tum' => 'isi-Tumbuka',
 				'tvl' => 'isi-Tuvalu',
 				'tw' => 'isi-Twi',
 				'twq' => 'isi-Tasawaq',
 				'ty' => 'isi-Tahitian',
 				'tyv' => 'isi-Tuvinian',
 				'tzm' => 'isi-Central Atlas Tamazight',
 				'udm' => 'isi-Udmurt',
 				'ug' => 'isi-Uighur',
 				'uk' => 'isi-Ukrainian',
 				'umb' => 'isi-Umbundu',
 				'und' => 'ulimi olungaziwa',
 				'ur' => 'isi-Urdu',
 				'uz' => 'isi-Uzbek',
 				'vai' => 'isi-Vai',
 				've' => 'isi-Venda',
 				'vec' => 'IsiVenetian',
 				'vi' => 'isi-Vietnamese',
 				'vmw' => 'Makhuwa',
 				'vo' => 'isi-Volapük',
 				'vun' => 'isiVunjo',
 				'wa' => 'isi-Walloon',
 				'wae' => 'isi-Walser',
 				'wal' => 'isi-Wolaytta',
 				'war' => 'isi-Waray',
 				'wbp' => 'isi-Warlpiri',
 				'wo' => 'isi-Wolof',
 				'wuu' => 'isi-Wu Chinese',
 				'xal' => 'isi-Kalmyk',
 				'xh' => 'isiXhosa',
 				'xnr' => 'Kangri',
 				'xog' => 'isi-Soga',
 				'yav' => 'isi-Yangben',
 				'ybb' => 'isi-Yemba',
 				'yi' => 'isi-Yiddish',
 				'yo' => 'isi-Yoruba',
 				'yrl' => 'isi-Nheengatu',
 				'yue' => 'isi-Cantonese',
 				'yue@alt=menu' => 'isi-Chinese, Cantonese',
 				'za' => 'IsiZhuang',
 				'zgh' => 'isi-Moroccan Tamazight esivamile',
 				'zh' => 'isi-Chinese',
 				'zh@alt=menu' => 'isi-Chinese, Mandarin',
 				'zh_Hans' => 'isi-Chinese (esenziwe-lula)',
 				'zh_Hans@alt=long' => 'Isi-Chinese Esenziwe Lula',
 				'zh_Hant' => 'Isi-Chinese Sasendulo',
 				'zh_Hant@alt=long' => 'isi-Chinese (sasendulo)',
 				'zu' => 'isiZulu',
 				'zun' => 'isi-Zuni',
 				'zxx' => 'akukho okuqukethwe kolimi',
 				'zza' => 'isi-Zaza',

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
			'Adlm' => 'isi-Adlam',
 			'Aghb' => 'isi-Caucasian Albanian',
 			'Ahom' => 'isi-Ahom',
 			'Arab' => 'isi-Arabic',
 			'Arab@alt=variant' => 'isi-Perso-Arabic',
 			'Aran' => 'i-Nastaliq',
 			'Armi' => 'isi-Imperial Aramaic',
 			'Armn' => 'isi-Armenian',
 			'Avst' => 'isi-Avestan',
 			'Bali' => 'isi-Balinese',
 			'Bamu' => 'isi-Bamum',
 			'Bass' => 'isi-Bassa Vah',
 			'Batk' => 'isi-Batak',
 			'Beng' => 'isi-Bangla',
 			'Bhks' => 'isi-Bhaiksuki',
 			'Bopo' => 'isi-Bopomofo',
 			'Brah' => 'isi-Brahmi',
 			'Brai' => 'i-Braille',
 			'Bugi' => 'isi-Buginese',
 			'Buhd' => 'isi-Buhid',
 			'Cakm' => 'isi-Chakma',
 			'Cans' => 'i-Unified Canadian Aboriginal Syllabics',
 			'Cari' => 'isi-Carian',
 			'Cham' => 'isi-Cham',
 			'Cher' => 'isi-Cherokee',
 			'Chrs' => 'isi-Chorasmian',
 			'Copt' => 'isi-Coptic',
 			'Cprt' => 'isi-Cypriot',
 			'Cyrl' => 'isi-Cyrillic',
 			'Deva' => 'isi-Devanagari',
 			'Diak' => 'isi-Dives Akuru',
 			'Dogr' => 'isi-Dogra',
 			'Dsrt' => 'isi-Deseret',
 			'Dupl' => 'isi-Duployan shorthand',
 			'Egyp' => 'i-Egyptian hieroglyphs',
 			'Elba' => 'isi-Elbasan',
 			'Elym' => 'isi-Elymaic',
 			'Ethi' => 'isi-Ethiopic',
 			'Geor' => 'isi-Georgian',
 			'Glag' => 'isi-Glagolitic',
 			'Gong' => 'isi-Gunjala Gondi',
 			'Gonm' => 'isi-Masaram Gondi',
 			'Goth' => 'isi-Gothic',
 			'Gran' => 'isi-Grantha',
 			'Grek' => 'isi-Greek',
 			'Gujr' => 'isi-Gujarati',
 			'Guru' => 'isi-Gurmukhi',
 			'Hanb' => 'isi-Hanb',
 			'Hang' => 'isi-Hangul',
 			'Hani' => 'isi-Han',
 			'Hano' => 'isi-Hanunoo',
 			'Hans' => 'enziwe lula',
 			'Hans@alt=stand-alone' => 'isi-Han esenziwe lula',
 			'Hant' => 'okosiko',
 			'Hant@alt=stand-alone' => 'isi-Han sosiko',
 			'Hatr' => 'isi-Hatran',
 			'Hebr' => 'isi-Hebrew',
 			'Hira' => 'isi-Hiragana',
 			'Hluw' => 'isi-Anatolian Hieroglyphs',
 			'Hmng' => 'isi-Pahawh Hmong',
 			'Hmnp' => 'i-Nyiakeng Puachue Hmong',
 			'Hrkt' => 'i-Japanese syllabaries',
 			'Hung' => 'isi-Old Hungarian',
 			'Ital' => 'i-Old Italic',
 			'Jamo' => 'isi-Jamo',
 			'Java' => 'isi-Javanese',
 			'Jpan' => 'isi-Japanese',
 			'Kali' => 'isi-Kayah Li',
 			'Kana' => 'isi-Katakana',
 			'Khar' => 'isi-Kharoshthi',
 			'Khmr' => 'isi-Khmer',
 			'Khoj' => 'isi-Khojki',
 			'Kits' => 'i-Khitan small script',
 			'Knda' => 'isi-Kannada',
 			'Kore' => 'isi-Korean',
 			'Kthi' => 'isi-Kaithi',
 			'Lana' => 'isi-Lanna',
 			'Laoo' => 'isi-Lao',
 			'Latn' => 'isi-Latin',
 			'Lepc' => 'isi-Lepcha',
 			'Limb' => 'isi-Limbu',
 			'Lina' => 'i-Linear A',
 			'Linb' => 'i-Linear B',
 			'Lisu' => 'isi-Fraser',
 			'Lyci' => 'i-Lycian',
 			'Lydi' => 'i-Lydian',
 			'Mahj' => 'i-Mahajani',
 			'Maka' => 'i-Makasar',
 			'Mand' => 'isi-Mandaean',
 			'Mani' => 'i-Manichaean',
 			'Marc' => 'i-Marchen',
 			'Medf' => 'i-Medefaidrin',
 			'Mend' => 'i-Mende',
 			'Merc' => 'i-Meroitic Cursive',
 			'Mero' => 'i-Meroitic',
 			'Mlym' => 'isi-Malayalam',
 			'Modi' => 'i-Modi',
 			'Mong' => 'isi-Mongolian',
 			'Mroo' => 'i-Mro',
 			'Mtei' => 'isi-Meitei Mayek',
 			'Mult' => 'i-Multani',
 			'Mymr' => 'isi-Myanmar',
 			'Nand' => 'i-Nandinagari',
 			'Narb' => 'i-Old North Arabian',
 			'Nbat' => 'i-Nabataean',
 			'Nkoo' => 'isi-N’Ko',
 			'Nshu' => 'i-Nüshu',
 			'Ogam' => 'i-Ogham',
 			'Olck' => 'isi-Ol Chiki',
 			'Orkh' => 'i-Orkhon',
 			'Orya' => 'isi-Odia',
 			'Osge' => 'isi-Osage',
 			'Osma' => 'i-Osmanya',
 			'Palm' => 'i-Palmyrene',
 			'Pauc' => 'i-Pau Cin Hau',
 			'Perm' => 'i-Old Permic',
 			'Phag' => 'i-Phags-pa',
 			'Phli' => 'i-Inscriptional Pahlavi',
 			'Phlp' => 'i-Psalter Pahlavi',
 			'Phnx' => 'i-Phoenician',
 			'Plrd' => 'isi-Pollard Phonetic',
 			'Prti' => 'i-Inscriptional Parthian',
 			'Qaag' => 'i-Zawgyi',
 			'Rjng' => 'i-Rejang',
 			'Rohg' => 'isi-Hanifi Rohingya',
 			'Runr' => 'i-Runic',
 			'Samr' => 'i-Samaritan',
 			'Sarb' => 'i-Old South Arabian',
 			'Saur' => 'isi-Saurashtra',
 			'Sgnw' => 'i-SignWriting',
 			'Shaw' => 'i-Shavian',
 			'Shrd' => 'i-Sharada',
 			'Sidd' => 'i-Siddham',
 			'Sind' => 'i-Khudawadi',
 			'Sinh' => 'isi-Sinhala',
 			'Sogd' => 'i-Sogdian',
 			'Sogo' => 'i-Old Sogdian',
 			'Sora' => 'i-Sora Sompeng',
 			'Soyo' => 'i-Soyombo',
 			'Sund' => 'isi-Sundanese',
 			'Sylo' => 'isi-Syloti Nagri',
 			'Syrc' => 'isi-Syriac',
 			'Tagb' => 'i-Tagbanwa',
 			'Takr' => 'i-Takri',
 			'Tale' => 'isi-Tai Le',
 			'Talu' => 'isi-New Tai Lue',
 			'Taml' => 'isi-Tamil',
 			'Tang' => 'i-Tangut',
 			'Tavt' => 'isi-Tai Viet',
 			'Telu' => 'isi-Telugu',
 			'Tfng' => 'isi-Tifinagh',
 			'Tglg' => 'i-Tagalog',
 			'Thaa' => 'isi-Thaana',
 			'Thai' => 'isi-Thai',
 			'Tibt' => 'i-Tibetan',
 			'Tirh' => 'i-Tirhuta',
 			'Ugar' => 'i-Ugaritic',
 			'Vaii' => 'isi-Vai',
 			'Wara' => 'i-Varang Kshiti',
 			'Wcho' => 'isi-Wancho',
 			'Xpeo' => 'i-Old Persian',
 			'Xsux' => 'i-Sumero-Akkadian Cuneiform',
 			'Yezi' => 'i-Yezidi',
 			'Yiii' => 'isi-Yi',
 			'Zanb' => 'i-Zanabazar Square',
 			'Zinh' => 'Okuthethwe',
 			'Zmth' => 'i-Mathematical Notation',
 			'Zsye' => 'i-Emoji',
 			'Zsym' => 'amasimbuli',
 			'Zxxx' => 'okungabhaliwe',
 			'Zyyy' => 'jwayelekile',
 			'Zzzz' => 'iskripthi esingaziwa',

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
			'001' => 'umhlaba',
 			'002' => 'i-Africa',
 			'003' => 'i-North America',
 			'005' => 'i-South America',
 			'009' => 'i-Oceania',
 			'011' => 'i-Western Africa',
 			'013' => 'i-Central America',
 			'014' => 'i-Eastern Africa',
 			'015' => 'i-Northern Africa',
 			'017' => 'i-Middle Africa',
 			'018' => 'i-Southern Africa',
 			'019' => 'i-Americas',
 			'021' => 'i-Northern America',
 			'029' => 'i-Caribbean',
 			'030' => 'i-Eastern Asia',
 			'034' => 'i-Southern Asia',
 			'035' => 'i-South-Eastern Asia',
 			'039' => 'i-Southern Europe',
 			'053' => 'i-Australasia',
 			'054' => 'i-Melanesia',
 			'057' => 'i-Micronesian Region',
 			'061' => 'i-Polynesia',
 			'142' => 'i-Asia',
 			'143' => 'i-Central Asia',
 			'145' => 'i-Western Asia',
 			'150' => 'i-Europe',
 			'151' => 'i-Eastern Europe',
 			'154' => 'i-Northern Europe',
 			'155' => 'i-Western Europe',
 			'202' => 'Sub-Saharan Africa',
 			'419' => 'i-Latin America',
 			'AC' => 'i-Ascension Island',
 			'AD' => 'i-Andorra',
 			'AE' => 'i-United Arab Emirates',
 			'AF' => 'i-Afghanistan',
 			'AG' => 'i-Antigua ne-Barbuda',
 			'AI' => 'i-Anguilla',
 			'AL' => 'i-Albania',
 			'AM' => 'i-Armenia',
 			'AO' => 'i-Angola',
 			'AQ' => 'i-Antarctica',
 			'AR' => 'i-Argentina',
 			'AS' => 'i-American Samoa',
 			'AT' => 'i-Austria',
 			'AU' => 'i-Australia',
 			'AW' => 'i-Aruba',
 			'AX' => 'i-Åland Islands',
 			'AZ' => 'i-Azerbaijan',
 			'BA' => 'i-Bosnia ne-Herzegovina',
 			'BB' => 'i-Barbados',
 			'BD' => 'i-Bangladesh',
 			'BE' => 'i-Belgium',
 			'BF' => 'i-Burkina Faso',
 			'BG' => 'i-Bulgaria',
 			'BH' => 'i-Bahrain',
 			'BI' => 'i-Burundi',
 			'BJ' => 'i-Benin',
 			'BL' => 'i-Saint Barthélemy',
 			'BM' => 'i-Bermuda',
 			'BN' => 'i-Brunei',
 			'BO' => 'i-Bolivia',
 			'BQ' => 'i-Caribbean Netherlands',
 			'BR' => 'i-Brazil',
 			'BS' => 'i-Bahamas',
 			'BT' => 'i-Bhutan',
 			'BV' => 'i-Bouvet Island',
 			'BW' => 'iBotswana',
 			'BY' => 'i-Belarus',
 			'BZ' => 'i-Belize',
 			'CA' => 'i-Canada',
 			'CC' => 'i-Cocos (Keeling) Islands',
 			'CD' => 'i-Congo - Kinshasa',
 			'CD@alt=variant' => 'i-Congo (DRC)',
 			'CF' => 'i-Central African Republic',
 			'CG' => 'i-Congo - Brazzaville',
 			'CG@alt=variant' => 'i-Congo (Republic)',
 			'CH' => 'i-Switzerland',
 			'CI' => 'i-Côte d’Ivoire',
 			'CI@alt=variant' => 'i-Ivory Coast',
 			'CK' => 'i-Cook Islands',
 			'CL' => 'i-Chile',
 			'CM' => 'i-Cameroon',
 			'CN' => 'i-China',
 			'CO' => 'i-Colombia',
 			'CP' => 'i-Clipperton Island',
 			'CR' => 'i-Costa Rica',
 			'CU' => 'i-Cuba',
 			'CV' => 'i-Cape Verde',
 			'CW' => 'i-Curaçao',
 			'CX' => 'i-Christmas Island',
 			'CY' => 'i-Cyprus',
 			'CZ' => 'i-Czechia',
 			'CZ@alt=variant' => 'i-Czech Republic',
 			'DE' => 'i-Germany',
 			'DG' => 'i-Diego Garcia',
 			'DJ' => 'i-Djibouti',
 			'DK' => 'i-Denmark',
 			'DM' => 'i-Dominica',
 			'DO' => 'i-Dominican Republic',
 			'DZ' => 'i-Algeria',
 			'EA' => 'i-Cueta ne-Melilla',
 			'EC' => 'i-Ecuador',
 			'EE' => 'i-Estonia',
 			'EG' => 'i-Egypt',
 			'EH' => 'i-Western Sahara',
 			'ER' => 'i-Eritrea',
 			'ES' => 'i-Spain',
 			'ET' => 'i-Ethiopia',
 			'EU' => 'i-European Union',
 			'EZ' => 'I-Eurozone',
 			'FI' => 'i-Finland',
 			'FJ' => 'i-Fiji',
 			'FK' => 'i-Falkland Islands',
 			'FK@alt=variant' => 'i-Falkland Islands (Islas Malvinas)',
 			'FM' => 'i-Micronesia',
 			'FO' => 'i-Faroe Islands',
 			'FR' => 'i-France',
 			'GA' => 'i-Gabon',
 			'GB' => 'i-United Kingdom',
 			'GB@alt=short' => 'i-U.K.',
 			'GD' => 'i-Grenada',
 			'GE' => 'i-Georgia',
 			'GF' => 'i-French Guiana',
 			'GG' => 'i-Guernsey',
 			'GH' => 'i-Ghana',
 			'GI' => 'i-Gibraltar',
 			'GL' => 'i-Greenland',
 			'GM' => 'i-Gambia',
 			'GN' => 'i-Guinea',
 			'GP' => 'i-Guadeloupe',
 			'GQ' => 'i-Equatorial Guinea',
 			'GR' => 'i-Greece',
 			'GS' => 'i-South Georgia ne-South Sandwich Islands',
 			'GT' => 'i-Guatemala',
 			'GU' => 'i-Guam',
 			'GW' => 'i-Guinea-Bissau',
 			'GY' => 'i-Guyana',
 			'HK' => 'i-Hong Kong SAR China',
 			'HK@alt=short' => 'i-Hong Kong',
 			'HM' => 'I-Heard & McDonald Island',
 			'HN' => 'i-Honduras',
 			'HR' => 'i-Croatia',
 			'HT' => 'i-Haiti',
 			'HU' => 'i-Hungary',
 			'IC' => 'i-Canary Islands',
 			'ID' => 'i-Indonesia',
 			'IE' => 'i-Ireland',
 			'IL' => 'kwa-Israel',
 			'IM' => 'i-Isle of Man',
 			'IN' => 'i-India',
 			'IO' => 'i-British Indian Ocean Territory',
 			'IO@alt=chagos' => 'i-Chagos Archipelago',
 			'IQ' => 'i-Iraq',
 			'IR' => 'i-Iran',
 			'IS' => 'i-Iceland',
 			'IT' => 'i-Italy',
 			'JE' => 'i-Jersey',
 			'JM' => 'i-Jamaica',
 			'JO' => 'i-Jordan',
 			'JP' => 'i-Japan',
 			'KE' => 'i-Kenya',
 			'KG' => 'i-Kyrgyzstan',
 			'KH' => 'i-Cambodia',
 			'KI' => 'i-Kiribati',
 			'KM' => 'i-Comoros',
 			'KN' => 'i-Saint Kitts ne-Nevis',
 			'KP' => 'i-North Korea',
 			'KR' => 'i-South Korea',
 			'KW' => 'i-Kuwait',
 			'KY' => 'i-Cayman Islands',
 			'KZ' => 'i-Kazakhstan',
 			'LA' => 'i-Laos',
 			'LB' => 'i-Lebanon',
 			'LC' => 'i-Saint Lucia',
 			'LI' => 'i-Liechtenstein',
 			'LK' => 'i-Sri Lanka',
 			'LR' => 'i-Liberia',
 			'LS' => 'iLesotho',
 			'LT' => 'i-Lithuania',
 			'LU' => 'i-Luxembourg',
 			'LV' => 'i-Latvia',
 			'LY' => 'i-Libya',
 			'MA' => 'i-Morocco',
 			'MC' => 'i-Monaco',
 			'MD' => 'i-Moldova',
 			'ME' => 'i-Montenegro',
 			'MF' => 'i-Saint Martin',
 			'MG' => 'i-Madagascar',
 			'MH' => 'i-Marshall Islands',
 			'MK' => 'i-North Macedonia',
 			'ML' => 'iMali',
 			'MM' => 'i-Myanmar (Burma)',
 			'MN' => 'i-Mongolia',
 			'MO' => 'i-Macau SAR China',
 			'MO@alt=short' => 'i-Macau',
 			'MP' => 'i-Northern Mariana Islands',
 			'MQ' => 'i-Martinique',
 			'MR' => 'i-Mauritania',
 			'MS' => 'i-Montserrat',
 			'MT' => 'i-Malta',
 			'MU' => 'i-Mauritius',
 			'MV' => 'i-Maldives',
 			'MW' => 'iMalawi',
 			'MX' => 'i-Mexico',
 			'MY' => 'i-Malaysia',
 			'MZ' => 'i-Mozambique',
 			'NA' => 'i-Namibia',
 			'NC' => 'i-New Caledonia',
 			'NE' => 'i-Niger',
 			'NF' => 'i-Norfolk Island',
 			'NG' => 'i-Nigeria',
 			'NI' => 'i-Nicaragua',
 			'NL' => 'i-Netherlands',
 			'NO' => 'i-Norway',
 			'NP' => 'i-Nepal',
 			'NR' => 'i-Nauru',
 			'NU' => 'i-Niue',
 			'NZ' => 'i-New Zealand',
 			'NZ@alt=variant' => 'i-Aotearoa New Zealand',
 			'OM' => 'i-Oman',
 			'PA' => 'i-Panama',
 			'PE' => 'i-Peru',
 			'PF' => 'i-French Polynesia',
 			'PG' => 'i-Papua New Guinea',
 			'PH' => 'i-Philippines',
 			'PK' => 'i-Pakistan',
 			'PL' => 'i-Poland',
 			'PM' => 'i-Saint Pierre kanye ne-Miquelon',
 			'PN' => 'i-Pitcairn Islands',
 			'PR' => 'i-Puerto Rico',
 			'PS' => 'i-Palestinian Territories',
 			'PS@alt=short' => 'i-Palestine',
 			'PT' => 'i-Portugal',
 			'PW' => 'i-Palau',
 			'PY' => 'i-Paraguay',
 			'QA' => 'i-Qatar',
 			'QO' => 'i-Outlying Oceania',
 			'RE' => 'i-Réunion',
 			'RO' => 'i-Romania',
 			'RS' => 'i-Serbia',
 			'RU' => 'i-Russia',
 			'RW' => 'i-Rwanda',
 			'SA' => 'i-Saudi Arabia',
 			'SB' => 'i-Solomon Islands',
 			'SC' => 'i-Seychelles',
 			'SD' => 'i-Sudan',
 			'SE' => 'i-Sweden',
 			'SG' => 'i-Singapore',
 			'SH' => 'i-St. Helena',
 			'SI' => 'i-Slovenia',
 			'SJ' => 'i-Svalbard ne-Jan Mayen',
 			'SK' => 'i-Slovakia',
 			'SL' => 'i-Sierra Leone',
 			'SM' => 'i-San Marino',
 			'SN' => 'i-Senegal',
 			'SO' => 'i-Somalia',
 			'SR' => 'i-Suriname',
 			'SS' => 'i-South Sudan',
 			'ST' => 'i-São Tomé kanye ne-Príncipe',
 			'SV' => 'i-El Salvador',
 			'SX' => 'i-Sint Maarten',
 			'SY' => 'i-Syria',
 			'SZ' => 'i-Swaziland',
 			'TA' => 'i-Tristan da Cunha',
 			'TC' => 'i-Turks ne-Caicos Islands',
 			'TD' => 'i-Chad',
 			'TF' => 'i-French Southern Territories',
 			'TG' => 'i-Togo',
 			'TH' => 'i-Thailand',
 			'TJ' => 'i-Tajikistan',
 			'TK' => 'i-Tokelau',
 			'TL' => 'i-Timor-Leste',
 			'TL@alt=variant' => 'i-East Timor',
 			'TM' => 'i-Turkmenistan',
 			'TN' => 'i-Tunisia',
 			'TO' => 'i-Tonga',
 			'TR' => 'i-Turkey',
 			'TR@alt=variant' => 'i-Türkiye',
 			'TT' => 'i-Trinidad ne-Tobago',
 			'TV' => 'i-Tuvalu',
 			'TW' => 'i-Taiwan',
 			'TZ' => 'i-Tanzania',
 			'UA' => 'i-Ukraine',
 			'UG' => 'i-Uganda',
 			'UM' => 'I-U.S. Outlying Islands',
 			'UN' => 'I-United Nations',
 			'UN@alt=short' => 'ifulegi',
 			'US' => 'i-United States',
 			'US@alt=short' => 'i-U.S',
 			'UY' => 'i-Uruguay',
 			'UZ' => 'i-Uzbekistan',
 			'VA' => 'i-Vatican City',
 			'VC' => 'i-Saint Vincent ne-Grenadines',
 			'VE' => 'i-Venezuela',
 			'VG' => 'i-British Virgin Islands',
 			'VI' => 'i-U.S. Virgin Islands',
 			'VN' => 'i-Vietnam',
 			'VU' => 'i-Vanuatu',
 			'WF' => 'i-Wallis ne-Futuna',
 			'WS' => 'i-Samoa',
 			'XA' => 'Pseudo-Accents',
 			'XB' => 'Pseudo-Bidi',
 			'XK' => 'i-Kosovo',
 			'YE' => 'i-Yemen',
 			'YT' => 'i-Mayotte',
 			'ZA' => 'iNingizimu Afrika',
 			'ZM' => 'i-Zambia',
 			'ZW' => 'iZimbabwe',
 			'ZZ' => 'iSifunda esingaziwa',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'Ubhalomagama lwase-German losiko',
 			'1994' => 'Ubhalomagama lwase-Russia olusezingeni',
 			'1996' => 'Ubhalomagama lwase-German lwango-1996',
 			'1606NICT' => 'Isi-French esimaphakathi kuya ku-1606',
 			'1694ACAD' => 'isi-French Samanje',
 			'1959ACAD' => 'Okwemfundo',
 			'ABL1943' => 'Ukwakhiwa kobhalomagama kwango-1943',
 			'AKUAPEM' => 'i-AKUAPEM',
 			'ALALC97' => 'i-ALA-LC Romanization, i-edishini yango-1997',
 			'ALUKU' => 'Ulwimi lwesi-Aluku',
 			'AO1990' => 'Isivumelwano Sobhalomagama Lolwimi lesi-Portuguese sango-1990',
 			'ARANES' => 'i-ARANES',
 			'ASANTE' => 'i-ASANTE',
 			'AUVERN' => 'i-AUVERN',
 			'BAKU1926' => 'Uhlamvu lwesi-Turkic Latin oluhlanganisiwe',
 			'BALANKA' => 'Ulwimi lwe-Balank lwe-Anii',
 			'BARLA' => 'Iqembu lolwomi lwesi-Barlavento lwe-Kabuverdianu',
 			'BASICENG' => 'i-BASICENG',
 			'BAUDDHA' => 'i-BAUDDHA',
 			'BISCAYAN' => 'i-BISCAYAN',
 			'BISKE' => 'Ulwimi lwe-San Giorgio/Bila',
 			'BOHORIC' => 'Uhlambu lwe-Bohorič',
 			'BOONT' => 'i-Boontling',
 			'BORNHOLM' => 'i-BORNHOLM',
 			'CISAUP' => 'i-CISAUP',
 			'COLB1945' => 'Ubhalomagama lwe-Portuguese-Brazilian lwango-1945',
 			'CORNU' => 'i-CORNU',
 			'CREISS' => 'i-CREISS',
 			'DAJNKO' => 'Uhlamvu lwe-Dajnko',
 			'EKAVSK' => 'isi-Serbian esinokuphimisa kwe-Ekavian',
 			'EMODENG' => 'i-English Yesimanje',
 			'FONIPA' => 'Ifonotiki ye-IPA',
 			'FONKIRSH' => 'i-FONKIRSH',
 			'FONNAPA' => 'i-FONNAPA',
 			'FONUPA' => 'Ifonotiki ye-UPA',
 			'FONXSAMP' => 'i-FONXSAMP',
 			'GASCON' => 'i-GASCON',
 			'GRCLASS' => 'i-GRCLASS',
 			'GRITAL' => 'i-GRITAL',
 			'GRMISTR' => 'i-GRMISTR',
 			'HEPBURN' => 'i-Hepburn romanization',
 			'HOGNORSK' => 'i-HOGNORSK',
 			'HSISTEMO' => 'i-HSISTEMO',
 			'IJEKAVSK' => 'Isi-Serbian esinokuphimisa kwe-Ijekavian',
 			'ITIHASA' => 'i-ITIHASA',
 			'IVANCHOV' => 'i-IVANCHOV',
 			'JAUER' => 'i-JAUER',
 			'JYUTPING' => 'i-JYUTPING',
 			'KKCOR' => 'Ubhalomagama oluvamile',
 			'KOCIEWIE' => 'i-KOCIEWIE',
 			'KSCOR' => 'Ubhalomagama olusezingeni',
 			'LAUKIKA' => 'i-LAUKIKA',
 			'LEMOSIN' => 'i-LEMOSIN',
 			'LENGADOC' => 'i-LENGADOC',
 			'LIPAW' => 'Ulwimi lwesi-Lipovaz lase-Resian',
 			'LUNA1918' => 'i-LUNA1918',
 			'METELKO' => 'Uhlambu lwe-Metelko',
 			'MONOTON' => 'i-Monotonic',
 			'NDYUKA' => 'Ulwimi lwesi-Ndyuka',
 			'NEDIS' => 'Ulwimi lwesi-Natisone',
 			'NEWFOUND' => 'i-NEWFOUND',
 			'NICARD' => 'i-NICARD',
 			'NJIVA' => 'Ulwimi lwesi-Gniva/Njiva',
 			'NULIK' => 'i-Volapük yesimanje',
 			'OSOJS' => 'Ulwimi lwesi-Oseacco/Osojane',
 			'OXENDICT' => 'Ukupela Kwesichazamazwi se-Oxford EnglishOxford English Dictionary spelling',
 			'PAHAWH2' => 'i-PAHAWH2',
 			'PAHAWH3' => 'i-PAHAWH3',
 			'PAHAWH4' => 'i-PAHAWH4',
 			'PAMAKA' => 'ulwimi lwesi-Pamaka',
 			'PETR1708' => 'i-PETR1708',
 			'PINYIN' => 'i-Pinyin Romanization',
 			'POLYTON' => 'i-Polytonic',
 			'POSIX' => 'Ikhompyutha',
 			'PROVENC' => 'i-PROVENC',
 			'PUTER' => 'i-PUTER',
 			'REVISED' => 'Ubhalomagama Olubuyekeziwe',
 			'RIGIK' => 'I-Volapük Yakudala',
 			'ROZAJ' => 'i-Resian',
 			'RUMGR' => 'i-RUMGR',
 			'SAAHO' => 'i-Saho',
 			'SCOTLAND' => 'i-English Esezingeni ye-Scotish',
 			'SCOUSE' => 'i-Scouse',
 			'SIMPLE' => 'OKULULA',
 			'SOLBA' => 'Ulwimi lwesi-Stolvizza/Solbica',
 			'SOTAV' => 'Iqembu lolwimi lwesi-Sotavento lwe-Kabuverdianu',
 			'SPANGLIS' => 'i-SPANGLIS',
 			'SURMIRAN' => 'i-SURMIRAN',
 			'SURSILV' => 'i-SURSILV',
 			'SUTSILV' => 'i-SUTSILV',
 			'TARASK' => 'Ubhalomagama lwesi-Taraskievica',
 			'UCCOR' => 'Ubhalomagama Oluhlanganisiwe',
 			'UCRCOR' => 'Ubhalomagama Olubuyekeziwe Oluhlanganisiwe',
 			'ULSTER' => 'i-ULSTER',
 			'UNIFON' => 'Uhlamvu lwefonotiki lwe-Unifon',
 			'VAIDIKA' => 'i-VAIDIKA',
 			'VALENCIA' => 'i-Valencian',
 			'VALLADER' => 'i-VALLADER',
 			'VIVARAUP' => 'i-VIVARAUP',
 			'WADEGILE' => 'i-Wade-Giles Romanization',
 			'XSISTEMO' => 'i-XSISTEMO',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Ikhalenda',
 			'cf' => 'Ifomethi yemali',
 			'colalternate' => 'Ziba Ukuhlelwa Kwezimpawu',
 			'colbackwards' => 'Ukuhlelwa Kwendlela Yokubiza Okuhlehlisiwe',
 			'colcasefirst' => 'Ukuhlelwa Ngokwezinhlamvu Ezinkulu/Ezincane',
 			'colcaselevel' => 'Ukuhlelwa Okuncike Ezinkinobhweni',
 			'collation' => 'Uhlelo lokuhlunga',
 			'colnormalization' => 'Ukuhlelwa Okulinganisiwe',
 			'colnumeric' => 'Ukuhlelwa Ngezinombolo',
 			'colstrength' => 'Amandla Okuhlelwa',
 			'currency' => 'Imali',
 			'hc' => 'Umjikelezo wehora (12 vs 24',
 			'lb' => 'I-Line Break Style',
 			'ms' => 'Isistimu yokulinganisa',
 			'numbers' => 'Izinombolo',
 			'timezone' => 'Isikhathi Sendawo',
 			'va' => 'Okokwehlukanisa Kwasendaweni',
 			'x' => 'Yokusetshenziswa Ngasese',

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
 				'buddhist' => q{ikhalenda lesi-Buddhist},
 				'chinese' => q{Ikhalenda lesi-Chinese},
 				'coptic' => q{i-Coptic Calender},
 				'dangi' => q{Ikhalenda lesi-Dangi},
 				'ethiopic' => q{Ikhalenda lesi-Ethiopic},
 				'ethiopic-amete-alem' => q{i-Ethiopic Amete Alem Calender},
 				'gregorian' => q{ikhalenda lesi-Gregorian},
 				'hebrew' => q{Ikhalenda lesi-Hebrew},
 				'indian' => q{i-Indian National Calender},
 				'islamic' => q{Ikhalenda lesi-Hijri},
 				'islamic-civil' => q{Ikhalenda lesiHijri (tabular, civil epoch)},
 				'islamic-rgsa' => q{Ikhalenda yesi-Islamic (Saudi Arabia, sighting)},
 				'islamic-tbla' => q{Ikhalenda yesi-Islamic (tabular, astronomical epoch)},
 				'islamic-umalqura' => q{Ikhalenda lesiHijri (Umm al-Qura))},
 				'iso8601' => q{Ikhalenda le-ISO-8601},
 				'japanese' => q{Ikhalenda lesi-Japanese},
 				'persian' => q{Ikhalenda lesi-Persian},
 				'roc' => q{Ikhalenda lesi-Minguo},
 			},
 			'cf' => {
 				'account' => q{Ifomethi yemali ye-Accounting},
 				'standard' => q{Ifomethi yemali ejwayelekile},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Hlela Izimpawu},
 				'shifted' => q{Hlela Ukuziba Izimpawu},
 			},
 			'colbackwards' => {
 				'no' => q{Hlela Izindlela Zokuphimisela Ngokujwayelekile},
 				'yes' => q{Ukuhlelwa Kokuphimisela Kuhlehlisiwe},
 			},
 			'colcasefirst' => {
 				'lower' => q{Hlela Okwezinhlamvu Eziphansi Kuqala},
 				'no' => q{Hlela Ngokwenhlamvu Ezejwayelekile},
 				'upper' => q{Hlela Izinhlamvu Ezinkulu Kuqala},
 			},
 			'colcaselevel' => {
 				'no' => q{Hlela Okungancikile Ezinkinobhweni},
 				'yes' => q{Hlela Okuncike Ekumeni Kwezinkinobho},
 			},
 			'collation' => {
 				'big5han' => q{Ukuhlunga kwe-Traditional Chinese - Big5},
 				'compat' => q{Ukuhlunga Kwangaphambilini, ngokusebenzisana},
 				'dictionary' => q{Uhlelo Lokuhlunga Lesichazamazwi},
 				'ducet' => q{Ukuhlunga okuzenzakalelayo kwe-Unicode},
 				'emoji' => q{Uhlelo Lokuhlunga le-Emoji},
 				'eor' => q{Imithetho Yokuhlunga ye-European},
 				'gb2312han' => q{Ukuhlunga kwe-Simplified Chinese - GB2312},
 				'phonebook' => q{Ukuhlunga kwebhuku lefoni},
 				'phonetic' => q{Hlela Ngokwefonetiki},
 				'pinyin' => q{Ukuhlunga nge-Pinyin},
 				'search' => q{Usesho olujwayelekile},
 				'searchjl' => q{Sesha nge-Hangul Ongwaqa Basekuqaleni},
 				'standard' => q{I-oda yokuhlunga ejwayelekile},
 				'stroke' => q{Ukuhlunga kwe-Stroke},
 				'traditional' => q{Ukuhlunga ngokisiko},
 				'unihan' => q{Ukuhlunga kwe-Radical-Stroke},
 				'zhuyin' => q{Ukuhlunga kwe-Zhuyin},
 			},
 			'colnormalization' => {
 				'no' => q{Hlela Ngaphandle Kokulinganisa},
 				'yes' => q{Ukuhlelwa Khekhodi Enye Kulinganisiwe},
 			},
 			'colnumeric' => {
 				'no' => q{Hlela Izinhlamvu Zenombolo Ngazinye},
 				'yes' => q{Hlela Izinhlamvu Ngokwezinombolo},
 			},
 			'colstrength' => {
 				'identical' => q{Hlela konke},
 				'primary' => q{Hlela Izinhlamvu Zaphansi Kuphela},
 				'quaternary' => q{Hlola Ukuphimisela/Ukuma kwezinhlamvu/Ububanzi/i-Kana},
 				'secondary' => q{Hlela Ukuphimisela},
 				'tertiary' => q{Hlela Ukuphimisela/Ukuma kwezinhlamvu/Ububanzi},
 			},
 			'd0' => {
 				'fwidth' => q{i-Fullwidth},
 				'hwidth' => q{Ubude obuhhafu},
 				'npinyin' => q{Okwezinombolo},
 			},
 			'hc' => {
 				'h11' => q{isistimu yamahora angu-12 (0-11)},
 				'h12' => q{isistimu yamahora angu-12 (1-12)},
 				'h23' => q{isistimu yamahora angu-24 (0-23)},
 				'h24' => q{isistimu yamahora angu-24 (1-24)},
 			},
 			'lb' => {
 				'loose' => q{i-Line Break Style exegayo},
 				'normal' => q{i-Line Break Style ekahle},
 				'strict' => q{i-Line Break Style enomthetho oqinile},
 			},
 			'm0' => {
 				'bgn' => q{I-BGN},
 				'ungegn' => q{I-UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{isistimu ye-Metric},
 				'uksystem' => q{isistimu yokulinganisa ebusayo},
 				'ussystem' => q{isistimu yokulinganisa yase-US},
 			},
 			'numbers' => {
 				'ahom' => q{Izinombolo ze-Ahom},
 				'arab' => q{amadijithi esi-Arabic-Indic},
 				'arabext' => q{amadijithi esi-Arabic-Indic eluliwe},
 				'armn' => q{izinombolo zesi-Armenian},
 				'armnlow' => q{izinombolo ezincane zesi-Armenian},
 				'bali' => q{Izinombolo ze-Balinese},
 				'beng' => q{izinombolo zesi-Bengali},
 				'brah' => q{Izinombolo ze-Brahmi},
 				'cakm' => q{Izinombolo ze-Chakma},
 				'cham' => q{Izinombolo ze-Cham},
 				'cyrl' => q{Izinombolo ze-Cyrillic},
 				'deva' => q{izinombolo zesi-Devanagari},
 				'diak' => q{Izinombolo ze-Dives Akuru},
 				'ethi' => q{izinombolo zesi-Ethiopic},
 				'finance' => q{Izinombolo Zezomnotho},
 				'fullwide' => q{ububanzi obugcwele bamadijithi},
 				'geor' => q{izinombolo zesi-Georgian},
 				'gong' => q{Izinombolo ze-Gunjala Gondi},
 				'gonm' => q{Izinombolo ze-Masaram Gondi},
 				'grek' => q{izinombolo zesi-Greek},
 				'greklow' => q{izinombolo ezincane zesi-Greek},
 				'gujr' => q{amadijithi esi-Gujarati},
 				'guru' => q{amadijithi esi-Gurmukhi},
 				'hanidec' => q{izinombolo zezinombolo zesi-Chinese},
 				'hans' => q{izinombolo ezicacile zesi-Chinese},
 				'hansfin' => q{izinombolo ezicacile zezezimali zesi-Chinese},
 				'hant' => q{izinombolo zosiko zesi-Chinese},
 				'hantfin' => q{izinombolo zosiko zezezimali zesi-Chinese},
 				'hebr' => q{izinombolo zesi-Hebrew},
 				'hmng' => q{Izinombolo ze-Pahawh Hmong},
 				'hmnp' => q{Izinombolo ze-Nyiakeng Puachue Hmong},
 				'java' => q{Izinombolo ze-Javanese},
 				'jpan' => q{izinombolo zesi-Japanese},
 				'jpanfin' => q{izinombolo zezezimali zesi-Japanese},
 				'kali' => q{Izinombolo ze-Kayah Li},
 				'khmr' => q{amadijithi esi-Khmer},
 				'knda' => q{amadijithi esi-Kannada},
 				'lana' => q{Izinombolo ze-Tai Tham Hora},
 				'lanatham' => q{Izinombolo ze-Tai Tham Tham},
 				'laoo' => q{amadijithi esi-Lao},
 				'latn' => q{amadijithi ase-Western},
 				'lepc' => q{Izinombolo ze-Lepcha},
 				'limb' => q{Izinombolo ze-Limbu},
 				'mathbold' => q{Izinombolo ze-Mathematical Bold},
 				'mathdbl' => q{Izinombolo ze-Mathematical Double-Struck},
 				'mathmono' => q{Izinombolo ze-Mathematical Monospace},
 				'mathsanb' => q{Izinombolo ze-Mathematical Sans-Serif Bold},
 				'mathsans' => q{Izinombolo ze-Mathematical Sans-Serif},
 				'mlym' => q{amadijithi esi-Malayalam},
 				'modi' => q{Izinombolo ze-Modi},
 				'mong' => q{i-Mongolian Digits},
 				'mroo' => q{Izinombolo ze-Mro},
 				'mtei' => q{Izinombolo ze-Meetei Mayek},
 				'mymr' => q{amadijithi esi-Maynmar},
 				'mymrshan' => q{Izinombolo ze-Myanmar Shan},
 				'mymrtlng' => q{Izinombolo ze-Myanmar Tai Laing},
 				'native' => q{Izinkinobho Zasendaweni},
 				'nkoo' => q{Izinombolo ze-N’Ko},
 				'olck' => q{Izinombolo ze-Ol Chiki},
 				'orya' => q{Amadijithi ase-Odia},
 				'osma' => q{Izinombolo ze-Osmanya},
 				'rohg' => q{Izinombolo ze-Hanifi Rohingya},
 				'roman' => q{izinombolo zesi-Roman},
 				'romanlow' => q{izinombolo zesi-Tamil},
 				'saur' => q{Izinombolo ze-Saurashtra},
 				'shrd' => q{Izinombolo ze-Sharada},
 				'sind' => q{Izinombolo ze-Khudawadi},
 				'sinh' => q{Izinombolo ze-Sinhala Lith},
 				'sora' => q{Izinombolo ze-Sora Sompeng},
 				'sund' => q{Izinombolo ze-Sundanese},
 				'takr' => q{Izinombolo ze-Takri},
 				'talu' => q{Izinombolo ze-New Tai Lue},
 				'taml' => q{izinombolo zesi-Tamil},
 				'tamldec' => q{amadijithi esi-Tamil},
 				'telu' => q{amadijithi esi-Telegu},
 				'thai' => q{amadijithi esi-Thai},
 				'tibt' => q{amadijithi esi-Tibetan},
 				'tirh' => q{Izinombolo ze-Tirhuta},
 				'traditional' => q{Izinombolo Ezijwayelekile},
 				'vaii' => q{Izinhlazu Zezinombolo ze-Vai},
 				'wara' => q{Izinombolo ze-Warang Citi},
 				'wcho' => q{Izinombolo ze-Wancho},
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
			'metric' => q{i-Metric},
 			'UK' => q{i-UK},
 			'US' => q{i-US},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Ulimi: {0}',
 			'script' => 'Umbhalo: {0}',
 			'region' => 'Isiyingi: {0}',

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
			auxiliary => qr{[áàăâåäãā æ ç éèĕêëē íìĭîïī ñ óòŏôöøō œ úùŭûüū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b {bh} c {ch} d {dl} {dy} e f g {gc} {gq} {gx} h {hh} {hl} i j k {kh} {kl} {kp} l m n {nc} {ngc} {ngq} {ngx} {nhl} {nk} {nkc} {nkq} {nkx} {nq} {ntsh} {nx} {ny} o p {ph} q {qh} r {rh} s {sh} t {th} {tl} {ts} {tsh} u v w x {xh} y z]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
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
						'1' => q(i-pico{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(i-pico{0}),
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
						'1' => q(i-zepto{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(i-zepto{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(i-yocto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(i-yocto{0}),
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
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
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
					'angle-arc-minute' => {
						'name' => q(arcminutes),
						'one' => q({0} arcminute),
						'other' => q({0} arcminutes),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcminutes),
						'one' => q({0} arcminute),
						'other' => q({0} arcminutes),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcseconds),
						'one' => q({0} arcsecond),
						'other' => q({0} arcseconds),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcseconds),
						'one' => q({0} arcsecond),
						'other' => q({0} arcseconds),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0} radians),
						'other' => q({0} radians),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0} radians),
						'other' => q({0} radians),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q({0} revolution),
						'other' => q({0} revolutions),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0} revolution),
						'other' => q({0} revolutions),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'per' => q({0} per m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'per' => q({0} per m²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(ama-karats),
						'one' => q({0} i-karat),
						'other' => q({0} ama-karats),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(ama-karats),
						'one' => q({0} i-karat),
						'other' => q({0} ama-karats),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(permille),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(permille),
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
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bits),
						'one' => q({0} i-bit),
						'other' => q({0} ama-bits),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bits),
						'one' => q({0} i-bit),
						'other' => q({0} ama-bits),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bytes),
						'one' => q({0} i-byte),
						'other' => q({0} ama-bytes),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bytes),
						'one' => q({0} i-byte),
						'other' => q({0} ama-bytes),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabits),
						'one' => q({0} i-gigabit),
						'other' => q({0} ama-gigabits),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabits),
						'one' => q({0} i-gigabit),
						'other' => q({0} ama-gigabits),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobits),
						'one' => q({0} i-kilobit),
						'other' => q({0} ama-kilobits),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobits),
						'one' => q({0} i-kilobit),
						'other' => q({0} ama-kilobits),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabits),
						'one' => q({0} i-megabit),
						'other' => q({0} megabits),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabits),
						'one' => q({0} i-megabit),
						'other' => q({0} megabits),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabits),
						'one' => q({0} i-terabit),
						'other' => q({0} ama-terabits),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabits),
						'one' => q({0} i-terabit),
						'other' => q({0} ama-terabits),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'one' => q({0} dec),
						'other' => q({0} decades),
					},
					# Core Unit Identifier
					'decade' => {
						'one' => q({0} dec),
						'other' => q({0} decades),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} ihora),
						'other' => q({0} amahora),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} ihora),
						'other' => q({0} amahora),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(microseconds),
						'one' => q({0} microsecond),
						'other' => q({0} microseconds),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(microseconds),
						'one' => q({0} microsecond),
						'other' => q({0} microseconds),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} iminithi),
						'other' => q({0} amaminithi),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} iminithi),
						'other' => q({0} amaminithi),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} inyanga),
						'other' => q({0} izinyanga),
						'per' => q({0} ngenyanga),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} inyanga),
						'other' => q({0} izinyanga),
						'per' => q({0} ngenyanga),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} isekhondi),
						'other' => q({0} amasekhondi),
						'per' => q({0}ps),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} isekhondi),
						'other' => q({0} amasekhondi),
						'per' => q({0}ps),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} iviki),
						'other' => q({0} amaviki),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} iviki),
						'other' => q({0} amaviki),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Calories),
						'one' => q({0} Calorie),
						'other' => q({0} Calories),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Calories),
						'one' => q({0} Calorie),
						'other' => q({0} Calories),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joule),
						'one' => q({0} i-joule),
						'other' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joule),
						'one' => q({0} i-joule),
						'other' => q({0} J),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(amachashazi ngesenthimitha),
						'one' => q({0} ichashazi ngesenthimitha),
						'other' => q({0} amachashazi ngesethimitha),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(amachashazi ngesenthimitha),
						'one' => q({0} ichashazi ngesenthimitha),
						'other' => q({0} amachashazi ngesethimitha),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(amachashazi nge-inch),
						'one' => q({0} ichashazi nge-inch),
						'other' => q({0} amachashazi nge-inch),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(amachashazi nge-inch),
						'one' => q({0} ichashazi nge-inch),
						'other' => q({0} amachashazi nge-inch),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0} MP),
						'other' => q({0} megapixels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0} MP),
						'other' => q({0} megapixels),
					},
					# Long Unit Identifier
					'light-candela' => {
						'one' => q({0} cd),
						'other' => q({0} candela),
					},
					# Core Unit Identifier
					'candela' => {
						'one' => q({0} cd),
						'other' => q({0} candela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'one' => q({0} i-lumen),
						'other' => q({0} lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'one' => q({0} i-lumen),
						'other' => q({0} lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q({0} i-lux),
						'other' => q({0} i-lux),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0} i-lux),
						'other' => q({0} i-lux),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'per' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'per' => q({0}kg),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} nge-{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} nge-{1}),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(square {0}),
						'one' => q(square {0}),
						'other' => q(square {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(square {0}),
						'one' => q(square {0}),
						'other' => q(square {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(cubic {0}),
						'one' => q(cubic {0}),
						'other' => q(cubic {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(cubic {0}),
						'one' => q(cubic {0}),
						'other' => q(cubic {0}),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(knot),
						'one' => q({0} amafindo),
						'other' => q({0} amafindo),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(knot),
						'one' => q({0} amafindo),
						'other' => q({0} amafindo),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'one' => q({0} sipuni dessert),
						'other' => q({0} dstspn),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'one' => q({0} sipuni dessert),
						'other' => q({0} dstspn),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q({0} Imp. isipuni dessert),
						'other' => q({0} dstspn Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q({0} Imp. isipuni dessert),
						'other' => q({0} dstspn Imp),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q({0} Imp. quart),
						'other' => q({0} qt Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0} Imp. quart),
						'other' => q({0} qt Imp.),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(i-z{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(i-z{0}),
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
					'angle-radian' => {
						'one' => q({0}rev),
						'other' => q({0}rev),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0}rev),
						'other' => q({0}rev),
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
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunam),
						'one' => q({0}dunam),
						'other' => q({0}dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunam),
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
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
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
						'one' => q({0} m²),
						'other' => q({0}m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0} m²),
						'other' => q({0}m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0}dunam),
						'other' => q({0}dunam),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0}dunam),
						'other' => q({0}dunam),
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
					'concentr-karat' => {
						'name' => q(karat),
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
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
						'one' => q({0}item),
						'other' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'one' => q({0}item),
						'other' => q({0}ppm),
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
						'one' => q({0}L/km),
						'other' => q({0}L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'one' => q({0}L/km),
						'other' => q({0}L/km),
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
						'one' => q({0}m/gUK),
						'other' => q({0}m/gUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0}m/gUK),
						'other' => q({0}m/gUK),
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
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'one' => q({0}Mb),
						'other' => q({0} kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'one' => q({0}Mb),
						'other' => q({0} kB),
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
						'one' => q({0}c),
						'other' => q({0}c),
					},
					# Core Unit Identifier
					'century' => {
						'one' => q({0}c),
						'other' => q({0}c),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0}),
						'other' => q({0} suku),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0}),
						'other' => q({0} suku),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'one' => q({0}dec),
						'other' => q({0} dec),
					},
					# Core Unit Identifier
					'decade' => {
						'one' => q({0}dec),
						'other' => q({0} dec),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} hora),
						'other' => q({0} hora),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} hora),
						'other' => q({0} hora),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} umzuzu),
						'other' => q({0} umzuzu),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} umzuzu),
						'other' => q({0} umzuzu),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(isekhondi),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(isekhondi),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} w),
						'other' => q({0} w),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} w),
						'other' => q({0} w),
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
						'one' => q({0}Btu),
						'other' => q({0}Btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'one' => q({0}Btu),
						'other' => q({0}Btu),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					# Core Unit Identifier
					'calorie' => {
						'one' => q({0}kcal),
						'other' => q({0}kcal),
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
						'one' => q({0} kHz),
						'other' => q({0}kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'one' => q({0} kHz),
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
					'graphics-dot' => {
						'name' => q(ichashazi),
						'one' => q({0}ichashazi),
						'other' => q({0}ichashazi),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(ichashazi),
						'one' => q({0}ichashazi),
						'other' => q({0}ichashazi),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'one' => q({0}dpcm),
						'other' => q({0}dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'one' => q({0}dpcm),
						'other' => q({0}dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'one' => q({0} dpi),
						'other' => q({0}dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'one' => q({0} dpi),
						'other' => q({0}dpi),
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
						'one' => q({0}MP),
						'other' => q({0}MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0}MP),
						'other' => q({0}MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'one' => q({0}ppcm),
						'other' => q({0} ppcm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'one' => q({0}ppcm),
						'other' => q({0} ppcm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'one' => q({0}ppi),
						'other' => q({0}ppi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'one' => q({0}ppi),
						'other' => q({0}ppi),
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
					'length-foot' => {
						'one' => q({0}′),
						'other' => q({0} ft),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0}′),
						'other' => q({0} ft),
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
						'one' => q({0} lm),
						'other' => q({0}lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'one' => q({0} lm),
						'other' => q({0}lm),
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
						'one' => q({0}gr),
						'other' => q({0}gr),
					},
					# Core Unit Identifier
					'grain' => {
						'one' => q({0}gr),
						'other' => q({0}gr),
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
						'one' => q({0} st),
						'other' => q({0}st),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0} st),
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
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0}MW),
						'other' => q({0}MW),
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
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
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
						'one' => q({0}kPa),
						'other' => q({0}kPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'one' => q({0}kPa),
						'other' => q({0}kPa),
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
						'one' => q({0} psi),
						'other' => q({0}psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'one' => q({0} psi),
						'other' => q({0}psi),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0}kph),
						'other' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0}kph),
						'other' => q({0} km/h),
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
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0}°),
						'other' => q({0}°),
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
					'volume-acre-foot' => {
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
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
						'one' => q({0}cL),
						'other' => q({0}cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'one' => q({0}cL),
						'other' => q({0}cL),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'one' => q({0}m³),
						'other' => q({0}m³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q({0}m³),
						'other' => q({0}m³),
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
						'one' => q({0}ft³),
						'other' => q({0}ft³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'one' => q({0}ft³),
						'other' => q({0}ft³),
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
						'one' => q({0}hL),
						'other' => q({0}hL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'one' => q({0}hL),
						'other' => q({0}hL),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl.dr.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl.dr.),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dr),
						'one' => q({0}dr),
						'other' => q({0}dr),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dr),
						'one' => q({0}dr),
						'other' => q({0}dr),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
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
						'name' => q(Imp gal),
						'one' => q({0}galIm),
						'other' => q({0}galIm),
						'per' => q({0}/galIm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Imp gal),
						'one' => q({0}galIm),
						'other' => q({0}galIm),
						'per' => q({0}/galIm),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'one' => q({0}hL),
						'other' => q({0}hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'one' => q({0}hL),
						'other' => q({0}hL),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'per' => q({0}hL),
					},
					# Core Unit Identifier
					'liter' => {
						'per' => q({0}hL),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'one' => q({0}ML),
						'other' => q({0}ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'one' => q({0}ML),
						'other' => q({0}ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'one' => q({0}cL),
						'other' => q({0}cL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'one' => q({0}cL),
						'other' => q({0}cL),
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
						'name' => q(pt),
						'one' => q({0}mpt),
						'other' => q({0}mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pt),
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
						'one' => q({0} Imp. quart),
						'other' => q({0} qt Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0} Imp. quart),
						'other' => q({0} qt Imp.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(indlela),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(indlela),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(i-p{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(i-p{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(i-y{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(i-y{0}),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arcmins),
						'one' => q({0} arcmin),
						'other' => q({0} arcmins),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcmins),
						'one' => q({0} arcmin),
						'other' => q({0} arcmins),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcsecs),
						'one' => q({0} arcsec),
						'other' => q({0} arcsecs),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcsecs),
						'one' => q({0} arcsec),
						'other' => q({0} arcsecs),
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
					'angle-radian' => {
						'name' => q(radians),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radians),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunams),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunams),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karats),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karats),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(izingxenye/izigidi),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(izingxenye/izigidi),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(miles/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(miles/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
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
					'digital-kilobit' => {
						'name' => q(kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
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
					'digital-terabit' => {
						'name' => q(Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(izinsuku),
						'one' => q({0} usuku),
						'other' => q({0} izinsuku),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(izinsuku),
						'one' => q({0} usuku),
						'other' => q({0} izinsuku),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(amahora),
						'one' => q({0} hora),
						'other' => q({0} hr),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(amahora),
						'one' => q({0} hora),
						'other' => q({0} hr),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsecs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsecs),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(amaminithi),
						'one' => q({0} iminithi),
						'other' => q({0} iminithi),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(amaminithi),
						'one' => q({0} iminithi),
						'other' => q({0} iminithi),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(izinyanga),
						'one' => q({0} nyanga),
						'other' => q({0} izinyanga),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(izinyanga),
						'one' => q({0} nyanga),
						'other' => q({0} izinyanga),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(amasekhondi),
						'one' => q({0} sekhondi),
						'other' => q({0} sec),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(amasekhondi),
						'one' => q({0} sekhondi),
						'other' => q({0} sec),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(amaviki),
						'one' => q({0} viki),
						'other' => q({0} amaviki),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(amaviki),
						'one' => q({0} viki),
						'other' => q({0} amaviki),
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
					'graphics-dot' => {
						'name' => q(amachashazi),
						'one' => q({0} ichashazi),
						'other' => q({0} amachashazi),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(amachashazi),
						'one' => q({0} ichashazi),
						'other' => q({0} amachashazi),
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
					'length-meter' => {
						'name' => q(m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
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
					'mass-gram' => {
						'name' => q(g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
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
					'volume-liter' => {
						'name' => q(l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:yebo|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:cha|c|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, ne-{1}),
				2 => q({0} ne-{1}),
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
					'one' => '0 inkulungwane',
					'other' => '0 inkulungwane',
				},
				'10000' => {
					'one' => '00 inkulungwane',
					'other' => '00 inkulungwane',
				},
				'100000' => {
					'one' => '000 inkulungwane',
					'other' => '000 inkulungwane',
				},
				'1000000' => {
					'one' => '0 isigidi',
					'other' => '0 isigidi',
				},
				'10000000' => {
					'one' => '00 isigidi',
					'other' => '00 isigidi',
				},
				'100000000' => {
					'one' => '000 isigidi',
					'other' => '000 isigidi',
				},
				'1000000000' => {
					'one' => '0 isigidi sezigidi',
					'other' => '0 isigidi sezigidi',
				},
				'10000000000' => {
					'one' => '00 isigidi sezigidi',
					'other' => '00 isigidi sezigidi',
				},
				'100000000000' => {
					'one' => '000 isigidi sezigidi',
					'other' => '000 isigidi sezigidi',
				},
				'1000000000000' => {
					'one' => '0 isigidintathu',
					'other' => '0 isigidintathu',
				},
				'10000000000000' => {
					'one' => '00 isigidintathu',
					'other' => '00 isigidintathu',
				},
				'100000000000000' => {
					'one' => '000 isigidintathu',
					'other' => '000 isigidintathu',
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
				'currency' => q(i-Dirham yase-United Arab Emirates),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(i-Afghan Afghani),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(i-Albanian Lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(i-Armenian Dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(i-Netherlands Antillean Guilder),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(i-Angolan Kwanza),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(i-Argentina Peso),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(i-Austrilian Dollar),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(i-Aruban Florin),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(i-Azerbaijani Manat),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(i-Bosnia-Herzegovina Convertible Mark),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(i-Barbadian Dollar),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(i-Bangladeshi Taka),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(i-Bulgarian Lev),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(i-Bahraini Dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(i-Burundian Franc),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(i-Bermudan Dollar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(i-Brunei Dollar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(i-Bolivian Boliviano),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(i-Brazilian Real),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(i-Bahamian Dollar),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(i-Bhutanese Ngultrum),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(i-Botswana Pula),
			},
		},
		'BYN' => {
			symbol => 'P.',
			display_name => {
				'currency' => q(i-Belarusian Ruble),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(i-Belarusian Ruble \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(i-Belize Dollar),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(i-Candian Dollar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(i-Congolese Franc),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(i-Swiss Franc),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(i-Chilean Peso),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(i-CNH),
				'one' => q(i-Chinese yuan \(offshore\)),
				'other' => q(i-CNH),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(i-Chinese Yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(i-Colombian Peso),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(i-Costa Rican Colón),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(i-Cuban Convertable Peso),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(i-Cuban Peso),
				'one' => q(i-Cuban pesos),
				'other' => q(i-Cuban pesos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(i-Cape Verdean Escudo),
				'one' => q(i-Cape Verdean Escudo),
				'other' => q(i-Cape Verdean escudos),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(i-Czech Republic Koruna),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(i-Djiboutian Franc),
			},
		},
		'DKK' => {
			symbol => 'Kr',
			display_name => {
				'currency' => q(i-Danish Krone),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(i-Dominican Peso),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(i-Algerian Dinar),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(i-Egyptian Pound),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(i-Eritrean Nakfa),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(i-Ethopian Birr),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(i-Euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(i-Fijian Dollar),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(i-Falkland Islands Pound),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(i-British Pound),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(i-Georgian Lari),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(i-Ghanaian Cedi),
				'one' => q(i-Ghanaian Cedi),
				'other' => q(i-Ghanaian cedis),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(i-Gibraltar Pound),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(i-Gambian Dalasi),
				'one' => q(i-Gambian Dalasi),
				'other' => q(i-Gambian dalasis),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(i-Gunean Franc),
				'one' => q(i-Gunean Franc),
				'other' => q(i-Guinean francs),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(i-Guatemalan Quetzal),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(i-Guyanaese Dollar),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(i-Hong Kong Dollar),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(i-Honduran Lempira),
				'one' => q(i-Honduran Lempira),
				'other' => q(i-Honduran lempiras),
			},
		},
		'HRK' => {
			symbol => 'Kn',
			display_name => {
				'currency' => q(i-Croatian Kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(i-Haitian Gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(i-Hungarian Forint),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(i-Indonesian Rupiah),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(i-Israeli New Sheqel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(i-Indian Rupee),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(i-Iraqi Dinar),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(i-Iranian Rial),
			},
		},
		'ISK' => {
			symbol => 'Kr',
			display_name => {
				'currency' => q(i-Icelandic Króna),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(i-Jamaican Dollar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(i-Jordanian Dinar),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(i-Japanese Yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(i-Kenyan Shilling),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(i-Kyrgystani Som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(i-Cambodian Riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(i-Comorian Franc),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(i-North Korean Won),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(i-South Korean Won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(i-Kuwaiti Dinar),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(i-Cayman Islands Dollar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(i-Kazakhstani Tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(i-Laotian Kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(i-Lebanese Pound),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(i-Sri Lankan Rupee),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(i-Liberian Dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(i-Lesotho Loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(i-Lithuanian Litas),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(i-Latvian Lats),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(i-Libyan Dinar),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(i-Moroccan Dirham),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(i-Moldovan Leu),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(i-Malagasy Ariary),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(i-Macedonian Denar),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(i-Myanma Kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(i-Mongolian Tugrik),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(i-Macanese Pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(i-Mauritanian Ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(i-Mauritanian Ouguiya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(i-Mauritian Rupee),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(i-Maldivian Rufiyana),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(i-Malawian Kwacha),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(i-Mexican Peso),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(i-Malaysian Ringgit),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(i-Mozambican Metical),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(i-Namibian Dollar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(i-Nigerian Naira),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(i-Nicaraguan Córdoba),
			},
		},
		'NOK' => {
			symbol => 'Kr',
			display_name => {
				'currency' => q(i-Norwegian Krone),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(i-Nepalese Rupee),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(i-New Zealand Dollar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(i-Omani Rial),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(i-Panamanian Balboa),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(i-Peruvian Nuevo Sol),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(i-Papua New Guinean Kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(i-Philippine Peso),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(i-Pakistani Rupee),
			},
		},
		'PLN' => {
			symbol => 'Zł',
			display_name => {
				'currency' => q(i-Polish Zloty),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(i-Paraguayan Guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(i-Qatari Rial),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(i-Romanian Leu),
				'one' => q(i-Romanian leu),
				'other' => q(i-Romanian lei),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(i-Serbian Dinar),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(i-Russian Ruble),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(i-Rwandan Franc),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(i-Saudi Riyal),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(i-Solomon Islands Dollar),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(i-Seychellois Rupee),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(i-Sudanese Pound),
			},
		},
		'SEK' => {
			symbol => 'Kr',
			display_name => {
				'currency' => q(i-Swedish Krona),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(i-Singapore Dollar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(i-Saint Helena Pound),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(i-Sierra Leonean Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(i-Sierra Leonean Leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(i-Somali Shilling),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(i-Surinamese Dollar),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(i-South Sudanese Pound),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(i-São Tomé kanye ne-Príncipe Dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(i-São Tomé kanye ne-Príncipe Dobra),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(i-Syrian Pound),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(i-Swazi Lilangeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(i-Thai Baht),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(i-Tajikistani Somoni),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(i-Turkmenistani Manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(i-Tunisian Dinar),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(i-Tongan Paʻanga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(i-Turkish Lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(i-Trinidad and Tobago Dollar),
				'one' => q(i-Trinidad and Tobago dollar),
				'other' => q(i-Trinidad & Tobago dollars),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(i-New Taiwan Dollar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(i-Tanzanian Shilling),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(i-Ukrainian Hryvnia),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(i-Ugandan Shilling),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(i-US Dollar),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(i-Uruguayan Peso),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(i-Uzbekistan Som),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(i-Venezuelan Bolívar \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(i-Venezuelan Bolívar),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(i-Vietnamese Dong),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(i-Vanuatu Vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(i-Samoan Tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(i-Central African CFA Franc),
				'one' => q(i-CFA Franc BCEA),
				'other' => q(i-CFA Franc BCEA),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(i-East Caribbean Dollar),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(i-West African CFA Franc),
				'one' => q(i-West African CFA Franc),
				'other' => q(i-West African CFA francs),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(i-CFP Franc),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(imali engaziwa),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(i-Yemeni Rial),
			},
		},
		'ZAR' => {
			symbol => 'R',
			display_name => {
				'currency' => q(i-South African Rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(i-Zambian Kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(i-Zambian Kwacha),
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
							'Mas',
							'Eph',
							'Mey',
							'Jun',
							'Jul',
							'Aga',
							'Sep',
							'Okt',
							'Nov',
							'Dis'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'E',
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
					wide => {
						nonleap => [
							'Januwari',
							'Februwari',
							'Mashi',
							'Ephreli',
							'Meyi',
							'Juni',
							'Julayi',
							'Agasti',
							'Septhemba',
							'Okthoba',
							'Novemba',
							'Disemba'
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
						mon => 'Mso',
						tue => 'Bil',
						wed => 'Tha',
						thu => 'Sin',
						fri => 'Hla',
						sat => 'Mgq',
						sun => 'Son'
					},
					wide => {
						mon => 'UMsombuluko',
						tue => 'ULwesibili',
						wed => 'ULwesithathu',
						thu => 'ULwesine',
						fri => 'ULwesihlanu',
						sat => 'UMgqibelo',
						sun => 'ISonto'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'M',
						tue => 'B',
						wed => 'T',
						thu => 'S',
						fri => 'H',
						sat => 'M',
						sun => 'S'
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
					wide => {0 => 'ikota yesi-1',
						1 => 'ikota yesi-2',
						2 => 'ikota yesi-3',
						3 => 'ikota yesi-4'
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
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1000
						&& $time < 1300;
					return 'evening1' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1000;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1000
						&& $time < 1300;
					return 'evening1' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1000;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1000
						&& $time < 1300;
					return 'evening1' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1000;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1000
						&& $time < 1300;
					return 'evening1' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1000;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1000
						&& $time < 1300;
					return 'evening1' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1000;
					return 'night1' if $time >= 1900
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1000
						&& $time < 1300;
					return 'evening1' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1000;
					return 'night1' if $time >= 1900
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
					'afternoon1' => q{emini},
					'evening1' => q{ntambama},
					'morning1' => q{entathakusa},
					'morning2' => q{ekuseni},
					'night1' => q{ebusuku},
				},
				'narrow' => {
					'am' => q{a},
					'pm' => q{p},
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
		'buddhist' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'BC',
				'1' => 'AD'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'generic' => {
			'full' => q{EEEE dd MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d, y},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{M/d/yy},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
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
		'buddhist' => {
		},
		'generic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
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
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			Md => q{M/d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yM => q{yM},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMd => q{MMM d, y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, M/d/y GGGGG},
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
			GyMd => q{M/d/y GGGGG},
			MMMEd => q{E, MMM d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{MMM d, y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
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
		'buddhist' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{G y – G y},
			},
			GyM => {
				G => q{GGGGG y-MM – GGGGG y-MM},
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			GyMEd => {
				G => q{GGGGG y-MM-dd, E – GGGGG y-MM-dd, E},
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			GyMMM => {
				G => q{G y MMM – G y MMM},
				y => q{G y MMM – y MMM},
			},
			GyMMMEd => {
				G => q{G y MMM d, E – G y MMM d, E},
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			GyMMMd => {
				G => q{G y MMM d – G y MMM d},
				M => q{G y MMM d – MMM d},
				y => q{G y MMM d – y MMM d},
			},
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
		'generic' => {
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
				d => q{MMM d – d},
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
				y => q{y–y},
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
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y},
				d => q{E, MMM d – E, MMM d, y},
				y => q{E, MMM d, y – E, MMM d, y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y},
			},
			yMd => {
				M => q{M/d/y – M/d/y},
				d => q{M/d/y – M/d/y},
				y => q{M/d/y – M/d/y},
			},
		},
		'gregorian' => {
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
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
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
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y},
				d => q{E, MMM d – E, MMM d, y},
				y => q{E, MMM d, y – E, MMM d, y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y},
				d => q{MMM d – d, y},
				y => q{MMM d, y – MMM d, y},
			},
			yMd => {
				M => q{M/d/y – M/d/y},
				d => q{M/d/y – M/d/y},
				y => q{M/d/y – M/d/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Isikhathi sase-{0}),
		regionFormat => q({0} Isikhathi sasemini),
		regionFormat => q({0} isikhathi esivamile),
		'Afghanistan' => {
			long => {
				'standard' => q#Isikhathi sase-Afghanistan#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#i-Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#i-Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#i-Addis Ababa#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#i-Algiers#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#i-Asmara#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#i-Bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#i-Bangui#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#i-Banjul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#i-Bissau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#i-Blantyre#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#i-Brazzaville#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#i-Bujumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#i-Cairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#i-Casablanca#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#i-Ceuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#i-Conakry#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#i-Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#i-Dar es Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#i-Djibouti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#i-Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#i-El Aaiun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#i-Freetown#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#i-Gaborone#,
		},
		'Africa/Harare' => {
			exemplarCity => q#i-Harare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#i-Johannesburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#iJuba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#i-Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#i-Khartoum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#i-Kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#i-Kinshasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#i-Lagos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#i-Libreville#,
		},
		'Africa/Lome' => {
			exemplarCity => q#i-Lome#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#i-Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#i-Lubumbashi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#iLusaka#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#iMalabo#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#iMaputo#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#iMaseru#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#iMbabane#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#i-Mogadishu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#i-Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#i-Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#i-Ndjamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#i-Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#i-Nouakchott#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#i-Ouagadougou#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#i-Porto-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#i-São Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#i-Tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#i-Tunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#i-Windhoek#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Isikhathi sase-Central Africa#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Isikhathi saseMpumalanga Afrika#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Isikhathi esivamile saseNingizimu Afrika#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Isikhathi sasehlobo saseNtshonalanga Afrika#,
				'generic' => q#Isikhathi saseNtshonalanga Afrika#,
				'standard' => q#Isikhathi esivamile saseNtshonalanga Afrika#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Isikhathi sase-Alaska sasemini#,
				'generic' => q#Isikhathi sase-Alaska#,
				'standard' => q#Isikhathi sase-Alaska esijwayelekile#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Isikhathi sase-Amazon sasehlobo#,
				'generic' => q#Isikhathi sase-Amazon#,
				'standard' => q#Isikhathi sase-Amazon esijwayelekile#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#i-Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#i-Anchorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#i-Anguilla#,
		},
		'America/Antigua' => {
			exemplarCity => q#i-Antigua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#i-Araguaina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#i-La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#i-Rio Gallegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#i-Salta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#i-San Juan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#i-San Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#i-Tucuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#i-Ushuaia#,
		},
		'America/Aruba' => {
			exemplarCity => q#i-Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#i-Asunción#,
		},
		'America/Bahia' => {
			exemplarCity => q#i-Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#i-Bahia Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#i-Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#i-Belem#,
		},
		'America/Belize' => {
			exemplarCity => q#i-Belize#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#i-Blanc-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#i-Boa Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#i-Bogota#,
		},
		'America/Boise' => {
			exemplarCity => q#i-Boise#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#i-Buenos Aires#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#i-Cambridge Bay#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#i-Campo Grande#,
		},
		'America/Cancun' => {
			exemplarCity => q#i-Cancun#,
		},
		'America/Caracas' => {
			exemplarCity => q#i-Caracas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#i-Catamarca#,
		},
		'America/Cayenne' => {
			exemplarCity => q#i-Cayenne#,
		},
		'America/Cayman' => {
			exemplarCity => q#i-Cayman#,
		},
		'America/Chicago' => {
			exemplarCity => q#i-Chicago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#i-Chihuahua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#i-Atikokan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#i-Cordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#i-Costa Rica#,
		},
		'America/Creston' => {
			exemplarCity => q#i-Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#i-Cuiaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#i-Curaçao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#i-Danmarkshavn#,
		},
		'America/Dawson' => {
			exemplarCity => q#i-Dawson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#i-Dawson Creek#,
		},
		'America/Denver' => {
			exemplarCity => q#i-Denver#,
		},
		'America/Detroit' => {
			exemplarCity => q#i-Detroit#,
		},
		'America/Dominica' => {
			exemplarCity => q#i-Dominica#,
		},
		'America/Edmonton' => {
			exemplarCity => q#i-Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#i-Eirunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#i-El Salvador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#i-Fort Nelson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#i-Fortaleza#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#i-Glace Bay#,
		},
		'America/Godthab' => {
			exemplarCity => q#i-Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#i-Goose Bay#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#i-Grand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#i-Grenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#i-Guadeloupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#i-Guatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#i-Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#i-Guyana#,
		},
		'America/Halifax' => {
			exemplarCity => q#i-Halifax#,
		},
		'America/Havana' => {
			exemplarCity => q#i-Havana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#i-Hermosillo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#i-Knox, Indiana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#i-Marengo, Indiana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#i-Petersburg, Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#i-Tell City, Indiana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#i-Vevay, Indiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#i-Vincennes, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#i-Winamac, Indiana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#i-Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#i-Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#i-Iqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#i-Jamaica#,
		},
		'America/Jujuy' => {
			exemplarCity => q#i-Jujuy#,
		},
		'America/Juneau' => {
			exemplarCity => q#i-Juneau#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#i-Monticello, Kentucky#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#i-Kralendijk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#i-La Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#i-Lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#i-Los Angeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#i-Louisville#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#i-Lower Prince’s Quarter#,
		},
		'America/Maceio' => {
			exemplarCity => q#i-Maceio#,
		},
		'America/Managua' => {
			exemplarCity => q#i-Managua#,
		},
		'America/Manaus' => {
			exemplarCity => q#i-Manaus#,
		},
		'America/Marigot' => {
			exemplarCity => q#i-Marigot#,
		},
		'America/Martinique' => {
			exemplarCity => q#i-Martinique#,
		},
		'America/Matamoros' => {
			exemplarCity => q#i-Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#i-Mazatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#i-Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#i-Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#i-Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#i-Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#i-Mexico City#,
		},
		'America/Miquelon' => {
			exemplarCity => q#i-Miquelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#i-Moncton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#i-Monterrey#,
		},
		'America/Montevideo' => {
			exemplarCity => q#i-Montevideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#i-Montserrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#i-Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#i-New York#,
		},
		'America/Nome' => {
			exemplarCity => q#i-Nome#,
		},
		'America/Noronha' => {
			exemplarCity => q#i-Noronha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#i-Beulah, North Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#i-Center, North Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#i-New Salem, North Dakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#i-Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#i-Panama#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#i-Paramaribo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#i-Phoenix#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#i-Port-au-Prince#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#i-Port of Spain#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#i-Porto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#i-Puerto Rico#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#i-Punta Arenas#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#i-Rankin Inlet#,
		},
		'America/Recife' => {
			exemplarCity => q#i-Recife#,
		},
		'America/Regina' => {
			exemplarCity => q#i-Regina#,
		},
		'America/Resolute' => {
			exemplarCity => q#i-Resolute#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#i-Rio Branco#,
		},
		'America/Santarem' => {
			exemplarCity => q#i-Santarem#,
		},
		'America/Santiago' => {
			exemplarCity => q#i-Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#i-Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#i-Sao Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#i-Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#i-Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#i-St. Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#i-St. John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#i-St. Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#I-St. Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#i-St. Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#i-St. Vincent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#i-Swift Current#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#i-Tegucigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#i-Thule#,
		},
		'America/Tijuana' => {
			exemplarCity => q#i-Tijuana#,
		},
		'America/Toronto' => {
			exemplarCity => q#i-Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#i-Tortola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#i-Vancouver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#i-Whitehorse#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#i-Winnipeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#i-Yakutat#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Isikhathi sase-North American Central sasemini#,
				'generic' => q#Isikhathi sase-North American Central#,
				'standard' => q#Isikhathi sase-North American Central esijwayelekile#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Isikhathi sase-North American East sasemini#,
				'generic' => q#Isikhathi sase-North American East#,
				'standard' => q#Isikhathi sase-North American East esijwayelekile#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Isikhathi sase-North American Mountain sasemini#,
				'generic' => q#Isikhathi sase-North American Mountain#,
				'standard' => q#Isikhathi sase-North American Mountain esijwayelekile#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Isikhathi sase-North American Pacific sasemini#,
				'generic' => q#Isikhathi sase-North American Pacific#,
				'standard' => q#Isikhathi sase-North American Pacific esijwayelekile#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#esase-Anadyr Summer Time#,
				'generic' => q#esase-Anadyr Time#,
				'standard' => q#esase-Anadyr Standard Time#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#i-Casey#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#i-Davis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#i-Dumont d’Urville#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#i-Macquarie#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#i-Mawson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#i-McMurdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#i-Palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#i-Rothera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#i-Syowa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#i-Troll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#i-Vostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Isikhathi sase-Apia sasemini#,
				'generic' => q#Isikhathi sase-Apia#,
				'standard' => q#Isikhathi sase-Apia esivamile#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Isikhathi semini sase-Arabian#,
				'generic' => q#Isikhathi sase-Arabian#,
				'standard' => q#Isikhathi esivamile sase-Arabian#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#i-Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Isikhathi sase-Argentina sasehlobo#,
				'generic' => q#Isikhathi sase-Argentina#,
				'standard' => q#Isikhathi sase-Argentina esijwayelekile#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Isikhathi saseNyakatho ne-Argentina sasehlobo#,
				'generic' => q#Isikhathi saseNyakatho ne-Argentina#,
				'standard' => q#Isikhathi saseNyakatho ne-Argentina esijwayelekile#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Isikhathi sehlobo sase-Armenia#,
				'generic' => q#Isikhathi saseArmenia#,
				'standard' => q#Isikhathi esivamile sase-Armenia#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#i-Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#i-Almaty#,
		},
		'Asia/Amman' => {
			exemplarCity => q#i-Amman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#i-Anadyr#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#i-Aqtau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#i-Aqtobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#i-Ashgabat#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#i-Baghdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#i-Bahrain#,
		},
		'Asia/Baku' => {
			exemplarCity => q#i-Baku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#i-Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#i-Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#i-Beirut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#i-Bishkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#i-Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#i-Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#i-Chita#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#i-Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#i-Damascus#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#i-Dhaka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#i-Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#i-Dubai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#i-Dushanbe#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#iGaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#i-Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#i-Hong Kong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#i-Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#i-Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#i-Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#i-Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#i-Jerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#i-Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#i-Kamchatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#i-Karachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#i-Kathmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#i-Khandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#i-Krasnoyarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#i-Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#i-Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#i-Kuwait#,
		},
		'Asia/Macau' => {
			exemplarCity => q#i-Macau#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#i-Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#i-Makassar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#i-Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#i-Muscat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#i-Nicosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#i-Novokuznetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#i-Novosibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#i-Omsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#i-Oral#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#i-Phnom Penh#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#i-Pontianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#i-Pyongyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#i-Qatar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#I-Kostanay#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#i-Qyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#i-Rangoon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#i-Riyadh#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#i-Ho Chi Minh City#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#i-Sakhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#i-Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#i-Seoul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#i-Shanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#i-Singapore#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#i-Srednekolymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#i-Taipei#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#i-Tashkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#i-Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#i-Tehran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#i-Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#i-Tokyo#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#i-Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#i-Ulaanbaatar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#i-Urumqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#i-Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#i-Vientiane#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#i-Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#i-Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#i-Yekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#i-Yerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Isikhathi sase-Atlantic sasemini#,
				'generic' => q#Isikhathi sase-Atlantic#,
				'standard' => q#Isikhathi sase-Atlantic esijwayelekile#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#i-Azores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#i-Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#i-Canary#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#i-Cape Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#i-Faroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#i-Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#i-Reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#i-South Georgia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#i-St. Helena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#i-Stanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#i-Adelaide#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#i-Brisbane#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#i-Broken Hill#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#i-Darwin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#i-Eucla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#i-Hobart#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#i-Lindeman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#i-Lord Howe#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#i-Melbourne#,
		},
		'Australia/Perth' => {
			exemplarCity => q#i-Perth#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#i-Sydney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Isikhathi sase-Australian Central sasemini#,
				'generic' => q#Isikhathi sase-Central Australia#,
				'standard' => q#Isikhathi sase-Australian Central esivamile#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Isikhathi sasemini sase-Australian Central West#,
				'generic' => q#Isikhathi sase-Australian Central West#,
				'standard' => q#Isikhathi sase-Australian Central West esivamile#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Isikhathi sasemini sase-Australian East#,
				'generic' => q#Isikhathi sase-Eastern Australia#,
				'standard' => q#Isikhathi esivamile sase-Australian East#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Isikhathi sase-Australian Western sasemini#,
				'generic' => q#Isikhathi sase-Western Australia#,
				'standard' => q#Isikhathi sase-Australian Western esivamile#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Isikhathi sehlobo sase-Azerbaijan#,
				'generic' => q#Isikhathi sase-Azerbaijan#,
				'standard' => q#Isikhathi esivamile sase-Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Isikhathi sasehlobo sase-Azores#,
				'generic' => q#Isikhathi sase-Azores#,
				'standard' => q#Isikhathi esijwayelekile sase-Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Isikhathi sase-Bangladesh sasehlobo#,
				'generic' => q#Isikhathi sase-Bangladesh#,
				'standard' => q#Isikhathi sase-Bangladesh esivamile#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Isikhathi sase-Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Isikhathi sase-Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Isikhathi sase-Brasilia sasehlobo#,
				'generic' => q#Isikhathi sase-Brasilia#,
				'standard' => q#Isikhathi sase-Brasilia esijwayelekile#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Isikhathi sase-Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Isikhathi sehlobo sase-Cape Verde#,
				'generic' => q#Isikhathi sase-Cape Verde#,
				'standard' => q#Isikhathi esezingeni sase-Cape Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Isikhathi esivamile sase-Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Isikhathi sasemini sase-Chatham#,
				'generic' => q#Isikhathi sase-Chatham#,
				'standard' => q#Isikhathi esivamile sase-Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Isikhathi sase-Chile sasehlobo#,
				'generic' => q#Isikhathi sase-Chile#,
				'standard' => q#Isikhathi sase-Chile esijwayelekile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Isikhathi semini sase-China#,
				'generic' => q#Isikhathi sase-China#,
				'standard' => q#Isikhathi esivamile sase-China#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Isikhathi sase-Christmas Island#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Isikhathi sase-Cocos Islands#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Isikhathi sase-Colombia sasehlobo#,
				'generic' => q#Isikhathi sase-Colombia#,
				'standard' => q#Isikhathi sase-Colombia esijwayelekile#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Isikhathi esiyingxenye yasehlobo sase-Cook Islands#,
				'generic' => q#Isikhathi sase-Cook Islands#,
				'standard' => q#Isikhathi esivamile sase-Cook Islands#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Isikhathi sase-Cuba sasemini#,
				'generic' => q#Isikhathi sase-Cuba#,
				'standard' => q#Isikhathi sase-Cuba esijwayelekile#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Isikhathi sase-Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Isikhathi sase-Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Isikhathi sase-East Timor#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Isikhathi sase-Easter Island sasehlobo#,
				'generic' => q#Isikhathi sase-Easter Island#,
				'standard' => q#Isikhathi sase-Easter Island esijwayelekile#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Isikhathi sase-Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#isikhathi somhlaba esididiyelwe#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#idolobha elingaziwa#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#i-Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#i-Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#i-Astrakhan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#i-Athens#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#i-Belgrade#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#i-Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#i-Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#i-Brussels#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#i-Bucharest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#i-Budapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#i-Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#i-Chisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#i-Copenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#i-Dublin#,
			long => {
				'daylight' => q#isikhathi sase-Irish esivamile#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#i-Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#i-Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#i-Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#i-Isle of Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#i-Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#i-Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#i-Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#i-Kiev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#i-Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#i-Lisbon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#i-Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#i-London#,
			long => {
				'daylight' => q#isikhathi sase-British sasehlobo#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#i-Luxembourg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#i-Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#i-Malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#i-Mariehamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#i-Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#i-Monaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#i-Moscow#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#i-Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#i-Paris#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#i-Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#i-Prague#,
		},
		'Europe/Riga' => {
			exemplarCity => q#i-Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#i-Rome#,
		},
		'Europe/Samara' => {
			exemplarCity => q#i-Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#i-San Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#i-Sarajevo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#i-Saratov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#i-Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#i-Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#i-Sofia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#i-Stockholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#i-Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#i-Tirane#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#i-Ulyanovsk#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#i-Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#i-Vatican#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#i-Vienna#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#i-Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#i-Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#i-Warsaw#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#i-Zagreb#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#i-Zurich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Isikhathi sasehlobo sase-Central Europe#,
				'generic' => q#Isikhathi sase-Central Europe#,
				'standard' => q#Isikhathi esijwayelekile sase-Central Europe#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Isikhathi sasehlobo sase-Eastern Europe#,
				'generic' => q#Isikhathi sase-Eastern Europe#,
				'standard' => q#Isikhathi esijwayelekile sase-Eastern Europe#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Isikhathi sase-Further-eastern Europe#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Isikhathi sasehlobo sase-Western Europe#,
				'generic' => q#Isikhathi sase-Western Europe#,
				'standard' => q#Isikhathi esijwayelekile sase-Western Europe#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Isikhathi sase-Falkland Islands sasehlobo#,
				'generic' => q#Isikhathi sase-Falkland Islands#,
				'standard' => q#Isikhathi sase-Falkland Islands esijwayelekile#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Isikhathi sehlobo sase-Fiji#,
				'generic' => q#Isikhathi sase-Fiji#,
				'standard' => q#Isikhathi esivamile sase-Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Isikhathi sase-French Guiana#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Isikhathi sase-French Southern nase-Antarctic#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Isikhathi sase-Greenwich Mean#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Isikhathi sase-Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Isikhathi sase-Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Isikhathi sehlobo sase-Georgia#,
				'generic' => q#Isikhathi sase-Georgia#,
				'standard' => q#Isikhathi esivamile sase-Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Isikhathi sase-Gilbert Islands#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Isikhathi sase-East Greenland sasemini#,
				'generic' => q#Isikhathi sase-East Greenland#,
				'standard' => q#Isikhathi sase-East Greenland esijwayelekile#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Isikhathi sase-West Greenland sasehlobo#,
				'generic' => q#Isikhathi sase-West Greenland#,
				'standard' => q#Isikhathi sase-West Greenland esijwayelekile#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Isikhathi esivamile sase-Gulf#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Isikhathi sase-Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Isikhathi sase-Hawaii-Aleutia sasemini#,
				'generic' => q#Isikhathi sase-Hawaii-Aleutia#,
				'standard' => q#Isikhathi sase-Hawaii-Aleutia esijwayelekile#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Isikhathi sehlobo sase-Hong Kong#,
				'generic' => q#Isikhathi sase-Hong Kong#,
				'standard' => q#Isikhathi esivamile sase-Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Isikhathi sehlobo e-Hovd#,
				'generic' => q#Isikhathi sase-Hovd#,
				'standard' => q#Isikhathi Esimisiwe sase-Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Isikhathi sase-India esivamile#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#i-Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#i-Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Ukhisimusi#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#i-Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#i-Comoro#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#i-Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#iMahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#i-Maldives#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#i-Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#i-Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#i-Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Isikhathi sase-Indian Ocean#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Isikhathi sase-Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Isikhathi sase-Central Indonesia#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Isikhathi sase-Eastern Indonesia#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Isikhathi sase-Western Indonesia#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Isikhathi sase-Iran sasemini#,
				'generic' => q#Isikhathi sase-Iran#,
				'standard' => q#Isikhathi sase-Iran esivamile#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Isikhathi sasehlobo e-Irkutsk#,
				'generic' => q#Isikhathi sase-Irkutsk#,
				'standard' => q#Isikhathi Esivamile sase-Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Isikhathi sasemini sakwa-Israel#,
				'generic' => q#Isikhathi sase-Israel#,
				'standard' => q#Isikhathi esivamile sase-Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Isikhathi semini sase-Japan#,
				'generic' => q#Isikhathi sase-Japan#,
				'standard' => q#Isikhathi esivamile sase-Japan#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#esase-Petropavlovsk-Kamchatski Summer Time#,
				'generic' => q#esase-Petropavlovsk-Kamchatski Time#,
				'standard' => q#esase-Petropavlovsk-Kamchatski Standard Time#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Isikhathi saseKazakhstan#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Isikhathi sase-Mpumalanga ne-Kazakhstan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Isikhathi saseNtshonalanga ne-Kazakhstan#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Isikhathi semini sase-Korea#,
				'generic' => q#Isikhathi sase-Korea#,
				'standard' => q#Isikhathi Esivamile sase-Korea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Isikhathi sase-Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Isikhathi sasehlobo e-Krasnoyarsk#,
				'generic' => q#Isikhathi sase-Krasnoyarsk#,
				'standard' => q#Isikhathi Esivamile sase-Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Isikhathi sase-Kyrgystan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Isikhathi sase-Line Islands#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Isikhathi sase-Lord Howe sasemini#,
				'generic' => q#Isikhathi sase-Lord Howe#,
				'standard' => q#Isikhathi sase-Lord Howe esivamile#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Isikhathi sasehlobo e-Magadan#,
				'generic' => q#Isikhathi sase-Magadan#,
				'standard' => q#Isikhathi Esivamile sase-Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Isikhathi sase-Malaysia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Isikhathi sase-Maldives#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Isikhathi sase-Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Isikhathi sase-Marshall Islands#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Isikhathi sehlobo sase-Mauritius#,
				'generic' => q#Isikhathi sase-Mauritius#,
				'standard' => q#Isikhathi esivamile sase-Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Isikhathi sase-Mawson#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Isikhathi sase-Mexican Pacific sasemini#,
				'generic' => q#Isikhathi sase-Mexican Pacific#,
				'standard' => q#Isikhathi sase-Mexican Pacific esijwayelekile#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Isikhathi sehlobo e-Ulan Bator#,
				'generic' => q#Isikhathi sase-Ulan Bator#,
				'standard' => q#Isikhathi Esimisiwe sase-Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Isikhathi sasehlobo e-Moscow#,
				'generic' => q#Isikhathi sase-Moscow#,
				'standard' => q#Isikhathi sase-Moscow esijwayelekile#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Isikhathi sase-Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Isikhathi sase-Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Isikhathi sase-Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Isikhathi sase-New Caledonia sasehlobo#,
				'generic' => q#Isikhathi sase-New Caledonia#,
				'standard' => q#Isikhathi sase-New Caledonia esivamile#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Isikhathi sasemini sase-New Zealand#,
				'generic' => q#Isikhathi sase-New Zealand#,
				'standard' => q#Isikhathi esivamile sase-New Zealand#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Isikhathi sase-Newfoundland sasemini#,
				'generic' => q#Isikhathi sase-Newfoundland#,
				'standard' => q#Isikhathi sase-Newfoundland esijwayelekile#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Isikhathi sase-Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Isikhathi sase-Norfolk Islands sasehlobo#,
				'generic' => q#Isikhathi sase-Norfolk Islands#,
				'standard' => q#Isikhathi sase-Norfolk Islands esivamile#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Isikhathi sase-Fernando de Noronha sasehlobo#,
				'generic' => q#Isikhathi sase-Fernando de Noronha#,
				'standard' => q#Isikhathi sase-Fernando de Noronha esivamile#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Isikhathi sasehlobo sase-Novosibirsk#,
				'generic' => q#Isikhathi sase-Novosibirsk#,
				'standard' => q#Isikhathi Esivamile sase-Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Isikhathi sasehlobo sase-Omsk#,
				'generic' => q#Isikhathi sase-Omsk#,
				'standard' => q#Isikhathi Esivamile sase-Omsk#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#i-Apia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#i-Auckland#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#i-Bougainville#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#i-Chatham#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#i-Easter#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#i-Efate#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#i-Enderbury#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#i-Fakaofo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#i-Fiji#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#i-Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#i-Galapagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#i-Gambier#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#i-Guadalcanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#i-Guam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#i-Honolulu#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#i-Kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#i-Kosrae#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#i-Kwajalein#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#i-Majuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#i-Marquesas#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#i-Midway#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#i-Nauru#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#i-Niue#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#i-Norfolk#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#i-Noumea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#i-Pago Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#i-Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#i-Pitcairn#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#i-Pohnpei#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#i-Port Moresby#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#i-Rarotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#i-Saipan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#i-Tahiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#i-Tarawa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#i-Tongatapu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#i-Chuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#i-Wake#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#i-Wallis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Isikhathi sase-Pakistan sasehlobo#,
				'generic' => q#Isikhathi sase-Pakistan#,
				'standard' => q#Isikhathi sase-Pakistan esivamile#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Isikhathi sase-Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Isikhathi sase-Papua New Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Isikhathi sase-Paraguay sasehlobo#,
				'generic' => q#Isikhathi sase-Paraguay#,
				'standard' => q#Isikhathi sase-Paraguay esivamile#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Isikhathi sase-Peru sasehlobo#,
				'generic' => q#Isikhathi sase-Peru#,
				'standard' => q#Isikhathi sase-Peru esivamile#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Isikhathi sehlobo sase-Philippine#,
				'generic' => q#Isikhathi sase-Philippine#,
				'standard' => q#Isikhathi esivamile sase-Philippine#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Isikhathi sase-Phoenix Islands#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Isikhathi sase-Saint Pierre nase-Miquelon sasemini#,
				'generic' => q#Isikhathi sase-Saint Pierre nase-Miquelon#,
				'standard' => q#Iikhathi sase-Saint Pierre nase-Miquelon esijwayelekile#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Isikhathi sase-Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Isikhathi sase-Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Isikhathi sase-Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Isikhathi sase-Reunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Isikhathi sase-Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Isikhathi sasehlobo e-Sakhalin#,
				'generic' => q#Isikhathi sase-Sakhalin#,
				'standard' => q#Isikhathi Esivamile sase-Sakhalin#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#esase-Samara Summer Time#,
				'generic' => q#esase-Samara Time#,
				'standard' => q#esase-Samara Standard Time#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Isikhathi sase-Samoa sasemini#,
				'generic' => q#Isikhathi sase-Samoa#,
				'standard' => q#Isikhathi sase-Samoa esivamile#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Isikhathi sase-Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Isikhathi esivamile sase-Singapore#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Isikhathi sase-Solomon Islands#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Isikhathi sase-South Georgia#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Isikhathi sase-Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Isikhathi sase-Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Isikhathi sase-Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Isikhathi semini sase-Taipei#,
				'generic' => q#Isikhathi sase-Taipei#,
				'standard' => q#Isikhathi esivamile sase-Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Isikhathi sase-Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Isikhathi sase-Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Isikhathi sase-Tonga sasehlobo#,
				'generic' => q#Isikhathi sase-Tonga#,
				'standard' => q#Isikhathi sase-Tonga esivamile#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Isikhathi sase-Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Isikhathi sehlobo sase-Turkmenistan#,
				'generic' => q#Isikhathi sase-Turkmenistan#,
				'standard' => q#Isikhathi esivamile sase-Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Isikhathi sase-Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Isikhathi sase-Uruguay sasehlobo#,
				'generic' => q#Isikhathi sase-Uruguay#,
				'standard' => q#Isikhathi sase-Uruguay esijwayelekile#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Isikhathi sehlobo sase-Uzbekistan#,
				'generic' => q#Isikhathi sase-Uzbekistan#,
				'standard' => q#Isikhathi esivamile sase-Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Isikhathi sase-Vanuatu sasehlobo#,
				'generic' => q#Isikhathi sase-Vanuatu#,
				'standard' => q#Isikhathi sase-Vanuatu esijwayelekile#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Isikhathi sase-Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Isikhathi sasehlobo e-Vladivostok#,
				'generic' => q#Isikhathi sase-Vladivostok#,
				'standard' => q#Isikhathi Esivamile sase-Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Isikhathi sase-Volgograd sasehlobo#,
				'generic' => q#Isikhathi sase-Volgograd#,
				'standard' => q#Isikhathi Esivamile sase-Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Isikhathi sase-Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Isikhathi sase-Wake Island#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Isikhathi sase-Wallis nase-Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Isikhathi sasehlobo e-Yakutsk#,
				'generic' => q#Isikhathi sase-Yakutsk#,
				'standard' => q#Isikhathi Esivamile sase-Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Isikhathi sasehlobo e-Yekaterinburg#,
				'generic' => q#Isikhathi sase-Yekaterinburg#,
				'standard' => q#Isikhathi Esivamile sase-Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukon Time#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
