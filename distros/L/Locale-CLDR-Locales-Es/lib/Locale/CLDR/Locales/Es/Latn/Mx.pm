=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Es::Latn::Mx - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es::Latn::Mx;
# This file auto generated from Data\common\main\es_MX.xml
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

extends('Locale::CLDR::Locales::Es::Latn::419');
has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ace' => 'acehnés',
 				'ady' => 'adigué',
 				'arp' => 'arapaho',
 				'ars' => 'árabe neyedí',
 				'bas' => 'basa',
 				'bax' => 'bamun',
 				'bho' => 'bhoshpuri',
 				'bla' => 'siksika',
 				'bua' => 'buriat',
 				'ckb@alt=menu' => 'kurdo del centro',
 				'crj' => 'cree del sureste',
 				'crl' => 'cree del noreste',
 				'crr' => 'carolina algonquian',
 				'dar' => 'darguin',
 				'dum' => 'neerlandés medieval',
 				'en_GB@alt=short' => 'inglés (R. U.)',
 				'enm' => 'inglés medieval',
 				'eu' => 'euskera',
 				'frm' => 'francés medieval',
 				'gan' => 'gan (China)',
 				'gmh' => 'alemán de la alta edad media',
 				'grc' => 'griego antiguo',
 				'hak' => 'kejia (China)',
 				'hax' => 'haida del sur',
 				'hil' => 'hiligainón',
 				'hsn' => 'xiang (China)',
 				'ikt' => 'inuktitut del oeste de Canadá',
 				'inh' => 'ingusetio',
 				'kbd' => 'kabardiano',
 				'kgp' => 'kaingang',
 				'krc' => 'karachái bálkaro',
 				'kum' => 'cumuco',
 				'mga' => 'irlandés medieval',
 				'nan' => 'min nan (Chino)',
 				'nr' => 'ndebele meridional',
 				'nso' => 'sotho septentrional',
 				'ojb' => 'ojibwa del noroeste',
 				'ojw' => 'ojibwa del oeste',
 				'pa' => 'punyabí',
 				'shu' => 'árabe chadiano',
 				'slh' => 'lushootseed del sur',
 				'ss' => 'siswati',
 				'sw' => 'suajili',
 				'sw_CD' => 'suajili del Congo',
 				'syr' => 'siriaco',
 				'tce' => 'tutchone del sur',
 				'ug@alt=variant' => 'uyghur',
 				'wuu' => 'chino wu',
 				'zgh' => 'tamazight marroquí estándar',

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
			'011' => 'África Occidental',
 			'014' => 'África Oriental',
 			'015' => 'África septentrional',
 			'018' => 'África meridional',
 			'030' => 'Asia Oriental',
 			'034' => 'Asia meridional',
 			'035' => 'Sudeste Asiático',
 			'039' => 'Europa meridional',
 			'145' => 'Asia Occidental',
 			'151' => 'Europa Oriental',
 			'154' => 'Europa septentrional',
 			'155' => 'Europa Occidental',
 			'BA' => 'Bosnia y Herzegovina',
 			'CI' => 'Côte d’Ivoire',
 			'GB@alt=short' => 'RU',
 			'GG' => 'Guernsey',
 			'SZ' => 'Eswatini',
 			'TR@alt=variant' => 'Turquía',
 			'UM' => 'Islas menores alejadas de EE. UU.',

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
 				'roc' => q{calendario minguo},
 			},
 			'collation' => {
 				'ducet' => q{orden de clasificación de Unicode predeterminado},
 			},
 			'numbers' => {
 				'gujr' => q{dígitos en gujarati},
 				'mtei' => q{dígitos en manipuri},
 				'olck' => q{dígitos ol chiki},
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
			'UK' => q{imperial},

		}
	},
);

