=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Tzm - Package for language Central Atlas Tamazight

=cut

package Locale::CLDR::Locales::Tzm;
# This file auto generated from Data\common\main\tzm.xml
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
				'ak' => 'Takanit',
 				'am' => 'Tamharit',
 				'ar' => 'Taεrabt',
 				'be' => 'Tabilarusit',
 				'bg' => 'Tabelɣarit',
 				'bn' => 'Tabinɣalit',
 				'cs' => 'Tačikt',
 				'de' => 'Talmanit',
 				'el' => 'Tayunanit',
 				'en' => 'Tanglizt',
 				'es' => 'tasbelyunit',
 				'fa' => 'Tafarisit',
 				'fr' => 'Tafṛansist',
 				'ha' => 'Tahawsat',
 				'hi' => 'Tahindit',
 				'hu' => 'Tahenɣarit',
 				'id' => 'Tindunisit',
 				'ig' => 'Tigbut',
 				'it' => 'Taṭalyant',
 				'ja' => 'Tajappunit',
 				'jv' => 'Tajavanit',
 				'km' => 'Taxmert ,Talammast',
 				'ko' => 'Takurit',
 				'ms' => 'Tamalizit',
 				'my' => 'Taburmanit',
 				'ne' => 'Tanippalit',
 				'nl' => 'Tahulanḍit',
 				'pa' => 'Tabenjabit',
 				'pl' => 'Tappulunit',
 				'pt' => 'Taburtuɣalit',
 				'ro' => 'Taṛumanit',
 				'ru' => 'Tarusit',
 				'rw' => 'Tarwandit',
 				'so' => 'Taṣumalit',
 				'sv' => 'Taswidit',
 				'ta' => 'Tatamilt',
 				'th' => 'Taṭayt',
 				'tr' => 'Taturkit',
 				'tzm' => 'Tamaziɣt n laṭlaṣ',
 				'uk' => 'Tukranit',
 				'ur' => 'Turdut',
 				'vi' => 'Taviṭnamit',
 				'yo' => 'Tayurubat',
 				'zh' => 'Tacinwit,Mandarin',
 				'zu' => 'tazulut',

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
			'AD' => 'Anḍurra',
 			'AE' => 'Imarat Tiεrabin Tidduklin',
 			'AF' => 'Afɣanistan',
 			'AG' => 'Antigwa d Barbuda',
 			'AI' => 'Angwilla',
 			'AL' => 'Albanya',
 			'AM' => 'Arminya',
 			'AO' => 'Angula',
 			'AR' => 'Arjuntin',
 			'AS' => 'Samwa Imirikaniyyin',
 			'AT' => 'Ustriyya',
 			'AU' => 'Usṭralya',
 			'AW' => 'Aruba',
 			'AZ' => 'Azerbiǧan',
 			'BA' => 'Busna-d-Hirsik',
 			'BB' => 'Barbadus',
 			'BD' => 'Bangladic',
 			'BE' => 'Beljika',
 			'BF' => 'Burkina Fasu',
 			'BG' => 'Belɣarya',
 			'BH' => 'Baḥrayn',
 			'BI' => 'Burundi',
 			'BJ' => 'Binin',
 			'BM' => 'Birmuda',
 			'BN' => 'Brunay',
 			'BO' => 'Bulivya',
 			'BR' => 'Bṛazil',
 			'BS' => 'Bahamas',
 			'BT' => 'Buṭan',
 			'BW' => 'Butswana',
 			'BY' => 'Bilarusya',
 			'BZ' => 'Biliz',
 			'CA' => 'Kanada',
 			'CD' => 'Tagduda Tadimuqraṭit n Kungu',
 			'CF' => 'Tagduda n Afrika Wammas',
 			'CG' => 'Kungu',
 			'CH' => 'Swisra',
 			'CI' => 'Taɣazut n Uszer',
 			'CK' => 'Tigzirin n Kuk',
 			'CL' => 'Ccili',
 			'CM' => 'Kamerun',
 			'CN' => 'Ṣṣin',
 			'CO' => 'Kulumbya',
 			'CR' => 'Kusṭa Rika',
 			'CU' => 'kuba',
 			'CV' => 'Tigzirin n Iɣf Uzegzaw',
 			'CY' => 'Qubrus',
 			'CZ' => 'Tagduda n Čik',
 			'DE' => 'Almanya',
 			'DJ' => 'Ǧibuti',
 			'DK' => 'Danmark',
 			'DM' => 'Ḍuminika',
 			'DO' => 'Tagduda n Ḍuminikan',
 			'DZ' => 'Dzayer',
 			'EC' => 'Ikwaḍur',
 			'EE' => 'Isṭunya',
 			'EG' => 'Miṣr',
 			'ER' => 'Iritrya',
 			'ES' => 'Sbanya',
 			'ET' => 'Ityupya',
 			'FI' => 'Finlanḍa',
 			'FJ' => 'Fiji',
 			'FK' => 'Tigzirin n Falkland',
 			'FM' => 'Mikrunizya',
 			'FR' => 'Fṛansa',
 			'GA' => 'Gabun',
 			'GB' => 'Tagelda Taddukelt',
 			'GD' => 'Grinada',
 			'GE' => 'Jyurjya',
 			'GF' => 'Guyana Tafransist',
 			'GH' => 'Ɣana',
 			'GI' => 'Jibralṭar',
 			'GL' => 'Grinlanḍa',
 			'GM' => 'Gambya',
 			'GN' => 'Ɣinya',
 			'GP' => 'Gwadalup',
 			'GQ' => 'Ɣinya Tikwaṭur it',
 			'GR' => 'Yunan',
 			'GT' => 'Gwatimala',
 			'GU' => 'Gwam',
 			'GW' => 'Ɣinya-Bissaw',
 			'GY' => 'Guyana',
 			'HN' => 'Hinduras',
 			'HR' => 'Krwatya',
 			'HT' => 'Hayti',
 			'HU' => 'Henɣarya',
 			'ID' => 'Indunizya',
 			'IE' => 'Irlanḍa',
 			'IL' => 'Israeil',
 			'IN' => 'Hind',
 			'IO' => 'Amur n Agaraw Uhindi Ubṛiṭani',
 			'IQ' => 'Ɛiraq',
 			'IR' => 'Iran',
 			'IS' => 'Islanḍa',
 			'IT' => 'Iṭalya',
 			'JM' => 'Jamayka',
 			'JO' => 'Urḍun',
 			'JP' => 'Jjappun',
 			'KE' => 'Kinya',
 			'KG' => 'Kirɣistan',
 			'KH' => 'Kambudj',
 			'KI' => 'Kiribati',
 			'KM' => 'Qumur',
 			'KN' => 'Santekits d Nivis',
 			'KP' => 'Kurya Tugafat',
 			'KR' => 'Kurya Tunẓult',
 			'KW' => 'Kuwwayt',
 			'KY' => 'Tigzirin n Kayman',
 			'KZ' => 'Kazaxistan',
 			'LA' => 'Laws',
 			'LB' => 'Lubnan',
 			'LC' => 'Santelusya',
 			'LI' => 'Lictencṭayn',
 			'LK' => 'Srilanka',
 			'LR' => 'Libirya',
 			'LS' => 'Lisuṭu',
 			'LT' => 'Litwanya',
 			'LU' => 'Liksumburg',
 			'LV' => 'Liṭṭunya',
 			'LY' => 'Libya',
 			'MA' => 'Meṛṛuk',
 			'MC' => 'Munaku',
 			'MD' => 'Mulḍavya',
 			'MG' => 'Madaɣacqar',
 			'MH' => 'Tigzirin n Marcal',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar',
 			'MN' => 'Manɣulya',
 			'MP' => 'Tigzirin n Maryana Tugafat',
 			'MQ' => 'Martinik',
 			'MR' => 'Muritanya',
 			'MS' => 'Muntsirra',
 			'MT' => 'Malṭa',
 			'MU' => 'Muris',
 			'MV' => 'Maldiv',
 			'MW' => 'Malawi',
 			'MX' => 'Miksik',
 			'MY' => 'Malizya',
 			'MZ' => 'Muzambiq',
 			'NA' => 'Namibya',
 			'NC' => 'kalidunya Tamaynut',
 			'NE' => 'Nnijer',
 			'NF' => 'Tigzirt Nurfulk',
 			'NG' => 'Nijiria',
 			'NI' => 'Nikaragwa',
 			'NL' => 'Hulanḍa',
 			'NO' => 'Nnurwij',
 			'NP' => 'Nippal',
 			'NR' => 'Nawru',
 			'NU' => 'Niwi',
 			'NZ' => 'Zilanḍa Tamaynut',
 			'OM' => 'Ɛumman',
 			'PA' => 'Panama',
 			'PE' => 'Piru',
 			'PF' => 'Pulinizya Tafransist',
 			'PG' => 'Papwa Ɣinya Tamaynut',
 			'PH' => 'Filippin',
 			'PK' => 'Pakistan',
 			'PL' => 'Pulunya',
 			'PM' => 'Santepyir d Mikelun',
 			'PN' => 'Pitkirn',
 			'PR' => 'Purturiku',
 			'PS' => 'Agemmaḍ Ugut d Ɣazza Ifilisṭiniyen',
 			'PT' => 'Purtuɣal',
 			'PW' => 'Palu',
 			'PY' => 'Paragway',
 			'QA' => 'Qaṭar',
 			'RE' => 'Riyyunyun',
 			'RO' => 'Ṛumanya',
 			'RU' => 'Rusya',
 			'RW' => 'Ruwwanḍa',
 			'SA' => 'Ssaεudiyya Taεrabt',
 			'SB' => 'Tigzirin n Salumun',
 			'SC' => 'Ssicil',
 			'SD' => 'Ssudan',
 			'SE' => 'Ssewwid',
 			'SG' => 'Sanɣafura',
 			'SH' => 'Santehilin',
 			'SI' => 'Sluvinya',
 			'SK' => 'Sluvakya',
 			'SL' => 'Siralyun',
 			'SM' => 'Sanmarinu',
 			'SN' => 'Ssiniɣal',
 			'SO' => 'Ṣṣumal',
 			'SR' => 'Surinam',
 			'ST' => 'Sawṭumi d Prinsip',
 			'SV' => 'Salvaḍur',
 			'SY' => 'Surya',
 			'SZ' => 'Swazilanḍa',
 			'TC' => 'Tigzirin Turkiyyin d Tikaykusin',
 			'TD' => 'Tcad',
 			'TG' => 'Ṭṭugu',
 			'TH' => 'Ṭaylanḍa',
 			'TJ' => 'Ṭaǧikistan',
 			'TK' => 'Tuklu',
 			'TL' => 'Timur Tagmuṭ',
 			'TM' => 'Turkmanistan',
 			'TN' => 'Tunes',
 			'TO' => 'Ṭunga',
 			'TR' => 'Turkya',
 			'TT' => 'Trinidad d Ṭubagu',
 			'TV' => 'Ṭuvalu',
 			'TW' => 'Ṭaywan',
 			'TZ' => 'Ṭanzanya',
 			'UA' => 'Ukranya',
 			'UG' => 'Uɣanda',
 			'US' => 'Iwunak Idduklen n Amirika',
 			'UY' => 'Urugway',
 			'UZ' => 'Uzbakistan',
 			'VA' => 'Awank iɣrem n Vatikan',
 			'VC' => 'Santevinsent d Grinadin',
 			'VE' => 'Vinzwilla',
 			'VG' => 'Tigzirin (Virgin) Tibṛiṭaniyin',
 			'VI' => 'Tigzirin n Virjin n Iwunak Yedduklen',
 			'VN' => 'Viṭnam',
 			'VU' => 'Vanwatu',
 			'WF' => 'Walis d Futuna',
 			'WS' => 'Samwa',
 			'YE' => 'Yaman',
 			'YT' => 'Mayuṭ',
 			'ZA' => 'Tafrikt Tunẓul',
 			'ZM' => 'Zambya',
 			'ZW' => 'Zimbabwi',

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
			auxiliary => qr{[o p v]},
			index => ['A', 'B', 'C', 'DḌ', 'E', 'Ɛ', 'F', 'G', 'Ɣ', 'HḤ', 'I', 'J', 'K', 'L', 'M', 'N', 'Q', 'RṚ', 'SṢ', 'TṬ', 'U', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c dḍ e ɛ f g {gʷ} ɣ hḥ i j k {kʷ} l m n q rṛ sṣ tṭ u w x y z]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'DḌ', 'E', 'Ɛ', 'F', 'G', 'Ɣ', 'HḤ', 'I', 'J', 'K', 'L', 'M', 'N', 'Q', 'RṚ', 'SṢ', 'TṬ', 'U', 'W', 'X', 'Y', 'Z'], };
},
);


