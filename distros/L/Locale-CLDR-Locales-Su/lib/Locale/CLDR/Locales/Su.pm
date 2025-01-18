=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Su - Package for language Sundanese

=cut

package Locale::CLDR::Locales::Su;
# This file auto generated from Data\common\main\su.xml
#	on Fri 17 Jan 12:03:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.46.0');

use v5.12.0;
use mro 'c3';
use utf8;
use feature 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(mineus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nol),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← titik →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(hiji),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dua),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tilu),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(opat),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(lima),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(genep),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(tujuh),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(dalapan),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(salapan),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(sapuluh),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(sabelas),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(→→ belas),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←← puluh[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%%spellout-cardinal-large←ratus[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%%spellout-cardinal-large←rebu[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%%spellout-cardinal-large←juta[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-cardinal-large←miliar[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-cardinal-large' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(sa),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal= ),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal= ),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
			},
		},
		'spellout-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(mineus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ka=%spellout-cardinal=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.0=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=#,##0.0=),
				},
			},
		},
    } },
);

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'de' => 'Jérman',
 				'de_AT' => 'Jérman Austria',
 				'de_CH' => 'Jérman Swiss Luhur',
 				'en' => 'Inggris',
 				'en_AU' => 'Inggris Australia',
 				'en_CA' => 'Inggris Kanada',
 				'en_GB@alt=short' => 'Inggris UK',
 				'en_US' => 'Inggris Amerika',
 				'en_US@alt=short' => 'Inggris AS',
 				'es' => 'Spanyol',
 				'es_419' => 'Spanyol Amérika Latin',
 				'es_ES' => 'Spanyol Éropa',
 				'es_MX' => 'Spanyol Méksiko',
 				'fr' => 'Prancis',
 				'fr_CA' => 'Prancis Kanada',
 				'fr_CH' => 'Prancis Swiss',
 				'it' => 'Italia',
 				'ja' => 'Jepang',
 				'pt' => 'Portugis',
 				'pt_BR' => 'Portugis Brasil',
 				'pt_PT' => 'Portugis Éropa',
 				'ru' => 'Rusia',
 				'su' => 'Basa Sunda',
 				'und' => 'Basa teu dikenal',
 				'zh' => 'Tiongkok',
 				'zh@alt=menu' => 'Tiongkok, Mandarin',
 				'zh_Hans' => 'Tiongkok Sederhana',
 				'zh_Hans@alt=long' => 'Tiongkok Mandarin Sederhana',
 				'zh_Hant' => 'Tiongkok Tradisional',
 				'zh_Hant@alt=long' => 'Tiongkok Mandarin Tradisional',

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
			'Cyrl' => 'Sirilik',
 			'Hans' => 'Sederhana',
 			'Hans@alt=stand-alone' => 'Han Sederhana',
 			'Hant' => 'Tradisional',
 			'Hant@alt=stand-alone' => 'Han Tradisional',
 			'Latn' => 'Latin',
 			'Zxxx' => 'Non-tulisan',
 			'Zzzz' => 'Tulisan Teu Dikenal',

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
			'BR' => 'Brasil',
 			'CN' => 'Tiongkok',
 			'DE' => 'Jérman',
 			'FR' => 'Prancis',
 			'GB' => 'Britania Raya',
 			'ID' => 'Indonesia',
 			'IN' => 'India',
 			'IT' => 'Italia',
 			'JP' => 'Jepang',
 			'RU' => 'Rusia',
 			'US' => 'Amérika Sarikat',
 			'ZZ' => 'Wilayah Teu Dikenal',

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
 				'gregorian' => q{Kalénder Grégorian},
 			},
 			'collation' => {
 				'standard' => q{Aturan Runtuyan Standar},
 			},
 			'numbers' => {
 				'latn' => q{Digit Barat},
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
			'metric' => q{Métrik},
 			'UK' => q{U.K.},
 			'US' => q{A.S.},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Basa: {0}',
 			'script' => 'Skrip: {0}',
 			'region' => 'Daérah: {0}',

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
			auxiliary => qr{[áàăâåäãā æ ç èĕêëē íìĭîïī ñ óòŏôöøō œ úùŭûüū ÿ]},
			index => ['A', 'B', 'C', 'D', 'EÉ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d eé f g h i j k l m n o p q r s t u v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'EÉ', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h.mm',
				hms => 'h.mm.ss',
				ms => 'm.ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'narrow' => {
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'other' => q({0}m/gUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'other' => q({0}m/gUK),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'other' => q({0}dsp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'other' => q({0}dsp-Imp),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'other' => q({0}fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'other' => q({0}fl oz Im),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'other' => q({0}galIm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'other' => q({0}galIm),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:enya|e|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:teu|t|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, sareng {1}),
				2 => q({0} sareng {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
			'timeSeparator' => q(.),
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
		'BRL' => {
			display_name => {
				'currency' => q(Real Brasil),
				'other' => q(real Brasil),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Tiongkok),
				'other' => q(yuan Tiongkok),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'other' => q(euro),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pound Inggris),
				'other' => q(pound Inggris),
			},
		},
		'IDR' => {
			symbol => 'Rp',
			display_name => {
				'currency' => q(Rupee Indonésia),
				'other' => q(rupee Indonésia),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupee India),
				'other' => q(rupee India),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Yén Jepang),
				'other' => q(yén Jepang),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rubel Rusia),
				'other' => q(rubel Rusia),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Dolar A.S.),
				'other' => q(dolar A.S.),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Mata Uang Teu Dikenal),
				'other' => q(\(mata uang teu dikenal\)),
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
							'Péb',
							'Mar',
							'Apr',
							'Méi',
							'Jun',
							'Jul',
							'Ags',
							'Sép',
							'Okt',
							'Nop',
							'Dés'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Januari',
							'Pébruari',
							'Maret',
							'April',
							'Méi',
							'Juni',
							'Juli',
							'Agustus',
							'Séptémber',
							'Oktober',
							'Nopémber',
							'Désémber'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'J',
							'P',
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
						mon => 'Sen',
						tue => 'Sal',
						wed => 'Reb',
						thu => 'Kem',
						fri => 'Jum',
						sat => 'Sap',
						sun => 'Mng'
					},
					wide => {
						mon => 'Senén',
						tue => 'Salasa',
						wed => 'Rebo',
						thu => 'Kemis',
						fri => 'Jumaah',
						sat => 'Saptu',
						sun => 'Minggu'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'S',
						tue => 'S',
						wed => 'R',
						thu => 'K',
						fri => 'J',
						sat => 'S',
						sun => 'M'
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
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					wide => {0 => 'kuartal ka-1',
						1 => 'kuartal ka-2',
						2 => 'kuartal ka-3',
						3 => 'kuartal ka-4'
					},
				},
				'stand-alone' => {
					wide => {0 => 'kuartal ka-1',
						1 => 'kuartal ka-2',
						2 => 'kuartal ka-3',
						3 => 'kuartal-ka 4'
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
				'0' => 'SM',
				'1' => 'M'
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
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d/M/yy},
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
			'full' => q{H.mm.ss zzzz},
			'long' => q{H.mm.ss z},
			'medium' => q{H.mm.ss},
			'short' => q{H.mm},
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
		'gregorian' => {
			Bhm => q{h.mm B},
			Bhms => q{h.mm.ss B},
			EBhm => q{E h.mm B},
			EBhms => q{E h.mm.ss B},
			EHm => q{E HH.mm},
			Ed => q{E d},
			Ehm => q{E h.mm a},
			Ehms => q{E h.mm.ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			Hm => q{HH.mm},
			Hms => q{HH.mm.ss},
			Hmsv => q{HH.mm.ss v},
			Hmv => q{HH.mm v},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			hmsv => q{h.mm.ss a v},
			hmv => q{h.mm a v},
			ms => q{mm.ss},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM, y},
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

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'America_Central' => {
			long => {
				'daylight' => q#Waktu Usum Panas Tengah#,
				'generic' => q#Waktu Tengah#,
				'standard' => q#Waktu Standar Tengah#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Waktu Usum Panas Wétan#,
				'generic' => q#Waktu Wétan#,
				'standard' => q#Waktu Standar Wétan#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Waktu Usum Panas Pagunungan#,
				'generic' => q#Waktu Pagunungan#,
				'standard' => q#Waktu Standar Pagunungan#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Waktu Usum Panas Pasifik#,
				'generic' => q#Waktu Pasifik#,
				'standard' => q#Waktu Standar Pasifik#,
			},
		},
		'Asia/Macau' => {
			exemplarCity => q#Makau#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Waktu Usum Panas Atlantik#,
				'generic' => q#Waktu Atlantik#,
				'standard' => q#Waktu Standar Atlantik#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Waktu Usum Panas Kolombia#,
				'generic' => q#Waktu Kolombia#,
				'standard' => q#Waktu Standar Kolombia#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Waktu Universal Terkoordinasi#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Kota Teu Dikenal#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Waktu Usum Panas Éropa Tengah#,
				'generic' => q#Waktu Éropa Tengah#,
				'standard' => q#Waktu Standar Éropa Tengah#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Waktu Usum Panas Éropa Timur#,
				'generic' => q#Waktu Éropa Timur#,
				'standard' => q#Waktu Standar Éropa Timur#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Waktu Usum Panas Éropa Barat#,
				'generic' => q#Waktu Éropa Barat#,
				'standard' => q#Waktu Standar Éropa Barat#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Waktu Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Waktu Galapagos#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
