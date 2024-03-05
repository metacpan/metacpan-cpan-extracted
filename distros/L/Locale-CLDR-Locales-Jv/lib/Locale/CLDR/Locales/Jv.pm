=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Jv - Package for language Javanese

=cut

package Locale::CLDR::Locales::Jv;
# This file auto generated from Data\common\main\jv.xml
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
				'ab' => 'Abkhazian',
 				'ace' => 'Achinese',
 				'ada' => 'Adangme',
 				'ady' => 'Adyghe',
 				'af' => 'Afrika',
 				'agq' => 'Aghem',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'ale' => 'Aleut',
 				'alt' => 'Altai Sisih Kidul',
 				'am' => 'Amharik',
 				'an' => 'Aragonese',
 				'ann' => 'Obolo',
 				'anp' => 'Angika',
 				'ar' => 'Arab',
 				'ar_001' => 'Arab Standar Anyar',
 				'arn' => 'Mapushe',
 				'arp' => 'Arapaho',
 				'ars' => 'Arab Najdi',
 				'as' => 'Assam',
 				'asa' => 'Asu',
 				'ast' => 'Asturia',
 				'atj' => 'Atikamekw',
 				'av' => 'Avaric',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Azerbaijan',
 				'ba' => 'Bashkir',
 				'ban' => 'Bali',
 				'bas' => 'Basaa',
 				'be' => 'Belarus',
 				'bem' => 'Bemba',
 				'bez' => 'Bena',
 				'bg' => 'Bulgaria',
 				'bgc' => 'Haryanvi',
 				'bho' => 'Bhojpuri',
 				'bi' => 'Bislama',
 				'bin' => 'Bini',
 				'bla' => 'Siksiká',
 				'bm' => 'Bambara',
 				'bn' => 'Bengali',
 				'bo' => 'Tibet',
 				'br' => 'Breton',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnia lan Hercegovina',
 				'bug' => 'Bugis',
 				'byn' => 'Blin',
 				'ca' => 'Katala',
 				'cay' => 'Kayuga',
 				'ccp' => 'Chakma',
 				'ce' => 'Chechen',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Chiga',
 				'ch' => 'Khamorro',
 				'chk' => 'Chuukese',
 				'chm' => 'Mari',
 				'cho' => 'Choctaw',
 				'chp' => 'Chipewyan',
 				'chr' => 'Cherokee',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Kurdi Tengah',
 				'clc' => 'Chilcotin',
 				'co' => 'Korsika',
 				'crg' => 'Michif',
 				'crj' => 'Kree Kidul Wetan',
 				'crk' => 'Kree Polos',
 				'crl' => 'Kree Lor Segara',
 				'crm' => 'Moose Cree',
 				'crr' => 'Karolina Algonquian',
 				'cs' => 'Ceska',
 				'csw' => 'Kree Rawa',
 				'cu' => 'Slavia Gerejani',
 				'cv' => 'Khuvash',
 				'cy' => 'Welsh',
 				'da' => 'Dansk',
 				'dak' => 'Dakota',
 				'dar' => 'Dargwa',
 				'dav' => 'Taita',
 				'de' => 'Jérman',
 				'de_AT' => 'Jérman Ostenrik',
 				'de_CH' => 'Jérman Switserlan',
 				'dgr' => 'Dogrib',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Sorbia Non Standar',
 				'dua' => 'Duala',
 				'dv' => 'Divehi',
 				'dyo' => 'Jola-Fonyi',
 				'dz' => 'Dzongkha',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'eka' => 'Ekajuk',
 				'el' => 'Yunani',
 				'en' => 'Inggris',
 				'en_AU' => 'Inggris Ostrali',
 				'en_CA' => 'Inggris Kanada',
 				'en_GB' => 'Inggris Karajan Manunggal',
 				'en_GB@alt=short' => 'Inggris (Britania)',
 				'en_US' => 'Inggris Amérika Sarékat',
 				'en_US@alt=short' => 'Inggris (AS)',
 				'eo' => 'Esperanto',
 				'es' => 'Spanyol',
 				'es_419' => 'Spanyol (Amerika Latin)',
 				'es_ES' => 'Spanyol (Eropah)',
 				'es_MX' => 'Spanyol (Meksiko)',
 				'et' => 'Estonia',
 				'eu' => 'Basque',
 				'ewo' => 'Ewondo',
 				'fa' => 'Persia',
 				'ff' => 'Fulah',
 				'fi' => 'Suomi',
 				'fil' => 'Tagalog',
 				'fj' => 'Fijian',
 				'fo' => 'Faroe',
 				'fon' => 'Fon',
 				'fr' => 'Prancis',
 				'fr_CA' => 'Prancis Kanada',
 				'fr_CH' => 'Prancis Switserlan',
 				'frc' => 'Prancis Cajun',
 				'frr' => 'Frisian Lor Segara',
 				'fur' => 'Friulian',
 				'fy' => 'Frisia Sisih Kulon',
 				'ga' => 'Irlandia',
 				'gaa' => 'Ga',
 				'gd' => 'Gaulia',
 				'gez' => 'Gees',
 				'gil' => 'Gilbertese',
 				'gl' => 'Galisia',
 				'gn' => 'Guarani',
 				'gor' => 'Gorontalo',
 				'gsw' => 'Jerman Swiss',
 				'gu' => 'Gujarat',
 				'guz' => 'Gusii',
 				'gv' => 'Manx',
 				'gwi' => 'Gwichʼin',
 				'ha' => 'Hausa',
 				'hai' => 'Haida',
 				'haw' => 'Hawaii',
 				'hax' => 'Haida Sisih Kidul',
 				'he' => 'Ibrani',
 				'hi' => 'India',
 				'hil' => 'Hiligainon',
 				'hmn' => 'Hmong',
 				'hr' => 'Kroasia',
 				'hsb' => 'Sorbia Standar',
 				'ht' => 'Kreol Haiti',
 				'hu' => 'Hungaria',
 				'hup' => 'Hupa',
 				'hur' => 'Halkomelem',
 				'hy' => 'Armenia',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Indonesia',
 				'ig' => 'Iqbo',
 				'ii' => 'Sichuan Yi',
 				'ikt' => 'Kanada Inuktitut Sisih Kulon',
 				'ilo' => 'Iloko',
 				'inh' => 'Ingus',
 				'io' => 'Ido',
 				'is' => 'Islandia',
 				'it' => 'Italia',
 				'iu' => 'Inuktitut',
 				'ja' => 'Jepang',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jv' => 'Jawa',
 				'ka' => 'Georgia',
 				'kab' => 'Kabyle',
 				'kac' => 'Kakhin',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kbd' => 'Kabardian',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Kabuverdianu',
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
 				'ko' => 'Korea',
 				'kok' => 'Konkani',
 				'kpe' => 'Kpelle',
 				'kr' => 'Kanuri',
 				'krc' => 'Karachai-Balkar',
 				'krl' => 'Karelian',
 				'kru' => 'Kuruk',
 				'ks' => 'Kashmiri',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Colonia',
 				'ku' => 'Kurdis',
 				'kum' => 'Kumik',
 				'kv' => 'Komi',
 				'kw' => 'Kernowek',
 				'kwk' => 'Kwakʼwala',
 				'ky' => 'Kirgis',
 				'la' => 'Latin',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lb' => 'Luksemburg',
 				'lez' => 'Lesghian',
 				'lg' => 'Ganda',
 				'li' => 'Limburgish',
 				'lil' => 'Lillooet',
 				'lkt' => 'Lakota',
 				'lmo' => 'Lombard',
 				'ln' => 'Lingala',
 				'lo' => 'Laos',
 				'lou' => 'Louisiana Creole',
 				'loz' => 'Losi',
 				'lrc' => 'Luri Sisih Lor',
 				'lsm' => 'Saamia',
 				'lt' => 'Lithuania',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Miso',
 				'luy' => 'Luyia',
 				'lv' => 'Latvia',
 				'mad' => 'Madura',
 				'mag' => 'Magahi',
 				'mai' => 'Maithili',
 				'mak' => 'Makasar',
 				'mas' => 'Masai',
 				'mdf' => 'Moksha',
 				'men' => 'Mende',
 				'mer' => 'Meru',
 				'mfe' => 'Morisyen',
 				'mg' => 'Malagasi',
 				'mgh' => 'Makhuwa-Meeto',
 				'mgo' => 'Meta’',
 				'mh' => 'Marshallese',
 				'mi' => 'Maori',
 				'mic' => 'Mi\'kmak',
 				'min' => 'Minangkabau',
 				'mk' => 'Makedonia',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongolia',
 				'mni' => 'Manipuri',
 				'moe' => 'Innu-aimun',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Marathi',
 				'ms' => 'Melayu',
 				'mt' => 'Malta',
 				'mua' => 'Mundang',
 				'mul' => 'Basa Multilingua',
 				'mus' => 'Muskogee',
 				'mwl' => 'Mirandese',
 				'my' => 'Myanmar',
 				'myv' => 'Ersia',
 				'mzn' => 'Mazanderani',
 				'na' => 'Nauru',
 				'nap' => 'Neapolitan',
 				'naq' => 'Nama',
 				'nb' => 'Bokmål Norwegia',
 				'nd' => 'Ndebele Lor',
 				'nds' => 'Jerman Non Standar',
 				'ne' => 'Nepal',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Niuean',
 				'nl' => 'Walanda',
 				'nl_BE' => 'Flemis',
 				'nmg' => 'Kwasio',
 				'nn' => 'Nynorsk Norwegia',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Norwegia',
 				'nog' => 'Nogai',
 				'nqo' => 'N’Ko',
 				'nr' => 'Ndebele Kidul',
 				'nso' => 'Sotho Sisih Lor',
 				'nus' => 'Nuer',
 				'nv' => 'Navajo',
 				'ny' => 'Nyanja',
 				'nyn' => 'Nyankole',
 				'oc' => 'Ossitan',
 				'ojb' => 'Ojibwa Kulon Segara',
 				'ojc' => 'Ojibwa Tengah',
 				'ojs' => 'Oji-Kree',
 				'ojw' => 'Ojibwa Sisih Kulon',
 				'oka' => 'Okanagan',
 				'om' => 'Oromo',
 				'or' => 'Odia',
 				'os' => 'Ossetia',
 				'pa' => 'Punjab',
 				'pag' => 'Pangasinan',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiamento',
 				'pau' => 'Palauan',
 				'pcm' => 'Nigeria Pidgin',
 				'pis' => 'Pijin',
 				'pl' => 'Polandia',
 				'pqm' => 'Maliseet-Passamakuoddi',
 				'prg' => 'Prusia',
 				'ps' => 'Pashto',
 				'pt' => 'Portugis',
 				'pt_BR' => 'Portugis Brasil',
 				'pt_PT' => 'Portugis Portugal',
 				'qu' => 'Quechua',
 				'raj' => 'Rajasthani',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotongan',
 				'rhg' => 'Rohingya',
 				'rm' => 'Roman',
 				'rn' => 'Rundi',
 				'ro' => 'Rumania',
 				'rof' => 'Rombo',
 				'ru' => 'Rusia',
 				'rup' => 'Aromanian',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskerta',
 				'sad' => 'Sandawe',
 				'sah' => 'Sakha',
 				'saq' => 'Samburu',
 				'sat' => 'Santali',
 				'sba' => 'Ngambai',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardinian',
 				'scn' => 'Sisilia',
 				'sco' => 'Skots',
 				'sd' => 'Sindhi',
 				'se' => 'Sami Sisih Lor',
 				'seh' => 'Sena',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'shi' => 'Tachelhit',
 				'shn' => 'Shan',
 				'si' => 'Sinhala',
 				'sk' => 'Slowakia',
 				'sl' => 'Slovenia',
 				'slh' => 'Lushootseed Sisih Kidul',
 				'sm' => 'Samoa',
 				'smn' => 'Inari Sami',
 				'sms' => 'Skolt Sami',
 				'sn' => 'Shona',
 				'snk' => 'Soninke',
 				'so' => 'Somalia',
 				'sq' => 'Albania',
 				'sr' => 'Serbia',
 				'srn' => 'Sranan Tongo',
 				'ss' => 'Swati',
 				'st' => 'Sotho Sisih Kidul',
 				'str' => 'Selat Salish',
 				'su' => 'Sunda',
 				'suk' => 'Sukuma',
 				'sv' => 'Swedia',
 				'sw' => 'Swahili',
 				'swb' => 'Komorian',
 				'syr' => 'Siriak',
 				'ta' => 'Tamil',
 				'tce' => 'Tutkhone Sisih Kidul',
 				'te' => 'Telugu',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'tet' => 'Tetum',
 				'tg' => 'Tajik',
 				'tgx' => 'Tagish',
 				'th' => 'Thailand',
 				'tht' => 'Tahltan',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tk' => 'Turkmen',
 				'tlh' => 'Klingon',
 				'tli' => 'Tlingit',
 				'tn' => 'Tswana',
 				'to' => 'Tonga',
 				'tok' => 'Toki Pona',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Turki',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tt' => 'Tatar',
 				'ttm' => 'Tutkhone Sisih Lor',
 				'tum' => 'Tumbuka',
 				'tvl' => 'Tupalu',
 				'twq' => 'Tasawaq',
 				'ty' => 'Tahiti',
 				'tyv' => 'Tupinian',
 				'tzm' => 'Tamazight Atlas Tengah',
 				'udm' => 'Udmurt',
 				'ug' => 'Uighur',
 				'uk' => 'Ukraina',
 				'umb' => 'Umbundu',
 				'und' => 'Basa Ora Dikenali',
 				'ur' => 'Urdu',
 				'uz' => 'Uzbek',
 				'vai' => 'Vai',
 				've' => 'Venda',
 				'vi' => 'Vietnam',
 				'vo' => 'Volapuk',
 				'vun' => 'Vunjo',
 				'wa' => 'Walloon',
 				'wae' => 'Walser',
 				'wal' => 'Wolaitta',
 				'war' => 'Warai',
 				'wo' => 'Wolof',
 				'wuu' => 'Tyonghwa Wu',
 				'xal' => 'Kalmik',
 				'xh' => 'Xhosa',
 				'xog' => 'Soga',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Yiddish',
 				'yo' => 'Yoruba',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Kanton',
 				'yue@alt=menu' => 'Tyonghwa, Kanton',
 				'zgh' => 'Tamazight Moroko Standar',
 				'zh' => 'Tyonghwa',
 				'zh@alt=menu' => 'Tyonghwa, Mandarin',
 				'zh_Hans' => 'Tyonghwa (Ringkes)',
 				'zh_Hans@alt=long' => 'Tyonghwa Mandarin (Ringkes)',
 				'zh_Hant' => 'Tyonghwa (Tradisional)',
 				'zh_Hant@alt=long' => 'Tyonghwa Mandarin (Tradisional)',
 				'zu' => 'Zulu',
 				'zun' => 'Zuni',
 				'zxx' => 'Konten tanpa linguistik',
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
 			'Arab' => 'hija’iyah',
 			'Aran' => 'Nastalik',
 			'Armn' => 'Armenia',
 			'Beng' => 'Bangla',
 			'Bopo' => 'Bopomofo',
 			'Brai' => 'Braille',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Wanda Manunggal Aborigin Kanada',
 			'Cher' => 'Sherokee',
 			'Cyrl' => 'Sirilik',
 			'Deva' => 'Devanagari',
 			'Ethi' => 'Ethiopik',
 			'Geor' => 'Georgia',
 			'Grek' => 'Yunani',
 			'Gujr' => 'Gujarati',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Han nganggo Bopomofo',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hans' => 'Prasaja',
 			'Hans@alt=stand-alone' => 'Han Prasaja',
 			'Hant' => 'Tradhisional',
 			'Hant@alt=stand-alone' => 'Han Tradhisional',
 			'Hebr' => 'Ibrani',
 			'Hira' => 'Hiragana',
 			'Hrkt' => 'Silabaris Jepang',
 			'Jpan' => 'Jepang',
 			'Kana' => 'Katakana',
 			'Khmr' => 'Khmer',
 			'Knda' => 'Kannada',
 			'Kore' => 'Korea',
 			'Laoo' => 'Lao',
 			'Latn' => 'Latin',
 			'Mlym' => 'Malayalam',
 			'Mong' => 'Mongolia',
 			'Mtei' => 'Meitei Mayek',
 			'Mymr' => 'Myanmar',
 			'Nkoo' => 'N’Ko',
 			'Olck' => 'Ol Chiki',
 			'Orya' => 'Odia',
 			'Rohg' => 'Hanifi',
 			'Sinh' => 'Sinhala',
 			'Sund' => 'Sunda',
 			'Syrc' => 'Siriak',
 			'Taml' => 'Tamil',
 			'Telu' => 'Telugu',
 			'Tfng' => 'Tifinak',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thailand',
 			'Tibt' => 'Tibetan',
 			'Vaii' => 'Vai',
 			'Yiii' => 'Yi',
 			'Zmth' => 'Notasi Matematika',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Simbol',
 			'Zxxx' => 'Ora Ketulis',
 			'Zyyy' => 'Umum',
 			'Zzzz' => 'Skrip Ora Dikenali',

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
			'001' => 'Donya',
 			'002' => 'Afrika',
 			'003' => 'Amérika Lor',
 			'005' => 'Amérika Kidul',
 			'009' => 'Oséania',
 			'011' => 'Afrika Kulon',
 			'013' => 'Amérika Tengah',
 			'014' => 'Afrika Wétan',
 			'015' => 'Afrika Lor',
 			'017' => 'Afrika Sisih Tengah',
 			'018' => 'Afrika Sisih Kidul',
 			'019' => 'Amérika',
 			'021' => 'Amérika Sisih Lor',
 			'029' => 'Karibia',
 			'030' => 'Asia Wétan',
 			'034' => 'Asia Kidul',
 			'035' => 'Asia Kidul-wétan',
 			'039' => 'Éropah Kidul',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Daerah Mikronesia',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia Tengah',
 			'145' => 'Asia Kulon',
 			'150' => 'Éropah',
 			'151' => 'Éropah Wétan',
 			'154' => 'Éropah Lor',
 			'155' => 'Éropah Kulon',
 			'202' => 'Afrika Kidule Sahara',
 			'419' => 'Amérika Latin',
 			'AC' => 'Pulo Ascension',
 			'AD' => 'Andora',
 			'AE' => 'Uni Émirat Arab',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua lan Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albani',
 			'AM' => 'Arménia',
 			'AO' => 'Angola',
 			'AQ' => 'Antartika',
 			'AR' => 'Argèntina',
 			'AS' => 'Samoa Amerika',
 			'AT' => 'Ostenrik',
 			'AU' => 'Ostrali',
 			'AW' => 'Aruba',
 			'AX' => 'Kapuloan Alan',
 			'AZ' => 'Azerbaijan',
 			'BA' => 'Bosnia lan Hèrségovina',
 			'BB' => 'Barbadhos',
 			'BD' => 'Banggaladésa',
 			'BE' => 'Bèlgi',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgari',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Bénin',
 			'BL' => 'Saint Barthélémi',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunéi',
 			'BO' => 'Bolivia',
 			'BQ' => 'Karibia Walanda',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Pulo Bovèt',
 			'BW' => 'Botswana',
 			'BY' => 'Bélarus',
 			'BZ' => 'Bélisé',
 			'CA' => 'Kanada',
 			'CC' => 'Kapuloan Cocos (Keeling)',
 			'CD' => 'Kongo - Kinshasa',
 			'CD@alt=variant' => 'Républik Dhémokratik Kongo',
 			'CF' => 'Républik Afrika Tengah',
 			'CG' => 'Kongo - Brassaville',
 			'CG@alt=variant' => 'Républik Kongo',
 			'CH' => 'Switserlan',
 			'CI' => 'Pasisir Gadhing',
 			'CK' => 'Kapuloan Cook',
 			'CL' => 'Cilé',
 			'CM' => 'Kamerun',
 			'CN' => 'Tyongkok',
 			'CO' => 'Kolombia',
 			'CP' => 'Pulo Clipperton',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Pongol Verdé',
 			'CW' => 'Kurasao',
 			'CX' => 'Pulo Natal',
 			'CY' => 'Siprus',
 			'CZ' => 'Céko',
 			'CZ@alt=variant' => 'Républik Céko',
 			'DE' => 'Jérman',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Jibuti',
 			'DK' => 'Dhènemarken',
 			'DM' => 'Dominika',
 			'DO' => 'Républik Dominika',
 			'DZ' => 'Aljasair',
 			'EA' => 'Séuta lan Melila',
 			'EC' => 'Ékuadhor',
 			'EE' => 'Éstonia',
 			'EG' => 'Mesir',
 			'EH' => 'Sahara Kulon',
 			'ER' => 'Éritréa',
 			'ES' => 'Sepanyol',
 			'ET' => 'Étiopia',
 			'EU' => 'Uni Éropah',
 			'EZ' => 'Zona Éuro',
 			'FI' => 'Finlan',
 			'FJ' => 'Fiji',
 			'FK' => 'Kapuloan Falkland',
 			'FK@alt=variant' => 'Kapuloan Falkland (Islas Malvinas)',
 			'FM' => 'Féderasi Mikronésia',
 			'FO' => 'Kapuloan Faro',
 			'FR' => 'Prancis',
 			'GA' => 'Gabon',
 			'GB' => 'Karajan Manunggal',
 			'GB@alt=short' => 'KM',
 			'GD' => 'Grénada',
 			'GE' => 'Géorgia',
 			'GF' => 'Guyana Prancis',
 			'GG' => 'Guernsei',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadélup',
 			'GQ' => 'Guinéa Katulistiwa',
 			'GR' => 'Grikenlan',
 			'GS' => 'Georgia Kidul lan Kapuloan Sandwich Kidul',
 			'GT' => 'Guatémala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Laladan Administratif Astamiwa Hong Kong',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Kapuloan Heard lan McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Kroasia',
 			'HT' => 'Haiti',
 			'HU' => 'Honggari',
 			'IC' => 'Kapuloan Kanari',
 			'ID' => 'Indonésia',
 			'IE' => 'Républik Irlan',
 			'IL' => 'Israèl',
 			'IM' => 'Pulo Man',
 			'IN' => 'Indhia',
 			'IO' => 'Wilayah Inggris ing Segara Hindia',
 			'IO@alt=chagos' => 'Kapuloan Chagos',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Èslan',
 			'IT' => 'Itali',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Yordania',
 			'JP' => 'Jepang',
 			'KE' => 'Kénya',
 			'KG' => 'Kirgistan',
 			'KH' => 'Kamboja',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoro',
 			'KN' => 'Saint Kits lan Nèvis',
 			'KP' => 'Korea Lor',
 			'KR' => 'Koréa Kidul',
 			'KW' => 'Kuwait',
 			'KY' => 'Kapuloan Kéman',
 			'KZ' => 'Kasakstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'Santa Lusia',
 			'LI' => 'Liktenstén',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Libèria',
 			'LS' => 'Lésotho',
 			'LT' => 'Litowen',
 			'LU' => 'Luksemburg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'ME' => 'Montenégro',
 			'MF' => 'Santa Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Kapuloan Marshall',
 			'MK' => 'Républik Makédonia Lor',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Laladan Administratif Astamiwa Makau',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Kapuloan Mariana Lor',
 			'MQ' => 'Martinik',
 			'MR' => 'Mauritania',
 			'MS' => 'Monsérat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maladéwa',
 			'MW' => 'Malawi',
 			'MX' => 'Mèksiko',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibia',
 			'NC' => 'Kalédonia Anyar',
 			'NE' => 'Nigér',
 			'NF' => 'Pulo Norfolk',
 			'NG' => 'Nigéria',
 			'NI' => 'Nikaragua',
 			'NL' => 'Walanda',
 			'NO' => 'Nurwègen',
 			'NP' => 'Népal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Selandia Anyar',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinesia Prancis',
 			'PG' => 'Papua Nugini',
 			'PH' => 'Pilipina',
 			'PK' => 'Pakistan',
 			'PL' => 'Polen',
 			'PM' => 'Saint Pièr lan Mikuélon',
 			'PN' => 'Kapuloan Pitcairn',
 			'PR' => 'Puèrto Riko',
 			'PS' => 'Tlatah Palèstina',
 			'PS@alt=short' => 'Palèstina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Katar',
 			'QO' => 'Oseania Paling Njaba',
 			'RE' => 'Réunion',
 			'RO' => 'Ruméni',
 			'RS' => 'Sèrbi',
 			'RU' => 'Rusia',
 			'RW' => 'Rwanda',
 			'SA' => 'Arab Saudi',
 			'SB' => 'Kapuloan Suleman',
 			'SC' => 'Sésèl',
 			'SD' => 'Sudan',
 			'SE' => 'Swèdhen',
 			'SG' => 'Singapura',
 			'SH' => 'Saint Héléna',
 			'SI' => 'Slovénia',
 			'SJ' => 'Svalbard lan Jan Mayen',
 			'SK' => 'Slowak',
 			'SL' => 'Siéra Léoné',
 			'SM' => 'San Marino',
 			'SN' => 'Sénégal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Sudan Kidul',
 			'ST' => 'Sao Tomé lan Principé',
 			'SV' => 'Èl Salvador',
 			'SX' => 'Sint Martén',
 			'SY' => 'Suriah',
 			'SZ' => 'Swasiland',
 			'SZ@alt=variant' => '(Swasiland)',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks lan Kapuloan Kaikos',
 			'TD' => 'Chad',
 			'TF' => 'Wilayah Prancis nang Kutub Kidul',
 			'TG' => 'Togo',
 			'TH' => 'Tanah Thai',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor Leste',
 			'TL@alt=variant' => 'Timor Wétan',
 			'TM' => 'Turkménistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turki',
 			'TT' => 'Trinidad lan Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansania',
 			'UA' => 'Ukrania',
 			'UG' => 'Uganda',
 			'UM' => 'Kapuloan AS Paling Njaba',
 			'UN' => 'Pasarékatan Bangsa-Bangsa',
 			'US' => 'Amérika Sarékat',
 			'US@alt=short' => 'AS',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbèkistan',
 			'VA' => 'Kutha Vatikan',
 			'VC' => 'Saint Vinsen lan Grénadin',
 			'VE' => 'Vénésuéla',
 			'VG' => 'Kapuloan Virgin Britania',
 			'VI' => 'Kapuloan Virgin Amérika',
 			'VN' => 'Viètnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis lan Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Logat Semu',
 			'XB' => 'Rong Arah Semu',
 			'XK' => 'Kosovo',
 			'YE' => 'Yaman',
 			'YT' => 'Mayotte',
 			'ZA' => 'Afrika Kidul',
 			'ZM' => 'Sambia',
 			'ZW' => 'Simbabwe',
 			'ZZ' => 'Daerah Ora Dikenali',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Tanggalan',
 			'cf' => 'Format Mata Uang',
 			'collation' => 'Urutan Pamilahan',
 			'currency' => 'Mata Uang',
 			'hc' => 'Siklus Jam (12 vs 24)',
 			'lb' => 'Gaya Ganti Baris',
 			'ms' => 'Sistem Pangukuran',
 			'numbers' => 'Angka',

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
 				'buddhist' => q{Tanggalan Buddha},
 				'chinese' => q{Tanggalan Cina},
 				'coptic' => q{Tanggalan Koptik},
 				'dangi' => q{Tanggalan Dangi},
 				'ethiopic' => q{Tanggalan Etiopia},
 				'ethiopic-amete-alem' => q{Tanggalan Etiopia Amete Alem},
 				'gregorian' => q{Tanggalan Gregorian},
 				'hebrew' => q{Tanggalan Ibrani},
 				'islamic' => q{Tanggalan Hijriah},
 				'islamic-civil' => q{Tanggalan Hijriah (tabel, jaman sipil)},
 				'islamic-tbla' => q{Tanggalan Hijriah (tabel, jaman astronomis)},
 				'islamic-umalqura' => q{Tanggalan Hijriah (Umm al-Qura)},
 				'iso8601' => q{Tanggalan ISO-8601},
 				'japanese' => q{Tanggalan Jepang},
 				'persian' => q{Tanggalan Persia},
 				'roc' => q{Tanggalan Minguo},
 			},
 			'cf' => {
 				'account' => q{Format Mata Uang Akuntansi},
 				'standard' => q{Format Mata Uang Standar},
 			},
 			'collation' => {
 				'ducet' => q{Urutan Pamilahan Unicode Default},
 				'search' => q{Panlusuran Tujuan Umum},
 				'standard' => q{Standar Ngurutke Urutan},
 			},
 			'hc' => {
 				'h11' => q{Sistem 12 Jam (0–11)},
 				'h12' => q{Sistem 12 Jam (1–12)},
 				'h23' => q{Sistem 24 Jam (0–23)},
 				'h24' => q{Sistem 24 Jam (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Gaya Ganti Baris Longgar},
 				'normal' => q{Gaya Ganti Baris Normal},
 				'strict' => q{Gaya Ganti Baris Strik},
 			},
 			'ms' => {
 				'metric' => q{Sistem Metrik},
 				'uksystem' => q{Sistem Pangukuran Imperial},
 				'ussystem' => q{Sistem Pangukuran AS},
 			},
 			'numbers' => {
 				'arab' => q{Digit Hindu-Arab},
 				'arabext' => q{Digit Hindu-Arab Diambakake},
 				'armn' => q{Angka Armenia},
 				'armnlow' => q{Angka Huruf Cilik Armenia},
 				'beng' => q{Digit Bengali},
 				'cakm' => q{Digit Chakma},
 				'deva' => q{Digit Devanagari},
 				'ethi' => q{Angka Etiopia},
 				'fullwide' => q{Digit Amba Kebak},
 				'geor' => q{Angka Georgian},
 				'grek' => q{Angka Yunani},
 				'greklow' => q{Angka Huruf Cilik Yunani},
 				'gujr' => q{Digit Gujarat},
 				'guru' => q{Digit Gurmukhi},
 				'hanidec' => q{Angka Desimal Mandarin},
 				'hans' => q{Angka Mandarin Ringkes},
 				'hansfin' => q{Angka Finansial Mandarin Ringkes},
 				'hant' => q{Angka Mandarin Tradisional},
 				'hantfin' => q{Angka Finansial Mandarin Tradisional},
 				'hebr' => q{Angka Ibrani},
 				'java' => q{Digit Jawa},
 				'jpan' => q{Angka Jepang},
 				'jpanfin' => q{Angka Finansial Jepang},
 				'khmr' => q{Digit Khmer},
 				'knda' => q{Digit Kannada},
 				'laoo' => q{Digit Lao},
 				'latn' => q{Digit Latin},
 				'mlym' => q{Digit Malayalam},
 				'mtei' => q{Digit Meetei Mayek},
 				'mymr' => q{Digit Myanmar},
 				'olck' => q{Digit Ol Chiki},
 				'orya' => q{Digit Odia},
 				'roman' => q{Angka Romawi},
 				'romanlow' => q{Angka Huruf Cilik Romawi},
 				'taml' => q{Angka Tamil Tradisional},
 				'tamldec' => q{Digit Tamil},
 				'telu' => q{Digit Telugu},
 				'thai' => q{Digit Thailand},
 				'tibt' => q{Digit Tibet},
 				'vaii' => q{Digit Vai},
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
			'metric' => q{Metrik},
 			'UK' => q{BR},
 			'US' => q{AS},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Basa: {0}',
 			'script' => 'Skrip: {0}',
 			'region' => 'Daerah: {0}',

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
			auxiliary => qr{[f q v x z]},
			index => ['AÂÅ', 'B', 'C', 'D', 'EÉÈÊ', 'G', 'H', 'IÌ', 'J', 'K', 'L', 'M', 'N', 'OÒ', 'P', 'R', 'S', 'T', 'UÙ', 'W', 'Y'],
			main => qr{[aâå b c d eéèê g h iì j k l m n oò p r s t uù w y]},
		};
	},
