=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mua - Package for language Mundang

=cut

package Locale::CLDR::Locales::Mua;
# This file auto generated from Data\common\main\mua.xml
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
				'ak' => 'akaŋ',
 				'am' => 'amharik',
 				'ar' => 'arabiya',
 				'be' => 'belarussiya',
 				'bg' => 'bulgaria',
 				'bn' => 'bengalia',
 				'cs' => 'syekya',
 				'de' => 'germaŋ',
 				'el' => 'grek',
 				'en' => 'zah Anglofoŋ',
 				'es' => 'Espaniya',
 				'fa' => 'Persia',
 				'fr' => 'zah sǝr Franssǝ',
 				'ha' => 'haussa',
 				'hi' => 'hindi',
 				'hu' => 'hungariya',
 				'id' => 'indonesiya',
 				'ig' => 'igbo',
 				'it' => 'italiya',
 				'ja' => 'zah sǝr Japoŋ',
 				'jv' => 'javaniya',
 				'km' => 'kmer',
 				'ko' => 'korea',
 				'ms' => 'malasiya',
 				'mua' => 'MUNDAŊ',
 				'my' => 'birmania',
 				'ne' => 'Nepaliya',
 				'nl' => 'zah sǝr ma kasǝŋ',
 				'pa' => 'Pǝnjabi',
 				'pl' => 'Poloniya',
 				'pt' => 'Zah sǝr Portugal',
 				'ro' => 'Romaniya',
 				'ru' => 'Russiya',
 				'rw' => 'Zah sǝr Rwanda',
 				'so' => 'Somaliya',
 				'sv' => 'Swedia',
 				'ta' => 'Tamul',
 				'tr' => 'Turk',
 				'uk' => 'Ukrainia',
 				'ur' => 'Urdu',
 				'vi' => 'Vietnamiya',
 				'yo' => 'Yoruba',
 				'zh' => 'zah Syiŋ',
 				'zu' => 'Zulu',

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
			'AD' => 'andorra',
 			'AE' => 'Sǝr Arabiya ma taini',
 			'AF' => 'afghanistaŋ',
 			'AG' => 'antiguan ne Barbuda',
 			'AI' => 'anguiya',
 			'AL' => 'albaniya',
 			'AM' => 'armeniya',
 			'AO' => 'angola',
 			'AR' => 'argentiniya',
 			'AS' => 'samoa Amerika',
 			'AT' => 'austriya',
 			'AU' => 'australiya',
 			'AW' => 'aruba',
 			'AZ' => 'azerbaijaŋ',
 			'BA' => 'bosniya ne Herzegovina',
 			'BB' => 'barbadiya',
 			'BD' => 'bangladeshiya',
 			'BE' => 'belgika',
 			'BF' => 'burkina Faso',
 			'BG' => 'bulgariya',
 			'BH' => 'bahraiŋ',
 			'BI' => 'burundi',
 			'BJ' => 'beniŋ',
 			'BM' => 'bermudiya',
 			'BN' => 'bruniya',
 			'BO' => 'boliviya',
 			'BR' => 'brazilya',
 			'BS' => 'bahamas',
 			'BT' => 'butaŋ',
 			'BW' => 'botswana',
 			'BY' => 'belarussiya',
 			'BZ' => 'beliziya',
 			'CA' => 'kanada',
 			'CD' => 'Sǝr Kongo ma dii ne zair',
 			'CF' => 'centrafrika',
 			'CG' => 'kongo',
 			'CH' => 'Sǝr Swiss',
 			'CI' => 'ser Ivoiriya',
 			'CK' => 'kook ma laŋne',
 			'CL' => 'syili',
 			'CM' => 'kameruŋ',
 			'CN' => 'syiŋ',
 			'CO' => 'kolombiya',
 			'CR' => 'kosta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'kap ma laŋne',
 			'CY' => 'Syipriya',
 			'CZ' => 'Sǝr Syek',
 			'DE' => 'Germaniya',
 			'DJ' => 'Djibouti',
 			'DK' => 'Daŋmark',
 			'DM' => 'Dominik',
 			'DO' => 'Sǝr Dominik ma lii',
 			'DZ' => 'algeriya',
 			'EC' => 'Ekwatǝr',
 			'EE' => 'Estoniya',
 			'EG' => 'Sǝr Egypt',
 			'ER' => 'Sǝr Eritre',
 			'ES' => 'Espaŋiya',
 			'ET' => 'Etiopia',
 			'FI' => 'Sǝr Finland',
 			'FJ' => 'Sǝr Fiji',
 			'FK' => 'Sǝr malouniya ma laŋne',
 			'FM' => 'Micronesiya',
 			'FR' => 'Franssǝ',
 			'GA' => 'Gaboŋ',
 			'GB' => 'Sǝr Anglofoŋ',
 			'GD' => 'Grenadǝ',
 			'GE' => 'Georgiya',
 			'GF' => 'Sǝr Guyana ma Franssǝ',
 			'GH' => 'Gana',
 			'GI' => 'Sǝr Gibraltar',
 			'GL' => 'Sǝr Groenland',
 			'GM' => 'Gambiya',
 			'GN' => 'Guine',
 			'GP' => 'Sǝr Gwadeloupǝ',
 			'GQ' => 'Sǝr Guine',
 			'GR' => 'Sǝr Grek',
 			'GT' => 'Gwatemala',
 			'GU' => 'Gwam',
 			'GW' => 'Guine ma Bissao',
 			'GY' => 'Guyana',
 			'HN' => 'Sǝr Honduras',
 			'HR' => 'kroatiya',
 			'HT' => 'Sǝr Haiti',
 			'HU' => 'Hungriya',
 			'ID' => 'Indonesiya',
 			'IE' => 'Sǝr Ireland',
 			'IL' => 'Sǝr Israel',
 			'IN' => 'Sǝr Indǝ',
 			'IO' => 'anglofoŋ ma Indiya',
 			'IQ' => 'Irak',
 			'IR' => 'Iraŋ',
 			'IS' => 'Sǝr Island',
 			'IT' => 'Italiya',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordaniya',
 			'JP' => 'Japaŋ',
 			'KE' => 'Sǝr Kenya',
 			'KG' => 'Kirgizstaŋ',
 			'KH' => 'kambodiya',
 			'KI' => 'Sǝr Kiribati',
 			'KM' => 'komora',
 			'KN' => 'Sǝr Kristof ne Nievǝ',
 			'KP' => 'Sǝr Kore fah sǝŋ',
 			'KR' => 'Sǝr Kore nekǝsǝŋ',
 			'KW' => 'Sǝr Kowait',
 			'KY' => 'kayman ma laŋne',
 			'KZ' => 'Kazakstaŋ',
 			'LA' => 'Sǝr Laos',
 			'LB' => 'Libaŋ',
 			'LC' => 'Sǝr Lucia',
 			'LI' => 'Lichtǝnsteiŋ',
 			'LK' => 'Sǝr Lanka',
 			'LR' => 'Liberiya',
 			'LS' => 'Sǝr Lesotho',
 			'LT' => 'Lituaniya',
 			'LU' => 'Sǝr Luxemburg',
 			'LV' => 'Letoniya',
 			'LY' => 'Libiya',
 			'MA' => 'Marok',
 			'MC' => 'Monako',
 			'MD' => 'Moldoviya',
 			'MG' => 'Madagaskar',
 			'MH' => 'Sǝr Marshall ma laŋne',
 			'ML' => 'Sǝr Mali',
 			'MM' => 'Sǝr Myanmar',
 			'MN' => 'Mongoliya',
 			'MP' => 'Sǝr Maria ma laŋne',
 			'MQ' => 'Martinika',
 			'MR' => 'Mauritaniya',
 			'MS' => 'Sǝr Montserrat',
 			'MT' => 'Sǝr Malta',
 			'MU' => 'Sǝr Mauricǝ',
 			'MV' => 'Maldivǝ',
 			'MW' => 'Sǝr Malawi',
 			'MX' => 'Mexiko',
 			'MY' => 'Malaysiya',
 			'MZ' => 'Mozambika',
 			'NA' => 'Namibiya',
 			'NC' => 'Kaledoniya mafuu',
 			'NE' => 'Sǝr Niger',
 			'NF' => 'Norfolk ma laŋne',
 			'NG' => 'Nigeriya',
 			'NI' => 'Nikaragwa',
 			'NL' => 'Sǝr ma kasǝŋ',
 			'NO' => 'Norvegǝ',
 			'NP' => 'Sǝr Nepal',
 			'NR' => 'Sǝr Nauru',
 			'NU' => 'Niwe',
 			'NZ' => 'Zeland mafuu',
 			'OM' => 'Omaŋ',
 			'PA' => 'Sǝr Panama',
 			'PE' => 'Peru',
 			'PF' => 'Sǝr Polynesiya ma Franssǝ',
 			'PG' => 'Papuasiya Guine mafuu',
 			'PH' => 'Filipiŋ',
 			'PK' => 'Pakistaŋ',
 			'PL' => 'Pologŋ',
 			'PM' => 'Sǝr Pǝtar ne Mikǝlon',
 			'PN' => 'Pitkairn',
 			'PR' => 'Porto Riko',
 			'PS' => 'Sǝr Palestiniya',
 			'PT' => 'Sǝr Portugal',
 			'PW' => 'Sǝr Palau',
 			'PY' => 'Paragwai',
 			'QA' => 'Katar',
 			'RE' => 'Sǝr Reunion',
 			'RO' => 'Romaniya',
 			'RU' => 'Russiya',
 			'RW' => 'Rwanda',
 			'SA' => 'Sǝr Arabiya',
 			'SB' => 'Sǝr Salomon ma laŋne',
 			'SC' => 'Saichel',
 			'SD' => 'Sudaŋ',
 			'SE' => 'Sǝr Sued',
 			'SG' => 'Singapur',
 			'SH' => 'Sǝr Helena',
 			'SI' => 'Sloveniya',
 			'SK' => 'Slovakiya',
 			'SL' => 'Sierra Leonǝ',
 			'SM' => 'Sǝr Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somaliya',
 			'SR' => 'Sǝr Surinam',
 			'ST' => 'Sao Tome ne Principe',
 			'SV' => 'Sǝr Salvador',
 			'SY' => 'Syria',
 			'SZ' => 'Sǝr Swaziland',
 			'TC' => 'Turkiya ne kaicos ma laŋne',
 			'TD' => 'syad',
 			'TG' => 'Sǝr Togo',
 			'TH' => 'Tailand',
 			'TJ' => 'Tajikistaŋ',
 			'TK' => 'Sǝr Tokelau',
 			'TL' => 'Timoriya',
 			'TM' => 'Turkmenistaŋ',
 			'TN' => 'Tunisiya',
 			'TO' => 'Sǝr Tonga',
 			'TR' => 'Turkiya',
 			'TT' => 'Trinite ne Tobago',
 			'TV' => 'Sǝr Tuvalu',
 			'TW' => 'Taiwaŋ',
 			'TZ' => 'Tanzaniya',
 			'UA' => 'Ukraiŋ',
 			'UG' => 'Uganda',
 			'US' => 'Amerika',
 			'UY' => 'Urugwai',
 			'UZ' => 'Uzbekistaŋ',
 			'VA' => 'Vaticaŋ',
 			'VC' => 'Sǝr Vinceŋ ne Grenadiŋ',
 			'VE' => 'Sǝr Venezuela',
 			'VG' => 'ser Anglofon ma laŋne',
 			'VI' => 'Sǝr amerika ma laŋne',
 			'VN' => 'Sǝr Vietnam',
 			'VU' => 'Sǝr Vanuatu',
 			'WF' => 'Wallis ne Futuna',
 			'WS' => 'Sǝr Samoa',
 			'YE' => 'Yemeŋ',
 			'YT' => 'Mayot',
 			'ZA' => 'Afrika nekǝsǝŋ',
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
			auxiliary => qr{[q x]},
			index => ['A', 'B', 'Ɓ', 'C', 'D', 'Ɗ', 'E', 'Ǝ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{[aã b ɓ c d ɗ eë ǝ f g h iĩ j k l m n ŋ oõ p r s t u vṽ w y z]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'Ɓ', 'C', 'D', 'Ɗ', 'E', 'Ǝ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
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
	default		=> qq{“},
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
	default		=> sub { qr'^(?i:Oho|O|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:A a|A|no|n)$' }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
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
				'currency' => q(Solai Arabiya),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(solai Angola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(solai Australya),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(solai Barenya),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(solai Burundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(solai Botswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(solai Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(solai Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Solai Swiss),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(solai Syiŋ),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(solai Kapverdiya),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(solai Djibouti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(solai Algerya),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(solai Egypt),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(solai Eritre),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(solai Etiopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(solai Euro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(solai Britaniya),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(solai Gana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(solai Gambiya),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(solai Guine),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(solai India),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(solai Japoŋ),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(solai Kenia),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(solai Komorya),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(solai Liberiya),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(solai Lesotho),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(solai Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Solai Marok),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Solai Malagasya),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Solai Mauritaniya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Solai Mauritaniya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Solai Mauricǝ),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Solai Malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Solai Mozambika),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Solai Namibiya),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Solai Nigeriya),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Solai Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Solai Saudiya),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Solai Saichel),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Solai Sudaŋ ma dii ne dinar),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Solai Sudaŋ ma dii ne livre),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Solai Helena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(solai Sierra leonǝ),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(solai Sierra leonǝ \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Solai Somaliya),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Solai Sao Tome \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Solai Sao Tome),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(solai Swaziland),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Solai Tunisiya),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Solai Tanzaniya),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Solai Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Solai Amerika),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(solai BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(solai BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Solai Africa nekǝsǝŋ),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Solai Zambiya \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Solai Zambiya),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Solai Zimbabwe),
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
							'FLO',
							'CLA',
							'CKI',
							'FMF',
							'MAD',
							'MBI',
							'MLI',
							'MAM',
							'FDE',
							'FMU',
							'FGW',
							'FYU'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Fĩi Loo',
							'Cokcwaklaŋne',
							'Cokcwaklii',
							'Fĩi Marfoo',
							'Madǝǝuutǝbijaŋ',
							'Mamǝŋgwãafahbii',
							'Mamǝŋgwãalii',
							'Madǝmbii',
							'Fĩi Dǝɓlii',
							'Fĩi Mundaŋ',
							'Fĩi Gwahlle',
							'Fĩi Yuru'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'O',
							'A',
							'I',
							'F',
							'D',
							'B',
							'L',
							'M',
							'E',
							'U',
							'W',
							'Y'
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
						mon => 'Cla',
						tue => 'Czi',
						wed => 'Cko',
						thu => 'Cka',
						fri => 'Cga',
						sat => 'Cze',
						sun => 'Cya'
					},
					wide => {
						mon => 'Comlaaɗii',
						tue => 'Comzyiiɗii',
						wed => 'Comkolle',
						thu => 'Comkaldǝɓlii',
						fri => 'Comgaisuu',
						sat => 'Comzyeɓsuu',
						sun => 'Com’yakke'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'Z',
						wed => 'O',
						thu => 'A',
						fri => 'G',
						sat => 'E',
						sun => 'Y'
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
					abbreviated => {0 => 'F1',
						1 => 'F2',
						2 => 'F3',
						3 => 'F4'
					},
					wide => {0 => 'Tai fĩi sai ma tǝn kee zah',
						1 => 'Tai fĩi sai zah lǝn gwa ma kee',
						2 => 'Tai fĩi sai zah lǝn sai ma kee',
						3 => 'Tai fĩi sai ma coo kee zah ‘na'
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
					'am' => q{comme},
					'pm' => q{lilli},
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
				'1' => 'PK'
			},
			wide => {
				'0' => 'KǝPel Kristu',
				'1' => 'Pel Kristu'
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
			'medium' => q{d MMM y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
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
			Ed => q{E d},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			Ed => q{E d},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
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
