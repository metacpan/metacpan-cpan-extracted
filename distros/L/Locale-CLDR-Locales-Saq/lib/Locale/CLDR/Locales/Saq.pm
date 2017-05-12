=head1

Locale::CLDR::Locales::Saq - Package for language Samburu

=cut

package Locale::CLDR::Locales::Saq;
# This file auto generated from Data\common\main\saq.xml
#	on Fri 29 Apr  7:23:53 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

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
				'ak' => 'Kiakan',
 				'am' => 'Kiamhari',
 				'ar' => 'Kiarabu',
 				'be' => 'Kibelarusi',
 				'bg' => 'Kibulgaria',
 				'bn' => 'Kibangla',
 				'cs' => 'Kichecki',
 				'de' => 'Kijerumani',
 				'el' => 'Kigiriki',
 				'en' => 'Kingereza',
 				'es' => 'Kihispania',
 				'fa' => 'Kiajemi',
 				'fr' => 'Kifaransa',
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
 				'ru' => 'Kirusi',
 				'rw' => 'Kinyarwanda',
 				'saq' => 'Kisampur',
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
			'AD' => 'Andora',
 			'AE' => 'Falme za Kiarabu',
 			'AF' => 'Afuganistani',
 			'AG' => 'Antigua na Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AR' => 'Ajentina',
 			'AS' => 'Samoa ya Marekani',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AZ' => 'Azabajani',
 			'BA' => 'Bosnia na Hezegovina',
 			'BB' => 'Babadosi',
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
 			'BS' => 'Bahama',
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
 			'KY' => 'Visiwa vya Kayman',
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
			auxiliary => qr{(?^u:[f q x z])},
			index => ['A', 'B', 'C', 'D', 'E', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y'],
			main => qr{(?^u:[a b c d e g h i j k l m n o p r s t u v w y])},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y'], };
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
	default		=> sub { qr'^(?i:Neja|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Nara)$' }
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
				'currency' => q(Njilingi eel Falme za Kiarabu),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Njilingi eel Angola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Njilingi eel Australia),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Njilingi eel Bahareni),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Njilingi eel Burundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Njilingi eel Botswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Njilingi eel Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Njilingi eel Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Njilingi eel Uswisi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Njilingi eel China),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Njilingi eel Kepuvede),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Njilingi eel Jibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Njilingi eel Aljeria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Njilingi eel Misri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Njilingi eel Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Njilingi eel Uhabeshi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yuro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Njilingi eel Uingereza),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Njilingi eel Ghana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Njilingi eel Gambia),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Njilingi eel Gine),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Njilingi eel India),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Njilingi eel Kijapani),
			},
		},
		'KES' => {
			symbol => 'Ksh',
			display_name => {
				'currency' => q(Njilingi eel Kenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Njilingi eel Komoro),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dola eel Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Njilingi eel Lesoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Njilingi eel Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Njilingi eel Moroko),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Njilingi eel Bukini),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Njilingi eel Moritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Njilingi eel Morisi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Njilingi eel Malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Njilingi eel Msumbiji),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Njilingi eel Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Njilingi eel Nijeria),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Njilingi eel Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Njilingi eel Saudia),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Njilingi eel Shelisheli),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Paunt eel Sudani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Paunt eel Santahelena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leoni),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Njilingi eel Somalia),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Njilingi eel Sao Tome na Principe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Njilingi eel Tunisia),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Njilingi eel Tanzania),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Njilingi eel Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dola eel Marekani),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Njilingi eel CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Njilingi eel CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Njilingi eel Afrika Kusini),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Njilingi eel Zambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Njilingi eel Zambia),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dola eel Zimbabwe),
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
							'Obo',
							'Waa',
							'Oku',
							'Ong',
							'Ime',
							'Ile',
							'Sap',
							'Isi',
							'Saa',
							'Tom',
							'Tob',
							'Tow'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Lapa le obo',
							'Lapa le waare',
							'Lapa le okuni',
							'Lapa le ong’wan',
							'Lapa le imet',
							'Lapa le ile',
							'Lapa le sapa',
							'Lapa le isiet',
							'Lapa le saal',
							'Lapa le tomon',
							'Lapa le tomon obo',
							'Lapa le tomon waare'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'O',
							'W',
							'O',
							'O',
							'I',
							'I',
							'S',
							'I',
							'S',
							'T',
							'T',
							'T'
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
						mon => 'Kun',
						tue => 'Ong',
						wed => 'Ine',
						thu => 'Ile',
						fri => 'Sap',
						sat => 'Kwe',
						sun => 'Are'
					},
					wide => {
						mon => 'Mderot ee kuni',
						tue => 'Mderot ee ong’wan',
						wed => 'Mderot ee inet',
						thu => 'Mderot ee ile',
						fri => 'Mderot ee sapa',
						sat => 'Mderot ee kwe',
						sun => 'Mderot ee are'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'K',
						tue => 'O',
						wed => 'I',
						thu => 'I',
						fri => 'S',
						sat => 'K',
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
					abbreviated => {0 => 'R1',
						1 => 'R2',
						2 => 'R3',
						3 => 'R4'
					},
					wide => {0 => 'Robo 1',
						1 => 'Robo 2',
						2 => 'Robo 3',
						3 => 'Robo 4'
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
				'wide' => {
					'am' => q{Tesiran},
					'pm' => q{Teipa},
				},
				'abbreviated' => {
					'pm' => q{Teipa},
					'am' => q{Tesiran},
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
				'0' => 'KK',
				'1' => 'BK'
			},
			wide => {
				'0' => 'Kabla ya Christo',
				'1' => 'Baada ya Christo'
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