has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{[...]},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(por ciento),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(por ciento),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(por mil),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(por mil),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohmios),
						'one' => q({0} ohmio),
						'other' => q({0} ohmios),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohmios),
						'one' => q({0} ohmio),
						'other' => q({0} ohmios),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowatts-hora),
						'one' => q(kilowatt-hora),
						'other' => q({0} kilowatts-hora),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowatts-hora),
						'one' => q(kilowatt-hora),
						'other' => q({0} kilowatts-hora),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(millas escandinavas),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(millas escandinavas),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(millas naúticas),
						'one' => q({0} milla naútica),
						'other' => q({0} millas naúticas),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(millas naúticas),
						'one' => q({0} milla naútica),
						'other' => q({0} millas naúticas),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(pársecs),
						'one' => q({0} pársec),
						'other' => q({0} pársecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(pársecs),
						'one' => q({0} pársec),
						'other' => q({0} pársecs),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0} caballo de fuerza),
						'other' => q({0} caballos de fuerza),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0} caballo de fuerza),
						'other' => q({0} caballos de fuerza),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Bft),
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Bft),
						'one' => q(B {0}),
						'other' => q(B {0}),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvines),
						'one' => q(kelvin),
						'other' => q({0} kelvines),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvines),
						'one' => q(kelvin),
						'other' => q({0} kelvines),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q({0} acre-pie),
						'other' => q({0} acre-pies),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q({0} acre-pie),
						'other' => q({0} acre-pies),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(onzas líquidas),
						'one' => q({0} onza líquida),
						'other' => q({0} onzas líquidas),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(onzas líquidas),
						'one' => q({0} onza líquida),
						'other' => q({0} onzas líquidas),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0}kt),
						'other' => q({0}ct),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0}kt),
						'other' => q({0}ct),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'one' => q({0} GB),
						'other' => q({0}GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'one' => q({0} GB),
						'other' => q({0}GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'one' => q({0} kb),
						'other' => q({0}kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'one' => q({0} kb),
						'other' => q({0}kb),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'one' => q({0} Tb),
						'other' => q({0}Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'one' => q({0} Tb),
						'other' => q({0}Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'one' => q({0} TB),
						'other' => q({0}TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'one' => q({0} TB),
						'other' => q({0}TB),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(días),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(días),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sem),
						'one' => q({0}sem),
						'other' => q({0}sem),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sem),
						'one' => q({0}sem),
						'other' => q({0}sem),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(a),
						'one' => q({0}a),
						'other' => q({0}a),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(a),
						'one' => q({0}a),
						'other' => q({0}a),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0} V),
						'other' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0} V),
						'other' => q({0}V),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'one' => q({0} GHz),
						'other' => q({0}GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'one' => q({0} GHz),
						'other' => q({0}GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'one' => q({0} Hz),
						'other' => q({0}Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'one' => q({0} Hz),
						'other' => q({0}Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'one' => q({0} kHz),
						'other' => q({0}kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'one' => q({0} kHz),
						'other' => q({0}kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'one' => q({0} MHz),
						'other' => q({0}MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'one' => q({0} MHz),
						'other' => q({0}MHz),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0} cm),
						'other' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0} cm),
						'other' => q({0}cm),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0} km),
						'other' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0} km),
						'other' => q({0}km),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0} mm),
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0} mm),
						'other' => q({0}mm),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0} kg),
						'other' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0} kg),
						'other' => q({0}kg),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'one' => q({0} atm),
						'other' => q({0}atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'one' => q({0} atm),
						'other' => q({0}atm),
					},
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(fuerza G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(fuerza G),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(º),
						'one' => q({0} grados),
						'other' => q({0} grados),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(º),
						'one' => q({0} grados),
						'other' => q({0} grados),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'one' => q({0} mi/gal imp.),
						'other' => q({0} mi/gal imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0} mi/gal imp.),
						'other' => q({0} mi/gal imp.),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'one' => q({0} B),
						'other' => q({0} byte),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0} B),
						'other' => q({0} byte),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(días),
						'one' => q({0} día),
						'other' => q({0} días),
						'per' => q({0}/d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(días),
						'one' => q({0} día),
						'other' => q({0} días),
						'per' => q({0}/d),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(meses),
						'one' => q({0} m.),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(meses),
						'one' => q({0} m.),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sem),
						'one' => q({0} sem.),
						'other' => q({0} sem),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sem),
						'one' => q({0} sem.),
						'other' => q({0} sem),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(a),
						'one' => q({0} a),
						'other' => q({0} a),
						'per' => q({0}/a),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(a),
						'one' => q({0} a),
						'other' => q({0} a),
						'per' => q({0}/a),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(a. l.),
						'one' => q({0} a. l.),
						'other' => q({0} a. l.),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(a. l.),
						'one' => q({0} a. l.),
						'other' => q({0} a. l.),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(millas),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(millas),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(M),
						'one' => q({0} M),
						'other' => q({0} M),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(M),
						'one' => q({0} M),
						'other' => q({0} M),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(pc),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(CV),
						'one' => q({0} CV),
						'other' => q({0} CV),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(CV),
						'one' => q({0} CV),
						'other' => q({0} CV),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/hora),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/hora),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(N⋅m),
						'one' => q({0} N⋅m),
						'other' => q({0} N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(N⋅m),
						'one' => q({0} N⋅m),
						'other' => q({0} N⋅m),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(tza.),
						'one' => q({0} tzas.),
						'other' => q({0} tzas.),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(tza.),
						'one' => q({0} tzas.),
						'other' => q({0} tzas.),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pt),
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
			},
		},
} },
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BTN' => {
			display_name => {
				'currency' => q(ngultrum butanés),
				'one' => q(ngultrum butanés),
				'other' => q(ngultrums butaneses),
			},
		},
		'BYN' => {
			symbol => 'p.',
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
		'MRO' => {
			symbol => 'MRU',
		},
		'MRU' => {
			symbol => 'UM',
		},
		'MVR' => {
			display_name => {
				'currency' => q(rupia de Maldivas),
				'one' => q(rupia de Maldivas),
				'other' => q(rupias de Maldivas),
			},
		},
		'MXN' => {
			symbol => '$',
		},
		'RON' => {
			symbol => 'lei',
			display_name => {
				'one' => q(leu rumano),
				'other' => q(lei rumanos),
			},
		},
		'SSP' => {
			symbol => '£',
		},
		'SYP' => {
			symbol => '£',
		},
		'THB' => {
			display_name => {
				'currency' => q(baht tailandés),
				'one' => q(baht tailandés),
				'other' => q(bahts tailandeses),
			},
		},
		'VEF' => {
			symbol => 'Bs',
		},
		'VES' => {
			display_name => {
				'one' => q(bolívar venezolano),
				'other' => q(bolivares venezolanos),
			},
		},
		'XXX' => {
			display_name => {
				'one' => q(\(moneda desconocida\)),
				'other' => q(\(moneda desconocida\)),
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
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
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
				'narrow' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
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
		},
		'gregorian' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y},
			'long' => q{d 'de' MMMM 'de' y},
			'medium' => q{d MMM y},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
			MMMEd => q{E d MMM},
			h => q{hh a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{EEE, d MMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyQQQ => q{QQQ y G},
		},
		'gregorian' => {
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			GyMMMd => q{d MMM y G},
			Hmsvvvv => q{HH:mm:ss (vvvv)},
			MMMEd => q{E d 'de' MMM},
			MMd => q{d/MM},
			MMdd => q{dd/MM},
			yMEd => q{E, d/M/y},
			yMM => q{MM/y},
			yMMMEd => q{EEE, d 'de' MMM 'de' y},
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
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			fallback => '{0} – {1}',
		},
		'gregorian' => {
			GyMMM => {
				G => q{MMM 'de' y G – MMM 'de' y G},
				M => q{MMM–MMM 'de' y G},
				y => q{MMM 'de' y – MMM 'de' y G},
			},
			GyMMMEd => {
				G => q{E d 'de' MMM 'de' y G – E d 'de' MMM 'de' y G},
				M => q{E d 'de' MMM – E d 'de' MMM 'de' y G},
				d => q{E d 'de' MMM – E d 'de' MMM 'de' y G},
				y => q{E d 'de' MMM 'de' y – E d 'de' MMM 'de' y G},
			},
			GyMMMd => {
				G => q{d 'de' MMM 'de' y G – d 'de' MMM 'de' y G},
				M => q{d 'de' MMM – d 'de' MMM 'de' y G},
				d => q{d–d 'de' MMM 'de' y G},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y G},
			},
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
				d => q{E, d/M – E, d/M},
			},
			MMMEd => {
				M => q{E d 'de' MMM – E d 'de' MMM},
				d => q{E d 'de' MMM – E d 'de' MMM},
			},
			MMMd => {
				d => q{d–d 'de' MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			h => {
				a => q{h a – h a},
			},
			hm => {
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
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
			yMMM => {
				M => q{MMM–MMM 'de' y},
			},
			yMMMEd => {
				M => q{E d 'de' MMM – E d 'de' MMM 'de' y},
				d => q{E d 'de' MMM – E d 'de' MMM 'de' y},
				y => q{E d 'de' MMM 'de' y – E d 'de' MMM 'de' y},
			},
			yMMMM => {
				y => q{MMMM 'de' y – MMMM 'de' y},
			},
			yMMMd => {
				M => q{d 'de' MMM – d 'de' MMM y},
				d => q{d–d 'de' MMM 'de' y},
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
		'Africa/Bujumbura' => {
			exemplarCity => q#Buyumbura#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Conakri#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es-Salaam#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branco#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Thomas#,
		},
		'Apia' => {
			long => {
				'daylight' => q#hora de verano de Apia#,
				'generic' => q#hora de Apia#,
				'standard' => q#hora estándar de Apia#,
			},
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almatý#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobé#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atirau#,
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
				'generic' => q#hora de Isla de Pascua#,
				'standard' => q#hora estándar de la isla de Pascua#,
			},
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
				'daylight' => q#hora de verano de Islas Malvinas#,
				'generic' => q#hora de Islas Malvinas#,
				'standard' => q#hora estándar de Islas Malvinas#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#hora de las Islas Gilbert#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#hora de las Islas Marshall#,
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
				'standard' => q#hora de la Isla Wake#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
