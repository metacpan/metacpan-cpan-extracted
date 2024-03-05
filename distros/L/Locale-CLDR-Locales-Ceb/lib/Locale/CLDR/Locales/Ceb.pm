=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ceb - Package for language Cebuano

=cut

package Locale::CLDR::Locales::Ceb;
# This file auto generated from Data\common\main\ceb.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

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
				'ar' => 'Arabic',
 				'ar_001' => 'Modernong Standard nga Arabic',
 				'bn' => 'Bangla',
 				'ceb' => 'Cebuano',
 				'de' => 'German',
 				'de_AT' => 'Austrian German',
 				'de_CH' => 'Swiss High German',
 				'en' => 'English',
 				'en_AU' => 'English sa Australia',
 				'en_CA' => 'English sa Canada',
 				'en_GB' => 'Britanikong English',
 				'en_GB@alt=short' => 'English sa UK',
 				'en_US' => 'English sa America',
 				'en_US@alt=short' => 'English sa US',
 				'es' => 'Espanyol',
 				'es_ES' => 'Espanyol (Europa)',
 				'fr' => 'Pranses',
 				'fr_CA' => 'Pranses sa Canada',
 				'fr_CH' => 'Pranses sa Switzerland',
 				'hi' => 'Hindi',
 				'hi_Latn@alt=variant' => 'Hinglish',
 				'id' => 'Indonesian',
 				'it' => 'Italiano',
 				'ja' => 'Hinapon',
 				'ko' => 'Korean',
 				'nl' => 'Dutch',
 				'nl_BE' => 'Flemish',
 				'pl' => 'Polish',
 				'pt' => 'Portuguese',
 				'pt_BR' => 'Brazilyanong Portuguese',
 				'pt_PT' => 'Portuguese sa Europe',
 				'ru' => 'Russian',
 				'th' => 'Thai',
 				'tr' => 'Turkish',
 				'und' => 'Wala Mailhing Pinulongan',
 				'zh' => 'Inintsik',
 				'zh@alt=menu' => 'Chinese, Mandarin',
 				'zh_Hans' => 'Pinasimpleng Chinese',
 				'zh_Hans@alt=long' => 'Pinasimpleng Mandarin Chinese',
 				'zh_Hant' => 'Tradisyonal nga Chinese',
 				'zh_Hant@alt=long' => 'Tradisyonal nga Mandarin Chinese',

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
			'Arab' => 'Arabo',
 			'Cyrl' => 'Sirilisko',
 			'Hans' => 'Pinasimple',
 			'Hans@alt=stand-alone' => 'Pinasimpleng Han',
 			'Hant' => 'Tradisyonal',
 			'Hant@alt=stand-alone' => 'Tradisyonal nga Han',
 			'Jpan' => 'Japanese',
 			'Kore' => 'Korean',
 			'Latn' => 'Latin',
 			'Zxxx' => 'Dili Sinulat',
 			'Zzzz' => 'Wala Mailhing Script',

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
			'001' => 'kalibutan',
 			'002' => 'Africa',
 			'003' => 'North America',
 			'005' => 'South America',
 			'009' => 'Oceania',
 			'011' => 'Western Africa',
 			'013' => 'Central America',
 			'014' => 'Eastern Africa',
 			'015' => 'Northern Africa',
 			'017' => 'Middle Africa',
 			'018' => 'Southern Africa',
 			'019' => 'Americas',
 			'021' => 'Northern America',
 			'029' => 'Caribbean',
 			'030' => 'Eastern Asia',
 			'034' => 'Southern Asia',
 			'035' => 'Southeast Asia',
 			'039' => 'Southern Europe',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Micronesian Region',
 			'061' => 'Polynesia',
 			'142' => 'Asia',
 			'143' => 'Central Asia',
 			'145' => 'Western Asia',
 			'150' => 'Europe',
 			'151' => 'Eastern Europe',
 			'154' => 'Northern Europe',
 			'155' => 'Western Europe',
 			'202' => 'Sub-Saharan Africa',
 			'419' => 'Latin America',
 			'AC' => 'Ascension Island',
 			'AD' => 'Andorra',
 			'AE' => 'United Arab Emirates',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua & Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarctica',
 			'AR' => 'Argentina',
 			'AS' => 'American Samoa',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Aland Islands',
 			'AZ' => 'Azerbaijan',
 			'BA' => 'Bosnia & Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgium',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthelemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Caribbean Netherlands',
 			'BR' => 'Brazil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvet Island',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Cocos (Keeling) Islands',
 			'CD' => 'Congo - Kinshasa',
 			'CD@alt=variant' => 'Congo (DRC)',
 			'CF' => 'Central African Republic',
 			'CG' => 'Congo - Brazzaville',
 			'CG@alt=variant' => 'Congo (Republika)',
 			'CH' => 'Switzerland',
 			'CI' => 'Cote d’Ivoire',
 			'CI@alt=variant' => 'Ivory Coast',
 			'CK' => 'Cook Islands',
 			'CL' => 'Chile',
 			'CM' => 'Cameroon',
 			'CN' => 'China',
 			'CO' => 'Colombia',
 			'CP' => 'Clipperton Island',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cape Verde',
 			'CW' => 'Curacao',
 			'CX' => 'Christmas Island',
 			'CY' => 'Cyprus',
 			'CZ' => 'Czechia',
 			'CZ@alt=variant' => 'Czech Republic',
 			'DE' => 'Germany',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Denmark',
 			'DM' => 'Dominica',
 			'DO' => 'Dominican Republic',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta & Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egypt',
 			'EH' => 'Western Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Espanya',
 			'ET' => 'Ethiopia',
 			'EU' => 'European Union',
 			'EZ' => 'Eurozone',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Falkland Islands',
 			'FK@alt=variant' => 'Falkland Islands (Islas Malvinas)',
 			'FM' => 'Micronesia',
 			'FO' => 'Faroe Islands',
 			'FR' => 'France',
 			'GA' => 'Gabon',
 			'GB' => 'United Kingdom',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'French Guiana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Equatorial Guinea',
 			'GR' => 'Greece',
 			'GS' => 'South Georgia & South Sandwich Islands',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong SAR China',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Heard & McDonald Islands',
 			'HN' => 'Honduras',
 			'HR' => 'Croatia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungary',
 			'IC' => 'Canary Islands',
 			'ID' => 'Indonesia',
 			'IE' => 'Ireland',
 			'IL' => 'Israel',
 			'IM' => 'Isle of Man',
 			'IN' => 'India',
 			'IO' => 'Teritoryo sa British Indian Ocean',
 			'IO@alt=chagos' => 'Chagos Archipelago',
 			'IQ' => 'Iraq',
 			'IR' => 'Iran',
 			'IS' => 'Iceland',
 			'IT' => 'Italya',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordan',
 			'JP' => 'Japan',
 			'KE' => 'Kenya',
 			'KG' => 'Kyrgyzstan',
 			'KH' => 'Cambodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoros',
 			'KN' => 'St. Kitts & Nevis',
 			'KP' => 'North Korea',
 			'KR' => 'South Korea',
 			'KW' => 'Kuwait',
 			'KY' => 'Cayman Islands',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Lebanon',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lithuania',
 			'LU' => 'Luxembourg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Morocco',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Marshall Islands',
 			'MK' => 'North Macedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macao SAR China',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Northern Mariana Islands',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldives',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibia',
 			'NC' => 'New Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk Island',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Netherlands',
 			'NO' => 'Norway',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'New Zealand',
 			'NZ@alt=variant' => 'Aotearoa New Zealand',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'French Polynesia',
 			'PG' => 'Papua New Guinea',
 			'PH' => 'Pilipinas',
 			'PK' => 'Pakistan',
 			'PL' => 'Poland',
 			'PM' => 'St. Pierre & Miquelon',
 			'PN' => 'Pitcairn Islands',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestinian Territories',
 			'PS@alt=short' => 'Palestine',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Outlying Oceania',
 			'RE' => 'Reunion',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Russia',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi Arabia',
 			'SB' => 'Solomon Islands',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Sweden',
 			'SG' => 'Singapore',
 			'SH' => 'St. Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard & Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'South Sudan',
 			'ST' => 'Sao Tome & Principe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks & Caicos Islands',
 			'TD' => 'Chad',
 			'TF' => 'French Southern Territories',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'East Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turkey',
 			'TT' => 'Trinidad & Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraine',
 			'UG' => 'Uganda',
 			'UM' => 'U.S. Outlying Islands',
 			'UN' => 'Hiniusang Kanasoran',
 			'US' => 'Estados Unidos',
 			'US@alt=short' => 'US',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatican City',
 			'VC' => 'St. Vincent & Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'British Virgin Islands',
 			'VI' => 'U.S. Virgin Islands',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis & Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Pseudo-Accents',
 			'XB' => 'Pseudo-Bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'South Africa',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Wala Mailhing Rehiyon',

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
 				'gregorian' => q{Gregorian nga Kalendaryo},
 				'iso8601' => q{Kalendaryo sa ISO-8601},
 			},
 			'collation' => {
 				'standard' => q{Standard nga Paagi sa Paghan-ay},
 			},
 			'numbers' => {
 				'latn' => q{Mga Western Digit},
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
			'language' => 'Pinulongan: {0}',
 			'script' => 'Script: {0}',
 			'region' => 'Rehiyon: {0}',

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
			auxiliary => qr{[c f j ñ q v x z]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b d e g h i k l m n o p r s t u w y]},
			punctuation => qr{[\- ‑ , ; \: ! ? . … '‘’ "“” ( ) \[ \] @ * / \& # ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(cardinal nga direksyon),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(cardinal nga direksyon),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(deci{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(deci{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(pico{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(pico{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(femto{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(femto{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(atto{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atto{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(centi{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(centi{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(zepto{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(zepto{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(yocto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yocto{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(milli{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(milli{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(micro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micro{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nano{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nano{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hecto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hecto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0} g-force),
						'other' => q({0} g-force),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} g-force),
						'other' => q({0} g-force),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(mga metro kada segundo kwadrado),
						'one' => q({0} ka metro kada segundo kwadrado),
						'other' => q({0} ka mga metro kada segundo kwadrado),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(mga metro kada segundo kwadrado),
						'one' => q({0} ka metro kada segundo kwadrado),
						'other' => q({0} ka mga metro kada segundo kwadrado),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(mga arcminute),
						'one' => q({0} ka arcminute),
						'other' => q({0} ka mga arcminute),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(mga arcminute),
						'one' => q({0} ka arcminute),
						'other' => q({0} ka mga arcminute),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(mga arcsecond),
						'one' => q({0} ka arcsecond),
						'other' => q({0} ka mga arcsecond),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(mga arcsecond),
						'one' => q({0} ka arcsecond),
						'other' => q({0} ka mga arcsecond),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} ka degree),
						'other' => q({0} ka mga degree),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} ka degree),
						'other' => q({0} ka mga degree),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0} ka radian),
						'other' => q({0} ka mga radian),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0} ka radian),
						'other' => q({0} ka mga radian),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(rebolusyon),
						'one' => q({0} ka rebolusyon),
						'other' => q({0} ka mga rebolusyon),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(rebolusyon),
						'one' => q({0} ka rebolusyon),
						'other' => q({0} ka mga rebolusyon),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} ka acre),
						'other' => q({0} ka mga acre),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} ka acre),
						'other' => q({0} ka mga acre),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'one' => q({0} ka dunam),
						'other' => q({0} ka mga dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'one' => q({0} ka dunam),
						'other' => q({0} ka mga dunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} ka ektarya),
						'other' => q({0} ka mga ektarya),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} ka ektarya),
						'other' => q({0} ka mga ektarya),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(mga centimetro kwadrado),
						'one' => q({0} ka sentimetro kwadrado),
						'other' => q({0} ka mga sentimetro kwadrado),
						'per' => q({0} kada sentimetro kwadrado),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(mga centimetro kwadrado),
						'one' => q({0} ka sentimetro kwadrado),
						'other' => q({0} ka mga sentimetro kwadrado),
						'per' => q({0} kada sentimetro kwadrado),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(mga square foot),
						'one' => q({0} ka square foot),
						'other' => q({0} ka mga square foot),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(mga square foot),
						'one' => q({0} ka square foot),
						'other' => q({0} ka mga square foot),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(mga square inch),
						'one' => q({0} ka mga square inch),
						'other' => q({0} ka square inch),
						'per' => q({0} kada square inch),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(mga square inch),
						'one' => q({0} ka mga square inch),
						'other' => q({0} ka square inch),
						'per' => q({0} kada square inch),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(mga square kilometer),
						'one' => q({0} ka kilometro kwadrado),
						'other' => q({0} ka mga kilometro kwadrado),
						'per' => q({0} kada kilometro kwadrado),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(mga square kilometer),
						'one' => q({0} ka kilometro kwadrado),
						'other' => q({0} ka mga kilometro kwadrado),
						'per' => q({0} kada kilometro kwadrado),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(mga metro kwadrado),
						'one' => q({0} ka metro kwadrado),
						'other' => q({0} ka mga metro kwadrado),
						'per' => q({0} kada metro kwadrado),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(mga metro kwadrado),
						'one' => q({0} ka metro kwadrado),
						'other' => q({0} ka mga metro kwadrado),
						'per' => q({0} kada metro kwadrado),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} ka milya kwadrado),
						'other' => q({0} ka mga milya kwadrado),
						'per' => q({0} kada milya kwadrado),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} ka milya kwadrado),
						'other' => q({0} ka mga milya kwadrado),
						'per' => q({0} kada milya kwadrado),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(mga square yard),
						'one' => q({0} ka square yard),
						'other' => q({0} ka mga square yard),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(mga square yard),
						'one' => q({0} ka square yard),
						'other' => q({0} ka mga square yard),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0} ka karat),
						'other' => q({0} ka mga karat),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0} ka karat),
						'other' => q({0} ka mga karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mga milligram kada deciliter),
						'one' => q({0} ka milligram kada deciliter),
						'other' => q({0} ka mga milligram kada deciliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mga milligram kada deciliter),
						'one' => q({0} ka milligram kada deciliter),
						'other' => q({0} ka mga milligram kada deciliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mga millimole kada litro),
						'one' => q({0} ka millimole kada litro),
						'other' => q({0} ka mga millimole kada litro),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mga millimole kada litro),
						'one' => q({0} ka millimole kada litro),
						'other' => q({0} ka mga millimole kada litro),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mga mole),
						'one' => q({0} ka mole),
						'other' => q({0} ka mga mole),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mga mole),
						'one' => q({0} ka mole),
						'other' => q({0} ka mga mole),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q({0} ka porsyento),
						'other' => q({0} ka porsyento),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q({0} ka porsyento),
						'other' => q({0} ka porsyento),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} ka permille),
						'other' => q({0} ka permille),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} ka permille),
						'other' => q({0} ka permille),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(mga part per million),
						'one' => q({0} ka part per million),
						'other' => q({0} ka mga part per million),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(mga part per million),
						'one' => q({0} ka part per million),
						'other' => q({0} ka mga part per million),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} ka permyriad),
						'other' => q({0} ka permyriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} ka permyriad),
						'other' => q({0} ka permyriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(mga litro kada 100 kilometro),
						'one' => q({0} ka litro kada 100 kilometro),
						'other' => q({0} ka litro kada 100 kilometro),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(mga litro kada 100 kilometro),
						'one' => q({0} ka litro kada 100 kilometro),
						'other' => q({0} ka litro kada 100 kilometro),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(mga litro kada kilometro),
						'one' => q({0} litro kada kilometro),
						'other' => q({0} ka mga litro kada kilometro),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(mga litro kada kilometro),
						'one' => q({0} litro kada kilometro),
						'other' => q({0} ka mga litro kada kilometro),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mga milya kada gallon),
						'one' => q({0} ka milya kada gallon),
						'other' => q({0} ka mga milya kada gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mga milya kada gallon),
						'one' => q({0} ka milya kada gallon),
						'other' => q({0} ka mga milya kada gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mga milya kada Imp. gallon),
						'one' => q({0} ka milya kada Imp. gallon),
						'other' => q({0} ka mga milya kada Imp. gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mga milya kada Imp. gallon),
						'one' => q({0} ka milya kada Imp. gallon),
						'other' => q({0} ka mga milya kada Imp. gallon),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} sidlakan),
						'north' => q({0} amihanan),
						'south' => q({0} habagatan),
						'west' => q({0} kasadpan),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} sidlakan),
						'north' => q({0} amihanan),
						'south' => q({0} habagatan),
						'west' => q({0} kasadpan),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(mga bit),
						'one' => q({0} ka bit),
						'other' => q({0} ka mga bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(mga bit),
						'one' => q({0} ka bit),
						'other' => q({0} ka mga bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(mga byte),
						'one' => q({0} ka byte),
						'other' => q({0} ka mga byte),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(mga byte),
						'one' => q({0} ka byte),
						'other' => q({0} ka mga byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(mga gigabit),
						'one' => q({0} ka gigabit),
						'other' => q({0} ka mga gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(mga gigabit),
						'one' => q({0} ka gigabit),
						'other' => q({0} ka mga gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(mga gigabyte),
						'one' => q({0} ka gigabyte),
						'other' => q({0} ka mga gigabyte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(mga gigabyte),
						'one' => q({0} ka gigabyte),
						'other' => q({0} ka mga gigabyte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(mga kilobit),
						'one' => q({0} ka kilobit),
						'other' => q({0} ka mga kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(mga kilobit),
						'one' => q({0} ka kilobit),
						'other' => q({0} ka mga kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(mga kilobyte),
						'one' => q({0} ka kilobyte),
						'other' => q({0} ka mga kilobyte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(mga kilobyte),
						'one' => q({0} ka kilobyte),
						'other' => q({0} ka mga kilobyte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(mga megabit),
						'one' => q({0} ka megabit),
						'other' => q({0} ka mga megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(mga megabit),
						'one' => q({0} ka megabit),
						'other' => q({0} ka mga megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(mga megabyte),
						'one' => q({0} ka megabyte),
						'other' => q({0} ka mga megabyte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(mga megabyte),
						'one' => q({0} ka megabyte),
						'other' => q({0} ka mga megabyte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(mga petabyte),
						'one' => q({0} ka petabyte),
						'other' => q({0} ka mga petabyte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(mga petabyte),
						'one' => q({0} ka petabyte),
						'other' => q({0} ka mga petabyte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(mga terabit),
						'one' => q({0} ka terabit),
						'other' => q({0} ka mga terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(mga terabit),
						'one' => q({0} ka terabit),
						'other' => q({0} ka mga terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(mga terabyte),
						'one' => q({0} ka terabyte),
						'other' => q({0} ka mga terabyte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(mga terabyte),
						'one' => q({0} ka terabyte),
						'other' => q({0} ka mga terabyte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(mga siglo),
						'one' => q({0} ka siglo),
						'other' => q({0} ka mga siglo),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(mga siglo),
						'one' => q({0} ka siglo),
						'other' => q({0} ka mga siglo),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0} ka adlaw),
						'other' => q({0} ka mga adlaw),
						'per' => q({0} kada adlaw),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} ka adlaw),
						'other' => q({0} ka mga adlaw),
						'per' => q({0} kada adlaw),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(mga dekada),
						'one' => q({0} ka dekada),
						'other' => q({0} ka mga dekada),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(mga dekada),
						'one' => q({0} ka dekada),
						'other' => q({0} ka mga dekada),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} ka oras),
						'other' => q({0} ka mga oras),
						'per' => q({0} kada oras),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} ka oras),
						'other' => q({0} ka mga oras),
						'per' => q({0} kada oras),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mga microsecond),
						'one' => q({0} ka microsecond),
						'other' => q({0} ka mga microsecond),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mga microsecond),
						'one' => q({0} ka microsecond),
						'other' => q({0} ka mga microsecond),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(mga millisecond),
						'one' => q({0} ka millisecond),
						'other' => q({0} ka mga millisecond),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(mga millisecond),
						'one' => q({0} ka millisecond),
						'other' => q({0} ka mga millisecond),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} ka minuto),
						'other' => q({0} ka mga minuto),
						'per' => q({0} kada minuto),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} ka minuto),
						'other' => q({0} ka mga minuto),
						'per' => q({0} kada minuto),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} ka buwan),
						'other' => q({0} ka mga buwan),
						'per' => q({0} kada buwan),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} ka buwan),
						'other' => q({0} ka mga buwan),
						'per' => q({0} kada buwan),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(mga nanosecond),
						'one' => q({0} ka nanosecond),
						'other' => q({0} ka mga nanosecond),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(mga nanosecond),
						'one' => q({0} ka nanosecond),
						'other' => q({0} ka mga nanosecond),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} ka segundo),
						'other' => q({0} ka mga segundo),
						'per' => q({0} kada segundo),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} ka segundo),
						'other' => q({0} ka mga segundo),
						'per' => q({0} kada segundo),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} ka semana),
						'other' => q({0} ka mga semana),
						'per' => q({0} kada semana),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} ka semana),
						'other' => q({0} ka mga semana),
						'per' => q({0} kada semana),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0} ka tuig),
						'other' => q({0} ka mga tuig),
						'per' => q({0} kada tuig),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0} ka tuig),
						'other' => q({0} ka mga tuig),
						'per' => q({0} kada tuig),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(mga ampere),
						'one' => q({0} ka ampere),
						'other' => q({0} ka mga ampere),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(mga ampere),
						'one' => q({0} ka ampere),
						'other' => q({0} ka mga ampere),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mga milliampere),
						'one' => q({0} milliampere),
						'other' => q({0} ka mga milliampere),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mga milliampere),
						'one' => q({0} milliampere),
						'other' => q({0} ka mga milliampere),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0} ka ohm),
						'other' => q({0} ka mga ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0} ka ohm),
						'other' => q({0} ka mga ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0} ka boltahe),
						'other' => q({0} ka mga boltahe),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0} ka boltahe),
						'other' => q({0} ka mga boltahe),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(Mga British thermal unit),
						'one' => q({0} ka British thermal unit),
						'other' => q({0} ka mga British thermal unit),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(Mga British thermal unit),
						'one' => q({0} ka British thermal unit),
						'other' => q({0} ka mga British thermal unit),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(mga calorie),
						'one' => q({0} ka calorie),
						'other' => q({0} ka mga calorie),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(mga calorie),
						'one' => q({0} ka calorie),
						'other' => q({0} ka mga calorie),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(mga electronvolt),
						'one' => q({0} ka electronvolt),
						'other' => q({0} ka mga electronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(mga electronvolt),
						'one' => q({0} ka electronvolt),
						'other' => q({0} ka mga electronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(mga Calorie),
						'one' => q({0} ka Calorie),
						'other' => q({0} ka mga Calorie),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(mga Calorie),
						'one' => q({0} ka Calorie),
						'other' => q({0} ka mga Calorie),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0} ka joule),
						'other' => q({0} ka mga joule),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0} ka joule),
						'other' => q({0} ka mga joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(mga kilocalorie),
						'one' => q({0} ka kilocalorie),
						'other' => q({0} ka mga kilocalorie),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(mga kilocalorie),
						'one' => q({0} ka kilocalorie),
						'other' => q({0} ka mga kilocalorie),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(mga kilojoule),
						'one' => q({0} ka kilojoule),
						'other' => q({0} ka mga kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(mga kilojoule),
						'one' => q({0} ka kilojoule),
						'other' => q({0} ka mga kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(mga kilowatt-hour),
						'one' => q({0} ka kilowatt hour),
						'other' => q({0} ka mga kilowatt-hour),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(mga kilowatt-hour),
						'one' => q({0} ka kilowatt hour),
						'other' => q({0} ka mga kilowatt-hour),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(Mga US therm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(Mga US therm),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(mga newton),
						'one' => q({0} ka newton),
						'other' => q({0} ka mga newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(mga newton),
						'one' => q({0} ka newton),
						'other' => q({0} ka mga newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(mga pound sa puwersa),
						'one' => q({0} ka pound sa puwersa),
						'other' => q({0} ka mga pound sa puwersa),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(mga pound sa puwersa),
						'one' => q({0} ka pound sa puwersa),
						'other' => q({0} ka mga pound sa puwersa),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'one' => q({0} dot),
						'other' => q({0} px),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q({0} dot),
						'other' => q({0} px),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(mga dot kada sentimetro),
						'one' => q({0} ka dot kada sentimetro),
						'other' => q({0} ka mga dot kada sentimetro),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(mga dot kada sentimetro),
						'one' => q({0} ka dot kada sentimetro),
						'other' => q({0} ka mga dot kada sentimetro),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(mga dot kada pulgada),
						'one' => q({0} ka dot kada pulgada),
						'other' => q({0} ka mga dot kada pulgada),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(mga dot kada pulgada),
						'one' => q({0} ka dot kada pulgada),
						'other' => q({0} ka mga dot kada pulgada),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(typographic em),
						'one' => q({0} ka em),
						'other' => q({0} ka mga em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(typographic em),
						'one' => q({0} ka em),
						'other' => q({0} ka mga em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0} ka megapixel),
						'other' => q({0} ka mga megapixel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0} ka megapixel),
						'other' => q({0} ka mga megapixel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0} ka pixel),
						'other' => q({0} ka mga pixel),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0} ka pixel),
						'other' => q({0} ka mga pixel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(mga pixel kada sentimetro),
						'one' => q({0} ka pixel kada sentimetro),
						'other' => q({0} ka mga pixel kada sentimetro),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(mga pixel kada sentimetro),
						'one' => q({0} ka pixel kada sentimetro),
						'other' => q({0} ka mga pixel kada sentimetro),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(mga pixel kada pulgada),
						'one' => q({0} ka pixel kada pulgada),
						'other' => q({0} ka mga pixel kada pulgada),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(mga pixel kada pulgada),
						'one' => q({0} ka pixel kada pulgada),
						'other' => q({0} ka mga pixel kada pulgada),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(mga astronomical unit),
						'one' => q({0} ka astronomical unit),
						'other' => q({0} ka mga astronomical unit),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(mga astronomical unit),
						'one' => q({0} ka astronomical unit),
						'other' => q({0} ka mga astronomical unit),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(mga sentimetro),
						'one' => q({0} ka sentimetro),
						'other' => q({0} ka mga sentimetro),
						'per' => q({0} kada sentimetro),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(mga sentimetro),
						'one' => q({0} ka sentimetro),
						'other' => q({0} ka mga sentimetro),
						'per' => q({0} kada sentimetro),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(mga decimeter),
						'one' => q({0} ka decimeter),
						'other' => q({0} ka mga decimeter),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(mga decimeter),
						'one' => q({0} ka decimeter),
						'other' => q({0} ka mga decimeter),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(radyus sa yuta),
						'one' => q({0} ka radyus sa yuta),
						'other' => q({0} ka radyus sa yuta),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(radyus sa yuta),
						'one' => q({0} ka radyus sa yuta),
						'other' => q({0} ka radyus sa yuta),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} ka piye),
						'other' => q({0} ka mga piye),
						'per' => q({0} kada piye),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} ka piye),
						'other' => q({0} ka mga piye),
						'per' => q({0} kada piye),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} ka pulgada),
						'other' => q({0} ka pulgada),
						'per' => q({0} kada pulgada),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} ka pulgada),
						'other' => q({0} ka pulgada),
						'per' => q({0} kada pulgada),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(mga kilometro),
						'one' => q({0} ka kilometro),
						'other' => q({0} ka mga kilometro),
						'per' => q({0} kada kilometro),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(mga kilometro),
						'one' => q({0} ka kilometro),
						'other' => q({0} ka mga kilometro),
						'per' => q({0} kada kilometro),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(mga light year),
						'one' => q({0} ka light year),
						'other' => q({0} ka mga light year),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(mga light year),
						'one' => q({0} ka light year),
						'other' => q({0} ka mga light year),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mga metro),
						'one' => q({0} ka metro),
						'other' => q({0} ka mga metro),
						'per' => q({0} kada metro),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mga metro),
						'one' => q({0} ka metro),
						'other' => q({0} ka mga metro),
						'per' => q({0} kada metro),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mga micrometer),
						'one' => q({0} ka micrometer),
						'other' => q({0} ka mga micrometer),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mga micrometer),
						'one' => q({0} ka micrometer),
						'other' => q({0} ka mga micrometer),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} ka milya),
						'other' => q({0} ka mga milya),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} ka milya),
						'other' => q({0} ka mga milya),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(mile-scandinavian),
						'one' => q({0} ka mile-scandinavian),
						'other' => q({0} ka mile-scandinavian),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(mile-scandinavian),
						'one' => q({0} ka mile-scandinavian),
						'other' => q({0} ka mile-scandinavian),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mga millimetro),
						'one' => q({0} ka millimetro),
						'other' => q({0} ka millimetro),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mga millimetro),
						'one' => q({0} ka millimetro),
						'other' => q({0} ka millimetro),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(mga nanometer),
						'one' => q({0} ka nanometer),
						'other' => q({0} ka mga nanometer),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(mga nanometer),
						'one' => q({0} ka nanometer),
						'other' => q({0} ka mga nanometer),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(mga nautical mile),
						'one' => q({0} ka nautical mile),
						'other' => q({0} ka mga nautical mile),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(mga nautical mile),
						'one' => q({0} ka nautical mile),
						'other' => q({0} ka mga nautical mile),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0} ka parsec),
						'other' => q({0} ka mga parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0} ka parsec),
						'other' => q({0} ka mga parsec),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(mga picometer),
						'one' => q({0} ka picometer),
						'other' => q({0} ka mga picometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(mga picometer),
						'one' => q({0} ka picometer),
						'other' => q({0} ka mga picometer),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q({0} ka point),
						'other' => q({0} ka mga point),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q({0} ka point),
						'other' => q({0} ka mga point),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} ka solar radius),
						'other' => q({0} ka mga solar radius),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} ka solar radius),
						'other' => q({0} ka mga solar radius),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} ka yarda),
						'other' => q({0} ka mga yarda),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} ka yarda),
						'other' => q({0} ka mga yarda),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(candela),
						'one' => q({0} ka candela),
						'other' => q({0} ka candela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(candela),
						'one' => q({0} ka candela),
						'other' => q({0} ka candela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
						'one' => q({0} ka lumen),
						'other' => q({0} ka lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
						'one' => q({0} ka lumen),
						'other' => q({0} ka lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0} ka solar luminosity),
						'other' => q({0}ka mga solar luminosity),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} ka solar luminosity),
						'other' => q({0}ka mga solar luminosity),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0} ka carat),
						'other' => q({0} ka mga carat),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0} ka carat),
						'other' => q({0} ka mga carat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q({0} ka dalton),
						'other' => q({0} ka mga dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q({0} ka dalton),
						'other' => q({0} ka mga dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q({0} ka mass sa Earth),
						'other' => q({0} ka mga mass sa Earth),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} ka mass sa Earth),
						'other' => q({0} ka mga mass sa Earth),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'one' => q({0} ka grain),
						'other' => q({0} ka grain),
					},
					# Core Unit Identifier
					'grain' => {
						'one' => q({0} ka grain),
						'other' => q({0} ka grain),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} ka gramo),
						'other' => q({0} ka mga gramo),
						'per' => q({0} kada gramo),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} ka gramo),
						'other' => q({0} ka mga gramo),
						'per' => q({0} kada gramo),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(mga kilogramo),
						'one' => q({0} ka kilogramo),
						'other' => q({0} ka mga kilogramo),
						'per' => q({0} kada kilogramo),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(mga kilogramo),
						'one' => q({0} ka kilogramo),
						'other' => q({0} ka mga kilogramo),
						'per' => q({0} kada kilogramo),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mga microgram),
						'one' => q({0} ka microgram),
						'other' => q({0} ka mga microgram),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mga microgram),
						'one' => q({0} ka microgram),
						'other' => q({0} ka mga microgram),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(mga milligram),
						'one' => q({0} ka milligram),
						'other' => q({0} ka mga milligram),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(mga milligram),
						'one' => q({0} ka milligram),
						'other' => q({0} ka mga milligram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(mga ounce),
						'one' => q({0} ka ounce),
						'other' => q({0} ka mga ounce),
						'per' => q({0} kada ounce),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(mga ounce),
						'one' => q({0} ka ounce),
						'other' => q({0} ka mga ounce),
						'per' => q({0} kada ounce),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(mga troy ounce),
						'one' => q({0} ka troy ounce),
						'other' => q({0} ka mga troy ounce),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(mga troy ounce),
						'one' => q({0} ka troy ounce),
						'other' => q({0} ka mga troy ounce),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} ka pound),
						'other' => q({0} ka mga pound),
						'per' => q({0} kada pound),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} ka pound),
						'other' => q({0} ka mga pound),
						'per' => q({0} kada pound),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} ka solar mass),
						'other' => q({0} ka mga solar mass),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} ka solar mass),
						'other' => q({0} ka mga solar mass),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} ka tonelada),
						'other' => q({0} ka mga tonelada),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} ka tonelada),
						'other' => q({0} ka mga tonelada),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(mga metrikong tonelada),
						'one' => q({0} ka metrikong tonelada),
						'other' => q({0} ka mga metrikong tonelada),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(mga metrikong tonelada),
						'one' => q({0} ka metrikong tonelada),
						'other' => q({0} ka mga metrikong tonelada),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} kada {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} kada {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(mga gigawatt),
						'one' => q({0} ka gigawatt),
						'other' => q({0} ka mga gigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(mga gigawatt),
						'one' => q({0} ka gigawatt),
						'other' => q({0} ka mga gigawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(horsepower),
						'one' => q({0} ka horsepower),
						'other' => q({0} ka horsepower),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(horsepower),
						'one' => q({0} ka horsepower),
						'other' => q({0} ka horsepower),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(mga kilowatt),
						'one' => q({0} ka kilowatt),
						'other' => q({0} ka mga kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(mga kilowatt),
						'one' => q({0} ka kilowatt),
						'other' => q({0} ka mga kilowatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(mga megawatt),
						'one' => q({0} ka megawatt),
						'other' => q({0} ka mga megawatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(mga megawatt),
						'one' => q({0} ka megawatt),
						'other' => q({0} ka mga megawatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(mga milliwatt),
						'one' => q({0} ka milliwatt),
						'other' => q({0} ka mga milliwatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(mga milliwatt),
						'one' => q({0} ka milliwatt),
						'other' => q({0} ka mga milliwatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0} ka watt),
						'other' => q({0} ka mga watt),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} ka watt),
						'other' => q({0} ka mga watt),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(square {0}),
						'one' => q(square {0}),
						'other' => q(square {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(square {0}),
						'one' => q(square {0}),
						'other' => q(square {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(cubic {0}),
						'one' => q(cubic {0}),
						'other' => q(cubic {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(cubic {0}),
						'one' => q(cubic {0}),
						'other' => q(cubic {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(mga atmosphere),
						'one' => q({0} ka atmosphere),
						'other' => q({0} ka mga atmosphere),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(mga atmosphere),
						'one' => q({0} ka atmosphere),
						'other' => q({0} ka mga atmosphere),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(mga bar),
						'one' => q({0} ka bar),
						'other' => q({0} ka mga bar),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(mga bar),
						'one' => q({0} ka bar),
						'other' => q({0} ka mga bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(mga hectopascal),
						'one' => q({0} ka hectopascal),
						'other' => q({0} ka mga hectopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(mga hectopascal),
						'one' => q({0} ka hectopascal),
						'other' => q({0} ka mga hectopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(mga inch sa mercury),
						'one' => q({0} ka inch sa mercury),
						'other' => q({0} ka mga pulgada sa mercury),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(mga inch sa mercury),
						'one' => q({0} ka inch sa mercury),
						'other' => q({0} ka mga pulgada sa mercury),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(mga kilopascal),
						'one' => q({0} ka kilopascal),
						'other' => q({0} ka mga kilopascal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(mga kilopascal),
						'one' => q({0} ka kilopascal),
						'other' => q({0} ka mga kilopascal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(mga megapascal),
						'one' => q({0} ka megapascal),
						'other' => q({0} ka mga megapascal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(mga megapascal),
						'one' => q({0} ka megapascal),
						'other' => q({0} ka mga megapascal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mga millibar),
						'one' => q({0} ka millibar),
						'other' => q({0} ka mga millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mga millibar),
						'one' => q({0} ka millibar),
						'other' => q({0} ka mga millibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mga millimetro sa mercury),
						'one' => q({0} ka millimetro sa mercury),
						'other' => q({0} ka mga millimetro sa mercury),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mga millimetro sa mercury),
						'one' => q({0} ka millimetro sa mercury),
						'other' => q({0} ka mga millimetro sa mercury),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(mga pascal),
						'one' => q({0} ka pascal),
						'other' => q({0} ka mga pascal),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(mga pascal),
						'one' => q({0} ka pascal),
						'other' => q({0} ka mga pascal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(mga pound kada kuwadradong pulgada),
						'one' => q({0} ka pound kada kuwadradong pulgada),
						'other' => q({0} ka mga pound kada kuwadradong pulgada),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(mga pound kada kuwadradong pulgada),
						'one' => q({0} ka pound kada kuwadradong pulgada),
						'other' => q({0} ka mga pound kada kuwadradong pulgada),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(mga kilometro kada oras),
						'one' => q({0} ka kilometro kada oras),
						'other' => q({0} ka mga kilometro kada oras),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(mga kilometro kada oras),
						'one' => q({0} ka kilometro kada oras),
						'other' => q({0} ka mga kilometro kada oras),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(mga knot),
						'one' => q({0} ka knot),
						'other' => q({0} ka mga knot),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(mga knot),
						'one' => q({0} ka knot),
						'other' => q({0} ka mga knot),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(mga metro kada segundo),
						'one' => q({0} ka metro kada segundo),
						'other' => q({0} ka mga metro kada segundo),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(mga metro kada segundo),
						'one' => q({0} ka metro kada segundo),
						'other' => q({0} ka mga metro kada segundo),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mga milya kada oras),
						'one' => q({0} ka milya kada oras),
						'other' => q({0} ka mga milya kada oras),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mga milya kada oras),
						'one' => q({0} ka milya kada oras),
						'other' => q({0} ka mga milya kada oras),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(mga degree Celsius),
						'one' => q({0} ka degree Celsius),
						'other' => q({0} degree Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(mga degree Celsius),
						'one' => q({0} ka degree Celsius),
						'other' => q({0} degree Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(mga degree Fahrenheit),
						'one' => q({0} degree Fahrenheit),
						'other' => q({0} degree Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(mga degree Fahrenheit),
						'one' => q({0} degree Fahrenheit),
						'other' => q({0} degree Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(mga kelvin),
						'one' => q({0} ka kelvin),
						'other' => q({0} ka mga kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(mga kelvin),
						'one' => q({0} ka kelvin),
						'other' => q({0} ka mga kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(mga newton-meter),
						'one' => q({0} N⋅m),
						'other' => q({0} ka mga newton-meter),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(mga newton-meter),
						'one' => q({0} N⋅m),
						'other' => q({0} ka mga newton-meter),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pound-feet),
						'one' => q({0} ka pound-force-foot),
						'other' => q({0} ka mga pound-force-foot),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pound-feet),
						'one' => q({0} ka pound-force-foot),
						'other' => q({0} ka mga pound-force-foot),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(mga acre-foot),
						'one' => q({0} ka acre-foot),
						'other' => q({0} ka mga acre-foot),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(mga acre-foot),
						'one' => q({0} ka acre-foot),
						'other' => q({0} ka mga acre-foot),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(mga barrel),
						'one' => q({0} ka barrel),
						'other' => q({0} ka mga barrel),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(mga barrel),
						'one' => q({0} ka barrel),
						'other' => q({0} ka mga barrel),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(mga centiliter),
						'one' => q({0} ka centiliter),
						'other' => q({0} ka mga centiliter),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(mga centiliter),
						'one' => q({0} ka centiliter),
						'other' => q({0} ka mga centiliter),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(mga cubic centimeter),
						'one' => q({0} ka cubic centimeter),
						'other' => q({0} ka mga cubic centimeter),
						'per' => q({0} kada cubic centimeter),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(mga cubic centimeter),
						'one' => q({0} ka cubic centimeter),
						'other' => q({0} ka mga cubic centimeter),
						'per' => q({0} kada cubic centimeter),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(mga cubic foot),
						'one' => q({0} ka cubic foot),
						'other' => q({0} ka mga cubic foot),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(mga cubic foot),
						'one' => q({0} ka cubic foot),
						'other' => q({0} ka mga cubic foot),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(mga cubic inch),
						'one' => q({0} ka cubic inch),
						'other' => q({0} ka mga cubic inch),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(mga cubic inch),
						'one' => q({0} ka cubic inch),
						'other' => q({0} ka mga cubic inch),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(mga cubic kilometer),
						'one' => q({0} ka cubic kilometer),
						'other' => q({0} ka mga cubic kilometer),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(mga cubic kilometer),
						'one' => q({0} ka cubic kilometer),
						'other' => q({0} ka mga cubic kilometer),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(mga cubic meter),
						'one' => q({0} ka cubic meter),
						'other' => q({0} ka mga cubic meter),
						'per' => q({0} kada cubic meter),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(mga cubic meter),
						'one' => q({0} ka cubic meter),
						'other' => q({0} ka mga cubic meter),
						'per' => q({0} kada cubic meter),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mga cubic mile),
						'one' => q({0} ka cubic mile),
						'other' => q({0} ka mga cubic mile),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mga cubic mile),
						'one' => q({0} ka cubic mile),
						'other' => q({0} ka mga cubic mile),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(mga cubic yard),
						'one' => q({0} ka cubic yard),
						'other' => q({0} ka mga cubic yard),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(mga cubic yard),
						'one' => q({0} ka cubic yard),
						'other' => q({0} ka mga cubic yard),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0} ka tasa),
						'other' => q({0} ka mga tasa),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0} ka tasa),
						'other' => q({0} ka mga tasa),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mga metric cup),
						'one' => q({0} ka metric cup),
						'other' => q({0} ka metric cup),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mga metric cup),
						'one' => q({0} ka metric cup),
						'other' => q({0} ka metric cup),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(mga deciliter),
						'one' => q({0} ka deciliter),
						'other' => q({0} ka mga deciliter),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(mga deciliter),
						'one' => q({0} ka deciliter),
						'other' => q({0} ka mga deciliter),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(kutsarang panghinam-is),
						'one' => q({0} ka kutsarang panghinam-is),
						'other' => q({0} ka kutsarang panghinam-is),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(kutsarang panghinam-is),
						'one' => q({0} ka kutsarang panghinam-is),
						'other' => q({0} ka kutsarang panghinam-is),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Imp. nga kutsarang panghinam-is),
						'one' => q({0} ka Imp. nga kutsarang panghinam-is),
						'other' => q({0} ka Imp. nga kutsarang panghinam-is),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Imp. nga kutsarang panghinam-is),
						'one' => q({0} ka Imp. nga kutsarang panghinam-is),
						'other' => q({0} ka Imp. nga kutsarang panghinam-is),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram),
						'one' => q({0} ka dram),
						'other' => q({0} ka dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram),
						'one' => q({0} ka dram),
						'other' => q({0} ka dram),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(mga fluid ounce),
						'one' => q({0} ka fluid ounce),
						'other' => q({0} ka mga fluid ounce),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(mga fluid ounce),
						'one' => q({0} ka fluid ounce),
						'other' => q({0} ka mga fluid ounce),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(mga Imp. fluid ounce),
						'one' => q({0} ka Imp. fluid ounce),
						'other' => q({0} ka mga Imp. fluid ounce),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(mga Imp. fluid ounce),
						'one' => q({0} ka Imp. fluid ounce),
						'other' => q({0} ka mga Imp. fluid ounce),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(mga gallon),
						'one' => q({0} ka gallon),
						'other' => q({0} ka mga gallon),
						'per' => q({0} kada gallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(mga gallon),
						'one' => q({0} ka gallon),
						'other' => q({0} ka mga gallon),
						'per' => q({0} kada gallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(mga Imp. gallon),
						'one' => q({0} ka Imp. gallon),
						'other' => q({0} ka mga Imp. gallon),
						'per' => q({0} kada Imp. gallon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(mga Imp. gallon),
						'one' => q({0} ka Imp. gallon),
						'other' => q({0} ka mga Imp. gallon),
						'per' => q({0} kada Imp. gallon),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(mga hectoliter),
						'one' => q({0} ka hectoliter),
						'other' => q({0} ka mga hectoliter),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(mga hectoliter),
						'one' => q({0} ka hectoliter),
						'other' => q({0} ka mga hectoliter),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} ka litro),
						'other' => q({0} ka mga litro),
						'per' => q({0} kada litro),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} ka litro),
						'other' => q({0} ka mga litro),
						'per' => q({0} kada litro),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(mga megaliter),
						'one' => q({0} ka megaliter),
						'other' => q({0} ka mga megaliter),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(mga megaliter),
						'one' => q({0} ka megaliter),
						'other' => q({0} ka mga megaliter),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mga milliliter),
						'one' => q({0} ka milliliter),
						'other' => q({0} ka mga milliliter),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mga milliliter),
						'one' => q({0} ka milliliter),
						'other' => q({0} ka mga milliliter),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'one' => q({0} ka pint),
						'other' => q({0} ka mga pint),
					},
					# Core Unit Identifier
					'pint' => {
						'one' => q({0} ka pint),
						'other' => q({0} ka mga pint),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(mga metric pint),
						'one' => q({0} ka metric pint),
						'other' => q({0} ka mga metric pint),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(mga metric pint),
						'one' => q({0} ka metric pint),
						'other' => q({0} ka mga metric pint),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(mga quart),
						'one' => q({0} ka quart),
						'other' => q({0} ka mga quart),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(mga quart),
						'one' => q({0} ka quart),
						'other' => q({0} ka mga quart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp. quart),
						'one' => q({0} ka Imp. quart),
						'other' => q({0} ka Imp. quart),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp. quart),
						'one' => q({0} ka Imp. quart),
						'other' => q({0} ka Imp. quart),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(mga kutsara),
						'one' => q({0} ka kutsara),
						'other' => q({0} ka kutsara),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(mga kutsara),
						'one' => q({0} ka kutsara),
						'other' => q({0} ka kutsara),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(mga kutsarita),
						'one' => q({0} ka kutsarita),
						'other' => q({0} ka mga kutsarita),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(mga kutsarita),
						'one' => q({0} ka kutsarita),
						'other' => q({0} ka mga kutsarita),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(adlaw),
						'one' => q({0} adlaw),
						'other' => q({0} adlaw),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(adlaw),
						'one' => q({0} adlaw),
						'other' => q({0} adlaw),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(oras),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(oras),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(msec),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(msec),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minuto),
						'one' => q({0} minuto),
						'other' => q({0} minuto),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minuto),
						'one' => q({0} minuto),
						'other' => q({0} minuto),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(buwan),
						'one' => q({0} buwan),
						'other' => q({0} buwan),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(buwan),
						'one' => q({0} buwan),
						'other' => q({0} buwan),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(segundo),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(segundo),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(semana),
						'one' => q({0} semana),
						'other' => q({0}w),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(semana),
						'one' => q({0} semana),
						'other' => q({0}w),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(tuig),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(tuig),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramo),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramo),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/hr),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/hr),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litro),
						'one' => q({0}L),
						'other' => q({0}L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litro),
						'one' => q({0}L),
						'other' => q({0}L),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direksyon),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direksyon),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(mga metro/sec²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(mga metro/sec²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(mga arcmin),
						'one' => q({0} ka arcmin),
						'other' => q({0} ka mga arcmin),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(mga arcmin),
						'one' => q({0} ka arcmin),
						'other' => q({0} ka mga arcmin),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(mga arcsec),
						'one' => q({0} ka arcsec),
						'other' => q({0} ka mga arcsec),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(mga arcsec),
						'one' => q({0} ka arcsec),
						'other' => q({0} ka mga arcsec),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(mga degree),
						'one' => q({0} deg),
						'other' => q({0} deg),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(mga degree),
						'one' => q({0} deg),
						'other' => q({0} deg),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(mga radian),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(mga radian),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(mga acre),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(mga acre),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(mga dunam),
						'one' => q({0} ka dunam),
						'other' => q({0} ka dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(mga dunam),
						'one' => q({0} ka dunam),
						'other' => q({0} ka dunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(mga ektarya),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(mga ektarya),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(mga sq foot),
						'one' => q({0} sq ft),
						'other' => q({0} sq ft),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(mga sq foot),
						'one' => q({0} sq ft),
						'other' => q({0} sq ft),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(mga inch²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(mga inch²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(mga metro²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(mga metro²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mga milya kwadrado),
						'one' => q({0} sq mi),
						'other' => q({0} sq mi),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mga milya kwadrado),
						'one' => q({0} sq mi),
						'other' => q({0} sq mi),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(mga yard²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(mga yard²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(mga karat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(mga karat),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(millimol/litro),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(millimol/litro),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mole),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mole),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(porsyento),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(porsyento),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(permille),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(permille),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(mga part/million),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(mga part/million),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(permyriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(permyriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(mga litro/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(mga litro/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mga milya/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mga milya/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mga milya/gal Imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mga milya/gal Imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0} ka bit),
						'other' => q({0} ka bit),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0} ka bit),
						'other' => q({0} ka bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'one' => q({0} ka byte),
						'other' => q({0} ka byte),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0} ka byte),
						'other' => q({0} ka byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GByte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GByte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kByte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kByte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MByte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MByte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PByte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PByte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TByte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TByte),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(mga adlaw),
						'one' => q({0} ka adlaw),
						'other' => q({0} ka adlaw),
						'per' => q({0}/adlaw),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(mga adlaw),
						'one' => q({0} ka adlaw),
						'other' => q({0} ka adlaw),
						'per' => q({0}/adlaw),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(mga oras),
						'one' => q({0} ka oras),
						'other' => q({0} ka oras),
						'per' => q({0}/oras),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(mga oras),
						'one' => q({0} ka oras),
						'other' => q({0} ka oras),
						'per' => q({0}/oras),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsecs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsecs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(mga millisec),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(mga millisec),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(mga minuto),
						'one' => q({0} ka minuto),
						'other' => q({0} ka minuto),
						'per' => q({0}/minuto),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(mga minuto),
						'one' => q({0} ka minuto),
						'other' => q({0} ka minuto),
						'per' => q({0}/minuto),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mga buwan),
						'one' => q({0} ka buwan),
						'other' => q({0} ka buwan),
						'per' => q({0}/buwan),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mga buwan),
						'one' => q({0} ka buwan),
						'other' => q({0} ka buwan),
						'per' => q({0}/buwan),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(mga nanosec),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(mga nanosec),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(mga segundo),
						'one' => q({0}segundo),
						'other' => q({0}segundo),
						'per' => q({0}/segundo),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(mga segundo),
						'one' => q({0}segundo),
						'other' => q({0}segundo),
						'per' => q({0}/segundo),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(mga semana),
						'one' => q({0} ka semana),
						'other' => q({0} ka semana),
						'per' => q({0}/semana),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(mga semana),
						'one' => q({0} ka semana),
						'other' => q({0} ka semana),
						'per' => q({0}/semana),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(mga tuig),
						'one' => q({0} ka tuig),
						'other' => q({0} ka tuig),
						'per' => q({0}/tuig),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(mga tuig),
						'one' => q({0} ka tuig),
						'other' => q({0} ka tuig),
						'per' => q({0}/tuig),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(mga amp),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(mga amp),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mga milliamp),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mga milliamp),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(mga ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(mga ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(mga boltahe),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(mga boltahe),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(electronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(electronvolt),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(mga joule),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(mga joule),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kW-hour),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kW-hour),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q({0} ka US therm),
						'other' => q({0} ka mga US therm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q({0} ka US therm),
						'other' => q({0} ka mga US therm),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pound-force),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pound-force),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'one' => q({0} ka em),
						'other' => q({0} ka em),
					},
					# Core Unit Identifier
					'em' => {
						'one' => q({0} ka em),
						'other' => q({0} ka em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(mga megapixel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(mga megapixel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(mga pixel),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(mga pixel),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(mga piye),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(mga piye),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(mga pulgada),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(mga pulgada),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(mga light yr),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(mga light yr),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mga μmeter),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mga μmeter),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mga milya),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mga milya),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(mga parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(mga parsec),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(mga point),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(mga point),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(mga solar radius),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(mga solar radius),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(mga yarda),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(mga yarda),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(mga solar luminosity),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(mga solar luminosity),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(mga carat),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(mga carat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(mga dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(mga dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(mga mass sa Earth),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(mga mass sa Earth),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(mga gramo),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(mga gramo),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(mga pound),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(mga pound),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(mga solar mass),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(mga solar mass),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(mga tonelada),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(mga tonelada),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(mga watt),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(mga watt),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q({0} ka bar),
						'other' => q({0} ka bar),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q({0} ka bar),
						'other' => q({0} ka bar),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0} ka mbar),
						'other' => q({0} ka mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0} ka mbar),
						'other' => q({0} ka mbar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/oras),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/oras),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(mga metro/seg),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(mga metro/seg),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mga milya/oras),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mga milya/oras),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(deg. C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(deg. C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(deg. F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(deg. F),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barrel),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barrel),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(mga foot³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(mga foot³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(mga inch³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(mga inch³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(mga yard³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(mga yard³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(mga tasa),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(mga tasa),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'one' => q({0} ka dram fl),
						'other' => q({0} ka dram fl),
					},
					# Core Unit Identifier
					'dram' => {
						'one' => q({0} ka dram fl),
						'other' => q({0} ka dram fl),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'one' => q({0} ka drop),
						'other' => q({0} ka drop),
					},
					# Core Unit Identifier
					'drop' => {
						'one' => q({0} ka drop),
						'other' => q({0} ka drop),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'one' => q({0} ka jigger),
						'other' => q({0} ka jigger),
					},
					# Core Unit Identifier
					'jigger' => {
						'one' => q({0} ka jigger),
						'other' => q({0} ka jigger),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(mga litro),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(mga litro),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'one' => q({0} ka pinch),
						'other' => q({0} ka pinch),
					},
					# Core Unit Identifier
					'pinch' => {
						'one' => q({0} ka pinch),
						'other' => q({0} ka pinch),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(mga pint),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(mga pint),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qts),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qts),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(kutsarita),
						'one' => q({0} ka kutsarita),
						'other' => q({0} ka kutsarita),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(kutsarita),
						'one' => q({0} ka kutsarita),
						'other' => q({0} ka kutsarita),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:oo|o|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:dili|d|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, ug {1}),
				2 => q({0} ug {1}),
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
				'currency' => q(United Arab Emirates Dirham),
				'one' => q(UAE dirham),
				'other' => q(UAE dirhams),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghan Afghani),
				'one' => q(Afghan Afghani),
				'other' => q(Afghan Afghanis),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Albanian Lek),
				'one' => q(Albanian lek),
				'other' => q(Albanian leke),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armenian Dram),
				'one' => q(Armenian dram),
				'other' => q(Armenian drams),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Netherlands Antillean Guilder),
				'one' => q(Netherlands Antillean guilder),
				'other' => q(Mga Netherlands Antillean guilder),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angolan Kwanza),
				'one' => q(Angolan kwanza),
				'other' => q(Angolan kwanzas),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentine Peso),
				'one' => q(Argentine peso),
				'other' => q(Argentine pesos),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Australian Dollar),
				'one' => q(Australian dollar),
				'other' => q(Australian dollars),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruban Florin),
				'one' => q(Aruban florin),
				'other' => q(Aruban florin),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Azerbaijani Manat),
				'one' => q(Azerbaijani manat),
				'other' => q(Azerbaijani manats),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosnia-Herzegovina Convertible Mark),
				'one' => q(Bosnia-Herzegovina convertible mark),
				'other' => q(Bosnia-Herzegovina convertible marks),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbadian Dollar),
				'one' => q(Barbadian dollar),
				'other' => q(Mga Barbadian dollar),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bangladeshi Taka),
				'one' => q(Bangladeshi taka),
				'other' => q(Bangladeshi takas),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgarian Lev),
				'one' => q(Bulgarian lev),
				'other' => q(Bulgarian leva),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahraini Dinar),
				'one' => q(Bahraini dinar),
				'other' => q(Bahraini dinars),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundian Franc),
				'one' => q(Burundian franc),
				'other' => q(Burundian francs),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermudan Dollar),
				'one' => q(Bermudan dollar),
				'other' => q(Mga Bermudan dollar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Brunei Dollar),
				'one' => q(Brunei dollar),
				'other' => q(Brunei dollars),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bolivian Boliviano),
				'one' => q(Bolivian boliviano),
				'other' => q(Bolivian bolivianos),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brazilian Real),
				'one' => q(Brazilian real),
				'other' => q(Brazilian reals),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahamian Dollar),
				'one' => q(Bahamian dollar),
				'other' => q(Mga Bahamian dollar),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Bhutanese Ngultrum),
				'one' => q(Bhutanese ngultrum),
				'other' => q(Bhutanese ngultrums),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botswanan Pula),
				'one' => q(Botswanan pula),
				'other' => q(Botswanan pulas),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Belarusian Ruble),
				'one' => q(Belarusian ruble),
				'other' => q(Belarusian rubles),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belize Dollar),
				'one' => q(Belize dollar),
				'other' => q(Mga Belize dollar),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Canadian Dollar),
				'one' => q(Canadian dollar),
				'other' => q(Mga Canadian dollar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Congolese Franc),
				'one' => q(Congolese franc),
				'other' => q(Congolese francs),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Swiss Franc),
				'one' => q(Swiss franc),
				'other' => q(Swiss francs),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Chilean Peso),
				'one' => q(Chilean peso),
				'other' => q(Chilean pesos),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Chinese Yuan \(offshore\)),
				'one' => q(Chinese yuan \(offshore\)),
				'other' => q(Chinese yuan \(offshore\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Chinese Yuan),
				'one' => q(Chinese yuan),
				'other' => q(Chinese yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Colombian Peso),
				'one' => q(Colombian peso),
				'other' => q(Colombian pesos),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Costa Rican Colon),
				'one' => q(Costa Rican colon),
				'other' => q(Mga Costa Rican colon),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Cuban Convertible Peso),
				'one' => q(Cuban convertible peso),
				'other' => q(Mga Cuban convertible peso),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Cuban Peso),
				'one' => q(Cuban peso),
				'other' => q(Mga Cuban peso),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Cape Verdean Escudo),
				'one' => q(Cape Verdean escudo),
				'other' => q(Cape Verdean escudos),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Czech Koruna),
				'one' => q(Czech koruna),
				'other' => q(Czech korunas),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Djiboutian Franc),
				'one' => q(Djiboutian franc),
				'other' => q(Djiboutian francs),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Danish Krone),
				'one' => q(Danish krone),
				'other' => q(Danish kroner),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominican Peso),
				'one' => q(Dominican peso),
				'other' => q(Mga Dominican peso),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algerian Dinar),
				'one' => q(Algerian dinar),
				'other' => q(Algerian dinars),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Egyptian Pound),
				'one' => q(Egyptian pound),
				'other' => q(Egyptian pounds),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritrean Nakfa),
				'one' => q(Eritrean nakfa),
				'other' => q(Eritrean nakfas),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Ethiopian Birr),
				'one' => q(Ethiopian birr),
				'other' => q(Ethiopian birrs),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'one' => q(euro),
				'other' => q(euros),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fijian Dollar),
				'one' => q(Fijian dollar),
				'other' => q(Fijian dollars),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Falkland Islands Pound),
				'one' => q(Falkland Islands pound),
				'other' => q(Falkland Islands pounds),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(British Pound),
				'one' => q(British pound),
				'other' => q(British pounds),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Georgian Lari),
				'one' => q(Georgian lari),
				'other' => q(Georgian laris),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Ghanaian Cedi),
				'one' => q(Ghanaian cedi),
				'other' => q(Ghanaian cedis),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltar Pound),
				'one' => q(Gibraltar pound),
				'other' => q(Gibraltar pounds),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambian Dalasi),
				'one' => q(Gambian dalasi),
				'other' => q(Gambian dalasis),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Guinean Franc),
				'one' => q(Guinean franc),
				'other' => q(Guinean francs),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Guatemalan Quetzal),
				'one' => q(Guatemalan quetzal),
				'other' => q(Mga Guatemalan quetzal),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Guyanaese Dollar),
				'one' => q(Guyanaese dollar),
				'other' => q(Guyanaese dollars),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hong Kong Dollar),
				'one' => q(Hong Kong dollar),
				'other' => q(Hong Kong dollars),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Honduran Lempira),
				'one' => q(Honduran lempira),
				'other' => q(Mga Honduran lempira),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Croatian Kuna),
				'one' => q(Croatian kuna),
				'other' => q(Croatian kunas),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haitian Gourde),
				'one' => q(Haitian gourde),
				'other' => q(Mga Haitian gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Hungarian Forint),
				'one' => q(Hungarian forint),
				'other' => q(Hungarian forints),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indonesian Rupiah),
				'one' => q(Indonesian rupiah),
				'other' => q(Indonesian rupiahs),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Israeli New Shekel),
				'one' => q(Israeli new shekel),
				'other' => q(Israeli new shekels),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indian Rupee),
				'one' => q(Indian rupee),
				'other' => q(Indian rupees),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Iraqi Dinar),
				'one' => q(Iraqi dinar),
				'other' => q(Iraqi dinars),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Iranian Rial),
				'one' => q(Iranian rial),
				'other' => q(Iranian rials),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Icelandic Krona),
				'one' => q(Icelandic krona),
				'other' => q(Icelandic kronur),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaican Dollar),
				'one' => q(Jamaican dollar),
				'other' => q(Mga Jamaican dollar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jordanian Dinar),
				'one' => q(Jordanian dinar),
				'other' => q(Jordanian dinars),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Japanese Yen),
				'one' => q(Japanese yen),
				'other' => q(Japanese yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Kenyan Shilling),
				'one' => q(Kenyan shilling),
				'other' => q(Kenyan shillings),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kyrgystani Som),
				'one' => q(Kyrgystani som),
				'other' => q(Kyrgystani soms),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Cambodian Riel),
				'one' => q(Cambodian riel),
				'other' => q(Cambodian riels),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Comorian Franc),
				'one' => q(Comorian franc),
				'other' => q(Comorian francs),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(North Korean Won),
				'one' => q(North Korean won),
				'other' => q(North Korean won),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(South Korean Won),
				'one' => q(South Korean won),
				'other' => q(South Korean won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuwaiti Dinar),
				'one' => q(Kuwaiti dinar),
				'other' => q(Kuwaiti dinars),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Cayman Islands Dollar),
				'one' => q(Cayman Islands dollar),
				'other' => q(Mga Cayman Islands dollar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kazakhstani Tenge),
				'one' => q(Kazakhstani tenge),
				'other' => q(Kazakhstani tenges),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laotian Kip),
				'one' => q(Laotian kip),
				'other' => q(Laotian kips),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Lebanese Pound),
				'one' => q(Lebanese pound),
				'other' => q(Lebanese pounds),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Sri Lankan Rupee),
				'one' => q(Sri Lankan rupee),
				'other' => q(Sri Lankan rupees),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberian Dollar),
				'one' => q(Liberian dollar),
				'other' => q(Liberian dollars),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesotho Loti),
				'one' => q(Lesotho loti),
				'other' => q(Lesotho lotis),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libyan Dinar),
				'one' => q(Libyan dinar),
				'other' => q(Libyan dinars),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Moroccan Dirham),
				'one' => q(Moroccan dirham),
				'other' => q(Moroccan dirhams),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldovan Leu),
				'one' => q(Moldovan leu),
				'other' => q(Moldovan lei),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Malagasy Ariary),
				'one' => q(Malagasy ariary),
				'other' => q(Malagasy ariaries),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Macedonian Denar),
				'one' => q(Macedonian denar),
				'other' => q(Macedonian denari),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Myanmar Kyat),
				'one' => q(Myanmar kyat),
				'other' => q(Myanmar kyats),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongolian Tugrik),
				'one' => q(Mongolian tugrik),
				'other' => q(Mongolian tugriks),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Macanese Pataca),
				'one' => q(Macanese pataca),
				'other' => q(Macanese patacas),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mauritanian Ouguiya),
				'one' => q(Mauritanian ouguiya),
				'other' => q(Mauritanian ouguiyas),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mauritian Rupee),
				'one' => q(Mauritian rupee),
				'other' => q(Mauritian rupees),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Maldivian Rufiyaa),
				'one' => q(Maldivian rufiyaa),
				'other' => q(Maldivian rufiyaas),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawian Kwacha),
				'one' => q(Malawian kwacha),
				'other' => q(Malawian kwachas),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Mexican Peso),
				'one' => q(Mexican peso),
				'other' => q(Mga Mexican peso),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Malaysian Ringgit),
				'one' => q(Malaysian ringgit),
				'other' => q(Malaysian ringgits),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mozambican Metical),
				'one' => q(Mozambican metical),
				'other' => q(Mozambican meticals),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibian Dollar),
				'one' => q(Namibian dollar),
				'other' => q(Namibian dollars),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigerian Naira),
				'one' => q(Nigerian naira),
				'other' => q(Nigerian nairas),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nicaraguan Cordoba),
				'one' => q(Nicaraguan cordoba),
				'other' => q(Mga Nicaraguan cordoba),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norwegian Krone),
				'one' => q(Norwegian krone),
				'other' => q(Norwegian kroner),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepalese Rupee),
				'one' => q(Nepalese rupee),
				'other' => q(Nepalese rupees),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(New Zealand Dollar),
				'one' => q(New Zealand dollar),
				'other' => q(New Zealand dollars),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Omani Rial),
				'one' => q(Omani rial),
				'other' => q(Omani rials),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panamanian Balboa),
				'one' => q(Panamanian balboa),
				'other' => q(Mga Panamanian balboa),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peruvian Sol),
				'one' => q(Peruvian sol),
				'other' => q(Peruvian soles),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papua New Guinean Kina),
				'one' => q(Papua New Guinean kina),
				'other' => q(Papua New Guinean kina),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Philippine Peso),
				'one' => q(Philippine peso),
				'other' => q(Philippine pesos),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakistani Rupee),
				'one' => q(Pakistani rupee),
				'other' => q(Pakistani rupees),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Polish Zloty),
				'one' => q(Polish zloty),
				'other' => q(Polish zlotys),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraguayan Guarani),
				'one' => q(Paraguayan guarani),
				'other' => q(Paraguayan guaranis),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Qatari Rial),
				'one' => q(Qatari rial),
				'other' => q(Qatari riyals),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Romanian Leu),
				'one' => q(Romanian leu),
				'other' => q(Romanian lei),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serbian Dinar),
				'one' => q(Serbian dinar),
				'other' => q(Serbian dinars),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Russian Ruble),
				'one' => q(Russian ruble),
				'other' => q(Russian rubles),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Rwandan Franc),
				'one' => q(Rwandan franc),
				'other' => q(Rwandan francs),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudi Riyal),
				'one' => q(Saudi riyal),
				'other' => q(Saudi riyals),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Solomon Islands Dollar),
				'one' => q(Solomon Islands dollar),
				'other' => q(Solomon Islands dollars),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seychellois Rupee),
				'one' => q(Seychellois rupee),
				'other' => q(Seychellois rupees),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudanese Pound),
				'one' => q(Sudanese pound),
				'other' => q(Sudanese pounds),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Swedish Krona),
				'one' => q(Swedish krona),
				'other' => q(Swedish kronor),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singapore Dollar),
				'one' => q(Singapore dollar),
				'other' => q(Singapore dollars),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St. Helena Pound),
				'one' => q(St. Helena pound),
				'other' => q(St. Helena pounds),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sierra Leonean Leone),
				'one' => q(Sierra Leonean leone),
				'other' => q(Sierra Leonean leones),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra Leonean Leone \(1964—2022\)),
				'one' => q(Sierra Leonean leone \(1964—2022\)),
				'other' => q(Sierra Leonean leones \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somali Shilling),
				'one' => q(Somali shilling),
				'other' => q(Somali shillings),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinamese Dollar),
				'one' => q(Surinamese dollar),
				'other' => q(Surinamese dollars),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(South Sudanese Pound),
				'one' => q(South Sudanese pound),
				'other' => q(South Sudanese pounds),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Sao Tome & Principe Dobra),
				'one' => q(Sao Tome & Principe dobra),
				'other' => q(São Tomé & Príncipe dobras),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Syrian Pound),
				'one' => q(Syrian pound),
				'other' => q(Syrian pounds),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Swazi Lilangeni),
				'one' => q(Swazi lilangeni),
				'other' => q(Swazi emalangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Thai Baht),
				'one' => q(Thai baht),
				'other' => q(Thai baht),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tajikistani Somoni),
				'one' => q(Tajikistani somoni),
				'other' => q(Tajikistani somonis),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Turkmenistani Manat),
				'one' => q(Turkmenistani manat),
				'other' => q(Turkmenistani manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunisian Dinar),
				'one' => q(Tunisian dinar),
				'other' => q(Tunisian dinars),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tongan Paʻanga),
				'one' => q(Tongan paʻanga),
				'other' => q(Tongan paʻanga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Turkish Lira),
				'one' => q(Turkish lira),
				'other' => q(Turkish Lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad & Tobago Dollar),
				'one' => q(Trinidad & Tobago dollar),
				'other' => q(Mga Trinidad & Tobago dollar),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(New Taiwan Dollar),
				'one' => q(New Taiwan dollar),
				'other' => q(New Taiwan dollars),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzanian Shilling),
				'one' => q(Tanzanian shilling),
				'other' => q(Tanzanian shillings),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ukrainian Hryvnia),
				'one' => q(Ukrainian hryvnia),
				'other' => q(Ukrainian hryvnias),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Ugandan Shilling),
				'one' => q(Ugandan shilling),
				'other' => q(Ugandan shillings),
			},
		},
		'USD' => {
			symbol => 'US $',
			display_name => {
				'currency' => q(US Dollar),
				'one' => q(US dollar),
				'other' => q(Mga US dollar),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruguayan Peso),
				'one' => q(Uruguayan peso),
				'other' => q(Uruguayan pesos),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Uzbekistani Som),
				'one' => q(Uzbekistani som),
				'other' => q(Uzbekistani som),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venezuelan Bolivar),
				'one' => q(Venezuelan bolivar),
				'other' => q(Venezuelan bolívars),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Vietnamese Dong),
				'one' => q(Vietnamese dong),
				'other' => q(Vietnamese dong),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatu Vatu),
				'one' => q(Vanuatu vatu),
				'other' => q(Vanuatu vatus),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoan Tala),
				'one' => q(Samoan tala),
				'other' => q(Samoan tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Central African CFA Franc),
				'one' => q(Central African CFA franc),
				'other' => q(Central African CFA francs),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(East Caribbean Dollar),
				'one' => q(East Caribbean dollar),
				'other' => q(Mga East Caribbean dollar),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(West African CFA Franc),
				'one' => q(West African CFA franc),
				'other' => q(West African CFA francs),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP Franc),
				'one' => q(CFP franc),
				'other' => q(CFP francs),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Wala Nailhi nga Kwarta),
				'one' => q(\(wala mailhi nga yunit sa kwarta\)),
				'other' => q(\(wala mailhi nga kwarta\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Yemeni Rial),
				'one' => q(Yemeni rial),
				'other' => q(Yemeni rials),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(South African Rand),
				'one' => q(South African rand),
				'other' => q(South African rand),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Zambian Kwacha),
				'one' => q(Zambian kwacha),
				'other' => q(Zambian kwachas),
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
							'Ene',
							'Peb',
							'Mar',
							'Abr',
							'May',
							'Hun',
							'Hul',
							'Ago',
							'Sep',
							'Okt',
							'Nob',
							'Dis'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Enero',
							'Pebrero',
							'Marso',
							'Abril',
							'Mayo',
							'Hunyo',
							'Hulyo',
							'Agosto',
							'Septiyembre',
							'Oktubre',
							'Nobyembre',
							'Disyembre'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'E',
							'P',
							'M',
							'A',
							'M',
							'H',
							'H',
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
						mon => 'Lun',
						tue => 'Mar',
						wed => 'Miy',
						thu => 'Huw',
						fri => 'Biy',
						sat => 'Sab',
						sun => 'Dom'
					},
					wide => {
						mon => 'Lunes',
						tue => 'Martes',
						wed => 'Miyerkules',
						thu => 'Huwebes',
						fri => 'Biyernes',
						sat => 'Sabado',
						sun => 'Domingo'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'H',
						fri => 'B',
						sat => 'S',
						sun => 'D'
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
					wide => {0 => 'unang quarter',
						1 => 'ika-2 nga quarter',
						2 => 'ika-3 nga quarter',
						3 => 'ika-4 nga quarter'
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
				'0' => 'BC',
				'1' => 'AD'
			},
			wide => {
				'0' => 'Sa Wala Pa Si Kristo',
				'1' => 'Anno Domini'
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
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d, y},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{M/d/yy},
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
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			GyMd => q{M/d/y GGGGG},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			Md => q{M/d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, M/d/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, MMM d, y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{MMM d, y G},
			yyyyMd => q{M/d/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			GyMd => q{M/d/y GGGGG},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMW => q{'semana' W 'sa' MMMM},
			Md => q{M/d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{MMM d, y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'semana' w 'sa' Y},
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
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, M/d/y GGGGG – E, M/d/y GGGGG},
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				d => q{MMM d – d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d – d},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			yMd => {
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, M/d/y GGGGG – E, M/d/y GGGGG},
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				d => q{MMM d – d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d – d},
			},
			h => {
				h => q{h – h a},
			},
			hm => {
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y},
				d => q{E, M/d/y – E, M/d/y},
				y => q{E, M/d/y – E, M/d/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y},
				d => q{E, MMM d – E, MMM d, y},
				y => q{E, MMM d, y – E, MMM d, y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y},
				d => q{MMM d – d, y},
				y => q{MMM d, y – MMM d, y},
			},
			yMd => {
				M => q{M/d/y – M/d/y},
				d => q{M/d/y – M/d/y},
				y => q{M/d/y – M/d/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q(GMT {0}),
		regionFormat => q(Oras sa {0}),
		regionFormat => q(Daylight Time sa {0}),
		regionFormat => q(Tamdanang Oras sa {0}),
		fallbackFormat => q({1} {0}),
		'Afghanistan' => {
			long => {
				'standard' => q#Oras sa Afghanistan#,
			},
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Oras sa Central Africa#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Oras sa East Africa#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Tamdanang Oras sa South Africa#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa West Africa#,
				'generic' => q#Oras sa West Africa#,
				'standard' => q#Tamdanang Oras sa West Africa#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Daylight Time sa Alaska#,
				'generic' => q#Oras sa Alaska#,
				'standard' => q#Tamdanang Oras sa Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Amazon#,
				'generic' => q#Oras sa Amazon#,
				'standard' => q#Tamdanang Oras sa Amazon#,
			},
		},
		'America_Central' => {
			long => {
				'daylight' => q#Central Daylight Time#,
				'generic' => q#Central Time#,
				'standard' => q#Central Standard Time#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Eastern Daylight Time#,
				'generic' => q#Eastern Time#,
				'standard' => q#Eastern Standard Time#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Mountain Daylight Time#,
				'generic' => q#Mountain Time#,
				'standard' => q#Mountain Standard Time#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pacific Daylight Time#,
				'generic' => q#Pacific Time#,
				'standard' => q#Pacific Standard Time#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Daylight Time sa Apia#,
				'generic' => q#Oras sa Apia#,
				'standard' => q#Tamdanang Oras sa Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Arabia#,
				'generic' => q#Oras sa Arabia#,
				'standard' => q#Tamdanang Oras sa Arabia#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Argentina#,
				'generic' => q#Oras sa Argentina#,
				'standard' => q#Tamdanang Oras sa Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Western Argentina#,
				'generic' => q#Oras sa Western Argentina#,
				'standard' => q#Tamdanang Oras sa Western Argentina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Armenia#,
				'generic' => q#Oras sa Armenia#,
				'standard' => q#Tamdanang Oras sa Armenia#,
			},
		},
		'Asia/Saigon' => {
			exemplarCity => q#Siyudad sa Ho Chi Minh#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantic Daylight Time#,
				'generic' => q#Atlantic Time#,
				'standard' => q#Atlantic Standard Time#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Central Australia#,
				'generic' => q#Oras sa Central Australia#,
				'standard' => q#Tamdanang Oras sa Central Australia#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Central Western Australia#,
				'generic' => q#Oras sa Central Western Australia#,
				'standard' => q#Tamdanang Oras sa Central Western Australia#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Eastern Australia#,
				'generic' => q#Oras sa Eastern Australia#,
				'standard' => q#Tamdanang Oras sa Eastern Australia#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Western Australia#,
				'generic' => q#Oras sa Western Australia#,
				'standard' => q#Tamdanang Oras sa Western Australia#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Azerbaijan#,
				'generic' => q#Oras sa Azerbaijan#,
				'standard' => q#Tamdanang Oras sa Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Azores#,
				'generic' => q#Oras sa Azores#,
				'standard' => q#Tamdanang Oras sa Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Bangladesh#,
				'generic' => q#Oras sa Bangladesh#,
				'standard' => q#Tamdanang Oras sa Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Oras sa Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Oras sa Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Brasilia#,
				'generic' => q#Oras sa Brasilia#,
				'standard' => q#Tamdanang Oras sa Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Oras sa Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Cape Verde#,
				'generic' => q#Oras sa Cape Verde#,
				'standard' => q#Tamdanang Oras sa Cape Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Tamdanang Oras sa Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Chatham#,
				'generic' => q#Oras sa Chatham#,
				'standard' => q#Tamdanang Oras sa Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Chile#,
				'generic' => q#Oras sa Chile#,
				'standard' => q#Tamdanang Oras sa Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Tsina#,
				'generic' => q#Oras sa Tsina#,
				'standard' => q#Tamdanang Oras sa Tsina#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Choibalsan#,
				'generic' => q#Oras sa Choibalsan#,
				'standard' => q#Tamdanang Oras sa Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Oras sa Christmas Island#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Oras sa Cocos Islands#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Colombia#,
				'generic' => q#Oras sa Colombia#,
				'standard' => q#Tamdanang Oras sa Colombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Katungang Oras sa Tag-init sa Cook Islands#,
				'generic' => q#Oras sa Cook Islands#,
				'standard' => q#Tamdanang Oras sa Cook Islands#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Cuba#,
				'generic' => q#Oras sa Cuba#,
				'standard' => q#Tamdanang Oras sa Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Oras sa Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Oras sa Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Oras sa East Timor#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Easter Island#,
				'generic' => q#Oras sa Easter Island#,
				'standard' => q#Tamdanang Oras sa Easter Island#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Oras sa Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Gikoordinar nga Kinatibuk-ang Oras#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Wala Mailhing Lungsod#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Tamdanang Oras sa Irish#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa British#,
			},
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Central Europe#,
				'generic' => q#Oras sa Central Europe#,
				'standard' => q#Tamdanang Oras sa Central Europe#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Eastern Europe#,
				'generic' => q#Oras sa Eastern Europe#,
				'standard' => q#Tamdanang Oras sa Eastern Europe#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Oras sa Further-eastern Europe#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Western Europe#,
				'generic' => q#Oras sa Western Europe#,
				'standard' => q#Tamdanang Oras sa Western Europe#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Falkland Islands#,
				'generic' => q#Oras sa Falkland Islands#,
				'standard' => q#Tamdanang Oras sa Falkland Islands#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Fiji#,
				'generic' => q#Oras sa Fiji#,
				'standard' => q#Tamdanang Oras sa Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Oras sa French Guiana#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Oras sa French Southern ug Antarctic#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Oras sa Greenwich Mean#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Oras sa Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Oras sa Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Georgia#,
				'generic' => q#Oras sa Georgia#,
				'standard' => q#Tamdanang Oras sa Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Oras sa Gilbert Islands#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa East Greenland#,
				'generic' => q#Oras sa East Greenland#,
				'standard' => q#Tamdanang Oras sa East Greenland#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa West Greenland#,
				'generic' => q#Oras sa West Greenland#,
				'standard' => q#Tamdanang Oras sa West Greenland#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Tamdanang Oras sa Gulf#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Oras sa Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Hawaii-Aleutian#,
				'generic' => q#Oras sa Hawaii-Aleutian#,
				'standard' => q#Tamdanang Oras sa Hawaii-Aleutian#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Hong Kong#,
				'generic' => q#Oras sa Hong Kong#,
				'standard' => q#Tamdanang Oras sa Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Hovd#,
				'generic' => q#Oras sa Hovd#,
				'standard' => q#Tamdanang Oras sa Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Tamdanang Oras sa India#,
			},
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Oras sa Indian Ocean#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Oras sa Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Oras sa Central Indonesia#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Oras sa Eastern Indonesia#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Oras sa Western Indonesia#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Iran#,
				'generic' => q#Oras sa Iran#,
				'standard' => q#Tamdanang Oras sa Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Irkutsk#,
				'generic' => q#Oras sa Irkutsk#,
				'standard' => q#Tamdanang Oras sa Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Israel#,
				'generic' => q#Oras sa Israel#,
				'standard' => q#Tamdanang Oras sa Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Oras sa Adlawan sa Japan#,
				'generic' => q#Oras sa Japan#,
				'standard' => q#Tamdanang Oras sa Japan#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Oras sa East Kazakhstan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Oras sa West Kazakhstan#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Korea#,
				'generic' => q#Oras sa Korea#,
				'standard' => q#Tamdanang Oras sa Korea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Oras sa Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Krasnoyarsk#,
				'generic' => q#Oras sa Krasnoyarsk#,
				'standard' => q#Tamdanang Oras sa Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Oras sa Kyrgyzstan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Oras sa Line Islands#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Lord Howe#,
				'generic' => q#Oras sa Lord Howe#,
				'standard' => q#Tamdanang Oras sa Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Oras sa Macquarie Island#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Magadan#,
				'generic' => q#Oras sa Magadan#,
				'standard' => q#Tamdanang Oras sa Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Oras sa Malaysia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Oras sa Maldives#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Oras sa Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Oras sa Marshall Islands#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Mauritius#,
				'generic' => q#Oras sa Mauritius#,
				'standard' => q#Tamdanang Oras sa Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Oras sa Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Northwest Mexico#,
				'generic' => q#Oras sa Northwest Mexico#,
				'standard' => q#Tamdanang Oras sa Northwest Mexico#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Mexican Pacific#,
				'generic' => q#Oras sa Mexican Pacific#,
				'standard' => q#Tamdanang Oras sa Mexican Pacific#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Ulaanbaatar#,
				'generic' => q#Oras sa Ulaanbaatar#,
				'standard' => q#Tamdanang Oras sa Ulaanbaatar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Moscow#,
				'generic' => q#Oras sa Moscow#,
				'standard' => q#Tamdanang Oras sa Moscow#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Oras sa Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Oras sa Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Oras sa Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa New Caledonia#,
				'generic' => q#Oras sa New Caledonia#,
				'standard' => q#Tamdanang Oras sa New Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa New Zealand#,
				'generic' => q#Oras sa New Zealand#,
				'standard' => q#Tamdanang Oras sa New Zealand#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Newfoundland#,
				'generic' => q#Oras sa Newfoundland#,
				'standard' => q#Tamdanang Oras sa Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Oras sa Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Norfolk Island#,
				'generic' => q#Oras sa Norfolk Island#,
				'standard' => q#Tamdanang Oras sa Norfolk Island#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Fernando de Noronha#,
				'generic' => q#Oras sa Fernando de Noronha#,
				'standard' => q#Tamdanang Oras sa Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Novosibirsk#,
				'generic' => q#Oras sa Novosibirsk#,
				'standard' => q#Tamdanang Oras sa Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Omsk#,
				'generic' => q#Oras sa Omsk#,
				'standard' => q#Tamdanang Oras sa Omsk#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Pakistan#,
				'generic' => q#Oras sa Pakistan#,
				'standard' => q#Tamdanang Oras sa Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Oras sa Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Oras sa Papua New Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Paraguay#,
				'generic' => q#Oras sa Paraguay#,
				'standard' => q#Tamdanang Oras sa Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Peru#,
				'generic' => q#Oras sa Peru#,
				'standard' => q#Tamdanang Oras sa Peru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Pilipinas#,
				'generic' => q#Oras sa Pilipinas#,
				'standard' => q#Tamdanang Oras sa Pilipinas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Oras sa Phoenix Islands#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa St.Pierre & Miquelon#,
				'generic' => q#Oras sa St. Pierre & Miquelon#,
				'standard' => q#Tamdanang Oras sa St. Pierre & Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Oras sa Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Oras sa Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Oras sa Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Oras sa Reunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Oras sa Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Sakhalin#,
				'generic' => q#Oras sa Sakhalin#,
				'standard' => q#Tamdanang Oras sa Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Daylight Time sa Samoa#,
				'generic' => q#Oras sa Samoa#,
				'standard' => q#Tamdanang Oras sa Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Oras sa Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Tamdanang Oras sa Singapore#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Oras sa Solomon Islands#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Oras sa South Georgia#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Oras sa Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Oras sa Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Oras sa Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Taipei#,
				'generic' => q#Oras sa Taipei#,
				'standard' => q#Tamdanang Oras sa Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Oras sa Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Oras sa Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Tonga#,
				'generic' => q#Oras sa Tonga#,
				'standard' => q#Tamdanang Oras sa Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Oras sa Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Turkmenistan#,
				'generic' => q#Oras sa Turkmenistan#,
				'standard' => q#Tamdanang Oras sa Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Oras sa Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Uruguay#,
				'generic' => q#Oras sa Uruguay#,
				'standard' => q#Tamdanang Oras sa Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Uzbekistan#,
				'generic' => q#Oras sa Uzbekistan#,
				'standard' => q#Tamdanang Oras sa Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Vanuatu#,
				'generic' => q#Oras sa Vanuatu#,
				'standard' => q#Tamdanang Oras sa Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Oras sa Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Vladivostok#,
				'generic' => q#Oras sa Vladivostok#,
				'standard' => q#Tamdanang Oras sa Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Volgograd#,
				'generic' => q#Oras sa Volgograd#,
				'standard' => q#Tamdanang Oras sa Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Oras sa Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Oras sa Wake Island#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Oras sa Wallis & Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Yakutsk#,
				'generic' => q#Oras sa Yakutsk#,
				'standard' => q#Tamdanang Oras sa Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Oras sa Tag-init sa Yekaterinburg#,
				'generic' => q#Oras sa Yekaterinburg#,
				'standard' => q#Tamdanang Oras sa Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Oras sa Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
