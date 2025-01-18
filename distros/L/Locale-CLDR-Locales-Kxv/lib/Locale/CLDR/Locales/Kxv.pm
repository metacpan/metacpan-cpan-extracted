=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Kxv - Package for language Kuvi

=cut

package Locale::CLDR::Locales::Kxv;
# This file auto generated from Data\common\main\kxv.xml
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
				'af' => 'aprikaans',
 				'am' => 'aarmenia',
 				'ar' => 'arabic',
 				'ar_001' => 'punijuga mānānka arabic',
 				'as' => 'aasamis',
 				'az' => 'ajerbaijani',
 				'az@alt=short' => 'ājeri',
 				'be' => 'belarusiati',
 				'bg' => 'bulgeriati',
 				'bn' => 'bangali',
 				'bo' => 'tibetī',
 				'brx' => 'boḍo',
 				'bs' => 'bajniati',
 				'ca' => 'keṭelan',
 				'chr' => 'cerokī',
 				'cs' => 'cek',
 				'da' => 'denis',
 				'de' => 'jerman',
 				'de_AT' => 'ausṭriati jerman',
 				'de_CH' => 'svis high jerman',
 				'doi' => 'ḍogri',
 				'el' => 'grīk',
 				'en' => 'ingrajī',
 				'en_AU' => 'ausṭreliati ingarjī',
 				'en_CA' => 'kanaḍati ingarjī',
 				'en_GB' => 'briṭisti ingrajī',
 				'en_GB@alt=short' => 'juktarajyati ingrajī',
 				'en_US' => 'amerikati ingrajī',
 				'en_US@alt=short' => 'juktarasṭrati ingrajī',
 				'es' => 'spenis',
 				'es_419' => 'laṭin americati spenis',
 				'es_ES' => 'yuropīyati spenis',
 				'es_MX' => 'meksikoti spenis',
 				'et' => 'esṭoniyati',
 				'eu' => 'bask',
 				'fa' => 'persiati',
 				'fa_AF' => 'ḍari',
 				'fi' => 'pinnis',
 				'fil' => 'pilipino',
 				'fr' => 'prenc',
 				'fr_CA' => 'kanaḍati prenc',
 				'fr_CH' => 'svis prenc',
 				'gl' => 'galesiati',
 				'gu' => 'gujraṭī',
 				'he' => 'hibru',
 				'hi_Latn' => 'hindi',
 				'hr' => 'kroesiati',
 				'hu' => 'hngeriyati',
 				'hy' => 'aarmeniati',
 				'id' => 'inḍonesiyati',
 				'is' => 'aislanḍik',
 				'it' => 'iṭaliti',
 				'ja' => 'japanij',
 				'ka' => 'jorjiati',
 				'kk' => 'kjaak',
 				'km' => 'kmer',
 				'kn' => 'knnaḍa',
 				'ko' => 'koriati',
 				'kok' => 'konkanī',
 				'ks' => 'kasmīrī',
 				'kxv' => 'kuvi',
 				'ky' => 'kyrgyj',
 				'lo' => 'lao',
 				'lt' => 'lituaniyati',
 				'lv' => 'laṭviati',
 				'mai' => 'maitilī',
 				'mk' => 'mesiḍoniyati',
 				'ml' => 'malyalam',
 				'mn' => 'mongoliyati',
 				'mni' => 'maṇipurī',
 				'mr' => 'maraṭi',
 				'ms' => 'malei',
 				'my' => 'burmij',
 				'nb' => 'norvejiati būkmal',
 				'ne' => 'nepaḷī',
 				'nl' => 'ḍc',
 				'nl_BE' => 'vlaams',
 				'or' => 'oḍiaa',
 				'pa' => 'pnjabī',
 				'pl' => 'polis',
 				'pt' => 'portugīj',
 				'pt_BR' => 'brajilian portugīj',
 				'pt_PT' => 'yuropīyati portugīj',
 				'ro' => 'romaniyati',
 				'ro_MD' => 'molḍaviati',
 				'ru' => 'rusiyati',
 				'sa' => 'sanskrit',
 				'sat' => 'santalī',
 				'sd' => 'sindi',
 				'si' => 'sinhali',
 				'sk' => 'slovak',
 				'sl' => 'sloveniyati',
 				'sq' => 'albaniyati',
 				'sr' => 'sarbiyati',
 				'sv' => 'sviḍis',
 				'sw' => 'svahili',
 				'sw_CD' => 'kongo svahili',
 				'ta' => 'tamiḷ',
 				'te' => 'telugu',
 				'th' => 'tae',
 				'tr' => 'turkis',
 				'uk' => 'yukraniyati',
 				'ur' => 'urdu',
 				'uz' => 'ujbek',
 				'vi' => 'vietnaamti',
 				'xnr' => 'kangri',
 				'zh' => 'cainati',
 				'zh@alt=menu' => 'cainati, manḍarin',
 				'zh_Hans' => 'sahaj cainati',
 				'zh_Hans@alt=long' => 'sahaj manḍarin cainati',
 				'zh_Hant' => 'hirudlu cainati',
 				'zh_Hant@alt=long' => 'hirudlu manḍarin cainati',
 				'zu' => 'julu',

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
			'Arab' => 'aarabic',
 			'Beng' => 'bangalī',
 			'Brah' => 'brahmi',
 			'Cher' => 'cerokī',
 			'Cyrl' => 'sirilik',
 			'Deva' => 'devnagrī',
 			'Gujr' => 'gujraṭī',
 			'Guru' => 'gurmukī',
 			'Hans' => 'sahaj',
 			'Hans@alt=stand-alone' => 'sahaj han',
 			'Hant' => 'hirudlu',
 			'Hant@alt=stand-alone' => 'hirudlu han',
 			'Knda' => 'knnaḍa',
 			'Latn' => 'laṭin',
 			'Mlym' => 'malayalam',
 			'Orya' => 'oḍiaa',
 			'Saur' => 'saurastra',
 			'Taml' => 'tamiḷ',
 			'Telu' => 'telugu',
 			'Zxxx' => 'raciaahalee',
 			'Zzzz' => 'puṇāātiakr',

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
			'001' => 'raji, purti',
 			'419' => 'laṭin amerika',
 			'AD' => 'ānḍorā',
 			'AE' => 'aanḍiti arab emireṭs',
 			'AF' => 'aapganistan',
 			'AG' => 'eṇṭigaa aḍe barbuḍaa',
 			'AI' => 'anguila',
 			'AL' => 'albania',
 			'AM' => 'aarmenia',
 			'AO' => 'angola',
 			'AQ' => 'ānṭarkṭikā',
 			'AR' => 'aarhenṭina',
 			'AS' => 'amerikati samva',
 			'AT' => 'austria',
 			'AU' => 'astrelia',
 			'AW' => 'aruba',
 			'AX' => 'eleṇḍ dīp',
 			'AZ' => 'ajerbaijan',
 			'BA' => 'bajnia aḍe hertsegovina',
 			'BB' => 'barbaḍos',
 			'BD' => 'banglades',
 			'BE' => 'beljiym',
 			'BF' => 'burkina paso',
 			'BG' => 'bulgaria',
 			'BH' => 'bāren',
 			'BI' => 'buruṇḍī',
 			'BJ' => 'benīn',
 			'BL' => 'se barṭelemi',
 			'BM' => 'bermuḍā',
 			'BN' => 'brunae',
 			'BO' => 'boliviā',
 			'BQ' => 'karibiyn nedrlends',
 			'BR' => 'brājil',
 			'BS' => 'bāhāmās',
 			'BT' => 'buṭān',
 			'BW' => 'boṭsvana',
 			'BY' => 'belarūs',
 			'BZ' => 'belīj',
 			'CA' => 'kanaḍa',
 			'CC' => 'kokos keling dīp',
 			'CD' => 'kongo - kinsasa',
 			'CD@alt=variant' => 'kongo (drc)',
 			'CF' => 'madini aaprika republik',
 			'CG' => 'kongo - brajavil',
 			'CG@alt=variant' => 'kongo republik',
 			'CH' => 'svitjerlaṇḍ',
 			'CI' => 'koṭ ḍi vaa',
 			'CI@alt=variant' => 'aivrī kosṭ',
 			'CK' => 'kuk dīp',
 			'CL' => 'cili',
 			'CM' => 'kemarun',
 			'CN' => 'caina',
 			'CO' => 'kolmbiaa',
 			'CR' => 'kosta rika',
 			'CU' => 'kyuba',
 			'CV' => 'kep vrḍi',
 			'CW' => 'kyurasao',
 			'CX' => 'kristmas dīp',
 			'CY' => 'saipras',
 			'CZ' => 'cekiya',
 			'CZ@alt=variant' => 'cek republik',
 			'DE' => 'jermanī',
 			'DG' => 'ḍiego garsia',
 			'DJ' => 'jibutī',
 			'DK' => 'ḍenmark',
 			'DM' => 'dominika',
 			'DO' => 'dominikan republik',
 			'DZ' => 'aljīriaa',
 			'EA' => 'seuṭa aḍe melila',
 			'EC' => 'ekvaḍor',
 			'EE' => 'esṭoniya',
 			'EG' => 'ījipṭ',
 			'EH' => 'vedakuṇpu sahara',
 			'ER' => 'īriṭriaa',
 			'ES' => 'spein',
 			'ET' => 'ītiyopiya',
 			'FI' => 'pinlaṇd',
 			'FJ' => 'piji',
 			'FK' => 'paklaṇd dīp',
 			'FK@alt=variant' => 'paklaṇd dīp (āislas malvinas)',
 			'FM' => 'micronesiaa',
 			'FO' => 'pēro dīp',
 			'FR' => 'prans',
 			'GA' => 'gbon',
 			'GB' => 'uniṭeḍ kingḍom',
 			'GB@alt=short' => 'yuke',
 			'GD' => 'graneida',
 			'GE' => 'jeorjiaa',
 			'GF' => 'prenc guiyana',
 			'GG' => 'grnse',
 			'GH' => 'gana',
 			'GI' => 'jbralṭr',
 			'GL' => 'grīnlanḍ',
 			'GM' => 'gambia',
 			'GN' => 'gini',
 			'GP' => 'gvadelup',
 			'GQ' => 'ikveṭorial gini',
 			'GR' => 'grīs',
 			'GS' => 'dakiṇ jārjiā aḍe dakiṇ sandwich dīp',
 			'GT' => 'gvaṭemala',
 			'GU' => 'guām',
 			'GW' => 'gini-bisau',
 			'GY' => 'guyana',
 			'HK' => 'hong kong (sar) caina',
 			'HK@alt=short' => 'hong kong',
 			'HN' => 'honḍuras',
 			'HR' => 'kroesia',
 			'HT' => 'haiti',
 			'HU' => 'hungarī',
 			'IC' => 'kanari dīp',
 			'ID' => 'inḍonesiya',
 			'IE' => 'aayarlanḍ',
 			'IL' => 'israel',
 			'IM' => 'aail āp man',
 			'IN' => 'inḍiā',
 			'IO' => 'briṭis inḍiāti samudra handi',
 			'IQ' => 'irak',
 			'IR' => 'iran',
 			'IS' => 'aislanḍ',
 			'IT' => 'iṭalī',
 			'JE' => 'jersī',
 			'JM' => 'jamaika',
 			'JO' => 'jorḍan',
 			'JP' => 'japan',
 			'KE' => 'kenya',
 			'KG' => 'kirgistan',
 			'KH' => 'kamboḍia',
 			'KI' => 'kiribaṭi',
 			'KM' => 'komoros',
 			'KN' => 'seint kiṭs āḍe nebis',
 			'KP' => 'uttar koriya',
 			'KR' => 'dkiṇ koriyaa',
 			'KW' => 'kuvet',
 			'KY' => 'keimen dīp',
 			'KZ' => 'kajakstan',
 			'LA' => 'laos',
 			'LB' => 'lebanon',
 			'LC' => 'seint lusiya',
 			'LI' => 'likṭensṭein',
 			'LK' => 'sri lanka',
 			'LR' => 'laiberīya',
 			'LS' => 'lesotho',
 			'LT' => 'liṭuaania',
 			'LU' => 'lksemborg',
 			'LV' => 'laṭviya',
 			'LY' => 'libya',
 			'MA' => 'morkko',
 			'MC' => 'monako',
 			'MD' => 'molḍovaa',
 			'ME' => 'monṭenegro',
 			'MF' => 'seint martin',
 			'MG' => 'madagascar',
 			'MH' => 'marsall dīp',
 			'MK' => 'uttar mesiḍoniya',
 			'ML' => 'mali',
 			'MM' => 'myanmar (brma)',
 			'MN' => 'mongolia',
 			'MO' => 'makao sar cina',
 			'MO@alt=short' => 'makao',
 			'MP' => 'uttar mariyana dīp',
 			'MQ' => 'marṭinik',
 			'MR' => 'mauriṭaniya',
 			'MS' => 'monṭserrarṭ',
 			'MT' => 'malṭaa',
 			'MU' => 'mauriss',
 			'MV' => 'māldīp',
 			'MW' => 'malavī',
 			'MX' => 'meksīko',
 			'MY' => 'maleseāā',
 			'MZ' => 'mojambik',
 			'NA' => 'namibia',
 			'NC' => 'nyu keleḍoniya',
 			'NE' => 'naījr',
 			'NF' => 'norpok dīp',
 			'NG' => 'naigeria',
 			'NI' => 'nikaraguaa',
 			'NL' => 'nederlanḍs',
 			'NO' => 'norvay',
 			'NP' => 'nepal',
 			'NR' => 'nauru',
 			'NU' => 'niyu',
 			'NZ' => 'nyu jīlanḍ',
 			'OM' => 'oman',
 			'PA' => 'panema',
 			'PE' => 'peru',
 			'PF' => 'prenc',
 			'PG' => 'papua nyu gini',
 			'PH' => 'pilippines',
 			'PK' => 'pakistan',
 			'PL' => 'polanḍ',
 			'PM' => 'seint pierri ande mikelon',
 			'PN' => 'piṭkarn dīp',
 			'PR' => 'puerto rico',
 			'PS' => 'palesṭiati handi',
 			'PS@alt=short' => 'palesṭain',
 			'PT' => 'portugal',
 			'PW' => 'palau',
 			'PY' => 'pareguvai',
 			'QA' => 'katar',
 			'RE' => 'riyuniyn',
 			'RO' => 'romaniya',
 			'RS' => 'serbia',
 			'RU' => 'russia',
 			'RW' => 'rvanḍa',
 			'SA' => 'saūdi arabiya',
 			'SB' => 'soloman dīp',
 			'SC' => 'siselles',
 			'SD' => 'suḍan',
 			'SE' => 'sviḍen',
 			'SG' => 'singapor',
 			'SH' => 'seint helena',
 			'SI' => 'slovenia',
 			'SJ' => 'svalbard aḍe jan mayen',
 			'SK' => 'slovakia',
 			'SL' => 'sierra leyon',
 			'SM' => 'san marino',
 			'SN' => 'senegal',
 			'SO' => 'somaliya',
 			'SR' => 'surīname',
 			'SS' => 'dkiṇ sūdan',
 			'ST' => 'sao tom aḍe prinsipe',
 			'SV' => 'el salvador',
 			'SX' => 'sint mārṭen',
 			'SY' => 'sīriya',
 			'SZ' => 'esvaṭini',
 			'SZ@alt=variant' => 'svajilanḍ',
 			'TC' => 'turks aḍe keikes dīp',
 			'TD' => 'cad',
 			'TF' => 'prēnch dakiṇ teritorī',
 			'TG' => 'ṭogo',
 			'TH' => 'tailanḍ',
 			'TJ' => 'tajākīstān',
 			'TK' => 'ṭokelau',
 			'TL' => 'ṭimor - leste',
 			'TL@alt=variant' => 'īst ṭimor',
 			'TM' => 'turkmenīstān',
 			'TN' => 'ṭunisiaa',
 			'TO' => 'ṭonga',
 			'TR' => 'turkī',
 			'TT' => 'ṭriniḍaḍ aḍe ṭobego',
 			'TV' => 'tuvala',
 			'TW' => 'taivan',
 			'TZ' => 'ṭanjaniya',
 			'UA' => 'yūkrain',
 			'UG' => 'yūganḍa',
 			'UM' => 'yu.es. aautlaing dīp',
 			'US' => 'yunaiṭeḍ stets',
 			'US@alt=short' => 'yu.es.',
 			'UY' => 'ūrugve',
 			'UZ' => 'ūjbekistaan',
 			'VA' => 'bāṭikān',
 			'VC' => 'seint vinseṇṭ aḍe grenaḍi',
 			'VE' => 'venejuela',
 			'VG' => 'briṭis vrjin dīp',
 			'VI' => 'yu.es. vrjin dīp',
 			'VN' => 'viyetnam',
 			'VU' => 'vanuaatu',
 			'WF' => 'vallis aḍe puṭuna',
 			'WS' => 'samoaa',
 			'XK' => 'kosovo',
 			'YE' => 'yemen',
 			'YT' => 'mayoṭṭ',
 			'ZA' => 'dkīṇ aaprika',
 			'ZM' => 'jambiya',
 			'ZW' => 'jimbabve',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'kelenḍr',
 			'cf' => 'ṭakã pormat',
 			'collation' => 'mila krm',
 			'currency' => 'ṭakã',
 			'hc' => 'veḍiti gila (12 vrses 24)',
 			'lb' => 'daḍi ḍikihin aaḍa',
 			'ms' => 'laṭini leka',
 			'numbers' => 'sṅkya',

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
 				'gregorian' => q{gregoriyan kelenḍr},
 				'indian' => q{barat jatiya kelenḍr},
 			},
 			'cf' => {
 				'standard' => q{mānānka takã},
 			},
 			'collation' => {
 				'ducet' => q{ḍepalt yunikoḍ baga lẽ},
 				'phonebook' => q{pnbhi baga lẽ},
 				'search' => q{samani udesya parin},
 				'standard' => q{mānānka baga lẽ},
 			},
 			'hc' => {
 				'h11' => q{12 gṇṭati pddti (0 - 11)},
 				'h12' => q{12 gṇṭati pddti (1–12)},
 				'h23' => q{24 gṇṭati pddti (0 - 23)},
 				'h24' => q{24 gṇṭati pddti (1 - 24)},
 			},
 			'ms' => {
 				'metric' => q{meṭrik pddti},
 				'uksystem' => q{samrajyti aaṭini map pddti},
 				'ussystem' => q{aamerikati map pddti},
 			},
 			'numbers' => {
 				'arab' => q{arabic-bartiya nmbr},
 				'arabext' => q{nkiaati arabic - bartiya nmbr},
 				'beng' => q{bngalī nmbr},
 				'deva' => q{devnagrī nmbr},
 				'gujr' => q{gujraṭī nmbr},
 				'guru' => q{gurumukī nmbr},
 				'knda' => q{knnaḍ nmbr},
 				'latn' => q{veḍa kuṇpu nmbr},
 				'mlym' => q{malayalam nmbr},
 				'orya' => q{oḍiya nmbr},
 				'roman' => q{roman nmbr},
 				'romanlow' => q{roman mila kase nmbr},
 				'taml' => q{hirudulu tamiḷ nmbr},
 				'tamldec' => q{tamiḷ nmbr},
 				'telu' => q{telugū nmbr},
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
			'metric' => q{meṭric},
 			'UK' => q{yuke},
 			'US' => q{yues},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'kata: {0}',
 			'script' => 'akr: {0}',
 			'region' => 'muṭha: {0}',

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
			main => qr{[aā {aa}{āā} b c dḍ eē g h iī j k lḷ m nñṅṇ oō p rṛ s tṭ uū v y]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, aḍe {1}),
				2 => q({0} aḍe {1}),
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
					'other' => '0 h',
				},
				'10000' => {
					'other' => '00 h',
				},
				'100000' => {
					'other' => '000 h',
				},
				'1000000' => {
					'other' => '0 mi',
				},
				'10000000' => {
					'other' => '00 mi',
				},
				'100000000' => {
					'other' => '000 mi',
				},
				'1000000000' => {
					'other' => '0 bi',
				},
				'10000000000' => {
					'other' => '00 bi',
				},
				'100000000000' => {
					'other' => '000 bi',
				},
				'1000000000000' => {
					'other' => '0 tri',
				},
				'10000000000000' => {
					'other' => '00 tri',
				},
				'100000000000000' => {
					'other' => '000 tri',
				},
				'standard' => {
					'default' => '#,##,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'other' => '0 hjar',
				},
				'10000' => {
					'other' => '00 hjar',
				},
				'100000' => {
					'other' => '000 hjar',
				},
				'1000000' => {
					'other' => '0 million',
				},
				'10000000' => {
					'other' => '00 million',
				},
				'100000000' => {
					'other' => '000 million',
				},
				'1000000000' => {
					'other' => '0 billion',
				},
				'10000000000' => {
					'other' => '00 billion',
				},
				'100000000000' => {
					'other' => '000 billion',
				},
				'1000000000000' => {
					'other' => '0 trillion',
				},
				'10000000000000' => {
					'other' => '00 trillion',
				},
				'100000000000000' => {
					'other' => '000 trillion',
				},
			},
			'short' => {
				'1000' => {
					'other' => '0 h',
				},
				'10000' => {
					'other' => '00 h',
				},
				'100000' => {
					'other' => '000 h',
				},
				'1000000' => {
					'other' => '0 mi',
				},
				'10000000' => {
					'other' => '00 mi',
				},
				'100000000' => {
					'other' => '000 mi',
				},
				'1000000000' => {
					'other' => '0 bi',
				},
				'10000000000' => {
					'other' => '00 bi',
				},
				'100000000000' => {
					'other' => '000 bi',
				},
				'1000000000000' => {
					'other' => '0 tri',
				},
				'10000000000000' => {
					'other' => '00 tri',
				},
				'100000000000000' => {
					'other' => '000 tri',
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
						'positive' => '¤#,##,##0.00',
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
		'BRL' => {
			display_name => {
				'currency' => q(brājil ti riel),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(cin ti yuān),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(yuro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(briṭis pāunḍ),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(bārat ti ṭnkā),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(jāpān ti yēn),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rūs ti rūbel),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(iūes ḍalār),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(puṇātī lēmbū),
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
							'pusu',
							'maha',
							'pagu',
							'hire',
							'bese',
							'jaṭṭa',
							'aasaḍi',
							'srabĩ',
							'bado',
							'dasara',
							'divi',
							'pande'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'pusu lenju',
							'maha lenju',
							'pagu lenju',
							'hire lenju',
							'bese lenju',
							'jaṭṭa lenju',
							'aasaḍi lenju',
							'srabĩ lenju',
							'bado lenju',
							'dasara lenju',
							'divi lenju',
							'pande lenju'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'pu',
							'ma',
							'pa',
							'hi',
							'be',
							'ja',
							'aa',
							'sra',
							'b',
							'da',
							'di',
							'pa'
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
						mon => 'smba',
						tue => 'manga',
						wed => 'puda',
						thu => 'laki',
						fri => 'sukru',
						sat => 'sani',
						sun => 'aadi'
					},
					short => {
						mon => 's',
						tue => 'ma',
						wed => 'pu',
						thu => 'laki',
						fri => 'su',
						sat => 'sa',
						sun => 'aa'
					},
					wide => {
						mon => 'smbara',
						tue => 'mangaḍa',
						wed => 'pudara',
						thu => 'laki vara',
						fri => 'sukru vara',
						sat => 'sani vara',
						sun => 'aadi vara'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 's',
						tue => 'ma',
						wed => 'pu',
						thu => 'la',
						fri => 'su',
						sat => 'sa',
						sun => 'aa'
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
					wide => {0 => '1sṭ kuarṭr',
						1 => '2nḍ kuarṭr',
						2 => '3rḍ kuarṭr',
						3 => '4th kuarṭr'
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
					'am' => q{am},
					'pm' => q{pm},
				},
				'narrow' => {
					'am' => q{a},
					'pm' => q{p},
				},
			},
			'stand-alone' => {
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
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'bc',
				'1' => 'ad'
			},
			wide => {
				'0' => 'krisṭ purb nki',
				'1' => 'krisṭabd'
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
			'long' => q{G d MMMM y},
			'medium' => q{G d MMM y},
			'short' => q{G d/M/y},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			GyMMMEd => q{G E, d MMM y},
			GyMMMd => q{G d MMM y},
			GyMd => q{GGGGG d/M/y},
			M => q{M},
			MEd => q{E, d/M},
			MMM => q{MMM},
			MMMEd => q{E, d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			yyyyM => q{GGGGG M/y},
			yyyyMEd => q{G E, d/M/y},
			yyyyMMM => q{G MMM y},
			yyyyMMMEd => q{G E, d MMM y},
			yyyyMMMd => q{G d MMM y},
			yyyyMd => q{G d/M/y},
			yyyyQQQ => q{QQQ G y},
			yyyyQQQQ => q{QQQQ G y},
		},
		'gregorian' => {
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM G y},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{GGGGG d/M/y},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMW => q{MMMM 'tã' 'vara' W},
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
			yw => q{Y 'tã' 'vara' w},
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
				h => q{B h–h},
			},
			Bhm => {
				B => q{B h:mm – B h:mm},
				h => q{B h:mm–h:mm},
				m => q{B h:mm–h:mm},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y G},
				d => q{E, d/M/y – E, d/M/y G},
				y => q{E, d/M/y – E, d/M/y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
			},
		},
		'gregorian' => {
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
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
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} belā),
		regionFormat => q({0} ḍayliṭ belā),
		regionFormat => q({0} mānānka belā),
		'Afghanistan' => {
			long => {
				'standard' => q#aapganistan belā#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#ecra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#aḍis ababa#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#aljīyrs#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#asmara#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#bangui#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#banjul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#bissau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#blanṭaer#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#brajavill#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#bujumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#kairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#kasablanka#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#seuṭa#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#konakrī#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#ḍkar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#dar es salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#jibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#duala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#el aaiyun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#prīṭaun#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#gaboron#,
		},
		'Africa/Harare' => {
			exemplarCity => q#hrare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#johannesburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#kmpala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#karṭoum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#kinsasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#lagos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#librevill#,
		},
		'Africa/Lome' => {
			exemplarCity => q#lom#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#luanḍa#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#lubumbasi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#lusaka#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#malabo#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#mapuṭu#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#maseru#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#mbabane#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#mogaḍisu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#njamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#niyame#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#nueksa#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#vagdugu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#porṭo-ṇovo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#sao ṭom#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#ṭunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#vindhuk#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#madini aaprika belā#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#veḍa hpu aaprika belā#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#dkiṇ aaprika belā#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#veḍa kuṇpu aaprika karã belā#,
				'generic' => q#veḍakuṇpu aaprika belā#,
				'standard' => q#veḍa kuṇpu aaprika mananka belā#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#alaska ḍelaaiṭ belā#,
				'generic' => q#alaska belā#,
				'standard' => q#alaska mananka belā#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#āmajon karã masa belā#,
				'generic' => q#āmajon belā#,
				'standard' => q#āmajon mananka belā#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#aḍak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#ankoraj#,
		},
		'America/Anguilla' => {
			exemplarCity => q#enguilla#,
		},
		'America/Antigua' => {
			exemplarCity => q#enṭigua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#aragvaina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#la rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#riyo gallegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#salṭa#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#san huan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#san luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#ṭukūmn#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#usvaiya#,
		},
		'America/Aruba' => {
			exemplarCity => q#aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#esunsion#,
		},
		'America/Bahia' => {
			exemplarCity => q#bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#baia banḍeras#,
		},
		'America/Barbados' => {
			exemplarCity => q#barbaḍos#,
		},
		'America/Belem' => {
			exemplarCity => q#belem#,
		},
		'America/Belize' => {
			exemplarCity => q#belij#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#blank-sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#boa vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#bogoṭa#,
		},
		'America/Boise' => {
			exemplarCity => q#boisī#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#buenous aires#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#kembrij be#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#kampo granḍe#,
		},
		'America/Cancun' => {
			exemplarCity => q#kankun#,
		},
		'America/Caracas' => {
			exemplarCity => q#karakas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#katamarka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#keyen#,
		},
		'America/Cayman' => {
			exemplarCity => q#keiman#,
		},
		'America/Chicago' => {
			exemplarCity => q#cikago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#chihuahua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#eṭikoken#,
		},
		'America/Cordoba' => {
			exemplarCity => q#korḍaba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#kosṭa rika#,
		},
		'America/Creston' => {
			exemplarCity => q#kresṭon#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#kuaaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#kyuraso#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#ḍanmarksavn#,
		},
		'America/Dawson' => {
			exemplarCity => q#ḍaosn#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#ḍaoson krīk#,
		},
		'America/Denver' => {
			exemplarCity => q#ḍenver#,
		},
		'America/Detroit' => {
			exemplarCity => q#ḍeṭroiṭ#,
		},
		'America/Dominica' => {
			exemplarCity => q#ḍominika#,
		},
		'America/Edmonton' => {
			exemplarCity => q#eḍmonṭon#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#eirunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#el salvaḍor#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#phort nelsn#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#portaleja#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#glas bay#,
		},
		'America/Godthab' => {
			exemplarCity => q#nūk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#goos be#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#granḍ ṭurk#,
		},
		'America/Grenada' => {
			exemplarCity => q#grenaḍa#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#guaḍeloupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#guatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#guajakil#,
		},
		'America/Guyana' => {
			exemplarCity => q#guyana#,
		},
		'America/Halifax' => {
			exemplarCity => q#helipaks#,
		},
		'America/Havana' => {
			exemplarCity => q#havana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#ermosijo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#noks, inḍiyana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#marengo, inḍiyana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#piṭtrsberg, inḍiyana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#ṭell sity, inḍiyana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#vivi, inḍiyana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#vincens, inḍiyana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#vinamak, inḍiyana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#inḍianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#inūvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#ikaluiṭ#,
		},
		'America/Jamaica' => {
			exemplarCity => q#jamaika#,
		},
		'America/Jujuy' => {
			exemplarCity => q#huhue#,
		},
		'America/Juneau' => {
			exemplarCity => q#junov#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#monṭisello, kenṭukī#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#krelenḍeik#,
		},
		'America/La_Paz' => {
			exemplarCity => q#la paj#,
		},
		'America/Lima' => {
			exemplarCity => q#lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#los anjeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#louiville#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#lover princ’s kuvaṭar#,
		},
		'America/Maceio' => {
			exemplarCity => q#masīo#,
		},
		'America/Managua' => {
			exemplarCity => q#managua#,
		},
		'America/Manaus' => {
			exemplarCity => q#manaus#,
		},
		'America/Marigot' => {
			exemplarCity => q#marigoṭ#,
		},
		'America/Martinique' => {
			exemplarCity => q#marṭinik#,
		},
		'America/Matamoros' => {
			exemplarCity => q#maṭamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#masaṭlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#menḍoja#,
		},
		'America/Menominee' => {
			exemplarCity => q#menominī#,
		},
		'America/Merida' => {
			exemplarCity => q#meriḍa#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#meṭlakaṭla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#meksico siṭy#,
		},
		'America/Miquelon' => {
			exemplarCity => q#mikvilõ#,
		},
		'America/Moncton' => {
			exemplarCity => q#monkṭon#,
		},
		'America/Monterrey' => {
			exemplarCity => q#monṭerre#,
		},
		'America/Montevideo' => {
			exemplarCity => q#monṭevidio#,
		},
		'America/Montserrat' => {
			exemplarCity => q#monṭserreṭ#,
		},
		'America/Nassau' => {
			exemplarCity => q#nasau#,
		},
		'America/New_York' => {
			exemplarCity => q#niyu york#,
		},
		'America/Nome' => {
			exemplarCity => q#nom#,
		},
		'America/Noronha' => {
			exemplarCity => q#noronha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#biyula, uttar ḍakoṭa#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#maḍinī uttar ḍakoṭa#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#neu salem, uttar ḍakoṭa#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#panama#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#paramaribo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#piniks#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#port-au-prinse#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#porṭ ap spain#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#porṭp velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#puerto riko#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#puṇṭa erenas#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#rankin inledṭ#,
		},
		'America/Recife' => {
			exemplarCity => q#resipi#,
		},
		'America/Regina' => {
			exemplarCity => q#rejina#,
		},
		'America/Resolute' => {
			exemplarCity => q#rejalyuṭ#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#rio branko#,
		},
		'America/Santarem' => {
			exemplarCity => q#satari#,
		},
		'America/Santiago' => {
			exemplarCity => q#sanṭiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#sento ḍomingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#sao paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#iṭokoṭormiṭ#,
		},
		'America/Sitka' => {
			exemplarCity => q#sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#senṭ bartelemi#,
		},
		'America/St_Johns' => {
			exemplarCity => q#senṭ jons#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#sent kiṭṭs#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#sent lusia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#senṭ tomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#senṭ vinsenṭ#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#svipṭ kurrenṭ#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#tegu#,
		},
		'America/Thule' => {
			exemplarCity => q#tule#,
		},
		'America/Tijuana' => {
			exemplarCity => q#tihvana#,
		},
		'America/Toronto' => {
			exemplarCity => q#ṭoronṭo#,
		},
		'America/Tortola' => {
			exemplarCity => q#ṭorṭola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#vankūver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#vhaiṭhors#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#vinnipeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#yakuṭaṭ#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#madinī ḍelaaiṭ belā#,
				'generic' => q#madinī belā#,
				'standard' => q#madinī mananka belā#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#veḍahapu ḍelaaiṭ belā#,
				'generic' => q#veḍahapu belā#,
				'standard' => q#veḍahapu mananka belā#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#harka ḍelaaiṭ belā#,
				'generic' => q#harka belā#,
				'standard' => q#harka mananka belā#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#pesipik ḍelaaiṭ belā#,
				'generic' => q#pesipik belā#,
				'standard' => q#pesipik mananka belā#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#kesee#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#ḍevis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#ḍyumont de urvill#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#mekvari#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#mavson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#mek murḍo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#rotera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#syova#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#ṭroll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#vosṭok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#epiā delāit belā#,
				'generic' => q#epiā belā#,
				'standard' => q#epiā mānānka belā#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#ārbiāti delāit belā#,
				'generic' => q#ārbiāti belā#,
				'standard' => q#ārbiāti mānānka belā#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#lngyarbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#ārjenṭinā kār~ā belā belā#,
				'generic' => q#ārjenṭinā belā#,
				'standard' => q#ārjenṭinā mānānka belā#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#weḍākuṇupu ārjenṭinā kār~ā belā#,
				'generic' => q#weḍākuṇupu ārjenṭinā belā#,
				'standard' => q#weḍākuṇupu ārjenṭinā mānānka belā#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#ārmeniā kār~ā belā#,
				'generic' => q#ārmeniā belā#,
				'standard' => q#ārmeniā mānānka belā#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#eḍen#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#almaṭy#,
		},
		'Asia/Amman' => {
			exemplarCity => q#amman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#anaḍir#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#aaktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#asgabaṭ#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#atarau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#bahrain#,
		},
		'Asia/Baku' => {
			exemplarCity => q#baku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#beirut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#biskek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#cita#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#ḍamaskus#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#ḍaka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#ḍili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#dubai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#dusambe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#pamagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#gaja#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#hong kong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#irkuṭsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#jerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#kamcaṭka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#karacī#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#kaṭmanḍu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#kandiga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#krasneyarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#kuala lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#kucing#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#kuvait#,
		},
		'Asia/Macau' => {
			exemplarCity => q#mkao#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#megaḍan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#makasar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#manīla#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#maskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#nikosiya#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#nevokujneṭsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#novosibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#omsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#oral#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#pnom penh#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#ponṭianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#pyongyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#kosṭane#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#kijuorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#yangon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#riyad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#ho ci minh siti#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#sahalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#seol#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#sengai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#singapor#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#sreḍnekolymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#taipei#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#taskenṭ#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#tehran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#timphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#ṭokyo#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#ṭomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#ulanbaṭar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#urumci#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#yust-nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#vienṭiaan#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#vlaḍivosṭok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#yakuṭsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#yikaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#yerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#āṭlānṭik delāiṭ belā#,
				'generic' => q#āṭlānṭik belā#,
				'standard' => q#āṭlānṭik mānānka belā#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#ajores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#bermūda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#keneri#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#kep verḍe#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#pero#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#maḍiera#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#reykyavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#dkiṇ jorjia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#sent helena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#sṭanli#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#aedileid#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#brisbane#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#broken hill#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#ḍarvin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#yukla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#hobarṭ#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#linḍerman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#lorḍ hove#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#melborne#,
		},
		'Australia/Perth' => {
			exemplarCity => q#pert#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#syḍnī#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#āstreliāti mādinā delāiṭ belā#,
				'generic' => q#mādinā āstreliā belā#,
				'standard' => q#āstreliāti mādinā mānānka belā#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#āstreliāti mādinā weḍākuṇupu delāiṭ belā#,
				'generic' => q#āstreliāti mādinā weḍākuṇupu belā#,
				'standard' => q#āstreliāti mādinā weḍākuṇupu mānānka belā#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#āstreliāti weḍāhapū delāiti belā#,
				'generic' => q#weḍāhapu āstraliā belā#,
				'standard' => q#āstreliāti weḍāhapū mānānka belā#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#āstreliāti weḍākuṇupū delāiṭ belā#,
				'generic' => q#weḍākuṇupū āstreliā belā#,
				'standard' => q#āstreliāti weḍākuṇupū mānānka belā#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#ājerbāijān kār~ā belā#,
				'generic' => q#ājerbāijān belā#,
				'standard' => q#ājerbāijān mānānka belā#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#ajores kār~ā belā#,
				'generic' => q#ajores belā#,
				'standard' => q#ajores mānānka belā#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#bānglādes kār~ā belā#,
				'generic' => q#bānglādes belā#,
				'standard' => q#bānglādes mānānka belā#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#butān belā#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#bolwiā belā#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#brājiliā kār~ā belā#,
				'generic' => q#brājiliā belā#,
				'standard' => q#brājiliā mānānka belā#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#bruneti dārusālām belā#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#kep bḍ kār~ā belā#,
				'generic' => q#kep bḍ belā#,
				'standard' => q#kep bḍ mānānka belā#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#cāmor mānānka belā#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#cyātām delāit belā#,
				'generic' => q#cyātām belā#,
				'standard' => q#cyātām mānānka belā#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#cili kār~ā belā#,
				'generic' => q#cini belā#,
				'standard' => q#cili mānānka belā#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#cin delāiṭ belā#,
				'generic' => q#cin belā#,
				'standard' => q#cin mānānka belā#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#krismās dīp belā#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#kokos dīp belā#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#kolombiā kār~ā belā#,
				'generic' => q#kolombiā belā#,
				'standard' => q#kolombiā mānānka belā#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#kuk dīp ādā kār~ā belā#,
				'generic' => q#kuk dīp belā#,
				'standard' => q#kuk dīp mānānka belā#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#kubā delāiṭ belā#,
				'generic' => q#kubā belā#,
				'standard' => q#kubā mānānka belā#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#debis belā#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#ḍumonṭ ḍi arwilē belā#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#weḍāhapu timor belā#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#isṭr dīp kār~ā belā#,
				'generic' => q#isṭr dīp belā#,
				'standard' => q#isṭr dīp mānānka belā#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#iquāḍor belā#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#smani jaga pruti belā#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#puṇaã ti gaḍa#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#amsṭerḍam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#aaṇḍora#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#aasṭrahan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#etens#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#belgraḍe#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#braṭislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#brussels#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#bukarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#buḍapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#kisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#kopenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#ḍblin#,
			long => {
				'daylight' => q#aairis manaka belā#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#jibralṭar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#gernsi#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#aail ap man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#jersi#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#kaliningraḍ#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#kiyv#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#lisbon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#lyublyana#,
		},
		'Europe/London' => {
			exemplarCity => q#lnḍn#,
			long => {
				'daylight' => q#briṭis karã masa belā#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#lksembrg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#meḍriḍ#,
		},
		'Europe/Malta' => {
			exemplarCity => q#malṭa#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#marieham#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#mosko#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#paris#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#pḍgoritsa#,
		},
		'Europe/Prague' => {
			exemplarCity => q#prag#,
		},
		'Europe/Riga' => {
			exemplarCity => q#riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#rom#,
		},
		'Europe/Samara' => {
			exemplarCity => q#samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#san marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#sarajevo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#saraṭov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#simperopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#skopi#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#sopiya#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#sṭokhom#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#talin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#ṭirane#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#ulyanovsk#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#vaḍuj#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#vaṭikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#vienna#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#volgograḍ#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#varsa#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#tegusigalpa#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#juric#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#mādinā yuropiāti kār~ā belā#,
				'generic' => q#mādinā yuropiāti belā#,
				'standard' => q#mādinā yuropiāti mānānka belā#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#weḍāhpu yuropiāti kār~ā belā#,
				'generic' => q#weḍāhpu yuropiāti belā#,
				'standard' => q#weḍāhpu yuropiāti mānānka belā#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#ar weḍāhpu yuropati belā#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#weḍākūṇūpu yuropiāti kār~ā belā#,
				'generic' => q#weḍākūṇūpu yuropiāti belā#,
				'standard' => q#weḍākūṇūpu yuropiāti mānānka belā#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#paklyānḍ dīpati kār~ā belā#,
				'generic' => q#paklyānḍ dīpati belā#,
				'standard' => q#paklyānḍ dīpati mānānka belā#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#piji kār~ā belā#,
				'generic' => q#piji belā#,
				'standard' => q#piji mānānka belā#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#prench guyān belā#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#prenc dakiṇ aḍe aanṭārkṭik belā#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#grinwic mīn belā#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#gālāpogs belā#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#gambiyr belā#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#jarjiā kār~ā belā#,
				'generic' => q#jarjīā belā#,
				'standard' => q#jarjiā mānānka belā#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#gīlbrṭ dīp belā#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#weḍāhpu grinlānd kār~ā belā#,
				'generic' => q#weḍāhpu grinlānd belā#,
				'standard' => q#weḍāhpu grinlānd mānānka belā#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#weḍakūṇūp grinlānḍ kār~ā belā#,
				'generic' => q#weḍakūṇūp grinlānḍ belā#,
				'standard' => q#weḍakūṇūp grinlānḍ mānānka belā#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#galp mānānka belā#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#guyān belā#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#hāwāe- aalūsān ḍelāiṭ belā#,
				'generic' => q#hāwāe- aalūsān belā#,
				'standard' => q#hāwāe- aalūsān mānānka belā#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#hang kang kār~ā belā#,
				'generic' => q#hang kang belā#,
				'standard' => q#hang kang mānānka belā#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#hwoḍ kār~ā belā#,
				'generic' => q#hwoḍ belā#,
				'standard' => q#hwoḍ mānānka belā#,
			},
		},
		'India' => {
			long => {
				'standard' => q#bārat mānānka belā#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#ṭananariv#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#krisṭmas#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#kokos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#komoro#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#maldives#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#maurisius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#mayoṭ#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#reunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#bārat kājā belā#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#inḍocinā belā#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#mādini inḍnesiā belā#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#weḍāhpu inḍnesiā belā#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#weḍākūṇpū inḍnesiā belā#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#irān ḍelāiṭ belā#,
				'generic' => q#irān belā#,
				'standard' => q#irān mānānka belā#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#īrkustak kār~ā belā#,
				'generic' => q#īrkustak belā#,
				'standard' => q#īrkustak mānānka belā#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#ijarāīl ḍelāiṭ belā#,
				'generic' => q#ijarāīl belā#,
				'standard' => q#ijarāīl mānānka belā#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#jāpān ḍelāiṭ belā#,
				'generic' => q#jāpān belā#,
				'standard' => q#jāpān mānānka belā#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#kājākstān belā#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#weḍāhapu kājākstān belā#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#weḍākūṇpū kājākstān belā#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#koriān ḍelāiṭ belā#,
				'generic' => q#koriān belā#,
				'standard' => q#koriān mānānka belā#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#kasrāē belā#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#krāsnōrska kār~ā belā#,
				'generic' => q#krāsnōrska belā#,
				'standard' => q#krāsnōrska mānānka belā#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#kirgijstān belā#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#lāin dīp belā#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#laṛ hawe ḍelāiṭ belā#,
				'generic' => q#laṛ hawe belā#,
				'standard' => q#laṛ hawe mānānka belā#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#māgādan ḍelāit belā#,
				'generic' => q#māgādan belā#,
				'standard' => q#māgādan mānānka belā#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#malesiā belā#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#māldīp belā#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#mārksas belā#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#mārsāl dīpa belā#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#marīsas kār~ā belā#,
				'generic' => q#marīsas belā#,
				'standard' => q#marīsasmānānka belā#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#māwosn belā#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#meksikān pesipic ḍelāiṭ belā#,
				'generic' => q#meksikān pesipic belā#,
				'standard' => q#meksikān pesipic mānānka belā#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#ūlānbator kār~ā belā#,
				'generic' => q#ūlānbator belā#,
				'standard' => q#ūlānbator mānānka belā#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#mosko kār~ā belā#,
				'generic' => q#mosko belā#,
				'standard' => q#mosko mānānka belā#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#miñyāmār belā#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#nāurū belā#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#nepāl belā#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#niū keleḍoniā kār~ā belā#,
				'generic' => q#niū keleḍoniā belā#,
				'standard' => q#niū keleḍoniā mānānka belā#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#niūjilānḍ ḍelāiṭ belā#,
				'generic' => q#niūjilānḍ belā#,
				'standard' => q#niūjilānḍ mānānka belā#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#niūpaunḍlyānḍ ḍelāiṭ belā#,
				'generic' => q#niūpaunḍlyānḍ belā#,
				'standard' => q#niūpaunḍlyānḍ mānānka belā#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#niū belā#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#norpok dīp ḍelāiṭ belā#,
				'generic' => q#norpok dīp belā#,
				'standard' => q#norpok dīp mānānka belā#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#parn~ḍo ḍe norohā~ kār~ā belā#,
				'generic' => q#parn~ḍo ḍe norohā~ belā#,
				'standard' => q#parn~ḍo ḍe norohā~ mānānka belā#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#nawosibisrk kār~ā belā#,
				'generic' => q#nawosibisrk belā#,
				'standard' => q#nawosibisrk mānānka belā#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#amska kār~ā belā#,
				'generic' => q#amska belā#,
				'standard' => q#amska mānānka belā#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#apia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#āklanḍ#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#bouganvill#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#ceṭam#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#īster#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#ipeṭe#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#pakaopo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#piji#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#punaputi#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#galapagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#gambier#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#guaḍalkenal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#guam#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#kanṭon#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#kisrae#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#kvajalein#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#majuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#markisas#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#miḍvay#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#nauru#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#niue#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#norpok#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#numie#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#pango pango#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#piṭkern#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#ponpei#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#porṭ moresbi#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#rarotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#saipan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#ṭahiṭi#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#tarava#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#ṭongaṭapu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#cūk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#vek#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#vallis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#pākistān kār~ā belā#,
				'generic' => q#pākistān belā#,
				'standard' => q#pākistān mānānka belā#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#pālāu belā#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#pāpuā niu gunīā belā#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#pārāguyē kār~ā belā#,
				'generic' => q#pārāguyē belā#,
				'standard' => q#pārāguyē mānānka belā#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#peru kār~ā belā#,
				'generic' => q#peru belā#,
				'standard' => q#peru mānānka belā#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#pilipin kār~ā belā#,
				'generic' => q#pilipin belā#,
				'standard' => q#pilipin mānānka belā#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#piniksa dīpati belā#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#sēnṭ pierē aḍē mekwēlān ḍelāiṭ belā#,
				'generic' => q#sēnṭ pierē aḍē mekwēlān belā#,
				'standard' => q#sēnṭ pierē aḍē mekwēlān mānānka belā#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#piṭkēran belā#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#ponāpe belā#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#pyongayāng belā#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#rīūnīan belā#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#rotērā belā#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#sakālin kār~ā belā#,
				'generic' => q#sakālin belā#,
				'standard' => q#sakālin mānānka belā#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#saāmoa ḍelāiṭ#,
				'generic' => q#saāmoa belā#,
				'standard' => q#saāmoa mānānka belā#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#sēsels belā#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#singāpur mānānka belā#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#soloman dīpati belā#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#dkīṇa jarjīā belā#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#surīnām belā#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#sawā belā#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#tāhiti belā#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#tāipē ḍelāiṭ#,
				'generic' => q#tāipē belā#,
				'standard' => q#tāipē mānānka belā#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#tājikistān belā#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#ṭokelāu belā#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#ṭangā kār~ā belā#,
				'generic' => q#ṭangā belā#,
				'standard' => q#ṭangā mānānka belā#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#cuk belā#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#turkmenistān kār~ā belā#,
				'generic' => q#turkmenistān belā#,
				'standard' => q#turkmenistān manaka belā#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#tuwalū belā#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#urguwē kār~ā belā#,
				'generic' => q#urguwē belā#,
				'standard' => q#urguwē manaka belā#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#uzwēkistān kārã belā#,
				'generic' => q#uzwēkistān belā#,
				'standard' => q#uzwēkistān mānānka belā#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#wanuātū kār~ā belā#,
				'generic' => q#wanuātū belā#,
				'standard' => q#wanuātū mānānka belā#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#wenēzuelā belā#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#wlādiwostak kār~ā belā#,
				'generic' => q#wlādiwostak belā#,
				'standard' => q#wlādiwostak mānānka belā#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#wālgogrāḍ kār~ā belā#,
				'generic' => q#wālgogrāḍ belā#,
				'standard' => q#wālgogrāḍ mānānka belā#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#wostak belā#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#waka dīpa belā#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#walis aḍē puṭunā#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#yakustuk kār~ā belā#,
				'generic' => q#yakustuk belā#,
				'standard' => q#yakustuk mānānka belā#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#yakaterinbarg kār~ā belā#,
				'generic' => q#yakaterinbarg belā#,
				'standard' => q#yakaterinbarg mānānka belā#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
