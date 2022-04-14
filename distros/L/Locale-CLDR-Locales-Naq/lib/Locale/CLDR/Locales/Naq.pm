=encoding utf8

=head1

Locale::CLDR::Locales::Naq - Package for language Nama

=cut

package Locale::CLDR::Locales::Naq;
# This file auto generated from Data/common/main/naq.xml
#	on Mon 11 Apr  5:34:04 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.1');

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
				'ak' => 'Akangowab',
 				'am' => 'Amharicgowab',
 				'ar' => 'Arabiǁî gowab',
 				'be' => 'Belarusanǁî gowab',
 				'bg' => 'Bulgariaǁî gowab',
 				'bn' => 'Bengaliǁî gowab',
 				'cs' => 'Czechǁî gowab',
 				'de' => 'Duits',
 				'el' => 'Xriks',
 				'en' => 'Engels',
 				'es' => 'Spaans',
 				'fa' => 'Persiaǁî gowab',
 				'fr' => 'Frans',
 				'ha' => 'Hausagowab',
 				'hi' => 'Hindigowab',
 				'hu' => 'Hungariaǁî gowab',
 				'id' => 'Indonesiaǁî gowab',
 				'ig' => 'Igbogowab',
 				'it' => 'Italians',
 				'ja' => 'Japanees',
 				'jv' => 'Javanese',
 				'km' => 'Khmerǁî gowab, Central',
 				'ko' => 'Koreaǁî gowab',
 				'ms' => 'Malayǁî gowab',
 				'my' => 'Burmesǁî gowab',
 				'naq' => 'Khoekhoegowab',
 				'ne' => 'Nepalǁî gowab',
 				'nl' => 'Hollands',
 				'pa' => 'Punjabigowab',
 				'pl' => 'Poleǁî gowab',
 				'pt' => 'Portugees',
 				'ro' => 'Romaniaǁî gowab',
 				'ru' => 'Russiaǁî gowab',
 				'rw' => 'Rwandaǁî gowab',
 				'so' => 'Somaliǁî gowab',
 				'sv' => 'Swedeǁî gowab',
 				'ta' => 'Tamilǁî gowab',
 				'th' => 'Thaiǁî gowab',
 				'tr' => 'Turkeǁî gowab',
 				'uk' => 'Ukrainiaǁî gowab',
 				'ur' => 'Urduǁî gowab',
 				'vi' => 'Vietnamǁî gowab',
 				'yo' => 'Yorubab',
 				'zh' => 'Chineesǁî gowab, Mandarinni',
 				'zu' => 'Zulub',

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
			'AD' => 'Andorrab',
 			'AE' => 'United Arab Emirates',
 			'AF' => 'Afghanistanni',
 			'AG' => 'Antiguab tsî Barbudab',
 			'AI' => 'Anguillab',
 			'AL' => 'Albaniab',
 			'AM' => 'Armeniab',
 			'AO' => 'Angolab',
 			'AR' => 'Argentinab',
 			'AS' => 'Americab Samoab',
 			'AT' => 'Austriab',
 			'AU' => 'Australieb',
 			'AW' => 'Arubab',
 			'AZ' => 'Azerbaijanni',
 			'BA' => 'Bosniab tsî Herzegovinab',
 			'BB' => 'Barbados',
 			'BD' => 'Banglades',
 			'BE' => 'Belgiummi',
 			'BF' => 'Burkina Fasob',
 			'BG' => 'Bulgariab',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundib',
 			'BJ' => 'Benins',
 			'BM' => 'Bermudas',
 			'BN' => 'Brunei',
 			'BO' => 'Boliviab',
 			'BR' => 'Braziliab',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutans',
 			'BW' => 'Botswanab',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Kanadab',
 			'CD' => 'Democratic Republic of the Congo',
 			'CF' => 'Central African Republiki',
 			'CG' => 'Congob',
 			'CH' => 'Switzerlandi',
 			'CI' => 'Ivoorkusi',
 			'CK' => 'Cook Islands',
 			'CL' => 'Chilib',
 			'CM' => 'Cameroonni',
 			'CN' => 'Chinab',
 			'CO' => 'Colombiab',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cubab',
 			'CV' => 'Cape Verde Islands',
 			'CY' => 'Cyprus',
 			'CZ' => 'Czech Republiki',
 			'DE' => 'Duitslandi',
 			'DJ' => 'Djibouti',
 			'DK' => 'Denmarki',
 			'DM' => 'Dominicab',
 			'DO' => 'Dominican Republic',
 			'DZ' => 'Algeriab',
 			'EC' => 'Ecuadori',
 			'EE' => 'Estoniab',
 			'EG' => 'Egipteb',
 			'ER' => 'Eritreab',
 			'ES' => 'Spanieb',
 			'ET' => 'Ethiopiab',
 			'FI' => 'Finlandi',
 			'FJ' => 'Fijib',
 			'FK' => 'Falkland Islands',
 			'FM' => 'Micronesia',
 			'FR' => 'Frankreiki',
 			'GA' => 'Gaboni',
 			'GB' => 'United Kingdom',
 			'GD' => 'Grenada',
 			'GE' => 'Georgiab',
 			'GF' => 'French Guiana',
 			'GH' => 'Ghanab',
 			'GI' => 'Gibraltar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambiab',
 			'GN' => 'Guineab',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Equatorial Guineab',
 			'GR' => 'Xrikelandi',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HN' => 'Honduras',
 			'HR' => 'Croatiab',
 			'HT' => 'Haiti',
 			'HU' => 'Hongareieb',
 			'ID' => 'Indonesiab',
 			'IE' => 'Irlandi',
 			'IL' => 'Israeli',
 			'IN' => 'Indiab',
 			'IO' => 'British Indian Ocean Territory',
 			'IQ' => 'Iraqi',
 			'IR' => 'Iranni',
 			'IS' => 'Iceland',
 			'IT' => 'Italiab',
 			'JM' => 'Jamaicab',
 			'JO' => 'Jordanni',
 			'JP' => 'Japanni',
 			'KE' => 'Kenyab',
 			'KG' => 'Kyrgyzstanni',
 			'KH' => 'Cambodiab',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoros',
 			'KN' => 'Saint Kitts and Nevis',
 			'KP' => 'Koreab, Noord',
 			'KR' => 'Koreab, Suid',
 			'KW' => 'Kuwaiti',
 			'KY' => 'Cayman Islands',
 			'KZ' => 'Kazakhstanni',
 			'LA' => 'Laos',
 			'LB' => 'Lebanonni',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtensteinni',
 			'LK' => 'Sri Lankab',
 			'LR' => 'Liberiab',
 			'LS' => 'Lesothob',
 			'LT' => 'Lithuaniab',
 			'LU' => 'Luxembourgi',
 			'LV' => 'Latvia',
 			'LY' => 'Libyab',
 			'MA' => 'Morocco',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'MG' => 'Madagascari',
 			'MH' => 'Marshall Islands',
 			'MK' => 'Macedoniab',
 			'ML' => 'Malib',
 			'MM' => 'Myanmar',
 			'MN' => 'Mongolia',
 			'MP' => 'Northern Mariana Islands',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldives',
 			'MW' => 'Malawib',
 			'MX' => 'Mexicob',
 			'MY' => 'Malaysiab',
 			'MZ' => 'Mozambiki',
 			'NA' => 'Namibiab',
 			'NC' => 'New Caledonia',
 			'NE' => 'Nigeri',
 			'NF' => 'Norfolk Island',
 			'NG' => 'Nigerieb',
 			'NI' => 'Nicaraguab',
 			'NL' => 'Netherlands',
 			'NO' => 'Noorweeb',
 			'NP' => 'Nepali',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'New Zealandi',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Perub',
 			'PF' => 'French Polynesia',
 			'PG' => 'Papua New Guineab',
 			'PH' => 'Philippinni',
 			'PK' => 'Pakistanni',
 			'PL' => 'Polandi',
 			'PM' => 'Saint Pierre and Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestinian West Bank and Gaza',
 			'PT' => 'Portugali',
 			'PW' => 'Palau',
 			'PY' => 'Paraguaib',
 			'QA' => 'Qatar',
 			'RE' => 'Réunion',
 			'RO' => 'Romania',
 			'RU' => 'Rasiab',
 			'RW' => 'Rwandab',
 			'SA' => 'Saudi Arabiab',
 			'SB' => 'Solomon Islands',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudanni',
 			'SE' => 'Swedeb',
 			'SG' => 'Singapore',
 			'SH' => 'Saint Helena',
 			'SI' => 'Slovenia',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegali',
 			'SO' => 'Somaliab',
 			'SR' => 'Suriname',
 			'ST' => 'São Tomé and Príncipe',
 			'SV' => 'El Salvadori',
 			'SY' => 'Syriab',
 			'SZ' => 'Swazilandi',
 			'TC' => 'Turks and Caicos Islands',
 			'TD' => 'Chadi',
 			'TG' => 'Togob',
 			'TH' => 'Thailandi',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'East Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisiab',
 			'TO' => 'Tonga',
 			'TR' => 'Turkeieb',
 			'TT' => 'Trinidad and Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzaniab',
 			'UA' => 'Ukraine',
 			'UG' => 'Ugandab',
 			'US' => 'Amerikab',
 			'UY' => 'Uruguaib',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatican State',
 			'VC' => 'Saint Vincent and the Grenadines',
 			'VE' => 'Venezuelab',
 			'VG' => 'British Virgin Islands',
 			'VI' => 'U.S. Virgin Islands',
 			'VN' => 'Vietnammi',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis and Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Suid Afrikab',
 			'ZM' => 'Zambiab',
 			'ZW' => 'Zimbabweb',

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
			auxiliary => qr{[j l v]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'W', 'X', 'Y', 'Z'],
			main => qr{[a â b c d e f g h i î k m n o ô p q r s t u û w x y z ǀ ǁ ǂ ǃ]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'W', 'X', 'Y', 'Z'], };
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
	default		=> sub { qr'^(?i:Îi|Î|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Hî-î|H|no|n)$' }
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
				'currency' => q(United Arab Emirates Dirham),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angolan Kwanzab),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Australian Dollari),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahrain Dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi Franc),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botswanan Pulab),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Canadian Dollari),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Congolese Franc),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Swiss Franci),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Chinese Yuan Renminbi),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo Caboverdiano),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Djibouti Franc),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algerian Dinar),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Egytian Ponds),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritreian Nakfa),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Ethiopian Birr),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Eurob),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(British Ponds),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ghana Cedi),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambia Dalasi),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Guinea Franc),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indian Rupee),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Japanese Yenni),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Kenyan Shilling),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Comorian Franc),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberian Dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesotho Loti),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libyan Dinar),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Moroccan Dirham),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Malagasy Franc),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mauritania Ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mauritania Ouguiya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mauritius Rupeeb),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawian Kwachab),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mozambique Metical),
			},
		},
		'NAD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Namibia Dollari),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigerian Naira),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Rwanda Franci),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudi Riyal),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seychelles Rupee),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudanese Dinar),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Sudanese Ponds),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St Helena Ponds),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somali Shillings),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Sao Tome and Principe Dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Sao Tome and Principe Dobra),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunisian Dinar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzanian Shillings),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Ugandan Shillings),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(US Dollari),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA Franc BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(CFA Franc BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(South African Randi),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambian Kwachab \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Zambian Kwachab),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabwe Dollari),
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
							'Jan',
							'Feb',
							'Mar',
							'Apr',
							'May',
							'Jun',
							'Jul',
							'Aug',
							'Sep',
							'Oct',
							'Nov',
							'Dec'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ǃKhanni',
							'ǃKhanǀgôab',
							'ǀKhuuǁkhâb',
							'ǃHôaǂkhaib',
							'ǃKhaitsâb',
							'Gamaǀaeb',
							'ǂKhoesaob',
							'Aoǁkhuumûǁkhâb',
							'Taraǀkhuumûǁkhâb',
							'ǂNûǁnâiseb',
							'ǀHooǂgaeb',
							'Hôasoreǁkhâb'
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
							'J',
							'A',
							'S',
							'O',
							'N',
							'D'
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
						mon => 'Ma',
						tue => 'De',
						wed => 'Wu',
						thu => 'Do',
						fri => 'Fr',
						sat => 'Sat',
						sun => 'Son'
					},
					wide => {
						mon => 'Mantaxtsees',
						tue => 'Denstaxtsees',
						wed => 'Wunstaxtsees',
						thu => 'Dondertaxtsees',
						fri => 'Fraitaxtsees',
						sat => 'Satertaxtsees',
						sun => 'Sontaxtsees'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'M',
						tue => 'E',
						wed => 'W',
						thu => 'D',
						fri => 'F',
						sat => 'A',
						sun => 'S'
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
					abbreviated => {0 => 'KW1',
						1 => 'KW2',
						2 => 'KW3',
						3 => 'KW4'
					},
					wide => {0 => '1ro kwartals',
						1 => '2ǁî kwartals',
						2 => '3ǁî kwartals',
						3 => '4ǁî kwartals'
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
					'am' => q{ǁgoagas},
					'pm' => q{ǃuias},
				},
				'wide' => {
					'am' => q{ǁgoagas},
					'pm' => q{ǃuias},
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
				'0' => 'BC',
				'1' => 'AD'
			},
			wide => {
				'0' => 'Xristub aiǃâ',
				'1' => 'Xristub khaoǃgâ'
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
