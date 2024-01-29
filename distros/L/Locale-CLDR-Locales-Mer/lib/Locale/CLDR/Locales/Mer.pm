=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Mer - Package for language Meru

=cut

package Locale::CLDR::Locales::Mer;
# This file auto generated from Data\common\main\mer.xml
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
				'ak' => 'Kĩakani',
 				'am' => 'Kĩamarĩki',
 				'ar' => 'Kĩarabu',
 				'be' => 'Kĩbelarusi',
 				'bg' => 'Kĩbulugĩria',
 				'bn' => 'Kĩbangira',
 				'cs' => 'Kĩcheki',
 				'de' => 'Kĩnjamanĩ',
 				'el' => 'Kĩngiriki',
 				'en' => 'Kĩngeretha',
 				'es' => 'Kĩspĩni',
 				'fa' => 'Kĩpasia',
 				'fr' => 'Kĩfuransi',
 				'ha' => 'Kĩhausa',
 				'hi' => 'Kĩhĩndi',
 				'hu' => 'Kĩhangarĩ',
 				'id' => 'Kĩindonesia',
 				'ig' => 'Kĩigbo',
 				'it' => 'Kĩitalĩ',
 				'ja' => 'Kĩjapani',
 				'jv' => 'Kĩjava',
 				'km' => 'Kĩkambodia',
 				'ko' => 'Kĩkorea',
 				'mer' => 'Kĩmĩrũ',
 				'ms' => 'Kĩmalesia',
 				'my' => 'Kĩburma',
 				'ne' => 'Kĩnepali',
 				'nl' => 'Kĩholandi',
 				'pa' => 'Kĩpunjabu',
 				'pl' => 'Kĩpolandi',
 				'pt' => 'Kĩpochogo',
 				'ro' => 'Kĩromania',
 				'ru' => 'Kĩrashia',
 				'rw' => 'Kĩrwanda',
 				'so' => 'Kĩsomali',
 				'sv' => 'Kĩswideni',
 				'ta' => 'Kĩtamilu',
 				'th' => 'Kĩthailandi',
 				'tr' => 'Kĩtakĩ',
 				'uk' => 'Kĩukirĩni',
 				'ur' => 'Kĩurdu',
 				'vi' => 'Kĩvietinamu',
 				'yo' => 'Kĩyoruba',
 				'zh' => 'Kĩchina',
 				'zu' => 'Kĩzulu',

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
 			'AE' => 'Falme cia Kiarabu',
 			'AF' => 'Afuganistani',
 			'AG' => 'Antigua na Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Alubania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AR' => 'Ajentina',
 			'AS' => 'Samoa ya Amerika',
 			'AT' => 'Austiria',
 			'AU' => 'Austrĩlia',
 			'AW' => 'Aruba',
 			'AZ' => 'Azebaijani',
 			'BA' => 'Bosnia na Hezegovina',
 			'BB' => 'Babadosi',
 			'BD' => 'Bangiradeshi',
 			'BE' => 'Beronjiamu',
 			'BF' => 'Bukinafaso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Baharini',
 			'BI' => 'Burundi',
 			'BJ' => 'Benini',
 			'BM' => 'Bamuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BR' => 'Brazilu',
 			'BS' => 'Bahamasi',
 			'BT' => 'Butani',
 			'BW' => 'Botswana',
 			'BY' => 'Belarusi',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CD' => 'Nthĩ ya Kidemokrasĩ ya Kongo',
 			'CF' => 'Nthĩ ya Afrika gatĩgatĩ',
 			'CG' => 'Kongo',
 			'CH' => 'Swizilandi',
 			'CI' => 'Kodivaa',
 			'CK' => 'Aĩrandi cia Cook',
 			'CL' => 'Chile',
 			'CM' => 'Kameruni',
 			'CN' => 'China',
 			'CO' => 'Kolombia',
 			'CR' => 'Kostarika',
 			'CU' => 'Kiuba',
 			'CV' => 'Kepuvede',
 			'CY' => 'Caipurasi',
 			'CZ' => 'Nthĩ ya Cheki',
 			'DE' => 'Njamanĩ',
 			'DJ' => 'Jibuti',
 			'DK' => 'Denimaki',
 			'DM' => 'Dominika',
 			'DO' => 'Nthĩ ya Dominika',
 			'DZ' => 'Angiria',
 			'EC' => 'Ekwado',
 			'EE' => 'Estonia',
 			'EG' => 'Misiri',
 			'ER' => 'Eritrea',
 			'ES' => 'Spĩni',
 			'ET' => 'Ithiopia',
 			'FI' => 'Finilandi',
 			'FJ' => 'Fiji',
 			'FK' => 'Aĩrandi cia Falklandi',
 			'FM' => 'Mikronesia',
 			'FR' => 'Fransi',
 			'GA' => 'Gaboni',
 			'GB' => 'Ngeretha',
 			'GD' => 'Grenada',
 			'GE' => 'Jojia',
 			'GF' => 'Gwiyana ya Fransi',
 			'GH' => 'Ghana',
 			'GI' => 'Ngĩbrata',
 			'GL' => 'Ngirinilandi',
 			'GM' => 'Gambia',
 			'GN' => 'Gine',
 			'GP' => 'Gwadelupe',
 			'GQ' => 'Gine ya Iquita',
 			'GR' => 'Ngiriki',
 			'GT' => 'Gwatemala',
 			'GU' => 'Gwam',
 			'GW' => 'Ginebisau',
 			'GY' => 'Guyana',
 			'HN' => 'Hondurasi',
 			'HR' => 'Koroashia',
 			'HT' => 'Haiti',
 			'HU' => 'Hangarĩ',
 			'ID' => 'Indonesia',
 			'IE' => 'Aelandi',
 			'IL' => 'Isiraeli',
 			'IN' => 'India',
 			'IO' => 'Nthĩ cia Ngeretha gatagatĩ ka ĩria ria Hindi',
 			'IQ' => 'Iraki',
 			'IR' => 'Irani',
 			'IS' => 'Aisilandi',
 			'IT' => 'Italĩ',
 			'JM' => 'Jamaika',
 			'JO' => 'Jorondani',
 			'JP' => 'Japani',
 			'KE' => 'Kenya',
 			'KG' => 'Kirigizistani',
 			'KH' => 'Kambodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoro',
 			'KN' => 'Santakitzi na Nevis',
 			'KP' => 'Korea Nothi',
 			'KR' => 'Korea Saũthi',
 			'KW' => 'Kuwĩ ti',
 			'KY' => 'Aĩrandi cia Kayman',
 			'KZ' => 'Kazakistani',
 			'LA' => 'Laosi',
 			'LB' => 'Lebanoni',
 			'LC' => 'Santalusia',
 			'LI' => 'Lishenteni',
 			'LK' => 'Sirilanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lithuania',
 			'LU' => 'Luxembogu',
 			'LV' => 'Lativia',
 			'LY' => 'Lĩbia',
 			'MA' => 'Moroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'MG' => 'Madagasika',
 			'MH' => 'Aĩrandi cia Marshal',
 			'ML' => 'Mali',
 			'MM' => 'Myanima',
 			'MN' => 'Mongolia',
 			'MP' => 'Aĩrandi cia Mariana ya nothi',
 			'MQ' => 'Martiniki',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrati',
 			'MT' => 'Malta',
 			'MU' => 'Maurĩtiasi',
 			'MV' => 'Modivu',
 			'MW' => 'Malawi',
 			'MX' => 'Mexiko',
 			'MY' => 'Malĩsia',
 			'MZ' => 'Mozambiki',
 			'NA' => 'Namibia',
 			'NC' => 'Kalendoia Ĩnjeru',
 			'NE' => 'Nija',
 			'NF' => 'Aĩrandi cia Norfok',
 			'NG' => 'Nijeria',
 			'NI' => 'Nikaragwa',
 			'NL' => 'Holandi',
 			'NO' => 'Norwi',
 			'NP' => 'Nepali',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Niuzilandi',
 			'OM' => 'Omani',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinesia ya Fransi',
 			'PG' => 'Papua',
 			'PH' => 'Filipino',
 			'PK' => 'Pakistani',
 			'PL' => 'Polandi',
 			'PM' => 'Santapieri na Mikeloni',
 			'PN' => 'Pitkairni',
 			'PR' => 'Pwetoriko',
 			'PS' => 'Rũtere rwa Westi banki na Gaza cia Palestina',
 			'PT' => 'Potogo',
 			'PW' => 'Palau',
 			'PY' => 'Paragwai',
 			'QA' => 'Kata',
 			'RE' => 'Riyunioni',
 			'RO' => 'Romania',
 			'RU' => 'Rashia',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi',
 			'SB' => 'Airandi Cia Solomon',
 			'SC' => 'Shelisheli',
 			'SD' => 'Sudani',
 			'SE' => 'Swideni',
 			'SG' => 'Singapoo',
 			'SH' => 'Santahelena',
 			'SI' => 'Slovenia',
 			'SK' => 'Slovakia',
 			'SL' => 'Siera Leoni',
 			'SM' => 'Samarino',
 			'SN' => 'Senego',
 			'SO' => 'Somalia',
 			'SR' => 'Surinamu',
 			'ST' => 'Sao Tome na Principe',
 			'SV' => 'Elsavado',
 			'SY' => 'Siria',
 			'SZ' => 'Swazilandi',
 			'TC' => 'Aĩrandi cia Takĩ na Kaiko',
 			'TD' => 'Chadi',
 			'TG' => 'Togo',
 			'TH' => 'Thaĩlandi',
 			'TJ' => 'Tajikistani',
 			'TK' => 'Tokelau',
 			'TL' => 'Timori ya Isti',
 			'TM' => 'Tukumenistani',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Takĩ',
 			'TT' => 'Trinidad na Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwani',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukirĩni',
 			'UG' => 'Uganda',
 			'US' => 'Amerika',
 			'UY' => 'Urugwĩ',
 			'UZ' => 'Uzibekistani',
 			'VA' => 'Vatikani',
 			'VC' => 'Santavisenti na Grenadini',
 			'VE' => 'Venezuela',
 			'VG' => 'Aĩrandi cia Virgin cia Ngeretha',
 			'VI' => 'Aĩrandi cia Virgin cia Amerika',
 			'VN' => 'Vietinamu',
 			'VU' => 'Vanuatu',
 			'WF' => 'Walis na Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Yemeni',
 			'YT' => 'Mayotte',
 			'ZA' => 'Afrika ya Southi',
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
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d e f g h i ĩ j k l m n o p q r s t u ũ v w x y z]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
	default		=> sub { qr'^(?i:Ii|I|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Arĩ|A|no|n)$' }
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
				'currency' => q(Dirham ya Falme cia Kiarabu),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza ya Angola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dola ya Austrĩlia),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinari ya Baharini),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Faranga ya Burundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula ya Botswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dola ya Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Faranga ya Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Faranga ya Swisilandi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Renminbi ya China),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Eskudo ya Kepuvede),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Faranga ya Jibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinari ya Anjĩria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Paũndi ya Misri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa ya Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Bĩrũ ya Ithiopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yuro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Paũndi ya Ngeretha),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sedi ya Ghana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi ya Gambia),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Faranga ya Gine),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupia ya India),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Sarafu ya japani),
			},
		},
		'KES' => {
			symbol => 'Ksh',
			display_name => {
				'currency' => q(Shilingi ya Kenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Faranga ya Komoro),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dola ya Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti ya Lesoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinari ya Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham ya Moroko),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariarĩ ya Bukini),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ugwiya ya Mauritania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ugwiya ya Mauritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupia ya Maurĩtiasi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha ya Malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metikali ya Mozambĩkĩ),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dola ya Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira ya Nijeria),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Faranga ya Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal ya Saudi Arĩbia),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupia ya Shelisheli),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Paũndi ya Sudani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Paũndi ya Santahelena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leoni),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Shilingi ya Somalia),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra ya Sao Tome na Principe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra ya Sao Tome na Principe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinari ya Tunisia),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Shilingi ya Tanzania),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shilingi ya Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dola ya Amerika),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Faranga CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Faranga CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Randi ya Afrika ya Sauthi),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha ya Zambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha ya Zambia),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dola ya Zimbabwe),
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
							'JAN',
							'FEB',
							'MAC',
							'ĨPU',
							'MĨĨ',
							'NJU',
							'NJR',
							'AGA',
							'SPT',
							'OKT',
							'NOV',
							'DEC'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Januarĩ',
							'Feburuarĩ',
							'Machi',
							'Ĩpurũ',
							'Mĩĩ',
							'Njuni',
							'Njuraĩ',
							'Agasti',
							'Septemba',
							'Oktũba',
							'Novemba',
							'Dicemba'
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
							'Ĩ',
							'M',
							'N',
							'N',
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
						mon => 'MRA',
						tue => 'WAI',
						wed => 'WET',
						thu => 'WEN',
						fri => 'WTN',
						sat => 'JUM',
						sun => 'KIU'
					},
					wide => {
						mon => 'Muramuko',
						tue => 'Wairi',
						wed => 'Wethatu',
						thu => 'Wena',
						fri => 'Wetano',
						sat => 'Jumamosi',
						sun => 'Kiumia'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'M',
						tue => 'W',
						wed => 'W',
						thu => 'W',
						fri => 'W',
						sat => 'J',
						sun => 'K'
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
					wide => {0 => 'Ĩmwe kĩrĩ inya',
						1 => 'Ijĩrĩ kĩrĩ inya',
						2 => 'Ithatũ kĩrĩ inya',
						3 => 'Inya kĩrĩ inya'
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
					'am' => q{RŨ},
					'pm' => q{ŨG},
				},
				'wide' => {
					'am' => q{RŨ},
					'pm' => q{ŨG},
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
				'0' => 'MK',
				'1' => 'NK'
			},
			wide => {
				'0' => 'Mbere ya Kristũ',
				'1' => 'Nyuma ya Kristũ'
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
