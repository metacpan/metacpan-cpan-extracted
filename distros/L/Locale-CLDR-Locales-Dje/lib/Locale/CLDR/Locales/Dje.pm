=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Dje - Package for language Zarma

=cut

package Locale::CLDR::Locales::Dje;
# This file auto generated from Data\common\main\dje.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

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
				'ak' => 'Akan senni',
 				'am' => 'Amhaarik senni',
 				'ar' => 'Laaraw senni',
 				'be' => 'Belaruus senni',
 				'bg' => 'Bulagaari senni',
 				'bn' => 'Bengali senni',
 				'cs' => 'Cek senni',
 				'de' => 'Almaŋ senni',
 				'dje' => 'Zarmaciine',
 				'el' => 'Grek senni',
 				'en' => 'Inglisi senni',
 				'es' => 'Espaaɲe senni',
 				'fa' => 'Farsi senni',
 				'fr' => 'Fransee senni',
 				'ha' => 'Hawsance senni',
 				'hi' => 'Induu senni',
 				'hu' => 'Hungaari senni',
 				'id' => 'Indoneesi senni',
 				'ig' => 'Iboo senni',
 				'it' => 'Itaali senni',
 				'ja' => 'Japonee senni',
 				'jv' => 'Javanee senni',
 				'km' => 'Kmeer senni',
 				'ko' => 'Koree senni',
 				'ms' => 'Maleezi senni',
 				'my' => 'Burme senni',
 				'ne' => 'Neepal senni',
 				'nl' => 'Holandee senni',
 				'pa' => 'Punjaabi sennii',
 				'pl' => 'Polonee senni',
 				'pt' => 'Portugee senni',
 				'ro' => 'Rumaani senni',
 				'ru' => 'Ruusi senni',
 				'rw' => 'Rwanda senni',
 				'so' => 'Somaali senni',
 				'sv' => 'Suweede senni',
 				'ta' => 'Tamil senni',
 				'th' => 'Taailandu senni',
 				'tr' => 'Turku senni',
 				'uk' => 'Ukreen senni',
 				'ur' => 'Urdu senni',
 				'vi' => 'Vietnaam senni',
 				'yo' => 'Yorbance senni',
 				'zh' => 'Sinuwa senni',
 				'zu' => 'Zulu senni',

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
			'AD' => 'Andoora',
 			'AE' => 'Laaraw Imaarawey Margantey',
 			'AF' => 'Afgaanistan',
 			'AG' => 'Antigua nda Barbuuda',
 			'AI' => 'Angiiya',
 			'AL' => 'Albaani',
 			'AM' => 'Armeeni',
 			'AO' => 'Angoola',
 			'AR' => 'Argentine',
 			'AS' => 'Ameriki Samoa',
 			'AT' => 'Otriši',
 			'AU' => 'Ostraali',
 			'AW' => 'Aruuba',
 			'AZ' => 'Azerbaayijaŋ',
 			'BA' => 'Bosni nda Herzegovine',
 			'BB' => 'Barbaados',
 			'BD' => 'Bangladeši',
 			'BE' => 'Belgiiki',
 			'BF' => 'Burkina faso',
 			'BG' => 'Bulgaari',
 			'BH' => 'Bahareen',
 			'BI' => 'Burundi',
 			'BJ' => 'Beniŋ',
 			'BM' => 'Bermuda',
 			'BN' => 'Bruunee',
 			'BO' => 'Boolivi',
 			'BR' => 'Breezil',
 			'BS' => 'Bahamas',
 			'BT' => 'Buutaŋ',
 			'BW' => 'Botswaana',
 			'BY' => 'Biloriši',
 			'BZ' => 'Beliizi',
 			'CA' => 'Kanaada',
 			'CD' => 'Kongoo demookaratiki laboo',
 			'CF' => 'Centraafriki koyra',
 			'CG' => 'Kongoo',
 			'CH' => 'Swisu',
 			'CI' => 'Kudwar',
 			'CK' => 'Kuuk gungey',
 			'CL' => 'Šiili',
 			'CM' => 'Kameruun',
 			'CN' => 'Šiin',
 			'CO' => 'Kolombi',
 			'CR' => 'Kosta rika',
 			'CU' => 'Kuuba',
 			'CV' => 'Kapuver gungey',
 			'CY' => 'Šiipur',
 			'CZ' => 'Cek labo',
 			'DE' => 'Almaaɲe',
 			'DJ' => 'Jibuuti',
 			'DK' => 'Danemark',
 			'DO' => 'Doominiki laboo',
 			'DZ' => 'Alžeeri',
 			'EC' => 'Ekwateer',
 			'EE' => 'Estooni',
 			'EG' => 'Misra',
 			'ER' => 'Eritree',
 			'ES' => 'Espaaɲe',
 			'ET' => 'Ecioopi',
 			'FI' => 'Finlandu',
 			'FJ' => 'Fiji',
 			'FK' => 'Kalkan gungey',
 			'FM' => 'Mikronezi',
 			'FR' => 'Faransi',
 			'GA' => 'Gaabon',
 			'GB' => 'Albaasalaama Marganta',
 			'GD' => 'Grenaada',
 			'GE' => 'Gorgi',
 			'GF' => 'Faransi Guyaan',
 			'GH' => 'Gaana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grinland',
 			'GM' => 'Gambi',
 			'GN' => 'Gine',
 			'GP' => 'Gwadeluup',
 			'GQ' => 'Ginee Ekwatorial',
 			'GR' => 'Greece',
 			'GT' => 'Gwatemaala',
 			'GU' => 'Guam',
 			'GW' => 'Gine-Bisso',
 			'GY' => 'Guyaane',
 			'HN' => 'Honduras',
 			'HR' => 'Krwaasi',
 			'HT' => 'Haiti',
 			'HU' => 'Hungaari',
 			'ID' => 'Indoneezi',
 			'IE' => 'Irlandu',
 			'IL' => 'Israyel',
 			'IN' => 'Indu laboo',
 			'IO' => 'Britiši Indu teekoo laama',
 			'IQ' => 'Iraak',
 			'IR' => 'Iraan',
 			'IS' => 'Ayseland',
 			'IT' => 'Itaali',
 			'JM' => 'Jamaayik',
 			'JO' => 'Urdun',
 			'JP' => 'Jaapoŋ',
 			'KE' => 'Keeniya',
 			'KG' => 'Kyrgyzstan',
 			'KH' => 'kamboogi',
 			'KI' => 'Kiribaati',
 			'KM' => 'Komoor',
 			'KN' => 'Seŋ Kitts nda Nevis',
 			'KP' => 'Gurma Kooree',
 			'KR' => 'Hawsa Kooree',
 			'KW' => 'Kuweet',
 			'KY' => 'Kayman gungey',
 			'KZ' => 'Kaazakstan',
 			'LA' => 'Laawos',
 			'LB' => 'Lubnaan',
 			'LC' => 'Seŋ Lussia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Srilanka',
 			'LR' => 'Liberia',
 			'LS' => 'Leesoto',
 			'LT' => 'Lituaani',
 			'LU' => 'Luxembourg',
 			'LV' => 'Letooni',
 			'LY' => 'Liibi',
 			'MA' => 'Maarok',
 			'MC' => 'Monako',
 			'MD' => 'Moldovi',
 			'MG' => 'Madagascar',
 			'MH' => 'Maršal gungey',
 			'ML' => 'Maali',
 			'MM' => 'Maynamar',
 			'MN' => 'Mongooli',
 			'MP' => 'Mariana Gurma Gungey',
 			'MQ' => 'Martiniiki',
 			'MR' => 'Mooritaani',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mooris gungey',
 			'MV' => 'Maldiivu',
 			'MW' => 'Malaawi',
 			'MX' => 'Mexiki',
 			'MY' => 'Maleezi',
 			'MZ' => 'Mozambik',
 			'NA' => 'Naamibi',
 			'NC' => 'Kaaledooni Taagaa',
 			'NE' => 'Nižer',
 			'NF' => 'Norfolk Gungoo',
 			'NG' => 'Naajiriia',
 			'NI' => 'Nikaragwa',
 			'NL' => 'Hollandu',
 			'NO' => 'Norveej',
 			'NP' => 'Neepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Zeelandu Taaga',
 			'OM' => 'Omaan',
 			'PA' => 'Panama',
 			'PE' => 'Peeru',
 			'PF' => 'Faransi Polineezi',
 			'PG' => 'Papua Ginee Taaga',
 			'PH' => 'Filipine',
 			'PK' => 'Paakistan',
 			'PL' => 'Poloɲe',
 			'PM' => 'Seŋ Piyer nda Mikelon',
 			'PN' => 'Pitikarin',
 			'PR' => 'Porto Riko',
 			'PS' => 'Palestine Dangay nda Gaaza',
 			'PT' => 'Portugaal',
 			'PW' => 'Palu',
 			'PY' => 'Paraguwey',
 			'QA' => 'Kataar',
 			'RE' => 'Reenioŋ',
 			'RO' => 'Rumaani',
 			'RU' => 'Iriši laboo',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudiya',
 			'SB' => 'Solomon Gungey',
 			'SC' => 'Seešel',
 			'SD' => 'Suudaŋ',
 			'SE' => 'Sweede',
 			'SG' => 'Singapur',
 			'SH' => 'Seŋ Helena',
 			'SI' => 'Sloveeni',
 			'SK' => 'Slovaaki',
 			'SL' => 'Seera Leon',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somaali',
 			'SR' => 'Surinaam',
 			'ST' => 'Sao Tome nda Prinsipe',
 			'SV' => 'Salvador laboo',
 			'SY' => 'Suuria',
 			'SZ' => 'Swaziland',
 			'TC' => 'Turk nda Kayikos Gungey',
 			'TD' => 'Caadu',
 			'TG' => 'Togo',
 			'TH' => 'Taayiland',
 			'TJ' => 'Taažikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timoor hawsa',
 			'TM' => 'Turkmenistaŋ',
 			'TN' => 'Tunizi',
 			'TO' => 'Tonga',
 			'TR' => 'Turki',
 			'TT' => 'Trinidad nda Tobaago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taayiwan',
 			'TZ' => 'Tanzaani',
 			'UA' => 'Ukreen',
 			'UG' => 'Uganda',
 			'US' => 'Ameriki Laabu Margantey',
 			'UY' => 'Uruguwey',
 			'UZ' => 'Uzbeekistan',
 			'VA' => 'Vaatikan Laama',
 			'VC' => 'Seŋvinsaŋ nda Grenadine',
 			'VE' => 'Veneezuyeela',
 			'VG' => 'Britiši Virgin gungey',
 			'VI' => 'Ameerik Virgin Gungey',
 			'VN' => 'Vietnaam',
 			'VU' => 'Vanautu',
 			'WF' => 'Wallis nda Futuna',
 			'WS' => 'Samoa',
 			'YE' => 'Yaman',
 			'YT' => 'Mayooti',
 			'ZA' => 'Hawsa Afriki Laboo',
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
			auxiliary => qr{[v]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ɲ', 'Ŋ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'W', 'X', 'Y', 'Z'],
			main => qr{[aã b c d eẽ f g h i j k l m n ɲ ŋ oõ p q r sš t u w x y zž]},
			numbers => qr{[  \- ‑ . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ɲ', 'Ŋ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'W', 'X', 'Y', 'Z'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ayyo|A|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Kala|K|no|n)$' }
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

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '#,##0.00¤',
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
				'currency' => q(Laaraw Immaara Margantey Dirham),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angoola Kwanza),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Ostraali Dollar),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahareen Dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi Fraŋ),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botswaana Pund),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanaada Dollar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Kongo Fraŋ),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Swisu Fraŋ),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Sinwa Yuan Renminbi),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kapuver Escudo),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Jibuuti Fraŋ),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Alžeeri Dinar),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Misra Pund),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritree Nafka),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Ecioopi Birr),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Eero),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Britin Pund),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Gaana Šiidi),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambi Dalasi),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Ginee Fraŋ),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indu Rupii),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Jaapoŋ Yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Keeniya Šiiliŋ),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komoor Fraŋ),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberia Dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Leezoto Loti),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Liibi Dinar),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Maarok Dirham),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Malgaaši Fraŋ),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mooritaani Ugiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mooritaani Ugiya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mooris Rupii),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malaawi Kwaca),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mozambik Metikal),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Naamibi Dollar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naajiriya Neera),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Rwanda Fraŋ),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudiya Riyal),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seešel Rupii),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Suudaŋ Dinar),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Suudaŋ Pund),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Seŋ Helena Fraŋ),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leeon),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leeon \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somaali Šiiliŋ),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Sao Tome nda Prinsipe Dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Sao Tome nda Prinsipe Dobra),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunizi Dinar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzaani Šiiliŋ),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Uganda Šiiliŋ),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Ameriki Dollar),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA Fraŋ \(BEAC\)),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(CFA Fraŋ \(BCEAO\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Hawasa Afriki Rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambi Kwaca \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Zambi Kwaca),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabwe Dollar),
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
							'Žan',
							'Fee',
							'Mar',
							'Awi',
							'Me',
							'Žuw',
							'Žuy',
							'Ut',
							'Sek',
							'Okt',
							'Noo',
							'Dee'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Žanwiye',
							'Feewiriye',
							'Marsi',
							'Awiril',
							'Me',
							'Žuweŋ',
							'Žuyye',
							'Ut',
							'Sektanbur',
							'Oktoobur',
							'Noowanbur',
							'Deesanbur'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'Ž',
							'F',
							'M',
							'A',
							'M',
							'Ž',
							'Ž',
							'U',
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
						mon => 'Ati',
						tue => 'Ata',
						wed => 'Ala',
						thu => 'Alm',
						fri => 'Alz',
						sat => 'Asi',
						sun => 'Alh'
					},
					wide => {
						mon => 'Atinni',
						tue => 'Atalaata',
						wed => 'Alarba',
						thu => 'Alhamisi',
						fri => 'Alzuma',
						sat => 'Asibti',
						sun => 'Alhadi'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'T',
						tue => 'T',
						wed => 'L',
						thu => 'M',
						fri => 'Z',
						sat => 'S',
						sun => 'H'
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
					abbreviated => {0 => 'A1',
						1 => 'A2',
						2 => 'A3',
						3 => 'A4'
					},
					wide => {0 => 'Arrubu 1',
						1 => 'Arrubu 2',
						2 => 'Arrubu 3',
						3 => 'Arrubu 4'
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
					'am' => q{Subbaahi},
					'pm' => q{Zaarikay b},
				},
				'wide' => {
					'am' => q{Subbaahi},
					'pm' => q{Zaarikay b},
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
				'0' => 'IJ',
				'1' => 'IZ'
			},
			wide => {
				'0' => 'Isaa jine',
				'1' => 'Isaa zamanoo'
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
