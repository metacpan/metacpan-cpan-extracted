=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ksf - Package for language Bafia

=cut

package Locale::CLDR::Locales::Ksf;
# This file auto generated from Data\common\main\ksf.xml
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
				'ak' => 'riakan',
 				'am' => 'riamarik',
 				'ar' => 'riarab',
 				'be' => 'ribɛlɔrís',
 				'bg' => 'ribulgarí',
 				'bn' => 'ribɛngáli',
 				'cs' => 'ricɛ́k',
 				'de' => 'ridjɛrman',
 				'el' => 'rigrɛ́k',
 				'en' => 'riingɛrís',
 				'es' => 'rikpanyá',
 				'fa' => 'ripɛrsán',
 				'fr' => 'ripɛrɛsǝ́',
 				'ha' => 'rikaksa',
 				'hi' => 'riíndí',
 				'hu' => 'riɔngrɔá',
 				'id' => 'riindonɛsí',
 				'ig' => 'riigbo',
 				'it' => 'riitalyɛ́n',
 				'ja' => 'rijapɔ́ŋ',
 				'jv' => 'rijawanɛ́',
 				'km' => 'rikmɛr',
 				'ko' => 'rikɔrɛɛ́',
 				'ksf' => 'rikpa',
 				'ms' => 'rimalaí',
 				'my' => 'ribirmán',
 				'ne' => 'rinepalɛ́',
 				'nl' => 'riɔlándɛ́',
 				'pa' => 'ripɛnjabí',
 				'pl' => 'ripɔlɔ́n',
 				'pt' => 'ripɔrtugɛ́',
 				'ro' => 'rirɔmán',
 				'ru' => 'rirís',
 				'rw' => 'rirwanda',
 				'so' => 'risomalí',
 				'sv' => 'riswɛ́dǝ',
 				'ta' => 'ritamúl',
 				'th' => 'ritaí',
 				'tr' => 'riturk',
 				'uk' => 'riukrɛ́n',
 				'ur' => 'riurdú',
 				'vi' => 'riwyɛtnám',
 				'yo' => 'riyúuba',
 				'zh' => 'ricinɔá',
 				'zu' => 'rizúlu',

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
			'AD' => 'andɔrǝ',
 			'AE' => 'bǝlɔŋ bǝ kaksa bɛ táatáaŋzǝn',
 			'AF' => 'afganistáŋ',
 			'AG' => 'antiga ri barbúda',
 			'AI' => 'angiya',
 			'AL' => 'albaní',
 			'AM' => 'armɛní',
 			'AO' => 'angóla',
 			'AR' => 'arjǝntín',
 			'AS' => 'samɔa a amɛrika',
 			'AT' => 'otric',
 			'AU' => 'ɔstralí',
 			'AW' => 'aruba',
 			'AZ' => 'azabecán',
 			'BA' => 'bɔsnyɛ ri hɛrsǝgɔvín',
 			'BB' => 'baabaadǝ',
 			'BD' => 'baŋladɛ́c',
 			'BE' => 'bɛljík',
 			'BF' => 'bukína fǝ́ asɔ',
 			'BG' => 'bulgarí',
 			'BH' => 'barǝ́n',
 			'BI' => 'burundí',
 			'BJ' => 'bɛnǝ́n',
 			'BM' => 'bɛɛmúdǝ',
 			'BN' => 'brunǝ́',
 			'BO' => 'bɔɔlíví',
 			'BR' => 'brɛsíl',
 			'BS' => 'baamás',
 			'BT' => 'bután',
 			'BW' => 'botswana',
 			'BY' => 'bɛlaris',
 			'BZ' => 'bɛliz',
 			'CA' => 'kanada',
 			'CD' => 'kɔngó anyɔ́n',
 			'CF' => 'santrafrík',
 			'CG' => 'kɔngó',
 			'CH' => 'swís',
 			'CI' => 'kɔtiwuár',
 			'CK' => 'zɛ i kúk',
 			'CL' => 'cíli',
 			'CM' => 'kamɛrún',
 			'CN' => 'cín',
 			'CO' => 'kolɔmbí',
 			'CR' => 'kɔstaríka',
 			'CU' => 'kuba',
 			'CV' => 'kapvɛr',
 			'CY' => 'cíprɛ',
 			'CZ' => 'cɛ́k',
 			'DE' => 'djɛrman',
 			'DJ' => 'dyibutí',
 			'DK' => 'danmak',
 			'DM' => 'dɔminik',
 			'DO' => 'dɔminik rɛpublík',
 			'DZ' => 'aljɛrí',
 			'EC' => 'ɛkwatɛǝ́',
 			'EE' => 'ɛstoní',
 			'EG' => 'ɛjípt',
 			'ER' => 'ɛritrɛ́',
 			'ES' => 'kpanyá',
 			'ET' => 'ɛtyɔpí',
 			'FI' => 'fínlan',
 			'FJ' => 'fíji',
 			'FK' => 'zǝ maalwín',
 			'FM' => 'mikronɛ́si',
 			'FR' => 'pɛrɛsǝ́',
 			'GA' => 'gabɔŋ',
 			'GB' => 'kǝlɔŋ kǝ kǝtáatáaŋzǝn',
 			'GD' => 'grɛnadǝ',
 			'GE' => 'jɔrjí',
 			'GF' => 'guyán i pɛrɛsǝ́',
 			'GH' => 'gána',
 			'GI' => 'jibraltá',
 			'GL' => 'grínlan',
 			'GM' => 'gambí',
 			'GN' => 'ginɛ́',
 			'GP' => 'gwadɛlúp',
 			'GQ' => 'ginɛ́ ɛkwatɔrial',
 			'GR' => 'grɛ́k',
 			'GT' => 'gwátǝmala',
 			'GU' => 'gwám',
 			'GW' => 'ginɛ́ bisɔ́',
 			'GY' => 'guyán',
 			'HN' => 'ɔnduras',
 			'HR' => 'krwasí',
 			'HT' => 'ayiti',
 			'HU' => 'ɔngrí',
 			'ID' => 'indonɛsí',
 			'IE' => 'ilán',
 			'IL' => 'israɛ́l',
 			'IN' => 'indí',
 			'IO' => 'zǝ ingɛrís ncɔ́m wa indi',
 			'IQ' => 'irák',
 			'IR' => 'iráŋ',
 			'IS' => 'zǝ i glás',
 			'IT' => 'italí',
 			'JM' => 'jamaík',
 			'JO' => 'jɔrdán',
 			'JP' => 'japɔ́ŋ',
 			'KE' => 'kɛnya',
 			'KG' => 'kigistáŋ',
 			'KH' => 'kambodj',
 			'KI' => 'kiribáti',
 			'KM' => 'komɔr',
 			'KN' => 'sɛnkrǝstɔ́f ri nyɛ́vǝ',
 			'KP' => 'korɛanɔ́r',
 			'KR' => 'korɛasud',
 			'KW' => 'kuwɛit',
 			'KY' => 'zǝ i gan',
 			'KZ' => 'kazakstáŋ',
 			'LA' => 'laɔs',
 			'LB' => 'libáŋ',
 			'LC' => 'sɛntlísí',
 			'LI' => 'lictɛnstɛ́n',
 			'LK' => 'srílaŋka',
 			'LR' => 'libɛrya',
 			'LS' => 'lǝsóto',
 			'LT' => 'litwaní',
 			'LU' => 'luksɛmbúr',
 			'LV' => 'lɛtoní',
 			'LY' => 'libí',
 			'MA' => 'marɔk',
 			'MC' => 'monako',
 			'MD' => 'mɔldaví',
 			'MG' => 'madagaska',
 			'MH' => 'zǝ i marcál',
 			'ML' => 'mali',
 			'MM' => 'myanmár',
 			'MN' => 'mɔŋolí',
 			'MP' => 'zǝ maryánnɔ́r',
 			'MQ' => 'matiník',
 			'MR' => 'mwaritaní',
 			'MS' => 'mɔnsɛrat',
 			'MT' => 'maltǝ',
 			'MU' => 'mwarís',
 			'MV' => 'maldivǝ',
 			'MW' => 'malawi',
 			'MX' => 'mɛksík',
 			'MY' => 'malɛsí',
 			'MZ' => 'mosambík',
 			'NA' => 'namibí',
 			'NC' => 'kalɛdoní anyɔ́n',
 			'NE' => 'nijɛ́r',
 			'NF' => 'zɛ nɔ́fɔlk',
 			'NG' => 'nijɛ́rya',
 			'NI' => 'níkarágwa',
 			'NL' => 'kǝlɔŋ kǝ ázǝ',
 			'NO' => 'nɔrvɛjǝ',
 			'NP' => 'nɛpal',
 			'NR' => 'nwarú',
 			'NU' => 'niwɛ́',
 			'NZ' => 'zɛlan anyɔ́n',
 			'OM' => 'oman',
 			'PA' => 'panama',
 			'PE' => 'pɛrú',
 			'PF' => 'pɔlinɛsí a pɛrɛsǝ́',
 			'PG' => 'papwazí ginɛ́ anyɔ́n',
 			'PH' => 'filipǝ́n',
 			'PK' => 'pakistáŋ',
 			'PL' => 'polɔ́n',
 			'PM' => 'sɛnpyɛr ri mikɛlɔŋ',
 			'PN' => 'pitkɛ́n',
 			'PR' => 'pɔtoríko',
 			'PS' => 'zǝ palɛstínǝ',
 			'PT' => 'portugál',
 			'PW' => 'palwa',
 			'PY' => 'paragwɛ́',
 			'QA' => 'katá',
 			'RE' => 'rɛunyɔŋ',
 			'RO' => 'rɔmaní',
 			'RU' => 'risí',
 			'RW' => 'rwanda',
 			'SA' => 'arabí saodí',
 			'SB' => 'zǝ salomɔ́n',
 			'SC' => 'sɛcɛl',
 			'SD' => 'sudan',
 			'SE' => 'swɛdǝ',
 			'SG' => 'siŋapó',
 			'SH' => 'sɛntɛ́len',
 			'SI' => 'slovɛní',
 			'SK' => 'slovakí',
 			'SL' => 'syɛraleon',
 			'SM' => 'sɛnmarǝn',
 			'SN' => 'sɛnɛgal',
 			'SO' => 'somalí',
 			'SR' => 'surinam',
 			'ST' => 'saotomɛ́ ri priŋsib',
 			'SV' => 'salvadɔr',
 			'SY' => 'sirí',
 			'SZ' => 'swazilan',
 			'TC' => 'zǝ tirk ri kakɔs',
 			'TD' => 'caád',
 			'TG' => 'togo',
 			'TH' => 'tɛlan',
 			'TJ' => 'tadjikistaŋ',
 			'TK' => 'tokǝlao',
 			'TL' => 'timor anǝ á ɛst',
 			'TM' => 'tirkmɛnistaŋ',
 			'TN' => 'tunɛsí',
 			'TO' => 'tɔŋa',
 			'TR' => 'tirkí',
 			'TT' => 'tɛrinitɛ ri tobago',
 			'TV' => 'tuwalu',
 			'TW' => 'tɛwán',
 			'TZ' => 'tanzaní',
 			'UA' => 'ukrain',
 			'UG' => 'uganda',
 			'US' => 'amɛrika',
 			'UY' => 'urugwɛ́',
 			'UZ' => 'usbɛkistaŋ',
 			'VA' => 'watikáŋ',
 			'VC' => 'sɛnvǝnsǝŋ ri grɛnadín',
 			'VE' => 'wɛnǝzwɛla',
 			'VG' => 'zǝ bɛ gɔn inɛ a ingɛrís',
 			'VI' => 'zǝ bɛ gɔn inɛ á amɛrika',
 			'VN' => 'wyɛtnám',
 			'VU' => 'wanwatu',
 			'WF' => 'walis ri futuna',
 			'WS' => 'samɔa',
 			'YE' => 'yɛmɛn',
 			'YT' => 'mayɔ́t',
 			'ZA' => 'afrik anǝ a sud',
 			'ZM' => 'zambí',
 			'ZW' => 'zimbabwɛ́',

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
			index => ['A', 'B', 'C', 'D', 'E', 'Ǝ', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{[aá b c d eé ǝ{ǝ́} ɛ{ɛ́} f g h ií j k l m n ŋ oó ɔ{ɔ́} p r s t uú v w y z]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'Ǝ', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
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

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:Ɛ́|Ɛ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:EÉ|E|no|n)$' }
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
				'currency' => q(mɔni mǝ á bǝlɔŋ bǝ kaksa bɛ táatáaŋzǝn),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(mɔni mǝ á angóla),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(mɔni mǝ á ɔstralí),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(mɔni mǝ á barǝ́n),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(mɔni mǝ á burundí),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(mɔni mǝ á botswana),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(mɔni mǝ á kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(mɔni mǝ á kɔngó),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(mɔni mǝ á swís),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(mɔni mǝ á cín),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(mɔni mǝ á kapvɛr),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(mɔni mǝ á dyibutí),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(mɔni mǝ á aljɛrí),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(mɔni mǝ á ɛjípt),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(mɔni mǝ á ɛritrɛ́),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(mɔni mǝ á ɛtyɔpí),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(mɔni mǝ á pɛrɛsǝ́),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(mɔni mǝ á ingɛrís),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(mɔni mǝ á gána),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(mɔni mǝ á gambí),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(mɔni mǝ á ginɛ́),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(mɔni mǝ á indí),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(mɔni mǝ á japɔ́ŋ),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(mɔni mǝ á kɛnya),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(mɔni mǝ á komɔr),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(mɔni mǝ á libɛrya),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(mɔni mǝ á lǝsóto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(mɔni mǝ á libí),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(mɔni mǝ á marɔk),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(mɔni mǝ á madagaska),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mɔni mǝ á mwaritaní \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mɔni mǝ á mwaritaní),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(mɔni mǝ á mwarís),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(mɔni mǝ á malawi),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(mɔni mǝ á mosambík),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(mɔni mǝ á namibí),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(mɔni mǝ á nijɛ́rya),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(mɔni mǝ á rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(mɔni mǝ á arabí saodí),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(mɔni mǝ á sɛcɛl),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(mɔni mǝ á sudan),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(mɔni mǝ á sɛntɛ́len),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(mɔni mǝ á syɛraleon),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(mɔni mǝ á syɛraleon \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(mɔni mǝ á somalí),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(mɔni mǝ á saotomɛ́ ri priŋsib \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(mɔni mǝ á saotomɛ́ ri priŋsib),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(mɔni mǝ á swazilan),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(mɔni mǝ á tunɛsí),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(mɔni mǝ á tanzaní),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(mɔni mǝ á uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(mɔni mǝ á amɛrika),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(fráŋ),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(mɔni mǝ á afríka aná wɛs),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(mɔni mǝ á afrik anǝ a sud),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(mɔni mǝ á zambí \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(mɔni mǝ á zambí),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(mɔni mǝ á zimbabwɛ́),
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
							'ŋ1',
							'ŋ2',
							'ŋ3',
							'ŋ4',
							'ŋ5',
							'ŋ6',
							'ŋ7',
							'ŋ8',
							'ŋ9',
							'ŋ10',
							'ŋ11',
							'ŋ12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ŋwíí a ntɔ́ntɔ',
							'ŋwíí akǝ bɛ́ɛ',
							'ŋwíí akǝ ráá',
							'ŋwíí akǝ nin',
							'ŋwíí akǝ táan',
							'ŋwíí akǝ táafɔk',
							'ŋwíí akǝ táabɛɛ',
							'ŋwíí akǝ táaraa',
							'ŋwíí akǝ táanin',
							'ŋwíí akǝ ntɛk',
							'ŋwíí akǝ ntɛk di bɔ́k',
							'ŋwíí akǝ ntɛk di bɛ́ɛ'
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
						mon => 'lǝn',
						tue => 'maa',
						wed => 'mɛk',
						thu => 'jǝǝ',
						fri => 'júm',
						sat => 'sam',
						sun => 'sɔ́n'
					},
					wide => {
						mon => 'lǝndí',
						tue => 'maadí',
						wed => 'mɛkrɛdí',
						thu => 'jǝǝdí',
						fri => 'júmbá',
						sat => 'samdí',
						sun => 'sɔ́ndǝ'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'l',
						tue => 'm',
						wed => 'm',
						thu => 'j',
						fri => 'j',
						sat => 's',
						sun => 's'
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
					abbreviated => {0 => 'i1',
						1 => 'i2',
						2 => 'i3',
						3 => 'i4'
					},
					wide => {0 => 'id́ɛ́n kǝbǝk kǝ ntɔ́ntɔ́',
						1 => 'idɛ́n kǝbǝk kǝ kǝbɛ́ɛ',
						2 => 'idɛ́n kǝbǝk kǝ kǝráá',
						3 => 'idɛ́n kǝbǝk kǝ kǝnin'
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
					'am' => q{sárúwá},
					'pm' => q{cɛɛ́nko},
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
				'0' => 'd.Y.',
				'1' => 'k.Y.'
			},
			wide => {
				'0' => 'di Yɛ́sus aká yálɛ',
				'1' => 'cámɛɛn kǝ kǝbɔpka Y'
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
