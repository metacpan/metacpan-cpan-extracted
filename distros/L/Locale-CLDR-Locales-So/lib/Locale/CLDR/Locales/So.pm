=encoding utf8

=head1 NAME

Locale::CLDR::Locales::So - Package for language Somali

=cut

package Locale::CLDR::Locales::So;
# This file auto generated from Data\common\main\so.xml
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
				'ab' => 'U dhashay Abkhazia',
 				'ace' => 'Shiinays',
 				'ada' => 'Adangme',
 				'ady' => 'U dhashay Ady',
 				'af' => 'Afrikaanka',
 				'agq' => 'Ageem',
 				'ain' => 'U dhashay Ain',
 				'ak' => 'Akan',
 				'ale' => 'U dhashay Ale',
 				'alt' => 'Southern Altai',
 				'am' => 'Axmaar',
 				'an' => 'U dhashay Aragon',
 				'ann' => 'Obolo',
 				'anp' => 'U dhashay Anp',
 				'ar' => 'Carabi',
 				'ar_001' => 'Carabiga rasmiga ah',
 				'arn' => 'Mapuche',
 				'arp' => 'U dhashay Arap',
 				'ars' => 'Najdi Arabic',
 				'as' => 'Asaamiis',
 				'asa' => 'Asu',
 				'ast' => 'Astuuriyaan',
 				'atj' => 'Atikamekw',
 				'av' => 'U dhashay Avar',
 				'awa' => 'Awa',
 				'ay' => 'U dhashay Aymar',
 				'az' => 'Asarbayjan',
 				'az@alt=short' => 'Aseeri',
 				'ba' => 'Bashkir',
 				'ban' => 'U dhashay Baline',
 				'bas' => 'Basaa',
 				'be' => 'Beleruusiyaan',
 				'bem' => 'Bemba',
 				'bez' => 'Bena',
 				'bg' => 'Bulgeeriyaan',
 				'bgc' => 'Haryanvi',
 				'bho' => 'U dhashay Bhohp',
 				'bi' => 'U dhashay Bislam',
 				'bin' => 'U dhashay Bin',
 				'bla' => 'Siksiká',
 				'bm' => 'Bambaara',
 				'bn' => 'Bangladesh',
 				'bo' => 'Tibeetaan',
 				'br' => 'Biriton',
 				'brx' => 'Bodo',
 				'bs' => 'Bosniyaan',
 				'bug' => 'U dhashay Bugin',
 				'byn' => 'U dhashay Byn',
 				'ca' => 'Katalaan',
 				'cay' => 'Cayuga',
 				'ccp' => 'Jakma',
 				'ce' => 'Jejen',
 				'ceb' => 'Sebuano',
 				'cgg' => 'Jiga',
 				'ch' => 'Chamorro',
 				'chk' => 'Chuukese',
 				'chm' => 'Mari',
 				'cho' => 'Choctaw',
 				'chp' => 'Chipewyan',
 				'chr' => 'Jerookee',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Bartamaha Kurdish',
 				'ckb@alt=variant' => 'Kurdi, Sorani',
 				'clc' => 'Chilcotin',
 				'co' => 'Korsikan',
 				'crg' => 'Michif',
 				'crj' => 'Southern East Cree',
 				'crk' => 'Plains Cree',
 				'crl' => 'Northern East Cree',
 				'crm' => 'Moose Cree',
 				'crr' => 'Carolina Algonquian',
 				'cs' => 'Jeeg',
 				'csw' => 'Swampy Cree',
 				'cu' => 'Kaniisadda Islaafik',
 				'cv' => 'Chuvash',
 				'cy' => 'Welsh',
 				'da' => 'Dhaanish',
 				'dak' => 'Dakota',
 				'dar' => 'Dargwa',
 				'dav' => 'Taiita',
 				'de' => 'Jarmal',
 				'de_AT' => 'Jarmal Awsteeriya',
 				'de_CH' => 'Iswiiska Sare ee Jarmal',
 				'dgr' => 'Dogrib',
 				'dje' => 'Sarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Soorbiyaanka Hoose',
 				'dua' => 'Duaala',
 				'dv' => 'Divehi',
 				'dyo' => 'Joola-Foonyi',
 				'dz' => 'D’zongqa',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Eewe',
 				'efi' => 'Efik',
 				'eka' => 'Ekajuk',
 				'el' => 'Giriik',
 				'en' => 'Ingiriisi',
 				'en_AU' => 'Ingiriis Austaraaliyaan',
 				'en_CA' => 'Ingiriis Kanadiyaan',
 				'en_GB' => 'Ingiriis Biritish',
 				'en_GB@alt=short' => 'Ingiriiska Boqortooyada Midooday',
 				'en_US' => 'Ingiriis Maraykan',
 				'en_US@alt=short' => 'Ingiriiska Maraykanka',
 				'eo' => 'Isberaanto',
 				'es' => 'Isbaanish',
 				'es_419' => 'Isbaanishka Laatiin Ameerika',
 				'es_ES' => 'Isbaanish (Isbayn)',
 				'es_MX' => 'Isbaanishka Mexico',
 				'et' => 'Istooniyaan',
 				'eu' => 'Basquu',
 				'ewo' => 'Eewondho',
 				'fa' => 'Faarisi',
 				'fa_AF' => 'Faarsi',
 				'ff' => 'Fuulah',
 				'fi' => 'Finishka',
 				'fil' => 'Filibiino',
 				'fj' => 'Fijian',
 				'fo' => 'Farowsi',
 				'fon' => 'Fon',
 				'fr' => 'Faransiis',
 				'fr_CA' => 'Faransiiska Kanada',
 				'fr_CH' => 'Faransiis (Iswiiserlaand)',
 				'frc' => 'Faransiiska Cajun',
 				'frr' => 'Northern Frisian',
 				'fur' => 'Firiyuuliyaan',
 				'fy' => 'Firiisiyan Galbeed',
 				'ga' => 'Ayrish',
 				'gaa' => 'Ga',
 				'gd' => 'Iskot Giilik',
 				'gez' => 'Geez',
 				'gil' => 'Gilbertese',
 				'gl' => 'Galiisiyaan',
 				'gn' => 'Guarani',
 				'gor' => 'Gorontalo',
 				'gsw' => 'Jarmal Iswiis',
 				'gu' => 'Gujaraati',
 				'guz' => 'Guusii',
 				'gv' => 'Mankis',
 				'gwi' => 'Gwichʼin',
 				'ha' => 'Hawsa',
 				'hai' => 'Haida',
 				'haw' => 'Hawaay',
 				'hax' => 'Southern Haida',
 				'he' => 'Cibraani',
 				'hi' => 'Hindi',
 				'hi_Latn' => 'Hindi (Latin)',
 				'hi_Latn@alt=variant' => 'Hinglish',
 				'hil' => 'Hiligaynon',
 				'hmn' => 'Hamong',
 				'hr' => 'Koro’eeshiyaan',
 				'hsb' => 'Sorobiyaanka Sare',
 				'ht' => 'Heeytiyaan Karawle',
 				'hu' => 'Hangariyaan',
 				'hup' => 'Hupa',
 				'hur' => 'Halkomelem',
 				'hy' => 'Armeeniyaan',
 				'hz' => 'Herero',
 				'ia' => 'Interlinguwa',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Indunusiyaan',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Sijuwan Yi',
 				'ikt' => 'Western Canadian Inuktitut',
 				'ilo' => 'Iloko',
 				'inh' => 'Ingush',
 				'io' => 'Ido',
 				'is' => 'Ayslandays',
 				'it' => 'Talyaani',
 				'iu' => 'Inuktitut',
 				'ja' => 'Jabaaniis',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ingoomba',
 				'jmc' => 'Chaga',
 				'jv' => 'Jafaaniis',
 				'ka' => 'Joorijiyaan',
 				'kab' => 'Kabayle',
 				'kac' => 'Kachin',
 				'kaj' => 'Jju',
 				'kam' => 'Kaamba',
 				'kbd' => 'U dhashay Kabardia',
 				'kcg' => 'Tyap',
 				'kde' => 'Kimakonde',
 				'kea' => 'Kabuferdiyanu',
 				'kfo' => 'Koro',
 				'kgp' => 'Kaingang',
 				'kha' => 'Khasi',
 				'khq' => 'Koyra Jiini',
 				'ki' => 'Kikuuyu',
 				'kj' => 'Kuanyama',
 				'kk' => 'Kasaaq',
 				'kkj' => 'Kaako',
 				'kl' => 'Kalaallisuut',
 				'kln' => 'Kalenjin',
 				'km' => 'Kamboodhian',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannadays',
 				'ko' => 'Kuuriyaan',
 				'kok' => 'Konkani',
 				'kpe' => 'Kpelle',
 				'kr' => 'Kanuri',
 				'krc' => 'Karachay-Balkar',
 				'krl' => 'Karelian',
 				'kru' => 'Kurukh',
 				'ks' => 'Kaashmiir',
 				'ksb' => 'Shambaala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Kologniyaan',
 				'ku' => 'Kurdishka',
 				'kum' => 'Kumyk',
 				'kv' => 'Komi',
 				'kw' => 'Kornish',
 				'kwk' => 'Kwakʼwala',
 				'ky' => 'Kirgiis',
 				'la' => 'Laatiin',
 				'lad' => 'Ladino',
 				'lag' => 'Laangi',
 				'lb' => 'Luksaamboorgish',
 				'lez' => 'Lezghian',
 				'lg' => 'Gandha',
 				'li' => 'Limburgish',
 				'lil' => 'Lillooet',
 				'lkt' => 'Laakoota',
 				'ln' => 'Lingala',
 				'lo' => 'Lao',
 				'lou' => 'Louisiana Creole',
 				'loz' => 'Lozi',
 				'lrc' => 'Luri Waqooyi',
 				'lsm' => 'Saamia',
 				'lt' => 'Lituwaanays',
 				'lu' => 'Luuba-kataanga',
 				'lua' => 'Luba-Lulua',
 				'lun' => 'Lunda',
 				'luo' => 'Luwada',
 				'lus' => 'Mizo',
 				'luy' => 'Luyia',
 				'lv' => 'Laatfiyaan',
 				'mad' => 'Madurese',
 				'mag' => 'Magahi',
 				'mai' => 'Dadka Maithili',
 				'mak' => 'Makasar',
 				'mas' => 'Masaay',
 				'mdf' => 'Moksha',
 				'men' => 'Mende',
 				'mer' => 'Meeru',
 				'mfe' => 'Moorisayn',
 				'mg' => 'Malagaasi',
 				'mgh' => 'Makhuwa',
 				'mgo' => 'Meetaa',
 				'mh' => 'Marshallese',
 				'mi' => 'Maaoori',
 				'mic' => 'Mi\'kmaq',
 				'min' => 'Minangkabau',
 				'mk' => 'Masadooniyaan',
 				'ml' => 'Malayalam',
 				'mn' => 'Mangooli',
 				'mni' => 'Maniburi',
 				'moe' => 'Innu-aimun',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Maarati',
 				'ms' => 'Malaay',
 				'mt' => 'Maltiis',
 				'mua' => 'Miyundhaang',
 				'mul' => 'Luuqado kala duwan',
 				'mus' => 'Muscogee',
 				'mwl' => 'Mirandese',
 				'my' => 'Burmese',
 				'myv' => 'Erzya',
 				'mzn' => 'Masanderaani',
 				'na' => 'Nauru',
 				'nap' => 'Neapolitan',
 				'naq' => 'Nama',
 				'nb' => 'Nawrijii Bokmål',
 				'nd' => 'Indhebeele Waqooyi',
 				'nds' => 'Jarmal Hooseeya',
 				'ne' => 'Nebaali',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Niuean',
 				'nl' => 'Holandays',
 				'nl_BE' => 'Af faleemi',
 				'nmg' => 'Kuwaasiyo',
 				'nn' => 'Nawriijiga Nynorsk',
 				'nnh' => 'Ingiyembuun',
 				'no' => 'Nawriiji',
 				'nog' => 'Nogai',
 				'nqo' => 'N’Ko',
 				'nr' => 'South Ndebele',
 				'nso' => 'Northern Sotho',
 				'nus' => 'Nuweer',
 				'nv' => 'Navajo',
 				'ny' => 'Inyaanja',
 				'nyn' => 'Inyankoole',
 				'oc' => 'Occitan',
 				'ojb' => 'Northwestern Ojibwa',
 				'ojc' => 'Central Ojibwa',
 				'ojs' => 'Oji-Cree',
 				'ojw' => 'Western Ojibwa',
 				'oka' => 'Okanagan',
 				'om' => 'Oromo',
 				'or' => 'Oodhiya',
 				'os' => 'Oseetic',
 				'pa' => 'Bunjaabi',
 				'pag' => 'Pangasinan',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiamento',
 				'pau' => 'Palauan',
 				'pcm' => 'Bidjinka Nayjeeriya',
 				'pis' => 'Pijin',
 				'pl' => 'Boolish',
 				'pqm' => 'Maliseet-Passamaquoddy',
 				'prg' => 'Brashiyaanki Hore',
 				'ps' => 'Bashtuu',
 				'pt' => 'Boortaqiis',
 				'pt_BR' => 'Boortaqiiska Baraasiil',
 				'pt_PT' => 'Boortaqiis (Boortuqaal)',
 				'qu' => 'Quwejuwa',
 				'raj' => 'Rajasthani',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotongan',
 				'rhg' => 'Rohingya',
 				'rm' => 'Romaanis',
 				'rn' => 'Rundhi',
 				'ro' => 'Romanka',
 				'rof' => 'Rombo',
 				'ru' => 'Ruush',
 				'rup' => 'U dhashay Aromania',
 				'rw' => 'Ruwaandha',
 				'rwk' => 'Raawa',
 				'sa' => 'Sanskrit',
 				'sad' => 'Sandawe',
 				'sah' => 'Saaqa',
 				'saq' => 'Sambuuru',
 				'sat' => 'Santali',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardinian',
 				'scn' => 'Sicilian',
 				'sco' => 'Scots',
 				'sd' => 'Siindhi',
 				'se' => 'Sami Waqooyi',
 				'seh' => 'Seena',
 				'ses' => 'Koyraboro Seenni',
 				'sg' => 'Sango',
 				'sh' => 'Serbiyaan',
 				'shi' => 'Shilha',
 				'shn' => 'Shan',
 				'si' => 'Sinhaleys',
 				'sk' => 'Isloofaak',
 				'sl' => 'Islofeeniyaan',
 				'slh' => 'Southern Lushootseed',
 				'sm' => 'Samowan',
 				'smn' => 'Inaari Saami',
 				'sms' => 'Skolt Sami',
 				'sn' => 'Shoona',
 				'snk' => 'Soninke',
 				'so' => 'Soomaali',
 				'sq' => 'Albeeniyaan',
 				'sr' => 'Seerbiyaan',
 				'srn' => 'Sranan Tongo',
 				'ss' => 'Swati',
 				'st' => 'Sesooto',
 				'str' => 'Straits Salish',
 				'su' => 'Suudaaniis',
 				'suk' => 'Sukuma',
 				'sv' => 'Iswiidhish',
 				'sw' => 'Sawaaxili',
 				'swb' => 'Comorian',
 				'syr' => 'Syria',
 				'ta' => 'Tamiil',
 				'tce' => 'Southern Tutchone',
 				'te' => 'Teluugu',
 				'tem' => 'Timne',
 				'teo' => 'Teeso',
 				'tet' => 'Tetum',
 				'tg' => 'Taajik',
 				'tgx' => 'Tagish',
 				'th' => 'Taaylandays',
 				'tht' => 'Tahltan',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tk' => 'Turkumaanish',
 				'tlh' => 'Klingon',
 				'tli' => 'Tlingit',
 				'tn' => 'Tswana',
 				'to' => 'Toongan',
 				'tok' => 'Toki Pona',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Turkish',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tt' => 'Taatar',
 				'ttm' => 'Northern Tutchone',
 				'tum' => 'Tumbuka',
 				'tvl' => 'Tuvalu',
 				'tw' => 'Tiwiyan',
 				'twq' => 'Tasaawaq',
 				'ty' => 'Tahitian',
 				'tyv' => 'Tuvinia',
 				'tzm' => 'Bartamaha Atlaas Tamasayt',
 				'udm' => 'Udmurt',
 				'ug' => 'Uighur',
 				'uk' => 'Yukreeniyaan',
 				'umb' => 'Umbundu',
 				'und' => 'Af aan la aqoon ama aan sax ahayn',
 				'ur' => 'Urduu',
 				'uz' => 'Usbakis',
 				'vai' => 'Faayi',
 				've' => 'Venda',
 				'vi' => 'Fiitnaamays',
 				'vo' => 'Folabuuk',
 				'vun' => 'Fuunjo',
 				'wa' => 'Walloon',
 				'wae' => 'Walseer',
 				'wal' => 'Wolaytta',
 				'war' => 'Waray',
 				'wo' => 'Woolof',
 				'wuu' => 'Wu Chinese',
 				'xal' => 'Kalmyk',
 				'xh' => 'Hoosta',
 				'xog' => 'Sooga',
 				'yav' => 'Yaangbeen',
 				'ybb' => 'Yemba',
 				'yi' => 'Yadhish',
 				'yo' => 'Yoruuba',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Kantoneese',
 				'yue@alt=menu' => 'Shiinays, Cantonese',
 				'zgh' => 'Morokaanka Tamasayt Rasmiga',
 				'zh' => 'Shiinaha Mandarin',
 				'zh_Hans' => 'Shiinaha Rasmiga ah',
 				'zh_Hant' => 'Shiinahii Hore',
 				'zu' => 'Zuulu',
 				'zun' => 'Zuni',
 				'zxx' => 'Luuqad Looma Hayo',
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
 			'Aghb' => 'Qoraalka Luuqada Caucasian Albanian',
 			'Ahom' => 'Dadka Ahom',
 			'Arab' => 'Carabi',
 			'Aran' => 'Farta Luuqada Faarsiga',
 			'Armi' => 'Luuqada Imperial Aramaic',
 			'Armn' => 'Armeeniyaan',
 			'Avst' => 'Luuqada Avestan',
 			'Bali' => 'Baliniis',
 			'Bamu' => 'Bamum',
 			'Bass' => 'Qoraalka Vah',
 			'Batk' => 'Batak',
 			'Beng' => 'Baangla',
 			'Bhks' => 'Qoraalka Bhaiksuki',
 			'Bopo' => 'Bobomofo',
 			'Brah' => 'Dhirta Brahmi',
 			'Brai' => 'Qoraalka Indhoolaha',
 			'Bugi' => 'Luuqada Buginiiska',
 			'Buhd' => 'Luuqada Buhid',
 			'Cakm' => 'Jakma',
 			'Cans' => 'Qoraalka Luuqada Aborajiinka ee Kanada',
 			'Cari' => 'Luuqada kaariyaanka',
 			'Cham' => 'Jam',
 			'Cher' => 'Jerokee',
 			'Chrs' => 'Luuqada Korasmiyaanka',
 			'Copt' => 'Dadka Kotiga',
 			'Cprt' => 'sibraas dhalad ah',
 			'Cyrl' => 'Siriylik',
 			'Deva' => 'Dhefangaari',
 			'Diak' => 'Luuqadaha Dives Akuru',
 			'Dogr' => 'Dadka Dogra',
 			'Dsrt' => 'Gobalka Deseret',
 			'Dupl' => 'Qoraalka Duployan shorthand',
 			'Egyp' => 'Fartii hore ee Masaarida',
 			'Elba' => 'Magaalada Elbasan',
 			'Elym' => 'Qoraalka Elymaic',
 			'Ethi' => 'Itoobiya',
 			'Geor' => 'Joorjiya',
 			'Glag' => 'Qoraalka Glagolitic',
 			'Gong' => 'Gumjala Gondi',
 			'Gonm' => 'Qoraalka Masaram Gondi',
 			'Goth' => 'Dadka Gothic',
 			'Gran' => 'Qoraalka Grantha',
 			'Grek' => 'Giriik',
 			'Gujr' => 'Gujaraati',
 			'Guru' => 'Luuqada gujarati',
 			'Hanb' => 'Han iyo Bobomofo',
 			'Hang' => 'Hanguul',
 			'Hani' => 'Han',
 			'Hano' => 'Qoraalka Hanunoo',
 			'Hans' => 'La fududeeyay',
 			'Hans@alt=stand-alone' => 'Haan La fududeeyay',
 			'Hant' => 'Hore',
 			'Hant@alt=stand-alone' => 'Haanti hore',
 			'Hatr' => 'Qoraalka Hatran',
 			'Hebr' => 'Cibraani',
 			'Hira' => 'Hiragana',
 			'Hluw' => 'Qoraalka Anatolian Hieroglyphs',
 			'Hmng' => 'Hmonga pahawh',
 			'Hmnp' => 'Hmonga Nyiakeng Puachue',
 			'Hrkt' => 'Qoraalka Xuruufta Jabaaniiska',
 			'Hung' => 'Hangariyaankii Hore',
 			'Ital' => 'Itaaliggii Hore',
 			'Jamo' => 'Jaamo',
 			'Java' => 'Jafaniis',
 			'Jpan' => 'Jabaaniis',
 			'Kali' => 'Kayah LI',
 			'Kana' => 'Katakaana',
 			'Khar' => 'Koraalka kharooshi',
 			'Khmr' => 'Khamer',
 			'Khoj' => 'Qoraalka Khojki',
 			'Kits' => 'Qoraalka yar ee Khitan',
 			'Knda' => 'Kanada',
 			'Kore' => 'Kuuriyaan',
 			'Kthi' => 'kaithi',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Dalka Lao',
 			'Latn' => 'Laatiin',
 			'Lepc' => 'Lebja',
 			'Limb' => 'Limbu',
 			'Lina' => 'Nidaamka qoraalka Linear A',
 			'Linb' => 'Nidaamka qoraalka Linear B',
 			'Lisu' => 'Wabiga Fraser',
 			'Lyci' => 'Lyciantii Hore',
 			'Lydi' => 'Lydian',
 			'Mahj' => 'Mahajani',
 			'Maka' => 'Makasar',
 			'Mand' => 'Luuqada Mandaean',
 			'Mani' => 'Manichaean',
 			'Marc' => 'Marchen',
 			'Medf' => 'Madefaidrin',
 			'Mend' => 'Mende',
 			'Merc' => 'Meroitic Curve',
 			'Mero' => 'Meroitic',
 			'Mlym' => 'Maalayalam',
 			'Modi' => 'Moodi',
 			'Mong' => 'Mongooliyaan',
 			'Mroo' => 'Mro',
 			'Mtei' => 'Qoraalka Luuqada Meitei',
 			'Mult' => 'Multani',
 			'Mymr' => 'Mayanmaar',
 			'Nand' => 'Nandinagari',
 			'Narb' => 'Carabiyadii Hore ee Wuqooye',
 			'Nbat' => 'Nabataean',
 			'Newa' => 'Newa',
 			'Nkoo' => 'N’Ko',
 			'Nshu' => 'Nüshu',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Ol Jiki',
 			'Orkh' => 'Orkhon',
 			'Orya' => 'Oodhiya',
 			'Osge' => 'Osage',
 			'Osma' => 'Osmanya',
 			'Palm' => 'Palmyrene',
 			'Pauc' => 'Baaw Sin Haaw',
 			'Perm' => 'Permic gii hore',
 			'Phag' => 'Qoraalka Phags-pa',
 			'Phli' => 'Qoraaladii hore ee Pahlavi',
 			'Phlp' => 'Qoraalka midig laga bilaabo ee faarsiyiintii',
 			'Phnx' => 'Luuqada Phoenicianka',
 			'Plrd' => 'Shibanaha',
 			'Prti' => 'Qoraalka Parthian',
 			'Qaag' => 'Qoraalka Sawgiga',
 			'Rjng' => 'Dadka Rejan',
 			'Rohg' => 'Hanifi Rohingya',
 			'Runr' => 'Dadka Rejang',
 			'Samr' => 'Dadka Samaritan',
 			'Sarb' => 'Crabiyaankii Hore ee Wuqooyi',
 			'Saur' => 'Sawrashtra',
 			'Sgnw' => 'Qaabka dhagoolka loola hadlo',
 			'Shaw' => 'calaamad qoris',
 			'Shrd' => 'Sharada',
 			'Sidd' => 'Siddham',
 			'Sind' => 'khudwadi',
 			'Sinh' => 'Sinhaala',
 			'Sogd' => 'Sogdiyaan',
 			'Sogo' => 'Sogdiyaankii Hore',
 			'Sora' => 'Qoraalka Sora Sompeng',
 			'Soyo' => 'Soyombo',
 			'Sund' => 'Dadka Sundaniiska',
 			'Sylo' => 'Qoraalka Luuqada Sylheti',
 			'Syrc' => 'Lahjada Syriac',
 			'Tagb' => 'Tagbanwa',
 			'Takr' => 'Takri',
 			'Tale' => 'Tai Le',
 			'Talu' => 'Tai Lue cusub',
 			'Taml' => 'Taamiil',
 			'Tang' => 'Luuqada Tangut',
 			'Tavt' => 'Farta lagu Qoro Luuqadaha Tai',
 			'Telu' => 'Teeluguu',
 			'Tfng' => 'Farta Tifinagh',
 			'Tglg' => 'Luuqada Tagalog',
 			'Thaa' => 'Daana',
 			'Thai' => 'Taay',
 			'Tibt' => 'Tibetaan',
 			'Tirh' => 'Qoraalka Luuqada Maithili',
 			'Ugar' => 'Luuqada Ugaritic',
 			'Vaii' => 'Dadka Vai',
 			'Wara' => 'Nidaamka Qoraalka Luuqada Ho',
 			'Wcho' => 'Dadka wanjo',
 			'Xpeo' => 'Faarsigii Hore',
 			'Xsux' => 'Qoraalkii Hore ee dadka Sumaariyiinta ee dhulka mesobataamiya',
 			'Yezi' => 'Dadka Yesiidiga',
 			'Yiii' => 'Tiknoolajiyada Yi',
 			'Zanb' => 'Xarafka laba jibaaran ee kujira Xarfaha Zanabazar',
 			'Zinh' => 'Dhaxlay',
 			'Zmth' => 'Aqoonsiga Xisaabta',
 			'Zsye' => 'Calaamad Dareen Muujin',
 			'Zsym' => 'Calaamado',
 			'Zxxx' => 'Aan la qorin',
 			'Zyyy' => 'Caadi ahaan',
 			'Zzzz' => 'Far aan la aqoon amase aan saxnayn',

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
			'001' => 'Dunida',
 			'002' => 'Afrika',
 			'003' => 'Waqooyi Ameerika',
 			'005' => 'Koonfur Ameerika',
 			'009' => 'Osheeniya',
 			'011' => 'Galbeeka Afrika',
 			'013' => 'Bartamaha Ameerika',
 			'014' => 'Afrikada Bari',
 			'015' => 'Waqooyiga Afrika',
 			'017' => 'Afrikada Dhexe',
 			'018' => 'Afrikada Koonfureed',
 			'019' => 'Ameerikaas',
 			'021' => 'Waqooyiga Ameerika',
 			'029' => 'Karibiyaan',
 			'030' => 'Aasiyada Bari',
 			'034' => 'Aasiyada Koonfureed',
 			'035' => 'Aasiyada Koonfur-galbeed',
 			'039' => 'Yurubta Koonfureed',
 			'053' => 'Austraalaasiya',
 			'054' => 'Melaneesiya',
 			'057' => 'Gobolka Aasiyada yar',
 			'061' => 'Booliyneesiya',
 			'142' => 'Aasiya',
 			'143' => 'Bartamaha Aasiya',
 			'145' => 'Aasiyada Galbeed',
 			'150' => 'Yurub',
 			'151' => 'Yurubta Bari',
 			'154' => 'Yurubta Waqooyi',
 			'155' => 'Yurubta Galbeed',
 			'202' => 'Afrikada ka hooseysa Saxaraha',
 			'419' => 'Laatiin Ameerika',
 			'AC' => 'Jasiiradda Asensiyoon',
 			'AD' => 'Andora',
 			'AE' => 'Midawga Imaaraatka Carabta',
 			'AF' => 'Afgaanistaan',
 			'AG' => 'Antigua & Barbuuda',
 			'AI' => 'Anguula',
 			'AL' => 'Albaaniya',
 			'AM' => 'Armeeniya',
 			'AO' => 'Angoola',
 			'AQ' => 'Antaarktika',
 			'AR' => 'Arjentiina',
 			'AS' => 'Samowa Ameerika',
 			'AT' => 'Awsteriya',
 			'AU' => 'Awstaraaliya',
 			'AW' => 'Aruba',
 			'AX' => 'Jasiiradda Aland',
 			'AZ' => 'Asarbajan',
 			'BA' => 'Boosniya & Harsegofina',
 			'BB' => 'Baarbadoos',
 			'BD' => 'Bangaladhesh',
 			'BE' => 'Biljam',
 			'BF' => 'Burkiina Faaso',
 			'BG' => 'Bulgaariya',
 			'BH' => 'Baxreyn',
 			'BI' => 'Burundi',
 			'BJ' => 'Biniin',
 			'BL' => 'St. Baathelemiy',
 			'BM' => 'Barmuuda',
 			'BN' => 'Buruneey',
 			'BO' => 'Boliifiya',
 			'BQ' => 'Karibiyaan Nadarlands',
 			'BR' => 'Baraasiil',
 			'BS' => 'Bahaamas',
 			'BT' => 'Buutan',
 			'BV' => 'Buufet Island',
 			'BW' => 'Botuswaana',
 			'BY' => 'Belarus',
 			'BZ' => 'Beliis',
 			'CA' => 'Kanada',
 			'CC' => 'Jasiiradda Kookoos',
 			'CD' => 'Jamhuuriyadda Dimuquraadiga Kongo',
 			'CD@alt=variant' => 'Jamhuuriyadda Dimuqaadiga Kongo',
 			'CF' => 'Jamhuuriyadda Afrikada Dhexe',
 			'CG' => 'Kongo',
 			'CG@alt=variant' => 'Jamhuuriyadda Kongo',
 			'CH' => 'Swiiserlaand',
 			'CI' => 'Ayfori Koost',
 			'CK' => 'Jasiiradda Kook',
 			'CL' => 'Jili',
 			'CM' => 'Kaameruun',
 			'CN' => 'Shiinaha',
 			'CO' => 'Koloombiya',
 			'CP' => 'Jasiiradda Kilibarton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuuba',
 			'CV' => 'Jasiiradda Kayb Faarde',
 			'CW' => 'Kurakaaw',
 			'CX' => 'Jasiiradda Kirismas',
 			'CY' => 'Qubrus',
 			'CZ' => 'Jekiya',
 			'CZ@alt=variant' => 'Jamhuuriyadda Jek',
 			'DE' => 'Jarmal',
 			'DG' => 'Diyeego Karsiya',
 			'DJ' => 'Jabuuti',
 			'DK' => 'Denmark',
 			'DM' => 'Dominika',
 			'DO' => 'Jamhuuriyaddda Dominika',
 			'DZ' => 'Aljeeriya',
 			'EA' => 'Seyuta & Meliila',
 			'EC' => 'Ikuwadoor',
 			'EE' => 'Estooniya',
 			'EG' => 'Masar',
 			'EH' => 'Saxaraha Galbeed',
 			'ER' => 'Eritreeya',
 			'ES' => 'Isbeyn',
 			'ET' => 'Itoobiya',
 			'EU' => 'Midowga Yurub',
 			'EZ' => 'Yurusoon',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Jaziiradaha Fooklaan',
 			'FK@alt=variant' => 'Jasiiradaha Fookland',
 			'FM' => 'Mikroneesiya',
 			'FO' => 'Jasiiradda Faroo',
 			'FR' => 'Faransiis',
 			'GA' => 'Gaaboon',
 			'GB' => 'Boqortooyada Midowday',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Giriinaada',
 			'GE' => 'Joorjiya',
 			'GF' => 'Faransiis Gini',
 			'GG' => 'Guurnsey',
 			'GH' => 'Gaana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambiya',
 			'GN' => 'Gini',
 			'GP' => 'Guadeluub',
 			'GQ' => 'Ekuwatooriyal Gini',
 			'GR' => 'Giriig',
 			'GS' => 'Jasiiradda Joorjiyada Koonfureed & Sandwij',
 			'GT' => 'Guwaatamaala',
 			'GU' => 'Guaam',
 			'GW' => 'Gini-Bisaaw',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong',
 			'HM' => 'Jasiiradda Haad & MakDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Korweeshiya',
 			'HT' => 'Haiti',
 			'HU' => 'Hangari',
 			'IC' => 'Jasiiradda Kanari',
 			'ID' => 'Indoneesiya',
 			'IE' => 'Ayrlaand',
 			'IL' => 'Israaʼiil',
 			'IM' => 'Jasiiradda Isle of Man',
 			'IN' => 'Hindiya',
 			'IO' => 'Dhul xadeedka Badweynta Hindiya ee Ingiriiska',
 			'IO@alt=chagos' => 'Chagos Archipelago',
 			'IQ' => 'Ciraaq',
 			'IR' => 'Iiraan',
 			'IS' => 'Ayslaand',
 			'IT' => 'Talyaani',
 			'JE' => 'Jaarsey',
 			'JM' => 'Jamaaika',
 			'JO' => 'Urdun',
 			'JP' => 'Jabaan',
 			'KE' => 'Kenya',
 			'KG' => 'Kirgistaan',
 			'KH' => 'Kamboodiya',
 			'KI' => 'Kiribati',
 			'KM' => 'Komooros',
 			'KN' => 'St. Kitts iyo Nevis',
 			'KP' => 'Kuuriyada Waqooyi',
 			'KR' => 'Kuuriyada Koonfureed',
 			'KW' => 'Kuwayt',
 			'KY' => 'Cayman Islands',
 			'KZ' => 'Kasaakhistaan',
 			'LA' => 'Laos',
 			'LB' => 'Lubnaan',
 			'LC' => 'St. Lusia',
 			'LI' => 'Liyjtensteyn',
 			'LK' => 'Sirilaanka',
 			'LR' => 'Laybeeriya',
 			'LS' => 'Losooto',
 			'LT' => 'Lituweeniya',
 			'LU' => 'Luksemboorg',
 			'LV' => 'Latfiya',
 			'LY' => 'Liibya',
 			'MA' => 'Morooko',
 			'MC' => 'Moonako',
 			'MD' => 'Moldofa',
 			'ME' => 'Moontenegro',
 			'MF' => 'St. Maartin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Jasiiradda Maarshal',
 			'MK' => 'Masedooniya Waqooyi',
 			'ML' => 'Maali',
 			'MM' => 'Mayanmar',
 			'MN' => 'Mongooliya',
 			'MO' => 'Makaaw',
 			'MP' => 'Jasiiradda Waqooyiga Mariaana',
 			'MQ' => 'Maartinik',
 			'MR' => 'Muritaaniya',
 			'MS' => 'Montserrat',
 			'MT' => 'Maalta',
 			'MU' => 'Mawrishiyaas',
 			'MV' => 'Maaldiifis',
 			'MW' => 'Malaawi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malaysiya',
 			'MZ' => 'Musambiik',
 			'NA' => 'Namiibiya',
 			'NC' => 'Jasiiradda Niyuu Kaledooniya',
 			'NE' => 'Nayjer',
 			'NF' => 'Jasiiradda Noorfolk',
 			'NG' => 'Nayjeeriya',
 			'NI' => 'Nikaraaguwa',
 			'NL' => 'Nederlaands',
 			'NO' => 'Noorweey',
 			'NP' => 'Nebaal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Niyuusiilaand',
 			'NZ@alt=variant' => 'Aotearoa New Zealand',
 			'OM' => 'Cumaan',
 			'PA' => 'Baanama',
 			'PE' => 'Beeru',
 			'PF' => 'Booliyneesiya Faransiiska',
 			'PG' => 'Babwa Niyuu Gini',
 			'PH' => 'Filibiin',
 			'PK' => 'Bakistaan',
 			'PL' => 'Booland',
 			'PM' => 'St. Pierre iyo Miquelon',
 			'PN' => 'Bitkairn',
 			'PR' => 'Bueerto Riiko',
 			'PS' => 'Dhulka Falastiiniyiinta daanta galbeed iyo marinka qasa',
 			'PS@alt=short' => 'Falastiin',
 			'PT' => 'Bortugaal',
 			'PW' => 'Balaaw',
 			'PY' => 'Baraguaay',
 			'QA' => 'Qadar',
 			'QO' => 'Dhulxeebeedka Osheeniya',
 			'RE' => 'Riyuuniyon',
 			'RO' => 'Rumaaniya',
 			'RS' => 'Seerbiya',
 			'RU' => 'Ruush',
 			'RW' => 'Ruwanda',
 			'SA' => 'Sacuudi Carabiya',
 			'SB' => 'Jasiiradda Solomon',
 			'SC' => 'Sishelis',
 			'SD' => 'Suudaan',
 			'SE' => 'Iswidhan',
 			'SG' => 'Singaboor',
 			'SH' => 'Saynt Helena',
 			'SI' => 'Islofeeniya',
 			'SJ' => 'Jasiiradda Sfaldbaad & Jaan Mayen',
 			'SK' => 'Islofaakiya',
 			'SL' => 'Siraaliyoon',
 			'SM' => 'San Marino',
 			'SN' => 'Sinigaal',
 			'SO' => 'Soomaaliya',
 			'SR' => 'Surineym',
 			'SS' => 'Koonfur Suudaan',
 			'ST' => 'Sao Tome & Birincibal',
 			'SV' => 'El Salfadoor',
 			'SX' => 'Siint Maarteen',
 			'SY' => 'Suuriya',
 			'SZ' => 'Eswaatiini',
 			'SZ@alt=variant' => 'Iswaasilaan',
 			'TA' => 'Tiristan da Kunha',
 			'TC' => 'Turks & Kaikos Island',
 			'TD' => 'Jaad',
 			'TF' => 'Dhul xadeedka Koonfureed ee Faransiiska',
 			'TG' => 'Toogo',
 			'TH' => 'Taylaand',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelaaw',
 			'TL' => 'Timoor',
 			'TL@alt=variant' => 'Bariga Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tuniisiya',
 			'TO' => 'Tonga',
 			'TR' => 'Turki',
 			'TT' => 'Tirinidaad & Tobago',
 			'TV' => 'Tufaalu',
 			'TW' => 'Taywaan',
 			'TZ' => 'Tansaaniya',
 			'UA' => 'Yukrayn',
 			'UG' => 'Ugaanda',
 			'UM' => 'Jasiiradaha ka baxsan Maraykanka',
 			'UN' => 'Qaramada Midoobay',
 			'US' => 'Maraykanka',
 			'UY' => 'Uruguwaay',
 			'UZ' => 'Usbakistan',
 			'VA' => 'Faatikaan',
 			'VC' => 'St. Finsent & Girenadiins',
 			'VE' => 'Fenisuweela',
 			'VG' => 'Biritish Farjin Island',
 			'VI' => 'U.S Fargin Island',
 			'VN' => 'Fiyetnaam',
 			'VU' => 'Fanuaatu',
 			'WF' => 'Walis & Futuna',
 			'WS' => 'Samoowa',
 			'XA' => 'Lahjadaha Pseudo',
 			'XB' => 'Pseudo-Bidi',
 			'XK' => 'Koosofo',
 			'YE' => 'Yaman',
 			'YT' => 'Mayotte',
 			'ZA' => 'Koonfur Afrika',
 			'ZM' => 'Saambiya',
 			'ZW' => 'Simbaabwe',
 			'ZZ' => 'Gobol aan la aqoonin',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'orthofraphygii hore ee Jarmalka',
 			'1994' => 'Heerka orthographyga Resiyaanka',
 			'1996' => 'Orthigraphygii jarmal ee 1996',
 			'1606NICT' => 'Fransiiskii dhexe ee ugu dambeeyay ilaa 1606',
 			'1694ACAD' => 'Faransiiskii Hore',
 			'1959ACAD' => 'Tacliin',
 			'ABL1943' => 'Qaacideeynta orthographygii 1943',
 			'ALALC97' => 'ALA-LC Romanization, 1997 daabacaad',
 			'ALUKU' => 'Lahjada Aluku',
 			'AO1990' => 'Heshiiska luuqada orthografiga burtuqiiska 1990',
 			'BAKU1926' => 'Farta Latin Turkiga ee Mideeysan',
 			'BALANKA' => 'Lahjada Balanka ee Anii',
 			'BARLA' => 'lahjada kooxda Barlavento ee kabuverdianu',
 			'BISKE' => 'Lahjada San Giorgio/Bila',
 			'BOHORIC' => 'Farta Bohorič',
 			'BOONT' => 'Luuqada Boontling',
 			'BORNHOLM' => 'BOONHOLM',
 			'COLB1945' => 'Shirkii orthografiga ee Portuguese-Brazilian 1945',
 			'DAJNKO' => 'alfabeetka Dajnko',
 			'EKAVSK' => 'dhaqyada isku jirka ah ee Serbiyaanka iyo Ekviyaan',
 			'EMODENG' => 'Ingiriiskii hore ee casriga ahaa',
 			'IJEKAVSK' => 'dhawaaqyada Serbiyaanka iyo Ijekaviyaan',
 			'KKCOR' => 'orhographyga caadiga ah',
 			'KSCOR' => 'heerka orthographyga',
 			'LENGADOC' => 'LENGADOK',
 			'LIPAW' => 'Lahjada Lipavaz ee Resiyaanka',
 			'LUNA1918' => 'LUUNA1918',
 			'METELKO' => 'alfaabeetka nmetelko',
 			'MONOTON' => 'MOONOTOONIK',
 			'NDYUKA' => 'lahjada Ndyuka',
 			'NEDIS' => 'lahjada Natisone',
 			'NEWFOUND' => 'HELITAANCUSUB',
 			'NICARD' => 'KAARKANI',
 			'NJIVA' => 'lahjada Gniva/Njiva',
 			'NULIK' => 'Folabuka casriga ah',
 			'OSOJS' => 'lahjada Oseacco/Osojane',
 			'OXENDICT' => 'hinggaadinta Qaamuuska Ingiriisiga Oxford',
 			'POSIX' => 'Kombiyuutar',
 			'SAAHO' => 'Saaho',
 			'SCOTLAND' => 'Heerka Ingiriisiga Iskootishka',
 			'SCOUSE' => 'GARAACID',
 			'SIMPLE' => 'Fudud',
 			'SOLBA' => 'lahjada Stolvizza/Solbica',
 			'TARASK' => 'orthographyga Taraskievica',
 			'UCCOR' => 'orthograpghyga mideeysan',
 			'UCRCOR' => 'orthographyga mideeysan ee hadana ladul maray',
 			'VALENCIA' => 'Faleensiyaawi',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Habeentiris',
 			'cf' => 'Habka Lacagta',
 			'collation' => 'Kala Soocidda Dalabka',
 			'currency' => 'Lacagta',
 			'hc' => 'Wareegga Saacadda (12 ilaa 24)',
 			'lb' => 'Habka Jebinta Xariiqda',
 			'ms' => 'Nidaamka Cabbiraadda',
 			'numbers' => 'Tirooyinka',

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
 				'buddhist' => q{Habeentiriska Buudhist},
 				'chinese' => q{Habeetiriska Shiinaha},
 				'coptic' => q{Habeentiriska Koptiga},
 				'dangi' => q{Habeetiriska Dangi},
 				'ethiopic' => q{Habeentiriska Itoobiya},
 				'ethiopic-amete-alem' => q{Taariikhda Itoobiya ee Amete Alem},
 				'gregorian' => q{Habeetiriska Geregoriyaan},
 				'hebrew' => q{Habeentiriska yuhuudda},
 				'indian' => q{Habeentiris Qarameedka Hindiya},
 				'islamic' => q{Habeentiriska islaamka},
 				'islamic-civil' => q{Taariikhda Islaamiga (shax ahaan, waayo madaniyeed)},
 				'islamic-rgsa' => q{Habeentiriska Islaamka (Sacuudiga, aragtida)},
 				'islamic-tbla' => q{Taariikhda Islaamiga (shax ahaan, waayo xiddigeed)},
 				'islamic-umalqura' => q{Taariikhda Islaamiga(Umm al-Qura)},
 				'iso8601' => q{Habeentiriska ISO-8601},
 				'japanese' => q{Habeentiriska jabbaanka},
 				'persian' => q{Habeentiriska Baarshiyaanka},
 				'roc' => q{Habeentiriska Minguwo},
 			},
 			'cf' => {
 				'account' => q{Habka Xisaabinta Lacagta},
 				'standard' => q{Habka Heerka Lacagta},
 			},
 			'collation' => {
 				'big5han' => q{Isku hagaajinta Shiineeskii Hore - Big5},
 				'compat' => q{Iswaafajinta Isku hajintii hore},
 				'dictionary' => q{Isku hagaajinta Qaamuuska},
 				'ducet' => q{Lambar Sireedka Caalamiga ee Kala Soocidda Dalabka},
 				'emoji' => q{Isku hagaajinta Emojiga},
 				'eor' => q{Xeerarka Dalabka Yurub},
 				'gb2312han' => q{Isku hagaajinta Farta shiineeska},
 				'phonebook' => q{Isku hagaajinta foonbuuga},
 				'pinyin' => q{Isku hagaajinta Pinyin},
 				'reformed' => q{Isku hagaajinta Reformed},
 				'search' => q{Raadinta Guud},
 				'searchjl' => q{Raadinta Shibanaha Hangul},
 				'standard' => q{Amarka Kala Soocidda Caadiga ah},
 				'stroke' => q{Isku hagaajinta Farta},
 				'traditional' => q{Isku hagaajin Fareedkii Hore},
 				'unihan' => q{Isku hagaajinta Farta Radical-Stroke},
 				'zhuyin' => q{Isku hagaajinta Farta Zhuyin},
 			},
 			'hc' => {
 				'h11' => q{12 Saac ee Nidaamka Saacadda (0–12)},
 				'h12' => q{12 Saac ee Nidaamka Saacadda (1–12)},
 				'h23' => q{24 Saac ee Nidaamka Saacadda (0–23)},
 				'h24' => q{24 Saac ee Nidaamka Saacadda (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Habka Jabinta Xariiqda Dabacsan},
 				'normal' => q{Habka Jabinta Xariiqda Caadiga ah},
 				'strict' => q{Habka Jabinta Xariiqda Adag},
 			},
 			'ms' => {
 				'metric' => q{Nidaamka Metric},
 				'uksystem' => q{Nidaamka Cabbirka Imperial-ka},
 				'ussystem' => q{Nidaamka Cabbirka ee US},
 			},
 			'numbers' => {
 				'ahom' => q{Godadka Ahom},
 				'arab' => q{Gdadka Carabi-Hindiya},
 				'arabext' => q{Tirooyinka Dheeraadka ah ee Godadka Carabi-Hindiya},
 				'armn' => q{Nidaam Tireedka Armeeniya},
 				'armnlow' => q{Nidaam Tireedka Yaryar ee Armeeniya},
 				'bali' => q{Godadka Balinese},
 				'beng' => q{Godadka Banglaa},
 				'brah' => q{Godadka Brahmi},
 				'cakm' => q{Godadka Chakma},
 				'cham' => q{Godadka cham},
 				'cyrl' => q{Lambarada Cyrillic},
 				'deva' => q{Godadka Defangaari},
 				'diak' => q{Godadka Dives Akuru},
 				'ethi' => q{Nidaam Tireedka Itoobiya},
 				'fullwide' => q{Ballac Godadka Buuxa},
 				'geor' => q{Nidaam Tireedka Giyoorgiyaanka},
 				'gong' => q{Godadka Gunjala Gondi},
 				'gonm' => q{Lambarada Masaram Gondi},
 				'grek' => q{Nidaam Tireedka Giriiga},
 				'greklow' => q{Nidaam Tireedka Yaryar ee Giriiga},
 				'gujr' => q{Godadka Gujaraati},
 				'guru' => q{Godadka Gurmukhi},
 				'hanidec' => q{Nidaamka Tireedka Tobanle ee Shiinaha},
 				'hans' => q{Nidaam Tireedka Hore La Fududeeyay ee Shiinaha},
 				'hansfin' => q{Nidaam Tireedka Hore La Fududeeyay ee Dhaqaalaha Shiinaha},
 				'hant' => q{Nidaam Tireedka Hore ee Shiinaha},
 				'hantfin' => q{Nidaam Tireedkii Hore ee Dhaqaalaha Shiinaha},
 				'hebr' => q{Nidaam Tireedka Cibraanka},
 				'hmng' => q{Nidaam Tireedka Hebrew},
 				'hmnp' => q{Godadka Nyiakeng Puachue Hmong},
 				'java' => q{Godadka Javanese},
 				'jpan' => q{Nidaam Tireedka Jabbaanka},
 				'jpanfin' => q{Nidaam Tireedka Dhaqaalaha Jabbaanka},
 				'kali' => q{Godadka Kayah Li},
 				'khmr' => q{Godadka Khamer},
 				'knda' => q{Godadka Kanada},
 				'lana' => q{Godadka Tai Tham Hora},
 				'lanatham' => q{Godadka Tai Tham},
 				'laoo' => q{Godadka Laao},
 				'latn' => q{Godadka Ree Galbeedka},
 				'lepc' => q{Godadka Lepcha},
 				'limb' => q{Godadka Limbu},
 				'mathbold' => q{Godad Xisaabeedka Waaweeyn},
 				'mathdbl' => q{Godad Xisaabeedka Labalaabma},
 				'mathmono' => q{Godad Xisaabeedka Monospace},
 				'mathsanb' => q{Godad xisaabeedka waaweeyn ee Sans-Serif},
 				'mathsans' => q{Godad xisaabeedka Sans-Serif},
 				'mlym' => q{Godadka Malayalam},
 				'modi' => q{Godadka Modi},
 				'mong' => q{Godadka Mongooliyaanka},
 				'mroo' => q{Godadka Mro},
 				'mtei' => q{Godadka Meetei Mayek},
 				'mymr' => q{Godadka Mayanmaar},
 				'mymrshan' => q{Godadka Myanmar Shan},
 				'mymrtlng' => q{Godadka Myanmar Tai Laing},
 				'nkoo' => q{Godadka N’Ko},
 				'olck' => q{Godadka Ol Chiki},
 				'orya' => q{Godadka Oodhiya},
 				'osma' => q{Godadka Osmanya},
 				'rohg' => q{Godadka Hanifi Rohingya},
 				'roman' => q{Nidaam Tireedka Roomaanka},
 				'romanlow' => q{Nidaam Tireedka yaryar ee Roomaanka},
 				'saur' => q{Godadka Saurashtra},
 				'shrd' => q{Godadka Sharada},
 				'sind' => q{Godadka Khudawadi},
 				'sinh' => q{Godadka Sinhala Lith},
 				'sora' => q{Godadka Sora Sompeng},
 				'sund' => q{Godadka Sundaniiska},
 				'takr' => q{Godadka Takri},
 				'talu' => q{Godadka cusub ee Tai Lue},
 				'taml' => q{Nidaam Tireedki Hore ee Taaamiil},
 				'tamldec' => q{Godka Tirada Taamiil},
 				'telu' => q{Godka Tirada Telugu},
 				'thai' => q{Godka Tirada Thai},
 				'tibt' => q{Godka Tirada Tibetan},
 				'tirh' => q{Godadka Tirhuta},
 				'vaii' => q{Godadka Vai},
 				'wara' => q{Godadka Warang Citi},
 				'wcho' => q{Godadka Wancho},
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
 			'UK' => q{Boqortooyada Midawday},
 			'US' => q{Maraykan},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Luuqad : {0}',
 			'script' => 'Qoraal: {0}',
 			'region' => 'Gobol : {0}',

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
			auxiliary => qr{[a e i o p u v z]},
			index => ['B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'Q', 'R', 'S', 'T', 'W', 'X', 'Y'],
			main => qr{[b c d f g h j k l m n q r s t w x y]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'Q', 'R', 'S', 'T', 'W', 'X', 'Y'], };
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
						'name' => q(afarta Jiho),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(afarta Jiho),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(dheer{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(dheer{0}),
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
					'10p-2' => {
						'1' => q(senti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(senti{0}),
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
						'1' => q(quecto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(quecto{0}),
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
					'10p30' => {
						'1' => q(quetta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(quetta{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0} cadaadis dib ku riixaya),
						'other' => q({0} cadaadis dib ku riixaya),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} cadaadis dib ku riixaya),
						'other' => q({0} cadaadis dib ku riixaya),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(mitir Isku-weer halkii ilbiriqsi),
						'one' => q({0} mitir Isku-weer halkii ilbiriqsi),
						'other' => q({0} mitir Isku-weer halkii ilbiriqsi),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(mitir Isku-weer halkii ilbiriqsi),
						'one' => q({0} mitir Isku-weer halkii ilbiriqsi),
						'other' => q({0} mitir Isku-weer halkii ilbiriqsi),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(aarkminit),
						'one' => q({0} aarkminit),
						'other' => q({0} aarkminit),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(aarkminit),
						'one' => q({0} aarkminit),
						'other' => q({0} aarkminit),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} digrii),
						'other' => q({0} digrii),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} digrii),
						'other' => q({0} digrii),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0} raadiyan),
						'other' => q({0} raadiyan),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0} raadiyan),
						'other' => q({0} raadiyan),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(wareeg),
						'one' => q({0} wareeg),
						'other' => q({0} wareeg),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(wareeg),
						'one' => q({0} wareeg),
						'other' => q({0} wareeg),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} aakre),
						'other' => q({0} aakre),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} aakre),
						'other' => q({0} aakre),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q(hektar),
						'other' => q({0} hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q(hektar),
						'other' => q({0} hektar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(sentimitir jibaaran),
						'one' => q({0} sentimitir jibaaran),
						'other' => q({0} sentimitir jibaaran),
						'per' => q({0} jibaaran sentimitirkiiba),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sentimitir jibaaran),
						'one' => q({0} sentimitir jibaaran),
						'other' => q({0} sentimitir jibaaran),
						'per' => q({0} jibaaran sentimitirkiiba),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} fiit jibaaran),
						'other' => q({0} fiit jibaaran),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} fiit jibaaran),
						'other' => q({0} fiit jibaaran),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(Injis jibaaran),
						'one' => q({0} Inji jibaaran),
						'other' => q({0} injis jibaaran),
						'per' => q({0} jibaaran injigiiba),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(Injis jibaaran),
						'one' => q({0} Inji jibaaran),
						'other' => q({0} injis jibaaran),
						'per' => q({0} jibaaran injigiiba),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kiilomitir jibaaran),
						'one' => q({0} kiilomitir jibaaran),
						'other' => q({0} kiilomitir jibaaran),
						'per' => q({0} jibaaran kiilomitirkiiba),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kiilomitir jibaaran),
						'one' => q({0} kiilomitir jibaaran),
						'other' => q({0} kiilomitir jibaaran),
						'per' => q({0} jibaaran kiilomitirkiiba),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0} mitir jibaaran),
						'other' => q({0} mitir jibaaran),
						'per' => q({0} jibaaran mitirkiiba),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0} mitir jibaaran),
						'other' => q({0} mitir jibaaran),
						'per' => q({0} jibaaran mitirkiiba),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} meyl jibaaran),
						'other' => q({0} meyl jibaaran),
						'per' => q({0} jibaaran meylkiiba),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} meyl jibaaran),
						'other' => q({0} meyl jibaaran),
						'per' => q({0} jibaaran meylkiiba),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'one' => q({0} yaardi jibaaran),
						'other' => q({0} yaardi jibaaran),
					},
					# Core Unit Identifier
					'square-yard' => {
						'one' => q({0} yaardi jibaaran),
						'other' => q({0} yaardi jibaaran),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(shayyo),
						'one' => q({0} shay),
						'other' => q({0} shayo),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(shayyo),
						'one' => q({0} shay),
						'other' => q({0} shayo),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karaatis),
						'one' => q({0} karaat),
						'other' => q({0} karaat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karaatis),
						'one' => q({0} karaat),
						'other' => q({0} karaat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligaraam disilitirkiiba),
						'one' => q({0} miligaraam disilitirkiib),
						'other' => q({0} miligaraam disilitirkiib),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligaraam disilitirkiiba),
						'one' => q({0} miligaraam disilitirkiib),
						'other' => q({0} miligaraam disilitirkiib),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimool litirkiiba),
						'one' => q({0} milimool litirkiiba),
						'other' => q({0} milimool litirkiiba),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimool litirkiiba),
						'one' => q({0} milimool litirkiiba),
						'other' => q({0} milimool litirkiiba),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q(boqolkiiba {0}),
						'other' => q(boqolkiiba {0}),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q(boqolkiiba {0}),
						'other' => q(boqolkiiba {0}),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} baarmiil),
						'other' => q({0} baarmiil),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} baarmiil),
						'other' => q({0} baarmiil),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(qeyb milyankiiba),
						'one' => q({0} qeyb milyankiiba),
						'other' => q({0} qeyb milyankiiba),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(qeyb milyankiiba),
						'one' => q({0} qeyb milyankiiba),
						'other' => q({0} qeyb milyankiiba),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} bermiraad),
						'other' => q({0} bermiraad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} bermiraad),
						'other' => q({0} bermiraad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litar 100-kii kiilomitirba),
						'one' => q({0} litar 100-kii kiilomitirba),
						'other' => q({0}litar 100-kii kiilomitirba),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litar 100-kii kiilomitirba),
						'one' => q({0} litar 100-kii kiilomitirba),
						'other' => q({0}litar 100-kii kiilomitirba),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litar kiilomitirkiiba),
						'one' => q(litar kiilomitirkiiba),
						'other' => q({0} litir kiilomitirkiiba),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litar kiilomitirkiiba),
						'one' => q(litar kiilomitirkiiba),
						'other' => q({0} litir kiilomitirkiiba),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(meyl galaankiiba),
						'one' => q({0} meylis galaankiiba),
						'other' => q({0} meyl galaankiiba),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(meyl galaankiiba),
						'one' => q({0} meylis galaankiiba),
						'other' => q({0} meyl galaankiiba),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(meyl imb. galaankiiba),
						'one' => q({0} meyl imb. galaankiiba),
						'other' => q({0} meyl imb. galaankiiba),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(meyl imb. galaankiiba),
						'one' => q({0} meyl imb. galaankiiba),
						'other' => q({0} meyl imb. galaankiiba),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Bari),
						'north' => q({0} Waqooyi),
						'south' => q({0} Koonfur),
						'west' => q({0} galbeed),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Bari),
						'north' => q({0} Waqooyi),
						'south' => q({0} Koonfur),
						'west' => q({0} galbeed),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bitis),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bitis),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(beytis),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(beytis),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabitis),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabitis),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabeytis),
						'one' => q({0} gigabeyt),
						'other' => q({0} gigabeyt),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabeytis),
						'one' => q({0} gigabeyt),
						'other' => q({0} gigabeyt),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kiilobitis),
						'one' => q({0} kiilobit),
						'other' => q({0} kiilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kiilobitis),
						'one' => q({0} kiilobit),
						'other' => q({0} kiilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kiiloobeytis),
						'one' => q({0} kiilobeyt),
						'other' => q({0} kiilobeyt),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kiiloobeytis),
						'one' => q({0} kiilobeyt),
						'other' => q({0} kiilobeyt),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabitis),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabitis),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabeytis),
						'one' => q({0} megabeyt),
						'other' => q({0} megabeyt),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabeytis),
						'one' => q({0} megabeyt),
						'other' => q({0} megabeyt),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(betabeytis),
						'one' => q({0} betabeyt),
						'other' => q({0} betabeyt),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(betabeytis),
						'one' => q({0} betabeyt),
						'other' => q({0} betabeyt),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabitis),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabitis),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabeytis),
						'one' => q({0} terabeyt),
						'other' => q({0} terabeyt),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabeytis),
						'one' => q({0} terabeyt),
						'other' => q({0} terabeyt),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(qarni),
						'one' => q({0} qarni),
						'other' => q({0} qarniyo),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(qarni),
						'one' => q({0} qarni),
						'other' => q({0} qarniyo),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(Maalmo),
						'one' => q({0} maalin),
						'other' => q({0} maalmood),
						'per' => q({0} maalintiiba),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Maalmo),
						'one' => q({0} maalin),
						'other' => q({0} maalmood),
						'per' => q({0} maalintiiba),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(rubuc qarni),
						'one' => q(rubuc qarni),
						'other' => q({0} dec),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(rubuc qarni),
						'one' => q(rubuc qarni),
						'other' => q({0} dec),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} saacad),
						'other' => q({0} saacadood),
						'per' => q({0} saacadiiba),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} saacad),
						'other' => q({0} saacadood),
						'per' => q({0} saacadiiba),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(maykroseken),
						'one' => q({0} maykroseken),
						'other' => q({0} maykroseken),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(maykroseken),
						'one' => q({0} maykroseken),
						'other' => q({0} maykroseken),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(miliseken),
						'one' => q({0} miliseken),
						'other' => q({0} miliseken),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(miliseken),
						'one' => q({0} miliseken),
						'other' => q({0} miliseken),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} daqiiqad),
						'other' => q({0} daqiiqo),
						'per' => q({0} daqiiqadiiba),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} daqiiqad),
						'other' => q({0} daqiiqo),
						'per' => q({0} daqiiqadiiba),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Bilo),
						'one' => q({0} bil),
						'other' => q({0} bilood),
						'per' => q({0} bishiiba),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Bilo),
						'one' => q({0} bil),
						'other' => q({0} bilood),
						'per' => q({0} bishiiba),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanoseken),
						'one' => q({0} nanoseken),
						'other' => q({0} nanoseken),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanoseken),
						'one' => q({0} nanoseken),
						'other' => q({0} nanoseken),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(Rubucyo),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(Rubucyo),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ilbiriqsi),
						'one' => q({0} ilbiriqsi),
						'other' => q({0} ilbiriqsi),
						'per' => q({0} Ilbiriqsigiiba),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ilbiriqsi),
						'one' => q({0} ilbiriqsi),
						'other' => q({0} ilbiriqsi),
						'per' => q({0} Ilbiriqsigiiba),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(toddobaadyo),
						'one' => q({0} toddobaad),
						'other' => q({0} toddobaadyo),
						'per' => q({0} toddobaadkiiba),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(toddobaadyo),
						'one' => q({0} toddobaad),
						'other' => q({0} toddobaadyo),
						'per' => q({0} toddobaadkiiba),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(Sannado),
						'one' => q({0} Sannad),
						'other' => q({0} Sannado),
						'per' => q({0} Sannadkiiba),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(Sannado),
						'one' => q({0} Sannad),
						'other' => q({0} Sannado),
						'per' => q({0} Sannadkiiba),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amberes),
						'one' => q({0} ambeer),
						'other' => q({0} ambeer),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amberes),
						'one' => q({0} ambeer),
						'other' => q({0} ambeer),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliambeeris),
						'one' => q({0} miliambeer),
						'other' => q({0} miliambeer),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliambeeris),
						'one' => q({0} miliambeer),
						'other' => q({0} miliambeer),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0} foolt),
						'other' => q({0} foolt),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0} foolt),
						'other' => q({0} foolt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(halbeega kulaylka ee Biritishka),
						'one' => q(halbeega kulaylka ee Biritishka),
						'other' => q({0} halbeega kulaylka ee Biritishka),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(halbeega kulaylka ee Biritishka),
						'one' => q(halbeega kulaylka ee Biritishka),
						'other' => q({0} halbeega kulaylka ee Biritishka),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kalooris),
						'one' => q({0} kalooris),
						'other' => q({0} kalooris),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kalooris),
						'one' => q({0} kalooris),
						'other' => q({0} kalooris),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(Elektarofooltis),
						'one' => q({0} Elektarofoolt),
						'other' => q({0}Elektarofooltis),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(Elektarofooltis),
						'one' => q({0} Elektarofoolt),
						'other' => q({0}Elektarofooltis),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Kalooris),
						'one' => q({0} Kalooris),
						'other' => q({0} Kalooris),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kalooris),
						'one' => q({0} Kalooris),
						'other' => q({0} Kalooris),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(Juules),
						'one' => q({0} juul),
						'other' => q({0} juules),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(Juules),
						'one' => q({0} juul),
						'other' => q({0} juules),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'one' => q({0} kilokalooris),
						'other' => q({0} kilokalooris),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'one' => q({0} kilokalooris),
						'other' => q({0} kilokalooris),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojuules),
						'one' => q({0} kiilojuul),
						'other' => q({0} kiilojuules),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojuules),
						'one' => q({0} kiilojuul),
						'other' => q({0} kiilojuules),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kiilowaat-saacado),
						'one' => q({0} kiilowaat saacadiiba),
						'other' => q({0} kiilowaat saacadiiba),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kiilowaat-saacado),
						'one' => q({0} kiilowaat saacadiiba),
						'other' => q({0} kiilowaat saacadiiba),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-saacadood 100 kiilomitirba),
						'one' => q({0} kilowatt-saacadood 100 kiilomitirba),
						'other' => q({0} kilowatt-saacadood 100 kiilomitirba),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-saacadood 100 kiilomitirba),
						'one' => q({0} kilowatt-saacadood 100 kiilomitirba),
						'other' => q({0} kilowatt-saacadood 100 kiilomitirba),
					},
					# Long Unit Identifier
					'force-newton' => {
						'one' => q({0} nuyuuton),
						'other' => q({0} nuyuuton),
					},
					# Core Unit Identifier
					'newton' => {
						'one' => q({0} nuyuuton),
						'other' => q({0} nuyuuton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'one' => q({0} rodol xoog),
						'other' => q({0} rodolo xoog),
					},
					# Core Unit Identifier
					'pound-force' => {
						'one' => q({0} rodol xoog),
						'other' => q({0} rodolo xoog),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahaartis),
						'one' => q({0} gigahaart),
						'other' => q({0} gigahaart),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahaartis),
						'one' => q({0} gigahaart),
						'other' => q({0} gigahaart),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(haartis),
						'one' => q({0} haart),
						'other' => q({0} haart),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(haartis),
						'one' => q({0} haart),
						'other' => q({0} haart),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kiilohaartis),
						'one' => q({0} kiilohaart),
						'other' => q({0} kiilohaart),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kiilohaartis),
						'one' => q({0} kiilohaart),
						'other' => q({0} kiilohaart),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(meegahaartis),
						'one' => q({0} megahaart),
						'other' => q({0} megahaart),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(meegahaartis),
						'one' => q({0} megahaart),
						'other' => q({0} megahaart),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(dhibicyo),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(dhibicyo),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dhibco halkii sentimitir),
						'one' => q({0} dhibco halkii sentimitir),
						'other' => q({0} dhibco halkii sentimitir),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dhibco halkii sentimitir),
						'one' => q({0} dhibco halkii sentimitir),
						'other' => q({0} dhibco halkii sentimitir),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dhibco injigiiba),
						'one' => q({0} dhibic injigiiba),
						'other' => q({0} dhibic injigiiba),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dhibco injigiiba),
						'one' => q({0} dhibic injigiiba),
						'other' => q({0} dhibic injigiiba),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(ems qoraal ahaan ah),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(ems qoraal ahaan ah),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(Unuga xidigiska),
						'one' => q({0} unuga xidigiska),
						'other' => q({0} unuga xidigiska),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(Unuga xidigiska),
						'one' => q({0} unuga xidigiska),
						'other' => q({0} unuga xidigiska),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(Sentimitir),
						'one' => q({0} sentimitir),
						'other' => q({0} sentimitir),
						'per' => q({0} sentimitirkiiba),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(Sentimitir),
						'one' => q({0} sentimitir),
						'other' => q({0} sentimitir),
						'per' => q({0} sentimitirkiiba),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(desimitir),
						'one' => q({0} desimitir),
						'other' => q({0} dsimitir),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(desimitir),
						'one' => q({0} desimitir),
						'other' => q({0} dsimitir),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(fiit),
						'one' => q(Fuudh),
						'other' => q({0} fiit),
						'per' => q({0} fiitkiiba),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(fiit),
						'one' => q(Fuudh),
						'other' => q({0} fiit),
						'per' => q({0} fiitkiiba),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(Injis),
						'one' => q(Injis),
						'other' => q({0} injis),
						'per' => q({0} injigiiba),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(Injis),
						'one' => q(Injis),
						'other' => q({0} injis),
						'per' => q({0} injigiiba),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(Kiilo mitir),
						'one' => q({0} kiilo mitir),
						'other' => q({0} kiilo mitir),
						'per' => q({0} kiilo mitirkiiba),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(Kiilo mitir),
						'one' => q({0} kiilo mitir),
						'other' => q({0} kiilo mitir),
						'per' => q({0} kiilo mitirkiiba),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(sannadaha masaafada iftiinka),
						'one' => q({0} sanno masaafo Iftiin),
						'other' => q({0} sanno masaafo iftiin),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(sannadaha masaafada iftiinka),
						'one' => q({0} sanno masaafo Iftiin),
						'other' => q({0} sanno masaafo iftiin),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mitir),
						'one' => q({0} mitir),
						'other' => q({0} mitir),
						'per' => q({0} mitirkiiba),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mitir),
						'one' => q({0} mitir),
						'other' => q({0} mitir),
						'per' => q({0} mitirkiiba),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(maykromitir),
						'one' => q({0} maykromitir),
						'other' => q({0} maykromitir),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(maykromitir),
						'one' => q({0} maykromitir),
						'other' => q({0} maykromitir),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(Meyl),
						'one' => q({0} meyl),
						'other' => q({0} meyl),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(Meyl),
						'one' => q({0} meyl),
						'other' => q({0} meyl),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(meyl-iskandineyfiyaan),
						'one' => q({0} meyl-iskandineyfiyaan),
						'other' => q({0} meyl-iskanddineyfiyaan),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(meyl-iskandineyfiyaan),
						'one' => q({0} meyl-iskandineyfiyaan),
						'other' => q({0} meyl-iskanddineyfiyaan),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimitir),
						'one' => q({0} milimitir),
						'other' => q({0} milimitir),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimitir),
						'one' => q({0} milimitir),
						'other' => q({0} milimitir),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanomitir),
						'one' => q({0} nanomitir),
						'other' => q({0} nanomitir),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanomitir),
						'one' => q({0} nanomitir),
						'other' => q({0} nanomitir),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(Nuutikal meyl),
						'one' => q(nuutika meyl),
						'other' => q({0} nuutikal meyl),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(Nuutikal meyl),
						'one' => q(nuutika meyl),
						'other' => q({0} nuutikal meyl),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(Barseks),
						'one' => q({0} barseks),
						'other' => q({0} barseks),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(Barseks),
						'one' => q({0} barseks),
						'other' => q({0} barseks),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(Bikomitir),
						'one' => q({0} bikomitir),
						'other' => q({0} bikomitir),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(Bikomitir),
						'one' => q({0} bikomitir),
						'other' => q({0} bikomitir),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q({0} dhibic),
						'other' => q({0} dhibco),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q({0} dhibic),
						'other' => q({0} dhibco),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} raadiyas qoraxeed),
						'other' => q({0} raadiyas qoraxeed),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} raadiyas qoraxeed),
						'other' => q({0} raadiyas qoraxeed),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(Yaardi),
						'one' => q({0} yaardi),
						'other' => q({0} yaardi),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(Yaardi),
						'one' => q({0} yaardi),
						'other' => q({0} yaardi),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q({0} laks),
						'other' => q({0} laks),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0} laks),
						'other' => q({0} laks),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(iftiinnada qorraxda),
						'one' => q({0} iftiinka qorraxda),
						'other' => q({0} iftiinada qorraxda),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(iftiinnada qorraxda),
						'one' => q({0} iftiinka qorraxda),
						'other' => q({0} iftiinada qorraxda),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0} karaats),
						'other' => q({0} karaats),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0} karaats),
						'other' => q({0} karaats),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(Daltonis),
						'one' => q({0} Dalton),
						'other' => q({0} Dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(Daltonis),
						'one' => q({0} Dalton),
						'other' => q({0} Dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(cufka Dhulka),
						'one' => q({0} cufka Dhulka),
						'other' => q({0} cufka Dhulka),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(cufka Dhulka),
						'one' => q({0} cufka Dhulka),
						'other' => q({0} cufka Dhulka),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} garaam),
						'other' => q({0} garaam),
						'per' => q({0} garaamkiiba),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} garaam),
						'other' => q({0} garaam),
						'per' => q({0} garaamkiiba),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kiilogaraam),
						'one' => q({0} kiilogaraam),
						'other' => q({0} kiilogaraam),
						'per' => q({0} kiilogaraam),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kiilogaraam),
						'one' => q({0} kiilogaraam),
						'other' => q({0} kiilogaraam),
						'per' => q({0} kiilogaraam),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(maykrogaraam),
						'one' => q({0} maykrogaraam),
						'other' => q({0} maykrogaraam),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(maykrogaraam),
						'one' => q({0} maykrogaraam),
						'other' => q({0} maykrogaraam),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(miligaraam),
						'one' => q({0} miligaraam),
						'other' => q({0} miligaraam),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(miligaraam),
						'one' => q({0} miligaraam),
						'other' => q({0} miligaraam),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ownis),
						'one' => q({0} ownis),
						'other' => q({0} ownis),
						'per' => q({0} owniskiiba),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ownis),
						'one' => q({0} ownis),
						'other' => q({0} ownis),
						'per' => q({0} owniskiiba),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(torooy ownis),
						'one' => q({0} torooy ownis),
						'other' => q({0} torooy ownis),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(torooy ownis),
						'one' => q({0} torooy ownis),
						'other' => q({0} torooy ownis),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} bownd),
						'other' => q({0} bownd),
						'per' => q({0} bowndkiiba),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} bownd),
						'other' => q({0} bownd),
						'per' => q({0} bowndkiiba),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(cufka qorraxda),
						'one' => q({0} cufka qorraxda),
						'other' => q({0} cufka qorraxda),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(cufka qorraxda),
						'one' => q({0} cufka qorraxda),
						'other' => q({0} cufka qorraxda),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} tan),
						'other' => q({0} tan),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} tan),
						'other' => q({0} tan),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(metrik tan),
						'one' => q({0} metrik tan),
						'other' => q({0} metrik tan),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(metrik tan),
						'one' => q({0} metrik tan),
						'other' => q({0} metrik tan),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawaatis),
						'one' => q({0} gigawaat),
						'other' => q({0} gigawaat),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawaatis),
						'one' => q({0} gigawaat),
						'other' => q({0} gigawaat),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(horasbaawar),
						'one' => q({0} horasbaawar),
						'other' => q({0} horasbaawar),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(horasbaawar),
						'one' => q({0} horasbaawar),
						'other' => q({0} horasbaawar),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kiilowaat),
						'one' => q({0} kiilowaat),
						'other' => q({0} kiilowaat),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kiilowaat),
						'one' => q({0} kiilowaat),
						'other' => q({0} kiilowaat),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(meegawaat),
						'one' => q({0} meegawaat),
						'other' => q({0} meegawaat),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(meegawaat),
						'one' => q({0} meegawaat),
						'other' => q({0} meegawaat),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(miliwaat),
						'one' => q({0} miliwaat),
						'other' => q({0} miliwaat),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(miliwaat),
						'one' => q({0} miliwaat),
						'other' => q({0} miliwaat),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(waatis),
						'one' => q({0} waat),
						'other' => q({0} waat),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(waatis),
						'one' => q({0} waat),
						'other' => q({0} waat),
					},
					# Long Unit Identifier
					'power2' => {
						'one' => q(laba-jibaar {0}),
						'other' => q(laba-jibaar {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q(laba-jibaar {0}),
						'other' => q(laba-jibaar {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'one' => q(saddex-jibaar {0}),
						'other' => q(saddex-jibaar {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'one' => q(saddex-jibaar {0}),
						'other' => q(saddex-jibaar {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(hawada agagaarka),
						'one' => q({0} hawada agagaarka),
						'other' => q({0} hawada agagaarka),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(hawada agagaarka),
						'one' => q({0} hawada agagaarka),
						'other' => q({0} hawada agagaarka),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hektobaskalis),
						'one' => q({0} hektobaskal),
						'other' => q({0} hektobaskal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hektobaskalis),
						'one' => q({0} hektobaskal),
						'other' => q({0} hektobaskal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inches of mercury),
						'one' => q({0} Inji maakuri ah),
						'other' => q({0} Inji maakuri ah),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inches of mercury),
						'one' => q({0} Inji maakuri ah),
						'other' => q({0} Inji maakuri ah),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(Kiilobaskalis),
						'one' => q({0} kiilobaskal),
						'other' => q({0} kiilobaskal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(Kiilobaskalis),
						'one' => q({0} kiilobaskal),
						'other' => q({0} kiilobaskal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(meegabaskalis),
						'one' => q({0} meegabaskal),
						'other' => q({0} meegabaskal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(meegabaskalis),
						'one' => q({0} meegabaskal),
						'other' => q({0} meegabaskal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(milibaaris),
						'one' => q({0} milibaar),
						'other' => q({0} milibaar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(milibaaris),
						'one' => q({0} milibaar),
						'other' => q({0} milibaar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milimitir maakuri ah),
						'one' => q({0} milimitir maarkuri),
						'other' => q({0} milimitir maarkuri),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milimitir maakuri ah),
						'one' => q({0} milimitir maarkuri),
						'other' => q({0} milimitir maarkuri),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(rodol halkii inji ee Isku weer ah),
						'one' => q({0} rodol halkii inji ee Isku weer ah),
						'other' => q({0} rodol halkii inji ee Isku weer ah),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(rodol halkii inji ee Isku weer ah),
						'one' => q({0} rodol halkii inji ee Isku weer ah),
						'other' => q({0} rodol halkii inji ee Isku weer ah),
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
						'name' => q(kiilomitir saacadiiba),
						'one' => q({0} kiilomitir saacadiiba),
						'other' => q({0} kiilomitir saacadiiba),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kiilomitir saacadiiba),
						'one' => q({0} kiilomitir saacadiiba),
						'other' => q({0} kiilomitir saacadiiba),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nott),
						'one' => q({0} nott),
						'other' => q({0} nott),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nott),
						'one' => q({0} nott),
						'other' => q({0} nott),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(mitir ilbiriqsigiiba),
						'one' => q(mitir ilbiriqsigiiba),
						'other' => q({0} mitir ilbiriqsigiiba),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(mitir ilbiriqsigiiba),
						'one' => q(mitir ilbiriqsigiiba),
						'other' => q({0} mitir ilbiriqsigiiba),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} meyl saacadiiba),
						'other' => q({0} meyl saacadiiba),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} meyl saacadiiba),
						'other' => q({0} meyl saacadiiba),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(degriis Selsiyaas),
						'one' => q({0} degrii Selsiyaas),
						'other' => q({0} degrii Selsiyaas),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(degriis Selsiyaas),
						'one' => q({0} degrii Selsiyaas),
						'other' => q({0} degrii Selsiyaas),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(degriis Faahrenheyt),
						'one' => q({0} degrii Faahrenheyt),
						'other' => q({0} degrii Faahrenheyt),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(degriis Faahrenheyt),
						'one' => q({0} degrii Faahrenheyt),
						'other' => q({0} degrii Faahrenheyt),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelfinis),
						'one' => q({0} kelfin),
						'other' => q({0} kelfin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelfinis),
						'one' => q({0} kelfin),
						'other' => q({0} kelfin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(nuyuuton-mitir),
						'one' => q({0} nuyuuton-mitir),
						'other' => q({0} nuyuuton-mitir),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(nuyuuton-mitir),
						'one' => q({0} nuyuuton-mitir),
						'other' => q({0} nuyuuton-mitir),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(Roodal-fiit),
						'one' => q({0}roodal-fiit),
						'other' => q({0} roodal fiit),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(Roodal-fiit),
						'one' => q({0}roodal-fiit),
						'other' => q({0} roodal fiit),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(akre-fiit),
						'one' => q({0} akre-fiit),
						'other' => q({0} akre-fiit),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(akre-fiit),
						'one' => q({0} akre-fiit),
						'other' => q({0} akre-fiit),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q({0} foosto),
						'other' => q({0} foosto),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q({0} foosto),
						'other' => q({0} foosto),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0}cabirka bushel),
						'other' => q({0}cabirka bushels),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0}cabirka bushel),
						'other' => q({0}cabirka bushels),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sentilitar),
						'one' => q({0} sentilitar),
						'other' => q({0} sentilitar),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sentilitar),
						'one' => q({0} sentilitar),
						'other' => q({0} sentilitar),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(sentimitir saddex jibaaran),
						'one' => q({0} sentimitir saddex jibaaran),
						'other' => q({0} sentimitir saddex jibaaran),
						'per' => q({0} sentimitirkii saddex jibaaranba),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(sentimitir saddex jibaaran),
						'one' => q({0} sentimitir saddex jibaaran),
						'other' => q({0} sentimitir saddex jibaaran),
						'per' => q({0} sentimitirkii saddex jibaaranba),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(fiit saddex jibaaran),
						'one' => q({0} fiit saddex jibaaran),
						'other' => q({0} fiit saddex jibaaran),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(fiit saddex jibaaran),
						'one' => q({0} fiit saddex jibaaran),
						'other' => q({0} fiit saddex jibaaran),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inji saddex jibaaran),
						'one' => q({0} inji saddex jibaaran),
						'other' => q({0} inji saddex jibaaran),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inji saddex jibaaran),
						'one' => q({0} inji saddex jibaaran),
						'other' => q({0} inji saddex jibaaran),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kiilomitir saddex jabbaaran),
						'one' => q({0} kiilomitir saddex jabbaaran),
						'other' => q({0} kiilomitir saddex jabaaran),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kiilomitir saddex jabbaaran),
						'one' => q({0} kiilomitir saddex jabbaaran),
						'other' => q({0} kiilomitir saddex jabaaran),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(mitir saddex jabbaaran),
						'one' => q({0} mitir saddex jibaaran),
						'other' => q({0} mitir saddex jibaaran),
						'per' => q({0} mitirkii saddex jibaaranba),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(mitir saddex jabbaaran),
						'one' => q({0} mitir saddex jibaaran),
						'other' => q({0} mitir saddex jibaaran),
						'per' => q({0} mitirkii saddex jibaaranba),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(meyl saddex jibaaran),
						'one' => q({0} meyl saddex jibaaran),
						'other' => q({0} meyl saddex jibaaran),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(meyl saddex jibaaran),
						'one' => q({0} meyl saddex jibaaran),
						'other' => q({0} meyl saddex jibaaran),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yaardi saddex jibaaran),
						'one' => q({0} yaardi saddex jibaaran),
						'other' => q({0} yaardi saddex jibaaran),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yaardi saddex jibaaran),
						'one' => q({0} yaardi saddex jibaaran),
						'other' => q({0} yaardi saddex jibaaran),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0} koob),
						'other' => q({0} koob),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0} koob),
						'other' => q({0} koob),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(metrik koob),
						'one' => q(metrik koob),
						'other' => q({0} merik koob),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(metrik koob),
						'one' => q(metrik koob),
						'other' => q({0} merik koob),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(disilitar),
						'one' => q({0} disilitar),
						'other' => q({0} disilitar),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(disilitar),
						'one' => q({0} disilitar),
						'other' => q({0} disilitar),
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
						'name' => q(owniska dareeraha),
						'one' => q({0} owniska dareeraha),
						'other' => q({0} owniska dareeraha),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(owniska dareeraha),
						'one' => q({0} owniska dareeraha),
						'other' => q({0} owniska dareeraha),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q({0} imb. owniska dareeraha),
						'other' => q({0} imb. owniska dareeraha),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0} imb. owniska dareeraha),
						'other' => q({0} imb. owniska dareeraha),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galaan),
						'one' => q({0} galaan),
						'other' => q({0} galaan),
						'per' => q({0} galaankiiba),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galaan),
						'one' => q({0} galaan),
						'other' => q({0} galaan),
						'per' => q({0} galaankiiba),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(imb. galaan),
						'one' => q({0} imb. galaan),
						'other' => q({0} imb. galaan),
						'per' => q({0} imb. galaankiiba),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(imb. galaan),
						'one' => q({0} imb. galaan),
						'other' => q({0} imb. galaan),
						'per' => q({0} imb. galaankiiba),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektolitar),
						'one' => q({0} hektolitar),
						'other' => q({0} hektolitar),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektolitar),
						'one' => q({0} hektolitar),
						'other' => q({0} hektolitar),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} litar),
						'other' => q({0} litar),
						'per' => q({0} litarkiiba),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} litar),
						'other' => q({0} litar),
						'per' => q({0} litarkiiba),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(meegalitar),
						'one' => q({0} meegalitar),
						'other' => q({0} meegalitar),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(meegalitar),
						'one' => q({0} meegalitar),
						'other' => q({0} meegalitar),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililitar),
						'one' => q({0} mililitar),
						'other' => q({0} mililitar),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililitar),
						'one' => q({0} mililitar),
						'other' => q({0} mililitar),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(bintis),
						'one' => q({0} bint),
						'other' => q({0} bint),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(bintis),
						'one' => q({0} bint),
						'other' => q({0} bint),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(metrik bintis),
						'one' => q({0} metrik bint),
						'other' => q({0} metrik bint),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(metrik bintis),
						'one' => q({0} metrik bint),
						'other' => q({0} metrik bint),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kowaart),
						'one' => q({0} kowaart),
						'other' => q({0} kowaart),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kowaart),
						'one' => q({0} kowaart),
						'other' => q({0} kowaart),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(malqaacadood),
						'one' => q({0} malqaacad),
						'other' => q({0} malqaacadood),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(malqaacadood),
						'one' => q({0} malqaacad),
						'other' => q({0} malqaacadood),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(malqaacad shaah),
						'one' => q(malqaacad shaah),
						'other' => q({0} malqaacad shaah),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(malqaacad shaah),
						'one' => q(malqaacad shaah),
						'other' => q({0} malqaacad shaah),
					},
				},
				'narrow' => {
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
						'one' => q({0}shay),
						'other' => q({0}shay),
					},
					# Core Unit Identifier
					'item' => {
						'one' => q({0}shay),
						'other' => q({0}shay),
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
					'concentr-percent' => {
						'name' => q(%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ppm),
						'one' => q({0}ppm),
						'other' => q({0}ppm#),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
						'one' => q({0}ppm),
						'other' => q({0}ppm#),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}B),
						'north' => q({0}W),
						'south' => q({0}K),
						'west' => q({0}G),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}B),
						'north' => q({0}W),
						'south' => q({0}K),
						'west' => q({0}G),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(toban sano),
						'one' => q({0}diis),
						'other' => q({0}diis),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(toban sano),
						'one' => q({0}diis),
						'other' => q({0}diis),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(scd),
						'one' => q({0} scd),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(scd),
						'one' => q({0} scd),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(mlsek),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(mlsek),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(dqqd),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(dqqd),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Bil),
						'one' => q({0}b),
						'other' => q({0}b),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Bil),
						'one' => q({0}b),
						'other' => q({0}b),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(Rubac),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(Rubac),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0}il),
						'other' => q({0}il),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0}il),
						'other' => q({0}il),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(t),
						'one' => q({0}t),
						'other' => q({0}t),
						'per' => q({0}/tobaadkii),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(t),
						'one' => q({0}t),
						'other' => q({0}t),
						'per' => q({0}/tobaadkii),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(snd),
						'one' => q({0}s),
						'other' => q({0}s),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(snd),
						'one' => q({0}s),
						'other' => q({0}s),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'one' => q({0}Kal),
						'other' => q({0}Kal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'one' => q({0}Kal),
						'other' => q({0}Kal),
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
					'graphics-dot' => {
						'name' => q(dhibic),
						'one' => q({0}dhibic),
						'other' => q({0}dhibic),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(dhibic),
						'one' => q({0}dhibic),
						'other' => q({0}dhibic),
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
						'one' => q({0}dhbi),
						'other' => q({0}dhbi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'one' => q({0}dhbi),
						'other' => q({0}dhbi),
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
					'mass-grain' => {
						'name' => q(gr),
						'one' => q({0}gr),
						'other' => q({0}gr),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gr),
						'one' => q({0}gr),
						'other' => q({0}gr),
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
					'pressure-inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
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
						'name' => q(km/s),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/s),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
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
					'volume-bushel' => {
						'name' => q(cabirka bushel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(cabirka bushel),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mkoob),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mkoob),
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
						'name' => q(dsp Imp),
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dsp Imp),
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
						'one' => q({0}L),
						'other' => q({0}L),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pn),
						'one' => q({0}pn),
						'other' => q({0}pn),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pn),
						'one' => q({0}pn),
						'other' => q({0}pn),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q({0}qt-Imp.),
						'other' => q({0}qt-Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0}qt-Imp.),
						'other' => q({0}qt-Imp.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(jiho),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(jiho),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(cadaadis dib ku riixaya),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(cadaadis dib ku riixaya),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(mitir/ilbrqsi²),
						'one' => q({0} m/i²),
						'other' => q({0} m/i²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(mitir/ilbrqsi²),
						'one' => q({0} m/i²),
						'other' => q({0} m/i²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arkmnt),
						'one' => q({0} arkmnt),
						'other' => q({0} arkmnt),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arkmnt),
						'one' => q({0} arkmnt),
						'other' => q({0} arkmnt),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(aarkseken),
						'one' => q({0} aarkseken),
						'other' => q({0} aarkseken),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(aarkseken),
						'one' => q({0} aarkseken),
						'other' => q({0} aarkseken),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(digrii),
						'one' => q({0} dig),
						'other' => q({0} dig),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(digrii),
						'one' => q({0} dig),
						'other' => q({0} dig),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(raadiyan),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(raadiyan),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(wreg),
						'one' => q({0} wreg),
						'other' => q({0} wreg),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(wreg),
						'one' => q({0} wreg),
						'other' => q({0} wreg),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(aakre),
						'one' => q({0} ak),
						'other' => q({0} ak),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(aakre),
						'one' => q({0} ak),
						'other' => q({0} ak),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunaam),
						'one' => q({0} dunaam),
						'other' => q({0} dunaam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunaam),
						'one' => q({0} dunaam),
						'other' => q({0} dunaam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektar),
						'one' => q({0} hk),
						'other' => q({0} hk),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektar),
						'one' => q({0} hk),
						'other' => q({0} hk),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(fiit jibaaran),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(fiit jibaaran),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(injis²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(injis²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(mitir jibaaran),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(mitir jibaaran),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(meyl jibaaran),
						'one' => q({0} my²),
						'other' => q({0} my²),
						'per' => q({0}/my²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(meyl jibaaran),
						'one' => q({0} my²),
						'other' => q({0} my²),
						'per' => q({0}/my²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yaardi jibaaran),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yaardi jibaaran),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(shay),
						'one' => q({0} shay),
						'other' => q({0} shay),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(shay),
						'one' => q({0} shay),
						'other' => q({0} shay),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karaat),
						'one' => q({0} kr),
						'other' => q({0} kr),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karaat),
						'one' => q({0} kr),
						'other' => q({0} kr),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mool),
						'one' => q({0} mool),
						'other' => q({0} mool),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mool),
						'one' => q({0} mool),
						'other' => q({0} mool),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(boqolkiiba),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(boqolkiiba),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(baarmiil),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(baarmiil),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(qeyb/milyankiiba),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(qeyb/milyankiiba),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(bermiraad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(bermiraad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litar/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litar/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(meyl/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(meyl/gal),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(meyl/gal imb.),
						'one' => q({0} mg Imb.),
						'other' => q({0} mg Imb.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(meyl/gal imb.),
						'one' => q({0} mg Imb.),
						'other' => q({0} mg Imb.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} B),
						'north' => q({0} W),
						'south' => q({0} K),
						'west' => q({0} G),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} B),
						'north' => q({0} W),
						'south' => q({0} K),
						'west' => q({0} G),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(beyt),
						'one' => q({0} beyt),
						'other' => q({0} beyt),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(beyt),
						'one' => q({0} beyt),
						'other' => q({0} beyt),
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
						'name' => q(GBeyt),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GBeyt),
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
						'name' => q(kBeyt),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kBeyt),
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
						'name' => q(MBeyt),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MBeyt),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(BBeyt),
						'one' => q({0} BB),
						'other' => q({0} BB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(BBeyt),
						'one' => q({0} BB),
						'other' => q({0} BB),
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
						'name' => q(TBeyt),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TBeyt),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(q),
						'one' => q({0} q),
						'other' => q({0} q),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(q),
						'one' => q({0} q),
						'other' => q({0} q),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(mln),
						'one' => q({0} mln),
						'other' => q({0} mln),
						'per' => q({0}/mt),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(mln),
						'one' => q({0} mln),
						'other' => q({0} mln),
						'per' => q({0}/mt),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(saacado),
						'one' => q({0} scd),
						'other' => q({0} scd),
						'per' => q({0} scdi),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(saacado),
						'one' => q({0} scd),
						'other' => q({0} scd),
						'per' => q({0} scdi),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mykseken),
						'one' => q({0} myks),
						'other' => q({0} myks),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mykseken),
						'one' => q({0} myks),
						'other' => q({0} myks),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisek),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisek),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(daqiiqad),
						'one' => q({0} dqqd),
						'other' => q({0} daqiiqo),
						'per' => q({0} dqqdb),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(daqiiqad),
						'one' => q({0} dqqd),
						'other' => q({0} daqiiqo),
						'per' => q({0} dqqdb),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(bil),
						'one' => q({0} bil),
						'other' => q({0} bil),
						'per' => q({0}/bsh),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(bil),
						'one' => q({0} bil),
						'other' => q({0} bil),
						'per' => q({0}/bsh),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosek),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosek),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(Rubuc),
						'one' => q({0} rubac),
						'other' => q({0} rubac),
						'per' => q({0}/rubac),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(Rubuc),
						'one' => q({0} rubac),
						'other' => q({0} rubac),
						'per' => q({0}/rubac),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ilbrqsi),
						'one' => q({0} ilbrqsi),
						'other' => q({0} ilbrqsi),
						'per' => q({0}/ilbrgba),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ilbrqsi),
						'one' => q({0} ilbrqsi),
						'other' => q({0} ilbrqsi),
						'per' => q({0}/ilbrgba),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(toddobaad),
						'one' => q({0} tdbd),
						'other' => q({0} tdbd),
						'per' => q({0}/tdbdk),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(toddobaad),
						'one' => q({0} tdbd),
						'other' => q({0} tdbd),
						'per' => q({0}/tdbdk),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(sno),
						'one' => q(snd),
						'other' => q({0} snd),
						'per' => q({0}/sk),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(sno),
						'one' => q(snd),
						'other' => q({0} snd),
						'per' => q({0}/sk),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ambs),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ambs),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliambs),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliambs),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohmis),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohmis),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(fooltis),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(fooltis),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(HKB),
						'one' => q({0} Hkb),
						'other' => q({0} Hkb),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(HKB),
						'one' => q({0} Hkb),
						'other' => q({0} Hkb),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(Elektarofoolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(Elektarofoolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Kal),
						'one' => q({0} Kal),
						'other' => q({0} Kal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kal),
						'one' => q({0} Kal),
						'other' => q({0} Kal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(juules),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(juules),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokalooris),
						'one' => q({0} Kkal),
						'other' => q({0} Kkal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokalooris),
						'one' => q({0} Kkal),
						'other' => q({0} Kkal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kiilojuul),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kiilojuul),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(KW-saacad),
						'one' => q({0} KWs),
						'other' => q({0} KWs),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(KW-saacad),
						'one' => q({0} KWs),
						'other' => q({0} KWs),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(nuyuuton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(nuyuuton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(rodol xoog),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(rodol xoog),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(Dhibicyo),
						'one' => q({0} dhiibic),
						'other' => q({0} dhibicyo),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(Dhibicyo),
						'one' => q({0} dhiibic),
						'other' => q({0} dhibicyo),
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
						'name' => q(dhbi),
						'one' => q({0} dhbi),
						'other' => q({0} dhbi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dhbi),
						'one' => q({0} dhbi),
						'other' => q({0} dhbi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ux),
						'one' => q({0} ux),
						'other' => q({0} ux),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ux),
						'one' => q({0} ux),
						'other' => q({0} ux),
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
					'length-inch' => {
						'name' => q(injis),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(injis),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
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
						'name' => q(μmitir),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μmitir),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(meyl),
						'one' => q({0} my),
						'other' => q({0} my),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(meyl),
						'one' => q({0} my),
						'other' => q({0} my),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(smy),
						'one' => q({0} smy),
						'other' => q({0} smy),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(smy),
						'one' => q({0} smy),
						'other' => q({0} smy),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(nmy),
						'one' => q({0} nmy),
						'other' => q({0} nmy),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(nmy),
						'one' => q({0} nmy),
						'other' => q({0} nmy),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(bs),
						'one' => q({0} bs),
						'other' => q({0} bs),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(bs),
						'one' => q({0} bs),
						'other' => q({0} bs),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(bm),
						'one' => q({0} bm),
						'other' => q({0} bm),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(bm),
						'one' => q({0} bm),
						'other' => q({0} bm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(dhibco),
						'one' => q({0} dhbc),
						'other' => q({0} dhbc),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(dhibco),
						'one' => q({0} dhbc),
						'other' => q({0} dhbc),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(raadiyas qoraxeed),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(raadiyas qoraxeed),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yaardi),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yaardi),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(laks),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(laks),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(iftiinada qorraxda),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(iftiinada qorraxda),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karaats),
						'one' => q({0} KT),
						'other' => q({0} KT),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karaats),
						'one' => q({0} KT),
						'other' => q({0} KT),
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
						'name' => q(cufk Dhulka),
						'one' => q({0} CDh),
						'other' => q({0} CDh),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(cufk Dhulka),
						'one' => q({0} CDh),
						'other' => q({0} CDh),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(garaam),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(garaam),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ow),
						'one' => q({0} ow),
						'other' => q({0} ow),
						'per' => q({0}/ow),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ow),
						'one' => q({0} ow),
						'other' => q({0} ow),
						'per' => q({0}/ow),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(torooy ow),
						'one' => q({0} ow t),
						'other' => q({0} ow t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(torooy ow),
						'one' => q({0} ow t),
						'other' => q({0} ow t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(bownd),
						'one' => q({0} bw),
						'other' => q({0} bw),
						'per' => q({0}/bw),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(bownd),
						'one' => q({0} bw),
						'other' => q({0} bw),
						'per' => q({0}/bw),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(xufka qorraxda),
						'one' => q({0} CQ),
						'other' => q({0} CQ),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(xufka qorraxda),
						'one' => q({0} CQ),
						'other' => q({0} CQ),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tan),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tan),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hb),
						'one' => q({0} hb),
						'other' => q({0} hb),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hb),
						'one' => q({0} hb),
						'other' => q({0} hb),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(waat),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(waat),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hBa),
						'one' => q({0} hBa),
						'other' => q({0} hBa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hBa),
						'one' => q({0} hBa),
						'other' => q({0} hBa),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kBa),
						'one' => q({0} kBa),
						'other' => q({0} kBa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kBa),
						'one' => q({0} kBa),
						'other' => q({0} kBa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(Mba),
						'one' => q({0} Mba),
						'other' => q({0} Mba),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(Mba),
						'one' => q({0} Mba),
						'other' => q({0} Mba),
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
					'speed-kilometer-per-hour' => {
						'name' => q(km/saacadiiba),
						'one' => q({0} km/s),
						'other' => q({0} km/s),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/saacadiiba),
						'one' => q({0} km/s),
						'other' => q({0} km/s),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nt),
						'one' => q({0} nt),
						'other' => q({0} nt),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nt),
						'one' => q({0} nt),
						'other' => q({0} nt),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(mitir/ilbrqsi),
						'one' => q({0} m/i),
						'other' => q({0} m/i),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(mitir/ilbrqsi),
						'one' => q({0} m/i),
						'other' => q({0} m/i),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(meyl saacadiiba),
						'one' => q({0} my/s),
						'other' => q({0} my/s),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(meyl saacadiiba),
						'one' => q({0} my/s),
						'other' => q({0} my/s),
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
					'volume-acre-foot' => {
						'name' => q(akr ft),
						'one' => q({0} akr ft),
						'other' => q({0} akr ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(akr ft),
						'one' => q({0} akr ft),
						'other' => q({0} akr ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(foosto),
						'one' => q({0} fsto),
						'other' => q({0} fsto),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(foosto),
						'one' => q({0} fsto),
						'other' => q({0} fsto),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(cabirka bushels),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(cabirka bushels),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sL),
						'one' => q({0} sL),
						'other' => q({0} sL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sL),
						'one' => q({0} sL),
						'other' => q({0} sL),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(fiit³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(fiit³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inji³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inji³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(my³),
						'one' => q({0} my³),
						'other' => q({0} my³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(my³),
						'one' => q({0} my³),
						'other' => q({0} my³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yaardi³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yaardi³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(koob),
						'one' => q({0} k),
						'other' => q({0} k),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(koob),
						'one' => q({0} k),
						'other' => q({0} k),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mkob),
						'one' => q(mk),
						'other' => q({0} mk),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mkob),
						'one' => q(mk),
						'other' => q({0} mk),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dareere dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dareere dram),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(own dr),
						'one' => q({0} own dr),
						'other' => q({0} own dr),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(own dr),
						'one' => q({0} own dr),
						'other' => q({0} own dr),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(imb. owniska dareeraha),
						'one' => q({0} own dr imb.),
						'other' => q({0} own dr imb.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(imb. owniska dareeraha),
						'one' => q({0} own dr imb.),
						'other' => q({0} own dr imb.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(imb. gal),
						'one' => q({0} gal Imb.),
						'other' => q({0} gal Imb,),
						'per' => q({0}/gal Imb.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(imb. gal),
						'one' => q({0} gal Imb.),
						'other' => q({0} gal Imb,),
						'per' => q({0}/gal Imb.),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litar),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litar),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(bint),
						'one' => q({0} bt),
						'other' => q({0} bt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(bint),
						'one' => q({0} bt),
						'other' => q({0} bt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(mbt),
						'one' => q({0} mbt),
						'other' => q({0} mbt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(mbt),
						'one' => q({0} mbt),
						'other' => q({0} mbt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kts),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kts),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(mlqcd),
						'one' => q({0} mlqcd),
						'other' => q({0} mlqcd),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(mlqcd),
						'one' => q({0} mlqcd),
						'other' => q({0} mlqcd),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(mlqcd sh),
						'one' => q({0} mlqcd sh),
						'other' => q({0} mlqcd sh),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(mlqcd sh),
						'one' => q({0} mlqcd sh),
						'other' => q({0} mlqcd sh),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:haa|h|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:maya|m|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} iyo {1}),
				2 => q({0} iyo {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arab' => {
			'exponential' => q(E),
		},
		'arabext' => {
			'exponential' => q(E),
		},
		'bali' => {
			'nan' => q(NaN),
		},
		'cham' => {
			'nan' => q(NaN),
		},
		'fullwide' => {
			'superscriptingExponent' => q((^)),
		},
		'gong' => {
			'nan' => q(NaN),
		},
		'kali' => {
			'nan' => q(NaN),
		},
		'knda' => {
			'nan' => q(NaN),
		},
		'lana' => {
			'nan' => q(NaN),
		},
		'lanatham' => {
			'nan' => q(NaN),
		},
		'latn' => {
			'nan' => q(MaL),
		},
		'lepc' => {
			'nan' => q(NaN),
			'superscriptingExponent' => q((^)),
		},
		'limb' => {
			'nan' => q(NaN),
		},
		'mong' => {
			'nan' => q(NaN),
		},
		'mymr' => {
			'nan' => q(NaN),
		},
		'mymrshan' => {
			'nan' => q(NaN),
		},
		'osma' => {
			'superscriptingExponent' => q((^)),
		},
		'sund' => {
			'nan' => q(NaN),
		},
		'takr' => {
			'nan' => q(NaN),
		},
		'talu' => {
			'nan' => q(NaN),
		},
		'tamldec' => {
			'nan' => q(NaN),
		},
		'telu' => {
			'nan' => q(NaN),
		},
		'thai' => {
			'nan' => q(NaN),
		},
		'tibt' => {
			'nan' => q(NaN),
		},
		'vaii' => {
			'nan' => q(NaN),
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
					'one' => '0 kun',
					'other' => '0 Kun',
				},
				'10000' => {
					'one' => '00 Kun',
					'other' => '00 Kun',
				},
				'100000' => {
					'one' => '000 Kun',
					'other' => '000 Kun',
				},
				'1000000' => {
					'one' => '0 Milyan',
					'other' => '0 Milyan',
				},
				'10000000' => {
					'one' => '00 Milyan',
					'other' => '00 Milyan',
				},
				'100000000' => {
					'one' => '000 Milyan',
					'other' => '000 Milyan',
				},
				'1000000000' => {
					'one' => '0 Bilyan',
					'other' => '0 Bilyan',
				},
				'10000000000' => {
					'one' => '00 Bilyan',
					'other' => '00 Bilyan',
				},
				'100000000000' => {
					'one' => '000 Bilyan',
					'other' => '000 Bilyan',
				},
				'1000000000000' => {
					'one' => '0 Tirilyan',
					'other' => '0 Tirilyan',
				},
				'10000000000000' => {
					'one' => '00 Tirilyan',
					'other' => '00 Tirilyan',
				},
				'100000000000000' => {
					'one' => '000 Tirilyan',
					'other' => '000 Tirilyan',
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
				'currency' => q(Dirhamka Isutaga Imaaraatka Carabta),
				'one' => q(dirhamka Isutaga Imaaraatka Carabta),
				'other' => q(dirhamka Isutaga Imaaraatka Carabta),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afgan Afgani),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lekta Albaniya),
				'one' => q(lekta Abaniya),
				'other' => q(lekta Albaniya),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Daraamka Armeniya),
				'one' => q(daraamka Armeniya),
				'other' => q(daraamka Armeniya),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Galdarka Nadarlaan Antiliyaan),
				'one' => q(galdarka Nadarlaan Antiliyaan),
				'other' => q(galdarada Nadarlaan Antiliyaan),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kawansada Angola),
				'one' => q(kawansada Angola),
				'other' => q(kawansada Angola),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentine Austral),
				'one' => q(Argentine Austral),
				'other' => q(Argentine Australs),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Beesada Ley ee Arjentiin \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Beesada Ley ee Arjentiin \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Beesada Ley ee Arjentiin \(1883–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Beesada Arjentiin),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Doolarka Astaraaliya),
				'one' => q(doolarka Astaraaliya),
				'other' => q(doolarada Astaraaliya),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Foloorinta Aruban),
				'one' => q(foloorinta Aruban),
				'other' => q(foloorinta Aruban),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manaata Asarbeyjan),
				'one' => q(manaata Asarbeyjan),
				'other' => q(manaata Asarbeyjan),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Diinaarka BBosnia-Hersogofina 1.00 konfatibal maakta Bosnia-Hersogofina 1 konfatibal maaka Bosnia-Hersogofina \(1992–1994\)),
				'one' => q(Diinaarka BBosnia-Hersogofina \(1992–1994\)),
				'other' => q(Diinaarka BBosnia-Hersogofina 1.00 konfatibal maakta Bosnia-Hersogofina 1 konfatibal maaka Bosnia-Hersogofina \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Konfatibal Maakta Bosnia-Hersogofina),
				'one' => q(konfatibal maakta Bosnia-Hersogofina),
				'other' => q(konfatibal maakta Bosnia-Hersogofina),
			},
		},
		'BBD' => {
			symbol => 'DBB',
			display_name => {
				'currency' => q(Doolarka Barbaadiyaan),
				'one' => q(doolarka Barbaadiyaan),
				'other' => q(doolarada Barbaadiyaan),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka Bangledesh),
				'one' => q(taka Bangledesh),
				'other' => q(taka Bangledesh),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lefta Bulgariya),
				'one' => q(lefta Bulgariya),
				'other' => q(lefta Bulgariya),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinaarka Baxreyn),
				'one' => q(dinaarka Baxreyn),
				'other' => q(dinaarka Baxreyn),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Faranka Burundi),
				'one' => q(faranka Burundi),
				'other' => q(faranka Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Doolarka Barmuuda),
				'one' => q(doolarka Barmuuda),
				'other' => q(Doolarka Barmuuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Doolarka Buruney),
				'one' => q(doolarka Buruney),
				'other' => q(doolarada Buruney),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bolifiyanada Bolifiya),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Bolifiyaabka Bolifiyaano\(1863–1963\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Realka Barasil),
				'one' => q(Realka Barasil),
				'other' => q(Realada Barasil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Doolarka Bahamaas),
				'one' => q(doolarka Bahamaas),
				'other' => q(doolarada Bahamaas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Nugultaramta Butan),
				'one' => q(nugultaramta Butan),
				'other' => q(nugultaramta Butan),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Buulada Botswana),
				'one' => q(buulada Botswana),
				'other' => q(buulada Botswana),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Rubalka Belarus),
				'one' => q(rubalka Belarus),
				'other' => q(rubalka Belarus),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Doolarka Beelisa),
				'one' => q(doolarka Beelisa),
				'other' => q(doolarada Beelisa),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Doolarka Kanada),
				'one' => q(doolarka Kanada),
				'other' => q(doolarada Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Faranka Kongo),
				'one' => q(faranka Kongo),
				'other' => q(faranka Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Faranka Iswiska),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Beesada Jili),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuwanta Shiinaha \(Ofshoor\)),
				'one' => q(yuwanta Shiinaha \(Ofshoor\)),
				'other' => q(yuwanta Shiinaha \(Ofshoor\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuwanta Shiinaha),
				'one' => q(yuwanta Shiinaha),
				'other' => q(yuwanta Shiinaha),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Beesada Kolombiya),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Kolonka Kosta Riika),
				'one' => q(kolonka Kosta Riika),
				'other' => q(kolonka Kosta Riika),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Beesada Konfatibal ee Kuuba),
				'one' => q(beesada konfatibal ee Kuuba),
				'other' => q(beesada konfatibal ee Kuuba),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Beesada Kuuba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Eskudo Keyb Farde),
				'one' => q(eskudo Keyb Farde),
				'other' => q(eskudo Keyb Farde),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Korunada Jeek),
				'one' => q(korunada Jeek),
				'other' => q(korunada Jeek),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Faran Jabuuti),
				'one' => q(faranka Jabuuti),
				'other' => q(faranka Jabuuti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Koronka Danishka),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Beesada Dominiika),
				'one' => q(beesada Dominiika),
				'other' => q(beesada Dominiika),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinaarka Aljeriya),
				'one' => q(dinaarka Aljeriya),
				'other' => q(dinaarka Aljeriya),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Kroonka Estooniya),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Bowndka Masar),
				'one' => q(bowndka Masar),
				'other' => q(bowndka Masar),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfada Eritriya),
				'one' => q(nakfada Eritriya),
				'other' => q(nafkada Eritriya),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birta Itoobbiya),
				'one' => q(birta Itoobbiya),
				'other' => q(birta Itoobbiya),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yuuroo),
				'one' => q(yuuroo),
				'other' => q(yuuroo),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Markkada Fiinishka ah),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Doolarka Fiji),
				'one' => q(doolarka Fiji),
				'other' => q(doolarada Fiji),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Bowndka Faalklaan Aylaanis),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Bowndka Biritishka),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Laariga Joorjiya),
				'one' => q(laariga Joorjiya),
				'other' => q(laariga Joorjiya),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Sedida Gana),
				'one' => q(sedida Gana),
				'other' => q(sedida Gana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Bowndka Gibraltar),
				'one' => q(bowndka Gibraltar),
				'other' => q(bowndka Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasida Gambiya),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Faranka Gini),
				'one' => q(faranka Gini),
				'other' => q(faranka Gini),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Kuwestalka Guwatemala),
				'one' => q(kuwestalka Guwatemala),
				'other' => q(kuwestalka Guwatemala),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Doolarka Guyanes),
				'one' => q(Doolarka Guyanes),
				'other' => q(Doolarada Guyanes),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Doolarka Hoon Koon),
				'one' => q(Doolarada Hoon Koon),
				'other' => q(Doolarada Hoon Koon),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lembirada Honduras),
				'one' => q(lembirada Honduras),
				'other' => q(lembirada Honduras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kunada Korooshiya),
				'one' => q(kunada Korooshiya),
				'other' => q(kunada Korooshiya),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Goordada Hiyati),
				'one' => q(goordada Hiyati),
				'other' => q(goordada Hiyati),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Forintiska Hangari),
				'one' => q(forintiska Hangari),
				'other' => q(forintiska Hangari),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rubiah Indonesiya),
				'one' => q(rubiah Indonesiya),
				'other' => q(rubiah Indonesiya),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(baawnka Ayrishka),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Niyuu Shekelka Israaiil),
				'one' => q(niyuu shekelka Israaiil),
				'other' => q(niyuu shekelka Israaiil),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rubiga Hindiya),
				'one' => q(rubiga Hindiya),
				'other' => q(rubiga Hindiya),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinaarka Ciraaq),
				'one' => q(dinaarka Ciraaq),
				'other' => q(dinaarka Ciraaq),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Riyaalka Iran),
				'one' => q(riyaalka Iran),
				'other' => q(riyaalka Iran),
			},
		},
		'ISJ' => {
			display_name => {
				'one' => q(krónaha Iceland \(1918–1981\)),
				'other' => q(krónaha Iceland \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Koronada Eysland),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Doolarka Jamayka),
				'one' => q(doolarka Jamayka),
				'other' => q(doolarada Jamayka),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinaarka Urdun),
				'one' => q(dinaarka Urdun),
				'other' => q(dinaarka Urdun),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yenta Jabaan),
				'one' => q(yenta Jabaan),
				'other' => q(yenta Jabaan),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shilingka Kenya),
				'one' => q(shilingka Kenya),
				'other' => q(shilingka Kenya),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Somta Kiyrgiystan),
				'one' => q(somta Kiyriygstan),
				'other' => q(somta Kiyrgiystan),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riyf kambodiya),
				'one' => q(Riyf Kambodiya),
				'other' => q(Riyf kambodiya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Faranka Komoros),
				'one' => q(faranka Komoros),
				'other' => q(faranka Komoros),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Wonka Waqooyiga Kuuriya),
				'one' => q(wonka Waqooyiga Kuuriya),
				'other' => q(wonka Waqooyiga Kuuriya),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Wonka Koonfur Kuuriya),
				'one' => q(wonka Koonfur Kuuriya),
				'other' => q(wonka Koonfur Kuuriya),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinaarka Kuweyt),
				'one' => q(dinaarka Kuweyt),
				'other' => q(dinaarka Kuweyt),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Doolarka Kayman Aylaanis),
				'one' => q(doolarka Kayman Aylaanis),
				'other' => q(Doolarada Kayman Aylaanis),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tengeda Kasakhstan),
				'one' => q(tengeda Kasakhstan),
				'other' => q(tengeda Kasakhstan),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kib Laoti),
				'one' => q(kib Laoti),
				'other' => q(kib Laoti),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Bowndka Lubnaan),
				'one' => q(bowndka Lubnaan),
				'other' => q(Bowndka Lubnaan),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rubiga Siri lanka),
				'one' => q(rubiga Siri Lanka),
				'other' => q(rubiga Siri lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Doolarka Liberiya),
				'one' => q(doolarka Liberiya),
				'other' => q(doolarka Liberiya),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesotho Loti),
				'one' => q(Lesotho loti),
				'other' => q(Lesotho lotis),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Rubalka Latfiya),
				'one' => q(rubalka Latvia),
				'other' => q(rubalka Latfiya),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinaarka Libya),
				'one' => q(dinaarka Libya),
				'other' => q(dinaarka Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirhamka Moroko),
				'one' => q(dirhamka Moroko),
				'other' => q(dirhamka Moroko),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leeyuuda Moldofa),
				'one' => q(leeyuuda Moldofa),
				'other' => q(leeyuuda Moldofa),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Arayrida Madagaskar),
				'one' => q(arayrida Madagaskar),
				'other' => q(arayrida Madagaskar),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Denaarka Masedoniya),
				'one' => q(denaarka Masedoniya),
				'other' => q(denaarka Masedoniya),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kayatda Mayanmaar),
				'one' => q(kayatda Mayanmaar),
				'other' => q(kayatda Mayanmaar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrikta Mongoliya),
				'one' => q(tugrikta Mongoliya),
				'other' => q(tugrikta Mongoliya),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Bataka Makana),
				'one' => q(bataka Makana),
				'other' => q(bataka Makana),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Oogiya Mawritaniya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Oogiyada Mawritaaniya),
				'one' => q(oogiyada Mawritaniya),
				'other' => q(oogiyada Mawritaniya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rubiga Mowrishiya),
				'one' => q(rubiga Mowrishiya),
				'other' => q(rubiga Mowrishiya),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyada Maldifiya),
				'one' => q(rufiyada Maldifiya),
				'other' => q(rufiyada Maldifiya),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kawajada Malawi),
				'one' => q(kawajada Malawi),
				'other' => q(kawajada Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Beesada Meksiko),
				'one' => q(Beesada Meksiko),
				'other' => q(beesada Meksiko),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringitda Malayshiya),
				'one' => q(ringitda Malayshiya),
				'other' => q(ringitda Malayshiya),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metikalka Mosambik),
				'one' => q(metikalka Mosambik),
				'other' => q(Metikalka Mosambik),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Doolarka Namibiya),
				'one' => q(doolarka Namibiya),
				'other' => q(doolarka Namibiya),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nairada Neyjeeriya),
				'one' => q(nairada Neyjeeriya),
				'other' => q(nairada Neyjeeriya),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Kordobada Nikargow),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Koronka Norway),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rubiga Nebal),
				'one' => q(rubiga Nebal),
				'other' => q(rubiga Nebal),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Doolarka Niyuu Siyalaan),
				'one' => q(doolarka Niyuu siyalaan),
				'other' => q(doolarada Niyuu Siyalaan),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Riyaalka Cumaan),
				'one' => q(riyaalka Cumaan),
				'other' => q(riyaalka Cumaan),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balbow Banama),
				'one' => q(balbaw Banama),
				'other' => q(balbow Banama),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Solsha Beeru),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kinada Babua Niyuu Gini),
				'one' => q(kinada Babua Niyuu Gini),
				'other' => q(kinada Babua Niyuu Gini),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Biso Filibin),
				'one' => q(biso Filibin),
				'other' => q(biso Filibin),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rubiga Bakistan),
				'one' => q(rubiga Bakistan),
				'other' => q(rubiga Bakistan),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Solotida Bolaan),
				'one' => q(solotida Bolaan),
				'other' => q(solotida Bolaan),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guranida Baraguway),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Riyaalka Qatar),
				'one' => q(riyaalka Qatar),
				'other' => q(riyaalka Qatar),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Liyuuda Romaniya),
				'one' => q(liyuuda Romaniya),
				'other' => q(liyuuda Romaniya),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinaarka Serbiya),
				'one' => q(dinaarka Serbiya),
				'other' => q(dinaarka Serbiya),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rubalka Ruushka),
				'one' => q(rubalka Ruushka),
				'other' => q(rubalka Ruushka),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Faranka Ruwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyaalka Sacuudiga),
				'one' => q(Riyaalka Sacuudiga),
				'other' => q(riyaalka Sacuudiga),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Doolarka Solomon Aylaanis),
				'one' => q(doolarka Solomon Aylaanis),
				'other' => q(doolarada Solomon Aylaanis),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rubiga Siisalis),
				'one' => q(rubiga Siisalis),
				'other' => q(rubiga Siisalis),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Bowndka Suudaan),
				'one' => q(bowndka Suudaan),
				'other' => q(bowndka Suudaan),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Koronka Isweden),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Doolarka Singabuur),
				'one' => q(doolarka Singabuur),
				'other' => q(doolarka Singabuur),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Bowndka St Helen),
				'one' => q(bowndka St Helen),
				'other' => q(Bowndka St Helen),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leonka Sira Leon),
				'one' => q(leonka Sira Leon),
				'other' => q(leonka Sira Leon),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leonka Sira Leon \(1964—2022\)),
				'one' => q(leonka Sira Leon \(1964—2022\)),
				'other' => q(leonka Sira Leon \(1964—2022\)),
			},
		},
		'SOS' => {
			symbol => 'S',
			display_name => {
				'currency' => q(Shilingka Soomaaliya),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Doolarka Surinamees),
				'one' => q(Doolarka Surinamees),
				'other' => q(Doolarada Surinamees),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Bowndka Koonfurta Suudaan),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra Sao Tome & Birinsibi),
				'one' => q(dobrada Sao Tome Birinsibi),
				'other' => q(dobrada Sao Tome & Birinsibi),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Bowndka Suuriya),
				'one' => q(bowndka Suuriya),
				'other' => q(bowndka Suuriya),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeenida iswaasi),
				'one' => q(lilengeenida Iswaasi),
				'other' => q(lilangeenida iswaasi),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Baatka Taylaan),
				'one' => q(Baatda Taylaan),
				'other' => q(baatda Taylaan),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoonida Tajikistan),
				'one' => q(soomonida Tajikistan),
				'other' => q(somoonida Tajikistan),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manaata Turkmenistan),
				'one' => q(manaata Turkmenistan),
				'other' => q(manaata Turkmenistan),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinaarka Tunisiya),
				'one' => q(dinaarka Tunisiya),
				'other' => q(dinaarka Tunisiya),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Ba’angada Tonga),
				'one' => q(ba’angada Tonga),
				'other' => q(ba’angada Tonga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Liirada Turkiga),
				'one' => q(liirada Turkiga),
				'other' => q(liirada Turkiga),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Doolarka Tirinidad iyo Tobago),
				'one' => q(doolarka Tirinidad iyo Tobago),
				'other' => q(doolarada Tirinidad iyo Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Doolarka Taywaanta Cusub),
				'one' => q(doolarka Taywaanta Cusub),
				'other' => q(doolarada Taywaanta Cusub),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Shilingka Tansaaniya),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hirfiniyada Yukreeyn),
				'one' => q(hirfiniyada Yukreeyn),
				'other' => q(hirfiniyada Yukreeyn),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shilingka Yugandha),
				'one' => q(shilingka Yugandha),
				'other' => q(shilingka Yugandha),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Doolarka Mareeykanka),
				'one' => q(doolarka Mareeykanka),
				'other' => q(doolarada Mareeykanka),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Beesada Urugway),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Somta Usbekistan),
				'one' => q(somta Usbekistan),
				'other' => q(somta Usbekistan),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Bolifar Fenesuala \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bolifarada Fenesuwela),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dongta Fitnaam),
				'one' => q(dongta Fitnaam),
				'other' => q(dongta Fitnaam),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Fatu Fanuatu),
				'one' => q(fatu Fanuatu),
				'other' => q(fatu Fanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala Samao),
				'one' => q(tala Samao),
				'other' => q(tala Samao),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Faranka CFA ee Bartamaha Afrika),
				'one' => q(faranka CFA ee Bartamaha Afrika),
				'other' => q(faranka CFA ee Bartamaha Afrika),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Doolarka Iist Kaaribyan),
				'one' => q(doolarka Iist Kaaribyan),
				'other' => q(doolarada Iist Kaaribyan),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Faranka CFA Galbeedka Afrika),
				'one' => q(faranka CFA Galbeedka Afrika),
				'other' => q(faranka CFA Galbeedka Afrika),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Faranka CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Lacag aan la aqoon),
				'one' => q(\(halbeeg lacag aan la aqoon\)),
				'other' => q(\(Lacag aan la aqoon\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Riyaalka Yemen),
				'one' => q(riyaalka Yemen),
				'other' => q(riyaalka Yemen),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Randka Koonfur Afrika),
				'one' => q(randka Koonfur Afrika),
				'other' => q(randka Koonfur Afrika),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kawajada Sambiya),
				'one' => q(Kawaja Sambiya),
				'other' => q(Kawajada Sambiya),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'chinese' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Bisha1',
							'Bisha2',
							'Bisha3',
							'Bisha4',
							'Bisha5',
							'Bisha6',
							'Bisha7',
							'Bisha8',
							'Bisha9',
							'Bisha10',
							'Bisha11',
							'Bisha12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Bisha Koobaad',
							'bisha labaad',
							'bisha saddexaad',
							'bisha afaraad',
							'bisha shanaad',
							'bisha lixaad',
							'bisha todobaad',
							'bisha siddedad',
							'bisha sagaalad',
							'bisha tobnaad',
							'bisha kow iyo tobnaad',
							'bisha laba iyo tobnaad'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					wide => {
						nonleap => [
							'Bisha Koobaad',
							'Bisha Labaad',
							'Bisha Sadexaad',
							'Bisha Afraad',
							'Bisha Shanaad',
							'Bisha Lixaad',
							'Bisha Todabaad',
							'Bisha Sideedaad',
							'Bisha Sagaalaad',
							'Bisha Tobnaad',
							'Bisha Kow iyo Tobnaad',
							'Bisha laba iyo Tobnaad'
						],
						leap => [
							
						],
					},
				},
			},
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Jan',
							'Feb',
							'Mar',
							'Abr',
							'May',
							'Jun',
							'Lul',
							'Ogs',
							'Seb',
							'Okt',
							'Nof',
							'Dis'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Bisha Koobaad',
							'Bisha Labaad',
							'Bisha Saddexaad',
							'Bisha Afraad',
							'Bisha Shanaad',
							'Bisha Lixaad',
							'Bisha Todobaad',
							'Bisha Sideedaad',
							'Bisha Sagaalaad',
							'Bisha Tobnaad',
							'Bisha Kow iyo Tobnaad',
							'Bisha Laba iyo Tobnaad'
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
							'L',
							'O',
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
							'Jannaayo',
							'Febraayo',
							'Maarso',
							'Abriil',
							'May',
							'Juun',
							'Luuliyo',
							'Ogosto',
							'Sebteembar',
							'Oktoobar',
							'Noofeembar',
							'Diseembar'
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
							'Mux.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Jum. I',
							'Jum. II',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shaw.',
							'Dul’-Qicda.',
							'Dhuʻl-H.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Muxarram',
							'Safar',
							'Rabic al-awwal',
							'Rabic al-thani',
							'Jumada al-awwal',
							'jumada al-thani',
							'Rajab',
							'Shacban',
							'Ramadan',
							'Shawwal',
							'Dul al-qacda',
							'Dul xijjah'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Mux.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Jum. I',
							'Jum. II',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shaw.',
							'Dul-Q.',
							'Dul-X.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Muxarram',
							'Safar',
							'Rabic al-awwal',
							'Rabic al-thani',
							'Jumada al-awwal',
							'jumada al-thani',
							'Rajab',
							'Shacban',
							'Ramadan',
							'Shawwal',
							'Dul al-qacdah',
							'Dul xijjah'
						],
						leap => [
							
						],
					},
				},
			},
			'persian' => {
				'format' => {
					wide => {
						nonleap => [
							'Janaayo',
							'Feebraayo',
							'Maarso',
							'Abril',
							'Maayo',
							'Juun',
							'Luuliyo',
							'Agoosto',
							'Sabteembar',
							'Oktoobar',
							'Noofeembar',
							'Diiseembar'
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
						mon => 'Isn',
						tue => 'Tldo',
						wed => 'Arbc',
						thu => 'Khms',
						fri => 'Jmc',
						sat => 'Sbti',
						sun => 'Axd'
					},
					wide => {
						mon => 'Isniin',
						tue => 'Talaado',
						wed => 'Arbaco',
						thu => 'Khamiis',
						fri => 'Jimco',
						sat => 'Sabti',
						sun => 'Axad'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'I',
						tue => 'T',
						wed => 'A',
						thu => 'Kh',
						fri => 'J',
						sat => 'S',
						sun => 'A'
					},
					short => {
						mon => 'Isn',
						tue => 'Tldo',
						wed => 'Arbaco',
						thu => 'Khms',
						fri => 'Jmc',
						sat => 'Sbti',
						sun => 'Axd'
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
					abbreviated => {0 => 'R1',
						1 => 'R2',
						2 => 'R3',
						3 => 'R4'
					},
					wide => {0 => 'Rubaca 1aad',
						1 => 'Rubaca 2aad',
						2 => 'Rubaca 3aad',
						3 => 'Rubaca 4aad'
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
					'am' => q{GH},
					'pm' => q{GD},
				},
				'narrow' => {
					'am' => q{h},
					'pm' => q{d},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{AM},
					'pm' => q{GD},
				},
				'wide' => {
					'am' => q{GH},
					'pm' => q{GD},
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
		'chinese' => {
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'BC',
				'1' => 'AD'
			},
			narrow => {
				'0' => 'B',
				'1' => 'A'
			},
			wide => {
				'0' => 'Ciise Hortii',
				'1' => 'Ciise Dabadii'
			},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'Kahor R.O.C.',
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
		'buddhist' => {
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d, y},
			'long' => q{MMMM d, y},
			'medium' => q{dd-MMM-y},
			'short' => q{dd/MM/yy},
		},
		'hebrew' => {
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
		'indian' => {
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
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
		'buddhist' => {
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
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
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
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
		'buddhist' => {
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
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
		'hebrew' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'indian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
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
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			GyMd => q{M/d/y GGGGG},
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
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			GyMd => q{M/d/y GGGGG},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			MMMMW => q{'toddobaadka' W 'ee' MMMM},
			Md => q{M/d},
			hmsv => q{h:mm:ss a v},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{MMM d, y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'toddobaadka' w 'ee' Y},
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
		},
		'coptic' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'dangi' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
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
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				y => q{U MMM – U MMM},
			},
			yMMMEd => {
				M => q{U MMM d, E – MMM d, E},
				d => q{U MMM d, E – MMM d, E},
				y => q{U MMM d, E – U MMM d, E},
			},
			yMMMM => {
				y => q{U MMMM – U MMMM},
			},
			yMMMd => {
				M => q{U MMM d – MMM d},
				y => q{U MMM d – U MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
		'ethiopic' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
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
				y => q{y – y G},
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
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			yMd => {
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
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
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, dd MMM – E, dd MMM},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd–dd MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
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
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM dd – E, MMM dd, y},
				d => q{E, MMM dd – E, MMM dd, y},
				y => q{E, MMM dd, y – E, MMM dd, y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y},
				d => q{dd–dd MMM y},
				y => q{dd MMM y – dd MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
		'hebrew' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'indian' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'islamic' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'japanese' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'persian' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'roc' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
	} },
);

has 'cyclic_name_sets' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(guga ayaa bilaabmaya),
						1 => q(biyaha roobka),
						2 => q(xayayaan lakiciyay),
						3 => q(guga ekuinikis),
						4 => q(dhalaalaya cad na),
						5 => q(hadhuudha roobka),
						6 => q(jiilaalka ayaa bilaabmaya),
						7 => q(hadhuudh buuxda),
						8 => q(hadhuudh dhagta kujirta),
						9 => q(xaalka kulka),
						10 => q(kulayl yar),
						11 => q(kulayl weeyn),
						12 => q(daayrta ayaa bilaabmaysa),
						13 => q(dhamaadka kulaylka),
						14 => q(dhado cad),
						15 => q(ekuinokiska daayrta),
						16 => q(dhado qaboow),
						17 => q(baraf soo dhacaya),
						18 => q(qaboowbaha ayaa bilaabmaya),
						19 => q(baraf yar),
						20 => q(baraf weeyn),
						21 => q(qorax qabow),
						22 => q(qaboow yar),
						23 => q(qaboow weeyn),
					},
					'narrow' => {
						2 => q(cayayaan kacay),
						4 => q(dhalaalya cad na),
						6 => q(kulka ayaa bilaabmaya),
						8 => q(hadhuudh ku jirta dhagaha),
						9 => q(xaalada kulka),
						10 => q(kuleeyl yar),
						12 => q(deyrta ayaa bilaameeysa),
						18 => q(kulka ayaa bilaabmaya),
						19 => q(barafka yar),
						21 => q(xaalada qaboobaha),
						22 => q(qaboow weeyn),
					},
					'wide' => {
						2 => q(cayayaan lakiciyay),
						9 => q(xaalada kulka),
					},
				},
			},
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(Jiir),
						1 => q(Dibi),
						2 => q(Shabeel),
						3 => q(Bakeeyle),
						4 => q(Masduullaa),
						5 => q(Mas),
						6 => q(Faras),
						7 => q(Ri),
						8 => q(Daanyeer),
						9 => q(Diiq),
						10 => q(Eey),
						11 => q(Doofaar),
					},
					'wide' => {
						8 => q(daanyeer),
					},
				},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Waqtiga {0}),
		regionFormat => q(Waqtiga Dharaarta ee {0}),
		regionFormat => q(Waqtiga Caadiga Ah ee {0}),
		'Acre' => {
			long => {
				'daylight' => q#Wakhtiga Kulka ee Acre#,
				'generic' => q#Wakhtiga Acre#,
				'standard' => q#Wakhtiga Caadiga ah ee Acre#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Waqtiga Afggaanistaan#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjaan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akra#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Aljeeris#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamaako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Baagi#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisaaw#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Balantire#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Barasafil#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Qaahira#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kasabalaanka#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Seuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Conakri#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Daresalaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Jibuuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douaala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Ceyuun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Firiitawn#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gabroon#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Haraare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johansbaag#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kambaala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartuum#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Laagoos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Librefil#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Loom#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luwaanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbaashi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusaaka#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Mabuuto#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maseero#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mababaane#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Muqdisho#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrofiya#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nayroobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Injamina#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Nijame#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nookjot#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Wagadugu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Boorto-Noofo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Saw Toom#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tiribooli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tuunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhook#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Waqtiga Bartamaha Afrika#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Waqtiga Bariga Afrika#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Waqtiyada Caadiga Ah ee Koonfur Afrika#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Galbeedka Afrika#,
				'generic' => q#Waqtiga Galbeedka Afrika#,
				'standard' => q#Waqtiga Caadiga Ah ee Galbeedka Afrika#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Alaska#,
				'generic' => q#Waqtiga Alaska#,
				'standard' => q#Waqtiga Caadiga Ah ee Alaska#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Saacada Waqtiga Kulaylaha ee Almaty#,
				'generic' => q#Waqtiga Almaty#,
				'standard' => q#Waqtiga Caadiga ah ee Almaty#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Amason#,
				'generic' => q#Waqtiga Amason#,
				'standard' => q#Waqtiga Caadiga Ah ee Amason#,
			},
		},
		'America/Anchorage' => {
			exemplarCity => q#Anjorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguwila#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antiguwa#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguwayna#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Riyoja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Riyo Jalejos#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Juwaan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Luwis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tukuumaan#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaay#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunkiyon#,
		},
		'America/Bahia' => {
			exemplarCity => q#Baahiya#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahiya Banderas#,
		},
		'America/Belize' => {
			exemplarCity => q#Beliise#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Balank-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Bow Fista#,
		},
		'America/Boise' => {
			exemplarCity => q#Boyse#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buwenos Ayris#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kambiriij Baay#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Kaambo Garandi#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kaankuun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakaas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamaarka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kayeen#,
		},
		'America/Cayman' => {
			exemplarCity => q#Keymaan#,
		},
		'America/Chicago' => {
			exemplarCity => q#Jikaago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Jiwaahuu#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Magaalada Juarez#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokaan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kordooba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta Riika#,
		},
		'America/Creston' => {
			exemplarCity => q#Karestoon#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kuyaaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kurakoow#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Daanmaakshaan#,
		},
		'America/Dawson' => {
			exemplarCity => q#Doosan#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Doosan Kireek#,
		},
		'America/Denver' => {
			exemplarCity => q#Denfar#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detoroyt#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominiika#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Iiruneeb#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salfadoor#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Foot Nelson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Footalesa#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Galeys Baay#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Guus Baay#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Garaan Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Garenaada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guwadeluub#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guwatemaala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guwayaquwil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyaana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifakas#,
		},
		'America/Havana' => {
			exemplarCity => q#Hafaana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Harmosilo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Nokis, Indiyaana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Mareengo, Indiyaana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Betesbaag, Indiyaana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tel Siti, Indiyaana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Feefaay, Indiyaana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Finseenes, Indiyaana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winaamak, Indiyaana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indiyaanabolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuufik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Iqaaluut#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamayka#,
		},
		'America/Juneau' => {
			exemplarCity => q#Juniyuu#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Montiseelo, Kentaki#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kiraalendik#,
		},
		'America/La_Paz' => {
			exemplarCity => q#Laa Baas#,
		},
		'America/Lima' => {
			exemplarCity => q#Liima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Loos Anjalis#,
		},
		'America/Louisville' => {
			exemplarCity => q#Luusfile#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Loowa Birinses Kuwaata#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maasiiyo#,
		},
		'America/Managua' => {
			exemplarCity => q#Manaaguwa#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaauus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Maarigot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Maartiniikuyuu#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazaatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Meendoosa#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menoominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Meriida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlaakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Meksiko Siti#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Miiquulon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Moonktoon#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Moonteerey#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Moontafiidiyo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Moontseraat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nasaaw#,
		},
		'America/New_York' => {
			exemplarCity => q#Niyuu Yook#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nibiigoon#,
		},
		'America/Nome' => {
			exemplarCity => q#Noom#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Biyuulah, Waqooyiga Dakoota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Bartamaha, Waqooyiga Dakoota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Niyuu Saalem, Waqooyiga Dakoota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Banaama#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Bangnirtuung#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Foonikis#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Boort-aw-Biriins#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Boort of Isbayn#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Boorta Riiko#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Bunta Arinaas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Reyni Rifer#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Raankin Inleet#,
		},
		'America/Recife' => {
			exemplarCity => q#Receyf#,
		},
		'America/Regina' => {
			exemplarCity => q#Rejiina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resoluut#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Riyo Baraanko#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santareem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiyaago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Saanto Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Saaw Boolo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Itoqortoomiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Siitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Baartelemi#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. Joon#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St. Kitis#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St. Lusiya#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Toomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St. Finsent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Iswift Karent#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegusigalba#,
		},
		'America/Thule' => {
			exemplarCity => q#Tuul#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Tanda Baay#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tijuwaana#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortoola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Fankuufar#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Waythoras#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winibeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yakutaat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yelowneyf#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Bartamaha Waqooyiga Ameerika#,
				'generic' => q#Waqtiga Bartamaha Waqooyiga Ameerika#,
				'standard' => q#Waqtiga Caadiga Ah ee Bartamaha Waqooyiga Ameerika#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Bariga Waqooyiga Ameerika#,
				'generic' => q#Waqtiga Bariga ee Waqooyiga Ameerika#,
				'standard' => q#Waqtiga Caadiga Ah ee Bariga Waqooyiga Ameerika#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Buurleyda Waqooyiga Ameerika#,
				'generic' => q#Waqtiga Buuraleyda ee Waqooyiga Ameerika#,
				'standard' => q#Waqtiga Caadiga ah ee Buuraleyda Waqooyiga Ameerika#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Basifika Waqooyiga Ameerika#,
				'generic' => q#Waqtiga Basifika ee Waqooyiga Ameerika#,
				'standard' => q#Waqtiga Caadiga ah ee Basifika Waqooyiga Ameerika#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Wakhtiga Kulka ee Anadyr#,
				'generic' => q#Wakhtiga Anadyr#,
				'standard' => q#Wakhtiga Caadiga ah ee Anadyr#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Kaysee#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Dafis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’urfile#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makquwariy#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#MakMurdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Baamar#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rotera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Siyowa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Torool#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Fostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Abiya#,
				'generic' => q#Waqtiga Abiya#,
				'standard' => q#Waqtiga Caadiga Ah ee Abiya#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Saacada Waqtiga Kulaylaha Aqtau#,
				'generic' => q#Waqtiga Aqtau#,
				'standard' => q#Waqtiga Caadiga ah ee Aqtau#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Saacada Waqtiga kulaylaha Aqtobe#,
				'generic' => q#Waqtiga Aqtobe#,
				'standard' => q#Waqtiga Caadiga ah ee Aqtobe#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Carabta#,
				'generic' => q#Waqtiga Carabta#,
				'standard' => q#Waqtiga Caadiga Ah ee Carabta#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Lonjirbyeen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Arjentiina#,
				'generic' => q#Waqtia Arjentiina#,
				'standard' => q#Waqtiga Caadiga Ah ee Arjentiina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Galbeedka Arjentiina#,
				'generic' => q#Waqtiga Galbeedka Arjentiina#,
				'standard' => q#Waqtiga Caadiga Ah ee Galbeedka Arjentiina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Armeeniya#,
				'generic' => q#Waqtiga Armeeniya#,
				'standard' => q#Waqtiga Caadiga Ah ee Armeeniya#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Cadan#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almati#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Ammaan#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadiyr#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktaw#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atiyraw#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Baqdaad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Baxreyn#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkook#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaauul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beyruud#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Buruney#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkaata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Jiita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Joybalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Dimishiq#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dhaaka#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubay#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Qasa#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hoong Koong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hofud#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsik#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakaarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayabura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jeerusaalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kaabuul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamkatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karaaji#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandiyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Karasnoyarska#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lambuur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kujing#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuweyt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makow#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magedan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Maniila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosiya#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Nofokusnetsik#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Nofosibirsik#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Benom Ben#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Botiyaanak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Boyongyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Qaddar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qiyslorda#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyaad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Hoo Ji Mih Siti#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkaan#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Soul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghaay#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singabuur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Sarednokoleymisk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Teybey#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Toshkeent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tibilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tehraan#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Timbu#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Fiyaantiyaan#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Faladifostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakut#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterinbaag#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerefan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Atlantika Waqooyiga Ameerika#,
				'generic' => q#Waqtiga Atlantika ee Waqooyiga Ameerika#,
				'standard' => q#Waqtiga Caadiga Ah ee Atlantika Waqooyiga Ameerika#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Asores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Barmuuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanari#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Keyb Faarde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Farow#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjafik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Sowt Joorjiya#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Istaanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelayde#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Birisban#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Boroken Hil#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Kuriy#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Yukla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hubaart#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lod How#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melboon#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Bert#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Bartamaha Astaraaliya#,
				'generic' => q#Waqtiga Bartamaha Astaraaliya#,
				'standard' => q#Waqtiga Caadiga Ah ee Bartamaha Astaraaliya#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta Bartamaha Galbeedka Australiya#,
				'generic' => q#Waqtiga Bartamaha Galbeedka Astaraaliya#,
				'standard' => q#Waqtiga Caadiga Ah ee Bartamaha Galbeedka Astaraaliya#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Bariga Astaraaliya#,
				'generic' => q#Waqtiga Bariga Astaraaliya#,
				'standard' => q#Waqtiyada Caadiga ah ee Bariga Astaraaliya#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Galbeedka Astaraaliya#,
				'generic' => q#Waqtiga Galbeedka Astaraaliya#,
				'standard' => q#Waqtiga Caadiga Ah ee Galbeedka Astaraaliya#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Asarbeyjan#,
				'generic' => q#Waqtiga Asarbeyjan#,
				'standard' => q#Waqtiga Caadiga Ah ee Asarbeyjan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Asores#,
				'generic' => q#Waqtiga Asores#,
				'standard' => q#Waqtiga Caadiga Ah ee Asores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Bangledeesh#,
				'generic' => q#Waqtiga Bangledeesh#,
				'standard' => q#Waqtiga Caadiga Ah ee Bangledeesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Waqtiga Butaan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Waqtiga Boliifiya#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Baraasiliya#,
				'generic' => q#Waqtiga Baraasiliya#,
				'standard' => q#Waqtiga Caadiga ah ee Baraasiliya#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Waqtiga Buruney Daarusalaam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Keyb Faarde#,
				'generic' => q#Waqtiga Keyb Faarde#,
				'standard' => q#Waqtiga Caadiga Ah ee Keyb Faarde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Waqtiga Jamoro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Jaatam#,
				'generic' => q#Waqtiga Jaatam#,
				'standard' => q#Waqtiga Caadiga Ah ee Jaatam#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Jili#,
				'generic' => q#Waqtiga Jili#,
				'standard' => q#Waqtiga Caadiga Ah ee Jili#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Shiinaha#,
				'generic' => q#Waqtiga Shiinaha#,
				'standard' => q#Waqtiga Caadiga Ah ee Shiinaha#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Joybalsan#,
				'generic' => q#Waqtiga Joybalsan#,
				'standard' => q#Waqtiga Caadiga Ah ee Joybalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Waqtiga Kirismas Aylaan#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Waqtiga Kokos Aylaan#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Kolambiya#,
				'generic' => q#Waqtiga Kolambiya#,
				'standard' => q#Waqtiga Caadiga Ah ee Kolambiya#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Waqtiga Nus Xagaaga ah ee Kuuk Aylaanis#,
				'generic' => q#Waqtiga Kuuk Aylaanis#,
				'standard' => q#Waqtiga Caadiga Ah ee Kuuk Aylaanis#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Kuuba#,
				'generic' => q#Waqtiga Kuuba#,
				'standard' => q#Waqtiga Caadiga Ah ee Kuuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Waqtiga Dafis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Waqtiga Dumont - d’urfille#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Waqtiga Iist Timoor#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Iistar Aylaan#,
				'generic' => q#Waqtiga Iistar Aylaan#,
				'standard' => q#Waqtiga Caadiga Ah ee Iistar Aylaan#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Waqtiga Ekuwadoor#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Waqtiga Isku-xiran ee Caalamka#,
			},
			short => {
				'standard' => q#Waqtiga UTC#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Magaalo Aan La Garanayn#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdaam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andoora#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astarakhaan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atens#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgaraydh#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Barliin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Baratislafa#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Barasalis#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bujarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budabest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingeen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Jisinaaw#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kobenhaagan#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dhaablin#,
			long => {
				'daylight' => q#Waqtiga Caadiga Ah ee Ayrishka#,
			},
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Geernisi#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Heleniski#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ayle of Maan#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbuul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jaarsey#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiyeef#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kiroof#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lubalaana#,
		},
		'Europe/London' => {
			exemplarCity => q#Landan#,
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Biritishka#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksemberg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madriid#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Maarihaam#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minisk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskow#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Baariis#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Bodgorika#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Baraag#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riija#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rooma#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Mariino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarayeefo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratoof#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferobol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Iskoobje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofiya#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Istokhoom#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Taalin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tiraane#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanofisk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Usgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Faduus#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Fatikaan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Fiyeena#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Finiyuus#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Folgograd#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Saqrib#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Saborosey#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Suurikh#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Bartamaha Yurub#,
				'generic' => q#Waqtiga Bartamaha Yurub#,
				'standard' => q#Waqtiga Caadiga Ah ee Bartamaha Yurub#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Bariga Yurub#,
				'generic' => q#Waqtiga Bariga Yurub#,
				'standard' => q#Waqtiga Caadiga Ah ee Bariga Yurub#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Waqtiga Bariga Fog ee Yurub#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Galbeedka Yurub#,
				'generic' => q#Waqtiga Galbeedka Yurub#,
				'standard' => q#Waqtiga Caadiga Ah ee Galbeedka Yurub#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Faalklaan Aylaanis#,
				'generic' => q#Waqtiga Faalklaan Aylaanis#,
				'standard' => q#Waqtiga Caadiga Ah ee Faalklaan Aylaanis#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Fiji#,
				'generic' => q#Waqtiga Fiji#,
				'standard' => q#Waqtiga Caadiga Ah ee Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Waqtiga Ferenj Guyana#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Waqtiga Koonfurta Faransiiska & Antaarktik#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Wakhtiga Giriinwij#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Waqtiga Galabagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Waqtiga Gambiyar#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Joorjiya#,
				'generic' => q#Waqtiga Joorjiya#,
				'standard' => q#Waqtiga Caadiga Ah ee Joorjiya#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Waqtiga Jilbeert Aylaan#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Bariga Giriinlaan#,
				'generic' => q#Waqtiga Bariga ee Giriinlaan#,
				'standard' => q#Waqtiga Caadiga ah ee Bariga Giriinlaan#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Galbeedka Giriinlaan#,
				'generic' => q#Waqtiga Galbeedka Giriinlaan#,
				'standard' => q#Waqtiga Caadiga Ah ee Galbeedka Giriinlaan#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Waqtiga Gacanka#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Waqtiga Guyaana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Hawaay-Alutiyaan#,
				'generic' => q#Waqtiga Hawaay-Alutiyaan#,
				'standard' => q#Waqtiga Caadiga Ah ee Hawaay-Alutiyaan#,
			},
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAST#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Hoong Koong#,
				'generic' => q#Waqtiga Hoong Koong#,
				'standard' => q#Waqtiga Caadiga Ah ee Hoong Koong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Hofud#,
				'generic' => q#Waqtiga Hofud#,
				'standard' => q#Waqtiga Caadiga Ah ee Hofud#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Waqtiga Caadiga Ah ee Hindiya#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarifo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Jagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Kiristmas#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoro#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kergalen#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldifis#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Morishiyaas#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayoote#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Riyuuniyon#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Waqtiga Badweynta Hindiya#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Waqtiga Indoshiina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Waqtiga Bartamaha Indoneeysiya#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Waqtiga Indoneeysiya#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Waqtiga Galbeedka Indoneeysiya#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Iiraan#,
				'generic' => q#Waqtiga Iiraan#,
				'standard' => q#Waqtiga Caadiga Ah ee Iiraan#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Irkutsik#,
				'generic' => q#Waqtiga Irkutsik#,
				'standard' => q#Waqtiga Caadiga Ah ee Irkutsik#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Israaiil#,
				'generic' => q#Waqtiga Israaiil#,
				'standard' => q#Waqtiga Caadiga Ah ee Israaiil#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Jabaan#,
				'generic' => q#Waqtiga Jabaan#,
				'standard' => q#Waqtiga Caadiga Ah ee Jabaan#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Wakhtiga Kulka ee Petropavlovsk-Kamchatski#,
				'generic' => q#Wakhtiga Petropavlovsk-Kamchatski#,
				'standard' => q#Wakhtiga Caadiga ah ee Petropavlovsk-Kamchatski#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Waqtiga Bariga Kasakhistaan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Waqtiga Koonfurta Kasakhistan#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Kuuriya#,
				'generic' => q#Waqtiga Kuuriya#,
				'standard' => q#Waqtiga Caadiga Ah ee Kuuriya#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Waqtiga Kosriy#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Karasnoyarsik#,
				'generic' => q#Waqtiga Karasnoyarsik#,
				'standard' => q#Waqtiga Caadiga Ah ee Karasnoyarsik#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Waqtiga Kiyrigistaan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Waqtiga Leyn Aylaan#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Lod How#,
				'generic' => q#Waqtiga Lod How#,
				'standard' => q#Waqtiga Caadiga Ah ee Lod How#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Waqtiga Makquwariy Aylaan#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Magedan#,
				'generic' => q#Watiga Magedan#,
				'standard' => q#Waqtiga Caadiga Ah ee Magedan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Waqtiga Maleyshiya#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Waqtiga Maldifis#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Waqtiga Marquwesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Waqtiga Maarshaal Aylaanis#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Morishiyaas#,
				'generic' => q#Waqtiga Morishiyaas#,
				'standard' => q#Waqtiga Caadiga Ah ee Morishiyaas#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Waqtiga Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Waqooyi-Galbeed Meksiko#,
				'generic' => q#Waqtiga Waqooyi-Galbeed Meksiko#,
				'standard' => q#Waqtiga Caadiga Ah ee Waqooyi-Galbeed Meksiko#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Baasifikada Meksiko#,
				'generic' => q#Waqtiga Baasifikada Meksiko#,
				'standard' => q#Waqtiga Caadiga Ah ee Baasifikada Meksiko#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Ulaanbaataar#,
				'generic' => q#Waqtiga Ulaanbaataar#,
				'standard' => q#Waqtiga Caadiga Ah ee Ulaanbaataar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Moskow#,
				'generic' => q#Waqtiga Moskow#,
				'standard' => q#Waqtiga Caadiga Ah ee Moskow#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Waqtiga Mayanmaar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Waqtiga Nawroo#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Waqtiga Neebaal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Niyuu Kaledoniya#,
				'generic' => q#Waqtiga Niyuu Kaledonya#,
				'standard' => q#Waqtiga Caadiga Ah ee Niyuu Kaledoniya#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Niyuu Si’laan#,
				'generic' => q#Waqtiga Niyuu Si’laan#,
				'standard' => q#Waqtiga Caadiga Ah ee Niyuu Si’laan#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Niyuufoonlaan#,
				'generic' => q#Waqtiga Niyuufoonlaan#,
				'standard' => q#Waqtiga Caadiga Ah ee Niyuufoonlaan#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Waqtiga Niyuu#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Waqtiga Maalinta ee Norfolk Island#,
				'generic' => q#Waqtiga Norfolk Island#,
				'standard' => q#Waqtiga Caadiga ah ee Norfolk Island#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Farnaando de Nooronha#,
				'generic' => q#Waqtiga Farnaando de Noronha#,
				'standard' => q#Waqtiga Caadiga Ah ee Farnaando de Nooronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Nofosibirsik#,
				'generic' => q#Waqtiga Nofosibirsik#,
				'standard' => q#Waqtiga Caadiga Ah ee Nofosibirsik#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Omsk#,
				'generic' => q#Waqtiga Omsk#,
				'standard' => q#Waqtiga Caadiga Ah ee Omsk#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Abiya#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Owklaan#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Boogaynfil#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Jatam#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Iistar#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderburi#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#fakofo#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galabagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambiyr#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Cuadalkanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guwam#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Joonston#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#Kantoon#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimaati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosrii#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kuwajaleyn#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marquwesas#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nawroo#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niyuu#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Noorfek#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Noomiya#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Bago Bago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Balaw#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Bitkayrn#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Bonbey#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Boort Moresbi#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Seyban#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatabu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Juuk#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Walis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Bakistaan#,
				'generic' => q#Waqtiga Bakistaan#,
				'standard' => q#Waqtiga Caadiga Ah ee Bakistaan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Waqtiga Balaw#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Waqtiga Babuw Niyuu Giniya#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Baragwaay#,
				'generic' => q#Waqtiga Baragwaay#,
				'standard' => q#Waqtiga Caadiga Ah ee Baragwaay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Beeru#,
				'generic' => q#Waqtiga Beeru#,
				'standard' => q#Waqtiga Caadiga Ah ee Beeru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Filibiin#,
				'generic' => q#Waqtiga Filibiin#,
				'standard' => q#Waqtiga Caadiga Ah ee Filibiin#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Waqtiga Foonikis Aylaanis#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee St. Beere & Mikiwelon#,
				'generic' => q#Waqtiga St. Beere & Mikiwelon#,
				'standard' => q#Waqtiga Caadiga Ah St. Beere & Mikiwelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Waqtiga Bitkeen#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Waqtiga Bonabe#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Waqtiga Boyongyang#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Saacada Waqtiga Kulaylaha Qyzylorda#,
				'generic' => q#Waqtiga Qyzylorda#,
				'standard' => q#Waqtiga Caadiga ah ee Qyzylorda#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Waqtiga Riyuuniyon#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Waqtiga Rotera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Sakhalin#,
				'generic' => q#Waqtiga Sakhalin#,
				'standard' => q#Waqtiga Caadiga Ah ee Sakhalin#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Wakhtiga Kulka ee Samara#,
				'generic' => q#Wakhtiga Samara#,
				'standard' => q#Wakhtiga Caadiga ah ee Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Samoa#,
				'generic' => q#Waqtiga Samoa#,
				'standard' => q#Waqtiga Caadiga Ah ee Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Waqtiga Siishalis#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Waqtiga Singabuur#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Waqtiga Solomon Aylaanis#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Waqtiga Sowt Joorjiya#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Waqtiga Surineym#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Waqtiga Siyowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Waqtiga Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Waqtiga Dharaarta ee Teybey#,
				'generic' => q#Waqtiga Teybey#,
				'standard' => q#Waqtiga Caadiga Ah ee Teybey#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Waqtiga Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Waqtiga Tokeluu#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Tonga#,
				'generic' => q#Waqtiga Tonga#,
				'standard' => q#Waqtiga Caadiga Ah ee Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Waqtiga Juuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Turkmenistan#,
				'generic' => q#Waqtiga Turkmenistaan#,
				'standard' => q#Waqtiga Caadiga Ah ee Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Waqtiga Tufalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Urugwaay#,
				'generic' => q#Waqtiga Urugwaay#,
				'standard' => q#Waqtiga Caadiga Ah ee Urugwaay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Usbekistan#,
				'generic' => q#Waqtiga Usbekistan#,
				'standard' => q#Waqtiga Caadiga Ah ee Usbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Fanuutu#,
				'generic' => q#Waqtiga Fanuutu#,
				'standard' => q#Waqtiga Caadiga Ah ee Fanuutu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Waqtiga Fenezuweela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Faladifostok#,
				'generic' => q#Waqtiga Faladifostok#,
				'standard' => q#Waqtiga Caadiga Ah ee Faladifostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Folgograd#,
				'generic' => q#Waqtiga Folgograd#,
				'standard' => q#Waqtiga Caadiga Ah ee Folgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Waqtiga Fostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Waqtiga Wayk Iylaanis#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Waqtiga Walis & Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Yakut#,
				'generic' => q#Waqtiyada Yakut#,
				'standard' => q#Waqtiga Caadiga Ah ee Yakut#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Waqtiga Xagaaga ee Yekaterinbaag#,
				'generic' => q#Waqtiga Yekaterinbaag#,
				'standard' => q#Waqtiga Caadiga Ah ee Yekaterinbaag#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Waqtiga Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
