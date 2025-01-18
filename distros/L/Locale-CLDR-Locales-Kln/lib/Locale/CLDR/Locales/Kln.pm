=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Kln - Package for language Kalenjin

=cut

package Locale::CLDR::Locales::Kln;
# This file auto generated from Data\common\main\kln.xml
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
				'ak' => 'kutitab Aka',
 				'am' => 'kutitab Amariek',
 				'ar' => 'kutitab Arabuk',
 				'be' => 'kutitab Belarusa',
 				'bg' => 'kutitab Bulgaria',
 				'bn' => 'kutitab Bengali',
 				'cs' => 'kutitab Chek',
 				'de' => 'kutitab Chermani',
 				'el' => 'kutitab Greece',
 				'en' => 'kutitab Uingeresa',
 				'es' => 'kutitab Espianik',
 				'fa' => 'kutitab Persia',
 				'fr' => 'kutitab Kifaransa',
 				'ha' => 'kutitab Hausa',
 				'hi' => 'kutitab Maindiik',
 				'hu' => 'kutitab Hangari',
 				'id' => 'kutitab Indonesia',
 				'ig' => 'kutitab Igbo',
 				'it' => 'kutitab Talianek',
 				'ja' => 'kutitap Japan',
 				'jv' => 'kutitap Javanese',
 				'kln' => 'Kalenjin',
 				'km' => 'kutitab Kher nebo Kwen',
 				'ko' => 'kutitab Korea',
 				'ms' => 'kutitab Malay',
 				'my' => 'kutitab Burma',
 				'ne' => 'kutitab Nepali',
 				'nl' => 'kutitab Boa',
 				'pa' => 'kutitab Punjab',
 				'pl' => 'kutitap Poland',
 				'pt' => 'kutitab Portugal',
 				'ro' => 'kutitab Romaniek',
 				'ru' => 'kutitab Russia',
 				'rw' => 'kutitab Kinyarwanda',
 				'so' => 'kutitab Somaliek',
 				'sv' => 'kutitab Sweden',
 				'ta' => 'kutitab Tamil',
 				'th' => 'kutitab Thailand',
 				'tr' => 'kutitab Turkey',
 				'uk' => 'kutitab Ukraine',
 				'ur' => 'kutitab Urdu',
 				'vi' => 'kutitab Vietnam',
 				'yo' => 'kutitab Yoruba',
 				'zh' => 'kutitab China',
 				'zu' => 'kutitab Zulu',

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
			'AD' => 'Emetab Andorra',
 			'AE' => 'Emetab kibagenge nebo arabuk',
 			'AF' => 'Emetab Afghanistan',
 			'AG' => 'Emetab Antigua ak Barbuda',
 			'AI' => 'Emetab Anguilla',
 			'AL' => 'Emetab Albania',
 			'AM' => 'Emetab Armenia',
 			'AO' => 'Emetab Angola',
 			'AR' => 'Emetab Argentina',
 			'AS' => 'Emetab American Samoa',
 			'AT' => 'Emetab Austria',
 			'AU' => 'Emetab Australia',
 			'AW' => 'Emetab Aruba',
 			'AZ' => 'Emetab Azerbaijan',
 			'BA' => 'Emetab Bosnia ak Herzegovina',
 			'BB' => 'Emetab Barbados',
 			'BD' => 'Emetab Bangladesh',
 			'BE' => 'Emetab Belgium',
 			'BF' => 'Emetab Burkina Faso',
 			'BG' => 'Emetab Bulgaria',
 			'BH' => 'Emetab Bahrain',
 			'BI' => 'Emetab Burundi',
 			'BJ' => 'Emetab Benin',
 			'BM' => 'Emetab Bermuda',
 			'BN' => 'Emetab Brunei',
 			'BO' => 'Emetab Bolivia',
 			'BR' => 'Emetab Brazil',
 			'BS' => 'Emetab Bahamas',
 			'BT' => 'Emetab Bhutan',
 			'BW' => 'Emetab Botswana',
 			'BY' => 'Emetab Belarus',
 			'BZ' => 'Emetab Belize',
 			'CA' => 'Emetab Canada',
 			'CD' => 'Emetab Congo - Kinshasa',
 			'CF' => 'Emetab Afrika nebo Kwen',
 			'CG' => 'Emetab Congo - Brazzaville',
 			'CH' => 'Emetab Switzerland',
 			'CI' => 'Emetab Côte d’Ivoire',
 			'CK' => 'Ikwembeyotab Cook',
 			'CL' => 'Emetab Chile',
 			'CM' => 'Emetab Cameroon',
 			'CN' => 'Emetab China',
 			'CO' => 'Emetab Colombia',
 			'CR' => 'Emetab Costa Rica',
 			'CU' => 'Emetab Cuba',
 			'CV' => 'Ikwembeyotab Cape Verde',
 			'CY' => 'Emetab Cyprus',
 			'CZ' => 'Emetab Czech Republic',
 			'DE' => 'Emetab Geruman',
 			'DJ' => 'Emetab Djibouti',
 			'DK' => 'Emetab Denmark',
 			'DM' => 'Emetab Dominica',
 			'DO' => 'Emetab Dominican Republic',
 			'DZ' => 'Emetab Algeria',
 			'EC' => 'Emetab Ecuador',
 			'EE' => 'Emetab Estonia',
 			'EG' => 'Emetab Misiri',
 			'ER' => 'Emetab Eritrea',
 			'ES' => 'Emetab Spain',
 			'ET' => 'Emetab Ethiopia',
 			'FI' => 'Emetab Finland',
 			'FJ' => 'Emetab Fiji',
 			'FK' => 'Ikwembeyotab Falkland',
 			'FM' => 'Emetab Micronesia',
 			'FR' => 'Emetab France',
 			'GA' => 'Emetab Gabon',
 			'GB' => 'Emetab Kibagenge nebo Uingereza',
 			'GD' => 'Emetab Grenada',
 			'GE' => 'Emetab Georgia',
 			'GF' => 'Emetab Guiana nebo Ufaransa',
 			'GH' => 'Emetab Ghana',
 			'GI' => 'Emetab Gibraltar',
 			'GL' => 'Emetab Greenland',
 			'GM' => 'Emetab Gambia',
 			'GN' => 'Emetab Guinea',
 			'GP' => 'Emetab Guadeloupe',
 			'GQ' => 'Emetab Equatorial Guinea',
 			'GR' => 'Emetab Greece',
 			'GT' => 'Emetab Guatemala',
 			'GU' => 'Emetab Guam',
 			'GW' => 'Emetab Guinea-Bissau',
 			'GY' => 'Emetab Guyana',
 			'HN' => 'Emetab Honduras',
 			'HR' => 'Emetab Croatia',
 			'HT' => 'Emetab Haiti',
 			'HU' => 'Emetab Hungary',
 			'ID' => 'Emetab Indonesia',
 			'IE' => 'Emetab Ireland',
 			'IL' => 'Emetab Israel',
 			'IN' => 'Emetab India',
 			'IO' => 'Kebebertab araraitab indian Ocean nebo Uingeresa',
 			'IQ' => 'Emetab Iraq',
 			'IR' => 'Emetab Iran',
 			'IS' => 'Emetab Iceland',
 			'IT' => 'Emetab Italy',
 			'JM' => 'Emetab Jamaica',
 			'JO' => 'Emetab Jordan',
 			'JP' => 'Emetab Japan',
 			'KE' => 'Emetab Kenya',
 			'KG' => 'Emetab Kyrgyzstan',
 			'KH' => 'Emetab Cambodia',
 			'KI' => 'Emetab Kiribati',
 			'KM' => 'Emetab Comoros',
 			'KN' => 'Emetab Saint Kitts ak Nevis',
 			'KP' => 'Emetab Korea nebo murot katam',
 			'KR' => 'Emetab korea nebo murot tai',
 			'KW' => 'Emetab Kuwait',
 			'KY' => 'Ikwembeyotab Cayman',
 			'KZ' => 'Emetab Kazakhstan',
 			'LA' => 'Emetab Laos',
 			'LB' => 'Emetab Lebanon',
 			'LC' => 'Emetab Lucia Ne',
 			'LI' => 'Emetab Liechtenstein',
 			'LK' => 'Emetab Sri Lanka',
 			'LR' => 'Emetab Liberia',
 			'LS' => 'Emetab Lesotho',
 			'LT' => 'Emetab Lithuania',
 			'LU' => 'Emetab Luxembourg',
 			'LV' => 'Emetab Latvia',
 			'LY' => 'Emetab Libya',
 			'MA' => 'Emetab Morocco',
 			'MC' => 'Emetab Monaco',
 			'MD' => 'Emetab Moldova',
 			'MG' => 'Emetab Madagascar',
 			'MH' => 'Ikwembeiyotab Marshall',
 			'ML' => 'Emetab Mali',
 			'MM' => 'Emetab Myanmar',
 			'MN' => 'Emetab Mongolia',
 			'MP' => 'Ikwembeiyotab Mariana nebo murot katam',
 			'MQ' => 'Emetab Martinique',
 			'MR' => 'Emetab Mauritania',
 			'MS' => 'Emetab Montserrat',
 			'MT' => 'Emetab Malta',
 			'MU' => 'Emetab Mauritius',
 			'MV' => 'Emetab Maldives',
 			'MW' => 'Emetab Malawi',
 			'MX' => 'Emetab Mexico',
 			'MY' => 'Emetab Malaysia',
 			'MZ' => 'Emetab Mozambique',
 			'NA' => 'Emetab Namibia',
 			'NC' => 'Emetab New Caledonia',
 			'NE' => 'Emetab niger',
 			'NF' => 'Ikwembeiyotab Norfork',
 			'NG' => 'Emetab Nigeria',
 			'NI' => 'Emetab Nicaragua',
 			'NL' => 'Emetab Holand',
 			'NO' => 'Emetab Norway',
 			'NP' => 'Emetab Nepal',
 			'NR' => 'Emetab Nauru',
 			'NU' => 'Emetab Niue',
 			'NZ' => 'Emetab New Zealand',
 			'OM' => 'Emetab Oman',
 			'PA' => 'Emetab Panama',
 			'PE' => 'Emetab Peru',
 			'PF' => 'Emetab Polynesia nebo ufaransa',
 			'PG' => 'Emetab Papua New Guinea',
 			'PH' => 'Emetab Philippines',
 			'PK' => 'Emetab Pakistan',
 			'PL' => 'Emetab Poland',
 			'PM' => 'Emetab Peter Ne titil ak Miquelon',
 			'PN' => 'Emetab Pitcairn',
 			'PR' => 'Emetab Puerto Rico',
 			'PS' => 'Emetab Palestine',
 			'PT' => 'Emetab Portugal',
 			'PW' => 'Emetab Palau',
 			'PY' => 'Emetab Paraguay',
 			'QA' => 'Emetab Qatar',
 			'RE' => 'Emetab Réunion',
 			'RO' => 'Emetab Romania',
 			'RU' => 'Emetab Russia',
 			'RW' => 'Emetab Rwanda',
 			'SA' => 'Emetab Saudi Arabia',
 			'SB' => 'Ikwembeiyotab Solomon',
 			'SC' => 'Emetab Seychelles',
 			'SD' => 'Emetab Sudan',
 			'SE' => 'Emetab Sweden',
 			'SG' => 'Emetab Singapore',
 			'SH' => 'Emetab Helena Ne tilil',
 			'SI' => 'Emetab Slovenia',
 			'SK' => 'Emetab Slovakia',
 			'SL' => 'Emetab Sierra Leone',
 			'SM' => 'Emetab San Marino',
 			'SN' => 'Emetab Senegal',
 			'SO' => 'Emetab Somalia',
 			'SR' => 'Emetab Suriname',
 			'ST' => 'Emetab São Tomé and Príncipe',
 			'SV' => 'Emetab El Salvador',
 			'SY' => 'Emetab Syria',
 			'SZ' => 'Emetab Swaziland',
 			'TC' => 'Ikwembeiyotab Turks ak Caicos',
 			'TD' => 'Emetab Chad',
 			'TG' => 'Emetab Togo',
 			'TH' => 'Emetab Thailand',
 			'TJ' => 'Emetab Tajikistan',
 			'TK' => 'Emetab Tokelau',
 			'TL' => 'Emetab Timor nebo Murot tai',
 			'TM' => 'Emetab Turkmenistan',
 			'TN' => 'Emetab Tunisia',
 			'TO' => 'Emetab Tonga',
 			'TR' => 'Emetab Turkey',
 			'TT' => 'Emetab Trinidad ak Tobago',
 			'TV' => 'Emetab Tuvalu',
 			'TW' => 'Emetab Taiwan',
 			'TZ' => 'Emetab Tanzania',
 			'UA' => 'Emetab Ukrainie',
 			'UG' => 'Emetab Uganda',
 			'US' => 'Emetab amerika',
 			'UY' => 'Emetab Uruguay',
 			'UZ' => 'Emetab Uzibekistani',
 			'VA' => 'Emetab Vatican',
 			'VC' => 'Emetab Vincent netilil ak Grenadines',
 			'VE' => 'Emetab Venezuela',
 			'VG' => 'Ikwembeyotab British Virgin',
 			'VI' => 'Ikwemweiyotab Amerika',
 			'VN' => 'Emetab Vietnam',
 			'VU' => 'Emetab Vanuatu',
 			'WF' => 'Emetab Walis ak Futuna',
 			'WS' => 'Emetab Samoa',
 			'YE' => 'Emetab Yemen',
 			'YT' => 'Emetab Mayotte',
 			'ZA' => 'Emetab Afrika nebo Murot tai',
 			'ZM' => 'Emetab Zambia',
 			'ZW' => 'Emetab Zimbabwe',

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
			auxiliary => qr{[f q v x z]},
			index => ['A', 'B', 'C', 'D', 'E', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'W', 'Y'],
			main => qr{[a b c d e g h i j k l m n o p r s t u w y]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'W', 'Y'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Wei|W|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Achicha|A|no|n)$' }
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
				'currency' => q(Rabisiekab Kibagegeitab arabuk),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Rabisiekab Angolan),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dolaitab Australian),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Rabisiekab Bahrain),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Rabisiekab Burundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Rabisiekab Botswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dolaitab Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Rabisiekab Congo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Rabisiekab Swiss),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Rabisiekab China),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Rabisiekab Kepuvede),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Rabisiekab Jibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Rabisiekab Algerian),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Pauditab Misri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Rabisiekab Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Rabisiekab Ethiopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yuroit),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(pounditab Uingereza),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Rabisiekab Ghana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Rabisiekab Gambia),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Rabisiekab Guinea),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rabisiekab India),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Rabisiekab Japan),
			},
		},
		'KES' => {
			symbol => 'Ksh',
			display_name => {
				'currency' => q(Silingitab ya Kenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Rabisiekab Komoro),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dolaitab Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Rabisiekab Lesoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Rabisiekab Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Rabisiekab Moroccan),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Rabisiekab Malagasy),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Rabisiekab Mauritania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Rabisiekab Mauritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rabisiekab Mauritius),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Rabisiekaby Malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Rabisiekab Msumbiji),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dolaitab Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Rabisiekab Nigeria),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Rabisiekab Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Rabisiekab Saudia),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rabisiekab Shelisheli),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Pouditab Sudan),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Pouditab helena ne tilil),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leonit),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leonit \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(siligitab Somalia),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Rabisiekab Sao Tome ak Principe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Rabisiekab Sao Tome ak Principe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangenit),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(RabisiekabTunisia),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(silingitab Tanzania),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Silingitab Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dolaitab ya Amareka),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Rabisiekab CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Rabisiekab CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Randitab Afrika nebo murot tai),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwachaitab Zambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwachaitab Zambia),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dolaitab ya Zimbabwe),
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
							'Mul',
							'Ngat',
							'Taa',
							'Iwo',
							'Mam',
							'Paa',
							'Nge',
							'Roo',
							'Bur',
							'Epe',
							'Kpt',
							'Kpa'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Mulgul',
							'Ng’atyaato',
							'Kiptaamo',
							'Iwootkuut',
							'Mamuut',
							'Paagi',
							'Ng’eiyeet',
							'Rooptui',
							'Bureet',
							'Epeeso',
							'Kipsuunde ne taai',
							'Kipsuunde nebo aeng’'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'M',
							'N',
							'T',
							'I',
							'M',
							'P',
							'N',
							'R',
							'B',
							'E',
							'K',
							'K'
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
						mon => 'Kot',
						tue => 'Koo',
						wed => 'Kos',
						thu => 'Koa',
						fri => 'Kom',
						sat => 'Kol',
						sun => 'Kts'
					},
					wide => {
						mon => 'Kotaai',
						tue => 'Koaeng’',
						wed => 'Kosomok',
						thu => 'Koang’wan',
						fri => 'Komuut',
						sat => 'Kolo',
						sun => 'Kotisap'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'T',
						tue => 'O',
						wed => 'S',
						thu => 'A',
						fri => 'M',
						sat => 'L',
						sun => 'T'
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
					wide => {0 => 'Robo netai',
						1 => 'Robo nebo aeng’',
						2 => 'Robo nebo somok',
						3 => 'Robo nebo ang’wan'
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
					'am' => q{krn},
					'pm' => q{koosk},
				},
				'wide' => {
					'am' => q{karoon},
					'pm' => q{kooskoliny},
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
				'0' => 'AM',
				'1' => 'KO'
			},
			wide => {
				'0' => 'Amait kesich Jesu',
				'1' => 'Kokakesich Jesu'
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
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			Md => q{M/d},
			hm => q{h:mm a},
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
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			Md => q{M/d},
			hm => q{h:mm a},
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
