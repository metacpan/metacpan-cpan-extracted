=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mas - Package for language Masai

=cut

package Locale::CLDR::Locales::Mas;
# This file auto generated from Data\common\main\mas.xml
#	on Fri 13 Oct  9:26:36 am GMT

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
				'ak' => 'nkʉtʉ́k ɔ́ɔ̄ lAkan',
 				'am' => 'nkʉtʉ́k ɔ́ɔ̄ lAmhari',
 				'ar' => 'nkʉtʉ́k ɔ́ɔ̄ lmarabu',
 				'be' => 'nkʉtʉ́k ɔ́ɔ̄ lBelarusi',
 				'bg' => 'nkʉtʉ́k ɔ́ɔ̄ lBulgaria',
 				'bn' => 'lnkʉtʉ́k ɔ́ɔ̄ lBengali',
 				'cs' => 'nkʉtʉ́k ɔ́ɔ̄ lcheki',
 				'de' => 'nkʉtʉ́k ɔ́ɔ̄ ljerumani',
 				'el' => 'nkʉtʉ́k ɔ́ɔ̄ lgiriki',
 				'en' => 'nkʉtʉ́k ɔ́ɔ̄ nkɨ́resa',
 				'es' => 'nkʉtʉ́k ɔ́ɔ̄ lspania',
 				'fa' => 'nkʉtʉ́k ɔ́ɔ̄ lpersia',
 				'fr' => 'nkʉtʉ́k ɔ́ɔ̄ faransa',
 				'ha' => 'nkʉtʉ́k ɔ́ɔ̄ hausa',
 				'hi' => 'nkʉtʉ́k ɔ́ɔ̄ lmoindi',
 				'hu' => 'nkʉtʉ́k ɔ́ɔ̄ lhungari',
 				'id' => 'nkʉtʉ́k ɔ́ɔ̄ Indonesia',
 				'ig' => 'nkʉtʉ́k ɔ́ɔ̄ Igbo',
 				'it' => 'nkʉtʉ́k ɔ́ɔ̄ ltalian',
 				'ja' => 'nkʉtʉ́k ɔ́ɔ̄ japani',
 				'jv' => 'nkʉtʉ́k ɔ́ɔ̄ ljana',
 				'km' => 'nkʉtʉ́k ɔ́ɔ̄ lkambodia',
 				'ko' => 'nkʉtʉ́k ɔ́ɔ̄ lkorea',
 				'mas' => 'Maa',
 				'ms' => 'nkʉtʉ́k ɔ́ɔ̄ malay',
 				'my' => 'nkʉtʉ́k ɔ́ɔ̄ lBurma',
 				'ne' => 'nkʉtʉ́k ɔ́ɔ̄ lnepali',
 				'nl' => 'nkʉtʉ́k ɔ́ɔ̄ lduchi',
 				'pa' => 'nkʉtʉ́k ɔ́ɔ̄ lpunjabi',
 				'pl' => 'nkʉtʉ́k ɔ́ɔ̄ lpoland',
 				'pt' => 'nkʉtʉ́k ɔ́ɔ̄ lportuguese',
 				'ro' => 'nkʉtʉ́k ɔ́ɔ̄ lromania',
 				'ru' => 'nkʉtʉ́k ɔ́ɔ̄ lrusi',
 				'rw' => 'nkʉtʉ́k ɔ́ɔ̄ lruwanda',
 				'so' => 'nkʉtʉ́k ɔ́ɔ̄ lchumari',
 				'sv' => 'nkʉtʉ́k ɔ́ɔ̄ lswidi',
 				'ta' => 'nkʉtʉ́k ɔ́ɔ̄ ltamil',
 				'th' => 'nkʉtʉ́k ɔ́ɔ̄ ltai',
 				'tr' => 'nkʉtʉ́k ɔ́ɔ̄ lturuki',
 				'uk' => 'nkʉtʉ́k ɔ́ɔ̄ lkrania',
 				'ur' => 'nkʉtʉ́k ɔ́ɔ̄ lurdu',
 				'vi' => 'nkʉtʉ́k ɔ́ɔ̄ lvietinamu',
 				'yo' => 'nkʉtʉ́k ɔ́ɔ̄ lyoruba',
 				'zh' => 'nkʉtʉ́k ɔ́ɔ̄ lchina',
 				'zu' => 'nkʉtʉ́k ɔ́ɔ̄ lzulu',

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
 			'TZ' => 'Tansania',
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
 			'ZM' => 'Sambia',
 			'ZW' => 'Simbabwe',

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'metric' => q{Metric},

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
			index => ['A', 'B', 'C', 'D', 'E', 'Ɛ', 'G', 'H', 'I', 'Ɨ', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'Ʉ', 'W', 'Y'],
			main => qr{[a á à â ā b c d e é è ê ē ɛ g h i í ì î ī ɨ j k l m n {ny} ŋ o ó ò ô ō ɔ p r {rr} s {sh} t u ú ù û ū ʉ {ʉ́} w {wu} y {yi}]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'Ɛ', 'G', 'H', 'I', 'Ɨ', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'Ʉ', 'W', 'Y'], };
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
	default		=> sub { qr'^(?i:Eé|E|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Á’ā|A|no|n)$' }
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
				'currency' => q(Iropiyianí ɔ́ɔ̄ lmarabu),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Iropiyianí e Angola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Iropiyianí e Austria),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Iropiyianí e Bahareini),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Iropiyianí e Burundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Iropiyianí e Botswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Iropiyianí e Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Iropiyianí e Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Iropiyianí e Uswisi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Iropiyianí e China),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Iropiyianí e Kepuvede),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Iropiyianí e Jibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Iropiyianí e Algeria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Iropiyianí e Misri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Iropiyianí e Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Iropiyianí e Uhabeshi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Iropiyianí e yuro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Iropiyianí e Nkɨ́resa),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Iropiyianí e Ghana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Iropiyianí e Gambia),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Iropiyianí e Gine),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Iropiyianí e India),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Iropiyianí e Japani),
			},
		},
		'KES' => {
			symbol => 'Ksh',
			display_name => {
				'currency' => q(Iropiyianí e Kenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Iropiyianí e Komoro),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Iropiyianí e Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Iropiyianí e Lesoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Iropiyianí e Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Iropiyianí e Moroko),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Iropiyianí e Bukini),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Iropiyianí e Moritania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Iropiyianí e Moritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Iropiyianí e Morisi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Iropiyianí e Malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Iropiyianí e Msumbiji),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Iropiyianí e Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Iropiyianí e Nijeria),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Iropiyianí e Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Iropiyianí e Saudi),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Iropiyianí e Shelisheli),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Iropiyianí e Sudani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Iropiyianí e Santahelena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Iropiyianí e leoni),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Iropiyianí e Somalia),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Iropiyianí e Saotome \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Iropiyianí e Saotome),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Iropiyianí e lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Iropiyianí e Tunisia),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Iropiyianí e Tanzania),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Iropiyianí e Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Iropiyianí ɔ́ɔ̄ lamarekani),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Iropiyianí e CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Iropiyianí e CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Iropiyianí e Afrika Kusini),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Iropiyianí e Sambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Iropiyianí e Sambia),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Iropiyianí e Simbabwe),
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
							'Dal',
							'Ará',
							'Ɔɛn',
							'Doy',
							'Lép',
							'Rok',
							'Sás',
							'Bɔ́r',
							'Kús',
							'Gís',
							'Shʉ́',
							'Ntʉ́'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Oladalʉ́',
							'Arát',
							'Ɔɛnɨ́ɔɨŋɔk',
							'Olodoyíóríê inkókúâ',
							'Oloilépūnyīē inkókúâ',
							'Kújúɔrɔk',
							'Mórusásin',
							'Ɔlɔ́ɨ́bɔ́rárɛ',
							'Kúshîn',
							'Olgísan',
							'Pʉshʉ́ka',
							'Ntʉ́ŋʉ́s'
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
						mon => 'Jtt',
						tue => 'Jnn',
						wed => 'Jtn',
						thu => 'Alh',
						fri => 'Iju',
						sat => 'Jmo',
						sun => 'Jpi'
					},
					wide => {
						mon => 'Jumatátu',
						tue => 'Jumane',
						wed => 'Jumatánɔ',
						thu => 'Alaámisi',
						fri => 'Jumáa',
						sat => 'Jumamósi',
						sun => 'Jumapílí'
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
					abbreviated => {0 => 'E1',
						1 => 'E2',
						2 => 'E3',
						3 => 'E4'
					},
					wide => {0 => 'Erobo 1',
						1 => 'Erobo 2',
						2 => 'Erobo 3',
						3 => 'Erobo 4'
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
					'am' => q{Ɛnkakɛnyá},
					'pm' => q{Ɛndámâ},
				},
				'wide' => {
					'am' => q{Ɛnkakɛnyá},
					'pm' => q{Ɛndámâ},
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
				'0' => 'MY',
				'1' => 'EY'
			},
			wide => {
				'0' => 'Meínō Yɛ́sʉ',
				'1' => 'Eínō Yɛ́sʉ'
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
