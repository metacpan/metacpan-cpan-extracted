=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mg - Package for language Malagasy

=cut

package Locale::CLDR::Locales::Mg;
# This file auto generated from Data\common\main\mg.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

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
				'ak' => 'Akan',
 				'am' => 'Amharika',
 				'ar' => 'Arabo',
 				'be' => 'Bielorosy',
 				'bg' => 'Biolgara',
 				'bn' => 'Bengali',
 				'cs' => 'Tseky',
 				'de' => 'Alemanina',
 				'el' => 'Grika',
 				'en' => 'Anglisy',
 				'es' => 'Espaniola',
 				'fa' => 'Persa',
 				'fr' => 'Frantsay',
 				'ha' => 'haoussa',
 				'hi' => 'hindi',
 				'hu' => 'hongroà',
 				'id' => 'Indonezianina',
 				'ig' => 'igbo',
 				'it' => 'Italianina',
 				'ja' => 'Japoney',
 				'jv' => 'Javaney',
 				'km' => 'khmer',
 				'ko' => 'Koreanina',
 				'mg' => 'Malagasy',
 				'ms' => 'Malay',
 				'my' => 'Birmana',
 				'ne' => 'Nepale',
 				'nl' => 'Holandey',
 				'pa' => 'Penjabi',
 				'pl' => 'Poloney',
 				'pt' => 'Portiogey',
 				'ro' => 'Romanianina',
 				'ru' => 'Rosianina',
 				'rw' => 'Roande',
 				'so' => 'Somalianina',
 				'sv' => 'Soisa',
 				'ta' => 'Tamoila',
 				'th' => 'Taioaney',
 				'tr' => 'Tiorka',
 				'uk' => 'Okrainianina',
 				'ur' => 'Ordò',
 				'vi' => 'Vietnamianina',
 				'yo' => 'Yôrobà',
 				'zh' => 'Sinoa, Mandarin',
 				'zu' => 'Zolò',

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
			'AD' => 'Andorra',
 			'AE' => 'Emirà Arabo mitambatra',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antiga sy Barboda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AR' => 'Arzantina',
 			'AS' => 'Samoa amerikanina',
 			'AT' => 'Aotrisy',
 			'AU' => 'Aostralia',
 			'AW' => 'Arobà',
 			'AZ' => 'Azerbaidjan',
 			'BA' => 'Bosnia sy Herzegovina',
 			'BB' => 'Barbady',
 			'BD' => 'Bangladesy',
 			'BE' => 'Belzika',
 			'BF' => 'Borkina Faso',
 			'BG' => 'Biolgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Borondi',
 			'BJ' => 'Benin',
 			'BM' => 'Bermioda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BR' => 'Brezila',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhotana',
 			'BW' => 'Botsoana',
 			'BY' => 'Belarosy',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CD' => 'Repoblikan’i Kongo',
 			'CF' => 'Repoblika Ivon’Afrika',
 			'CG' => 'Kôngô',
 			'CH' => 'Soisa',
 			'CI' => 'Côte d’Ivoire',
 			'CK' => 'Nosy Kook',
 			'CL' => 'Shili',
 			'CM' => 'Kamerona',
 			'CN' => 'Sina',
 			'CO' => 'Kôlômbia',
 			'CR' => 'Kosta Rikà',
 			'CU' => 'Kiobà',
 			'CV' => 'Nosy Cap-Vert',
 			'CY' => 'Sypra',
 			'CZ' => 'Repoblikan’i Tseky',
 			'DE' => 'Alemaina',
 			'DJ' => 'Djiboti',
 			'DK' => 'Danmarka',
 			'DM' => 'Dominika',
 			'DO' => 'Repoblika Dominikanina',
 			'DZ' => 'Alzeria',
 			'EC' => 'Ekoatera',
 			'EE' => 'Estonia',
 			'EG' => 'Ejypta',
 			'ER' => 'Eritrea',
 			'ES' => 'Espaina',
 			'ET' => 'Ethiopia',
 			'FI' => 'Finlandy',
 			'FJ' => 'Fidji',
 			'FK' => 'Nosy Falkand',
 			'FM' => 'Mikrônezia',
 			'FR' => 'Frantsa',
 			'GA' => 'Gabon',
 			'GB' => 'Angletera',
 			'GD' => 'Grenady',
 			'GE' => 'Zeorzia',
 			'GF' => 'Guyana frantsay',
 			'GH' => 'Ghana',
 			'GI' => 'Zibraltara',
 			'GL' => 'Groenland',
 			'GM' => 'Gambia',
 			'GN' => 'Ginea',
 			'GP' => 'Goadelopy',
 			'GQ' => 'Guinea Ekoatera',
 			'GR' => 'Gresy',
 			'GT' => 'Goatemalà',
 			'GU' => 'Guam',
 			'GW' => 'Giné-Bisao',
 			'GY' => 'Guyana',
 			'HN' => 'Hondiorasy',
 			'HR' => 'Kroasia',
 			'HT' => 'Haiti',
 			'HU' => 'Hongria',
 			'ID' => 'Indonezia',
 			'IE' => 'Irlandy',
 			'IL' => 'Israely',
 			'IN' => 'Indy',
 			'IO' => 'Faridranomasina indiana britanika',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islandy',
 			'IT' => 'Italia',
 			'JM' => 'Jamaïka',
 			'JO' => 'Jordania',
 			'JP' => 'Japana',
 			'KE' => 'Kenya',
 			'KG' => 'Kiordistan',
 			'KH' => 'Kambôdja',
 			'KI' => 'Kiribati',
 			'KM' => 'Kômaoro',
 			'KN' => 'Saint-Christophe-et-Niévès',
 			'KP' => 'Korea Avaratra',
 			'KR' => 'Korea Atsimo',
 			'KW' => 'Kôeity',
 			'KY' => 'Nosy Kayman',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Laôs',
 			'LB' => 'Libana',
 			'LC' => 'Sainte-Lucie',
 			'LI' => 'Listenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Litoania',
 			'LU' => 'Lioksamboro',
 			'LV' => 'Letonia',
 			'LY' => 'Libya',
 			'MA' => 'Marôka',
 			'MC' => 'Mônakô',
 			'MD' => 'Môldavia',
 			'MG' => 'Madagasikara',
 			'MH' => 'Nosy Marshall',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar',
 			'MN' => 'Môngôlia',
 			'MP' => 'Nosy Mariana Atsinanana',
 			'MQ' => 'Martinika',
 			'MR' => 'Maoritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Maorisy',
 			'MV' => 'Maldiva',
 			'MW' => 'Malaoì',
 			'MX' => 'Meksika',
 			'MY' => 'Malaizia',
 			'MZ' => 'Mozambika',
 			'NA' => 'Namibia',
 			'NC' => 'Nouvelle-Calédonie',
 			'NE' => 'Niger',
 			'NF' => 'Nosy Norfolk',
 			'NG' => 'Nizeria',
 			'NI' => 'Nikaragoà',
 			'NL' => 'Holanda',
 			'NO' => 'Nôrvezy',
 			'NP' => 'Nepala',
 			'NR' => 'Naorò',
 			'NU' => 'Nioé',
 			'NZ' => 'Nouvelle-Zélande',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peroa',
 			'PF' => 'Polynezia frantsay',
 			'PG' => 'Papouasie-Nouvelle-Guinée',
 			'PH' => 'Filipina',
 			'PK' => 'Pakistan',
 			'PL' => 'Pôlôna',
 			'PM' => 'Saint-Pierre-et-Miquelon',
 			'PN' => 'Pitkairn',
 			'PR' => 'Pôrtô Rikô',
 			'PS' => 'Palestina',
 			'PT' => 'Pôrtiogala',
 			'PW' => 'Palao',
 			'PY' => 'Paragoay',
 			'QA' => 'Katar',
 			'RE' => 'Larenion',
 			'RO' => 'Romania',
 			'RU' => 'Rosia',
 			'RW' => 'Roanda',
 			'SA' => 'Arabia saodita',
 			'SB' => 'Nosy Salomona',
 			'SC' => 'Seyshela',
 			'SD' => 'Sodan',
 			'SE' => 'Soedy',
 			'SG' => 'Singaporo',
 			'SH' => 'Sainte-Hélène',
 			'SI' => 'Slovenia',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'Saint-Marin',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Sorinam',
 			'ST' => 'São Tomé-et-Príncipe',
 			'SV' => 'El Salvador',
 			'SY' => 'Syria',
 			'SZ' => 'Soazilandy',
 			'TC' => 'Nosy Turks sy Caïques',
 			'TD' => 'Tsady',
 			'TG' => 'Togo',
 			'TH' => 'Thailandy',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelao',
 			'TL' => 'Timor Atsinanana',
 			'TM' => 'Torkmenistan',
 			'TN' => 'Tonizia',
 			'TO' => 'Tongà',
 			'TR' => 'Torkia',
 			'TT' => 'Trinidad sy Tobagô',
 			'TV' => 'Tovalò',
 			'TW' => 'Taioana',
 			'TZ' => 'Tanzania',
 			'UA' => 'Okraina',
 			'UG' => 'Oganda',
 			'US' => 'Etazonia',
 			'UY' => 'Orogoay',
 			'UZ' => 'Ozbekistan',
 			'VA' => 'Firenen’i Vatikana',
 			'VC' => 'Saint-Vincent-et-les Grenadines',
 			'VE' => 'Venezoelà',
 			'VG' => 'Nosy britanika virijiny',
 			'VI' => 'Nosy Virijiny Etazonia',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanoatò',
 			'WF' => 'Wallis sy Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Yemen',
 			'YT' => 'Mayôty',
 			'ZA' => 'Afrika Atsimo',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbaboe',

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
			auxiliary => qr{[c q u w x]},
			index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'V', 'Y', 'Z'],
			main => qr{[a à â b d e é è ê ë f g h i ì î ï j k l m n ñ o ô p r s t v y z]},
			numbers => qr{[\- ‑ , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'V', 'Y', 'Z'], };
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
	default		=> sub { qr'^(?i:Eny|E|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Tsia|T|no|n)$' }
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 1,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0.###',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
				},
			},
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'default' => '#E0',
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
					'accounting' => {
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
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
				'currency' => q(Dirham),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza angoley),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dolara aostralianina),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dinar bahreïni),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Farantsa Borondi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pola botsoaney),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dôlara Kanadianina),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Farantsa kôngôley),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Farantsa soisa),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yoan sinoa Renminbi),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Farantsa Djibotianina),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinara alzerianina),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(vola venty ejipsiana),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfà Eritreanina),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Bir etiopianina),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Eoro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(livre sterling),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(cédi),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi gambianina),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Farantsa Gineanina),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Ropia Indianina),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yen Japoney),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shilling kenianina),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Farantsa Komorianina),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dôlara Liberianina),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinara Libyanina),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham marokianina),
			},
		},
		'MGA' => {
			symbol => 'Ar',
			display_name => {
				'currency' => q(Ariary),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya moritanianina \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya moritanianina),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Ropia maorisianina),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha malawite),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metikaly),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dolara namibianina),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira nigerianina),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Farantsa Roande),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Rial saodianina),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Ropia Seysheloà),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Dinara Sodaney),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(livre soudanaise \(1956–2007\)),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(livre de Sainte-Hélène),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Shilling somalianina),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinar tonizianina),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Shilling tanzanianina),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shilling ogandianina),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dolara amerikanina),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Farantsa CFA \(BEAC\)),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Farantsa CFA \(BCEAO\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand afrikanina tatsimo),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha zambianina \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha zambianina),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dôlara Zimbaboeanina),
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
							'Mey',
							'Jon',
							'Jol',
							'Aog',
							'Sep',
							'Okt',
							'Nov',
							'Des'
						],
						leap => [
							
						],
					},
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
					wide => {
						nonleap => [
							'Janoary',
							'Febroary',
							'Martsa',
							'Aprily',
							'Mey',
							'Jona',
							'Jolay',
							'Aogositra',
							'Septambra',
							'Oktobra',
							'Novambra',
							'Desambra'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Jan',
							'Feb',
							'Mar',
							'Apr',
							'Mey',
							'Jon',
							'Jol',
							'Aog',
							'Sep',
							'Okt',
							'Nov',
							'Des'
						],
						leap => [
							
						],
					},
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
					wide => {
						nonleap => [
							'Janoary',
							'Febroary',
							'Martsa',
							'Aprily',
							'Mey',
							'Jona',
							'Jolay',
							'Aogositra',
							'Septambra',
							'Oktobra',
							'Novambra',
							'Desambra'
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
						mon => 'Alats',
						tue => 'Tal',
						wed => 'Alar',
						thu => 'Alak',
						fri => 'Zom',
						sat => 'Asab',
						sun => 'Alah'
					},
					narrow => {
						mon => 'A',
						tue => 'T',
						wed => 'A',
						thu => 'A',
						fri => 'Z',
						sat => 'A',
						sun => 'A'
					},
					short => {
						mon => 'Alats',
						tue => 'Tal',
						wed => 'Alar',
						thu => 'Alak',
						fri => 'Zom',
						sat => 'Asab',
						sun => 'Alah'
					},
					wide => {
						mon => 'Alatsinainy',
						tue => 'Talata',
						wed => 'Alarobia',
						thu => 'Alakamisy',
						fri => 'Zoma',
						sat => 'Asabotsy',
						sun => 'Alahady'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Alats',
						tue => 'Tal',
						wed => 'Alar',
						thu => 'Alak',
						fri => 'Zom',
						sat => 'Asab',
						sun => 'Alah'
					},
					narrow => {
						mon => 'A',
						tue => 'T',
						wed => 'A',
						thu => 'A',
						fri => 'Z',
						sat => 'A',
						sun => 'A'
					},
					short => {
						mon => 'Alats',
						tue => 'Tal',
						wed => 'Alar',
						thu => 'Alak',
						fri => 'Zom',
						sat => 'Asab',
						sun => 'Alah'
					},
					wide => {
						mon => 'Alatsinainy',
						tue => 'Talata',
						wed => 'Alarobia',
						thu => 'Alakamisy',
						fri => 'Zoma',
						sat => 'Asabotsy',
						sun => 'Alahady'
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Telovolana voalohany',
						1 => 'Telovolana faharoa',
						2 => 'Telovolana fahatelo',
						3 => 'Telovolana fahefatra'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'T1',
						1 => 'T2',
						2 => 'T3',
						3 => 'T4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Telovolana voalohany',
						1 => 'Telovolana faharoa',
						2 => 'Telovolana fahatelo',
						3 => 'Telovolana fahefatra'
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
					'am' => q{AM},
					'pm' => q{PM},
				},
				'wide' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'narrow' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'wide' => {
					'am' => q{AM},
					'pm' => q{PM},
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
				'0' => 'Alohan’i JK',
				'1' => 'Aorian’i JK'
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
			'medium' => q{y MMM d},
			'short' => q{y-MM-dd},
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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
			MEd => q{E d/M},
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
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{M},
			MEd => q{E d/M},
			MMM => q{MMM},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{y-MM-dd},
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
		'gregorian' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d–d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
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
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{y MMM–MMM},
				y => q{y MMM – y MMM},
			},
			yMMMEd => {
				M => q{y MMM d, E – MMM d, E},
				d => q{y MMM d, E – MMM d, E},
				y => q{y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{y MMMM–MMMM},
				y => q{y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				d => q{y MMM d–d},
				y => q{y MMM d – y MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
	} },
);

no Moo;

1;

# vim: tabstop=4
