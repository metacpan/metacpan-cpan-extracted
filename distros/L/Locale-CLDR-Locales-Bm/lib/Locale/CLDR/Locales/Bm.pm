=head1

Locale::CLDR::Locales::Bm - Package for language Bambara

=cut

package Locale::CLDR::Locales::Bm;
# This file auto generated from Data\common\main\bm.xml
#	on Fri 13 Apr  7:02:47 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

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
				'ak' => 'akankan',
 				'am' => 'amarikikan',
 				'ar' => 'larabukan',
 				'be' => 'biyelorisikan',
 				'bg' => 'buligarikan',
 				'bm' => 'bamanakan',
 				'bn' => 'bɛngalikan',
 				'cs' => 'cɛkikan',
 				'de' => 'alimaɲikan',
 				'el' => 'gɛrɛsikan',
 				'en' => 'angilɛkan',
 				'es' => 'esipaɲolkan',
 				'fa' => 'perisanikan',
 				'fr' => 'tubabukan',
 				'ha' => 'awusakan',
 				'hi' => 'inidikan',
 				'hu' => 'oŋirikan',
 				'id' => 'Ɛndonezikan',
 				'ig' => 'igibokan',
 				'it' => 'italikan',
 				'ja' => 'zapɔnekan',
 				'jv' => 'javanekan',
 				'km' => 'kambojikan',
 				'ko' => 'korekan',
 				'ms' => 'malɛzikan',
 				'my' => 'birimanikan',
 				'ne' => 'nepalekan',
 				'nl' => 'olandekan',
 				'pa' => 'pɛnijabikan',
 				'pl' => 'polonekan',
 				'pt' => 'pɔritigalikan',
 				'ro' => 'rumanikan',
 				'ru' => 'irisikan',
 				'rw' => 'ruwandakan',
 				'so' => 'somalikan',
 				'sv' => 'suwɛdikan',
 				'ta' => 'tamulikan',
 				'th' => 'tayikan',
 				'tr' => 'turikikan',
 				'uk' => 'ukɛrɛnikan',
 				'ur' => 'urudukan',
 				'vi' => 'wiyɛtinamukan',
 				'yo' => 'yorubakan',
 				'zh' => 'siniwakan',
 				'zu' => 'zulukan',

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
			'AD' => 'Andɔr',
 			'AE' => 'Arabu mara kafoli',
 			'AF' => 'Afiganistaŋ',
 			'AG' => 'Antiga-ni-Barbuda',
 			'AI' => 'Angiya',
 			'AL' => 'Alibani',
 			'AM' => 'Arimeni',
 			'AO' => 'Angola',
 			'AR' => 'Arizantin',
 			'AS' => 'Samowa amerikani',
 			'AT' => 'Otirisi',
 			'AU' => 'Ositirali',
 			'AW' => 'Aruba',
 			'AZ' => 'Azɛrbayjaŋ',
 			'BA' => 'Bozni-Ɛrizigovini',
 			'BB' => 'Barbadi',
 			'BD' => 'Bɛngiladɛsi',
 			'BE' => 'Bɛliziki',
 			'BF' => 'Burukina Faso',
 			'BG' => 'Buligari',
 			'BH' => 'Bareyini',
 			'BI' => 'Burundi',
 			'BJ' => 'Benɛn',
 			'BM' => 'Bermudi',
 			'BN' => 'Burinɛyi',
 			'BO' => 'Bolivi',
 			'BR' => 'Berezili',
 			'BS' => 'Bahamasi',
 			'BT' => 'Butaŋ',
 			'BW' => 'Bɔtisiwana',
 			'BY' => 'Belarusi',
 			'BZ' => 'Belizi',
 			'CA' => 'Kanada',
 			'CD' => 'Kongo ka republiki demɔkratiki',
 			'CF' => 'Santarafiriki',
 			'CG' => 'Kongo',
 			'CH' => 'Suwisi',
 			'CI' => 'Kodiwari',
 			'CK' => 'Kuki Gun',
 			'CL' => 'Sili',
 			'CM' => 'Kameruni',
 			'CN' => 'Siniwajamana',
 			'CO' => 'Kolombi',
 			'CR' => 'Kɔsitarika',
 			'CU' => 'Kuba',
 			'CV' => 'Capivɛrdi',
 			'CY' => 'Cipri',
 			'CZ' => 'Ceki republiki',
 			'DE' => 'Alimaɲi',
 			'DJ' => 'Jibuti',
 			'DK' => 'Danemarki',
 			'DM' => 'Dɔminiki',
 			'DO' => 'Dɔmimiki republiki',
 			'DZ' => 'Alizeri',
 			'EC' => 'Ekwatɔr',
 			'EE' => 'Esetoni',
 			'EG' => 'Eziputi',
 			'ER' => 'Eritere',
 			'ES' => 'Esipaɲi',
 			'ET' => 'Etiopi',
 			'FI' => 'Finilandi',
 			'FJ' => 'Fiji',
 			'FK' => 'Maluwini Gun',
 			'FM' => 'Mikironesi',
 			'FR' => 'Faransi',
 			'GA' => 'Gabɔŋ',
 			'GB' => 'Angilɛtɛri',
 			'GD' => 'Granadi',
 			'GE' => 'Zeyɔrzi',
 			'GF' => 'Faransi ka gwiyani',
 			'GH' => 'Gana',
 			'GI' => 'Zibralitari',
 			'GL' => 'Gɔrɔhenelandi',
 			'GM' => 'Ganbi',
 			'GN' => 'Gine',
 			'GP' => 'Gwadelup',
 			'GQ' => 'Gine ekwatɔri',
 			'GR' => 'Gɛrɛsi',
 			'GT' => 'Gwatemala',
 			'GU' => 'Gwam',
 			'GW' => 'Gine Bisawo',
 			'GY' => 'Gwiyana',
 			'HN' => 'Hɔndirasi',
 			'HR' => 'Kroasi',
 			'HT' => 'Ayiti',
 			'HU' => 'Hɔngri',
 			'ID' => 'Ɛndonezi',
 			'IE' => 'Irilandi',
 			'IL' => 'Isirayeli',
 			'IN' => 'Ɛndujamana',
 			'IO' => 'Angilɛ ka ɛndu dugukolo',
 			'IQ' => 'Iraki',
 			'IR' => 'Iraŋ',
 			'IS' => 'Isilandi',
 			'IT' => 'Itali',
 			'JM' => 'Zamayiki',
 			'JO' => 'Zɔrdani',
 			'JP' => 'Zapɔn',
 			'KE' => 'Keniya',
 			'KG' => 'Kirigizisitaŋ',
 			'KH' => 'Kamboji',
 			'KI' => 'Kiribati',
 			'KM' => 'Komɔri',
 			'KN' => 'Kristɔfo-Senu-ni-Ɲevɛs',
 			'KP' => 'Kɛɲɛka Kore',
 			'KR' => 'Worodugu Kore',
 			'KW' => 'Kowɛti',
 			'KY' => 'Bama Gun',
 			'KZ' => 'Kazakistaŋ',
 			'LA' => 'Layosi',
 			'LB' => 'Libaŋ',
 			'LC' => 'Lusi-Senu',
 			'LI' => 'Lisɛnsitayini',
 			'LK' => 'Sirilanka',
 			'LR' => 'Liberiya',
 			'LS' => 'Lesoto',
 			'LT' => 'Lituyani',
 			'LU' => 'Likisanburu',
 			'LV' => 'Letoni',
 			'LY' => 'Libi',
 			'MA' => 'Marɔku',
 			'MC' => 'Monako',
 			'MD' => 'Molidavi',
 			'MG' => 'Madagasikari',
 			'MH' => 'Marisali Gun',
 			'MK' => 'Macedɔni',
 			'ML' => 'Mali',
 			'MM' => 'Myanimari',
 			'MN' => 'Moŋoli',
 			'MP' => 'Kɛɲɛka Mariyani Gun',
 			'MQ' => 'Maritiniki',
 			'MR' => 'Mɔritani',
 			'MS' => 'Moŋsera',
 			'MT' => 'Malti',
 			'MU' => 'Morisi',
 			'MV' => 'Maldivi',
 			'MW' => 'Malawi',
 			'MX' => 'Meksiki',
 			'MY' => 'Malɛzi',
 			'MZ' => 'Mozanbiki',
 			'NA' => 'Namibi',
 			'NC' => 'Kaledoni Koura',
 			'NE' => 'Nizɛri',
 			'NF' => 'Nɔrofoliki Gun',
 			'NG' => 'Nizeriya',
 			'NI' => 'Nikaragwa',
 			'NL' => 'Peyiba',
 			'NO' => 'Nɔriwɛzi',
 			'NP' => 'Nepali',
 			'NR' => 'Nawuru',
 			'NU' => 'Nyuwe',
 			'NZ' => 'Zelandi Koura',
 			'OM' => 'Omaŋ',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Faransi ka polinezi',
 			'PG' => 'Papuwasi-Gine-Koura',
 			'PH' => 'Filipini',
 			'PK' => 'Pakisitaŋ',
 			'PL' => 'Poloɲi',
 			'PM' => 'Piyɛri-Senu-ni-Mikelɔŋ',
 			'PN' => 'Pitikarini',
 			'PR' => 'Pɔrotoriko',
 			'PS' => 'Palesitini',
 			'PT' => 'Pɔritigali',
 			'PW' => 'Palawu',
 			'PY' => 'Paraguwayi',
 			'QA' => 'Katari',
 			'RE' => 'Reyuɲɔŋ',
 			'RO' => 'Rumani',
 			'RU' => 'Irisi',
 			'RW' => 'Ruwanda',
 			'SA' => 'Arabiya Sawudiya',
 			'SB' => 'Salomo Gun',
 			'SC' => 'Sesɛli',
 			'SD' => 'Sudaŋ',
 			'SE' => 'Suwɛdi',
 			'SG' => 'Sɛngapuri',
 			'SH' => 'Ɛlɛni Senu',
 			'SI' => 'Sloveni',
 			'SK' => 'Slowaki',
 			'SL' => 'Siyera Lewɔni',
 			'SM' => 'Marini-Senu',
 			'SN' => 'Senegali',
 			'SO' => 'Somali',
 			'SR' => 'Surinami',
 			'ST' => 'Sawo Tome-ni-Prinicipe',
 			'SV' => 'Salivadɔr',
 			'SY' => 'Siri',
 			'SZ' => 'Swazilandi',
 			'TC' => 'Turiki Gun ni Kayiki',
 			'TD' => 'Cadi',
 			'TG' => 'Togo',
 			'TH' => 'Tayilandi',
 			'TJ' => 'Tajikisitani',
 			'TK' => 'Tokelo',
 			'TL' => 'Kɔrɔn Timɔr',
 			'TM' => 'Turikimenisitani',
 			'TN' => 'Tunizi',
 			'TO' => 'Tonga',
 			'TR' => 'Turiki',
 			'TT' => 'Trinite-ni-Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Tayiwani',
 			'TZ' => 'Tanzani',
 			'UA' => 'Ukɛrɛni',
 			'UG' => 'Uganda',
 			'US' => 'Ameriki',
 			'UY' => 'Urugwayi',
 			'UZ' => 'Uzebekisitani',
 			'VA' => 'Vatikaŋ',
 			'VC' => 'Vinisɛn-Senu-ni-Grenadini',
 			'VE' => 'Venezuwela',
 			'VG' => 'Angilɛ ka Sungurunnin Gun',
 			'VI' => 'Ameriki ka Sungurunnin Gun',
 			'VN' => 'Wiyɛtinamu',
 			'VU' => 'Vanuwatu',
 			'WF' => 'Walisi-ni-Futuna',
 			'WS' => 'Samowa',
 			'YE' => 'Yemɛni',
 			'YT' => 'Mayoti',
 			'ZA' => 'Worodugu Afriki',
 			'ZM' => 'Zanbi',
 			'ZW' => 'Zimbabuwe',

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
			auxiliary => qr{[q v x]},
			index => ['A', 'B', 'C', 'D', 'E', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ɲ', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'W', 'Y', 'Z'],
			main => qr{[a b c d e ɛ f g h i j k l m n ɲ ŋ o ɔ p r s t u w y z]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'Ɛ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ɲ', 'Ŋ', 'O', 'Ɔ', 'P', 'R', 'S', 'T', 'U', 'W', 'Y', 'Z'], };
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

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ɔwɔ|ɔ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ayi|a|no|n)$' }
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
				'currency' => q(arabu mara kafoli Diram),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angola Kwanza),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(ositirali Dolar),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bareyini Dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundi Fraŋ),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(bɔtisiwana Pula),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(kanada Dolar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(kongole Fraŋ),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(suwisi Fraŋ),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(siniwa Yuwan),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(capivɛrdi Esekudo),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(jibuti Fraŋ),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(alizeri Dinar),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(eziputi Livri),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritere Nafika),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(etiopi Bir),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(ero),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(angilɛ Livri),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(gana Sedi),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambi Dalasi),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(gine Fraŋ),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Ɛndu Rupi),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(zapɔne Yɛn),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(keniya Siling),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(komɔri Fraŋ),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(liberiya Dolar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesoto Loti),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libi Dinar),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(marɔku Diram),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(madagasikari Fraŋ),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mɔritani Uguwiya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(morisi Rupi),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malawi Kwaca),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(mozanbiki Metikali),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibi Dolar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nizeriya Nɛra),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(ruwanda Fraŋ),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(sawudiya Riyal),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(sesɛli Rupi),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudani Dinar),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(sudani Livri),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Ɛlɛni-Senu Livri),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(siyeralewɔni Lewɔni),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somali Siling),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(sawotome Dobra),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(swazilandi Lilangeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tunizi Dinar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tanzani Siling),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(uganda Siling),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(ameriki Dolar),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(sefa Fraŋ \(BEAC\)),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(sefa Fraŋ \(BCEAO\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(sudafriki Randi),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(zambi Kwaca \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(zambi Kwaca),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(zimbabuwe Dolar),
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
							'zan',
							'feb',
							'mar',
							'awi',
							'mɛ',
							'zuw',
							'zul',
							'uti',
							'sɛt',
							'ɔku',
							'now',
							'des'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'zanwuye',
							'feburuye',
							'marisi',
							'awirili',
							'mɛ',
							'zuwɛn',
							'zuluye',
							'uti',
							'sɛtanburu',
							'ɔkutɔburu',
							'nowanburu',
							'desanburu'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'Z',
							'F',
							'M',
							'A',
							'M',
							'Z',
							'Z',
							'U',
							'S',
							'Ɔ',
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
						mon => 'ntɛ',
						tue => 'tar',
						wed => 'ara',
						thu => 'ala',
						fri => 'jum',
						sat => 'sib',
						sun => 'kar'
					},
					wide => {
						mon => 'ntɛnɛ',
						tue => 'tarata',
						wed => 'araba',
						thu => 'alamisa',
						fri => 'juma',
						sat => 'sibiri',
						sun => 'kari'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'N',
						tue => 'T',
						wed => 'A',
						thu => 'A',
						fri => 'J',
						sat => 'S',
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
					abbreviated => {0 => 'KS1',
						1 => 'KS2',
						2 => 'KS3',
						3 => 'KS4'
					},
					wide => {0 => 'kalo saba fɔlɔ',
						1 => 'kalo saba filanan',
						2 => 'kalo saba sabanan',
						3 => 'kalo saba naaninan'
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
				'0' => 'J.-C. ɲɛ',
				'1' => 'ni J.-C.'
			},
			wide => {
				'0' => 'jezu krisiti ɲɛ',
				'1' => 'jezu krisiti minkɛ'
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
			M => q{M},
			MMM => q{MMM},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			M => q{M},
			MMM => q{MMM},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			ms => q{m:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
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
		'gregorian' => {
			'Day' => '{0} ({2}: {1})',
			'Day-Of-Week' => '{0} {1}',
			'Era' => '{1} {0}',
			'Hour' => '{0} ({2}: {1})',
			'Minute' => '{0} ({2}: {1})',
			'Month' => '{0} ({2}: {1})',
			'Quarter' => '{0} ({2}: {1})',
			'Second' => '{0} ({2}: {1})',
			'Timezone' => '{0} {1}',
			'Week' => '{0} ({2}: {1})',
			'Year' => '{1} {0}',
		},
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
