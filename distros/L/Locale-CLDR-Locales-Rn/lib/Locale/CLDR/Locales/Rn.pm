=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Rn - Package for language Rundi

=cut

package Locale::CLDR::Locales::Rn;
# This file auto generated from Data\common\main\rn.xml
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
				'ak' => 'Igikani',
 				'am' => 'Ikimuhariki',
 				'ar' => 'Icarabu',
 				'be' => 'Ikibelarusiya',
 				'bg' => 'Ikinyabuligariya',
 				'bn' => 'Ikibengali',
 				'cs' => 'Igiceke',
 				'de' => 'Ikidage',
 				'el' => 'Ikigereki',
 				'en' => 'Icongereza',
 				'es' => 'Icesipanyolo',
 				'fa' => 'Igiperisi',
 				'fr' => 'Igifaransa',
 				'ha' => 'Igihawusa',
 				'hi' => 'Igihindi',
 				'hu' => 'Ikinyahongiriya',
 				'id' => 'Ikinyendoziya',
 				'ig' => 'Ikigubo',
 				'it' => 'Igitaliyani',
 				'ja' => 'Ikiyapani',
 				'jv' => 'Ikinyejava',
 				'km' => 'Igikambodiya',
 				'ko' => 'Ikinyakoreya',
 				'ms' => 'Ikinyamaleziya',
 				'my' => 'Ikinyabirimaniya',
 				'ne' => 'Ikinepali',
 				'nl' => 'Igiholandi',
 				'pa' => 'Igipunjabi',
 				'pl' => 'Ikinyapolonye',
 				'pt' => 'Igiporutugari',
 				'rn' => 'Ikirundi',
 				'ro' => 'Ikinyarumaniya',
 				'ru' => 'Ikirusiya',
 				'rw' => 'Ikinyarwanda',
 				'so' => 'Igisomali',
 				'sv' => 'Igisuweduwa',
 				'ta' => 'Igitamili',
 				'th' => 'Ikinyatayilandi',
 				'tr' => 'Igiturukiya',
 				'uk' => 'Ikinyayukereni',
 				'ur' => 'Inyeyurudu',
 				'vi' => 'Ikinyaviyetinamu',
 				'yo' => 'Ikiyoruba',
 				'zh' => 'Igishinwa',
 				'zu' => 'Ikizulu',

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
 			'AE' => 'Leta Zunze Ubumwe z’Abarabu',
 			'AF' => 'Afuganisitani',
 			'AG' => 'Antigwa na Baribuda',
 			'AI' => 'Angwila',
 			'AL' => 'Alubaniya',
 			'AM' => 'Arumeniya',
 			'AO' => 'Angola',
 			'AR' => 'Arijantine',
 			'AS' => 'Samowa nyamerika',
 			'AT' => 'Otirishe',
 			'AU' => 'Ositaraliya',
 			'AW' => 'Aruba',
 			'AZ' => 'Azerubayijani',
 			'BA' => 'Bosiniya na Herigozevine',
 			'BB' => 'Barubadosi',
 			'BD' => 'Bangaladeshi',
 			'BE' => 'Ububiligi',
 			'BF' => 'Burukina Faso',
 			'BG' => 'Buligariya',
 			'BH' => 'Bahareyini',
 			'BI' => 'Uburundi',
 			'BJ' => 'Bene',
 			'BM' => 'Berimuda',
 			'BN' => 'Buruneyi',
 			'BO' => 'Boliviya',
 			'BR' => 'Burezili',
 			'BS' => 'Bahamasi',
 			'BT' => 'Butani',
 			'BW' => 'Botswana',
 			'BY' => 'Belausi',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CD' => 'Repubulika Iharanira Demokarasi ya Kongo',
 			'CF' => 'Repubulika ya Santarafurika',
 			'CG' => 'Kongo',
 			'CH' => 'Ubusuwisi',
 			'CI' => 'Kotedivuware',
 			'CK' => 'Izinga rya Kuku',
 			'CL' => 'Shili',
 			'CM' => 'Kameruni',
 			'CN' => 'Ubushinwa',
 			'CO' => 'Kolombiya',
 			'CR' => 'Kositarika',
 			'CU' => 'Kiba',
 			'CV' => 'Ibirwa bya Kapuveri',
 			'CY' => 'Izinga rya Shipure',
 			'CZ' => 'Repubulika ya Ceke',
 			'DE' => 'Ubudage',
 			'DJ' => 'Jibuti',
 			'DK' => 'Danimariki',
 			'DM' => 'Dominika',
 			'DO' => 'Repubulika ya Dominika',
 			'DZ' => 'Alijeriya',
 			'EC' => 'Ekwateri',
 			'EE' => 'Esitoniya',
 			'EG' => 'Misiri',
 			'ER' => 'Elitereya',
 			'ES' => 'Hisipaniya',
 			'ET' => 'Etiyopiya',
 			'FI' => 'Finilandi',
 			'FJ' => 'Fiji',
 			'FK' => 'Izinga rya Filikilandi',
 			'FM' => 'Mikoroniziya',
 			'FR' => 'Ubufaransa',
 			'GA' => 'Gabo',
 			'GB' => 'Ubwongereza',
 			'GD' => 'Gerenada',
 			'GE' => 'Jeworujiya',
 			'GF' => 'Gwayana y’Abafaransa',
 			'GH' => 'Gana',
 			'GI' => 'Juburalitari',
 			'GL' => 'Gurunilandi',
 			'GM' => 'Gambiya',
 			'GN' => 'Guneya',
 			'GP' => 'Gwadelupe',
 			'GQ' => 'Gineya Ekwatoriyali',
 			'GR' => 'Ubugereki',
 			'GT' => 'Gwatemala',
 			'GU' => 'Gwamu',
 			'GW' => 'Gineya Bisawu',
 			'GY' => 'Guyane',
 			'HN' => 'Hondurasi',
 			'HR' => 'Korowasiya',
 			'HT' => 'Hayiti',
 			'HU' => 'Hungariya',
 			'ID' => 'Indoneziya',
 			'IE' => 'Irilandi',
 			'IL' => 'Isiraheli',
 			'IN' => 'Ubuhindi',
 			'IO' => 'Intara y’Ubwongereza yo mu birwa by’Abahindi',
 			'IQ' => 'Iraki',
 			'IR' => 'Irani',
 			'IS' => 'Ayisilandi',
 			'IT' => 'Ubutaliyani',
 			'JM' => 'Jamayika',
 			'JO' => 'Yorudaniya',
 			'JP' => 'Ubuyapani',
 			'KE' => 'Kenya',
 			'KG' => 'Kirigisitani',
 			'KH' => 'Kamboje',
 			'KI' => 'Kiribati',
 			'KM' => 'Izinga rya Komore',
 			'KN' => 'Sekitsi na Nevisi',
 			'KP' => 'Koreya y’amajaruguru',
 			'KR' => 'Koreya y’amajepfo',
 			'KW' => 'Koweti',
 			'KY' => 'Ibirwa bya Keyimani',
 			'KZ' => 'Kazakisitani',
 			'LA' => 'Layosi',
 			'LB' => 'Libani',
 			'LC' => 'Selusiya',
 			'LI' => 'Lishyitenshitayini',
 			'LK' => 'Sirilanka',
 			'LR' => 'Liberiya',
 			'LS' => 'Lesoto',
 			'LT' => 'Lituwaniya',
 			'LU' => 'Lukusamburu',
 			'LV' => 'Lativa',
 			'LY' => 'Libiya',
 			'MA' => 'Maroke',
 			'MC' => 'Monako',
 			'MD' => 'Moludavi',
 			'MG' => 'Madagasikari',
 			'MH' => 'Izinga rya Marishari',
 			'ML' => 'Mali',
 			'MM' => 'Birimaniya',
 			'MN' => 'Mongoliya',
 			'MP' => 'Amazinga ya Mariyana ryo mu majaruguru',
 			'MQ' => 'Maritiniki',
 			'MR' => 'Moritaniya',
 			'MS' => 'Monteserati',
 			'MT' => 'Malita',
 			'MU' => 'Izinga rya Morise',
 			'MV' => 'Moludave',
 			'MW' => 'Malawi',
 			'MX' => 'Migizike',
 			'MY' => 'Maleziya',
 			'MZ' => 'Mozambiki',
 			'NA' => 'Namibiya',
 			'NC' => 'Niyukaledoniya',
 			'NE' => 'Nijeri',
 			'NF' => 'izinga rya Norufoluke',
 			'NG' => 'Nijeriya',
 			'NI' => 'Nikaragwa',
 			'NL' => 'Ubuholandi',
 			'NO' => 'Noruveji',
 			'NP' => 'Nepali',
 			'NR' => 'Nawuru',
 			'NU' => 'Niyuwe',
 			'NZ' => 'Nuvelizelandi',
 			'OM' => 'Omani',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polineziya y’Abafaransa',
 			'PG' => 'Papuwa Niyugineya',
 			'PH' => 'Amazinga ya Filipine',
 			'PK' => 'Pakisitani',
 			'PL' => 'Polonye',
 			'PM' => 'Sempiyeri na Mikeloni',
 			'PN' => 'Pitikeyirini',
 			'PR' => 'Puwetoriko',
 			'PS' => 'Palesitina Wesitibanka na Gaza',
 			'PT' => 'Porutugali',
 			'PW' => 'Palawu',
 			'PY' => 'Paragwe',
 			'QA' => 'Katari',
 			'RE' => 'Amazinga ya Reyiniyo',
 			'RO' => 'Rumaniya',
 			'RU' => 'Uburusiya',
 			'RW' => 'u Rwanda',
 			'SA' => 'Arabiya Sawudite',
 			'SB' => 'Amazinga ya Salumoni',
 			'SC' => 'Amazinga ya Seyisheli',
 			'SD' => 'Sudani',
 			'SE' => 'Suwedi',
 			'SG' => 'Singapuru',
 			'SH' => 'Sehelene',
 			'SI' => 'Siloveniya',
 			'SK' => 'Silovakiya',
 			'SL' => 'Siyeralewone',
 			'SM' => 'Sanimarino',
 			'SN' => 'Senegali',
 			'SO' => 'Somaliya',
 			'SR' => 'Suriname',
 			'ST' => 'Sawotome na Perensipe',
 			'SV' => 'Eli Saluvatori',
 			'SY' => 'Siriya',
 			'SZ' => 'Suwazilandi',
 			'TC' => 'Amazinga ya Turkisi na Cayikosi',
 			'TD' => 'Cadi',
 			'TG' => 'Togo',
 			'TH' => 'Tayilandi',
 			'TJ' => 'Tajikisitani',
 			'TK' => 'Tokelawu',
 			'TL' => 'Timoru y’iburasirazuba',
 			'TM' => 'Turukumenisitani',
 			'TN' => 'Tuniziya',
 			'TO' => 'Tonga',
 			'TR' => 'Turukiya',
 			'TT' => 'Tirinidadi na Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Tayiwani',
 			'TZ' => 'Tanzaniya',
 			'UA' => 'Ikerene',
 			'UG' => 'Ubugande',
 			'US' => 'Leta Zunze Ubumwe za Amerika',
 			'UY' => 'Irigwe',
 			'UZ' => 'Uzubekisitani',
 			'VA' => 'Umurwa wa Vatikani',
 			'VC' => 'Sevensa na Gerenadine',
 			'VE' => 'Venezuwela',
 			'VG' => 'Ibirwa by’isugi by’Abongereza',
 			'VI' => 'Amazinga y’Isugi y’Abanyamerika',
 			'VN' => 'Viyetinamu',
 			'VU' => 'Vanuwatu',
 			'WF' => 'Walisi na Futuna',
 			'WS' => 'Samowa',
 			'YE' => 'Yemeni',
 			'YT' => 'Mayote',
 			'ZA' => 'Afurika y’Epfo',
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
	default		=> qq{”},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ego|E|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Oya|O|no|n)$' }
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

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0 %',
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
				'currency' => q(Idiramu ryo muri Leta Zunze Ubumwe z’Abarabu),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Ikwanza ryo muri Angola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Idolari ryo muri Ositaraliya),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Idinari ry’iribahireyini),
			},
		},
		'BIF' => {
			symbol => 'FBu',
			display_name => {
				'currency' => q(Ifaranga ry’Uburundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Ipula ryo muri Botswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Idolari rya Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Ifaranga rya Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Ifaranga ry’Ubusuwisi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Iyuwani ryo mu Bushinwa),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Irikaboveridiyano ryo muri Esikudo),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Ifaranga ryo muri Jibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Idinari ryo muri Alijeriya),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Ipawundi rya Misiri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Irinakufa ryo muri Eritereya),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Ibiri ryo muri Etiyopiya),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Iyero),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Ipawundi ryo mu Bwongereza),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Icedi ryo muri Gana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Idalasi ryo muri Gambiya),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Ifaranga ryo muri Gineya),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Irupiya ryo mu Buhindi),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Iyeni ry’Ubuyapani),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Ishilingi rya Kenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Ifaranga rya Komore),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Idolari rya Liberiya),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Iloti ryo muro Lesoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Idinari rya Libiya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Idiramu ryo muri Maroke),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Iriyari ryo muri Madagasikari),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ugwiya ryo muri Moritaniya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ugwiya ryo muri Moritaniya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Irupiya ryo mu birwa bya Morise),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Ikwaca ryo muri Malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Irimetikali ryo muri Mozambike),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Idolari rya Namibiya),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Inayira ryo muri Nijeriya),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Ifaranga ry’u Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Iriyari ryo muri Arabiya Sawudite),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Irupiya ryo mu birwa bya Sayisheli),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Ipawundi rya Sudani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Ipawundi rya Sente Helena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Ilewone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Ilewone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Ishilingi ryo muri Somaliya),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Idobura ryo muri Sawotome na Perensipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Idobura ryo muri Sawotome na Perensipe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Ililangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Idinari ryo muri Tuniziya),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Ishilingi rya Tanzaniya),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Ishilingi ry’Ubugande),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Idolari ry’abanyamerika),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Irandi ryo muri Afurika y’Epfo),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Ikwaca ryo muri Zambiya \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Ikwaca ryo muri Zambiya),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Idolari ryo muri Zimbabwe),
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
							'Mut.',
							'Gas.',
							'Wer.',
							'Mat.',
							'Gic.',
							'Kam.',
							'Nya.',
							'Kan.',
							'Nze.',
							'Ukw.',
							'Ugu.',
							'Uku.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Nzero',
							'Ruhuhuma',
							'Ntwarante',
							'Ndamukiza',
							'Rusama',
							'Ruheshi',
							'Mukakaro',
							'Nyandagaro',
							'Nyakanga',
							'Gitugutu',
							'Munyonyo',
							'Kigarama'
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
						mon => 'mbe.',
						tue => 'kab.',
						wed => 'gtu.',
						thu => 'kan.',
						fri => 'gnu.',
						sat => 'gnd.',
						sun => 'cu.'
					},
					wide => {
						mon => 'Ku wa mbere',
						tue => 'Ku wa kabiri',
						wed => 'Ku wa gatatu',
						thu => 'Ku wa kane',
						fri => 'Ku wa gatanu',
						sat => 'Ku wa gatandatu',
						sun => 'Ku w’indwi'
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
					abbreviated => {0 => 'I1',
						1 => 'I2',
						2 => 'I3',
						3 => 'I4'
					},
					wide => {0 => 'Igice ca mbere c’umwaka',
						1 => 'Igice ca kabiri c’umwaka',
						2 => 'Igice ca gatatu c’umwaka',
						3 => 'Igice ca kane c’umwaka'
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
					'am' => q{Z.MU.},
					'pm' => q{Z.MW.},
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
				'0' => 'Mb.Y.',
				'1' => 'Ny.Y'
			},
			wide => {
				'0' => 'Mbere ya Yezu',
				'1' => 'Nyuma ya Yezu'
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
