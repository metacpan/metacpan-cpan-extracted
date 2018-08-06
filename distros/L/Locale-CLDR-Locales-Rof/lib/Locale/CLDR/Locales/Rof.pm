=head1

Locale::CLDR::Locales::Rof - Package for language Rombo

=cut

package Locale::CLDR::Locales::Rof;
# This file auto generated from Data\common\main\rof.xml
#	on Sun  5 Aug  6:19:20 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.0');

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
				'ak' => 'Kiakani',
 				'am' => 'Kiamhari',
 				'ar' => 'Kiarabu',
 				'be' => 'Kibelarusi',
 				'bg' => 'Kibulgaria',
 				'bn' => 'Kibangla',
 				'cs' => 'Kichecki',
 				'de' => 'Kijerumani',
 				'el' => 'Kigiriki',
 				'en' => 'Kiingereza',
 				'es' => 'Kihispania',
 				'fa' => 'Kiajemi',
 				'fr' => 'Kyifaransa',
 				'ha' => 'Kihausa',
 				'hi' => 'Kihindi',
 				'hu' => 'Kihungari',
 				'id' => 'Kiindonesia',
 				'ig' => 'Kiigbo',
 				'it' => 'Kiitaliano',
 				'ja' => 'Kijapani',
 				'jv' => 'Kijava',
 				'km' => 'Kikambodia',
 				'ko' => 'Kikorea',
 				'ms' => 'Kimalesia',
 				'my' => 'Kiburma',
 				'ne' => 'Kinepali',
 				'nl' => 'Kiholanzi',
 				'pa' => 'Kipunjabi',
 				'pl' => 'Kipolandi',
 				'pt' => 'Kireno',
 				'ro' => 'Kiromania',
 				'rof' => 'Kihorombo',
 				'ru' => 'Kirusi',
 				'rw' => 'Kinyarwanda',
 				'so' => 'Kisomali',
 				'sv' => 'Kiswidi',
 				'ta' => 'Kitamil',
 				'th' => 'Kitailandi',
 				'tr' => 'Kituruki',
 				'uk' => 'Kiukrania',
 				'ur' => 'Kiurdu',
 				'vi' => 'Kivietinamu',
 				'yo' => 'Kiyoruba',
 				'zh' => 'Kichina',
 				'zu' => 'Kizulu',

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
			'AD' => 'Andoro',
 			'AE' => 'Falme za Kiarabu',
 			'AF' => 'Afuganistani',
 			'AG' => 'Antigua na Babuda',
 			'AI' => 'Anguila',
 			'AL' => 'Albania',
 			'AM' => 'Amenia',
 			'AO' => 'Angolo',
 			'AR' => 'Ajentina',
 			'AS' => 'Samoa ya Marekani',
 			'AT' => 'Ostria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AZ' => 'Azabajani',
 			'BA' => 'Bosnia na Hezegovina',
 			'BB' => 'Babado',
 			'BD' => 'Bangladeshi',
 			'BE' => 'Ubelgiji',
 			'BF' => 'Bukinafaso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahareni',
 			'BI' => 'Burundi',
 			'BJ' => 'Benini',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BR' => 'Brazili',
 			'BS' => 'Bahamasi',
 			'BT' => 'Butani',
 			'BW' => 'Botswana',
 			'BY' => 'Belarusi',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CD' => 'Jamhuri ya Kidemokrasia ya Kongo',
 			'CF' => 'Jamhuri ya Afrika ya Kati',
 			'CG' => 'Kongo',
 			'CH' => 'Uswisi',
 			'CI' => 'Kodivaa',
 			'CK' => 'Visiwa vya Cook',
 			'CL' => 'Chile',
 			'CM' => 'Kameruni',
 			'CN' => 'China',
 			'CO' => 'Kolombia',
 			'CR' => 'Kostarika',
 			'CU' => 'Kuba',
 			'CV' => 'Kepuvede',
 			'CY' => 'Kuprosi',
 			'CZ' => 'Jamhuri ya Cheki',
 			'DE' => 'Ujerumani',
 			'DJ' => 'Jibuti',
 			'DK' => 'Denmaki',
 			'DM' => 'Dominika',
 			'DO' => 'Jamhuri ya Dominika',
 			'DZ' => 'Aljeria',
 			'EC' => 'Ekwado',
 			'EE' => 'Estonia',
 			'EG' => 'Misri',
 			'ER' => 'Eritrea',
 			'ES' => 'Hispania',
 			'ET' => 'Uhabeshi',
 			'FI' => 'Ufini',
 			'FJ' => 'Fiji',
 			'FK' => 'Visiwa vya Falkland',
 			'FM' => 'Mikronesia',
 			'FR' => 'Ufaransa',
 			'GA' => 'Gaboni',
 			'GB' => 'Uingereza',
 			'GD' => 'Grenada',
 			'GE' => 'Jojia',
 			'GF' => 'Gwiyana ya Ufaransa',
 			'GH' => 'Ghana',
 			'GI' => 'Jibralta',
 			'GL' => 'Grinlandi',
 			'GM' => 'Gambia',
 			'GN' => 'Gine',
 			'GP' => 'Gwadelupe',
 			'GQ' => 'Ginekweta',
 			'GR' => 'Ugiriki',
 			'GT' => 'Gwatemala',
 			'GU' => 'Gwam',
 			'GW' => 'Ginebisau',
 			'GY' => 'Guyana',
 			'HN' => 'Hondurasi',
 			'HR' => 'Korasia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungaria',
 			'ID' => 'Indonesia',
 			'IE' => 'Ayalandi',
 			'IL' => 'Israeli',
 			'IN' => 'India',
 			'IO' => 'Eneo la Uingereza katika Bahari Hindi',
 			'IQ' => 'Iraki',
 			'IR' => 'Uajemi',
 			'IS' => 'Aislandi',
 			'IT' => 'Italia',
 			'JM' => 'Jamaika',
 			'JO' => 'Yordani',
 			'JP' => 'Japani',
 			'KE' => 'Kenya',
 			'KG' => 'Kirigizistani',
 			'KH' => 'Kambodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoro',
 			'KN' => 'Santakitzi na Nevis',
 			'KP' => 'Korea Kaskazini',
 			'KR' => 'Korea Kusini',
 			'KW' => 'Kuwaiti',
 			'KY' => 'Visiwa vya Kaimai',
 			'KZ' => 'Kazakistani',
 			'LA' => 'Laosi',
 			'LB' => 'Lebanoni',
 			'LC' => 'Santalusia',
 			'LI' => 'Lishenteni',
 			'LK' => 'Sirilanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesoto',
 			'LT' => 'Litwania',
 			'LU' => 'Lasembagi',
 			'LV' => 'Lativia',
 			'LY' => 'Libya',
 			'MA' => 'Moroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'MG' => 'Bukini',
 			'MH' => 'Visiwa vya Marshal',
 			'MK' => 'Masedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myama',
 			'MN' => 'Mongolia',
 			'MP' => 'Visiwa vya Mariana vya Kaskazini',
 			'MQ' => 'Martiniki',
 			'MR' => 'Moritania',
 			'MS' => 'Montserrati',
 			'MT' => 'Malta',
 			'MU' => 'Morisi',
 			'MV' => 'Modivu',
 			'MW' => 'Malawi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malesia',
 			'MZ' => 'Msumbiji',
 			'NA' => 'Namibia',
 			'NC' => 'Nyukaledonia',
 			'NE' => 'Nijeri',
 			'NF' => 'Kisiwa cha Norfok',
 			'NG' => 'Nijeria',
 			'NI' => 'Nikaragwa',
 			'NL' => 'Uholanzi',
 			'NO' => 'Norwe',
 			'NP' => 'Nepali',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nyuzilandi',
 			'OM' => 'Omani',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinesia ya Ufaransa',
 			'PG' => 'Papua',
 			'PH' => 'Filipino',
 			'PK' => 'Pakistani',
 			'PL' => 'Polandi',
 			'PM' => 'Santapieri na Mikeloni',
 			'PN' => 'Pitkairni',
 			'PR' => 'Pwetoriko',
 			'PS' => 'Ukingo wa Magharibi na Ukanda wa Gaza wa Palestina',
 			'PT' => 'Ureno',
 			'PW' => 'Palau',
 			'PY' => 'Paragwai',
 			'QA' => 'Katari',
 			'RE' => 'Riyunioni',
 			'RO' => 'Romania',
 			'RU' => 'Urusi',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi',
 			'SB' => 'Visiwa vya Solomon',
 			'SC' => 'Shelisheli',
 			'SD' => 'Sudani',
 			'SE' => 'Uswidi',
 			'SG' => 'Singapoo',
 			'SH' => 'Santahelena',
 			'SI' => 'Slovenia',
 			'SK' => 'Slovakia',
 			'SL' => 'Siera Leoni',
 			'SM' => 'Samarino',
 			'SN' => 'Senegali',
 			'SO' => 'Somalia',
 			'SR' => 'Surinamu',
 			'ST' => 'Sao Tome na Principe',
 			'SV' => 'Elsavado',
 			'SY' => 'Siria',
 			'SZ' => 'Uswazi',
 			'TC' => 'Visiwa vya Turki na Kaiko',
 			'TD' => 'Chadi',
 			'TG' => 'Togo',
 			'TH' => 'Tailandi',
 			'TJ' => 'Tajikistani',
 			'TK' => 'Tokelau',
 			'TL' => 'Timori ya Mashariki',
 			'TM' => 'Turukimenistani',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Uturuki',
 			'TT' => 'Trinidad na Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwani',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraini',
 			'UG' => 'Uganda',
 			'US' => 'Marekani',
 			'UY' => 'Urugwai',
 			'UZ' => 'Uzibekistani',
 			'VA' => 'Vatikani',
 			'VC' => 'Santavisenti na Grenadini',
 			'VE' => 'Venezuela',
 			'VG' => 'Visiwa vya Virgin vya Uingereza',
 			'VI' => 'Visiwa vya Virgin vya Marekani',
 			'VN' => 'Vietinamu',
 			'VU' => 'Vanuatu',
 			'WF' => 'Walis na Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Yemeni',
 			'YT' => 'Mayotte',
 			'ZA' => 'Afrika Kusini',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',

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
			auxiliary => qr{[q x]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n o p r s t u v w y z]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
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
	default		=> sub { qr'^(?i:Yee|Y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ehe|N)$' }
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
		'AED' => {
			display_name => {
				'currency' => q(heleri sa Falme za Kiarabu),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(heleri sa Angola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(heleri sa Australia),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(heleri sa Bahareni),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(heleri sa Burundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(heleri sa Botswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(heleri sa Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(heleri sa Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(heleri sa Uswisi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(heleri sa China),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(heleri sa Kepuvede),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(heleri sa Jibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(heleri sa Aljeria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(heleri sa Misri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(heleri sa Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(heleri sa Uhabeshi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(yuro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(heleri sa Uingereza),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(heleri sa Ghana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(heleri sa Gambia),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(heleri sa Gine),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(heleri sa India),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(heleri sa Japani),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(heleri sa Kenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(heleri sa Komoro),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(heleri sa Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(heleri sa Lesoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(heleri sa Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(heleri sa Moroko),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(heleri sa Bukini),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(heleri sa Moritania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(heleri sa Moritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(heleri sa Morisi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(heleri sa Malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(heleri sa Msumbiji),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(heleri sa Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(heleri sa Nijeria),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(heleri sa Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(heleri sa Saudia),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(heleri sa Shelisheli),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(heleri sa Sudani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(heleri sa Santahelena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leoni),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(heleri sa Somalia),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(heleri sa Sao Tome na Principe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(heleri sa Sao Tome na Principe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(heleri sa Tunisia),
			},
		},
		'TZS' => {
			symbol => 'TSh',
			display_name => {
				'currency' => q(heleri sa Tanzania),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(heleri sa Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(heleri sa Marekani),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(heleri sa CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(heleri sa CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(heleri sa Afrika Kusini),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(heleri sa Zambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(heleri sa Zambia),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(heleri sa Zimbabwe),
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
							'M1',
							'M2',
							'M3',
							'M4',
							'M5',
							'M6',
							'M7',
							'M8',
							'M9',
							'M10',
							'M11',
							'M12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Mweri wa kwanza',
							'Mweri wa kaili',
							'Mweri wa katatu',
							'Mweri wa kaana',
							'Mweri wa tanu',
							'Mweri wa sita',
							'Mweri wa saba',
							'Mweri wa nane',
							'Mweri wa tisa',
							'Mweri wa ikumi',
							'Mweri wa ikumi na moja',
							'Mweri wa ikumi na mbili'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'K',
							'K',
							'K',
							'K',
							'T',
							'S',
							'S',
							'N',
							'T',
							'I',
							'I',
							'I'
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
						mon => 'Ijt',
						tue => 'Ijn',
						wed => 'Ijtn',
						thu => 'Alh',
						fri => 'Iju',
						sat => 'Ijm',
						sun => 'Ijp'
					},
					wide => {
						mon => 'Ijumatatu',
						tue => 'Ijumanne',
						wed => 'Ijumatano',
						thu => 'Alhamisi',
						fri => 'Ijumaa',
						sat => 'Ijumamosi',
						sun => 'Ijumapili'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => '3',
						tue => '4',
						wed => '5',
						thu => '6',
						fri => '7',
						sat => '1',
						sun => '2'
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
					wide => {0 => 'Robo ya kwanza',
						1 => 'Robo ya kaili',
						2 => 'Robo ya katatu',
						3 => 'Robo ya kaana'
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
					'am' => q{kang’ama},
					'pm' => q{kingoto},
				},
				'wide' => {
					'am' => q{kang’ama},
					'pm' => q{kingoto},
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
				'0' => 'KM',
				'1' => 'BM'
			},
			wide => {
				'0' => 'Kabla ya Mayesu',
				'1' => 'Baada ya Mayesu'
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
			'short' => q{dd/MM/y},
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
		'gregorian' => {
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
	} },
);

no Moo;

1;

# vim: tabstop=4
