=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Uz - Package for language Uzbek

=cut

package Locale::CLDR::Locales::Uz;
# This file auto generated from Data\common\main\uz.xml
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
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'afar',
 				'ab' => 'abxaz',
 				'ace' => 'achin',
 				'ada' => 'adangme',
 				'ady' => 'adigey',
 				'af' => 'afrikaans',
 				'agq' => 'agem',
 				'ain' => 'aynu',
 				'ak' => 'akan',
 				'ale' => 'aleut',
 				'alt' => 'janubiy oltoy',
 				'am' => 'amxar',
 				'an' => 'aragon',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'arab',
 				'ar_001' => 'standart arab',
 				'arn' => 'mapuche',
 				'arp' => 'arapaxo',
 				'ars' => 'najd arab',
 				'as' => 'assam',
 				'asa' => 'asu',
 				'ast' => 'asturiy',
 				'atj' => 'atikamek',
 				'av' => 'avar',
 				'awa' => 'avadxi',
 				'ay' => 'aymara',
 				'az' => 'ozarbayjon',
 				'az@alt=short' => 'ozar',
 				'ba' => 'boshqird',
 				'ban' => 'bali',
 				'bas' => 'basa',
 				'be' => 'belarus',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'bolgar',
 				'bgc' => 'harianvi',
 				'bgn' => 'g‘arbiy baluj',
 				'bho' => 'bxojpuri',
 				'bi' => 'bislama',
 				'bin' => 'bini',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bengal',
 				'bo' => 'tibet',
 				'br' => 'breton',
 				'brx' => 'bodo',
 				'bs' => 'bosniy',
 				'bug' => 'bugi',
 				'byn' => 'blin',
 				'ca' => 'katalan',
 				'cay' => 'kayuga',
 				'ccp' => 'chakma',
 				'ce' => 'chechen',
 				'ceb' => 'sebuan',
 				'cgg' => 'chiga',
 				'ch' => 'chamorro',
 				'chk' => 'chukot',
 				'chm' => 'mari',
 				'cho' => 'choktav',
 				'chp' => 'chipevyan',
 				'chr' => 'cheroki',
 				'chy' => 'cheyenn',
 				'ckb' => 'sorani-kurd',
 				'clc' => 'chilkotin',
 				'co' => 'korsikan',
 				'crg' => 'michif',
 				'crj' => 'janubi-sharqiy kri',
 				'crk' => 'tekislik kri',
 				'crl' => 'shomoli-sharqiy kri',
 				'crm' => 'mus kri',
 				'crr' => 'karolin algonkin',
 				'crs' => 'kreol (Seyshel)',
 				'cs' => 'chex',
 				'csw' => 'botqoq kri',
 				'cu' => 'slavyan (cherkov)',
 				'cv' => 'chuvash',
 				'cy' => 'valliy',
 				'da' => 'dan',
 				'dak' => 'dakota',
 				'dar' => 'dargva',
 				'dav' => 'taita',
 				'de' => 'nemischa',
 				'de_AT' => 'nemis (Avstriya)',
 				'de_CH' => 'yuqori nemis (Shveytsariya)',
 				'dgr' => 'dogrib',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'quyi sorb',
 				'dua' => 'duala',
 				'dv' => 'divexi',
 				'dyo' => 'diola-fogni',
 				'dz' => 'dzongka',
 				'dzg' => 'dazag',
 				'ebu' => 'embu',
 				'ee' => 'eve',
 				'efi' => 'efik',
 				'eka' => 'ekajuk',
 				'el' => 'grek',
 				'en' => 'inglizcha',
 				'en_AU' => 'ingliz (Avstraliya)',
 				'en_CA' => 'ingliz (Kanada)',
 				'en_GB' => 'ingliz (Britaniya)',
 				'en_GB@alt=short' => 'ingliz (Buyuk Britaniya)',
 				'en_US' => 'ingliz (Amerika)',
 				'en_US@alt=short' => 'ingliz (AQSH)',
 				'eo' => 'esperanto',
 				'es' => 'ispancha',
 				'es_419' => 'ispan (Lotin Amerikasi)',
 				'es_ES' => 'ispan (Yevropa)',
 				'es_MX' => 'ispan (Meksika)',
 				'et' => 'estoncha',
 				'eu' => 'bask',
 				'ewo' => 'evondo',
 				'fa' => 'fors',
 				'fa_AF' => 'dari',
 				'ff' => 'fula',
 				'fi' => 'fincha',
 				'fil' => 'filipincha',
 				'fj' => 'fiji',
 				'fo' => 'farercha',
 				'fon' => 'fon',
 				'fr' => 'fransuzcha',
 				'fr_CA' => 'fransuz (Kanada)',
 				'fr_CH' => 'fransuz (Shveytsariya)',
 				'frc' => 'kajun fransuz',
 				'frr' => 'shimoliy friz',
 				'fur' => 'friul',
 				'fy' => 'g‘arbiy friz',
 				'ga' => 'irland',
 				'gaa' => 'ga',
 				'gag' => 'gagauz',
 				'gan' => 'gan',
 				'gd' => 'shotland-gel',
 				'gez' => 'geez',
 				'gil' => 'gilbert',
 				'gl' => 'galisiy',
 				'gn' => 'guarani',
 				'gor' => 'gorontalo',
 				'gsw' => 'nemis (Shveytsariya)',
 				'gu' => 'gujarot',
 				'guz' => 'gusii',
 				'gv' => 'men',
 				'gwi' => 'gvichin',
 				'ha' => 'xausa',
 				'hai' => 'hayda',
 				'haw' => 'gavaycha',
 				'hax' => 'janubiy hayda',
 				'he' => 'ivrit',
 				'hi' => 'hind',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hil' => 'hiligaynon',
 				'hmn' => 'xmong',
 				'hr' => 'xorvat',
 				'hsb' => 'yuqori sorb',
 				'ht' => 'gaityan',
 				'hu' => 'venger',
 				'hup' => 'xupa',
 				'hur' => 'halkomelem',
 				'hy' => 'arman',
 				'hz' => 'gerero',
 				'ia' => 'interlingva',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonez',
 				'ig' => 'igbo',
 				'ii' => 'sichuan',
 				'ikt' => 'sharqiy-kanada inuktitut',
 				'ilo' => 'iloko',
 				'inh' => 'ingush',
 				'io' => 'ido',
 				'is' => 'island',
 				'it' => 'italyan',
 				'iu' => 'inuktitut',
 				'ja' => 'yapon',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jv' => 'yavan',
 				'ka' => 'gruzincha',
 				'kab' => 'kabil',
 				'kac' => 'kachin',
 				'kaj' => 'kaji',
 				'kam' => 'kamba',
 				'kbd' => 'kabardin',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'kabuverdianu',
 				'kfo' => 'koro',
 				'kgp' => 'kaingang',
 				'kha' => 'kxasi',
 				'khq' => 'koyra-chiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kvanyama',
 				'kk' => 'qozoqcha',
 				'kkj' => 'kako',
 				'kl' => 'grenland',
 				'kln' => 'kalenjin',
 				'km' => 'xmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'koreyscha',
 				'koi' => 'komi-permyak',
 				'kok' => 'konkan',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'qorachoy-bolqor',
 				'krl' => 'karel',
 				'kru' => 'kurux',
 				'ks' => 'kashmircha',
 				'ksb' => 'shambala',
 				'ksf' => 'bafiya',
 				'ksh' => 'kyoln',
 				'ku' => 'kurdcha',
 				'kum' => 'qo‘miq',
 				'kv' => 'komi',
 				'kw' => 'korn',
 				'kwk' => 'kvakvala',
 				'ky' => 'qirgʻizcha',
 				'la' => 'lotincha',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lb' => 'lyuksemburgcha',
 				'lez' => 'lezgin',
 				'lg' => 'ganda',
 				'li' => 'limburg',
 				'lil' => 'lilluet',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'laos',
 				'lou' => 'luiziana kreol',
 				'loz' => 'lozi',
 				'lrc' => 'shimoliy luri',
 				'lsm' => 'saamia',
 				'lt' => 'litva',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'lushay',
 				'luy' => 'luhya',
 				'lv' => 'latishcha',
 				'mad' => 'madur',
 				'mag' => 'magahi',
 				'mai' => 'maythili',
 				'mak' => 'makasar',
 				'mas' => 'masay',
 				'mdf' => 'moksha',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'morisyen',
 				'mg' => 'malagasiy',
 				'mgh' => 'maxuva-mitto',
 				'mgo' => 'meta',
 				'mh' => 'marshall',
 				'mi' => 'maori',
 				'mic' => 'mikmak',
 				'min' => 'minangkabau',
 				'mk' => 'makedon',
 				'ml' => 'malayalam',
 				'mn' => 'mongol',
 				'mni' => 'manipur',
 				'moe' => 'innu-aymun',
 				'moh' => 'mohauk',
 				'mos' => 'mossi',
 				'mr' => 'maratxi',
 				'ms' => 'malay',
 				'mt' => 'maltiy',
 				'mua' => 'mundang',
 				'mul' => 'bir nechta til',
 				'mus' => 'krik',
 				'mwl' => 'miranda',
 				'my' => 'birman',
 				'myv' => 'erzya',
 				'mzn' => 'mozandaron',
 				'na' => 'nauru',
 				'nap' => 'neapolitan',
 				'naq' => 'nama',
 				'nb' => 'norveg-bokmal',
 				'nd' => 'shimoliy ndebele',
 				'nds' => 'quyi nemis',
 				'nds_NL' => 'quyi sakson',
 				'ne' => 'nepal',
 				'new' => 'nevar',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niue',
 				'nl' => 'niderland',
 				'nl_BE' => 'flamand',
 				'nmg' => 'kvasio',
 				'nn' => 'norveg-nyunorsk',
 				'nnh' => 'ngiyembun',
 				'no' => 'norveg',
 				'nog' => 'no‘g‘ay',
 				'nqo' => 'nko',
 				'nr' => 'janubiy ndebel',
 				'nso' => 'shimoliy soto',
 				'nus' => 'nuer',
 				'nv' => 'navaxo',
 				'ny' => 'cheva',
 				'nyn' => 'nyankole',
 				'oc' => 'oksitan',
 				'ojb' => 'shimoli-gʻarbiy ojibva',
 				'ojc' => 'markaziy ijibve',
 				'ojs' => 'oji-kri',
 				'ojw' => 'gʻarbiy ojibva',
 				'oka' => 'okanagan',
 				'om' => 'oromo',
 				'or' => 'oriya',
 				'os' => 'osetin',
 				'pa' => 'panjobcha',
 				'pag' => 'pangasinan',
 				'pam' => 'pampanga',
 				'pap' => 'papiyamento',
 				'pau' => 'palau',
 				'pcm' => 'kreol (Nigeriya)',
 				'pis' => 'pijin',
 				'pl' => 'polyakcha',
 				'pqm' => 'maliset-passamakvoddi',
 				'prg' => 'pruss',
 				'ps' => 'pushtu',
 				'pt' => 'portugalcha',
 				'pt_BR' => 'portugal (Braziliya)',
 				'pt_PT' => 'portugal (Yevropa)',
 				'qu' => 'kechua',
 				'quc' => 'kiche',
 				'raj' => 'rajastani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotongan',
 				'rhg' => 'rohinja',
 				'rm' => 'romansh',
 				'rn' => 'rundi',
 				'ro' => 'rumincha',
 				'ro_MD' => 'moldovan',
 				'rof' => 'rombo',
 				'ru' => 'ruscha',
 				'rup' => 'arumin',
 				'rw' => 'kinyaruanda',
 				'rwk' => 'ruanda',
 				'sa' => 'sanskrit',
 				'sad' => 'sandave',
 				'sah' => 'saxa',
 				'saq' => 'samburu',
 				'sat' => 'santali',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardin',
 				'scn' => 'sitsiliya',
 				'sco' => 'shotland',
 				'sd' => 'sindhi',
 				'sdh' => 'janubiy kurd',
 				'se' => 'shimoliy saam',
 				'seh' => 'sena',
 				'ses' => 'koyraboro-senni',
 				'sg' => 'sango',
 				'shi' => 'tashelxit',
 				'shn' => 'shan',
 				'si' => 'singal',
 				'sk' => 'slovakcha',
 				'sl' => 'slovencha',
 				'slh' => 'janubiy lushutsid',
 				'sm' => 'samoa',
 				'sma' => 'janubiy saam',
 				'smj' => 'lule-saam',
 				'smn' => 'inari-saam',
 				'sms' => 'skolt-saam',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somalicha',
 				'sq' => 'alban',
 				'sr' => 'serbcha',
 				'srn' => 'sranan-tongo',
 				'ss' => 'svati',
 				'ssy' => 'saho',
 				'st' => 'janubiy soto',
 				'str' => 'streyts salish',
 				'su' => 'sundan',
 				'suk' => 'sukuma',
 				'sv' => 'shved',
 				'sw' => 'suaxili',
 				'sw_CD' => 'suaxili (Kongo)',
 				'swb' => 'qamar',
 				'syr' => 'suriyacha',
 				'ta' => 'tamil',
 				'tce' => 'janubiy tutchone',
 				'te' => 'telugu',
 				'tem' => 'timne',
 				'teo' => 'teso',
 				'tet' => 'tetum',
 				'tg' => 'tojik',
 				'tgx' => 'tagish',
 				'th' => 'tay',
 				'tht' => 'taltan',
 				'ti' => 'tigrinya',
 				'tig' => 'tigre',
 				'tk' => 'turkman',
 				'tlh' => 'klingon',
 				'tli' => 'tlingit',
 				'tn' => 'tsvana',
 				'to' => 'tongan',
 				'tok' => 'tokipona',
 				'tpi' => 'tok-piksin',
 				'tr' => 'turk',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tt' => 'tatar',
 				'ttm' => 'shimoliy tutchone',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'twq' => 'tasavak',
 				'ty' => 'taiti',
 				'tyv' => 'tuva',
 				'tzm' => 'markaziy atlas tamazigxt',
 				'udm' => 'udmurt',
 				'ug' => 'uyg‘ur',
 				'uk' => 'ukrain',
 				'umb' => 'umbundu',
 				'und' => 'noma’lum til',
 				'ur' => 'urdu',
 				'uz' => 'o‘zbek',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vyetnam',
 				'vo' => 'volapyuk',
 				'vun' => 'vunjo',
 				'wa' => 'vallon',
 				'wae' => 'valis',
 				'wal' => 'volamo',
 				'war' => 'varay',
 				'wbp' => 'valbiri',
 				'wo' => 'volof',
 				'wuu' => 'vu xitoy',
 				'xal' => 'qalmoq',
 				'xh' => 'kxosa',
 				'xog' => 'soga',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'idish',
 				'yo' => 'yoruba',
 				'yrl' => 'nyengatu',
 				'yue' => 'kanton',
 				'yue@alt=menu' => 'xitoy, kanton',
 				'zgh' => 'tamazigxt',
 				'zh' => 'xitoy',
 				'zh@alt=menu' => 'xitoy, mandarin',
 				'zh_Hans@alt=long' => 'xitoy (soddalashtirilgan mandarin)',
 				'zh_Hant' => 'xitoy (an’anaviy)',
 				'zh_Hant@alt=long' => 'xitoy (an’anaviy mandarin)',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'til tarkibi yo‘q',
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
 			'Arab' => 'arab',
 			'Aran' => 'nastaʼliq',
 			'Armn' => 'arman',
 			'Beng' => 'bengal',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'brayl',
 			'Cakm' => 'chakma',
 			'Cans' => 'kanada boʻgʻin yozuvi',
 			'Cher' => 'cheroki',
 			'Cyrl' => 'kirill',
 			'Deva' => 'devanagari',
 			'Ethi' => 'habash',
 			'Geor' => 'gruzin',
 			'Grek' => 'grek',
 			'Gujr' => 'gujarot',
 			'Guru' => 'gurmukxi',
 			'Hanb' => 'hanb',
 			'Hang' => 'hangul',
 			'Hani' => 'xitoy',
 			'Hans' => 'soddalashgan',
 			'Hans@alt=stand-alone' => 'soddalashgan xitoy',
 			'Hant' => 'anʼanaviy',
 			'Hant@alt=stand-alone' => 'an’anaviy xitoy',
 			'Hebr' => 'ivrit',
 			'Hira' => 'hiragana',
 			'Hrkt' => 'katakana yoki hiragana',
 			'Jamo' => 'jamo',
 			'Jpan' => 'yapon',
 			'Kana' => 'katakana',
 			'Khmr' => 'kxmer',
 			'Knda' => 'kannada',
 			'Kore' => 'koreys',
 			'Laoo' => 'laos',
 			'Latn' => 'lotin',
 			'Mlym' => 'malayalam',
 			'Mong' => 'mongol',
 			'Mtei' => 'manipuri',
 			'Mymr' => 'myanma',
 			'Nkoo' => 'nko',
 			'Olck' => 'ol chiki',
 			'Orya' => 'oriya',
 			'Rohg' => 'hanifi',
 			'Sinh' => 'singal',
 			'Sund' => 'sundan',
 			'Syrc' => 'suryoniy',
 			'Taml' => 'tamil',
 			'Telu' => 'telugu',
 			'Tfng' => 'tifinag',
 			'Thaa' => 'taana',
 			'Thai' => 'tay',
 			'Tibt' => 'tibet',
 			'Vaii' => 'vay',
 			'Yiii' => 'i',
 			'Zmth' => 'matematik ifodalar',
 			'Zsye' => 'emoji',
 			'Zsym' => 'belgilar',
 			'Zxxx' => 'yozuvsiz',
 			'Zyyy' => 'umumiy',
 			'Zzzz' => 'noma’lum yozuv',

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
			'001' => 'Dunyo',
 			'002' => 'Afrika',
 			'003' => 'Shimoliy Amerika',
 			'005' => 'Janubiy Amerika',
 			'009' => 'Okeaniya',
 			'011' => 'G‘arbiy Afrika',
 			'013' => 'Markaziy Amerika',
 			'014' => 'Sharqiy Afrika',
 			'015' => 'Shimoliy Afrika',
 			'017' => 'Markaziy Afrika',
 			'018' => 'Janubiy Afrika',
 			'019' => 'Amerika',
 			'021' => 'Shimoliy Amerika – AQSH va Kanada',
 			'029' => 'Karib havzasi',
 			'030' => 'Sharqiy Osiyo',
 			'034' => 'Janubiy Osiyo',
 			'035' => 'Janubi-sharqiy Osiyo',
 			'039' => 'Janubiy Yevropa',
 			'053' => 'Avstralaziya',
 			'054' => 'Melaneziya',
 			'057' => 'Mikroneziya mintaqasi',
 			'061' => 'Polineziya',
 			'142' => 'Osiyo',
 			'143' => 'Markaziy Osiyo',
 			'145' => 'G‘arbiy Osiyo',
 			'150' => 'Yevropa',
 			'151' => 'Sharqiy Yevropa',
 			'154' => 'Shimoliy Yevropa',
 			'155' => 'G‘arbiy Yevropa',
 			'202' => 'Sahro janubidagi Afrika',
 			'419' => 'Lotin Amerikasi',
 			'AC' => 'Me’roj oroli',
 			'AD' => 'Andorra',
 			'AE' => 'Birlashgan Arab Amirliklari',
 			'AF' => 'Afgʻoniston',
 			'AG' => 'Antigua va Barbuda',
 			'AI' => 'Angilya',
 			'AL' => 'Albaniya',
 			'AM' => 'Armaniston',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktida',
 			'AR' => 'Argentina',
 			'AS' => 'Amerika Samoasi',
 			'AT' => 'Avstriya',
 			'AU' => 'Avstraliya',
 			'AW' => 'Aruba',
 			'AX' => 'Aland orollari',
 			'AZ' => 'Ozarbayjon',
 			'BA' => 'Bosniya va Gertsegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgiya',
 			'BF' => 'Burkina-Faso',
 			'BG' => 'Bolgariya',
 			'BH' => 'Bahrayn',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Sen-Bartelemi',
 			'BM' => 'Bermuda orollari',
 			'BN' => 'Bruney',
 			'BO' => 'Boliviya',
 			'BQ' => 'Boneyr, Sint-Estatius va Saba',
 			'BR' => 'Braziliya',
 			'BS' => 'Bagama orollari',
 			'BT' => 'Butan',
 			'BV' => 'Buve oroli',
 			'BW' => 'Botsvana',
 			'BY' => 'Belarus',
 			'BZ' => 'Beliz',
 			'CA' => 'Kanada',
 			'CC' => 'Kokos (Kiling) orollari',
 			'CD' => 'Kongo – Kinshasa',
 			'CD@alt=variant' => 'Kongo (KDR)',
 			'CF' => 'Markaziy Afrika Respublikasi',
 			'CG' => 'Kongo – Brazzavil',
 			'CG@alt=variant' => 'Kongo (Respublika)',
 			'CH' => 'Shveytsariya',
 			'CI' => 'Kot-d’Ivuar',
 			'CI@alt=variant' => 'Fil suyagi qirg‘og‘i',
 			'CK' => 'Kuk orollari',
 			'CL' => 'Chili',
 			'CM' => 'Kamerun',
 			'CN' => 'Xitoy',
 			'CO' => 'Kolumbiya',
 			'CP' => 'Klipperton oroli',
 			'CR' => 'Kosta-Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Kabo-Verde',
 			'CW' => 'Kyurasao',
 			'CX' => 'Rojdestvo oroli',
 			'CY' => 'Kipr',
 			'CZ' => 'Chexiya',
 			'CZ@alt=variant' => 'Chexiya Respublikasi',
 			'DE' => 'Germaniya',
 			'DG' => 'Diyego-Garsiya',
 			'DJ' => 'Jibuti',
 			'DK' => 'Daniya',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikan Respublikasi',
 			'DZ' => 'Jazoir',
 			'EA' => 'Seuta va Melilya',
 			'EC' => 'Ekvador',
 			'EE' => 'Estoniya',
 			'EG' => 'Misr',
 			'EH' => 'G‘arbiy Sahroi Kabir',
 			'ER' => 'Eritreya',
 			'ES' => 'Ispaniya',
 			'ET' => 'Efiopiya',
 			'EU' => 'Yevropa Ittifoqi',
 			'EZ' => 'Yevrozona',
 			'FI' => 'Finlandiya',
 			'FJ' => 'Fiji',
 			'FK' => 'Folklend orollari',
 			'FK@alt=variant' => 'Folklend (Malvin) orollari',
 			'FM' => 'Mikroneziya',
 			'FO' => 'Farer orollari',
 			'FR' => 'Fransiya',
 			'GA' => 'Gabon',
 			'GB' => 'Buyuk Britaniya',
 			'GB@alt=short' => 'Britaniya',
 			'GD' => 'Grenada',
 			'GE' => 'Gruziya',
 			'GF' => 'Fransuz Gvianasi',
 			'GG' => 'Gernsi',
 			'GH' => 'Gana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grenlandiya',
 			'GM' => 'Gambiya',
 			'GN' => 'Gvineya',
 			'GP' => 'Gvadelupe',
 			'GQ' => 'Ekvatorial Gvineya',
 			'GR' => 'Gretsiya',
 			'GS' => 'Janubiy Georgiya va Janubiy Sendvich orollari',
 			'GT' => 'Gvatemala',
 			'GU' => 'Guam',
 			'GW' => 'Gvineya-Bisau',
 			'GY' => 'Gayana',
 			'HK' => 'Gonkong (Xitoy MMH)',
 			'HK@alt=short' => 'Gonkong',
 			'HM' => 'Xerd va Makdonald orollari',
 			'HN' => 'Gonduras',
 			'HR' => 'Xorvatiya',
 			'HT' => 'Gaiti',
 			'HU' => 'Vengriya',
 			'IC' => 'Kanar orollari',
 			'ID' => 'Indoneziya',
 			'IE' => 'Irlandiya',
 			'IL' => 'Isroil',
 			'IM' => 'Men oroli',
 			'IN' => 'Hindiston',
 			'IO' => 'Britaniyaning Hind okeanidagi hududi',
 			'IQ' => 'Iroq',
 			'IR' => 'Eron',
 			'IS' => 'Islandiya',
 			'IT' => 'Italiya',
 			'JE' => 'Jersi',
 			'JM' => 'Yamayka',
 			'JO' => 'Iordaniya',
 			'JP' => 'Yaponiya',
 			'KE' => 'Keniya',
 			'KG' => 'Qirgʻiziston',
 			'KH' => 'Kambodja',
 			'KI' => 'Kiribati',
 			'KM' => 'Komor orollari',
 			'KN' => 'Sent-Kits va Nevis',
 			'KP' => 'Shimoliy Koreya',
 			'KR' => 'Janubiy Koreya',
 			'KW' => 'Quvayt',
 			'KY' => 'Kayman orollari',
 			'KZ' => 'Qozogʻiston',
 			'LA' => 'Laos',
 			'LB' => 'Livan',
 			'LC' => 'Sent-Lyusiya',
 			'LI' => 'Lixtenshteyn',
 			'LK' => 'Shri-Lanka',
 			'LR' => 'Liberiya',
 			'LS' => 'Lesoto',
 			'LT' => 'Litva',
 			'LU' => 'Lyuksemburg',
 			'LV' => 'Latviya',
 			'LY' => 'Liviya',
 			'MA' => 'Marokash',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'ME' => 'Chernogoriya',
 			'MF' => 'Sent-Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshall orollari',
 			'MK' => 'Shimoliy Makedoniya',
 			'ML' => 'Mali',
 			'MM' => 'Myanma (Birma)',
 			'MN' => 'Mongoliya',
 			'MO' => 'Makao (Xitoy MMH)',
 			'MO@alt=short' => 'Makao',
 			'MP' => 'Shimoliy Mariana orollari',
 			'MQ' => 'Martinika',
 			'MR' => 'Mavritaniya',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mavrikiy',
 			'MV' => 'Maldiv orollari',
 			'MW' => 'Malavi',
 			'MX' => 'Meksika',
 			'MY' => 'Malayziya',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibiya',
 			'NC' => 'Yangi Kaledoniya',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk oroli',
 			'NG' => 'Nigeriya',
 			'NI' => 'Nikaragua',
 			'NL' => 'Niderlandiya',
 			'NO' => 'Norvegiya',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Yangi Zelandiya',
 			'NZ@alt=variant' => 'Aotearoa Yangi Zelandiya',
 			'OM' => 'Ummon',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Fransuz Polineziyasi',
 			'PG' => 'Papua – Yangi Gvineya',
 			'PH' => 'Filippin',
 			'PK' => 'Pokiston',
 			'PL' => 'Polsha',
 			'PM' => 'Sen-Pyer va Mikelon',
 			'PN' => 'Pitkern orollari',
 			'PR' => 'Puerto-Riko',
 			'PS' => 'Falastin hududlari',
 			'PS@alt=short' => 'Falastin',
 			'PT' => 'Portugaliya',
 			'PW' => 'Palau',
 			'PY' => 'Paragvay',
 			'QA' => 'Qatar',
 			'QO' => 'Tashqi Okeaniya',
 			'RE' => 'Reyunion',
 			'RO' => 'Ruminiya',
 			'RS' => 'Serbiya',
 			'RU' => 'Rossiya',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudiya Arabistoni',
 			'SB' => 'Solomon orollari',
 			'SC' => 'Seyshel orollari',
 			'SD' => 'Sudan',
 			'SE' => 'Shvetsiya',
 			'SG' => 'Singapur',
 			'SH' => 'Muqaddas Yelena oroli',
 			'SI' => 'Sloveniya',
 			'SJ' => 'Shpitsbergen va Yan-Mayen',
 			'SK' => 'Slovakiya',
 			'SL' => 'Syerra-Leone',
 			'SM' => 'San-Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somali',
 			'SR' => 'Surinam',
 			'SS' => 'Janubiy Sudan',
 			'ST' => 'San-Tome va Prinsipi',
 			'SV' => 'Salvador',
 			'SX' => 'Sint-Marten',
 			'SY' => 'Suriya',
 			'SZ' => 'Svazilend',
 			'TA' => 'Tristan-da-Kunya',
 			'TC' => 'Turks va Kaykos orollari',
 			'TD' => 'Chad',
 			'TF' => 'Fransuz Janubiy hududlari',
 			'TG' => 'Togo',
 			'TH' => 'Tailand',
 			'TJ' => 'Tojikiston',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Sharqiy Timor',
 			'TM' => 'Turkmaniston',
 			'TN' => 'Tunis',
 			'TO' => 'Tonga',
 			'TR' => 'Turkiya',
 			'TT' => 'Trinidad va Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Tayvan',
 			'TZ' => 'Tanzaniya',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'AQSH yondosh orollari',
 			'UN' => 'Birlashgan Millatlar Tashkiloti',
 			'UN@alt=short' => 'BMT',
 			'US' => 'Amerika Qo‘shma Shtatlari',
 			'US@alt=short' => 'AQSH',
 			'UY' => 'Urugvay',
 			'UZ' => 'Oʻzbekiston',
 			'VA' => 'Vatikan',
 			'VC' => 'Sent-Vinsent va Grenadin',
 			'VE' => 'Venesuela',
 			'VG' => 'Britaniya Virgin orollari',
 			'VI' => 'AQSH Virgin orollari',
 			'VN' => 'Vyetnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Uollis va Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Qalbaki urg‘u',
 			'XB' => 'Qalbaki Bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yaman',
 			'YT' => 'Mayotta',
 			'ZA' => 'Janubiy Afrika Respublikasi',
 			'ZM' => 'Zambiya',
 			'ZW' => 'Zimbabve',
 			'ZZ' => 'Noma’lum mintaqa',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'taqvim',
 			'cf' => 'valyuta formati',
 			'collation' => 'saralash tartibi',
 			'currency' => 'valyuta',
 			'hc' => 'soat tizimi (12 yoki 24)',
 			'lb' => 'qatorni uzish uslubi',
 			'ms' => 'o‘lchov tizimi',
 			'numbers' => 'raqamlar',

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
 				'buddhist' => q{buddizm taqvimi},
 				'chinese' => q{xitoy taqvimi},
 				'coptic' => q{qibtiy taqvim},
 				'dangi' => q{dangi taqvimi},
 				'ethiopic' => q{habash taqvimi},
 				'ethiopic-amete-alem' => q{Amete Alem habash taqvimi},
 				'gregorian' => q{grigorian taqvimi},
 				'hebrew' => q{yahudiy taqvimi},
 				'islamic' => q{hijriy taqvim},
 				'islamic-civil' => q{jadvalli hijriy taqvim},
 				'islamic-tbla' => q{jadvalli hijriy taqvim (astronomik davr)},
 				'islamic-umalqura' => q{hijriy taqvim (Ummul Quro)},
 				'iso8601' => q{ISO-8601 taqvimi},
 				'japanese' => q{yapon taqvimi},
 				'persian' => q{fors taqvimi},
 				'roc' => q{mingo taqvimi},
 			},
 			'cf' => {
 				'account' => q{moliyaviy valyuta formati},
 				'standard' => q{standart valyuta formati},
 			},
 			'collation' => {
 				'ducet' => q{standart Unicode saralash tartibi},
 				'search' => q{qidiruv},
 				'standard' => q{standart saralash tartibi},
 			},
 			'hc' => {
 				'h11' => q{12 soatlik tizim (0–11)},
 				'h12' => q{12 soatlik tizim (1–12)},
 				'h23' => q{24 soatlik tizim (0–23)},
 				'h24' => q{24 soatlik tizim (1–24)},
 			},
 			'lb' => {
 				'loose' => q{qatorni yumshoq uzish},
 				'normal' => q{qatorni odatiy uzish},
 				'strict' => q{qatorni qat’iy uzish},
 			},
 			'ms' => {
 				'metric' => q{metrik tizim},
 				'uksystem' => q{Britaniya o‘lchov tizimi},
 				'ussystem' => q{AQSH o‘lchov tizimi},
 			},
 			'numbers' => {
 				'arab' => q{arab-hind raqamlari},
 				'arabext' => q{kengaytirilgan arab-hind raqamlari},
 				'armn' => q{arman raqamlari},
 				'armnlow' => q{arman kichik raqamlari},
 				'beng' => q{bengal raqamlari},
 				'cakm' => q{chakma raqamlari},
 				'deva' => q{devanagari raqamlari},
 				'ethi' => q{habash raqamlari},
 				'fullwide' => q{to‘liq enli raqamlar},
 				'geor' => q{gruzin raqamlari},
 				'grek' => q{grek raqamlari},
 				'greklow' => q{kichik grek raqamlari},
 				'gujr' => q{gujarot raqamlari},
 				'guru' => q{gurmukxi raqamlari},
 				'hanidec' => q{xitoy o‘nli raqamlari},
 				'hans' => q{soddalashgan xitoy raqamlari},
 				'hansfin' => q{soddalashgan xitoy raqamlari (moliyaviy)},
 				'hant' => q{an’anaviy xitoy raqamlari},
 				'hantfin' => q{an’anaviy xitoy raqamlari (moliyaviy)},
 				'hebr' => q{ivrit raqamlari},
 				'java' => q{yava raqamlari},
 				'jpan' => q{yapon raqamlari},
 				'jpanfin' => q{yapon raqamlari (moliyaviy)},
 				'khmr' => q{kxmer raqamlari},
 				'knda' => q{kannada raqamlari},
 				'laoo' => q{laos raqamlari},
 				'latn' => q{zamonaviy arab raqamlari},
 				'mlym' => q{malayalam raqamlari},
 				'mtei' => q{manipuri raqamlari},
 				'mymr' => q{birma raqamlari},
 				'olck' => q{ol chiki taqamlari},
 				'orya' => q{oriya raqamlari},
 				'roman' => q{rim raqamlari},
 				'romanlow' => q{kichik rim raqamlari},
 				'taml' => q{an’anaviy tamil raqamlari},
 				'tamldec' => q{tamil raqamlari},
 				'telu' => q{telugu raqamlari},
 				'thai' => q{tay raqamlari},
 				'tibt' => q{tibet raqamlari},
 				'vaii' => q{vay raqamlari},
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
 			'UK' => q{Buyuk Britaniya},
 			'US' => q{AQSH},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Til: {0}',
 			'script' => 'Yozuv: {0}',
 			'region' => 'Mintaqa: {0}',

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
			auxiliary => qr{[áàăâåäãā æ cç éèĕêëē íìĭîïī ñ óòŏôöøō œ úùŭûüū w ÿ]},
			index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'X', 'Y', 'Z', '{Oʻ}', '{Gʻ}', '{Sh}', '{Ch}'],
			main => qr{[a b d e f g h i j k l m n o p q r s t u v x y z {oʻ} {gʻ} {sh} {ch} ʼ]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'X', 'Y', 'Z', '{Oʻ}', '{Gʻ}', '{Sh}', '{Ch}'], };
},
);


