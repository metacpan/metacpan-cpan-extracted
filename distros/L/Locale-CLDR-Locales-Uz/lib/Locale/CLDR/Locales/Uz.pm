=head1

Locale::CLDR::Locales::Uz - Package for language Uzbek

=cut

package Locale::CLDR::Locales::Uz;
# This file auto generated from Data\common\main\uz.xml
#	on Fri 13 Apr  7:33:45 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
# Need to add code for Key type pattern
sub display_name_pattern {
	my ($self, $name, $region, $script, $variant) = @_;

	my $display_pattern = '{0} ({1})';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0}, {1}', grep {$_} (
		$region,
		$script,
		$variant,
	);

	$display_pattern =~s/\{1\}/$subtags/g;
	return $display_pattern;
}

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
 				'anp' => 'angika',
 				'ar' => 'arab',
 				'ar_001' => 'standart arab',
 				'arn' => 'mapuche',
 				'arp' => 'arapaxo',
 				'as' => 'assam',
 				'asa' => 'asu',
 				'ast' => 'asturiy',
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
 				'ce' => 'chechen',
 				'ceb' => 'sebuan',
 				'cgg' => 'chiga',
 				'ch' => 'chamorro',
 				'chk' => 'chukot',
 				'chm' => 'mari',
 				'cho' => 'choktav',
 				'chr' => 'cheroki',
 				'chy' => 'cheyenn',
 				'ckb' => 'sorani-kurd',
 				'co' => 'korsikan',
 				'crs' => 'kreol (Seyshel)',
 				'cs' => 'chex',
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
 				'dsb' => 'quyi sorbcha',
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
 				'ff' => 'fula',
 				'fi' => 'fincha',
 				'fil' => 'filipincha',
 				'fj' => 'fiji',
 				'fo' => 'farercha',
 				'fon' => 'fon',
 				'fr' => 'fransuzcha',
 				'fr_CA' => 'fransuz (Kanada)',
 				'fr_CH' => 'fransuz (Shveytsariya)',
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
 				'hak' => 'hak',
 				'haw' => 'gavaycha',
 				'he' => 'ivrit',
 				'hi' => 'hind',
 				'hil' => 'hiligaynon',
 				'hmn' => 'xmong',
 				'hr' => 'xorvat',
 				'hsb' => 'yuqori sorb',
 				'hsn' => 'hsn',
 				'ht' => 'gaityan',
 				'hu' => 'venger',
 				'hup' => 'xupa',
 				'hy' => 'arman',
 				'hz' => 'gerero',
 				'ia' => 'interlingva',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonez',
 				'ig' => 'igbo',
 				'ii' => 'sichuan',
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
 				'ky' => 'qirgʻizcha',
 				'la' => 'lotincha',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lb' => 'lyuksemburgcha',
 				'lez' => 'lezgin',
 				'lg' => 'ganda',
 				'li' => 'limburg',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'laos',
 				'loz' => 'lozi',
 				'lrc' => 'shimoliy luri',
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
 				'mn' => 'mo‘g‘ul',
 				'mni' => 'manipur',
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
 				'nan' => 'nan',
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
 				'nl' => 'golland',
 				'nl_BE' => 'flamand',
 				'nmg' => 'kvasio',
 				'nn' => 'norveg-nyunorsk',
 				'nnh' => 'ngiyembun',
 				'nog' => 'no‘g‘ay',
 				'nqo' => 'nko',
 				'nr' => 'janubiy ndebel',
 				'nso' => 'shimoliy soto',
 				'nus' => 'nuer',
 				'nv' => 'navaxo',
 				'ny' => 'cheva',
 				'nyn' => 'nyankole',
 				'oc' => 'oksitan',
 				'om' => 'oromo',
 				'or' => 'oriya',
 				'os' => 'osetin',
 				'pa' => 'panjobcha',
 				'pag' => 'pangasinan',
 				'pam' => 'pampanga',
 				'pap' => 'papiyamento',
 				'pau' => 'palau',
 				'pcm' => 'kreol (Nigeriya)',
 				'pl' => 'polyakcha',
 				'prg' => 'pruss',
 				'ps' => 'pushtu',
 				'pt' => 'portugalcha',
 				'pt_BR' => 'portugal (Braziliya)',
 				'pt_PT' => 'portugal (Yevropa)',
 				'qu' => 'kechua',
 				'quc' => 'kiche',
 				'rap' => 'rapanui',
 				'rar' => 'rarotongan',
 				'rm' => 'romansh',
 				'rn' => 'rundi',
 				'ro' => 'rumincha',
 				'ro_MD' => 'moldovan',
 				'rof' => 'rombo',
 				'root' => 'tub aholi tili',
 				'ru' => 'ruscha',
 				'rup' => 'arumin',
 				'rw' => 'kinyaruanda',
 				'rwk' => 'ruanda',
 				'sa' => 'sanskrit',
 				'sad' => 'sandave',
 				'sah' => 'saxa',
 				'saq' => 'samburu',
 				'sat' => 'santal',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardin',
 				'scn' => 'sitsiliya',
 				'sco' => 'shotland',
 				'sd' => 'sindxi',
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
 				'su' => 'sundan',
 				'suk' => 'sukuma',
 				'sv' => 'shved',
 				'sw' => 'suaxili',
 				'sw_CD' => 'suaxili (Kongo)',
 				'swb' => 'qamar',
 				'syr' => 'suriyacha',
 				'ta' => 'tamil',
 				'te' => 'telugu',
 				'tem' => 'timne',
 				'teo' => 'teso',
 				'tet' => 'tetum',
 				'tg' => 'tojik',
 				'th' => 'tay',
 				'ti' => 'tigrinya',
 				'tig' => 'tigre',
 				'tk' => 'turkman',
 				'tlh' => 'klingon',
 				'tn' => 'tsvana',
 				'to' => 'tongan',
 				'tpi' => 'tok-piksin',
 				'tr' => 'turk',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tt' => 'tatar',
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
 				'wuu' => 'wuu',
 				'xal' => 'qalmoq',
 				'xh' => 'kxosa',
 				'xog' => 'soga',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'idish',
 				'yo' => 'yoruba',
 				'yue' => 'kanton',
 				'zgh' => 'tamazigxt',
 				'zh' => 'xitoy',
 				'zh_Hans' => 'xitoy (soddalashgan)',
 				'zh_Hant' => 'xitoy (an’anaviy)',
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
			'Arab' => 'arab',
 			'Armn' => 'arman',
 			'Beng' => 'bengal',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'brayl',
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
 			'Hans' => 'soddalashgan xitoy',
 			'Hans@alt=stand-alone' => 'soddalashgan xitoy',
 			'Hant' => 'an’anaviy xitoy',
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
 			'Mymr' => 'myanma',
 			'Orya' => 'oriya',
 			'Sinh' => 'singal',
 			'Taml' => 'tamil',
 			'Telu' => 'telugu',
 			'Thaa' => 'taana',
 			'Thai' => 'tay',
 			'Tibt' => 'tibet',
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
 			'EZ' => 'yevrozona',
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
 			'MK' => 'Makedoniya',
 			'MK@alt=variant' => 'Makedoniya (SYRM)',
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
 				'dangi' => q{dangi taqvimi},
 				'ethiopic' => q{habash taqvimi},
 				'gregorian' => q{grigorian taqvimi},
 				'hebrew' => q{yahudiy taqvimi},
 				'islamic' => q{islomiy taqvim},
 				'iso8601' => q{ISO-8601 taqvimi},
 				'japanese' => q{yapon taqvimi},
 				'persian' => q{fors taqvimi},
 				'roc' => q{Mingo taqvimi},
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
 				'jpan' => q{yapon raqamlari},
 				'jpanfin' => q{yapon raqamlari (moliyaviy)},
 				'khmr' => q{kxmer raqamlari},
 				'knda' => q{kannada raqamlari},
 				'laoo' => q{laos raqamlari},
 				'latn' => q{zamonaviy arab raqamlari},
 				'mlym' => q{malayalam raqamlari},
 				'mymr' => q{birma raqamlari},
 				'orya' => q{oriya raqamlari},
 				'roman' => q{rim raqamlari},
 				'romanlow' => q{kichik rim raqamlari},
 				'taml' => q{an’anaviy tamil raqamlari},
 				'tamldec' => q{tamil raqamlari},
 				'telu' => q{telugu raqamlari},
 				'thai' => q{tay raqamlari},
 				'tibt' => q{tibet raqamlari},
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
			auxiliary => qr{[c w]},
			index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'X', 'Y', 'Z', '{Oʻ}', '{Gʻ}', '{Sh}', '{Ch}'],
			main => qr{[a b d e f g h i j k l m n o p q r s t u v x y z {oʻ} {gʻ} {sh} {ch} ʼ]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ’ " “ ” „ « » ( ) \[ \] \{ \} § @ * / \& # ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'X', 'Y', 'Z', '{Oʻ}', '{Gʻ}', '{Sh}', '{Ch}'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'final' => '{0}…',
			'initial' => '…{0}',
			'medial' => '{0}…{1}',
			'word-final' => '{0} …',
			'word-initial' => '… {0}',
			'word-medial' => '{0} … {1}',
		};
	},
);