has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Yeh|Y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Uhu|U|no|n)$' }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
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
				'currency' => q(Derhem Uymarati),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza Unguli),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Ḍular Usṭrali),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Ḍinar Ubaḥrayni),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Frank Uburundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula Ubutswani),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Ḍular Ukanadi),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Frank Ukunguli),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Frank Uswisri),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Ywan Renminbi Ucinwi),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Iskudu Ukabuvirdyani),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Frank Uğibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Ḍinar Udzayri),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Junih Umiṣṛi),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa Uyritri),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr Uyityuppi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Uṛu),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Junih Ubriṭani),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sidi Uɣani),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi Agambi),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Frank Uɣini),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupi Uḥindi),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yann Ujappuni),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Cillin Ukini),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Frank Uqumuri),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Ḍular Ulibiri),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Luti Ulusuṭi),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Ḍinar Ulibi),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Derhem Umeṛṛuki),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Aryari Umalɣaci),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Uqiyya Umuritani \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Uqiyya Umuritani),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupi Umurisi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwača Umalawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mitikal Umuzambiqi),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Ḍular Unamibi),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nayra Unijiri),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Frank Urwandi),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Ryal Usaεudi),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupi Usicili),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Junih Usudani),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Junih Usudani \(1956–2007\)),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Junih Usantehilini),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Lyun Usirralyuni),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Lyun Usirralyuni \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Cilin Uṣumali),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dubra Usawṭumi \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dubra Usawṭumi),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilanjini Uswazi),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Ḍinar Utunsi),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Cilin Uṭanzani),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Cilin Uɣandi \(1966–1987\)),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Ḍular Umirikani),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Frank CFA \(BEAC\)),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Frank CFA \(BCEAO\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand Ufriki Unzul),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwača Uzambi \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwača Uzambi),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Ḍular Uzimbabwi),
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
							'Yen',
							'Yeb',
							'Mar',
							'Ibr',
							'May',
							'Yun',
							'Yul',
							'Ɣuc',
							'Cut',
							'Kṭu',
							'Nwa',
							'Duj'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Yennayer',
							'Yebrayer',
							'Mars',
							'Ibrir',
							'Mayyu',
							'Yunyu',
							'Yulyuz',
							'Ɣuct',
							'Cutanbir',
							'Kṭuber',
							'Nwanbir',
							'Dujanbir'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'Y',
							'Y',
							'M',
							'I',
							'M',
							'Y',
							'Y',
							'Ɣ',
							'C',
							'K',
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
						mon => 'Ayn',
						tue => 'Asn',
						wed => 'Akr',
						thu => 'Akw',
						fri => 'Asm',
						sat => 'Asḍ',
						sun => 'Asa'
					},
					wide => {
						mon => 'Aynas',
						tue => 'Asinas',
						wed => 'Akras',
						thu => 'Akwas',
						fri => 'Asimwas',
						sat => 'Asiḍyas',
						sun => 'Asamas'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'A',
						tue => 'A',
						wed => 'A',
						thu => 'A',
						fri => 'A',
						sat => 'A',
						sun => 'A'
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
					abbreviated => {0 => 'IA1',
						1 => 'IA2',
						2 => 'IA3',
						3 => 'IA4'
					},
					wide => {0 => 'Imir adamsan 1',
						1 => 'Imir adamsan 2',
						2 => 'Imir adamsan 3',
						3 => 'Imir adamsan 4'
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
					'am' => q{Zdat azal},
					'pm' => q{Ḍeffir aza},
				},
				'wide' => {
					'am' => q{Zdat azal},
					'pm' => q{Ḍeffir aza},
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
				'0' => 'ZƐ',
				'1' => 'ḌƐ'
			},
			wide => {
				'0' => 'Zdat Ɛisa (TAƔ)',
				'1' => 'Ḍeffir Ɛisa (TAƔ)'
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
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			Md => q{M/d},
			hm => q{h:mm a},
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
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMEd => q{E, MMMM d},
			Md => q{M/d},
			hm => q{h:mm a},
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
