=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Asa - Package for language Asu

=cut

package Locale::CLDR::Locales::Asa;
# This file auto generated from Data\common\main\asa.xml
#	on Fri 13 Oct  9:05:49 am GMT

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
				'ak' => 'Kiakan',
 				'am' => 'Kiamhari',
 				'ar' => 'Kiarabu',
 				'asa' => 'Kipare',
 				'be' => 'Kibelarusi',
 				'bg' => 'Kibulgaria',
 				'bn' => 'Kibangla',
 				'cs' => 'Kicheki',
 				'de' => 'Kijerumani',
 				'el' => 'Kigiriki',
 				'en' => 'Kiingeredha',
 				'es' => 'Kihithpania',
 				'fa' => 'Kiajemi',
 				'fr' => 'Kifarantha',
 				'ha' => 'Kihautha',
 				'hi' => 'Kihindi',
 				'hu' => 'Kihungari',
 				'id' => 'Kiindonethia',
 				'ig' => 'Kiigbo',
 				'it' => 'Kiitaliaano',
 				'ja' => 'Kijapani',
 				'jv' => 'Kijava',
 				'km' => 'Kikambodia',
 				'ko' => 'Kikorea',
 				'ms' => 'Kimalesia',
 				'my' => 'Kiburma',
 				'ne' => 'Kinepali',
 				'nl' => 'Kiholandhi',
 				'pa' => 'Kipunjabi',
 				'pl' => 'Kipolandi',
 				'pt' => 'Kireno',
 				'ro' => 'Kiromania',
 				'ru' => 'Kiruthi',
 				'rw' => 'Kinyarandwa',
 				'so' => 'Kithomali',
 				'sv' => 'Kithwidi',
 				'ta' => 'Kitamil',
 				'th' => 'Kitailandi',
 				'tr' => 'Kituruki',
 				'uk' => 'Kiukrania',
 				'ur' => 'Kiurdu',
 				'vi' => 'Kivietinamu',
 				'yo' => 'Kiyoruba',
 				'zh' => 'Kichina',
 				'zu' => 'Kidhulu',

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
 			'AE' => 'Falme dha Kiarabu',
 			'AF' => 'Afuganistani',
 			'AG' => 'Antigua na Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AR' => 'Ajentina',
 			'AS' => 'Thamoa ya Marekani',
 			'AT' => 'Authtria',
 			'AU' => 'Authtralia',
 			'AW' => 'Aruba',
 			'AZ' => 'Adhabajani',
 			'BA' => 'Bothnia na Hedhegovina',
 			'BB' => 'Babadothi',
 			'BD' => 'Bangladeshi',
 			'BE' => 'Ubelgiji',
 			'BF' => 'Bukinafatho',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahareni',
 			'BI' => 'Burundi',
 			'BJ' => 'Benini',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BR' => 'Brazili',
 			'BS' => 'Bahama',
 			'BT' => 'Butani',
 			'BW' => 'Botthwana',
 			'BY' => 'Belaruthi',
 			'BZ' => 'Belidhe',
 			'CA' => 'Kanada',
 			'CD' => 'Jamhuri ya Kidemokrathia ya Kongo',
 			'CF' => 'Jamhuri ya Afrika ya Kati',
 			'CG' => 'Kongo',
 			'CH' => 'Uthwithi',
 			'CI' => 'Kodivaa',
 			'CK' => 'Vithiwa vya Cook',
 			'CL' => 'Chile',
 			'CM' => 'Kameruni',
 			'CN' => 'China',
 			'CO' => 'Kolombia',
 			'CR' => 'Kothtarika',
 			'CU' => 'Kuba',
 			'CV' => 'Kepuvede',
 			'CY' => 'Kuprothi',
 			'CZ' => 'Jamhuri ya Cheki',
 			'DE' => 'Ujerumani',
 			'DJ' => 'Jibuti',
 			'DK' => 'Denmaki',
 			'DM' => 'Dominika',
 			'DO' => 'Jamhuri ya Dominika',
 			'DZ' => 'Aljeria',
 			'EC' => 'Ekwado',
 			'EE' => 'Ethtonia',
 			'EG' => 'Mithri',
 			'ER' => 'Eritrea',
 			'ES' => 'Hithpania',
 			'ET' => 'Uhabeshi',
 			'FI' => 'Ufini',
 			'FJ' => 'Fiji',
 			'FK' => 'Vithiwa vya Falkland',
 			'FM' => 'Mikronethia',
 			'FR' => 'Ufarantha',
 			'GA' => 'Gaboni',
 			'GB' => 'Uingeredha',
 			'GD' => 'Grenada',
 			'GE' => 'Jojia',
 			'GF' => 'Gwiyana ya Ufarantha',
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
 			'HN' => 'Hondurathi',
 			'HR' => 'Korathia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungaria',
 			'ID' => 'Indonethia',
 			'IE' => 'Ayalandi',
 			'IL' => 'Ithraeli',
 			'IN' => 'India',
 			'IO' => 'Ieneo la Uingeredha katika Bahari Hindi',
 			'IQ' => 'Iraki',
 			'IR' => 'Uajemi',
 			'IS' => 'Aithlandi',
 			'IT' => 'Italia',
 			'JM' => 'Jamaika',
 			'JO' => 'Yordani',
 			'JP' => 'Japani',
 			'KE' => 'Kenya',
 			'KG' => 'Kirigizithtani',
 			'KH' => 'Kambodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoro',
 			'KN' => 'Thantakitdhi na Nevith',
 			'KP' => 'Korea Kathkazini',
 			'KR' => 'Korea Kuthini',
 			'KW' => 'Kuwaiti',
 			'KY' => 'Vithiwa vya Kayman',
 			'KZ' => 'Kazakithtani',
 			'LA' => 'Laothi',
 			'LB' => 'Lebanoni',
 			'LC' => 'Thantaluthia',
 			'LI' => 'Lishenteni',
 			'LK' => 'Thirilanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lethoto',
 			'LT' => 'Litwania',
 			'LU' => 'Lathembagi',
 			'LV' => 'Lativia',
 			'LY' => 'Libya',
 			'MA' => 'Moroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'MG' => 'Bukini',
 			'MH' => 'Vithiwa vya Marshal',
 			'MK' => 'Mathedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myama',
 			'MN' => 'Mongolia',
 			'MP' => 'Vithiwa vya Mariana vya Kathkazini',
 			'MQ' => 'Martiniki',
 			'MR' => 'Moritania',
 			'MS' => 'Monttherrati',
 			'MT' => 'Malta',
 			'MU' => 'Morithi',
 			'MV' => 'Modivu',
 			'MW' => 'Malawi',
 			'MX' => 'Mekthiko',
 			'MY' => 'Malethia',
 			'MZ' => 'Mthumbiji',
 			'NA' => 'Namibia',
 			'NC' => 'Nyukaledonia',
 			'NE' => 'Nijeri',
 			'NF' => 'Kithiwa cha Norfok',
 			'NG' => 'Nijeria',
 			'NI' => 'Nikaragwa',
 			'NL' => 'Uholandhi',
 			'NO' => 'Norwe',
 			'NP' => 'Nepali',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nyudhilandi',
 			'OM' => 'Omani',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinesia ya Ufarantha',
 			'PG' => 'Papua',
 			'PH' => 'Filipino',
 			'PK' => 'Pakithtani',
 			'PL' => 'Polandi',
 			'PM' => 'Thantapieri na Mikeloni',
 			'PN' => 'Pitkairni',
 			'PR' => 'Pwetoriko',
 			'PS' => 'Palestina',
 			'PT' => 'Ureno',
 			'PW' => 'Palau',
 			'PY' => 'Paragwai',
 			'QA' => 'Katari',
 			'RE' => 'Riyunioni',
 			'RO' => 'Romania',
 			'RU' => 'Uruthi',
 			'RW' => 'Rwanda',
 			'SA' => 'Thaudi',
 			'SB' => 'Vithiwa vya Tholomon',
 			'SC' => 'Shelisheli',
 			'SD' => 'Thudani',
 			'SE' => 'Uthwidi',
 			'SG' => 'Thingapoo',
 			'SH' => 'Thantahelena',
 			'SI' => 'Thlovenia',
 			'SK' => 'Tholvakia',
 			'SL' => 'Thiera Leoni',
 			'SM' => 'Thamarino',
 			'SN' => 'Thenegali',
 			'SO' => 'Thomalia',
 			'SR' => 'Thurinamu',
 			'ST' => 'Thao Tome na Principe',
 			'SV' => 'Elsavado',
 			'SY' => 'Thiria',
 			'SZ' => 'Uthwadhi',
 			'TC' => 'Vithiwa vya Turki na Kaiko',
 			'TD' => 'Chadi',
 			'TG' => 'Togo',
 			'TH' => 'Tailandi',
 			'TJ' => 'Tajikithtani',
 			'TK' => 'Tokelau',
 			'TL' => 'Timori ya Mashariki',
 			'TM' => 'Turukimenithtani',
 			'TN' => 'Tunithia',
 			'TO' => 'Tonga',
 			'TR' => 'Uturuki',
 			'TT' => 'Trinidad na Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwani',
 			'TZ' => 'Tadhania',
 			'UG' => 'Uganda',
 			'US' => 'Marekani',
 			'UY' => 'Urugwai',
 			'UZ' => 'Udhibekithtani',
 			'VA' => 'Vatikani',
 			'VC' => 'Thantavithenti na Grenadini',
 			'VE' => 'Venezuela',
 			'VG' => 'Vithiwa vya Virgin vya Uingeredha',
 			'VI' => 'Vithiwa vya Virgin vya Marekani',
 			'VN' => 'Vietinamu',
 			'VU' => 'Vanuatu',
 			'WF' => 'Walith na Futuna',
 			'WS' => 'Thamoa',
 			'YE' => 'Yemeni',
 			'YT' => 'Mayotte',
 			'ZA' => 'Afrika Kuthini',
 			'ZM' => 'Dhambia',
 			'ZW' => 'Dhimbabwe',

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
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n o p r s t u v w y z]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
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
	default		=> sub { qr'^(?i:Iyee|I|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Hai|H|no|n)$' }
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
				'currency' => q(dirham ya Falme dha Kiarabu),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwandha ya Angola),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(dola ya Authtralia),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dinari ya Bahareni),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(faranga ya Burundi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula ya Botthwana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(dola ya Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(faranga ya Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(faranga ya Uthwithi),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(yuan renminbi ya China),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(ethkudo ya Kepuvede),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(faranga ya Jibuti),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinari ya Aljeria),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(pauni ya Mithri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nakfa ya Eritrea),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(bir ya Uhabeshi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(yuro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(pauni ya Uingeredha),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(thedi ya Ghana),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalathi ya Gambia),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(faranga ya Gine),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(rupia ya India),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(tharafu ya Kijapani),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(shilingi ya Kenya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(faranga ya Komoro),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dola ya Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti ya Lethoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinari ya Libya),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dirham ya Moroko),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(faranga ya Bukini),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ugwiya ya Moritania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ugwiya ya Moritania),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(rupia ya Morithi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha ya Malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(metikali ya Mthumbiji),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dola ya Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira ya Nijeria),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(faranga ya Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(riyal ya Thaudia),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(rupia ya Shelisheli),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(dinari ya Thudani),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(pauni ya Thudani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(pauni ya Thantahelena),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leoni),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(shilingi ya Thomalia),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(dobra ya Thao Tome na Principe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra ya Thao Tome na Principe),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinari ya Tunithia),
			},
		},
		'TZS' => {
			symbol => 'TSh',
			display_name => {
				'currency' => q(shilingi ya Tandhania),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(shilingi ya Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(dola ya Marekani),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(faranga CFA BEAC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(faranga CFA BCEAO),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(randi ya Afrika Kuthini),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(kwacha ya Dhambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwacha ya Dhambia),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(dola ya Dhimbabwe),
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
							'Mac',
							'Apr',
							'Mei',
							'Jun',
							'Jul',
							'Ago',
							'Sep',
							'Okt',
							'Nov',
							'Dec'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Januari',
							'Februari',
							'Machi',
							'Aprili',
							'Mei',
							'Juni',
							'Julai',
							'Agosti',
							'Septemba',
							'Oktoba',
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
						mon => 'Jtt',
						tue => 'Jnn',
						wed => 'Jtn',
						thu => 'Alh',
						fri => 'Ijm',
						sat => 'Jmo',
						sun => 'Jpi'
					},
					wide => {
						mon => 'Jumatatu',
						tue => 'Jumanne',
						wed => 'Jumatano',
						thu => 'Alhamisi',
						fri => 'Ijumaa',
						sat => 'Jumamosi',
						sun => 'Jumapili'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'J',
						tue => 'J',
						wed => 'J',
						thu => 'A',
						fri => 'I',
						sat => 'J',
						sun => 'J'
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
					abbreviated => {0 => 'R1',
						1 => 'R2',
						2 => 'R3',
						3 => 'R4'
					},
					wide => {0 => 'Robo 1',
						1 => 'Robo 2',
						2 => 'Robo 3',
						3 => 'Robo 4'
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
					'am' => q{icheheavo},
					'pm' => q{ichamthi},
				},
				'wide' => {
					'am' => q{icheheavo},
					'pm' => q{ichamthi},
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
				'0' => 'KM',
				'1' => 'BM'
			},
			wide => {
				'0' => 'Kabla yakwe Yethu',
				'1' => 'Baada yakwe Yethu'
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
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
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
