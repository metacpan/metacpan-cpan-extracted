=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Xog - Package for language Soga

=cut

package Locale::CLDR::Locales::Xog;
# This file auto generated from Data\common\main\xog.xml
#	on Tue  5 Dec  1:38:04 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.4');

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
				'ak' => 'Oluakaani',
 				'am' => 'Oluamhariki',
 				'ar' => 'Oluwarabu',
 				'be' => 'Olubelarusi',
 				'bg' => 'Olubulugariya',
 				'bn' => 'Olubengali',
 				'cs' => 'Oluceeke',
 				'de' => 'Oludaaki',
 				'el' => 'Oluyonaani',
 				'en' => 'Olungereza',
 				'es' => 'Olusipanya',
 				'fa' => 'Oluperusi',
 				'fr' => 'Olufalansa',
 				'ha' => 'Oluhawuza',
 				'hi' => 'Oluhindu',
 				'hu' => 'Oluhangare',
 				'id' => 'Oluyindonezya',
 				'ig' => 'Oluyibo',
 				'it' => 'Oluyitale',
 				'ja' => 'Olujapani',
 				'jv' => 'Olunnajjava',
 				'km' => 'Olukme',
 				'ko' => 'Olukoreya',
 				'ms' => 'Olumalayi',
 				'my' => 'Olubbama',
 				'ne' => 'Olunepali',
 				'nl' => 'Oluholandi',
 				'pa' => 'Olupunjabi',
 				'pl' => 'Olupolandi',
 				'pt' => 'Olupotugiizi',
 				'ro' => 'Olulomaniya',
 				'ru' => 'Olulasa',
 				'rw' => 'Olunarwanda',
 				'so' => 'Olusomaliya',
 				'sv' => 'Oluswideni',
 				'ta' => 'Olutamiiru',
 				'th' => 'Oluttaayi',
 				'tr' => 'Olutake',
 				'uk' => 'Oluyukurayine',
 				'ur' => 'Olu-urudu',
 				'vi' => 'Oluvyetinaamu',
 				'xog' => 'Olusoga',
 				'yo' => 'Oluyoruba',
 				'zh' => 'Olucayina',
 				'zu' => 'Oluzzulu',

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
 			'AE' => 'Emireeti',
 			'AF' => 'Afaganisitani',
 			'AG' => 'Antigwa ni Barabuda',
 			'AI' => 'Angwila',
 			'AL' => 'Alibaniya',
 			'AM' => 'Arameniya',
 			'AO' => 'Angola',
 			'AR' => 'Arigentina',
 			'AS' => 'Samowa omumerika',
 			'AT' => 'Awusituriya',
 			'AU' => 'Awusitureliya',
 			'AW' => 'Aruba',
 			'AZ' => 'Azerebayijaani',
 			'BA' => 'Boziniya Hezegovina',
 			'BB' => 'Barabadosi',
 			'BD' => 'Bangaladesi',
 			'BE' => 'Bubirigi',
 			'BF' => 'Burukina Faso',
 			'BG' => 'Bulugariya',
 			'BH' => 'Baareeni',
 			'BI' => 'Burundi',
 			'BJ' => 'Benini',
 			'BM' => 'Beremuda',
 			'BN' => 'Burunayi',
 			'BO' => 'Boliviya',
 			'BR' => 'Buraziiri',
 			'BS' => 'Bahamasi',
 			'BT' => 'Butaani',
 			'BW' => 'Botiswana',
 			'BY' => 'Belarusi',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CD' => 'Kongo - Zayire',
 			'CF' => 'Lipabulika ya Senturafiriki',
 			'CG' => 'Kongo',
 			'CH' => 'Switizirandi',
 			'CI' => 'Kote Divwa',
 			'CK' => 'Ebizinga bya Kkuki',
 			'CL' => 'Cile',
 			'CM' => 'Kameruuni',
 			'CN' => 'Cayina',
 			'CO' => 'Kolombya',
 			'CR' => 'Kosita Rika',
 			'CU' => 'Cuba',
 			'CV' => 'Ebizinga bya Kepu Veredi',
 			'CY' => 'Sipuriya',
 			'CZ' => 'Lipabulika ya Ceeka',
 			'DE' => 'Budaaki',
 			'DJ' => 'Jjibuti',
 			'DK' => 'Denimaaka',
 			'DM' => 'Dominika',
 			'DO' => 'Lipabulika ya Dominika',
 			'DZ' => 'Aligerya',
 			'EC' => 'Ekwado',
 			'EE' => 'Esitoniya',
 			'EG' => 'Misiri',
 			'ER' => 'Eritureya',
 			'ES' => 'Sipeyini',
 			'ET' => 'Esyopya',
 			'FI' => 'Finilandi',
 			'FJ' => 'Fiji',
 			'FK' => 'Ebiizinga bya Falikalandi',
 			'FM' => 'Mikuronezya',
 			'FR' => 'Bufalansa',
 			'GA' => 'Gaboni',
 			'GB' => 'Bungereza',
 			'GD' => 'Gurenada',
 			'GE' => 'Gyogya',
 			'GF' => 'Guyana enfalansa',
 			'GH' => 'Gana',
 			'GI' => 'Giburalita',
 			'GL' => 'Gurenelandi',
 			'GM' => 'Gambya',
 			'GN' => 'Gini',
 			'GP' => 'Gwadalupe',
 			'GQ' => 'Gayana yaku ekweta',
 			'GR' => 'Buyonaani',
 			'GT' => 'Gwatemala',
 			'GU' => 'Gwamu',
 			'GW' => 'Gini-Bisawu',
 			'GY' => 'Gayana',
 			'HN' => 'Hundurasi',
 			'HR' => 'Kurowesya',
 			'HT' => 'Hayiti',
 			'HU' => 'Hangare',
 			'ID' => 'Yindonezya',
 			'IE' => 'Ayalandi',
 			'IL' => 'Yisirayeri',
 			'IN' => 'Buyindi',
 			'IO' => 'Ebizinga bya Cago',
 			'IQ' => 'Yiraaka',
 			'IR' => 'Yiraani',
 			'IS' => 'Ayisirandi',
 			'IT' => 'Yitale',
 			'JM' => 'Jamayika',
 			'JO' => 'Yorodani',
 			'JP' => 'Japani',
 			'KE' => 'Kenya',
 			'KG' => 'Kirigizisitaani',
 			'KH' => 'Kambodya',
 			'KI' => 'Kiribati',
 			'KM' => 'Ebizinga bya Komoro',
 			'KN' => 'Senti Kitisi ne Nevisi',
 			'KP' => 'Koreya eya mumambuka',
 			'KR' => 'Koreya eya mumaserengeta',
 			'KW' => 'Kuweti',
 			'KY' => 'Ebizinga bya Kayimaani',
 			'KZ' => 'Kazakisitaani',
 			'LA' => 'Lawosi',
 			'LB' => 'Lebanoni',
 			'LC' => 'Senti Luciya',
 			'LI' => 'Licitensitayini',
 			'LK' => 'Sirilanka',
 			'LR' => 'Liberya',
 			'LS' => 'Lesoso',
 			'LT' => 'Lisuwenya',
 			'LU' => 'Lukisembaaga',
 			'LV' => 'Lativya',
 			'LY' => 'Libya',
 			'MA' => 'Moroko',
 			'MC' => 'Monako',
 			'MD' => 'Molodova',
 			'MG' => 'Madagasika',
 			'MH' => 'Bizinga bya Mariso',
 			'MK' => 'Masedoniya',
 			'ML' => 'Mali',
 			'MM' => 'Myanima',
 			'MN' => 'Mongoliya',
 			'MP' => 'Bizinga bya Mariyana ebyamumambuka',
 			'MQ' => 'Maritiniiki',
 			'MR' => 'Mawulitenya',
 			'MS' => 'Monteseraati',
 			'MT' => 'Malita',
 			'MU' => 'Mawulisyasi',
 			'MV' => 'Ebizinga bya Malidive',
 			'MW' => 'Malawi',
 			'MX' => 'Mekisiko',
 			'MY' => 'Malezya',
 			'MZ' => 'Mozambiiki',
 			'NA' => 'Namibiya',
 			'NC' => 'Kaledonya mupya',
 			'NE' => 'Nije',
 			'NF' => 'Kizinga ky’eNorofoko',
 			'NG' => 'Nayijerya',
 			'NI' => 'Nikaraguwa',
 			'NL' => 'Holandi',
 			'NO' => 'Nowe',
 			'NP' => 'Nepalo',
 			'NR' => 'Nawuru',
 			'NU' => 'Niyuwe',
 			'NZ' => 'Niyuziirandi',
 			'OM' => 'Omaani',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinesiya enfalansa',
 			'PG' => 'Papwa Nyugini',
 			'PH' => 'Ebizinga bya Firipino',
 			'PK' => 'Pakisitaani',
 			'PL' => 'Polandi',
 			'PM' => 'Senti Piyere ni Mikeloni',
 			'PN' => 'Pitikeeni',
 			'PR' => 'Potoriko',
 			'PS' => 'Palesitayini ni Gaza',
 			'PT' => 'Potugaali',
 			'PW' => 'Palawu',
 			'PY' => 'Paragwayi',
 			'QA' => 'Kataa',
 			'RE' => 'Leyunyoni',
 			'RO' => 'Lomaniya',
 			'RU' => 'Lasa',
 			'RW' => 'Rwanda',
 			'SA' => 'Sawudarebya',
 			'SB' => 'Ebizanga bya Solomooni',
 			'SC' => 'Sesere',
 			'SD' => 'Sudaani',
 			'SE' => 'Swideni',
 			'SG' => 'Singapowa',
 			'SH' => 'Senti Herena',
 			'SI' => 'Sirovenya',
 			'SK' => 'Sirovakya',
 			'SL' => 'Siyeralewone',
 			'SM' => 'Sanimarino',
 			'SN' => 'Senegaalo',
 			'SO' => 'Somaliya',
 			'SR' => 'Surinaamu',
 			'ST' => 'Sanitome ni Purincipe',
 			'SV' => 'El salivado',
 			'SY' => 'Siriya',
 			'SZ' => 'Swazirandi',
 			'TC' => 'Ebizinga bya Taaka ni Kayikosi',
 			'TD' => 'Caadi',
 			'TG' => 'Togo',
 			'TH' => 'Tayirandi',
 			'TJ' => 'Tajikisitaani',
 			'TK' => 'Tokelawu',
 			'TL' => 'Timowa',
 			'TM' => 'Takimenesitaani',
 			'TN' => 'Tunisya',
 			'TO' => 'Tonga',
 			'TR' => 'Ttake',
 			'TT' => 'Turindaadi ni Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Tayiwani',
 			'UA' => 'Yukurayine',
 			'UG' => 'Yuganda',
 			'US' => 'Amerika',
 			'UY' => 'Wurugwayi',
 			'UZ' => 'Wuzibekisitaani',
 			'VA' => 'Vatikaani',
 			'VC' => 'Senti Vinsenti ni Gurendadiini',
 			'VE' => 'Venzwera',
 			'VG' => 'Ebizinga bya Virigini ebitwalibwa Bungereza',
 			'VI' => 'Ebizinga bya Virigini eby’Amerika',
 			'VN' => 'Vyetinaamu',
 			'VU' => 'Vanawuwatu',
 			'WF' => 'Walisi ni Futuna',
 			'WS' => 'Samowa',
 			'YE' => 'Yemeni',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sawusafirika',
 			'ZM' => 'Zambya',
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
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z]},
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
	default		=> sub { qr'^(?i:Ye|Y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Be|B|no|n)$' }
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
						'positive' => '#,##0.00 ¤',
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
				'currency' => q(Diraamu eya Emireeti),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza y’Angola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Doola y’Awusiturelya),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinaali ya Baareeni),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Faranga ya burundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula ya Botiswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Doola ya Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Faranga ya Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Faranga ey’eSwitizirandi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuwani Reniminibi ya Cayina),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Esikudo ya Keepu Veredi),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Faranga ya Jjibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinaali y’Aligerya),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Pawunda ya Misiri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakifa ya Eritureya),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Biiru ya Esyopya),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yuro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pawunda ya Bungereza),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sedi ya Gana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi ya Gambya),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Faranga ya Gini),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupiya ya Buyindi),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yeni ya Japani),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Silingi ya Kenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Faranga ya Komoro),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Doola ya Liberya),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti ya Lesoso),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinaali ya Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Diraamu ey’eMoroko),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Faranga ey’eMalagase),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Wugwiya ey’eMawritenya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Wugwiya ey’eMawritenya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupiya ey’eMawurisyasi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwaca ey’eMalawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metikaali ey’eMozambiiki),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nayira ey’eNayijerya),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Faranga ey’eRwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyaali ey’eBuwarabu),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupiya ey’eSesere),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Dinaali ey’eSudaani),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Pawunda ey’eSudaani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Pawunda ey’eSenti Herena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Lewone),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Silingi ey’eSomaliya),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobura ey’eSantome ne Purincipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobura ey’eSantome ne Purincipe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinaali ey’eTunizya),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Silingi ey’eTanzaniya),
			},
		},
		'UGX' => {
			symbol => 'USh',
			display_name => {
				'currency' => q(Silingi eya Yuganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Doola ey’Amerika),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Faranga yamu Afirika ya wakati),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Faranga yamu Afirika ya bugwanjuba),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Randi ey’eSawusafirika),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwaca ey’eZambya \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwaca ey’eZambya),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Doola ey’eZimbabwe),
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
							'Apu',
							'Maa',
							'Juu',
							'Jul',
							'Agu',
							'Seb',
							'Oki',
							'Nov',
							'Des'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Janwaliyo',
							'Febwaliyo',
							'Marisi',
							'Apuli',
							'Maayi',
							'Juuni',
							'Julaayi',
							'Agusito',
							'Sebuttemba',
							'Okitobba',
							'Novemba',
							'Desemba'
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
						mon => 'Bala',
						tue => 'Kubi',
						wed => 'Kusa',
						thu => 'Kuna',
						fri => 'Kuta',
						sat => 'Muka',
						sun => 'Sabi'
					},
					wide => {
						mon => 'Balaza',
						tue => 'Owokubili',
						wed => 'Owokusatu',
						thu => 'Olokuna',
						fri => 'Olokutaanu',
						sat => 'Olomukaaga',
						sun => 'Sabiiti'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'B',
						tue => 'B',
						wed => 'S',
						thu => 'K',
						fri => 'K',
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
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					wide => {0 => 'Ebisera ebyomwaka ebisoka',
						1 => 'Ebisera ebyomwaka ebyokubiri',
						2 => 'Ebisera ebyomwaka ebyokusatu',
						3 => 'Ebisera ebyomwaka ebyokuna'
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
					'am' => q{Munkyo},
					'pm' => q{Eigulo},
				},
				'wide' => {
					'am' => q{Munkyo},
					'pm' => q{Eigulo},
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
				'0' => 'AZ',
				'1' => 'AF'
			},
			wide => {
				'0' => 'Kulisto nga azilawo',
				'1' => 'Kulisto nga affile'
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