has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{?},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
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

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h:mm',
				hms => 'h:mm:ss',
				ms => 'm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'acre' => {
						'name' => q(akr),
						'one' => q({0} akr),
						'other' => q({0} akr),
					},
					'acre-foot' => {
						'name' => q(akrofut),
						'one' => q({0} akrofut),
						'other' => q({0} akrofut),
					},
					'ampere' => {
						'name' => q(amper),
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					'arc-minute' => {
						'name' => q(yoy daqiqasi),
						'one' => q({0} yoy daqiqasi),
						'other' => q({0} yoy daqiqasi),
					},
					'arc-second' => {
						'name' => q(yoy soniyasi),
						'one' => q({0} yoy soniyasi),
						'other' => q({0} yoy soniyasi),
					},
					'astronomical-unit' => {
						'name' => q(astronomik birlik),
						'one' => q({0} astronomik birlik),
						'other' => q({0} astronomik birlik),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(bayt),
						'one' => q({0} bayt),
						'other' => q({0} bayt),
					},
					'calorie' => {
						'name' => q(kaloriya),
						'one' => q(kaloriya),
						'other' => q({0} kaloriya),
					},
					'carat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					'celsius' => {
						'name' => q(Selsiy darajasi),
						'one' => q({0} Selsiy darajasi),
						'other' => q({0} Selsiy darajasi),
					},
					'centiliter' => {
						'name' => q(santilitr),
						'one' => q({0} santilitr),
						'other' => q({0} santilitr),
					},
					'centimeter' => {
						'name' => q(santimetr),
						'one' => q({0} santimetr),
						'other' => q({0} santimetr),
						'per' => q({0}/santimetr),
					},
					'century' => {
						'name' => q(asr),
						'one' => q({0} asr),
						'other' => q({0} asr),
					},
					'coordinate' => {
						'east' => q({0} sharqiy uzunlik),
						'north' => q({0} shimoliy kenglik),
						'south' => q({0} janubiy kenglik),
						'west' => q({0} g‘arbiy uzunlik),
					},
					'cubic-centimeter' => {
						'name' => q(kub santimetr),
						'one' => q({0} kub santimetr),
						'other' => q({0} kub santimetr),
						'per' => q({0}/kub santimetr),
					},
					'cubic-foot' => {
						'name' => q(kub fut),
						'one' => q({0} kub fut),
						'other' => q({0} kub fut),
					},
					'cubic-inch' => {
						'name' => q(kub duym),
						'one' => q({0} kub duym),
						'other' => q({0} kub duym),
					},
					'cubic-kilometer' => {
						'name' => q(kub kilometr),
						'one' => q({0} kub kilometr),
						'other' => q({0} kub kilometr),
					},
					'cubic-meter' => {
						'name' => q(kub metr),
						'one' => q({0} kub metr),
						'other' => q({0} kub metr),
						'per' => q({0}/kub metr),
					},
					'cubic-mile' => {
						'name' => q(kub mil),
						'one' => q({0} kub mil),
						'other' => q({0} kub mil),
					},
					'cubic-yard' => {
						'name' => q(kub yard),
						'one' => q({0} kub yard),
						'other' => q({0} kub yard),
					},
					'cup' => {
						'name' => q(piyola),
						'one' => q({0} piyola),
						'other' => q({0} piyola),
					},
					'cup-metric' => {
						'name' => q(metrik piyola),
						'one' => q({0} metrik piyola),
						'other' => q({0} metrik piyola),
					},
					'day' => {
						'name' => q(kun),
						'one' => q({0} kun),
						'other' => q({0} kun),
						'per' => q({0}/kun),
					},
					'deciliter' => {
						'name' => q(detsilitr),
						'one' => q({0} detsilitr),
						'other' => q({0} detsilitr),
					},
					'decimeter' => {
						'name' => q(detsimetr),
						'one' => q({0} detsimetr),
						'other' => q({0} detsimetr),
					},
					'degree' => {
						'name' => q(gradus),
						'one' => q({0} gradus),
						'other' => q({0} gradus),
					},
					'fahrenheit' => {
						'name' => q(Farengeyt darajasi),
						'one' => q({0} Farengeyt darajasi),
						'other' => q({0} Farengeyt darajasi),
					},
					'fluid-ounce' => {
						'name' => q(suyuq unsiya),
						'one' => q({0} suyuq unsiya),
						'other' => q({0} suyuq unsiya),
					},
					'foodcalorie' => {
						'name' => q(kaloriya),
						'one' => q({0} kaloriya),
						'other' => q({0} kaloriya),
					},
					'foot' => {
						'name' => q(fut),
						'one' => q({0} fut),
						'other' => q({0} fut),
						'per' => q({0}/fut),
					},
					'g-force' => {
						'name' => q(gravitatsiya kuchi),
						'one' => q({0} grav. kuchi),
						'other' => q({0} grav. kuchi),
					},
					'gallon' => {
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0}/gallon),
					},
					'gallon-imperial' => {
						'name' => q(imp. gallon),
						'one' => q({0} imp. gallon),
						'other' => q({0} imp. gallon),
						'per' => q({0}/imp. gallon),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					'gigabyte' => {
						'name' => q(gigabayt),
						'one' => q({0} gigabayt),
						'other' => q({0} gigabayt),
					},
					'gigahertz' => {
						'name' => q(gigagers),
						'one' => q({0} gigagers),
						'other' => q({0} gigagers),
					},
					'gigawatt' => {
						'name' => q(gigavatt),
						'one' => q({0} gigavatt),
						'other' => q({0} gigavatt),
					},
					'gram' => {
						'name' => q(gramm),
						'one' => q({0} gramm),
						'other' => q({0} gramm),
						'per' => q({0}/gramm),
					},
					'hectare' => {
						'name' => q(gektar),
						'one' => q({0} gektar),
						'other' => q({0} gektar),
					},
					'hectoliter' => {
						'name' => q(gektolitr),
						'one' => q({0} gektolitr),
						'other' => q({0} gektolitr),
					},
					'hectopascal' => {
						'name' => q(gektopaskal),
						'one' => q({0} gektopaskal),
						'other' => q({0} gektopaskal),
					},
					'hertz' => {
						'name' => q(gers),
						'one' => q({0} gers),
						'other' => q({0} gers),
					},
					'horsepower' => {
						'name' => q(ot kuchi),
						'one' => q({0} ot kuchi),
						'other' => q({0} ot kuchi),
					},
					'hour' => {
						'name' => q(soat),
						'one' => q({0} soat),
						'other' => q({0} soat),
						'per' => q({0}/soat),
					},
					'inch' => {
						'name' => q(duym),
						'one' => q({0} duym),
						'other' => q({0} duym),
						'per' => q({0}/duym),
					},
					'inch-hg' => {
						'name' => q(duym simob ustuni),
						'one' => q({0} duym simob ustuni),
						'other' => q({0} duym simob ustuni),
					},
					'joule' => {
						'name' => q(joul),
						'one' => q({0} joul),
						'other' => q({0} joul),
					},
					'karat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					'kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					'kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					'kilobyte' => {
						'name' => q(kilobayt),
						'one' => q({0} kilobayt),
						'other' => q({0} kilobayt),
					},
					'kilocalorie' => {
						'name' => q(kilokaloriya),
						'one' => q({0} kilokaloriya),
						'other' => q({0} kilokaloriya),
					},
					'kilogram' => {
						'name' => q(kilogramm),
						'one' => q({0} kilogramm),
						'other' => q({0} kilogramm),
						'per' => q({0}/kilogramm),
					},
					'kilohertz' => {
						'name' => q(kilogers),
						'one' => q({0} kilogers),
						'other' => q({0} kilogers),
					},
					'kilojoule' => {
						'name' => q(kilojoul),
						'one' => q({0} kilojoul),
						'other' => q({0} kilojoul),
					},
					'kilometer' => {
						'name' => q(kilometr),
						'one' => q({0} kilometr),
						'other' => q({0} kilometr),
						'per' => q({0}/kilometr),
					},
					'kilometer-per-hour' => {
						'name' => q(km/soat),
						'one' => q({0} km/soat),
						'other' => q({0} km/soat),
					},
					'kilowatt' => {
						'name' => q(kilovatt),
						'one' => q({0} kilovatt),
						'other' => q({0} kilovatt),
					},
					'kilowatt-hour' => {
						'name' => q(kilovatt-soat),
						'one' => q({0} kilovatt-soat),
						'other' => q({0} kilovatt-soat),
					},
					'knot' => {
						'name' => q(uzel),
						'one' => q({0} uzel),
						'other' => q({0} uzel),
					},
					'light-year' => {
						'name' => q(yorug‘lik yili),
						'one' => q({0} yorug‘lik yili),
						'other' => q({0} yorug‘lik yili),
					},
					'liter' => {
						'name' => q(litr),
						'one' => q({0} litr),
						'other' => q({0} litr),
						'per' => q({0}/litr),
					},
					'liter-per-100kilometers' => {
						'name' => q(litr/100 km),
						'one' => q({0} litr/100 km),
						'other' => q({0} litr/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(litr/kilometr),
						'one' => q({0} litr/kilometr),
						'other' => q({0} litr/kilometr),
					},
					'lux' => {
						'name' => q(lyuks),
						'one' => q({0} lyuks),
						'other' => q({0} lyuks),
					},
					'megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					'megabyte' => {
						'name' => q(megabayt),
						'one' => q({0} megabayt),
						'other' => q({0} megabayt),
					},
					'megahertz' => {
						'name' => q(megagers),
						'one' => q({0} megagers),
						'other' => q({0} megagers),
					},
					'megaliter' => {
						'name' => q(megalitr),
						'one' => q({0} megalitr),
						'other' => q({0} megalitr),
					},
					'megawatt' => {
						'name' => q(megavatt),
						'one' => q({0} megavatt),
						'other' => q({0} megavatt),
					},
					'meter' => {
						'name' => q(metr),
						'one' => q({0} metr),
						'other' => q({0} metr),
						'per' => q({0}/metr),
					},
					'meter-per-second' => {
						'name' => q(metr/soniya),
						'one' => q({0} metr/soniya),
						'other' => q({0} metr/soniya),
					},
					'meter-per-second-squared' => {
						'name' => q(metr/soniya kvadrat),
						'one' => q({0} metr/soniya kvadrat),
						'other' => q({0} metr/soniya kvadrat),
					},
					'metric-ton' => {
						'name' => q(tonna),
						'one' => q({0} tonna),
						'other' => q({0} tonna),
					},
					'microgram' => {
						'name' => q(mikrogramm),
						'one' => q({0} mikrogramm),
						'other' => q({0} mikrogramm),
					},
					'micrometer' => {
						'name' => q(mikrometr),
						'one' => q({0} mikrometr),
						'other' => q({0} mikrometr),
					},
					'microsecond' => {
						'name' => q(mikrosoniya),
						'one' => q({0} mikrosoniya),
						'other' => q({0} mikrosoniya),
					},
					'mile' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					'mile-per-gallon' => {
						'name' => q(mil/gallon),
						'one' => q({0} mil/gallon),
						'other' => q({0} mil/gallon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mil/imp. gallon),
						'one' => q({0} mil/imp. gallon),
						'other' => q({0} mil/imp. gallon),
					},
					'mile-per-hour' => {
						'name' => q(mil/soat),
						'one' => q({0} mil/soat),
						'other' => q({0} mil/soat),
					},
					'mile-scandinavian' => {
						'name' => q(skandinav mili),
						'one' => q({0} skandinav mili),
						'other' => q({0} skandinav mili),
					},
					'milliampere' => {
						'name' => q(milliamper),
						'one' => q({0} milliamper),
						'other' => q({0} milliamper),
					},
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					'milligram' => {
						'name' => q(milligramm),
						'one' => q({0} milligramm),
						'other' => q({0} milligramm),
					},
					'milligram-per-deciliter' => {
						'name' => q(milligramm/detsilitr),
						'one' => q({0} milligramm/detsilitr),
						'other' => q({0} milligramm/detsilitr),
					},
					'milliliter' => {
						'name' => q(millilitr),
						'one' => q({0} millilitr),
						'other' => q({0} millilitr),
					},
					'millimeter' => {
						'name' => q(millimetr),
						'one' => q({0} millimetr),
						'other' => q({0} millimetr),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm simob ustuni),
						'one' => q({0} mm simob ustuni),
						'other' => q({0} mm simob ustuni),
					},
					'millimole-per-liter' => {
						'name' => q(millimol/litr),
						'one' => q({0} millimol/litr),
						'other' => q({0} millimol/litr),
					},
					'millisecond' => {
						'name' => q(millisoniya),
						'one' => q({0} millisoniya),
						'other' => q({0} millisoniya),
					},
					'milliwatt' => {
						'name' => q(millivatt),
						'one' => q({0} millivatt),
						'other' => q({0} millivatt),
					},
					'minute' => {
						'name' => q(daqiqa),
						'one' => q({0} daqiqa),
						'other' => q({0} daqiqa),
						'per' => q({0}/daqiqa),
					},
					'month' => {
						'name' => q(oy),
						'one' => q({0} oy),
						'other' => q({0} oy),
						'per' => q({0}/oy),
					},
					'nanometer' => {
						'name' => q(nanometr),
						'one' => q({0} nanometr),
						'other' => q({0} nanometr),
					},
					'nanosecond' => {
						'name' => q(nanosoniya),
						'one' => q({0} nanosoniya),
						'other' => q({0} nanosoniya),
					},
					'nautical-mile' => {
						'name' => q(dengiz mili),
						'one' => q({0} dengiz mili),
						'other' => q({0} dengiz mili),
					},
					'ohm' => {
						'name' => q(om),
						'one' => q({0} om),
						'other' => q({0} om),
					},
					'ounce' => {
						'name' => q(unsiya),
						'one' => q({0} unsiya),
						'other' => q({0} unsiya),
						'per' => q({0}/unsiya),
					},
					'ounce-troy' => {
						'name' => q(troya unsiyasi),
						'one' => q({0} troya unsiyasi),
						'other' => q({0} troya unsiyasi),
					},
					'parsec' => {
						'name' => q(parsek),
						'one' => q({0} parsek),
						'other' => q({0} parsek),
					},
					'part-per-million' => {
						'name' => q(millionning ulushi),
						'one' => q(milliondan {0}),
						'other' => q(milliondan {0}),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pikometr),
						'one' => q({0} pikometr),
						'other' => q({0} pikometr),
					},
					'pint' => {
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					'pint-metric' => {
						'name' => q(metrik pint),
						'one' => q({0} metrik pint),
						'other' => q({0} metrik pint),
					},
					'point' => {
						'name' => q(nuqta),
						'one' => q({0} nuqta),
						'other' => q({0} nuqta),
					},
					'pound' => {
						'name' => q(funt),
						'one' => q({0} funt),
						'other' => q({0} funt),
						'per' => q({0}/funt),
					},
					'pound-per-square-inch' => {
						'name' => q(funt/kvadrat duym),
						'one' => q({0} funt/kvadrat duym),
						'other' => q({0} funt/kvadrat duym),
					},
					'quart' => {
						'name' => q(kvart),
						'one' => q({0} kvart),
						'other' => q({0} kvart),
					},
					'radian' => {
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radian),
					},
					'revolution' => {
						'name' => q(aylanish),
						'one' => q({0} marta aylanish),
						'other' => q({0} marta aylanish),
					},
					'second' => {
						'name' => q(soniya),
						'one' => q({0} soniya),
						'other' => q({0} soniya),
						'per' => q({0}/soniya),
					},
					'square-centimeter' => {
						'name' => q(kvadrat santimetr),
						'one' => q({0} kvadrat santimetr),
						'other' => q({0} kvadrat santimetr),
						'per' => q({0}/kvadrat santimetr),
					},
					'square-foot' => {
						'name' => q(kvadrat fut),
						'one' => q({0} kvadrat fut),
						'other' => q({0} kvadrat fut),
					},
					'square-inch' => {
						'name' => q(kvadrat duym),
						'one' => q({0} kvadrat dyum),
						'other' => q({0} kvadrat dyum),
						'per' => q({0}/kvadrat duym),
					},
					'square-kilometer' => {
						'name' => q(kvadrat kilometr),
						'one' => q({0} kvadrat kilometr),
						'other' => q({0} kvadrat kilometr),
						'per' => q({0} kvadrat kilometr),
					},
					'square-meter' => {
						'name' => q(kvadrat metr),
						'one' => q({0} kvadrat metr),
						'other' => q({0} kvadrat metr),
						'per' => q({0}/kvadrat metr),
					},
					'square-mile' => {
						'name' => q(kvadrat mil),
						'one' => q({0} kvadrat mil),
						'other' => q({0} kvadrat mil),
						'per' => q({0}/kvadrat mil),
					},
					'square-yard' => {
						'name' => q(kvadrat yard),
						'one' => q({0} kvadrat yard),
						'other' => q({0} kvadrat yard),
					},
					'tablespoon' => {
						'name' => q(osh qoshiq),
						'one' => q({0} osh qoshiq),
						'other' => q({0} osh qoshiq),
					},
					'teaspoon' => {
						'name' => q(choy qoshiq),
						'one' => q({0} choy qoshiq),
						'other' => q({0} choy qoshiq),
					},
					'terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					'terabyte' => {
						'name' => q(terabayt),
						'one' => q({0} terabayt),
						'other' => q({0} terabayt),
					},
					'ton' => {
						'name' => q(amerika tonnasi),
						'one' => q({0} amerika tonnasi),
						'other' => q({0} amerika tonnasi),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					'watt' => {
						'name' => q(vatt),
						'one' => q({0} vatt),
						'other' => q({0} vatt),
					},
					'week' => {
						'name' => q(hafta),
						'one' => q({0} hafta),
						'other' => q({0} hafta),
						'per' => q({0}/hafta),
					},
					'yard' => {
						'name' => q(yard),
						'one' => q({0} yard),
						'other' => q({0} yard),
					},
					'year' => {
						'name' => q(yil),
						'one' => q({0} yil),
						'other' => q({0} yil),
						'per' => q({0}/yil),
					},
				},
				'narrow' => {
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
					},
					'coordinate' => {
						'east' => q({0} shq. u.),
						'north' => q({0} shm. k.),
						'south' => q({0} jan. k.),
						'west' => q({0} g‘rb. u.),
					},
					'cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'day' => {
						'name' => q(kun),
						'one' => q({0} kun),
						'other' => q({0} kun),
					},
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'foot' => {
						'one' => q({0} fut),
						'other' => q({0} fut),
					},
					'g-force' => {
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gram' => {
						'name' => q(gramm),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectopascal' => {
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'horsepower' => {
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(soat),
						'one' => q({0} soat),
						'other' => q({0} soat),
					},
					'inch' => {
						'one' => q({0} dyuym),
						'other' => q({0} dyuym),
					},
					'inch-hg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/soat),
						'one' => q({0} km/soat),
						'other' => q({0} km/soat),
					},
					'kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'light-year' => {
						'one' => q({0} yo.y.),
						'other' => q({0} yo.y.),
					},
					'liter' => {
						'name' => q(litr),
						'one' => q({0}L),
						'other' => q({0}L),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100 km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					'meter' => {
						'name' => q(metr),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'meter-per-second' => {
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'mile' => {
						'one' => q({0} milya),
						'other' => q({0} milya),
					},
					'mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'millibar' => {
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'name' => q(mson),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(daq.),
						'one' => q({0} daq.),
						'other' => q({0} daq.),
					},
					'month' => {
						'name' => q(oy),
						'one' => q({0} oy),
						'other' => q({0} oy),
					},
					'ounce' => {
						'one' => q({0} untsiya),
						'other' => q({0} untsiya),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pound' => {
						'one' => q({0} funt),
						'other' => q({0} funt),
					},
					'second' => {
						'name' => q(son.),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					'square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					'watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(hafta),
						'one' => q({0} hafta),
						'other' => q({0} hafta),
					},
					'yard' => {
						'one' => q({0} yard),
						'other' => q({0} yard),
					},
					'year' => {
						'name' => q(yil),
						'one' => q({0} yil),
						'other' => q({0} yil),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(akr),
						'one' => q({0} akr),
						'other' => q({0} akr),
					},
					'acre-foot' => {
						'name' => q(akrofut),
						'one' => q({0} akrofut),
						'other' => q({0} akrofut),
					},
					'ampere' => {
						'name' => q(amper),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(yoy daqiqasi),
						'one' => q({0} yoy daq.),
						'other' => q({0} yoy daq.),
					},
					'arc-second' => {
						'name' => q(yoy soniyasi),
						'one' => q({0} yoy son.),
						'other' => q({0} yoy son.),
					},
					'astronomical-unit' => {
						'name' => q(a.b.),
						'one' => q({0} a.b.),
						'other' => q({0} a.b.),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(bayt),
						'one' => q({0} bayt),
						'other' => q({0} bayt),
					},
					'calorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					'carat' => {
						'name' => q(karat),
						'one' => q({0} kar),
						'other' => q({0} kar),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(sL),
						'one' => q({0} sL),
						'other' => q({0} sL),
					},
					'centimeter' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
						'per' => q({0}/sm),
					},
					'century' => {
						'name' => q(asr),
						'one' => q({0} asr),
						'other' => q({0} asr),
					},
					'coordinate' => {
						'east' => q({0} shq. u.),
						'north' => q({0} shm. k.),
						'south' => q({0} jan. k.),
						'west' => q({0} g‘rb. u.),
					},
					'cubic-centimeter' => {
						'name' => q(sm³),
						'one' => q({0} sm³),
						'other' => q({0} sm³),
						'per' => q({0}/sm³),
					},
					'cubic-foot' => {
						'name' => q(kub fut),
						'one' => q({0} kub fut),
						'other' => q({0} kub fut),
					},
					'cubic-inch' => {
						'name' => q(kub duym),
						'one' => q({0} kub duym),
						'other' => q({0} kub duym),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(kub mil),
						'one' => q({0} kub mil),
						'other' => q({0} kub mil),
					},
					'cubic-yard' => {
						'name' => q(kub yard),
						'one' => q({0} yard³),
						'other' => q({0} yard³),
					},
					'cup' => {
						'name' => q(piyola),
						'one' => q({0} piyola),
						'other' => q({0} piyola),
					},
					'cup-metric' => {
						'name' => q(m. piyola),
						'one' => q({0} m. piyola),
						'other' => q({0} m. piyola),
					},
					'day' => {
						'name' => q(kun),
						'one' => q({0} kun),
						'other' => q({0} kun),
						'per' => q({0}/kun),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(gradus),
						'one' => q({0} grad),
						'other' => q({0} grad),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'name' => q(suyuq unsiya),
						'one' => q({0} suyuq unsiya),
						'other' => q({0} suyuq unsiya),
					},
					'foodcalorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					'foot' => {
						'name' => q(fut),
						'one' => q({0} fut),
						'other' => q({0} fut),
						'per' => q({0} fut),
					},
					'g-force' => {
						'name' => q(grav. kuchi),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(imp. gal.),
						'one' => q({0} imp. gal.),
						'other' => q({0} imp. gal.),
						'per' => q({0} imp. gal.),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gbit),
						'other' => q({0} Gbit),
					},
					'gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(GGs),
						'one' => q({0} GGs),
						'other' => q({0} GGs),
					},
					'gigawatt' => {
						'name' => q(GVt),
						'one' => q({0} GVt),
						'other' => q({0} GVt),
					},
					'gram' => {
						'name' => q(gramm),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(gektar),
						'one' => q({0} ga),
						'other' => q({0} ga),
					},
					'hectoliter' => {
						'name' => q(gL),
						'one' => q({0} gL),
						'other' => q({0} gL),
					},
					'hectopascal' => {
						'name' => q(gPa),
						'one' => q({0} gPa),
						'other' => q({0} gPa),
					},
					'hertz' => {
						'name' => q(Gs),
						'one' => q({0} Gs),
						'other' => q({0} Gs),
					},
					'horsepower' => {
						'name' => q(o.k.),
						'one' => q({0} o.k.),
						'other' => q({0} o.k.),
					},
					'hour' => {
						'name' => q(soat),
						'one' => q({0} soat),
						'other' => q({0} soat),
						'per' => q({0}/soat),
					},
					'inch' => {
						'name' => q(duym),
						'one' => q({0} dy),
						'other' => q({0} dy),
						'per' => q({0}/dy),
					},
					'inch-hg' => {
						'name' => q(dy sim.ust),
						'one' => q({0} dy sim.ust),
						'other' => q({0} dy sim.ust),
					},
					'joule' => {
						'name' => q(joul),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(karat),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kbit),
						'other' => q({0} kbit),
					},
					'kilobyte' => {
						'name' => q(KB),
						'one' => q({0} KB),
						'other' => q({0} KB),
					},
					'kilocalorie' => {
						'name' => q(kkal),
						'one' => q({0} kkal),
						'other' => q({0} kkal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kGs),
						'one' => q({0} kGs),
						'other' => q({0} kGs),
					},
					'kilojoule' => {
						'name' => q(kilojoul),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/soat),
						'one' => q({0} km/soat),
						'other' => q({0} km/soat),
					},
					'kilowatt' => {
						'name' => q(kVt),
						'one' => q({0} kVt),
						'other' => q({0} kVt),
					},
					'kilowatt-hour' => {
						'name' => q(kVt-soat),
						'one' => q({0} kVt-soat),
						'other' => q({0} kVt-soat),
					},
					'knot' => {
						'name' => q(uzel),
						'one' => q({0} uzel),
						'other' => q({0} uzel),
					},
					'light-year' => {
						'name' => q(yorug‘lik yili),
						'one' => q({0} y.y.),
						'other' => q({0} y.y.),
					},
					'liter' => {
						'name' => q(litr),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(litr/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					'lux' => {
						'name' => q(lk),
						'one' => q({0} lk),
						'other' => q({0} lk),
					},
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mbit),
						'other' => q({0} Mbit),
					},
					'megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MGs),
						'one' => q({0} MGs),
						'other' => q({0} MGs),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					'megawatt' => {
						'name' => q(MVt),
						'one' => q({0} MVt),
						'other' => q({0} MVt),
					},
					'meter' => {
						'name' => q(metr),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(metr/soniya²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µmetr),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(mks),
						'one' => q({0} mks),
						'other' => q({0} mks),
					},
					'mile' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					'mile-per-gallon' => {
						'name' => q(mil/gal),
						'one' => q({0} mil/gal),
						'other' => q({0} mil/gal),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mil/imp. gallon),
						'one' => q({0} mil/imp.gal),
						'other' => q({0} mil/imp.gal),
					},
					'mile-per-hour' => {
						'name' => q(mil/soat),
						'one' => q({0} mil/soat),
						'other' => q({0} mil/soat),
					},
					'mile-scandinavian' => {
						'name' => q(sk. mili),
						'one' => q({0} sk. mili),
						'other' => q({0} sk. mili),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm sim.ust),
						'one' => q({0} mm sim.ust),
						'other' => q({0} mm sim.ust),
					},
					'millimole-per-liter' => {
						'name' => q(millimol/litr),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'name' => q(millisoniya),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mVt),
						'one' => q({0} mVt),
						'other' => q({0} mVt),
					},
					'minute' => {
						'name' => q(daq.),
						'one' => q({0} daq.),
						'other' => q({0} daq.),
						'per' => q({0}/daq.),
					},
					'month' => {
						'name' => q(oy),
						'one' => q({0} oy),
						'other' => q({0} oy),
						'per' => q({0}/oy),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(nanosoniya),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(den. mili),
						'one' => q({0} den. mili),
						'other' => q({0} den. mili),
					},
					'ohm' => {
						'name' => q(om),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(unsiya),
						'one' => q({0} unsiya),
						'other' => q({0} unsiya),
						'per' => q({0}/unsiya),
					},
					'ounce-troy' => {
						'name' => q(troya unsiyasi),
						'one' => q({0} troya unsiyasi),
						'other' => q({0} troya unsiyasi),
					},
					'parsec' => {
						'name' => q(pk),
						'one' => q({0} pk),
						'other' => q({0} pk),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(nuqta),
						'one' => q({0} nuqta),
						'other' => q({0} nuqta),
					},
					'pound' => {
						'name' => q(funt),
						'one' => q({0} funt),
						'other' => q({0} funt),
						'per' => q({0}/funt),
					},
					'pound-per-square-inch' => {
						'name' => q(funt/kv.dy),
						'one' => q({0} funt/kv.dy),
						'other' => q({0} funt/kv.dy),
					},
					'quart' => {
						'name' => q(kvart),
						'one' => q({0} kvart),
						'other' => q({0} kvart),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(aylanish),
						'one' => q({0} marta ayl.),
						'other' => q({0} marta ayl.),
					},
					'second' => {
						'name' => q(son.),
						'one' => q({0} son.),
						'other' => q({0} son.),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(sm²),
						'one' => q({0} sm²),
						'other' => q({0} sm²),
						'per' => q({0}/sm²),
					},
					'square-foot' => {
						'name' => q(kv. fut),
						'one' => q({0} kv. fut),
						'other' => q({0} kv. fut),
					},
					'square-inch' => {
						'name' => q(kvadrat duym),
						'one' => q({0} kv. duym),
						'other' => q({0} kv. duym),
						'per' => q({0} kv. duym),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(kv. mil),
						'one' => q({0} kv. mil),
						'other' => q({0} kv. mil),
						'per' => q({0}/mil²),
					},
					'square-yard' => {
						'name' => q(yard²),
						'one' => q({0} yard²),
						'other' => q({0} yard²),
					},
					'tablespoon' => {
						'name' => q(osh qoshiq),
						'one' => q({0} osh qoshiq),
						'other' => q({0} osh qoshiq),
					},
					'teaspoon' => {
						'name' => q(choy qoshiq),
						'one' => q({0} choy qoshiq),
						'other' => q({0} choy qoshiq),
					},
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tbit),
						'other' => q({0} Tbit),
					},
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(amer. t),
						'one' => q({0} amer. t),
						'other' => q({0} amer. t),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(Vt),
						'one' => q({0} Vt),
						'other' => q({0} Vt),
					},
					'week' => {
						'name' => q(hafta),
						'one' => q({0} hafta),
						'other' => q({0} hafta),
						'per' => q({0}/hafta),
					},
					'yard' => {
						'name' => q(yard),
						'one' => q({0} yard),
						'other' => q({0} yard),
					},
					'year' => {
						'name' => q(yil),
						'one' => q({0} yil),
						'other' => q({0} yil),
						'per' => q({0}/yil),
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
				start => q({0} {1}),
				middle => q({0} {1}),
				end => q({0} {1}),
				2 => q({0} {1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 1,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arabext' => {
			'decimal' => q(٫),
			'exponential' => q(×۱۰^),
			'group' => q(٬),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(son emas),
			'perMille' => q(؉),
			'percentSign' => q(٪),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(٫),
		},
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q( ),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(son emas),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(:),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'default' => {
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
				'standard' => {
					'default' => '#,##0.###',
				},
			},
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
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
				},
			},
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'default' => '#E0',
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
		'arabext' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '#,##0.00 ¤',
					},
				},
			},
		},
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
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
			symbol => 'AED',
			display_name => {
				'currency' => q(Birlashgan Arab Amirliklari dirhami),
				'one' => q(BAA dirhami),
				'other' => q(BAA dirhami),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afg‘oniston afg‘oniysi),
				'one' => q(Afg‘oniston afg‘oniysi),
				'other' => q(Afg‘oniston afg‘oniysi),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Albaniya leki),
				'one' => q(Albaniya leki),
				'other' => q(Albaniya leki),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Armaniston drami),
				'one' => q(Armaniston drami),
				'other' => q(Armaniston drami),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Niderlandiya antil guldeni),
				'one' => q(Niderlandiya antil guldeni),
				'other' => q(Niderlandiya antil guldeni),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Angola kvanzasi),
				'one' => q(Angola kvanzasi),
				'other' => q(Angola kvanzasi),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Argentina pesosi),
				'one' => q(Argentina pesosi),
				'other' => q(Argentina pesosi),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(Avstraliya dollari),
				'one' => q(Avstraliya dollari),
				'other' => q(Avstraliya dollari),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Aruba florini),
				'one' => q(Aruba florini),
				'other' => q(Aruba florini),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Ozarbayjon manati),
				'one' => q(Ozarbayjon manati),
				'other' => q(Ozarbayjon manati),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Bosniya va Gertsegovina ayirboshlash markasi),
				'one' => q(Bosniya va Gertsegovina ayirboshlash markasi),
				'other' => q(Bosniya va Gertsegovina ayirboshlash markasi),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Barbados dollari),
				'one' => q(Barbados dollari),
				'other' => q(Barbados dollari),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Bangladesh takasi),
				'one' => q(Bangladesh takasi),
				'other' => q(Bangladesh takasi),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Bolgariya levi),
				'one' => q(Bolgariya levi),
				'other' => q(Bolgariya levi),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Bahrayn dinori),
				'one' => q(Bahrayn dinori),
				'other' => q(Bahrayn dinori),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Burundi franki),
				'one' => q(Burundi franki),
				'other' => q(Burundi franki),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Bermuda dollari),
				'one' => q(Bermuda dollari),
				'other' => q(Bermuda dollari),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Bruney dollari),
				'one' => q(Bruney dollari),
				'other' => q(Bruney dollari),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Boliviya bolivianosi),
				'one' => q(Boliviya bolivianosi),
				'other' => q(Boliviya bolivianosi),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Braziliya reali),
				'one' => q(Braziliya reali),
				'other' => q(Braziliya reali),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Bagama dollari),
				'one' => q(Bagama dollari),
				'other' => q(Bagama dollari),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Butan ngultrumi),
				'one' => q(Butan ngultrumi),
				'other' => q(Butan ngultrumi),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Botsvana pulasi),
				'one' => q(Botsvana pulasi),
				'other' => q(Botsvana pulasi),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Belarus rubli),
				'one' => q(Belarus rubli),
				'other' => q(Belarus rubli),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Belarus rubli \(2000–2016\)),
				'one' => q(Belarus rubli \(2000–2016\)),
				'other' => q(Belarus rubli \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Beliz dollari),
				'one' => q(Beliz dollari),
				'other' => q(Beliz dollari),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Kanada dollari),
				'one' => q(Kanada dollari),
				'other' => q(Kanada dollari),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Kongo franki),
				'one' => q(Kongo franki),
				'other' => q(Kongo franki),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Shveytsariya franki),
				'one' => q(Shveytsariya franki),
				'other' => q(Shveytsariya franki),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Chili pesosi),
				'one' => q(Chili pesosi),
				'other' => q(Chili pesosi),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(CNH),
				'one' => q(CNH),
				'other' => q(CNH),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Xitoy yuani),
				'one' => q(Xitoy yuani),
				'other' => q(Xitoy yuani),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Kolumbiya pesosi),
				'one' => q(Kolumbiya pesosi),
				'other' => q(Kolumbiya pesosi),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Kosta-Rika koloni),
				'one' => q(Kosta-Rika koloni),
				'other' => q(Kosta-Rika koloni),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Kuba ayirboshlash pesosi),
				'one' => q(Kuba ayirboshlash pesosi),
				'other' => q(Kuba ayirboshlash pesosi),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Kuba pesosi),
				'one' => q(Kuba pesosi),
				'other' => q(Kuba pesosi),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Kabo-Verde eskudosi),
				'one' => q(Kabo-Verde eskudosi),
				'other' => q(Kabo-Verde eskudosi),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Chexiya kronasi),
				'one' => q(Chexiya kronasi),
				'other' => q(Chexiya kronasi),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Jibuti franki),
				'one' => q(Jibuti franki),
				'other' => q(Jibuti franki),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Daniya kronasi),
				'one' => q(Daniya kronasi),
				'other' => q(Daniya kronasi),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Dominikana pesosi),
				'one' => q(Dominikana pesosi),
				'other' => q(Dominikana pesosi),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Jazoir dinori),
				'one' => q(Jazoir dinori),
				'other' => q(Jazoir dinori),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Misr funti),
				'one' => q(Misr funti),
				'other' => q(Misr funti),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Eritreya nakfasi),
				'one' => q(Eritreya nakfasi),
				'other' => q(Eritreya nakfasi),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Efiopiya biri),
				'one' => q(Efiopiya biri),
				'other' => q(Efiopiya biri),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Yevro),
				'one' => q(yevro),
				'other' => q(yevro),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Fiji dollari),
				'one' => q(Fiji dollari),
				'other' => q(Fiji dollari),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Folklend orollari funti),
				'one' => q(Folklend orollari funti),
				'other' => q(Folklend orollari funti),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Angliya funt sterlingi),
				'one' => q(Angliya funt sterlingi),
				'other' => q(Angliya funt sterlingi),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Gruziya larisi),
				'one' => q(Gruziya larisi),
				'other' => q(Gruziya larisi),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Gana sedisi),
				'one' => q(Gana sedisi),
				'other' => q(Gana sedisi),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Gibraltar funti),
				'one' => q(Gibraltar funti),
				'other' => q(Gibraltar funti),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Gambiya dalasisi),
				'one' => q(Gambiya dalasisi),
				'other' => q(Gambiya dalasisi),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Gvineya franki),
				'one' => q(Gvineya franki),
				'other' => q(Gvineya franki),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Gvatemala ketsali),
				'one' => q(Gvatemala ketsali),
				'other' => q(Gvatemala ketsali),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Gayana dollari),
				'one' => q(Gayana dollari),
				'other' => q(Gayana dollari),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Gonkong dollari),
				'one' => q(Gonkong dollari),
				'other' => q(Gonkong dollari),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Gonduras lempirasi),
				'one' => q(Gonduras lempirasi),
				'other' => q(Gonduras lempirasi),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Xorvatiya kunasi),
				'one' => q(Xorvatiya kunasi),
				'other' => q(Xorvatiya kunasi),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Gaiti gurdi),
				'one' => q(Gaiti gurdi),
				'other' => q(Gaiti gurdi),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Vengriya forinti),
				'one' => q(Vengriya forinti),
				'other' => q(Vengriya forinti),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Indoneziya rupiyasi),
				'one' => q(Indoneziya rupiyasi),
				'other' => q(Indoneziya rupiyasi),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Isroil yangi shekeli),
				'one' => q(Isroil yangi shekeli),
				'other' => q(Isroil yangi shekeli),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Hindiston rupiyasi),
				'one' => q(Hindiston rupiyasi),
				'other' => q(Hindiston rupiyasi),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Iroq dinori),
				'one' => q(Iroq dinori),
				'other' => q(Iroq dinori),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Eron riyoli),
				'one' => q(Eron riyoli),
				'other' => q(Eron riyoli),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Islandiya kronasi),
				'one' => q(Islandiya kronasi),
				'other' => q(Islandiya kronasi),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Yamayka dollari),
				'one' => q(Yamayka dollari),
				'other' => q(Yamayka dollari),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Iordaniya dinori),
				'one' => q(Yordaniya dinori),
				'other' => q(Iordaniya dinori),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Yaponiya iyenasi),
				'one' => q(Yaponiya iyenasi),
				'other' => q(Yaponiya iyenasi),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Keniya shillingi),
				'one' => q(Keniya shillingi),
				'other' => q(Keniya shillingi),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Qirg‘iziston somi),
				'one' => q(Qirg‘iziston somi),
				'other' => q(Qirg‘iziston somi),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Kambodja rieli),
				'one' => q(Kambodja rieli),
				'other' => q(Kambodja rieli),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Komor orollari franki),
				'one' => q(Komor orollari franki),
				'other' => q(Komor orollari franki),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Shimoliy Koreya voni),
				'one' => q(Shimoliy Koreya voni),
				'other' => q(Shimoliy Koreya voni),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Janubiy Koreya voni),
				'one' => q(Janubiy Koreya voni),
				'other' => q(Janubiy Koreya voni),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Kuvayt dinori),
				'one' => q(Kuvayt dinori),
				'other' => q(Kuvayt dinori),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Kayman orollari dollari),
				'one' => q(Kayman orollari dollari),
				'other' => q(Kayman orollari dollari),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Qozog‘iston tengesi),
				'one' => q(Qozog‘iston tengesi),
				'other' => q(Qozog‘iston tengesi),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Laos kipi),
				'one' => q(Laos kipi),
				'other' => q(Laos kipi),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Livan funti),
				'one' => q(Livan funti),
				'other' => q(Livan funti),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Shri-Lanka rupiyasi),
				'one' => q(Shri-Lanka rupiyasi),
				'other' => q(Shri-Lanka rupiyasi),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Liberiya dollari),
				'one' => q(Liberiya dollari),
				'other' => q(Liberiya dollari),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Litva liti),
				'one' => q(Litva liti),
				'other' => q(Litva liti),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Latviya lati),
				'one' => q(Latviya lati),
				'other' => q(Latviya lati),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Liviya dinori),
				'one' => q(Liviya dinori),
				'other' => q(Liviya dinori),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Marokash dirhami),
				'one' => q(Marokash dirhami),
				'other' => q(Marokash dirhami),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Moldova leyi),
				'one' => q(Moldova leyi),
				'other' => q(Moldova leyi),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Malagasi ariarisi),
				'one' => q(Malagasi ariarisi),
				'other' => q(Malagasi ariarisi),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Makedoniya dinori),
				'one' => q(Makedoniya dinori),
				'other' => q(Makedoniya dinori),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Myanma kyati),
				'one' => q(Myanma kyati),
				'other' => q(Myanma kyati),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Mongoliya tugriki),
				'one' => q(Mongoliya tugriki),
				'other' => q(Mongoliya tugriki),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Makao patakasi),
				'one' => q(Makao patakasi),
				'other' => q(Makao patakasi),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Mavritaniya uqiyasi),
				'one' => q(Mavritaniya uqiyasi),
				'other' => q(Mavritaniya uqiyasi),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Mavritaniya rupiyasi),
				'one' => q(Mavritaniya rupiyasi),
				'other' => q(Mavritaniya rupiyasi),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Maldiv rupiyasi),
				'one' => q(Maldiv rupiyasi),
				'other' => q(Maldiv rupiyasi),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Malavi kvachasi),
				'one' => q(Malavi kvachasi),
				'other' => q(Malavi kvachasi),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Meksika pesosi),
				'one' => q(Meksika pesosi),
				'other' => q(Meksika pesosi),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Malayziya ringgiti),
				'one' => q(Malayziya ringgiti),
				'other' => q(Malayziya ringgiti),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Mozambik metikali),
				'one' => q(Mozambik metikali),
				'other' => q(Mozambik metikali),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Namibiya dollari),
				'one' => q(Namibiya dollari),
				'other' => q(Namibiya dollari),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Nigeriya nayrasi),
				'one' => q(Nigeriya nayrasi),
				'other' => q(Nigeriya nayrasi),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Nikaragua kordobasi),
				'one' => q(Nikaragua kordobasi),
				'other' => q(Nikaragua kordobasi),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Norvegiya kronasi),
				'one' => q(Norvegiya kronasi),
				'other' => q(Norvegiya kronasi),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Nepal rupiyasi),
				'one' => q(Nepal rupiyasi),
				'other' => q(Nepal rupiyasi),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Yangi Zelandiya dollari),
				'one' => q(Yangi Zelandiya dollari),
				'other' => q(Yangi Zelandiya dollari),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Ummon riyoli),
				'one' => q(Ummon riyoli),
				'other' => q(Ummon riyoli),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Panama balboasi),
				'one' => q(Panama balboasi),
				'other' => q(Panama balboasi),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Peru soli),
				'one' => q(Peru soli),
				'other' => q(Peru soli),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Papua – Yangi Gvineya kinasi),
				'one' => q(Papua – Yangi Gvineya kinasi),
				'other' => q(Papua – Yangi Gvineya kinasi),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filippin pesosi),
				'one' => q(Filippin pesosi),
				'other' => q(Filippin pesosi),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Pokiston rupiyasi),
				'one' => q(Pokiston rupiyasi),
				'other' => q(Pokiston rupiyasi),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Polsha zlotiyi),
				'one' => q(Polsha zlotiyi),
				'other' => q(Polsha zlotiyi),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Paragvay guaranisi),
				'one' => q(Paragvay guaranisi),
				'other' => q(Paragvay guaranisi),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Qatar riyoli),
				'one' => q(Qatar riyoli),
				'other' => q(Qatar riyoli),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Ruminiya leyi),
				'one' => q(Ruminiya leyi),
				'other' => q(Ruminiya leyi),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Serbiya dinori),
				'one' => q(Serbiya dinori),
				'other' => q(Serbiya dinori),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Rossiya rubli),
				'one' => q(Rossiya rubli),
				'other' => q(Rossiya rubli),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Ruanda franki),
				'one' => q(Ruanda franki),
				'other' => q(Ruanda franki),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Saudiya Arabistoni riyoli),
				'one' => q(Saudiya Arabistoni riyoli),
				'other' => q(Saudiya Arabistoni riyoli),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Solomon orollari dollari),
				'one' => q(Solomon orollari dollari),
				'other' => q(Solomon orollari dollari),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Seyshel rupiyasi),
				'one' => q(Seyshel rupiyasi),
				'other' => q(Seyshel rupiyasi),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Sudan funti),
				'one' => q(Sudan funti),
				'other' => q(Sudan funti),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Shvetsiya kronasi),
				'one' => q(Shvetsiya kronasi),
				'other' => q(Shvetsiya kronasi),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Singapur dollari),
				'one' => q(Singapur dollari),
				'other' => q(Singapur dollari),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Muqaddas Yelena oroli funti),
				'one' => q(Muqaddas Yelena oroli funti),
				'other' => q(Muqaddas Yelena oroli funti),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Syerra-Leone leonesi),
				'one' => q(Syerra-Leone leonesi),
				'other' => q(Syerra-Leone leonesi),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Somali shillingi),
				'one' => q(Somali shillingi),
				'other' => q(Somali shillingi),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Surinam dollari),
				'one' => q(Surinam dollari),
				'other' => q(Surinam dollari),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Janubiy Sudan funti),
				'one' => q(Janubiy Sudan funti),
				'other' => q(Janubiy Sudan funti),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(San-Tome va Prinsipi dobrasi),
				'one' => q(San-Tome va Prinsipi dobrasi),
				'other' => q(San-Tome va Prinsipi dobrasi),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Suriya funti),
				'one' => q(Suriya funti),
				'other' => q(Suriya funti),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Svazilend lilangenisi),
				'one' => q(Svazilend lilangenisi),
				'other' => q(Svazilend lilangenisi),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(Tailand bati),
				'one' => q(Tailand bati),
				'other' => q(Tailand bati),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Tojikiston somoniysi),
				'one' => q(Tojikiston somoniysi),
				'other' => q(Tojikiston somoniysi),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Turkmaniston manati),
				'one' => q(Turkmaniston manati),
				'other' => q(Turkmaniston manati),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Tunis dinori),
				'one' => q(Tunis dinori),
				'other' => q(Tunis dinori),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Tonga paangasi),
				'one' => q(Tonga paangasi),
				'other' => q(Tonga paangasi),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Turk lirasi),
				'one' => q(Turk lirasi),
				'other' => q(Turk lirasi),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Trinidad va Tobago dollari),
				'one' => q(Trinidad va Tobago dollari),
				'other' => q(Trinidad va Tobago dollari),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Yangi Tayvan dollari),
				'one' => q(Yangi Tayvan dollari),
				'other' => q(Yangi Tayvan dollari),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Tanzaniya shillingi),
				'one' => q(Tanzaniya shillingi),
				'other' => q(Tanzaniya shillingi),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Ukraina grivnasi),
				'one' => q(Ukraina grivnasi),
				'other' => q(Ukraina grivnasi),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Uganda shillingi),
				'one' => q(Uganda shillingi),
				'other' => q(Uganda shillingi),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(AQSH dollari),
				'one' => q(AQSH dollari),
				'other' => q(AQSH dollari),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Urugvay pesosi),
				'one' => q(Urugvay pesosi),
				'other' => q(Urugvay pesosi),
			},
		},
		'UZS' => {
			symbol => 'soʻm',
			display_name => {
				'currency' => q(O‘zbekiston so‘mi),
				'one' => q(O‘zbekiston so‘mi),
				'other' => q(O‘zbekiston so‘mi),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Venesuela bolivari),
				'one' => q(Venesuela bolivari),
				'other' => q(Venesuela bolivari),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Vyetnam dongi),
				'one' => q(Vyetnam dongi),
				'other' => q(Vyetnam dongi),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vanuatu vatusi),
				'one' => q(Vanuatu vatusi),
				'other' => q(Vanuatu vatusi),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Samoa talasi),
				'one' => q(Samoa talasi),
				'other' => q(Samoa talasi),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Markaziy Afrika CFA franki),
				'one' => q(Markaziy Afrika CFA franki),
				'other' => q(Markaziy Afrika CFA franki),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Sharqiy Karib dollari),
				'one' => q(Sharqiy Karib dollari),
				'other' => q(Sharqiy Karib dollari),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(G‘arbiy Afrika CFA franki),
				'one' => q(G‘arbiy Afrika CFA franki),
				'other' => q(G‘arbiy Afrika CFA franki),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(Fransuz Polineziyasi franki),
				'one' => q(Fransuz Polineziyasi franki),
				'other' => q(Fransuz Polineziyasi franki),
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
			symbol => 'YER',
			display_name => {
				'currency' => q(Yaman riyoli),
				'one' => q(Yaman riyoli),
				'other' => q(Yaman riyoli),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Janubiy Afrika rendi),
				'one' => q(Janubiy Afrika rendi),
				'other' => q(Janubiy Afrika rendi),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Zambiya kvachasi),
				'one' => q(Zambiya kvachasi),
				'other' => q(Zambiya kvachasi),
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
					wide => {
						nonleap => [
							'Muharram',
							'Safar',
							'Robiʼ ul-avval',
							'Robiʼ ul-oxir',
							'Jumad ul-avval',
							'Jumad ul-oxir',
							'Rajab',
							'Shaʼbon',
							'Ramazon',
							'Shavvol',
							'Zul-qaʼda',
							'Zul-hijja'
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
					narrow => {
						mon => 'D',
						tue => 'S',
						wed => 'C',
						thu => 'P',
						fri => 'J',
						sat => 'S',
						sun => 'Y'
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
					abbreviated => {
						mon => 'Dush',
						tue => 'Sesh',
						wed => 'Chor',
						thu => 'Pay',
						fri => 'Jum',
						sat => 'Shan',
						sun => 'Yak'
					},
					narrow => {
						mon => 'D',
						tue => 'S',
						wed => 'C',
						thu => 'P',
						fri => 'J',
						sat => 'S',
						sun => 'Y'
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1-chorak',
						1 => '2-chorak',
						2 => '3-chorak',
						3 => '4-chorak'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1-ch',
						1 => '2-ch',
						2 => '3-ch',
						3 => '4-ch'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
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
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 600
						&& $time < 1100;
					return 'afternoon1' if $time >= 1100
						&& $time < 1800;
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
				'wide' => {
					'afternoon1' => q{kunduzi},
					'morning1' => q{ertalab},
					'night1' => q{kechasi},
					'noon' => q{tush payti},
					'midnight' => q{yarim tun},
					'pm' => q{TK},
					'am' => q{TO},
					'evening1' => q{kechqurun},
				},
				'narrow' => {
					'pm' => q{TK},
					'midnight' => q{yarim tun},
					'noon' => q{tush payti},
					'night1' => q{kechasi},
					'afternoon1' => q{kunduzi},
					'morning1' => q{ertalab},
					'evening1' => q{kechqurun},
					'am' => q{TO},
				},
				'abbreviated' => {
					'am' => q{TO},
					'evening1' => q{kechqurun},
					'pm' => q{TK},
					'midnight' => q{yarim tun},
					'night1' => q{kechasi},
					'noon' => q{tush payti},
					'morning1' => q{ertalab},
					'afternoon1' => q{kunduzi},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{TO},
					'evening1' => q{kechqurun},
					'pm' => q{TK},
					'midnight' => q{yarim tun},
					'night1' => q{kechasi},
					'noon' => q{tush payti},
					'morning1' => q{ertalab},
					'afternoon1' => q{kunduzi},
				},
				'narrow' => {
					'evening1' => q{kechqurun},
					'am' => q{TO},
					'noon' => q{tush payti},
					'night1' => q{kechasi},
					'afternoon1' => q{kunduzi},
					'morning1' => q{ertalab},
					'pm' => q{TK},
					'midnight' => q{yarim tun},
				},
				'abbreviated' => {
					'am' => q{TO},
					'evening1' => q{kechqurun},
					'noon' => q{tush payti},
					'night1' => q{kechasi},
					'morning1' => q{ertalab},
					'afternoon1' => q{kunduzi},
					'pm' => q{TK},
					'midnight' => q{yarim tun},
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
				'0' => 'miloddan avvalgi',
				'1' => 'milodiy'
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
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			E => q{ccc},
			EBhm => q{E, B h:mm},
			EBhms => q{E, B h:mm:ss},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{MMM, G y},
			GyMMMEd => q{E, d-MMM, G y},
			GyMMMd => q{d-MMM, G y},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss (v)},
			Hmv => q{HH:mm (v)},
			M => q{LL},
			MEd => q{E, dd/MM},
			MMM => q{LLL},
			MMMEd => q{E, d-MMM},
			MMMMW => q{MMM, W-'hafta'},
			MMMMd => q{d-MMMM},
			MMMd => q{d-MMM},
			Md => q{dd/MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a (v)},
			hmv => q{h:mm a (v)},
			ms => q{mm:ss},
			y => q{y},
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
		'generic' => {
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			E => q{ccc},
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
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, dd.MM},
			MMM => q{LLL},
			MMMEd => q{E, d-MMM},
			MMMMd => q{d-MMMM},
			MMMd => q{d-MMM},
			Md => q{dd.MM},
			d => q{d},
			h => q{h (a)},
			hm => q{h:mm (a)},
			hms => q{h:mm:ss (a)},
			ms => q{mm:ss},
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
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Timezone' => '{0} {1}',
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
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
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d-MMM – E, d-MMM},
				d => q{E, d-MMM – E, d-MMM},
			},
			MMMd => {
				M => q{d-MMM – d-MMM},
				d => q{d – d-MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a (v)},
				h => q{h:mm–h:mm a (v)},
				m => q{h:mm–h:mm a (v)},
			},
			hv => {
				a => q{h a – h a (v)},
				h => q{h–h a (v)},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{MMM – MMM, y},
				y => q{MMM, y – MMM, y},
			},
			yMMMEd => {
				M => q{E, d-MMM – E, d-MMM, y},
				d => q{E, d-MMM – E, d-MMM, y},
				y => q{E, d-MMM, y – E, d-MMM, y},
			},
			yMMMM => {
				M => q{MMMM – MMMM, y},
				y => q{MMMM, y – MMMM, y},
			},
			yMMMd => {
				M => q{d-MMM – d-MMM, y},
				d => q{d – d-MMM, y},
				y => q{d-MMM, y – d-MMM, y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
		'generic' => {
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{E, dd.MM – E, dd.MM},
				d => q{E, dd.MM – E, dd.MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d-MMM – E, d-MMM},
				d => q{E, d-MMM – E, d-MMM},
			},
			MMMd => {
				M => q{d-MMM – d-MMM},
				d => q{d – d-MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			y => {
				y => q{y–y (G)},
			},
			yM => {
				M => q{MM.y – MM.y (GGGGG)},
				y => q{MM.y – MM.y (GGGGG)},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y (GGGGG)},
				d => q{E, dd.MM.y – E, dd.MM.y (GGGGG)},
				y => q{E, dd.MM.y – E, dd.MM.y (GGGGG)},
			},
			yMMM => {
				M => q{y (G), MMM – MMM},
				y => q{y (G), MMM – y, MMM},
			},
			yMMMEd => {
				M => q{E, d-MMM – E, d-MMM, y (G)},
				d => q{E, d-MMM – E, d-MMM, y (G)},
				y => q{E, d-MMM, y – E, d-MMM, y (G)},
			},
			yMMMM => {
				M => q{MMMM – MMMM, y (G)},
				y => q{MMMM, y – MMMM, y (G)},
			},
			yMMMd => {
				M => q{d-MMM – d-MMM, y (G)},
				d => q{d – d-MMM, y (G)},
				y => q{d-MMM, y – d-MMM, y (G)},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y (GGGGG)},
				d => q{dd.MM.y – dd.MM.y (GGGGG)},
				y => q{dd.MM.y – dd.MM.y (GGGGG)},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0}),
		regionFormat => q({0} (+1)),
		regionFormat => q({0} (+0)),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Afgʻoniston vaqti#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
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
		'Africa/Bamako' => {
			exemplarCity => q#Bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangi#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banjul#,
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
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujumbura#,
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
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
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
		'Africa/Gaborone' => {
			exemplarCity => q#Gaborone#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Xarare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Yoxannesburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Xartum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinshasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Librevil#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lome#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbashi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusaka#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malabo#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputu#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maseru#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbabane#,
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
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndjamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakchott#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uagadugu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#San-Tome#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunis#,
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
		'America/Antigua' => {
			exemplarCity => q#Antigua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La-Rioxa#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio-Galyegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Salta#,
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
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
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
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belem#,
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
		'America/Bogota' => {
			exemplarCity => q#Bogota#,
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
		'America/Chihuahua' => {
			exemplarCity => q#Chihuahua#,
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
		'America/Denver' => {
			exemplarCity => q#Denver#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroyt#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eyrunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza#,
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
		'America/Grand_Turk' => {
			exemplarCity => q#Grand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenada#,
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
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indiana#,
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
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ikaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Yamayka#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jujuy#,
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
		'America/Lima' => {
			exemplarCity => q#Lima#,
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
		'America/Managua' => {
			exemplarCity => q#Managua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigo#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinika#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Masatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menomini#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
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
		'America/Monterrey' => {
			exemplarCity => q#Monterrey#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#Nyu-York#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon#,
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
		'America/Panama' => {
			exemplarCity => q#Panama#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pangnirtang#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribo#,
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
		'America/Santarem' => {
			exemplarCity => q#Santarem#,
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
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
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
		'America/Toronto' => {
			exemplarCity => q#Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortola#,
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
		'America/Yakutat' => {
			exemplarCity => q#Yakutat#,
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
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rotera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Syova#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Troll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vostok#,
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
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bayrut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Bruney#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkutta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chita#,
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
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubay#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dushanbe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
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
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
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
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamchatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Xandiga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala-Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Quvayt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Maskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosiya#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novosibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Uralsk#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Pnompen#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pxenyan#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Qatar#,
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
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tehron#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan-Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumchi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vyentyan#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerevan#,
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
		'Australia/Lindeman' => {
			exemplarCity => q#Lindeman#,
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
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
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
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
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
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Irlandiya yozgi vaqti#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
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
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersi#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiyev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lyublyana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#Britaniya yozgi vaqti#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lyuksemburg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariyexamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
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
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rim#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San-Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarayevo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
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
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanovsk#,
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
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varshava#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
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
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
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
				'standard' => q#Norfolk oroli vaqti#,
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
		'Pacific/Apia' => {
			exemplarCity => q#Apia#,
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
		'Pacific/Efate' => {
			exemplarCity => q#Efate#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderberi oroli#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fiji#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambye oroli#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Gvadalkanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Gonolulu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Jonston#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosrae#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kvajaleyn#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markiz orollari#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midvey orollari#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nauru#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niue#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Norfolk#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Numea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago-Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
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
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonga#,
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
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatapu#,
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
	 } }
);
no Moo;

1;

# vim: tabstop=4
