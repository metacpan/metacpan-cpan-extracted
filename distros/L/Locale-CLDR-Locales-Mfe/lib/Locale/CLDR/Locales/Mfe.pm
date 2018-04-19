=head1

Locale::CLDR::Locales::Mfe - Package for language Morisyen

=cut

package Locale::CLDR::Locales::Mfe;
# This file auto generated from Data\common\main\mfe.xml
#	on Fri 13 Apr  7:19:15 am GMT

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
				'ak' => 'akan',
 				'am' => 'amarik',
 				'ar' => 'arab',
 				'be' => 'bieloris',
 				'bg' => 'bilgar',
 				'bn' => 'bengali',
 				'cs' => 'tchek',
 				'de' => 'alman',
 				'el' => 'grek',
 				'en' => 'angle',
 				'es' => 'espagnol',
 				'fa' => 'persan',
 				'fr' => 'franse',
 				'ha' => 'haoussa',
 				'hi' => 'hindi',
 				'hu' => 'hongrwa',
 				'id' => 'indonezien',
 				'ig' => 'igbo',
 				'it' => 'italien',
 				'ja' => 'zapone',
 				'jv' => 'zavane',
 				'km' => 'khmer, santral',
 				'ko' => 'koreen',
 				'mfe' => 'kreol morisien',
 				'ms' => 'male',
 				'my' => 'birman',
 				'ne' => 'nepale',
 				'nl' => 'olande',
 				'pa' => 'penjabi',
 				'pl' => 'polone',
 				'pt' => 'portige',
 				'ro' => 'roumin',
 				'ru' => 'ris',
 				'rw' => 'rwanda',
 				'so' => 'somali',
 				'sv' => 'swedwa',
 				'ta' => 'tamoul',
 				'th' => 'thaï',
 				'tr' => 'tirk',
 				'uk' => 'ikrenien',
 				'ur' => 'ourdou',
 				'vi' => 'vietnamien',
 				'yo' => 'yoruba',
 				'zh' => 'sinwa, mandarin',
 				'zu' => 'zoulou',

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
			'AD' => 'Andor',
 			'AE' => 'Emira arab ini',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua-ek-Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albani',
 			'AM' => 'Armeni',
 			'AO' => 'Angola',
 			'AR' => 'Larzantinn',
 			'AS' => 'Samoa amerikin',
 			'AT' => 'Lostris',
 			'AU' => 'Lostrali',
 			'AW' => 'Aruba',
 			'AZ' => 'Azerbaïdjan',
 			'BA' => 'Bosni-Herzegovinn',
 			'BB' => 'Barbad',
 			'BD' => 'Banglades',
 			'BE' => 'Belzik',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bilgari',
 			'BH' => 'Bahreïn',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BM' => 'Bermid',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivi',
 			'BR' => 'Brezil',
 			'BS' => 'Bahamas',
 			'BT' => 'Boutan',
 			'BW' => 'Botswana',
 			'BY' => 'Belaris',
 			'BZ' => 'Beliz',
 			'CA' => 'Kanada',
 			'CD' => 'Repiblik demokratik Kongo',
 			'CF' => 'Repiblik Lafrik Santral',
 			'CG' => 'Kongo',
 			'CH' => 'Laswis',
 			'CI' => 'Côte d’Ivoire',
 			'CK' => 'Zil Cook',
 			'CL' => 'Shili',
 			'CM' => 'Kamerounn',
 			'CN' => 'Lasinn',
 			'CO' => 'Kolonbi',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Kap-Ver',
 			'CY' => 'Cyprus',
 			'CZ' => 'Repiblik Chek',
 			'DE' => 'Almagn',
 			'DJ' => 'Djibouti',
 			'DK' => 'Dannmark',
 			'DM' => 'Dominik',
 			'DO' => 'Repiblik dominikin',
 			'DZ' => 'Alzeri',
 			'EC' => 'Ekwater',
 			'EE' => 'Estoni',
 			'EG' => 'Lezipt',
 			'ER' => 'Erythre',
 			'ES' => 'Lespagn',
 			'ET' => 'Letiopi',
 			'FI' => 'Finland',
 			'FJ' => 'Fidji',
 			'FK' => 'Zil malwinn',
 			'FM' => 'Mikronezi',
 			'FR' => 'Lafrans',
 			'GA' => 'Gabon',
 			'GB' => 'United Kingdom',
 			'GD' => 'Grenad',
 			'GE' => 'Zeorzi',
 			'GF' => 'Gwiyann franse',
 			'GH' => 'Ghana',
 			'GI' => 'Zibraltar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambi',
 			'GN' => 'Gine',
 			'GP' => 'Guadloup',
 			'GQ' => 'Gine ekwatoryal',
 			'GR' => 'Gres',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Gine-Bisau',
 			'GY' => 'Guyana',
 			'HN' => 'Honduras',
 			'HR' => 'Kroasi',
 			'HT' => 'Ayti',
 			'HU' => 'Ongri',
 			'ID' => 'Indonezi',
 			'IE' => 'Irland',
 			'IL' => 'Izrael',
 			'IN' => 'Lenn',
 			'IO' => 'Teritwar Britanik Losean Indien',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Itali',
 			'JM' => 'Zamaik',
 			'JO' => 'Zordani',
 			'JP' => 'Zapon',
 			'KE' => 'Kenya',
 			'KG' => 'Kirghizistan',
 			'KH' => 'Kambodj',
 			'KI' => 'Kiribati',
 			'KM' => 'Komor',
 			'KN' => 'Saint-Christophe-ek-Niévès',
 			'KP' => 'Lakore-dinor',
 			'KR' => 'Lakore-disid',
 			'KW' => 'Koweit',
 			'KY' => 'Zil Kayman',
 			'KZ' => 'Kazakstan',
 			'LA' => 'Laos',
 			'LB' => 'Liban',
 			'LC' => 'Sainte-Lucie',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lezoto',
 			'LT' => 'Lituani',
 			'LU' => 'Luxembourg',
 			'LV' => 'Letoni',
 			'LY' => 'Libi',
 			'MA' => 'Marok',
 			'MC' => 'Monako',
 			'MD' => 'Moldavi',
 			'MG' => 'Madagaskar',
 			'MH' => 'Zil Marshall',
 			'MK' => 'Masedwann',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar',
 			'MN' => 'Mongoli',
 			'MP' => 'Zil Maryann dinor',
 			'MQ' => 'Martinik',
 			'MR' => 'Moritani',
 			'MS' => 'Montsera',
 			'MT' => 'Malt',
 			'MU' => 'Moris',
 			'MV' => 'Maldiv',
 			'MW' => 'Malawi',
 			'MX' => 'Mexik',
 			'MY' => 'Malezi',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibi',
 			'NC' => 'Nouvel-Kaledoni',
 			'NE' => 'Nizer',
 			'NF' => 'Lil Norfolk',
 			'NG' => 'Nizeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Oland',
 			'NO' => 'Norvez',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niowe',
 			'NZ' => 'Nouvel Zeland',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Perou',
 			'PF' => 'Polinezi franse',
 			'PG' => 'Papouazi-Nouvel-Gine',
 			'PH' => 'Filipinn',
 			'PK' => 'Pakistan',
 			'PL' => 'Pologn',
 			'PM' => 'Saint-Pierre-ek-Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Porto Rico',
 			'PS' => 'Teritwar Palestinn',
 			'PT' => 'Portigal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Katar',
 			'RE' => 'Larenion',
 			'RO' => 'Roumani',
 			'RU' => 'Larisi',
 			'RW' => 'Rwanda',
 			'SA' => 'Larabi Saoudit',
 			'SB' => 'Zil Salomon',
 			'SC' => 'Sesel',
 			'SD' => 'Soudan',
 			'SE' => 'Laswed',
 			'SG' => 'Singapour',
 			'SH' => 'Sainte-Hélène',
 			'SI' => 'Sloveni',
 			'SK' => 'Slovaki',
 			'SL' => 'Sierra Leone',
 			'SM' => 'Saint-Marin',
 			'SN' => 'Senegal',
 			'SO' => 'Somali',
 			'SR' => 'Surinam',
 			'ST' => 'São Tome-ek-Prínsip',
 			'SV' => 'Salvador',
 			'SY' => 'Lasiri',
 			'SZ' => 'Swaziland',
 			'TC' => 'Zil Tirk ek Caïcos',
 			'TD' => 'Tchad',
 			'TG' => 'Togo',
 			'TH' => 'Thayland',
 			'TJ' => 'Tadjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor oriantal',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tinizi',
 			'TO' => 'Tonga',
 			'TR' => 'Tirki',
 			'TT' => 'Trinite-ek-Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzani',
 			'UA' => 'Ikrenn',
 			'UG' => 'Ouganda',
 			'US' => 'Lamerik',
 			'UY' => 'Uruguay',
 			'UZ' => 'Ouzbekistan',
 			'VA' => 'Lata Vatikan',
 			'VC' => 'Saint-Vincent-ek-Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Zil vierz britanik',
 			'VI' => 'Zil Vierz Lamerik',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis-ek-Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Yemenn',
 			'YT' => 'Mayot',
 			'ZA' => 'Sid-Afrik',
 			'ZM' => 'Zambi',
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
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n o p r s t u v w x y z]},
			numbers => qr{[  \- . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
	default		=> sub { qr'^(?i:Wi|W|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Non|N)$' }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'group' => q( ),
		},
	} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AED' => {
			display_name => {
				'currency' => q(dirham Emira arab ini),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza angole),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(dolar ostralien),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dinar bahreïn),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(fran burunde),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula ya botswane),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(dolar kanadien),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(fran kongole),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(fran swis),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(yuan renminbi sinwa),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(eskudo kapverdien),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(fran djiboutien),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinar alzerien),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(liv ezipsien),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nafka erythreen),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(birr etiopien),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(liv sterlin),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(sedi ganeen),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi gambien),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(fran gineen),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(roupi),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(yen zapone),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(shiling kenyan),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(fran komorien),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dolar liberien),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti lezoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinar libien),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dirham marokin),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(fran malgas),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ouguiya moritanien),
			},
		},
		'MUR' => {
			symbol => 'Rs',
			display_name => {
				'currency' => q(roupi morisien),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha malawit),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(metikal mozanbikin),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dolar namibien),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira nizerian),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(fran rwande),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(rial saoudien),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(roupi seselwa),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(dinar soudane),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(liv soudane),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(liv Sainte-Hélène),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leonn Sierra-Leone),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(shilingi somalien),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(dobra santomeen),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni swazi),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinar tinizien),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(shiling tanzanien),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(shiling ougande),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(dolar amerikin),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(fran CFA \(BEAC\)),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(fran CFA \(BCEAO\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(rand sid-afrikin),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(kwacha zanbien \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwacha zanbien),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(dolar zimbawe),
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
							'zan',
							'fev',
							'mar',
							'avr',
							'me',
							'zin',
							'zil',
							'out',
							'sep',
							'okt',
							'nov',
							'des'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'zanvie',
							'fevriye',
							'mars',
							'avril',
							'me',
							'zin',
							'zilye',
							'out',
							'septam',
							'oktob',
							'novam',
							'desam'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'z',
							'f',
							'm',
							'a',
							'm',
							'z',
							'z',
							'o',
							's',
							'o',
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
						mon => 'lin',
						tue => 'mar',
						wed => 'mer',
						thu => 'ze',
						fri => 'van',
						sat => 'sam',
						sun => 'dim'
					},
					wide => {
						mon => 'lindi',
						tue => 'mardi',
						wed => 'merkredi',
						thu => 'zedi',
						fri => 'vandredi',
						sat => 'samdi',
						sun => 'dimans'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'l',
						tue => 'm',
						wed => 'm',
						thu => 'z',
						fri => 'v',
						sat => 's',
						sun => 'd'
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
					abbreviated => {0 => 'T1',
						1 => 'T2',
						2 => 'T3',
						3 => 'T4'
					},
					wide => {0 => '1e trimes',
						1 => '2em trimes',
						2 => '3em trimes',
						3 => '4em trimes'
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
				'0' => 'av. Z-K',
				'1' => 'ap. Z-K'
			},
			wide => {
				'0' => 'avan Zezi-Krist',
				'1' => 'apre Zezi-Krist'
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
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
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
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
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
