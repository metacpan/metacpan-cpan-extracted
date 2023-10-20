=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Shi::Latn - Package for language Tachelhit

=cut

package Locale::CLDR::Locales::Shi::Latn;
# This file auto generated from Data\common\main\shi_Latn.xml
#	on Fri 13 Oct  9:37:06 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Shi');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'ak' => 'Takant',
 				'am' => 'Tamharit',
 				'ar' => 'Taɛrabt',
 				'be' => 'Tabilarust',
 				'bg' => 'Tablɣarit',
 				'bn' => 'Tabnɣalit',
 				'cs' => 'Tatcikit',
 				'de' => 'Talimant',
 				'el' => 'Tagrigit',
 				'en' => 'Tanglizt',
 				'es' => 'Tasbnyulit',
 				'fa' => 'Tafursit',
 				'fr' => 'Tafransist',
 				'ha' => 'Tahawsat',
 				'hi' => 'Tahindit',
 				'hu' => 'Tahnɣarit',
 				'id' => 'Tandunisit',
 				'ig' => 'Tigbut',
 				'it' => 'Taṭalyant',
 				'ja' => 'Tajabbunit',
 				'jv' => 'Tajavanit',
 				'km' => 'Taxmirt',
 				'ko' => 'Takurit',
 				'ms' => 'Tamalawit',
 				'my' => 'Tabirmanit',
 				'ne' => 'Tanibalit',
 				'nl' => 'Tahulandit',
 				'pa' => 'Tabnjabit',
 				'pl' => 'Tabulunit',
 				'pt' => 'Tabṛṭqizt',
 				'ro' => 'Tarumanit',
 				'ru' => 'Tarusit',
 				'rw' => 'Taruwandit',
 				'shi' => 'Tashelḥiyt',
 				'so' => 'Tasumalit',
 				'sv' => 'Taswidit',
 				'ta' => 'Tatamilt',
 				'th' => 'Tataylandit',
 				'tr' => 'Taturkit',
 				'uk' => 'Tukranit',
 				'ur' => 'Turdut',
 				'vi' => 'Tafitnamit',
 				'yo' => 'Tayrubat',
 				'zh' => 'Tacinwit',
 				'zu' => 'Tazulut',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'AD' => 'andura',
 			'AE' => 'limarat',
 			'AF' => 'afɣanistan',
 			'AG' => 'antiga d brbuda',
 			'AI' => 'angila',
 			'AL' => 'albanya',
 			'AM' => 'arminya',
 			'AO' => 'angula',
 			'AR' => 'arjantin',
 			'AS' => 'samwa tamirikanit',
 			'AT' => 'nnmsa',
 			'AU' => 'ustralya',
 			'AW' => 'aruba',
 			'AZ' => 'adrabijan',
 			'BA' => 'busna d hirsik',
 			'BB' => 'barbad',
 			'BD' => 'bangladic',
 			'BE' => 'bljika',
 			'BF' => 'burkina fasu',
 			'BG' => 'blɣara',
 			'BH' => 'bḥrayn',
 			'BI' => 'burundi',
 			'BJ' => 'binin',
 			'BM' => 'brmuda',
 			'BN' => 'bruni',
 			'BO' => 'bulibya',
 			'BR' => 'brazil',
 			'BS' => 'bahamas',
 			'BT' => 'bhutan',
 			'BW' => 'butswana',
 			'BY' => 'bilarusya',
 			'BZ' => 'biliz',
 			'CA' => 'kanada',
 			'CD' => 'tagdudant tadimukratit n Kongo',
 			'CF' => 'tagdudant tanammast n ifriqya',
 			'CG' => 'kungu',
 			'CH' => 'swisra',
 			'CI' => 'kut difwar',
 			'CK' => 'tigzirin n kuk',
 			'CL' => 'ccili',
 			'CM' => 'kamirun',
 			'CN' => 'ccinwa',
 			'CO' => 'culumbya',
 			'CR' => 'kusta rika',
 			'CU' => 'kuba',
 			'CV' => 'tigzirin n kabbirdi',
 			'CY' => 'qubrus',
 			'CZ' => 'tagdudant tatcikit',
 			'DE' => 'almanya',
 			'DJ' => 'djibuti',
 			'DK' => 'danmark',
 			'DM' => 'duminik',
 			'DO' => 'tagdudant taduminikt',
 			'DZ' => 'dzayr',
 			'EC' => 'ikwadur',
 			'EE' => 'istunya',
 			'EG' => 'miṣṛ',
 			'ER' => 'iritirya',
 			'ES' => 'sbanya',
 			'ET' => 'ityubya',
 			'FI' => 'fillanda',
 			'FJ' => 'fidji',
 			'FK' => 'tigzirin n malawi',
 			'FM' => 'mikrunizya',
 			'FR' => 'fransa',
 			'GA' => 'gabun',
 			'GB' => 'tagldit imunn',
 			'GD' => 'ɣrnaṭa',
 			'GE' => 'jurjya',
 			'GF' => 'gwiyan tafransist',
 			'GH' => 'ɣana',
 			'GI' => 'adrar n ṭaṛiq',
 			'GL' => 'griland',
 			'GM' => 'gambya',
 			'GN' => 'ɣinya',
 			'GP' => 'gwadalub',
 			'GQ' => 'ɣinya n ikwadur',
 			'GR' => 'lyunan',
 			'GT' => 'gwatimala',
 			'GU' => 'gwam',
 			'GW' => 'ɣinya bisaw',
 			'GY' => 'gwiyana',
 			'HN' => 'hunduras',
 			'HR' => 'krwatya',
 			'HT' => 'hayti',
 			'HU' => 'hnɣarya',
 			'ID' => 'andunisya',
 			'IE' => 'irlanda',
 			'IL' => 'israyil',
 			'IN' => 'lhind',
 			'IO' => 'tamnaḍt tanglizit n ugaru ahindi',
 			'IQ' => 'lɛiraq',
 			'IR' => 'iran',
 			'IS' => 'island',
 			'IT' => 'iṭalya',
 			'JM' => 'jamayka',
 			'JO' => 'lurdun',
 			'JP' => 'lyaban',
 			'KE' => 'kinya',
 			'KG' => 'kirɣizistan',
 			'KH' => 'kambudya',
 			'KI' => 'kiribati',
 			'KM' => 'cumur',
 			'KN' => 'sankris d nifis',
 			'KP' => 'kurya n iẓẓlmḍ',
 			'KR' => 'kurya n iffus',
 			'KW' => 'lkwit',
 			'KY' => 'tigzirin n kayman',
 			'KZ' => 'kazaxstan',
 			'LA' => 'laws',
 			'LB' => 'lubnan',
 			'LC' => 'santlusi',
 			'LI' => 'likinctayn',
 			'LK' => 'srilanka',
 			'LR' => 'libirya',
 			'LS' => 'liṣuṭu',
 			'LT' => 'litwanya',
 			'LU' => 'luksanburg',
 			'LV' => 'latfya',
 			'LY' => 'libya',
 			'MA' => 'lmɣrib',
 			'MC' => 'munaku',
 			'MD' => 'muldufya',
 			'MG' => 'madaɣacqar',
 			'MH' => 'tigzirin n marcal',
 			'MK' => 'masidunya',
 			'ML' => 'mali',
 			'MM' => 'myanmar',
 			'MN' => 'mnɣulya',
 			'MP' => 'tigzirin n maryan n iẓẓlmḍ',
 			'MQ' => 'martinik',
 			'MR' => 'muṛiṭanya',
 			'MS' => 'munsirat',
 			'MT' => 'malṭa',
 			'MU' => 'muris',
 			'MV' => 'maldif',
 			'MW' => 'malawi',
 			'MX' => 'miksik',
 			'MY' => 'malizya',
 			'MZ' => 'muznbiq',
 			'NA' => 'namibya',
 			'NC' => 'kalidunya tamaynut',
 			'NE' => 'nnijir',
 			'NF' => 'tigzirin n nurfulk',
 			'NG' => 'nijirya',
 			'NI' => 'nikaragwa',
 			'NL' => 'hulanda',
 			'NO' => 'nnrwij',
 			'NP' => 'nibal',
 			'NR' => 'nawru',
 			'NU' => 'niwi',
 			'NZ' => 'nyuzilanda',
 			'OM' => 'ɛuman',
 			'PA' => 'banama',
 			'PE' => 'biru',
 			'PF' => 'bulinizya tafransist',
 			'PG' => 'babwa ɣinya tamaynut',
 			'PH' => 'filibbin',
 			'PK' => 'bakistan',
 			'PL' => 'bulunya',
 			'PM' => 'sanbyir d miklun',
 			'PN' => 'bitkayrn',
 			'PR' => 'burtu riku',
 			'PS' => 'agmmaḍ n tagut d ɣzza',
 			'PT' => 'bṛṭqiz',
 			'PW' => 'balaw',
 			'PY' => 'baragway',
 			'QA' => 'qatar',
 			'RE' => 'riyunyun',
 			'RO' => 'rumanya',
 			'RU' => 'rusya',
 			'RW' => 'rwanda',
 			'SA' => 'ssaɛudiya',
 			'SB' => 'tigzirin n saluman',
 			'SC' => 'ssicil',
 			'SD' => 'ssudan',
 			'SE' => 'sswid',
 			'SG' => 'snɣafura',
 			'SH' => 'santilin',
 			'SI' => 'slufinya',
 			'SK' => 'slufakya',
 			'SL' => 'ssiralyun',
 			'SM' => 'sanmarinu',
 			'SN' => 'ssinigal',
 			'SO' => 'ṣṣumal',
 			'SR' => 'surinam',
 			'ST' => 'sawṭumi d bransib',
 			'SV' => 'salfadur',
 			'SY' => 'surya',
 			'SZ' => 'swazilanda',
 			'TC' => 'tigzirin n turkya d kayk',
 			'TD' => 'tcad',
 			'TG' => 'ṭugu',
 			'TH' => 'ṭayland',
 			'TJ' => 'tadjakistan',
 			'TK' => 'ṭuklaw',
 			'TL' => 'timur n lqblt',
 			'TM' => 'turkmanstan',
 			'TN' => 'tuns',
 			'TO' => 'ṭunga',
 			'TR' => 'turkya',
 			'TT' => 'trinidad d ṭubagu',
 			'TV' => 'tufalu',
 			'TW' => 'ṭaywan',
 			'TZ' => 'ṭanẓanya',
 			'UA' => 'ukranya',
 			'UG' => 'uɣanda',
 			'US' => 'iwunak munnin n mirikan',
 			'UY' => 'urugway',
 			'UZ' => 'uzbakistan',
 			'VA' => 'awank n fatikan',
 			'VC' => 'sanfansan d grinadin',
 			'VE' => 'finzwila',
 			'VG' => 'tigzirin timgad n nngliz',
 			'VI' => 'tigzirin timgad n iwunak munnin',
 			'VN' => 'fitnam',
 			'VU' => 'fanwaṭu',
 			'WF' => 'walis d futuna',
 			'WS' => 'samwa',
 			'YE' => 'yaman',
 			'YT' => 'mayuṭ',
 			'ZA' => 'afriqya n iffus',
 			'ZM' => 'zambya',
 			'ZW' => 'zimbabwi',

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
			auxiliary => qr{[o p v]},
			index => ['A', 'B', 'C', 'D', 'Ḍ', 'E', 'Ɛ', 'F', 'G', '{Gʷ}', 'Ɣ', 'H', 'Ḥ', 'I', 'J', 'K', '{Kʷ}', 'L', 'M', 'N', 'Q', 'R', 'Ṛ', 'S', 'Ṣ', 'T', 'Ṭ', 'U', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d ḍ e ɛ f g {gʷ} ɣ h ḥ i j k {kʷ} l m n q r ṛ s ṣ t ṭ u w x y z]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'Ḍ', 'E', 'Ɛ', 'F', 'G', '{Gʷ}', 'Ɣ', 'H', 'Ḥ', 'I', 'J', 'K', '{Kʷ}', 'L', 'M', 'N', 'Q', 'R', 'Ṛ', 'S', 'Ṣ', 'T', 'Ṭ', 'U', 'W', 'X', 'Y', 'Z'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{«},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{„},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:yyih|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:uhu|u|no|n)$' }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
		},
	} }
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '#,##0.00¤',
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
				'currency' => q(adrim n limarat),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza n angula),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(adular n ustralya),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(adinar n bḥrayn),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(frank n burundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(abula n butswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(adular n kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(frank n kungu),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(afrank n swisra),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(ayan n ccinwa),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(iskudu n kabbirdi),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(frank n djibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(adinar n dzayr),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(ajnih n miṣṛ),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nafka n iritirya),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(bir n ityubya),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(uru),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(ajnih astrlini n nngliz),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(sidi n ɣana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi n gambya),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(frank n ɣinya),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(arubi n lhind),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(ayan n lyaban),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(acilin n kinya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(frank n qumuṛ),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(adular n libirya),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(luti n liṣuṭu),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(adinar n libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(adrim n lmɣrib),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(frank n madaɣacqar),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(uqiyya n muṛiṭanya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(uqiyya n muṛiṭanya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(arubi n muris),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwaca n malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(amitikl n muznbiq),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(adular n namibya),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nayra n nijirya),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(afrank n rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(aryal n ssaɛudiya),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(arubi n ssicil),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(adinar n ssudan),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(ajnih n ssudan),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(ajnih n santilin),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(liyun),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(acilin n ṣṣumal),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(adubra n sanṭumi \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(adubra n sanṭumi),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilanjini),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(adinar n tuns),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(acilin n ṭanẓanya),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(acilin n uɣanda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(adular n iwunak imunn),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(frank ṣifa),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(frank ṣifa bisaw),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(arand n afriqya n iffus),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(akwaca n zambya \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(akwaca n zambya),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(adular n zimbabwi),
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
							'inn',
							'bṛa',
							'maṛ',
							'ibr',
							'may',
							'yun',
							'yul',
							'ɣuc',
							'cut',
							'ktu',
							'nuw',
							'duj'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'innayr',
							'bṛayṛ',
							'maṛṣ',
							'ibrir',
							'mayyu',
							'yunyu',
							'yulyuz',
							'ɣuct',
							'cutanbir',
							'ktubr',
							'nuwanbir',
							'dujanbir'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'i',
							'b',
							'm',
							'i',
							'm',
							'y',
							'y',
							'ɣ',
							'c',
							'k',
							'n',
							'd'
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
						mon => 'ayn',
						tue => 'asi',
						wed => 'akṛ',
						thu => 'akw',
						fri => 'asim',
						sat => 'asiḍ',
						sun => 'asa'
					},
					wide => {
						mon => 'aynas',
						tue => 'asinas',
						wed => 'akṛas',
						thu => 'akwas',
						fri => 'asimwas',
						sat => 'asiḍyas',
						sun => 'asamas'
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
					abbreviated => {0 => 'ak 1',
						1 => 'ak 2',
						2 => 'ak 3',
						3 => 'ak 4'
					},
					wide => {0 => 'akṛaḍyur 1',
						1 => 'akṛaḍyur 2',
						2 => 'akṛaḍyur 3',
						3 => 'akṛaḍyur 4'
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
					'am' => q{tifawt},
					'pm' => q{tadggʷat},
				},
				'wide' => {
					'am' => q{tifawt},
					'pm' => q{tadggʷat},
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
				'0' => 'daɛ',
				'1' => 'dfɛ'
			},
			wide => {
				'0' => 'dat n ɛisa',
				'1' => 'dffir n ɛisa'
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
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM, y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM, y},
			'short' => q{d/M/y},
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
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			M => q{M},
			MMM => q{MMM},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			M => q{M},
			MMM => q{MMM},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
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
		'gregorian' => {
			'Day' => '{0} ({2}: {1})',
			'Day-Of-Week' => '{0} {1}',
			'Era' => '{1} {0}',
			'Hour' => '{0} ({2}: {1})',
			'Minute' => '{0} ({2}: {1})',
			'Month' => '{0} ({2}: {1})',
			'Quarter' => '{0} ({2}: {1})',
			'Second' => '{0} ({2}: {1})',
			'Timezone' => '{0} {1}',
			'Week' => '{0} ({2}: {1})',
			'Year' => '{1} {0}',
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
	} },
);

no Moo;

1;

# vim: tabstop=4