EOT
: sub {
		return { index => ['AÂÅ', 'B', 'C', 'D', 'EÉÈÊ', 'G', 'H', 'IÌ', 'J', 'K', 'L', 'M', 'N', 'OÒ', 'P', 'R', 'S', 'T', 'UÙ', 'W', 'Y'], };
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
						'name' => q(arah kardinal),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(arah kardinal),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(Kibi{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(Kibi{0}),
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
						'1' => q(yobe{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(desi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(desi{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(piko{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(piko{0}),
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
						'1' => q(senti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(senti{0}),
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
						'1' => q(yokto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yokto{0}),
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
						'1' => q(mili{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(mili{0}),
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
						'1' => q(mikro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(mikro{0}),
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
						'1' => q(hekto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hekto{0}),
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
						'other' => q({0} tenaga-g),
					},
					# Core Unit Identifier
					'g-force' => {
						'other' => q({0} tenaga-g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meter saben detik kuadrat),
						'other' => q({0} meter saben detik kuadrat),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meter saben detik kuadrat),
						'other' => q({0} meter saben detik kuadrat),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'other' => q({0} derajat),
					},
					# Core Unit Identifier
					'degree' => {
						'other' => q({0} derajat),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radian),
						'other' => q({0} radian),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radian),
						'other' => q({0} radian),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(revolusi),
						'other' => q({0} revolusi),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(revolusi),
						'other' => q({0} revolusi),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'other' => q({0} hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'other' => q({0} hektar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(sentimeter pesagi),
						'other' => q({0} sentimeter pesagi),
						'per' => q({0} saben sentimeter pesagi),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sentimeter pesagi),
						'other' => q({0} sentimeter pesagi),
						'per' => q({0} saben sentimeter pesagi),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(inci pesagi),
						'other' => q({0} inci pesagi),
						'per' => q({0} saben inci pesagi),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(inci pesagi),
						'other' => q({0} inci pesagi),
						'per' => q({0} saben inci pesagi),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilometer pesagi),
						'other' => q({0} kilometer pesagi),
						'per' => q({0} saben kilometer pesagi),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilometer pesagi),
						'other' => q({0} kilometer pesagi),
						'per' => q({0} saben kilometer pesagi),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(meter pesagi),
						'other' => q({0} meter pesagi),
						'per' => q({0} saben meter pesagi),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(meter pesagi),
						'other' => q({0} meter pesagi),
						'per' => q({0} saben meter pesagi),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mil pesagi),
						'other' => q({0} mil pesagi),
						'per' => q({0} saben mil pesagi),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mil pesagi),
						'other' => q({0} mil pesagi),
						'per' => q({0} saben mil pesagi),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yard pesagi),
						'other' => q({0} yard pesagi),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yard pesagi),
						'other' => q({0} yard pesagi),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'karat' => {
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligram saben desiliter),
						'other' => q({0} miligram saben desiliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligram saben desiliter),
						'other' => q({0} miligram saben desiliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimol saben liter),
						'other' => q({0} milimol saben liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimol saben liter),
						'other' => q({0} milimol saben liter),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'other' => q({0} persen),
					},
					# Core Unit Identifier
					'percent' => {
						'other' => q({0} persen),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'other' => q({0} permil),
					},
					# Core Unit Identifier
					'permille' => {
						'other' => q({0} permil),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(bagean saben yuta),
						'other' => q({0} bagean saben yuta),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(bagean saben yuta),
						'other' => q({0} bagean saben yuta),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'other' => q({0} permiriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'other' => q({0} permiriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(liter saben 100 kilometer),
						'other' => q({0} liter saben 100 kilometer),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(liter saben 100 kilometer),
						'other' => q({0} liter saben 100 kilometer),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(liter saben kilometer),
						'other' => q({0} liter saben kilometer),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(liter saben kilometer),
						'other' => q({0} liter saben kilometer),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mil saben galon),
						'other' => q({0} mil saben galon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil saben galon),
						'other' => q({0} mil saben galon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil saben galon inggris),
						'other' => q({0} mil saben galon inggris),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil saben galon inggris),
						'other' => q({0} mil saben galon inggris),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabit),
						'other' => q({0} gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabit),
						'other' => q({0} gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabite),
						'other' => q({0} gigabite),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabite),
						'other' => q({0} gigabite),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobit),
						'other' => q({0} kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobit),
						'other' => q({0} kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobite),
						'other' => q({0} kilobite),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobite),
						'other' => q({0} kilobite),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabit),
						'other' => q({0} megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabit),
						'other' => q({0} megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabite),
						'other' => q({0} megabite),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabite),
						'other' => q({0} megabite),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabite),
						'other' => q({0} petabite),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabite),
						'other' => q({0} petabite),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabit),
						'other' => q({0} terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabit),
						'other' => q({0} terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabite),
						'other' => q({0} terabite),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabite),
						'other' => q({0} terabite),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} saben dina),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} saben dina),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dasawarsa),
						'other' => q({0} dasawarsa),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dasawarsa),
						'other' => q({0} dasawarsa),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'per' => q({0} saben jam),
					},
					# Core Unit Identifier
					'hour' => {
						'per' => q({0} saben jam),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrodetik),
						'other' => q({0} mikrodetik),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrodetik),
						'other' => q({0} mikrodetik),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milidetik),
						'other' => q({0} milidetik),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milidetik),
						'other' => q({0} milidetik),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(menit),
						'other' => q({0} menit),
						'per' => q({0} saben menit),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(menit),
						'other' => q({0} menit),
						'per' => q({0} saben menit),
					},
					# Long Unit Identifier
					'duration-month' => {
						'per' => q({0} saben sasi),
					},
					# Core Unit Identifier
					'month' => {
						'per' => q({0} saben sasi),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanodetik),
						'other' => q({0} nanodetik),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanodetik),
						'other' => q({0} nanodetik),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(detik),
						'other' => q({0} detik),
						'per' => q({0} saben detik),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(detik),
						'other' => q({0} detik),
						'per' => q({0} saben detik),
					},
					# Long Unit Identifier
					'duration-week' => {
						'per' => q({0} saben peken),
					},
					# Core Unit Identifier
					'week' => {
						'per' => q({0} saben peken),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0} saben taun),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0} saben taun),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'other' => q({0} amper),
					},
					# Core Unit Identifier
					'ampere' => {
						'other' => q({0} amper),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'other' => q({0} miliamper),
					},
					# Core Unit Identifier
					'milliampere' => {
						'other' => q({0} miliamper),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(takeran panas Britania),
						'other' => q({0} takeran panas Britania),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(takeran panas Britania),
						'other' => q({0} takeran panas Britania),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kalori),
						'other' => q({0} kalori),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kalori),
						'other' => q({0} kalori),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'other' => q({0} elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'other' => q({0} elektronvolt),
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
					'energy-joule' => {
						'other' => q({0} jol),
					},
					# Core Unit Identifier
					'joule' => {
						'other' => q({0} jol),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokalori),
						'other' => q({0} kilokalori),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokalori),
						'other' => q({0} kilokalori),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'other' => q({0} kilojol),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'other' => q({0} kilojol),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowatt-jam),
						'other' => q({0} kilowatt-jam),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowatt-jam),
						'other' => q({0} kilowatt-jam),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-jam saben 100 kilometer),
						'other' => q({0} kilowatt-jam saben 100 kilometer),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-jam saben 100 kilometer),
						'other' => q({0} kilowatt-jam saben 100 kilometer),
					},
					# Long Unit Identifier
					'force-newton' => {
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'other' => q({0} pon gaya),
					},
					# Core Unit Identifier
					'pound-force' => {
						'other' => q({0} pon gaya),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahet),
						'other' => q({0} gigahet),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahet),
						'other' => q({0} gigahet),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(het),
						'other' => q({0} het),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(het),
						'other' => q({0} het),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohet),
						'other' => q({0} kilohet),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohet),
						'other' => q({0} kilohet),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahet),
						'other' => q({0} megahet),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahet),
						'other' => q({0} megahet),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(titik per sentimeter),
						'other' => q({0} titik per sentimeter),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(titik per sentimeter),
						'other' => q({0} titik per sentimeter),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(titik per inci),
						'other' => q({0} titik per inci),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(titik per inci),
						'other' => q({0} titik per inci),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(tipografi em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(tipografi em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapiksel),
						'other' => q({0} megapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapiksel),
						'other' => q({0} megapiksel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(piksel),
						'other' => q({0} piksel),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(piksel),
						'other' => q({0} piksel),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unit astronomi),
						'other' => q({0} unit astronomi),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unit astronomi),
						'other' => q({0} unit astronomi),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sentimeter),
						'other' => q({0} sentimeter),
						'per' => q({0} saben sentimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sentimeter),
						'other' => q({0} sentimeter),
						'per' => q({0} saben sentimeter),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(desimeter),
						'other' => q({0} desimeter),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(desimeter),
						'other' => q({0} desimeter),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(radius donya),
						'other' => q({0} radius donya),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(radius donya),
						'other' => q({0} radius donya),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'other' => q({0} fathoms),
					},
					# Core Unit Identifier
					'fathom' => {
						'other' => q({0} fathoms),
					},
					# Long Unit Identifier
					'length-foot' => {
						'per' => q({0} saben kaki),
					},
					# Core Unit Identifier
					'foot' => {
						'per' => q({0} saben kaki),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'other' => q({0} furlongs),
					},
					# Core Unit Identifier
					'furlong' => {
						'other' => q({0} furlongs),
					},
					# Long Unit Identifier
					'length-inch' => {
						'other' => q({0} inci),
						'per' => q({0} saben inci),
					},
					# Core Unit Identifier
					'inch' => {
						'other' => q({0} inci),
						'per' => q({0} saben inci),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} saben kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} saben kilometer),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'other' => q({0} taun cahya),
					},
					# Core Unit Identifier
					'light-year' => {
						'other' => q({0} taun cahya),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(meter),
						'other' => q({0} meter),
						'per' => q({0} saben meter),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(meter),
						'other' => q({0} meter),
						'per' => q({0} saben meter),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrometer),
						'other' => q({0} mikrometer),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrometer),
						'other' => q({0} mikrometer),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(mil-skandinavia),
						'other' => q({0} mil-skandinavia),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(mil-skandinavia),
						'other' => q({0} mil-skandinavia),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimeter),
						'other' => q({0} milimeter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimeter),
						'other' => q({0} milimeter),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometer),
						'other' => q({0} nanometer),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometer),
						'other' => q({0} nanometer),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(mil segoro),
						'other' => q({0} mil segoro),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(mil segoro),
						'other' => q({0} mil segoro),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'other' => q({0} parsek),
					},
					# Core Unit Identifier
					'parsec' => {
						'other' => q({0} parsek),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometer),
						'other' => q({0} pikometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometer),
						'other' => q({0} pikometer),
					},
					# Long Unit Identifier
					'length-point' => {
						'other' => q({0} poin),
					},
					# Core Unit Identifier
					'point' => {
						'other' => q({0} poin),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'other' => q({0} radii srengenge),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'other' => q({0} radii srengenge),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
						'other' => q({0} lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
						'other' => q({0} lumen),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'other' => q({0} luminositas srengenge),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'other' => q({0} luminositas srengenge),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'other' => q({0} massa Bumi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'other' => q({0} massa Bumi),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'other' => q({0} gram),
						'per' => q({0} saben gram),
					},
					# Core Unit Identifier
					'gram' => {
						'other' => q({0} gram),
						'per' => q({0} saben gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} saben kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} saben kilogram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'other' => q({0} mikrogram),
					},
					# Core Unit Identifier
					'microgram' => {
						'other' => q({0} mikrogram),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(miligram),
						'other' => q({0} miligram),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(miligram),
						'other' => q({0} miligram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'per' => q({0} saben ons),
					},
					# Core Unit Identifier
					'ounce' => {
						'per' => q({0} saben ons),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'per' => q({0} saben pon),
					},
					# Core Unit Identifier
					'pound' => {
						'per' => q({0} saben pon),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'other' => q({0} massa srengenge),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'other' => q({0} massa srengenge),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} saben {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} saben {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawatt),
						'other' => q({0} gigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawatt),
						'other' => q({0} gigawatt),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowatt),
						'other' => q({0} kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowatt),
						'other' => q({0} kilowatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawatt),
						'other' => q({0} megawatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawatt),
						'other' => q({0} megawatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(miliwatt),
						'other' => q({0} miliwatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(miliwatt),
						'other' => q({0} miliwatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'other' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'other' => q({0} watt),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(peng loro {0}),
						'other' => q(pesagi {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(peng loro {0}),
						'other' => q(pesagi {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(peng telu {0}),
						'other' => q(kubik {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(peng telu {0}),
						'other' => q(kubik {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfer),
						'other' => q({0} atmosfer),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfer),
						'other' => q({0} atmosfer),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hektopaskal),
						'other' => q({0} hektopaskal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hektopaskal),
						'other' => q({0} hektopaskal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inci saka raksa),
						'other' => q({0} inci saka raksa),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inci saka raksa),
						'other' => q({0} inci saka raksa),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapaskal),
						'other' => q({0} megapaskal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapaskal),
						'other' => q({0} megapaskal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(milibar),
						'other' => q({0} milibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(milibar),
						'other' => q({0} milibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milimeter saka raksa),
						'other' => q({0} milimeter saka raksa),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milimeter saka raksa),
						'other' => q({0} milimeter saka raksa),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(paskal),
						'other' => q({0} paskal),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(paskal),
						'other' => q({0} paskal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(pon saben inci kuadrat),
						'other' => q({0} pon saben inci kuadrat),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pon saben inci kuadrat),
						'other' => q({0} pon saben inci kuadrat),
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
					'speed-kilometer-per-hour' => {
						'name' => q(kilometer saben jam),
						'other' => q({0} kilometer saben jam),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometer saben jam),
						'other' => q({0} kilometer saben jam),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meter saben detik),
						'other' => q({0} meter saben detik),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meter saben detik),
						'other' => q({0} meter saben detik),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mil saben jam),
						'other' => q({0} mil saben jam),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mil saben jam),
						'other' => q({0} mil saben jam),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(derajat celsius),
						'other' => q({0} derajat celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(derajat celsius),
						'other' => q({0} derajat celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(derajat Fahrenhet),
						'other' => q({0} derajat Fahrenhet),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(derajat Fahrenhet),
						'other' => q({0} derajat Fahrenhet),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvin),
						'other' => q({0} kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvin),
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
						'name' => q(newton-meter),
						'other' => q({0} newton-meter),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton-meter),
						'other' => q({0} newton-meter),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'other' => q({0} barel),
					},
					# Core Unit Identifier
					'barrel' => {
						'other' => q({0} barel),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(sentimeter kubik),
						'other' => q({0} sentimeter kubik),
						'per' => q({0} saben sentimeter kubik),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(sentimeter kubik),
						'other' => q({0} sentimeter kubik),
						'per' => q({0} saben sentimeter kubik),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kaki kubik),
						'other' => q({0} kaki kubik),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kaki kubik),
						'other' => q({0} kaki kubik),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inci kubik),
						'other' => q({0} inci kubik),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inci kubik),
						'other' => q({0} inci kubik),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilometer kubik),
						'other' => q({0} kilometer kubik),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilometer kubik),
						'other' => q({0} kilometer kubik),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(meter kubik),
						'other' => q({0} meter kubik),
						'per' => q({0} saben meter kubik),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(meter kubik),
						'other' => q({0} meter kubik),
						'per' => q({0} saben meter kubik),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mil kubik),
						'other' => q({0} mil kubik),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mil kubik),
						'other' => q({0} mil kubik),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yard kubik),
						'other' => q({0} yard kubik),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yard kubik),
						'other' => q({0} yard kubik),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'other' => q({0} metrik kup),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'other' => q({0} metrik kup),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(desiliter),
						'other' => q({0} desiliter),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(desiliter),
						'other' => q({0} desiliter),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'per' => q({0} saben galon),
					},
					# Core Unit Identifier
					'gallon' => {
						'per' => q({0} saben galon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'other' => q({0} galon inggris),
						'per' => q({0} saben galon inggris),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'other' => q({0} galon inggris),
						'per' => q({0} saben galon inggris),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektoliter),
						'other' => q({0} hektoliter),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektoliter),
						'other' => q({0} hektoliter),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'other' => q({0} liter),
						'per' => q({0} saben liter),
					},
					# Core Unit Identifier
					'liter' => {
						'other' => q({0} liter),
						'per' => q({0} saben liter),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megaliter),
						'other' => q({0} megaliter),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megaliter),
						'other' => q({0} megaliter),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililiter),
						'other' => q({0} mililiter),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililiter),
						'other' => q({0} mililiter),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(sak juwit),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(sak juwit),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(sendok mangan),
						'other' => q({0} sendok mangan),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(sendok mangan),
						'other' => q({0} sendok mangan),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(sendok teh),
						'other' => q({0} sendok teh),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(sendok teh),
						'other' => q({0} sendok teh),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'other' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'other' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'other' => q({0} kaki²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'other' => q({0} kaki²),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg inggris),
						'other' => q({0}m/gUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg inggris),
						'other' => q({0}m/gUK),
					},
					# Long Unit Identifier
					'duration-day' => {
						'other' => q({0}d),
					},
					# Core Unit Identifier
					'day' => {
						'other' => q({0}d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0}j),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0}j),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(mdtk),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(mdtk),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'other' => q({0}seprapat),
					},
					# Core Unit Identifier
					'quarter' => {
						'other' => q({0}seprapat),
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
					'energy-therm-us' => {
						'other' => q({0}panas AS),
					},
					# Core Unit Identifier
					'therm-us' => {
						'other' => q({0}panas AS),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'other' => q({0}kWh/km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'other' => q({0}kWh/km),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'other' => q({0}tpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'other' => q({0}tpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'other' => q({0}tpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'other' => q({0}tpi),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'tonne' => {
						'other' => q({0}t),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'other' => q({0}dj),
					},
					# Core Unit Identifier
					'horsepower' => {
						'other' => q({0}dj),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'other' => q({0}lbf⋅kaki),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'other' => q({0}lbf⋅kaki),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'other' => q({0}cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'other' => q({0}cL),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'other' => q({0}sde),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'other' => q({0}sde),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'other' => q({0}sde-lmp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'other' => q({0}sde-lmp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'other' => q({0}by.dr.),
					},
					# Core Unit Identifier
					'dram' => {
						'other' => q({0}by.dr.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'other' => q({0}ons by),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'other' => q({0}ons by),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'other' => q({0}oz lm by),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'other' => q({0}oz lm by),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'other' => q({0}gallm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'other' => q({0}gallm),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'other' => q({0}juwit),
					},
					# Core Unit Identifier
					'pinch' => {
						'other' => q({0}juwit),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'other' => q({0}mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'other' => q({0}mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'other' => q({0}sprt),
					},
					# Core Unit Identifier
					'quart' => {
						'other' => q({0}sprt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'other' => q({0}spt-lmp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'other' => q({0}spt-lmp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'other' => q({0}sdm),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'other' => q({0}sdm),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(arah),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(arah),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(tenaga-g),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(tenaga-g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meter/detik²),
						'other' => q({0} m/detik²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meter/detik²),
						'other' => q({0} m/detik²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(menit saka busur),
						'other' => q({0} menit saka busur),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(menit saka busur),
						'other' => q({0} menit saka busur),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(detik saka busur),
						'other' => q({0} detik saka busur),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(detik saka busur),
						'other' => q({0} detik saka busur),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(derajat),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(derajat),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(are),
						'other' => q({0} are),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(are),
						'other' => q({0} are),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektar),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(kaki pesagi),
						'other' => q({0} kaki pesagi),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kaki pesagi),
						'other' => q({0} kaki pesagi),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(inci²),
						'other' => q({0} inci²),
						'per' => q({0}/inci²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(inci²),
						'other' => q({0} inci²),
						'per' => q({0}/inci²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mil²),
						'other' => q({0} mil²),
						'per' => q({0}/mil²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mil²),
						'other' => q({0} mil²),
						'per' => q({0}/mil²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yard²),
						'other' => q({0} yard²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yard²),
						'other' => q({0} yard²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(iji),
						'other' => q({0} iji),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(iji),
						'other' => q({0} iji),
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
					'concentr-percent' => {
						'name' => q(persen),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(persen),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(permil),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(permil),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(bagean/yuta),
						'other' => q({0}bpj),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(bagean/yuta),
						'other' => q({0}bpj),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(permiriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(permiriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'other' => q({0} L/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'other' => q({0} L/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(liter/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(liter/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mil/galon),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil/galon),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil/galon inggris),
						'other' => q({0} mpg inggris),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil/galon inggris),
						'other' => q({0} mpg inggris),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} wetan),
						'north' => q({0} lor),
						'south' => q({0} kidul),
						'west' => q({0} kulon),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} wetan),
						'north' => q({0} lor),
						'south' => q({0} kidul),
						'west' => q({0} kulon),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bite),
						'other' => q({0} bite),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bite),
						'other' => q({0} bite),
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
						'name' => q(GBite),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GBite),
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
						'name' => q(kBite),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kBite),
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
						'name' => q(MBite),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MBite),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PBite),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PBite),
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
						'name' => q(TBite),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TBite),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dina),
						'other' => q({0} dina),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dina),
						'other' => q({0} dina),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dsw),
						'other' => q({0} dsw),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dsw),
						'other' => q({0} dsw),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(jam),
						'other' => q({0} jam),
						'per' => q({0}/jam),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(jam),
						'other' => q({0} jam),
						'per' => q({0}/jam),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μdtk),
						'other' => q({0} μd),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μdtk),
						'other' => q({0} μd),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milidtk),
						'other' => q({0} md),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milidtk),
						'other' => q({0} md),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(mnt),
						'other' => q({0} mnt),
						'per' => q({0}/mnt),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(mnt),
						'other' => q({0} mnt),
						'per' => q({0}/mnt),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(sasi),
						'other' => q({0} sasi),
						'per' => q({0}/sasi),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(sasi),
						'other' => q({0} sasi),
						'per' => q({0}/sasi),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanodtk),
						'other' => q({0} nd),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanodtk),
						'other' => q({0} nd),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(seprapat),
						'other' => q({0} seprapat),
						'per' => q({0}/seprapat),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(seprapat),
						'other' => q({0} seprapat),
						'per' => q({0}/seprapat),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(dtk),
						'other' => q({0} dtk),
						'per' => q({0}/dtk),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(dtk),
						'other' => q({0} dtk),
						'per' => q({0}/dtk),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(peken),
						'other' => q({0} peken),
						'per' => q({0}/peken),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(peken),
						'other' => q({0} peken),
						'per' => q({0}/peken),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(taun),
						'other' => q({0} taun),
						'per' => q({0}/taun),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(taun),
						'other' => q({0} taun),
						'per' => q({0}/taun),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amper),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amper),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliamper),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliamper),
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
					'energy-calorie' => {
						'name' => q(kal),
						'other' => q({0} kal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kal),
						'other' => q({0} kal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolt),
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
					'energy-joule' => {
						'name' => q(jol),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(jol),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kkal),
						'other' => q({0} kkal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kkal),
						'other' => q({0} kkal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojol),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojol),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kW-jam),
						'other' => q({0} kW-jam),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kW-jam),
						'other' => q({0} kW-jam),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(takeran panas AS),
						'other' => q({0} takeran panas AS),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(takeran panas AS),
						'other' => q({0} takeran panas AS),
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
						'name' => q(pon gaya),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pon gaya),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(titik),
						'other' => q({0} titik),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(titik),
						'other' => q({0} titik),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(tpcm),
						'other' => q({0} tpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(tpcm),
						'other' => q({0} tpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(tpi),
						'other' => q({0} tpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(tpi),
						'other' => q({0} tpi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ua),
						'other' => q({0} ua),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ua),
						'other' => q({0} ua),
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
						'name' => q(kaki),
						'other' => q({0} kaki),
						'per' => q({0}/kaki),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(kaki),
						'other' => q({0} kaki),
						'per' => q({0}/kaki),
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
						'name' => q(inci),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inci),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(taun cahya),
						'other' => q({0} tc),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(taun cahya),
						'other' => q({0} tc),
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
						'name' => q(μmeter),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μmeter),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mil),
						'other' => q({0} mil),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mil),
						'other' => q({0} mil),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsek),
						'other' => q({0} ps),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsek),
						'other' => q({0} ps),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(poin),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(poin),
						'other' => q({0} p),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(radii srengenge),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(radii srengenge),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yard),
						'other' => q({0} yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yard),
						'other' => q({0} yard),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandela),
						'other' => q({0} kandela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandela),
						'other' => q({0} kandela),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(luk),
						'other' => q({0} luk),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(luk),
						'other' => q({0} luk),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(luminositas srengenge),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(luminositas srengenge),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
						'other' => q({0} karat),
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
						'name' => q(massa Bumi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(massa Bumi),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(wiji),
						'other' => q({0} wiji),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(wiji),
						'other' => q({0} wiji),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogram),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ons),
						'other' => q({0} ons),
						'per' => q({0}/ons),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ons),
						'other' => q({0} ons),
						'per' => q({0}/ons),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy ons),
						'other' => q({0} troy ons),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy ons),
						'other' => q({0} troy ons),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pon),
						'other' => q({0} pon),
						'per' => q({0}/pon),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pon),
						'other' => q({0} pon),
						'per' => q({0}/pon),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(massa srengenge),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(massa srengenge),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(watu),
						'other' => q({0} watu),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(watu),
						'other' => q({0} watu),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(ton),
						'other' => q({0} ton),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ton),
						'other' => q({0} ton),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(metrik ton),
						'other' => q({0} metrik ton),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(metrik ton),
						'other' => q({0} metrik ton),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(tenogo jaran),
						'other' => q({0} tenogo jaran),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(tenogo jaran),
						'other' => q({0} tenogo jaran),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/jam),
						'other' => q({0} km/jam),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/jam),
						'other' => q({0} km/jam),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(knot),
						'other' => q({0} knot),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(knot),
						'other' => q({0} knot),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meter/dtk),
						'other' => q({0} m/dtk),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meter/dtk),
						'other' => q({0} m/dtk),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mil/jam),
						'other' => q({0} mil/jam),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mil/jam),
						'other' => q({0} mil/jam),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pon-kaki),
						'other' => q({0} pon-kaki),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pon-kaki),
						'other' => q({0} pon-kaki),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(are-kaki),
						'other' => q({0} are-kaki),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(are-kaki),
						'other' => q({0} are-kaki),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barel),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barel),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(gantang),
						'other' => q({0} gantang),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(gantang),
						'other' => q({0} gantang),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sentiliter),
						'other' => q({0} sentiliter),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sentiliter),
						'other' => q({0} sentiliter),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kaki³),
						'other' => q({0} kaki³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kaki³),
						'other' => q({0} kaki³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inci³),
						'other' => q({0} inci³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inci³),
						'other' => q({0} inci³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mil³),
						'other' => q({0} mil³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mil³),
						'other' => q({0} mil³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yard³),
						'other' => q({0} yard³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yard³),
						'other' => q({0} yard³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(kup),
						'other' => q({0} kup),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(kup),
						'other' => q({0} kup),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(metrik kup),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(metrik kup),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(sendok es),
						'other' => q({0} sendok es),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(sendok es),
						'other' => q({0} sendok es),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Imp. sendok es),
						'other' => q({0} Imp. sendok es),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Imp. sendok es),
						'other' => q({0} Imp. sendok es),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(banyu dram),
						'other' => q({0} banyu dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(banyu dram),
						'other' => q({0} banyu dram),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(tetes),
						'other' => q({0} tetes),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(tetes),
						'other' => q({0} tetes),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(ons banyu),
						'other' => q({0} ons banyu),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(ons banyu),
						'other' => q({0} ons banyu),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. ons banyu),
						'other' => q({0} Imp. ons banyu),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. ons banyu),
						'other' => q({0} Imp. ons banyu),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galon),
						'other' => q({0} galon),
						'per' => q({0}/galon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galon),
						'other' => q({0} galon),
						'per' => q({0}/galon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(galon inggris),
						'other' => q({0} gal inggris),
						'per' => q({0}/galon inggris),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(galon inggris),
						'other' => q({0} gal inggris),
						'per' => q({0}/galon inggris),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(juwit),
						'other' => q({0} sak juwit),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(juwit),
						'other' => q({0} sak juwit),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pin),
						'other' => q({0} pin),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pin),
						'other' => q({0} pin),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(metrik pin),
						'other' => q({0} metrik pin),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(metrik pin),
						'other' => q({0} metrik pin),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(seprapat galon),
						'other' => q({0} seprapat galon),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(seprapat galon),
						'other' => q({0} seprapat galon),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp. seprapat galon),
						'other' => q({0} Imp. seprapat galon),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp. seprapat galon),
						'other' => q({0} Imp. seprapat galon),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(sdk mgn),
						'other' => q({0} sdk mgn),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(sdk mgn),
						'other' => q({0} sdk mgn),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(sdk teh),
						'other' => q({0} sdk teh),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(sdk teh),
						'other' => q({0} sdk teh),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:yoh)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ora|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, lan {1}),
				2 => q({0} lan {1}),
		} }
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'java',
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
					'other' => '0 èwu',
				},
				'10000' => {
					'other' => '00 èwu',
				},
				'100000' => {
					'other' => '000 èwu',
				},
				'1000000' => {
					'other' => '0 yuta',
				},
				'10000000' => {
					'other' => '00 yuta',
				},
				'100000000' => {
					'other' => '000 yuta',
				},
				'1000000000' => {
					'other' => '0 milyar',
				},
				'10000000000' => {
					'other' => '00 milyar',
				},
				'100000000000' => {
					'other' => '000 milyar',
				},
				'1000000000000' => {
					'other' => '0 trilyun',
				},
				'10000000000000' => {
					'other' => '00 trilyun',
				},
				'100000000000000' => {
					'other' => '000 trilyun',
				},
			},
			'short' => {
				'1000' => {
					'other' => '0È',
				},
				'10000' => {
					'other' => '00È',
				},
				'100000' => {
					'other' => '000È',
				},
				'1000000' => {
					'other' => '0Y',
				},
				'10000000' => {
					'other' => '00Y',
				},
				'100000000' => {
					'other' => '000Y',
				},
				'1000000000' => {
					'other' => '0M',
				},
				'10000000000' => {
					'other' => '00M',
				},
				'100000000000' => {
					'other' => '000M',
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
				'currency' => q(Dirham Uni Emirat Arab),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani Afganistan),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek Albania),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram Armenia),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Guilder Antilla Walanda),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza Angola),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso Argentina),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dolar Australia),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Florin Aruban),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat Azerbaijan),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Mark Konvertibel Bosnia-Herzegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dolar Barbadian),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka Bangladesh),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lev Bulgaria),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahrain Dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Franc Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dolar Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dolar Brunai),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano Bolivia),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real Brasil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dolar Bahamian),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum Bhutan),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula Botswana),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Ruble Belarusia),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dolar Belise),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dolar Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Franc Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Franc Swiss),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Peso Chili),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan Tyongkok \(Jaban Rangkah\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Tyongkok),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Peso Kolumbia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colon Kosta Rika),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Peso Konvertibel Kuba),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso Kuba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo Tanjung Verde),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Koruna Czech),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Franc Djibouti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Krone Denmark),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Peso Dominika),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar Algeria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Pound Mesir),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr Ethiopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dolar Fiji),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Pound Kepuloan Falkland),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pound Inggris),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari Georgia),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Cedi Ghana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Pound Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi Gambia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Franc Guinea),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal Guatemala),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dolar Guyana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dolar Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira Honduras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna Kroasia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Forint Hungaria),
			},
		},
		'IDR' => {
			symbol => 'Rp',
			display_name => {
				'currency' => q(Rupiah Indonesia),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Shekel Anyar Israel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupee India),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinar Irak),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial Iran),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Krona Islandia),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dolar Jamaika),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinar Yordania),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yen Jepang),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shilling Kenya),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som Kirgistan),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel Kamboja),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Franc Komoro),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won Korea Lor),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won Korea Kidul),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinar Kuwait),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dolar Kepuloan Caiman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge Kasakhstan),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip Laos),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Pound Libanon),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rupee Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dolar Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesotho Loti),
				'other' => q(Lesotho lotis),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinar Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham Maroko),
				'other' => q(Dirham Moroko),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leu Moldova),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariary Malagasi),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Denar Masedonia),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik Mongol),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca Macau),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya Mauritania \(1973 - 2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya Mauritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupee Mauritius),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa Maladewa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Peso Meksiko),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgit Malaysia),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metical Mosambik),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dolar Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira Nigeria),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Cordoba Nikaragua),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Krone Norwegia),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupee Nepal),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dolar Selandia Anyar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rial Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa Panama),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sol Peru),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina Papua Nugini),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Piso Filipina),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupee Pakistan),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty Polandia),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guarani Paraguay),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Rial Qatar),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Leu Rumania),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinar Serbia),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rubel Rusia),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Franc Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal Saudi),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dolar Kepuloan Solomon),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupee Seichelles),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Pound Sudan),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Krona Swedia),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dolar Singapura),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Pound Santa Helena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leone Sierra Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone Sierra Leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Shilling Somalia),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dolar Suriname),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Pound Sudan Kidul),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra Sao Tome lan Principe),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Pound Siria),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni Swasi),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Baht Thai),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni Tajikistan),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat Turmenistan),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinar Tunisia),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Paʻanga Tonga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lira Turki),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dolar Trinidad lan Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Dolar Anyar Taiwan),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Shilling Tansania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia Ukrania),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shilling Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dolar Amerika Serikat),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Peso Uruguay),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Som Usbekistan),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Bolivar Venezuela \(2008 - 2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bolivar Venezuela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong Vietnam),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala Samoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA Franc Afrika Tengah),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dolar Karibia Wetan),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(CFA Franc Afrika Kulon),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Franc CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Dhuwit Ora Dikenali),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Rial Yaman),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand Afrika Kidul),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha Sambia),
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
							'Jun',
							'Jul',
							'Agt',
							'Sep',
							'Okt',
							'Nov',
							'Des'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Januari',
							'Februari',
							'Maret',
							'April',
							'Mei',
							'Juni',
							'Juli',
							'Agustus',
							'September',
							'Oktober',
							'November',
							'Desember'
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
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Sur.',
							'Sap.',
							'Mul.',
							'B. Mul.',
							'Jum. Aw.',
							'Jum. Ak.',
							'Rej.',
							'Ruw.',
							'Pso.',
							'Shaw.',
							'Slo.',
							'Bsar.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Sura',
							'Sapar',
							'Mulud',
							'Bakda Mulud',
							'Jumadilawal',
							'Jumadilakir',
							'Rejeb',
							'Ruwah',
							'Pasa',
							'Sawal',
							'Selo',
							'Besar'
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
						mon => 'Sen',
						tue => 'Sel',
						wed => 'Rab',
						thu => 'Kam',
						fri => 'Jum',
						sat => 'Sab',
						sun => 'Ahad'
					},
					wide => {
						mon => 'Senin',
						tue => 'Selasa',
						wed => 'Rabu',
						thu => 'Kamis',
						fri => 'Jumat',
						sat => 'Sabtu',
						sun => 'Ahad'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'S',
						tue => 'S',
						wed => 'R',
						thu => 'K',
						fri => 'J',
						sat => 'S',
						sun => 'A'
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
					abbreviated => {0 => 'TW1',
						1 => 'TW2',
						2 => 'TW3',
						3 => 'TW4'
					},
					wide => {0 => 'triwulan kaping pisan',
						1 => 'triwulan kaping loro',
						2 => 'triwulan kaping telu',
						3 => 'triwulan kaping papat'
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
					'am' => q{Isuk},
					'pm' => q{Wengi},
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
				'0' => 'SM',
				'1' => 'M'
			},
			wide => {
				'0' => 'Sakdurunge Masehi',
				'1' => 'Masehi'
			},
		},
		'islamic' => {
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
			'short' => q{dd-MM-y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd-MM-y},
		},
		'islamic' => {
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
		'islamic' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'islamic' => {
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
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{GGGGG dd-MM-y},
			MEd => q{E, dd/MM},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM - y GGGGG},
			yyyyMEd => q{E, dd - MM - y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd - MM - y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			MEd => q{E dd/MM},
			MMMEd => q{E, d MMM},
			MMMMW => q{'pekan' W 'ing' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{MM-y},
			yMEd => q{E, dd-MM-y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd-MM-y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'pekan' w 'ing' Y},
		},
		'islamic' => {
			Ed => q{d E},
			GyMd => q{d/M/y GGGGG},
			yyyyM => q{M/y GGGGG},
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
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM, y G – E, d MMM, y G},
				M => q{E, d MMM – E, d MMM, y G},
				d => q{E, d MMM – E, d MMM, y G},
				y => q{E, d MMM, y – E, d MMM, y G},
			},
			GyMMMd => {
				G => q{d MMM, y G – d MMM, y G},
				M => q{d MMM – d MMM, y G},
				d => q{d – d MMM, y G},
				y => q{d MMM, y – d MMM, y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
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
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d – d},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{MM-y – MM-y GGGGG},
				y => q{MM-y – MM-y GGGGG},
			},
			yMEd => {
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
		},
		'gregorian' => {
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
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
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
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d – d},
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
				M => q{MM-y – MM-y},
				y => q{MM-y – MM-y},
			},
			yMEd => {
				M => q{E, dd-MM-y – E, dd-MM-y},
				d => q{E, dd-MM-y – E, dd-MM-y},
				y => q{E, dd-MM-y – E, dd-MM-y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd-MM-y – dd-MM-y},
				d => q{dd-MM-y – dd-MM-y},
				y => q{dd-MM-y – dd-MM-y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Wektu {0}),
		regionFormat => q(Wektu Ketigo {0}),
		regionFormat => q(Wektu Standar {0}),
		'Afghanistan' => {
			long => {
				'standard' => q#Wektu Afghanistan#,
			},
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kasablanka#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakri#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Wektu Afrika Tengah#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Wektu Afrika Wetan#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Wektu Standar Afrika Kidul#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Wektu Ketigo Afrika Kulon#,
				'generic' => q#Wektu Afrika Kulon#,
				'standard' => q#Wektu Standar Afrika Kulon#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Wektu Ketigo Alaska#,
				'generic' => q#Wektu Alaska#,
				'standard' => q#Wektu Standar Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Wektu Ketigo Amazon#,
				'generic' => q#Wektu Amazon#,
				'standard' => q#Wektu Standar Amazon#,
			},
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Belize' => {
			exemplarCity => q#Belise#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Teluk Cambridge#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Kampo Grande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamarka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kayenne#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caiman#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Ciudad Juáres#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta Rika#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kuiaba#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Benteng Nelson#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Teluk Glace#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Teluk Goose#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifak#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox [Indiana]#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo [Indiana]#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg [Indiana]#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City [Indiana]#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay [Indiana]#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes [Indiana]#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac [Indiana]#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello [Kentucky]#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinik#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendosa#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Kutho Meksiko#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah [Dakota Lor]#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Tengah [Dakota Lor]#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Salem Anyar [Dakota Lor]#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Palabuhan Spanyol#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Riko#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Kali Rainy#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Santa Barthelemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Santa John#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Santa Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Santa Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Santa Vincent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Arus Banter#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Teluk Gludhug#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Wektu Ketigo Tengah#,
				'generic' => q#Wektu Tengah#,
				'standard' => q#Wektu Standar Tengah#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Wektu Ketigo sisih Wetah#,
				'generic' => q#Wektu sisih Wetan#,
				'standard' => q#Wektu Standar sisih Wetan#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Wektu Ketigo Giri#,
				'generic' => q#Wektu Giri#,
				'standard' => q#Wektu Standar Giri#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Wektu Ketigo Pasifik#,
				'generic' => q#Wektu Pasifik#,
				'standard' => q#Wektu Standar Pasifik#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Wektu Ketigo Apia#,
				'generic' => q#Wektu Apia#,
				'standard' => q#Wektu Standar Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Wektu Ketigo Arab#,
				'generic' => q#Wektu Arab#,
				'standard' => q#Wektu Standar Arab#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Wektu Ketigo Argentina#,
				'generic' => q#Wektu Argentina#,
				'standard' => q#Wektu Standar Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Wektu Ketigo Argentina sisih Kulon#,
				'generic' => q#Wektu Argentina sisih Kulon#,
				'standard' => q#Wektu Standar Argentina sisih Kulon#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Wektu Ketigo Armenia#,
				'generic' => q#Wektu Armenia#,
				'standard' => q#Wektu Standar Armenia#,
			},
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkuta#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Yerusalem#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapura#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Wektu Ketigo Atlantik#,
				'generic' => q#Wektu Atlantik#,
				'standard' => q#Wektu Standar Atlantik#,
			},
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanari#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kape Verde#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgia Kidul#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Santa Helena#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Wektu Ketigo Australia Tengah#,
				'generic' => q#Wektu Australia Tengah#,
				'standard' => q#Wektu Standar Australia Tengah#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Wektu Ketigo Australia Tengah sisih Kulon#,
				'generic' => q#Wektu Australia Tengah sisih Kulon#,
				'standard' => q#Wektu Standar Australia Tengah sisih Kulon#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Wektu Ketigo Australia sisih Wetan#,
				'generic' => q#Wektu Australia sisih Wetan#,
				'standard' => q#Wektu Standar Australia sisih Wetan#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Wektu Ketigo Australia sisih Kulon#,
				'generic' => q#Wektu Australia sisih Kulon#,
				'standard' => q#Wektu Standar Australia sisih Kulon#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Wektu Ketigo Azerbaijan#,
				'generic' => q#Wektu Azerbaijan#,
				'standard' => q#Wektu Standar Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Wektu Ketigo Azores#,
				'generic' => q#Wektu Azores#,
				'standard' => q#Wektu Standar Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Wektu Ketigo Bangladesh#,
				'generic' => q#Wektu Bangladesh#,
				'standard' => q#Wektu Standar Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Wektu Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Wektu Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Wektu Ketigo Brasilia#,
				'generic' => q#Wektu Brasilia#,
				'standard' => q#Wektu Standar Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Wektu Brunai Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Wektu Ketigo Tanjung Verde#,
				'generic' => q#Wektu Tanjung Verde#,
				'standard' => q#Wektu Standar Tanjung Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Wektu Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Wektu Ketigo Chatham#,
				'generic' => q#Wektu Chatham#,
				'standard' => q#Wektu Standar Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Wektu Ketigo Chili#,
				'generic' => q#Wektu Chili#,
				'standard' => q#Wektu Standar Chili#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Wektu Ketigo Cina#,
				'generic' => q#Wektu Cina#,
				'standard' => q#Wektu Standar Cina#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#WEktu Ketigo Choibalsan#,
				'generic' => q#Wektu Choibalsan#,
				'standard' => q#Wektu Standar Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Wektu Pulo Natal#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Wektu Kepuloan Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Wektu Ketigo Kolombia#,
				'generic' => q#Wektu Kolombia#,
				'standard' => q#Wektu Standar Kolombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Wektu Ketigo Kepuloan Cook#,
				'generic' => q#Wektu Kepuloan Cook#,
				'standard' => q#Wektu Standar Kepuloan Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Wektu Ketigo Kuba#,
				'generic' => q#Wektu Kuba#,
				'standard' => q#Wektu Standar Kuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Wektu Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Wektu Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Wektu Timor Leste#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Wektu Ketigo Pulo Paskah#,
				'generic' => q#Wektu Pulo Paskah#,
				'standard' => q#Wektu Standar Pulo Paskah#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Wektu Ekuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Wektu Universal Kakoordhinasi#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Kuto Ora Dikenali#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athena#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Wektu Standar Irlandia#,
			},
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Pulo Man#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Wektu Ketigo Inggris#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksemburk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Wektu Ketigo Eropa Tengah#,
				'generic' => q#Wektu Eropa Tengah#,
				'standard' => q#Wektu Standar Eropa Tengah#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Wektu Ketigo Eropa sisih Wetan#,
				'generic' => q#Wektu Eropa sisih Wetan#,
				'standard' => q#Wektu Standar Eropa sisih Wetan#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Wektu Eropa sisih Wetan seng Luwih Adoh#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Wektu Ketigo Eropa sisih Kulon#,
				'generic' => q#Wektu Eropa sisih Kulon#,
				'standard' => q#Wektu Standar Eropa sisih Kulon#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Wektu Ketigo Kepuloan Falkland#,
				'generic' => q#Wektu Kepuloan Falkland#,
				'standard' => q#Wektu Standar Kepuloan Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Wektu Ketigo Fiji#,
				'generic' => q#Wektu Fiji#,
				'standard' => q#Wektu Standar Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Wektu Guiana Prancis#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Wektu Antartika lan Prancis sisih Kidul#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Wektu Rerata Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Wektu Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Wektu Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Wektu Ketigo Georgia#,
				'generic' => q#Wektu Georgia#,
				'standard' => q#Wektu Standar Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Wektu Kepuloan Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Wektu Ketigo Grinland Wetan#,
				'generic' => q#Wektu Grinland Wetan#,
				'standard' => q#Wektu Standar Grinland Wetan#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Wektu Ketigo Grinland Kulon#,
				'generic' => q#Wektu Grinland Kulon#,
				'standard' => q#Wektu Standar Grinland Kulon#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Wektu Standar Teluk#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Wektu Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Wektu Ketigo Hawaii-Aleutian#,
				'generic' => q#Wektu Hawaii-Aleutian#,
				'standard' => q#Wektu Standar Hawaii-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Wektu Ketigo Hong Kong#,
				'generic' => q#Wektu Hong Kong#,
				'standard' => q#Wektu Standar Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Wektu Ketigo Hovd#,
				'generic' => q#Wektu Hovd#,
				'standard' => q#Wektu Standar Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Wektu Standar India#,
			},
		},
		'Indian/Chagos' => {
			exemplarCity => q#Khagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Natal#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoro#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maladewa#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Wektu Segoro Hindia#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Wektu Indocina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Wektu Indonesia Tengah#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Wektu Indonesia sisih Wetan#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Wektu Indonesia sisih Kulon#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Wektu Ketigo Iran#,
				'generic' => q#Wektu Iran#,
				'standard' => q#Wektu Standar Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Wektu Ketigo Irkutsk#,
				'generic' => q#Wektu Irkutsk#,
				'standard' => q#Wektu Standar Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Wektu Ketigo Israel#,
				'generic' => q#Wektu Israel#,
				'standard' => q#Wektu Standar Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Wektu Ketigo Jepang#,
				'generic' => q#Wektu Jepang#,
				'standard' => q#Wektu Standar Jepang#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Wektu Kazakhstan Wetan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Wektu Kazakhstan Kulon#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Wektu Ketigo Korea#,
				'generic' => q#Wektu Korea#,
				'standard' => q#Wektu Standar Korea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Wektu Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Wektu Ketigo Krasnoyarsk#,
				'generic' => q#Wektu Krasnoyarsk#,
				'standard' => q#Wektu Standar Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Wektu Kirgizstan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Wektu Kepuloan Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Wektu Ketigo Lord Howe#,
				'generic' => q#Wektu Lord Howe#,
				'standard' => q#Wektu Standar Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Wektu Pulo Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Wektu Ketigo Magadan#,
				'generic' => q#Wektu Magadan#,
				'standard' => q#Wektu Standar Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Wektu Malaysia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Wektu Maladewa#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Wektu Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Wektu Kepuloan Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Wektu Ketigo Mauritius#,
				'generic' => q#Wektu Mauritius#,
				'standard' => q#Wektu Standar Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Wektu Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Wektu Ketigo Meksiko Lor-Kulon#,
				'generic' => q#Wektu Meksiko Lor-Kulon#,
				'standard' => q#Wektu Standar Meksiko Lor-Kulon#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Wektu Ketigo Pasifik Meksiko#,
				'generic' => q#Wektu Pasifik Meksiko#,
				'standard' => q#Wektu Standar Pasifik Meksiko#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Wektu Ketigo Ulaanbaatar#,
				'generic' => q#Wektu Ulaanbaatar#,
				'standard' => q#Wektu Standar Ulaanbaatar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Wektu Ketigo Moscow#,
				'generic' => q#Wektu Moscow#,
				'standard' => q#Wektu Standar Moscow#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Wektu Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Wektu Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Wektu Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Wektu Ketigo Kaledonia Anyar#,
				'generic' => q#Wektu Kaledonia Anyar#,
				'standard' => q#Wektu Standar Kaledonia Anyar#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Wektu Ketigo Selandia Anyar#,
				'generic' => q#Wektu Selandia Anyar#,
				'standard' => q#Wektu Standar Selandia Anyar#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Wektu Ketigo Newfoundland#,
				'generic' => q#Wektu Newfoundland#,
				'standard' => q#Wektu Standar Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Wektu Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Wektu Ketigo Pulo Norfolk#,
				'generic' => q#Wektu Pulo Norfolk#,
				'standard' => q#Wektu Standar Pulo Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Wektu Ketigo Fernando de Noronha#,
				'generic' => q#Wektu Fernando de Noronha#,
				'standard' => q#Wektu Standar Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Wektu Ketigo Novosibirsk#,
				'generic' => q#Wektu Novosibirsk#,
				'standard' => q#Wektu Standar Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Wektu Ketigo Omsk#,
				'generic' => q#Wektu Omsk#,
				'standard' => q#Wektu Standar Omsk#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Paskah#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Pelabuhan Moresby#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Wektu Ketigo Pakistan#,
				'generic' => q#Wektu Pakistan#,
				'standard' => q#Wektu Standar Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Wektu Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Wektu Papua Nugini#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Wektu Ketigo Paraguay#,
				'generic' => q#Wektu Paraguay#,
				'standard' => q#Wektu Standar Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Wektu Ketigo Peru#,
				'generic' => q#Wektu Peru#,
				'standard' => q#Wektu Standar Peru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Wektu Ketigo Filipina#,
				'generic' => q#Wektu Filipina#,
				'standard' => q#Wektu Standar Filipina#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Wektu Kepuloan Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Wektu Ketigo Santa Pierre lan Miquelon#,
				'generic' => q#Wektu Santa Pierre lan Miquelon#,
				'standard' => q#Wektu Standar Santa Pierre lan Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Wektu Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Wektu Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Wektu Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Wektu Reunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Wektu Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Wektu Ketigo Sakhalin#,
				'generic' => q#Wektu Sakhalin#,
				'standard' => q#Wektu Standar Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Wektu Ketigo Samoa#,
				'generic' => q#Wektu Samoa#,
				'standard' => q#Wektu Standar Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Wektu Seichelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Wektu Singapura#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Wektu Kepuloan Solomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Wektu Georgia Kidul#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Wektu Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Wektu Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Wektu Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Wektu Ketigo Taipei#,
				'generic' => q#Wektu Taipei#,
				'standard' => q#Wektu Standar Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Wektu Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Wektu Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Wektu Ketigo Tonga#,
				'generic' => q#Wektu Tonga#,
				'standard' => q#Wektu Standar Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Wektu Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Wektu Ketigo Turkmenistan#,
				'generic' => q#Wektu Turkmenistan#,
				'standard' => q#Wektu Standar Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Wektu Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Wektu Ketigo Uruguay#,
				'generic' => q#Wektu Uruguay#,
				'standard' => q#Wektu Standar Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Wektu Ketigo Usbekistan#,
				'generic' => q#Wektu Usbekistan#,
				'standard' => q#Wektu Standar Usbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Wektu Ketigo Vanuatu#,
				'generic' => q#Wektu Vanuatu#,
				'standard' => q#Wektu Standar Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Wektu Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Wektu Ketigo Vladivostok#,
				'generic' => q#Wektu Vladivostok#,
				'standard' => q#Wektu Standar Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wektu Ketigo Volgograd#,
				'generic' => q#Wektu Volgograd#,
				'standard' => q#Wektu Standar Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Wektu Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wektu Pulo Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wektu Wallis lan Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Wektu Ketigo Yakutsk#,
				'generic' => q#Wektu Yakutsk#,
				'standard' => q#Wektu Standar Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Wektu Ketigo Yekaterinburg#,
				'generic' => q#Wektu Yekaterinburg#,
				'standard' => q#Wektu Standar Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Wektu Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
