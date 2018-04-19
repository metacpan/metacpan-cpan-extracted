=head1

Locale::CLDR::Locales::So - Package for language Somali

=cut

package Locale::CLDR::Locales::So;
# This file auto generated from Data\common\main\so.xml
#	on Fri 13 Apr  7:28:39 am GMT

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
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'af' => 'Afrikaanays',
 				'ak' => 'Akan',
 				'am' => 'Axmaari',
 				'ar' => 'Carabi',
 				'as' => 'Asaamiis',
 				'az' => 'Azerbaijan',
 				'be' => 'Beleruusiyaan',
 				'bg' => 'Bulgeeriyaan',
 				'bn' => 'Bangaali',
 				'br' => 'Bereton',
 				'bs' => 'Boosniya',
 				'ca' => 'Katalaan',
 				'cs' => 'Jeeg',
 				'cy' => 'Welsh',
 				'da' => 'Danmarkays',
 				'de' => 'Jarmal',
 				'de_CH' => 'Jarmal (Iswiiserlaand)',
 				'el' => 'Giriik',
 				'en' => 'Ingiriisi',
 				'en_GB' => 'Ingiriisi (Boqortooyada Midowday)',
 				'en_US' => 'Ingiriisi (Maraykan)',
 				'eo' => 'Isberento',
 				'es' => 'Isbaanish',
 				'es_419' => 'Isbaanishka Laatiin Ameerika',
 				'es_ES' => 'Isbaanish (Isbayn)',
 				'et' => 'Istooniyaan',
 				'eu' => 'Basquu',
 				'fa' => 'Faarisi',
 				'fi' => 'Fiinlaandees',
 				'fil' => 'Tagalog',
 				'fo' => 'Farowsi',
 				'fr' => 'Faransiis',
 				'fr_CH' => 'Faransiis (Iswiiserlaand)',
 				'fy' => 'Firiisiyan Galbeed',
 				'ga' => 'Ayrish',
 				'gd' => 'Iskot Giilik',
 				'gl' => 'Galiisiyaan',
 				'gn' => 'Guraani',
 				'gu' => 'Gujaraati',
 				'ha' => 'Hawsa',
 				'he' => 'Cibri',
 				'hi' => 'Hindi',
 				'hr' => 'Koro’eeshiyaan',
 				'hu' => 'Hangariyaan',
 				'hy' => 'Armeeniyaan',
 				'ia' => 'Interlinguwa',
 				'id' => 'Indunuusiyaan',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'is' => 'Ayslandays',
 				'it' => 'Talyaani',
 				'ja' => 'Jabbaaniis',
 				'jv' => 'Jafaaniis',
 				'ka' => 'Joorijiyaan',
 				'km' => 'Kamboodhian',
 				'kn' => 'Kannadays',
 				'ko' => 'Kuuriyaan',
 				'ku' => 'Kurdishka',
 				'ky' => 'Kirgiis',
 				'la' => 'Laatiin',
 				'ln' => 'Lingala',
 				'lo' => 'Laothian',
 				'lt' => 'Lituwaanays',
 				'lv' => 'Laatfiyaan',
 				'mk' => 'Masadooniyaan',
 				'ml' => 'Malayalam',
 				'mn' => 'Mangooli',
 				'mr' => 'Maarati',
 				'ms' => 'Malaay',
 				'mt' => 'Maltiis',
 				'my' => 'Burmese',
 				'ne' => 'Nebaali',
 				'nl' => 'Holandays',
 				'nn' => 'Nowrwejiyan (naynoroski)',
 				'no' => 'Af Noorwiijiyaan',
 				'oc' => 'Okitaan',
 				'or' => 'Oriya',
 				'pa' => 'Bunjaabi',
 				'pl' => 'Boolish',
 				'ps' => 'Bashtuu',
 				'pt' => 'Boortaqiis',
 				'pt_BR' => 'Boortaqiiska Baraasiil',
 				'pt_PT' => 'Boortaqiis (Boortuqaal)',
 				'ro' => 'Romanka',
 				'ru' => 'Ruush',
 				'rw' => 'Rwanda',
 				'sa' => 'Sanskrit',
 				'sd' => 'SINDHI',
 				'sh' => 'Serbiyaan',
 				'si' => 'Sinhaleys',
 				'sk' => 'Isloofaak',
 				'sl' => 'Islofeeniyaan',
 				'so' => 'Soomaali',
 				'sq' => 'Albaaniyaan',
 				'sr' => 'Seerbiyaan',
 				'st' => 'Sesooto',
 				'sv' => 'Swiidhis',
 				'sw' => 'Sawaaxili',
 				'ta' => 'Tamiil',
 				'te' => 'Teluugu',
 				'th' => 'Taaylandays',
 				'ti' => 'Tigrinya',
 				'tk' => 'Turkumaanish',
 				'tlh' => 'Kiligoon',
 				'tr' => 'Turkish',
 				'tw' => 'Tiwiyan',
 				'ug' => 'UIGHUR',
 				'uk' => 'Yukreeniyaan',
 				'und' => 'Af aan la aqoon ama aan sax ahayn',
 				'ur' => 'Urduu',
 				'uz' => 'Usbakis',
 				'vi' => 'Fiitnaamays',
 				'xh' => 'Hoosta',
 				'yi' => 'Yadhish',
 				'yo' => 'Yoruuba',
 				'zh' => 'Jayniis',
 				'zu' => 'Zuulu',

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
			'Latn' => 'Laatiin',
 			'Zxxx' => 'Aan la qorin',
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
			'014' => 'Afrikada Bari',
 			'030' => 'Aasiyada Bari',
 			'151' => 'Yurubta Bari',
 			'AD' => 'Andora',
 			'AE' => 'Imaaraadka Carabta ee Midoobay',
 			'AF' => 'Afgaanistaan',
 			'AG' => 'Antigua iyo Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albaaniya',
 			'AM' => 'Armeeniya',
 			'AO' => 'Angoola',
 			'AR' => 'Arjantiin',
 			'AS' => 'Samowa Ameerika',
 			'AT' => 'Awsteriya',
 			'AU' => 'Awstaraaliya',
 			'AW' => 'Aruba',
 			'AZ' => 'Azerbajaan',
 			'BA' => 'Bosniya Hersigoviina',
 			'BB' => 'Baarbadoos',
 			'BD' => 'Bangaaladheesh',
 			'BE' => 'Biljam',
 			'BF' => 'Burkiina Faaso',
 			'BG' => 'Bulgaariya',
 			'BH' => 'Baxreyn',
 			'BI' => 'Burundi',
 			'BJ' => 'Biniin',
 			'BM' => 'Bermuuda',
 			'BN' => 'Buruneeya',
 			'BO' => 'Boliifiya',
 			'BR' => 'Braasiil',
 			'BS' => 'Bahaamas',
 			'BT' => 'Bhutan',
 			'BW' => 'Botuswaana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CD' => 'Jamhuuriyadda Dimuquraadiga Kongo',
 			'CF' => 'Jamhuuriyadda Afrikada Dhexe',
 			'CG' => 'Kongo',
 			'CH' => 'Swiiserlaand',
 			'CI' => 'Ivory coast',
 			'CK' => 'Jaziiradda Cook',
 			'CL' => 'Jili',
 			'CM' => 'Kaameruun',
 			'CN' => 'Shiinaha',
 			'CO' => 'Kolombiya',
 			'CR' => 'Kosta Riika',
 			'CU' => 'Kuuba',
 			'CV' => 'Cape Verde Islands',
 			'CY' => 'Qubrus',
 			'CZ' => 'Jamhuuriyadda Jek',
 			'DE' => 'Jarmal',
 			'DJ' => 'Jabuuti',
 			'DK' => 'Denmark',
 			'DM' => 'Domeenika',
 			'DO' => 'Jamhuuriyadda Domeenika',
 			'DZ' => 'Aljeeriya',
 			'EC' => 'Ikuwadoor',
 			'EE' => 'Estooniya',
 			'EG' => 'Masar',
 			'ER' => 'Eretereeya',
 			'ES' => 'Isbeyn',
 			'ET' => 'Itoobiya',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Jaziiradaha Fooklaan',
 			'FM' => 'Micronesia',
 			'FR' => 'Faransiis',
 			'GA' => 'Gaaboon',
 			'GB' => 'United Kingdom',
 			'GD' => 'Giriinaada',
 			'GE' => 'Joorjiya',
 			'GF' => 'French Guiana',
 			'GH' => 'Gaana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambiya',
 			'GN' => 'Gini',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Equatorial Guinea',
 			'GR' => 'Giriig',
 			'GT' => 'Guwaatamaala',
 			'GU' => 'Guam',
 			'GW' => 'Gini-Bisaaw',
 			'GY' => 'Guyana',
 			'HN' => 'Honduras',
 			'HR' => 'Korweeshiya',
 			'HT' => 'Hayti',
 			'HU' => 'Hangeri',
 			'ID' => 'Indoneesiya',
 			'IE' => 'Ayrlaand',
 			'IL' => 'Israaʼiil',
 			'IN' => 'Hindiya',
 			'IO' => 'British Indian Ocean Territory',
 			'IQ' => 'Ciraaq',
 			'IR' => 'Iiraan',
 			'IS' => 'Iislaand',
 			'IT' => 'Talyaani',
 			'JM' => 'Jameyka',
 			'JO' => 'Urdun',
 			'JP' => 'Jabaan',
 			'KE' => 'Kiiniya',
 			'KG' => 'Kirgistaan',
 			'KH' => 'Kamboodiya',
 			'KI' => 'Kiribati',
 			'KM' => 'Komooros',
 			'KN' => 'Saint Kitts and Nevis',
 			'KP' => 'Kuuriyada Waqooyi',
 			'KR' => 'Kuuriyada Koonfureed',
 			'KW' => 'Kuwayt',
 			'KY' => 'Cayman Islands',
 			'KZ' => 'Kasaakhistaan',
 			'LA' => 'Laos',
 			'LB' => 'Lubnaan',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sirilaanka',
 			'LR' => 'Laybeeriya',
 			'LS' => 'Losooto',
 			'LT' => 'Lituweeniya',
 			'LU' => 'Luksemboorg',
 			'LV' => 'Latfiya',
 			'LY' => 'Liibiya',
 			'MA' => 'Marooko',
 			'MC' => 'Moonako',
 			'MD' => 'Moldofa',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshall Islands',
 			'MK' => 'Makadooniya',
 			'ML' => 'Maali',
 			'MM' => 'Miyanmar',
 			'MN' => 'Mongooliya',
 			'MP' => 'Northern Mariana Islands',
 			'MQ' => 'Martinique',
 			'MR' => 'Muritaaniya',
 			'MS' => 'Montserrat',
 			'MT' => 'Maalda',
 			'MU' => 'Murishiyoos',
 			'MV' => 'Maaldiqeen',
 			'MW' => 'Malaawi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malaysia',
 			'MZ' => 'Musambiig',
 			'NA' => 'Namiibiya',
 			'NC' => 'New Caledonia',
 			'NE' => 'Nayjer',
 			'NF' => 'Norfolk Island',
 			'NG' => 'Nayjeeriya',
 			'NI' => 'Nikaraaguwa',
 			'NL' => 'Netherlands',
 			'NO' => 'Noorweey',
 			'NP' => 'Nebaal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Neyuusilaand',
 			'OM' => 'Cumaan',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'French Polynesia',
 			'PG' => 'Papua New Guinea',
 			'PH' => 'Filibiin',
 			'PK' => 'Bakistaan',
 			'PL' => 'Booland',
 			'PM' => 'Saint Pierre and Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Falastiin Daanka galbeed iyo Qasa',
 			'PT' => 'Bortuqaal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qadar',
 			'RE' => 'Réunion',
 			'RO' => 'Rumaaniya',
 			'RU' => 'Ruush',
 			'RW' => 'Ruwanda',
 			'SA' => 'Sacuudi Carabiya',
 			'SB' => 'Solomon Islands',
 			'SC' => 'Sishelis',
 			'SD' => 'Suudaan',
 			'SE' => 'Iswidhan',
 			'SG' => 'Singaboor',
 			'SH' => 'Saint Helena',
 			'SI' => 'Slovenia',
 			'SK' => 'Slovakia',
 			'SL' => 'Siraaliyoon',
 			'SM' => 'San Marino',
 			'SN' => 'Sinigaal',
 			'SO' => 'Soomaaliya',
 			'SR' => 'Suriname',
 			'SS' => 'Koonfur Suudaan',
 			'ST' => 'São Tomé and Príncipe',
 			'SV' => 'El Salvador',
 			'SY' => 'Suuriya',
 			'SZ' => 'Iswaasilaand',
 			'TC' => 'Turks and Caicos Islands',
 			'TD' => 'Jaad',
 			'TG' => 'Toogo',
 			'TH' => 'Taylaand',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timorka bari',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tuniisiya',
 			'TO' => 'Tonga',
 			'TR' => 'Turki',
 			'TT' => 'Trinidad and Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taywaan',
 			'TZ' => 'Tansaaniya',
 			'UA' => 'Ukrayn',
 			'UG' => 'Ugaanda',
 			'US' => 'Maraykanka',
 			'UY' => 'Uruguwaay',
 			'UZ' => 'Uusbakistaan',
 			'VA' => 'Faatikaan',
 			'VC' => 'Saint Vincent and the Grenadines',
 			'VE' => 'Fenisuweela',
 			'VG' => 'British Virgin Islands',
 			'VI' => 'U.S. Virgin Islands',
 			'VN' => 'Fiyetnaam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis and Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Yaman',
 			'YT' => 'Mayotte',
 			'ZA' => 'Koonfur Afrika',
 			'ZM' => 'Saambiya',
 			'ZW' => 'Simbaabwe',
 			'ZZ' => 'Far aan la aqoon amase aan saxnayn',

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
 			'currency' => 'Lacag',

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
 				'hebrew' => q{Habeentiriska yuhuudda},
 				'islamic' => q{Habeentiriska islaamka},
 				'japanese' => q{Habeentiriska jabbaanka},
 			},

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
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
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

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'group' => q(,),
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
					'one' => '0K',
					'other' => '0K',
				},
				'10000' => {
					'one' => '00K',
					'other' => '00K',
				},
				'100000' => {
					'one' => '000K',
					'other' => '000K',
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
		'DJF' => {
			display_name => {
				'currency' => q(Faran Jabbuuti),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birta Itoobbiya),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yuuroo),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyaalka Sacuudiga),
			},
		},
		'SOS' => {
			symbol => 'S',
			display_name => {
				'currency' => q(Shilin soomaali),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Shilin Tansaani),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Doollar maraykan),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Lacag aan la qoon ama aan saxnayn),
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
							'Kob',
							'Lab',
							'Sad',
							'Afr',
							'Sha',
							'Lix',
							'Tod',
							'Sid',
							'Sag',
							'Tob',
							'KIT',
							'LIT'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'K',
							'L',
							'S',
							'A',
							'S',
							'L',
							'T',
							'S',
							'S',
							'T',
							'K',
							'L'
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
							'K',
							'L',
							'S',
							'A',
							'S',
							'L',
							'T',
							'S',
							'S',
							'T',
							'K',
							'L'
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
						tue => 'Tal',
						wed => 'Arb',
						thu => 'Kha',
						fri => 'Jim',
						sat => 'Sab',
						sun => 'Axd'
					},
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
						tue => 'Tal',
						wed => 'Arb',
						thu => 'Kha',
						fri => 'Jim',
						sat => 'Sab',
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
						tue => 'Tal',
						wed => 'Arb',
						thu => 'Kha',
						fri => 'Jim',
						sat => 'Sab',
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Rubaca 1aad',
						1 => 'Rubaca 2aad',
						2 => 'Rubaca 3aad',
						3 => 'Rubaca 4aad'
					},
				},
				'stand-alone' => {
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
					'pm' => q{gn.},
					'am' => q{sn.},
				},
				'narrow' => {
					'pm' => q{gn.},
					'am' => q{sn.},
				},
				'wide' => {
					'am' => q{sn.},
					'pm' => q{gn.},
				},
			},
			'stand-alone' => {
				'wide' => {
					'pm' => q{gn.},
					'am' => q{sn.},
				},
				'abbreviated' => {
					'pm' => q{gn.},
					'am' => q{sn.},
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
				'0' => 'CK',
				'1' => 'CD'
			},
			wide => {
				'0' => 'CK',
				'1' => 'CD'
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
			'full' => q{EEEE, MMMM dd, y G},
			'long' => q{dd MMMM y G},
			'medium' => q{dd-MMM-y G},
			'short' => q{dd/MM/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM dd, y},
			'long' => q{dd MMMM y},
			'medium' => q{dd-MMM-y},
			'short' => q{dd/MM/yy},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			hm => q{h:mm a},
			ms => q{mm:ss},
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
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			MMMMW => q{'usbuuc' W 'ee' MMMM},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			hm => q{h:mm a},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
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
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
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
				M => q{E, dd MMM – E, dd MMM},
				d => q{E, dd – E, dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd–dd MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
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
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM dd – E, MMM dd, y},
				d => q{E, MMM dd – E, MMM dd, y},
				y => q{E, MMM dd, y – E, MMM dd, y},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y},
				d => q{dd–dd MMM y},
				y => q{dd MMM y – dd MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
		'gregorian' => {
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
				M => q{E, dd MMM – E, dd MMM},
				d => q{E, dd – E, dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd–dd MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
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
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM dd – E, MMM dd, y},
				d => q{E, MMM dd – E, MMM dd, y},
				y => q{E, MMM dd, y – E, MMM dd, y},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y},
				d => q{dd–dd MMM y},
				y => q{dd MMM y – dd MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Colombia' => {
			long => {
				'daylight' => q#Waqtiyada Xagaaga Kolambiya#,
				'generic' => q#Waqtiga Kolambiya#,
				'standard' => q#Waqtiyada Caadiga ah ee kolambiya#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Waqtiga Galabagos#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
