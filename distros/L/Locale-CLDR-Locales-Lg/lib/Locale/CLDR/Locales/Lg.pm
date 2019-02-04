=encoding utf8

=head1

Locale::CLDR::Locales::Lg - Package for language Ganda

=cut

package Locale::CLDR::Locales::Lg;
# This file auto generated from Data\common\main\lg.xml
#	on Sun  3 Feb  2:02:48 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.0');

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
				'ak' => 'Lu-akaani',
 				'am' => 'Lu-amhariki',
 				'ar' => 'Luwarabu',
 				'be' => 'Lubelarusi',
 				'bg' => 'Lubulugariya',
 				'bn' => 'Lubengali',
 				'cs' => 'Luceeke',
 				'de' => 'Ludaaki',
 				'el' => 'Lugereeki/Luyonaani',
 				'en' => 'Lungereza',
 				'es' => 'Lusipanya',
 				'fa' => 'Luperusi',
 				'fr' => 'Lufalansa',
 				'ha' => 'Luhawuza',
 				'hi' => 'Luhindu',
 				'hu' => 'Luhangare',
 				'id' => 'Luyindonezya',
 				'ig' => 'Luyibo',
 				'it' => 'Luyitale',
 				'ja' => 'Lujapani',
 				'jv' => 'Lunnajjava',
 				'km' => 'Lukme',
 				'ko' => 'Lukoreya',
 				'lg' => 'Luganda',
 				'ms' => 'Lumalayi',
 				'my' => 'Lubbama',
 				'ne' => 'Lunepali',
 				'nl' => 'Luholandi',
 				'pa' => 'Lupunjabi',
 				'pl' => 'Lupolandi',
 				'pt' => 'Lupotugiizi',
 				'ro' => 'Lulomaniya',
 				'ru' => 'Lulasa',
 				'rw' => 'Lunarwanda',
 				'so' => 'Lusomaliya',
 				'sv' => 'Luswideni',
 				'ta' => 'Lutamiiru',
 				'th' => 'Luttaayi',
 				'tr' => 'Lutake',
 				'uk' => 'Luyukurayine',
 				'ur' => 'Lu-urudu',
 				'vi' => 'Luvyetinaamu',
 				'yo' => 'Luyoruba',
 				'zh' => 'Lucayina',
 				'zu' => 'Luzzulu',

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
 			'AG' => 'Antigwa ne Barabuda',
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
 			'CF' => 'Lipubulika eya Senturafiriki',
 			'CG' => 'Kongo',
 			'CH' => 'Switizirandi',
 			'CI' => 'Kote Divwa',
 			'CK' => 'Bizinga bya Kkuki',
 			'CL' => 'Cile',
 			'CM' => 'Kameruuni',
 			'CN' => 'Cayina',
 			'CO' => 'Kolombya',
 			'CR' => 'Kosita Rika',
 			'CU' => 'Cuba',
 			'CV' => 'Bizinga by’e Kepu Veredi',
 			'CY' => 'Sipuriya',
 			'CZ' => 'Lipubulika ya Ceeka',
 			'DE' => 'Budaaki',
 			'DJ' => 'Jjibuti',
 			'DK' => 'Denimaaka',
 			'DM' => 'Dominika',
 			'DO' => 'Lipubulika ya Dominika',
 			'DZ' => 'Aligerya',
 			'EC' => 'Ekwado',
 			'EE' => 'Esitoniya',
 			'EG' => 'Misiri',
 			'ER' => 'Eritureya',
 			'ES' => 'Sipeyini',
 			'ET' => 'Esyopya',
 			'FI' => 'Finilandi',
 			'FJ' => 'Fiji',
 			'FK' => 'Bizinga by’eFalikalandi',
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
 			'GQ' => 'Gayana ey’oku ekweta',
 			'GR' => 'Bugereeki/Buyonaani',
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
 			'IO' => 'Bizinga by’eCago',
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
 			'KM' => 'Bizinga by’eKomoro',
 			'KN' => 'Senti Kitisi ne Nevisi',
 			'KP' => 'Koreya ey’omumambuka',
 			'KR' => 'Koreya ey’omumaserengeta',
 			'KW' => 'Kuweti',
 			'KY' => 'Bizinga ebya Kayimaani',
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
 			'MP' => 'Bizinga bya Mariyana eby’omumambuka',
 			'MQ' => 'Maritiniiki',
 			'MR' => 'Mawulitenya',
 			'MS' => 'Monteseraati',
 			'MT' => 'Malita',
 			'MU' => 'Mawulisyasi',
 			'MV' => 'Bizinga by’eMalidive',
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
 			'PH' => 'Bizinga bya Firipino',
 			'PK' => 'Pakisitaani',
 			'PL' => 'Polandi',
 			'PM' => 'Senti Piyere ne Mikeloni',
 			'PN' => 'Pitikeeni',
 			'PR' => 'Potoriko',
 			'PS' => 'Palesitayini',
 			'PT' => 'Potugaali',
 			'PW' => 'Palawu',
 			'PY' => 'Paragwayi',
 			'QA' => 'Kataa',
 			'RE' => 'Leyunyoni',
 			'RO' => 'Lomaniya',
 			'RU' => 'Lasa',
 			'RW' => 'Rwanda',
 			'SA' => 'Sawudarebya - Buwarabu',
 			'SB' => 'Bizanga by’eSolomooni',
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
 			'ST' => 'Sanitome ne Purincipe',
 			'SV' => 'El salivado',
 			'SY' => 'Siriya',
 			'SZ' => 'Swazirandi',
 			'TC' => 'Bizinga by’eTaaka ne Kayikosi',
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
 			'TT' => 'Turindaadi ne Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Tayiwani',
 			'TZ' => 'Tanzaniya',
 			'UA' => 'Yukurayine',
 			'UG' => 'Yuganda',
 			'US' => 'Amerika',
 			'UY' => 'Wurugwayi',
 			'UZ' => 'Wuzibekisitaani',
 			'VA' => 'Vatikaani',
 			'VC' => 'Senti Vinsenti ne Gurendadiini',
 			'VE' => 'Venzwera',
 			'VG' => 'Bizinga ebya Virigini ebitwalibwa Bungereza',
 			'VI' => 'Bizinga bya Virigini eby’Amerika',
 			'VN' => 'Vyetinaamu',
 			'VU' => 'Vanawuwatu',
 			'WF' => 'Walisi ne Futuna',
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
			auxiliary => qr{[h q x]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{[a b c d e f g i j k l m n {ny} ŋ o p r s t u v w y z]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
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
	default		=> sub { qr'^(?i:Nedda|N)$' }
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
				'currency' => q(Diraamu eya Emireeti),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza ey’Angola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Doola ey’Awusiturelya),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinaali ey’eBaareeni),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Faranga ey’eburundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula ey’eBotiswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Doola ey’eKanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Faranga ey’eKongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Faranga ey’eSwitizirandi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuwani Reniminibi ey’eCayina),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Esikudo ey’Keepu Veredi),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Faranga ey’eJjibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinaali ey’Aligerya),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Pawundi ey’eMisiri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakifa ey’Eritureya),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Biiru ey’Esyopya),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yuro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pawundi ey’eBungereza),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sedi ey’eGana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi ey’eGambya),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Faranga ey’eGini),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupiya ey’eBuyindi),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yeni ey’eJapani),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Silingi ey’eKenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Faranga ey’eKomoro),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Doola ey’eLiberya),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti ey’eLesoso),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinaali ey’eLibya),
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
		'NAD' => {
			display_name => {
				'currency' => q(Doola ey’eNamibiya),
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
				'currency' => q(Pawundi ey’eSudaani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Pawundi ey’eSenti Herena),
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
				'currency' => q(Faranga ey’omu Afirika eya wakati),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Faranga ey’omu Afirika ey’ebugwanjuba),
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
						mon => 'Bal',
						tue => 'Lw2',
						wed => 'Lw3',
						thu => 'Lw4',
						fri => 'Lw5',
						sat => 'Lw6',
						sun => 'Sab'
					},
					wide => {
						mon => 'Balaza',
						tue => 'Lwakubiri',
						wed => 'Lwakusatu',
						thu => 'Lwakuna',
						fri => 'Lwakutaano',
						sat => 'Lwamukaaga',
						sun => 'Sabbiiti'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'B',
						tue => 'L',
						wed => 'L',
						thu => 'L',
						fri => 'L',
						sat => 'L',
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
					abbreviated => {0 => 'Kya1',
						1 => 'Kya2',
						2 => 'Kya3',
						3 => 'Kya4'
					},
					wide => {0 => 'Kyakuna 1',
						1 => 'Kyakuna 2',
						2 => 'Kyakuna 3',
						3 => 'Kyakuna 4'
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
				'0' => 'Kulisito nga tannaza',
				'1' => 'Bukya Kulisito Azaal'
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
