=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ku - Package for language Kurdish

=cut

package Locale::CLDR::Locales::Ku;
# This file auto generated from Data\common\main\ku.xml
#	on Tue  5 Dec  1:19:10 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.4');

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
				'aa' => 'afarî',
 				'ab' => 'abxazî',
 				'ace' => 'açehî',
 				'ady' => 'adîgeyî',
 				'af' => 'afrîkansî',
 				'ain' => 'aynuyî',
 				'ale' => 'alêwîtî',
 				'am' => 'amharî',
 				'an' => 'aragonî',
 				'ar' => 'erebî',
 				'ar_001' => 'erebiya standard',
 				'as' => 'asamî',
 				'ast' => 'astûrî',
 				'av' => 'avarî',
 				'ay' => 'aymarayî',
 				'az' => 'azerî',
 				'az@alt=short' => 'azerî',
 				'ba' => 'başkîrî',
 				'ban' => 'balînî',
 				'be' => 'belarusî',
 				'bem' => 'bembayî',
 				'bg' => 'bulgarî',
 				'bho' => 'bojpûrî',
 				'bi' => 'bîslamayî',
 				'bla' => 'blakfotî',
 				'bm' => 'bambarayî',
 				'bn' => 'bengalî',
 				'bo' => 'tîbetî',
 				'br' => 'bretonî',
 				'bs' => 'bosnî',
 				'bug' => 'bugî',
 				'byn' => 'byn',
 				'ca' => 'katalanî',
 				'ce' => 'çeçenî',
 				'ceb' => 'sebwanoyî',
 				'ch' => 'çamoroyî',
 				'chk' => 'çûkî',
 				'chm' => 'marî',
 				'chr' => 'çerokî',
 				'chy' => 'çeyenî',
 				'ckb' => 'soranî',
 				'co' => 'korsîkayî',
 				'cs' => 'çekî',
 				'cv' => 'çuvaşî',
 				'cy' => 'weylsî',
 				'da' => 'danmarkî',
 				'de' => 'elmanî',
 				'dsb' => 'sorbiya jêrîn',
 				'dua' => 'diwalayî',
 				'dv' => 'divehî',
 				'dz' => 'conxayî',
 				'ee' => 'eweyî',
 				'el' => 'yewnanî',
 				'en' => 'îngilîzî',
 				'eo' => 'esperantoyî',
 				'es' => 'spanî',
 				'et' => 'estonî',
 				'eu' => 'baskî',
 				'fa' => 'farisî',
 				'ff' => 'fulahî',
 				'fi' => 'fînî',
 				'fil' => 'fîlîpînoyî',
 				'fj' => 'fîjî',
 				'fo' => 'ferî',
 				'fr' => 'frensî',
 				'fur' => 'friyolî',
 				'fy' => 'frîsî',
 				'ga' => 'îrî',
 				'gd' => 'gaelîka skotî',
 				'gez' => 'gez',
 				'gil' => 'kîrîbatî',
 				'gl' => 'galîsî',
 				'gn' => 'guwaranî',
 				'gor' => 'gorontaloyî',
 				'gsw' => 'elmanîşî',
 				'gu' => 'gujaratî',
 				'gv' => 'manksî',
 				'ha' => 'hawsayî',
 				'haw' => 'hawayî',
 				'he' => 'îbranî',
 				'hi' => 'hindî',
 				'hil' => 'hîlîgaynonî',
 				'hr' => 'xirwatî',
 				'hsb' => 'sorbiya jorîn',
 				'ht' => 'haîtî',
 				'hu' => 'mecarî',
 				'hy' => 'ermenî',
 				'hz' => 'hereroyî',
 				'ia' => 'interlingua',
 				'id' => 'indonezî',
 				'ig' => 'îgboyî',
 				'ilo' => 'îlokanoyî',
 				'inh' => 'îngûşî',
 				'io' => 'îdoyî',
 				'is' => 'îzlendî',
 				'it' => 'îtalî',
 				'iu' => 'înuîtî',
 				'ja' => 'japonî',
 				'jbo' => 'lojbanî',
 				'jv' => 'javayî',
 				'ka' => 'gurcî',
 				'kab' => 'kabîlî',
 				'kea' => 'kapverdî',
 				'kk' => 'qazaxî',
 				'kl' => 'kalalîsûtî',
 				'km' => 'ximêrî',
 				'kn' => 'kannadayî',
 				'ko' => 'koreyî',
 				'kok' => 'konkanî',
 				'ks' => 'keşmîrî',
 				'ksh' => 'rîpwarî',
 				'ku' => 'kurdî',
 				'kv' => 'komî',
 				'kw' => 'kornî',
 				'ky' => 'kirgizî',
 				'lad' => 'ladînoyî',
 				'lb' => 'luksembûrgî',
 				'lez' => 'lezgînî',
 				'lg' => 'lugandayî',
 				'li' => 'lîmbûrgî',
 				'lkt' => 'lakotayî',
 				'ln' => 'lingalayî',
 				'lo' => 'lawsî',
 				'lrc' => 'luriya bakur',
 				'lt' => 'lîtwanî',
 				'lv' => 'latviyayî',
 				'mad' => 'madurayî',
 				'mas' => 'masayî',
 				'mdf' => 'mokşayî',
 				'mg' => 'malagasî',
 				'mh' => 'marşalî',
 				'mi' => 'maorî',
 				'mic' => 'mîkmakî',
 				'min' => 'mînangkabawî',
 				'mk' => 'makedonî',
 				'ml' => 'malayalamî',
 				'mn' => 'mongolî',
 				'moh' => 'mohawkî',
 				'mr' => 'maratî',
 				'ms' => 'malezî',
 				'mt' => 'maltayî',
 				'my' => 'burmayî',
 				'myv' => 'erzayî',
 				'mzn' => 'mazenderanî',
 				'na' => 'nawrûyî',
 				'nap' => 'napolîtanî',
 				'nb' => 'norwecî (bokmål)',
 				'ne' => 'nepalî',
 				'niu' => 'nîwî',
 				'nl' => 'holendî',
 				'nl_BE' => 'flamî',
 				'nn' => 'norwecî (nynorsk)',
 				'nso' => 'sotoyiya bakur',
 				'nv' => 'navajoyî',
 				'oc' => 'oksîtanî',
 				'om' => 'oromoyî',
 				'or' => 'oriyayî',
 				'os' => 'osetî',
 				'pa' => 'puncabî',
 				'pam' => 'kapampanganî',
 				'pap' => 'papyamentoyî',
 				'pau' => 'palawî',
 				'pl' => 'polonî',
 				'prg' => 'prûsyayî',
 				'ps' => 'peştûyî',
 				'pt' => 'portugalî',
 				'qu' => 'keçwayî',
 				'rap' => 'rapanuyî',
 				'rar' => 'rarotongî',
 				'rm' => 'romancî',
 				'ro' => 'romanî',
 				'ru' => 'rusî',
 				'rup' => 'aromanî',
 				'rw' => 'kînyariwandayî',
 				'sa' => 'sanskrîtî',
 				'sc' => 'sardînî',
 				'scn' => 'sicîlî',
 				'sco' => 'skotî',
 				'sd' => 'sindhî',
 				'se' => 'samiya bakur',
 				'si' => 'kîngalî',
 				'sk' => 'slovakî',
 				'sl' => 'slovenî',
 				'sm' => 'samoayî',
 				'smn' => 'samiya înarî',
 				'sn' => 'şonayî',
 				'so' => 'somalî',
 				'sq' => 'elbanî',
 				'sr' => 'sirbî',
 				'srn' => 'sirananî',
 				'ss' => 'swazî',
 				'st' => 'sotoyiya başûr',
 				'su' => 'sundanî',
 				'sv' => 'swêdî',
 				'sw' => 'swahîlî',
 				'swb' => 'komorî',
 				'syr' => 'siryanî',
 				'ta' => 'tamîlî',
 				'te' => 'telûgûyî',
 				'tet' => 'tetûmî',
 				'tg' => 'tacikî',
 				'th' => 'tayî',
 				'ti' => 'tigrînî',
 				'tk' => 'tirkmenî',
 				'tlh' => 'klîngonî',
 				'tn' => 'tswanayî',
 				'to' => 'tongî',
 				'tpi' => 'tokpisinî',
 				'tr' => 'tirkî',
 				'trv' => 'tarokoyî',
 				'ts' => 'tsongayî',
 				'tt' => 'teterî',
 				'tum' => 'tumbukayî',
 				'tvl' => 'tuvalûyî',
 				'ty' => 'tahîtî',
 				'tzm' => 'temazîxtî',
 				'udm' => 'udmurtî',
 				'ug' => 'oygurî',
 				'uk' => 'ukraynî',
 				'ur' => 'urdûyî',
 				'uz' => 'ozbekî',
 				'vi' => 'viyetnamî',
 				'vo' => 'volapûkî',
 				'wa' => 'walonî',
 				'war' => 'warayî',
 				'wo' => 'wolofî',
 				'xh' => 'xosayî',
 				'yi' => 'yidîşî',
 				'yo' => 'yorubayî',
 				'yue' => 'kantonî',
 				'zu' => 'zuluyî',
 				'zza' => 'zazakî',

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
			'Arab' => 'erebî',
 			'Armn' => 'ermenî',
 			'Beng' => 'bengalî',
 			'Cyrl' => 'kirîlî',
 			'Deva' => 'devanagarî',
 			'Geor' => 'gurcî',
 			'Grek' => 'yewnanî',
 			'Khmr' => 'ximêrî',
 			'Latn' => 'latînî',
 			'Mong' => 'mongolî',
 			'Tibt' => 'tîbetî',
 			'Zsym' => 'sembol',
 			'Zxxx' => 'ne nivîsandî',
 			'Zyyy' => 'hevpar',
 			'Zzzz' => 'nivîsa nenas',

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
			'001' => 'Cîhan',
 			'002' => 'Afrîka',
 			'003' => 'Amerîkaya Bakur',
 			'005' => 'Amerîkaya Başûr',
 			'009' => 'Okyanûsya',
 			'013' => 'Amerîkaya Navîn',
 			'015' => 'Afrîkaya Bakur',
 			'019' => 'Amerîka',
 			'029' => 'Karîb',
 			'053' => 'Awistralasya',
 			'054' => 'Melanezya',
 			'057' => 'Herêma Mîkronezya',
 			'061' => 'Polînezya',
 			'142' => 'Asya',
 			'150' => 'Ewropa',
 			'151' => 'Ewropaya Rojhilat',
 			'155' => 'Ewropaya Rojava',
 			'419' => 'Amerîkaya Latînî',
 			'AD' => 'Andorra',
 			'AE' => 'Emîrtiyên Erebî yên Yekbûyî',
 			'AF' => 'Efxanistan',
 			'AG' => 'Antîgua û Berbûda',
 			'AL' => 'Albanya',
 			'AM' => 'Ermenistan',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktîka',
 			'AR' => 'Arjentîn',
 			'AS' => 'Samoaya Amerîkanî',
 			'AT' => 'Awistirya',
 			'AU' => 'Awistralya',
 			'AW' => 'Arûba',
 			'AZ' => 'Azerbaycan',
 			'BA' => 'Bosniya û Herzegovîna',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladeş',
 			'BE' => 'Belçîka',
 			'BF' => 'Burkîna Faso',
 			'BG' => 'Bulgaristan',
 			'BH' => 'Behreyn',
 			'BI' => 'Burundî',
 			'BJ' => 'Bênîn',
 			'BL' => 'Saint-Barthélemy',
 			'BM' => 'Bermûda',
 			'BN' => 'Brûney',
 			'BO' => 'Bolîvya',
 			'BR' => 'Brazîl',
 			'BS' => 'Bahama',
 			'BT' => 'Bûtan',
 			'BW' => 'Botswana',
 			'BY' => 'Belarûs',
 			'BZ' => 'Belîze',
 			'CA' => 'Kanada',
 			'CD' => 'Kongo - Kînşasa',
 			'CD@alt=variant' => 'Kongo (KDK)',
 			'CF' => 'Komara Afrîkaya Navend',
 			'CG' => 'Kongo - Brazzaville',
 			'CG@alt=variant' => 'Kongo (Komar)',
 			'CH' => 'Swîsre',
 			'CI' => 'Peravê Diranfîl',
 			'CK' => 'Giravên Cook',
 			'CL' => 'Şîle',
 			'CM' => 'Kamerûn',
 			'CN' => 'Çîn',
 			'CO' => 'Kolombiya',
 			'CR' => 'Kosta Rîka',
 			'CU' => 'Kûba',
 			'CV' => 'Kap Verde',
 			'CY' => 'Kîpros',
 			'CZ' => 'Çekya',
 			'CZ@alt=variant' => 'Komara Çekî',
 			'DE' => 'Almanya',
 			'DJ' => 'Cîbûtî',
 			'DK' => 'Danîmarka',
 			'DM' => 'Domînîka',
 			'DO' => 'Komara Domînîk',
 			'DZ' => 'Cezayir',
 			'EC' => 'Ekuador',
 			'EE' => 'Estonya',
 			'EG' => 'Misir',
 			'EH' => 'Sahraya Rojava',
 			'ER' => 'Erîtrea',
 			'ES' => 'Spanya',
 			'ET' => 'Etiyopya',
 			'EU' => 'Yekîtiya Ewropayê',
 			'FI' => 'Fînlenda',
 			'FJ' => 'Fîjî',
 			'FK' => 'Giravên Malvîn',
 			'FK@alt=variant' => 'Giravên Falkland',
 			'FM' => 'Mîkronezya',
 			'FO' => 'Giravên Feroe',
 			'FR' => 'Fransa',
 			'GA' => 'Gabon',
 			'GB' => 'Keyaniya Yekbûyî',
 			'GB@alt=short' => 'KY',
 			'GD' => 'Grenada',
 			'GE' => 'Gurcistan',
 			'GF' => 'Guyanaya Fransî',
 			'GH' => 'Gana',
 			'GI' => 'Cîbraltar',
 			'GL' => 'Grînlenda',
 			'GM' => 'Gambiya',
 			'GN' => 'Gîne',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Gîneya Rojbendî',
 			'GR' => 'Yewnanistan',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Gîne-Bissau',
 			'GY' => 'Guyana',
 			'HK@alt=short' => 'Hong Kong',
 			'HN' => 'Hondûras',
 			'HR' => 'Kroatya',
 			'HT' => 'Haîtî',
 			'HU' => 'Macaristan',
 			'IC' => 'Giravên Qenariyê',
 			'ID' => 'Îndonezya',
 			'IE' => 'Îrlenda',
 			'IL' => 'Îsraêl',
 			'IM' => 'Girava Man',
 			'IN' => 'Hindistan',
 			'IQ' => 'Iraq',
 			'IR' => 'Îran',
 			'IS' => 'Îslenda',
 			'IT' => 'Îtalya',
 			'JM' => 'Jamaîka',
 			'JO' => 'Urdun',
 			'JP' => 'Japon',
 			'KE' => 'Kenya',
 			'KG' => 'Qirgizistan',
 			'KH' => 'Kamboca',
 			'KI' => 'Kirîbatî',
 			'KM' => 'Komor',
 			'KN' => 'Saint Kitts û Nevîs',
 			'KP' => 'Korêya Bakur',
 			'KR' => 'Korêya Başûr',
 			'KW' => 'Kuweyt',
 			'KY' => 'Giravên Kaymanê',
 			'KZ' => 'Qazaxistan',
 			'LA' => 'Laos',
 			'LB' => 'Libnan',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Srî Lanka',
 			'LR' => 'Lîberya',
 			'LS' => 'Lesoto',
 			'LT' => 'Lîtvanya',
 			'LU' => 'Lûksembûrg',
 			'LV' => 'Letonya',
 			'LY' => 'Lîbya',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'MF',
 			'MG' => 'Madagaskar',
 			'MH' => 'Giravên Marşal',
 			'MK' => 'Makedonya',
 			'MK@alt=variant' => 'MK',
 			'ML' => 'Malî',
 			'MM' => 'Myanmar (Birmanya)',
 			'MN' => 'Mongolya',
 			'MO@alt=short' => 'Makao',
 			'MP' => 'Giravên Bakurê Marianan',
 			'MQ' => 'Martinique',
 			'MR' => 'Morîtanya',
 			'MT' => 'Malta',
 			'MU' => 'Maurîtius',
 			'MV' => 'Maldîv',
 			'MW' => 'Malawî',
 			'MX' => 'Meksîk',
 			'MY' => 'Malezya',
 			'MZ' => 'Mozambîk',
 			'NA' => 'Namîbya',
 			'NC' => 'Kaledonyaya Nû',
 			'NE' => 'Nîjer',
 			'NF' => 'Girava Norfolk',
 			'NG' => 'Nîjerya',
 			'NI' => 'Nîkaragua',
 			'NL' => 'Holenda',
 			'NO' => 'Norwêc',
 			'NP' => 'Nepal',
 			'NR' => 'Naûrû',
 			'NU' => 'Niûe',
 			'NZ' => 'Nû Zelenda',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Perû',
 			'PF' => 'Polînezyaya Fransî',
 			'PG' => 'Papua Gîneya Nû',
 			'PH' => 'Filîpîn',
 			'PK' => 'Pakistan',
 			'PL' => 'Polonya',
 			'PM' => 'Saint-Pierre û Miquelon',
 			'PN' => 'Giravên Pitcairn',
 			'PR' => 'Porto Rîko',
 			'PS' => 'Xakên filistînî',
 			'PS@alt=short' => 'Filistîn',
 			'PT' => 'Portûgal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qeter',
 			'RE' => 'Réunion',
 			'RO' => 'Romanya',
 			'RS' => 'Serbistan',
 			'RU' => 'Rûsya',
 			'RW' => 'Rwanda',
 			'SA' => 'Erebistana Siyûdî',
 			'SB' => 'Giravên Salomon',
 			'SC' => 'Seyşel',
 			'SD' => 'Sûdan',
 			'SE' => 'Swêd',
 			'SG' => 'Singapûr',
 			'SI' => 'Slovenya',
 			'SK' => 'Slovakya',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marîno',
 			'SN' => 'Senegal',
 			'SO' => 'Somalya',
 			'SR' => 'Sûrînam',
 			'SS' => 'Sûdana Başûr',
 			'ST' => 'Sao Tome û Prînsîpe',
 			'SV' => 'El Salvador',
 			'SY' => 'Sûrî',
 			'SZ' => 'Swazîlenda',
 			'TC' => 'Giravên Turk û Kaîkos',
 			'TD' => 'Çad',
 			'TG' => 'Togo',
 			'TH' => 'Taylenda',
 			'TJ' => 'Tacîkistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Tîmora-Leste',
 			'TL@alt=variant' => 'Tîmora Rojhilat',
 			'TM' => 'Tirkmenistan',
 			'TN' => 'Tûnis',
 			'TO' => 'Tonga',
 			'TR' => 'Tirkiye',
 			'TT' => 'Trînîdad û Tobago',
 			'TV' => 'Tûvalû',
 			'TW' => 'Taywan',
 			'TZ' => 'Tanzanya',
 			'UA' => 'Ûkrayna',
 			'UG' => 'Ûganda',
 			'UN' => 'Neteweyên Yekbûyî',
 			'US' => 'Dewletên Yekbûyî yên Amerîkayê',
 			'US@alt=short' => 'DYA',
 			'UY' => 'Ûrûguay',
 			'UZ' => 'Ûzbêkistan',
 			'VA' => 'Vatîkan',
 			'VC' => 'Saint Vincent û Giravên Grenadîn',
 			'VE' => 'Venezuela',
 			'VN' => 'Viyetnam',
 			'VU' => 'Vanûatû',
 			'WF' => 'Wallis û Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'ZA' => 'Afrîkaya Başûr',
 			'ZM' => 'Zambiya',
 			'ZW' => 'Zîmbabwe',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'salname',
 			'collation' => 'rêzkirin',
 			'currency' => 'diwîz',

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
 				'chinese' => q{salnameya çînî},
 				'gregorian' => q{salnameya gregorî},
 				'hebrew' => q{salnameya îbranî},
 				'islamic' => q{salnameya koçî},
 				'iso8601' => q{salnameya ISO-8601},
 				'japanese' => q{salnameya japonî},
 				'persian' => q{salnameya îranî},
 				'roc' => q{salnameya Komara Çînê},
 			},
 			'numbers' => {
 				'roman' => q{hejmarên romî},
 			},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'ziman: {0}',
 			'script' => 'nivîs: {0}',
 			'region' => 'herêm: {0}',

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
			auxiliary => qr{[á à ă â å ä ã ā æ é è ĕ ë ē í ì ĭ ï ī ñ ó ò ŏ ô ø ō œ ß ú ù ŭ ū ÿ]},
			index => ['A', 'B', 'C', 'Ç', 'D', 'E', 'Ê', 'F', 'G', 'H', 'I', 'Î', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Ş', 'T', 'U', 'Û', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c ç d e ê f g h i î j k l m n o p q r s ş t u û v w x y z]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Ç', 'D', 'E', 'Ê', 'F', 'G', 'H', 'I', 'Î', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Ş', 'T', 'U', 'Û', 'V', 'W', 'X', 'Y', 'Z'], };
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
	default		=> qq{‘},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'coordinate' => {
						'east' => q({0} rojhilat),
						'north' => q({0} bakur),
						'south' => q({0} başûr),
						'west' => q({0} rojava),
					},
					'day' => {
						'name' => q(roj),
						'one' => q({0} roj),
						'other' => q({0} roj),
						'per' => q({0}/roj),
					},
					'hour' => {
						'name' => q(saet),
						'one' => q({0} saet),
						'other' => q({0} saet),
						'per' => q({0}/st),
					},
					'minute' => {
						'name' => q(deqîqe),
						'one' => q({0} deqîqe),
						'other' => q({0} deqîqe),
						'per' => q({0}/d),
					},
					'month' => {
						'name' => q(meh),
						'one' => q({0} meh),
						'other' => q({0} meh),
						'per' => q({0}/meh),
					},
					'second' => {
						'name' => q(sanî),
						'one' => q({0} saniye),
						'other' => q({0} saniye),
						'per' => q({0}/s),
					},
					'week' => {
						'name' => q(hefte),
						'one' => q({0} hefte),
						'other' => q({0} hefte),
						'per' => q({0}/hefte),
					},
					'year' => {
						'name' => q(sal),
						'one' => q({0} sal),
						'other' => q({0} sal),
					},
				},
				'narrow' => {
					'coordinate' => {
						'east' => q({0}Rh),
						'north' => q({0}Bk),
						'south' => q({0}Bş),
						'west' => q({0}Ra),
					},
					'day' => {
						'name' => q(roj),
						'one' => q({0}r),
						'other' => q({0}r),
					},
					'hour' => {
						'name' => q(saet),
						'one' => q({0}st),
						'other' => q({0}st),
					},
					'minute' => {
						'name' => q(d),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					'month' => {
						'name' => q(meh),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0}s),
						'other' => q({0}s),
					},
					'week' => {
						'one' => q({0}hf),
						'other' => q({0}hf),
					},
					'year' => {
						'name' => q(sl),
						'one' => q({0}sl),
						'other' => q({0}sl),
					},
				},
				'short' => {
					'coordinate' => {
						'east' => q({0} Rh),
						'north' => q({0} Bk),
						'south' => q({0} Bş),
						'west' => q({0} Ra),
					},
					'day' => {
						'name' => q(roj),
						'one' => q({0} roj),
						'other' => q({0} roj),
						'per' => q({0}/r),
					},
					'hour' => {
						'name' => q(saet),
						'one' => q({0} st),
						'other' => q({0} st),
						'per' => q({0}/st),
					},
					'minute' => {
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					'month' => {
						'name' => q(meh),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'week' => {
						'name' => q(hf),
						'one' => q({0} hf),
						'other' => q({0} hf),
						'per' => q({0}/hf),
					},
					'year' => {
						'name' => q(sal),
						'one' => q({0} sal),
						'other' => q({0} sal),
						'per' => q({0}/sal),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:erê|e|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:na|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} û {1}),
				2 => q({0} û {1}),
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
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q(.),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
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
				'standard' => {
					'default' => '#,##0.###',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '%#,##0',
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
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(ewro),
				'one' => q(ewro),
				'other' => q(ewro),
			},
		},
		'TRY' => {
			symbol => '₺',
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
							'rêb',
							'reş',
							'ada',
							'avr',
							'gul',
							'pûş',
							'tîr',
							'gel',
							'rez',
							'kew',
							'ser',
							'ber'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'R',
							'R',
							'A',
							'A',
							'G',
							'P',
							'T',
							'G',
							'R',
							'K',
							'S',
							'B'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'rêbendanê',
							'reşemiyê',
							'adarê',
							'avrêlê',
							'gulanê',
							'pûşperê',
							'tîrmehê',
							'gelawêjê',
							'rezberê',
							'kewçêrê',
							'sermawezê',
							'berfanbarê'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'rêb',
							'reş',
							'ada',
							'avr',
							'gul',
							'pûş',
							'tîr',
							'gel',
							'rez',
							'kew',
							'ser',
							'ber'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'R',
							'R',
							'A',
							'A',
							'G',
							'P',
							'T',
							'G',
							'R',
							'K',
							'S',
							'B'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'rêbendan',
							'reşemî',
							'adar',
							'avrêl',
							'gulan',
							'pûşper',
							'tîrmeh',
							'gelawêj',
							'rezber',
							'kewçêr',
							'sermawez',
							'berfanbar'
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
							'muẖerem',
							'sefer',
							'rebîʿulewel',
							'rebîʿulaxer',
							'cemazîyelewel',
							'cemazîyelaxer',
							'receb',
							'şeʿban',
							'remezan',
							'şewal',
							'zîlqeʿde',
							'zîlẖece'
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
						mon => 'dş',
						tue => 'sş',
						wed => 'çş',
						thu => 'pş',
						fri => 'în',
						sat => 'ş',
						sun => 'yş'
					},
					narrow => {
						mon => 'D',
						tue => 'S',
						wed => 'Ç',
						thu => 'P',
						fri => 'Î',
						sat => 'Ş',
						sun => 'Y'
					},
					short => {
						mon => 'dş',
						tue => 'sş',
						wed => 'çş',
						thu => 'pş',
						fri => 'în',
						sat => 'ş',
						sun => 'yş'
					},
					wide => {
						mon => 'duşem',
						tue => 'sêşem',
						wed => 'çarşem',
						thu => 'pêncşem',
						fri => 'în',
						sat => 'şemî',
						sun => 'yekşem'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'dş',
						tue => 'sş',
						wed => 'çş',
						thu => 'pş',
						fri => 'în',
						sat => 'ş',
						sun => 'yş'
					},
					narrow => {
						mon => 'D',
						tue => 'S',
						wed => 'Ç',
						thu => 'P',
						fri => 'Î',
						sat => 'Ş',
						sun => 'Y'
					},
					short => {
						mon => 'dş',
						tue => 'sş',
						wed => 'çş',
						thu => 'pş',
						fri => 'în',
						sat => 'ş',
						sun => 'yş'
					},
					wide => {
						mon => 'duşem',
						tue => 'sêşem',
						wed => 'çarşem',
						thu => 'pêncşem',
						fri => 'în',
						sat => 'şemî',
						sun => 'yekşem'
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
					abbreviated => {0 => 'Ç1',
						1 => 'Ç2',
						2 => 'Ç3',
						3 => 'Ç4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Ç1',
						1 => 'Ç2',
						2 => 'Ç3',
						3 => 'Ç4'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Ç1',
						1 => 'Ç2',
						2 => 'Ç3',
						3 => 'Ç4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
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
					'am' => q{BN},
					'pm' => q{PN},
				},
				'wide' => {
					'am' => q{BN},
					'pm' => q{PN},
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
				'0' => 'BZ',
				'1' => 'PZ'
			},
			wide => {
				'0' => 'berî zayînê',
				'1' => 'piştî zayînê'
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
		},
		'gregorian' => {
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
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
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
			E => q{ccc},
			d => q{d},
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
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			fallback => '{0} – {1}',
		},
	} },
);

no Moo;

1;

# vim: tabstop=4
