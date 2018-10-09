=encoding utf8

=head1

Locale::CLDR::Locales::Es::Any::Mx - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Any::Mx;
# This file auto generated from Data\common\main\es_MX.xml
#	on Sun  7 Oct 10:30:11 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.1');

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
 				'arp' => 'arapaho',
 				'bas' => 'basa',
 				'bax' => 'bamun',
 				'bho' => 'bhojpuri',
 				'bla' => 'siksika',
 				'bua' => 'buriat',
 				'dum' => 'neerlandés medieval',
 				'en_GB@alt=short' => 'inglés (R. U.)',
 				'enm' => 'inglés medieval',
 				'eu' => 'euskera',
 				'frm' => 'francés medieval',
 				'gan' => 'gan (China)',
 				'gmh' => 'alemán de la alta edad media',
 				'grc' => 'griego antiguo',
 				'hak' => 'kejia (China)',
 				'hsn' => 'xiang (China)',
 				'kbd' => 'kabardiano',
 				'krc' => 'karachay-balkar',
 				'lo' => 'lao',
 				'lus' => 'lushai',
 				'mga' => 'irlandés medieval',
 				'nan' => 'min nan (Chino)',
 				'nr' => 'ndebele meridional',
 				'nso' => 'sotho septentrional',
 				'pa' => 'punyabí',
 				'pcm' => 'pcm',
 				'rn' => 'kiroundi',
 				'shu' => 'árabe chadiano',
 				'ss' => 'siswati',
 				'st' => 'sesotho meridional',
 				'sw' => 'suajili',
 				'sw_CD' => 'suajili del Congo',
 				'syr' => 'siriaco',
 				'tet' => 'tetún',
 				'tn' => 'setswana',
 				'tyv' => 'tuviniano',
 				'ug@alt=variant' => 'uyghur',
 				'wo' => 'wolof',
 				'wuu' => 'wuu',
 				'xal' => 'kalmyk',
 				'zgh' => 'tamazight marroquí estándar',

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
 			'Telu' => 'telugú',

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
			'011' => 'África Occidental',
 			'014' => 'África Oriental',
 			'015' => 'África septentrional',
 			'018' => 'África meridional',
 			'030' => 'Asia Oriental',
 			'034' => 'Asia meridional',
 			'035' => 'Sudeste Asiático',
 			'039' => 'Europa meridional',
 			'057' => 'Región de Micronesia',
 			'145' => 'Asia Occidental',
 			'151' => 'Europa Oriental',
 			'154' => 'Europa septentrional',
 			'155' => 'Europa Occidental',
 			'BA' => 'Bosnia y Herzegovina',
 			'CI' => 'Côte d’Ivoire',
 			'EZ' => 'zona euro',
 			'GB@alt=short' => 'RU',
 			'GG' => 'Guernsey',
 			'TA' => 'Tristán de Acuña',
 			'TL' => 'Timor-Leste',
 			'UM' => 'Islas menores alejadas de EE. UU.',
 			'UN' => 'UN',
 			'VI' => 'Islas Vírgenes de EE. UU.',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'Calendario',
 			'collation' => 'Orden',
 			'currency' => 'Moneda',

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
 				'gregorian' => q{Calendario gregoriano},
 				'roc' => q{calendario minguo},
 			},
 			'collation' => {
 				'ducet' => q{orden de clasificación de Unicode predeterminado},
 				'standard' => q{Orden estándar},
 				'traditional' => q{Orden tradicional},
 			},
 			'd0' => {
 				'fwidth' => q{Ancho completo},
 				'hwidth' => q{Ancho medio},
 			},
 			'lb' => {
 				'normal' => q{salto de línea normal},
 			},
 			'm0' => {
 				'bgn' => q{BGN},
 				'ungegn' => q{UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{sistema métrico},
 				'uksystem' => q{sistema imperial},
 				'ussystem' => q{sistema estadounidense},
 			},
 			'numbers' => {
 				'arab' => q{Dígitos en arábigo-índico},
 				'arabext' => q{Dígitos en árabigo-índico extendido},
 				'armn' => q{Números en armenio},
 				'armnlow' => q{Números en armenio en minúscula},
 				'ethi' => q{Números en etíope},
 				'geor' => q{Números en georgiano},
 				'grek' => q{Números en griego},
 				'greklow' => q{Números en griego en minúscula},
 				'gujr' => q{dígitos en gujarati},
 				'guru' => q{Dígitos en gurmuji},
 				'hanidec' => q{Numeros decimales en chino},
 				'hans' => q{Números en chino simplificado},
 				'hansfin' => q{Números financieros en chino simplificado},
 				'hant' => q{Números en chino tradicional},
 				'hantfin' => q{Números financieros en chino tradicional},
 				'hebr' => q{Números en hebreo},
 				'jpanfin' => q{Números financieros en japonés},
 				'knda' => q{números en kannada},
 				'laoo' => q{Dígitos en lao},
 				'mlym' => q{Dígitos en malabar},
 				'taml' => q{Números en tamil},
 				'tamldec' => q{Dígitos en tamil},
 				'telu' => q{Dígitos en telugú},
 				'tibt' => q{Dígitos en tibetano},
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
						'name' => q(acre-pies),
						'one' => q({0} acre-pie),
						'other' => q({0} acre-pies),
					},
					'arc-minute' => {
						'name' => q(arcominutos),
						'one' => q({0} minuto),
						'other' => q({0} minutos),
					},
					'arc-second' => {
						'name' => q(arcosegundos),
						'one' => q({0} segundo),
						'other' => q({0} segundos),
					},
					'fluid-ounce' => {
						'name' => q(onzas líquidas),
						'one' => q({0} onza líquida),
						'other' => q({0} onzas líquidas),
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
					},
					'kelvin' => {
						'name' => q(kelvines),
						'one' => q(kelvin),
						'other' => q({0} kelvines),
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
						'name' => q(kilowatt-hora),
						'one' => q(kilowatt-hora),
						'other' => q({0} kilowatts-hora),
					},
					'lux' => {
						'name' => q(lux),
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
					'micrometer' => {
						'name' => q(micrometros),
						'one' => q({0} micrometro),
						'other' => q({0} micrometros),
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
					'nautical-mile' => {
						'name' => q(millas naúticas),
						'one' => q({0} milla naútica),
						'other' => q({0} millas naúticas),
					},
					'ohm' => {
						'name' => q(ohmios),
						'one' => q({0} ohmio),
						'other' => q({0} ohmios),
					},
					'parsec' => {
						'name' => q(pársecs),
						'one' => q({0} pársec),
						'other' => q({0} pársecs),
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
					'day' => {
						'name' => q(días),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					'month' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'week' => {
						'name' => q(sem),
						'one' => q({0}sem),
						'other' => q({0}sem),
					},
					'year' => {
						'name' => q(a),
						'one' => q({0}a),
						'other' => q({0}a),
					},
				},
				'short' => {
					'arc-minute' => {
						'one' => q({0} min),
						'other' => q({0} min),
					},
					'arc-second' => {
						'name' => q(arcseg),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'carat' => {
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup' => {
						'name' => q(tza.),
						'one' => q({0} tza.),
						'other' => q({0} tzas.),
					},
					'day' => {
						'name' => q(días),
						'one' => q({0} día),
						'other' => q({0} días),
						'per' => q({0}/d),
					},
					'degree' => {
						'name' => q(º),
					},
					'g-force' => {
						'name' => q(fuerza G),
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
					'kilometer-per-hour' => {
						'name' => q(km/hora),
					},
					'light-year' => {
						'name' => q(al),
						'one' => q({0} a. l.),
						'other' => q({0} a. l.),
					},
					'mile' => {
						'name' => q(millas),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mpg Imp.),
						'one' => q({0} mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					'month' => {
						'name' => q(meses),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'nanometer' => {
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					'nautical-mile' => {
						'name' => q(M),
						'one' => q({0} M),
						'other' => q({0} M),
					},
					'parsec' => {
						'name' => q(pc),
					},
					'pint' => {
						'name' => q(pt),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'week' => {
						'name' => q(sem),
						'one' => q({0} sem),
						'other' => q({0} sem),
					},
					'yard' => {
						'name' => q(yd),
					},
					'year' => {
						'name' => q(a),
						'one' => q({0} a),
						'other' => q({0} a),
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
				'1000000000000' => {
					'other' => '0 billones',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 k',
					'other' => '0 k',
				},
				'10000' => {
					'one' => '00 k',
					'other' => '00 k',
				},
				'100000' => {
					'one' => '000 k',
					'other' => '000 k',
				},
				'1000000000' => {
					'one' => '0000 M',
					'other' => '0000 M',
				},
				'10000000000' => {
					'one' => '00 mil M',
					'other' => '00 mil M',
				},
				'100000000000' => {
					'one' => '000 mil M',
					'other' => '000 mil M',
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
		'BGN' => {
			display_name => {
				'other' => q(levas búlgaras),
			},
		},
		'BYN' => {
			symbol => 'p.',
		},
		'CNH' => {
			display_name => {
				'currency' => q(CNH),
				'one' => q(CNH),
				'other' => q(CNH),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nakfa),
			},
		},
		'FKP' => {
			symbol => '£',
		},
		'LVL' => {
			display_name => {
				'one' => q(lats letón),
				'other' => q(lats letones),
			},
		},
		'MXN' => {
			symbol => '$',
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
				'currency' => q(baht tailandés),
				'one' => q(baht tailandés),
				'other' => q(bats),
			},
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
		'XXX' => {
			display_name => {
				'one' => q(\(moneda desconocida\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwacha zambiano),
				'one' => q(kwacha zambiano),
				'other' => q(kwachas zambianos),
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
							'ene',
							'feb',
							'mar',
							'abr',
							'may',
							'jun',
							'jul',
							'ago',
							'sep',
							'oct',
							'nov',
							'dic'
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
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'J',
						fri => 'V',
						sat => 'S',
						sun => 'D'
					},
					short => {
						mon => 'lu',
						tue => 'ma',
						wed => 'mi',
						thu => 'ju',
						fri => 'vi',
						sat => 'sá',
						sun => 'do'
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
					abbreviated => {0 => '1er. trim.',
						1 => '2º. trim.',
						2 => '3er. trim.',
						3 => '4º trim.'
					},
					narrow => {0 => '1T',
						1 => '2T',
						2 => '3T',
						3 => '4T'
					},
					wide => {0 => '1.er trimestre',
						1 => '2º. trimestre',
						2 => '3.er trimestre',
						3 => '4o. trimestre'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1er. trim.',
						1 => '2º. trim.',
						2 => '3er. trim.',
						3 => '4º trim.'
					},
					narrow => {0 => '1T',
						1 => '2T',
						2 => '3T',
						3 => '4T'
					},
					wide => {0 => '1.er trimestre',
						1 => '2º. trimestre',
						2 => '3.er trimestre',
						3 => '4º trimestre'
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
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'night1' if $time >= 2000
						&& $time < 2400;
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
				'abbreviated' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
				'wide' => {
					'pm' => q{p. m.},
					'am' => q{a. m.},
				},
				'narrow' => {
					'evening1' => q{de la tarde},
					'morning2' => q{mañana},
					'noon' => q{del mediodía},
					'morning1' => q{de la madrugada},
					'night1' => q{de la noche},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'pm' => q{p. m.},
					'am' => q{a. m.},
				},
				'wide' => {
					'pm' => q{p. m.},
					'am' => q{a. m.},
				},
				'abbreviated' => {
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
			'short' => q{dd/MM/yy},
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
			'full' => q{H:mm:ss zzzz},
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
		'gregorian' => {
			EHm => q{E H:mm},
			EHms => q{E H:mm:ss},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			GyMMMd => q{d MMM y G},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			MMMEd => q{E d 'de' MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			yMEd => q{E, d/M/y},
			yMM => q{MM/y},
			yMMMEd => q{EEE, d 'de' MMMM 'de' y},
			yQQQ => q{QQQ y},
		},
		'generic' => {
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			MMMEd => q{E d MMM},
			MMMMd => q{d 'de' MMM},
			MMMd => q{d MMM},
			h => q{hh a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{EEE, d MMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyQQQ => q{QQQ y G},
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
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			fallback => '{0} – {1}',
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
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM 'de' y},
			},
			yMMMEd => {
				M => q{E d 'de' MMM – E d 'de' MMM 'de' y},
				d => q{E d 'de' MMM – E d 'de' MMM 'de' y},
				y => q{E d 'de' MMM 'de' y – E d 'de' MMM 'de' y},
			},
			yMMMM => {
				y => q{MMMM 'de' y – MMMM 'de' y},
			},
			yMMMd => {
				M => q{d 'de' MMM – d 'de' MMM y},
				d => q{d–d 'de' MMM 'de' y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
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
		'Africa/Bujumbura' => {
			exemplarCity => q#Buyumbura#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Conakri#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es-Salaam#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Jartum#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branco#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Thomas#,
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#hora de verano de las Montañas Rocosas#,
				'generic' => q#hora de las Montañas Rocosas#,
				'standard' => q#hora estándar de las Montañas Rocosas#,
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
		'Asia/Almaty' => {
			exemplarCity => q#Almatý#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dusambé#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Piongyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Qatar#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangón (Rangún)#,
		},
		'Christmas' => {
			long => {
				'standard' => q#hora de la isla de Navidad#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#hora de las Islas Cocos#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#hora de verano media de las Islas Cook#,
				'generic' => q#hora de las Islas Cook#,
				'standard' => q#hora estándar de las Islas Cook#,
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
				'standard' => q#Tiempo Universal Coordinado#,
			},
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
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
		'Irkutsk' => {
			long => {
				'daylight' => q#hora de verano de Irkutsh#,
				'generic' => q#hora de Irkutsk#,
				'standard' => q#hora estándar de Irkutsh#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#hora de la isla Macquarie#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#hora de las Islas Marshall#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#hora de Myanmar (Birmania)#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#hora de la isla Norfolk#,
			},
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake#,
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