has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
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
						'1' => q(eksbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(eksbi{0}),
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
						'1' => q(detsi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(detsi{0}),
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
						'1' => q(santi{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(santi{0}),
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
						'1' => q(milli{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(milli{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(kvekto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(kvekto{0}),
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
						'1' => q(eksa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(eksa{0}),
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
						'1' => q(kvetta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(kvetta{0}),
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
						'name' => q(gravitatsiya kuchi),
						'one' => q({0} grav. kuchi),
						'other' => q({0} grav. kuchi),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(gravitatsiya kuchi),
						'one' => q({0} grav. kuchi),
						'other' => q({0} grav. kuchi),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metr/soniya kvadrat),
						'one' => q({0} metr/soniya kvadrat),
						'other' => q({0} metr/soniya kvadrat),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metr/soniya kvadrat),
						'one' => q({0} metr/soniya kvadrat),
						'other' => q({0} metr/soniya kvadrat),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0} yoy daqiqasi),
						'other' => q({0} yoy daqiqasi),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0} yoy daqiqasi),
						'other' => q({0} yoy daqiqasi),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0} yoy soniyasi),
						'other' => q({0} yoy soniyasi),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0} yoy soniyasi),
						'other' => q({0} yoy soniyasi),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} gradus),
						'other' => q({0} gradus),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} gradus),
						'other' => q({0} gradus),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radian),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radian),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q({0} marta aylanish),
						'other' => q({0} marta aylanish),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0} marta aylanish),
						'other' => q({0} marta aylanish),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} gektar),
						'other' => q({0} gektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} gektar),
						'other' => q({0} gektar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(kvadrat santimetr),
						'one' => q({0} kvadrat santimetr),
						'other' => q({0} kvadrat santimetr),
						'per' => q({0}/kvadrat santimetr),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(kvadrat santimetr),
						'one' => q({0} kvadrat santimetr),
						'other' => q({0} kvadrat santimetr),
						'per' => q({0}/kvadrat santimetr),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(kvadrat fut),
						'one' => q({0} kvadrat fut),
						'other' => q({0} kvadrat fut),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kvadrat fut),
						'one' => q({0} kvadrat fut),
						'other' => q({0} kvadrat fut),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'one' => q({0} kvadrat dyum),
						'other' => q({0} kvadrat dyum),
						'per' => q({0}/kvadrat duym),
					},
					# Core Unit Identifier
					'square-inch' => {
						'one' => q({0} kvadrat dyum),
						'other' => q({0} kvadrat dyum),
						'per' => q({0}/kvadrat duym),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kvadrat kilometr),
						'one' => q({0} kvadrat kilometr),
						'other' => q({0} kvadrat kilometr),
						'per' => q({0} kvadrat kilometr),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kvadrat kilometr),
						'one' => q({0} kvadrat kilometr),
						'other' => q({0} kvadrat kilometr),
						'per' => q({0} kvadrat kilometr),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(kvadrat metr),
						'one' => q({0} kvadrat metr),
						'other' => q({0} kvadrat metr),
						'per' => q({0}/kvadrat metr),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(kvadrat metr),
						'one' => q({0} kvadrat metr),
						'other' => q({0} kvadrat metr),
						'per' => q({0}/kvadrat metr),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(kvadrat mil),
						'one' => q({0} kvadrat mil),
						'other' => q({0} kvadrat mil),
						'per' => q({0}/kvadrat mil),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(kvadrat mil),
						'one' => q({0} kvadrat mil),
						'other' => q({0} kvadrat mil),
						'per' => q({0}/kvadrat mil),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(kvadrat yard),
						'one' => q({0} kvadrat yard),
						'other' => q({0} kvadrat yard),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(kvadrat yard),
						'one' => q({0} kvadrat yard),
						'other' => q({0} kvadrat yard),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(elementlar),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(elementlar),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milligramm/detsilitr),
						'one' => q({0} milligramm/detsilitr),
						'other' => q({0} milligramm/detsilitr),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milligramm/detsilitr),
						'one' => q({0} milligramm/detsilitr),
						'other' => q({0} milligramm/detsilitr),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'one' => q({0} millimol/litr),
						'other' => q({0} millimol/litr),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'one' => q({0} millimol/litr),
						'other' => q({0} millimol/litr),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q({0} foiz),
						'other' => q({0} foiz),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q({0} foiz),
						'other' => q({0} foiz),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} promille),
						'other' => q({0} promille),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} promille),
						'other' => q({0} promille),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} promiriada),
						'other' => q({0} promiriada),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} promiriada),
						'other' => q({0} promiriada),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litr/100 km),
						'one' => q({0} litr/100 km),
						'other' => q({0} litr/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litr/100 km),
						'one' => q({0} litr/100 km),
						'other' => q({0} litr/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litr/kilometr),
						'one' => q({0} litr/kilometr),
						'other' => q({0} litr/kilometr),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litr/kilometr),
						'one' => q({0} litr/kilometr),
						'other' => q({0} litr/kilometr),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mil/gallon),
						'one' => q({0} mil/gallon),
						'other' => q({0} mil/gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil/gallon),
						'one' => q({0} mil/gallon),
						'other' => q({0} mil/gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'one' => q({0} mil/imp. gallon),
						'other' => q({0} mil/imp. gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0} mil/imp. gallon),
						'other' => q({0} mil/imp. gallon),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} sharqiy uzunlik),
						'north' => q({0} shimoliy kenglik),
						'south' => q({0} janubiy kenglik),
						'west' => q({0} g‘arbiy uzunlik),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} sharqiy uzunlik),
						'north' => q({0} shimoliy kenglik),
						'south' => q({0} janubiy kenglik),
						'west' => q({0} g‘arbiy uzunlik),
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
						'name' => q(gigabayt),
						'one' => q({0} gigabayt),
						'other' => q({0} gigabayt),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabayt),
						'one' => q({0} gigabayt),
						'other' => q({0} gigabayt),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobayt),
						'one' => q({0} kilobayt),
						'other' => q({0} kilobayt),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobayt),
						'one' => q({0} kilobayt),
						'other' => q({0} kilobayt),
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
						'name' => q(megabayt),
						'one' => q({0} megabayt),
						'other' => q({0} megabayt),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabayt),
						'one' => q({0} megabayt),
						'other' => q({0} megabayt),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabayt),
						'one' => q({0} petabayt),
						'other' => q({0} petabayt),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabayt),
						'one' => q({0} petabayt),
						'other' => q({0} petabayt),
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
						'name' => q(terabayt),
						'one' => q({0} terabayt),
						'other' => q({0} terabayt),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabayt),
						'one' => q({0} terabayt),
						'other' => q({0} terabayt),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosoniya),
						'one' => q({0} mikrosoniya),
						'other' => q({0} mikrosoniya),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosoniya),
						'one' => q({0} mikrosoniya),
						'other' => q({0} mikrosoniya),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0} millisoniya),
						'other' => q({0} millisoniya),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0} millisoniya),
						'other' => q({0} millisoniya),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(daqiqa),
						'one' => q({0} daqiqa),
						'other' => q({0} daqiqa),
						'per' => q({0}/daqiqa),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(daqiqa),
						'one' => q({0} daqiqa),
						'other' => q({0} daqiqa),
						'per' => q({0}/daqiqa),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q({0} nanosoniya),
						'other' => q({0} nanosoniya),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q({0} nanosoniya),
						'other' => q({0} nanosoniya),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(soniya),
						'one' => q({0} soniya),
						'other' => q({0} soniya),
						'per' => q({0}/soniya),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(soniya),
						'one' => q({0} soniya),
						'other' => q({0} soniya),
						'per' => q({0}/soniya),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliamper),
						'one' => q({0} milliamper),
						'other' => q({0} milliamper),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliamper),
						'one' => q({0} milliamper),
						'other' => q({0} milliamper),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0} om),
						'other' => q({0} om),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0} om),
						'other' => q({0} om),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(Britaniya issiqlik birligi),
						'one' => q({0} Britaniya issiqlik birligi),
						'other' => q({0} Britaniya issiqlik birligi),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(Britaniya issiqlik birligi),
						'one' => q({0} Britaniya issiqlik birligi),
						'other' => q({0} Britaniya issiqlik birligi),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kaloriya),
						'one' => q(kaloriya),
						'other' => q({0} kaloriya),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kaloriya),
						'one' => q(kaloriya),
						'other' => q({0} kaloriya),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kaloriya),
						'one' => q({0} kaloriya),
						'other' => q({0} kaloriya),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kaloriya),
						'one' => q({0} kaloriya),
						'other' => q({0} kaloriya),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0} joul),
						'other' => q({0} joul),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0} joul),
						'other' => q({0} joul),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokaloriya),
						'one' => q({0} kilokaloriya),
						'other' => q({0} kilokaloriya),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokaloriya),
						'one' => q({0} kilokaloriya),
						'other' => q({0} kilokaloriya),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'one' => q({0} kilojoul),
						'other' => q({0} kilojoul),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'one' => q({0} kilojoul),
						'other' => q({0} kilojoul),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilovatt-soat),
						'one' => q({0} kilovatt-soat),
						'other' => q({0} kilovatt-soat),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilovatt-soat),
						'one' => q({0} kilovatt-soat),
						'other' => q({0} kilovatt-soat),
					},
					# Long Unit Identifier
					'force-newton' => {
						'one' => q({0} nyuton),
						'other' => q({0} nyuton),
					},
					# Core Unit Identifier
					'newton' => {
						'one' => q({0} nyuton),
						'other' => q({0} nyuton),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigagers),
						'one' => q({0} gigagers),
						'other' => q({0} gigagers),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigagers),
						'one' => q({0} gigagers),
						'other' => q({0} gigagers),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(gers),
						'one' => q({0} gers),
						'other' => q({0} gers),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(gers),
						'one' => q({0} gers),
						'other' => q({0} gers),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilogers),
						'one' => q({0} kilogers),
						'other' => q({0} kilogers),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilogers),
						'one' => q({0} kilogers),
						'other' => q({0} kilogers),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megagers),
						'one' => q({0} megagers),
						'other' => q({0} megagers),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megagers),
						'one' => q({0} megagers),
						'other' => q({0} megagers),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(nuqta/santimetr),
						'one' => q({0} nuqta/santimetr),
						'other' => q({0} nuqta/santimetr),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(nuqta/santimetr),
						'one' => q({0} nuqta/santimetr),
						'other' => q({0} nuqta/santimetr),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(tipografik em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(tipografik em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0} megapiksel),
						'other' => q({0} megapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0} megapiksel),
						'other' => q({0} megapiksel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0} piksel),
						'other' => q({0} piksel),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0} piksel),
						'other' => q({0} piksel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(piksel/santimetr),
						'one' => q({0} piksel/santimetr),
						'other' => q({0} piksel/santimetr),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(piksel/santimetr),
						'one' => q({0} piksel/santimetr),
						'other' => q({0} piksel/santimetr),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronomik birlik),
						'one' => q({0} astronomik birlik),
						'other' => q({0} astronomik birlik),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronomik birlik),
						'one' => q({0} astronomik birlik),
						'other' => q({0} astronomik birlik),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(santimetr),
						'one' => q({0} santimetr),
						'other' => q({0} santimetr),
						'per' => q({0}/santimetr),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(santimetr),
						'one' => q({0} santimetr),
						'other' => q({0} santimetr),
						'per' => q({0}/santimetr),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(detsimetr),
						'one' => q({0} detsimetr),
						'other' => q({0} detsimetr),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(detsimetr),
						'one' => q({0} detsimetr),
						'other' => q({0} detsimetr),
					},
					# Long Unit Identifier
					'length-foot' => {
						'per' => q({0}/fut),
					},
					# Core Unit Identifier
					'foot' => {
						'per' => q({0}/fut),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} duym),
						'other' => q({0} duym),
						'per' => q({0}/duym),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} duym),
						'other' => q({0} duym),
						'per' => q({0}/duym),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometr),
						'one' => q({0} kilometr),
						'other' => q({0} kilometr),
						'per' => q({0}/kilometr),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometr),
						'one' => q({0} kilometr),
						'other' => q({0} kilometr),
						'per' => q({0}/kilometr),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} yorug‘lik yili),
						'other' => q({0} yorug‘lik yili),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} yorug‘lik yili),
						'other' => q({0} yorug‘lik yili),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0} metr),
						'other' => q({0} metr),
						'per' => q({0}/metr),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0} metr),
						'other' => q({0} metr),
						'per' => q({0}/metr),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrometr),
						'one' => q({0} mikrometr),
						'other' => q({0} mikrometr),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrometr),
						'one' => q({0} mikrometr),
						'other' => q({0} mikrometr),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(skandinav mili),
						'one' => q({0} skandinav mili),
						'other' => q({0} skandinav mili),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(skandinav mili),
						'one' => q({0} skandinav mili),
						'other' => q({0} skandinav mili),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(millimetr),
						'one' => q({0} millimetr),
						'other' => q({0} millimetr),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(millimetr),
						'one' => q({0} millimetr),
						'other' => q({0} millimetr),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometr),
						'one' => q({0} nanometr),
						'other' => q({0} nanometr),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometr),
						'one' => q({0} nanometr),
						'other' => q({0} nanometr),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(dengiz mili),
						'one' => q({0} dengiz mili),
						'other' => q({0} dengiz mili),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(dengiz mili),
						'one' => q({0} dengiz mili),
						'other' => q({0} dengiz mili),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsek),
						'one' => q({0} parsek),
						'other' => q({0} parsek),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsek),
						'one' => q({0} parsek),
						'other' => q({0} parsek),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometr),
						'one' => q({0} pikometr),
						'other' => q({0} pikometr),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometr),
						'one' => q({0} pikometr),
						'other' => q({0} pikometr),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} quyosh radiusi),
						'other' => q({0} quyosh radiusi),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} quyosh radiusi),
						'other' => q({0} quyosh radiusi),
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
						'name' => q(lyuks),
						'one' => q({0} lyuks),
						'other' => q({0} lyuks),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lyuks),
						'one' => q({0} lyuks),
						'other' => q({0} lyuks),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0} quyosh nuri kuchi),
						'other' => q({0} quyosh nuri kuchi),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} quyosh nuri kuchi),
						'other' => q({0} quyosh nuri kuchi),
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
						'one' => q({0} Yer massasi),
						'other' => q({0} Yer massasi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} Yer massasi),
						'other' => q({0} Yer massasi),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} gramm),
						'other' => q({0} gramm),
						'per' => q({0}/gramm),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} gramm),
						'other' => q({0} gramm),
						'per' => q({0}/gramm),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogramm),
						'one' => q({0} kilogramm),
						'other' => q({0} kilogramm),
						'per' => q({0}/kilogramm),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogramm),
						'one' => q({0} kilogramm),
						'other' => q({0} kilogramm),
						'per' => q({0}/kilogramm),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogramm),
						'one' => q({0} mikrogramm),
						'other' => q({0} mikrogramm),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogramm),
						'one' => q({0} mikrogramm),
						'other' => q({0} mikrogramm),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(milligramm),
						'one' => q({0} milligramm),
						'other' => q({0} milligramm),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(milligramm),
						'one' => q({0} milligramm),
						'other' => q({0} milligramm),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} quyosh massasi),
						'other' => q({0} quyosh massasi),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} quyosh massasi),
						'other' => q({0} quyosh massasi),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(amerika tonnasi),
						'one' => q({0} amerika tonnasi),
						'other' => q({0} amerika tonnasi),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(amerika tonnasi),
						'one' => q({0} amerika tonnasi),
						'other' => q({0} amerika tonnasi),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tonna),
						'one' => q({0} tonna),
						'other' => q({0} tonna),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tonna),
						'one' => q({0} tonna),
						'other' => q({0} tonna),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigavatt),
						'one' => q({0} gigavatt),
						'other' => q({0} gigavatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigavatt),
						'one' => q({0} gigavatt),
						'other' => q({0} gigavatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(ot kuchi),
						'one' => q({0} ot kuchi),
						'other' => q({0} ot kuchi),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(ot kuchi),
						'one' => q({0} ot kuchi),
						'other' => q({0} ot kuchi),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilovatt),
						'one' => q({0} kilovatt),
						'other' => q({0} kilovatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilovatt),
						'one' => q({0} kilovatt),
						'other' => q({0} kilovatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megavatt),
						'one' => q({0} megavatt),
						'other' => q({0} megavatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megavatt),
						'one' => q({0} megavatt),
						'other' => q({0} megavatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(millivatt),
						'one' => q({0} millivatt),
						'other' => q({0} millivatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(millivatt),
						'one' => q({0} millivatt),
						'other' => q({0} millivatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(vatt),
						'one' => q({0} vatt),
						'other' => q({0} vatt),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(vatt),
						'one' => q({0} vatt),
						'other' => q({0} vatt),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0} kvadrat),
						'one' => q({0} kvadrat),
						'other' => q({0} kvadrat),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0} kvadrat),
						'one' => q({0} kvadrat),
						'other' => q({0} kvadrat),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0} kub),
						'one' => q({0} kub),
						'other' => q({0} kub),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0} kub),
						'one' => q({0} kub),
						'other' => q({0} kub),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfera),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfera),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfera),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfera),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(gektopaskal),
						'one' => q({0} gektopaskal),
						'other' => q({0} gektopaskal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(gektopaskal),
						'one' => q({0} gektopaskal),
						'other' => q({0} gektopaskal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(duym simob ustuni),
						'one' => q({0} duym simob ustuni),
						'other' => q({0} duym simob ustuni),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(duym simob ustuni),
						'one' => q({0} duym simob ustuni),
						'other' => q({0} duym simob ustuni),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopaskal),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopaskal),
						'one' => q({0} kilopaskal),
						'other' => q({0} kilopaskal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapaskal),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapaskal),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskal),
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
						'name' => q(mm simob ustuni),
						'one' => q({0} mm simob ustuni),
						'other' => q({0} mm simob ustuni),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mm simob ustuni),
						'one' => q({0} mm simob ustuni),
						'other' => q({0} mm simob ustuni),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(paskal),
						'one' => q({0} paskal),
						'other' => q({0} paskal),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(paskal),
						'one' => q({0} paskal),
						'other' => q({0} paskal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(funt/duym kvadrat),
						'one' => q({0} funt/duym kvadrat),
						'other' => q({0} funt/duym kvadrat),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(funt/duym kvadrat),
						'one' => q({0} funt/duym kvadrat),
						'other' => q({0} funt/duym kvadrat),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Bofort),
						'one' => q(Bofort {0}),
						'other' => q(Bofort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Bofort),
						'one' => q(Bofort {0}),
						'other' => q(Bofort {0}),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metr/soniya),
						'one' => q({0} metr/soniya),
						'other' => q({0} metr/soniya),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metr/soniya),
						'one' => q({0} metr/soniya),
						'other' => q({0} metr/soniya),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(Selsiy darajasi),
						'one' => q({0} Selsiy darajasi),
						'other' => q({0} Selsiy darajasi),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(Selsiy darajasi),
						'one' => q({0} Selsiy darajasi),
						'other' => q({0} Selsiy darajasi),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(Farengeyt darajasi),
						'one' => q({0} Farengeyt darajasi),
						'other' => q({0} Farengeyt darajasi),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(Farengeyt darajasi),
						'one' => q({0} Farengeyt darajasi),
						'other' => q({0} Farengeyt darajasi),
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
					'torque-newton-meter' => {
						'name' => q(nyuton-metr),
						'one' => q({0} nyuton-metr),
						'other' => q({0} nyuton-metr),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(nyuton-metr),
						'one' => q({0} nyuton-metr),
						'other' => q({0} nyuton-metr),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(funt-fut),
						'one' => q({0} funt-kuch-fut),
						'other' => q({0} funt-fut),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(funt-fut),
						'one' => q({0} funt-kuch-fut),
						'other' => q({0} funt-fut),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(santilitr),
						'one' => q({0} santilitr),
						'other' => q({0} santilitr),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(santilitr),
						'one' => q({0} santilitr),
						'other' => q({0} santilitr),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(kub santimetr),
						'one' => q({0} kub santimetr),
						'other' => q({0} kub santimetr),
						'per' => q({0}/kub santimetr),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(kub santimetr),
						'one' => q({0} kub santimetr),
						'other' => q({0} kub santimetr),
						'per' => q({0}/kub santimetr),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kub kilometr),
						'one' => q({0} kub kilometr),
						'other' => q({0} kub kilometr),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kub kilometr),
						'one' => q({0} kub kilometr),
						'other' => q({0} kub kilometr),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(kub metr),
						'one' => q({0} kub metr),
						'other' => q({0} kub metr),
						'per' => q({0}/kub metr),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(kub metr),
						'one' => q({0} kub metr),
						'other' => q({0} kub metr),
						'per' => q({0}/kub metr),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'one' => q({0} kub yard),
						'other' => q({0} kub yard),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'one' => q({0} kub yard),
						'other' => q({0} kub yard),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(metrik piyola),
						'one' => q({0} metrik piyola),
						'other' => q({0} metrik piyola),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(metrik piyola),
						'one' => q({0} metrik piyola),
						'other' => q({0} metrik piyola),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(detsilitr),
						'one' => q({0} detsilitr),
						'other' => q({0} detsilitr),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(detsilitr),
						'one' => q({0} detsilitr),
						'other' => q({0} detsilitr),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(imp. desert qoshiq),
						'one' => q({0} imp. desert qoshiq),
						'other' => q({0} imp. desert qoshiq),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(imp. desert qoshiq),
						'one' => q({0} imp. desert qoshiq),
						'other' => q({0} imp. desert qoshiq),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(draxma),
						'one' => q({0} draxma),
						'other' => q({0} draxma),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(draxma),
						'one' => q({0} draxma),
						'other' => q({0} draxma),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q({0} ingliz suyuq unsiyasi),
						'other' => q({0} ingliz suyuq unsiyasi),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0} ingliz suyuq unsiyasi),
						'other' => q({0} ingliz suyuq unsiyasi),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0}/gallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0}/gallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(imp. gallon),
						'one' => q({0} imp. gallon),
						'other' => q({0} imp. gallon),
						'per' => q({0}/imp. gallon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(imp. gallon),
						'one' => q({0} imp. gallon),
						'other' => q({0} imp. gallon),
						'per' => q({0}/imp. gallon),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(gektolitr),
						'one' => q({0} gektolitr),
						'other' => q({0} gektolitr),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(gektolitr),
						'one' => q({0} gektolitr),
						'other' => q({0} gektolitr),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} litr),
						'other' => q({0} litr),
						'per' => q({0}/litr),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} litr),
						'other' => q({0} litr),
						'per' => q({0}/litr),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitr),
						'one' => q({0} megalitr),
						'other' => q({0} megalitr),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitr),
						'one' => q({0} megalitr),
						'other' => q({0} megalitr),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(millilitr),
						'one' => q({0} millilitr),
						'other' => q({0} millilitr),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(millilitr),
						'one' => q({0} millilitr),
						'other' => q({0} millilitr),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(metrik pint),
						'one' => q({0} metrik pint),
						'other' => q({0} metrik pint),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(metrik pint),
						'one' => q({0} metrik pint),
						'other' => q({0} metrik pint),
					},
				},
				'narrow' => {
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
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
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
						'other' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
						'one' => q({0}ppm),
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
					'duration-millisecond' => {
						'name' => q(mson),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(mson),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'per' => q({0}/ch.),
					},
					# Core Unit Identifier
					'quarter' => {
						'per' => q({0}/ch.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'one' => q({0} nqt/sm),
						'other' => q({0} nuqta/sm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'one' => q({0} nqt/sm),
						'other' => q({0} nuqta/sm),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} dyuym),
						'other' => q({0} dyuym),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} dyuym),
						'other' => q({0} dyuym),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} yo.y.),
						'other' => q({0} yo.y.),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} yo.y.),
						'other' => q({0} yo.y.),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} milya),
						'other' => q({0} milya),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} milya),
						'other' => q({0} milya),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kd),
						'one' => q({0}kd),
						'other' => q({0}kd),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kd),
						'one' => q({0}kd),
						'other' => q({0}kd),
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
					'light-solar-luminosity' => {
						'name' => q(L☉),
						'one' => q({0}L☉),
						'other' => q({0}L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(L☉),
						'one' => q({0}L☉),
						'other' => q({0}L☉),
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
					'power-horsepower' => {
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
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
						'name' => q(funt-fut),
						'one' => q({0} funt-fut),
						'other' => q({0} funt-fut),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(funt-fut),
						'one' => q({0} funt-fut),
						'other' => q({0} funt-fut),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
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
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(yo‘nalish),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(yo‘nalish),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(s{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(s{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(kv{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(kv{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(gekto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(gekto{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(Kv{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(Kv{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(grav. kuchi),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(grav. kuchi),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metr/soniya²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metr/soniya²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(yoy daqiqasi),
						'one' => q({0} yoy daq.),
						'other' => q({0} yoy daq.),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(yoy daqiqasi),
						'one' => q({0} yoy daq.),
						'other' => q({0} yoy daq.),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(yoy soniyasi),
						'one' => q({0} yoy son.),
						'other' => q({0} yoy son.),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(yoy soniyasi),
						'one' => q({0} yoy son.),
						'other' => q({0} yoy son.),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(gradus),
						'one' => q({0} grad),
						'other' => q({0} grad),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(gradus),
						'one' => q({0} grad),
						'other' => q({0} grad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(aylanish),
						'one' => q({0} marta ayl.),
						'other' => q({0} marta ayl.),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(aylanish),
						'one' => q({0} marta ayl.),
						'other' => q({0} marta ayl.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akr),
						'one' => q({0} akr),
						'other' => q({0} akr),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akr),
						'one' => q({0} akr),
						'other' => q({0} akr),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(gektar),
						'one' => q({0} ga),
						'other' => q({0} ga),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(gektar),
						'one' => q({0} ga),
						'other' => q({0} ga),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(sm²),
						'one' => q({0} sm²),
						'other' => q({0} sm²),
						'per' => q({0}/sm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sm²),
						'one' => q({0} sm²),
						'other' => q({0} sm²),
						'per' => q({0}/sm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(kv. fut),
						'one' => q({0} kv. fut),
						'other' => q({0} kv. fut),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kv. fut),
						'one' => q({0} kv. fut),
						'other' => q({0} kv. fut),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(kvadrat duym),
						'one' => q({0} kv. duym),
						'other' => q({0} kv. duym),
						'per' => q({0} kv. duym),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(kvadrat duym),
						'one' => q({0} kv. duym),
						'other' => q({0} kv. duym),
						'per' => q({0} kv. duym),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(kv. mil),
						'one' => q({0} kv. mil),
						'other' => q({0} kv. mil),
						'per' => q({0}/mil²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(kv. mil),
						'one' => q({0} kv. mil),
						'other' => q({0} kv. mil),
						'per' => q({0}/mil²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yard²),
						'one' => q({0} yard²),
						'other' => q({0} yard²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yard²),
						'one' => q({0} yard²),
						'other' => q({0} yard²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(element),
						'one' => q({0} element),
						'other' => q({0} ta element),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(element),
						'one' => q({0} element),
						'other' => q({0} ta element),
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
					'concentr-millimole-per-liter' => {
						'name' => q(millimol/litr),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimol/litr),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(foiz),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(foiz),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(promille),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(promille),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(milliondan ulush),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(milliondan ulush),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(promiriada),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(promiriada),
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
						'name' => q(litr/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litr/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mil/gal),
						'one' => q({0} mil/gal),
						'other' => q({0} mil/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil/gal),
						'one' => q({0} mil/gal),
						'other' => q({0} mil/gal),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil/imp. gallon),
						'one' => q({0} mil/imp.gal),
						'other' => q({0} mil/imp.gal),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil/imp. gallon),
						'one' => q({0} mil/imp.gal),
						'other' => q({0} mil/imp.gal),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} shq. u.),
						'north' => q({0} shm. k.),
						'south' => q({0} jan. k.),
						'west' => q({0} g‘rb. u.),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} shq. u.),
						'north' => q({0} shm. k.),
						'south' => q({0} jan. k.),
						'west' => q({0} g‘rb. u.),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bayt),
						'one' => q({0} bayt),
						'other' => q({0} bayt),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bayt),
						'one' => q({0} bayt),
						'other' => q({0} bayt),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gbit),
						'other' => q({0} Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gbit),
						'other' => q({0} Gbit),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kbit),
						'other' => q({0} kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kbit),
						'other' => q({0} kbit),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mbit),
						'other' => q({0} Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mbit),
						'other' => q({0} Mbit),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tbit),
						'other' => q({0} Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tbit),
						'other' => q({0} Tbit),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(asr),
						'one' => q({0} asr),
						'other' => q({0} asr),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(asr),
						'one' => q({0} asr),
						'other' => q({0} asr),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(kun),
						'one' => q({0} kun),
						'other' => q({0} kun),
						'per' => q({0}/kun),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(kun),
						'one' => q({0} kun),
						'other' => q({0} kun),
						'per' => q({0}/kun),
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
						'name' => q(soat),
						'one' => q({0} soat),
						'other' => q({0} soat),
						'per' => q({0}/soat),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(soat),
						'one' => q({0} soat),
						'other' => q({0} soat),
						'per' => q({0}/soat),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mks),
						'one' => q({0} mks),
						'other' => q({0} mks),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mks),
						'one' => q({0} mks),
						'other' => q({0} mks),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(millisoniya),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(millisoniya),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(daq.),
						'one' => q({0} daq.),
						'other' => q({0} daq.),
						'per' => q({0}/daq.),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(daq.),
						'one' => q({0} daq.),
						'other' => q({0} daq.),
						'per' => q({0}/daq.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(oy),
						'one' => q({0} oy),
						'other' => q({0} oy),
						'per' => q({0}/oy),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(oy),
						'one' => q({0} oy),
						'other' => q({0} oy),
						'per' => q({0}/oy),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosoniya),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosoniya),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(chorak),
						'one' => q({0} chorak),
						'other' => q({0} chorak),
						'per' => q({0}/chorak),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(chorak),
						'one' => q({0} chorak),
						'other' => q({0} chorak),
						'per' => q({0}/chorak),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(son.),
						'one' => q({0} son.),
						'other' => q({0} son.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(son.),
						'one' => q({0} son.),
						'other' => q({0} son.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(hafta),
						'one' => q({0} hafta),
						'other' => q({0} hafta),
						'per' => q({0}/hafta),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(hafta),
						'one' => q({0} hafta),
						'other' => q({0} hafta),
						'per' => q({0}/hafta),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(yil),
						'one' => q({0} yil),
						'other' => q({0} yil),
						'per' => q({0}/yil),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(yil),
						'one' => q({0} yil),
						'other' => q({0} yil),
						'per' => q({0}/yil),
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
					'electric-ohm' => {
						'name' => q(om),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(om),
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
						'name' => q(elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joul),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joul),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kkal),
						'one' => q({0} kkal),
						'other' => q({0} kkal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kkal),
						'one' => q({0} kkal),
						'other' => q({0} kkal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoul),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoul),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kVt-soat),
						'one' => q({0} kVt-soat),
						'other' => q({0} kVt-soat),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kVt-soat),
						'one' => q({0} kVt-soat),
						'other' => q({0} kVt-soat),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(AQSH termi),
						'one' => q({0} AQSH termi),
						'other' => q({0} AQSH termi),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(AQSH termi),
						'one' => q({0} AQSH termi),
						'other' => q({0} AQSH termi),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(nyuton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(nyuton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(funt-kuch),
						'one' => q({0} funt-kuch),
						'other' => q({0} funt-kuch),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(funt-kuch),
						'one' => q({0} funt-kuch),
						'other' => q({0} funt-kuch),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(GGs),
						'one' => q({0} GGs),
						'other' => q({0} GGs),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(GGs),
						'one' => q({0} GGs),
						'other' => q({0} GGs),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(Gs),
						'one' => q({0} Gs),
						'other' => q({0} Gs),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(Gs),
						'one' => q({0} Gs),
						'other' => q({0} Gs),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kGs),
						'one' => q({0} kGs),
						'other' => q({0} kGs),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kGs),
						'one' => q({0} kGs),
						'other' => q({0} kGs),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(MGs),
						'one' => q({0} MGs),
						'other' => q({0} MGs),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(MGs),
						'one' => q({0} MGs),
						'other' => q({0} MGs),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'one' => q({0} piksel),
						'other' => q({0} piksel),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q({0} piksel),
						'other' => q({0} piksel),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(nuqta/sm),
						'one' => q({0} nuqta/sm),
						'other' => q({0} nuqta/sm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(nuqta/sm),
						'one' => q({0} nuqta/sm),
						'other' => q({0} nuqta/sm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(nuqta/duym),
						'one' => q({0} nuqta/duym),
						'other' => q({0} nuqta/duym),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(nuqta/duym),
						'one' => q({0} nuqta/duym),
						'other' => q({0} nuqta/duym),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapiksel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(piksel),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(piksel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(px/sm),
						'one' => q({0} px/sm),
						'other' => q({0} px/sm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(px/sm),
						'one' => q({0} px/sm),
						'other' => q({0} px/sm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(piksel/duym),
						'one' => q({0} piksel/duym),
						'other' => q({0} piksel/duym),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(piksel/duym),
						'one' => q({0} piksel/duym),
						'other' => q({0} piksel/duym),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(a.b.),
						'one' => q({0} a.b.),
						'other' => q({0} a.b.),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(a.b.),
						'one' => q({0} a.b.),
						'other' => q({0} a.b.),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
						'per' => q({0}/sm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
						'per' => q({0}/sm),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(yer radiusi),
						'one' => q({0} yer radiusi),
						'other' => q({0} yer radiusi),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(yer radiusi),
						'one' => q({0} yer radiusi),
						'other' => q({0} yer radiusi),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fatom),
						'one' => q({0} fatom),
						'other' => q({0} fatom),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fatom),
						'one' => q({0} fatom),
						'other' => q({0} fatom),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(fut),
						'one' => q({0} fut),
						'other' => q({0} fut),
						'per' => q({0} fut),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(fut),
						'one' => q({0} fut),
						'other' => q({0} fut),
						'per' => q({0} fut),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(farlong),
						'one' => q({0} farlong),
						'other' => q({0} farlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(farlong),
						'one' => q({0} farlong),
						'other' => q({0} farlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(duym),
						'one' => q({0} dy),
						'other' => q({0} dy),
						'per' => q({0}/dy),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(duym),
						'one' => q({0} dy),
						'other' => q({0} dy),
						'per' => q({0}/dy),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(yorug‘lik yili),
						'one' => q({0} y.y.),
						'other' => q({0} y.y.),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(yorug‘lik yili),
						'one' => q({0} y.y.),
						'other' => q({0} y.y.),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metr),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metr),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μmetr),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μmetr),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(sk. mili),
						'one' => q({0} sk. mili),
						'other' => q({0} sk. mili),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(sk. mili),
						'one' => q({0} sk. mili),
						'other' => q({0} sk. mili),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(den. mili),
						'one' => q({0} den. mili),
						'other' => q({0} den. mili),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(den. mili),
						'one' => q({0} den. mili),
						'other' => q({0} den. mili),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(pk),
						'one' => q({0} pk),
						'other' => q({0} pk),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(pk),
						'one' => q({0} pk),
						'other' => q({0} pk),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(nuqta),
						'one' => q({0} nuqta),
						'other' => q({0} nuqta),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(nuqta),
						'one' => q({0} nuqta),
						'other' => q({0} nuqta),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(quyosh radiusi),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(quyosh radiusi),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yard),
						'one' => q({0} yard),
						'other' => q({0} yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yard),
						'one' => q({0} yard),
						'other' => q({0} yard),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandela),
						'one' => q({0} kandela),
						'other' => q({0} kandela),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lk),
						'one' => q({0} lk),
						'other' => q({0} lk),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lk),
						'one' => q({0} lk),
						'other' => q({0} lk),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(quyosh nuri kuchi),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(quyosh nuri kuchi),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karat),
						'one' => q({0} kar),
						'other' => q({0} kar),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
						'one' => q({0} kar),
						'other' => q({0} kar),
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
						'name' => q(Yer massasi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Yer massasi),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} gran),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} gran),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramm),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramm),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(unsiya),
						'one' => q({0} unsiya),
						'other' => q({0} unsiya),
						'per' => q({0}/unsiya),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(unsiya),
						'one' => q({0} unsiya),
						'other' => q({0} unsiya),
						'per' => q({0}/unsiya),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troya unsiyasi),
						'one' => q({0} troya unsiyasi),
						'other' => q({0} troya unsiyasi),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troya unsiyasi),
						'one' => q({0} troya unsiyasi),
						'other' => q({0} troya unsiyasi),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(funt),
						'one' => q({0} funt),
						'other' => q({0} funt),
						'per' => q({0}/funt),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(funt),
						'one' => q({0} funt),
						'other' => q({0} funt),
						'per' => q({0}/funt),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(quyosh massasi),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(quyosh massasi),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(tosh),
						'one' => q({0} tosh),
						'other' => q({0} tosh),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(tosh),
						'one' => q({0} tosh),
						'other' => q({0} tosh),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(amer. t),
						'one' => q({0} amer. t),
						'other' => q({0} amer. t),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(amer. t),
						'one' => q({0} amer. t),
						'other' => q({0} amer. t),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(GVt),
						'one' => q({0} GVt),
						'other' => q({0} GVt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(GVt),
						'one' => q({0} GVt),
						'other' => q({0} GVt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(o.k.),
						'one' => q({0} o.k.),
						'other' => q({0} o.k.),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(o.k.),
						'one' => q({0} o.k.),
						'other' => q({0} o.k.),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kVt),
						'one' => q({0} kVt),
						'other' => q({0} kVt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kVt),
						'one' => q({0} kVt),
						'other' => q({0} kVt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(MVt),
						'one' => q({0} MVt),
						'other' => q({0} MVt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(MVt),
						'one' => q({0} MVt),
						'other' => q({0} MVt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(mVt),
						'one' => q({0} mVt),
						'other' => q({0} mVt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(mVt),
						'one' => q({0} mVt),
						'other' => q({0} mVt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(Vt),
						'one' => q({0} Vt),
						'other' => q({0} Vt),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(Vt),
						'one' => q({0} Vt),
						'other' => q({0} Vt),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(gPa),
						'one' => q({0} gPa),
						'other' => q({0} gPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(gPa),
						'one' => q({0} gPa),
						'other' => q({0} gPa),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(funt/dy.kv),
						'one' => q({0} funt/dy.kv),
						'other' => q({0} funt/dy.kv),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(funt/dy.kv),
						'one' => q({0} funt/dy.kv),
						'other' => q({0} funt/dy.kv),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/soat),
						'one' => q({0} km/soat),
						'other' => q({0} km/soat),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/soat),
						'one' => q({0} km/soat),
						'other' => q({0} km/soat),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(uzel),
						'one' => q({0} uzel),
						'other' => q({0} uzel),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(uzel),
						'one' => q({0} uzel),
						'other' => q({0} uzel),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mil/soat),
						'one' => q({0} mil/soat),
						'other' => q({0} mil/soat),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mil/soat),
						'one' => q({0} mil/soat),
						'other' => q({0} mil/soat),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(funt-kuch-fut),
						'one' => q({0} funt-kuch-fut),
						'other' => q({0} funt-kuch-fut),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(funt-kuch-fut),
						'one' => q({0} funt-kuch-fut),
						'other' => q({0} funt-kuch-fut),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(akrofut),
						'one' => q({0} akrofut),
						'other' => q({0} akrofut),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(akrofut),
						'one' => q({0} akrofut),
						'other' => q({0} akrofut),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barrel),
						'one' => q({0} barrel),
						'other' => q({0} barrel),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barrel),
						'one' => q({0} barrel),
						'other' => q({0} barrel),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushel),
						'one' => q({0} bushel),
						'other' => q({0} bushel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushel),
						'one' => q({0} bushel),
						'other' => q({0} bushel),
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
					'volume-cubic-centimeter' => {
						'name' => q(sm³),
						'one' => q({0} sm³),
						'other' => q({0} sm³),
						'per' => q({0}/sm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(sm³),
						'one' => q({0} sm³),
						'other' => q({0} sm³),
						'per' => q({0}/sm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kub fut),
						'one' => q({0} kub fut),
						'other' => q({0} kub fut),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kub fut),
						'one' => q({0} kub fut),
						'other' => q({0} kub fut),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(kub duym),
						'one' => q({0} kub duym),
						'other' => q({0} kub duym),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(kub duym),
						'one' => q({0} kub duym),
						'other' => q({0} kub duym),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(kub mil),
						'one' => q({0} kub mil),
						'other' => q({0} kub mil),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(kub mil),
						'one' => q({0} kub mil),
						'other' => q({0} kub mil),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(kub yard),
						'one' => q({0} yard³),
						'other' => q({0} yard³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(kub yard),
						'one' => q({0} yard³),
						'other' => q({0} yard³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(piyola),
						'one' => q({0} piyola),
						'other' => q({0} piyola),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(piyola),
						'one' => q({0} piyola),
						'other' => q({0} piyola),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(m. piyola),
						'one' => q({0} m. piyola),
						'other' => q({0} m. piyola),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(m. piyola),
						'one' => q({0} m. piyola),
						'other' => q({0} m. piyola),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(desert qoshiq),
						'one' => q({0} desert qoshiq),
						'other' => q({0} desert qoshiq),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(desert qoshiq),
						'one' => q({0} desert qoshiq),
						'other' => q({0} desert qoshiq),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(imp desert qoshiq),
						'one' => q({0} imp desert qoshiq),
						'other' => q({0} imp desert qoshiq),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(imp desert qoshiq),
						'one' => q({0} imp desert qoshiq),
						'other' => q({0} imp desert qoshiq),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(suyuqlik draxmasi),
						'one' => q({0} suyuqlik draxmasi),
						'other' => q({0} suyuqlik draxmasi),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(suyuqlik draxmasi),
						'one' => q({0} suyuqlik draxmasi),
						'other' => q({0} suyuqlik draxmasi),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(tomchi),
						'one' => q({0} tomchi),
						'other' => q({0} tomchi),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(tomchi),
						'one' => q({0} tomchi),
						'other' => q({0} tomchi),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(suyuq unsiya),
						'one' => q({0} suyuq unsiya),
						'other' => q({0} suyuq unsiya),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(suyuq unsiya),
						'one' => q({0} suyuq unsiya),
						'other' => q({0} suyuq unsiya),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(ingliz suyuq unsiyasi),
						'one' => q({0} ing. suyuq uns.),
						'other' => q({0} ing. suyuq uns.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(ingliz suyuq unsiyasi),
						'one' => q({0} ing. suyuq uns.),
						'other' => q({0} ing. suyuq uns.),
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
						'name' => q(imp. gal.),
						'one' => q({0} imp. gal.),
						'other' => q({0} imp. gal.),
						'per' => q({0} imp. gal.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(imp. gal.),
						'one' => q({0} imp. gal.),
						'other' => q({0} imp. gal.),
						'per' => q({0} imp. gal.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(gL),
						'one' => q({0} gL),
						'other' => q({0} gL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(gL),
						'one' => q({0} gL),
						'other' => q({0} gL),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(qadah),
						'one' => q({0} qadah),
						'other' => q({0} qadah),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(qadah),
						'one' => q({0} qadah),
						'other' => q({0} qadah),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litr),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litr),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(chimdim),
						'one' => q({0} chimdim),
						'other' => q({0} chimdim),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(chimdim),
						'one' => q({0} chimdim),
						'other' => q({0} chimdim),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kvart),
						'one' => q({0} kvart),
						'other' => q({0} kvart),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kvart),
						'one' => q({0} kvart),
						'other' => q({0} kvart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(imp kvarta),
						'one' => q({0} imp. kvarta),
						'other' => q({0} imp. kvarta),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(imp kvarta),
						'one' => q({0} imp. kvarta),
						'other' => q({0} imp. kvarta),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(osh qoshiq),
						'one' => q({0} osh qoshiq),
						'other' => q({0} osh qoshiq),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(osh qoshiq),
						'one' => q({0} osh qoshiq),
						'other' => q({0} osh qoshiq),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(choy qoshiq),
						'one' => q({0} choy qoshiq),
						'other' => q({0} choy qoshiq),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(choy qoshiq),
						'one' => q({0} choy qoshiq),
						'other' => q({0} choy qoshiq),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ha|h)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:yo‘q|y|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} va {1}),
				2 => q({0} va {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arabext' => {
			'minusSign' => q(-),
			'nan' => q(son emas),
			'plusSign' => q(+),
		},
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
			'nan' => q(son emas),
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
					'one' => '0 ming',
					'other' => '0 ming',
				},
				'10000' => {
					'one' => '00 ming',
					'other' => '00 ming',
				},
				'100000' => {
					'one' => '000 ming',
					'other' => '000 ming',
				},
				'1000000' => {
					'one' => '0 million',
					'other' => '0 million',
				},
				'10000000' => {
					'one' => '00 million',
					'other' => '00 million',
				},
				'100000000' => {
					'one' => '000 million',
					'other' => '000 million',
				},
				'1000000000' => {
					'one' => '0 milliard',
					'other' => '0 milliard',
				},
				'10000000000' => {
					'one' => '00 milliard',
					'other' => '00 milliard',
				},
				'100000000000' => {
					'one' => '000 milliard',
					'other' => '000 milliard',
				},
				'1000000000000' => {
					'one' => '0 trillion',
					'other' => '0 trillion',
				},
				'10000000000000' => {
					'one' => '00 trillion',
					'other' => '00 trillion',
				},
				'100000000000000' => {
					'one' => '000 trillion',
					'other' => '000 trillion',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 ming',
					'other' => '0 ming',
				},
				'10000' => {
					'one' => '00 ming',
					'other' => '00 ming',
				},
				'100000' => {
					'one' => '000 ming',
					'other' => '000 ming',
				},
				'1000000' => {
					'one' => '0 mln',
					'other' => '0 mln',
				},
				'10000000' => {
					'one' => '00 mln',
					'other' => '00 mln',
				},
				'100000000' => {
					'one' => '000 mln',
					'other' => '000 mln',
				},
				'1000000000' => {
					'one' => '0 mlrd',
					'other' => '0 mlrd',
				},
				'10000000000' => {
					'one' => '00 mlrd',
					'other' => '00 mlrd',
				},
				'100000000000' => {
					'one' => '000 mlrd',
					'other' => '000 mlrd',
				},
				'1000000000000' => {
					'one' => '0 trln',
					'other' => '0 trln',
				},
				'10000000000000' => {
					'one' => '00 trln',
					'other' => '00 trln',
				},
				'100000000000000' => {
					'one' => '000 trln',
					'other' => '000 trln',
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
				'currency' => q(Birlashgan Arab Amirliklari dirhami),
				'one' => q(BAA dirhami),
				'other' => q(BAA dirhami),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afg‘oniston afg‘oniysi),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Albaniya leki),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armaniston drami),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Niderlandiya antil guldeni),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angola kvanzasi),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentina pesosi),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Avstraliya dollari),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruba florini),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Ozarbayjon manati),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosniya va Gertsegovina ayirboshlash markasi),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbados dollari),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bangladesh takasi),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bolgariya levi),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahrayn dinori),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi franki),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda dollari),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Bruney dollari),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviya bolivianosi),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Braziliya reali),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bagama dollari),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Butan ngultrumi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botsvana pulasi),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Belarus rubli),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Belarus rubli \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Beliz dollari),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanada dollari),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Kongo franki),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Shveytsariya franki),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Chili pesosi),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Xitoy yuani \(ofshor\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Xitoy yuani),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Kolumbiya pesosi),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Kosta-Rika koloni),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Kuba ayirboshlash pesosi),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Kuba pesosi),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kabo-Verde eskudosi),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Chexiya kronasi),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Jibuti franki),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Daniya kronasi),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominikana pesosi),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Jazoir dinori),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Misr funti),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritreya nakfasi),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Efiopiya biri),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yevro),
				'one' => q(yevro),
				'other' => q(yevro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fiji dollari),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Folklend orollari funti),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Angliya funt sterlingi),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Gruziya larisi),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Gana sedisi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltar funti),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambiya dalasisi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Gvineya franki),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Gvatemala ketsali),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Gayana dollari),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Gonkong dollari),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Gonduras lempirasi),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Xorvatiya kunasi),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gaiti gurdi),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Vengriya forinti),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indoneziya rupiyasi),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Isroil yangi shekeli),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Hindiston rupiyasi),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Iroq dinori),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Eron riyoli),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Islandiya kronasi),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Yamayka dollari),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Iordaniya dinori),
				'one' => q(Yordaniya dinori),
				'other' => q(Iordaniya dinori),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yaponiya iyenasi),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Keniya shillingi),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Qirg‘iziston somi),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Kambodja rieli),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komor orollari franki),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Shimoliy Koreya voni),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Janubiy Koreya voni),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuvayt dinori),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Kayman orollari dollari),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Qozog‘iston tengesi),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laos kipi),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Livan funti),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Shri-Lanka rupiyasi),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberiya dollari),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesoto lotisi),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litva liti),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Latviya lati),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Liviya dinori),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Marokash dirhami),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldova leyi),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Malagasi ariarisi),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Makedoniya dinori),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Myanma kyati),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongoliya tugriki),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Makao patakasi),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mavritaniya uqiyasi \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mavritaniya uqiyasi),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mavritaniya rupiyasi),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Maldiv rupiyasi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malavi kvachasi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Meksika pesosi),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Malayziya ringgiti),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mozambik metikali),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibiya dollari),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigeriya nayrasi),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nikaragua kordobasi),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norvegiya kronasi),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepal rupiyasi),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Yangi Zelandiya dollari),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Ummon riyoli),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panama balboasi),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peru soli),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papua – Yangi Gvineya kinasi),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filippin pesosi),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pokiston rupiyasi),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Polsha zlotiyi),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paragvay guaranisi),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Qatar riyoli),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Ruminiya leyi),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serbiya dinori),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rossiya rubli),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Ruanda franki),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudiya Arabistoni riyoli),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Solomon orollari dollari),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seyshel rupiyasi),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudan funti),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Shvetsiya kronasi),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singapur dollari),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Muqaddas Yelena oroli funti),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Syerra-Leone leonesi),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Syerra-Leone leonesi \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somali shillingi),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinam dollari),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Janubiy Sudan funti),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(San-Tome va Prinsipi dobrasi \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(San-Tome va Prinsipi dobrasi),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Suriya funti),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Svazilend lilangenisi),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Tailand bati),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tojikiston somoniysi),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Turkmaniston manati),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunis dinori),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tonga paangasi),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Turk lirasi),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad va Tobago dollari),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Yangi Tayvan dollari),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzaniya shillingi),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ukraina grivnasi),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Uganda shillingi),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(AQSH dollari),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Urugvay pesosi),
			},
		},
		'UZS' => {
			symbol => 'soʻm',
			display_name => {
				'currency' => q(O‘zbekiston so‘mi),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Venesuela bolivari \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venesuela bolivari),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Vyetnam dongi),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatu vatusi),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoa talasi),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Markaziy Afrika CFA franki),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Sharqiy Karib dollari),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(G‘arbiy Afrika CFA franki),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Fransuz Polineziyasi franki),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Noma’lum valyuta),
				'one' => q(\(noma’lum valyuta\)),
				'other' => q(\(noma’lum valyuta\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Yaman riyoli),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Janubiy Afrika rendi),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Zambiya kvachasi),
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
							'yan',
							'fev',
							'mar',
							'apr',
							'may',
							'iyn',
							'iyl',
							'avg',
							'sen',
							'okt',
							'noy',
							'dek'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'yanvar',
							'fevral',
							'mart',
							'aprel',
							'may',
							'iyun',
							'iyul',
							'avgust',
							'sentabr',
							'oktabr',
							'noyabr',
							'dekabr'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Yan',
							'Fev',
							'Mar',
							'Apr',
							'May',
							'Iyn',
							'Iyl',
							'Avg',
							'Sen',
							'Okt',
							'Noy',
							'Dek'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'Y',
							'F',
							'M',
							'A',
							'M',
							'I',
							'I',
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
							'Yanvar',
							'Fevral',
							'Mart',
							'Aprel',
							'May',
							'Iyun',
							'Iyul',
							'Avgust',
							'Sentabr',
							'Oktabr',
							'Noyabr',
							'Dekabr'
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
							'Muh.',
							'Saf.',
							'Rob. avv.',
							'Rob. ox.',
							'Jum. avv.',
							'Jum. ox.',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shav.',
							'Zul-q.',
							'Zul-h.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Muharram',
							'Safar',
							'Robi’ ul-avval',
							'Robi’ ul-oxir',
							'Jumad ul-avval',
							'Jumad ul-oxir',
							'Rajab',
							'Sha’bon',
							'Ramazon',
							'Shavvol',
							'Zul-qa’da',
							'Zul-hijja'
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
							'farvardin',
							'oʻrdibehisht',
							'xurdod',
							'tir',
							'murdod',
							'shahrivar',
							'mehr',
							'obon',
							'ozar',
							'dey',
							'bahman',
							'isfan'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'farvardin',
							'oʻrdibehisht',
							'xurdod',
							'tir',
							'murdod',
							'shahrivar',
							'mehr',
							'obon',
							'ozar',
							'dey',
							'bahman',
							'isfand'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'farvardin',
							'oʻrdibehisht',
							'xurdod',
							'tur',
							'murdod',
							'shahrivar',
							'mehr',
							'obon',
							'ozar',
							'dey',
							'bahman',
							'isfand'
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
						mon => 'Dush',
						tue => 'Sesh',
						wed => 'Chor',
						thu => 'Pay',
						fri => 'Jum',
						sat => 'Shan',
						sun => 'Yak'
					},
					short => {
						mon => 'Du',
						tue => 'Se',
						wed => 'Ch',
						thu => 'Pa',
						fri => 'Ju',
						sat => 'Sh',
						sun => 'Ya'
					},
					wide => {
						mon => 'dushanba',
						tue => 'seshanba',
						wed => 'chorshanba',
						thu => 'payshanba',
						fri => 'juma',
						sat => 'shanba',
						sun => 'yakshanba'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'D',
						tue => 'S',
						wed => 'C',
						thu => 'P',
						fri => 'J',
						sat => 'S',
						sun => 'Y'
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
					abbreviated => {0 => '1-ch',
						1 => '2-ch',
						2 => '3-ch',
						3 => '4-ch'
					},
					wide => {0 => '1-chorak',
						1 => '2-chorak',
						2 => '3-chorak',
						3 => '4-chorak'
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
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1100;
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
					'afternoon1' => q{kunduzi},
					'am' => q{TO},
					'evening1' => q{kechqurun},
					'midnight' => q{yarim tun},
					'morning1' => q{ertalab},
					'night1' => q{kechasi},
					'noon' => q{tush payti},
					'pm' => q{TK},
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
				'0' => 'm.a.',
				'1' => 'milodiy'
			},
			wide => {
				'0' => 'miloddan avvalgi'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'hijriy'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => 'forsiy'
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
			'full' => q{EEEE, d-MMMM, y (G)},
			'long' => q{d-MMMM, y (G)},
			'medium' => q{d-MMM, y (G)},
			'short' => q{dd.MM.y (GGGGG)},
		},
		'gregorian' => {
			'full' => q{EEEE, d-MMMM, y},
			'long' => q{d-MMMM, y},
			'medium' => q{d-MMM, y},
			'short' => q{dd/MM/yy},
		},
		'islamic' => {
		},
		'persian' => {
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
			'full' => q{H:mm:ss (zzzz)},
			'long' => q{H:mm:ss (z)},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
		},
		'islamic' => {
		},
		'persian' => {
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
		'islamic' => {
		},
		'persian' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			EBhm => q{E, B h:mm},
			EBhms => q{E, B h:mm:ss},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E, h:mm (a)},
			Ehms => q{E, h:mm:ss (a)},
			Gy => q{y (G)},
			GyMMM => q{MMM, y (G)},
			GyMMMEd => q{E, d-MMM, y (G)},
			GyMMMd => q{d-MMM, y (G)},
			GyMd => q{dd.MM.y GGGGG},
			MEd => q{E, dd.MM},
			MMMEd => q{E, d-MMM},
			MMMMd => q{d-MMMM},
			MMMd => q{d-MMM},
			Md => q{dd.MM},
			h => q{h (a)},
			hm => q{h:mm (a)},
			hms => q{h:mm:ss (a)},
			y => q{y (G)},
			yyyy => q{y (G)},
			yyyyM => q{MM.y (GGGGG)},
			yyyyMEd => q{E, dd.MM.y (GGGGG)},
			yyyyMMM => q{y (G), MMM},
			yyyyMMMEd => q{E, d-MMM, y (G)},
			yyyyMMMM => q{y (G), MMMM},
			yyyyMMMd => q{d-MMM, y (G)},
			yyyyMd => q{dd.MM.y (GGGGG)},
			yyyyQQQ => q{y (G), QQQ},
			yyyyQQQQ => q{y (G), QQQQ},
		},
		'gregorian' => {
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			EBhm => q{E, B h:mm},
			EBhms => q{E, B h:mm:ss},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			GyMMM => q{MMM, G y},
			GyMMMEd => q{E, d-MMM, G y},
			GyMMMd => q{d-MMM, G y},
			GyMd => q{dd.MM.y GGGGG},
			Hmsv => q{HH:mm:ss (v)},
			Hmv => q{HH:mm (v)},
			M => q{LL},
			MEd => q{E, dd/MM},
			MMMEd => q{E, d-MMM},
			MMMMW => q{MMMM, W-'hafta'},
			MMMMd => q{d-MMMM},
			MMMd => q{d-MMM},
			Md => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a (v)},
			hmv => q{h:mm a (v)},
			yM => q{MM.y},
			yMEd => q{E, dd/MM/y},
			yMMM => q{MMM, y},
			yMMMEd => q{E, d-MMM, y},
			yMMMM => q{MMMM, y},
			yMMMd => q{d-MMM, y},
			yMd => q{dd/MM/y},
			yQQQ => q{y, QQQ},
			yQQQQ => q{y, QQQQ},
			yw => q{Y, w-'hafta'},
		},
		'islamic' => {
			yyyyMMM => q{MMM, y (G)},
			yyyyMMMM => q{MMMM, y G},
			yyyyMMMd => q{d-MMM, y G},
			yyyyQQQ => q{QQQ, y (G)},
			yyyyQQQQ => q{QQQQ, y (G)},
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
				B => q{B h – B h},
				h => q{B h – h},
			},
			Bhm => {
				B => q{B h:mm – B h:mm},
				h => q{B h:mm–h:mm},
				m => q{B h:mm – h:mm},
			},
			Gy => {
				G => q{G y – G y},
			},
			GyM => {
				G => q{M/y (GGGGG) – M/y (GGGGG)},
				M => q{M/y – M/y (GGGGG)},
				y => q{M/y – M/y (GGGGG)},
			},
			GyMEd => {
				G => q{E, d/M/y (GGGGG) – E, d/M/y (GGGGG)},
				M => q{E, d/M/y – E, d/M/y (GGGGG)},
				d => q{E, d/M/y – E, d/M/y (GGGGG)},
				y => q{E, d/M/y – E, d/M/y (GGGGG)},
			},
			GyMMM => {
				G => q{MMM G y – MMM G y},
				M => q{MMM – MMM, G y},
				y => q{MMM y – MMM y (G)},
			},
			GyMMMEd => {
				G => q{E, d-MMM, G y – E, d-MMM, G y},
				M => q{E, d-MMM – E, d-MMM, G y},
				d => q{E, d-MMM – E, d-MMM, G y},
				y => q{E, d-MMM, y – E, d-MMM, y (G)},
			},
			GyMMMd => {
				G => q{d-MMM, G y – d-MMM, G y},
				M => q{d-MMM – d-MMM, G y},
				d => q{d – d-MMM, G y},
				y => q{d-MMM, y – d-MMM, y (G)},
			},
			GyMd => {
				G => q{d/M/y (GGGGG) – d/M/y (GGGGG)},
				M => q{d/M/y – d/M/y (GGGGG)},
				d => q{d/M/y – d/M/y (GGGGG)},
				y => q{d/M/y – d/M/y (GGGGG)},
			},
			MEd => {
				M => q{E, dd.MM – E, dd.MM},
				d => q{E, dd.MM – E, dd.MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d-MMM – E, d-MMM},
				d => q{E, d-MMM – E, d-MMM},
			},
			MMMd => {
				M => q{d-MMM – d-MMM},
				d => q{d – d-MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			y => {
				y => q{y–y (G)},
			},
			yM => {
				M => q{MM.y – MM.y (GGGGG)},
				y => q{MM.y – MM.y (GGGGG)},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y (GGGGG)},
				d => q{E, dd.MM.y – E, dd.MM.y (GGGGG)},
				y => q{E, dd.MM.y – E, dd.MM.y (GGGGG)},
			},
			yMMM => {
				M => q{y (G), MMM – MMM},
				y => q{y (G), MMM – y, MMM},
			},
			yMMMEd => {
				M => q{E, d-MMM – E, d-MMM, y (G)},
				d => q{E, d-MMM – E, d-MMM, y (G)},
				y => q{E, d-MMM, y – E, d-MMM, y (G)},
			},
			yMMMM => {
				M => q{MMMM – MMMM, y (G)},
				y => q{MMMM, y – MMMM, y (G)},
			},
			yMMMd => {
				M => q{d-MMM – d-MMM, y (G)},
				d => q{d – d-MMM, y (G)},
				y => q{d-MMM, y – d-MMM, y (G)},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y (GGGGG)},
				d => q{dd.MM.y – dd.MM.y (GGGGG)},
				y => q{dd.MM.y – dd.MM.y (GGGGG)},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{B h – B h},
				h => q{B h – h},
			},
			Bhm => {
				B => q{B h:mm – B h:mm},
				h => q{B h:mm – h:mm},
				m => q{B h:mm – h:mm},
			},
			Gy => {
				G => q{G y – G y},
			},
			GyM => {
				G => q{M/y (G) – M/y (G)},
				M => q{M/y – M/y (G)},
				y => q{M/y – M/y (G)},
			},
			GyMEd => {
				G => q{E, M/d/y (G) – E, M/d/y (G)},
				M => q{E, M/d/y – E, M/d/y (G)},
				d => q{E, M/d/y – E, M/d/y (G)},
				y => q{E, M/d/y – E, M/d/y (G)},
			},
			GyMMM => {
				G => q{MMM, G y – MMM, G y},
				M => q{MMM–MMM, G y},
				y => q{MMM, y – MMM, y (G)},
			},
			GyMMMEd => {
				G => q{E, d-MMM, G y – E, d-MMM, G y},
				M => q{E, d-MMM – E, d-MMM, G y},
				d => q{E, d-MMM – E, d-MMM, G y},
				y => q{E, d-MMM, y – E, d-MMM, y (G)},
			},
			GyMMMd => {
				G => q{d-MMM, G y – d-MMM, G y},
				M => q{d-MMM – d-MMM, G y},
				d => q{d – d-MMM, G y},
				y => q{d-MMM, y – d-MMM, y (G)},
			},
			GyMd => {
				G => q{M/d/y (G) – M/d/y (G)},
				M => q{M/d/y – M/d/y (G)},
				d => q{M/d/y – M/d/y (G)},
				y => q{M/d/y – M/d/y (G)},
			},
			Hmv => {
				H => q{HH:mm–HH:mm (v)},
				m => q{HH:mm–HH:mm (v)},
			},
			Hv => {
				H => q{HH–HH (v)},
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
				M => q{E, d-MMM – E, d-MMM},
				d => q{E, d-MMM – E, d-MMM},
			},
			MMMd => {
				M => q{d-MMM – d-MMM},
				d => q{d – d-MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
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
				a => q{h:mm a – h:mm a (v)},
				h => q{h:mm–h:mm a (v)},
				m => q{h:mm–h:mm a (v)},
			},
			hv => {
				a => q{h a – h a (v)},
				h => q{h–h a (v)},
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
				M => q{MMM – MMM, y},
				y => q{MMM, y – MMM, y},
			},
			yMMMEd => {
				M => q{E, d-MMM – E, d-MMM, y},
				d => q{E, d-MMM – E, d-MMM, y},
				y => q{E, d-MMM, y – E, d-MMM, y},
			},
			yMMMM => {
				M => q{MMMM – MMMM, y},
				y => q{MMMM, y – MMMM, y},
			},
			yMMMd => {
				M => q{d-MMM – d-MMM, y},
				d => q{d – d-MMM, y},
				y => q{d-MMM, y – d-MMM, y},
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
		'Afghanistan' => {
			long => {
				'standard' => q#Afgʻoniston vaqti#,
			},
		},
		'Africa/Accra' => {
			exemplarCity => q#Akkra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis-Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Jazoir#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmera#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangi#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantayr#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzavil#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Qohira#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kasablanka#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Seuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakri#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dor-us-Salom#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Jibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Duala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Al-Ayun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Fritaun#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Xarare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Yoxannesburg#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Xartum#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Librevil#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputu#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadisho#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monroviya#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nayrobi#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uagadugu#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#San-Tome#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Vindxuk#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Markaziy Afrika vaqti#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Sharqiy Afrika vaqti#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Janubiy Afrika standart vaqti#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Gʻarbiy Afrika yozgi vaqti#,
				'generic' => q#Gʻarbiy Afrika vaqti#,
				'standard' => q#Gʻarbiy Afrika standart vaqti#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alyaska yozgi vaqti#,
				'generic' => q#Alyaska vaqti#,
				'standard' => q#Alyaska standart vaqti#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazonka yozgi vaqti#,
				'generic' => q#Amazonka vaqti#,
				'standard' => q#Amazonka standart vaqti#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak oroli#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Ankorij#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Angilya#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La-Rioxa#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio-Galyegos#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San-Xuan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San-Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tukuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaya#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunson#,
		},
		'America/Bahia' => {
			exemplarCity => q#Baiya#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahiya-Banderas#,
		},
		'America/Belize' => {
			exemplarCity => q#Beliz#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blank-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa-Vista#,
		},
		'America/Boise' => {
			exemplarCity => q#Boyse#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos-Ayres#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kembrij-Bey#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Kampu-Grandi#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kankun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamarka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kayenna#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kayman orollari#,
		},
		'America/Chicago' => {
			exemplarCity => q#Chikago#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Koral-Xarbor#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta-Rika#,
		},
		'America/Creston' => {
			exemplarCity => q#Kreston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kuyaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kyurasao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Denmarksxavn#,
		},
		'America/Dawson' => {
			exemplarCity => q#Douson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Douson-Krik#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroyt#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eyrunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Gleys-Bey#,
		},
		'America/Godthab' => {
			exemplarCity => q#Gotxob#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Gus-Bey#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Gvadelupa#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Gvatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayakil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Gayana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Galifaks#,
		},
		'America/Havana' => {
			exemplarCity => q#Gavana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Ermosillo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Noks, Indiana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Pitersberg, Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell-Siti, Indiana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vivey, Indiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vinsens, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Vinamak, Indiana#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ikaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Yamayka#,
		},
		'America/Juneau' => {
			exemplarCity => q#Juno#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Montisello, Kentukki#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendeyk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La-Pas#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los-Anjeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Luisvill#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Louer-Prinses-Kuorter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maseyo#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigo#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinika#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Masatlan#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menomini#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexiko#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Monkton#,
		},
		'America/New_York' => {
			exemplarCity => q#Nyu-York#,
		},
		'America/Nome' => {
			exemplarCity => q#Nom#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronya#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Boyla, Shimoliy Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Markaz, Shimoliy Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Nyu-Salem, Shimoliy Dakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Oxinaga#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pangnirtang#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Feniks#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-o-Prens#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port-of-Speyn#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Portu-Velyu#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto-Riko#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta-Arenas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Reyni-River#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin-Inlet#,
		},
		'America/Recife' => {
			exemplarCity => q#Resifi#,
		},
		'America/Regina' => {
			exemplarCity => q#Rejayna#,
		},
		'America/Resolute' => {
			exemplarCity => q#Rezolyut#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Riu-Branku#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa-Izabel#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santyago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo-Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#San-Paulu#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittokkortoormiut#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sen-Bartelemi#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sent-Jons#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sent-Kits#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sent-Lyusiya#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sent-Tomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sent-Vinsent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Svift-Karrent#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegusigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Tule#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Tander-Bey#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tixuana#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vankuver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Uaytxors#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Vinnipeg#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yellounayf#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Markaziy Amerika yozgi vaqti#,
				'generic' => q#Markaziy Amerika vaqti#,
				'standard' => q#Markaziy Amerika standart vaqti#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Sharqiy Amerika yozgi vaqti#,
				'generic' => q#Sharqiy Amerika vaqti#,
				'standard' => q#Sharqiy Amerika standart vaqti#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Tog‘ yozgi vaqti (AQSH)#,
				'generic' => q#Tog‘ vaqti (AQSH)#,
				'standard' => q#Tog‘ standart vaqti (AQSH)#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Tinch okeani yozgi vaqti#,
				'generic' => q#Tinch okeani vaqti#,
				'standard' => q#Tinch okeani standart vaqti#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Keysi#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Deyvis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dyumon-d’Yurvil#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makkuori#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mouson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#Mak-Merdo#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rotera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Syova#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia yozgi vaqti#,
				'generic' => q#Apia vaqti#,
				'standard' => q#Apia standart vaqti#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Saudiya Arabistoni yozgi vaqti#,
				'generic' => q#Saudiya Arabistoni vaqti#,
				'standard' => q#Saudiya Arabistoni standart vaqti#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyir#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentina yozgi vaqti#,
				'generic' => q#Argentina vaqti#,
				'standard' => q#Argentina standart vaqti#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Gʻarbiy Argentina yozgi vaqti#,
				'generic' => q#Gʻarbiy Argentina vaqti#,
				'standard' => q#Gʻarbiy Argentina standart vaqti#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armaniston yozgi vaqti#,
				'generic' => q#Armaniston vaqti#,
				'standard' => q#Armaniston standart vaqti#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Adan#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almati#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Ammon#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadir#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Oqtov#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Oqto‘ba#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ashxobod#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atirau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bag‘dod#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrayn#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Boku#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bayrut#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Bruney#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkutta#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Choybalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damashq#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dakka#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubay#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#G‘azo#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Xevron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Gonkong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Xovd#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jaypur#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Quddus#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Qobul#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Xandiga#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala-Lumpur#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Quvayt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Maskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosiya#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Uralsk#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Pnompen#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pxenyan#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kustanay#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qizilo‘rda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangun#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Ar-Riyod#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Xoshimin#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Saxalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarqand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanxay#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolimsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taypey#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Toshkent#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tehron#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan-Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumchi#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vyentyan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantika yozgi vaqti#,
				'generic' => q#Atlantika vaqti#,
				'standard' => q#Atlantika standart vaqti#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azor orollari#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda orollari#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanar orollari#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kabo-Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Farer orollari#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeyra oroli#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykyavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Janubiy Georgiya#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Muqaddas Yelena oroli#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stenli#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaida#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisben#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Broken-Xill#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Kerri#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darvin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Evkla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Xobart#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lord-Xau oroli#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melburn#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Pert#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Markaziy Avstraliya yozgi vaqti#,
				'generic' => q#Markaziy Avstraliya vaqti#,
				'standard' => q#Markaziy Avstraliya standart vaqti#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Markaziy Avstraliya g‘arbiy yozgi vaqti#,
				'generic' => q#Markaziy Avstraliya g‘arbiy vaqti#,
				'standard' => q#Markaziy Avstraliya g‘arbiy standart vaqti#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Sharqiy Avstraliya yozgi vaqti#,
				'generic' => q#Sharqiy Avstraliya vaqti#,
				'standard' => q#Sharqiy Avstraliya standart vaqti#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#G‘arbiy Avstraliya yozgi vaqti#,
				'generic' => q#G‘arbiy Avstraliya vaqti#,
				'standard' => q#G‘arbiy Avstraliya standart vaqti#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Ozarbayjon yozgi vaqti#,
				'generic' => q#Ozarbayjon vaqti#,
				'standard' => q#Ozarbayjon standart vaqti#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azor orollari yozgi vaqti#,
				'generic' => q#Azor orollari vaqti#,
				'standard' => q#Azor orollari standart vaqti#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladesh yozgi vaqti#,
				'generic' => q#Bangladesh vaqti#,
				'standard' => q#Bangladesh standart vaqti#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Butan vaqti#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Boliviya vaqti#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Braziliya yozgi vaqti#,
				'generic' => q#Braziliya vaqti#,
				'standard' => q#Braziliya standart vaqti#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Bruney-Dorussalom vaqti#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kabo-Verde yozgi vaqti#,
				'generic' => q#Kabo-Verde vaqti#,
				'standard' => q#Kabo-Verde standart vaqti#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorro standart vaqti#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatem yozgi vaqti#,
				'generic' => q#Chatem vaqti#,
				'standard' => q#Chatem standart vaqti#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chili yozgi vaqti#,
				'generic' => q#Chili vaqti#,
				'standard' => q#Chili standart vaqti#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Xitoy yozgi vaqti#,
				'generic' => q#Xitoy vaqti#,
				'standard' => q#Xitoy standart vaqti#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Choybalsan yozgi vaqti#,
				'generic' => q#Choybalsan vaqti#,
				'standard' => q#Choybalsan standart vaqti#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Rojdestvo oroli vaqti#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kokos orollari vaqti#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbiya yozgi vaqti#,
				'generic' => q#Kolumbiya vaqti#,
				'standard' => q#Kolumbiya standart vaqti#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Kuk orollari yarim yozgi vaqti#,
				'generic' => q#Kuk orollari vaqti#,
				'standard' => q#Kuk orollari standart vaqti#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kuba yozgi vaqti#,
				'generic' => q#Kuba vaqti#,
				'standard' => q#Kuba standart vaqti#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Deyvis vaqti#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dyumon-d’Yurvil vaqti#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Sharqiy Timor vaqti#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Pasxa oroli yozgi vaqti#,
				'generic' => q#Pasxa oroli vaqti#,
				'standard' => q#Pasxa oroli standart vaqti#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekvador vaqti#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Koordinatali universal vaqt#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#noma’lum shahar#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astraxan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Afina#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bryussel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Buxarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapesht#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Byuzingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kishinyov#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopengagen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Irlandiya yozgi vaqti#,
			},
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Gernsi#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Xelsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Men oroli#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersi#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiyev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lyublyana#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Britaniya yozgi vaqti#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lyuksemburg#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariyexamn#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parij#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgoritsa#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rim#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San-Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarayevo#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopye#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofiya#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokgolm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Ujgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduts#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vena#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnyus#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varshava#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporojye#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Syurix#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Markaziy Yevropa yozgi vaqti#,
				'generic' => q#Markaziy Yevropa vaqti#,
				'standard' => q#Markaziy Yevropa standart vaqti#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Sharqiy Yevropa yozgi vaqti#,
				'generic' => q#Sharqiy Yevropa vaqti#,
				'standard' => q#Sharqiy Yevropa standart vaqti#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Kaliningrad va Minsk vaqti#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#G‘arbiy Yevropa yozgi vaqti#,
				'generic' => q#G‘arbiy Yevropa vaqti#,
				'standard' => q#G‘arbiy Yevropa standart vaqti#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Folklend orollari yozgi vaqti#,
				'generic' => q#Folklend orollari vaqti#,
				'standard' => q#Folklend orollari standart vaqti#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fiji yozgi vaqti#,
				'generic' => q#Fiji vaqti#,
				'standard' => q#Fiji standart vaqti#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Fransuz Gvianasi vaqti#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Fransuz Janubiy hududlari va Antarktika vaqti#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Grinvich o‘rtacha vaqti#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos vaqti#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambye vaqti#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Gruziya yozgi vaqti#,
				'generic' => q#Gruziya vaqti#,
				'standard' => q#Gruziya standart vaqti#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbert orollari vaqti#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Sharqiy Grenlandiya yozgi vaqti#,
				'generic' => q#Sharqiy Grenlandiya vaqti#,
				'standard' => q#Sharqiy Grenlandiya standart vaqti#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#G‘arbiy Grenlandiya yozgi vaqti#,
				'generic' => q#G‘arbiy Grenlandiya vaqti#,
				'standard' => q#G‘arbiy Grenlandiya standart vaqti#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Fors ko‘rfazi standart vaqti#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Gayana vaqti#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Gavayi-aleut yozgi vaqti#,
				'generic' => q#Gavayi-aleut vaqti#,
				'standard' => q#Gavayi-aleut standart vaqti#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Gonkong yozgi vaqti#,
				'generic' => q#Gonkong vaqti#,
				'standard' => q#Gonkong standart vaqti#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Xovd yozgi vaqti#,
				'generic' => q#Xovd vaqti#,
				'standard' => q#Xovd standart vaqti#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Hindiston standart vaqti#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivu#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Rojdestvo oroli#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokos orollari#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komor orollari#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kergelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mae#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldiv orollari#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mavrikiy#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayorka#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reyunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Hind okeani vaqti#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Hindixitoy vaqti#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Markaziy Indoneziya vaqti#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Sharqiy Indoneziya vaqti#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Gʻarbiy Indoneziya vaqti#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Eron yozgi vaqti#,
				'generic' => q#Eron vaqti#,
				'standard' => q#Eron standart vaqti#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutsk yozgi vaqti#,
				'generic' => q#Irkutsk vaqti#,
				'standard' => q#Irkutsk standart vaqti#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Isroil yozgi vaqti#,
				'generic' => q#Isroil vaqti#,
				'standard' => q#Isroil standart vaqti#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Yaponiya yozgi vaqti#,
				'generic' => q#Yaponiya vaqti#,
				'standard' => q#Yaponiya standart vaqti#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Sharqiy Qozogʻiston vaqti#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Gʻarbiy Qozogʻiston vaqti#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Koreya yozgi vaqti#,
				'generic' => q#Koreya vaqti#,
				'standard' => q#Koreya standart vaqti#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae vaqti#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnoyarsk yozgi vaqti#,
				'generic' => q#Krasnoyarsk vaqti#,
				'standard' => q#Krasnoyarsk standart vaqti#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Qirgʻiziston vaqti#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Layn orollari vaqti#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord-Xau yozgi vaqti#,
				'generic' => q#Lord-Xau vaqti#,
				'standard' => q#Lord-Xau standart vaqti#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Makkuori oroli vaqti#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan yozgi vaqti#,
				'generic' => q#Magadan vaqti#,
				'standard' => q#Magadan standart vaqti#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malayziya vaqti#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldiv orollari vaqti#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Markiz orollari vaqti#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshall orollari vaqti#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mavrikiy yozgi vaqti#,
				'generic' => q#Mavrikiy vaqti#,
				'standard' => q#Mavrikiy standart vaqti#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mouson vaqti#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Shimoli-g‘arbiy Meksika yozgi vaqti#,
				'generic' => q#Shimoli-g‘arbiy Meksika vaqti#,
				'standard' => q#Shimoli-g‘arbiy Meksika standart vaqti#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Meksika Tinch okeani yozgi vaqti#,
				'generic' => q#Meksika Tinch okeani vaqti#,
				'standard' => q#Meksika Tinch okeani standart vaqti#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulan-Bator yozgi vaqti#,
				'generic' => q#Ulan-Bator vaqti#,
				'standard' => q#Ulan-Bator standart vaqti#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskva yozgi vaqti#,
				'generic' => q#Moskva vaqti#,
				'standard' => q#Moskva standart vaqti#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanma vaqti#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru vaqti#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepal vaqti#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Yangi Kaledoniya yozgi vaqti#,
				'generic' => q#Yangi Kaledoniya vaqti#,
				'standard' => q#Yangi Kaledoniya standart vaqti#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Yangi Zelandiya yozgi vaqti#,
				'generic' => q#Yangi Zelandiya vaqti#,
				'standard' => q#Yangi Zelandiya standart vaqti#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Nyufaundlend yozgi vaqti#,
				'generic' => q#Nyufaundlend vaqti#,
				'standard' => q#Nyufaundlend standart vaqti#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niuye vaqti#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolk oroli yozgi vaqti#,
				'generic' => q#Norfolk oroli vaqti#,
				'standard' => q#Norfolk oroli standart vaqti#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernandu-di-Noronya yozgi vaqti#,
				'generic' => q#Fernandu-di-Noronya vaqti#,
				'standard' => q#Fernandu-di-Noronya standart vaqti#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk yozgi vaqti#,
				'generic' => q#Novosibirsk vaqti#,
				'standard' => q#Novosibirsk standart vaqti#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk yozgi vaqti#,
				'generic' => q#Omsk vaqti#,
				'standard' => q#Omsk standart vaqti#,
			},
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Oklend#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bugenvil#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Chatem oroli#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Pasxa oroli#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderberi oroli#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambye oroli#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Gvadalkanal#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Gonolulu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Jonston#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kvajaleyn#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markiz orollari#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midvey orollari#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Numea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago-Pago#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitkern#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Ponpei oroli#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Port-Morsbi#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saypan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Taiti oroli#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarava#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Truk orollari#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Ueyk oroli#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Uollis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pokiston yozgi vaqti#,
				'generic' => q#Pokiston vaqti#,
				'standard' => q#Pokiston standart vaqti#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau vaqti#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua-Yangi Gvineya vaqti#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paragvay yozgi vaqti#,
				'generic' => q#Paragvay vaqti#,
				'standard' => q#Paragvay standart vaqti#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru yozgi vaqti#,
				'generic' => q#Peru vaqti#,
				'standard' => q#Peru standart vaqti#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filippin yozgi vaqti#,
				'generic' => q#Filippin vaqti#,
				'standard' => q#Filippin standart vaqti#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Feniks orollari vaqti#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Sen-Pyer va Mikelon yozgi vaqti#,
				'generic' => q#Sen-Pyer va Mikelon vaqti#,
				'standard' => q#Sen-Pyer va Mikelon standart vaqti#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitkern vaqti#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape vaqti#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pxenyan vaqti#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reyunion vaqti#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rotera vaqti#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Saxalin yozgi vaqti#,
				'generic' => q#Saxalin vaqti#,
				'standard' => q#Saxalin standart vaqti#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa yozgi vaqti#,
				'generic' => q#Samoa vaqti#,
				'standard' => q#Samoa standart vaqti#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seyshel orollari vaqti#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapur vaqti#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Solomon orollari vaqti#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Janubiy Georgiya vaqti#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinam vaqti#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syova vaqti#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Taiti vaqti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Tayvan yozgi vaqti#,
				'generic' => q#Tayvan vaqti#,
				'standard' => q#Tayvan standart vaqti#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tojikiston vaqti#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau vaqti#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga yozgi vaqti#,
				'generic' => q#Tonga vaqti#,
				'standard' => q#Tonga standart vaqti#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk vaqti#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmaniston yozgi vaqti#,
				'generic' => q#Turkmaniston vaqti#,
				'standard' => q#Turkmaniston standart vaqti#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu vaqti#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Urugvay yozgi vaqti#,
				'generic' => q#Urugvay vaqti#,
				'standard' => q#Urugvay standart vaqti#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#O‘zbekiston yozgi vaqti#,
				'generic' => q#O‘zbekiston vaqti#,
				'standard' => q#O‘zbekiston standart vaqti#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu yozgi vaqti#,
				'generic' => q#Vanuatu vaqti#,
				'standard' => q#Vanuatu standart vaqti#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venesuela vaqti#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok yozgi vaqti#,
				'generic' => q#Vladivostok vaqti#,
				'standard' => q#Vladivostok standart vaqti#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgograd yozgi vaqti#,
				'generic' => q#Volgograd vaqti#,
				'standard' => q#Volgograd standart vaqti#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostok vaqti#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Ueyk oroli vaqti#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Uollis va Futuna vaqti#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Yakutsk yozgi vaqti#,
				'generic' => q#Yakutsk vaqti#,
				'standard' => q#Yakutsk standart vaqti#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Yekaterinburg yozgi vaqti#,
				'generic' => q#Yekaterinburg vaqti#,
				'standard' => q#Yekaterinburg standart vaqti#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukon vaqti#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
