=encoding utf8

=head1

Locale::CLDR::Locales::Es::Any::Us - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::Us;
# This file auto generated from Data\common\main\es_US.xml
#	on Sun  3 Feb  1:49:07 pm GMT

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

extends('Locale::CLDR::Locales::Es::Any::419');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'ace' => 'acehnés',
 				'alt' => 'altái meridional',
 				'arp' => 'arapaho',
 				'bas' => 'basa',
 				'bax' => 'bamun',
 				'bho' => 'bhojpuri',
 				'bla' => 'siksika',
 				'bua' => 'buriat',
 				'dum' => 'neerlandés medieval',
 				'en_GB@alt=short' => 'inglés (RU)',
 				'enm' => 'inglés medieval',
 				'eu' => 'euskera',
 				'frm' => 'francés medieval',
 				'gan' => 'gan (China)',
 				'gmh' => 'alemán de la alta edad media',
 				'grc' => 'griego antiguo',
 				'gu' => 'gurayatí',
 				'hak' => 'hak',
 				'hsn' => 'xiang (China)',
 				'ht' => 'criollo haitiano',
 				'kbd' => 'kabardiano',
 				'krc' => 'karachay-balkar',
 				'lo' => 'lao',
 				'lus' => 'lushai',
 				'mga' => 'irlandés medieval',
 				'nan' => 'nan',
 				'nr' => 'ndebele meridional',
 				'nso' => 'sotho septentrional',
 				'pcm' => 'pcm',
 				'rm' => 'romanche',
 				'rn' => 'kiroundi',
 				'shu' => 'árabe chadiano',
 				'sma' => 'sami meridional',
 				'ss' => 'siswati',
 				'st' => 'sesotho meridional',
 				'sw_CD' => 'swahili del Congo',
 				'syr' => 'siriaco',
 				'tet' => 'tetún',
 				'tn' => 'setchwana',
 				'tyv' => 'tuviniano',
 				'tzm' => 'tamazight del Atlas Central',
 				'wo' => 'wolof',
 				'wuu' => 'wuu',
 				'xal' => 'kalmyk',

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
			'Hanb' => 'hanb',
 			'Mlym' => 'malayálam',

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
			'011' => 'África occidental',
 			'014' => 'África oriental',
 			'015' => 'África septentrional',
 			'018' => 'África meridional',
 			'030' => 'Asia oriental',
 			'034' => 'Asia meridional',
 			'035' => 'Sudeste asiático',
 			'039' => 'Europa meridional',
 			'057' => 'Región de Micronesia',
 			'145' => 'Asia occidental',
 			'151' => 'Europa oriental',
 			'154' => 'Europa septentrional',
 			'155' => 'Europa occidental',
 			'AC' => 'Isla de la Ascensión',
 			'BA' => 'Bosnia y Herzegovina',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'CI',
 			'EZ' => 'zona euro',
 			'GB@alt=short' => 'RU',
 			'GG' => 'Guernsey',
 			'QO' => 'Territorios alejados de Oceanía',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'TL',
 			'UM' => 'Islas menores alejadas de EE. UU.',
 			'VI' => 'Islas Vírgenes de EE. UU.',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'collation' => {
 				'ducet' => q{orden de clasificación de Unicode predeterminado},
 			},
 			'lb' => {
 				'normal' => q{salto de línea normal},
 			},
 			'ms' => {
 				'uksystem' => q{sistema imperial},
 			},
 			'numbers' => {
 				'gujr' => q{dígitos en gujarati},
 				'knda' => q{números en kannada},
 				'laoo' => q{números en lao},
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
			'US' => q{estadounidense},

		}
	},
);

