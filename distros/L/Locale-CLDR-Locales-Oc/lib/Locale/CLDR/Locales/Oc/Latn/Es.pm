=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Oc::Latn::Es - Package for language Occitan

=cut

package Locale::CLDR::Locales::Oc::Latn::Es;
# This file auto generated from Data\common\main\oc_ES.xml
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

extends('Locale::CLDR::Locales::Oc::Latn');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ar' => 'arab',
 				'ar_001' => 'arab estandard modèrne',
 				'bn' => 'bengalí',
 				'de_AT' => 'alemand austriac',
 				'de_CH' => 'naut alemand suís',
 				'en_CA' => 'anglés canadienc',
 				'en_GB@alt=short' => 'anglés (Regne Unit)',
 				'es' => 'espanhòu',
 				'es_419' => 'espanhòu latinoamerican',
 				'es_ES' => 'espanhòu d’Espanha',
 				'es_MX' => 'espanhòu de Mexic',
 				'fi' => 'finés',
 				'fr_CA' => 'francés canadienc',
 				'fr_CH' => 'francés suís',
 				'hi_Latn' => 'hindi (latin)',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hu' => 'hongarés',
 				'id' => 'indonesi',
 				'pt_BR' => 'portugés de Brasil',
 				'pt_PT' => 'portugués de Portugal',
 				'sl' => 'esloven',
 				'sv' => 'suec',
 				'th' => 'tailandés',
 				'und' => 'lengua desconeishuda',
 				'zh@alt=menu' => 'chinés mandarin',
 				'zh_Hans' => 'shinés simplificat',
 				'zh_Hant' => 'chinés tradicionau',
 				'zh_Hant@alt=long' => 'chinés mandarin tradicionau',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_script' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		sub {
			my %scripts = (
			'Arab' => 'arab',
 			'Hans@alt=stand-alone' => 'han simplificat',
 			'Hant' => 'tradicionau',
 			'Hant@alt=stand-alone' => 'han tradicionau',
 			'Latn' => 'latino',
 			'Zxxx' => 'no escrit',
 			'Zzzz' => 'alfabet desconeishut',

			);
			if ( @_ ) {
				return $scripts{$_[0]};
			}
			return \%scripts;
		}
	}
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'001' => 'Mon',
 			'003' => 'America deth Nòrd',
 			'005' => 'Sudamerica',
 			'011' => 'Africa occidentau',
 			'013' => 'Centreamerica',
 			'014' => 'Africa orientau',
 			'015' => 'Africa septentrionau',
 			'017' => 'Africa centrau',
 			'018' => 'Africa meridionau',
 			'019' => 'America',
 			'021' => 'Nòrt America',
 			'030' => 'Asia orientau',
 			'034' => 'Asia meridionau',
 			'035' => 'Sudèst aisatic',
 			'039' => 'Euròpa meridionau',
 			'053' => 'Australasia',
 			'057' => 'Region de Micronesia',
 			'143' => 'Asia centrau',
 			'145' => 'Asia occidentau',
 			'151' => 'Euròpa orientau',
 			'154' => 'Euròpa septentrionau',
 			'155' => 'Euròpa occidentau',
 			'419' => 'Latinoamerica',
 			'AI' => 'Anguila',
 			'AQ' => 'Antartida',
 			'AS' => 'Samoa Americana',
 			'AU' => 'Australia',
 			'AX' => 'Isles Åland',
 			'BF' => 'Burquina Faso',
 			'BH' => 'Barein',
 			'BI' => 'Borondi',
 			'BL' => 'Sant Bartolomé',
 			'BM' => 'Bermudes',
 			'BO' => 'Bolivia',
 			'BQ' => 'Carib neerlandés',
 			'BW' => 'Botsuana',
 			'BZ' => 'Belice',
 			'CC' => 'Isles Còcos',
 			'CD' => 'Republica Democratica deth Còngo',
 			'CD@alt=variant' => 'Còngo (RDC)',
 			'CF' => 'Republica Centreafricana',
 			'CG' => 'Còngo',
 			'CG@alt=variant' => 'Còngo (Republica)',
 			'CI' => 'Còsta d’Ivoire',
 			'CI@alt=variant' => 'Còsta de Marfil',
 			'CK' => 'Isles Cook',
 			'CO' => 'Colòmbia',
 			'CP' => 'Isla Clipperton',
 			'CV' => 'Cabo Verde',
 			'CX' => 'Isla de Nadau',
 			'DJ' => 'Yibuti',
 			'DK' => 'Dinamarca',
 			'DO' => 'Republica Dominicana',
 			'DZ' => 'Argelia',
 			'EC' => 'Equador',
 			'EH' => 'Sahara Occidentau',
 			'ER' => 'Eritrea',
 			'EZ' => 'zòna euro',
 			'FI' => 'Finlandia',
 			'FJ' => 'Fiyi',
 			'FK' => 'Isles Malvines',
 			'FK@alt=variant' => 'Isles Malvines (Isles Falkland)',
 			'FO' => 'Isles Faròe',
 			'GA' => 'Gabòn',
 			'GB' => 'Regne Unit',
 			'GD' => 'Granada',
 			'GF' => 'Guaiana Francesa',
 			'GG' => 'Guernesey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadalupe',
 			'GQ' => 'Guinèa Equatorial',
 			'GS' => 'Isles Geòrgia deth Sud e Sandwich deth Sud',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'RAE de Hong Kong (China)',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Isles Heard e McDonald',
 			'HN' => 'Honduras',
 			'HT' => 'Aití',
 			'IC' => 'Isles Canàries',
 			'IL' => 'Israel',
 			'IM' => 'Isla de Man',
 			'IO' => 'Territòri Britanic der Ocean Índic',
 			'JM' => 'Jamaica',
 			'KG' => 'Kirguistan',
 			'KH' => 'Cambòya',
 			'KI' => 'Kiribati',
 			'KM' => 'Comores',
 			'KN' => 'Sant Critòbal e Nieves',
 			'KP' => 'Corèa deth Nòrd',
 			'KR' => 'Corèa deth Sud',
 			'KY' => 'Isles Caiman',
 			'KZ' => 'Kazajistan',
 			'LR' => 'Liberia',
 			'LS' => 'Lesoto',
 			'LT' => 'Lituania',
 			'MC' => 'Mònaco',
 			'MH' => 'Isles Marshall',
 			'MK' => 'Macedònia deth Nòrd',
 			'MO' => 'RAE de Macao (China)',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Isles Marianes deth Nòrd',
 			'MR' => 'Mauritania',
 			'MV' => 'Maldives',
 			'MW' => 'Malawi',
 			'NC' => 'Nòva Caledònia',
 			'NE' => 'Níger',
 			'NF' => 'Isla Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Païsi Baishi',
 			'NO' => 'Noroega',
 			'NZ@alt=variant' => 'Aotearoa (Nòva Zelanda)',
 			'PF' => 'Polinesia Francesa',
 			'PH' => 'Filipines',
 			'PL' => 'Polonia',
 			'PM' => 'Sant Pèir e Miquelon',
 			'PN' => 'Isla Pitcairn',
 			'PS' => 'Territòris Palestins',
 			'PW' => 'Palaos',
 			'QA' => 'Quatar',
 			'QO' => 'Territòris aluenhats d’Oceania',
 			'RE' => 'Reunion',
 			'RU' => 'Rossia',
 			'SB' => 'Isles Salomon',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Suecia',
 			'SL' => 'Sierra Leona',
 			'SM' => 'Sant Marino',
 			'SS' => 'Sudan deth Sud',
 			'ST' => 'Sant Tomé e Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Esoatini',
 			'SZ@alt=variant' => 'Suazilandia',
 			'TC' => 'Isles Turques e Caicos',
 			'TF' => 'Territòris Australs Francesi',
 			'TJ' => 'Tayikistan',
 			'TL' => 'Timòr-Leste',
 			'TL@alt=variant' => 'Timòr Orientau',
 			'TM' => 'Turkmenistan',
 			'TT' => 'Trinitat e Tobago',
 			'UM' => 'Islas menors aluenhades d’EE. UU.',
 			'UN' => 'Nacions Unides',
 			'US@alt=short' => 'EE. UU.',
 			'VA' => 'Ciutat deth Vatican',
 			'VC' => 'Sant Vicent e Granadines',
 			'VE' => 'Veneçuela',
 			'VG' => 'Isles Verges Britaniques',
 			'VI' => 'Isles Verges EE. UU.',
 			'XA' => 'pseudoaccents',
 			'XB' => 'pseudobidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'ZA' => 'Sudafrica',
 			'ZW' => 'Zimbabue',
 			'ZZ' => 'region desconeishuda',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => {
 				'gregorian' => q{calendari gregorian},
 				'iso8601' => q{calendari ISO-8601},
 			},
 			'collation' => {
 				'standard' => q{ordre estandard},
 			},
 			'numbers' => {
 				'latn' => q{digits occidentaus},
 			},

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'metric' => q{métric},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Lengua: {0}',
 			'script' => 'Escritura: {0}',
 			'region' => 'Region: {0}',

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
			index => ['A', 'B', 'CÇ', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” « » ( ) \[ \] § @ * / \& # † ‡ ⋅]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'CÇ', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'initial' => '… {0}',
			'medial' => '{0}… {1}',
			'word-initial' => '… {0}',
		};
	},
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

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(punt cardinau),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punt cardinau),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(punt),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punt),
					},
				},
			} }
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 2,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'adlm' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'bali' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'beng' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'brah' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'cakm' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'cham' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'deva' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'fullwide' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'gong' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'gonm' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'gujr' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'guru' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'hanidec' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'hmnp' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'java' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'kali' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'khmr' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'knda' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'lana' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'lanatham' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'laoo' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'latn' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'lepc' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'limb' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'mlym' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'mong' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'mtei' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'mymr' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'mymrshan' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'nkoo' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'olck' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'orya' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'osma' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'rohg' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'saur' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'shrd' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'sora' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'sund' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'takr' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'talu' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'tamldec' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'telu' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'thai' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'tibt' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
		'vaii' => {
			'decimal' => q(.),
			'group' => q(,),
			'timeSeparator' => q(:),
		},
	} }
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'adlm' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'arabext' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'bali' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'beng' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'brah' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'cakm' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'cham' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'deva' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'fullwide' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'gong' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'gonm' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'gujr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'guru' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'hanidec' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'java' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'kali' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'khmr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'knda' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'lana' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'lanatham' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'laoo' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'lepc' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'limb' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'mlym' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'mong' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'mtei' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'mymr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'mymrshan' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'nkoo' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'olck' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'orya' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'osma' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'rohg' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'saur' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'shrd' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'sora' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'sund' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'takr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'talu' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'tamldec' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'telu' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'thai' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'tibt' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '#,##0.00¤',
					},
				},
			},
		},
		'vaii' => {
			'pattern' => {
				'default' => {
					'accounting' => {
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
		'ANG' => {
			display_name => {
				'currency' => q(florin atillan),
			},
		},
		'ARS' => {
			symbol => 'ARS',
		},
		'AUD' => {
			symbol => 'AUD',
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(dòlars bermudense),
			},
		},
		'BND' => {
			symbol => 'BND',
		},
		'BRL' => {
			symbol => 'BRL',
		},
		'BZD' => {
			symbol => 'BZD',
		},
		'CAD' => {
			symbol => 'CAD',
		},
		'CLP' => {
			symbol => 'CLP',
		},
		'CNH' => {
			display_name => {
				'currency' => q(yuan chinés \(extracontinanetau\)),
				'other' => q(yuans chinessi \(extracontinanetaus\)),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'other' => q(yuans chinessi),
			},
		},
		'COP' => {
			symbol => 'COP',
		},
		'DOP' => {
			display_name => {
				'currency' => q(peso dominican),
			},
		},
		'EGP' => {
			symbol => 'EGP',
		},
		'FJD' => {
			symbol => 'FJD',
		},
		'FKP' => {
			symbol => 'FKP',
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'other' => q(liures esterlines),
			},
		},
		'GIP' => {
			symbol => 'GIP',
		},
		'GMD' => {
			display_name => {
				'currency' => q(calasi),
			},
		},
		'HKD' => {
			display_name => {
				'other' => q(dòlars hongkonessi),
			},
		},
		'ILS' => {
			symbol => 'ILS',
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(ropia inidia),
				'other' => q(ropies indies),
			},
		},
		'KMF' => {
			symbol => 'CF',
		},
		'KRW' => {
			symbol => 'KRW',
		},
		'KYD' => {
			display_name => {
				'currency' => q(dòlar des Isles Caiman),
				'other' => q(dòlars des Isles Caiman),
			},
		},
		'LBP' => {
			symbol => 'LBP',
		},
		'MVR' => {
			display_name => {
				'other' => q(rufiyes),
			},
		},
		'MXN' => {
			symbol => 'MXN',
		},
		'NAD' => {
			symbol => 'NAD',
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'other' => q(dòlars neozelandessi),
			},
		},
		'PGK' => {
			display_name => {
				'other' => q(kines),
			},
		},
		'RUB' => {
			display_name => {
				'other' => q(robles russi),
			},
		},
		'RWF' => {
			symbol => 'RF',
		},
		'SBD' => {
			symbol => 'SBD',
		},
		'SGD' => {
			symbol => 'SDG',
		},
		'SRD' => {
			symbol => 'SRD',
		},
		'THB' => {
			symbol => '฿',
		},
		'TOP' => {
			symbol => 'T$',
		},
		'TRY' => {
			symbol => 'TL',
		},
		'TTD' => {
			symbol => 'TTD',
		},
		'TWD' => {
			display_name => {
				'other' => q(naus dòlars taiwanessi),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(dòlar estadounidenc),
				'other' => q(dòlars estadounidencs),
			},
		},
		'UYU' => {
			symbol => 'UYU',
		},
		'WST' => {
			symbol => 'WST',
		},
		'XAF' => {
			symbol => 'XAF',
			display_name => {
				'currency' => q(franc CFA d’Africa centrau),
				'other' => q(francs CFA d’Africa centrau),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(dòlar deth Caribe Occidentau),
				'other' => q(dòlars deth Caribe Occidentau),
			},
		},
		'XOF' => {
			symbol => 'XOF',
			display_name => {
				'currency' => q(franc CFA d’Africa occidentau),
				'other' => q(francs CFA d’Africa occidentau),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(moneda desconeishuda),
				'other' => q(\(moneda desconeishuda\)),
			},
		},
		'ZMW' => {
			symbol => 'ZK',
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
							'gèr',
							'her',
							'mar',
							'abr',
							'mai',
							'jun',
							'jur',
							'ago',
							'set',
							'oct',
							'nov',
							'dec'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'G',
							'H',
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
					wide => {
						nonleap => [
							'gèr',
							'hereuèr',
							'març',
							'abriu',
							'mai',
							'junh',
							'juriòl',
							'agost',
							'seteme',
							'octobre',
							'noveme',
							'deseme'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					wide => {
						nonleap => [
							'gèr',
							'hereuèr',
							'març',
							'abriu',
							'mai',
							'junh',
							'juriòl',
							'agost',
							'seteme',
							'octobre',
							'noveme',
							'deseme'
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
						mon => 'del',
						tue => 'dma',
						wed => 'dmè',
						thu => 'dij',
						fri => 'diu',
						sat => 'dis',
						sun => 'dim'
					},
					short => {
						mon => 'de',
						tue => 'da',
						wed => 'dm',
						thu => 'dj',
						fri => 'du',
						sat => 'ds',
						sun => 'di'
					},
					wide => {
						mon => 'deluns',
						tue => 'dimars',
						wed => 'dimèrcles',
						thu => 'dijaus',
						fri => 'diuendres',
						sat => 'dissabte',
						sun => 'dimenge'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'X',
						thu => 'J',
						fri => 'U',
						sat => 'S',
						sun => 'D'
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
					wide => {0 => '1èr trimèstre',
						1 => '2au trimèstre',
						2 => '3au trimèstre',
						3 => '4au trimèstre'
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
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
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
				'0' => 'a. C.',
				'1' => 'd. C.'
			},
			narrow => {
				'0' => 'a. C.',
				'1' => 'd. C.'
			},
			wide => {
				'0' => 'abans Jesucrist',
				'1' => 'dempús de Crist'
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
			'full' => q{EEEE, d 'de' MMMM 'de' y G},
			'long' => q{d 'de' MMMM 'de' y G},
			'medium' => q{d 'de' MMM 'de' y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y},
			'long' => q{d 'de' MMMM 'de' y},
			'medium' => q{d MMM y},
			'short' => q{d/MM/yy},
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
			'full' => q{H:mm:ss (zzzz)},
			'long' => q{H:mm:ss z},
			'medium' => q{H:mm:ss},
			'short' => q{H:mm},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMM => q{MMMM 'de' y G},
			GyMMMMEd => q{E, d 'de' MMMM 'de' y G},
			GyMMMMd => q{d 'de' MMMM 'de' y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d 'de' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{EEE, d MMM y G},
			yyyyMMMM => q{MMMM 'de' y G},
			yyyyMMMMEd => q{EEE, d 'de' MMMM 'de' y G},
			yyyyMMMMd => q{d 'de' MMMM 'de' y G},
			yyyyMMMd => q{d MMM, y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E, H:mm},
			EHms => q{E, H:mm:ss},
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			GyMMMEd => q{E, d MMM y G},
			GyMMMM => q{MMMM 'de' y G},
			GyMMMMEd => q{E, d 'de' MMMM 'de' y G},
			GyMMMMd => q{d 'de' MMMM 'de' y G},
			GyMd => q{d/M/y G},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			Hmsv => q{H:mm:ss v},
			Hmv => q{H:mm v},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d 'de' MMMM},
			MMMMW => q{'setmana' W 'de' MMMM},
			MMMMd => q{d 'de' MMMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M/y},
			yMEd => q{EEE, d/M/y},
			yMMMEd => q{EEE, d MMM y},
			yMMMM => q{MMMM 'de' y},
			yMMMMEd => q{EEE, d 'de' MMMM 'de' y},
			yMMMMd => q{d 'de' MMMM 'de' y},
			yMd => q{d/M/y},
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
		'generic' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E d/M/y GGGGG – E d/M/y GGGGG},
				M => q{E d/M/y – E d/M/y GGGGG},
				d => q{E d/M/y – E d/M/y GGGGG},
				y => q{E d/M/y – E d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM 'de' y G – MMM 'de' y G},
				M => q{MMM – MMM 'de' y G},
				y => q{MMM 'de' y – MMM 'de' y G},
			},
			GyMMMEd => {
				G => q{E, d 'de' MMM 'de' y G – E d 'de' MMM 'de' y G},
				M => q{E, d 'de' MMM – E d 'de' MMM 'de' y G},
				d => q{E, d 'de' MMM – E d 'de' MMM 'de' y G},
				y => q{E, d 'de' MMM 'de' y – E d 'de' MMM 'de' y G},
			},
			GyMMMd => {
				G => q{d 'de' MMM 'de' y G – d 'de' MMM 'de' y G},
				M => q{d 'de' MMM – d 'de' MMM 'de' y G},
				d => q{d – d 'de' MMM 'de' y G},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM},
				d => q{E, d 'de' MMM – E, d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM – d 'de' MMM},
				d => q{d – d 'de' MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM 'de' y G},
				y => q{MMM 'de' y – MMM 'de' y G},
			},
			yMMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				d => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				y => q{E, d 'de' MMM 'de' y – E, d 'de' MMM 'de' y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM 'de' y G},
				y => q{MMMM 'de' y – MMMM 'de' y G},
			},
			yMMMd => {
				M => q{d 'de' MMM – d 'de' MMM y G},
				d => q{d – d 'de' MMM 'de' y G},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
			},
			GyM => {
				G => q{M/y G – M/y G},
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			GyMEd => {
				G => q{E, d/M/y G – E, d/M/y G},
				M => q{E, d/M/y – E, d/M/y G},
				d => q{E, d/M/y – E, d/M/y G},
				y => q{E, d/M/y – E, d/M/y G},
			},
			GyMMMEd => {
				G => q{E, d MMM – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM, y G},
				y => q{E, d MMM, y – E, d MMM, y G},
			},
			GyMMMd => {
				d => q{d–d MMM y G},
			},
			GyMd => {
				G => q{d/M/y G – d/M/y G},
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMMEd => {
				M => q{E, d 'de' MMMM – E, d 'de' MMMM},
				d => q{E, d 'de' MMMM – E, d 'de' MMMM},
			},
			MMMMd => {
				M => q{d 'de' MMMM – d 'de' MMMM},
				d => q{d–d 'de' MMMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMMEd => {
				M => q{E, d MMM y – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMMEd => {
				M => q{E, d 'de' MMMM – E, d 'de' MMMM 'de' y},
				d => q{E, d 'de' MMMM – E, d 'de' MMMM 'de' y},
				y => q{E, d 'de' MMMM 'de' y – E, d 'de' MMMM 'de' y},
			},
			yMMMMd => {
				M => q{d 'de' MMMM – d 'de' MMMM 'de' y},
				d => q{d–d 'de' MMMM 'de' y},
				y => q{d 'de' MMMM 'de' y – d 'de' MMMM 'de' y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(orari d’estiu de {0}),
		regionFormat => q(orari estandard de {0}),
		'Africa/Abidjan' => {
			exemplarCity => q#Abiyan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Acra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adís Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Argel#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisau#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Eth Cairo#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Yibuti#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Jartum#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadiscio#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Yamena#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nuakchot#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uagadugú#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Portonovo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sant Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Trípoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Túnez#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#ora d’Africa central#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#ora d’Africa orientau#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#ora d’estiu d’Africa occidentau#,
				'generic' => q#ora d’Africa occidentau#,
				'standard' => q#ora esdandard d’Africa occidentau#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#ora d’estiu d’Alaska#,
				'generic' => q#ora d’Alaska#,
				'standard' => q#ora estandard d’Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#ora d’estiu der Amazònes#,
				'generic' => q#ora der Amazònes#,
				'standard' => q#ora estandard der Amazònes#,
			},
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Río Gallegos#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia de Banderas#,
		},
		'America/Belem' => {
			exemplarCity => q#Belén#,
		},
		'America/Belize' => {
			exemplarCity => q#Belice#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Cayena#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caiman#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Còdoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Còsta Rica#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Gran Turca#,
		},
		'America/Grenada' => {
			exemplarCity => q#Granada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalupe#,
		},
		'America/Havana' => {
			exemplarCity => q#Era Havana#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Manaus' => {
			exemplarCity => q#MmManaos#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinica#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Ciutat de Méxic#,
		},
		'America/New_York' => {
			exemplarCity => q#Nòva York#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Dakota deth Nòrd#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota deth Nòrd#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota deth Nòrd#,
		},
		'America/Panama' => {
			exemplarCity => q#Panamà#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Puerto Príncipe#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Puerto Espanha#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago de Chile#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sao paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sant Bartolomé#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sant Joan de Terranòva#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sant Cristòbal#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Lucía#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sant Vicent#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tòrtola#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#ora d’estiu centrau#,
				'generic' => q#ora centrau#,
				'standard' => q#ora estandard centrau#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#ora d’estiu orientau#,
				'generic' => q#ora orientau#,
				'standard' => q#ora estandard orientau#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#ora d’estiu des Montanhes Rocoses#,
				'generic' => q#ora des Montanhes Rocoses#,
				'standard' => q#ora estandard des Montanhes Rocoses#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#ora d’estiu deth Pacific#,
				'generic' => q#ora deth Pacific#,
				'standard' => q#ora estandard deth Pacific#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#ora d’estiu d’arabia#,
				'generic' => q#ora d’Arabia#,
				'standard' => q#ora estandard d’Arabia#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#ora d’estiu d’Argentina#,
				'generic' => q#ora d’Argentina#,
				'standard' => q#ora estandard d’Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#ora d’estiu d’Argentina occidentau#,
				'generic' => q#ora d’Agertina occidentau#,
				'standard' => q#ora estandard d’Argentina occidentau#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#ora d’estiu d’Armenia#,
				'generic' => q#ora d’Armenia#,
				'standard' => q#ora estandard d’Armenia#,
			},
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anádyr#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Asjabad#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Baréin#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakú#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaúl#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chitá#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasco#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dusambé#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalen#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandú#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Mascate#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Catar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanai#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ciutat Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sajalín#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seol#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolimsk#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taskent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiflies#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Timbu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümqi#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Ereván#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#ora d’estiu der Atlantic#,
				'generic' => q#ora der Atlantic#,
				'standard' => q#ora estandard der Atlantic#,
			},
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudes#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cabo Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Isles Feroe#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reikiavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Geòrgia deth Sud#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Santa Elena#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sídney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#ora d’estiu d’Austràlia centrau#,
				'generic' => q#ora d’Austràlia centrau#,
				'standard' => q#ora estandard d’Austràlia centrau#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#ora d’estiu d’Austràlia centreoccidentau#,
				'generic' => q#ora d’Austràlia centreoccidentau#,
				'standard' => q#ora estandarda d’Austràlia centreoccidentau#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#ora d’estiu d’Austràlia orientau#,
				'generic' => q#ora d’Austràlia orientau#,
				'standard' => q#ora estandard d’Austràlia orientau#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#ora d’estiu estandard d’Australia occidentau#,
				'generic' => q#ora d’Austràlia occidentau#,
				'standard' => q#ora estandard d’Australia occidentau#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#ora d’estiu d’Azerbaijan#,
				'generic' => q#ora d’Azerbaijan#,
				'standard' => q#ora estandard d’Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#ora d’estiu des Açòres#,
				'generic' => q#ora des Açòres#,
				'standard' => q#ora estandard des Açòres#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#ora d’estiu de Bangladesh#,
				'generic' => q#ora de Bangaldesh#,
				'standard' => q#ora estandard de Bangladesh#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#ora d’estiu de Brasilia#,
				'generic' => q#ora de Brasilia#,
				'standard' => q#ora estandard de Brasilia#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#ora d’estiu de Cap-Verd#,
				'generic' => q#ora de Cap-Verd#,
				'standard' => q#ora estandard de Cap-Verd#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#ora d’estiu de Chile#,
				'generic' => q#ora de Chile#,
				'standard' => q#ora estandard de Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#ora d’estiu de China#,
				'generic' => q#ora de China#,
				'standard' => q#ora estandard de China#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#ora d’estiu de Choibalsan#,
				'generic' => q#ora de Choibalsan#,
				'standard' => q#ora estandard de Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#ora dera isla de Nadau#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#ora dera isla de Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#ora d’estiu de Colòmbia#,
				'generic' => q#ora de Colòmbia#,
				'standard' => q#ora estandard de Colòmbia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#ora d’estiu mieja des Isles Cook#,
				'generic' => q#ora des Isles Cook#,
				'standard' => q#ora estandard des Isles Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#ora d’estiu de Cuba#,
				'generic' => q#ora de Cuba#,
				'standard' => q#ora estandard de Cuba#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#ora de Timòr orientau#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#ora d’estiu dera isla de Pasqua#,
				'generic' => q#ora dera isla de Pasqua#,
				'standard' => q#ora estandard dera isla de Pasqua#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#ora universau coordinada#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#ciutat desconeishuda#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astracan#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucarest#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#ora d’estiu d’Irlanda#,
			},
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Isla de Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Estambul#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kírov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboa#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Liubliana#,
		},
		'Europe/London' => {
			exemplarCity => q#Lòndres#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#Sant Marino#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Sarátov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferòpol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopie#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofía#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Estocolm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uliánovsk#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Eth Vatican#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viena#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilna#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsòvia#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporiyia#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zúrich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#ora d’estiu d’Euròpa centrau#,
				'generic' => q#ora d’Euròpa centrau#,
				'standard' => q#ora estandard d’Euròpa centrau#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#ora d’estiu d’Euròpa de l’èst#,
				'generic' => q#ora d’Euròpa de l’èst#,
				'standard' => q#ora estandard d’Euròpa de l’èst#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#ora der extrem d’Euròpa orientau#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#ora d’estiu d’Euròpa occidentau#,
				'generic' => q#ora d’Euròpa occidentau#,
				'standard' => q#ora estandard d’Euròpa occidentau#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#ora d’estiu des isles Maldives#,
				'generic' => q#ora des isles Maldives#,
				'standard' => q#ora estandard des isles Maldives#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#ora dera Guayana Francesa#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#hora d’Antartida e Territoris Australs Francesi#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#ora deth meridian de Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#ora de Galápagos#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#ora d’estiu de Geòrgia#,
				'generic' => q#ora de Geòrgia#,
				'standard' => q#ora estandard de Geòrgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#ora des Isles Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#ora d’estiu de Groenlandia orientau#,
				'generic' => q#ora de Groenlandia orientau#,
				'standard' => q#ora estandard de Groenlandia orientau#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#ora d’estiu de Groenlandia occidentau#,
				'generic' => q#ora de Groenlandia occidentau#,
				'standard' => q#ora estandard de Groenlandia occidentau#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#ora de Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#ora d’estiu de Hawai-Aleutianes#,
				'generic' => q#ora de Hawai-Aleutianes#,
				'standard' => q#ora estandard de Hawai-Aleutianes#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#ora d’estiu de Hong Kong#,
				'generic' => q#ora de Hong Kong#,
				'standard' => q#ora estandard de Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#ora d’estiu de Hovd#,
				'generic' => q#ora de Hovd#,
				'standard' => q#ora estandard de Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#ora estandard dera India#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Nadau#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comores#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Maurici#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#ora der Ocean Indic#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#hora d’Indonesia centrau#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#hora d’Indonesia orientau#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#hora d’Indonesia occidentau#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#ora d’estiu d’Iran#,
				'generic' => q#ora d’Iran#,
				'standard' => q#ora estandard d’Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#ora d’estiu d’Irkutsk#,
				'generic' => q#ora d’Irkutsk#,
				'standard' => q#ora estandard d’Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#ora d’estiu d’Israèl#,
				'generic' => q#ora d’Israèl#,
				'standard' => q#ora estàndard d’Israèl#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#ora d’estiu de Japon#,
				'generic' => q#ora de Japon#,
				'standard' => q#ora estandard de Japon#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#ora de Kazajistan orientau#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#ora de Kazajistan occidentau#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#ora d’estiu de Corèa#,
				'generic' => q#ora de Corèa#,
				'standard' => q#ora estandard de Corèa#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#ora d’estiu de Krasnoyarsk#,
				'generic' => q#ora de Krasnoyarsk#,
				'standard' => q#ora estandard de Krasnoyarsk#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#ora des Espòrades Equatorials#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#ora dera Isla Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#ora d’estiu de Magadan#,
				'generic' => q#ora de Magadan#,
				'standard' => q#ora estandard de Magadan#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#ora des Isles Marqueses#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#ora des Isles Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#ora d’estiu de Maurici#,
				'generic' => q#ora de Maurici#,
				'standard' => q#ora estandard de Maurici#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#ora d’estiu deth nòrd-èst de Mexic#,
				'generic' => q#ora deth nòrd-èst de Mexic#,
				'standard' => q#ora estandard deth nòrd-èst de Mexic#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#ora d’estiu deth Pacífic de Mexic#,
				'generic' => q#ora deth Pacífic de Mexic#,
				'standard' => q#ora estandard deth Pacífic de Mexic#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#ora d’estiu de Ulan Bator#,
				'generic' => q#ora de Ulan Bator#,
				'standard' => q#ora estandard de Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#ora d’estiu de Moscòu#,
				'generic' => q#ora de Moscòu#,
				'standard' => q#ora estandard de Moscòu#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#ora deth Nepal#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#ora d’estiu de Terra-Nòva#,
				'generic' => q#ora de Terra-Nòva#,
				'standard' => q#ora estandard de Terra-Nòva#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#ora d’estiu dera Isla Norfolk#,
				'generic' => q#ora dera Isla Norfolk#,
				'standard' => q#ora estandard dera Isla Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#ora d’estiu de Fernando de Noronha#,
				'generic' => q#ora de Fernando de Noronha#,
				'standard' => q#ora estandard de Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#ora d’estiu de Novosibirsk#,
				'generic' => q#ora de Novosibirsk#,
				'standard' => q#ora estandard de Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#ora d’estiu d’Omsk#,
				'generic' => q#ora d’Omsk#,
				'standard' => q#ora estandard d’Omsk#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Isla de Pasqua#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fiyi#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápagos#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marqueses#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palaos#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahití#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#ora d’estiu deth Pakistan#,
				'generic' => q#ora deth Pakistan#,
				'standard' => q#ora estandard deth Pakistan#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#ora d’estiu de Paraguay#,
				'generic' => q#ora de Paraguay#,
				'standard' => q#ora estandard de Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#ora d’estu de Perú#,
				'generic' => q#ora de Perú#,
				'standard' => q#ora estandard de Perú#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#ora d’estiu de Filipines#,
				'generic' => q#ora de Filipines#,
				'standard' => q#ora estandard de Filipines#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#ora des Isles Fénix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#ora d’estiu de St. Pierre e Miquelon#,
				'generic' => q#ora de St. Pierre e Miquelon#,
				'standard' => q#ora estandard de St. Pierre e Miquelon#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#ora de Reünion#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#ora d’estiu de Sajalin#,
				'generic' => q#ora de Sajalin#,
				'standard' => q#ora estandard de Sajalin#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#ora des Isles Salomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#ora de Geòrgia deth Sud#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#ora d’estiu de Taipei#,
				'generic' => q#ora de Taipei#,
				'standard' => q#ora estandard de Taipei#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#ora d’estiu de Turkmenistan#,
				'generic' => q#ora de Turkmenistan#,
				'standard' => q#ora estandard de Turkmenistan#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#ora d’estiu d’Uruguay#,
				'generic' => q#ora d’Uruguay#,
				'standard' => q#ora estandard d’Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#ora d’estiu de Uzbekistan#,
				'generic' => q#ora de Uzbekistan#,
				'standard' => q#ora estandard de Uzbekistan#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#ora d’estiu de Vladivostok#,
				'generic' => q#ora de Vladivostok#,
				'standard' => q#ora estandard de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#ora d’estiu de Volgograd#,
				'generic' => q#ora de Volgograd#,
				'standard' => q#ora estandard de Volgograd#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#ora dera Isla Wake#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#ora d’estiu de Yakutsk#,
				'generic' => q#ora de Yakutsk#,
				'standard' => q#ora estandard de Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#ora d’estiu d’Ekaterimburg#,
				'generic' => q#ora d’Ekaterimburg#,
				'standard' => q#ora estandard d’Ekaterimburg#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
