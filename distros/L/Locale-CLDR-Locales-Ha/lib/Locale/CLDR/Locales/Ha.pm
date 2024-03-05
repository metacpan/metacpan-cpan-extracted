=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ha - Package for language Hausa

=cut

package Locale::CLDR::Locales::Ha;
# This file auto generated from Data\common\main\ha.xml
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
 				'af' => 'Afirkanci',
 				'agq' => 'Aghem',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'ale' => 'Aleut',
 				'alt' => 'Altai na Kudanci',
 				'am' => 'Amharik',
 				'an' => 'Aragonesanci',
 				'ann' => 'Obolo',
 				'anp' => 'Angika',
 				'ar' => 'Larabci',
 				'ar_001' => 'Larabci Asali Na Zamani',
 				'arn' => 'Mapuche',
 				'arp' => 'Arapaho',
 				'ars' => 'Larabcin Najdi',
 				'as' => 'Asamisanci',
 				'asa' => 'Asu',
 				'ast' => 'Asturia',
 				'atj' => 'Atikamekw',
 				'av' => 'Avaric',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymaranci',
 				'az' => 'Azerbaijanci',
 				'az@alt=short' => 'Azeri',
 				'ba' => 'Bashkir',
 				'ban' => 'Balenesanci',
 				'bas' => 'Basaa',
 				'be' => 'Belarusanci',
 				'bem' => 'Bemba',
 				'bez' => 'Bena',
 				'bg' => 'Bulgariyanci',
 				'bgc' => 'Haryanvi',
 				'bho' => 'Bhojpuri',
 				'bi' => 'Bislama',
 				'bin' => 'Bini',
 				'bla' => 'Siksiká',
 				'bm' => 'Bambara',
 				'bn' => 'Bengali',
 				'bo' => 'Tibetan',
 				'br' => 'Buretananci',
 				'brx' => 'Bodo',
 				'bs' => 'Bosniyanci',
 				'bug' => 'Buginesanci',
 				'byn' => 'Blin',
 				'ca' => 'Kataloniyanci',
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
 				'ckb' => 'Kurdawa ta Tsakiya',
 				'clc' => 'Chilcotin',
 				'co' => 'Corsican',
 				'crg' => 'Michif',
 				'crj' => 'Cree na Kusu-Maso-Gabas',
 				'crk' => 'Plains Cree',
 				'crl' => 'Cree na Arewacin-Gabas',
 				'crm' => 'Moose Cree',
 				'crr' => 'Carolina Algonquian',
 				'cs' => 'Cek',
 				'csw' => 'Swampy Cree',
 				'cu' => 'Church Slavic',
 				'cv' => 'Chuvash',
 				'cy' => 'Welsh',
 				'da' => 'Danish',
 				'dak' => 'Dakota',
 				'dar' => 'Dargwa',
 				'dav' => 'Taita',
 				'de' => 'Jamusanci',
 				'de_AT' => 'Jamusanci Ostiriya',
 				'de_CH' => 'Jamusanci Suwizalan',
 				'dgr' => 'Dogrib',
 				'dje' => 'Zarma',
 				'doi' => 'Harshen Dogri',
 				'dsb' => 'Sorbianci ta kasa',
 				'dua' => 'Duala',
 				'dv' => 'Divehi',
 				'dyo' => 'Jola-Fonyi',
 				'dz' => 'Dzongkha',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'eka' => 'Ekajuk',
 				'el' => 'Girkanci',
 				'en' => 'Turanci',
 				'en_AU' => 'Turanci Ostareliya',
 				'en_CA' => 'Turanci Kanada',
 				'en_GB' => 'Turanci Biritaniya',
 				'en_GB@alt=short' => 'Turancin Ingila',
 				'en_US' => 'Turanci Amirka',
 				'en_US@alt=short' => 'Turancin Amurka',
 				'eo' => 'Esperanto',
 				'es' => 'Sifaniyanci',
 				'es_419' => 'Sifaniyancin Latin Amirka',
 				'es_ES' => 'Sifaniyanci Turai',
 				'es_MX' => 'Sifaniyanci Mesiko',
 				'et' => 'Istoniyanci',
 				'eu' => 'Basque',
 				'ewo' => 'Ewondo',
 				'fa' => 'Farisa',
 				'fa_AF' => 'Farisanci na Afaganistan',
 				'ff' => 'Fulah',
 				'fi' => 'Yaren mutanen Finland',
 				'fil' => 'Dan Filifin',
 				'fj' => 'Fijiyanci',
 				'fo' => 'Faroese',
 				'fon' => 'Fon',
 				'fr' => 'Faransanci',
 				'fr_CA' => 'Farasanci Kanada',
 				'fr_CH' => 'Farasanci Suwizalan',
 				'frc' => 'Faransancin Cajun',
 				'frr' => 'Firisiyanci na Arewaci',
 				'fur' => 'Friulian',
 				'fy' => 'Frisian ta Yamma',
 				'ga' => 'Dan Irish',
 				'gaa' => 'Ga',
 				'gd' => 'Kʼabilan Scots Gaelic',
 				'gez' => 'Geez',
 				'gil' => 'Gilbertese',
 				'gl' => 'Bagalike',
 				'gn' => 'Guwaraniyanci',
 				'gor' => 'Gorontalo',
 				'gsw' => 'Jamusanci Swiss',
 				'gu' => 'Gujarati',
 				'guz' => 'Gusii',
 				'gv' => 'Manx',
 				'gwi' => 'Gwichʼin',
 				'ha' => 'Hausa',
 				'hai' => 'Haida',
 				'haw' => 'Hawaiianci',
 				'hax' => 'Haida na Kudanci',
 				'he' => 'Ibrananci',
 				'hi' => 'Harshen Hindi',
 				'hi_Latn' => 'Hindi (Latinanci)',
 				'hi_Latn@alt=variant' => 'Hinglish',
 				'hil' => 'Hiligaynon',
 				'hmn' => 'Hmong',
 				'hr' => 'Kuroshiyan',
 				'hsb' => 'Sorbianci ta Sama',
 				'ht' => 'Haitian Creole',
 				'hu' => 'Harshen Hungari',
 				'hup' => 'Hupa',
 				'hur' => 'Halkomelem',
 				'hy' => 'Armeniyanci',
 				'hz' => 'Herero',
 				'ia' => 'Yare Tsakanin Kasashe',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Harshen Indunusiya',
 				'ie' => 'Intagulanci',
 				'ig' => 'Igbo',
 				'ii' => 'Sichuan Yi',
 				'ikt' => 'Inuktitut na Yammacin Kanada',
 				'ilo' => 'Ikolo',
 				'inh' => 'Ingush',
 				'io' => 'Ido',
 				'is' => 'Yaren mutanen Iceland',
 				'it' => 'Italiyanci',
 				'iu' => 'Inuktitut',
 				'ja' => 'Japananci',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jv' => 'Jafananci',
 				'ka' => 'Jojiyanci',
 				'kab' => 'Kabyle',
 				'kac' => 'Kachin',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kbd' => 'Karbadiyanci',
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
 				'km' => 'Harshen Kimar',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada',
 				'ko' => 'Harshen Koreya',
 				'kok' => 'Konkananci',
 				'kpe' => 'Kpelle',
 				'kr' => 'Kanuri',
 				'krc' => 'Karachay-Balkar',
 				'krl' => 'Kareliyanci',
 				'kru' => 'Kurukh',
 				'ks' => 'Kashmiri',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Colognian',
 				'ku' => 'Kurdanci',
 				'kum' => 'Kumyk',
 				'kv' => 'Komi',
 				'kw' => 'Cornish',
 				'kwk' => 'Kwakʼwala',
 				'ky' => 'Kirgizanci',
 				'la' => 'Dan Kabilar Latin',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lb' => 'Luxembourgish',
 				'lez' => 'Lezghiniyanci',
 				'lg' => 'Ganda',
 				'li' => 'Limburgish',
 				'lil' => 'Lillooet',
 				'lkt' => 'Lakota',
 				'ln' => 'Lingala',
 				'lo' => 'Lao',
 				'lou' => 'Creole na Louisiana',
 				'loz' => 'Lozi',
 				'lrc' => 'Arewacin Luri',
 				'lsm' => 'Saamiyanci',
 				'lt' => 'Lituweniyanci',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Mizo',
 				'luy' => 'Luyia',
 				'lv' => 'Latbiyanci',
 				'mad' => 'Madurese',
 				'mag' => 'Magahi',
 				'mai' => 'Maithili',
 				'mak' => 'Makasar',
 				'mas' => 'Harshen Masai',
 				'mdf' => 'Moksha',
 				'men' => 'Mende',
 				'mer' => 'Meru',
 				'mfe' => 'Morisyen',
 				'mg' => 'Malagasi',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Metaʼ',
 				'mh' => 'Marshallese',
 				'mi' => 'Maori',
 				'mic' => 'Mi\'kmaq',
 				'min' => 'Minangkabau',
 				'mk' => 'Dan Masedoniya',
 				'ml' => 'Malayalamci',
 				'mn' => 'Mongoliyanci',
 				'mni' => 'Manipuri',
 				'moe' => 'Innu-aimun',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Maratinci',
 				'ms' => 'Harshen Malai',
 				'mt' => 'Harshen Maltis',
 				'mua' => 'Mundang',
 				'mul' => 'Harsuna masu yawa',
 				'mus' => 'Muscogee',
 				'mwl' => 'Mirandese',
 				'my' => 'Burmanci',
 				'myv' => 'Erzya',
 				'mzn' => 'Mazanderani',
 				'na' => 'Nauru',
 				'nap' => 'Neapolitan',
 				'naq' => 'Nama',
 				'nb' => 'Norwegian Bokmål',
 				'nd' => 'North Ndebele',
 				'nds' => 'Low German',
 				'ne' => 'Nepali',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Niuean',
 				'nl' => 'Holanci',
 				'nmg' => 'Kwasio',
 				'nn' => 'Norwegian Nynorsk',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Harhsen Norway',
 				'nog' => 'Harshen Nogai',
 				'nqo' => 'N’Ko',
 				'nr' => 'Ndebele na Kudu',
 				'nso' => 'Sotho na Arewaci',
 				'nus' => 'Nuer',
 				'nv' => 'Navajo',
 				'ny' => 'Nyanja',
 				'nyn' => 'Nyankole',
 				'oc' => 'Ositanci',
 				'ojb' => 'Ojibwa na Arewa-Maso-Yamma',
 				'ojc' => 'Ojibwa na Tsakiya',
 				'ojs' => 'Oji-Cree',
 				'ojw' => 'Ojibwa na Yammaci',
 				'oka' => 'Okanagan',
 				'om' => 'Oromo',
 				'or' => 'Odiya',
 				'os' => 'Ossetic',
 				'pa' => 'Punjabi',
 				'pag' => 'Pangasinanci',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiamento',
 				'pau' => 'Palauan',
 				'pcm' => 'Pidgin na Najeriya',
 				'pis' => 'Pijin',
 				'pl' => 'Harshen Polan',
 				'pqm' => 'Maliseet-Passamaquoddy',
 				'prg' => 'Ferusawa',
 				'ps' => 'Pashtanci',
 				'pt' => 'Harshen Potugis',
 				'pt_BR' => 'Harshen Potugis na Birazil',
 				'pt_PT' => 'Potugis Ƙasashen Turai',
 				'qu' => 'Quechua',
 				'raj' => 'Rajasthani',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotongan',
 				'rhg' => 'Harshen Rohingya',
 				'rm' => 'Romansh',
 				'rn' => 'Rundi',
 				'ro' => 'Romaniyanci',
 				'rof' => 'Rombo',
 				'ru' => 'Rashanci',
 				'rup' => 'Aromaniyanci',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskrit',
 				'sad' => 'Sandawe',
 				'sah' => 'Sakha',
 				'saq' => 'Samburu',
 				'sat' => 'Santali',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardiniyanci',
 				'scn' => 'Sisiliyanci',
 				'sco' => 'Scots',
 				'sd' => 'Sindiyanci',
 				'se' => 'Sami ta Arewa',
 				'seh' => 'Sena',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'sh' => 'Kuroweshiyancin-Sabiya',
 				'shi' => 'Tachelhit',
 				'shn' => 'Shan',
 				'si' => 'Sinhalanci',
 				'sk' => 'Basulke',
 				'sl' => 'Basulabe',
 				'slh' => 'Lushbootseed na Kudanci',
 				'sm' => 'Samoan',
 				'smn' => 'Inari Sami',
 				'sms' => 'Skolt Sami',
 				'sn' => 'Shona',
 				'snk' => 'Soninke',
 				'so' => 'Somalianci',
 				'sq' => 'Albaniyanci',
 				'sr' => 'Sabiyan',
 				'srn' => 'Sranan Tongo',
 				'ss' => 'Swati',
 				'st' => 'Sesotanci',
 				'str' => 'Straits Salish',
 				'su' => 'Harshen Sundanese',
 				'suk' => 'Sukuma',
 				'sv' => 'Harshen Suwedan',
 				'sw' => 'Harshen Suwahili',
 				'swb' => 'Komoriyanci',
 				'syr' => 'Syriac',
 				'ta' => 'Tamil',
 				'tce' => 'Tutchone na Kudanci',
 				'te' => 'Telugu',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'tet' => 'Tatum',
 				'tg' => 'Tajik',
 				'tgx' => 'Tagish',
 				'th' => 'Thai',
 				'tht' => 'Tahltan',
 				'ti' => 'Tigrinyanci',
 				'tig' => 'Tigre',
 				'tk' => 'Tukmenistanci',
 				'tlh' => 'Klingon',
 				'tli' => 'Tlingit',
 				'tn' => 'Tswana',
 				'to' => 'Tonganci',
 				'tok' => 'Toki Pona',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Harshen Turkiyya',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tt' => 'Tatar',
 				'ttm' => 'Tutchone na Arewaci',
 				'tum' => 'Tumbuka',
 				'tvl' => 'Tuvalu',
 				'tw' => 'Tiwiniyanci',
 				'twq' => 'Tasawak',
 				'ty' => 'Tahitiyanci',
 				'tyv' => 'Tuviniyanci',
 				'tzm' => 'Tamazight na Atlas Tsaka',
 				'udm' => 'Udmurt',
 				'ug' => 'Ugiranci',
 				'uk' => 'Harshen Yukuren',
 				'umb' => 'Umbundu',
 				'und' => 'Harshen da ba a sani ba',
 				'ur' => 'Urdanci',
 				'uz' => 'Uzbek',
 				'vai' => 'Vai',
 				've' => 'Venda',
 				'vi' => 'Harshen Biyetinam',
 				'vo' => 'Volapük',
 				'vun' => 'Vunjo',
 				'wa' => 'Walloon',
 				'wae' => 'Walser',
 				'wal' => 'Wolaytta',
 				'war' => 'Waray',
 				'wo' => 'Wolof',
 				'wuu' => 'Sinancin Wu',
 				'xal' => 'Kalmyk',
 				'xh' => 'Bazosa',
 				'xog' => 'Soga',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Yaren Yiddish',
 				'yo' => 'Yarbanci',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Harshen Cantonese',
 				'yue@alt=menu' => 'Sinanci, Cantonese',
 				'zgh' => 'Daidaitaccen Moroccan Tamazight',
 				'zh' => 'Harshen Sinanci',
 				'zh@alt=menu' => 'Harshen, Sinanci',
 				'zh_Hans' => 'Sauƙaƙaƙƙen Sinanci',
 				'zh_Hant' => 'Sinanci na gargajiya',
 				'zu' => 'Harshen Zulu',
 				'zun' => 'Zuni',
 				'zxx' => 'Babu abun cikin yare',
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
 			'Arab' => 'Larabci',
 			'Aran' => 'Rubutun Nastaliq',
 			'Armn' => 'Armeniyawa',
 			'Beng' => 'Bangla',
 			'Bopo' => 'Bopomofo',
 			'Brai' => 'Rubutun Makafi',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Haɗaɗɗun Gaɓoɓin ʼYan Asali na Kanada',
 			'Cher' => 'Cherokee',
 			'Cyrl' => 'Cyrillic',
 			'Deva' => 'Devanagari',
 			'Ethi' => 'Ethiopic',
 			'Geor' => 'Georgian',
 			'Grek' => 'Girka',
 			'Gujr' => 'Gujarati',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Han tare da Bopomofo',
 			'Hang' => 'Yaren Hangul',
 			'Hani' => 'Mutanen Han na ƙasar Sin',
 			'Hans' => 'Sauƙaƙaƙƙen',
 			'Hans@alt=stand-alone' => 'Sauƙaƙaƙƙen Hans',
 			'Hant' => 'Na gargajiya',
 			'Hant@alt=stand-alone' => 'Han na gargajiya',
 			'Hebr' => 'Ibrananci',
 			'Hira' => 'Tsarin Rubutun Hiragana',
 			'Hrkt' => 'kalaman Jafananci',
 			'Jamo' => 'Jamo',
 			'Jpan' => 'Jafanis',
 			'Kana' => 'Tsarin Rubutun Katakana',
 			'Khmr' => 'Yaren Khmer',
 			'Knda' => 'Yaren Kannada',
 			'Kore' => 'Rubutun Koriya',
 			'Laoo' => 'Yan lao',
 			'Latn' => 'Latin',
 			'Mlym' => 'Yaren Malayalam',
 			'Mong' => 'Na kasar Mongolia',
 			'Mtei' => 'Meitei Mayek',
 			'Mymr' => 'Ƙasar Myanmar',
 			'Nkoo' => 'N’Ko',
 			'Olck' => 'Ol Chiki',
 			'Orya' => 'Yaren Odia',
 			'Rohg' => 'Hanifi',
 			'Sinh' => 'Yaren Sinhala',
 			'Sund' => 'Sudananci',
 			'Syrc' => 'Siriyanci',
 			'Taml' => 'Yaren Tamil',
 			'Telu' => 'Yaren Telugu',
 			'Tfng' => 'Tifinagh',
 			'Thaa' => 'Yaren Thaana',
 			'Thai' => 'Thai',
 			'Tibt' => 'Yaren Tibet',
 			'Vaii' => 'Vai',
 			'Yiii' => 'Yi',
 			'Zmth' => 'Alamar Lissafi',
 			'Zsye' => 'Alama ta hoto',
 			'Zsym' => 'Alamomi',
 			'Zxxx' => 'Ba rubutacce ba',
 			'Zyyy' => 'Gama-gari',
 			'Zzzz' => 'Rubutun da ba sani ba',

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
			'001' => 'Duniya',
 			'002' => 'Afirka',
 			'003' => 'Amurka ta Arewa',
 			'005' => 'Amurka ta Kudu',
 			'009' => 'Osheniya',
 			'011' => 'Afirka ta Yamma',
 			'013' => 'Amurka ta Tsakiya',
 			'014' => 'Afirka ta Gabas',
 			'015' => 'Arewacin Afirka',
 			'017' => 'Afirka ta Tsakiya',
 			'018' => 'Kudancin Afirka',
 			'019' => 'Nahiyoyin Amurka',
 			'021' => 'Arewacin Amurka',
 			'029' => 'Karebiyan',
 			'030' => 'Gabashin Asiya',
 			'034' => 'Kudancin Asiya',
 			'035' => 'Kudu Maso Gabashin Asiya',
 			'039' => 'Kudancin Turai',
 			'053' => 'Asturesiya',
 			'054' => 'Melanesia',
 			'057' => 'Yankin Micronesiya',
 			'061' => 'Kasar Polynesia',
 			'142' => 'Asiya',
 			'143' => 'Asiya ta Tsakiya',
 			'145' => 'Yammacin Asiya',
 			'150' => 'Turai',
 			'151' => 'Gabashin Turai',
 			'154' => 'Arewacin Turai',
 			'155' => 'Yammacin Turai',
 			'202' => 'Afirka ta Kudancin Sahara',
 			'419' => 'Latin Amurka',
 			'AC' => 'Tsibirin Ascension',
 			'AD' => 'Andora',
 			'AE' => 'Haɗaɗɗiyar Daular Larabawa',
 			'AF' => 'Afaganistan',
 			'AG' => 'Antigua da Barbuda',
 			'AI' => 'Angila',
 			'AL' => 'Albaniya',
 			'AM' => 'Armeniya',
 			'AO' => 'Angola',
 			'AQ' => 'Antatika',
 			'AR' => 'Arjantiniya',
 			'AS' => 'Samowa Ta Amurka',
 			'AT' => 'Ostiriya',
 			'AU' => 'Ostareliya',
 			'AW' => 'Aruba',
 			'AX' => 'Tsibirai na Åland',
 			'AZ' => 'Azarbaijan',
 			'BA' => 'Bosniya da Harzagobina',
 			'BB' => 'Barbadas',
 			'BD' => 'Bangiladas',
 			'BE' => 'Belgiyom',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgariya',
 			'BH' => 'Baharan',
 			'BI' => 'Burundi',
 			'BJ' => 'Binin',
 			'BL' => 'San Barthélemy',
 			'BM' => 'Barmuda',
 			'BN' => 'Burune',
 			'BO' => 'Bolibiya',
 			'BQ' => 'Caribbean Netherlands',
 			'BR' => 'Birazil',
 			'BS' => 'Bahamas',
 			'BT' => 'Butan',
 			'BV' => 'Tsibirin Bouvet',
 			'BW' => 'Baswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Beliz',
 			'CA' => 'Kanada',
 			'CC' => 'Tsibirai Cocos (Keeling)',
 			'CD' => 'Jamhuriyar Dimokuraɗiyyar Kongo',
 			'CD@alt=variant' => 'Kongo (DRC)',
 			'CF' => 'Jamhuriyar Afirka Ta Tsakiya',
 			'CG' => 'Kongo',
 			'CG@alt=variant' => 'Jamhuriyar Kongo',
 			'CH' => 'Suwizalan',
 			'CI' => 'Aibari Kwas',
 			'CK' => 'Tsibiran Kuku',
 			'CL' => 'Cayile',
 			'CM' => 'Kamaru',
 			'CN' => 'Sin',
 			'CO' => 'Kolambiya',
 			'CP' => 'Tsibirin Clipperton',
 			'CR' => 'Kwasta Rika',
 			'CU' => 'Kyuba',
 			'CV' => 'Tsibiran Kap Barde',
 			'CW' => 'Ƙasar Curaçao',
 			'CX' => 'Tsibirin Kirsmati',
 			'CY' => 'Sifurus',
 			'CZ' => 'Jamhuriyar Cak',
 			'DE' => 'Jamus',
 			'DG' => 'Tsibirn Diego Garcia',
 			'DJ' => 'Jibuti',
 			'DK' => 'Danmark',
 			'DM' => 'Dominika',
 			'DO' => 'Jamhuriyar Dominika',
 			'DZ' => 'Aljeriya',
 			'EA' => 'Ceuta da Melilla',
 			'EC' => 'Ekwador',
 			'EE' => 'Estoniya',
 			'EG' => 'Misira',
 			'EH' => 'Yammacin Sahara',
 			'ER' => 'Eritireya',
 			'ES' => 'Sipen',
 			'ET' => 'Habasha',
 			'EU' => 'Tarayyar Turai',
 			'EZ' => 'Sashin Turai',
 			'FI' => 'Finlan',
 			'FJ' => 'Fiji',
 			'FK' => 'Tsibiran Falkilan',
 			'FM' => 'Mikuronesiya',
 			'FO' => 'Tsibirai na Faroe',
 			'FR' => 'Faransa',
 			'GA' => 'Gabon',
 			'GB' => 'Biritaniya',
 			'GD' => 'Girnada',
 			'GE' => 'Jiwarjiya',
 			'GF' => 'Gini Ta Faransa',
 			'GG' => 'Yankin Guernsey',
 			'GH' => 'Gana',
 			'GI' => 'Jibaraltar',
 			'GL' => 'Grinlan',
 			'GM' => 'Gambiya',
 			'GN' => 'Gini',
 			'GP' => 'Gwadaluf',
 			'GQ' => 'Gini Ta Ikwaita',
 			'GR' => 'Girka',
 			'GS' => 'Kudancin Geogia da Kudancin Tsibirin Sandiwic',
 			'GT' => 'Gwatamala',
 			'GU' => 'Gwam',
 			'GW' => 'Gini Bisau',
 			'GY' => 'Guyana',
 			'HK' => 'Babban Yankin Mulkin Hong Kong na Ƙasar Sin',
 			'HM' => 'Tsibirin Heard da McDonald',
 			'HN' => 'Yankin Honduras',
 			'HR' => 'Kurowaishiya',
 			'HT' => 'Haiti',
 			'HU' => 'Hungari',
 			'IC' => 'Tsibiran Canary',
 			'ID' => 'Indunusiya',
 			'IE' => 'Ayalan',
 			'IL' => 'Israʼila',
 			'IM' => 'Isle na Mutum',
 			'IN' => 'Indiya',
 			'IO' => 'Yankin Birtaniya Na Tekun Indiya',
 			'IQ' => 'Iraƙi',
 			'IR' => 'Iran',
 			'IS' => 'Aisalan',
 			'IT' => 'Italiya',
 			'JE' => 'Kasar Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordan',
 			'JP' => 'Japan',
 			'KE' => 'Kenya',
 			'KG' => 'Kirgizistan',
 			'KH' => 'Kambodiya',
 			'KI' => 'Kiribati',
 			'KM' => 'Kwamoras',
 			'KN' => 'San Kiti Da Nebis',
 			'KP' => 'Koriya Ta Arewa',
 			'KR' => 'Koriya Ta Kudu',
 			'KW' => 'Kwiyat',
 			'KY' => 'Tsibiran Kaiman',
 			'KZ' => 'Kazakistan',
 			'LA' => 'Lawas',
 			'LB' => 'Labanan',
 			'LC' => 'San Lusiya',
 			'LI' => 'Licansitan',
 			'LK' => 'Siri Lanka',
 			'LR' => 'Laberiya',
 			'LS' => 'Lesoto',
 			'LT' => 'Lituweniya',
 			'LU' => 'Lukusambur',
 			'LV' => 'Litibiya',
 			'LY' => 'Libiya',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Maldoba',
 			'ME' => 'Mantanegara',
 			'MF' => 'San Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Tsibiran Marshal',
 			'MK' => 'Macedonia ta Arewa',
 			'ML' => 'Mali',
 			'MM' => 'Burma, Miyamar',
 			'MN' => 'Mangoliya',
 			'MO' => 'Babban Yankin Mulkin Macao na Ƙasar Sin',
 			'MP' => 'Tsibiran Mariyana Na Arewa',
 			'MQ' => 'Martinik',
 			'MR' => 'Moritaniya',
 			'MS' => 'Manserati',
 			'MT' => 'Malta',
 			'MU' => 'Moritus',
 			'MV' => 'Maldibi',
 			'MW' => 'Malawi',
 			'MX' => 'Mesiko',
 			'MY' => 'Malaisiya',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibiya',
 			'NC' => 'Kaledoniya Sabuwa',
 			'NE' => 'Nijar',
 			'NF' => 'Tsibirin Narfalk',
 			'NG' => 'Nijeriya',
 			'NI' => 'Nikaraguwa',
 			'NL' => 'Holan',
 			'NO' => 'Norwe',
 			'NP' => 'Nefal',
 			'NR' => 'Nauru',
 			'NU' => 'Niyu',
 			'NZ' => 'Nuzilan',
 			'NZ@alt=variant' => 'Aotearoa Nuzilan',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Feru',
 			'PF' => 'Folinesiya Ta Faransa',
 			'PG' => 'Papuwa Nugini',
 			'PH' => 'Filipin',
 			'PK' => 'Pakistan',
 			'PL' => 'Polan',
 			'PM' => 'San Piyar da Mikelan',
 			'PN' => 'Pitakarin',
 			'PR' => 'Porto Riko',
 			'PS' => 'Yankunan Palasɗinu',
 			'PS@alt=short' => 'Palasɗinu',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Faragwai',
 			'QA' => 'Katar',
 			'QO' => 'Bakin Teku',
 			'RE' => 'Rawuniyan',
 			'RO' => 'Romaniya',
 			'RS' => 'Sabiya',
 			'RU' => 'Rasha',
 			'RW' => 'Ruwanda',
 			'SA' => 'Saudiyya',
 			'SB' => 'Tsibiran Salaman',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Suwedan',
 			'SG' => 'Singapur',
 			'SH' => 'San Helena',
 			'SI' => 'Sulobeniya',
 			'SJ' => 'Svalbard da Jan Mayen',
 			'SK' => 'Sulobakiya',
 			'SL' => 'Salewo',
 			'SM' => 'San Marino',
 			'SN' => 'Sanigal',
 			'SO' => 'Somaliya',
 			'SR' => 'Suriname',
 			'SS' => 'Sudan ta Kudu',
 			'ST' => 'Sawo Tome Da Paransip',
 			'SV' => 'El Salbador',
 			'SX' => 'San Maarten',
 			'SY' => 'Sham, Siriya',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Suwazilan',
 			'TA' => 'Tritan da Kunha',
 			'TC' => 'Turkis Da Tsibiran Kaikwas',
 			'TD' => 'Cadi',
 			'TF' => 'Yankin Faransi ta Kudu',
 			'TG' => 'Togo',
 			'TH' => 'Tailan',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Takelau',
 			'TL' => 'Timor Ta Gabas',
 			'TM' => 'Turkumenistan',
 			'TN' => 'Tunisiya',
 			'TO' => 'Tonga',
 			'TR' => 'Turkiyya',
 			'TT' => 'Tirinidad Da Tobago',
 			'TV' => 'Tubalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzaniya',
 			'UA' => 'Yukaran',
 			'UG' => 'Yuganda',
 			'UM' => 'Rukunin Tsibirin U.S',
 			'UN' => 'Majalisar Ɗinkin Duniya',
 			'US' => 'Amurka',
 			'UY' => 'Yurigwai',
 			'UZ' => 'Uzubekistan',
 			'VA' => 'Batikan',
 			'VC' => 'San Binsan Da Girnadin',
 			'VE' => 'Benezuwela',
 			'VG' => 'Tsibirin Birjin Na Birtaniya',
 			'VI' => 'Tsibiran Birjin Ta Amurka',
 			'VN' => 'Biyetinam',
 			'VU' => 'Banuwatu',
 			'WF' => 'Walis Da Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Gogewar Kwalwa',
 			'XB' => 'Gano wani abu ta hanyar amfani da fasaha',
 			'XK' => 'Kasar Kosovo',
 			'YE' => 'Yamal',
 			'YT' => 'Mayoti',
 			'ZA' => 'Afirka Ta Kudu',
 			'ZM' => 'Zambiya',
 			'ZW' => 'Zimbabuwe',
 			'ZZ' => 'Yanki da ba a sani ba',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kalanda',
 			'cf' => 'Yanayin Kudi',
 			'collation' => 'Tsarin Rabewa',
 			'currency' => 'Kudin Kasa',
 			'hc' => 'Zagayen Awowi',
 			'lb' => 'Salo na Raba Layi',
 			'ms' => 'Tsarin Awo',
 			'numbers' => 'Lambobi',

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
 				'buddhist' => q{Kalandar Buddist},
 				'chinese' => q{Kalandar Sin},
 				'coptic' => q{Kalandar Coptic},
 				'dangi' => q{Kalandar Dangi},
 				'ethiopic' => q{Kalandar Etiofic},
 				'ethiopic-amete-alem' => q{Kalandar Ethiopic Amete Alem},
 				'gregorian' => q{Kalandar Gregoria},
 				'hebrew' => q{Kalandar Ibrananci},
 				'islamic' => q{Kalandar Musulunci},
 				'islamic-civil' => q{Kalandar Musulunci (tabular, civil epoch)},
 				'islamic-tbla' => q{Kalandar Musulunci (tabular, astronomical epoch)},
 				'islamic-umalqura' => q{Kalandar Musulunci (Umm al-Qura)},
 				'iso8601' => q{Kalandar ISO-8601},
 				'japanese' => q{Kalandar Jafan},
 				'persian' => q{Kalandar Farisa},
 				'roc' => q{Kalandar kasar Sin},
 			},
 			'cf' => {
 				'account' => q{Tsarin Kudi na Kididdiga},
 				'standard' => q{Tsarin Kudi Nagartacce},
 			},
 			'collation' => {
 				'ducet' => q{Tsarin Rabewa na Dan-maƙalu na Asali},
 				'search' => q{Bincike na Dalilai-Gamagari},
 				'standard' => q{Daidaitaccen Kasawa},
 			},
 			'hc' => {
 				'h11' => q{Tsarin Awowi 12(0–11)},
 				'h12' => q{Tsarin Awowi 12(1–12)},
 				'h23' => q{Tsarin Awowi 24(0–23)},
 				'h24' => q{Tsarin Awowi 24(1–24)},
 			},
 			'lb' => {
 				'loose' => q{Salo na Raba Layi Sakakke},
 				'normal' => q{Salo na Raba Layi na Kodayaushe},
 				'strict' => q{Salo na Raba Layi mai Tsauri},
 			},
 			'ms' => {
 				'metric' => q{Tsarin Awo na Metric},
 				'uksystem' => q{Tsarin Awo na Imperial},
 				'ussystem' => q{Tsarin Awo na Amurka},
 			},
 			'numbers' => {
 				'arab' => q{Lambobi na Larabawan a Gabas},
 				'arabext' => q{Fitattun lambobin lissafi na Larabci},
 				'armn' => q{Lambobin ƙirga na Armenia},
 				'armnlow' => q{Kananan Haruffan Armenia},
 				'beng' => q{Lambobin Yaren Bangla},
 				'cakm' => q{Lambobin Chakma},
 				'deva' => q{Lambobin Tsarin Rubutu na Devangari},
 				'ethi' => q{Lambobin ƙirga na Ethiopia},
 				'fullwide' => q{Lambobi masu Cikakken-Faɗi},
 				'geor' => q{Lambobin ƙirga na Georgia},
 				'grek' => q{Lambobin ƙirga na Girka},
 				'greklow' => q{Kananan Haruffa na Girka},
 				'gujr' => q{Lambobin Yaren Gujarati},
 				'guru' => q{Lambobi na Tsarin Rubutun Gurmukhi},
 				'hanidec' => q{Lambobin Gomiya na Yaren ƙasar Sin},
 				'hans' => q{Lambobin ƙirga na Yaren ƙasar Sin wanda aka Sauƙaƙa},
 				'hansfin' => q{Lambobin Ƙirgan Kudi na Yaren ƙasar Sin wanda aka Sauƙaƙa},
 				'hant' => q{Lambobin Ƙirga na Yaren ƙasar Sin na Alʼada},
 				'hantfin' => q{Lambobin Ƙirgan Kudi na Yaren ƙasar Sin na Alʼada},
 				'hebr' => q{Lambobin ƙirga na Hebrew},
 				'java' => q{Lambobin Javanese},
 				'jpan' => q{Lambobin ƙirga na Jafananci},
 				'jpanfin' => q{Lambobin ƙirgan Kudi na Jafananci},
 				'khmr' => q{Lambobin Yaren Khmer},
 				'knda' => q{Lambobin Yaren Kannada},
 				'laoo' => q{Lambobin Yaren Lao},
 				'latn' => q{Lambobi na Yammaci},
 				'mlym' => q{Lambobin Yaren Malayalam},
 				'mtei' => q{Lambobin Meetei Mayek},
 				'mymr' => q{Lambobin Myanmar},
 				'olck' => q{Lambobin Ol Chiki},
 				'orya' => q{Lambobin Yaren Odia},
 				'roman' => q{Lambobin Rumawa},
 				'romanlow' => q{Lambobin Kirga Kanana na Rumawa},
 				'taml' => q{Lambobin ƙirga na Tamil na Alʼada},
 				'tamldec' => q{Lambobin Tamil},
 				'telu' => q{Lambobin yaren Telugu},
 				'thai' => q{Lambobin yaren Thai},
 				'tibt' => q{Lambobin yaren Tibet},
 				'vaii' => q{Lambobin Vai},
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
			'metric' => q{Tsarin awo},
 			'UK' => q{Tsarin awo kasar Ingila},
 			'US' => q{Amurka},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Harshe: {0}',
 			'script' => 'Rubutu: {0}',
 			'region' => 'Yanki: {0}',

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
			auxiliary => qr{[áàâ éèê íìî óòô p q {r̃} úùû v x]},
			index => ['A', 'B', 'Ɓ', 'C', 'D', 'Ɗ', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'Ƙ', 'L', 'M', 'N', 'O', 'R', 'S', 'T', 'U', 'W', 'Y', 'Ƴ', 'Z'],
			main => qr{[a b ɓ c d ɗ e f g h i j k ƙ l m n o r s {sh} t {ts} u w y ƴ z ʼ]},
			punctuation => qr{[\- ‑ , ; \: ! ? . '‘’ "“” ( ) \[ \] \{ \} ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'Ɓ', 'C', 'D', 'Ɗ', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'Ƙ', 'L', 'M', 'N', 'O', 'R', 'S', 'T', 'U', 'W', 'Y', 'Ƴ', 'Z'], };
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
						'name' => q(wurin fuskanta),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(wurin fuskanta),
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
						'1' => q(hekta{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hekta{0}),
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
						'one' => q(g-force {0}),
						'other' => q(g-force {0}),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q(g-force {0}),
						'other' => q(g-force {0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meters per second squared),
						'one' => q(meter per second squared {0}),
						'other' => q(meters per second squared {0}),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meters per second squared),
						'one' => q(meter per second squared {0}),
						'other' => q(meters per second squared {0}),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arcminutes),
						'one' => q(arcminute {0}),
						'other' => q(arcminutes {0}),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcminutes),
						'one' => q(arcminute {0}),
						'other' => q(arcminutes {0}),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcseconds),
						'one' => q(arcsecond {0}),
						'other' => q(arcseconds {0}),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcseconds),
						'one' => q(arcsecond {0}),
						'other' => q(arcseconds {0}),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q(degree {0}),
						'other' => q(degrees {0}),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q(degree {0}),
						'other' => q(degrees {0}),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radians),
						'one' => q(radian {0}),
						'other' => q(radians {0}),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radians),
						'one' => q(radian {0}),
						'other' => q(radians {0}),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(revolution),
						'one' => q(revolution {0}),
						'other' => q(revolutions {0}),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(revolution),
						'one' => q(revolution {0}),
						'other' => q(revolutions {0}),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(eka),
						'one' => q(eka {0}),
						'other' => q(ekoki {0}),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(eka),
						'one' => q(eka {0}),
						'other' => q(ekoki {0}),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'one' => q(dunam {0}),
						'other' => q(dunams {0}),
					},
					# Core Unit Identifier
					'dunam' => {
						'one' => q(dunam {0}),
						'other' => q(dunams {0}),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q(hekta {0}),
						'other' => q(hektoci {0}),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q(hekta {0}),
						'other' => q(hektoci {0}),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(sikwaya sentimitoci),
						'one' => q(sikwaya sentimita {0}),
						'other' => q(sikwaya sentimitoci {0}),
						'per' => q({0} a sikwaya sentimita),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sikwaya sentimitoci),
						'one' => q(sikwaya sentimita {0}),
						'other' => q(sikwaya sentimitoci {0}),
						'per' => q({0} a sikwaya sentimita),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(sikwaya ƙafafu),
						'one' => q(sikwaya ƙafa {0}),
						'other' => q(sikwaya ƙafafu {0}),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(sikwaya ƙafafu),
						'one' => q(sikwaya ƙafa {0}),
						'other' => q(sikwaya ƙafafu {0}),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(sikwaya incis),
						'one' => q(sikwaya inci {0}),
						'other' => q(sikwaya incina {0}),
						'per' => q({0} a sikwaya inci),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(sikwaya incis),
						'one' => q(sikwaya inci {0}),
						'other' => q(sikwaya incina {0}),
						'per' => q({0} a sikwaya inci),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(sikwaya kilomitoci),
						'one' => q(sikwaya kilomita {0}),
						'other' => q(sikwaya kilomitoci {0}),
						'per' => q({0} a sikwaya kilomita),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(sikwaya kilomitoci),
						'one' => q(sikwaya kilomita {0}),
						'other' => q(sikwaya kilomitoci {0}),
						'per' => q({0} a sikwaya kilomita),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(sikwaya mitoci),
						'one' => q(sikwaya mita {0}),
						'other' => q(sikwaya mitoci {0}),
						'per' => q({0} a sikwaya mita),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(sikwaya mitoci),
						'one' => q(sikwaya mita {0}),
						'other' => q(sikwaya mitoci {0}),
						'per' => q({0} a sikwaya mita),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(sikwaya mil-mil),
						'one' => q(sikwaya mil {0}),
						'other' => q(sikwaya mil-mil {0}),
						'per' => q({0} a sikwaya mil),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(sikwaya mil-mil),
						'one' => q(sikwaya mil {0}),
						'other' => q(sikwaya mil-mil {0}),
						'per' => q({0} a sikwaya mil),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(sikwaya yadina),
						'one' => q(sikwaya yadi {0}),
						'other' => q(sikwaya yaduna {0}),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(sikwaya yadina),
						'one' => q(sikwaya yadi {0}),
						'other' => q(sikwaya yaduna {0}),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(abubuwa),
						'one' => q(abu {0}),
						'other' => q(abubuwa {0}),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(abubuwa),
						'one' => q(abu {0}),
						'other' => q(abubuwa {0}),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q(karat {0}),
						'other' => q(karats {0}),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q(karat {0}),
						'other' => q(karats {0}),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrams per deciliter),
						'one' => q(milligram per deciliter {0}),
						'other' => q(milligrams per deciliter {0}),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligrams per deciliter),
						'one' => q(milligram per deciliter {0}),
						'other' => q(milligrams per deciliter {0}),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimoles per liter),
						'one' => q(millimole per liter {0}),
						'other' => q(millimoles per liter {0}),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimoles per liter),
						'one' => q(millimole per liter {0}),
						'other' => q(millimoles per liter {0}),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(moles),
						'one' => q(mole {0}),
						'other' => q(moles {0}),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(moles),
						'one' => q(mole {0}),
						'other' => q(moles {0}),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q(kaso {0}),
						'other' => q(Kaso {0}),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q(kaso {0}),
						'other' => q(Kaso {0}),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q(permille {0}),
						'other' => q(permille {0}),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q(permille {0}),
						'other' => q(permille {0}),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(parts per million),
						'one' => q(part per million {0}),
						'other' => q(parts per million {0}),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(parts per million),
						'one' => q(part per million {0}),
						'other' => q(parts per million {0}),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q(permyriad {0}),
						'other' => q(permyriad {0}),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q(permyriad {0}),
						'other' => q(permyriad {0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litoci a kilomitoci 100),
						'one' => q(lita a kilomitoci 100 {0}),
						'other' => q(litoci a kilomitoci 100 {0}),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litoci a kilomitoci 100),
						'one' => q(lita a kilomitoci 100 {0}),
						'other' => q(litoci a kilomitoci 100 {0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litoci a kilomita),
						'one' => q(lita a kilomita {0}),
						'other' => q(litoci a kilomita {0}),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litoci a kilomita),
						'one' => q(lita a kilomita {0}),
						'other' => q(litoci a kilomita {0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mil-mil a galan),
						'one' => q(mil a galan {0}),
						'other' => q(mil-mil a galan {0}),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil-mil a galan),
						'one' => q(mil a galan {0}),
						'other' => q(mil-mil a galan {0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil-mil a Imp. gallon),
						'one' => q(mil a Imp. gallon {0}),
						'other' => q(mil-mil a Imp. gallon {0}),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil-mil a Imp. gallon),
						'one' => q(mil a Imp. gallon {0}),
						'other' => q(mil-mil a Imp. gallon {0}),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q(Gabas {0}),
						'north' => q(Arewa {0}),
						'south' => q(Kudu {0}),
						'west' => q(Yamma {0}),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q(Gabas {0}),
						'north' => q(Arewa {0}),
						'south' => q(Kudu {0}),
						'west' => q(Yamma {0}),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bits),
						'one' => q(bit {0}),
						'other' => q(bits {0}),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bits),
						'one' => q(bit {0}),
						'other' => q(bits {0}),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bytes),
						'one' => q(byte {0}),
						'other' => q(bytes {0}),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bytes),
						'one' => q(byte {0}),
						'other' => q(bytes {0}),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabits),
						'one' => q(gigabit {0}),
						'other' => q(gigabits {0}),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabits),
						'one' => q(gigabit {0}),
						'other' => q(gigabits {0}),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabytes),
						'one' => q(gigabyte {0}),
						'other' => q(gigabytes {0}),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabytes),
						'one' => q(gigabyte {0}),
						'other' => q(gigabytes {0}),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobits),
						'one' => q(kilobit {0}),
						'other' => q(kilobits {0}),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobits),
						'one' => q(kilobit {0}),
						'other' => q(kilobits {0}),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobytes),
						'one' => q(kilobyte {0}),
						'other' => q(kilobytes {0}),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobytes),
						'one' => q(kilobyte {0}),
						'other' => q(kilobytes {0}),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabits),
						'one' => q(megabit {0}),
						'other' => q(megabits {0}),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabits),
						'one' => q(megabit {0}),
						'other' => q(megabits {0}),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabytes),
						'one' => q(megabyte {0}),
						'other' => q(megabytes {0}),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabytes),
						'one' => q(megabyte {0}),
						'other' => q(megabytes {0}),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabytes),
						'one' => q(petabyte {0}),
						'other' => q(petabytes {0}),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabytes),
						'one' => q(petabyte {0}),
						'other' => q(petabytes {0}),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabits),
						'one' => q(terabit {0}),
						'other' => q(terabits {0}),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabits),
						'one' => q(terabit {0}),
						'other' => q(terabits {0}),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabytes),
						'one' => q(terabyte {0}),
						'other' => q(terabytes {0}),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabytes),
						'one' => q(terabyte {0}),
						'other' => q(terabytes {0}),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ƙarnoni),
						'one' => q(ƙarni {0}),
						'other' => q(ƙarnoni {0}),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ƙarnoni),
						'one' => q(ƙarni {0}),
						'other' => q(ƙarnoni {0}),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q(rana {0}),
						'other' => q(ranaku {0}),
						'per' => q({0} a rana),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q(rana {0}),
						'other' => q(ranaku {0}),
						'per' => q({0} a rana),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(shekaru goma-goma),
						'one' => q(sk gm {0}),
						'other' => q(shk gm-gm {0}),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(shekaru goma-goma),
						'one' => q(sk gm {0}),
						'other' => q(shk gm-gm {0}),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q(sa′a {0}),
						'other' => q(sa′o′i {0}),
						'per' => q({0} a saʼa),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q(sa′a {0}),
						'other' => q(sa′o′i {0}),
						'per' => q({0} a saʼa),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(makirosekan),
						'one' => q(makirosekan {0}),
						'other' => q(makirosekans {0}),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(makirosekan),
						'one' => q(makirosekan {0}),
						'other' => q(makirosekans {0}),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisakan),
						'one' => q(millisakan {0}),
						'other' => q(millisakans {0}),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisakan),
						'one' => q(millisakan {0}),
						'other' => q(millisakans {0}),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(mintoci),
						'one' => q(minti {0}),
						'other' => q(mintoci {0}),
						'per' => q({0} a minti),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(mintoci),
						'one' => q(minti {0}),
						'other' => q(mintoci {0}),
						'per' => q({0} a minti),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(wat),
						'one' => q(wata {0}),
						'other' => q(watanni {0}),
						'per' => q({0} a wata),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(wat),
						'one' => q(wata {0}),
						'other' => q(watanni {0}),
						'per' => q({0} a wata),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekan),
						'one' => q(nanosekan {0}),
						'other' => q(nanosekans {0}),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekan),
						'one' => q(nanosekan {0}),
						'other' => q(nanosekans {0}),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kwatoci),
						'one' => q(kwata {0}),
						'other' => q(kwatoci {0}),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kwatoci),
						'one' => q(kwata {0}),
						'other' => q(kwatoci {0}),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(daƙiƙoƙi),
						'one' => q(daƙiƙa {0}),
						'other' => q(daƙiƙoƙi {0}),
						'per' => q({0} a daƙiƙa),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(daƙiƙoƙi),
						'one' => q(daƙiƙa {0}),
						'other' => q(daƙiƙoƙi {0}),
						'per' => q({0} a daƙiƙa),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q(mako {0}),
						'other' => q(makonni {0}),
						'per' => q({0} a mako),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q(mako {0}),
						'other' => q(makonni {0}),
						'per' => q({0} a mako),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q(shekara {0}),
						'other' => q(shekaru {0}),
						'per' => q({0} a shekara),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q(shekara {0}),
						'other' => q(shekaru {0}),
						'per' => q({0} a shekara),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amperes),
						'one' => q(ampere {0}),
						'other' => q(amperes {0}),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amperes),
						'one' => q(ampere {0}),
						'other' => q(amperes {0}),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliamperes),
						'one' => q(milliamperes {0}),
						'other' => q(milliamperes {0}),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliamperes),
						'one' => q(milliamperes {0}),
						'other' => q(milliamperes {0}),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohms),
						'one' => q(ohm {0}),
						'other' => q(ohms {0}),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohms),
						'one' => q(ohm {0}),
						'other' => q(ohms {0}),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q(volt {0}),
						'other' => q(volts {0}),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q(volt {0}),
						'other' => q(volts {0}),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(British thermal units),
						'one' => q(British thermal unit {0}),
						'other' => q(British thermal units {0}),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(British thermal units),
						'one' => q(British thermal unit {0}),
						'other' => q(British thermal units {0}),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kaloris),
						'one' => q(kalori {0}),
						'other' => q(kaloris {0}),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kaloris),
						'one' => q(kalori {0}),
						'other' => q(kaloris {0}),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(electronvolts),
						'one' => q(electronvolt {0}),
						'other' => q(electronvolts {0}),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(electronvolts),
						'one' => q(electronvolt {0}),
						'other' => q(electronvolts {0}),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Kaloris),
						'one' => q(Kalori {0}),
						'other' => q(Kaloris {0}),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kaloris),
						'one' => q(Kalori {0}),
						'other' => q(Kaloris {0}),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q(joule {0}),
						'other' => q(joules {0}),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q(joule {0}),
						'other' => q(joules {0}),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokaloris),
						'one' => q(kilokalori {0}),
						'other' => q(kilokaloris {0}),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokaloris),
						'one' => q(kilokalori {0}),
						'other' => q(kilokaloris {0}),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoules),
						'one' => q(kilojoule {0}),
						'other' => q(kilojoules {0}),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoules),
						'one' => q(kilojoule {0}),
						'other' => q(kilojoules {0}),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowatt-hours),
						'one' => q(kilowatt hour {0}),
						'other' => q(kilowatt-hours {0}),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowatt-hours),
						'one' => q(kilowatt hour {0}),
						'other' => q(kilowatt-hours {0}),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q(US therm {0}),
						'other' => q(US therms {0}),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q(US therm {0}),
						'other' => q(US therms {0}),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-hour per 100 kilometers),
						'one' => q(kilowatt-hour per 100 kilometers {0}),
						'other' => q(kilowatt-hours per 100 kilometers {0}),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-hour per 100 kilometers),
						'one' => q(kilowatt-hour per 100 kilometers {0}),
						'other' => q(kilowatt-hours per 100 kilometers {0}),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newtons),
						'one' => q(newton {0}),
						'other' => q(newtons {0}),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newtons),
						'one' => q(newton {0}),
						'other' => q(newtons {0}),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pounds of force),
						'one' => q(pound of force {0}),
						'other' => q(pounds of force {0}),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pounds of force),
						'one' => q(pound of force {0}),
						'other' => q(pounds of force {0}),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahertz),
						'one' => q(gigahertz {0}),
						'other' => q(gigahertz {0}),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q(gigahertz {0}),
						'other' => q(gigahertz {0}),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertz),
						'one' => q(hertz {0}),
						'other' => q(hertz {0}),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertz),
						'one' => q(hertz {0}),
						'other' => q(hertz {0}),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohertz),
						'one' => q(kilohertz {0}),
						'other' => q(kilohertz {0}),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q(kilohertz {0}),
						'other' => q(kilohertz {0}),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahertz),
						'one' => q(megahertz {0}),
						'other' => q(megahertz {0}),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q(megahertz {0}),
						'other' => q(megahertz {0}),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'one' => q(aya {0}),
						'other' => q(aya {0}),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q(aya {0}),
						'other' => q(aya {0}),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(ayoyi a sentimita),
						'one' => q({0} aya a sentimita),
						'other' => q({0} ayoyi a sentimita),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(ayoyi a sentimita),
						'one' => q({0} aya a sentimita),
						'other' => q({0} ayoyi a sentimita),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(ayoyi a inci),
						'one' => q({0} aya a inci),
						'other' => q({0} ayoyi a inci),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(ayoyi a inci),
						'one' => q({0} aya a inci),
						'other' => q({0} ayoyi a inci),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(typographic em),
						'one' => q(em {0}),
						'other' => q({0} ems),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(typographic em),
						'one' => q(em {0}),
						'other' => q({0} ems),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q(megafikzel {0}),
						'other' => q(megafikzels {0}),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q(megafikzel {0}),
						'other' => q(megafikzels {0}),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(fikzel),
						'one' => q(fikzel {0}),
						'other' => q(fikzels {0}),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(fikzel),
						'one' => q(fikzel {0}),
						'other' => q(fikzels {0}),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(fikzels a sentimita),
						'one' => q({0} fikzel a sentimita),
						'other' => q({0} fikzels a sentimita),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(fikzels a sentimita),
						'one' => q({0} fikzel a sentimita),
						'other' => q({0} fikzels a sentimita),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(fikzel a inci),
						'one' => q({0} fikzel a inci),
						'other' => q({0} fikzels a inci),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(fikzel a inci),
						'one' => q({0} fikzel a inci),
						'other' => q({0} fikzels a inci),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronomical units),
						'one' => q(astronomical unit {0}),
						'other' => q(astronomical units {0}),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronomical units),
						'one' => q(astronomical unit {0}),
						'other' => q(astronomical units {0}),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sentimitoci),
						'one' => q(sentimita {0}),
						'other' => q(sentimitoci {0}),
						'per' => q({0} a sentimita),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sentimitoci),
						'one' => q(sentimita {0}),
						'other' => q(sentimitoci {0}),
						'per' => q({0} a sentimita),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(disimitoci),
						'one' => q(disimita {0}),
						'other' => q(disimitoci {0}),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(disimitoci),
						'one' => q(disimita {0}),
						'other' => q(disimitoci {0}),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(earth radius),
						'one' => q(earth radius {0}),
						'other' => q(earth radius {0}),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(earth radius),
						'one' => q(earth radius {0}),
						'other' => q(earth radius {0}),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathoms),
						'one' => q(fathom {0}),
						'other' => q(fathoms {0}),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathoms),
						'one' => q(fathom {0}),
						'other' => q(fathoms {0}),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q(ƙafa {0}),
						'other' => q(ƙafafu {0}),
						'per' => q({0} a ƙafa),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q(ƙafa {0}),
						'other' => q(ƙafafu {0}),
						'per' => q({0} a ƙafa),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q(furlong {0}),
						'other' => q(furlongs {0}),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q(furlong {0}),
						'other' => q(furlongs {0}),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q(inci {0}),
						'other' => q(incina {0}),
						'per' => q({0} a inci),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q(inci {0}),
						'other' => q(incina {0}),
						'per' => q({0} a inci),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilomitoci),
						'one' => q(kilomita {0}),
						'other' => q(kilomitoci {0}),
						'per' => q({0} a kilomita),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilomitoci),
						'one' => q(kilomita {0}),
						'other' => q(kilomitoci {0}),
						'per' => q({0} a kilomita),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(shekarun haske),
						'one' => q(shekarar haske {0}),
						'other' => q(shekarun haske {0}),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(shekarun haske),
						'one' => q(shekarar haske {0}),
						'other' => q(shekarun haske {0}),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mitoci),
						'one' => q(mita {0}),
						'other' => q(mitoci {0}),
						'per' => q({0} a mita),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mitoci),
						'one' => q(mita {0}),
						'other' => q(mitoci {0}),
						'per' => q({0} a mita),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(makiromitoci),
						'one' => q(makiromita {0}),
						'other' => q(makiromitoci {0}),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(makiromitoci),
						'one' => q(makiromita {0}),
						'other' => q(makiromitoci {0}),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q(mil {0}),
						'other' => q(mil-mil {0}),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q(mil {0}),
						'other' => q(mil-mil {0}),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(mile-scandinavian),
						'one' => q(mile-scandinavian {0}),
						'other' => q(miles-scandinavian {0}),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(mile-scandinavian),
						'one' => q(mile-scandinavian {0}),
						'other' => q(miles-scandinavian {0}),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimitoci),
						'one' => q(milimita {0}),
						'other' => q(milimitoci {0}),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimitoci),
						'one' => q(milimita {0}),
						'other' => q(milimitoci {0}),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanomitoci),
						'one' => q(nanomita {0}),
						'other' => q(nanomitoci {0}),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanomitoci),
						'one' => q(nanomita {0}),
						'other' => q(nanomitoci {0}),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(nautical miles),
						'one' => q(nautical mile {0}),
						'other' => q(nautical miles {0}),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(nautical miles),
						'one' => q(nautical mile {0}),
						'other' => q(nautical miles {0}),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q(fasek {0}),
						'other' => q(fasekoki {0}),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q(fasek {0}),
						'other' => q(fasekoki {0}),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(fikomitoci),
						'one' => q(fikomita {0}),
						'other' => q(fikomitoci {0}),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(fikomitoci),
						'one' => q(fikomita {0}),
						'other' => q(fikomitoci {0}),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q(maki {0}),
						'other' => q(makuna {0}),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q(maki {0}),
						'other' => q(makuna {0}),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q(solar radius {0}),
						'other' => q(solar radii {0}),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q(solar radius {0}),
						'other' => q(solar radii {0}),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q(yadi {0}),
						'other' => q(yaduka {0}),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q(yadi {0}),
						'other' => q(yaduka {0}),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(candela),
						'one' => q(candela {0}),
						'other' => q(candela {0}),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(candela),
						'one' => q(candela {0}),
						'other' => q(candela {0}),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
						'one' => q(lumen {0}),
						'other' => q(lumen {0}),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
						'one' => q(lumen {0}),
						'other' => q(lumen {0}),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q(lux {0}),
						'other' => q(lux {0}),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q(lux {0}),
						'other' => q(lux {0}),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q(solar luminosity {0}),
						'other' => q(solar luminosities {0}),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q(solar luminosity {0}),
						'other' => q(solar luminosities {0}),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q(carat {0}),
						'other' => q(carats {0}),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q(carat {0}),
						'other' => q(carats {0}),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q(dalton {0}),
						'other' => q(daltons {0}),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q(dalton {0}),
						'other' => q(daltons {0}),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q(Earth mas {0}),
						'other' => q(Earth masses {0}),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q(Earth mas {0}),
						'other' => q(Earth masses {0}),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(giram-giram),
						'one' => q(giram {0}),
						'other' => q(giram-giram {0}),
						'per' => q({0} a giram),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(giram-giram),
						'one' => q(giram {0}),
						'other' => q(giram-giram {0}),
						'per' => q({0} a giram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogiramgiram),
						'one' => q(kilogiram {0}),
						'other' => q(kilogiramgiram {0}),
						'per' => q({0} a kilogiram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogiramgiram),
						'one' => q(kilogiram {0}),
						'other' => q(kilogiramgiram {0}),
						'per' => q({0} a kilogiram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(makirogiramgiram),
						'one' => q(Makirogiram {0}),
						'other' => q(makirogiramgiram {0}),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(makirogiramgiram),
						'one' => q(Makirogiram {0}),
						'other' => q(makirogiramgiram {0}),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(milligiramgiram),
						'one' => q(milligiram {0}),
						'other' => q(milligiramgiram {0}),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(milligiramgiram),
						'one' => q(milligiram {0}),
						'other' => q(milligiramgiram {0}),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(oza-oza),
						'one' => q(oza {0}),
						'other' => q(oza-oza {0}),
						'per' => q({0} a oza),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(oza-oza),
						'one' => q(oza {0}),
						'other' => q(oza-oza {0}),
						'per' => q({0} a oza),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oza-ozar troy),
						'one' => q(oza troy {0}),
						'other' => q(oza-ozar troy {0}),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oza-ozar troy),
						'one' => q(oza troy {0}),
						'other' => q(oza-ozar troy {0}),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q(Laba {0}),
						'other' => q(laba-laba {0}),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q(Laba {0}),
						'other' => q(laba-laba {0}),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q(solar mas {0}),
						'other' => q(solar masses {0}),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q(solar mas {0}),
						'other' => q(solar masses {0}),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q(stone {0}),
						'other' => q(stones {0}),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q(stone {0}),
						'other' => q(stones {0}),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q(tan {0}),
						'other' => q(tan-tan {0}),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q(tan {0}),
						'other' => q(tan-tan {0}),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(metric tons),
						'one' => q(metric ton {0}),
						'other' => q(metric tons {0}),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(metric tons),
						'one' => q(metric ton {0}),
						'other' => q(metric tons {0}),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} a {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} a {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawatwat),
						'one' => q(gigawat {0}),
						'other' => q(gigawatwat {0}),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawatwat),
						'one' => q(gigawat {0}),
						'other' => q(gigawatwat {0}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(ƙarfin inji),
						'one' => q(ƙarfin inji {0}),
						'other' => q(ƙarfin inji {0}),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(ƙarfin inji),
						'one' => q(ƙarfin inji {0}),
						'other' => q(ƙarfin inji {0}),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowatwat),
						'one' => q(kilowat {0}),
						'other' => q(kilowatwat {0}),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowatwat),
						'one' => q(kilowat {0}),
						'other' => q(kilowatwat {0}),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawatwat),
						'one' => q(megawat {0}),
						'other' => q(megawatwat {0}),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawatwat),
						'one' => q(megawat {0}),
						'other' => q(megawatwat {0}),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(milliwatwat),
						'one' => q(milliwat {0}),
						'other' => q(milliwatwat {0}),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(milliwatwat),
						'one' => q(milliwat {0}),
						'other' => q(milliwatwat {0}),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q(wat {0}),
						'other' => q(wat-wat {0}),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q(wat {0}),
						'other' => q(wat-wat {0}),
					},
					# Long Unit Identifier
					'power2' => {
						'one' => q(sikwaya {0}),
						'other' => q(sikwaya {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q(sikwaya {0}),
						'other' => q(sikwaya {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'one' => q(kubic {0}),
						'other' => q(kubic {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'one' => q(kubic {0}),
						'other' => q(kubic {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(yanaye-yanaye),
						'one' => q(Yanayi {0}),
						'other' => q(yanaye-yanaye {0}),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(yanaye-yanaye),
						'one' => q(Yanayi {0}),
						'other' => q(yanaye-yanaye {0}),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(sanduna),
						'one' => q(sanda {0}),
						'other' => q(anduna {0}),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(sanduna),
						'one' => q(sanda {0}),
						'other' => q(anduna {0}),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hectopascals),
						'one' => q(hectopascal {0}),
						'other' => q(hectopascals {0}),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hectopascals),
						'one' => q(hectopascal {0}),
						'other' => q(hectopascals {0}),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(incinan zaiba),
						'one' => q(incin zaiba {0}),
						'other' => q(incinan zaiba {0}),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(incinan zaiba),
						'one' => q(incin zaiba {0}),
						'other' => q(incinan zaiba {0}),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopascals),
						'one' => q(kilopascal {0}),
						'other' => q(kilopascals {0}),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopascals),
						'one' => q(kilopascal {0}),
						'other' => q(kilopascals {0}),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapascals),
						'one' => q(megapascal {0}),
						'other' => q(megapascals {0}),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapascals),
						'one' => q(megapascal {0}),
						'other' => q(megapascals {0}),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(millibars),
						'one' => q(millibar {0}),
						'other' => q(millibars {0}),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(millibars),
						'one' => q(millibar {0}),
						'other' => q(millibars {0}),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(millimitocin zaiba),
						'one' => q(millimitar zaiba {0}),
						'other' => q(millimitocin zaiba {0}),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(millimitocin zaiba),
						'one' => q(millimitar zaiba {0}),
						'other' => q(millimitocin zaiba {0}),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(pascals),
						'one' => q(pascal {0}),
						'other' => q(pascals {0}),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(pascals),
						'one' => q(pascal {0}),
						'other' => q(pascals {0}),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(laba-laba a sikwaya inci),
						'one' => q(laba a sikwaya inci {0}),
						'other' => q(laba-laba a sikwaya inci {0}),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(laba-laba a sikwaya inci),
						'one' => q(laba a sikwaya inci {0}),
						'other' => q(laba-laba a sikwaya inci {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilomitoci a saʼa),
						'one' => q(kilomita {0} a sa′a),
						'other' => q(kilomitoci {0} a sa′a),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilomitoci a saʼa),
						'one' => q(kilomita {0} a sa′a),
						'other' => q(kilomitoci {0} a sa′a),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(knots),
						'one' => q(knot {0}),
						'other' => q(knots {0}),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(knots),
						'one' => q(knot {0}),
						'other' => q(knots {0}),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(mitoci a daƙiƙa),
						'one' => q(mita a daƙiƙa {0}),
						'other' => q(mitoci a daƙiƙa {0}),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(mitoci a daƙiƙa),
						'one' => q(mita a daƙiƙa {0}),
						'other' => q(mitoci a daƙiƙa {0}),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mil-mil a saʼa),
						'one' => q(mil {0} a sa′a),
						'other' => q(mil-mil {0} a sa′a),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mil-mil a saʼa),
						'one' => q(mil {0} a sa′a),
						'other' => q(mil-mil {0} a sa′a),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(digiri-digiri Selsiyas),
						'one' => q(Digiri Selsiyas {0}),
						'other' => q(digiri-digiri Selsiyas {0}),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(digiri-digiri Selsiyas),
						'one' => q(Digiri Selsiyas {0}),
						'other' => q(digiri-digiri Selsiyas {0}),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(digiri-digiri faranhit),
						'one' => q(Digiri Faranhit {0}),
						'other' => q(digiri-digiri faranhit {0}),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(digiri-digiri faranhit),
						'one' => q(Digiri Faranhit {0}),
						'other' => q(digiri-digiri faranhit {0}),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'one' => q(Digirin yanayi {0}),
						'other' => q(digiri-digiri {0}),
					},
					# Core Unit Identifier
					'generic' => {
						'one' => q(Digirin yanayi {0}),
						'other' => q(digiri-digiri {0}),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvins),
						'one' => q(kelvin {0}),
						'other' => q(kelvins {0}),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvins),
						'one' => q(kelvin {0}),
						'other' => q(kelvins {0}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newton-meters),
						'one' => q(newton-meter {0}),
						'other' => q(newton-meters {0}),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton-meters),
						'one' => q(newton-meter {0}),
						'other' => q(newton-meters {0}),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pound-feet),
						'one' => q(Pound-force-foot {0}),
						'other' => q(pound-feet {0}),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pound-feet),
						'one' => q(Pound-force-foot {0}),
						'other' => q(pound-feet {0}),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(eka-ƙafafu),
						'one' => q(eka-ƙafa {0}),
						'other' => q(eka-ƙafafu {0}),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(eka-ƙafafu),
						'one' => q(eka-ƙafa {0}),
						'other' => q(eka-ƙafafu {0}),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(ganguna),
						'one' => q(ganga {0}),
						'other' => q(ganguna {0}),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(ganguna),
						'one' => q(ganga {0}),
						'other' => q(ganguna {0}),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q(bushel {0}),
						'other' => q(bushels {0}),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q(bushel {0}),
						'other' => q(bushels {0}),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sentilitoci),
						'one' => q(sentilita {0}),
						'other' => q(sentilitoci {0}),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sentilitoci),
						'one' => q(sentilita {0}),
						'other' => q(sentilitoci {0}),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(kubik sentimitoci),
						'one' => q(kubik sentimita {0}),
						'other' => q(kubik sentimitoci {0}),
						'per' => q({0} a kubik sentimita),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(kubik sentimitoci),
						'one' => q(kubik sentimita {0}),
						'other' => q(kubik sentimitoci {0}),
						'per' => q({0} a kubik sentimita),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kubik ƙafafu),
						'one' => q(kubik ƙafa {0}),
						'other' => q(kubik ƙafafu {0}),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kubik ƙafafu),
						'one' => q(kubik ƙafa {0}),
						'other' => q(kubik ƙafafu {0}),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(kubic incina),
						'one' => q(kubik inci {0}),
						'other' => q(kubik incina {0}),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(kubic incina),
						'one' => q(kubik inci {0}),
						'other' => q(kubik incina {0}),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kubik kilomitoci),
						'one' => q(kubik kilomita {0}),
						'other' => q(kubik kilomitoci {0}),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kubik kilomitoci),
						'one' => q(kubik kilomita {0}),
						'other' => q(kubik kilomitoci {0}),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(kubic mitoci),
						'one' => q(kubic mita {0}),
						'other' => q(kubic mitoci {0}),
						'per' => q({0} a kubic mita),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(kubic mitoci),
						'one' => q(kubic mita {0}),
						'other' => q(kubic mitoci {0}),
						'per' => q({0} a kubic mita),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(kubik mil-mil),
						'one' => q(kubik mil {0}),
						'other' => q(kubik mil-mil {0}),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(kubik mil-mil),
						'one' => q(kubik mil {0}),
						'other' => q(kubik mil-mil {0}),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(kubik yaduka),
						'one' => q(kubik yadi {0}),
						'other' => q(kubik yaduka {0}),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(kubik yaduka),
						'one' => q(kubik yadi {0}),
						'other' => q(kubik yaduka {0}),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q(kofi {0}),
						'other' => q(kofuna {0}),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q(kofi {0}),
						'other' => q(kofuna {0}),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(metric cups),
						'one' => q(metric cup {0}),
						'other' => q(metric cups {0}),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(metric cups),
						'one' => q(metric cup {0}),
						'other' => q(metric cups {0}),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(desilitoci),
						'one' => q(desilita {0}),
						'other' => q(desilitoci {0}),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(desilitoci),
						'one' => q(desilita {0}),
						'other' => q(desilitoci {0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dessert spoon),
						'one' => q(dessert spoon {0}),
						'other' => q(dessert spoon {0}),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dessert spoon),
						'one' => q(dessert spoon {0}),
						'other' => q(dessert spoon {0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Imp. dessert spoon),
						'one' => q(Imp. dessert spoon {0}),
						'other' => q(Imp. dessert spoon {0}),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Imp. dessert spoon),
						'one' => q(Imp. dessert spoon {0}),
						'other' => q(Imp. dessert spoon {0}),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram),
						'one' => q(dram {0}),
						'other' => q({0} dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram),
						'one' => q(dram {0}),
						'other' => q({0} dram),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fluid ounces),
						'one' => q(fluid ounce {0}),
						'other' => q(fluid ounces {0}),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fluid ounces),
						'one' => q(fluid ounce {0}),
						'other' => q(fluid ounces {0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. fluid ounces),
						'one' => q(Imp. fluid ounce {0}),
						'other' => q(Imp. fluid ounces {0}),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. fluid ounces),
						'one' => q(Imp. fluid ounce {0}),
						'other' => q(Imp. fluid ounces {0}),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galan-galan),
						'one' => q(galan {0}),
						'other' => q(galan-galan {0}),
						'per' => q({0} a galan),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galan-galan),
						'one' => q(galan {0}),
						'other' => q(galan-galan {0}),
						'per' => q({0} a galan),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Imp. gallons),
						'one' => q(Imp. gallon {0}),
						'other' => q(Imp. gallons {0}),
						'per' => q({0} a Imp. gallons),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Imp. gallons),
						'one' => q(Imp. gallon {0}),
						'other' => q(Imp. gallons {0}),
						'per' => q({0} a Imp. gallons),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektolitoci),
						'one' => q(hektolita {0}),
						'other' => q(hektolitoci {0}),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektolitoci),
						'one' => q(hektolita {0}),
						'other' => q(hektolitoci {0}),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q(lita {0}),
						'other' => q(litoci {0}),
						'per' => q({0} a lita),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q(lita {0}),
						'other' => q(litoci {0}),
						'per' => q({0} a lita),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitoci),
						'one' => q(megalita {0}),
						'other' => q(megalitoci {0}),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitoci),
						'one' => q(megalita {0}),
						'other' => q(megalitoci {0}),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(millimitoci),
						'one' => q(millimita {0}),
						'other' => q(millimitoci {0}),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(millimitoci),
						'one' => q(millimita {0}),
						'other' => q(millimitoci {0}),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'one' => q(pint {0}),
						'other' => q(pints {0}),
					},
					# Core Unit Identifier
					'pint' => {
						'one' => q(pint {0}),
						'other' => q(pints {0}),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(metric pints),
						'one' => q(metric pint {0}),
						'other' => q(metric pints {0}),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(metric pints),
						'one' => q(metric pint {0}),
						'other' => q(metric pints {0}),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(quarts),
						'one' => q(quart {0}),
						'other' => q(quarts {0}),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(quarts),
						'one' => q(quart {0}),
						'other' => q(quarts {0}),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp. quart),
						'one' => q(Imp. quart {0}),
						'other' => q(Imp. quart {0}),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp. quart),
						'one' => q(Imp. quart {0}),
						'other' => q(Imp. quart {0}),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(manyan cokula),
						'one' => q(babban cokali {0}),
						'other' => q(manyan cokula {0}),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(manyan cokula),
						'one' => q(babban cokali {0}),
						'other' => q(manyan cokula {0}),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(ƙananan cokula),
						'one' => q(ƙaramin cokali {0}),
						'other' => q(ƙananan cokula {0}),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(ƙananan cokula),
						'one' => q(ƙaramin cokali {0}),
						'other' => q(ƙananan cokula {0}),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q(G{0}),
						'other' => q(Gs{0}),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q(G{0}),
						'other' => q(Gs{0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q(m/s²{0}),
						'other' => q(m/s²{0}),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q(m/s²{0}),
						'other' => q(m/s²{0}),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arcmin),
						'one' => q(arcmin{0}),
						'other' => q(arcmin{0}),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcmin),
						'one' => q(arcmin{0}),
						'other' => q(arcmin{0}),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcsec),
						'one' => q(arcsecs{0}),
						'other' => q(arcsecs{0}),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcsec),
						'one' => q(arcsecs{0}),
						'other' => q(arcsecs{0}),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(deg),
						'one' => q(deg{0}),
						'other' => q(deg{0}),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(deg),
						'one' => q(deg{0}),
						'other' => q(deg{0}),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rad),
						'one' => q(rad{0}),
						'other' => q(rad{0}),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad),
						'one' => q(rad{0}),
						'other' => q(rad{0}),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q(rev{0}),
						'other' => q(rev{0}),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q(rev{0}),
						'other' => q(rev{0}),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(eka),
						'one' => q(ek{0}),
						'other' => q(ek{0}),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(eka),
						'one' => q(ek{0}),
						'other' => q(ek{0}),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunam),
						'one' => q(dunam{0}),
						'other' => q(dunam{0}),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunam),
						'one' => q(dunam{0}),
						'other' => q(dunam{0}),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hekta),
						'one' => q(ha{0}),
						'other' => q(hk{0}),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hekta),
						'one' => q(ha{0}),
						'other' => q(hk{0}),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'one' => q(cm²{0}),
						'other' => q(cm²{0}),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q(cm²{0}),
						'other' => q(cm²{0}),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q(sk ƙf {0}),
						'other' => q(sk ƙf{0}),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q(sk ƙf {0}),
						'other' => q(sk ƙf{0}),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'one' => q(in²{0}),
						'other' => q(in²{0}),
					},
					# Core Unit Identifier
					'square-inch' => {
						'one' => q(in²{0}),
						'other' => q(in²{0}),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q(km²{0}),
						'other' => q(km²{0}),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q(km²{0}),
						'other' => q(km²{0}),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q(m²{0}),
						'other' => q(m²{0}),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q(m²{0}),
						'other' => q(m²{0}),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q(sq mi{0}),
						'other' => q(sq mi{0}),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q(sq mi{0}),
						'other' => q(sq mi{0}),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yd²),
						'one' => q(yd²{0}),
						'other' => q(yd²{0}),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yd²),
						'one' => q(yd²{0}),
						'other' => q(yd²{0}),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'one' => q(abu{0}),
						'other' => q(Abw{0}),
					},
					# Core Unit Identifier
					'item' => {
						'one' => q(abu{0}),
						'other' => q(Abw{0}),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karat),
						'one' => q(kt{0}),
						'other' => q(kt{0}),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
						'one' => q(kt{0}),
						'other' => q(kt{0}),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'one' => q(mg/dL{0}),
						'other' => q(mg/dL{0}),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'one' => q(mg/dL{0}),
						'other' => q(mg/dL{0}),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q(mmol/L{0}),
						'other' => q(mmol/L{0}),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q(mmol/L{0}),
						'other' => q(mmol/L{0}),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mol),
						'one' => q(mol{0}),
						'other' => q(mol{0}),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mol),
						'one' => q(mol{0}),
						'other' => q(mol{0}),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q(%{0}),
						'other' => q(%{0}),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q(%{0}),
						'other' => q(%{0}),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ppm),
						'one' => q(ppm{0}),
						'other' => q(ppm{0}),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
						'one' => q(ppm{0}),
						'other' => q(ppm{0}),
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
						'one' => q(L/100km{0}),
						'other' => q(L/100km{0}),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'one' => q(L/100km{0}),
						'other' => q(L/100km{0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q(L/km{0}),
						'other' => q(L/km{0}),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q(L/km{0}),
						'other' => q(L/km{0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'one' => q(mag{0}),
						'other' => q(mag{0}),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'one' => q(mag{0}),
						'other' => q(mag{0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mag UK),
						'one' => q(m/gUK{0}),
						'other' => q(m/gUK{0}),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mag UK),
						'one' => q(m/gUK{0}),
						'other' => q(m/gUK{0}),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q(G{0}),
						'north' => q(A{0}),
						'south' => q(K{0}),
						'west' => q(Y{0}),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q(G{0}),
						'north' => q(A{0}),
						'south' => q(K{0}),
						'west' => q(Y{0}),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q(bit{0}),
						'other' => q(bit{0}),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q(bit{0}),
						'other' => q(bit{0}),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'one' => q(B{0}),
						'other' => q(B{0}),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'one' => q(B{0}),
						'other' => q(B{0}),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gb),
						'one' => q(Gb{0}),
						'other' => q(Gb{0}),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
						'one' => q(Gb{0}),
						'other' => q(Gb{0}),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
						'one' => q(GB{0}),
						'other' => q(GB {0}),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
						'one' => q(GB{0}),
						'other' => q(GB {0}),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
						'one' => q(kb{0}),
						'other' => q(kb{0}),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
						'one' => q(kb{0}),
						'other' => q(kb{0}),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
						'one' => q(kB{0}),
						'other' => q(kB{0}),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
						'one' => q(kB{0}),
						'other' => q(kB{0}),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
						'one' => q(Mb{0}),
						'other' => q(Mb{0}),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
						'one' => q(Mb{0}),
						'other' => q(Mb{0}),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MB),
						'one' => q(MB{0}),
						'other' => q(MB{0}),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MB),
						'one' => q(MB{0}),
						'other' => q(MB{0}),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PB),
						'one' => q(PB{0}),
						'other' => q(PB{0}),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
						'one' => q(PB{0}),
						'other' => q(PB{0}),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
						'one' => q(Tb{0}),
						'other' => q(Tb{0}),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
						'one' => q(Tb{0}),
						'other' => q(Tb{0}),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TB),
						'one' => q(TB{0}),
						'other' => q(TB{0}),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TB),
						'one' => q(TB{0}),
						'other' => q(TB{0}),
					},
					# Long Unit Identifier
					'duration-century' => {
						'one' => q(ƙ{0}),
						'other' => q(ƙ{0}),
					},
					# Core Unit Identifier
					'century' => {
						'one' => q(ƙ{0}),
						'other' => q(ƙ{0}),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(rana),
						'one' => q(r{0}),
						'other' => q(r{0}),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(rana),
						'one' => q(r{0}),
						'other' => q(r{0}),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'one' => q(sk gm{0}),
						'other' => q(sk gm{0}),
					},
					# Core Unit Identifier
					'decade' => {
						'one' => q(sk gm{0}),
						'other' => q(sk gm{0}),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(saʼa),
						'one' => q(s{0}),
						'other' => q(s{0}),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(saʼa),
						'one' => q(s{0}),
						'other' => q(s{0}),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'one' => q(μs{0}),
						'other' => q(μs{0}),
					},
					# Core Unit Identifier
					'microsecond' => {
						'one' => q(μs{0}),
						'other' => q(μs{0}),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(msek),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(msek),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(mnt),
						'one' => q(minti{0}),
						'other' => q(minti {0}),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(mnt),
						'one' => q(minti{0}),
						'other' => q(minti {0}),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(wata),
						'one' => q(w{0}),
						'other' => q(w{0}),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(wata),
						'one' => q(w{0}),
						'other' => q(w{0}),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q(ns{0}),
						'other' => q(ns{0}),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q(ns{0}),
						'other' => q(ns{0}),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'one' => q(kwt{0}),
						'other' => q(kwt{0}),
					},
					# Core Unit Identifier
					'quarter' => {
						'one' => q(kwt{0}),
						'other' => q(kwt{0}),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(mk),
						'one' => q(m{0}),
						'other' => q(m{0}),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(mk),
						'one' => q(m{0}),
						'other' => q(m{0}),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(shkr),
						'one' => q(shkr {0}),
						'other' => q(s{0}),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(shkr),
						'one' => q(shkr {0}),
						'other' => q(s{0}),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q(A{0}),
						'other' => q(A{0}),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q(A{0}),
						'other' => q(A{0}),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mA),
						'one' => q(mA{0}),
						'other' => q(mA{0}),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mA),
						'one' => q(mA{0}),
						'other' => q(mA{0}),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q(Ω{0}),
						'other' => q(Ω{0}),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q(Ω{0}),
						'other' => q(Ω{0}),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volt),
						'one' => q(V{0}),
						'other' => q(V{0}),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volt),
						'one' => q(V{0}),
						'other' => q(V{0}),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'one' => q(Btu{0}),
						'other' => q(Btu{0}),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'one' => q(Btu{0}),
						'other' => q(Btu{0}),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'one' => q(kal{0}),
						'other' => q(kal{0}),
					},
					# Core Unit Identifier
					'calorie' => {
						'one' => q(kal{0}),
						'other' => q(kal{0}),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(eV),
						'one' => q(eV{0}),
						'other' => q(eV{0}),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(eV),
						'one' => q(eV{0}),
						'other' => q(eV{0}),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'one' => q(Kal{0}),
						'other' => q(Kal{0}),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'one' => q(Kal{0}),
						'other' => q(Kal{0}),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joule),
						'one' => q(J{0}),
						'other' => q(J{0}),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joule),
						'one' => q(J{0}),
						'other' => q(J{0}),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'one' => q(kcal{0}),
						'other' => q(kcal{0}),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'one' => q(kcal{0}),
						'other' => q(kcal{0}),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kj),
						'one' => q(kj{0}),
						'other' => q(kj{0}),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kj),
						'one' => q(kj{0}),
						'other' => q(kj{0}),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q(kWh{0}),
						'other' => q(kWh{0}),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q(kWh{0}),
						'other' => q(kWh{0}),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q(US therm{0}),
						'other' => q(US therm{0}),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q(US therm{0}),
						'other' => q(US therm{0}),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q(kWh/100km{0}),
						'other' => q(kWh/100km{0}),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q(kWh/100km{0}),
						'other' => q(kWh/100km{0}),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(N),
						'one' => q(N{0}),
						'other' => q(N{0}),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(N),
						'one' => q(N{0}),
						'other' => q(N{0}),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(lbf),
						'one' => q(lbf{0}),
						'other' => q(lbf{0}),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(lbf),
						'one' => q(lbf{0}),
						'other' => q(lbf{0}),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'one' => q(GHz{0}),
						'other' => q(GHz{0}),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'one' => q(GHz{0}),
						'other' => q(GHz{0}),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'one' => q(Hz{0}),
						'other' => q(Hz{0}),
					},
					# Core Unit Identifier
					'hertz' => {
						'one' => q(Hz{0}),
						'other' => q(Hz{0}),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'one' => q(kHz{0}),
						'other' => q(kHz{0}),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'one' => q(kHz{0}),
						'other' => q(kHz{0}),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'one' => q(MHz{0}),
						'other' => q(MHz{0}),
					},
					# Core Unit Identifier
					'megahertz' => {
						'one' => q(MHz{0}),
						'other' => q(MHz{0}),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'one' => q(aya{0}),
						'other' => q(ayoyi{0}),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q(aya{0}),
						'other' => q(ayoyi{0}),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'one' => q(dpcm{0}),
						'other' => q(dpcm{0}),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'one' => q(dpcm{0}),
						'other' => q(dpcm{0}),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'one' => q(dpi{0}),
						'other' => q(dpi{0}),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'one' => q(dpi{0}),
						'other' => q(dpi{0}),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'one' => q(em{0}),
						'other' => q(em{0}),
					},
					# Core Unit Identifier
					'em' => {
						'one' => q(em{0}),
						'other' => q(em{0}),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q(MP{0}),
						'other' => q(MP{0}),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q(MP{0}),
						'other' => q(MP{0}),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q(px{0}),
						'other' => q(px{0}),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q(px{0}),
						'other' => q(px{0}),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'one' => q(ppcm{0}),
						'other' => q(ppcm{0}),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'one' => q(ppcm{0}),
						'other' => q(ppcm{0}),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'one' => q(ppi{0}),
						'other' => q(ppi{0}),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'one' => q(ppi{0}),
						'other' => q(ppi{0}),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q(au{0}),
						'other' => q(au{0}),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q(au{0}),
						'other' => q(au{0}),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q(cm{0}),
						'other' => q(cm{0}),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q(cm{0}),
						'other' => q(cm{0}),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q(dm{0}),
						'other' => q(dm{0}),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q(dm{0}),
						'other' => q(dm{0}),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'one' => q(R⊕{0}),
						'other' => q(R⊕{0}),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q(R⊕{0}),
						'other' => q(R⊕{0}),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q(fth{0}),
						'other' => q(fth{0}),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q(fth{0}),
						'other' => q(fth{0}),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q(ƙf{0}),
						'other' => q(ƙff{0}),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q(ƙf{0}),
						'other' => q(ƙff{0}),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
						'one' => q(fur{0}),
						'other' => q(fur{0}),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
						'one' => q(fur{0}),
						'other' => q(fur{0}),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q(km{0}),
						'other' => q(km{0}),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q(km{0}),
						'other' => q(km{0}),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(sh),
						'one' => q(sh{0}),
						'other' => q(sh{0}),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(sh),
						'one' => q(sh{0}),
						'other' => q(sh{0}),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q(m{0}),
						'other' => q(m{0}),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q(m{0}),
						'other' => q(m{0}),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'one' => q(μm{0}),
						'other' => q(μm{0}),
					},
					# Core Unit Identifier
					'micrometer' => {
						'one' => q(μm{0}),
						'other' => q(μm{0}),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q(mi{0}),
						'other' => q(mil-mil{0}),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q(mi{0}),
						'other' => q(mil-mil{0}),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q(smi{0}),
						'other' => q(smi{0}),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q(smi{0}),
						'other' => q(smi{0}),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q(mm{0}),
						'other' => q(mm{0}),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q(mm{0}),
						'other' => q(mm{0}),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'one' => q(nm{0}),
						'other' => q(nm{0}),
					},
					# Core Unit Identifier
					'nanometer' => {
						'one' => q(nm{0}),
						'other' => q(nm{0}),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q(nmi{0}),
						'other' => q(nmi{0}),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q(nmi{0}),
						'other' => q(nmi{0}),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(fasek),
						'one' => q(fasek{0}),
						'other' => q(fasekoki{0}),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(fasek),
						'one' => q(fasek{0}),
						'other' => q(fasekoki{0}),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q(pm{0}),
						'other' => q(pm{0}),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q(pm{0}),
						'other' => q(pm{0}),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q(mk{0}),
						'other' => q(mk{0}),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q(mk{0}),
						'other' => q(mk{0}),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(R☉),
						'one' => q(R☉{0}),
						'other' => q(R☉{0}),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(R☉),
						'one' => q(R☉{0}),
						'other' => q(R☉{0}),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q(yd{0}),
						'other' => q(ydk{0}),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q(yd{0}),
						'other' => q(ydk{0}),
					},
					# Long Unit Identifier
					'light-candela' => {
						'one' => q(cd{0}),
						'other' => q(cd{0}),
					},
					# Core Unit Identifier
					'candela' => {
						'one' => q(cd{0}),
						'other' => q(cd{0}),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'one' => q(lm{0}),
						'other' => q(lm{0}),
					},
					# Core Unit Identifier
					'lumen' => {
						'one' => q(lm{0}),
						'other' => q(lm{0}),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q(lx{0}),
						'other' => q(lx{0}),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q(lx{0}),
						'other' => q(lx{0}),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(L☉),
						'one' => q(L☉{0}),
						'other' => q(L☉{0}),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(L☉),
						'one' => q(L☉{0}),
						'other' => q(L☉{0}),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(carat),
						'one' => q(CD{0}),
						'other' => q(CD{0}),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(carat),
						'one' => q(CD{0}),
						'other' => q(CD{0}),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(Da),
						'one' => q(Da{0}),
						'other' => q(Da{0}),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(Da),
						'one' => q(Da{0}),
						'other' => q(Da{0}),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(M⊕),
						'one' => q(M⊕{0}),
						'other' => q(M⊕{0}),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(M⊕),
						'one' => q(M⊕{0}),
						'other' => q(M⊕{0}),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'one' => q(ƙwaya{0}),
						'other' => q(ƙwaya{0}),
					},
					# Core Unit Identifier
					'grain' => {
						'one' => q(ƙwaya{0}),
						'other' => q(ƙwaya{0}),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q(g{0}),
						'other' => q(g{0}),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q(g{0}),
						'other' => q(g{0}),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q(kg{0}),
						'other' => q(kg{0}),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q(kg{0}),
						'other' => q(kg{0}),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'one' => q(μg{0}),
						'other' => q(μg{0}),
					},
					# Core Unit Identifier
					'microgram' => {
						'one' => q(μg{0}),
						'other' => q(μg{0}),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'one' => q(mg{0}),
						'other' => q(mg{0}),
					},
					# Core Unit Identifier
					'milligram' => {
						'one' => q(mg{0}),
						'other' => q(mg{0}),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q(oz{0}),
						'other' => q(oz{0}),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q(oz{0}),
						'other' => q(oz{0}),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz t),
						'one' => q(oz t{0}),
						'other' => q(oz t{0}),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q(oz t{0}),
						'other' => q(oz t{0}),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(laba),
						'one' => q({0}#),
						'other' => q({0}#),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(laba),
						'one' => q({0}#),
						'other' => q({0}#),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(M☉),
						'one' => q(M☉{0}),
						'other' => q(M☉{0}),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(M☉),
						'one' => q(M☉{0}),
						'other' => q(M☉{0}),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone),
						'one' => q(st{0}),
						'other' => q(st{0}),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
						'one' => q(st{0}),
						'other' => q(st{0}),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tan),
						'one' => q(tn{0}),
						'other' => q(tn{0}),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tan),
						'one' => q(tn{0}),
						'other' => q(tn{0}),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'one' => q(t{0}),
						'other' => q(t{0}),
					},
					# Core Unit Identifier
					'tonne' => {
						'one' => q(t{0}),
						'other' => q(t{0}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'one' => q(GW{0}),
						'other' => q(GW{0}),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'one' => q(GW{0}),
						'other' => q(GW{0}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q(ƙi{0}),
						'other' => q(ƙi{0}),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q(ƙi{0}),
						'other' => q(ƙi{0}),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q(kW{0}),
						'other' => q(kW{0}),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q(kW{0}),
						'other' => q(kW{0}),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'one' => q(MW{0}),
						'other' => q(MW{0}),
					},
					# Core Unit Identifier
					'megawatt' => {
						'one' => q(MW{0}),
						'other' => q(MW{0}),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'one' => q(mW{0}),
						'other' => q(mW{0}),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'one' => q(mW{0}),
						'other' => q(mW{0}),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(wat),
						'one' => q(W{0}),
						'other' => q(W{0}),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(wat),
						'one' => q(W{0}),
						'other' => q(W{0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'one' => q(yny{0}),
						'other' => q(yny{0}),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'one' => q(yny{0}),
						'other' => q(yny{0}),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q(sanda{0}),
						'other' => q(sanda{0}),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q(sanda{0}),
						'other' => q(sanda{0}),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q(hPa{0}),
						'other' => q(hPa{0}),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q(hPa{0}),
						'other' => q(hPa{0}),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q(″ Hg{0}),
						'other' => q(″ Hg{0}),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q(″ Hg{0}),
						'other' => q(″ Hg{0}),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'one' => q(kPa{0}),
						'other' => q(kPa{0}),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'one' => q(kPa{0}),
						'other' => q(kPa{0}),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'one' => q(MPa{0}),
						'other' => q(MPa{0}),
					},
					# Core Unit Identifier
					'megapascal' => {
						'one' => q(MPa{0}),
						'other' => q(MPa{0}),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q(mbar{0}),
						'other' => q(mbar{0}),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q(mbar{0}),
						'other' => q(mbar{0}),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q(mmHg{0}),
						'other' => q(mmHg{0}),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q(mmHg{0}),
						'other' => q(mmHg{0}),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'one' => q(Pa{0}),
						'other' => q(Pa{0}),
					},
					# Core Unit Identifier
					'pascal' => {
						'one' => q(Pa{0}),
						'other' => q(Pa{0}),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'one' => q(psi{0}),
						'other' => q(psi{0}),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'one' => q(psi{0}),
						'other' => q(psi{0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q(km/s{0}),
						'other' => q(km/s{0}),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q(km/s{0}),
						'other' => q(km/s{0}),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'one' => q(kn{0}),
						'other' => q(kn{0}),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q(kn{0}),
						'other' => q(kn{0}),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/d),
						'one' => q(m/d{0}),
						'other' => q(m/d{0}),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/d),
						'one' => q(m/d{0}),
						'other' => q(m/d{0}),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q(mas{0}),
						'other' => q(mas{0}),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q(mas{0}),
						'other' => q(mas{0}),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°S),
						'one' => q(S°{0}),
						'other' => q(S°{0}),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°S),
						'one' => q(S°{0}),
						'other' => q(S°{0}),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
						'one' => q(°{0}),
						'other' => q(°{0}),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q(°{0}),
						'other' => q(°{0}),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'one' => q(K{0}),
						'other' => q(K{0}),
					},
					# Core Unit Identifier
					'kelvin' => {
						'one' => q(K{0}),
						'other' => q(K{0}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'one' => q(N⋅m{0}),
						'other' => q(N⋅m{0}),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'one' => q(N⋅m{0}),
						'other' => q(N⋅m{0}),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'one' => q(lbf⋅ft{0}),
						'other' => q(lbf⋅ft{0}),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q(lbf⋅ft{0}),
						'other' => q(lbf⋅ft{0}),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q(ek ƙf{0}),
						'other' => q(ek ƙf{0}),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q(ek ƙf{0}),
						'other' => q(ek ƙf{0}),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q(gang{0}),
						'other' => q(gang{0}),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q(gang{0}),
						'other' => q(gang{0}),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bu),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bu),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'one' => q(sL{0}),
						'other' => q(sL {0}),
					},
					# Core Unit Identifier
					'centiliter' => {
						'one' => q(sL{0}),
						'other' => q(sL {0}),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'one' => q(cm³{0}),
						'other' => q(cm³{0}),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q(cm³{0}),
						'other' => q(cm³{0}),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'one' => q(ƙf³{0}),
						'other' => q(ƙf³{0}),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'one' => q(ƙf³{0}),
						'other' => q(ƙf³{0}),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'one' => q(in³{0}),
						'other' => q(in³{0}),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'one' => q(in³{0}),
						'other' => q(in³{0}),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q(km³{0}),
						'other' => q(km³{0}),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q(km³{0}),
						'other' => q(km³{0}),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'one' => q(m³{0}),
						'other' => q(m³{0}),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'one' => q(m³{0}),
						'other' => q(m³{0}),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q(mi³{0}),
						'other' => q(mi³{0}),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q(mi³{0}),
						'other' => q(mi³{0}),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'one' => q(yd³{0}),
						'other' => q(yd³{0}),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'one' => q(yd³{0}),
						'other' => q(yd³{0}),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(kofi),
						'one' => q(k{0}),
						'other' => q(kfn{0}),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(kofi),
						'one' => q(k{0}),
						'other' => q(kfn{0}),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q(mc{0}),
						'other' => q(mc{0}),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q(mc{0}),
						'other' => q(mc{0}),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'one' => q(dL{0}),
						'other' => q(dL{0}),
					},
					# Core Unit Identifier
					'deciliter' => {
						'one' => q(dL{0}),
						'other' => q(dL{0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dsp),
						'one' => q(dsp{0}),
						'other' => q(dsp{0}),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dsp),
						'one' => q(dsp{0}),
						'other' => q(dsp{0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dsp lmp),
						'one' => q(dsp-lmp{0}),
						'other' => q(dsp-lmp{0}),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dsp lmp),
						'one' => q(dsp-lmp{0}),
						'other' => q(dsp-lmp{0}),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl.dr.),
						'one' => q(fl.dr.{0}),
						'other' => q(fl.dr.{0}),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl.dr.),
						'one' => q(fl.dr.{0}),
						'other' => q(fl.dr.{0}),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'one' => q(ɗigo{0}),
						'other' => q(ɗigo{0}),
					},
					# Core Unit Identifier
					'drop' => {
						'one' => q(ɗigo{0}),
						'other' => q(ɗigo{0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'one' => q(fl oz{0}),
						'other' => q(fl oz{0}),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'one' => q(fl oz{0}),
						'other' => q(fl oz{0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'one' => q(fl oz Im{0}),
						'other' => q(fl oz Im{0}),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'one' => q(fl oz Im{0}),
						'other' => q(fl oz Im{0}),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'one' => q(gal{0}),
						'other' => q(gal{0}),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'one' => q(gal{0}),
						'other' => q(gal{0}),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Imp gal),
						'one' => q(galIm{0}),
						'other' => q(galIm{0}),
						'per' => q({0}/galIm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Imp gal),
						'one' => q(galIm{0}),
						'other' => q(galIm{0}),
						'per' => q({0}/galIm),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'one' => q(hL{0}),
						'other' => q(hL{0}),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'one' => q(hL{0}),
						'other' => q(hL{0}),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'one' => q(jigger{0}),
						'other' => q(jigger{0}),
					},
					# Core Unit Identifier
					'jigger' => {
						'one' => q(jigger{0}),
						'other' => q(jigger{0}),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(lita),
						'one' => q(L{0}),
						'other' => q(L{0}),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(lita),
						'one' => q(L{0}),
						'other' => q(L{0}),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'one' => q(ML{0}),
						'other' => q(ML{0}),
					},
					# Core Unit Identifier
					'megaliter' => {
						'one' => q(ML{0}),
						'other' => q(ML{0}),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'one' => q(mL{0}),
						'other' => q(mL{0}),
					},
					# Core Unit Identifier
					'milliliter' => {
						'one' => q(mL{0}),
						'other' => q(mL{0}),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pn),
						'one' => q(pn{0}),
						'other' => q(pn{0}),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pn),
						'one' => q(pn{0}),
						'other' => q(pn{0}),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pt),
						'one' => q(pt{0}),
						'other' => q(pt{0}),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pt),
						'one' => q(pt{0}),
						'other' => q(pt{0}),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'one' => q(mpt{0}),
						'other' => q(mpt{0}),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'one' => q(mpt{0}),
						'other' => q(mpt{0}),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qt),
						'one' => q(qt{0}),
						'other' => q(qt{0}),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qt),
						'one' => q(qt{0}),
						'other' => q(qt{0}),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q(qt-Imp.{0}),
						'other' => q(qt-Imp.{0}),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q(qt-Imp.{0}),
						'other' => q(qt-Imp.{0}),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'one' => q(bckl{0}),
						'other' => q(bckl{0}),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'one' => q(bckl{0}),
						'other' => q(bckl{0}),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'one' => q(ƙmc{0}),
						'other' => q(ƙmc{0}),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'one' => q(ƙmc{0}),
						'other' => q(ƙmc{0}),
					},
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q(G {0}),
						'other' => q(G {0}),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q(G {0}),
						'other' => q(G {0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meters/sec²),
						'one' => q(m/s² {0}),
						'other' => q(m/s² {0}),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meters/sec²),
						'one' => q(m/s² {0}),
						'other' => q(m/s² {0}),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arcmins),
						'one' => q(arcmin {0}),
						'other' => q(arcmin {0}),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcmins),
						'one' => q(arcmin {0}),
						'other' => q(arcmin {0}),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcsecs),
						'one' => q(arcsec {0}),
						'other' => q(arcsec {0}),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcsecs),
						'one' => q(arcsec {0}),
						'other' => q(arcsec {0}),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(degrees),
						'one' => q(deg {0}),
						'other' => q(deg {0}),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(degrees),
						'one' => q(deg {0}),
						'other' => q(deg {0}),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radian),
						'one' => q(rad {0}),
						'other' => q(rad {0}),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radian),
						'one' => q(rad {0}),
						'other' => q(rad {0}),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q(rev {0}),
						'other' => q(rev {0}),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q(rev {0}),
						'other' => q(rev {0}),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ekoki),
						'one' => q(ek {0}),
						'other' => q(ek {0}),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ekoki),
						'one' => q(ek {0}),
						'other' => q(ek {0}),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunams),
						'one' => q(dunam {0}),
						'other' => q(dunam {0}),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunams),
						'one' => q(dunam {0}),
						'other' => q(dunam {0}),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektoci),
						'one' => q(ha {0}),
						'other' => q(ha {0}),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektoci),
						'one' => q(ha {0}),
						'other' => q(ha {0}),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'one' => q(cm² {0}),
						'other' => q(cm² {0}),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q(cm² {0}),
						'other' => q(cm² {0}),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(sk ƙafa),
						'one' => q(sk ƙf {0}),
						'other' => q(sk ƙf {0}),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(sk ƙafa),
						'one' => q(sk ƙf {0}),
						'other' => q(sk ƙf {0}),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(incina²),
						'one' => q(in² {0}),
						'other' => q(in² {0}),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(incina²),
						'one' => q(in² {0}),
						'other' => q(in² {0}),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q(km² {0}),
						'other' => q(km² {0}),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q(km² {0}),
						'other' => q(km² {0}),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(mitoci²),
						'one' => q(m² {0}),
						'other' => q(m² {0}),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(mitoci²),
						'one' => q(m² {0}),
						'other' => q(m² {0}),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(sk mil-mil),
						'one' => q(sq mi {0}),
						'other' => q(sq mi {0}),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(sk mil-mil),
						'one' => q(sq mi {0}),
						'other' => q(sq mi {0}),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yaduna²),
						'one' => q(yd² {0}),
						'other' => q(yd² {0}),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yaduna²),
						'one' => q(yd² {0}),
						'other' => q(yd² {0}),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(abu),
						'one' => q(abu {0}),
						'other' => q(Abw. {0}),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(abu),
						'one' => q(abu {0}),
						'other' => q(Abw. {0}),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karats),
						'one' => q(kt {0}),
						'other' => q(kt {0}),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karats),
						'one' => q(kt {0}),
						'other' => q(kt {0}),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'one' => q(mg/dL {0}),
						'other' => q(mg/dL {0}),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'one' => q(mg/dL {0}),
						'other' => q(mg/dL {0}),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimol/liter),
						'one' => q(mmol/L {0}),
						'other' => q(mmol/L {0}),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimol/liter),
						'one' => q(mmol/L {0}),
						'other' => q(mmol/L {0}),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mole),
						'one' => q(mol {0}),
						'other' => q(mol {0}),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mole),
						'one' => q(mol {0}),
						'other' => q(mol {0}),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(kaso),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(kaso),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(permille),
						'one' => q(‰{0}),
						'other' => q(‰{0}),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(permille),
						'one' => q(‰{0}),
						'other' => q(‰{0}),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(parts/million),
						'one' => q(ppm {0}),
						'other' => q(ppm {0}),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(parts/million),
						'one' => q(ppm {0}),
						'other' => q(ppm {0}),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(permyriad),
						'one' => q(‱{0}),
						'other' => q(‱{0}),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(permyriad),
						'one' => q(‱{0}),
						'other' => q(‱{0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'one' => q(L/100km {0}),
						'other' => q(L/100km {0}),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'one' => q(L/100km {0}),
						'other' => q(L/100km {0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litoci/km),
						'one' => q(L/km {0}),
						'other' => q(L/km {0}),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litoci/km),
						'one' => q(L/km {0}),
						'other' => q(L/km {0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mil-mil/gal),
						'one' => q(mag {0}),
						'other' => q(mag {0}),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil-mil/gal),
						'one' => q(mag {0}),
						'other' => q(mag {0}),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil-mil/gal Imp.),
						'one' => q(mag Imp. {0}),
						'other' => q(mag Imp. {0}),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil-mil/gal Imp.),
						'one' => q(mag Imp. {0}),
						'other' => q(mag Imp. {0}),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q(G {0}),
						'north' => q(A {0}),
						'south' => q(K {0}),
						'west' => q(Y {0}),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q(G {0}),
						'north' => q(A {0}),
						'south' => q(K {0}),
						'west' => q(Y {0}),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q(bit {0}),
						'other' => q(bit {0}),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q(bit {0}),
						'other' => q(bit {0}),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'one' => q(byte {0}),
						'other' => q(byte {0}),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q(byte {0}),
						'other' => q(byte {0}),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
						'one' => q(Gb {0}),
						'other' => q(Gb {0}),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q(Gb {0}),
						'other' => q(Gb {0}),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GByte),
						'one' => q(GB {0}),
						'other' => q(GB {0}),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GByte),
						'one' => q(GB {0}),
						'other' => q(GB {0}),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
						'one' => q(kb {0}),
						'other' => q(kb {0}),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
						'one' => q(kb {0}),
						'other' => q(kb {0}),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(KByte),
						'one' => q(kB {0}),
						'other' => q(kB {0}),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(KByte),
						'one' => q(kB {0}),
						'other' => q(kB {0}),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
						'one' => q(Mb {0}),
						'other' => q(Mb {0}),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
						'one' => q(Mb {0}),
						'other' => q(Mb {0}),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MByte),
						'one' => q(MB {0}),
						'other' => q(MB {0}),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MByte),
						'one' => q(MB {0}),
						'other' => q(MB {0}),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PByte),
						'one' => q(PB {0}),
						'other' => q(PB {0}),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PByte),
						'one' => q(PB {0}),
						'other' => q(PB {0}),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
						'one' => q(Tb {0}),
						'other' => q(Tb {0}),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
						'one' => q(Tb {0}),
						'other' => q(Tb {0}),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TByte),
						'one' => q(TB {0}),
						'other' => q(TB {0}),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TByte),
						'one' => q(TB {0}),
						'other' => q(TB {0}),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ƙ),
						'one' => q(ƙ {0}),
						'other' => q(ƙ {0}),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ƙ),
						'one' => q(ƙ {0}),
						'other' => q(ƙ {0}),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ranaku),
						'one' => q(rana {0}),
						'other' => q(Rnk. {0}),
						'per' => q({0}/r),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ranaku),
						'one' => q(rana {0}),
						'other' => q(Rnk. {0}),
						'per' => q({0}/r),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(shkr gm),
						'one' => q(sk gm {0}),
						'other' => q(sk gm {0}),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(shkr gm),
						'one' => q(sk gm {0}),
						'other' => q(sk gm {0}),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(saʼoʼi),
						'one' => q(s {0}),
						'other' => q(s {0}),
						'per' => q({0}/saʼa),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(saʼoʼi),
						'one' => q(s {0}),
						'other' => q(s {0}),
						'per' => q({0}/saʼa),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsecs),
						'one' => q(μs {0}),
						'other' => q(μs {0}),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsecs),
						'one' => q(μs {0}),
						'other' => q(μs {0}),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milseks),
						'one' => q(ms {0}),
						'other' => q(ms {0}),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milseks),
						'one' => q(ms {0}),
						'other' => q(ms {0}),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(mintc),
						'one' => q(mnt {0}),
						'other' => q(mnt {0}),
						'per' => q({0}/mnt),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(mintc),
						'one' => q(mnt {0}),
						'other' => q(mnt {0}),
						'per' => q({0}/mnt),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(watanni),
						'one' => q(wat {0}),
						'other' => q(wtnn {0}),
						'per' => q({0}/w),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(watanni),
						'one' => q(wat {0}),
						'other' => q(wtnn {0}),
						'per' => q({0}/w),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanoseks),
						'one' => q(ns {0}),
						'other' => q(ns {0}),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanoseks),
						'one' => q(ns {0}),
						'other' => q(ns {0}),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kwt),
						'one' => q(kwt {0}),
						'other' => q(kwtc {0}),
						'per' => q(k/{0}),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kwt),
						'one' => q(kwt {0}),
						'other' => q(kwtc {0}),
						'per' => q(k/{0}),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(daƙ),
						'one' => q(d {0}),
						'other' => q(d {0}),
						'per' => q({0}/d),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(daƙ),
						'one' => q(d {0}),
						'other' => q(d {0}),
						'per' => q({0}/d),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(makonni),
						'one' => q(mk {0}),
						'other' => q(mkn {0}),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(makonni),
						'one' => q(mk {0}),
						'other' => q(mkn {0}),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(shekaru),
						'one' => q(shkr {0}),
						'other' => q(shkru {0}),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(shekaru),
						'one' => q(shkr {0}),
						'other' => q(shkru {0}),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q(A {0}),
						'other' => q(A {0}),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q(A {0}),
						'other' => q(A {0}),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliamps),
						'one' => q(mA {0}),
						'other' => q(mA {0}),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliamps),
						'one' => q(mA {0}),
						'other' => q(mA {0}),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q(Ω {0}),
						'other' => q(Ω {0}),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q(Ω {0}),
						'other' => q(Ω {0}),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volts),
						'one' => q(V {0}),
						'other' => q(V {0}),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volts),
						'one' => q(V {0}),
						'other' => q(V {0}),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q(Btu {0}),
						'other' => q(Btu {0}),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q(Btu {0}),
						'other' => q(Btu {0}),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kal),
						'one' => q(kal {0}),
						'other' => q(kal {0}),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kal),
						'one' => q(kal {0}),
						'other' => q(kal {0}),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(electronvolt),
						'one' => q(eV {0}),
						'other' => q(eV {0}),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(electronvolt),
						'one' => q(eV {0}),
						'other' => q(eV {0}),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Kal),
						'one' => q(Kal {0}),
						'other' => q(Kal {0}),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kal),
						'one' => q(Kal {0}),
						'other' => q(Kal {0}),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joules),
						'one' => q(J {0}),
						'other' => q(J {0}),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joules),
						'one' => q(J {0}),
						'other' => q(J {0}),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'one' => q(kcal {0}),
						'other' => q(kcal {0}),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'one' => q(kcal {0}),
						'other' => q(kcal {0}),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoule),
						'one' => q(kj {0}),
						'other' => q(kj {0}),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoule),
						'one' => q(kj {0}),
						'other' => q(kj {0}),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kW-hour),
						'one' => q(kWh {0}),
						'other' => q(kWh {0}),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kW-hour),
						'one' => q(kWh {0}),
						'other' => q(kWh {0}),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q(US therm {0}),
						'other' => q(US therm {0}),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q(US therm {0}),
						'other' => q(US therm {0}),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q(kWh/100km {0}),
						'other' => q(kWh/100km {0}),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q(kWh/100km {0}),
						'other' => q(kWh/100km {0}),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
						'one' => q(N {0}),
						'other' => q(N {0}),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
						'one' => q(N {0}),
						'other' => q(N {0}),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pounds-force),
						'one' => q(lbf {0}),
						'other' => q(lbf {0}),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pounds-force),
						'one' => q(lbf {0}),
						'other' => q(lbf {0}),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'one' => q(GHz {0}),
						'other' => q(GHz {0}),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'one' => q(GHz {0}),
						'other' => q(GHz {0}),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'one' => q(Hz {0}),
						'other' => q(Hz {0}),
					},
					# Core Unit Identifier
					'hertz' => {
						'one' => q(Hz {0}),
						'other' => q(Hz {0}),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'one' => q(kHz {0}),
						'other' => q(kHz {0}),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'one' => q(kHz {0}),
						'other' => q(kHz {0}),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'one' => q(MHz {0}),
						'other' => q(MHz {0}),
					},
					# Core Unit Identifier
					'megahertz' => {
						'one' => q(MHz {0}),
						'other' => q(MHz {0}),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(aya),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(aya),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'one' => q(dpcm {0}),
						'other' => q(dpcm {0}),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'one' => q(dpcm {0}),
						'other' => q(dpcm {0}),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'one' => q(dpi {0}),
						'other' => q(dpi {0}),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'one' => q(dpi {0}),
						'other' => q(dpi {0}),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'one' => q(em {0}),
						'other' => q(em {0}),
					},
					# Core Unit Identifier
					'em' => {
						'one' => q(em {0}),
						'other' => q(em {0}),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megafikzels),
						'one' => q(MP {0}),
						'other' => q(MP {0}),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megafikzels),
						'one' => q(MP {0}),
						'other' => q(MP {0}),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(fikzels),
						'one' => q(px {0}),
						'other' => q(px {0}),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(fikzels),
						'one' => q(px {0}),
						'other' => q(px {0}),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'one' => q(ppi {0}),
						'other' => q(ppi {0}),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'one' => q(ppi {0}),
						'other' => q(ppi {0}),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q(au {0}),
						'other' => q(au {0}),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q(au {0}),
						'other' => q(au {0}),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q(cm {0}),
						'other' => q(cm {0}),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q(cm {0}),
						'other' => q(cm {0}),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q(dm {0}),
						'other' => q(dm {0}),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q(dm {0}),
						'other' => q(dm {0}),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'one' => q(R⊕ {0}),
						'other' => q(R⊕ {0}),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q(R⊕ {0}),
						'other' => q(R⊕ {0}),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathom),
						'one' => q(fth {0}),
						'other' => q(fth {0}),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathom),
						'one' => q(fth {0}),
						'other' => q(fth {0}),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ƙafafu),
						'one' => q(ƙf {0}),
						'other' => q(ƙff {0}),
						'per' => q({0}/ƙf),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ƙafafu),
						'one' => q(ƙf {0}),
						'other' => q(ƙff {0}),
						'per' => q({0}/ƙf),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongs),
						'one' => q(fur {0}),
						'other' => q(fur {0}),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongs),
						'one' => q(fur {0}),
						'other' => q(fur {0}),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(incina),
						'one' => q(in {0}),
						'other' => q(in {0}),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(incina),
						'one' => q(in {0}),
						'other' => q(in {0}),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q(km {0}),
						'other' => q({0} km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q(km {0}),
						'other' => q({0} km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(shkr haske),
						'one' => q(sh {0}),
						'other' => q(sh {0}),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(shkr haske),
						'one' => q(sh {0}),
						'other' => q(sh {0}),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'one' => q(m {0}),
						'other' => q(m {0}),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'one' => q(m {0}),
						'other' => q(m {0}),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μmeters),
						'one' => q(μm {0}),
						'other' => q(μm {0}),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μmeters),
						'one' => q(μm {0}),
						'other' => q(μm {0}),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mil-mil),
						'one' => q(mi {0}),
						'other' => q(mi {0}),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mil-mil),
						'one' => q(mi {0}),
						'other' => q(mi {0}),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q(smi {0}),
						'other' => q(smi {0}),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q(smi {0}),
						'other' => q(smi {0}),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q(mm {0}),
						'other' => q(mm {0}),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q(mm {0}),
						'other' => q(mm {0}),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'one' => q(nm {0}),
						'other' => q(nm {0}),
					},
					# Core Unit Identifier
					'nanometer' => {
						'one' => q(nm {0}),
						'other' => q(nm {0}),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q(nmi {0}),
						'other' => q(nmi {0}),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q(nmi {0}),
						'other' => q(nmi {0}),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(fasekoki),
						'one' => q(pc {0}),
						'other' => q(pc {0}),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(fasekoki),
						'one' => q(pc {0}),
						'other' => q(pc {0}),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q(pm {0}),
						'other' => q(pm {0}),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q(pm {0}),
						'other' => q(pm {0}),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(makuna),
						'one' => q(mk {0}),
						'other' => q(mk {0}),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(makuna),
						'one' => q(mk {0}),
						'other' => q(mk {0}),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(solar radii),
						'one' => q(R☉ {0}),
						'other' => q(R☉ {0}),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(solar radii),
						'one' => q(R☉ {0}),
						'other' => q(R☉ {0}),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yaduka),
						'one' => q(yd {0}),
						'other' => q(yd {0}),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yaduka),
						'one' => q(yd {0}),
						'other' => q(yd {0}),
					},
					# Long Unit Identifier
					'light-candela' => {
						'one' => q(cd {0}),
						'other' => q(cd {0}),
					},
					# Core Unit Identifier
					'candela' => {
						'one' => q(cd {0}),
						'other' => q(cd {0}),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
						'one' => q(lx {0}),
						'other' => q(lx {0}),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
						'one' => q(lx {0}),
						'other' => q(lx {0}),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(solar luminosities),
						'one' => q(L☉ {0}),
						'other' => q(L☉ {0}),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(solar luminosities),
						'one' => q(L☉ {0}),
						'other' => q(L☉ {0}),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(carats),
						'one' => q(CD {0}),
						'other' => q(CD {0}),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(carats),
						'one' => q(CD {0}),
						'other' => q(CD {0}),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(daltons),
						'one' => q(Da {0}),
						'other' => q(daltons {0}),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(daltons),
						'one' => q(Da {0}),
						'other' => q(daltons {0}),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(Earth masses),
						'one' => q(M⊕ {0}),
						'other' => q(M⊕ {0}),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Earth masses),
						'one' => q(M⊕ {0}),
						'other' => q(M⊕ {0}),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(ƙwaya),
						'one' => q(ƙwaya {0}),
						'other' => q(ƙwaya {0}),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(ƙwaya),
						'one' => q(ƙwaya {0}),
						'other' => q(ƙwaya {0}),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(giram),
						'one' => q(g {0}),
						'other' => q(g {0}),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(giram),
						'one' => q(g {0}),
						'other' => q(g {0}),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q(kg {0}),
						'other' => q(kg {0}),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q(kg {0}),
						'other' => q(kg {0}),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'one' => q(μg {0}),
						'other' => q(μg {0}),
					},
					# Core Unit Identifier
					'microgram' => {
						'one' => q(μg {0}),
						'other' => q(μg {0}),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'one' => q(mg {0}),
						'other' => q(mg {0}),
					},
					# Core Unit Identifier
					'milligram' => {
						'one' => q(mg {0}),
						'other' => q(mg {0}),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q(oz {0}),
						'other' => q(oz {0}),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q(oz {0}),
						'other' => q(oz {0}),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(ozar troy),
						'one' => q(oz t {0}),
						'other' => q(oz t {0}),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(ozar troy),
						'one' => q(oz t {0}),
						'other' => q(oz t {0}),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(laba-laba),
						'one' => q(lb {0}),
						'other' => q(lb {0}),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(laba-laba),
						'one' => q(lb {0}),
						'other' => q(lb {0}),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(solar masses),
						'one' => q(M☉ {0}),
						'other' => q(M☉ {0}),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(solar masses),
						'one' => q(M☉ {0}),
						'other' => q(M☉ {0}),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stones),
						'one' => q(st {0}),
						'other' => q(st {0}),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stones),
						'one' => q(st {0}),
						'other' => q(st {0}),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tan-tan),
						'one' => q(tn {0}),
						'other' => q(tn {0}),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tan-tan),
						'one' => q(tn {0}),
						'other' => q(tn {0}),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'one' => q(t {0}),
						'other' => q(t {0}),
					},
					# Core Unit Identifier
					'tonne' => {
						'one' => q(t {0}),
						'other' => q(t {0}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'one' => q(GW {0}),
						'other' => q(GW {0}),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'one' => q(GW {0}),
						'other' => q(GW {0}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(ƙi),
						'one' => q(ƙi {0}),
						'other' => q(ƙi {0}),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(ƙi),
						'one' => q(ƙi {0}),
						'other' => q(ƙi {0}),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q(kW {0}),
						'other' => q(kW {0}),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q(kW {0}),
						'other' => q(kW {0}),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'one' => q(MW {0}),
						'other' => q(MW {0}),
					},
					# Core Unit Identifier
					'megawatt' => {
						'one' => q(MW {0}),
						'other' => q(MW {0}),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'one' => q(mW {0}),
						'other' => q(mW {0}),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'one' => q(mW {0}),
						'other' => q(mW {0}),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(wat-wat),
						'one' => q(W {0}),
						'other' => q(W {0}),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(wat-wat),
						'one' => q(W {0}),
						'other' => q(W {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(yny),
						'one' => q(yny {0}),
						'other' => q(yny {0}),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(yny),
						'one' => q(yny {0}),
						'other' => q(yny {0}),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(sanda),
						'one' => q(sanda {0}),
						'other' => q(sanda {0}),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(sanda),
						'one' => q(sanda {0}),
						'other' => q(sanda {0}),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q(hPa {0}),
						'other' => q(hPa {0}),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q(hPa {0}),
						'other' => q(hPa {0}),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q(inHg {0}),
						'other' => q(inHg {0}),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q(inHg {0}),
						'other' => q(inHg {0}),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'one' => q(kPa {0}),
						'other' => q(kPa {0}),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'one' => q(kPa {0}),
						'other' => q(kPa {0}),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'one' => q(MPa {0}),
						'other' => q(MPa {0}),
					},
					# Core Unit Identifier
					'megapascal' => {
						'one' => q(MPa {0}),
						'other' => q(MPa {0}),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q(mbar {0}),
						'other' => q(mbar {0}),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q(mbar {0}),
						'other' => q(mbar {0}),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q(mmHg {0}),
						'other' => q(mmHg {0}),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q(mmHg {0}),
						'other' => q(mmHg {0}),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'one' => q(Pa {0}),
						'other' => q(Pa {0}),
					},
					# Core Unit Identifier
					'pascal' => {
						'one' => q(Pa {0}),
						'other' => q(Pa {0}),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'one' => q(psi {0}),
						'other' => q(psi {0}),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'one' => q(psi {0}),
						'other' => q(psi {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/saʼa),
						'one' => q(km/s {0}),
						'other' => q(km/s {0}),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/saʼa),
						'one' => q(km/s {0}),
						'other' => q(km/s {0}),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'one' => q(kn {0}),
						'other' => q(kn {0}),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q(kn {0}),
						'other' => q(kn {0}),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(mitoci/daƙ),
						'one' => q(m/s {0}),
						'other' => q(m/s {0}),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(mitoci/daƙ),
						'one' => q(m/s {0}),
						'other' => q(m/s {0}),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mil-mil/saʼa),
						'one' => q(mas {0}),
						'other' => q(mas {0}),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mil-mil/saʼa),
						'one' => q(mas {0}),
						'other' => q(mas {0}),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(dig. S),
						'one' => q(°S{0}),
						'other' => q(°S{0}),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(dig. S),
						'one' => q(°S{0}),
						'other' => q(°S{0}),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(dig. F),
						'one' => q(F°{0}),
						'other' => q(F°{0}),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(dig. F),
						'one' => q(F°{0}),
						'other' => q(F°{0}),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'one' => q(°{0}),
						'other' => q(°{0}),
					},
					# Core Unit Identifier
					'generic' => {
						'one' => q(°{0}),
						'other' => q(°{0}),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'one' => q(K {0}),
						'other' => q(K {0}),
					},
					# Core Unit Identifier
					'kelvin' => {
						'one' => q(K {0}),
						'other' => q(K {0}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'one' => q(N⋅m {0}),
						'other' => q(N⋅m {0}),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'one' => q(N⋅m {0}),
						'other' => q(N⋅m {0}),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'one' => q(lbf⋅ft {0}),
						'other' => q(lbf⋅ft {0}),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q(lbf⋅ft {0}),
						'other' => q(lbf⋅ft {0}),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(eka ƙf),
						'one' => q(ek ƙf {0}),
						'other' => q(ek ƙf {0}),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(eka ƙf),
						'one' => q(ek ƙf {0}),
						'other' => q(ek ƙf {0}),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q(gang {0}),
						'other' => q(gang {0}),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q(gang {0}),
						'other' => q(gang {0}),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushels),
						'one' => q(bu {0}),
						'other' => q(bu {0}),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushels),
						'one' => q(bu {0}),
						'other' => q(bu {0}),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'one' => q(sL {0}),
						'other' => q(sL {0}),
					},
					# Core Unit Identifier
					'centiliter' => {
						'one' => q(sL {0}),
						'other' => q(sL {0}),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'one' => q(cm³ {0}),
						'other' => q(cm³ {0}),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q(cm³ {0}),
						'other' => q(cm³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ƙafafu³),
						'one' => q(ƙf³ {0}),
						'other' => q(ƙf³ {0}),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ƙafafu³),
						'one' => q(ƙf³ {0}),
						'other' => q(ƙf³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(incina³),
						'one' => q(in³ {0}),
						'other' => q(in³ {0}),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(incina³),
						'one' => q(in³ {0}),
						'other' => q(in³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q(km³ {0}),
						'other' => q(km³ {0}),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q(km³ {0}),
						'other' => q(km³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'one' => q(m³ {0}),
						'other' => q(m³ {0}),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'one' => q(m³ {0}),
						'other' => q(m³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q(mi³ {0}),
						'other' => q(mi³ {0}),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q(mi³ {0}),
						'other' => q(mi³ {0}),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yaduka³),
						'one' => q(yd³ {0}),
						'other' => q(yd³ {0}),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yaduka³),
						'one' => q(yd³ {0}),
						'other' => q(yd³ {0}),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(kofuna),
						'one' => q(k {0}),
						'other' => q(k {0}),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(kofuna),
						'one' => q(k {0}),
						'other' => q(k {0}),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q(mc {0}),
						'other' => q(mc {0}),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q(mc {0}),
						'other' => q(mc {0}),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'one' => q(dL {0}),
						'other' => q(dL {0}),
					},
					# Core Unit Identifier
					'deciliter' => {
						'one' => q(dL {0}),
						'other' => q(dL {0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'one' => q(dstspn {0}),
						'other' => q(dstspn {0}),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'one' => q(dstspn {0}),
						'other' => q(dstspn {0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q(dstspn Imp {0}),
						'other' => q(dstspn Imp {0}),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q(dstspn Imp {0}),
						'other' => q(dstspn Imp {0}),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'one' => q(dram fl {0}),
						'other' => q(dram fl {0}),
					},
					# Core Unit Identifier
					'dram' => {
						'one' => q(dram fl {0}),
						'other' => q(dram fl {0}),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(ɗigo),
						'one' => q(ɗigo {0}),
						'other' => q(ɗigo {0}),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(ɗigo),
						'one' => q(ɗigo {0}),
						'other' => q(ɗigo {0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q(fl oz {0}),
						'other' => q(fl oz {0}),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q(fl oz {0}),
						'other' => q(fl oz {0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q(fl oz Imp. {0}),
						'other' => q(fl oz Imp. {0}),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q(fl oz Imp. {0}),
						'other' => q(fl oz Imp. {0}),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'one' => q(gal {0}),
						'other' => q(gal {0}),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'one' => q(gal {0}),
						'other' => q(gal {0}),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'one' => q(gal Imp. {0}),
						'other' => q(gal Imp.{0}),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q(gal Imp. {0}),
						'other' => q(gal Imp.{0}),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'one' => q(hL {0}),
						'other' => q(hL {0}),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'one' => q(hL {0}),
						'other' => q(hL {0}),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'one' => q(jigger {0}),
						'other' => q(jigger {0}),
					},
					# Core Unit Identifier
					'jigger' => {
						'one' => q(jigger {0}),
						'other' => q(jigger {0}),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litoci),
						'one' => q(L {0}),
						'other' => q(L {0}),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litoci),
						'one' => q(L {0}),
						'other' => q(L {0}),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'one' => q(ML {0}),
						'other' => q(ML {0}),
					},
					# Core Unit Identifier
					'megaliter' => {
						'one' => q(ML {0}),
						'other' => q(ML {0}),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'one' => q(mL {0}),
						'other' => q(mL {0}),
					},
					# Core Unit Identifier
					'milliliter' => {
						'one' => q(mL {0}),
						'other' => q(mL {0}),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'one' => q(pinch {0}),
						'other' => q(pinch {0}),
					},
					# Core Unit Identifier
					'pinch' => {
						'one' => q(pinch {0}),
						'other' => q(pinch {0}),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pints),
						'one' => q(pt {0}),
						'other' => q(pt {0}),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pints),
						'one' => q(pt {0}),
						'other' => q(pt {0}),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'one' => q(mpt {0}),
						'other' => q(mpt {0}),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'one' => q(mpt {0}),
						'other' => q(mpt {0}),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qts),
						'one' => q(qt {0}),
						'other' => q(qt {0}),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qts),
						'one' => q(qt {0}),
						'other' => q(qt {0}),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q(qt Imp. {0}),
						'other' => q(qt Imp. {0}),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q(qt Imp. {0}),
						'other' => q(qt Imp. {0}),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(bckl),
						'one' => q(bckl {0}),
						'other' => q(bckl {0}),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(bckl),
						'one' => q(bckl {0}),
						'other' => q(bckl {0}),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(ƙmc),
						'one' => q(ƙmc {0}),
						'other' => q({0} tsp),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(ƙmc),
						'one' => q(ƙmc {0}),
						'other' => q({0} tsp),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:i|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:aʼa|a|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, da {1}),
				2 => q({0} da {1}),
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
					'one' => 'Dubu 0',
					'other' => 'Dubu 0',
				},
				'10000' => {
					'one' => 'Dubu 00',
					'other' => 'Dubu 00',
				},
				'100000' => {
					'one' => 'Dubu 000',
					'other' => 'Dubu 000',
				},
				'1000000' => {
					'one' => 'Miliyan 0',
					'other' => 'Miliyan 0',
				},
				'10000000' => {
					'one' => 'Miliyan 00',
					'other' => 'Miliyan 00',
				},
				'100000000' => {
					'one' => 'Miliyan 000',
					'other' => 'Miliyan 000',
				},
				'1000000000' => {
					'one' => 'Biliyan 0',
					'other' => 'Biliyan 0',
				},
				'10000000000' => {
					'one' => 'Biliyan 00',
					'other' => 'Biliyan 00',
				},
				'100000000000' => {
					'one' => 'Biliyan 000',
					'other' => 'Biliyan 000',
				},
				'1000000000000' => {
					'one' => 'Triliyan 0',
					'other' => 'Triliyan 0',
				},
				'10000000000000' => {
					'one' => 'Triliyan 00',
					'other' => 'Triliyan 00',
				},
				'100000000000000' => {
					'one' => 'Triliyan 000',
					'other' => 'Triliyan 000',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0D',
					'other' => '0D',
				},
				'10000' => {
					'one' => '00D',
					'other' => '00D',
				},
				'100000' => {
					'one' => '000D',
					'other' => '000D',
				},
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

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AED' => {
			display_name => {
				'currency' => q(Kuɗin Haɗaɗɗiyar Daular Larabawa),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani na ƙasar Afghanistan),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Kuɗin Albania),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Kuɗin Armenia),
				'one' => q(kuɗin Armenia),
				'other' => q(Kuɗin Armenia),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Antillean Guilder na ƙasar Netherlands),
				'one' => q(Antillean guilder na ƙasar Netherlands),
				'other' => q(Antillean Guilder na ƙasar Netherlands),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kuɗin Angola),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso na ƙasar Argentina),
				'one' => q(peso na ƙasar Argentina),
				'other' => q(Peso na ƙasar Argentina),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dalar Ostareliya),
				'one' => q(Dalolin Ostareliya),
				'other' => q(Dalolin Ostareliya),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Florin na yankin Aruba),
				'one' => q(florin na yankin Aruba),
				'other' => q(Florin na yankin Aruba),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Kuɗin Azerbaijani),
				'one' => q(kuɗin Azerbaijani),
				'other' => q(Kuɗin Azerbaijani),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Kuɗaɗen Bosnia da Herzegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dalar ƙasar Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka na ƙasar Bangladesh),
				'one' => q(taka na ƙasar Bangladesh),
				'other' => q(Taka na ƙasar Bangladesh),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Kuɗin Bulgeria),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Kuɗin Baharan),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Kuɗin Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dalar ƙasar Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dalar Brunei),
				'one' => q(Dalolin Brunei),
				'other' => q(Dalolin Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boloviano na ƙasar Bolivia),
				'one' => q(boliviano na ƙasar Bolivia),
				'other' => q(Boloviano na ƙasar Bolivia),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Ril Kudin Birazil),
				'one' => q(Ril Kuɗin Birazil),
				'other' => q(Ril Kuɗin Birazil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dalar ƙasar Bahamas),
				'one' => q(dalar ƙasar Bahamas),
				'other' => q(Dalar ƙasar Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum na ƙasar Bhutan),
				'one' => q(ngultrum na ƙasar Bhutan),
				'other' => q(Ngultrum na ƙasar Bhutan),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Kuɗin Baswana),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Kuɗin Belarus),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dalar ƙasar Belize),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dalar Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Kuɗin Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Kuɗin Suwizalan),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Peso na ƙasar Chile),
				'one' => q(peso na ƙasar Chile),
				'other' => q(Peso na ƙasar Chile),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuwan na ƙasar Sin \(na wajen ƙasa\)),
				'one' => q(yuwan na ƙasar Sin \(na wajen ƙasa\)),
				'other' => q(yuwan na ƙasar Sin \(na wajen ƙasa\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuwan na ƙasar Sin),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Peso na ƙasar Columbia),
				'one' => q(peso na ƙasar Columbia),
				'other' => q(Peso na ƙasar Columbia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colón na ƙasar Costa Rica),
				'one' => q(colón na ƙasar Costa Rica),
				'other' => q(colón na ƙasar Costa Rica),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Peso mai fuska biyu na ƙasar Kuba),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso na ƙasar Kuba),
				'one' => q(peso na ƙasar Cuba),
				'other' => q(Peso na ƙasar Kuba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kuɗin Tsibiran Kap Barde),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Kuɗin Czech),
				'one' => q(kuɗin Czech),
				'other' => q(Kuɗin Czech),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Kuɗin Jibuti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Krone na ƙasar Denmark),
				'one' => q(krone na ƙasar Denmark),
				'other' => q(Krone na ƙasar Denmark),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Peso na jamhuriyar Dominica),
				'one' => q(peso na jamhuriyar Dominica),
				'other' => q(Peso na jamhuriyar Dominica),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Kuɗin Aljeriya),
				'one' => q(Dinarin Aljeriya),
				'other' => q(Dinarin Aljeriya),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Fam kin Masar),
				'one' => q(Fam na Masar),
				'other' => q(Fam na Masar),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Kuɗin Eritireya),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Kuɗin Habasha),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yuro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dalar Fiji),
				'one' => q(Dalolin Fiji),
				'other' => q(Dalolin Fiji),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Fam na ƙasar Tsibirai na Falkland),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Fam na Ingila),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Kuɗin Georgia),
				'one' => q(kuɗin Georgia),
				'other' => q(Kuɗin Georgia),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Cedi),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Sidi na Ghana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Kuɗin Gibraltal),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Kuɗin Gambiya),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Kuɗin Guinea),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Kuɗin Gini),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal na ƙasar Guatemala),
				'one' => q(quetzal na ƙasar Guatemala),
				'other' => q(Quetzal na ƙasar Guatemala),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dalar Guyana),
				'one' => q(dalar Guyana),
				'other' => q(Dalar Guyana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dalar Hong Kong),
				'one' => q(dalar Hong Kong),
				'other' => q(Dalar Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira na ƙasar Honduras),
				'one' => q(lempira na ƙasar Honduras),
				'other' => q(Lempira na ƙasar Honduras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuɗin Croatia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde na ƙasar Haiti),
				'one' => q(gourde na ƙasar Haiti),
				'other' => q(Gourde na ƙasar Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Kuɗin Hungary),
				'one' => q(kuɗin Hungary),
				'other' => q(Kuɗin Hungary),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupiah na ƙasar Indonesia),
				'one' => q(rupiah na ƙasar Indonesia),
				'other' => q(Rupiah na ƙasar Indonesia),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Sabbin Kuɗin Israʼila),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Kuɗin Indiya),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinarin Iraqi),
				'one' => q(dinarin Iraqi),
				'other' => q(Dinarin Iraqi),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Riyal na ƙasar Iran),
				'one' => q(Riyal-riyal na ƙasar Iran),
				'other' => q(Riyal-riyal na ƙasar Iran),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Króna na ƙasar Iceland),
				'one' => q(króna na ƙasar Iceland),
				'other' => q(Króna na ƙasar Iceland),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dalar Jamaica),
				'one' => q(dalar Jamaica),
				'other' => q(Dalar Jamaica),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinarin Jordan),
				'one' => q(dinarin Jordan),
				'other' => q(Dinarin Jordan),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Yen na ƙasar Japan),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Sulen Kenya),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som na ƙasar Kyrgystani),
				'one' => q(som na ƙasar Kyrgystani),
				'other' => q(Som na ƙasar Kyrgystani),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel na ƙasar Cambodia),
				'one' => q(riel na ƙasar Cambodia),
				'other' => q(Riel na ƙasar Cambodia),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Kuɗin Kwamoras),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won na ƙasar Koriya ta Arewa),
				'one' => q(won na ƙasar Koriya ta Arewa),
				'other' => q(won na ƙasar Koriya ta Arewa),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won na Koriya ta Kudu),
				'one' => q(won na Koriya ta Kudu),
				'other' => q(won na Koriya ta Kudu),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinarin Kuwaiti),
				'one' => q(dinarin Kuwaiti),
				'other' => q(Dinarin Kuwaiti),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dalar ƙasar Tsibirai na Cayman),
				'one' => q(dalar ƙasar Tsibirai na Cayman),
				'other' => q(Dalar ƙasar Tsibirai na Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge na ƙasar Kazkhstan),
				'one' => q(tenge na ƙasar Kazakhstan),
				'other' => q(Tenge na ƙasar Kazkhstan),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kuɗin Laos),
				'one' => q(kuɗin Laos),
				'other' => q(Kuɗin Laos),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Kuɗin Lebanon),
				'one' => q(kuɗin Lebanon),
				'other' => q(Kuɗin Lebanon),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rupee na ƙasar Sri Lanka),
				'one' => q(rupee na ƙasar Sri Lanka),
				'other' => q(Rupee na ƙasar Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dalar Laberiya),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Kuɗin Lesoto),
				'one' => q(Kuɗaɗen Lesoto),
				'other' => q(Kuɗaɗen Lesoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Kuɗin Libiya),
				'one' => q(Dinarin Libiya),
				'other' => q(Dinarin Libiya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Kuɗin Maroko),
				'one' => q(Dirhamin Maroko),
				'other' => q(Dirhamomin Maroko),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Kuɗaɗen Moldova),
				'one' => q(Kuɗaɗen Moldova),
				'other' => q(kuɗaɗen Moldova),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Kuɗin Madagaskar),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Dinarin Macedonia),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kuɗin Myanmar),
				'one' => q(kuɗin Myanmar),
				'other' => q(Kuɗin Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik na Mongolia),
				'one' => q(tugrik na Mongoliya),
				'other' => q(Tugrik na Mongolia),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca na ƙasar Macao),
				'one' => q(pataca na ƙasar Macao),
				'other' => q(Pataca na ƙasar Macao),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Kuɗin Moritaniya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Kuɗin Moritaniya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Kuɗin Moritus),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa na ɓasar Maldives),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kuɗin Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Peso na ƙasar Mekziko),
				'one' => q(peso na ƙasar Mekziko),
				'other' => q(peso na ƙasar Mekziko),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Kuɗin Malaysia),
				'one' => q(kuɗin Malaysia),
				'other' => q(Kuɗin Malaysia),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Kuɗin Mozambik),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metical na ƙasar Mozambique),
				'one' => q(metical na ƙasar Mozambique),
				'other' => q(Metical na ƙasar Mozambique),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dalar Namibiya),
			},
		},
		'NGN' => {
			symbol => '₦',
			display_name => {
				'currency' => q(Nairar Najeriya),
				'one' => q(Nairar Nijeriya),
				'other' => q(Nairorin Najeriya),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Córdoba na ƙasar Nicaragua),
				'one' => q(córdoba na ƙasar Nicaragua),
				'other' => q(Córdoba na ƙasar Nicaragua),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Krone na ƙasar Norway),
				'one' => q(krone na ƙasar Norway),
				'other' => q(Krone na ƙasar Norway),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupee na Nepal),
				'one' => q(rupee na Nepal),
				'other' => q(Rupee na Nepal),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dalar New Zealand),
				'one' => q(Dalolin New Zealand),
				'other' => q(Dalolin New Zealand),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Riyal ɗin Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa na ƙasar Panama),
				'one' => q(balboa na ƙasar Panama),
				'other' => q(Balboa na ƙasar Panama),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sol na ƙasar Peru),
				'one' => q(sol na ƙasar Peru),
				'other' => q(Sol na ƙasar Peru),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina na ƙasar Papua Sabon Guinea),
				'one' => q(kina na ƙasar Papua Sabon Guinea),
				'other' => q(Kina na ƙasar Papua Sabon Guinea),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Kuɗin Philippine),
				'one' => q(kuɗin Philippine),
				'other' => q(Kuɗin Philippine),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupee na ƙasar Pakistan),
				'one' => q(rupee na ƙasar Pakistan),
				'other' => q(Rupee na ƙasar Pakistan),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Kuɗin Polan),
				'one' => q(kuɗin Polan),
				'other' => q(kuɗaɗen Polan),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guarani na ƙasar Paraguay),
				'one' => q(guarani na ƙasar Paraguay),
				'other' => q(Guarani na ƙasar Paraguay),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Riyal ɗin Qatar),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Kuɗin Romania),
				'one' => q(kuɗin Romania),
				'other' => q(Kuɗin Romania),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinarin Serbia),
				'one' => q(dinarin Serbia),
				'other' => q(Dinarin Serbia),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Ruble na ƙasar Rasha),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Kuɗin Ruwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal),
				'one' => q(Riyal ɗin Saudiyya),
				'other' => q(Riyal),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dalar Tsibirai na Solomon),
				'one' => q(Dalolin Tsibirai na Solomon),
				'other' => q(Dalolin Tsibirai na Solomon),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Kuɗin Saishal),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Fam na Sudan),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Krona na ƙasar Sweden),
				'one' => q(krona na ƙasar Sweden),
				'other' => q(Krona na ƙasar Sweden),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dalar Singapore),
				'one' => q(Dalolin Singapore),
				'other' => q(Dalolin Singapore),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Fam kin San Helena),
				'one' => q(Fam na San Helena),
				'other' => q(fam na San Helena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Kuɗin Salewo),
				'one' => q(Kuɗin Saliyo),
				'other' => q(Kuɗin Saliyo),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Kuɗin Salewo \(1964—2022\)),
				'one' => q(Kuɗin Saliyo \(1964—2022\)),
				'other' => q(Kuɗin Saliyo \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Sulen Somaliya),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dalar ƙasar Suriname),
				'one' => q(dalar ƙasar Suriname),
				'other' => q(Dalar ƙasar Suriname),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Fam na Kudancin Sudan),
				'one' => q(fam na Kudancin Sudan),
				'other' => q(Fam na Kudancin Sudan),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Kuɗin Sawo Tome da Paransip \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Kuɗin Sawo Tome da Paransip),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Kuɗin Siriya),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Kuɗin Lilangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Baht na ƙasar Thailand),
				'one' => q(baht na ƙasar Thailand),
				'other' => q(Baht na ƙasar Thailand),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni na ƙasar Tajikistan),
				'one' => q(somoni na ƙasar Tajikistan),
				'other' => q(Somoni na ƙasar Tajikistan),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat na ƙasar Turkmenistan),
				'one' => q(manat na ƙasar Turkmenistan),
				'other' => q(Manat na ƙasar Turkmenistan),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Kuɗin Tunisiya),
				'one' => q(Dinarin Tunusiya),
				'other' => q(Dinarin Tunusiya),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Paʻanga na ƙasar Tonga),
				'one' => q(paʻanga na ƙasar Tonga),
				'other' => q(Paʻanga na ƙasar Tonga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Kuɗin Turkiyya),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dalar ƙasar Trinidad da Tobago),
				'one' => q(dalar ƙasar Trinidad da Tobago),
				'other' => q(Dalar ƙasar Trinidad da Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Sabuwar Dalar Taiwan),
				'one' => q(Sabuwar dalar Taiwan),
				'other' => q(Sabuwar Dalar Taiwan),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Sulen Tanzaniya),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Kudin Ukrainian),
				'one' => q(kuɗin Ukrain),
				'other' => q(Kuɗin Ukrain),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Sule Yuganda),
				'one' => q(Sulallan Yuganda),
				'other' => q(Sulallan Yuganda),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Dalar Amurka),
				'one' => q(Dalar Amirka),
				'other' => q(Dalar Amurka),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Peso na ƙasar Uruguay),
				'one' => q(peso na ƙasar Uruguay),
				'other' => q(Peso na ƙasar Uruguay),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Som na ƙasar Uzbekistan),
				'one' => q(som na ƙasar Uzbekistan),
				'other' => q(Som na ƙasar Uzbekistan),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bolívar na ƙasar Venezuela),
				'one' => q(bolívar na ƙasar Venezuela),
				'other' => q(Bolívar na ƙasar Venezuela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Kuɗin Vietnam),
				'one' => q(kuɗin Vietnam),
				'other' => q(Kuɗin Vietnam),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu da ƙasar Vanuatu),
				'one' => q(vatu na ƙasar Vanuatu),
				'other' => q(Vatu da ƙasar Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala na ƙasar Samoa),
				'one' => q(tala na ƙasar Samoa),
				'other' => q(Tala na ƙasar Samoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Kuɗin Sefa na Afirka Ta Tsakiya),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dalar Gabashin Karebiyan),
				'one' => q(dalar Gabashin Karebiyan),
				'other' => q(dalar Gabashin Karebiyan),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Kuɗin Sefa na Afirka Ta Yamma),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Kuɗin CFP franc),
				'one' => q(kuɗin CFP franc),
				'other' => q(Kuɗin CFP franc),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Kudin da ba a sani ba),
				'one' => q(\(kuɗin sashe da ba a sani ba\)),
				'other' => q(\(Kudin da ba a sani ba\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Riyal ɗin Yemen),
				'one' => q(riyal ɗin Yemen),
				'other' => q(Riyal ɗin Yemen),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Kuɗin Afirka Ta Kudu),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kuɗin Zambiya \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kuɗin Zambiya),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dalar zimbabuwe),
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
							'Fab',
							'Mar',
							'Afi',
							'May',
							'Yun',
							'Yul',
							'Agu',
							'Sat',
							'Okt',
							'Nuw',
							'Dis'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Janairu',
							'Faburairu',
							'Maris',
							'Afirilu',
							'Mayu',
							'Yuni',
							'Yuli',
							'Agusta',
							'Satumba',
							'Oktoba',
							'Nuwamba',
							'Disamba'
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
							'Y',
							'Y',
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
					wide => {
						nonleap => [
							'Muharram',
							'Safar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Jumada I',
							'Jumada II',
							'Rajab',
							'Shaʼaban',
							'Ramadan',
							'Shawwal',
							'Dhuʻl-Qiʻdah',
							'Dhuʻl-Hijjah'
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
						mon => 'Lit',
						tue => 'Tal',
						wed => 'Lar',
						thu => 'Alh',
						fri => 'Jum',
						sat => 'Asa',
						sun => 'Lah'
					},
					short => {
						mon => 'Li',
						tue => 'Ta',
						wed => 'Lr',
						thu => 'Al',
						fri => 'Ju',
						sat => 'As',
						sun => 'Lh'
					},
					wide => {
						mon => 'Litinin',
						tue => 'Talata',
						wed => 'Laraba',
						thu => 'Alhamis',
						fri => 'Jummaʼa',
						sat => 'Asabar',
						sun => 'Lahadi'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'T',
						wed => 'L',
						thu => 'A',
						fri => 'J',
						sat => 'A',
						sun => 'L'
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
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					wide => {0 => 'Kwata na ɗaya',
						1 => 'Kwata na biyu',
						2 => 'Kwata na uku',
						3 => 'Kwata na huɗu'
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
					'am' => q{SF},
					'pm' => q{YM},
				},
				'wide' => {
					'am' => q{Safiya},
					'pm' => q{Yamma},
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
				'0' => 'K.H',
				'1' => 'BHAI'
			},
			wide => {
				'0' => 'Kafin haihuwar annab',
				'1' => 'Bayan haihuwar annab'
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
			'full' => q{EEEE, d MMMM, y G},
			'long' => q{d MMMM, y G},
			'medium' => q{d MMM, y G},
			'short' => q{d/M/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM, y},
			'long' => q{d MMMM, y},
			'medium' => q{d MMM, y},
			'short' => q{d/M/yy},
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
			'full' => q{{0}, {1}},
			'long' => q{{0}, {1}},
			'medium' => q{{0}, {1}},
			'short' => q{{0}, {1}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1}, {0}},
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
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			Md => q{M/d},
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
			Ed => q{E, d},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			MMMMW => q{'satin' W 'cikin' MMMM},
			Md => q{M/d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM, y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'sati' w 'cikin' Y},
		},
		'islamic' => {
			Ed => q{d E},
			Gy => q{y G},
			GyMMM => q{G MMM y},
			GyMMMEd => q{G d MMM y, E},
			GyMMMd => q{G d MMM y},
			GyMd => q{GGGGG dd-MM-y},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			yM => q{yM},
			yMEd => q{E, d M y},
			yMMM => q{y MMM},
			yMMMEd => q{E, d MMM, y},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
			yyyy => q{y G},
			yyyyM => q{y/M GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{y G MMM},
			yyyyMMMEd => q{y G d MMM, E},
			yyyyMMMM => q{y G MMMM},
			yyyyMMMd => q{y G d MMM},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{y G QQQ},
			yyyyQQQQ => q{y G QQQQ},
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
			MEd => {
				d => q{E, dd/M – E, dd/M},
			},
			h => {
				a => q{h a – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				y => q{y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				y => q{y MMM d – y MMM d},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} Lokaci),
		regionFormat => q({0} Lokacin Rana),
		regionFormat => q({0} Daidaitaccen Lokaci),
		'Afghanistan' => {
			long => {
				'standard' => q#Lokacin Afghanistan#,
			},
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Lokacin Afirka ta Tsakiya#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Lokacin Gabashin Afirka#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#South Africa Standard Time#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Lokacin Bazara na Afirka ta Yamma#,
				'generic' => q#Lokacin Afirka ta Yamma#,
				'standard' => q#Tsayayyen Lokacin Afirka ta Yamma#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Lokacin Rana na Alaska#,
				'generic' => q#Lokacin Alaska#,
				'standard' => q#Tsayayyen Lokacin Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Lokacin Bazara na Amazon#,
				'generic' => q#Lokacin Amazon#,
				'standard' => q#Tsayayyen Lokacin Amazon#,
			},
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Arewacin Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Arewacin Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Arewacin Dakota#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Lokacin Rana dake Arewacin Amurika ta Tsakiya#,
				'generic' => q#Lokaci dake Amurika arewa ta tsakiyar#,
				'standard' => q#Tsayayyen Lokaci dake Arewacin Amurika ta Tsakiya#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Lokacin Rana ta Gabas dake Arewacin Amurika#,
				'generic' => q#Lokacin Gabas dake Arewacin Amurikaa#,
				'standard' => q#Tsayayyen Lokacin Gabas dake Arewacin Amurika#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Lokacin Rana na Tsaunin Arewacin Amurka#,
				'generic' => q#Lokacin Tsauni na Arewacin Amurka#,
				'standard' => q#Lokaci tsayayye na tsauni a Arewacin Amurica#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Lokacin Rana na Arewacin Amurka#,
				'generic' => q#Lokacin Arewacin Amurika#,
				'standard' => q#Lokaci Tsayayye na Arewacin Amurika#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Lokacin Rana na Apia#,
				'generic' => q#Lokacin Apia#,
				'standard' => q#Tsayayyen Lokacin Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Lokacin Rana na Arebiya#,
				'generic' => q#Lokacin Arebiya#,
				'standard' => q#Arabian Standard Time#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Lokacin Bazara na Argentina#,
				'generic' => q#Lokacin Argentina#,
				'standard' => q#Tsayayyen Lokacin Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Lokacin Bazara na Yammacin Argentina#,
				'generic' => q#Lokacin Yammacin Argentina#,
				'standard' => q#Tsayayyen Lokacin Yammacin Argentina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Lokacin Bazara na Armenia#,
				'generic' => q#Lokacin Armenia#,
				'standard' => q#Tsayayyen Lokacin Armenia#,
			},
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Lokacin Rana na Kanada, Puerto Rico da Virgin Islands#,
				'generic' => q#Lokacin Kanada, Puerto Rico da Virgin Islands#,
				'standard' => q#Tsayayyen Lokacin Kanada, Puerto Rico da Virgin Islands#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Lokacin Rana na Tsakiyar Austiraliya#,
				'generic' => q#Central Australia Time#,
				'standard' => q#Tsayayyen Lokacin Tsakiyar Austiraliya#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Lokacin Rana na Yammacin Tsakiyar Austiraliya#,
				'generic' => q#Lokacin Yammacin Tsakiyar Austiraliya#,
				'standard' => q#Tsayayyen Lokacin Yammacin Tsakiyar Austiraliya#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Lokacin Rana na Gabashin Austiraliya#,
				'generic' => q#Lokacin Gabashin Austiraliya#,
				'standard' => q#Australian Eastern Standard Time#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Lokacin Rana na Yammacin Austiralia#,
				'generic' => q#Lokacin Yammacin Austiralia#,
				'standard' => q#Tsayayyen Lokacin Yammacin Austiralia#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Lokacin Bazara na Azerbaijan#,
				'generic' => q#Lokacin Azerbaijan#,
				'standard' => q#Tsayayyen Lokacin Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Lokacin Azure na Bazara#,
				'generic' => q#Lokacin Azores#,
				'standard' => q#Lokacin Azores Daidaitacce#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Lokacin Bazara na Bangladesh#,
				'generic' => q#Lokacin Bangladesh#,
				'standard' => q#Tsayayyen Lokacin Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutan Time#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Lokacin Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Lokacin Bazara na Brasillia#,
				'generic' => q#Lokacin Brasillia#,
				'standard' => q#Tsayayyen Lokacin Brasillia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Lokacin Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Lokacin Bazara na Cape Verde#,
				'generic' => q#Lokacin Cape Verde#,
				'standard' => q#Cape Verde Standard Time#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Tsayayyen Lokacin Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Lokacin Rana na Chatham#,
				'generic' => q#Lokacin Chatham#,
				'standard' => q#Tsayayyen Lokacin Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Lokacin Bazara na Chile#,
				'generic' => q#Lokacin Chile#,
				'standard' => q#Tsayayyen Lokacin Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Lokacin Rana na Sin#,
				'generic' => q#Lokacin Sin#,
				'standard' => q#Tsayayyen Lokacin Sin#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Lokacin Bazara na Choibalsan#,
				'generic' => q#Lokacin Choibalsan#,
				'standard' => q#Tsayayyen Lokacin Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Lokacin Christmas Island#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Lokacin Cocos Islands#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Lokacin Bazara na Colombia#,
				'generic' => q#Lokacin Colombia#,
				'standard' => q#Tsayayyen Lokacin Colombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Rabin Lokacin Bazara na Cook Islands#,
				'generic' => q#Lokacin Cook Islands#,
				'standard' => q#Tsayayyen Lokacin Cook Islands#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Lokacin Rana na Kuba#,
				'generic' => q#Lokaci na Kuba#,
				'standard' => q#Tsayayyen Lokacin Kuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Lokacin Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Lokacin Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Lokacin East Timor#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Lokacin Bazara na Easter Island#,
				'generic' => q#Lokacin Easter Island#,
				'standard' => q#Tsayayyen Lokacin Easter Island#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Lokacin Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Hadewa Lokaci na Duniya#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Birni da ba a sani ba#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Tsayayyen Lokacin Irish#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Lokacin Bazara na Birtaniya#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Tsakiyar bazara a lokaci turai#,
				'generic' => q#Tsakiyar a lokaci turai#,
				'standard' => q#Ida Tsakiyar a Lokaci Turai#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Gabas a lokaci turai da bazara#,
				'generic' => q#Lokaci a turai gabas#,
				'standard' => q#Ida lokaci a turai gabas#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Lokacin Gabashin Turai mai Nisa#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Ida lokaci ta yammacin turai da bazara#,
				'generic' => q#Lokaci ta yammacin turai#,
				'standard' => q#Ida lokaci ta yammacin turai#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Lokacin Bazara na Falkland Islands#,
				'generic' => q#Lokacin Falkland Islands#,
				'standard' => q#Tsayayyen Lokacin Falkland Islands#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Lokacin Bazara na Fiji#,
				'generic' => q#Lokacin Fiji#,
				'standard' => q#Tsayayyen Lokacin Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Lokacin French Guiana#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Lokacin Kudancin Faransa da Antarctic#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Lokacin Greenwhich a London#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Lokacin Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Lokacin Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgia Summer Time#,
				'generic' => q#Lokacin Georgia#,
				'standard' => q#Tsayayyen Lokacin Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Lokacin Gilbert Islands#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Lokacin Rana na Gabashin Greenland#,
				'generic' => q#Lokacin Gabas na Greenland#,
				'standard' => q#Tsayayyen Lokacin Gabashin Greenland#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Lokacin Rana na Yammacin Greenland#,
				'generic' => q#Lokacin Yammacin Greenland#,
				'standard' => q#Tsayayyen Lokacin Yammacin Greenland#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Lokacin Golf#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Lokacin Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Lokacin Rana na Hawaii-Aleutian#,
				'generic' => q#Lokaci na Hawaii-Aleutian#,
				'standard' => q#Tsayayyen Lokacin Hawaii-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Lokacin Bazara na Hong Kong#,
				'generic' => q#Lokacin Hong Kong#,
				'standard' => q#Tsayayyen Lokacin Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Lokacin Bazara na Hovd#,
				'generic' => q#Lokacin Hovd#,
				'standard' => q#Tsayayyen Lokacin Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#India Standard Time#,
			},
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Lokacin Tekun Indiya#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Lokacin Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Lokacin Indonesia ta Tsakiya#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Eastern Indonesia Time#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Lokacin Yammacin Indonesia#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Lokacin Rana na Iran#,
				'generic' => q#Lokacin Iran#,
				'standard' => q#Tsayayyen Lokacin Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Lokacin Bazara na Irkutsk#,
				'generic' => q#Lokacin Irkutsk#,
				'standard' => q#Tsayayyen Lokacin Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israel Daylight Time#,
				'generic' => q#Lokacin Israʼila#,
				'standard' => q#Israel Standard Time#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japan Daylight Time#,
				'generic' => q#Lokacin Japan#,
				'standard' => q#Japan Standard Time#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Lokacin Gabashin Kazakhstan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Lokacin Yammacin Kazakhstan#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Lokacin Rana na Koriya#,
				'generic' => q#Lokacin Koriya#,
				'standard' => q#Tsayayyen Lokacin Koriya#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Lokacin Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Lokacin Bazara na Krasnoyarsk#,
				'generic' => q#Lokacin Krasnoyarsk#,
				'standard' => q#Tsayayyen Lokacin Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Lokacin Kazakhstan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Lokacin Line Islands#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lokacin Rana na Vote Lord Howe#,
				'generic' => q#Lokacin Lord Howe#,
				'standard' => q#Tsayayyen Lokacin Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Lokacin Macquarie Island#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Lokacin Bazara na Magadan#,
				'generic' => q#Lokacin Magadan#,
				'standard' => q#Tsayayyen Lokacin Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Lokacin Malaysia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Lokacin Maldives#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Lokacin Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Lokacin Marshall Islands#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Lokacin Bazara na Mauritius#,
				'generic' => q#Lokacin Mauritius#,
				'standard' => q#Tsayayyen Lokacin Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Lokacin Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Lokacin Rana na Arewa Maso Yammacin Mekziko#,
				'generic' => q#Lokacin Arewa Maso Yammacin Mekziko#,
				'standard' => q#Tsayayyen Lokacin Arewa Maso Yammacin Mekziko#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Lokacin Rana na Mekziko Pacific#,
				'generic' => q#Lokacin Mekziko Pacific#,
				'standard' => q#Tsayayyen Lokacin Mekziko Pacific#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Lokacin Bazara na Ulaanbaatar#,
				'generic' => q#Lokacin Ulaanbaatar#,
				'standard' => q#Tsayayyen Lokacin Ulaanbaatar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Lokacin Bazara na Moscow#,
				'generic' => q#Lokacin Moscow#,
				'standard' => q#Tsayayyen Lokacin Moscow#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Lokacin Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Lokacin Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Lokacin Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Lokacin Bazara na New Caledonia#,
				'generic' => q#Lokacin New Caledonia#,
				'standard' => q#Tsayayyen Lokacin New Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Lokacin Rana na New Zealand#,
				'generic' => q#Lokacin New Zealand#,
				'standard' => q#Tsayayyen Lokacin New Zealand#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Lokaci rana ta Newfoundland#,
				'generic' => q#Lokacin Newfoundland#,
				'standard' => q#Lokaci Tsayayye ta Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Lokacin Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Lokacin Rana na Norfolk Island#,
				'generic' => q#Lokacin Norfolk Island#,
				'standard' => q#Tsayayyen Lokacin Norfolk Island#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Lokacin Bazara na Fernando de Noronha#,
				'generic' => q#Lokacin Fernando de Noronha#,
				'standard' => q#Tsayayyen Lokacin Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Lokacin Bazara na Novosibirsk#,
				'generic' => q#Lokacin Novosibirsk#,
				'standard' => q#Novosibirsk Standard Time#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Lokacin Bazara na Omsk#,
				'generic' => q#Lokacin Omsk#,
				'standard' => q#Tsayayyen Lokacin Omsk#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Lokacin Bazara na Pakistan#,
				'generic' => q#Lokacin Pakistan#,
				'standard' => q#Tsayayyen Lokacin Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Lokacin Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Lokacin Papua New Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Lokacin Bazara na Paraguay#,
				'generic' => q#Lokacin Paraguay#,
				'standard' => q#Tsayayyen Lokacin Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Lokacin Bazara na Peru#,
				'generic' => q#Lokacin Peru#,
				'standard' => q#Tsayayyen Lokacin Peru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Lokacin Bazara na Philippine#,
				'generic' => q#Lokacin Philippine#,
				'standard' => q#Tsayayyen Lokacin Philippine#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Lokacin Phoenix Islands#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Lokacin Rana na St. Pierre da Miquelon#,
				'generic' => q#Lokacin St. Pierre da Miquelon#,
				'standard' => q#Tsayayyen Lokacin St. Pierre da Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Lokacin Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Lokacin Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Lokacin Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Lokacin Réunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Lokacin Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Lokacin Bazara na Sakhalin#,
				'generic' => q#Lokacin Sakhalin#,
				'standard' => q#Tsayayyen Lokacin Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Lokacin Rana na Vote Samoa#,
				'generic' => q#Lokacin Samoa#,
				'standard' => q#Tsayayyen Lokacin Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Lokacin Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Tsayayyen Lokacin Singapore#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Lokacin Rana na Solomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Lokacin Kudancin Georgia#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Lokacin Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Lokacin Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Lokacin Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Lokacin Rana na Taipei#,
				'generic' => q#Lokacin Taipei#,
				'standard' => q#Tsayayyen Lokacin Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Lokacin Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau Time#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Lokacin Bazara na Tonga#,
				'generic' => q#Lokacin Tonga#,
				'standard' => q#Tsayayyen Lokacin Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Lokacin Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistan Summer Time#,
				'generic' => q#Lokacin Turkmenistan#,
				'standard' => q#Tsayayyen Lokacin Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Lokacin Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Lokacin Bazara na Uruguay#,
				'generic' => q#Lokacin Uruguay#,
				'standard' => q#Tsayayyen Lokacin Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Lokacin Bazara na Uzbekistan#,
				'generic' => q#Lokacin Uzbekistan#,
				'standard' => q#Tsayayyen Lokacin Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Lokacin Bazara na Vanuatu#,
				'generic' => q#Lokacin Vanuatu#,
				'standard' => q#Tsayayyen Lokacin Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Lokacin Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Lokacin Bazara na Vladivostok#,
				'generic' => q#Lokacin Vladivostok#,
				'standard' => q#Tsayayyen Lokacin Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Lokacin Bazara na Volgograd#,
				'generic' => q#Lokacin Volgograd#,
				'standard' => q#Tsayayyen Lokacin Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Lokacin Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Lokacin Wake Island#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Lokacin Wallis da Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Lokacin Bazara na Yakutsk#,
				'generic' => q#Lokacin Yakutsk#,
				'standard' => q#Tsayayyen Lokacin Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Lokacin Bazara na Yekaterinburg#,
				'generic' => q#Lokacin Yekaterinburg#,
				'standard' => q#Tsayayyen Lokacin Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Lokacin Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