has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{[...]},
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

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'acre-foot' => {
						'name' => q(acres-pies),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gal),
						'one' => q({0} gal Imp.),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					'gigahertz' => {
						'one' => q({0} gigahercio),
						'other' => q({0} gigahercios),
					},
					'gigawatt' => {
						'name' => q(gigavatios),
						'one' => q({0} gigavatio),
						'other' => q({0} gigavatios),
					},
					'hertz' => {
						'name' => q(hercios),
						'one' => q({0} hercio),
						'other' => q({0} hercios),
					},
					'horsepower' => {
						'one' => q({0} caballo de vapor),
						'other' => q({0} caballos de vapor),
					},
					'kelvin' => {
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					'kilohertz' => {
						'name' => q(kilohercios),
						'one' => q({0} kilohercio),
						'other' => q({0} kilohercios),
					},
					'kilowatt' => {
						'name' => q(kilovatios),
						'one' => q({0} kilovatio),
						'other' => q({0} kilovatios),
					},
					'kilowatt-hour' => {
						'name' => q(kilovatios hora),
						'one' => q({0} kilovatio hora),
						'other' => q({0} kilovatios hora),
					},
					'megahertz' => {
						'name' => q(megahercios),
						'one' => q({0} megahercio),
						'other' => q({0} megahercios),
					},
					'megawatt' => {
						'name' => q(megavatios),
						'one' => q({0} megavatio),
						'other' => q({0} megavatios),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mpg Imp.),
						'one' => q({0} mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					'mile-scandinavian' => {
						'name' => q(millas escandinavas),
					},
					'milligram-per-deciliter' => {
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					'milliwatt' => {
						'name' => q(milivatios),
						'one' => q({0} milivatio),
						'other' => q({0} milivatios),
					},
					'ohm' => {
						'name' => q(ohmios),
						'one' => q({0} ohmio),
						'other' => q({0} ohmios),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'revolution' => {
						'name' => q(revoluciones),
					},
					'volt' => {
						'name' => q(voltios),
						'one' => q({0} voltio),
						'other' => q({0} voltios),
					},
					'watt' => {
						'name' => q(vatios),
						'one' => q({0} vatio),
						'other' => q({0} vatios),
					},
				},
				'narrow' => {
					'fahrenheit' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
				},
				'short' => {
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'carat' => {
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'day' => {
						'per' => q({0}/d),
					},
					'degree' => {
						'name' => q(grad.),
					},
					'g-force' => {
						'name' => q(Fg),
						'one' => q({0} Fg),
						'other' => q({0} Fg),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gal),
						'one' => q({0} gal Imp.),
						'other' => q({0} gal Imp.),
					},
					'horsepower' => {
						'name' => q(CV),
						'one' => q({0} CV),
						'other' => q({0} CV),
					},
					'light-year' => {
						'one' => q({0} a. l.),
						'other' => q({0} a. l.),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mpg Imp.),
						'one' => q({0} mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'year' => {
						'per' => q({0}/a),
					},
				},
			} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'long' => {
				'1000000000' => {
					'one' => '0 billón',
					'other' => '0 billones',
				},
				'10000000000' => {
					'one' => '00 billones',
					'other' => '00 billones',
				},
				'100000000000' => {
					'one' => '000 billones',
					'other' => '000 billones',
				},
				'1000000000000' => {
					'one' => '0 trillón',
					'other' => '0 trillones',
				},
				'10000000000000' => {
					'one' => '00 trillones',
					'other' => '00 trillones',
				},
				'100000000000000' => {
					'one' => '000 trillones',
					'other' => '000 trillones',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 K',
					'other' => '0 K',
				},
				'10000' => {
					'one' => '00 K',
					'other' => '00 K',
				},
				'100000' => {
					'one' => '000 K',
					'other' => '000 K',
				},
				'1000000000' => {
					'one' => '0 B',
					'other' => '0 B',
				},
				'10000000000' => {
					'one' => '00 B',
					'other' => '00 B',
				},
				'100000000000' => {
					'one' => '000 B',
					'other' => '000 B',
				},
				'1000000000000' => {
					'one' => '0 T',
					'other' => '0 T',
				},
				'10000000000000' => {
					'one' => '00 T',
					'other' => '00 T',
				},
				'100000000000000' => {
					'one' => '000 T',
					'other' => '000 T',
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
		'AMD' => {
			display_name => {
				'currency' => q(dram),
			},
		},
		'FKP' => {
			symbol => '£',
		},
		'JPY' => {
			symbol => '¥',
		},
		'KGS' => {
			display_name => {
				'one' => q(som),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ringit),
				'one' => q(ringit),
				'other' => q(ringits),
			},
		},
		'RON' => {
			symbol => 'lei',
		},
		'SSP' => {
			symbol => '£',
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra santotomense),
				'one' => q(dobra santotomense),
				'other' => q(dobra santotomense),
			},
		},
		'SYP' => {
			symbol => '£',
		},
		'THB' => {
			display_name => {
				'currency' => q(bat),
				'one' => q(bat),
				'other' => q(bats),
			},
		},
		'USD' => {
			symbol => '$',
		},
		'UZS' => {
			display_name => {
				'currency' => q(sum),
				'one' => q(sum),
				'other' => q(sums),
			},
		},
		'VEF' => {
			symbol => 'Bs',
		},
		'XAF' => {
			display_name => {
				'currency' => q(franco CFA de África central),
				'one' => q(franco CFA de África central),
				'other' => q(francos CFA de África central),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(franco CFA de África Occidental),
				'one' => q(franco CFA de África Occidental),
				'other' => q(francos CFA de África Occidental),
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
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'J',
						fri => 'V',
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
					wide => {0 => '1.er trimestre',
						1 => '2.º trimestre',
						2 => '3.er trimestre',
						3 => '4.º trimestre'
					},
				},
				'stand-alone' => {
					wide => {0 => '1.er trimestre',
						1 => '2.º trimestre',
						2 => '3.er trimestre',
						3 => '4.º trimestre'
					},
				},
			},
	} },
);

