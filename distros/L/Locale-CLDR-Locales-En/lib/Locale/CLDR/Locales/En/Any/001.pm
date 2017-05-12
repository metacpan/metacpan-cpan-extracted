=head1

Locale::CLDR::Locales::En::Any::001 - Package for language English

=cut

package Locale::CLDR::Locales::En::Any::001;
# This file auto generated from Data\common\main\en_001.xml
#	on Fri 29 Apr  6:59:33 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::En::Any');
has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'centiliter' => {
						'name' => q(centilitres),
						'one' => q({0} centilitre),
						'other' => q({0} centilitres),
					},
					'centimeter' => {
						'name' => q(centimetres),
						'one' => q({0} centimetre),
						'other' => q({0} centimetres),
						'per' => q({0} per centimetre),
					},
					'cubic-centimeter' => {
						'name' => q(cubic centimetres),
						'one' => q({0} cubic centimetre),
						'other' => q({0} cubic centimetres),
						'per' => q({0} per cubic centimetre),
					},
					'cubic-kilometer' => {
						'name' => q(cubic kilometres),
						'one' => q({0} cubic kilometre),
						'other' => q({0} cubic kilometres),
					},
					'cubic-meter' => {
						'name' => q(cubic metres),
						'one' => q({0} cubic metre),
						'other' => q({0} cubic metres),
						'per' => q({0} per cubic metre),
					},
					'deciliter' => {
						'name' => q(decilitres),
						'one' => q({0} decilitre),
						'other' => q({0} decilitres),
					},
					'decimeter' => {
						'name' => q(decimetre),
						'one' => q({0} decimetre),
						'other' => q({0} decimetres),
					},
					'gallon' => {
						'name' => q(US gallons),
						'one' => q({0} US gallon),
						'other' => q({0} US gallons),
						'per' => q({0} per US gallon),
					},
					'gallon-imperial' => {
						'name' => q(gallons),
						'one' => q({0} gallon),
						'other' => q({0} gallons),
						'per' => q({0} per gallon),
					},
					'hectoliter' => {
						'name' => q(hectolitres),
						'one' => q({0} hectolitre),
						'other' => q({0} hectolitres),
					},
					'kilometer' => {
						'name' => q(kilometres),
						'one' => q({0} kilometre),
						'other' => q({0} kilometres),
						'per' => q({0} per kilometre),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometres per hour),
						'one' => q({0} kilometre per hour),
						'other' => q({0} kilometres per hour),
					},
					'liter' => {
						'name' => q(litres),
						'one' => q({0} litre),
						'other' => q({0} litres),
						'per' => q({0} per litre),
					},
					'liter-per-100kilometers' => {
						'name' => q(litres per 100 kilometres),
						'one' => q({0} litre per 100 kilometres),
						'other' => q({0} litres per 100 kilometres),
					},
					'liter-per-kilometer' => {
						'name' => q(litres per kilometre),
						'one' => q({0} litre per kilometre),
						'other' => q({0} litres per kilometre),
					},
					'megaliter' => {
						'name' => q(megalitres),
						'one' => q({0} megalitre),
						'other' => q({0} megalitres),
					},
					'meter' => {
						'name' => q(metres),
						'one' => q({0} metre),
						'other' => q({0} metres),
						'per' => q({0} per metre),
					},
					'meter-per-second' => {
						'name' => q(metres per second),
						'one' => q({0} metre per second),
						'other' => q({0} metres per second),
					},
					'meter-per-second-squared' => {
						'name' => q(metres per second squared),
						'one' => q({0} metre per second squared),
						'other' => q({0} metres per second squared),
					},
					'micrometer' => {
						'name' => q(micrometre),
						'one' => q({0} micrometre),
						'other' => q({0} micrometres),
					},
					'mile-per-gallon' => {
						'name' => q(miles per US gallon),
						'one' => q({0} mile per US gallon),
						'other' => q({0} miles per US gallon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(miles per gallon),
						'one' => q({0} mile per gallon),
						'other' => q({0} miles per gallon),
					},
					'milligram-per-deciliter' => {
						'name' => q(milligrams per decilitre),
						'one' => q({0} milligram per decilitre),
						'other' => q({0} milligrams per decilitre),
					},
					'milliliter' => {
						'name' => q(millilitres),
						'one' => q({0} millilitre),
						'other' => q({0} millilitres),
					},
					'millimeter' => {
						'name' => q(millimetres),
						'one' => q({0} millimetre),
						'other' => q({0} millimetres),
					},
					'millimeter-of-mercury' => {
						'name' => q(millimetres of mercury),
						'one' => q({0} millimetre of mercury),
						'other' => q({0} millimetres of mercury),
					},
					'millimole-per-liter' => {
						'name' => q(millimoles per litre),
						'one' => q({0} millimole per litre),
						'other' => q({0} millimoles per litre),
					},
					'nanometer' => {
						'name' => q(nanometres),
						'one' => q({0} nanometre),
						'other' => q({0} nanometres),
					},
					'picometer' => {
						'name' => q(picometres),
						'one' => q({0} picometre),
						'other' => q({0} picometres),
					},
					'square-centimeter' => {
						'name' => q(square centimetres),
						'one' => q({0} square centimetre),
						'other' => q({0} square centimetres),
						'per' => q({0} per square centimetre),
					},
					'square-kilometer' => {
						'name' => q(square kilometres),
						'one' => q({0} square kilometre),
						'other' => q({0} square kilometres),
					},
					'square-meter' => {
						'name' => q(square metres),
						'one' => q({0} square metre),
						'other' => q({0} square metres),
						'per' => q({0} per square metre),
					},
				},
				'narrow' => {
					'celsius' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0}cl),
						'other' => q({0}cl),
					},
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0}dl),
						'other' => q({0}dl),
					},
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'gallon' => {
						'name' => q(US gal),
						'one' => q({0}galUS),
						'other' => q({0}galUS),
						'per' => q({0}/galUS),
					},
					'gallon-imperial' => {
						'name' => q(gal),
						'one' => q({0}gal),
						'other' => q({0}gal),
						'per' => q({0}/gal),
					},
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0}hl),
						'other' => q({0}hl),
					},
					'liter' => {
						'name' => q(litre),
						'one' => q({0}l),
						'other' => q({0}l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0}l/km),
						'other' => q({0}l/km),
					},
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0}Ml),
						'other' => q({0}Ml),
					},
					'mile-per-gallon' => {
						'name' => q(mpg US),
						'one' => q({0}mpgUS),
						'other' => q({0}mpgUS),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mpg),
						'one' => q({0}mpg),
						'other' => q({0}mpg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
					},
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0}ml),
						'other' => q({0}ml),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
					},
					'pound' => {
						'one' => q({0}lb),
						'other' => q({0}lb),
					},
				},
				'short' => {
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'gallon' => {
						'name' => q(US gal),
						'one' => q({0} gal US),
						'other' => q({0} gal US),
					},
					'gallon-imperial' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
					},
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					'hour' => {
						'one' => q({0} hr),
						'other' => q({0} hrs),
					},
					'liter' => {
						'name' => q(litres),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(litres/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					'meter' => {
						'name' => q(metres),
					},
					'meter-per-second' => {
						'name' => q(metres/sec),
					},
					'meter-per-second-squared' => {
						'name' => q(metres/sec²),
					},
					'micrometer' => {
						'name' => q(µmetres),
					},
					'mile-per-gallon' => {
						'name' => q(miles/gal US),
						'one' => q({0} mpg US),
						'other' => q({0} mpg US),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(miles/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					'millimole-per-liter' => {
						'name' => q(millimol/litre),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					'minute' => {
						'one' => q({0} min),
						'other' => q({0} mins),
					},
					'second' => {
						'one' => q({0} sec),
						'other' => q({0} secs),
					},
				},
			} }
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BYB' => {
			display_name => {
				'currency' => q(Belarusian New Rouble \(1994–1999\)),
				'one' => q(Belarusian new rouble \(1994–1999\)),
				'other' => q(Belarusian new roubles \(1994–1999\)),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Belarusian Rouble),
				'one' => q(Belarusian rouble),
				'other' => q(Belarusian roubles),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
		},
		'LVR' => {
			display_name => {
				'currency' => q(Latvian Rouble),
				'one' => q(Latvian rouble),
				'other' => q(Latvian roubles),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Russian Rouble),
				'one' => q(Russian rouble),
				'other' => q(Russian roubles),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Russian Rouble \(1991–1998\)),
				'one' => q(Russian rouble \(1991–1998\)),
				'other' => q(Russian roubles \(1991–1998\)),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tajikistani Rouble),
				'one' => q(Tajikistani rouble),
				'other' => q(Tajikistani roubles),
			},
		},
		'USD' => {
			symbol => 'US$',
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
			if ($_ eq 'chinese') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
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

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
		},
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
		'chinese' => {
			'full' => q{EEEE, d MMMM r(U)},
			'long' => q{d MMMM r(U)},
			'medium' => q{d MMM r},
			'short' => q{dd/MM/r},
		},
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
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
		},
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
		'chinese' => {
			Ed => q{E d},
			GyMMMEd => q{E, d MMM r(U)},
			GyMMMd => q{d MMM r},
			M => q{LL},
			MEd => q{E, dd/MM},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			UMMMd => q{d MMM U},
			UMd => q{dd/MM/U},
			yMd => q{dd/MM/r},
			yyyyM => q{MM/r},
			yyyyMEd => q{E, dd/MM/r},
			yyyyMMMEd => q{E, d MMM r(U)},
			yyyyMMMd => q{d MMM r},
			yyyyMd => q{dd/MM/r},
		},
		'gregorian' => {
			Ed => q{E d},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E, dd/MM},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{dd/MM},
			yM => q{MM/y},
			yMEd => q{E, dd/MM/y},
			yMMMEd => q{E, d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd/MM/y},
		},
		'generic' => {
			Ed => q{E d},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{LL},
			MEd => q{E, dd/MM},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			yyyyM => q{MM/y GGGGG},
			yyyyMEd => q{E, dd/MM/y GGGGG},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd/MM/y GGGGG},
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
		'chinese' => {
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM U},
				d => q{E, d – E, d MMM U},
				y => q{E, d MMM U – E, d MMM U},
			},
			yMMMd => {
				M => q{d MMM – d MMM U},
				d => q{d – d MMM U},
				y => q{d MMM U – d MMM U},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
		'gregorian' => {
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
		'generic' => {
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			yM => {
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				d => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				y => q{E, dd/MM/y – E, dd/MM/y GGGGG},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Alaska' => {
			short => {
				'daylight' => q(∅∅∅),
				'generic' => q(∅∅∅),
				'standard' => q(∅∅∅),
			},
		},
		'America_Central' => {
			short => {
				'daylight' => q(∅∅∅),
				'generic' => q(∅∅∅),
				'standard' => q(∅∅∅),
			},
		},
		'America_Eastern' => {
			short => {
				'daylight' => q(∅∅∅),
				'generic' => q(∅∅∅),
				'standard' => q(∅∅∅),
			},
		},
		'America_Mountain' => {
			short => {
				'daylight' => q(∅∅∅),
				'generic' => q(∅∅∅),
				'standard' => q(∅∅∅),
			},
		},
		'America_Pacific' => {
			short => {
				'daylight' => q(∅∅∅),
				'generic' => q(∅∅∅),
				'standard' => q(∅∅∅),
			},
		},
		'Atlantic' => {
			short => {
				'daylight' => q(∅∅∅),
				'generic' => q(∅∅∅),
				'standard' => q(∅∅∅),
			},
		},
		'Hawaii_Aleutian' => {
			short => {
				'daylight' => q(∅∅∅),
				'generic' => q(∅∅∅),
				'standard' => q(∅∅∅),
			},
		},
		'Pacific/Honolulu' => {
			short => {
				'daylight' => q(∅∅∅),
				'generic' => q(∅∅∅),
				'standard' => q(∅∅∅),
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
