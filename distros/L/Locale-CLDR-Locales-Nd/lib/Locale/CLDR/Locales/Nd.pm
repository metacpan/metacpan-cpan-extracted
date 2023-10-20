=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Nd - Package for language North Ndebele

=cut

package Locale::CLDR::Locales::Nd;
# This file auto generated from Data\common\main\nd.xml
#	on Fri 13 Oct  9:30:09 am GMT

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

extends('Locale::CLDR::Locales::Root');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'ak' => 'isi-Akhani',
 				'am' => 'isi-Amaharikhi',
 				'ar' => 'isi-Alabhu',
 				'be' => 'isi-Bhelarashiyani',
 				'bg' => 'isi-Bulgaria',
 				'bn' => 'isi-Bhengali',
 				'cs' => 'isi-Czech',
 				'de' => 'isi-Jalimani',
 				'el' => 'isi-Giliki',
 				'en' => 'isi-Ngisi',
 				'es' => 'isi-Sipeyini',
 				'fa' => 'isi-Pheshiyani',
 				'fr' => 'isi-Fulentshi',
 				'ha' => 'isi-Hausa',
 				'hi' => 'isi-Hindi',
 				'hu' => 'isi-Hangari',
 				'id' => 'isi-Indonesia',
 				'ig' => 'isi-Igbo',
 				'it' => 'isi-Italiano',
 				'ja' => 'isi-Japhani',
 				'jv' => 'isi-Java',
 				'km' => 'isi-Khambodiya',
 				'ko' => 'isi-Koriya',
 				'ms' => 'isi-Malayi',
 				'my' => 'isi-Burma',
 				'nd' => 'isiNdebele',
 				'ne' => 'isi-Nepali',
 				'nl' => 'isi-Dutch',
 				'pa' => 'isi-Phunjabi',
 				'pl' => 'isi-Pholoshi',
 				'pt' => 'isi-Potukezi',
 				'ro' => 'isi-Romani',
 				'ru' => 'isi-Rashiya',
 				'rw' => 'isi-Ruwanda',
 				'so' => 'isi-Somali',
 				'sv' => 'isi-Swidishi',
 				'ta' => 'isi-Thamil',
 				'th' => 'isi-Thayi',
 				'tr' => 'isi-Thekishi',
 				'uk' => 'isi-Ukrain',
 				'ur' => 'isi-Udu',
 				'vi' => 'isi-Vietnamese',
 				'yo' => 'isi-Yorubha',
 				'zh' => 'isi-China',
 				'zu' => 'isi-Zulu',

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
 			'AE' => 'United Arab Emirates',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua le Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AR' => 'Ajentina',
 			'AS' => 'Samoa ye Amelika',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Arubha',
 			'AZ' => 'Azerbaijan',
 			'BA' => 'Bhosnia le Herzegovina',
 			'BB' => 'Bhabhadosi',
 			'BD' => 'Bhangiladeshi',
 			'BE' => 'Bhelgium',
 			'BF' => 'Bhukina Faso',
 			'BG' => 'Bhulgariya',
 			'BH' => 'Bhahareni',
 			'BI' => 'Bhurundi',
 			'BJ' => 'Bhenini',
 			'BM' => 'Bhemuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bholiviya',
 			'BR' => 'Brazili',
 			'BS' => 'Bhahamas',
 			'BT' => 'Bhutani',
 			'BW' => 'Botswana',
 			'BY' => 'Bhelarusi',
 			'BZ' => 'Bhelize',
 			'CA' => 'Khanada',
 			'CD' => 'Democratic Republic of the Congo',
 			'CF' => 'Central African Republic',
 			'CG' => 'Khongo',
 			'CH' => 'Switzerland',
 			'CI' => 'Ivory Coast',
 			'CK' => 'Cook Islands',
 			'CL' => 'Chile',
 			'CM' => 'Khameruni',
 			'CN' => 'China',
 			'CO' => 'Kholombiya',
 			'CR' => 'Khosta Rikha',
 			'CU' => 'Cuba',
 			'CV' => 'Cape Verde Islands',
 			'CY' => 'Cyprus',
 			'CZ' => 'Czech Republic',
 			'DE' => 'Germany',
 			'DJ' => 'Djibouti',
 			'DK' => 'Denmakhi',
 			'DM' => 'Dominikha',
 			'DO' => 'Dominican Republic',
 			'DZ' => 'Aljeriya',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egypt',
 			'ER' => 'Eritrea',
 			'ES' => 'Spain',
 			'ET' => 'Ethiopia',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Falkland Islands',
 			'FM' => 'Micronesia',
 			'FR' => 'Furansi',
 			'GA' => 'Gabhoni',
 			'GB' => 'United Kingdom',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Gwiyana ye Furansi',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambiya',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Equatorial Guinea',
 			'GR' => 'Greece',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HN' => 'Honduras',
 			'HR' => 'Croatia',
 			'HT' => 'Hayiti',
 			'HU' => 'Hungary',
 			'ID' => 'Indonesiya',
 			'IE' => 'Ireland',
 			'IL' => 'Isuraeli',
 			'IN' => 'Indiya',
 			'IO' => 'British Indian Ocean Territory',
 			'IQ' => 'Iraki',
 			'IR' => 'Iran',
 			'IS' => 'Iceland',
 			'IT' => 'Itali',
 			'JM' => 'Jamaica',
 			'JO' => 'Jodani',
 			'JP' => 'Japan',
 			'KE' => 'Khenya',
 			'KG' => 'Kyrgyzstan',
 			'KH' => 'Cambodia',
 			'KI' => 'Khiribati',
 			'KM' => 'Khomoro',
 			'KN' => 'Saint Kitts and Nevis',
 			'KP' => 'North Korea',
 			'KR' => 'South Korea',
 			'KW' => 'Khuweiti',
 			'KY' => 'Cayman Islands',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Lebhanoni',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Libheriya',
 			'LS' => 'Lesotho',
 			'LT' => 'Lithuania',
 			'LU' => 'Luxembourg',
 			'LV' => 'Latvia',
 			'LY' => 'Libhiya',
 			'MA' => 'Morokho',
 			'MC' => 'Monakho',
 			'MD' => 'Moldova',
 			'MG' => 'Madagaska',
 			'MH' => 'Marshall Islands',
 			'MK' => 'Macedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar',
 			'MN' => 'Mongolia',
 			'MP' => 'Northern Mariana Islands',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldives',
 			'MW' => 'Malawi',
 			'MX' => 'Meksikho',
 			'MY' => 'Malezhiya',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibhiya',
 			'NC' => 'New Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk Island',
 			'NG' => 'Nigeriya',
 			'NI' => 'Nicaragua',
 			'NL' => 'Netherlands',
 			'NO' => 'Noweyi',
 			'NP' => 'Nephali',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'New Zealand',
 			'OM' => 'Omani',
 			'PA' => 'Panama',
 			'PE' => 'Pheru',
 			'PF' => 'Pholinesiya ye Fulansi',
 			'PG' => 'Papua New Guinea',
 			'PH' => 'Philippines',
 			'PK' => 'Phakistani',
 			'PL' => 'Pholandi',
 			'PM' => 'Saint Pierre and Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestinian West Bank and Gaza',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Kathari',
 			'RE' => 'Réunion',
 			'RO' => 'Romania',
 			'RU' => 'Rashiya',
 			'RW' => 'Ruwanda',
 			'SA' => 'Saudi Arabia',
 			'SB' => 'Solomon Islands',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudani',
 			'SE' => 'Sweden',
 			'SG' => 'Singapore',
 			'SH' => 'Saint Helena',
 			'SI' => 'Slovenia',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegali',
 			'SO' => 'Somaliya',
 			'SR' => 'Suriname',
 			'ST' => 'São Tomé and Príncipe',
 			'SV' => 'El Salvador',
 			'SY' => 'Syria',
 			'SZ' => 'Swaziland',
 			'TC' => 'Turks and Caicos Islands',
 			'TD' => 'Chadi',
 			'TG' => 'Thogo',
 			'TH' => 'Thayilandi',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Thokelawu',
 			'TL' => 'East Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisiya',
 			'TO' => 'Thonga',
 			'TR' => 'Thekhi',
 			'TT' => 'Trinidad le Tobago',
 			'TV' => 'Thuvalu',
 			'TW' => 'Thayiwani',
 			'TZ' => 'Tanzaniya',
 			'UA' => 'Yukreini',
 			'UG' => 'Uganda',
 			'US' => 'Amelika',
 			'UY' => 'Yurugwai',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatican State',
 			'VC' => 'Saint Vincent and the Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'British Virgin Islands',
 			'VI' => 'U.S. Virgin Islands',
 			'VN' => 'Vietnam',
 			'VU' => 'Vhanuatu',
 			'WF' => 'Wallis and Futuna',
 			'WS' => 'Samowa',
 			'YE' => 'Yemeni',
 			'YT' => 'Mayotte',
 			'ZA' => 'Mzansi ye Afrika',
 			'ZM' => 'Zambiya',
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
			auxiliary => qr{[r]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n o p q s t u v w x y z]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
	default		=> sub { qr'^(?i:Yebo|Y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Hatshi|H|no|n)$' }
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
				'currency' => q(Dola laseArab),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza yase Angola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dola yase Australia),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinari yase Bhahareni),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Fulenki yase Bhurundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Phula yase Botswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dola yase Khanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Fulenki yase Khongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Fulenki yase Swisi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Renminbi yase China),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo Caboverdiano),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Fulenki yase Jibhuthi),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinali yase Aljeriya),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Phawundi laseGibhide),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa yase Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Dola laseEthiopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yuro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Phawundi yase Ngilandi),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sedi yase Ghana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi yase Gambia),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Fulenki yase Gine),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupi yase Indiya),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yeni yase Japhani),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shilingi yase Kenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Fulenki yase Khomoro),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dola yase Libheriya),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lothi yase Lesotho),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinari yase Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham yase Morokho),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Fulenki yase Malagasi),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ugwiya yase Moritaniya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ugwiya yase Moritaniya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupi yase Morishasi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha yase Malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metikali yase Mozambiki),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dola yase Namibiya),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nayira yase Nijeriya),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Fulenki yase Ruwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal yase Saudi),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupi yase Seyisheli),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Dinari yase Sudani),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Phawundi yase Sudani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Phawundindi laseSt Helena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leyoni),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Shilingi yase Somaliya),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra yase Sao Tome lo Principe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra yase Sao Tome lo Principe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinari yase Tunisiya),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Shilingi yase Tanzaniya),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shilingi yase Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dola yase Amelika),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Fulenki CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Fulenki CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Randi yase Afrika ye Zanzi),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha yase Zambiya \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha yase Zambiya),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dola yase Zimbabwe),
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
							'Zib',
							'Nhlo',
							'Mbi',
							'Mab',
							'Nkw',
							'Nhla',
							'Ntu',
							'Ncw',
							'Mpan',
							'Mfu',
							'Lwe',
							'Mpal'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Zibandlela',
							'Nhlolanja',
							'Mbimbitho',
							'Mabasa',
							'Nkwenkwezi',
							'Nhlangula',
							'Ntulikazi',
							'Ncwabakazi',
							'Mpandula',
							'Mfumfu',
							'Lwezi',
							'Mpalakazi'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'Z',
							'N',
							'M',
							'M',
							'N',
							'N',
							'N',
							'N',
							'M',
							'M',
							'L',
							'M'
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
						mon => 'Mvu',
						tue => 'Sib',
						wed => 'Sit',
						thu => 'Sin',
						fri => 'Sih',
						sat => 'Mgq',
						sun => 'Son'
					},
					wide => {
						mon => 'Mvulo',
						tue => 'Sibili',
						wed => 'Sithathu',
						thu => 'Sine',
						fri => 'Sihlanu',
						sat => 'Mgqibelo',
						sun => 'Sonto'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'M',
						tue => 'S',
						wed => 'S',
						thu => 'S',
						fri => 'S',
						sat => 'M',
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
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					wide => {0 => 'Kota 1',
						1 => 'Kota 2',
						2 => 'Kota 3',
						3 => 'Kota 4'
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
				'0' => 'UKristo angakabuyi',
				'1' => 'Ukristo ebuyile'
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
