=encoding utf8

=head1

Locale::CLDR::Locales::Yav - Package for language Yangben

=cut

package Locale::CLDR::Locales::Yav;
# This file auto generated from Data\common\main\yav.xml
#	on Sun  3 Feb  2:26:14 pm GMT

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
				'ak' => 'akánɛ',
 				'am' => 'amalíke',
 				'ar' => '́pakas',
 				'be' => 'pielúse',
 				'bg' => 'bulgálɛ',
 				'bn' => 'pengálɛ́ɛ',
 				'cs' => 'cɛ́kɛ́ɛ',
 				'de' => 'ŋndiáman',
 				'el' => 'yavánɛ',
 				'en' => 'íŋgilísé',
 				'es' => 'nuɛspanyɔ́lɛ',
 				'fa' => 'nupɛ́lisɛ',
 				'fr' => 'feleŋsí',
 				'ha' => 'pakas',
 				'hi' => 'índí',
 				'hu' => 'ɔ́ŋgɛ',
 				'id' => 'índonísiɛ',
 				'ig' => 'íbo',
 				'it' => 'itáliɛ',
 				'ja' => 'ndiáman',
 				'jv' => 'yávanɛ',
 				'km' => 'kímɛɛ',
 				'ko' => 'kolíe',
 				'ms' => 'máliɛ',
 				'my' => 'bímanɛ',
 				'ne' => 'nunipálɛ',
 				'nl' => 'nilándɛ',
 				'pa' => 'nupunsapíɛ́',
 				'pl' => 'nupolonɛ́ɛ',
 				'pt' => 'nupɔlitukɛ́ɛ',
 				'ro' => 'nulumɛ́ŋɛ',
 				'ru' => 'nulúse',
 				'rw' => 'nuluándɛ́ɛ',
 				'so' => 'nusomalíɛ',
 				'sv' => 'nusuetua',
 				'ta' => 'nutámule',
 				'th' => 'nutáyɛ',
 				'tr' => 'nutúluke',
 				'uk' => 'nukeleniɛ́ŋɛ',
 				'ur' => 'nulutú',
 				'vi' => 'nufiɛtnamíɛŋ',
 				'yav' => 'nuasue',
 				'yo' => 'nuyolúpa',
 				'zh' => 'sinúɛ',
 				'zu' => 'nusulú',

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
			'AD' => 'Aŋtúla',
 			'AE' => 'imiláat i paaláap',
 			'AF' => 'Afkanistáŋ',
 			'AG' => 'Aŋtíka na Palpúta',
 			'AI' => 'Aŋkíla',
 			'AL' => 'Alpaní',
 			'AM' => 'Almanía',
 			'AO' => 'Aŋkúla',
 			'AR' => 'Alsaŋtín',
 			'AS' => 'Sámua u Amelíka',
 			'AT' => 'Otilís',
 			'AU' => 'Otalalí',
 			'AW' => 'Alúpa',
 			'AZ' => 'Asɛlpaisáŋ',
 			'BA' => 'Pusiní-ɛlkofína',
 			'BB' => 'Palpatós',
 			'BD' => 'Paŋkalatɛs',
 			'BE' => 'Pɛlsíik',
 			'BF' => 'Pulikínafásó',
 			'BG' => 'Pulukalíi',
 			'BH' => 'Palɛŋ',
 			'BI' => 'Púlúndí',
 			'BJ' => 'Penɛŋ',
 			'BM' => 'Pɛlmúta',
 			'BN' => 'Pulunéy',
 			'BO' => 'Polífia',
 			'BR' => 'Pilesíl',
 			'BS' => 'Pahámas',
 			'BT' => 'Putaŋ',
 			'BW' => 'Posuána',
 			'BY' => 'Pelalús',
 			'BZ' => 'Pelíse',
 			'CA' => 'Kánáta',
 			'CD' => 'kitɔŋ kí kongó',
 			'CF' => 'Santalafilíik',
 			'CG' => 'Kongó',
 			'CH' => 'suwíis',
 			'CI' => 'Kótifualɛ',
 			'CK' => 'Kúuke',
 			'CL' => 'Silí',
 			'CM' => 'Kemelún',
 			'CN' => 'Síine',
 			'CO' => 'Kɔlɔ́mbía',
 			'CR' => 'Kóstálíka',
 			'CU' => 'kúpa',
 			'CV' => 'Kápfɛl',
 			'CY' => 'síplɛ',
 			'CZ' => 'kitɔŋ kí cɛ́k',
 			'DE' => 'nsáman',
 			'DJ' => 'síputí',
 			'DK' => 'tanemálk',
 			'DM' => 'túmúnéke',
 			'DO' => 'kitɔŋ kí tumunikɛ́ŋ',
 			'DZ' => 'Alselí',
 			'EC' => 'ekuatɛ́l',
 			'EE' => 'ɛstoni',
 			'EG' => 'isípit',
 			'ER' => 'elitée',
 			'ES' => 'panyá',
 			'ET' => 'etiopí',
 			'FI' => 'fɛnlánd',
 			'FJ' => 'físi',
 			'FK' => 'maluwín',
 			'FM' => 'mikolonesí',
 			'FR' => 'felensí',
 			'GA' => 'kapɔ́ŋ',
 			'GB' => 'ingilíís',
 			'GD' => 'kelenáat',
 			'GE' => 'sɔlsíi',
 			'GF' => 'kuyáan u felensí',
 			'GH' => 'kaná',
 			'GI' => 'sílpalatáal',
 			'GL' => 'kuluɛnlánd',
 			'GM' => 'kambíi',
 			'GN' => 'kiiné',
 			'GP' => 'kuatelúup',
 			'GQ' => 'kinéekuatolial',
 			'GR' => 'kilɛ́ɛk',
 			'GT' => 'kuatemalá',
 			'GU' => 'kuamiɛ',
 			'GW' => 'kiinépisaó',
 			'GY' => 'kuyáan',
 			'HN' => 'ɔndúlas',
 			'HR' => 'Kolowasíi',
 			'HT' => 'ayíti',
 			'HU' => 'ɔngilí',
 			'ID' => 'ɛndonesí',
 			'IE' => 'ililánd',
 			'IL' => 'ísilayɛ́l',
 			'IN' => 'ɛ́ɛnd',
 			'IO' => 'Kɔɔ́m kí ndián yi ngilís',
 			'IQ' => 'ilák',
 			'IR' => 'iláŋ',
 			'IS' => 'isláand',
 			'IT' => 'italí',
 			'JM' => 'samayíik',
 			'JO' => 'sɔltaní',
 			'JP' => 'sapɔ́ɔŋ',
 			'KE' => 'kénia',
 			'KG' => 'kilikisistáŋ',
 			'KH' => 'Kámbóse',
 			'KI' => 'kilipatí',
 			'KM' => 'Kɔmɔ́ɔl',
 			'KN' => 'sɛ́ŋkilistɔ́f eniɛ́f',
 			'KP' => 'kɔlé u muɛnɛ́',
 			'KR' => 'kɔlé wu mbát',
 			'KW' => 'kowéet',
 			'KY' => 'Káyímanɛ',
 			'KZ' => 'kasaksitáŋ',
 			'LA' => 'lawós',
 			'LB' => 'lipáŋ',
 			'LC' => 'sɛ́ŋtɛ́lusí',
 			'LI' => 'lístɛ́nsitáyin',
 			'LK' => 'silíláŋka',
 			'LR' => 'lipélia',
 			'LS' => 'lesotó',
 			'LT' => 'litiyaní',
 			'LU' => 'liksambúul',
 			'LV' => 'letoní',
 			'LY' => 'lipíi',
 			'MA' => 'malóok',
 			'MC' => 'monakó',
 			'MD' => 'moltafí',
 			'MG' => 'matakaskáal',
 			'MH' => 'ílmalasáal',
 			'MK' => 'masetuán',
 			'ML' => 'malí',
 			'MM' => 'miaŋmáal',
 			'MN' => 'mongolí',
 			'MP' => 'il maliyanɛ u muɛnɛ́',
 			'MQ' => 'maltiníik',
 			'MR' => 'molitaní',
 			'MS' => 'mɔŋsilá',
 			'MT' => 'málɛ́t',
 			'MU' => 'molís',
 			'MV' => 'maletíif',
 			'MW' => 'malawí',
 			'MX' => 'mɛksíik',
 			'MY' => 'malesí',
 			'MZ' => 'mosambík',
 			'NA' => 'namipí',
 			'NC' => 'nufɛ́l kaletoní',
 			'NE' => 'nisɛ́ɛl',
 			'NF' => 'il nɔ́lfɔ́lɔk',
 			'NG' => 'nisélia',
 			'NI' => 'nikalaká',
 			'NL' => 'nitililáand',
 			'NO' => 'nɔlfɛ́ɛs',
 			'NP' => 'nepáal',
 			'NR' => 'nawulú',
 			'NU' => 'niyuwé',
 			'NZ' => 'nufɛ́l seláand',
 			'OM' => 'omáŋ',
 			'PA' => 'panamá',
 			'PE' => 'pelú',
 			'PF' => 'polinesí u felensí',
 			'PG' => 'papuasí nufɛ́l kiiné',
 			'PH' => 'filipíin',
 			'PK' => 'pakistáŋ',
 			'PL' => 'pɔlɔ́ɔny',
 			'PM' => 'sɛ́ŋpiɛ́l e mikelɔ́ŋ',
 			'PN' => 'pitikɛ́ɛlínɛ́',
 			'PR' => 'pólótolíko',
 			'PS' => 'kitɔŋ ki palɛstíin',
 			'PT' => 'pɔltukáal',
 			'PW' => 'palawú',
 			'PY' => 'palakúé',
 			'QA' => 'katáal',
 			'RE' => 'elewuniɔ́ŋ',
 			'RO' => 'ulumaní',
 			'RU' => 'ulusí',
 			'RW' => 'uluándá',
 			'SA' => 'alapísawutíit',
 			'SB' => 'il salomɔ́ŋ',
 			'SC' => 'sesɛ́ɛl',
 			'SD' => 'sutáaŋ',
 			'SE' => 'suɛ́t',
 			'SG' => 'singapúul',
 			'SH' => 'sɛ́ŋtɛ́ elɛ́ɛnɛ',
 			'SI' => 'silofení',
 			'SK' => 'silofakí',
 			'SL' => 'sieláleyɔ́ɔn',
 			'SM' => 'san malíno',
 			'SN' => 'senekáal',
 			'SO' => 'somalí',
 			'SR' => 'sulináam',
 			'ST' => 'sáwó tomé e pelensípe',
 			'SV' => 'salfatɔ́ɔl',
 			'SZ' => 'suasiláand',
 			'TC' => 'túluk na káyiik',
 			'TD' => 'Sáat',
 			'TG' => 'tokó',
 			'TH' => 'tayiláand',
 			'TJ' => 'tasikistáaŋ',
 			'TK' => 'tokeló',
 			'TL' => 'timɔ́ɔl u nipálɛ́n',
 			'TM' => 'tulukmenisitáaŋ',
 			'TN' => 'tunusí',
 			'TO' => 'tɔ́ŋka',
 			'TR' => 'tulukíi',
 			'TT' => 'tilinitáat na tupákɔ',
 			'TV' => 'tufalú',
 			'TW' => 'tayiwáan',
 			'TZ' => 'taŋsaní',
 			'UA' => 'ukilɛ́ɛn',
 			'UG' => 'ukánda',
 			'US' => 'amálíka',
 			'UY' => 'ulukuéy',
 			'UZ' => 'usupekistáaŋ',
 			'VA' => 'fatikáaŋ',
 			'VC' => 'sɛ́ŋ fɛŋsáŋ elekelenatíin',
 			'VE' => 'fenesuwelá',
 			'VG' => 'Filisíin ungilís',
 			'VI' => 'pindisúlɛ́ pi amálíka',
 			'VN' => 'fiɛtnáam',
 			'VU' => 'fanuatú',
 			'WF' => 'walíis na futúna',
 			'WS' => 'samowá',
 			'YE' => 'yémɛn',
 			'YT' => 'mayɔ́ɔt',
 			'ZA' => 'afilí mbátɛ́',
 			'ZM' => 'saambíi',
 			'ZW' => 'simbapuwé',

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
			auxiliary => qr{[g j q r x z]},
			index => ['A', 'B', 'C', 'D', 'E', 'Ɛ', 'F', 'H', 'I', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'S', 'T', 'U', 'V', 'W', 'Y'],
			main => qr{[a á à â ǎ ā b c d e é è ɛ {ɛ́} {ɛ̀} f h i í ì î ī k l m {mb} n {ny} ŋ {ŋg} o ó ò ô ǒ ō ɔ {ɔ́} {ɔ̀} p s t u ú ù û ǔ ū v w y]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'Ɛ', 'F', 'H', 'I', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'Ɔ', 'P', 'S', 'T', 'U', 'V', 'W', 'Y'], };
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
	default		=> qq{«},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ɛ́ɛ́ɛ|ɛ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:aákó|a|no|n)$' }
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
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
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
						'negative' => '(#,##0.00 ¤)',
						'positive' => '#,##0.00 ¤',
					},
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
		'AOA' => {
			display_name => {
				'currency' => q(kuansa wu angolá),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(toláal wu ostalalí),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(tináal wu paaléen),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(faláŋɛ u pulundí),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula pu posuána),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(toláal u kanáta),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(́faláŋɛ u kongó),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(yuan ɛlɛnmimbí),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(ɛskúdo u kápfɛ́ɛl),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(́faláŋɛ u síputí),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(tináal wu alselí),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(lífilɛ wu isípit),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(náfka wu elitilée),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(píil wu etiopí),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(olóo),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(lífilɛ sitelelíiŋ),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(setí),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(talasí u kaambí),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(silí u kiiné),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(ulupí),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(yɛ́ɛn u sapɔ́ɔŋ),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(síliŋ u kénia),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(́faláŋɛ u kɔmɔ́ɔl),
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
							'o.1',
							'o.2',
							'o.3',
							'o.4',
							'o.5',
							'o.6',
							'o.7',
							'o.8',
							'o.9',
							'o.10',
							'o.11',
							'o.12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'pikítíkítie, oólí ú kutúan',
							'siɛyɛ́, oóli ú kándíɛ',
							'ɔnsúmbɔl, oóli ú kátátúɛ',
							'mesiŋ, oóli ú kénie',
							'ensil, oóli ú kátánuɛ',
							'ɔsɔn',
							'efute',
							'pisuyú',
							'imɛŋ i puɔs',
							'imɛŋ i putúk,oóli ú kátíɛ',
							'makandikɛ',
							'pilɔndɔ́'
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
						mon => 'md',
						tue => 'mw',
						wed => 'et',
						thu => 'kl',
						fri => 'fl',
						sat => 'ss',
						sun => 'sd'
					},
					wide => {
						mon => 'móndie',
						tue => 'muányáŋmóndie',
						wed => 'metúkpíápɛ',
						thu => 'kúpélimetúkpiapɛ',
						fri => 'feléte',
						sat => 'séselé',
						sun => 'sɔ́ndiɛ'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'm',
						tue => 'm',
						wed => 'e',
						thu => 'k',
						fri => 'f',
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
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					wide => {0 => 'ndátúɛ 1',
						1 => 'ndátúɛ 2',
						2 => 'ndátúɛ 3',
						3 => 'ndátúɛ 4'
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
				'wide' => {
					'am' => q{kiɛmɛ́ɛm},
					'pm' => q{kisɛ́ndɛ},
				},
				'abbreviated' => {
					'am' => q{kiɛmɛ́ɛm},
					'pm' => q{kisɛ́ndɛ},
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
				'0' => 'k.Y.',
				'1' => '+J.C.'
			},
			wide => {
				'0' => 'katikupíen Yésuse',
				'1' => 'ékélémkúnupíén n'
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
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
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
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
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
