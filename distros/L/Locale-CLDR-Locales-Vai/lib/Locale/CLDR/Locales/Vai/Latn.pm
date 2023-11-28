=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Vai::Latn - Package for language Vai

=cut

package Locale::CLDR::Locales::Vai::Latn;
# This file auto generated from Data\common\main\vai_Latn.xml
#	on Sat  4 Nov  6:29:48 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.3');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Vai');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'ak' => 'Akaŋ',
 				'am' => 'Amihári',
 				'ar' => 'Lahabu',
 				'be' => 'Bhelarusaŋ',
 				'bg' => 'Bhɔgerɛŋ',
 				'bn' => 'Bhɛŋgáli',
 				'cs' => 'Chɛ',
 				'de' => 'Jamáĩ',
 				'el' => 'Hɛlɛŋ',
 				'en' => 'Poo',
 				'es' => 'Panyɛĩ',
 				'fa' => 'Pɛɛsiyɛŋ',
 				'fr' => 'Fɛŋsi',
 				'ha' => 'Hawusa',
 				'hi' => 'Híiŋdi',
 				'hu' => 'Hɔŋgérɛŋ',
 				'id' => 'Índonisiyɛŋ',
 				'ig' => 'Ígbo',
 				'it' => 'Itáliyɛŋ',
 				'ja' => 'Japaníĩ',
 				'jv' => 'Javaníĩ',
 				'km' => 'Kimɛɛ̃ tɛ',
 				'ko' => 'Koríyɛŋ',
 				'ms' => 'Maléee',
 				'my' => 'Bhɛmísi',
 				'ne' => 'Nipali',
 				'nl' => 'Dɔchi',
 				'pa' => 'Puŋjabhi',
 				'pl' => 'Pɔ́lési',
 				'pt' => 'Potokíi',
 				'ro' => 'Romíniyɛŋ',
 				'ru' => 'Rɔshiyɛŋ',
 				'rw' => 'Rawunda',
 				'so' => 'Somáli',
 				'sv' => 'Súwídɛŋ',
 				'ta' => 'Tamíli',
 				'th' => 'Tái',
 				'tr' => 'Tɔ́ki',
 				'uk' => 'Yukureniyɛŋ',
 				'ur' => 'Ɔdu',
 				'vai' => 'Vai',
 				'vi' => 'Viyamíĩ',
 				'yo' => 'Yóróbha',
 				'zh' => 'Chaniĩ',
 				'zu' => 'Zúlu',

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
			'AD' => 'Aŋdóra',
 			'AE' => 'Yunaitɛ Arabhi Ɛmire',
 			'AF' => 'Afigándesitaŋ',
 			'AG' => 'Aŋtígwa Ɓahabhuda',
 			'AI' => 'Aŋgíla',
 			'AL' => 'Abhaniya',
 			'AM' => 'Améniya',
 			'AO' => 'Aŋgóla',
 			'AR' => 'Ajɛŋtína',
 			'AS' => 'Poo Sambowa',
 			'AT' => 'Ɔ́situwa',
 			'AU' => 'Ɔsituwéeliya',
 			'AW' => 'Arubha',
 			'AZ' => 'Azabhaijaŋ',
 			'BA' => 'Bhɔsiniya',
 			'BB' => 'Bhabhedo',
 			'BD' => 'Bhangiladɛ̀shi',
 			'BE' => 'Bhɛgiyɔŋ',
 			'BF' => 'Bhokina Fáso',
 			'BG' => 'Bhɔgeriya',
 			'BH' => 'Bharɛŋ',
 			'BI' => 'Bhurundi',
 			'BJ' => 'Bhɛni',
 			'BM' => 'Bhɛmuda',
 			'BN' => 'Bhurunɛĩ',
 			'BO' => 'Bholiviya',
 			'BR' => 'Bhurazeli',
 			'BS' => 'Bahámasi',
 			'BT' => 'Bhutaŋ',
 			'BW' => 'Bhosuwana',
 			'BY' => 'Bhɛlarusi',
 			'BZ' => 'Bheliz',
 			'CA' => 'Kánáda',
 			'CD' => 'Avorekoo',
 			'CF' => 'Áfíríka Lumaã Tɛ Boloe',
 			'CG' => 'Kóngo',
 			'CH' => 'Suweza Lumaã',
 			'CI' => 'Kódivówa',
 			'CK' => 'Kóki Tiŋŋɛ',
 			'CL' => 'Chéli',
 			'CM' => 'Kameruŋ',
 			'CN' => 'Cháína',
 			'CO' => 'Kɔlɔmbiya',
 			'CR' => 'Kósíta Ríko',
 			'CU' => 'Kiyubha',
 			'CV' => 'Kepi Vɛdi Tiŋŋɛ',
 			'CY' => 'Saɛpurɔ',
 			'CZ' => 'Chɛki Boloe',
 			'DE' => 'Jamáĩ',
 			'DJ' => 'Jibhuti',
 			'DK' => 'Danimaha',
 			'DM' => 'Domíiníka',
 			'DO' => 'Domíiníka Ɓoloe',
 			'DZ' => 'Agiriya',
 			'EC' => 'Ɛ́kúwédɔ',
 			'EE' => 'Ɛsitóninya',
 			'EG' => 'Míséla',
 			'ER' => 'Ɛritera',
 			'ES' => 'Panyɛĩ',
 			'ET' => 'Ítiyópiya',
 			'FI' => 'Fiŋlɛŋ',
 			'FJ' => 'Fíji',
 			'FK' => 'Fáháki Luma Tiŋŋɛ',
 			'FM' => 'Mikonisiya',
 			'FR' => 'Fɛŋsi',
 			'GA' => 'Gabhɔŋ',
 			'GB' => 'Yunaitɛ Kíŋdɔŋ',
 			'GD' => 'Gurinéda',
 			'GE' => 'Jɔɔjiya',
 			'GF' => 'Fɛŋsi Giwana',
 			'GH' => 'Gana',
 			'GI' => 'Jibhurata',
 			'GL' => 'Jamba Kuwa Lumaã',
 			'GM' => 'Gambiya',
 			'GN' => 'Gini',
 			'GP' => 'Guwadelupe',
 			'GQ' => 'Dúúnyá Tɛ Giini',
 			'GR' => 'Hɛlɛŋ',
 			'GT' => 'Guwatɛmala',
 			'GU' => 'Guwami',
 			'GW' => 'Gini Bhisawo',
 			'GY' => 'Guyana',
 			'HN' => 'Hɔndura',
 			'HR' => 'Koresiya',
 			'HT' => 'Háiti',
 			'HU' => 'Hɔ́ngare',
 			'ID' => 'Índonisiya',
 			'IE' => 'Áre Lumaã',
 			'IL' => 'Bhanísiláila',
 			'IN' => 'Índiya',
 			'IO' => 'Jengéesi Gbawoe Índiya Kɔiyɛ Lɔ',
 			'IQ' => 'Iraki',
 			'IR' => 'Iraŋ',
 			'IS' => 'Áisi Lumaã',
 			'IT' => 'Ítali',
 			'JM' => 'Jamaika',
 			'JO' => 'Jɔɔdaŋ',
 			'JP' => 'Japaŋ',
 			'KE' => 'Kénya',
 			'KG' => 'Kigisitaŋ',
 			'KH' => 'Kaŋbhodiya',
 			'KI' => 'Kiribhati',
 			'KM' => 'Komorosi',
 			'KN' => 'Siŋ Kisi ɓɛ́ Nevisi',
 			'KP' => 'Koriya Kɔi Kaŋndɔ',
 			'KR' => 'Koriya Kɔi Leŋŋɛ Lɔ',
 			'KW' => 'Kuweti',
 			'KY' => 'Keemaŋ Tiŋŋɛ',
 			'KZ' => 'Kazasitaŋ',
 			'LA' => 'Lawosi',
 			'LB' => 'Lebhanɔ',
 			'LC' => 'Siŋ Lusiya',
 			'LK' => 'Suri Laŋka',
 			'LR' => 'Laibhiya',
 			'LS' => 'Lisóto',
 			'LT' => 'Lituweninya',
 			'LU' => 'Lusimbɔ',
 			'LV' => 'Lativiya',
 			'LY' => 'Lebhiya',
 			'MA' => 'Mɔroko',
 			'MC' => 'Mɔnako',
 			'MD' => 'Mɔlidova',
 			'MG' => 'Madagasita',
 			'MH' => 'Masha Tiŋŋɛ',
 			'MK' => 'Masedoninya',
 			'ML' => 'Mali',
 			'MM' => 'Miyamaha',
 			'MN' => 'Mɔngoliya',
 			'MP' => 'Kɔi Kaŋndɔ Mariyana Tiŋŋɛ',
 			'MQ' => 'Matiniki',
 			'MR' => 'Mɔretaninya',
 			'MS' => 'Mɔserati',
 			'MT' => 'Malita',
 			'MU' => 'Mɔreshɔ',
 			'MV' => 'Malidavi',
 			'MW' => 'Malawi',
 			'MX' => 'Mɛsíko',
 			'MY' => 'Malesiya',
 			'MZ' => 'Mozambiki',
 			'NA' => 'Namibiya',
 			'NC' => 'Kalidoninya Námaá',
 			'NE' => 'Naĩja',
 			'NF' => 'Nɔfɔ Tiŋŋɛ',
 			'NG' => 'Naĩjiriya',
 			'NI' => 'Nikaraguwa',
 			'NL' => 'Nidɔlɛŋ',
 			'NO' => 'Nɔɔwe',
 			'NP' => 'Nepa',
 			'NR' => 'Noru',
 			'NU' => 'Niwe',
 			'NZ' => 'Zilɛŋ Námaá',
 			'OM' => 'Omaŋ',
 			'PA' => 'Panama',
 			'PE' => 'Pɛru',
 			'PF' => 'Fɛŋsi Polinísiya',
 			'PG' => 'Papuwa Gini Námaá',
 			'PH' => 'Félepiŋ',
 			'PK' => 'Pakisitaŋ',
 			'PL' => 'Pólɛŋ',
 			'PM' => 'Siŋ Piiyɛ ɓɛ́ Mikelɔŋ',
 			'PN' => 'Pitikɛŋ',
 			'PR' => 'Piyuto Riko',
 			'PS' => 'Palesitininya Tele Jii Kɔiyɛ lá hĩ Gaza',
 			'PT' => 'Potokíi',
 			'PW' => 'Palo',
 			'PY' => 'Paragɔe',
 			'QA' => 'Kataha',
 			'RE' => 'Renyɔɔ̃',
 			'RO' => 'Romininya',
 			'RU' => 'Rɔshiya',
 			'RW' => 'Rawunda',
 			'SA' => 'Lahabu',
 			'SB' => 'Sulaimaãna Tiŋŋɛ',
 			'SC' => 'Seshɛɛ',
 			'SD' => 'Sudɛŋ',
 			'SE' => 'Suwidɛŋ',
 			'SG' => 'Síingapoo',
 			'SH' => 'Siŋ Hɛlina',
 			'SI' => 'Suloveninya',
 			'SK' => 'Sulovakiya',
 			'SL' => 'Gbeya Bahawɔ',
 			'SM' => 'Saŋ Marindo',
 			'SN' => 'Sinigaha',
 			'SO' => 'Somaliya',
 			'SR' => 'Surinambe',
 			'ST' => 'Sawo Tombe ɓɛ a Gbawoe',
 			'SV' => 'Ɛlɛ Sávádɔ',
 			'SY' => 'Síyaŋ',
 			'SZ' => 'Suwazi Lumaã',
 			'TC' => 'Tukisi ɓɛ̀ Kaikóosi Tiŋŋɛ',
 			'TD' => 'Chádi',
 			'TG' => 'Togo',
 			'TH' => 'Tai Lumaã',
 			'TJ' => 'Tajikisitaŋ',
 			'TK' => 'Tokelo',
 			'TL' => 'Tele Ɓɔ́ Timɔɔ̃',
 			'TM' => 'Tukimɛnisitaŋ',
 			'TN' => 'Tunisiya',
 			'TO' => 'Tɔnga',
 			'TR' => 'Tɔ́ɔ́ki',
 			'TT' => 'Turindeda ɓɛ́ Tobhego',
 			'TV' => 'Tuválu',
 			'TW' => 'Taiwaŋ',
 			'TZ' => 'Taŋzaninya',
 			'UA' => 'Yukuréŋ',
 			'UG' => 'Yuganda',
 			'US' => 'Poo',
 			'UY' => 'Yuwegɔwe',
 			'UZ' => 'Yubhɛkisitaŋ',
 			'VA' => 'Vatikaŋ Ɓoloe',
 			'VC' => 'Siŋ Viŋsi',
 			'VE' => 'Vɛnɛzuwela',
 			'VG' => 'Jengéesi Bhɛɛ Lɔ Musu Tiŋŋɛ',
 			'VI' => 'Poo Bhɛɛ lɔ Musu Tiŋŋɛ',
 			'VN' => 'Viyanami',
 			'VU' => 'Vanuwátu',
 			'WF' => 'Walísi',
 			'WS' => 'Samowa',
 			'YE' => 'Yemɛni',
 			'YT' => 'Mavote',
 			'ZA' => 'Afirika Kɔi Leŋŋɛ Lɔ',
 			'ZM' => 'Zambiya',
 			'ZW' => 'Zimbabhuwe',

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
			index => ['A', 'B', 'Ɓ', 'C', 'D', 'Ɗ', 'E', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a á ã b ɓ c d ɗ e é ẽ ɛ {ɛ́} {ɛ̃} f g h i í ĩ j k l m n ŋ o ó õ ɔ {ɔ́} {ɔ̃} p q r s t u ú ũ v w x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'Ɓ', 'C', 'D', 'Ɗ', 'E', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
	default		=> sub { qr'^(?i:yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:kpele|k|no|n)$' }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'vaii',
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'group' => q(,),
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
				'currency' => q(Yunaitɛ Arabhi Ɛmire Dihami),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angola Kuwaŋza),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Ɔ́situwa Dala),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bharɛŋ Dina),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Bhurundi Furaŋki),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Bhosuwana Pula),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanada Dala),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Kóngo Furaŋki),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Suwesi Furaŋki),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Chaníĩ Yuwaŋ Rɛŋmimbi),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Ɛsikudo Cabovɛdiyano),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Jibhuti Furaŋki),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Agiriya Dina),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Míséla Pɔɔ̃),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Ɛritera Nakifa),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Ítiyopiya Bhii),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Yuro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Jengési Pɔɔ̃),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Gana Sidi),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambiya Dalasi),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Gini Furaŋki),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Índiya Rupi),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Japaniĩ Yɛŋ),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Kénya Siyeŋ),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komoro Furaŋki),
			},
		},
		'LRD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Laibhiya Dala),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lisóto Loti),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libhiya Dina),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Mɔroko Dihami),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Malagasi Ariyari),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mɔretani Yugiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mɔretani Yugiya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mɔreshɔ Rupi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawi Kuwacha),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mozambiki Mɛtikali),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibiya Dala),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naĩjiriya Naĩra),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Rawunda Furaŋki),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Lahabu Sawodi Riya),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudaniĩ Pɔɔ̃),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Siŋ Hɛlina Pɔɔ̃),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Liyɔɔ̀),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somaliya Siyeŋ),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Sawo Tombe ɓɛ a Gbawo Dobura \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Sawo Tombe ɓɛ a Gbawo Dobura),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunisiya Dina),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Taŋzaniya Siyeŋ),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Yuganda Siyeŋ),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Poo Dala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Áfíríka Tɛ Sifa),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Áfíríka Tele Jíí Sifa),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Afirika Kɔi Leŋŋɛ lɔ Randi),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambiya Kuwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Zambiya Kuwacha),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbhabhuwe Dala),
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
					wide => {
						nonleap => [
							'luukao kemã',
							'ɓandaɓu',
							'vɔɔ',
							'fulu',
							'goo',
							'6',
							'7',
							'kɔnde',
							'saah',
							'galo',
							'kenpkato ɓololɔ',
							'luukao lɔma'
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
					wide => {
						mon => 'tɛɛnɛɛ',
						tue => 'talata',
						wed => 'alaba',
						thu => 'aimisa',
						fri => 'aijima',
						sat => 'siɓiti',
						sun => 'lahadi'
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
			'short' => q{dd/MM/y G},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMd => q{MMM d y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			Ed => q{E d},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMd => q{MMM d y},
			yMd => q{M/d/y},
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