has 'day_period_data' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { sub {
		# Time in hhmm format
		my ($self, $type, $time, $day_period_type) = @_;
		$day_period_type //= 'default';
		SWITCH:
		for ($type) {
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2000
						&& $time < 2400;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'night1' if $time >= 2000
						&& $time < 2400;
					return 'morning2' if $time >= 600
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2000
						&& $time < 2400;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'night1' if $time >= 2000
						&& $time < 2400;
					return 'morning2' if $time >= 600
						&& $time < 1200;
				}
				last SWITCH;
				}
		}
	} },
);

around day_period_data => sub {
	my ($orig, $self) = @_;
	return $self->$orig;
};

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'narrow' => {
					'evening1' => q{de la tarde},
					'morning1' => q{de la madrugada},
					'noon' => q{del mediodía},
					'morning2' => q{mañana},
					'night1' => q{de la noche},
				},
				'wide' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
				'abbreviated' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
				'narrow' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
				'wide' => {
					'pm' => q{p. m.},
					'am' => q{a. m.},
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
			'medium' => q{d MMM, y G},
		},
		'gregorian' => {
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
			GyMMM => q{MMM y G},
			GyMMMd => q{d MMM y G},
			MMMEd => q{E d MMM},
			MMMMd => q{d 'de' MMM},
			MMMd => q{d MMM},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
		},
		'gregorian' => {
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			GyMMMd => q{d MMM y G},
			Hmsv => q{HH:mm:ss v},
			Hmsvvvv => q{HH:mm:ss (vvvv)},
			Hmv => q{HH:mm v},
			MMMEd => q{E, d 'de' MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			yMEd => q{E, d/M/y},
			yMM => q{MM/y},
			yMMMEd => q{EEE, d 'de' MMMM 'de' y},
			yQQQ => q{QQQ y},
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
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			fallback => '{0} – {1}',
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E, d/M/y–E, d/M/y G},
				d => q{E, d/M/y–E, d/M/y G},
				y => q{E, d/M/y–E, d/M/y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMMEd => {
				M => q{E d 'de' MMM – E d 'de' MMM},
				d => q{E d 'de' MMM – E d 'de' MMM},
			},
			MMMd => {
				d => q{d–d 'de' MMM},
			},
			h => {
				a => q{h a – h a},
			},
			hm => {
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM 'de' y},
			},
			yMMMM => {
				y => q{MMMM 'de' y – MMMM 'de' y},
			},
			yMMMd => {
				M => q{d 'de' MMM – d 'de' MMM y},
				d => q{d–d 'de' MMM 'de' y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Africa/Accra' => {
			exemplarCity => q#Acra#,
		},
		'Alaska' => {
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
			},
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Thomas#,
		},
		'America_Central' => {
			short => {
				'daylight' => q#CDT#,
				'generic' => q#CT#,
				'standard' => q#CST#,
			},
		},
		'America_Eastern' => {
			short => {
				'daylight' => q#EDT#,
				'generic' => q#ET#,
				'standard' => q#EST#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#hora de verano de las Montañas Rocosas#,
				'generic' => q#hora de las Montañas Rocosas#,
				'standard' => q#hora estándar de las Montañas Rocosas#,
			},
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MT#,
				'standard' => q#MST#,
			},
		},
		'America_Pacific' => {
			short => {
				'daylight' => q#PDT#,
				'generic' => q#PT#,
				'standard' => q#PST#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#hora de verano de Apia#,
				'generic' => q#hora de Apia#,
				'standard' => q#hora estándar de Apia#,
			},
		},
		'Argentina_Western' => {
			long => {
				'generic' => q#hora de Argentina occidental#,
				'standard' => q#hora estándar de Argentina occidental#,
			},
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dusambé#,
		},
		'Atlantic' => {
			short => {
				'daylight' => q#ADT#,
				'generic' => q#AT#,
				'standard' => q#AST#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#hora de Chamorro#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#hora de las Islas Cocos#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#hora de verano de la isla de Pascua#,
				'generic' => q#hora de la isla de Pascua#,
				'standard' => q#hora estándar de la isla de Pascua#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#hora universal coordinada#,
			},
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakhan#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanovsk#,
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#hora de verano de Europa oriental#,
				'generic' => q#hora de Europa oriental#,
				'standard' => q#hora estándar de Europa oriental#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#hora del extremo oriental de Europa#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#hora de verano de Europa occidental#,
				'generic' => q#hora de Europa occidental#,
				'standard' => q#hora estándar de Europa occidental#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#hora de verano de las islas Malvinas#,
				'generic' => q#hora de las islas Malvinas#,
				'standard' => q#hora estándar de las islas Malvinas#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#hora de las islas Gilbert#,
			},
		},
		'Hawaii_Aleutian' => {
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAST#,
			},
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#hora del Océano Índico#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#hora de la isla Macquarie#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#hora de las islas Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#hora de las Islas Marshall#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#hora de la isla Norfolk#,
			},
		},
		'Pacific/Honolulu' => {
			short => {
				'daylight' => q#HDT#,
				'generic' => q#HST#,
				'standard' => q#HST#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#hora de las islas Fénix#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#hora de Pyongyang#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#hora de las Islas Salomón#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#hora de la isla Wake#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
