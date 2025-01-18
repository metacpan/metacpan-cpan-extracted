=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ig - Package for language Igbo

=cut

package Locale::CLDR::Locales::Ig;
# This file auto generated from Data\common\main\ig.xml
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
				'aa' => 'Afar',
 				'ab' => 'Abkaziani',
 				'ace' => 'Achinisi',
 				'ada' => 'Adangme',
 				'ady' => 'Adigi',
 				'af' => 'Afrikaans',
 				'agq' => 'Aghem',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'ale' => 'Aleut',
 				'alt' => 'Southern Altai',
 				'am' => 'Amariikị',
 				'an' => 'Aragonisị',
 				'ann' => 'Obolo',
 				'anp' => 'Angika',
 				'apc' => 'apcc',
 				'ar' => 'Arabiikị',
 				'ar_001' => 'Ụdị Arabiikị nke oge a',
 				'arn' => 'Mapuche',
 				'arp' => 'Arapaho',
 				'ars' => 'Najdi Arabikị',
 				'as' => 'Asamisị',
 				'asa' => 'Asụ',
 				'ast' => 'Asturianị',
 				'atj' => 'Atikamekw',
 				'av' => 'Avarịk',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Azerbaijani',
 				'az@alt=short' => 'Azeri',
 				'ba' => 'Bashkir',
 				'bal' => 'Baluchi',
 				'ban' => 'Balinese',
 				'bas' => 'Basaà',
 				'be' => 'Belarusian',
 				'bem' => 'Bembà',
 				'bew' => 'Betawi',
 				'bez' => 'Bena',
 				'bg' => 'Bulgarian',
 				'bgc' => 'Haryanvi',
 				'bgn' => 'Western Balochi',
 				'bho' => 'Bojpuri',
 				'bi' => 'Bislama',
 				'bin' => 'Bini',
 				'bla' => 'Siksikà',
 				'blo' => 'Anii',
 				'blt' => 'Tai Dam',
 				'bm' => 'Bambara',
 				'bn' => 'Bangla',
 				'bo' => 'Tibetan',
 				'br' => 'Breton',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnian',
 				'bss' => 'Akoose',
 				'bug' => 'Buginese',
 				'byn' => 'Blin',
 				'ca' => 'Catalan',
 				'cad' => 'Caddo',
 				'cay' => 'Cayuga',
 				'cch' => 'Atsam',
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
 				'chy' => 'Cheyene',
 				'cic' => 'Chickasaw',
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
 				'cs' => 'Czech',
 				'csw' => 'Asụsụ Swampy Kree',
 				'cu' => 'Church slavic',
 				'cv' => 'Chuvash',
 				'cy' => 'Welsh',
 				'da' => 'Danish',
 				'dak' => 'Dakota',
 				'dar' => 'Dargwa',
 				'dav' => 'Taita',
 				'de' => 'German',
 				'de_AT' => 'Austrian German',
 				'de_CH' => 'Swiss High German',
 				'dgr' => 'Dogrib',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Lower Sorbian',
 				'dua' => 'Duala',
 				'dv' => 'Divehi',
 				'dyo' => 'Jola-Fonyi',
 				'dz' => 'Dọzngọka',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'eka' => 'Ekajuk',
 				'el' => 'Grik',
 				'en' => 'Bekee',
 				'en_AU' => 'Bekee ndị Australia',
 				'en_CA' => 'Bekee ndị Canada',
 				'en_GB' => 'Bekee ndị United Kingdom',
 				'en_GB@alt=short' => 'Bekee ndị UK',
 				'en_US' => 'Bekee ndị America',
 				'en_US@alt=short' => 'Bekee ndị US',
 				'eo' => 'Esperanto',
 				'es' => 'Spanish',
 				'es_419' => 'Spanish ndị Latin America',
 				'es_ES' => 'Spanish ndị Europe',
 				'es_MX' => 'Spanish ndị Mexico',
 				'et' => 'Estonian',
 				'eu' => 'Basque',
 				'ewo' => 'Ewondo',
 				'fa' => 'Asụsụ Persia',
 				'fa_AF' => 'Dari',
 				'ff' => 'Fula',
 				'fi' => 'Finnish',
 				'fil' => 'Filipino',
 				'fj' => 'Fijanị',
 				'fo' => 'Faroese',
 				'fon' => 'Fon',
 				'fr' => 'French',
 				'fr_CA' => 'Canadian French',
 				'fr_CH' => 'Swiss French',
 				'frc' => 'Cajun French',
 				'frr' => 'Northern Frisian',
 				'fur' => 'Friulian',
 				'fy' => 'Ọdịda anyanwụ Frisian',
 				'ga' => 'Irish',
 				'gaa' => 'Ga',
 				'gd' => 'Asụsụ Scottish Gaelic',
 				'gez' => 'Geez',
 				'gil' => 'Gilbertese',
 				'gl' => 'Galician',
 				'gn' => 'Guarani',
 				'gor' => 'Gorontalo',
 				'gsw' => 'German Swiss',
 				'gu' => 'Gujarati',
 				'guz' => 'Gusii',
 				'gv' => 'Mansị',
 				'gwi' => 'Gwichʼin',
 				'ha' => 'Hausa',
 				'hai' => 'Haida',
 				'haw' => 'Hawaịlịan',
 				'hax' => 'Southern Haida',
 				'he' => 'Hebrew',
 				'hi' => 'Hindi',
 				'hi_Latn@alt=variant' => 'Hinglish',
 				'hil' => 'Hiligayanon',
 				'hmn' => 'Hmong',
 				'hnj' => 'Hmong Njua',
 				'hr' => 'Croatian',
 				'hsb' => 'Upper Sorbian',
 				'ht' => 'Haịtịan ndị Cerọle',
 				'hu' => 'Hungarian',
 				'hup' => 'Hupa',
 				'hur' => 'Halkomelem',
 				'hy' => 'Armenianị',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Indonesian',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Sichuan Yi',
 				'ikt' => 'Westarn Canadian Inuktitut',
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
 				'kaa' => 'Kara-Kalpak',
 				'kab' => 'Kabyle',
 				'kac' => 'Kachin',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kbd' => 'Kabadian',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Kabụverdịanụ',
 				'ken' => 'Kenyang',
 				'kfo' => 'Koro',
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
 				'kok' => 'Konkani',
 				'kpe' => 'Kpelle',
 				'kr' => 'Kanuri',
 				'krc' => 'Karachay-Balkar',
 				'krl' => 'Karelian',
 				'kru' => 'Kurukh',
 				'ks' => 'Kashmiri',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafịa',
 				'ksh' => 'Colognian',
 				'ku' => 'Kurdish',
 				'kum' => 'Kumik',
 				'kv' => 'Komi',
 				'kw' => 'Cornish',
 				'kwk' => 'Kwakʼwala',
 				'kxv' => 'Kuvi',
 				'ky' => 'Kyrgyz',
 				'la' => 'Latin',
 				'lad' => 'Ladino',
 				'lag' => 'Langị',
 				'lb' => 'Luxembourgish',
 				'lez' => 'Lezghian',
 				'lg' => 'Ganda',
 				'li' => 'Limburgish',
 				'lij' => 'Ligurian',
 				'lil' => 'Liloetị',
 				'lkt' => 'Lakota',
 				'lld' => 'ID',
 				'lmo' => 'Lombard',
 				'ln' => 'Lingala',
 				'lo' => 'Lao',
 				'lou' => 'Louisiana Creole',
 				'loz' => 'Lozi',
 				'lrc' => 'Northern Luri',
 				'lsm' => 'Saamia',
 				'lt' => 'Lithuanian',
 				'ltg' => 'Latgalian',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lun' => 'Lunda',
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
 				'mgo' => 'Meta',
 				'mh' => 'Marshallese',
 				'mhn' => 'mhnn',
 				'mi' => 'Māori',
 				'mic' => 'Mi\'kmaw',
 				'min' => 'Minangkabau',
 				'mk' => 'Macedonian',
 				'ml' => 'Malayalam',
 				'mn' => 'Mọngolịan',
 				'mni' => 'Asụsụ Manipuri',
 				'moe' => 'Innu-aimun',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Asụsụ Marathi',
 				'ms' => 'Malay',
 				'mt' => 'Asụsụ Malta',
 				'mua' => 'Mundang',
 				'mul' => 'Ọtụtụ asụsụ',
 				'mus' => 'Muscogee',
 				'mwl' => 'Mirandese',
 				'my' => 'Burmese',
 				'myv' => 'Erzya',
 				'mzn' => 'Mazanderani',
 				'na' => 'Nauru',
 				'nap' => 'Neapolitan',
 				'naq' => 'Nama',
 				'nb' => 'Norwegian Bokmål',
 				'nd' => 'North Ndebele',
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
 				'nso' => 'Northern Sotho',
 				'nus' => 'Nuer',
 				'nv' => 'Navajo',
 				'ny' => 'Nyanja',
 				'nyn' => 'Nyankole',
 				'oc' => 'Asụsụ Osịtan',
 				'ojb' => 'Northwestern Ojibwa',
 				'ojc' => 'Central Ojibwa',
 				'ojs' => 'Oji-Cree',
 				'ojw' => 'Westarn Ojibwa',
 				'oka' => 'Okanagan',
 				'om' => 'Oromo',
 				'or' => 'Ọdịa',
 				'os' => 'Ossetic',
 				'osa' => 'Osage',
 				'pa' => 'Punjabi',
 				'pag' => 'Pangasinan',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiamento',
 				'pau' => 'Palauan',
 				'pcm' => 'Pidgin ndị Naijirịa',
 				'pis' => 'Pijin',
 				'pl' => 'Asụsụ Polish',
 				'pqm' => 'Maliseet-Passamaquoddy',
 				'prg' => 'Prụssịan',
 				'ps' => 'Pashọ',
 				'pt' => 'Pọrtụgụese',
 				'pt_BR' => 'Asụsụ Portugese ndị Brazil',
 				'pt_PT' => 'Asụsụ Portuguese ndị Europe',
 				'qu' => 'Asụsụ Quechua',
 				'quc' => 'Kʼicheʼ',
 				'raj' => 'Rajastani',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotongan',
 				'rhg' => 'Rohingya',
 				'rif' => 'Riffian',
 				'rm' => 'Asụsụ Romansh',
 				'rn' => 'Rundi',
 				'ro' => 'Asụsụ Romanian',
 				'ro_MD' => 'Moldavian',
 				'rof' => 'Rombo',
 				'ru' => 'Asụsụ Russia',
 				'rup' => 'Aromanian',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Asụsụ Sanskrit',
 				'sad' => 'Sandawe',
 				'sah' => 'Yakut',
 				'saq' => 'Samburu',
 				'sat' => 'Asụsụ Santali',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Asụsụ Sardini',
 				'scn' => 'Sicilian',
 				'sco' => 'Scots',
 				'sd' => 'Asụsụ Sindhi',
 				'sdh' => 'Southern Kurdish',
 				'se' => 'Northern Sami',
 				'seh' => 'Sena',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'shi' => 'Tachịkịt',
 				'shn' => 'Shan',
 				'si' => 'Sinhala',
 				'sid' => 'Sidamo',
 				'sk' => 'Asụsụ Slovak',
 				'skr' => 'skrr',
 				'sl' => 'Asụsụ Slovenia',
 				'slh' => 'Southern Lushootseed',
 				'sm' => 'Samoan',
 				'sma' => 'Southern Sami',
 				'smj' => 'Lule Sami',
 				'smn' => 'Inari Sami',
 				'sms' => 'Skolt sami',
 				'sn' => 'Shona',
 				'snk' => 'Soninke',
 				'so' => 'Somali',
 				'sq' => 'Asụsụ Albania',
 				'sr' => 'Asụsụ Serbia',
 				'srn' => 'Sranan Tongo',
 				'ss' => 'Swati',
 				'ssy' => 'Saho',
 				'st' => 'Southern Sotho',
 				'str' => 'Straits Salish',
 				'su' => 'Asụsụ Sundan',
 				'suk' => 'Sukuma',
 				'sv' => 'Sụwidiishi',
 				'sw' => 'Asụsụ Swahili',
 				'swb' => 'Comorian',
 				'syr' => 'Sirịak',
 				'szl' => 'Asụsụ Sileshia',
 				'ta' => 'Tamil',
 				'tce' => 'Southern Tutchone',
 				'te' => 'Telugu',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'tet' => 'Tetum',
 				'tg' => 'Tajik',
 				'tgx' => 'Tagish',
 				'th' => 'Thai',
 				'tht' => 'Tahitan',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tk' => 'Turkmen',
 				'tlh' => 'Klingon',
 				'tli' => 'Tlingit',
 				'tn' => 'Tswana',
 				'to' => 'Tongan',
 				'tok' => 'Toki Pona',
 				'tpi' => 'Tok pisin',
 				'tr' => 'Turkish',
 				'trv' => 'Taroko',
 				'trw' => 'Torwali',
 				'ts' => 'Tsonga',
 				'tt' => 'Asụsụ Tatar',
 				'ttm' => 'Northern Tutchone',
 				'tum' => 'Tumbuka',
 				'tvl' => 'Tuvalu',
 				'twq' => 'Tasawaq',
 				'ty' => 'Tahitian',
 				'tyv' => 'Tuvinian',
 				'tzm' => 'Central Atlas Tamazight',
 				'udm' => 'Udmurt',
 				'ug' => 'Uyghur',
 				'uk' => 'Asụsụ Ukrain',
 				'umb' => 'Umbundu',
 				'und' => 'Asụsụ a na-amaghị',
 				'ur' => 'Urdu',
 				'uz' => 'Uzbek',
 				've' => 'Venda',
 				'vec' => 'Asụsụ Veneshia',
 				'vi' => 'Vietnamese',
 				'vmw' => 'Makhuwa',
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
 				'xnr' => 'Kangri',
 				'xog' => 'Soga',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Yiddish',
 				'yo' => 'Yoruba',
 				'yrl' => 'Asụsụ Nheengatu',
 				'yue' => 'Cantonese',
 				'yue@alt=menu' => 'Chaịniiz,Cantonese',
 				'za' => 'Zhuang',
 				'zgh' => 'Standard Moroccan Tamazight',
 				'zh' => 'Chaịniiz',
 				'zh@alt=menu' => 'Chaịniiz, Mandarin',
 				'zh_Hans' => 'Asụsụ Chaịniiz dị mfe',
 				'zh_Hans@alt=long' => 'Asụsụ Mandarin Chaịniiz dị mfe',
 				'zh_Hant' => 'Asụsụ ọdịnala Chaịniiz',
 				'zh_Hant@alt=long' => 'Asụsụ ọdịnala Mandarin Chaịniiz',
 				'zu' => 'Zulu',
 				'zun' => 'Zuni',
 				'zxx' => 'Enweghị asụsụ dịnaya',
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
 			'Aghb' => 'Caucasian Albanian',
 			'Arab' => 'Mkpụrụ Okwu Arabic',
 			'Aran' => 'Nastaliq',
 			'Armi' => 'Imperial Aramaic',
 			'Armn' => 'Mkpụrụ ọkwụ Armenịan',
 			'Avst' => 'Avestan',
 			'Bali' => 'Balinese',
 			'Bamu' => 'Bamum',
 			'Bass' => 'Bassa Vah',
 			'Batk' => 'Batak',
 			'Beng' => 'Mkpụrụ ọkwụ Bangla',
 			'Bhks' => 'Bhaiksuki',
 			'Bopo' => 'Mkpụrụ ọkwụ Bopomofo',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Braille',
 			'Bugi' => 'Buginese',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Unified Canadian Aboriginal Syllabics',
 			'Cari' => 'Carian',
 			'Cher' => 'Cherokee',
 			'Chrs' => 'Chorasmian',
 			'Copt' => 'Coptic',
 			'Cpmn' => 'Cypro-Minoan',
 			'Cprt' => 'Cypriot',
 			'Cyrl' => 'Cyrillic',
 			'Cyrs' => 'Old Church Slavonic Cyrillic',
 			'Deva' => 'Mkpụrụ ọkwụ Devangarị',
 			'Diak' => 'Dives Akuru',
 			'Dogr' => 'Dogra',
 			'Dsrt' => 'Deseret',
 			'Dupl' => 'Duployan shorthand',
 			'Egyp' => 'Egyptian hieroglyphs',
 			'Elba' => 'Elbasan',
 			'Elym' => 'Elymaic',
 			'Ethi' => 'Mkpụrụ ọkwụ Etọpịa',
 			'Gara' => 'Garay',
 			'Geor' => 'Mkpụrụ ọkwụ Geọjịan',
 			'Glag' => 'Glagolitic',
 			'Gong' => 'Gunjala Gondi',
 			'Gonm' => 'Masaram Gondi',
 			'Goth' => 'Gothic',
 			'Gran' => 'Grantha',
 			'Grek' => 'Mkpụrụ ọkwụ grịk',
 			'Gujr' => 'Mkpụrụ ọkwụ Gụjaratị',
 			'Gukh' => 'Gurung Khema',
 			'Guru' => 'Mkpụrụ ọkwụ Gụrmụkị',
 			'Hanb' => 'Han na Bopomofo',
 			'Hang' => 'Mkpụrụ ọkwụ Hangụl',
 			'Hani' => 'Mkpụrụ ọkwụ Han',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'Nke dị mfe',
 			'Hans@alt=stand-alone' => 'Han di mfe',
 			'Hant' => 'Omenala',
 			'Hant@alt=stand-alone' => 'Han site na omenala',
 			'Hatr' => 'Hatran',
 			'Hebr' => 'Mkpụrụ ọkwụ Hebrew',
 			'Hira' => 'Mkpụrụ okwụ Hịragana',
 			'Hluw' => 'Anatolian Hieroglyphs',
 			'Hmng' => 'Pahawh Hmong',
 			'Hmnp' => 'Nyiakeng Puachue Hmong',
 			'Hrkt' => 'mkpụrụ ọkwụ Japanịsị',
 			'Hung' => 'Old Hungarian',
 			'Ital' => 'Old Italic',
 			'Java' => 'Javanese',
 			'Jpan' => 'Japanese',
 			'Kali' => 'Kayah Li',
 			'Kana' => 'Katakana',
 			'Kawi' => 'KAWI',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Khmer',
 			'Khoj' => 'Khojki',
 			'Kits' => 'Khitan small script',
 			'Knda' => 'Kannada',
 			'Kore' => 'Korean',
 			'Krai' => 'Kirat Rai',
 			'Kthi' => 'Kaithi',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Lao',
 			'Latf' => 'Fraktur Latin',
 			'Latg' => 'Gaelic Latin',
 			'Latn' => 'Latin',
 			'Lepc' => 'Lepcha',
 			'Limb' => 'Limbu',
 			'Lina' => 'Linear A',
 			'Linb' => 'Linear B',
 			'Lisu' => 'Fraser',
 			'Lyci' => 'Lycian',
 			'Lydi' => 'Lydian',
 			'Mahj' => 'Mahajani',
 			'Maka' => 'Makasar',
 			'Mand' => 'Mandaean',
 			'Mani' => 'Manichaean',
 			'Marc' => 'Marchen',
 			'Medf' => 'Medefaidrin',
 			'Mend' => 'Mende',
 			'Merc' => 'Meroitic Cursive',
 			'Mero' => 'Meroitic',
 			'Mlym' => 'Malayalam',
 			'Mong' => 'Mongolian',
 			'Mroo' => 'Mro',
 			'Mtei' => 'Meitei Mayek',
 			'Mult' => 'Multani',
 			'Mymr' => 'Myanmar',
 			'Nagm' => 'Nag Mundari',
 			'Nand' => 'Nandinagari',
 			'Narb' => 'Old North Arabian',
 			'Nbat' => 'Nabataean',
 			'Nkoo' => 'N’Ko',
 			'Nshu' => 'Nüshu',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Ol Chiki',
 			'Onao' => 'Ol Onal',
 			'Orkh' => 'Orkhon',
 			'Orya' => 'Odia',
 			'Osge' => 'Osage',
 			'Osma' => 'Osmanya',
 			'Ougr' => 'Old Uyghur',
 			'Palm' => 'Palmyrene',
 			'Pauc' => 'Pau Cin Hau',
 			'Perm' => 'Old Permic',
 			'Phag' => 'Phags-pa',
 			'Phli' => 'Inscriptional Pahlavi',
 			'Phlp' => 'Psalter Pahlavi',
 			'Phnx' => 'Phoenician',
 			'Plrd' => 'Pollard Phonetic',
 			'Prti' => 'Inscriptional Parthian',
 			'Qaag' => 'Zawgyi',
 			'Rjng' => 'Rejang',
 			'Rohg' => 'Hanifi',
 			'Runr' => 'Runic',
 			'Samr' => 'Samaritan',
 			'Sarb' => 'Old South Arabian',
 			'Saur' => 'Saurashtra',
 			'Sgnw' => 'SignWriting',
 			'Shaw' => 'Shavian',
 			'Shrd' => 'Sharada',
 			'Sidd' => 'Siddham',
 			'Sind' => 'Khudawadi',
 			'Sinh' => 'Sinhala',
 			'Sogd' => 'Sogdian',
 			'Sogo' => 'Old Sogdian',
 			'Sora' => 'Sora Sompeng',
 			'Soyo' => 'Soyombo',
 			'Sund' => 'Sundanese',
 			'Sunu' => 'Sunuwar',
 			'Sylo' => 'Syloti Nagri',
 			'Syrc' => 'Siriak',
 			'Syre' => 'Estrangelo Syriac',
 			'Syrj' => 'Western Syriac',
 			'Syrn' => 'Eastern Syriac',
 			'Tagb' => 'Tagbanwa',
 			'Takr' => 'Takri',
 			'Tale' => 'Tai Le',
 			'Talu' => 'New Tai Lue',
 			'Taml' => 'Tamil',
 			'Tang' => 'Tangut',
 			'Tavt' => 'Tai Viet',
 			'Telu' => 'Telugu',
 			'Tfng' => 'Tifinagh',
 			'Tglg' => 'Tagalog',
 			'Thaa' => 'Thaana',
 			'Tibt' => 'Tibetan',
 			'Tirh' => 'Tirhuta',
 			'Tnsa' => 'Tangsa',
 			'Todr' => 'Todhri',
 			'Tutg' => 'Tulu-Tigalari',
 			'Ugar' => 'Ugaritic',
 			'Vaii' => 'Vai',
 			'Vith' => 'Vithkuqi',
 			'Wara' => 'Varang Kshiti',
 			'Wcho' => 'Wancho',
 			'Xpeo' => 'Old Persian',
 			'Xsux' => 'Sumero-Akkadian Cuneiform',
 			'Yezi' => 'Yezidi',
 			'Yiii' => 'Yi',
 			'Zanb' => 'Zanabazar Square',
 			'Zinh' => 'Inherited',
 			'Zmth' => 'Mkpụrụ ọkwụ Mgbakọ',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Akara',
 			'Zxxx' => 'A na-edeghị ede',
 			'Zyyy' => 'Common',
 			'Zzzz' => 'Edemede a na-amaghi',

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
			'001' => 'Uwa',
 			'002' => 'Afrika',
 			'003' => 'Mpaghara Ugwu Amerịka',
 			'005' => 'Mpaghara Mgbada Ugwu America',
 			'009' => 'Oceania',
 			'011' => 'Mpaghara Ọdịda Anyanwụ Afrịka',
 			'013' => 'Etiti America',
 			'014' => 'Mpaghara Ọwụwa Anyanwụ Afrịka',
 			'015' => 'Mpaghara Ugwu Afrịka',
 			'017' => 'Etiti Afrịka',
 			'018' => 'Mpaghara Mgbada Ugwu Afrịka',
 			'019' => 'Amerịka',
 			'021' => 'Mpaghara Ugwu America',
 			'029' => 'Caribbean',
 			'030' => 'Mpaghara Ọwụwa Anyanwụ Asia',
 			'034' => 'Mpaghara Mgbada Ugwu Asia',
 			'035' => 'Mpaghara Mgbada Ugwu Asia dị na Ọwụwa Anyanwụ',
 			'039' => 'Mpaghara Mgbada Ugwu Europe',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Mpaghara Micronesian',
 			'061' => 'Polynesia',
 			'142' => 'Asia',
 			'143' => 'Etiti Asia',
 			'145' => 'Mpaghara Ọdịda Anyanwụ Asia',
 			'150' => 'Europe',
 			'151' => 'Mpaghara Ọwụwa Anyanwụ Europe',
 			'154' => 'Mpaghara Ugwu Europe',
 			'155' => 'Mpaghara Ọdịda Anyanwụ Europe',
 			'202' => 'Sub-Saharan Afrịka',
 			'419' => 'Latin America',
 			'AC' => 'Ascension Island',
 			'AD' => 'Andorra',
 			'AE' => 'United Arab Emirates',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua na Barbuda',
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
 			'BA' => 'Bosnia & Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgium',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthélemy',
 			'BM' => 'Bemuda',
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
 			'CC' => 'Agwaetiti Cocos (Keeling)',
 			'CD' => 'Congo - Kinshasa',
 			'CD@alt=variant' => 'Congo (DRC)',
 			'CF' => 'Central African Republik',
 			'CG' => 'Congo',
 			'CG@alt=variant' => 'Congo (Republik)',
 			'CH' => 'Switzerland',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Ivory Coast',
 			'CK' => 'Agwaetiti Cook',
 			'CL' => 'Chile',
 			'CM' => 'Cameroon',
 			'CN' => 'China',
 			'CO' => 'Colombia',
 			'CP' => 'Agwaetiti Clipperton',
 			'CQ' => 'Sark',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Cuba',
 			'CV' => 'Cape Verde',
 			'CW' => 'Kurakao',
 			'CX' => 'Agwaetiti Christmas',
 			'CY' => 'Cyprus',
 			'CZ' => 'Czechia',
 			'CZ@alt=variant' => 'Czech Republik',
 			'DE' => 'Germany',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Denmark',
 			'DM' => 'Dominica',
 			'DO' => 'Dominican Republik',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta & Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egypt',
 			'EH' => 'Ọdịda Anyanwụ Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spain',
 			'ET' => 'Ethiopia',
 			'EU' => 'Otu nzukọ mba Europe',
 			'EZ' => 'Gburugburu Euro',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Falkland Islands',
 			'FK@alt=variant' => 'Falkland Islands (Islas Malvinas)',
 			'FM' => 'Micronesia',
 			'FO' => 'Faroe Islands',
 			'FR' => 'France',
 			'GA' => 'Gabon',
 			'GB' => 'United Kingdom',
 			'GB@alt=short' => 'UK',
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
 			'HM' => 'Agwaetiti Heard na Agwaetiti McDonald',
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
 			'IO' => 'British Indian Ocean Territory',
 			'IO@alt=chagos' => 'Chagos Archipelago',
 			'IQ' => 'Iraq',
 			'IR' => 'Iran',
 			'IS' => 'Iceland',
 			'IT' => 'Italy',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordan',
 			'JP' => 'Japan',
 			'KE' => 'Kenya',
 			'KG' => 'Kyrgyzstan',
 			'KH' => 'Cambodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoros',
 			'KN' => 'St. Kitts & Nevis',
 			'KP' => 'North Korea',
 			'KR' => 'South Korea',
 			'KW' => 'Kuwait',
 			'KY' => 'Cayman Islands',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Lebanon',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lithuania',
 			'LU' => 'Luxembourg',
 			'LV' => 'Latvia',
 			'LY' => 'Libia',
 			'MA' => 'Morocco',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Agwaetiti Marshall',
 			'MK' => 'North Macedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macao SAR China',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Agwaetiti Northern Mariana',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldivesa',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibia',
 			'NC' => 'New Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Agwaetiti Norfolk',
 			'NG' => 'Naịjịrịa',
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
 			'PH' => 'Philippines',
 			'PK' => 'Pakistan',
 			'PL' => 'Poland',
 			'PM' => 'St. Pierre & Miquelon',
 			'PN' => 'Agwaetiti Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Mpaghara ndị Palestine',
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
 			'SB' => 'Agwaetiti Solomon',
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
 			'SS' => 'South Sudan',
 			'ST' => 'São Tomé & Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks & Caicos Islands',
 			'TD' => 'Chad',
 			'TF' => 'Ụmụ ngalaba Frenchi Southern',
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
 			'TT' => 'Trinidad na Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraine',
 			'UG' => 'Uganda',
 			'UM' => 'Obere Agwaetiti Dị Na Mpụga U.S',
 			'UN' => 'Mba Ụwa Jikọrọ Ọnụ',
 			'US' => 'United States',
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
 			'XA' => 'Pseudo-Accents',
 			'XB' => 'Pseudo-Bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'South Africa',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Mpaghara A na-amaghị',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kalenda',
 			'cf' => 'Ụsọrọ egọ',
 			'collation' => 'Ụsọrọ Nhazị',
 			'currency' => 'Egọ',
 			'hc' => 'Okịrịkịrị Awa (12 vs 24)',
 			'lb' => 'Akara akanka nkwụsị',
 			'ms' => 'Ụsọrọ Mmeshọ',
 			'numbers' => 'Nọmba',

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
 				'buddhist' => q{Kalenda Bụddịst},
 				'chinese' => q{Kalenda Chinese},
 				'coptic' => q{Kalenda Koptic},
 				'dangi' => q{Kalenda Dang},
 				'ethiopic' => q{Kalenda Etopịa},
 				'ethiopic-amete-alem' => q{Etiopic Amete Alem Kalenda},
 				'gregorian' => q{Kalenda Gregory},
 				'hebrew' => q{Kalenda Hebrew},
 				'indian' => q{Kalenda India},
 				'islamic' => q{Kalenda Hijri},
 				'islamic-civil' => q{Kalenda Hijri},
 				'islamic-rgsa' => q{Kalenda Hijri (Saudi Arabia, sighting)},
 				'islamic-tbla' => q{Kalenda Hijri (tabular, astronomical epoch)},
 				'islamic-umalqura' => q{Kalenda Hijri (Umm al-Qura)},
 				'iso8601' => q{Kalenda ISO-8601},
 				'japanese' => q{Kalenda Japanese},
 				'persian' => q{Kalenda Persian},
 				'roc' => q{Kalenda repụblic nke China},
 			},
 			'cf' => {
 				'account' => q{Ụsọrọ akantụ egọ},
 				'standard' => q{Ụsọrọ egọ nzụgbe},
 			},
 			'collation' => {
 				'ducet' => q{Default Unicode ụsọrọ nhazị},
 				'phonebook' => q{Nhazị akwụkwọ ebe a na-ede nọmba fon},
 				'pinyin' => q{Pinyin ụsọrọ nhazị},
 				'search' => q{Ọchụchụ nịle},
 				'standard' => q{Usoro Nhazi},
 			},
 			'hc' => {
 				'h11' => q{Ụsọrọ Okịrịkịrị awa iri na abụọ (0–11)},
 				'h12' => q{Ụsọrọ Okịrịkịrị awa iri na abụọ (0–12)},
 				'h23' => q{Ụsọrọ Okịrịkịrị (0–23)},
 				'h24' => q{Ụsọrọ Okịrịkịrị (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Akara akanka nkwụsị esịghị ịke},
 				'normal' => q{Akara akanka nkwụsị kwesịrị},
 				'strict' => q{Akara akanka nkwụsị sịrị ịke},
 			},
 			'ms' => {
 				'metric' => q{Ụsọrọ Metric},
 				'uksystem' => q{Ụsọrọ Mmeshọ ịmperịa},
 				'ussystem' => q{Ụsọrọ Mmeshọ US},
 			},
 			'numbers' => {
 				'ahom' => q{Ọnụ ọgụgụ Ahom},
 				'arab' => q{Ọnụ ọgụgụ Arab na Indị},
 				'arabext' => q{Ọnụ ọgụgụ Arab na Indị agbatịrị},
 				'armn' => q{Ọnụ ọgụgụ Armenịa},
 				'armnlow' => q{ọbere ọnụ ọgụgụ Armenịa},
 				'bali' => q{Balinese Digits},
 				'beng' => q{Ọnụ ọgụgụ Bangla},
 				'brah' => q{Brahmi Digits},
 				'cakm' => q{Ọnụ ọgụgụ Chakma},
 				'cham' => q{Cham Digits},
 				'cyrl' => q{Ọnụ ọgụgụ Cyrillic},
 				'deva' => q{Ọnụ ọgụgụ Devanagarị},
 				'diak' => q{Ọnụ ọgụgụ Dives Akuru},
 				'ethi' => q{Ọnụ ọgụgụ Etọpịa},
 				'fullwide' => q{Ọnụ ọgụgụ ọbọsara},
 				'gara' => q{Ọnụ ọgụgụ Garay},
 				'geor' => q{Ọnụ ọgụgụ Georgian},
 				'gong' => q{Ọnụ ọgụgụ Gunjala Gondi},
 				'gonm' => q{Ọnụ ọgụgụ Masaram Gondi},
 				'grek' => q{Ọnụ ọgụgụ Grik},
 				'greklow' => q{Ọbere ọnụ ọgụgụ Grik},
 				'gujr' => q{Ọnụ ọgụgụ Gụjaratị},
 				'gukh' => q{Ọnụ ọgụgụ Gurung Khema},
 				'guru' => q{Onụ ọgụgụ Gụmụkh},
 				'hanidec' => q{Ọnụ ọgụgụ ntụpọ Chịnese},
 				'hans' => q{Ọnụ ọgụgụ mfe Chịnese},
 				'hansfin' => q{Ọnụ ọgụgụ akantụ mfe nke Chinese},
 				'hant' => q{Ọnụ ọgụgụ ọdinala chinese},
 				'hantfin' => q{Ọnụ ọgụgụ akantụ ọdịnala Chinese},
 				'hebr' => q{Ọnụ ọgụgụ Hebrew},
 				'hmng' => q{Ọnụ ọgụgụ Pahawh Hmong},
 				'hmnp' => q{Ọnụ ọgụgụ Nyiakeng Puachue Hmong},
 				'java' => q{Ọnụ ọgụgụ Javanịsị},
 				'jpan' => q{Ọnụ ọgụgụ Japanese},
 				'jpanfin' => q{Ọnụ ọgụgụ akantụ Japanese},
 				'kali' => q{Ọnụ ọgụgụ Kayah Li},
 				'kawi' => q{Ọnụ ọgụgụ Kawi},
 				'khmr' => q{Ọnụ ọgụgụ Khmer},
 				'knda' => q{Ọnụ ọgụgụ Kannada},
 				'krai' => q{Ọnụ ọgụgụ Kirat Rai},
 				'lana' => q{Ọnụ ọgụgụ Tai Tham Hora},
 				'lanatham' => q{Ọnụ ọgụgụ Tai Tham Tham},
 				'laoo' => q{Ọnụ ọgụgụ Lao},
 				'latn' => q{Ọnụ Ọgụgụ Mpaghara Ọdịda Anyanwụ},
 				'lepc' => q{Ọnụ ọgụgụ Lepcha},
 				'limb' => q{Ọnụ ọgụgụ Limbu},
 				'mathbold' => q{Ọnụ ọgụgụ Mathematical Bold},
 				'mathdbl' => q{Ọnụ ọgụgụ Mathematical Double-Struck},
 				'mathmono' => q{Ọnụ ọgụgụ Mathematical Monospace},
 				'mathsanb' => q{Ọnụ ọgụgụ Mathematical Sans-Serif Bold},
 				'mathsans' => q{Ọnụ ọgụgụ Mathematical Sans-Serif},
 				'mlym' => q{Ọnụ ọgụgụ Malayala},
 				'modi' => q{Ọnụ ọgụgụ Modi},
 				'mong' => q{Ọnụ ọgụgụ Mongolian},
 				'mroo' => q{Ọnụ ọgụgụ Mro},
 				'mtei' => q{Ọnụ ọgụgụ Meetei Mayek},
 				'mymr' => q{Ọnụ ọgụgụ Myamar},
 				'mymrepka' => q{Ọnụ ọgụgụ Myanmar Eastern Pwo Karen},
 				'mymrpao' => q{Ọnụ ọgụgụ Myanmar Pao},
 				'mymrshan' => q{Ọnụ ọgụgụ Myanmar Shan},
 				'mymrtlng' => q{Ọnụ ọgụgụ Myanmar Tai Laing},
 				'nagm' => q{Ọnụ ọgụgụ Nag Mundari},
 				'nkoo' => q{Ọnụ ọgụgụ N’Ko},
 				'olck' => q{Ọnụ ọgụgụ Ochiki},
 				'onao' => q{Ọnụ ọgụgụ Ol Onal},
 				'orya' => q{Ọnụ ọgụgụ Ọdịa},
 				'osma' => q{Ọnụ ọgụgụ Osmanya},
 				'outlined' => q{Ọnụ ọgụgụ Outlined},
 				'rohg' => q{Ọnụ ọgụgụ Hanifi Rohingya},
 				'roman' => q{Ọnụ ọgụgụ Roman},
 				'romanlow' => q{Ọbere Ọnụ ọgụgụ Roman},
 				'saur' => q{Ọnụ ọgụgụ Saurashtra},
 				'shrd' => q{Ọnụ ọgụgụ Sharada},
 				'sind' => q{Ọnụ ọgụgụ Khudawadi},
 				'sinh' => q{Ọnụ ọgụgụ Sinhala Lith},
 				'sora' => q{Ọnụ ọgụgụ Sora Sompeng},
 				'sund' => q{Ọnụ ọgụgụ Sundanese},
 				'sunu' => q{Ọnụ ọgụgụ Sunuwar},
 				'takr' => q{Ọnụ ọgụgụ Takri},
 				'talu' => q{Ọnụ ọgụgụ New Tai Lue},
 				'taml' => q{Ọnụ ọgụgụ ọdịnala Tamịl},
 				'tamldec' => q{Ọnụ ọgụgụ Tamị},
 				'telu' => q{Ọnụ ọgụgụ Telụgụ},
 				'thai' => q{Ọnụ ọgụgụ Taị},
 				'tibt' => q{Ọnụ ọgụgụ Tịbeta},
 				'tirh' => q{Ọnụ ọgụgụ Tirhuta},
 				'tnsa' => q{Ọnụ ọgụgụ Tangsa},
 				'vaii' => q{Ọnụ ọgụgụ Vai},
 				'wara' => q{Ọnụ ọgụgụ Warang Citi},
 				'wcho' => q{Ọnụ ọgụgụ Wancho},
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
			'metric' => q{Metriik},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Asụsụ: {0}',
 			'script' => 'Mkpụrụ Okwu: {0}',
 			'region' => 'Mpaghara: {0}',

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
			auxiliary => qr{[áàā c éèē íìī {ị́}{ị̀} ḿ{m̀} ńǹ óòō {ọ́}{ọ̀} q úùū {ụ́}{ụ̀} x]},
			index => ['A', 'B', '{CH}', 'C', 'D', 'E', 'F', 'G', '{GB}', '{GH}', '{GW}', 'H', 'I', 'Ị', 'J', 'K', '{KP}', '{KW}', 'L', 'M', 'N', 'Ṅ', '{NW}', '{NY}', 'O', 'Ọ', 'P', 'Q', 'R', 'S', '{SH}', 'T', 'U', 'Ụ', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b {ch} d e f g {gb} {gh} {gw} h i ị j k {kp} {kw} l m n ṅ {nw} {ny} o ọ p r s {sh} t u ụ v w y z]},
			punctuation => qr{[\- ‑ , ; \: ! ? . ‘’ “” ( ) \[ \] \{ \}]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', '{CH}', 'C', 'D', 'E', 'F', 'G', '{GB}', '{GH}', '{GW}', 'H', 'I', 'Ị', 'J', 'K', '{KP}', '{KW}', 'L', 'M', 'N', 'Ṅ', '{NW}', '{NY}', 'O', 'Ọ', 'P', 'Q', 'R', 'S', '{SH}', 'T', 'U', 'Ụ', 'V', 'W', 'X', 'Y', 'Z'], };
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
					'10p-1' => {
						'1' => q(deci{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(deci{0}),
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
					'10p-30' => {
						'1' => q(kwekto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(kwekto{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(obere{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(obere{0}),
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
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(kwetta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(kwetta{0}),
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
					'concentr-portion-per-1e9' => {
						'name' => q(akụkụ kwa ijeri),
						'other' => q({0} akụkụ kwa ijeri),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(akụkụ kwa ijeri),
						'other' => q({0} akụkụ kwa ijeri),
					},
					# Long Unit Identifier
					'coordinate' => {
						'north' => q({0} north),
						'south' => q({0} south),
						'west' => q({0} west),
					},
					# Core Unit Identifier
					'coordinate' => {
						'north' => q({0} north),
						'south' => q({0} south),
						'west' => q({0} west),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(Ọtụtụ nari afọ),
						'other' => q({0} Ọtụtụ nari afọ),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(Ọtụtụ nari afọ),
						'other' => q({0} Ọtụtụ nari afọ),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(Ọtụtụ Ubochi),
						'other' => q({0} Ọtụtụ Ubochi),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Ọtụtụ Ubochi),
						'other' => q({0} Ọtụtụ Ubochi),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(Ọtụtụ afọ iri),
						'other' => q({0} Ọtụtụ afọ iri),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(Ọtụtụ afọ iri),
						'other' => q({0} Ọtụtụ afọ iri),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(Ọtụtụ awa),
						'other' => q({0} Ọtụtụ awa),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(Ọtụtụ awa),
						'other' => q({0} Ọtụtụ awa),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(nkeji),
						'other' => q({0} nkeji),
						'per' => q({0} kwa nkeji),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(nkeji),
						'other' => q({0} nkeji),
						'per' => q({0} kwa nkeji),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Ọtụtụ Ọnwa),
						'other' => q({0} Ọnwa),
						'per' => q({0} kwa Ọnwa),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Ọtụtụ Ọnwa),
						'other' => q({0} Ọnwa),
						'per' => q({0} kwa Ọnwa),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(Ọtụtụ abali),
						'other' => q({0} Ọtụtụ abali),
						'per' => q({0} kwa abali),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(Ọtụtụ abali),
						'other' => q({0} Ọtụtụ abali),
						'per' => q({0} kwa abali),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(Nkeji Nkeano),
						'other' => q({0}/q),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(Nkeji Nkeano),
						'other' => q({0}/q),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekọnd),
						'other' => q({0} sekọnd),
						'per' => q({0} kwa sekọnd),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekọnd),
						'other' => q({0} sekọnd),
						'per' => q({0} kwa sekọnd),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(Ọtụtụ Izu),
						'other' => q({0} Ọtụtụ Izu),
						'per' => q({0} kwa Izu),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(Ọtụtụ Izu),
						'other' => q({0} Ọtụtụ Izu),
						'per' => q({0} kwa Izu),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(Ọtụtụ Afọ),
						'other' => q({0} Ọtụtụ Afọ),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(Ọtụtụ Afọ),
						'other' => q({0} Ọtụtụ Afọ),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Kalori),
						'other' => q({0} Kalori),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kalori),
						'other' => q({0} Kalori),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(ntụpọ kwa sentimita),
						'other' => q({0} ntụpọ kwa sentimita),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(ntụpọ kwa sentimita),
						'other' => q({0} ntụpọ kwa sentimita),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(ntụpọ kwa inch),
						'other' => q({0} ntụpọ kwa inch),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(ntụpọ kwa inch),
						'other' => q({0} ntụpọ kwa inch),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixels),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'other' => q({0} pixels),
					},
					# Core Unit Identifier
					'pixel' => {
						'other' => q({0} pixels),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pixels per centimeter),
						'other' => q({0} pixels per centimeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pixels per centimeter),
						'other' => q({0} pixels per centimeter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixels per inch),
						'other' => q({0} pixels per inch),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixels per inch),
						'other' => q({0} pixels per inch),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(radius uwa),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(radius uwa),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
					},
					# Long Unit Identifier
					'power2' => {
						'other' => q({0} sukwia),
					},
					# Core Unit Identifier
					'power2' => {
						'other' => q({0} sukwia),
					},
					# Long Unit Identifier
					'power3' => {
						'other' => q({0} kubik),
					},
					# Core Unit Identifier
					'power3' => {
						'other' => q({0} kubik),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Beaufort),
						'other' => q(Beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Beaufort),
						'other' => q(Beaufort {0}),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(ìhè),
						'other' => q({0} ìhè),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(ìhè),
						'other' => q({0} ìhè),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(ngaji mégharia onu),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(ngaji mégharia onu),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(mmiri dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(mmiri dram),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'concentr-item' => {
						'other' => q({0}ihe),
					},
					# Core Unit Identifier
					'item' => {
						'other' => q({0}ihe),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'other' => q({0}mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'other' => q({0}mmol/L),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'other' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'other' => q({0}ppm),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(akụkụ/ijeri),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(akụkụ/ijeri),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(Ubochi),
						'other' => q({0} Ọtụtụ Ubochi),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Ubochi),
						'other' => q({0} Ọtụtụ Ubochi),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(awa),
						'other' => q({0} awa),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(awa),
						'other' => q({0} awa),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsec),
						'other' => q({0}μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsec),
						'other' => q({0}μs),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'other' => q({0}ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'other' => q({0}ns),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(Ọtụtụ abali),
						'other' => q({0}Ọtụtụ abali),
						'per' => q({0}/abali),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(Ọtụtụ abali),
						'other' => q({0}Ọtụtụ abali),
						'per' => q({0}/abali),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'other' => q({0}q),
					},
					# Core Unit Identifier
					'quarter' => {
						'other' => q({0}q),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kal),
						'other' => q({0}kal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kal),
						'other' => q({0}kal),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'other' => q({0}Kal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'other' => q({0}Kal),
					},
					# Long Unit Identifier
					'force-newton' => {
						'other' => q({0}N),
					},
					# Core Unit Identifier
					'newton' => {
						'other' => q({0}N),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'other' => q({0}ntụpọ),
					},
					# Core Unit Identifier
					'dot' => {
						'other' => q({0}ntụpọ),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpcm),
						'other' => q({0}dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpcm),
						'other' => q({0}dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
						'other' => q({0}dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
						'other' => q({0}dpi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'other' => q({0}em),
					},
					# Core Unit Identifier
					'em' => {
						'other' => q({0}em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'other' => q({0}MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'other' => q({0}MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'other' => q({0}px),
					},
					# Core Unit Identifier
					'pixel' => {
						'other' => q({0}px),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'other' => q(B{0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'other' => q(B{0}),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(ìhè),
						'other' => q({0}ìhè),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(ìhè),
						'other' => q({0}ìhè),
					},
				},
				'short' => {
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ihe),
						'other' => q({0} ihe),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ihe),
						'other' => q({0} ihe),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(akụkụ/ijeri),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(akụkụ/ijeri),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(Ọtụtụ Ubochi),
						'other' => q({0} Ọtụtụ Ubochi),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Ọtụtụ Ubochi),
						'other' => q({0} Ọtụtụ Ubochi),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(Ọtụtụ awa),
						'other' => q({0} awa),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(Ọtụtụ awa),
						'other' => q({0} awa),
					},
					# Long Unit Identifier
					'duration-month' => {
						'other' => q({0} mths),
					},
					# Core Unit Identifier
					'month' => {
						'other' => q({0} mths),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(Ọtụtụ abali),
						'other' => q({0} Ọtụtụ abali),
						'per' => q({0}/abali),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(Ọtụtụ abali),
						'other' => q({0} Ọtụtụ abali),
						'per' => q({0}/abali),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'other' => q({0} qtrs),
					},
					# Core Unit Identifier
					'quarter' => {
						'other' => q({0} qtrs),
					},
					# Long Unit Identifier
					'duration-week' => {
						'other' => q({0} wks),
					},
					# Core Unit Identifier
					'week' => {
						'other' => q({0} wks),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Kal),
						'other' => q({0} Kal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kal),
						'other' => q({0} Kal),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(ntụpọ),
						'other' => q({0} ntụpọ),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(ntụpọ),
						'other' => q({0} ntụpọ),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
						'other' => q({0} nki),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
						'other' => q({0} nki),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(ìhè),
						'other' => q({0} ìhè),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(ìhè),
						'other' => q({0} ìhè),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(ngaji mégharia onu),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(ngaji mégharia onu),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dobé),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dobé),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Eye|E|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Mba|M|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, na {1}),
				2 => q({0} na {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arab' => {
			'minusSign' => q(‏-),
			'percentSign' => q(٪‏),
			'plusSign' => q(‏+),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0 %',
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
		'arab' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '¤#,##0.00',
					},
				},
			},
		},
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
				'currency' => q(Ego Dirham obodo United Arab Emirates),
				'other' => q(Ego dirhams obodo UAE),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Ego Afghani Obodo Afghanistan),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Ego Lek Obodo Albania),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Ego Dram obodo Armenia),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Ego Antillean Guilder obodo Netherlands),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Ego Kwanza obodo Angola),
				'other' => q(Ego kwanzas obodo Angola),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Ego Peso obodo Argentina),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Australia),
				'other' => q(Ego dollars obodo Australia),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Ego Florin obodo Aruba),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Ego Manat obodo Azerbaijan),
				'other' => q(Ego manats obodo Azerbaijan),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Akara mgbanwe ego obodo Bosnia-Herzegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Ego Taka obodo Bangladesh),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Ego Lev mba Bulgaria),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Ego Dinar Obodo Bahrain),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Ego Franc obodo Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dollar Bermuda),
				'other' => q(Dollars Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Brunei),
				'other' => q(Ego dollars obodo Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Ego Boliviano obodo Bolivia),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real Brazil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Ego Dollar Obodo Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ego Ngultrum obodo Bhutan),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Ego Pula obodo Bostwana),
				'other' => q(Ego pulas obodo Bostwana),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Ego Ruble mba Belarus),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dollar Belize),
				'other' => q(Dollars Belize),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dollar Canada),
				'other' => q(Dollars Canada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Ego Franc obodo Congo),
				'other' => q(Ego francs mba Congo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Ego Franc mba Switzerland),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Ego Peso obodo Chile),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Ego Yuan Obodo China \(ndị bi na mmiri\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan China),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Ego Peso obodo Columbia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Ego Colón obodo Costa Rica),
				'other' => q(Ego colóns obodo Costa Rica),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Ego Peso e nwere ike ịgbanwe nke obodo Cuba),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Ego Peso obodo Cuba),
				'other' => q(Ego pesos obodo Cuba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo Caboverdiano),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Ego Koruna obodo Czech),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Ego Franc obodo Djibouti),
				'other' => q(ego francs obodo Djibouti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Ego Krone Obodo Denmark),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Ego Peso Obodo Dominica),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Ego Dinar Obodo Algeria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Ego Pound obodo Egypt),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Ego Nakfa obodo Eritrea),
				'other' => q(Ego nakfas obodo Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Ego Birr obodo Ethiopia),
				'other' => q(Ego birrs obodo Ethiopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'other' => q(euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Fiji),
				'other' => q(Ego dollars obodo Fijian),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Ego Pound obodo Falkland Islands),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pound British),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Ego Lari Obodo Georgia),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Ego Cedi obodo Ghana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Ego Pound obodo Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Ego Dalasi obodo Gambia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Ego Franc obodo Guinea),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Ego Quetzal obodo Guatemala),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Guyana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Ego Dollar Obodo Honk Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Ego Lempira obodo Honduras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Ego Kuna obodo Croatia),
				'other' => q(Ego kunas obodo Croatia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Ego Gourde obodo Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Ego Forint obodo Hungary),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Ego Rupiah Obodo Indonesia),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Ego Shekel ọhụrụ obodo Israel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupee India),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Ego Dinar obodo Iraq),
				'other' => q(Ego dinars obodo Iraq),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Ego Rial obodo Iran),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Ego Króna obodo Iceland),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Jamaica),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Ego Dinar Obodo Jordan),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Yen Japan),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Ego Shilling obodo Kenya),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Ego Som Obodo Kyrgyzstan),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Ego Riel obodo Cambodia),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Ego Franc obodo Comoros),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Ego Won Obodo North Korea),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Ego Won Obodo South Korea),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Ego Dinar Obodo Kuwait),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Cayman Islands),
				'other' => q(Ego dollars obodo Cayman Islands),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Ego Tenge obodo Kazakhstani),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Ego Kip Obodo Laos),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Ego Pound obodo Lebanon),
				'other' => q(Ego Pound Obodo Lebanon),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Ego Rupee obodo Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Ego loti obodo Lesotho),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Ego Dinar obodo Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Ego Dirham obodo Morocco),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Ego Leu obodo Moldova),
				'other' => q(Ego leu mba Moldova),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ego Ariary obodo Madagascar),
				'other' => q(Ego ariaries obodo Madagascar),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Ego Denar Obodo Macedonia),
				'other' => q(Ego denari mba Macedonia),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Ego Kyat obodo Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Ego Turgik Obodo Mongolia),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Ego Pataca ndị Obodo Macanese),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ego Ouguiya Obodo Mauritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Ego Rupee obodo Mauritania),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Ego Rufiyaa obodo Moldova),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Ego Kwacha obodo Malawi),
				'other' => q(Ego kwachas obodo Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Ego Peso obodo Mexico),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ego Ringgit obodo Malaysia),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Ego Metical obodo Mozambique),
				'other' => q(Ego meticals obodo Mozambique),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Namibia),
			},
		},
		'NGN' => {
			symbol => '₦',
			display_name => {
				'currency' => q(Naịra),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Ego Córodoba obodo Nicaragua),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Ego Krone Obodo Norway),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Ego Rupee obodo Nepal),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo New Zealand),
				'other' => q(Ego dollars obodo New Zealand),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Ego Rial obodo Oman),
				'other' => q(Ego rials Obodo Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Ego Balboa obodo Panama),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Ego Sol obodo Peru),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Ego Kina obodo Papua New Guinea),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Ego Piso obodo Philippine),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Ego Rupee obodo Pakistan),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Ego Zloty mba Poland),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Ego Guarani obodo Paraguay),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Ego Rial obodo Qatar),
				'other' => q(Ego rials obodo Qatar),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Ego Leu obodo Romania),
				'other' => q(Ego leu Obodo Romania),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Ego Dinar obodo Serbia),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Ruble Russia),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Ego Franc obodo Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Ego Riyal obodo Saudi),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Solomon Islands),
				'other' => q(Ego dollars obodo Solomon Islands),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Ego Rupee obodo Seychelles),
				'other' => q(Ego rupees obodo Seychelles),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Ego Pound obodo Sudan),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Ego Krona Obodo Sweden),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo Singapore),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Ego Pound obodo St Helena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Ego Leone obodo Sierra Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Ego Leone obodo Sierra Leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Ego shilling obodo Somali),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dollar Surinamese),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Ego Pound obodo South Sudan),
				'other' => q(Ego pounds mba ọdịda anyanwụ Sudan),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Ego Dobra nke obodo Sāo Tomé na Principe),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Ego Pound obodo Syria),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Ego Lilangeni obodo Swaziland),
				'other' => q(Ego emalangeni obodo Swaziland),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Ego Baht obodo Thai),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Who Somoni obodo Tajikistan),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Ego Manat Obodo Turkmenistan),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Ego Dinar Obodo Tunisia),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Ego paʻanga obodo Tonga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Ego Lira obodo Turkey),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dollar Trinidad & Tobago),
				'other' => q(Dollars Trinidad & Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Dollar obodo New Taiwan),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Ego Shilling Obodo Tanzania),
				'other' => q(Ego Shillings Obodo Tanzania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ego Hryvnia obodo Ukraine),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Ego Shilling obodo Uganda),
				'other' => q(Ego shillings obodo Uganda),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Dollar US),
				'other' => q(Dollars US),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Ego Peso obodo Uruguay),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Ego Som obodo Uzbekistan),
				'other' => q(Ego som obodo Uzbekistan),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Ego Bolivar obodo Venezuela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Ego Dong obodo Vietnam),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Ego Vatu obodo Vanuatu),
				'other' => q(Ego Vanuatu vatus obodo Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Ego Tala obodo Samoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Ego Franc mba etiti Africa),
				'other' => q(Ego francs mba etiti Africa),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Ego Dollar obodo East Carribbean),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Ego CFA Franc obodo West Africa),
				'other' => q(Ego CFA francs mba ọdịda anyanwụ Afrịka),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Ego Franc obodo CFP),
				'other' => q(Ego francs obodo CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Ego Amaghị),
				'other' => q(\(ego amaghị\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Ego Rial obodo Yemeni),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Ego Rand obodo South Africa),
				'other' => q(Ego rand obodo South Africa),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Ego Kwacha Obodo Zambia),
				'other' => q(Ego kwachas obodo Zambia),
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
							'Jen',
							'Feb',
							'Maa',
							'Epr',
							'Mee',
							'Juu',
							'Jul',
							'Ọgọ',
							'Sep',
							'Ọkt',
							'Nov',
							'Dis'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Jenụwarị',
							'Febrụwarị',
							'Maachị',
							'Epreel',
							'Mee',
							'Jun',
							'Julaị',
							'Ọgọọst',
							'Septemba',
							'Ọktoba',
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
							'E',
							'M',
							'J',
							'J',
							'Ọ',
							'S',
							'Ọ',
							'N',
							'D'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Jenụwarị',
							'Febrụwarị',
							'Maachị',
							'Epreel',
							'Mee',
							'Jun',
							'Julaị',
							'Ọgọọst',
							'Septemba',
							'Ọktoba',
							'Novemba',
							'Disemba'
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
						mon => 'Mọn',
						tue => 'Tiu',
						wed => 'Wen',
						thu => 'Tọọ',
						fri => 'Fraị',
						sat => 'Sat',
						sun => 'Sọn'
					},
					wide => {
						mon => 'Mọnde',
						tue => 'Tiuzdee',
						wed => 'Wenezdee',
						thu => 'Tọọzdee',
						fri => 'Fraịdee',
						sat => 'Satọdee',
						sun => 'Sọndee'
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
					wide => {0 => 'Ọkara 1',
						1 => 'Ọkara 2',
						2 => 'Ọkara 3',
						3 => 'Ọkara 4'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
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
					'am' => q{N’ụtụtụ},
					'pm' => q{N’abalị},
				},
				'narrow' => {
					'am' => q{N’ụtụtụ},
					'pm' => q{N’abalị},
				},
				'wide' => {
					'am' => q{N’ụtụtụ},
					'pm' => q{N’abali},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{N’ụtụtụ},
					'pm' => q{N’abalị},
				},
				'narrow' => {
					'am' => q{N’ụtụtụ},
					'pm' => q{N’abalị},
				},
				'wide' => {
					'am' => q{N’ụtụtụ},
					'pm' => q{N’abalị},
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
				'0' => 'Tupu Kraist',
				'1' => 'Afọ Kraịst'
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
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d/M/yy},
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
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			Md => q{M/d},
			hm => q{h:mm a},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			GyMMM => q{MMM G y},
			GyMMMEd => q{E, d MMM, G y},
			GyMMMd => q{d MMM, G y},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{'Izu' W 'n'‘'ime' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'Izu' w 'n' 'ime' Y},
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
			MMM => {
				M => q{MMM – MMM},
			},
		},
		'gregorian' => {
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
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
				M => q{MM/y – MM/y},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				M => q{y MMM d, E – MMM d, E},
				d => q{y MMM d, E – MMM d, E},
				y => q{y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				y => q{y MMM d – y MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Oge {0}),
		regionFormat => q(Oge Ihe {0}),
		regionFormat => q(Oge Izugbe {0}),
		'Afghanistan' => {
			long => {
				'standard' => q#Oge Afghanistan#,
			},
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Oge Etiti Afrịka#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Oge Mpaghara Ọwụwa Anyanwụ Afrịka#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Oge Izugbe Mpaghara Mgbada Ugwu Afrịka#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Ọdịda Anyanwụ Afrịka#,
				'generic' => q#Oge Mpaghara Ọdịda Anyanwụ Afrịka#,
				'standard' => q#Oge Izugbe Mpaghara Ọdịda Anyanwụ Afrịka#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Oge Ihe Alaska#,
				'generic' => q#Oge Alaska#,
				'standard' => q#Oge Izugbe Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Amazon#,
				'generic' => q#Oge Amazon#,
				'standard' => q#Oge Izugbe Amazon#,
			},
		},
		'America_Central' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Etiti#,
				'generic' => q#Oge Mpaghara Etiti#,
				'standard' => q#Oge Izugbe Mpaghara Etiti#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Ọwụwa Anyanwụ#,
				'generic' => q#Oge Mpaghara Ọwụwa Anyanwụ#,
				'standard' => q#Oge Izugbe Mpaghara Ọwụwa Anyanwụ#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Ugwu#,
				'generic' => q#Oge Mpaghara Ugwu#,
				'standard' => q#Oge Izugbe Mpaghara Ugwu#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Pacific#,
				'generic' => q#Oge Mpaghara Pacific#,
				'standard' => q#Oge Izugbe Mpaghara Pacific#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Oge Ihe Apia#,
				'generic' => q#Oge Apia#,
				'standard' => q#Oge Izugbe Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Oge Ihe Arab#,
				'generic' => q#Oge Arab#,
				'standard' => q#Oge Izugbe Arab#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Argentina#,
				'generic' => q#Oge Argentina#,
				'standard' => q#Oge Izugbe Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Ọdịda Anyanwụ Argentina#,
				'generic' => q#Oge Mpaghara Ọdịda Anyanwụ Argentina#,
				'standard' => q#Oge Izugbe Mpaghara Ọdịda Anyanwụ Argentina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Armenia#,
				'generic' => q#Oge Armenia#,
				'standard' => q#Oge Izugbe Armenia#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Atlantic#,
				'generic' => q#Oge Mpaghara Atlantic#,
				'standard' => q#Oge Izugbe Mpaghara Atlantic#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Oge Ihe Etiti Australia#,
				'generic' => q#Oge Etiti Australia#,
				'standard' => q#Oge Izugbe Etiti Australia#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Ọdịda Anyanwụ Etiti Australia#,
				'generic' => q#Oge Mpaghara Ọdịda Anyanwụ Etiti Australia#,
				'standard' => q#Oge Izugbe Mpaghara Ọdịda Anyanwụ Etiti Australia#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Ọwụwa Anyanwụ Australia#,
				'generic' => q#Oge Mpaghara Ọwụwa Anyanwụ Australia#,
				'standard' => q#Oge Izugbe Mpaghara Ọwụwa Anyanwụ Australia#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Ọdịda Anyanwụ Australia#,
				'generic' => q#Oge Mpaghara Ọdịda Anyanwụ Australia#,
				'standard' => q#Oge Izugbe Mpaghara Ọdịda Anyanwụ Australia#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Azerbaijan#,
				'generic' => q#Oge Azerbaijan#,
				'standard' => q#Oge Izugbe Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Azores#,
				'generic' => q#Oge Azores#,
				'standard' => q#Oge Izugbe Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Bangladesh#,
				'generic' => q#Oge Bangladesh#,
				'standard' => q#Oge Izugbe Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Oge Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Oge Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Brasilia#,
				'generic' => q#Oge Brasilia#,
				'standard' => q#Oge Izugbe Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Oge Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Cape Verde#,
				'generic' => q#Oge Cape Verde#,
				'standard' => q#Oge Izugbe Cape Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Oge Izugbe Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Oge Ihe Chatham#,
				'generic' => q#Oge Chatham#,
				'standard' => q#Oge Izugbe Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Chile#,
				'generic' => q#Oge Chile#,
				'standard' => q#Oge Izugbe Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Oge Ihe China#,
				'generic' => q#Oge China#,
				'standard' => q#Oge Izugbe China#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Oge Ekeresimesi Island#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Oge Cocos Islands#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Columbia#,
				'generic' => q#Oge Columbia#,
				'standard' => q#Oge Izugbe Columbia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Oge Ọkara Okpomọkụ Cook Islands#,
				'generic' => q#Oge Cook Islands#,
				'standard' => q#Oge Izugbe Cook Islands#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Oge Ihe Mpaghara Cuba#,
				'generic' => q#Oge Cuba#,
				'standard' => q#Oge Izugbe Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Oge Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Oge Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Oge Mpaghara Ọwụwa Anyanwụ Timor#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Ọwụwa Anyanwụ Island#,
				'generic' => q#Oge Mpaghara Ọwụwa Anyanwụ Island#,
				'standard' => q#Oge Izugbe Mpaghara Ọwụwa Anyanwụ Island#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Oge Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Nhazi Oge Ụwa Niile#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Obodo Amaghị#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Ireland#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Britain#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Etiti Europe#,
				'generic' => q#Oge Mpaghara Etiti Europe#,
				'standard' => q#Oge Izugbe Mpaghara Etiti Europe#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Ọwụwa Anyanwụ Europe#,
				'generic' => q#Oge Mpaghara Ọwụwa Anyanwụ Europe#,
				'standard' => q#Oge Izugbe Mpaghara Ọwụwa Anyanwụ Europe#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Further-eastern European Time#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Ọdịda Anyanwụ Europe#,
				'generic' => q#Oge Mpaghara Ọdịda Anyanwụ Europe#,
				'standard' => q#Oge Izugbe Mpaghara Ọdịda Anyanwụ Europe#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Falkland Islands#,
				'generic' => q#Oge Falkland Islands#,
				'standard' => q#Oge Izugbe Falkland Islands#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Fiji#,
				'generic' => q#Oge Fiji#,
				'standard' => q#Oge Izugbe Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Oge French Guiana#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Oge French Southern & Antarctic#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Oge Mpaghara Greemwich Mean#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Oge Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Oge Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Georgia#,
				'generic' => q#Oge Georgia#,
				'standard' => q#Oge Izugbe Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Oge Gilbert Islands#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Ọwụwa Anyanwụ Greenland#,
				'generic' => q#Oge Mpaghara Ọwụwa Anyanwụ Greenland#,
				'standard' => q#Oge Izugbe Mpaghara Ọwụwa Anyanwụ Greenland#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mpaghara Ọdịda Anyanwụ Greenland#,
				'generic' => q#Oge Mpaghara Ọdịda Anyanwụ Greenland#,
				'standard' => q#Oge Izugbe Mpaghara Ọdịda Anyanwụ Greenland#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Oge Izugbe Gulf#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Oge Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Oge Ihe Hawaii-Aleutian#,
				'generic' => q#Oge Hawaii-Aleutian#,
				'standard' => q#Oge Izugbe Hawaii-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Hong Kong#,
				'generic' => q#Oge Hong Kong#,
				'standard' => q#Oge Izugbe Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Hovd#,
				'generic' => q#Oge Hovd#,
				'standard' => q#Oge Izugbe Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Oge Izugbe India#,
			},
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Oge Osimiri India#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Oge Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Oge Etiti Indonesia#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Oge Mpaghara Ọwụwa Anyanwụ Indonesia#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Oge Mpaghara Ọdịda Anyanwụ Indonesia#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Oge Ihe Iran#,
				'generic' => q#Oge Iran#,
				'standard' => q#Oge Izugbe Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Irkutsk#,
				'generic' => q#Oge Irkutsk#,
				'standard' => q#Oge Izugbe Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Oge Ihe Israel#,
				'generic' => q#Oge Israel#,
				'standard' => q#Oge Izugbe Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Oge Ihe Japan#,
				'generic' => q#Oge Japan#,
				'standard' => q#Oge Izugbe Japan#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Oge Kazakhstan#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Oge Mpaghara Ọwụwa Anyanwụ Kazakhstan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Oge Mpaghara Ọdịda Anyanwụ Kazakhstan#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Oge Ihe Korea#,
				'generic' => q#Oge Korea#,
				'standard' => q#Oge Izugbe Korea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Oge Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Krasnoyarsk#,
				'generic' => q#Oge Krasnoyarsk#,
				'standard' => q#Oge Izugbe Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Oge Kyrgyzstan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Oge Line Islands#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Oge Ihe Lord Howe#,
				'generic' => q#Oge Lord Howe#,
				'standard' => q#Oge Izugbe Lord Howe#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Magadan#,
				'generic' => q#Oge Magadan#,
				'standard' => q#Oge Izugbe Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Oge Malaysia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Oge Maldives#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Oge Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Oge Marshall Islands#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Mauritius#,
				'generic' => q#Oge Mauritius#,
				'standard' => q#Oge Izugbe Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Oge Mawson#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Oge Ihe Mexican Pacific#,
				'generic' => q#Oge Mexican Pacific#,
				'standard' => q#Oge Izugbe Mexican Pacific#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Ulaanbaatar#,
				'generic' => q#Oge Ulaanbaatar#,
				'standard' => q#Oge Izugbe Ulaanbaatar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Moscow#,
				'generic' => q#Oge Moscow#,
				'standard' => q#Oge Izugbe Moscow#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Oge Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Oge Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Oge Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Oge Okpomọkụ New Caledonia#,
				'generic' => q#Oge New Caledonia#,
				'standard' => q#Oge Izugbe New Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Oge Ihe New Zealand#,
				'generic' => q#Oge New Zealand#,
				'standard' => q#Oge Izugbe New Zealand#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Oge Ihe Newfoundland#,
				'generic' => q#Oge Newfoundland#,
				'standard' => q#Oge Izugbe Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Oge Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Norfolk Island#,
				'generic' => q#Oge Norfolk Island#,
				'standard' => q#Oge Izugbe Norfolk Island#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Fernando de Noronha#,
				'generic' => q#Oge Fernando de Noronha#,
				'standard' => q#Oge Izugbe Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Novosibirsk#,
				'generic' => q#Oge Novosibirsk#,
				'standard' => q#Oge Izugbe Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Omsk#,
				'generic' => q#Oge Omsk#,
				'standard' => q#Oge Izugbe Omsk#,
			},
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Pakistan#,
				'generic' => q#Oge Pakistan#,
				'standard' => q#Oge Izugbe Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Oge Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Oge Papua New Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Paraguay#,
				'generic' => q#Oge Paraguay#,
				'standard' => q#Oge Izugbe Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Peru#,
				'generic' => q#Oge Peru#,
				'standard' => q#Oge Izugbe Peru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Philippine#,
				'generic' => q#Oge Philippine#,
				'standard' => q#Oge Izugbe Philippine#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Oge Phoenix Islands#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Oge Ihe St. Pierre & Miquelon#,
				'generic' => q#Oge St. Pierre & Miquelon#,
				'standard' => q#Oge Izugbe St. Pierre & Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Oge Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Oge Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Oge Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Oge Réunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Oge Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Sakhalin#,
				'generic' => q#Oge Sakhalin#,
				'standard' => q#Oge Izugbe Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Oge Ihe Samoa#,
				'generic' => q#Oge Samoa#,
				'standard' => q#Oge Izugbe Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Oge Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Oge Izugbe Singapore#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Oge Solomon Islands#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Oge South Georgia#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Oge Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Oge Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Oge Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Oge Ihe Taipei#,
				'generic' => q#Oge Taipei#,
				'standard' => q#Oge Izugbe Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Oge Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Oge Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Tonga#,
				'generic' => q#Oge Tonga#,
				'standard' => q#Oge Izugbe Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Oge Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Turkmenist#,
				'generic' => q#Oge Turkmenist#,
				'standard' => q#Oge Izugbe Turkmenist#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Oge Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Uruguay#,
				'generic' => q#Oge Uruguay#,
				'standard' => q#Oge Izugbe Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Uzbekist#,
				'generic' => q#Oge Uzbekist#,
				'standard' => q#Oge Izugbe Uzbekist#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Vanuatu#,
				'generic' => q#Oge Vanuatu#,
				'standard' => q#Oge Izugbe Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Oge Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Vladivostok#,
				'generic' => q#Oge Vladivostok#,
				'standard' => q#Oge Izugbe Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Volgograd#,
				'generic' => q#Oge Volgograd#,
				'standard' => q#Oge Izugbe Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Oge Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Oge Wake Island#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Oge Wallis & Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Yakutsk#,
				'generic' => q#Oge Yakutsk#,
				'standard' => q#Oge Izugbe Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Oge Okpomọkụ Yekaterinburg#,
				'generic' => q#Oge Yekaterinburg#,
				'standard' => q#Oge Izugbe Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Oge Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
